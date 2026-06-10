# U.S. S22 Preliminary A00 Periodized Results

These are preliminary A00 baseline estimates using actual log output as an effective-output proxy, NFC productive-capacity capital, and an unadjusted NFC wage-share-conditioned accumulated capital-growth index. The estimates are not Shaikh-adjusted results, not mechanization-bias specifications, and not final productive-capacity estimates.

## Period status

|period_id|years|n_obs|estimator|theta_0_estimate|theta_omega_estimate|admissibility_status|warning_flags|
|---|---|---|---|---|---|---|---|
|full_long_sample|1929-2024|95|diagnostic_OLS_not_preferred_estimator| 2.3742855| -2.9326252|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|pre_1974_full|1929-1973|44|diagnostic_OLS_not_preferred_estimator|34.2134752|-53.0287998|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|post_1973_full|1974-2024|51|diagnostic_OLS_not_preferred_estimator| 0.9345139| -0.7225566|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|fordist_core|1945-1973|29|diagnostic_OLS_not_preferred_estimator|14.3141289|-21.6326349|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|bridge_1940_1978|1940-1978|39|diagnostic_OLS_not_preferred_estimator|22.5303804|-34.6950225|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|pre_1974_alt_1940_1973|1940-1973|34|diagnostic_OLS_not_preferred_estimator|21.6355810|-33.2716117|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|
|pre_1974_alt_1947_1973|1947-1973|27|diagnostic_OLS_not_preferred_estimator|15.0487710|-22.8043391|proxy_admissible_for_preliminary_A00|diagnostic_OLS_not_preferred_estimator|

## Interpretation

All seven governed windows are estimated with diagnostic OLS. The coefficients provide preliminary evidence about the elasticity of realized output with respect to productive-capacity capital accumulation and its lagged wage-share-conditioned q path. They are not promoted as final structural coefficients.

## Limitations

Shaikh-style distributive adjustments remain blocked pending current-release protocol.
The baseline uses unadjusted `omega_NFC`.
The dependent variable is realized output, used here as a preliminary proxy to estimate the elasticity of output with respect to productive-capacity capital accumulation. A stricter theoretical productive-capacity object remains downstream.
Mechanization-bias specifications using ME/NRC composition are deferred.
IPP and GOV_TRANS frontier conditioners are not included in this baseline regression.
S40 capacity/utilization reconstruction is not part of this pass.
