# Assesment of Repo State: Workflow, Pipeline, and Code → Output Map

## Scope and interpretation used

This assessment focuses on the **active scripts directly under `codes/`** that match your requested focus items:

- `codes/10_config.R`
- `codes/20_shaikh_ardl_replication.R`
- `codes/21_CR_ARDL_grid.R`
- `codes/22_VECM_S1.R`

Notes:

1. Your prompt names `22_VECM_S1_shaikh_window`; in this repo root `codes/` the matching active file is currently `22_VECM_S1.R` (its internal header still references the former name).  
2. As requested, this excludes legacy content inside subfolders (`codes/_legacy`, `codes/_main_legacy`, `codes/_tsdyn_branch`) from the main analysis.

---

## 1) High-level working flow (current state)

### Pipeline order (intended practical order)

1. **Configuration bootstrap** via `10_config.R`.
2. **Faithful fixed-order ARDL replication** via `20_shaikh_ardl_replication.R`.
3. **ARDL grid exploration + frontier artifacts** via `21_CR_ARDL_grid.R`.
4. **VECM S1 lattice discovery (lnY, lnK)** via `22_VECM_S1.R`.

### Shared pattern across scripts

- All modeling scripts call `source("codes/10_config.R")` and `source("codes/99_utils.R")`.
- Data source for focused scripts is the Shaikh workbook path configured in `CONFIG$data_shaikh`.
- Outputs are mostly written as **CSV**, **PNG**, and **TXT logs**, organized by each script’s chosen root folder.

---

## 2) File-by-file assessment

## A) `codes/10_config.R` — pipeline control plane

### Role in workflow

`10_config.R` is the central parameter registry. It defines:

- input file/sheet routes,
- variable name mapping,
- window locks,
- deterministic-space options,
- lag bounds,
- reproducibility seed,
- output roots,
- and run behavior toggles.

### Inputs/outputs behavior

- **Consumes**: none (pure config object definition).
- **Produces**: in-memory `CONFIG` list (used by downstream scripts).

### Key path and extension map

- Input-like references (strings inside config):
  - `data/processed/ddbb_cu_US_kgr.xlsx` → `.xlsx`
  - `data/raw/Shaikh_RepData.xlsx` → `.xlsx`
- Declared output roots:
  - `output/TsDynEngine` (folder)
  - `output/InferenceRank_tsDyn` (folder)

### Assessment

- **Strength**: single-source control point improves reproducibility and consistency.
- **Risk**: multiple scripts currently override/select their own output roots instead of consistently using `OUT_TSDYN`/`OUT_RANK`.

---

## B) `codes/20_shaikh_ardl_replication.R` — faithful ARDL replication block

### Role in workflow

This script performs a faithful ARDL replication-style run on the locked `shaikh_window`, with:

- fixed ARDL order `(2,4)`,
- dummy-year handling,
- bounds tests,
- long-run multipliers,
- utilization series construction,
- UECM/RECM extraction for error-correction interpretation,
- and a compact comparison plot.

### Data and dependency flow

- Reads Shaikh workbook (`.xlsx`) from config.
- Constructs transformed series (`lnY`, `lnK`) after deflating by price index.
- Fits ARDL with formula `lnY ~ lnK | dummies`.

### Outputs generated (with path extensions)

Under `output/CU_estimates_compare/`:

- `csv/SHAIKH_ARDL_replication_series_shaikh_window.csv` → `.csv`
- `logs/SHAIKH_ARDL_replication_log_shaikh_window.txt` → `.txt`
- `figs/FIG_SHAIKH_ARDL_u_shaikh_window.png` → `.png`

### Assessment

- **Strength**: clear, self-contained replication artifact set (series + log + figure).
- **Risk**: hard-coded dummy years and fixed order make this script intentionally non-generalized (which is fine for faithful replication, but should be explicitly treated as such in run docs).

---

## C) `codes/21_CR_ARDL_grid.R` — ARDL grid + geometry/frontiers

### Role in workflow

This script executes a bounded ARDL grid over `(p,q)` and exports:

- cell-level geometry cards,
- 3 frontier envelope tables,
- 3 frontier figures,
- and a manifest append entry.

### Data and output flow

- Reads Shaikh workbook (`.xlsx`) from config.
- Builds real/log series (`lnY`, `lnK`) in `shaikh_window`.
- Runs ARDL for `p = 1..4`, `q = 1..4`.
- Computes log-likelihood/complexity diagnostics including ICOMP/RICOMP penalty proxies.

### Outputs generated (with path extensions)

Under `output/CriticalReplication/`:

- `csv/GEOMETRY_CARDS_ARDL.csv` → `.csv`
- `csv/ENVELOPE_ARDL_fit_vs_k.csv` → `.csv`
- `csv/ENVELOPE_ARDL_fit_vs_ICOMP.csv` → `.csv`
- `csv/ENVELOPE_ARDL_fit_vs_RICOMP.csv` → `.csv`
- `figs/FIG_Frontier_ARDL_fit_vs_k.png` → `.png`
- `figs/FIG_Frontier_ARDL_fit_vs_ICOMP.png` → `.png`
- `figs/FIG_Frontier_ARDL_fit_vs_RICOMP.png` → `.png`
- `manifest/RUN_MANIFEST.md` → `.md`

### Important repo-state issue found

Inside the core grid loop, there are literal Markdown fences (```) embedded in executable R code. This is a syntax-breaking condition in an `.R` script and will prevent execution unless removed.

### Assessment

- **Strength**: coherent geometry/frontier export design.
- **Critical issue**: current file appears non-runnable due to embedded code-fence tokens.
- **Consistency gap**: header comment says `20_CR_ARDL_grid.R` while file name is `21_CR_ARDL_grid.R`.

---

## D) `codes/22_VECM_S1.R` — VECM Stage S1 lattice engine

### Role in workflow

This is the most complex stage among the focus scripts. It performs a branch-wise VECM discovery process for `X_t = (lnY, lnK)'` with:

- deterministic branch combinations (SR/LR include settings),
- p-grid exploration,
- q-profile asymmetry in short-run Γ terms,
- rank-1 anchoring and beta normalization,
- restricted OLS lattice build,
- stability diagnostics via companion roots,
- IC tables, top-cell summaries,
- representative ECT exports and root overlays.

### Data and output flow

- Reads Shaikh workbook (`.xlsx`) from config.
- Filters to `shaikh_window`.
- Creates branch roots under `output/Self_Discovery_Process/VECM_stage/S1_lnY_lnK/shaikh_window/<det_tag>/`.
- Writes substantial branch-specific CSV/PNG/TXT/TeX-stub outputs.

### Output classes and extensions

Per branch (`<det_tag>`):

- `csv/*.csv` → cell lattices, deltas, IC eta, branch summary, top-cells, eigenvalue long tables
- `figs/*.png` → ΔBIC surface, LL frontier, theta/stability surfaces, embeddings, ECT overlay, roots overlay
- `logs/*.txt` + `logs/*.csv` → run index + gate-failure diagnostics
- `ect/*.csv` → representative ECT series
- `tex/README_TEX_STUBS.tex` → `.tex` placeholder/stub

### Assessment

- **Strength**: robust research-engine structure with detailed diagnostics and branch isolation.
- **Risk**: higher operational complexity and many moving parts; execution success is package- and data-sensitive.
- **Naming drift**: internal header still references the prior filename (`52_VECM_S1_shaikh_window.R`) though active file is `22_VECM_S1.R`.

---

## 3) Code → output map (condensed)

| Code file | Primary purpose | Input extensions | Output root | Output extensions |
|---|---|---|---|---|
| `codes/10_config.R` | Global config object | `.xlsx` (declared paths) | (declares only) | n/a (no direct write) |
| `codes/20_shaikh_ardl_replication.R` | Faithful ARDL replication | `.xlsx` | `output/CU_estimates_compare/` | `.csv`, `.txt`, `.png` |
| `codes/21_CR_ARDL_grid.R` | ARDL grid + frontiers | `.xlsx` | `output/CriticalReplication/` | `.csv`, `.png`, `.md` |
| `codes/22_VECM_S1.R` | VECM S1 lattice/discovery | `.xlsx` | `output/Self_Discovery_Process/VECM_stage/S1_lnY_lnK/shaikh_window/` | `.csv`, `.png`, `.txt`, `.tex` |

---

## 4) Pipeline health assessment (quick verdict)

### What is working conceptually

- The repository has a clear staged logic: config → faithful baseline → ARDL uncertainty map → VECM uncertainty map.
- Output artifacts are already organized in analysis-friendly formats (especially CSV + figure pairs).

### What needs immediate attention

1. **Fix `codes/21_CR_ARDL_grid.R` syntax issue** (remove embedded Markdown code fences).
2. **Standardize naming/comments** to avoid confusion (`20_` vs `21_`; `52_` header vs `22_` filename).
3. **Unify output contracts** across scripts (currently split between `CU_estimates_compare`, `CriticalReplication`, and `Self_Discovery_Process`).

### Suggested next normalization step

Create one short orchestration README section or runner script that declares:

- execution order,
- expected successful artifact paths,
- and a minimal run-checklist (existence checks by extension: `.csv/.png/.txt/.md/.tex`).

