# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_BRIDGE_1940_1978_LL11

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

LL11

## Nominal sample

1940-1978

## Complete-case sample

1940-1978

## Effective sample

1942 1977 n = 36

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role     estimate  std_error    t_value
       (Intercept)    deterministic -65.04002999 54.9399026 -1.1838396
          k_me_log   long_run_level  -1.44152578  1.2976880 -1.1108416
         k_nrc_log   long_run_level   6.65193964  4.6794015  1.4215364
         omega_nfc   long_run_level 117.63813954 86.5757486  1.3587886
  k_me_log_x_omega   long_run_level   2.69536035  2.0417009  1.3201544
 k_nrc_log_x_omega   long_run_level -10.08233348  7.3635844 -1.3692155
             trend    deterministic  -0.01422995  0.0309928 -0.4591372
   p_value significance_stars
 0.2503565
 0.2798133
 0.1705676
 0.1893418
 0.2016941
 0.1861129
 0.6510867

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

- effective sample size: 36
- design rank: 16
- df residual: 20
- missingness count: 0
- lead/lag sample loss: 3
- residual summary statistics: min=-0.0452047573745485; q1=-0.0164819072571546; median=0.000567070024390545; mean=6.99272755344383e-19; q3=0.024438023293657; max=0.0456876767045996; sd=0.0259797996835695
- condition number warning: WARN_HIGH_CONDITION_NUMBER_1116001.95

## Warnings

- large coefficient magnitude: Review magnitude stability across windows and grids
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
