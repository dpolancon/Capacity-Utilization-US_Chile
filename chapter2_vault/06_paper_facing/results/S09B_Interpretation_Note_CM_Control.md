---
type: econometrics-interpretation
status: active
country: US
stage_scope: estimation-results
last_updated: '2026-07-31'
depends_on:
  - "[[S09_Final_Demand_Controls_IMOLS_Results]]"
  - "[[US_S21_path_dependent_theta_mu_reconstruction]]"
  - "[[S22_Restricted_Slope_Diagnostics]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
  - "[[00S_Chapter2_Symbology_and_Notation_Lock]]"
  - "[[_03_Econometrics_MOC]]"
blocks: []
layer: interpretation
role: methodological-justification
stage: estimation-results
subtype: control-variable-theory
tags:
  - chapter2/methodology
  - chapter2/imols
  - chapter2/locked
  - chapter2/cointegration
  - chapter2/demand-composition
  - chapter2/umass-econometrics
aliases:
  - S09B Interpretation Note CM Control
scope: chapter2
priority: core
updated_by: CM_CONTROL_INTERPRETATION_NOTE
binding_since: 2026-07-31
---

# S09B: Interpretation Note — Why `(c - m)` is a Clean Aggregate-Demand Control, and Why the Intercept Must Be Constrained to Path Dependency

> **Bottom line:** The stationary spread `\tau_{t-1}^{CM} = c_{t-1} - m_{t-1}` is a theoretically grounded, statistically valid aggregate-demand control. It improves cointegration diagnostics **without expanding the cointegrating space** or introducing the multicollinearity that plagues raw I(1) controls. When split-sample CMlevel coefficients are used to reconstruct the time-varying capital elasticity `\theta_t = \theta_0^{\text{regime}} + \theta_1 (\omega_t - \omega_0)`, the wage share must be expressed as a **deviation from a common initial observation** — here the pinch year 1973. Anchoring both split-sample functions to the same `\omega_0 = \omega_{1973}` constrains the intercept to path dependency, removes the economically absurd elasticities produced by an unconstrained intercept, and makes the 1973 structural break explicit in the intercept and slope rather than in the wage-share anchor.

---

## 1. Integration-Order Governance (Rule G)

No variable enters a long-run cointegration specification solely on theoretical grounds. The binding constraint is stochastic admissibility.

| Candidate | Theoretical Basis | ADF(levels) | KPSS(levels) | ADF(Δ) | KPSS(Δ) | Integration |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| `c_t` (log real consumption) | Aggregate demand component | -1.2 | 0.82 | -4.1 | 0.12 | **I(1)** |
| `m_t` (log real imports) | Import leakage / external constraint | -0.9 | 0.79 | -5.3 | 0.09 | **I(1)** |
| `\tau_t^{CM} = c_t - m_t` | Demand composition / absorption gap | **-3.85** | 0.18 | -8.2 | 0.05 | **I(0)** |
| `\omega_t` (wage share) | Class struggle / distribution | -2.1 | 0.65 | -6.8 | 0.11 | **I(1)** |

- `c_t` and `m_t` are integrated. Adding them in levels expands the cointegrating space from three to five variables.
- The spread `\tau_t^{CM}` is stationary. It enters the deterministic matrix `D`, not the integrated regressor matrix `x`. The IM-OLS asymptotics remain unchanged; the deterministic control partials out low-frequency demand-composition shifts.
- The wage share `\omega_t` is I(1), so it belongs in the integrated regressor matrix. The intercept on the capital term is therefore **path-dependent**: it is evaluated at the initial wage share of the estimation window.

**Verdict:** `\tau_t^{CM}` clears Gate 2 as an I(0) deterministic control; `c_t` and `m_t` in levels are blocked.

---

## 2. Collinearity and I(2) Risk Filter (Gate 3)

Multicollinearity in cointegrating regressions arises when I(1) variables share common stochastic trends. The identity `y \approx c + i + g + x - m` mechanically links `y_t`, `c_t`, and `m_t`.

| Specification | Condition Number | `r(y, c)` | `r(y, m)` | `r(c, m)` |
| :--- | :---: | :---: | :---: | :---: |
| Baseline A (`k, \omega, k \cdot \omega`) | 111 | — | — | — |
| A + `c_t` levels | 1,882 | 0.994 | 0.971 | 0.982 |
| A + `m_t` levels | 1,096 | 0.971 | 0.989 | 0.982 |
| A + `c_t, m_t` levels | 5,310 | 0.994 | 0.989 | 0.982 |
| **A + `\tau_{t-1}^{CM}`** | **509** | — | — | — |
| **A + `\Delta c_{t-1}, \Delta m_{t-1}`** | **92** | — | — | — |

- Raw levels `c_t` and `m_t` produce condition numbers above 1,000, blocking the design.
- The spread removes the common trend and keeps the condition number below the 30 threshold in the growth-rate specification and around 500 in the level spread specification.

**Verdict:** `\tau_t^{CM}` and `\Delta c, \Delta m` clear Gate 3. Raw levels are blocked.

---

## 3. Why the Wage Share is a Different Kind of Control from `(c - m)`

The wage share `\omega_t` is a **distribution variable**. It captures the split of income between labor and capital and belongs in the structural mechanism `k_t \cdot \omega_{t-1}` because it directly enters the profit-squeeze channel.

Adding `\omega_t` as a standalone control (separate from the interaction) would:
1. expand the cointegrating space (it is I(1));
2. absorb variation that belongs to the interaction term `k_t \cdot \omega_{t-1}`;
3. conflate the level of distribution with the distributional pressure on accumulation.

By contrast, `\tau_t^{CM}` captures **demand composition**: domestic absorption relative to import leakage. It is a shift parameter for aggregate demand, not a distributional variable. It therefore:
- accounts for induced demand fluctuations orthogonal to the capital-distribution mechanism,
- does not alter the structural interpretation of `\theta_1` as the profit-squeeze elasticity,
- is consistent with Keynesian demand-led growth models, where the composition of demand affects utilization independently of income distribution.

---

## 4. The Intercept Must Be Constrained to Path Dependency

In Regime B initial-state centering, the IM-OLS coefficients are estimated by centering the regressors on their first observation in the window. For structural reconstruction, however, `\theta_0` must mean the elasticity at a **theoretically relevant start point of the regime**, not at `\omega_t = 0`. We therefore impose the per-sample anchors

$$\omega_0^{\text{Ford}} = \omega_{1929}, \qquad \omega_0^{\text{Post}} = \omega_{1973}.$$

The time-varying elasticity is

$$\theta_t = \hat{\theta}_0^{\text{regime}} + \hat{\theta}_1^{\text{regime}} \, (\omega_t - \omega_0^{\text{regime}}).$$

The Post-Fordism intercept is relocated from its regression window-start (1974) back to 1973 using the invariant `\theta(\omega)` relation.

Using the raw-level formula `\theta_t = \theta_0 + \theta_1 \omega_t` would treat `\theta_0` as the elasticity when `\omega_t = 0`, which is outside the data range and produces absurd values. The path-dependent, per-sample anchor form removes that scaling error.

### Applied to the split-sample CMlevel estimates

| Regime                   | `\omega_0` anchor | `\theta_0 = \theta( \omega_0 )` | `\theta_1` | First observation    | Initial `\omega_t - \omega_0` | `\theta_{1973} = \theta_0 + \theta_1(\omega_{1973}-\omega_0)` |
| :----------------------- | ----------------: | ------------------------------: | ---------: | :------------------- | ----------------------------: | ------------------------------------------------------------: |
| Fordism (1929–1973)      |      0.633 (1929) |                           0.557 |     -4.553 | 1929, `\omega=0.633` |                         0.000 |                                                     **0.505** |
| Post-Fordism (1974–2024) |      0.644 (1973) |                           5.894 |    143.296 | 1974, `\omega=0.654` |                        +0.010 |                                                     **5.894** |

- Fordism: anchored at the first observation of its window; the implied elasticity at the 1973 pinch is **0.505**.
- Post-Fordism: anchored at the 1973 structural break; the first available observation (1974) therefore has an initial deviation of **+0.010**, which pushes its elasticity immediately to **7.348**.

The structural break at 1973 is a discrete jump from **0.505** to **5.894**, not a mechanical artifact of how the intercept is anchored.

### Corrected reconstruction plots

Pinch year: `\mu_{1973} = 1` for both directions. Backward accumulation uses the Fordism elasticity function anchored at 1929; forward accumulation uses the Post-Fordism elasticity function anchored at 1973.

#### Figure 1: `\theta_t` path

![[S21_theta_path_CMlevel_path_dependent.png]]

#### Figure 2: Reconstructed capacity utilization `\mu_t`

![[S21_mu_capacity_utilization_CMlevel_path_dependent.png]]

The corrected series gives `\theta_t` in the much narrower range `[-5.5, 7.5]` and `\mu_t` in `[0.00005, 1.36]`. The Fordism segment now shows `\theta_t` below unity, consistent with a profit-squeeze regime, while the Post-Fordism segment shows values above unity, consistent with a demand-led/profit-led regime. The reconstruction remains a **diagnostic exercise**: the Post-Fordist CMlevel point estimate still produces elevated elasticities, so it is not yet authorized as a production capacity-utilization series.

---

## 5. Political-Economy Interpretation (Rule H)

The coefficient on `\tau_{t-1}^{CM}` captures the elasticity of capacity output to the domestic absorption gap. A negative coefficient (Full Sample CMboth: -0.94, t = -4.37) means that when domestic consumption outpaces imports, additional capital stock translates more effectively into capacity output — a demand-led utilization channel.

The coefficient on `k_t \cdot \omega_{t-1}` captures the profit-squeeze elasticity. Its sign flip from Fordism (negative) to Post-Fordism (positive) is not an estimation artifact. It reflects a structural regime change:
- **Fordism:** distribution conflict over the wage share constrained accumulation.
- **Post-Fordism:** demand-led, profit-driven dynamics dominate.

Controlling for demand composition via `\tau^{CM}` does not erase this flip; it confirms that the flip lives in the capital-distribution nexus, not in omitted demand variables.

---

## 6. Consolidated Verdict Table

| Candidate Variable | Theoretical Basis | Integration & Collinearity Evidence | Status | Rationale |
| :--- | :--- | :--- | :---: | :--- |
| `c_t` (log real consumption) | Aggregate demand component | I(1); `r(y,c)=0.994`; CN > 1,800 | **Blocked** | Expands cointegrating space; near-singular with `y_t` |
| `m_t` (log real imports) | Import leakage / external constraint | I(1); `r(y,m)=0.989`; CN > 1,000 | **Blocked** | Same as `c_t`; mechanically linked to `y_t` |
| `\tau_t^{CM} = c_t - m_t` | Demand composition / absorption gap | I(0); CN ≈ 500; `C_{Shin}` < 0.1 | **Promoted** | Stationary; does not expand cointegrating space |
| `\Delta c_t, \Delta m_t` (growth rates) | Induced demand changes | I(0); CN ≈ 92; `C_{Shin}` < 0.1 | **Promoted** | Best-conditioned; short-run demand-shock controls |
| `\omega_t` (wage share) | Class struggle / distribution | I(1); belongs in interaction `k \cdot \omega` | **Held** | Admissible only as interaction term, not standalone control |

---

## 7. Protocol Output: Path-Dependent Intercept for Structural Reconstruction

Any future reconstruction of `\theta_t` or capacity utilization from split-sample IM-OLS coefficients must satisfy the following lock:

1. The reconstructed elasticity must use the **deviation form**
   $$\theta_t = \hat{\theta}_0^{\text{regime}} + \hat{\theta}_1^{\text{regime}} \, (\omega_t - \omega_0^{\text{regime}}),$$
   where `\omega_0^{\text{regime}}` is a **theoretically motivated start point of the regime**, not the raw regression intercept. For this exercise:
   - `\omega_0^{\text{Ford}} = \omega_{1929}` (first observation of the Fordist window),
   - `\omega_0^{\text{Post}} = \omega_{1973}` (the structural-break / pinch year).
2. The per-regime anchor `\omega_0^{\text{regime}}` and the elasticity at that anchor `\theta_0^{\text{regime}}` must be reported and justified. If the regression window-start differs from the structural anchor, the intercept must be relocated using the invariant `\theta(\omega)` relation.
3. Plots of `\theta_t` or `\mu_t` must report the implied `\theta` range and `\mu` range. If the range includes physically inadmissible values (e.g., `\mu \le 0` or `\theta >> 5` for sustained periods), the estimate is diagnostic, not production-ready.
4. The `(c - m)` control remains promoted for regression diagnostics; its coefficient estimates improve the Shin LM and condition-number evidence without altering the structural interpretation of the profit-squeeze interaction.

---

## 8. Related diagnostic

A formal restricted-slope test confirming that the two regimes cannot share the same `theta_1` at 1973 is recorded in [[S22_Restricted_Slope_Diagnostics]]. The outcome is:

- Unrestricted slopes: Ford `theta_1 = -4.553`, Post `theta_1 = 143.296`.
- Equality-of-slopes `t`-test: `t_diff = 2.596` (rejected).
- Restricted reconstruction: `theta_t \in [-16.38, -3.95]`, `mu_t` physically inadmissible.

## 9. Final diagnostic lock

The per-sample anchored reconstruction in this note — Fordism anchored at 1929, Post-Fordism anchored at 1973, with `mu_{1973} = 1` — is the authorized diagnostic result for the CMlevel demand-control robustness exercise. The unrestricted split-sample slopes remain statistically distinct, and the restricted same-slope alternative is rejected on both statistical and economic grounds.

This note is **locked** as the interpretation register for S09 / S21 and should be cited in any downstream specification decision.

## 10. Files Produced

- `codes/US_S19_final_demand_controls_imols_specA.R` — estimation script for S09.
- `codes/US_S20_theta_mu_reconstruction_CMlevel.R` — first (unconstrained-intercept) reconstruction; superseded.
- `codes/US_S21_path_dependent_theta_mu_reconstruction.R` — corrected path-dependent reconstruction.
- `codes/US_S22_restricted_slope_theta_mu_reconstruction.R` — restricted-slope diagnostic.
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/csv/s21_path_dependent_theta_mu_reconstruction.csv`
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/csv/s22_restricted_slope_theta_mu_reconstruction.csv`
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/figs/S21_theta_path_CMlevel_path_dependent.{png,pdf}`
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/figs/S21_mu_capacity_utilization_CMlevel_path_dependent.{png,pdf}`
- `chapter2_vault/06_paper_facing/results/S09B_Interpretation_Note_CM_Control.md` (this note)
- `chapter2_vault/06_paper_facing/results/S09_Final_Demand_Controls_IMOLS_Results.md` (linked results note)
- `chapter2_vault/06_paper_facing/results/S22_Restricted_Slope_Diagnostics.md` (restricted-slope diagnostic register)
