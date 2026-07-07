# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_PRE_1974_FULL_NO_TREND_LL00

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

pre_1974_full

## Lead/lag grid

LL00

## Nominal sample

1929-1973

## Complete-case sample

1931-1973

## Effective sample

1932 1973 n = 42

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term        coefficient_role   estimate std_error     t_value
       (Intercept) deterministic_intercept -0.5089186 31.640031 -0.01608464
          k_me_log          long_run_level  0.2673211  1.366815  0.19557953
         k_nrc_log          long_run_level  1.0684189  2.962627  0.36063230
         omega_nfc          long_run_level 12.1552839 49.265639  0.24672945
  k_me_log_x_omega          long_run_level -0.1380659  2.122202 -0.06505789
 k_nrc_log_x_omega          long_run_level -1.0163928  4.613612 -0.22030307
   p_value significance_stars
 0.9872637
 0.8461386
 0.7206726
 0.8066461
 0.9485204
 0.8269924

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

- effective sample size: 42
- design rank: 9
- df residual: 33
- missingness count: 0
- lead/lag sample loss: 0
- residual summary statistics: min=-0.191202797669719; q1=-0.0324807687934235; median=0.00916588530370395; mean=-9.33349638069739e-20; q3=0.0407908703111923; max=0.124571139766579; sd=0.0661873964638875
- condition number warning: PASS_CONDITION_NUMBER_88959.73

## Warnings

- large coefficient magnitude: Review no-trend magnitude stability
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
- k_me_log_x_omega: SIGN_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
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
