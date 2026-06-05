"""
11_construct_panel.py (v3)
==========================
Constructs the estimation panel for Stage A.2 (Chile).

DUAL CAPITAL ACCOUNTING (locked 2026-04-03):
  For MPF / capacity utilization:
    K_gross_real = Kg  (gross real capital, 2003 CLP GPIM)
  For profit rate denominator:
    K_net_cc = Kn * p_K  (net current cost = real net x investment price deflator)
  Composition ratio:
    comp = Kg / (Kn * p_K)

State vector: (y, k_gross_NR, k_gross_ME, pi_k_gross_ME)
  k variables use log(Kg) for consistency with MPF

Reads:  data/raw/chile/ch2_raw_panel_chile.csv  (from 10_data_assembly.py)
        K-Stock-Harmonization (for p_K deflators)
Writes: data/processed/chile/ch2_panel_chile.csv
"""

import pandas as pd
import numpy as np
from pathlib import Path

REPO     = Path("C:/ReposGitHub/Capacity-Utilization-US_Chile")
KSTOCK   = Path("C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_series_2003CLP_1900_2024.csv")
IN_FILE  = REPO / "data/raw/chile/ch2_raw_panel_chile.csv"
OUT_FILE = REPO / "data/processed/chile/ch2_panel_chile.csv"
OUT_FILE.parent.mkdir(parents=True, exist_ok=True)

# ── Load K-Stock with both Kg (gross) and Kn (net) and p_K (deflator) ─────────
print("Loading K-Stock (gross + net + deflator)...")
df_k = pd.read_csv(KSTOCK)
print(f"  K-Stock columns: {list(df_k.columns)}")
print(f"  Assets: {df_k['asset'].unique()}")

# Pivot: get Kg, Kn, p_K, I for ME and NR separately
df_k_wide = df_k[df_k["asset"].isin(["ME","NR"])][
    ["year","asset","Kg","Kn","p_K","I"]
].copy()
df_k_wide = df_k_wide.pivot(index="year", columns="asset").reset_index()
df_k_wide.columns = ["year"] + [f"{col[1]}_{col[0]}" for col in df_k_wide.columns[1:]]

# Rename to clear notation
rename_map = {
    "ME_Kg": "Kg_ME",  "ME_Kn": "Kn_ME",  "ME_p_K": "pK_ME",  "ME_I": "I_ME",
    "NR_Kg": "Kg_NR",  "NR_Kn": "Kn_NR",  "NR_p_K": "pK_NR",  "NR_I": "I_NR",
}
df_k_wide = df_k_wide.rename(columns=rename_map)
print(f"  K-Stock wide: {df_k_wide['year'].min()}-{df_k_wide['year'].max()}, {len(df_k_wide)} rows")

# ── Load raw panel (GDP + distribution) ──────────────────────────────────────
df_raw = pd.read_csv(IN_FILE)
print(f"\nLoaded raw panel: {df_raw['year'].min()}-{df_raw['year'].max()}, {len(df_raw)} rows")

# ── Merge ──────────────────────────────────────────────────────────────────────
df = df_raw.merge(df_k_wide, on="year", how="left")

# ── DUAL CAPITAL ACCOUNTING ───────────────────────────────────────────────────

# --- FOR MPF / CAPACITY UTILIZATION: real GROSS capital ---
df["Kg_total"]  = df["Kg_ME"] + df["Kg_NR"]    # total gross real capital
df["k_gross_ME"] = np.log(df["Kg_ME"])           # log gross ME
df["k_gross_NR"] = np.log(df["Kg_NR"])           # log gross NR
df["k_gross"]    = np.log(df["Kg_total"])         # log total gross

# --- FOR PROFIT RATE: net CURRENT COST ---
# K_net_cc = Kn * p_K  (real net x investment price deflator)
df["Kn_cc_ME"]  = df["Kn_ME"] * df["pK_ME"]     # ME net current cost
df["Kn_cc_NR"]  = df["Kn_NR"] * df["pK_NR"]     # NR net current cost
df["Kn_cc_total"] = df["Kn_cc_ME"] + df["Kn_cc_NR"]  # total net current cost

# --- COMPOSITION RATIO: physical-to-value ---
df["comp_ME"]    = df["Kg_ME"] / df["Kn_cc_ME"]  # ME composition
df["comp_NR"]    = df["Kg_NR"] / df["Kn_cc_NR"]  # NR composition
df["comp_total"] = df["Kg_total"] / df["Kn_cc_total"]  # total composition

# --- PROFIT RATE ---
df["Pi"]         = df["pi"] * df["GDP_real"]     # total profits
df["r_nc"]       = df["Pi"] / df["Kn_cc_total"]  # monetary profit rate

# ── VECM STATE VECTOR ─────────────────────────────────────────────────────────
# Uses GROSS real capital (for MPF identification)
df["y"]           = np.log(df["GDP_real"])
df["pi_k_ME"]     = df["pi"] * df["k_gross_ME"]  # interaction: pi * log(Kg_ME)
df["pi_k_NR"]     = df["pi"] * df["k_gross_NR"]  # sensitivity

# Also keep net versions for reference
df["Kn_total"]    = df["Kn_ME"] + df["Kn_NR"]
df["k_net_ME"]    = np.log(df["Kn_ME"])
df["k_net_NR"]    = np.log(df["Kn_NR"])

# ── CAPITAL COMPOSITION (Fordist/BoP channel) ────────────────────────────────
df["phi_ME"]     = df["Kg_ME"] / df["Kg_NR"]     # ME/NR gross ratio (BoP mechanization ratio)
df["s_ME"]       = df["Kg_ME"] / df["Kg_total"]  # ME share in gross capital
df["log_phi_ME"] = np.log(df["phi_ME"])

# ── STAGE C VARIABLES ─────────────────────────────────────────────────────────
# Total gross investment
df["I_total"]    = df["I_ME"] + df["I_NR"]

# Recapitalization rate: chi = I_gross / Pi
df["chi"]        = df["I_total"] / df["Pi"]

# Terms of trade (BoP proxy, copper-price driven)
df["ToT"]        = df["X_FOB"] / df["M_CIF"]
df["ln_ToT"]     = np.log(df["ToT"].replace(0, np.nan))

# Non-reinvested surplus: NRS = Pi - I_total
df["NRS"]        = df["Pi"] - df["I_total"]
df["nrs_y"]      = df["NRS"] / df["GDP_real"]
df["nrs_y_lag"]  = df["nrs_y"].shift(1)

# ── LOG CAPITAL PRODUCTIVITY ──────────────────────────────────────────────────
# For MPF channel: b_gross = y - k_gross
df["b_gross"] = df["y"] - df["k_gross"]
# For profit rate channel: b_nc recovered post-Stage A as theta_hat * comp

# ── FORDIST WINDOW CHECK ──────────────────────────────────────────────────────
df_f = df[(df["year"] >= 1945) & (df["year"] <= 1978)]
print(f"\nFordist window (1945-1978): {len(df_f)} rows")

print("\nMissing — VECM state vector (y, k_gross_NR, k_gross_ME, pi_k_ME):")
for v in ["y","k_gross_NR","k_gross_ME","pi_k_ME"]:
    print(f"  {v}: {df_f[v].isnull().sum()} missing")

print("\nMissing — dual capital accounting:")
for v in ["Kg_ME","Kg_NR","Kn_cc_ME","Kn_cc_NR","comp_total","r_nc"]:
    print(f"  {v}: {df_f[v].isnull().sum()} missing")

print("\nMissing — Stage C:")
for v in ["chi","ToT","nrs_y"]:
    print(f"  {v}: {df_f[v].isnull().sum()} missing")

print(f"\nMean composition ratio (Fordist): {df_f['comp_total'].mean():.3f}")
print(f"Mean profit rate (Fordist): {df_f['r_nc'].mean():.4f}")

# ── SELECT OUTPUT COLUMNS ─────────────────────────────────────────────────────
cols = [
    "year",
    # VECM state vector (gross real for MPF)
    "y", "k_gross_NR", "k_gross_ME", "k_gross", "pi_k_ME", "pi_k_NR",
    # Distribution
    "pi", "omega", "exploitation_rate",
    # Dual capital accounting
    "Kg_ME", "Kg_NR", "Kg_total",           # gross real
    "Kn_ME", "Kn_NR", "Kn_total",           # net real
    "Kn_cc_ME", "Kn_cc_NR", "Kn_cc_total",  # net current cost
    "pK_ME", "pK_NR",                         # price deflators
    "comp_ME", "comp_NR", "comp_total",       # composition ratios
    # Profit rate
    "Pi", "r_nc",
    # Capital composition (BoP channel)
    "phi_ME", "s_ME", "log_phi_ME",
    # Stage C
    "chi", "I_total", "I_ME", "I_NR",
    "ToT", "ln_ToT", "NRS", "nrs_y", "nrs_y_lag",
    "b_gross",
    # Reference net real (for cross-checks)
    "k_net_ME", "k_net_NR",
    # Raw GDP
    "GDP_real", "X_FOB", "M_CIF",
]
cols = [c for c in cols if c in df.columns]
df_out = df[cols].copy()

df_out.to_csv(OUT_FILE, index=False)
print(f"\nSaved: {OUT_FILE}")
print("\nDual capital accounting locked:")
print("  VECM / MPF:    k = log(Kg)        [real gross, 2003 CLP GPIM]")
print("  Profit rate:   K_net_cc = Kn * pK  [net current cost]")
print("  Composition:   comp = Kg / K_net_cc")
print("  Stage C:       chi = I_total / Pi")
print("\nNext: Rscript codes/stage_a/chile/20_integration_tests.R")
