---
type: audit_report
status: active
depends_on: []
stage_scope: econometrics
country: US_CL
last_updated: 2026-08-11
updated_by: CMPR_CUSTOM_CV_BENCHMARKING_RESEARCH
layer: diagnostic
role: econometrics_audit
stage: section3_imols
tags: [fixed-b, asymptotics, monte-carlo, cmpr]
---

# Literature Review & Deep Research: Appending and Reporting Custom Fixed-$b$ Non-Standard Critical Values in Applied Econometrics

This report presents a literature review and best-practice guide on how custom Monte Carlo simulated asymptotic critical values—specifically under **fixed-$b$ asymptotics** (Kiefer & Vogelsang, 2002, 2005; Vogelsang & Wagner, 2014; Vogelsang et al., 2024) with **product processes** ($I(1) \times I(1)$) and **Bai-Perron step dummies**—are professionally formatted, tabulated, and appended in top-tier econometric journals (*Journal of Applied Econometrics*, *Journal of Econometrics*, *Journal of Business & Economic Statistics*) and doctoral dissertations.

---

## 1. Literature Review & Methodological Foundations

### 1.1 The Failure of Standard Asymptotics in Cointegrating Regressions
In non-stationary time-series regressions, standard asymptotic distributions ($\mathcal{N}(0,1)$, $\chi^2$) break down due to second-order endogeneity, non-zero cross-correlations, and non-linear functionals of Brownian motion. Classical estimators like Fully Modified OLS (FM-OLS) and Dynamic OLS (D-OLS) eliminate second-order endogeneity, but their test statistics remain highly sensitive to choices of Heteroskedasticity and Autocorrelation Consistent (HAC) bandwidths $M$ relative to sample size $T$.

Standard ("small-$b$") asymptotics assume that as $T \to \infty$, the ratio $b = M/T \to 0$. Under small-$b$, kernel choice and bandwidth selection disappear from the asymptotic distribution. However, in finite samples, non-zero $b$ creates substantial size distortions and over-rejection of the null hypothesis.

### 1.2 Fixed-$b$ Asymptotics (Kiefer & Vogelsang 2002, 2005; Vogelsang & Wagner 2014)
To solve finite-sample size distortions, **fixed-$b$ asymptotics** holds $b = M/T \in (0, 1]$ constant as $T \to \infty$. Under fixed-$b$:
1. The limiting distributions of HAC-standardized $t$-statistics and global cointegration diagnostics (such as the **Vogelsang–Wagner Type 2 statistic**, $S_{\text{Type 2}}$) explicitly depend on the bandwidth ratio $b$, the kernel function, and the number of stochastic regressors $k$.
2. As $b$ increases, the limiting distribution widens (thicker tails), reflecting the variability introduced by long-run variance estimation.
3. Consequently, **there is no single critical value** for a given significance level ($1\%, 5\%, 10\%$); instead, critical values are smooth functions of $b$ and $k$.

### 1.3 Cointegrating Multivariate Polynomial Regressions (CMPR) & Bai-Perron Breaks
When cointegrating specifications extend to **product processes** ($I(1) \times I(1)$) and **endogenous structural breaks** (Bai & Perron, 1998, 2003):
- **Polynomial Product Variables**: The limiting distribution involves stochastic integrals of Brownian motion products ($\int W_1(r) W_2(r) dW_3(r)$), yielding non-Gaussian distributions with considerably wider tail quantiles than standard linear $I(1)$ regressors.
- **Dynamic Structural Breaks**: When break dates $T_b$ are determined endogenously via sum of squared residual minimization, the break-search algorithm consumes degrees of freedom and shifts the limiting Brownian bridge projection.
- **Implication**: Pre-tabulated critical value tables (e.g., MacKinnon, 1996; Shin, 1994) are **invalid**. Researchers must execute custom specification-dependent Monte Carlo simulations matching the exact integration geometry, kernel, $b$-bandwidth ratio, and break selection protocol.

---

## 2. Professional Tabulation and Appendix Reporting Conventions

Top empirical economics journals and doctoral dissertations adhere to standard structural conventions when presenting custom Monte Carlo critical values:

1. **Main Text vs. Appendix Split**:
   - **Main Text Tables**: Present empirical parameter estimates, observed HAC test statistics (e.g., $S_{\text{Type 2}}$), and model bandwidth ratios ($b$). Standard errors or significance stars are mapped directly to custom simulated critical values.
   - **Dedicated Diagnostic Appendix**: A standalone section (e.g., *Appendix D: Cointegration Diagnostics and Fixed-$b$ Critical Values*) contains the full simulation methodology, provenance, and 2D surface tables.

2. **Structure of Critical Value Surface Tables**:
   - Tables are formatted as **2D grids** indexed by the bandwidth ratio $b \in [0.02, 1.00]$ (rows or sub-panels) across regressor dimensions $k$ and significance quantiles ($90\%, 95\%, 99\%$).
   - Multi-panel layouts separate inference across variable types: **Panel A** for base $I(1)$ level regressors, **Panel B** for product processes ($I(1) \times I(1)$), and **Panel C** for the global cointegration test ($S_{\text{Type 2}}$).

3. **Directional Null Disambiguation (Star Reversal Warnings)**:
   - Journals strictly require clear notation when reporting tests with opposing null hypotheses:
     - **Residual ADF (Engle-Granger)**: $H_0$: *No Cointegration* $\implies$ Stars indicate rejection of no cointegration (**Favourable** result).
     - **Shin LM / Vogelsang–Wagner Type 2**: $H_0$: *Cointegration* $\implies$ Rejection indicates spurious regression; therefore, an **absence of stars is the favourable result**.

---

## 3. Best Practices for Formatting and Reporting Custom Monte Carlo Simulated Bounds

Below are **5 best practices** for formatting, tabulating, and reporting custom Monte Carlo simulated bounds for product processes ($I(1) \times I(1)$) with Bai-Perron step dummies:

### 1. Exact Structural Algorithmic Replication of the Null Hypothesis ($H_0$)
- **Protocol**: The Monte Carlo Data Generating Process (DGP) under $H_0$ must replicate every step of the empirical pipeline. Generate independent zero-drift random walks, construct product interactions $I(1) \times I(1)$, execute the dynamic Bai-Perron break search (`strucchange::breakpoints`), construct structural break step dummies based on selected endogenous breaks, and extract test statistics. 
- **Why**: Static CV tables assume fixed exogenous breaks. Dynamic selection absorbs noise under $H_0$ and shifts tails outward.

### 2. Multi-Panel Surface Tabulation Indexed by Bandwidth Ratio ($b$) and Regressor Topology
- **Protocol**: Segregate critical bounds into panels (Panel A: $I(1)$ base terms, Panel B: $I(1) \times I(1)$ interaction terms, Panel C: Global $S_{\text{Type 2}}$ tests). 
- **Why**: Applying unified $I(1)$ CVs to $I(1) \times I(1)$ product processes leads to severe size distortions and spurious claims of cointegration.

### 3. Explicit Model-Specific Footnote Reporting in Main-Text Empirical Tables
- **Protocol**: In main-text tables, state the observed test stat alongside the specific critical bound mapping in a footnote (e.g., "$S_{\text{Type 2}} = 0.46$ (Simulated CVs for $b=0.12$: 4.12, 5.89)"). 

### 4. Complete Simulation Metadata & Convergence Provenance Logging
- **Protocol**: Include a *Simulation Provenance Block* in the appendix: $N_{\text{sim}} \ge 100,000$, pseudo-RNG seed, sample size $T$, kernel bandwidth, and break trimming fractions ($\epsilon = 0.15$).

### 5. Mandatory Null-Direction & Star-Reversal Disambiguation Notes
- **Protocol**: Mandate directional notes detailing the null hypotheses to prevent confusion (i.e. indicating that an absence of stars is favourable for Shin LM/$S_{\text{Type 2}}$ tests).
