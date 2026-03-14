# CLAUDE.md — Project Context

## Overview

Critical replication of Shaikh's (2016) capacity utilization estimation for the US corporate sector. Uses ARDL and Johansen VECM cointegration methods to stress-test the original ARDL(2,4) specification across a broad specification lattice. UMass heterodox macroeconomics dissertation.

## Pipeline Architecture

| Script | Stage | Description |
|--------|-------|-------------|
| `10_config.R` | Config | Global CONFIG list: paths, column maps, sample windows, shock type, seed |
| `99_utils.R` | Utility | `safe_write_csv()`, `make_dummies()`, `now_stamp()` |
| `98_ardl_helpers.R` | Utility | Covariance sanitization, ICOMP computation, `make_spec_row()`, `extract_envelope()` |
| `99_figure_protocol.R` | Utility | Figure protocol: Tufte theme, colorblind-safe palette, dual PDF+PNG export, 20 builder functions |
| `20_S0_shaikh_faithful.R` | S0 | Faithful ARDL(2,4) replication across 5 PSS cases |
| `21_S1_ardl_geometry.R` | S1 | 500-spec ARDL lattice with F-bounds admissibility + frontier extraction |
| `22_S2_vecm_bivariate.R` | S2 | Johansen VECM bivariate (m=2), 48 specs, triple admissibility gate |
| `23_S2_vecm_trivariate.R` | S2 | Johansen VECM trivariate (m=3) + rotation check, 96 specs |
| `24_manifest_runner.R` | Runner | Pipeline orchestrator: S0 → S1 → S2(m=2) → S2(m=3) → Pack |
| `80_pack_ch3_replication.R` | Pack | Results packaging: 8 summary tables, 20 dual-format figures |

Auxiliary (not in main pipeline): `25_S0_deflator_grid_search.R`, `20_S0_shaikh_faithful_aux_manual_override_code.R`, `s0_manual_override_repdata.R`

## How to Run

```bash
# Full pipeline
Rscript codes/24_manifest_runner.R

# Individual stage
Rscript codes/20_S0_shaikh_faithful.R
```

**Shock toggle:** Edit `CONFIG$SHOCK_TYPE` in `codes/10_config.R`:
- `"permanent"` — step dummies (d(year >= break))
- `"transitory"` — impulse dummies (d(year == break))

Dummy years: 1956, 1974, 1980 (fixed).

## Variable Mapping (from `10_config.R`)

| CONFIG key | Column | Meaning |
|------------|--------|---------|
| `y_nom` | `VAcorp` | Nominal value added (corporate) |
| `k_nom` | `KGCcorp` | Nominal gross capital stock (corporate) |
| `p_index` | `pIGcorpbea` | BEA price deflator for investment goods |
| `u_shaikh` | `uK` | Shaikh's capacity utilization |
| `e_rate` | `exploit_rate` | Exploitation rate |
| `pi_share` | `Profshcorp` | Corporate profit share |

- **Sample window:** 1947–2011 (T=65)
- **Seed:** 123456

## Data Layout

```
data/raw/                              # Read-only source data
  Shaikh_canonical_series_v1.csv       # Primary dataset (31 cols, 1929–2011)
  ALFRED_GDPDEF_vintage2012.csv        # GDP deflator vintage (FRED/ALFRED)
  Shaikh_RepData.xlsx                  # Original replication workbook
  _Appendix6.8DataTablesCorrected.xlsx # Shaikh Appendix 6.8 tables
  ddbb_cu_US_kgr.xlsx                 # Extended CU database

output/CriticalReplication/
  S0_faithful/  csv/ figures/ logs/
  S1_geometry/  csv/ figures/ logs/
  S2_vecm/      csv/ figures/ logs/
  ResultsPack/  tables/ figures/
  Manifest/     logs/
```

## Coding Conventions

- All scripts source config + utilities via `here::here("codes/10_config.R")` etc.
- CSVs: use `safe_write_csv(df, path)` — auto-creates parent directories
- Figures: use the figure protocol in `99_figure_protocol.R` (dual PDF+PNG, 7x5 default)
- Spec rows: use `make_spec_row()` from `98_ardl_helpers.R` for consistent lattice structure
- Frontier: use `extract_envelope()` for Pareto frontier extraction
- Dummies: use `make_dummies(df, years, CONFIG$SHOCK_TYPE)` from `99_utils.R`

## R Dependencies

`here`, `readr`, `dplyr`, `tidyr`, `purrr`, `stringr`, `ARDL`, `tsDyn`, `urca`, `ggplot2`, `ggrepel`

## Git Notes

- `.gitignore` excludes: `output/**/*.rds`, `output/**/*.RData`, `output/Manifest/`
- CSV tables and PNG/PDF figures **are** version-controlled
- `data/raw/` is read-only — never modify source data
- Detailed handoff spec: `docs/ClaudeCode_Handoff_S0S1S2.md`
