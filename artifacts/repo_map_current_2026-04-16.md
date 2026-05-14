# Current Repo Map — Capacity-Utilization-US_Chile

**Snapshot date:** 2026-04-16

This file is a literal current-state map of the repository as it exists on disk on the snapshot date. It is a navigational inventory, not a target-state build spec.

**Legacy note:** `artifacts/repo_structure_Ch2_v2.md` remains in the repo as an older target-state planning document and should be read as legacy context rather than a description of the current structure.

## Root tree

```text
Capacity-Utilization-US_Chile/
├── .claude/                             hidden Codex-local settings and worktrees
├── .git/                                Git metadata
├── .qwen/                               hidden Qwen-local settings
├── .Rproj.user/                         RStudio user state
├── .vscode/                             VS Code launch/settings files
├── agents/                              prompt and agent instruction documents
├── artifacts/                           working reference docs and structured research assets
├── codes/                               executable analysis scripts; currently legacy-heavy
├── data/                                raw, interim, processed, and final datasets
├── docs/                                research notes, corridor workspaces, and legacy documentation
├── output/                              estimation results, result packages, tables, and writing outputs
├── reports/                             stand-alone report notes
├── tmp/                                 temporary working files
├── WS_corridor/                         workspace-specific corridor directory
├── .gitattributes
├── .gitignore
├── .Rhistory
├── .Rprofile
├── AGENTS.md
├── Capacity-Utilization-US_Chile.Rproj
├── CLAUDE.md
├── QWEN.md
└── README.md
```

## Major active subtrees

### `artifacts/`

Current reference and handoff area with both compact markdown artifacts and structured subtrees.

```text
artifacts/
├── AR_Corridor/                         corridor package with numbered thematic subfolders
│   ├── 00_governing_notes/
│   ├── 01_accounting_objects/
│   ├── 02_country_tracks/
│   ├── 03_dysfunctionality/
│   ├── 04_estimation_outputs/
│   └── 05_paper_facing_assets/
├── chapter2/                            current Chapter 2 authority materials
│   ├── Ch2_Outline_DEFINITIVE.md
│   ├── ch2_modular_index.md
│   ├── ch2_section_prompts.md
│   ├── ch2_voice_guide.md
│   ├── fire_ch2_drafts.py
│   ├── s2_2_final_draft.md
│   └── s2_2_voice_constraints.md
├── dataset_build_state_snapshot_2026-04-16.md
├── dataviz_bestpractices_application_stageB.md
├── README_cointReg_package.md
├── repo_structure_Ch2_v2.md             legacy target-state repo spec
├── stageC_handoff_US.md
└── WritingStyleArtifactEconmetrics.md
```

### `codes/`

Executable code area. The visible current layout is not the `stage_a/stage_b/stage_c` top-level structure described in the older Chapter 2 spec; it is centered on root scripts plus legacy subtrees.

```text
codes/
├── CL_CU_fix/                           current named code workspace; no visible children at this level
├── legacy/                              older staged analysis tree
│   ├── pre_DOLS_VECM/
│   ├── stage_a/
│   ├── stage_b/
│   └── stage_c/
├── _legacyV2/                           second legacy code area
├── CL_01_stage1_mu.R
├── CL_02_stage2_mu_DOLS.R
├── CL_03_results_package_mu_theta_wsh.R
├── CL_04_results_presentation.R
├── CL_A_stage1_ECT_audit.R
├── CL_B_stage2_mu_Diagnostic.R
├── CL_profitability_analysis.R
├── us_dols_mu_theta_graph.R
├── us_dols_spec_grid_cointReg.R
├── us_dols_theta_graph.R
├── us_profitability_analysis.R
└── us_profitability_analysis_results_pack.R
```

### `data/`

Data area is organized by lifecycle state rather than by the target-state structure described in the older planning document.

```text
data/
├── final/                              final deliverable datasets
├── interim/                            intermediate build products
│   └── structural_identification/
├── processed/                          processed analysis-ready data
│   ├── Chile/
│   └── US/
└── raw/                                source data holdings
    ├── Chile/
    ├── other/
    └── US/
        ├── bea/
        └── fred/
```

### `docs/`

Documentation area combines active research workspaces, empirical notes, Obsidian configuration, and legacy material.

```text
docs/
├── .obsidian/                          local Obsidian vault configuration
├── data_sources_WS_corridor_v1/        active WS corridor corpus workspace
│   ├── 00_admin/
│   ├── 01_sources_raw/
│   ├── 02_notes/
│   ├── 03_bibliography/
│   ├── 04_mappings/
│   ├── 05_prompts/
│   ├── 06_exports/
│   ├── Chile_Assets/
│   ├── copper_hinge_integrated/
│   ├── copper_sector_chile_us/
│   ├── CrisisTheory/
│   ├── us_military_keynesianism_apparatus/
│   ├── ws_obsidian_wiring_pack/
│   ├── Zavaleta-Comparative-Relational-Toolkit/
│   ├── AGENTS.md
│   ├── README.md
│   └── WS_Obsidian_Wiring_Protocol.md
├── empirical_strategy/                 compact empirical notes and notebooks
│   ├── nb_01_redesign_motivation.md
│   ├── nb_02_unit_root_battery.md
│   ├── nb_03_stage1_recap_ECTm.md
│   ├── nb_04_cls_threshold_estimation.md
│   ├── nb_05_parameter_recovery_theta.md
│   ├── nb_06_mu_construction_results.md
│   └── README.md
├── _legacy/                            older documentation tree plus archived notes
│   ├── data_set_building/
│   ├── empirical_strategy/
│   ├── results/
│   ├── trigger/
│   ├── repo_structure_Ch2_v2.md
│   └── other legacy markdown references
└── WS_Obsidian_Wiring_Protocol.md
```

### `output/`

Output area contains both stage-based result folders and older package-style result directories. Mixed casing is present in the current tree and is preserved here exactly.

```text
output/
├── chile_2Smu_S1/                      older Chile result package
│   ├── csv/
│   ├── figs/
│   ├── reports_artifacts/
│   ├── tex/
│   └── txt/
├── chile_2Smu_S2_tdols/                older Chile TDOLS result package
│   ├── csv/
│   ├── figs/
│   ├── tex/
│   └── txt/
├── diagnostics/
├── panel/
├── profitability_us/                   older US profitability result package
│   ├── csv/
│   ├── figs/
│   ├── rds/
│   └── tex/
├── results_package_us/                 packaged US result bundle
│   ├── cointreg_results/
│   ├── figures/
│   └── tables/
├── stage_a/                            stage-based outputs
│   ├── Chile/
│   └── US/
├── stage_b/                            stage-based outputs
│   ├── Chile/
│   ├── Comparison/
│   └── US/
├── stage_c/                            stage-based outputs
│   ├── chile/
│   ├── comparison/
│   ├── us/
│   └── US_tmp/
├── swing_dysfunctionality/
├── tables/
└── writing/
    └── drafts/
```

## Support and irregular areas

### `agents/`

Prompt library and operator-facing markdown files for model sessions. Current contents are markdown prompts and framework notes rather than a nested code tree.

### `reports/`

Small report area. At the snapshot date it contains `chile_frontier_multicollinearity_audit.md`.

### `tmp/`

Temporary working area. Visible current child:

```text
tmp/
└── pdfs/
```

### `WS_corridor/`

Workspace-specific corridor directory present at repo root. No visible children were returned at the sampled level during this snapshot.

### Hidden/tooling folders

```text
.claude/
├── worktrees/
└── settings.json

.qwen/
└── settings.json

.vscode/
├── settings.json.orig
└── launch.json
```

## Status notes

- Active current-state areas: `artifacts/`, `data/`, `docs/`, `output/`, and root-level project/config files.
- Legacy or archival areas: `codes/legacy/`, `codes/_legacyV2/`, `docs/_legacy/`, and the older planning file `artifacts/repo_structure_Ch2_v2.md`.
- Workspace-specific or corridor-focused areas: `docs/data_sources_WS_corridor_v1/`, `artifacts/AR_Corridor/`, and `WS_corridor/`.
