---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-25
layer: code_stage_design
created_by: E10V_I2_TRAP_RESOLUTION
updated_by: CPR_IMOLS_ESTIMATION_PROTOCOL_LOCK
role: methodological-rationale
stage: pre-estimation-design
tags:
  - chapter2/econometrics
  - chapter2/methodological-rationale
  - chapter2/imols-cpr
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# E11 — IM-OLS CPR Asymptotic Rationale

This document provides the theoretical and mathematical rationale for using the **Integrated Modified OLS (IM-OLS)** estimator in the Cointegrating Polynomial Regression (CPR) framework.

---

## 1. Polynomial Cointegration and Convergence Rates

When a cointegrating regression includes the interaction of two $I(1)$ variables, say $\tau_t$ (capital composition) and $\omega_t$ (wage share), the cross-product term $(\tau_t \cdot \omega_{t-1})$ is an $O_p(T)$ degree-2 polynomial CPR regressor. 

Under **Cointegrating Polynomial Regression (CPR)** theory (Park & Phillips, 2001; Wagner & Hong, 2016):
*   $\tau_t, \omega_t, k_t$ are linear $I(1)$ processes, whose partial sums scale at $O_p(T^{3/2})$ and whose estimated coefficients converge at rate $T^{-1}$.
*   The raw cross-product $(\tau_t \cdot \omega_{t-1})$ scales at $O_p(T)$ along the sample, its partial sum scales at $O_p(T^2)$, and its estimated coefficient ($\hat{d}$) converges at the super-consistent rate of $T^{-3/2}$.

---

## 2. Why FWL Orthogonalization is Forbidden ($S M_X \neq M_{SX} S$)

Pre-estimation Frisch-Waugh-Lovell (FWL) orthogonalization of the interaction term against linear components is mathematically invalid. Let $M_X = I - X(X'X)^{-1}X'$ be the projection operator in levels, and $S$ be the partial sum (cumulation) operator.

Because partial summation is not a unitary operator ($S'S \neq I$), **partial summation does not commute with projection**:
$$ S M_X \neq M_{SX} S $$

Residualizing the interaction in levels prior to taking partial sums alters the limiting Brownian functional:
$$ B_{z, \text{projected}}(r) = B_z(r) - \left( \int_0^1 B_z D' dr \right) \left( \int_0^1 D D' dr \right)^{-1} D(r) $$
This changes the distribution of the regressor under the continuous mapping theorem. Standard errors and t-statistics from FWL pre-filtered models are not asymptotically equivalent to native IM-OLS. The raw interaction must enter the full IM-OLS design directly.

---

## 3. Why DOLS and FM-OLS are Blocked

### 3.1 DOLS Regressor Explosion
Dynamic OLS (DOLS) eliminates endogeneity by adding leads and lags of first-differenced regressors. For a polynomial cross-product:
$$ \Delta(\tau_t \cdot \omega_t) = \tau_{t-1} \Delta \omega_t + \omega_{t-1} \Delta \tau_t + \Delta \tau_t \Delta \omega_t $$
This introduces high-frequency difference products into the design matrix, causing severe multicollinearity and parameter space expansion.

### 3.2 FM-OLS Path-Dependent Limit Failure
Fully Modified OLS (FM-OLS) assumes the endogeneity bias is a constant long-run covariance matrix. For the cross-product $\tau_t \omega_{t-1}$, the limiting functional is a product of Brownian motions ($B_\tau B_\omega$), which is not a martingale. Its path-dependent quadratic variation cannot be purged by a constant kernel estimator.

---

## 4. The IM-OLS Resolution

IM-OLS (Vogelsang & Wagner, 2014) purges endogeneity by augmenting the partial sum regression with unaccumulated levels ($k_t, \omega_t$):
$$ \sum_{s=1}^t y_s = a \cdot t + b \sum_{s=1}^t k_s + \psi \sum_{s=1}^t \tau_s + f \sum_{s=1}^t \omega_s + d \sum_{s=1}^t (\tau_s \omega_{s-1}) + \lambda_k k_t + \lambda_\omega \omega_t + \varepsilon_t $$

*   The nuisance levels ($\lambda_k k_t, \lambda_\omega \omega_t$) absorb endogeneity without dynamic lead/lag augmentation.
*   The rate normalization matrix $R_T = \operatorname{diag}(T^{1/2}, T, T, T, T^{3/2})$ separates exponents asymptotically.
*   Invariance across centering choices (Uncentered Main vs. Initial-State Robustness) is governed by [[N11_Centering_Protocol_Three_Regime]].

