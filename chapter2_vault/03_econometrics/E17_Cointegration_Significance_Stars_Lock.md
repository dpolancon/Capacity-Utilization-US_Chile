---
type: econometrics
status: active
depends_on:
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
  - chapter2_vault/03_econometrics/E15_Vogelsang_Wagner_IMOLS_Cointegration_Test_Lock.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-08-03
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
>
> **2026-08-03 update**: §2's prior ban on the VW Type 2 row is **superseded**. The manual Euclidean-norm calculation §2 warned against was never what shipped — `US_S50_section31_imols_estimation.R` and `COMMON_S40_baseline_imols_cpr_estimation.R` implement a proper Wald quadratic form (`λ2' V2⁻¹ λ2 / ω²`), consistent with [[E15_Vogelsang_Wagner_IMOLS_Cointegration_Test_Lock]]'s "PRIMARY & BINDING" designation. What *was* wrong, and is now fixed, is the critical values that statistic was compared against: a single hardcoded triple (11.45/13.78/18.90) applied to every model regardless of bandwidth or regressor count. See §3 below for the corrected methodology and the audit memo at `chapter2_vault/08_audits/2026-08-03_section31_cointegration_stars_audit.md` for the full before/after accounting.

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

## 2. VW Type 2 ($\lambda_2 = 0$) Test Statistic: Wald Form Retained, Critical Values Corrected

The Vogelsang and Wagner (2014) Type 2 test ($H_0$: Cointegration) is theoretically robust. `cointReg::cointRegIM` does not export a ready-made Wald statistic for $\lambda_2 = 0$, but the necessary variance-covariance matrix *can* be reconstructed from the model's design matrices and `fit$lambda2`/`fit$omega.u.v` — `calc_vw_type2_stat()` in `US_S50_section31_imols_estimation.R` (mirrored in `COMMON_S40_baseline_imols_cpr_estimation.R`) does exactly this, producing a genuine quadratic-form Wald statistic $\hat\lambda_2' \hat V_2^{-1} \hat\lambda_2 / \hat\omega^2$. This is **not** the Euclidean-norm shortcut this section previously warned against, and is not banned.

**What was actually broken** (found by audit, 2026-08-03): the statistic was compared against a single hardcoded critical-value triple (10%/5%/1% = 11.45/13.78/18.90) for every one of the 18 models in the Section 3.1 report, regardless of (a) each model's actual bandwidth choice and (b) whether the model had 2 or 3 stochastic regressors. Genuine Vogelsang-Wagner (2014) fixed-$b$ critical values are **not constant** — they vary by an order of magnitude across the bandwidth-ratio range and depend on the number of stochastic regressors $k$. The hardcoded triple matched no single $(b, k)$ cell of the actual published table.

**Fix**: `codes/COMMON_VW_fixedb_critical_values.R` digitizes the Vogelsang & Wagner (2014) critical-value supplement (Bartlett kernel, intercept-only case) for $k = 1..4$ stochastic regressors, over the full tabulated bandwidth-ratio grid $b = \text{bandwidth}/T \in [0.02, 1.00]$, and exposes `fixedb_crit()` / `fixedb_stars()` to interpolate the correct critical value for each model's actual $(b, k)$. Both the VW Type 2 row **and** every coefficient-level significance star (`$\hat\alpha$`, `$\hat\gamma^{\text{step}}$`, `$\hat\theta_0$`, `$\hat\theta_1$`, `$\hat\beta_{\text{cm}}$` — see §4) now use this module. Any script computing IM-OLS significance stars should `source()` this module rather than hardcoding critical values.

**Not yet resolved**: Shin LM ($C_{\text{Shin}}$) still uses a single fixed critical-value row (10%/5%/1% = 0.095/0.121/0.184) applied regardless of regressor count. Shin's (1994) original table could not be retrieved during the 2026-08-03 audit (source unreachable). This is flagged as provisional in all paper-facing footnotes pending independent verification — see the audit memo.

---

## 3. Fixed-$b$ Critical Values (Corrected 2026-08-03)

**Engle-Granger ADF** critical values depend on $m$, the total number of $I(1)$ variables in the system (1 dependent variable + stochastic regressors; step dummies do not count toward $m$). This test was already correctly implemented — `cv_adf()` in `US_S50_section31_imols_estimation.R` varies the MacKinnon (2010), Case 2 (constant only) critical values by $m$. The previously-locked $m=4$ ($k=3$ regressors) case remains:
- 10% Significance ($^*$): **-3.81**
- 5% Significance ($^{**}$): **-4.10**
- 1% Significance ($^{***}$): **-4.64**

*(Note: For short sub-samples like the Fordist era where $T=44$, small-sample bias pushes true critical values slightly more negative. The asymptotic boundaries remain the official reporting thresholds, but marginal significance around $-4.10$ in short samples must be interpreted cautiously).*

**VW Type 2 (Wald) and coefficient $t$-tests** now use the fixed-$b$, $(b,k)$-indexed tables in `codes/COMMON_VW_fixedb_critical_values.R` (source: Vogelsang & Wagner 2014 online supplement, "Tables with Critical Values for Integrated Modified OLS Estimation and Fixed-b Inference for Cointegrating Regressions," Bartlett kernel / intercept-only case). Currently tabulated for $k=1..4$ stochastic regressors; extend the module (do not hand-add constants elsewhere) if a future specification needs $k>4$.

---

## 4. Coefficient-Level Significance Stars Also Use Fixed-$b$ Critical Values

Prior to 2026-08-03, coefficient rows ($\hat\alpha$, $\hat\gamma^{\text{step}}$, $\hat\theta_0$, $\hat\theta_1$, $\hat\beta_{\text{cm}}$) in `US_S50_section31_imols_estimation.R` used naive standard-normal cutoffs (1.645/1.960/2.576) despite the report's own methodology claiming "fixed-$b$ HAR $t$-statistics." Genuine fixed-$b$ critical values for a single-coefficient $t$-test are systematically **larger** than the standard-normal ones (see [[E10V_IMOLS_CPR_Active_Estimator_Lock]]'s note that kernel/bandwidth choice moves significance stars), so the naive cutoffs **overstated significance**.

**Fix**: coefficient stars now use `fixedb_stars(..., stat = "t", k, b)` from `codes/COMMON_VW_fixedb_critical_values.R`, with $k$ = the model's number of stochastic regressors and $b$ = that model's actual bandwidth/$T$ ratio (same indexing as the VW Type 2 row). Auditing the Section 3.1 report under this correction flipped 39 coefficient-level stars (all downgrades — none gained significance), concentrated in Table 3 (Shaikh-Tonak Tier 2 wage share models) and the step-dummy rows across all three tables. See the audit memo for the full list.

**Open question, not resolved by this audit**: whether intercept and step-dummy coefficients (which multiply bounded, non-integrated regressors) should really be tested against the same $k$-indexed fixed-$b$ table derived for coefficients on stochastic $I(1)$ regressors, or whether Vogelsang & Wagner (2014) intends a different (possibly standard-normal) treatment for purely deterministic terms. The current implementation applies the stochastic-regressor table uniformly for consistency with the report's stated "fixed-$b$ HAR" methodology; revisit if a closer reading of the source paper indicates otherwise.
