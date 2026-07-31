---
type: research_note
status: active
created: 2026-07-25
session_id: dde829f2-9b4b-42db-85bc-10040c085fcd
country: US_CL
scope: capital_integration_cointegration_mechanization_specification
authority_files:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
  - AGENTS.md
subtype: handoff
stage_scope: N/A
last_updated: '2026-07-29'
depends_on: []
blocks: []
layer: archive
priority: context
---

# Session Handoff — Capital Integration, Cointegration & Cavaliere Wild Bootstrap Audit

**Date:** July 25, 2026  
**Session ID:** `dde829f2-9b4b-42db-85bc-10040c085fcd`  
**Repository:** `Capacity-Utilization-US_Chile`  

---

## 1. Executive Summary & Core Deliverables

This session upgraded the unified empirical audit of heterogeneous capital integration and cointegration across the U.S. (1925–2021) and Chile (1920–2024) by implementing Cavaliere et al. (2012) Wild Bootstrap rank testing and re-normalizing all cointegrating vectors strictly with Nonresidential Structures ($K^{\text{NRC}}$/$K^{\text{NR}}$) on the LHS.

### Key Accomplishments:
1. **Econometric Pipeline Upgrade (`codes/COMMON_S34_break_informed_vecm_pipeline.R`)**:
   - Implemented 500-replication Cavaliere, Rahbek, & Taylor (2012) Rademacher wild bootstrap rank tests (`wild_bootstrap_johansen_trace`) to handle heteroskedasticity and non-stationary volatility.
   - Normalized cointegrating vectors as $k_t^{\text{NRC}} = \hat{\alpha} + \hat{\gamma} k_t^{\text{ME}} + \hat{u}_t$.

2. **Master LaTeX Report & PDF Re-compiled**:
   - **Path:** [`output/reports/capital_integration_cointegration_comprehensive_report.tex`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/reports/capital_integration_cointegration_comprehensive_report.tex)
   - **PDF:** [`output/reports/capital_integration_cointegration_comprehensive_report.pdf`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/reports/capital_integration_cointegration_comprehensive_report.pdf) (10 pages).
   - **Table 4**: Added dual bootstrap comparison (standard i.i.d.\ vs Cavaliere wild bootstrap).

---

## 2. Updated Econometric Findings

| Specification | Standard Trace | i.i.d.\ Boot $p$ | Cavaliere Wild Boot $p$ | $\hat{\gamma}$ ($k^{\text{NRC}} = \hat{\alpha} + \hat{\gamma} k^{\text{ME}}$) | Interpretation |
|---|---|---|---|---|---|
| **Chile Full Century (Drift)** | 31.36 ($r=1$) | 1.000 | **0.004** | **0.955** | Balanced Fordist mechanization |
| **Chile Dictatorship (Drift)** | 32.70 ($r=1$) | 0.102 | **0.008** | **1.157** | Wage suppression / structural plant growth |
| **U.S. Full Century (Drift)** | 22.76 ($r=1$) | 1.000 | **0.026** | **0.994** | Proportional long-run growth ($\hat{\gamma} \approx 1.0$) |
| **U.S. Century Break-Aug. (Trend)** | 33.72 ($r=1$) | **0.030** | **0.014** | **0.237** ($\approx 0.24$) | Post-Fordist decoupling: plant construction grew at $< 1/4$ rate of machinery deepening |

---

## 3. Active Artifacts

- **LaTeX Source:** [`output/reports/capital_integration_cointegration_comprehensive_report.tex`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/reports/capital_integration_cointegration_comprehensive_report.tex)
- **PDF Report:** [`output/reports/capital_integration_cointegration_comprehensive_report.pdf`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/reports/capital_integration_cointegration_comprehensive_report.pdf)
- **Ledger CSV:** [`output/break_informed_johansen_vecm_ledger.csv`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/break_informed_johansen_vecm_ledger.csv)
- **R Pipeline:** [`codes/COMMON_S34_break_informed_vecm_pipeline.R`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/COMMON_S34_break_informed_vecm_pipeline.R)
