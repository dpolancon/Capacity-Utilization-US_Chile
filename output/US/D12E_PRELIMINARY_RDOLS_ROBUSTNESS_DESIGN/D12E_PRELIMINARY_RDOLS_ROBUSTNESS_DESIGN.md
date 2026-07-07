# D12E Preliminary RDOLS Robustness Design

D12E is a design pass. It inspected D12C/D12D outputs, current D10 source-of-truth availability, and the historical S22 window lock. It did not estimate coefficients.

## Coefficient Warning Boundary

All coefficient-related references are DESIGN_STAGE_PRELIMINARY_ONLY.

- intercept sign flip: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- omega_nfc magnitude shift across LL11/LL22: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- k_nrc_log_x_omega magnitude shift across LL11/LL22: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- intercept sign flip: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- omega_nfc magnitude shift across LL11/LL22: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- k_nrc_log_x_omega magnitude shift across LL11/LL22: Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY
- condition-number or collinearity warnings: Design shorter-window and grid sensitivity checks; do not interpret final coefficients
- condition-number or collinearity warnings: Design shorter-window and grid sensitivity checks; do not interpret final coefficients

## Feasible Design

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

## Prohibited

- q_omega construction or use.
- FM-OLS or IM-OLS nonlinear baseline substitution.
- cointRegD as interacted baseline engine.
- Dynamic corrections for interaction/generated terms.
- Productive-capacity reconstruction.
- Utilization reconstruction.
- Elasticity recovery.
- Final manuscript interpretation.

## Terminal Decision

AUTHORIZE_D12F_CONTROLLED_RDOLS_ROBUSTNESS_EXECUTION
