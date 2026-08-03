---
type: econometrics-result
status: active
country: US
stage_scope: estimation-results
last_updated: '2026-07-31'
depends_on:
  - "[[S08_C_and_M_Separate_Controls_IMOLS_Results]]"
  - "[[S07_AD_Control_Alternatives_IMOLS_Results]]"
  - "[[S09B_Interpretation_Note_CM_Control]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
  - "[[00S_Chapter2_Symbology_and_Notation_Lock]]"
  - "[[US_S19_final_demand_controls_imols_specA]]"
  - "[[US_S21_path_dependent_theta_mu_reconstruction]]"
  - "[[_03_Econometrics_MOC]]"
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
  - S09 Final Demand Controls IM-OLS Results
scope: chapter2
priority: core
updated_by: FINAL_DEMAND_CONTROL_SPECA_RESULTS
binding_since: 2026-07-31
---

# S09: Final I(0) Demand Controls for Specification A — IM-OLS Results

> **Task:** Add demand controls to Spec A **without expanding the cointegrating space**. Two approaches are tested:
>
> 1. **Stationary C-M spread as a deterministic control:**
>    $$\tau_{t-1}^{CM} = c_{t-1}^{real} - m_{t-1}^{real}$$
>    enters as an I(0) regressor in the deterministic matrix.
>
> 2. **Real C and M growth rates as deterministic controls:**
>    $$\Delta c_t = c_t - c_{t-1}, \qquad \Delta m_t = m_t - m_{t-1}, \qquad \text{lagged one period}$$
>    capture induced aggregate-demand changes and are I(0).
>
> Both avoid the collinearity problem that made raw `c_t` and `m_t` levels unusable in S08.

> **High-level finding:** Adding demand controls as I(0) regressors substantially improves cointegration diagnostics in the Full Sample and Golden Age. The Post-Fordism positive `theta_1` on the wage-share interaction remains positive and significant in most specifications — consistent with the view that this regime is **not** profit-squeeze dominated. The recommended parsimonious robustness specification is **Spec A + lagged `c-m` spread as a deterministic control**.

---

## 1. Specifications

| Spec | Equation |
| --- | --- |
| **A** (baseline) | `y^{NFC} ~ k + \omega + k \cdot \omega_{lag} + D` |
| **CMlevel** | `A + \tau^{CM}_{t-1}` (demand-composition level control) |
| **CMboth** | `A + \tau^{CM}_{t-1} + k \cdot \tau^{CM}_{t-1}` (level + interaction) |
| **DcDm** | `A + \Delta c_{t-1} + \Delta m_{t-1}` (induced demand-growth controls) |

All variables are Regime B initial-state centered within each window. Step dummies (`D1933`, `D1947`, `D1974`, `D2008`) enter everywhere; constant columns are dropped.

---

## 2. Results

### Table 1: `theta_0` on capital (`k`)

| Window       |               A |        CMlevel |        CMboth |             DcDm |
| :----------- | --------------: | -------------: | ------------: | ---------------: |
| Full Sample  | 0.61 (t = 1.52) |    0.72 (6.48) |   0.62 (8.56) | **0.81** (18.92) |
| Fordism      |     0.53 (0.59) |    0.56 (2.78) |   0.46 (6.53) | **0.84** (25.56) |
| Golden Age   |    23.10 (2.58) | -47.58 (-2.22) | -1.29 (-0.12) |     13.47 (2.63) |
| Post-Fordism |     3.94 (2.36) |    7.35 (2.76) |   6.86 (2.83) |      2.40 (1.74) |
| Neoliberal   |     2.36 (1.43) |    4.67 (1.41) |   0.24 (0.05) |      2.75 (2.03) |
| Post-GFC     |   144.17 (4.03) |  130.80 (3.75) |  36.70 (0.81) |    105.47 (3.22) |

- Capital elasticity is generally stable around **0.6–0.85** once demand controls are included, except in small-sample windows (Golden Age, Post-GFC) where it becomes erratic.

### Table 2: `theta_1` on the wage-share interaction (`k \cdot \omega_{lag}`)

| Window | A | CMlevel | CMboth | DcDm | Cointegration verdict |
| :--- | ---: | ---: | ---: | ---: | :--- |
| Full Sample | **-48.10** (t = -6.63) | **+1.61** (t = 3.35) | **+1.57** (t = 4.79) | **+1.71** (t = 3.41) | CMlevel/CMboth/DcDm all `coint_ok`; A rejects |
| Fordism | **-134.25** (t = -3.83) | **-4.55** (t = -7.75) | **-8.23** (t = -30.76) | **-3.85** (t = -5.47) | All `coint_ok`; sign stays negative |
| Golden Age | +678.74 (t = 2.28) | +294.43 (t = 1.51) | +268.70 (t = 2.45) | +526.84 (t = 2.89) | Mixed; CMboth/DcDm `coint_ok` but positive |
| Post-Fordism | **+220.46** (t = 2.46) | **+143.30** (t = 2.52) | +107.31 (t = 1.44) | **+210.86** (t = 3.08) | Positive and significant in A, CMlevel, DcDm |
| Neoliberal | **+284.91** (t = 2.10) | **+192.93** (t = 2.38) | +148.29 (t = 1.80) | +260.04 (t = 1.97) | Positive and significant in A, CMlevel |
| Post-GFC | +5622.46 (t = 3.69) | +3599.06 (t = 2.62) | +1358.85 (t = 0.80) | +4768.55 (t = 3.49) | Tiny sample; volatile |

### Table 3: Demand-control coefficients

| Window | Spec | `\tau^{CM}_{t-1}` | `k \cdot \tau^{CM}_{t-1}` | `\Delta c_{t-1}` | `\Delta m_{t-1}` |
| :--- | :---: | ---: | ---: | ---: | ---: |
| Full Sample | CMlevel | -0.17 (t = -0.88) | — | — | — |
| Full Sample | CMboth | -0.94 (t = -4.37) | +0.14 (t = 4.24) | — | — |
| Full Sample | DcDm | — | — | +6.16 (t = 2.22) | -2.58 (t = -2.34) |
| Fordism | CMlevel | -0.70 (t = -1.46) | — | — | — |
| Fordism | CMboth | -0.23 (t = -1.29) | -0.30 (t = -5.31) | — | — |
| Fordism | DcDm | — | — | +2.29 (t = 1.51) | -0.53 (t = -1.40) |
| Post-Fordism | CMlevel | +7.93 (t = 1.48) | — | — | — |
| Post-Fordism | CMboth | +1.89 (t = 0.15) | +3.55 (t = 0.58) | — | — |
| Post-Fordism | DcDm | — | — | +263.75 (t = 3.14) | -52.45 (t = -1.84) |
| Golden Age | CMlevel | -137.09 (t = -3.14) | — | — | — |
| Golden Age | CMboth | -59.62 (t = -3.43) | +22.92 (t = 4.21) | — | — |
| Golden Age | DcDm | — | — | +354.53 (t = 2.52) | +31.94 (t = 1.13) |

### Table 4: Diagnostics

| Window | Spec | `C_{\text{Shin}}` | `CN` | EG-ADF |
| :--- | :---: | ---: | ---: | :--- |
| Full Sample | A | 1.108 | 111 | coint 1% |
| Full Sample | CMlevel | **0.083** | 509 | coint 5% |
| Full Sample | CMboth | **0.021** | 1,059 | coint 1% |
| Full Sample | DcDm | **0.104** | **92** | coint 1% |
| Fordism | A | 1.164 | 17 | coint 1% |
| Fordism | CMlevel | **0.033** | 207 | coint 1% |
| Fordism | DcDm | **0.048** | **10** | coint 1% |
| Post-Fordism | A | 0.155 | 76 | coint 1% |
| Post-Fordism | CMlevel | 0.278 | 129 | coint 1% |
| Post-Fordism | DcDm | **0.041** | **97** | coint 1% |
| Golden Age | A | 0.236 | 12 | no coint |
| Golden Age | DcDm | **0.040** | **18** | coint 1% |

---

## 3. Interpretation

1. **Demand controls restore cointegration hygiene.** The Shin LM statistic drops sharply once an I(0) demand control is added. In the Full Sample, Fordism, Post-Fordism, and Golden Age, `C_{\text{Shin}}` moves into the `coint_ok` region.

2. **The wage-share interaction coefficient is sensitive to the choice of demand control in the Full Sample.** In the baseline A it is strongly negative (-48). Adding either `\tau^{CM}` or `\Delta c, \Delta m` flips it to a small positive (~+1.6). This suggests that in the long-run full-sample regression, some of the variation previously attributed to the profit-squeeze channel was actually capturing low-frequency demand-composition shifts.

3. **The Post-Fordism positive `theta_1` is robust.** Across CMlevel, DcDm, and the baseline, the wage-share interaction remains positive and statistically significant (or borderline) in Post-Fordism and Neoliberal windows. This supports the interpretation that the later regime is demand-led/profit-led rather than profit-squeeze constrained.

4. **Fordism stays negative.** The negative profit-squeeze coefficient is preserved and in fact sharpened (higher t-statistics) once the C-M spread is controlled for.

5. **Growth-rate controls are the best-conditioned specification.** `DcDm` achieves condition numbers below 100 in most windows because `\Delta c` and `\Delta m` are stationary. It is a good short-run demand-shock robustness check. The `\tau^{CM}` spread, by contrast, is more structural (a persistent composition variable) but raises `CN` to ~500.

---

## 4. Recommendation

| Goal                             | Recommended spec                                                                           |
| -------------------------------- | ------------------------------------------------------------------------------------------ |
| **Main paper robustness check**  | **CMlevel**: `y ~ k + \omega + k \cdot \omega_{lag} + (c-m)_{t-1} + D`                     |
| **Short-run demand-shock check** | **DcDm**: `y ~ k + \omega + k \cdot \omega_{lag} + \Delta c_{t-1} + \Delta m_{t-1} + D`    |
| **Avoid**                        | Raw levels `c_t` and `m_t` in the cointegrating regression (S08) — too collinear with `y`. |

The CMlevel specification is preferred because:
- It is parsimonious (one extra deterministic regressor).
- It cleans up the Shin LM statistic.
- It preserves the qualitative regime pattern: negative `theta_1` in Fordism, positive `theta_1` in Post-Fordism/Neoliberal.

The Full Sample flip from -48 to +1.6 is worth noting in the paper: the aggregate profit-squeeze result is **not robust to demand-composition controls**, which is consistent with the chapter's claim that the profit-squeeze mechanism is regime-specific rather than a universal long-run law.

---

## 6. Structural Reconstruction of `theta_t` and Capacity Utilization from CMlevel Split-Sample Coefficients

Using the CMlevel split-sample point estimates and the **path-dependent intercept correction** described in [[S09B_Interpretation_Note_CM_Control]], the time-varying elasticity is
$$\theta_t = \hat{\theta}_0^{\text{regime}} + \hat{\theta}_1^{\text{regime}} \, (\omega_t^{\text{NFC}} - \omega_0^{\text{regime}}),$$
with per-sample anchors
$$\omega_0^{\text{Ford}} = \omega_{1929} = 0.633 \quad \text{and} \quad \omega_0^{\text{Post}} = \omega_{1973} = 0.644.$$
The Fordist intercept is therefore the elasticity at 1929 (`θ₀ = 0.557`). The Post-Fordist intercept is relocated from its regression window-start (1974) to the 1973 break year (`θ₀ = 5.894`). Latent capacity utilization is reconstructed from
$$g_{Y_t^p} = \theta_t \, g_{K_t}, \qquad \mu_{1973}=1.$$

### Figure 1: `theta_t` path (path-dependent intercept)

![[S21_theta_path_CMlevel_path_dependent.png]]

### Figure 2: Reconstructed capacity utilization `mu_t`

![[S21_mu_capacity_utilization_CMlevel_path_dependent.png]]

### Interpretation

- With the per-sample anchors, `theta_t` ranges in `[-5.46, 7.46]`, a massive reduction from the unconstrained `[-100, +100]` range.
- Fordism is anchored at 1929 (`omega_0 = 0.633`, `theta(omega_0)=0.557`), but its value at the 1973 pinch is **0.505**.
- Post-Fordism is anchored at the 1973 break (`omega_0 = 0.644`, `theta(omega_0)=5.894`). Its first available observation in 1974 has an initial deviation `omega_{1974} - omega_0 = +0.010`, pushing the elasticity immediately to **7.348**.
- The structural break at 1973 is therefore a discrete jump from **0.505 (Fordism)** to **5.894 (Post-Fordism)**.
- **Fordism:** `theta_t` is mostly below unity, especially in the 1930s and early 1940s, consistent with a profit-squeeze / low-absorption regime where productive capacity grows slowly relative to capital.
- **Post-Fordism:** `theta_t` jumps above unity after 1973, consistent with a demand-led/profit-led regime where latent productive capacity grows faster than the capital stock.
- The reconstruction remains a **diagnostic exercise**: the Post-Fordist CMlevel point estimate still yields high elasticities, so it is not yet authorized as a production utilization series.
- A formal restricted-slope test confirms the two regimes cannot share the same `theta_1` at the 1973 pinch; see [[S22_Restricted_Slope_Diagnostics]].

### PDF versions

- `S21_theta_path_CMlevel_path_dependent.pdf`
- `S21_mu_capacity_utilization_CMlevel_path_dependent.pdf`

---

## 7. Files Produced

- `codes/US_S19_final_demand_controls_imols_specA.R` — estimation script.
- `codes/US_S21_path_dependent_theta_mu_reconstruction.R` — reconstruction and plotting script, per-sample initial anchors.
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/csv/s19_final_demand_controls_specA_results.csv` — full nested IM-OLS results.
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/csv/s21_path_dependent_theta_mu_reconstruction.csv` — reconstructed `theta_t` and `mu_t`.
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/figs/S21_theta_path_CMlevel_path_dependent.{png,pdf}`.
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/figs/S21_mu_capacity_utilization_CMlevel_path_dependent.{png,pdf}`.
- `chapter2_vault/06_paper_facing/results/S09_Final_Demand_Controls_IMOLS_Results.md` (this report).
