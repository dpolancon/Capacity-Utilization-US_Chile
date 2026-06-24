---
type: codex_cloud_task_prompt
project: dissertation_chapter_2
phase: data_construction_closure
stage: S30D
task_id: S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD
status: ready_to_launch
repository: "C:\\ReposGitHub\\Capacity-Utilization-US_Chile"
assigned_branch: feature/s30d-dataset-release-scaffold
exact_base_commit: 911885ce763fdf4b73903ebb552682cfb108d0b3
upstream_stage: S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING
upstream_validation: PASS_84
upstream_decision: AUTHORIZE_S30A_S30B_S30C_S30D_PARALLEL_DATA_CLOSURE_EXECUTION
parallel_execution: true
merge_into_main: false
---

# S30D Dataset Release Schema Scaffold Prompt

## Assignment

Work in:

```text
C:\ReposGitHub\Capacity-Utilization-US_Chile
```

Task:

```text
S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD
```

Assigned branch:

```text
feature/s30d-dataset-release-scaffold
```

Exact base commit:

```text
911885ce763fdf4b73903ebb552682cfb108d0b3
```

Exclusive write ownership:

```text
codes/US_S30D*
output/US/S30D*
```

Do not write into shared final release directories during this task. Do not merge into `main`. Do not use floating `main` as a base.

## Mandatory Preflight

Begin with:

```bash
git branch --show-current
git rev-parse HEAD
git status --short
```

Required:

```text
branch = feature/s30d-dataset-release-scaffold
HEAD = 911885ce763fdf4b73903ebb552682cfb108d0b3
```

If either check fails, stop with:

```text
STOP_BASE_OR_BRANCH_MISMATCH
```

## Purpose

Create schema-only and zero-row infrastructure for the later canonical Chapter 2 dataset release.

S29L found 11 release-infrastructure items classified as absent. Verify the exact list from S29L before creating the authorized scaffold.

The acceptance target is:

```text
DATASET_RELEASE_SCAFFOLD_READY
```

The final decision may authorize later use by S30E-S30F. It must not authorize canonical assembly.

## Required Inputs

Read:

```text
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_TASK_D_DATASET_RELEASE_SCHEMA_SCAFFOLD.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_PARALLEL_FANOUT_EXECUTION_GUIDE.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLAN.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_VALIDATION.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_DECISION.md
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_release_infrastructure_readiness.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_unresolved_dependency_ledger.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_registry.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_input_contract.csv
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/csv/S29L_parallel_task_output_contract.csv
```

Also read S29K and S29L contract evidence as schema references only. Do not mutate family outputs.

## Allowed Scaffold Objects

At minimum create schema-only or zero-row templates for:

- canonical long-panel schema;
- canonical wide consultation-panel schema;
- variable dictionary schema;
- provenance ledger schema;
- admissibility ledger schema;
- support-window ledger schema;
- family-interface registry schema;
- release-manifest schema;
- SHA-256 integrity-manifest schema;
- family-source copy-validation schema;
- duplicate-key audit schema;
- unit-consistency audit schema;
- support-window audit schema;
- missingness audit schema;
- handoff template;
- validation template;
- decision template.

## Zero-Row Rule

All dataset-like artifacts must be:

```text
schema-only
```

or:

```text
zero-row templates
```

Avoid synthetic example rows. If examples are necessary for documentation, place them in Markdown only and label them clearly as non-data examples.

## Schema Requirements

The canonical long schema must support fields such as:

```text
year
variable_id
value
unit
family_id
contract_status
analytical_role
source_stage
source_commit
source_file
coverage_start
coverage_end
first_fully_supported_year
support_status
baseline_window_eligible
warmup_observation
authoritative_variable_id
provenance_id
```

The variable dictionary must support:

```text
variable_id
display_name
family_id
concept
definition
unit
reference_year
transformation
asset_or_sector_scope
contract_status
analytical_role
authoritative_variable_id
baseline_or_robustness
support_start
support_end
source_stage
source_commit
notes
```

The release manifest must support:

```text
relative_path
file_role
row_count
column_count
file_size_bytes
sha256
source_stage
release_status
```

## Required Outputs

Create S30D outputs only under `output/US/S30D*` and scripts only under `codes/US_S30D*`. Required outputs:

- schema registry;
- zero-row long template;
- zero-row wide template or wide-schema specification;
- zero-row variable dictionary;
- zero-row provenance ledger;
- zero-row admissibility ledger;
- zero-row support-window ledger;
- zero-row family-interface registry;
- zero-row release manifest;
- zero-row integrity manifest;
- validation-rule registry;
- audit-specification registry;
- handoff template;
- validation template;
- decision template;
- scaffold validation checks;
- review-needed ledger;
- common completion record.

## Prohibitions

Do not:

- use floating `main` as a base;
- edit outside `codes/US_S30D*` and `output/US/S30D*`;
- edit any other S30 namespace;
- edit S29L or earlier outputs;
- modify family outputs;
- modify provider repositories;
- change `chapter2_vault/.obsidian/workspace.json`;
- stage `data/provider_handoffs/`;
- copy live family observations;
- join any family;
- construct a canonical dataset;
- choose authoritative variables beyond existing contracts;
- create complete-case samples;
- create estimation samples;
- calculate final release hashes;
- create a release candidate;
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
- S29L infrastructure-gap list consumed;
- all required schemas present;
- all schemas have required keys;
- no live observations copied;
- all dataset templates contain zero rows;
- no joins;
- no authoritative variable selection;
- no complete-case sample;
- no estimation sample;
- no release candidate;
- no final hashes;
- no family output mutation;
- no canonical dataset;
- no `q`;
- no `theta`;
- no productive capacity;
- no utilization;
- no modeling;
- no econometrics.

## Final Decision Logic

Return `AUTHORIZE_DATASET_RELEASE_SCAFFOLD_CONSUMPTION` only if validation passes and the family status is `DATASET_RELEASE_SCAFFOLD_READY`. If required schemas cannot be created as zero-row/schema-only artifacts, return `BLOCK_FOR_RELEASE_SCAFFOLD_REVIEW`.

## Git Closure

After validation passes:

```bash
git status --short
git add -- codes/US_S30D* output/US/S30D*
git diff --cached --name-only
git diff --cached --check
git commit -m "Build Chapter 2 dataset release scaffold"
git push origin feature/s30d-dataset-release-scaffold
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
