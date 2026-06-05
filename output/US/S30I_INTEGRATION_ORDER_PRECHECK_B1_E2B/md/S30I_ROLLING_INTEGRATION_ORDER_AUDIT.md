# S30I Rolling Integration-Order Audit

## 1. Executive read
Rolling windows generated: 1188.
Rolling stability cells: 72.
Stability labels: endpoint_fragile=7; mixed_unstable=17; stable_I0=7; stable_I1=14; stable_I2_risk=27.

## 2. Rolling protocol used
Pre-1974 expanding windows hold the start at the earliest available year and vary endpoints through 1973. Post-1973 expanding windows hold the start at 1974. Fixed-width windows use widths 30, 35, and 40 without crossing the 1974 partition.

## 3. Variables included
k_t, k_NRC_t, k_ME_t, m_ME_NRC_t, omega_k_t, omega_m_ME_NRC_t, y_t, omega_t, pK_relative_ME_NRC

## 4. Window families included
pre_1974_expanding, post_1973_expanding, fixed_width_30_pre_1974, fixed_width_30_post_1973, fixed_width_35_pre_1974, fixed_width_35_post_1973, fixed_width_40_pre_1974, fixed_width_40_post_1973

## 5. Compact rolling-stability table
| variable_id | window_family | n_windows_valid | dominant_classification | near_endpoint_classification | rolling_stability_label | s32_window_implication |
|---|---|---|---|---|---|---|
| k_t | pre_1974_expanding | 21.000 | I0_preferred | I0_preferred | stable_I0 | supports_with_caveat |
| k_t | post_1973_expanding | 27.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_t | fixed_width_30_pre_1974 | 16.000 | I0_preferred | I0_preferred | mixed_unstable | supports_with_caveat |
| k_t | fixed_width_30_post_1973 | 22.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_t | fixed_width_35_pre_1974 | 11.000 | I0_preferred | I0_preferred | mixed_unstable | supports_with_caveat |
| k_t | fixed_width_35_post_1973 | 17.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_t | fixed_width_40_pre_1974 | 6.000 | I0_preferred | I0_preferred | stable_I0 | supports_with_caveat |
| k_t | fixed_width_40_post_1973 | 12.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | pre_1974_expanding | 21.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | post_1973_expanding | 27.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_30_pre_1974 | 16.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_30_post_1973 | 22.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_35_pre_1974 | 11.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_35_post_1973 | 17.000 | I2_risk | I1_preferred | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_40_pre_1974 | 6.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_40_post_1973 | 12.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | pre_1974_expanding | 21.000 | I2_risk | I0_preferred | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | post_1973_expanding | 27.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | fixed_width_30_pre_1974 | 16.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | fixed_width_30_post_1973 | 22.000 | I2_risk | mixed_test_evidence | endpoint_fragile | endpoint_fragile_hold |
| k_ME_t | fixed_width_35_pre_1974 | 11.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | fixed_width_35_post_1973 | 17.000 | I2_risk | I1_preferred | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | fixed_width_40_pre_1974 | 6.000 | I1_preferred | I2_risk | endpoint_fragile | endpoint_fragile_hold |
| k_ME_t | fixed_width_40_post_1973 | 12.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | pre_1974_expanding | 21.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | post_1973_expanding | 27.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_30_pre_1974 | 16.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_30_post_1973 | 22.000 | I2_risk | I1_preferred | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_35_pre_1974 | 11.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_35_post_1973 | 17.000 | I2_risk | mixed_test_evidence | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_40_pre_1974 | 6.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_40_post_1973 | 12.000 | I2_risk | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| omega_k_t | pre_1974_expanding | 21.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |
| omega_k_t | post_1973_expanding | 27.000 | mixed_test_evidence | I1_preferred | endpoint_fragile | endpoint_fragile_hold |
| omega_k_t | fixed_width_30_pre_1974 | 16.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |
| omega_k_t | fixed_width_30_post_1973 | 22.000 | I1_preferred | I1_preferred | mixed_unstable | supports_with_caveat |
| omega_k_t | fixed_width_35_pre_1974 | 11.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |
| omega_k_t | fixed_width_35_post_1973 | 17.000 | mixed_test_evidence | I1_preferred | mixed_unstable | supports_with_caveat |
| omega_k_t | fixed_width_40_pre_1974 | 6.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |
| omega_k_t | fixed_width_40_post_1973 | 12.000 | mixed_test_evidence | I1_preferred | mixed_unstable | supports_with_caveat |
| omega_m_ME_NRC_t | pre_1974_expanding | 21.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |
| omega_m_ME_NRC_t | post_1973_expanding | 27.000 | I1_preferred | mixed_test_evidence | stable_I1 | supports_window_review |
| omega_m_ME_NRC_t | fixed_width_30_pre_1974 | 16.000 | I1_preferred | mixed_test_evidence | stable_I1 | supports_window_review |
| omega_m_ME_NRC_t | fixed_width_30_post_1973 | 22.000 | I2_risk | I1_preferred | mixed_unstable | supports_with_caveat |
| omega_m_ME_NRC_t | fixed_width_35_pre_1974 | 11.000 | I1_preferred | mixed_test_evidence | stable_I1 | supports_window_review |
| omega_m_ME_NRC_t | fixed_width_35_post_1973 | 17.000 | I2_risk | I1_preferred | mixed_unstable | supports_with_caveat |
| omega_m_ME_NRC_t | fixed_width_40_pre_1974 | 6.000 | I1_preferred | I1_preferred | endpoint_fragile | endpoint_fragile_hold |
| omega_m_ME_NRC_t | fixed_width_40_post_1973 | 12.000 | mixed_test_evidence | I1_preferred | endpoint_fragile | endpoint_fragile_hold |
| y_t | pre_1974_expanding | 21.000 | I0_preferred | I0_preferred | stable_I0 | supports_with_caveat |
| y_t | post_1973_expanding | 27.000 | I1_preferred | I1_preferred | mixed_unstable | supports_with_caveat |
| y_t | fixed_width_30_pre_1974 | 16.000 | I0_preferred | I0_preferred | mixed_unstable | supports_with_caveat |
| y_t | fixed_width_30_post_1973 | 22.000 | I1_preferred | mixed_test_evidence | mixed_unstable | supports_with_caveat |
| y_t | fixed_width_35_pre_1974 | 11.000 | I1_preferred | I0_preferred | mixed_unstable | supports_with_caveat |
| y_t | fixed_width_35_post_1973 | 17.000 | I1_preferred | mixed_test_evidence | mixed_unstable | supports_with_caveat |
| y_t | fixed_width_40_pre_1974 | 6.000 | I1_preferred | mixed_test_evidence | endpoint_fragile | endpoint_fragile_hold |
| y_t | fixed_width_40_post_1973 | 12.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |
| omega_t | pre_1974_expanding | 21.000 | I0_preferred | I0_preferred | stable_I0 | supports_with_caveat |
| omega_t | post_1973_expanding | 27.000 | I1_preferred | I1_preferred | mixed_unstable | supports_with_caveat |
| omega_t | fixed_width_30_pre_1974 | 16.000 | I0_preferred | I0_preferred | stable_I0 | supports_with_caveat |
| omega_t | fixed_width_30_post_1973 | 22.000 | I1_preferred | I1_preferred | mixed_unstable | supports_with_caveat |
| omega_t | fixed_width_35_pre_1974 | 11.000 | I0_preferred | I0_preferred | stable_I0 | supports_with_caveat |
| omega_t | fixed_width_35_post_1973 | 17.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |
| omega_t | fixed_width_40_pre_1974 | 6.000 | I0_preferred | I0_preferred | stable_I0 | supports_with_caveat |
| omega_t | fixed_width_40_post_1973 | 12.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |
| pK_relative_ME_NRC | pre_1974_expanding | 21.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |
| pK_relative_ME_NRC | post_1973_expanding | 27.000 | I2_risk | I1_preferred | stable_I2_risk | not_compatible_without_redesign |
| pK_relative_ME_NRC | fixed_width_30_pre_1974 | 16.000 | I1_preferred | I0_preferred | mixed_unstable | supports_with_caveat |
| pK_relative_ME_NRC | fixed_width_30_post_1973 | 22.000 | I2_risk | I1_preferred | mixed_unstable | supports_with_caveat |
| pK_relative_ME_NRC | fixed_width_35_pre_1974 | 11.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |
| pK_relative_ME_NRC | fixed_width_35_post_1973 | 17.000 | I1_preferred | I1_preferred | mixed_unstable | supports_with_caveat |
| pK_relative_ME_NRC | fixed_width_40_pre_1974 | 6.000 | I1_preferred | I1_preferred | endpoint_fragile | endpoint_fragile_hold |
| pK_relative_ME_NRC | fixed_width_40_post_1973 | 12.000 | I1_preferred | I1_preferred | stable_I1 | supports_window_review |

## 6. Pre-1974 endpoint-stability assessment
| variable_id | share_I1_preferred | share_I2_risk | near_endpoint_classification | rolling_stability_label | s32_window_implication |
|---|---|---|---|---|---|
| k_t | 0.000 | 0.000 | I0_preferred | stable_I0 | supports_with_caveat |
| k_NRC_t | 0.000 | 1.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | 0.000 | 0.810 | I0_preferred | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | 0.000 | 1.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| omega_k_t | 0.857 | 0.000 | I1_preferred | stable_I1 | supports_window_review |
| omega_m_ME_NRC_t | 1.000 | 0.000 | I1_preferred | stable_I1 | supports_window_review |
| y_t | 0.000 | 0.000 | I0_preferred | stable_I0 | supports_with_caveat |
| omega_t | 0.000 | 0.000 | I0_preferred | stable_I0 | supports_with_caveat |
| pK_relative_ME_NRC | 1.000 | 0.000 | I1_preferred | stable_I1 | supports_window_review |

## 7. Post-1973 endpoint-stability assessment
| variable_id | share_I1_preferred | share_I2_risk | near_endpoint_classification | rolling_stability_label | s32_window_implication |
|---|---|---|---|---|---|
| k_t | 0.000 | 1.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | 0.000 | 1.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | 0.000 | 1.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | 0.000 | 1.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| omega_k_t | 0.259 | 0.000 | I1_preferred | endpoint_fragile | endpoint_fragile_hold |
| omega_m_ME_NRC_t | 0.704 | 0.000 | mixed_test_evidence | stable_I1 | supports_window_review |
| y_t | 0.481 | 0.000 | I1_preferred | mixed_unstable | supports_with_caveat |
| omega_t | 0.556 | 0.000 | I1_preferred | mixed_unstable | supports_with_caveat |
| pK_relative_ME_NRC | 0.074 | 0.926 | I1_preferred | stable_I2_risk | not_compatible_without_redesign |

## 8. Fixed-width rolling-window assessment
| variable_id | window_family | n_windows_valid | dominant_classification | rolling_stability_label | s32_window_implication |
|---|---|---|---|---|---|
| k_t | fixed_width_30_pre_1974 | 16.000 | I0_preferred | mixed_unstable | supports_with_caveat |
| k_t | fixed_width_30_post_1973 | 22.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_t | fixed_width_35_pre_1974 | 11.000 | I0_preferred | mixed_unstable | supports_with_caveat |
| k_t | fixed_width_35_post_1973 | 17.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_t | fixed_width_40_pre_1974 | 6.000 | I0_preferred | stable_I0 | supports_with_caveat |
| k_t | fixed_width_40_post_1973 | 12.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_30_pre_1974 | 16.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_30_post_1973 | 22.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_35_pre_1974 | 11.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_35_post_1973 | 17.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_40_pre_1974 | 6.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_NRC_t | fixed_width_40_post_1973 | 12.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | fixed_width_30_pre_1974 | 16.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | fixed_width_30_post_1973 | 22.000 | I2_risk | endpoint_fragile | endpoint_fragile_hold |
| k_ME_t | fixed_width_35_pre_1974 | 11.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | fixed_width_35_post_1973 | 17.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| k_ME_t | fixed_width_40_pre_1974 | 6.000 | I1_preferred | endpoint_fragile | endpoint_fragile_hold |
| k_ME_t | fixed_width_40_post_1973 | 12.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_30_pre_1974 | 16.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_30_post_1973 | 22.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_35_pre_1974 | 11.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_35_post_1973 | 17.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_40_pre_1974 | 6.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| m_ME_NRC_t | fixed_width_40_post_1973 | 12.000 | I2_risk | stable_I2_risk | not_compatible_without_redesign |
| omega_k_t | fixed_width_30_pre_1974 | 16.000 | I1_preferred | stable_I1 | supports_window_review |
| omega_k_t | fixed_width_30_post_1973 | 22.000 | I1_preferred | mixed_unstable | supports_with_caveat |
| omega_k_t | fixed_width_35_pre_1974 | 11.000 | I1_preferred | stable_I1 | supports_window_review |
| omega_k_t | fixed_width_35_post_1973 | 17.000 | mixed_test_evidence | mixed_unstable | supports_with_caveat |
| omega_k_t | fixed_width_40_pre_1974 | 6.000 | I1_preferred | stable_I1 | supports_window_review |
| omega_k_t | fixed_width_40_post_1973 | 12.000 | mixed_test_evidence | mixed_unstable | supports_with_caveat |
| omega_m_ME_NRC_t | fixed_width_30_pre_1974 | 16.000 | I1_preferred | stable_I1 | supports_window_review |
| omega_m_ME_NRC_t | fixed_width_30_post_1973 | 22.000 | I2_risk | mixed_unstable | supports_with_caveat |
| omega_m_ME_NRC_t | fixed_width_35_pre_1974 | 11.000 | I1_preferred | stable_I1 | supports_window_review |
| omega_m_ME_NRC_t | fixed_width_35_post_1973 | 17.000 | I2_risk | mixed_unstable | supports_with_caveat |
| omega_m_ME_NRC_t | fixed_width_40_pre_1974 | 6.000 | I1_preferred | endpoint_fragile | endpoint_fragile_hold |
| omega_m_ME_NRC_t | fixed_width_40_post_1973 | 12.000 | mixed_test_evidence | endpoint_fragile | endpoint_fragile_hold |
| y_t | fixed_width_30_pre_1974 | 16.000 | I0_preferred | mixed_unstable | supports_with_caveat |
| y_t | fixed_width_30_post_1973 | 22.000 | I1_preferred | mixed_unstable | supports_with_caveat |
| y_t | fixed_width_35_pre_1974 | 11.000 | I1_preferred | mixed_unstable | supports_with_caveat |
| y_t | fixed_width_35_post_1973 | 17.000 | I1_preferred | mixed_unstable | supports_with_caveat |
| y_t | fixed_width_40_pre_1974 | 6.000 | I1_preferred | endpoint_fragile | endpoint_fragile_hold |
| y_t | fixed_width_40_post_1973 | 12.000 | I1_preferred | stable_I1 | supports_window_review |
| omega_t | fixed_width_30_pre_1974 | 16.000 | I0_preferred | stable_I0 | supports_with_caveat |
| omega_t | fixed_width_30_post_1973 | 22.000 | I1_preferred | mixed_unstable | supports_with_caveat |
| omega_t | fixed_width_35_pre_1974 | 11.000 | I0_preferred | stable_I0 | supports_with_caveat |
| omega_t | fixed_width_35_post_1973 | 17.000 | I1_preferred | stable_I1 | supports_window_review |
| omega_t | fixed_width_40_pre_1974 | 6.000 | I0_preferred | stable_I0 | supports_with_caveat |
| omega_t | fixed_width_40_post_1973 | 12.000 | I1_preferred | stable_I1 | supports_window_review |
| pK_relative_ME_NRC | fixed_width_30_pre_1974 | 16.000 | I1_preferred | mixed_unstable | supports_with_caveat |
| pK_relative_ME_NRC | fixed_width_30_post_1973 | 22.000 | I2_risk | mixed_unstable | supports_with_caveat |
| pK_relative_ME_NRC | fixed_width_35_pre_1974 | 11.000 | I1_preferred | stable_I1 | supports_window_review |
| pK_relative_ME_NRC | fixed_width_35_post_1973 | 17.000 | I1_preferred | mixed_unstable | supports_with_caveat |
| pK_relative_ME_NRC | fixed_width_40_pre_1974 | 6.000 | I1_preferred | endpoint_fragile | endpoint_fragile_hold |
| pK_relative_ME_NRC | fixed_width_40_post_1973 | 12.000 | I1_preferred | stable_I1 | supports_window_review |

## 9. Capital-variable implications
| variable_id | window_family | rolling_stability_label | s32_window_implication | human_review_flag |
|---|---|---|---|---|
| k_t | pre_1974_expanding | stable_I0 | supports_with_caveat | FALSE |
| k_t | post_1973_expanding | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_t | fixed_width_30_pre_1974 | mixed_unstable | supports_with_caveat | TRUE |
| k_t | fixed_width_30_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_t | fixed_width_35_pre_1974 | mixed_unstable | supports_with_caveat | TRUE |
| k_t | fixed_width_35_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_t | fixed_width_40_pre_1974 | stable_I0 | supports_with_caveat | FALSE |
| k_t | fixed_width_40_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_NRC_t | pre_1974_expanding | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_NRC_t | post_1973_expanding | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_NRC_t | fixed_width_30_pre_1974 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_NRC_t | fixed_width_30_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_NRC_t | fixed_width_35_pre_1974 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_NRC_t | fixed_width_35_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_NRC_t | fixed_width_40_pre_1974 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_NRC_t | fixed_width_40_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_ME_t | pre_1974_expanding | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_ME_t | post_1973_expanding | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_ME_t | fixed_width_30_pre_1974 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_ME_t | fixed_width_30_post_1973 | endpoint_fragile | endpoint_fragile_hold | TRUE |
| k_ME_t | fixed_width_35_pre_1974 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_ME_t | fixed_width_35_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| k_ME_t | fixed_width_40_pre_1974 | endpoint_fragile | endpoint_fragile_hold | TRUE |
| k_ME_t | fixed_width_40_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| m_ME_NRC_t | pre_1974_expanding | stable_I2_risk | not_compatible_without_redesign | TRUE |
| m_ME_NRC_t | post_1973_expanding | stable_I2_risk | not_compatible_without_redesign | TRUE |
| m_ME_NRC_t | fixed_width_30_pre_1974 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| m_ME_NRC_t | fixed_width_30_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| m_ME_NRC_t | fixed_width_35_pre_1974 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| m_ME_NRC_t | fixed_width_35_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| m_ME_NRC_t | fixed_width_40_pre_1974 | stable_I2_risk | not_compatible_without_redesign | TRUE |
| m_ME_NRC_t | fixed_width_40_post_1973 | stable_I2_risk | not_compatible_without_redesign | TRUE |

## 10. B1 implication
The B1 question is whether k_t and omega_k_t can be treated as admissible long-run regressors alongside y_t. If k_t is genuinely I2-risk, B1 cannot be read as a clean I(1) cointegrating-regression design without redesign. If the I2-risk call is an artifact of deterministic sensitivity or failed-test handling, B1 remains admissible for review but must carry the S30I caveat.

## 11. E2B implication
The E2B question is whether k_NRC_t, m_ME_NRC_t, and omega_m_ME_NRC_t can support the NRC-envelope / distribution-conditioned mechanization-bias interpretation. If k_NRC_t and m_ME_NRC_t are genuinely I2-risk, E2B cannot be promoted mechanically from S32 coefficient results. If the I2-risk call is mostly rule-driven or short-window fragile, E2B remains a review candidate but must be documented as integration-order sensitive.

## 12. Guardrail statement
Rolling integration-order diagnostics are window-reliability evidence, not model-choice evidence. Stable I(1) behavior supports human review of the corresponding estimation window family. Stable I2-risk behavior blocks clean I(1) cointegrating-regression interpretation unless the specification is redesigned. Endpoint-fragile behavior should be held for review rather than promoted mechanically.
This rolling audit does not choose the model and does not authorize S40.
