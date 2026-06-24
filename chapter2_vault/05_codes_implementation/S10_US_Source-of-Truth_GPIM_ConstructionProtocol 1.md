---

title: "S10: U.S. Source-of-Truth and GPIM Construction Protocol"  
type: "note"  
subtype: "protocol"  
status: "locked"  
layer: "data_pipeline"  
design_role: "source_truth_construction"  
scope: "chapter2_us"  
stage: "S10"  
created: 2026-06-05  
updated: 2026-06-08

upstream_provider: "US-BEA-Income-FixedAssets-Dataset"  
analytical_source_truth_repo: "Capacity-Utilization-US_Chile"  
upstream_role: "bea_nipa_fixed_assets_carrier_bundle"  
chapter2_role: "canonical_s10_source_truth_construction"

canonical_gpim_method: "weibull_account_level_gross_stock_reconstruction"  
canonical_gpim_toggle: "option_b_weibull_account_level"  
sensitivity_gpim_toggle: "option_a_shaikh_bea1993_aggregate_finite_life"  
capital_stock_object: "gross_productive_capacity_stock"  
depreciation_retirement_distinction: true  
shaikh_gpim_role: "validation_and_sensitivity_benchmark_not_canonical_method"

sectoral_accounting_status: "locked"  
strict_nfc_layer_status: "baseline"  
corrected_corporate_layer_status: "parallel_baseline"  
mixed_layer_status: "alternative_baseline"  
raw_layer_status: "diagnostic_only"  
corporate_correction: "shaikh_style_imputed_interest_correction"  
financial_sector_interpretation: "broader_corporate_reproduction_capacity_not_strict_productive_capacity"  
distributive_boundary_rule: "distribution_conditioning_need_not_share_output_capital_sector_boundary"  
prohibited_baseline_mismatch: "Y_Corp_star_with_K_NFC_without_separate_theory"

required_layers:

- "A_NFC_STRICT"
    
- "B_CORP_SHAIKH_CORRECTED"
    
- "C_NFC_WITH_CORP_DISTRIBUTION"
    
- "D_RAW_DIAGNOSTIC"
    

capital_type_scope:

- "T"
    
- "NRC"
    
- "ME"
    

sector_scope:

- "NFC"
    
- "CORP"
    

s10_canonical_panel: "data/processed/us/S10_SOURCE_TRUTH/S10_us_source_truth_wide.rds"  
s10_canonical_csv: "data/processed/us/S10_SOURCE_TRUTH/S10_us_source_truth_wide.csv"  
s10_long_panel: "data/processed/us/S10_SOURCE_TRUTH/S10_us_source_truth_long.csv"  
s10_provenance_ledger: "data/processed/us/S10_SOURCE_TRUTH/S10_us_variable_provenance.csv"  
s10_gpim_parameter_ledger: "data/processed/us/S10_SOURCE_TRUTH/S10_us_gpim_parameter_ledger.csv"  
s10_asset_mapping_ledger: "data/processed/us/S10_SOURCE_TRUTH/S10_us_asset_mapping_ledger.csv"  
s10_construction_ledger: "data/processed/us/S10_SOURCE_TRUTH/S10_us_construction_ledger.csv"  
s10_validation_report: "data/processed/us/S10_SOURCE_TRUTH/S10_us_validation_report.md"  
s10_build_manifest: "data/processed/us/S10_SOURCE_TRUTH/S10_us_build_manifest.txt"

upstream_bundle_path: "output/ch2_s10_export"  
required_upstream_files:

- "us_bea_s10_carrier_wide.csv"
    
- "us_bea_s10_carrier_long.csv"
    
- "us_bea_s10_variable_ledger.csv"
    
- "us_bea_s10_source_manifest.csv"
    
- "us_bea_s10_gpim_inputs.csv"
    
- "us_bea_s10_validation_report.md"
    
- "us_bea_s10_export_commit.txt"
    

validation_gates:

- "upstream_provenance_complete"
    
- "gpim_ingredient_completeness"
    
- "bea_asset_mapping_complete"
    
- "fraumeni_service_life_crosscheck"
    
- "nomura_mapping_flagged_as_interpretive"
    
- "government_transportation_hybrid_flag"
    
- "shaikh_bea1993_toggle_retained"
    
- "sectoral_layer_identifiers_exported"
    
- "no_downstream_estimation_before_s10_freeze"
    

downstream_blocked_until_s10_passes:

- "S20"
    
- "S30"
    
- "S31I"
    
- "S32"
    
- "S40"
    

related_to:

- "US-BEA-Income-FixedAssets-Dataset"
    
- "Capacity-Utilization-US_Chile"
    
- "GPIM_Application"
    
- "S20_US_SourceTruth_Panel"
    
- "S31I_Integration_Order_Precheck"
    
- "S32_B1_E2B_Model_Choice"
    
- "S40_Restricted_B1_Reconstruction"
    
- "A00_Aggregate_Transformation_Benchmark"
    
- "A03_TransformationElasticity_Two-CapitalCapacityComposition"
    

---


# S10: U.S. Source-of-Truth and GPIM Construction Protocol

> [!warning] Duplicate historical protocol
> The active identification variables are governed by [[R_distribution_conditioned_theta_identification]] and the non-suffixed S10 protocol. Accumulated-index requirements in this duplicate note are parked and non-authoritative.

## Core procedural lock

S10 is the Chapter 2 stage that constructs the canonical U.S. source-of-truth panel.

S10 is not an estimation stage. It does not run S20, S30, S31I, S32, S40, theta reconstruction, productive-capacity reconstruction, or utilization reconstruction.

S10 builds and validates the empirical objects that later stages are allowed to use.

The locked architecture is:

  
```text  
US-BEA-Income-FixedAssets-Dataset  
-> S10-ready upstream carrier bundle  
-> Capacity-Utilization-US_Chile/S10  
-> Chapter 2 U.S. source-of-truth panel
```

The upstream US-BEA repo supplies auditable ingredients. The Chapter 2 repo owns the canonical analytical construction.


`US-BEA-Income-FixedAssets-Dataset` is the upstream provider. Its job is to fetch, clean, and export auditable BEA/NIPA/Fixed Assets ingredients: investment flows, price indexes, value added, compensation, surplus measures, official comparison stocks, imputed-interest correction inputs, metadata, and provenance.

`S10-ready upstream carrier bundle` is the export package from that repo. It is not just a CSV. It is a controlled bundle with the variables plus ledgers: where each variable came from, what table/line it uses, what sector it belongs to, whether it is nominal/real/index/ratio, what commit produced it, and whether it is raw, transformed, GPIM input, or validation series.

`Capacity-Utilization-US_Chile/S10` is the Chapter 2 construction stage. This is where the theoretical decisions happen. S10 takes the upstream ingredients and constructs the actual Chapter 2 objects: GPIM gross capital stocks by sector and capital type, corrected corporate value added, wage shares, profit shares,$mME$,$NRCm_{ME,NRC}$,$mME$,$NRC​$,$k \omega$ $k$, and the layer identifiers.

`Chapter 2 U.S. source-of-truth panel` is the final validated panel that S20/S30/S32/S40 are allowed to use. Once produced, later stages should not reach back into raw BEA files or silently use alternative upstream outputs.


---

## Repository roles

### Upstream repo: `US-BEA-Income-FixedAssets-Dataset`

The US-BEA repo is the upstream extraction and carrier repo. Its role is to provide frozen BEA, NIPA, and Fixed Assets inputs and the metadata required to audit them.

It may provide raw or harmonized variables, official comparison series, investment flows, price indexes, sector-account mappings, and provenance ledgers.

It does not decide the final Chapter 2 theoretical variables.

It does not own the canonical definitions of:

$$  
q_t^{\omega,h},\quad
q_t^{ME,\omega,h},\quad
m_{ME,NRC,t},\quad  
\theta_t,\quad  
\mu_t.  
$$

Those objects are constructed inside the Chapter 2 repo.

### Chapter 2 repo: `Capacity-Utilization-US_Chile`

The Chapter 2 repo is the analytical source-of-truth repo.

It owns S10. It decides how upstream inputs become Chapter 2 variables. It owns the GPIM implementation used for the Chapter 2 U.S. panel, the construction ledger, the validation report, and the canonical processed panel used by later stages.

The Chapter 2 repo must pin the upstream US-BEA commit SHA used for every S10 build.

---

## GPIM methodological lock

The canonical Chapter 2 capital-stock object is a gross productive-capacity stock, not a net book-value stock.

The conceptual distinction is:

$$  
\text{depreciation} \neq \text{retirement}.  
$$

Depreciation governs value attrition in the net stock. Retirement governs the physical exit of installed capital from production.

Chapter 2 uses gross capital stock as a productive-capacity object. Therefore, gross stock falls when assets are retired from service, not when their accounting value depreciates.

The canonical Chapter 2 GPIM recursion is:

# $$  
KGR_{s,a,t}

IGR_{s,a,t}  
+  
(1-\rho_{s,a,t})KGR_{s,a,t-1},  
$$

where:

- (s) indexes the sector;
    
- (a) indexes the capital type;
    
- (KGR_{s,a,t}) is the real gross stock for sector (s) and capital type (a);
    
- (IGR_{s,a,t}) is real gross investment for sector (s) and capital type (a);
    
- (\rho_{s,a,t}) is the retirement rate for sector (s) and capital type (a).
    

Under the canonical Weibull specification:

# $$  
\rho_{s,a,t}  
\approx  
h(\bar{\tau}_{s,a,t})

\frac{\alpha_{s,a}}{\lambda_{s,a}}  
\left(  
\frac{\bar{\tau}_{s,a,t}}{\lambda_{s,a}}  
\right)^{\alpha_{s,a}-1},  
$$

where (\bar{\tau}_{s,a,t}) is the investment-weighted mean age of the stock.

The Weibull scale parameter is derived from the locked service life and shape parameter:

# $$  
\lambda_{s,a}

\frac{L_{s,a}}{\Gamma(1+\alpha_{s,a}^{-1})}.  
$$

The canonical inputs are therefore:

$$  
L_{s,a},\quad  
\alpha_{s,a},\quad  
IGR_{s,a,t},\quad  
\bar{\tau}_{s,a,t},\quad  
KGR_{s,a,t-1}.  
$$

---

## Capital-account scope

S10 must construct capital stocks by sector and by capital type.

The sectoral scopes are:

|Code|Sector|
|---|---|
|`NFC`|Nonfinancial corporate sector|
|`CORP`|Total corporate sector|

The capital-type scopes are:

|Code|Capital object|
|---|---|
|`T`|Total capital stock|
|`NRC`|Non-residential construction|
|`ME`|Machinery and equipment|

The GPIM rule must therefore be applied to each sector-capital pair:

$$  
(s,a)  
\in  
{NFC,CORP}  
\times  
{T,NRC,ME}.  
$$

The canonical S10 capital menu is:

|Variable family|Meaning|
|---|---|
|`KGR_NFC_T`|GPIM gross total capital, nonfinancial corporate|
|`KGR_NFC_NRC`|GPIM gross non-residential construction, nonfinancial corporate|
|`KGR_NFC_ME`|GPIM gross machinery and equipment, nonfinancial corporate|
|`KGR_CORP_T`|GPIM gross total capital, total corporate|
|`KGR_CORP_NRC`|GPIM gross non-residential construction, total corporate|
|`KGR_CORP_ME`|GPIM gross machinery and equipment, total corporate|

S10 must also export the corresponding real investment flows, nominal investment flows where available, price indexes, retirement rates, official comparison stocks, and validation diagnostics for each sector-capital pair.

---

## Retirement-distribution toggle architecture

S10 must retain two retirement-rate modes.

### Option A: Shaikh/BEA-1993 aggregate finite-life path

This is a sensitivity and validation toggle.

It preserves comparability with the finite-service-life reconstruction logic used in Shaikh’s ADJ1/BEA-1993 framework.

It is not the canonical Chapter 2 GPIM specification.

### Option B: Weibull account-level retirement distribution

This is the canonical Chapter 2 GPIM specification.

It uses account-level service lives and Weibull shape parameters. It makes the retirement mechanism explicit and allows different retirement profiles for structures, equipment, and government transportation infrastructure.

S10 must treat Option B as canonical and Option A as a robustness/sensitivity path.

---

## Locked Weibull parameters

|Account|(L) years|(\alpha)|(\lambda)|Status|
|---|--:|--:|--:|---|
|Nonfinancial corporate structures|30|1.6|33.0|canonical|
|Nonfinancial corporate equipment|14|1.7|15.3|canonical|
|Government transportation|60|1.3|68.4|canonical but hybrid|

The government transportation parameter is explicitly hybrid: U.S. service life comes from BEA/Fraumeni-style service-life evidence; the hazard-shape proxy comes from Nomura-style road-related Weibull evidence. It must remain flagged as hybrid in the provenance ledger.

For the total corporate sector, S10 must either map the same account-level parameters to corporate structures and corporate machinery/equipment or create a separate parameter ledger if the corporate asset composition requires different service-life weights.

The total capital stock `T` must not receive an arbitrary independent retirement parameter if it is constructed as an aggregation of `NRC` and `ME`. If `T` is reconstructed directly, S10 must document the implied service-life and retirement-rate logic separately.

---

## Source hierarchy for GPIM parameters

The locked hierarchy is:

1. Fraumeni/BEA service-life evidence is the primary source for service lives (L).
    
2. Nomura-style empirical Weibull evidence is the primary source for shape parameters (\alpha).
    
3. Shaikh/BEA-1993 finite-life logic is used as a methodological validation and sensitivity benchmark.
    
4. Shaikh is not the primary source for account-level (L) or (\alpha).
    

Chapter 2 does not simply reproduce Shaikh’s GPIM. It builds a Chapter 2-specific GPIM layer using an explicit Weibull retirement distribution.

---

## Sectoral-accounting lock: NFC, Shaikh-corrected corporate, and mixed Marxian conditioning

S10 must not treat the U.S. source of truth as a single-sector object.

The Chapter 2 U.S. panel must distinguish four analytically different but mutually comparable layers:

1. a strict nonfinancial corporate productive-capacity layer;
    
2. a Shaikh-corrected total corporate layer;
    
3. a mixed Marxian conditioning layer, where the productive-capacity object remains nonfinancial corporate but the distributive condition is measured at the corrected corporate level;
    
4. a raw diagnostic layer.
    

This distinction is locked because the sectoral scope of productive capacity and the sectoral scope of distributive conflict are not necessarily identical.

---

## Income and distribution menu

S10 must construct both a strict NFC income-distribution layer and a Shaikh-corrected corporate income-distribution layer.

### Strict NFC income layer

The required NFC income-side variables are:

|Variable|Meaning|
|---|---|
|`VA_NFC_nom`|nonfinancial corporate value added|
|`COMP_NFC_nom`|nonfinancial corporate employee compensation|
|`GOS_NFC_nom`|nonfinancial corporate gross operating surplus, if available|
|`NOS_NFC_nom`|nonfinancial corporate net operating surplus, if available|
|`PROFIT_NFC_nom`|profit measure if separately constructed|
|`omega_NFC`|nonfinancial corporate wage share|
|`pi_NFC`|nonfinancial corporate profit share|

The baseline NFC wage share is:

# $$  
\omega^{NFC}_t

\frac{COMP^{NFC}_t}{VA^{NFC}_t}.  
$$

The corresponding residual profit share is:

# $$  
\pi^{NFC}_t

1-\omega^{NFC}_t.  
$$

If a surplus-based profit-share measure is used instead, S10 must report the exact surplus numerator and keep it separate from the residual definition.

### Shaikh-corrected corporate income layer

The required corporate income-side variables are:

|Variable|Meaning|
|---|---|
|`VA_CORP_NIPA_nom`|raw corporate value added|
|`COMP_CORP_nom`|corporate employee compensation|
|`NOS_CORP_NIPA_nom`|raw corporate net operating surplus|
|`BankMonIntPaid`|monetary interest paid by the banking sector|
|`CorpNFNetImpIntPaid`|nonfinancial corporate net imputed interest paid|
|`CorpImpIntAdj`|Shaikh-style imputed-interest correction|
|`VA_CORP_star_nom`|corrected corporate value added|
|`NOS_CORP_star_nom`|corrected corporate surplus|
|`omega_CORP_star`|corrected corporate wage-share proxy|
|`pi_CORP_star`|corrected corporate profit share|
|`omega_CORP_comp`|compensation-based corrected corporate wage-share diagnostic|

The corrected corporate value added is:

# $$  
VA^{Corp,*}_t

VA^{Corp,NIPA}_t  
+  
CorpImpIntAdj_t.  
$$

The corrected corporate surplus is:

# $$  
NOS^{Corp,*}_t

NOS^{Corp,NIPA}_t  
+  
CorpImpIntAdj_t.  
$$

The corrected corporate profit share is:

# $$  
\pi^{Corp,*}_t

\frac{NOS^{Corp,_}_t}{VA^{Corp,_}_t}.  
$$

The corrected corporate wage-share proxy is:

# $$  
\omega^{Corp,*}_t

1-\pi^{Corp,*}_t.  
$$

S10 must also retain the compensation-based diagnostic wage share:

# $$  
\omega^{Corp,comp}_t

\frac{COMP^{Corp}_t}{VA^{Corp,*}_t}.  
$$

This diagnostic is useful because the corrected residual wage-share definition and the compensation-share definition may differ when taxes, proprietors’ components, or other accounting categories enter the corporate value-added structure.

---

## Layer A: strict NFC productive-capacity layer

The strict NFC layer is the baseline productive-capacity object.

It uses:

$$  
Y^{NFC},\quad  
K^{NFC},\quad  
K^{NRC,NFC},\quad  
K^{ME,NFC},\quad  
\omega^{NFC}.  
$$

This layer answers the narrow question:

> How does nonfinancial corporate capital accumulation become nonfinancial productive capacity?

This is the cleanest layer for the strict Marxian productive-sector interpretation. It keeps output, capital, and distribution inside the same nonfinancial corporate boundary.

Layer A is the preferred baseline when the object is productive capacity in the strict sense.

---

## Layer B: Shaikh-corrected total corporate layer

The Shaikh-corrected corporate layer is a broader corporate reproduction-capacity object.

It uses:

$$  
Y^{Corp,_},\quad  
K^{Corp},\quad  
K^{NRC,Corp},\quad  
K^{ME,Corp},\quad  
\omega^{Corp,_}.  
$$

The star denotes the Shaikh-style correction for imputed financial intermediation and profit-transfer accounting.

The purpose of the correction is not to treat finance as productive in the same Marxian sense as nonfinancial production. The purpose is to avoid counting financial intermediation claims as if they were an independent addition to the corporate value product.

Layer B answers the broader question:

> How does the corrected corporate capital structure become a corporate reproduction-capacity field?

This layer is Marxian-defensible only if it is explicitly interpreted as a broader corporate reproduction-capacity field, not as a pure productive-capacity object.

Financial corporations may own buildings, equipment, software, and organizational infrastructures that condition capitalist reproduction. These assets may participate in circulation, coordination, appropriation, and command over production without being treated as productive capital in the narrow value-producing sense.

Therefore, Layer B is admissible as a broader corporate-capacity layer, but it must not silently replace the strict NFC productive-capacity layer.

---

## Layer C: mixed Marxian conditioning layer

The mixed layer keeps the productive-capacity object inside the nonfinancial corporate sector but allows the distributive condition to be measured at the corrected corporate level.

It uses:

$$  
Y^{NFC},\quad  
K^{NFC},\quad  
K^{NRC,NFC},\quad  
K^{ME,NFC},\quad  
\omega^{Corp,*}.  
$$

This layer answers the question:

> How does nonfinancial corporate capital accumulation become productive capacity when technique choice is conditioned by the broader corporate/class distributive settlement?

This layer is Marxian-defensible because the wage/profit conflict that conditions technique choice need not be sector-contained. Nonfinancial firms choose techniques under economy-wide labor-market discipline, corporate profitability norms, wage bargaining conditions, monetary conditions, and class conflict. These conditions may be better captured by a corrected corporate distributive variable than by a narrow NFC wage share.

Layer C is not a sectoral mismatch if it is explicitly interpreted as:

$$  
\text{NFC productive-capacity object}  
+  
\text{corporate-wide distributive conditioning variable}.  
$$

Layer C is therefore promotable as an alternative baseline, not merely a diagnostic, provided the note and ledger clearly mark the causal object.

---

## Layer D: raw diagnostic layer

The raw diagnostic layer contains uncorrected BEA/NIPA objects and official comparison stocks.

It may include:

$$  
Y^{Corp,NIPA},\quad  
K^{Corp,BEA},\quad  
\omega^{Corp,NIPA},  
$$

and official BEA fixed-asset comparison stocks.

Layer D is diagnostic only.

It cannot be used as the promoted Chapter 2 source-of-truth layer unless explicitly reclassified after a separate accounting review.

---

## Sectoral interpretation rules

The following rules are locked.

### Rule 1: productive-capacity boundary

The productive-capacity object must be sectorally explicit.

If the object is strict productive capacity, the promoted variables must be:

$$  
Y^{NFC},\quad  
K^{NFC}.  
$$

If the object is broader corporate reproduction capacity, the promoted variables may be:

$$  
Y^{Corp,*},\quad  
K^{Corp}.  
$$

The two objects must not be collapsed.

### Rule 2: distributive-conditioning boundary

The distributive variable does not have to share the same sectoral boundary as the productive-capacity object.

The following specification is admissible:

# $$  
Y^{NFC}_t

c  
+  
\beta_1 K^{NFC}_t  
+  
\beta_2(\omega^{Corp,*}_t K^{NFC}_t)  
+  
\xi_t.  
$$

Its interpretation is not mixed-sector production.

Its interpretation is:

$$  
\text{NFC capacity formation conditioned by corporate-wide distributive conflict}.  
$$

### Rule 3: corrected corporate layer

The corrected corporate layer must use the Shaikh-style imputed-interest correction.

Raw corporate value added and raw corporate surplus are not sufficient for the promoted corporate layer.

The corrected corporate layer must carry the star notation:

$$  
Y^{Corp,_},\quad  
\omega^{Corp,_}.  
$$

The star means:

> corrected for imputed financial-intermediation accounting so that financial claims are not treated as independent additions to the corporate value product.

### Rule 4: no silent finance-productivity claim

Using the corrected corporate layer does not imply that finance is productive in the strict Marxian value-producing sense.

The corrected corporate layer is admissible because financial-sector fixed assets and infrastructures may condition corporate reproduction, circulation, command, and appropriation.

This is a broader reproduction-capacity object, not a pure productive-capacity object.

### Rule 5: no uncorrected corporate promotion

The following layer is not promotable without additional justification:

$$  
Y^{Corp,NIPA},\quad  
K^{Corp},\quad  
\omega^{Corp,NIPA}.  
$$

Raw corporate data may double count or misclassify imputed financial intermediation and profit-transfer flows.

Raw corporate objects remain diagnostic unless corrected.

### Rule 6: no dependent-variable mismatch

The following combination is not a baseline source-of-truth layer:

$$  
Y^{Corp,_},\quad  
K^{NFC},\quad  
\omega^{Corp,_}.  
$$

This specification makes NFC capital explain corrected total corporate output. It may be estimated diagnostically, but it is not a baseline transformation relation unless a separate theory explicitly claims that NFC capital governs total corporate output.

---

## S10 layer status table

|Layer|Output|Capital|Distribution|Status|Interpretation|
|---|---|---|---|---|---|
|A|(Y^{NFC})|(K^{NFC}), (K^{NRC,NFC}), (K^{ME,NFC})|(\omega^{NFC})|baseline|strict NFC productive capacity|
|B|(Y^{Corp,*})|(K^{Corp}), (K^{NRC,Corp}), (K^{ME,Corp})|(\omega^{Corp,*})|parallel baseline|corrected corporate reproduction capacity|
|C|(Y^{NFC})|(K^{NFC}), (K^{NRC,NFC}), (K^{ME,NFC})|(\omega^{Corp,*})|alternative baseline|NFC capacity conditioned by corporate-wide distributive conflict|
|D|raw BEA/NIPA|official/raw stocks|raw shares|diagnostic only|accounting sensitivity|

---

## Required upstream US-BEA S10 carrier bundle

The US-BEA repo must provide an S10-ready export bundle before S10 runs.

Suggested upstream export path:

```text
output/ch2_s10_export/
  us_bea_s10_carrier_wide.csv
  us_bea_s10_carrier_long.csv
  us_bea_s10_variable_ledger.csv
  us_bea_s10_source_manifest.csv
  us_bea_s10_gpim_inputs.csv
  us_bea_s10_validation_report.md
  us_bea_s10_export_commit.txt
```

The upstream carrier must include enough information to construct, verify, and audit Chapter 2 variables inside the Chapter 2 repo.

---

## Required upstream variable menu

### Provenance fields

Every upstream variable must carry the following fields.

|Field|Meaning|
|---|---|
|`year`|calendar year|
|`source_repo`|upstream repo name|
|`source_repo_commit`|commit SHA|
|`source_file`|upstream file path|
|`source_table`|BEA/NIPA/Fixed Asset table|
|`source_line`|source line or series identifier|
|`source_vintage`|data download or vintage date|
|`unit`|nominal dollars, real dollars, index, ratio, etc.|
|`sector_scope`|NFC, corporate, government, aggregate|
|`asset_scope`|total, structures, equipment, transportation, etc.|
|`price_base`|price base year|
|`construction_method`|imported, transformed, GPIM input, official comparison|
|`missing_flag`|missingness or interpolation marker|

No variable can enter S10 without provenance fields.

### Investment-flow inputs

|Variable|Required use|
|---|---|
|`IGN_NFC_T`|nominal gross investment, NFC total capital|
|`IGN_NFC_NRC`|nominal gross investment, NFC non-residential construction|
|`IGN_NFC_ME`|nominal gross investment, NFC machinery and equipment|
|`IGN_CORP_T`|nominal gross investment, corporate total capital|
|`IGN_CORP_NRC`|nominal gross investment, corporate non-residential construction|
|`IGN_CORP_ME`|nominal gross investment, corporate machinery and equipment|
|`IGR_NFC_T`|real gross investment, NFC total capital|
|`IGR_NFC_NRC`|real gross investment, NFC non-residential construction|
|`IGR_NFC_ME`|real gross investment, NFC machinery and equipment|
|`IGR_CORP_T`|real gross investment, corporate total capital|
|`IGR_CORP_NRC`|real gross investment, corporate non-residential construction|
|`IGR_CORP_ME`|real gross investment, corporate machinery and equipment|

If real investment is not exported upstream, S10 must construct it from nominal investment and price indexes.

### Capital-price inputs

|Variable|Required use|
|---|---|
|`pK_NFC_T`|deflate/revalue NFC total capital|
|`pK_NFC_NRC`|deflate/revalue NFC non-residential construction|
|`pK_NFC_ME`|deflate/revalue NFC machinery and equipment|
|`pK_CORP_T`|deflate/revalue corporate total capital|
|`pK_CORP_NRC`|deflate/revalue corporate non-residential construction|
|`pK_CORP_ME`|deflate/revalue corporate machinery and equipment|

S10 may construct relative price diagnostics from these inputs, but relative-price diagnostics are not upstream authority.

### Initial-stock anchors

|Variable|Required use|
|---|---|
|`KGR_initial_NFC_T`|initial gross stock anchor, NFC total capital|
|`KGR_initial_NFC_NRC`|initial gross stock anchor, NFC non-residential construction|
|`KGR_initial_NFC_ME`|initial gross stock anchor, NFC machinery and equipment|
|`KGR_initial_CORP_T`|initial gross stock anchor, corporate total capital|
|`KGR_initial_CORP_NRC`|initial gross stock anchor, corporate non-residential construction|
|`KGR_initial_CORP_ME`|initial gross stock anchor, corporate machinery and equipment|
|`initial_stock_year`|anchor year|
|`initial_stock_source`|source and method|
|`initial_stock_method`|BEA benchmark, reconstructed, interpolated, etc.|

No GPIM recursion can be canonical unless the initial stock anchor is explicit.

### Age and cohort inputs

The upstream carrier should provide either cohort-level investment histories or enough history to construct investment-weighted mean age.

|Variable or object|Required use|
|---|---|
|`investment_cohort_history_NFC_T`|compute (\bar{\tau}_{s,a,t})|
|`investment_cohort_history_NFC_NRC`|compute (\bar{\tau}_{s,a,t})|
|`investment_cohort_history_NFC_ME`|compute (\bar{\tau}_{s,a,t})|
|`investment_cohort_history_CORP_T`|compute (\bar{\tau}_{s,a,t})|
|`investment_cohort_history_CORP_NRC`|compute (\bar{\tau}_{s,a,t})|
|`investment_cohort_history_CORP_ME`|compute (\bar{\tau}_{s,a,t})|
|`mean_age_NFC_T`|optional if computed upstream|
|`mean_age_NFC_NRC`|optional if computed upstream|
|`mean_age_NFC_ME`|optional if computed upstream|
|`mean_age_CORP_T`|optional if computed upstream|
|`mean_age_CORP_NRC`|optional if computed upstream|
|`mean_age_CORP_ME`|optional if computed upstream|

If upstream does not provide mean age, S10 must compute it and report the method.

### Official BEA comparison stocks

|Variable|Required use|
|---|---|
|`KGR_BEA_NFC_T`|validation comparison|
|`KGR_BEA_NFC_NRC`|validation comparison|
|`KGR_BEA_NFC_ME`|validation comparison|
|`KGR_BEA_CORP_T`|validation comparison|
|`KGR_BEA_CORP_NRC`|validation comparison|
|`KGR_BEA_CORP_ME`|validation comparison|
|`KNC_BEA_NFC_T`|net-stock comparison|
|`KNC_BEA_NFC_NRC`|net-stock comparison|
|`KNC_BEA_NFC_ME`|net-stock comparison|
|`KNC_BEA_CORP_T`|net-stock comparison|
|`KNC_BEA_CORP_NRC`|net-stock comparison|
|`KNC_BEA_CORP_ME`|net-stock comparison|

These series are comparison series, not automatically canonical Chapter 2 stocks.

### Income and distribution inputs

|Variable|Required use|
|---|---|
|`VA_NFC_nom`|nonfinancial corporate value added|
|`COMP_NFC_nom`|nonfinancial corporate employee compensation|
|`GOS_NFC_nom`|nonfinancial corporate gross operating surplus, if available|
|`NOS_NFC_nom`|nonfinancial corporate net operating surplus, if available|
|`VA_CORP_NIPA_nom`|raw corporate value added|
|`COMP_CORP_nom`|corporate employee compensation|
|`NOS_CORP_NIPA_nom`|raw corporate net operating surplus|
|`BankMonIntPaid`|monetary interest paid by the banking sector|
|`CorpNFNetImpIntPaid`|nonfinancial corporate net imputed interest paid|
|`CorpImpIntAdj`|Shaikh-style imputed-interest correction|
|`VA_CORP_star_nom`|corrected corporate value added|
|`NOS_CORP_star_nom`|corrected corporate surplus|
|`omega_NFC`|nonfinancial corporate wage share|
|`pi_NFC`|nonfinancial corporate profit share|
|`omega_CORP_star`|corrected corporate wage-share proxy|
|`pi_CORP_star`|corrected corporate profit share|
|`omega_CORP_comp`|compensation-based corrected corporate wage-share diagnostic|

---

## Variables constructed inside S10

The following variables must be constructed inside Chapter 2 S10 and must not be carried as upstream theoretical authority:

$$  
k_t,\quad  
k^{NRC}_t,\quad  
k^{ME}_t,  
$$

# $$  
m_{ME,NRC,t}

## k^{ME}_t

k^{NRC}_t,  
$$

S10 must construct:

$$
q_t^{\omega,1},\quad q_t^{\omega,3},\quad q_t^{\omega,5},
$$

and:

$$
q_t^{ME,\omega,1},\quad q_t^{ME,\omega,3},\quad q_t^{ME,\omega,5}.
$$

The benchmark variables are uncentered. S10 must not construct full-sample-centered versions as benchmark candidates.

S10 does not construct:

$$  
\theta_t,\quad  
Y^p_t,\quad  
\mu_t.  
$$

Those belong to later reconstruction stages.

---

## Required S10 output identifiers

S10 must export layer identifiers in every output file.

Required fields:

```text
layer_id
layer_name
output_scope
capital_scope
distribution_scope
correction_status
marxian_interpretation
promotion_status
```

Allowed `layer_id` values:

```text
A_NFC_STRICT
B_CORP_SHAIKH_CORRECTED
C_NFC_WITH_CORP_DISTRIBUTION
D_RAW_DIAGNOSTIC
```

Allowed `correction_status` values:

```text
nfc_internal
shaikh_corrected_corporate
mixed_nfc_capacity_corp_distribution
raw_diagnostic
```

Allowed `promotion_status` values:

```text
baseline
parallel_baseline
alternative_baseline
diagnostic_only
blocked
```

---

## S10 output files

Suggested Chapter 2 output path:

```text
data/processed/us/S10_SOURCE_TRUTH/
  S10_us_source_truth_wide.csv
  S10_us_source_truth_wide.rds
  S10_us_source_truth_long.csv
  S10_us_variable_provenance.csv
  S10_us_gpim_parameter_ledger.csv
  S10_us_asset_mapping_ledger.csv
  S10_us_construction_ledger.csv
  S10_us_validation_report.md
  S10_us_build_manifest.txt
```

Suggested code path:

```text
codes/S10_US_SOURCE_TRUTH/
  00_S10_config.R
  01_import_us_bea_carrier.R
  02_validate_us_bea_carrier.R
  03_build_gpim_weibull_accounts.R
  04_build_shaikh_bea1993_toggle.R
  05_build_income_distribution_layers.R
  06_construct_ch2_variables.R
  07_validate_s10_source_truth.R
  08_export_s10_source_truth.R
```

---

## S10 validation gates

S10 cannot be marked complete unless all validation gates pass.

### Gate 1: upstream provenance

The upstream US-BEA carrier bundle must include a commit SHA, source manifest, variable ledger, and construction metadata.

### Gate 2: GPIM ingredient completeness

The carrier must include investment flows, capital price indexes, initial stock anchors, and either mean-age series or enough historical investment information to compute investment-weighted mean age.

### Gate 3: BEA asset mapping

The mapping from BEA asset categories to Chapter 2 accounts must be explicit:

$$  
\text{BEA assets}  
\rightarrow  
K^{NRC,NFC},\quad  
K^{ME,NFC},\quad  
K^{NRC,Corp},\quad  
K^{ME,Corp}.  
$$

### Gate 4: Fraumeni service-life cross-check

The Fraumeni/BEA service-life values used for the locked parameters must be cross-checked against the exact BEA asset mapping used in code. Working averages are not enough for final validation.

### Gate 5: Nomura mapping flag

The mapping from Nomura’s Japanese discard categories to U.S. BEA asset categories must be documented as interpretive, not one-to-one.

### Gate 6: government transportation hybrid flag

Government transportation must remain flagged as a hybrid decision:

$$  
L_{gov,tr}=60  
\quad  
\text{from U.S./BEA service-life evidence},  
$$

$$  
\alpha_{gov,tr}=1.3  
\quad  
\text{from Nomura-style road hazard-shape proxy}.  
$$

### Gate 7: Shaikh/BEA-1993 sensitivity toggle

S10 must retain the Shaikh/BEA-1993 aggregate finite-life path as a sensitivity toggle.

It cannot replace the canonical Weibull account-level reconstruction.

### Gate 8: sectoral layer identifiers

S10 must export the layer identifiers `A_NFC_STRICT`, `B_CORP_SHAIKH_CORRECTED`, `C_NFC_WITH_CORP_DISTRIBUTION`, and `D_RAW_DIAGNOSTIC`.

### Gate 9: no downstream estimation

S20, S30, S31I, S32, and S40 cannot run on a revised U.S. panel until S10 passes and the S10 validation report is exported.

---

## Standing prohibitions

Do not treat the upstream US-BEA repo as the final authority for Chapter 2 theoretical variables.

Do not treat Shaikh/BEA-1993 as the canonical Chapter 2 GPIM rule.

Do not use net capital stock as the productive-capacity object unless explicitly running a diagnostic or book-value profitability layer.

Do not allow official BEA comparison stocks to silently replace the canonical S10 GPIM stocks.

Do not carry (\omega k), (m_{ME,NRC}), or (\omega m_{ME,NRC}) as upstream variables. They must be constructed inside S10.

Do not promote raw corporate variables without the Shaikh-style imputed-interest correction.

Do not run S40 from any panel that has not passed S10.

Do not interpret S10 as choosing the econometric model. S10 builds the source-of-truth panel only.

---

## Procedural lock on sectoral accounting

S10 must build the strict NFC layer, the Shaikh-corrected corporate layer, the mixed Marxian conditioning layer, and the raw diagnostic layer.

The strict NFC layer remains the narrow productive-capacity baseline.

The Shaikh-corrected corporate layer is a broader corporate reproduction-capacity layer.

The mixed layer is admissible because the distributive struggle conditioning technique choice may operate at the corrected corporate/class level even when the productive-capacity object remains nonfinancial corporate.

No later S20, S30, S32, or S40 result can be promoted unless its sectoral layer is explicitly identified.

---

## Procedural lock

S10 is now the required source-of-truth stage for the U.S. side of Chapter 2.

The US-BEA repo must be curated to export an S10-ready carrier bundle.

The Chapter 2 repo must own the canonical construction of the U.S. source-of-truth panel.

The canonical Chapter 2 GPIM rule is the Weibull account-level gross-stock reconstruction.

The GPIM rule must be applied by sector and capital type:

$$  
(s,a)  
\in  
{NFC,CORP}  
\times  
{T,NRC,ME}.  
$$

Shaikh/BEA-1993 remains a sensitivity and validation toggle.

The Shaikh-style imputed-interest correction is required for the promoted total corporate layer.

S10 must be completed, validated, and frozen before any new S20/S30/S32/S40 pass is promoted.
