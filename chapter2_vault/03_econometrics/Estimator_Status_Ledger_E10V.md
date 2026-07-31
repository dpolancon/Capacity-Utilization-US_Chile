---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US
last_updated: 2026-07-25
layer: code_stage_design
created_by: E10V_I2_TRAP_RESOLUTION
updated_by: CPR_IMOLS_ESTIMATION_PROTOCOL_LOCK
role: active-ledger
stage: pre-estimation-design
tags:
  - chapter2/econometrics
  - chapter2/active-ledger
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# Estimator Status Ledger E10V

| Estimator / Filter | Status for CPR Cross-Product Design | Allowed Role | Blocked Role | Required Gate / Rule |
| :--- | :--- | :--- | :--- | :--- |
| **IM-OLS (CPR-adapted)** | **Preferred Baseline** | Long-run parameter estimation and capacity reconstruction. | Silent re-estimation in downstream results packaging. | Vogelsang-Wagner residual test. |
| **FWL Orthogonalization** | **Forbidden Pre-Filter** | None — breaks continuous mapping limit ($SM_X \neq M_{SX}S$). | Pre-filtering interaction terms prior to IM-OLS. | Formally prohibited. |
| **Centering Regimes (A/B/C)** | **Diagnostic Robustness** | Regime A: Main (Uncentered, QR/SVD). Regime B: Primary Robustness (Initial-state). Regime C: Secondary (Sample-mean). | Halting pipeline on numerical drift. | Confidence-band overlap diagnostic (see [[N11_Centering_Protocol_Three_Regime]]). |
| **Restricted DOLS** | **Diagnostic/Robustness** | Comparator to check coefficient stability. | Baseline estimation. | Integration-order gate check. |
| **FM-OLS** | **Diagnostic/Robustness** | Comparator for linear sub-specifications. | Baseline estimation. | Path-dependent Brownian limit check. |
| **Static OLS** | **Preliminary levels check** | Cointegration diagnostics. | Final coefficient inference. | Integration-order gate check. |
| **Johansen / VECM** | **System robustness** | System dynamic checks. | Automatic replacement for single-equation CPR baseline. | Integration-order gate check. |

