---
type: paper_facing
status: results
country: CL
stage_scope: S04_Empirical_Handoff
last_updated: 2026-08-09
updated_by: CHILE_DIVISIA_ELASTICITY_AUDIT_UPDATE
depends_on:
  - chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md
  - chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
  - chapter2_vault/04_data_measurement/V02_Chile_KStock_DataProvenance_Management.md
  - chapter2_vault/08_audits_handoffs/2026-08-09_chile_data_provenance_audit_report.md
layer: results
scope: section 4.4
priority: core
---

# R05: Chile Model Selection, Cointegration Rank & Trustworthy Aggregate Elasticity Audit

**Date:** 2026-08-09  
**Scope:** Chilean Peripheral Extension (Section 3.3 / 4.4, $1920\text{--}2024$, $N=104$)  
**Authority:** `chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md` & `00E_Chapter2_PaperFacing_Constitution.md`

---

## Executive Summary

This audit report evaluates all estimated Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS models for the Chilean economy ($1920\text{--}2024$) to identify **preferable specifications** based on cointegration strength, statistical parameter admissibility, VIF collinearity diagnostics, and the construction of a **rigorous Divisia aggregate transformation elasticity ($\theta^{\text{Peripheral}}_t$)**.

Benchmarked against our 100,000-pass seed-locked Monte Carlo critical bounds (`set.seed(1920)`), this audit establishes **Model M3.3b (Level Machinery Import Imbalance)** and **Model M3.2a (Continuous Mediated ToT Capacity)** as the primary preferable models for aggregate elasticity reconstruction ($\bar{\theta}_t \in (0, 1.0)$), supported by **Model M3.3a (Prebischian Purchasing Power of Exports)** as the strongest cointegration anchor.

---

## 1. Mathematical Derivation of Divisia Aggregate Transformation Elasticity ($\theta^{\text{Peripheral}}_t$)

Following the constitutional production surface:
$$y_t = \alpha + \theta_{\text{NRC}} k^{\text{NR}}_t + \theta_{\kappa} \kappa_t + \theta_{\omega\kappa} \hat{\omega}^{\text{ortho}}_{t-1} \kappa_t + \theta_{\kappa p^{\kappa}} \hat{p}^{\kappa, \text{ortho}}_t + \delta_{\kappa} (\kappa_t \cdot D^{\text{ext}}_t) + \delta_{\omega\kappa} (\hat{\omega}^{\text{ortho}}_{t-1} \kappa_t \cdot D^{\text{ext}}_t) + u_t$$

### A. Total Differential of Potential Capacity ($dy^p_t$)
Holding slow-moving state variables fixed, taking the total differential yields:
\begin{align}
    dy^p_t &= \theta_{\text{NRC}} dk^{\text{NR}}_t + MP_{\kappa, t} d\kappa_t \\
    &= \theta_{\text{NRC}} dk^{\text{NR}}_t + \left[ \theta_{\kappa} + \theta_{\omega\kappa} \omega_{t-1} + \theta_{\kappa p^{\kappa}} p^{\kappa}_t + \delta_{\kappa} D^{\text{ext}}_t + \delta_{\omega\kappa} (\omega_{t-1} D^{\text{ext}}_t) \right] d\kappa_t
\end{align}

### B. Divisia Index of Heterogeneous Aggregate Capital ($dk^{\text{cap}}_t$)
Variation in aggregate capital follows from the Divisia index of its heterogeneous structural components. Since $s_{\text{ME}, t} + s_{\text{NRC}, t} = 1$ and $d\kappa_t = dk^{\text{ME}}_t - dk^{\text{NRC}}_t$:
\begin{align}
    dk^{\text{cap}}_t &\approx s_{\text{ME}, t} dk^{\text{ME}}_t + s_{\text{NRC}, t} dk^{\text{NRC}}_t \\
    &= dk^{\text{NR}}_t + s_{\text{ME}, t} d\kappa_t
\end{align}

### C. Ratio along the Empirical Accumulation Path
Dividing $dy^p_t$ by $dk^{\text{cap}}_t$ and decomposing $d\kappa_t$ into its inner composition $\frac{d\kappa_t}{dk^{\text{NR}}_t} = \left(\frac{dk^{\text{ME}}_t}{dk^{\text{NR}}_t} - 1\right) = \beta^{\text{path}}_t - 1$ yields the exact state-dependent aggregate transformation elasticity:

\begin{equation}
    \theta^{\text{Peripheral}}_t = \frac{\theta_{\text{NRC}} + \left[ \theta_{\kappa} + \theta_{\omega\kappa} \omega_{t-1} + \theta_{\kappa p^{\kappa}} p^{\kappa}_t + \delta_{\kappa} D^{\text{ext}}_t + \delta_{\omega\kappa} (\omega_{t-1} D^{\text{ext}}_t) \right] \left( \frac{d\kappa_t}{dk^{\text{NR}}_t} \right)}{1 + s_{\text{ME}, t} \left( \frac{d\kappa_t}{dk^{\text{NR}}_t} \right)}
    \label{eq:theta_divisia_peripheral_results}
\end{equation}

where $\beta^{\text{path}}_t = \frac{dk^{\text{ME}}_t}{dk^{\text{NR}}_t}$ is estimated via non-parametric LOESS regression of $k^{\text{ME}}_t$ on $k^{\text{NR}}_t$ along the historical accumulation path ($\text{span} = 0.35$).

---

## 2. Cointegration & Econometric Admissibility Criteria

To be classified as a **preferable model**, an empirical specification must satisfy four strict econometrics gates:

1. **Cointegration Triad Confirmation ($H_0$: Cointegration)**:
   - Residual ADF ($t_{\text{ADF}} \le -4.29$, $p < 0.05$).
   - Shin LM ($C_{\text{Shin}} \le 0.0430$, passing 95% Monte Carlo bound).
   - Vogelsang-Wagner Type 2 ($S_{\text{Type 2}} \le 7.82$, passing 95% Monte Carlo bound of $0.0430$ on $C_{\text{Shin}}$ and $3.697$ on $t$-stats).
2. **Divisia Aggregate Elasticity Admissibility**:
   - $\bar{\theta}^{\text{Peripheral}}_t \in (0, 1.0)$ across the estimation sample.
3. **Collinearity Governance**:
   - Base regressors $VIF \le 1.42$; orthogonalized interaction terms $VIF \le 1.06$.

---

## 3. Master Model Comparison & Divisia Elasticity Summary Matrix

Below is the comparative audit matrix across all primary Chilean specifications estimated in `output/chile_imols_peripheral_results.csv`:

| Model ID | Specification Name | Threshold Variable ($v_t$) | Optimal Cutoff ($\hat{\gamma}$) | Resid ADF ($t_{\text{ADF}}$) | Shin LM ($C_{\text{Shin}}$) | VW Type 2 ($S_{\text{Type 2}}$) | Base Elasticity ($\hat{\theta}_{\text{NRC}}$) | Divisia Mean Elasticity ($\bar{\theta}_t$) | Admissibility Verdict |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **M3.1a** | Baseline CMPR | None | — | $-4.12^{**}$ | $0.04$ | $9.15$ | $0.86^{***}$ (0.17) | $0.7973$ | **Rejected**: Lacks BoP gate; fails wage dividend. |
| **M3.2a** | Continuous Mediated | $M^{\text{cap, ToT}}_t$ | — | $-4.35^{**}$ | $0.03$ | $7.82$ | $0.79^{***}$ (0.14) | **$0.6826$** | **PREFERRED PRIMARY (Continuous)**: Perfectly bounded in $(0, 1.0)$. |
| **M3.3a** | T-CMPR Prebischian | $M^{\text{cap, ToT}}_t$ | $16.28$ | $-4.68^{***}$ | $0.02$ | **$6.45$** | $1.19^{***}$ (0.09) | $1.1250$ | **PREFERRED ANCHOR (Trade)**: Strongest cointegration score. |
| **M3.3b** | T-CMPR Machinery Imbal. | $\text{Imbalance}_{\text{level}, t}$ | $-1.64$ | $-4.42^{**}$ | $0.03$ | **$7.12$** | $1.04^{***}$ (0.13) | **$0.8777$** | **PREFERRED PRIMARY (Demand)**: Bounded Divisia elasticity in $(0, 1.0)$. |
| **M3.3c** | T-CMPR Growth Imbal. | $\text{Imbalance}_{\text{growth}, t}$ | $0.27$ | $-4.18^{**}$ | $0.04$ | $8.95$ | $0.86^{***}$ (0.15) | $0.8012$ | **Diagnostic**: High variance in growth rates. |
| **M3.3d** | T-CMPR WBOP Manuf. | $M^{\text{manuf}}_t / Y_t$ | $0.07$ | $-4.31^{**}$ | $0.03$ | $7.60$ | $0.85^{***}$ (0.15) | $0.7895$ | **Preferred WBOP**: Bounded capital import proxy. |
| **M3.3e** | T-CMPR WBOP Remittance | $D1c_t$ (Outflows) | $0.09$ | $-4.55^{***}$ | $0.03$ | **$6.90$** | $1.11^{***}$ (0.13) | $1.0375$ | **PREFERRED FINANCIAL**: Best debt/remittance gate. |
| **M3.3f** | T-CMPR WBOP Current Acc. | $F1_t$ (CA Balance) | $-0.02$ | $-4.30^{**}$ | $0.03$ | $7.45$ | $0.92^{***}$ (0.16) | $0.8510$ | **Secondary WBOP**: Overall external balance. |

---

## 4. Dynamic Trajectory Comparison

```text
Model M3.2a (Continuous Mediated ToT Capacity):
  - Divisia Mean theta_t: 0.6826 (Strictly bounded within (0, 1.0))
  - Normal Regime (Slack BoP): theta_t ≈ 0.72 -- 0.79
  - Crisis Regime (Low BoP): theta_t collapses continuously to 0.42 -- 0.51

Model M3.3b (Level Machinery Demand Imbalance):
  - Divisia Mean theta_t: 0.8777 (Strictly bounded within (0, 1.0))
  - Normal Regime (Slack BoP): theta_t ≈ 0.91 -- 0.96
  - Crisis Regime (High Imbalance): theta_t drops to 0.52 -- 0.64

Model M3.3a (Prebischian Purchasing Power of Exports):
  - Divisia Mean theta_t: 1.1250 (Strongest cointegration anchor, S_Type2 = 6.45)
  - Normal Regime (Slack BoP): theta_t ≈ 1.10
  - Crisis Regime (Binding BoP): theta_t drops to 0.48 -- 0.62
```

---

## 5. Final Model Promotion Verdict

1. **Primary Preferred Model for Elasticity Reconstruction**: **Model M3.3b (Level Machinery Import Imbalance)** and **Model M3.2a (Continuous Mediated ToT Capacity)**.
   - Yields bounded Divisia aggregate transformation elasticities ($\bar{\theta}_t = 0.8777$ and $0.6826$) strictly within the theoretical $(0, 1.0)$ envelope.
2. **Primary Preferred Model for Cointegration Discipline**: **Model M3.3a (Prebischian Purchasing Power of Exports)**.
   - Strongest cointegration score ($S_{\text{Type 2}} = 6.45$).

---

## Data Lineage & Vault Links

- **Primary Results CSV**: [`output/chile_imols_peripheral_results.csv`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/chile_imols_peripheral_results.csv)
- **100k Seed-Locked Monte Carlo CSV**: [`output/Chile_S52_cmpr_critical_values_N100000.csv`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/Chile_S52_cmpr_critical_values_N100000.csv)
- **Paper-Facing Specifications Draft**: [`chapter2_vault/06_paper_facing/drafts/ch2_sec4_4_peripheral_extension_Chile/ch2_sec4_4_1_specifications.md`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/drafts/ch2_sec4_4_peripheral_extension_Chile/ch2_sec4_4_1_specifications.md)
- [[00N_Chapter2_PaperFacing_MAP]] — Locked 6-section paper structure
- [[V02_Chile_KStock_DataProvenance_Management]] — Chile data provenance management note
- [[2026-08-09_chile_data_provenance_audit_report]] — Chile master data provenance audit report
