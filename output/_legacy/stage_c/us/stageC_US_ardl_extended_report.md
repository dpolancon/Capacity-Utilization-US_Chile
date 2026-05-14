# Stage C Report — ARDL Extended Sample Estimations
## US Non-Financial Corporate Sector
**Date:** 2026-04-07 | **Script:** 22_ardl_extended_samples_us.R

---

## 1. Overview

| Estimation | Spec | Sample | Eff N | Order | AIC | R2 | Adj R2 | F(Case3) | F p | t(Case3) | t p | ECT | Half-life | LR mu | mu p |
|------------|------|--------|-------|-------|-----|-----|--------|----------|-----|----------|-----|-----|-----------|-------|------|
| 3ch_1930 | 3ch | 1930-1973 | 42 | 2,0,2,2 | -287.8 | 0.620 | 0.513 | 10.908 | 0.0001 | -5.883 | 0.0004 | -0.667 | 0.6 | 0.016 | 0.6654 |
| 4ch_1930 | 4ch | 1930-1973 | 42 | 2,0,0,3,1 | -299.0 | 0.722 | 0.632 | 8.144 | 0.0006 | -5.596 | 0.0008 | -0.612 | 0.7 | -0.020 | 0.5676 |
| 3ch_1940 | 3ch | 1940-1973 | 35 | 2,2,2,2 | -244.8 | 0.719 | 0.584 | 6.727 | 0.0019 | -4.480 | 0.0070 | -0.637 | 0.7 | 0.019 | 0.6445 |
| 4ch_1940 | 4ch | 1940-1973 | 35 | 1,0,2,2,1 | -244.5 | 0.699 | 0.574 | 4.413 | 0.0277 | -4.014 | 0.0480 | -0.553 | 0.9 | -0.025 | 0.6681 |
| 3ch_1947 | 3ch | 1947-1974 | 29 | 2,2,2,2 | -249.4 | 0.919 | 0.867 | 5.713 | 0.0080 | -4.484 | 0.0069 | -0.454 | 1.1 | 0.143 | 0.0217 |
| 4ch_1947 | 4ch | 1947-1974 | 29 | 2,2,2,2,2 | -251.0 | 0.938 | 0.875 | 4.803 | 0.0146 | -4.653 | 0.0081 | -0.498 | 1.0 | 0.252 | 0.1437 |

---

## 3ch_19301973_N44

**Sample:** 1930-1973 | **Effective N:** 42 | **Model:** ARDL(2,0,2,2)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 8.727 | 0.0001 | NA | NA |
| 3 | 10.908 | 0.0001 | -5.883 | 0.0004 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | 0.0229 | 0.0660 | 0.347 | 0.7309 |
| r | 0.0160 | 0.0606 | 0.265 | 0.7929 |
| mu | 0.0160 | 0.0367 | 0.437 | 0.6654 |
| pi | 0.0331 | 0.1875 | 0.177 | 0.8609 |

### ECM (Case 3)

- **ECT:** -0.6667 (OLS t=-6.908)
- **Bounds t (Case 3):** -5.883 (p=0.0004) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 0.63 years | **95% adjustment:** 2.7 years

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 0.743 | 0.3887 | PASS |
| BG(2) | 12.679 | 0.0018 | WARNING |
| Breusch-Pagan | 15.774 | 0.0718 | PASS |
| Jarque-Bera | 12.458 | 0.0020 | WARNING |
| RESET | 0.047 | 0.8302 | PASS |

---

## 4ch_19301973_N44

**Sample:** 1930-1973 | **Effective N:** 42 | **Model:** ARDL(2,0,0,3,1)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 7.306 | 0.0005 | NA | NA |
| 3 | 8.144 | 0.0006 | -5.596 | 0.0008 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | -0.0393 | 0.1201 | -0.327 | 0.7457 |
| mu | -0.0200 | 0.0345 | -0.578 | 0.5676 |
| B_real | 0.0801 | 0.0868 | 0.923 | 0.3633 |
| PyPK | 0.0707 | 0.0785 | 0.900 | 0.3750 |
| pi | -0.0724 | 0.1378 | -0.525 | 0.6031 |

### ECM (Case 3)

- **ECT:** -0.6118 (OLS t=-6.781)
- **Bounds t (Case 3):** -5.596 (p=0.0008) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 0.73 years | **95% adjustment:** 3.2 years

### Wald Test: H0: beta_mu = beta_PyPK + beta_Br

- Difference: -0.1044 | SE: 0.1217 | t: -0.8585 | p: 0.3972
- Decision: **FAIL TO REJECT H0**

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 0.644 | 0.4223 | PASS |
| BG(2) | 1.802 | 0.4062 | PASS |
| Breusch-Pagan | 11.835 | 0.2962 | PASS |
| Jarque-Bera | 17.955 | 0.0001 | WARNING |
| RESET | 2.311 | 0.1390 | PASS |

---

## 3ch_19401973_N34

**Sample:** 1940-1973 | **Effective N:** 35 | **Model:** ARDL(2,2,2,2)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 5.465 | 0.0024 | NA | NA |
| 3 | 6.727 | 0.0019 | -4.480 | 0.0070 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | -0.1282 | 0.1313 | -0.976 | 0.3392 |
| r | 0.0243 | 0.1211 | 0.201 | 0.8426 |
| mu | 0.0195 | 0.0417 | 0.468 | 0.6445 |
| pi | 0.4385 | 0.3536 | 1.240 | 0.2275 |

### ECM (Case 3)

- **ECT:** -0.6368 (OLS t=-5.515)
- **Bounds t (Case 3):** -4.480 (p=0.0070) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 0.68 years | **95% adjustment:** 3.0 years

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 2.947 | 0.0861 | PASS |
| BG(2) | 7.929 | 0.0190 | WARNING |
| Breusch-Pagan | 15.870 | 0.1460 | PASS |
| Jarque-Bera | 1.131 | 0.5681 | PASS |
| RESET | 1.274 | 0.2712 | PASS |

---

## 4ch_19401973_N34

**Sample:** 1940-1973 | **Effective N:** 35 | **Model:** ARDL(1,0,2,2,1)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 3.685 | 0.0354 | NA | NA |
| 3 | 4.413 | 0.0277 | -4.014 | 0.0480 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | -0.2266 | 0.1650 | -1.373 | 0.1825 |
| mu | -0.0252 | 0.0581 | -0.434 | 0.6681 |
| B_real | 0.1876 | 0.1381 | 1.358 | 0.1870 |
| PyPK | 0.1461 | 0.1354 | 1.079 | 0.2914 |
| pi | 0.0283 | 0.5112 | 0.055 | 0.9563 |

### ECM (Case 3)

- **ECT:** -0.5534 (OLS t=-5.074)
- **Bounds t (Case 3):** -4.014 (p=0.0480) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 0.86 years | **95% adjustment:** 3.7 years

### Wald Test: H0: beta_mu = beta_PyPK + beta_Br

- Difference: -0.1986 | SE: 0.1637 | t: -1.2135 | p: 0.2367
- Decision: **FAIL TO REJECT H0**

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 3.788 | 0.0516 | PASS |
| BG(2) | 7.000 | 0.0302 | WARNING |
| Breusch-Pagan | 12.387 | 0.2600 | PASS |
| Jarque-Bera | 0.408 | 0.8153 | PASS |
| RESET | 0.080 | 0.7802 | PASS |

---

## 3ch_19471974_N28

**Sample:** 1947-1974 | **Effective N:** 29 | **Model:** ARDL(2,2,2,2)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 4.664 | 0.0091 | NA | NA |
| 3 | 5.713 | 0.0080 | -4.484 | 0.0069 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | -0.1278 | 0.1211 | -1.056 | 0.3059 |
| r | 0.1191 | 0.1669 | 0.714 | 0.4850 |
| mu | 0.1430 | 0.0566 | 2.526 | 0.0217 |
| pi | 0.1425 | 0.3752 | 0.380 | 0.7088 |

### ECM (Case 3)

- **ECT:** -0.4541 (OLS t=-5.185)
- **Bounds t (Case 3):** -4.484 (p=0.0069) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 1.15 years | **95% adjustment:** 4.9 years

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 1.731 | 0.1883 | PASS |
| BG(2) | 2.270 | 0.3214 | PASS |
| Breusch-Pagan | 7.420 | 0.7641 | PASS |
| Jarque-Bera | 7.144 | 0.0281 | WARNING |
| RESET | 0.036 | 0.8517 | PASS |

---

## 4ch_19471974_N28

**Sample:** 1947-1974 | **Effective N:** 29 | **Model:** ARDL(2,2,2,2,2)

### Bounds Tests

| Case | F-stat | F p-value | t-stat | t p-value |
|------|--------|-----------|--------|-----------|
| 1 | NA | NA | NA | NA |
| 2 | 4.237 | 0.0126 | NA | NA |
| 3 | 4.803 | 0.0146 | -4.653 | 0.0081 |
| 4 | NA | NA | NA | NA |
| 5 | NA | NA | NA | NA |

### Long-Run Multipliers

| Variable | Estimate | SE | t-stat | p-value |
|----------|---------|-----|--------|---------|
| (Intercept) | -0.1361 | 0.1063 | -1.281 | 0.2209 |
| mu | 0.2520 | 0.1627 | 1.549 | 0.1437 |
| B_real | 0.0381 | 0.0831 | 0.459 | 0.6536 |
| PyPK | -0.0451 | 0.1512 | -0.299 | 0.7697 |
| pi | 0.0864 | 0.2680 | 0.322 | 0.7521 |

### ECM (Case 3)

- **ECT:** -0.4983 (OLS t=-5.557)
- **Bounds t (Case 3):** -4.653 (p=0.0081) — REJECTS H0 at 5%
- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.
- **Half-life:** 1.00 years | **95% adjustment:** 4.3 years

### Wald Test: H0: beta_mu = beta_PyPK + beta_Br

- Difference: 0.1291 | SE: 0.1933 | t: 0.6677 | p: 0.5152
- Decision: **FAIL TO REJECT H0**

### Diagnostics

| Test | Statistic | p-value | Decision |
|------|----------|---------|----------|
| BG(1) | 0.003 | 0.9569 | PASS |
| BG(2) | 0.662 | 0.7183 | PASS |
| Breusch-Pagan | 20.719 | 0.1090 | PASS |
| Jarque-Bera | 0.343 | 0.8423 | PASS |
| RESET | 0.001 | 0.9774 | PASS |

---

## WWII Dummy Evaluation (1930-1973 samples)

### 3-channel

- Base: AIC=-287.79 BIC=-268.68
- D_wwii: AIC=-298.10 BIC=-277.25

### 4-channel

- Base: AIC=-298.97 BIC=-278.12
- D_wwii: AIC=-318.03 BIC=-295.44

---

## Cross-Sample Stability

### Long-run mu multiplier across samples

| Spec | 1930-1973 | 1940-1973 | 1948-1973 (prev) |
|------|-----------|-----------|------------------|
| 3ch | 0.016 | 0.019 | 0.276 |
| 4ch | -0.020 | -0.025 | 0.639 |

---

*Script: codes/stage_c/us/22_ardl_extended_samples_us.R*
*Generated: 2026-04-07*
