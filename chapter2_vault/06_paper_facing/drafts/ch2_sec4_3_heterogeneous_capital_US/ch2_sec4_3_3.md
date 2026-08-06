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
role: Specification B capacity recovery and long-run dynamics
stage: paper-assembly
tags:
  - chapter2/paper-facing
scope: chapter2
priority: core
---

## Capacity Recovery and Long-Run Dynamics

This section applies preferred **Model M2.19a** (Shaikh-Tonak Tier 1 NVA Basis) to reconstruct the historical paths of potential capacity output ($Y_t^p$), capacity utilization ($\mu_t = Y_t / Y_t^p$), and the aggregate heterogeneous transformation elasticity ($\theta_t^{\text{SpecB}}$) for the U.S. Non-Financial Corporate sector over 1929–2024.

**Bottom Line Up Front (BLUF).** The empirical reconstruction under Specification B confirms that disaggregating capital into non-residential structures ($k^{\text{NRC}}$) and machinery ($k^{\text{ME}}$) reinforces the core findings of the baseline model while revealing the precise mechanism of overaccumulation. The aggregate transformation elasticity $\theta_t^{\text{SpecB}}$ remains strictly below 1.00 ($\theta_t^{\text{SpecB}} \in [0.42, 0.47]$), establishing that U.S. corporate accumulation is trapped in permanent capital overaccumulation.

**Capacity Reconstruction Methodology (Protocol D03).** Following Protocol D03, level-anchoring is evaluated relative to the 1973 Federal Reserve Board capacity peak ($\mu_{1973} = 1.00$). The reconstructed potential capacity output path matches observed value added at the 1973 pinch point, allowing clean extrapolation of capacity utilization without relying on regression residuals.

1. **Structural Capital Overaccumulation under Heterogeneous Capital**: The total effective capacity elasticity of capital $\theta_{\text{tot},t} = \hat{\theta}_{\text{NRC}} + \hat{\theta}_{\kappa,t}$ remains bounded between $0.48$ and $0.63$ across the entire 1929–2024 window. Because $\theta_{\text{tot},t}$ is strictly less than 1.00, expanding physical corporate capital yields less than a proportional increase in potential capacity output. U.S. corporate capitalism operates permanently within a structural regime of capital overaccumulation.
2. **Effective Wage Pressure and Dynamic Mechanization Payoff**: Modeling the mechanization elasticity as $\theta_{\kappa,t} = \hat{\theta}_{\kappa} + \hat{\theta}_{\omega\kappa} \text{inter\_ortho}_{\omega\kappa, t}$ demonstrates that technological capacity expansion is driven by the interaction of variable labor costs and corporate financial retention. Under Fordism, high productive wage shares combined with low financial overhead ($\iota \approx 0$) forced defensive mechanization, driving rapid potential capacity growth ($g_{Y^p}$). Under Post-Fordism, wage suppression and financialization ($\iota \uparrow$) depressed effective wage pressure, slowing potential capacity expansion.
3. **Institutional Realization Crisis**: Reconstructed capacity utilization ($\hat{\mu}_t$) exposes the fundamental macroeconomic contradiction of neoliberalism. Under Fordism (1929–1973), utilization cycled around normal capacity ($\hat{\mu} \in [0.75, 1.00]$) outside the Great Depression trough ($\hat{\mu}_{1933} = 0.32$) and WWII mobilization peak ($\hat{\mu}_{1944} = 0.78$). Under Post-Fordism (1974–2024), wage suppression restored profit shares but crippled consumer demand growth ($g_Y$), while financialization diverted corporate profits away from physical investment. Consequently, capacity utilization suffered a secular downward drift, reaching deep structural troughs in 1982 ($\hat{\mu} \approx 0.58$), 2009 ($\hat{\mu} \approx 0.65$), and 2020 ($\hat{\mu} \approx 0.68$).

## 2. Capacity Reconstruction Methodology (Protocol D03)

Estimating Model M2.19a identifies the long-run cointegrating parameters $\hat{\theta}_{\text{NRC}}$, $\hat{\theta}_{\kappa}$, and $\hat{\theta}_{\omega\kappa}$. Converting these estimates into an absolute capacity utilization path requires level-anchoring under **Protocol D03**.

We anchor the capacity path at $t^* = 1973$, setting $\mu_{1973} = 1.00$ (100%). The year 1973 represents the historical peak in the Federal Reserve Board manufacturing capacity series and marks the institutional divide between post-war Fordism and neoliberal restructuring.

The state-dependent total capacity elasticity is evaluated as:

$$\theta_{\text{tot},t} = \hat{\theta}_{\text{NRC}} + \hat{\theta}_{\kappa} + \hat{\theta}_{\omega\kappa} \text{inter\_ortho}_{\omega\kappa, t}$$

where $\hat{\theta}_{\text{NRC}} = 0.613$, $\hat{\theta}_{\kappa} = 0.313$, and $\hat{\theta}_{\omega\kappa} = -15.987$ from Model M2.6a.

Log potential capacity output $y_t^p = \ln Y_t^p$ is constructed directly relative to the 1973 pinch point:

$$y_t^p = y_{1973} + \hat{\theta}_{\text{NRC}} (k_t^{\text{NRC}} - k_{1973}^{\text{NRC}}) + \hat{\theta}_{\kappa} (\kappa_t - \kappa_{1973}) + \hat{\theta}_{\omega\kappa} (\text{inter\_ortho}_{\omega\kappa, t} - \text{inter\_ortho}_{\omega\kappa, 1973})$$

Reconstructed capacity utilization is calculated as observed real gross value added relative to potential capacity:

$$\hat{\mu}_t = \frac{Y_t}{\hat{Y}_t^p} = \exp(y_t - y_t^p)$$

By construction, $\hat{\mu}_{1973} = 1.000000$ exactly, fully adhering to Protocol D03.

## 3. Heterogeneous Overaccumulation Regime ($\theta_{\text{tot},t} < 1.00$)

Disaggregating capital into non-residential structures and machinery confirms that the U.S. corporate economy operates permanently within a regime of capital overaccumulation ($\theta_{\text{tot},t} < 1.00$).

Across the 1929–2024 century, $\theta_{\text{tot},t}$ averages approximately $0.55$, remaining far below the unit elasticity threshold ($\theta = 1.00$). Diminishing returns to capital deepening reflect the rising organic composition of capital: expanding physical machinery equipment requires an increasing share of gross investment merely to replace depreciated assets, maintain complex technical systems, and absorb administrative overhead, rather than generating proportional additions to net output capacity.

## 4. Institutional Periodization: Fordism (1929–1973) vs. Post-Fordism (1974–2024)

Reconstructed capacity utilization $\hat{\mu}_t$ illustrates the contrasting macroeconomic dynamics of the two post-war institutional eras.

### A. The Fordist Era (1929–1973): Supply-Side Dynamism and Demand Alignment
The Fordist era combined strong institutional wage growth, low corporate financialization ($\iota < 0.04$), and active state macroeconomic management.

1. **Great Depression Collapse (1929–1933)**: The collapse of real aggregate demand pushed capacity utilization down to a historic trough of $\hat{\mu}_{1933} = 31.8\%$.
2. **Wartime Industrial Mobilization (1939–1944)**: World War II state direction pushed existing plant infrastructure to operate beyond normal capacity design limits, driving utilization to $\hat{\mu}_{1944} = 77.8\%$.
3. **Golden Age Stability (1947–1966)**: Institutionalized wage growth sustained robust consumer demand ($g_Y$), matching rapid potential capacity growth ($g_{Y^p}$). Utilization cycled in a stable band between $60\%$ and $75\%$.
4. **Late-Fordist Profit Squeeze (1967–1973)**: Tight labor markets pushed wage shares up, inducing corporate firms to accelerate mechanization. Rapid capacity expansion pushed utilization to its structural peak of $\hat{\mu}_{1973} = 100\%$.

### B. Post-Fordist Neoliberal Restructuring (1974–2024): Financialization and Realization Crisis
Neoliberal policy responded to the Fordist profit squeeze by crushing collective bargaining, suppressing real wages, and deregulating financial markets.

1. **Volcker Monetary Disinflation (1979–1982)**: Severe interest rate hikes induced a sharp industrial contraction, driving utilization down to $\hat{\mu}_{1982} = 58.1\%$.
2. **Neoliberal Squeeze and Financial Diversion**: Wage suppression reduced the productive wage share, while corporate asset allocation shifted heavily toward Intellectual Property Products and financial assets ($\iota$ rose above $15\%$). This dual squeeze suppressed effective wage pressure $(1-\iota)\omega$, slowing potential capacity expansion ($g_{Y^p}$).
3. **Secular Realization Crisis**: Although lower capacity growth $g_{Y^p}$ reduced supply expansion, aggregate demand growth $g_Y$ fell even faster due to stagnant wage incomes and fiscal austerity. Consequently, capacity utilization suffered a secular downward trend across successive business cycles ($\hat{\mu}_{1989} = 78.4\%$, $\hat{\mu}_{2000} = 81.2\%$, $\hat{\mu}_{2007} = 75.1\%$, $\hat{\mu}_{2020} = 68.1\%$).

## 5. Contradictory Tendencies of Capitalist Accumulation

The dynamic law of motion for capacity utilization:

$$g_{\mu,t} = g_{Y,t} - g_{Y^p,t} = g_{Y,t} - (\hat{\theta}_{\text{NRC}} g_{K^{\text{NR}},t} + \theta_{\kappa,t} g_{\kappa,t})$$

encapsulates the core structural contradiction of modern capitalism:

Under Fordism, wage growth stimulated technological dynamism ($\theta_{\kappa,t} \uparrow$), expanding potential capacity output. When aggregate demand growth matched capacity expansion, utilization remained stable near normal levels. Under Post-Fordism, capital resolved the Fordist supply-side profit squeeze by suppressing wages and diverting liquidity into financial assets. While this restored corporate profit shares, it created a chronic demand-side realization crisis. Wage suppression crippled consumer demand growth ($g_Y$), trapping corporate capitalism in a regime of persistent excess capacity and secularly declining utilization.
