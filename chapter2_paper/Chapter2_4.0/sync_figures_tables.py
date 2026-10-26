# sync_figures_tables.py
#
# Mirrors every figure and table the manuscript actually consumes into
# chapter2_paper/WP_Chapter2_1.0/figures_tables/, and writes a checksummed manifest.
#
# WHAT THIS IS AND IS NOT
# -----------------------
# The mirror is a DERIVED build artifact. The manuscript continues to \includegraphics
# from output/ and \input from reports/, so the single-source-of-truth property holds:
# there is exactly one authoritative copy of every number, and it is not in this folder.
# The mirror exists so the chapter can be inspected, audited, and carried around as one
# unit without dragging the whole repository along.
#
# The mirror is defined by what the .tex files actually reference, discovered by parsing
# them. It is never a hand-maintained list, because a hand-maintained list is exactly the
# thing that goes stale without anyone noticing.
#
# Re-running is safe and idempotent. On a second run it re-checksums every mirrored file
# and reports drift rather than silently overwriting, so a source that changed under the
# manuscript is visible instead of absorbed.

import csv
import hashlib
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent.parent
MIRROR = HERE / "figures_tables"
MANIFEST = MIRROR / "MANIFEST.csv"

INCLUDE_RE = re.compile(r"\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}")
INPUT_RE = re.compile(r"\\input\{([^}]+)\}")
LABEL_RE = re.compile(r"\\label\{([^}]+)\}")
CAPTION_RE = re.compile(r"\\caption\{")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def build_files():
    """The .tex files actually reachable from main.tex, in build order."""
    main = HERE / "main.tex"
    files = [main]
    for name in INPUT_RE.findall(main.read_text(encoding="utf-8")):
        p = HERE / (name if name.endswith(".tex") else name + ".tex")
        if p.exists():
            files.append(p)
    return files


def balanced_env(text, start, begin=r"\begin{table}", end=r"\end{table}"):
    """Extract a table environment, tolerating nesting."""
    depth, i = 0, start
    while i < len(text):
        if text.startswith(begin, i):
            depth += 1
            i += len(begin)
        elif text.startswith(end, i):
            depth -= 1
            i += len(end)
            if depth == 0:
                return text[start:i]
        else:
            i += 1
    return None


def collect():
    """Discover every artifact the manuscript consumes."""
    items = []
    for tex in build_files():
        rel_tex = tex.name
        text = tex.read_text(encoding="utf-8")
        lines = text.splitlines()

        for n, line in enumerate(lines, start=1):
            for raw in INCLUDE_RE.findall(line):
                src = (HERE / raw).resolve()
                items.append(dict(kind="figure", origin="mirrored", source=src,
                                  raw=raw, consumer=rel_tex, line=n, payload=None))
            for raw in INPUT_RE.findall(line):
                if not raw.startswith("../"):
                    continue                      # structural \input{section4}
                src = (HERE / raw).resolve()
                items.append(dict(kind="table", origin="mirrored", source=src,
                                  raw=raw, consumer=rel_tex, line=n, payload=None))

        # Table environments written inline rather than \input. These have no file of
        # their own, so the mirror extracts them; the manifest marks them as extracted
        # so nobody mistakes the extract for a source.
        for m in re.finditer(re.escape(r"\begin{table}"), text):
            env = balanced_env(text, m.start())
            if env is None:
                continue
            lbl = LABEL_RE.search(env)
            stem = (lbl.group(1).replace("tab:", "") if lbl
                    else f"unlabeled_{m.start()}")
            items.append(dict(kind="table", origin="extracted", source=None,
                              raw=f"{rel_tex} inline", consumer=rel_tex,
                              line=text[:m.start()].count("\n") + 1,
                              payload=env, stem=stem))
    return items


def main():
    MIRROR.mkdir(parents=True, exist_ok=True)

    previous = {}
    if MANIFEST.exists():
        with open(MANIFEST, encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                previous[row["mirrored_name"]] = row

    rows, missing, drifted = [], [], []
    for it in collect():
        if it["origin"] == "mirrored":
            src = it["source"]
            if not src.exists():
                missing.append(it["raw"])
                continue
            name = src.name
            dest = MIRROR / name
            digest = sha256(src)
            shutil.copy2(src, dest)
            rows.append({
                "mirrored_name": name,
                "artifact_kind": it["kind"],
                "origin": "mirrored",
                "source_path": str(src.relative_to(REPO_ROOT)).replace("\\", "/"),
                "sha256": digest,
                "source_mtime": datetime.fromtimestamp(
                    src.stat().st_mtime, tz=timezone.utc).strftime("%Y-%m-%d %H:%M"),
                "bytes": src.stat().st_size,
                "consumer_file": it["consumer"],
                "consumer_line": it["line"],
            })
        else:
            name = f"inline_{it['consumer'].replace('.tex','')}_{it['stem']}.tex"
            dest = MIRROR / name
            body = (
                "% Extracted by sync_figures_tables.py from "
                f"{it['consumer']} line {it['line']}.\n"
                "% This table is written inline in the manuscript and has no source file\n"
                "% of its own. The extract is a copy for audit; the manuscript is the source.\n"
                + it["payload"] + "\n"
            )
            dest.write_text(body, encoding="utf-8")
            rows.append({
                "mirrored_name": name,
                "artifact_kind": it["kind"],
                "origin": "extracted",
                "source_path": f"{it['consumer']} (inline)",
                "sha256": hashlib.sha256(it["payload"].encode("utf-8")).hexdigest(),
                "source_mtime": datetime.fromtimestamp(
                    (HERE / it["consumer"]).stat().st_mtime,
                    tz=timezone.utc).strftime("%Y-%m-%d %H:%M"),
                "bytes": len(it["payload"].encode("utf-8")),
                "consumer_file": it["consumer"],
                "consumer_line": it["line"],
            })

    for r in rows:
        old = previous.get(r["mirrored_name"])
        if old and old["sha256"] != r["sha256"]:
            drifted.append(r["mirrored_name"])

    rows.sort(key=lambda r: (r["artifact_kind"], r["mirrored_name"]))
    with open(MANIFEST, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    figs = sum(1 for r in rows if r["artifact_kind"] == "figure")
    tabs = sum(1 for r in rows if r["artifact_kind"] == "table")
    ext = sum(1 for r in rows if r["origin"] == "extracted")
    print(f"mirrored to {MIRROR.relative_to(REPO_ROOT)}")
    print(f"  figures            : {figs}")
    print(f"  tables             : {tabs}  ({ext} extracted inline, {tabs - ext} \\input)")
    print(f"  manifest rows      : {len(rows)}")
    if drifted:
        print(f"  DRIFT since last run ({len(drifted)}): " + ", ".join(drifted))
    else:
        print("  drift since last run: none")
    if missing:
        print(f"  REFERENCED BUT ABSENT ({len(missing)}): " + ", ".join(missing))


if __name__ == "__main__":
    main()
