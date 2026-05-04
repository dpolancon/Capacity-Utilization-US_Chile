# AR_Corridor and chapter2 artifact relocation log — 2026-05-03

## Status

The previous tracked `AR_Corridor/` and `chapter2/` materials have been relocated into `artifacts/`.

This is intentional.

## Relocated paths

Tracked source paths removed from active root:

- `AR_Corridor/`
- `chapter2/`

Replacement artifact paths added:

- `artifacts/AR_Corridor/`
- `artifacts/chapter2/`

## Interpretation

These files are no longer treated as active data-management or production-code paths.

They are retained as project artifacts: prior estimation notes, governing notes, scripts, results packages, and Chapter 2 drafting infrastructure.

## Scope implication

The repository root should now prioritize the active data/result-production pipeline. Historical drafting and corridor artifacts should live under `artifacts/` unless promoted back into active production.

## Remaining check

The following adjacent paths are still not handled by this relocation:

- `docs/ch2/`
- `docs/results/`
- `docs/trigger/`

Those should be reviewed in a separate commit.
