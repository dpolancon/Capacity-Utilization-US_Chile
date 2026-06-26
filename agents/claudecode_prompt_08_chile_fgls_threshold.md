# Claude Code Prompt 08: Chile Stage A.3 — FGLS Threshold Cointegration Estimation
## Regime-Specific Coefficient Recovery on the Capacity Frontier under Haldrup & Chen Diagnostic Ladder
## Estimation Window: 1940–1978 (N=39) or 1920–1987 | Default: 1940–1978

---

## 1. Context and Methodological Role

This prompt governs the implementation of `CL_S90_threshold_dummy_fgls_admissibility.R`. 

In the empirical chapter, we study the Chilean capacity utilization and capital accumulation dynamics. The first-layer identification of the transformation elasticity ($\theta_t$) is estimated globally using FM-OLS and IM-OLS. However, if the long-run relation is subject to regime shifts (e.g., driven by external balance-of-payments constraints or profit share thresholds), global estimators will average across distinct parameter vectors, producing fragile results.

To address this, we implement **Feasible Generalized Least Squares (FGLS) Threshold Cointegration Estimation** as a separate regime-layer analysis. This estimator is **admissible only after passing the diagnostic ladder** to justify that the nonlinearity is indeed threshold cointegration rather than a unit root problem, a deterministic structural break, or misspecified deterministic components.

### Econometric References:
- **Haldrup et al. (2012):** Guides the diagnostic ladder (unit roots, structural breaks, and nonlinearities) to establish the stochastic source of persistence before regime-sensitive estimation.
- **Chen (2013):** Establishes the threshold-estimation framework for integrated regressors with serial correlation and endogeneity, utilizing Cochrane-Orcutt FGLS and bootstrap inference.
- **Hansen (2000):** Establishes sample splitting and threshold estimation methods.

---

## 2. Repo Paths and File Structure

```r
REPO     <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
DATA_IN  <- file.path(REPO, "data/processed/Chile")
OUT_CSV  <- file.path(REPO, "output/stage_a/Chile/csv")
OUT_FIG  <- file.path(REPO, "output/stage_a/Chile/figs")

dir.create(OUT_CSV, recursive=TRUE, showWarnings=FALSE)
dir.create(OUT_FIG, recursive=TRUE, showWarnings=FALSE)
```

### Input Files:
- `data/processed/Chile/ch2_panel_chile.csv` (contains $y_t$, $k^{NR}_t$, $k^{ME}_t$, $\pi_t$, $\omega_t$)
- `data/processed/Chile/ECT_m_stage1.csv` (contains $ECT_{m,t}$, the balance-of-payments import propensity error correction term)

---

## 3. Theoretical Specification & Variable Construction

We estimate the capacity frontier using the reparameterized state vector to avoid near-multicollinearity between the capital stocks:

$$y_t = \alpha + A k_t^{CL} + B c_t + C (\pi_t c_t) + \phi \pi_t + \varepsilon_t$$

where:
- $y_t$: log real GDP (`y`)
- $k_t^{CL}$: log total productive capital scale $= \ln(K^{NR}_t + K^{ME}_t)$
- $c_t$: log-composition ratio $= k^{ME}_t - k^{NR}_t = \ln(K^{ME}_t / K^{NR}_t)$
- $\pi_t$: profit share (`pi_t = 1 - omega_t`), untransformed, centered around its sample mean
- $c_t \pi_t$: distribution-composition interaction term

The regime division is governed by a threshold variable $q_{t-d}$ crossing an unknown threshold $\gamma$:
- **Regime 1 (Slack/Constrained):** $q_{t-d} \le \gamma$
- **Regime 2 (Binding/Unconstrained):** $q_{t-d} > \gamma$

**Candidate Threshold Variables ($q_t$):**
1. Lagged balance-of-payments error correction term $ECT_{m,t-1}$ (Stage 1 ECT)
2. Profit share $\pi_t$ (direct distributional threshold)

### Structural Parameter Recovery:
For each regime $g \in \{1, 2\}$, we recover:
- Infrastructure elasticity: $\theta_{1,g} = A_g - B_g$
- Machinery elasticity: $\theta_{2,g} = A_g + B_g$
- Distribution-composition interaction: $\theta_{3,g} = 2C_g$

The distribution-conditioned transformation elasticity in regime $g$ is:
$$\hat{\theta}_{t,g} = \hat{\theta}_{1,g} (1 - \phi_t) + \hat{\theta}_{2,g} \phi_t + \hat{\theta}_{3,g} \pi_t \phi_t$$
where $\phi_t = K^{ME}_t / (K^{NR}_t + K^{ME}_t)$ is the machinery share of total productive capital in levels.

---

## 4. The Haldrup & Chen Diagnostic and Estimation Ladder

### Step 1: Pre-Flight Diagnostics (Haldrup Ladder)
- **Unit Roots:** Perform ADF and KPSS tests on all state variables ($y_t, k_t^{CL}, c_t, \pi_t$). Confirm all are $I(1)$ in levels and $I(0)$ in first differences.
- **Structural Breaks:** Run Zivot-Andrews unit-root tests to check for endogenous structural breaks in the individual series. Run Gregory-Hansen tests on the baseline linear relation to determine if cointegration is recovered when allowing for a single unknown structural shift.
- **Threshold Admissibility (Sup-Wald Test):** Run a Sup-Wald test for threshold presence (linear vs. 2-regime model) over a trimmed search grid of $\gamma$ (excluding the outer 15% of observations). Compute the bootstrap p-value of the Sup-Wald statistic using a residual bootstrap (500 replications).
  - *Rule:* If $p_{\text{boot}} \ge 0.10$, threshold behavior is not statistically supported. The script must log this warning but proceed to complete the estimation for robustness.

### Step 2: Cochrane-Orcutt FGLS Estimation (Chen Ladder)
To correct for serial correlation and obtain efficient estimates in the threshold model:
1. **First-Stage OLS Grid Search:** Perform OLS regressions for all candidate thresholds $\gamma$ in the trimmed range of the threshold variable. Identify $\hat{\gamma}_{OLS}$ that minimizes the sum of squared residuals:
   $$\hat{\gamma}_{OLS} = \arg\min_{\gamma} SSR_{OLS}(\gamma)$$
2. **Residual AR Modeling:** Compute OLS residuals $\hat{\varepsilon}_t = y_t - X_t(\hat{\gamma}_{OLS})' \hat{\theta}_{OLS}$. Fit an $AR(p)$ model to the residuals:
   $$\hat{\varepsilon}_t = \rho_1 \hat{\varepsilon}_{t-1} + \dots + \rho_p \hat{\varepsilon}_{t-p} + u_t$$
   Select the optimal lag order $p \in \{1, 2\}$ using the Bayesian Information Criterion (BIC).
3. **Cochrane-Orcutt Filtering:** Transform all variables ($y_t$ and the regime-partitioned regressors $X_{1,t}(\gamma), X_{2,t}(\gamma)$) using the estimated AR coefficients:
   $$y_t^* = y_t - \sum_{j=1}^p \hat{\rho}_j y_{t-j}$$
   $$X_{g,t}^*(\gamma) = X_{g,t}(\gamma) - \sum_{j=1}^p \hat{\rho}_j X_{g,t-j}(\gamma), \quad g \in \{1,2\}$$
4. **Second-Stage FGLS Grid Search:** Perform OLS on the transformed variables $y_t^*$ and $X_{g,t}^*(\gamma)$ over the same candidate thresholds $\gamma$. Identify the FGLS threshold estimate:
   $$\hat{\gamma}_{FGLS} = \arg\min_{\gamma} SSR_{FGLS}(\gamma)$$
5. **Coefficient Recovery:** Extract the final FGLS coefficients $\hat{\theta}_{FGLS} = (\hat{\theta}_{1,FGLS}, \hat{\theta}_{2,FGLS})'$ and compute standard errors using HAC standard errors on the transformed equation.

### Step 3: Threshold Confidence Intervals (Chen Robust CIs)
Construct the Likelihood Ratio (LR) statistic for the threshold parameter:
$$LR(\gamma) = \frac{SSR_{FGLS}(\gamma) - SSR_{FGLS}(\hat{\gamma}_{FGLS})}{\hat{\sigma}^2_{FGLS}}$$
The 95% confidence interval for $\gamma$ is the set of candidate values for which $LR(\gamma) \le 7.35$ (Hansen's asymptotic critical value). Plot this LR profile to visually inspect the threshold identification strength (weak vs. strong identification).

### Step 4: Reconstructing Capacity Utilization ($\mu_t$)
Using the recovered regime-specific coefficients:
1. Construct the predicted log productive capacity:
   $$\hat{y}_t^p = \hat{\alpha}_{\text{regime}(t)} + \hat{A}_{\text{regime}(t)} k_t^{CL} + \hat{B}_{\text{regime}(t)} c_t + \hat{C}_{\text{regime}(t)} (\pi_t c_t) + \hat{\phi}_{\text{regime}(t)} \pi_t$$
2. Impose the Chilean level-anchor protocol (defined in `D03`):
   $$\mu_{CL,1980} = 1.0 \quad \Rightarrow \quad \hat{y}_{t,\text{anchored}}^p = \hat{y}_t^p + (y_{1980} - \hat{y}_{1980}^p)$$
3. Derive capacity utilization:
   $$\log \mu_{CL,t} = y_t - \hat{y}_{t,\text{anchored}}^p \quad \Rightarrow \quad \mu_{CL,t} = \exp(\log \mu_{CL,t})$$

---

## 5. R Code Skeleton for Implementation

Your script should implement the following structure:

```r
# ==============================================================================
# CL_S90_threshold_dummy_fgls_admissibility.R
# Feasible Generalized Least Squares (FGLS) Threshold Cointegration
# ==============================================================================

library(tidyverse)
library(urca)
library(sandwich)
library(ggplot2)
library(scales)

# ---- 1. Setup paths and parameters
REPO     <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
DATA_IN  <- file.path(REPO, "data/processed/Chile")
OUT_CSV  <- file.path(REPO, "output/stage_a/Chile/csv")
OUT_FIG  <- file.path(REPO, "output/stage_a/Chile/figs")

dir.create(OUT_CSV, recursive=TRUE, showWarnings=FALSE)
dir.create(OUT_FIG, recursive=TRUE, showWarnings=FALSE)

# ---- 2. Load panel data & Stage 1 ECT
panel <- read_csv(file.path(DATA_IN, "ch2_panel_chile.csv")) %>% arrange(year)
ect_s1 <- read_csv(file.path(DATA_IN, "ECT_m_stage1.csv")) %>% 
  select(year, ECT_m) %>%
  arrange(year)

# Merge datasets and construct lagged threshold variables
df <- panel %>%
  left_join(ect_s1, by = "year") %>%
  mutate(
    # Log total capital stock (scale variable)
    k_CL = log(exp(k_NR) + exp(k_ME)),
    # Capital composition ratio
    c_t = k_ME - k_NR,
    # Profit share (untransformed, centered)
    pi_t = 1 - omega,
    pi_t_centered = pi_t - mean(pi_t, na.rm=TRUE),
    # Interaction term
    pi_c = pi_t_centered * c_t,
    # Threshold candidates
    q_ect_lag1 = lag(ECT_m, 1),
    q_pi_lag1 = lag(pi_t_centered, 1)
  ) %>%
  filter(year >= 1940, year <= 1978) # Default estimation window

# ---- 3. Haldrup Ladder: Unit Root & Structural Break Diagnostics
# [Implement ur.df(), ur.kpss(), and Gregory-Hansen tests here]
cat("\n=== Haldrup Ladder: Unit Root Diagnostics ===\n")
# Print test summaries and confirm I(1) integration orders

# ---- 4. Chen Threshold Estimation: OLS Grid Search
# Setup grid search parameters
threshold_var <- df$q_ect_lag1 # Choose default threshold variable
valid_idx <- which(!is.na(threshold_var))
y_vec <- df$y[valid_idx]
X_mat <- cbind(1, df$k_CL[valid_idx], df$c_t[valid_idx], df$pi_c[valid_idx], df$pi_t_centered[valid_idx])
q_vec <- threshold_var[valid_idx]

# Trim the top and bottom 15% of the threshold variable
trim_pct <- 0.15
q_sorted <- sort(q_vec)
n_obs <- length(q_vec)
trim_low <- q_sorted[floor(n_obs * trim_pct)]
trim_high <- q_sorted[ceiling(n_obs * (1 - trim_pct))]
candidates <- q_vec[q_vec >= trim_low & q_vec <= trim_high]

ssr_ols <- numeric(length(candidates))

for (i in seq_along(candidates)) {
  gamma <- candidates[i]
  regime1 <- as.numeric(q_vec <= gamma)
  regime2 <- as.numeric(q_vec > gamma)
  
  X1 <- X_mat * regime1
  X2 <- X_mat * regime2
  X_combined <- cbind(X1, X2)
  
  fit <- lm.fit(X_combined, y_vec)
  ssr_ols[i] <- sum(fit$residuals^2)
}

gamma_ols <- candidates[which.min(ssr_ols)]
cat(sprintf("First-Stage OLS Threshold: %.4f\n", gamma_ols))

# ---- 5. Cochrane-Orcutt Residual Transformation
# Fit AR model to OLS residuals
best_gamma_idx <- which.min(ssr_ols)
regime1_best <- as.numeric(q_vec <= gamma_ols)
regime2_best <- as.numeric(q_vec > gamma_ols)
X_best <- cbind(X_mat * regime1_best, X_mat * regime2_best)
ols_best <- lm(y_vec ~ X_best - 1)
e_hat <- residuals(ols_best)

# AR(p) selection (BIC check)
ar_fit1 <- arima(e_hat, order=c(1,0,0), include.mean=FALSE)
ar_fit2 <- arima(e_hat, order=c(2,0,0), include.mean=FALSE)
# Select order based on AIC/BIC
# [Implement selection logic and extract AR coefficients rho]

# Apply Cochrane-Orcutt transformation to y_vec and X_mat
# [Implement filtering step]

# ---- 6. Second-Stage FGLS Grid Search & Parameter Estimation
# Repeat grid search on filtered variables to find gamma_fgls
# [Implement FGLS grid search and estimate final coefficients]

# ---- 7. Chen Robust Inference and HAC Standard Errors
# Compute Newey-West HAC standard errors on the Cochrane-Orcutt transformed model
# Construct the Likelihood Ratio (LR) statistic profile for gamma

# ---- 8. Recover Structural Elasticities & Reconstruct mu_CL
# Recover A_g, B_g, C_g and structural parameters theta_1, theta_2, theta_3 for both regimes
# Reconstruct Y^p, anchor at 1980 (mu_CL = 1), and extract mu_CL series

# ---- 9. Plotting & Exports
# Generate and save the three requested plots
# Export results to CSV
```

---

## 6. Verification and Export Checklist

When you run this script, ensure you verify:
1. **Statistical Significance of Threshold:** Report the Sup-Wald statistic and its bootstrap p-value. Clearly note if threshold behavior is rejected but estimated anyway for robustness.
2. **Cochrane-Orcutt Residual Check:** Confirm that the residuals of the Cochrane-Orcutt transformed model are free of serial correlation (e.g., using a Ljung-Box test).
3. **Pinch-Year Level Anchor:** Verify that $\mu_{CL,1980} = 1.0$ exactly in the reconstructed utilization series.
4. **Economic Plausibility:** Confirm the recovered parameters match theoretical sign priors:
   - Positive capital elasticity in both regimes.
   - Machinery elasticity exceeds infrastructure elasticity ($\psi > \theta_0$) in the binding regime.
   - Interaction term ($C$ or $\theta_2$) is negative, showing high wage shares dampen machinery-led expansion.
