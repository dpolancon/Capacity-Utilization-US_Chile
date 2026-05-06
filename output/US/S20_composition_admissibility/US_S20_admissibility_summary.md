# US S20 composition and stability admissibility summary

## Status

This file records the S20 admissibility layer for the US case.

It does not perform final coefficient recovery and does not reconstruct productive capacity or utilization.

## Data span

- First year: 1929
- Last year: 2024
- Observations: 96

## Composition availability

- s_t is not available in the current US source panel; S30 must use the wage-share interaction baseline or wait for a machinery/non-machinery capital split.
- phi_t is not available in the current US source panel; this is acceptable for the center benchmark.

## Candidate windows

- Window register: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S20_composition_admissibility/us_s20_candidate_window_register.csv`
- Window summary: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S20_composition_admissibility/us_s20_window_admissibility_summary.csv`

## Guardrail

OLS scans in this script are diagnostic only. They do not replace FM-OLS, IM-OLS, or DOLS in S30/S90.

DOLS-era windows are treated as candidate historical/admissibility windows, not as final regimes.

S30 may proceed only after this S20 layer is reviewed.
