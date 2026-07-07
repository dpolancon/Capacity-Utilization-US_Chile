# S35 Specification Review and Estimator-Refreeze Prep Gate

## Purpose

S35 reviews S34 admissibility results and freezes no estimator. It distinguishes theta-recovery specifications, OVB-control terms, distribution-conditioned accumulation, mechanization-composition accumulation, blocked raw interactions, and CPR-only experiments.

## S34 locks consumed

- `Q_omega` is I(1) and authorized standard-if-I(1), but design-fragile.
- `Q_MEshare` is I(1) and authorized standard-if-I(1), but must pass S35 design review.
- `Q_q` remains blocked for I(2) risk.
- `omega_NFC` and `ME_share` are bounded-persistent states, not clean pure I(1) trend objects.
- Raw `k_Kcap * omega_NFC`, raw `k_Kcap * q`, `q^2`, and raw `q * omega_NFC` are blocked from the standard grid.

## Locked interpretation

Include omega_t not to recover theta_t directly, but to prevent the mechanization-composition path Q^{MEshare}_t from absorbing omitted distributional-state effects. The recovered theta_t remains tied to accumulated composition-conditioned capacity building, while omega_t enters as a bounded-persistent OVB-control and second-order distributional state term.

## Required S35 answers

- **Is `Q_MEshare` admissible when paired with `k_Kcap`?** Integration says yes, but design says hold: condition_number=31.298; max_pairwise_corr=0.99796; Full rank but high condition number; estimator refreeze prep must review.
- **Is `Q_MEshare + omega_NFC` admissible as mechanization path plus OVB-control?** Only conceptually. The design remains fragile: condition_number=35.024; max_pairwise_corr=0.99796; Full rank but high condition number; estimator refreeze prep must review.
- **Is `Q_omega` too collinear with `k_Kcap` to remain in the main estimator menu?** Yes. condition_number=271.67; max_pairwise_corr=0.99997; Near-perfect pairwise collinearity; do not use as main menu without redesign.
- **Should `Q_omega` be retained only as reduced-form distribution-conditioned robustness path?** Yes. It is distribution-conditioned accumulation, not direct mechanization composition.
- **Should `Q_q` remain blocked?** Yes. S34 classifies `Q_q` as `I2_RISK`, so it remains outside the standard grid.
- **Is there a better observed q proxy available, or should observed-q recovery be parked?** No better authorized observed q proxy is present in the S34/S31I menu; observed-q recovery is parked.
- **Which candidate specifications are standard-grid admissible?** None are authorized for immediate estimator refreeze. `Q_MEshare` specifications are theoretically preferred but held for design review.
- **Which candidate specifications must be diagnostic-only?** `Q_omega` reduced-form paths, `Q_omega + omega_NFC`, and upstream q-omega screens.
- **Which require CPR/polynomial treatment?** Raw `k*q`, raw `k*omega`, raw `q*omega`, and `q^2` remain outside the standard grid; nonlinear q work routes to CPR.

## Main Design Diagnostics

|design_id|variables|n_obs|condition_number|pairwise_correlation_max|max_vif_from_correlation_inverse|collinearity_status|
|---|---|---|---|---|---|---|
|S35_DES_KCAP_QMESHARE|k_Kcap + Q_MEshare|   99| 31.3|0.998|245.4|FRAGILE_HIGH_CONDITION_NUMBER|
|S35_DES_KCAP_QMESHARE_OMEGA|k_Kcap + Q_MEshare + omega_NFC|   96|35.02|0.998|261.3|FRAGILE_HIGH_CONDITION_NUMBER|
|S35_DES_KCAP_QOMEGA|k_Kcap + Q_omega|   95|271.7|    1|18452|FRAGILE_NEAR_PERFECT_COLLINEARITY|
|S35_DES_KCAP_QOMEGA_OMEGA|k_Kcap + Q_omega + omega_NFC|   95|369.2|    1|28921|FRAGILE_NEAR_PERFECT_COLLINEARITY|

## Specification Review Ledger

|spec_id|specification_role|theta_recovery_status|accumulation_channel|ovb_control_status|s35_status|
|---|---|---|---|---|---|
|S35_CORE_MECH_COMP_OVB|preferred_theoretical_candidate|theta_t = beta + gamma s_ME_{t-1}; omega_NFC is not theta recovery|mechanization_composition_accumulation|bounded_persistent_OVB_control|HOLD_FOR_DESIGN_REVIEW|
|S35_MECH_COMP_PATH|theta_recovery_candidate|theta_t = beta + gamma s_ME_{t-1}|mechanization_composition_accumulation|none|HOLD_FOR_DESIGN_REVIEW|
|S35_DIST_ACCUM_PATH|reduced_form_distribution_robustness|theta_t = beta + gamma omega_{t-1}; reduced form, not mechanization composition|distribution_conditioned_accumulation|none|DIAGNOSTIC_ONLY|
|S35_DIST_ACCUM_OVB|reduced_form_distribution_robustness_with_control|theta_t = beta + gamma omega_{t-1}; delta omega_NFC is OVB control|distribution_conditioned_accumulation|bounded_persistent_OVB_control_with_double_counting_risk|DIAGNOSTIC_ONLY|
|S35_OBS_Q_PATH|observed_q_recovery_candidate|parked; Q_q would imply theta_t = beta + gamma q_{t-1}|observed_q_weighted_accumulation|none|BLOCK_STANDARD_GRID_PENDING_I2_REVIEW|
|S35_RAW_K_OMEGA|blocked_raw_interaction|blocked; raw interaction is not preferred theta recovery|none|none|BLOCK_STANDARD_GRID_PENDING_I2_REVIEW|
|S35_RAW_K_Q|blocked_raw_interaction|blocked; raw interaction is not preferred theta recovery|none|none|BLOCK_STANDARD_GRID_PENDING_I2_REVIEW|
|S35_Q_SQUARED|nonlinear_mechanization_experiment|does not recover theta_t inside the standard capacity equation|nonlinear_technique_choice|none|ROUTE_NONLINEAR_MECHANIZATION_TO_CPR|
|S35_Q_OMEGA_RAW|technique_choice_diagnostic|upstream q-star relation, not direct theta recovery|technique_choice_state|none|DIAGNOSTIC_ONLY|

## Estimator Menu Candidate Ledger

|spec_id|menu_tier|standard_grid_status|estimator_refreeze_prep_status|reason|
|---|---|---|---|---|
|S35_CORE_MECH_COMP_OVB|candidate_main_after_design_review|not_authorized_yet|hold|Theoretically leading, but k_Kcap and Q_MEshare remain highly collinear; omega_NFC is bounded-persistent OVB control.|
|S35_MECH_COMP_PATH|candidate_nested_baseline_after_design_review|not_authorized_yet|hold|Cleaner theta-recovery path than OVB version, but still fails basic design fragility threshold.|
|S35_DIST_ACCUM_PATH|reduced_form_robustness_only|diagnostic_or_robustness_only|do_not_refreeze_as_main|Q_omega is I(1) but nearly perfectly collinear with k_Kcap and is distribution-conditioned, not direct mechanization composition.|
|S35_DIST_ACCUM_OVB|reduced_form_robustness_only|diagnostic_only|do_not_refreeze_as_main|Adds bounded omega_NFC to a path already weighted by omega_NFC; double-counting risk plus near-singular design.|
|S35_OBS_Q_PATH|parked_observed_q_recovery|blocked_standard_grid|do_not_refreeze|Q_q remains I2_RISK; observed-q recovery is parked until a better q proxy is authorized.|
|S35_RAW_K_OMEGA|blocked_raw_interaction|blocked_standard_grid|do_not_refreeze|Raw level interaction is blocked by S34.|
|S35_RAW_K_Q|blocked_raw_interaction|blocked_standard_grid|do_not_refreeze|Raw k*q is blocked by S34.|
|S35_Q_SQUARED|cpr_polynomial_only|route_to_CPR|do_not_refreeze|Nonlinear mechanization through q^2 requires CPR/polynomial treatment.|
|S35_Q_OMEGA_RAW|upstream_diagnostic_only|diagnostic_only|do_not_refreeze_as_capacity_spec|Technique-choice screen is upstream and visually weak in S34.|

## Final Decision

`HOLD_FOR_DESIGN_REVIEW`

Estimator refreeze should not begin from this layer. The next move is a targeted design review of the mechanization-composition path, especially whether `Q_MEshare` can be orthogonalized, periodized, indexed, or otherwise represented without collapsing into `k_Kcap`.
