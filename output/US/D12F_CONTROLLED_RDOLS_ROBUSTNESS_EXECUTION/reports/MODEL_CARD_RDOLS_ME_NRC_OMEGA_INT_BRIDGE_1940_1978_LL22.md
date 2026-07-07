# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_BRIDGE_1940_1978_LL22

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

LL22

## Nominal sample

1940-1978

## Complete-case sample

1940-1978

## Effective sample

1943 1976 n = 34

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role    estimate   std_error     t_value
       (Intercept)    deterministic -6.24425725  86.6854085 -0.07203354
          k_me_log   long_run_level  0.03795959   2.0002361  0.01897755
         k_nrc_log   long_run_level  2.32932880   7.1454850  0.32598610
         omega_nfc   long_run_level 17.81075734 138.6743802  0.12843582
  k_me_log_x_omega   long_run_level  1.31986913   2.9075112  0.45395151
 k_nrc_log_x_omega   long_run_level -2.37393811  11.4966582 -0.20648941
             trend    deterministic -0.14060521   0.0656136 -2.14292778
    p_value significance_stars
 0.94376188
 0.98517090
 0.75004941
 0.89993151
 0.65796462
 0.83987070
 0.05331192                  *

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

- effective sample size: 34
- design rank: 22
- df residual: 12
- missingness count: 0
- lead/lag sample loss: 5
- residual summary statistics: min=-0.0508653944179059; q1=-0.00939494273968211; median=0.00358440731597969; mean=-1.05430689199418e-19; q3=0.012695923881256; max=0.0237707524523739; sd=0.0177841852160721
- condition number warning: WARN_HIGH_CONDITION_NUMBER_2012418.25

## Warnings

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
