"""
13_merge_distribution.py
========================
Merge distribution data (pi, omega, e_distr) into the extended panel.
Source: Astorga (2023) 1920-2010 spliced with BCCh BDES, 1920-2024.
"""

import pandas as pd
from pathlib import Path

REPO = Path("C:/ReposGitHub/Capacity-Utilization-US_Chile")
PANEL_FILE = REPO / "output/panel/chile_panel_extended.csv"
DISTR_FILE = REPO / "data/raw/Chile/distr_19202024.xlsx"

# ── Load ─────────────────────────────────────────────────────────────
panel = pd.read_csv(PANEL_FILE, index_col="year")
distr = pd.read_excel(DISTR_FILE, sheet_name="values")
distr = distr.rename(columns={"periodo": "year", "wsh": "omega", "psh": "pi", "e": "e_distr"})
distr = distr.set_index("year")

print(f"Panel: {panel.index.min()}-{panel.index.max()}, {panel.shape[1]} cols")
print(f"Distribution: {distr.index.min()}-{distr.index.max()}, {len(distr)} rows")

# ── Merge ────────────────────────────────────────────────────────────
panel = panel.join(distr[["omega", "pi", "e_distr"]], how="left")

# ── Consistency check: pi + omega = 1 ───────────────────────────────
check = (panel["pi"] + panel["omega"] - 1).abs()
max_dev = check.dropna().max()
consist_ok = max_dev < 0.01
print(f"\nConsistency check (pi + omega = 1): {'PASSED' if consist_ok else 'FAILED'}  (max dev: {max_dev:.6f})")
if not consist_ok:
    raise AssertionError(f"pi + omega != 1, max deviation: {max_dev:.4f}")

# ── e cross-check ───────────────────────────────────────────────────
e_check = panel["pi"] / panel["omega"]
e_dev = (panel["e_distr"] - e_check).abs().dropna()
print(f"e cross-check max deviation: {e_dev.max():.6f}")

# ── Coverage ─────────────────────────────────────────────────────────
first = panel["pi"].first_valid_index()
last = panel["pi"].last_valid_index()
n = panel["pi"].notna().sum()
fordist_miss = panel.loc[1940:1978, "pi"].isna().sum()
print(f"\npi/omega coverage: {n} years ({first}-{last})")
print(f"Missing pi in Fordist window (1940-1978): {fordist_miss}")

# ── Save ─────────────────────────────────────────────────────────────
panel.to_csv(PANEL_FILE)
print(f"\nFinal panel: {panel.shape[0]} rows × {panel.shape[1]} cols")
print(f"Saved: {PANEL_FILE}")
