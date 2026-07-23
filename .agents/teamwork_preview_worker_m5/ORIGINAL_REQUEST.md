## 2026-07-23T20:18:45Z
<USER_REQUEST>
You are Worker for Milestone 5 (R4: Automated Verification Script).

Working Directory: c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_worker_m5
Project Root: c:\ReposGitHub\Capacity-Utilization-US_Chile

DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Task Instructions:
1. Create `tests/verify_repo_tidy.R` (and a python wrapper/runner `tests/verify_repo_tidy.py` if needed) at `c:\ReposGitHub\Capacity-Utilization-US_Chile\tests\verify_repo_tidy.R`. Ensure the `tests/` directory is created if it does not exist.
2. The script must programmatically perform and report on the following 3 checks:
   - Check 1: Verify `codes/` directory contains no nested subdirectories other than `legacy/` and `runs/`.
   - Check 2: Verify `data/metadata/data_provenance_manifest.md` exists and parses cleanly as valid YAML containing all 6 mandatory fields (`type`, `status`, `depends_on`, `stage_scope`, `country`, `last_updated`).
   - Check 3: Verify all active vault markdown files in `chapter2_vault/` and `drafts/` / `reports/` contain valid YAML headers with all 6 mandatory properties.
3. Execute `tests/verify_repo_tidy.R` (and/or `tests/verify_repo_tidy.py`) using system command execution tools (e.g. `Rscript tests/verify_repo_tidy.R` or `python tests/verify_repo_tidy.py`).
4. Ensure the script exits with exit code 0 and prints a clear green status report.
5. Save your code changes, execution commands, and test logs to `c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_worker_m5\changes.md` and `handoff.md`, then send a completion message to the orchestrator.
</USER_REQUEST>
