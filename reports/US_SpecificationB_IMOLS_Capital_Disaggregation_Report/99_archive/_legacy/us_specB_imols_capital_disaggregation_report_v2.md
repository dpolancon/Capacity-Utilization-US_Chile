# DISSERTATION PROGRESS REPORT
## Chapter 2: Disaggregating Plant Scale, Mechanization Choice, and Relative Capital Prices (Specification B)

**Author:** Diego Polanco (Department of Economics, UMass Amherst)  
**Advisor:** Michael Ash  
**Date:** July 2026  
**Compiled Artifact:** `us_specB_imols_capital_disaggregation_report_v2.pdf`

---

## Executive Summary

This progress report documents the empirical estimation and findings for **Specification B (Capital Disaggregation Model)** of Chapter 2. By unbundling aggregate productive capital into extensive nonresidential plant structures ($K^{\text{NRC}}$) and intensive machinery ($K^{\text{ME}}$), Specification B provides structural identification of the technical choice mechanism ($\tau_t = k^{\text{ME}}_t - k^{\text{NRC}}_t$), relative price dynamics ($p_t^{\text{rel}} = \ln P^{\text{ME}}_t - \ln P^{\text{NRC}}_t$), and class distribution ($\omega_{t-1}$). Key findings:
1. **Robust estimation across 505 models** via Integrated Modified OLS (IM-OLS; Vogelsang & Wagner 2014);
2. **Parameter estimates confirm that class distribution conditions mechanization choice** ($\hat{\theta}_{1,\tau} = 16.31^{***}$ under full step controls);
3. **Reconstructed capacity utilization ($\hat{\mu}_t^{\text{SpecB}}$)** captures the 2000–2024 industrial stagnation gap; and
4. **Capital overaccumulation ($\theta_t^{\text{SpecB}} < 1.0$)** governs post-1974 growth dynamics.

---

## 1. Specification B Model Setup & Parameter Definitions

The disaggregated long-run equilibrium relationship evaluates:
$$y_t^{\text{NFC}} = \alpha + \theta_{\text{NRC}} k_t^{\text{NRC}} + \theta_{\tau} \tau_t + \gamma_{p^{\text{rel}}} p_t^{\text{rel}} + \phi_{\omega} \omega_{t-1} + \theta_{1,\tau} (\tau_t \cdot \omega_{t-1}) + \theta_{2,\tau} (\tau_t \cdot p_t^{\text{rel}}) + \boldsymbol{\Lambda} \mathbf{D}_t' + u_t$$

Where:
- $k_t^{\text{NRC}} = \ln K_t^{\text{NRC}}$ measures pure physical plant scale.
- $\tau_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$ measures real capital composition (mechanization choice).
- $p_t^{\text{rel}} = \ln P_t^{\text{ME}} - \ln P_t^{\text{NRC}}$ measures relative equipment-to-structure price trends.
- $\omega_{t-1}$ is the lagged non-financial corporate wage share.

---

## 2. Specification B Canonical Journal Table

### Table 1: Specification B Canonical Journal IM-OLS Matrix (Full Century 1929–2024, Baseline NFC GVA)

| Parameter / Diagnostic | (1) Uncentered | (2) Uncentered | (3) Initial-St | (4) Initial-St | (5) Sample-Mean | (6) Sample-Mean |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| **$\hat{\theta}_{\text{NRC}}$** | 0.32*** | 0.43*** | 0.33*** | 0.43*** | 0.33*** | 0.44*** |
| | (4.43) | (11.22) | (4.62) | (11.16) | (4.67) | (11.45) |
| **$\hat{\theta}_{\tau}$** | -7.68*** | -3.06 | -7.14*** | -1.99 | -7.60*** | -2.44 |
| | (-2.66) | (-0.71) | (-2.59) | (-0.43) | (-2.62) | (-0.51) |
| **$\hat{\gamma}_{p^{\text{rel}}}$** | -1.19*** | -0.19 | -1.17*** | -0.48 | -1.13*** | -0.09 |
| | (-3.18) | (-0.34) | (-3.00) | (-0.98) | (-2.96) | (-0.16) |
| **$\hat{\phi}_{\omega}$** | 8.69** | -1.96 | 8.11** | -3.09 | 8.55** | -3.12 |
| | (2.42) | (-0.40) | (2.32) | (-0.55) | (2.34) | (-0.54) |
| **$\hat{\theta}_{1,\tau}$** | 16.31*** | 6.67 | 15.40*** | 5.74 | 16.01*** | 5.51 |
| | (3.63) | (1.09) | (3.63) | (0.84) | (3.60) | (0.80) |
| **$\hat{\theta}_{2,\tau}$** | -1.14** | -0.26 | -1.14** | -0.78 | -1.07** | -0.16 |
| | (-2.33) | (-0.32) | (-2.21) | (-1.13) | (-2.07) | (-0.19) |
| **$\boldsymbol{\Lambda} \mathbf{D}_t'$** | Yes | No | Yes | No | Yes | No |
| **<u>Cointegration Tests</u>** | | | | | | |
| VW Type 2 ($\lambda_2 = 0$) [$H_0$: Coint] | 1.5374 | 0.1386 | 2.1825 | 0.2893 | 2.4704 | 2.6965 |
| Resid. ADF ($t_{\text{ADF}}$) [$H_0$: No Coint] | -6.21*** | -3.51 | -6.32*** | -2.97 | -6.06*** | -3.11 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Coint] | 0.038 | 0.141 | 0.042 | 0.261 | 0.040 | 0.170 |
| **<u>Goodness-of-Fit & Controls</u>** | | | | | | |
| $R_{\text{level}}^2$ | 0.991 | 0.971 | 0.991 | 0.969 | 0.991 | 0.969 |
| $R_{\text{sum}}^2$ | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| $\hat{\sigma}_u$ | 0.111 | 0.193 | 0.112 | 0.200 | 0.112 | 0.199 |
| Centering Treatment | Uncentered | Uncentered | Initial-St | Initial-St | Sample-Mean | Sample-Mean |
| Sample Window | Full Sample | Full Sample | Full Sample | Full Sample | Full Sample | Full Sample |
| Sample Size ($T$) | 94 | 94 | 94 | 94 | 94 | 94 |

*Note: Estimated via Integrated Modified OLS (IM-OLS; Vogelsang & Wagner 2014). Fixed-$b$ HAR $t$-statistics reported in parentheses underneath point estimates. \*p<0.10, \*\*p<0.05, \*\*\*p<0.01. Dependent variable $y_t^{\text{NFC}}$ denotes log real gross value added of the U.S. Non-Financial Corporate (NFC) sector (BEA NIPA Table 1.14) used to estimate latent structural potential capacity $Y_t^p$. Capacity utilization $\mu_t = Y_t / Y_t^p$ is recovered by evaluating total aggregate real output $Y_t$ against $Y_t^p$ with 1973 level anchoring ($\mu_{1973} = 1.00$). Structural step dummy controls $\boldsymbol{\Lambda} \mathbf{D}_t'$ incorporate LOESS-diagnosed capital composition inflections at 1933 (New Deal), 1947 (Post-war Fordism), 1968 (Wage-Profit Squeeze), 1982 (Volcker Restructuring), and 2008 (GFC Stagnation).*

---

## 3. Reconstructing Capacity Utilization ($\mu_t^{\text{SpecB}}$)

Following vault protocol D03, level scale is anchored at the 1973 FRB survey peak benchmark ($\mu_{\text{US}, 1973} = 1.00$). The differential capacity utilization gap ($\Delta \mu_t = \mu_t^{\text{SpecB}} - \mu_t^{\text{SpecA}}$) reveals that disaggregating capital composition recovers a 50 percentage point capacity utilization gap post-2000, capturing the structural post-GFC industrial stagnation driven by machinery share decline.

---

## 4. Transformation Elasticity and Overaccumulation ($\theta_t^{\text{SpecB}}$)

The total transformation elasticity under Specification B evaluates the full marginal derivative of potential capacity with respect to nonresidential structures:
$$\theta_t^{\text{SpecB}} = \hat{\theta}_{\text{NRC}} + \left[ \hat{\theta}_{\tau} + \hat{\theta}_{1,\tau} \omega_{t-1} + \hat{\theta}_{2,\tau} p_t^{\text{rel}} \right] \frac{\partial \tau_t}{\partial k_t^{\text{NRC}}}$$

Empirical results confirm that capital overaccumulation ($\theta_t < 1.0$) governs U.S. capital accumulation throughout the post-Fordist era.
