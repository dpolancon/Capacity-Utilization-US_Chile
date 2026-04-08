# Stage 1 VECM — Output Manifest
**Generated:** 2026-04-07 | **Script:** `codes/stage_a/chile/02b_stage1_deliver.R`

---

## CSV files (`output/stage_a/Chile/csv/`)

| File | Rows | Description |
|------|------|-------------|
| `stage1_ECT_m.csv` | 105 | Error correction term by year and regime. Columns: year, ECT_m, regime. This is the primary deliverable for Stage 2 TVECM. |
| `stage1_cointegrating_vectors.csv` | 8 | Long-run coefficients (zeta_0..zeta_3) with standardized impacts for each regime. |
| `stage1_alpha_loadings.csv` | 8 | Loading matrix (alpha) for each regime. Rows: m, k_ME, nrs, omega. |
| `stage1_weak_exogeneity.csv` | 8 | LR test statistics and p-values for H0: alpha_j = 0 (weak exogeneity of variable j). |
| `stage1_diagnostics.csv` | 8 | Post-estimation test results: Portmanteau, ARCH-LM, Jarque-Bera, ADF on ECT. |
| `stage1_lag_selection.csv` | 8 | AIC/HQ/SC/FPE criteria and selected lag K for each regime. |
| `stage1_johansen_trace.csv` | 8 | Johansen trace test: H0, test statistic, critical values (10%/5%/1%), decision. |
| `stage1_johansen_maxeigen.csv` | 8 | Johansen max-eigenvalue test: same structure as trace. |
| `stage1_short_run_coefficients.csv` | 44 | Full Gamma matrix: all equations, all terms, with SEs and t-stats. |
| `stage1_eigenvalues.csv` | 10 | Eigenvalues from the Johansen procedure for each regime. |
| `stage1_variable_summary.csv` | 8 | Mean, sd, min, max for each variable in each sub-sample. |
| `stage1_correlation_matrices.csv` | 8 | Pairwise correlations among state vector variables. |
| `stage1_standardized_impacts.csv` | 3 | Side-by-side comparison: raw coefficients, sd, and coefficient x sd for each channel. |

## Report

| File | Description |
|------|-------------|
| `stage1_vecm_report.md` | Full empirical strategy report with parameter discussion, diagnostics, limitations. |

## Pipeline copy

| File | Description |
|------|-------------|
| `data/processed/chile/ECT_m_stage1.csv` | Identical copy of `stage1_ECT_m.csv` for downstream Stage 2 pipeline. |

## How to load in R

```r
library(readr)
ect   <- read_csv('output/stage_a/Chile/csv/stage1_ECT_m.csv')
betas <- read_csv('output/stage_a/Chile/csv/stage1_cointegrating_vectors.csv')
diag  <- read_csv('output/stage_a/Chile/csv/stage1_diagnostics.csv')
sr    <- read_csv('output/stage_a/Chile/csv/stage1_short_run_coefficients.csv')
```

## How to load in Python

```python
import pandas as pd
ect   = pd.read_csv('output/stage_a/Chile/csv/stage1_ECT_m.csv')
betas = pd.read_csv('output/stage_a/Chile/csv/stage1_cointegrating_vectors.csv')
```

## Key objects for Stage 2

- **ECT_m** (`stage1_ECT_m.csv`): The regime-specific cointegrating residual.
  Filter by `regime` column to get the appropriate ECT for each period.
  This serves as the threshold transition variable for the Stage 2 TVECM.
- **Cointegrating vectors** (`stage1_cointegrating_vectors.csv`): Needed to
  reconstruct ECT_m from new data or for out-of-sample evaluation.
- **Alpha loadings** (`stage1_alpha_loadings.csv`): Speed of adjustment —
  needed if Stage 2 conditions on the error-correction speed.

---
*Generated: 2026-04-07*
