---
type: note
subtype: hinge
status: superseded
layer: analytical_foundation
design_role: mechanism_definition
scope: chapter2_core
related_to:
  - H01_Cajas_to_Transformation_Elasticity
  - H02_Theta_to_Empirical_Coefficients
  - N00_Mechanization_Analytical_References
  - R05_Frontier_of_Not_Becoming
created: 2026-05-27
updated: 2026-05-27
---

# H03: Double Choice of Technique and Plant Capacity

## Core Claim
The aggregate production structure is not governed by a single, monolithic optimization over a homogeneous capital stock. It is governed by a **Double Choice of Technique** that strictly separates the extensive margin (plant capacity/infrastructure) from the intensive margin (mechanization/distributive conflict).

This separation provides the exact analytical and mathematical justification for the interaction terms in the Basu-compliant empirical model, isolating the mechanism of induced innovation.

---

## 1. The Two Forms of Capital
To resolve the heterogeneity of capital and map it to distinct temporalities of accumulation, the capital stock is partitioned into two functionally distinct variables:

1. **$K^{NRC}$ (Non-Residential Construction / Infrastructure):** 
   - Defines the **structural envelope** or Plant Capacity ($Y_{tp}$).
   - Lumpy, irreversible, slow-moving, and subject to long-term financial constraints.
   - Sets the *extensive* limit of production.
2. **$K^{ME}$ (Machinery & Equipment):** 
   - Defines the **technique of production** (mechanization $q = K^{ME}/L$).
   - Continuous, tactical, subject to scrapping and depreciation.
   - Represents the *intensive* margin and the active response to class conflict.

---

## 2. Stage 1: The Strategic Choice (The Envelope)
The firm (or the decentralized aggregate) commits to a plant size $K^{NRC}$ based on long-run expected demand and structural conditions. This establishes the **Plant Capacity** envelope:
$$ Y_{tp} = \Gamma(K^{NRC}) $$
This represents the structural limit of "not becoming"—the maximum physical scale of the economy before tactical mechanization decisions are even considered.

---

## 3. Stage 2: The Tactical Choice (Induced Mechanization)
Given the structural envelope $K^{NRC}$, the firm chooses the technique of production to minimize unit costs. 
Let labor productivity be $a = Y/L$ and mechanization be $q = K^{ME}/L$. The technological frontier is strictly conditioned by the plant size:
$$ a = \Phi(q; K^{NRC}) $$
*(Properties: $\Phi_q > 0, \Phi_{qq} < 0, \Phi_{K^{NRC}} > 0, \Phi_{q, K^{NRC}} > 0$. A larger/better infrastructure increases both the ceiling and the marginal productivity of machinery).*

**The Optimization Problem:**
The firm minimizes unit cost $c$, where $w$ is the wage rate and $\rho$ is the user cost of machinery:
$$ \min_{q} \ c(q) = \frac{w + \rho q}{\Phi(q; K^{NRC})} $$

**The First-Order Condition (Induced Innovation):**
Taking the derivative with respect to $q$ and setting it to zero yields:
$$ \frac{\Phi_q \cdot q}{\Phi} = \frac{\rho q}{w + \rho q} \implies \epsilon_{a,q}(q^*; K^{NRC}) = \sigma_{me}(\omega) $$
Where:
- $\epsilon_{a,q}$ is the elasticity of labor productivity with respect to mechanization.
- $\sigma_{me}$ is the share of machinery costs in total operating costs, which is inversely related to the wage share ($\omega$).

**The Mechanism:**
A rise in distributive pressure ($\omega \uparrow$) increases the relative cost of labor, forcing the firm to choose a higher level of mechanization ($q^* \uparrow$) to restore profitability. The optimal technique is therefore a function of both the structural envelope and distributive conflict:
$$ q^* = q(\omega, K^{NRC}) $$

---

## 4. Empirical Mapping (Basu-Compliant FM-OLS)
To strictly adhere to dimensional analysis (Basu, 2022), we define dimensionless log-indices relative to a structural base year $r$. Because $K^{NRC}$ and $K^{ME}$ have different units and deflators, each is normalized by its *own* reference unit:
*   $y_t = \ln(Y_t / Y_r)$
*   $k^{nrc}_t = \ln(K^{NRC}_t / K^{NRC}_r)$
*   $k^{me}_t = \ln(K^{ME}_t / K^{ME}_r)$

The estimable cointegrating equation (via FM-OLS) requires an intercept ($\alpha_0$) to absorb the non-zero mean of the structural residual ($\ln \mu_t$) and the base-year constants:
$$ y_t = \alpha_0 + \beta_1 k^{nrc}_t + \beta_2 k^{me}_t + \beta_3 (\omega_t \cdot k^{me}_t) + \tilde{\mu}_t $$

**Mapping from Coefficients to Structural Mechanisms:**
The estimated slope coefficients directly recover the structural parameters of the double choice. **The intercept ($\alpha_0$) is strictly discarded for structural inference** per the Anti-Residual Ontology protocol.
*   **$\beta_1$ (Stage 1 - Envelope):** Elasticity of output with respect to plant size ($K^{NRC}$). Captures the expansion of the structural baseline.
*   **$\beta_2$ (Stage 2 - Direct Payoff):** Direct elasticity of output with respect to machinery ($K^{ME}$).
*   **$\beta_3$ (Stage 2 - Distributive Conditioning):** Captures the *induced* component of machinery. It is the empirical shadow of the FOC $\epsilon_{a,q} = \sigma_{me}(\omega)$. It measures how the productivity payoff of the machinery stock is amplified by distributive pressure.

---

## 5. Capacity Reconstruction & Utilization Extraction
Productive capacity is reconstructed structurally using *only* the super-consistent slopes, entirely bypassing the contaminated intercept $\alpha_0$:
$$ \hat{y}_{tp, t} = \hat{\beta}_1 k^{nrc}_t + \hat{\beta}_2 k^{me}_t + \hat{\beta}_3 (\omega_t \cdot k^{me}_t) $$
Utilization is then derived as the dimensionless gap, and subsequently pinned to reality via the **Level Anchoring** protocol:
$$ \ln \mu_t = y_t - \hat{y}_{tp, t} \implies \mu_t = \text{Anchor} \times \exp(y_t - \hat{y}_{tp, t}) $$

---

## 6. Ontological Status (Okishio-Vidal Bridge)
The systematic part of the equation ($\hat{y}_{tp, t}$) estimates the historical average of the shifting **"not becoming"** frontier (the Cajas limit). It captures how the boundary of smooth reproduction shifts when distribution ($\omega$) changes.

The residual ($\tilde{\mu}_t$) is the empirical fingerprint of **"becoming"** (Okishio's market anarchy and Vidal's internal firm friction). The fact that $\tilde{\mu}_t$ fluctuates is the mathematical proof that the economy traces a "scarred" historical path strictly inside or disjointed from the pure optimization frontier.

---

## Locked Formulation
Productive capacity is bounded by a Double Choice of Technique. The extensive margin ($K^{NRC}$) defines the structural envelope (Plant Capacity), while the intensive margin ($K^{ME}$) represents the tactical, conflict-driven choice of mechanization. Distributive pressures ($\omega$) do not shift an aggregate production function; they shift the optimal choice of technique along a frontier conditioned by infrastructure. The empirical interaction term ($\omega \cdot k^{me}$) is the direct mathematical realization of this induced innovation mechanism, estimated via dimensionally compliant log-indices.