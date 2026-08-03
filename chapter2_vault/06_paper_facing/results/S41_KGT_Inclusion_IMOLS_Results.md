---
type: econometrics-result
status: active
country: US
stage_scope: estimation-results
last_updated: '2026-08-01'
depends_on:
  - "[[S09B_Interpretation_Note_CM_Control]]"
  - "[[S22_Restricted_Slope_Diagnostics]]"
  - "[[S40_KGT_Inclusion_Code_Map]]"
  - "[[00S_Chapter2_Symbology_and_Notation_Lock]]"
  - "[[_03_Econometrics_MOC]]"
blocks: []
layer: interpretation
role: diagnostic-robustness
stage: estimation-results
subtype: capital-boundary-robustness
tags:
  - chapter2/results
  - chapter2/imols
  - chapter2/specification-a
  - chapter2/kgt-inclusion
---

# S41 — Government Transportation Capital as Productive Capacity: Baseline vs Extended IM-OLS

## 1. Hypothesis and verdict

**Hypothesis tested:** the Fordist over-accumulation finding (negative interaction slope θ₁ in the CMlevel branch) is driven by omitting government transportation capital (roads, highways — social overhead capital) from the productive capital aggregate K_cap = K_ME + K_NRC.

**Verdict: the hypothesis is NOT supported.** Including a GPIM gross government-transportation stock moves the Fordist θ₁ from **−4.281 to −3.794** (≈ 11% toward zero) with the t-statistic essentially unchanged (−5.03 → −4.75). The sign, magnitude class, and significance of the Fordist profit-squeeze/over-accumulation interaction survive the capital-boundary extension. The BEA-net robustness variant agrees (θ₁ = −3.814). The over-accumulation reading of the Fordist era is **robust to the capital measurement boundary**, not an artifact of it.

Post-Fordism moves in the opposite direction: extending capital *raises* θ₁ (0.707 → 0.989, no-dummy cells), strengthening the positive demand-composition elasticity there. The regime contrast identified in [[S22_Restricted_Slope_Diagnostics]] (slope rotation at 1973) is therefore *sharpened*, not attenuated, by including government transportation capital.

---

## 2. Construction of K_G_transport (D13/D14)

The panel's existing `GOV_TRANS_stock` is BEA current-cost **net** stock (FAAt701 lines 12+14) — never a GPIM construction — and the panel column `k_GOV_TRANS` is a broken constant from a silent fallback in `US_S31J_stage_pending_us_conditioners.R:32` (flagged for repair; not used here). D13/D14 built the GPIM gross stock properly:

| Element | Choice | Source |
| :--- | :--- | :--- |
| Investment flows | FAAt705 gross investment, Highways & streets + Transportation structures, 1901–2024 | BEA menu (staged, validated) |
| Deflator | Implicit price p_GT = FAAt701 / FAAt702-rebased (2017=100), per line; 1901–1924 backcast by log-linear extrapolation of the 1925–1950 mean growth | D14 |
| Survival | Untruncated Weibull, **L = 60, α = 1.3** (Fraumeni life, Nomura 2005 shape), promoted from the D01 metadata row; ages 0:500 (fat tail requires longer support than D06's 0:200) | D01 / Appendix-Retirement-Distribution |
| Initialization | **Benchmark-seeded** (primary): flat pre-1901 real flow calibrated so the 1929 current-cost gross stock equals BEA net × the late-sample (1995–2024) stabilized gross/net ratio. Cold start is not an authorized preferred baseline (V02 §12) | D14 |
| Valuation | K_GT_current = K_GT_real × p_GT/100, per line then summed — same current-cost basis as the panel's K_ME + K_NRC | D14 |

**Why benchmark seeding was mandatory:** the cold-start (1901) stock is **−42.2% below** the benchmarked stock in 1929, −17.5% in 1947, −3.6% in 1973 (convergence < 1% only from 2003). A cold-start k_cap_GT would have injected spurious capital growth exactly inside the Fordist window — the heart of the hypothesis. Warm-up risk at 1929 is HIGH (0.47 = 28/60 years) per the D13 ledger.

**Resulting share path:** K_GT / K_cap_GT = 0.176 (1929) → peak **0.300 (1943)** → 0.269 (2024). Gross/net ratio 1.14–1.26 throughout.

All D13 checks (21/21) and D14 checks (13/13) PASS. Artifacts under `output/US/S41_KGT_INCLUSION/` (audit/, data/, csv/, figs/), all stamped `DIAGNOSTIC_ONLY;NOT_D06_BASELINE;S41_BRANCH`.

---

## 3. Specification

$$y_t = \alpha + \theta_0 k_t + \theta_1 (k_t \cdot \omega_{t-1}^c) + \beta_{cm}(c-m)_{t-1}^c + \boldsymbol{\gamma}'\mathbf{D}_t + \varepsilon_t$$

- Estimator: IM-OLS (`cointReg::cointRegIM`) per the E10V lock; wrapper identical to S19. The Bartlett kernel / Newey–West bandwidth arguments are the repo's inference-layer convention only (t-statistics, Shin LM, VW statistics) — IM-OLS coefficients are kernel-invariant and the kernel is not part of the lock.
- Demand control: locked I(0) `(c−m)_{t−1}` (CMlevel, [[S09B_Interpretation_Note_CM_Control]]), in the deterministic matrix.
- **Standalone wage share dropped** per session design (multicollinearity); ω enters only via the k·ω interaction. This differs from S19's CMlevel (which carries standalone ω), so levels of θ₁ are not directly comparable to S09B's −4.553 — the within-S41 A-vs-B contrast is the object of interest.
- Per-window initial-observation anchoring (locked S09B convention).
- Capital definitions: **A** = k_cap (baseline); **B** = k_cap_GT (+GPIM gross K_GT); **C** = k_cap_GTnet (+BEA net, robustness).
- Dummy sets: **ND** = intercept only; **WD** = steps D1933, D1947, D1974, D2008 + WWII block 1942–1945, degenerate columns dropped on the effective sample.
- **A0 wiring check:** the script replicates S19's CMlevel spec exactly and matches the frozen `s19_final_demand_controls_specA_results.csv` to max |diff| = 2.8e−13 before any extended cell is interpreted.

---

## 4. Results (landscape: parameters as rows, specifications as columns)

### 4.1 Fordism 1929–1973 (effective sample 1949–1973, T = 25)

The (c−m) control begins 1947 (FRED), so the effective Fordist sample is 1949–1973; on that sample all step/block dummies are degenerate, hence **ND ≡ WD** (single column shown per capital definition).

| Parameter        | A: Baseline | B: +GPIM gross |  C: +BEA net |
| :--------------- | ----------: | -------------: | -----------: |
| θ₀ (k)           |       0.637 |          0.655 |        0.662 |
|                  |      (2.66) |         (3.19) |       (3.24) |
| **θ₁ (k·ω_lag)** |  **−4.281** |     **−3.794** |   **−3.814** |
|                  |     (−5.03) |        (−4.75) |      (−4.80) |
| β (c−m)ₜ₋₁       |      −0.510 |         −0.383 |       −0.363 |
|                  |     (−0.90) |        (−0.75) |      (−0.71) |
| T                |          25 |             25 |           25 |
| R² (level)       |      0.9792 |         0.9802 |       0.9808 |
| σ̂ᵤ              |      0.0558 |         0.0544 |       0.0537 |
| CN               |     129.6 ⚑ |        117.2 ⚑ |      118.8 ⚑ |
| Resid. ADF       |  coint_1pct |     coint_1pct |   coint_1pct |
| Shin LM          |    coint_ok |    reject_5pct | reject_10pct |

### 4.2 Post-Fordism 1974–2024 (T = 50)

| Parameter        |       A-ND |       A-WD |       B-ND |       B-WD |       C-ND |       C-WD |
| :--------------- | ---------: | ---------: | ---------: | ---------: | ---------: | ---------: |
| θ₀ (k)           |      0.428 |      0.427 |      0.450 |      0.449 |      0.450 |      0.449 |
|                  |     (8.14) |     (8.66) |     (7.60) |     (8.32) |     (7.63) |     (8.31) |
| **θ₁ (k·ω_lag)** |  **0.707** |     −0.070 |  **0.989** |     −0.064 |  **0.957** |     −0.066 |
|                  |     (2.90) |    (−0.17) |     (3.55) |    (−0.15) |     (3.47) |    (−0.15) |
| β (c−m)ₜ₋₁       |     −0.473 |     −0.460 |     −0.437 |     −0.419 |     −0.439 |     −0.422 |
|                  |    (−5.24) |    (−5.36) |    (−4.37) |    (−4.50) |    (−4.41) |    (−4.54) |
| T                |         50 |         50 |         50 |         50 |         50 |         50 |
| R² (level)       |     0.9874 |     0.9888 |     0.9858 |     0.9880 |     0.9858 |     0.9879 |
| σ̂ᵤ              |     0.0530 |     0.0501 |     0.0564 |     0.0519 |     0.0563 |     0.0520 |
| CN               |     78.1 ⚑ |    101.9 ⚑ |     89.9 ⚑ |    118.8 ⚑ |     88.9 ⚑ |    117.2 ⚑ |
| Resid. ADF       | coint_5pct | coint_1pct | coint_5pct | coint_1pct | coint_5pct | coint_1pct |
| Shin LM          |   coint_ok |   coint_ok |   coint_ok |   coint_ok |   coint_ok |   coint_ok |

### 4.3 Full sample 1929–2024 (effective T = 76)

| Parameter | A-ND | A-WD | B-ND | B-WD | C-ND | C-WD |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| θ₀ (k) | 0.364 | 0.794 | 0.371 | 0.823 | 0.371 | 0.822 |
|   t | (6.25) | (7.05) | (6.60) | (7.69) | (6.61) | (7.68) |
| **θ₁ (k·ω_lag)** | **0.430** | 0.926 | **0.473** | 0.492 | **0.460** | 0.479 |
|   t | (2.04) | (1.74) | (2.46) | (1.16) | (2.38) | (1.14) |
| β (c−m)ₜ₋₁ | −0.570 | 0.009 | −0.547 | 0.086 | −0.547 | 0.083 |
|   t | (−3.51) | (0.05) | (−3.49) | (0.47) | (−3.50) | (0.45) |
| T | 76 | 76 | 76 | 76 | 76 | 76 |
| R² (level) | 0.9798 | 0.9861 | 0.9829 | 0.9896 | 0.9830 | 0.9897 |
| σ̂ᵤ | 0.1186 | 0.0983 | 0.1090 | 0.0852 | 0.1089 | 0.0849 |
| CN | 110.4 ⚑ | 432.8 ⚑ | 115.6 ⚑ | 450.7 ⚑ | 115.0 ⚑ | 447.0 ⚑ |
| Resid. ADF | coint_1pct | coint_1pct | coint_1pct | coint_1pct | coint_1pct | coint_1pct |
| Shin LM | reject_5pct | coint_ok | reject_1pct | coint_ok | reject_1pct | coint_ok |

⚑ = condition number above the CN ≤ 30 gate; interaction-class signs must be read with the disclosed collinearity in mind (consistent with S22's CN = 663 in this branch).

---

## 5. Reading

1. **The Fordist over-accumulation signal is capital-boundary-robust.** Adding ~18–30% more capital (the GT share of the extended aggregate over the Fordist window) attenuates θ₁ by only ≈ 11% and leaves t ≈ −4.8. The user's conjecture that omitted government transportation capital drives the result is answered: it contributes modestly to the magnitude, not to the existence, of the negative interaction.
2. **The B-vs-C agreement (−3.794 vs −3.814)** shows the finding is insensitive to the gross-GPIM vs BEA-net measurement of the government stock — the boundary matters more than the survival methodology, and neither overturns the sign.
3. **The 1973 rotation sharpens.** Post-Fordist θ₁ rises with extended capital while Fordist θ₁ stays deeply negative; the S22 slope-rotation finding gains a robustness leg.
4. **Post-Fordism WD kills θ₁** (−0.07, t ≈ −0.2) in all three capital definitions: with D2008 and D1974 absorbing level shifts, the positive interaction is not separately identified there. This mirrors the known fragility disclosed in the S19 branch and is a dummy-saturation effect, not a capital-definition effect (it appears identically in A, B, C).

---

## 6. Limitations and governance

- **Valuation mix:** the extended aggregate adds a gross government stock to net private stocks (both current-cost). A fully gross aggregate would require replacing K_ME/K_NRC with the D06 refrozen gross stocks — that changes the locked baseline itself and was out of scope.
- **Effective Fordist sample is 1949–1973** (T = 25) because the locked (c−m) control begins 1947. Inherited from the frozen S19/S09B branch (same T there). The 1929–1948 years — including the share peak of 1943 — are outside the estimated Fordist sample.
- **CN > 30 in every cell** (78–451); disclosed, not suppressed, per N11 gating convention.
- **Initialization:** benchmark-seeded primary with cold-start and synthetic-growth sensitivities disclosed in `D14_initialization_sensitivity_disclosure.csv`; cold-start divergence −42% (1929) → −3.6% (1973).
- **Authorization note:** per `D06_exclusion_ledger.csv`, government transportation is excluded from baseline K_capacity (`baseline_capacity_component` prohibited). This S41 branch is **diagnostic only**; it does not amend the exclusion, and no frozen artifact (D06/D07/D10, `gpim_baseline_components_long.csv`, S09B) was modified. If the chapter later wants K_G_transport in the headline aggregate, the exclusion ledger must be amended explicitly.
- **Repair flag:** `k_GOV_TRANS` in the baseline panel is a constant 3.43 (fallback bug at `US_S31J_stage_pending_us_conditioners.R:32`, `k_NR` vs `k_NRC` name mismatch). Any prior use of that column tested a constant.

## 7. Traceability

Every headline number above maps to `output/US/S41_KGT_INCLUSION/csv/s41_estimation_ledger.csv` (cell IDs A/B/C-Full/Ford/Post-ND/WD); the wiring check to `s41_a0_wiring_check.csv`; construction to `data/D14_*.csv`. Scripts: `codes/US_D13_gov_transport_gpim_readiness_audit.R`, `codes/US_D14_gov_transport_gpim_gross_stock_build.R`, `codes/US_S41_kgt_inclusion_baseline_vs_extended_imols.R`. Figures: `figs/s41_theta1_comparison_baseline_vs_extended.{png,pdf}`, `figs/s41_gt_share_path.{png,pdf}`.

---

**See also:** [[S42_Full_Fordist_Window_CM_Extension_Results]] extends the (c−m) control to 1929 (NIPA T10106) and re-runs this grid on the full Fordist window (T=42 instead of T=25) — with an important caveat: the extended control tests as I(1)-indicated, so those results are exploratory. [[S43_Auxiliary_Dummy_Diagnostics]] tests seven additional historical break dummies; none overturns the Fordist θ₁.

*S41 diagnostic branch closed 2026-08-01. Authorized baseline results remain S09B/S21.*
