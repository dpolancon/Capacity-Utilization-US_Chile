# D12B Baseline Estimation Design

## Scope

D12B is an estimation-design pass. It does not estimate coefficients, print real model results, reconstruct productive capacity, recover utilization, recover elasticity paths, or reintroduce q_omega.

The design consumes the D11R and D12V/D12V2 decisions:

- D11R terminal decision: `AUTHORIZE_D12_BASELINE_ESTIMATION_DESIGN`.
- D12V estimator doctrine: Restricted DOLS is the preferred baseline-design estimator after gates.
- D12V2 terminal decision: `AUTHORIZE_D12B_ESTIMATION_DESIGN_SESSION`.

## Baseline Object

The controlled D12B baseline design object is the Chapter 2 nonlinear/interacted first-layer transformation relation. The long-run level relation may contain:

- dependent output: `Y_REAL_NFC_GVA_BASELINE_D09` or its log-level working form in D12C;
- productive-origin capital base variables: `K_ME`, `K_NRC`, and/or the authorized ME+NRC capacity boundary `K_capacity`;
- distribution variable: `omega_NFC_productive_origin_GVA`;
- profit-share support variable: `pi_NFC_productive_origin_GVA`, if authorized by the candidate specification;
- generated or interacted terms only after the interaction-term gate passes.

The baseline capital boundary remains ME/NRC. Total-capital variables are excluded from baseline eligibility by D11R.

## Variable Roles

| Variable or object | D12B role | Boundary status | D12C note |
|---|---|---|---|
| `Y_REAL_NFC_GVA_BASELINE_D09` | dependent-output candidate | baseline authorized by D11/D11R | D12C may load but must not treat D12B as coefficient evidence. |
| `K_ME` | admissible level base variable | ME/NRC productive-origin boundary | D12C may construct first differences for RDOLS dynamics if the gate remains open. |
| `K_NRC` | admissible level base variable | ME/NRC productive-origin boundary | D12C may construct first differences for RDOLS dynamics if the gate remains open. |
| `K_capacity` | boundary reference / possible level base object | ME+NRC boundary, not total capital | D12C must decide whether to use disaggregated ME/NRC or aggregate boundary form. |
| `omega_NFC_productive_origin_GVA` | distribution level variable | baseline-authorized productive-origin measure | May enter level relation and base-difference set only if classified as admissible. |
| `pi_NFC_productive_origin_GVA` | profit-share support variable | baseline-authorized support measure | May enter only when the specification declares it. |
| interaction/generated terms | long-run level terms only | gated | No mechanical dynamic corrections. |
| q_omega family | parked | blocked | Must not enter D12C baseline. |
| total-capital GPIM objects | robustness-only / excluded from baseline | D11R reclassified out of baseline | Must not leak into D12C baseline. |

## Gate Status

| Gate | D12B design status | Evidence |
|---|---|---|
| Boundary clean | PASS | D11R reclassified total-capital variables out of baseline; ME/NRC remains baseline capital. |
| q_omega parked | PASS | D11R and D12V confirm no q_omega-family object is active. |
| Integration-order gate | NON_BLOCKING_FOR_DESIGN | D11 identified likely I(1) output/distribution variables and possible I2 risk for capital; D12C must re-open the gate before fitting. |
| Interaction/generated-term gate | NON_BLOCKING_FOR_DESIGN | D12V created the gate; D12C must classify any generated term before fitting. |
| Lead/lag survival | PASS_FOR_DESIGN | D11 sample windows support design grids; D12C must compute exact effective sample before fitting. |

## Lead/Lag Grid Design

D12C may consider the following restricted DOLS grids if the gate remains open:

| Grid ID | Leads | Lags | D12B status | Reason |
|---|---:|---:|---|---|
| `RDOLS_LL_0_0` | 0 | 0 | design-reference-only | Baseline matrix with no dynamic augmentation; useful for rank checks, not final estimator. |
| `RDOLS_LL_1_1` | 1 | 1 | preferred-initial-grid | Minimal symmetric dynamic correction with low sample loss. |
| `RDOLS_LL_2_2` | 2 | 2 | sensitivity-grid | More dynamic correction; still design-surviving given the D11 window. |
| `RDOLS_LL_3_3` | 3 | 3 | max-caution-grid | Only if D12C sample survival and rank checks pass. |

## Estimator Design Decision

The D12B estimator design selects a local manual Restricted DOLS wrapper as the baseline implementation path.

`cointReg::cointRegD` is not the nonlinear/interacted baseline engine because it applies DOLS dynamic corrections to every column supplied in `x`. Chapter 2 requires interaction/generated terms to remain in the long-run level relation while dynamic corrections are restricted to admissible base-variable first differences.

## D12C Authorization Boundary

D12C may implement controlled preliminary RDOLS estimation only after it:

1. reopens the integration-order and interaction-term gates;
2. confirms no q_omega reintroduction;
3. builds the restricted dynamic correction matrix only from admissible base-variable first differences;
4. reports sample survival and design rank before coefficients;
5. prints the result through the contract-first `ch2_rdols` interface.

D12B authorizes D12C design implementation and controlled preliminary estimation. It does not authorize final manuscript estimation.
