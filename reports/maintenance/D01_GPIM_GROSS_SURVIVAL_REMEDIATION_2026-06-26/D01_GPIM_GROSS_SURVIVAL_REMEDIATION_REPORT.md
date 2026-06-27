# D01 GPIM Gross-Survival Remediation Maintenance Report

**Date:** 2026-06-26  
**Branch:** `feature/us-gpim-remediation-gross-survival`  
**Base:** `origin/main` at `27e1c8d02fec5844a9debb27870be54ec5d8f452`  
**Status:** Completed locally; validation passed.

## Scope

D01 implements the first GPIM remediation target: removal of the artificial terminal-retirement cliff at mean service life. The pass constructs only the gross real surviving stock for U.S. ME and NRC using the S29C real-investment flows.

This pass does not rerun S31/S32, does not run econometric estimation, does not modify provider source data, does not create preservation or archive refs, and does not replace the frozen Chapter 2 capital stock as a paper-facing baseline.

## Governance Evidence Read

- `chapter2_vault/04_data_measurement/V02_GPIM_Constitution.md`
- `reports/report_gpim_shaikh_comparison_2026-06-25/report_gpim_shaikh_comparison_2026-06-25.md`
- `reports/report_gpim_shaikh_comparison_2026-06-25/tables/table_11_finding_matrix.csv`
- `reports/report_gpim_shaikh_comparison_2026-06-25/validation/validation_checks.csv`
- `codes/US_GPIM_shaikh_capital_stock_decay_diagnostic.R`

The governing locks are preserved: survival is an extensive-margin schedule; conditional productive intensity is separate; gross surviving stock is repaired first; net or wealth stock is excluded; quality and intensity are not double counted; productive stock and capital services remain distinct; no productive stock is converted into wealth stock or CFC.

## Input Selection

The latest authorized real-investment input selected for D01 is:

`output/US/S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION/csv/S29C_fixed_assets_price_real_investment_long.csv`

The D01 script filters this file to:

- `I_ME_REAL_2017`, ME, `asset_specific_real_investment_flow`
- `I_NRC_REAL_2017`, NRC, `asset_specific_real_investment_flow`

Both series cover 1901-2024 in `millions_2017_dollars`.

## Method

The implemented survival schedule is:

```text
S(a) = exp(-((a / lambda) ^ alpha))
lambda = L / Gamma(1 + 1 / alpha)
K_asset,t = sum_a I_asset,t-a * S_asset(a)
```

Locked parameter results:

| Asset | Mean life L | Alpha | Lambda | S(L) | S(L+1) |
|---|---:|---:|---:|---:|---:|
| ME | 14 | 1.7 | 15.690766 | 0.438761 | 0.396009 |
| NRC | 30 | 1.6 | 33.460697 | 0.431828 | 0.412731 |

Government transportation parameters are retained only as metadata in `D01_survival_schedule_table.csv`; they are not part of the core ME+NRC stock.

## Outputs

All generated outputs are isolated under:

`output/US/D01_GPIM_GROSS_SURVIVAL_REMEDIATION/`

Generated files:

- `D01_gpim_gross_survival_panel.csv`
- `D01_gpim_core_capital_panel.csv`
- `D01_survival_schedule_table.csv`
- `D01_input_provenance_ledger.csv`
- `D01_validation_checks.csv`
- `D01_vs_frozen_diagnostic_comparison.csv`
- `D01_remediation_report.md`

The changed-path ledger is:

`reports/maintenance/D01_GPIM_GROSS_SURVIVAL_REMEDIATION_2026-06-26/D01_changed_paths_ledger.csv`

## Validation

`Rscript codes/US_D01_gpim_gross_survival_remediation.R` completed successfully.

Validation result: 15 PASS, 0 FAIL.

Key checks passed:

- Lambda calibration matches locked values.
- Survival at mean life is positive.
- Survival schedules are monotone non-increasing.
- S(0) equals 1.
- No terminal cliff exists at mean life.
- Asset stocks are nonnegative.
- Core stock is positive where observed.
- ME and NRC remain separately reported.
- Outputs are isolated to the D01 directory.
- Data outputs contain no net, wealth, productive, or efficiency stock columns.
- Input provenance hashes are present.
- 1947 index is populated because 1947 is observed.
- Report states no downstream econometric authorization.
- Required output files are generated.
- No live API or provider mutation dependency is used.

## Diagnostic Comparison

D01 produces a 2024 core index of `41.808879` on a 1947=100 basis. This matches the untruncated diagnostic target and differs from the frozen terminal-cliff series endpoint of `35.806099`.

D01 remains far below the Shaikh asset ME+NRC and aggregate Weibull diagnostic paths, so this pass resolves the retirement-schedule defect only. Input-path and initialization-history diagnostics remain open for later phases.

## Authorization Boundary

D01 authorizes only the isolated gross-survival remediation artifact. It does not authorize paper-facing baseline replacement, S31/S32 reruns, VECM estimation, investment-function estimation, or downstream econometric consumption.
