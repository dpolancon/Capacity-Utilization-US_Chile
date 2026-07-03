# D10-R2 Decision Report

D10-R2 classifies the eight D10-R hash differences without rerunning D10 and without modifying D10 source-of-truth outputs.

## Opening Repo State
- git status --short --branch: ## main...origin/main [ahead 1] |  M chapter2_vault/.obsidian/appearance.json |  M chapter2_vault/.obsidian/core-plugins.json | ?? codes/US_D10R2_output_hash_difference_reconciliation.ps1
- git rev-list --left-right --count HEAD...origin/main: 1	0
- Branch is ahead of origin/main by the D10-R commit.
- Unrelated local UI/noise files left unstaged: chapter2_vault/.obsidian/appearance.json, chapter2_vault/.obsidian/core-plugins.json, and user-confirmed chapter2_vault/Untitled.md.

## Hash-Difference Files
- `codes/US_D10_us_econometric_and_accounting_source_of_truth_dataset.R`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_growth_weight_guard_ledger.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_tax_subsidy_transfer_ledger.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_us_source_of_truth_panel_long.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_us_source_of_truth_panel_wide.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_validation_checks.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_variable_dictionary.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/reports/D10_decision_report.md`

## Classification
- `codes/US_D10_us_econometric_and_accounting_source_of_truth_dataset.R`: `RERUN_FILE_NOT_AVAILABLE_FOR_DIFF`, `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_growth_weight_guard_ledger.csv`: `RERUN_FILE_NOT_AVAILABLE_FOR_DIFF`, `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_tax_subsidy_transfer_ledger.csv`: `RERUN_FILE_NOT_AVAILABLE_FOR_DIFF`, `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_us_source_of_truth_panel_long.csv`: `RERUN_FILE_NOT_AVAILABLE_FOR_DIFF`, `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_us_source_of_truth_panel_wide.csv`: `RERUN_FILE_NOT_AVAILABLE_FOR_DIFF`, `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_validation_checks.csv`: `RERUN_FILE_NOT_AVAILABLE_FOR_DIFF`, `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_variable_dictionary.csv`: `RERUN_FILE_NOT_AVAILABLE_FOR_DIFF`, `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/reports/D10_decision_report.md`: `RERUN_FILE_NOT_AVAILABLE_FOR_DIFF`, `REVIEW_REQUIRED`

The D10-R temp worktree was removed, so rerun file bodies are not available for D10-R2 line-level, numeric, or normalized-content comparison. D10-R retained hashes, shapes, and validation review, but not the rerun output files themselves.

## Core CSV Value Audit Summary
- REVIEW_REQUIRED: 4
- PASS: 5

Core CSVs with matching hashes pass. Core CSVs with hash differences remain review-required because rerun file bodies are unavailable.

## Boundary And q_omega Status
- PASS: 10
- q_omega remains parked and no q_omega-family columns exist in the committed D10 wide panel.
- Baseline capital boundary remains ME L14 + NRC L30; K_capacity identity remains PASS in D10 validation.

## D10 Source Output Mutation
- D10 output diff in main worktree: none

## Final Decision
REQUIRE_D10R_COMPARISON_ARTIFACT_REGENERATION
