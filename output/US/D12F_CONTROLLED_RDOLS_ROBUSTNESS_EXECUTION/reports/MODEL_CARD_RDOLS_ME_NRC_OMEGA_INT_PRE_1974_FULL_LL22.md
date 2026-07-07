# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_PRE_1974_FULL_LL22

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

pre_1974_full

## Lead/lag grid

LL22

## Nominal sample

1929-1973

## Complete-case sample

1931-1973

## Effective sample

1934 1971 n = 38

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role    estimate   std_error     t_value
       (Intercept)    deterministic  7.97843177  64.4136217  0.12386249
          k_me_log   long_run_level -0.48759296   1.8996065 -0.25668104
         k_nrc_log   long_run_level  0.36025632   5.5959074  0.06437854
         omega_nfc   long_run_level  7.39533003 102.6905340  0.07201569
  k_me_log_x_omega   long_run_level  0.36713477   2.9987048  0.12243112
 k_nrc_log_x_omega   long_run_level -0.82659393   8.9260524 -0.09260465
             trend    deterministic  0.09298973   0.0411375  2.26046162
    p_value significance_stars
 0.90296684
 0.80069639
 0.94946630
 0.94348196
 0.90408220
 0.92736727
 0.03808683                 **

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

- effective sample size: 38
- design rank: 22
- df residual: 16
- missingness count: 0
- lead/lag sample loss: 5
- residual summary statistics: min=-0.0745999641526801; q1=-0.0177837521962924; median=0.00262758103834612; mean=0; q3=0.0235386744314547; max=0.0616101158521427; sd=0.0325783734313499
- condition number warning: WARN_HIGH_CONDITION_NUMBER_838197.45

## Warnings

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
