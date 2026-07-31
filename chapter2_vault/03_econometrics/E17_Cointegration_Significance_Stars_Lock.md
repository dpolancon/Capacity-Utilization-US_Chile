---
type: econometrics
status: active
depends_on:
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
  - chapter2_vault/03_econometrics/E15_Vogelsang_Wagner_IMOLS_Cointegration_Test_Lock.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-26
updated_by: COINTEGRATION_STARS_AUDIT
layer: governance_constraint
role: cointegration_star_lock
stage: post-estimation-diagnostics
tags:
  - chapter2/econometrics
  - chapter2/cointegration
  - chapter2/imols
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# E17: Cointegration Significance Stars and Test Triad Lock

> [!IMPORTANT]
> **Constitutional Declaration**: This lock governs the interpretation, reporting, and critical value calibration of cointegration tests for IM-OLS estimations in Chapter 2. It formally recognizes the **"Star Reversal Paradox"** between competing Null Hypotheses, enforcing that significance stars (`*`, `**`, `***`) have diametrically opposed economic meanings depending on the test.

---

## 1. The "Star Reversal" Paradox (Opposing Null Hypotheses)

The two primary cointegration diagnostic tests employed in the IM-OLS framework evaluate opposing Null Hypotheses ($H_0$). Therefore, the standard convention of assigning stars for statistical significance must be interpreted with extreme caution:

| Test | Null Hypothesis ($H_0$) | What Stars (`**`) Mean | Ideal Result for a Valid Model |
| :--- | :--- | :--- | :--- |
| **Resid. ADF ($t_{\text{ADF}}$)** | **No Cointegration** (Residuals are I(1)) | **Cointegration is Valid** (Rejects I(1) residuals) | **STARS** (`***` or `**`) |
| **Shin LM ($C_{\text{Shin}}$)** | **Cointegration** (Residuals are I(0)) | **Cointegration is Invalid/Spurious** (Rejects I(0)) | **NO STARS** |

### Reader Warning Clause
To prevent cognitive dissonance when readers observe mixed star patterns across tests, **all paper-facing tables must include the following explicit warning in their footnotes**:
> *"Note: For the Residual ADF test, significance stars indicate rejection of No Cointegration (supporting cointegration). For the Shin LM test, significance stars indicate rejection of Cointegration (indicating spurious regression)."*

---

## 2. Suspension of VW Type 2 ($\lambda_2 = 0$) Test Statistic

The Vogelsang and Wagner (2014) Type 2 test ($H_0$: Cointegration) is theoretically robust, but the underlying R package (`cointReg::cointRegIM`) does not export the variance-covariance matrix necessary to construct a valid Wald test for $\lambda_2 = 0$. 

Any manual Euclidean norm calculation (`sqrt(sum(lambda2^2))`) is mathematically invalid and produces spurious significance stars. 
**Directive**: The VW Type 2 test row is hereby **banned** from all empirical reporting tables until package-level Wald test functionality is implemented. The Shin LM test ($C_{\text{Shin}}$) assumes full responsibility as the primary $H_0$: Cointegration test.

---

## 3. Engle-Granger ADF Critical Values for $m=4$ ($k=3$ Regressors)

The critical values for the Engle-Granger residual ADF test depend on $m$, the total number of $I(1)$ variables in the system (1 dependent variable + 3 stochastic regressors: $k_t^{\text{cap}}$, $\omega_{t-1}$, and their interaction). Step dummy controls do not count toward $m$.

Under MacKinnon (2010), Case 2 (Constant only) for $m=4$, the binding asymptotic critical values for the ADF test are locked as follows:
- 10% Significance ($^*$): **-3.81**
- 5% Significance ($^{**}$): **-4.10**
- 1% Significance ($^{***}$): **-4.64**

*(Note: For short sub-samples like the Fordist era where $T=44$, small-sample bias pushes true critical values slightly more negative. The asymptotic boundaries remain the official reporting thresholds, but marginal significance around $-4.10$ in short samples must be interpreted cautiously).*
