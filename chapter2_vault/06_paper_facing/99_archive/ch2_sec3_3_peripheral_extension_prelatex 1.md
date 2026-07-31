---
type: paper_facing
status: draft
country: US_CL
stage_scope: N/A
last_updated: '2026-07-29'
depends_on: []
blocks: []
layer: design
scope: chapter2
priority: context
---

# Section 3.3: Peripheral Extension: Foreign Strain and Financial Subordination

In the capitalist periphery, the choice of technique and the transformation elasticity $\theta^N$ are not solely determined by domestic distributive conflict and the infrastructural envelope. They are structurally conditioned by foreign exchange (FX) availability, financial subordination, and Balance of Payments (BoP) constraints. 

Because machinery ($K^{ME}$) accumulation and maintenance require imported capital goods, spare parts, and technology, FX scarcity generates a **realization bottleneck**. When the BoP constraint binds, the *effective profit share* available for reinvestment is squeezed—not because domestic surplus value is not produced, but because it cannot be converted into imported reinvestment goods. This truncates the capacity payoff of machinery accumulation and generates a regime-dependent peripheral transformation elasticity.

## 3.3.1 The Foreign-Exchange Conversion Bottleneck

The intensive margin's optimal mechanization rate $q^*(\omega)$ requires the continuous deployment and maintenance of $K^{ME}$. In peripheral economies (such as Chile), a significant fraction of these inputs are technologically non-substitutable domestically:

$$ i^{ME}_t = i^{ME, \text{dom}}_t + i^{ME, \text{imp}}_t $$

Realized accumulation depends on the ability to convert accounting surplus into imported reinvestment flows. Let $F^{\text{avail}}_t$ denote available foreign exchange (exports, net capital inflows, reserves net of debt service). The reinvestment requirement for the intensive margin is:

$$ F^{\text{req}}_t = \mu_{\text{imp}} \cdot P^{ME, \text{imp}}_t \cdot i^{ME}_t $$

where $\mu_{\text{imp}} \in (0,1]$ is the import intensity of machinery investment and maintenance.

Domestic class conflict ($\omega$) and nominal profitability ($\pi = 1-\omega$) determine the *nominal* surplus available for accumulation. However, the *realized* reinvestment capacity is gated by the FX-conversion ratio:

$$ \phi_t = \min\left(1, \frac{F^{\text{avail}}_t}{F^{\text{req}}_t}\right) $$

When $F^{\text{avail}}_t \geq F^{\text{req}}_t$, $\phi_t = 1$ (slack FX regime). When $F^{\text{avail}}_t < F^{\text{req}}_t$, $\phi_t < 1$ (binding FX regime). The gap $1 - \phi_t$ represents **blocked surplus**: accounting profits that cannot be materialized as productive reinvestment due to structural balance-of-payments constraints and financial subordination.

## 3.3.2 Effective Profit Share Squeeze and Truncated Accumulation

Let $\pi_t = 1 - \omega_t$ be the nominal profit share. The **effective profit share** available for reinvestment in the periphery is:

$$ \pi^{\text{eff}}_t = \pi_t \cdot \phi_t = (1 - \omega_t) \cdot \phi_t $$

The effective profit share is squeezed whenever $\phi_t < 1$, even if the domestic wage share $\omega_t$ remains constant or falls. This is not a domestic distributional squeeze; it is a **structural realization failure** imposed by external payment constraints and peripheral financial subordination.

The intensive-margin accumulation rate responds directly to $\pi^{\text{eff}}$, not $\pi$:

$$ g_{K^{ME}, t} = \chi^{ME} \pi^{\text{eff}}_t - \delta^{ME} = \chi^{ME} (1-\omega_t) \phi_t - \delta^{ME} $$

When the BoP binds ($\phi_t < 1$), the mechanization budget constraint tightens endogenously. The induced innovation logic $q^*(\omega)$ is truncated not by domestic wage pressure, but by the inability to convert accounting surplus into imported machinery. The economy experiences a *peripheral accumulation wedge* where high nominal profitability coexists with low realized capacity formation.

## 3.3.3 Regime-Dependent Peripheral Transformation Elasticity

The capacity payoff of machinery accumulation ($\theta^{ME}$) becomes a function of $\pi^{\text{eff}}$ rather than just $\omega$ and $s$. We define two structural external regimes:

- **Regime $E_A$ (FX Abundant / BoP Slack):** $\phi_t = 1 \implies \pi^{\text{eff}} = \pi$. The transformation elasticity operates at its smooth-reproduction benchmark:
  $$ \theta^{ME}_{\text{periph}} = \theta^{ME}(\omega, s) $$

- **Regime $E_B$ (FX Scarce / BoP Binding):** $\phi_t < 1 \implies \pi^{\text{eff}} < \pi$. The realized transformation elasticity becomes:
  $$ \theta^{ME}_{\text{periph}} = \theta^{ME}(\pi^{\text{eff}}, s) \cdot \kappa(\phi_t) $$
  where $\kappa(\phi_t) \in (0,1]$ is a **peripheral efficiency penalty** capturing vintage mismatch, maintenance backlogs, and idle capacity when imported spare parts and complementary inputs are rationed.

The aggregate peripheral transformation elasticity aggregates the unconstrained extensive margin and the FX-constrained intensive margin:

$$ \theta^N_{\text{periph}} = \frac{\theta^{NRC}(1-s) g_{K^{NRC}} + \theta^{ME}_{\text{periph}} \cdot s \cdot (\chi^{ME} \pi^{\text{eff}} - \delta^{ME})}{(1-s) g_{K^{NRC}} + s \cdot (\chi^{ME} \pi^{\text{eff}} - \delta^{ME})} $$

## 3.3.4 External Mechanization Wedge and Financial Subordination

For peripheral economies, the machinery share of accumulation is further mediated by the external mechanization wedge:

$$ \mathcal{E}_t = \Lambda_t \varphi_t $$

where $\varphi_t = \frac{I_t^{ME}}{I_t^{ME} + I_t^{NRC}}$ is the real machinery accumulation share, and $\Lambda_t$ captures structural foreign-exchange leverage and debt-service strain. 

Under peripheral neoliberalism, foreign financial subordination alters the accumulation circuit. High real interest rates, capital flight, and volatile terms of trade periodically trigger regime shifts ($E_A \to E_B$). When $F^{\text{avail}}_t$ drops below $F^{\text{req}}_t$, $\phi_t$ falls below 1, causing a sudden contraction in $\pi^{\text{eff}}$ and a downward jump in $\theta^{ME}_{\text{periph}}$. 

This creates a **kinked, regime-dependent transformation curve**. Domestic wage suppression ($\omega \downarrow$) cannot resolve the crisis if the BoP constraint binds ($\phi_t < 1$), because the resulting surplus remains blocked from materializing as productive capacity. The peripheral formation remains structurally locked between internal class struggle and external financial subordination.
