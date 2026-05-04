# Active Production Spine Register - 2026-05-03

This register records the active production spine after the local current-state
audit. It is a navigation and governance note for the repository's production
surface, not a renewed audit and not a cleanup directive.

## Repository Status

The local current state is the working truth for Chapter 2 production work.
`origin/main` remains the historical baseline against which the current
reorganization can be compared, but it is not the operative production state.

This repository is the data-management and results-production repo for Chapter
2. It is not the Obsidian/vault governance layer. Vault, governance, and
cross-project knowledge-management materials belong outside the active
production spine unless they are explicitly required for reproducible Chapter 2
data construction or results generation.

## Candidate Active Scripts

Candidate active scripts are concentrated in the new flat script layer:

- `codes/CL_*`
- `codes/US_*`
- `codes/us_*`

These scripts are the current candidates for production execution and review.
Legacy staged trees remain pending review zones until their status is resolved.

## Candidate Active Data

Candidate active data are concentrated in:

- `data/raw/Chile/`
- `data/final/`
- `data/processed/US/`
- `data/processed/wbop_*`

These paths contain the working input and constructed data surfaces for current
Chapter 2 production.

## Candidate Active Outputs

Candidate active outputs are concentrated in:

- `output/source_of_truth_chile/`
- `output/chile_diagnostic_package/`
- `output/profitability_chile/`
- `output/profitability_chile_diagnostic/`
- `output/profitability_chile_diagnostic_short_very_19681975/`
- `output/profitability_chile_diagnostic_shortrun_19571978/`
- `output/profitability_us/`
- `output/wbop/`
- `output/US_dols_diagnostics/`
- `output/US_theta_break_core_1929_1978/`
- `output/US_theta_window_benchmark_and_robustness/`

These output directories are the current candidates for result inspection,
paper-facing package assembly, and reproducibility review.

## Pending Review Zones

The following zones are not part of the confirmed active production spine until
reviewed and explicitly resolved:

- old tracked `codes/stage_a`, `codes/stage_b`, and `codes/stage_c` deletions
- old tracked `data/final` and `data/processed` deletions
- old tracked `output/stage_a`, `output/stage_b`, and `output/stage_c` deletions
- `codes/legacy/`
- `codes/_legacyV2/`
- `output/_legacy/`
- remaining `docs/.obsidian/`
- remaining `docs/_legacy/`
- remaining `docs/data_set_building/`
- remaining `docs/empirical_strategy/`
- remaining `docs/method_classifier_reference/`
- `RRR_Accumulation_Framework.md`
- `AGENTS.md`
- `agents/analyst_agent.md`

These zones require separate review before any deletion, migration, or
promotion decision. This register does not authorize cleanup.

## Chapter 2 Methodological Contract

Chapter 2 does not estimate utilization directly. It estimates the long-run
transformation relation, reconstructs productive capacity, anchors its level,
and only then derives utilization.

FM-OLS is the main reconstruction estimator. IM-OLS is robustness. DOLS is a
fragility and stress diagnostic. Threshold/FGLS is downstream only after
diagnostics.

Residuals and generated ECTs do not identify utilization or activate regimes.
They remain diagnostic or intermediate objects unless the Chapter 2 estimation
contract explicitly assigns them another role.
