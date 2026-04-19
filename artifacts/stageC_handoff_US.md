# Stage C Handoff — US Investment Function Estimation
## Claude Code Session Artifact
**Date:** 2026-04-06 | **Country:** United States | **Sector:** Non-Financial Corporate

---

## 1. What has been completed

### Stage A — Structural identification of the MPF via Johansen VECM

**Script:** `codes/stage_a/us/37_agnostic_absolute_us.R` (unrestricted), `39_restricted_vecm_absolute_us.R` (short-run restrictions)

- **State vector:** X = (y, k, omega, omega*k)' in absolute 2024-price log-levels + ecdet="const"
- **Rank:** r = 3 confirmed (trace + max-eigen at 1%)
- **Short-run restrictions:** alpha[omega_k, .] = 0, Gamma[omega_k, .] = 0, Gamma[., omega_k] = 0 (interaction excluded from short-run dynamics)
- **CV1 (y-normalized):** y = 8.9238*k + 222.1611*omega - 12.8509*(omega*k) - 138.2544
- **Transformation elasticity:** theta(omega) = 8.924 - 12.851*omega
- **Knife-edge:** omega_H = 0.617 (inside sample [0.565, 0.678])
- **Crisis boundary:** omega* = 0.694 (theta=0, outside sample)
- **Rank-1 robustness:** beta_1 identical at r=1 and r=3 (script 42)
- **Capacity utilization:** mu pinned at mu(1948) = 0.80 (Federal Reserve benchmark), frontier grown via g(Y*) = theta * g(K)
- **Reports:** `output/stage_a/us/results_report_stageA_US.md`, `output/stage_a/us/md/rank1_structural_report.md`

### Stage B — Weisskopf profitability decomposition (4-channel)

**Script:** `codes/stage_b/us/20_profitability_decomposition_us_v2.R`

- **Identity:** r = mu * B * pi, where B = (Py/PK) * B_real (exact)
- **4-channel decomposition:** d(ln r) = phi_mu + phi_PyPK + phi_Br + phi_pi
- **Measurement:**
  - r = GOS / KNC (nominal profit rate over net current-cost capital)
  - B = r / (mu * pi) (derived from identity, not computed independently)
  - B_real = B * (pK / Py) (real capital productivity, derived from identity)
  - PyPK = Py / pK (relative output-to-capital price)
  - pi = Psh_NF (profit share from income distribution, NOT GOS/GVA)
- **Turning points on r:** 1951(P), 1954(T), 1955(P), 1958(T), 1966(P), 1970(T), 1972(P), 1974(T)
- **Key finding:** 1972-74 contraction dominated by Py/PK channel (58%), not distribution or demand. B_real actually rose.
- **Tables:** `output/stage_b/US/csv/stageB_US_table_B1_annual_contributions_v2.csv` (1940-2024), B2 (swings), B3 (sub-period averages)
- **Figures:** 10 standalone files in `output/stage_b/US/figs/` (B1a-f levels, B2a cumulative, B2b annual bars, B3 swings, B4 turning points)

---

## 2. Stage C dataset

**File:** `data/processed/us_nf_corporate_stageC.csv`
**Codebook:** `data/processed/us_nf_corporate_stageC_codebook.csv`
**Coverage:** 1929-2024, 96 observations, 55 variables

### Variable groups

| Group | Variables | Notes |
|-------|-----------|-------|
| Profit rates | `r`, `r_net`, `cash_flow` | r=GOS/KNC, r_net=NOS/KNC, cash_flow=(GOS-CorpTax)/KNC |
| Weisskopf levels | `mu`, `B`, `B_real`, `PyPK`, `pi` | B_real is the technology channel for ARDL |
| Accumulation | `chi`, `g_K`, `g_Kn`, `g_Y`, `g_Yp` | chi=IGC/GOS, g_Yp=theta*g_K |
| Distribution | `omega`, `pi`, `e`, `theta` | theta=8.924-12.851*omega |
| Financial | `tax_rate`, `ret_rate`, `div_payout`, `int_share` | tax=CorpTax/PBT, int=NetInt/GOS |
| Depreciation | `cca_rate` | CCA/KGC |
| 4-channel contribs | `dlnr`, `phi_mu`, `phi_PyPK`, `phi_Br`, `phi_pi` | exact decomposition |
| Nominal levels | `GVA`, `GOS`, `EC`, `KNC`, `KNR`, `KGC`, `KGR`, `IGC` | millions $ |
| Real levels | `GVA_real`, `EC_real`, `GOS_real` | 2024 constant prices |
| Deflators | `Py`, `pK` | both index 2024=100 |
| Income accounts | `CCA_NF`, `NOS_NF`, `TPI_NF`, `NetInt_NF`, `CorpTax_NF`, `PBT_NF`, `PAT_NF`, `Dividends_NF`, `Retained_NF` | from BEA |
| Classification | `regime`, `tendency_label` | Pre-Fordist/Fordist/Post-Fordist |

### Identities that hold (validated)

```
r = mu * B * pi                    (machine precision)
B = PyPK * B_real                  (machine precision)
d(ln r) = phi_mu + phi_PyPK + phi_Br + phi_pi   (machine precision)
g_Yp = theta * g_K                 (exact)
omega + pi != 1  (gap = TPI/GVA — this is correct NIPA accounting)
```

### Missing (not in dataset)

- External interest rate (Fed funds, Baa yield) — needs FRED pull if used as regressor
- Tobin's q — would require stock market data
- Capacity utilization from Fed survey (for comparison with structural mu) — needs FRED pull

---

## 3. Notation locks (enforce in all code and output)

- `mu` = capacity utilization (never "u" or "CU")
- `chi` = recapitalization rate I/GOS (never "beta")
- `theta` = transformation elasticity (never "alpha" in variable names)
- `B_real` = real capital productivity (never "Br" in display, ok in R variable `phi_Br`)
- `PyPK` = relative price Py/PK (never "terms of trade" or "price channel" alone)
- `pi` = profit share (never the mathematical constant in this context)
- `omega` = wage share
- Regime labels: "Pre-Fordist", "Fordist", "Post-Fordist"
- MPF (not IPF); "Harrodian benchmark" (not "natural rate of growth")

---

## 4. Figure protocol (carry forward to Stage C figures)

- **No titles** within plots
- **No facet_wrap/facet_grid** — standalone files, LaTeX handles panel assembly
- **Okabe-Ito palette:** mu=#0072B2, PyPK=#CC79A7, B_real=#009E73, pi=#D55E00
- **Regime colors:** Pre-Fordist=#999999, Fordist=#0072B2, Post-Fordist=#D95F02
- **Font:** Roboto Condensed via showtext, base_size=13
- **Axis text:** x=24pt (90deg rotated), y=20pt, titles=22pt
- **In-chart labels:** ~9pt (3x the original 3pt)
- **Turning-point verticals:** dashed dark gray at identified years on all time-series plots
- **Regime bands:** shaded rectangles with italic text labels (on level panels)
- **No LOESS smoothers**
- **Export:** W=12, H=6, cairo_pdf + png at 150 dpi
- **End-of-line labels** instead of legend boxes (for line charts)
- **Legend inside plot** (for bar charts)

---

## 5. Data sources (external repos)

| Repo | Path | Content |
|------|------|---------|
| US-BEA-Income-FixedAssets-Dataset | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` | Income accounts, capital stocks, deflators |
| This repo raw data | `data/raw/us/US_corporate_NF_kstock_distribution.csv` | NF corporate sector assembled panel |

---

## 6. Suggested Stage C specification

### Dependent variable
`g_K` (real gross capital accumulation rate) or `chi` (recapitalization rate)

### Candidate regressors (from Weisskopf-Basu framework)
- `r` or `r_net` — profitability signal
- `mu` — demand/utilization channel
- `B_real` — technology channel (the theoretically appropriate variable; `B` nominal available for robustness)
- `pi` — distribution channel
- `PyPK` — relative price / realization channel
- `cash_flow` — internal finance
- `int_share` — financial burden
- `tax_rate` — fiscal regime

### Estimation window
- Primary: **1945-1978** (Fordist era)
- Extended: 1940-2024 (robustness)
- The dataset covers 1929-2024; g_K available from 1930

### Method
ARDL (Pesaran bounds test) — handles mixed I(0)/I(1) regressors. The structural mu is I(0) by construction (ECT from the VECM); r and pi may be I(1). ARDL is robust to this mixture.

### Hypothesis tests (from Chapter outline §2.7)
- H1: mu enters significantly (demand-led accumulation)
- H2: B_real enters significantly (technology channel operative)
- H3: pi enters with expected sign (distribution → accumulation feedback)
- H4: PyPK channel distinguishable from B_real (price vs technology)

---

## 7. Files inventory

```
codes/stage_a/us/
  35_theta_omega_plot_us.R          — theta-omega plane + mu + plots
  37_agnostic_absolute_us.R         — unrestricted Johansen
  39_restricted_vecm_absolute_us.R  — short-run restricted VECM
  39b_rank_under_restriction.R      — rank confirmation
  40_test_cv1_omega0_absolute_us.R  — omega=0 test (reference, overruled)
  41_test_beta_restrictions_all_cvs.R — robustness restrictions
  42_rank1_check.R                  — rank=1 robustness + mu

codes/stage_b/us/
  10_build_dataset_us.R             — Stage B/C base dataset
  20_profitability_decomposition_us_v2.R — 4-channel Weisskopf (current)

codes/stage_c/us/
  10_build_stageC_dataset_us.R      — Stage C dataset assembly

data/processed/
  us_nf_corporate_stageBC.csv       — base dataset (20 vars)
  us_nf_corporate_stageC.csv        — full Stage C dataset (55 vars)
  us_nf_corporate_stageC_codebook.csv

output/stage_a/us/
  csv/                              — theta-omega tibble, rank1 series, restriction tests
  figs/                             — theta-omega plots, mu plots
  results_report_stageA_US.md
  md/rank1_structural_report.md

output/stage_b/US/
  csv/                              — B1 annual, B2 swings, B3 sub-period averages
  figs/                             — 10 standalone figures (B1a-f, B2a-b, B3, B4)
```

---

*Generated: 2026-04-06 | Authority: Ch2_Outline_DEFINITIVE.md*
