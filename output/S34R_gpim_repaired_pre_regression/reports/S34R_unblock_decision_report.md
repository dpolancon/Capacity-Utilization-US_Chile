# S34R GPIM-Repaired Pre-Regression Unblock Decision

## Purpose

S34R repairs the S34 diagnostic base by rebuilding capital, growth, composition, and accumulated paths from the D06/D07 GPIM-repaired boundary. It runs no final long-run estimator.

## Provenance Verdict

- Required repaired downstream objects passed provenance gate: `True`.
- Repaired `Q_omega` and `Q_MEshare` are rebuilt from D06/D07 repaired growth and state weights.
- `Q_q_if_retained` remains diagnostic/stale-blocked unless a better observed q proxy is authorized.

## Design Verdict

| design_id                 | regressors                     |   condition_number |   pairwise_correlation_max | allowed_status          |
|:--------------------------|:-------------------------------|-------------------:|---------------------------:|:------------------------|
| DES0_kcap                 | k_Kcap                         |            1       |                 nan        | PASS_DESIGN_DIAGNOSTICS |
| DES1_kcap_Qomega          | k_Kcap + Q_omega               |          442.586   |                   0.99999  | SEVERE_FRAGILITY        |
| DES2_kcap_QMEshare        | k_Kcap + Q_MEshare             |            2.57856 |                   0.738528 | PASS_DESIGN_DIAGNOSTICS |
| DES3_kcap_QMEshare_omega  | k_Kcap + Q_MEshare + omega_NFC |            2.75167 |                   0.738528 | PASS_DESIGN_DIAGNOSTICS |
| DES4_kcap_Qomega_omega    | k_Kcap + Q_omega + omega_NFC   |          540.473   |                   0.99999  | SEVERE_FRAGILITY        |
| DES5_kME_kNRC             | k_ME + k_NRC                   |            4.86957 |                   0.91907  | PASS_DESIGN_DIAGNOSTICS |
| DES6_kcap_Qomega_QMEshare | k_Kcap + Q_omega + Q_MEshare   |          542.975   |                   0.99999  | SEVERE_FRAGILITY        |

## Residual Cointegration Gate

The EG screen uses `aTSA::coint.test()` and records type1/type2/type3 rows. Type1 is the primary screen for non-trend first-stage residuals. OVB-control models containing `omega_NFC` are mixed-order diagnostics, not pure standard EG authorization.

| model_id   | rhs                            |   p_value | eg_classification                 | model_order_status   |
|:-----------|:-------------------------------|----------:|:----------------------------------|:---------------------|
| EG0        | k_Kcap                         |       0.1 | EG_PASS_WEAK                      | PURE_I1_CORE         |
| EG1        | k_ME + k_NRC                   |       0.1 | EG_PASS_WEAK                      | PURE_I1_CORE         |
| EG2        | k_Kcap + Q_MEshare             |       0.1 | EG_PASS_WEAK                      | PURE_I1_CORE         |
| EG3        | k_Kcap + Q_omega               |       0.1 | EG_PASS_WEAK                      | PURE_I1_CORE         |
| EG4        | k_Kcap + Q_MEshare + Q_omega   |       0.1 | EG_PASS_WEAK                      | PURE_I1_CORE         |
| EGD1       | k_Kcap + Q_MEshare + omega_NFC |       0.1 | EG_MIXED_ORDER_CONTROL_DIAGNOSTIC | MIXED_ORDER_CONTROL  |
| EGD2       | k_Kcap + Q_omega + omega_NFC   |       0.1 | EG_MIXED_ORDER_CONTROL_DIAGNOSTIC | MIXED_ORDER_CONTROL  |

## Unblock Matrix

| criterion                                   | passed   | notes                                                                           |
|:--------------------------------------------|:---------|:--------------------------------------------------------------------------------|
| repaired_gpim_provenance_passed             | True     | Capital/growth/composition/Q objects match or are rebuilt from D06/D07.         |
| repaired_panel_created                      | True     | S34R repaired candidate panel exists.                                           |
| repaired_i_order_ledger_created             | True     | Repaired integration ledger exists.                                             |
| no_stale_gpim_object_enters_candidate_specs | True     | Candidate specs use rebuilt repaired objects.                                   |
| raw_interactions_remain_blocked             | True     | Raw k*omega and k*q remain blocked.                                             |
| q_q_remains_blocked_if_not_clean            | True     | Observed-q recovery remains blocked/stale unless reviewed.                      |
| at_least_one_core_eg_pass                   | True     | At least one pure-I1 core EG screen passes type1 at weak/strong threshold.      |
| main_candidate_not_fatal_collinearity       | True     | DES2 k_Kcap + Q_MEshare is not severe >100, but may warn.                       |
| small_interpretable_menu_possible           | True     | Menu can be limited to Q_MEshare core/OVB plus diagnostics after design review. |
| final_decision                              | True     | HOLD_FOR_DESIGN_REVIEW                                                          |

## Final Decision

`HOLD_FOR_DESIGN_REVIEW`

## Recommended Next Action

Do not proceed directly to FM-OLS/DOLS/IM-OLS. Review the repaired EG and design ledgers. If design warnings are tolerable, S35 can be rerun against the repaired S34R panel with a small menu centered on `k_Kcap + Q_MEshare`, while `Q_omega` remains reduced-form robustness and raw interactions remain blocked.