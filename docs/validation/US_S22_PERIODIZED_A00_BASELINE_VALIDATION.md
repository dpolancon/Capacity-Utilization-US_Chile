# U.S. S22 Periodized A00 Baseline Validation

**Overall result: PASS.**

## Purpose

S22 constructs periodized, window-reset `q_omega_h1_Kcap` indexes from NFC productive-capacity capital growth and lagged unadjusted `omega_NFC`, then estimates preliminary effective-output proxy regressions. It does not estimate a mechanization-bias model.

## Upstream inputs

- `data/processed/us_s20/us_s20_capital_distribution_frontier_panel.csv`
- `data/processed/us_s20/us_s20_validation_checks.csv`
- `data/processed/US/us_s20_admissibility_panel.csv`
- `output/US/S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B/csv/S30I_variable_construction_ledger.csv`
- Optional canonical S21 q panel was not present and was not required.

## Period windows

|period_id|start_year|end_year|
|---|---|---|
|full_long_sample|1929|2024|
|pre_1974_full|1929|1973|
|post_1973_full|1974|2024|
|fordist_core|1945|1973|
|bridge_1940_1978|1940|1978|
|pre_1974_alt_1940_1973|1940|1973|
|pre_1974_alt_1947_1973|1947|1973|

## Binding periodization rule

For each period, S22 cumulatively sums `omega_NFC_{s-1} * g_Kcap_s` from the first usable observation and resets the index inside the period. It imports no accumulated pre-period q history, does not center or standardize q, and uses no contemporaneous distribution state.

## Effective q coverage

|period_id|start_year|end_year|n_obs|complete_case_start|complete_case_end|
|---|---|---|---|---|---|
|full_long_sample|1929|2024|95|1930|2024|
|pre_1974_full|1929|1973|44|1930|1973|
|post_1973_full|1974|2024|51|1974|2024|
|fordist_core|1945|1973|29|1945|1973|
|bridge_1940_1978|1940|1978|39|1940|1978|
|pre_1974_alt_1940_1973|1940|1973|34|1940|1973|
|pre_1974_alt_1947_1973|1947|1973|27|1947|1973|

## Regression status

|period_id|n_obs|estimator|admissibility_status|warning_flags|
|---|---|---|---|---|
|full_long_sample|95|diagnostic_OLS_not_preferred_estimator|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|pre_1974_full|44|diagnostic_OLS_not_preferred_estimator|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|post_1973_full|51|diagnostic_OLS_not_preferred_estimator|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|fordist_core|29|diagnostic_OLS_not_preferred_estimator|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|bridge_1940_1978|39|diagnostic_OLS_not_preferred_estimator|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|pre_1974_alt_1940_1973|34|diagnostic_OLS_not_preferred_estimator|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|pre_1974_alt_1947_1973|27|diagnostic_OLS_not_preferred_estimator|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|

The dependent variable is the established `y_t` log real output series used in prior S30/S32 scaffolds. S22 labels it `effective_output_proxy`; it is not canonical `y_t^p` and is not claimed to equal theoretical productive capacity.

## Validation checks

|check_name|status|details|
|---|---|---|
|Actual log output is permitted as the preliminary effective-output proxy|PASS|Source: data/processed/US/us_s20_admissibility_panel.csv:y_t; ledger label: log real output.|
|All seven requested period regressions are estimated|PASS|full_long_sample=95; pre_1974_full=44; post_1973_full=51; fordist_core=29; bridge_1940_1978=39; pre_1974_alt_1940_1973=34; pre_1974_alt_1947_1973=27|
|Required k_Kcap, g_Kcap, and omega_NFC variables exist|PASS|k_Kcap; g_Kcap; omega_NFC|
|Dependent variable is not mislabeled as canonical y_t^p|PASS|Dependent variable label is y_t_actual_log_output.|
|Regression rows label the dependent-variable role as effective_output_proxy|PASS|All seven regression rows use the explicit proxy role.|
|Diagnostic OLS, if used, is not mislabeled as FM-OLS|PASS|All estimated rows are labeled exactly diagnostic_OLS_not_preferred_estimator.|
|Lagged omega_NFC is backward-looking only|PASS|Each increment uses omega_NFC from year s-1.|
|Every period has at least 25 complete q observations|PASS|full_long_sample=95; pre_1974_full=44; post_1973_full=51; fordist_core=29; bridge_1940_1978=39; pre_1974_alt_1940_1973=34; pre_1974_alt_1947_1973=27|
|No contemporaneous omega_NFC is used in q construction|PASS|q increment = omega_NFC_{s-1} * g_Kcap_s.|
|No IPP or GOV_TRANS conditioner is included in regression rows|PASS|Frontier conditioners are excluded from the baseline regression.|
|No h3 or h5 q-index is used in the preferred baseline|PASS|Memory rule is h1 only.|
|No Johansen or VECM estimator is run|PASS|No system estimator or integration-order test is invoked.|
|No omega_x or e_x interaction variable is constructed|PASS|Superseded level interactions are absent.|
|No mechanization-bias variable is included in regression rows|PASS|Estimated baseline rows contain only k_Kcap and periodized q.|
|omega_CORP is not used in preferred q construction|PASS|Preferred state is omega_NFC.|
|No pre_1974 window ends in 1974|PASS|No prohibited 1974 endpoint.|
|No periodized q-index uses pre-period accumulated values|PASS|All q columns are missing before their first usable period observation.|
|No q_e variable is used in the preferred baseline|PASS|Only q_omega_h1_Kcap periodized indexes are constructed.|
|No Shaikh-adjusted variable is used|PASS|Only unadjusted S20 omega_NFC is used.|
|No short post-1974 window is created|PASS|post_1974_tight and post_1974_support are absent.|
|No unrequested period window is created|PASS|Exactly seven requested q columns constructed.|
|No capacity utilization is reconstructed|PASS|S22 constructs q indexes only; no utilization column is produced.|
|All required S22 output files are written|PASS|7 of 7 required outputs written.|
|All pre_1974 windows end in 1973|PASS|pre_1974_full; pre_1974_alt_1940_1973; pre_1974_alt_1947_1973|
|Provider artifacts are unchanged|PASS|6 provider files hashed unchanged.|
|Effective-output regressions carry preliminary proxy admissibility|PASS|Actual output is admitted as a proxy, not as theoretical capacity.|
|Each period q increment equals lagged omega_NFC times g_Kcap|PASS|All seven period-specific increment columns match within 1e-12.|
|q increment is not a delta of an omega-capital product|PASS|Implemented directly as omega_NFC_{s-1} * Delta log(K_cap_s); no product level or product difference is constructed.|
|Each periodized q-index resets inside its period|PASS|First q value equals the first usable within-period increment.|
|Regression rows are marked preliminary|PASS|All seven period rows explicitly remain preliminary.|
|All requested period windows are present|PASS|full_long_sample; pre_1974_full; post_1973_full; fordist_core; bridge_1940_1978; pre_1974_alt_1940_1973; pre_1974_alt_1947_1973|
|S20 validation checks contain no FAIL|PASS|26 S20 checks inspected.|
|S20 input panel exists|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/us_s20/us_s20_capital_distribution_frontier_panel.csv|
|All upstream inputs are unchanged|PASS|4 input hashes compared.|

## Hard-lock confirmation

S22 fetched no BEA data, modified no provider or S20 artifact, built no Shaikh-adjusted variable, level interaction, q_e index, h3/h5 index, mechanization regressor, frontier-conditioner regression, integration test, Johansen/VECM system, productive-capacity reconstruction, or capacity-utilization reconstruction.
