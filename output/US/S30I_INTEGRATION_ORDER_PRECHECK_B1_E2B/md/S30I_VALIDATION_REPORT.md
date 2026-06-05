# S30I Validation Report

Run tag: `S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B`.
Run timestamp: 2026-06-03 16:03:00 -04.

| check | pass | evidence |
|---|---|---|
| Output folders exist | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B |
| Required CSVs were written | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S30I_integration_order_tests_long.csv \| C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S30I_integration_order_classification.csv \| C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S30I_variable_construction_ledger.csv |
| Required markdown files were written | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B/md/S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B.md \| C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B/md/S30I_VALIDATION_REPORT.md |
| All tested variables have a construction-ledger entry | TRUE | y_t \| k_t \| omega_t \| omega_k_t \| k_NRC_t \| k_ME_t \| m_ME_NRC_t \| omega_m_ME_NRC_t \| pK_relative_ME_NRC \| s_t \| phi_t \| s_t_proxy \| phi_t_proxy \| s_t_proxy_cc \| phi_t_proxy_cc |
| All B1/E2B constructed regressors were tested directly | TRUE | omega_k_t \| k_NRC_t \| k_ME_t \| m_ME_NRC_t \| omega_m_ME_NRC_t |
| All main windows were attempted | TRUE | full_long_sample \| pre_1974 \| post_1973 \| fordist_core \| bridge_1940_1978 \| pre_1974_alt_1940_1973 \| pre_1974_alt_1947_1974 |
| Missing columns are reported explicitly | TRUE | s_t \| phi_t |
| Failed or skipped tests are reported explicitly | TRUE | ur.pp does not support deterministic_spec: none \| ur.kpss does not support deterministic_spec: none \| ur.ers does not support deterministic_spec: none \| insufficient observations for integration-order precheck \| insufficient observations for one-break diagnostic |
| No S31 outputs were overwritten | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31_estimation_tables_tex \| C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S31_model_choice_vif_screen |
| No S32 model-choice outputs were overwritten | TRUE | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S32_B1_E2B_MODEL_CHOICE_REVIEW |
| No S40 reconstruction was run | TRUE | No output/US/S40 folder present |

## Missing-column audit
| column_name | present_in_input | nonmissing_obs | notes |
|---|---|---|---|
| s_t | TRUE | 0.000 | present but zero nonmissing observations |
| phi_t | TRUE | 0.000 | present but zero nonmissing observations |

## Failed or skipped tests
| variable_id | window_id | transform | test_name | deterministic_spec | error_message |
|---|---|---|---|---|---|
| y_t | full_long_sample | first_difference | Phillips-Perron | none | ur.pp does not support deterministic_spec: none |
| y_t | full_long_sample | first_difference | KPSS | none | ur.kpss does not support deterministic_spec: none |
| y_t | full_long_sample | first_difference | DF-GLS_ERS | none | ur.ers does not support deterministic_spec: none |
| k_t | full_long_sample | first_difference | Phillips-Perron | none | ur.pp does not support deterministic_spec: none |
| k_t | full_long_sample | first_difference | KPSS | none | ur.kpss does not support deterministic_spec: none |
| k_t | full_long_sample | first_difference | DF-GLS_ERS | none | ur.ers does not support deterministic_spec: none |
| omega_t | full_long_sample | first_difference | Phillips-Perron | none | ur.pp does not support deterministic_spec: none |
| omega_t | full_long_sample | first_difference | KPSS | none | ur.kpss does not support deterministic_spec: none |
| omega_t | full_long_sample | first_difference | DF-GLS_ERS | none | ur.ers does not support deterministic_spec: none |
| omega_k_t | full_long_sample | first_difference | Phillips-Perron | none | ur.pp does not support deterministic_spec: none |
| omega_k_t | full_long_sample | first_difference | KPSS | none | ur.kpss does not support deterministic_spec: none |
| omega_k_t | full_long_sample | first_difference | DF-GLS_ERS | none | ur.ers does not support deterministic_spec: none |
| k_NRC_t | full_long_sample | first_difference | Phillips-Perron | none | ur.pp does not support deterministic_spec: none |
| k_NRC_t | full_long_sample | first_difference | KPSS | none | ur.kpss does not support deterministic_spec: none |
| k_NRC_t | full_long_sample | first_difference | DF-GLS_ERS | none | ur.ers does not support deterministic_spec: none |
| k_ME_t | full_long_sample | first_difference | Phillips-Perron | none | ur.pp does not support deterministic_spec: none |
| k_ME_t | full_long_sample | first_difference | KPSS | none | ur.kpss does not support deterministic_spec: none |
| k_ME_t | full_long_sample | first_difference | DF-GLS_ERS | none | ur.ers does not support deterministic_spec: none |
| m_ME_NRC_t | full_long_sample | first_difference | Phillips-Perron | none | ur.pp does not support deterministic_spec: none |
| m_ME_NRC_t | full_long_sample | first_difference | KPSS | none | ur.kpss does not support deterministic_spec: none |
| m_ME_NRC_t | full_long_sample | first_difference | DF-GLS_ERS | none | ur.ers does not support deterministic_spec: none |
| omega_m_ME_NRC_t | full_long_sample | first_difference | Phillips-Perron | none | ur.pp does not support deterministic_spec: none |
| omega_m_ME_NRC_t | full_long_sample | first_difference | KPSS | none | ur.kpss does not support deterministic_spec: none |
| omega_m_ME_NRC_t | full_long_sample | first_difference | DF-GLS_ERS | none | ur.ers does not support deterministic_spec: none |
| pK_relative_ME_NRC | full_long_sample | first_difference | Phillips-Perron | none | ur.pp does not support deterministic_spec: none |
| pK_relative_ME_NRC | full_long_sample | first_difference | KPSS | none | ur.kpss does not support deterministic_spec: none |
| pK_relative_ME_NRC | full_long_sample | first_difference | DF-GLS_ERS | none | ur.ers does not support deterministic_spec: none |
| s_t | full_long_sample | level | ADF | drift | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | ADF | drift_trend | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | ADF | none | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | Phillips-Perron | drift | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | Phillips-Perron | drift_trend | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | Phillips-Perron | none | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | KPSS | drift | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | KPSS | drift_trend | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | KPSS | none | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | DF-GLS_ERS | drift | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | DF-GLS_ERS | drift_trend | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | DF-GLS_ERS | none | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | ADF | drift | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | ADF | drift_trend | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | ADF | none | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | Phillips-Perron | drift | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | Phillips-Perron | drift_trend | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | Phillips-Perron | none | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | KPSS | drift | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | KPSS | drift_trend | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | KPSS | none | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | DF-GLS_ERS | drift | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | DF-GLS_ERS | drift_trend | insufficient observations for integration-order precheck |
| s_t | full_long_sample | first_difference | DF-GLS_ERS | none | insufficient observations for integration-order precheck |
| s_t | full_long_sample | level | Zivot-Andrews | break_both | insufficient observations for one-break diagnostic |
| phi_t | full_long_sample | level | ADF | drift | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | ADF | drift_trend | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | ADF | none | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | Phillips-Perron | drift | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | Phillips-Perron | drift_trend | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | Phillips-Perron | none | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | KPSS | drift | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | KPSS | drift_trend | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | KPSS | none | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | DF-GLS_ERS | drift | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | DF-GLS_ERS | drift_trend | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | DF-GLS_ERS | none | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | ADF | drift | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | ADF | drift_trend | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | ADF | none | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | Phillips-Perron | drift | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | Phillips-Perron | drift_trend | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | Phillips-Perron | none | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | KPSS | drift | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | KPSS | drift_trend | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | KPSS | none | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | DF-GLS_ERS | drift | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | DF-GLS_ERS | drift_trend | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | first_difference | DF-GLS_ERS | none | insufficient observations for integration-order precheck |
| phi_t | full_long_sample | level | Zivot-Andrews | break_both | insufficient observations for one-break diagnostic |
| s_t_proxy | full_long_sample | first_difference | Phillips-Perron | none | ur.pp does not support deterministic_spec: none |
| s_t_proxy | full_long_sample | first_difference | KPSS | none | ur.kpss does not support deterministic_spec: none |
| s_t_proxy | full_long_sample | first_difference | DF-GLS_ERS | none | ur.ers does not support deterministic_spec: none |

Validation status: PASS.
