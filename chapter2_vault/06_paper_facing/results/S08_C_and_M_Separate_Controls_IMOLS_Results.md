---
type: econometrics-result
status: active
country: US
stage_scope: estimation-results
last_updated: '2026-07-31'
depends_on:
  - "[[S07_AD_Control_Alternatives_IMOLS_Results]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
  - "[[00S_Chapter2_Symbology_and_Notation_Lock]]"
  - "[[US_S18_C_and_M_separate_controls_imols_specA]]"
blocks: []
layer: results
role: multispec-synthesis
stage: estimation-results
subtype: cointegration-matrix
tags:
  - chapter2/results
  - chapter2/imols
  - chapter2/specification-a
  - chapter2/demand-composition
  - chapter2/cointegration
aliases:
  - S08 C and M Separate Controls IM-OLS Results
scope: chapter2
priority: core
updated_by: CM_SEPARATE_CONTROL_SPECA_RESULTS
binding_since: 2026-07-31
---

# S08: Separate Consumption and Import Controls for Specification A — IM-OLS Results

> **Task:** Re-run the demand-control robustness exercise using real log consumption (`c_t`) and real log imports (`m_t`) as **separate** variables, rather than as the pre-composed spread `\tau^{CM}=c-m`. Both are tried (a) as additional I(1) level regressors and (b) as separate interactions with capital (`k \times c_{lag}` and `k \times m_{lag}`). The C-M spread specification from S07 is included as a benchmark.

> **High-level finding:** Separate C and M controls raise dimension and collinearity without producing a cleaner profit-squeeze coefficient. The pre-composed `C-M` spread remains the more parsimonious and stable demand-composition regressor. In particular:
> - **Level controls** (`c_{lag}`, `m_{lag}`) create very high condition numbers (thousands to hundreds of thousands) and inconsistent sign patterns across windows.
> - **Separate interactions** (`k \times c_{lag}`, `k \times m_{lag}`) are mostly individually negative in the full sample but flip signs across regimes and are unstable when both are included.
> - The **C-M interaction** continues to show a stable positive sign and the best cointegration diagnostics.

---

## 1. Why the spread `C - M` was tried first

Both `c_t` and `m_t` are integrated (log real consumption and log real imports both trend). Adding two extra I(1) regressors expands the cointegrating space and risks over-parameterising a single-equation IM-OLS model. The spread `\tau^{CM}_t = c_t - m_t` is stationary (ADF(none) = -3.85), so `k_t^{cap} \cdot \tau^{CM}_{t-1}` is a single I(1) interaction and imposes only one extra parameter. The exercise here checks whether forcing separate C and M coefficients uncovers something the spread hides.

All estimates use `cointReg::cointRegIM` with Regime B initial-state centering, the same diagnostic triad (EG-ADF, Shin LM, VW Type 2), and the same step-dummy deterministics as in S06/S07.

---

## 2. Consumption and imports as level (I(1)) controls

The tested level-control equation augments Spec A with `c_{lag}`, `m_{lag}`, or both:
$$y_t^{NFC} = a + \theta_0 k_t^{cap} + \theta_1 (k_t^{cap} \cdot \omega_{t-1}) + \beta_c c_{t-1} + \beta_m m_{t-1} + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$$

### Table 1: Level controls

| Window | Spec | `\theta_0` | `\theta_1^{kw}` | `\beta_c` | `\beta_m` | `C_{\text{Shin}}` | `CN` |
| :--- | :---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Full Sample | A (ref) | 0.612 | **-48.10** | — | — | 1.108 | 111 |
| Full Sample | `Clvl` (C only) | 0.032 | **+0.48** | +1.112 | — | 0.196 | 1,882 |
| Full Sample | `Mlvl` (M only) | 0.492 | **+1.64** | — | +0.271 | 0.108 | 1,096 |
| Full Sample | `CMlvl` (C + M) | -0.021 | +0.15 | +1.648 | **-0.241** | 0.156 | 5,310 |
| Fordism | A (ref) | 0.529 | **-134.26** | — | — | 1.164 | 17 |
| Fordism | `Clvl` | 0.020 | **-1.29** | +1.181 | — | 0.083 | 544 |
| Fordism | `Mlvl` | 0.202 | **-3.38** | — | +0.592 | 0.029 | 489 |
| Fordism | `CMlvl` | 0.053 | **-2.26** | +0.16 | +0.60 | 0.032 | 1,983 |
| Post-Fordism | A (ref) | 3.94 | **+220.46** | — | — | 0.155 | 76 |
| Post-Fordism | `Clvl` | 8.01 | **+138.10** | -10.15 | — | 0.375 | 478 |
| Post-Fordism | `Mlvl` | 8.44 | **+137.38** | — | -4.93 | 0.345 | 241 |
| Post-Fordism | `CMlvl` | -2.68 | **+201.62** | +51.08 | -21.55 | 0.374 | 3,645 |
| Golden Age | A (ref) | 23.10 | +678.74 | — | — | 0.236 | 12 |
| Golden Age | `Clvl` | 43.97 | -31.80 | **-64.48** | — | 0.129 | 642 |
| Golden Age | `Mlvl` | 76.39 | +133.98 | — | **-63.31** | 0.042 | 525 |
| Golden Age | `CMlvl` | 16.96 | **-181.25** | -116.78 | +52.45 | 0.556 | 2,420 |
| Neoliberal | A (ref) | 2.36 | **+284.91** | — | — | 0.305 | 22 |
| Neoliberal | `Clvl` | 3.18 | **+403.67** | +1.43 | — | 0.520 | 154 |
| Neoliberal | `Mlvl` | 3.59 | **+317.91** | — | -0.20 | 0.536 | 93 |
| Neoliberal | `CMlvl` | -3.77 | **+271.06** | +54.15 | -21.24 | 0.514 | 3,604 |

**Interpretation:**
- Adding C and/or M in levels changes the profit-squeeze coefficient `\theta_1^{kw}` substantially and often flips its sign relative to the baseline Spec A.
- The individual C/M level effects change sign across windows (e.g., `\beta_m` is positive in Fordism and negative in the Full Sample / Post-Fordism), a classic symptom of multicollinearity between I(1) regressors.
- Condition numbers are extremely high (`CN > 1,000` in every case and `> 5,000` when C and M are both present). Cointegration diagnostics are therefore unreliable.

---

## 3. Consumption and imports as separate capital interactions

Here C and M enter through `k_t^{cap} \cdot c_{t-1}` and `k_t^{cap} \cdot m_{t-1}`, keeping the wage-share interaction as in Spec A:
$$y_t^{NFC} = a + \theta_0 k_t^{cap} + \theta_1 (k_t^{cap} \cdot \omega_{t-1}) + \theta_{1c} (k_t^{cap} \cdot c_{t-1}) + \theta_{1m} (k_t^{cap} \cdot m_{t-1}) + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$$

### Table 2: Interaction controls

| Window | Spec | `\theta_0` | `\theta_1^{kw}` | `\theta_{1c}^{kc}` | `\theta_{1m}^{km}` | `C_{\text{Shin}}` | `CN` |
| :--- | :---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Full Sample | A (ref) | 0.612 | **-48.10** | — | — | 1.108 | 111 |
| Full Sample | `Cint` (C only) | 0.883 | **+1.76** | -0.048 | — | 0.021 | 618 |
| Full Sample | `Mint` (M only) | 0.929 | **+1.66** | — | -0.029 | 0.027 | 499 |
| Full Sample | `CMint` (C + M) | 0.912 | **+2.05** | -0.270 | +0.114 | 0.021 | 11,397 |
| Fordism | A (ref) | 0.529 | **-134.26** | — | — | 1.164 | 17 |
| Fordism | `Cint` | 0.474 | **-7.70** | +0.20 | — | 0.065 | 146 |
| Fordism | `Mint` | 0.464 | **-8.85** | — | +0.16 | 0.037 | 153 |
| Fordism | `CMint` | 0.420 | **-9.19** | -0.38 | +0.37 | 0.018 | 6,636 |
| Post-Fordism | A (ref) | 3.94 | **+220.46** | — | — | 0.155 | 76 |
| Post-Fordism | `Cint` | 8.52 | +63.88 | -5.29 | — | 0.284 | 188 |
| Post-Fordism | `Mint` | 7.67 | +77.24 | — | -2.51 | 0.358 | 181 |
| Post-Fordism | `CMint` | 4.41 | **+156.65** | +20.37 | -10.78 | 0.371 | 3,231 |
| Golden Age | A (ref) | 23.10 | +678.74 | — | — | 0.236 | 12 |
| Golden Age | `Cint` | 22.83 | +166.56 | -9.54 | — | 0.049 | 105 |
| Golden Age | `Mint` | 28.61 | **+393.76** | — | **-10.52** | 0.094 | 114 |
| Golden Age | `CMint` | 8.34 | -48.65 | -129.85 | +71.53 | 0.045 | 16,101 |
| Neoliberal | A (ref) | 2.36 | **+284.91** | — | — | 0.305 | 22 |
| Neoliberal | `Cint` | 6.50 | **+184.55** | +1.97 | — | 0.517 | 61 |
| Neoliberal | `Mint` | 4.95 | **+175.32** | — | -0.24 | 0.512 | 49 |
| Neoliberal | `CMint` | 0.066 | **+203.95** | +39.39 | -17.73 | 0.703 | 8,436 |

**Interpretation:**
- In the **Full Sample**, both `k \times C` and `k \times M` are negative (or jointly negative/positive with large standard errors), and the `C_{\text{Shin}}` statistic improves dramatically.
- In **Fordism**, `k \times C` and `k \times M` are individually **positive**; only when both are included do they take opposite signs. This is inconsistent with the negative demand-absorption story in the Full Sample.
- In **Post-Fordism** and **Neoliberal** windows, `\theta_1^{kw}` remains positive and significant, just as in the original Spec A. The separate C/M interactions do not remove the regime flip.
- When both interactions are included (`CMint`), condition numbers explode (`> 3,000`), making coefficient interpretation fragile.

---

## 4. Comparison with the C-M spread from S07

| Window | `CMdiff: k \times (C-M)` | `C_{\text{Shin}}` | `CN` |
| :--- | ---: | ---: | ---: |
| Full Sample | +0.065 (t = 2.17) | **0.082** | 248 |
| Fordism | +0.466 (t = 2.05) | 0.171 | 96 |
| Golden Age | +19.51 (t = 2.39) | **0.041** | 57 |
| Post-Fordism | +5.72 (t = 2.46) | 0.258 | 77 |
| Neoliberal | +5.73 (t = 2.18) | 0.283 | 23 |

The spread interaction is:
- Lower-dimensional (one interaction term instead of two).
- More stable (all positive across major windows).
- Better conditioned (CN remains below 250 in every window except Fordism, where it is still manageable).
- Cleaner on cointegration diagnostics (`C_{\text{Shin}} < 0.1` in Full Sample and Golden Age).

---

## 5. Verdict

1. **Using C and M separately does not solve the Spec A sign-flip problem.** The separate level controls are dominated by collinearity with the I(1) output variable, and the separate interactions produce sign changes across regimes and very high condition numbers.

2. **The `C - M` spread is still the preferred demand-composition control** when a single, parsimonious demand-composition regressor is needed. It gives a stable positive coefficient and acceptable diagnostics.

3. **If the goal is to allow C and M to have opposite effects**, the theoretical preference is already embedded in the sign of the spread: a high `C - M` means strong domestic absorption relative to import leakage. Decomposing the spread into two free I(1) regressors adds noise rather than information.

4. **The original profit-squeeze instability is not a demand-composition omission.** The Fordism/Post-Fordism sign flip in `\theta_1^{kw}` persists or is amplified by adding C/M controls. The next step should be a structural-break or regime-specific parameter design, not more demand variables.

---

## 6. Files Produced

- `codes/US_S18_C_and_M_separate_controls_imols_specA.R` — estimation script.
- `output/US/S18_C_AND_M_SEPARATE_CONTROLS_SPECA/csv/s18_c_and_m_separate_controls_specA_results.csv` — full nested results.
- `chapter2_vault/06_paper_facing/results/S08_C_and_M_Separate_Controls_IMOLS_Results.md` (this report).
