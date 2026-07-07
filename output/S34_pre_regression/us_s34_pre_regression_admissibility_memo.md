# S34 Pre-regression variable-menu admissibility memo

## 1. Data panel used

S34 uses `data/processed/us_s31i/us_s31i_candidate_audit_panel.csv` as the primary panel because it is the latest broad non-estimator candidate menu containing output, capacity capital, ME/NRC components, distribution states, q paths, mechanization candidates, and frontier conditioners. `data/processed/us_s32c/us_s32c_candidate_panel.csv` is newer but narrower and tied to a corporate-boundary robustness pass; S34 imports only S32C-only columns as secondary diagnostic variables. The v1.1 release candidate is discovered but not used as primary because it does not contain the full S31I q/composition menu.

## 2. Variables inspected

- Inspected variables: y_t, K_ME, K_NRC, K_cap, k_ME, k_NRC, k_Kcap, g_K_ME, g_K_NRC, g_Kcap, ME_NRC_gap, ME_share, NRC_share, Delta_ME_NRC_gap, Delta_ME_share, Delta_NRC_share, omega_NFC, omega_CORP, pi_res_NFC, pi_res_CORP, e_NFC, e_CORP, ln_e_NFC, ln_e_CORP, q_omega_h1_Kcap, q_omega_h3_Kcap, q_omega_h5_Kcap, q_e_h1_Kcap, q_e_h3_Kcap, q_e_h5_Kcap, q_omega_h1_Kcap__full_long_sample, q_omega_h1_Kcap__pre_1974_full, q_omega_h1_Kcap__post_1973_full, q_omega_h1_Kcap__fordist_core, q_omega_h1_Kcap__bridge_1940_1978, q_omega_h1_Kcap__pre_1974_alt_1940_1973, q_omega_h1_Kcap__pre_1974_alt_1947_1973, q_omega_h1_ME, q_omega_h1_NRC, q_omega_h1_ME_minus_NRC, q_omega_h1_ME_share, q_omega_h1_NRC_share, q_omega_h1_ME_NRC_gap, IPP_stock, IPP_growth, IPP_share_total_fixed_assets, IPP_share_capital_plus_IPP, IPP_to_Kcap, GOV_TRANS_stock, GOV_TRANS_growth, GOV_TRANS_to_Kcap, GOV_TRANS_to_NRC, GOV_TRANS_to_ME, CORP_GVA, Py_fred, CORP_GVA_real, y_CORP, q_increment_omegaCORP_h1_Kcap, q_omegaCORP_h1_Kcap, q_omegaCORP_h1_Kcap__full_long_sample, q_omegaCORP_h1_Kcap__pre_1974_full, q_omegaCORP_h1_Kcap__post_1973_full, q_omegaCORP_h1_Kcap__fordist_core, q_omegaCORP_h1_Kcap__bridge_1940_1978, q_omegaCORP_h1_Kcap__pre_1974_alt_1940_1973, q_omegaCORP_h1_Kcap__pre_1974_alt_1947_1973, q_omegaCORP_h1_ME, q_omegaCORP_h1_NRC, q_omegaCORP_h1_ME_minus_NRC, q_omegaCORP_h1_ME_share, q_omegaCORP_h1_NRC_share, q_omegaCORP_h1_ME_NRC_gap, Q_omega, q_proxy_mechanization_growth, Q_q, Q_MEshare, Q_Ishare

## 3. Standard cointegration-screen candidates

- `y_t`
- `k_ME`
- `k_NRC`
- `k_Kcap`
- `Delta_ME_NRC_gap`
- `e_NFC`
- `e_CORP`
- `ln_e_NFC`
- `ln_e_CORP`
- `q_omega_h1_Kcap`
- `q_omega_h3_Kcap`
- `q_omega_h5_Kcap`
- `q_e_h1_Kcap`
- `q_e_h3_Kcap`
- `q_e_h5_Kcap`
- `q_omega_h1_Kcap__full_long_sample`
- `q_omega_h1_ME`
- `q_omega_h1_NRC`
- `y_CORP`
- `q_omegaCORP_h1_Kcap`
- `q_omegaCORP_h1_Kcap__full_long_sample`
- `q_omegaCORP_h1_ME`
- `q_omegaCORP_h1_NRC`
- `Q_omega`
- `q_proxy_mechanization_growth`
- `Q_MEshare`

## 4. Bounded-persistent variables

- `ME_share`
- `NRC_share`
- `Delta_ME_share`
- `Delta_NRC_share`
- `omega_NFC`
- `omega_CORP`
- `pi_res_NFC`
- `pi_res_CORP`
- `IPP_share_total_fixed_assets`
- `IPP_share_capital_plus_IPP`
- `IPP_to_Kcap`
- `GOV_TRANS_to_Kcap`
- `GOV_TRANS_to_NRC`
- `GOV_TRANS_to_ME`

Bounded shares and ratios are not mechanically promoted to pure I(1) objects. Their persistence is recorded as an admissibility problem rather than as a standard long-run level license.

## 5. Blocked standard interactions

|object_id|variables_used|classification|notes|
|---|---|---|---|
|k_cap_times_wage_share|k_Kcap + omega_NFC|BLOCK_STANDARD_I2_RISK|Raw k*omega is theoretically second-order and blocked unless the state is I0.|
|k_cap_times_q|k_Kcap + q_omega_h1_Kcap|BLOCK_STANDARD_I2_RISK|Raw k*q confounds accumulated technique path logic and carries I(2) risk.|
|q_squared|q_omega_h1_Kcap|BLOCK_STANDARD_I2_RISK|Polynomial q is routed away from the standard grid unless q is stationary.|
|q_times_wage_share|q_omega_h1_Kcap + omega_NFC|BLOCK_STANDARD_I2_RISK|Raw q*omega is overloaded relative to the accumulated-path hierarchy.|
|Q_q|Q_q|BLOCK_STANDARD_I2_RISK|Integration classification in S34 ledger: I2_RISK. Accumulated paths are tested separately from raw products.|

## 6. Plausible accumulated paths

|object_id|classification|notes|
|---|---|---|
|Q_omega|AUTHORIZE_STANDARD_IF_I1|Integration classification in S34 ledger: I1. Accumulated paths are tested separately from raw products.|
|Q_MEshare|AUTHORIZE_STANDARD_IF_I1|Integration classification in S34 ledger: I1. Accumulated paths are tested separately from raw products.|

## 7. Visually plausible level relations

|relation_id|lhs|rhs_set|visual_status|integration_compatibility|
|---|---|---|---|---|
|REL_y_kcap|y_t|k_Kcap|visually_plausible|compatible_I1_pair|
|REL_y_kME|y_t|k_ME|visually_plausible|compatible_I1_pair|
|REL_y_kNRC|y_t|k_NRC|visually_plausible|compatible_I1_pair|
|REL_y_Qomega|y_t|Q_omega|visually_plausible|compatible_I1_pair|
|REL_y_Qq|y_t|Q_q|visually_plausible|blocked_i2_risk|
|REL_y_MEshare|y_t|ME_share|mixed_visual_support|bounded_state_not_standard_I1|
|REL_y_QMEshare|y_t|Q_MEshare|visually_plausible|compatible_I1_pair|
|REL_ycorp_Qcorp|y_CORP|q_omegaCORP_h1_Kcap|visually_plausible|compatible_I1_pair|

## 8. Theoretical relations not visually supported

|relation_id|lhs|rhs_set|theoretical_status|visual_status|notes|
|---|---|---|---|---|---|
|REL_q_omega|q_proxy_mechanization_growth|omega_NFC|TECHNIQUE_CHOICE|weak_visual_support|level_correlation=0.112; lhs=I1; rhs=BOUNDED_PERSISTENT|

## 9. Collinearity warnings

|design_id|regressors|condition_number|pairwise_correlation_max|rank_status|notes|
|---|---|---|---|---|---|
|DES_kcap_Qomega|k_Kcap + Q_omega|271.7|    1|full_rank|High condition number; fragile design warning.|
|DES_kME_kNRC|k_ME + k_NRC|18.87|0.9944|full_rank|Very high pairwise correlation; fragile design warning.|
|DES_kcap_Qq_Qomega|k_Kcap + Q_q + Q_omega|375.1|    1|full_rank|High condition number; fragile design warning.|
|DES_kcap_Qq_MEshare|k_Kcap + Q_q + ME_share|16.85|0.9862|full_rank|Very high pairwise correlation; fragile design warning.|

## 10. Recommended next repo layer

The next layer should be an S35 variable-review and estimator-refreeze prep gate that reviews S34 classifications, resolves I(2)-risk and bounded-persistent candidates, then freezes a smaller estimator menu. It should not start from the raw interaction grid.

## Explicit refreeze answer

Should the next move be an estimator refreeze? No. The next move is to use S34 as a pre-regression admissibility gate. Estimator refreeze should only occur after the integration-order, interaction-risk, visual-plausibility, and design-collinearity ledgers are reviewed.

## Final decision

`BLOCK_ESTIMATOR_REFREEZE_PENDING_I2_RISK_REVIEW`
