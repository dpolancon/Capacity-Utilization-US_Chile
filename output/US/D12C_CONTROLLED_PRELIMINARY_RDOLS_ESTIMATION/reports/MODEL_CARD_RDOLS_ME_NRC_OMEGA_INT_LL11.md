# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_LL11

## Status

CONTROLLED_PRELIMINARY

NOT FINAL MANUSCRIPT ESTIMATION

## Vault contract

- q_omega PARKED
- FM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE
- IM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE
- RESTRICTED DOLS DYNAMIC CORRECTIONS APPLY ONLY TO BASE-VARIABLE FIRST DIFFERENCES

## D12B authorization source

D12B terminal decision authorized controlled preliminary RDOLS estimation through D12C.

## Estimator

RESTRICTED_DOLS

## Model object

`RDOLS_ME_NRC_OMEGA_INT_LL11`

## Gates

                    model_id        boundary_gate        qomega_gate
 RDOLS_ME_NRC_OMEGA_INT_LL11 PASS_ME_NRC_BOUNDARY PASS_QOMEGA_PARKED
                             integration_order_gate
 PASS_CONTROLLED_PRELIMINARY_REOPENED_FROM_D11_D12B
                                   interaction_gate sample_survival_gate
 PASS_INTERACTION_LEVEL_ONLY_NO_DYNAMIC_CORRECTIONS PASS_SAMPLE_SURVIVAL
      rank_gate         overall_gate_status
 PASS_FULL_RANK PASS_CONTROLLED_PRELIMINARY

## Specification

Dependent variable: `y_log_nfc_gva`
Level base terms: `k_me_log; k_nrc_log; omega_nfc`
Interaction terms: `k_me_log_x_omega; k_nrc_log_x_omega`
Dynamic base terms: `k_me_log; k_nrc_log; omega_nfc`
Blocked dynamic terms: `k_me_log_x_omega; k_nrc_log_x_omega`

## Sample

       run_id                    model_id full_start full_end effective_start
 D12C_RUN_001 RDOLS_ME_NRC_OMEGA_INT_LL11       1931     2024            1933
 effective_end n_full n_effective n_lost_lead_lag n_lost_missing
          2023     94          91               3              3
        sample_status
 PASS_SAMPLE_SURVIVAL

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role estimate std_error t_value p_value
       (Intercept)    deterministic   2.2197    7.3285  0.3029  0.7628
          k_me_log   long_run_level  -0.1733    0.1503 -1.1527  0.2527
         k_nrc_log   long_run_level   0.8210    0.6041  1.3591  0.1782
         omega_nfc   long_run_level  10.6278   11.7697  0.9030  0.3694
  k_me_log_x_omega   long_run_level   0.3091    0.2261  1.3672  0.1756
 k_nrc_log_x_omega   long_run_level  -0.9039    0.9729 -0.9290  0.3558
             trend    deterministic   0.0282    0.0029  9.7262  0.0000

## Auxiliary dynamic terms

Auxiliary dynamic coefficients are hidden by default in the print method and are estimator-correction terms only.

                term                   coefficient_role estimate std_error
    d_k_me_log_lead1 restricted_base_difference_dynamic  -0.5771    0.2643
  d_k_me_log_current restricted_base_difference_dynamic   0.7745    0.3185
     d_k_me_log_lag1 restricted_base_difference_dynamic  -0.0298    0.2526
   d_k_nrc_log_lead1 restricted_base_difference_dynamic  -0.4260    0.3486
 d_k_nrc_log_current restricted_base_difference_dynamic  -0.9708    0.3399
    d_k_nrc_log_lag1 restricted_base_difference_dynamic  -0.4585    0.1843
   d_omega_nfc_lead1 restricted_base_difference_dynamic   2.4239    0.5215
 d_omega_nfc_current restricted_base_difference_dynamic   0.2424    0.4881
    d_omega_nfc_lag1 restricted_base_difference_dynamic  -0.3975    0.4932
 t_value p_value shown_by_default
 -2.1836  0.0321            FALSE
  2.4317  0.0174            FALSE
 -0.1181  0.9063            FALSE
 -1.2219  0.2256            FALSE
 -2.8565  0.0055            FALSE
 -2.4878  0.0151            FALSE
  4.6480  0.0000            FALSE
  0.4965  0.6210            FALSE
 -0.8060  0.4228            FALSE

## Diagnostics

- effective sample size: 91
- design rank: 16
- design columns: 16
- df residual: 75
- condition number: 213963.6379

## Restrictions

- No q_omega-family terms.
- No total-capital baseline terms.
- No FM-OLS/IM-OLS nonlinear baseline substitution.
- No unrestricted DOLS interaction dynamics.

## Not-authorized uses

- final manuscript estimation
- productive-capacity reconstruction
- utilization reconstruction
- elasticity recovery

## Next decision

D12D may review preliminary results only. D12D is not final manuscript interpretation.
