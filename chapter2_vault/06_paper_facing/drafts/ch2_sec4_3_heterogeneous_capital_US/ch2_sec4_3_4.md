---
type: paper_facing
status: draft
country: US_CL
stage_scope: S03
last_updated: '2026-08-05'
depends_on: 
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
layer: analytical_foundation
scope: chapter2
---

\subsubsection{The Aggregate Transformation Elasticity}

\paragraph{A}
The aggregate transformation elasticity ($\theta^{SpecB}_t$) is the ratio of the total differentials of potential capacity ($dy^p_t$) and aggregate log capital ($dk^{cap}_t$) along the historical accumulation path.

\paragraph{B}
The total differential of the capacity equation, holding the slow-moving state variables fixed, separates the extensive envelope from the intensive margin:

\[ dy^p_t = \frac{\partial y^p_t}{\partial k^{NRC}_t} dk^{NRC}_t + \frac{\partial y^p_t}{\partial \kappa_t} d\kappa_t \]

\paragraph{C}
Substituting $\partial y^p_t / \partial k^{NRC}_t = \theta_{NRC}$ and the marginal capacity payoff to the mechanization gap $\partial y^p_t / \partial \kappa_t = MP_\kappa$:

\[ dy^p_t = \theta_{NRC} dk^{NRC}_t + MP_\kappa d\kappa_t \]
\[ dy^p_t = \theta_{NRC} dk^{NRC}_t + \left( \theta_\kappa + \theta_{\omega\kappa} \omega_{t-1} + \theta_{\kappa p\kappa} p^\kappa_t \right) d\kappa_t \]

\paragraph{D}
The variation in aggregate capital ($dk^{cap}_t$) follows from the Divisia index of the heterogeneous components, weighted by their nominal shares in the total productive capital stock ($s_{ME,t}$ and $s_{NRC,t}$):

\[ dk^{cap}_t \approx s_{ME,t} dk^{ME}_t + s_{NRC,t} dk^{NRC}_t \]

\paragraph{E}
By definition, the shares sum to unity ($s_{ME,t} + s_{NRC,t} = 1$) and the variation in the mechanization gap is the difference in accumulation rates ($d\kappa_t = dk^{ME}_t - dk^{NRC}_t$). Substituting $dk^{ME}_t = d\kappa_t + dk^{NRC}_t$, the aggregate capital variation simplifies elegantly to:

\[ dk^{cap}_t \approx s_{ME,t} (d\kappa_t + dk^{NRC}_t) + s_{NRC,t} dk^{NRC}_t = dk^{NRC}_t + s_{ME,t} d\kappa_t \]

\paragraph{F}
Dividing both the capacity differential ($dy^p_t$) and the capital differential ($dk^{cap}_t$) by the extensive accumulation rate ($dk^{NRC}_t$) yields the elasticity parameterized by the empirical growth path $\frac{d\kappa_t}{dk^{NRC}_t}$:

\[ \theta^{SpecB}_t = \frac{dy^p_t}{dk^{cap}_t} = \frac{\theta_{NRC} dk^{NRC}_t + MP_\kappa d\kappa_t}{dk^{NRC}_t + s_{ME,t} d\kappa_t} = \frac{\theta_{NRC} + MP_\kappa \frac{d\kappa_t}{dk^{NRC}_t}}{1 + s_{ME,t} \frac{d\kappa_t}{dk^{NRC}_t}} \]

\paragraph{G}
Expanding the marginal payoff term ($MP_\kappa$) recovers the full structural expression for the aggregate transformation elasticity under Specification B:

\[ \theta^{SpecB}_t = \frac{\theta_{NRC} + \left( \theta_\kappa + \theta_{\omega\kappa} \omega_{t-1} + \theta_{\kappa p\kappa} p^\kappa_t \right) \frac{d\kappa_t}{dk^{NRC}_t}}{1 + s_{ME,t} \frac{d\kappa_t}{dk^{NRC}_t}} \]

\paragraph{H}
Empirically, evaluating the trajectory slope $\frac{d\kappa_t}{dk^{NRC}_t}$ using point estimates of annual growth rates ($\frac{g^{ME}_t}{g^{NRC}_t} - 1$) introduces severe high-frequency noise and division-by-zero singularities during recession years when aggregate capital accumulation slows to near-zero ($g^{cap}_t \approx 0$). Furthermore, using nominal capital shares introduces relative asset price inflation noise. To isolate the true structural capacity transformation elasticity, we ground the weights in real GPIM gross physical capital stocks ($s^{\text{real}}_{ME,t} = \frac{K^{ME}_t}{K^{ME}_t + K^{NRC}_t}$) and evaluate the trajectory slope $\frac{d\kappa_t}{dk^{NRC}_t}$ non-parametrically.

\paragraph{I}
We estimate the smooth accumulation corridor by fitting a non-parametric LOESS curve of the mechanization gap $\kappa_t = k^{ME}_t - k^{NRC}_t$ against extensive plant scale $k^{NRC}_t$ with a smoothing parameter $\text{span} = 0.30$:

\[ \kappa_t = f(k^{NRC}_t) + \epsilon_t \]

\paragraph{J}
The structural derivative $\frac{d\kappa_t}{dk^{NRC}_t}$ is evaluated as the local slope of the predicted LOESS trajectory:

\[ \frac{d\kappa_t}{dk^{NRC}_t} = \frac{d \hat{f}(k^{NRC}_t)}{d k^{NRC}_t} \]

\paragraph{K}
Substituting the smooth LOESS slope $\frac{d\kappa_t}{dk^{NRC}_t}$ and the real gross capital share $s^{\text{real}}_{ME,t}$ into the continuous differential formula from Paragraph G yields the operational state-dependent aggregate transformation elasticity:

\[ \theta^{SpecB}_t = \frac{\theta^{str}_{NRC} + MP_{\kappa, t} \frac{d\kappa_t}{dk^{NRC}_t}}{1 + s^{\text{real}}_{ME,t} \frac{d\kappa_t}{dk^{NRC}_t}} \]

\paragraph{L}
Because the denominator $1 + s^{\text{real}}_{ME,t} \frac{d\kappa_t}{dk^{NRC}_t}$ is strictly positive and smooth across both the historical baseline ($T=94$) and the stricter Tier 2 supervisory-adjusted window ($T=77$), this operationalization completely eliminates zero-growth singularities. It isolates the dynamic interaction between structural parameters ($\theta$) and the long-run historical corridor of accumulation, showing how the capacity yield responds to shifting distributive conflict ($\omega_{t-1}$) and the strategic intensity of mechanization.

\paragraph{M}
We operationalize this formalization by reconstructing the historical series for the aggregate transformation elasticity ($\theta^{SpecB}_t$) and capacity utilization ($\mu_t$) using the parameter estimates from the preferred specifications: Model M2.19a (NVA-basis, Shaikh-Tonak Tier 1, No Break) and Model M2.24b (NVA-basis, Shaikh-Tonak Tier 2, With Breaks in 1944, 1965, 1979, and 1996). Potential capacity $Y^p_t$ is constructed using the direct evaluation method anchored at the 1973 peak benchmark, which guarantees that $\mu_{1973} = 100\%$ exactly for both models.

\paragraph{N}
The reconstructed series for aggregate capacity utilization (Figure~\ref{fig:specB_mu}) reveals a clear periodization of U.S. corporate performance. During the height of the Fordist accumulation era (1945–1973), capacity utilization was high and stable, reflecting robust demand and coordinated growth. Following the 1973 oil shock and the collapse of the Fordist wage-productivity accord, utilization entered a severe decline, bottoming out during the early 1980s recessions. In the post-Fordist era (1980–2024), utilization recovered and stabilized at a lower average level, showing that corporate restructuring successfully adapted the production process to the new institutional regime.

![Reconstructed Capacity Utilization ($\mu_t$), Specification B](output/US/S61_SECTION32_IMOLS/figures/fig_specB_reconstructed_capacity_utilization.png "fig:specB_mu")

\paragraph{O}
The trajectory of the smooth dynamic transformation elasticity under the constrained overcapacity view (Figure~\ref{fig:specB_knife_edge}) shows that $\theta^{SpecB}_t$ remains consistently below the critical overcapacity threshold ($\theta = 1.00$) throughout the entire post-1930 period (averaging $\approx 0.52$ for M2.19a and $\approx 0.46$ for M2.24b). This result confirms the core Marxist-Okishian thesis of chronic capital overaccumulation: the marginal capacity yield of aggregate investment is structurally depressed, meaning that the U.S. corporate sector cannot escape the overaccumulation regime even during periods of apparent recovery.

![Aggregate Transformation Elasticity and the Harrodian Knife-Edge](output/US/S61_SECTION32_IMOLS/figures/fig_specB_aggregate_elasticity_knife_edge.png "fig:specB_knife_edge")

\paragraph{P}
Allowing the y-axis to vary without constraints (Figure~\ref{fig:specB_elasticity_zoom}) illustrates the smooth, continuous evolution of the aggregate capital yield across historical accumulation eras. Rather than being disrupted by artificial division-by-zero spikes, the unconstrained series clearly traces the secular decline of the transformation elasticity from the early post-war peak down through the stagflation crisis and post-1980s neoliberal restructuring.

![Unconstrained Aggregate Transformation Elasticity](output/US/S61_SECTION32_IMOLS/figures/fig_specB_aggregate_elasticity_zoomed.png "fig:specB_elasticity_zoom")


