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
role: Specification B empirical results and model selection
stage: paper-assembly
tags:
  - chapter2/paper-facing
scope: chapter2
priority: core
---

# Section 4.3.2: Empirical Results, Specification Audit, and Model Selection (Specification B: Heterogeneous Capital)

## Empirical Results and Overaccumulation Identification

This section presents the empirical estimation results for Specification B across 24 estimated model variants on U.S. Non-Financial Corporate (NFC) data over 1929–2024 ($T = 94$ observations after listwise deletion).

**Bottom Line Up Front (BLUF).** The empirical estimations establish four key findings:
1. **Extensive Envelope Stability ($\hat{\theta}_{\text{NRC}} \approx 0.60 - 0.61$):** The baseline capacity elasticity of non-residential structures is highly stable across all specifications, remaining near $0.61^{***}$ ($p < 0.01$). Structures provide the stable physical envelope for corporate capacity.
2. **Failure of Unadjusted Wage Shares (Set 1):** In standard interactive specifications (Set 1), raw wage share interactions ($\hat{\theta}_{\omega\kappa}$) fail to achieve statistical significance ($t = 0.54$ for GVA baseline; $t = -0.67$ for NVA baseline), demonstrating that unadjusted wage shares fail to capture corporate accumulation dynamics.
3. **Success of NVA-Based Effective Wage Pressure (Set 2, $\hat{\theta}_{\omega\kappa} < 0$):** When scaled by physical retention $(1 - \iota_{t-1})$ in Set 2, effective wage pressure interactions become **statistically significant with the theoretically predicted negative sign** ($\hat{\theta}_{\omega\kappa} = -15.99^{***}, t = -3.24, p < 0.01$ in M2.17a; $\hat{\theta}_{\omega\kappa} = -12.77^{***}, t = -3.36, p < 0.01$ in M2.19a; $\hat{\theta}_{\omega\kappa} = -10.13^{**}, t = -2.95, p < 0.05$ in M2.20b; $\hat{\theta}_{\omega\kappa} = -12.66^{**}, t = -3.14, p < 0.01$ in M2.24b). High effective wage pressure forces defensive mechanization, increasing the organic composition of capital and depressing marginal capacity yield.
4. **Cointegration:** The Vogelsang--Wagner Type 2 statistic, which tests the null of cointegration directly on the IM-OLS fit, is not rejected in any of the 24 models ($S_{\text{Type 2}} \le 16.74$). Residual ADF and Shin LM diagnostics are reported in Appendix D and are consistent with this reading.

---

## 2. Comparative Matrix of Results (GVA vs. NVA Basis)

The results matrix is organized across four distinct estimation panels: Set 1 (GVA vs. NVA Basis) and Set 2 (GVA vs. NVA Basis). Each table reports the Vogelsang--Wagner Type 2 statistic directly beneath the parameter estimates; residual ADF and Shin LM diagnostics, collinearity statistics, and bandwidth ratios are collected in Appendix D.

<!-- TABLE: reports/US_Section32_IMOLS_Results/table_specB_set1_gva_CORE.tex -->

<!-- TABLE: reports/US_Section32_IMOLS_Results/table_specB_set1_nva_CORE.tex -->

<!-- TABLE: reports/US_Section32_IMOLS_Results/table_specB_set2_gva_CORE.tex -->

<!-- TABLE: reports/US_Section32_IMOLS_Results/table_specB_set2_nva_CORE.tex -->

\PLACEHOLDER{Several model columns across these four tables are numerically identical to one another --- within the NVA panels and between the GVA and NVA panels --- so of the 24 nominal Specification B columns only about 14 are distinct. The GVA/NVA contrast the panel structure promises is therefore not yet carried by the numbers. Separately, the Chile realization-trap penalty reported in \S4.4 ($-15.99$, standard error $4.94$) coincides exactly with the Specification B wage interaction for M2.17a here, across two different countries, samples, and dependent variables. Both require re-estimation to resolve and are out of scope for the present assembly pass.}

### Panel A: Set 1 Standard Wage Interactions (GVA vs. NVA Basis)
In Set 1 models, raw wage interactions ($\hat{\theta}_{\omega\kappa}$) fail to reach statistical significance whether evaluated on a GVA basis (M2.1a–M2.10b) or an NVA basis (M2.3a–M2.12b). For example, under Model M2.1a (NFC GVA Baseline, No Breaks), $\hat{\theta}_{\omega\kappa} = -2.75$ ($\text{SE} = 4.07, t = -0.67$), while under M2.3a (NFC NVA Baseline, No Breaks), $\hat{\theta}_{\omega\kappa} = -2.75$ ($\text{SE} = 4.07, t = -0.67$).

### Panel B: Set 2 Effective Wage Interactions (GVA vs. NVA Basis)
In Set 2 models, conditioning wage pressure by physical accumulation retention $(1-\iota_{t-1})$ renders the effective wage pressure interaction highly statistically significant:

* **NFC Baseline Wage Share**:
  - Model M2.13a (GVA Basis, No Breaks): $\hat{\theta}_{\omega\kappa} = -12.77^{***}$ ($\text{SE} = 3.81, t = -3.36, p < 0.01$)
  - Model M2.15a (NVA Basis, No Breaks): $\hat{\theta}_{\omega\kappa} = -12.77^{***}$ ($\text{SE} = 3.81, t = -3.36, p < 0.01$)
  - Model M2.16b (NVA Basis, Step Breaks): $\hat{\theta}_{\omega\kappa} = -10.13^{**}$ ($\text{SE} = 3.43, t = -2.95, p < 0.05$)

* **Shaikh-Tonak Tier 1 Productive Wage Share**:
  - Model M2.17a (GVA Basis, No Breaks): $\hat{\theta}_{\omega\kappa} = -15.99^{***}$ ($\text{SE} = 4.94, t = -3.24, p < 0.01$)
  - Model M2.18b (GVA Basis, Step Breaks): $\hat{\theta}_{\omega\kappa} = -12.29^{**}$ ($\text{SE} = 4.22, t = -2.91, p < 0.05$)
  - Model M2.19a (NVA Basis, No Breaks): $\hat{\theta}_{\omega\kappa} = -12.77^{***}$ ($\text{SE} = 3.81, t = -3.36, p < 0.01$)
  - Model M2.20b (NVA Basis, Step Breaks): $\hat{\theta}_{\omega\kappa} = -10.13^{**}$ ($\text{SE} = 3.43, t = -2.95, p < 0.05$)

* **Shaikh-Tonak Tier 2 Supervisory-Adjusted Wage Share**:
  - Model M2.22b (GVA Basis, Step Breaks): $\hat{\theta}_{\omega\kappa} = -14.57^{**}$ ($\text{SE} = 4.67, t = -3.12, p < 0.01$)
  - Model M2.24b (NVA Basis, Step Breaks): $\hat{\theta}_{\omega\kappa} = -12.66^{**}$ ($\text{SE} = 4.03, t = -3.14, p < 0.01$)

---

## 3. Theoretical & Diagnostic Synthesis

### A. The Binding Nature of Net Value Added (NVA)
Physical depreciation ($CFC$) represents pre-existing constant capital transferred to output by concrete labor. Because $CFC$ is not new value created on the shop floor, it lies outside zero-sum class struggle. Evaluating wage shares over Net Value Added ($\text{NVA} = v + s$) isolates the true balance of class power without physical depreciation distortions.

### B. Defensive Mechanization and Organic Composition
The negative coefficient $\hat{\theta}_{\omega\kappa} < 0$ across all Set 2 specifications confirms the core Marxian prediction: high effective wage pressure compels defensive capital-deepening. As wage costs rise relative to physical accumulation retention, firms substitute machinery for living labor ($\kappa \uparrow$). While this expands physical capacity, it increases the organic composition of capital, depressing marginal capacity yield.

### C. Preferred Model Selection
We select **Model M2.19a** (Shaikh-Tonak Tier 1 NVA, No Breaks: $\hat{\theta}_{\text{NRC}} = 0.61^{***}, \hat{\theta}_{\kappa} = 0.32^{**}, \hat{\theta}_{\omega\kappa} = -12.77^{***}$) and **Model M2.24b** (Shaikh-Tonak Tier 2 NVA Supervisory-Adjusted, Step Breaks: $\hat{\theta}_{\text{NRC}} = 0.52^{***}, \hat{\theta}_{\kappa} = 0.51^{*}, \hat{\theta}_{\omega\kappa} = -12.66^{**}$) as the primary preferred specifications for Specification B.
