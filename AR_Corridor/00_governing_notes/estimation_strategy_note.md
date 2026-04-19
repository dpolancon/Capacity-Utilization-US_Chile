# AR Corridor — Estimation Strategy Note
**Date:** 2026-04-13  
**Estimator family:** DOLS (Dynamic OLS)

## Theoretical lineage
- Saikkonen (1991): foundational asymptotic efficiency theory for modified OLS in cointegrating regressions
- Stock & Watson (1993): canonical operational form — regress on contemporaneous levels plus leads and
  lags of first differences; asymptotically equivalent to Johansen/Ahn-Reinsel in the I(1) single-vector case

## US long-run identification target
The identifying regression is:

```
y_t = c + β₁·k_t + β₂·(ω_t·k_t) + leads/lags of Δk_t, Δ(ω_t·k_t) + ε_t
```

From estimated coefficients:
```
θ̂_t = β̂₁ + β̂₂·ω_t
```

ε_t = ln(μ_t) is the long-run utilization residual.

## Benchmark normalization
μ_{t₀} = 1 at a benchmark year of approximate full-capacity operation.
ε̃_t = ε̂_t − ε̂_{t₀}
μ̂_t = exp(ε̃_t)

## Sample structure
- Full sample: all available observations (1929–2024 panel; Fordist window 1945–1978 is the focus)
- Sample A: t ≤ 1973 (pre-oil shock / pre-crisis)
- Sample B: t ≥ 1974 (post-oil shock / post-Fordist transition)

## Citation rule (locked)
- Saikkonen (1991): cite for asymptotic efficiency and time-domain correction justification
- Stock & Watson (1993): cite for operational DOLS specification, leads/lags implementation
