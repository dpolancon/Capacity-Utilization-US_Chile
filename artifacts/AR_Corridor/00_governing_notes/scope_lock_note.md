# AR Corridor — Scope Lock Note
**Date:** 2026-04-13  
**Status:** Active governing note

## What this corridor is
The AR Corridor contains all estimation, accounting objects, and paper-facing assets for Chapter 2: Demand-Led Profitability and Structural Crisis of Capitalism in Chile and the United States during the Fordist Era.

## Scope locks
- **Distributional variable (US):** ω_t = wage share (EC_NF / GVA_NF), Non-Financial Corporate sector
- **Distributional variable (Chile):** ω_t = wage share, to be confirmed on data pipeline completion
- **Estimator (long-run):** DOLS via `cointRegD()` (cointReg package), bandwidth = Newey-West
  - `cointRegD()` handles leads/lags construction and long-run variance correction internally (Saikkonen 1991 / Stock & Watson 1993)
- **Sample structure (US):**
  - Baseline: full sample (all available years)
  - Sample A: t ≤ 1973 (pre-oil shock / pre-crisis, backwards from 1973)
  - Sample B: t ≥ 1974 (post-oil shock / post-Fordist transition, onwards from 1974)
  - Sample C: 1945–1973 (Fordist core window)
- **Fordist focus window:** 1945–1978; full panel available 1929–2024
- **θ is a regime parameter** defined upstream by production structure; it is NOT a FOC residual
- **μ̂_t is recovered** from DOLS residual after benchmark-year normalization, not estimated directly

## Accounting rules

### Law: structural identification always uses gross capital (KGR)
Never use net stocks (KNC) for θ identification. Gross measures capture the full accumulation frontier that the MPF maps. Net stocks conflate depreciation heterogeneity with the transformation elasticity. KGR is the law for all structural identification.

### Distributive accounting: ω_t + π_t = 1
For **Non-Financial Corporate** capital, the identity wage share + profit share = 1 holds by construction (EC_NF + GOS_NF = GVA_NF, hence EC_NF/GVA_NF + GOS_NF/GVA_NF = 1). This is the sector used for θ identification.

For the broader **Corporate** aggregate (including financial), the identity may not hold cleanly — the distributive split depends on financial sector treatment and is not confirmed. Do not use the Corporate aggregate for structural identification unless the identity is verified.

## What does NOT belong here
- VECM/Johansen estimation of θ (archived at codes/legacy/pre_DOLS_VECM/)
- Chilean TVECM Stage 2 (pending Stage 1 VECM completion — separate track)
- Chapter 3 two-country RRR (separate file tree)
