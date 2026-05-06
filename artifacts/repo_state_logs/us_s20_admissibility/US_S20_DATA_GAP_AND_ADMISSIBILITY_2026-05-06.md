# US S20 data gap and admissibility memo — 2026-05-06

## Status

The US S10/S20 smoke test succeeded.

The current source-of-truth panel covers 1929–2024 and supports a baseline center-benchmark transformation-relation workflow.

## Data gap

The current US source panel does not detect machinery/non-machinery stock columns.

Therefore:

- `s_t = K_t^M / K_t` is not currently available;
- `phi_t = I_t^M / I_t^A` is not currently available;
- the full composition-weighted machinery-channel model is not yet admissible for the US case.

## Current admissible US path

The US case can currently proceed as:

S10 source-of-truth panel  
→ S20 baseline admissibility  
→ S30 wage-share interaction baseline

The admissible baseline S30 surface is:

- `k_t`
- `omega_t * k_t`
- centered interaction variants for diagnostic comparison

## Not-yet-admissible US path

The US case cannot yet proceed as:

S10 source-of-truth panel  
→ S20 machinery composition layer  
→ S30 composition-weighted `theta_tot` model

because the necessary machinery/non-machinery capital split is absent from the current panel.

## Interpretation

This does not invalidate the US benchmark.

It means the US can currently function as the center benchmark for the wage-share-conditioned transformation relation, while the full machinery-composition architecture remains pending a capital-composition data upgrade.

## Guardrail

Do not claim that the current US S30 model estimates the full composition-weighted machinery-channel transformation.

Write instead:

The current US S30 model is admissible as a wage-share interaction center benchmark. The full composition-weighted machinery-channel model requires a machinery/non-machinery capital split that is not yet available in the current US source panel.
