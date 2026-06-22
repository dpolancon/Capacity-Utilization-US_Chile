# S30 Merge-Readiness Controller

This controller performs a dry-run audit for the S30 integration sequence. It checks remote branch tips, task-owned changed paths, committed completion evidence, expected task decisions and statuses, and a temporary sequential merge simulation.

The remote branch tip is the authoritative result commit for each S30 task. Completion records may be created before the final Git commit exists, so a missing, pending, unavailable, or placeholder result-commit value in a completion record does not block readiness. A contradictory explicit commit hash in a completion record still requires human review.

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

## Apply Controller

`Test-S30MergeReadiness.ps1` is audit-only and never changes `main`.

`Invoke-S30SequentialIntegration.ps1` is the explicit apply controller. It first reruns the dry-run readiness controller and proceeds only when that audit authorizes controlled S30 integration. It creates a temporary integration worktree outside the normal checkout, merges S30A, S30B, S30C, and S30D in that order, validates each uncommitted merge, and pushes only the validated merge commit to `origin/main`.

Run the apply controller only with the exact confirmation token:

```powershell
.\automation\chapter2\Invoke-S30SequentialIntegration.ps1 `
  -Apply `
  -Confirmation "APPLY_S30_SEQUENTIAL_INTEGRATION"
```

It stops without applying if the readiness audit fails, `origin/main` diverges, a feature tip differs from the plan, a merge conflicts, a forbidden path appears, completion evidence fails, or the confirmation token is missing. It never force-pushes, never modifies S30 feature branches, and never uses the normal `main` checkout for merging.
