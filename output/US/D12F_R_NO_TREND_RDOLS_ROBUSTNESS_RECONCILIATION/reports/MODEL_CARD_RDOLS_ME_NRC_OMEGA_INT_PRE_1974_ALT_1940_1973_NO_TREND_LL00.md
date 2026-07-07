# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_PRE_1974_ALT_1940_1973_NO_TREND_LL00

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

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term        coefficient_role    estimate std_error    t_value
       (Intercept) deterministic_intercept -20.0684003 56.363110 -0.3560556
          k_me_log          long_run_level  -0.1858364  1.763396 -0.1053855
         k_nrc_log          long_run_level   2.6895764  4.999128  0.5380091
         omega_nfc          long_run_level  49.1261292 88.479825  0.5552241
  k_me_log_x_omega          long_run_level   0.6706152  2.756539  0.2432816
 k_nrc_log_x_omega          long_run_level  -4.0803418  7.844103 -0.5201795
   p_value significance_stars
 0.7249098
 0.9169458
 0.5955253
 0.5838800
 0.8098546
 0.6077040

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
 is_trend_dynamic_term
                 FALSE
                 FALSE
                 FALSE

## Diagnostics

- effective sample size: 33
- design rank: 9
- df residual: 24
- missingness count: 0
- lead/lag sample loss: 0
- residual summary statistics: min=-0.0684035350671715; q1=-0.018279737388528; median=-0.00401796106975696; mean=-8.28167213429091e-19; q3=0.0160906537949623; max=0.0711264860453892; sd=0.0301626754062437
- condition number warning: WARN_HIGH_CONDITION_NUMBER_309403.75

## Warnings

- large coefficient magnitude: Review no-trend magnitude stability
- large coefficient magnitude: Review no-trend magnitude stability
- condition number warning: Review no-trend collinearity diagnostics
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity

## Trend-included diagnostic comparison

- (Intercept): MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log: MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_nrc_log: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
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
