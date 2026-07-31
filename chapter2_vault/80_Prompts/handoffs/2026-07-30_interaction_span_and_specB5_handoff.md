---
type: handoff
status: active
country: US
stage_scope: S33F_S33G
last_updated: 2026-07-30
depends_on:
  - chapter2_vault/03_econometrics/N11_Centering_Protocol_Three_Regime.md
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
  - chapter2_vault/06_paper_facing/drafts/ch2_sec3_2_heterogeneous_capital_prelatex.md
  - chapter2_vault/02_analyitical_foundation/A06_RelativePrice_Mechanization_Theory.md
layer: session_handoff
---

# Handoff: The Interaction-Span Mechanism and Specification B5

Two stages added, `US_S33F` (diagnostic) and `US_S33G` (Spec B5). No existing stage was modified; no
report was touched. Everything below is reproducible from ledgers under
`output/US/BREAK_AWARE_IMOLS/`.

## 1. What went wrong, and where

Spec B estimates were changing — including changing **sign** — depending on which centering regime was
reported. Since `AGENTS.md:152` defaults to Regime B while `E10V:50-53` designates Regime A the Main
Specification, that meant an arbitrary convention was deciding whether H1 and H2 were supported.

`N11_Centering_Protocol_Three_Regime.md` §1 asserts a Core Invariance Theorem: interaction
coefficients are identical across centering choices. The theorem is **algebraically correct** but
carries an unstated premise — the design must span *all lower-order constituents* of every
interaction. Break-interacted designs violate it.

## 2. The mechanism

Centering the base series before forming a break-interacted cross-product expands as

$$(\kappa - \kappa_0)(\omega - \omega_0)D_t = \kappa\omega D_t - \kappa_0(\omega D_t) - \omega_0(\kappa D_t) + \kappa_0\omega_0 D_t$$

so invariance requires $\kappa\omega D_t$, $\omega D_t$, $\kappa D_t$ **and** $D_t$ in the design.

| Stage | $\kappa\omega D_t$ | $\kappa D_t$ | $\omega D_t$ | Span |
|---|:--:|:--:|:--:|---|
| `US_S33D` | ✅ ($\delta_2$) | ✅ ($\delta_1$) | ❌ | broken |
| `US_S33E` | ✅ | ❌ | ❌ | broken |
| `US_S33G` (B5) | ✅ | ✅ | ✅ | **complete** |

**Verified on synthetic data with a known DGP** (T=94), OLS relative spread across the three centering
regimes:

| Design | OLS spread | Verdict |
|---|---:|---|
| $\{1,\kappa,\omega,\kappa\omega\}$ — §1's stated case | 6e-16 | invariant ✅ |
| $+\ D_t,\ \kappa\omega D_t$ — our design shape | 7.8e-02 | **not invariant** ❌ |
| $+\ D_t,\ \kappa D_t,\ \omega D_t,\ \kappa\omega D_t$ | 6e-16 | invariant ✅ |
| span broken *and* standalone $\kappa$ dropped (B4) | 7.1e-01 | **worst** ❌ |

**Two alternatives were tested and ruled out.** IM-OLS is not the cause — invariant to ~0.3% on clean
data. Ill-conditioning is not the cause — CN forced to 181 leaves the spread at 0.26%. A linear trend
in `deter` does not fix it (median spread 1.98 → 1.64 on real data).

## 3. Why the first gate was wrong

`US_S33F`'s initial gate took the median relative spread across *all* parameters and reported NOT
CONFIRMED. That gate was mis-specified: N11 §1 states centering changes "the point of evaluation for
the baseline linear coefficients", so base coefficients are *supposed* to move. Averaging over them
tests a claim §1 never makes. The corrected gate is **interaction-class parameters only**, carried as
a `parameter_class` column in `specB5_centering_stability.csv`.

## 4. Specification B5

`codes/US_S33G_specB5_theory_consistent_full_sample.R`. §3.2 line 94 exactly, full sample, complete
span:

$$y^p_t = \theta_{NRC}k^{NRC}_t + \theta_\kappa \kappa_t + \theta_{\omega\kappa}(\omega_{t-1}\kappa_t) + \theta_{\kappa p\kappa}(p^\kappa_t\kappa_t) + \boldsymbol{\gamma}'\mathbf{D}_t + u_t$$

Two corrections against the prior tracks: **$\theta_\kappa$ restored** (§3.2 derives it from the
quadratic $\lambda_2\kappa^2$ term; it carries the $MP_\kappa$ intercept and curvature, and B4's
exclusion left $\theta_t^{\text{SpecB}}$ unrecoverable) and **the span completed**. Both were needed —
neither alone gives sign-stability.

$T_B^* = 1969$, read from `US_S33A` §6.5's Bai-Perron search on $\Delta(\kappa\omega)$, never
hardcoded. Route is **formal**: all three base variables are `I1_with_break`/PASS on the full sample.

**Not in the design, deliberately:** no three-way $\kappa\omega p^\kappa$ (§3.2's marginal cost is
additively separable, line 51); no $(\kappa p^\kappa)D_t$ (§2.6 predicts regime change in the
wage-mechanization nexus only, and $\kappa p^\kappa$ carries no dummy interaction so imposes no span
requirement); no unit-root test on any cross-product (E10V line 37 — CPR regressors inherit
admissibility from base series).

### Results, interacted model (T=94, 14 columns, 79 residual df, formal route)

| Parameter | Class | Estimate | $t$ | Centering range | Stable |
|---|---|---:|---:|---|:--:|
| $\theta_{NRC}$ | interaction | 0.588*** | 8.09 | [0.588, 0.599] | ✅ |
| $\theta_\kappa$ | base | 0.994*** | 3.16 | [0.944, 7.430] | ✅ |
| $\theta_{\omega\kappa}$ | interaction | −9.694 | −1.62 | [−13.82, −9.61] | ✅ |
| $\theta_{\kappa p^\kappa}$ | interaction | −0.558 | −1.01 | [−0.689, −0.558] | ✅ |
| $\theta_{\omega\kappa,brk}$ | interaction | 14.139 | 1.31 | [14.14, 18.43] | ✅ |
| $\theta_{\kappa,brk}$ | base | −1.235*** | −2.87 | [−10.42, −1.24] | ✅ |
| $\gamma_1$ | base | 0.677** | 2.39 | [−11.20, 0.68] | ❌ |

**Gate: PASS, 7/7 interaction-class parameters sign-stable.** Relative spreads 0.018–0.417.

### Sign stability against the prior tracks

| Track | $\theta_{\omega\kappa}$ | $\theta_{\kappa p^\kappa}$ |
|---|---|---|
| `US_S33D` Fordist interacted | [−23.61, +47.79] ❌ | [−11.48, +0.01] ❌ |
| `US_S33E` full-sample interacted | [−19.60, +5.05] ❌ | [−0.744, +2.083] ❌ |
| **`US_S33G` B5 interacted** | **[−13.82, −9.61] ✅** | **[−0.689, −0.558] ✅** |

## 5. What this means substantively

$\hat\theta_{\kappa p^\kappa}$ is now **negative and sign-stable** — the sign §3.2 line 68 predicts for
H2 — where every prior track had it flipping with the centering convention. It is not significant at
5% ($t = -1.01$), so H2 is *directionally consistent, not confirmed*.

The **slope-break decision is `retain_additive_step_control`**: $\theta_{\omega\kappa,brk} = 14.14$ is
sign-stable but $t = 1.31$, below the 5% threshold. So on the full sample the wage-mechanization
elasticity does not show a statistically significant regime shift at 1969, even though its point
estimate is large and its sign is robust. This is a weaker claim than `US_S33E` reported
($t = -2.90$), and the difference is attributable to the span correction — which is the point.

Note $\theta_{\kappa,brk} = -1.235$*** is significant, but it is base-class and its centering range
[−10.42, −1.24] is wide; it should not be quoted as a point estimate.

## 6. Sign conflict, recorded not adjudicated

§3.2 line 68 gives $\gamma_2 > 0 \Rightarrow \theta_{\kappa p^\kappa} < 0$.
`A06_RelativePrice_Mechanization_Theory.md` line 72 derives the **opposite**,
$\partial q^*/\partial p^{rel} > 0$, from a multiplicative cost form. The two drafts are unreconciled
in the vault. `specB5_price_channel_sign_conflict.csv` records the estimate alongside both
derivations with `theoretical_conflict_unresolved = TRUE`. **This needs an authorial decision.**

§3.2 also uses contemporaneous $p^\kappa_t$ while A06 uses lagged $p^{rel}_{t-1}$; B5 follows §3.2.

## 7. Open items

- **`US_S33D` and `US_S33E` still carry broken spans.** Their break-interacted coefficients have
  centering-dependent signs and should not be quoted for H1/H2 until corrected.
- **v7 report is affected.** Table 3.2's δ-rows and Table 3.3's B4 interacted columns rest on those
  designs. Left untouched this pass by decision; needs a deliberate correction pass.
- Residual interaction-coefficient spread (0.21–0.42) is larger than the ~0.007 synthetic benchmark.
  B5 is **sign-identified, not exactly invariant**. Cause not isolated.
- §3.2 vs A06 price-sign conflict (above).
- `E10V:50-53` says Regime A is the Main Specification; `AGENTS.md:152` says default to Regime B; code
  reports B. Matters less now that interaction coefficients are sign-stable, but still unresolved.
- $\theta_t^{\text{SpecB}}$ not re-derived; E18 path-derivative work still deferred. B5 restores
  $\theta_\kappa$, so recovery is now *possible* — but $\theta_\kappa$ is base-class and
  centering-sensitive, so $\lambda_2$ must be read as a range, not a point.

## 8. Run order

```
Rscript codes/US_S33A_bai_perron_split_sample_prescan.R      # supplies T_B* = 1969
Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R # supplies the full-sample gate
Rscript codes/US_S33F_centering_invariance_diagnostic.R      # diagnostic, optional
Rscript codes/US_S33G_specB5_theory_consistent_full_sample.R # Spec B5
```
