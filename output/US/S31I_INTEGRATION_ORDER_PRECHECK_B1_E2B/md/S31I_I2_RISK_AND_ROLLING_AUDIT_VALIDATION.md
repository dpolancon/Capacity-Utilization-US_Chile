# S31I I2-Risk and Rolling Audit Validation

| check | pass | evidence |
|---|---|---|
| Existing S31I outputs were found | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B |
| Existing classification CSV was read | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_integration_order_classification.csv |
| Existing tests-long CSV was read | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_integration_order_tests_long.csv |
| Existing construction ledger was read | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_variable_construction_ledger.csv |
| All target variables were audited | TRUE | k_t \| k_NRC_t \| k_ME_t \| m_ME_NRC_t \| omega_k_t \| omega_m_ME_NRC_t \| y_t \| omega_t \| pK_relative_ME_NRC |
| All original S31I windows were attempted | TRUE | full_long_sample \| pre_1974 \| post_1973 \| fordist_core \| bridge_1940_1978 \| pre_1974_alt_1940_1973 \| pre_1974_alt_1947_1974 |
| Rolling-window families were attempted | TRUE | pre_1974_expanding \| post_1973_expanding \| fixed_width_30_pre_1974 \| fixed_width_30_post_1973 \| fixed_width_35_pre_1974 \| fixed_width_35_post_1973 \| fixed_width_40_pre_1974 \| fixed_width_40_post_1973 |
| Failed/skipped test handling was inspected | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_i2_risk_rule_diagnostics.csv |
| Rule diagnostics were written | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_i2_risk_rule_diagnostics.csv |
| Rolling-window outputs were written | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_rolling_integration_order_windows.csv \| C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_rolling_integration_order_stability.csv |
| Original S31I outputs were not overwritten | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_integration_order_tests_long.csv \| C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_integration_order_classification.csv \| C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_variable_construction_ledger.csv \| C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/md/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B.md \| C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/md/S31I_VALIDATION_REPORT.md |
| S31 outputs were not overwritten | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31_estimation_tables_tex \| C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31_model_choice_vif_screen |
| S32 outputs were not overwritten | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S32_B1_E2B_MODEL_CHOICE_REVIEW |
| S40 was not run | TRUE | No output/US/S40 folder present |

Validation status: PASS.
