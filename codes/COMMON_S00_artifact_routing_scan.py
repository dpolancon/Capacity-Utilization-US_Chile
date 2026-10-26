# COMMON_S00_artifact_routing_scan.py
#
# Scans the repository's analysis scripts and records which script writes which
# figure, table, or data artifact. Emits three CSV ledgers into
# output/artifact_routing/.
#
# WHY THIS EXISTS
# ---------------
# Nothing in this repository records code -> artifact edges. The manuscript draws
# every estimate from reports/, but which script produced a given fragment was, until
# now, recoverable only by reading 214 scripts. That gap has already cost: one binding
# table has no producer at all, and one figure script writes to a path that no longer
# matches where its outputs are consumed from.
#
# DESIGN COMMITMENT
# -----------------
# This scanner does not guess. The repository uses four incompatible path conventions
# and several scripts build filenames from loop variables, which is legitimately
# unresolvable by static analysis. Every row carries a `resolution` field of `exact`,
# `partial` (directory known, filename dynamic), or `unresolved`. A wrong `exact` is
# worse than an honest `unresolved`, because the whole point of the ledger is to be
# trustable without re-reading the source.
#
# Run from anywhere; paths resolve relative to the repo root.

import csv
import os
import re
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = REPO_ROOT / "output" / "artifact_routing"

# Scripts outside codes/ that nevertheless produce paper-facing artifacts.
OFF_TREE_SCRIPTS = [
    REPO_ROOT / "output" / "generate_latex_tables.py",
    REPO_ROOT / "chapter2_paper" / "WP_Chapter2_1.0" / "split_core_triad_tables.py",
    REPO_ROOT / "chapter2_paper" / "WP_Chapter2_1.0" / "compile_chapter2.py",
]

ARTIFACT_EXT = {
    ".png": "figure", ".pdf": "figure", ".svg": "figure",
    ".jpg": "figure", ".jpeg": "figure",
    ".tex": "table", ".csv": "table",
    ".rds": "data", ".rdata": "data",
    ".md": "doc", ".txt": "doc",
}

# Write calls -> which argument carries the path.
# 0-based positional index, plus the named-argument aliases to check first.
WRITE_CALLS = {
    # figures
    "ggsave":      (0, ["filename"], "figure"),
    "png":         (0, ["filename", "file"], "figure"),
    "pdf":         (0, ["file", "filename"], "figure"),
    "svg":         (0, ["filename", "file"], "figure"),
    "cairo_pdf":   (0, ["filename", "file"], "figure"),
    "jpeg":        (0, ["filename", "file"], "figure"),
    # tables and data
    "write.csv":   (1, ["file"], "table"),
    "write_csv":   (1, ["file", "path"], "table"),
    "fwrite":      (1, ["file"], "table"),
    "write.table": (1, ["file"], "table"),
    "writeLines":  (1, ["con"], "table"),
    "saveRDS":     (1, ["file"], "data"),
    "save":        (None, ["file"], "data"),
    "sink":        (0, ["file"], "doc"),
    "write_rds":   (1, ["file", "path"], "data"),
}


# --------------------------------------------------------------------------
# Small expression utilities
# --------------------------------------------------------------------------

def split_top_level(s, sep=","):
    """Split on `sep` at paren/bracket depth zero, respecting quotes."""
    parts, buf, depth, quote = [], [], 0, None
    i = 0
    while i < len(s):
        ch = s[i]
        if quote:
            buf.append(ch)
            if ch == quote and (i == 0 or s[i - 1] != "\\"):
                quote = None
        elif ch in "\"'":
            quote = ch
            buf.append(ch)
        elif ch in "([{":
            depth += 1
            buf.append(ch)
        elif ch in ")]}":
            depth -= 1
            buf.append(ch)
        elif ch == sep and depth == 0:
            parts.append("".join(buf).strip())
            buf = []
        else:
            buf.append(ch)
        i += 1
    if buf:
        parts.append("".join(buf).strip())
    return parts


def match_call(text, idx):
    """Given index of an opening paren, return (args_string, index_after_close)."""
    depth, quote, i = 0, None, idx
    while i < len(text):
        ch = text[i]
        if quote:
            if ch == quote and text[i - 1] != "\\":
                quote = None
        elif ch in "\"'":
            quote = ch
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return text[idx + 1:i], i + 1
        i += 1
    return None, len(text)


def logical_lines(raw):
    """
    Join physical lines into logical ones where brackets are unbalanced, so a
    file.path(...) spanning three lines is seen as a single expression. Returns
    (text, first_physical_line_number) pairs.
    """
    out, buf, start, depth = [], [], None, 0
    for n, line in enumerate(raw.splitlines(), start=1):
        stripped = line.split("#")[0] if line.strip().startswith("#") else line
        if start is None:
            start = n
        buf.append(stripped)
        for ch in stripped:
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
        if depth <= 0:
            out.append((" ".join(x.strip() for x in buf), start))
            buf, start, depth = [], None, 0
    if buf:
        out.append((" ".join(x.strip() for x in buf), start or 1))
    return out


# --------------------------------------------------------------------------
# Symbolic path resolution
# --------------------------------------------------------------------------

class Resolver:
    """
    Tracks variable assignments and evaluates path expressions symbolically.

    Returns (value, resolution) where resolution is 'exact', 'partial', or
    'unresolved'. 'partial' means a directory resolved but the filename is dynamic --
    common where a script loops over model names.
    """

    REPO_SENTINELS = ("getwd()", "normalizePath(getwd())", "here()", "here::here()")

    def __init__(self):
        self.vars = {}

    def assign(self, name, expr):
        val, res = self.eval(expr)
        if res in ("exact", "partial"):
            self.vars[name] = (val, res)
        elif name in self.vars:
            del self.vars[name]   # reassigned to something unknown; forget it

    def eval(self, expr):
        e = expr.strip()
        if not e:
            return None, "unresolved"

        # string literal
        m = re.fullmatch(r'"([^"]*)"|\'([^\']*)\'', e)
        if m:
            return (m.group(1) if m.group(1) is not None else m.group(2)), "exact"

        # repo-root sentinels
        if e.replace(" ", "") in [s.replace(" ", "") for s in self.REPO_SENTINELS]:
            return str(REPO_ROOT).replace("\\", "/"), "exact"

        # bare identifier
        if re.fullmatch(r"[A-Za-z_.][A-Za-z0-9_.]*", e):
            if e in self.vars:
                return self.vars[e]
            return None, "unresolved"

        # function call
        m = re.match(r"([A-Za-z_.][A-Za-z0-9_.$:]*)\s*\(", e)
        if m:
            fn = m.group(1).split("::")[-1]
            args, end = match_call(e, m.end() - 1)
            if args is None or e[end:].strip() not in ("", ")"):
                if args is None:
                    return None, "unresolved"
            parts = [p for p in split_top_level(args) if p.strip()]

            if fn in ("file.path", "join", "os.path.join"):
                return self._join(parts, "/")
            if fn in ("paste0", "str_c"):
                return self._join(parts, "")
            if fn == "paste":
                sep = "/"
                keep = []
                for p in parts:
                    ms = re.match(r'sep\s*=\s*["\'](.*)["\']', p)
                    if ms:
                        sep = ms.group(1)
                    else:
                        keep.append(p)
                return self._join(keep, sep)
            if fn in ("normalizePath", "Path", "path.expand", "str"):
                return self.eval(parts[0]) if parts else (None, "unresolved")
            if fn in ("sprintf", "format", "glue", "f"):
                return None, "unresolved"     # runtime interpolation
            return None, "unresolved"

        # pathlib division:  base / "name.png"
        if "/" in e and '"' in e or "'" in e:
            segs = split_top_level(e, "/")
            if len(segs) > 1:
                return self._join(segs, "/")

        return None, "unresolved"

    def _join(self, parts, sep):
        vals, worst = [], "exact"
        for p in parts:
            if re.match(r"[A-Za-z_.][A-Za-z0-9_.]*\s*=", p) and "==" not in p:
                continue                      # named arg such as recursive = TRUE
            v, r = self.eval(p)
            if r == "unresolved":
                # A dynamic tail (loop variable) still leaves the prefix usable.
                if vals:
                    return sep.join(vals), "partial"
                return None, "unresolved"
            if r == "partial":
                worst = "partial"
            vals.append(v)
        if not vals:
            return None, "unresolved"
        return sep.join(vals), worst


# --------------------------------------------------------------------------
# Classification helpers
# --------------------------------------------------------------------------

def repo_relative(path):
    if not path:
        return None
    p = path.replace("\\", "/")
    root = str(REPO_ROOT).replace("\\", "/")
    if p.lower().startswith(root.lower()):
        return p[len(root):].lstrip("/")
    if re.match(r"^[A-Za-z]:/", p):
        return "ABSOLUTE_OUTSIDE_REPO:" + p
    return p.lstrip("./")


def artifact_kind(path, call_kind):
    if not path:
        return call_kind or "unknown"
    ext = os.path.splitext(path)[1].lower()
    kind = ARTIFACT_EXT.get(ext)
    if kind is None:
        return call_kind or "unknown"
    # A .pdf written by a device call is a figure; a .pdf under reports/ is a document.
    if ext == ".pdf" and call_kind != "figure" and "/reports/" in path.replace("\\", "/"):
        return "doc"
    return kind


def destination_tree(rel):
    if not rel:
        return "unknown"
    if rel.startswith("ABSOLUTE_OUTSIDE_REPO"):
        return "outside_repo"
    head = rel.split("/")[0]
    return head if head in ("output", "reports", "chapter2_vault", "data",
                            "chapter2_paper", "codes") else "other"


# --------------------------------------------------------------------------
# Per-file scan
# --------------------------------------------------------------------------

ASSIGN_R = re.compile(r"^\s*([A-Za-z_.][A-Za-z0-9_.]*)\s*(?:<-|=(?!=))\s*(.+)$")
ASSIGN_PY = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)\s*(.+)$")

# A line that reads is not a line that writes. Without this guard the string-literal
# detector would report every input CSV as an output of the script consuming it.
READ_VERBS = (r"(?<![A-Za-z0-9_.])("
              r"read\.csv|read_csv|read\.table|readRDS|read_rds|fread|readLines|"
              r"read_excel|read_xlsx|load|source|file\.exists|dir\.exists|"
              r"pd\.read_[a-z_]+|list\.files|Sys\.glob|include_graphics"
              r")\s*\(")

# Strength ordering used when the same artifact is seen more than once on a line.
EVIDENCE_RANK = {"write_call": 3, "path_expression": 2, "string_literal": 1}


def scan_file(path):
    try:
        raw = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []

    is_py = path.suffix.lower() == ".py"
    rows, resolver = [], Resolver()
    read_paths = set()   # paths this script consumes; never reported as its outputs

    for text, lineno in logical_lines(raw):
        stripped = text.strip()
        if not stripped or stripped.startswith("#"):
            continue

        # 1. write calls
        for fn, (pos, named, kind) in WRITE_CALLS.items():
            for m in re.finditer(r"(?<![A-Za-z0-9_.$])" + re.escape(fn) + r"\s*\(", text):
                args, _ = match_call(text, m.end() - 1)
                if args is None:
                    continue
                parts = split_top_level(args)
                expr = None
                for nm in named:                        # named argument wins
                    for p in parts:
                        mm = re.match(re.escape(nm) + r"\s*=\s*(.+)$", p.strip())
                        if mm:
                            expr = mm.group(1)
                            break
                    if expr:
                        break
                if expr is None and pos is not None:
                    positional = [p for p in parts
                                  if not re.match(r"[A-Za-z_.][A-Za-z0-9_.]*\s*=(?!=)", p.strip())]
                    if len(positional) > pos:
                        expr = positional[pos]
                if expr is None:
                    continue
                val, res = resolver.eval(expr)
                rows.append(dict(line=lineno, call=fn, expr=expr.strip()[:200],
                                 resolved=val, resolution=res, call_kind=kind,
                                 detection="write_call"))

        # 2. Python file handles: open(path, "w")
        if is_py:
            for m in re.finditer(r"(?<![A-Za-z0-9_.])open\s*\(", text):
                args, _ = match_call(text, m.end() - 1)
                if not args:
                    continue
                parts = split_top_level(args)
                if len(parts) >= 2 and re.search(r'["\'][wa]b?\+?["\']', parts[1]):
                    val, res = resolver.eval(parts[0])
                    rows.append(dict(line=lineno, call="open(w)", expr=parts[0][:200],
                                     resolved=val, resolution=res, call_kind="table",
                                     detection="write_call"))
            for m in re.finditer(r"\.write_text\s*\(|\.to_csv\s*\(|\.savefig\s*\(", text):
                head = text[:m.start()]
                mm = re.search(r"([A-Za-z_][A-Za-z0-9_]*(?:\s*/\s*[^/]+)*)\s*$", head)
                if mm:
                    val, res = resolver.eval(mm.group(1))
                    rows.append(dict(line=lineno, call=m.group(0).strip("(. "),
                                     expr=mm.group(1)[:200], resolved=val,
                                     resolution=res, call_kind="unknown",
                                     detection="write_call"))

        # 3. path expressions naming an artifact extension (catches paths passed as
        #    function arguments, which is how both Python table generators work)
        for m in re.finditer(r"(file\.path|os\.path\.join|paste0)\s*\(", text):
            args, end = match_call(text, m.end() - 1)
            if args is None:
                continue
            whole = text[m.start():end]
            if not re.search(r'["\'][^"\']*\.(png|pdf|svg|tex|csv|rds)["\']', whole, re.I):
                continue
            val, res = resolver.eval(whole)
            if val:
                rows.append(dict(line=lineno, call="path_expr", expr=whole[:200],
                                 resolved=val, resolution=res, call_kind="unknown",
                                 detection="path_expression"))

        # 4. bare string literals naming an artifact, passed as call arguments.
        #    Both Python table generators hand an absolute .tex path to a user-defined
        #    writer, which no amount of static analysis will recognise as a write. The
        #    literal is real evidence, but weaker than a write call -- so it is recorded
        #    as its own evidence class, and suppressed on any line carrying a read verb
        #    so that inputs are never mistaken for outputs.
        lits = re.findall(r'["\']([^"\']*\.(?:png|pdf|svg|tex|csv|rds))["\']', text, re.I)
        # A single write call writes one path. Three or more artifact literals on one
        # logical line is a vector of inputs (`files <- c(...)`), not a set of writes.
        if not re.search(READ_VERBS, text) and len(lits) < 3:
            for m in re.finditer(r'["\']([^"\']*\.(?:png|pdf|svg|tex|csv|rds))["\']', text, re.I):
                lit = m.group(1)
                if "/" not in lit and "\\" not in lit:
                    continue                      # bare filename, no directory: too weak
                val, res = resolver.eval('"' + lit + '"')
                rows.append(dict(line=lineno, call="string_literal", expr=lit[:200],
                                 resolved=val, resolution=res, call_kind="unknown",
                                 detection="string_literal"))

        # 5. record read targets, so the weaker detectors cannot claim an input as
        #    an output. A path assigned to a variable that is later handed to
        #    read.csv() is a dependency of this script, not a product of it.
        for m in re.finditer(READ_VERBS, text):
            args, _ = match_call(text, m.end() - 1)
            if not args:
                continue
            for p in split_top_level(args)[:2]:
                v, r = resolver.eval(p.strip())
                if v and r == "exact":
                    read_paths.add(repo_relative(v))

        # 6. assignments last, so a call on the same logical line sees prior state
        m = (ASSIGN_PY if is_py else ASSIGN_R).match(text)
        if m and not re.match(r"^\s*(if|for|while|function|def)\b", text):
            resolver.assign(m.group(1), m.group(2))

    return [r for r in rows
            if r["detection"] == "write_call"
            or repo_relative(r["resolved"]) not in read_paths]


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    targets = sorted(
        [p for p in (REPO_ROOT / "codes").rglob("*")
         if p.suffix.lower() in (".r", ".py") and p.is_file()]
    ) + [p for p in OFF_TREE_SCRIPTS if p.exists()]

    # Keyed by (script, line, artifact); the same path is often caught by more than
    # one detector on the same line, and only the strongest evidence should survive.
    best = {}
    for script in targets:
        rel_script = str(script.relative_to(REPO_ROOT)).replace("\\", "/")
        for r in scan_file(script):
            rel = repo_relative(r["resolved"])
            kind = artifact_kind(rel, r["call_kind"])
            if kind in ("unknown", "doc") and r["detection"] != "write_call":
                continue
            row = {
                "script": script.name,
                "script_path": rel_script,
                "line": r["line"],
                "call": r["call"],
                "detection": r["detection"],
                "evidence": r["detection"],
                "path_expression": r["expr"],
                "resolved_path": rel or "",
                "artifact_kind": kind,
                "destination_tree": destination_tree(rel),
                "exists_on_disk": (
                    ("yes" if (REPO_ROOT / rel).exists() else "no")
                    if rel and r["resolution"] == "exact" and not rel.startswith("ABSOLUTE")
                    else ""
                ),
                "resolution": r["resolution"],
                "in_legacy_tree": "yes" if "/legacy/" in rel_script or "/runs/" in rel_script else "no",
            }
            key = (rel_script, r["line"], rel or r["expr"])
            prev = best.get(key)
            if prev is None or EVIDENCE_RANK.get(row["evidence"], 0) > EVIDENCE_RANK.get(prev["evidence"], 0):
                best[key] = row

    edges = sorted(best.values(), key=lambda e: (e["script_path"], e["line"]))
    _write(OUT_DIR / "artifact_routing_edges.csv", edges)

    # Reverse index: artifact -> producing script(s)
    producers = defaultdict(set)
    for e in edges:
        if e["resolved_path"] and e["resolution"] == "exact":
            producers[e["resolved_path"]].add(e["script_path"])

    strongest = defaultdict(str)
    for e in edges:
        if e["resolved_path"] and e["resolution"] == "exact":
            if EVIDENCE_RANK.get(e["evidence"], 0) > EVIDENCE_RANK.get(strongest[e["resolved_path"]], 0):
                strongest[e["resolved_path"]] = e["evidence"]

    reverse = []
    for art in sorted(producers):
        srcs = sorted(producers[art])
        reverse.append({
            "artifact": art,
            "n_producers": len(srcs),
            "producers": " | ".join(srcs),
            "artifact_kind": artifact_kind(art, None),
            "strongest_evidence": strongest[art],
            "exists_on_disk": "yes" if (REPO_ROOT / art).exists() else "no",
            "flag": " ".join(f for f in [
                "MULTIPLE_PRODUCERS" if len(srcs) > 1 else "",
                # No write call anywhere: the edge rests on a path literal alone, which
                # a script that merely reads the file can also produce. Treat as a lead,
                # not a fact.
                "WEAK_EVIDENCE_ONLY" if strongest[art] != "write_call" else "",
            ] if f),
        })

    # Artifacts on disk in the paper-facing trees with no declared producer
    tracked = set(producers)
    orphans = []
    for e in edges:
        if e["resolved_path"] and e["resolution"] == "exact" and e["exists_on_disk"] == "no":
            orphans.append({"kind": "declared_but_absent", "path": e["resolved_path"],
                            "detail": f'{e["script_path"]}:{e["line"]}'})

    scan_roots = [
        REPO_ROOT / "output" / "figures",
        REPO_ROOT / "output" / "US" / "S60_CAPACITY_RECOVERY" / "figures",
        REPO_ROOT / "output" / "US" / "S61_SECTION32_IMOLS" / "figures",
        REPO_ROOT / "output" / "CL" / "S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY",
        REPO_ROOT / "output" / "CL" / "figures",
        REPO_ROOT / "reports" / "US_Section31_IMOLS_Results",
        REPO_ROOT / "reports" / "US_Section32_IMOLS_Results",
        REPO_ROOT / "reports" / "Chile_Section33_Peripheral_IMOLS_Results",
    ]
    for root in scan_roots:
        if not root.exists():
            continue
        for f in sorted(root.iterdir()):
            if not f.is_file() or f.suffix.lower() not in (".png", ".pdf", ".tex", ".svg"):
                continue
            if "_legacy" in str(f) or "99_archive" in str(f):
                continue
            rel = str(f.relative_to(REPO_ROOT)).replace("\\", "/")
            if rel not in tracked:
                orphans.append({"kind": "on_disk_no_producer", "path": rel, "detail": ""})

    seen_o = set()
    orphans = [o for o in orphans
               if not ((o["kind"], o["path"]) in seen_o or seen_o.add((o["kind"], o["path"])))]

    _write(OUT_DIR / "artifact_routing_reverse.csv", reverse)
    _write(OUT_DIR / "artifact_routing_orphans.csv", orphans)

    by_res = defaultdict(int)
    for e in edges:
        by_res[e["resolution"]] += 1
    print(f"scripts scanned        : {len(targets)}")
    print(f"edges recorded         : {len(edges)}")
    print(f"  exact / partial / unresolved : "
          f"{by_res['exact']} / {by_res['partial']} / {by_res['unresolved']}")
    print(f"distinct artifacts     : {len(reverse)}")
    print(f"orphan rows            : {len(orphans)}")
    print(f"written to             : {OUT_DIR.relative_to(REPO_ROOT)}")


def _write(path, rows):
    if not rows:
        rows = [{"note": "no rows"}]
    with open(path, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)


if __name__ == "__main__":
    main()
