---
type: codex_cloud_task_prompt
project: dissertation_chapter_2
phase: data_construction_closure
stage: S30C
task_id: S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK
status: ready_to_launch
repository: "C:\\ReposGitHub\\Capacity-Utilization-US_Chile"
assigned_branch: feature/s30c-contextual-family-lock
exact_base_commit: 911885ce763fdf4b73903ebb552682cfb108d0b3
upstream_stage: S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING
upstream_validation: PASS_84
upstream_decision: AUTHORIZE_S30A_S30B_S30C_S30D_PARALLEL_DATA_CLOSURE_EXECUTION
parallel_execution: true
merge_into_main: false
---

# S30C Contextual Family Classification Lock Prompt

## Assignment

Work in:

```text
C:\ReposGitHub\Capacity-Utilization-US_Chile
```

Task:

```text
S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK
```

Assigned branch:

```text
feature/s30c-contextual-family-lock
```

Exact base commit:

```text
911885ce763fdf4b73903ebb552682cfb108d0b3
```

Exclusive write ownership:

```text
codes/US_S30C*
output/US/S30C*
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
branch = feature/s30c-contextual-family-lock
HEAD = 911885ce763fdf4b73903ebb552682cfb108d0b3
```

If either check fails, stop with:

```text
STOP_BASE_OR_BRANCH_MISMATCH
```

## Purpose

Inventory and lock the status of contextual, non-core, metadata-only, parked, blocked, and excluded objects.

At minimum audit:

- IPP assets and investment;
- government transportation;
- highways and streets;
- transportation structures;
- other government fixed assets;
- residential objects;
- provider TOTAL;
- review-required fixed-assets objects;
- metadata-only objects;
- blocked objects;
- parked objects.

The acceptance target is:

```text
CONTEXTUAL_FAMILY_CLASSIFICATION_LOCKED
```

The final decision may authorize inclusion in a later canonical dataset only as appropriately classified references. It must not authorize actual integration or model controls.

## Conceptual Locks

Preserve exactly:

```text
K^ME and K^NR = core capacity-building capital
IPP = contextual or productive-frontier-shaping; not core accumulation capital
government transportation = contextual or frontier-conditioning; not core accumulation capital
residential = excluded from productive capital
provider TOTAL = not analytical downstream TOT
metadata-only = must remain metadata-only
blocked = must remain blocked unless separately authorized
```

## Required Inputs

Read:

```text
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_TASK_C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_PARALLEL_FANOUT_EXECUTION_GUIDE.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLAN.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_VALIDATION.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_DECISION.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_family_readiness_inventory.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_unresolved_dependency_ledger.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_review_needed_ledger.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_registry.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_input_contract.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_output_contract.csv
```

Also read committed contextual and fixed-assets evidence from S22, S24B, S24C, S25, S26, S27, S28, and S29K as needed. Do not mutate those inputs.

## Allowed Classifications

Every contextual object must receive exactly one:

```text
CONTEXTUAL_AUTHORIZED
DIAGNOSTIC_ONLY
METADATA_REFERENCE_ONLY
PARKED_FOR_FUTURE_RESEARCH
EXCLUDED_FROM_CHAPTER2_DATASET
BLOCKED
```

If any object cannot be classified from committed evidence, stop with:

```text
BLOCK_FOR_CONTEXTUAL_CLASSIFICATION_REVIEW
```

## Allowed Work

S30C may:

- inventory objects;
- verify observation-bearing versus metadata-only status;
- classify theoretical role;
- create a contextual reference contract;
- create reference-only interfaces where authorized;
- independently validate classifications and source references;
- create a handoff.

## Required Outputs

Create S30C outputs only under `output/US/S30C*` and scripts only under `codes/US_S30C*`. Required outputs:

- contextual inventory;
- observation/metadata status ledger;
- theoretical-role ledger;
- classification contract;
- contextual reference interface manifest;
- exclusion ledger;
- parked ledger;
- blocked ledger;
- provider-TOTAL nonpromotion audit;
- core-capital boundary audit;
- independent validation;
- handoff manifest;
- review-needed ledger;
- validation checks;
- decision document;
- common completion record.

## Prohibitions

Do not:

- use floating `main` as a base;
- edit outside `codes/US_S30C*` and `output/US/S30C*`;
- edit any other S30 namespace;
- edit S29L or earlier outputs;
- modify provider repositories;
- change `chapter2_vault/.obsidian/workspace.json`;
- stage `data/provider_handoffs/`;
- modify core capital;
- add IPP to core capital;
- add government transportation to core capital;
- promote residential objects into productive capital;
- promote provider TOTAL into analytical downstream TOT;
- promote metadata-only objects;
- promote blocked objects;
- assign productive-efficiency weights;
- construct controls for a model;
- join contextual variables with capital;
- join contextual variables with output;
- join contextual variables with distribution;
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
- exclusive namespace;
- complete contextual inventory;
- one status per object;
- IPP not core;
- government transportation not core;
- residential excluded from productive capital;
- provider TOTAL not promoted;
- metadata-only not promoted;
- blocked objects not promoted;
- no family joins;
- no model controls created;
- no canonical dataset;
- no complete-case sample;
- no estimation sample;
- no `q`;
- no `theta`;
- no productive capacity;
- no utilization;
- no modeling;
- no econometrics.

## Final Decision Logic

Return `AUTHORIZE_CONTEXTUAL_REFERENCE_CONSUMPTION` only if validation passes and the family status is `CONTEXTUAL_FAMILY_CLASSIFICATION_LOCKED`. If classification cannot be completed without violating the conceptual locks, return `BLOCK_FOR_CONTEXTUAL_CLASSIFICATION_REVIEW`.

## Git Closure

After validation passes:

```bash
git status --short
git add -- codes/US_S30C* output/US/S30C*
git diff --cached --name-only
git diff --cached --check
git commit -m "Lock contextual data family classifications"
git push origin feature/s30c-contextual-family-lock
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
