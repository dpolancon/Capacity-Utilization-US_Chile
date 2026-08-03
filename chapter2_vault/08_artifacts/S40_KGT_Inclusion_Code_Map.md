---
type: code_map
status: as_built
session: 2026-08-01
country: US
stage_scope: D13-D14-S41
depends_on:
  - "[[S09B_Interpretation_Note_CM_Control]]"
  - "[[S22_Restricted_Slope_Diagnostics]]"
  - "[[S33_SPAN_CORRECTION_AND_RECONCILIATION_HANDOFF]]"
  - "[[ch2_sec3_1_baseline_homogeneous_prelatex]]"
blocks:
  - "[[S41_KGT_Inclusion_IMOLS_Results]]"
last_updated: "2026-08-01"
---

# Code Map (as built): Government Transportation Capital as Productive Capacity — D13 / D14 / S41

> **Revision note.** The original draft of this map assumed `GOV_TRANS_stock` in the
> baseline panel was GPIM-ready and framed the session as "audit + merge + estimate"
> under a stage label S40. Exploration falsified both assumptions: (i) `GOV_TRANS_stock`
> is BEA current-cost **net** stock (FAAt701) passed through — the registered GPIM lane
> (`DOWNSTREAM__GOV_TRANS_GPIM`) was never built; (ii) `S40` collides with existing
> `COMMON_S40_*` scripts. The session was rebuilt as **D13 → D14 → S41** with a full
> GPIM construction. This file records what was actually implemented.

## Research hypothesis and outcome

**Hypothesis:** the Fordist over-accumulation finding (negative θ₁ in the CMlevel
branch) is driven by omitting government transportation capital from
K_cap = K_ME + K_NRC.

**Outcome (see [[S41_KGT_Inclusion_IMOLS_Results]]):** not supported. Fordist θ₁ moves
−4.281 → −3.794 (≈ 11% toward zero), t ≈ −4.8 unchanged. The over-accumulation signal
is capital-boundary-robust; the 1973 slope rotation ([[S22_Restricted_Slope_Diagnostics]])
sharpens rather than attenuates.

## Session context

| Prior session | Key finding | Constraint honored |
|---|---|---|
| S22 (Open Code, 2026-07-31) | 1973 break is a slope rotation; equal-slope restriction rejected ~1% | Split windows; no common-slope models |
| S33 (Claude Code, 2026-07-31) | Span defect fixed; price channel unidentified with wage break | No price terms in this branch |
| S09B (locked) | Per-sample anchored CMlevel is the authorized specification | (c−m)_{t−1} control and anchoring unchanged; S09B untouched |

## Critical repo facts discovered (verified with file:line)

1. `GOV_TRANS_stock` = FAAt701 net current-cost (lines 12+14), built at
   `US_S20_build_capital_distribution_frontier.R:415-423`. Not GPIM.
2. `k_GOV_TRANS` is a **constant 3.43** — silent fallback bug at
   `US_S31J_stage_pending_us_conditioners.R:32-34` (`k_NR` vs `k_NRC` name mismatch).
   Never used in this session; flagged for repair.
3. Panel `K_ME`/`K_NRC` are **also BEA net current-cost** (despite the filename
   `gpim_baseline_components_long.csv`) — extended aggregate therefore valued current-cost.
4. GPIM kernel: no reusable function existed; authoritative inline kernel at
   `US_D06_gpim_refreeze_with_guarded_pkn.R:212-273` (copied, not S29D which carries the
   terminal-exit defect).
5. Gov-transport Weibull parameters pre-locked as metadata: `US_D01...R:87-94` —
   **L = 60, α = 1.3, λ = 64.9648** (Fraumeni life, Nomura 2005 shape). Promoted, not invented.
6. No deflator lane existed for gov investment (S29C is ME/NRC-only) — built implicit
   p_GT = FAAt701 / FAAt702-rebased.
7. `D06_exclusion_ledger.csv` prohibits gov transport as `baseline_capacity_component`
   → entire branch runs `DIAGNOSTIC_ONLY;NOT_D06_BASELINE;S41_BRANCH`, isolated under
   `output/US/S41_KGT_INCLUSION/`.

## Stage sequence (as built)

```
D13 (readiness audit) ──gate──▶ D14 (GPIM build + extended panel) ──gate──▶ S41 (IM-OLS grid) ──▶ report
```

### D13 — `codes/US_D13_gov_transport_gpim_readiness_audit.R`
- FAAt705 coverage: both lines 1901–2024, gap-free. FAAt701/FAAt702: 1925–2024.
- Promoted D01 metadata Weibull row; λ recomputation asserted.
- Warm-up ledger: 1929 ratio 0.47 **HIGH**; 1947 ratio 0.77 MEDIUM → initialization
  sensitivity mandatory (V02 §12).
- **21/21 checks PASS** → `AUTHORIZE_D14_...` token.
- Outputs: `output/US/S41_KGT_INCLUSION/audit/D13_*.csv` (checks, coverage, parameters,
  deflator feasibility, warmup ledger).

### D14 — `codes/US_D14_gov_transport_gpim_gross_stock_build.R`
- Implicit deflator per line (2017=100), 1901–1924 backcast via log-linear extrapolation
  of 1925–1950 mean growth (flat-hold sensitivity carried in the panel).
- GPIM cohort convolution, Weibull L=60/α=1.3, **ages 0:500** (D06's 0:200 fails the
  1e-6 tail tolerance for this fat-tailed distribution).
- **Initialization — primary = benchmark-seeded:** flat pre-1901 real flow (1841–1900)
  solved in closed form so 1929 current-cost gross = BEA net × late-sample (1995–2024)
  gross/net ratio. Cold-start divergence: −42.2% (1929), −17.5% (1947), −3.6% (1973),
  <1% from 2003 — cold start would have injected spurious capital growth inside the
  Fordist window. Sensitivities: cold start; synthetic-growth backcast.
- Extended panel: `k_cap_GT = log(K_cap + K_GT_current)`;
  `k_cap_GTnet = log(K_cap + GOV_TRANS_stock)` (free BEA-net robustness);
  `GT_share` path 0.176 (1929) → 0.300 peak (1943) → 0.269 (2024).
- **13/13 checks PASS** → `AUTHORIZE_S41_...` token.
- Outputs: `output/US/S41_KGT_INCLUSION/data/` — `s41_extended_capital_panel.csv`,
  deflator/stock/aggregate panels, gross-vs-net context ledger, benchmark-seed
  calibration ledger, initialization disclosure, validation checks.

### S41 — `codes/US_S41_kgt_inclusion_baseline_vs_extended_imols.R`
- Estimator wrapper copied verbatim from `US_S19_final_demand_controls_imols_specA.R`
  (cointRegIM, residual ADF, Shin LM, VW Type 2, CN). E10V locks IM-OLS itself; the
  "ba"/"nw" kernel/bandwidth arguments are the inference-layer convention only
  (coefficients are kernel-invariant — see the 2026-08-01 E10V clarification).
- **A0 wiring check:** replicates S19 CMlevel exactly (incl. standalone ω) against the
  frozen S19 CSV — max |diff| 2.8e-13, asserted < 1e-6, halts on failure.
- Session spec drops standalone ω (enters only via k·ω_lag):
  `y ~ k + k·ω_lag + (c−m)_{t−1} + D`.
- Grid: capital {A = k_cap, B = k_cap_GT, C = k_cap_GTnet} × windows
  {Full 1929–2024, Fordism 1929–1973, Post 1974–2024} × dummies {ND, WD = steps
  D1933/D1947/D1974/D2008 + WWII block 1942–45} = 18 cells.
- Degenerate dummy columns dropped on the **effective** sample (post cm-availability
  filter) — in Fordism (effective 1949–1973, T=25, inherited from the locked branch)
  all dummies collapse, so ND ≡ WD there by construction.
- Outputs: `csv/` — long table, **wide landscape table (parameters = rows, cells =
  columns)**, estimation ledger, A0 wiring check; `figs/` — θ₁ comparison,
  GT_share path (png+pdf).

### Report — `chapter2_vault/06_paper_facing/results/S41_KGT_Inclusion_IMOLS_Results.md`
Landscape markdown tables per window; headline A-vs-B contrast; authorization note re
the D06 exclusion; limitations (valuation mix, effective Fordist sample, CN > 30
everywhere, initialization); full traceability to `s41_estimation_ledger.csv`.

## Locks respected

No modification of: S09B (locked), D06/D07/D10 frozen outputs, exclusion ledgers,
`gpim_baseline_components_long.csv`. No common-slope models (S22 rejection). No price
channel terms (S33). Estimator = IM-OLS per E10V.

## Companion session: S42 (full Fordist window, 2026-08-01)

[[S42_Full_Fordist_Window_CM_Extension_Results]] extends the (c−m) control to
1929 via NIPA T10106 (`codes/US_S42A_nipa_cm_control_extension_fetch.R`,
`codes/US_S42B_kgt_full_fordist_window_imols.R`), unlocking the true 1929–1973
Fordist window (T=42 vs S41's T=25). Headline: Fordist θ₁ persists in the WD
cell (−3.86) but the ND cell loses significance (t=−1.67); full-sample θ₁
flips sign. Both effects are qualified by an **I(1)-indicated stationarity
verdict** on the extended control across all windows — flagged as exploratory,
not confirmatory. A continuity decomposition separates the control-source
effect (−3.4 to −3.7) from the sample-extension effect (+2.0 to +2.6).

## Companion session: S43 (auxiliary dummy diagnostics, 2026-08-01)

[[S43_Auxiliary_Dummy_Diagnostics]] sweeps seven additional historical
step/block dummies (Roosevelt recession, Korean War, Eisenhower recession,
Nixon shock, Volcker shock in both step and block form, dot-com, COVID) plus
a residual mean-shift scan (`codes/US_S43_auxiliary_dummy_diagnostics.R`).
No candidate overturns the Fordist θ₁; the Volcker step (S1979, |t| ≥ 3.1 in
all home-window cells) is the only candidate with a serious claim to the WD
set; the dot-com hypothesis is rejected in its home window. No promotion
enacted — WD unchanged everywhere.

## Follow-ups spawned by this session

1. Repair the `k_GOV_TRANS` fallback bug in `US_S31J_stage_pending_us_conditioners.R`
   (constant-column defect; any prior regression use tested a constant).
2. If K_G_transport is ever promoted into headline K_capacity: amend
   `D06_exclusion_ledger.csv` explicitly and rebuild a fully-gross private aggregate
   (D06 refrozen stocks) for methodological consistency.
3. Pre-1947 (c−m) control extension would unlock the true 1929–1973 Fordist sample
   (currently T=25 effective, inherited from the locked branch).

---

*As-built map recorded 2026-08-01. Original draft superseded in place (same file, per
artifact-update convention).*
