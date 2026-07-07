# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_NO_TREND_LL22

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

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term        coefficient_role    estimate  std_error    t_value
       (Intercept) deterministic_intercept  36.1164440 19.5753182  1.8449991
          k_me_log          long_run_level   0.4648028  0.2596412  1.7901734
         k_nrc_log          long_run_level  -1.8428221  1.2284841 -1.5000782
         omega_nfc          long_run_level -39.4512151 32.2615144 -1.2228569
  k_me_log_x_omega          long_run_level  -0.2232860  0.3995673 -0.5588193
 k_nrc_log_x_omega          long_run_level   2.9495224  2.0601991  1.4316686
    p_value significance_stars
 0.07691683                  *
 0.08554602                  *
 0.14611832
 0.23278679
 0.58125660
 0.16462288

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

- effective sample size: 46
- design rank: 21
- df residual: 25
- missingness count: 0
- lead/lag sample loss: 4
- residual summary statistics: min=-0.0310260542261733; q1=-0.0128896582553259; median=-0.00115232020893574; mean=5.84821008799926e-20; q3=0.00997317015473368; max=0.037719261837664; sd=0.0184738074202812
- condition number warning: WARN_HIGH_CONDITION_NUMBER_234010.78

## Warnings

- large coefficient magnitude: Review no-trend magnitude stability
- p-value threshold crossing: Review preliminary no-trend p-value pattern
- p-value threshold crossing: Review preliminary no-trend p-value pattern
- large coefficient magnitude: Review no-trend magnitude stability
- condition number warning: Review no-trend collinearity diagnostics
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity

## Trend-included diagnostic comparison

- (Intercept): MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log: MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_nrc_log: MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- omega_nfc: MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log_x_omega: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
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
