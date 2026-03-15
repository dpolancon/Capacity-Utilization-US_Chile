# Capacity-Utilization-US_Chile
### Chapter 2 — Track B: Reduced-Rank VECM and Regime Analysis
**Dissertation**: *A Historical Trace of Capacity Utilization Measurements*
**Author**: Diego Polanco | UMass Amherst | Supervisor: Michael Ash

## Overview
Five-dimensional reduced-rank VECM, rank r=3. State vector: [output, capital accumulation, exploitation rate, kₜeₜ, kₜeₜ²]. Structural break 1973 (Fordist / post-Fordist). US corporate sector.

## Pipeline Status (M0–M13)
| Module | Label | Status |
|--------|-------|--------|
| M0 | Data construction, I(1) verification | 🔲 Not coded |
| M1 | Lag selection, VAR pre-testing | 🔲 Not coded |
| M2 | Johansen trace/eigenvalue, rank r=3 | 🔲 Not coded |
| M3–M8 | RRR estimation, generated regressors, BFGS | 🔲 Not coded |
| M9 | Parametric bootstrap B=999/4999 | 🔲 Not coded |
| M10–M11 | Regime break, Fordist/post-Fordist comparison | 🔲 Not coded |
| M12–M13 | IRF, FEVD, results packing | 🔲 Not coded |

**Gate**: Do not begin M0 until Track A S9 confirms e_corp loads on independent cointegrating vector.

## Identification
- Rank r=3, 14 restrictions (5 over-identifying)
- CR threshold 0.15 for generated regressor bias
- Bootstrap replaces MacKinnon-Haug-Michelis tabulated critical values

## Structure
- `scripts/track_b/` — M0–M13 pipeline (to be built)
- `data/raw/` — source series (BEA, FRED)
- `output/figures/` — fig_*.png + fig_*.pdf
- `results/`
