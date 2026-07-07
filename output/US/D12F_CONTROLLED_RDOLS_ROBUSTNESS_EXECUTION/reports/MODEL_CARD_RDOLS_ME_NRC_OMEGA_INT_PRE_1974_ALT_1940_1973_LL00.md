# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_PRE_1974_ALT_1940_1973_LL00

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

pre_1974_alt_1940_1973

## Lead/lag grid

LL00

## Nominal sample

1940-1973

## Complete-case sample

1940-1973

## Effective sample

1941 1973 n = 33

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role     estimate    std_error    t_value
       (Intercept)    deterministic -49.29525166  67.68762114 -0.7282757
          k_me_log   long_run_level  -0.81761138   1.94715291 -0.4199010
         k_nrc_log   long_run_level   5.21169914   5.95596240  0.8750390
         omega_nfc   long_run_level  93.71398832 105.38042611  0.8892922
  k_me_log_x_omega   long_run_level   1.76731971   3.10248843  0.5696459
 k_nrc_log_x_omega   long_run_level  -7.88376464   9.24345172 -0.8529027
             trend    deterministic  -0.01698633   0.02139472 -0.7939499
   p_value significance_stars
 0.4737950
 0.6784544
 0.3905992
 0.3830532
 0.5744401
 0.4025082
 0.4353401

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

- effective sample size: 33
- design rank: 10
- df residual: 23
- missingness count: 0
- lead/lag sample loss: 1
- residual summary statistics: min=-0.0622612183956719; q1=-0.0215669820101406; median=-0.000689197583269075; mean=-1.07763125022802e-18; q3=0.0160254603090227; max=0.0641725986846049; sd=0.0297576507350549
- condition number warning: WARN_HIGH_CONDITION_NUMBER_1224940.79

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
