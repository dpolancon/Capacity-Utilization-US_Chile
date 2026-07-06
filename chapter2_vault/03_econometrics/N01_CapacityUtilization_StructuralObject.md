---
type: note
status: locked
layer: method
design_role: structural_object_definition
scope: chapter2_core_support
estimator_status: restricted-dols-required-for-nonlinear-baseline
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - M10_Empirical_Identification_Framework
  - N02_SuperConsistency
  - R01_residual_vs_structural_identification
priority: high
role: methodological-rationale
stage: pre-estimation-design
aliases:
  - Capacity utilization structural object
tags:
  - chapter2/econometrics
  - chapter2/methodological-rationale
  - chapter2/qomega-parked
updated_by: D12V2_OBSIDIAN_ECONOMETRICS_VAULT_ORGANIZATION
---

# Capacity Utilization as a Structural Object

> [!warning] q_omega parked
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path. See [[D12V_Restricted_DOLS_Active_Estimator_Lock]].


> [!gate] D12V2 gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.


> [!important] D12V2 status
> The active Chapter 2 baseline-design candidate is Restricted DOLS, not generic DOLS.
> Restricted DOLS keeps nonlinear/interacted terms in the long-run level equation and restricts dynamic corrections to admissible base-variable differences.
> See [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]].


> [!gate] D12V interaction-term gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.
> Restricted DOLS is preferred only after base-variable integration status, interaction-term status, and sample-window adequacy are classified.

> [!warning] q_omega remains parked
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path. See [[D12V_Restricted_DOLS_Active_Estimator_Lock]].

## Core claim

Capacity utilization is not directly observed and not identified by a residual. Observed output is effective-demand-realized output:

$$
y_t=y_t^p+\log\mu_t.
$$

Productive capacity $y_t^p$ is latent. The empirical problem is its structural reconstruction.

## Identification sequence

The first layer identifies the distribution-conditioned capital-to-capacity elasticity:

$$
\text{long-run coefficient vector}
\rightarrow
\hat\theta_t
\rightarrow
\hat y_t^p
\rightarrow
\text{level anchoring}
\rightarrow
\hat\mu_t.
$$

After anchoring:

$$
\widehat{\log\mu_t}=y_t-\hat y_t^p.
$$

The residual may diagnose the long-run relation. It does not identify the denominator of utilization.

## First-layer equation

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
\varepsilon_t,
$$

where:

$$
\theta_t=\theta_0+\theta_1\tilde d_t.
$$

The object is the interaction-implied elasticity, not $\phi$ and not a wage-led/profit-led demand response.

## Capital and anchoring rules

The capital variable must be restricted to productive-capacity capital before estimation. A coefficient vector disciplines the fitted path but does not fix its absolute capacity level. An explicit benchmark or pinch-year rule remains necessary.

Without level anchoring, utilization is underidentified.

## Methodological lock

**Capacity utilization is a level ratio between observed output and structurally reconstructed productive capacity. Identification must first recover and anchor $y_t^p$ before $\mu_t$ can be derived.**

## Parked / not current baseline

The accumulated $q_t^{\omega,h}$ index remains a possible historical-memory operator. It is not the current baseline identification object.
