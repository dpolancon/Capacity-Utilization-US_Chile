---
name: cpr-im-ols
description: "High-performance framework for Vogelsang et al. (2024) Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS. Implements specification-dependent Monte Carlo simulation algorithms for non-standard fixed-b inference with endogenous structural breaks."
metadata:
  version: "2.0.0"
  last_updated: "2026-08-04"
  status: active
  dependencies:
    - R packages: cointReg, matrixStats, strucchange, parallel
  triggers:
    - "cpr imols"
    - "cmpr im-ols"
    - "custom critical values"
    - "simulate critical values"
    - "specification-dependent DGP"
---

# CMPR IM-OLS General Estimation & Simulation Protocol

This skill dictates the exact econometric pipeline necessary for valid fixed-$b$ inference when empirical cointegrating regressions contain polynomial combinations of non-stationary processes. Standard distributions fail due to the integration geometry of product variables ($I(1) \times I(1)$, etc.) and the recursive degrees of freedom loss from endogenous break audits.

---

## 1. Tool Integration
You must source the custom CMPR IM-OLS estimator (which handles the partial summing of interaction vectors and level augmentations internally) before invoking any empirical estimation or simulation loops:
```R
source(".agents/skills/cpr-im-ols/scripts/cpr_imols_estimator.R")
```

---

## 2. Structural Deconstruction of the Empirical Model
Prior to simulating critical values, rigorously decompose the specific empirical model into matrices:
- **$x\_base$ (Base Stochastic Levels)**: The purely $I(1)$ base vectors (e.g., $k_t, \omega_t$). These are used solely for endogeneity correction (via their first differences $\Delta x\_base_t$).
- **$x$ (Total Stochastic Design)**: All $I(1)$ level variables AND their polynomial products (e.g., $k_t \cdot \omega_t$). This is the matrix of variables whose parameters we are estimating.
- **$deter$ (Deterministic/Stationary Design)**: All constant intercept terms, deterministic trends, zero-mean stationary $I(0)$ demand controls, and step level-shift dummy variables ($D^{\text{step}}_{T_b} = \mathbb{I}(t \ge T_b)$).

---

## 3. Specification-Dependent Monte Carlo DGP ($H_0$)
To extract valid fixed-$b$ critical bounds for the specific test statistics, construct a Data Generating Process (DGP) under the null hypothesis of cointegration:

### Step 3.1: Base Process Simulation
For each simulation pass $m \in \{1 \dots N_{\text{sim}}\}$:
1. Simulate independent, zero-drift random walks for each base variable in $x\_base$: $x^*_{it} = x^*_{i,t-1} + e_{it}$ where $e_{it} \sim N(0, 1)$.
2. Simulate independent white noise $z^*_{kt} \sim N(0, 1)$ for any $I(0)$ controls present in $deter$.

### Step 3.2: Algebraic Recombination
1. Construct the polynomial interaction terms algebraically using the simulated random walks (e.g., $p^*_{jt} = x^*_{1t} \cdot x^*_{2t}$).
2. Assemble the simulated total design matrix $x^*$ and the base matrix $x\_base^*$.

### Step 3.3: Endogenous Break Replication (Dynamic Audit)
If the empirical specification leverages endogenous structural breaks (Bai-Perron protocol):
1. Compute a preliminary simulated dependent variable $y^*_{pre}$ as a linear combination of $x^*$ plus an independent normal error $u_t \sim N(0,1)$.
2. Run an OLS regression: $y^*_{pre} \sim x^*$.
3. Extract residuals and run the exact same structural break test algorithm applied empirically (e.g., `strucchange::breakpoints(..., h = 0.15)`).
4. Construct simulated step dummies from the detected breakpoints and append them to $deter^*$.

### Step 3.4: Simulated Estimation & Extraction
1. Generate the final simulated dependent variable: $y^*_t = deter^* \beta_d + x^* \beta_x + u_t$.
2. Pass the simulated matrices to the custom estimator: 
   `fit <- cointRegIM_CMPR(x=x^*, y=y^*, deter=deter^*, x_base=x\_base^*)`
3. Compute the $CT_{IM}$ (Type 2) statistic using `calc_vw_type2_stat`.
4. Extract the absolute values of the $t$-statistics for coefficients in $x^*$.

---

## 4. Parallel Orchestration Engine
Simulations must scale to $100,000$ iterations to achieve asymptotic tail convergence.
- On Windows architectures, utilize `parallel::makeCluster` (PSOCK clusters).
- Explicitly evaluate `clusterEvalQ(cl, { library(matrixStats); library(cointReg); library(strucchange) })` on worker nodes.
- Export the `cointRegIM_CMPR` and `calc_vw_type2_stat` functions to the cluster environment.
- Capture the $90\%, 95\%,$ and $99\%$ empirical quantiles from the simulated sampling distributions.

---

## 5. Inference Mapping Protocol
Map empirical parameter estimates to the correct simulated reference distribution:
- **Level Parameter ($t_{\text{level}}$)**: Benchmark empirical $t$-stats against the simulated quantile path derived from base $I(1)$ stochastic regressors.
- **Polynomial Parameter ($t_{\text{inter}}$)**: Benchmark empirical $t$-stats against the simulated quantile path derived from the product processes. (Interactions induce fatter tails than standard $I(1)$ distributions).
- **Global Test ($CT_{IM}$)**: Benchmark the empirical $S_{\text{Type 2}}$ statistic against the simulated $CT_{IM}$ bounds.

---

## 6. Matrix & Reporting Artifacts
- **Layout Constraints**: Implement matrices exceeding 6 dimensions using horizontal geometry (`\usepackage[margin=1in,landscape]{geometry}`).
- **Transparency Footnotes**: Every resulting LaTeX matrix must carry a `\multicolumn` wrapped footnote confirming that inference leverages a "custom N-pass Monte Carlo suite matched exactly to the integration geometry of the regressors and dynamic Bai-Perron break degrees of freedom."
