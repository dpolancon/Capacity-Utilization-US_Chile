# Stage C Report — ARDL Extended Sample Estimations
## US Non-Financial Corporate Sector
**Date:** 2026-04-07 | **Script:** 23_ardl_extended_netK_us.R

---

## 1. Overview

| Estimation | Spec | Sample | Eff N | Order | AIC | R2 | Adj R2 | F(Case3) | F p | t(Case3) | t p | ECT | Half-life | LR mu | mu p |
|------------|------|--------|-------|-------|-----|-----|--------|----------|-----|----------|-----|-----|-----------|-------|------|
| 3ch_1930 | 3ch | 1930-1973 | 42 | 2,2,0,2 | -293.9 | 0.912 | 0.887 | 6.161 | 0.0044 | -3.963 | 0.0323 | -0.511 | 1.0 | -0.134 | 0.0087 |
| 4ch_1930 | 4ch | 1930-1973 | 42 | 2,0,3,2,1 | -302.8 | 0.938 | 0.913 | 4.987 | 0.0110 | -4.301 | 0.0227 | -0.502 | 1.0 | -0.016 | 0.7155 |
| 3ch_1940 | 3ch | 1940-1973 | 35 | 2,2,2,2 | -251.2 | 0.904 | 0.858 | 8.657 | 0.0006 | -4.898 | 0.0017 | -0.598 | 0.8 | -0.142 | 0.0020 |
| 4ch_1940 | 4ch | 1940-1973 | 36 | 1,0,0,1,0 | -248.4 | 0.841 | 0.808 | 2.589 | 0.3078 | -2.639 | 0.4396 | -0.334 | 1.7 | 0.017 | 0.8338 |
| 3ch_1947 | 3ch | 1947-1974 | 30 | 1,1,1,0 | -229.0 | 0.802 | 0.750 | 13.408 | 0.0000 | -4.779 | 0.0024 | -0.461 | 1.1 | 0.138 | 0.1356 |
| 4ch_1947 | 4ch | 1947-1974 | 29 | 2,2,2,2,2 | -246.1 | 0.945 | 0.890 | 6.147 | 0.0017 | -5.410 | 0.0009 | -0.595 | 0.8 | 0.229 | 0.1398 |

---

## 3ch_19301973_N44

**Sample:** 1930-1973 | **Effective N:** 42 | **Model:** ARDL(2,2,0,2)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 5.143 | 0.0042 | NA | NA |
| 3 | 6.161 | 0.0044 | -3.963 | 0.0323 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | 0.0863 | 0.1010 | 0.855 | 0.3990 |
| r | 0.5501 | 0.0729 | 7.544 | 0.0000 |
| mu | -0.1338 | 0.0479 | -2.794 | 0.0087 |
| pi | -0.1568 | 0.2623 | -0.598 | 0.5542 |

### ECM (Case 3)

- **ECT:** -0.5107 (OLS t=-5.192)
- **Bounds t (Case 3):** -3.963 (p=0.0323) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 0.97 years | **95% adjustment:** 4.2 years

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 1.477 | 0.2243 | PASS |
| BG(2) | 13.472 | 0.0012 | WARNING |
| Breusch-Pagan | 9.234 | 0.4159 | PASS |
| Jarque-Bera | 16.575 | 0.0003 | WARNING |
| RESET | 0.652 | 0.4257 | PASS |

---

## 4ch_19301973_N44

**Sample:** 1930-1973 | **Effective N:** 42 | **Model:** ARDL(2,0,3,2,1)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 4.243 | 0.0125 | NA | NA |
| 3 | 4.987 | 0.0110 | -4.301 | 0.0227 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | -0.1823 | 0.1512 | -1.206 | 0.2375 |
| mu | -0.0160 | 0.0435 | -0.368 | 0.7155 |
| B_real | 0.2024 | 0.1065 | 1.901 | 0.0673 |
| PyPK | 0.0772 | 0.0950 | 0.813 | 0.4228 |
| pi | 0.0444 | 0.4339 | 0.102 | 0.9191 |

### ECM (Case 3)

- **ECT:** -0.5017 (OLS t=-5.327)
- **Bounds t (Case 3):** -4.301 (p=0.0227) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 1.00 years | **95% adjustment:** 4.3 years

### Wald Test: H0: beta_mu = beta_PyPK + beta_Br

- Difference: -0.1484 | SE: 0.1263 | t: -1.1743 | p: 0.2498
- Decision: **FAIL TO REJECT H0**

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 0.114 | 0.7360 | PASS |
| BG(2) | 8.176 | 0.0168 | WARNING |
| Breusch-Pagan | 8.230 | 0.7669 | PASS |
| Jarque-Bera | 25.830 | 0.0000 | WARNING |
| RESET | 0.771 | 0.3874 | PASS |

---

## 3ch_19401973_N34

**Sample:** 1940-1973 | **Effective N:** 35 | **Model:** ARDL(2,2,2,2)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 7.148 | 0.0006 | NA | NA |
| 3 | 8.657 | 0.0006 | -4.898 | 0.0017 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | 0.0077 | 0.1260 | 0.061 | 0.9518 |
| r | 0.6094 | 0.1187 | 5.135 | 0.0000 |
| mu | -0.1422 | 0.0408 | -3.490 | 0.0020 |
| pi | 0.0497 | 0.3373 | 0.147 | 0.8842 |

### ECM (Case 3)

- **ECT:** -0.5979 (OLS t=-6.256)
- **Bounds t (Case 3):** -4.898 (p=0.0017) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 0.76 years | **95% adjustment:** 3.3 years

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 3.329 | 0.0681 | PASS |
| BG(2) | 6.846 | 0.0326 | WARNING |
| Breusch-Pagan | 13.570 | 0.2577 | PASS |
| Jarque-Bera | 1.419 | 0.4919 | PASS |
| RESET | 0.268 | 0.6096 | PASS |

---

## 4ch_19401973_N34

**Sample:** 1940-1973 | **Effective N:** 36 | **Model:** ARDL(1,0,0,1,0)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 2.174 | 0.3655 | NA | NA |
| 3 | 2.589 | 0.3078 | -2.639 | 0.4396 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | -0.0870 | 0.2268 | -0.384 | 0.7039 |
| mu | 0.0174 | 0.0821 | 0.212 | 0.8338 |
| B_real | 0.2345 | 0.1642 | 1.428 | 0.1640 |
| PyPK | 0.0594 | 0.1576 | 0.377 | 0.7092 |
| pi | -0.2811 | 0.2813 | -0.999 | 0.3259 |

### ECM (Case 3)

- **ECT:** -0.3345 (OLS t=-3.838)
- **Bounds t (Case 3):** -2.639 (p=0.4396) — inconclusive
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 1.70 years | **95% adjustment:** 7.4 years

### Wald Test: H0: beta_mu = beta_PyPK + beta_Br

- Difference: -0.0925 | SE: 0.1277 | t: -0.7243 | p: 0.4747
- Decision: **FAIL TO REJECT H0**

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 2.112 | 0.1462 | PASS |
| BG(2) | 5.262 | 0.0720 | PASS |
| Breusch-Pagan | 7.084 | 0.3132 | PASS |
| Jarque-Bera | 0.736 | 0.6922 | PASS |
| RESET | 1.028 | 0.3192 | PASS |

---

## 3ch_19471974_N28

**Sample:** 1947-1974 | **Effective N:** 30 | **Model:** ARDL(1,1,1,0)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 11.290 | 0.0000 | NA | NA |
| 3 | 13.408 | 0.0000 | -4.779 | 0.0024 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | 0.0311 | 0.1269 | 0.245 | 0.8087 |
| r | 0.4199 | 0.2264 | 1.855 | 0.0764 |
| mu | 0.1384 | 0.0895 | 1.547 | 0.1356 |
| pi | -0.4691 | 0.3620 | -1.296 | 0.2079 |

### ECM (Case 3)

- **ECT:** -0.4610 (OLS t=-7.786)
- **Bounds t (Case 3):** -4.779 (p=0.0024) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 1.12 years | **95% adjustment:** 4.8 years

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 2.595 | 0.1072 | PASS |
| BG(2) | 7.851 | 0.0197 | WARNING |
| Breusch-Pagan | 3.204 | 0.7828 | PASS |
| Jarque-Bera | 3.239 | 0.1980 | PASS |
| RESET | 0.018 | 0.8951 | PASS |

---

## 4ch_19471974_N28

**Sample:** 1947-1974 | **Effective N:** 29 | **Model:** ARDL(2,2,2,2,2)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 5.138 | 0.0020 | NA | NA |
| 3 | 6.147 | 0.0017 | -5.410 | 0.0009 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | -0.2572 | 0.0962 | -2.674 | 0.0181 |
| mu | 0.2294 | 0.1465 | 1.566 | 0.1398 |
| B_real | 0.1930 | 0.0744 | 2.594 | 0.0212 |
| PyPK | 0.0191 | 0.1369 | 0.140 | 0.8910 |
| pi | -0.0370 | 0.2452 | -0.151 | 0.8823 |

### ECM (Case 3)

- **ECT:** -0.5954 (OLS t=-6.286)
- **Bounds t (Case 3):** -5.410 (p=0.0009) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 0.77 years | **95% adjustment:** 3.3 years

### Wald Test: H0: beta_mu = beta_PyPK + beta_Br

- Difference: 0.0103 | SE: 0.2040 | t: 0.0504 | p: 0.9605
- Decision: **FAIL TO REJECT H0**

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 2.956 | 0.0856 | PASS |
| BG(2) | 7.767 | 0.0206 | WARNING |
| Breusch-Pagan | 16.536 | 0.2818 | PASS |
| Jarque-Bera | 1.487 | 0.4755 | PASS |
| RESET | 1.687 | 0.2166 | PASS |

---

## WWII Dummy Evaluation (1930-1973 samples)

### 3-channel

- Base: AIC=-293.91 BIC=-274.80
- D_wwii: AIC=-306.83 BIC=-285.98

### 4-channel

- Base: AIC=-302.83 BIC=-278.50
- D_wwii: AIC=-323.00 BIC=-296.93

---

## Cross-Sample Stability

### Long-run mu multiplier across samples

| Spec | 1930-1973 | 1940-1973 | 1948-1973 (prev) |
|------|-----------|-----------|------------------|
| 3ch | -0.134 | -0.142 | 0.276 |
| 4ch | -0.016 | 0.017 | 0.639 |

---

*Script: codes/stage_c/us/23_ardl_extended_netK_us.R*
*Generated: 2026-04-07*
