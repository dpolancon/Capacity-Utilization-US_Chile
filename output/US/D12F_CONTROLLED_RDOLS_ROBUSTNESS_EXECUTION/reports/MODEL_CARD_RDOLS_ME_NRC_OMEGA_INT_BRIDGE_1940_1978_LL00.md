# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_BRIDGE_1940_1978_LL00

## Status

CONTROLLED_PRELIMINARY
DESIGN_STAGE_PRELIMINARY_ONLY
NOT FINAL MANUSCRIPT ESTIMATION
q_omega PARKED
FM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE
IM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE
RESTRICTED DOLS DYNAMIC CORRECTIONS APPLY ONLY TO BASE-VARIABLE FIRST DIFFERENCES
MAXIMAL FEASIBLE EFFECTIVE SAMPLE USED

## Estimator

RESTRICTED_DOLS

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

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role     estimate   std_error    t_value
       (Intercept)    deterministic -45.92357906 45.03412259 -1.0197507
          k_me_log   long_run_level  -0.95298285  1.11837537 -0.8521136
         k_nrc_log   long_run_level   4.99765221  3.89042658  1.2846026
         omega_nfc   long_run_level  88.05401479 70.67719099  1.2458618
  k_me_log_x_omega   long_run_level   1.91150145  1.79951803  1.0622297
 k_nrc_log_x_omega   long_run_level  -7.52742643  6.08872932 -1.2362886
             trend    deterministic  -0.01135179  0.01690315 -0.6715785
   p_value significance_stars
 0.3165774
 0.4013809
 0.2094578
 0.2231394
 0.2972077
 0.2266220
 0.5073555

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

## Diagnostics

- effective sample size: 38
- design rank: 10
- df residual: 28
- missingness count: 0
- lead/lag sample loss: 1
- residual summary statistics: min=-0.070956078355713; q1=-0.0194496032357713; median=-0.00254297823206305; mean=-8.44268945005365e-19; q3=0.0171134945977736; max=0.0724233330526836; sd=0.0301184372045285
- condition number warning: WARN_HIGH_CONDITION_NUMBER_931855.37

## Warnings

- large coefficient magnitude: Review magnitude stability across windows and grids
- large coefficient magnitude: Review magnitude stability across windows and grids
- condition number warning: Review collinearity diagnostics

## Restrictions

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

D12G may review preliminary robustness results only. D12G is not final manuscript interpretation.
