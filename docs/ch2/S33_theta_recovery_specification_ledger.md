# S33 — Theta Recovery Specification Ledger

Date: 2026-07-07  
Repo: `Capacity-Utilization-US_Chile`  
Status: methodological note / pre-regression gate  
Scope: Chapter 2 U.S. empirical architecture

---

## 1. Purpose

This note locks a specification-facing ledger for the recovery of the time-varying or state-conditioned capacity-building elasticity, \(\theta_t\), in the Chapter 2 empirical architecture.

The central rule is:

> \(\theta_t\) is not whatever coefficient moves. It is the recoverable capacity-building elasticity implied by a theoretically admissible specification.

Some specifications recover \(\theta_t\) directly. Some recover only upstream determinants of \(\theta_t\). Some are diagnostic only. Some must be blocked from the standard FM-OLS / DOLS / IM-OLS estimator grid because they create raw polynomial or interaction terms that may behave as I(2).

This note also records the next methodological move: a wide pre-regression integration-order and visual-inspection report over the variable menu.

---

## 2. Core notation

\[
y_t = \log Y_t
\]

Realized effective-demand output. This is not productive capacity itself.

\[
k_t = \log K^{cap}_t
\]

Capacity-relevant capital. Current repo lock: \(K^{cap}=ME+NRC\), where ME is machinery/equipment and NRC is nonresidential construction.

\[
k^{ME}_t,\; k^{NRC}_t
\]

Heterogeneous capacity-capital components.

\[
\omega_t
\]

Distributional state, usually wage share or a related distribution/profitability object.

\[
q_t
\]

Observed proxy for selected technique or mechanization intensity.

\[
q_t^*
\]

Theoretically optimal technique chosen at a given distribution.

\[
q_t^* = \arg\max_q \left[a(q)-q(1-\omega_t)\right]
\]

Under an interior solution:

\[
a'(q_t^*) = 1-\omega_t
\]

Distribution therefore first enters the capitalist choice of technique. It should not be treated only as an interaction variable added after capital has already been accumulated.

\[
Q^{tech}_t = \sum_{s\leq t} q^*_{s-1}\Delta k_s
\]

Accumulated technique-weighted capacity-building path.

\[
Q^q_t = \sum_{s\leq t} q_{s-1}\Delta k_s
\]

Observed-technique proxy for the accumulated technique-weighted path.

\[
Q^{\omega}_t = \sum_{s\leq t} \omega_{s-1}\Delta k_s
\]

Distribution-weighted accumulation path. This is useful, but second-order relative to the technique-choice object.

\[
s^{ME}_t = \frac{K^{ME}_t}{K^{ME}_t+K^{NRC}_t}
\]

Machinery composition of capacity capital.

\[
\phi^{ME}_t = \frac{I^{ME}_t}{I^{ME}_t+I^{NRC}_t}
\]

Flow composition of current capacity-building investment.

---

## 3. Theoretical hierarchy

The preferred causal-theoretical ordering is:

\[
\omega_t \rightarrow q_t^* \rightarrow \Delta K^{ME}_t,\Delta K^{NRC}_t \rightarrow K^{cap}_t \rightarrow Y^p_t \rightarrow \mu_t
\]

Not:

\[
K^{cap}_t \times \omega_t \rightarrow Y_t
\]

The first-order hypothesis is that distribution conditions the choice of technique.

The second-order hypothesis is that the selected technique conditions productive-capacity building.

The third-order hypothesis is that distribution still directly conditions capacity after the technique channel has been accounted for.

---

## 4. Ledger A — baseline and decomposition specifications

| ID | Specification | Object estimated | Recovery of \(\theta_t\) | Interpretation | Gate |
|---|---|---|---|---|---|
| `S0_AGG_KCAP` | \(y_t=\alpha+\theta k_t+u_t\) | Scalar output-capital relation | \(\theta_t=\theta\) | Benchmark capacity elasticity only. No changing technique or distributional state-dependence. | `AUTHORIZE_BASELINE` if \(y,k\sim I(1)\) and \(u_t\sim I(0)\). |
| `S1_PERIODIZED_KCAP` | \(y_t=\alpha_j+\theta_j k_t+u_t\) | Regime-specific output-capital relation | \(\theta_t=\theta_j\) for period \(j\) | Step-function historical \(\theta_t\). Useful for Fordist/post-Fordist segmentation. | `AUTHORIZE_PERIODIZED` if enough observations and residual cointegration by window. |
| `S2_ROLLING_KCAP` | Rolling-window \(y_t=\alpha_\tau+\theta_\tau k_t+u_t\) | Local instability | \(\theta_t\approx\hat\theta_\tau\), diagnostic only | Shows whether fixed-vector closure is breaking. Not structural recovery. | `DIAGNOSTIC_ONLY`. |
| `S3_COMPONENT_K` | \(y_t=\alpha+\theta_{ME}k^{ME}_t+\theta_{NRC}k^{NRC}_t+u_t\) | Heterogeneous capital-capacity mapping | \(\theta_t=\theta_{ME}\rho^{ME}_t+\theta_{NRC}\rho^{NRC}_t\), where \(\rho^i_t=\Delta k^i_t/\Delta k_t\) | First serious bridge from aggregate capacity to disproportional accumulation. ME and NRC are not marginal-product inputs. | `AUTHORIZE_COMPONENT_DECOMP` if residual is I(0) and design matrix is not degenerate. |
| `S4_COMPOSITION_STATE` | \(y_t=\alpha+\theta k_t+\psi s^{ME}_t+u_t\) | Composition effect on relation level/location | Directly \(\theta_t=\theta\); total derivative is not cleanly identified | Composition shifts the relation but does not alone recover changing elasticity. | `SECONDARY_ROBUSTNESS`. |

---

## 5. Ledger B — technique-choice specifications

These specifications are upstream of \(\theta_t\). They recover the mechanism that may generate \(\theta_t\), but they do not by themselves recover \(\theta_t\).

| ID | Specification | Object estimated | Recovery of \(\theta_t\) | Interpretation | Gate |
|---|---|---|---|---|---|
| `T0_TECH_CHOICE_SURPLUS_SHARE` | \(q_t=\alpha+\beta(1-\omega_t)+v_t\) | Distribution-conditioned technique choice | No direct \(\theta_t\). Recovers \(q_t^*=g(\omega_t)\). | First-order hypothesis: distribution shapes chosen technique. | `AUTHORIZE_UPSTREAM` if admissible under integration order. |
| `T1_TECH_CHOICE_WAGE_SHARE` | \(q_t=\alpha+\beta\omega_t+v_t\) | Same, wage-share sign convention | No direct \(\theta_t\) | If \(\beta>0\), higher wage share induces mechanization; if \(\beta<0\), profitability/surplus conditions dominate. | `AUTHORIZE_UPSTREAM`. |
| `T2_TECH_CHOICE_PERIODIZED` | \(q_t=\alpha_j+\beta_j\omega_t+v_t\) | Regime-specific distribution-technique relation | No direct \(\theta_t\). Generates \(q_j^*(\omega)\). | Candidate if Fordist/post-Fordist technique choice differs. | `AUTHORIZE_UPSTREAM_PERIODIZED`. |
| `T3_MECHANIZATION_LINEAR` | \(a_t=\lambda_0+\lambda_1 q_t+e_t\) | Linear mechanization-productivity relation | No direct \(\theta_t\) | Informs whether technique can affect capacity elasticity. | `DIAGNOSTIC_OR_SECONDARY`. |
| `T4_MECHANIZATION_QUADRATIC` | \(a_t=\lambda_0+\lambda_1q_t+\lambda_2q_t^2+e_t\) | Decreasing, constant, or increasing returns to mechanization | No direct \(\theta_t\). Identifies curvature of \(a(q)\). | Theoretically central but econometrically hazardous if \(q_t\sim I(1)\), because \(q_t^2\) may be I(2). | `CPR_EXPERIMENT` unless \(q_t\) is stationary/bounded. |

---

## 6. Ledger C — direct state-dependent \(\theta_t\) specifications

These models try to recover a changing \(\theta_t\) directly from the capacity equation.

| ID | Specification | Object estimated | Recovery of \(\theta_t\) | Interpretation | Gate |
|---|---|---|---|---|---|
| `D0_RAW_DISTRIBUTION_INTERACTION` | \(y_t=\alpha+\beta k_t+\gamma(k_t\omega_t)+u_t\) | Direct distribution-conditioned elasticity | \(\theta_t=\beta+\gamma\omega_t\) | Clear but theoretically second-order: distribution modifies capacity elasticity directly instead of first shaping \(q^*\). | `AUTHORIZE_ONLY_IF_OMEGA_I0`; block if \(\omega_t\sim I(1)\). |
| `D1_RAW_TECHNIQUE_INTERACTION` | \(y_t=\alpha+\beta k_t+\gamma(k_tq_t)+u_t\) | Direct technique-conditioned elasticity | \(\theta_t=\beta+\gamma q_t\) | Stronger than D0, but raw \(kq\) is dangerous if both are I(1). | `AUTHORIZE_ONLY_IF_Q_I0`; otherwise `CPR_EXPERIMENT`. |
| `D2_RAW_COMPOSITION_INTERACTION` | \(y_t=\alpha+\beta k_t+\gamma(k_ts^{ME}_t)+u_t\) | Composition-conditioned elasticity | \(\theta_t=\beta+\gamma s^{ME}_t\) | Useful if \(s^{ME}\) is bounded/I(0). Captures machinery-heavy capacity regimes. | `SECONDARY_DIRECT_THETA` if \(s^{ME}\sim I(0)\). |
| `D3_MULTI_STATE_INTERACTION` | \(y_t=\alpha+\beta k_t+\gamma_1(k_tq_t)+\gamma_2(k_t\omega_t)+u_t\) | Technique and distribution jointly condition elasticity | \(\theta_t=\beta+\gamma_1q_t+\gamma_2\omega_t\) | Too broad for baseline. Useful only after nested tests show both channels survive. | `LATE_STAGE_ROBUSTNESS`; high collinearity risk. |
| `D4_FUNCTIONAL_COEFFICIENT` | \(y_t=\alpha+\theta(q_t,\omega_t)k_t+u_t\) | Smooth state-dependent elasticity | \(\theta_t=\theta(q_t,\omega_t)\) | Elegant but too heavy for the current repo baseline. | `FUTURE_EXTENSION`. |
| `D5_TVP_THETA` | \(y_t=\alpha+\theta_t k_t+u_t,\;\theta_t=\theta_{t-1}+\eta_t\) | Statistical time-varying elasticity | Recovers \(\theta_t\) statistically, not structurally | Useful if fixed cointegrating vector fails, but weakens mechanism unless tied back to \(q^*\). | `DIAGNOSTIC_ONLY_OR_APPENDIX`. |

---

## 7. Ledger D — accumulated path specifications

These are the strongest candidates because they preserve the claim that accumulation builds capacity while allowing technique, distribution, and composition to condition how accumulation becomes capacity.

| ID | Specification | Object estimated | Recovery of \(\theta_t\) | Interpretation | Gate |
|---|---|---|---|---|---|
| `A0_ACCUM_TECH_PATH` | \(Q^{tech}_t=\sum q^*_{s-1}\Delta k_s\), then \(y_t=\alpha+\beta k_t+\gamma Q^{tech}_t+u_t\) | Technique-conditioned accumulation path | \(\theta_t=\beta+\gamma q^*_{t-1}\) | Preferred theoretical recovery. Distribution shapes \(q^*\); \(q^*\) shapes the capacity effect of accumulation. | `AUTHORIZE_MAIN_EXTENSION` if \(Q^{tech}\sim I(1)\) and residual is I(0). |
| `A1_ACCUM_OBSERVED_Q_PATH` | \(Q^q_t=\sum q_{s-1}\Delta k_s\), then \(y_t=\alpha+\beta k_t+\gamma Q^q_t+u_t\) | Observed-technique-weighted accumulation | \(\theta_t=\beta+\gamma q_{t-1}\) | Empirical version of A0 when \(q^*\) is proxied by observed \(q\). | `AUTHORIZE_MAIN_EXTENSION` if \(Q^q\sim I(1)\). |
| `A2_ACCUM_DISTRIBUTION_PATH` | \(Q^\omega_t=\sum \omega_{s-1}\Delta k_s\), then \(y_t=\alpha+\beta k_t+\gamma Q^\omega_t+u_t\) | Distribution-weighted accumulation | \(\theta_t=\beta+\gamma\omega_{t-1}\) | Reduced-form proxy for distribution-conditioned technique. Now second-order. | `AUTHORIZE_SECOND_ORDER`. |
| `A3_ACCUM_ME_SHARE_PATH` | \(Q^{MEshare}_t=\sum s^{ME}_{s-1}\Delta k_s\), then \(y_t=\alpha+\beta k_t+\gamma Q^{MEshare}_t+u_t\) | Composition-conditioned accumulation | \(\theta_t=\beta+\gamma s^{ME}_{t-1}\) | Strong bridge between heterogeneous capital and mechanization. | `AUTHORIZE_SECOND_ORDER_OR_MAIN_ALT`. |
| `A4_ACCUM_FLOW_COMPOSITION_PATH` | \(Q^{Ishare}_t=\sum \phi^{ME}_{s-1}\Delta k_s\), then \(y_t=\alpha+\beta k_t+\gamma Q^{Ishare}_t+u_t\) | Flow-choice-conditioned accumulation | \(\theta_t=\beta+\gamma\phi^{ME}_{t-1}\) | Captures current capitalist accumulation choices better than stock composition. | `AUTHORIZE_MAIN_ALT` if data are clean. |
| `A5_HET_ACCUM_COMPONENT_PATHS` | \(y_t=\alpha+\gamma_{ME}Q^{ME}_t+\gamma_{NRC}Q^{NRC}_t+u_t\) | Separate ME and NRC accumulation paths | \(\theta_t=\gamma_{ME}q^{ME}_{t-1}\rho^{ME}_t+\gamma_{NRC}q^{NRC}_{t-1}\rho^{NRC}_t\) | Most faithful to heterogeneous mechanization; highest risk of collinearity and overfitting. | `LATE_STAGE_ROBUSTNESS`. |
| `A6_FULL_NESTED_PATH` | \(y_t=\alpha+\beta k_t+\gamma Q^{tech}_t+\delta Q^\omega_t+\psi s^{ME}_t+u_t\) | Technique, distribution, and composition jointly | \(\theta_t=\beta+\gamma q^*_{t-1}+\delta\omega_{t-1}\), with composition as level shifter unless interacted | Too crowded for baseline. Use only as final nested falsification test. | `ROBUSTNESS_ONLY`. |

---

## 8. Ledger E — blocked or experimental specifications

| ID | Specification | Claimed recovery | Problem | Treatment |
|---|---|---|---|---|
| `X0_K_TIMES_Q_IF_BOTH_I1` | \(y_t=\alpha+\beta k_t+\gamma k_tq_t+u_t\) | \(\theta_t=\beta+\gamma q_t\) | If \(k,q\sim I(1)\), \(kq\) is generally I(2). Standard FM-OLS/DOLS/IM-OLS are not valid naively. | `BLOCK_STANDARD`; route to `CPR_EXPERIMENT`. |
| `X1_Q_SQUARED_IF_Q_I1` | \(a_t=\lambda_0+\lambda_1q_t+\lambda_2q_t^2+e_t\) | Curvature of mechanization | If \(q\sim I(1)\), \(q^2\) may be I(2). | `CPR_EXPERIMENT` unless \(q\sim I(0)\). |
| `X2_K_TIMES_OMEGA_IF_BOTH_I1` | \(y_t=\alpha+\beta k_t+\gamma k_t\omega_t+u_t\) | \(\theta_t=\beta+\gamma\omega_t\) | Same raw interaction trap. Also theoretically second-order relative to \(q^*\). | `BLOCK_STANDARD`; maybe `SECOND_ORDER_CPR`. |
| `X3_FULL_RAW_INTERACTIONS` | \(y_t=\alpha+\beta k+\gamma kq+\delta k\omega+\eta q\omega+u_t\) | Multiple state-dependent \(\theta_t\) channels | Overloaded, collinear, likely mixed-order. | `DO_NOT_BASELINE`. |
| `X4_DIFFERENCED_ONLY` | \(\Delta y_t=\alpha+\beta\Delta k_t+\gamma\Delta Q_t+e_t\) | Short-run elasticity | Does not recover long-run \(\theta_t\); collapses capacity into realized-output co-movement. | `DIAGNOSTIC_ONLY`. |

---

## 9. Recommended recovery hierarchy

1. Recover the benchmark:

\[
\theta^0 \quad \text{from} \quad y_t=\alpha+\theta k_t+u_t.
\]

2. Test whether distribution selects technique:

\[
q_t^* = g(\omega_t).
\]

3. Recover the technique-conditioned elasticity:

\[
Q^{tech}_t = \sum q^*_{s-1}\Delta k_s
\]

\[
y_t=\alpha+\beta k_t+\gamma Q^{tech}_t+u_t
\]

so that:

\[
\boxed{\theta_t=\beta+\gamma q^*_{t-1}}
\]

4. Test whether distribution still has a residual second-order effect:

\[
y_t=\alpha+\beta k_t+\gamma Q^{tech}_t+\delta Q^\omega_t+u_t
\]

so that:

\[
\theta_t=\beta+\gamma q^*_{t-1}+\delta\omega_{t-1}.
\]

5. Test heterogeneous capital either as component decomposition:

\[
\theta_t=\theta_{ME}\rho^{ME}_t+\theta_{NRC}\rho^{NRC}_t
\]

or as composition-conditioned accumulation:

\[
\theta_t=\beta+\gamma s^{ME}_{t-1}.
\]

---

## 10. Repo-facing decision codes

| Decision code | Meaning | Specifications |
|---|---|---|
| `BASELINE_THETA` | Constant capacity elasticity only | `S0_AGG_KCAP` |
| `REGIME_THETA` | Stepwise historical \(\theta_t\) | `S1_PERIODIZED_KCAP` |
| `IMPLIED_HETEROGENEOUS_THETA` | \(\theta_t\) varies with ME/NRC growth composition | `S3_COMPONENT_K` |
| `UPSTREAM_QSTAR` | Recovers technique choice, not \(\theta_t\) | `T0`, `T1`, `T2` |
| `PREFERRED_THETA_T` | Recovers \(\theta_t\) through accumulated technique-conditioned capacity | `A0`, `A1` |
| `SECOND_ORDER_DISTRIBUTION_THETA` | Distribution directly conditions \(\theta_t\), but after \(q^*\) | `A2`, possibly `D0` |
| `COMPOSITION_THETA` | Capital heterogeneity conditions \(\theta_t\) | `A3`, `A4`, `A5` |
| `DIAGNOSTIC_ONLY` | Shows instability but does not recover structural \(\theta_t\) | `S2`, `D5`, `X4` |
| `BLOCK_STANDARD` | Cannot enter ordinary FM-OLS/DOLS/IM-OLS grid | `X0`, `X1`, `X2`, `X3` |
| `CPR_EXPERIMENT` | Allowed only in polynomial/higher-order cointegration layer | nonlinear/raw I(2)-risk specs |

---

## 11. Next methodological move

The best next move is a wide pre-regression report over the full variable menu.

This should be a descriptive and admissibility layer before any estimator refreeze. It should not estimate the final long-run relation yet.

Required outputs:

1. Variable-menu ledger with source, construction rule, economic role, and expected integration order.
2. Time-series plots in levels for all candidate variables.
3. Time-series plots in first differences or growth rates.
4. Pairwise level plots for theoretically plausible long-run relations.
5. Scatterplots of levels and differences for candidate relations.
6. Integration-order battery: ADF, PP, KPSS, and break-aware checks where relevant.
7. Classification flags: `I0`, `I1`, `I2_RISK`, `BOUNDED_PERSISTENT`, `BREAK_STATIONARY_RISK`, `AMBIGUOUS`.
8. Interaction-risk ledger for raw products, powers, and accumulated weighted paths.
9. Collinearity/design diagnostics for expanded heterogeneous-capital specifications.
10. Pre-regression relation-screening memo identifying which level relations are theory-consistent and visually plausible.

The report should answer, before estimation:

- Which variables can plausibly enter a standard cointegration grid?
- Which variables are only diagnostic?
- Which raw interactions must be blocked?
- Which accumulated paths remain admissible as I(1)?
- Which candidate level relations are visually plausible rather than merely theory-imposed?
- Which specifications should be routed to CPR/polynomial experimentation?

---

## 12. Locked sentence

The preferred recovery of \(\theta_t\) is not the raw interaction \(k_tq_t\) or \(k_t\omega_t\), but the accumulated technique-conditioned capacity path \(Q^{tech}_t=\sum q^*_{s-1}\Delta k_s\), because it preserves accumulation as the source of productive capacity while allowing the distributionally selected technique to govern the elasticity of capacity building.
