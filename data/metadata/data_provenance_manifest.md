---
type: provenance_manifest
status: active
depends_on:
  - data/metadata/us_bea_variable_menu_locked.csv
  - codes/10_bea_api_helpers.R
stage_scope: S10-S90
country: comparative
last_updated: 2026-07-23
---

# Central Data Provenance Manifest — Chapter 2 Dissertation

## 1. Executive Overview & Boundary Protocol

This central provenance manifest governs the end-to-end data lineage, feeder repository mappings, raw staging layers, transformation pipelines, and final production releases for both the United States and Chile empirical tracks in Chapter 2 ("Demand-Led Profitability and Structural Crisis of Capitalism in Chile and the United States during the Fordist Era").

### Provider Boundary Protocol
In accordance with repository governance rules (`AGENTS.md`):
- **US Feeder Repository** (`C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset`): Provider of raw BEA NIPA and Fixed Assets tables, FRED fallbacks, variable menus, and provenance ledgers. The feeder repo is a provider, not an analytical authority.
- **Chile Feeder Repository** (`C:\ReposGitHub\K-Stock-Harmonization`): Provider of harmonized long-run fixed capital stock series ($K^{NR}$, $K^{ME}$) and capital deflators ($P_k$) joining Perez FBKF (1900–1994) with Central Bank of Chile (BCCh) forward extensions (1995–2024) in constant 2003 CLP.
- **Main Dissertation Repository** (`C:\ReposGitHub\Capacity-Utilization-US_Chile`): Owns all GPIM stock constructions (S10), capital distribution & frontier panels (S20), integrated source of truth releases (S30), integration order tests (S31i), baseline cointegration & ECMs (S32), structural breaks (S32b/c), estimator refreezing (S35), final TVECM/DOLS regressions (S40), and robustness tests (S90).

---

## 2. United States Track Provenance Mapping

### 2.1 Feeder Repository & Provider Handoff Layer
- **Feeder Repository**: `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset`
- **Staging / Provider Handoff Directory**: `data/provider_handoffs/US_BEA_FixedAssets/2026-06-11/`
  - `HANDOFF.md`: Provider handoff specification and boundary contract
  - `MANIFEST.csv`: Handoff file registry and verification checksums
  - `ch2_master_variable_menu_long.csv`: 71 variable menu rows (65 locked source concepts + 6 implied investment fallbacks)
  - `ch2_bea_table_disclosure_audit.csv`: BEA API table and line disclosure audit
  - `ch2_fred_fallback_audit.csv`: Audit of FRED fallback series ($GDPA$, $GNPA$, $CAPUT$)
  - `ch2_provider_fetch_provenance_ledger.csv`: Vintage timestamps, query parameters, and line descriptions
  - `ch2_provider_variable_dictionary.csv`: Concept taxonomy and role definitions
- **Synced Metadata Layer**: `data/external/us_bea_provider/` & `data/metadata/`
  - `data/metadata/us_bea_variable_menu_locked.csv`: Primary locked BEA variable menu
  - `data/metadata/us_bea_variable_menu_locked.json`: Machine-readable JSON variable dictionary
  - `data/external/us_bea_provider/us_bea_source_provenance_ledger.csv`: Full provenance ledger
  - `data/external/us_bea_provider/US_BEA_PROVIDER_IMPORT_VALIDATION_LEDGER.csv`: Import audit ledger

### 2.2 Raw Input Layer (`data/raw/US/`)
- **BEA Raw Tables (`data/raw/US/bea/`)**:
  - `private_net_chain_raw.csv`, `private_net_cc_raw.csv`, `private_net_hist_raw.csv`: Private nonresidential structures ($K^{NR}$) and machinery & equipment ($K^{ME}$)
  - `private_inv_raw.csv`, `private_dep_cc_raw.csv`: Investment flows and depreciation
  - `govt_net_chain_raw.csv`, `govt_net_cc_raw.csv`, `govt_inv_raw.csv`, `govt_dep_cc_raw.csv`: Government transportation capital ($GOV\_TRANS$) and state fixed assets
- **FRED Fallback Series (`data/raw/US/fred/`)**:
  - `A191RD3A086NBEA.csv` (GDP Deflator)
  - `CAPUT_1967_2025_FRED.csv` (Federal Reserve Capacity Utilization Index)
  - `GDPA.csv`, `GNPA.csv` (Annual Nominal GDP and GNP)
- **Corporate Distribution Inputs (`data/raw/US/`)**:
  - `US_corporate_NF_kstock_distribution.csv` (Nonfinancial corporate boundary shares)

### 2.3 Stage-by-Stage Processing Pipeline (US)
1. **Stage 10 (GPIM Stock Construction)**:
   - Script: `codes/S10_us_gpim_construction.R`
   - Output Path: `data/processed/us_s10/`
   - Key Artifacts: `us_s10_source_panel_long.csv`, `us_s10_object_admissibility_ledger.csv`, `us_s10_provider_validation_checks.csv`
2. **Stage 20 (Capital Distribution & Frontier Panel)**:
   - Script: `codes/S20_us_capital_distribution.R`
   - Output Path: `data/processed/us_s20/`
   - Key Artifacts: `us_s20_capital_distribution_frontier_panel.csv`, `us_s20_construction_ledger.csv`, `us_s20_admissibility_panel.csv`
3. **Stage 22 (Periodized q & Regression Prep)**:
   - Script: `codes/S22_us_periodized_q.R`
   - Output Path: `data/processed/us_s22/`
   - Key Artifacts: `us_s22_periodized_q_panel.csv`, `us_s22_periodized_q_ledger.csv`, `us_s22_preliminary_regression_results.csv`
4. **Stage 30 (Canonical Source of Truth Release)**:
   - Script: `codes/S30_us_integrated_dataset.R`
   - Output Path: `data/releases/chapter2_us_source_of_truth_v1/`
   - Key Artifacts: `CH2_US_SOURCE_OF_TRUTH_LONG.csv`, `CH2_US_SOURCE_OF_TRUTH_WIDE.csv`, `CH2_US_PROVENANCE_LEDGER.csv`, `CH2_US_ADMISSIBILITY_LEDGER.csv`, `CH2_US_RELEASE_MANIFEST.csv`
   - Active Candidate Path: `data/releases/chapter2_us_source_of_truth_v1_1_candidate/`
5. **Stages 31i–S90 (Downstream Econometrics)**:
   - `data/processed/us_s31i/`: `us_s31i_candidate_audit_panel.csv`, `us_s31i_integration_order_tests.csv`
   - `data/processed/us_s32/`: `us_s32_cointegration_tests.csv`, `us_s32_ecm_estimation_results.csv`
   - `data/processed/us_s32b/`: `us_s32b_subsample_cointegration_tests.csv`, `us_s32b_subsample_ecm_results.csv`
   - `data/processed/us_s32c/`: `us_s32c_robustness_diagnostics.csv`, `us_s32c_robustness_specifications.csv`

---

## 3. Chile Track Provenance Mapping

### 3.1 Feeder Repository & Harmonization Layer
- **Feeder Repository**: `C:\ReposGitHub\K-Stock-Harmonization`
- **Staged Harmonized Output Bundles**:
  - `outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_series_2003CLP_1900_2024.csv`: Canonical Perez FBKF (1900–1994) + Central Bank forward extension (1995–2024) in constant 2003 CLP.
  - `outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_pk_2003base_1940_2024.csv`: Harmonized capital price deflator index ($P_k$).
  - Reference Baseline: `outputs/HARMONIZED_PEREZ_2003CLP_v1/harmonized_series_2003CLP_1900_1994.csv`.

### 3.2 Raw Input Layer (`data/raw/Chile/`)
- **Central Bank & Historical Macro Data**:
  - `PerezEyzaguirre_DemandaAgregada.xlsx`: Real GDP, aggregate demand, and gross investment (1810–2020)
  - `distr_19202024.xlsx`: Functional income distribution, wage share, and profit share ($\pi_t$) (1920–2024)
  - `CentralBank_RentsShares.xlsx`: Central Bank sectoral profit shares and net rent series
  - `ADnominal_deflators_19962025_BCCH.xlsx`: Central Bank nominal deflators (1996–2025)
  - `Astorga2023_SupM2.xlsx`, `Astorga2023_SupM3.xlsx`: Astorga historical macro series
  - `W04_Precios_ClioLabPUC.xlsx`: ClioLab PUC long-run price indices
  - `ch2_raw_panel_chile.csv`: Master raw Chilean input panel

### 3.3 Processed & Final Production Pipeline (Chile)
1. **Raw Panel Staging & Harmonization**:
   - Scripts: `codes/CL_01_stage_raw_panel.R` / `codes/01_CL_prepare_data.R`
   - Output Path: `data/processed/Chile/ch2_panel_chile.csv`
2. **Mechanization Growth & Error Correction**:
   - Scripts: `codes/CL_02_mechanization_ect.R` / `codes/02_CL_mechanization_ect.R`
   - Output Path: `data/processed/Chile/ECT_m_stage1.csv`
3. **Theta-Mu Estimation Panel**:
   - Scripts: `codes/CL_03_theta_mu_estimation.R` / `codes/03_CL_theta_mu.R`
   - Output Path: `data/processed/Chile/stage2_theta_mu.csv`
4. **Final TVECM Production Panel & Validation**:
   - Output Path: `data/final/chile_tvecm_panel.csv` (Final TVECM estimation dataset for Chile)
   - Codebook: `data/final/chile_tvecm_panel_README.txt`
   - Validation Report: `data/final/chile_tvecm_validation.md`

---

## 4. Master Variable Role Taxonomy Matrix

| Variable ID | Descriptive Concept | Feeder Origin / Path | Staging Path in Repo | Final Target File | Transformation Script | Scope | Role Tag |
|---|---|---|---|---|---|---|---|
| `K_ME_US` | Machinery & Equipment Stock (US) | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` | `data/raw/US/bea/private_net_chain_raw.csv` | `data/releases/chapter2_us_source_of_truth_v1/CH2_US_SOURCE_OF_TRUTH_LONG.csv` | `codes/S10_us_gpim_construction.R` | US | direct_productive_capacity_capital |
| `K_NRC_US` | Nonresidential Structures Stock (US) | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` | `data/raw/US/bea/private_net_chain_raw.csv` | `data/releases/chapter2_us_source_of_truth_v1/CH2_US_SOURCE_OF_TRUTH_LONG.csv` | `codes/S10_us_gpim_construction.R` | US | direct_productive_capacity_capital |
| `IPP_US` | Intellectual Property Products Stock (US) | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` | `data/raw/US/bea/private_net_chain_raw.csv` | `data/releases/chapter2_us_source_of_truth_v1/CH2_US_SOURCE_OF_TRUTH_LONG.csv` | `codes/S10_us_gpim_construction.R` | US | frontier_conditioner (excluded from K_cap) |
| `GOV_TRANS_US` | Government Transportation Capital (US) | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` | `data/raw/US/bea/govt_net_chain_raw.csv` | `data/releases/chapter2_us_source_of_truth_v1/CH2_US_SOURCE_OF_TRUTH_LONG.csv` | `codes/S10_us_gpim_construction.R` | US | frontier_conditioner (excluded from private K_cap) |
| `K_cap_CL` | Harmonized Capital Stock 2003CLP (Chile) | `C:\ReposGitHub\K-Stock-Harmonization` | `outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_series_2003CLP_1900_2024.csv` | `data/processed/Chile/ch2_panel_chile.csv` | `codes/CL_01_stage_raw_panel.R` | CL | canonical_capital_stock |
| `P_k_CL` | Harmonized Capital Deflator (Chile) | `C:\ReposGitHub\K-Stock-Harmonization` | `outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_pk_2003base_1940_2024.csv` | `data/processed/Chile/ch2_panel_chile.csv` | `codes/CL_01_stage_raw_panel.R` | CL | capital_price_index |
| `pi_CL` | Profit Share (Chile) | BCCH / `distr_19202024.xlsx` | `data/raw/Chile/distr_19202024.xlsx` | `data/processed/Chile/ch2_panel_chile.csv` | `codes/CL_01_stage_raw_panel.R` | CL | profit_share |
| `Y_CL` | Real GDP 2003CLP (Chile) | Perez & Eyzaguirre / BCCH | `data/raw/Chile/PerezEyzaguirre_DemandaAgregada.xlsx` | `data/processed/Chile/ch2_panel_chile.csv` | `codes/CL_01_stage_raw_panel.R` | CL | real_output |

---

## 5. Verification Commands

To independently audit and verify data provenance integrity:
1. **US BEA Provider Staging Verification**:
   ```powershell
   Rscript codes/S10_us_gpim_construction.R
   ```
2. **Chile Harmonization Verification**:
   ```powershell
   python C:\ReposGitHub\K-Stock-Harmonization\codes\run_harmonization_bcch.py
   ```
3. **Data Release Integrity Check**:
   ```powershell
   Rscript codes/S30_us_integrated_dataset.R
   ```
