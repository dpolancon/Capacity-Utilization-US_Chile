---
type: analytical_note
status: future_research
stage_scope: post_dissertation
country: Chile
last_updated: 2026-08-12
tags: [future_research, corner_solution, mechanization, reprimarization, external_constraint]
---

# Formalizing the Corner Solution ($\bar{\kappa}_t$) Across Institutional Regimes

## 1. The Context of the Hypothesis

In the baseline econometric specifications for the Chilean case, the composite external threshold ($Z_t \le 0.425$) isolates the period where the external constraint binds ($D_t = 1$). During these specific years (e.g., 2005–2008), the conventional Okishio-type cost-minimization logic—whereby rising wage shares or falling profit rates induce capital intensification (higher $\kappa_t$)—breaks down or reverses. 

While a traditional structuralist account might expect the balance-of-payments bottleneck to manifest as rapid currency depreciation and runaway inflation, the empirical record of the 2000s commodity boom reveals a different phenomenon. Under a free-floating exchange rate regime, the immense influx of export revenues masked the underlying structural bottleneck. However, the bottleneck did not resolve through domestic capacity expansion; rather, it manifested as an **unproductive, rentier drain of the surplus** leading to **re-primarization** of the productive matrix.

## 2. Towards a Formalization of the Corner Solution

Future research should formalize this breakdown not merely as an econometric parameter shift, but as a bounded optimization problem where the firm hits a macroeconomic "corner solution" ($\bar{\kappa}_t$).

When $D_t = 1$, the economy's import capacity is structurally decoupled from its effective demand for capital accumulation. The theoretical proposition is that the capital composition gap, $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$, reaches an upper bound $\bar{\kappa}_t$. 

### The Rentier-Drain Mechanism

1. **Rent Appropriation over Accumulation**: During the commodity boom, surplus expands, but it is captured as rent rather than reinvested as productive machinery and equipment ($K^{\text{ME}}$).
2. **Deindustrialization / Re-primarization**: The relative price of commodities induces a reallocation of resources toward the primary sector (non-residential structures and extraction-related fixed capital, $K^{\text{NRC}}$) and away from complex manufacturing or machinery accumulation.
3. **The Boundary Condition**: The derivative of capital composition with respect to distributive variables, $\partial \kappa_t / \partial e_t$ (or $\partial \kappa_t / \partial \omega_t$), changes sign because firms are not responding to labor costs by mechanizing; they are responding to the primary-sector rent gradient. Mechanization is halted at $\bar{\kappa}_t$.

### Proposed Analytical Setup

Let the firm's objective function be modified to incorporate the structural rent gradient ($R_t$) and the external bottleneck ($Z_t$):

$$
\max \Pi_t = f(K^{\text{ME}}_t, K^{\text{NRC}}_t, L_t) - w_t L_t - p^{\kappa}_t K_t + R_t(Z_t)
$$

Subject to the external constraint:
$$
g_{K^{\text{ME}}} \le M_c(Z_t)
$$
where $M_c$ is the import capacity of the economy constrained by the primary export sector. When the constraint binds ($D_t = 1$), $K^{\text{ME}}$ cannot expand regardless of the wage share $\omega_t$ or exploitation rate $e_t$, forcing the economy into a corner solution where $\kappa_t \to \bar{\kappa}_t$. The surplus is instead funneled into rentier channels (financialization, real estate, or pure extraction).

## 3. Methodological Next Steps

1. **Analytical Derivation**: Formally derive the first-order conditions under the Kuhn-Tucker multiplier for the import capacity constraint. Show mathematically how the sign of the comparative statics (e.g., $\partial \kappa_t / \partial \omega_t$) flips when the multiplier is strictly positive.
2. **Empirical Extensions**: 
   - Integrate sector-level data differentiating between primary extractive sectors and manufacturing.
   - Trace the flow of funds (rent appropriation) vs. fixed capital formation during the 2005–2008 boom.
3. **Link to Re-primarization Literature**: Ground the formal model in the Latin American structuralist literature on Dutch Disease, re-primarization, and the political economy of rentierism.
