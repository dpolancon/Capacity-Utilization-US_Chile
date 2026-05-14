# §2.8.1 — Specification
**Source authority:** `RRR_Accumulation_Framework.md` §7
**Date drafted:** 2026-03-29
**Word count:** 449
**Self-check:** PASS

The accounting law derived in §2.7 established that the gross accumulation rate decomposes as $\iota_t = \beta_t\, r_t$, where $\beta_t = I_t / \Pi_t$ is the recapitalization rate. The behavioral question is whether $\beta_t$ is constant. If it is, accumulation follows the accounting identity mechanically and the recapitalization rate absorbs into the intercept of any log-linear specification. If it is not, then something drives capitalists to reinvest more or less of the surplus than the accounting decomposition alone would predict. This section specifies the behavioral accumulation law that takes up that question.

## The behavioral recapitalization response

Let the recapitalization rate respond to the same three channels that compose the profit rate:

$$\ln \beta_t = \eta_0 + \eta_1\, \ln \pi_t + \eta_2\, \ln \mu_t + \eta_3\, \ln B_t. \tag{2.16}$$

Each $\eta_j$ measures how much the recapitalization rate deviates from constancy in response to changes in distribution ($\pi_t$), demand conditions ($\mu_t$), and the structural transformation of capital productivity ($B_t$). Substituting (2.16) into the log of the accounting identity $\iota_t = \beta_t\, \pi_t\, \mu_t\, B_t$ yields the behavioral accumulation law:

$$\boxed{\ln \iota_t = c + b_1\, \ln \pi_t + b_2\, \ln \widehat{\mu}_t + b_3\, \ln \widehat{B}_t + \varepsilon_t.} \tag{2.17}$$

The coefficients have the structure $b_j = 1 + \eta_j$, so that each carries a dual interpretation:

| Coefficient | Accounting reading | Behavioral reading |
|---|---|---|
| $b_1$ | Profit-share elasticity of accumulation | $\eta_1 = b_1 - 1$: distribution response |
| $b_2$ | Utilization elasticity of accumulation | $\eta_2 = b_2 - 1$: demand response |
| $b_3$ | Capital-productivity elasticity of accumulation | $\eta_3 = b_3 - 1$: structural response |

When $b_j = 1$, the recapitalization rate does not respond to channel $j$ and the accounting identity governs that margin. When $b_j \neq 1$, the deviation $\eta_j = b_j - 1$ is the behavioral content — the extent to which capitalists' reinvestment decisions amplify ($\eta_j > 0$) or partially offset ($\eta_j < 0$) the accounting channel.

## Two-stage conditioning

A critical architectural point governs the estimation of (2.17). The regressors $\widehat{\mu}_t$ and $\widehat{B}_t$ are not observed variables — they are Stage A outputs, recovered from the cointegrating relation estimated in §2.6 and constructed via the definitions of §2.6.4. Stage B does not re-estimate utilization or capital productivity; it takes them as given conditioning variables. The behavioral accumulation law is therefore a conditional behavioral module: it describes how realized accumulation responds to profitability once the structural identification problem has been solved upstream. An ARDL equation cannot perform Stage A's identification — it can only estimate the recapitalization response conditional on Stage A's recovered objects.

## Estimation framework

The behavioral accumulation law (2.17) is estimated via the ARDL bounds-testing procedure of Pesaran, Shin, and Smith (2001). The bounds test is appropriate here because the regressors include a mixture of $I(0)$ and $I(1)$ variables: $\ln \pi_t$ and $\ln \widehat{B}_t$ are plausibly $I(1)$, while $\ln \widehat{\mu}_t$ is $I(0)$ by construction from the rank-1 identification. The PSS procedure does not require pre-classification of the integration order of each regressor, which makes it robust to the generated-regressor character of $\widehat{\mu}_t$ and $\widehat{B}_t$. The investment function in this framework is profit-oriented and market-share-oriented: the three channels capture the profit-share incentive, the demand signal through utilization, and the structural conditions of capital productivity that determine the long-run return to reinvestment.
