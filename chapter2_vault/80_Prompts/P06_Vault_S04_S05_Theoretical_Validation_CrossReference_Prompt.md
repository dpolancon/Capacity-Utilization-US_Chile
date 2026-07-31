---
type: prompt
status: active
country: US
stage_scope: results-synthesis
last_updated: 2026-07-31
depends_on:
  - "[[S04_StructuralBreak_locked decisions]]"
  - "[[S05_Appendix]]"
  - "[[S01_StructuralBreak_Protocol]]"
  - "[[S02_StructuralBreak_Protocol]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
  - "[[00E_Chapter2_PaperFacing_Constitution]]"
  - "[[00S_Chapter2_Symbology_and_Notation_Lock]]"
layer: governance_prompt
role: theoretical-adjudication
stage: post-estimation-synthesis
tags:
  - chapter2/prompts
  - chapter2/results
  - chapter2/theoretical-validation
  - chapter2/structural-breaks
  - chapter2/imols
scope: chapter2
priority: high
created_by: Diego
updated_by: THEORETICAL_VALIDATION_CROSSREF_PROMPT
---

# P06: Cross-Referencing S04/S05 Vault Results with Theoretical Hypothesis Validation

## 1. Context & Objective

Notes `S04_StructuralBreak_locked decisions.md` and `S05_Appendix.md` previously relied on purely statistical/econometric criteria (mechanical VIF thresholds, arbitrary lag grids, and pure variance reduction) to select structural break specifications. This approach risks choosing models where collinear break terms destroy or mask the core theoretical mechanisms of Chapter 2.

This prompt establishes a **Dual-Criterion Adjudication Standard** to cross-reference and update vault notes `S04` and `S05` against the verified empirical decision matrix (`structural_break_combinatorics_decision_matrix.md`). Model selection must **privilege theoretical hypothesis validation** alongside econometric cointegration hygiene under **Regime B (Initial-State Centering)**.

---

## 2. Core Theoretical Hypotheses to Privilege

### Hypothesis 1: Aggregate Profit Squeeze ($\theta_1 < 0$ in Specification A)
- **Theoretical Claim**: Distributional conflict conditions aggregate capacity creation. A higher labor wage share ($\omega_{t-1}$) depresses the marginal capacity-generating elasticity of productive capital ($K^{\text{cap}}$).
- **Admissibility Standard**: Structural break models that introduce slope shifts must preserve the negative sign and statistical significance of $\theta_1$ ($\hat{\theta}_1 < 0, p < 0.05$). If multi-way slope breaks induce collinearity that renders $\theta_1$ insignificant or positive without structural rationale, the slope breaks must be converted to additive level controls ($D_t$).

### Hypothesis 2: Intensive Mechanization Choice ($\theta_{\omega\kappa} < 0$ in Specification B)
- **Theoretical Claim**: In disaggregated capital ($K^{\text{NRC}}$ plant vs. $K^{\text{ME}}$ machinery), rising wage shares drive intensive mechanization choice relative to extensive plant scale ($\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$).
- **Admissibility Standard**: The model must identify a statistically significant wage-squeeze interaction ($\hat{\theta}_{\omega\kappa} < 0, p < 0.05$) under initial-state centering. Slope break terms ($\theta_{\omega\kappa,\text{brk}}$) are retained only when they reflect genuine post-break regime shifts without violating condition number bounds ($\text{CN} \le 100$).

---

## 3. Dual-Criterion Adjudication Protocol

Every model in the $2^3 = 8$ (Spec A) and $2^4 = 16$ (Spec B) initial-state centered permutation space must be evaluated across two sequential gates:

### Gate 1: Econometric & Cointegration Hygiene (Regime B Initial-State Centered)
1. **Condition Number Bound**: Standardized Condition Number $\text{CN} \le 100$. Models exceeding 100 are disqualified as `Collinear`.
2. **Residual Stationarity**: Shin LM statistic $C_{\text{Shin}} < 0.095$ (confirming cointegration at 10%).
3. **HAR Joint Significance**: Fixed-$b$ HAR joint Wald test $F$-statistic must reject $H_0: \theta_{\text{main}} = 0 \text{ AND } \theta_{\text{brk}} = 0$ at $p < 0.05$.

### Gate 2: Theoretical Hypothesis Validation
1. **Sign & Significance Stability**: The core theoretical parameters ($\theta_1$ in Spec A; $\theta_{\omega\kappa}$ in Spec B) must be statistically significant and conform to political economy theory.
2. **Parsimonious Selection**: If adding extra slope breaks degrades the $t$-statistic of the main theoretical parameter without yielding a statistically significant break coefficient ($|t_{\text{brk}}| < 1.96$), the break term is converted to a pure level control ($D_t^*$).

---

## 4. Cross-Referenced Adjudication Results (Spec A & Spec B)

### Specification A (Aggregate Capital)
* **Fordist Era (1929–1973; $T_B^* = 1947$)**:
  * **Selected Model**: **SpecA-1** (retains capital scale shift $\theta_{K,\text{brk}} = -1.15^{***}, t = -2.80$).
  * **Theoretical Validation**: Main profit squeeze parameter is **statistically valid and negative**: $\hat{\theta}_1 = -3.45^{***}$ ($t = -2.71$; Wald $F = 7.32, p = 0.011$).
  * **Econometric Hygiene**: $\text{CN} = 46.02 \le 100$, $C_{\text{Shin}} = 0.0255 < 0.095$, $\hat{\sigma}_u = 0.0591$ (17.3% variance reduction).

* **Post-Fordist Era (1974–2024; $T_B^* = 2008$)**:
  * **Selected Model**: **SpecA-1** under Initial-State Centering.
  * **Theoretical & Econometric Validation**: Establishes cointegration ($C_{\text{Shin}} = 0.0276 < 0.095$, $\text{CN} = 74.48$). Because the scale break term is statistically insignificant ($t = -1.11$), it converts to an additive level control ($D_{2008}$).

---

### Specification B (Disaggregated Capital)
* **Fordist Era (1929–1973; $T_B^* = 1947$)**:
  * **Selected Model**: **SpecB-0** (Baseline).
  * **Theoretical & Econometric Validation**: All models with $>1$ slope shift violate $\text{CN} \le 100$. SpecB-0 passes cointegration ($C_{\text{Shin}} = 0.0292, \text{CN} = 90.40$).

* **Post-Fordist Era (1974–2024; $T_B^* = 2008$)**:
  * **Selected Model**: **SpecB-6** (retains gap shift $\theta_{\kappa,\text{brk}} = 4.89^{***}, t = 2.71$ and wage interaction shift $\theta_{\omega\kappa,\text{brk}} = 63.94^{***}, t = 3.36$).
  * **Theoretical Validation**: Mechanization choice wage interaction is **negative and highly significant**: $\hat{\theta}_{\omega\kappa} = -46.56^{***}$ ($t = -3.74$; Wald $F = 7.01, p = 0.0034$).
  * **Econometric Hygiene**: $\text{CN} = 82.48 \le 100$, $C_{\text{Shin}} = 0.0154 < 0.095$, $\hat{\sigma}_u = 0.0277$ (18.7% variance reduction).

---

## 5. Execution Directives for Vault Updating

1. **Update `S04_StructuralBreak_locked decisions.md`**:
   - Replace all legacy $\delta_1, \delta_2, \delta_3$ notation with locked $\theta$-notation ($\theta_{K,\text{brk}}, \theta_{\omega K,\text{brk}}, \theta_{\kappa,\text{brk}}, \theta_{\omega\kappa,\text{brk}}, \theta_{\kappa p^\kappa,\text{brk}}$).
   - Replace old VIF tables with the verified Regime B Initial-State Centered $2^3$ and $2^4$ decision tables.
   - Update executive text to reflect the **Dual-Criterion Adjudication Standard** prioritizing theoretical hypothesis validation.

2. **Update `S05_Appendix.md`**:
   - Align Appendix C description with the Initial-State Centered $2^3$ and $2^4$ combinatorics grids.
   - Update robustness band tables to reflect the exact verified estimates from the IM-OLS engine.
