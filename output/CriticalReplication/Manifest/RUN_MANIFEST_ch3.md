# RUN MANIFEST — Chapter 3 Critical Replication

## Run metadata
- Run ID: `ch3_20260311_183129`
- Timestamp: `2026-03-11T18:31:29-0300`
- Timezone: `America/Santiago`
- Git hash: `ea10042`
- Seed: `123456`
- Machine/OS: `sysname Windows; release 10 x64; version build 26200; nodename DIEGO-ASUS; machine x86-64; login User; user User; effective_user User; udomain DIEGO-ASUS`

## Input data and variable mapping
- Dataset path: `data/raw/Shaikh_RepData.xlsx`
- Sheet: `long`
- Window lock: `shaikh_window` (1947-2011)

## Script execution log
| Script | Description | Exists | Status | Exit | Reason | Log |
|---|---|---|---|---|---|---|
| `20_S0_shaikh_faithful.R` | S0: faithful ARDL(2,4) replication | yes | ok | 0 | OK | `output/CriticalReplication/Manifest/logs/20_S0_shaikh_faithful_run.log` |
| `21_S1_ardl_geometry.R` | S1: ARDL specification geometry (500-spec lattice) | yes | ok | 0 | OK | `output/CriticalReplication/Manifest/logs/21_S1_ardl_geometry_run.log` |
| `22_S2_vecm_bivariate.R` | S2 m=2: bivariate VECM system identification | yes | ok | 0 | OK | `output/CriticalReplication/Manifest/logs/22_S2_vecm_bivariate_run.log` |
| `23_S2_vecm_trivariate.R` | S2 m=3: trivariate VECM + rotation check | yes | ok | 0 | OK | `output/CriticalReplication/Manifest/logs/23_S2_vecm_trivariate_run.log` |
| `80_pack_ch3_replication.R` | Results packaging: strict consumer of S0/S1/S2 public CSVs | yes | ok | 0 | OK | `output/CriticalReplication/Manifest/logs/80_pack_ch3_replication_run.log` |

## Output artifact index
- `output/CriticalReplication/Manifest/logs/20_S0_shaikh_faithful_run.log`
- `output/CriticalReplication/Manifest/logs/21_S1_ardl_geometry_run.log`
- `output/CriticalReplication/Manifest/logs/22_S2_vecm_bivariate_run.log`
- `output/CriticalReplication/Manifest/logs/23_S2_vecm_trivariate_run.log`
- `output/CriticalReplication/Manifest/logs/80_pack_ch3_replication_run.log`
- `output/CriticalReplication/Manifest/logs/SESSIONINFO_ch3.txt`
- `output/CriticalReplication/ResultsPack/figures/fig_S0_utilization_replication.pdf`
- `output/CriticalReplication/ResultsPack/INDEX_RESULTS_PACK.md`
- `output/CriticalReplication/ResultsPack/tables/TAB_S0_bounds_report.csv`
- `output/CriticalReplication/ResultsPack/tables/TAB_S0_fivecase.csv`
- `output/CriticalReplication/ResultsPack/tables/TAB_S1_frontier_summary.csv`
- `output/CriticalReplication/ResultsPack/tables/TAB_S2_admissibility_summary.csv`
- `output/CriticalReplication/ResultsPack/tables/TAB_S2_rotation_check.csv`
- `output/CriticalReplication/S0_faithful/csv/S0_fivecase_summary.csv`
- `output/CriticalReplication/S0_faithful/csv/S0_spec_report.csv`
- `output/CriticalReplication/S0_faithful/csv/S0_utilization_series.csv`
- `output/CriticalReplication/S0_faithful/figures/FIG_S1_ARDL_u_compare_cases_Fpass_shaikh_window.png`
- `output/CriticalReplication/S0_faithful/logs/SHAIKH_ARDL_replication_log_shaikh_window.txt`
- `output/CriticalReplication/S1_geometry/csv/S1_admissible.csv`
- `output/CriticalReplication/S1_geometry/csv/S1_frontier_F020.csv`
- `output/CriticalReplication/S1_geometry/csv/S1_frontier_theta.csv`
- `output/CriticalReplication/S1_geometry/csv/S1_frontier_u_band.csv`
- `output/CriticalReplication/S1_geometry/csv/S1_lattice_full.csv`
- `output/CriticalReplication/S1_geometry/figures/fig_S1_global_frontier.png`
- `output/CriticalReplication/S1_geometry/figures/fig_S1_ic_tangencies.png`
- `output/CriticalReplication/S1_geometry/figures/fig_S1_informational_domain.png`
- `output/CriticalReplication/S1_geometry/logs/S1_ardl_geometry_log.txt`
- `output/CriticalReplication/S2_vecm/csv/S2_m2_admissible.csv`
- `output/CriticalReplication/S2_vecm/csv/S2_m2_lattice_full.csv`
- `output/CriticalReplication/S2_vecm/csv/S2_m2_omega20.csv`
- `output/CriticalReplication/S2_vecm/csv/S2_m2_u_band.csv`
- `output/CriticalReplication/S2_vecm/csv/S2_m3_admissible.csv`
- `output/CriticalReplication/S2_vecm/csv/S2_m3_lattice_full.csv`
- `output/CriticalReplication/S2_vecm/csv/S2_m3_omega20.csv`
- `output/CriticalReplication/S2_vecm/csv/S2_m3_u_band.csv`
- `output/CriticalReplication/S2_vecm/csv/S2_rotation_check.csv`
- `output/CriticalReplication/S2_vecm/figures/fig_S2_global_frontier_m2.pdf`
- `output/CriticalReplication/S2_vecm/figures/fig_S2_global_frontier_m3.pdf`
- `output/CriticalReplication/S2_vecm/figures/fig_S2_ic_tangencies_m2.pdf`
- `output/CriticalReplication/S2_vecm/figures/fig_S2_ic_tangencies_m3.pdf`
- `output/CriticalReplication/S2_vecm/figures/fig_S2_informational_domain_m2.pdf`
- `output/CriticalReplication/S2_vecm/figures/fig_S2_informational_domain_m3.pdf`
- `output/CriticalReplication/S2_vecm/logs/S2_vecm_bivariate_log.txt`
- `output/CriticalReplication/S2_vecm/logs/S2_vecm_trivariate_log.txt`

## Session snapshot
- `sessionInfo()` → `output/CriticalReplication/Manifest/logs/SESSIONINFO_ch3.txt`

## Deviations / notes
- None.
