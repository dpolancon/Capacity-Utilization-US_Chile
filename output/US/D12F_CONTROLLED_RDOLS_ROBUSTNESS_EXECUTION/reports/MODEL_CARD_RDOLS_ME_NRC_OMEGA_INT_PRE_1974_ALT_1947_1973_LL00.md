# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_PRE_1974_ALT_1947_1973_LL00

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

pre_1974_alt_1947_1973

## Lead/lag grid

LL00

## Nominal sample

1947-1973

## Complete-case sample

1947-1973

## Effective sample

1948 1973 n = 26

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role      estimate    std_error      t_value
       (Intercept)    deterministic -6.706705e+01  71.17561760 -0.942275568
          k_me_log   long_run_level -1.341571e+00   1.64712093 -0.814494750
         k_nrc_log   long_run_level  6.709409e+00   6.12159598  1.096022835
         omega_nfc   long_run_level  1.236655e+02 111.06002899  1.113501748
  k_me_log_x_omega   long_run_level  2.544535e+00   2.72868026  0.932514765
 k_nrc_log_x_omega   long_run_level -1.049336e+01   9.46899213 -1.108181021
             trend    deterministic  3.806318e-04   0.04117945  0.009243245
   p_value significance_stars
 0.3600626
 0.4273187
 0.2892924
 0.2819421
 0.3649298
 0.2841647
 0.9927393

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

- effective sample size: 26
- design rank: 10
- df residual: 16
- missingness count: 0
- lead/lag sample loss: 1
- residual summary statistics: min=-0.0614063227617582; q1=-0.00994358077071444; median=0.0025168155065085; mean=-7.83863836303297e-19; q3=0.0122954103739973; max=0.0294280733854634; sd=0.0193500269914448
- condition number warning: WARN_HIGH_CONDITION_NUMBER_1749919.25

## Warnings

- large coefficient magnitude: Review magnitude stability across windows and grids
- large coefficient magnitude: Review magnitude stability across windows and grids
- large coefficient magnitude: Review magnitude stability across windows and grids
- low degrees of freedom: Review low-df robustness candidate
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
