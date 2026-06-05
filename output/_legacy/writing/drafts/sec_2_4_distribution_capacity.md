# §2.4 — Distribution-Conditioned Capacity: The Interaction Term
**Source authority:** `RRR_Accumulation_Framework.md` §1–2
**Date drafted:** 2026-03-29
**Word count:** 537
**Self-check:** PASS

The confinement identity derived in §2.3 recovers capacity utilization as the deviation of realized output from the productive-capacity manifold, but it leaves the transformation elasticity $\theta(\Lambda)$ as an abstract regime parameter. To take the identity to data, one needs an empirically tractable specification that links $\theta$ to observable magnitudes. This section introduces the distribution-conditioned capacity relation, in which the transformation elasticity varies with the profit share, and derives the rank-1 identification equation that makes $\mu_t$ recoverable from observed time series.

## Profit share and the interaction term

The exploitation rate $e_t$ maps into the profit share through the identity

$$\pi_t = \frac{e_t}{1 + e_t}, \tag{2.5}$$

where $\pi_t \equiv \Pi_t / Y_t$ is the share of gross profits in output. Define the interaction term

$$z_t \equiv \pi_t\, k_t, \tag{2.6}$$

which is a constructed object — the product of the profit share and the log capital stock — not a primitive state variable. The interaction term serves as the empirical proxy for the distribution-dependent component of $\theta(\Lambda) \cdot k_t$ in the cointegrating space. Its role is to rotate the long-run manifold so that the capacity transformation elasticity can respond to changes in distribution without requiring a separate structural equation for $\theta$.

## The long-run capacity relation

Embedding the interaction term into the cointegrating space yields the long-run capacity relation:

$$y_t = c + \beta_1\, k_t + \beta_2\, (\pi_t\, k_t) + \xi_t, \qquad \xi_t \equiv \ln \mu_t. \tag{2.7}$$

The parameters $\beta_1$ and $\beta_2$ are structural coefficients of the cointegrating relation. They are not behavioral choices and they are not estimated from an optimization problem; they are the long-run parameters of the capacity manifold, pinned by the institutional space $\Lambda$ within which accumulation proceeds. The residual $\xi_t$ is log capacity utilization, and the identifying assumption is that $\xi_t$ is stationary — that is, utilization fluctuates around the capacity manifold but does not drift permanently away from it.

The endogenous long-run transformation elasticity is then

$$\theta_t = \beta_1 + \beta_2\, \pi_t. \tag{2.8}$$

This is the empirical proxy for the general $\theta(e \mid \Lambda)$ introduced in §2.3: the transformation elasticity is not a fixed number but varies with the prevailing distribution of income. When the profit share rises, $\theta_t$ shifts by $\beta_2$ — and the sign and magnitude of $\beta_2$ determine whether higher exploitation raises or depresses the rate at which capital accumulation translates into productive capacity.

## Proposition 2 (Rank-1 Identification)

*If the residual $\xi_t$ from the long-run capacity relation (2.7) is $I(0)$, then the recovered capacity utilization series is*

$$\widehat{\ln \mu_t} = y_t - \hat{c} - \hat{\beta}_1\, k_t - \hat{\beta}_2\, (\pi_t\, k_t). \tag{2.9}$$

Three features of this identification deserve emphasis. First, $\theta$ remains upstream: the parameters $\beta_1$ and $\beta_2$ are structural parameters of the cointegrating relation, not behavioral margins subject to agent optimization. The capacity transformation elasticity is a property of the institutional regime, not a choice variable. Second, the interaction term $z_t = \pi_t\, k_t$ rotates the cointegrating space — it is a constructed object needed to represent $\theta(e) \cdot k$ within the linear structure of the Johansen VECM. Without it, the cointegrating relation would impose a constant $\theta = \beta_1$, collapsing the distribution-conditioned specification back to the regime-invariant case. Third, the Increasing Intensity of Conflict Schedule (IICS) is a falsifiable hypothesis, not an imposed condition. The sign of $\beta_2$ is unrestricted: if $\beta_2 > 0$, then higher exploitation raises $\theta_t$ and distributional polarization expands the economy's capacity-generating ability per unit of capital; if $\beta_2 < 0$, the opposite holds; if $\beta_2 = 0$, distribution does not condition the transformation elasticity and the specification reduces to the confinement identity of §2.3 with a constant slope. The data adjudicate. The next section embeds this identification in the center-periphery comparison that structures the empirical work of the chapter.
