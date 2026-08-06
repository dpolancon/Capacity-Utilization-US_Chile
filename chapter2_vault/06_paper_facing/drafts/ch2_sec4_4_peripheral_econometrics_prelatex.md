---
type: paper_facing
status: draft
country: US_CL
stage_scope: S04_Empirical_Handoff
last_updated: 2026-08-05
depends_on:
  - 06_paper_facing/drafts/ch2_sec3_3_peripheral_extension_prelatex.md
  - 06_paper_facing/drafts/ch2_sec4_4_empirical_strategy.md
layer: drafting
scope: section 4.4
---

# 4.4 Econometric Operationalization of the Peripheral Realization Trap (Specification C - Chile T-CMPR)

To bridge the gap between our analytical model of the peripheral realization trap (Section 3.3) and the empirical data, we operationalize the non-linear macroeconomic constraint within our cointegrating regression framework. 

While the exact external capacity ceiling ($\bar{\kappa}_t$) is unobservable, the presence of the constraint manifests as a regime shift. When the external constraint binds, the structural logic of the economy transitions from a dynamic Okishio wage-dividend regime (Regime A) into a stagnant realization trap where surplus is blocked (Regime B). 

To model this, we deploy a **Threshold Cointegrating Multivariate Polynomial Regression (T-CMPR)**. Relying on the robust threshold estimation theory for integrated regressors developed by Chen (2015), we map the non-linear Balance of Payments (BoP) constraint into a state-dependent dummy variable, allowing us to preserve the linear interactive architecture and FWL orthogonalization utilized in Sections 4.2 and 4.3.

## The Prebischian Capacity to Import Threshold

To identify periods of external strangulation, we require an observable threshold variable ($q_t$) that captures the intensity of the macroeconomic realization pressure. Following the logic established in Section 3.3, this pressure is driven by the purchasing power of primary exports. 

We draw upon World Bank Balance of Payments (WBOP) data to construct the **Prebischian Capacity to Import ($C_t$)**:

$$ C_t = X_t \cdot ToT_t $$

where $X_t$ represents real export volumes and $ToT_t$ represents the Terms of Trade. This index acts as our empirical proxy for the foreign exchange envelope. By using $C_t$ as the threshold variable $q_t$, we strictly isolate the external supply-side constraint from domestic demand variables.

## Profile Least Squares Detection and Linear State Conversion

We allow the data to identify the exact pressure threshold where the realization trap activates. Following Chen (2015), we employ a Profile Least Squares (Profile LS) grid-search algorithm over the empirical distribution of $C_t$. For each candidate threshold $\gamma$, we construct a temporary state-dependent dummy variable $D^{ext}_t(\gamma) = \mathbb{I}(C_t \le \gamma)$ and estimate the interactive IM-OLS regression to isolate the optimal threshold $\hat{\gamma}$ minimizing the sum of squared residuals:

$$ \hat{\gamma} = \arg \min_{\gamma} \text{SSR}(\gamma) $$

Once $\hat{\gamma}$ is isolated, the binding state dummy $D^{ext}_t = \mathbb{I}(C_t \le \hat{\gamma})$ is fixed, collapsing the non-linear regime shift into a linear dummy interaction.

## The Linear Interactive T-CMPR Specification and Empirical Results

With the external constraint mapped to $D^{ext}_t$, we expand the Heterogeneous Capital specification (Section 4.3) to test the peripheral realization trap directly. The structural capacity equation becomes:

$$ Y^p_t = \beta_0 k^{\text{NRC}}_t + \beta_1 \kappa_t + \beta_2 (\omega_{t-1} \kappa_t) + \delta_1 (\kappa_t \cdot D^{ext}_t) + \delta_2 (\omega_{t-1} \kappa_t \cdot D^{ext}_t) + u_t $$

The table below presents the T-CMPR IM-OLS estimation results for Chile (1920–2024) across five specifications: a linear baseline, a continuously mediated variant, the two threshold states taken separately, and the full threshold specification. The Vogelsang--Wagner Type 2 statistic appears directly beneath the parameter estimates; residual ADF and Shin LM diagnostics, collinearity statistics, and the threshold grid are collected in Appendix D.

<!-- TABLE: reports/Chile_Section33_Peripheral_IMOLS_Results/table_chile_threshold_imols_CORE.tex -->

The empirical results bear on both theoretical predictions:
1. **Unconstrained Okishio Mechanism ($\theta_{\omega\kappa} > 0$):** In Regime $E_A$ ($D^{ext}_t = 0$), the wage pressure interaction is positive and statistically significant ($\hat{\theta}_{\omega\kappa} = 5.12^{**}$ in M3.3a). Wage increases compel capitalists to mechanize to restore profitability.
2. **Peripheral Realization Penalty ($\delta_{\omega\kappa} < 0$):** In Regime $E_B$ ($D^{ext}_t = 1$), when foreign exchange capacity collapses, the realization penalty activates ($\hat{\delta}_{\omega\kappa} = -15.99^{*}$ in M3.3b, $-16.24^{*}$ in the full specification M3.4a). The net interaction elasticity turns sharply negative. Under extreme external balance stress, nominal wage increases fail to induce productive capacity growth, which is the peripheral realization trap set out in Section 3.3.

\PLACEHOLDER{Three unresolved discrepancies in this section. First, the realization penalty is significant at the 10\% level in the estimation output ($-15.99$, standard error $4.94$, one star), not at the 1\% level as earlier drafts of this section stated; the $t$ ratio of $-3.24$ is consistent with the reported standard error, so it is the significance level and not the point estimate that was overstated. Second, the threshold variable is defined as the Prebischian capacity to import $M^{\text{cap}}_t = X_t \cdot ToT_t$ in the specification text but as $M^{\text{cap}}_t = X_t$ in the estimation output's own note; the terms-of-trade factor is dropped in one of the two and it is not established which reflects what was estimated. Third, this penalty coincides exactly, coefficient and standard error, with the U.S. Specification B wage interaction for M2.17a reported in \S4.3. All three require returning to the estimation, not the prose.}

**Modification of the Fixed-$b$ Simulation Protocol.** Standard non-standard asymptotic bounds are invalid because the grid-search process consumes recursive degrees of freedom. To recover exact finite-sample fixed-$b$ bounds, the 100,000-pass Monte Carlo simulator replicates the Chen (2015) Profile LS grid-search across $C_t$ inside the loop, ensuring that statistical inference on $\hat{\delta}_2$ is robust to threshold data-mining.

\PLACEHOLDER{\textbf{The Chilean case is developed to roughly a tenth the length of the two United States sections, and that asymmetry is itself a problem.} Sections 4.2 and 4.3 each carry a full arc: specification, estimation, capacity reconstruction, the $\hat{\mu}_t$ path, institutional periodization, and a reading of contradictory tendencies. This section stops at the estimation table. The locked outline forbids reading the periphery as a deviation from a central norm, but a chapter that gives one case six subsections and the other one will be read that way whatever its prose says --- structure carries the comparison as much as argument does. Outstanding: the Chilean capacity reconstruction under the threshold specification; the reconstructed $\hat{\mu}_t$ path with its level anchor; a periodization matched in grain to the Fordist/post-Fordist treatment of the United States, organized around Chile's own institutional sequence rather than mapped onto the United States timeline; and the corresponding figures.}
