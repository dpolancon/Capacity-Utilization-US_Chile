---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-23
layer: econometrics
design_role: comprehensive_capital_integration_audit
scope: comparative_capital_integration_order
created: 2026-07-23
sources:
  - output/comprehensive_urca_unit_root_matrix.csv
  - output/break_informed_johansen_vecm_ledger.csv
related_to:
  - N03_US_Theta_Integration_Order_Admissibility
  - N04_CL_Theta_Integration_Order_Admissibility
  - N06_LOESS_DataDriven_Structural_Break_Assessment
  - Interaction_Term_Integration_Order_Gate
  - E12_QStar_Demotion_Lock
tags:
  - chapter2/econometrics
  - chapter2/comprehensive-urca
  - chapter2/integration-order
  - chapter2/drift-trend-vecm
subtype: econometric_protocol
blocks: []
priority: reference
---

# N05 — Comprehensive Capital Integration & Cointegration Audit (Exact Windows, Drift vs Trend, & I(1) Verification)

## Executive Summary

This note documents the comprehensive unit root and cointegration audit for the **United States (1925--2021, 97 annual observations)** and **Chile (1920--2024, 105 annual observations)** across exact historically informed sub-samples:
- **US**: 1925--1946 (Interwar & WWII), 1947--1973 (Fordist Expansion), 1974--2008 (Neoliberal Restructuring), 2009--2021 (Post-GFC Stagnation), 1925--2021 (Full Long-Fordism Century).
- **Chile**: 1920--1938 (Nitrate Crisis), 1939--1973 (Classic ISI), 1974--1989 (Dictatorship Shock), 1990--2024 (Democratic Neoliberal Export Model), 1920--2024 (Full Chile Century).

## Core Econometric Findings

1. **First-Difference $I(1)$ Verification**:
   - For all composing assets ($K^{\text{ME}}$ and $K^{\text{NRC}}$/$K^{\text{NR}}$), log-levels fail to reject unit roots across ADF, PP, and ERS-GLS tests ($p > 0.10$), while first differences ($\Delta \ln K_t$) strongly reject unit roots ($p < 0.01$). Both series are strictly $I(1)$.

2. **Drift Controls (`ecdet = "const"`)**:
   - **US Full Century (1925--2021)**: Trace = **22.76** > 19.96 (5% CV) $\to$ **$r=1$ (Cointegrated)** with long-run elasticity $\hat{\gamma} = 1.0058$ (unitary elasticity).
   - **Chile Full Century (1920--2024)**: Trace = **31.36** > 19.96 (5% CV) $\to$ **$r=1$ (Cointegrated)** with long-run elasticity $\hat{\gamma} = 1.0471$.

3. **Trend Stationarity Controls (`ecdet = "trend"`) & Small-Sample Bootstrap**:
   - **US Full Century Institutional Break ($D_{1973}, D_{2008}$)**: Trace = **33.72** > 25.32 (5% CV) $\to$ **Strong $r=1$ (Cointegrated)** with $\hat{\gamma} = 4.2208$.
   - **Chile Dictatorship Shock (1974--1989)**: Trace = **40.70** > 25.32 (5% CV), Bootstrap $p = 0.017 \to$ **$r=1$ (Cointegrated)**.
   - **Chile Nitrate Crisis (1920--1938)**: Trace = **33.37** > 25.32 (5% CV), Bootstrap $p = 0.037 \to$ **$r=1$ (Cointegrated)**.

## Source Artifacts
- Unit Root Matrix: `output/comprehensive_urca_unit_root_matrix.csv`
- Break-Informed VECM Ledger: `output/break_informed_johansen_vecm_ledger.csv`
