---
status: active-ledger
scope: chapter2-econometrics
created_by: D12V_ECONOMETRICS_VAULT_ESTIMATOR_PIVOT
role: active-ledger
stage: pre-estimation-design
aliases:
  - Estimator status ledger
  - D12V estimator ledger
  - Estimator admissibility ledger
tags:
  - chapter2/econometrics
  - chapter2/pre-estimation-design
updated_by: D12V2_OBSIDIAN_ECONOMETRICS_VAULT_ORGANIZATION
---

# Estimator Status Ledger D12V

| Estimator | Status for linear cointegration | Status for nonlinear/interacted objects | Status for generated/changing-coefficient objects | Allowed role | Blocked role | Required gate | Notes |
|---|---|---|---|---|---|---|---|
| Static OLS | Possible preliminary levels reference after cointegration is established, but not final inference basis for endogenous cointegration. | Not baseline. | Not baseline. | Descriptive or preliminary comparison. | Final inference basis for endogenous cointegration. | Cointegration admissibility. | Super-consistency alone does not settle inference or reconstruction. |
| Standard FM-OLS | Possible diagnostic or comparator for standard linear cointegration. | Blocked for nonlinear/interacted baseline. | Blocked for generated/changing-coefficient baseline. | Historical reference, diagnostic comparator, possible linear estimator under assumptions. | Baseline authorization for nonlinear/interacted/generated Chapter 2 objects. | [[Interaction_Term_Integration_Order_Gate]] plus separate linear-object classification if used. | See [[FMOLS_IMOLS_Failure_For_Interaction_Objects]]. |
| Standard IM-OLS | Possible diagnostic or comparator for standard linear cointegration. | Blocked for nonlinear/interacted baseline. | Blocked for generated/changing-coefficient baseline. | Historical reference, diagnostic comparator, possible linear estimator under assumptions. | Baseline authorization for nonlinear/interacted/generated Chapter 2 objects. | [[Interaction_Term_Integration_Order_Gate]] plus separate linear-object classification if used. | Not globally invalid; not Chapter 2 nonlinear baseline. |
| Restricted IM-OLS | Not needed as the primary linear baseline. | Blocked as substitute for Restricted DOLS. | Blocked as substitute for Restricted DOLS. | None for D12 baseline design. | Replacing Restricted DOLS with base-variable partial sums. | Not authorized. | Cumulative sums do not provide the Restricted DOLS short-run sieve logic. |
| Unrestricted DOLS | Possible standard DOLS design for strictly linear cointegration when lead/lags are admissible. | Blocked for interaction objects unless separately authorized. | Blocked for generated/changing-coefficient objects unless separately authorized. | Linear robustness or sensitivity where dynamic corrections are governed. | Mechanical leads/lags of interaction/generated differences. | Interaction-term protocol plus lead-lag authorization. | Sample-loss and collinearity risks are design-relevant. |
| Restricted DOLS | Possible but not necessary for strictly linear objects. | Preferred baseline-design estimator after gates. | Preferred baseline-design estimator after gates. | D12 baseline-design candidate. | Uncontrolled estimation before gates. | Integration-order, interaction-term classification, lead-lag sensitivity. | Keeps nonlinear level object; restricts dynamic corrections to base differences. |
| ARDL / ECM | Possible robustness or design comparison after order conditions are clear. | Not baseline replacement. | Not baseline replacement. | Short-run adjustment comparison or robustness design. | Replacement for the long-run nonlinear cointegration baseline. | Integration-order and model-object gate. | ECM coefficients do not identify the first-layer object by themselves. |
| FGLS / Prais-Winsten / Cochrane-Orcutt | Possible regime-layer correction under a separate threshold protocol. | Blocked as cointegration-endogeneity correction. | Blocked as generated-object baseline correction. | Regime-layer or serial-correlation correction after admissibility. | Substitute for cointegration/endogeneity correction. | Threshold/regime protocol. | Does not establish cointegration. |
| Phillips-Ouliaris | Diagnostic/admissibility test for residual-based cointegration. | Diagnostic/admissibility role only. | Diagnostic/admissibility role only. | Cointegration gate. | Final coefficient estimator. | Candidate-relation definition. | Tests no-cointegration null; does not choose estimator. |
| Engle-Granger | Diagnostic/admissibility framework. | Diagnostic role only. | Diagnostic role only. | Residual-based cointegration reference or screen. | Final coefficient estimator for Chapter 2 baseline. | Candidate-relation definition. | Residual behavior is not utilization. |
| Johansen / VECM | System cointegration and rank evidence under systems protocol. | Not automatically baseline. | Not automatically baseline. | System robustness or separate systems design. | Automatic replacement for single-equation Restricted DOLS design. | Separate systems protocol. | Requires its own identification and normalization discipline. |

## Links

- [[Estimator_Status_Ledger_D12V]]
- [[D12V_Restricted_DOLS_Active_Estimator_Lock]]
- [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]]
- [[FMOLS_IMOLS_Failure_For_Interaction_Objects]]
- [[Interaction_Term_Integration_Order_Gate]]
