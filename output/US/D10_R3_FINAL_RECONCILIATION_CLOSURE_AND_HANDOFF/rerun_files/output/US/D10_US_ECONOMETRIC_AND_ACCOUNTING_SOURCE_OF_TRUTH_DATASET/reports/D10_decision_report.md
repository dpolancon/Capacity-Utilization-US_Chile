# D10 Decision Report

D10 consolidates the U.S. econometric and accounting source-of-truth dataset. It estimates nothing.

## Opening repository state
- Branch: main
- HEAD: f54c2ba68d2c05b6589f3b8fa212714211680053
- origin/main: f54c2ba68d2c05b6589f3b8fa212714211680053
- Required terminal commit present: f54c2ba Implement D09-S GPIM service-life sensitivity report
- Initial working tree: clean

## Locked upstream decisions
- D05: AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN
- D06: AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION
- D07-0: AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION
- D07: AUTHORIZE_D08_SOURCE_OF_TRUTH_REVIEW
- D08: AUTHORIZE_D09_TRANSFORMATION_PLANNING
- D09: AUTHORIZE_D10_TRANSFORMATION_PLANNING
- D09-R: AUTHORIZE_D09_DOUBLE_VALIDATION_REVIEW
- D09-S: AUTHORIZE_D10_TRANSFORMATION_PLANNING_WITH_NRC_ROBUSTNESS_FLAG

## Baseline capital lock
K_capacity = K_ME + K_NRC. ME uses L = 14 and alpha = 1.7. NRC uses L = 30 and alpha = 1.6.

NRC_ROBUSTNESS_FLAG is carried forward because longer NRC service lives reduce the late-sample decline but increase inherited-vintage/warmup fragility. D09-S sensitivity stocks remain report-only and do not enter D10 baseline variables.

## Source mapping
- D06 capacity: output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN/csv/D06_capacity_refrozen_panel.csv
- D07 level panel: output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/csv/D07_level_accounting_panel_wide.csv
- D09-S sensitivity report: reports/report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01/tex/report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01.tex

## Decision
REQUIRE_D10_RECONCILIATION

Corporate-clean accounting and financial/imputed-interest corrections are preserved as candidate/crosswalk objects, not model-ready baseline inputs. The baseline boundary is intact, q_omega is parked, and no econometrics were run.
