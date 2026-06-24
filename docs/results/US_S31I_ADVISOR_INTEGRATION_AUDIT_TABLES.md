# U.S. S31I Advisor Integration Audit Tables

## 1. Executive summary

S31I audits integration-order admissibility and I(2) risk for the effective-output proxy, productive-capacity capital, distribution states, aggregate and periodized q indexes, mechanization candidates, and frontier conditioners before S32 model choice.
The audit is needed because cumulative q variables and capital levels can carry higher-order stochastic trends that invalidate a later cointegrating-regression design if they are treated mechanically.
The locked baseline is actual log output as an effective-output proxy, NFC K_cap, unadjusted omega_NFC, and q_omega_h1_Kcap. Mechanization and frontier objects remain candidate-only.
Because productive capacity is latent, S32 uses actual log output as the effective-output proxy. The target is not an observed productive-capacity dependent variable, but the coefficient structure linking capital accumulation to capacity-forming output dynamics.
GOV_TRANS_growth and IPP_growth are immediately stationary among frontier conditioners. Baseline I(1) variables are not rejected for that reason; they are carried to S32 as cointegration candidates subject to cointegration/admissibility testing.
**S31I does not estimate coefficients. It only audits integration-order admissibility and I(2) risk before S32 model choice.**

## 2. Current baseline architecture

|Block|Object|Role|Status|Comment|
|---|---|---|---|---|
|Effective output|y_t|effective-output proxy|effective-output proxy|Actual log output; productive capacity is latent.|
|Productive-capacity capital|K_cap|preferred NFC capital|locked|K_ME + K_NRC.|
|Distribution|omega_NFC|preferred state|locked unadjusted|NFC compensation/GVA.|
|Aggregate A00 q|q_omega_h1_Kcap|preferred aggregate q candidate|constructed_for_S31I_integration_audit; preferred_A00_q_candidate|No centering or unrestricted weights.|
|Periodized A00 q|seven S22 period-reset q indexes|periodized baseline candidates|validated S22|Reset within each window.|
|Mechanization extension|six mechanization-bias q candidates|candidate extensions|audit-only|Not baseline replacements.|
|Frontier conditioning|IPP and GOV_TRANS|frontier conditioners|candidate-only|Not additive K_cap components.|
|Adjusted distribution|Shaikh-adjusted distribution|blocked variant|blocked|Current-release protocol remains blocked.|

## 3. Candidate-variable families audited

|Family|Variables audited|Purpose in later S32|Status entering S31I|
|---|---|---|---|
|aggregate_q_indexes|q_omega_h1_Kcap, q_omega_h3_Kcap, q_omega_h5_Kcap, q_e_h1_Kcap, q_e_h3_Kcap, q_e_h5_Kcap|preferred_A00_q_candidate; memory_state_robustness_candidate; alternative_distribution_proxy_candidate|constructed_for_S31I_integration_audit|
|distribution_states|omega_NFC, omega_CORP, pi_res_NFC, pi_res_CORP, e_NFC, e_CORP, ln_e_NFC, ln_e_CORP|preferred_distribution_state; distribution_robustness_or_diagnostic|validated_upstream|
|effective_output_proxy|y_t|effective_output_proxy|validated_upstream|
|frontier_conditioners|IPP_stock, IPP_growth, IPP_share_total_fixed_assets, IPP_share_capital_plus_IPP, IPP_to_Kcap, GOV_TRANS_stock, GOV_TRANS_growth, GOV_TRANS_to_Kcap, GOV_TRANS_to_NRC, GOV_TRANS_to_ME|frontier_conditioner|validated_upstream|
|mechanization_bias_q_candidates|q_omega_h1_ME, q_omega_h1_NRC, q_omega_h1_ME_minus_NRC, q_omega_h1_ME_share, q_omega_h1_NRC_share, q_omega_h1_ME_NRC_gap|mechanization_bias_candidate|audit_only_mechanization_q_candidate|
|mechanization_composition_diagnostics|ME_NRC_gap, ME_share, NRC_share, Delta_ME_NRC_gap, Delta_ME_share, Delta_NRC_share|composition_diagnostic; audit_only_mechanization_change_variable|validated_upstream; audit_only_constructed|
|periodized_q_indexes|q_omega_h1_Kcap__full_long_sample, q_omega_h1_Kcap__pre_1974_full, q_omega_h1_Kcap__post_1973_full, q_omega_h1_Kcap__fordist_core, q_omega_h1_Kcap__bridge_1940_1978, q_omega_h1_Kcap__pre_1974_alt_1940_1973, q_omega_h1_Kcap__pre_1974_alt_1947_1973|periodized_A00_q_candidate|validated_upstream_periodized|
|productive_capacity_capital|K_ME, K_NRC, K_cap, k_ME, k_NRC, k_Kcap, g_K_ME, g_K_NRC, g_Kcap|capital_level; capital_growth|validated_upstream|

## 4. Integration-order summary

|Family|Variables|Dominant integration classification|I(2)-risk count|Rolling-instability count|S32 implication|
|---|---|---|---|---|---|
|aggregate_q_indexes|6|I1_recommended|0|6|carry I(1)/no-I(2) objects with rolling warnings|
|distribution_states|8|I1_recommended|0|8|carry I(1)/no-I(2) objects with rolling warnings|
|effective_output_proxy|1|I1_recommended|0|1|carry I(1)/no-I(2) objects with rolling warnings|
|frontier_conditioners|10|I1_recommended|2|9|carry I(1)/no-I(2) objects with rolling warnings|
|mechanization_bias_q_candidates|6|I2_risk|4|6|carry I(1)/no-I(2) objects with rolling warnings|
|mechanization_composition_diagnostics|6|I1_recommended|3|6|carry I(1)/no-I(2) objects with rolling warnings|
|periodized_q_indexes|7|I1_recommended|2|5|carry I(1)/no-I(2) objects with rolling warnings|
|productive_capacity_capital|9|I0_recommended|3|9|carry I(1)/no-I(2) objects with rolling warnings|

## 5. Baseline A00 admissibility table

|Variable|Role|Integration-order recommendation|I(2)-risk flag|Rolling instability flag|Carry to S32?|Comment|
|---|---|---|---|---|---|---|
|y_t|effective_output_proxy|I1_recommended|FALSE|TRUE|TRUE|carry_to_S32_baseline_cointegration_candidate_with_rolling_warning|
|k_Kcap|capital_level|I1_recommended|FALSE|TRUE|TRUE|carry_to_S32_baseline_cointegration_candidate_with_rolling_warning|
|q_omega_h1_Kcap|preferred_A00_q_candidate|I1_recommended|FALSE|TRUE|TRUE|carry_to_S32_baseline_cointegration_candidate_with_rolling_warning|
|q_omega_h1_Kcap__full_long_sample|periodized_A00_q_candidate|I1_recommended|FALSE|TRUE|TRUE|carry_to_S32_periodized_cointegration_candidate_with_rolling_warning|
|q_omega_h1_Kcap__pre_1974_full|periodized_A00_q_candidate|I1_recommended|FALSE|TRUE|TRUE|carry_to_S32_periodized_cointegration_candidate_with_rolling_warning|
|q_omega_h1_Kcap__post_1973_full|periodized_A00_q_candidate|I2_risk|TRUE|FALSE|FALSE|audit_only_high_i2_risk|
|q_omega_h1_Kcap__fordist_core|periodized_A00_q_candidate|I1_recommended|FALSE|TRUE|TRUE|carry_to_S32_periodized_cointegration_candidate_with_rolling_warning|
|q_omega_h1_Kcap__bridge_1940_1978|periodized_A00_q_candidate|I1_recommended|FALSE|TRUE|TRUE|carry_to_S32_periodized_cointegration_candidate_with_rolling_warning|
|q_omega_h1_Kcap__pre_1974_alt_1940_1973|periodized_A00_q_candidate|I1_recommended|FALSE|TRUE|TRUE|carry_to_S32_periodized_cointegration_candidate_with_rolling_warning|
|q_omega_h1_Kcap__pre_1974_alt_1947_1973|periodized_A00_q_candidate|I2_risk|TRUE|FALSE|FALSE|audit_only_high_i2_risk|
|omega_NFC|preferred_distribution_state|I1_recommended|FALSE|TRUE|TRUE|carry_to_S32_cointegration_or_admissibility_candidate_with_rolling_warning|
|g_Kcap|capital_growth|I0_recommended|FALSE|TRUE|FALSE|stationary capital-growth input used to construct q, not the preferred long-run level regressor.|

## 6. Mechanization-bias candidate table

|Candidate|Mechanization meaning|Increment rule|Integration-order recommendation|I(2)-risk flag|Carry to S32?|Comment|
|---|---|---|---|---|---|---|
|q_omega_h1_ME|ME growth channel|cumsum(lag(omega_NFC,1) * g_K_ME)|I1_recommended|FALSE|TRUE|carry_to_S32_mechanization_cointegration_candidate_with_rolling_warning|
|q_omega_h1_NRC|NRC growth channel|cumsum(lag(omega_NFC,1) * g_K_NRC)|I1_recommended|FALSE|TRUE|carry_to_S32_mechanization_cointegration_candidate_with_rolling_warning|
|q_omega_h1_ME_minus_NRC|relative ME-vs-NRC growth bias|cumsum(lag(omega_NFC,1) * g_ME_minus_NRC)|I2_risk|TRUE|FALSE|audit_only_high_i2_risk|
|q_omega_h1_ME_share|ME composition-share shift|cumsum(lag(omega_NFC,1) * Delta_ME_share)|I2_risk|TRUE|FALSE|audit_only_high_i2_risk|
|q_omega_h1_NRC_share|NRC composition-share shift|cumsum(lag(omega_NFC,1) * Delta_NRC_share)|I2_risk|TRUE|FALSE|audit_only_high_i2_risk|
|q_omega_h1_ME_NRC_gap|log ME/NRC composition gap|cumsum(lag(omega_NFC,1) * Delta_ME_NRC_gap)|I2_risk|TRUE|FALSE|audit_only_high_i2_risk|

## 7. Frontier-conditioner table

|Variable|Conditioner type|Integration-order recommendation|I(2)-risk flag|Use in S32?|Comment|
|---|---|---|---|---|---|
|IPP_stock|IPP|ambiguous_or_higher_order_risk|TRUE|FALSE|audit_only_high_i2_risk - frontier conditioner, not additive K_cap|
|IPP_growth|IPP|I0_recommended|FALSE|TRUE|carry_to_S32_stationary_frontier_conditioner_candidate_with_rolling_warning - frontier conditioner, not additive K_cap|
|IPP_share_total_fixed_assets|IPP|I1_recommended|FALSE|TRUE|carry_to_S32_frontier_cointegrating_conditioner_candidate_with_rolling_warning - frontier conditioner, not additive K_cap|
|IPP_share_capital_plus_IPP|IPP|I1_recommended|FALSE|TRUE|carry_to_S32_frontier_cointegrating_conditioner_candidate_with_rolling_warning - frontier conditioner, not additive K_cap|
|IPP_to_Kcap|IPP|I1_recommended|FALSE|TRUE|carry_to_S32_frontier_cointegrating_conditioner_candidate_with_rolling_warning - frontier conditioner, not additive K_cap|
|GOV_TRANS_stock|GOV_TRANS|I2_risk|TRUE|FALSE|audit_only_high_i2_risk - frontier conditioner, not additive K_cap|
|GOV_TRANS_growth|GOV_TRANS|I0_recommended|FALSE|TRUE|carry_to_S32_stationary_frontier_conditioner_candidate - frontier conditioner, not additive K_cap|
|GOV_TRANS_to_Kcap|GOV_TRANS|I1_recommended|FALSE|TRUE|carry_to_S32_frontier_cointegrating_conditioner_candidate_with_rolling_warning - frontier conditioner, not additive K_cap|
|GOV_TRANS_to_NRC|GOV_TRANS|I1_recommended|FALSE|TRUE|carry_to_S32_frontier_cointegrating_conditioner_candidate_with_rolling_warning - frontier conditioner, not additive K_cap|
|GOV_TRANS_to_ME|GOV_TRANS|I1_recommended|FALSE|TRUE|carry_to_S32_frontier_cointegrating_conditioner_candidate_with_rolling_warning - frontier conditioner, not additive K_cap|

## 8. Main bottlenecks for advisor discussion

- Whether cumulative q-index variables show I(2) risk.
- Whether period-reset q variables reduce integration pressure.
- Whether ME/NRC mechanization candidates are empirically admissible.
- Whether capital-level classifications are stable across historical windows.
- Whether frontier conditioners should enter only after baseline stability.
- Whether actual output is adequate as a preliminary effective-output proxy.
- Whether alternative exploitation-rate q indexes add robustness or risk.

## 9. Recommended S32 model-choice sequence

S32 should begin with effective-output proxy y_t ~ k_Kcap + q_omega_h1_Kcap, using FM-OLS/IM-OLS/DOLS only after cointegration/admissibility gates.

|Step|Model family|Candidate regressors|Condition to proceed|Purpose|
|---|---|---|---|---|
|1|A00 aggregate baseline|effective-output proxy y_t ~ k_Kcap + q_omega_h1_Kcap|run FM-OLS/IM-OLS/DOLS only after cointegration/admissibility gates|establish aggregate reference|
|2|A00 periodized baseline|k_Kcap + period-reset q_omega_h1_Kcap|I(1), no global I(2) risk; retain rolling warning|test historical reset sensitivity|
|3|Mechanization-bias extension|k_Kcap + selected mechanization q candidates|I(1), no global I(2) risk; retain rolling warning|test composition channels|
|4|Frontier-conditioner extension|stable baseline + selected IPP/GOV_TRANS conditioners|baseline stability established first|test frontier conditioning|
|5|Alternative distribution proxy robustness|replace omega_NFC state with e_NFC q robustness|baseline architecture remains unchanged|distribution-state robustness|

## 10. Advisor-safe interpretation note

These audits do not decide the theory. They decide which empirical objects are safe enough to carry into the estimator/model-choice stage. The baseline remains aggregate NFC productive-capacity capital with unadjusted omega_NFC. Mechanization-bias q variables are candidate extensions, not replacements for the baseline.
