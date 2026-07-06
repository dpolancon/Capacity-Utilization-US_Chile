---
type: rule_note
status: binding
layer: method
scope: chapter2_core
design_role: specification_layering
estimator_status: restricted-dols-required-for-nonlinear-baseline
created: 2026-06-02
updated: 2026-06-11
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - A05_NRCEnvelope_MechanizationBias
  - M10_Empirical_Identification_Framework
role: superseded-for-baseline
stage: pre-estimation-design
aliases:
  - Binding specification layering rule
tags:
  - chapter2/econometrics
  - chapter2/superseded
  - chapter2/fmols
  - chapter2/imols
  - chapter2/qomega-parked
updated_by: D12V2_OBSIDIAN_ECONOMETRICS_VAULT_ORGANIZATION
---

# R10: Binding Specification Layering Rule

> [!warning] q_omega parked
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path. See [[D12V_Restricted_DOLS_Active_Estimator_Lock]].


> [!gate] D12V2 gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.


> [!warning] D12V2 status
> This note is not baseline authorization.
> FM-OLS and IM-OLS are blocked for nonlinear/interacted/generated Chapter 2 baseline specifications.
> Use [[D12V_Restricted_DOLS_Active_Estimator_Lock]], [[FMOLS_IMOLS_Failure_For_Interaction_Objects]], and [[Estimator_Status_Ledger_D12V]] before citing this note for estimation design.


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
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path. See [[D12V_Restricted_DOLS_Active_Estimator_Lock]].

## Core rule

[[R_distribution_conditioned_theta_identification]] governs every specification layer.

```text
A00 primitive scale interaction = preferred first layer
A05 composition interaction = competing specification
q accumulated indexes = parked historical-memory operators
Johansen/VECM = system robustness only
Threshold-FGLS = separate justified regime layer
reconstruction = blocked until human promotion and anchoring
```

## 1. Preferred first layer

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
\varepsilon_t.
$$

The identified object is:

$$
\theta_t=\theta_0+\theta_1\tilde d_t.
$$

The direct distribution term is retained as a nuisance control.

## 2. Composition-mediated competitor

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
\varepsilon_t.
$$

This specification tests mediation through productive-capital composition. It does not lock an additive-capital conclusion.

## 3. Variable-generation gate

Required first-layer variables are:

```text
k_prod_scale
d_centered_constant
k_prod_scale_x_d_centered
tau_ME_NR_centered
tau_ME_NR_x_d_centered
```

Every export must document the productive-capital boundary, distribution measure, constant reference, sample, and transformation.

## 4. Estimation and promotion

FM-OLS is main, IM-OLS is robustness, and DOLS is fragility. Cointegration admissibility, coefficient stability, fitted-path plausibility, and human review precede reconstruction.

Only a human-promoted coefficient vector may be used to reconstruct and anchor productive capacity.

## 5. Regime layer

Threshold or switching models follow only after the diagnostic ladder:

1. integration order;
2. deterministic components;
3. structural breaks;
4. nonlinear mean reversion;
5. threshold admissibility.

## Parked / not current baseline

The accumulated $q_t^{\omega,h}$ and $q_t^{ME,\omega,h}$ indexes remain possible historical-memory operators. Earlier level-interaction comparisons without the direct distribution control also remain historical only.

## Locked formulation

The primitive centered interaction is the preferred first-layer identification device. The centered composition interaction is the competing specification. Utilization remains downstream of productive-capacity reconstruction and anchoring.
