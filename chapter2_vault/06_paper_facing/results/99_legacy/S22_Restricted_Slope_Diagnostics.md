---
type: econometrics-result
status: active
country: US
stage_scope: estimation-results
last_updated: '2026-07-31'
depends_on:
  - "[[S09B_Interpretation_Note_CM_Control]]"
  - "[[S09_Final_Demand_Controls_IMOLS_Results]]"
  - "[[US_S21_path_dependent_theta_mu_reconstruction]]"
  - "[[00S_Chapter2_Symbology_and_Notation_Lock]]"
  - "[[_03_Econometrics_MOC]]"
blocks: []
layer: interpretation
role: diagnostic-robustness
stage: estimation-results
subtype: restricted-slope-test
tags:
  - chapter2/results
  - chapter2/imols
  - chapter2/specification-a
  - chapter2/restricted-slope
---

# S22 — Restricted-Slope Diagnostic: Same `theta_1` at the 1973 Pinch

## 1. What the restriction means

The CMlevel split-sample results (S09 / S09B) deliver two very different `theta(omega)` slopes:

- Fordism 1929–1973: `hat theta_1 = -4.553` (profit-squeeze / low-absorption elasticity).
- Post-Fordism 1974–2024: `hat theta_1 = 143.296` (steep demand-composition elasticity).

A sceptical reading of the Post-Fordist intercept is that the 1973 break is mainly a **level shift** in capacity utilization rather than a **rotation** of the elasticity function. This note tests that possibility by imposing

$$\left. \frac{\partial \theta_t}{\partial \omega_t} \right|_{t=1973}^{\text{Ford}}
    = \left. \frac{\partial \theta_t}{\partial \omega_t} \right|_{t=1973}^{\text{Post}},$$

i.e. a single slope `theta_1` common to both regimes, while allowing the intercept (the elasticity evaluated at `omega_{1973}`) to shift across the break.

---

## 2. Implementation

The model is estimated on the union of the Fordist (1929–1973) and Post-Fordist (1974–2024) windows, using the same I(0) demand-composition control `(c-m)_{t-1}` as the CMlevel specification. To make the 1973 kink meaningful, both `k_t` and `omega_t` are centered on their 1973 values:

| Regressor | Role |
| :--- | :--- |
| `k_t^c = k_t - k_{1973}` | Common capital slope; `theta_0^Ford(1973)` is its coefficient. |
| `(k_t^c * Post_t)` | Post-Fordist shift in the intercept at 1973. |
| `omega_t^c = omega_t - omega_{1973}` | Common wage-share level effect on output. |
| `(k_t^c * omega_t^c)` | **Common** profit-squeeze / demand-absorption slope `theta_1`. |
| `Post_t`, `D_{1933}`, `D_{1947}`, `D_{2008}` | Step shifts and regime level shift. |
| `(c-m)_{t-1}^c` | I(0) demand-composition control, centered at 1973. |

No `Post_t * k_t^c * omega_t^c` interaction is included; that is the restricted slope.

---

## 3. Results

### 3.1 Restricted-slope IM-OLS estimates

| Parameter | Estimate | `t`-stat | Interpretation at 1973 |
| :--- | ---: | ---: | :--- |
| `theta_0^Ford(1973)`: `k_t^c` | -12.969 | -2.747 | Fordist elasticity at the pinch year. |
| Post intercept shift: `k_t^c * Post_t` | 7.571 | 2.023 | Difference `theta_0^Post - theta_0^Ford`. |
| **Common slope `theta_1`:** `k_t^c * omega_t^c` | **106.997** | **1.704** | Slope imposed identical across regimes. |
| `omega_t^c` | -339.389 | -2.536 | Additive wage-share level effect (not part of `theta_t`). |
| `(c-m)_{t-1}^c` | -8.571 | -0.895 | Demand-composition control. |

Implied elasticities at the pinch:

- `theta_{1973}^Ford = -12.969`.
- `theta_{1973}^Post = -12.969 + 7.571 = -5.399`.

Both intercepts are negative. With the large common positive slope, `theta_t` stays negative throughout the sample.

### 3.2 Model diagnostics

| Statistic | Value | Verdict |
| :--- | ---: | :--- |
| `T` | 76 | — |
| Residual ADF | -4.253 | Cointegration at 10%, weaker than unrestricted. |
| Shin LM (`C_Shin`) | 0.5205 | Rejects stationarity (too large). |
| Condition number | 663.5 | Severe collinearity. |

The restricted model **fails** the Shin-LM stationarity requirement and produces a condition number far above comfortable thresholds.

### 3.3 Split-sample comparison and formal slope-equality check

The unrestricted CMlevel estimates are:

| Regime | `theta_1` | `SE` |
| :--- | ---: | ---: |
| Fordism | -4.553 | 0.587 |
| Post-Fordism | 143.296 | 56.945 |

Difference: `143.296 - (-4.553) = 147.848`.

Approximate `t`-statistic for the equality of slopes:

$$t_{\text{diff}} = \frac{147.848}{\sqrt{0.587^2 + 56.945^2}} = 2.596.$$

This rejects the null of equal slopes at roughly the 1% two-sided level (`p \approx 0.009`).

### 3.4 Reconstructed objects under the restriction

Using the restricted `theta_t` and forcing `mu_{1973} = 1`:

| Object | Value | Comment |
| :--- | ---: | :--- |
| `theta_t` range | `[-16.378, -3.949]` | Entire path is negative; economically nonsensical for a capacity elasticity. |
| `mu_t` range | `[-9.12e15, 1.24e15]` | Physical nonsense; the negative elasticities reverse the sign of potential-output growth. |

---

## 4. Interpretation

The data **reject** a common slope at the 1973 structural break. Imposing it forces `theta_t` into a negative range and produces absurd reconstructed utilization. Three conclusions follow:

1. The 1973 break is not merely a level shift in utilization; it is a **regime change in the transformation elasticity** itself.
2. The Post-Fordist positive `theta_1` is not an artifact of a miss-specified intercept; the unrestricted split-sample slopes are statistically different.
3. The per-sample anchored reconstruction in S09B / S21 — Fordism anchored at 1929, Post-Fordism anchored at 1973 — is the admissible diagnostic.

This result is consistent with the chapter's interpretation: the Fordist profit-squeeze / low-absorption regime is replaced after 1973 by a demand-led / profit-led regime in which the response of latent capacity to the wage share differs structurally.

---

## 5. Figures

### Figure 1: `theta_t` path under common-slope restriction

![[S22_theta_path_CMlevel_restricted_slope.png]]

The path is entirely below zero and extremely flat in absolute terms compared with the unrestricted version in S21.

### Figure 2: Reconstructed `mu_t` under common-slope restriction

![[S22_mu_capacity_utilization_CMlevel_restricted_slope.png]]

The reconstruction is physically inadmissible; the common-slope restriction is therefore diagnostic only and is **not** a candidate for a production utilization series.

---

## 6. Files produced

- `codes/US_S22_restricted_slope_theta_mu_reconstruction.R` — restricted-slope estimation and reconstruction.
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/csv/s22_restricted_slope_theta_mu_reconstruction.csv`.
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/figs/S22_theta_path_CMlevel_restricted_slope.{png,pdf}`.
- `output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/figs/S22_mu_capacity_utilization_CMlevel_restricted_slope.{png,pdf}`.

---

## 7. Register entry: what a "same slope at 1973" restriction entails

| Feature | Unrestricted (S09B / S21) | Restricted (S22) |
| :--- | :--- | :--- |
| Anchor | `omega_0^Ford = 1929`, `omega_0^Post = 1973` | Both regimes centered on `omega_{1973}` |
| Slope | `theta_1^Ford = -4.553`, `theta_1^Post = 143.296` | Single `theta_1 = 106.997` |
| Intercept at 1973 | Ford **0.505**, Post **5.894** | Ford **-12.969**, Post **-5.399** |
| `theta_t` range | `[-5.46, 7.46]` | `[-16.38, -3.95]` |
| `mu_t` range | `[0.000053, 1.36]` | `[-9.12e15, 1.24e15]` |
| Formal slope test | — | `t_{diff} = 2.596`, equal slope rejected |
| Verdict | Diagnostic baseline | Rejected / diagnostic counter-factual |

---

*Status: restricted-slope diagnostic complete. The S09B per-sample anchored reconstruction remains the authorized diagnostic result.*
