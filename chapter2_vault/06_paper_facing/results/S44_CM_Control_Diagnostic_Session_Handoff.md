---
type: session-handoff
status: active
country: US
stage_scope: specification-governance
last_updated: '2026-08-01'
depends_on:
  - "[[S42_Full_Fordist_Window_CM_Extension_Results]]"
  - "[[S43_Auxiliary_Dummy_Diagnostics]]"
  - "[[S09B_Interpretation_Note_CM_Control]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
proposes:
  - "[[S44_CM_Deterministic_Control_Branch]]"
tags:
  - chapter2/handoff
  - chapter2/specification-governance
  - chapter2/cm-control
  - chapter2/s44-proposal
---

# SESSION HANDOFF — (c−m) Control Diagnostic + S44 Governance Proposal

**Date:** 2026-08-01. **Repo:** `Capacity-Utilization-US_Chile` (Chapter 2, US branch). **Session type:** exploratory diagnostics + governance proposal. **Prepared for:** any AI assistant or collaborator continuing this work without access to the session transcript. Everything below is self-contained; verify file claims against the repo before relying on them.

---

## 1. What this session did

This session did not run new regressions or modify any locked artifact. It performed four things:

1. **Unpacked the prior session handoff** (S42/S43/E10V) and extracted the decision layer — which cells are authorized vs exploratory, which dummy promotions are pending, and what the open issues require.
2. **Produced five diagnostic plots** of the (c−m) demand-composition control series from NIPA T10106 (1929–2025), using the already-computed `s42a_extended_cm_control_panel.csv`.
3. **Diagnosed the S09B I(0) misclassification** of (c−m) and documented why it was a low-power artifact of the T=25 sub-window ADF test.
4. **Proposed S44**: replacing (c−m)_{t−1} as a stochastic I(1) regressor with a piecewise deterministic linear trend (break 1973) in D_t, as the econometrically and theoretically superior treatment.

No scripts were written. No frozen artifact was modified. All plots are exploratory; none are paper-facing outputs.

---

## 2. Authorized-spec ledger (standing summary)

| Axis | Authorized | Exploratory / pending |
|---|---|---|
| Estimator | IM-OLS (E10V); kernel/bandwidth = inference layer only | FM-OLS, DOLS blocked |
| Capital definition | A (baseline k_cap) | B (+GPIM), C (+BEA net gov-transport) |
| Control source + window | FRED (c−m), 1947+; effective Fordism 1949–1973 (T=25) | NIPA extension 1929+ (S42, I(1)-indicated, exploratory) |
| Dummy set | WD (D1933, D1947, D1974, D2008 + WWII block 1942–45) | ND = fallback check only |
| (c−m) integration order | **I(1) — see §4; S09B I(0) verdict was a low-power artifact** | Piecewise-trend treatment proposed (S44) |
| Fordist θ₁ | < 0 confirmed; robust to capital boundary (S41), break candidates (S43), sample extension (S42 WD) | — |
| Volcker (S1979) | Tested; significant in Post-WD (t=−4.15); promotion **not enacted** | Governance decision pending |

---

## 3. Diagnostic plots produced (this session)

All saved to `outputs/` (session working folder, not committed). If needed for paper use, re-generate from `s42a_extended_cm_control_panel.csv` + `S15C_FRED_DEMAND_CONTROL_COINTEGRATION/csv/fred_ad_components_panel.csv`.

| File | Content |
|---|---|
| `cm_nipa_vs_fred.png` | NIPA (1929→) vs FRED (1947→) overlaid; difference panel confirms corr=1.0000, mean\|Δ\|=2×10⁻⁶ |
| `logC_logM_dual_and_cm.png` | Panel A: log C (left axis) + log M (right axis) dual-axis; Panel B: (c−m) log difference with Fordist/Post slopes annotated (−0.012/yr vs −0.021/yr) |
| `CM_ratio_levels.png` | C/M in levels (×multiple): 1929=17×, 1947=26×, 1973=12×, 2001=5.6×, 2025=4.4× |
| `CM_ratio_index2017.png` | C/M ratio indexed 2017=100: 1929=375, 1973=272, 2001=123, 2025=97 |
| `CM_ratio_growth.png` | Annual % growth rate of C/M with 5-yr rolling mean; confirms Δ(c−m) is visually stationary, (c−m) levels are I(1) |

**Key visual finding:** indexing to 2017=100 shows the entire Fordist window sits between 270–580, the post-Fordist window descends from 270 to 97. The 1973 slope rotation in θ₁ and the structural acceleration in import penetration are the same regime break — the political economy interpretation and the trade-openness data are aligned.

---

## 4. The (c−m) I(0) misclassification — diagnosis

**S09B locked (c−m)_{t−1} as an I(0) stochastic control. This is wrong on the full sample.** The formal S42A verdicts already flagged this (ADF p=0.80, KPSS p=0.01 on the Fordist window of the extended series). This session identified four compounding causes:

1. **Sub-window ADF has near-zero power at T=25.** ADF power against near-unit-root alternatives at T=25 is ~10–20%. The "I(0)" verdict was not wrong given the test — it was the wrong test for the question.
2. **The FRED series starts 1947, cutting off the most I(1)-revealing segment.** The 1929–1947 stretch (Depression import collapse, WWII wartime spike) is where any unit-root test has power. The FRED window discards it.
3. **ADF and KPSS conflict was resolved in favor of convenience.** KPSS rejects I(0) on the extended series; this was overridden by a weak ADF non-rejection.
4. **Economic theory prior contaminated the verdict.** The argument that a demand-composition ratio "should" be I(0) is empirically wrong for the US: the reserve-currency dynamic permits permanent import penetration growth not subject to balance-of-payments correction.

**What (c−m) actually is:** trend-stationary — I(0) around a deterministic downward trend — rather than either pure I(0) or pure I(1). The trend is driven by discrete, dateable policy events (GATT rounds, Bretton Woods collapse 1971, WTO/NAFTA 1994–95, China WTO 2001). This makes it plausibly *deterministic*, not stochastic.

**Why the current S09B spec is not catastrophically misspecified despite this:** IM-OLS partial-sum transformation partially absorbs slow-moving I(1) trends. The main risk is contamination of the cointegrating space between y, k, kω — not spurious cointegration. The authorized results (S09B/S21) stand as reported; the I(1) issue motivates S44 as a robustness/upgrade branch, not a retraction.

---

## 5. S44 governance proposal — (c−m) as deterministic control

**Proposal:** Replace (c−m)_{t−1} in the stochastic regressor set with a **piecewise linear trend (break at 1973)** added to D_t. Specifically:

- Drop `cm_lag1` from the CPR stochastic space.
- Add to D_t: `trend_ford` = t·𝟙(t ≤ 1973) and `trend_post` = t·𝟙(t > 1973), both anchored at the per-window initial observation (same anchoring convention as all other regressors, per S09B).
- Run the standard IM-OLS grid (capital A, ND/WD, Full/Ford/Post) and compare θ₁ to the authorized S09B/S21 ledger row.

**Theoretical motivation (directly from political economy framework):**
- Trade liberalization is a policy-round process with known dates — economically deterministic, not a random walk.
- The 1973 piecewise break aligns with the Fordist/post-Fordist regime change already identified in S22 and locked into the authorized spec.
- Treating a deterministic process as a stochastic I(1) regressor inflates the cointegrating rank requirement and the condition number unnecessarily.

**Expected benefits:**
- Closes the I(1) disclosure problem for the S42 branch without requiring structural-break unit-root testing.
- Reduces CN (removing a stochastic regressor; replacing with deterministic terms costs fewer effective parameters in IM-OLS).
- Strengthens theoretical motivation for the 1973 break in the deterministic component.
- Cleanly separates the *production-side* cointegrating relationship (y, k, kω) from the *demand-composition secular trend* (now absorbed into D_t).

**Governance requirements before enacting:**
- Explicit decision to amend the authorized dummy set (parallel governance to Volcker promotion, separate decision).
- New script `codes/US_S44_cm_deterministic_control_branch.R` following the standard cell-loop structure.
- Re-run all three windows (Full/Ford/Post) × two dummy sets (ND/WD) × capital A; compare θ₁ and t-stats to S09B/S21 reference row.
- If θ₁ stable: report as "robust to demand-composition specification." If θ₁ moves: report the magnitude and interpret.
- S44 outputs → `output/US/S44_CM_DETERMINISTIC/`; report → `chapter2_vault/06_paper_facing/results/S44_CM_Deterministic_Control_Results.md`.

**This proposal does NOT require:** re-running S41/S42/S43 (those read the frozen `s41_extended_capital_panel.csv`); modifying any locked artifact; changing the E10V estimator or the 1973 break date.

---

## 6. Other open issues carried forward (from prior session)

1. **`output/gpim_baseline_components_long.csv` is mutated and un-reviewed.** Background repair task wrote directly into main working tree (`.claude/worktrees/serene-booth-1ead90`). S41/S42/S43 unaffected (read frozen `s41_extended_capital_panel.csv`). D14 and anything reading the baseline panel will pick up the mutated version silently. **Review before any commit or D14 re-run.**
2. **Extended (c−m) control is I(1)-indicated on 1929+.** S44 proposal above is the preferred resolution. Alternative: structural-break-adjusted unit-root tests (Zivot-Andrews or Perron) on the NIPA extension — the 1930s trade collapse and 1971 Bretton Woods are candidate break dates.
3. **Volcker S1979 promotion into WD** is a separate governance decision (step t=−4.15 in Post-WD; would add ~+120 CN to Post-WD cells; requires re-running affected branches). Independent of S44.
4. **CN > 30 in nearly every T1 cell** (78–1037). Standing disclosure convention: report, don't suppress. S44 may partially alleviate this.
5. **Nothing committed to git.** Entire session output (S42/S43 scripts, reports, outputs, E10V amendment, this handoff) sits uncommitted alongside the un-reviewed baseline-panel mutation. Commit S42/S43/E10V work separately from any baseline-panel change.

---

## 7. Decision queue for next session

Ordered by urgency / dependency:

| # | Decision | Gate |
|---|---|---|
| 1 | Review + revert-or-commit mutated `gpim_baseline_components_long.csv` | Blocks any D14 re-run |
| 2 | Commit S42/S43/E10V work to git (separate from baseline mutation) | Clears working tree |
| 3 | Enact S44 governance decision (piecewise deterministic trend for c−m) | Requires explicit authorization |
| 4 | Volcker S1979 promotion decision | Independent of S44; requires explicit authorization |
| 5 | Structural-break unit-root test on NIPA (c−m) extension (if S44 not enacted) | Required before any S42 number is cited as confirmatory |

---

## 8. Rules any continuation must respect

- Estimator = IM-OLS only (E10V); FM-OLS and DOLS blocked.
- No common-slope models across 1973 (S22 rejection); no price-channel terms (S33).
- Per-window initial-observation anchoring; merges must keep pre-control rows (all.x = TRUE).
- Degenerate dummy columns dropped on the **effective** sample (after control-availability filtering).
- Never halt a pipeline on diagnostic verdicts — record and collect in "Limitations" section.
- S09B/S21 remain authorized; every new branch stamped DIAGNOSTIC_ONLY until explicitly promoted.
- All real series must share 2017=100 base; verify on any new data pull.
- S44 is a **proposal** at this stage — do not implement without explicit governance decision in this session log or a successor.

---

*Handoff prepared 2026-08-01 by Cowork/Claude session following S42/S43 unpacking and (c−m) diagnostic analysis.*
