---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: CL
last_updated: 2026-07-23
layer: econometrics
design_role: integration_order_admissibility_map
scope: CL_first_layer_theta_recovery
created: 2026-07-23
sources:
  - data/processed/integration_order/classified_variable_integration_ledger.csv
  - chapter2_vault/02_analyitical_foundation/A06_Peripheral_3Way_Orthogonalization_Pending.md
related_to:
  - N03_US_Theta_Integration_Order_Admissibility
  - Interaction_Term_Integration_Order_Gate
tags:
  - chapter2/econometrics
  - chapter2/chile
  - chapter2/theta
  - chapter2/integration-order
subtype: econometric_protocol
blocks: []
priority: reference
---

# N04 — Chile $\theta_t$ Integration-Order Admissibility Map

## Verdict

The integration-order testing engine (`COMMON_S31`) classifies Chilean macro capital, class distribution ($\omega_t^{\text{CL}}$), foreign exchange external wedge proxies ($z_t^{(1)}, z_t^{(2)}$), and orthogonalized interaction residuals into definitive integration order categories:

1. **Strong $I(1)$ Series**:
   - Class Distribution ($\omega_t^{\text{CL}}$): ADF diff $p = 0.0100$, KPSS diff stat = 0.0593.
   - Real Export Capacity ($z_t^{(2)} = \text{xcap}$): ADF diff $p = 0.0100$, KPSS diff stat = 0.2805.
   - Orthogonalized 2-Way Scale-Distribution Residual ($\hat{u}^{(k,\omega)}_{\text{CL}, t}$): ADF diff $p = 0.0100$.

2. **Weak $I(1)$ Series (Admissible with FWL Pre-Filter)**:
   - Aggregate Capital ($k_t^{\text{CL, cap}}$) and Machinery ($k_t^{\text{CL, ME}}$): ADF diff $p \approx 0.09$, requiring CPR gate handling (`S34R-B`).
   - Log Terms of Trade ($z_t^{(1)}$): ADF diff $p = 0.0100$, KPSS level stat = 0.2674.
   - Orthogonalized 2-Way Distribution-FX Residual ($\hat{u}^{(\omega,z)}_{\text{CL}, t}$): ADF diff $p = 0.0100$.
   - Pending 3-Way Orthogonalized Residual ($\hat{u}^{(k,\omega,z)}_{\text{CL, pending}, t}$): ADF diff $p = 0.0100$, KPSS level stat = 0.0700.

3. **Blocked / $I(2)$ Risk**:
   - Direct Nonresidential Structures Level ($k_t^{\text{CL, NR}}$) and un-filtered scale-FX product ($\hat{u}^{(k,z)}_{\text{CL}, t}$): ADF diff $p > 0.1236$, blocked from direct unrestricted estimation.

## Source Ledger Summary

| Variable Symbol | N | Level ADF p | Level KPSS stat | Diff ADF p | Classification | Gate Status |
|---|---|---|---|---|---|---|
| $k_t^{\text{CL, cap}}$ | 91 | 0.9900 | 2.2456 | 0.0941 | Weak $I(1)$ | Admissible with FWL Pre-Filter |
| $k_t^{\text{CL, ME}}$ | 91 | 0.9668 | 2.1121 | 0.0929 | Weak $I(1)$ | Admissible with FWL Pre-Filter |
| $k_t^{\text{CL, NR}}$ | 91 | 0.9900 | 2.2843 | 0.1236 | $I(2)$ Risk | Blocked |
| $\omega_t^{\text{CL}}$ | 91 | 0.2869 | 1.4915 | 0.0100 | Strong $I(1)$ | Admissible (CPR Gate) |
| $z_t^{(1)}$ (ToT) | 91 | 0.4095 | 0.2674 | 0.0100 | Weak $I(1)$ | Admissible with FWL Pre-Filter |
| $z_t^{(2)}$ (Xcap) | 91 | 0.7493 | 0.7915 | 0.0100 | Strong $I(1)$ | Admissible (CPR Gate) |
| $\hat{u}^{(k,\omega)}_{\text{CL}, t}$ | 91 | 0.9779 | 0.5249 | 0.0100 | Strong $I(1)$ | Admissible (CPR Gate) |
| $\hat{u}^{(k,z)}_{\text{CL}, t}$ | 91 | 0.9158 | 0.1815 | 0.2934 | $I(2)$ Risk | Blocked |
| $\hat{u}^{(\omega,z)}_{\text{CL}, t}$ | 91 | 0.7328 | 0.1273 | 0.0100 | Weak $I(1)$ | Admissible with FWL Pre-Filter |
| $\hat{u}^{(k,\omega,z)}_{\text{CL, pending}, t}$ | 91 | 0.1365 | 0.0700 | 0.0100 | Weak $I(1)$ | Admissible with FWL Pre-Filter |

## Locked Statement

**The Chilean integration-order tests advance aggregate scale ($k_t^{\text{CL, cap}}$), distribution ($\omega_t^{\text{CL}}$), real export capacity ($z_t^{(2)}$), and the FWL orthogonalized 2-way and 3-way interaction residuals ($\hat{u}^{(k,\omega)}_{\text{CL}, t}, \hat{u}^{(k,\omega,z)}_{\text{CL, pending}, t}$) as admissible $I(1)$ regressors under the `S34R-B` CPR gate. Unfiltered structure levels ($k_t^{\text{CL, NR}}$) carry persistent $I(2)$ risk and remain blocked.**
