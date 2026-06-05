# S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B

## 1. Executive read
Run timestamp: 2026-06-03 16:03:00 -04.
Input dataset: `C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/US/us_s20_admissibility_panel.csv`.
This pass classifies the stochastic order of variables used by the current S32 B1/E2B comparison. It does not choose the winning model.
Classification counts: ambiguous_hold=3; break_sensitive=5; deterministic_sensitive=36; I0_preferred=4; I1_preferred=18; I2_risk=25; insufficient_observations=14.
S32 implication counts: compatible_but_document_mixed_order=41; compatible_with_S32=22; hold_for_review=3; insufficient_evidence=14; not_compatible_without_redesign=25.

## 2. Variable construction ledger
| variable_id | source_type | source_columns | construction_formula | used_in_spec | test_priority |
|---|---|---|---|---|---|
| y_t | raw_column | y_t | input column y_t | both | required |
| k_t | raw_column | k_t | input column k_t | B1 | required |
| omega_t | raw_column | omega_t | input column omega_t | both | required |
| omega_k_t | constructed_regressor | omega_t \| k_t | omega_t * k_t | B1 | required |
| k_NRC_t | constructed_regressor | K_NRC_gross_real | log(K_NRC_gross_real) | E2B | required |
| k_ME_t | constructed_regressor | K_ME_gross_real | log(K_ME_gross_real) | support_diagnostic | support |
| m_ME_NRC_t | derived_gap | K_ME_gross_real \| K_NRC_gross_real | log(K_ME_gross_real) - log(K_NRC_gross_real) | E2B | required |
| omega_m_ME_NRC_t | constructed_regressor | omega_t \| K_ME_gross_real \| K_NRC_gross_real | omega_t * (log(K_ME_gross_real) - log(K_NRC_gross_real)) | E2B | required |
| pK_relative_ME_NRC | optional_support | pK_relative_ME_NRC | input column pK_relative_ME_NRC | support_diagnostic | support |
| s_t | optional_support | s_t | input column s_t | support_diagnostic | support |
| phi_t | optional_support | phi_t | input column phi_t | support_diagnostic | support |
| s_t_proxy | optional_support | s_t_proxy | input column s_t_proxy | support_diagnostic | support |
| phi_t_proxy | optional_support | phi_t_proxy | input column phi_t_proxy | support_diagnostic | support |
| s_t_proxy_cc | optional_support | s_t_proxy_cc | input column s_t_proxy_cc | support_diagnostic | support |
| phi_t_proxy_cc | optional_support | phi_t_proxy_cc | input column phi_t_proxy_cc | support_diagnostic | support |

## 3. Compact classification table
| variable_id | window_id | n_obs | classification | confidence | s32_implication | human_review_flag |
|---|---|---|---|---|---|---|
| y_t | full_long_sample | 96.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| k_t | full_long_sample | 96.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| omega_t | full_long_sample | 96.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| omega_k_t | full_long_sample | 96.000 | break_sensitive | low | compatible_but_document_mixed_order | TRUE |
| k_NRC_t | full_long_sample | 96.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| k_ME_t | full_long_sample | 96.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| m_ME_NRC_t | full_long_sample | 96.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| omega_m_ME_NRC_t | full_long_sample | 96.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| pK_relative_ME_NRC | full_long_sample | 96.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| s_t | full_long_sample | 0.000 | insufficient_observations | low | insufficient_evidence | TRUE |
| phi_t | full_long_sample | 0.000 | insufficient_observations | low | insufficient_evidence | TRUE |
| s_t_proxy | full_long_sample | 96.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| phi_t_proxy | full_long_sample | 96.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| s_t_proxy_cc | full_long_sample | 96.000 | break_sensitive | low | compatible_but_document_mixed_order | TRUE |
| phi_t_proxy_cc | full_long_sample | 96.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| y_t | pre_1974 | 45.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| k_t | pre_1974 | 45.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| omega_t | pre_1974 | 45.000 | I0_preferred | high | compatible_with_S32 | FALSE |
| omega_k_t | pre_1974 | 45.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| k_NRC_t | pre_1974 | 45.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| k_ME_t | pre_1974 | 45.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| m_ME_NRC_t | pre_1974 | 45.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| omega_m_ME_NRC_t | pre_1974 | 45.000 | break_sensitive | low | compatible_but_document_mixed_order | TRUE |
| pK_relative_ME_NRC | pre_1974 | 45.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| s_t | pre_1974 | 0.000 | insufficient_observations | low | insufficient_evidence | TRUE |
| phi_t | pre_1974 | 0.000 | insufficient_observations | low | insufficient_evidence | TRUE |
| s_t_proxy | pre_1974 | 45.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| phi_t_proxy | pre_1974 | 45.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| s_t_proxy_cc | pre_1974 | 45.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| phi_t_proxy_cc | pre_1974 | 45.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| y_t | post_1973 | 51.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| k_t | post_1973 | 51.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| omega_t | post_1973 | 51.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| omega_k_t | post_1973 | 51.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| k_NRC_t | post_1973 | 51.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| k_ME_t | post_1973 | 51.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| m_ME_NRC_t | post_1973 | 51.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| omega_m_ME_NRC_t | post_1973 | 51.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| pK_relative_ME_NRC | post_1973 | 51.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| s_t | post_1973 | 0.000 | insufficient_observations | low | insufficient_evidence | TRUE |
| phi_t | post_1973 | 0.000 | insufficient_observations | low | insufficient_evidence | TRUE |
| s_t_proxy | post_1973 | 51.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| phi_t_proxy | post_1973 | 51.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| s_t_proxy_cc | post_1973 | 51.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| phi_t_proxy_cc | post_1973 | 51.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| y_t | fordist_core | 29.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| k_t | fordist_core | 29.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| omega_t | fordist_core | 29.000 | I0_preferred | high | compatible_with_S32 | FALSE |
| omega_k_t | fordist_core | 29.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| k_NRC_t | fordist_core | 29.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| k_ME_t | fordist_core | 29.000 | ambiguous_hold | low | hold_for_review | TRUE |
| m_ME_NRC_t | fordist_core | 29.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| omega_m_ME_NRC_t | fordist_core | 29.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| pK_relative_ME_NRC | fordist_core | 29.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| s_t | fordist_core | 0.000 | insufficient_observations | low | insufficient_evidence | TRUE |
| phi_t | fordist_core | 0.000 | insufficient_observations | low | insufficient_evidence | TRUE |
| s_t_proxy | fordist_core | 29.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| phi_t_proxy | fordist_core | 29.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| s_t_proxy_cc | fordist_core | 29.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| phi_t_proxy_cc | fordist_core | 29.000 | break_sensitive | low | compatible_but_document_mixed_order | TRUE |
| y_t | bridge_1940_1978 | 39.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| k_t | bridge_1940_1978 | 39.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| omega_t | bridge_1940_1978 | 39.000 | I0_preferred | high | compatible_with_S32 | FALSE |
| omega_k_t | bridge_1940_1978 | 39.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| k_NRC_t | bridge_1940_1978 | 39.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| k_ME_t | bridge_1940_1978 | 39.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| m_ME_NRC_t | bridge_1940_1978 | 39.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| omega_m_ME_NRC_t | bridge_1940_1978 | 39.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| pK_relative_ME_NRC | bridge_1940_1978 | 39.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| s_t | bridge_1940_1978 | 0.000 | insufficient_observations | low | insufficient_evidence | TRUE |
| phi_t | bridge_1940_1978 | 0.000 | insufficient_observations | low | insufficient_evidence | TRUE |
| s_t_proxy | bridge_1940_1978 | 39.000 | I2_risk | low | not_compatible_without_redesign | TRUE |
| phi_t_proxy | bridge_1940_1978 | 39.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| s_t_proxy_cc | bridge_1940_1978 | 39.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| phi_t_proxy_cc | bridge_1940_1978 | 39.000 | I1_preferred | high | compatible_with_S32 | FALSE |
| y_t | pre_1974_alt_1940_1973 | 34.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| k_t | pre_1974_alt_1940_1973 | 34.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| omega_t | pre_1974_alt_1940_1973 | 34.000 | I0_preferred | high | compatible_with_S32 | FALSE |
| omega_k_t | pre_1974_alt_1940_1973 | 34.000 | deterministic_sensitive | low | compatible_but_document_mixed_order | TRUE |
| k_NRC_t | pre_1974_alt_1940_1973 | 34.000 | I2_risk | low | not_compatible_without_redesign | TRUE |

## 4. B1 precondition assessment
B1 is most compatible with the current S32 cointegrating-regression design if y_t and k_t behave as I(1), omega_t behaves as I(0) or bounded-persistent, and the constructed interaction omega_t*k_t behaves as an admissible I(1)-type long-run regressor.
If omega is I(1), B1 becomes more fragile because omega_t*k_t is no longer a clean distributive modulation of an I(1) capital trend.
If omega*k is ambiguous or I2-risk, B1 coefficient significance cannot be interpreted as sufficient long-run evidence without further redesign.
| variable_id | window_id | classification | confidence | s32_implication | notes |
|---|---|---|---|---|---|
| y_t | full_long_sample | I1_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | full_long_sample | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| omega_t | full_long_sample | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| omega_k_t | full_long_sample | break_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| y_t | pre_1974 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | pre_1974 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_t | pre_1974 | I0_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift ; sensitivity_classification=I0_preferred |
| omega_k_t | pre_1974 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| y_t | post_1973 | I1_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | post_1973 | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| omega_t | post_1973 | I1_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; omega_t I(1) makes B1 interaction interpretation more fragile |
| omega_k_t | post_1973 | I1_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| y_t | fordist_core | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | fordist_core | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_t | fordist_core | I0_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift ; sensitivity_classification=I0_preferred |
| omega_k_t | fordist_core | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| y_t | bridge_1940_1978 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | bridge_1940_1978 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_t | bridge_1940_1978 | I0_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift ; sensitivity_classification=I0_preferred |
| omega_k_t | bridge_1940_1978 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| y_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_t | pre_1974_alt_1940_1973 | I0_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift ; sensitivity_classification=I0_preferred |
| omega_k_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| y_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_t | pre_1974_alt_1947_1974 | ambiguous_hold | low | hold_for_review | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| omega_k_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |

## 5. E2B precondition assessment
E2B is most compatible with the current S32 design if y_t and k_NRC_t behave as I(1), while m_t and omega_t*m_t have a defensible order classification compatible with the intended NRC-envelope / distribution-conditioned mechanization-bias interpretation.
If m_t is I(0), E2B becomes a mixed I(1)/I(0) specification rather than a clean all-I(1) cointegrating regression. This is not automatically invalid, but it must be documented.
If omega*m is ambiguous or I2-risk, E2B's mechanization-bias channel should be held for review and not promoted mechanically.
| variable_id | window_id | classification | confidence | s32_implication | notes |
|---|---|---|---|---|---|
| y_t | full_long_sample | I1_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_NRC_t | full_long_sample | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | full_long_sample | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | full_long_sample | I1_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| y_t | pre_1974 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_NRC_t | pre_1974 | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | pre_1974 | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | pre_1974 | break_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| y_t | post_1973 | I1_preferred | high | compatible_with_S32 | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_NRC_t | post_1973 | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | post_1973 | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | post_1973 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| y_t | fordist_core | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_NRC_t | fordist_core | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | fordist_core | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | fordist_core | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; constructed interaction needs human review before coefficient interpretation |
| y_t | bridge_1940_1978 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_NRC_t | bridge_1940_1978 | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | bridge_1940_1978 | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | bridge_1940_1978 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| y_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_NRC_t | pre_1974_alt_1940_1973 | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | pre_1974_alt_1940_1973 | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| y_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_NRC_t | pre_1974_alt_1947_1974 | I2_risk | low | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| omega_m_ME_NRC_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; constructed interaction needs human review before coefficient interpretation |

## 6. Constructed-regressor risk assessment
| variable_id | window_id | classification | confidence | human_review_flag | notes |
|---|---|---|---|---|---|
| omega_k_t | full_long_sample | break_sensitive | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| k_NRC_t | full_long_sample | I2_risk | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | full_long_sample | I1_preferred | high | FALSE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| m_ME_NRC_t | full_long_sample | I2_risk | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | full_long_sample | I1_preferred | high | FALSE | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| omega_k_t | pre_1974 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_NRC_t | pre_1974 | I2_risk | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | pre_1974 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| m_ME_NRC_t | pre_1974 | I2_risk | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | pre_1974 | break_sensitive | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| omega_k_t | post_1973 | I1_preferred | high | FALSE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_NRC_t | post_1973 | I2_risk | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | post_1973 | I2_risk | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | post_1973 | I2_risk | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | post_1973 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| omega_k_t | fordist_core | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_NRC_t | fordist_core | I2_risk | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | fordist_core | ambiguous_hold | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=ambiguous_hold |
| m_ME_NRC_t | fordist_core | I2_risk | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | fordist_core | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; constructed interaction needs human review before coefficient interpretation |
| omega_k_t | bridge_1940_1978 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_NRC_t | bridge_1940_1978 | I2_risk | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | bridge_1940_1978 | I2_risk | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | bridge_1940_1978 | I2_risk | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | bridge_1940_1978 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| omega_k_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_NRC_t | pre_1974_alt_1940_1973 | I2_risk | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | pre_1974_alt_1940_1973 | I2_risk | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | pre_1974_alt_1940_1973 | I2_risk | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| omega_k_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_NRC_t | pre_1974_alt_1947_1974 | I2_risk | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| m_ME_NRC_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| omega_m_ME_NRC_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | TRUE | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; constructed interaction needs human review before coefficient interpretation |

## 7. Deterministic-sensitivity assessment
| variable_id | window_id | classification | confidence | notes |
|---|---|---|---|---|
| omega_t | full_long_sample | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| phi_t_proxy_cc | full_long_sample | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| y_t | pre_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | pre_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_k_t | pre_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_ME_t | pre_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| phi_t_proxy | pre_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| omega_m_ME_NRC_t | post_1973 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| phi_t_proxy | post_1973 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| phi_t_proxy_cc | post_1973 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| y_t | fordist_core | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | fordist_core | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_k_t | fordist_core | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| omega_m_ME_NRC_t | fordist_core | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; constructed interaction needs human review before coefficient interpretation |
| pK_relative_ME_NRC | fordist_core | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| s_t_proxy_cc | fordist_core | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| y_t | bridge_1940_1978 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | bridge_1940_1978 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_k_t | bridge_1940_1978 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| omega_m_ME_NRC_t | bridge_1940_1978 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| pK_relative_ME_NRC | bridge_1940_1978 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| s_t_proxy_cc | bridge_1940_1978 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| y_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_k_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| omega_m_ME_NRC_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| phi_t_proxy | pre_1974_alt_1940_1973 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| s_t_proxy_cc | pre_1974_alt_1940_1973 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| y_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_k_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_ME_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| m_ME_NRC_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| omega_m_ME_NRC_t | pre_1974_alt_1947_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; constructed interaction needs human review before coefficient interpretation |
| pK_relative_ME_NRC | pre_1974_alt_1947_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| s_t_proxy | pre_1974_alt_1947_1974 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |


## 8. Break-sensitivity assessment
Zivot-Andrews one-break diagnostics were run with `urca::ur.za(model = "both", lag = 2)` where observations were sufficient.
| variable_id | window_id | classification | confidence | notes |
|---|---|---|---|---|
| omega_t | full_long_sample | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| omega_k_t | full_long_sample | break_sensitive | low | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| s_t_proxy_cc | full_long_sample | break_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| phi_t_proxy_cc | full_long_sample | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| omega_m_ME_NRC_t | pre_1974 | break_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| phi_t_proxy_cc | fordist_core | break_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| omega_m_ME_NRC_t | bridge_1940_1978 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| s_t_proxy_cc | bridge_1940_1978 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| omega_m_ME_NRC_t | pre_1974_alt_1940_1973 | deterministic_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| phi_t_proxy_cc | pre_1974_alt_1947_1974 | break_sensitive | low | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |


## 9. Implications for S32 interpretation
This precheck is an input to human adjudication. It does not reinterpret S32 residual ADF gates as formal cointegration tests and does not mechanically reject a specification from one ambiguous variable.
| variable_id | window_id | classification | s32_implication | notes |
|---|---|---|---|---|
| k_t | full_long_sample | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| omega_t | full_long_sample | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| omega_k_t | full_long_sample | break_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| k_NRC_t | full_long_sample | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | full_long_sample | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| s_t | full_long_sample | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| phi_t | full_long_sample | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| s_t_proxy | full_long_sample | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| s_t_proxy_cc | full_long_sample | break_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| phi_t_proxy_cc | full_long_sample | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| y_t | pre_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | pre_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_k_t | pre_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_NRC_t | pre_1974 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | pre_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| m_ME_NRC_t | pre_1974 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | pre_1974 | break_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| s_t | pre_1974 | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| phi_t | pre_1974 | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| s_t_proxy | pre_1974 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| phi_t_proxy | pre_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| k_t | post_1973 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_NRC_t | post_1973 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | post_1973 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | post_1973 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | post_1973 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| s_t | post_1973 | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| phi_t | post_1973 | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| s_t_proxy | post_1973 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| phi_t_proxy | post_1973 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| phi_t_proxy_cc | post_1973 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| y_t | fordist_core | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | fordist_core | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_k_t | fordist_core | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_NRC_t | fordist_core | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | fordist_core | ambiguous_hold | hold_for_review | primary_deterministic_spec=drift_trend ; sensitivity_classification=ambiguous_hold |
| m_ME_NRC_t | fordist_core | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | fordist_core | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; constructed interaction needs human review before coefficient interpretation |
| pK_relative_ME_NRC | fordist_core | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| s_t | fordist_core | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| phi_t | fordist_core | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| s_t_proxy | fordist_core | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| s_t_proxy_cc | fordist_core | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| phi_t_proxy_cc | fordist_core | break_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| y_t | bridge_1940_1978 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | bridge_1940_1978 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_k_t | bridge_1940_1978 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_NRC_t | bridge_1940_1978 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | bridge_1940_1978 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | bridge_1940_1978 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | bridge_1940_1978 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| pK_relative_ME_NRC | bridge_1940_1978 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| s_t | bridge_1940_1978 | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| phi_t | bridge_1940_1978 | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| s_t_proxy | bridge_1940_1978 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| s_t_proxy_cc | bridge_1940_1978 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| y_t | pre_1974_alt_1940_1973 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | pre_1974_alt_1940_1973 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_k_t | pre_1974_alt_1940_1973 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_NRC_t | pre_1974_alt_1940_1973 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | pre_1974_alt_1940_1973 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| m_ME_NRC_t | pre_1974_alt_1940_1973 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| omega_m_ME_NRC_t | pre_1974_alt_1940_1973 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation ; Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct |
| pK_relative_ME_NRC | pre_1974_alt_1940_1973 | ambiguous_hold | hold_for_review | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| s_t | pre_1974_alt_1940_1973 | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| phi_t | pre_1974_alt_1940_1973 | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| s_t_proxy | pre_1974_alt_1940_1973 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift ; sensitivity_classification=I2_risk |
| phi_t_proxy | pre_1974_alt_1940_1973 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| s_t_proxy_cc | pre_1974_alt_1940_1973 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| y_t | pre_1974_alt_1947_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| k_t | pre_1974_alt_1947_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| omega_t | pre_1974_alt_1947_1974 | ambiguous_hold | hold_for_review | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| omega_k_t | pre_1974_alt_1947_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred ; constructed interaction needs human review before coefficient interpretation |
| k_NRC_t | pre_1974_alt_1947_1974 | I2_risk | not_compatible_without_redesign | primary_deterministic_spec=drift_trend ; sensitivity_classification=I2_risk |
| k_ME_t | pre_1974_alt_1947_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift_trend ; sensitivity_classification=I1_preferred |
| m_ME_NRC_t | pre_1974_alt_1947_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold |
| omega_m_ME_NRC_t | pre_1974_alt_1947_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=ambiguous_hold ; constructed interaction needs human review before coefficient interpretation |
| pK_relative_ME_NRC | pre_1974_alt_1947_1974 | deterministic_sensitive | compatible_but_document_mixed_order | primary_deterministic_spec=drift ; sensitivity_classification=I1_preferred |
| s_t | pre_1974_alt_1947_1974 | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |
| phi_t | pre_1974_alt_1947_1974 | insufficient_observations | insufficient_evidence | primary_deterministic_spec=drift ; sensitivity_classification=test_failed |

## 10. Explicit non-selection statement
This pass does not choose between B1 and E2B. S31 VIF outputs are left untouched. S32 model-choice outputs are left untouched. S40 remains parked.
