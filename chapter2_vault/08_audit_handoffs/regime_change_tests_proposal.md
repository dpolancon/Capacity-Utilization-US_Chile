---
type: paper_facing
status: proposal
country: CL
stage_scope: S04_Empirical_Handoff
last_updated: 2026-08-05
depends_on:
  - 06_paper_facing/drafts/ch2_sec3_3_peripheral_extension_prelatex.md
  - 06_paper_facing/drafts/ch2_sec4_4_peripheral_econometrics_prelatex.md
layer: design
scope: section 4.4
---

# Proposal: Operationalizing Regime Change & BoP Constraint Testing in CMPR IM-OLS (Chile Track)

This audit handoff presents a unified proposal for testing the hypothesis of a peripheral regime change—driven by a binding Balance of Payments (BoP) constraint—against an unconstrained baseline model. All notation strictly adheres to the Master Notation Lock (`AGENTS.md`) and incorporates the specific empirical boundaries of the Chilean historical dataset.

---

## 1. Chilean Empirical Data Boundaries & Price Wedges

Before specifying the estimation equations, we enforce three crucial data boundaries specific to the Chilean long-run panel ($1920$--$2024$):

1. **Macroeconomic Aggregate Boundary (Gross Domestic Product):**
   Unlike the U.S. track (which uses sector-level Non-Financial Corporate value added $y_t^{\text{NFC}}$), **Chile lacks sector-level NFC accounts prior to 1990**. Therefore, all Chilean models are estimated directly on **total real Gross Domestic Product ($y_t = \ln Y_t$)**.
2. **Relative Price Variable ($p_t^{\kappa}$) Price Splicing & RER Alternatives:**
   Chile lacks domestic price indices for machinery and structure capital stocks before 1940. To construct the relative price ratio $p_t^{\kappa} = \ln P^{\text{ME}}_t - \ln P^{\text{NRC}}_t$:
   - **Internal Price Anchor:** We extract the internal capital deflator $P^{\text{internal}}_t$ (which anchors plant structures and civil works) from ClioLab/BCCh deflators staged under the `K-Stock-Harmonization` data provenance.
   - **Imported Price Wedge:** We proxy the imported machinery price index using the US wholesale capital price index from `data/raw/Chile/W04_Precios_ClioLabPUC.xlsx` adjusted by the nominal exchange rate.
   - **Real Exchange Rate ($RER_t$) Alternative:** Alternatively, the annual Real Exchange Rate ($RER_t$) acts as a direct proxy for $p_t^{\kappa}$. The $RER_t$ mathematically captures the relative price wedge of imported capital goods (machinery) against domestic non-tradables (structures/construction deflator), providing an elegant, highly observable alternative.
3. **Threshold Variable Notation Lock ($M^{\text{cap}}_t$):**
   To avoid notation collision with the mechanization growth rate ($q = \Delta \ln(K^{\text{ME}}/L)$), the threshold variable is **never labeled $q_t$**. It is strictly designated as the **Prebischian Capacity to Import ($M^{\text{cap}}_t = X_t \cdot ToT_t$)**, where $X_t$ is real export volume and $ToT_t$ is the Terms of Trade from the WBOP dataset.

---

## 2. Nested Specification Hierarchy for Chile

We formulate three nested empirical specifications within the Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS framework:

### Model 0: Baseline Unconstrained Model (No Regime Shift)
The baseline specification assumes that foreign exchange availability never binds ($\phi_t = 1 \implies \pi^{\text{eff}}_t = \pi_t$). The long-run Chilean GDP capacity equation is given by:
$$ y_t = \alpha + \theta_{\text{NRC}} k^{\text{NRC}}_t + \theta_{\kappa} \kappa_t + \theta_{\omega \kappa} (\omega_{t-1} \kappa_t) + \beta_{p^{\kappa}} p^{\kappa}_t + u_t $$
where:
- $y_t = \ln Y_t$ is real aggregate Chilean GDP.
- $\theta_{\text{NRC}}$ is the base elasticity of non-residential structures.
- $\theta_{\kappa}$ is the autonomous mechanization gap elasticity ($\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$).
- $\theta_{\omega \kappa}$ measures the unconstrained wage-induced Okishio mechanization dividend.
- $\beta_{p^{\kappa}}$ is the coefficient on the imported relative price ratio $p_t^{\kappa}$ (or the $RER_t$ proxy).

### Model 1: Continuous Mediated Model (Linear Interaction)
Model 1 continuously scales the wage-mechanization dividend by the log Prebischian Capacity to Import ($\ln M^{\text{cap}}_t$):
$$ y_t = \alpha + \theta_{\text{NRC}} k^{\text{NRC}}_t + \theta_{\kappa} \kappa_t + \theta_{\omega \kappa} (\omega_{t-1} \kappa_t) + \theta_{\text{periph}} (\omega_{t-1} \kappa_t \cdot \ln M^{\text{cap}}_t) + \beta_{p^{\kappa}} p^{\kappa}_t + u_t $$
Here, $\theta_{\text{periph}} > 0$ tests whether higher export purchasing power amplifies the intensive-margin mechanization dividend by relaxing foreign exchange rationing.

### Model 2: Threshold Cointegrating Model (Regime-Switching T-CMPR)
Model 2 embeds the sharp non-linear corner solution derived in Section 3.3. Define the external binding state dummy using the threshold parameter $\gamma$:
$$ D^{\text{ext}}_t(\gamma) = \mathbb{I}(M^{\text{cap}}_t \le \gamma) $$
The structural specification splits into two distinct regimes:
$$ y_t = \alpha + \theta_{\text{NRC}} k^{\text{NRC}}_t + \theta_{\kappa} \kappa_t + \theta_{\omega \kappa} (\omega_{t-1} \kappa_t) + \delta_{\kappa} (\kappa_t \cdot D^{\text{ext}}_t) + \delta_{\omega \kappa} (\omega_{t-1} \kappa_t \cdot D^{\text{ext}}_t) + \beta_{p^{\kappa}} p^{\kappa}_t + u_t $$
- **Regime $E_A$ (Slack BoP, $D^{\text{ext}}_t = 0$):** Intensive-margin elasticity is $\theta_{\text{ME, core}} = \theta_{\kappa} + \theta_{\omega \kappa} \omega_{t-1}$.
- **Regime $E_B$ (Binding Trap, $D^{\text{ext}}_t = 1$):** Intensive-margin elasticity collapses to $\theta_{\text{ME, periph}} = (\theta_{\kappa} + \delta_{\kappa}) + (\theta_{\omega \kappa} + \delta_{\omega \kappa}) \omega_{t-1}$.
- **Core Hypothesis Test:** $H_0: \delta_{\kappa} = 0 \text{ and } \delta_{\omega \kappa} = 0$ (No Regime Change) vs. $H_1: \delta_{\omega \kappa} < 0$ (Peripheral Realization Penalty).

---

## 3. Hypothesis Testing Engine for Regime Change

Testing $H_0$ within the IM-OLS framework under integrated regressors and endogenous threshold selection requires non-standard inference:

### Test 1: Profile LS Generalized Sup-Wald Test (Chen 2015)
To test $H_0: \boldsymbol{\delta} = \mathbf{0}$ against $H_1: \boldsymbol{\delta} \ne \mathbf{0}$ with unknown threshold $\gamma \in \Gamma$:
1. Compute the Profile LS grid search over $\gamma \in \Gamma = [\underline{\gamma}, \overline{\gamma}]$ using IM-OLS partial-summed regressions:
   $$ \hat{\gamma}_{M^{\text{cap}}} = \arg \min_{\gamma \in \Gamma} \text{SSR}_n(\gamma) $$
2. Construct the Generalized Sup-Wald statistic:
   $$ \widetilde{T}_n = \sup_{\gamma \in \Gamma} W_n(\gamma) = \sup_{\gamma \in \Gamma} \left[ \hat{\boldsymbol{\delta}}(\gamma)' \left( \text{Var}(\hat{\boldsymbol{\delta}}(\gamma)) \right)^{-1} \hat{\boldsymbol{\delta}}(\gamma) \right] $$
3. **Fixed-$b$ Monte Carlo Bootstrap:** Critical values are extracted from a 100,000-pass simulation using the `cpr-im-ols` engine. The simulator generates null $I(1)$ series and executes the exact same Profile LS grid search over simulated $M^{\text{cap} *}_t$ on every iteration, guaranteeing exact finite-sample size control.

---

## 4. Robustness Protocols: Rolling Windows and Cointegration Parameter Stability

Rather than assessing out-of-sample forecast validation (which is rejected for long-run structural estimation), robustness checks are designed to audit the stability of the aggregate elasticity $\theta$ and the cointegrating vector parameters:

### Protocol A: 30-Year Rolling-Window IM-OLS Parameter Stability
1. Estimate Model 0 over a 30-year rolling window ($W = 30$).
2. Plot the trajectory of $\hat{\theta}_{\omega \kappa}^{(t)}$ with 95% fixed-$b$ confidence intervals.
3. **Structural Prediction:** During major foreign exchange crises (e.g., the 1930s Great Depression, 1973, 1982 debt crisis), $\hat{\theta}_{\omega \kappa}^{(t)}$ should plummet toward zero or become negative, reflecting the onset of the realization trap ($\phi_t < 1$).

### Protocol B: Cointegration Parameter Stability Audits
To formally audit the constancy of the cointegrating vector $\theta$ against standard parameter drift:
1. **Hansen's (1992) $L_c$ Parameter Stability Test:** Run the $L_c$ test on the IM-OLS residuals. Under the null hypothesis, the cointegrating parameters are constant over the sample; the alternative is that the parameters follow a martingale process (random walk parameter drift).
2. **CUSUM of Residuals and CUSUM of Squares (Vogelsang & Wagner 2014):** Compute the CUSUM and CUSUM of Squares statistics directly on the IM-OLS partial-summed residuals $\hat{u}^+_t$. Rejections of the null bounds confirm the structural locations of the regime shifts, matching them historically with the WBOP Capacity to Import collapses.
3. **Recursive IM-OLS Estimations:** Plot recursive estimates of the structures elasticity ($\hat{\theta}_{\text{NRC}}$) and the mechanization gap elasticity ($\hat{\theta}_{\kappa}$) as the sample window expands from $1920+t$ to $2024$, verifying whether the parameters stabilize once the threshold dummy $D^{\text{ext}}_t$ is included in the design matrix.

---

## Summary Matrix of Chilean Specifications

| Spec ID | Model Class | Dependent Var | Key Interaction Regressors | Threshold Variable | Primary Hypothesis |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **M3.1a** | Baseline CMPR | $y_t = \ln Y_t$ | $\omega_{t-1} \kappa_t, p_t^{\kappa}$ | None | Unconstrained Okishio dividend ($\theta_{\omega \kappa} > 0$). |
| **M3.2a** | Mediated CMPR | $y_t = \ln Y_t$ | $\omega_{t-1} \kappa_t \cdot \ln M^{\text{cap}}_t$ | Continuous $M^{\text{cap}}_t$ | FX capacity relaxes import bottleneck ($\theta_{\text{periph}} > 0$). |
| **M3.3a/b** | Threshold CMPR | $y_t = \ln Y_t$ | $\omega_{t-1} \kappa_t \cdot D^{\text{ext}}_t$ | $M^{\text{cap}}_t \le \hat{\gamma}_{M^{\text{cap}}}$ | BoP constraint blocks surplus ($\delta_{\omega \kappa} < 0$). |

*Vault artifact logged under `chapter2_vault/08_audit_handoffs/regime_change_tests_proposal.md`.*
