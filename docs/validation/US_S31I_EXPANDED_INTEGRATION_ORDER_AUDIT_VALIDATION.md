# U.S. S31I Expanded Integration-Order Audit Validation

## Purpose

S31I audits integration order, I(2) risk, and historical-window classification stability for all governed A00, periodized, mechanization, distribution, and frontier-conditioner candidates.

## Inputs used

- `data/processed/us_s20/us_s20_capital_distribution_frontier_panel.csv`
- `data/processed/us_s20/us_s20_construction_ledger.csv`
- `data/processed/us_s20/us_s20_validation_checks.csv`
- `data/processed/us_s22/us_s22_periodized_q_panel.csv`
- `data/processed/us_s22/us_s22_periodized_q_ledger.csv`
- `data/processed/us_s22/us_s22_preliminary_regression_results.csv`
- `data/processed/us_s22/us_s22_preliminary_regression_diagnostics.csv`
- `data/processed/us_s22/us_s22_validation_checks.csv`

## Candidate families audited

- `effective_output_proxy`
- `productive_capacity_capital`
- `mechanization_composition_diagnostics`
- `distribution_states`
- `aggregate_q_indexes`
- `periodized_q_indexes`
- `mechanization_bias_q_candidates`
- `frontier_conditioners`

## Test protocol

ADF tests use `urca::ur.df` with AIC lag selection under none, drift, and trend deterministic cases. KPSS tests use `urca::ur.kpss` with short bandwidths under drift and trend. Level, first-difference, and second-difference traces remain visible.

## Rolling-window protocol

The audit re-runs the primary deterministic ADF/KPSS pair on the seven governed historical windows. It creates no short post-1974 window and no pre-1974 window ending in 1974.

## Outputs written

- `data/processed/us_s31i/us_s31i_candidate_audit_panel.csv`
- `data/processed/us_s31i/us_s31i_variable_registry.csv`
- `data/processed/us_s31i/us_s31i_integration_order_tests.csv`
- `data/processed/us_s31i/us_s31i_i2_risk_ledger.csv`
- `data/processed/us_s31i/us_s31i_rolling_window_audit.csv`
- `data/processed/us_s31i/us_s31i_admissibility_recommendations.csv`
- `data/processed/us_s31i/us_s31i_validation_checks.csv`
- `docs/validation/US_S31I_EXPANDED_INTEGRATION_ORDER_AUDIT_VALIDATION.md`
- `docs/results/US_S31I_ADVISOR_INTEGRATION_AUDIT_TABLES.md`

## Validation summary

|check_name|status|details|
|---|---|---|
|Advisor-facing markdown report is written|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/docs/results/US_S31I_ADVISOR_INTEGRATION_AUDIT_TABLES.md|
|Advisor report includes all required tidy tables|PASS|Sections 1 through 10 present.|
|Required aggregate q candidates are audited|PASS|constructed_for_S31I_integration_audit|
|Aggregate q variants retain their theoretical roles without S21|PASS|Missing S21 is a workflow note, not a theoretical-role downgrade.|
|Integration audit is not mislabeled as model-choice output|PASS|All outputs are S31I audit artifacts.|
|I(1)/no-I(2) baseline variables carry to S32 with warnings|PASS|y_t, k_Kcap, and q_omega_h1_Kcap are baseline cointegration candidates; no estimator is run in S31I.|
|Required capital variables exist|PASS|Nine capital objects audited.|
|All required CSV outputs are written|PASS|7 of 7 CSV files written.|
|Required distribution variables exist|PASS|Eight distribution objects audited.|
|Required frontier conditioners are audited|PASS|Ten IPP/GOV_TRANS objects audited.|
|Mechanization q candidates are marked candidate-only|PASS|All mechanization q rows are candidate-only.|
|Required mechanization q candidates are constructed and audited|PASS|q_omega_h1_ME; q_omega_h1_NRC; q_omega_h1_ME_minus_NRC; q_omega_h1_ME_share; q_omega_h1_NRC_share; q_omega_h1_ME_NRC_gap|
|No FM-OLS, IM-OLS, DOLS, Johansen, or VECM is run|PASS|No coefficient or system estimator is called.|
|No omega_x or e_x level interaction is constructed|PASS|Superseded interactions absent.|
|No q increment uses Delta(omega*K) or Delta(omega*k)|PASS|No distribution-capital product level is constructed.|
|No regressions are estimated|PASS|Script runs unit-root/stationarity tests only.|
|No Shaikh-adjusted variable is constructed|PASS|Unadjusted distribution only.|
|No capacity utilization is reconstructed|PASS|No productive-capacity or utilization series is constructed.|
|Required periodized q candidates are audited|PASS|q_omega_h1_Kcap__full_long_sample; q_omega_h1_Kcap__pre_1974_full; q_omega_h1_Kcap__post_1973_full; q_omega_h1_Kcap__fordist_core; q_omega_h1_Kcap__bridge_1940_1978; q_omega_h1_Kcap__pre_1974_alt_1940_1973; q_omega_h1_Kcap__pre_1974_alt_1947_1973|
|Provider artifacts are unmodified|PASS|6 hashes compared.|
|q increments use lagged distribution times growth/change|PASS|19 of 19 constructed/periodized q identities verified numerically.|
|Rolling instability alone is a warning, not an automatic block|PASS|I(1)/no-I(2) candidates carry forward with rolling warnings.|
|S20 validation has no FAIL|PASS|26 checks inspected.|
|S20 input panel exists|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/us_s20/us_s20_capital_distribution_frontier_panel.csv|
|Canonical S21 q output availability|WARN|Missing optional S21; aggregate q variants constructed for S31I without theoretical-role downgrade.|
|S22 validation has no FAIL|PASS|34 checks inspected.|
|S22 q panel exists|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/us_s22/us_s22_periodized_q_panel.csv|
|All S20/S22 inputs are unchanged|PASS|8 hashes compared.|
|Validation report is written|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/docs/validation/US_S31I_EXPANDED_INTEGRATION_ORDER_AUDIT_VALIDATION.md|
|y_t remains an effective-output proxy for latent productive capacity|PASS|Actual log output is not labeled as observed productive capacity.|
|Effective-output proxy y_t is labeled correctly|PASS|y_t role = effective_output_proxy.|

## Hard-lock confirmation

S31I fetched no BEA data, modified no provider or upstream output, constructed no adjusted distribution or level interaction, estimated no regression or cointegrating model, ran no Johansen/VECM system, reconstructed no productive capacity or utilization, promoted no coefficient, and did not run S32.
