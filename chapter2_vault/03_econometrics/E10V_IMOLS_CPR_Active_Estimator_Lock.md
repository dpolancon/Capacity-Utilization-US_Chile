---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-08-01
layer: code_stage_design
active_estimator: imols-cpr
orthogonalization: forbidden
fwl_status: forbidden
centering_protocol: three-regime
dols_status: diagnostic-comparator
fmols_status: diagnostic-comparator
created_by: E10V_I2_TRAP_RESOLUTION
updated_by: CPR_IMOLS_ESTIMATION_PROTOCOL_LOCK
role: active-lock
stage: pre-estimation-design
tags:
  - chapter2/econometrics
  - chapter2/active-lock
  - chapter2/imols-cpr
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# E10V — IM-OLS CPR Active Estimator Lock

## Active Doctrine
Integrated Modified OLS (IM-OLS) adapted for Cointegrating Polynomial Regressions (CPR) is the preferred baseline-design estimator for Chapter 2. This lock governs all empirical estimations of the long-run transformation relation.

## Pre-Estimation Requirements
Before running the baseline estimation, the model must pass:
1.  **Integration Order & Polynomial Classification Gate:** Verify that base variables ($k_t, \tau_t, \omega_t$) are $I(1)$ using standard unit root tests under [[Interaction_Term_Integration_Order_Gate]], and classify the cross-product term $(\tau_t \cdot \omega_{t-1})$ as an $O_p(T)$ degree-2 polynomial CPR regressor.
2.  **FWL Pre-Filtering Prohibition:** Pre-estimation FWL orthogonalization of interaction terms is **formally forbidden**. Partial summation does not commute with projection ($S M_X \neq M_{SX} S$), meaning level-filtered residuals violate CPR Brownian limit theory. The interaction enters raw into the full design.
3.  **Three-Regime Centering Protocol:** Centering is strictly a finite-sample numerical stabilization choice (see [[N11_Centering_Protocol_Three_Regime]]). The interaction parameter $\hat{d}$ is mathematically invariant across all centering choices.

## Baseline Specification
The structural levels equation is:
$$ y_t = a + b k_t + \psi \tau_t + f \omega_t + d (\tau_t \omega_{t-1}) + u_t $$
where $k_t \equiv \ln K^{NRC}_t$ (structural envelope) and $\tau_t \equiv \ln K^{ME}_t - \ln K^{NRC}_t$ (composition log difference).

The model is estimated using the partial sum transformation of IM-OLS:
$$ \sum_{s=1}^t y_s = a \cdot t + b \sum_{s=1}^t k_s + \psi \sum_{s=1}^t \tau_s + f \sum_{s=1}^t \omega_s + d \sum_{s=1}^t (\tau_s \omega_{s-1}) + \lambda_k k_t + \lambda_\omega \omega_t + \varepsilon_t $$
where unaccumulated level nuisance terms ($\lambda_k k_t, \lambda_\omega \omega_t$) absorb long-run endogeneity covariance without requiring dynamic lead/lag augmentation or LRCV kernel estimation.

## Centering & Robustness Architecture
- **Main Specification (Regime A):** Uncentered raw variables; requires QR matrix factorization (`lm()`) or SVD (`lstsq`) to prevent floating-point precision loss.
- **Primary Robustness (Regime B):** Initial-state centering ($\tilde{\tau}_t = \tau_t - \tau_1, \tilde{\omega}_t = \omega_t - \omega_1$); provides canonical Brownian initialization ($B(0)=0$), eliminates numerical drift, and gives base coefficient $\hat{\psi}$ structural interpretation at the historical regime origin.
- **Secondary Robustness (Regime C):** Sample-mean centering ($\tilde{\tau}_t = \tau_t - \bar{\tau}, \tilde{\omega}_t = \omega_t - \bar{\omega}$); standard practice comparator.

## LRV Kernel/Bandwidth: Inference Layer Only (clarification, 2026-08-01)

The IM-OLS **point estimates are invariant to kernel and bandwidth choices**. The partial-sum transformation absorbs long-run endogeneity through the unaccumulated nuisance terms ($\lambda_k k_t, \lambda_\omega \omega_t$) above — no LRCV correction of the coefficients is performed, and no kernel enters the estimator itself.

The `kernel = "ba", bandwidth = "nw"` (Bartlett / Newey–West) arguments appearing in the repo's `cointReg::cointRegIM` calls (S19/S22/S33/S41 wrappers) are a **repo-wide inference-layer reporting convention**, not part of this lock. They enter only:

- the long-run variance $\hat\omega_{u \cdot v}$ that scales t-statistics,
- the normalization of the Shin LM cointegration statistic,
- the Vogelsang–Wagner test statistics.

Changing kernel or bandwidth can therefore move significance stars and test verdicts, **never coefficients**. Any statement attributing "Bartlett kernel / Newey–West bandwidth" to the E10V lock itself is a misattribution: kernel-dependent LRCV bias correction of coefficients is an **FM-OLS** property, and that dependence is among the reasons FM-OLS is blocked for the baseline (see Blocked Roles).

**Mechanism, corrected 2026-08-03**: the *how* of "moves significance stars" is the fixed-$b$ asymptotic framework (Kiefer & Vogelsang 2002, 2005) — critical values for both the VW Type 2 cointegration test and individual coefficient $t$-tests depend on the bandwidth-to-sample-size ratio $b=\text{bandwidth}/T$ and the number of stochastic regressors $k$, and are **not** the standard-normal 1.645/1.96/2.576 cutoffs. `codes/COMMON_VW_fixedb_critical_values.R` implements the correct $(b,k)$-indexed lookup (digitized from Vogelsang & Wagner 2014's published tables); see [[E17_Cointegration_Significance_Stars_Lock]] §2-4 for the full audit and correction.

## Blocked Roles
*   **FWL Pre-Filtering / Auxiliary Residualization:** Blocked — mathematically non-commutative with partial summation.
*   **Standard DOLS / Restricted DOLS:** Blocked for baseline estimations due to regressor density (DOLS regressor explosion) and severe collinearity.
*   **Standard FM-OLS:** Blocked for baseline due to path-dependent quadratic variation in cross-product Brownian limits preventing constant LRCV bias correction.

