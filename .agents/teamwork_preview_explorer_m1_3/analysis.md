# Chapter 2 Dissertation Repository Tidying — Milestone 1 Exploration Report
**Data Provenance Mappings & Markdown YAML Metadata Standardization**

- **Author**: Explorer 3 (Milestone 1 Explorer)
- **Working Directory**: `c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_3`
- **Target Repository**: `c:\ReposGitHub\Capacity-Utilization-US_Chile`
- **Date**: 2026-07-23

---

## Executive Summary

This report delivers the complete exploration findings, exact data provenance mappings, draft manifest schema, and comprehensive YAML metadata audit & mapping table for Milestone 1 of the Chapter 2 dissertation repository tidying project.

### Key Discoveries
1. **Feeder Repo Provenance & Data Lineage**:
   - **US Track**: Feeder repo `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` acts as the single provider for BEA API NIPA/Fixed Assets data and FRED fallbacks. Provider handoffs staged in `data/provider_handoffs/US_BEA_FixedAssets/2026-06-11/` (71 variable menu rows) and synced metadata in `data/external/us_bea_provider/` flow through `codes/S10_us_gpim_construction.R` -> `data/processed/us_s10/` -> `codes/S20_us_capital_distribution.R` -> `data/processed/us_s20/` -> `codes/S30_us_integrated_dataset.R` -> `data/releases/chapter2_us_source_of_truth_v1/`.
   - **Chile Track**: Feeder repo `C:\ReposGitHub\K-Stock-Harmonization` delivers canonical Perez FBKF (1900–1994) and BCCh forward extension (1995–2024) in constant 2003 CLP (`outputs/HARMONIZED_BCCH_2003CLP_v1/`). Combined with raw demand & distribution inputs (`data/raw/Chile/`), transformation scripts (`codes/CL_01` to `CL_04`) produce `data/processed/Chile/ch2_panel_chile.csv` -> `data/processed/Chile/stage2_theta_mu.csv` -> `data/final/chile_tvecm_panel.csv`.

2. **YAML Header Audit (477 Markdown Files Scanned)**:
   - **Total Markdown Files**: 477 files across `chapter2_vault/` (146), `reports/` (13), `output/` (277, including 31 paper section drafts in `output/_legacy/writing/drafts/`), `data/` (13), `docs/` (22), `codes/` (2), and root (4).
   - **Existing YAML Headers**: 121 files possess a YAML header; 356 files have NO header.
   - **Mandatory Field Compliance**: **0 out of 477 files (0%) possess all 6 mandatory fields** (`type`, `status`, `depends_on`, `stage_scope`, `country`, `last_updated`).
   - **Deficit Breakdown**: `status` is present in 121 files, `type` in 109 files, `country` in 7 files, `depends_on` in 4 files, `stage_scope` in 3 files, and `last_updated` in 1 file.

3. **Standard Metadata Taxonomy & Proposed Mapping**:
   - Proposed a clean, normalized taxonomy for all 6 mandatory fields.
   - Constructed a file-by-file mapping table for all 477 files in the repository.

---

## 1. Exact Data Provenance Mappings & Manifest Schema

### 1.1 US Track Provenance Mapping
- **Provider Feeder Repo**: `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset`
- **Staging / Provider Handoff**: `data/provider_handoffs/US_BEA_FixedAssets/2026-06-11/`
  - `HANDOFF.md`, `MANIFEST.csv`, `README.md`
  - `ch2_master_variable_menu_long.csv` (71 variable menu rows: 65 locked source concepts, 6 implied investment fallback rows)
  - `ch2_bea_table_disclosure_audit.csv`, `ch2_fred_fallback_audit.csv`
  - `ch2_provider_fetch_provenance_ledger.csv`, `ch2_provider_variable_dictionary.csv`
- **Synced Metadata Layer**: `data/external/us_bea_provider/`
  - `us_bea_variable_menu_locked.csv`, `us_bea_variable_menu_locked.json`, `us_bea_source_provenance_ledger.csv`, `us_bea_variable_menu_long.csv`, `US_BEA_PROVIDER_IMPORT_VALIDATION_LEDGER.csv`
- **Raw Data Input Layer**:
  - `data/raw/US/bea/`: 9 raw BEA tables (`govt_dep_cc_raw.csv`, `govt_inv_raw.csv`, `govt_net_cc_raw.csv`, `govt_net_chain_raw.csv`, `private_dep_cc_raw.csv`, `private_inv_raw.csv`, `private_net_cc_raw.csv`, `private_net_chain_raw.csv`, `private_net_hist_raw.csv`)
  - `data/raw/US/fred/`: 4 FRED fallback tables (`A191RD3A086NBEA.csv`, `CAPUT_1967_2025_FRED.csv`, `GDPA.csv`, `GNPA.csv`)
  - `data/raw/US/US_corporate_NF_kstock_distribution.csv`
- **Stage 10 Staged Processed Data**: `data/processed/us_s10/`
  - Script: `codes/S10_us_gpim_construction.R`
  - Outputs: `us_s10_source_panel_long.csv`, `us_s10_object_admissibility_ledger.csv`, `us_s10_provider_validation_checks.csv`
- **Stage 20 Capital Distribution & Frontier Panel**: `data/processed/us_s20/`
  - Script: `codes/S20_us_capital_distribution.R`
  - Outputs: `us_s20_capital_distribution_frontier_panel.csv`, `us_s20_construction_ledger.csv`, `us_s20_validation_checks.csv`, `us_s20_admissibility_panel.csv`
- **Stage 22 Periodized q & Regression Panel**: `data/processed/us_s22/`
  - Script: `codes/S22_us_periodized_q.R`
  - Outputs: `us_s22_periodized_q_panel.csv`, `us_s22_periodized_q_ledger.csv`, `us_s22_preliminary_regression_results.csv`
- **Stage 30 Dataset Release (Canonical Source of Truth)**: `data/releases/chapter2_us_source_of_truth_v1/`
  - Script: `codes/S30_us_integrated_dataset.R`
  - Outputs: `CH2_US_SOURCE_OF_TRUTH_LONG.csv`, `CH2_US_SOURCE_OF_TRUTH_WIDE.csv`, `CH2_US_PROVENANCE_LEDGER.csv`, `CH2_US_ADMISSIBILITY_LEDGER.csv`, `CH2_US_RELEASE_MANIFEST.csv`, `README.md`
  - Candidate update: `data/releases/chapter2_us_source_of_truth_v1_1_candidate/`
- **Stage 31i to Stage 40 Downstream Processed Data**:
  - `data/processed/us_s31i/`: Integration order tests (`us_s31i_candidate_audit_panel.csv`, `us_s31i_integration_order_tests.csv`, `us_s31i_variable_registry.csv`)
  - `data/processed/us_s32/`: Baseline Cointegration & ECM (`us_s32_cointegration_tests.csv`, `us_s32_ecm_estimation_results.csv`, `us_s32_cointegration_ledger.csv`)
  - `data/processed/us_s32b/`: Structural break ECMs (`us_s32b_subsample_cointegration_tests.csv`, `us_s32b_subsample_ecm_results.csv`)
  - `data/processed/us_s32c/`: Robustness specifications (`us_s32c_robustness_diagnostics.csv`, `us_s32c_robustness_specifications.csv`)

### 1.2 Chile Track Provenance Mapping
- **Provider Feeder Repo**: `C:\ReposGitHub\K-Stock-Harmonization`
  - Output Bundle 1: `outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_series_2003CLP_1900_2024.csv` (Canonical Perez FBKF 1900-1994 + BCCh forward extension 1995-2024 in constant 2003 CLP)
  - Output Bundle 2: `outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_pk_2003base_1940_2024.csv` (Capital price index P_k)
  - Baseline Reference: `outputs/HARMONIZED_PEREZ_2003CLP_v1/harmonized_series_2003CLP_1900_1994.csv`
- **Raw Data Input Layer**: `data/raw/Chile/`
  - `ADnominal_deflators_19962025_BCCH.xlsx` (Central Bank nominal deflators)
  - `Astorga2023_SupM2.xlsx`, `Astorga2023_SupM3.xlsx` (Astorga historical macro series)
  - `CentralBank_RentsShares.xlsx` (BCCH profit share & rent series)
  - `ch2_raw_panel_chile.csv` (Compiled raw panel for Chile)
  - `distr_19202024.xlsx` (Income distribution 1920-2024)
  - `PerezEyzaguirre_DemandaAgregada.xlsx` (Aggregate demand 1810-2020)
  - `W04_Precios_ClioLabPUC.xlsx` (ClioLab PUC historical deflators)
- **Processed Intermediate Layer**: `data/processed/Chile/`
  - Scripts: `codes/CL_01_stage_raw_panel.R` / `codes/01_CL_prepare_data.R` -> `ch2_panel_chile.csv`
  - Scripts: `codes/CL_02_mechanization_ect.R` / `codes/02_CL_mechanization_ect.R` -> `ECT_m_stage1.csv`
  - Scripts: `codes/CL_03_theta_mu_estimation.R` / `codes/03_CL_theta_mu.R` -> `stage2_theta_mu.csv`
- **Final Production Panel & Validation**: `data/final/`
  - `chile_tvecm_panel.csv`: Final TVECM estimation panel for Chile
  - `chile_tvecm_panel_README.txt`: Codebook and provenance description
  - `chile_tvecm_validation.md`: Validation report for Chilean TVECM panel

---

### 1.3 Draft Schema for `data/metadata/data_provenance_manifest.md`

```markdown
---
type: data_provenance
status: active
depends_on:
  - data/provider_handoffs/US_BEA_FixedAssets/2026-06-11/HANDOFF.md
  - data/external/us_bea_provider/us_bea_variable_menu_locked.csv
  - C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_BCCH_2003CLP_v1/summary.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-23
---

# Data Provenance Manifest — Chapter 2 Dissertation

## 1. Overview & Provider Boundary Protocol
This manifest documents the exact data provenance, feeder repository origin, staging path, transformation pipeline, and final production target for all quantitative series in Chapter 2.

## 2. Feeder Repository Mapping Matrix

| Series ID | Concept Name | Feeder Repo / Source Path | Staging Path in Main Repo | Production / Target File | Transformation Code | Country | Role Tag |
|---|---|---|---|---|---|---|---|
| `K_ME_US` | Machinery & Equipment Stock (US) | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` | `data/raw/US/bea/private_net_chain_raw.csv` | `data/releases/chapter2_us_source_of_truth_v1/CH2_US_SOURCE_OF_TRUTH_LONG.csv` | `codes/S10_us_gpim_construction.R` | US | direct_productive_capacity_capital |
| `K_NRC_US` | Nonresidential Structures (US) | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` | `data/raw/US/bea/private_net_chain_raw.csv` | `data/releases/chapter2_us_source_of_truth_v1/CH2_US_SOURCE_OF_TRUTH_LONG.csv` | `codes/S10_us_gpim_construction.R` | US | direct_productive_capacity_capital |
| `IPP_US` | Intellectual Property Products (US) | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` | `data/raw/US/bea/private_net_chain_raw.csv` | `data/releases/chapter2_us_source_of_truth_v1/CH2_US_SOURCE_OF_TRUTH_LONG.csv` | `codes/S10_us_gpim_construction.R` | US | frontier_conditioner (excluded from K_cap) |
| `GOV_TRANS_US` | Government Transportation Capital (US) | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` | `data/raw/US/bea/govt_net_chain_raw.csv` | `data/releases/chapter2_us_source_of_truth_v1/CH2_US_SOURCE_OF_TRUTH_LONG.csv` | `codes/S10_us_gpim_construction.R` | US | frontier_conditioner (excluded from private K_cap) |
| `K_cap_CL` | Harmonized Capital Stock 2003CLP (Chile) | `C:\ReposGitHub\K-Stock-Harmonization` | `outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_series_2003CLP_1900_2024.csv` | `data/processed/Chile/ch2_panel_chile.csv` | `codes/CL_01_stage_raw_panel.R` | CL | canonical_capital_stock |
| `P_k_CL` | Harmonized Capital Deflator (Chile) | `C:\ReposGitHub\K-Stock-Harmonization` | `outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_pk_2003base_1940_2024.csv` | `data/processed/Chile/ch2_panel_chile.csv` | `codes/CL_01_stage_raw_panel.R` | CL | capital_price_index |
| `pi_CL` | Profit Share (Chile) | Central Bank of Chile / Raw File | `data/raw/Chile/distr_19202024.xlsx` | `data/processed/Chile/ch2_panel_chile.csv` | `codes/CL_01_stage_raw_panel.R` | CL | profit_share |
| `Y_CL` | Real GDP (Chile) | Perez & Eyzaguirre / BCCH | `data/raw/Chile/PerezEyzaguirre_DemandaAgregada.xlsx` | `data/processed/Chile/ch2_panel_chile.csv` | `codes/CL_01_stage_raw_panel.R` | CL | real_output |

## 3. Data Integrity & Verification Commands
- US Provider Validation: `Rscript codes/S10_us_gpim_construction.R`
- Chile Harmonization Validation: `python C:\ReposGitHub\K-Stock-Harmonization\codes\run_harmonization_bcch.py`
```

---

## 2. Markdown YAML Metadata Header Audit Results

### 2.1 Summary of Audit Findings (477 Markdown Files)

| Metric | Total Count | Percentage | Description |
|---|---|---|---|
| **Total Markdown Files Scanned** | **477** | 100% | Excludes `.agents`, `.claude`, `.vscode` |
| **Files with Existing YAML Headers** | **121** | 25.4% | Header enclosed by `---` lines at start of file |
| **Files WITHOUT YAML Headers** | **356** | 74.6% | No YAML header present |
| **Files Compliant with ALL 6 Mandatory Fields** | **0** | **0.0%** | **Every file is missing at least 1 mandatory field** |

---

### 2.2 Field Deficit Matrix across Existing 121 Headers

| Mandatory Field | Present Count | Missing Count | Compliance % | Primary Reason for Deficit |
|---|---|---|---|---|
| `status` | 121 | 0 | 100.0% | Included in all legacy vault headers (though non-standard values exist) |
| `type` | 109 | 12 | 90.1% | Missing in legacy notes and custom headers |
| `country` | 7 | 114 | 5.8% | Omitted from almost all vault notes |
| `depends_on` | 4 | 117 | 3.3% | Rarely defined in legacy vault headers |
| `stage_scope` | 3 | 118 | 2.5% | Replaced by informal `scope:` or omitted |
| `last_updated` | 1 | 120 | 0.8% | Replaced by `updated:` or omitted |

---

### 2.3 Audit Summary by Folder Hierarchy

| Folder Path | Total Files | Has YAML | Missing Header | Missing Mandatory Fields | Key Observations |
|---|---|---|---|---|---|
| `chapter2_vault/` | 146 | 118 | 28 | 146 (100%) | 118 files have partial headers; missing `country`, `depends_on`, `stage_scope`, `last_updated`. |
| `reports/` | 13 | 0 | 13 | 13 (100%) | Maintenance audit reports and decision memos lack headers entirely. |
| `output/` | 277 | 3 | 274 | 277 (100%) | Includes 31 draft sections in `output/_legacy/writing/drafts/` and stage verdict memos. |
| `data/` | 13 | 0 | 13 | 13 (100%) | Dataset READMEs, validation reports, and handoff notes lack headers. |
| `docs/` | 22 | 0 | 22 | 22 (100%) | Documentation files lack headers. |
| `codes/` | 2 | 0 | 2 | 2 (100%) | `codes/README.md` and `codes/stage_gate_manifest.md` lack headers. |
| Root Directory | 4 | 0 | 4 | 4 (100%) | `AGENTS.md`, `PROJECT.md`, `CLAUDE.md`, `README.md` lack standard header format. |

---

## 3. Standard Metadata Taxonomy & Proposed Values

### 3.1 Standard Taxonomy for Mandatory Fields

1. **`type`** (Document Functional Archetype):
   - `system_rules`: System instructions and governance (`AGENTS.md`, `PROJECT.md`, `CLAUDE.md`)
   - `readme`: Folder or repository overview (`README.md`)
   - `constitutional_core`: Foundational dissertation claims and governing problem (`chapter2_vault/00_constitutive_core/`)
   - `analytical_foundation`: Theoretical model and regime microfoundations (`chapter2_vault/01_*`, `02_*`)
   - `econometric_protocol`: Econometric specification and admissibility rules (`chapter2_vault/03_econometrics/`)
   - `data_measurement`: Data definition and deflator protocol (`chapter2_vault/04_data_measurement/`)
   - `code_implementation_memo`: Code architecture and execution protocols (`chapter2_vault/05_codes_implementation/`)
   - `paper_facing_map`: Paper structure map, outline, and references (`chapter2_vault/06_paper_facing/`)
   - `writing_rule`: Exposition and voice rules (`chapter2_vault/07_WrittingSkills_and_Rules/`)
   - `prompt_execution_contract`: Active execution prompts (`chapter2_vault/80_Prompts/`)
   - `legacy_note`: Preserved historical exploration notes (`chapter2_vault/09_legacy/`)
   - `inactive_archive`: Inactive/parked documents (`chapter2_vault/99_inactive/`)
   - `audit_report`: Maintenance, GPIM, and provenance audit reports (`reports/`)
   - `stage_report`: Stage results, verdict memos, and stage summaries (`output/US/`, `output/CL/`)
   - `draft_section`: Paper section manuscript drafts (`output/_legacy/writing/drafts/`)
   - `data_manifest`: Dataset handoff and release manifests (`data/provider_handoffs/`, `data/releases/`)
   - `validation_report`: Data validation notes (`data/final/`, `data/interim/`)
   - `documentation`: Reverse documentation (`docs/`)
   - `stage_contract`: Stage transition and repository manifests (`codes/`)

2. **`status`** (Operational Lifecycle Status):
   - `active`: Current binding rule, protocol, or active report
   - `locked`: Locked constitution, outline, or structural map
   - `superseded`: Historical version replaced by newer contract
   - `draft`: Paper draft section or work-in-progress report
   - `frozen`: Data release or frozen dataset artifact
   - `legacy`: Preserved historical note
   - `inactive`: Archived/parked document

3. **`depends_on`** (Upstream Dependencies):
   - List of relative file paths in YAML array format, e.g. `[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]`.

4. **`stage_scope`** (Pipeline Stage Scope):
   - `S00` (Foundations / Constitution)
   - `S10` (Source-of-truth GPIM Construction & Staging)
   - `S20` (Capital Distribution Frontier & Admissibility Panels)
   - `S22` (Periodized q & Regression Panel)
   - `S30` (Dataset Release & Integrated Dataset Closure)
   - `S31i` (Integration Order & Candidate Audit)
   - `S32` (Baseline Cointegration & ECM)
   - `S32b` (Structural Breaks & Subsample ECM)
   - `S32c` (Robustness Specifications)
   - `S35` (Estimator Refreeze)
   - `S40` (Restricted B1 Reconstruction & Final Regressions)
   - `S90` (Path-Dependent Theta Robustness)
   - `all_stages` (Cross-stage infrastructure or governance)
   - `none` (General docs, writing style, non-staged files)

5. **`country`** (Geographic Scope):
   - `US`: United States
   - `CL`: Chile
   - `US_CL`: Comparative / Center-periphery / Joint focus
   - `none`: Methodological / General / Meta

6. **`last_updated`** (Date Stamp):
   - ISO-8601 date string (`YYYY-MM-DD`).

---

## 4. Comprehensive YAML Metadata Mapping Table (Sample View)

The full 477-file mapping table has been compiled and saved to `proposed_yaml_mapping_normalized.csv`. Below is an illustrative excerpt across key directory sections:

| File Relative Path | Proposed `type` | Proposed `status` | Proposed `depends_on` | Proposed `stage_scope` | Proposed `country` | Proposed `last_updated` |
|---|---|---|---|---|---|---|
| `AGENTS.md` | `system_rules` | `active` | `[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]` | `all_stages` | `US_CL` | `2026-07-23` |
| `PROJECT.md` | `system_rules` | `active` | `[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]` | `all_stages` | `US_CL` | `2026-07-23` |
| `README.md` | `readme` | `active` | `[]` | `all_stages` | `US_CL` | `2026-07-23` |
| `chapter2_vault/00_constitutive_core/01_Governing_Memo.md` | `constitutional_core` | `active` | `[chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md]` | `S00` | `US_CL` | `2026-07-23` |
| `chapter2_vault/03_econometrics/R10_Binding_Specification_Layering_Rule.md` | `econometric_protocol` | `superseded` | `[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]` | `all_stages` | `US_CL` | `2026-06-11` |
| `chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md` | `code_implementation_memo` | `active` | `[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]` | `all_stages` | `US_CL` | `2026-07-23` |
| `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md` | `paper_facing_map` | `locked` | `[chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md]` | `all_stages` | `US_CL` | `2026-07-23` |
| `chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md` | `constitutional_core` | `locked` | `[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]` | `all_stages` | `US_CL` | `2026-07-23` |
| `reports/maintenance/D01_GPIM_GROSS_SURVIVAL_REMEDIATION_2026-06-26/...` | `audit_report` | `active` | `[chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]` | `S10` | `US` | `2026-06-26` |
| `output/US/S32_cointegration_ecm/reports/S32_COINTEGRATION_ECM_VERDICT_MEMO.md` | `stage_report` | `active` | `[chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md]` | `S32` | `US` | `2026-07-05` |
| `output/_legacy/writing/drafts/sec_2_1_introduction.md` | `draft_section` | `draft` | `[chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]` | `S00` | `US_CL` | `2026-07-23` |
| `data/provider_handoffs/US_BEA_FixedAssets/2026-06-11/HANDOFF.md` | `data_manifest` | `active` | `[]` | `S10` | `US` | `2026-06-11` |
| `data/releases/chapter2_us_source_of_truth_v1/README.md` | `data_manifest` | `frozen` | `[data/provider_handoffs/US_BEA_FixedAssets/2026-06-11/HANDOFF.md]` | `S30` | `US` | `2026-06-23` |
| `data/final/chile_tvecm_validation.md` | `validation_report` | `active` | `[C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_BCCH_2003CLP_v1/summary.md]` | `S40` | `CL` | `2026-07-23` |

---

## 5. Artifact Index in Working Directory

- `analysis.md`: This comprehensive report.
- `yaml_audit.csv`: Raw audit data of existing headers for all 477 markdown files.
- `proposed_yaml_mapping_normalized.csv`: Full file-by-file mapping table with proposed values for all 6 mandatory fields across all 477 files.
- `audit_yaml.ps1`, `summarize_yaml.ps1`, `full_md_audit.ps1`, `generate_normalized_yaml.ps1`, `summarize_normalized.ps1`: Automated PowerShell analysis scripts.
