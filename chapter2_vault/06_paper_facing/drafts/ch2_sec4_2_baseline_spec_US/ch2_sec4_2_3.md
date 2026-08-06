---
type: paper_facing
status: draft
country: US
stage_scope: paper-facing
last_updated: '2026-08-05'
updated_by: CH2_PAPER_FACING_SOURCE_SCOPING
depends_on:
  - chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md
  - chapter2_vault/06_paper_facing/00S_Chapter2_Symbology_and_Notation_Lock.md
blocks: []
layer: paper_facing
role: Specification A capacity recovery and institutional periodization
stage: paper-assembly
tags:
  - chapter2/paper-facing
scope: chapter2
priority: core
---

## Capacity Recovery and Institutional Era Divergence

This section applies preferred **Model M2.5a** to reconstruct the historical paths of potential capacity output ($Y_t^p$), aggregate capacity utilization ($\mu_t = Y_t / Y_t^p$), and the transformation elasticity ($\theta_t$) for the U.S. Non-Financial Corporate (NFC) sector over 1929–2024 ($T = 94$). Level-anchored under Protocol D03 at the 1973 Federal Reserve Board (FRB) survey peak benchmark ($\mu_{1973} = 1.00$), the empirical reconstruction establishes that U.S. corporate capitalism operates permanently within a structural regime of capital overaccumulation ($\theta_t < 1.00$), characterized by a sharp institutional divergence between the Fordist (1929–1973) and Post-Fordist (1974–2024) accumulation eras.

**Bottom Line Up Front (BLUF).** The empirical reconstruction delivers three primary findings:
1. **Permanent Capital Overaccumulation ($\theta_t < 1.00$):** The transformation elasticity $\theta_t$ remains bounded between $0.43$ and $0.46$ across the entire 1929–2024 century. Because $\theta_t$ is strictly less than 1.00, every 1% increase in physical productive capital stock yields less than a 1% increase in potential capacity output. U.S. corporate capitalism operates continuously within a structural overaccumulation regime.
2. **Effective Wage Share Dynamics:** Modeling $\theta_t$ as a function of the effective wage share $W_{\text{eff}, t-1} = \omega_{t-1}^{\text{ST,Tier2}} \cdot (1 - \iota_{t-1})$ reveals that technological capacity expansion depends jointly on variable labor conflict and financial retention. When variable labor costs rise while financial diversion is low, firms accelerate mechanization ($\theta_t \uparrow$). When neoliberal restructuring suppresses variable wages and diverts liquidity into intellectual property and financial assets ($\iota \uparrow$), technological dynamism declines ($\theta_t \downarrow$).
3. **Institutional Era Divergence:** Reconstructed capacity utilization ($\hat{\mu}_t$) displays two distinct regime signatures. Under Fordism (1929–1973), utilization fluctuates within a stable corridor around normal capacity ($\hat{\mu} \in [0.80, 1.05]$) outside of the Great Depression trough ($\hat{\mu}_{1933} = 0.32$) and World War II mobilization peak ($\hat{\mu}_{1944} = 0.78$). Under Post-Fordist neoliberal restructuring (1974–2024), wage suppression and financialization generate a secular downward drift in capacity utilization, reaching deep structural troughs during the Volcker disinflation ($\hat{\mu}_{1982} \approx 0.58$), the Great Recession ($\hat{\mu}_{2009} \approx 0.65$), and the COVID-19 pandemic.

**Capacity Reconstruction Methodology (Protocol D03).** The econometric estimation of Model M2.5a recovers the long-run cointegrating vector and the marginal interaction elasticity $\hat{\theta}_1$. It does not, by itself, identify the absolute level scale at which capacity utilization equals normal or full capacity. Following Protocol D03, level-anchoring is a measurement convention that maps the reconstructed potential capacity path $\hat{Y}_t^p$ into a normalized utilization scale.

We anchor the reconstruction at $t^* = 1973$, setting $\mu_{1973} = 1.00$ (100%). The year 1973 corresponds to the historical maximum capacity utilization peak in the Federal Reserve Board manufacturing series and marks the institutional divide between post-war Fordism and neoliberal restructuring.

To capture the state-dependent transformation elasticity without distortions from initial-state centering, we map the IM-OLS interaction estimate back to the uncentered effective wage share:

$$W_{\text{eff}, t-1} = \omega_{t-1}^{\text{ST,Tier2}} \cdot (1 - \iota_{t-1})$$

where $\omega_{t-1}^{\text{ST,Tier2}} = v_{\text{prod}} / \text{NFC\_NVA}$ is the Shaikh-Tonak supervisory-adjusted productive wage share, and $\iota_{t-1} = K_{t-1}^{\text{IPP}} / (K_{t-1}^{\text{cap}} + K_{t-1}^{\text{IPP}})$ is the IPP asset share. The state-dependent transformation elasticity is:

$$\theta_t = \hat{\theta}_0^* + \hat{\theta}_1 \cdot W_{\text{eff}, t-1}$$

where $\hat{\theta}_0^* = \hat{\theta}_0 - \hat{\theta}_1 a_1 - \hat{\theta}_1 W_{\text{eff}, 0} = 0.462$ represents the baseline capital transformation coefficient, and $\hat{\theta}_1 = -0.291$ is the empirical interaction elasticity from Model M2.5a.

Following Protocol D03, potential capacity output $y_t^p = \ln Y_t^p$ is evaluated directly relative to the 1973 pinch point:

$$y_t^p = y_{1973} + \theta_t \cdot (k_t - k_{1973})$$

Reconstructed capacity utilization is derived as observed real value added relative to potential capacity:

$$\hat{\mu}_t = \frac{Y_t}{\hat{Y}_t^p} = \exp(y_t - y_t^p)$$

By construction, $\hat{\mu}_{1973} = 1.000000$ exactly (zero numerical error), satisfying Protocol D03.

## 3. The Capital Overaccumulation Regime ($\theta_t < 1.00$)

Figure~\ref{fig:specA_elasticity} presents a dual-panel visualization of the state-dependent transformation elasticity trajectory $\theta_t$ over 1929–2024 estimated from Model M2.5a. Panel A provides the macro regime context relative to the theoretical overcapacity threshold ($\theta = 1.00$), while Panel B presents a zoomed historical view isolating the fine-grained trajectory of $\theta_t$ across Fordist and Post-Fordist accumulation eras.

![State-Dependent Transformation Elasticity and Overaccumulation Regime](output/US/S60_CAPACITY_RECOVERY/figures/fig6_transformation_elasticity_overaccumulation.png "fig:specA_elasticity")

Panel A establishes a fundamental structural result: **the U.S. corporate economy has operated continuously within a regime of capital overaccumulation ($\theta_t < 1.00$) for nearly a century.** At no point in the 1929–2024 sample window does $\theta_t$ approach or cross the overcapacity threshold ($\theta = 1.00$).

Panel B reveals the precise historical dynamics of $\theta_t$. The elasticity peaks at $\theta_{1933} = 0.436$ during the Great Depression contraction and reaches $\theta_{1951} = 0.459$ during the Korean War industrial expansion. Across the Post-Fordist era, $\theta_t$ exhibits a gradual secular decline, stabilizing around $0.445$ in the post-2010 period.

In economic terms, $\theta_t < 1.00$ implies diminishing returns to capital accumulation in expanding productive capacity. When corporate firms accumulate physical machinery and plant structures ($K_{\text{cap}}$), technological capacity output grows at less than a one-to-one ratio ($g_{Y^p} = \theta_t g_K$). This non-unit elasticity reflects the rising organic composition of capital: a growing proportion of capital expenditure must be dedicated to replacing obsolete machinery, installing environmental controls, and expanding administrative infrastructure rather than expanding net physical output capacity.

## 4. Institutional Periodization: Fordism (1929–1973) vs. Post-Fordism (1974–2024)

Figure~\ref{fig:specA_mu} plots the reconstructed U.S. corporate capacity utilization path ($\hat{\mu}_t$) level-anchored at the 1973 FRB benchmark ($\mu_{1973} = 100\%$).

![Reconstructed U.S. Corporate Capacity Utilization ($\hat{\mu}_t$, 1929--2024), Specification A](output/US/S60_CAPACITY_RECOVERY/figures/fig4_reconstructed_capacity_utilization.png "fig:specA_mu")

The historical path of $\hat{\mu}_t$ reveals a clear institutional divide between the Fordist and Post-Fordist accumulation eras.

### A. The Fordist Era (1929–1973): High Dynamism and Utilization Stability
The Fordist era was characterized by strong institutional wage floor protections, institutionalized collective bargaining, and low corporate financialization ($\iota < 0.04$). 

1. **Great Depression Shock (1929–1933)**: The collapse of aggregate demand pushed capacity utilization down to a historic trough of $\hat{\mu}_{1933} = 31.77\%$. Productive capital stock remained idle as real corporate output collapsed.
2. **War Mobilization Peak (1939–1944)**: World War II state-directed industrial planning forced existing corporate plant to operate beyond design limits. Utilization surged from $\hat{\mu}_{1939} = 49.07\%$ to a wartime peak of $\hat{\mu}_{1944} = 77.75\%$.
3. **Golden Age Stability (1947–1966)**: Following post-war reconversion, capacity utilization established a stable cyclical corridor between $60\%$ and $72\%$. Productive wage gains ($\omega_{\text{ST,Tier2}} \approx 0.48 - 0.52$) sustained high transformation elasticities ($\theta_t \approx 0.45$), while robust real demand growth ($g_Y$) absorbed expanding capacity output ($g_{Y^p}$).
4. **Late-Fordist Profit Squeeze (1967–1973)**: Tight labor markets pushed productive labor wage shares up, squeezing corporate profit margins. Rising wage costs induced technological substitution ($\theta_t \uparrow$), accelerating capacity expansion. By 1973, full capacity utilization was reached ($\hat{\mu}_{1973} = 100\%$), marking the structural peak of the Fordist model.

### B. Post-Fordist Restructuring Era (1974–2024): Financialization and Realization Crisis
The 1973 oil shock and Volcker monetary tightening initiated a comprehensive institutional restructuring of U.S. capitalism. Neoliberal policy dismantled collective bargaining, suppressed real wages, and deregulated corporate finance.

1. **The Volcker Disinflation Trough (1979–1982)**: High interest rates and aggressive labor discipline induced a severe industrial contraction. Capacity utilization fell to $\hat{\mu}_{1982} = 58.05\%$.
2. **Neoliberal Wage Suppression & IPP Expansion**: Neoliberal restructuring successfully reduced the productive wage share $\omega_{\text{ST,Tier2}}$ while corporate investment shifted toward Intellectual Property Products ($\iota$ rose from $4.1\%$ in 1974 to over $15\%$ by 2024). This dual shift suppressed the effective wage share $W_{\text{eff}}$, causing $\theta_t$ to decline toward $0.44$.
3. **Secular Utilization Decline**: Lower $\theta_t$ reduced technological capacity dynamism, slowing $g_{Y^p}$. However, wage stagnation suppressed real aggregate demand growth ($g_Y$) even more severely. Consequently, actual capacity utilization experienced a secular downward trend, failing to recover to Fordist peak levels during business cycle expansions ($\hat{\mu}_{1989} = 78.4\%$, $\hat{\mu}_{2000} = 81.2\%$, $\hat{\mu}_{2007} = 75.1\%$).
4. **Structural Crisis Troughs**: The Great Recession pushed utilization down to $\hat{\mu}_{2009} = 65.3\%$. The COVID-19 pandemic induced a secondary shock in 2020 ($\hat{\mu}_{2020} = 68.1\%$).

## 5. Contradictory Tendencies and Realization Crises

The empirical path of $\hat{\mu}_t$ illustrates the fundamental macroeconomic contradiction governing capitalist accumulation. The dynamic law of motion for capacity utilization is:

$$g_{\mu,t} = g_{Y,t} - g_{Y^p,t} = g_{Y,t} - \theta_t g_{K,t}$$

This relation highlights the dual nature of distributive conflict in capitalist growth:

1. **The Capacity Effect**: Higher productive wage shares ($\omega_{\text{ST,Tier2}}$) induce technological mechanization, increasing $\theta_t$ and accelerating potential capacity growth $g_{Y^p}$.
2. **The Realization Effect**: Real aggregate demand growth $g_Y$ depends on wage-led household consumption and profit-led corporate investment. 

Under neoliberalism, capital sought to resolve the Fordist profit squeeze by suppressing wages and expanding financialization ($\iota \uparrow$). While this restored corporate profit shares, it created a chronic realization crisis. Suppressing variable labor wages crippled consumer demand growth ($g_Y \downarrow$), while financialization diverted corporate profits away from physical investment $g_K$ into stock buybacks and financial asset acquisition. 

Even though lower $\theta_t$ slowed potential capacity growth $g_{Y^p}$, aggregate demand growth $g_Y$ fell even faster. Thus, neoliberal restructuring resolved the Fordist supply-side profit squeeze only by replacing it with a chronic Post-Fordist demand-side realization crisis, trapping U.S. corporate capitalism in a regime of persistent excess capacity and secularly declining utilization.
