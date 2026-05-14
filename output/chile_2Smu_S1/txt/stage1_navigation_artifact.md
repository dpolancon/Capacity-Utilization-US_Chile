# Stage 1 navigation artifact

## Purpose

This note is the navigation layer for the Stage 1 external-disequilibrium results package. It assumes the output root:

`outputs/chile_2Smu_S1/`

The working interpretation locked in the session is:

- Stage 1 only
- ECT = external disequilibrium, not utilization
- working lead object: `PRE1974 × S1_B × lag1 × rank1`

## Spec registry

- `S1_A`: `log_M ~ log_KME`
- `S1_B`: `log_M ~ log_KME + log_NRS_proxy`
- `S1_C`: `log_M ~ log_KME + omega`
- `S1_D`: `log_M ~ log_KME + log_NRS_proxy + omega`

## Sample registry

- `FULL`
- `PRE1974`
- `POST1974`

## CSV inventory

| object | rows | cols |
|---|---:|---:|
| `alpha` | 72 | 6 |
| `beta` | 72 | 6 |
| `ect_series` | 1536 | 6 |
| `ect_summary` | 24 | 11 |
| `jb` | 12 | 4 |
| `lm` | 12 | 5 |
| `rank` | 144 | 10 |
| `unitroot_battery` | 72 | 8 |
| `vif` | 24 | 4 |
| `white` | 12 | 4 |

## File map

### Core interpretation layer
- `stage1__ect_series.csv`
- `stage1__ect_summary.csv`
- `stage1__alpha.csv`
- `stage1__beta.csv`

### Diagnostic layer
- `stage1__unitroot_battery.csv`
- `stage1__vif.csv`
- `stage1__white.csv`
- `stage1__lm.csv`
- `stage1__jb.csv`
- `stage1__rank.csv`

## Recommended reading order

1. `stage1__ect_summary.csv`
2. `stage1__alpha.csv`
3. `stage1__beta.csv`
4. `stage1__ect_series.csv`
5. `stage1__rank.csv`
6. remaining diagnostics

## Build the master RDS

This environment could not serialize an actual `.rds`, so the builder script is provided.

Run in R from the repo root:

```r
source(here::here("codes", "build_stage1_master_rds.R"))
```

Or paste the script contents from:

`build_stage1_master_rds.R`

The script reads all Stage 1 CSV outputs and writes:

`outputs/chile_2Smu_S1/txt/stage1__master_results.rds`

## Expected object structure inside the RDS

- `alpha`
- `beta`
- `ect_series`
- `ect_summary`
- `jb`
- `lm`
- `rank`
- `unitroot_battery`
- `vif`
- `white`
- `meta`

## Minimal load snippet

```r
x <- readRDS(here::here("outputs", "chile_2Smu_S1", "txt", "stage1__master_results.rds"))
names(x)
x$meta
```
