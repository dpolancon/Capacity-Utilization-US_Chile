# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_PRE_1974_ALT_1947_1973_NO_TREND_LL00

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

pre_1974_alt_1947_1973

## Lead/lag grid

LL00

## Nominal sample

1947-1973

## Complete-case sample

1947-1973

## Effective sample

1948 1973 n = 26

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term        coefficient_role   estimate std_error    t_value
       (Intercept) deterministic_intercept -67.504452 51.578748 -1.3087648
          k_me_log          long_run_level  -1.348745  1.409457 -0.9569248
         k_nrc_log          long_run_level   6.746880  4.449967  1.5161641
         omega_nfc          long_run_level 124.338191 81.391008  1.5276649
  k_me_log_x_omega          long_run_level   2.558496  2.204661  1.1604939
 k_nrc_log_x_omega          long_run_level -10.549891  7.012860 -1.5043635
   p_value significance_stars
 0.2080312
 0.3520169
 0.1478518
 0.1449874
 0.2618860
 0.1508396

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

- effective sample size: 26
- design rank: 9
- df residual: 17
- missingness count: 0
- lead/lag sample loss: 0
- residual summary statistics: min=-0.0614022361577594; q1=-0.00987596774082574; median=0.00244988289051816; mean=7.00333356427911e-19; q3=0.0122758877648537; max=0.0294334911202205; sd=0.0193500786544817
- condition number warning: WARN_HIGH_CONDITION_NUMBER_384299.08

## Warnings

- large coefficient magnitude: Review no-trend magnitude stability
- large coefficient magnitude: Review no-trend magnitude stability
- large coefficient magnitude: Review no-trend magnitude stability
- low degrees of freedom: Review low-df no-trend candidate
- condition number warning: Review no-trend collinearity diagnostics

## Trend-included diagnostic comparison

- (Intercept): TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
- k_me_log: TREND_INSENSITIVE (DESIGN_STAGE_PRELIMINARY_ONLY)
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
