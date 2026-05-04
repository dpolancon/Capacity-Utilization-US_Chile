# data_sources_WS_corridor migration log — 2026-05-03

## Status

The `docs/data_sources_WS_corridor/` material has been moved out of this repository into a separate local repository.

This deletion is intentional. These files are no longer treated as part of the active `Capacity-Utilization-US_Chile` data-management and results-production repository.

## Interpretation

The files were not lost. They were externalized.

Within this repository, their deletion should be read as repository-scope cleanup: removing a qualitative/world-system/source-corridor subrepo from the quantitative data-management and output-production repository.

## Scope implication

This repository should focus on data management, source-of-truth panels, Chile and US capacity-utilization reconstruction, profitability diagnostics, result packages, and reproducibility scripts.

The externalized corridor repository should hold WS corridor notes, copper/USMF/corridor packs, qualitative source ledgers, mechanism maps, bibliography, and reading infrastructure.

## Git interpretation

Tracked deletions under the following paths are intentional candidates for staging:

- `docs/data_sources_WS_corridor/`
- `docs/data_sources_WS_corridor_v1/`

Do not restore these paths from `origin/main` unless explicitly needed.

## Remaining check

Before staging deletions, confirm whether active code or documentation still links to these paths.
