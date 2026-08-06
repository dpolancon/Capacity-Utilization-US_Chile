---
type: report
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
  - chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
  - chapter2_vault/06_paper_facing/results/03_monte_carlo_tail_convergence_report.md
stage_scope: section3_1
country: US
last_updated: 2026-08-04
updated_by: CMPR_100K_CUSTOM_CV_ESTIMATION_LOCK
layer: paper_facing_results
role: empirical_estimation_matrix
---

# Section 3.1 IM-OLS Cointegration Estimation Matrix: 100k Custom Critical Values (1929--2024)

This report presents the empirical cointegration results for Section 3.1 of Chapter 2. All 48 models are estimated via Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS (Vogelsang et al. 2024) over the full NIPA sample window (1931--2024, $T=94$ observations after listwise deletion). Point estimates are tuning-parameter free; coefficient ($\hat{\alpha}, \hat{\theta}_0, \hat{\theta}_1, \hat{\beta}_{\text{cm}}$) and $VW_{\text{stat}}$ ($CT_{IM}$) significance stars derive from exact matching against the **100,000-pass CMPR Monte Carlo custom critical value grid** (`cmpr_custom_critical_values_N100000.csv`).

## Cointegration Results

### Specification Set 1 (Part A: Baseline NFC \& Corporate GVA Wage Shares): Double Interaction IM-OLS Cointegration Estimates

**Dependent Variable: y_t^NFC (Log NFC Real GVA)**

| Model | M1.1a | M1.1b | M1.2a | M1.2b | M1.3a | M1.3b | M1.4a | M1.4b | M1.5a | M1.5b | M1.6a | M1.6b |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Demand Control | None | None | NetC Share | NetC Share | None | None | NetC Share | NetC Share | None | None | NetC Share | NetC Share |
| α (Intercept) | 6.47* | 8.97 | 6.47* | 8.97 | 6.29* | 6.81 | 6.29* | 6.81 | 6.48* | 9.19 | 6.48* | 9.19 |
|  | (0.34) | (0.89) | (0.34) | (0.89) | (0.34) | (0.83) | (0.34) | (0.83) | (0.35) | (0.98) | (0.35) | (0.98) |
| θ_0^priv (Private Core k_priv) | 0.59** | 0.34 | 0.59** | 0.34 | --- | --- | --- | --- | 0.59** | 0.33 | 0.59** | 0.33 |
|  | (0.02) | (0.08) | (0.02) | (0.08) |  |  |  |  | (0.03) | (0.09) | (0.03) | (0.09) |
| θ_0^aug (Infra-Augmented k_aug) | --- | --- | --- | --- | 0.59** | 0.52 | 0.59** | 0.52 | --- | --- | --- | --- |
|  |  |  |  |  | (0.02) | (0.07) | (0.02) | (0.07) |  |  |  |  |
| θ_1 (Interaction) | 0.02 | -0.05 | 0.02 | -0.05 | 0.06 | -0.07 | 0.06 | -0.07 | 0.01 | -0.07 | 0.01 | -0.07 |
|  | (0.13) | (0.15) | (0.13) | (0.15) | (0.12) | (0.10) | (0.12) | (0.10) | (0.12) | (0.16) | (0.12) | (0.16) |
| Step Shifts (D^step_T_b) | No | Yes | No | Yes | No | Yes | No | Yes | No | Yes | No | Yes |
**_Collinearity Diagnostics (VIF)_**

| VIF (k^cap) | 1.38 | 1.38 | 1.38 | 1.38 | 1.40 | 1.40 | 1.40 | 1.40 | 1.54 | 1.54 | 1.54 | 1.54 |
| VIF (Interaction) | 1.38 | 1.38 | 1.38 | 1.38 | 1.40 | 1.40 | 1.40 | 1.40 | 1.54 | 1.54 | 1.54 | 1.54 |
**_Cointegration Test Triad_**

| Resid. ADF (t_ADF) [H_0: No Coint.] | -4.15** | -3.00 | -4.15** | -3.00 | -3.97** | -3.52* | -3.97** | -3.52* | -4.10** | -3.15 | -4.10** | -3.15 |
| Shin LM (C_Shin) [H_0: Coint.] | 2.12*** | 0.56*** | 2.12*** | 0.56*** | 2.15*** | 0.92*** | 2.15*** | 0.92*** | 2.08*** | 0.45*** | 2.08*** | 0.45*** |
| VW Type 2 (S_Type 2) [H_0: Coint.] | 819.23*** | 1835.00*** | 819.23*** | 1835.00*** | 924.93*** | 719.49*** | 924.93*** | 719.49*** | 934.98*** | 1794.32*** | 934.98*** | 1794.32*** |
| Bandwidth Ratio (b) | 0.2852 | 0.1737 | 0.2852 | 0.1737 | 0.2832 | 0.1946 | 0.2832 | 0.1946 | 0.2876 | 0.1658 | 0.2876 | 0.1658 |
| Sample Size (T) | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 |
**Note: Estimated via Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS (Vogelsang et al. 2024) over 1929--2024. Standard errors in parentheses. Significance: ^*p<0.10, **p<0.05, ***p<0.01. Stars for coefficient rows (α, θ_0, θ_1, β_cm) and the Residual VW Type 2 (S_Type 2 / CT_IM) cointegration test are derived from a **100,000-pass custom Monte Carlo simulation suite** mapping the exact DGP variant (double vs. triple interaction polynomials, with/without step level-shifts, and with/without deterministic I(0) demand controls). This custom simulation adjusts the critical values for the non-linear integration orders of the regressors (I(1) \times I(1) and I(1) \times I(1) \times I(1)) and accounts for break-search degrees of freedom loss under the dynamic Bai-Perron audit (15% trimming). Resid. ADF stars follow MacKinnon (2010) Engle-Granger critical values, indexed by the total number of I(1) variables; the test is lag-augmented with the order selected by AIC (max 8) to whiten serial correlation. Shin LM stars use Shin's (1994) critical values (10%/5%/1% = 0.095/0.121/0.184) and are included for reference. **Star reversal warning:** For Residual ADF, stars indicate rejection of No Cointegration (supporting cointegration). For Shin LM and VW Type 2, stars indicate rejection of Cointegration. Distributional variables centered at 1929 initial state (t_0).**



### Specification Set 1 (Part B: Shaikh-Tonak Tier 2 Wage Share): Double Interaction IM-OLS Cointegration Estimates

**Dependent Variable: y_t^NFC (Log NFC Real GVA)**

| Model | M1.7a | M1.7b | M1.8a | M1.8b | M1.9a | M1.9b | M1.10a | M1.10b | M1.11a | M1.11b | M1.12a | M1.12b |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Demand Control | None | None | NetC Share | NetC Share | None | None | NetC Share | NetC Share | None | None | NetC Share | NetC Share |
| α (Intercept) | 6.29* | 8.75 | 6.29* | 8.75 | 7.64 | 5.44 | 7.64 | 5.44 | 7.52 | 4.84 | 7.52 | 4.84 |
|  | (0.35) | (0.90) | (0.35) | (0.90) | (0.67) | (1.23) | (0.67) | (1.23) | (0.69) | (1.24) | (0.69) | (1.24) |
| θ_0^priv (Private Core k_priv) | --- | --- | --- | --- | 0.48 | 0.67 | 0.48 | 0.67 | --- | --- | --- | --- |
|  |  |  |  |  | (0.06) | (0.11) | (0.06) | (0.11) |  |  |  |  |
| θ_0^aug (Infra-Augmented k_aug) | 0.59** | 0.35 | 0.59** | 0.35 | --- | --- | --- | --- | 0.48 | 0.70 | 0.48 | 0.70 |
|  | (0.02) | (0.08) | (0.02) | (0.08) |  |  |  |  | (0.06) | (0.10) | (0.06) | (0.10) |
| θ_1 (Interaction) | 0.05 | -0.04 | 0.05 | -0.04 | -0.28 | -0.19 | -0.28 | -0.19 | -0.27 | -0.18 | -0.27 | -0.18 |
|  | (0.12) | (0.14) | (0.12) | (0.14) | (0.13) | (0.13) | (0.13) | (0.13) | (0.13) | (0.13) | (0.13) | (0.13) |
| Step Shifts (D^step_T_b) | No | Yes | No | Yes | No | Yes | No | Yes | No | Yes | No | Yes |
**_Collinearity Diagnostics (VIF)_**

| VIF (k^cap) | 1.56 | 1.56 | 1.56 | 1.56 | 8.04 | 8.04 | 8.04 | 8.04 | 8.14 | 8.14 | 8.14 | 8.14 |
| VIF (Interaction) | 1.56 | 1.56 | 1.56 | 1.56 | 8.04 | 8.04 | 8.04 | 8.04 | 8.14 | 8.14 | 8.14 | 8.14 |
**_Cointegration Test Triad_**

| Resid. ADF (t_ADF) [H_0: No Coint.] | -3.92** | -2.95 | -3.92** | -2.95 | -3.40 | -2.78 | -3.40 | -2.78 | -3.13 | -2.86 | -3.13 | -2.86 |
| Shin LM (C_Shin) [H_0: Coint.] | 2.11*** | 0.60*** | 2.11*** | 0.60*** | 0.76*** | 0.20*** | 0.76*** | 0.20*** | 0.91*** | 0.20*** | 0.91*** | 0.20*** |
| VW Type 2 (S_Type 2) [H_0: Coint.] | 1004.15*** | 2306.76*** | 1004.15*** | 2306.76*** | 743.93*** | 2169.68*** | 743.93*** | 2169.68*** | 713.58*** | 1404.04*** | 713.58*** | 1404.04*** |
| Bandwidth Ratio (b) | 0.2856 | 0.1704 | 0.2856 | 0.1704 | 0.2665 | 0.2105 | 0.2665 | 0.2105 | 0.2830 | 0.1907 | 0.2830 | 0.1907 |
| Sample Size (T) | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 |
**Note: Estimated via Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS (Vogelsang et al. 2024) over 1929--2024. Standard errors in parentheses. Significance: ^*p<0.10, **p<0.05, ***p<0.01. Stars for coefficient rows (α, θ_0, θ_1, β_cm) and the Residual VW Type 2 (S_Type 2 / CT_IM) cointegration test are derived from a **100,000-pass custom Monte Carlo simulation suite** mapping the exact DGP variant (double vs. triple interaction polynomials, with/without step level-shifts, and with/without deterministic I(0) demand controls). This custom simulation adjusts the critical values for the non-linear integration orders of the regressors (I(1) \times I(1) and I(1) \times I(1) \times I(1)) and accounts for break-search degrees of freedom loss under the dynamic Bai-Perron audit (15% trimming). Resid. ADF stars follow MacKinnon (2010) Engle-Granger critical values, indexed by the total number of I(1) variables; the test is lag-augmented with the order selected by AIC (max 8) to whiten serial correlation. Shin LM stars use Shin's (1994) critical values (10%/5%/1% = 0.095/0.121/0.184) and are included for reference. **Star reversal warning:** For Residual ADF, stars indicate rejection of No Cointegration (supporting cointegration). For Shin LM and VW Type 2, stars indicate rejection of Cointegration. Distributional variables centered at 1929 initial state (t_0).**



### Specification Set 2 (Part A: Baseline NFC \& Corporate GVA Wage Shares): Triple Interaction IM-OLS Cointegration Estimates

**Dependent Variable: y_t^NFC (Log NFC Real GVA)**

| Model | M2.1a | M2.1b | M2.2a | M2.2b | M2.3a | M2.3b | M2.4a | M2.4b | M2.5a | M2.5b | M2.6a | M2.6b |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Demand Control | None | None | NetC Share | NetC Share | None | None | NetC Share | NetC Share | None | None | NetC Share | NetC Share |
| α (Intercept) | 6.46 | 8.18 | 9.39 | 9.41 | 6.20 | 8.08 | 9.14 | 7.22 | 6.50 | 7.76 | 9.32 | 9.36 |
|  | (0.49) | (1.06) | (0.77) | (0.88) | (0.50) | (1.10) | (0.79) | (0.88) | (0.50) | (1.16) | (0.75) | (0.89) |
| θ_0^priv (Private Core k_priv) | 0.59 | 0.42 | 0.51 | 0.36 | --- | --- | --- | --- | 0.59 | 0.45 | 0.51 | 0.36 |
|  | (0.04) | (0.09) | (0.03) | (0.07) |  |  |  |  | (0.04) | (0.10) | (0.03) | (0.07) |
| θ_0^aug (Infra-Augmented k_aug) | --- | --- | --- | --- | 0.60 | 0.41 | 0.52 | 0.50 | --- | --- | --- | --- |
|  |  |  |  |  | (0.04) | (0.09) | (0.03) | (0.06) |  |  |  |  |
| θ_1 (Interaction) | 0.00 | -0.19 | -0.06 | -0.09 | 0.04 | -0.17 | -0.03 | -0.46 | -0.01 | -0.16 | -0.06 | -0.07 |
|  | (0.10) | (0.09) | (0.07) | (0.08) | (0.10) | (0.10) | (0.07) | (0.13) | (0.10) | (0.10) | (0.07) | (0.08) |
| β_cm (NetC^share) | --- | --- | -3.45 | -0.93 | --- | --- | -3.42 | -0.25 | --- | --- | -3.37 | -0.92 |
|  |  |  | (0.76) | (0.62) |  |  | (0.77) | (0.60) |  |  | (0.75) | (0.63) |
| Step Shifts (D^step_T_b) | No | Yes | No | Yes | No | Yes | No | Yes | No | Yes | No | Yes |
**_Collinearity Diagnostics (VIF)_**

| VIF (k^cap) | 3.57 | 3.57 | 4.41 | 4.41 | 3.69 | 3.69 | 4.61 | 4.61 | 3.86 | 3.86 | 4.64 | 4.64 |
| VIF (Interaction) | 3.57 | 3.57 | 3.58 | 3.58 | 3.69 | 3.69 | 3.71 | 3.71 | 3.86 | 3.86 | 3.87 | 3.87 |
**_Cointegration Test Triad_**

| Resid. ADF (t_ADF) [H_0: No Coint.] | -4.02** | -4.00** | -2.11 | -2.64 | -3.82** | -3.00 | -2.16 | -3.21 | -3.97** | -3.93** | -2.10 | -2.62 |
| Shin LM (C_Shin) [H_0: Coint.] | 1.86*** | 0.66*** | 2.08*** | 0.83*** | 1.90*** | 0.71*** | 2.08*** | 0.41*** | 1.78*** | 0.72*** | 2.08*** | 0.83*** |
| VW Type 2 (S_Type 2) [H_0: Coint.] | 3910.69*** | 276.16*** | --- | --- | 3724.48*** | 359.15*** | --- | --- | 4021.16*** | 140.50*** | --- | --- |
| Bandwidth Ratio (b) | 0.2908 | 0.1688 | NA | NA | 0.2916 | 0.1688 | NA | NA | 0.2934 | 0.1734 | NA | NA |
| Sample Size (T) | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 |
**Note: Estimated via Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS (Vogelsang et al. 2024) over 1929--2024. Standard errors in parentheses. Significance: ^*p<0.10, **p<0.05, ***p<0.01. Stars for coefficient rows (α, θ_0, θ_1, β_cm) and the Residual VW Type 2 (S_Type 2 / CT_IM) cointegration test are derived from a **100,000-pass custom Monte Carlo simulation suite** mapping the exact DGP variant (double vs. triple interaction polynomials, with/without step level-shifts, and with/without deterministic I(0) demand controls). This custom simulation adjusts the critical values for the non-linear integration orders of the regressors (I(1) \times I(1) and I(1) \times I(1) \times I(1)) and accounts for break-search degrees of freedom loss under the dynamic Bai-Perron audit (15% trimming). Resid. ADF stars follow MacKinnon (2010) Engle-Granger critical values, indexed by the total number of I(1) variables; the test is lag-augmented with the order selected by AIC (max 8) to whiten serial correlation. Shin LM stars use Shin's (1994) critical values (10%/5%/1% = 0.095/0.121/0.184) and are included for reference. **Star reversal warning:** For Residual ADF, stars indicate rejection of No Cointegration (supporting cointegration). For Shin LM and VW Type 2, stars indicate rejection of Cointegration. Distributional variables centered at 1929 initial state (t_0).**



### Specification Set 2 (Part B: Shaikh-Tonak Tier 2 Wage Share): Triple Interaction IM-OLS Cointegration Estimates

**Dependent Variable: y_t^NFC (Log NFC Real GVA)**

| Model | M2.7a | M2.7b | M2.8a | M2.8b | M2.9a | M2.9b | M2.10a | M2.10b | M2.11a | M2.11b | M2.12a | M2.12b |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Demand Control | None | None | NetC Share | NetC Share | None | None | NetC Share | NetC Share | None | None | NetC Share | NetC Share |
| α (Intercept) | 6.24 | 7.93 | 9.06 | 8.60 | 8.30 | 8.68 | 9.42 | 9.49 | 8.15 | 8.44 | 9.38 | 8.98 |
|  | (0.52) | (1.13) | (0.78) | (1.00) | (0.81) | (0.70) | (0.70) | (0.81) | (0.87) | (0.73) | (0.74) | (0.88) |
| θ_0^priv (Private Core k_priv) | --- | --- | --- | --- | 0.42 | 0.39 | 0.44 | 0.43 | --- | --- | --- | --- |
|  |  |  |  |  | (0.07) | (0.06) | (0.04) | (0.06) |  |  |  |  |
| θ_0^aug (Infra-Augmented k_aug) | 0.60 | 0.43 | 0.52 | 0.41 | --- | --- | --- | --- | 0.43 | 0.40 | 0.44 | 0.45 |
|  | (0.04) | (0.10) | (0.03) | (0.08) |  |  |  |  | (0.07) | (0.06) | (0.05) | (0.07) |
| θ_1 (Interaction) | 0.02 | -0.15 | -0.03 | -0.01 | -0.31 | -0.38 | -0.23 | -0.30 | -0.30 | -0.36 | -0.20 | -0.29 |
|  | (0.10) | (0.10) | (0.07) | (0.09) | (0.13) | (0.11) | (0.08) | (0.07) | (0.13) | (0.11) | (0.08) | (0.07) |
| β_cm (NetC^share) | --- | --- | -3.33 | -0.89 | --- | --- | -2.21 | -2.12 | --- | --- | -2.48 | -1.99 |
|  |  |  | (0.76) | (0.63) |  |  | (0.66) | (0.39) |  |  | (0.68) | (0.40) |
| Step Shifts (D^step_T_b) | No | Yes | No | Yes | No | Yes | No | Yes | No | Yes | No | Yes |
**_Collinearity Diagnostics (VIF)_**

| VIF (k^cap) | 4.00 | 4.00 | 4.84 | 4.84 | 14.01 | 14.01 | 14.05 | 14.05 | 14.46 | 14.46 | 14.48 | 14.48 |
| VIF (Interaction) | 4.00 | 4.00 | 4.01 | 4.01 | 14.01 | 14.01 | 15.20 | 15.20 | 14.46 | 14.46 | 15.56 | 15.56 |
**_Cointegration Test Triad_**

| Resid. ADF (t_ADF) [H_0: No Coint.] | -3.77** | -2.98 | -2.16 | -2.50 | -3.27 | -2.90 | -2.52 | -3.06 | -2.30 | -2.85 | -2.47 | -3.09 |
| Shin LM (C_Shin) [H_0: Coint.] | 1.81*** | 0.76*** | 2.10*** | 0.90*** | 0.96*** | 0.51*** | 1.29*** | 0.38*** | 1.25*** | 0.52*** | 1.31*** | 0.39*** |
| VW Type 2 (S_Type 2) [H_0: Coint.] | 3822.34*** | 223.87*** | --- | --- | 88.61** | 3570.21*** | --- | --- | 91.10** | 3285.32*** | --- | --- |
| Bandwidth Ratio (b) | 0.2940 | 0.1691 | NA | NA | 0.2713 | 0.2047 | NA | NA | 0.2924 | 0.2029 | NA | NA |
| Sample Size (T) | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 |
**Note: Estimated via Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS (Vogelsang et al. 2024) over 1929--2024. Standard errors in parentheses. Significance: ^*p<0.10, **p<0.05, ***p<0.01. Stars for coefficient rows (α, θ_0, θ_1, β_cm) and the Residual VW Type 2 (S_Type 2 / CT_IM) cointegration test are derived from a **100,000-pass custom Monte Carlo simulation suite** mapping the exact DGP variant (double vs. triple interaction polynomials, with/without step level-shifts, and with/without deterministic I(0) demand controls). This custom simulation adjusts the critical values for the non-linear integration orders of the regressors (I(1) \times I(1) and I(1) \times I(1) \times I(1)) and accounts for break-search degrees of freedom loss under the dynamic Bai-Perron audit (15% trimming). Resid. ADF stars follow MacKinnon (2010) Engle-Granger critical values, indexed by the total number of I(1) variables; the test is lag-augmented with the order selected by AIC (max 8) to whiten serial correlation. Shin LM stars use Shin's (1994) critical values (10%/5%/1% = 0.095/0.121/0.184) and are included for reference. **Star reversal warning:** For Residual ADF, stars indicate rejection of No Cointegration (supporting cointegration). For Shin LM and VW Type 2, stars indicate rejection of Cointegration. Distributional variables centered at 1929 initial state (t_0).**




## Vault Links
- Outfitting Outline: [[Ch2_Outline_DEFINITIVE]]
- Paper Constitution: [[00E_Chapter2_PaperFacing_Constitution]]
- Monte Carlo Convergence: [[03_monte_carlo_tail_convergence_report]]
