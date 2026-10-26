---
type: session_handoff
status: active
depends_on: [
  "chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md",
  "chapter2_vault/08_audits_handoffs/2026-08-11_cmpr_custom_cv_benchmarking_memo.md"
]
stage_scope: figure_protocol_and_visualization
country: US_CL
last_updated: 2026-08-11
updated_by: SESSION_HANDOFF_FIGURE_REDESIGN
layer: governance_handoff
role: visualization_and_exposition
stage: section3_and_section4
tags: [handoff, figure-protocol, elasticity, capacity-utilization, im-ols]
---

# Session Handoff: Visual Redesign & Figure Protocol for Admissible Specifications (Section 3 & Section 4)

## 1. Executive Summary & Session Goal
The primary goal of the upcoming session is to **re-design, standardize, and programmatically generate the full suite of analytical figures** for Chapter 2. Visualization will be restricted strictly to **admissible specifications**—models that satisfy the cointegration triad (Engle-Granger ADF, Shin LM, and Vogelsang-Wagner $CT_{\text{IM}}$) and demonstrate statistical significance for the core theoretical mechanisms (the effective wage pressure interaction $\hat{\theta}_1$). 

The session will establish a formal **Figure Protocol** governing formatting, palette, LaTeX float placement, and empirical exposition grounded in political economy (the surplus approach, class struggle, and institutional periodization).

---

## 2. Upstream Audit State & Completed Pipeline Infrastructure
Before initializing figure re-design, the incoming session can rely on the following verified and completed infrastructure:

1. **Wage Share Provenance & Data Boundaries:**
   - The Shaikh-Tonak Tier 2 wage share constant extrapolation (`1929-1947`) has been removed. Tier 2 series cleanly operate over `1948–2024` ($T=77$), while Tier 1 and NIPA baseline series cover `1931–2024` ($T=94$).
2. **Reproducible Fixed-$b$ Non-Standard Inference:**
   - 100,000-pass specification-dependent Monte Carlo simulations (`set.seed(1929)`) have been executed for both sample sizes ($T=94$ and $T=77$). Critical value surfaces are saved under:
     - `output/US/S50_SECTION31_IMOLS/csv/section31_cmpr_custom_critical_values_T94_N100000.csv`
     - `output/US/S50_SECTION31_IMOLS/csv/section31_cmpr_custom_critical_values_T77_N100000.csv`
3. **Estimation Matrix Synchronization:**
   - Both Section 3.1 (Aggregate Capital $k^{\text{cap}}$) and Section 3.2 (Heterogeneous Capital $k^{\text{NRC}}, k^{\text{ME}}$) estimation engines enforce dynamic sample filtering, FWL orthogonalization, and sample-accurate critical value matching.
   - LaTeX summary tables are compiled and available under `reports/US_Section31_IMOLS_Results/` and `reports/US_Section32_IMOLS_Results/`.

---

## 3. Admissibility Criteria & Candidate Models Matrix
Figures must only display results derived from specifications that pass the two-tier admissibility gate:

### Tier 1: Cointegration Triad Confirmation
- **Engle-Granger ADF:** $t_{\text{ADF}}$ rejects the null of no cointegration ($p < 0.05$).
- **Vogelsang $CT_{\text{IM}}$ (Type 2):** $CT_{\text{IM}}$ statistic rejects the null of no cointegration under custom fixed-$b$ critical bounds ($p < 0.05$ or $p < 0.10$).
- **Shin LM:** $C_{\text{Shin}}$ does not reject the null of cointegration.

### Tier 2: Theoretical Admissibility & Mechanism Significance
- **Specification Set 2 (Effective Wage Pressure):** The interaction term $(1-\iota_{t-1}) \cdot \omega_{t-1}$ must yield a negative and statistically significant coefficient ($\hat{\theta}_1 < 0$), confirming that high defensive wage pressure forces capital substitution that depresses capacity yields.
- **NVA Domain Priority:** Net Value Added (NVA) and Shaikh-Tonak Tier 2 supervisory-adjusted series take analytical precedence over unadjusted GVA measures.

### Target Primary Models for Visualization:
- **Section 3.1 (Aggregate Capital):** Model `M2.8a` (Shaikh-Tonak Tier 2 NVA, No Break) and `M2.8b` (With Structural Breaks).
- **Section 3.2 (Heterogeneous Capital):** Model `M2.19a` (Tier 1 NVA, Core Capital) and `M2.24b` (Tier 2 NVA, Core Capital + Breaks).

---

## 4. Target Figure Suite to be Redesigned

| Figure ID | Topic / Analytical Objective | Key Series / Elements | Primary Script Reference |
|---|---|---|---|
| **Figure 1** | **Reconstructed Capacity Utilization ($\mu_t$)** | Compare $\mu_t = Y_t / Y_t^p$ across preferred models (M2.8a/b, M2.19a/24b) against official NIPA/Federal Reserve benchmarks. Include 1973 peak anchor ($100\%$). | `US_S60_section32_reconstruction.R` |
| **Figure 2** | **Transformation Elasticity ($\theta_t$) & Harrodian Knife-Edge** | Plot dynamic elasticity $\theta_t = \frac{d Y^p}{d K}$ against the Harrodian Overcapacity Threshold ($\theta = 1.00$). Highlight long-run transition below $1.00$. | `US_S60_section32_reconstruction.R` |
| **Figure 3** | **State-Dependent Overaccumulation & Distributive Pressures** | Dual-axis alignment of $\theta_t$ against effective wage pressure $(1-\iota_{t-1}) \cdot \omega_{t-1}$ across Fordist (1947–1973) and Post-Fordist (1974–2024) eras. | `US_S60_section423_reconstruction.R` |
| **Figure 4** | **Heterogeneous Mechanization & Asset Composition** | Asset ratio $\tau_t = k^{\text{ME}} - k^{\text{NRC}}$ and relative capital asset prices $p_t^{\kappa}$ driving disaggregated yields $\theta_t^{\text{SpecB}}$. | `COMMON_S37_report_figures_234.R` |

---

## 5. Standardized Figure Protocol Rules (Binding for Next Session)

The new visualization scripts must strictly adhere to the project's visual formatting rules:

1. **No Titles Inside `ggplot2`:**
   - Figure titles, subtitles, and detailed descriptions must **never** be hardcoded inside `ggplot2` objects via `ggtitle()` or `labs(title=...)`. All titles and captions are handled natively in LaTeX.
2. **Palette & Styling:**
   - **Preferred Specification Line:** Solid Deep Navy (`#1B365D`), `linewidth = 1.1`.
   - **Robustness / Break Specification Line:** Dashed Slate Blue (`#5C768D`), `linewidth = 0.9`.
   - **Threshold Lines ($\theta = 1.00$, $\mu = 100\%$):** Dashed Dark Red (`#8B0000`), `linewidth = 0.8`.
   - **Vertical Event/Periodization Line (1973):** Dotted Dark Green (`#006400`), `linewidth = 0.8`.
   - **Theme:** Clean, publication-ready `theme_minimal(base_size = 11)` with subtle gridlines (`#E5E5E5`) and `legend.position = "bottom"`.
3. **Export Formats & Paths:**
   - High-resolution PNG (`300 dpi`) for visual inspection + vectorized PDF (`.pdf`) for LaTeX inclusion.
   - Output destination: `output/US/figures/` or section-specific subdirectories under `output/US/`.

---

## 6. Prompt to Initialize the New Session

Copy and paste the following prompt when starting the new session:

> **New Session Prompt:**
> *"We are starting a dedicated session to re-design and programmatically generate the analytical figures for Chapter 2 based on our admissible IM-OLS specifications (Section 3.1 & Section 3.2). Please read the handoff document at `chapter2_vault/08_audits_handoffs/2026-08-11_figure_redesign_session_handoff.md` and the standing instructions in `AGENTS.md`. We will: (1) Define a master figure generation script following our strict ggplot2/LaTeX protocol, (2) Re-generate Figures 1 through 4 for our preferred admissible models (M2.8a/b and M2.19a/24b), and (3) Draft political-economy interpretations for each figure grounded in the surplus approach, class struggle, and institutional periodization."*

---
*Prepared by Agentic AI Coding Assistant — 2026-08-11*
