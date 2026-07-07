# D12E Robustness Design Summary

D12E reviewed D12C and D12D controlled preliminary artifacts and translated D12D warnings into a D12F robustness queue. D12E did not run coefficient estimation.

## Warning Intake

- intercept sign flip: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- omega_nfc magnitude shift across LL11/LL22: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- k_nrc_log_x_omega magnitude shift across LL11/LL22: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- intercept sign flip: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- omega_nfc magnitude shift across LL11/LL22: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- k_nrc_log_x_omega magnitude shift across LL11/LL22: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- condition-number or collinearity warnings: Design shorter-window and grid sensitivity checks; do not interpret final coefficients
- condition-number or collinearity warnings: Design shorter-window and grid sensitivity checks; do not interpret final coefficients

## Historical Windows

- full_long_sample: BASELINE_ALREADY_ESTIMATED
- pre_1974_full: PRIMARY_ROBUSTNESS_CANDIDATE
- post_1973_full: PRIMARY_ROBUSTNESS_CANDIDATE
- fordist_core: SECONDARY_ROBUSTNESS_CANDIDATE
- bridge_1940_1978: SECONDARY_ROBUSTNESS_CANDIDATE
- pre_1974_alt_1940_1973: SUPPORT_ROBUSTNESS_CANDIDATE
- pre_1974_alt_1947_1973: SUPPORT_ROBUSTNESS_CANDIDATE
- post_1974_tight: BLOCKED_NOT_ESTIMABLE
- post_1974_support: BLOCKED_NOT_ESTIMABLE
- volcker_event_profile: DESCRIPTIVE_ONLY_NOT_ESTIMABLE

## Current Sample

Current complete-case model sample: 1931-2024 (n=94).

## Lead/Lag Grids

- LL00: static levels plus current base differences only, diagnostic minimal-dynamics design
- LL11: D12C baseline grid already estimated
- LL22: D12C robustness grid already estimated
- LL33: candidate high-dynamic grid only if sample/rank feasible

## D12F Queue

- D12F_QUEUE_001: RDOLS_ME_NRC_OMEGA_INT_PRE_1974_FULL_LL11 (P1_PRIMARY)
- D12F_QUEUE_002: RDOLS_ME_NRC_OMEGA_INT_PRE_1974_FULL_LL22 (P1_PRIMARY)
- D12F_QUEUE_003: RDOLS_ME_NRC_OMEGA_INT_PRE_1974_FULL_LL00 (P4_DIAGNOSTIC)
- D12F_QUEUE_004: RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_LL11 (P1_PRIMARY)
- D12F_QUEUE_005: RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_LL22 (P1_PRIMARY)
- D12F_QUEUE_006: RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_LL00 (P4_DIAGNOSTIC)
- D12F_QUEUE_007: RDOLS_ME_NRC_OMEGA_INT_POST_1973_FULL_LL33 (P4_DIAGNOSTIC)
- D12F_QUEUE_008: RDOLS_ME_NRC_OMEGA_INT_FORDIST_CORE_LL11 (P2_SECONDARY)
- D12F_QUEUE_009: RDOLS_ME_NRC_OMEGA_INT_FORDIST_CORE_LL00 (P4_DIAGNOSTIC)
- D12F_QUEUE_010: RDOLS_ME_NRC_OMEGA_INT_BRIDGE_1940_1978_LL11 (P2_SECONDARY)
- D12F_QUEUE_011: RDOLS_ME_NRC_OMEGA_INT_BRIDGE_1940_1978_LL22 (P2_SECONDARY)
- D12F_QUEUE_012: RDOLS_ME_NRC_OMEGA_INT_BRIDGE_1940_1978_LL00 (P4_DIAGNOSTIC)
- D12F_QUEUE_013: RDOLS_ME_NRC_OMEGA_INT_PRE_1974_ALT_1940_1973_LL11 (P3_SUPPORT)
- D12F_QUEUE_014: RDOLS_ME_NRC_OMEGA_INT_PRE_1974_ALT_1940_1973_LL00 (P4_DIAGNOSTIC)
- D12F_QUEUE_015: RDOLS_ME_NRC_OMEGA_INT_PRE_1974_ALT_1947_1973_LL00 (P4_DIAGNOSTIC)

## Blocked

- pre_1974_full LL33: BLOCK_NOT_ESTIMABLE
- fordist_core LL22: BLOCK_NOT_ESTIMABLE
- fordist_core LL33: BLOCK_NOT_ESTIMABLE
- bridge_1940_1978 LL33: BLOCK_NOT_ESTIMABLE
- pre_1974_alt_1940_1973 LL22: BLOCK_NOT_ESTIMABLE
- pre_1974_alt_1940_1973 LL33: BLOCK_NOT_ESTIMABLE
- pre_1974_alt_1947_1973 LL11: BLOCK_NOT_ESTIMABLE
- pre_1974_alt_1947_1973 LL22: BLOCK_NOT_ESTIMABLE
- pre_1974_alt_1947_1973 LL33: BLOCK_NOT_ESTIMABLE
- post_1974_tight LL00: BLOCK_NOT_ESTIMABLE
- post_1974_tight LL11: BLOCK_NOT_ESTIMABLE
- post_1974_tight LL22: BLOCK_NOT_ESTIMABLE
- post_1974_tight LL33: BLOCK_NOT_ESTIMABLE
- post_1974_support LL00: BLOCK_NOT_ESTIMABLE
- post_1974_support LL11: BLOCK_NOT_ESTIMABLE
- post_1974_support LL22: BLOCK_NOT_ESTIMABLE
- post_1974_support LL33: BLOCK_NOT_ESTIMABLE
- volcker_event_profile LL00: BLOCK_NOT_ESTIMABLE
- volcker_event_profile LL11: BLOCK_NOT_ESTIMABLE
- volcker_event_profile LL22: BLOCK_NOT_ESTIMABLE
- volcker_event_profile LL33: BLOCK_NOT_ESTIMABLE

## Terminal Decision

AUTHORIZE_D12F_CONTROLLED_RDOLS_ROBUSTNESS_EXECUTION

D12F is authorized for controlled preliminary RDOLS robustness execution only, not final estimation.
