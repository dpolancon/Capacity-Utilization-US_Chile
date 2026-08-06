---
type: paper_facing
status: draft
country: US_CL
stage_scope: S03
last_updated: '2026-08-05'
updated_by: PERIPHERAL_CORNER_SOLUTION_SYNTHESIS
depends_on: 
  - A04_PeripheralTransformationElasticity
  - 03_Section_3_2_Heterogeneous_Capital
layer: analytical_foundation
scope: chapter2
---

# Section 3.3: Peripheral Extension: Imitative Capitalism, the Choice of Technique, and the Realization Bottleneck

In the capitalist periphery, the intensive margin of accumulation is structurally tethered to the world market and constrained by domestic social friction. Following Prebisch (1981) and Kaldor (1959), peripheral capitalism is characterized by high consumption propensities out of profits, structural inelasticities in agriculture, and a chronic vulnerability to balance-of-payments crises. This introduces a dual realization bottleneck: the macroeconomic capacity to import and the inelastic domestic supply of wage-goods. To integrate these structuralist insights into our heterogeneous capital framework, we formalize the Prebisch-Kaldor external strangulation (*estrangulamiento exterior*) not as an ad-hoc penalty, but as a strict macroeconomic boundary constraint on the cost-minimizing firm's choice of technique.

## 3.3.1 The Import-Biased Intensive Margin and the Prebisch-Kaldor Constraint

In Section 3.2, we established that the cost-minimizing firm chooses the mechanization gap $\kappa_t$ to maximize the net viability surplus, defined as the gross engineering yield of the gap minus the effective distributive and price costs:

$$ \max_{\kappa_t} \ c(\kappa_t) = \Phi(\kappa_t) - \kappa_t \cdot MC(\omega_{t-1}, p^\kappa_t) $$

where $\Phi(\kappa_t) = \lambda_0 + \lambda_1 \kappa_t + \lambda_2 \kappa_t^2$ is the regime-conditioned mechanization frontier, and $MC(\omega_{t-1}, p^\kappa_t) = \gamma_0 - \gamma_1 \omega_{t-1} + \gamma_2 p^\kappa_t$ is the marginal viability cost of the gap.

In the core, this optimization proceeds unconstrained, yielding the optimal mechanization gap $\kappa_t^*$. However, in the periphery, active mechanization is strictly import-biased. The widening of the mechanization gap requires imported capital goods, specialized machinery, and technologically non-substitutable spare parts. 

Let the physical import requirement per unit of output ($m^{req}_t$) be a linear function of the chosen technique:

$$ m^{req}_t = \nu \cdot \kappa_t $$

where $\nu > 0$ captures the structural import-intensity of the mechanization gap. 

Simultaneously, the physical capacity to satisfy this requirement is bounded by the macroeconomic **Capacity to Import** per unit of output ($m^{avail}_t = M^{avail}_t / Y_t$). Following Prebisch, peripheral export growth is governed by the center's income elasticity of demand for primary goods ($\epsilon_{m,c} < 1$), structurally lagging behind domestic import demand. This external asymmetry, compounded by Kaldor's observation of extreme conspicuous consumption out of capitalist profits ($c_k \approx 0.60$ for Chile), severely squeezes the foreign exchange available for productive accumulation.

This imposes a strict external ceiling on the choice of technique:

$$ \nu \cdot \kappa_t \le m^{avail}_t \implies \kappa_t \le \bar{\kappa}_t \equiv \frac{m^{avail}_t}{\nu} $$

## 3.3.2 The Constrained Cost-Surplus Maximization Problem

The peripheral firm's tactical problem is therefore a constrained cost-surplus maximization:

$$ \max_{\kappa_t} \ c(\kappa_t) = \Phi(\kappa_t) - \kappa_t \cdot MC(\omega_{t-1}, p^\kappa_t) $$
$$ \text{subject to:} \quad \kappa_t \le \bar{\kappa}_t $$

This formulation defines two distinct accumulation regimes, endogenous to the interaction between domestic distributive conflict and the global market. To identify exactly *how* the external limit ($\bar{\kappa}_t$) becomes binding, we must decompose the macroeconomic allocation of foreign exchange.

## 3.3.3 The Macroeconomic Allocation of Foreign Exchange

The total supply of foreign exchange per unit of output is driven by primary exports ($x_t = p_t^x X_t / Y_t$). Due to the center's low income elasticity for primary goods, $x_t$ is structurally rigid.

The total demand for foreign exchange per unit of output consists of three competing components:
1. **Wage-Goods Imports ($m^W_t$)**: Driven by the wage share $\omega_{t-1}$ and the structural inelasticity of domestic agriculture (Kaldor's food bottleneck). $m^W_t = m_w \omega_{t-1}$.
2. **Conspicuous Consumption Imports ($m^C_t$)**: Driven by the profit share $\pi_t$ and the high propensity of the peripheral upper strata to imitate the consumption patterns of the center (Prebisch's imitative capitalism). $m^C_t = m_c c_k \pi_t$.
3. **Productive Capital Imports ($m^K_t$)**: Driven by the mechanization gap. $m^K_t = \nu \kappa_t$.

The balance of payments constraint requires that total import demand cannot exceed export capacity:
$$ m_w \omega_{t-1} + m_c c_k \pi_t + \nu \kappa_t \le x_t $$

Using the distributive identity $\pi_t = 1 - \omega_{t-1}$, we substitute and solve for the maximum feasible mechanization gap $\bar{\kappa}_t$:
$$ m_w \omega_{t-1} + m_c c_k (1 - \omega_{t-1}) + \nu \kappa_t \le x_t $$
$$ \nu \kappa_t \le x_t - m_c c_k + (m_c c_k - m_w) \omega_{t-1} $$

$$ \bar{\kappa}_t(\omega_{t-1}) = \frac{1}{\nu} \left[ x_t - m_c c_k + (m_c c_k - m_w) \omega_{t-1} \right] $$

This equation mathematically formalizes the structuralist critique. The base capacity to import capital goods is determined by export earnings minus the baseline luxury consumption of the capitalist class ($x_t - m_c c_k$).

## 3.3.4 Endogenous Regime Shifts: The Corner Solution

The firm's unconstrained optimal technique $\kappa_t^*(\omega_{t-1})$ is strictly increasing in the wage share ($\frac{\partial \kappa_t^*}{\partial \omega_{t-1}} > 0$) due to the Okishio labor-saving bias.

### Regime A: Slack BoP (The Unconstrained Optimum)
When the macroeconomic capacity to import is abundant relative to the desired technique ($\kappa_t^* \le \bar{\kappa}_t$), the firm solves the standard first-order condition $\frac{dc}{d\kappa_t} = 0$, yielding $\kappa_t^*$. The labor-saving bias successfully extracts the Okishio distributive dividend, preserving the firm's cost-surplus.

### Regime B: The Peripheral Realization Trap (The Corner Solution)
The constraint turns binding when the required mechanization outstrips the available foreign exchange: $\kappa_t^*(\omega_{t-1}) > \bar{\kappa}_t(\omega_{t-1})$. The firm is forced into a **corner solution**:
$$ \kappa_t = \bar{\kappa}_t $$

This happens through two intersecting structural vulnerabilities. First, if $m_c c_k$ is massive (the conspicuous consumption drain), the baseline FX availability is severely squeezed, lowering the intercept of $\bar{\kappa}_t$. Second, if domestic agriculture is highly inelastic ($m_w > m_c c_k$), a rising wage share simultaneously increases the *demand* for capital imports (via $\kappa_t^*$) while *contracting* the supply of available FX (via $\bar{\kappa}_t$). 

## 3.3.5 Effective Profit Compression and the Blocked Surplus

The collision between desired technique and available foreign exchange generates a direct wedge between nominal profitability and realized accumulation. We define the **FX-Conversion Ratio** ($\phi_t$) as the ratio of the maximum feasible technique to the optimal unconstrained technique:

$$ \phi_t = \min\left(1, \frac{\bar{\kappa}_t}{\kappa_t^*}\right) $$

When the external constraint binds ($\kappa_t^* > \bar{\kappa}_t$), $\phi_t < 1$. This generates a direct compression of the **effective profit share** ($\pi_t^{eff}$) available for intensive accumulation. Even if domestic wage suppression yields a high nominal profit share ($\pi_t$), the physical inability to convert that surplus into imported machinery squeezes the effective profit rate:

$$ \pi_t^{eff} = \pi_t \cdot \phi_t = (1 - \omega_{t-1}) \cdot \phi_t $$

The difference constitutes the **Blocked Surplus**:
$$ \text{Blocked Surplus} = \pi_t(1 - \phi_t) $$

Because the accumulation of machinery is driven by the *effective* profit share ($g_{K^{ME}} = \chi^{ME} \pi_t^{eff} - \delta^{ME}$), the constraint totally decouples nominal profitability from capacity formation. If capitalists squeeze wages to raise $\pi_t$, they inadvertently increase conspicuous consumption ($m^C_t$), which lowers $\bar{\kappa}_t$ and tanks the conversion ratio $\phi_t$. 

## 3.3.6 The Failure of the Okishio Mechanism and Structural Inflation

At the boundary $\kappa_t = \bar{\kappa}_t$, the **Okishio mechanism is blocked**. The firm is stripped of its ability to defend its viability surplus through labor-saving technical change. 

Because the required machinery cannot be imported, the "wage-savings dividend" cannot be capitalized into physical capacity. Consequently, the firm suffers a persistent shortfall in its cost-surplus relative to its unconstrained optimal state. 

Unable to extract the distributive dividend via mechanization, capitalists attempt to recover this blocked surplus through the only remaining channel: price markups. As Kaldor (1959) emphasized, when the wage-goods (food) bottleneck forces nominal wage adjustments, and the external BoP bottleneck blocks defensive mechanization, any further increase in the wage share directly crushes profitability. The resulting defensive pricing behavior ignites the **structural inflation** dynamic.
