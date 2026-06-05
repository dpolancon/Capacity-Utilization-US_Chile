# Stage 1 VECM — Split-Sample Estimation Crosswalk
**Date:** 2026-04-07 | **Country:** Chile

## Specification
- State vector: Y = (m, k_ME, nrs, omega)'
- Deterministic: restricted constant (Case 3, ecdet='const')
- Parameterization: spec='transitory'
- VAR lag K=2 (fixed) | VECM lag L=1
- Split at 1973. Post-1973 includes D1975 as unrestricted impulse dummy.

### PRE-1973 — ISI ERA (1920–1972)
- Sample: N=53 | VAR lag K=2 | Rank r=1

#### Cointegrating Vector (normalized on m)
$$m = -5.8040 + 0.9303 \cdot k^{ME} + 0.4445 \cdot nrs + -3.9188 \cdot \omega$$

| Coefficient | Value | Interpretation |
|-------------|-------|----------------|
| zeta_1 (k_ME) | +0.9303 | Tavares confirmed |
| zeta_2 (nrs) | +0.4445 | Kaldor/Palma-Marcel |
| zeta_3 (omega) | -3.9188 | Wage share |
| zeta_0 (const) | -5.8040 | |

#### Loading Matrix
| Variable | alpha | |
|----------|-------|---|
| m | -0.1779 | error-corrects |
| k_ME | -0.0062 | |
| nrs | +0.2131 | |
| omega | -0.0656 | |

#### Weak Exogeneity
| Variable | LR | p | Decision |
|----------|-----|---|----------|
| m | 6.493 | 0.0108 | NOT weakly exogenous |
| k_ME | 1.681 | 0.1947 | weakly exogenous |
| nrs | 2.591 | 0.1075 | weakly exogenous |
| omega | 5.598 | 0.0180 | NOT weakly exogenous |

#### Diagnostics
- Portmanteau: p=0.8664 OK
- ARCH-LM:     p=0.8996 OK
- Jarque-Bera: p=0.0000 FAIL
- ADF on ECT:  tau=-4.4470 stationary

#### ECT Summary
- mean=-0.2211  sd=0.5472  range=[-1.6294, 1.1975]

---

### POST-1973 — NEOLIBERAL ERA (1973–2024)
- Sample: N=52 | VAR lag K=2 | Rank r=1

#### Cointegrating Vector (normalized on m)
$$m = 9.3324 + 0.3091 \cdot k^{ME} + 0.2386 \cdot nrs + -7.1284 \cdot \omega$$

| Coefficient | Value | Interpretation |
|-------------|-------|----------------|
| zeta_1 (k_ME) | +0.3091 | Tavares confirmed |
| zeta_2 (nrs) | +0.2386 | Kaldor/Palma-Marcel |
| zeta_3 (omega) | -7.1284 | Wage share |
| zeta_0 (const) | +9.3324 | |

#### Loading Matrix
| Variable | alpha | |
|----------|-------|---|
| m | -0.1796 | error-corrects |
| k_ME | -0.0162 | |
| nrs | -0.0186 | |
| omega | -0.0193 | |

#### Weak Exogeneity
| Variable | LR | p | Decision |
|----------|-----|---|----------|
| m | 8.969 | 0.0027 | NOT weakly exogenous |
| k_ME | 2.847 | 0.0915 | weakly exogenous |
| nrs | 0.157 | 0.6922 | weakly exogenous |
| omega | 1.814 | 0.1780 | weakly exogenous |

#### Diagnostics
- Portmanteau: p=0.5334 OK
- ARCH-LM:     p=0.9469 OK
- Jarque-Bera: p=0.0324 FAIL
- ADF on ECT:  tau=-3.1685 stationary

#### ECT Summary
- mean=-0.0847  sd=0.3451  range=[-1.0573, 0.5423]

---

## Structural Comparison
| Parameter | Pre-1973 (ISI) | Post-1973 (neoliberal) |
|-----------|---------------|----------------------|
| zeta_1 (k_ME) | +0.9303 | +0.3091 |
| zeta_2 (nrs) | +0.4445 | +0.2386 |
| zeta_3 (omega) | -3.9188 | -7.1284 |
| zeta_0 (const) | -5.8040 | +9.3324 |
| alpha_m | -0.1779 | -0.1796 |
| Portmanteau p | 0.8664 | 0.5334 |
| ARCH p | 0.8996 | 0.9469 |
| JB p | 0.0000 | 0.0324 |

## ECT_m: `data/processed/Chile/ECT_m_stage1.csv`
- 105 observations (1920–2024)
- Column `regime` identifies which system generated each ECT value

---
*Generated: 2026-04-07 | Authority: Ch2_Outline_DEFINITIVE.md*
