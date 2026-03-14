# Capacity Utilization: US Critical Replication (Shaikh 2016)

**UMass Heterodox Macroeconomics | Dissertation Chapter 3**

Critical replication and informational robustness analysis of Shaikh's (2016)
capacity utilization estimation via ARDL and VECM cointegration methods.
The pipeline replicates the ARDL(2,4) specification from Table 6.7.14 of
*Capitalism: Competition, Conflict, Crises* and then stress-tests the result
across a 500-specification ARDL lattice and a 144-specification Johansen VECM
system identification exercise.

---

## Repository Structure

```
Capacity-Utilization-US_Chile/
├── capacity_utilization.Rproj       # RStudio project anchor (here::here() root)
├── .gitignore                       # Excludes .rds/.RData, LaTeX build, OS files
├── .gitattributes
│
├── codes/                           # All R source code
│   ├── 10_config.R                  # Global configuration (paths, column maps, windows)
│   ├── 99_utils.R                   # Shared utilities (I/O, logging, make_dummies)
│   ├── 98_ardl_helpers.R            # ARDL/VECM helpers (ICOMP, envelope, spec rows)
│   ├── 99_figure_protocol.R         # Unified figure protocol (theme, palettes, builders)
│   │
│   ├── 20_S0_shaikh_faithful.R      # S0: Faithful ARDL(2,4) replication (5-case sweep)
│   ├── 21_S1_ardl_geometry.R        # S1: ARDL specification geometry (500-spec lattice)
│   ├── 22_S2_vecm_bivariate.R       # S2: Johansen VECM bivariate (m=2, 48 specs)
│   ├── 23_S2_vecm_trivariate.R      # S2: Johansen VECM trivariate (m=3, 96 specs)
│   ├── 24_manifest_runner.R         # Pipeline orchestrator + manifest writer
│   ├── 80_pack_ch3_replication.R    # Results packaging (8 tables, 20 figures)
│   │
│   ├── 25_S0_deflator_grid_search.R # Auxiliary: deflator/Y-series grid search
│   ├── 20_S0_shaikh_faithful_aux_manual_override_code.R
│   │                                # Auxiliary: manual override ARDL spec testing
│   └── s0_manual_override_repdata.R # Auxiliary: RepData deflator candidate testing
│
├── data/
│   ├── raw/                         # Source data (read-only inputs)
│   │   ├── Shaikh_canonical_series_v1.csv   # Primary dataset (31 columns, 1929–2011)
│   │   ├── Shaikh_RepData.xlsx              # Original Shaikh replication workbook
│   │   ├── _Appendix6.8DataTablesCorrected.xlsx  # Shaikh Appendix 6.8 data tables
│   │   ├── Shaikh_exploitation_rate_faithful_v1.csv  # Exploitation rate construction
│   │   ├── ALFRED_GDPDEF_vintage2012.csv    # GDP deflator vintage (FRED/ALFRED)
│   │   └── ddbb_cu_US_kgr.xlsx             # Extended capacity utilization database
│   └── processed/
│       └── ddbb_cu_US_kgr.xlsx              # Processed version of CU database
│
├── docs/
│   └── ClaudeCode_Handoff_S0S1S2.md # Architectural handoff specification (v2)
│
└── output/CriticalReplication/      # All pipeline outputs
    ├── Manifest/                    # Pipeline execution records
    │   ├── RUN_MANIFEST_ch3.md      # Human-readable manifest
    │   ├── RUN_MANIFEST_ch3.csv     # Machine-readable manifest
    │   └── logs/                    # Per-script stdout/stderr capture
    │       ├── 20_S0_shaikh_faithful_run.log
    │       ├── 21_S1_ardl_geometry_run.log
    │       ├── 22_S2_vecm_bivariate_run.log
    │       ├── 23_S2_vecm_trivariate_run.log
    │       ├── 80_pack_ch3_replication_run.log
    │       └── SESSIONINFO_ch3.txt
    │
    ├── S0_faithful/                 # Stage 0 outputs
    │   ├── csv/
    │   │   ├── S0_spec_report.csv           # 5-case bounds test results
    │   │   ├── S0_fivecase_summary.csv      # LR coefficient table (all cases)
    │   │   ├── S0_utilization_series.csv    # u_hat + yp_hat annual series
    │   │   └── S0_grid_results.csv          # Deflator grid search results
    │   ├── figures/
    │   │   ├── FIG_S0_ARDL_u_compare_cases_Fpass_shaikh_window.png
    │   │   └── FIG_S1_ARDL_u_compare_cases_Fpass_shaikh_window.png
    │   ├── logs/
    │   │   ├── SHAIKH_ARDL_replication_log_shaikh_window.txt
    │   │   └── grid_search_log.txt
    │   └── S0_agent_report.md
    │
    ├── S1_geometry/                 # Stage 1 outputs
    │   ├── csv/
    │   │   ├── S1_lattice_full.csv          # Full 500-spec lattice
    │   │   ├── S1_admissible.csv            # F-bounds admissible subset
    │   │   ├── S1_frontier_F020.csv         # Bottom-20% AIC frontier
    │   │   ├── S1_frontier_theta.csv        # Theta distribution on frontier
    │   │   └── S1_frontier_u_band.csv       # Utilization band on frontier
    │   ├── figures/
    │   │   ├── fig_S1_global_frontier.png
    │   │   ├── fig_S1_ic_tangencies.png
    │   │   └── fig_S1_informational_domain.png
    │   └── logs/
    │       └── S1_ardl_geometry_log.txt
    │
    ├── S2_vecm/                     # Stage 2 outputs (bivariate + trivariate)
    │   ├── csv/
    │   │   ├── S2_m2_lattice_full.csv       # Full m=2 lattice (48 specs)
    │   │   ├── S2_m2_admissible.csv         # Triple-gate admissible (m=2)
    │   │   ├── S2_m2_omega20.csv            # Bottom-20% neg2logL frontier (m=2)
    │   │   ├── S2_m2_u_band.csv             # Utilization band (m=2)
    │   │   ├── S2_m3_lattice_full.csv       # Full m=3 lattice (96 specs)
    │   │   ├── S2_m3_admissible.csv         # Triple-gate admissible (m=3)
    │   │   ├── S2_m3_omega20.csv            # Bottom-20% neg2logL frontier (m=3)
    │   │   ├── S2_m3_u_band.csv             # Utilization band (m=3)
    │   │   └── S2_rotation_check.csv        # P8 rotation diagnostic (r=2)
    │   ├── figures/
    │   │   ├── fig_S2_global_frontier_m2.pdf
    │   │   ├── fig_S2_global_frontier_m3.pdf
    │   │   ├── fig_S2_ic_tangencies_m2.pdf
    │   │   ├── fig_S2_ic_tangencies_m3.pdf
    │   │   ├── fig_S2_informational_domain_m2.pdf
    │   │   └── fig_S2_informational_domain_m3.pdf
    │   └── logs/
    │       ├── S2_vecm_bivariate_log.txt
    │       └── S2_vecm_trivariate_log.txt
    │
    └── ResultsPack/                 # Paper-facing summary package
        ├── INDEX_RESULTS_PACK.md
        ├── tables/                  # 8 summary CSV tables
        │   ├── TAB_S0_bounds_report.csv
        │   ├── TAB_S0_fivecase.csv
        │   ├── TAB_S1_frontier_summary.csv
        │   ├── TAB_S1_ic_winners.csv
        │   ├── TAB_S2_admissibility_summary.csv
        │   ├── TAB_S2_ic_winners.csv
        │   ├── TAB_S2_rotation_check.csv
        │   └── TAB_CROSS_theta_comparison.csv
        └── figures/                 # 20 dual-format figures (PDF + PNG)
            ├── fig_S0_utilization_replication.*
            ├── fig_S0_capacity_benchmark.*
            ├── fig_S0_fivecase_comparison.*
            ├── fig_S0_fitcomplexity_seed.*
            ├── fig_S1_global_frontier.*
            ├── fig_S1_ic_tangencies.*
            ├── fig_S1_informational_domain.*
            ├── fig_S1_theta_distribution.*
            ├── fig_S1_utilization_band.*
            ├── fig_S1_sK_distribution.*
            ├── fig_S2_global_frontier_m2.*
            ├── fig_S2_global_frontier_m3.*
            ├── fig_S2_ic_tangencies_m2.*
            ├── fig_S2_ic_tangencies_m3.*
            ├── fig_S2_informational_domain_m2.*
            ├── fig_S2_informational_domain_m3.*
            ├── fig_S2_theta_distribution.*
            ├── fig_S2_utilization_band.*
            ├── fig_S2_alpha_heatmap.*
            └── fig_CROSS_synthesis.*
```

---

## File Descriptions

### Configuration and Utilities (`codes/`)

| File | Lines | Description |
|------|------:|-------------|
| `10_config.R` | 87 | Central configuration: data paths, column name mapping (`VAcorp`, `KGCcorp`, `pIGcorpbea`, `uK`, `exploit_rate`), sample windows (`shaikh_window = 1947–2011`), output directory map, shock type toggle (`SHOCK_TYPE`: `"permanent"` or `"transitory"`), and reproducibility seed. |
| `99_utils.R` | 33 | Shared utilities sourced by all scripts: `safe_write_csv()` (directory-creating CSV writer), `now_stamp()` (timestamp formatter), and `make_dummies(df, years, type)` (unified dummy builder supporting permanent step dummies or transitory impulse dummies). |
| `98_ardl_helpers.R` | 435 | ARDL/VECM computational helpers: covariance sanitization and ridge stabilization, numerically stable log-determinant via Cholesky, C1/ICOMP/ICOMP_Misspec computation (Bozdogan 1990, 2016), canonical spec-row builder `make_spec_row()`, Pareto frontier extraction `extract_envelope()`, and fit-complexity plane plot functions for S1/S2. |
| `99_figure_protocol.R` | 854 | Paper-facing figure protocol sourced exclusively by the pack script: Tufte-inspired `theme_ch3()`, colorblind-safe Okabe-Ito palette, `save_ch3_fig()` (dual PDF+PNG export), and 20 builder functions (`build_fig_S0_*`, `build_fig_S1_*`, `build_fig_S2_*`, `build_fig_cross_*`). |

### Pipeline Scripts (`codes/`)

| File | Lines | Description |
|------|------:|-------------|
| `20_S0_shaikh_faithful.R` | 578 | **Stage 0**: Faithful replication of Shaikh's ARDL(2,4) specification across all 5 PSS cases. Loads the canonical CSV, rebases the price deflator to 2005=100, constructs real log output and capital, applies step or impulse dummies at 1956/1974/1980, estimates ARDL models via the `ARDL` package, computes F-bounds and t-bounds tests, extracts LR multipliers with delta-method standard errors, and recovers the capacity utilization series. Produces 3 public CSVs and a verification block comparing against Shaikh Table 6.7.14. |
| `21_S1_ardl_geometry.R` | 517 | **Stage 1**: Full ARDL specification geometry. Sweeps a grid of p=1:5, q=1:5, case=1:5, s={s0,s1,s2,s3} = 500 specifications. For each, estimates the ARDL model, runs bounds tests, computes 5 information criteria (AIC, BIC, HQ, ICOMP, ICOMP_Misspec), extracts LR multipliers and u_hat. Applies F-bounds admissibility gate (alpha=0.10), constructs the F^(0.20) fattened frontier (bottom 20% AIC), identifies IC winners, and exports the full lattice, admissible set, frontier, theta distribution, and utilization band. |
| `22_S2_vecm_bivariate.R` | 474 | **Stage 2 (m=2)**: Johansen VECM bivariate system identification. State vector X_t = (lnY, lnK)'. Sweeps p=1:4, d={d0,d1,d2,d3}, h={h0,h1,h2} = 48 specifications with cointegration rank r=1. Triple admissibility gate: (1) convergence, (2) Johansen trace rank consistency at 5%, (3) companion-matrix stability. Constructs Omega_20 frontier (bottom 20% neg2logL). |
| `23_S2_vecm_trivariate.R` | 581 | **Stage 2 (m=3)**: Johansen VECM trivariate system with exploitation rate. State vector X_t = (lnY, lnK, e)'. Sweeps p=1:4, d={d0,d1,d2,d3}, h={h0,h1,h2}, r={1,2} = 96 specifications. Same triple admissibility gate. Includes P8 rotation diagnostic for r=2 specs: regresses e on u_hat to test reserve-army sign prior (lambda < 0). |
| `24_manifest_runner.R` | 309 | Pipeline orchestrator. Runs all 5 scripts sequentially via `Rscript` subprocess calls, captures exit codes and stdout, validates public artifact contracts, and writes the run manifest (both Markdown and CSV). Sole manifest writer in the pipeline. |
| `80_pack_ch3_replication.R` | 391 | Results packaging. Strict consumer of S0/S1/S2 public CSV outputs — CONTRACT ERROR on any missing input. Produces 8 summary tables and 20 dual-format (PDF+PNG) figures for the paper. Uses the figure protocol from `99_figure_protocol.R`. |

### Auxiliary Scripts (`codes/`)

| File | Lines | Description |
|------|------:|-------------|
| `25_S0_deflator_grid_search.R` | 634 | Overnight grid search testing 7 candidate Y-series and deflator combinations to identify which reproduces Shaikh's published ARDL(2,4) coefficients. Not part of the main pipeline. |
| `20_S0_shaikh_faithful_aux_manual_override_code.R` | 353 | Manual override testing of specific deflator candidates with full delta-method LR dummy multipliers. |
| `s0_manual_override_repdata.R` | 409 | RepData deflator candidate testing (4 candidates: A/B/C/D) against Shaikh Table 6.7.14 targets. |

### Data (`data/`)

| File | Size | Description |
|------|-----:|-------------|
| `raw/Shaikh_canonical_series_v1.csv` | 29 KB | Primary dataset: 31 columns covering US corporate sector variables 1929–2011. Key columns: `year`, `VAcorp` (nominal output), `KGCcorp` (nominal capital), `pIGcorpbea` (price deflator), `uK` (Shaikh's capacity utilization), `exploit_rate`, `Profshcorp` (profit share). |
| `raw/Shaikh_RepData.xlsx` | 22 KB | Original Shaikh replication workbook. |
| `raw/_Appendix6.8DataTablesCorrected.xlsx` | 690 KB | Shaikh Appendix 6.8 data tables with corrections. |
| `raw/Shaikh_exploitation_rate_faithful_v1.csv` | 11 KB | Exploitation rate construction audit trail. |
| `raw/ALFRED_GDPDEF_vintage2012.csv` | 3 KB | GDP deflator vintage from FRED/ALFRED (2012 vintage). |
| `raw/ddbb_cu_US_kgr.xlsx` | 26 KB | Extended capacity utilization database. |
| `processed/ddbb_cu_US_kgr.xlsx` | 26 KB | Processed version of CU database. |

---

## Running the Pipeline

**Prerequisites:** R >= 4.3 with packages: `here`, `readr`, `dplyr`, `tidyr`, `purrr`, `stringr`, `ARDL`, `tsDyn`, `urca`, `ggplot2`, `ggrepel`.

```bash
cd Capacity-Utilization-US_Chile/
Rscript codes/24_manifest_runner.R
```

This runs S0 → S1 → S2(m=2) → S2(m=3) → Pack in sequence. The manifest at
`output/CriticalReplication/Manifest/RUN_MANIFEST_ch3.md` records status for
each stage.

### Shock Type Toggle

Edit `codes/10_config.R` and set `SHOCK_TYPE`:

```r
SHOCK_TYPE = "permanent",    # step dummies: d(year >= break)
SHOCK_TYPE = "transitory",   # impulse dummies: d(year == break)
```

Then re-run the pipeline. The dummy years (1956, 1974, 1980) remain fixed;
only their functional form changes.

---

## Key References

- Shaikh, A. (2016). *Capitalism: Competition, Conflict, Crises*. Oxford University Press. Table 6.7.14.
- Pesaran, Shin & Smith (2001). Bounds testing approaches to the analysis of level relationships. *JASA*, 16(3).
- Bozdogan, H. (1990). On the information-based measure of covariance complexity (ICOMP). *Computational Statistics & Data Analysis*, 9(2).
- Johansen, S. (1991). Estimation and hypothesis testing of cointegration vectors. *Econometrica*, 59(6).
