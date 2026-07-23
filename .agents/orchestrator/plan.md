# Master Plan: Capacity-Utilization-US_Chile Repository Tidy & Scoping Alignment

## Executive Summary
This plan covers the complete execution of requirements R1-R4 for the `Capacity-Utilization-US_Chile` repository, following the Project Orchestrator pattern. All implementation, script creation, file modifications, build/test commands, and auditing will be dispatched to subagents.

## Milestones & Execution Steps

### Milestone 1: Exploration & Assessment
- Dispatch 3 `teamwork_preview_explorer` subagents to:
  1. Inspect `codes/` directory structure, list all non-flat files/folders, identify legacy scripts and stage runs (`S34R`), check LaTeX junk files (`.nav`, `.snm`, `.aux`, `.log`) in `output/` or `chapter2_paper/`, check `.gitignore`.
  2. Inspect `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md` and `Advisor_Review_2026-07-23.md` (or relevant review notes) for exact references to "Recapitalization Corridor", \chi_t, \psi_j, Subsections 2.3.3, 6.1.2, 6.1.3, 6.1, and Section 7.
  3. Inspect feeder repos (`C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` and `C:\ReposGitHub\K-Stock-Harmonization`) and existing `data/raw/` / `data/provider_handoffs/` files to design the exact mapping for `data/metadata/data_provenance_manifest.md`.
  4. Inspect all markdown files in `chapter2_vault/`, `drafts/`, and `reports/` to list all files requiring YAML header standardization.

### Milestone 2: R1 Outline Pruning
- Dispatch `teamwork_preview_worker` to edit `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md` per R1.
- Dispatch 2 `teamwork_preview_reviewer` subagents to verify outline pruning.

### Milestone 3: R2 Repository Reorganization & Tidy-Up
- Dispatch `teamwork_preview_worker` to:
  - Tidy `codes/` by moving legacy/archive scripts to `codes/legacy/` and stage-run subdirectories (e.g. `S34R`) to `codes/runs/`.
  - Clean up LaTeX build junk (`.nav`, `.snm`, `.aux`, `.log`) in `output/` and update `.gitignore`.
  - Create `data/metadata/data_provenance_manifest.md` with required YAML metadata and mapping of feeder repos.
- Dispatch 2 `teamwork_preview_reviewer` subagents to verify R2 layout and manifest.

### Milestone 4: R3 YAML Metadata Standardization
- Dispatch `teamwork_preview_worker` to standardize YAML headers across all active markdown files in `chapter2_vault/` and `drafts/` / `reports/` with the mandatory 6 fields (`type`, `status`, `depends_on`, `stage_scope`, `country`, `last_updated`).
- Dispatch 2 `teamwork_preview_reviewer` subagents to verify YAML frontmatter across all markdown files.

### Milestone 5: R4 Verification Script & Forensic Audit
- Dispatch `teamwork_preview_worker` to create `tests/verify_repo_tidy.R` (or Python equivalent `tests/verify_repo_tidy.py`) and run it to verify:
  1. No forbidden subdirectories in `codes/` (only `legacy/` and `runs/`).
  2. `data/metadata/data_provenance_manifest.md` exists and has valid YAML metadata.
  3. All vault markdown files have valid YAML headers with the 6 mandatory properties.
- Dispatch 2 `teamwork_preview_challenger` subagents to execute `tests/verify_repo_tidy.R` / `.py` independently and stress-test the criteria.
- Dispatch `teamwork_preview_auditor` to conduct full forensic integrity audit.
- Gate check: Ensure all pass, exit code 0, CLEAN audit.
