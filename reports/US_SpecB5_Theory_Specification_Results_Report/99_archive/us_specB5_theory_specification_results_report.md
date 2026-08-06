# DISSERTATION PROGRESS REPORT
## Chapter 2: From the Okishio Viability Condition to a Testable Capacity Equation (Specification B5)

**Author:** Diego Polanco (Department of Economics, UMass Amherst)
**Advisor:** Michael Ash
**Date:** July 2026
**Compiled artifact:** `us_specB5_theory_specification_results_report.pdf`
**Estimation stage:** `codes/US_S33G_specB5_theory_consistent_full_sample.R`
**Supersedes for the break-interacted results:** `us_specB_imols_capital_disaggregation_report_v7.pdf` (retained unmodified)

---

## 1. Introduction

Marxian theories of technical change make a sharp claim about capacity: the productive potential of a
capital stock is not an engineering constant but the outcome of a cost-minimizing choice made under
distributive and price pressure. If that claim is right, the terms through which distribution enters a
capacity equation are structural parameters, not controls. Most empirical work treats them as
controls, and the resulting interaction terms then look like specification search.

This paper examines whether the Okishio viability condition, formalized in Section 3.2 of this
chapter, licenses a specific cointegrating capacity equation for the United States over 1929–2024, and
whether that equation survives estimation. I derive the estimating equation from the firm's
cost-surplus problem rather than positing it, estimate it by Integrated Modified OLS under the E10V
estimator lock, and report the full centering triad rather than a single preferred model. The central
result is negative and worth stating immediately: **the theory imposes two sign restrictions, and no
estimated specification satisfies both at once.** The uninteracted model recovers the wage-savings
dividend ($\hat\gamma_1 = 4.20 > 0$) but reverses the relative price penalty ($\hat\gamma_2 = -1.00 <
0$); the break-interacted model recovers the price penalty ($\hat\gamma_2 = 0.56 > 0$) but reverses the
wage dividend ($\hat\gamma_1 = -9.69 < 0$). The mechanism the theory describes is not jointly
identified in this data.

Two subsidiary findings support that reading. The extensive scale parameter $\theta_{NRC}$ is sharply
and stably estimated at 0.59 ($t = 8.09$), varying by 1.8 percent across centering regimes, so the
failure is specific to the state-dependent channel and not general to the design. And the
wage-mechanization structural break at 1969, which an earlier specification reported as significant,
does not survive a correction to the interaction span ($t = 1.31$).

Notation used throughout: $y^{NFC}_t$ is log real non-financial corporate value added; $k^{NRC}_t$ and
$k^{ME}_t$ are log real stocks of nonresidential structures and of machinery and equipment;
$\kappa_t \equiv k^{ME}_t - k^{NRC}_t$ is the **mechanization gap**; $p^\kappa_t \equiv \ln P^{ME}_t -
\ln P^{NRC}_t$ is the log **relative price** of machinery to structures; and $\omega_{t-1}$ is the
lagged wage share.

---

## 2. Descriptive grounding

The raw series carry a fact that constrains any account of the mechanization decision. Table 1 reports
mean annual changes; for the log levels these are growth rates, and for $\kappa_t$ and $p^\kappa_t$,
which are log ratios, they are divergence rates between two series.

### Table 1: Mean annual change, by era

| Series | Full sample 1929–2024 | Fordist 1929–1973 | Post-Fordist 1974–2024 |
|---|---:|---:|---:|
| Corporate value added ($y^{NFC}$), % p.a. | 3.89 | 4.93 | 3.12 |
| Nonresidential structures ($k^{NRC}$), % p.a. | 5.76 | 5.46 | 5.72 |
| Machinery and equipment ($k^{ME}$), % p.a. | 6.21 | 6.95 | 5.30 |
| Mechanization gap ($\kappa$), pp p.a. | 0.45 | **1.49** | **−0.43** |
| Relative price ($p^\kappa$), pp p.a. | −0.69 | **0.90** | **−2.03** |
| Wage share ($\omega$), pp p.a. | −0.10 | −0.05 | −0.17 |

Source: `output/US/BREAK_AWARE_IMOLS/S33H_DESCRIPTIVE/csv/specB_descriptive_growth_rates.csv`.

Read the last two rows together. During Fordism the relative price of machinery **rose** 0.90 points a
year while the mechanization gap **widened** 1.49 points a year. After 1974 the relative price
**collapsed** at 2.03 points a year while the gap **narrowed** 0.43 points a year. Machinery became
dramatically cheaper relative to structures, and firms responded by slowing the accumulation of
machinery relative to plant.

That co-movement is positive in both eras, and Section 3 predicts it should be negative. The puzzle is
visible in the data before any estimator touches it, which is why it belongs here rather than in a
robustness appendix. Figures 1 through 3 — `fig_specB_3panel_structural_decomposition.png`,
`fig_specB_mechanization_drift.png`, and `fig_specB_relative_price_drift.png` under `output/figures/`
— show the same relationship non-parametrically.

Output growth decelerated by 1.8 points between eras while structures accumulation held nearly
constant at about 5.7 percent. The extensive margin kept expanding as its capacity yield fell.

---

## 3. Theory: the Okishio viability condition

Section 3.2 of this chapter derives capacity from a decentralized cost-minimization problem. Potential
output decomposes into an extensive envelope and an intensive yield generated by the gap:

$$y^p_t = \theta_{NRC} k^{NRC}_t + \Psi_t(\kappa_t, \omega_{t-1}, p^\kappa_t)$$

The firm chooses $\kappa_t$ against a mechanization frontier $\Phi(\kappa_t) = \lambda_0 + \lambda_1
\kappa_t + \lambda_2 \kappa_t^2$, maximizing the net viability surplus

$$\max_{\kappa_t} \ c(\kappa_t) = \Phi(\kappa_t) - \kappa_t \cdot MC(\omega_{t-1}, p^\kappa_t)$$

where $MC$ is the marginal viability cost of widening the gap. Two channels set it. Raising $\kappa_t$
substitutes machinery for labor, and the value of that displacement is proportional to the lagged wage
share, so a higher wage share **reduces** the net cost of mechanizing. Raising $\kappa_t$ also requires
accumulating machinery faster than structures, at a cost proportional to the relative price, so a
higher $p^\kappa_t$ **increases** it:

$$MC(\omega_{t-1}, p^\kappa_t) = \gamma_0 - \gamma_1 \omega_{t-1} + \gamma_2 p^\kappa_t, \qquad \gamma_1 > 0, \ \gamma_2 > 0$$

Here $\gamma_1$ is the wage-savings dividend and $\gamma_2$ the relative price penalty. The
first-order condition gives the optimal gap

$$\kappa_t^*(\omega_{t-1}, p^\kappa_t) = \frac{(\gamma_0 - \lambda_1) - \gamma_1 \omega_{t-1} + \gamma_2 p^\kappa_t}{2\lambda_2}$$

with strict concavity $\lambda_2 < 0$ guaranteeing an interior maximum. The comparative statics are the
induced-innovation mechanism:

$$\frac{\partial \kappa_t^*}{\partial \omega_{t-1}} = -\frac{\gamma_1}{2\lambda_2} > 0, \qquad \frac{\partial \kappa_t^*}{\partial p^\kappa_t} = \frac{\gamma_2}{2\lambda_2} < 0$$

A rising wage share forces cost-minimizing firms to widen the gap. A rising relative price of machinery
suppresses it.

**What this means at the workplace.** The algebra above compresses a concrete institutional process.
Capital becomes capacity through a conversion that happens on the shop floor: a given stock of
structures and machines yields potential output only at some rate of throughput, set by shift
patterns, crewing levels, maintenance regimes and the pace of work. The mechanization gap is the
margin on which firms adjust that conversion. Widening it — adding machines faster than floor space —
raises output per worker-hour and lets the firm economize on a wage bill that has become expensive.
Distribution enters the capacity equation because the wage share is what makes that substitution worth
undertaking, and it enters *lagged* because the wage settlement precedes the investment decision it
provokes. The relative price enters because the same substitution has to be bought at the going price
of equipment. Neither variable is a control for something else; each is a term in the calculation a
cost-minimizing firm actually performs.

**An unresolved conflict in the theory.** Section 3.2 line 68 derives $\partial\kappa^*/\partial
p^\kappa < 0$. The companion note `A06_RelativePrice_Mechanization_Theory.md` line 72 derives the
opposite, $\partial q^*/\partial p^{rel} > 0$, from a multiplicative rather than additive cost form.
The two are not reconciled in the vault. Section 2's descriptive evidence sits with A06. This report
records the conflict and does not adjudicate it; the ledger
`specB5_price_channel_sign_conflict.csv` carries both derivations against every estimate.

*Added after this report's estimates were fixed.* `US_S33I` has since estimated A06 §2's own nested
ladder, and it narrows the conflict without settling it — see
`A06_S32_PriceChannel_Reconciliation.md`. Three findings bear on the reading below. First, the two
derivations are about **different objects**: $\theta_{\kappa p\kappa}$ is a capacity-equation
coefficient, while A06 line 72 is a comparative static on the optimal gap, and A06 derives no sign
for its own estimating coefficient. Second, A06 line 72 and its own gloss at line 74 carry
**opposite signs**, so A06's price prediction is unsettled internally. Third, and bearing directly
on §7 below, the price block is **jointly insignificant once the wage-mechanization break is
included** ($F = 0.521$, $p = 0.597$). B5's sign-stable negative estimate is therefore consistent
with §3.2 but is not evidence that the price channel is present. The ladder reproduces B5's
interacted cell to $4.6\times10^{-12}$, so this qualifies the same numbers rather than competing
with them.

---

## 4. How the theory licenses the specification

The step from Section 3 to an estimating equation is an envelope-theorem argument, and it is what
distinguishes this specification from a regression with interaction terms added for flexibility.

The marginal capacity payoff of the gap is the derivative of the intensive yield, which by the envelope
theorem equals the net marginal viability yield at the optimum:

$$MP_\kappa = \frac{\partial \Phi}{\partial \kappa_t} - MC(\omega_{t-1}, p^\kappa_t) = \underbrace{(\lambda_1 - \gamma_0 + 2\lambda_2 \kappa_t)}_{\text{autonomous yield}} + \gamma_1 \omega_{t-1} - \gamma_2 p^\kappa_t$$

Integrating over $\kappa_t$, holding the slow-moving state variables predetermined, gives the intensive
yield and therefore the capacity equation:

$$y^p_t = \theta_{NRC} k^{NRC}_t + \theta_\kappa \kappa_t + \theta_{\omega\kappa}(\omega_{t-1}\kappa_t) + \theta_{\kappa p\kappa}(p^\kappa_t \kappa_t)$$

with the structural identities

$$\theta_{\omega\kappa} = \gamma_1 > 0, \qquad \theta_{\kappa p\kappa} = -\gamma_2 < 0$$

The interaction terms are the macroeconomic footprint of the viability constraint. Distribution and
relative prices enter multiplicatively because they alter the marginal capacity payoff of the gap, not
because a level effect needed conditioning.

Four consequences bind the estimation.

**The standalone gap is required.** $\theta_\kappa$ carries the autonomous yield $(\lambda_1 -
\gamma_0)$. An earlier specification (B4) dropped it on the argument that mechanization is "only a
channel." The derivation does not support that: without $\theta_\kappa$ the marginal payoff has no
intercept and the transformation elasticity cannot be recovered from the structural model. B5 restores
it.

**There is no three-way term.** $MC$ is additively separable in $\omega_{t-1}$ and $p^\kappa_t$, so the
model generates two two-way interactions and nothing else. A $\kappa\omega p^\kappa$ term would invent
structure the theory does not contain, at a real cost in conditioning.

**Curvature is not identified.** The integrated yield carries no $\kappa^2$ term, so $\theta_\kappa$
recovers the autonomous yield and $\lambda_2$ is unidentified. Strict concavity is assumed, not tested.
Any claim about the frontier's shape would require a $\kappa^2$ regressor this equation does not carry.

**The interaction span must be complete.** This requirement comes from the econometrics, not the
theory, and violating it silently invalidated the earlier estimates. Centering a base series before
forming a break-interacted cross-product expands as

$$(\kappa - \kappa_0)(\omega - \omega_0)D_t = \kappa\omega D_t - \kappa_0(\omega D_t) - \omega_0(\kappa D_t) + \kappa_0\omega_0 D_t$$

so the design must span $\omega D_t$ and $\kappa D_t$ as well as $\kappa\omega D_t$ and $D_t$.
Otherwise centering stops being a reparameterization and becomes a change of model. On synthetic data
with a known data-generating process, ordinary least squares gives a relative spread across centering
regimes of $6\times10^{-16}$ when the span is complete and $7.8\times10^{-2}$ when it is not. Two
alternative explanations were tested and rejected: the estimator is not at fault (IM-OLS varies by
about 0.3 percent on well-conditioned data) and neither is ill-conditioning (forcing the condition
number to 181 leaves the spread at 0.26 percent). B5 carries the complete span.

---

## 5. Results

The estimation window is 1929–2024 ($T = 94$). The internal break date $T_B^* = 1969$ comes from a
Bai-Perron search on $\Delta(\kappa_t\omega_{t-1})$ and is not imposed.

**What the integration-order requirement rules out.** A cointegrating regression is only interpretable
as a long-run relationship if its variables share a common stochastic trend. The practical question is
counterfactual: which specifications would this requirement *reject*? Two kinds. A variable that is
stationary around its breaks — trend-stationary rather than integrated — cannot participate in a
cointegrating vector at all, because it has no stochastic trend to share; the lagged wage share fails
this way in the aggregate specification of the companion report. A variable that remains integrated
after first differencing carries a second unit root, and regressing it on $I(1)$ variables produces
residuals that look stationary in-sample without any long-run relationship existing; the mechanization
gap fails this way in the Post-Fordist sub-sample. Here, on the full sample, all three base variables
survive both tests: each has a unit root in levels and loses it in first differences, tested under
broken deterministics. The route is therefore **formal** rather than exploratory, and the estimates
below are not carrying an unstated caveat about what the series are.

Step controls $D_{1933}$, $B_{1942\text{–}1945}$, $D_{1981}$ and $D_{2000}$ enter additively as
variance hygiene. A reader concerned that these dummies are absorbing the regime shift rather than
merely cleaning variance should note that the break-interaction decision in Section 7 comes back
negative: the additive controls carry what shift there is, and the multiplicative term adds nothing
significant.

I report all three centering regimes and designate no single primary model. The reason is in Section 6:
no configuration clears the condition-number threshold, and the paper-facing claim is the stability of
the interaction coefficients across regimes, not any one point estimate.

### Table 2: Specification B5, uninteracted ($T = 94$, 10 design columns, 83 residual d.f.)

| Parameter | Uncentered | Initial-state | Sample-mean |
|---|---:|---:|---:|
| $\hat\theta_{NRC}$ | 0.326*** (4.82) | 0.321*** (4.48) | 0.371*** (6.11) |
| $\hat\theta_{\kappa}$ | −3.130 (−1.00) | 0.980*** (2.65) | 1.117*** (4.74) |
| $\hat\beta_{p^\kappa}$ | 0.313 (0.56) | −0.807** (−2.35) | −0.266 (−1.22) |
| $\hat\beta_{\omega}$ | 1.606 (0.44) | −4.191** (−2.18) | −2.605** (−1.99) |
| $\hat\theta_{\omega\kappa}$ | 5.693 (1.17) | 4.203 (0.98) | 4.010 (0.87) |
| $\hat\theta_{\kappa p^\kappa}$ | 1.027 (1.44) | 0.997 (1.40) | 0.655 (0.89) |
| Condition number | 638.06 | 49.50 | **30.02** |
| $C_{\text{Shin}}$ | 0.0523 | 0.0540 | 0.0610 |
| Residual ADF | −4.458** | −4.632** | −4.408* |
| $\hat\sigma_u$ | 0.1095 | 0.1094 | 0.1125 |
| $R^2_{\text{level}}$ | 0.9912 | 0.9912 | 0.9907 |

### Table 3: Specification B5, break-interacted at $T_B^* = 1969$ ($T = 94$, 14 design columns, 79 residual d.f.)

| Parameter | Uncentered | Initial-state | Sample-mean |
|---|---:|---:|---:|
| $\hat\theta_{NRC}$ | 0.593*** (8.00) | 0.588*** (8.09) | 0.599*** (8.21) |
| $\hat\theta_{\kappa}$ | 7.430* (1.91) | 0.994*** (3.16) | 0.944*** (4.48) |
| $\hat\beta_{p^\kappa}$ | −0.430 (−0.98) | 0.221 (0.86) | −0.053 (−0.29) |
| $\hat\beta_{\omega}$ | −12.205** (−2.00) | −1.573 (−1.23) | −7.674*** (−3.36) |
| $\hat\theta_{\omega\kappa}$ | −9.613 (−1.60) | −9.694 (−1.62) | −13.822** (−2.40) |
| $\hat\theta_{\kappa p^\kappa}$ | −0.617 (−1.15) | −0.558 (−1.01) | −0.689 (−1.24) |
| $\hat\gamma_1$ (level shift) | −11.195** (−2.22) | 0.677** (2.39) | 0.018 (0.19) |
| $\hat\theta_{\kappa,brk}$ | −10.417 (−1.56) | −1.235*** (−2.87) | −1.384*** (−3.49) |
| $\hat\beta_{\omega,brk}$ | 16.469** (2.05) | 0.817 (0.15) | 9.220*** (3.12) |
| $\hat\theta_{\omega\kappa,brk}$ | 14.418 (1.34) | 14.139 (1.31) | 18.427* (1.75) |
| Condition number | 2531.72 | 82.72 | 39.94 |
| $C_{\text{Shin}}$ | 0.0152 | 0.0146 | 0.0165 |
| Residual ADF | −7.400*** | −7.366*** | −7.053*** |
| $\hat\sigma_u$ | 0.0641 | 0.0640 | 0.0658 |
| $R^2_{\text{level}}$ | 0.9971 | 0.9971 | 0.9970 |

Fixed-$b$ HAR $t$-statistics in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.
Source: `S33G_IMOLS_SPEC_B5/csv/specB5_coefficients.csv`.

Cointegration holds throughout. $C_{\text{Shin}}$ runs from 0.0146 to 0.0610 against a 10 percent
critical value of 0.095, and the residual ADF rejects no-cointegration in all six columns. The break
interaction improves fit substantially, cutting $\hat\sigma_u$ from 0.109 to 0.064.

### Table 4: Sensitivity of each parameter to the centering regime

Centering changes two things by construction — the conditioning of the design and the point at which
baseline linear coefficients are evaluated. The invariance claim in the centering protocol therefore
applies to the interaction-class parameters, and only those are gated.

| Parameter | Class | Range across regimes | Relative spread | Sign stable |
|---|---|---|---:|:---:|
| $\theta_{NRC}$ | interaction | [0.588, 0.599] | 0.018 | Yes |
| $\theta_{\kappa p^\kappa}$ | interaction | [−0.689, −0.558] | 0.210 | Yes |
| $\theta_{\omega\kappa,brk}$ | interaction | [14.139, 18.427] | 0.274 | Yes |
| $\theta_{\omega\kappa}$ | interaction | [−13.822, −9.613] | 0.381 | Yes |
| $\beta_{\omega}$ | base | [−12.205, −1.573] | 1.487 | Yes |
| $\theta_{\kappa,brk}$ | base | [−10.417, −1.235] | 2.113 | Yes |
| $\theta_{\kappa}$ | base | [0.944, 7.430] | 2.077 | Yes |
| $\beta_{p^\kappa}$ | base | [−0.430, 0.221] | 2.775 | No |
| $\gamma_1$ | base | [−11.195, 0.677] | 2.996 | No |

Break-interacted model. Source: `specB5_centering_stability.csv`. Seven of seven interaction-class
parameters hold their sign across all three regimes.

---

## 6. Specification space, and what failed

Reporting only the surviving specification would misrepresent how much of the space was searched. Four
designs were estimated and superseded.

**B3, the canonical fully interacted split-sample model.** Carries $\kappa_t$ three times — as a level,
in $\kappa\omega$, and in $\kappa p^\kappa$ — with condition numbers of 82 and 361 in the Fordist
window and 43 and 231 in the Post-Fordist. Its break-interacted coefficients are centering-dependent:
$\hat\theta_{\omega\kappa}$ spans [−23.61, 47.79] across regimes in the interacted Fordist column.

**B4, the standalone-gap exclusion.** Dropped $\theta_\kappa$ on the argument that mechanization is
distribution-conditioned rather than autonomous. Conditioning improved substantially (Fordist
uninteracted CN 82.2 → 21.2, the one cell in the project that clears 30). But Section 4 shows the
exclusion is not licensed by the derivation, and residual variance rose in every cell. Its
$\hat\theta_{\omega\kappa}$ spans [−19.60, 5.05].

**The span-broken full-sample track.** Correct in restoring the full 94-observation window and in
locating the break endogenously, but it carried $\kappa\omega D_t$ without $\kappa D_t$ or $\omega
D_t$. Its $\hat\theta_{\kappa p^\kappa}$ spans [−0.744, 2.083] — the sign of the price channel was set
by the centering convention.

**Deterministic specification.** A linear trend added to the deterministic component was tested as a
candidate remedy for the centering sensitivity and rejected: the median relative spread moved only from
1.98 to 1.64.

### Table 5: Sign identification across tracks

| Track | $\hat\theta_{\omega\kappa}$ range | Stable | $\hat\theta_{\kappa p^\kappa}$ range | Stable |
|---|---|:---:|---|:---:|
| Split-sample, Fordist interacted | [−23.607, 47.794] | No | [−11.482, 0.012] | No |
| Split-sample, Post-Fordist interacted | [−50.119, −45.959] | Yes | [0.463, 0.604] | Yes |
| Full-sample, span broken | [−19.600, 5.053] | No | [−0.744, 2.083] | No |
| **Full-sample, span complete (B5)** | **[−13.822, −9.613]** | **Yes** | **[−0.689, −0.558]** | **Yes** |

Source: `specB5_vs_prior_tracks_comparison.csv`.

---

## 7. Key findings

**The theory's two sign restrictions are not jointly satisfied.** Section 4 requires $\gamma_1 > 0$ and
$\gamma_2 > 0$. Recovering them from the structural identities:

| Specification | $\hat\gamma_1 = \hat\theta_{\omega\kappa}$ | Sign correct | $\hat\gamma_2 = -\hat\theta_{\kappa p^\kappa}$ | Sign correct |
|---|---:|:---:|---:|:---:|
| Uninteracted | 4.203 | **Yes** | −0.997 | No |
| Break-interacted | −9.694 | No | 0.558 | **Yes** |

Source: `specB5_structural_parameter_recovery.csv`. Each specification recovers exactly one channel of
the viability condition and reverses the other. On the Rule H reading of coefficients as regime
signatures, this is not a technical failure but a substantive one: the induced-innovation mechanism
that Section 3 derives does not appear in the US data as a single coherent structure over 1929–2024.
The descriptive evidence in Section 2 points the same way, with $\kappa$ and $p^\kappa$ co-moving
positively in both eras where the theory requires them to move oppositely.

**The price channel is now sign-identified, but not significant.** $\hat\theta_{\kappa p^\kappa}$ holds
a negative sign across all three centering regimes, [−0.689, −0.558], where every earlier track flipped
with the convention chosen. Its $t$-statistic is −1.01. The correct statement is that the price penalty
is directionally consistent with Section 3.2 and statistically indistinguishable from zero.

**Extensive scale is the one sharply identified parameter, and it carries an overaccumulation
punchline.** $\hat\theta_{NRC} = 0.588$ ($t = 8.09$), with a relative spread of 0.018 across regimes.
Plant structures anchor capacity precisely, and the failure documented above is specific to the
state-dependent channel.

Put the elasticity together with the descriptive rates in Table 1 and the stake becomes concrete. After
1974 structures accumulated at 5.72 percent a year. At an elasticity of 0.588, the extensive margin
alone contributed

$$0.588 \times 5.72 = 3.36\ \text{percent per year}$$

of capacity growth, against realized output growth of 3.12 percent. Capacity from plant structures
alone outran output by roughly 0.24 points a year, which compounds to about 12 percentage points of
accumulated slack across the half-century — and that is before any contribution from machinery. This
is the arithmetic behind the overaccumulation reading: it does not require the state-dependent channel
to work, only the extensive elasticity to be below one and capital to keep accumulating.

**The elasticity is probably biased downward.** $k^{NRC}_t$ is a perpetual-inventory construct
depending on assumed service lives and depreciation geometry, so it carries classical measurement
error on the right-hand side. In a cointegrating regression the attenuation is less severe than in a
stationary one, since the super-consistency of the long-run estimator dominates as $T$ grows, but it
does not vanish: the direction is toward zero, so 0.588 should be read as a lower bound on the true
extensive elasticity. That direction matters for the punchline above. A larger true $\theta_{NRC}$
widens the gap between capacity growth and output growth, strengthening rather than weakening the
overaccumulation reading.

**The 1969 break does not survive the span correction.** $\hat\theta_{\omega\kappa,brk} = 14.139$ with
$t = 1.31$, so the decision is `retain_additive_step_control`: no significant multiplicative shift in
the wage-mechanization relation. An earlier specification reported this coefficient at $t = -2.90$, and
that significance was an artifact of the incomplete span.

**Two parameters are unrecoverable.** $\lambda_2$ requires a $\kappa^2$ regressor the equation does not
carry, so strict concavity is assumed rather than tested. The transformation elasticity
$\theta^{SpecB}_t$ is not re-derived here; it runs through the LOESS path-derivative stage rather than
the break-aware one, and re-deriving it under B5 requires re-estimating the full model grid. No
B5-conditioned trajectory is asserted.

---

## 8. Deviations from standard protocol

Three departures from the applied-econometrics protocol used elsewhere in this project, each with its
reason.

**Frisch-Waugh-Lovell orthogonalization of interaction terms is not performed.** The general protocol
calls for substituting the residual of an auxiliary regression for the raw cross-product when $I(2)$
risk is present. The E10V estimator lock forbids this, and the argument is specific to the estimator:
partial summation does not commute with projection ($S M_X \neq M_{SX} S$), so level-filtered residuals
violate the Brownian limit theory that cointegrating polynomial regression relies on. FWL
pre-filtering is not useful in this time-series setting. The interaction enters raw, and
`s33_assert_no_fwl()` enforces it at runtime.

**Integration order is established by Lee-Strazicich rather than ADF and KPSS.** The general protocol
screens with ADF and KPSS on levels and first differences. Every series here contains structural
breaks, and the augmented Dickey-Fuller test is biased toward non-rejection under a break — it would
systematically misclassify exactly the series this chapter is about. The Lee-Strazicich Minimum-LM test
with endogenous break location replaces it, adjudicated on the levels-and-differences pair.
Cointegration diagnostics retain the residual ADF and the Shin LM statistic.

**The condition-number threshold is not met, and no model is designated primary.** The protocol blocks
any specification with a standardized condition number above 30 regardless of theoretical motivation.
No B5 configuration clears it: the uninteracted model reaches 30.02 under sample-mean centering, and
the break-interacted model runs from 39.94 to 2531.72. Rather than select the regime that comes closest
and present it as preferred, this report gives the full triad and rests its claims on sign stability
across regimes. B5 is entered below as **Held**, not Promoted.

**Bootstrap inference is not triggered.** Small-sample bootstrap applies at $N \le 30$; here $T = 94$,
so asymptotic Fixed-$b$ HAR inference stands alone.

---

## 9. Consolidated verdict table

| Candidate Variable | Theoretical Basis | Integration & Collinearity Evidence | Status | Governing Lock / Rationale |
|---|---|---|---|---|
| $k^{NRC}_t$ | Extensive capacity envelope, §3.2.1 | LS $I(1)$-with-break, gate PASS; $\hat\theta_{NRC}$ rel. spread 0.018 | **Promoted** | Clears integration gate; sharply identified across all regimes |
| $\kappa_t$ | Autonomous yield $(\lambda_1-\gamma_0)$, §3.2.3 | LS $I(1)$-with-break, gate PASS; base-class, rel. spread 2.077 | **Held** | Required by the derivation; centering-sensitive, so reported as a range |
| $p^\kappa_t$ | Relative price penalty $\gamma_2$, §3.2.2 | LS $I(1)$-with-break, gate PASS; $\hat\beta_{p^\kappa}$ sign-unstable | **Held** | Enters as a level control; the identified channel is the interaction |
| $\omega_{t-1}$ | Wage-savings dividend $\gamma_1$, §3.2.2 | Level term sign-stable but rel. spread 1.487 | **Held** | Base-class; point of evaluation moves with centering by construction |
| $\kappa_t \cdot \omega_{t-1}$ | $\theta_{\omega\kappa}=\gamma_1>0$, §3.2.3 | Sign-stable [−13.82, −9.61]; **sign contradicts theory** | **Held** | Identified but sign-reversed in the interacted model; H1 not supported |
| $\kappa_t \cdot p^\kappa_t$ | $\theta_{\kappa p\kappa}=-\gamma_2<0$, §3.2.3 | Sign-stable [−0.689, −0.558]; $t=-1.01$ | **Held** | Sign consistent with §3.2, magnitude indistinguishable from zero |
| $\kappa_t\omega_{t-1}D_t$ (1969) | Regime shift in the wage channel, §2.6 | $t=1.31$; sign-stable [14.14, 18.43] | **Held** | Not significant at 5%; decision is additive step control |
| $\kappa_t\omega_{t-1}p^\kappa_t$ | None — $MC$ additively separable | Not estimated | **Rejected** | §3.2 derives no three-way term; would add collinearity without warrant |
| $\kappa^2_t$ | Frontier curvature $\lambda_2$ | Not in the integrated $\Psi_t$ | **Blocked** | Unidentified; strict concavity assumed, not tested |
| FWL-residualized interactions | Protocol Gate 4 | Not estimated | **Blocked** | E10V: partial summation does not commute with projection |
| **Specification B5 (whole)** | §3.2 line 94 | Cointegrated ($C_{\text{Shin}}$ 0.015–0.061); **CN 30.0–2531.7 fails the ≤30 gate** | **Held** | Sign-identified across centering, but no configuration clears the collinearity threshold |

---

## 10. Open items

- The §3.2 versus A06 sign conflict on the price channel is unresolved, but `US_S33I` has narrowed
  it: the two derivations address different objects, A06's formula contradicts A06's own prose, and
  the sign of the estimated interaction is set by the wage-break specification rather than by the
  price theory. The outstanding decision is A06's cost-function convention, not an empirical one.
  See `A06_S32_PriceChannel_Reconciliation.md`.
- The price channel is not detectable once the wage-mechanization break is in the model (joint Wald
  $p = 0.597$ contemporaneous, $0.985$ lagged). Whether $\theta_{\kappa p\kappa}$ belongs in the
  reported specification at all is now an open question, not a settled one.
- The split-sample and span-broken tracks retain incomplete interaction spans; their break-interacted
  coefficients should not be quoted for either hypothesis until corrected. **Corrected on
  2026-07-31** — see the v7 (Spec A) and v8 (Spec B) reports for the re-estimated designs and the
  span-correction impact tables.
- Residual interaction-coefficient spread of 0.21 to 0.42 exceeds the roughly 0.007 that a complete
  span achieves on synthetic data. B5 is sign-identified, not exactly invariant, and the remaining gap
  is unexplained.
- $\theta^{SpecB}_t$ awaits re-derivation under B5 through the path-derivative stage.
- No configuration clears the condition-number threshold. A specification that does — plausibly one
  built on investment flows rather than stock ratios — remains the outstanding econometric problem.
