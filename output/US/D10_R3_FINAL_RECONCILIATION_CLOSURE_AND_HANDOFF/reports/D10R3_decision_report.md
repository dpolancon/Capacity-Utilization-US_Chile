# D10-R3 Decision Report

D10-R3 closes the D10 reproducibility trail by rerunning D10 in a detached temporary worktree, preserving rerun file bodies, and comparing the eight prior hash-difference files.

## Opening Repo State
- `git status --short --branch`: ## main...origin/main |  M chapter2_vault/.obsidian/appearance.json |  M chapter2_vault/.obsidian/core-plugins.json | ?? codes/US_D10R3_final_reconciliation_closure_and_handoff.ps1 | ?? output/US/D10_R3_FINAL_RECONCILIATION_CLOSURE_AND_HANDOFF/
- `git rev-list --left-right --count HEAD...origin/main`: 0	0
- Earlier R failure is preserved as provenance and superseded by absolute-path Rscript success.

## Rscript
- Path: `C:\Program Files\R\R-4.6.1\bin\Rscript.exe`
- Version: Rscript (R) version 4.6.1 (2026-06-24)

## Temporary Worktree
- Path: `C:\ReposGitHub\Capacity-Utilization-US_Chile_D10R3_tmp`
- Removed: True

## D10 Rerun
- Exit code: 0
- D10 validation: 52/52 PASS

## Preserved Rerun Files
- `codes/US_D10_us_econometric_and_accounting_source_of_truth_dataset.R`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_growth_weight_guard_ledger.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_tax_subsidy_transfer_ledger.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_us_source_of_truth_panel_long.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_us_source_of_truth_panel_wide.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_validation_checks.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_variable_dictionary.csv`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/reports/D10_decision_report.md`
- All rerun D10 CSVs copied to `output/US/D10_R3_FINAL_RECONCILIATION_CLOSURE_AND_HANDOFF/rerun_files/all_csv/`.

## Hash-Difference Classification
- `codes/US_D10_us_econometric_and_accounting_source_of_truth_dataset.R`: `BYTE_ONLY_LINE_ENDING`; `NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_growth_weight_guard_ledger.csv`: `FLOAT_FORMAT_ONLY`; `NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_tax_subsidy_transfer_ledger.csv`: `REVIEW_REQUIRED`; `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_us_source_of_truth_panel_long.csv`: `REVIEW_REQUIRED`; `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_us_source_of_truth_panel_wide.csv`: `REVIEW_REQUIRED`; `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_validation_checks.csv`: `FLOAT_FORMAT_ONLY`; `NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_variable_dictionary.csv`: `REVIEW_REQUIRED`; `REVIEW_REQUIRED`
- `output/US/D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/reports/D10_decision_report.md`: `BYTE_ONLY_LINE_ENDING`; `NON_SUBSTANTIVE_REPRODUCIBILITY_DIFFERENCE`

## Core CSV Audit
- PASS: 6/9

## Boundary And Accounting Status
- q_omega: parked; no q_omega-family columns created.
- D09-S sensitivity stocks: report-only, not baseline.
- Baseline: ME L14 alpha1.7 + NRC L30 alpha1.6; K_capacity = ME + NRC reconfirmed.
- Corporate-clean: CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK;NOT_MODEL_READY.
- Financial/imputed-interest: CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK;NOT_MODEL_READY.
- Exploitation-rate ingredients: ALTERNATIVE_DISTRIBUTIVE_CONSTRUCTION_CONTRACT;NOT_MODEL_READY.
- Tax/subsidy/transfer: AUTHORIZED_ACCOUNTING_INGREDIENT;AUTHORIZED_SURPLUS_BRIDGE;AUTHORIZED_TRANSFER_RECONCILIATION;NOT_BASELINE_REGRESSOR.

## Main Worktree
- D10 source-output mutation: none
- Unrelated Obsidian UI noise: present and not staged.

## Final Decision
REQUIRE_D10_OUTPUT_RECONCILIATION
