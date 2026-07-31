---
type: theory
status: active
depends_on:
  - chapter2_vault/00_constitutive_core/01_Governing_Memo.md
stage_scope: S00
country: US_CL
last_updated: 2026-07-25
updated_by: CPR_IMOLS_ESTIMATION_PROTOCOL_LOCK
subtype: analytical_foundation
blocks: []
layer: theory
scope: chapter2
priority: reference
---

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
The baseline log-level cointegrating equation estimated via Integrated Modified OLS (IM-OLS CPR framework, per [[E10V_IMOLS_CPR_Active_Estimator_Lock]]) is:
$$
y_t = \alpha + b k_t + \psi \tau_t + f \omega_t + d (\tau_t \omega_{t-1}) + u_t
$$
where $k_t \equiv \ln K^{NRC}_t$ is the structural envelope scale and $\tau_t \equiv \ln K^{ME}_t - \ln K^{NRC}_t$ is the capital composition log difference. The partial sum IM-OLS transformation is:
$$
\sum_{s=1}^t y_s = \alpha \cdot t + b \sum_{s=1}^t k_s + \psi \sum_{s=1}^t \tau_s + f \sum_{s=1}^t \omega_s + d \sum_{s=1}^t (\tau_s \omega_{s-1}) + \lambda_k k_t + \lambda_\omega \omega_t + \varepsilon_t
$$
Centering follows the Three-Regime Architecture (see [[N11_Centering_Protocol_Three_Regime]]): Regime A (Uncentered main) and Regime B (Initial-state centering primary robustness). Pre-estimation diagnostic gating follows the 5-stage protocol in [[N12_PreTesting_Protocol_Integration_Breaks_ChoiceOfTechnique]], reconciling unit root orders, LOESS early-warning inflections, VECM drift leakage, and Okishio choice of technique. FWL pre-filtering of the interaction is strictly forbidden.

**Intercept Rule ($\alpha$):** The intercept absorbs base-year dimensional constants and the non-zero mean of $\ln \mu_t$. It is **strictly discarded** for structural capacity inference. Capacity reconstruction uses only super-consistent slopes.

## 2. Identification vs. Reconstruction
- **Identified Object:** Systematic part of $y_t$ (composition-weighted capacity trend)
- **Reconstructed Capacity:** 
$$
\hat{y}^p_t = \hat{b} k_t + \hat{\psi} \tau_t + \hat{f} \omega_t + \hat{d} (\tau_t \omega_{t-1})
$$
- **Utilization Gap:** $\ln \mu_t = y_t - \hat{y}^p_t$ (mean-zero cyclical deviation)

## 3. Level Anchoring Protocol
To recover the absolute historical level of $\mu_t$, pin the dimensionless gap to a verified benchmark year $t^*$ where central surveys or historical accounts indicate $\mu_{t^*} = \mu^*$ (e.g., 0.85):
$$
\mu_t = \mu^* \cdot \exp\left[ (y_t - \hat{y}^p_t) - (y_{t^*} - \hat{y}^p_{t^*}) \right]
$$

This bypasses the contaminated intercept and ensures dimensional homogeneity.

## 4. Mapping to Structural Payoffs
- $\beta_1 \to \theta^{NRC}$: Baseline capacity payoff of infrastructure (per [[A01_Extensive_Accumulation]])
- $\beta_2, \beta_3 \to \theta^{ME}(\pi, s)$: Distributively modulated payoff of machinery (per [[A02_Intensive_Accumulation]])
- Aggregate $\theta^N$ is composition-weighted per [[A03_TransformationElasticity_Two-CapitalCapacityComposition]]

## Locked Formulation
Estimation identifies the composition-weighted capacity trend; slopes reconstruct productive capacity structurally; utilization is derived as a pinned dimensionless gap. The intercept is never used for TFP or capacity definition. This protocol enforces the constitutional anti-residual rule.**