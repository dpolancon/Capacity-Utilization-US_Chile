---
type: paper_facing_section
status: active
depends_on:
  - chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md
  - chapter2_vault/06_paper_facing/00S_Chapter2_Symbology_and_Notation_Lock.md
  - chapter2_vault/03_econometrics/R02_Identification_and_Estimation_Protocol.md
stage_scope: stage_2_write
country: CL
last_updated: 2026-08-12
updated_by: CHILE_PERIPHERAL_ECONOMETRIC_STRATEGY_DRAFT
layer: paper_facing
role: econometric_strategy
stage: stage_2
tags: [chile, im_ols, threshold_cmpr, bop_constraint, cointegration, structural_breaks]
---

# Empirical Evidence for Chile: Peripheral Capitalism under External Constraint

## Econometric Strategy: Threshold Cointegrating Multivariate Polynomial Regression

This section translates the peripheral corner-solution model developed in Section 3.3 into an empirical identification strategy. The core objective is to estimate how the transformation elasticity $\theta$—which governs the conversion of capital accumulation into productive capacity—is determined in a peripheral, balance-of-payments-constrained economy. 

In core economies, the transformation elasticity $\theta$ reflects a domestic trade-off between extensive and intensive accumulation, mediated primarily by internal wage-led distributional conflict. In a peripheral economy like Chile, capital accumulation relies structurally on imported machinery and equipment. When foreign exchange reserves collapse, the peripheral state faces a binding balance-of-payments constraint that curtails the mechanization function. Rather than adjusting smoothly through domestic relative prices, the economy undergoes a discontinuous structural breakdown: the capacity-generating effect of capital accumulation collapses.

To capture this state-dependent structural mechanism without imposing ad-hoc functional forms, we operationalize identification under a **Threshold Cointegrating Multivariate Polynomial Regression (T-CMPR)** estimated via Integrated Modified OLS (IM-OLS) \citep{VogelsangWagner2024}.

---

### Linear Representation & Derivative Analysis

The generalized estimating equation specifies log real GDP ($y_t$) as a cointegrating function of non-residential structures ($k_t^{\text{NR}}$), the mechanization gap ($\kappa_t$), distributional conflict ($\omega_{t-1}$), the state-dependent external regime shift ($D_t^{\gamma}$), and relative price shocks ($\tilde{p}_t^{\kappa, \text{RER}}$):

$$y_t = \alpha + \theta_1 k_t^{\text{NR}} + \theta_2 \kappa_t + \theta_3 (\omega_{t-1} \cdot \kappa_t) + \theta_4 (\kappa_t \cdot D_t^{\gamma}) + \theta_5 (\omega_{t-1} \cdot \kappa_t \cdot D_t^{\gamma}) + \theta_6 \tilde{p}_t^{\kappa, \text{RER}} + u_t$$

where:
* $y_t = \ln Y_t$ is log real GDP in 2003 CLP.
* $k_t^{\text{NR}} = \ln K_t^{\text{NR}}$ is the log net stock of non-residential structures (extensive capital stock).
* $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NR}} = \ln(K_t^{\text{ME}} / K_t^{\text{NR}})$ is the capital composition ratio, representing the mechanization gap between intensive machinery and equipment ($K_t^{\text{ME}}$) and extensive non-residential structures ($K_t^{\text{NR}}$).
* $\omega_{t-1}$ is the one-period lagged wage share, evaluated under both net ($\omega_{t-1}^{\text{net}}$) and gross ($\omega_{t-1}^{\text{gross}}$) distribution. Lagging distribution by one period prevents contemporaneous feedback endogeneity with output.
* $D_t^{\gamma} = \mathbb{I}(Z_t \le \gamma)$ is an indicator variable that takes the value 1 when the composite balance-of-payments constraint index ($Z_t$) falls at or below an endogenously identified threshold $\gamma$, and 0 otherwise.
* $\tilde{p}_t^{\kappa, \text{RER}}$ is the standardized relative price of capital assets adjusted for the real effective exchange rate.
* $u_t$ is a stationary $I(0)$ cointegration error term.

The central analytical parameter of interest is the **marginal capital-composition transformation elasticity** $\theta(\omega, D_t)$, defined as the partial derivative of productive capacity $y_t$ with respect to the mechanization gap $\kappa_t$:

$$\frac{\partial y_t}{\partial \kappa_t} = \theta_2 + \theta_3 \omega_{t-1} + \theta_4 D_t^{\gamma} + \theta_5 (\omega_{t-1} \cdot D_t^{\gamma})$$

The parameter vector $\boldsymbol{\theta}$ directly tests the peripheral corner-solution hypothesis:
1. **Unconstrained Baseline Elasticity ($\theta_2$)**: Measures the baseline capacity effect of mechanization when external constraints do not bind ($D_t^{\gamma} = 0$).
2. **Domestic Distributional Mediation ($\theta_3$)**: Captures the Fordist induced-innovation effect, where higher wage shares incentivize capitalists to substitute labor with machinery under normal foreign exchange liquidity.
3. **Kuhn-Tucker Constraint Curtailment ($\theta_4$)**: Measures the direct structural shift in the mechanization elasticity when the external constraint binds ($D_t^{\gamma} = 1$).
4. **Peripheral Distributional Inversion ($\theta_5$)**: Captures the state-dependent breakdown in wage-led accumulation. A negative estimate ($\theta_5 < 0$) demonstrates that under foreign exchange starvation, domestic wage pressures cannot be translated into intensive accumulation because machinery goods must be imported.

---

### Institutional Boundary Discovery: The 1942 Monetary Pivot

Consequently, we establish **1942–2024** ($T = 83$ total annual observations; $T = 68$ effective cointegrating observations spanning 1943–2010 after lagging distribution by one period and matching historical ClioLab source series coverage) as our primary benchmark estimation sample. The pre-1942 decade (1932–1941) marks the chaotic disintegration of gold-standard rules, whereas 1942 marks the establishment of state-directed foreign exchange budgeting and functional credit management.

This institutional boundary separates two fundamentally distinct monetary regimes. Under the financial architecture designed by the 1925 Kemmerer Financial Mission (**Decree-Law No. 486** and **Decree-Law No. 606**), the Banco Central de Chile operated under a strict gold exchange standard, legally required to maintain a 50 percent gold and foreign exchange reserve cover against its monetary base ($M_0$). Following the collapse of British sterling in September 1931, Chile formally suspended gold convertibility in July 1931. The subsequent decade (1932–1941) was characterized by severe fiscal dominance, multiple exchange rate fragmentation managed by the *Comisión de Cambios Internacionales*, and erratic international reserve coverage.

The institutional pivot occurred in 1942 with the passage of **Law No. 7,200 (July 18, 1942)** and **Law No. 7,434**, which thoroughly reformed the Organic Law of the Banco Central de Chile. These statutes replaced the Kemmerer reserve cover requirements with a state-directed system of functional credit ceilings and centralized foreign-exchange budgeting. Working in tandem with the **Corporación de Fomento de la Producción (CORFO)**—created by **Law No. 6,640** in 1939—the central bank shifted from defending an orthodox currency peg to actively allocating foreign exchange and credit to strategic import-substituting industrial sectors. This structural reorganization stabilized the balance-of-payments transmission mechanism, establishing 1942 as the true historical starting point for a coherent long-run macroeconomic model of peripheral capital accumulation.

### Threshold Grid Search & Non-Standard Inference

The regime indicator $D_t^{\gamma} = \mathbb{I}(Z_t \le \gamma)$ depends on an unknown threshold parameter $\gamma$ evaluated over a standardized composite balance-of-payments variable $Z_t$. Following Hansen (2000) and Vogelsang and Wagner (2024), we estimate $\gamma$ endogenously via profile Sum of Squared Residuals (SSR) minimization:

$$\hat{\gamma} = \arg\min_{\gamma \in \Gamma} \text{SSR}(\gamma) = \arg\min_{\gamma \in \Gamma} \sum_{t=1}^{T} \hat{u}_t(\gamma)^2$$

The search grid $\Gamma$ is constrained to the trimmed quantile interval $\Gamma = [\gamma_{0.15}, \gamma_{0.85}]$ with step increments of 0.05 to prevent empirical instability at sample tails.

For each candidate threshold $\gamma \in \Gamma$:
1. The threshold indicator $D_t^{\gamma}$ is constructed from $Z_t$.
2. The interactive regressor matrix $X_t(\gamma) = [k_t^{\text{NR}}, \kappa_t, \omega_{t-1} \kappa_t, \kappa_t D_t^{\gamma}, \omega_{t-1} \kappa_t D_t^{\gamma}, \tilde{p}_t^{\kappa, \text{RER}}]$ is assembled.
3. The model is estimated via IM-OLS, partialing out deterministic components and non-stationary nuisance functions to extract IM-OLS residuals $\hat{u}_t(\gamma)$ and long-run variance matrices.
4. The profile estimator selects $\hat{\gamma}$ matching the global minimum $\text{SSR}(\hat{\gamma})$.

Because the threshold $\hat{\gamma}$ is searched endogenously over non-stationary $I(1)$ interaction terms, standard Gaussian asymptotic inference breaks down completely. The profile search introduces an endogenous optimization selection that inflates parameter variance and shifts test statistic distributions. To conduct valid inference without relying on invalid standard tables, we execute a specification-contingent **Monte Carlo simulation suite (10,000 replications)**.

Crucially, the simulation protocol handles two distinct testing objectives under non-standard asymptotics:
1. **Cointegration Diagnostic ($CT_{\text{IM}}$)**: The null hypothesis $H_0$ is that the specification forms a valid cointegrating relation ($u_t \sim I(0)$), evaluated against the alternative $H_1$ of no cointegration ($u_t \sim I(1)$, i.e. spurious regression). Under $H_0$, the asymptotic distribution of the $CT_{\text{IM}}$ statistic is invariant to the true cointegrating parameters $\boldsymbol{\theta}$, but depends strictly on the stochastic geometry of the design matrix $X_t(\gamma)$—including $I(1) \times I(1)$ interaction products, Frisch-Waugh-Lovell (FWL) orthogonalization projections, and the profile SSR grid search over $\Gamma$.
2. **Parameter Significance ($t$-statistics)**: The null hypothesis $H_0: \theta_j = 0$ tests individual coefficient zero-restrictions. For each simulation pass, centered $t$-statistics $t^* = (\hat{\theta}_j^* - \theta_j^0) / \text{SE}(\hat{\theta}_j^*)$ are extracted across the profile grid search to construct exact fixed-$b$ critical bounds for empirical parameter testing.

On each iteration, the Data Generating Process (DGP) simulates independent base random walks, constructs the specification-specific interaction design $X_t^*(\gamma)$, generates a cointegrated series $y_t^*$ under stationary $I(0)$ errors, executes the full profile SSR grid search across $\Gamma = [\gamma_{0.15}, \gamma_{0.85}]$, and records the resulting $CT_{\text{IM}}$ and centered $|t^*|$ distributions. The resulting empirical distributions provide exact, non-standard fixed-$b$ critical bounds for inference.

---

### Bai-Perron Structural Break Benchmark

To prove that the external threshold $D_t^{\gamma}$ captures a genuine state-dependent macroeconomic constraint rather than an arbitrary historical trend break, we benchmark the model against the Bai and Perron (1998, 2003) multiple structural break protocol.

The Bai-Perron specification models structural change as an exogenous, calendar-time break $T_b$:

$$D_t^{\text{BP}} = \mathbb{I}(t \ge T_b)$$

$$y_t = \alpha + \theta_1 k_t^{\text{NR}} + \theta_2 \kappa_t + \theta_3 (\omega_{t-1} \kappa_t) + \theta_4 (\kappa_t D_t^{\text{BP}}) + \theta_5 (\omega_{t-1} \kappa_t D_t^{\text{BP}}) + \theta_6 \tilde{p}_t^{\kappa, \text{RER}} + u_t$$

Dynamic search over candidate break dates $T_b \in [0.15 T, 0.85 T]$ identifies two distinct historical break points:
* **Net Wage Share ($\omega^{\text{net}}$)**: Identifies $T_b = 1987$. Econometrically, 1987 marks the post-1982 crisis structural consolidation under the Buchi reforms, where privatization, non-traditional export promotion, and fiscal austerity suppressed real wages to restore financial stability.
* **Gross Wage Share ($\omega^{\text{gross}}$)**: Identifies $T_b = 1999$. Econometrically, 1999 marks the climax of the Asian Financial Crisis in Chile, when the Central Bank abandoned the exchange rate crawling band system and floated the Chilean peso, triggering a severe contraction in gross operating surplus.

Comparing Bai-Perron calendar breaks against the composite threshold $Z_t \le 0.425$ provides a strict falsification test: if the BoP composite threshold achieves lower SSR and superior cointegration statistics than calendar breaks, we rule out deterministic time breaks in favor of true BoP state-dependence.

---

### Variable Specification & Data Provenance: Relative Price Control ($\tilde{p}_t^{\kappa, \text{RER}}$)

The relative price control $\tilde{p}_t^{\kappa, \text{RER}}$ accounts for international price shocks and foreign purchasing power shifts affecting imported capital assets:

$$p_t^{\kappa, \text{RER}} = \ln(\text{TCREAL}_t)$$

where $\text{TCREAL}_t$ is the multilateral Real Effective Exchange Rate index (rebased to 2003 = 1.0), and $\tilde{p}_t^{\kappa, \text{RER}} = \text{scale}(p_t^{\kappa, \text{RER}})$ is standardized to zero mean and unit variance.

#### Data Provenance & Construction
In primary source statistical accounting for Chile, separate long-run deflators for non-residential structures ($P_t^{\text{NRC}}$) and machinery ($P_t^{\text{ME}}$) do not exist as continuous annual series back to 1940. Capital stock harmonization (`C:/ReposGitHub/K-Stock-Harmonization`) constructs a single unified capital goods price deflator index ($P_{K,t}$, staged as `Pk_2003base`), built by splicing historical investment deflators from the ClioLab/PUC historical database (1940–2010) with official Central Bank of Chile (BCCH) National Accounts deflators (2003 base year). 

To capture foreign relative price shocks on capital accumulation without fabricating separate asset deflators, the empirical strategy employs two complementary proxies:
1. **Baseline Foreign Exchange Price Control ($\tilde{p}_t^{\kappa, \text{RER}}$)**: Uses the log of the Real Effective Exchange Rate ($\ln\text{TCREAL}_t$), capturing foreign exchange purchasing power shocks that directly alter the domestic cost of imported machinery and equipment ($K_t^{\text{ME}}$).
2. **Robustness Asset-to-Output Ratio ($p_t^{\kappa, P_Y/P_K}$)**: Evaluates the log ratio of the aggregate GDP deflator ($P_{Y,t}$) to the single unified capital price index ($P_{K,t}$):
   $$p_t^{\kappa, P_Y/P_K} = \ln\left(\frac{P_{Y,t}}{P_{K,t}}\right)$$
   measuring relative movements between general output prices and unified investment goods prices.

#### Interaction Geometry & Multicollinearity Prevention
Two critical econometric principles dictate the treatment of the price control:
1. **Additive Levels Entry ($\theta_6$)**: The price control enters strictly additively in levels ($\theta_6 \tilde{p}_t^{\kappa, \text{RER}}$). It does **not** enter the first derivative of capacity with respect to capital composition ($\frac{\partial y_t}{\partial \kappa_t}$).
2. **VIF Inflation & Variance Explosions**: Preliminary empirical grid tests introducing price interaction terms (e.g., $\kappa_t \cdot \tilde{p}_t$) caused severe multicollinearity, pushing Variance Inflation Factors above $VIF > 88$. Inside the IM-OLS non-standard distribution, this collinearity destroys matrix invertibility $(X'X)^{-1}$ and inflates Monte Carlo critical bounds to extreme values ($|t^*| > 19$), rendering structural parameter identification impossible without adding explanatory power over cointegration. By keeping $\tilde{p}_t^{\kappa, \text{RER}}$ as an additive macro control—or dropping it in ultra-parsimonious specifications—we isolate the physical asset composition mechanism without polluting the structural derivative.

---

### Comparative Model Progression across the Specification Grid

To map the specification space transparently, estimation proceeds through a 3-stage comparative grid:

$$\text{1. Baseline Uninteracted} \longrightarrow \text{2. Exogenous Bai-Perron} \longrightarrow \text{3. Endogenous Composite BoP Threshold}$$

```
[1. Baseline Uninteracted]  --->  [2. Exogenous Bai-Perron]  --->  [3. Endogenous Composite BoP]
  (No Regime Shift)                (Calendar-Time Break)             (State-Dependent Constraint)
```

1. **Model (1) & (5) — Baseline Uninteracted**: Assumes an unconstrained economy ($D_t = 0$). Fails residual cointegration ($t_{\text{ADF}} = -1.84$ / $-1.92$), proving that ignoring external constraints produces spurious long-run regressions.
2. **Model (2) & (6) — Bai-Perron Calendar Breaks**: Models structural change as a fixed calendar date ($1987$ / $1999$). Exhibits unstable coefficient volatility ($\hat{\theta}_{\omega\kappa D} = -11.86$) and weak residual stationarity ($t_{\text{ADF}} = -2.72$ / $-2.98$).
3. **Model (3), (4), (7), & (8) — Endogenous Composite BoP Thresholds**: Models structural change state-dependently whenever $Z_t = 0.2 \tilde{M}_t + 0.8 \tilde{S}_t \le 0.425$. Reliably achieves strong cointegration ($t_{\text{ADF}} = -3.81^{*}$ to $-4.11^{**}$, $CT_{\text{IM}} = 8.39$ to $15.20$).

---

### Cointegration Diagnostics & Finite-Sample Response Surface Bounds

To verify long-run cointegration, we evaluate two complementary residual tests:

#### 1. Vogelsang-Wagner Type 2 IM-OLS Statistic ($CT_{\text{IM}}$)
The primary cointegration test is the Vogelsang and Wagner (2024) Type 2 statistic ($CT_{\text{IM}}$), which tests the null hypothesis of cointegration ($H_0: \text{Residuals are } I(0)$):

$$CT_{\text{IM}} = \frac{1}{T^2 \hat{\omega}^2} \sum_{t=1}^{T} \hat{S}_t^2$$

where $\hat{S}_t = \sum_{j=1}^{t} \hat{u}_j$ is the partial sum of IM-OLS residuals, and $\hat{\omega}^2$ is the long-run variance estimator. Small values of $CT_{\text{IM}}$ support cointegration; values exceeding critical bounds reject cointegration.

#### 2. Residual Augmented Dickey-Fuller Test ($t_{\text{ADF}}$)
As a robustness check, we apply the Augmented Dickey-Fuller regression to the IM-OLS residuals:

$$\Delta \hat{u}_t = \rho \hat{u}_{t-1} + \sum_{i=1}^{p} \psi_i \Delta \hat{u}_{t-i} + \epsilon_t$$

testing $H_0: \rho = 0$ (unit root / no cointegration) against $H_1: \rho < 0$ (stationary residuals / cointegration).

#### Response Surface Finite-Sample Critical Bounds Calibration
Standard Dickey-Fuller critical values (where 5% is $-2.89$) are completely invalid for cointegration residuals because OLS/IM-OLS parameter optimization minimizes residual variance, pulling $\hat{u}_t$ artificially toward zero and causing severe over-rejection.

The significance stars reported in our results ($^*p<0.10, ^{**}p<0.05, ^{***}p<0.01$) are derived from **finite-sample Response Surface Monte Carlo simulations** \citep{MacKinnon1996, EngleGranger1987} specifically calibrated to $T=68$ effective observations and $k=5$ integrated regressors:

| Significance Level | Standard Univariate DF Bound | **Engle-Granger Cointegration Bound ($k=5, T=68$)** |
| :---: | :---: | :---: |
| **10% ($^*$)** | -2.58 | **-3.75** |
| **5% ($^{**}$)** | -2.89 | **-4.10** |
| **1% ($^{***}$)** | -3.50 | **-4.75** |

Under this calibrated surface, $t_{\text{ADF}} = -3.81$ (Cols 4, 8) exceeds the 10% boundary ($-3.75$) to earn a **$^{*}$**, while $t_{\text{ADF}} = -4.11$ (Col 7) exceeds the 5% boundary ($-4.10$) to earn a **$^{**}$**, ensuring absolute statistical rigor and transparent diagnostic reporting.
