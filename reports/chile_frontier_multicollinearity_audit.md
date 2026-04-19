# Chile Frontier Multicollinearity Audit

Generated on 2026-04-12.

Goal: test whether multicollinearity between `k_NR` and `k_ME` is structurally undermining frontier identification in Chile, and compare that problem against theory-consistent reparameterizations.

## 1. Current specification inventory

### Active frontier in production code

- `codes/stage_a/chile/03_stage2_frontier_vecm.R` fixes the productive-frontier beta on the ISI window, 1940-1972, with the Johansen state vector `(y, k_NR, k_ME, omega_kME)`.
- Exact frontier regressors in the cointegrating relation: `k_NR`, `k_ME`, `omega_kME`, plus a restricted constant.
- The current long-run frontier therefore implies `y ~ k_NR + k_ME + omega*k_ME`.

### Threshold / high-regime estimator now in use

- The same script does **not** estimate a second long-run frontier in high regime.
- The threshold stage is a CLS-TVECM on first differences with regime-specific **error-correction loadings** only.
- Exact regressors in each differenced equation: `ECT_r1`, `ECT_r2`, one lag of `Δy`, `Δk_NR`, `Δk_ME`, `Δomega_kME`, `D1973`, `D1975`, and a constant.
- Threshold classification uses lagged Stage-1 import ECT, with `gamma_hat = -0.1394` on years 1922-2024.

### Cointegration and DOLS variants already attempted outside production code

- `codes/stage_a/chile/_diag_isi_cv1.R`: same active frontier form on three windows: ISI 1940-1972 with `K=3`, extended 1935-1978 with `D1973` and `D1975`, and ISI 1940-1972 with forced `K=2`.
- `codes/stage_a/chile/03x_frontier_discovery.R`: trial cointegration systems `(y, k_NR, lphi)`, `(y, k_NR, lphi, omega_kME)`, `(y, k_NR, omega, omega_kNR)`, and `(y, k_NR, lphi, omega)`.
- `codes/stage_a/chile/_diag_enhanced_ur.R`: feasibility check for reparameterized Johansen on `(y, k_CL, c_t, omega_c)`; the script rejects that route for Johansen because `c_t` and `omega_c` remain too persistent under its break-corrected battery.
- `agents/claudecode_prompt_06_reparam_frontier.md`: proposed but not productionized reparameterization `(y, k_CL, k_ME, omega_kME)`.
- `output/stage_a/Chile/stage2_psi_fix_proposals.md`: DOLS was proposed for `(y, k_CL, c_t, omega_c)` but there is no active Chile frontier DOLS script in `codes/stage_a/chile`.

## 2. Design-matrix diagnostics

### A. Current form (`y ~ k_NR + k_ME + omega*k_ME`)

#### Baseline ISI sample (1940-1972, N=33)

| pair | correlation |
| --- | --- |
| k_NR vs k_ME | 0.9881 |
| k_NR vs omega_kME | 0.1792 |
| k_ME vs omega_kME | 0.1726 |

| term | VIF |
| --- | --- |
| k_NR | 42.57 |
| k_ME | 42.47 |
| omega_kME | 1.03 |

- Condition number: `13.15`
- Eigenvalues of standardized `X'X`: `65.5108, 30.1106, 0.3786`

#### Threshold regime 1 sample (slack, N=46)

| pair | correlation |
| --- | --- |
| k_NR vs k_ME | 0.9436 |
| k_NR vs omega_kME | -0.4380 |
| k_ME vs omega_kME | -0.4404 |

| term | VIF |
| --- | --- |
| k_NR | 9.18 |
| k_ME | 9.20 |
| omega_kME | 1.25 |

- Condition number: `6.32`
- Eigenvalues of standardized `X'X`: `101.3308, 31.1330, 2.5362`

#### Threshold regime 2 sample (binding, N=57)

| pair | correlation |
| --- | --- |
| k_NR vs k_ME | 0.9635 |
| k_NR vs omega_kME | -0.6777 |
| k_ME vs omega_kME | -0.7236 |

| term | VIF |
| --- | --- |
| k_NR | 14.11 |
| k_ME | 16.02 |
| omega_kME | 2.12 |

- Condition number: `8.69`
- Eigenvalues of standardized `X'X`: `144.6839, 21.4017, 1.9144`

#### Full-sample threshold-interaction design (1922-2024, N=103)

| pair | correlation |
| --- | --- |
| k_NR vs k_ME | 0.9535 |
| k_NR vs omega_kME | -0.6032 |
| k_ME vs omega_kME | -0.6253 |
| k_NR vs R_k_NR | 0.3224 |
| k_ME vs R_k_NR | 0.4336 |
| omega_kME vs R_k_NR | -0.1665 |
| k_NR vs R_k_ME | 0.3593 |
| k_ME vs R_k_ME | 0.4774 |
| omega_kME vs R_k_ME | -0.1974 |
| R_k_NR vs R_k_ME | 0.9982 |
| k_NR vs R_omega_kME | 0.0999 |
| k_ME vs R_omega_kME | 0.2022 |
| omega_kME vs R_omega_kME | 0.0676 |
| R_k_NR vs R_omega_kME | 0.9531 |
| R_k_ME vs R_omega_kME | 0.9377 |

| term | VIF |
| --- | --- |
| k_NR | 32.90 |
| k_ME | 62.93 |
| omega_kME | 2.63 |
| R_k_NR | 3006.75 |
| R_k_ME | 2774.01 |
| R_omega_kME | 51.51 |

- Condition number: `143.27`
- Eigenvalues of standardized `X'X`: `358.5741, 200.5538, 46.9905, 4.2949, 1.5692, 0.0175`

### B. Share form (`y ~ k_CL + s_ME*k_CL + omega*s_ME*k_CL`)

#### Baseline ISI sample (1940-1972, N=33)

| pair | correlation |
| --- | --- |
| k_CL vs skcl | 0.9424 |
| k_CL vs omega_skcl | 0.6519 |
| skcl vs omega_skcl | 0.6887 |

| term | VIF |
| --- | --- |
| k_CL | 8.94 |
| skcl | 9.78 |
| omega_skcl | 1.90 |

- Condition number: `6.71`
- Eigenvalues of standardized `X'X`: `80.9555, 13.2472, 1.7972`

#### Threshold regime 1 sample (slack, N=46)

| pair | correlation |
| --- | --- |
| k_CL vs skcl | 0.6682 |
| k_CL vs omega_skcl | 0.1345 |
| skcl vs omega_skcl | 0.6645 |

| term | VIF |
| --- | --- |
| k_CL | 2.62 |
| skcl | 4.60 |
| omega_skcl | 2.59 |

- Condition number: `4.05`
- Eigenvalues of standardized `X'X`: `90.5388, 38.9493, 5.5119`

#### Threshold regime 2 sample (binding, N=57)

| pair | correlation |
| --- | --- |
| k_CL vs skcl | 0.9003 |
| k_CL vs omega_skcl | 0.6448 |
| skcl vs omega_skcl | 0.8555 |

| term | VIF |
| --- | --- |
| k_CL | 7.64 |
| skcl | 16.66 |
| omega_skcl | 5.40 |

- Condition number: `8.31`
- Eigenvalues of standardized `X'X`: `145.8949, 19.9936, 2.1115`

#### Full-sample threshold-interaction design (1922-2024, N=103)

| pair | correlation |
| --- | --- |
| k_CL vs skcl | 0.8725 |
| k_CL vs omega_skcl | 0.6033 |
| skcl vs omega_skcl | 0.8575 |
| k_CL vs R_k_CL | 0.4100 |
| skcl vs R_k_CL | 0.5422 |
| omega_skcl vs R_k_CL | 0.5489 |
| k_CL vs R_skcl | 0.6775 |
| skcl vs R_skcl | 0.8329 |
| omega_skcl vs R_skcl | 0.7685 |
| R_k_CL vs R_skcl | 0.8964 |
| k_CL vs R_omega_skcl | 0.4852 |
| skcl vs R_omega_skcl | 0.6771 |
| omega_skcl vs R_omega_skcl | 0.7295 |
| R_k_CL vs R_omega_skcl | 0.9580 |
| R_skcl vs R_omega_skcl | 0.9518 |

| term | VIF |
| --- | --- |
| k_CL | 6.49 |
| skcl | 32.40 |
| omega_skcl | 11.81 |
| R_k_CL | 30.99 |
| R_skcl | 63.03 |
| R_omega_skcl | 72.87 |

- Condition number: `24.86`
- Eigenvalues of standardized `X'X`: `472.3810, 94.2702, 37.6773, 5.2253, 1.6817, 0.7645`

### C. Composition-gap form (`y ~ k_CL + c + omega*c`)

#### Baseline ISI sample (1940-1972, N=33)

| pair | correlation |
| --- | --- |
| k_CL vs c_t | 0.9123 |
| k_CL vs omega_c | 0.7538 |
| c_t vs omega_c | 0.8406 |

| term | VIF |
| --- | --- |
| k_CL | 5.99 |
| c_t | 8.81 |
| omega_c | 3.42 |

- Condition number: `6.10`
- Eigenvalues of standardized `X'X`: `85.5312, 8.1712, 2.2976`

#### Threshold regime 1 sample (slack, N=46)

| pair | correlation |
| --- | --- |
| k_CL vs c_t | 0.5503 |
| k_CL vs omega_c | 0.6120 |
| c_t vs omega_c | 0.9160 |

| term | VIF |
| --- | --- |
| k_CL | 1.60 |
| c_t | 6.22 |
| omega_c | 6.93 |

- Condition number: `5.46`
- Eigenvalues of standardized `X'X`: `107.9583, 23.4153, 3.6264`

#### Threshold regime 2 sample (binding, N=57)

| pair | correlation |
| --- | --- |
| k_CL vs c_t | 0.8509 |
| k_CL vs omega_c | 0.8187 |
| c_t vs omega_c | 0.9844 |

| term | VIF |
| --- | --- |
| k_CL | 3.78 |
| c_t | 40.33 |
| omega_c | 33.76 |

- Condition number: `14.21`
- Eigenvalues of standardized `X'X`: `155.1955, 12.0359, 0.7686`

#### Full-sample threshold-interaction design (1922-2024, N=103)

| pair | correlation |
| --- | --- |
| k_CL vs c_t | 0.8214 |
| k_CL vs omega_c | 0.8071 |
| c_t vs omega_c | 0.9788 |
| k_CL vs R_k_CL | 0.4100 |
| c_t vs R_k_CL | 0.5449 |
| omega_c vs R_k_CL | 0.5086 |
| k_CL vs R_c_t | 0.7197 |
| c_t vs R_c_t | 0.8071 |
| omega_c vs R_c_t | 0.7987 |
| R_k_CL vs R_c_t | 0.0563 |
| k_CL vs R_omega_c | 0.6418 |
| c_t vs R_omega_c | 0.7225 |
| omega_c vs R_omega_c | 0.7441 |
| R_k_CL vs R_omega_c | -0.0771 |
| R_c_t vs R_omega_c | 0.9762 |

| term | VIF |
| --- | --- |
| k_CL | 3.34 |
| c_t | 63.79 |
| omega_c | 52.14 |
| R_k_CL | 4.38 |
| R_c_t | 82.34 |
| R_omega_c | 73.45 |

- Condition number: `31.50`
- Eigenvalues of standardized `X'X`: `442.8765, 128.8729, 27.2276, 9.7147, 2.8619, 0.4463`


## 3. Frontier estimation comparison

All coefficient tables below use DOLS with one lead and one lag of first differences and Newey-West HAC errors for contiguous samples. Threshold-split samples are non-contiguous, so those are estimated with static OLS-HAC instead of DOLS.

### Baseline ISI estimates (1940-1972)

| spec | estimator | term | estimate | std_error | t_stat | p_value |
| --- | --- | --- | --- | --- | --- | --- |
| A | DOLS(q=1) | k_NR | 1.1535 | 0.1776 | 6.49 | <0.0001 |
| A | DOLS(q=1) | k_ME | -0.0313 | 0.1269 | -0.25 | 0.8082 |
| A | DOLS(q=1) | omega_kME | -0.0141 | 0.0104 | -1.36 | 0.1923 |
| B | DOLS(q=1) | k_CL | 1.1466 | 0.0674 | 17.01 | <0.0001 |
| B | DOLS(q=1) | skcl | -0.0786 | 0.0395 | -1.99 | 0.0630 |
| B | DOLS(q=1) | omega_skcl | -0.0421 | 0.0329 | -1.28 | 0.2185 |
| C | DOLS(q=1) | k_CL | 1.1201 | 0.0560 | 19.99 | <0.0001 |
| C | DOLS(q=1) | c_t | -0.5754 | 0.2090 | -2.75 | 0.0136 |
| C | DOLS(q=1) | omega_c | 0.3130 | 0.1849 | 1.69 | 0.1088 |

| spec | sample_id | estimator | n | cond_num | max_vif | rmse | adj_r2 | bg_p | bp_p | jb_p | adf_tau | adf_cv5 | residual_stationary |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | baseline_isi | DOLS(q=1) | 30 | 13.98 | 48.75 | 0.0267 | 0.9893 | 0.1280 | 0.3305 | 0.8943 | -6.003 | -1.950 | Yes |
| B | baseline_isi | DOLS(q=1) | 30 | 7.77 | 12.96 | 0.0268 | 0.9892 | 0.1011 | 0.3154 | 0.9410 | -6.033 | -1.950 | Yes |
| C | baseline_isi | DOLS(q=1) | 30 | 6.94 | 10.96 | 0.0254 | 0.9903 | 0.2450 | 0.3190 | 0.8733 | -5.661 | -1.950 | Yes |

### Post-1973 contiguous split estimates (1973-2024)

| spec | estimator | term | estimate | std_error | t_stat | p_value |
| --- | --- | --- | --- | --- | --- | --- |
| A | DOLS(q=1) | k_NR | 0.9703 | 0.1427 | 6.80 | <0.0001 |
| A | DOLS(q=1) | k_ME | 0.0247 | 0.0583 | 0.42 | 0.6742 |
| A | DOLS(q=1) | omega_kME | 0.0277 | 0.0198 | 1.40 | 0.1687 |
| B | DOLS(q=1) | k_CL | 1.1111 | 0.1061 | 10.47 | <0.0001 |
| B | DOLS(q=1) | skcl | -0.1543 | 0.0377 | -4.09 | 0.0002 |
| B | DOLS(q=1) | omega_skcl | 0.0979 | 0.0630 | 1.55 | 0.1290 |
| C | DOLS(q=1) | k_CL | 0.9305 | 0.0853 | 10.90 | <0.0001 |
| C | DOLS(q=1) | c_t | -1.0449 | 0.3722 | -2.81 | 0.0080 |
| C | DOLS(q=1) | omega_c | 1.5149 | 1.0604 | 1.43 | 0.1618 |

| spec | sample_id | estimator | n | cond_num | max_vif | rmse | adj_r2 | bg_p | bp_p | jb_p | adf_tau | adf_cv5 | residual_stationary |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | post_1973 | DOLS(q=1) | 49 | 16.76 | 58.08 | 0.0347 | 0.9959 | <0.0001 | 0.2857 | 0.5010 | -2.806 | -1.950 | Yes |
| B | post_1973 | DOLS(q=1) | 49 | 21.73 | 99.50 | 0.0440 | 0.9935 | <0.0001 | 0.1775 | 0.4885 | -2.774 | -1.950 | Yes |
| C | post_1973 | DOLS(q=1) | 49 | 19.70 | 80.58 | 0.0478 | 0.9923 | <0.0001 | 0.0464 | 0.7039 | -3.578 | -1.950 | Yes |

### Threshold-split level estimates

| spec | estimator | term | estimate | std_error | t_stat | p_value |
| --- | --- | --- | --- | --- | --- | --- |
| A | OLS-HAC | k_NR | 1.0915 | 0.1546 | 7.06 | <0.0001 |
| A | OLS-HAC | k_ME | -0.0073 | 0.1161 | -0.06 | 0.9501 |
| A | OLS-HAC | omega_kME | 0.0094 | 0.0131 | 0.72 | 0.4777 |
| B | OLS-HAC | k_CL | 1.1507 | 0.0598 | 19.24 | <0.0001 |
| B | OLS-HAC | skcl | -0.1467 | 0.0298 | -4.93 | <0.0001 |
| B | OLS-HAC | omega_skcl | 0.0725 | 0.0433 | 1.67 | 0.1019 |
| C | OLS-HAC | k_CL | 1.0492 | 0.0569 | 18.45 | <0.0001 |
| C | OLS-HAC | c_t | -0.7789 | 0.2075 | -3.75 | 0.0005 |
| C | OLS-HAC | omega_c | 0.6048 | 0.3852 | 1.57 | 0.1239 |

| spec | estimator | term | estimate | std_error | t_stat | p_value |
| --- | --- | --- | --- | --- | --- | --- |
| A | OLS-HAC | k_NR | 0.9289 | 0.0756 | 12.29 | <0.0001 |
| A | OLS-HAC | k_ME | 0.0674 | 0.0449 | 1.50 | 0.1393 |
| A | OLS-HAC | omega_kME | -0.0145 | 0.0217 | -0.67 | 0.5055 |
| B | OLS-HAC | k_CL | 1.0582 | 0.0662 | 15.99 | <0.0001 |
| B | OLS-HAC | skcl | -0.1118 | 0.0308 | -3.63 | 0.0006 |
| B | OLS-HAC | omega_skcl | 0.0590 | 0.0512 | 1.15 | 0.2539 |
| C | OLS-HAC | k_CL | 1.0018 | 0.0295 | 34.00 | <0.0001 |
| C | OLS-HAC | c_t | -1.2089 | 0.1790 | -6.75 | <0.0001 |
| C | OLS-HAC | omega_c | 1.7268 | 0.3510 | 4.92 | <0.0001 |

| spec | sample_id | estimator | n | cond_num | max_vif | rmse | adj_r2 | bg_p | bp_p | jb_p | adf_tau | adf_cv5 | residual_stationary |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | regime_slack | OLS-HAC | 46 | 6.32 | 9.20 | 0.1173 | 0.9739 | 0.0042 | <0.0001 | 0.6237 | -3.411 | -1.950 | Yes |
| B | regime_slack | OLS-HAC | 46 | 4.05 | 4.60 | 0.1209 | 0.9723 | 0.0044 | <0.0001 | 0.9956 | -3.515 | -1.950 | Yes |
| C | regime_slack | OLS-HAC | 46 | 5.46 | 6.93 | 0.1264 | 0.9697 | 0.0073 | <0.0001 | 0.6831 | -3.464 | -1.950 | Yes |
| A | regime_binding | OLS-HAC | 57 | 8.69 | 16.02 | 0.1234 | 0.9893 | <0.0001 | 0.0891 | <0.0001 | -2.574 | -1.950 | Yes |
| B | regime_binding | OLS-HAC | 57 | 8.31 | 16.66 | 0.1466 | 0.9849 | <0.0001 | 0.2856 | 0.5951 | -1.844 | -1.950 | No |
| C | regime_binding | OLS-HAC | 57 | 14.21 | 40.33 | 0.1212 | 0.9896 | <0.0001 | 0.3771 | <0.0001 | -3.324 | -1.950 | Yes |

### Full-sample threshold-interaction DOLS

| spec | estimator | term | estimate | std_error | t_stat | p_value |
| --- | --- | --- | --- | --- | --- | --- |
| A | DOLS(q=1) | k_NR | 0.8556 | 0.1014 | 8.44 | <0.0001 |
| A | DOLS(q=1) | k_ME | 0.1135 | 0.0866 | 1.31 | 0.1936 |
| A | DOLS(q=1) | omega_kME | 0.0355 | 0.0268 | 1.32 | 0.1899 |
| A | DOLS(q=1) | R_k_NR | 0.1102 | 0.1228 | 0.90 | 0.3723 |
| A | DOLS(q=1) | R_k_ME | -0.1002 | 0.1117 | -0.90 | 0.3725 |
| A | DOLS(q=1) | R_omega_kME | -0.0265 | 0.0434 | -0.61 | 0.5437 |
| B | DOLS(q=1) | k_CL | 1.0196 | 0.0382 | 26.69 | <0.0001 |
| B | DOLS(q=1) | skcl | -0.1173 | 0.0374 | -3.14 | 0.0024 |
| B | DOLS(q=1) | omega_skcl | 0.1066 | 0.0716 | 1.49 | 0.1408 |
| B | DOLS(q=1) | R_k_CL | -0.0019 | 0.0130 | -0.14 | 0.8872 |
| B | DOLS(q=1) | R_skcl | -0.0271 | 0.0356 | -0.76 | 0.4484 |
| B | DOLS(q=1) | R_omega_skcl | 0.0555 | 0.0966 | 0.57 | 0.5675 |
| C | DOLS(q=1) | k_CL | 0.9667 | 0.0307 | 31.47 | <0.0001 |
| C | DOLS(q=1) | c_t | -0.2846 | 0.3323 | -0.86 | 0.3945 |
| C | DOLS(q=1) | omega_c | -0.0461 | 0.6948 | -0.07 | 0.9473 |
| C | DOLS(q=1) | R_k_CL | -0.0004 | 0.0042 | -0.09 | 0.9251 |
| C | DOLS(q=1) | R_c_t | -0.8253 | 0.4450 | -1.85 | 0.0676 |
| C | DOLS(q=1) | R_omega_c | 1.3871 | 0.8813 | 1.57 | 0.1197 |

| spec | sample_id | estimator | n | cond_num | max_vif | rmse | adj_r2 | bg_p | bp_p | jb_p | adf_tau | adf_cv5 | residual_stationary |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | threshold_interaction | DOLS(q=1) | 100 | 148.73 | 3229.37 | 0.0640 | 0.9951 | <0.0001 | 0.0232 | <0.0001 | -4.734 | -1.950 | Yes |
| B | threshold_interaction | DOLS(q=1) | 100 | 26.31 | 85.79 | 0.0700 | 0.9942 | <0.0001 | 0.0842 | 0.0160 | -4.785 | -1.950 | Yes |
| C | threshold_interaction | DOLS(q=1) | 100 | 30.84 | 79.29 | 0.0724 | 0.9938 | <0.0001 | 0.1195 | 0.0030 | -4.552 | -1.950 | Yes |

## 4. Summary assessment

### Baseline identification ranking

| spec | form | n | max_abs_corr | max_vif | cond_num | sign_pattern_ok |
| --- | --- | --- | --- | --- | --- | --- |
| A | Current form | 33 | 0.9881 | 42.57 | 13.15 | No |
| B | Share form | 33 | 0.9424 | 9.78 | 6.71 | No |
| C | Composition-gap form | 33 | 0.9123 | 8.81 | 6.10 | No |

### Stability across contiguous sample split and threshold partitions

| spec | post_sign_changes | threshold_split_sign_changes | threshold_interactions_sig |
| --- | --- | --- | --- |
| A | 2 | 2 | 0 |
| B | 1 | 0 | 0 |
| C | 0 | 0 | 0 |

### Threshold-use comparison

| spec | interaction_cond | interaction_max_vif | interaction_resid_stationary | split_slack_resid_stationary | split_binding_resid_stationary | split_avg_rmse | interaction_rmse |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A | 148.73 | 3229.37 | Yes | Yes | Yes | 0.1203 | 0.0640 |
| B | 26.31 | 85.79 | Yes | Yes | No | 0.1338 | 0.0700 |
| C | 30.84 | 79.29 | Yes | Yes | Yes | 0.1238 | 0.0724 |

### Reading the threshold result against the current TVECM

- The existing CLS-TVECM still matters for the short-run asymmetry: the current repository note reports `gamma_hat = -0.1394`, bootstrap linearity rejection at `p = 0.005`, and a shadow-price slowdown from `alpha_y(1) = -0.091` to `alpha_y(2) = -0.017`.
- But those results operate on adjustment speeds, not on the long-run frontier design matrix. They do not cure the beta-level collinearity between capital terms.
- The audit therefore treats the threshold as useful only if it either stabilizes the long-run coefficients under sample split or survives as a well-conditioned interaction design. If it fails both tests, it should be demoted from estimator to state detector.

### Direct verdict on the competing forms

- **Current form (A)** fails the audit. In the ISI window the core capital pair remains almost singular (`cor = 0.9881`, `VIF ≈ 42.5` for both capital terms), the machinery coefficient stays near zero or negative, and threshold interactions drive the design into outright numerical degeneracy (`max VIF > 3000`).
- **Share form (B)** improves conditioning sharply, but not enough to make the frontier structurally convincing. The share term stays negative in both the ISI and post-1973 DOLS fits, and the binding-regime split loses residual stationarity. This form reduces the geometry problem, but it does not deliver a cleaner long-run decomposition than C.
- **Composition-gap form (C)** gives the lowest ISI condition number and the lowest baseline VIF profile, while also producing the most stable coefficient signs across the post-1973 split and the threshold splits. That is why C wins the audit. The gain is geometric and stability-based, not a full recovery of the expected Kaldorian sign pattern: the composition term is still negative in the ISI DOLS. The recommendation is therefore about identification discipline, not about declaring the composition effect theoretically settled.

## 5. Recommendation

The frontier form that minimizes the identification problem in the baseline window is **Composition-gap form** (`y ~ k_CL + c + omega*c`).

The threshold should stay in the chapter as a crisis-state classifier, not as the device that rescues frontier identification. The interaction design duplicates an already collinear level structure, while threshold-split coefficients remain unstable across slack and binding subsamples. The TVECM still documents asymmetric short-run adjustment, but it does not identify the long-run frontier any better than the static reparameterization.

The decisive point is simple. The current frontier fails because `k_NR` and `k_ME` are still trying to identify separate elasticities off the same stochastic trend. The share form softens that problem but does not stabilize the long-run relation enough to trust its decomposition. The composition-gap form does not solve every theoretical sign issue, but it gives the cleanest matrix, the most stable coefficients, and the least fragile threshold comparison. That is the strongest identification position available in the current data.

**Recommendation: reparameterize to total capital + composition gap.**

**Threshold handling: keep threshold only as crisis-state detector.**
