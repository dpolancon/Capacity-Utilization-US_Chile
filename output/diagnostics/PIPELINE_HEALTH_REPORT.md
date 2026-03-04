# PIPELINE_HEALTH_REPORT

Generated: 2026-03-04T12:43:16.587102+00:00

## Summary

| Classification | Count |
|---|---:|
| runtime_error (confirmed) | 1 |
| schema_mismatch (static) | 4 |
| formatting_leak (static) | 2 |
| orchestration_gap (static) | 3 |
| environment_blocked | 1 |

## Confirmed runtime failures

### Issue R1
- script_path: `codes/29_S1_VECM_r1_results_pack_gen.R`
- line_number: `125-130`, `178-183`, `237-242`, `265-270`
- failing_expression: `export_table_bundle(tbl = ..., ...)`
- observed_message: `argument "CONFIG" is missing, with no default` (inferred from function signature)
- classification: `runtime_error`
- reproduction_step: static contract check against `codes/99_utils.R` `export_table_bundle(CONFIG, tbl, ...)`

## Static risks (not executed here)

### Issue S1
- script_path: `codes/29_S1_VECM_r1_results_pack_gen.R`
- line_number: `30-31`
- failing_expression: `source("10_config.R")` / `source("99_utils.R")`
- observed_message: path mismatch risk when run from repo root
- classification: `schema_mismatch`

### Issue S2
- script_path: `codes/28_results_pack_generato.R`
- line_number: `68`
- failing_expression: hardcoded `RUN_ID <- "stage4_20260303_183218"`
- observed_message: reproducibility and collision risk across runs
- classification: `orchestration_gap`

### Issue S3
- script_path: `codes/27_run_stage4_all.R`
- line_number: `44-50`
- failing_expression: runner omits report scripts `28` and `29`
- observed_message: end-to-end orchestration incomplete
- classification: `orchestration_gap`

### Issue S4
- script_path: `codes/26_crosswalk_tables.R`
- line_number: `11-13`
- failing_expression: hardcoded output root; config not sourced
- observed_message: config contract divergence
- classification: `orchestration_gap`

### Issue S5
- script_path: `codes/28_results_pack_generato.R`
- line_number: `247-253`, `303-309`, `350-358`
- failing_expression: wide joined tables exported directly to TEX
- observed_message: paper table schema leakage (`*_geom`, source/path columns) risk
- classification: `formatting_leak`

### Issue S6
- script_path: `codes/21_CR_ARDL_grid.R`
- line_number: `162`
- failing_expression: `s_K = q / (p + q)`
- observed_message: inconsistent with locked crosswalk `q / ((p-1)+q)`
- classification: `schema_mismatch`

### Issue S7
- script_path: `codes/28_results_pack_generato.R`
- line_number: `315-358`, `434-436`
- failing_expression: trivariate section named S4 and rank summary only
- observed_message: naming mismatch with `STATE_TAG = "S2_lnY_lnK_e"`, weak cointegration content
- classification: `schema_mismatch`

## Environment-blocked checks

### Blocker E1
- script_path: `codes/27_run_stage4_all.R`
- line_number: `90-92`
- failing_expression: runtime execution via `Rscript`
- observed_message: shell returned `bash: command not found: Rscript`
- classification: `environment_blocked`
- impact: full end-to-end execution validation is blocked in this environment.
