# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_BRIDGE_1940_1978_NO_TREND_LL11

## Status

CONTROLLED_PRELIMINARY
DESIGN_STAGE_PRELIMINARY_ONLY
NOT FINAL MANUSCRIPT ESTIMATION
NO PRODUCTIVE-CAPACITY RECONSTRUCTION
NO UTILIZATION RECONSTRUCTION
NO ELASTICITY RECOVERY

CONTROLLED_PRELIMINARY
NOT FINAL MANUSCRIPT ESTIMATION
NO-TREND BASELINE CONTRACT
D12F TREND-INCLUDED RESULTS RECLASSIFIED AS DIAGNOSTIC COMPARATOR
q_omega PARKED
FM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE
IM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE
RESTRICTED DOLS DYNAMIC CORRECTIONS APPLY ONLY TO BASE-VARIABLE FIRST DIFFERENCES
MAXIMAL FEASIBLE EFFECTIVE SAMPLE USED

## Estimator

RESTRICTED_DOLS

## No-trend contract

NO_TREND_BASELINE_RULE: intercept allowed; linear deterministic trend blocked.

## Window

bridge_1940_1978

## Lead/lag grid

LL11

## Nominal sample

1940-1978

## Complete-case sample

1940-1978

## Effective sample

1942 1977 n = 36

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term        coefficient_role   estimate std_error   t_value
       (Intercept) deterministic_intercept -61.499058 53.364000 -1.152445
          k_me_log          long_run_level  -1.495184  1.267897 -1.179263
         k_nrc_log          long_run_level   6.348197  4.544524  1.396889
         omega_nfc          long_run_level 112.910361 84.330506  1.338903
  k_me_log_x_omega          long_run_level   2.676789  2.002576  1.336673
 k_nrc_log_x_omega          long_run_level  -9.710772  7.180137 -1.352449
   p_value significance_stars
 0.2620890
 0.2514820
 0.1770352
 0.1949166
 0.1956318
 0.1906167

## Auxiliary dynamic terms

Auxiliary coefficients are hidden by default and are estimator-correction terms only.

                term                   coefficient_role shown_by_default
    d_k_me_log_lead1 restricted_base_difference_dynamic            FALSE
  d_k_me_log_current restricted_base_difference_dynamic            FALSE
     d_k_me_log_lag1 restricted_base_difference_dynamic            FALSE
   d_k_nrc_log_lead1 restricted_base_difference_dynamic            FALSE
 d_k_nrc_log_current restricted_base_difference_dynamic            FALSE
    d_k_nrc_log_lag1 restricted_base_difference_dynamic            FALSE
   d_omega_nfc_lead1 restricted_base_difference_dynamic            FALSE
 d_omega_nfc_current restricted_base_difference_dynamic            FALSE
    d_omega_nfc_lag1 restricted_base_difference_dynamic            FALSE
 is_dynamic_base_difference_term is_interaction_dynamic_term
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
 is_trend_dynamic_term
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE

## Diagnostics

- effective sample size: 36
- design rank: 15
- df residual: 21
- missingness count: 0
- lead/lag sample loss: 2
- residual summary statistics: min=-0.0436462758459009; q1=-0.0185396594466299; median=0.00072739960275598; mean=0; q3=0.0230903739230966; max=0.0452648962448017; sd=0.0261163588240283
- condition number warning: WARN_HIGH_CONDITION_NUMBER_323711.77

## Warnings

- large coefficient magnitude: Review no-trend magnitude stability
- large coefficient magnitude: Review no-trend magnitude stability
- condition number warning: Review no-trend collinearity diagnostics

## Trend-included diagnostic comparison

- (Intercept): TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_nrc_log: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- omega_nfc: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log_x_omega: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_nrc_log_x_omega: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)

## Restrictions

- No trend in preferred no-trend baseline.
- No q_omega-family variables.
- No FM-OLS/IM-OLS nonlinear baseline substitution.
- No cointRegD interacted baseline engine.
- No unrestricted DOLS interaction dynamics.
- No common-overlap sample equalization.

## Not-authorized uses

- final manuscript estimation
- productive-capacity reconstruction
- utilization reconstruction
- elasticity recovery

## Next D12G review action

D12G may review preliminary no-trend robustness results only. D12G is not final manuscript interpretation.
