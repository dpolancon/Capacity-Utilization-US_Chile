# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_NO_TREND_LL33

## Status

CONTROLLED_PRELIMINARY
DESIGN_STAGE_PRELIMINARY_ONLY
NOT FINAL MANUSCRIPT ESTIMATION
NO PRODUCTIVE-CAPACITY RECONSTRUCTION
NO UTILIZATION RECONSTRUCTION
NO ELASTICITY RECOVERY

CONTROLLED_PRELIMINARY
NOT FINAL MANUSCRIPT ESTIMATION
NO-TREND BASELINE CONTRACT
D12F TREND-INCLUDED RESULTS RECLASSIFIED AS DIAGNOSTIC COMPARATOR
q_omega PARKED
FM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE
IM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE
RESTRICTED DOLS DYNAMIC CORRECTIONS APPLY ONLY TO BASE-VARIABLE FIRST DIFFERENCES
MAXIMAL FEASIBLE EFFECTIVE SAMPLE USED

## Estimator

RESTRICTED_DOLS

## No-trend contract

NO_TREND_BASELINE_RULE: intercept allowed; linear deterministic trend blocked.

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

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term        coefficient_role    estimate  std_error    t_value
       (Intercept) deterministic_intercept  25.7858382 30.8166653  0.8367498
          k_me_log          long_run_level   0.2034698  0.3357236  0.6060634
         k_nrc_log          long_run_level  -0.9292297  1.9543094 -0.4754773
         omega_nfc          long_run_level -20.7629501 49.9059915 -0.4160412
  k_me_log_x_omega          long_run_level   0.1671552  0.4798261  0.3483661
 k_nrc_log_x_omega          long_run_level   1.3701565  3.2361857  0.4233862
   p_value significance_stars
 0.4143413
 0.5524799
 0.6404990
 0.6825847
 0.7318420
 0.6773215

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
 is_trend_dynamic_term
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE
                 FALSE

## Diagnostics

- effective sample size: 44
- design rank: 27
- df residual: 17
- missingness count: 0
- lead/lag sample loss: 6
- residual summary statistics: min=-0.0214008164404026; q1=-0.00930973125058505; median=-0.00140508658925823; mean=-3.49901610211231e-19; q3=0.00747613299460912; max=0.0357099931849859; sd=0.0131889456213449
- condition number warning: WARN_HIGH_CONDITION_NUMBER_421070.67

## Warnings

- large coefficient magnitude: Review no-trend magnitude stability
- large coefficient magnitude: Review no-trend magnitude stability
- low degrees of freedom: Review low-df no-trend candidate
- condition number warning: Review no-trend collinearity diagnostics
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity

## Trend-included diagnostic comparison

- (Intercept): TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log: SIGN_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_nrc_log: MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- omega_nfc: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log_x_omega: MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_nrc_log_x_omega: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)

## Restrictions

- No trend in preferred no-trend baseline.
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

D12G may review preliminary no-trend robustness results only. D12G is not final manuscript interpretation.
