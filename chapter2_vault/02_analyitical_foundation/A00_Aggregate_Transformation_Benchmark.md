---
title: "A00: Aggregate Transformation Benchmark"
type: "note"
subtype: "object"
status: "active"
layer: "analytical_foundation"
design_role: "baseline_identification"
scope: "chapter2_core"
created: 2026-06-01
updated: 2026-06-01
related_to:
  - "A01_Extensive_Accumulation"
  - "A02_Intensive_Accumulation"
  - "A03_TransformationElasticity_Two-CapitalCapacityComposition"
  - "A04_PeripheralTransformationElasticity"
  - "N01_CapacityUtilization_StructuralObject"
  - "M10_Empirical_Identification_Framework"
  - "R04_FMOLS_structural_preservation"
---

# A00: Aggregate Transformation Benchmark

## Core Claim

A00 defines the baseline aggregate identification of the transformation elasticity. The capital stock remains undifferentiated as total real productive capital ($K_t$), but the transformation elasticity is time-varying because distribution conditions the capacity payoff of accumulation.

The locked formulation is:

$$
\text{aggregate } K_t,\quad \text{time-varying } \theta_t.
$$

A00 is therefore not a constant-$\theta$ benchmark. It is the aggregate-capital benchmark with a distributive interaction that makes the aggregate transformation elasticity time-varying.

---

## 1. Aggregate Capital Object

The A00 capital object is:

$$
K_t \equiv K_t^{prod},
$$

where $K_t^{prod}$ is the total real productive capital stock relevant for capacity formation.

A00 makes no distinction between:

$$
K^{ME}
\quad \text{and} \quad
K^{NRC}.
$$

Those component channels are not part of the A00 baseline. If component data are needed to construct a coherent aggregate real productive capital stock, they enter only as measurement inputs for $K_t$, not as separate explanatory mechanisms.

---

## 2. Baseline Econometric Object

The A00 baseline econometric specification is:

$$
y_t = c + \beta_1 k_t + \beta_2(\omega_t k_t) + \xi_t,
$$

where:

- $y_t$ is log output or the dimensionally admissible output index;
- $k_t$ is log aggregate real productive capital or the dimensionally admissible capital index;
- $\omega_t$ is the distributive wage-share condition;
- $\omega_t k_t$ is the baseline distributive interaction term;
- $\xi_t$ is the equation disturbance, not utilization.

The interaction term is not a secondary extension. It is the A00 econometric device that lets the aggregate transformation elasticity vary with distribution while capital remains aggregated.

The implied time-varying transformation elasticity is:

$$
\theta_t = \beta_1 + \beta_2\omega_t.
$$

---

## 3. Capacity Reconstruction

Once the A00 coefficient vector is recovered, the implied elasticity path enters productive-capacity reconstruction:

$$
\ln \hat{Y}_t^p
=
\ln Y_r^p
+
\sum_{\tau=r+1}^{t}
\theta_{\tau}\Delta \ln K_{\tau}.
$$

The reference level is fixed by an explicit anchor:

$$
Y_r^p = \frac{Y_r}{\mu_r}.
$$

If the anchor is normalized to full utilization, then:

$$
\mu_r = 1
\quad \Rightarrow \quad
Y_r^p = Y_r.
$$

---

## 4. Utilization Derivation

Capacity utilization is derived only after productive capacity has been reconstructed and level-anchored:

$$
\hat{\mu}_t
=
\frac{Y_t}{\hat{Y}_t^p}.
$$

The residual from the A00 relation does not identify utilization. Residuals may diagnose misspecification, instability, or deviations from the reconstructed path, but the object $\mu_t$ is a level ratio that requires the prior reconstruction of $\hat{Y}_t^p$.

---

## 5. Boundary with A03

A03 does not introduce time variation in $\theta_t$ for the first time. A00 already has a time-varying aggregate transformation elasticity:

$$
\theta_t = \beta_1 + \beta_2\omega_t.
$$

A03 opens that aggregate object into a two-capital composition mechanism involving:

$$
K^{ME},\quad K^{NRC},\quad s_t.
$$

Thus A03 is a decomposition and escalation note. It explains when the aggregate A00 elasticity must be decomposed into machinery, infrastructure, and composition-share channels. It does not replace the A00 aggregate interaction benchmark.

---

## 6. Boundary with A04

A04 becomes relevant when peripheral or external realization constraints contaminate the A00 relation. In that case, aggregate capital accumulation and the distributive interaction may no longer be sufficient to reconstruct productive capacity without modeling external bottlenecks, imported capital-goods constraints, or other realization limits.

---

## Locked Formulation

A00 defines the baseline aggregate identification of the transformation elasticity:

$$
y_t = c + \beta_1 k_t + \beta_2(\omega_t k_t) + \xi_t,
$$

which implies:

$$
\theta_t = \beta_1 + \beta_2\omega_t.
$$

The locked formulation is aggregate $K_t$, time-varying $\theta_t$. A03 opens the aggregate $\theta_t$ into two-capital composition channels; it does not introduce time variation for the first time.
