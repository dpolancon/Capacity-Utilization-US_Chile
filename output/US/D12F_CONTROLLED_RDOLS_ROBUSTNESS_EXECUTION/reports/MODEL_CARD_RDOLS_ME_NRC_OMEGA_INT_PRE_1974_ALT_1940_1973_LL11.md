# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_PRE_1974_ALT_1940_1973_LL11

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

LL11

## Nominal sample

1940-1973

## Complete-case sample

1940-1973

## Effective sample

1942 1972 n = 31

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role     estimate    std_error    t_value
       (Intercept)    deterministic -85.23371689  81.91028755 -1.0405740
          k_me_log   long_run_level  -1.54318720   2.20707152 -0.6992013
         k_nrc_log   long_run_level   8.27484464   7.12576972  1.1612563
         omega_nfc   long_run_level 150.91256298 127.85664188  1.1803263
  k_me_log_x_omega   long_run_level   2.95085269   3.51330686  0.8399075
 k_nrc_log_x_omega   long_run_level -12.76328851  11.08565618 -1.1513336
             trend    deterministic  -0.01785201   0.03841912 -0.4646648
   p_value significance_stars
 0.3145560
 0.4951264
 0.2636845
 0.2562502
 0.4141475
 0.2676172
 0.6488447

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

- effective sample size: 31
- design rank: 16
- df residual: 15
- missingness count: 0
- lead/lag sample loss: 3
- residual summary statistics: min=-0.0382429319063943; q1=-0.0191334978374167; median=-0.00140729857758035; mean=-3.36026167268819e-19; q3=0.0140209889320828; max=0.0487376318558015; sd=0.0248127184141328
- condition number warning: WARN_HIGH_CONDITION_NUMBER_1437327.43

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
