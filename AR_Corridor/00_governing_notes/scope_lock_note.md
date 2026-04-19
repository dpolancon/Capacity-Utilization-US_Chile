# AR Corridor — Scope Lock Note
**Date:** 2026-04-13  
**Status:** Active governing note

## What this corridor is
The AR Corridor contains all estimation, accounting objects, and paper-facing assets for Chapter 2: Demand-Led Profitability and Structural Crisis of Capitalism in Chile and the United States during the Fordist Era.

## Scope locks
- Distributional variable (US): ω_t = wage share (EC_NF / GVA_NF), Non-Financial Corporate sector
- Distributional variable (Chile): ω_t = wage share, to be confirmed on data pipeline completion
- Estimator (long-run): DOLS following Saikkonen (1991) / Stock & Watson (1993)
- Sample structure (US): baseline = full sample; Sample A = t ≤ 1973 (backwards); Sample B = t ≥ 1974 (onwards)
- Fordist focus window: 1945–1978; full panel available 1929–2024
- θ is a regime parameter defined upstream by production structure; it is NOT a FOC residual
- μ̂_t is recovered from DOLS residual after benchmark-year normalization, not estimated directly

## What does NOT belong here
- VECM/Johansen estimation of θ (archived at codes/legacy/pre_DOLS_VECM/)
- Chilean TVECM Stage 2 (pending Stage 1 VECM completion — separate track)
- Chapter 3 two-country RRR (separate file tree)
