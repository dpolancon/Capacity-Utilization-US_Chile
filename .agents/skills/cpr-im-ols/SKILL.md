---
name: cpr-im-ols
description: "High-performance framework for Vogelsang et al. (2024) Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS. Implements specification-dependent Monte Carlo simulation algorithms for non-standard fixed-b inference with endogenous structural breaks."
metadata:
  version: "2.1.0"
  last_updated: "2026-08-11"
  status: active
  dependencies:
    - R packages: cointReg, matrixStats, strucchange, parallel
  triggers:
    - "cpr imols"
    - "cmpr im-ols"
    - "custom critical values"
    - "simulate critical values"
    - "specification-dependent DGP"
    - "heterogeneous capital recovery"
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
1. Generate the final simulated dependent variable: $y^*_t = deter^* \beta_d + x^* \beta_x + u_t$. *(Note: A non-zero $\beta_x$ vector ensures cointegration holds for the valid simulation of the $CT_{IM}$ null distribution).*
2. Pass the simulated matrices to the custom estimator: 
   `fit <- cointRegIM_CMPR(x=x^*, y=y^*, deter=deter^*, x_base=x\_base^*)`
3. Compute the $CT_{IM}$ (Type 2) statistic using `calc_vw_type2_stat`.
4. **CRITICAL:** Extract the absolute values of the *centered* parameter $t$-statistics for coefficients in $x^*$. If $\beta_x$ was set to a non-zero vector in step 1, the simulated $t$-statistics *must* be explicitly centered around those true values: $t^* = |(\hat{\beta}^*_x - \beta_x) / SE(\hat{\beta}^*_x)|$. Extracting uncentered $t$-statistics from a non-zero DGP erroneously simulates the alternative hypothesis (power), generating massively inflated and invalid critical bounds.

---

## 4. Centering and FWL Orthogonalization Invariance
Centering a distributive interaction variable (e.g., $\omega$ at its initial condition) or applying a Frisch-Waugh-Lovell (FWL) orthogonalization to an interaction term ($k \cdot \omega \sim a + b \cdot k$) introduces strictly zero econometric bias to the estimated interaction parameter (e.g., the transformation elasticity $\theta_K$). 
- The strict linearity of the partial sum operator and the FWL projection guarantee that any location shift in the interaction multiplier is completely absorbed by the base stochastic coefficient ($\beta_k$), leaving $\beta_{k \cdot \omega}$ and the estimated residuals mathematically invariant.
- **Requirement:** This invariance strictly requires that the base term ($k$) is explicitly retained in the total stochastic design matrix ($x$). Omission of the base term violates the CMPR structural design, forces the interaction parameter to erroneously absorb the direct capital effect, and invalidates fixed-$b$ inference.

---

## 5. Parallel Orchestration Engine
Simulations must scale to $100,000$ iterations to achieve asymptotic tail convergence.
- On Windows architectures, utilize `parallel::makeCluster` (PSOCK clusters).
- Explicitly evaluate `clusterEvalQ(cl, { library(matrixStats); library(cointReg); library(strucchange) })` on worker nodes.
- Export the `cointRegIM_CMPR` and `calc_vw_type2_stat` functions to the cluster environment.
- Capture the $90\%, 95\%,$ and $99\%$ empirical quantiles from the simulated sampling distributions.

---

## 6. Inference Mapping Protocol
Map empirical parameter estimates to the correct simulated reference distribution:
- **Level Parameter ($t_{\text{level}}$)**: Benchmark empirical $t$-stats against the simulated quantile path derived from base $I(1)$ stochastic regressors.
- **Polynomial Parameter ($t_{\text{inter}}$)**: Benchmark empirical $t$-stats against the simulated quantile path derived from the product processes. (Interactions induce fatter tails than standard $I(1)$ distributions).
- **Global Test ($CT_{IM}$)**: Benchmark the empirical $S_{\text{Type 2}}$ statistic against the simulated $CT_{IM}$ bounds.

---

## 7. Heterogeneous Capital & Time-Varying Elasticity Recovery (Specification B)
When executing models with heterogeneous capital stock (e.g., machinery vs. structures) and distributive interaction variables:
- **Auxiliary FWL Orthogonalization**: Recover the structural base elasticities ($\theta_{\text{NRC}}^{\text{str}}$, $\theta_{\kappa}^{\text{str}}$) by running auxiliary Frisch-Waugh-Lovell (FWL) regressions of the interaction terms against the base state variables. This purges the linear dependence and isolates the pure structural yields.
- **Asset-Weighted Aggregate Elasticity**: Construct the time-varying aggregate transformation elasticity path using physical asset shares ($s_{\text{ME},t}$) and the structural marginal yields: $\theta_t^{\text{Aggregate}} = \theta_{\text{NRC}}^{\text{str}} + s_{\text{ME},t} \cdot MP_{\kappa,t}^{\text{str}}$.
- **Pinch-Year Anchoring**: When recovering implicit capacity utilization ($\mu_t$), integrate the differential capacity law anchored strictly to the historical Pinch Year (e.g., 1973 where $\mu_{1973} \equiv 100\%$). Avoid arbitrary average-centering.
- **Visualization Bounds**: When plotting driving forces (e.g., relative asset prices vs. effective distributive pressure), base-index relative prices to the pinch year (e.g., $1973 = 1.00$) to guarantee structural bounding (e.g., $max \le 1.50$) while optimally preserving the rich historical variation.

---

## 8. Matrix & Reporting Artifacts
- **Multi-Interaction Table Taxonomy**: In models with multiple $I(1) \times I(1)$ interactions (e.g., Specification B with $\kappa \cdot C$ and $\kappa \cdot p^{\kappa}$), DO NOT pool interaction critical values into a single generic $t_{\text{inter}}$ row. Report individual simulated critical bounds for each distinct level ($t_{\text{NRC}}, t_{\kappa}$) and interaction parameter ($t_{\omega \kappa}, t_{\kappa p}$), as joint covariance geometry causes their tail distributions under $H_0$ to differ.
- **Full Structural Break Panel Coverage ($m=0 \dots m_{\max}$)**: Appendix tables MUST report simulated critical value panels for every break count present across the empirical model selection matrix (e.g., $m=0, 1, 2, 3, 4$). Omitting intermediate break counts ($m=1, 2, 3$) undermines forensic transparency, leaving demoted or alternative models unbenchmarked against their exact degree-of-freedom penalty.
- **Layout Constraints**: Implement matrices exceeding 6 dimensions using horizontal geometry (`\usepackage[margin=1in,landscape]{geometry}`).
- **Transparency Footnotes**: Every resulting LaTeX matrix must carry a `\multicolumn` wrapped footnote confirming that inference leverages a "custom N-pass Monte Carlo suite matched exactly to the integration geometry of the regressors and dynamic Bai-Perron break degrees of freedom."
