---
status: active-lock
scope: chapter2-econometrics
active_estimator: restricted-dols
fmols_status: blocked-for-nonlinear-baseline
imols_status: blocked-for-nonlinear-baseline
restricted_imols_status: blocked
unrestricted_dols_status: blocked-for-interactions
q_omega_status: parked
requires_gate:
  - integration-order
  - interaction-term-classification
  - lead-lag-sensitivity
created_by: D12V_ECONOMETRICS_VAULT_ESTIMATOR_PIVOT
role: active-lock
stage: pre-estimation-design
aliases:
  - Restricted DOLS
  - RDOLS
  - Active estimator lock
  - D12V estimator pivot
  - Baseline estimator lock
tags:
  - chapter2/econometrics
  - chapter2/active-lock
  - chapter2/restricted-dols
  - chapter2/pre-estimation-design
  - chapter2/qomega-parked
updated_by: D12V2_OBSIDIAN_ECONOMETRICS_VAULT_ORGANIZATION
---

# D12V — Restricted DOLS Active Estimator Lock

## Active doctrine

Restricted DOLS is the preferred baseline-design estimator for Chapter 2 nonlinear/interacted/generated/changing-coefficient specifications, conditional on the integration-order gate, interaction-term classification gate, and lead-lag sensitivity gate.

This lock governs the design path for the first-layer transformation relation. It does not authorize uncontrolled coefficient estimation.

## Why this pivot is needed

Earlier vault notes treated FM-OLS as the main log-level estimator, IM-OLS as the robustness check, and DOLS as a generic fragility diagnostic. That hierarchy does not resolve the nonlinear/interacted object now governing Chapter 2. The baseline object contains generated interaction terms, changing elasticities, and downstream productive-capacity reconstruction. Standard linear cointegration corrections do not automatically discipline that object.

The pivot is required because the estimator must keep the nonlinear level object while preventing dynamic-correction terms from becoming a second generated structural equation.

## Restricted DOLS rule

For an interaction object:

```text
z_t = x_1t × x_2t
```

the long-run level equation may include:

```text
x_1t
x_2t
z_t
```

Restricted DOLS keeps the nonlinear or interaction term in the long-run level relation but restricts the short-run dynamic correction set to admissible base-variable differences:

```text
Delta x_1t
Delta x_2t
```

Leads/lags of interaction or generated terms are blocked unless a separate nonlinear or polynomial-cointegration protocol explicitly authorizes them.

## What is blocked

Standard FM-OLS is blocked as the active baseline estimator for nonlinear/interacted/generated Chapter 2 objects.

Standard IM-OLS is blocked as the active baseline estimator for nonlinear/interacted/generated Chapter 2 objects.

Restricted IM-OLS is blocked as a substitute for Restricted DOLS. Cumulative sums of admissible base variables do not provide the same short-run sieve logic as leads/lags of admissible base differences.

Unrestricted DOLS is blocked for interaction objects unless a separate protocol explicitly authorizes dynamic corrections for interaction-term differences.

## What remains diagnostic or historical

FM-OLS and IM-OLS remain legitimate references for standard linear cointegrating regressions under their assumptions. They are not baseline-authorized for the nonlinear/interacted/generated Chapter 2 object unless a separate specialized nonlinear or polynomial-cointegration protocol is explicitly authorized.

Phillips-Ouliaris, Engle-Granger, and Johansen/VECM remain admissibility and system-diagnostic tools under their own protocols. They do not select the Restricted DOLS baseline by themselves.

## Required gates before estimation

Before any D12 baseline estimation design, the candidate equation must pass:

1. base-variable integration-order classification;
2. interaction/generated-term classification;
3. base-variable cointegration checks where relevant;
4. sample-window adequacy under the restricted DOLS lead/lag grid;
5. q_omega boundary review confirming that q_omega-family variables remain parked.

The operative gate note is [[Interaction_Term_Integration_Order_Gate]].

## Relation to D12 baseline estimation design

D12B may construct a baseline estimation prompt only after this vault doctrine is installed. D12B must treat Restricted DOLS as the preferred design candidate, not as an automatic execution command. The design must still declare the candidate relation, classify integration orders, choose admissible base variables, define the lead/lag grid, and record effective sample survival.

## Links

- [[D12V_Restricted_DOLS_Active_Estimator_Lock]]
- [[FMOLS_IMOLS_Failure_For_Interaction_Objects]]
- [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]]
- [[Interaction_Term_Integration_Order_Gate]]
- [[Estimator_Status_Ledger_D12V]]
