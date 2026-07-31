---
type: paper_facing
status: draft
country: US_CL
stage_scope: S03
last_updated: '2026-07-31'
depends_on: 
  - A04_PeripheralTransformationElasticity
  - 03_Section_3_2_Heterogeneous_Capital
layer: analytical_foundation
scope: chapter3
---

# Section 3.3: Peripheral Extension: Imitative Capitalism, the Capacity to Import, and the Balance-of-Payments Gate

In the capitalist periphery, the intensive margin of accumulation is structurally tethered to the world market. The widening of the mechanization gap ($\kappa_t$) requires imported capital goods, specialized machinery, and technologically non-substitutable spare parts. Following Prebisch’s structuralist critique of imitative capitalism, the periphery imports technology designed for the center's factor endowments, rendering the intensive margin inherently import-biased. 

This structural dependence introduces a realization bottleneck. When the Balance of Payments (BoP) constraint binds, the aggregate peripheral transformation elasticity ($\theta_{\text{periph}}$) is truncated—not by domestic wage pressure, but by the inability to convert domestic surplus into imported capital goods.

## 3.3.1 The Import Intensity of Induced Mechanization

In Section 3.2, we established that domestic class struggle forces cost-minimizing firms to widen the mechanization gap. The optimal gap $\kappa_t^*$ is strictly increasing in the lagged wage share ($\partial \kappa_t^* / \partial \omega_{t-1} > 0$). 

Let the required physical import volume ($M^{req}_t$) be driven by this desired intensive accumulation:

$$ M^{req}_t = \nu \cdot \kappa_t^*(\omega_{t-1}, p_t^\kappa) \cdot Y_t $$

where $\nu > 0$ captures the structural import-intensity of the mechanization gap. Because the optimal gap widens in response to domestic wage pressure, the foreign exchange requirement is strictly increasing in the wage share:

$$ \frac{\partial M^{req}_t}{\partial \omega_{t-1}} = \nu Y_t \frac{\partial \kappa_t^*}{\partial \omega_{t-1}} > 0 $$

This derivation establishes a fundamental open-economy macro linkage: **distributive conflict directly inflates the external payment requirement.** The firm’s tactical response to domestic wage bargaining structurally exacerbates the peripheral balance-of-payments deficit.

## 3.3.2 The Capacity to Import and Global Asymmetries

The physical capacity to satisfy this requirement is bounded by the **Capacity to Import** ($M^{avail}_t$), determined by export volumes and the terms of trade. Following Prebisch, peripheral export growth is governed by the center's income elasticity of demand for peripheral goods ($\epsilon_{m,c}$). Because Engel's law and technological monopolies depress the center's import propensity ($\epsilon_{m,c} < 1$), the growth of the Capacity to Import lags structurally behind the growth of domestic import demand. This global asymmetry generates the structural tendency toward external strangulation (*estrangulamiento exterior*).

## 3.3.3 The FX-Conversion Bottleneck and Blocked Surplus

Realized intensive accumulation is gated by the FX-conversion ratio ($\phi_t$), which measures the fraction of the machinery-implied import requirement that can be physically realized:

$$ \phi_t = \min\left(1, \frac{M^{avail}_t}{M^{req}_t(\omega_{t-1})}\right) $$

When $M^{avail}_t \ge M^{req}_t$, the BoP constraint is slack ($\phi_t = 1$). When $M^{avail}_t < M^{req}_t$, the BoP constraint binds ($\phi_t < 1$). 

In the binding regime, the physical volume of imported capital goods is strictly capped at $M^{avail}_t$. This generates a **Blocked Surplus**: domestic accounting profits that cannot be materialized as productive capacity due to external payment constraints. Crucially, the physical ceiling on accumulation becomes strictly invariant to domestic distributive conflict. Squeezing the wage share to raise nominal profitability does not increase the physical capacity to import; it merely expands the blocked surplus, decoupling nominal profitability from realized capacity formation.

## 3.3.4 The Aggregate Weight and Endogenous Regime Shifts

The BoP constraint operates as a non-linear regime gate triggering a **peripheral efficiency penalty**. Because imported capital goods and spare parts exhibit strict Leontief complementarity with domestic structures, the rationing of imported inputs induces severe vintage mismatch, maintenance backlogs, and idle capacity. We model this penalty via $\Psi(\phi_t) = \phi_t^\eta$, where $\eta \ge 1$ captures the rigidity of import complementarity. 

The constrained intensive-margin transformation elasticity becomes:

$$ \theta^{ME}_{\text{periph}} = \theta^{ME}_{\text{core}} \cdot \phi_t^\eta $$

Aggregating the unconstrained extensive margin and the FX-constrained intensive margin yields the complete aggregate peripheral transformation elasticity:

$$ \theta_{\text{periph}} = (1 - W_{ME}) \theta_{NRC} + W_{ME} \theta^{ME}_{\text{periph}} $$

The weight $W_{ME}$ is not a static accounting parameter; it is the endogenous Divisia growth-share of intensive-margin capital in aggregate accumulation. Formally:

$$ W_{ME} = \frac{s_{ME} g_{K^{ME}}}{(1 - s_{ME}) g_{K^{NRC}} + s_{ME} g_{K^{ME}}} $$

where $s_{ME}$ is the machinery share of the total productive capital stock. The net accumulation rates at both margins are strictly gated by the effective profit share:

$$ g_{K^{ME}} = \chi^{ME} \pi^{eff}_t - \delta^{ME} $$
$$ g_{K^{NRC}} = \chi^{NRC} \pi^{eff}_t - \delta^{NRC} $$

This structural linkage proves that the composition of accumulation is regime-dependent. In a slack BoP regime ($\phi_t = 1$), the full nominal profit share accelerates intensive accumulation ($g_{K^{ME}} \uparrow$). The weight $W_{ME}$ rises, shifting the aggregate transformation elasticity toward the high-yield mechanization frontier ($\theta^{ME}_{\text{core}}$). 

Conversely, when the BoP binds ($\phi_t < 1$), FX rationing depresses the effective profit share. Because imported machinery is strictly rationed, intensive accumulation collapses ($g_{K^{ME}} \downarrow$), mechanically driving $W_{ME} \to 0$. As the weight shifts away from machinery, the peripheral economy is forced to rely predominantly on extensive plant expansion ($\theta_{NRC}$), structurally pulling down total technological dynamism and locking the economy into low-productivity techniques.

## 3.3.5 The Peripheral Realization Trap

To evaluate the total effect of domestic class struggle on realized peripheral capacity formation, we take the total derivative of $\theta_{\text{periph}}$ with respect to the wage share:

$$ \frac{d \theta_{\text{periph}}}{d \omega_{t-1}} = \underbrace{W_{ME} \theta_{\omega\kappa} \phi_t^\eta}_{\text{Okishio Distributive Dividend}} + \underbrace{W_{ME} \theta^{ME}_{\text{core}} \eta \phi_t^{\eta-1} \frac{\partial \phi_t}{\partial \omega_{t-1}}}_{\text{Peripheral FX Penalty}} $$

Because $\partial M^{req}_t / \partial \omega_{t-1} > 0$, the derivative of the conversion ratio with respect to the wage share is strictly negative ($\partial \phi_t / \partial \omega_{t-1} < 0$). 

> [!conclusion] The Peripheral Realization Trap
> In a slack BoP regime ($\phi_t = 1$), the FX penalty term vanishes, and domestic wage bargaining successfully induces mechanization, expanding capacity. However, when the BoP binds ($\phi_t < 1$), the second term activates. If the Leontief rigidity of imported complements ($\eta$) is sufficiently high, the **Peripheral FX Penalty dominates the Okishio Distributive Dividend**, rendering the total derivative negative:
> $$ \frac{d \theta_{\text{periph}}}{d \omega_{t-1}} < 0 $$
> This formally defines the **Peripheral Realization Trap**: aggressive wage bargaining forces the firm to choose an import-intensive technique, which collides with the exogenous Capacity to Import. The resulting rationing of imported complements idles the machinery stock, collapsing realized capacity formation. Conversely, domestic wage suppression mechanically relaxes the BoP constraint, allowing the existing capital stock to function. The peripheral economy remains structurally locked between internal class struggle and external financial subordination.
