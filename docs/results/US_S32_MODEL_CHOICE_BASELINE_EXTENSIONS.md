# U.S. S32 Preliminary Model Choice: Baseline and Extensions

## 1. Meeting-ready summary

These are preliminary S32 model-choice results using actual log output as the effective-output proxy. Productive capacity is latent; coefficients are interpreted as preliminary evidence on capacity-forming capital accumulation, not as estimates using observed productive capacity as the dependent variable.
The preferred baseline is y_t ~ k_Kcap + q_omega_h1_Kcap. Phillips-Ouliaris and residual-stationarity gates screen admissibility; they do not promote any coefficient to a final dissertation estimate.

## 2. Baseline result table

|model_id|n_obs|best_available_estimator|theta_0_k_Kcap|theta_omega_q|po_gate|residual_adf_gate|residual_kpss_gate|cointegration_screen|s30i_warnings|advisor_show_flag|
|---|---|---|---|---|---|---|---|---|---|---|
|S32_A00_baseline|    95|FM_OLS_preliminary|3.3304|-4.4253|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap|TRUE|

### Aggregate q robustness

|model_id|n_obs|best_available_estimator|theta_0_k_Kcap|theta_omega_q|po_gate|residual_adf_gate|residual_kpss_gate|cointegration_screen|s30i_warnings|advisor_show_flag|
|---|---|---|---|---|---|---|---|---|---|---|
|S32_A00_q_h3|    93|FM_OLS_preliminary|3.1894|-4.2208|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h3_Kcap|FALSE|
|S32_A00_q_h5|    91|FM_OLS_preliminary|4.5655|-6.4223|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h5_Kcap|FALSE|
|S32_A00_q_e_h1|    95|FM_OLS_preliminary|-0.37767|1.5617|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_e_h1_Kcap|FALSE|
|S32_A00_q_e_h3|    93|FM_OLS_preliminary|-0.34351|1.4834|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_e_h3_Kcap|FALSE|
|S32_A00_q_e_h5|    91|FM_OLS_preliminary|-0.83844| 2.306|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_e_h5_Kcap|FALSE|

## 3. Periodized results table

|model_id|n_obs|best_available_estimator|theta_0_k_Kcap|theta_omega_q|po_gate|residual_adf_gate|residual_kpss_gate|cointegration_screen|s30i_warnings|advisor_show_flag|
|---|---|---|---|---|---|---|---|---|---|---|
|S32_periodized_full_long_sample|    95|FM_OLS_preliminary|3.3304|-4.4253|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap__full_long_sample|TRUE|
|S32_periodized_pre_1974_full|    44|FM_OLS_preliminary|40.757|-63.424|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap__pre_1974_full|TRUE|
|S32_periodized_post_1973_full|    51|FM_OLS_preliminary|0.49283|-0.0070781|fail|pass|pass|mixed_evidence|I2_risk:q_omega_h1_Kcap__post_1973_full; rolling_instability:y_t,k_Kcap|FALSE|
|S32_periodized_fordist_core|    29|FM_OLS_preliminary|15.218|-23.047|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap__fordist_core|TRUE|
|S32_periodized_bridge_1940_1978|    39|FM_OLS_preliminary| 22.57|-34.746|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap__bridge_1940_1978|TRUE|
|S32_periodized_pre_1974_alt_1940_1973|    34|FM_OLS_preliminary|21.796|-33.511|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap__pre_1974_alt_1940_1973|TRUE|
|S32_periodized_pre_1974_alt_1947_1973|    27|FM_OLS_preliminary| 14.16|-21.369|fail|fail|pass|fail|I2_risk:q_omega_h1_Kcap__pre_1974_alt_1947_1973; rolling_instability:y_t,k_Kcap|FALSE|

All pre-1974 windows end in 1973. No short post-1974 window is added.

## 4. Mechanization-extension table

|model_id|mechanization_candidate|n_obs|extension_coefficient|po_gate|residual_adf_gate|cointegration_screen|s30i_warnings|advisor_show_flag|comment|
|---|---|---|---|---|---|---|---|---|---|
|S32_ME_growth_extension|q_omega_h1_ME|    95|1.6681|fail|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap,q_omega_h1_ME|FALSE|Candidate extension, not a replacement for the aggregate baseline.|
|S32_NRC_growth_extension|q_omega_h1_NRC|    95|-3.3082|fail|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap,q_omega_h1_NRC|FALSE|Candidate extension, not a replacement for the aggregate baseline.|
|S32_ME_minus_NRC_growth_extension|q_omega_h1_ME_minus_NRC|    95|1.1151|fail|pass|mixed_evidence|I2_risk:q_omega_h1_ME_minus_NRC; rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap,q_omega_h1_ME_minus_NRC|FALSE|Candidate extension, not a replacement for the aggregate baseline.|
|S32_ME_share_extension|q_omega_h1_ME_share|    95|5.0531|fail|pass|mixed_evidence|I2_risk:q_omega_h1_ME_share; rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap,q_omega_h1_ME_share|FALSE|Candidate extension, not a replacement for the aggregate baseline.|
|S32_NRC_share_extension|q_omega_h1_NRC_share|    95|-5.0531|fail|pass|mixed_evidence|I2_risk:q_omega_h1_NRC_share; rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap,q_omega_h1_NRC_share|FALSE|Candidate extension, not a replacement for the aggregate baseline.|
|S32_ME_NRC_gap_extension|q_omega_h1_ME_NRC_gap|    95|1.1151|fail|pass|mixed_evidence|I2_risk:q_omega_h1_ME_NRC_gap; rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap,q_omega_h1_ME_NRC_gap|FALSE|Candidate extension, not a replacement for the aggregate baseline.|

I(2)-risk mechanization candidates are retained only as diagnostic stress tests and are excluded from the preferred advisor display set.

## 5. Frontier-conditioner table

|model_id|frontier_conditioner|n_obs|conditioner_coefficient|po_gate|residual_adf_gate|residual_kpss_gate|cointegration_screen|s30i_warnings|advisor_show_flag|
|---|---|---|---|---|---|---|---|---|---|
|S32_GOV_TRANS_growth_extension|GOV_TRANS_growth|    95|0.69291|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap|FALSE|
|S32_IPP_growth_extension|IPP_growth|    95|3.0115|fail|pass|pass|mixed_evidence|rolling_instability:y_t,k_Kcap,q_omega_h1_Kcap,IPP_growth|FALSE|

GOV_TRANS_growth and IPP_growth enter as stationary conditioners, not as long-run level regressors or additive components of K_cap.

## 6. Preferred advisor display set

|advisor_priority|model_id|model_family|best_available_estimator|cointegration_screen|notes|
|---|---|---|---|---|---|
|1_baseline_show|S32_A00_baseline|A00_aggregate|FM_OLS_preliminary|mixed_evidence|Reference model; coefficients remain preliminary.|
|2_periodized_show|S32_periodized_bridge_1940_1978|A00_periodized|FM_OLS_preliminary|mixed_evidence|Governed S22 period-reset q window.|
|2_periodized_show|S32_periodized_fordist_core|A00_periodized|FM_OLS_preliminary|mixed_evidence|Governed S22 period-reset q window.|
|2_periodized_show|S32_periodized_full_long_sample|A00_periodized|FM_OLS_preliminary|mixed_evidence|Governed S22 period-reset q window.|
|2_periodized_show|S32_periodized_pre_1974_alt_1940_1973|A00_periodized|FM_OLS_preliminary|mixed_evidence|Governed S22 period-reset q window.|
|2_periodized_show|S32_periodized_pre_1974_full|A00_periodized|FM_OLS_preliminary|mixed_evidence|Governed S22 period-reset q window.|

## 7. What can be said

- S32 uses actual log output as an effective-output proxy while productive capacity remains latent.
- The aggregate A00 specification is the reference model for all comparisons.
- Phillips-Ouliaris and residual tests provide preliminary, model-specific admissibility evidence.
- Rolling integration instability remains visible as a warning and is not an automatic rejection.
- Periodized specifications reveal whether historical resetting changes the preliminary screen.
- Mechanization and frontier terms are extensions whose admissibility is judged against the aggregate baseline.

## 8. What cannot be claimed yet

- These are not final dissertation estimates.
- These do not remove all I(2)-risk warnings.
- These are not Shaikh-adjusted distribution results.
- These do not use observed productive capacity as the dependent variable.
- Mechanization-bias extensions are candidate extensions, not baseline replacements.
