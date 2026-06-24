---
type: codex_parallel_execution_contract
project: dissertation_chapter_2
phase: data_construction_closure
stage: S30_parallel_execution
status: active
repository: "C:\\ReposGitHub\\Capacity-Utilization-US_Chile"
exact_base_commit: 911885ce763fdf4b73903ebb552682cfb108d0b3
parallel_task_count: 4
upstream_stage: S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING
upstream_validation: PASS_84
upstream_decision: AUTHORIZE_S30A_S30B_S30C_S30D_PARALLEL_DATA_CLOSURE_EXECUTION
---

# S30 Common Execution Contract

## Purpose

This note is the common execution contract for S30A, S30B, S30C, and S30D. All four Codex Cloud tasks must branch from the same exact S29L commit, run independently, write to non-overlapping namespaces, commit and push only their own assigned branch, never merge themselves into `main`, and return the standardized report and machine-readable completion record defined here.

The exact base commit is:

```text
911885ce763fdf4b73903ebb552682cfb108d0b3
```

Floating `main` is not an acceptable base.

## Chapter 2 Conceptual And Measurement Locks

All S30 tasks must preserve these locks:

- `μ_t` = capacity utilization = Y/Y^p; never use `u`.
- `χ_t` = recapitalization rate = I/Π; never use `β_t`.
- `q` = mechanization growth rate; never use `m` for mechanization because `m` is import share or propensity.
- `θ_t = θ₁ + θ₂π_t` = distribution-conditioned transformation elasticity.
- `K^NR` = nonresidential structures.
- `K^ME` = machinery and equipment.
- Uppercase variables are levels; lowercase variables are log-levels; dot notation is for growth rates.
- Use MPF, not IPF.
- Use Harrodian benchmark, not natural rate of growth.
- `β_j` is reserved for cointegrating vectors and Layer-2 coefficients only.

## Task Matrix

| Task | Branch | Exclusive code ownership | Exclusive output ownership |
| --- | --- | --- | --- |
| S30A | `feature/s30a-output-family-closure` | `codes/US_S30A*` | `output/US/S30A*` |
| S30B | `feature/s30b-distribution-family-closure` | `codes/US_S30B*` | `output/US/S30B*` |
| S30C | `feature/s30c-contextual-family-lock` | `codes/US_S30C*` | `output/US/S30C*` |
| S30D | `feature/s30d-dataset-release-scaffold` | `codes/US_S30D*` | `output/US/S30D*` |

## Mandatory Task Preflight

Every task must begin in `C:\ReposGitHub\Capacity-Utilization-US_Chile` and run:

```bash
git branch --show-current
git rev-parse HEAD
git status --short
```

Required state:

```text
branch = assigned feature branch
HEAD = 911885ce763fdf4b73903ebb552682cfb108d0b3
```

If either branch or `HEAD` fails, stop immediately with:

```text
STOP_BASE_OR_BRANCH_MISMATCH
```

Do not run the task from floating `main`; do not accept a branch whose base differs from the exact S29L commit.

## Allowed Inputs

Tasks may read committed repository evidence and the S29L planning package under:

```text
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/
```

Task-specific prompts define additional allowed upstream evidence. Provider repositories are read-only unless a task prompt explicitly authorizes discovery; none of S30A, S30B, S30C, or S30D authorizes provider mutation.

## Shared No-Go Rules

All four S30 tasks must prohibit:

- floating `main` as a base;
- edits outside assigned ownership;
- edits to another S30 namespace;
- edits to S29L or earlier outputs;
- provider-repository modifications;
- changes to `chapter2_vault/.obsidian/workspace.json`;
- staging `data/provider_handoffs/`;
- cross-family joins;
- canonical dataset construction;
- complete-case samples;
- estimation samples;
- construction of `q`;
- omega-weighted capital variables;
- distribution-capital interactions;
- construction of `theta` or `θ_t`;
- productive capacity;
- utilization or `μ_t` construction;
- modeling;
- econometrics;
- branch self-merging.

## Forbidden Paths

Every task must leave these paths untouched and unstaged:

```text
chapter2_vault/.obsidian/workspace.json
data/provider_handoffs/
```

Every task must also leave S29L and earlier outputs untouched:

```text
output/US/S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING/
output/US/S29*
output/US/S28*
output/US/S27*
output/US/S26*
output/US/S25*
output/US/S24*
output/US/S23*
output/US/S22*
output/US/S21*
```

Earlier outputs may be read as inputs where a task prompt allows them; they must not be modified.

## Shared Git Discipline

Each S30 task must:

- stage only assigned task files;
- inspect `git diff --cached --name-only`;
- run `git diff --cached --check`;
- commit only after task validation passes;
- push only the assigned feature branch;
- not open or merge a pull request unless the user later requests it;
- report the result commit.

Do not merge into `main`.

## Standardized Report Contract

Every task final report must include these fields:

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

Every task must create a machine-readable completion record with these fields:

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

## Final Decision Logic

Each task may return a consumption authorization only if all task-specific validation checks pass, the exact branch and base are verified, only assigned namespaces changed, no prohibited object was created, and the completion record is written.

If any required boundary, classification, schema, or source rule cannot be resolved from committed evidence, the task must stop with the task-specific block decision and must not create a substitute architecture.

## Merge Policy

S30 tasks never merge themselves. The downstream human-controlled merge order is:

```text
S30A
    ↓ validate after merge
S30B
    ↓ validate after merge
S30C
    ↓ validate after merge
S30D
    ↓ validate scaffold
S30E integrated dataset closure and canonical assembly
    ↓ validate canonical dataset
S30F dataset release freeze and downstream dataset-consumption authorization
    ↓
S31 diagnostic work begins; S31I is integration-order testing
```

No automatic merge is authorized.
