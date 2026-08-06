---
type: paper_facing
status: draft
country: US_CL
stage_scope: S03_Handoff
last_updated: '2026-07-31'
depends_on: 
  - 03_Section_3_1_Baseline
  - 03_Section_3_2_Heterogeneous_Capital
  - 03_Section_3_3_Peripheral_Extension
layer: empirical_bridge
scope: chapter2
---

# Section 3.4: Formal Hypotheses and Empirical Handoff

The analytical models developed in Sections 3.1 through 3.3 generate a strict set of testable propositions regarding the structural efficiency of capital accumulation. This section translates the theoretical mechanics of the Okishio distributive dividend, the state-dependent viability yield, and the Peripheral Realization Trap into the exact econometric identification strategies deployed in Chapter 4.

## 3.4.1 The Core (US) Hypotheses: Induced Mechanization and Overaccumulation
Drawing on the state-dependent viability model (Section 3.2) and the IM-OLS cointegration architecture (Specification B3), we test the following propositions for the U.S. Non-Financial Corporate sector (1929–2024):

*   **Hypothesis 1 (The Okishio Distributive Dividend):** Domestic class struggle successfully induces labor-saving mechanization. The interaction between the lagged wage share and the mechanization gap is strictly positive and statistically significant in the long-run cointegrating vector.
    *   *Empirical Target:* $\hat{\theta}_{\omega\kappa} > 0$. (Validated via US Spec B3 Initial-State centering with step controls).
*   **Hypothesis 2 (The Relative Price Penalty):** The structural cost of the infrastructure envelope penalizes intensive accumulation. The interaction between the relative price of machinery and the mechanization gap is strictly negative.
    *   *Empirical Target:* $\hat{\theta}_{\kappa p\kappa} < 0$.
*   **Hypothesis 3 (The Structural Overaccumulation Regime):** Under weak labor closure (post-Fordism/neoliberalism), the state-dependent marginal viability yield collapses. The total aggregate transformation elasticity falls below unity, and potentially into negative territory, indicating that marginal capital accumulation yields diminishing or negative capacity expansion.
    *   *Empirical Target:* $\theta^{SpecB}_t < 1.0$ (averaging 0.41 over the century, and $\theta^{SpecB}_t < 0$ post-2000), mathematically formalizing the 50 percentage-point industrial stagnation gap.

## 3.4.2 The Periphery (Chile) Hypotheses: Imitative Capitalism and the BoP Gate
Drawing on the Prebischian extension (Section 3.3), the Chilean capital stock data (1900–2024), and the World Historical Balance of Payments (WBOP) dataset, we test the following propositions. 

> [!warning] Econometric Mandate: The I(2) Rupture
> Because the Chilean gross machinery stock ($k^{ME}_t$) is I(2) over the full century due to the permanent shift in the accumulation rate in 1973, and because pre-1973 ISI imports were administratively rationed, **Hypotheses 4 and 5 must be strictly tested on the post-1974 market-clearing sample** using break-aware ARDL or first-difference VECM specifications.

*   **Hypothesis 4 (The Import-Intensity of Imitative Mechanization):** The long-run structural requirement for productive imports is fundamentally anchored to the intensive margin of accumulation. The machinery stock dictates the foreign-exchange commitment of the peripheral economy.
    *   *Empirical Target:* The long-run cointegrating elasticity of real productive imports ($m_t$) with respect to the machinery stock ($k^{ME}_t$) is strictly positive and structurally locked ($\hat{\beta}_1 \approx 0.83$).
*   **Hypothesis 5 (The Peripheral Realization Trap):** When the Balance of Payments constraint binds (actual imports fall below the machinery-implied requirement *and* the WBOP Capacity to Import is contracting), the Okishio distributive dividend is inverted. The peripheral efficiency penalty dominates, rendering the total derivative of capacity with respect to the wage share negative.
    *   *Empirical Target:* In the augmented capacity equation, the triple interaction term capturing the binding regime ($Gap_t < 0 \cap \Delta \ln C_t < 0$) forces the total marginal effect of $\omega_{t-1}$ on $\kappa_t$ to be $\le 0$. 
*   **Hypothesis 6 (The 1982-1983 Physical Contraction):** The ultimate empirical fingerprint of the *estrangulamiento exterior* is the physical destruction of reproductive capital. When the external debt crisis severed the Capacity to Import ($\phi_t \to 0$), the imitative machinery stock physically contracted due to the absolute blockade of imported spare parts and replacement capital.
    *   *Empirical Target:* A violent, exogenous downward structural break in the $k^{ME}_t$ series precisely coinciding with the 1982-1983 BoP crisis, decoupling from the extensive margin ($k^{NRC}_t$).



### Section 3.4.1: Synthesis of Testable Propositions and Empirical Handoff

The analytical engines developed in Sections 3.1 through 3.3 yield a strict, testable parameter space. The transformation elasticity is not an exogenous engineering constant; it is a regime-dependent outcome governed by domestic class struggle, the internal composition of capital, and the external Balance of Payments (BoP). 

Table 1 consolidates the theoretical parameters, their expected algebraic signs, and their direct mapping to the IM-OLS (US) and ARDL/VECM (Chile) identification strategies deployed in Chapter 4.

### Table 1: Unified Parameter Matrix and Expected Signs

| Margin / Regime                | Theoretical Parameter                                |   Expected Sign   | Political-Economy Mechanism & Empirical Mapping                                                                                                                                                                                            |
| :----------------------------- | :--------------------------------------------------- | :---------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **US: Baseline (3.1)**         | $\frac{\partial q^*}{\partial \omega}$               |        $+$        | **Induced Innovation:** Distributive pressure forces cost-minimizing firms to cross the Marx-Okishio viability threshold, substituting labor for machinery.                                                                                |
| **US: Heterogeneous (3.2)**    | $\theta_{NRC}$                                       |        $+$        | **Extensive Envelope Yield:** The baseline capacity payoff of non-residential structures (the passive infrastructure envelope).                                                                                                            |
| **US: Heterogeneous (3.2)**    | $\theta_{\omega\kappa}$                              |        $+$        | **Okishio Distributive Dividend:** The state-dependent marginal viability of the mechanization gap. Wage pressure structurally increases the capacity-yield of machinery. *(Maps to US Spec B3 $\hat{\theta}_{\omega\kappa} > 0$)*.        |
| **US: Heterogeneous (3.2)**    | $\theta_{\kappa p\kappa}$                            |        $-$        | **Relative Price Penalty:** The structural cost drag of the infrastructure envelope. A rising relative price of machinery suppresses the optimal mechanization gap.                                                                        |
| **US: Overaccumulation**       | $\theta^{SpecB}_t$                                   |       $< 1$       | **Structural Stagnation:** Under weak labor closure (post-Fordism), the state-dependent marginal viability yield collapses, rendering marginal capital accumulation incapable of expanding productive capacity.                            |
| **Chile: Import Req. (3.3)**   | $\beta_1 = \frac{\partial m^{req}}{\partial k^{ME}}$ |        $+$        | **Imitative Capitalism:** The structural foreign-exchange cost of the intensive margin. Expanding the machinery stock strictly commits the periphery to proportional capital imports. *(Maps to Chile VECM $\hat{\beta}_1 \approx 0.83$)*. |
| **Chile: FX Bottleneck (3.3)** | $\frac{\partial \phi_t}{\partial \omega_{t-1}}$      |        $-$        | **Distributive Inflation of FX Demand:** Wage bargaining widens the mechanization gap, mechanically inflating the import requirement and compressing the FX-conversion ratio ($\phi_t$).                                                   |
| **Chile: Binding BoP (3.3)**   | $\theta_{Penalty}$                                   |        $-$        | **Peripheral Efficiency Penalty:** When the BoP binds ($\phi_t < 1$), Leontief rationing of imported spare parts idles the machinery stock, severing the link between physical capital and capacity.                                       |
| **Chile: The Trap (3.3)**      | $\frac{d \theta_{\text{periph}}}{d \omega_{t-1}}$    | ${\phi<1}$<br>$-$ | **The Peripheral Realization Trap:** In a binding BoP regime, the FX penalty dominates the Okishio dividend. Wage suppression mechanically relaxes the external constraint, while wage bargaining collapses realized capacity formation.   |

This matrix establishes the exact econometric targets for the empirical chapter. 
