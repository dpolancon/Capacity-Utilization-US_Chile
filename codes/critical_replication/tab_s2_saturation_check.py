#!/usr/bin/env python3
"""Run 4+1 saturation checks for Stage-2 ARDL envelope schema stability.

Scenarios:
  v1 clean baseline
  v2 aliases only
  v3 alias+canonical coexistence (expected fail-fast)
  v4 duplicate-suffixed variants (.1) present
  v5 final single canonical run
"""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path

ALIAS_MAP = {"k": "k_total", "ICOMP": "ICOMP_pen", "RICOMP": "RICOMP_pen"}


def read_table(path: Path):
    with path.open(newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        cols = reader.fieldnames or []
    return cols, rows


def write_table(path: Path, cols, rows):
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(cols))
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row.get(k, "") for k in cols})


def canonicalize_cols(cols):
    seen = set()
    for c in cols:
        if c in seen:
            return False, f"duplicate names detected: {c}", cols
        seen.add(c)

    coexist = [f"{a}/{c}" for a, c in ALIAS_MAP.items() if a in cols and c in cols]
    if coexist:
        return False, "alias+canonical coexist: " + ", ".join(coexist), cols

    out = [c for c in cols if c not in ALIAS_MAP and not re.search(r"\.[0-9]+$", c)]
    seen = set()
    for c in out:
        if c in seen:
            return False, f"duplicates remain after canonicalize: {c}", out
        seen.add(c)

    return True, "ok", out


def scenario_cols(cols, scenario_num):
    cols = list(cols)
    if scenario_num == 1:
        return cols
    if scenario_num == 2:  # aliases only
        cols = [c for c in cols if c not in ALIAS_MAP.values()]
        for a in ALIAS_MAP:
            if a not in cols:
                cols.append(a)
        return cols
    if scenario_num == 3:  # alias + canonical coexistence
        for a, c in ALIAS_MAP.items():
            if c in cols and a not in cols:
                cols.append(a)
        return cols
    if scenario_num == 4:  # duplicate-suffixed variants
        out = []
        for c in cols:
            out.append(c)
            if c in ("k_total", "ICOMP_pen", "RICOMP_pen"):
                out.append(f"{c}.1")
        return out
    if scenario_num == 5:  # final single canonical
        ok, _, canon = canonicalize_cols(cols)
        return canon if ok else cols
    raise ValueError("scenario_num must be in 1..5")


def run_saturation(files):
    names = {
        1: "v1_clean_baseline",
        2: "v2_alias_only",
        3: "v3_alias_plus_canonical",
        4: "v4_suffix_duplicates",
        5: "v5_final_single_canonical",
    }
    report = []
    for i in range(1, 6):
        details = []
        all_ok = True
        for path in files:
            cols, _ = read_table(path)
            cols_s = scenario_cols(cols, i)
            ok, msg, _ = canonicalize_cols(cols_s)
            all_ok &= ok
            details.append({"file": path.name, "ok": ok, "message": msg})
        report.append({"scenario": names[i], "pass": all_ok, "details": details})
    return report


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--apply-final-canonical", action="store_true",
                    help="Rewrite Stage-2 envelope CSVs to canonical schema before running saturation checks.")
    ap.add_argument("--report-path", default="output/CriticalReplication/Manifest/logs/TAB_S2_saturation_report.json")
    args = ap.parse_args()

    root = Path(args.repo_root).resolve()
    base = root / "output" / "CriticalReplication" / "Exercise_b_ARDL_grid" / "csv"
    files = [
        base / "ENVELOPE_ARDL_logLik_vs_k_total.csv",
        base / "ENVELOPE_ARDL_logLik_vs_ICOMP_pen.csv",
        base / "ENVELOPE_ARDL_logLik_vs_RICOMP_pen.csv",
    ]

    if args.apply_final_canonical:
        for p in files:
            cols, rows = read_table(p)
            _, _, canon = canonicalize_cols(cols)
            write_table(p, canon, rows)

    report = run_saturation(files)
    for item in report:
        print(f"[{item['scenario']}] pass={item['pass']}")
        for d in item["details"]:
            print(f"  - {d['file']}: ok={d['ok']} | {d['message']}")

    out = root / args.report_path
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2))
    print(f"REPORT_WRITTEN {out}")


if __name__ == "__main__":
    main()
