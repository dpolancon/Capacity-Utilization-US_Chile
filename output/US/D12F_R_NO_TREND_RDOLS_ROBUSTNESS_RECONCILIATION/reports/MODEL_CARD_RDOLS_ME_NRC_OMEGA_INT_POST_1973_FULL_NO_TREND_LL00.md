# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_NO_TREND_LL00

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

LL00

## Nominal sample

1974-2024

## Complete-case sample

1974-2024

## Effective sample

1975 2024 n = 50

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term        coefficient_role    estimate  std_error    t_value
       (Intercept) deterministic_intercept  48.1389800 10.4955354  4.5866150
          k_me_log          long_run_level   0.3956742  0.2178048  1.8166461
         k_nrc_log          long_run_level  -2.5572908  0.6679188 -3.8287449
         omega_nfc          long_run_level -58.7579142 16.9997183 -3.4564052
  k_me_log_x_omega          long_run_level  -0.1219996  0.3509987 -0.3475786
 k_nrc_log_x_omega          long_run_level   4.1039581  1.1050029  3.7139797
      p_value significance_stars
 4.193205e-05                ***
 7.658681e-02                  *
 4.328558e-04                ***
 1.287792e-03                ***
 7.299348e-01
 6.086019e-04                ***

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

- effective sample size: 50
- design rank: 9
- df residual: 41
- missingness count: 0
- lead/lag sample loss: 0
- residual summary statistics: min=-0.0530193952647117; q1=-0.0209926755897154; median=-0.00424920849519315; mean=-1.6482244714032e-18; q3=0.0236994482714539; max=0.0693930105721802; sd=0.0272174071538604
- condition number warning: WARN_HIGH_CONDITION_NUMBER_107213.5

## Warnings

- large coefficient magnitude: Review no-trend magnitude stability
- p-value threshold crossing: Review preliminary no-trend p-value pattern
- p-value threshold crossing: Review preliminary no-trend p-value pattern
- p-value threshold crossing: Review preliminary no-trend p-value pattern
- large coefficient magnitude: Review no-trend magnitude stability
- p-value threshold crossing: Review preliminary no-trend p-value pattern
- p-value threshold crossing: Review preliminary no-trend p-value pattern
- condition number warning: Review no-trend collinearity diagnostics
- trend sensitivity relative to D12F: Review no-trend versus trend-included diagnostic sensitivity

## Trend-included diagnostic comparison

- (Intercept): TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log: SIGNIFICANCE_CHANGED_AFTER_TREND_REMOVAL (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_nrc_log: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- omega_nfc: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log_x_omega: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
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
