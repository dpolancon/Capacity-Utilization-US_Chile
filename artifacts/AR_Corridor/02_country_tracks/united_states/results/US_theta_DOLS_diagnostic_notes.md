# US DOLS — Diagnostic Notes
**Date generated:** 2026-04-13 15:12:26  
**Script:** 01_US_theta_DOLS.R  
**p (leads/lags):** 2  

## 1. Data loaded
- Source path: C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/us_nf_corporate_stageBC.csv
- Years in panel: 1929 – 2024
- N total rows: 96

## 2. Sample trimming (leads/lags)
| Sample | Raw N | After trimming | Years |
|--------|-------|----------------|-------|
| Full sample | 96 | 93 | 1932–2024 |
| Pre-1974 (≤1973) | 47 | 44 | 1932–1975 |
| Post-1973 (≥1974) | 53 | 50 | 1975–2024 |
| Fordist core (1945–1973) | 33 | 30 | 1946–1975 |

## 3. Sign checks
| Sample | β̂₂ < 0? | Interpretation |
|--------|----------|----------------|
| Full sample | YES | Consistent with theoretical prior |
| Pre-1974 (≤1973) | YES | Consistent with theoretical prior |
| Post-1973 (≥1974) | NO | INCONSISTENT — theoretical prior requires β̂₂ < 0 |
| Fordist core (1945–1973) | YES | Consistent with theoretical prior |

Theoretical prior: β̂₂ < 0 required (higher wage share reduces transformation elasticity slope).

## 4. Harrodian threshold
| Sample | ω_H | ω̄ | ω_min | ω_max | ω_H in range? |
|--------|-----|-----|-------|-------|---------------|
| Full sample | 131.5970 | 0.6228 | 0.5648 | 0.6777 | NO |
| Pre-1974 (≤1973) | -0.5360 | 0.6325 | 0.5945 | 0.6777 | NO |
| Post-1973 (≥1974) | -179.8173 | 0.6157 | 0.5648 | 0.6549 | NO |
| Fordist core (1945–1973) | 0.4819 | 0.6333 | 0.6095 | 0.6634 | NO |

## 5. Benchmark normalization
- Primary benchmark year: 1966
- ε̂_{1966} (full sample): 0.036909
- μ̂_{benchmark} = 1.000 (by construction)

## 6. Open flags
- DERIVATION: y_t = log(GVA_real).
- DERIVATION: k_t = log(KGR).

- Column resolution: omega_t derived from: direct
- ok_t rebuilt: FALSE
