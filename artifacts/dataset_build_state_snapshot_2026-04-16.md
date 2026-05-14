# Dataset Build State Snapshot (2026-04-16)

## Scope
Current operational state of the dataset-build process in this repo, based on existing files and manifests.  
This is a status artifact only; no estimation was launched in this pass.

## 1) Current core datasets on disk

| Dataset | Path | Rows | Year coverage | Status |
|---|---|---:|---:|---|
| Chile panel (assembly layer) | `data/processed/Chile/ch2_panel_chile.csv` | 165 | 1860–2024 | present |
| Chile Stage A output panel | `data/processed/Chile/stage2_theta_mu.csv` | 105 | 1920–2024 | present |
| Chile Stage B 4-channel panel | `output/stage_b/Chile/csv/stageB_CL_panel_1940_1978_4ch.csv` | 39 | 1940–1978 | present |
| US Stage C panel | `data/processed/US/us_nf_corporate_stageC.csv` | 96 | 1929–2024 | present |

## 2) Process state by stage

### Stage A (Chile)
- Results package exists: `output/stage_a/Chile/stage_a_results_manifest.md` (generated 2026-04-08).
- Integration outputs exist:  
  - `output/stage_a/Chile/csv/integration_tests.csv`  
  - `output/stage_a/Chile/csv/stage2_ur_crosswalk.csv`
- Stage-gate signal is not fully clean in the saved outputs:
  - `integration_tests.csv` flags `k_NR` and `k_ME` as `CHECK`.
  - `stage2_ur_crosswalk.csv` flags `k_ME` and `phi` as `I(2) — investigate`.

### Stage B (Chile)
- 4-channel decomposition outputs are present in `output/stage_b/Chile/` (csv + figs + tables).
- Core profitability/decomposition panel exists and is usable for downstream mapping checks.

### Stage C (US)
- Stage C datasets and reports exist in `data/processed/US/` and `output/stage_c/us/`.
- US side appears materially populated; no new Stage C run was executed in this pass.

## 3) Immediate integrity and workflow notes

- `codes/stage_a/chile/20_integration_tests.R` is currently not present in working tree.
- Stage A integration result files are present, but rerun reproducibility of the gate script is currently blocked until that script path is restored or replaced.
- `output/stage_a/US/cointreg_results/` does not exist; US outputs are under `output/stage_a/US/vecm_results/`.

## 4) Downstream variable mapping availability check

Requested downstream names:
- `d_r_chl`
- `phi_mu_chl`
- `g_k_chl_proxy`
- `g_y_chl_proxy`

Literal-name search result across `data/`, `output/`, `codes/`, `docs/`:
- no exact matches found for the four requested names.

Closest currently available columns:
- Profit-rate growth proxy candidate:
  - `dlnr` in `output/stage_b/Chile/csv/stageB_CL_panel_1940_1978_4ch.csv`
- Endogenous profit-rate component candidate:
  - `phi_mu` in `output/stage_b/Chile/csv/stageB_CL_panel_1940_1978_4ch.csv`
- Accumulation-rate proxy candidates:
  - `g_K_CL` in `output/stage_a/Chile/csv/stage2_panel_with_mu_v2.csv`
  - `g_kNR` in `data/processed/Chile/stage2_theta_mu.csv`
- Growth-rate proxy candidate:
  - `g_Y` in `data/processed/Chile/stage2_theta_mu.csv` and `output/stage_a/Chile/csv/stage2_panel_with_mu_v2.csv`

## 5) Ready / blocked assessment (current)

- **Ready now:** dataset-state documentation, mapping design, and non-estimation preprocessing decisions.
- **Blocked / unresolved for clean estimation launch:** unresolved Stage A integration diagnostics (`k_ME`, `phi`) and missing in-tree gate script path for direct rerun of `20_integration_tests.R`.
- **Mapping decision pending:** explicit canonical renaming/alias layer for the four downstream target names.

## 6) Minimal next actions

1. Re-establish the Stage A Chile integration gate runner in-tree (`20_integration_tests.R` or approved replacement).
2. Resolve or formally accept the `k_ME` / `phi` integration diagnostics with explicit method note.
3. Add a deterministic mapping file (or transform script) that binds:
   - `d_r_chl <- dlnr`
   - `phi_mu_chl <- phi_mu`
   - `g_k_chl_proxy <- [chosen source: g_K_CL or g_kNR]`
   - `g_y_chl_proxy <- g_Y`
4. Only after (1)-(3), proceed to estimation launch under a logged preflight manifest.
