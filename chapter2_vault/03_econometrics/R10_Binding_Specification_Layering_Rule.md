---
type: rule_note
status: binding
layer: method
scope: chapter2_core
design_role: specification_layering
created: 2026-06-02
updated: 2026-06-11
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - A05_NRCEnvelope_MechanizationBias
  - M10_Empirical_Identification_Framework
---

# R10: Binding Specification Layering Rule

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
