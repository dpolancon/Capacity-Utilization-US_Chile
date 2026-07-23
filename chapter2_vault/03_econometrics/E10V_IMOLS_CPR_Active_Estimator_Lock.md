---
type: econometric_protocol
status: active
depends_on: [chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-23
layer: code_stage_design
active_estimator: imols-cpr
orthogonalization: mandatory
dols_status: diagnostic-comparator
fmols_status: diagnostic-comparator
created_by: E10V_I2_TRAP_RESOLUTION
role: active-lock
stage: pre-estimation-design
tags:
- chapter2/econometrics
- chapter2/active-lock
- chapter2/imols-cpr
---

# E10V — IM-OLS CPR Active Estimator Lock

## Active Doctrine
Integrated Modified OLS (IM-OLS) adapted for Cointegrating Polynomial Regressions (CPR) is the preferred baseline-design estimator for Chapter 2. This lock governs all empirical estimations of the long-run transformation relation.

## Pre-Estimation Requirements
Before running the baseline estimation, the model must pass:
1.  **Orthogonalization Filter:** The interaction term $(\tilde{k}_t \cdot \omega_{t-1})$ must be residualized against the linear components ($\tilde{k}_t$, $\omega_t$) using an auxiliary OLS regression. The resulting residuals $\hat{u}_t$ are used in the main equation.
2.  **Integration Order Gate:** Verify that base variables are $I(1)$ and the interaction term is $I(2)$ using unit root tests under [[Interaction_Term_Integration_Order_Gate]].

## Baseline Specification
The estimation equation is:
$$ \tilde{y}_t = a + b \tilde{k}_t + f \omega_t + d \hat{u}_t + e_t $$
where $\hat{u}_t$ is the orthogonalized interaction residual. The model is estimated using the partial sum transformation of IM-OLS:
$$ \sum_{s=1}^t \tilde{y}_s = a \cdot t + b \sum_{s=1}^t \tilde{k}_s + f \sum_{s=1}^t \omega_s + d \sum_{s=1}^t \hat{u}_s + \nu_t $$

## Blocked Roles
*   **Standard DOLS / Restricted DOLS:** Blocked for baseline estimations due to regressor density (DOLS regressor explosion) and severe collinearity.
*   **Standard FM-OLS:** Blocked for baseline due to I(2) long-run covariance matrix estimation sensitivity.
