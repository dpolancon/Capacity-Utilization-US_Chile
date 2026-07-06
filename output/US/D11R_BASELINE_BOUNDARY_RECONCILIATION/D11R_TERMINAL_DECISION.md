# D11R Terminal Decision

Terminal decision: AUTHORIZE_D12_BASELINE_ESTIMATION_DESIGN

## Reconciliation Summary

D11 correctly blocked D12 authorization because total-capital variables still carried baseline authorization.
D11R retains the variables but reclassifies them out of baseline eligibility in the downstream reconciliation layer.

## Target Variables

- G_TOT_GPIM_2017: EXCLUDED_FROM_BASELINE; d12_baseline_eligible=FALSE
- LOG_G_TOT_GPIM_2017: EXCLUDED_FROM_BASELINE; d12_baseline_eligible=FALSE

## Boundary Status

Target variables reclassified: TRUE
No total-capital variable baseline-authorized under D11R: TRUE
Baseline capital remains ME/NRC: TRUE
q_omega blocking leakage: FALSE

D11R did not run final estimation, final coefficient estimation, elasticity recovery, productive-capacity reconstruction, or utilization reconstruction.
