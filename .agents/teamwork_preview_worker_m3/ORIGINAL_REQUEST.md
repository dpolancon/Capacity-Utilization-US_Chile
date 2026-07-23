## 2026-07-23T20:10:49Z

<USER_REQUEST>
You are Worker 2 for Milestone 3 (R2: Repository Reorganization & Tidy-Up).

Working Directory: c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_worker_m3
Project Root: c:\ReposGitHub\Capacity-Utilization-US_Chile

DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Task Instructions:
1. Read Explorer 1's report (`c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_1\analysis.md`) and Explorer 3's report (`c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3\analysis.md`).
2. `codes/` Directory Reorganization:
   - Ensure `codes/runs/` directory exists.
   - Move the 3 stage-run subdirectories:
     - `codes/S34R_A_repaired_design_review_state_dependence` -> `codes/runs/S34R_A_repaired_design_review_state_dependence`
     - `codes/S34R_B_cpr_realigned_design_gate` -> `codes/runs/S34R_B_cpr_realigned_design_gate`
     - `codes/S34R_gpim_repaired_pre_regression` -> `codes/runs/S34R_gpim_repaired_pre_regression`
   - Delete `codes/.Rhistory`.
   - Confirm `codes/` contains no subdirectories other than `legacy/` and `runs/`.
3. Clean Up LaTeX Compilation Junk & Update `.gitignore`:
   - Delete all 106 LaTeX build junk files (`.aux`, `.nav`, `.snm`, `.fls`, `.fdb_latexmk`, `.out`, `.toc`, `.bbl`, `.blg`, `*_latex_compile.log`) in `output/` and `reports/`. Use `git rm --cached` or command-line tools so tracked junk files are un-tracked from git.
   - Update `c:\ReposGitHub\Capacity-Utilization-US_Chile\.gitignore` to block all LaTeX junk (`.aux`, `.nav`, `.snm`, `.vrb`, `.log`, `.out`, `.toc`, `.fls`, `.fdb_latexmk`, `.bbl`, `.blg`, `**/.Rhistory`) across the entire repository, ensuring negation patterns like `!output/**` and `!reports/**` do not override LaTeX ignore rules.
4. Central Data Provenance Manifest (`data/metadata/data_provenance_manifest.md`):
   - Create `data/metadata/data_provenance_manifest.md` with standard 6-field YAML frontmatter:
     ```yaml
     ---
     type: provenance_manifest
     status: active
     depends_on:
       - data/metadata/us_bea_variable_menu_locked.csv
       - codes/10_bea_api_helpers.R
     stage_scope: S10-S90
     country: comparative
     last_updated: 2026-07-23
     ---
     ```
   - Detail the exact feeder repository mappings for both US (`US-BEA-Income-FixedAssets-Dataset`) and Chile (`K-Stock-Harmonization`) to `data/raw/` and `data/provider_handoffs/`, using the draft schema from Explorer 3's `analysis.md`.
5. Save your report and verification evidence to `c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_worker_m3\changes.md` and `handoff.md`, then send a completion message to the orchestrator.
</USER_REQUEST>
