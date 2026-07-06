---
type: R-note
id: R_Cointegration_Admissibility_Superconsistent_Estimators
title: Cointegration Admissibility for Super-Consistent Estimators
status: draft
estimator_status: restricted-dols-required-for-nonlinear-baseline
updated_by: D12V_ECONOMETRICS_VAULT_ESTIMATOR_PIVOT
created: 2026-06-03
updated: 2026-06-11
project: Chapter 2
repo_area: 02_econometrics
note_role: identification_guardrail
object_domain: long_run_transformation_relation
method_family: super_consistent_cointegrating_regression
primary_estimators:
  - FM-OLS
  - IM-OLS
  - DOLS
primary_gate: Phillips-Ouliaris residual-based cointegration test
secondary_gate: residual ADF stationarity diagnostic
scope:
  - theoretical_admissibility
  - residual_stationarity
  - long_run_coefficient_interpretation
  - super_consistency
locked_terms:
  - cointegration admissibility
  - residual-based cointegration gate
  - residual stationarity
  - no-cointegration null
  - super-consistent estimator
forbidden_terms:
  - FM-OLS cointegration test
  - Phillips-Hansen cointegration test
  - coefficient significance proves cointegration
  - residual ADF proves cointegration
related_specs:
  - SPEC_A00_PRIMITIVE_INTERACTION
  - SPEC_A05_COMPOSITION_INTERACTION
related_notes:
  - A00_Benchmark_Identification
  - A05_Distributive_Mechanization_Bias
  - A06_B1_E2B_Model_Choice_Lock
tags:
  - chapter2
  - econometrics
  - cointegration
  - super-consistency
  - residual-stationarity
  - phillips-ouliaris
  - fmols
  - imols
  - dols
---

# R11: Cointegration Admissibility for Super-Consistent Estimators

> [!warning] D12V status update — FM-OLS
> Standard FM-OLS is superseded as the active baseline estimator for nonlinear/interacted/generated Chapter 2 specifications.
> It remains available only as historical reference, diagnostic comparator, or possible estimator for strictly linear cointegration objects if the model object is explicitly classified as standard linear cointegration.
> Do not use this note as baseline authorization without passing through [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Interaction_Term_Integration_Order_Gate]].

> [!warning] D12V status update — IM-OLS
> Standard IM-OLS is not baseline-authorized for nonlinear/interacted/generated Chapter 2 specifications.
> A restricted IM-OLS analogue is blocked as a substitute for Restricted DOLS because cumulative sums of base variables do not resolve interaction-term endogeneity in the required way.
> Use [[FMOLS_IMOLS_Failure_For_Interaction_Objects]] and [[Estimator_Status_Ledger_D12V]] before citing this note for estimation design.

> [!important] D12V status update — DOLS
> The active Chapter 2 baseline-design candidate is Restricted DOLS, not generic DOLS.
> Restricted DOLS keeps nonlinear/interacted terms in the long-run level equation but restricts the dynamic correction set to admissible base-variable differences.
> Unrestricted DOLS is blocked for interaction objects unless a separate protocol authorizes leads/lags of interaction-term differences.
> See [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]].

> [!gate] D12V interaction-term gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.
> Restricted DOLS is preferred only after base-variable integration status, interaction-term status, and sample-window adequacy are classified.

> [!warning] q_omega remains parked
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path.

## Purpose

This note locks the theoretical admissibility rule for using super-consistent estimators in Chapter 2.

FM-OLS, IM-OLS, and DOLS estimate candidate cointegrating regressions. They do not establish cointegration by themselves. Their long-run interpretation requires that the candidate relation define a stationary residual.

The relevant admissibility question is therefore not whether a coefficient is statistically significant. The relevant admissibility question is whether the estimated long-run relation produces a residual that behaves as a stationary disequilibrium term.

## Core rule

For a candidate long-run relation,

$$
y_t = c + x_t'\beta + u_t,
$$

the coefficient vector $\beta$ is admissible as a cointegrating vector only if

$$
u_t \sim I(0).
$$

If $y_t$ and $x_t$ are nonstationary and no stationary linear combination exists, the levels regression is not a cointegrating regression. It may still produce large coefficients, high fit, or statistically significant terms, but those estimates are not admissible as long-run transformation parameters.

The residual is the object that separates a cointegrating relation from a spurious levels regression.

## Sequence of inference

The correct sequence is:

$$
\text{candidate long-run relation}
\rightarrow
\text{residual stationarity / cointegration admissibility}
\rightarrow
\text{super-consistent estimation}
\rightarrow
\text{corrected coefficient inference}.
$$

The incorrect sequence is:

$$
\text{statistically significant coefficient}
\rightarrow
\text{cointegration}.
$$

Coefficient significance cannot establish cointegration. It can only be interpreted after the long-run relation has passed an admissibility check.

## Role of the residual

The residual is not a secondary diagnostic. In a cointegrating regression, the residual is the empirical form of the disequilibrium term.

For Chapter 2, the candidate relation is not a short-run predictive regression. It is a long-run transformation relation linking output, capital accumulation, distribution, and capital composition. The residual must therefore represent bounded deviations from that relation.

If the residual is nonstationary, the candidate relation does not identify a stable long-run transformation path.

## Role of super-consistent estimators

FM-OLS, IM-OLS, and DOLS operate after the cointegration object has been defined.

OLS is super-consistent in a cointegrating regression, but super-consistency alone is not enough for valid inference. Long-run endogeneity, serial correlation, dynamic misspecification, bandwidth choices, lag choices, and finite-sample instability can distort standard inference.

The three estimators address these problems differently.

FM-OLS modifies least squares to correct long-run endogeneity and serial correlation.

IM-OLS transforms the cointegrating regression through an integrated modified procedure and reduces dependence on estimator-side tuning choices.

DOLS augments the long-run levels regression with leads and lags of first differences of the regressors, absorbing short-run dynamics and endogeneity effects through dynamic correction.

These estimators improve estimation and inference conditional on the cointegrating-regression object. They do not replace the requirement that the residual be stationary.

## Why Phillips-Ouliaris is required

A generic unit-root test on estimated residuals is useful as a diagnostic, but it is not the strongest theoretical gate for cointegration admissibility.

The residual is generated from an estimated long-run relation. It is not an ordinary observed time series. Its distribution reflects the prior estimation of the cointegrating vector.

Phillips-Ouliaris is designed for this problem. It is a residual-based test of the null of no cointegration. It tests whether the residual behavior is compatible with a unit root once the residual has been generated from a levels relation among nonstationary variables.

The conceptual null is:

$$
H_0: \text{no cointegration}.
$$

The alternative is:

$$
H_1: \text{cointegration}.
$$

Rejecting $H_0$ provides residual-based evidence that the variables form a stationary long-run combination.

This makes Phillips-Ouliaris more appropriate than treating a generic residual ADF test as if it were a full cointegration test. A residual ADF gate can remain useful as a screening diagnostic, but Phillips-Ouliaris is the formal residual-based cointegration gate.

## Normalization problem

Residual-based tests can depend on how the cointegrating regression is normalized. For example, estimating

$$
y_t = c + x_t'\beta + u_t
$$

can produce a different residual-test outcome than normalizing the relation on one of the regressors. This is not desirable when the theoretical object is a relation among levels rather than a single predictive equation.

The Phillips-Ouliaris framework addresses this problem through a normalization-invariant test. In implementation, the $P_z$ statistic is preferred because it does not depend on which variable is placed on the left-hand side of the cointegrating regression.

This is especially important for Chapter 2. The objects B1 and E2B are written as single-equation specifications, but conceptually they represent candidate long-run relations among a vector of variables. A normalization-invariant residual-based gate is therefore more appropriate for admissibility than a test tied to a single left-hand-side normalization.

## Chapter 2 specifications

For the preferred A00 benchmark, the candidate relation is:

$$
y_t
=
\alpha
+
\theta_0 k_t
+
\phi\tilde d_t
+
\theta_1(k_t\tilde d_t)
+
u_t^{A00}.
$$

The admissibility condition is:

$$
u_t^{A00} \sim I(0).
$$

If this condition holds, the transformation coefficient can be read as:

$$
\theta_t
=
\theta_0
+
\theta_1\tilde d_t.
$$

For the A05 composition-mediated candidate, the relation is:

$$
y_t
=
\alpha
+
\theta\tilde k_t^{scale}
+
\psi\tilde\tau_t
+
\phi\tilde d_t
+
\lambda(\tilde\tau_t\tilde d_t)
+
u_t^{A05}.
$$

The admissibility condition is:

$$
u_t^{A05} \sim I(0).
$$

Without residual stationarity, these interaction-implied effects are not admissible as long-run transformation effects.

## Parked / not current baseline

The accumulated $q_t^{\omega,h}$ and $q_t^{ME,\omega,h}$ relations remain possible historical-memory specifications. They are not the current A00 or A05 baseline.

## Distinction between admissibility and significance

Residual stationarity and coefficient significance answer different questions.

Residual stationarity asks whether the relation is admissible as a cointegrating relation.

Coefficient significance asks whether a specific term matters conditional on that admissibility.

A model can pass the residual gate and still have an insignificant coefficient of interest.

A model can have a significant coefficient and still fail the residual gate.

Only the first case can be retained as an admissible but substantively weak relation. The second case cannot be interpreted as a locked long-run relation.

## Protocol implication

The Chapter 2 model-choice workflow must separate four layers:

1. Candidate relation definition.
2. Cointegration admissibility.
3. Coefficient inference.
4. Reconstruction authorization.

Phillips-Ouliaris belongs to layer 2.

FM-OLS, IM-OLS, and DOLS belong to layer 3.

S40 reconstruction belongs to layer 4 and remains unauthorized until separately locked.

## Governance rule

Use Phillips-Ouliaris as the formal residual-based cointegration admissibility gate.

Keep residual ADF as a diagnostic screen only.

Do not describe FM-OLS, IM-OLS, or DOLS as cointegration tests.

Do not interpret a statistically significant long-run coefficient as evidence of cointegration.

Do not promote any specification to reconstruction if coefficient significance and residual cointegration evidence conflict.

## Locked statement

Residual stationarity is an admissibility condition for interpreting a levels regression as a cointegrating relation. FM-OLS, IM-OLS, and DOLS provide corrected estimation and inference conditional on that cointegrating object. Phillips-Ouliaris is the appropriate formal residual-based gate because it is designed for generated residuals from candidate cointegrating regressions and tests the null of no cointegration.

Coefficient significance cannot establish cointegration. Residual stationarity cannot establish substantive relevance by itself. A specification becomes credible only when residual-based cointegration evidence and coefficient robustness point in the same direction.
