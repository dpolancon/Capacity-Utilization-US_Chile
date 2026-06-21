# S29E Stock-Flow-Consistent Core Capital Aggregation Validation

Validation result: `PASS 72`.

Core constructed variables: `5`.
Output panel rows: `1860`.
Core first fully supported year: `1931`.
Maximum reconciliation residual: `0.00000000745058059692383`.
Maximum aggregate SFC residual: `0.000000116415321826935`.

S29E constructs core investment, gross stock, net stock, retirements, and CFC by exact ME+NRC addition only. It constructs no weighted capital index, chain index, q, theta, productive capacity, utilization, modeling, or econometric output.

## Checks

- `s29d_outputs_present`: `PASS` - S29D_asset_specific_gpim_stocks_flows_long.csv; S29D_gpim_parameter_schedule_audit.csv; S29D_asset_specific_construction_ledger.csv; S29D_asset_specific_source_to_stock_provenance.csv; S29D_asset_specific_gross_sfc_residual_audit.csv; S29D_asset_specific_net_sfc_residual_audit.csv; S29D_initialization_support_status_audit.csv; S29D_locked_baseline_comparison_audit.csv; S29D_no_aggregation_audit.csv; S29D_validation_checks.csv; S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION_VALIDATION.md; S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION_DECISION.md
- `s29d_validation_all_pass`: `PASS` - S29D_validation_checks.csv PASS 79
- `s29d_decision_authorizes_s29e`: `PASS` - AUTHORIZE_S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION
- `s29c_outputs_present`: `PASS` - S29C_fixed_assets_price_real_investment_long.csv; S29C_validation_checks.csv
- `s29c_validation_all_pass`: `PASS` - S29C_validation_checks.csv PASS 77
- `me_real_investment_present`: `PASS` - I_ME_REAL_2017
- `nrc_real_investment_present`: `PASS` - I_NRC_REAL_2017
- `gross_me_stock_present`: `PASS` - G_ME_GPIM_2017
- `gross_nrc_stock_present`: `PASS` - G_NRC_GPIM_2017
- `net_me_stock_present`: `PASS` - N_ME_GPIM_2017
- `net_nrc_stock_present`: `PASS` - N_NRC_GPIM_2017
- `me_retirement_present`: `PASS` - RET_ME_GPIM_2017
- `nrc_retirement_present`: `PASS` - RET_NRC_GPIM_2017
- `me_cfc_present`: `PASS` - CFC_ME_GPIM_2017
- `nrc_cfc_present`: `PASS` - CFC_NRC_GPIM_2017
- `me_unit_is_millions_2017_dollars`: `PASS` - ME unit millions_2017_dollars
- `nrc_unit_is_millions_2017_dollars`: `PASS` - NRC unit millions_2017_dollars
- `me_nrc_units_compatible`: `PASS` - ME/NRC units compatible
- `me_nrc_frequency_compatible`: `PASS` - annual frequency
- `me_nrc_timing_compatible`: `PASS` - identical calendar years
- `me_nrc_coverage_compatible`: `PASS` - 1901-2024, 124 years
- `core_boundary_contains_only_me_and_nrc`: `PASS` - component scope ME/NRC only
- `core_real_investment_constructed`: `PASS` - I_CORE_REAL_2017
- `core_gross_stock_constructed`: `PASS` - G_CORE_GPIM_2017
- `core_net_stock_constructed`: `PASS` - N_CORE_GPIM_2017
- `core_retirement_constructed`: `PASS` - RET_CORE_GPIM_2017
- `core_cfc_constructed`: `PASS` - CFC_CORE_GPIM_2017
- `core_real_investment_exact_addition_pass`: `PASS` - I exact addition
- `core_gross_stock_exact_addition_pass`: `PASS` - G exact addition
- `core_net_stock_exact_addition_pass`: `PASS` - N exact addition
- `core_retirement_exact_addition_pass`: `PASS` - RET exact addition
- `core_cfc_exact_addition_pass`: `PASS` - CFC exact addition
- `component_reconciliation_residuals_within_tolerance`: `PASS` - max 0.00000000745058059692383
- `core_gross_sfc_identity_pass`: `PASS` - gross core SFC PASS
- `core_net_sfc_identity_pass`: `PASS` - net core SFC PASS
- `core_gross_sfc_max_residual_within_tolerance`: `PASS` - max 0.000000098254531621933
- `core_net_sfc_max_residual_within_tolerance`: `PASS` - max 0.000000116415321826935
- `core_first_fully_supported_year_equals_1931`: `PASS` - core first fully supported 1931
- `core_warmup_years_explicitly_flagged`: `PASS` - warm-up rows flagged
- `core_fully_supported_years_explicitly_flagged`: `PASS` - fully supported rows flagged
- `common_unit_timing_audit_created`: `PASS` - 6 unit/timing rows
- `construction_ledger_created`: `PASS` - 5 ledger rows
- `reconciliation_audit_created`: `PASS` - 5 reconciliation rows
- `gross_sfc_audit_created`: `PASS` - gross SFC audit created
- `net_sfc_audit_created`: `PASS` - net SFC audit created
- `support_status_audit_created`: `PASS` - 124 support rows
- `provenance_ledger_created`: `PASS` - 5 provenance rows
- `me_gross_share_constructed_as_diagnostic`: `PASS` - ME gross share diagnostic
- `nrc_gross_share_constructed_as_diagnostic`: `PASS` - NRC gross share diagnostic
- `gross_composition_shares_sum_to_one`: `PASS` - max residual 0.000000000000000222044604925031
- `arithmetic_growth_contribution_audit_created`: `PASS` - 123 growth rows
- `arithmetic_growth_contribution_identity_pass`: `PASS` - max residual 0.000000000000000222044604925031
- `no_weighted_level_construction`: `PASS` - no weighted level construction
- `no_weighted_growth_stock_construction`: `PASS` - growth audit diagnostic only
- `no_chain_weighted_capital_index_constructed`: `PASS` - no chain index
- `no_gpim_rerun_on_aggregate_investment`: `PASS` - no aggregate GPIM rerun
- `no_gpim_parameters_modified`: `PASS` - no parameter modification
- `no_ipp_in_core`: `PASS` - no IPP
- `no_government_transportation_in_core`: `PASS` - no government transportation
- `no_residential_assets_in_core`: `PASS` - no residential
- `no_total_fixed_assets_in_core`: `PASS` - no total fixed assets
- `no_alternative_core_stock_constructed`: `PASS` - no alternative core stock
- `no_real_output_variables_constructed`: `PASS` - no real output
- `no_q_variables_constructed`: `PASS` - no q
- `no_theta_variables_constructed`: `PASS` - no theta
- `no_productive_capacity_constructed`: `PASS` - no productive capacity
- `no_utilization_constructed`: `PASS` - no utilization
- `no_modeling_outputs_created`: `PASS` - no modeling
- `no_econometric_outputs_created`: `PASS` - no econometrics
- `no_adjusted_shaikh_objects_constructed`: `PASS` - no adjusted Shaikh
- `upstream_outputs_not_modified`: `PASS` - S29D/S29C input hashes unchanged
- `provider_repository_not_modified`: `PASS` - Provider repo tracked and staged diffs are clean; untracked local files are ignored.
