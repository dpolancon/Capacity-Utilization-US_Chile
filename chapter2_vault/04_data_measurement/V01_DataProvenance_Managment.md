---
type: note
status: locked
project: Chapter 2
repo: Capacity-Utilization-US_Chile
topic: US BEA upstream provider handoff
created: 2026-06-09
updated: 2026-06-10
upstream_repo: US-BEA-Income-FixedAssets-Dataset
upstream_tag: us-bea-provider-menu-shaikh-blocked-2026-06-09
downstream_repo: Capacity-Utilization-US_Chile
---
# US BEA Upstream Provider Handoff

> [!important] Current identification lock
> Downstream construction must follow [[R_distribution_conditioned_theta_identification]]: productive-capital scale, constant-centered distribution, their primitive interaction, and the centered ME/NR composition fork. Accumulated-index requirements below are parked historical-memory requirements.

## Purpose

This note records the local handoff route from the upstream BEA provider repository into the downstream Chapter 2 capacity-utilization repository.

The upstream repository is:

```text
C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset
```

The downstream analytical repository is:

```text
C:\ReposGitHub\Capacity-Utilization-US_Chile
```

The upstream repository fetches, stages, documents, and validates BEA Fixed Assets and NIPA source ingredients. It does not construct the final Chapter 2 source-of-truth dataset.

The downstream repository owns:

- S10/S20/S30/S40 analytical construction;
    
- GPIM stock construction;
    
- current-release Shaikh-style income corrections only after the protocol passes;
    
- distributive variables;
    
- accumulated distribution-conditioned capital-growth indexes;
    
- frontier-conditioning variables;
    
- admissibility ledgers;
    
- econometric objects.
    

## Locked Upstream State

The upstream provider layer is locked on:

```text
commit: 9ca9f79
tag: us-bea-provider-menu-shaikh-blocked-2026-06-09
branch merged to: main
```

The upstream validation state is:

```text
provider validation: PASS
manifest variables: 175
staged source variables: 94
staged annual observations: 9,438
coverage: 1901–2025 overall
required staged variables: 69
```

## Local Upstream Routes

Use these local source routes when ingesting into the downstream repo.

### 1. Staged source data

```text
C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset\data\staged\us_bea_variable_menu_long.csv
```

This is the main data handoff object.

It contains one row per year/date × staged BEA/NIPA source variable.

Use this file to read actual annual source observations.

### 2. Provenance ledger

```text
C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset\data\metadata\us_bea_source_provenance_ledger.csv
```

This is the audit/provenance handoff object.

It contains one row per manifest variable and preserves:

- BEA dataset;
    
- BEA table;
    
- BEA line;
    
- source description;
    
- sector boundary;
    
- asset block;
    
- account boundary;
    
- unit;
    
- price basis;
    
- stock/flow type;
    
- role tag;
    
- status;
    
- vintage;
    
- source query;
    
- notes.
    

Use this file to preserve table-line-unit-vintage provenance in downstream construction.

### 3. Locked manifest

```text
C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset\data\metadata\us_bea_variable_menu_locked.csv
```

This is the locked variable-menu contract.

It includes staged variables, explicit gaps, diagnostic variables, and downstream-only construction contracts.

Use this file to verify whether a downstream object is:

- directly staged;
    
- not available from the standard BEA menu;
    
- requiring manual mapping;
    
- downstream-constructed only.
    

### 4. JSON copy of locked manifest

```text
C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset\data\metadata\us_bea_variable_menu_locked.json
```

This is the machine-readable JSON version of the locked menu.

Use only if a JSON contract is more convenient than CSV.

### 5. Provider contract

```text
C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset\docs\US_BEA_VARIABLE_MENU_PROVIDER_CONTRACT.md
```

This file documents the formal boundary between upstream provider and downstream analytical construction.

### 6. Validation report

```text
C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset\docs\US_BEA_VARIABLE_MENU_VALIDATION_REPORT.md
```

This file documents the validation pass, staged variables, explicit gaps, and downstream handoff.

### 7. Execution report

```text
C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset\docs\US_BEA_VARIABLE_MENU_EXECUTION_REPORT.md
```

This file records the execution summary for the locked upstream pass.

## Local Downstream Target Routes

Suggested downstream landing folder:

```text
C:\ReposGitHub\Capacity-Utilization-US_Chile\data\external\us_bea_provider\
```

Suggested copied files:

```text
C:\ReposGitHub\Capacity-Utilization-US_Chile\data\external\us_bea_provider\us_bea_variable_menu_long.csv
C:\ReposGitHub\Capacity-Utilization-US_Chile\data\external\us_bea_provider\us_bea_source_provenance_ledger.csv
C:\ReposGitHub\Capacity-Utilization-US_Chile\data\external\us_bea_provider\us_bea_variable_menu_locked.csv
C:\ReposGitHub\Capacity-Utilization-US_Chile\data\external\us_bea_provider\us_bea_variable_menu_locked.json
```

Suggested copied documentation:

```text
C:\ReposGitHub\Capacity-Utilization-US_Chile\docs\data_sources\US_BEA_VARIABLE_MENU_PROVIDER_CONTRACT.md
C:\ReposGitHub\Capacity-Utilization-US_Chile\docs\data_sources\US_BEA_VARIABLE_MENU_VALIDATION_REPORT.md
C:\ReposGitHub\Capacity-Utilization-US_Chile\docs\data_sources\US_BEA_VARIABLE_MENU_EXECUTION_REPORT.md
```

## PowerShell Copy Route

From any PowerShell session:

```powershell
$src = "C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset"
$dst = "C:\ReposGitHub\Capacity-Utilization-US_Chile"

New-Item -ItemType Directory -Force -Path "$dst\data\external\us_bea_provider" | Out-Null
New-Item -ItemType Directory -Force -Path "$dst\docs\data_sources" | Out-Null

Copy-Item "$src\data\staged\us_bea_variable_menu_long.csv" `
  "$dst\data\external\us_bea_provider\us_bea_variable_menu_long.csv" -Force

Copy-Item "$src\data\metadata\us_bea_source_provenance_ledger.csv" `
  "$dst\data\external\us_bea_provider\us_bea_source_provenance_ledger.csv" -Force

Copy-Item "$src\data\metadata\us_bea_variable_menu_locked.csv" `
  "$dst\data\external\us_bea_provider\us_bea_variable_menu_locked.csv" -Force

Copy-Item "$src\data\metadata\us_bea_variable_menu_locked.json" `
  "$dst\data\external\us_bea_provider\us_bea_variable_menu_locked.json" -Force

Copy-Item "$src\docs\US_BEA_VARIABLE_MENU_PROVIDER_CONTRACT.md" `
  "$dst\docs\data_sources\US_BEA_VARIABLE_MENU_PROVIDER_CONTRACT.md" -Force

Copy-Item "$src\docs\US_BEA_VARIABLE_MENU_VALIDATION_REPORT.md" `
  "$dst\docs\data_sources\US_BEA_VARIABLE_MENU_VALIDATION_REPORT.md" -Force

Copy-Item "$src\docs\US_BEA_VARIABLE_MENU_EXECUTION_REPORT.md" `
  "$dst\docs\data_sources\US_BEA_VARIABLE_MENU_EXECUTION_REPORT.md" -Force
```

## R Ingestion Skeleton

Downstream scripts should read the provider files from the copied local route.

```r
library(readr)
library(dplyr)

bea_provider_dir <- "C:/ReposGitHub/Capacity-Utilization-US_Chile/data/external/us_bea_provider"

bea_long <- read_csv(
  file.path(bea_provider_dir, "us_bea_variable_menu_long.csv"),
  show_col_types = FALSE
)

bea_provenance <- read_csv(
  file.path(bea_provider_dir, "us_bea_source_provenance_ledger.csv"),
  show_col_types = FALSE
)

bea_manifest <- read_csv(
  file.path(bea_provider_dir, "us_bea_variable_menu_locked.csv"),
  show_col_types = FALSE
)

stopifnot(nrow(bea_manifest) == 175)
stopifnot(length(unique(bea_long$variable_id)) == 94)
stopifnot(nrow(bea_long) == 9438)
stopifnot(nrow(bea_provenance) == 175)
stopifnot(all(unique(bea_long$variable_id) %in% bea_manifest$variable_id))
stopifnot(all(unique(bea_long$variable_id) %in% bea_provenance$variable_id))

message("US BEA provider handoff loaded successfully.")
```

## Analytical Boundary

Do not treat the upstream provider file as the final Chapter 2 source-of-truth dataset.

The upstream provider gives source ingredients only.

S00 imports and validates provider artifacts only. It does not construct GPIM stocks, Shaikh-adjusted income variables, distributive variables, accumulated indexes, capacity or utilization variables, or econometric outputs.

S00 imported the current candidate ingredients only. The current-release Shaikh-style protocol is downstream analytical work and remains blocked. Shaikh 2011 is the conceptual/accounting benchmark; current BEA release semantics are the admissibility constraint.

No Shaikh-adjusted income, profit-share, wage-share, exploitation-rate, accumulated-index, regression, capacity, or utilization variable may be constructed until the current-release Shaikh-style protocol passes.

The downstream repo must construct:

- GPIM gross and net capital stocks;
    
- `K_ME`;
    
- `K_NRC`;
    
- `K_cap = K_ME + K_NRC`;
    
- IPP frontier-conditioning variables;
    
- GOV_TRANS frontier-conditioning variables;
    
- Shaikh-adjusted income and distribution variables only after the current-release protocol passes;
    
- profit share;
    
- wage share;
    
- exploitation ratio `e`;
    
- accumulated distribution-conditioned capital-growth indexes;
    
- S10/S20/S30/S40 analytical datasets;
    
- admissibility ledgers.
    

## Locked Productive-Capacity Object

Preferred downstream private productive-capacity capital is:

```text
K_cap = K_ME + K_NRC
```

where:

```text
ME  = machinery and equipment
NRC = nonresidential construction / nonresidential structures
```

IPP is excluded from preferred `K_cap`.

Government transportation fixed assets are excluded from preferred private `K_cap`.

IPP and GOV_TRANS remain retained as frontier conditioners.

Preferred transformation object:

```text
y_t^p = alpha + theta_0*k_t + theta_omega*q_omega_h1_Kcap_t + u_t
theta_t = theta_0 + theta_omega*omega_(t-1)
```

Wage share is the preferred distributive state. The exploitation rate is retained only as an alternative proxy.

The unadjusted wage share may proceed as the first-pass baseline. If the current-release Shaikh-style protocol passes later, adjusted-distribution robustness variants may be constructed separately and must not overwrite the baseline.

Do not encode the alternative additive object:

```text
g_Yp = theta*g_Kcap + psi*g_IPP + gamma*g_GOV_TRANS
```

## Main Downstream Filters

Examples of useful downstream filters:

### Direct productive-capacity capital ingredients

```r
kcap_ingredients <- bea_long %>%
  filter(
    asset_block %in% c("ME", "NRC"),
    role_tag == "direct_productive_capacity_capital",
    status == "staged"
  )
```

### NFC productive-sector fixed-assets ingredients

```r
nfc_kcap_ingredients <- bea_long %>%
  filter(
    sector_boundary == "NFC",
    asset_block %in% c("ME", "NRC"),
    status == "staged"
  )
```

### IPP frontier-conditioning ingredients

```r
ipp_ingredients <- bea_long %>%
  filter(
    asset_block == "IPP",
    role_tag == "frontier_conditioner",
    status == "staged"
  )
```

### Government transportation frontier-conditioning ingredients

```r
gov_trans_ingredients <- bea_long %>%
  filter(
    sector_boundary == "GOV_TRANS",
    role_tag == "frontier_conditioner",
    status == "staged"
  )
```

### Current candidate Shaikh-style ingredients

```r
shaikh_interest_lines <- bea_long %>%
  filter(
    variable_id %in% c(
      "T711_L4", "T711_L44", "T711_L73",
      "T711_L28", "T711_L52", "T711_L91",
      "T711_L74", "T711_L53"
    )
  )
```

## Required Downstream Constructions

The provider validation handoff identifies the following as downstream-owned objects. Unadjusted distribution and accumulated-index objects may proceed under their own stage gates:

```text
K_G_NFC_ME_GPIM
K_G_NFC_NRC_GPIM
K_G_NFC_KCAP_GPIM
K_N_NFC_ME_GPIM
K_N_NFC_NRC_GPIM
K_N_NFC_KCAP_GPIM
P_K_NFC_ME_GPIM
P_K_NFC_NRC_GPIM
IPP_NFC_GPIM
GOV_TRANS_GPIM
omega_CORP
omega_NFC
pi_res_CORP
e_CORP
q_omega_h1_Kcap
q_omega_h3_Kcap
q_omega_h5_Kcap
q_e_h1_Kcap
q_e_h3_Kcap
q_e_h5_Kcap
source_provenance_ledger
```

These are not upstream products.

The `q_omega_*` family is the preferred A00 benchmark family. `q_omega_h1_Kcap` uses the inherited one-period wage-share state; `q_omega_h3_Kcap` and `q_omega_h5_Kcap` use restricted three-year and five-year moving-average robustness states. The `q_e_*` family repeats those memory restrictions with the exploitation rate as an alternative-proxy robustness state.

Level interaction variables are diagnostic/superseded only and are not allowed to drive A00, coefficient promotion, or S40 reconstruction.

The following current-release Shaikh-style objects remain protocol-gated and are not approved downstream constructions:

```text
BankMonIntPaid_t
CorpNFNetImpIntPaid_t
CorpImpIntAdj_t
GVAcorp_adj_t
NOScorp_adj_t
VAcorp_adj_t
omega_adj_CORP_t
pi_adj_res_CORP_t
e_adj_CORP_t
```

Their provenance begins with the S00 candidate-line import, but their construction requires the downstream current-release Shaikh-style protocol to pass. No current BEA line-number match is sufficient on its own.

## Explicit Non-Menu Auxiliary Data

The upstream repo also contains auxiliary labor-market files.

These files may be retained for reference or future extension, but they are outside the active BEA variable-menu provider pipeline.

They must not be added to the locked Chapter 2 variable menu unless a later explicit pass promotes them into the provider contract.

## Raw Snapshot Rule

Do not ingest raw BEA snapshots directly into Chapter 2 construction unless auditing a discrepancy.

Raw upstream snapshots live at:

```text
C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset\data\raw\provider\2026-06-09\
```

They are audit backup, not the preferred downstream ingestion route.

Preferred downstream ingestion route:

```text
staged long file + provenance ledger + locked manifest
```

## Closure

This upstream provider pass is locked and has been imported through S00.

S00 remains an import/validation boundary only. Later construction must preserve the A00 accumulated-index lock, the blocked current-release Shaikh-style protocol, and the classification of IPP and GOV_TRANS as frontier conditioners rather than additive capital terms.
