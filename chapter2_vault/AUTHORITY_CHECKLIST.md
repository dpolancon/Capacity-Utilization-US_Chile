---
type: research_note
status: active
country: US_CL
stage_scope: N/A
last_updated: '2026-07-29'
depends_on: []
blocks: []
layer: design
scope: chapter2
priority: reference
---

# Authority File Checklist

## Changing the theoretical claim?
- [ ] Update 06_paper_facing/00E_Constitution.md
- [ ] Check consistency with 00N_Map.md section burdens
- [ ] Check consistency with 00_constitutive_core/ problem statement
- [ ] Validate against 06_paper_facing/00S_Notation_Lock.md

## Adding new data source or layer?
- [ ] Document in 04_data_measurement/
- [ ] Update data/metadata/data_provenance_manifest.md
- [ ] Update CLAUDE.md data sources table
- [ ] Link to code that ingests it (codes/)

## Changing estimator or specification?
- [ ] Check 05_codes_implementation/C03-REPO_STRUCTURE.md stage contract
- [ ] Validate against 03_econometrics/Interaction_Term_Integration_Order_Gate.md
- [ ] Update code stage (S* prefix) in codes/
- [ ] Update output/ directory structure if stage changed

## Adding new section to paper?
- [ ] Validate against 06_paper_facing/00N_Map.md section burdens
- [ ] Check that it doesn't violate "What must not appear" in that section
- [ ] Check notation against 00S_Notation_Lock.md
- [ ] Link to underlying vault sections

## Archiving old work?
- [ ] Move to 99_archive/ with clear dating
- [ ] Add entry to DEPRECATION.md
- [ ] Do NOT restore old structure or voice to active work