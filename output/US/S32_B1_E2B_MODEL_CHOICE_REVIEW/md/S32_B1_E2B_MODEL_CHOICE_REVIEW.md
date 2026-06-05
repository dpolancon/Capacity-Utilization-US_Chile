# S32 B1 versus E2B Model-Choice Review

## 1. Lock statement

S32 estimates only `SPEC_B1_WAGE_BASELINE` and `SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED`. The run does not estimate C, D, E1, or E2A specifications, does not choose a final winner, and does not authorize S40.

## 2. Data and sample

Input panel: `C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/US/us_s20_admissibility_panel.csv`. Available years: 1929-2024.
The existing S30/S20 output folders were not present; S32 therefore uses the active processed S20 panel and existing S31 VIF artifacts as the governed local inputs.

## 3. Specification contract

| spec_id | formula_label | S32_role | restriction |
|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | y_t ~ k_t + omega_k_t | baseline_locked_comparison_object | includes aggregate capital and omega_k only |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | y_t ~ k_NRC_t + omega_m_ME_NRC_t | restricted_mechanization_bias_candidate | m_ME_NRC_t omitted by design; E2B is not E2A |

## 4. Window design

Main review windows: full_long_sample, pre_1974, post_1973, fordist_core, bridge_1940_1978, pre_1974_alt_1940_1973, pre_1974_alt_1947_1974. Rolling endpoint windows keep the 1974 partition fixed and use a minimum sample length of 25 observations.

## 5. FM-OLS main results

| spec_id | window_id | regressor | coef | std_error | p_value |
|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | full_long_sample | k_t | 0.848 | 0.031 | 0.000 |
| SPEC_B1_WAGE_BASELINE | full_long_sample | omega_k_t | 0.034 | 0.056 | 0.544 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | k_NRC_t | 1.581 | 0.045 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | omega_m_ME_NRC_t | 1.273 | 0.175 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974 | k_t | 1.107 | 0.089 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974 | omega_k_t | -0.247 | 0.120 | 0.046 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | k_NRC_t | 1.454 | 0.103 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | omega_m_ME_NRC_t | 1.943 | 0.164 | 0.000 |
| SPEC_B1_WAGE_BASELINE | post_1973 | k_t | 0.816 | 0.007 | 0.000 |
| SPEC_B1_WAGE_BASELINE | post_1973 | omega_k_t | 0.016 | 0.009 | 0.077 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | k_NRC_t | 1.407 | 0.023 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | omega_m_ME_NRC_t | 0.275 | 0.044 | 0.000 |
| SPEC_B1_WAGE_BASELINE | fordist_core | k_t | 0.897 | 0.011 | 0.000 |
| SPEC_B1_WAGE_BASELINE | fordist_core | omega_k_t | -0.091 | 0.014 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | k_NRC_t | 1.403 | 0.010 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | omega_m_ME_NRC_t | 0.411 | 0.034 | 0.000 |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | k_t | 0.837 | 0.016 | 0.000 |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | omega_k_t | -0.047 | 0.019 | 0.016 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | k_NRC_t | 1.373 | 0.019 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | omega_m_ME_NRC_t | 0.522 | 0.073 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | k_t | 0.844 | 0.022 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | omega_k_t | -0.055 | 0.025 | 0.038 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | k_NRC_t | 1.428 | 0.022 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | omega_m_ME_NRC_t | 0.506 | 0.066 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | k_t | 0.921 | 0.016 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | omega_k_t | -0.113 | 0.017 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | k_NRC_t | 1.412 | 0.016 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | omega_m_ME_NRC_t | 0.536 | 0.081 | 0.000 |

## 6. IM-OLS robustness results

| spec_id | window_id | regressor | coef | std_error | p_value |
|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | full_long_sample | k_t | 0.815 | 0.038 | 0.000 |
| SPEC_B1_WAGE_BASELINE | full_long_sample | omega_k_t | 0.036 | 0.072 | 0.614 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | k_NRC_t | 1.529 | 0.052 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | omega_m_ME_NRC_t | 1.047 | 0.207 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974 | k_t | 1.201 | 0.112 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974 | omega_k_t | -0.413 | 0.170 | 0.020 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | k_NRC_t | 1.266 | 0.122 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | omega_m_ME_NRC_t | 1.988 | 0.193 | 0.000 |
| SPEC_B1_WAGE_BASELINE | post_1973 | k_t | 0.815 | 0.008 | 0.000 |
| SPEC_B1_WAGE_BASELINE | post_1973 | omega_k_t | 0.041 | 0.011 | 0.001 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | k_NRC_t | 1.381 | 0.027 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | omega_m_ME_NRC_t | 0.184 | 0.047 | 0.000 |
| SPEC_B1_WAGE_BASELINE | fordist_core | k_t | 0.935 | 0.016 | 0.000 |
| SPEC_B1_WAGE_BASELINE | fordist_core | omega_k_t | -0.148 | 0.019 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | k_NRC_t | 1.425 | 0.013 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | omega_m_ME_NRC_t | 0.470 | 0.039 | 0.000 |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | k_t | 0.907 | 0.024 | 0.000 |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | omega_k_t | -0.141 | 0.030 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | k_NRC_t | 1.347 | 0.021 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | omega_m_ME_NRC_t | 0.320 | 0.082 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | k_t | 0.929 | 0.029 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | omega_k_t | -0.190 | 0.034 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | k_NRC_t | 1.385 | 0.026 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | omega_m_ME_NRC_t | 0.269 | 0.076 | 0.001 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | k_t | 0.954 | 0.020 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | omega_k_t | -0.167 | 0.022 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | k_NRC_t | 1.494 | 0.027 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | omega_m_ME_NRC_t | 0.922 | 0.129 | 0.000 |

## 7. DOLS fragility diagnostics

| spec_id | window_id | regressor | coef | std_error | p_value |
|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | full_long_sample | k_t | 0.838 | 0.049 | 0.000 |
| SPEC_B1_WAGE_BASELINE | full_long_sample | omega_k_t | 0.042 | 0.060 | 0.483 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | k_NRC_t | 1.528 | 0.058 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | omega_m_ME_NRC_t | 0.779 | 0.320 | 0.017 |
| SPEC_B1_WAGE_BASELINE | pre_1974 | k_t | 1.124 | 0.182 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974 | omega_k_t | -0.292 | 0.260 | 0.267 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | k_NRC_t | 1.946 | 0.325 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | omega_m_ME_NRC_t | 3.387 | 0.716 | 0.000 |
| SPEC_B1_WAGE_BASELINE | post_1973 | k_t | 0.844 | 0.016 | 0.000 |
| SPEC_B1_WAGE_BASELINE | post_1973 | omega_k_t | 0.029 | 0.021 | 0.162 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | k_NRC_t | 1.505 | 0.096 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | omega_m_ME_NRC_t | 0.115 | 0.080 | 0.154 |
| SPEC_B1_WAGE_BASELINE | fordist_core | k_t | 0.829 | 0.031 | 0.000 |
| SPEC_B1_WAGE_BASELINE | fordist_core | omega_k_t | 0.010 | 0.046 | 0.827 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | k_NRC_t | 1.089 | 0.167 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | omega_m_ME_NRC_t | -0.427 | 0.640 | 0.511 |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | k_t | 0.983 | 0.076 | 0.000 |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | omega_k_t | -0.277 | 0.111 | 0.017 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | k_NRC_t | 1.282 | 0.041 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | omega_m_ME_NRC_t | -0.064 | 0.199 | 0.750 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | k_t | 1.027 | 0.067 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | omega_k_t | -0.360 | 0.101 | 0.001 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | k_NRC_t | 1.435 | 0.141 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | omega_m_ME_NRC_t | 0.358 | 0.420 | 0.400 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | k_t | 0.807 | 0.022 | 0.000 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | omega_k_t | 0.040 | 0.031 | 0.205 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | k_NRC_t | 1.397 | 0.308 | 0.000 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | omega_m_ME_NRC_t | 0.679 | 1.342 | 0.617 |

## 8. Estimator triangulation

| spec_id | window_id | fmols_imols_alignment | dols_fragility_flag | coefficient_magnitude_stability | triangulation_status |
|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | TRUE | FALSE | sign_unstable | partial_alignment |
| SPEC_B1_WAGE_BASELINE | fordist_core | TRUE | TRUE | sign_unstable | dols_fragile_only |
| SPEC_B1_WAGE_BASELINE | full_long_sample | TRUE | FALSE | magnitude_unstable | magnitude_unstable |
| SPEC_B1_WAGE_BASELINE | post_1973 | TRUE | FALSE | magnitude_unstable | magnitude_unstable |
| SPEC_B1_WAGE_BASELINE | pre_1974 | TRUE | FALSE | sign_unstable | partial_alignment |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | TRUE | FALSE | sign_unstable | partial_alignment |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | TRUE | TRUE | sign_unstable | dols_fragile_only |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | TRUE | TRUE | magnitude_unstable | magnitude_unstable |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | TRUE | TRUE | magnitude_unstable | magnitude_unstable |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | TRUE | FALSE | magnitude_review | strong_alignment |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | TRUE | FALSE | magnitude_unstable | magnitude_unstable |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | TRUE | FALSE | magnitude_review | strong_alignment |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | TRUE | FALSE | magnitude_unstable | magnitude_unstable |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | TRUE | FALSE | magnitude_unstable | magnitude_unstable |

## 9. Rolling endpoint review

| spec_id | window_id | window_start | window_end | fm_im_sign_stable | dols_fragility_flag | stability_flag |
|---|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1953 | 1929.000 | 1953.000 | TRUE | TRUE | dols_fragile_only |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1954 | 1929.000 | 1954.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1955 | 1929.000 | 1955.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1956 | 1929.000 | 1956.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1957 | 1929.000 | 1957.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1958 | 1929.000 | 1958.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1959 | 1929.000 | 1959.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1960 | 1929.000 | 1960.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1961 | 1929.000 | 1961.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1962 | 1929.000 | 1962.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1963 | 1929.000 | 1963.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1964 | 1929.000 | 1964.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1965 | 1929.000 | 1965.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1966 | 1929.000 | 1966.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1967 | 1929.000 | 1967.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1968 | 1929.000 | 1968.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1969 | 1929.000 | 1969.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1970 | 1929.000 | 1970.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1971 | 1929.000 | 1971.000 | TRUE | FALSE | partial_alignment |
| SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1972 | 1929.000 | 1972.000 | TRUE | FALSE | partial_alignment |

## 10. Endogenous outlier screen

Consensus outlier rows: 333. Historical priors used: `false` for all rows.
| year | spec_id | window_id | estimator | mad_score | cook_distance | outlier_priority |
|---|---|---|---|---|---|---|
| 1930.000 | SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | IM_OLS | 4.124 | 0.040 | high |
| 1930.000 | SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1955 | FM_OLS | 4.151 | 0.072 | high |
| 1931.000 | SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | IM_OLS | 4.874 | 0.078 | high |
| 1931.000 | SPEC_B1_WAGE_BASELINE | full_long_sample | IM_OLS | 5.648 | 0.034 | high |
| 1932.000 | SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | DOLS | 6.843 | 0.217 | high |
| 1932.000 | SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | IM_OLS | 6.444 | 0.217 | high |
| 1932.000 | SPEC_B1_WAGE_BASELINE | full_long_sample | FM_OLS | 7.152 | 0.257 | high |
| 1932.000 | SPEC_B1_WAGE_BASELINE | full_long_sample | IM_OLS | 6.757 | 0.257 | high |
| 1933.000 | SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | IM_OLS | 6.520 | 0.213 | high |
| 1933.000 | SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | FM_OLS | 3.694 | 0.213 | high |
| 1933.000 | SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | DOLS | 6.220 | 0.213 | high |
| 1933.000 | SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1973 | FM_OLS | 3.546 | 0.232 | high |
| 1933.000 | SPEC_B1_WAGE_BASELINE | pre_1974 | FM_OLS | 3.546 | 0.232 | high |
| 1933.000 | SPEC_B1_WAGE_BASELINE | full_long_sample | IM_OLS | 3.709 | 0.238 | high |
| 1933.000 | SPEC_B1_WAGE_BASELINE | full_long_sample | FM_OLS | 7.619 | 0.238 | high |
| 1933.000 | SPEC_B1_WAGE_BASELINE | full_long_sample | DOLS | 4.296 | 0.238 | high |
| 1934.000 | SPEC_B1_WAGE_BASELINE | full_long_sample | FM_OLS | 4.363 | 0.107 | high |
| 1934.000 | SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1965 | IM_OLS | 3.966 | 0.079 | high |
| 1934.000 | SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1968 | IM_OLS | 3.514 | 0.083 | high |
| 1934.000 | SPEC_B1_WAGE_BASELINE | roll_fordist_1929_1964 | IM_OLS | 3.953 | 0.076 | high |

## 11. Candidate dummy-control grid

Dummy candidates are pulse dummies for endogenously identified outlier years only. They are not imposed in S32 estimation, and historical validation is a later step.
| dummy_id | year | priority | recommended_for_future_control_test |
|---|---|---|---|
| D_pulse_1930 | 1930.000 | high | TRUE |
| D_pulse_1931 | 1931.000 | high | TRUE |
| D_pulse_1932 | 1932.000 | high | TRUE |
| D_pulse_1933 | 1933.000 | high | TRUE |
| D_pulse_1934 | 1934.000 | high | TRUE |
| D_pulse_1935 | 1935.000 | high | TRUE |
| D_pulse_1936 | 1936.000 | high | TRUE |
| D_pulse_1937 | 1937.000 | high | TRUE |
| D_pulse_1938 | 1938.000 | high | TRUE |
| D_pulse_1941 | 1941.000 | high | TRUE |
| D_pulse_1942 | 1942.000 | high | TRUE |
| D_pulse_1943 | 1943.000 | high | TRUE |
| D_pulse_1944 | 1944.000 | high | TRUE |
| D_pulse_1945 | 1945.000 | high | TRUE |
| D_pulse_1946 | 1946.000 | high | TRUE |
| D_pulse_1947 | 1947.000 | medium | TRUE |
| D_pulse_1948 | 1948.000 | high | TRUE |
| D_pulse_1949 | 1949.000 | high | TRUE |
| D_pulse_1952 | 1952.000 | medium | TRUE |
| D_pulse_1953 | 1953.000 | high | TRUE |

## 12. Model-choice ledger

| spec_id | window_id | coefficient_signs_pass | fmols_imols_robustness_pass | vif_pass | cointegration_admissibility_status | eligible_for_reconstruction_review | human_decision |
|---|---|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | FALSE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_B1_WAGE_BASELINE | fordist_core | FALSE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_B1_WAGE_BASELINE | full_long_sample | TRUE | TRUE | TRUE | weak_or_sensitive_admissibility | FALSE | mechanically_rejected |
| SPEC_B1_WAGE_BASELINE | post_1973 | TRUE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_B1_WAGE_BASELINE | pre_1974 | FALSE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | FALSE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | FALSE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | TRUE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | TRUE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | TRUE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | TRUE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | TRUE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | TRUE | TRUE | TRUE | fail | FALSE | mechanically_rejected |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | TRUE | TRUE | TRUE | fail | FALSE | mechanically_rejected |

## Phillips-Ouliaris residual-based cointegration robustness

Cointegration admissibility is assessed only through the Phillips-Ouliaris residual-based cointegration robustness gate. S32 runs `urca::ca.po()` on the levels data matrix for each candidate long-run relation; it does not treat FM-OLS, IM-OLS, or DOLS as cointegration tests and does not feed estimator residuals into `ca.po()`.

The baseline Phillips-Ouliaris gate is `Pz / constant / short`. `Pz` is preferred because it is invariant to normalization of the cointegrating vector. `Pu`, deterministic alternatives, and lag alternatives are sensitivity checks. The gate affects cointegration admissibility only; it does not authorize S40.

| spec_id | window_id | po_statistic | po_cv_1pct | po_cv_5pct | po_cv_10pct | phillips_ouliaris_gate |
|---|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | full_long_sample | 51.256 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | 16.034 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_B1_WAGE_BASELINE | pre_1974 | 30.419 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | 22.720 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_B1_WAGE_BASELINE | post_1973 | 30.725 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | 10.591 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_B1_WAGE_BASELINE | fordist_core | 19.031 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | 6.739 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | 16.296 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | 21.234 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | 15.035 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | 17.112 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | 23.208 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | 14.184 | 109.453 | 89.762 | 80.203 | fail |

## Cointegration admissibility ledger

The admissibility ledger summarizes the Phillips-Ouliaris baseline and sensitivity behavior, coefficient alignment, DOLS fragility, VIF status, and outlier severity. These are mechanical classifications for human review only.

| spec_id | window_id | po_pz_constant_short_gate | po_any_pz_pass | po_deterministic_sensitive | po_lag_sensitive | cointegration_admissibility_status |
|---|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | fail | FALSE | FALSE | FALSE | fail |
| SPEC_B1_WAGE_BASELINE | fordist_core | fail | FALSE | FALSE | FALSE | fail |
| SPEC_B1_WAGE_BASELINE | full_long_sample | fail | TRUE | TRUE | TRUE | weak_or_sensitive_admissibility |
| SPEC_B1_WAGE_BASELINE | post_1973 | fail | FALSE | FALSE | FALSE | fail |
| SPEC_B1_WAGE_BASELINE | pre_1974 | fail | FALSE | FALSE | FALSE | fail |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | fail | FALSE | FALSE | FALSE | fail |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | fail | FALSE | FALSE | FALSE | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | fail | FALSE | FALSE | FALSE | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | fail | FALSE | FALSE | FALSE | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | fail | FALSE | FALSE | FALSE | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | fail | FALSE | FALSE | FALSE | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | fail | FALSE | FALSE | FALSE | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | fail | FALSE | FALSE | FALSE | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | fail | FALSE | FALSE | FALSE | fail |

## S32 B1/E2B PO dummy robustness

The bounded dummy-robustness pass tests whether baseline Phillips-Ouliaris admissibility failures survive endogenous pulse controls drawn from `S32_dummy_candidate_grid.csv` and `S32_outlier_screen.csv`. Dummies are diagnostic controls only. No historical priors are used. Only D1 can rescue a spec-window for serious human review; D2 and D3 are fragility and stress diagnostics and cannot define the preferred relation.

| spec_id | window_id | d0_gate | d1_gate | d2_gate | d3_gate | d1_rescue_for_serious_human_review | dummy_robustness_status |
|---|---|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | fail | fail | fail | not_tested | FALSE | unchanged_failure |
| SPEC_B1_WAGE_BASELINE | fordist_core | fail | fail | not_tested | not_tested | FALSE | unchanged_failure |
| SPEC_B1_WAGE_BASELINE | full_long_sample | fail | fail | pass_5pct | pass_1pct | FALSE | fragility_only_D2_or_D3 |
| SPEC_B1_WAGE_BASELINE | post_1973 | fail | fail | fail | fail | FALSE | unchanged_failure |
| SPEC_B1_WAGE_BASELINE | pre_1974 | fail | fail | pass_5pct | not_tested | FALSE | fragility_only_D2_or_D3 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | fail | fail | not_tested | not_tested | FALSE | unchanged_failure |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | fail | fail | not_tested | not_tested | FALSE | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | fail | fail | fail | not_tested | FALSE | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | fail | fail | not_tested | not_tested | FALSE | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | fail | fail | pass_1pct | pass_1pct | FALSE | fragility_only_D2_or_D3 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | fail | fail | fail | fail | FALSE | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | fail | fail | fail | not_tested | FALSE | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | fail | fail | not_tested | not_tested | FALSE | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | fail | fail | not_tested | not_tested | FALSE | unchanged_failure |

## 13. Interpretation for human adjudication

The mechanical evidence is organized for adjudication, not replacement of it. FM-OLS and IM-OLS alignment is the core robustness gate. DOLS disagreement is retained as fragility evidence. Any row marked eligible is only eligible for human reconstruction review; it is not a selected reconstruction object.

## 14. Explicit non-authorization of S40

S40 remains parked. This run did not reconstruct theta, productive capacity, or utilization and did not authorize any reconstruction step.
