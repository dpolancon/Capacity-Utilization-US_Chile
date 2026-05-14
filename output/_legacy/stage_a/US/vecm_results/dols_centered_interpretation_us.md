# Centered DOLS θ-Identification — US Nonfinancial Corporate

## Estimation Details

- **Estimator**: DOLS with $p=2$ leads and lags of first differences
- **Standard errors**: Newey-West HAC, lag = $p+1 = 3$
- **Deflators**: $Y$ deflated by $P_Y$ (GDP deflator); $K$ deflated by $p_K$ (capital-goods deflator)
- **Centering**: $\omega^c_t = \omega_t - \bar{\omega}_{\text{sample}}$, computed within each window
- **Model**: $y_t = c + \bar{\theta} k_t + \beta_2 (\omega^c_t k_t) + \text{DOLS terms} + \varepsilon_t$
- **Recovery**: $\hat{\theta}_t = \hat{\bar{\theta}} + \hat{\beta}_2 (\omega_t - \bar{\omega}_{\text{sample}})$
- **Harrodian threshold**: $\omega_H = \bar{\omega} + (1 - \hat{\bar{\theta}})/\hat{\beta}_2$

## Deflator Provenance

- **$P_Y$ (Py_fred)**: source `income_accounts_NF.csv`, base year FRED index. Range 6.51–125.43. Rebasing to 2024 = 1: **NECESSARY** — index varies 19.3x over sample.
- **$p_K$ (pK_NF)**: source `US_corporate_NF_kstock_distribution.csv`, BEA capital-goods deflator for nonfinancial corporate. Range 3.41–100.00. Rebasing to 2024 = 1: **NECESSARY** — index varies 29.3x over sample.

Both deflators are **time-varying price indices**, not constants. The 2024 rebasing (divide by terminal-year value) is a normalization to express all real variables in 2024 purchasing power. It is not tautological: the indices span substantially different price levels across the sample, and the rebasing changes the level of logged variables by an additive constant that does not affect estimated slopes or cointegration relationships.

## Results Summary

### Full sample

- **Sample years**: 1929–2024 (economic label)
- **Regression years**: 1932–2022 (after DOLS trimming)
- **Active estimation window**: 1932–2022 (N = 91, after 2 leads + 2 lags + trend loss)
- **Effective N**: 91
- **Wage share**: mean = 0.6228, min = 0.5648, max = 0.6777
- **$\hat{\bar{\theta}}$**: 0.8648 (HAC SE = 0.0391, t = 22.108)
- **$\hat{\beta}_2$**: 0.0423 (HAC SE = 0.0378, t = 1.119)
- **R²**: 0.9927 (adj. = 0.9916)
- **Harrodian threshold**: N/A — wrong-sign slope
- **Equivalence**: |Δθ₁| = 2.22e-16, |Δθ₂| = 4.51e-16, max|Δfitted| = 1.78e-15

### Pre-1974 (<= 1973)

- **Sample years**: 1929–1973 (economic label)
- **Regression years**: 1932–1971 (after DOLS trimming)
- **Active estimation window**: 1932–1971 (N = 40, after 2 leads + 2 lags + trend loss)
- **Effective N**: 40
- **Wage share**: mean = 0.6320, min = 0.5945, max = 0.6777
- **$\hat{\bar{\theta}}$**: 0.9397 (HAC SE = 0.0470, t = 20.000)
- **$\hat{\beta}_2$**: -0.2919 (HAC SE = 0.1764, t = -1.655)
- **R²**: 0.9812 (adj. = 0.9729)
- **Harrodian threshold**: ω_H = 0.4253 — threshold outside observed sample range
- **Equivalence**: |Δθ₁| = 1.11e-15, |Δθ₂| = 1.50e-15, max|Δfitted| = 1.78e-15

### Post-1973 (>= 1974)

- **Sample years**: 1974–2024 (economic label)
- **Regression years**: 1977–2022 (after DOLS trimming)
- **Active estimation window**: 1977–2022 (N = 46, after 2 leads + 2 lags + trend loss)
- **Effective N**: 46
- **Wage share**: mean = 0.6147, min = 0.5648, max = 0.6549
- **$\hat{\bar{\theta}}$**: 0.8616 (HAC SE = 0.0199, t = 43.342)
- **$\hat{\beta}_2$**: 0.0293 (HAC SE = 0.0275, t = 1.065)
- **R²**: 0.9958 (adj. = 0.9942)
- **Harrodian threshold**: N/A — wrong-sign slope
- **Equivalence**: |Δθ₁| = 1.11e-16, |Δθ₂| = 7.91e-16, max|Δfitted| = 3.55e-15

### Fordist core (1945-1973)

- **Sample years**: 1945–1973 (economic label)
- **Regression years**: 1948–1971 (after DOLS trimming)
- **Active estimation window**: 1948–1971 (N = 24, after 2 leads + 2 lags + trend loss)
- **Effective N**: 24
- **Wage share**: mean = 0.6332, min = 0.6095, max = 0.6634
- **$\hat{\bar{\theta}}$**: 0.8352 (HAC SE = 0.0078, t = 106.597)
- **$\hat{\beta}_2$**: 0.0101 (HAC SE = 0.0948, t = 0.106)
- **R²**: 0.9992 (adj. = 0.9982)
- **Harrodian threshold**: N/A — wrong-sign slope
- **Equivalence**: |Δθ₁| = 6.66e-16, |Δθ₂| = 8.36e-16, max|Δfitted| = 0.00e+00

### Deep comparison (1940-1978)

- **Sample years**: 1940–1978 (economic label)
- **Regression years**: 1943–1976 (after DOLS trimming)
- **Active estimation window**: 1943–1976 (N = 34, after 2 leads + 2 lags + trend loss)
- **Effective N**: 34
- **Wage share**: mean = 0.6309, min = 0.5945, max = 0.6634
- **$\hat{\bar{\theta}}$**: 0.8082 (HAC SE = 0.0186, t = 43.413)
- **$\hat{\beta}_2$**: -0.2770 (HAC SE = 0.1079, t = -2.566)
- **R²**: 0.9939 (adj. = 0.9904)
- **Harrodian threshold**: ω_H = -0.0616 — no admissible positive threshold
- **Equivalence**: |Δθ₁| = 1.89e-15, |Δθ₂| = 1.78e-15, max|Δfitted| = 1.78e-15

## Fordist Core vs. Deep Comparison Window

The **Fordist core (1945–1973)** and **Deep comparison (1940–1978)** windows allow us to assess whether including the late-1930s transition years and the post-1973 break period materially alters the distributional slope estimate.
- **β̂₂ (Fordist core)**: 0.0101 (HAC SE = 0.0948, t = 0.106) — wrong-sign slope
- **β̂₂ (Deep comparison)**: -0.2770 (HAC SE = 0.1079, t = -2.566) — no admissible positive threshold

The difference is Δβ₂ = -0.28708 (-2846.1% relative to the Fordist-core magnitude).

This is a **qualitative change**: the sign of β₂ flips between the two windows. The Fordist core yields β̂₂ = 0.0101 while the Deep comparison yields β̂₂ = -0.2770. This suggests the distributional channel is **not robust** to the inclusion of 1940–1944 and 1974–1978 transition years.

The Deep comparison window adds 5 pre-war years (1940–1944) and 5 post-crisis years (1974–1978) to the Fordist core. If β₂ is stable, this confirms the distributional mechanism operates across the broader mid-century accumulation regime. If β₂ shifts materially, it indicates the Fordist core (1945–1973) is structurally distinct from the surrounding transition periods.

## Equivalence Verification

The centered parameterization is algebraically equivalent to the uncentered specification:

- Centered: $y_t = c + \bar{\theta} k_t + \beta_2 (\omega^c_t k_t) + \varepsilon_t$
- Uncentered: $y_t = c + \theta_1 k_t + \theta_2 (\omega_t k_t) + \varepsilon_t$
- Mapping: $\theta_1 = \bar{\theta} - \beta_2 \bar{\omega}$, $\theta_2 = \beta_2$
- Recovery: $\theta_t = \theta_1 + \theta_2 \omega_t = \bar{\theta} + \beta_2 (\omega_t - \bar{\omega})$

| Window | |Δθ₁| | |Δθ₂| | max|Δfitted| | max|Δresid| |
|--------|--------|--------|-------------|-------------|
| Full sample | 2.22e-16 | 4.51e-16 | 1.78e-15 | 5.17e-16 |
| Pre-1974 (<= 1973) | 1.11e-15 | 1.50e-15 | 1.78e-15 | 6.52e-16 |
| Post-1973 (>= 1974) | 1.11e-16 | 7.91e-16 | 3.55e-15 | 8.85e-16 |
| Fordist core (1945-1973) | 6.66e-16 | 8.36e-16 | 0.00e+00 | 6.33e-17 |
| Deep comparison (1940-1978) | 1.89e-15 | 1.78e-15 | 1.78e-15 | 1.72e-15 |

All equivalence tolerances are at or near machine precision, confirming algebraic equivalence.

---
*Generated: 2026-04-13 16:16:49.103721*
*Script: 43_dols_centered_refactor.R*
