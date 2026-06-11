# U.S. S20 Capital, Distribution, and Frontier Construction Ledger

## Productive-capacity capital

The preferred first-pass capital object is `K_cap = K_ME + K_NRC`. Machinery and equipment and nonresidential structures directly support productive capacity, and the NFC boundary is the locked preferred productive-sector boundary. Current-cost net stocks are used because they are additive common-unit S10 objects; official quantity indexes are diagnostic and cannot be summed as levels.

## Frontier conditioners

IPP is excluded from preferred productive-capacity capital because it conditions the transformation frontier rather than entering the direct ME-plus-NRC capacity identity. It remains in S20 through its stock, growth, and scale ratios.
GOV_TRANS is excluded because `K_cap` is private NFC capital. Transportation infrastructure remains a frontier conditioner through the auditable sum of transportation structures and highways/streets.

## Distribution

The unadjusted wage share is the first-pass baseline because direct compensation and gross-value-added lines are staged and admissible while the current-release Shaikh-style adjustment protocol remains blocked.
The exploitation rate and its log are retained only as alternative-proxy robustness variables; they do not replace the wage-share baseline.

## Deferred objects

Shaikh-adjusted variables remain blocked because the current-release semantic crosswalk has not passed. The `q_omega_*` and `q_e_*` accumulated indexes are deferred to S21. Integration testing and estimation are deferred to S30I and S30/S32.
Superseded `omega_x_*` and `e_x_*` level interactions are not analytical variables and are not constructed.

## Variable ledger

|s20_variable|s20_family|preferred_status|construction_status|source_s10_object_or_formula|formula|admissibility_basis|blocked_reason|notes|
|---|---|---|---|---|---|---|---|---|
|K_ME|productive_capacity_capital|preferred_component|constructed|NFC__ME__net_stock_current_cost|K_ME = S10 NFC ME net stock|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|K_NRC|productive_capacity_capital|preferred_component|constructed|NFC__NRC__net_stock_current_cost|K_NRC = S10 NFC NRC net stock|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|K_cap|productive_capacity_capital|preferred_baseline|constructed|K_ME + K_NRC|K_cap = K_ME + K_NRC|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.||IPP and GOV_TRANS are excluded.|
|k_ME|productive_capacity_capital|transformation|constructed|K_ME|k_ME = log(K_ME)|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|k_NRC|productive_capacity_capital|transformation|constructed|K_NRC|k_NRC = log(K_NRC)|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|k_Kcap|productive_capacity_capital|transformation|constructed|K_cap|k_Kcap = log(K_cap)|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|g_K_ME|productive_capacity_capital|transformation|constructed_with_missing_edges|k_ME|g_K_ME = Delta log(K_ME)|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|g_K_NRC|productive_capacity_capital|transformation|constructed_with_missing_edges|k_NRC|g_K_NRC = Delta log(K_NRC)|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|g_Kcap|productive_capacity_capital|transformation|constructed_with_missing_edges|k_Kcap|g_Kcap = Delta log(K_cap)|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|ME_NRC_gap|productive_capacity_capital|diagnostic|constructed|k_ME - k_NRC|ME_NRC_gap = k_ME - k_NRC|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|ME_share|productive_capacity_capital|diagnostic|constructed|K_ME / K_cap|ME_share = K_ME / K_cap|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|NRC_share|productive_capacity_capital|diagnostic|constructed|K_NRC / K_cap|NRC_share = K_NRC / K_cap|S10 marks NFC ME and NRC current-cost net stocks as staged direct productive-capacity ingredients; NFC is the preferred nonfinancial corporate productive-sector boundary.|||
|omega_CORP|distribution_unadjusted|preferred_baseline|constructed|CORP_COMP / CORP_GVA|omega_CORP = CORP_COMP / CORP_GVA|S10 stages direct NIPA compensation and gross-value-added lines and registers unadjusted wage shares as the preferred first-pass baseline.|||
|omega_NFC|distribution_unadjusted|preferred_baseline|constructed|NFC_COMP / NFC_GVA|omega_NFC = NFC_COMP / NFC_GVA|S10 stages direct NIPA compensation and gross-value-added lines and registers unadjusted wage shares as the preferred first-pass baseline.|||
|pi_res_CORP|distribution_unadjusted|residual_share|constructed|1 - omega_CORP|pi_res_CORP = 1 - omega_CORP|S10 stages direct NIPA compensation and gross-value-added lines and registers unadjusted wage shares as the preferred first-pass baseline.|||
|pi_res_NFC|distribution_unadjusted|residual_share|constructed|1 - omega_NFC|pi_res_NFC = 1 - omega_NFC|S10 stages direct NIPA compensation and gross-value-added lines and registers unadjusted wage shares as the preferred first-pass baseline.|||
|e_CORP|distribution_alternative_proxy|alternative_proxy|constructed|pi_res_CORP / omega_CORP|e_CORP = pi_res_CORP / omega_CORP|S10 stages direct NIPA compensation and gross-value-added lines and registers unadjusted wage shares as the preferred first-pass baseline.|||
|e_NFC|distribution_alternative_proxy|alternative_proxy|constructed|pi_res_NFC / omega_NFC|e_NFC = pi_res_NFC / omega_NFC|S10 stages direct NIPA compensation and gross-value-added lines and registers unadjusted wage shares as the preferred first-pass baseline.|||
|ln_e_CORP|distribution_alternative_proxy|alternative_proxy|constructed|e_CORP|ln_e_CORP = log(e_CORP)|S10 stages direct NIPA compensation and gross-value-added lines and registers unadjusted wage shares as the preferred first-pass baseline.|||
|ln_e_NFC|distribution_alternative_proxy|alternative_proxy|constructed|e_NFC|ln_e_NFC = log(e_NFC)|S10 stages direct NIPA compensation and gross-value-added lines and registers unadjusted wage shares as the preferred first-pass baseline.|||
|IPP_stock|frontier_conditioner_IPP|frontier_conditioner|constructed|NFC__IPP__net_stock_current_cost|IPP_stock = S10 NFC IPP net stock|S10 stages NFC IPP and NFC total fixed-assets current-cost net stocks; IPP is a frontier conditioner and is excluded from K_cap.|||
|IPP_growth|frontier_conditioner_IPP|frontier_conditioner|constructed_with_missing_edges|IPP_stock|IPP_growth = Delta log(IPP_stock)|S10 stages NFC IPP and NFC total fixed-assets current-cost net stocks; IPP is a frontier conditioner and is excluded from K_cap.|||
|IPP_share_total_fixed_assets|frontier_conditioner_IPP|frontier_conditioner|constructed|IPP_stock / NFC__TOTAL__net_stock_current_cost|IPP_share_total_fixed_assets = IPP_stock / NFC total fixed assets|S10 stages NFC IPP and NFC total fixed-assets current-cost net stocks; IPP is a frontier conditioner and is excluded from K_cap.|||
|IPP_share_capital_plus_IPP|frontier_conditioner_IPP|frontier_conditioner|constructed|IPP_stock / (K_cap + IPP_stock)|IPP_share_capital_plus_IPP = IPP_stock / (K_cap + IPP_stock)|S10 stages NFC IPP and NFC total fixed-assets current-cost net stocks; IPP is a frontier conditioner and is excluded from K_cap.|||
|IPP_to_Kcap|frontier_conditioner_IPP|frontier_conditioner|constructed|IPP_stock / K_cap|IPP_to_Kcap = IPP_stock / K_cap|S10 stages NFC IPP and NFC total fixed-assets current-cost net stocks; IPP is a frontier conditioner and is excluded from K_cap.|||
|GOV_TRANS_stock|frontier_conditioner_GOV_TRANS|frontier_conditioner|constructed|GOV_TRANS__TRANSPORTATION_STRUCTURES__net_stock_current_cost + GOV_TRANS__HIGHWAYS_STREETS__net_stock_current_cost|GOV_TRANS_stock = transportation structures + highways/streets|S10 stages transportation structures and highways/streets as separate GOV_TRANS current-cost net-stock components and frontier conditioners.|||
|GOV_TRANS_growth|frontier_conditioner_GOV_TRANS|frontier_conditioner|constructed_with_missing_edges|GOV_TRANS_stock|GOV_TRANS_growth = Delta log(GOV_TRANS_stock)|S10 stages transportation structures and highways/streets as separate GOV_TRANS current-cost net-stock components and frontier conditioners.|||
|GOV_TRANS_to_Kcap|frontier_conditioner_GOV_TRANS|frontier_conditioner|constructed|GOV_TRANS_stock / K_cap|GOV_TRANS_to_Kcap = GOV_TRANS_stock / K_cap|S10 stages transportation structures and highways/streets as separate GOV_TRANS current-cost net-stock components and frontier conditioners.|||
|GOV_TRANS_to_NRC|frontier_conditioner_GOV_TRANS|frontier_conditioner|constructed|GOV_TRANS_stock / K_NRC|GOV_TRANS_to_NRC = GOV_TRANS_stock / K_NRC|S10 stages transportation structures and highways/streets as separate GOV_TRANS current-cost net-stock components and frontier conditioners.|||
|GOV_TRANS_to_ME|frontier_conditioner_GOV_TRANS|frontier_conditioner|constructed|GOV_TRANS_stock / K_ME|GOV_TRANS_to_ME = GOV_TRANS_stock / K_ME|S10 stages transportation structures and highways/streets as separate GOV_TRANS current-cost net-stock components and frontier conditioners.|||
