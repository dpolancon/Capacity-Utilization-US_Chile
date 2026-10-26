---
type: pending_task
status: active
depends_on:
  - chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md
  - chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
  - chapter2_vault/08_audits_handoffs/2026-08-09_chile_data_provenance_audit_report.md
stage_scope: paper-facing
country: CL
last_updated: 2026-08-17
updated_by: CHILE_OMEGA_NET_SPLICING_AUDIT
layer: audit
role: pending-task-memo
stage: econometric-estimation
tags:
  - chapter2/audit
  - chapter2/pending-task
  - chapter2/chile
  - chapter2/distributive-shares
scope: chapter2
priority: medium
---

# Pending Task: Chilean Net Wage Share ($\omega^{\text{net}}$) Robustness Permutation Reruns

**Date:** 2026-08-17  
**Scope:** Chilean Peripheral Threshold CMPR IM-OLS Robustness Matrix  
**Context:** Splicing correction of post-1994 Consumption of Fixed Capital in `codes/CL_S40_price_proxy_integration.R`  

---

## 1. Executive Summary & Status of Core Results

On 2026-08-17, a forensic audit of `codes/CL_S40_price_proxy_integration.R` identified a redundant division factor applied to the post-1994 Central Bank of Chile (BCCh) depreciation series ($D_{\text{ME}} / 5.888$ and $D_{\text{NRC}} / 1.033$). Because the underlying file (`harmonized_series_2003CLP_1900_2024.csv` from `K-Stock-Harmonization`) was already harmonized to the 2003 CLP price basis matching Pérez & Eyzaguirre (2021) in 1990–1994, this division artificially suppressed real depreciation by 67%, causing $\omega^{\text{net}}$ to collapse from $0.783$ in 1994 down to $0.446$ in 1995.

### Verdict on Primary Empirical Results:
- **Core Results are 100% Intact and Unaffected**: The preferred Chilean CMPR State-Dependent Model ($Z_t \le 0.425$, $\theta_t^{\text{Agg}} \in [0.68, 0.95]$, and the $\mu_t$ capacity utilization series in `output/chile_fig1_mu_theta_dual_axis.pdf`, Section 4.4, and Section 5) was estimated using the lagged **Gross Wage Share** ($\omega_{t-1}^{\text{gross}}$), derived from Astorga (2023) / BCCh / Rodríguez Weber (2014).
- **Stylized Facts Updated**: Figure 3 in Section 4 (`fig_cl_stylized_3_wage_share.pdf`) and Table 2 (`tab_cl_stylized_facts_summary.tex`) have been regenerated with the corrected $\omega^{\text{net}}$ series (mean = $0.768$, $\text{SD} = 0.117$).

---

## 2. Scope of Pending Robustness Tasks

The only econometric models impacted by the corrected $\omega^{\text{net}}$ series are secondary exploratory permutations reported in **Appendix D Robustness Tables**:

1. **Section 3.3 Exploratory Grid (`codes/CL_S50_section33_imols_estimation.R`)**:
   - Models evaluating `omega_net_lag` and `e_net_lag` under Set 1 (Tier 0 physical core) and Set 2 (Tier 1 standalone relative prices).
2. **Backward-Expanding Windows (`codes/CL_S54_imols_backward_expanding_windows.R`)**:
   - Expanding sample stability tests configured with `omega_net_lag`.

---

## 3. Execution Protocol for Future Full Reruns

If full re-estimation of the Appendix D exploratory grids is requested:

1. **Step 1 — Verify Staged Panel**:
   Confirm `data/staged/ch2_panel_chile_with_prices.csv` is updated via:
   ```powershell
   Rscript codes/CL_S40_price_proxy_integration.R
   ```
2. **Step 2 — Re-run Exploratory Grid**:
   ```powershell
   Rscript codes/CL_S50_section33_imols_estimation.R
   ```
3. **Step 3 — Re-run Expanding Windows**:
   ```powershell
   Rscript codes/CL_S54_imols_backward_expanding_windows.R
   ```
4. **Step 4 — Update Appendix D LaTeX Tables**:
   Verify and synchronize Appendix D markdown logs (`reports/Chile_Section33_Peripheral_IMOLS_Results/`) and `.tex` tables.
