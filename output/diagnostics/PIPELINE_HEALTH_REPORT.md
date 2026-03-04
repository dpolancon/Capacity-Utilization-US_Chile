# PIPELINE HEALTH REPORT

Generated: 2026-03-04T12:43:02.809065+00:00

## Scope
Audited pipeline entrypoints and dependencies for Stage-4 critical replication:
- `codes/27_run_stage4_all.R`
- `codes/20_shaikh_ardl_replication.R`
- `codes/21_CR_ARDL_grid.R`
- `codes/22_VECM_S1.R`
- `codes/23_VECM_S2.R`
- `codes/26_crosswalk_tables.R`
- `codes/28_results_pack_generato.R`
- `codes/29_S1_VECM_r1_results_pack_gen.R`
- shared: `codes/10_config.R`, `codes/99_utils.R`, `codes/24_complexity_penalties.R`, `codes/25_envelope_tools.R`

## Environment check
- Runtime blocker: `Rscript` command is unavailable in this environment (`bash: command not found: Rscript`).
- Therefore, runtime execution is **blocked**; diagnosis below includes static/code-path findings plus prior artifact consistency checks.

## Dependency chain (intended)
1. `27_run_stage4_all.R` orchestrates compute scripts: `20 -> 21 -> 22 -> 23 -> 26`
2. Results-pack scripts (`28`, `29`) are separate and currently not run by `27`
3. `10_config.R` + `99_utils.R` provide path conventions/logging/helpers across stages

## Confirmed breakpoints

### Issue 1 — `29` source path mismatch
- **File**: `codes/29_S1_VECM_r1_results_pack_gen.R`
- **Lines**: 30-31
- **Problem**: uses `source("10_config.R")` and `source("99_utils.R")`, unlike project-standard `here::here("codes", ...)`; breaks when run from repo root.

### Issue 2 — `29` export function signature mismatch
- **File**: `codes/29_S1_VECM_r1_results_pack_gen.R`
- **Lines**: 125-130, 178-183, 237-242, 265-270
- **Problem**: calls `export_table_bundle(tbl=..., ...)` without first positional `CONFIG`; `99_utils.R` requires `export_table_bundle(CONFIG, tbl, ...)`.

### Issue 3 — orchestrator not end-to-end for report packaging
- **File**: `codes/27_run_stage4_all.R`
- **Lines**: 43-50
- **Problem**: runs only `20/21/22/23/26`; excludes `28` and `29`, so one-run workflow does not cover package/report outputs.

### Issue 4 — hardcoded run id in results pack
- **File**: `codes/28_results_pack_generato.R`
- **Line**: 68
- **Problem**: `RUN_ID <- "stage4_20260303_183218"`, causing stale metadata and collision risk.

### Issue 5 — crosswalk path not config-driven
- **File**: `codes/26_crosswalk_tables.R`
- **Lines**: 11-13
- **Problem**: hardcoded `output/CriticalReplication` root instead of `CONFIG$OUT_CR_*` conventions.

### Issue 6 — ARDL memory-share inconsistency
- **File**: `codes/21_CR_ARDL_grid.R`
- **Line**: 162
- **Problem**: `s_K = q / (p + q)` differs from locked crosswalk convention `q / ((p-1)+q)` used elsewhere.

## Static risk findings (not runtime-confirmed)
- Report table exports in `28` can leak wide schemas (joined branch/source columns) into TEX without explicit paper allowlists.
- Parallel-run safety incomplete: many outputs still write to fixed directories and shared manifest files.

## Malformed-output checks from existing artifacts
- Existing `ResultsPack` TEX for S3 is excessively wide (warehouse-like schema leakage), inconsistent with minimal paper export discipline.
- Existing naming around trivariate section uses S4 labels while compute stage is `STATE_TAG = "S2_lnY_lnK_e"`.

## Classification summary
- confirmed_runtime_failures: 1 (environment runtime blocker: missing `Rscript`)
- confirmed_static_breakpoints: 6
- static_risks: 2
- malformed_outputs_observed: 2
- environment_blocked_validations: end-to-end rerun of R pipeline

