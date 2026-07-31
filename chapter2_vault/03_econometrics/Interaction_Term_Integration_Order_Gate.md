---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-25
layer: code_stage_design
gate_type: integration-order-classification
blocks_estimation_until_passed: true
applies_to:
  - imols-cpr
  - nonlinear-cointegration
  - interaction-terms
  - generated-regressors
created_by: E10V_I2_TRAP_RESOLUTION
updated_by: CPR_IMOLS_ESTIMATION_PROTOCOL_LOCK
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
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# Interaction-Term Integration Order Gate

## Gate Purpose
This gate blocks baseline estimation design until the stochastic status of the base variables and the interaction term is classified. IM-OLS CPR is the preferred design candidate only after the model survives this gate.

## Required Classifications
Before any estimation design, the candidate model must verify:
1.  **Base Variable Integration Order:** Verify that the base variables ($y_t, k_t, \tau_t, \omega_t$) are $I(1)$ using standard unit root tests (ADF, KPSS, PP) allowing for structural breaks.
2.  **Interaction Term Classification:** Classify the cross-product term $(\tau_t \cdot \omega_{t-1})$ as an $O_p(T)$ degree-2 polynomial CPR regressor (not a classical $I(2)$ variable, as its second difference is not stationary $I(0)$).
3.  **FWL Pre-Filtering Prohibition:** Confirm that the interaction term is **not** subjected to auxiliary OLS orthogonalization or residualization ($SM_X \neq M_{SX}S$).
4.  **Centering Protocol Verification:** Confirm that estimation specifies Regime A (Uncentered main with QR/SVD matrix factorization) alongside Regime B (Initial-state centering) as the primary robustness check (see [[N11_Centering_Protocol_Three_Regime]]).

## Pass / Block Outcomes
```text
PASS_IMOLS_CPR_DESIGN_GATE
REQUIRE_INTEGRATION_ORDER_RECONCILIATION
BLOCK_FWL_PRE_FILTERING
BLOCK_DOLS_REGRESSOR_EXPLOSION
BLOCK_FMOLS_PATH_DEPENDENT_LRCV
```

## Links
- [[E10V_IMOLS_CPR_Active_Estimator_Lock]]
- [[Estimator_Status_Ledger_E10V]]
- [[E11_IMOLS_CPR_Asymptotic_Rationale]]
- [[N11_Centering_Protocol_Three_Regime]]
- [[_03_Econometrics_MOC]]

