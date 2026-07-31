---
type: prompt
status: active
country: US
stage_scope: pre-estimation-design
last_updated: 2026-07-30
depends_on:
  - chapter2_vault/03_econometrics/S01_StructuralBreak_Protocol.md
  - chapter2_vault/03_econometrics/S02_StructuralBreak_Protocol.md
  - chapter2_vault/03_econometrics/S03_StructuralBreak_Protocol.md
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
layer: implementation
role: execution-prompt
stage: pre-estimation-design
scope: chapter2
priority: core
target_model: opus
---

# Prompt: Break-Aware Re-Run of the US Baseline (Spec A) and Specification B IM-OLS Reports

## Context

You are working on Chapter 2 of a PhD dissertation ("Demand-Led Profitability and Structural
Crisis of Capitalism in Chile and the United States during the Fordist Era"). Read `AGENTS.md`
in the repo root before doing anything else — it is binding.

Two existing progress reports currently estimate IM-OLS cointegrating relations without a
formal, break-aware integration-order pre-testing stage:

1. `reports/US_Baseline_IMOLS_Capital_Aggregation_Report/us_baseline_imols_capital_aggregation_report_v5.pdf`
   (+ `.md` source) — Specification A, single aggregate capital model.
2. `reports/US_SpecificationB_IMOLS_Capital_Disaggregation_Report/us_specB_imols_capital_disaggregation_report_v6.pdf`
   — Specification B, disaggregated capital (mechanization gap $\kappa_t$).

As of 2026-07-30, three structural break protocol notes were locked as **binding** authority
governing any re-estimation of these two reports:

- `chapter2_vault/03_econometrics/S03_StructuralBreak_Protocol.md` — foundational Bai-Perron
  vs. Lee-Strazicich framework. Read this first.
- `chapter2_vault/03_econometrics/S01_StructuralBreak_Protocol.md` — applies S03 to
  Specification A (aggregate capital, $k_t^{cap}$).
- `chapter2_vault/03_econometrics/S02_StructuralBreak_Protocol.md` — applies S03 to
  Specification B (disaggregated capital, $\kappa_t$).

**Your task: produce new versions of both reports that integrate this binding pre-testing
protocol, so that the IM-OLS estimation is justified by formal integration-order and
structural-break evidence rather than assumed.**

---

## Required reading, in order

1. `AGENTS.md` — notation lock, stage gates, report/output governance, citation discipline,
   voice (WLM v4.0).
2. `chapter2_vault/03_econometrics/S03_StructuralBreak_Protocol.md` — binding, foundational.
3. `chapter2_vault/03_econometrics/S01_StructuralBreak_Protocol.md` — binding, Spec A.
4. `chapter2_vault/03_econometrics/S02_StructuralBreak_Protocol.md` — binding, Spec B.
5. `chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md` — active estimator
   lock; IM-OLS/CPR remains the estimator, orthogonalization and FWL remain forbidden.
6. `chapter2_vault/03_econometrics/Interaction_Term_Integration_Order_Gate.md` — no
   interacted/generated specification advances to estimator selection before this gate.
7. `reports/US_Baseline_IMOLS_Capital_Aggregation_Report/us_baseline_imols_capital_aggregation_report_v5.pdf`
   and its `.md` source — current Spec A report, to understand existing structure, tables,
   and prose voice.
8. `reports/US_SpecificationB_IMOLS_Capital_Disaggregation_Report/us_specB_imols_capital_disaggregation_report_v6.pdf`
   — current Spec B report.
9. `reports/US_Capital_Composition_Integrated_Report/us_capital_composition_integrated_report.pdf`
   — **non-binding preliminary evidence only.** This report documents the LOESS-based and
   pairwise integration-order groundwork that motivated the S0* protocol. It is useful context
   for what candidate break dates and integration-order puzzles look like, but it does **not**
   satisfy the S0* pre-testing requirement on its own. Do not cite it as if it were the formal
   Bai-Perron → Lee-Strazicich → IM-OLS sequence — that sequence has to be run fresh under the
   locked protocol.
10. Existing US integration-order code for context (do not treat as break-aware, they are not):
    `codes/US_S31I_integration_order_precheck_B1_E2B.R`,
    `codes/US_S31I_expanded_integration_order_audit.R`,
    `codes/US_S31I_i2_risk_and_rolling_audit_B1_E2B.R`.
11. Chile's equivalent break-aware precedent for pattern reference (same repo, different
    country branch, do not copy verbatim — the US variables and sample windows differ):
    `codes/CL_S20_structural_break_dual_route_audit.R`,
    `codes/CL_S32_break_aware_machinery_v6.R`, `codes/CL_S30_sequential_urca_battery_v6.R`.

---

## What is missing today (the gap this prompt closes)

No US-specific script currently implements the S0* binding sequence:

1. Bai-Perron (1998, 2003) sequential break search on stationary first-differenced vectors,
   within the Fordist (1929–1973) and Post-Fordist (1974–2024) sub-samples separately, per
   S01 §2 Step 1 and S02 Stage 2A.
2. Lee-Strazicich (2003) Minimum-LM unit root verification at the candidate break dates from
   step 1, confirming $k_t^{cap}$ / $k_t^{NRC}$ / $\kappa_t$ are I(1)-with-break rather than
   spurious I(2), per S01 §2 Step 2 and S02 Stage 2B. Use the implementation in
   `C:\ReposGitHub\LeeStrazicichUnitRoot` for this test — do not hand-roll a substitute.
3. IM-OLS / DOLS re-estimation with the additive (step + trend) and multiplicative
   (elasticity-switch) break interaction terms specified in S01 §1 and S02 §3, gated on
   step 2's verdict per the decision matrices in S01 §3 and S03 §2C.

You need to design and write this as new, flat, country/stage-prefixed R scripts under
`codes/`, following the repo's existing naming convention (e.g.
`US_S33_bai_perron_split_sample_prescan.R`,
`US_S34_lee_strazicich_break_robust_unitroot.R`,
`US_S35_break_interacted_imols_specA.R`,
`US_S36_break_interacted_imols_specB.R` — adjust numbering to avoid colliding with the
existing US_S3x files already listed above; check `codes/` before assigning numbers).

**Important constraint on execution:** you do not have a live R environment in this session.
Write the scripts completely and correctly, but do not fabricate their output. The scripts
must be handed off for local execution (the dissertation author runs them in RStudio), and the
two report rewrites must consume the resulting ledgers — not invented numbers. Where you need
a placeholder before real numbers exist, mark it explicitly as
`[PENDING: US_S3x LOCAL EXECUTION]` rather than inventing a plausible-looking statistic. This
is a hard rule, not a style preference — AGENTS.md forbids promoting a coefficient on
sign-match alone, and fabricated statistics are strictly worse than an honest placeholder.

---

## Deliverables

### 1. New R scripts (design + full implementation)

Under `codes/`, implementing the three-step S0* sequence for both Spec A and Spec B, producing
ledgers analogous in spirit to the Chile `CL_S30`/`CL_S32` outputs:
- Bai-Perron candidate break dates per sub-sample, with test statistics and trimming parameters
  exactly as specified in S01 §2 Step 1 (Fordist $\epsilon=0.20$, dates 1933/1947; Post-Fordist
  $\epsilon=0.15$, dates 1982/2000/2008) and S02 Stage 2A (global dates 1933/1947/1968/1982/2008).
- Lee-Strazicich Minimum-LM verdicts at each candidate date, using
  `C:\ReposGitHub\LeeStrazicichUnitRoot`.
- Break-interacted IM-OLS/DOLS estimation (additive and multiplicative terms), with the
  variance-reduction and Shin-LM/residual-ADF diagnostics specified in S01 §2 Step 3 and
  S02 Stage 3.
- A stage integrity ledger per script (pattern-match the `s30_stage_integrity_checks.csv` /
  `s32_break_route_integrity.csv` style already used in `output/CL/BOP_BINDING*/`).

Output location: `output/US/BREAK_AWARE_IMOLS/` (new directory; do not write into the existing
`output/CL/` tree; respect the reports-vs-output governance rule in `AGENTS.md`).

### 2. Two new report versions

**Do not overwrite `v5` or `v6`.** Create the next version number for each:

- `reports/US_Baseline_IMOLS_Capital_Aggregation_Report/us_baseline_imols_capital_aggregation_report_v6.md`
  (+ `.tex` once real numbers are in)
- `reports/US_SpecificationB_IMOLS_Capital_Disaggregation_Report/us_specB_imols_capital_disaggregation_report_v7.md`
  (+ `.tex` once real numbers are in)

Each new report must:
- Preserve the existing report's structure, matrices, and voice (WLM v4.0: evidence and
  verdict in the same paragraph, no hedging, no neutral summaries) as its base.
- Add a new methodology subsection, immediately before the main results matrix, titled
  something like "Break-Aware Integration-Order Pre-Testing (S0* Protocol)" that walks through
  the Bai-Perron → Lee-Strazicich → IM-OLS sequence and states the verdict at each step.
- Add the internal-slope-break comparative table (the "Table X" / "Table 3.2" template
  reproduced in S01 §4 and S02 §5) populated with real results once the scripts are run.
- State explicitly, in the same paragraph as any reported elasticity, whether that estimate
  survived the break-aware gate or is being reported as an exploratory/held-out result — mirror
  the honesty standard used in the Chile S40/S50 chronology (linear vs. threshold, formal vs.
  exploratory).
- Cite `reports/US_Capital_Composition_Integrated_Report/us_capital_composition_integrated_report.pdf`
  only as preliminary motivating evidence for candidate break-date selection, never as
  satisfying the S0* gate itself.
- Follow the repo's LaTeX table formatting locks in `AGENTS.md` once you produce the `.tex`
  version (`\textbf{}` not Markdown bold, `[h!]`/`[H]` floats, `\FloatBarrier` before each
  `\section`, explicit `p{Xcm}` column widths, `\footnotesize` footnotes).

### 3. A short handoff note

One file, `chapter2_vault/80_Prompts/handoffs/2026-07-30_us_breakaware_imols_handoff.md`,
listing: which scripts were written, what each produces, what is still `[PENDING: LOCAL
EXECUTION]`, and the exact `Rscript` commands the dissertation author needs to run locally
(same pattern as the Chile `HANDOFF_S40_TO_S99_FOR_CLAUDE_CODE.md` in the repo root — read that
file for the expected tone and level of detail before writing this one).

---

## Acceptance criteria

- All three S0* protocol notes are followed exactly as written (break dates, trimming
  parameters, test sequence, decision matrices) — no substitution of a different structural
  break methodology.
- The Lee-Strazicich test is implemented via `C:\ReposGitHub\LeeStrazicichUnitRoot`, not a
  custom reimplementation.
- No fabricated coefficients, p-values, or test statistics anywhere in the new report drafts —
  every number is either reproduced from an existing frozen ledger or explicitly marked
  `[PENDING: LOCAL EXECUTION]`.
- `v5` and `v6` of the existing reports remain untouched.
- The new reports are versioned `v6` (Spec A) and `v7` (Spec B) and saved under `reports/`,
  never under `output/`.
- All new quantitative artifacts (ledgers, figures) are saved under `output/US/BREAK_AWARE_IMOLS/`.
- The handoff note gives the dissertation author a complete, copy-pasteable local execution
  path (RStudio, package installs if new packages are needed, expected runtime).
- `reports/US_Capital_Composition_Integrated_Report/` is treated as non-binding preliminary
  evidence throughout, consistent with the caveat now recorded in
  `chapter2_vault/03_econometrics/README.md`.

---

## What "done" looks like for this turn

Given the no-R-execution constraint, a complete turn produces: the fully written R scripts,
the two report drafts in Markdown with real prior-stage content preserved and new sections
added (numeric gaps explicitly marked pending), and the handoff note. It does not produce
compiled PDFs with real new numbers — that step happens after local execution, exactly as it
did for the Chile `CL_S40` → `CL_S50`/`CL_S99` handoff earlier in this project.
