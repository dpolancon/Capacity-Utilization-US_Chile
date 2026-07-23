# Project: Capacity-Utilization-US_Chile Repository Tidy & Scoping Alignment

## Architecture
- `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md`: Paper-facing outline and scope.
- `chapter2_vault/`: Main vault of paper-facing notes, econometrics documentation, codes documentation, and governance.
- `codes/`: Execution scripts (must be flat except `legacy/` and `runs/`).
- `data/metadata/data_provenance_manifest.md`: Provenance manifest mapping feeder repos to `data/raw/` and `data/provider_handoffs/`.
- `tests/verify_repo_tidy.R` (or `.py`): Automated verification script checking directory structure, manifest YAML, and vault markdown YAML headers.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Exploration & Assessment | Inspect repo layout, codes/ structure, vault markdown files, feeder repos, and Ch2_Outline_DEFINITIVE.md | none | DONE |
| 2 | R1: Outline Pruning | Update `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md` according to Advisor_Review_2026-07-23.md rules | M1 | DONE |
| 3 | R2: Repo Reorg & Manifest | Tidy `codes/`, clean LaTeX junk, update `.gitignore`, create `data/metadata/data_provenance_manifest.md` | M1 | DONE |
| 4 | R3: YAML Standardization | Standardize YAML headers across all `chapter2_vault/` and `drafts/` / `reports/` markdown files | M1 | DONE |
| 5 | R4 & Forensic Verification | Create `tests/verify_repo_tidy.R` (or `.py`), execute tests, run Reviewers, Challenger, and Forensic Auditor | M2, M3, M4 | IN_PROGRESS |

## Code Layout
- `codes/` (flat Python/R scripts, except `codes/legacy/` and `codes/runs/`)
- `data/metadata/data_provenance_manifest.md`
- `tests/verify_repo_tidy.R` (or python equivalent)
