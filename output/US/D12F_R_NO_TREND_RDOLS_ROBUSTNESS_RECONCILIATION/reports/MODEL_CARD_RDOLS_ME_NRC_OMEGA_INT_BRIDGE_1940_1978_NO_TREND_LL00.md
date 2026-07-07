# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_BRIDGE_1940_1978_NO_TREND_LL00

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

LL00

## Nominal sample

1940-1978

## Complete-case sample

1940-1978

## Effective sample

1941 1978 n = 38

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term        coefficient_role    estimate std_error    t_value
       (Intercept) deterministic_intercept -31.9239972 39.539338 -0.8073984
          k_me_log          long_run_level  -0.7729076  1.075430 -0.7186964
         k_nrc_log          long_run_level   3.8295848  3.446890  1.1110262
         omega_nfc          long_run_level  66.6082909 62.452146  1.0665493
  k_me_log_x_omega          long_run_level   1.5447686  1.698355  0.9095676
 k_nrc_log_x_omega          long_run_level  -5.7675282  5.443675 -1.0594917
   p_value significance_stars
 0.4260101
 0.4780792
 0.2756840
 0.2949745
 0.3705486
 0.2981211

## Auxiliary dynamic terms

Auxiliary coefficients are hidden by default and are estimator-correction terms only.

                term                   coefficient_role shown_by_default
  d_k_me_log_current restricted_base_difference_dynamic            FALSE
 d_k_nrc_log_current restricted_base_difference_dynamic            FALSE
 d_omega_nfc_current restricted_base_difference_dynamic            FALSE
 is_dynamic_base_difference_term is_interaction_dynamic_term
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
 is_trend_dynamic_term
                 FALSE
                 FALSE
                 FALSE

## Diagnostics

- effective sample size: 38
- design rank: 9
- df residual: 29
- missingness count: 0
- lead/lag sample loss: 0
- residual summary statistics: min=-0.0777277986450705; q1=-0.0182268790908862; median=-0.00220683274020908; mean=1.47829539636593e-19; q3=0.0185023927014816; max=0.0766423584235754; sd=0.0303600386793127
- condition number warning: WARN_HIGH_CONDITION_NUMBER_242265.8

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
