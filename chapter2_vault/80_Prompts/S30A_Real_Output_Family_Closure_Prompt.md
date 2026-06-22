---
type: codex_cloud_task_prompt
project: dissertation_chapter_2
phase: data_construction_closure
stage: S30A
task_id: S30A_REAL_OUTPUT_FAMILY_CLOSURE
status: ready_to_launch
repository: "C:\\ReposGitHub\\Capacity-Utilization-US_Chile"
assigned_branch: feature/s30a-output-family-closure
exact_base_commit: 911885ce763fdf4b73903ebb552682cfb108d0b3
upstream_stage: S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING
upstream_validation: PASS_84
upstream_decision: AUTHORIZE_S30A_S30B_S30C_S30D_PARALLEL_DATA_CLOSURE_EXECUTION
parallel_execution: true
merge_into_main: false
---

# S30A Real Output Family Closure Prompt

## Assignment

Work in:

```text
C:\ReposGitHub\Capacity-Utilization-US_Chile
```

Task:

```text
S30A_REAL_OUTPUT_FAMILY_CLOSURE
```

Assigned branch:

```text
feature/s30a-output-family-closure
```

Exact base commit:

```text
911885ce763fdf4b73903ebb552682cfb108d0b3
```

Exclusive write ownership:

```text
codes/US_S30A*
output/US/S30A*
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
branch = feature/s30a-output-family-closure
HEAD = 911885ce763fdf4b73903ebb552682cfb108d0b3
```

If either check fails, stop with:

```text
STOP_BASE_OR_BRANCH_MISMATCH
```

## Purpose

Close the real/effective-output data family from currently committed repository evidence. S30A must determine and lock:

- authoritative output concept;
- sector boundary;
- nominal versus real status;
- official real-output availability;
- required price or deflator treatment;
- reference year;
- unit;
- coverage;
- support window;
- authoritative level;
- authoritative log representation;
- robustness or diagnostic alternatives;
- aliases;
- downstream contract;
- interface;
- independent validation;
- handoff;
- consumer intake.

The acceptance target is:

```text
OUTPUT_FAMILY_CLOSED_CONSUMABLE
```

The final decision may authorize later cross-family closure auditing. It must not authorize a cross-family join.

## Required Inputs

Read the S29L planning package and committed upstream evidence, including:

```text
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/md/S29L_TASK_A_REAL_OUTPUT_FAMILY_CLOSURE.md
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

Also read S21-S28 source and construction-planning outputs relevant to output, S24A/S24C/S25/S26 source panels and completeness reviews as relevant, any currently committed output-related construction outputs, provider V1 handoff copies already imported downstream, and existing output-related vault specifications only when needed for conceptual locks.

The provider repository remains read-only and should not be required for new discovery.

## Boundary Rule

Do not silently choose a sector or real-output treatment merely because a series is available. Explicitly reconcile:

- actual observed output;
- effective-demand-realized output;
- productive capacity as latent;
- output is not productive capacity;
- productive capacity and utilization are not constructed here.

If repository evidence cannot resolve the authoritative output boundary or deflator rule, stop with:

```text
BLOCK_FOR_OUTPUT_BOUNDARY_REVIEW
```

Do not invent a choice.

## Internal Stage Sequence

Implement a bounded family chain within the S30A namespace, for example:

```text
S30A1 output source and boundary review
    ↓
S30A2 authorized output construction, only if needed
    ↓
S30A3 analytical representation review
    ↓
S30A4 readiness review
    ↓
S30A5 downstream selection contract
    ↓
S30A6 interface assembly
    ↓
S30A7 independent validation and handoff
    ↓
S30A8 consumer intake
```

You may adapt internal numbering if repository conventions require it, but every stage and file must remain under `S30A`.

## Required Outputs

Create S30A outputs only under `output/US/S30A*` and scripts only under `codes/US_S30A*`. Required outputs:

- family readiness inventory;
- authoritative-variable ledger;
- construction ledger if construction was required;
- unit and reference-year ledger;
- support-window ledger;
- contract-status ledger;
- interface manifest;
- source-copy audit;
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
- edit outside `codes/US_S30A*` and `output/US/S30A*`;
- edit any other S30 namespace;
- edit S29L or earlier outputs;
- modify provider repositories;
- change `chapter2_vault/.obsidian/workspace.json`;
- stage `data/provider_handoffs/`;
- edit capital-family files;
- edit distribution-family files;
- edit contextual-family files;
- join output to capital;
- join output to distribution;
- join output to contextual variables;
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
- upstream S29L gate verification;
- authoritative concept explicit;
- sector boundary explicit;
- nominal/real status explicit;
- deflator rule explicit;
- reference year explicit;
- level and log roles explicit;
- support window explicit;
- source-copy residual equals zero where values are copied;
- no complete-case sample;
- no estimation sample;
- no cross-family join;
- no canonical dataset;
- no capacity or utilization construction;
- no `q`;
- no `theta`;
- no modeling;
- no econometrics.

## Final Decision Logic

Return `AUTHORIZE_OUTPUT_FAMILY_CONSUMPTION` only if validation passes and the family status is `OUTPUT_FAMILY_CLOSED_CONSUMABLE`. If the output boundary or deflator rule remains unresolved, return `BLOCK_FOR_OUTPUT_BOUNDARY_REVIEW`.

## Git Closure

After validation passes:

```bash
git status --short
git add -- codes/US_S30A* output/US/S30A*
git diff --cached --name-only
git diff --cached --check
git commit -m "Close real output data family"
git push origin feature/s30a-output-family-closure
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
