# US S30 transformation-relation report

## 1. Purpose of S30

S30 estimates and audits the long-run US transformation relation through a pre-declared estimator x window x specification grid.
The purpose is coefficient recovery plus parameter-stability discipline. Historical windows are pre-declared benchmark contrasts, not search devices.

## 2. Input panel and variable coverage

- Input panel: `C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/US/us_s20_admissibility_panel.csv`
- Panel span: 1929-2024
- Observations: 96

| variable | present | finite_observations |
| --- | --- | --- |
| y_t | TRUE |    96 |
| k_t | TRUE |    96 |
| omega_t | TRUE |    96 |
| omega_k_t | TRUE |    96 |
| s_t_proxy | TRUE |    96 |
| phi_t_proxy | TRUE |    96 |
| s_t_proxy_cc | TRUE |    96 |
| phi_t_proxy_cc | TRUE |    96 |
| pK_relative_ME_NRC | TRUE |    96 |

## 3. Composition status

- composition_status: proxy_available
- composition_basis: ME_NRC_component_proxy
- composition_tier: Tier B
- direct_sector_asset_split: FALSE
- The US composition variable is a Tier-B ME-NRC component proxy.
- It is not a direct NFCorp-by-asset-type split.

## 4. Window register used

- Register written: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_candidate_window_register_used.csv`
- Windows used: 10

| window_id | year_start | year_end | role | source |
| --- | --- | --- | --- | --- |
| prefordist_core_1929_1944 |  1929 |  1944 | predecessor | S20_register |
| pre_1974 |  1929 |  1973 | pre_reference | S30_mandatory+S20_register |
| full_long_sample |  1929 |  2024 | full_reference | S30_mandatory+S20_register |
| pre_1974_alt_1940_1973 |  1940 |  1973 | support | S30_mandatory |
| bridge_1940_1978 |  1940 |  1978 | bridge | S30_mandatory+S20_register |
| fordist_core |  1945 |  1973 | benchmark | S30_mandatory+S20_register |
| pre_1974_alt_1947_1974 |  1947 |  1974 | support | S30_mandatory |
| post_1974_tight |  1974 |  1983 | support_short | S30_mandatory+S20_register |
| post_1974_support |  1974 |  1987 | support | S30_mandatory+S20_register |
| post_1973 |  1974 |  2024 | post_reference | S30_mandatory+S20_register |

## 5. Estimator availability

| estimator | role | package | function_name | available |
| --- | --- | --- | --- | --- |
| FM_OLS | main_estimator | cointReg | cointRegFM | TRUE |
| IM_OLS | robustness_estimator | cointReg | cointRegIM | TRUE |
| DOLS | fragility_stress_diagnostic | cointReg | cointRegD | TRUE |

- Estimators successfully run: DOLS, FM_OLS, IM_OLS
- Estimators unavailable: none

## 6. Specification register

- Register written: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_specification_register.csv`

| spec_id | formula_label | role | promotion_eligible | diagnostic_only |
| --- | --- | --- | --- | --- |
| SPEC_B0_CAPITAL_ONLY | y_t ~ k_t | baseline_reference | FALSE | FALSE |
| SPEC_B1_WAGE_BASELINE | y_t ~ k_t + omega_k_t | core_candidate | TRUE | FALSE |
| SPEC_C1_COMPOSITION_STOCK | y_t ~ k_t + omega_k_t + s_proxy_k_t | core_candidate | TRUE | FALSE |
| SPEC_C2_FULL_COMPOSITION | y_t ~ k_t + omega_k_t + s_proxy_k_t + omega_s_proxy_k_t | core_candidate | TRUE | FALSE |
| SPEC_D1_CURRENT_COST_DIAGNOSTIC | y_t ~ k_t + omega_k_t + s_proxy_cc_k_t | diagnostic_only | FALSE | TRUE |
| SPEC_D2_PRICE_WEDGE_DIAGNOSTIC | y_t ~ k_t + omega_k_t + s_proxy_k_t + pKrel_k_t | diagnostic_only | FALSE | TRUE |

## 7. Main estimator grid summary

- Estimator grid: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_estimator_grid.csv`
- Estimated windows: 10
- Estimated specifications: 6

| estimator | estimator_status | status | grid_cells |
| --- | --- | --- | --- |
| DOLS | ok | estimated |    38 |
| FM_OLS | ok | estimated |    60 |
| IM_OLS | ok | estimated |    60 |
| DOLS | rejected_sample_size | rejected_sample_size |    22 |

## 8. Stability and proxy-stability summary

- Stability summary: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_window_stability_summary.csv`
- Exact Hansen-type parameter-instability testing was not implemented in this S30 script.
- The stability check is labeled proxy_stability_diagnostic and uses estimator triangulation, neighborhood checks, collinearity diagnostics, and rolling coefficient paths.
- Rolling/recursive diagnostics do not identify regimes.

| classification | n |
| --- | --- |
| CORE_CANDIDATE | 0 |
| SUPPORTING |    10 |
| FRAGILE |    30 |
| DIAGNOSTIC_ONLY |    20 |
| REJECTED | 0 |

## 9. Rolling/recursive diagnostic summary

- Rolling coefficients: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_rolling_coefficients.csv`
- Rolling estimates are diagnostics, not regime identifiers.
- Recursive estimates are not implemented in this first S30 script.

| metric | value |
| --- | --- |
| rolling_window_length | 30 |
| diagnostic_type | FM_OLS_cointegrating_diagnostic |
| estimated_rows | 804 |
| failed_or_rejected_rows | 0 |

## 10. Promotion table

Promotion is review eligibility only. No result is promoted solely because a coefficient has a preferred sign or significance.

| window_id | spec_id | classification | promotion_status | fm_ols_ok | im_ols_ok | dols_ok | severe_collinearity_flag | neighborhood_reversal_count | rolling_proxy_reversal_count |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| prefordist_core_1929_1944 | SPEC_B1_WAGE_BASELINE | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | FALSE |     1 |     1 |
| prefordist_core_1929_1944 | SPEC_C1_COMPOSITION_STOCK | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | FALSE |     3 |     2 |
| prefordist_core_1929_1944 | SPEC_C2_FULL_COMPOSITION | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | TRUE |     6 |     3 |
| pre_1974 | SPEC_B1_WAGE_BASELINE | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     4 |     1 |
| pre_1974 | SPEC_C1_COMPOSITION_STOCK | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     6 |     2 |
| pre_1974 | SPEC_C2_FULL_COMPOSITION | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | TRUE |    14 |     3 |
| full_long_sample | SPEC_B1_WAGE_BASELINE | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     6 |     1 |
| full_long_sample | SPEC_C1_COMPOSITION_STOCK | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     6 |     2 |
| full_long_sample | SPEC_C2_FULL_COMPOSITION | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | TRUE |    10 |     3 |
| pre_1974_alt_1940_1973 | SPEC_B1_WAGE_BASELINE | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     4 |     1 |
| pre_1974_alt_1940_1973 | SPEC_C1_COMPOSITION_STOCK | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |    10 |     2 |
| pre_1974_alt_1940_1973 | SPEC_C2_FULL_COMPOSITION | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | TRUE |    10 |     3 |
| bridge_1940_1978 | SPEC_B1_WAGE_BASELINE | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     4 |     1 |
| bridge_1940_1978 | SPEC_C1_COMPOSITION_STOCK | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |    10 |     2 |
| bridge_1940_1978 | SPEC_C2_FULL_COMPOSITION | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | TRUE |    10 |     3 |
| fordist_core | SPEC_B1_WAGE_BASELINE | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     4 |     1 |
| fordist_core | SPEC_C1_COMPOSITION_STOCK | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |    10 |     2 |
| fordist_core | SPEC_C2_FULL_COMPOSITION | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | TRUE |    14 |     3 |
| pre_1974_alt_1947_1974 | SPEC_B1_WAGE_BASELINE | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     4 |     1 |
| pre_1974_alt_1947_1974 | SPEC_C1_COMPOSITION_STOCK | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     6 |     2 |
| pre_1974_alt_1947_1974 | SPEC_C2_FULL_COMPOSITION | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | TRUE |     8 |     3 |
| post_1974_tight | SPEC_B1_WAGE_BASELINE | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | FALSE |     5 |     1 |
| post_1974_tight | SPEC_C1_COMPOSITION_STOCK | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | FALSE |     9 |     2 |
| post_1974_tight | SPEC_C2_FULL_COMPOSITION | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | TRUE |    14 |     3 |
| post_1974_support | SPEC_B1_WAGE_BASELINE | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | FALSE |     5 |     1 |
| post_1974_support | SPEC_C1_COMPOSITION_STOCK | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | FALSE |     9 |     2 |
| post_1974_support | SPEC_C2_FULL_COMPOSITION | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | FALSE | TRUE |    13 |     3 |
| post_1973 | SPEC_B1_WAGE_BASELINE | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     5 |     1 |
| post_1973 | SPEC_C1_COMPOSITION_STOCK | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | FALSE |     9 |     2 |
| post_1973 | SPEC_C2_FULL_COMPOSITION | FRAGILE | not_promoted_fragility_flag | TRUE | TRUE | TRUE | TRUE |    13 |     3 |

## 11. Guardrails and non-claims

- S30 does not reconstruct μ.
- S30 does not estimate θ^M directly.
- S30 does not reconstruct Yp.
- S30 does not compute capacity utilization.
- S30 does not run profitability analysis.
- S30 does not estimate threshold/FGLS.
- S30 does not run Gregory-Hansen, Bai-Perron, or Kejriwal-Perron.
- The Tier-B ME-NRC proxy is not a direct NFCorp-by-asset-type split.
- Historical windows are pre-declared benchmark contrasts.

## 12. Next step

S40 is allowed only after a S30 core candidate is reviewed.

## Warnings

- none
