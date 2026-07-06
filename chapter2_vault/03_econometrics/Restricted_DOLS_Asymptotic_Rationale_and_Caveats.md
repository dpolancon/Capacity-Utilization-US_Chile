---
status: working-rationale
scope: chapter2-econometrics
proof_status: conditional-not-final
supports:
  - restricted-dols
  - exclusion-of-delta-interaction-leads-lags
caveats:
  - product-of-I1-processes-not-automatically-standard-I1
  - projection-lemma-requires-formal-caution
  - mixed-integration-case-requires-separate-treatment
created_by: D12V_ECONOMETRICS_VAULT_ESTIMATOR_PIVOT
---

# Restricted DOLS Asymptotic Rationale and Caveats

## Model object

The active object is a nonlinear/interacted long-run relation. For a generated interaction:

```text
z_t = x_1t × x_2t
```

the long-run level equation may include the base variables and the interaction term. The interaction stays in the level relation because it is the structural object used to recover the changing transformation elasticity.

## Restricted DOLS construction

Restricted DOLS estimates the long-run level relation while augmenting it with leads/lags only of admissible base-variable differences.

The correction set is therefore:

```text
Δx_1t
Δx_2t
```

not:

```text
Δz_t
Δ(x_1t × x_2t)
```

unless a separate nonlinear or polynomial-cointegration protocol explicitly authorizes that expansion.

## Why leads/lags are restricted to base differences

The interaction difference expands mechanically as:

```text
Δz_t = x_1t Δx_2t + x_2t Δx_1t + Δx_1t Δx_2t
```

Mechanical inclusion of leads/lags of `Delta z_t` can import level-scaled difference products into the short-run correction set. That creates collinearity risk, interpretation risk, and sample-loss risk without proving that the generated terms are admissible dynamic corrections.

## Why unrestricted DOLS is blocked for interactions

Unrestricted DOLS treats the interaction-generated difference as another object to be dynamically augmented. For Chapter 2, that move is not neutral. It can turn the auxiliary correction set into an ungoverned second model of the interaction process.

The blocked object is not DOLS as such. The blocked object is unrestricted DOLS for nonlinear/interacted/generated specifications where dynamic corrections for interaction-term differences have not been separately authorized.

## Conditional asymptotic rationale

The uploaded proof supports Restricted DOLS as a conditional asymptotic rationale. It should not be presented as an unconditional final theorem.

The proof's projection logic motivates the restricted correction set: if the endogeneity channel can be projected onto admissible base-variable difference dynamics, then leads/lags of those base differences can serve as the correction sieve while the interaction remains in the long-run level equation.

This rationale is conditional on the integration-order gate and the interaction-term classification gate. It does not eliminate the need to classify the stochastic order of the product term.

## Caveats

Products of I(1) processes cannot be assumed to behave as ordinary I(1) regressors without a gate.

Mixed integration cases require separate handling. An interaction between I(1) and I(0), or between cointegrated base variables, may have different implications from an interaction between unrelated I(1) variables.

The projection lemma requires formal caution. The vault can use it as design rationale, but D12B must not represent it as a completed proof that all interaction specifications are asymptotically settled.

## Operational rule for Chapter 2

Use Restricted DOLS as the preferred baseline-design estimator only after [[Interaction_Term_Integration_Order_Gate]] passes. Keep the interaction in the long-run level relation. Restrict DOLS leads/lags to admissible base-variable differences. Block interaction-difference augmentation unless a separate nonlinear or polynomial-cointegration protocol authorizes it.
