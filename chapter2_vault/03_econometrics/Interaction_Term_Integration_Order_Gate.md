---
type: econometric_protocol
status: active
depends_on: [chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-23
layer: code_stage_design
gate_type: integration-order-and-interaction-classification
blocks_estimation_until_passed: true
applies_to:
- imols-cpr
- nonlinear-cointegration
- interaction-terms
- generated-regressors
created_by: E10V_I2_TRAP_RESOLUTION
role: active-gate
stage: pre-estimation-design
aliases:
- Interaction order gate
- Integration order gate
- IM-OLS CPR gate
- Interaction term gate
tags:
- chapter2/econometrics
- chapter2/active-gate
- chapter2/imols-cpr
- chapter2/pre-estimation-design
---

# Interaction-Term Integration Order Gate

## Gate Purpose
This gate blocks baseline estimation design until the stochastic status of the base variables and the interaction term is classified, and the orthogonalization filter is executed. IM-OLS CPR is the preferred design candidate only after the model survives this gate.

## Required Classifications
Before any estimation design, the candidate model must verify:
1.  **Base Variable Integration Order:** Verify that the base variables $\tilde{y}_t$ and $\tilde{k}_t$ are $I(1)$ using standard unit root tests (ADF, KPSS, PP) allowing for structural breaks.
2.  **Interaction Term Classification:** Identify if the interaction term $(\tilde{k}_t \cdot \omega_{t-1})$ is integrated of order two, $I(2)$, which is the case when $\omega_t \sim I(1)$.
3.  **Orthogonalization Filter:** Perform the auxiliary OLS regression:
    $$ (\tilde{k}_t \cdot \omega_{t-1}) = \alpha_0 + \alpha_1 \tilde{k}_t + \alpha_2 \omega_t + \hat{u}_t $$
    and extract the residuals $\hat{u}_t$.
4.  **VIF Multicollinearity Check:** Recalculate VIF values on the model $Y_t = a + b K_t + f \omega_t + d \hat{u}_t$. Confirm that VIFs for all regressors are below 10 (confirming that orthogonalization has resolved contemporaneous collinearity).

## Pass / Block Outcomes
```text
PASS_IMOLS_CPR_DESIGN_GATE
REQUIRE_INTEGRATION_ORDER_RECONCILIATION
REQUIRE_AUXILIARY_ORTHOGONALIZATION
BLOCK_DOLS_REGRESSOR_EXPLOSION
BLOCK_QOMEGA_REINTRODUCTION
```

## Links
- [[E10V_IMOLS_CPR_Active_Estimator_Lock]]
- [[Estimator_Status_Ledger_E10V]]
- [[E11_IMOLS_CPR_Asymptotic_Rationale]]
- [[_03_Econometrics_MOC]]
