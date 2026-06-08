---
type: note
status: active
layer: analytical_foundation
design_role: synthesis_hinge
scope: chapter2_core
related_to:
  - N04_Composition_of_Accumulation_and_Transformation
  - R03_Interpretation_of_Theta_as_Contradictory_Object
  - R04_What_is_Identified_vs_Reconstructed
created: 2026-05-05
---

# From machinery transformation to aggregate θ

## Core claim

The transformation elasticity is **machinery-specific at the structural level**, but **identified only as a composition-weighted aggregate** in the data.

$$
\theta_t^{tot} = s_t \theta_t^M + (1 - s_t)\theta^O
$$

The empirical model estimates the behavior of $$\theta^{tot}$$, from which the properties of $$\theta^M$$ are inferred.

---

## 1. Dual transformation structure

Productive capacity:

$$
Y_t^p = \theta_t^M K_t^M + \theta^O K_t^O
$$

with:

- $$\theta_t^M = \theta(\omega_t, \varphi_t, \mathcal{E}_t)$$  
- $$\theta^O$$ ≈ constant or slow-moving  

---

## 2. Aggregate representation

Define:

$$
K_t = K_t^M + K_t^O
$$

$$
s_t = \frac{K_t^M}{K_t}
$$

Then:

$$
Y_t^p = K_t \left[ s_t \theta_t^M + (1 - s_t)\theta^O \right]
$$

---

## 3. Observable transformation elasticity

Define:

$$
\theta_t^{tot} = s_t \theta_t^M + (1 - s_t)\theta^O
$$

so that:

$$
Y_t^p = \theta_t^{tot} K_t
$$

---

## 4. Structural vs empirical objects

- $$\theta^M$$ → structural object  
  - driven by mechanization and distributive conflict  
  - depends on $$\omega, \varphi, \mathcal{E}$$  
  - not directly estimated  

- $$\theta^{tot}$$ → identified object  
  - composition-weighted aggregate  
  - directly linked to observable output  

---

## 5. Mechanism decomposition

$$
\theta_t^{tot}
=
(1 - s_t)\theta^O
+
s_t \theta(\omega_t, \varphi_t, \mathcal{E}_t)
$$

Thus:

- $$s_t$$ governs the weight of the machinery channel  
- $$\omega_t$$ affects only $$\theta^M$$  
- $$\mathcal{E}_t$$ constrains only the machinery channel  

---

## 6. Empirical specification

Observed output:

$$
y_t = k_t + \ln \theta_t^{tot} + \ln \mu_t
$$

Approximate:

$$
y_t =
k_t
+
\beta_2 (s_t - \bar{s}) k_t
+
\beta_3 (\omega_t (s_t - \bar{s}) k_t)
+
\beta_4 (\mathcal{E}_t (s_t - \bar{s}) k_t)
+
\varepsilon_t
$$

where:

$$
\varepsilon_t = \ln \mu_t
$$

---

## 7. Mapping from coefficients to θ

The estimated coefficients describe the variation of $$\theta^{tot}$$:

$$
\ln \theta_t^{tot}
\approx
\beta_2 (s_t - \bar{s})
+
\beta_3 \omega_t (s_t - \bar{s})
+
\beta_4 \mathcal{E}_t (s_t - \bar{s})
$$

Thus:

- coefficients do not recover $$\theta^M$$ directly  
- they capture how $$\theta^{tot}$$ varies with composition and interaction terms  
- $$\theta^M$$ is inferred through its role in this variation  

---

## 8. Identification logic

$$
\theta^{tot}
$$
is identified because:
- $k_t$ captures capital scale  
- $s_t$ captures composition  
- $\omega_t$ and $\mathcal{E}_t$ shift only the machinery channel  

Thus:

> variation in output linked to composition and interaction terms cannot be explained by capital scale alone.

---

## 9. Role of infrastructure

Infrastructure enters in two ways:

1. Direct contribution:
   $$
   (1 - s_t)\theta^O
   $$

2. Productivity conditioning:
   $$
   a = a(q, K^O)
   $$

Thus:

- infrastructure contributes to capacity  
- it amplifies productivity  
- it does not transmit distributive conflict  

---

## 10. Interpretation

The model separates:

- **mechanism** → $\theta^M$ (conflict-driven transformation)  
- **measurement** → $\theta^{tot}$ (aggregate outcome)  

The empirical model estimates the second and interprets the first.

---

## Locked formulation

The empirical model identifies a composition-weighted transformation elasticity. The machinery-specific transformation elasticity is not directly estimated but inferred from how the aggregate transformation responds to composition, distribution, and external constraint. Infrastructure contributes to productive capacity both directly and by conditioning productivity, but does not participate in the conflict-driven transformation process. The distinction between structural and observable transformation elasticities is necessary to maintain consistency between theory and estimation.