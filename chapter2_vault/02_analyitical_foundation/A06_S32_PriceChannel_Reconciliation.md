---
type: theory
status: active
depends_on:
  - chapter2_vault/02_analyitical_foundation/A06_RelativePrice_Mechanization_Theory.md
  - chapter2_vault/06_paper_facing/drafts/ch2_sec3_2_heterogeneous_capital_prelatex.md
  - chapter2_vault/00_constitutive_core/R_distribution_conditioned_theta_identification.md
stage_scope: S33
country: US
last_updated: '2026-07-31'
updated_by: US_S33I_PRICE_CHANNEL_DISCRIMINATION
layer: analytical_foundation
design_role: price_channel_sign_reconciliation
scope: chapter2_core
related_to:
  - A06_RelativePrice_Mechanization_Theory
  - ch2_sec3_2_heterogeneous_capital_prelatex
subtype: analytical_foundation
blocks: []
priority: active
---

# Reconciliation: the price-channel sign in §3.2 and A06

**Status: the conflict is narrower than it appeared, and the data do not settle what remains.**
This note records the evidence and the two analytical discrepancies it surfaced. It does not
adjudicate; the theoretical choice stays with the author.

Evidence source: `US_S33I_price_channel_discrimination.R`, full sample 1929–2024, complete
interaction span, all three centering regimes. Ledgers under
`output/US/BREAK_AWARE_IMOLS/S33I_PRICE_CHANNEL_DISCRIMINATION/csv/`.

---

## 1. What the conflict was taken to be

`specB5_price_channel_sign_conflict.csv` records it as a straight sign disagreement:

| Source | Claim | Line |
|---|---|---|
| §3.2 | $\gamma_2 > 0$, and $\theta_{\kappa p\kappa} = -\gamma_2 < 0$ | 53, 88 |
| §3.2 | $\partial \kappa^*/\partial p^\kappa = \gamma_2/(2\lambda_2) < 0$ | 68 |
| A06 | $\partial q^*/\partial p^{\text{rel}} = -(1-\omega)e^{-p^{\text{rel}}}/(2\lambda_2) > 0$ | 72 |

The difference traces to the cost form: §3.2 line 51 makes the price enter marginal cost
**additively**, $MC = \gamma_0 - \gamma_1\omega_{t-1} + \gamma_2 p^\kappa_t$; A06 line 53 makes it
enter **multiplicatively**, $c = a - q(1-\omega)e^{-p^{\text{rel}}}$.

Two things complicate that framing before any estimation is consulted.

---

## 2. First discrepancy: the two claims are about different objects

$\theta_{\kappa p\kappa}$ is a coefficient in the **capacity equation**. It comes from §3.2 line 86,
where $p^\kappa$ shifts the marginal capacity payoff of the gap:

$$MP_\kappa = \underbrace{(\lambda_1 - \gamma_0 + 2\lambda_2 \kappa_t)}_{\text{autonomous}} + \gamma_1 \omega_{t-1} - \gamma_2 p^\kappa_t$$

A06 line 72 is a comparative static on the **optimal choice** $q^*$ — how much mechanization the
firm selects, not how a unit of it maps into capacity. These need not share a sign, and neither
draft derives one from the other.

Critically, **A06 never derives a sign for its own estimating coefficient.** Its Specification B3
(line 102) introduces $\theta_{2,\tau}(\tau_t^{\text{real}} \cdot p_{t-1}^{\text{rel}})$ without a
predicted sign anywhere in the note. The "A06 predicts positive" entry in
`specB5_price_channel_sign_conflict.csv` is an inference across that gap, not a claim A06 makes.
That ledger field should be read with this caveat attached.

---

## 3. Second discrepancy: A06 is internally inconsistent at this point

A06 line 72 gives $\partial q^*/\partial p^{\text{rel}} > 0$. A06 line 74 glosses that same result as

> cheapening of machinery relative to plant footprint … accelerates mechanization intensity

which is $\partial q^*/\partial p^{\text{rel}} < 0$ — the opposite sign, and the one §3.2 line 68
also reports.

The formula is not a differentiation slip. It follows from A06's own setup: with
$B \equiv (1-\omega)e^{-p^{\text{rel}}}$, the stationary point is $q^* = (B - \lambda_1)/(2\lambda_2)$,
so $\partial q^*/\partial B = 1/(2\lambda_2) < 0$ while $\partial B/\partial p^{\text{rel}} < 0$, giving
$\partial q^*/\partial p^{\text{rel}} > 0$. The inconsistency is in the model, not the algebra.

A related framing problem sits underneath it. A06 line 57 imposes $\lambda_2 < 0$ and calls the
stationary point a maximum, but $c(q) = \lambda_0 + \lambda_1 q + \lambda_2 q^2 - qB$ is **concave**
in $q$ under $\lambda_2 < 0$, so its stationary point maximises $c$. Whether $c$ is a cost to be
minimised or a surplus to be maximised is not consistent between line 51 (which calls $c$ the "unit
cost of mechanization") and line 45 (which describes the firm as maximising "net productivity
surplus").

**Consequence for the reconciliation.** A06's *prose* agrees with §3.2. Only A06's *formula*
disagrees, and that formula rests on a sign convention the note does not settle internally. The
apparent theoretical conflict is substantially an artefact of that unresolved convention.

*This is recorded, not decided.* Repairing A06's cost function is an author's call with
consequences for its §3 derivation of $\theta_t^{\text{SpecB}}$.

---

## 4. What the data say

`US_S33I` estimates A06 §2's own nested ladder — A1 no price term, A2 additive price control, A3
fully interacted — with A3 run under both timings. A06 keeps the additive price contemporaneous
even in its B3, so **only the interaction timing differs** between the two readings.

### 4.1 The sign is set by the break specification, not by the timing

$\hat\theta_{\kappa p\kappa}$, range across the three centering regimes:

| Timing | Wage-break interaction | Range | Sign-stable |
|---|---|---|---|
| Contemporaneous (§3.2) | No | $[+0.655, +1.027]$ | yes |
| Contemporaneous (§3.2) | **Yes** | $[-0.689, -0.558]$ | yes |
| Lagged (A06) | No | $[+1.200, +1.251]$ | yes |
| Lagged (A06) | **Yes** | $[-0.068, +0.531]$ | **no** |

Both timings give a **positive** coefficient without the wage-mechanization break and a
**negative or indeterminate** one with it. The price channel's sign is therefore not identified
independently of the wage-break specification — which is a statement about this design, not about
either theory.

### 4.2 The wage channel moves with it

$\hat\theta_{\omega\kappa}$ behaves the same way once a price term is present:

| Rung | Break interaction | Range |
|---|---|---|
| A2 additive | No | $[+3.43, +4.70]$ |
| A2 additive | Yes | $[-14.33, -11.32]$ |
| A3 contemporaneous | No | $[+4.01, +5.69]$ |
| A3 contemporaneous | Yes | $[-13.82, -9.61]$ |

The two channels are entangled: neither sign can be read off without fixing the other's
specification. §3.2 requires $\gamma_1 = \theta_{\omega\kappa} > 0$, which holds **only** in the
models without the break interaction — the same models that give $\theta_{\kappa p\kappa} > 0$ and
so violate §3.2's other restriction. This is the same joint-restriction failure the Spec B5 report
records, seen here across the whole ladder rather than at one specification.

### 4.3 The price block is jointly insignificant once the break is included

Joint Wald on the price terms, reported centering regime:

| Rung | Timing | Break int. | $\sigma_u$ | $C_{\text{Shin}}$ | CN | Wald $F$ | $p$ |
|---|---|---|---|---|---|---|---|
| A1 | — | No | 0.1514 | 0.1575 | 27.3 | — | — |
| A1 | — | Yes | 0.0905 | 0.0426 | 76.3 | — | — |
| A2 | — | No | 0.1143 | 0.0672 | 41.8 | 2.448 | 0.122 |
| A2 | — | Yes | 0.0786 | 0.0281 | 78.8 | 0.052 | 0.821 |
| A3 | contemporaneous | No | 0.1094 | 0.0540 | 49.5 | 3.031 | 0.054 |
| A3 | contemporaneous | **Yes** | 0.0640 | 0.0146 | 82.7 | **0.521** | **0.597** |
| A3 | lagged | No | 0.1076 | 0.0451 | 57.0 | 3.100 | 0.051 |
| A3 | lagged | **Yes** | 0.0710 | 0.0181 | 140.2 | **0.015** | **0.985** |

Without the break interaction the price block is marginal ($p \approx 0.05$–$0.12$). **With it, the
price block is nowhere near significant.**

This qualifies the Spec B5 headline directly. B5's sign-stable $\hat\theta_{\kappa p\kappa} \in
[-0.689, -0.558]$ — the one estimate that satisfies §3.2's price restriction — sits inside a price
block that is jointly indistinguishable from zero ($F = 0.521$, $p = 0.597$). Sign-stability across
centering is a necessary condition, not evidence that the channel is present.

### 4.4 Neither timing wins

Contemporaneous fits marginally better with the break interaction ($\sigma_u$ 0.0640 vs 0.0710,
$C_{\text{Shin}}$ 0.0146 vs 0.0181) and marginally worse without it (0.1094 vs 0.1076). The lagged
variant costs substantially more conditioning when interacted (CN 140.2 vs 82.7). Differences this
small do not settle a timing convention, and A06's argument for lagging — that the price signal
precedes the investment decision — is not contradicted by them.

---

## 5. Where this leaves the conflict

| Question | Resolved? | By what |
|---|---|---|
| Do §3.2 and A06 predict opposite signs for $\theta_{\kappa p\kappa}$? | **No, as posed** | The two claims are about different derivatives (§2). A06 predicts nothing for this coefficient. |
| Is A06's price comparative static settled? | **No** | Its formula and its prose disagree (§3). |
| Does the US data pick a sign? | **No** | The sign is set by the wage-break specification, not the price theory (§4.1). |
| Is the price channel present at all? | **Not detectably**, once the wage break is in | Joint Wald $p = 0.60$ (contemporaneous), $0.99$ (lagged) (§4.3). |
| Does the data prefer a timing? | **No** | Fit differences are within noise (§4.4). |

**The single most consequential item is §3, not §4.** If A06's prose is what was meant, then A06 and
§3.2 agree, the "conflict" dissolves, and $\theta_{\kappa p\kappa} < 0$ stands as the chapter's
single prediction — one the data do not reject but also do not support at conventional significance.
If A06's formula is what was meant, its cost function needs the maximisation/minimisation convention
fixed before the sign can be trusted.

---

## 6. Open route, not taken here

A06 line 78 gives a non-zero cross-partial

$$\frac{\partial^2 q^*}{\partial\omega\,\partial p^{\text{rel}}} = \frac{e^{-p^{\text{rel}}}}{2\lambda_2} < 0$$

whereas §3.2's additively separable cost implies it is exactly zero. This is the **sharpest formal
difference between the two drafts** and the only one that generates a distinct testable regressor —
a three-way $\kappa \cdot \omega \cdot p^\kappa$ term.

It was not estimated, for two reasons. It concerns the optimal gap rather than the capacity
equation, so §3.2's derivation chain does not license the regressor. And the entanglement in §4.2
means a three-way term would be added to a design whose two-way signs are already
specification-dependent.

If the cost-function convention in §3 is settled first, this becomes the natural discriminating
test.

---

## 7. Ledger cross-references

- `specB_price_channel_discrimination.csv` — 174 coefficient rows, full ladder
- `specB_price_channel_model_comparison.csv` — fit, conditioning, joint Wald per model
- `specB_price_channel_centering_stability.csv` — centering ranges and sign-stability
- `specB_price_channel_verdict.csv` — 13 rows, `adjudicated = FALSE` throughout
- `specB5_price_channel_sign_conflict.csv` — supersedes nothing; read its `a06_prediction`
  field with §2 of this note attached

Validation: `US_S33I`'s A3/contemporaneous/interacted cell reproduces `US_S33G` Spec B5 to
$4.6 \times 10^{-12}$ across all 30 shared coefficients, confirming the ladder nests the reported
specification exactly.

Related: [[A06_RelativePrice_Mechanization_Theory]],
[[R_distribution_conditioned_theta_identification]],
[[standalone_kappa_exclusion_assessment]]
