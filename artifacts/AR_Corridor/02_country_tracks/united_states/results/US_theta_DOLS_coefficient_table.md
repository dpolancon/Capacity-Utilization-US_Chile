# US θ Identification — DOLS Coefficient Table
**Estimator:** DOLS, p=2 leads/lags, Newey-West HAC standard errors  
**Specification:** y_t = c + β₁·k_t + β₂·(ω_t·k_t) + leads/lags + ε_t  
**θ̂_t = β̂₁ + β̂₂·ω_t**  

| Parameter | Full sample | Pre-1974 (≤1973) | Post-1973 (≥1974) | Fordist core (1945–1973) |
|-----------|-----------|-----------|-----------|-----------|
| β̂₁ (k_t) | 0.8569 | 1.2653 | 0.8574 | 0.9400 |
| (HAC s.e.) | (0.0493) | (0.0727) | (0.0189) | (0.0191) |
| β̂₂ (ω_t·k_t) | -0.0011 | -0.4949 | 0.0008 | -0.1246 |
| (HAC s.e.) | (0.0298) | (0.0934) | (0.0190) | (0.0279) |
| θ̂ at ω̄ | 0.8563 | 0.9523 | 0.8579 | 0.8610 |
| ω̄ (sample mean) | 0.6228 | 0.6325 | 0.6157 | 0.6333 |
| Harrodian threshold ω_H | 131.5970 | -0.5360 | -179.8173 | 0.4819 |
| ω_H in sample range? | NO | NO | NO | NO |
| N (after trimming) | 93 | 44 | 50 | 30 |
| R² | 0.9902 | 0.9823 | 0.9954 | 0.9982 |

**Note:** Harrodian threshold ω_H = (1 − β̂₁) / (−β̂₂) is the wage share at which θ̂ = 1.  
If ω_H lies inside the sample range [ω_min, ω_max], the crisis-trigger interpretation is confirmed.  
Standard errors corrected for heteroskedasticity and autocorrelation (Newey-West, automatic bandwidth).
