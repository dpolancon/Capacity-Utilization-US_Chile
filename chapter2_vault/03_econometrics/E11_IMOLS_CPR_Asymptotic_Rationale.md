---
type: econometric_protocol
status: active
depends_on: [chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-23
layer: code_stage_design
created_by: E10V_I2_TRAP_RESOLUTION
role: methodological-rationale
stage: pre-estimation-design
tags:
- chapter2/econometrics
- chapter2/methodological-rationale
- chapter2/imols-cpr
---

# E11 — IM-OLS CPR Asymptotic Rationale

This document provides the theoretical and mathematical rationale for using the **Integrated Modified OLS (IM-OLS)** estimator in the Cointegrating Polynomial Regression (CPR) framework to resolve the I(2) trap.

---

## 1. The I(2) Trap and CPR Convergence Rates

When a cointegrating regression includes the interaction of two $I(1)$ variables, say $\tilde{k}_t$ and $\omega_t$, the product term $(\tilde{k}_t \cdot \omega_t)$ is generally integrated of order two, $I(2)$. Standard linear cointegration theory assumes all regressors are $I(1)$, meaning that standard OLS, FM-OLS, or DOLS formulas are not directly applicable.

Under **Cointegrating Polynomial Regression (CPR)** theory (Wagner & Hong, 2016), the integration properties of the regressors are mixed:
*   $\tilde{k}_t$ and $\omega_t$ are $I(1)$ processes, converging at rate $T$.
*   $\hat{u}_t$ (the orthogonalized interaction residual) contains the $I(2)$ stochastic component, converging at rate $T^2$.

The OLS estimator in a CPR is super-consistent. However, the convergence rates differ:
*   The coefficients on $I(1)$ variables converge at rate $T^{-1}$.
*   The coefficient on the $I(2)$ interaction term ($d$) converges at the faster rate of $T^{-3/2}$.

---

## 2. Why DOLS and FM-OLS are Blocked for the CPR Baseline

### 2.1 The DOLS Regressor Explosion
Dynamic OLS (DOLS) eliminates endogeneity bias by adding leads and lags of first-differenced regressors. For an $I(2)$ interaction term, DOLS would require leads and lags of:
$$ \Delta(\tilde{k}_t \cdot \omega_t) = \tilde{k}_t \Delta \omega_t + \omega_t \Delta \tilde{k}_t $$
This introduces high-frequency difference products into the design matrix, causing:
1.  **Severe Multicollinearity:** The differenced terms are highly correlated with the level terms and their lags, causing near-singularity in the $(X'X)$ matrix.
2.  **Loss of Degrees of Freedom:** The parameter space expands rapidly, leading to poor finite-sample performance.

### 2.2 FM-OLS LRCV Estimation Complexity
Fully Modified OLS (FM-OLS) corrects for endogeneity and serial correlation by estimating the Long-Run Covariance (LRCV) matrix. When an $I(2)$ regressor is present, the LRCV matrix must capture the spectral density of the $I(2)$ process. This makes the FM-OLS estimator highly sensitive to the choice of kernel function and bandwidth parameter in finite samples, leading to unstable standard errors.

---

## 3. The IM-OLS Resolution

IM-OLS (Vogelsang & Wagner, 2014) bypasses both limitations:
1.  **No LRCV Estimation:** It corrects for serial correlation and endogeneity through a partial sum (integration) transformation of the entire model, eliminating the need to estimate long-run variance parameters.
2.  **No Dynamic Augmentation:** It does not require leads or lags of first differences, maintaining a sparse and stable design matrix.

### 3.1 Mathematical Transformation
The orthogonalized long-run levels relation:
$$ \tilde{y}_t = a + b \tilde{k}_t + f \omega_t + d \hat{u}_t + e_t $$
is transformed by taking cumulative sums from $s=1$ to $t$:
$$ \sum_{s=1}^t \tilde{y}_s = a \cdot t + b \sum_{s=1}^t \tilde{k}_s + f \sum_{s=1}^t \omega_s + d \sum_{s=1}^t \hat{u}_s + \sum_{s=1}^t e_s $$
By estimating this integrated relation using OLS:
*   The integrated regressors dominate the integrated noise $\sum e_s$ in the limit.
*   The endogeneity bias is purged, and the estimated coefficient $\hat{d}$ has a standard normal asymptotic distribution:
$$ t_{\hat{d}} \xrightarrow{d} \mathcal{N}(0, 1) $$
This validates standard inference ($t$-tests and Wald tests) using standard normal critical values.
