# S31I I2-Risk Audit Validation

| check | pass | evidence |
|---|---|---|
| Existing S31I outputs found | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B |
| Classification CSV read | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_integration_order_classification.csv |
| Tests-long CSV read | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_integration_order_tests_long.csv |
| Construction ledger read | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_variable_construction_ledger.csv |
| All target variables audited | TRUE | k_t \| k_NRC_t \| k_ME_t \| m_ME_NRC_t \| omega_k_t \| omega_m_ME_NRC_t \| y_t \| omega_t \| pK_relative_ME_NRC |
| All original S31I windows attempted | TRUE | full_long_sample \| pre_1974 \| post_1973 \| fordist_core \| bridge_1940_1978 \| pre_1974_alt_1940_1973 \| pre_1974_alt_1947_1974 |
| Failed/skipped handling inspected | TRUE | See S31I_i2_risk_rule_diagnostics.csv |
| Rule diagnostics written | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S31I_i2_risk_rule_diagnostics.csv |

Validation status: PASS.
