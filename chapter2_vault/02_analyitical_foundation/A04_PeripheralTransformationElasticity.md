---
type: note
subtype: object
status: active
layer: analytical_foundation
design_role: mechanism_definition
scope: chapter2_core
related_to:
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - N00_Mechanization_Analytical_References
  - N02_Peripheral_Mechanization_Constraint
  - R06_Regime_Gating_and_Diagnostic_Ladder
  - R05_Frontier_of_Not_Becoming
created: 2026-05-27
---

# A04: Peripheral Transformation Elasticity and FX-Constrained Profit Realization

## Core Claim
In the capitalist periphery, the transformation elasticity $\theta^N$ is not solely determined by domestic distributive conflict and infrastructural envelope. It is structurally conditioned by foreign exchange (FX) availability and Balance of Payments (BoP) dynamics. 

Because $K^{ME}$ accumulation and maintenance require imported capital goods, spare parts, and complementary intermediates, FX scarcity generates a **realization bottleneck**. When the BoP constraint binds, the *effective profit share* available for reinvestment is squeezed—not because surplus value is not produced, but because it cannot be converted into imported reinvestment goods. This truncates the capacity payoff of machinery accumulation and generates a regime-dependent peripheral transformation elasticity.

---

## 1. The FX-Conversion Bottleneck
The intensive margin's optimal mechanization rate $q^*(\omega)$ requires the continuous deployment and maintenance of $K^{ME}$. In peripheral economies, a significant fraction of these inputs are technologically non-substitutable domestically:
$$ i^{ME}_t = i^{ME, \text{dom}}_t + i^{ME, \text{imp}}_t $$
Realized accumulation depends on the ability to convert accounting surplus into imported reinvestment flows. Let $F^{avail}_t$ denote available foreign exchange (exports, net capital inflows, reserves net of debt service). The reinvestment requirement for the intensive margin is:
$$ F^{req}_t = \mu_{imp} \cdot P^{ME, imp}_t \cdot i^{ME}_t $$
where $\mu_{imp} \in (0,1]$ is the import intensity of machinery investment/maintenance.

**Structural Contradiction:** Domestic class conflict ($\omega$) and profitability ($\pi = 1-\omega$) determine the *nominal* surplus available for accumulation. However, the *realized* reinvestment capacity is gated by the FX-conversion ratio:
$$ \phi_t = \min\left(1, \frac{F^{avail}_t}{F^{req}_t}\right) $$
When $F^{avail}_t \geq F^{req}_t$, $\phi_t = 1$ (slack regime). When $F^{avail}_t < F^{req}_t$, $\phi_t < 1$ (binding regime). The gap $1 - \phi_t$ represents **blocked surplus**: accounting profits that cannot be materialized as productive reinvestment.

---

## 2. Effective Profit Share Squeeze
Let $\pi_t = 1 - \omega_t$ be the nominal profit share. The **effective profit share** available for reinvestment is:
$$ \pi^{eff}_t = \pi_t \cdot \phi_t $$
The effective profit share is squeezed whenever $\phi_t < 1$, even if $\omega_t$ remains constant. This is not a distributional squeeze; it is a **structural realization failure** imposed by external payment constraints.

The intensive-margin accumulation rate responds to $\pi^{eff}$, not $\pi$:
$$ g_{K^{ME}, t} = \chi^{ME} \pi^{eff}_t - \delta^{ME} = \chi^{ME} \pi_t \phi_t - \delta^{ME} $$
**Analytical Implication:** When the BoP binds, the mechanization budget constraint tightens endogenously. The induced innovation logic $q^*(\omega)$ is truncated not by wage pressure, but by the inability to convert surplus into imported machinery. The economy experiences a *peripheral accumulation wedge* where high nominal profitability coexists with low realized capacity formation.

---

## 3. Regime-Dependent Peripheral Transformation Elasticity
The capacity payoff of machinery accumulation ($\theta^{ME}$) is now a function of $\pi^{eff}$ rather than just $\omega$ and $s$. 

Define two external regimes:
- **Regime $E_A$ (FX Abundant / BoP Slack):** $\phi_t = 1 \implies \pi^{eff} = \pi$. The transformation elasticity operates at its smooth-reproduction benchmark:
  $$ \theta^{ME}_{periph} = \theta^{ME}(\omega, s) $$
- **Regime $E_B$ (FX Scarce / BoP Binding):** $\phi_t < 1 \implies \pi^{eff} < \pi$. The realized transformation elasticity becomes:
  $$ \theta^{ME}_{periph} = \theta^{ME}(\pi^{eff}, s) \cdot \kappa(\phi_t) $$
  where $\kappa(\phi_t) \in (0,1]$ is a **peripheral efficiency penalty** capturing vintage mismatch, maintenance backlogs, and idle capacity when imported spare parts/complements are rationed.

The aggregate peripheral transformation elasticity aggregates the unconstrained extensive margin and the FX-constrained intensive margin:
$$ \theta^N_{periph} = \frac{\theta^{NRC}(1-s) g_{K^{NRC}} + \theta^{ME}_{periph} \cdot s \cdot (\chi^{ME} \pi^{eff} - \delta^{ME})}{(1-s) g_{K^{NRC}} + s \cdot (\chi^{ME} \pi^{eff} - \delta^{ME})} $$

**Key Properties:**
1. **Non-Distributional Squeeze:** The decline in $\theta^N_{periph}$ under binding BoP is driven by $\phi_t \downarrow \implies \pi^{eff} \downarrow$, not by changes in $\omega$. Distributional conflict and external realization are analytically separated.
2. **Threshold Kink:** The transition $E_A \to E_B$ is discrete. When $F^{avail}_t$ crosses $F^{req}_t$, $\phi_t$ drops below 1, causing a sudden contraction in $\pi^{eff}$ and a downward jump in $\theta^{ME}_{periph}$. This creates a kinked, regime-dependent transformation curve.
3. **Accumulation Paradox:** Rising $\omega$ may theoretically push $q^*$ upward, but if $\phi_t < 1$, the squeezed $\pi^{eff}$ mechanically caps $g_{K^{ME}}$, preventing the induced innovation response from materializing in real capacity.

---

## 4. Contradictory Dynamics & Ontological Status
1. **Historical "Becoming" in the Periphery:** The gap $\pi - \pi^{eff}$ measures the **structural realization loss** due to FX scarcity. $\theta^N_{periph}$ is the empirical realization of Okishio's market anarchy intersecting with Prebisch/Thirlwall's external constraint.
2. **Not a Marginal Friction:** The BoP constraint does not act as a tax or continuous friction on the FOC. It operates as a **regime gate** on profit realization and reinvestment capacity. This preserves the analytical purity of the induced innovation mechanism while acknowledging that its realization is structurally truncated by macro-external limits.
3. **Empirical Mapping:** In the Basu-compliant cointegration framework, this corresponds to regime-dependent slope shifts in the capacity reconstruction vector. Threshold diagnostics must gate breaks on external indicators (current account balance, FX reserves, terms of trade) alongside domestic closure conditions (`R06` & `R07`). The empirical interaction term ($\omega_t \cdot c_t$) will exhibit sign instability or attenuation precisely when $\phi_t$ drops, signaling the transition from distributive to realization-gated accumulation.

---

## Locked Formulation
The peripheral transformation elasticity $\theta^N_{periph}$ captures the structural contradiction between domestic surplus generation and external payment realization. Because $K^{ME}$ accumulation is import-dependent, FX scarcity acts as a hard ceiling on the conversion of accounting profits into reinvestment flows. When the BoP binds, the effective profit share ($\pi^{eff} = \pi \cdot \phi$) is squeezed, truncating the capacity payoff of machinery accumulation independently of distributive conflict. This generates a regime-dependent, kinked transformation elasticity that deviates systematically from the smooth-reproduction benchmark. The constraint operates as an external realization gate, producing a contradictory accumulation dynamic where nominal profitability is structurally decoupled from realized capacity formation.