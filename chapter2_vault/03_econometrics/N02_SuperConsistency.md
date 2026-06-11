---
type: note
status: active
layer: method
design_role: estimation_clarification
scope: chapter2_core_support
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - N01_CapacityUtilization_StructuralObject
  - R01_residual_vs_structural_identification
  - R02_DOLS_reconstruction_dilemma
  - R04_FMOLS_structural_preservation
  - R06_IMOLS_integration_ladder_reconstruction
  - R07_FGLS_threshold_cointegration_admissibility
  - R08_threshold_break_diagnostics_to_FGLS
  - M10_Empirical_Identification_Framework
priority: high
---

# Super-consistency and the reconstruction of $\mu_t$

## Core claim

Super-consistency may support recovery of the first-layer long-run coefficient vector. It does not establish that the reconstructed productive-capacity path or derived utilization series is correct.

**Coefficient consistency does not imply object consistency.**

## First-layer target

The target is the primitive interaction:

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

It is not $\mu_t$, an ECM coefficient, a short-run multiplier, or full VECM dynamics.

## Reconstruction boundary

$$
\text{coefficient recovery}
\rightarrow
\hat\theta_t
\rightarrow
\hat y_t^p
\rightarrow
\text{level anchoring}
\rightarrow
\hat\mu_t.
$$

Super-consistency applies to coefficient recovery. Every downstream object remains contingent on specification, productive-capital measurement, fitted-path reconstruction, and anchoring.

## Estimator hierarchy

- FM-OLS is the main log-level estimator.
- IM-OLS is the robustness check.
- DOLS is the fragility diagnostic.
- Johansen/VECM provides system-level robustness only.

## Regime boundary

Global first-layer estimation assumes a stable long-run relation. Threshold-FGLS becomes admissible only after integration order, deterministic components, structural breaks, nonlinear mean reversion, and threshold admissibility have been assessed.

Threshold-FGLS is not a general replacement for the first-layer estimator hierarchy.

## Parked / not current baseline

The accumulated $q_t^{\omega,h}$ index is a possible historical-memory operator. It is not the current baseline and should be tested only after the primitive interaction problem is clarified.

## Locked statement

**Super-consistency belongs to first-layer coefficient recovery. Productive capacity and utilization are reconstructed objects, not automatic implications of coefficient convergence.**
