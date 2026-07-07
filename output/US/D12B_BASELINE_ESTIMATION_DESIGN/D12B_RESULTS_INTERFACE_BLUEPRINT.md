# D12B Results Interface Blueprint

## Purpose

D12C needs a contract-first result object and print layer before it estimates coefficients. The print interface must make the use status impossible to miss before any coefficient is displayed.

## Required Result Class

```r
class(out) <- c("ch2_rdols", "ch2_estimation_result")
```

## Required Object Components

```text
model_id
estimator
status
terminal_scope
contract
gates
specification
sample
coefficients
auxiliary_coefficients
fit_metadata
residual_metadata
design_metadata
validation
```

## Constructor Contract

`new_ch2_rdols_result()` should validate that:

- `estimator` equals `RESTRICTED_DOLS`;
- `status` is `CONTROLLED_PRELIMINARY` for D12C coefficient output;
- `terminal_scope` states `NOT_FINAL_MANUSCRIPT_ESTIMATION`;
- `contract` includes q_omega, FM-OLS, IM-OLS, and dynamic-correction warnings;
- `gates` records integration-order, interaction-term, boundary, q_omega, lead/lag, rank, and sample-survival status;
- auxiliary dynamic coefficients are stored separately from long-run coefficients.

## Print Method Signature

```r
print.ch2_rdols <- function(x,
                            ...,
                            digits = 4,
                            detail = c("compact", "full"),
                            show_auxiliary = FALSE)
```

## Required Print Order

1. Header
2. Model ID
3. Estimator
4. Status
5. Use-status warning
6. Vault contract
7. Gate statuses
8. Specification
9. Sample
10. Long-run coefficients
11. Auxiliary dynamic coefficient visibility note

## Required Warning Block Before Coefficients

The print method must always print the following before coefficients:

```text
CONTROLLED_PRELIMINARY
NOT FINAL MANUSCRIPT ESTIMATION
q_omega PARKED
FM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE
IM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE
RESTRICTED DOLS DYNAMIC CORRECTIONS APPLY ONLY TO BASE-VARIABLE FIRST DIFFERENCES
```

## Auxiliary Dynamic Coefficients

Default behavior:

```text
show_auxiliary = FALSE
```

Auxiliary dynamic coefficients may only be displayed when:

```r
print(x, show_auxiliary = TRUE)
```

When hidden, the print method must state:

```text
Auxiliary dynamic coefficients are hidden by default. Use print(x, show_auxiliary = TRUE) only for design audit, not manuscript interpretation.
```

## Coefficient Table Rule

Long-run coefficients and auxiliary dynamic coefficients must be stored and formatted separately. The print layer must not visually merge them, because the auxiliary terms are estimator corrections, not structural capacity terms.
