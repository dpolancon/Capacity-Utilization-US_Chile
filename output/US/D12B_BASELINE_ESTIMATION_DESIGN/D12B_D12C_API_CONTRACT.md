# D12B to D12C API Contract

## Contract Status

D12B authorizes D12C to implement controlled preliminary Restricted DOLS estimation architecture. D12B does not authorize final manuscript estimation.

## D12C May Implement

- manual Restricted DOLS wrapper;
- controlled preliminary coefficient estimation;
- contract-first result object;
- contract-first print method;
- model cards;
- sample-survival tables;
- gate-status tables;
- coefficient tables marked preliminary.

## D12C May Not Implement

- final manuscript estimation;
- productive-capacity reconstruction;
- utilization reconstruction;
- elasticity recovery;
- q_omega reintroduction;
- FM-OLS/IM-OLS nonlinear baseline;
- unrestricted DOLS interaction dynamics.

## Required Entry Points

| Function | D12C role | Required status |
|---|---|---|
| `build_level_matrix()` | Assemble long-run level regressors. | implementation allowed |
| `build_base_difference_matrix()` | Difference admissible base variables only. | implementation allowed |
| `build_restricted_lead_lag_matrix()` | Generate leads/lags only for admissible base differences. | implementation allowed |
| `align_rdols_sample()` | Align levels and dynamic terms. | implementation allowed |
| `fit_manual_rdols()` | Fit OLS on the controlled RDOLS matrix. | controlled preliminary only |
| `build_rdols_result_object()` | Build `ch2_rdols` result. | required before printing |
| `print.ch2_rdols()` | Print contract header before coefficients. | required |
| `write_rdols_model_card()` | Write design and use-status card. | required for any saved output |

## Required Input Contract

D12C must pass a specification object with:

- `model_id`;
- `dependent_variable`;
- `level_base_variables`;
- `level_interaction_terms`;
- `deterministic_terms`;
- `i0_controls`;
- `base_difference_variables`;
- `lead_lag_grid`;
- `sample_window`;
- `gate_statuses`;
- `source_paths`;
- `boundary_contract`.

## Required Output Contract

D12C result objects must include:

- `status = CONTROLLED_PRELIMINARY`;
- `terminal_scope = NOT_FINAL_MANUSCRIPT_ESTIMATION`;
- `estimator = RESTRICTED_DOLS`;
- explicit q_omega parked status;
- explicit FM-OLS/IM-OLS nonlinear baseline block;
- dynamic correction variable list;
- excluded interaction-dynamics list;
- sample survival;
- rank metadata;
- long-run coefficient table;
- auxiliary dynamic coefficient table stored separately;
- validation block.

## D12C Stop Conditions

D12C must stop if:

- q_omega enters the baseline variable set;
- total-capital variables enter the baseline level set;
- interaction/generated terms receive mechanical dynamic corrections;
- `cointReg::cointRegD` is selected as the nonlinear/interacted baseline engine;
- print output would show coefficients before the contract header;
- auxiliary dynamic coefficients are printed by default;
- a user-facing file labels output as final manuscript estimation.

## Terminal Authorization

If D12C implements this contract and all gates pass, it may produce controlled preliminary RDOLS coefficient output. That output remains design evidence, not final chapter estimation.
