# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_LL00

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

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role      estimate   std_error    t_value
       (Intercept)    deterministic  45.542556113 16.67701310  2.7308581
          k_me_log   long_run_level   0.372595518  0.24826927  1.5007718
         k_nrc_log   long_run_level  -2.380546250  1.10584979 -2.1526850
         omega_nfc   long_run_level -55.203324941 24.61257456 -2.2428911
  k_me_log_x_omega   long_run_level  -0.127852963  0.35635896 -0.3587758
 k_nrc_log_x_omega   long_run_level   3.869029987  1.61362981  2.3977185
             trend    deterministic   0.002712264  0.01343164  0.2019310
     p_value significance_stars
 0.009350859                ***
 0.141267591
 0.037429895                 **
 0.030512101                 **
 0.721649668
 0.021255803                 **
 0.840994177

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

## Diagnostics

- effective sample size: 50
- design rank: 10
- df residual: 40
- missingness count: 0
- lead/lag sample loss: 1
- residual summary statistics: min=-0.0522945030941211; q1=-0.0212978727009615; median=-0.00460533386033036; mean=3.98850874203105e-19; q3=0.02396132638626; max=0.0669814363357509; sd=0.0272035449980269
- condition number warning: WARN_HIGH_CONDITION_NUMBER_713375.39

## Warnings

- large coefficient magnitude: Review magnitude stability across windows and grids
- p-value threshold crossing: Review preliminary significance pattern
- p-value threshold crossing: Review preliminary significance pattern
- large coefficient magnitude: Review magnitude stability across windows and grids
- p-value threshold crossing: Review preliminary significance pattern
- p-value threshold crossing: Review preliminary significance pattern
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
