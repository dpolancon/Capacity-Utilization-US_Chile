---
type: research_note
status: active
country: US_CL
stage_scope: N/A
last_updated: '2026-07-29'
depends_on: []
blocks: []
layer: design
scope: chapter2
priority: reference
---

# Locked Notation (Chapter 2)

## Capacity Utilization & Transformation Elasticity

| Symbol | Definition                        | Never Use   | Notes                                      |
| ------ | --------------------------------- | ----------- | ------------------------------------------ |
| μ_t    | Capacity utilization = Y / Y^p    | u, U, u_t   | Reconstructed object, not residual         |
| θ_t    | Transformation elasticity         | β_t, m_t    | Mediates ω → Y^p; distribution-conditioned |
| χ_t    | Recapitalization rate = I / Π     | β_t         | Fixed capital reinvestment                 |
| q      | Mechanization growth rate         | m           | Not import share (m = import propensity)   |
| Y      | Output (level)                    | —           | Observed                                   |
| Y^p    | Potential productive capacity     | Y*, Y_trend | Reconstructed via θ identification         |
| ω_t    | Wage share                        | w, ω        | Distribution parameter                     |
| K^NR   | Nonresidential structures capital | K_struct    | BEA layer                                  |
| K^ME   | Machinery & equipment capital     | K_equip     | BEA layer                                  |

## Conventions

- **Uppercase:** Levels (Y, K, Π)
- **Lowercase:** Log-levels (y, k, π)
- **Dot notation:** Growth rates (ẏ = d log Y / dt)
- **Subscript t:** Time index
- **Subscript j:** Cointegrating vector index (β_j)

## Key Chains (Never Violate)

ω_t → θ_t → Y^p_t → μ_t

External constraint (Chile only) → χ_t adjustment → modified θ_t