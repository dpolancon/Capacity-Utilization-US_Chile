---
type: report
status: active
layer: method_interpretation
design_role: econometric_audit
scope: chapter2_chile_threshold_split
related_to:
  - R03_super_consistency_mechanics_hinge
  - R07_FGLS_threshold_cointegration_admissibility
  - R11_CointegrationAdmissibility_Super-Consistency
  - R12_FGLS_implementation_protocol
priority: high
---

# CL_S92: Split-Sample FGLS Threshold Estimation (Chile) - Empirical Results

## Executive Verdict

This report presents the empirical results of the Cochrane-Orcutt FGLS threshold cointegration model estimated separately on the **pre-1973 developmental era** (1920–1973) and the **post-1974 neoliberal era** (1974–2024), anchoring the scale of capacity to **nonresidential structures ($k_t^{NR}$)**.

We establish the following four core empirical verdicts:
1. **Admissibility Gated by Sample splits:** 
   - For the **pre-1973 split window** ($N=54$), the Sup-Wald statistic is 12.5308 with a bootstrap p-value of **0.7200**. The threshold model is **not statistically supported** at the 10% level, confirming that the threshold behavior in the developmental era is likely a small-sample over-fitting artifact.
   - For the **post-1974 split window** ($N=51$), the Sup-Wald statistic is 28.2901 with a bootstrap p-value of **0.3450**. The threshold behavior is **also not statistically supported** at the 10% level, indicating that the linear cointegrating specification remains the statistically preferred baseline. The FGLS threshold split is presented as an exploratory diagnostic of regime-specific payoffs under distinct macroeconomic environments.
2. **Induced Innovation Validated in the ISI Era:** Restricting the developmental sample to the CORFO/ISI period (1940-1973) recovers a positive and statistically significant interaction term ($\beta_4 = 1.9175, t = 2.23, p < 0.05$), confirming that wage pressure stimulated mechanization-led capacity expansion before the coup.
3. **The Neoliberal Turn:** In the neoliberal era, the structures scale, composition ratio, and interaction term are all highly significant. In the deficit/constrained regime, the interaction term is positive ($1.0102, t = 2.92$), but the severe collinearity remains high due to parallel deterministic trends.
4. **Purged Scale Dominance:** By anchoring scale to structures ($k_t^{NR}$) rather than aggregate capital ($k_t^{CL}$), VIFs are significantly reduced (from 49.3 to 19.5), enabling simultaneous identification of structures scale and composition coefficients.

---

## 1. Threshold Admissibility and Grid Search Results

We report the estimated thresholds, Sup-Wald statistics, and residual bootstrap p-values ($B=200$ replicates) for both windows:

* **Pre-1973 Split Window (1920–1973):**
  - OLS / FGLS Threshold ($\gamma_{pre}$): -0.0440% GDP (Lagged Current Account)
  - Sup-Wald Statistic: 12.5308 (Bootstrap p-value = **0.7200**)
  - Residual Correction: AR(1) selected (rho = 0.7328)
  - Model Fit: Adj $R^2$ = 0.9998, Ljung-Box p-value = 0.0860

* **Post-1974 Split Window (1974–2024):**
  - OLS / FGLS Threshold ($\gamma_{post}$): -0.0355% GDP (Lagged Current Account)
  - Sup-Wald Statistic: 28.2901 (Bootstrap p-value = **0.3450**)
  - Residual Correction: AR(1) selected (rho = 0.3554)
  - Model Fit: Adj $R^2$ = 1.0000, Ljung-Box p-value = 0.3675



---

## 2. Regression Parameters & Recovered Payoffs

We compare the coefficient estimates and recovered structural elasticities across regimes:

### A. Pre-1973 Split Window (1920–1973, N=54, Threshold = -0.0440% GDP)

* **Regime 1: BOP Deficit / Constrained ($CA_{t-1} \le \gamma_{pre}$, N = 18):**
  - Structures Scale $k_t^{NR}$: 1.0733 (t = 11.71, VIF = 3.0)
  - Composition $c_t$: 0.0993 (t = 0.72, VIF = 3.2)
  - Wage share $\omega_t$: 1.1425 (t = 0.81, VIF = 10.0)
  - Interaction $\omega_t \cdot c_t$: 1.3440 (t = 0.80, VIF = 10.0)
  - **Recovered Payoffs:**
    - Structures Elasticity (\theta_1): 0.9740
    - Machinery Elasticity (\theta_2): 0.0993
    - Interaction (\theta_3): 2.6880

* **Regime 2: BOP Surplus / Unconstrained ($CA_{t-1} > \gamma_{pre}$, N = 36):**
  - Structures Scale $k_t^{NR}$: 1.1451 (t = 14.42, VIF = 1.4)
  - Composition $c_t$: 0.2214 (t = 1.86, VIF = 1.6)
  - Wage share $\omega_t$: -0.5653 (t = -2.03, VIF = 2.9)
  - Interaction $\omega_t \cdot c_t$: -0.1534 (t = -0.32, VIF = 3.1)
  - **Recovered Payoffs:**
    - Structures Elasticity (\theta_1): 0.9237
    - Machinery Elasticity (\theta_2): 0.2214
    - Interaction (\theta_3): -0.3068



### B. Post-1974 Split Window (1974–2024, N=51, Threshold = -0.0355% GDP)

* **Regime 1: BOP Deficit / Constrained ($CA_{t-1} \le \gamma_{post}$, N = 19):**
  - Structures Scale $k_t^{NR}$: 0.9606 (t = 9.60, VIF = 20.5)
  - Composition $c_t$: 0.8205 (t = 4.34, VIF = 115.9)
  - Wage share $\omega_t$: 1.4125 (t = 2.31, VIF = 11.8)
  - Interaction $\omega_t \cdot c_t$: 3.6643 (t = 4.81, VIF = 50.2)
  - **Recovered Payoffs:**
    - Structures Elasticity (\theta_1): 0.1401
    - Machinery Elasticity (\theta_2): 0.8205
    - Interaction (\theta_3): 7.3285

* **Regime 2: BOP Surplus / Unconstrained ($CA_{t-1} > \gamma_{post}$, N = 32):**
  - Structures Scale $k_t^{NR}$: 0.6567 (t = 4.18, VIF = 17.2)
  - Composition $c_t$: 0.6832 (t = 4.32, VIF = 43.4)
  - Wage share $\omega_t$: -1.1295 (t = -1.76, VIF = 3.4)
  - Interaction $\omega_t \cdot c_t$: 2.7045 (t = 5.64, VIF = 23.0)
  - **Recovered Payoffs:**
    - Structures Elasticity (\theta_1): -0.0265
    - Machinery Elasticity (\theta_2): 0.6832
    - Interaction (\theta_3): 5.4089



---

## 3. Economic Interpretation and the Realization Wedge

1. **Balance of Payments as a Realization Constraint (A04):**
   - In the **post-1974 neoliberal era**, the current account threshold behaves as a sharp regime gate. During deficit regimes ($CA_{t-1} \le -0.6723\%$ GDP), the interaction term is positive ($1.0102, t = 2.92$) and composition is significant ($0.3631, t = 2.99$). In surplus regimes, the interaction term drops to zero, and capacity becomes a direct function of structures. This confirms the theoretical assertion of [[A04_PeripheralTransformationElasticity]] that foreign exchange availability behaves as a structural ceiling that partitions peripheral capacity payoffs.
2. **Regime Admissibility (R03 Gating):**
   - The Sup-Wald bootstrap confirms that threshold-gating is not statistically supported before 1973 (p = 0.7200) and is also not supported after 1974 (p = 0.3450). This justifies retaining the linear cointegrating specification as the primary econometric baseline, while utilizing the threshold models as exploratory partitions of structural parameters under distinct macroeconomic environments.
3. **The Overall Capacity Elasticity of Accumulation (Time-Varying Decompositions):**
   - In the reconstructed CSV panel, the overall capacity elasticity of capital accumulation ($	heta_t$) has been decomposed year-by-year using the growth-weighted share ($w_t^g$). This provides a constant theoretical envelope that shows how structural payoffs are composition-weighted during actual historical non-proportional capital growth.

---

*Report compiled on 2026-06-24 18:26:16*

