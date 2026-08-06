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

# Preliminary Analysis: Specification B (Effective Wage Pressure & Mechanization Gap)

This document synthesizes the initial output from the S61 empirical estimation and S62 Monte Carlo simulations for Section 3.2.

## 1. Monte Carlo Triple-$I(1)$ Bounds (S62)

The simulations demonstrate that double and triple interaction terms involving polynomial random walks profoundly alter the asymptotic distribution of the IM-OLS wald statistics. For the B3e and B4e specifications, compounding the effective wage pressure ($C_t = \omega_{t-1} \cdot (1-\iota_{t-1})$) with the mechanization gap ($\kappa_t$) requires distinct significance thresholds:

*   **B3e (Canonical with Effective Wage):** Critical $t$-values for the triple interaction explode asymptotically (e.g., $95\%$ critical value around 2351 for $N=100$), confirming that standard normal inference is invalid and fixed-$b$ bounds are strictly required.
*   **B4e (No Standalone $\kappa$):** Similar expansion in the asymptotic distribution, reinforcing the structural necessity of the simulation engine.

*Note: Final paper-facing bounds should be re-run at $N=100,000$ to ensure smooth asymptotic convergence.*

## 2. Empirical Estimation (S61)

The implementation successfully estimated the `B1`, `B3`, `B3e`, `B4`, and `B4e` taxonomies. 
Crucially, during execution, we identified that the `GOV_TRANS` (Government/Transfer) capital stock possessed near-zero variation against the NIPA data baseline. Consequently, $k^{GT}$ acted as a perfect collinear vector to the deterministic constant, crashing the cointegration kernel. Following the theoretical protocol to "demote its conditioning for future research", it was removed from the active auxiliary FWL space.

The resulting parameter ledger has been generated and compiled into LaTeX tables at:
`reports/US_Section32_IMOLS_Results/us_section32_imols_results.pdf`

### Next Steps for the Pipeline
1. Run the `us_section32_imols_results.pdf` through peer-review.
2. Formally interweave the coefficient values into the `ch2_sec3_2_heterogeneous_capital_prelatex.md` draft.

**To continue drafting, trigger the complete paper workflow using the /academic-pipeline.**
