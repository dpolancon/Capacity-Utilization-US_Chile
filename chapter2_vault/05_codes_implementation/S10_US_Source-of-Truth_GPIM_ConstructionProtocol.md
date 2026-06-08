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
  - "S30I"
  - "S32"
  - "S40"

related_to:
  - "R_distribution_conditioned_theta_identification"
  - "US-BEA-Income-FixedAssets-Dataset"
  - "Capacity-Utilization-US_Chile"
  - "GPIM_Application"
  - "S20_US_SourceTruth_Panel"
  - "S30I_Integration_Order_Precheck"
  - "S32_B1_E2B_Model_Choice"
  - "S40_Restricted_B1_Reconstruction"
  - "A00_Aggregate_Transformation_Benchmark"
  - "A03_TransformationElasticity_Two-CapitalCapacityComposition"
---

## Distribution-conditioned index construction lock

S10 must generate the corrected indexes before S30 estimation:

$$
q_t^{\omega,1}
=
\sum_{s=1}^{t}
\omega_{s-1}\Delta k_s,
\qquad
q_t^{\omega,3}
=
\sum_{s=1}^{t}
m_{s-1}^{(3)}\Delta k_s,
\qquad
q_t^{\omega,5}
=
\sum_{s=1}^{t}
m_{s-1}^{(5)}\Delta k_s.
$$

It must also generate:

$$
q_t^{ME,\omega,1},
\qquad
q_t^{ME,\omega,3},
\qquad
q_t^{ME,\omega,5},
$$

using the corresponding inherited-distribution memory state and $\Delta k_s^{ME}$.

The benchmark uses no full-sample centering. Every index export must record timing, memory state, first valid year, missingness, capital definition, and distribution measure. Downstream estimation remains blocked until these generated variables pass the feasibility checks in [[R10_Binding_Specification_Layering_Rule]].

## Sectoral-accounting lock: NFC, Shaikh-corrected corporate, and mixed Marxian conditioning

S10 must not treat the U.S. source of truth as a single-sector object.

The Chapter 2 U.S. panel must distinguish three analytically different but mutually comparable layers:

1. a strict nonfinancial corporate productive-capacity layer;
    
2. a Shaikh-corrected total corporate layer;
    
3. a mixed Marxian conditioning layer, where the productive-capacity object remains nonfinancial corporate but the distributive condition is measured at the corrected corporate level.
    

This distinction is locked because the sectoral scope of productive capacity and the sectoral scope of distributive conflict are not necessarily identical.

---

### Layer A: strict NFC productive-capacity layer

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

### Layer B: Shaikh-corrected total corporate layer

The Shaikh-corrected corporate layer is a broader corporate reproduction-capacity object.

It uses:

$$  
Y^{Corp},\quad  
K^{Corp},\quad  
\omega^{Corp}.  
$$

The star denotes the Shaikh-style correction for imputed financial intermediation and profit-transfer accounting.

The purpose of the correction is not to treat finance as productive in the same Marxian sense as nonfinancial production. The purpose is to avoid counting financial intermediation claims as if they were an independent addition to the corporate value product.

The corrected corporate output object is:

 $$  VA^{Corp,*}_t = VA^{Corp,NIPA}_t + CorpImpIntAdj_t.  
$$

The corrected corporate surplus object is:

$$  
NOS^{Corp,*}_t = NOS^{Corp,NIPA}_t  +  CorpImpIntAdj_t.  
$$

The corrected corporate profit share is:

$$
\pi^{Corp^*}_t = \frac{{NOS^{Corp}}_t}{VA^{Corp}_t}
$$

The corrected corporate wage-share proxy is:

 $$  
\omega^{Corp,*}_t =  1-\pi^{Corp,*}_t.  
$$

Layer B answers the broader question:

> How does the corrected corporate capital structure become a corporate reproduction-capacity field?

This layer is Marxian-defensible only if it is explicitly interpreted as a broader corporate reproduction-capacity field, not as a pure productive-capacity object.

Financial corporations may own buildings, equipment, software, and organizational infrastructures that condition capitalist reproduction. These assets may participate in circulation, coordination, appropriation, and command over production without being treated as productive capital in the narrow value-producing sense.

Therefore, Layer B is admissible as a broader corporate-capacity layer, but it must not silently replace the strict NFC productive-capacity layer.

---

### Layer C: mixed Marxian conditioning layer

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

### Layer D: raw diagnostic layer

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

---

### Rule 2: distributive-conditioning boundary

The distributive variable does not have to share the same sectoral boundary as the productive-capacity object.

The following specification is admissible:

$$  
Y^{NFC}_t

c  
+  
\beta_1 K^{NFC}_t  
+  
\beta_2(\omega^{Corp,*}_t K^{NFC}_t)  
+  
\xi_t.  
$$

Its interpretation is not “mixed-sector production.”

Its interpretation is:

$$  
\text{NFC capacity formation conditioned by corporate-wide distributive conflict}.  
$$

---

### Rule 3: corrected corporate layer

The corrected corporate layer must use the Shaikh-style imputed-interest correction.

Raw corporate value added and raw corporate surplus are not sufficient for the promoted corporate layer.

The corrected corporate layer must carry the star notation:

$$  
Y^{Corp}\quad \omega^{Corp}
$$

The star means:

> corrected for imputed financial-intermediation accounting so that financial claims are not treated as independent additions to the corporate value product.

---

### Rule 4: no silent finance-productivity claim

Using the corrected corporate layer does not imply that finance is productive in the strict Marxian value-producing sense.

The corrected corporate layer is admissible because financial-sector fixed assets and infrastructures may condition corporate reproduction, circulation, command, and appropriation.

This is a broader reproduction-capacity object, not a pure productive-capacity object.

---

### Rule 5: no uncorrected corporate promotion

The following layer is not promotable without additional justification:

$$  
Y^{Corp,NIPA},\quad  
K^{Corp},\quad  
\omega^{Corp,NIPA}.  
$$

Raw corporate data may double count or misclassify imputed financial intermediation and profit-transfer flows.

Raw corporate objects remain diagnostic unless corrected.

---

### Rule 6: no dependent-variable mismatch

The following combination is not a baseline source-of-truth layer:

$$  
Y^{Corp} \quad  
K^{NFC} \quad  
\omega^{Corp}  
$$

This specification makes NFC capital explain corrected total corporate output. It may be estimated diagnostically, but it is not a baseline transformation relation unless a separate theory explicitly claims that NFC capital governs total corporate output.

---

## S10 layer status table

| Layer | Output        | Capital             | Distribution        | Status               | Interpretation                                                   |
| ----- | ------------- | ------------------- | ------------------- | -------------------- | ---------------------------------------------------------------- |
| A     | ($Y^{NFC}$)   | ($K^{NFC}$)         | ($\omega^{NFC}$)    | baseline             | strict NFC productive capacity                                   |
| B     | ($Y^{Corp*}$) | (K^{Corp})          | ($\omega^{Corp,*}$) | parallel baseline    | corrected corporate reproduction capacity                        |
| C     | ($Y^{NFC}$)   | ($K^{NFC}$)         | ($\omega^{Corp*}$)  | alternative baseline | NFC capacity conditioned by corporate-wide distributive conflict |
| D     | raw BEA/NIPA  | official/raw stocks | raw shares          | diagnostic only      | accounting sensitivity                                           |

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

## Procedural lock on sectoral accounting

S10 must build the strict NFC layer, the Shaikh-corrected corporate layer, and the mixed Marxian conditioning layer.

The strict NFC layer remains the narrow productive-capacity baseline.

The Shaikh-corrected corporate layer is a broader corporate reproduction-capacity layer.

The mixed layer is admissible because the distributive struggle conditioning technique choice may operate at the corrected corporate/class level even when the productive-capacity object remains nonfinancial corporate.

No later S20, S30, S32, or S40 result can be promoted unless its sectoral layer is explicitly identified.
