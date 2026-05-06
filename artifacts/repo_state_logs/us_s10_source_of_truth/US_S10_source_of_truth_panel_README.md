# US S10 source-of-truth panel

Created by: codes/US_S10_source_of_truth_panel.R
Rebase year: 2024
Input raw k-stock/distribution file: C:/ReposGitHub/Capacity-Utilization-US_Chile/data/raw/us/US_corporate_NF_kstock_distribution.csv
Input BEA income file: C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset/data/processed/income_accounts_NF.csv
Output final panel: C:/ReposGitHub/Capacity-Utilization-US_Chile/data/final/US/us_source_of_truth_panel.csv
Output processed compatibility panel: C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/US/us_source_of_truth_panel.csv

## Span
- First year: 1929
- Last year: 2024
- Observations: 96

## Composition availability
- Machinery stock column detected: none
- Other stock column detected: none
- s_t available: FALSE
- phi_t available: FALSE

## Contract
S10 only constructs the canonical panel. It does not estimate theta, reconstruct productive capacity, derive utilization, or export paper-facing results.
