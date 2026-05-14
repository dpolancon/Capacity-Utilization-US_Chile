"""
14_merge_kstock.py
==================
Pivot gross capital stocks (Kg_ME, Kg_NRC) from long-format K-Stock
file and merge into the extended panel. Construct log capital stocks
for the VECM state vector: k = log(Kg).
"""

import pandas as pd
import numpy as np
from pathlib import Path

REPO = Path("C:/ReposGitHub/Capacity-Utilization-US_Chile")
PANEL_FILE = REPO / "output/panel/chile_panel_extended.csv"
KSTOCK_FILE = Path("C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_series_2003CLP_1900_2024.csv")

# ── Load ─────────────────────────────────────────────────────────────
panel = pd.read_csv(PANEL_FILE, index_col="year")
kstock = pd.read_csv(KSTOCK_FILE)
kstock = kstock[kstock["asset"].isin(["ME", "NRC"])]

print(f"Panel: {panel.index.min()}-{panel.index.max()}, {panel.shape[1]} cols")
print(f"K-Stock (ME+NRC): {kstock['year'].min()}-{kstock['year'].max()}, {len(kstock)} rows")

# ── Pivot Kg to wide ────────────────────────────────────────────────
kg_wide = kstock.pivot(index="year", columns="asset", values="Kg")
kg_wide.columns = [f"Kg_{c}" for c in kg_wide.columns]

# ── Kn consistency check ────────────────────────────────────────────
kn_wide = kstock.pivot(index="year", columns="asset", values="Kn")
kn_wide.columns = [f"Kn_{c}_check" for c in kn_wide.columns]

print("\nKn consistency check:")
for asset in ["ME", "NRC"]:
    col = f"Kn_{asset}"
    check_col = f"Kn_{asset}_check"
    if col in panel.columns:
        merged = panel[[col]].join(kn_wide[[check_col]], how="inner")
        dev = (merged[col] - merged[check_col]).abs().dropna()
        print(f"  {col}: max deviation = {dev.max():.6f}")
    else:
        print(f"  WARNING: {col} not found in panel")

# ── Merge Kg ─────────────────────────────────────────────────────────
panel = panel.join(kg_wide, how="left")

# ── Log capital stocks (VECM) ───────────────────────────────────────
panel["k_ME"]  = np.log(panel["Kg_ME"])
panel["k_NRC"] = np.log(panel["Kg_NRC"])
panel["k"]     = np.log(panel["Kg_ME"] + panel["Kg_NRC"])

# ── Coverage ─────────────────────────────────────────────────────────
print()
for var in ["Kg_ME", "Kg_NRC"]:
    n = panel[var].notna().sum()
    first = panel[var].first_valid_index()
    last = panel[var].last_valid_index()
    fordist_miss = panel.loc[1940:1978, var].isna().sum()
    print(f"{var}: {n} years ({first}-{last}), Fordist missing: {fordist_miss}")

# ── Save ─────────────────────────────────────────────────────────────
panel.to_csv(PANEL_FILE)
print(f"\nk_ME, k_NRC, k (log gross stocks) constructed")
print(f"Final panel: {panel.shape[0]} rows × {panel.shape[1]} cols")
print(f"Saved: {PANEL_FILE}")
