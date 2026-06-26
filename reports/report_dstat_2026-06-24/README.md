# S31B narrow descriptive report

## Purpose

Regression-facing descriptive documentation for seven U.S. Chapter 2 variables across the locked S31B historical windows.

## Analytical scope

Descriptive statistics only. The report does not select a model, estimate parameters, or modify the frozen dataset.

## Sources consumed

- Frozen source-of-truth v1 long file (read only).
- Completed S31B registry, structural, transition, event, accounting, provenance, and validation outputs.
- Authorized S29E `G_ME_GPIM_2017` and `G_NRC_GPIM_2017` inputs for kappa construction only.

## Build

- Script: `codes/US_S31B_build_narrow_descriptive_report.R`
- Order: extract and validate data; write tables and figures; write Markdown; write LaTeX mirror; run parity checks; compile PDF.
- Command from the worktree root: `Rscript codes/US_S31B_build_narrow_descriptive_report.R`
- LaTeX command from this folder: `latexmk -pdf -interaction=nonstopmode -halt-on-error report_dstat_2026-06-24.tex`

## Blocked object

Canonical real corporate GVA (`Y_REAL_CORP_GVA_BASELINE`) remains blocked and is not replaced.

## Construction date

24 June 2026
