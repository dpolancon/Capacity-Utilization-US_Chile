"""
12_extend_panel_bcch.py
=======================
Extend Chilean panel real quantities from 2011 to 2025 using BCCh
national accounts (reference 2018).

Method:
  1. Compute BCCh real at 2018 prices = nominal / deflator * 100
  2. Chain-link at 2010: anchor each component to PerezEyzaguirre level
     scale_factor = PE_real(2010) / BCCh_real_2018(2010)
     This preserves BCCh growth rates while anchoring to 2003-price levels.
  3. Fill 2011-2025 real quantities into existing panel rows

Scope restriction (critical):
  - Extension is for CU estimation window only
  - Profitability decomposition & investment function: 1940-1978, unchanged
  - Source change at 2011 flagged; BCCh post-2010 may not be stock-flow
    consistent with PerezEyzaguirre
  - I_ME_real / I_NRC_real: NaN for 2011-2025 (BCCh does not disaggregate)
"""

import pandas as pd
import numpy as np
from pathlib import Path

# ── paths ────────────────────────────────────────────────────────────
REPO = Path("C:/ReposGitHub/Capacity-Utilization-US_Chile")
BCCH_FILE = REPO / "data/raw/Chile/ADnominal_deflators_19962025_BCCH.xlsx"
PANEL_IN  = REPO / "output/panel/chile_panel.csv"
PANEL_OUT = REPO / "output/panel/chile_panel_extended.csv"

# ── BCCh row mapping (sheet Canasta) ─────────────────────────────────
# Nominal rows (0-indexed from raw.iloc):
#   1=C, 2=G, 3=FBKF, 4=INV, 5=X, 6=M, 7=GDP
# Deflator rows:
#   8=P_C, 9=P_G, 10=P_FBKF, 11=P_X, 12=P_M, 13=P_Y
BCCH_COMPONENTS = {
    "Y_real":  (7, 13),
    "C_real":  (1, 8),
    "G_real":  (2, 9),
    "I_real":  (3, 10),   # FBKF only — excludes inventories
    "X_real":  (5, 11),
    "M_real":  (6, 12),
}


def load_bcch_real():
    """Derive BCCh real quantities at 2018 prices from nominal/deflator."""
    raw = pd.read_excel(BCCH_FILE, sheet_name="Canasta", header=None)
    years = [int(y.year) if hasattr(y, "year") else int(y)
             for y in raw.iloc[0, 2:]]

    result = {}
    for var, (nom_row, defl_row) in BCCH_COMPONENTS.items():
        nom  = pd.to_numeric(raw.iloc[nom_row, 2:], errors="coerce").values
        defl = pd.to_numeric(raw.iloc[defl_row, 2:], errors="coerce").values
        # real at 2018 prices, miles de millones → millones (*1000)
        result[var] = nom / defl * 100 * 1000

    df = pd.DataFrame(result, index=years)
    df.index.name = "year"
    return df


def main():
    print("=" * 60)
    print("12_extend_panel_bcch.py — extend real quantities 2011-2025")
    print("=" * 60)

    panel = pd.read_csv(PANEL_IN, index_col="year")
    bcch  = load_bcch_real()
    print(f"Base panel:  {panel.index.min()}-{panel.index.max()}, {panel.shape[1]} cols")
    print(f"BCCh real:   {bcch.index.min()}-{bcch.index.max()}")

    # ── Chain-link at 2010 ───────────────────────────────────────────
    chain_vars = list(BCCH_COMPONENTS.keys())
    print("\nChain-link anchoring at 2010:")
    for var in chain_vars:
        pe_val   = panel.loc[2010, var]
        bcch_val = bcch.loc[2010, var]
        sf = pe_val / bcch_val
        print(f"  {var:10s}: PE={pe_val:>14,.0f}  BCCh_2018={bcch_val:>14,.0f}  scale={sf:.6f}")
        bcch[var] = bcch[var] * sf

    # ── Fill 2011-2025 into panel ────────────────────────────────────
    ext_years = range(2011, 2026)
    for var in chain_vars:
        for yr in ext_years:
            if yr in bcch.index:
                panel.loc[yr, var] = bcch.loc[yr, var]

    # NX_real for extension years
    for yr in ext_years:
        if yr in panel.index:
            panel.loc[yr, "NX_real"] = panel.loc[yr, "X_real"] - panel.loc[yr, "M_real"]

    # ── Source column ────────────────────────────────────────────────
    panel["source"] = "PerezEyzaguirre"
    for yr in ext_years:
        if yr in panel.index:
            panel.loc[yr, "source"] = "BCCh_2018ref_chainlinked2010"

    # ── Period / window flags for any new rows ───────────────────────
    for yr in ext_years:
        if yr in panel.index:
            panel.loc[yr, "period"] = "neoliberal"
            panel.loc[yr, "in_investment_window"] = False

    # ── Nominal series (full available span) ─────────────────────────
    panel["Y_nom"]     = panel["Y_real"]     * panel["P_Y"]      / 100
    panel["C_nom"]     = panel["C_real"]     * panel["P_C"]      / 100
    panel["G_nom"]     = panel["G_real"]     * panel["P_G"]      / 100
    panel["I_nom"]     = panel["I_real"]     * panel["P_K_fbkf"] / 100
    panel["X_nom"]     = panel["X_real"]     * panel["P_X"]      / 100
    panel["M_nom"]     = panel["M_real"]     * panel["P_M"]      / 100
    panel["NX_nom"]    = panel["X_nom"]      - panel["M_nom"]
    panel["I_ME_nom"]  = panel["I_ME_real"]  * panel["P_K_fbkf"] / 100
    panel["I_NRC_nom"] = panel["I_NRC_real"] * panel["P_K_fbkf"] / 100

    # ── Continuity check at splice (2010→2011) ───────────────────────
    print(f"\nGrowth rates at splice (2010→2011):")
    warnings = []
    for var in chain_vars + ["NX_real"]:
        v2010 = panel.loc[2010, var]
        v2011 = panel.loc[2011, var]
        gr = v2011 / v2010 - 1
        flag = " *** WARNING" if abs(gr) > 0.10 else ""
        print(f"  {var:10s}: {gr:+.3%}{flag}")
        if abs(gr) > 0.10:
            warnings.append(var)

    # ── Summary ──────────────────────────────────────────────────────
    print(f"\n{'='*60}")
    print(f"Extended panel shape: {panel.shape[0]} rows × {panel.shape[1]} cols")
    print(f"Year range:          {panel.index.min()}-{panel.index.max()}")
    print(f"Real quantity coverage:")
    print(f"  PerezEyzaguirre:   1860-2010")
    print(f"  BCCh (chain-link): 2011-2025")
    print(f"CU estimation window:  1940-2025 (max coverage)")
    print(f"Profitability / investment window: 1940-1978 (unchanged, PE only)")
    print(f"I_ME_real / I_NRC_real: NaN for 2011-2025 (BCCh does not disaggregate FBKF)")
    if warnings:
        print(f"Continuity warnings (>10% growth): {warnings}")

    # Missing values post-1940
    post1940 = panel.loc[1940:]
    miss = post1940.isnull().sum()
    miss = miss[miss > 0].sort_values(ascending=False)
    if len(miss) > 0:
        print(f"\nMissing values by variable (post-1940):")
        for v, n in miss.items():
            print(f"  {v:20s}: {n}")

    # ── Save ─────────────────────────────────────────────────────────
    panel.to_csv(PANEL_OUT)
    print(f"\nSaved: {PANEL_OUT}")


if __name__ == "__main__":
    main()
