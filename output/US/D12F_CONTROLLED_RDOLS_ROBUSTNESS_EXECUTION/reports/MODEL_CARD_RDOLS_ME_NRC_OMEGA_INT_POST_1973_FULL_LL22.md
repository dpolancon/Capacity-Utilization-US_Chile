# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_LL22

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

LL22

## Nominal sample

1974-2024

## Complete-case sample

1974-2024

## Effective sample

1977 2022 n = 46

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role     estimate   std_error    t_value
       (Intercept)    deterministic  16.61737583 25.42154916  0.6536728
          k_me_log   long_run_level   0.17409996  0.35520541  0.4901388
         k_nrc_log   long_run_level  -0.47257103  1.67763210 -0.2816893
         omega_nfc   long_run_level -15.86290888 37.65621037 -0.4212561
  k_me_log_x_omega   long_run_level  -0.28857012  0.40010513 -0.7212357
 k_nrc_log_x_omega   long_run_level   1.37714996  2.43445616  0.5656910
             trend    deterministic   0.03174093  0.02671182  1.1882728
   p_value significance_stars
 0.5195370
 0.6284866
 0.7805964
 0.6773169
 0.4777322
 0.5768550
 0.2463521

## Auxiliary dynamic terms

Auxiliary coefficients are hidden by default and are estimator-correction terms only.

                term                   coefficient_role shown_by_default
    d_k_me_log_lead1 restricted_base_difference_dynamic            FALSE
    d_k_me_log_lead2 restricted_base_difference_dynamic            FALSE
  d_k_me_log_current restricted_base_difference_dynamic            FALSE
     d_k_me_log_lag1 restricted_base_difference_dynamic            FALSE
     d_k_me_log_lag2 restricted_base_difference_dynamic            FALSE
   d_k_nrc_log_lead1 restricted_base_difference_dynamic            FALSE
   d_k_nrc_log_lead2 restricted_base_difference_dynamic            FALSE
 d_k_nrc_log_current restricted_base_difference_dynamic            FALSE
    d_k_nrc_log_lag1 restricted_base_difference_dynamic            FALSE
    d_k_nrc_log_lag2 restricted_base_difference_dynamic            FALSE
   d_omega_nfc_lead1 restricted_base_difference_dynamic            FALSE
   d_omega_nfc_lead2 restricted_base_difference_dynamic            FALSE
 d_omega_nfc_current restricted_base_difference_dynamic            FALSE
    d_omega_nfc_lag1 restricted_base_difference_dynamic            FALSE
    d_omega_nfc_lag2 restricted_base_difference_dynamic            FALSE
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
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE

## Diagnostics

- effective sample size: 46
- design rank: 22
- df residual: 24
- missingness count: 0
- lead/lag sample loss: 5
- residual summary statistics: min=-0.0293309023603207; q1=-0.0155994554304646; median=-0.00149775924887456; mean=-1.56295992528141e-19; q3=0.0110147788142984; max=0.0364355907847167; sd=0.0179532333393883
- condition number warning: WARN_HIGH_CONDITION_NUMBER_1277189.63

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
