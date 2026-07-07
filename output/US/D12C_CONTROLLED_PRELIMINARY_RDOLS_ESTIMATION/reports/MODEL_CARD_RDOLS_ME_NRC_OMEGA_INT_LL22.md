# MODEL_CARD_RDOLS_ME_NRC_OMEGA_INT_LL22

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

`RDOLS_ME_NRC_OMEGA_INT_LL22`

## Gates

                    model_id        boundary_gate        qomega_gate
 RDOLS_ME_NRC_OMEGA_INT_LL22 PASS_ME_NRC_BOUNDARY PASS_QOMEGA_PARKED
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
 D12C_RUN_002 RDOLS_ME_NRC_OMEGA_INT_LL22       1931     2024            1934
 effective_end n_full n_effective n_lost_lead_lag n_lost_missing
          2022     94          89               5              5
        sample_status
 PASS_SAMPLE_SURVIVAL

## Long-run coefficients

Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.

              term coefficient_role estimate std_error t_value p_value
       (Intercept)    deterministic  -6.1294    9.6453 -0.6355  0.5273
          k_me_log   long_run_level  -0.2594    0.1669 -1.5541  0.1249
         k_nrc_log   long_run_level   1.4317    0.7698  1.8598  0.0673
         omega_nfc   long_run_level  24.5202   15.5942  1.5724  0.1206
  k_me_log_x_omega   long_run_level   0.4438    0.2545  1.7437  0.0858
 k_nrc_log_x_omega   long_run_level  -1.9210    1.2483 -1.5389  0.1285
             trend    deterministic   0.0290    0.0031  9.4401  0.0000

## Auxiliary dynamic terms

Auxiliary dynamic coefficients are hidden by default in the print method and are estimator-correction terms only.

                term                   coefficient_role estimate std_error
    d_k_me_log_lead2 restricted_base_difference_dynamic  -0.1259    0.2584
    d_k_me_log_lead1 restricted_base_difference_dynamic  -0.4620    0.3501
  d_k_me_log_current restricted_base_difference_dynamic   0.4472    0.3291
     d_k_me_log_lag1 restricted_base_difference_dynamic   0.2638    0.2961
     d_k_me_log_lag2 restricted_base_difference_dynamic  -0.0049    0.2232
   d_k_nrc_log_lead2 restricted_base_difference_dynamic  -0.2499    0.4047
   d_k_nrc_log_lead1 restricted_base_difference_dynamic  -0.4021    0.4714
 d_k_nrc_log_current restricted_base_difference_dynamic  -0.5497    0.4282
    d_k_nrc_log_lag1 restricted_base_difference_dynamic  -0.8096    0.3130
    d_k_nrc_log_lag2 restricted_base_difference_dynamic  -0.2209    0.1513
   d_omega_nfc_lead2 restricted_base_difference_dynamic   1.4154    0.5567
   d_omega_nfc_lead1 restricted_base_difference_dynamic   2.6900    0.5028
 d_omega_nfc_current restricted_base_difference_dynamic  -0.3380    0.5420
    d_omega_nfc_lag1 restricted_base_difference_dynamic  -0.4230    0.5076
    d_omega_nfc_lag2 restricted_base_difference_dynamic  -0.4831    0.4963
 t_value p_value shown_by_default
 -0.4871  0.6277            FALSE
 -1.3196  0.1915            FALSE
  1.3588  0.1788            FALSE
  0.8909  0.3762            FALSE
 -0.0218  0.9827            FALSE
 -0.6174  0.5391            FALSE
 -0.8530  0.3967            FALSE
 -1.2838  0.2036            FALSE
 -2.5864  0.0119            FALSE
 -1.4607  0.1488            FALSE
  2.5427  0.0133            FALSE
  5.3495  0.0000            FALSE
 -0.6237  0.5349            FALSE
 -0.8333  0.4076            FALSE
 -0.9734  0.3338            FALSE

## Diagnostics

- effective sample size: 89
- design rank: 22
- design columns: 22
- df residual: 67
- condition number: 245601.0705

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
