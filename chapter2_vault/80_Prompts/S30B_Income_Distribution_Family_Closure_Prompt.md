---
type: codex_cloud_task_prompt
project: dissertation_chapter_2
phase: data_construction_closure
stage: S30B
task_id: S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE
status: ready_to_launch
repository: "C:\\ReposGitHub\\Capacity-Utilization-US_Chile"
assigned_branch: feature/s30b-distribution-family-closure
exact_base_commit: 911885ce763fdf4b73903ebb552682cfb108d0b3
upstream_stage: S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING
upstream_validation: PASS_84
upstream_decision: AUTHORIZE_S30A_S30B_S30C_S30D_PARALLEL_DATA_CLOSURE_EXECUTION
parallel_execution: true
merge_into_main: false
---

# S30B Income Distribution Family Closure Prompt

## Assignment

Work in:

```text
C:\ReposGitHub\Capacity-Utilization-US_Chile
```

Task:

```text
S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE
```

Assigned branch:

```text
feature/s30b-distribution-family-closure
```

Exact base commit:

```text
911885ce763fdf4b73903ebb552682cfb108d0b3
```

Exclusive write ownership:

```text
codes/US_S30B*
output/US/S30B*
```

Do not merge into `main`. Do not use floating `main` as a base.

## Mandatory Preflight

Begin with:

```bash
git branch --show-current
git rev-parse HEAD
git status --short
```

Required:

```text
branch = feature/s30b-distribution-family-closure
HEAD = 911885ce763fdf4b73903ebb552682cfb108d0b3
```

If either check fails, stop with:

```text
STOP_BASE_OR_BRANCH_MISMATCH
```

## Locked Upstream Facts

Verify S29A from repository evidence, not only these expected values:

```text
stage = S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION
constructed variables = 8
constructed rows = 776
coverage = 1929-2025
validation = PASS 57
```

If the S29A gate cannot be verified, stop with:

```text
BLOCK_FOR_S29A_GATE_REVIEW
```

## Theoretical Hierarchy

Preserve:

```text
preferred representation = wage share
alternative representation = exploitation rate
Shaikh-adjusted variables = blocked unless separately authorized
profit-related and complementary representations = diagnostic or robustness according to committed evidence
```

Do not construct new Shaikh-adjusted series.

## Purpose

Close the already constructed distribution family through:

```text
readiness review
    ↓
primary and robustness classification
    ↓
support-window contract
    ↓
downstream selection contract
    ↓
interface assembly
    ↓
independent validation
    ↓
handoff
    ↓
consumer intake
```

The acceptance target is:

```text
DISTRIBUTION_FAMILY_CLOSED_CONSUMABLE
```

The final decision may authorize cross-family closure auditing. It must not authorize actual integration.

## Required Inputs

Read:

```text
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_TASK_B_INCOME_DISTRIBUTION_FAMILY_CLOSURE.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_PARALLEL_FANOUT_EXECUTION_GUIDE.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLAN.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_VALIDATION.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_DECISION.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_family_readiness_inventory.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_unresolved_dependency_ledger.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_registry.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_input_contract.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_output_contract.csv
```

Also read S29A scripts and outputs, relevant S24A, S25, S26, S27, and S28 evidence, blocked/parked ledgers, current distribution-related conceptual locks, and Shaikh admissibility restrictions already committed downstream.

Do not reopen provider discovery.

## Required Classifications

Every constructed distribution variable must receive one status:

```text
BASELINE_AUTHORIZED
ROBUSTNESS_AUTHORIZED
CONDITIONAL_SECONDARY
DIAGNOSTIC_ONLY
ALIAS_INTERFACE_ONLY
BLOCKED
```

No variable may remain unclassified.

## Critical Restrictions

Require:

- wage-share preference remains explicit;
- exploitation rate remains alternative unless repository evidence authorizes otherwise;
- blocked Shaikh-adjusted variables remain blocked;
- aliases are not independent objects;
- complementary shares are not jointly treated as independent without explicit authorization;
- no distribution-capital interaction is constructed.

## Required Outputs

Create S30B outputs only under `output/US/S30B*` and scripts only under `codes/US_S30B*`. Required outputs:

- readiness inventory;
- authoritative-variable selection ledger;
- robustness ledger;
- diagnostic ledger;
- blocked-object ledger;
- alias-authority map;
- support-window contract;
- downstream variable contract;
- interface manifest;
- value-copy audit;
- independent validation;
- consumer registry;
- handoff manifest;
- review-needed ledger;
- validation checks;
- decision document;
- common completion record.

## Prohibitions

Do not:

- use floating `main` as a base;
- edit outside `codes/US_S30B*` and `output/US/S30B*`;
- edit any other S30 namespace;
- edit S29L or earlier outputs;
- modify provider repositories;
- change `chapter2_vault/.obsidian/workspace.json`;
- stage `data/provider_handoffs/`;
- construct new Shaikh-adjusted variables;
- treat aliases as independent objects;
- construct complementary shares as independent objects without explicit authorization;
- join distribution to capital;
- join distribution to output;
- join distribution to contextual variables;
- create canonical dataset artifacts;
- create complete-case samples;
- create estimation samples;
- construct `q`;
- construct omega-weighted capital variables;
- construct distribution-capital interactions;
- construct `theta` or `θ_t`;
- construct productive capacity;
- construct utilization or `μ_t`;
- run modeling;
- run econometrics;
- self-merge the branch.

## Validation Checks

Validation must verify:

- exact branch and base commit;
- S29A gate verification;
- exclusive namespace;
- all eight constructed variables accounted for;
- wage-share preference preserved;
- exploitation-rate alternative preserved;
- no Shaikh-adjusted construction;
- support windows explicit;
- aliases controlled;
- zero copy residual where interface values are copied;
- no cross-family joins;
- no interactions;
- no complete-case sample;
- no estimation sample;
- no canonical dataset;
- no `q`;
- no `theta`;
- no productive capacity;
- no utilization;
- no modeling;
- no econometrics.

## Final Decision Logic

Return `AUTHORIZE_DISTRIBUTION_FAMILY_CONSUMPTION` only if validation passes and the family status is `DISTRIBUTION_FAMILY_CLOSED_CONSUMABLE`. If the S29A gate, variable classification, Shaikh block, or support contract cannot be verified, return a block decision and do not create a substitute hierarchy.

## Git Closure

After validation passes:

```bash
git status --short
git add -- codes/US_S30B* output/US/S30B*
git diff --cached --name-only
git diff --cached --check
git commit -m "Close income distribution data family"
git push origin feature/s30b-distribution-family-closure
```

Stage only assigned task files. Do not merge into `main`. Do not open a pull request unless the user later requests it.

## Standardized Report Contract

Final report fields:

```text
task_id
branch
exact_base_commit
upstream_stages_consumed
files_read
scripts_created
output_directory
authoritative_variables
robustness_variables
conditional_variables
diagnostic_variables
alias_variables
metadata_only_objects
blocked_variables
review_required_variables
validation_result
final_decision
family_status
files_changed
result_commit
push_status
final_branch_status
other_task_namespaces_untouched
provider_repository_untouched
```

## Machine-Readable Completion Record

Create a completion record with:

```text
stage_id
task_id
branch
base_commit
result_commit
validation_status
decision
family_status
authoritative_variable_count
robustness_variable_count
conditional_variable_count
diagnostic_variable_count
alias_variable_count
metadata_only_count
blocked_variable_count
review_required_count
handoff_ready
consumer_intake_ready
```
