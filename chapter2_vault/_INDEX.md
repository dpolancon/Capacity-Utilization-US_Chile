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

# Chapter 2 Vault Index

## Locked Authority Files (Do Not Modify)

| File | Role | Last Updated | Depends On |
|---|---|---|---|
| 06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md | Paper-facing core claim | 2026-04-23 | None (foundational) |
| 06_paper_facing/00N_Chapter2_PaperFacing_MAP.md | Section sequencing & burdens | 2026-07-23 | Constitution |
| 06_paper_facing/00S_Chapter2_Symbology_and_Notation_Lock.md | All notation rules (BINDING) | 2026-07-27 | Constitution |
| 05_codes_implementation/C03-REPO_STRUCTURE.md | Stage gates & contracts | [check date] | Map |

## Theoretical Foundation (Read First)

### Core Logic Chain
00_constitutive_core/ → 01_contradictory_utilization_configurations/ → 02_analyitical_foundation/ → 03_econometrics/

**Key sequence:**
1. 00_constitutive_core/02_Research_Problem.md — Problem statement
2. 01_contradictory_utilization_configurations/01_Theoretical_Core_Notebook.md — Mechanism
3. 02_analyitical_foundation/A00_Aggregate_Transformation_Benchmark.md — Formal model
4. 03_econometrics/N01_CapacityUtilization_StructuralObject.md — Empirical object

## Implementation (Codes & Data)

### Active Stages

| Stage | Country | Status | Code Prefix | Output Dir |
|---|---|---|---|---|
| S35 | US | Active (refreeze) | US_S* | output/US/ |
| CL_S10 | Chile | Rebuild | CL_S* | output/CL/ |

**Code organization:** Flat, country/stage-prefixed in `codes/`  
**Data flow:** raw/ → interim/ → processed/ → final/ → releases/

## Navigation by Persona

### Theory-first (Building arguments)
→ Start: 06_paper_facing/00E_Constitution.md  
→ Then: 01_contradictory_utilization_configurations/  
→ Then: 02_analyitical_foundation/

### Code-first (Implementing specs)
→ Start: 05_codes_implementation/C03-REPO_STRUCTURE.md  
→ Then: codes/ [country_stage prefix]  
→ Then: 03_econometrics/ [spec name]

### Evidence-first (Assessing empirical support)
→ Start: 03_econometrics/N01_CapacityUtilization_StructuralObject.md  
→ Then: output/[US|CL]/ [stage]  
→ Then: 02_analyitical_foundation/R04_Measurement_and_Accounting_Consistency.md

## Stage Gates & Constraints

See `05_codes_implementation/C03-REPO_STRUCTURE.md` for:
- Stage progression rules
- Specification contracts
- Estimator advancement criteria
- Interaction term integration-order gate

**Key:** No nonlinear/interacted specification advances before passing `03_econometrics/Interaction_Term_Integration_Order_Gate.md`

## Legacy / Archive (Read Only)

| Path | Status | Last Used | Notes |
|---|---|---|---|
| 03_econometrics/_legacy/ | Read-only | Jul 2026 | Deprecated estimator explorations |
| 06_paper_facing/_legacy/ | Read-only | Mar 2026 | Pre-constitution drafts |
| 09_legacy/ | Archive | Before Jul 2026 | Pre-restructure vault organization |

**Policy:** Do not restore old outlines or voice from legacy. Authority is 06_paper_facing/00E & 00N.

## Meta: Notation Lock

**Always use:**
- μ_t = capacity utilization (never "u")
- χ_t = recapitalization rate (never β_t for this)
- q = mechanization growth rate
- θ_t = distribution-conditioned transformation elasticity
- Uppercase = levels; lowercase = logs

See `06_paper_facing/00S_Chapter2_Symbology_and_Notation_Lock.md` for full reference.

## Quick-Check: Am I Looking at the Right File?

- **Changing theory?** → Must update 06_paper_facing/ files and 00_constitutive_core/
- **Changing code?** → Check 05_codes_implementation/ stage contract first
- **Adding data?** → See 04_data_measurement/ + data/ structure
- **Estimator decision?** → Check 03_econometrics/ stage gate + 05_codes_implementation/
- **Writing prose?** → See chapter2_paper/ + 07_WrittingSkills_and_Rules/

---