# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_FORDIST_CORE_LL11

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

fordist_core

## Lead/lag grid

LL11

## Nominal sample

1945-1973

## Complete-case sample

1945-1973

## Effective sample

1947 1972 n = 26

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role    estimate   std_error     t_value
       (Intercept)    deterministic  28.0431088 53.24710896  0.52665974
          k_me_log   long_run_level  -0.4632843  1.12271607 -0.41264600
         k_nrc_log   long_run_level  -1.4758918  4.58816306 -0.32167380
         omega_nfc   long_run_level -20.9414561 82.38419711 -0.25419263
  k_me_log_x_omega   long_run_level   0.1178218  1.92776601  0.06111833
 k_nrc_log_x_omega   long_run_level   1.5505406  7.00437344  0.22136750
             trend    deterministic   0.1432262  0.04533799  3.15907662
    p_value significance_stars
 0.60991233
 0.68857373
 0.75432283
 0.80449716
 0.95246924
 0.82926113
 0.01017476                 **

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

## Diagnostics

- effective sample size: 26
- design rank: 16
- df residual: 10
- missingness count: 0
- lead/lag sample loss: 3
- residual summary statistics: min=-0.0162432409257175; q1=-0.00820862306878666; median=0.000530927657018634; mean=-1.41951319593223e-19; q3=0.00895429750528514; max=0.0152118211746376; sd=0.0098530285021162
- condition number warning: WARN_HIGH_CONDITION_NUMBER_1988338.27

## Warnings

- large coefficient magnitude: Review magnitude stability across windows and grids
- large coefficient magnitude: Review magnitude stability across windows and grids
- p-value threshold crossing: Review preliminary significance pattern
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
