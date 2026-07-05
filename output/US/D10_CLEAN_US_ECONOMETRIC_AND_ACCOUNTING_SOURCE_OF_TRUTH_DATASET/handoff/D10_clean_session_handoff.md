# Chapter 2 - D10 Clean Restart Handoff

## Final state

Final decision code: AUTHORIZE_D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW
D11 authorized: TRUE

## Branch and commit

Branch: restart/d10-clean-from-d09s
Base commit: f54c2ba
HEAD at build time: f54c2ba68d2c05b6589f3b8fa212714211680053

## Rscript path and version

Rscript path: C:\Program Files\R\R-4.5.2\bin\Rscript.exe
Rscript version: R version 4.5.2 (2025-10-31 ucrt) [Not] Part in a Rumble

## Dataset facts

Output folder: C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET
Wide panel shape: 125 rows x 72 columns.
Long panel row count: 6959
Variable dictionary row count: 223
Validation count: 37/37 PASS

## Baseline locks

K_capacity = K_ME + K_NRC.
ME: L=14, alpha=1.7.
NRC: L=30, alpha=1.6.
D09-S service-life sensitivity stocks remain report-only.

## Accounting scope

NFC productive-origin variables are the only baseline econometric objects.
Raw corporate variables are authorized raw comparison objects.
Corporate-clean, financial/imputed-interest, and exploitation-rate objects remain candidate, crosswalk, or construction-contract objects.
Tax, subsidy, transfer, interest, profit-tax, dividend, and retained-surplus variables are accounting bridges.

## What is not authorized

No q_omega object is authorized.
No D09-S sensitivity stock is authorized for baseline capital.
No total capital, total fixed assets, IPP, residential capital, government transportation, or all-BEA fixed-assets object is authorized for baseline capital.
No econometric estimation or integration testing is authorized by D10 clean.

## Next recommended pass

Run D11 integration and estimation readiness review only if this D10 clean commit is accepted.

## Resume commands

cd C:\ReposGitHub\Capacity-Utilization-US_Chile
git status --short --branch
git log --oneline --decorate -10
Get-Content output\US\D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET\csv\D10_clean_validation_checks.csv
