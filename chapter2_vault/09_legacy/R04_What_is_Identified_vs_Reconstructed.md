---
type: note
status: active
layer: analytical_foundation
design_role: identification_rule
scope: chapter2_core
related_to:
  - H02_Theta_to_Empirical_Coefficients
  - N04_Composition_of_Accumulation_and_Transformation
  - R03_Interpretation_of_Theta_as_Contradictory_Object
created: 2026-05-05
---

# What is identified vs reconstructed

## Core rule

The empirical model does not directly estimate the structural transformation elasticity.

It estimates a reduced-form object from which the structural mechanism is interpreted.

---

## 1. Estimated objects

The model directly estimates:

$$
\beta_1,\ \beta_2,\ \beta_3,\ \beta_4
$$

These are coefficients of the reduced-form equation relating output to capital, composition, and interaction terms.

---

## 2. Identified object (empirical)

From the estimated coefficients, the model identifies:

$$
\theta_t^{tot}
$$

defined as:

$$
\theta_t^{tot} = s_t \theta_t^M + (1 - s_t)\theta^O
$$

This is the **composition-weighted transformation elasticity**.

It is the only transformation object directly supported by the data.

---

## 3. Reconstructed object (structural)

The structural transformation elasticity:

$$
\theta_t^M
$$

is not directly estimated.

It is **reconstructed conceptually** from:

- the functional dependence:
  $$
  \theta_t^M = \theta(\omega_t, \varphi_t, \mathcal{E}_t)
  $$
- and the interpretation of coefficients:
  $$
  \beta_2,\ \beta_3,\ \beta_4
  $$

Thus:

> $$\theta^M$$ is a theoretical object whose behavior is inferred, not measured.

---

## 4. Residual object

The error term:

$$
\varepsilon_t = \ln \mu_t
$$

captures capacity utilization.

Important:

- utilization is not estimated independently  
- it is obtained as the residual after reconstructing productive capacity  

---

## 5. Identification logic

The model identifies $\theta^{tot}$ because:

- $k_t$ captures capital scale  
- $s_t$ captures composition  
- $\omega_t$ and $\mathcal{E}_t$ affect only the machinery channel  

Thus:

> variation in output linked to composition and interaction terms cannot be attributed to capital scale alone.

---

## 6. Guardrail

Do not claim:

- that $\theta^M$ is directly estimated  
- that coefficients are structural elasticities  
- that utilization identifies transformation  

Instead:

- coefficients identify $\theta^{tot}$  
- $\theta^M$ is interpreted through the model structure  
- utilization is a residual object  

---
## Notation rule for θ

Unless explicitly indexed, $$\theta$$ denotes the aggregate transformation coefficient:

$$
\theta \equiv \theta^{tot}
$$

The machinery-specific transformation is denoted:

$$
\theta^M
$$

Indices are used only when decomposition across capital components is required.

## Locked formulation

The empirical model identifies a composition-weighted transformation elasticity. The machinery-specific transformation elasticity is not directly estimated, but inferred from the structure of the model and the behavior of the estimated coefficients. Capacity utilization is obtained as the residual after reconstructing productive capacity. The distinction between estimation, identification, and reconstruction is necessary for maintaining theoretical and empirical consistency.