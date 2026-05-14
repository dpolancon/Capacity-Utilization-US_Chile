# US S30 Formal Stability Workspace

## Purpose

Formal S30 adjudication for the restricted B1 pathway.

This workspace supports the next bounded coding pass:

codes/US_S30_formal_stability_adjudication.R

## Forbidden

- estimator-grid expansion
- S40 code
- productive-capacity reconstruction
- utilization computation
- profitability outputs
- Chile outputs

## Required outputs

- us_s30_formal_spec_disposition.csv
- us_s30_hansen_stability_tests.csv
- us_s30_gregory_hansen_stress.csv
- us_s30_formal_stability_decision.csv
- US_S30_formal_stability_adjudication_report.md
- us_s30_formal_stability_manifest.csv

## Gate logic

S40 may open only as a restricted B1 pathway.

Mixed Tier 2 evidence requires a fragility flag.

Contradictory or unavailable Tier 2 evidence blocks S40.
