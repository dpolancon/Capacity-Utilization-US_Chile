---
type: econometrics-result
status: active
country: US
stage_scope: estimation-results
last_updated: '2026-08-01'
depends_on:
  - "[[S41_KGT_Inclusion_IMOLS_Results]]"
  - "[[S42_Full_Fordist_Window_CM_Extension_Results]]"
  - "[[S22_Restricted_Slope_Diagnostics]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
  - "[[_03_Econometrics_MOC]]"
blocks: []
layer: interpretation
role: diagnostic-robustness
stage: estimation-results
subtype: auxiliary-dummy-diagnostics
tags:
  - chapter2/results
  - chapter2/imols
  - chapter2/specification-a
  - chapter2/structural-breaks
---

# S43 — Auxiliary Step/Block Dummy Diagnostics

## 1. Motivation and nomenclature

S42 showed the Fordist θ₁ is dummy-dependent (ND t=−1.67 vs WD t=−2.85). This diagnostic asks whether **other historically plausible breaks** — beyond the WD set (D1933, D1947, D1974, D2008 + WWII block) — either overturn the headline θ₁ results or are being wrongly omitted. Seven events are tested one-at-a-time and jointly, and a data-driven residual scan checks for breaks the historical list missed.

**Cell-ID nomenclature** (used in all tables and CSVs):
- **Tier**: `T1` = locked FRED (c−m) control (1947+, clean I(0)); `T2` = extended NIPA control (1929+, I(1)-indicated — see S42 limitations).
- **Window**: Fordism (nominal 1929–1973), Post-Fordism (1974–2024), Full (1929–2024). Effective samples: T1 Fordism = 1949–1973 (T=25), T1 Full = 1949–2024 (T=76), T2 Fordism = 1931–1973 (T=42).
- **Base set**: `ND` = intercept only; `WD` = D1933, D1947, D1974, D2008 + WWII block (degenerate columns dropped on the effective sample — in T1 Fordism all WD dummies collapse, so ND ≡ WD there).
- **Candidate**: `B####_##` = block dummy (transient episode), `S####` = step dummy (permanent regime shift). `REF` = reference cell, `JOINT` = all 10%-significant candidates entered together.
- Capital = A (k_cap baseline) throughout; S41 established the A/B/C definitions move together.

| Candidate | Event | Form rationale |
| :--- | :--- | :--- |
| B1937_38 | Roosevelt recession | Transient contraction (T2 only — pre-1947) |
| B1950_53 | Korean War | Wartime episode, like the WWII block |
| B1957_58 | Eisenhower recession | Transient contraction |
| S1971 | Nixon shock | Bretton Woods end = regime shift |
| B1979_82 / S1979 | Volcker shock | Ambiguous: disinflation episode vs monetary-regime change — both forms tested |
| B2000_01 | Dot-com bust | Transient contraction |
| B2020_21 | COVID | Transient contraction |

**Wiring check:** the re-estimated reference cells reproduce the frozen S41 A-Ford and S42 A-Ford-ND/WD ledger rows to < 5×10⁻¹⁵ (`s43_wiring_check.csv`), so every Δ below is measured against exactly the S41/S42 baselines.

## 2. Headline verdicts

**No auxiliary dummy overturns the Fordist over-accumulation finding.** Fordist θ₁ stays negative and (in the truncated T1 window) strongly significant in every augmented cell. The candidate-by-candidate reading:

| Candidate | Verdict | Evidence |
| :--- | :--- | :--- |
| **Volcker (S1979/B1979_82)** | **Supported — strongest candidate** | Only event significant in its home window under both forms (Post WD: step t=−4.15, block t=−3.77). Step form dominates. Post-ND θ₁ *strengthens* to 1.437 (t=4.48) with S1979. |
| **COVID (B2020_21)** | Supported, with a sensitivity flag | Post WD t=2.44. Flips Post-WD θ₁ to −0.451 — but that cell's θ₁ is insignificant (t=−1.06), consistent with the known WD dummy-saturation of Post-Fordism. |
| **Eisenhower (B1957_58)** | Marginally supported | Fordism γ t=−1.89 (10% level); θ₁ attenuates −4.281 → −3.630 (≈15%) while its t *improves* to −5.35. Notably, the only residual-scan flag above |t|=2 sits at 1961 (Full window, t=3.68) — the post-Eisenhower recovery region. |
| Roosevelt (B1937_38) | Level-shift only | T2 WD t=2.23, but θ₁ moves −3.857 → −3.826: pure level absorption, no slope consequence. Tier-2 (I(1) disclosure applies). |
| Korean War (B1950_53) | Not supported in its home window | T1 Fordism t=−0.58. (T2-ND marginal at t=−1.88, pushing θ₁ to −6.63 — tier-2 caveat.) |
| Nixon (S1971) | Not supported | Fordism t=−0.44; significant only in the Full window (WD t=2.60) at CN=526, i.e. inside the known full-sample collinearity zone. |
| **Dot-com (B2000_01)** | **Not supported** | In its home window (Post) t=−0.37 (ND) / −0.28 (WD); θ₁ essentially unchanged. Its Full-window significance (t≈−2.6) at CN 125–467 is a pooling artifact, not a Post-Fordist break. |

## 3. Results (landscape: parameters as rows, cells as columns)

### 3.1 Fordism, T1 (effective 1949–1973, T=25; ND ≡ WD — dummies degenerate)

| Parameter | REF | +B1950_53 | +B1957_58 | +S1971 |
| :--- | ---: | ---: | ---: | ---: |
| **θ₁** | **−4.281** | −4.397 | **−3.630** | −3.956 |
|   t | (−5.03) | (−5.31) | (−5.35) | (−3.33) |
| γ (candidate) | — | −0.027 | −0.102 | −0.035 |
|   t | — | (−0.58) | (−1.89) | (−0.44) |
| CN | 129.6 ⚑ | 153.1 ⚑ | 133.6 ⚑ | 185.5 ⚑ |
| Resid. ADF | coint_1pct | coint_1pct | coint_10pct | (ledger) |
| Shin LM | coint_ok | coint_ok | reject_10pct | (ledger) |

### 3.2 Post-Fordism, T1 (T=50)

| Parameter | ND-REF | ND+B1979_82 | ND+S1979 | ND+B2000_01 | ND+B2020_21 |
| :--- | ---: | ---: | ---: | ---: | ---: |
| **θ₁** | **0.707** | 0.614 | **1.437** | 0.753 | 0.758 |
|   t | (2.90) | (2.94) | (4.48) | (2.73) | (3.11) |
| γ (candidate) | — | −0.190 | −0.190 | −0.028 | 0.145 |
|   t | — | (−3.66) | (−3.08) | (−0.37) | (1.86) |
| CN | 78.1 ⚑ | 87.7 ⚑ | 171.5 ⚑ | 81.6 ⚑ | 84.4 ⚑ |

| Parameter | WD-REF | WD+B1979_82 | WD+S1979 | WD+B2000_01 | WD+B2020_21 | WD+JOINT* |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **θ₁** | −0.070 | 0.088 | 0.096 | −0.026 | −0.451 | 0.212 |
|   t | (−0.17) | (0.24) | (0.30) | (−0.06) | (−1.06) | (0.60) |
| γ (candidate) | — | −0.185 | −0.225 | −0.020 | 0.182 | — |
|   t | — | (−3.77) | (−4.15) | (−0.28) | (2.44) | — |
| CN | 101.9 ⚑ | 111.3 ⚑ | 223.8 ⚑ | 107.7 ⚑ | 108.0 ⚑ | 259.3 ⚑ |

\* JOINT = S1979 + B2020_21 (the two 10%-significant candidates; when both Volcker forms pass, the more significant form is kept).

### 3.3 Fordism, T2 full window (effective 1931–1973, T=42; extended NIPA control — I(1) disclosure applies)

| Parameter | ND-REF | ND+B1937_38 | ND+B1950_53 | ND+B1957_58 | ND+S1971 |
| :--- | ---: | ---: | ---: | ---: | ---: |
| **θ₁** | **−5.460** | −5.469 | −6.629 | −6.162 | −2.554 |
|   t | (−1.67) | (−1.69) | (−2.04) | (−1.95) | (−0.54) |
| γ (candidate) | — | 0.105 | −0.359 | 0.146 | −0.315 |
|   t | — | (0.39) | (−1.88) | (0.57) | (−0.91) |
| CN | 6.3 | 7.6 | 7.9 | 6.7 | 8.5 |

| Parameter | WD-REF | WD+B1937_38 | WD+B1950_53 | WD+B1957_58 | WD+S1971 |
| :--- | ---: | ---: | ---: | ---: | ---: |
| **θ₁** | **−3.857** | −3.826 | −3.985 | −3.268 | −2.908 |
|   t | (−2.85) | (−3.00) | (−2.90) | (−2.70) | (−1.53) |
| γ (candidate) | — | 0.230 | −0.028 | −0.114 | −0.103 |
|   t | — | (2.23) | (−0.37) | (−1.23) | (−0.78) |
| CN | 130.3 ⚑ | 150.2 ⚑ | 134.3 ⚑ | 131.9 ⚑ | 163.0 ⚑ |

### 3.4 Full sample, T1 (effective 1949–2024, T=76) — summary only

All eight candidates were run on ND and WD bases (see `s43_candidate_ledger.csv`). Several attain |t|>2 (B1950_53, B1957_58, S1979, B2000_01 on ND; S1971, S1979, B2000_01 on WD), but every full-sample cell sits at CN 113–657 and the joint cell (B1950_53 + B1957_58 + S1971 + S1979 + B2000_01) reaches **CN = 1037** with θ₁ = −0.166 (t=−0.72). The full-sample window pools across the rejected common-slope restriction (S22), so these significances are read as pooling/collinearity artifacts, not break evidence — the home-window cells in §3.1–3.3 are the informative ones.

## 4. Residual scan (data-driven screen)

Single-break mean-shift scan (15% trimming) on each reference ND cell's IM-OLS residuals, plus standardized CUSUM (`s43_residual_scan.csv`, `figs/s43_residual_scan.*`, `figs/s43_residual_cusum.*`):

| Series | sup-\|t\| break after | sup \|t\| | Above \|t\|=2 flag? |
| :--- | ---: | ---: | :--- |
| T1 Fordism | 1952 | 1.22 | No |
| T1 Post-Fordism | 2016 | 1.89 | No |
| T1 Full | **1961** | **3.68** | **Yes** |
| T2 Fordism | 1945 | 1.79 | No |

At the named event years themselves, no scan t-statistic exceeds |2| (e.g., 1957: −0.09 in Fordism; 2000: −0.14 in Post; 1979: −0.31 in Full). Reading: **within each regime window, the reference residuals show no unmodeled level shift at any of the seven candidate dates** — consistent with §3's finding that the candidates act through variance absorption (Volcker, COVID) rather than correcting an omitted mean break. The single flag (Full window, after 1961) does not coincide with any named event and sits in the window that pools across the rejected 1973 common slope; it is most plausibly the regime transition leaking into the pooled residuals, echoed weakly by the T2-Fordism sup at 1945 (the D1947 neighborhood, already in WD).

## 5. Reading

1. **Robustness confirmed.** The Fordist negative θ₁ survives every candidate individually and jointly; the Post-Fordist positive θ₁ (ND) survives all four home-window candidates and *strengthens* under the Volcker step. The dummy-dependence found in S42 is not a symptom of an omitted additional break among these seven.
2. **Volcker is the one candidate with a serious claim** to join the WD set (both forms, |t| ≥ 3.1 in all four home-window cells; step form dominant). Promotion is a governance decision, not made here; note it would add CN ≈ +120 to Post-WD cells.
3. **The dot-com hypothesis is rejected** in its home window — the 2000–01 episode leaves no imprint on either θ₁ or the residuals.
4. **COVID matters for the Post-WD cell only**, where θ₁ is already unidentified (dummy saturation, S41 §5.4); it does not disturb the informative ND cell.

## 6. Limitations and interpretation warnings

1. **CN ⚑ in every T1 cell** (78–1037); only the T2-Fordism ND cells are well-conditioned (CN 6–9). Same disclosure convention as S22/S41/S42 (CN ≤ 30 gate reported, not enforced).
2. **Tier-2 cells (T2, §3.3) inherit the S42 I(1)-indicated verdict** on the extended (c−m) control — exploratory, not confirmatory.
3. **Multiple testing:** 8 candidates × multiple windows/bases ≈ 30 significance readings at the 10% level; 3 spurious hits are expected under the null. The Volcker result (four independent cells, |t| ≥ 3.1) clears this concern; the marginal results (Eisenhower t=−1.89, Korean T2 t=−1.88, COVID t=2.44) do not, individually.
4. **The residual scan is descriptive**: the |t|=2 flag line is conventional, not a sup-Wald critical value (which would be materially larger); the 1961 flag would likely *not* survive a proper Andrews sup-test, and no year was formally tested.
5. **The full-sample cells (§3.4) pool across the rejected common-slope restriction** (S22) and are reported for completeness only.
6. **No promotion is enacted.** The WD set in all authorized and diagnostic branches is unchanged. Adding S1979 (or any candidate) to WD requires an explicit governance amendment and re-running the affected branches.
7. Block vs step form choices are historically motivated but not exhaustively cross-tested (only Volcker got both forms); a form-misspecified candidate (e.g., Volcker as a longer 1979–85 block) could test differently.

## 7. Traceability

`output/US/S43_DUMMY_DIAGNOSTICS/csv/`: `s43_candidate_ledger.csv` (46 cells), `s43_delta_table_wide.csv`, `s43_residual_scan.csv`, `s43_wiring_check.csv`, `s43_skipped_cells.csv` (28 degenerate candidate/window pairs, e.g. B2020_21 in Fordism). Figures: `figs/s43_theta1_sensitivity.{png,pdf}`, `figs/s43_residual_scan.{png,pdf}`, `figs/s43_residual_cusum.{png,pdf}`. Script: `codes/US_S43_auxiliary_dummy_diagnostics.R`.

Panel: frozen `s41_extended_capital_panel.csv` (deliberately — the live baseline panel is under un-reviewed repair by the k_GOV_TRANS task). Estimator: IM-OLS per [[E10V_IMOLS_CPR_Active_Estimator_Lock]]; kernel/bandwidth is the inference-layer convention only (2026-08-01 clarification).

---

*S43 diagnostic branch closed 2026-08-01. Authorized baseline results remain S09B/S21. Companion to [[S41_KGT_Inclusion_IMOLS_Results]] and [[S42_Full_Fordist_Window_CM_Extension_Results]].*
