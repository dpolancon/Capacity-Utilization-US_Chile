---
type: stage_report
status: active
depends_on: [chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]
stage_scope: all_stages
country: US
last_updated: 2026-06-21
---

# S29H Total Capital Downstream Input Selection Contract

This contract locks the permitted downstream menu for total capital variables. It does not create new variables, transformations, model-input panels, samples, q, theta, productive capacity, utilization, modeling outputs, or econometric outputs.

## Authoritative Primary Inputs

- `G_TOT_GPIM_2017`: baseline productive-capital level, `1931-2024`.
- `LOG_G_TOT_GPIM_2017`: baseline logged productive-capital variable, `1931-2024`.

## Robustness Inputs

- `N_TOT_GPIM_2017`: net-stock robustness level.
- `LOG_N_TOT_GPIM_2017`: net-stock robustness log.

## Growth Candidates

- `DLOG_G_TOT`: log change in gross total capital.
- `GROWTH_ARITH_G_TOT`: exact arithmetic proportional change in gross total capital.

A later stage must select the growth definition explicitly. Arithmetic growth and log growth are not interchangeable.

## Warm-Up Rule

Warm-up observations are retained for continuity and diagnostics but are not authorized for baseline empirical estimation.
