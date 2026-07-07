# D12B RDOLS Implementation Blueprint

## Decision

D12C should implement a local manual Restricted DOLS wrapper. The wrapper is the Chapter 2 baseline implementation path for nonlinear/interacted/generated specifications after the integration-order and interaction-term gates pass.

`cointReg::cointRegD` remains a linear DOLS benchmark only. It is not the baseline engine for interacted Restricted DOLS because it applies dynamic corrections to all columns supplied in `x`.

## Hard Rule

Interaction/generated terms may enter the long-run level relation.

Interaction/generated terms must not mechanically receive dynamic corrections.

## Required Wrapper Architecture

1. Load `y`.
2. Load admissible level base variables.
3. Load admissible level interaction/generated terms, if the interaction gate passes.
4. Load deterministic terms and I(0) controls if authorized.
5. Construct first differences only for admissible base I(1) variables.
6. Generate leads/lags only for those base-variable differences.
7. Do not generate leads/lags of interaction/generated terms.
8. Align level observations with differenced dynamic terms.
9. Trim the sample according to missingness and lead/lag loss.
10. Fit the resulting design matrix by OLS only in D12C.
11. Mark any D12C coefficient output as `CONTROLLED_PRELIMINARY`.

## Proposed Local Function Sequence

```text
build_level_matrix
build_base_difference_matrix
build_restricted_lead_lag_matrix
align_rdols_sample
fit_manual_rdols
extract_long_run_coefficients
extract_auxiliary_dynamic_coefficients
compute_design_rank
compute_sample_survival
build_rdols_result_object
```

## Matrix Contract

The D12C design matrix must separate three blocks:

| Block | Contents | Dynamic corrections allowed |
|---|---|---|
| Long-run level block | y, admissible base levels, authorized deterministic terms, authorized controls, authorized interaction/generated terms | no |
| Restricted dynamic block | leads/lags of differences of admissible base I(1) variables | yes |
| Metadata block | gate statuses, sample, rank, variable roles, source lineage | not a regressor block |

The interaction/generated level block must never be copied into the restricted dynamic block without a separate polynomial/nonlinear cointegration protocol.

## Sample Alignment Contract

D12C must align the level relation and dynamic correction terms after lead/lag construction. It must report:

- declared sample window;
- raw nonmissing observations;
- observations lost to first differencing;
- observations lost to leads/lags;
- observations lost to missingness after alignment;
- final effective sample;
- design rank;
- number of long-run coefficients;
- number of auxiliary dynamic coefficients.

## D12B Prohibitions

D12B does not implement real-data coefficient estimation.

D12B does not run `lm`, `cointRegD`, `cointRegFM`, `cointRegIM`, or any substitute estimator on the data.

D12B does not print coefficient tables or real model results.

## D12C Status Rule

Any D12C coefficient output must be marked:

```text
CONTROLLED_PRELIMINARY
NOT FINAL MANUSCRIPT ESTIMATION
```
