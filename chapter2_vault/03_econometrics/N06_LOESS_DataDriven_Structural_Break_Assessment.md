---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-23
layer: econometrics
design_role: loess_data_driven_break_assessment
scope: comparative_structural_break_methodology
created: 2026-07-23
sources:
  - output/loess_inflection_break_comparison.csv
  - output/break_informed_johansen_vecm_ledger.csv
related_to:
  - N03_US_Theta_Integration_Order_Admissibility
  - N04_CL_Theta_Integration_Order_Admissibility
  - N05_Capital_Integration_Order_Comprehensive_Audit
  - E12_QStar_Demotion_Lock
tags:
  - chapter2/econometrics
  - chapter2/loess-inflection
  - chapter2/structural-breaks
  - chapter2/data-first
subtype: econometric_protocol
blocks: []
priority: reference
---

# N06 — LOESS 2nd Derivative Zero-Crossing VECM Assessment (Reconciled Synthesis)

## Executive Summary

This note reconciles the empirical role of **LOESS 2nd derivative zero-crossing dates ($\frac{d^2 \tau_t}{dt^2} = 0$)** versus discrete institutional step-dummies in Johansen VECM models for the US (1925--2021) and Chile (1920--2024).

Grounded in UMass Applied Econometrics Rule 2B (*Data-First Non-Parametric Visualization*), we resolve the complementary functions of both tools:
1. **Non-Parametric LOESS 2nd Derivative Inflections ($\frac{d^2 \tau_t}{dt^2} = 0$)**: Detect smooth, continuous turns in the rate of change of capital composition (e.g. **1968** in US, **1971** in Chile). They serve as *early warning indicators* of technical accumulation strain.
2. **Parametric Johansen VECM Step-Dummies ($D_t$)**: Model discrete structural level shifts in the cointegration space when technical strain culminates in a macro-institutional crisis (**1973** OPEC/coup shock).

## UMass Analytical Reconciliation

- **U.S. Fordist Squeeze (1968 vs 1973)**: The non-parametric LOESS inflection in **1968** shows that machinery deepening slowed 5 years *before* the 1973 OPEC oil shock, proving that technical reorganization preceded the energy/political crisis.
- **VECM Cointegration Performance**: Passing institutional step-dummies ($D_{1973}, D_{2008}$) into trend-augmented Johansen VECM yields strong cointegration ($r=1$, Trace = **33.72** > 25.32, $\hat{\gamma} = 4.2208$). In drift-controlled VECMs (`ecdet="const"`), the un-augmented full sample already yields unit long-run cointegration ($\hat{\gamma} = 1.0058$ for US; $\hat{\gamma} = 1.0471$ for Chile).

## Source Artifacts
- Script: `codes/COMMON_S36_loess_break_assessment.R`
- Comparison Ledger: `output/loess_inflection_break_comparison.csv`
- LOESS Plot: `output/figures/chile_us_capital_breaks_loess.png`
