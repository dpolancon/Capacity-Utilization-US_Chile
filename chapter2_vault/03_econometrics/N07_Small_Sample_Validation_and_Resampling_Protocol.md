---
type: econometrics
status: active
depends_on:
  - chapter2_vault/03_econometrics/N05_Capital_Integration_Order_Comprehensive_Audit.md
  - chapter2_vault/03_econometrics/N06_Kappa_Identification_and_IMOLS_Exogeneity_Paradox.md
stage_scope: layer_2_integration
country: US_CL
last_updated: 2026-07-25
layer: econometrics
scope: all_agent_sessions
subtype: econometric_synthesis
blocks: []
priority: reference
---

# N07 — Small-Sample Validation & Resampling Protocol for Super-Consistent Estimators ($15 \le N \le 30$)

This document synthesizes the theoretical and empirical literature on validating single-equation super-consistent cointegration estimators (FM-OLS, DOLS, IM-OLS) in small macro samples ($15 \le N \le 30$). It addresses the "Economic Relevance" of regime-specific choice-of-technique elasticities ($\hat{\gamma} \in [2.15, 3.03]$) and provides a concrete, reproducible validation architecture using time-series wild bootstrapping and Fixed-$b$ asymptotic corrections.

---

## 1. Executive Summary & Core Verdicts

1. **Failure of Standard Resampling (MBB / Subsampling):** Moving Block Bootstrap (MBB) and Subsampling fail in small cointegrated samples ($N \le 30$) because block-splicing creates artificial step discontinuities in $I(1)$ series and breaks residual stationarity.
2. **Superiority of IM-OLS + Residual Wild Bootstrap + Fixed-$b$:** 
   - **IM-OLS** (Vogelsang & Wagner, 2014) avoids non-parametric kernel bandwidth choices (FM-OLS) and lead/lag parameter proliferation (DOLS).
   - **Residual Wild Bootstrap** (Cavaliere, Rahbek, & Taylor, 2012) preserves temporal dynamics and heteroskedasticity structure without block splicing.
   - **Fixed-$b$ Asymptotics** (Vogelsang & Wagner, 2014; Wagner & Hong, 2016) controls empirical test size under $H_0$ even when $N = 20$.
3. **Validation of "Economic Relevance":** If the 95% Wild Bootstrap Confidence Interval strictly excludes $1.0$ (e.g., $[1.42, 3.28]$) and structural stability tests (`strucchange::supF`) show no breaks within the window, the point elasticity $\hat{\gamma} > 2.0$ is **statistically distinct from unity** after purging small-sample bias. This confirms that short-sample estimates represent genuine choice-of-technique structural elasticities rather than small-sample estimation noise.

---

## 2. Finite-Sample Bias Mechanics ($15 \le N \le 30$)

### 2.1 The Small-Sample Breakdown by Estimator

| Estimator | Primary Small-Sample Failure Mode | Degrees of Freedom Drain | Nuisance Sensitivity | Asymptotic & Finite-Sample Assessment |
| :--- | :--- | :--- | :--- | :--- |
| **FM-OLS** | Non-parametric kernel bandwidth under-smoothing ($M_N \approx 2-3$). High variance in LRCV matrix. | Minimal ($df = N - k - 1$). | High sensitivity to bandwidth $M_N$ and kernel selection. | $O(N)$ super-consistent, but severely distorted standard errors in small samples. |
| **DOLS** | Extreme lead/lag parameter proliferation and severe collinearity among $\Delta \boldsymbol{x}_{t-j}$. | Catastrophic ($df = N - k(p+q+1) - 1$). | Extreme sensitivity to lead/lag truncation $(p, q)$. | $O(N)$ super-consistent, but collapses when $N \le 25$ due to loss of $df$. |
| **IM-OLS** | Endpoint partial-sum leverage and sensitivity to sample boundary trends. | Low ($df = N - 2k - 2$). | Zero bandwidth/lag dependence; sensitive to boundary breaks. | **Preferred Baseline.** $O(N)$ super-consistent; requires Fixed-$b$ limit distribution. |

---

## 3. Evaluation of Resampling Architectures

### 3.1 Moving Block Bootstrap (MBB) & Subsampling (FAILS)
- **Stochastic Trend Discontinuity:** Rejoining random blocks of $I(1)$ variables $\boldsymbol{x}_t^*$ creates artificial step discontinuities at block boundaries.
- **Breakdown of Cointegration Dynamics:** The resampled residual $u_{1t}^* = y_t^* - \boldsymbol{x}_t^*{}' \hat{\boldsymbol{\beta}}$ accumulates $I(1)$ drift, violating residual stationarity.

### 3.2 Residual Wild Bootstrap (VALID)
- Re-fits a VAR on $\Delta \boldsymbol{x}_t$ and residuals $\hat{u}_{1t}$ to capture short-run dynamics.
- Multiplies orthogonalized residuals by Rademacher random variables ($w_t^* = \pm 1$).
- Preserves exact time-series dynamics, non-stationary volatility, and $I(1)$ persistence without splicing blocks.

### 3.3 Fixed-$b$ HAR Corrections (VALID)
- Treats $b = M_N / N$ as a fixed non-zero constant ($b \in (0, 1]$).
- Replaces standard normal critical values ($z = 1.96$) with non-standard limit distributions parameterized by $b$, providing exact size control at $N = 20$.

---

## 4. Contemporaneous Breakthroughs (2015–2026 Literature)

1. **Robustness of FM-OLS & IM-OLS in CPRs (Stypka, Wagner, Grabarczyk, & Kawka, 2025 - *Econometric Theory*):**
   Standard FM-OLS and IM-OLS estimators applied to non-linear interactive regressions (e.g., $w_t \cdot k_t$) yield the exact same limiting distribution as specialized Cointegrating Polynomial Regression (CPR) estimators. Specialized algorithms are unnecessary, provided Fixed-$b$ or Wild Bootstrap inference is applied.
2. **Panel & Small-Sample CPR (de Jong & Wagner, 2025):**
   Partial sum transformations (IM-OLS) automatically eliminate second-order endogeneity biases in polynomial/interactive specifications, making IM-OLS the single most robust estimator for short macro windows.

---

## 5. R Validation Protocol (Summary Workflow)

To test the "Economic Relevance" claim in R:

```R
library(cointReg)
library(sandwich)
library(strucchange)

# 1. Point Estimation via IM-OLS
fit_im <- cointRegIM(x = cbind(k, wk), y = y)
gamma_hat <- fit_im$theta[3]

# 2. Structural Stability Verification
supf <- sctest(y ~ k + wk, type = "supF", from = 0.15, to = 0.85)

# 3. Residual Wild Bootstrap (H0: gamma = 1.0)
# (See script in subagent report for full 999-iteration function)
# Calculate 95% Wild Bootstrap CI and two-tailed p-value.
```

If `p_val_wild < 0.05` and the 95% Wild Bootstrap CI strictly excludes 1.0 (e.g., $[1.42, 3.28]$), the claim of **Economic Relevance** is fully validated: the regime-specific choice of technique is super-elastic and statistically distinct from the long-run unit baseline.
