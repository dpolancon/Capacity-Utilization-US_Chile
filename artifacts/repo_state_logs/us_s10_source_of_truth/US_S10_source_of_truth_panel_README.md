# US S10 source-of-truth panel

Created by: codes/US_S10_source_of_truth_panel.R
Rebase year: 2024
Input raw k-stock/distribution file: C:/ReposGitHub/Capacity-Utilization-US_Chile/data/raw/us/US_corporate_NF_kstock_distribution.csv
Input BEA income file: C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset/data/processed/income_accounts_NF.csv
Input composition bridge file: C:/ReposGitHub/Capacity-Utilization-US_Chile/data/raw/US/us_nfcorp_composition_proxy_for_ch2.csv
Output final panel: C:/ReposGitHub/Capacity-Utilization-US_Chile/data/final/US/us_source_of_truth_panel.csv
Output processed compatibility panel: C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/US/us_source_of_truth_panel.csv

## Span
- First year: 1929
- Last year: 2024
- Observations: 96
- K_t alias: K_total_real
- capacity_register: gross_real_GPIM_stock
- a00_baseline_available: TRUE
- omega_k_formula: omega_t * k_t

## Composition availability
- Machinery stock column detected: none
- Other stock column detected: none
- s_t available: FALSE
- phi_t available: FALSE
- Composition bridge present: TRUE
- Composition bridge merged: TRUE
- Composition bridge rows: 100
- Composition bridge matched rows with default proxies: 96
- composition_status: proxy_available
- composition_basis: ME_NRC_component_proxy
- composition_tier: Tier B
- direct_sector_asset_split: FALSE
- sector_target: NFCorp
- Default proxy mappings: s_t_proxy = s_ME_over_ME_NRC_gross_real; phi_t_proxy = phi_ME_over_ME_NRC_real.
- Diagnostic proxy mappings: s_t_proxy_cc = s_ME_over_ME_NRC_gross_cc; phi_t_proxy_cc = phi_ME_over_ME_NRC_cc; pK_relative_ME_NRC = pK_relative_ME_NRC.
- Interpretation: Tier-B ME-NRC component proxy for the NFCorp-centered transformation relation; not a direct nonfinancial-corporate-by-asset-type split.
- No S10 composition bridge warning.

## Contract
S10 only constructs the canonical panel. It does not estimate theta, reconstruct productive capacity, derive utilization, or export paper-facing results.
