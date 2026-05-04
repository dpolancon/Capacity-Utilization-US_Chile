# Fast cleanup map — 2026-05-03

## Keep as active code

Candidate active scripts:

- `codes/CL_00_source_of_truth_chile.R`
- `codes/CL_01_stage1_mu.R`
- `codes/CL_03_results_package_mu_theta_wsh.R`
- `codes/CL_04_results_presentation.R`
- `codes/CL_05_profitability_analysis_core.R`
- `codes/CL_06_results_package_profitability.R`
- `codes/CL_07_results_package_profitability_diagnostics.R`
- `codes/CL_10_class_struggle_diagnostic.R`
- `codes/CL_11_dys_diagnostic_package.R`
- `codes/CL_12_capacity_utilization_diagnostic*.R`
- `codes/US_dols_*.R`
- `codes/us_profitability_analysis*.R`

## Keep as active data

- `data/raw/Chile/harmonized_series_2003CLP_1900_2024.csv`
- `data/final/chile_panel.csv`
- `data/final/chile_panel_README.txt`
- `data/processed/US/*`
- `data/processed/wbop_*`

## Keep as active outputs for review

- `output/source_of_truth_chile/`
- `output/profitability_chile/`
- `output/profitability_chile_diagnostic/`
- `output/profitability_us/`
- `output/wbop/`
- `output/US_dols_diagnostics/`
- `output/US_theta_break_core_1929_1978/`
- `output/US_theta_window_benchmark_and_robustness/`
- `output/chile_diagnostic_package/`

## Quarantine candidates

- `output/_legacy/`
- `codes/_legacyV2/`
- `codes/legacy/`
- `artifacts/AR_Corridor/`
- `artifacts/chapter2/`

## Suspect accidental files

- `.Rprofile`
- `.qwen/`
- `QWEN.md`
- top-level `-type f`
- top-level malformed `"GitHub\" "` entry if present

## Fast cleanup sequence

1. Write logs.
2. Build inventory tables.
3. Move active scripts into a clearer structure.
4. Move legacy/scratch to quarantine.
5. Update `.gitignore`.
6. Stage selectively.
7. Commit to a curation branch, not `main`.
