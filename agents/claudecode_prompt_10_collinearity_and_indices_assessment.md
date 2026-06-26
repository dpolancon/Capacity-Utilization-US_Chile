# Claude Code Prompt 10: Econometric Collinearity and Log-Indices Audit (Chile)
## Summoning Academic Research Skills for Level-Collinearity and Index Transformations
## Spec Gates: Pre-1973 vs. Post-1974 Sample Splits | Vault Alignment: 02_analytical_foundation

---

## 1. Objective and Task Definition

You are instructed to summon your **academic research skills** to conduct a formal econometric assessment of the collinearity problem between non-residential structures ($K_t^{NR}$) and machinery/equipment ($K_t^{ME}$) capital stocks in the Chilean capacity frontier model.

Specifically, you must:
1. **Purge the Vault Context:** Prior to conducting any econometric analysis, you must read all markdown notes in the directory:
   `C:\ReposGitHub\Capacity-Utilization-US_Chile\chapter2_vault\02_analyitical_foundation`
   Ensure your assessment is theoretically aligned with the peripheral realization constraints and mechanization bias specifications defined in A03, A04, and A05.
2. **Evaluate Log-Levels vs. Log-Indices:** Analyze whether transforming the capital series from log-levels to log-indices (e.g., base year 1980 = 100) or cumulative growth indices resolves near-multicollinearity, and derive the mathematical implications for the cointegrating vector.
3. **Enforce Historical Sample Splits:** Model the parameter stability by partitioning the sample into pre-1973 (historical developmental/ISI era) and 1974-onwards (coup and neoliberal era), allowing for nested sub-windows for crisis periods.

* **Target Output File:** `output/stage_a/Chile/docs/CL_S90_collinearity_and_indices_assessment.md`

---

## 2. Vault Alignment Requirements

Your assessment must explicitly reference and build upon these analytical foundation notes:
* **[A03_TransformationElasticity_Two-CapitalComposition](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/02_analyitical_foundation/A03_TransformationElasticity_Two-CapitalCapacityComposition.md):** Decomposing aggregate capital elasticity into structures and machinery.
* **[A04_PeripheralTransformationElasticity](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/02_analyitical_foundation/A04_PeripheralTransformationElasticity.md):** The balance of payments constraint and realization margins.
* **[A05_NRCEnvelope_MechanizationBias](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/02_analyitical_foundation/A05_NRCEnvelope_MechanizationBias.md):** The role of composition as a bias-mediator.

---

## 3. Econometric Core Questions to Answer

### A. The Mathematics of the Log-Index Transformation
Determine if shifting from log-levels ($\ln K_t$) to log-indices ($\ln I_t$, where $I_t = K_t / K_{t_0}$) alters the collinearity properties:
* Let $k_t^{NR} = \ln K_t^{NR}$ and $k_t^{ME} = \ln K_t^{ME}$ be the log-level series.
* Let $i_t^{NR} = \ln(K_t^{NR}/K_{t_0}^{NR}) = k_t^{NR} - k_{t_0}^{NR}$ and $i_t^{ME} = k_t^{ME} - k_{t_0}^{ME}$ be the log-index series.
* **Proof/Derivation:** Show that since $i_t$ is a linear translation of $k_t$ (shifted by the constant vector $k_{t_0}$), the regressor covariance matrix $\text{Var}(i_t)$ is identical to $\text{Var}(k_t)$. Thus, prove that re-indexing to a base year does **not** change eigenvalues, correlation coefficients, or the Variance Inflation Factors (VIFs).
* **Alternative Indexing:** Assess if constructing cumulative growth indices or chain-weighted growth indexes (e.g., cumulating growth rates after differencing) alters the integration properties or collinearity profiles.

### B. Sample-Splitting and Parameter Constancy Gates (1973 Boundary)
Diego's structural thesis argues that the transformation elasticity is structurally unstable across the 1973 institutional boundary due to the military coup and the subsequent transition from import-substitution industrialization (ISI) to neoliberal open-economy accumulation.
* **Verification:** Detail how you will estimate separate cointegrating vectors for the pre-1973 (developmental) sample and the post-1974 (neoliberal) sample.
* **Nested Windows:** Establish a protocol for validating parameter constancy using rolling nested sub-windows (e.g., 1940-1970 vs 1940-1973, and 1974-1987 vs 1974-2003) to ensure that the estimated parameters are stable within institutional regimes.

---

## 4. Writing & Execution Instructions (WLM v4.0 Voice)

* **Direct Verdict:** Do not hedge about whether log-indices work. State the mathematical equivalence clearly, and then discuss if any alternative transformations (such as composition-difference $c_t$) are required to solve the collinearity.
* **Vault Citations:** Wire your arguments directly to the analytical equations in the vault folder `02_analytical_foundation` using standard wiki links.
* **Checklist for Completion:**
  1. Executive Summary of Collinearity and Indexing.
  2. Mathematical Proof of Log-Level vs. Log-Index Covariance.
  3. Pre-1973 / Post-1974 Split-Estimation Protocol.
  4. Rolling/Nested Constancy Diagnostics Plan.
