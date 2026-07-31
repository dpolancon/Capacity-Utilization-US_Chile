---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-25
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

## Blocked Roles
*   **FWL Pre-Filtering / Auxiliary Residualization:** Blocked — mathematically non-commutative with partial summation.
*   **Standard DOLS / Restricted DOLS:** Blocked for baseline estimations due to regressor density (DOLS regressor explosion) and severe collinearity.
*   **Standard FM-OLS:** Blocked for baseline due to path-dependent quadratic variation in cross-product Brownian limits preventing constant LRCV bias correction.

