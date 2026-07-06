---
status: active-gate
scope: chapter2-econometrics
gate_type: integration-order-and-interaction-classification
blocks_estimation_until_passed: true
applies_to:
  - restricted-dols
  - nonlinear-cointegration
  - interaction-terms
  - generated-regressors
created_by: D12V_ECONOMETRICS_VAULT_ESTIMATOR_PIVOT
---

# Interaction-Term Integration Order Gate

## Gate purpose

This gate blocks baseline estimation design until the stochastic status of base variables and interaction/generated terms is classified. Restricted DOLS is the preferred design candidate only after the model object survives this gate.

## Required classifications

Before any Restricted DOLS baseline design, classify:

1. base variables as I(0), I(1), possible I(2), or unknown;
2. whether an interaction/generated term exists in the candidate equation;
3. whether base variables are cointegrated with each other;
4. whether the interaction term is I(1)-admissible, I(0)-control, mixed-order, generated, or blocked;
5. whether the sample window survives the restricted DOLS lead/lag grid.

## Base-variable checks

Each base variable must have documented integration-order evidence before it enters a nonlinear/interacted baseline design.

The gate must record whether the candidate base variable is:

- I(0);
- I(1);
- possible I(2);
- unknown;
- structurally broken in a way that makes the order classification unresolved.

## Interaction-term checks

For each generated term, record the base variables, generation rule, centering or scaling rule, and stochastic classification.

The interaction term must be classified as one of:

- I(1)-admissible;
- I(0)-control;
- mixed-order;
- generated but unresolved;
- blocked.

## Mixed-order cases

Mixed-order cases do not automatically fail, but they do block baseline design until the model object is reconciled. The design must explain whether the interaction is a control, a level relation component, a generated regressor with special handling, or a blocked term.

## Estimator implications

Restricted DOLS remains the preferred baseline-design estimator for nonlinear/interacted/generated Chapter 2 objects after this gate passes.

Standard FM-OLS, standard IM-OLS, and restricted IM-OLS are not substitutes for this gate.

Unrestricted DOLS remains blocked for interaction objects unless a separate protocol authorizes leads/lags of interaction-term differences.

## Pass / block outcomes

```text
PASS_RESTRICTED_DOLS_DESIGN_GATE
REQUIRE_INTEGRATION_ORDER_RECONCILIATION
REQUIRE_INTERACTION_TERM_CLASSIFICATION
BLOCK_MIXED_ORDER_UNRESOLVED
BLOCK_QOMEGA_REINTRODUCTION
BLOCK_BASELINE_BOUNDARY_LEAKAGE
```
