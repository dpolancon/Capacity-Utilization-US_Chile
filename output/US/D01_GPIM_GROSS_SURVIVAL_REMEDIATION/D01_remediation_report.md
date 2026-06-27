# D01 GPIM Gross-Survival Remediation

**Date:** 2026-06-26
**Status:** Gross-survival remediation output; not authorized for econometric consumption.

## Governance lock

The V02 GPIM Constitution governs this pass. It supersedes specifications that treat mean service life as a terminal age, force Weibull survival to zero after the mean life, or conflate survival, conditional productive intensity, and economic depreciation.

D01 therefore repairs only the gross real surviving stock. It does not construct a productive stock, a net or wealth stock, a capital-services series, current-cost valuation, or consumption of fixed capital. The current capital-stock series remains unauthorized as a paper-facing baseline until reimplementation and validation are complete.

## Diagnostic basis

The GPIM decay diagnostic found that the inherited terminal-exit rule removed large surviving cohort mass immediately after the stated mean life. It also found that input-path and initialization differences remain material. D01 is therefore a first remediation step, not a full refreeze.

Finding-matrix evidence: 

## Inputs

- Real-investment source: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION/csv/S29C_fixed_assets_price_real_investment_long.csv`.
- Included D01 assets: ME and NRC.
- Excluded from the core D01 construction: IPP, residential assets, government assets, inventories, land, and government transportation infrastructure.
- Government transportation Weibull parameters are retained only as metadata in the survival schedule table.

## Method

The implemented survival function is:

```text
S(a) = exp(-((a / lambda) ^ alpha))
lambda = L / Gamma(1 + 1 / alpha)
K_asset,t = sum_a I_asset,t-a * S_asset(a)
```

- ME: L = 14, alpha = 1.7, lambda = 15.690766.
- NRC: L = 30, alpha = 1.6, lambda = 33.460697.
- Government transportation metadata only: L = 60, alpha = 1.3, lambda = 64.964825.

The timing convention is beginning-of-year vintage inclusion for annual cohorts in the exact cohort convolution. No computational cliff is imposed at mean service life; surviving tail mass remains positive beyond L.

## Outputs

- `D01_gpim_gross_survival_panel.csv`
- `D01_gpim_core_capital_panel.csv`
- `D01_survival_schedule_table.csv`
- `D01_input_provenance_ledger.csv`
- `D01_validation_checks.csv`
- `D01_vs_frozen_diagnostic_comparison.csv`

## Authorization boundary

D01 authorizes only the isolated gross-survival repair artifact. It does not authorize replacement of the frozen Chapter 2 stock, S31/S32 reruns, VECM estimation, investment-function estimation, paper-facing baseline use, or downstream econometric consumption.

## Source checks read

- Constitution line count: 1290
- Diagnostic report line count: 96
