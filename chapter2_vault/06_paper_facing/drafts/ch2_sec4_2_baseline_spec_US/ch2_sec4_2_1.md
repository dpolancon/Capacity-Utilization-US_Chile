---
type: paper_facing
status: draft
country: US
stage_scope: paper-facing
last_updated: '2026-08-05'
updated_by: CH2_PAPER_FACING_SOURCE_SCOPING
depends_on:
  - chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md
  - chapter2_vault/06_paper_facing/00S_Chapter2_Symbology_and_Notation_Lock.md
blocks: []
layer: paper_facing
role: Specification A econometric specification and IM-OLS estimation
stage: paper-assembly
tags:
  - chapter2/paper-facing
scope: chapter2
priority: core
---

# 4.2 Empirical Reconstruction of the U.S. Core: Baseline Homogeneous Capital (Specification A)

This section maps the theoretical model of induced mechanization developed in Section 3 into an empirical econometric specification for the U.S. core economy. We establish the formal crosswalk between the aggregate transformation elasticity $\theta(e_t)$ and a Cointegrating Multivariate Polynomial Regression (CMPR) framework estimated via Integrated Modified OLS (IM-OLS) on U.S. Non-Financial Corporate (NFC) data over 1929–2024 ($T = 94$ observations after lag conditioning).

## Econometric Specification and IM-OLS Estimation

The analytical model establishes that potential net output growth $g_{Y^p}$ is governed by the growth of productive net capital stock $g_K$ through the aggregate transformation closure:

$$g_{Y^p} = \theta g_K \quad \text{and} \quad \frac{d Y^p}{d K} = \theta$$

where $\theta$ represents the aggregate transformation elasticity of capital. In Marxian and post-Keynesian growth theory, $\theta$ is not a fixed technical constant. Following the Mechanization Productive Frontier (MPF) framework—built on Okishio's market anarchy threshold, Vidal's internally divided firm, and Marglin-style distributive grounding—$\theta$ varies endogenously with distributive pressures and technological choices:

$$\theta_t = \theta_0 + \theta_1 \cdot \text{Interaction}_t$$

where $\theta_0$ is the baseline elasticity of capacity output with respect to productive capital, and $\theta_1$ measures the marginal response of capital productivity to distributive and financialization pressures.

Standard linear cointegration techniques fail when applied to non-linear transformations and interactions of integrated processes. As established by Wagner and Hong (2016) and Wagner (2023), integer powers, products, and non-linear combinations of $I(1)$ processes are not themselves $I(1)$ processes. Regressing log output on log capital and interaction terms constitutes a Cointegrating Polynomial Regression (CPR). Estimating a CPR with conventional linear estimators yields invalid asymptotic inference and inflated test statistics unless specialized non-standard estimators and critical values are employed.

We specify the empirical cointegrating equation for U.S. Non-Financial Corporate Real Net Value Added ($y_t = \ln Y_t^{\text{NFC,NVA}}$) as:

$$y_t = \alpha + \theta_0 k_t + \theta_1 \text{inter\_ortho}_t + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$$

where $\alpha$ is the constant intercept, $k_t$ is log real net capital stock, $\text{inter\_ortho}_t$ is the orthogonalized interaction regressor, $\mathbf{D}_t$ is a vector of deterministic step level-shift dummies ($\boldsymbol{\gamma}' \mathbf{D}_t$), and $u_t$ is a stationary $I(0)$ error term under the null hypothesis of cointegration.

**Productive Capital Stock Variants ($k_t$).** Following the BEA Fixed Assets boundary protocols, we evaluate two alternative capital stock aggregates:
1. **Private Core Capital ($k_t^{\text{priv}}$):** $\ln(K_t^{\text{ME}} + K_t^{\text{NRC}})$, combining private machinery and equipment ($K^{\text{ME}}$) with nonresidential structures ($K^{\text{NR}}$). This represents the primary direct productive capacity of the corporate sector.
2. **Infrastructure-Augmented Capital ($k_t^{\text{aug}}$):** $\ln(K_t^{\text{ME}} + K_t^{\text{NRC}} + K_t^{\text{GT}}$), incorporating government-funded transportation and infrastructure assets ($K^{\text{GT}}$) as a public conditioning capital stock.

Intellectual Property Products ($K^{\text{IPP}}$) are strictly excluded from the core capital stock $K_{\text{cap}}$ and treated as a frontier conditioner or overhead cost, adhering to national accounting boundary rules.

#### B. Distributive Wage Share Variants ($\omega_{t-1}$)
We test three alternative wage share measures, conditioned at lag 1 to reflect the historical lag in capital investment planning:
1. **Baseline NFC NVA Wage Share ($\omega_{\text{NFC,NVA}}$)**: Ratio of NFC compensation of employees to NFC net value added ($\text{NFC\_COMP} / \text{NFC\_NVA}$). This reflects the aggregate corporate distribution of net product.
2. **Corporate NVA Wage Share ($\omega_{\text{CORP,NVA}}$)**: Ratio of total corporate compensation to total corporate net value added ($\text{CORP\_COMP} / \text{CORP\_NVA}$). This variant accounts for corporate financial sector adjustments, ensuring compliance with the "No Double Accounting Rule" by removing financial sector net interest distortions.
3. **Shaikh-Tonak Tier 2 Wage Share ($\omega_{\text{ST,Tier2}}$)**: Ratio of supervisory-adjusted productive worker compensation to NFC net value added ($v_{\text{prod}} / \text{NFC\_NVA}$). Grounded in Shaikh and Tonak (1994), this measure strips out administrative and supervisory salaries from total employee compensation, isolating the true variable capital spent on productive labor that directly engages in value creation.

#### C. Interaction Logic and Permutation Sets
We evaluate two distinct interaction specifications to isolate the transmission mechanism:
* **Specification Set 1 (Double Interactions)**: Uses the interaction term $k_t \cdot \omega_{t-1}$. This specification tests whether wage-share pressure directly alters the capital transformation elasticity without conditioning on financial overhead.
* **Specification Set 2 (Triple Interactions)**: Uses the interaction term $k_t \cdot \omega_{t-1} \cdot (1 - \iota_{t-1})$, where $\iota_{t-1} = K_{t-1}^{\text{IPP}} / (K_{t-1}^{\text{cap}} + K_{t-1}^{\text{IPP}})$ represents the ratio of intellectual property products to total corporate fixed assets. The term $(1 - \iota_{t-1})$ measures the proportion of corporate capital retained in physical productive assets relative to financialized overhead. This specification tests whether distributive wage pressure induces mechanization only when corporate cash flows are not diverted into financialized asset accumulation.

In both specification sets, distributive variables ($\omega_{t-1}$ and $\iota_{t-1}$) are centered at their 1929 initial state ($t_0$) prior to forming products, ensuring that baseline coefficient estimates remain interpretable at the historical initial condition.

**Frisch-Waugh-Lovell (FWL) Orthogonalization Protocol.** Uncentered interaction terms between integrated processes introduce severe multicollinearity. In our sample, raw interaction terms ($k_t \cdot \omega_{t-1}$) exhibit pairwise correlation coefficients exceeding $r = 0.99$ with base log capital $k_t$, producing Variance Inflation Factors (VIF) above 100. High VIFs inflate parameter standard errors and render hypothesis testing unreliable.

To resolve multicollinearity without altering the economic content of the model, we implement a strict Frisch-Waugh-Lovell (FWL) orthogonalization protocol. Before estimating the main cointegrating regression, we regress the raw interaction term on base log capital $k_t$, the constant intercept, and any active deterministic step dummies:

$$\text{inter\_raw}_t = a_0 + a_1 k_t + \mathbf{a}_2' \mathbf{D}_t + \text{inter\_ortho}_t$$

We extract the OLS residual $\text{inter\_ortho}_t$ and substitute it into the main regression. By construction, $\text{inter\_ortho}_t$ is strictly orthogonal to base capital $k_t$ and deterministic trend components. This orthogonalization collapses the Variance Inflation Factor for both $k_t$ and $\text{inter\_ortho}_t$ to exactly **1.00** across all 24 estimated models. 

Mathematically, FWL orthogonalization leaves the estimated interaction coefficient $\hat{\theta}_1$ and its standard error completely unchanged, while isolating the pure marginal interactive elasticity from the base capital elasticity $\hat{\theta}_0$.

**Estimation Engine and Non-Standard Fixed-$b$ Inference.** We estimate the cointegrating equations using Integrated Modified OLS (IM-OLS) developed by Vogelsang and Wagner (2014a, 2024). Unlike Fully Modified OLS (FM-OLS) or Dynamic OLS (D-OLS), IM-OLS eliminates second-order endogeneity and serial correlation biases without requiring lead/lag choices or bandwidth tuning parameters in the estimation step.

The IM-OLS estimator applies a partial sum transformation to the regression model:

$$S_t^y = \sum_{i=1}^t y_i, \quad S_t^X = \sum_{i=1}^t X_i, \quad S_t^D = \sum_{i=1}^t D_i$$

The partial-summed equation is augmented with the level regressors $x_t$:

$$S_t^y = S_t^D \boldsymbol{\delta} + S_t^X \boldsymbol{\beta} + x_t' \boldsymbol{\gamma} + S_t^u$$

Estimating this augmented partial-sum regression via OLS yields super-consistent estimates of the long-run parameters. 

For asymptotic inference, standard normal and chi-squared critical values are invalid because the limiting distribution of the IM-OLS estimator depends on functionals of Brownian motions. Standard asymptotic inference also ignores finite-sample distortions caused by long-run variance estimation. We adopt fixed-$b$ asymptotic theory (Kiefer & Vogelsang 2005; Vogelsang & Wagner 2014a), estimating the scalar long-run variance $\omega_{u \cdot v}$ using a Bartlett kernel and Newey-West automatic bandwidth selection.

**100,000 Monte Carlo Simulation Suite.** To obtain exact critical values for hypothesis testing and cointegration diagnostics, we execute a custom Monte Carlo simulation suite ($N = 100,000$ replications, sample size $T = 94$). The simulation generates independent random walks for regressors and sets $y_t = u_t$ under the true null hypothesis ($\theta_0 = 0$). This DGP preserves the cointegrated structure required to simulate the null distribution of the $CT_{\text{IM}}$ (VW Type 2) cointegration test, while ensuring that the simulated parameter $t$-statistics:

$$t^* = \frac{\hat{\theta} - 0}{\text{SE}(\hat{\theta})}$$

recover the exact non-standard asymptotic null distribution.

**Endogenous Structural Break Audit.** To guard against structural instability across the 1929–2024 window, we implement a two-pass endogenous structural break audit. In the first pass, we estimate the baseline model without breaks and extract the IM-OLS residuals. We apply the Bai-Perron sequential structural break test to the residual path to identify up to two optimal break dates. If level breaks are detected, we construct step level-shift dummies:

$$D_{T_b}^{\text{step}} = \mathbb{I}(t \ge T_b)$$

and re-estimate the full IM-OLS regression including $\mathbf{D}_t^{\text{step}}$ in the deterministics vector. Both no-break ($a$) and break-adjusted ($b$) variants are retained to evaluate whether structural breaks alter the cointegration space.
