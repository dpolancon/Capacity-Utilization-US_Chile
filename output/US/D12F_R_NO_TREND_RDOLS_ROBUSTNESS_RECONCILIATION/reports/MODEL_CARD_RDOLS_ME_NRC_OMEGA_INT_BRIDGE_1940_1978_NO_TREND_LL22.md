# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_BRIDGE_1940_1978_NO_TREND_LL22

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

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term        coefficient_role   estimate  std_error   t_value
       (Intercept) deterministic_intercept -88.145898  87.899692 -1.002801
          k_me_log          long_run_level  -2.369650   1.869599 -1.267464
         k_nrc_log          long_run_level   8.734447   7.332376  1.191216
         omega_nfc          long_run_level 155.911947 138.721205  1.123923
  k_me_log_x_omega          long_run_level   4.100816   2.939396  1.395122
 k_nrc_log_x_omega          long_run_level -13.577355  11.567604 -1.173740
   p_value significance_stars
 0.3342581
 0.2272230
 0.2548640
 0.2813719
 0.1863572
 0.2615551

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

## Diagnostics

- effective sample size: 34
- design rank: 21
- df residual: 13
- missingness count: 0
- lead/lag sample loss: 4
- residual summary statistics: min=-0.063757287985302; q1=-0.0145636436611999; median=0.00239502760019408; mean=-8.79542507742761e-19; q3=0.0148957777492928; max=0.035988704587174; sd=0.0209119510712959
- condition number warning: WARN_HIGH_CONDITION_NUMBER_523808.03

## Warnings

- large coefficient magnitude: Review no-trend magnitude stability
- large coefficient magnitude: Review no-trend magnitude stability
- large coefficient magnitude: Review no-trend magnitude stability
- low degrees of freedom: Review low-df no-trend candidate
- condition number warning: Review no-trend collinearity diagnostics
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity

## Trend-included diagnostic comparison

- (Intercept): MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log: SIGN_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_nrc_log: MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- omega_nfc: MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log_x_omega: MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_nrc_log_x_omega: MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)

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
