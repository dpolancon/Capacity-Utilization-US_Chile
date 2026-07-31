---
type: paper_facing
status: pre-draft note
country: US
stage_scope: S33_BreakAware_IMOLS
last_updated: 2026-07-30
depends_on:
  - chapter2_vault/03_econometrics/standalone_kappa_exclusion_assessment.md
  - chapter2_vault/03_econometrics/S02_StructuralBreak_Protocol.md
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
  - chapter2_vault/03_econometrics/E18_Kappa_Path_Derivative_LOESS_Lock.md
  - us_specB_imols_capital_disaggregation_report_v7
layer: empirical_narrative
scope: section 4
---

# Empirical Narrative Synthesis: Specification B4 and the Status of the Mechanization Gap

Companion to the Spec B v7 report. Covers what Specification B4 is, what implementing it actually
showed, and what remains open. Every figure here comes from
`output/US/BREAK_AWARE_IMOLS/S33D_IMOLS_SPEC_B/csv/specB_B3_vs_B4_collinearity_comparison.csv`,
produced by `codes/US_S33D_break_interacted_imols_specB.R`.

## 1. The specification

Specification B3 carries the mechanization gap $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$ three
times: as a level, as $\kappa_t \omega_{t-1}$, and as $\kappa_t p_t^\kappa$. **Specification B4** drops
the standalone level and retains the gap only through its two conditioning channels:

$$y_t^{\text{NFC}} = \alpha + \theta_{\text{NRC}} k_t^{\text{NRC}} + \beta_{p^\kappa} p_t^\kappa + \beta_\omega \omega_{t-1} + \theta_{\omega\kappa}(\kappa_t \cdot \omega_{t-1}) + \theta_{\kappa p^\kappa}(\kappa_t \cdot p_t^\kappa) + \boldsymbol{\gamma}'\mathbf{D}_t + u_t$$

It is not part of the S02 taxonomy; it is added under
[[standalone_kappa_exclusion_assessment]] and implemented as a `use_standalone_kappa` flag so the
existing taxonomy loops, gate ledger, and integrity counts scale without a parallel code path.

## 2. Marxian grounding: the gap is a channel, not a trend

The warrant for B4 is theoretical before it is econometric. In Okishio (1961), Foley & Michl (1999)
and Shaikh (2016), capitalists do not raise the machinery-to-structures ratio out of a
distribution-neutral propensity to mechanize. Technical choice is driven by the cost of labour
relative to the cost of machines — by distributional conflict ($\omega_{t-1}$) and relative asset
prices ($p_t^\kappa$). On that reading $\kappa_t$ has no autonomous effect on productive capacity to
estimate: it is the *channel through which distribution and prices act*, and its standalone level has
no behavioural referent in the model being estimated.

The standard objection is that omitting a main effect while keeping its interaction induces
omitted-variable bias. That objection presumes the main effect is a primitive of the data-generating
process. The Marxian reading denies exactly that premise, which is why B4 is a specification claim
rather than a convenience. This argument stands independently of any diagnostic and is the part of
the case that survived verification untouched.

## 3. What implementing it actually showed

Three findings, of which only one matches the original assessment's headline.

**The precision gain on plant scale is the robust result.** $\hat\theta_{\text{NRC}}$ rises and
tightens in all four window × interaction pairings: Fordist 0.33 ($t = 2.04$) → 0.45 ($t = 3.19$);
Fordist interacted 0.61 ($t = 3.58$) → **0.82 ($t = 8.68$)**; Post-Fordist 0.54 ($t = 6.69$) → 0.59
($t = 7.69$); Post-Fordist interacted 0.77 ($t = 6.64$) → 0.62 ($t = 9.35$). Nonresidential structures
are an exceptionally clean extensive-scale anchor once they are not competing with a collinear gap
level. This survives every specification cut and is the finding to lead with.

**Conditioning improves everywhere but clears the threshold once.** The standardized condition number
falls in every cell — Fordist uninteracted 82.23 → **21.18**, Post-Fordist uninteracted 42.94 → 33.60,
Fordist interacted 361.44 → 142.44, Post-Fordist interacted 230.69 → 109.87. Only the first clears
$\text{CN} \le 30$. B4 materially improves the design without, on its own, delivering a
well-conditioned interacted model.

**The collinearity is real but the binding pair is not the expected one.** Measured directly, in
Fordism $\text{corr}(\kappa_t, \kappa_t p_t^\kappa) = +0.9934$ — near-perfect — while
$\text{corr}(\kappa_t, \kappa_t\omega_{t-1})$ is only $-0.2392$. In Post-Fordism both bind, at
$-0.9335$ and $-0.8792$. The term that makes the standalone level redundant is therefore the *price*
interaction before 1973 and both interactions after 1974. An account resting on the wage interaction
alone mis-locates the mechanism, and this is the substantive correction the implementation forced.

## 4. Two things that did not hold

The assessment claimed that excluding standalone $\kappa_t$ restores a *positive* choice-of-technique
elasticity in Post-Fordism, $\hat\theta_{\omega\kappa} = +12.98$. **It does not.** Under B4 the
estimate is $-12.30$ ($t = -1.80$) uninteracted and $-58.34$ ($t = -2.90$) interacted, and it is
negative in all sixteen permutations of the break-shift combinatorics grid ($-11.0$ to $-57.7$). The
wage-squeeze interaction is negative in Post-Fordism under every specification the pipeline can
produce. A sign flip *does* occur under B4, but in **Fordism** and in both interaction terms:
$\hat\theta_{\omega\kappa}$ goes $-2.12 \to +3.50$ (both insignificant) and
$\hat\theta_{\kappa p^\kappa}$ goes $-1.79$ ($t = -1.35$) $\to +2.29$ ($t = 3.00$), the latter becoming
significant.

There is also an unreported cost: $\hat\sigma_u$ **rises** in every cell (0.051 → 0.060, 0.041 →
0.049, 0.035 → 0.037, 0.025 → 0.031). Dropping a regressor buys conditioning at the price of fit. B4
should be presented as that trade, not as a free improvement. Cointegration itself is untouched —
$C_{\text{Shin}}$ stays between 0.020 and 0.035 under both specifications, well inside the 0.095
bound.

## 5. What B4 does not fix

**The integration-order gate is unchanged.** The Lee-Strazicich stage returns `persistent_I2_risk` for
$\kappa_t$ in the Post-Fordist window. Removing the level from the *regression* does not change the
*series*, so every Post-Fordist estimate — B3 and B4 alike — remains on the **exploratory** break-aware
route. Only the Fordist window is formally gated. Any claim built on a Post-Fordist B4 coefficient
carries that limitation with it.

**The transformation elasticity is not re-derived.** $\theta_t^{\text{SpecB}}$ runs through the E18
LOESS path-derivative machinery in `COMMON_S40_specB_imols_estimation.R`, not the break-aware stage,
and re-deriving it under B4 would require the full 505-model grid re-estimated on B4 parameters. The
chapter's existing figures — average $0.41$, range $[-0.27, 0.94]$, turning negative post-2000 — remain
B3-based. **No B4-conditioned trajectory is asserted anywhere in this pass**, and the overaccumulation
claim continues to rest on B3.

## 6. Open

- Re-derive $\theta_t^{\text{SpecB}}$ under B4 via E18 path derivatives, then revisit the era averages
  and the sign of the post-2000 trajectory.
- Run the §7.5 break-shift combinatorics grid on a B4 base; it currently grids B3 only.
- Decide whether B4 or B3 is the canonical Spec B for the chapter. This pass reports both, and the
  case for B4 is strongest in Fordism (where it clears $\text{CN} \le 30$ and sharpens
  $\theta_{\text{NRC}}$ most) and weakest in the interacted Post-Fordist model.
- Investigate whether the Post-Fordist $I(2)$ risk in $\kappa_t$ is better handled by the
  investment-flow respecification S03 §2C prescribes.
