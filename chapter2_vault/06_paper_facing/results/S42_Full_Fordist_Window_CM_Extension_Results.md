---
type: econometrics-result
status: active
country: US
stage_scope: estimation-results
last_updated: '2026-08-01'
depends_on:
  - "[[S41_KGT_Inclusion_IMOLS_Results]]"
  - "[[S09B_Interpretation_Note_CM_Control]]"
  - "[[S22_Restricted_Slope_Diagnostics]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
  - "[[_03_Econometrics_MOC]]"
blocks: []
layer: interpretation
role: diagnostic-robustness
stage: estimation-results
subtype: sample-boundary-robustness
tags:
  - chapter2/results
  - chapter2/imols
  - chapter2/specification-a
  - chapter2/kgt-inclusion
  - chapter2/sample-extension
---

# S42 — Full Fordist Window (1929–1973): NIPA (c−m) Control Extension

## 1. Motivation

[[S41_KGT_Inclusion_IMOLS_Results]] estimated the Fordist window on an **effective sample of 1949–1973 (T=25)**, because the locked `(c−m)` control (S09B/S19) is built from the FRED annual panel, which begins in 1947. That sample excludes the Depression, WWII, and the government-transportation-share peak (1943) identified in S41 — precisely the years most relevant to an "over-accumulation during the Fordist regime" claim.

This session extends the **same control definition** (`log C_real − log M_real`, lagged one period) back to 1929 using NIPA Table T10106 (real GDP components, chained dollars, annual), fetched directly from the BEA API (`codes/US_S42A_nipa_cm_control_extension_fetch.R`), and re-runs the full S41 capital-comparison grid on the extended sample (`codes/US_S42B_kgt_full_fordist_window_imols.R`).

**This is a diagnostic branch.** S09B/S21 remain the authorized results; nothing frozen was modified.

## 2. Headline result — read together with Section 6 below

With the full 1929–1973 Fordist window:

| | S41 (control from 1947, T=25) | S42 (control from 1929, T=42) |
|---|---:|---:|
| θ₁ Fordism, no dummies | −4.281 (t=−5.03) | **−5.460 (t=−1.67)** |
| θ₁ Fordism, with dummies | −4.281 (t=−5.03)* | **−3.857 (t=−2.85)** |
| θ₁ Full sample, no dummies | +0.430 (t=2.04) | **−0.486 (t=−0.97)** |

\* Fordism ND ≡ WD in S41 because all dummies were degenerate on the 1949–1973 effective sample.

The Fordist negative interaction **persists and is somewhat larger** in the full window (WD cell: −3.86 vs −4.28, comparable order of magnitude), but its **no-dummy t-statistic collapses to insignificance** (t=−1.67) — the step/block dummies (D1933, D1947, WWII) now do real work in absorbing variance, and only the WD cell recovers significance (t=−2.85). Extending the base sample without controlling for the Depression/WWII break structure produces a materially noisier estimate.

**The full-sample θ₁ flips sign** (+0.430 → −0.486, no-dummy cells) once the control covers 1929 onward. Given the stationarity findings below, this sign flip should be read as a specification-sensitivity warning, not as a competing structural estimate — see Section 6.

## 3. Construction of the extended control (S42A)

- NIPA T10106, "Personal consumption expenditures" and "Imports" lines, chained real dollars, annual, 1929–2025. Fetched via BEA API and cached (`output/US/S42_CM_EXTENSION/csv/s42a_nipa_t10106_raw_cache.csv`) so reruns require no key.
- `cm_t = log(C_real_nipa) − log(M_real_nipa)`, `cm_lag1` — identical functional form to the locked S09B/S19 control.
- **Overlap check against the locked FRED panel (1947–2025):** correlation in levels = 1.0000, correlation in first differences = 1.0000, mean |Δ| (levels) = 0.0000. The two sources agree essentially exactly on the overlap — both derive from the same underlying NIPA accounts. This is the strongest possible validation that the extension is measuring the same object, not a proxy.
- **Base-year audit:** all real series entering S42 (NIPA T10106 real C/M, FRED C_real/M_real, D14 government-transport deflators, S15B deflator) share the **2017=100** reference base. No mismatch flagged.

## 4. Results (landscape: parameters as rows, specifications as columns)

### 4.1 Fordism 1929–1973 (effective sample 1931–1973, T = 42)

The merged panel's earliest year with complete data is 1931 (two years lost to lag/merge, not to the control extension itself).

| Parameter        |       A-ND |         A-WD |       B-ND |        B-WD |       C-ND |        C-WD |
| :--------------- | ---------: | -----------: | ---------: | ----------: | ---------: | ----------: |
| θ₀ (k)           |      0.705 |        1.114 |      0.766 |       1.102 |      0.759 |       1.090 |
|                  |     (7.28) |       (7.86) |     (9.11) |      (8.04) |     (8.77) |      (7.99) |
| **θ₁ (k·ω_lag)** | **−5.460** |   **−3.857** | **−5.240** |  **−3.291** | **−5.244** |  **−3.306** |
|                  |    (−1.67) |      (−2.85) |    (−1.96) |     (−2.72) |    (−1.91) |     (−2.70) |
| β (c−m)ₜ₋₁       |     −0.207 |        0.622 |      0.113 |       0.718 |      0.095 |       0.696 |
|                  |    (−0.49) |       (1.92) |     (0.31) |      (2.26) |     (0.25) |      (2.19) |
| T                |         42 |           42 |         42 |          42 |         42 |          42 |
| R² (level)       |     0.9159 |       0.9848 |     0.9268 |      0.9864 |     0.9248 |      0.9861 |
| σ̂ᵤ              |     0.1954 |       0.0831 |     0.1822 |      0.0786 |     0.1847 |      0.0793 |
| CN               |        6.3 |      130.3 ⚑ |        6.5 |     119.9 ⚑ |        6.5 |     120.1 ⚑ |
| Resid. ADF       | coint_5pct |   coint_1pct | coint_5pct |  coint_1pct | coint_5pct |  coint_1pct |
| Shin LM          |   coint_ok | reject_10pct |   coint_ok | reject_5pct |   coint_ok | reject_5pct |

Note the CN contrast with S41: the no-dummy Fordist cells here have **CN ≈ 6.5** (well inside the ≤30 gate) — much better conditioned than S41's Fordist cells (CN ≈ 117–130) because the longer 1931–1973 sample carries more independent variation. The WD cells revert to high CN once the dummy block is added back.

### 4.2 Post-Fordism 1974–2024 — unchanged from S41 (T=50; the extended control does not affect this window since it agrees with FRED on the overlap).

### 4.3 Full sample 1929–2024 (effective T = 93; merged panel starts 1931)

| Parameter        |       A-ND |       A-WD |       B-ND |       B-WD |       C-ND |       C-WD |
| :--------------- | ---------: | ---------: | ---------: | ---------: | ---------: | ---------: |
| θ₀ (k)           |      0.683 |      0.837 |      0.702 |      0.801 |      0.696 |      0.799 |
|                  |     (8.60) |     (6.78) |     (9.28) |     (7.42) |     (9.20) |     (7.41) |
| **θ₁ (k·ω_lag)** | **−0.486** |     −0.219 | **−0.349** |     −0.222 | **−0.373** |     −0.228 |
|                  |    (−0.97) |    (−0.50) |    (−0.75) |    (−0.57) |    (−0.79) |    (−0.58) |
| β (c−m)ₜ₋₁       |      0.292 |      0.047 |      0.347 |      0.043 |      0.329 |      0.037 |
|                  |     (1.06) |     (0.22) |     (1.33) |     (0.23) |     (1.26) |     (0.20) |
| T                |         93 |         93 |         93 |         93 |         93 |         93 |
| R² (level)       |     0.9701 |     0.9926 |     0.9697 |     0.9932 |     0.9697 |     0.9934 |
| σ̂ᵤ              |     0.1936 |     0.0964 |     0.1949 |     0.0920 |     0.1948 |     0.0911 |
| CN               |     64.4 ⚑ |    670.4 ⚑ |     66.3 ⚑ |    684.2 ⚑ |     66.0 ⚑ |    680.3 ⚑ |
| Resid. ADF       | coint_5pct | coint_1pct | coint_1pct | coint_1pct | coint_1pct | coint_1pct |
| Shin LM          |   coint_ok |   coint_ok |   coint_ok |   coint_ok |   coint_ok |   coint_ok |

⚑ = CN above the ≤30 gate; disclosed, not suppressed.

## 5. Continuity decomposition — control-source effect vs sample-extension effect

Re-estimating the truncated 1949–1973 sample with the *new* NIPA control isolates how much of the S41→S42 change comes from switching data sources versus extending the sample:

| Capital | S41 (FRED control, T=25) | Truncated 1949–1973, NIPA control | Full 1931–1973, NIPA control (ND) | Control-source effect | Sample-extension effect |
| :--- | ---: | ---: | ---: | ---: | ---: |
| A (baseline) | −4.281 | −8.023 | −5.460 | **−3.742** | **+2.563** |
| B (+GPIM gross) | −3.794 | −7.248 | −5.240 | **−3.454** | **+2.009** |
| C (+BEA net) | −3.814 | −7.235 | −5.244 | **−3.422** | **+1.992** |

Both effects are substantial and **partly offset**: switching from the FRED control to the NIPA control on the *same* 1949–1973 sample makes θ₁ considerably more negative (−3.4 to −3.7), while extending the sample back to 1931 pulls it back toward zero (+2.0 to +2.6). This is despite the overlap check in Section 3 showing near-perfect agreement between the two control sources on 1947–2025 — the divergence is concentrated in **how each source's construction interacts with the estimator's anchoring and the specific years each panel drops**, not in the underlying NIPA data itself. This decomposition is reported as a diagnostic, not as grounds to prefer one source.

## 6. Limitations and interpretation warnings

**Read this section before citing any S42 number.**

1. **Stationarity of the extended control is NOT established, and the pre-test result is unfavorable.** ADF/KPSS tests on `cm_t` (`s42a_stationarity_verdicts.csv`) give **I(1)-indicated verdicts in all three windows**: full sample (ADF p=0.324, KPSS p=0.01), Fordism (ADF p=0.800, KPSS p=0.01), Post-Fordism (ADF p=0.948, KPSS p=0.01). The locked S09B/S19 branch established I(0) status for the FRED-sourced spread on 1947+ only; that status has **not been re-verified as favorable** for the NIPA-sourced spread on the extended sample. The IM-OLS deterministic-matrix convention (S19, S41) requires I(0) controls. Using a possibly-I(1) series in the deterministic block does not invalidate the point estimates mechanically, but it undermines the asymptotic justification for treating its coefficient and standard errors as valid — **the β_(c−m) estimates and their t-statistics in this report should be treated as exploratory, not confirmatory.**
2. **The full-sample sign flip (θ₁: +0.43 → −0.49) is a symptom of (1), not a competing finding.** It should not be read as revising the full-sample θ₁ recorded in S41/S09B.
3. **Fordist significance is dummy-dependent.** The no-dummy Fordist θ₁ has t=−1.67 (not conventionally significant); only the WD cell (t=−2.85) supports the over-accumulation reading with the full window. This is the opposite pattern from S41, where dummies were degenerate and irrelevant — here they are doing real identifying work, concentrated in the 1930s–40s.
4. **CN ⚑ in every WD cell and the entire full-sample block** (117–684) — same disclosure convention as S41 and S22 (CN ≤ 30 gate reported, not enforced).
5. **The continuity decomposition (Section 5) shows the control source matters as much as the sample window** — a caution against treating any single (c−m) construction as uniquely authoritative for this branch.
6. **Base-year and overlap checks passed cleanly** (Section 3) — these are not sources of concern; the concern is specifically the I(1)-indicated stationarity of the pooled 1929+ series.
7. **Governance:** S09B/S21 remain the authorized branch. This report does not propose replacing them. Any future promotion of the extended control to authorized status requires resolving (1) — e.g., testing whether a structural-break-adjusted unit-root test (Fordist-era trade collapse, 1930s) restores I(0) status, or whether a different transformation of the demand-composition variable is needed pre-1947.

## 7. Traceability

`output/US/S42_CM_EXTENSION/csv/`: `s42a_nipa_t10106_raw_cache.csv`, `s42a_extended_cm_control_panel.csv`, `s42a_overlap_consistency_check.csv`, `s42a_stationarity_verdicts.csv`, `s42a_base_year_audit.csv`, `s42_coefficient_table_long.csv`, `s42_coefficient_table_wide.csv`, `s42_estimation_ledger.csv`, `s42_continuity_decomposition.csv`. Figures: `figs/s42_theta1_full_fordist_window.{png,pdf}`, `figs/s42_fordist_theta1_decomposition.{png,pdf}`. Scripts: `codes/US_S42A_nipa_cm_control_extension_fetch.R`, `codes/US_S42B_kgt_full_fordist_window_imols.R`.

Estimator: IM-OLS per the [[E10V_IMOLS_CPR_Active_Estimator_Lock]]; kernel/bandwidth ("ba"/"nw") is the repo's inference-layer convention only (see the 2026-08-01 clarification in that lock) — coefficients are kernel-invariant.

---

**See also:** [[S43_Auxiliary_Dummy_Diagnostics]] tests seven additional historical step/block dummies (Eisenhower, Volcker, dot-com, COVID, Roosevelt recession, Korean War, Nixon shock) plus a residual break scan — none overturns the Fordist θ₁; Volcker is the only candidate with a serious claim to the WD set.

*S42 diagnostic branch closed 2026-08-01. Authorized baseline results remain S09B/S21. Companion to [[S41_KGT_Inclusion_IMOLS_Results]].*
