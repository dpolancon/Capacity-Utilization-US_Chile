"""
chile_data_construction.py
==========================
Build the Chilean TVECM estimation panel (1940-1985, sample 1945-1978).

Two-stage architecture
----------------------
Stage 1 VECM : (m, k_ME, nrs, omega)  → extracts ECT_m
Stage 2 TVECM: (y, k_NR, k_ME, omega·k_ME)  → regime-switching on ECT_m

Inputs
------
- output/panel/chile_panel_extended.csv   (backbone: 1860-2025, 44 cols)
- FRED API: PCOPPUSDM (copper), CPIAUCSL (US CPI)

Outputs
-------
- data/final/chile_tvecm_panel.csv
- data/final/chile_tvecm_panel.RData  (via CSV; R reads directly)
- data/final/chile_tvecm_validation.md

Author : Diego Polanco / Claude Code
Date   : 2026-04-06
"""

import warnings
warnings.filterwarnings("ignore", category=FutureWarning)

import sys
from pathlib import Path
import numpy as np
import pandas as pd
from io import StringIO
from datetime import datetime

# ---------------------------------------------------------------------------
# 0. PATHS
# ---------------------------------------------------------------------------
ROOT = Path(r"C:\ReposGitHub\Capacity-Utilization-US_Chile")
PANEL_PATH = ROOT / "output" / "panel" / "chile_panel_extended.csv"
RAW_CHILE  = ROOT / "data" / "raw" / "Chile"
OUT_DIR    = ROOT / "data" / "final"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SAMPLE_START = 1940
SAMPLE_END   = 1978
# Context window: all years where Kg_ME, Kg_NRC, and omega are jointly available.
# Capital stocks: 1900-2024 (K-Stock-Harmonization); omega: 1920-2024 (distr file).
# Joint availability: 1920-2024.
CONTEXT_START = 1920
CONTEXT_END   = 2024

# ---------------------------------------------------------------------------
# VARIABLE → STAGE MAPPING
# ---------------------------------------------------------------------------
# Stage 1 VECM:  (m, k_ME, nrs, omega)        → extracts ECT_m
# Stage 2 TVECM: (y, k_NR, k_ME, omega·k_ME)  → regime-switching on ECT_m(t-1)
# Post-estimation: phi = K_ME / K_NR           → transformation elasticity formula
#
# k_ME enters BOTH stages (overlap).
# omega enters Stage 1 directly AND Stage 2 via the interaction omega·k_ME.
STAGE_MAP = {
    # variable    : (stage_1, stage_2, post_est, role)
    "y"           : (False, True,  False, "Stage 2 state vector"),
    "k_NR"        : (False, True,  False, "Stage 2 state vector"),
    "k_ME"        : (True,  True,  False, "Stage 1 + Stage 2 state vector (overlap)"),
    "m"           : (True,  False, False, "Stage 1 state vector"),
    "nrs"         : (True,  False, False, "Stage 1 state vector"),
    "omega"       : (True,  True,  False, "Stage 1 state vector; Stage 2 via interaction"),
    "omega_kME"   : (False, True,  False, "Stage 2 state vector (interaction ω·k_ME)"),
    "phi"         : (False, False, True,  "Post-estimation: composition K_ME/K_NR"),
    "tot"         : (True,  False, False, "Stage 1 exogenous / conditioning"),
    "pcu"         : (True,  False, False, "Stage 1 exogenous / conditioning"),
    "rer"         : (True,  False, False, "Stage 1 exogenous / conditioning"),
    "ner"         : (True,  False, False, "Stage 1 exogenous / conditioning"),
    "p_Y"         : (False, False, False, "Auxiliary deflator"),
    "p_M"         : (False, False, False, "Auxiliary deflator"),
    "pi"          : (False, False, False, "Auxiliary (used in NRS construction)"),
}

# ---------------------------------------------------------------------------
# 1. LOAD BACKBONE PANEL
# ---------------------------------------------------------------------------
print("=" * 70)
print("CHILE TVECM DATA CONSTRUCTION PIPELINE")
print("=" * 70)
print(f"\nLoading backbone panel: {PANEL_PATH}")

raw = pd.read_csv(PANEL_PATH)
print(f"  Loaded: {raw.shape[0]} rows × {raw.shape[1]} cols, "
      f"years {raw['year'].min()}-{raw['year'].max()}")

# ---------------------------------------------------------------------------
# 2. VERIFY GROSS CAPITAL STOCKS
# ---------------------------------------------------------------------------
print("\n--- Step 0: Verify gross capital stocks ---")

for col in ["Kg_ME", "Kg_NRC"]:
    if col not in raw.columns:
        sys.exit(f"CRITICAL: {col} not found in panel. "
                 "Gross stocks are required — halting.")
    n_valid = raw.loc[
        (raw["year"] >= SAMPLE_START) & (raw["year"] <= SAMPLE_END), col
    ].notna().sum()
    expected = SAMPLE_END - SAMPLE_START + 1
    print(f"  {col}: {n_valid}/{expected} obs in sample window")
    if n_valid < expected:
        sys.exit(f"CRITICAL: {col} has gaps in {SAMPLE_START}-{SAMPLE_END}. Halting.")

print("  ✓ Gross stocks verified (Kg_ME, Kg_NRC present, complete in sample)")

# ---------------------------------------------------------------------------
# 3. CONSTRUCT TVECM VARIABLES
# ---------------------------------------------------------------------------
df = raw[["year"]].copy()

# --- y: log real GDP (2003 CLP) ---
print("\n--- Step 1: y = ln(Y_real) ---")
df["Y_real"] = raw["Y_real"]
df["y"] = np.log(raw["Y_real"])

# --- k_NR, k_ME: log gross capital stocks ---
print("--- Step 0 (cont.): k_NR, k_ME from gross stocks ---")
df["K_NR_gross"] = raw["Kg_NRC"]          # NRC = non-residential construction
df["K_ME_gross"] = raw["Kg_ME"]           # ME  = machinery & equipment
df["k_NR"] = np.log(raw["Kg_NRC"])
df["k_ME"] = np.log(raw["Kg_ME"])

# --- phi: composition ratio (levels, not logged) ---
print("--- Step 11 (partial): phi = K_ME / K_NR ---")
df["phi"] = raw["Kg_ME"] / raw["Kg_NRC"]

# --- m: log real imports (2003 CLP) ---
print("--- Step 2: m = ln(M_real) ---")
df["M_real"] = raw["M_real"]
df["m"] = np.log(raw["M_real"])
neg_m = raw.loc[raw["M_real"] <= 0]
if len(neg_m) > 0:
    print(f"  ⚠ WARNING: M_real ≤ 0 in years: {list(neg_m['year'])}")

# --- nrs: log non-reinvested surplus ---
print("--- Step 3: nrs = ln(Π - I) ---")
df["GOS"] = raw["pi"] * raw["Y_real"]   # Gross operating surplus = π·Y
df["I_total"] = raw["I_real"]
df["NRS"] = df["GOS"] - df["I_total"]

# Handle negative NRS
neg_nrs = df.loc[
    (df["year"] >= CONTEXT_START) & (df["year"] <= CONTEXT_END) & (df["NRS"] <= 0)
]
if len(neg_nrs) > 0:
    print(f"  ⚠ WARNING: NRS ≤ 0 in years: {list(neg_nrs['year'].values)}")
    print(f"    These observations will have nrs = NaN")

df["nrs"] = np.where(df["NRS"] > 0, np.log(df["NRS"]), np.nan)

nrs_sample = df.loc[
    (df["year"] >= SAMPLE_START) & (df["year"] <= SAMPLE_END)
]
n_nrs_valid = nrs_sample["nrs"].notna().sum()
n_expected = SAMPLE_END - SAMPLE_START + 1
print(f"  nrs valid in sample: {n_nrs_valid}/{n_expected}")

# --- omega: wage share (ratio, NOT logged) ---
print("--- Step 4: omega (wage share, ratio) ---")
df["omega"] = raw["omega"]

# Range check
omega_sample = df.loc[
    (df["year"] >= SAMPLE_START) & (df["year"] <= SAMPLE_END), "omega"
].dropna()
assert (omega_sample > 0).all() and (omega_sample < 1).all(), \
    "omega out of (0,1) range in sample!"
print(f"  omega range in sample: [{omega_sample.min():.4f}, {omega_sample.max():.4f}]")

# --- omega_kME: interaction term ---
print("--- Step 11 (partial): omega_kME = omega · k_ME ---")
df["omega_kME"] = df["omega"] * df["k_ME"]

# --- Deflators (from backbone — auxiliary, start 1940) ---
print("--- Step 5-6: Deflators (P_Y, P_M, P_X) ---")
df["p_Y"] = raw["P_Y"]
df["p_M"] = raw["P_M"]
df["p_X"] = raw["P_X"]

# --- tot: log terms of trade (from ClioLab 4.3.2 — extends to 1810) ---
print("--- Step 7: tot = ln(ToT) from ClioLab 4.3.2 ---")
CLIOLAB = RAW_CHILE / "W04_Precios_ClioLabPUC.xlsx"
tot_raw = pd.read_excel(CLIOLAB, "4.3.2", header=None, skiprows=11)
tot_raw.columns = ["year", "TERMINT"]
tot_raw = tot_raw.dropna(subset=["year"]).copy()
tot_raw["year"] = tot_raw["year"].astype(int)
tot_raw["TERMINT"] = pd.to_numeric(tot_raw["TERMINT"], errors="coerce")
tot_raw["tot"] = np.log(tot_raw["TERMINT"])
df = df.merge(tot_raw[["year", "tot"]], on="year", how="left")
n_tot = df.loc[
    (df["year"] >= SAMPLE_START) & (df["year"] <= SAMPLE_END), "tot"
].notna().sum()
print(f"  tot (ClioLab 4.3.2, TERMINT index 2003=100): {n_tot}/{SAMPLE_END - SAMPLE_START + 1} in sample")

# --- pi: profit share (keep for reference, used in NRS) ---
df["pi"] = raw["pi"]

# ---------------------------------------------------------------------------
# 4. EXTERNAL SERIES: COPPER, EXCHANGE RATES (all from ClioLab W04)
# ---------------------------------------------------------------------------

# --- Step 8: Real copper price ---
print("\n--- Step 8: Real copper price (pcu) ---")
# Sheet 4.3.3: COP_USA03 = real copper price in 2003 USD/lb (already deflated)
cu_raw = pd.read_excel(CLIOLAB, "4.3.3", header=None, skiprows=11)
cu_raw.columns = ["year", "COP_LOND", "COP_LOND03", "COP_USA", "COP_USA03"]
cu_raw = cu_raw.dropna(subset=["year"]).copy()
cu_raw["year"] = cu_raw["year"].astype(int)
cu_raw["COP_USA03"] = pd.to_numeric(cu_raw["COP_USA03"], errors="coerce")
cu_raw["pcu"] = np.log(cu_raw["COP_USA03"])

df = df.merge(cu_raw[["year", "pcu"]], on="year", how="left")
n_pcu = df.loc[
    (df["year"] >= SAMPLE_START) & (df["year"] <= SAMPLE_END), "pcu"
].notna().sum()
print(f"  pcu (ClioLab 4.3.3, COP_USA03 = 2003 USD/lb): {n_pcu}/{SAMPLE_END - SAMPLE_START + 1} in sample")

# --- Step 9: Exchange rates ---
print("\n--- Step 9: Exchange rates (ner, rer) ---")

# Sheet 4.2.1: TCNUSD = nominal exchange rate, "pesos actuales" per USD.
# ClioLab already handles the peso→escudo (1960) and escudo→peso (1975)
# redenominations by expressing the entire series in equivalent modern pesos.
ner_raw = pd.read_excel(CLIOLAB, "4.2.1", header=None, skiprows=11)
ner_raw.columns = ["year", "TCNUSD", "TCNLIB"]
ner_raw = ner_raw.dropna(subset=["year"]).copy()
ner_raw["year"] = ner_raw["year"].astype(int)
ner_raw["TCNUSD"] = pd.to_numeric(ner_raw["TCNUSD"], errors="coerce")
ner_raw["ner"] = np.log(ner_raw["TCNUSD"])

# Sheet 4.2.2: TCREAL = real exchange rate index, 2003 = 100.
# Increase = real depreciation of CLP.
rer_raw = pd.read_excel(CLIOLAB, "4.2.2", header=None, skiprows=11)
rer_raw.columns = ["year", "TCREAL"]
rer_raw = rer_raw.dropna(subset=["year"]).copy()
rer_raw["year"] = rer_raw["year"].astype(int)
rer_raw["TCREAL"] = pd.to_numeric(rer_raw["TCREAL"], errors="coerce")
rer_raw["rer"] = np.log(rer_raw["TCREAL"])

df = df.merge(ner_raw[["year", "ner"]], on="year", how="left")
df = df.merge(rer_raw[["year", "rer"]], on="year", how="left")

for label, col in [("ner", "ner"), ("rer", "rer")]:
    n = df.loc[
        (df["year"] >= SAMPLE_START) & (df["year"] <= SAMPLE_END), col
    ].notna().sum()
    print(f"  {label} (ClioLab 4.2.{'1' if col == 'ner' else '2'}): {n}/{SAMPLE_END - SAMPLE_START + 1} in sample")

# ---------------------------------------------------------------------------
# 5. STRUCTURAL BREAK DUMMIES
# ---------------------------------------------------------------------------
print("\n--- Step 10: Structural break dummies ---")
df["D1973"] = (df["year"] == 1973).astype(int)
df["D1975"] = (df["year"] == 1975).astype(int)
df["D7375"] = df["year"].isin([1973, 1974, 1975]).astype(int)
df["D1982"] = (df["year"] == 1982).astype(int)

# ---------------------------------------------------------------------------
# 6. SAMPLE FLAG
# ---------------------------------------------------------------------------
df["in_sample"] = (df["year"] >= SAMPLE_START) & (df["year"] <= SAMPLE_END)

# ---------------------------------------------------------------------------
# 7. TRIM TO CONTEXT WINDOW AND VERIFY
# ---------------------------------------------------------------------------
print("\n--- Step 12: Panel assembly and verification ---")

# Keep wider window for context (pre-sample lags, post-sample if needed)
panel = df.loc[
    (df["year"] >= CONTEXT_START) & (df["year"] <= CONTEXT_END)
].copy().reset_index(drop=True)

print(f"  Panel: {panel.shape[0]} rows × {panel.shape[1]} cols "
      f"({panel['year'].min()}-{panel['year'].max()})")

# Verify interaction term completeness
mask_both = panel[["omega", "k_ME"]].notna().all(axis=1)
mask_inter = panel["omega_kME"].notna()
assert mask_both.sum() == mask_inter.sum(), \
    "omega_kME has unexpected NaNs where omega and k_ME are defined"
print("  ✓ omega_kME consistent with omega and k_ME")

# Column order for export
EXPORT_COLS = [
    "year",
    # State vectors
    "y", "k_NR", "k_ME", "m", "nrs", "omega", "omega_kME",
    # Composition
    "phi",
    # Deflators
    "p_Y", "p_M",
    # External
    "tot", "pcu", "rer", "ner",
    # Dummies
    "D1973", "D1975", "D7375", "D1982",
    # Levels (for reference / post-estimation)
    "Y_real", "M_real", "K_NR_gross", "K_ME_gross", "GOS", "I_total", "NRS",
    "pi",
    # Flag
    "in_sample",
]
# Only include columns that exist
export_cols = [c for c in EXPORT_COLS if c in panel.columns]
panel = panel[export_cols]

# ---------------------------------------------------------------------------
# 8. COVERAGE SUMMARY TABLE
# ---------------------------------------------------------------------------
N_SAMPLE = SAMPLE_END - SAMPLE_START + 1

print("\n" + "=" * 70)
print(f"SERIES COVERAGE SUMMARY (in-sample: {SAMPLE_START}-{SAMPLE_END}, N={N_SAMPLE})")
print("=" * 70)

sample = panel.loc[panel["in_sample"]].copy()
LOG_SERIES = ["y", "k_NR", "k_ME", "m", "nrs", "omega", "omega_kME",
              "phi", "tot", "pcu", "rer", "ner"]

coverage_rows = []
for col in LOG_SERIES:
    if col not in sample.columns:
        continue
    s = sample[col].dropna()
    first_yr = panel.loc[panel[col].notna(), "year"].min()
    last_yr  = panel.loc[panel[col].notna(), "year"].max()
    row = {
        "variable": col,
        "first_year": int(first_yr) if pd.notna(first_yr) else "—",
        "last_year": int(last_yr) if pd.notna(last_yr) else "—",
        "n_valid_sample": len(s),
        "n_nan_sample": N_SAMPLE - len(s),
        "mean": f"{s.mean():.4f}" if len(s) > 0 else "—",
        "std":  f"{s.std():.4f}" if len(s) > 0 else "—",
        "min":  f"{s.min():.4f}" if len(s) > 0 else "—",
        "max":  f"{s.max():.4f}" if len(s) > 0 else "—",
    }
    coverage_rows.append(row)

cov_df = pd.DataFrame(coverage_rows)
print(cov_df.to_string(index=False))

# ---------------------------------------------------------------------------
# 9. VALIDATION REPORT
# ---------------------------------------------------------------------------
print("\n--- Writing validation report ---")

report_lines = []
report_lines.append("# Chile TVECM Panel — Validation Report")
report_lines.append(f"\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
report_lines.append(f"Pipeline: `codes/stage_a/chile/chile_data_construction.py`")
report_lines.append(f"Source panel: `output/panel/chile_panel_extended.csv`")
report_lines.append(f"\n## Panel dimensions")
report_lines.append(f"- Rows: {panel.shape[0]} (years {panel['year'].min()}-{panel['year'].max()})")
report_lines.append(f"- Columns: {panel.shape[1]}")
report_lines.append(f"- Estimation sample: {SAMPLE_START}-{SAMPLE_END} (N={N_SAMPLE})")

report_lines.append(f"\n## Series coverage (in-sample: {SAMPLE_START}-{SAMPLE_END})")
report_lines.append("")
report_lines.append("| Variable | First yr | Last yr | Valid | NaN | Mean | Std | Min | Max |")
report_lines.append("|----------|----------|---------|-------|-----|------|-----|-----|-----|")
for _, r in cov_df.iterrows():
    report_lines.append(
        f"| {r['variable']} | {r['first_year']} | {r['last_year']} | "
        f"{r['n_valid_sample']} | {r['n_nan_sample']} | "
        f"{r['mean']} | {r['std']} | {r['min']} | {r['max']} |"
    )

# Critical flags
report_lines.append("\n## Critical flags")
flags = []

# NRS negative check
neg_nrs_all = df.loc[
    (df["year"] >= CONTEXT_START) & (df["year"] <= CONTEXT_END) & (df["NRS"] <= 0)
]
if len(neg_nrs_all) > 0:
    flags.append(f"- **NRS ≤ 0** in years: {list(neg_nrs_all['year'].values)}. "
                 f"nrs set to NaN for these observations.")
else:
    flags.append("- NRS > 0 for all years in context window. No log issues.")

# Omega bounds
omega_ok = (sample["omega"] > 0).all() and (sample["omega"] < 1).all()
flags.append(f"- omega range check: {'PASS' if omega_ok else 'FAIL'} "
             f"[{sample['omega'].min():.4f}, {sample['omega'].max():.4f}]")

# Missing series
for col in ["pcu", "rer", "ner"]:
    n_miss = sample[col].isna().sum() if col in sample.columns else 34
    if n_miss == 34:
        flags.append(f"- **{col}: entirely missing in sample** — external sourcing required")
    elif n_miss > 0:
        flags.append(f"- {col}: {n_miss}/{N_SAMPLE} NaN in sample")

# Capital stock type
flags.append("- Capital stocks: **gross** (Kg_ME, Kg_NRC from K-Stock-Harmonization). Verified.")
flags.append("- Price base: 2003 CLP throughout (deflators indexed 2003=100)")

for f in flags:
    report_lines.append(f)

# NRS detail
report_lines.append("\n## NRS construction detail")
report_lines.append(f"- GOS = π × Y_real (profit share × real GDP)")
report_lines.append(f"- I_total = I_real (gross fixed capital formation)")
report_lines.append(f"- NRS = GOS − I_total")
nrs_s = sample[["year", "GOS", "I_total", "NRS", "nrs"]].copy()
nrs_s = nrs_s.rename(columns={"GOS": "Π", "I_total": "I", "NRS": "Π−I"})
report_lines.append(f"\n| Year | Π (GOS) | I (GFCF) | Π−I (NRS) | ln(NRS) |")
report_lines.append(f"|------|---------|----------|-----------|---------|")
for _, r in nrs_s.iterrows():
    report_lines.append(
        f"| {int(r['year'])} | {r['Π']:,.0f} | {r['I']:,.0f} | "
        f"{r['Π−I']:,.0f} | {r['nrs']:.4f} |"
    )

# Correlation matrix
report_lines.append("\n## Pairwise correlations (in-sample, log-level series)")
corr_cols = [c for c in ["y", "k_NR", "k_ME", "m", "nrs", "omega", "phi", "tot"]
             if c in sample.columns and sample[c].notna().sum() > 5]
if len(corr_cols) > 1:
    corr = sample[corr_cols].corr()
    report_lines.append("")
    report_lines.append("| | " + " | ".join(corr_cols) + " |")
    report_lines.append("|" + "---|" * (len(corr_cols) + 1))
    for idx in corr.index:
        vals = " | ".join(f"{corr.loc[idx, c]:.3f}" for c in corr_cols)
        report_lines.append(f"| {idx} | {vals} |")

# Unit root pre-tests
report_lines.append("\n## Unit root pre-tests (ADF)")
try:
    from statsmodels.tsa.stattools import adfuller

    adf_cols = [c for c in ["y", "k_NR", "k_ME", "m", "nrs", "omega", "phi", "tot"]
                if c in sample.columns and sample[c].notna().sum() >= 20]

    report_lines.append("\n### Levels (expect: fail to reject H₀ of unit root)")
    report_lines.append("")
    report_lines.append("| Series | ADF stat | p-value | Lags | 1% cv | 5% cv | 10% cv | Reject 5%? |")
    report_lines.append("|--------|----------|---------|------|-------|-------|--------|------------|")

    for col in adf_cols:
        s = sample[col].dropna().values
        try:
            stat, pval, usedlag, nobs, cv, _ = adfuller(s, maxlag=3, autolag="AIC", regression="c")
            reject = "YES ⚠" if pval < 0.05 else "no"
            report_lines.append(
                f"| {col} | {stat:.3f} | {pval:.3f} | {usedlag} | "
                f"{cv['1%']:.3f} | {cv['5%']:.3f} | {cv['10%']:.3f} | {reject} |"
            )
        except Exception as e:
            report_lines.append(f"| {col} | ERROR: {e} | | | | | |")

    report_lines.append("\n### First differences (expect: reject H₀ → confirms I(1))")
    report_lines.append("")
    report_lines.append("| Series | ADF stat | p-value | Lags | 1% cv | 5% cv | 10% cv | Reject 5%? |")
    report_lines.append("|--------|----------|---------|------|-------|-------|--------|------------|")

    for col in adf_cols:
        s = sample[col].dropna().diff().dropna().values
        try:
            stat, pval, usedlag, nobs, cv, _ = adfuller(s, maxlag=3, autolag="AIC", regression="c")
            reject = "YES ✓" if pval < 0.05 else "no ⚠"
            report_lines.append(
                f"| Δ{col} | {stat:.3f} | {pval:.3f} | {usedlag} | "
                f"{cv['1%']:.3f} | {cv['5%']:.3f} | {cv['10%']:.3f} | {reject} |"
            )
        except Exception as e:
            report_lines.append(f"| Δ{col} | ERROR: {e} | | | | | |")

except ImportError:
    report_lines.append("\n*statsmodels not available — ADF tests skipped.*")

# Stage mapping
report_lines.append("\n## Variable → Stage mapping")
report_lines.append("")
report_lines.append("| Variable | Stage 1 | Stage 2 | Post-est. | Role |")
report_lines.append("|----------|:-------:|:-------:|:---------:|------|")
for var, (s1, s2, pe, role) in STAGE_MAP.items():
    s1_mark = "**×**" if s1 else ""
    s2_mark = "**×**" if s2 else ""
    pe_mark = "**×**" if pe else ""
    report_lines.append(f"| {var} | {s1_mark} | {s2_mark} | {pe_mark} | {role} |")

# Overlap analysis
s1_vars = [v for v, (s1, s2, pe, _) in STAGE_MAP.items() if s1]
s2_vars = [v for v, (s1, s2, pe, _) in STAGE_MAP.items() if s2]
pe_vars = [v for v, (s1, s2, pe, _) in STAGE_MAP.items() if pe]
overlap = [v for v, (s1, s2, pe, _) in STAGE_MAP.items() if s1 and s2]

report_lines.append("\n### Cross-reference")
report_lines.append(f"- **Stage 1 VECM** state vector: `({', '.join(v for v in ['m','k_ME','nrs','omega'] if v in s1_vars)})`")
report_lines.append(f"- **Stage 1 exogenous**: `({', '.join(v for v in s1_vars if v not in ['m','k_ME','nrs','omega'])})`")
report_lines.append(f"- **Stage 2 TVECM** state vector: `({', '.join(v for v in ['y','k_NR','k_ME','omega_kME'] if v in s2_vars)})`")
report_lines.append(f"- **Post-estimation**: `({', '.join(pe_vars)})`")
report_lines.append(f"- **Overlap (Stage 1 ∩ Stage 2)**: `({', '.join(overlap)})`")
report_lines.append(f"  - `k_ME` is a state variable in both stages — "
                     f"it transmits the capital-deepening channel across the recursive structure.")
report_lines.append(f"  - `omega` enters Stage 1 directly and Stage 2 via the interaction "
                     f"`omega_kME = ω × k_ME` — it transmits the distributional channel.")

# Data sourcing notes
report_lines.append("\n## Data sources")
report_lines.append("| Variable | Source | Base |")
report_lines.append("|----------|--------|------|")
report_lines.append("| Y_real | Pérez & Eyzaguirre (via chile_panel_extended) | 2003 CLP |")
report_lines.append("| M_real | Pérez & Eyzaguirre (via chile_panel_extended) | 2003 CLP |")
report_lines.append("| Kg_ME, Kg_NRC | K-Stock-Harmonization (via chile_panel_extended) | 2003 CLP |")
report_lines.append("| omega, pi | distr_19202024.xlsx (via chile_panel_extended) | ratio |")
report_lines.append("| P_Y, P_X, P_M | ClioLab W04 splice (via chile_panel_extended) | 2003=100 |")
report_lines.append("| tot | ClioLab W04 sheet 4.3.2 (TERMINT, index 2003=100) | log |")
report_lines.append("| I_real | Pérez & Eyzaguirre (via chile_panel_extended) | 2003 CLP |")
report_lines.append("| pcu | ClioLab W04 sheet 4.3.3 (COP_USA03) | 2003 USD/lb |")
report_lines.append("| ner | ClioLab W04 sheet 4.2.1 (TCNUSD, pesos actuales/USD) | log |")
report_lines.append("| rer | ClioLab W04 sheet 4.2.2 (TCREAL, index 2003=100) | log |")

report_lines.append("\n## Outstanding items")
report_lines.append("- All series sourced. ClioLab W04 provides copper, NER, and RER "
                     "with redenomination handling built in.")
report_lines.append("- Note: ClioLab coverage ends 2010. Post-2010 extension would "
                     "require BCCh for exchange rates and World Bank for copper.")

report_lines.append(f"\n---\n*Report generated by chile_data_construction.py — {datetime.now().isoformat()}*")

report_path = OUT_DIR / "chile_tvecm_validation.md"
report_path.write_text("\n".join(report_lines), encoding="utf-8")
print(f"  Validation report: {report_path}")

# ---------------------------------------------------------------------------
# 10. EXPORT
# ---------------------------------------------------------------------------
print("\n--- Step 14: Export ---")

csv_path = OUT_DIR / "chile_tvecm_panel.csv"
panel.to_csv(csv_path, index=False)
print(f"  CSV: {csv_path}")
print(f"       {panel.shape[0]} rows × {panel.shape[1]} cols")

# R-compatible note: R reads this CSV directly via read.csv()
# Column names use underscores (R-safe)
rdata_note = OUT_DIR / "chile_tvecm_panel_README.txt"
rdata_note.write_text(
    "# Chile TVECM Panel\n"
    "# Load in R:\n"
    "#   df <- read.csv('chile_tvecm_panel.csv')\n"
    "#   sample <- df[df$in_sample == TRUE, ]\n"
    f"# Generated: {datetime.now().isoformat()}\n"
    f"# Columns: {', '.join(panel.columns)}\n",
    encoding="utf-8"
)

print("\n" + "=" * 70)
print("PIPELINE COMPLETE")
print("=" * 70)
print(f"  Panel:      {csv_path}")
print(f"  Validation: {report_path}")
print(f"  R readme:   {rdata_note}")

# Final coverage check
sample_final = panel.loc[panel["in_sample"]]
complete_cols = [c for c in ["y", "k_NR", "k_ME", "m", "nrs", "omega", "omega_kME"]
                 if sample_final[c].notna().all()]
missing_cols = [c for c in ["pcu", "rer", "ner"]
                if c in sample_final.columns and sample_final[c].isna().all()]
print(f"\n  Stage-ready variables ({N_SAMPLE}/{N_SAMPLE}):  {', '.join(complete_cols)}")
if missing_cols:
    print(f"  Missing (need external source): {', '.join(missing_cols)}")
