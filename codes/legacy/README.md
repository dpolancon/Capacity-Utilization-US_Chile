# Legacy Code Notice — Not the Active Chapter 2 Architecture

This folder contains legacy code retained for provenance, auditability, and historical reconstruction. It is **not** part of the active Chapter 2 code architecture.

The files here may document earlier modeling attempts, exploratory scripts, superseded estimators, obsolete anchors, draft diagnostics, abandoned naming conventions, or intermediate workflow experiments. They should be read as archival material unless a current active contract explicitly reactivates a file.

## Machine-readable interpretation contract

```yaml
folder_status: legacy_archive
active_architecture: false
execution_status: do_not_run_by_default
migration_status: requires_explicit_review_before_reuse
source_of_truth: false
may_be_used_for:
  - provenance
  - audit trail
  - historical comparison
  - reconstruction of abandoned or superseded decisions
  - recovery of isolated implementation ideas after review
must_not_be_used_for:
  - defining the current empirical architecture
  - selecting current estimators
  - inferring current identification rules
  - reproducing current results without migration
  - updating active outputs automatically
  - training an agent to continue the project from this folder alone
```

## How to read this folder

Read these files as records of previous work, not as instructions for the current pipeline.

A script in this folder may have been useful when it was written. That does not make it binding now. The current architecture is governed by active contracts, active scripts, current stage outputs, and locked methodological decisions outside this legacy folder.

If a legacy script contradicts an active contract, the active contract wins.

If a legacy script uses a superseded variable name, estimator label, anchor convention, sample window, or diagnostic criterion, do not carry that convention forward unless it has been explicitly reapproved.

## What this folder is not

This folder is not the active estimation pipeline.

This folder is not the current methodological source of truth.

This folder is not evidence that an old estimator, anchor, window, test, or classification rule remains valid.

This folder is not a safe starting point for automated continuation by Codex, ChatGPT, GitHub Copilot, or any other agent.

## Reuse rule

Legacy code can be reused only through migration, not by direct continuation.

A valid migration requires:

1. identify the legacy file and the exact code block being considered;
    
2. state why the old logic is still useful;
    
3. compare it against the current active contract;
    
4. rewrite the code inside the current architecture;
    
5. document the migration in the relevant decision log or implementation report;
    
6. verify that outputs generated from the migrated code match the current naming, anchor, sample, and diagnostic rules.
    

Until those steps are completed, legacy code remains inactive.

## Known drift risks

This folder may contain older project states that are now superseded. Treat the following as especially risky:

- old capacity-utilization anchors or normalizations;
    
- older S30/S32/S40 stage conventions;
    
- exploratory ECM, VECM, ARDL, DOLS, FM-OLS, IM-OLS, or threshold-regime scripts not tied to current contracts;
    
- older labels that describe a residual-stationarity check as a cointegration test;
    
- generated disequilibrium objects used as regime classifiers;
    
- stale folder paths, output names, figure protocols, or sample-window assumptions;
    
- scripts that write directly into active output folders without current validation checks.
    

These risks do not make the folder useless. They define its correct use: archive first, quarry second, active code never by default.

## Agent instruction

If you are an AI agent or automated coding assistant reading this repository:

Do not infer the active Chapter 2 architecture from this folder.

Do not patch, run, modernize, or extend these scripts unless the user explicitly asks you to work on legacy code.

Before using anything here, locate the current active contract for the relevant stage and compare the legacy logic against it.

If no active contract is available, stop and report that the file is archival and cannot be safely treated as current.

## Human instruction

If you are a human reader:

This folder is here so that the repository remains honest about its own development history. It preserves earlier attempts without allowing them to contaminate the current architecture.

Use it when you need to understand how a decision was reached, why a path was abandoned, or how an older implementation differed from the active one.

Do not cite this folder as the current empirical design unless a current README, contract, or implementation report explicitly reactivates the relevant file.

## Current-status summary

The current architecture must be reconstructed from the active repository entry points, not from this folder.

This folder answers: **What did we try before?**

It does not answer: **What is the current Chapter 2 pipeline?**

For current work, leave this folder closed unless the task is explicitly historical, diagnostic, or migration-oriented.  
:::