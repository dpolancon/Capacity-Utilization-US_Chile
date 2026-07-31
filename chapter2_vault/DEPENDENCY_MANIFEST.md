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

# Dependency Manifest

## Upstream → Downstream

### Constitution (Source of Truth)
06_paper_facing/00E_Constitution.md
├─→ 06_paper_facing/00N_Paper_Map.md
├─→ 06_paper_facing/00S_Symbology_Lock.md
├─→ 00_constitutive_core/01_Governing_Memo.md
└─→ All paper-facing sections

### Theoretical Foundation
00_constitutive_core/02_Research_Problem.md
├─→ 01_contradictory_utilization_configurations/03_Core_Claims_and_Punchlines.md
├─→ 02_analyitical_foundation/[all files]
└─→ 03_econometrics/N01_CapacityUtilization_StructuralObject.md

### Empirical Infrastructure
03_econometrics/N01_CapacityUtilization_StructuralObject.md
├─→ codes/CL_S* & US_S* (all stages)
├─→ output/[US|CL]/ (stage-specific results)
└─→ 06_paper_facing/[empirical claims in paper]

## Reverse: "If I modify X, what breaks?"

[Maps for each authority file]