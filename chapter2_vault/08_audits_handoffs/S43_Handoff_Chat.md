# Context and Master Prompt: Fixing the Section 3.1 IM-OLS Cointegration Report

This document provides the full background context, technical specifications, and a master execution prompt designed to lead an automated session or econometric pipeline through an actionable implementation plan to fix and update `us_section31_imols_results_v2.pdf`.

## 1. Executive Summary of Diagnostic Audit Findings

The audit of Section 3.1 (`2026-08-03_section31_cointegration_failure_diagnostics.md` and `2026-08-03_section31_cointegration_stars_audit.md`) resolved the apparent empirical deadlock where 16 out of 18 models failed residual ADF cointegration tests and 18 out of 18 models rejected Shin LM stability. Two primary technical defects were uncovered:

### A. The Residual ADF Lag Augmentation Defect

1. **The Bug:** `US_S50_section31_imols_estimation.R` previously ran an **unaugmented** Dickey-Fuller regression on the IM-OLS level residuals $\hat{u}_t$:
    
    $$\Delta \hat{u}_t = \gamma \hat{u}_{t-1} + e_t$$
    
    Because the IM-OLS residuals exhibit strong low-frequency autocorrelation ($\rho_1 \in [0.81, 0.96]$, Yule-Walker order $\text{AR}(2)$--$\text{AR}(4)$), omitting lagged differences inflated the residual variance, driving $t_{\text{ADF}}$ toward zero and causing false non-rejections of "no cointegration."
    
2. **The Fix:** Applying AIC/BIC-selected lag augmentation:
    
    $$\Delta \hat{u}_t = \gamma \hat{u}_{t-1} + \sum_{j=1}^p \psi_j \Delta \hat{u}_{t-j} + e_t$$
    
    whitens the error process. Once augmented ($p=1$ or $p=3$), **18 out of 18 models reject** $H_0: \text{no cointegration}$ at the 10% level, with **16 out of 18 rejecting at the 5% level**.
    

### B. Fixed-$b$ HAR Inference and Critical Value Alignment

1. **The Bug:** $S_{\text{Type 2}}$ (VW Type 2) statistics were previously evaluated against fixed constants (11.45 / 13.78 / 18.90) regardless of bandwidth ratio $b = \hat{B}/T$ or regressor count $q$. Coefficient-level $t$-statistics used standard normal cutoffs despite claims of fixed-$b$ HAR scaling.
    
2. **The Fix:** Digitized Vogelsang & Wagner (2014) primary critical-value tables across regressor dimensions $q \in \{1, 2, 3, 4\}$ (`COMMON_VW_fixedb_critical_values.R`). Applying continuous 2D interpolation over $(b, q)$ downgraded 39 overstated coefficient significance stars while leaving residual cointegration verdicts sound.
    

### C. Parameter Instability Decomposition

1. **Shin LM** $\leftrightarrow$ **Hansen** $L_c$ **Identity:** Shin's $C_{\text{Shin}}$ statistic is mathematically identical to Hansen's (1992) $L_c$ parameter stability test restricted to the intercept ($C_{\text{Shin}} = \frac{1}{T} L_c^{\text{intercept}}$). The 18/18 Shin rejections indicated level/intercept shifts across historical regimes (1944, 1965/68, 1981/82, 1996/99, 2010), not a structural failure of capital transformation elasticities ($\hat{\theta}_0, \hat{\theta}_1$).
    
2. **Step-Dummy Absorption:** Adding Bai-Perron step level-shift dummies ($D^{\text{step}}_{T_b} = \mathbb{I}(t \ge T_b)$) absorbs the level shifts. Under the model as estimated, Hansen's model-wide $L_c$ test confirms stability for **17 out of 18 specifications ("Held")**, leaving only 1 specification blocked (M2.8, $t_{\text{stat}} = -4.09$ vs $c_{0.05} = -4.10$).
    

## 2. Master Prompt for Implementation Plan Generation

Copy and paste the prompt below into your task runner or assistant session to execute the report correction workflow.

```
### MASTER PROMPT: GENERATE AND EXECUTE IMPLEMENTATION PLAN FOR REPORT FIX

ROLE & OBJECTIVE:
You are an expert quantitative econometrician and LaTeX publishing engine. Your task is to update, re-estimate, and recompile the Section 3.1 IM-OLS Cointegration Estimation Matrix report (`us_section31_imols_results_v2.pdf` / `us_section31_imols_results.tex`) based on the validated diagnostic audits (`2026-08-03_section31_cointegration_failure_diagnostics.md` and `2026-08-03_section31_cointegration_stars_audit.md`).

REPOSITORY CONTEXT:
- Target Report PDF: reports/US_Section31_IMOLS_Results/us_section31_imols_results_v2.pdf
- Target Report LaTeX: reports/US_Section31_IMOLS_Results/us_section31_imols_results.tex
- Estimation Script: codes/US_S50_section31_imols_estimation.R
- Shared Fixed-b CV Lookup: codes/COMMON_VW_fixedb_critical_values.R
- Stability Audit Script: codes/US_S51_section31_stability_audit.R

EXECUTION REQUIREMENTS:

1. R ESTIMATION ENGINE UPDATE (`codes/US_S50_section31_imols_estimation.R`):
   a. Ensure `adf_t_augmented()` with AIC/BIC lag selection is used for all residual ADF calculations (`Resid. ADF`).
   b. Ensure `COMMON_VW_fixedb_critical_values.R` is sourced and utilized for fixed-b HAR critical-value lookup across $q \in \{1, 2, 3, 4\}$ stochastic regressors and bandwidth ratio $b = \text{bandwidth}/T$.
   c. Record the chosen lag order $p$ and bandwidth ratio $b$ in the returned model metadata.
   d. Maintain effective sample size $N = 94$ (1929–2024 full NIPA window, 95 observations differenced, $N=94$ after lag-1 conditioning).

2. LATEX TABLES & REPORT RE-GENERATION (`us_section31_imols_results.tex`):
   a. Table 1 (Spec Set 1: Double Interactions M1.1–M1.6):
      - Update `Resid. ADF (t_ADF)` row with augmented ADF values and correct fixed-b significance stars.
      - Update coefficient stars for $\hat{\gamma}^{\text{step}}$, $\hat{\theta}_0$, and $\hat{\theta}_1$ to reflect fixed-b HAR standard errors.
   b. Table 2 (Spec Set 2 Part A: Triple Interactions M2.1–M2.6):
      - Update `Resid. ADF` values (confirm 6/6 rejecting $H_0: \text{no cointegration}$ at $p < 0.05$).
      - Align coefficient stars with fixed-b HAR cutoffs.
   c. Table 3 (Spec Set 2 Part B: Triple Interactions M2.7–M2.12):
      - Update `Resid. ADF` values. Flag M2.8 as blocked at 5% level ($t_{\text{stat}} = -4.09$ vs $c_{0.05} = -4.10$).
      - Align coefficient stars for $\hat{\theta}_0$, $\hat{\theta}_1$, and $\hat{\beta}_{cm}$.
   d. Text & Preamble Calibration:
      - Fix NIPA sample text to explicitly state $N = 94$ effective observations.
      - Update the data summary to note that `Resid. ADF` is lag-augmented via AIC/BIC to whiten AR(2)–AR(4) residual dynamics.
      - Clarify that fixed-b HAR critical values (Bartlett kernel, Newey-West bandwidth) are dynamically interpolated per model based on stochastic regressor count $q$ and bandwidth ratio $b$.

3. VAULT GOVERNANCE LOCK SYNC:
   a. Ensure `E17_Cointegration_Significance_Stars_Lock.md` reflects the active fixed-b interpolation methodology.
   b. Cross-reference `E18_Parameter_Stability_Audit_Protocol_Lock.md` for the parameter stability ledger (17 Held, 1 Blocked).

4. VERIFICATION & RECOMPILATION:
   a. Execute `Rscript codes/US_S50_section31_imols_estimation.R`.
   b. Recompile `us_section31_imols_results_v2.pdf` via `pdflatex`.
   c. Verify that every table cell in the recompiled PDF matches the newly computed CSV outputs in `output/US/S50_SECTION31_IMOLS/csv/s50_section31_results.csv`.

OUTPUT DELIVERABLE:
Provide a step-by-step implementation log detailing code edits made, exact numerical changes in the output matrix tables, LaTeX compilation status, and confirmation of table-to-data alignment.
```

## 3. Targeted LaTeX Table Revisions & Operational Checklist

Below is the specific mapping of mathematical notation, table rows, and footnotes to be updated during execution:

### A. Table Structure Updates

|   |   |   |
|---|---|---|
|**Table / Element**|**Prior Defective State**|**Corrected Operational State**|
|**Resid. ADF Statistic**|Unaugmented $t$-stat ($\Delta \hat{u}_t = \gamma \hat{u}_{t-1}$) yielding 16/18 non-rejections|Lag-augmented $t_{\text{ADF}}$ ($p \in \{1, 2, 3\}$ via AIC/BIC) yielding 18/18 rejections at 10% (16/18 at 5%)|
|**Fixed-**$b$ **Stars (Coefficients)**|Standard normal $z$-cutoffs (overstated significance)|Fixed-$b$ HAR $t$-statistics using Vogelsang & Wagner (2014) tables interpolated on $(b, q)$|
|**Fixed-**$b$ **Stars (**$S_{\text{Type 2}}$**)**|Hardcoded critical constants (11.45 / 13.78 / 18.90)|Exact fixed-$b$ Wald critical values matching regressor count $q \in \{1, 2, 3, 4\}$ and ratio $b$|
|**Sample Size** $N$|Inconsistent $N=95$ (text) vs $N=94$ (table foot)|Standardized $N=94$ across preamble text, tables, and notes|
|**Model Ledger Verdict**|"Cointegration breakdown"|**17 Held, 1 Blocked** (M2.8 blocked at 5% cutoff)|

### B. Mathematical Notation Standards for the Report

All inline and display equations in the report's text and footnotes must adhere strictly to LaTeX syntax:

1. **Cointegrating Vector:**
    
    $$y_t = \alpha + \theta_0 k_t + \theta_1 (k_t \cdot \omega_{t-1}) + \beta_{cm} (c-m)_{t-1} + \sum_{j} \gamma_j^{\text{step}} D_{T_{b,j}}^{\text{step}} + u_t$$
2. **Partial Sum Transformation (IM-OLS):**
    
    $$\tilde{y}_t = \sum_{s=1}^t y_s, \quad \tilde{k}_t = \sum_{s=1}^t k_s, \quad \tilde{u}_t = \sum_{s=1}^t u_s$$
3. **Augmented Residual ADF Regression:**
    
    $$\Delta \hat{u}_t = \gamma \hat{u}_{t-1} + \sum_{j=1}^p \psi_j \Delta \hat{u}_{t-j} + e_t$$
    
    where $H_0: \gamma = 0$ (no cointegration) vs $H_1: \gamma < 0$ (cointegration).
    

## 4. Verification & Integrity Checklist

Before finalizing the updated report, confirm the following integrity checks:

- [ ] **Augmentation Check:** Verify that `Resid. ADF` in `s50_section31_results.csv` reports AIC/BIC selected lag $p \ge 1$ for all specifications.
    
- [ ] **Star Alignment Check:** Confirm that no coefficient star uses naive $\pm 1.96$ or $\pm 2.58$ standard normal cutoffs; all must use interpolated fixed-$b$ critical values.
    
- [ ] **Table-to-CSV Reconciliation:** Cross-check Table 1, Table 2, and Table 3 in `us_section31_imols_results_v2.pdf` against `s50_section31_results.csv` to ensure 100% numerical identity.
    
- [ ] **Governance Lock Alignment:** Verify that `E17_Cointegration_Significance_Stars_Lock.md` and `E18_Parameter_Stability_Audit_Protocol_Lock.md` reflect the updated codebase.



---


### Mathematical Proof and Mechanics of $\lambda_1$ and $\lambda_2$ in WV (2014)

In Vogelsang and Wagner (2014a, Sections 2 and 5), testing for cointegration or parameter stability requires controlling for the long-run endogeneity and cross-correlation between the error process $u_t$ and the innovations of the integrated regressors $v_t = \Delta x_t$.

The matrix $\Omega$ represents the long-run covariance matrix (LRCV) of the joint vector $\eta_t = (u_t, v_t')'$:

$$\Omega = \begin{pmatrix} \Omega_{uu} & \Omega_{uv} \\ \Omega_{vu} & \Omega_{vv} \end{pmatrix}$$

To build pivotal fixed-$b$ test statistics (such as the IM-OLS Wald/t-tests or residual-based cointegration tests like the CPR KPSS-type $CT_{\text{IM}}$ test), the endogeneity of the regressors must be partialled out. The terms **$\lambda_1$ and $\lambda_2$** (or the scalar components of the Cholesky decomposition of $\Omega_{vv}$) arise in two specific contexts in their 2014 papers:

### 1. The Dynamic Triangular Decomposition (Full Design in CPRs)

In Vogelsang & Wagner (2014b) and Wagner & Hong (2016), when $x_t$ contains multiple integrated processes (e.g., $x_{1t}$ and $x_{2t}$), the limiting Brownian motion $B_v(r) = (B_{v1}(r), B_{v2}(r))'$ is transformed via a lower triangular matrix $L$:

$$\begin{pmatrix} B_{v1}(r) \\ B_{v2}(r) \end{pmatrix} = \Omega_{vv}^{1/2} W_v(r) = \begin{pmatrix} \lambda_{11} & \lambda_{12} \\ 0 & \lambda_{22} \end{pmatrix} \begin{pmatrix} W_{v1}(r) \\ W_{v2}(r) \end{pmatrix}$$

- **Why it matters for cointegration:** For CPR models (and interactive models like $k_t \cdot \omega_{t-1}$), the limiting distribution of the residual-based cointegration test $CT_{\text{IM}}$ depends on the powers and products of $B_v(r)$.
    
- **Full Design Condition:** If the model satisfies "Full Design" (Vogelsang & Wagner, 2014b; Wagner, 2023), the scalar variance components $\lambda_{ij}$ can be factorized out of the limit functionals. This leaves the asymptotic distribution under $H_0$ completely **nuisance-parameter free**, allowing the critical values to be tabulated via standard Brownian motion simulations ($W_v(r)$).
    

### 2. The Conditional Long-Run Variance $\omega_{u \cdot v}^2$

In Vogelsang & Wagner (2014a, Eq. 22–26), inference requires scaling by the conditional long-run variance of $u_t$ given $v_t$:

$$\omega_{u \cdot v}^2 = \Omega_{uu} - \Omega_{uv} \Omega_{vv}^{-1} \Omega_{vu}$$

When estimating $\omega_{u \cdot v}^2$ from the IM-OLS residuals $\tilde{u}_t$, standard OLS residuals lead to a non-zero mean in fixed-$b$ limits because $\tilde{u}_t$ is correlated with $S_{xt}$.

- To fix this, Vogelsang & Wagner adjust the IM-OLS residuals by regressing them on the augmented regressors $z_t$, producing **orthogonalized IM-OLS residuals** $\tilde{u}^*_t$.
    
- Scaling the partial sum of $\tilde{u}^*_t$ by $\hat{\omega}_{u \cdot v}^2$ generates the pivotal $S_{\text{Type 2}}$ (VW Type 2) and $CT_{\text{IM}}$ cointegration test statistics[cite: 1, 2].
    

### Implementation in R for Your Chapter 2 Pipeline

In your repository (`US_S50_section31_imols_estimation.R`), handling the Vogelsang & Wagner (2014) cointegration tests ($\lambda$-deconstructions and $S_{\text{Type 2}}$) involves three steps:

#### Step 1: Pre-Orthogonalize Interactive Regressors (Frisch-Waugh-Lovell)

To satisfy the Full Design condition and eliminate $I(2)$ collinearity between $k_t$ and the interaction $k_t \cdot \omega_{t-1}$:

1. Regress $(k_t \cdot \omega_{t-1})$ on the linear space $(1, k_t, \omega_{t-1})$.
    
2. Extract the orthogonalized residual $\hat{u}^{\text{inter}}_t$.
    
3. Run IM-OLS on the transformed partial sums using $\hat{u}^{\text{inter}}_t$ as the interactive regressor.
    

#### Step 2: Compute the Adjusted Residuals ($\tilde{u}^*_t$) for Fixed-$b$ Cointegration

Construct the adjusted IM-OLS residuals to purge nuisance parameters prior to running the Shin/KPSS-type ($C_{\text{Shin}}$) or VW Type 2 tests[cite: 1, 2]:

R

```
# 1. Obtain raw IM-OLS residuals
u_tilde <- S_y - S_X %*% beta_imols - X %*% gamma_imols

# 2. Project out endogeneity augmentation regressors Z_t = X_t
# To get orthogonalized residuals u_star (Vogelsang & Wagner 2014a, Eq. 24)
proj_Z <- X %*% solve(t(X) %*% X) %*% t(X) %*% u_tilde
u_star <- u_tilde - proj_Z

# 3. Estimate conditional long-run variance omega_u_v using Bartlett kernel
omega_hat_uv <- cointReg::lrvar(u_star, kernel = "Bartlett", bw = "Newey-West")
```

#### Step 3: Estimate the VW Cointegration Test Statistic ($S_{\text{Type 2}}$)

Calculate the scaled partial sum test statistic[cite: 1, 2]:

$$S_{\text{Type 2}} = \frac{1}{T^2 \hat{\omega}_{u \cdot v}^2} \sum_{t=1}^T \left( \sum_{s=1}^t \tilde{u}^*_s \right)^2$$

R

```
# Partial sum of adjusted residuals
S_u_star <- cumsum(u_star)

# VW Type 2 / Shin-type statistic for CPR
S_type2 <- sum(S_u_star^2) / (T_eff^2 * omega_hat_uv)
```

### Summary of What Changes in Your Report

1. **Parameter Stability vs. Cointegration Breakdown:** The 18/18 Shin LM rejections in your initial report were driven by intercept shifts ($\lambda_{\text{level}}$) rather than a breakdown of the cointegrating vector[cite: 1, 2].
    
2. **Absorption via Step Dummies:** By adding Bai-Perron step dummies ($D^{\text{step}}_{T_b}$), the level shifts are absorbed into the deterministic vector $D_t$[cite: 1, 2]. The resulting $S_{\text{Type 2}}$ and lag-augmented ADF tests confirm cointegration across **17 out of 18 models**[cite: 1, 2].

----

# Methodological Context and Implementation Guide for `cointReg::cointRegIM`

This document provides the foundational context and implementation logic for integrating your Section 3.1 Integrated Modified OLS (IM-OLS) pipeline directly into R using the native functions of the `cointReg` package[cite: 1, 2].

It bridges your theoretical Cointegrating Polynomial Regression (CPR) framework—grounded in Vogelsang & Wagner (2014) and Wagner & Hong (2016)—with the exact computational mechanics executed by `cointReg::cointRegIM`[cite: 1, 2].

## 1. Theoretical Context: Why Partial Sums and Kernels Are Required

### A. The Mechanics of `cointRegIM`

In standard linear or interactive cointegrating regressions ($y_t = X_t \theta + u_t$), serial correlation in $u_t$ and endogeneity between $u_t$ and the integrated regressor innovations $v_t = \Delta X_t$ introduce non-pivotal nuisance parameters into standard asymptotic distributions.

Rather than augmenting the model with leads and lags (DOLS) or modifying $y_t$ directly via explicit spectral density matrices (FM-OLS)[cite: 2, 3], IM-OLS applies a **Partial Sum Operator** ($\tilde{z}_t = \sum_{s=1}^t z_s$)[cite: 1, 2]:

$$S_{yt} = S_{Xt} \beta + X_t \gamma + D_t \delta + \tilde{u}_t$$

Where:

- $S_{yt} = \sum_{s=1}^t y_s$ transforms $I(1)$ variables into $I(2)$ space.
    
- $S_{Xt} = \sum_{s=1}^t X_s$ represents the cumulated stochastic regressors.
    
- $X_t$ (the level regressor) is added as an augmentation term to mathematically absorb endogeneity and long-run cross-correlation without requiring lead/lag choices.
    

### B. The Role of Kernel and Bandwidth in IM-OLS

While point estimates $\hat{\theta}_{\text{IMOLS}} = (\hat{\beta}, \hat{\gamma}, \hat{\delta})'$ are **tuning-parameter free**[cite: 1, 2], inference ($t$-statistics, Wald statistics, and cointegration tests) requires scaling by the conditional long-run variance of the residuals ($\omega_{u \cdot v}^2$)[cite: 1, 2].

In `cointReg::cointRegIM`:

1. **Kernel ($k(\cdot)$):** Tapers sample autocovariances $\hat{\gamma}(j)$ to ensure the long-run variance matrix remains positive semi-definite and statistically consistent. The **Bartlett kernel** (`kernel = "ba"`) is standard.
    
2. **Bandwidth ($M_T$):** Sets the lag truncation window. Under **Fixed-$b$ Asymptotics** (Vogelsang & Wagner 2014), the bandwidth ratio $b = M_T / T$ is held non-zero in the limit[cite: 1, 2]. As a result, critical values for hypothesis testing vary continuously with $b$ and the regressor count $q$, eliminating asymptotic size distortions[cite: 1, 2].
    

## 2. Low-Level Execution: Reconstructing `cointRegIM` step-by-step

To inspect `cointRegIM` without helper wrappers, run this bare-bones implementation. It executes matrix construction, baseline estimation, Bai-Perron structural break identification (`strucchange`), step-dummy expansion, and the final IM-OLS pass line-by-line.

R

```
library(cointReg)
library(strucchange)

# ==============================================================================
# 1. DATA PREPARATION & MATRIX CONSTRUCTION
# ==============================================================================
# Extract raw series from your data frame (e.g., df_data)
y     <- df_data$y_NFC
k     <- df_data$k_cap
w     <- df_data$omega_NFC_GVA_lag1
years <- df_data$year

# Initial state centering (1929 baseline)
w0  <- w[1]
w_c <- w - w0

# Create interaction term (Spec Set 1: Double Interaction)
inter <- k * w_c

# Design matrix of stochastic regressors X
X_mat <- cbind(k_cap = k, k_x_omega = inter)

# Deterministic matrix D (Start with constant intercept)
deter <- matrix(1, nrow = length(y), ncol = 1)
colnames(deter) <- "const"

# ==============================================================================
# 2. PASS 1: BASELINE IM-OLS ESTIMATION
# ==============================================================================
# Run IM-OLS via cointReg
# selector = c(1, 2) specifies automatic bandwidth selection via Newey-West
fit_pass1 <- cointReg::cointRegIM(
  x         = X_mat,
  y         = y,
  deter     = deter,
  selector  = c(1, 2),
  t.test    = TRUE,
  kernel    = "ba",
  bandwidth = "nw"
)

# Extract level residuals u.plus
u_pass1 <- fit_pass1$u.plus

# ==============================================================================
# 3. STRUCTURAL BREAK AUDIT (Bai-Perron on Pass 1 Residuals)
# ==============================================================================
# Identify persistent level shifts (15% trimming)
bp_audit <- tryCatch({
  strucchange::breakpoints(u_pass1 ~ 1, h = 0.15)
}, error = function(e) NULL)

# Expand deterministic matrix if breaks exist
if (!is.null(bp_audit) && !is.null(bp_audit$breakpoints) && !all(is.na(bp_audit$breakpoints))) {
  bp_indices <- bp_audit$breakpoints
  bp_years   <- years[bp_indices]
  
  for (byr in bp_years) {
    step_dummy <- ifelse(years >= byr, 1, 0)
    deter <- cbind(deter, step_dummy)
    colnames(deter)[ncol(deter)] <- paste0("D_step_", byr)
  }
}

# ==============================================================================
# 4. PASS 2: FINAL IM-OLS ESTIMATION WITH DYNAMIC STEP DUMMIES
# ==============================================================================
fit_pass2 <- cointReg::cointRegIM(
  x         = X_mat,
  y         = y,
  deter     = deter,
  selector  = c(1, 2),
  t.test    = TRUE,
  kernel    = "ba",
  bandwidth = "nw"
)

# ==============================================================================
# 5. PARAMETER EXTRACTION & INDEXING RULE
# ==============================================================================
# CRITICAL EXTRACTION RULE:
# cointRegIM() returns coefficients in the order: [Deterministic Terms | Stochastic Terms]
# You MUST skip ncol(deter) to extract the primary stochastic parameters (theta_0, theta_1).

n_deter <- ncol(deter)
coefs   <- as.vector(fit_pass2$theta)
sds     <- as.vector(fit_pass2$sd.theta)

alpha_hat   <- coefs[1]                        # Intercept
theta_0_hat <- coefs[n_deter + 1]              # Capital Elasticity
theta_1_hat <- coefs[n_deter + 2]              # Interaction Coefficient

# Fixed-b bandwidth ratio
bandwidth_M <- fit_pass2$bandwidth$number
T_obs       <- length(y)
b_ratio     <- bandwidth_M / T_obs

# Conditional Long-Run Variance
omega_u_v   <- fit_pass2$omega.u.v
```

## 3. Cointegration Testing & Post-Estimation Diagnostics

### A. The Cointegration Triad

To verify that the model constitutes a valid, stationary long-run attractor, you evaluate three complementary diagnostics[cite: 1, 2]:

```
                     ┌──────────────────────────────────────┐
                     │    IM-OLS RESIDUAL DIAGNOSTIC TRIAD   │
                     └──────────────────┬───────────────────┘
                                        │
        ┌───────────────────────────────┼──────────────────────────────┐
        ▼                               ▼                              ▼
┌───────────────────────┐   ┌───────────────────────┐   ┌──────────────────────────────┐
│  Lag-Augmented ADF    │   │      Shin LM          │   │      VW Type 2 (S_Type2)     │
├───────────────────────┤   ├───────────────────────┤   ├──────────────────────────────┤
│ H0: No Cointegration  │   │ H0: Cointegration     │   │ H0: Cointegration            │
│ Tests stationarity of │   │ Evaluates residual    │   │ Evaluates scaled partial-sum │
│ u.plus with AIC/BIC   │   │ score variance        │   │ variance via orthogonalized  │
│ lag augmentation.     │   │ (Level-shift signal)  │   │ residuals (u_star).          │
└───────────────────────┘   └───────────────────────┘   └──────────────────────────────┘
```

1. **Lag-Augmented Residual ADF ($t_{\text{ADF}}$):** Tests $H_0: \text{No Cointegration}$[cite: 1, 2]. **Bug Fix Requirement:** Must include lag augmentation ($\sum \psi_j \Delta \hat{u}_{t-j}$) selected by AIC/BIC to whiten residual serial correlation ($\rho_1 \in [0.81, 0.96]$)[cite: 1, 2].
    
2. **Shin LM ($C_{\text{Shin}}$):** Tests $H_0: \text{Cointegration}$[cite: 1, 2]. Identical to Hansen's (1992) $L_c$ parameter stability test on the intercept[cite: 1, 2].
    
3. **Vogelsang & Wagner Type 2 ($S_{\text{Type 2}}$):** Tests $H_0: \text{Cointegration}$[cite: 1, 2]. Measures scaled partial sum variance using orthogonalized residuals $\tilde{u}^*_t$.
    

### B. Fixed-$b$ Critical Value Interpolation Lookup

Because standard normal or static critical values are invalid across models with varying regressor counts ($q$) or bandwidth ratios ($b = M_T/T$), test statistics must be evaluated against $2D$-interpolated fixed-$b$ critical value lookup tables (Vogelsang & Wagner 2014)[cite: 1, 2]:

R

```
# Source repository lookup module
source("codes/COMMON_VW_fixedb_critical_values.R")

# Calculate VW Type 2 Statistic using orthogonalized residuals
# (cointRegIM calculates S_type2 using fit_pass2$u.plus and fit_pass2$omega.u.v)
vw_stat <- fit_pass2$stat.type2  # Or custom partial sum function

# Obtain fixed-b interpolated significance stars
# q = number of stochastic regressors (2 for Set 1, 3 for Set 2)
# b = M_T / T bandwidth ratio
q_regressors <- ncol(X_mat)

vw_stars <- fixedb_stars(
  stat      = vw_stat, 
  stat_type = "type2", 
  q         = q_regressors, 
  b         = b_ratio, 
  direction = "ge"
)
```

## 4. Summary of Output Verification

When stepping through `fit_pass2`, cross-check your console outputs against these target metrics:

- **Parameter Consistency:** Verify that $\hat{\theta}_0 \in (0, 1)$ confirms a positive, bounded capital elasticity under unbalanced growth[cite: 2, 3].
    
- **Step Dummy Absorption:** Confirm that adding Bai-Perron step dummies ($D^{\text{step}}_{T_b}$) absorbs intercept shifts (1944, 1965/68, 1981/82, 2010), stabilising the overall Hansen $L_c$ metric[cite: 1, 2].
    
- **Augmented ADF Rejections:** Verify that lag-augmented ADF statistics reject $H_0: \text{No Cointegration}$ at $p < 0.05$ across specifications[cite: 1, 2].




# MASTER PROMPT: SECTION 3.1 IM-OLS RE-ESTIMATION AND REPORT CORRECTION

## OBJECTIVE & CONTEXT
You are acting as the Lead Quantitative Econometrician for Chapter 2 of the dissertation ("Distribution, Technique, and the Transformation of Accumulation").
Your task is to re-run the 18-model Integrated Modified OLS (IM-OLS; Vogelsang & Wagner 2014) estimation battery for Section 3.1, apply the required diagnostic fixes, and re-compile the Section 3.1 results report (`us_section31_imols_results_v2.pdf`) and LaTeX source (`us_section31_imols_results.tex`).

### Repository Environment
* **Root Path:** `C:/ReposGitHub/Capacity-Utilization-US_Chile`
* **Primary Estimation Script:** `codes/US_S50_section31_imols_estimation.R`
* **Critical Value Module:** `codes/COMMON_VW_fixedb_critical_values.R`
* **Stability Audit Module:** `codes/COMMON_cointegration_stability_tests.R`
* **Target Output CSV:** `output/US/S50_SECTION31_IMOLS/csv/s50_section31_results.csv`
* **Target PDF Report:** `reports/US_Section31_IMOLS_Results/us_section31_imols_results_v2.pdf`

---

## 1. THE ECONOMETRIC DEFECTS TO FIX

### Defect A: Residual ADF Lag-Augmentation Bug
* **The Bug:** The previous code ran an unaugmented DF regression (`lm(diff(u) ~ u[-T] - 1)`). Because the IM-OLS residuals exhibit strong AR(1)–AR(4) serial correlation ($\rho_1 \in [0.81, 0.96]$), unmodeled dynamic variance drove the $t$-statistic towards zero, producing false non-rejections of "no cointegration" across 16/18 specifications.
* **The Fix:** Implement AIC/BIC-selected lag augmentation ($\sum_{j=1}^p \psi_j \Delta \hat{u}_{t-j}$) on the residual ADF test (`urca::ur.df(u, type = "none", selectlags = "AIC")`). Compare the resulting statistic against MacKinnon (2010) Engle-Granger $I(1)$ critical values indexed by total stochastic regressors ($m = k + 1$).

### Defect B: Nuisance Parameter Orthogonalization for $S_{\text{Type 2}}$ and Shin LM
* **The Mathematical Requirement:** Under Vogelsang & Wagner (2014a,b), residual-based cointegration tests ($S_{\text{Type 2}}$ and $C_{\text{Shin}}$) require orthogonalized IM-OLS residuals ($\tilde{u}^*_t$) to partial out the endogeneity between the error process $u_t$ and the regressor innovations $v_t = \Delta X_t$.
* **The Mechanics:**
  $$\tilde{u}_t = S_{yt} - S_{Xt}\hat{\beta} - X_t\hat{\gamma}$$
  $$\tilde{u}^*_t = \tilde{u}_t - X_t (X_t' X_t)^{-1} X_t' \tilde{u}_t$$
  $$\hat{\omega}^2_{u \cdot v} = \text{LongRunVar}(\tilde{u}^*_t \mid \text{Bartlett, Newey-West})$$
  $$S_{\text{Type 2}} = \frac{1}{T^2 \hat{\omega}^2_{u \cdot v}} \sum_{t=1}^T \left( \sum_{s=1}^t \tilde{u}^*_s \right)^2$$

### Defect C: Dynamic Step-Dummy Intercept Absorption & Shin/Hansen Equivalence
* **The Identity:** Shin's $C_{\text{Shin}}$ statistic is mathematically identical to Hansen's (1992) $L_c$ parameter stability test restricted to the intercept ($T \cdot C_{\text{Shin}} = L_{c,\text{intercept}}$). Rejections in $C_{\text{Shin}}$ indicate level/intercept shifts rather than a breakdown of the cointegrating vector $\hat{\theta}_0$.
* **The Absorption:** Incorporate first-pass Bai-Perron step level-shift dummies ($D^{\text{step}}_{T_b} = \mathbb{I}(t \ge T_b)$) into the deterministic matrix $D_t$. Re-evaluate test statistics against $2D$-interpolated fixed-$b$ lookup tables (`fixedb_stars(stat, stat_type, q, b)`), where $b = M_T / T$ and $q \in \{1, 2, 3, 4\}$.

---

## 2. STEP-BY-STEP IMPLEMENTATION TASKS

### Task 1: Update `US_S50_section31_imols_estimation.R`
1. Load `cointReg`, `strucchange`, `urca`, and source `codes/COMMON_VW_fixedb_critical_values.R`.
2. Update `run_s50_model()` to:
   * Calculate raw IM-OLS residuals ($\tilde{u}_t$) via `cointReg::cointRegIM`.
   * Run Bai-Perron breakpoint audit on $\tilde{u}_t$ (15% trimming, $h=0.15$).
   * Expand $D_t$ with identified step dummies $D^{\text{step}}_{T_b}$.
   * Calculate orthogonalized residuals $\tilde{u}^*_t = \tilde{u}_t - X (X'X)^{-1} X' \tilde{u}_t$.
   * Calculate $S_{\text{Type 2}}$ using $\tilde{u}^*_t$ and conditional long-run variance $\hat{\omega}^2_{u \cdot v}$.
   * Calculate lag-augmented ADF via `urca::ur.df(u, type = "none", selectlags = "AIC")`.
   * Lookup fixed-$b$ significance stars for $S_{\text{Type 2}}$ and $C_{\text{Shin}}$ using `b = bandwidth / T_obs` and $q = \text{ncol}(X_{\text{mat}})$.
3. Execute estimation loops over:
   * **Spec Set 1:** 6 Double-Interaction Models (M1.1–M1.6).
   * **Spec Set 2:** 12 Triple-Interaction Models (M2.1–M2.12).
4. Persist outputs to:
   * CSV: `output/US/S50_SECTION31_IMOLS/csv/s50_section31_results.csv`
   * RDS: `output/US/S50_SECTION31_IMOLS/rds/s50_fitted_models.rds`

### Task 2: Re-generate LaTeX Tables and PDF Report
1. Execute table generation routines in `US_S50_section31_imols_estimation.R` to update LaTeX fragments (`table_spec_set_1.tex`, `table_spec_set_2_part1.tex`, `table_spec_set_2_part2.tex`).
2. Update table footnotes in `us_section31_imols_results.tex` to explicitly state:
   * Residual ADF statistics incorporate AIC lag augmentation.
   * $S_{\text{Type 2}}$ and $C_{\text{Shin}}$ use orthogonalized IM-OLS residuals ($\tilde{u}^*_t$) scaled by conditional long-run variance $\hat{\omega}^2_{u \cdot v}$.
   * Significance stars reflect fixed-$b$ critical value interpolation over $b = M_T/T$ and regressor count $q$.
3. Compile PDF via `pdflatex` (two passes) to `reports/US_Section31_IMOLS_Results/us_section31_imols_results_v2.pdf`.

### Task 3: Update Governance Vault Locks
1. Update `E17_Cointegration_Significance_Stars_Lock.md` to document the lag-augmented ADF fix and the 2D fixed-$b$/$q$ lookup methodology.
2. Update `E18_Parameter_Stability_Audit_Protocol_Lock.md` to reflect that 17/18 models achieve "HELD" status once step level-shifts are absorbed.

---

## 3. EXECUTION COMMAND
Execute the complete pipeline, verify zero LaTeX compilation errors, confirm that 17/18 models reject $H_0: \text{No Cointegration}$ under augmented ADF, and display the final summary table.