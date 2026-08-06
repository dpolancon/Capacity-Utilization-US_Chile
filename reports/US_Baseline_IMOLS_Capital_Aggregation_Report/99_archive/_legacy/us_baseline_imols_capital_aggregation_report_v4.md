# DISSERTATION PROGRESS REPORT & ONLINE APPENDIX
## Chapter 2: Empirical Grounding, Capacity Reconstruction, and the Overaccumulation Regime (Specification A Appendix)

**Author:** Diego Polanco (Department of Economics, UMass Amherst)  
**Advisor:** Michael Ash  
**Date:** July 2026  
**Compiled Artifact:** `us_baseline_imols_capital_aggregation_report_v4.pdf`

---

## Executive Summary

This progress report provides the complete, paper-facing empirical appendix for **Specification A (Single Aggregate Capital Model)** of Chapter 2. The report presents the full range of 168 estimated IM-OLS cointegrating regressions across three master matrices:
1. **Primary Accumulation Eras Matrix** comparing Full Sample (1929–2024), Fordism (1929–1973), and Post-Fordism (1974–2024) across Centering Treatments;
2. **Multi-Wage Share Robustness Matrix** comparing Baseline NFC GVA, Corporate GVA, Shaikh-Tonak Tier 1, and Shaikh-Tonak Tier 2 wage measures; and
3. **Macroeconomic Sub-Window Diagnostic Matrix** evaluating Interwar & WWII, Golden Age, Neoliberal Restructuring, and Post-GFC Stagnation subwindows.

---

## 1. Specification A Appendix Tables

### Table A1: Specification A Primary Accumulation Eras IM-OLS Matrix (Full Sample, Fordism, Post-Fordism)

*(Conditional Landscape Orientation)*

| Parameter / Diagnostic | (1) Uncentered | (2) Uncentered | (3) Uncentered | (4) Initial-St | (5) Initial-St | (6) Initial-St | (7) Sample-Mean | (8) Sample-Mean | (9) Sample-Mean |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **$\hat{\beta}_{\text{Kcap}}$** | 0.49 | 0.28 | -0.32 | 12.65*** | 2.50*** | 14.15*** | 15.37*** | 2.76*** | 14.28*** |
| | (0.08) | (0.05) | (-0.11) | (128.24) | (21.57) | (155.07) | (50.50) | (9.73) | (112.51) |
| **$\hat{\phi}_{\omega}$** | 1.21*** | 0.81 | -0.33 | 0.81*** | 0.38* | -0.06 | 0.76*** | 0.41** | -0.05 |
| | (3.05) | (1.49) | (-0.72) | (19.15) | (1.81) | (-0.38) | (20.42) | (2.05) | (-0.32) |
| **$\hat{\theta}_{1}$** | 5.01 | -0.19 | 17.65 | -10.64*** | -0.07 | -15.42*** | -3.16** | 0.05 | -0.49 |
| | (0.55) | (-0.02) | (0.83) | (-3.70) | (-0.02) | (-2.99) | (-2.37) | (0.01) | (-0.32) |
| **$\boldsymbol{\Lambda} \mathbf{D}_t'$** | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| **<u>Cointegration Tests</u>** | | | | | | | | | |
| VW Type 2 ($\lambda_2 = 0$) [$H_0$: Coint] | 0.0736 | 0.3644 | 0.1704 | 1.5956 | 0.2307 | 0.1979 | 0.2570 | 0.2312 | 0.0463 |
| Resid. ADF ($t_{\text{ADF}}$) [$H_0$: No Coint] | -3.78 | -4.43** | -4.68** | -3.75 | -4.43** | -4.68** | -4.56** | -4.43** | -4.68** |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Coint] | 0.118 | 0.093 | 0.098 | 0.082 | 0.093 | 0.098 | 0.157 | 0.093 | 0.098 |
| **<u>Goodness-of-Fit & Controls</u>** | | | | | | | | | |
| $R_{\text{level}}^2$ | 0.974 | 0.974 | 0.985 | 0.982 | 0.974 | 0.985 | 0.979 | 0.974 | 0.985 |
| $R_{\text{sum}}^2$ | 0.998 | 0.998 | 0.999 | 0.999 | 0.998 | 0.999 | 0.999 | 0.998 | 0.999 |
| $\hat{\sigma}_u$ | 0.185 | 0.165 | 0.126 | 0.155 | 0.165 | 0.126 | 0.164 | 0.165 | 0.126 |
| Sample Window | Full Sample | Fordism | Post-Fordism | Full Sample | Fordism | Post-Fordism | Full Sample | Fordism | Post-Fordism |
| Sample Size ($T$) | 94 | 44 | 50 | 94 | 44 | 50 | 94 | 44 | 50 |

---

### Table A2: Specification A Multi-Wage Share Robustness Matrix (Full Century 1929–2024)

*(Portrait Orientation)*

| Parameter / Diagnostic | (1) Baseline NFC GVA | (2) Corporate GVA | (3) Shaikh-Tonak Tier 1 | (4) Shaikh-Tonak Tier 2 |
|---|:---:|:---:|:---:|:---:|
| **$\hat{\beta}_{\text{Kcap}}$** | 12.65*** | 12.66*** | 12.69*** | 12.60*** |
| | (128.24) | (130.83) | (133.88) | (148.15) |
| **$\hat{\phi}_{\omega}$** | 0.81*** | 0.84*** | 0.83*** | 0.92*** |
| | (19.15) | (18.92) | (20.21) | (13.53) |
| **$\hat{\theta}_{1}$** | -10.64*** | -11.37*** | -5.40*** | -3.33*** |
| | (-3.70) | (-4.03) | (-3.46) | (-3.14) |
| **$\boldsymbol{\Lambda} \mathbf{D}_t'$** | Yes | Yes | Yes | Yes |
| **<u>Cointegration Tests</u>** | | | | |
| VW Type 2 ($\lambda_2 = 0$) [$H_0$: Coint] | 1.5956 | 1.2763 | 0.2344 | 0.4313 |
| Resid. ADF ($t_{\text{ADF}}$) [$H_0$: No Coint] | -3.75 | -3.87 | -3.90 | -3.28 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Coint] | 0.082 | 0.078 | 0.103 | 0.110 |
| **<u>Goodness-of-Fit & Controls</u>** | | | | |
| $R_{\text{level}}^2$ | 0.982 | 0.983 | 0.984 | 0.984 |
| $R_{\text{sum}}^2$ | 1.000 | 1.000 | 1.000 | 1.000 |
| $\hat{\sigma}_u$ | 0.155 | 0.147 | 0.145 | 0.144 |
| Centering Treatment | Initial-St | Initial-St | Initial-St | Initial-St |
| Sample Window | Full Sample | Full Sample | Full Sample | Full Sample |
| Sample Size ($T$) | 94 | 94 | 94 | 94 |

---

### Table A3: Specification A Macroeconomic Sub-Window Diagnostic Sensitivity Matrix

*(Portrait Orientation)*

| Parameter / Diagnostic | (1) Interwar & WWII | (2) Golden Age | (3) Neoliberal Restruct | (4) Post-GFC Stagnation |
|---|:---:|:---:|:---:|:---:|
| **$\hat{\beta}_{\text{Kcap}}$** | 2.05** | 2.50*** | 1.95*** | 0.74*** |
| | (2.29) | (21.57) | (9.48) | (3.78) |
| **$\hat{\phi}_{\omega}$** | 0.69 | 0.38* | -0.10 | 0.08 |
| | (0.83) | (1.81) | (-0.46) | (0.33) |
| **$\hat{\theta}_{1}$** | -12.43 | -0.07 | -15.26 | 0.09 |
| | (-1.08) | (-0.02) | (-0.97) | (0.01) |
| **$\boldsymbol{\Lambda} \mathbf{D}_t'$** | Yes | Yes | Yes | Yes |
| **<u>Cointegration Tests</u>** | | | | |
| VW Type 2 ($\lambda_2 = 0$) [$H_0$: Coint] | 0.0469 | 0.2307 | 0.1704 | 0.1170 |
| Resid. ADF ($t_{\text{ADF}}$) [$H_0$: No Coint] | -3.11 | -4.43** | -4.68** | -2.85 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Coint] | 0.104 | 0.093 | 0.098 | 0.124 |
| **<u>Goodness-of-Fit & Controls</u>** | | | | |
| $R_{\text{level}}^2$ | 0.941 | 0.974 | 0.985 | 0.962 |
| $R_{\text{sum}}^2$ | 0.995 | 0.998 | 0.999 | 0.996 |
| $\hat{\sigma}_u$ | 0.218 | 0.165 | 0.126 | 0.084 |
| Centering Treatment | Initial-St | Initial-St | Initial-St | Initial-St |
| Sample Window | Interwar & WWII | Golden Age | Neoliberal Restruct | Post-GFC Stagnation |
| Sample Size ($T$) | 17 | 26 | 34 | 15 |

*Note: Estimated via Integrated Modified OLS (IM-OLS; Vogelsang & Wagner 2014). Fixed-$b$ HAR $t$-statistics reported in parentheses underneath point estimates. \*p<0.10, \*\*p<0.05, \*\*\*p<0.01. Dependent variable $y_t^{\text{NFC}}$ denotes log real gross value added of the U.S. Non-Financial Corporate (NFC) sector (BEA NIPA Table 1.14) used to estimate latent structural potential capacity $Y_t^p$. Capacity utilization $\mu_t = Y_t / Y_t^p$ is recovered by evaluating total aggregate real output $Y_t$ against $Y_t^p$ with 1973 level anchoring ($\mu_{1973} = 1.00$). Structural step dummy controls $\boldsymbol{\Lambda} \mathbf{D}_t'$ incorporate LOESS-diagnosed inflections on aggregate capital stock at 1933, 1947, 1974, and 2008.*
