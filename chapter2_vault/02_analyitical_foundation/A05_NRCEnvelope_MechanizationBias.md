---
type: note
subtype: object
status: active_pending_human_review
layer: analytical_foundation
design_role: empirical_bridge_definition
scope: chapter2_core
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - A01_Extensive_Accumulation
  - A02_Intensive_Accumulation
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - D01_GPIM_heterogeneous_capital_SFC
  - D02_PriceDeflator_Protocol_K_Composition
  - D04_ME_NRC_LogRatio_Construction_Protocol
  - R10_Binding_Specification_Layering_Rule
pending_tasks:
  - Define the productive-capital scale boundary.
  - Construct and audit the centered ME-to-NR composition term.
  - Compare direct scale-conditioning with composition-mediated conditioning.
  - Keep reconstruction blocked until explicit human promotion.
created: 2026-06-02
updated: 2026-06-11
---

# A05: Productive-Capital Scale and Composition Fork

## Core claim

A05 operationalizes the open specification fork in [[R_distribution_conditioned_theta_identification]]. It does not lock an additive productive-capital conclusion or a one-to-one assignment of machinery and nonresidential structures to intensive and extensive accumulation.

The question is whether distribution conditions the capital-to-capacity mapping directly through productive-capital scale or indirectly through productive-capital composition.

## Productive-capital boundary

Before either specification is estimated, the baseline capital object must be restricted to assets that build productive capacity:

$$
K_t^{prod}.
$$

IPP, financial-circulation fixed assets, government transport, and similar assets remain conditioners, diagnostics, or robustness objects unless separately justified as productive-capacity capital.

## Specification A: direct scale-conditioning

$$
y_t
=
\alpha
+
\theta_0\tilde k_t^{scale}
+
\phi\tilde d_t
+
\theta_1(\tilde k_t^{scale}\tilde d_t)
+
\varepsilon_t.
$$

The identified elasticity is:

$$
\theta_t=\theta_0+\theta_1\tilde d_t.
$$

## Specification B: composition-mediated conditioning

Define the centered composition term:

$$
\tilde\tau_t
=
\left(\ln K_t^{ME}-\ln K_t^{NR}\right)
-
\overline{\left(\ln K^{ME}-\ln K^{NR}\right)}.
$$

The candidate equation is:

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

The composition response is:

$$
\frac{\partial\hat y_t^p}{\partial\tilde\tau_t}
=
\psi+\lambda\tilde d_t.
$$

This tests whether distribution acts through technique or composition rather than directly through scale.

## Interpretation guardrails

- $\phi$ is a nuisance control, not wage-led/profit-led evidence.
- The interaction-implied elasticity is the object of interpretation.
- $K^{ME}$ and $K^{NR}$ are measured capital components; their structural roles remain an empirical specification question.
- Demand-composition variables do not enter either first-layer capacity equation as direct capacity builders.

## Estimation and promotion

FM-OLS is the main estimator, IM-OLS is the robustness check, and DOLS is the fragility diagnostic. Cointegration admissibility and estimator-family comparison precede reconstruction.

Neither specification authorizes productive-capacity reconstruction or utilization derivation until human review promotes a coefficient vector and an explicit level anchor is registered.

## Parked / not current baseline

The accumulated $q_t^{\omega,h}$ and $q_t^{ME,\omega,h}$ indexes remain possible historical-memory operators. The former $\omega_t m_t$ and $\omega_t k_t^{ME}$ equations remain historical comparison specifications. None is the current baseline.

## Locked formulation

A05 keeps direct scale-conditioning and composition-mediated conditioning as competing first-layer specifications. It does not presume that additive component stocks or a fixed intensive/extensive mapping have already been established.
