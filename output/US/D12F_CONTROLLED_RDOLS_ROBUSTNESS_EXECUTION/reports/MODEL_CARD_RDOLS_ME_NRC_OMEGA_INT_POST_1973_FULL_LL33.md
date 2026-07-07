# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_LL33

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

LL33

## Nominal sample

1974-2024

## Complete-case sample

1974-2024

## Effective sample

1978 2021 n = 44

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role     estimate   std_error    t_value
       (Intercept)    deterministic  18.20866130 30.90056193  0.5892663
          k_me_log   long_run_level  -0.29353124  0.51533219 -0.5695962
         k_nrc_log   long_run_level  -0.28726756  1.98871976 -0.1444485
         omega_nfc   long_run_level -22.10575878 49.09066048 -0.4503048
  k_me_log_x_omega   long_run_level   0.08106863  0.47682631  0.1700171
 k_nrc_log_x_omega   long_run_level   1.45153144  3.18321946  0.4559948
             trend    deterministic   0.05046530  0.04017703  1.2560735
   p_value significance_stars
 0.5639111
 0.5768620
 0.8869502
 0.6585324
 0.8671279
 0.6545219
 0.2271214

## Auxiliary dynamic terms

Auxiliary coefficients are hidden by default and are estimator-correction terms only.

                term                   coefficient_role shown_by_default
    d_k_me_log_lead1 restricted_base_difference_dynamic            FALSE
    d_k_me_log_lead2 restricted_base_difference_dynamic            FALSE
    d_k_me_log_lead3 restricted_base_difference_dynamic            FALSE
  d_k_me_log_current restricted_base_difference_dynamic            FALSE
     d_k_me_log_lag1 restricted_base_difference_dynamic            FALSE
     d_k_me_log_lag2 restricted_base_difference_dynamic            FALSE
     d_k_me_log_lag3 restricted_base_difference_dynamic            FALSE
   d_k_nrc_log_lead1 restricted_base_difference_dynamic            FALSE
   d_k_nrc_log_lead2 restricted_base_difference_dynamic            FALSE
   d_k_nrc_log_lead3 restricted_base_difference_dynamic            FALSE
 d_k_nrc_log_current restricted_base_difference_dynamic            FALSE
    d_k_nrc_log_lag1 restricted_base_difference_dynamic            FALSE
    d_k_nrc_log_lag2 restricted_base_difference_dynamic            FALSE
    d_k_nrc_log_lag3 restricted_base_difference_dynamic            FALSE
   d_omega_nfc_lead1 restricted_base_difference_dynamic            FALSE
   d_omega_nfc_lead2 restricted_base_difference_dynamic            FALSE
   d_omega_nfc_lead3 restricted_base_difference_dynamic            FALSE
 d_omega_nfc_current restricted_base_difference_dynamic            FALSE
    d_omega_nfc_lag1 restricted_base_difference_dynamic            FALSE
    d_omega_nfc_lag2 restricted_base_difference_dynamic            FALSE
    d_omega_nfc_lag3 restricted_base_difference_dynamic            FALSE
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
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE
                            TRUE                       FALSE

## Diagnostics

- effective sample size: 44
- design rank: 28
- df residual: 16
- missingness count: 0
- lead/lag sample loss: 7
- residual summary statistics: min=-0.0210735509137407; q1=-0.00999235319408786; median=-0.00161092371965473; mean=-4.45077312284532e-20; q3=0.00675279457227926; max=0.0314009652161651; sd=0.0125831330974928
- condition number warning: WARN_HIGH_CONDITION_NUMBER_1894628.51

## Warnings

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
