---
type: note
status: active
layer: method
design_role: estimation_protocol
scope: chapter2_core_support
related_to:
  - R07_FGLS_threshold_cointegration_admissibility
  - R08_threshold_break_diagnostics_to_FGLS
  - R10_Binding_Specification_Layering_Rule
  - M10_Empirical_Identification_Framework
priority: high
---

# R12: FGLS Threshold Cointegration Implementation Protocol

## Core Claim

The Feasible Generalized Least Squares (FGLS) threshold cointegration model must be implemented in compliance with the robust inference framework of **Chen (2015, *Econometric Theory*)**. 

This protocol integrates:
1. **Saikkonen (1991) dynamic augmentation** (leads and lags of first differences of capital regressors) to address endogeneity.
2. **Cochrane-Orcutt generalized residual filtering** to eliminate serial correlation.
3. **Trimmed grid search** over the candidate threshold space.
4. **Haldrup et al. (2012) diagnostic ladder** to confirm integration orders ($I(1)$ levels) and test parameter stability.

---

## 1. Mathematical Model and Endogeneity Correction

In the presence of endogeneity and serial correlation in regressions with $I(1)$ regressors, ordinary OLS is inefficient. To resolve endogeneity, we adopt Saikkonen's (1991) dynamic augmentation. 

Let the base threshold cointegrating regression be:

$$y_t = \alpha' X_t + \delta' X_t I(q_{t-d} \le \gamma_0) + u_t$$

We decompose the error term $u_t$ to capture the correlation with regressor innovations $\Delta X_t$:

$$u_t = \sum_{j=-K}^K \beta_j \Delta X_{t-j} + \eta_t$$

where $\eta_t$ is assumed to follow a stationary autoregressive process:

$$\eta_t = \rho_1 \eta_t-1 + \dots + \rho_p \eta_t-p + \varepsilon_t$$

Substituting this into the base regression yields the dynamically augmented threshold model:

$$y_t = \alpha' X_t + \delta' X_t I(q_{t-d} \le \gamma_0) + \sum_{j=-K}^K \beta_j \Delta X_{t-j} + \eta_t$$

where $\varepsilon_t$ is a martingale difference sequence, and $K$ is the number of leads/lags.

---

## 2. The Cochrane-Orcutt FGLS Algorithm

To estimate the parameters efficiently, the Cochrane-Orcutt FGLS algorithm proceeds in two stages:

### Stage 1: First-Stage OLS and AR Selection
1. Perform OLS regressions on the dynamically augmented model for all candidate thresholds $\gamma$ in a trimmed search grid (excluding the outer 15% of observations).
2. Find the first-stage threshold estimate:
   $$\hat{\gamma}_{OLS} = \arg\min_{\gamma} SSR_{OLS}(\gamma)$$
3. Compute the OLS residuals:
   $$\hat{\eta}_t = y_t - \hat{\alpha}_{OLS}' X_t - \hat{\delta}_{OLS}' X_t I(q_{t-d} \le \hat{\gamma}_{OLS}) - \sum_{j=-K}^K \hat{\beta}_j \Delta X_{t-j}$$
4. Estimate an $AR(p)$ model on the residuals $\hat{\eta}_t$:
   $$\hat{\eta}_t = \rho_1 \hat{\eta}_{t-1} + \dots + \rho_p \hat{\eta}_{t-p} + \hat{v}_t$$
   Select the optimal lag order $p$ (typically $p \in \{1, 2\}$) using the Bayesian Information Criterion (BIC). Let the estimated coefficients be $\hat{\rho}_1, \dots, \hat{\rho}_p$.

### Stage 2: Second-Stage FGLS Grid Search
1. Define the Cochrane-Orcutt filter for any variable $W_t$:
   $$W_t^* = W_t - \sum_{j=1}^p \hat{\rho}_j W_{t-j}$$
2. Apply the filter to the dependent variable, the partitioned regressors, and the dynamic leads/lags:
   $$y_t^* = y_t - \sum_{j=1}^p \hat{\rho}_j y_{t-j}$$
   $$X_{1,t}^*(\gamma) = X_t I(q_{t-d} \le \gamma) - \sum_{j=1}^p \hat{\rho}_j X_{t-j} I(q_{t-d-j} \le \gamma)$$
   $$X_{2,t}^*(\gamma) = X_t I(q_{t-d} > \gamma) - \sum_{j=1}^p \hat{\rho}_j X_{t-j} I(q_{t-d-j} > \gamma)$$
   $$\Delta X_{t-k}^* = \Delta X_{t-k} - \sum_{j=1}^p \hat{\rho}_j \Delta X_{t-k-j}$$
3. Perform the grid search OLS on the Cochrane-Orcutt transformed variables over the candidate threshold space:
   $$\hat{\gamma}_{FGLS} = \arg\min_{\gamma} SSR_{FGLS}(\gamma)$$
4. Estimate the final FGLS coefficients at $\hat{\gamma}_{FGLS}$:
   $$\hat{\theta}_{FGLS} = \left( \sum_{t=p+1}^n Z_t^*(\hat{\gamma}_{FGLS}) Z_t^*(\hat{\gamma}_{FGLS})' \right)^{-1} \left( \sum_{t=p+1}^n Z_t^*(\hat{\gamma}_{FGLS}) y_t^* \right)$$
   where $Z_t^*(\gamma) = [X_{1,t}^*(\gamma)', X_{2,t}^*(\gamma)', \Delta X_{t-K}^*, \dots, \Delta X_{t+K}^*]'$.
5. Compute robust Newey-West HAC standard errors on the Cochrane-Orcutt transformed regression.

---

## 3. Implementation with Capital Stocks

The primary capital stock inputs for Chile are sourced from the provider repository:
`C:\ReposGitHub\K-Stock-Harmonization`

We estimate the capacity frontier using the reparameterized state vector to avoid near-multicollinearity:
- Log total productive capital scale: $k_t^{CL} = \ln(K^{NR}_t + K^{ME}_t)$
- Log capital composition ratio: $c_t = \ln(K^{ME}_t / K^{NR}_t) = k^{ME}_t - k^{NR}_t$
- Centered profit share: $\pi_t = 1 - \omega_t$ (centered)

### Specification A: Core Aggregate Scale Interaction
$$y_t = \alpha + \theta_0 k_t^{CL} + \phi \pi_t + \theta_1 (k_t^{CL} \pi_t) + \sum_{j=-K}^K \beta_j \Delta k_{t-j}^{CL} + \eta_t$$

### Specification B: Mechanization Bias (Composition-Mediated) Interaction
$$y_t = \alpha + \theta k_t^{CL} + \psi c_t + \phi \pi_t + \lambda (c_t \pi_t) + \sum_{j=-K}^K \beta_{j,k} \Delta k_{t-j}^{CL} + \sum_{j=-K}^K \beta_{j,c} \Delta c_{t-j} + \eta_t$$

For both specifications, we partition the regressors based on the lagged current account balance from the WBOP database:
$$q_{t-1} = \text{current\_account\_net\_gdp}_{t-1}$$

---

## 4. Pre-Flight Unit Root Battery

Before estimating the FGLS threshold model, a battery of unit root tests must be run on the estimation window to confirm the $I(1)$ status of the variables. The battery must include:
1. **Augmented Dickey-Fuller (ADF) test** with a drift to check for stochastic trends.
2. **KPSS test** with a level constant to check the null hypothesis of stationarity.
3. **Zivot-Andrews test** with endogenous breaks to ensure that apparent nonstationarity is not an artifact of an unmodeled deterministic break.

All variables must reject stationarity in levels and reject nonstationarity in first differences.

---

## References

Chen, H. (2015). Robust estimation and inference for threshold models with integrated regressors. *Econometric Theory, 31*(4), 778–810.

Saikkonen, P. (1991). Asymptotically efficient estimation of cointegration regressions. *Econometric Theory, 7*(1), 1–20.
