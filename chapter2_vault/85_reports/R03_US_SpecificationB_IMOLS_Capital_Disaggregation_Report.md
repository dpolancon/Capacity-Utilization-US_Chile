---
type: research_note
status: active
depends_on:
  - chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
  - chapter2_vault/02_analyitical_foundation/A06_RelativePrice_Mechanization_Theory.md
  - chapter2_vault/03_econometrics/E14_RelativePrice_Integration_Order_Gate.md
  - chapter2_vault/04_data_measurement/D02_PriceDeflator_Protocol_K_Composition.md
stage_scope: S40
country: US
last_updated: 2026-07-26
updated_by: SPECIFICATION_B_PAPER_FACING_FULL_MATRIX_SYNCHRONIZATION
layer: report_mirror
design_role: dissertation_progress_report
scope: chapter2_core
related_to:
  - A06_RelativePrice_Mechanization_Theory
  - E14_RelativePrice_Integration_Order_Gate
  - D02_PriceDeflator_Protocol_K_Composition
subtype: report_mirror
blocks: []
priority: reference
---

# R02: US Specification B IM-OLS Capital Disaggregation Progress Report

> [!important] Paper-Facing Milestone Benchmark
> This vault note mirrors the publication-grade progress report for **Specification B** (Disaggregated Two-Capital Model with Relative Capital Asset Prices) benchmarked directly against Specification A across 8 visual figure environments (featuring 45° angled 5-year tick marks) and 3 paper-facing full result matrix LaTeX tables.
> PDF Compiled Location: `reports/US_SpecificationB_IMOLS_Capital_Disaggregation_Report/us_specB_imols_capital_disaggregation_progress_report.pdf`.

---

## Executive Summary (BLUF)

Specification B resolves the physical capital aggregation restriction ($\psi = b \cdot s_{\text{ME}}$) inherent in Specification A by explicitly disaggregating extensive plant scale ($k_t^{\text{NRC}}$) from intensive mechanization choice ($\tau_t^{\text{real}} = k_t^{\text{ME}} - k_t^{\text{NRC}}$) while controlling for relative asset price valuation drift ($p_t^{\text{rel}} = \ln P_{\text{NFC}}^{\text{ME}} - \ln P_{\text{NFC}}^{\text{NRC}}$).

Estimating the state-dependent two-capital model via Cointegrating Polynomial Regression IM-OLS across the 1925--2024 century sample achieves three major empirical milestones:
1. **Endogenous Choice of Technique**: Mechanization choice responds to distributional squeeze ($\hat{\theta}_{1, \tau} < 0$), proving that class conflict conditions technical choice.
2. **Relative Price Valuation Drift**: Relative capital asset prices ($p_t^{\text{rel}}$) act as a strictly $I(1)$ long-run conditioner that accelerates mechanization independent of wages ($\hat{\gamma}_{p^{\text{rel}}} < 0$).
3. **Total Derivative Overaccumulation & Utilization Path**: One-sector aggregate transformation elasticity derived via total derivative ($\theta_t^{\text{SpecB}} = \frac{d y^p}{d k^{\text{cap}}}$) confirms that U.S. post-war capitalism has operated continuously within the $\theta_t < 1.0$ capital overaccumulation regime (sample mean $\bar{\theta} \approx 0.72$). Reconstructed capacity utilization ($\mu_t^{\text{SpecB}}$) level-anchored to the 1973 Federal Reserve Board peak ($\mu_{1973} = 1.00$) reveals a $+1.8\%$ to $+3.2\%$ disaggregation gap during neoliberal restructuring relative to Specification A.

---

## 1. Paper-Facing Full Result Matrix Architecture

To achieve 100% presentation parity with Specification A, all quantitative tables present the complete estimation matrix across:
- **Centering Regimes**:
  - `RA`: Uncentered Raw Levels
  - `RB`: Initial-State Centered ($(x_t - x_1)$)
  - `RC`: Sample-Mean Centered ($(x_t - \bar{x})$)
- **Dummy States**:
  - `With`: Including historical LOESS step-dummy controls ($D_{1933}, D_{1947}, D_{1968}, D_{1982}, D_{2008}$)
  - `None`: Without step-dummy controls

### Multicollinearity & Centering Resolution
Centering variables around initial values (Regime B) or sample averages (Regime C) eliminates artificial correlation between main effects ($\tau_t$) and interaction terms ($\tau_t \cdot \omega_{t-1}$), stabilizing main effect estimates ($\hat{\theta}_{\tau}$) while leaving interaction estimates ($\hat{\theta}_{1,\tau}$) and Fixed-$b$ HAR $t$-statistics *identically invariant*.

---

## 2. Multi-Angle Visual Figure Portfolio (45° Rotated 5-Year Breaks)

1. **Figure 1 (`fig_specB_3panel_structural_decomposition.png`)**: 3-panel structural decomposition plot of $k_t^{\text{NRC}}$ vs $k_t^{\text{ME}}$, $\tau_t^{\text{real}}$, and $p_t^{\text{rel}}$ with institutional accumulation epoch shading.
2. **Figure 2 (`fig_specB_dual_parameter_forest.png`)**: Choice-of-technique interaction forest plot displaying point estimates and 95% HAR confidence intervals across all 504 model combinations.
3. **Figure 3 (`fig_specB_era_parameter_comparison.png`)**: Accumulation era parameter comparison bar chart with error bars comparing Fordist vs Post-Fordist eras.
4. **Figure 4 (`fig_specB_mechanization_response_surface.png`)**: 2D Iso-Mechanization contour map plotting optimal technical choice $q^*(\omega, p^{\text{rel}})$.
5. **Figure 5 (`fig_specB_reconstructed_capacity_utilization_1973_comparative.png`)**: Comparative 3-path capacity utilization series across Baseline NFC GVA, Shaikh-Tonak Tier 1, and Shaikh-Tonak Tier 2 with 45° angled 5-year tick marks.
6. **Figure 6 (`fig_specB_vs_specA_utilization_gap.png`)**: Differential utilization gap plot ($\Delta \mu_t = \mu_t^{\text{SpecB}} - \mu_t^{\text{SpecA}}$) displaying percentage point deviations.
7. **Figure 7 (`fig_specB_transformation_elasticity_theta_timeseries.png`)**: Total derivative aggregate transformation elasticity trajectory ($\theta_t^{\text{SpecB}}$) with shaded $\theta_t < 1.0$ Capital Overaccumulation Regime.

---

## 3. Quantitative Paper-Facing Tables (`reports/.../tables/`)

- **Table 1 (`table_baseline_imols_specB_primary.tex`)**: Primary Accumulation Eras 18-row estimation matrix across 3 Eras $\times$ 3 Centering Regimes $\times$ 2 Dummy States.
- **Table 2 (`table_baseline_imols_specB_wageshares.tex`)**: Multi-Wage Share 24-row robustness matrix across 4 Wage Measures $\times$ 3 Centering Regimes $\times$ 2 Dummy States.
- **Table 3 (`table_baseline_imols_specB_diagnostics.tex`)**: Diagnostic sub-window estimation matrix.

---

## 4. Next Steps: Chilean Comparative Extension

Immediate next milestone: parallel disaggregated estimation for **Chile (1960--2024)** using `K-Stock-Harmonization` to complete Chapter 2's center-periphery comparative synthesis.
