# D10-R Decision Report

D10-R reran the committed D10 source-of-truth script in a detached temporary worktree using Rscript 4.6.1. It did not estimate anything.

## Opening Repository State
- git status --short --branch: ## main...origin/main [ahead 1] |  M codes/US_D10R_reconciliation_and_reproducibility_check.ps1
- Branch: `main`
- HEAD: `8de311443e3cbc0075521504a85ddd5aac6d1911`
- origin/main: `0c5f3be463da68d209e7795844e00f88e2d50b4b`
- Divergence HEAD...origin/main: `1	0`
- Note: HEAD includes the prior D10-R environment-reconciliation artifact commit; origin/main remains the D10 commit under review.

## Rscript Availability
- PATH lookup via where.exe Rscript: exit 1.
- Absolute Rscript path used: `C:\Program Files\R\R-4.6.1\bin\Rscript.exe`.
- Version: Rscript (R) version 4.6.1 (2026-06-24)

## Temporary Worktree
- Path: `C:\ReposGitHub\Capacity-Utilization-US_Chile_D10R_tmp`
- Created: YES
- Removed: True

## D10 Script Rerun Result
- Script: `codes/US_D10_us_econometric_and_accounting_source_of_truth_dataset.R`
- Exit code: 0
- Rerun completed: YES

## Manifest Comparison Summary
- Files compared: 22
- Hash matches: 14
- Hash differences: 8

## CSV Shape Comparison Summary
- Key CSVs compared: 9
- Shape mismatches: 0

## D10 Validation Review Summary
- Rerun D10 validation checks: 52/52 PASS
- Required validation-review failures: 0

## Reconciliation Status
- q_omega parking status: no q_omega-family columns created on rerun.
- D09-S sensitivity stock exclusion: remains report-only and excluded from baseline.
- ME/NRC/capacity baseline reconfirmation: D10 validation rerun passed; K_capacity remains ME + NRC.
- Corporate-clean reconciliation status: CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK;NOT_MODEL_READY.
- Financial/imputed-interest reconciliation status: CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK;NOT_MODEL_READY.
- Exploitation-rate ingredient status: ALTERNATIVE_DISTRIBUTIVE_CONSTRUCTION_CONTRACT;NOT_MODEL_READY.
- Tax/subsidy/transfer reconciliation status: AUTHORIZED_ACCOUNTING_INGREDIENT;AUTHORIZED_SURPLUS_BRIDGE;AUTHORIZED_TRANSFER_RECONCILIATION;NOT_BASELINE_REGRESSOR.
- Main worktree mutation status: no D10 output diffs in main.

## Final Decision
REQUIRE_D10_OUTPUT_RECONCILIATION
