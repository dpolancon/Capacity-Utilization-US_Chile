---
title: "A00: Aggregate Transformation Benchmark"
type: "note"
subtype: "object"
status: "active"
layer: "analytical_foundation"
design_role: "baseline_identification"
scope: "chapter2_core"
created: 2026-06-01
updated: 2026-06-08
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

A00 is the aggregate-capital benchmark. It keeps total real productive capital $K_t$ undifferentiated while allowing the transformation coefficient to vary with inherited distribution. The binding identification rule is [[R_distribution_conditioned_theta_identification]].

The theoretical object remains:

$$
\dot{y}_t^p
=
\theta_t\dot{k}_t.
$$

Distribution conditions the transformation of capital accumulation into productive-capacity growth:

$$
\theta_t
=
\theta_0
+
\theta_\omega m_{t-1}^{(h)}.
$$

$\theta_t$ is not estimated freely year by year. A fixed coefficient vector and a pre-specified observed memory state generate its historical path.

## 1. Aggregate capital object

The A00 capital object is:

$$
K_t
\equiv
K_t^{prod}.
$$

A00 does not separate $K^{ME}$ from $K^{NR}$. Component stocks may enter the measurement construction of aggregate capital, but they do not become separate A00 mechanisms. That decomposition belongs to A03.

## 2. Active econometric device

The accumulated distribution-conditioned capital-growth index is:

$$
q_t^{\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s.
$$

The benchmark long-run relation is:

$$
y_t^p
=
\alpha
+
\theta_0 k_t
+
\theta_\omega q_t^{\omega,h}
+
u_t.
$$

The implied transformation coefficient is:

$$
\theta_t
=
\theta_0
+
\theta_\omega m_{t-1}^{(h)}.
$$

The benchmark memory state is inherited distribution:

$$
m_{t-1}^{(1)}
=
\omega_{t-1}.
$$

The three-year and five-year moving averages are restricted robustness states. Exponential memory is optional only at the pre-specified values in the governing rule. The benchmark does not estimate unrestricted lag weights.

## 3. Why accumulation replaces the level interaction

The accumulated index converts a growth-rate theory into a level-compatible cointegrating object. Each period's capital growth is weighted by the distributional condition inherited when that accumulation is transformed into productive capacity.

This is superior to a contemporaneous level interaction because the theory concerns the capacity payoff of accumulation, not a multiplication between distribution and the inherited capital-stock level.

## 4. Superseded route

The former relation:

$$
y_t
=
c
+
\beta_1 k_t
+
\beta_2(\omega_t k_t)
+
\xi_t
$$

is rejected as the active benchmark. The $\omega_t k_t$ level interaction may remain in the vault only as a superseded historical specification. It must not define A00, generated implementation variables, coefficient promotion, or S40 reconstruction.

## 5. No full-sample centering

The benchmark uses the uncentered inherited-distribution state and the uncentered accumulated index. Full-sample centering is prohibited because it imports future sample information into earlier observations and changes the historical meaning of the accumulation path.

Any centered variant is diagnostic only and cannot replace the benchmark.

## 6. Productive-capacity and utilization sequence

The corrected identification sequence is:

$$
\left(k_t,q_t^{\omega,h}\right)
\rightarrow
\left(\hat{\theta}_0,\hat{\theta}_\omega\right)
\rightarrow
\hat{\theta}_t
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

Capacity utilization remains:

$$
\hat{\mu}_t
=
\frac{Y_t}{\hat{Y}_t^p}.
$$

The cointegrating residual is an admissibility and diagnostic object. It does not identify utilization.

## 7. Boundary with A03

A03 opens the aggregate A00 object into $K^{ME}$ and $K^{NR}$ channels. A00's accumulated index is the aggregate reduced-form counterpart of A03's growth-rate transformation logic. It does not substitute for the two-capital decomposition.

## 8. Estimation and promotion

The corrected variables must be generated and audited before estimation. FM-OLS is the main estimator, IM-OLS is the robustness estimator, and DOLS is the fragility/robustness check. Johansen/VECM remains system-level robustness and does not replace the single-equation benchmark.

No corrected coefficient object may enter S40 until S30/S32 human review explicitly promotes it under [[R_distribution_conditioned_theta_identification]].

## Locked formulation

A00 identifies a time-varying aggregate transformation coefficient through accumulated distribution-conditioned capital growth:

$$
y_t^p
=
\alpha
+
\theta_0 k_t
+
\theta_\omega q_t^{\omega,h}
+
u_t,
\qquad
\theta_t
=
\theta_0
+
\theta_\omega m_{t-1}^{(h)}.
$$

The benchmark uses inherited distribution, no full-sample centering, and a pre-specified memory state. The former $\omega_t k_t$ level interaction is superseded.
