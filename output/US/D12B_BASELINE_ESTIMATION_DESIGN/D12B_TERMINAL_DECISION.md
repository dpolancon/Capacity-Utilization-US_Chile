# D12B Terminal Decision

Terminal decision: `AUTHORIZE_D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION`

## Authorization Basis

- Baseline object classified: TRUE
- Variable roles assigned: TRUE
- Boundary clean: TRUE
- q_omega parked: TRUE
- Integration-order gate resolved or non-blocking: TRUE for design, with D12C required to re-open before fitting
- Interaction/generated-term gate resolved or no interaction term present: TRUE for design, with D12C required to classify generated terms before fitting
- Restricted DOLS design admissible: TRUE
- At least one lead/lag grid survives: TRUE at design level from D11 sample windows
- cointRegD not selected as nonlinear baseline engine: TRUE
- Manual RDOLS wrapper blueprint complete: TRUE
- Results UI blueprint complete: TRUE
- D12C API contract complete: TRUE
- No coefficient estimation run in D12B: TRUE

## Boundary

D12C is authorized for controlled preliminary RDOLS estimation only. D12C is not authorized for final manuscript estimation, productive-capacity reconstruction, utilization reconstruction, elasticity recovery, q_omega reintroduction, FM-OLS/IM-OLS nonlinear baseline substitution, or unrestricted DOLS interaction dynamics.
