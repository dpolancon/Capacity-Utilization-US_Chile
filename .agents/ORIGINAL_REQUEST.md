# Original User Request

## Initial Request — 2026-07-23T15:41:28Z

Build a clean, audited repository state and an implementation plan for the Chapter 2 dissertation writing and data pipeline. This requires tidying up the repository, integrating new binding reports and scoping agreements, standardizing markdown files with YAML gatekeeping metadata, clarifying multi-repo interactions, and removing obsolete or polluting build files.

Working directory: c:\ReposGitHub\Capacity-Utilization-US_Chile
Integrity mode: development

## Requirements

### R1. Outline Pruning for Chapter 2/3 Scoping Partition
Prune the definitive outline (chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md) to conform to the scoping partition established in Advisor_Review_2026-07-23.md. Specifically:
*   Delete Subsection 2.3.3 (Recapitalization Corridor) and Paragraph 2.3.3.
*   Remove all references to investment function estimations (\chi_t, \psi_j$) in Section 4 and Section 5.
*   Delete Subsection 6.1.2 (Chile Corridor Analysis) and Subsection 6.1.3 (Comparative Corridor Synthesis). Refocus Subsection 6.1 entirely on the capacity-to-profitability transmission.
*   Update Section 7 to frame the recapitalization corridor as the bridge to Chapter 3.

### R2. Repository Reorganization & Tidy-Up
Ensure layout cleanliness and strict compliance with the stage-gate design:
*   Tidy up codes/ to keep it flat as per C03-REPO_STRUCTURE.md. Group legacy/archive scripts under codes/legacy/ and move S34R stage-run subdirectories into codes/runs/.
*   Clean up any obsolete local files, LaTeX compilation junk (.nav, .snm, .aux, .log in outputs), and ensure the .gitignore blocks them.
*   Create a central data/metadata/data_provenance_manifest.md mapping exactly which files and folders from the feeder repositories (US-BEA-Income-FixedAssets-Dataset and K-Stock-Harmonization) feed which parts of data/raw/ and data/provider_handoffs/.

### R3. YAML Metadata Standardization
Standardize YAML frontmatter on all markdown files in the vault (chapter2_vault/) and drafts/reports to optimize context token consumption and enable easy gatekeeping. Every active/vault markdown file must contain a YAML header with:
*   type: (e.g. outline, memo, results_report, constitutional_claim)
*   status: (e.g. active, superseded, legacy, deprecated)
*   depends_on: (list of dependent vault files or data schemas)
*   stage_scope: (stage tags: S10-S99)
*   country: (US, CL, or comparative)
*   last_updated: (ISO-8601 date)

### R4. Automated Verification Scripts
Create a verification script tests/verify_repo_tidy.R (or Python equivalent) that programmatically checks:
1.  That no forbidden nested folders exist in codes/ (except legacy/ and runs/).
2.  That data/metadata/data_provenance_manifest.md exists and contains valid YAML metadata properties.
3.  That all vault markdown files have valid YAML headers containing the six mandatory properties.

## Acceptance Criteria

### Audit & Reorganization
- [ ] codes/ directory contains no nested subdirectories other than legacy/ and runs/.
- [ ] chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md has no occurrences of "Recapitalization Corridor" or investment function parameters (\chi_t, \psi_j), and Section 7 frames the relocation to Chapter 3.
- [ ] data/metadata/data_provenance_manifest.md is created, successfully parsed as YAML, and details the exact inputs from feeder repositories.
- [ ] All active markdown files in chapter2_vault/ and drafts contain valid YAML frontmatter containing the mandatory properties (type, status, depends_on, stage_scope, country, last_updated).
- [ ] The automated verification script tests/verify_repo_tidy.R executes successfully and reports a green status (exit code 0).

## Follow-up — 2026-07-23T20:21:47Z

Note from user: You are welcome to use Python instead of R for the automated verification script (e.g. tests/verify_repo_tidy.py) or any other non-econometric tasks.

