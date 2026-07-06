---
status: methodological-warning
scope: chapter2-econometrics
estimator_status:
  fmols: blocked-for-nonlinear-baseline
  imols: blocked-for-nonlinear-baseline
  restricted_imols: blocked
  restricted_dols: preferred-design-candidate
proof_status: conditional-rationale
requires:
  - interaction-term-integration-gate
  - base-variable-integration-gate
  - lead-lag-sensitivity
created_by: D12V_ECONOMETRICS_VAULT_ESTIMATOR_PIVOT
role: methodological-warning
stage: pre-estimation-design
aliases:
  - FM-OLS failure
  - FMOLS failure
  - IM-OLS failure
  - IMOLS failure
  - Restricted IM-OLS blocked
tags:
  - chapter2/econometrics
  - chapter2/methodological-warning
  - chapter2/fmols
  - chapter2/imols
  - chapter2/pre-estimation-design
updated_by: D12V2_OBSIDIAN_ECONOMETRICS_VAULT_ORGANIZATION
---

# FM-OLS and IM-OLS Failure for Interaction Objects

## Problem object

The active problem is not a strictly linear cointegrating regression. Chapter 2 uses nonlinear/interacted/generated objects such as:

```text
z_t = x_1t × x_2t
```

The candidate long-run equation may include `x_1t`, `x_2t`, and `z_t`. The estimator must therefore handle a level interaction whose stochastic behavior is not automatically the same as an ordinary I(1) regressor.

## FM-OLS failure channel

Standard FM-OLS is designed for linear cointegrating regressions. Its correction relies on global long-run covariance adjustments that address long-run endogeneity and serial correlation for a linear levels relation.

That correction does not automatically resolve path-dependent nonlinear endogeneity introduced by multiplicative terms. The interaction object inherits the histories of both base variables, so a global covariance correction for the observed regressor matrix is not enough to authorize FM-OLS as the nonlinear Chapter 2 baseline.

## IM-OLS failure channel

Standard IM-OLS transforms the cointegrating regression through partial sums and uses integrated-space dominance for inference. That procedure does not automatically solve interaction-term endogeneity for nonlinear/interacted/generated objects.

The partial-sum transformation changes the space in which the coefficient is recovered, while the Chapter 2 reconstructed object must return to the log-level productive-capacity path. That trace-back problem becomes sharper when the long-run object includes generated interactions.

## Why restricted IM-OLS does not solve the problem

Restricted IM-OLS is blocked as a substitute for Restricted DOLS. Cumulative sums of admissible base variables do not purge interaction-term endogeneity in the same way that Restricted DOLS targets base-variable difference dynamics.

The DOLS restriction supplies a short-run sieve through leads/lags of admissible base differences. A partial-sum analogue changes the integration ladder and does not provide the same correction logic for the generated interaction level term.

## Contrast with Restricted DOLS

Restricted DOLS keeps the nonlinear level object in the long-run equation while restricting the dynamic correction set to admissible base-variable differences.

For `z_t = x_1t × x_2t`, the long-run level equation may retain `x_1t`, `x_2t`, and `z_t`. The dynamic augmentation uses leads/lags of `Δx_1t` and `Δx_2t`, not mechanical leads/lags of `Δz_t`, unless a separate nonlinear or polynomial-cointegration protocol authorizes that expansion.

## Qualification: not a global rejection of FM-OLS or IM-OLS

FM-OLS and IM-OLS remain legitimate references for standard linear cointegrating regressions under their assumptions. They are not baseline-authorized for the nonlinear/interacted/generated Chapter 2 object unless a separate specialized nonlinear or polynomial-cointegration protocol is explicitly authorized.

## Operational vault rule

Do not cite FM-OLS or IM-OLS notes as D12 baseline authorization for nonlinear/interacted/generated Chapter 2 specifications. Route the design through [[D12V_Restricted_DOLS_Active_Estimator_Lock]], [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]], and [[Interaction_Term_Integration_Order_Gate]].

## Links

- [[FMOLS_IMOLS_Failure_For_Interaction_Objects]]
- [[Estimator_Status_Ledger_D12V]]
