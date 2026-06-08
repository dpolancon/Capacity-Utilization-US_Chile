**---
type: note
subtype: rule
status: active
layer: analytical_foundation
design_role: identification_protocol
scope: chapter2_core
related_to:
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - H01_Cajas_to_Transformation_Elasticity
created: 2026-05-27
---

# R02: Identification and Estimation Protocol

## Core Rule
Capacity is **structurally reconstructed**, never residually extracted. The empirical model identifies a composition-weighted aggregate; structural payoffs ($\theta^{NRC}$, $\theta^{ME}$) are inferred via mapping rules, not directly estimated.

## 1. Estimable Specification
The standard log-level cointegrating equation (via FM-OLS) is:
$$
\ln Y_t = \alpha_0 + \beta_1 \ln K^{NRC}_t + \beta_2 \ln K^{ME}_t + \beta_3 (\omega_t \cdot \ln K^{ME}_t) + \tilde{\mu}_t
$$

**Intercept Rule ($\alpha_0$):** The intercept absorbs base-year dimensional constants and the non-zero mean of $\ln \mu_t$. It is **strictly discarded** for structural inference. Capacity reconstruction uses only super-consistent slopes.

## 2. Identification vs. Reconstruction
- **Identified Object:** Systematic part of $\ln Y_t$ (composition-weighted capacity trend)
- **Reconstructed Capacity:** 
$$
\ln \hat{Y}^p_t = \hat{\beta}_1 \ln K^{NRC}_t + \hat{\beta}_2 \ln K^{ME}_t + \hat{\beta}_3 (\omega_t \cdot \ln K^{ME}_t)
$$
- **Utilization Gap:** $\ln \mu_t = \ln Y_t - \ln \hat{Y}^p_t$ (mean-zero cyclical deviation)

## 3. Level Anchoring Protocol
To recover the absolute historical level of $\mu_t$, pin the dimensionless gap to a verified benchmark year $t^*$ where central surveys or historical accounts indicate $\mu_{t^*} = \mu^*$ (e.g., 0.85):
$$
\mu_t = \mu^* \cdot \exp\left[ (\ln Y_t - \ln \hat{Y}^p_t) - (\ln Y_{t^*} - \ln \hat{Y}^p_{t^*}) \right]
$$

This bypasses the contaminated intercept and ensures dimensional homogeneity.

## 4. Mapping to Structural Payoffs
- $\beta_1 \to \theta^{NRC}$: Baseline capacity payoff of infrastructure (per [[A01_Extensive_Accumulation]])
- $\beta_2, \beta_3 \to \theta^{ME}(\pi, s)$: Distributively modulated payoff of machinery (per [[A02_Intensive_Accumulation]])
- Aggregate $\theta^N$ is composition-weighted per [[A03_TransformationElasticity_Two-CapitalCapacityComposition]]

## Locked Formulation
Estimation identifies the composition-weighted capacity trend; slopes reconstruct productive capacity structurally; utilization is derived as a pinned dimensionless gap. The intercept is never used for TFP or capacity definition. This protocol enforces the constitutional anti-residual rule.**