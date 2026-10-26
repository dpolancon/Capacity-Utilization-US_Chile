---
type: session_handoff
status: active
source_repo: Capacity-Utilization-US_Chile
target_repo: Chapter3_RPEUP
date: 2026-08-15
session_id: 8ba10658-ecd5-49f7-a13e-fe56b552f2e0
tags:
  - handoff
  - chile
  - wbop
  - monetary_history
  - solvency_leverage
  - balance_of_payments
---

# Session Handoff: Chapter 2 to Chapter 3 Transmission
**Date:** August 15, 2026  
**From:** `C:\ReposGitHub\Capacity-Utilization-US_Chile`  
**To:** `C:\ReposGitHub\Chapter3_RPEUP`

---

## 1. Executive Summary & Context Transmission

In this session, we resolved the balance-of-payments regime identification bottleneck by moving from smoothed log-differences to the **raw mechanization import capacity ratio** ($R_t = M^{\text{manuf}} / X^{\text{tot}}$) using the Nievas & Piketty (2025) World Historical Balance of Payments (WBOP) database. We systematically extracted all 26 WBOP accounts for Chile (`CL`), constructed a comprehensive suite of structural balance-of-payments vulnerability indices, produced an expanded 14-page LaTeX compilation monograph, built a master Source-of-Truth dataset (1860–2024 / 1920–2024), and transferred all data and code assets to `Chapter3_RPEUP`.

---

## 2. Transferred Assets in `Chapter3_RPEUP`

```
C:\ReposGitHub\Chapter3_RPEUP\
├── codes\
│   ├── CL_S10_wbop_source_of_truth_panel.R         ← Canonical WBOP staging script
│   ├── CL_S90_solv_lev_ratio_plots.R               ← Central Bank Solvency/Leverage (M0, M1, M2) (1926–2010)
│   ├── CL_S90_wbop_event_robustness.R              ← Crisis event-study and robustness analysis
│   ├── CL_S91_wbop_structural_ratio_plots.R        ← WBOP structural ratio suite (1920–2024)
│   └── CL_S92_build_monetary_wbop_master_dataset.R ← Master CSV dataset generator
├── data\
│   ├── money_data_set\
│   │   ├── chile_monetary_wbop_compilation_master.csv ← Master Source-of-Truth (1860–2024, 165×46)
│   │   └── chile_monetary_wbop_1920_2024.csv          ← Core Estimation Window (1920–2024, 105×46)
│   └── wbop\
│       ├── NievasPiketty2025WBOPFinalSeries.xlsx       ← Master WBOP Excel database (26 accounts)
│       └── WBOP_DATA_WP2025_1800-2025.pdf             ← WBOP documentation working paper
└── output\CHILE_solv_lev_ratio_plots\
    ├── chile_solv_lev_plots_compilation.tex           ← Master 14-page LaTeX compilation monograph
    ├── chile_solv_lev_plots_compilation.pdf           ← Compiled publication-grade report
    ├── chile_monetary_wbop_compilation_master.csv     ← Output synchronization copy
    └── fig_*.pdf / fig_*.png                          ← All 14 high-res vector and raster figures
```

---

## 3. Master Dataset Variable Architecture (`chile_monetary_wbop_compilation_master.csv`)

| Variable Category | Column Name in CSV | Definition & Unit | Source / Provenance |
|---|---|---|---|
| **Time Index** | `year` | Annual observations (1860–2024) | Primary index |
| **Exchange Rate** | `e_t` | Nominal exchange rate (CLP per USD) | ClioLab W04 (Sheet 4.2.1) |
| **International Reserves** | `IR_usd` | Gross International Reserves (Nominal USD) | ClioLab W05 (Sheet 5.3) |
| **Reserves in Domestic Currency** | `Reserves_clp` | $F_t = e_t \times IR^{\text{USD}}_t$ (Nominal CLP) | Calculated |
| **Monetary Aggregates** | `M0_clp`, `M1_clp`, `M2_clp` | Currency in circulation, narrow money, broad money (Nominal CLP) | ClioLab W06 (Sheets 6.1.2 & 6.1.3) |
| **Central Bank Solvency Ratios** | `SolvR_M0`, `SolvR_M1`, `SolvR_M2` | $\text{SolvR} = F_t / M_i$ (Reserve backing ratio) | ClioLab / Calculated |
| **Central Bank Leverage Ratios** | `LevR_M0`, `LevR_M1`, `LevR_M2` | $\text{LevR} = M_i / F_t$ (Domestic monetary leverage) | ClioLab / Calculated |
| **WBOP Output** | `wbop_gdp_usd_mer` | Gross Domestic Product (Million USD, MER) | WBOP Sheet A1 |
| **Merchandise Trade (% GDP)** | `wbop_tb_goods_gdp`, `wbop_x_goods_gdp`, `wbop_m_goods_gdp` | Net balance, exports, imports of goods | WBOP Sheets B1a, B1b, B1c |
| **Primary Commodities (% GDP)** | `wbop_tb_prim_gdp`, `wbop_x_prim_gdp`, `wbop_m_prim_gdp` | Net balance, exports, imports of primary goods | WBOP Sheets B2a, B2b, B2c |
| **Manufactured Goods (% GDP)** | `wbop_tb_manuf_gdp`, `wbop_x_manuf_gdp`, `wbop_m_manuf_gdp` | Net balance, exports, imports of manufactures | WBOP Sheets B3a, B3b, B3c |
| **Services Trade (% GDP)** | `wbop_tb_serv_gdp`, `wbop_x_serv_gdp`, `wbop_m_serv_gdp` | Net balance, exports, imports of services | WBOP Sheets C1a, C1b, C1c |
| **Total Goods + Services (% GDP)** | `wbop_tb_tot_gdp`, `wbop_x_tot_gdp`, `wbop_m_tot_gdp` | Comprehensive external trade balance | WBOP Sheets C1d, C1e, C1f |
| **Primary Income / Surplus Drainage** | `wbop_net_inc_gdp`, `wbop_inc_inflow_gdp`, `wbop_inc_outflow_gdp` | Foreign debt interest + repatriated profits (% GDP) | WBOP Sheets D1a, D1b, D1c |
| **Current Account (% GDP)** | `wbop_current_account_gdp` | Net current account balance | WBOP Sheet F1 |
| **External Balance Sheet (% GDP)** | `wbop_niip_gdp`, `wbop_nfa_assets_gdp`, `wbop_nfa_liab_gdp` | Net International Investment Position, Gross Assets, Gross Liabilities | WBOP Sheets G1a, G1b, G1c |
| **Analytical Indicator 1** | `R_manuf_exp` | $R_t = M^{\text{manuf}} / X^{\text{tot}}$ (Mechanization Import Burden) | WBOP B3c / C1e |
| **Analytical Indicator 2** | `R_prebisch_singer` | $R_t^{\text{PS}} = M^{\text{manuf}} / X^{\text{prim}}$ (Prebisch-Singer Bottleneck) | WBOP B3c / B2b |
| **Analytical Indicator 3** | `share_prim_exp_pct` | $S_t^{\text{prim}} = (X^{\text{prim}} / X^{\text{goods}}) \times 100$ (Extractivism Share) | WBOP B2b / B1b |
| **Analytical Indicator 4** | `drainage_exp_pct` | $D_t^{\text{drain}} = (\text{Income Outflow} / X^{\text{tot}}) \times 100$ (Surplus Drainage %) | WBOP D1c / C1e |
| **Analytical Indicator 5** | `ext_leverage_ratio` | $L_t^{\text{ext}} = \text{Gross Liabilities} / \text{Gross Assets}$ (National Leverage) | WBOP G1c / G1b |
| **Analytical Indicator 6** | `liab_to_exp_ratio` | $\text{Liabilities} / X^{\text{tot}}$ (External Debt/Liability Burden on Exports) | WBOP G1c / C1e |

---

## 4. Analytical Bridge: Chapter 2 vs. Chapter 3

1. **In Chapter 2 (`Capacity-Utilization-US_Chile`)**:
   - The focus is the **structural transformation elasticity** $\theta(e_t, \omega_t, \kappa_t)$ and capacity utilization $\mu_t$.
   - $R_t = M^{\text{manuf}} / X^{\text{tot}}$ is used as the **exogenous switching threshold** in the 3-Regime CMPR IM-OLS grid search to capture sudden stops (1975, 1982, 1998, 2008) without distorting the I(1) cointegration vector.
2. **In Chapter 3 (`Chapter3_RPEUP`)**:
   - The focus is the **peripheral monetary and financial subordination regime** of Chilean capitalism.
   - The Central Bank solvency ratios ($\text{SolvR}_{M0}, \text{SolvR}_{M1}, \text{SolvR}_{M2}$) and leverage ratios are analyzed alongside surplus drainage ($D_t^{\text{drain}}$), unequal exchange ($R_t^{\text{PS}}$), and external balance-sheet fragility ($L_t^{\text{ext}}$) to explain the institutional evolution from 1926 Kemmerer orthodoxy to 1942 CORFO directed credit and post-1989 neoliberal financialization.

---

## 5. Immediate Next Steps in `Chapter3_RPEUP`

When you switch your active workspace to `C:\ReposGitHub\Chapter3_RPEUP`:
1. **Threshold & TVAR Models**: Run [`codes/01_route_C_threshold_regression.R`](file:///C:/ReposGitHub/Chapter3_RPEUP/codes/01_route_C_threshold_regression.R) and [`codes/02_route_B_var_tvar.R`](file:///C:/ReposGitHub/Chapter3_RPEUP/codes/02_route_B_var_tvar.R) utilizing the new `chile_monetary_wbop_compilation_master.csv` dataset.
2. **Monetary History Chapter Text**: Integrate the 14-figure compilation monograph [`output/CHILE_solv_lev_ratio_plots/chile_solv_lev_plots_compilation.pdf`](file:///C:/ReposGitHub/Chapter3_RPEUP/output/CHILE_solv_lev_ratio_plots/chile_solv_lev_plots_compilation.pdf) directly into Chapter 3's empirical narrative sections.
3. **Monthly BOP Calibration**: Update [`codes/06_monthly_bop_analysis.R`](file:///C:/ReposGitHub/Chapter3_RPEUP/codes/06_monthly_bop_analysis.R) to link modern monthly foreign-exchange reserves with historical annual WBOP regimes.
