# US S20 composition and stability admissibility summary

## Status

This file records the S20 admissibility layer for the US case.

It does not perform final coefficient recovery and does not reconstruct productive capacity or utilization.

## Data span

- First year: 1929
- Last year: 2024
- Observations: 96

## Composition availability

- composition_status = proxy_available
- composition_basis = ME_NRC_component_proxy
- composition_tier = Tier B
- direct_sector_asset_split = FALSE
- sector_target = NFCorp
- Estimation sample checked: 1929-2024 (N = 96)
- The ME-NRC component proxy is present and non-missing for the S20 estimation sample.
- s_t direct asset split is not available in the current US source panel.
- phi_t direct investment-composition split is not available in the current US source panel.
- Default proxy mappings: s_t_proxy = s_ME_over_ME_NRC_gross_real; phi_t_proxy = phi_ME_over_ME_NRC_real.
- Diagnostic proxy mappings: s_t_proxy_cc = s_ME_over_ME_NRC_gross_cc; phi_t_proxy_cc = phi_ME_over_ME_NRC_cc; pK_relative_ME_NRC = pK_relative_ME_NRC.
- Interpretation: Tier-B ME-NRC component proxy for the NFCorp-centered transformation relation; not a direct nonfinancial-corporate-by-asset-type split.

## Candidate windows

- Window register: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S20_composition_admissibility/us_s20_candidate_window_register.csv`
- Window summary: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S20_composition_admissibility/us_s20_window_admissibility_summary.csv`

## Guardrail

OLS scans in this script are diagnostic only. They do not replace FM-OLS, IM-OLS, or DOLS in S30/S90.

DOLS-era windows are treated as candidate historical/admissibility windows, not as final regimes.

S30 may proceed only after this S20 layer is reviewed.
