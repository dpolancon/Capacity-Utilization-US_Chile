---
title: "A00: Aggregate Transformation Benchmark"
type: "note"
subtype: "object"
status: "active"
layer: "analytical_foundation"
design_role: "baseline_identification"
scope: "chapter2_core"
created: 2026-06-01
updated: 2026-06-11
related_to:
  - "R_distribution_conditioned_theta_identification"
  - "A01_Extensive_Accumulation"
  - "A02_Intensive_Accumulation"
  - "A03_TransformationElasticity_Two-CapitalCapacityComposition"
  - "A04_PeripheralTransformationElasticity"
  - "N01_CapacityUtilization_StructuralObject"
  - "M10_Empirical_Identification_Framework"
  - "R04_FMOLS_structural_preservation"
---

# A00: Aggregate Transformation Benchmark

## Core claim

A00 is the first-layer aggregate productive-capital benchmark governed by [[R_distribution_conditioned_theta_identification]]. It identifies a distribution-conditioned capital-to-capacity elasticity. It does not identify utilization, short-run adjustment, or a demand regime.

The capital object is:

$$
K_t
\equiv
K_t^{prod}.
$$

Its boundary must be fixed before estimation. All fixed assets are not productive-capacity capital by default.

## Preferred first-layer equation

The primitive interaction is:

$$
y_t
=
\alpha
+
\theta_0 k_t
+
\phi \tilde d_t
+
\theta_1(k_t\tilde d_t)
+
\varepsilon_t,
$$

with:

$$
\tilde d_t=d_t-\bar d
$$

and:

$$
\theta_t=\theta_0+\theta_1\tilde d_t.
$$

The direct distribution term is a nuisance control. It prevents the interaction from absorbing distributional level effects and protects the specification against arbitrary rebasing of $k_t$.

## Identified and reconstructed objects

The long-run coefficient vector identifies $\hat\theta_t$. Productive capacity is then reconstructed and anchored. Utilization is derived only afterwards:

$$
\text{long-run coefficient vector}
\rightarrow
\hat\theta_t
\rightarrow
\hat y_t^p
\rightarrow
\hat\mu_t.
$$

The residual is an admissibility and diagnostic object. It does not directly identify utilization.

## Boundary with demand variables

Government expenditure, exports, consumption, imports, and other demand-composition variables belong to realization, utilization, leakages, fixed points, and later interpretation. They are not direct regressors in the first-layer productive-capacity equation.

## Boundary with A03 and A05

A00 tests direct scale-conditioning through aggregate productive capital. [[A03_TransformationElasticity_Two-CapitalCapacityComposition]] and [[A05_NRCEnvelope_MechanizationBias]] open the alternative composition-mediated fork.

This is an open specification question. A00 does not establish that machinery and nonresidential structures map one-to-one onto intensive and extensive accumulation.

## Estimation

FM-OLS is the main estimator. IM-OLS checks robustness. DOLS diagnoses fragility. Johansen/VECM is system-level robustness only.

No coefficient vector reaches productive-capacity reconstruction without cointegration admissibility, path review, explicit anchoring, and human promotion.

## Parked / not current baseline

The accumulated index $q_t^{\omega,h}$ remains a possible historical-memory operator. It is not the A00 baseline and should not govern current variable generation, coefficient promotion, or reconstruction.

HP-filter distribution gaps, non-interacted distribution-control models, ARDL short-run adjustment, and threshold models are not first-layer baseline devices.

## Locked formulation

$$
y_t
=
\alpha
+
\theta_0 k_t
+
\phi \tilde d_t
+
\theta_1(k_t\tilde d_t)
+
\varepsilon_t,
\qquad
\theta_t=\theta_0+\theta_1\tilde d_t.
$$

A00 identifies the distribution-conditioned capital-to-capacity elasticity. Productive capacity and utilization are reconstructed downstream under explicit anchoring.
