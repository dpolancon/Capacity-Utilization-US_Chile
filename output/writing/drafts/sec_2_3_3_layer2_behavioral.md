## §2.3.3 Layer 2: The Behavioral Identification

The accumulation identity established in §2.3.2 is exact. Taking logarithms of equation (2.y) preserves this exactness:

$$
\ln g_K \;=\; \ln \chi \;+\; \ln \pi \;+\; \ln \mu \;+\; \ln b
\tag{2.aa}
$$

Under the Cambridge closure $\chi = \bar{\chi}$, the recapitalization rate is a structural constant and $\ln \chi$ absorbs into the intercept. The three channels then carry unit elasticity: a one-percent increase in the profit share, in capacity utilization, or in capital productivity raises the accumulation rate by exactly one percent. This is not a behavioral claim --- it is the accounting benchmark that any investment function must be measured against.

The behavioral content enters when the recapitalization rate is permitted to respond to the same three channels. Let $\chi$ adjust log-linearly:

$$
\ln \chi \;=\; \eta_0 \;+\; \eta_1 \ln \pi \;+\; \eta_2 \ln \mu \;+\; \eta_3 \ln b
\tag{2.ab}
$$

Each $\eta_j$ registers the elasticity of the reinvestment decision with respect to the $j$-th channel --- the behavioral departure from the Cambridge benchmark where $\eta_j = 0$ for all $j$. Define $\beta_j \equiv 1 + \eta_j$, so that the unit-elasticity baseline is nested at $\beta_j = 1$. Substituting (2.ab) into (2.aa) yields the Layer-2 behavioral identification equation:

$$
\ln g_K \;=\; c \;+\; \beta_1 \ln \pi \;+\; \beta_2 \ln \mu \;+\; \beta_3 \ln b \;+\; \varepsilon
\tag{2.ac}
$$

| Coefficient | Accounting benchmark ($\beta_j = 1$) | Behavioral content ($\eta_j = \beta_j - 1$) |
|---|---|---|
| $\beta_1$ | Cambridge closure on distribution | $\chi$ elasticity w.r.t. $\pi$ |
| $\beta_2$ | Cambridge closure on demand | $\chi$ elasticity w.r.t. $\mu$ |
| $\beta_3$ | Cambridge closure on technology | $\chi$ elasticity w.r.t. $b$ |

The dual interpretation is the point. When $\beta_j = 1$, the $j$-th channel transmits to accumulation at exactly the rate the accounting identity prescribes --- the recapitalization rate is inert on that margin, and the Cambridge equation governs. When $\beta_j \neq 1$, the deviation $\eta_j$ measures how capitalists' reinvestment behavior amplifies ($\eta_j > 0$) or dampens ($\eta_j < 0$) the channel's accounting contribution. Layer 2 therefore provides two things simultaneously: coefficient interpretation for the full Weisskopf disaggregation that §2.7 estimates, and a formally precise benchmark --- the Cambridge closure --- against which every behavioral departure is identified. The Keynes--Robinson and Bhaduri--Marglin specifications are economically motivated compressions of these three channels, tested as Wald restrictions within the full disaggregation, not as algebraic reductions of equation (2.ac).

The restriction that disciplines the entire estimation architecture is the Okishio crisis-trigger test:

$$
H_0\!: \; \beta_2 = \beta_3
\tag{2.ad}
$$

The null states that the recapitalization elasticity with respect to capacity utilization equals the elasticity with respect to capital productivity --- that is, the two channels enter the reinvestment decision identically, and their distinct contributions collapse into the composite profit rate $r = \mu b \pi$. Rejection carries a precise structural implication: capacity utilization exerts an independent behavioral effect on recapitalization beyond its accounting role in the profit rate, and the gap $\eta_2 - \eta_3$ measures the magnitude of that independent effect. This is the formal condition under which the crisis trigger fires --- the condition under which demand-driven capacity shortfalls alter the pace of accumulation through a channel that the profit rate alone does not capture. Stage C (§2.7) tests this restriction empirically; the next sections construct the identification strategy that makes the test operational.
