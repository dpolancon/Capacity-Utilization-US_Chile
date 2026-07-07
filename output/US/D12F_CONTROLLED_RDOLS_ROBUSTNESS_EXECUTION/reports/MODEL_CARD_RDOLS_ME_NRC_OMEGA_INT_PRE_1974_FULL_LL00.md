# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_PRE_1974_FULL_LL00

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

pre_1974_full

## Lead/lag grid

LL00

## Nominal sample

1929-1973

## Complete-case sample

1931-1973

## Effective sample

1932 1973 n = 42

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role     estimate   std_error    t_value
       (Intercept)    deterministic -25.09252828 29.17459867 -0.8600814
          k_me_log   long_run_level  -1.75563589  1.37471932 -1.2770868
         k_nrc_log   long_run_level   3.59522115  2.75191415  1.3064438
         omega_nfc   long_run_level  55.54725941 45.89186839  1.2103944
  k_me_log_x_omega   long_run_level   2.58677904  2.07551440  1.2463315
 k_nrc_log_x_omega   long_run_level  -5.55326242  4.34555943 -1.2779166
             trend    deterministic   0.06517106  0.02078247  3.1358668
     p_value significance_stars
 0.396142351
 0.210760726
 0.200714116
 0.234992480
 0.221689723
 0.210471614
 0.003660565                ***

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

- effective sample size: 42
- design rank: 10
- df residual: 32
- missingness count: 0
- lead/lag sample loss: 1
- residual summary statistics: min=-0.117463919298747; q1=-0.0423256225023911; median=0.00698816121316592; mean=1.75537494592891e-19; q3=0.031964063088781; max=0.117847059399545; sd=0.0578878410367902
- condition number warning: WARN_HIGH_CONDITION_NUMBER_300572.68

## Warnings

- large coefficient magnitude: Review magnitude stability across windows and grids
- large coefficient magnitude: Review magnitude stability across windows and grids
- p-value threshold crossing: Review preliminary significance pattern
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
