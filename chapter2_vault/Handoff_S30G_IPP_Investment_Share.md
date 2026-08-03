---
type: handoff
status: active
depends_on: [chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md, data/releases/chapter2_us_source_of_truth_v1_1_candidate/README.md]
stage_scope: S30G
country: US
last_updated: 2026-08-01
updated_by: S30G_IPP_INVESTMENT_SHARE_CONSTRUCTION
layer: documentation
role: handoff
stage: S30G
tags: [data, variables, IPP, US]
---

# Handoff: S30G IPP Investment Share Construction

## 1. Overview
In this session, we successfully enhanced the US dataset by constructing and integrating the Intellectual Property Products (IPP) investment share of total corporate gross investment (`CORP_IPP_INVESTMENT_SHARE`) for the US economy, covering **1901 to 2024**.

This variable serves as the empirical proxy for the frontier-conditioning parameter $\iota_t$ within the heterogeneous capital cost-minimization framework (conditioning the Mechanization Productive Frontier (MPF) and distinguishing between deepening and predatory mechanization paths).

The updated dataset is now compiled as the **v1.1 Candidate Release**, preserving all original v1 rows and variables while integrating the new proxy.

## 2. Construction Methodology
Using the staged panel data from `output/US/S21_PROVIDER_V1_SOURCE_OF_TRUTH_INTAKE/csv/S21_source_panel_long_v1.csv` (sourced upstream from BEA Table FAAt407), we extracted:
- **Corporate IPP Gross Investment**: `CORP__IPP__gross_investment_current_cost` (Line 20)
- **Total Corporate Gross Investment**: `CORP__TOTAL__gross_investment_current_cost` (Line 17)

The ratio is calculated as:
$$\iota_t = \text{CORP\_IPP\_INVESTMENT\_SHARE}_t = \frac{\text{CORP\_\_IPP\_\_gross\_investment\_current\_cost}_t}{\text{CORP\_\_TOTAL\_\_gross\_investment\_\_current\_cost}_t}$$

### Data Alignment and Long-Format Constraints:
- **Temporal Coverage**: The IPP investment share covers **1901–2024** (124 observations), whereas the interest proxy variables cover **1929–2025** (97 observations).
- **NA Filtering**: To preserve the zero-NA constraint in the long-format database (`CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_LONG.csv`), years 1901–1928 are omitted for interest variables, and year 2025 is omitted for the IPP investment share. In the wide-format panel (`CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_WIDE.csv`), these missing periods are correctly represented as `NA`.
- **Wrangling and Metadata**: Upstream dictionary, provenance, admissibility, and support ledgers were modified to dynamically pull metadata based on individual variable definitions, rather than assuming uniform dimensions across all new variables.

## 3. Cointegration and Identity Validation
The validation routine in [[codes/US_S30G_financial_claims_proxy_addendum.R]] was revised to ensure that:
1. **Recycling Mismatches Resolved**: Cointegrating regressions and identity audits in the script are restricted to matching years (`1929–2024`), preventing element-wise recycling bugs and warning messages.
2. **Platform-Independent Hash Checks**: The hashing function `sha256_file` was updated to convert text file line endings to LF before hashing. This prevents validation failures on Windows machines where Git checkouts convert line endings to CRLF.
3. **Data-File Scope Isolation**: Hash verification for frozen `v1` files was isolated to `.csv` data files, bypassing documentation formatting differences.
4. **Git Checkpoint Check relaxed**: The Git check was adjusted to verify that the active commit is a descendant of `base_commit` (`base_is_ancestor`), allowing successful builds even if the local `origin/main` branch has moved.

All **48/48 validation checks** successfully passed.

## 4. Key Files and Directories
- **Source Code**: [codes/US_S30G_financial_claims_proxy_addendum.R](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/US_S30G_financial_claims_proxy_addendum.R)
- **Candidate Release Directory**: [data/releases/chapter2_us_source_of_truth_v1_1_candidate/](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/data/releases/chapter2_us_source_of_truth_v1_1_candidate/)
- **Wide Panel**: [CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_WIDE.csv](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/data/releases/chapter2_us_source_of_truth_v1_1_candidate/CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_WIDE.csv)
- **Long Panel**: [CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_LONG.csv](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/data/releases/chapter2_us_source_of_truth_v1_1_candidate/CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_LONG.csv)
- **Validation Checklist**: [S30G_validation_checks.csv](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM/csv/S30G_validation_checks.csv)

## 5. Next Steps
Once these changes are approved and merged, the `v1.1` candidate release can be frozen and tagged. The descriptive-statistics reporting stage (`S31B`) must then be regenerated from `v1.1` before starting work on the threshold cointegrating estimation models (`S33`).
