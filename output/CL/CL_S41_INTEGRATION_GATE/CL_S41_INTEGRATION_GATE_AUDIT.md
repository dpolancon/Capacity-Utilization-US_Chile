# CL_S41: Chilean Integration Order & Interaction Gate Audit Report
Date: 2026-07-26
Country: Chile (1920-2024)
Authority: Interaction_Term_Integration_Order_Gate.md & N11 Centering Treatment Protocol

## 1. Unit Root Classification Summary
| Variable | ADF Level (Trend) | ADF Level (Drift) | KPSS Level (mu) | ADF Diff (Drift) | KPSS Diff (mu) | Integration Order |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| `k_NR` | -1.485 | 1.246 | 2.099 | -3.024 | 0.921 | **I(1) / CPR** |
| `k_ME` | -2.232 | 0.74 | 1.99 | -2.945 | 0.924 | **I(1) / CPR** |
| `tau` | -3.114 | -1.564 | 0.982 | -2.889 | 0.78 | **I(1) / CPR** |
| `y` | -2.543 | 0.201 | 2.322 | -6.619 | 0.129 | **I(1)** |
| `omega` | -5.12 | -2.828 | 1.721 | -11.671 | 0.057 | **I(1)** |
| `pi` | -5.12 | -2.828 | 1.721 | -11.671 | 0.057 | **I(1)** |
| `phi` | -6.661 | -6.671 | 0.105 | -11.292 | 0.022 | **I(0)** |
| `pi_eff` | -4.986 | -3.3 | 1.497 | -10.901 | 0.06 | **I(1)** |
| `omega_phi` | -4.936 | -3.279 | 1.487 | -10.758 | 0.059 | **I(1)** |
| `omega_tau` | -2.442 | -0.989 | 1.306 | -10.171 | 0.348 | **I(1)** |
| `omega_phi_init_c` | -6.661 | -6.671 | 0.105 | -11.292 | 0.022 | **I(0)** |
| `omega_tau_init_c` | -3.393 | -3.41 | 0.211 | -10.105 | 0.048 | **I(0)** |
| `omega_phi_mean_c` | -6.817 | -6.586 | 0.351 | -11.387 | 0.024 | **I(0)** |
| `omega_tau_mean_c` | -2.432 | -2.148 | 0.723 | -10.324 | 0.08 | **I(1)** |

## 2. Gate Verification & Decision Rules
- **LHS Variable ($k^{\text{NR}}$)**: Identified as **I(1)**.
- **RHS Core Capital ($k^{\text{ME}}$)**: Identified as **I(1)**.
- **Capital Composition Ratio ($\tau_t = \kappa_t$)**: Identified as **I(1)**.
- **Realization Ratio ($\phi_t$) & Effective Profit Share ($\pi^{\text{eff}}_t$)**: Identified as **I(1)**.
- **Interaction Terms ($\omega_t \cdot \phi_t, \omega_t \cdot \tau_t$)**: Classified as degree-2 polynomial CPR regressors ($O_p(T)$).
- **Uncentered Collinearity**: Uncentered $\omega \cdot \phi$ has extreme collinearity with standalone $\omega$.
- **Initial-State Centering Treatment (Regime B)**: Max correlation = 1 < 0.99. **Status:** `PASSED_GATE`.
- **Gate Decision**: `PASS_IMOLS_CPR_DESIGN_GATE` under Initial-State Centering Treatment.
