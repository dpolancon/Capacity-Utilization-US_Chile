# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_PRE_1974_FULL_LL11

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

LL11

## Nominal sample

1929-1973

## Complete-case sample

1931-1973

## Effective sample

1933 1972 n = 40

## Maximal feasible effective sample rule

PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE

## Specification

y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role     estimate   std_error   t_value
       (Intercept)    deterministic -44.17724144 36.47167434 -1.211275
          k_me_log   long_run_level  -2.32812568  1.33659375 -1.741835
         k_nrc_log   long_run_level   5.20034586  3.29193259  1.579724
         omega_nfc   long_run_level  87.46626186 57.43129602  1.522972
  k_me_log_x_omega   long_run_level   3.43205637  2.07676485  1.652597
 k_nrc_log_x_omega   long_run_level  -8.23357780  5.18308178 -1.588549
             trend    deterministic   0.07158611  0.02170087  3.298766
     p_value significance_stars
 0.237582281
 0.094341478                  *
 0.127260831
 0.140834534
 0.111437036
 0.125250680
 0.003020981                ***

## Auxiliary dynamic terms

Auxiliary coefficients are hidden by default and are estimator-correction terms only.

                term                   coefficient_role shown_by_default
    d_k_me_log_lead1 restricted_base_difference_dynamic            FALSE
  d_k_me_log_current restricted_base_difference_dynamic            FALSE
     d_k_me_log_lag1 restricted_base_difference_dynamic            FALSE
   d_k_nrc_log_lead1 restricted_base_difference_dynamic            FALSE
 d_k_nrc_log_current restricted_base_difference_dynamic            FALSE
    d_k_nrc_log_lag1 restricted_base_difference_dynamic            FALSE
   d_omega_nfc_lead1 restricted_base_difference_dynamic            FALSE
 d_omega_nfc_current restricted_base_difference_dynamic            FALSE
    d_omega_nfc_lag1 restricted_base_difference_dynamic            FALSE
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

## Diagnostics

- effective sample size: 40
- design rank: 16
- df residual: 24
- missingness count: 0
- lead/lag sample loss: 3
- residual summary statistics: min=-0.101473917160177; q1=-0.0230359046289289; median=0.00262847654237619; mean=6.50521303491303e-19; q3=0.0240276228233694; max=0.0737557572602479; sd=0.0398356616643005
- condition number warning: WARN_HIGH_CONDITION_NUMBER_472114.07

## Warnings

- large coefficient magnitude: Review magnitude stability across windows and grids
- p-value threshold crossing: Review preliminary significance pattern
- large coefficient magnitude: Review magnitude stability across windows and grids
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
