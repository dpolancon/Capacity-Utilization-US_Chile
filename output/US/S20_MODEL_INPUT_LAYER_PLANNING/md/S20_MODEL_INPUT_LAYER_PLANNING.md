# S20 Model-Input Layer Planning

## Scope

This note defines the bounded implementation contract for the U.S. S20 model-input layer. It does not construct model-input data, invoke an S20 script, run econometrics, reconstruct GPIM, estimate $\theta_t$, construct productive capacity, derive utilization, or construct accumulated $q$.

The planning boundary is fixed by two upstream decisions:

- S14: `AUTHORIZE_S20_MODEL_INPUT_LAYER`
- S15: `AUTHORIZE_S20_PLANNING_NOTE`

S20 implementation must consume the S14 consolidation artifacts. It must not return to S12D construction outputs or provider files.

## Authorized S14 Registry

Exactly eight GPIM variables enter the authorized registry:

| variable_id | S20 role | unit | coverage |
|---|---|---|---|
| `I_NOMINAL_DIRECT_ME` | canonical nominal ME investment | current millions | 1901-2024 |
| `I_NOMINAL_DIRECT_NRC` | canonical nominal NRC investment | current millions | 1901-2024 |
| `P_K_SFC_ME_2017_100` | baseline ME capital-price index | 2017=100 | 1925-2024 |
| `P_K_SFC_NRC_2017_100` | baseline NRC capital-price index | 2017=100 | 1931-2024 |
| `I_REAL_GPIM_ME` | baseline real ME investment | millions_2017 | 1901-2024 |
| `I_REAL_GPIM_NRC` | baseline real NRC investment | millions_2017 | 1901-2024 |
| `K_GROSS_GPIM_ME` | composition-preserving ME capital input | millions_2017 | 1925-2024 |
| `K_GROSS_GPIM_NRC` | composition-preserving NRC capital input | millions_2017 | 1931-2024 |

No diagnostic net-value stock, `FAAt402` object, NFC output-price translation, productive-efficiency object, or other non-baseline S12D object may enter this registry.

## Capital Architecture

### Component Inputs

S20 must preserve:

- `K_GROSS_GPIM_ME`
- `K_GROSS_GPIM_NRC`

These are the composition-preserving objects. S20 may later derive logs, shares, or a centered ME/NRC composition measure only if the implementation prompt explicitly defines those transformations and validates positivity, support, units, and provenance. The component labels do not establish a fixed machinery/intensive and structures/extensive mapping.

### Derived Aggregate

The planned aggregate object is:

$$
K\_GROSS\_GPIM\_TOTAL_t
=
K\_GROSS\_GPIM\_ME_t
+
K\_GROSS\_GPIM\_NRC_t.
$$

This identity is admissible only because both source stocks are S14-registered real gross GPIM stocks measured in `millions_2017`. The aggregate is a derived scale object. It is not a claim that heterogeneous capital is physically homogeneous, that aggregation is theoretically neutral, or that the component architecture can be discarded.

The conservative baseline uses common support:

- `K_GROSS_GPIM_TOTAL` begins in 1931.
- No aggregate value is created before both component stocks exist.
- ME observations for 1925-1930 remain available in the component series.
- An implementation output must carry an aggregate-availability or common-support flag.
- Zero substitution, backward filling, or partial-support summation is prohibited.

The component stocks remain available after the aggregate is constructed. Later specifications may compare aggregate scale with the ME/NRC split or a separately authorized composition transformation.

## Theta Discipline

S20 prepares admissible inputs for estimating the long-run elasticity structure; it does not estimate $\theta_t$, productive capacity, or utilization.

$\theta_t$ is not a primitive data variable and is not directly observed. S20 may prepare capital-scale, component-capital, distribution, and explicitly defined interaction inputs for later estimators. It may not recover coefficients, fit a transformation relation, construct $Y_t^p$, or derive $\mu_t$.

## Distribution Architecture

### Preferred Baseline

The unadjusted wage share remains the preferred distribution variable. The S20 implementation prompt must identify:

- the authorized source artifact;
- sector and account boundary;
- formula and denominator;
- unit and frequency;
- coverage;
- join key and overlap with the 1931-2024 aggregate-capital baseline;
- missing-value policy;
- constant centering reference, if centering is implemented.

This planning note does not select or read a wage-share data file. Implementation must fail closed if the named source is absent, unaudited, or boundary-incompatible.

### Profit Share

Profit share may be retained as alternative or reconciliation evidence. It requires its own source, formula, boundary, and role metadata. It does not replace wage share as the preferred baseline under this plan.

### Shaikh-Adjusted Lane

A Shaikh-style corporate-sector adjustment is a conditional planned object only. It remains:

`BLOCKED_PENDING_CROSSWALK_AND_DATA`

Activation requires both:

1. current-release source data sufficient for the adjustment; and
2. a completed semantic and accounting crosswalk specifying source lines, accounting identities, signs, sector boundaries, and validation rules.

If either condition fails, no adjusted wage-share or profit-share object is constructed. If both later pass, adjusted objects must remain a separately labelled robustness or future-baseline candidate. They cannot silently overwrite the unadjusted wage-share baseline.

## Frontier Conditioners

IPP and government transportation may be registered as future control-conditioner candidates. S20 planning may document their potential roles and required future source lanes, but the baseline implementation must:

- exclude them from `K_GROSS_GPIM_TOTAL`;
- exclude them from baseline model specifications;
- avoid treating them as productive capital;
- avoid constructing productive-efficiency profiles;
- avoid accessing a new source lane without separate authorization.

Any later use belongs to a named robustness or extended specification with an independent input authorization.

## Accumulated Q

Accumulated $q$ remains parked.

- S20 constructs no accumulated $q$ object.
- This note does not authorize S21.
- No accumulated $q$ variable enters the S20 baseline.
- S21 may reopen only through a later explicit decision.

If S21 is reopened, its contract must separately decide the S14/S20-approved capital basis, accumulation reset logic, constant or diagnostic rolling centering, common support, initialization, and missing-year treatment.

## Planned Implementation Outputs

An S20 implementation prompt may authorize construction of a bounded model-input panel and ledgers containing:

1. the exact eight-variable S14 registry;
2. preserved ME and NRC component capital stocks;
3. `K_GROSS_GPIM_TOTAL` on 1931-2024 common support;
4. common-support and provenance flags;
5. a separately authorized unadjusted wage-share baseline input;
6. an optional, separately tagged profit-share alternative;
7. metadata-only frontier-conditioner candidates;
8. explicit exclusion and blocked-object ledgers.

It must not emit econometric results, accumulated $q$, $\theta_t$, productive capacity, utilization, or a productive-efficiency profile.

## Implementation Gate

The bounded S20 implementation prompt must require:

- exact S14 input paths and hashes;
- exact eight-variable allowlist;
- component and aggregate role separation;
- `millions_2017` unit equality before aggregation;
- row-level aggregate identity checks;
- 1931 common-support start;
- no partial-support aggregate values;
- distribution-source and boundary validation;
- unadjusted wage-share baseline protection;
- blocked Shaikh lane unless crosswalk and data both pass;
- frontier-conditioner exclusion from baseline;
- accumulated-$q$ exclusion;
- no provider access, GPIM reconstruction, econometrics, or downstream-stage invocation;
- an explicit post-implementation decision before any later stage reopens.

## Planning Decision Ledger

| ID | Area | Decision | Status |
|---|---|---|---|
| D01-D03 | Upstream gates and registry | Consume S14 under S15 planning authority; preserve exactly eight authorized GPIM variables. | LOCKED |
| D04 | Component capital | Preserve ME and NRC gross real GPIM stocks. | AUTHORIZE_FOR_IMPLEMENTATION_PROMPT |
| D05-D06 | Aggregate capital | Sum components only in common units and on common support beginning in 1931. | AUTHORIZE_FOR_IMPLEMENTATION_PROMPT |
| D07 | Theta discipline | Prepare inputs only; estimate no $\theta_t$, capacity, or utilization. | LOCKED |
| D08 | Wage share | Preferred unadjusted baseline, conditional on an explicit authorized source contract. | AUTHORIZE_CONDITIONAL_INPUT |
| D09 | Profit share | Alternative or reconciliation evidence only. | AUTHORIZE_OPTIONAL_ALTERNATIVE |
| D10 | Shaikh adjustment | Conditional future lane; blocked without crosswalk and data. | BLOCKED_PENDING_CROSSWALK_AND_DATA |
| D11 | Frontier conditioners | Metadata-only future control candidates; excluded from baseline. | PARKED_CONTROL_CANDIDATES |
| D12 | Accumulated $q$ | Remains parked; S21 remains closed. | PARKED |
| D13 | Centering | Constant reference baseline; rolling means diagnostic only. | AUTHORIZE_FOR_IMPLEMENTATION_PROMPT |
| D14-D15 | Stage gate | Authorize an S20 implementation prompt only; keep later stages closed. | AUTHORIZE_S20_IMPLEMENTATION_PROMPT |

## Validation Checks

| check_id | status | evidence |
|---|---|---|
| S14_DECISION_RECOGNIZED | PASS | S14 decision is `AUTHORIZE_S20_MODEL_INPUT_LAYER`. |
| S15_DECISION_RECOGNIZED | PASS | S15 decision is `AUTHORIZE_S20_PLANNING_NOTE`. |
| EXACTLY_EIGHT_S14_GPIM_VARIABLES_AUTHORIZED | PASS | The planning registry contains the exact eight S14 variable IDs. |
| COMPONENT_AND_AGGREGATE_ROLES_PRESERVED | PASS | ME/NRC components remain available and the aggregate is separately tagged as derived scale. |
| AGGREGATION_RULE_STATED | PASS | `K_GROSS_GPIM_TOTAL = K_GROSS_GPIM_ME + K_GROSS_GPIM_NRC` in `millions_2017`. |
| COMMON_SUPPORT_ISSUE_STATED | PASS | Conservative aggregate support begins in 1931; partial-support sums are prohibited. |
| THETA_NOT_ESTIMATED_IN_S20 | PASS | S20 is limited to input architecture and emits no coefficient or reconstructed object. |
| WAGE_SHARE_MARKED_PREFERRED | PASS | Unadjusted wage share is the preferred conditional distribution input. |
| SHAIKH_ADJUSTMENT_CONDITIONAL_OR_BLOCKED | PASS | Adjustment is blocked unless both current-release data and a semantic/accounting crosswalk exist. |
| FRONTIER_CONDITIONERS_EXCLUDED_FROM_BASELINE | PASS | IPP and government transportation are future control candidates only. |
| ACCUMULATED_Q_REMAINS_PARKED | PASS | S20 constructs no accumulated $q$ and does not authorize S21. |
| EXISTING_VAULT_NOTES_UNMODIFIED | PASS | This planning layer creates files only under the new S20 planning output directory. |
| NO_PROVIDER_FILES_ACCESSED_OR_MODIFIED | PASS | Planning consumed only S14 and S15 output artifacts. |
| NO_GPIM_RECONSTRUCTION | PASS | No GPIM construction or data transformation ran. |
| NO_DOWNSTREAM_SCRIPTS_INVOKED | PASS | No S20, S21, S22, S31I, S30, or S32 script was invoked. |
| NO_ECONOMETRICS_RUN | PASS | No estimator, test, coefficient, or model object was created. |
| PLANNING_REPORT_CREATED | PASS | Markdown planning report and CSV decision ledger were created. |
| FINAL_DECISION_EXPLICIT | PASS | The decision below is one of the permitted planning outcomes. |

## Final Decision

**AUTHORIZE_S20_IMPLEMENTATION_PROMPT**

This permits preparation of a bounded implementation prompt, not implementation itself. S21, S22, S31I, S30, and S32 remain closed.
