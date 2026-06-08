---
type: note
status: active
layer: superseded
design_role: synthesis_hinge
scope: chapter2_core
related_to:
  - N00_Mechanization_Analytical_References
  - N04_Composition_of_Accumulation_and_Transformation
  - R03_Interpretation_of_Theta_as_Contradictory_Object
  - R04_What_is_Identified_vs_Reconstructed
created: 2026-05-05
updated: 2026-05-27
---

# From machinery transformation to aggregate θ

## Core claim
The transformation elasticity is **machinery-specific at the structural level**, but **identified only as a composition-weighted aggregate** in the data. 

The empirical model estimates the behavior of $\theta^{tot}$, from which the properties of $\theta^M$ are inferred. The empirical coefficients are reduced-form summaries of distributive conditioning across two corridors.

---

## 1. Dual transformation structure
Productive capacity:
$$ Y_{tp} = \theta^M_t K^M_t + \theta^O K^O_t $$
with:
- $\theta^M_t = \theta(\omega_t, \varphi_t, E_t)$
- $\theta^O \approx$ constant or slow-moving

---

## 2. Aggregate representation
Define:
$$ K_t = K^M_t + K^O_t, \quad s_t = \frac{K^M_t}{K_t} $$
Then:
$$ Y_{tp} = K_t \left[ s_t \theta^M_t + (1 - s_t)\theta^O \right] $$

---

## 3. Observable transformation elasticity
Define:
$$ \theta^{tot}_t = s_t \theta^M_t + (1 - s_t)\theta^O $$
so that:
$$ Y_{tp} = \theta^{tot}_t K_t $$

---

## 4. Structural vs empirical objects
- **$\theta^M$** $\to$ structural object
  - driven by mechanization and distributive conflict
  - depends on $\omega, \varphi, E$
  - not directly estimated
- **$\theta^{tot}$** $\to$ identified object
  - composition-weighted aggregate
  - directly linked to observable output

---

## 5. Structural Disaggregation & The Two-Variable Optimization
To resolve the heterogeneity of capital and strictly adhere to dimensional analysis (Basu, 2022), the aggregate capital stock is partitioned into two functionally distinct variables:

1. **$K^{NRC}_t$ (Non-Residential Construction / Infrastructure):** Defines the **plant size** and structural envelope. It is a slow-moving state variable subject to long-term financial and structural constraints.
2. **$K^{ME}_t$ (Machinery & Equipment):** The **active decision variable** for mechanization. It is the margin where induced innovation occurs in response to distributive conflict ($\omega_t$) and external constraints ($E_t$).

### The Updated Closure
The smooth reproduction path (capacity growth) is no longer an aggregate relation $g_Y^p = \theta g_K$. Instead, it is driven by the accumulation of machinery, bounded by the infrastructural envelope:
$$ g_Y^p = \theta^{NRC} g_{K^{NRC}} + \theta^{ME}(\omega_t, E_t) g_{K^{ME}} $$
Where $\theta^{ME}$ is the variable transformation elasticity governed by the mechanization choice.

### Dimensionally Compliant Empirical Specification
Following Basu (2022), we define dimensionless log-indices relative to a structural base year $r$. Because $K^{NRC}$ and $K^{ME}$ have different units and deflators, each is normalized by its *own* reference unit:
*   $y_t = \ln(Y_t / Y_r)$
*   $k^{nrc}_t = \ln(K^{NRC}_t / K^{NRC}_r)$
*   $k^{me}_t = \ln(K^{ME}_t / K^{ME}_r)$

The estimable cointegrating equation (via FM-OLS) requires an intercept to absorb the non-zero mean of the structural residual ($\ln \mu_t$) and the base-year constants:
$$ y_t = \alpha_0 + \beta_1 k^{nrc}_t + \beta_2 k^{me}_t + \beta_3 (\omega_t \cdot k^{me}_t) + \beta_4 (E_t \cdot k^{me}_t) + \tilde{\mu}_t $$

### Mapping from Coefficients to Structural Mechanisms
The estimated slope coefficients directly recover the structural parameters of the two-variable optimization. **The intercept ($\alpha_0$) is strictly discarded for structural inference** per the Anti-Residual Ontology protocol.
*   **$\beta_1$ (Structural Envelope):** Elasticity of output with respect to plant size ($K^{NRC}$). Represents the baseline structural capacity.
*   **$\beta_2$ (Direct Machinery Payoff):** Direct elasticity of output with respect to machinery ($K^{ME}$).
*   **$\beta_3$ (Distributive Conditioning):** Captures the induced innovation response (Marx/Okishio/Cajas). It measures how wage pressure ($\omega_t$) alters the productivity payoff of the machinery stock.
*   **$\beta_4$ (Peripheral Constraint):** Captures the external wedge (Prebisch/Thirlwall). Since $K^{ME}$ is typically imported, the external constraint ($E_t$) directly conditions its capacity payoff.

### Capacity Reconstruction & Utilization Extraction
Productive capacity is reconstructed structurally using *only* the super-consistent slopes, entirely bypassing the contaminated intercept $\alpha_0$:
$$ \hat{y}_{tp, t} = \hat{\beta}_1 k^{nrc}_t + \hat{\beta}_2 k^{me}_t + \hat{\beta}_3 (\omega_t \cdot k^{me}_t) + \hat{\beta}_4 (E_t \cdot k^{me}_t) $$
Utilization is then derived as the dimensionless gap, and subsequently pinned to reality via the **Level Anchoring** protocol (e.g., assigning a known historical benchmark to a specific year):
$$ \ln \mu_t = y_t - \hat{y}_{tp, t} \implies \hat \mu_t = \text{Anchor} \times \exp(y_t - \hat{y}_{tp, t}) $$
### Capacity Reconstruction & Utilization Extraction
Productive capacity is reconstructed structurally, not extracted as a residual:
$$ \hat{y}_{tp, t} = \hat{\beta}_1 k^{nrc}_t + \hat{\beta}_2 k^{me}_t + \hat{\beta}_3 (\omega_t \cdot k^{me}_t) + \hat{\beta}_4 (E_t \cdot k^{me}_t) $$
Utilization is then derived as the dimensionless gap, later anchored to a historical benchmark:
$$ \ln \mu_t = y_t - \hat{y}_{tp, t} \implies \mu_t = \exp(y_t - \hat{y}_{tp, t}) $$
---

## 6. Peripheral Mechanization Constraint
Infrastructure and external constraints enter in two ways:
1. Direct contribution: $(1 - s_t)\theta^O$
2. Productivity conditioning: $a = a(q, K^O)$

**Grounding:** Kaldor (Chile), Prebisch, Thirlwall. Mechanization depends on foreign exchange. In the periphery, accumulation $\neq$ mechanization. $E_t$ constrains only the machinery channel.

---

## 7. Identification logic
$\theta^{tot}$ is identified because:
- $k_t$ captures capital scale
- $s_t$ captures composition
- $\omega_t$ and $E_t$ shift only the machinery channel

Thus:
> variation in output linked to composition and interaction terms cannot be explained by capital scale alone.

*Note: The residual $\varepsilon_t = \ln \mu_t$ is strictly utilization, not a misspecified capacity term. Capacity is reconstructed via $\theta^{tot}$, not extracted from the residual.*

---

## 8. Regime Shifts & Thresholds
Transformation elasticity is not globally stable. Regimes define corridor dominance.
**Grounding:** Basu (closure-dependent outcomes) and Regulation theory (regime shifts). Threshold models (FGLS) are gated by structural break diagnostics to capture these shifts in corridor dominance.

---

## Locked formulation
The empirical model identifies a composition-weighted transformation elasticity. The machinery-specific transformation elasticity is not directly estimated but inferred from how the aggregate transformation responds to composition, distribution, and external constraint. The empirical coefficients ($\beta_2$) are reduced-form summaries of distributive conditioning across two corridors. Infrastructure contributes to productive capacity both directly and by conditioning productivity, but does not participate in the conflict-driven transformation process. The distinction between structural and observable transformation elasticities is necessary to maintain consistency between theory and estimation, and regime shifts dictate the stability of these elasticities.