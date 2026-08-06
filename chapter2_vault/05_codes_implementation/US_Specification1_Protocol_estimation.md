---
type: econometric_protocol
stage_scope: estimation-results
status: active
last_updated: 2026-08-04
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
---
# Econometric Protocol: Section 3.1 IM-OLS Cointegration Estimation Matrix

## 1. Executive Summary

This protocol governs the implementation of the empirical cointegration estimations for Section 3.1 of Chapter 2. It mandates the use of Cointegrating Multivariate Polynomial Regression (CMPR) via the Integrated Modified OLS (IM-OLS) estimator. To resolve severe multicollinearity and "I(2) trap" dynamics inherent in interactive integrated processes, **Frisch-Waugh-Lovell (FWL) orthogonalization** is strictly required for all interaction terms. Inference will be drawn via custom Monte Carlo simulations (N=100) to ensure exact finite-sample size control. Estimations will be performed via a two-tier process: Baseline (Without Breaks) and Endogenous Bai-Perron (Two-Pass Route).

## 2. Model Specifications

The estimation matrix explores combinations of structural variables across two primary specification families (A1 and A2) to identify the long-run transformation elasticity ($\theta$).

### 2.1 Variables and Dimensions

The following indices and variables define the combinatorial grid:

- **Capital Stock Variant (**$j$**):**
    
    - `private`: Private Core Capital ($K^{ME} + K^{NRC}$)
        
    - `aug`: Infrastructure-Augmented Capital ($K^{ME} + K^{NRC} + K^{GT}$)
        
- **Wage Share Variant (**$o$**):**
    
    - NFC sector wage share over gross value added.
        
    - NFC sector wage share over net value added (capital consumption adjusted).
        
    - Corporate wage share over gross value added.
        
    - Corporate wage share over net value added.
        
    - Shaikh and Tonak Wage Share Tier 1 (corporate wage share clean from double accounting).
        
    - Shaikh and Tonak Wage Share Tier 2 (corporate wage share clean from double accounting and supervisory salaries).
        
- **Composition Control (**$(1-\iota)$**):**
    
    - The dimensionless share of investments in machinery and equipment (excluding IPP).
        

### 2.2 Specification Family A1 (Double Interaction)

This family models the standard structural capacity relation:

$$A1_{j,o,d}: \quad y_t = \alpha + \beta k_{j,t} + \phi \omega_{o,t-1} + \theta (k_{j,t} \cdot \omega_{o,t-1}) + \delta X_{d,t} + u_t$$

Where: 
- $y_t$ represent real output for the Non Financial Corporate sector 
- $X_{d,t}$ represents the endogenous step dummy protocol for structural breaks via Bai-Perron (active only in Tier 2).

### 2.3 Specification Family A2 (Triple Interaction)

This family conditions the transformation elasticity on the physical composition of capital accumulation while preserving the autonomous realization effect of distribution:

$$A2_{j,o}: \quad y_t = \alpha + \beta k_{j,t} + \gamma \omega_{o,t-1} + \phi [\omega_{o,t-1} \cdot (1-\iota_{t-1})] + \theta [k_{j,t} \cdot \omega_{o,t-1} \cdot (1-\iota_{t-1})] + \delta X_{d,t} + u_t$$

## 3. Mandatory Implementation Directives

### 3.1 Frisch-Waugh-Lovell (FWL) Orthogonalization

To stabilize the IM-OLS design matrix and prevent singular matrices caused by the product of $I(1)$ series, **all interaction terms must be orthogonalized** prior to estimation. The auxiliary projection must strictly mirror the linear space of the target main estimation.

- **For A1 (Double Interaction):**
    
    1. Run OLS: $(k_j \cdot \omega_{o,t-1})$ on the full linear space $X_1 = [1, k_j, \omega_{o,t-1}, X_{d,t}]$ (where $X_{d,t}$ is included only during Tier 2).
        
    2. Extract residuals $\hat{u}_{int}$.
        
    3. Estimate IM-OLS main model using $\hat{u}_{int}$ in place of the raw interaction.
        
- **For A2 (Triple Interaction):**
    
    - Define the composite term $x_3 = \omega_{o,t-1} \cdot (1-\iota_{t-1})$.
        
    
    1. Run OLS: $(k_j \cdot x_3)$ on the full linear space $X_1 = [1, k_j, \omega_{o,t-1}, x_3, X_{d,t}]$ (where $X_{d,t}$ is included only during Tier 2).
        
    2. Extract residuals $\hat{u}_{triple\_int}$.
        
    3. Estimate IM-OLS main model using $\hat{u}_{triple\_int}$ in place of the raw triple interaction.
        

_Critical Note: The standalone components (_$\omega_{o,t-1}$ _for A1; both_ $\omega_{o,t-1}$ _and_ $x_3$ _for A2) MUST remain in both the auxiliary regression and the final IM-OLS specification to avoid omitted variable bias and ensure a complete design span._

### 3.2 Two-Tier Estimation Process

All models within the A1 and A2 families must be run under two distinct structural break protocols:

1. **Baseline (Without Breaks):** The model is run exactly as specified above, with no structural step dummies ($X_{d,t}$ is empty). This serves as the benchmark to expose the underlying parameter instability.
    
2. **Endogenous Bai-Perron Protocol (Two-Pass Route):**
    
    - **Pass 1:** Estimate the baseline IM-OLS model. Extract the residuals (`u.plus`).
        
    - **Pass 2:** Execute a Bai-Perron structural break audit (via `strucchange::breakpoints` with $h=0.15$ trimming) strictly on the `u.plus` residuals.
        
    - **Pass 3:** For any identified break dates, construct permanent step-shift dummies ($X_{d,t}$). Insert these dummies into the deterministic matrix (`deter`) and re-estimate the full FWL-orthogonalized IM-OLS model (ensuring the new auxiliary FWL regression also includes these dummies).
        

### 3.3 Inference via Monte Carlo Simulation

Given the non-linear integration orders of the regressors (e.g., $I(1) \times I(1)$) and the degrees of freedom lost during the Bai-Perron search, standard asymptotic critical values are invalid.

- All p-values and significance stars for coefficients ($\alpha$, $\beta$, $\phi$, $\theta$) and the Residual VW Type 2 Cointegration test must be derived from a custom Monte Carlo simulation suite.
    
- The simulation count is set to $N=100$ to ensure operational feasibility while providing exact finite-sample size control tailored to each specific DGP variant.
    

### 3.4 Export and Formatting

- All estimation results must be exported and formatted to precisely match the structure of the existing `.tex` files located at: `C:\ReposGitHub\Capacity-Utilization-US_Chile\reports\US_Section31_IMOLS_Results`
    
- Any previous reports in this directory that do not adhere to this FWL/Monte Carlo protocol are to be considered legacy.
    
- **Significance:** Apply stars (* $p<0.10$, $p<0.05$, *** $p<0.01$) derived strictly from the custom Monte Carlo critical values.
    
- **Diagnostics:** Report VIF computed on the uncentered level regressors space.
    
- **Cointegration Triad:** Report Residual ADF, Shin LM, and VW Type 2 statistics. Include the star-reversal warning in the table notes.