# §2.6.4 — Derived Objects
**Source authority:** `RRR_Accumulation_Framework.md` §5
**Date drafted:** 2026-03-29
**Word count:** 235
**Self-check:** PASS
**Transition check:** Closes by noting these derived objects are Stage B inputs — handing off to §2.7 (accounting law) and §2.8 (behavioral estimation).

Once the cointegrating relation of §2.6 has been estimated and the rank-1 identification confirmed, the recovered utilization residual $\widehat{\ln \mu_t}$ generates two further structural objects by construction. These objects are not re-estimated in Stage B; they are passed forward as conditioning variables for the behavioral accumulation law.

**Definition 1 (Recovered Productive Capacity).** The log of productive capacity is

$$\hat{y}_t^p = y_t - \widehat{\ln \mu_t}. \tag{2.10a}$$

This is simply the output decomposition $y_t = y_t^p + \ln \mu_t$ of §2.3, solved for $y_t^p$ after substituting the Stage A estimate of utilization. The recovered series $\hat{y}_t^p$ is the productive-capacity path implied by the cointegrating relation — the output level that would prevail if $\mu_t = 1$.

**Definition 2 (Recovered Capital Productivity at Normal Capacity).** Capital productivity at normal capacity is

$$\widehat{\ln B_t} = \hat{y}_t^p - k_t, \qquad \widehat{B}_t = \exp(\hat{y}_t^p - k_t). \tag{2.10b}$$

The recovered $\widehat{B}_t$ measures the efficiency of the capital stock evaluated at normal utilization, net of cyclical demand fluctuations. Its trajectory over time is the empirical counterpart of the unbalanced-growth dynamics discussed in §2.3: when $\theta(\Lambda) < 1$, $\widehat{B}_t$ declines secularly as capital accumulates faster than productive capacity expands.

The two-stage architecture is load-bearing at this point. An ARDL investment equation of the type estimated in Stage B cannot perform Stage A's identification — it can describe how accumulation responds to utilization, but it cannot recover what utilization is. The utilization object $\widehat{\mu}_t$ and the capital-productivity object $\widehat{B}_t$ are available cleanly only after the cointegrating relation has been estimated and the rank-1 identification confirmed. §2.7 derives the accounting law that decomposes accumulation into its structural components, and §2.8 specifies the behavioral law that uses these recovered objects as inputs.
