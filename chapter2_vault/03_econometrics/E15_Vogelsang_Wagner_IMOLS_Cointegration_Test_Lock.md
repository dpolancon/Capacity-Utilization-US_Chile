---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/others/Ch2_Outline_DEFINITIVE.md
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-08-05
updated_by: VW_PROMOTION_TO_CORE
layer: governance_constraint
role: cointegration_test_lock
stage: post-estimation-diagnostics
tags:
  - chapter2/econometrics
  - chapter2/cointegration
  - chapter2/imols
  - chapter2/vogelsang-wagner
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# E15: Vogelsang-Wagner IM-OLS Cointegration Test Lock

> [!IMPORTANT]
> **Constitutional Declaration (Updated 2026-07-26)**: The **Vogelsang-Wagner (2014) Type 2 IM-OLS Test ($S_{\text{Type 2}}$)** has been fully operationalized via custom matrix algebra in `COMMON_S40_baseline_imols_cpr_estimation.R`. 
> 
> It stands alongside the **Shin (1994) LM stationarity test ($C_{\text{Shin}}$)** and the **Engle-Granger ADF test ($t_{\text{ADF}}$)** to form the complete **3-Test Cointegration Triad** reported across all empirical matrices.
> *See [[E17_Cointegration_Significance_Stars_Lock]] for critical values and Star Reversal rules.*
>
> **2026-08-03 correction**: this test's Wald statistic construction was always sound and was never actually banned in practice (an apparent contradiction with E17 §2's older text, now reconciled). What *was* wrong — found and fixed on this date — were the critical values the statistic was compared against: a single hardcoded triple used for every model regardless of bandwidth or regressor count. E17 §2-3 now documents the corrected, bandwidth- and regressor-count-indexed fixed-$b$ lookup (`codes/COMMON_VW_fixedb_critical_values.R`); the citation is Vogelsang & Wagner (2014), *Journal of Econometrics* 178(2), 741–760 (per [[L00_Econometrics_References]]) — not 2015, and not volume 148 as an earlier draft of this correction mistakenly wrote.

---

## 1. Executive Summary & Hierarchy of Cointegration Diagnostics

In non-linear, disaggregated, and interacted cointegrating specifications (Cointegrating Polynomial Regressions - CPR), traditional residual tests (Engle-Granger, Phillips-Ouliaris) suffer from bandwidth sensitivity and severe pre-testing bias.

The **Vogelsang-Wagner Type 2 IM-OLS Framework** (*Journal of Econometrics*, 2014) provides an intrinsic model specification and cointegration test that operates directly within the integrated regression structure without requiring residual post-filtering.

### Cointegration Hierarchy Lock:

```
┌─────────────────────────────────────────────────────────────────────────┐
│ PRIMARY & BINDING TEST: Vogelsang-Wagner Type 2 Test (\lambda_2 = 0)     │
│ Evaluates whether higher-order double-integrated terms Z_t are zero.   │
│ \lambda_2 = 0 holds under true cointegration; fails under spurious.     │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ SECONDARY ROBUSTNESS CHECKS: Residual Stationarity Suite                │
│ 1. Engle-Granger ADF Test (t_ADF on level residuals u.plus)             │
│ 2. Shin (1994) LM Stationarity Test (C_Shin on u.plus)                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ BACKGROUND DIAGNOSTICS: Johansen & Phillips-Ouliaris (Diagnostic Only)  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Theoretical Mechanics of the Primary Test: VW Type 2 ($\lambda_2 = 0$)

### 2.1 Type 2 IM-OLS Regression Model
Vogelsang and Wagner (2014) construct the Type 2 IM-OLS model by augmenting the integrated partial sum equation with a $k \times 1$ matrix $Z_t$ derived from double-reversed cumulated partial sums of the regressors $x_t$:

$$\text{\bf Type 2 Model:} \quad S_{y, t} = \delta_2' S_{D, t} + \beta_2' S_{x, t} + \gamma_2' x_t + \lambda_2' Z_t + u_{S, t}^{(2)}$$

where $S_{y, t} = \sum_{i=1}^t y_i$, $S_{x, t} = \sum_{i=1}^t x_i$, $S_{D, t} = \sum_{i=1}^t D_i$, and $Z_t$ contains the double-integrated base terms.

---

### 2.2 Decision Rule & Cointegration Identification
1. **Under True Cointegration ($u_t \sim I(0)$)**:
   The true equilibrium relationship is fully specified by $y_t - \beta_1' x_t - \delta_1' D_t = u_t$. In partial sum space, $Z_t$ is redundant:
   $$\mathbb{E}[\hat{\lambda}_2] = 0 \quad \text{and} \quad \hat{\beta}_1 \approx \hat{\beta}_2$$
   A Wald / $F$-test or joint $t$-test on $H_0: \lambda_2 = 0$ confirms valid cointegration.

2. **Under Spurious Regression / No Cointegration ($u_t \sim I(1)$)**:
   $S_{y, t}$ contains $I(2)$ explosive stochastic drift that $S_{x, t}$ cannot eliminate alone. The regression projects onto $Z_t$ to absorb the residual drift:
   $$\hat{\lambda}_2 \neq 0 \quad \text{and} \quad |\hat{\beta}_1 - \hat{\beta}_2| \gg 0$$

---

## 3. Demoted Secondary Robustness Metrics

While $\lambda_2 = 0$ serves as the primary binding cointegration test, two residual stationarity metrics are reported as secondary robustness checks:

1. **Engle-Granger ADF Test ($t_{\text{ADF}}$)**:
   - Evaluated on level residuals $\hat{u}_t^+$ from Type 1 IM-OLS (`fit$u.plus`).
   - $H_0$: Unit root (no cointegration) vs $H_1$: Stationary (cointegration).
   - Rejection ($t_{\text{ADF}} < c_{\alpha}$) provides secondary confirmation of stationarity.

2. **Shin (1994) LM Test ($C_{\text{Shin}}$)**:
   - Evaluated on level residuals $\hat{u}_t^+$ using IM-OLS long-run variance $\hat{\omega}^2$ (`fit$omega.u.v`).
   - $H_0$: Stationarity / cointegration holds vs $H_1$: Unit root.
   - Non-rejection ($C_{\text{Shin}} < c_{\alpha}$) provides secondary confirmation of $I(0)$ error bounds.

---

## 4. Paper-Facing Table Presentation Rule

> [!IMPORTANT]
> **2026-08-05 amendment (`VW_PROMOTION_TO_CORE`)**: this section previously required all
> three tests to appear together in every paper-facing table. That requirement sat awkwardly
> beside §1's own designation of the Type 2 test as PRIMARY & BINDING, and in practice the
> generated tables presented the three as a co-equal "triad" while the surrounding prose led
> with the ADF result — inverting the hierarchy this lock establishes. The rule below
> completes the hierarchy rather than changing it: the main text carries the binding test,
> and the secondary diagnostics move to a named appendix where they can be reported in full
> with their critical values and the star-reversal warning.

**Main-text (core) tables**, for Specification A, Specification B, and the Chilean threshold
specification alike:

1. **One cointegration row only**: the **Vogelsang-Wagner Type 2 statistic ($\lambda_2$ Wald
   test, $H_0$: cointegration)**, placed directly beneath the parameter estimates and above
   the sample-size block.
2. **No residual diagnostics**: `Residual ADF ($t_{\text{ADF}}$)` and `Shin LM ($C_{\text{Shin}}$)`
   do not appear in the main text, nor do the collinearity (VIF) rows or the bandwidth ratio.
3. **Verdict**: assigned on the Type 2 test alone.
4. **Note requirement**: because the Type 2 null *is* cointegration, its stars run opposite to
   the coefficient rows in the same table. The note must state that an absence of stars is the
   favourable result. Where the statistic has not been evaluated against its $(b,k)$-indexed
   fixed-$b$ critical value, the note must say so explicitly rather than presenting a bare
   number that reads as though inference had been performed.

**Appendix tables** (Appendix D of the chapter) carry the full set for every model reported in
the main text: ADF, Shin LM, and Type 2 together, plus VIF rows, the bandwidth ratio $b$, the
critical values in force, and the mandatory star-reversal warning from
[[E17_Cointegration_Significance_Stars_Lock]] §1.

**Implementation**: `chapter2_paper/WP_Chapter2_1.0/split_core_triad_tables.py` derives both
variants from a single source fragment in `reports/`, so the two cannot drift apart. It copies
every cell verbatim and invents no value.

---

## 5. Vault Cross-References

- Map of Content: [[_03_Econometrics_MOC]]
- Active Estimator Lock: [[E10V_IMOLS_CPR_Active_Estimator_Lock]]
- Pre-Testing Protocol: [[N12_PreTesting_Protocol_Integration_Breaks_ChoiceOfTechnique]]
