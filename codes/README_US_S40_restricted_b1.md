# US S40 Restricted B1 Reconstruction Contract

## Purpose

This file defines the contract for:

`codes/US_S40_theta_tot_mu_reconstruction.R`

S40 is a reconstruction stage, not an estimator stage.

It opens only because S30 returned:

`s40_gate = pass_restricted_fragility_flag`

for:

`SPEC_B1_WAGE_BASELINE`

Therefore, S40 may proceed only as a restricted B1 pathway with explicit fragility flags.

---

## Binding upstream gate

S40 must read:

`output/US/S30_transformation_relation/us_s30_formal_stability_decision.csv`

Required conditions:

- `candidate_spec_id = SPEC_B1_WAGE_BASELINE`
- `tier1_pass = TRUE`
- `s40_gate` is either:
  - `pass_restricted`
  - `pass_restricted_fragility_flag`
- `non_b1_specs_promoted = FALSE`
- `no_s40_code = TRUE`
- `no_mu_computation = TRUE`
- `no_chile_outputs = TRUE`

If these conditions fail, S40 must stop.

---

## Reconstruction sequence

S40 must follow:

    S30 coefficient recovery
    → theta_tot reconstruction
    → productive-capacity reconstruction
    → level anchoring
    → derived utilization

Formal sequence:

    estimated reduced-form relation
    → θ_t^tot
    → Y_t^p
    → level anchoring
    → μ_t

S40 must not identify utilization by residual.

The residual is an implication of reconstruction, not the object of identification.

---

## Estimator hierarchy

S40 must preserve the locked S30 estimator hierarchy:

    FM-OLS = main reconstruction basis
    IM-OLS = robustness metadata
    DOLS   = fragility / stress metadata

DOLS may not define:

- θ_t^tot
- Y_t^p
- μ_t
- level anchoring
- reconstruction admissibility

DOLS flags must be carried forward as fragility metadata only.

---

## Candidate restriction

S40 is restricted to:

`SPEC_B1_WAGE_BASELINE`

No other specification may enter S40.

Explicitly forbidden:

- B0 promotion
- C1 promotion
- C2 promotion
- D1 promotion
- D2 promotion
- estimator-grid expansion
- window shopping
- new specification search

---

## Measurement register

S40 uses the capacity register.

The relevant capital object is gross real GPIM capital interpreted as:

> constant-price purchasing power embodied in heterogeneous capital goods still in operation.

Forbidden:

- net current-cost capital as capacity stock
- gross current-cost capital as capacity stock
- profitability denominator inside S40
- profit-rate reconstruction

Profitability belongs downstream, not in S40.

---

## Composition status

The US composition variable is a Tier-B ME–NRC component proxy.

It is not a direct nonfinancial-corporate-by-asset-type machinery share.

If composition variables are used or passed through, metadata must preserve:

    sector_target = NFCorp
    composition_basis = ME_NRC_component_proxy
    composition_tier = Tier B
    direct_sector_asset_split = FALSE
    capacity_register = gross_real_GPIM

Real-volume composition is structural.

Current-cost composition and:

`pK_relative_ME_NRC`

are diagnostics only.

---

## Required inputs

Required S30 inputs:

- `output/US/S30_transformation_relation/us_s30_formal_stability_decision.csv`
- `output/US/S30_transformation_relation/us_s30_formal_spec_disposition.csv`
- `output/US/S30_transformation_relation/us_s30_estimator_grid.csv`
- `output/US/S30_transformation_relation/us_s30_specification_register.csv`
- `output/US/S30_transformation_relation/us_s30_candidate_window_register_used.csv`
- `output/US/S30_transformation_relation/us_s30_run_manifest.csv`

Required data input:

- current US source-of-truth or S20 panel used by S30

The script must detect and report the exact panel path used.

---

## Required outputs

Export destination:

`output/US/S40_theta_tot_mu_reconstruction/`

Required files:

- `us_s40_theta_tot_path.csv`
- `us_s40_productive_capacity_path.csv`
- `us_s40_mu_path.csv`
- `us_s40_anchor_register.csv`
- `us_s40_fragility_register.csv`
- `us_s40_reconstruction_manifest.csv`
- `US_S40_theta_tot_mu_reconstruction_report.md`

---

## Anchor rule

S40 must use an explicit level anchor.

Record in:

`us_s40_anchor_register.csv`

Required fields:

- anchor variable
- anchor year or anchor window
- anchor value
- normalization rule
- rationale
- inherited/new status

No silent normalization is allowed.

---

## Fragility rule

If S30 reports:

`s40_gate = pass_restricted_fragility_flag`

then all S40 outputs must carry:

`fragility_flag = TRUE`

Fragility register fields:

- S30 Tier 2 evidence class
- DOLS fragility flag
- DOLS contradiction windows
- whether DOLS veto was disabled
- S40 admissibility status

The report must state:

> S40 proceeds as a restricted B1 reconstruction under fragility, not as a clean benchmark promotion.

---

## Hard prohibitions

S40 must not:

- estimate a new cointegrating relation
- expand estimator grids
- use DOLS as reconstruction basis
- promote non-B1 specifications
- compute profitability
- touch Chile outputs
- create comparative outputs
- activate threshold-FGLS
- infer θ_t^M as directly estimated
- identify utilization by residual
- silently choose a new anchor

---

## Ready to code only if

- S30 restricted gate exists
- B1 is the only promoted specification
- active branch = `feature/us-s40-restricted-b1`
- working tree is clean
- output restricted to:

`codes/US_S40_theta_tot_mu_reconstruction.R`

and:

`output/US/S40_theta_tot_mu_reconstruction/`