# S31I I2-Risk Audit

## 1. Executive read
Run tag: `S31I_I2_RISK_AND_ROLLING_AUDIT_B1_E2B`.
Target I2-risk calls audited: 18.
Audit labels among I2-risk calls: genuine_I2_risk=14; mixed_test_evidence=1; short_window_fragility=3.
## Classification rule bug check
No target I2-risk classification was driven by failed or unsupported primary first-difference rows.
Exact code location inspected: `codes/US_S31I_integration_order_precheck_B1_E2B.R:435-480`.
Unsupported `none` rows exist for PP/KPSS/ERS, but they are outside the original primary classification evidence for the target I2-risk calls.
No corrected classification table was necessary.

## 2. Why the audit was run
The original S31I pass produced I2-risk, deterministic-sensitive, and fragile classifications. This audit separates genuine first-difference nonstationarity from deterministic sensitivity, short-window weakness, failed-test handling, and mixed ADF/PP/KPSS evidence.

## 3. Target variables and original S31I windows
| variable_id | window_id | n_obs | original_classification | audit_read | recommended_interpretation |
|---|---|---|---|---|---|
| y_t | full_long_sample | 96.000 | I1_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_t | full_long_sample | 96.000 | I2_risk | mixed_test_evidence | Hold for review because ADF/PP/KPSS evidence conflicts. |
| omega_t | full_long_sample | 96.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_k_t | full_long_sample | 96.000 | break_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_NRC_t | full_long_sample | 96.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| k_ME_t | full_long_sample | 96.000 | I1_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| m_ME_NRC_t | full_long_sample | 96.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| omega_m_ME_NRC_t | full_long_sample | 96.000 | I1_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| pK_relative_ME_NRC | full_long_sample | 96.000 | I1_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| y_t | pre_1974 | 45.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_t | pre_1974 | 45.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_t | pre_1974 | 45.000 | I0_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_k_t | pre_1974 | 45.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_NRC_t | pre_1974 | 45.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| k_ME_t | pre_1974 | 45.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| m_ME_NRC_t | pre_1974 | 45.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| omega_m_ME_NRC_t | pre_1974 | 45.000 | break_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| pK_relative_ME_NRC | pre_1974 | 45.000 | I1_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| y_t | post_1973 | 51.000 | I1_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_t | post_1973 | 51.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| omega_t | post_1973 | 51.000 | I1_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_k_t | post_1973 | 51.000 | I1_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_NRC_t | post_1973 | 51.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| k_ME_t | post_1973 | 51.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| m_ME_NRC_t | post_1973 | 51.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| omega_m_ME_NRC_t | post_1973 | 51.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| pK_relative_ME_NRC | post_1973 | 51.000 | I1_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| y_t | fordist_core | 29.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_t | fordist_core | 29.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_t | fordist_core | 29.000 | I0_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_k_t | fordist_core | 29.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_NRC_t | fordist_core | 29.000 | I2_risk | short_window_fragility | Hold for review; result is under the preferred 30-observation threshold. |
| k_ME_t | fordist_core | 29.000 | ambiguous_hold | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| m_ME_NRC_t | fordist_core | 29.000 | I2_risk | short_window_fragility | Hold for review; result is under the preferred 30-observation threshold. |
| omega_m_ME_NRC_t | fordist_core | 29.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| pK_relative_ME_NRC | fordist_core | 29.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| y_t | bridge_1940_1978 | 39.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_t | bridge_1940_1978 | 39.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_t | bridge_1940_1978 | 39.000 | I0_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_k_t | bridge_1940_1978 | 39.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_NRC_t | bridge_1940_1978 | 39.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| k_ME_t | bridge_1940_1978 | 39.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| m_ME_NRC_t | bridge_1940_1978 | 39.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| omega_m_ME_NRC_t | bridge_1940_1978 | 39.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| pK_relative_ME_NRC | bridge_1940_1978 | 39.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| y_t | pre_1974_alt_1940_1973 | 34.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_t | pre_1974_alt_1940_1973 | 34.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_t | pre_1974_alt_1940_1973 | 34.000 | I0_preferred | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_k_t | pre_1974_alt_1940_1973 | 34.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_NRC_t | pre_1974_alt_1940_1973 | 34.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| k_ME_t | pre_1974_alt_1940_1973 | 34.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| m_ME_NRC_t | pre_1974_alt_1940_1973 | 34.000 | I2_risk | genuine_I2_risk | Treat as substantive I2-risk until redesigned or externally adjudicated. |
| omega_m_ME_NRC_t | pre_1974_alt_1940_1973 | 34.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| pK_relative_ME_NRC | pre_1974_alt_1940_1973 | 34.000 | ambiguous_hold | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| y_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_t | pre_1974_alt_1947_1974 | 28.000 | ambiguous_hold | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_k_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| k_NRC_t | pre_1974_alt_1947_1974 | 28.000 | I2_risk | short_window_fragility | Hold for review; result is under the preferred 30-observation threshold. |
| k_ME_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| m_ME_NRC_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| omega_m_ME_NRC_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |
| pK_relative_ME_NRC | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk | No I2-specific action; retain original non-I2 caveat if any. |

## 4. Explanation of each I2-risk classification
| variable_id | window_id | diff_tests_support_stationarity | diff_tests_support_unit_root | failed_tests_count | unsupported_spec_count | audit_read | notes |
|---|---|---|---|---|---|---|---|
| k_t | full_long_sample | 2.000 | 1.000 | 3.000 | 3.000 | mixed_test_evidence | corrected_class_excluding_failed_rows=I2_risk |
| k_NRC_t | full_long_sample | 0.000 | 3.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| m_ME_NRC_t | full_long_sample | 0.000 | 3.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| k_NRC_t | pre_1974 | 0.000 | 3.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| m_ME_NRC_t | pre_1974 | 1.000 | 2.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| k_t | post_1973 | 0.000 | 3.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| k_NRC_t | post_1973 | 0.000 | 3.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| k_ME_t | post_1973 | 1.000 | 2.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| m_ME_NRC_t | post_1973 | 0.000 | 3.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| k_NRC_t | fordist_core | 0.000 | 3.000 | 3.000 | 3.000 | short_window_fragility | corrected_class_excluding_failed_rows=I2_risk |
| m_ME_NRC_t | fordist_core | 1.000 | 2.000 | 3.000 | 3.000 | short_window_fragility | corrected_class_excluding_failed_rows=I2_risk |
| k_NRC_t | bridge_1940_1978 | 1.000 | 2.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| k_ME_t | bridge_1940_1978 | 1.000 | 2.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| m_ME_NRC_t | bridge_1940_1978 | 1.000 | 2.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| k_NRC_t | pre_1974_alt_1940_1973 | 0.000 | 3.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| k_ME_t | pre_1974_alt_1940_1973 | 1.000 | 2.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| m_ME_NRC_t | pre_1974_alt_1940_1973 | 0.000 | 3.000 | 3.000 | 3.000 | genuine_I2_risk | corrected_class_excluding_failed_rows=I2_risk |
| k_NRC_t | pre_1974_alt_1947_1974 | 0.000 | 3.000 | 3.000 | 3.000 | short_window_fragility | corrected_class_excluding_failed_rows=I2_risk |

## 5. Test-trace summary for capital variables
| variable_id | window_id | diff_adf_primary_p_or_cv_read | diff_pp_primary_p_or_cv_read | diff_kpss_primary_p_or_cv_read | audit_read |
|---|---|---|---|---|---|
| k_t | full_long_sample | reject_unit_root_5pct | reject_unit_root_5pct | reject_stationarity_5pct | mixed_test_evidence |
| k_NRC_t | full_long_sample | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | genuine_I2_risk |
| k_ME_t | full_long_sample | reject_unit_root_5pct | reject_unit_root_5pct | fail_to_reject_stationarity_5pct | not_I2_risk |
| m_ME_NRC_t | full_long_sample | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | genuine_I2_risk |
| k_t | pre_1974 | reject_unit_root_5pct | reject_unit_root_5pct | fail_to_reject_stationarity_5pct | not_I2_risk |
| k_NRC_t | pre_1974 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | genuine_I2_risk |
| k_ME_t | pre_1974 | reject_unit_root_5pct | fail_to_reject_unit_root_5pct | fail_to_reject_stationarity_5pct | not_I2_risk |
| m_ME_NRC_t | pre_1974 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | fail_to_reject_stationarity_5pct | genuine_I2_risk |
| k_t | post_1973 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | genuine_I2_risk |
| k_NRC_t | post_1973 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | genuine_I2_risk |
| k_ME_t | post_1973 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | fail_to_reject_stationarity_5pct | genuine_I2_risk |
| m_ME_NRC_t | post_1973 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | genuine_I2_risk |
| k_t | fordist_core | reject_unit_root_5pct | fail_to_reject_unit_root_5pct | fail_to_reject_stationarity_5pct | not_I2_risk |
| k_NRC_t | fordist_core | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | short_window_fragility |
| k_ME_t | fordist_core | reject_unit_root_5pct | fail_to_reject_unit_root_5pct | fail_to_reject_stationarity_5pct | not_I2_risk |
| m_ME_NRC_t | fordist_core | reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | short_window_fragility |
| k_t | bridge_1940_1978 | reject_unit_root_5pct | reject_unit_root_5pct | fail_to_reject_stationarity_5pct | not_I2_risk |
| k_NRC_t | bridge_1940_1978 | reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | genuine_I2_risk |
| k_ME_t | bridge_1940_1978 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | fail_to_reject_stationarity_5pct | genuine_I2_risk |
| m_ME_NRC_t | bridge_1940_1978 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | fail_to_reject_stationarity_5pct | genuine_I2_risk |
| k_t | pre_1974_alt_1940_1973 | reject_unit_root_5pct | fail_to_reject_unit_root_5pct | fail_to_reject_stationarity_5pct | not_I2_risk |
| k_NRC_t | pre_1974_alt_1940_1973 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | genuine_I2_risk |
| k_ME_t | pre_1974_alt_1940_1973 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | fail_to_reject_stationarity_5pct | genuine_I2_risk |
| m_ME_NRC_t | pre_1974_alt_1940_1973 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | genuine_I2_risk |
| k_t | pre_1974_alt_1947_1974 | fail_to_reject_unit_root_5pct | reject_unit_root_5pct | fail_to_reject_stationarity_5pct | not_I2_risk |
| k_NRC_t | pre_1974_alt_1947_1974 | fail_to_reject_unit_root_5pct | fail_to_reject_unit_root_5pct | reject_stationarity_5pct | short_window_fragility |
| k_ME_t | pre_1974_alt_1947_1974 | reject_unit_root_5pct | reject_unit_root_5pct | fail_to_reject_stationarity_5pct | not_I2_risk |
| m_ME_NRC_t | pre_1974_alt_1947_1974 | reject_unit_root_5pct | reject_unit_root_5pct | fail_to_reject_stationarity_5pct | not_I2_risk |

## 6. Check on failed/skipped test handling
| diagnostic_id | result | severity | recommended_action |
|---|---|---|---|
| D01_existing_outputs_read | yes | none | Proceed to audit. |
| D02_unsupported_none_rows | yes | low | Keep unsupported none rows visible; do not count them as evidence. |
| D03_primary_failed_rows | no | none | No corrected target classification output required. |
| D04_i2_corrected_changes | no | none | Do not patch original S31I outputs. |
| D05_original_code_location | codes/US_S31I_integration_order_precheck_B1_E2B.R:435-480 | low | Document the rule and keep failed/skipped rows excluded from audit read. |

## 7. Deterministic-sensitivity assessment
| variable_id | window_id | original_classification | audit_read | notes |
|---|---|---|---|---|
| omega_t | full_long_sample | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| y_t | pre_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| k_t | pre_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| omega_k_t | pre_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| k_ME_t | pre_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| omega_m_ME_NRC_t | post_1973 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| y_t | fordist_core | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| k_t | fordist_core | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| omega_k_t | fordist_core | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| omega_m_ME_NRC_t | fordist_core | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| pK_relative_ME_NRC | fordist_core | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| y_t | bridge_1940_1978 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| k_t | bridge_1940_1978 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| omega_k_t | bridge_1940_1978 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| omega_m_ME_NRC_t | bridge_1940_1978 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| pK_relative_ME_NRC | bridge_1940_1978 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| y_t | pre_1974_alt_1940_1973 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| k_t | pre_1974_alt_1940_1973 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| omega_k_t | pre_1974_alt_1940_1973 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| omega_m_ME_NRC_t | pre_1974_alt_1940_1973 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| y_t | pre_1974_alt_1947_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| k_t | pre_1974_alt_1947_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| omega_k_t | pre_1974_alt_1947_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| k_ME_t | pre_1974_alt_1947_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| m_ME_NRC_t | pre_1974_alt_1947_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| omega_m_ME_NRC_t | pre_1974_alt_1947_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |
| pK_relative_ME_NRC | pre_1974_alt_1947_1974 | deterministic_sensitive | not_I2_risk | corrected_class_excluding_failed_rows=deterministic_sensitive |

## 8. Short-window fragility assessment
| variable_id | window_id | n_obs | original_classification | audit_read |
|---|---|---|---|---|
| y_t | fordist_core | 29.000 | deterministic_sensitive | not_I2_risk |
| k_t | fordist_core | 29.000 | deterministic_sensitive | not_I2_risk |
| omega_t | fordist_core | 29.000 | I0_preferred | not_I2_risk |
| omega_k_t | fordist_core | 29.000 | deterministic_sensitive | not_I2_risk |
| k_NRC_t | fordist_core | 29.000 | I2_risk | short_window_fragility |
| k_ME_t | fordist_core | 29.000 | ambiguous_hold | not_I2_risk |
| m_ME_NRC_t | fordist_core | 29.000 | I2_risk | short_window_fragility |
| omega_m_ME_NRC_t | fordist_core | 29.000 | deterministic_sensitive | not_I2_risk |
| pK_relative_ME_NRC | fordist_core | 29.000 | deterministic_sensitive | not_I2_risk |
| y_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk |
| k_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk |
| omega_t | pre_1974_alt_1947_1974 | 28.000 | ambiguous_hold | not_I2_risk |
| omega_k_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk |
| k_NRC_t | pre_1974_alt_1947_1974 | 28.000 | I2_risk | short_window_fragility |
| k_ME_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk |
| m_ME_NRC_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk |
| omega_m_ME_NRC_t | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk |
| pK_relative_ME_NRC | pre_1974_alt_1947_1974 | 28.000 | deterministic_sensitive | not_I2_risk |

## 9. Implications for B1
The B1 question is whether k_t and omega_k_t can be treated as admissible long-run regressors alongside y_t. If k_t is genuinely I2-risk, B1 cannot be read as a clean I(1) cointegrating-regression design without redesign. If the I2-risk call is an artifact of deterministic sensitivity or failed-test handling, B1 remains admissible for review but must carry the S31I caveat.

## 10. Implications for E2B
The E2B question is whether k_NRC_t, m_ME_NRC_t, and omega_m_ME_NRC_t can support the NRC-envelope / distribution-conditioned mechanization-bias interpretation. If k_NRC_t and m_ME_NRC_t are genuinely I2-risk, E2B cannot be promoted mechanically from S32 coefficient results. If the I2-risk call is mostly rule-driven or short-window fragile, E2B remains a review candidate but must be documented as integration-order sensitive.

## 11. Recommendation on corrected reclassification
No corrected reclassification table was necessary for the target variables.

## 12. Guardrail statement
S31, S32, and S40 remain untouched. This audit does not choose a model and does not reinterpret integration-order tests as cointegration evidence.
