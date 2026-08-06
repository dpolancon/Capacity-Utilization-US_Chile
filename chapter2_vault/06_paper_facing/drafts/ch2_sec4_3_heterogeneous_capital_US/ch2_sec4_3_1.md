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
role: Specification B econometric specification and estimation engine
stage: paper-assembly
tags:
  - chapter2/paper-facing
scope: chapter2
priority: core
---

# 4.3 Heterogeneous Capital, Mechanization Gap, and Overaccumulation (Specification B)

This section maps the theoretical model of heterogeneous capital accumulation and induced mechanization into an empirical econometric specification. We establish the formal crosswalk between the structural capacity transformation elasticity $\theta_t$ and a Cointegrating Multivariate Polynomial Regression (CMPR) framework estimated via Integrated Modified OLS (IM-OLS) on U.S. Non-Financial Corporate (NFC) data over 1929–2024 ($T = 94$ observations after lag conditioning).

## Spec B Econometric Specification and Cointegrating Equations

The baseline aggregate capital model assumes homogeneous capital stock. In historical reality, corporate fixed assets consist of distinct asset categories performing qualitatively different roles in production. Following the BEA Fixed Assets boundary protocols established in Chapter 2, we disaggregate core productive capital into non-residential structures ($K_t^{\text{NRC}}$) and machinery and equipment ($K_t^{\text{ME}}$).

Structures represent the physical footprint and plant infrastructure of production, while machinery embodies technological mechanization. The theoretical model establishes that potential real net value added growth $g_{Y^p}$ depends on the growth of structures $g_{K^{\text{NRC}}}$ and the expansion of the mechanization gap $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$:

$$g_{Y^p} = \theta_{\text{NRC}} g_{K^{\text{NRC}}} + \theta_{\kappa} g_{\kappa} \quad \text{and} \quad \frac{\partial Y^p}{\partial K^{\text{NRC}}} = \theta_{\text{NRC}}, \quad \frac{\partial Y^p}{\partial \kappa} = \theta_{\kappa}$$

where $\theta_{\text{NRC}}$ measures the capacity elasticity of plant structures and $\theta_{\kappa}$ measures the marginal capacity payoff of expanding the mechanization ratio. 

Following the Mechanization Productive Frontier (MPF) framework—combining Okishio's induced innovation threshold, Vidal's divided firm, and Marglin-style distributive grounding—the payoff to mechanization $\theta_{\kappa}$ is not a fixed technical constant. When firms face intense distributive conflict, rising labor costs compel capital to increase the organic composition of capital through mechanization. However, this induced innovation process depends on corporate liquidity and is constrained by financial overhead and relative asset prices:

$$\theta_{\kappa,t} = \theta_{\kappa} + \theta_{\omega\kappa} \text{inter}_{\omega\kappa, t-1} + \theta_{\kappa p} \text{inter}_{\kappa p, t-1}$$

where $\theta_{\kappa}$ is the autonomous mechanization elasticity, $\theta_{\omega\kappa}$ captures the marginal effect of effective wage pressure on technological yield, and $\theta_{\kappa p}$ measures the impact of relative machinery prices.

Regressing non-linear combinations, products, and non-stationary asset ratios of integrated processes introduces non-standard stochastic properties. As Wagner and Hong (2016) demonstrate, products of $I(1)$ series generate Cointegrating Polynomial Regressions (CPR) whose asymptotic distributions involve non-standard functionals of Brownian motions. Estimating a CPR with standard linear estimators yields invalid asymptotic inference and inflated test statistics unless specialized non-standard estimators and finite-sample critical values are employed.

We specify the empirical cointegrating equation for U.S. Non-Financial Corporate Real Gross Value Added ($y_t = \ln Y_t^{\text{NFC,GVA}}$) under Specification B as:

$$y_t = \alpha + \theta_{\text{NR}} k_t^{\text{NRC}} + \theta_{\kappa} \kappa_t + \theta_{\omega\kappa} \text{inter\_ortho}_{\omega\kappa, t} + \theta_{\kappa p} \text{inter\_ortho}_{\kappa p, t} + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$$

where $\alpha$ is the constant intercept, $k_t^{\text{NRC}}$ is log real non-residential structures, $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$ is the log mechanization gap, $\text{inter\_ortho}_{\omega\kappa, t}$ is the orthogonalized wage interaction term, $\text{inter\_ortho}_{\kappa p, t}$ is the orthogonalized relative price interaction, $\mathbf{D}_t$ is a vector of deterministic step level-shift dummies ($\boldsymbol{\gamma}' \mathbf{D}_t$), and $u_t$ is a stationary $I(0)$ error term under the cointegration null.

### Regressor Definitions and Data Provenance

We construct systematic permutations across wage share definitions, interaction structures, and structural break regimes to test the robustness of the heterogeneous capital model.

#### A. Disaggregated Capital Variables ($k_t^{\text{NRC}}$ and $\kappa_t$)
Data are sourced from the BEA Fixed Assets Accounts:
1. **Non-Residential Structures ($k_t^{\text{NRC}}$)**: $\ln K_t^{\text{NR}}$, representing nonresidential buildings, industrial plants, and utility structures.
2. **Mechanization Gap ($\kappa_t$)**: $k_t^{\text{ME}} - k_t^{\text{NRC}} = \ln(K_t^{\text{ME}} / K_t^{\text{NR}})$, measuring the log ratio of machinery and equipment capital to nonresidential structures.

Intellectual Property Products ($K^{\text{IPP}}$) and public transportation capital ($K^{\text{GT}}$) are excluded from core capital stock $K_{\text{cap}}$ and treated as frontier conditioners or overhead costs, adhering to the national accounting boundary rules locked in Chapter 2.

#### B. Nominal Wage Pressure Measures ($\omega_{t-1}$: GVA vs. NVA Basis)
We systematically evaluate 8 nominal wage pressure series, conditioned at lag 1 to match corporate investment planning horizons:
1. **Gross Value Added (GVA) Basis ($\omega_{\text{GVA}}$)**: Measures wage costs relative to nominal Gross Value Added ($\text{GVA} = CFC + v + s$). Includes baseline NFC compensation ($\text{COMP}/\text{GVA}$), Corporate sector compensation, and Shaikh-Tonak Tier 1 and Tier 2 GVA-adjusted shares.
2. **Net Value Added (NVA) Basis ($\omega_{\text{NVA}}$)**: Measures wage costs relative to nominal Net Value Added ($\text{NVA} = v + s$). Excludes Consumption of Fixed Capital ($CFC$), isolating true class struggle over newly created net value created on the shop floor. Includes baseline NFC compensation ($\text{COMP}/\text{NFC\_NVA}$), Corporate sector compensation, and Shaikh-Tonak Tier 1 and Tier 2 supervisory-adjusted shares ($v_{\text{prod}}/\text{NFC\_NVA}$).

#### C. Specification Sets (Standard vs. Effective Wage Pressure)
1. **Standard Wage Pressure (Specification Set 1)**: Interacts the mechanization gap directly with the wage share: $\kappa_t \cdot \omega_{t-1}$.
2. **Effective Wage Pressure (Specification Set 2)**: Interacts the mechanization gap with the financialization-adjusted effective wage share: $\kappa_t \cdot \omega_{t-1}(1 - \iota_{t-1})$, where $\iota_{t-1} = K_{t-1}^{\text{IPP}} / (K_{t-1}^{\text{cap}} + K_{t-1}^{\text{IPP}})$ measures the asset share of intellectual property and financialized overhead. The multiplier $(1 - \iota_{t-1})$ isolates the proportion of corporate accumulation retained in physical productive assets.

#### D. Relative Price Interaction ($\text{inter}_{\kappa p, t-1}$)
The price interaction is constructed as $\kappa_t \cdot (p_{t-1}^{\text{ME}} - p_{t-1}^{\text{NRC}})$, capturing relative asset price movements between machinery equipment and plant structures.

## 3. Frisch-Waugh-Lovell (FWL) Orthogonalization Protocol

Uncentered interaction terms between integrated series introduce severe multicollinearity. Raw interaction terms between $\kappa_t$, $k_t^{\text{NRC}}$, and $\omega_{t-1}$ exhibit pairwise correlation coefficients exceeding $r = 0.98$, generating Variance Inflation Factors (VIF) above 100. High VIFs inflate standard errors and mask structural relationships.

We enforce a strict Frisch-Waugh-Lovell (FWL) orthogonalization protocol. Before estimating the main cointegrating regression, we regress raw interaction terms on the base capital regressors ($k_t^{\text{NRC}}$ and $\kappa_t$), the constant intercept, and any active deterministic step dummies:

$$\text{inter\_raw}_t = a_0 + a_1 k_t^{\text{NRC}} + a_2 \kappa_t + \mathbf{a}_3' \mathbf{D}_t + \text{inter\_ortho}_t$$

We extract the OLS residual $\text{inter\_ortho}_t$ and insert it into the main regression. By construction, $\text{inter\_ortho}_t$ is strictly orthogonal to base capital regressors and deterministic components. This orthogonalization reduces the Variance Inflation Factor for base capital and interaction terms to near **1.00** across all models.

FWL orthogonalization leaves the estimated interaction coefficients ($\hat{\theta}_{\omega\kappa}, \hat{\theta}_{\kappa p}$) and their standard errors numerically identical to the uncentered model, while isolating the pure marginal interactive elasticity from the base capital elasticities.

## 4. Estimation Engine, FWL Detrending, and Non-Standard Fixed-$b$ Inference

We estimate Specification B using Integrated Modified OLS (IM-OLS) developed by Vogelsang and Wagner (2014a, 2024). IM-OLS eliminates second-order endogeneity and serial correlation biases without requiring lead/lag choices or bandwidth tuning parameters in the estimation step.

The IM-OLS estimator applies a partial sum transformation to the regression model:

$$S_t^y = \sum_{i=1}^t y_i, \quad S_t^X = \sum_{i=1}^t X_i, \quad S_t^D = \sum_{i=1}^t D_i$$

The partial-summed equation is augmented with level regressors $x_t$:

$$S_t^y = S_t^D \boldsymbol{\delta} + S_t^X \boldsymbol{\beta} + x_t' \boldsymbol{\gamma} + S_t^u$$

### Deterministic Space Detrending for Cointegration Null Tests

Applying cointegration tests to IM-OLS regressions requires careful handling of deterministic trends. In empirical macro data, stochastic regressors $x_t$ possess strong deterministic drift. If $x_t$ is not partialled out against the deterministic space (`deter` and step-shift accumulation paths `Sd`) prior to constructing the reverse cumulative sum matrix $Z_{2t}$ in Vogelsang-Wagner Type 2 tests, unspanned $t^4$ trends contaminate the test regression, blowing up the Wald statistic ($S_{\text{Type 2}}$) spuriously.

We implement FWL detrending within the IM-OLS estimator engine:

$$\mathbf{x}_{\text{det}} = \text{residuals of } \mathbf{x} \text{ regressed on } [\mathbf{D}_t, \mathbf{S}_{D,t}]$$

We construct reverse cumulative sum regressors from $\mathbf{x}_{\text{det}}$, eliminating deterministic trend contamination.

The corresponding construction detail for the residual cointegration diagnostics, which is a matter of implementation rather than of identification, is set out in Appendix D.

### 100,000 Monte Carlo Simulation Suite

Standard normal and chi-squared critical values are invalid for CPR regressions. We execute a custom Monte Carlo simulation suite ($N = 100,000$ replications, sample size $T = 94$) to generate exact finite-sample critical values under the null hypothesis of cointegration. The simulation generates independent random walks for regressors, partials out deterministic components under the exact empirical model structure, and derives exact critical thresholds for $t$-statistics and cointegration test statistics.
