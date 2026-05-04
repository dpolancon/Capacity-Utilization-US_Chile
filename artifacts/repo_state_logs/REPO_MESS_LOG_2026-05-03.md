# Repo mess log — 2026-05-03

## Status

This repository is in a major local transition state.

The local working tree is being treated as the active production state.  
`origin/main` remains the historical reference state, not the immediate target for restoration.

## Audit snapshot

Audit produced:

- 718 tracked files deleted locally
- 720 tracked files reported modified, largely inflated by deleted tracked files
- 649 untracked non-ignored files
- 142 ignored files eligible for cleanup dry-run

Top-level deleted tracked files:

- docs: 354
- output: 282
- codes: 60
- chapter2: 7
- data: 6
- AR_Corridor: 6

Top-level untracked files:

- output: 486
- codes: 114
- artifacts: 28
- data: 12
- agents: 2

## Interpretation

This is not a small dirty state. It is a structural replacement state.

Tracked online files from the previous repo architecture are locally deleted.
New local files appear to represent the active working pipeline, especially:

- `codes/CL_*`
- `codes/US_*`
- `codes/_legacyV2/`
- `codes/contexter/`
- `data/processed/US/`
- `data/processed/wbop_*`
- `data/raw/Chile/harmonized_series_2003CLP_1900_2024.csv`
- `output/source_of_truth_chile/`
- `output/wbop/`
- `output/profitability_chile*`
- `output/profitability_us/`
- `artifacts/`

## Working decision

Do not restore the repo to `origin/main` by default.

The local state is provisionally accepted as the active state.

Cleanup should proceed by classification:

1. Preserve active production code.
2. Preserve source-of-truth data and final processed panels.
3. Preserve result packages needed for Chapter 2 writing and defense.
4. Move scratch diagnostics to `_scratch_review` or `_legacy_review`.
5. Remove ignored generated junk only after dry-run.
6. Do not commit mass deletions until the curated replacement structure is explicit.

## Immediate cleanup objective

Produce a clean local architecture:

- `codes/active/`
- `codes/legacy/`
- `data/raw/`
- `data/processed/`
- `output/results_locked/`
- `output/diagnostics_review/`
- `artifacts/repo_state_logs/`

## Do not do

- Do not run `git reset --hard`.
- Do not run `git clean -fd` on non-ignored files.
- Do not push current state directly to `main`.
- Do not commit all deletions without a curation ledger.

## Shell-fragment cleanup

During terminal auditing, two accidental top-level shell-fragment files were created:

- `-type f`
- `GitHub" `

They were inspected as command-fragment artifacts and removed from the working tree. They were untracked and never part of the repository history.
