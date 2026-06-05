# §2.3 — Structural Primitives: Production, Capacity, and Unbalanced Growth
**Source authority:** `capital_accumulation_dynamics_v5.md`
**Date drafted:** 2026-03-29
**Word count:** 606

This section establishes the accounting scaffold on which all subsequent identification and estimation rests. Every relation derived here is a definition or an identity; no behavioral equation is imposed until §2.7. The reader should treat each step as a manipulation of national-accounts magnitudes, not as a claim about agent optimization.

## Production structure

The productive apparatus operates under a Leontief technology with fixed technical coefficients:

$$Y_t = \min(B_t K_t,\; A_t L_t),$$

where $Y_t$ is aggregate output, $K_t$ is the capital stock, $L_t$ is employment, $B_t$ is capital productivity at normal capacity, and $A_t$ is labor productivity at normal capacity. Both constraints bind simultaneously when the economy operates at normal capacity — that is, when capacity utilization equals unity. In general, however, realized output falls short of or overshoots productive capacity, and the ratio of the two defines the central object of the chapter.

## Output decomposition

Let $Y_t^p \equiv B_t K_t$ denote productive capacity — the maximum output sustainable at normal utilization of the installed capital stock. Capacity utilization is then

$$\mu_t \equiv \frac{Y_t}{Y_t^p},$$

so that realized output decomposes as $Y_t = \mu_t\, Y_t^p$. Taking logarithms and writing $y_t \equiv \ln Y_t$, $y_t^p \equiv \ln Y_t^p$, one obtains

$$y_t = y_t^p + \ln \mu_t. \tag{2.1}$$

This is a tautology: log output equals log productive capacity plus log utilization. Its analytical content emerges only once productive capacity is given independent structure.

## Capital productivity at normal capacity

By definition, capital productivity at normal capacity is

$$B_t \equiv \frac{Y_t^p}{K_t}, \qquad \ln B_t = y_t^p - k_t, \tag{2.2}$$

where $k_t \equiv \ln K_t$. Equation (2.2) records how the capacity-to-capital relationship evolves over time. If $B_t$ is constant, capital deepening translates one-for-one into capacity expansion. If $B_t$ falls — as it does under mechanization regimes that substitute capital for labor without proportional capacity gains — then the economy requires progressively more capital per unit of productive capacity.

## The unbalanced-growth closure

The link between capital accumulation and productive capacity is governed by the capacity transformation elasticity $\theta$, an upstream regime parameter pinned by the institutional space $\Lambda$:

$$y_t^p = \theta(\Lambda)\, k_t. \tag{2.3}$$

This is a growth-rate relation, not a level production function: it states that a one-percent increase in the log capital stock translates into a $\theta$-percent increase in log productive capacity. The parameter $\theta(\Lambda)$ is not derivable from any first-order condition and is not a behavioral choice. It summarizes the structural conditions — the prevailing technology regime, the composition of investment, the institutional arrangements governing capital allocation — under which capital accumulation is transformed into productive capacity. When $\theta = 1$, capital and capacity grow at the same rate: this is the Harrodian benchmark, the knife-edge that existing capacity utilization measures impose by construction. The general case is $\theta \neq 1$. Under-mechanization ($\theta > 1$) implies that capital accumulation generates more than proportional capacity expansion; over-mechanization ($\theta < 1$) implies that the economy accumulates capital faster than it creates productive capacity, so that the capital-output ratio rises secularly.

## Proposition 1 (Confinement Identity)

*If output decomposes as in (2.1) and productive capacity follows (2.3), then capacity utilization satisfies*

$$\ln \mu_t = y_t - \theta(\Lambda)\, k_t. \tag{2.4}$$

*Proof.* Substitute (2.3) into (2.1): $y_t = \theta(\Lambda)\, k_t + \ln \mu_t$. Rearranging yields (2.4). $\square$

The confinement identity is the core identification object of the chapter. Three features merit emphasis. First, it is pure accounting: no behavioral assumption has been invoked, only the decomposition of output into capacity and utilization and the definition of the capacity transformation elasticity. Second, when $\theta \neq 1$ the identity implies persistent structural disequilibrium in the capital-output ratio — the economy does not settle on a balanced-growth path, and the deviation of $\theta$ from unity measures the degree of structural imbalance. Third, the Harrodian benchmark $\theta = 1$ is not the default but the special case: imposing it amounts to assuming away precisely the structural content that this chapter seeks to recover.

To take the confinement identity to data, one requires an empirically tractable specification of $\theta$. The next section introduces the distribution-conditioned capacity relation, in which the transformation elasticity varies with the profit share, and derives the rank-1 identification equation that makes $\mu_t$ recoverable from observed time series.
