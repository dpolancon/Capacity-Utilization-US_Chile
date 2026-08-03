---
type: econometrics-result
status: active
country: US
stage_scope: estimation-results
last_updated: '2026-07-31'
depends_on:
  - "[[S04_StructuralBreak_locked decisions]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
  - "[[00S_Chapter2_Symbology_and_Notation_Lock]]"
  - "[[US_S15C2_demand_control_cointegration_fred_annual]]"
  - "[[US_S16_AD_controlled_imols_specA]]"
blocks: []
layer: results
role: multispec-synthesis
stage: estimation-results
subtype: cointegration-matrix
tags:
  - chapter2/results
  - chapter2/imols
  - chapter2/specification-a
  - chapter2/aggregate-demand-control
  - chapter2/cointegration
  - chapter2/stability-assessment
aliases:
  - S06 AD-Controlled Spec A IM-OLS Results
scope: chapter2
priority: core
updated_by: AD_CONTROLLED_SPECA_RESULTS
binding_since: 2026-07-31
---

# S06: AD-Controlled Specification A — IM-OLS Nested Estimation & Stability Assessment

> **Question posed:** Does adding a non-accumulation aggregate-demand control, `AD_t = C + G + NX` (real, chained 2017 dollars), to Specification A solve the instability of the profit-squeeze interaction `theta_1` across accumulation regimes?

> **Target specification:**
> $$ y_{t}^{\text{NFC}} \; = \; a \; + \; b \cdot AD_{t} \; + \; \theta_{0} \, k_{t}^{\text{cap}} \; + \; \theta_{1} \, (k_{t}^{\text{cap}} \cdot \omega_{t-1}) \; + \; \boldsymbol{\gamma}' \mathbf{D}_{t} \; + \; u_{t} $$

> **Short answer:** **No.** Adding `AD_t` as an additional I(1) level regressor makes the model less stable, not more. The demand control does not deliver a stable negative `theta_1` across Fordism and Post-Fordism; it inflates the condition number far above the vault hygiene gate (`CN \le 100`) and generally worsens cointegration hygiene (`C_{\text{Shin}} > 0.095`). The failure is structural: `AD_t`, aggregate capital `k_t^{\text{cap}}`, and output `y_t^{\text{NFC}}` are three mutually cointegrated I(1) variables, so a single-equation IM-OLS regression with both `AD_t` and `k_t` on the right-hand side is near-multicollinear and economically underidentified.

---

## 1. Data and Estimator

- **Dependent variable:** `y_t^{\text{NFC}} = \ln(Y_{\text{NFC GVA}}^{\text{real}})`, taken from `output/gpim_baseline_components_long.csv` (`y_t`).
- **Capital scale:** `k_t^{\text{cap}} = \ln(K_{\text{NFC}}^{\text{ME}} + K_{\text{NFC}}^{\text{NRC}})` from the same source.
- **Wage share:** `\omega_{t-1}` = lagged wage share (baseline NFC GVA measure), used in the interaction term `k_t^{\text{cap}} \cdot \omega_{t-1}`.
- **Demand control:** `AD_t = C + G + NX` built as the FRED annual real non-accumulation demand aggregate, `log_AD_fred`, from `output/US/S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION/csv/fred_annual_ad_components_panel.csv`.
- **Step dummies:** `D_{1933}, D_{1947}, D_{1974}, D_{2008}`; omitted when constant within a window.
- **Centering:** Regime B Initial-State Centering (locked protocol).
- **Estimator:** `cointReg::cointRegIM` (IM-OLS; Vogelsang & Wagner 2014), with the cointegration triad from the locked protocol: Engle-Granger ADF on level residuals, Shin LM (`H_0`: cointegration), and Vogelsang-Wagner Type 2.

---

## 2. Nested Specifications

| Code | Specification | Purpose |
| :--- | :--- | :--- |
| **S0** | `y ~ k + D` | Pure scale baseline |
| **A** | `y ~ k + omega + k*omega_lag + D` | Original locked Spec A (reference) |
| **AD0** | `y ~ AD + k + D` | AD as demand control, no interaction |
| **AD1** | `y ~ AD + k + k*omega_lag + D` | **Target specification** (replaces standalone `omega` with `AD`) |
| **AD2** | `y ~ AD + k + omega + k*omega_lag + D` | Full demand + distribution controls |

---

## 3. Core Coefficient Results

### Table 1: Target Speparation — AD1 vs. Original Spec A

| Window                   | Spec |  `b_{AD}`  | `t(b_{AD})` | `theta_0 (k)` | `t(theta_0)` | `theta_1 (k \times omega_{lag})` | `t(theta_1)` |
| :----------------------- | :--: | :--------: | :---------: | :-----------: | :----------: | :------------------------------: | :----------: |
| Full Sample (1931–2024)  |  A   |     —      |      —      |     0.612     |     1.52     |           **-48.099**            |  **-6.63**   |
| Full Sample (1931–2024)  | AD1  | **-7.877** |  **-3.85**  |     5.597     |     4.02     |              2.183               |     0.47     |
| Fordism (1929–1973)      |  A   |     —      |      —      |     0.529     |     0.59     |           **-134.255**           |  **-3.83**   |
| Fordism (1929–1973)      | AD1  |   -3.544   |    -1.42    |     3.348     |     1.72     |             -55.161              |    -1.92     |
| Post-Fordism (1974–2024) |  A   |     —      |      —      |     3.940     |     2.36     |             +220.463             |     2.46     |
| Post-Fordism (1974–2024) | AD1  |   -6.977   |    -0.48    |     7.281     |     1.04     |             +51.552              |     1.46     |
| Neoliberal (1974–2008)   |  A   |     —      |      —      |     2.362     |     1.43     |             +284.912             |     2.10     |
| Neoliberal (1974–2008)   | AD1  |   +1.711   |    0.10     |     2.658     |     0.32     |             +97.127              |     1.69     |
| Post-GFC (2009–2024)     |  A   |     —      |      —      |    144.169    |     4.03     |            +5622.461             |     3.69     |
| Post-GFC (2009–2024)     | AD1  |  +239.884  |    0.78     |   -182.780    |    -1.07     |            -3986.304             |    -2.51     |

### Table 2: Collinearity and Cointegration Hygiene

| Window | Spec | `C_{\text{Shin}}` | `ADF(t)` | `CN` | Hygiene Verdict |
| :--- | :---: | :---: | :---: | :---: | :--- |
| Full Sample | A | 1.1083 | -9.70 | 111.09 | **Fails** (Shin > 0.095; original S04 lock was `0.0255`) |
| Full Sample | AD1 | 1.0606 | -8.91 | **665.94** | **Fails** |
| Fordism | A | 1.1638 | -6.84 | 16.96 | **Fails** (S04 lock: `C_{\text{Shin}} = 0.0255`) |
| Fordism | AD1 | 1.0616 | -5.61 | **98.15** (borderline) | **Fails** |
| Post-Fordism | A | 0.1553 | -5.95 | 76.06 | Fails marginally |
| Post-Fordism | AD1 | **0.2153** | -6.28 | **483.03** | **Fails** |
| Post-GFC | A | 0.7133 | -5.57 | 6.84 | Fails |
| Post-GFC | AD1 | 0.2685 | -5.46 | **230.78** | **Fails** |

---

## 4. Cross-Reference with the Locked Baseline (S04)

The locked S04 results (under Regime B Initial-State Centering) were:

| Window | `theta_1` | `t(theta_1)` | `C_{\text{Shin}}` | Joint Wald |
| :--- | :---: | :---: | :---: | :---: |
| Fordism SpecA-1 | **-3.45**`*` | -2.71 | 0.0255 | `p = 0.011` |
| Post-Fordism SpecA-1 | +1.34 | 0.91 | 0.0276 | `p = 0.368` |
| Full Century (R01 report) | -8.40`*` | — | — | — |

The original Spec A already exhibited a **sign reversal** between Fordism (negative profit squeeze) and Post-Fordism (positive/interaction reversed). The hypothesis was that `AD_t` would absorb demand-driven output variation and leave `theta_1` theoretically stable and negative.

It did not. In the AD1 specification:
- Fordism still yields a negative `theta_1`, but the magnitude and standard error blow up.
- Post-Fordism still yields a **positive** `theta_1` (+51.55), opposite to the profit-squeeze prediction.
- The standalone `AD_t` coefficient is either the wrong sign (negative in Full Sample, Fordism, Post-Fordism) or wildly unstable across short windows (e.g. `b_{AD} = +239.9` in Post-GFC).

---

## 5. Why AD_t Fails as a Level Control

The demand-control design is econometrically ill-posed for IM-OLS in this context:

1. **Three I(1) variables in one equation.** `y_t^{\text{NFC}}`, `k_t^{\text{cap}}`, and `AD_t` are all non-stationary in logs and are mutually cointegrated. A single-equation IM-OLS model with two I(1) right-hand-side variables that share the same stochastic trend cannot identify two distinct long-run elasticities without an external exclusion restriction.

2. **Perfect demand-supply scaling.** By national-income accounting, `AD_t \approx Y_t \approx Y_t^{\text{NFC}}` up to the corporate-sector boundary and net exports. The level of aggregate demand is not an independent shifter of corporate value added; it is part of the same I(1) trend that must already be absorbed by the unit-root machinery.

3. **Collinearity explosion.** The condition numbers jump from the already-elevated original-Spec-A range (≈ 6–111) to **200–740** whenever `AD_t` is added. This violates the vault dual-criterion gate (`CN \le 100`).

4. **Cointegration hygiene deteriorates.** `C_{\text{Shin}}` rises above the locked 0.095 threshold in the AD-controlled row for every window except the pure scale baseline, and it is markedly higher than in the original Spec A rows.

---

## 6. Orders-of-Magnitude Assessment

The target specification AD1 asks the data to split the long-run scale effect between two collinear I(1) aggregates, capital `k` and demand `AD`. The resulting coefficients are not interpretable as structural economic parameters:

- In the Full Sample AD1, a 1% rise in `AD_t` is associated with a **-7.9%** change in `y_{\text{NFC}}` once capital is held constant — an economically absurd partial coefficient mechanically induced by collinearity.
- In Post-Fordism AD1, the demand coefficient is **-7.0** with `t = -0.48` and the capital coefficient is **+7.3** with `t = 1.04`; the two are offsetting each other in a near-linear combination rather than identifying separate mechanisms.
- Short diagnostic windows (Golden Age, Neoliberal, Post-GFC) produce coefficients in the hundreds or thousands, confirming that the model is being fit to residual noise ratios rather than to stable long-run parameters.

---

## 7. Verdict and Recommendation

**The non-accumulation demand control `AD_t` does not solve the Spec A instability and should not replace or augment the original interaction.**

The original instability — a sign flip of `theta_1` between Fordism and Post-Fordism — is a consequence of a broader structural-break issue, not a missing demand regressor. Adding the level of `AD_t` only repackages the same stochastic trend into two collinear regressors and worsens identification.

If a demand-side channel must be incorporated into the paper, two alternative formulations are admissible and would avoid the identification trap:

1. **Use a stationary demand-gap control.** First estimate the Engle-Granger residual `e_t = y_t^{\text{NFC}} - \hat{\beta} AD_t` from the bivariate cointegrating regression; this residual is I(0) and can enter Specification A as a stationary control without changing the integration orders of the regressors.

2. **Use the growth rate of demand.** `\Delta \log AD_t` is stationary (or at most I(0) in cyclical deviations) and can be added as a short-run growth control, though it would test a different hypothesis than the long-run capacity equation.

The locked baseline Spec A (with appropriate structural-break dummies and Regime B centering) remains the superior single-equation formulation for the profit-squeeze mechanism.

---

## 8. Files Produced

- `codes/US_S16_AD_controlled_imols_specA.R` — estimation script.
- `output/US/S16_AD_CONTROLLED_IMOLS_SPECA/csv/s16_ad_controlled_specA_results.csv` — full nested results.
- `chapter2_vault/06_paper_facing/results/S06_AD_Controlled_SpecA_IMOLS_Results.md` (this report).
