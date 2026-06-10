# U.S. S10 Source-of-Truth Construction Ledger

## Purpose

This ledger records provider ingredients and downstream-owned objects without constructing the pending analytical variables.

## Admissibility summary

|Admissibility status|Rows|
|---|---|
|alternative_proxy_pending| 7|
|blocked_pending_current_release_protocol|17|
|diagnostic_pending|21|
|downstream_constructed_pending|36|
|frontier_conditioner_pending|17|
|not_in_baseline|26|
|preferred_baseline_pending| 4|
|robustness_pending| 2|
|staged_source_ingredient|94|
|superseded_diagnostic_only|12|

## Downstream object registry

|object_id|construction_stage|analytical_role|admissibility_status|blocking_reason|
|---|---|---|---|---|
|ME_NRC_gap|S20_capital_construction|capital_composition_diagnostic|diagnostic_pending||
|ME_share|S20_capital_construction|capital_composition_diagnostic|diagnostic_pending||
|NRC_share|S20_capital_construction|capital_composition_diagnostic|diagnostic_pending||
|g_K_ME|S20_capital_construction|capital_transformation|downstream_constructed_pending||
|g_K_NRC|S20_capital_construction|capital_transformation|downstream_constructed_pending||
|g_Kcap|S20_capital_construction|capital_transformation|downstream_constructed_pending||
|k_Kcap|S20_capital_construction|capital_transformation|downstream_constructed_pending||
|k_ME|S20_capital_construction|capital_transformation|downstream_constructed_pending||
|k_NRC|S20_capital_construction|capital_transformation|downstream_constructed_pending||
|K_ME|S20_capital_construction|direct_productive_capacity_capital|downstream_constructed_pending||
|K_NRC|S20_capital_construction|direct_productive_capacity_capital|downstream_constructed_pending||
|K_cap|S20_capital_construction|preferred_productive_capacity_baseline|preferred_baseline_pending||
|pi_adj_res_CORP_t|S20_current_release_Shaikh_protocol|adjusted_residual_profit_share|blocked_pending_current_release_protocol|Current BEA candidate lines are provenance/candidate ingredients only, not formula-admissible inputs.|
|e_adj_CORP_t|S20_current_release_Shaikh_protocol|alternative_distributive_proxy_adjusted_variant|blocked_pending_current_release_protocol|Current BEA candidate lines are provenance/candidate ingredients only, not formula-admissible inputs.|
|omega_adj_CORP_t|S20_current_release_Shaikh_protocol|preferred_distributive_state_adjusted_variant|blocked_pending_current_release_protocol|Current BEA candidate lines are provenance/candidate ingredients only, not formula-admissible inputs.|
|GVAcorp_adj_t|S20_current_release_Shaikh_protocol|Shaikh_adjusted_income|blocked_pending_current_release_protocol|Current BEA candidate lines are provenance/candidate ingredients only, not formula-admissible inputs.|
|NOScorp_adj_t|S20_current_release_Shaikh_protocol|Shaikh_adjusted_income|blocked_pending_current_release_protocol|Current BEA candidate lines are provenance/candidate ingredients only, not formula-admissible inputs.|
|VAcorp_adj_t|S20_current_release_Shaikh_protocol|Shaikh_adjusted_income|blocked_pending_current_release_protocol|Current BEA candidate lines are provenance/candidate ingredients only, not formula-admissible inputs.|
|BankMonIntPaid_t|S20_current_release_Shaikh_protocol|Shaikh_style_interest_adjustment|blocked_pending_current_release_protocol|Current BEA candidate lines are provenance/candidate ingredients only, not formula-admissible inputs.|
|CorpImpIntAdj_t|S20_current_release_Shaikh_protocol|Shaikh_style_interest_adjustment|blocked_pending_current_release_protocol|Current BEA candidate lines are provenance/candidate ingredients only, not formula-admissible inputs.|
|CorpNFNetImpIntPaid_t|S20_current_release_Shaikh_protocol|Shaikh_style_interest_adjustment|blocked_pending_current_release_protocol|Current BEA candidate lines are provenance/candidate ingredients only, not formula-admissible inputs.|
|e_CORP|S20_distribution_construction|alternative_distributive_proxy|alternative_proxy_pending||
|e_NFC|S20_distribution_construction|alternative_distributive_proxy|alternative_proxy_pending||
|ln_e_CORP|S20_distribution_construction|alternative_distributive_proxy|alternative_proxy_pending||
|ln_e_NFC|S20_distribution_construction|alternative_distributive_proxy|alternative_proxy_pending||
|omega_CORP|S20_distribution_construction|preferred_distributive_state|preferred_baseline_pending||
|omega_NFC|S20_distribution_construction|preferred_distributive_state|preferred_baseline_pending||
|pi_res_CORP|S20_distribution_construction|residual_profit_share|downstream_constructed_pending||
|pi_res_NFC|S20_distribution_construction|residual_profit_share|downstream_constructed_pending||
|GOV_TRANS_growth|S20_frontier_conditioning|frontier_conditioner|frontier_conditioner_pending||
|GOV_TRANS_stock|S20_frontier_conditioning|frontier_conditioner|frontier_conditioner_pending||
|GOV_TRANS_to_Kcap|S20_frontier_conditioning|frontier_conditioner|frontier_conditioner_pending||
|GOV_TRANS_to_ME|S20_frontier_conditioning|frontier_conditioner|frontier_conditioner_pending||
|GOV_TRANS_to_NRC|S20_frontier_conditioning|frontier_conditioner|frontier_conditioner_pending||
|IPP_growth|S20_frontier_conditioning|frontier_conditioner|frontier_conditioner_pending||
|IPP_share_capital_plus_IPP|S20_frontier_conditioning|frontier_conditioner|frontier_conditioner_pending||
|IPP_share_total_fixed_assets|S20_frontier_conditioning|frontier_conditioner|frontier_conditioner_pending||
|IPP_stock|S20_frontier_conditioning|frontier_conditioner|frontier_conditioner_pending||
|IPP_to_Kcap|S20_frontier_conditioning|frontier_conditioner|frontier_conditioner_pending||
|K_G_NFC_KCAP_GPIM|S20_GPIM_construction|GPIM_capital_object|downstream_constructed_pending||
|K_G_NFC_ME_GPIM|S20_GPIM_construction|GPIM_capital_object|downstream_constructed_pending||
|K_G_NFC_NRC_GPIM|S20_GPIM_construction|GPIM_capital_object|downstream_constructed_pending||
|K_N_NFC_KCAP_GPIM|S20_GPIM_construction|GPIM_capital_object|downstream_constructed_pending||
|K_N_NFC_ME_GPIM|S20_GPIM_construction|GPIM_capital_object|downstream_constructed_pending||
|K_N_NFC_NRC_GPIM|S20_GPIM_construction|GPIM_capital_object|downstream_constructed_pending||
|P_K_NFC_ME_GPIM|S20_GPIM_construction|GPIM_capital_object|downstream_constructed_pending||
|P_K_NFC_NRC_GPIM|S20_GPIM_construction|GPIM_capital_object|downstream_constructed_pending||
|q_e_h1_Kcap|S30_A00_variable_construction|alternative_proxy_accumulated_index_robustness|alternative_proxy_pending||
|q_e_h3_Kcap|S30_A00_variable_construction|alternative_proxy_accumulated_index_robustness|alternative_proxy_pending||
|q_e_h5_Kcap|S30_A00_variable_construction|alternative_proxy_accumulated_index_robustness|alternative_proxy_pending||
|q_omega_h1_Kcap|S30_A00_variable_construction|preferred_A00_accumulated_index|preferred_baseline_pending||
|q_omega_h3_Kcap|S30_A00_variable_construction|preferred_A00_accumulated_index_robustness|robustness_pending||
|q_omega_h5_Kcap|S30_A00_variable_construction|preferred_A00_accumulated_index_robustness|robustness_pending||
|e_x_Kcap|S30_superseded_diagnostics|superseded_level_interaction|superseded_diagnostic_only|Level interactions must not define A00, generated implementation variables, coefficient promotion, or S40 reconstruction.|
|e_x_ME|S30_superseded_diagnostics|superseded_level_interaction|superseded_diagnostic_only|Level interactions must not define A00, generated implementation variables, coefficient promotion, or S40 reconstruction.|
|e_x_ME_NRC_gap|S30_superseded_diagnostics|superseded_level_interaction|superseded_diagnostic_only|Level interactions must not define A00, generated implementation variables, coefficient promotion, or S40 reconstruction.|
|e_x_NRC|S30_superseded_diagnostics|superseded_level_interaction|superseded_diagnostic_only|Level interactions must not define A00, generated implementation variables, coefficient promotion, or S40 reconstruction.|
|omega_x_Kcap|S30_superseded_diagnostics|superseded_level_interaction|superseded_diagnostic_only|Level interactions must not define A00, generated implementation variables, coefficient promotion, or S40 reconstruction.|
|omega_x_ME|S30_superseded_diagnostics|superseded_level_interaction|superseded_diagnostic_only|Level interactions must not define A00, generated implementation variables, coefficient promotion, or S40 reconstruction.|
|omega_x_ME_NRC_gap|S30_superseded_diagnostics|superseded_level_interaction|superseded_diagnostic_only|Level interactions must not define A00, generated implementation variables, coefficient promotion, or S40 reconstruction.|
|omega_x_NRC|S30_superseded_diagnostics|superseded_level_interaction|superseded_diagnostic_only|Level interactions must not define A00, generated implementation variables, coefficient promotion, or S40 reconstruction.|

## Locks

- `K_cap = K_ME + K_NRC` is the preferred productive-capacity identity.
- IPP and GOV_TRANS are frontier conditioners, not additive capital terms.
- Unadjusted wage share is the first-pass preferred distributive state.
- Exploitation rate is an alternative proxy.
- `q_omega_*` is the preferred A00 accumulated-index family.
- `q_e_*` is alternative-proxy robustness.
- `omega_x_*` and `e_x_*` level interactions are `superseded_diagnostic_only`.
- Shaikh-adjusted objects are `blocked_pending_current_release_protocol`.
- S10 creates no GPIM, regression, capacity, or utilization object.
