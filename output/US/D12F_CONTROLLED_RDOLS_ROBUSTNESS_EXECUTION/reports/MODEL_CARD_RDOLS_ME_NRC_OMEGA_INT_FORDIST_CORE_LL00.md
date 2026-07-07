# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_FORDIST_CORE_LL00

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

LL00

## Nominal sample

1945-1973

## Complete-case sample

1945-1973

## Effective sample

1946 1973 n = 28

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role     estimate   std_error      t_value
       (Intercept)    deterministic  5.781121641 59.96599737  0.096406662
          k_me_log   long_run_level -0.008425908  1.54796271 -0.005443224
         k_nrc_log   long_run_level  0.607740513  5.25296663  0.115694722
         omega_nfc   long_run_level  8.398076051 92.74446178  0.090550701
  k_me_log_x_omega   long_run_level  0.279633963  2.54550042  0.109854220
 k_nrc_log_x_omega   long_run_level -0.900255869  8.05273234 -0.111795082
             trend    deterministic  0.020160924  0.04186784  0.481537216
   p_value significance_stars
 0.9242629
 0.9957168
 0.9091754
 0.9288496
 0.9137405
 0.9122231
 0.6359370

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

- effective sample size: 28
- design rank: 10
- df residual: 18
- missingness count: 0
- lead/lag sample loss: 1
- residual summary statistics: min=-0.0613201824109682; q1=-0.0101705745875274; median=0.0040959505011662; mean=-1.24075201184411e-19; q3=0.0118469027039655; max=0.0412989749243095; sd=0.0209892455580844
- condition number warning: WARN_HIGH_CONDITION_NUMBER_1409937.82

## Warnings

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
