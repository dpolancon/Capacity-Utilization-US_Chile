# AR Corridor — Notation and Objects
**Date:** 2026-04-13

## Notation locks (from standing_instructions_v02.md)
- Uppercase = levels (Y, K, Ω)
- Lowercase = growth rates (y, k, ω in log-levels for estimation)
- θ(ω) = transformation elasticity, linear in ω: θ̂_t = β̂₁ + β̂₂·ω_t
- μ_t = capacity utilization (level); u = μ̇/μ (growth rate)
- ω_t = wage share = EC_NF / GVA_NF (US Non-Financial Corporate sector)
- χ = I/Π (recapitalization rate)
- MPF = Mechanization Possibility Frontier (never IPF)
- DOLS = Dynamic OLS (Stock & Watson 1993 operational form)

## Key objects recovered from DOLS
| Symbol     | Definition                               | Recovery method                     |
|------------|------------------------------------------|--------------------------------------|
| θ̂_t       | Transformation elasticity at time t      | β̂₁ + β̂₂·ω_t                         |
| ε̂_t       | Long-run DOLS residual                   | y_t − ĉ − β̂₁k_t − β̂₂(ω_t·k_t)      |
| ε̃_t       | Benchmark-normalized residual            | ε̂_t − ε̂_{t₀}                         |
| μ̂_t       | Capacity utilization index               | exp(ε̃_t)                             |
| Ŷ^p_t     | Productive capacity (log-level)          | y_t − ε̃_t                            |
