# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_LL11

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

post_1973_full

## Lead/lag grid

LL11

## Nominal sample

1974-2024

## Complete-case sample

1974-2024

## Effective sample

1976 2023 n = 48

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role     estimate   std_error    t_value
       (Intercept)    deterministic  33.92050922 18.59958490  1.8237240
          k_me_log   long_run_level   0.37633301  0.23820972  1.5798390
         k_nrc_log   long_run_level  -1.67071258  1.23014910 -1.3581383
         omega_nfc   long_run_level -38.68265429 27.75373732 -1.3937818
  k_me_log_x_omega   long_run_level  -0.27044345  0.32858857 -0.8230458
 k_nrc_log_x_omega   long_run_level   2.90097264  1.81708484  1.5964982
             trend    deterministic   0.01090136  0.01555854  0.7006673
    p_value significance_stars
 0.07754606                  *
 0.12397909
 0.18391900
 0.17298818
 0.41657355
 0.12020735
 0.48857443

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

- effective sample size: 48
- design rank: 16
- df residual: 32
- missingness count: 0
- lead/lag sample loss: 3
- residual summary statistics: min=-0.037163701145679; q1=-0.0176748813756889; median=-0.00208517108373428; mean=6.95061119301091e-19; q3=0.0154318442384892; max=0.0420843125359315; sd=0.021241245028364
- condition number warning: WARN_HIGH_CONDITION_NUMBER_917824.34

## Warnings

- large coefficient magnitude: Review magnitude stability across windows and grids
- p-value threshold crossing: Review preliminary significance pattern
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
