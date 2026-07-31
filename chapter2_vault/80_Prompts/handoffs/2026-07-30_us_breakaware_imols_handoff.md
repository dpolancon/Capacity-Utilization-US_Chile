---
type: handoff
status: complete_pending_review
target_agent: Claude Code / Diego
date_created: 2026-07-30
updated_by: Claude Code
context: US break-aware IM-OLS re-run (S0* protocol) for Specification A and Specification B
country: US
stage_scope: pre-estimation-design
layer: implementation
scope: chapter2
priority: core
depends_on:
  - chapter2_vault/80_Prompts/P05_US_BreakAware_IMOLS_ReRun_Prompt.md
  - chapter2_vault/03_econometrics/S01_StructuralBreak_Protocol.md
  - chapter2_vault/03_econometrics/S02_StructuralBreak_Protocol.md
  - chapter2_vault/03_econometrics/S03_StructuralBreak_Protocol.md
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
  - chapter2_vault/03_econometrics/Interaction_Term_Integration_Order_Gate.md
---

# Handoff: US Break-Aware IM-OLS Re-Run (S0\*)

## Where we are

✅ **S33A (Bai-Perron split-sample prescan)** — Written and executed. 232 test rows, 16 break dates.
✅ **S33B (Lee-Strazicich break-robust unit root)** — Written and executed. 144 LM runs, 14/18 cells pass the gate.
✅ **S33C (break-interacted IM-OLS, Spec A)** — Written and executed. 54 coefficient rows.
✅ **S33D (break-interacted IM-OLS, Spec B)** — Written and executed. 234 coefficient rows.
✅ **Spec A report v6 (`.md`)** — Written with real numbers throughout.
✅ **Spec B report v7 (`.md`)** — Written with real numbers throughout.
⏳ **`.tex` manuscripts for v6/v7** — Not produced. P05 defers these until the numbers are settled; the numbers now exist, so this is the next step if you want compiled PDFs.

**Nothing is `[PENDING: LOCAL EXECUTION]`.** P05 assumed no live R. R 4.5.2 was in fact available with every required package, so all four stages were run and both reports carry actual estimates rather than placeholders. Re-run locally to confirm reproducibility; the scripts are deterministic and take under three minutes end to end.

---

## Scripts written

All under `codes/`. All source `US_S33_break_aware_common.R`, all write under
`output/US/BREAK_AWARE_IMOLS/<STAGE>/csv/`, all end with a stage-integrity ledger and halt if
any check fails — a completed run is self-certifying.

| Script | Produces |
|---|---|
| `US_S33A_bai_perron_split_sample_prescan.R` | `bai_perron_test_ledger.csv`, `bai_perron_break_dates.csv`, `bai_perron_lag_selection.csv`, `bai_perron_protocol_concordance.csv`, `s33a_bai_perron_integrity.csv` |
| `US_S33B_lee_strazicich_break_robust_unitroot.R` | `lee_strazicich_lm_ledger.csv`, `ls_bp_break_concordance.csv`, `integration_order_verdict.csv`, `s33b_lee_strazicich_integrity.csv`, plus `raw/` dumps |
| `US_S33C_break_interacted_imols_specA.R` | `specA_break_interacted_imols_coefficients.csv`, `specA_slope_break_decision_ledger.csv`, `specA_interaction_gate_ledger.csv`, `specA_dols_comparator_ledger.csv`, `specA_table_X_matrix.csv`, `s33c_specA_integrity.csv` |
| `US_S33D_break_interacted_imols_specB.R` | `specB_break_interacted_imols_coefficients.csv`, `specB_slope_break_decision_ledger.csv`, `specB_interaction_gate_ledger.csv`, `specB_dols_comparator_ledger.csv`, `specB_marginal_product_kappa_regimes.csv`, `specB_table_3_2_matrix.csv`, `s33d_specB_integrity.csv` |

`US_S33_break_aware_common.R` was **modified** — section 9 only. It previously auto-discovered a
generic Lee-Strazicich entry point; it is now hard-pinned to `ur.ls`. See "Deviations" below.

---

## Run order

```bash
Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R --probe
```

```bash
Rscript codes/US_S33A_bai_perron_split_sample_prescan.R
```

```bash
Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R
```

```bash
Rscript codes/US_S33C_break_interacted_imols_specA.R
```

```bash
Rscript codes/US_S33D_break_interacted_imols_specB.R
```

S33C and S33D read `integration_order_verdict.csv` and will stop with an actionable message if
S33B has not run. S33B reads S33A's break dates for the concordance ledger and warns (does not
stop) if S33A has not run. The `--probe` call is optional and just prints what the external
engine exposes.

**Environment.** Verified present on this machine under R 4.5.2: `mbreaks` 1.0.1 (pinned by
`CL_S15_evidence_reconciliation.R`), `cointReg`, `strucchange`, `urca`, `sandwich`, `lmtest`,
`foreach`. Nothing needs installing. The optional Lee-Strazicich bootstrap route
(`ur.ls.bootstrap`) is **not** wired, because it requires packages that are absent; if you ever
want it, `install.packages(c("doSNOW","snow"))` first. Expected runtime: S33A ~90s, S33B ~40s,
S33C and S33D a few seconds each.

Paths are overridable: `CH2_REPO_ROOT` for the repo, `LS_REPO` for the Lee-Strazicich engine
(default `C:/ReposGitHub/LeeStrazicichUnitRoot`), `LS_FUN` if upstream ever renames `ur.ls`.

---

## Deviations on record

Four, all documented in the script headers and in both report drafts. Read these before quoting
any number.

**1. Lee-Strazicich cannot test at the Bai-Perron dates.** `ur.ls()` locates breaks endogenously
by grid-minimising the LM statistic, exposes no fixed-break-date argument, and defines its LM
regression helper inside the function body where it cannot be reached. S01 §2 Step 2 and S02
Stage 2B ask for the test "at the candidate break dates". That is not executable with the
mandated engine, and P05 forbids hand-rolling a substitute. The engine runs as designed and
`ls_bp_break_concordance.csv` reports the date agreement separately.

**2. The S03 §2C decision matrix is mis-specified.** It reads a *levels* non-rejection as evidence
of $I(2)$. That inverts the standard logic — an $I(1)$ series has a unit root in levels, so
failing to reject in levels is exactly what it must do. Applied literally, the matrix classified
$k_t^{cap}$, $k_t^{NRC}$ and $\kappa_t$ as $I(2)$ risks in almost every window: a pre-testing stage
diagnosing itself rather than the data. S33B therefore runs the LM test on **both** levels and
first differences and adjudicates on the pair (levels reject → $I(0)$-with-break; levels fail and
differences reject → $I(1)$-with-break; both fail → genuine $I(2)$ risk). The levels result is
still reported exactly as the protocol asks; it just stops being read as an $I(2)$ verdict alone.
**This is the one deviation that should be reflected back into S03 itself.**

**3. Critical values are tabulated at $T = 100$.** Every `ur.ls()` critical value comes from
$T = 100$ simulations, while the Fordist window carries $T = 43$ and Post-Fordist $T = 51$. The
test is over-sized in the sub-samples. Each ledger row carries the actual $T$ and the ratio.

**4. $\delta_3$ is defined but untabulated.** S02 §3 defines a third slope shift on
$(\kappa_t \cdot p_t^\kappa) \cdot D_t$ that the §5 Table 3.2 template omits. S33D estimates it and
adds the row, with the addition recorded in the table's `provenance` column.

Two smaller implementation choices, both recorded in the integrity ledgers: `WD_max` is named in
S03 §2A but is not exposed by `mbreaks` 1.0.1, so it is written as `NA` with a note rather than
approximated; and S33A walks a lag-order ladder because the partial-structural-change routine goes
singular on these short windows once the constant-coefficient block carries lag augmentation.

---

## Break-date architecture (settled 2026-07-30)

Split samples are **historical and fixed**: Fordism to 1973, Post-Fordism from 1974. Bai-Perron
dates are not a rival periodization — they locate within-sample breaks that must be controlled.

- **Slope shift** ($\delta$ terms): $T_B^* = 1947$ (Fordism), $T_B^* = 2008$ (Post-Fordism), per S01 §5 and S02 §6.
- **Additive steps**: Fordism $D_{1933}$ plus a **1942–1945 war block that switches back off** (war output is a level distortion that reverses; a permanent step would mis-attribute the post-war reversion to the capital elasticity). Post-Fordism $D_{1981}$ and $D_{2000}$, both Bai-Perron supported.

A `s33_block()` constructor was added to the common file for the war block. It is not in S01–S03,
which define only permanent steps and trend breaks; the rationale is in the function's comment.

**Centering.** The uncentered design is numerically unusable on this data — standardized condition
numbers run 3054–8832 (Spec A) and 310–3154 (Spec B) under Regime A, against 12–79 and 24–361
under initial-state centering. Every reported estimate uses **Regime B**, per the AGENTS.md
instruction to log the condition number and default to Regime B rather than block. The condition
numbers for all three regimes are recorded per model in `centering_note`.

---

## Results worth knowing before you read the reports

**Route status is not uniform, and it matters.**

| Window | Spec A | Spec B |
|---|---|---|
| Fordism 1929–1973 | **Exploratory** ($\omega_{t-1}$ is $I(0)$-with-break) | **Formal** (all three base variables clear) |
| Post-Fordism 1974–2024 | **Exploratory** ($k_t^{cap}$ is $I(0)$-with-break) | **Exploratory** ($\kappa_t$ carries persistent $I(2)$ risk) |

The label travels with every coefficient row in the ledgers and is stated in the same paragraph as
every elasticity in both reports, per P05.

**Three findings that change the story.**

1. **Break interactions repair the Spec A cointegration diagnostics.** Shin LM falls from
   $0.185^{***}$ to 0.031 (Fordism) and $0.330^{***}$ to 0.035 (Post-Fordism); residual ADF
   strengthens to $-4.76^{**}$ and $-5.98^{***}$. The within-sample break structure was absorbing
   into the residual.
2. **Fordism has an internal slope break in aggregate capital; Post-Fordism does not.** Spec A
   $\hat\delta_1 = -0.98$ ($t = -2.26$) halves $\hat\beta_{Kcap}$ from 1.84 to 0.86 across 1947.
   At 2008 neither $\delta$ is significant.
3. **Formal testing relocates the Spec B breaks away from capital composition.** Bai-Perron finds
   no growth-rate break in $\kappa_t$ in any window and puts them in $p_t^\kappa$ instead (1945,
   1995, 2008). Of the five S02 Stage 2A candidates only 1947 and 2008 are recovered within two
   years; 1933, 1968 and 1982 are not. The LOESS inflections behind the v6 step controls are not
   confirmed as capital-composition breaks.

The largest single coefficient in Table 3.2 — Spec B post-2008 $\hat\delta_1 = 8.54^{***}$ — sits
in the one window where $\kappa_t$ fails the integration gate. It is reported as exploratory and
should not be quoted as a finding.

---

## Governance

- **Frozen inputs.** `output/gpim_baseline_components_long.csv` (Spec A) and
  `output/gpim_specB_components_long.csv` (Spec B), the same panels
  `COMMON_S40_baseline_imols_cpr_estimation.R` and `COMMON_S40_specB_imols_estimation.R` consume.
  Neither is regenerated by any S33 script.
- **v5 and v6 untouched.** `us_baseline_imols_capital_aggregation_report_v5.{md,pdf}` and
  `us_specB_imols_capital_disaggregation_report_v6.pdf` are byte-identical to their pre-session state.
- **Reports vs output.** New reports are `.md` under `reports/`; all ledgers are `.csv` under
  `output/US/BREAK_AWARE_IMOLS/`. No `.tex` or `.pdf` was written into `output/`, and no `.csv`
  into `reports/`.
- **Notation lock (AGENTS.md v7).** $\kappa_t = k_t^{ME} - k_t^{NRC}$ replaces $\tau_t$ — the frozen
  panel still stores the column as `tau_real` and it is renamed to `kappa` on load, so no S33 script
  reproduces the retired notation. $q$ is the mechanization growth rate, never $m$. $\mu_t$ is
  capacity utilization, never $u$. $\delta$ is reserved for depreciation in the vault's notation
  lock; the S0\* protocols nonetheless use $\delta_1$/$\delta_2$/$\delta_3$ for the slope-shift
  parameters, and the scripts follow the protocols. **Flag for adjudication.**
- **E10V.** IM-OLS is the estimator throughout. DOLS rows carry
  `role = "diagnostic_comparator"` and are never promoted. FWL orthogonalization is blocked
  structurally by `s33_assert_no_fwl()`, which halts before any fit if an interaction column is
  numerically orthogonal to its own constituent levels.
- **Non-binding preliminary evidence.** `reports/US_Capital_Composition_Integrated_Report/` is
  cited in both reports only as motivating context for candidate break dates, never as satisfying
  the S0\* gate.

---

## Open items

- [ ] Review the S03 §2C decision-matrix correction (deviation 2) and decide whether to amend
      `S03_StructuralBreak_Protocol.md` itself. Everything downstream depends on it.
- [ ] Decide whether `s33_block()` (the war-block dummy) should be written into S01/S03 as a
      sanctioned constructor alongside $D_t$ and $DT_t$.
- [ ] Resolve the $\delta$ notation collision between AGENTS.md (depreciation) and S01–S03
      (slope-shift parameters).
- [ ] Build the `.tex` manuscripts for v6 and v7 and compile. AGENTS.md LaTeX locks apply:
      `\textbf{}` not Markdown bold, `[h!]`/`[H]` floats, `\FloatBarrier` before each `\section`,
      explicit `p{Xcm}` column widths, `\footnotesize` table footnotes.
- [ ] Decide whether the Post-Fordist Spec B relation should be respecified on investment flows,
      as S03 §2C directs when the $I(2)$ risk persists.
- [ ] Re-run the S01 §5 168-model and S02 §6 505-model grids under slope-adjusted parameters, and
      re-derive $\hat\mu_t$ and $\theta_t$. Out of scope for this pass.

**Status:** All four S0\* stages executed; both report drafts written with real estimates.
**Handoff date:** 2026-07-30
