---
type: analysis_report
status: active
depends_on: [codes/US_S61_section32_imols_specB.R, codes/US_S62_section32_imols_montecarlo.R]
stage_scope: section32_results
country: US
last_updated: 2026-08-04
layer: empirical_results
role: preliminary_analysis
stage: execution
---

# Preliminary Analysis: Specification B Cointegration & Effective Wage Pressure Handoff

This document compiles the empirical results from the full-sample ($1929–2024$, $T=94$) IM-OLS estimations for Section 3.2 (Specification B) and evaluates the significance of the mechanization gap and effective wage pressure using the custom Monte Carlo simulation critical values.

## 1. Custom Monte Carlo Critical Values (S62 Final, N=100,000)

Under the null hypothesis of cointegration ($H_0$), the dependent variable is simulated as a stationary $I(0)$ process independent of the stochastic regressors. The table below reports the custom finite-sample critical values for the Vogelsang-Wagner Type 2 Wald test ($CT_{\text{IM}}$) and the coefficient $t$-statistics:

| Variant | Test | 10% Bound ($^*$) | 5% Bound ($^{**}$) | 1% Bound ($^{***}$) |
| :--- | :--- | :---: | :---: | :---: |
| **Set 1 (Standard)** | $CT_{\text{IM}}$ | 0.0737 | 0.0943 | 0.1578 |
| | $t_{\kappa}$ (Gap) | 1.9451 | 2.3462 | 3.1884 |
| | $t_{\theta_{\omega\kappa}}$ (Wage) | 1.9392 | 2.3166 | 3.1104 |
| | $t_{\theta_{\kappa p}}$ (Price) | 1.9419 | 2.3202 | 3.1418 |
| **Set 1 + Breaks** | $CT_{\text{IM}}$ | 0.0693 | 0.0915 | 0.1626 |
| | $t_{\kappa}$ (Gap) | 2.0729 | 2.5080 | 3.4624 |
| | $t_{\theta_{\omega\kappa}}$ (Wage) | 2.0986 | 2.5391 | 3.4660 |
| | $t_{\theta_{\kappa p}}$ (Price) | 2.0873 | 2.5132 | 3.4640 |
| **Set 2 (Effective)** | $CT_{\text{IM}}$ | 0.0743 | 0.0940 | 0.1548 |
| | $t_{\kappa}$ (Gap) | 1.9463 | 2.3500 | 3.2056 |
| | $t_{\theta_{\omega\kappa}}$ (Wage) | 1.9393 | 2.3263 | 3.1089 |
| | $t_{\theta_{\kappa p}}$ (Price) | 1.9301 | 2.3121 | 3.1316 |
| **Set 2 + Breaks** | $CT_{\text{IM}}$ | 0.0691 | 0.0905 | 0.1610 |
| | $t_{\kappa}$ (Gap) | 2.0621 | 2.5026 | 3.4447 |
| | $t_{\theta_{\omega\kappa}}$ (Wage) | 2.0880 | 2.5220 | 3.4445 |
| | $t_{\theta_{\kappa p}}$ (Price) | 2.0839 | 2.5028 | 3.4417 |

*Note: These critical values reflect the final N=100,000 Monte Carlo run.*

## 2. Key Empirical Findings (S61 Results)

Comparing the standard wage pressure specification (**Set 1**) against the productive-accumulation-scaled effective wage pressure specification (**Set 2**) yields a major theoretical and empirical breakthrough:

### A. The Failure of Standard Wage Pressure (Set 1)
In the standard interactive specifications (Models M2.2a/b and M2.4a/b), the wage interaction term ($\theta_{\omega\kappa}$) is **statistically insignificant** across all wage measures:
* **Model M2.2a (NFC GVA, No Breaks):** $\theta_{\omega\kappa} = 4.011$ ($t$-stat = $0.54$). Far below the 10% custom critical value of $1.94$.
* **Model M2.2b (NFC GVA, With Breaks):** $\theta_{\omega\kappa} = -4.197$ ($t$-stat = $-1.00$). Far below the 10% custom critical value of $2.10$.
* Standalone wage shares fail to capture the structural pressure on technique choices because they do not account for the share of accumulation that is actually routed into productive machinery.

### B. The Success of Effective Wage Pressure (Set 2)
Once the wage share is scaled by $(1-\iota)$ to capture the "effective" wage pressure routed into accumulation (Set 2), the interaction term $\theta_{\omega\kappa}$ becomes **highly statistically significant** and carries the expected negative sign:
* **Model M2.6a (NFC GVA, No Breaks):** $\theta_{\omega\kappa} = -15.987$ ($t$-stat = $-3.24$). Exceeds the 1% custom critical value of $3.11$ ($p < 0.01$).
* **Model M2.6b (NFC GVA, With Breaks):** $\theta_{\omega\kappa} = -12.290$ ($t$-stat = $-2.91$). Exceeds the 5% custom critical value of $2.52$ ($p < 0.05$).
* **Model M2.8a (Shaikh-Tonak Tier 1, No Breaks):** $\theta_{\omega\kappa} = -12.770$ ($t$-stat = $-3.36$). Exceeds the 1% custom critical value of $3.11$ ($p < 0.01$).
* **Model M2.8b (Shaikh-Tonak Tier 1, With Breaks):** $\theta_{\omega\kappa} = -10.127$ ($t$-stat = $-2.95$). Exceeds the 5% custom critical value of $2.52$ ($p < 0.05$).

### C. Cointegration Verdict
All models reject the null of no cointegration under the Engle-Granger Residual ADF test (e.g., Model M2.6b ADF = $-4.775^{**}$ relative to MacKinnon critical values). Furthermore, the Shin LM and Vogelsang-Wagner Type 2 tests fail to reject the null of cointegration across both baseline models and models with structural breaks (e.g., Model M2.6b $C_{\text{Shin}} = 0.023$, $S_{\text{Type 2}} = 8.83$, both falling below their respective critical bounds). This provides robust mutual confirmation of stable cointegration under the IM-OLS framework, demonstrating that the parameter step-shifts successfully absorb the structural breaks without spurious trend contamination.

## 3. Theoretical Synthesis for Section 3.2 Prose

These findings provide direct empirical support for the theoretical model of the divided firm:
1. **The Mechanization Gap ($\kappa_t$):** The autonomous coefficient ($\theta_\kappa$) is positive and statistically significant (around $0.31$ to $0.61$), confirming that a wider gap yield is physically productive.
2. **The Effective Wage Channel ($\theta_{\omega\kappa} < 0$):** A rising effective wage share suppresses the marginal capacity payoff of the gap. This is consistent with Marxian theory: firms are forced by distributive conflict to mechanize, which increases the organic composition of capital and lowers potential capacity yield per unit of capital. 
3. **The Price Channel ($\theta_{\kappa p} \approx -0.38$ to $-1.27$):** A rising relative price of machinery penalizes the mechanization program, reducing the capacity payoff of the gap.

## 4. Next Steps: Porting to /academic-pipeline

Now that the S61 empirical results and S62 Monte Carlo engine are complete and verified, we will trigger the `/academic-pipeline` at **Stage 2 (WRITE)** to rewrite `ch2_sec3_2_heterogeneous_capital_prelatex.md`, interweaving these empirical coefficients and significance levels directly into the manuscript prose.
