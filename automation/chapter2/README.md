# S30 Merge-Readiness Controller

This controller performs a dry-run audit for the S30 integration sequence. It checks remote branch tips, task-owned changed paths, committed completion evidence, expected task decisions and statuses, and a temporary sequential merge simulation.

It does not merge `main`, push `main`, modify the four S30 feature branches, open a pull request, or begin S31A. The first version is audit-only.

Run it from the repository worktree:

```powershell
.\automation\chapter2\Test-S30MergeReadiness.ps1
```

Exit codes:

- `0`: `AUTHORIZE_CONTROLLED_S30_SEQUENTIAL_INTEGRATION`
- `2`: `HUMAN_REVIEW_REQUIRED`
- `1`: `TECHNICAL_FAILURE`

Audit outputs are written to:

```text
output/US/S30_MERGE_READINESS_AUDIT/
```

The Markdown report and decision files summarize the result without requiring the reader to inspect the PowerShell code.
