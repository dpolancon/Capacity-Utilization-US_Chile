---
type: session-handoff
status: active
country: US
stage_scope: estimation-results
last_updated: '2026-08-01'
depends_on:
  - "[[S41_KGT_Inclusion_IMOLS_Results]]"
  - "[[S42_Full_Fordist_Window_CM_Extension_Results]]"
  - "[[S43_Auxiliary_Dummy_Diagnostics]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
tags:
  - chapter2/handoff
  - chapter2/imols
---

# SESSION HANDOFF — E10V Clarification + S42 (Full Fordist Window) + S43 (Auxiliary Dummies)

**Date:** 2026-08-01. **Repo:** `Capacity-Utilization-US_Chile` (Chapter 2, US branch). **Prepared for:** any AI assistant or collaborator continuing this work without access to the session transcript. Everything below is self-contained; verify file claims against the repo before relying on them.

---

## 1. Project context (minimum background)

The chapter estimates a capacity-utilization framework in which latent potential output follows a cointegrating polynomial regression estimated by **IM-OLS** (`cointReg::cointRegIM`), per the estimator lock `chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md`:

y_t = α + θ₀·k_t + θ₁·(k_t · ω_{t−1}) + β_cm·(c−m)_{t−1} + γ'D_t + ε_t

- `y_t` = log real NFC value added; `k_t` = log productive capital (K_ME + K_NRC, current-cost); `ω` = wage share; `(c−m)` = log real consumption minus log real imports, an I(0) demand-composition control (locked spec S09B); `D_t` = dummy set.
- **θ₁ < 0 in the Fordist era (1929–1973)** is the "over-accumulation / profit-squeeze" reading; **θ₁ > 0 post-1974**. The 1973 break is a slope *rotation*, not a level shift (equal slopes rejected ≈1%, S22).
- All regressors are **anchored** at the first non-NA observation of the nominal window (per-window initial-observation convention, S09B). This matters: the anchor point of `k` changes the interaction term, so merges must preserve pre-control panel rows (all.x = TRUE) or wiring checks fail.
- Dummy nomenclature: **ND** = intercept only; **WD** = steps D1933, D1947, D1974, D2008 + WWII block 1942–45. Capital definitions: **A** = baseline k_cap, **B** = +GPIM gross gov-transport stock, **C** = +BEA net gov-transport (from the prior S41 session).
- **Authorized results remain S09B/S21.** Everything below is DIAGNOSTIC-branch work; no frozen artifact or lock was modified (one lock was *clarified*, see §2).

Prior session (same day, already documented): S41 tested whether omitting government transportation capital drives the Fordist θ₁ < 0. Verdict: no — θ₁ moves −4.281 → −3.794 (t ≈ −4.8 unchanged). See `chapter2_vault/06_paper_facing/results/S41_KGT_Inclusion_IMOLS_Results.md`.

## 2. Work item 1 — E10V kernel/bandwidth clarification (COMPLETE)

**Problem:** S41 documents attributed "Bartlett kernel / Newey–West bandwidth" to the E10V estimator lock. Wrong: E10V locks IM-OLS itself. IM-OLS **coefficients are kernel-invariant** (partial-sum transformation absorbs long-run endogeneity; no LRCV correction of coefficients). Kernel/bandwidth ("ba"/"nw") enter only the **inference layer**: t-statistics (ω̂_u.v), Shin LM normalization, VW statistics. Kernel-dependent LRCV *coefficient* correction is an FM-OLS property — one reason FM-OLS is blocked.

**Done:** dated subsection "LRV Kernel/Bandwidth: Inference Layer Only (clarification, 2026-08-01)" added to the E10V lock; three misattribution sites corrected (S41 report §3, S41 script header, S40 code map). Doc amendment only — no empirical proof script (user decision).

## 3. Work item 2 — S42: full Fordist window via extended (c−m) control (COMPLETE)

**Problem:** the locked FRED-based (c−m) control begins 1947, so S41's "Fordism" cells ran on an effective 1949–1973 sample (T=25), excluding the Depression, WWII, and the 1943 gov-transport share peak.

**S42A** (`codes/US_S42A_nipa_cm_control_extension_fetch.R`): fetched NIPA T10106 (real C and Imports, chained 2017$, 1929–2025) from the BEA API (key at Windows user scope, `HKCU:\Environment\BEA_API_KEY`; the raw pull is cached so reruns need no key). Built the identical (c−m) spread from 1929.
- Overlap vs FRED control (1947+): correlation 1.0000 in levels and differences, mean |Δ| = 0.0000 — same underlying NIPA data.
- Base-year audit: all real series on 2017=100. Clean.
- **Stationarity pre-tests: I(1)-indicated in ALL windows** (full: ADF p=0.32/KPSS p=0.01; Fordism: 0.80/0.01; Post: 0.95/0.01). Recorded, not gated (standing user instruction: never halt the pipeline on verdicts; carry them to the report's limitations section).

**S42B** (`codes/US_S42B_kgt_full_fordist_window_imols.R`): re-ran the 18-cell S41 grid (A/B/C × Full/Ford/Post × ND/WD) with the extended control. Fordism effective sample = 1931–1973 (T=42); WD dummies non-degenerate there for the first time.

**Key numbers (capital A):**
| Cell | θ₁ | t |
|---|---:|---:|
| S41 Fordism (T=25, FRED ctrl) | −4.281 | −5.03 |
| S42 Fordism ND (T=42) | −5.460 | −1.67 |
| S42 Fordism WD (T=42) | −3.857 | −2.85 |
| S42 Full-sample ND | −0.486 (sign flip vs S41's +0.430) | −0.97 |

**Continuity decomposition** (`s42_continuity_decomposition.csv`): switching FRED→NIPA control on the *same* 1949–1973 sample moves θ₁ by −3.4 to −3.7; extending the sample to 1931 moves it back +2.0 to +2.6. Control source matters as much as window despite the perfect data overlap — it operates through anchoring and dropped years, not the data.

**Interpretation discipline:** because the extended control tests I(1), all S42 β_cm estimates and the full-sample sign flip are **exploratory, not confirmatory**. Report: `chapter2_vault/06_paper_facing/results/S42_Full_Fordist_Window_CM_Extension_Results.md` (limitations in §6 are mandatory reading before citing any S42 number).

## 4. Work item 3 — S43: auxiliary step/block dummy diagnostics (COMPLETE)

**Question:** are other historically plausible breaks omitted, and does any overturn θ₁? Candidates: Roosevelt recession B1937_38, Korean War B1950_53, Eisenhower B1957_58, Nixon S1971, Volcker B1979_82 AND S1979 (both forms), dot-com B2000_01, COVID B2020_21. Blocks = transient episodes; steps = regime shifts. One-at-a-time on ND and WD bases, joint cells (candidates significant at 10%), plus a descriptive residual mean-shift scan + CUSUM (15% trimming) on reference ND residuals. Capital A only; Tier 1 = FRED control (clean I(0)), Tier 2 = extended NIPA control (for pre-1947 candidates; I(1) disclosure). Wiring check reproduced frozen S41/S42 ledger rows to <5e-15. 46 cells.

**Verdicts:**
- **No candidate overturns the Fordist θ₁ < 0** — the finding is break-robust as well as capital-boundary-robust (S41).
- **Volcker: the only serious candidate for WD promotion.** Both forms significant in Post-Fordism (step t=−4.15, block t=−3.77, WD base); step form dominant; survives the multiple-testing caveat (four cells |t|≥3.1). Post-ND θ₁ strengthens to 1.437 (t=4.48) with S1979. **Promotion NOT enacted** — it is a governance decision requiring an explicit WD amendment and re-runs.
- **Dot-com: rejected** in its home window (t≈−0.3); full-sample significance is a pooling artifact (CN 125–467; the full window straddles the rejected common slope).
- Eisenhower marginal (t=−1.89; attenuates Fordist θ₁ ~15% to −3.63 while its t improves to −5.35); COVID significant (t=2.44) but only disturbs the already-unidentified Post-WD cell; Roosevelt = level shift only; Korean/Nixon not supported.
- Residual scan: no flag at any event year; single |t|>2 flag at 1961 in the pooled Full window (t=3.68, descriptive only — no sup-Wald critical values applied).

Report: `chapter2_vault/06_paper_facing/results/S43_Auxiliary_Dummy_Diagnostics.md`. Script: `codes/US_S43_auxiliary_dummy_diagnostics.R`. Outputs: `output/US/S43_DUMMY_DIAGNOSTICS/{csv,figs}/`.

## 5. OPEN ISSUES (things the next session must know)

1. **`output/gpim_baseline_components_long.csv` is mutated and un-reviewed.** A background repair task (fixing the `k_GOV_TRANS` constant-3.43 fallback bug at `US_S31J_stage_pending_us_conditioners.R:32`, a `k_NR`/`k_NRC` name mismatch) wrote directly into the main working tree instead of staying in its worktree (`.claude/worktrees/serene-booth-1ead90`). The diff also shifts/NAs other columns in early rows — review before committing or reverting. **S41/S42/S43 are unaffected** (they read the frozen `s41_extended_capital_panel.csv`), but any re-run of D14 or anything reading the baseline panel will silently pick up the new version.
2. **The extended (c−m) control is I(1)-indicated on 1929+.** Before any promotion of the S42 branch: test structural-break-adjusted unit roots (1930s trade collapse) or an alternative pre-1947 demand-composition transformation.
3. **Volcker S1979 promotion into WD** is pending a governance decision (would add ~+120 CN to Post-WD cells; requires re-running affected branches).
4. **CN > 30 in nearly every T1 cell** (78–1037) — standing disclosure convention (report, don't suppress); only T2-Fordism ND cells are well-conditioned (CN 6–9).

## 6. File inventory (this session)

**Scripts:** `codes/US_S42A_nipa_cm_control_extension_fetch.R`, `codes/US_S42B_kgt_full_fordist_window_imols.R`, `codes/US_S43_auxiliary_dummy_diagnostics.R`.
**Reports:** `chapter2_vault/06_paper_facing/results/S42_Full_Fordist_Window_CM_Extension_Results.md`, `.../S43_Auxiliary_Dummy_Diagnostics.md`.
**Amended docs:** `chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md` (clarification subsection), `S41_KGT_Inclusion_IMOLS_Results.md`, `chapter2_vault/08_artifacts/S40_KGT_Inclusion_Code_Map.md`, `chapter2_vault/03_econometrics/_03_Econometrics_MOC.md` (S42/S43 lines).
**Outputs:** `output/US/S42_CM_EXTENSION/{csv,figs}/` (raw T10106 cache, extended control panel, overlap/stationarity/base-year audits, 18-cell tables, continuity decomposition, 2 figures); `output/US/S43_DUMMY_DIAGNOSTICS/{csv,figs}/` (46-cell ledger, wide delta table, residual scan, wiring check, skipped-cells log, 3 figures).
**Nothing committed to git yet** — the working tree holds all of the above as new/modified files, plus the un-reviewed baseline-panel mutation from the background task (see §5.1).

## 7. Rules any continuation must respect

- Estimator = IM-OLS only (E10V); FM-OLS and DOLS blocked; kernel/bandwidth = inference-layer convention, never part of coefficient identity.
- No common-slope models across 1973 (S22 rejection); no price-channel terms (S33); per-window initial-observation anchoring; degenerate dummy columns dropped on the **effective** sample (after control-availability filtering), and merges must keep pre-control rows (all.x = TRUE) so anchors sit at the nominal window start.
- Never halt a pipeline on diagnostic verdicts — record them and collect them in an end-of-report "Limitations and interpretation warnings" section (explicit standing user instruction).
- S09B/S21 stay authorized; every new branch is stamped DIAGNOSTIC_ONLY; check all real series share the 2017=100 base.

---

*Handoff prepared 2026-08-01 by the Claude Code session that executed S42/S43.*
