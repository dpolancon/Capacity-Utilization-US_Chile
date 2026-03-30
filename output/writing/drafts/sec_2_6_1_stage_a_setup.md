# §2.6.1 — Estimation
**Source authority:** `empirical_strategy_reduced_rank.md`
**Date drafted:** 2026-03-29
**Word count:** 426
**Self-check:** PASS
**Transition check:** Closes by noting the estimation setup is common to both countries; §2.6.2 reports US results, §2.6.3 reports Chile.

Stage A estimates the long-run capacity relation derived in §2.4 and recovers the latent utilization object $\widehat{\mu}_t$. The econometric framework is the Johansen (1988) maximum-likelihood procedure applied to the state vector $X_t = (y_t,\, k_t,\, \pi_t\, k_t)'$, where $y_t$ is log output, $k_t$ is log capital stock, and $\pi_t\, k_t$ is the distribution-capital interaction term.

The Johansen procedure embeds the long-run capacity relation within a vector error-correction model (VECM) of the form

$$\Delta X_t = \Pi X_{t-1} + \sum_{i=1}^{p-1} \Gamma_i \Delta X_{t-i} + \Phi D_t + \varepsilon_t,$$

where $\Pi = \alpha \beta'$ is the reduced-rank matrix that encodes the cointegrating relations, $\Gamma_i$ are short-run adjustment matrices, and $D_t$ collects deterministic components. The rank of $\Pi$ determines the number of cointegrating vectors. Under the identification of §2.4, the expected rank is $r = 1$: a single long-run relation ties output, capital, and the interaction term together, and the stationary residual of that relation is $\ln \mu_t$.

Rank determination proceeds through two complementary test sequences. The trace test evaluates $H_0\colon r \leq j$ against $H_1\colon r > j$ for $j = 0, 1, 2$, while the maximum-eigenvalue test evaluates $H_0\colon r = j$ against $H_1\colon r = j + 1$. Critical values follow Johansen and Juselius (1990), adjusted for the finite-sample correction of Reimers (1992) given the moderate sample lengths involved (roughly 60–70 annual observations for the US and Chile).

The deterministic specification is the restricted constant model: a drift term is absorbed into the cointegrating space rather than left unrestricted in the common trends. This choice reflects the theoretical prior that the long-run capacity relation admits a non-zero intercept — the constant $c$ in $y_t = c + \beta_1 k_t + \beta_2 (\pi_t k_t) + \xi_t$ — but that no deterministic linear trend should enter the cointegrating residual. Intuitively, $\ln \mu_t$ fluctuates around a mean but does not trend; the restricted constant ensures that the econometric specification respects this property.

Structural-break detection employs the Gregory and Hansen (1996) test for cointegration with an endogenous break at an unknown date. This is particularly relevant for Chile, where the 1973 military coup and the 1982 debt crisis represent candidate regime shifts that may alter the cointegrating parameters. For the US, the candidate break corresponds to the Fordist/post-Fordist transition around 1973. The GPY (2025) impossibility result — which proves that the cointegrating vector $\beta$ cannot be fully nonparametric — provides formal justification for maintaining constant cointegrating vectors within institutional regimes and testing for breaks at regime boundaries rather than estimating continuously time-varying parameters. The estimation setup described here is common to both countries; the following subsections report results for the US and Chile in turn.
