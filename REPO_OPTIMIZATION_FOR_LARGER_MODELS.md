---
type: infrastructure_optimization
date_created: 2026-07-29
target_audience: Claude Opus / Sonnet models
purpose: Token efficiency, navigation speed, context completeness
authority: CLAUDE.md + README.md + AGENTS.md
---

# Repo Optimization for Larger Claude Models

## Current State Snapshot

- **Total markdown:** 27,775 lines across vault
- **Vault structure:** 10 primary directories + legacy/archive subdirs
- **Authority files:** 4 locked (constitution, map, symbology, notation)
- **Code files:** 75 total (53 active econometrics + implementation)
- **Data sources:** 3 primary (US BEA, Chile K-stock, Chile profit share)
- **Metadata debt:** .agents folder (1.1M, old session artifacts)
- **Legacy files:** Distributed across 03_econometrics/_legacy, 06_paper_facing/_legacy, 09_legacy

---

## Why This Matters for Larger Models

**Claude Opus / Sonnet have 200k context windows** vs. Haiku's 100k. The opportunity is not just size—it's **depth and simultaneity**. Larger models can:

- Hold the entire vault structure in mind without re-reading
- Track dependencies across theory → code → data → output
- Spot redundancy or gaps across sections without fragmented navigation
- Commit to decisions once (in project files) rather than re-deriving constraints per task

**Current friction:** Vault structure requires models to infer dependencies. Add a navigation layer and you unlock simultaneous reasoning across theory, code, and evidence.

---

## Priority 1: Authority & Navigation Layer

### 1.1 Create `_INDEX.md` — Single Entry Point

**Purpose:** All models should start here. Maps the entire vault, surface dependencies, flags locked files.

**Location:** `chapter2_vault/_INDEX.md`

**Content structure:**

```markdown
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
```

### 1.2 Create `DEPENDENCY_MANIFEST.md`

**Purpose:** Show which files depend on which other files. Helps models avoid circular reasoning.

**Content template:**

```markdown
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
```

---

## Priority 2: Archive & Deprecation Cleanup

### 2.1 Archive `.agents` Folder

**Issue:** 1.1M of session metadata from old exploratory work. Not needed for future model runs.

**Action:**
```bash
mkdir -p chapter2_vault/99_archive/old_agent_sessions
mv .agents/* chapter2_vault/99_archive/old_agent_sessions/
rmdir .agents
```

**Document:** Add a `DEPRECATION.md` to 99_archive:
```markdown
# Deprecated Materials

## .agents/ Session Artifacts (Archived 2026-07-29)

These were outputs from multi-agent teamwork previews. They are archived for reference only.
Do not restore this structure or use these prompts for new work.

Authority for current work is always:
- CLAUDE.md
- chapter2_vault/06_paper_facing/
- chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md
```

### 2.2 Consolidate `03_econometrics/_legacy` → `99_archive`

**Action:**
```bash
mv chapter2_vault/03_econometrics/_legacy/* chapter2_vault/99_archive/legacy_econometrics/
```

**Add `03_econometrics/README.md`:**
```markdown
# Econometrics Specifications

## Active Estimator: Polynomial Cointegration (CPR)

See: N01_CapacityUtilization_StructuralObject.md

## Deprecated Explorations

See: ../99_archive/legacy_econometrics/ for:
- DOLS vs. FM-OLS vs. IM-OLS comparisons
- Earlier threshold-model attempts
- Interaction-term integration-order work (now consolidated in E_*.md)

These are provided for understanding the research process, not for current work.
```

### 2.3 Create `DEPRECATION_NOTICES.md`

**Purpose:** Flag files that should not be used, prevent models from defaulting to old logic.

```markdown
# Deprecation Notices

## Files to Ignore (or read for history only)

| File Path | Why Deprecated | Replacement |
|---|---|---|
| chapter2_vault/01_contradictory_utilization_configurations/okishio_macro_anarchy_bridge/archive_raw_briefs/ | Research notes; logic is in 02_analyitical_foundation | See 02_analyitical_foundation/H00_Okishio_Vidal_Decentralized_Accumulation.md |
| 03_econometrics/_legacy/*.md | Old estimator debates; settled | See N01_CapacityUtilization_StructuralObject.md for current spec |
| 06_paper_facing/_legacy/ | Pre-constitution drafts | See 00E & 00N current authority |
| 09_legacy/ | Pre-restructure vault org | Use _INDEX.md to navigate current structure |

## What to do if you find yourself in a deprecated file

1. Stop reading it for policy/logic guidance
2. Find its replacement in the table above
3. If you need historical context, document the question and note the archive location
```

---

## Priority 3: Quick-Reference Sheets (Single-Page Scanning)

### 3.1 `NOTATION_SHEET.md`

Extract this from 06_paper_facing/00S and make it **scannable** at the top of the vault.

```markdown
# Locked Notation (Chapter 2)

## Capacity Utilization & Transformation Elasticity

| Symbol | Definition | Never Use | Notes |
|---|---|---|---|
| μ_t | Capacity utilization = Y / Y^p | u, U, u_t | Reconstructed object, not residual |
| θ_t | Transformation elasticity | β_t, m_t | Mediates ω → Y^p; distribution-conditioned |
| χ_t | Recapitalization rate = I / Π | β_t | Fixed capital reinvestment |
| q | Mechanization growth rate | m | Not import share (m = import propensity) |
| Y | Output (level) | — | Observed |
| Y^p | Potential productive capacity | Y*, Y_trend | Reconstructed via θ identification |
| ω_t | Wage share | w, ω | Distribution parameter |
| K^NR | Nonresidential structures capital | K_struct | BEA layer |
| K^ME | Machinery & equipment capital | K_equip | BEA layer |

## Conventions

- **Uppercase:** Levels (Y, K, Π)
- **Lowercase:** Log-levels (y, k, π)
- **Dot notation:** Growth rates (ẏ = d log Y / dt)
- **Subscript t:** Time index
- **Subscript j:** Cointegrating vector index (β_j)

## Key Chains (Never Violate)

ω_t → θ_t → Y^p_t → μ_t

External constraint (Peru only) → χ_t adjustment → modified θ_t
```

### 3.2 `STAGE_GATES.md`

Extract from 05_codes_implementation/C03 and make it a one-pager.

```markdown
# Stage Gate Rules (Chapter 2)

## Specification Advancement Constraints

**No nonlinear, interacted, or generated specification may advance to estimator selection before passing:**

`chapter2_vault/03_econometrics/Interaction_Term_Integration_Order_Gate.md`

## Active Stages (as of 2026-07-29)

### US Track (S35 — Refreeze)
- Status: Estimator locked (CPR / Polynomial Cointegration)
- Last stage: S35 (VECM validation + factor-loading audit)
- Next: S40 (final utilization reconstruction + appendix figures)
- Code: US_S* prefix

### Chile Track (CL_S10 — Rebuild)
- Status: Data reconstruction in progress
- Last stage: CL_S10 (WBOP reconciliation + RER base audit)
- Next: CL_S15 (external constraint evidence layer)
- Code: CL_S* prefix

## Stage Progression Policy

1. **Data stage** (S0–S10) — Source of truth locked in; auxiliary layers can be added
2. **Specification stage** (S15–S30) — Can iterate; must pass gate before estimator
3. **Estimator stage** (S35+) — Locked; only validation runs after this
4. **Freezepoint** (S40+) — Results published; no model re-estimation

**Freeze point** for US: S40 (end July 2026)
**Current target** for Chile: S35 (end August 2026)
```

### 3.3 Create `AUTHORITY_CHECKLIST.md`

Quick reference for which files to update when changing different aspects:

```markdown
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
```

---

## Priority 4: Code-to-Theory Index

### 4.1 Create `codes/README.md` 

Map which code files implement which theoretical objects.

```markdown
# Code Index (Chapter 2)

## By Stage & Country

### US Track

#### S00–S10: Data Staging
- US_S05_*.R — Read BEA files, validate K stock
- US_S10_*.R — Construct Y, K, ω vectors; synchronize to Chile calendar

#### S15–S30: Specification & Estimation
- US_S15_*.R — Test cointegration order
- US_S20_*.R — Estimate long-run transformation relation (θ identification)
- US_S25_*.R — Recover Y^p from θ estimates
- US_S30_*.R — Reconstruct μ from Y^p + normalization

#### S35+: Validation & Output
- US_S35_*.R — VECM stability, residual diagnostics
- US_S40_*.R — Final figure/table generation for paper

### Chile Track

#### CL_S00–S10: Data Reconstruction
- CL_S05_*.R — BCCH/INE query + raw series staging
- CL_S10_*.R — WBOP reconciliation, RER base audit
- CL_S10_structural_break_*.R — Identify regime breaks (1973, 1990)

#### CL_S15–S30: External Constraint & Specification
- CL_S15_*.R — External balance evidence layer
- CL_S20_*.R — Model external constraint; test admissibility
- CL_S25_*.R — Stationary accumulation breaks; recapitalization analysis
- CL_S30_*.R — Estimate transformation relation w/ external mediation

#### CL_S35+: Estimation & Comparison
- CL_S35_*.R — VECM with external constraint
- CL_S40_*.R — μ reconstruction; center-periphery comparison figures

## By Theoretical Object

### θ_t Identification
- codes/US_S20_*.R, CL_S30_*.R (Polynomial Cointegration / CPR)
- Output: 03_econometrics/N01_CapacityUtilization_StructuralObject.md (theta_hat table)

### Y^p Reconstruction
- codes/US_S25_*.R, CL_S35_*.R
- Dependency: θ estimates (prior stage)

### External Constraint Modeling (Chile only)
- CL_S20_external_constraint_*.R
- Theory: 02_analyitical_foundation/[regulation theory notes]

### Recapitalization χ_t
- CL_S25_stationary_accumulation_breaks.R
- Theory: Needs linking to 00_constitutive_core/ profit-rate-of-profit section (if exists)

## Dependency: Data → Code → Output → Paper

See DEPENDENCY_MANIFEST.md for full chain.
```

---

## Priority 5: Standardize Metadata Frontmatter

### 5.1 Template (Copy to all vault files)

```yaml
---
type: [research_note | theory | econometrics | code_governance | paper_facing]
status: [active | locked | deprecated | archived | draft]
country: [US | CL | US_CL]
stage: [S00-S40 | N/A]
last_updated: [YYYY-MM-DD]
depends_on: [file paths]
blocks: [file paths]
layer: [theory | empirics | design | implementation | archive]
scope: [chapter2 | methodology | dissertation]
priority: [core | reference | context | legacy]
---
```

### 5.2 Audit & Fix

```bash
# Find all .md files missing frontmatter
grep -L "^---" chapter2_vault/**/*.md

# Find all with incomplete frontmatter
grep "status: draft" chapter2_vault/**/*.md  # Should be rare in 06_paper_facing
```

---

## Priority 6: Quick-Check Templates for Models

### 6.1 At Session Start (Add to Skill Prompt)

```markdown
## Context Loading Sequence for Larger Models

If you're working on Chapter 2:

1. **[30 sec]** Read: chapter2_vault/_INDEX.md
2. **[2 min]** Read: NOTATION_SHEET.md + STAGE_GATES.md
3. **[5 min]** Read: Relevant section of DEPENDENCY_MANIFEST.md
4. **[On demand]** Read: Specific vault file from 00_constitutive_core/ or 06_paper_facing/

Do not start with codes/ or data/ without understanding:
- Current stage (S35 US, CL_S10 Chile)
- What you're trying to identify (θ? μ? external constraint?)
- Which paper section it feeds (06_paper_facing/00N_Map.md)
```

### 6.2 Decision Tree (Add to .claude/skills or CLAUDE.md)

```markdown
## Decision Tree: Where Should I Look?

### "What is the theoretical claim?"
→ 06_paper_facing/00E_Constitution.md (150 lines, locked)

### "What's the paper structure?"
→ 06_paper_facing/00N_Map.md (260 lines, locked)

### "What notation should I use?"
→ 06_paper_facing/00S_Notation_Lock.md + NOTATION_SHEET.md

### "What code implements X?"
→ codes/README.md + codes/[country_stage]_*.R

### "How does data flow?"
→ DEPENDENCY_MANIFEST.md + data/metadata/

### "Can I change the specification?"
→ 05_codes_implementation/C03-REPO_STRUCTURE.md + stage gates

### "Is this file still active?"
→ Check `status:` in frontmatter; if `deprecated`, see DEPRECATION.md

### "What's blocking me?"
→ STAGE_GATES.md or check `blocks:` in dependent file's frontmatter
```

---

## Implementation Roadmap

### Immediate (Today)

1. **Create `_INDEX.md`** → Copy structure above, fill in dates/paths
2. **Create `NOTATION_SHEET.md`** → Extract from 00S, format as table
3. **Create `STAGE_GATES.md`** → Extract from C03, add current status
4. **Create `AUTHORITY_CHECKLIST.md`** → Copy template above

**Effort:** ~1 hour | **Benefit:** 10x faster model onboarding

### Short-term (This week)

5. **Create `DEPENDENCY_MANIFEST.md`** → Map file dependencies
6. **Create `codes/README.md`** → Index code by stage/object
7. **Standardize frontmatter** → Add to all active vault files
8. **Create `DEPRECATION.md`** → Archive old agent sessions

**Effort:** ~3 hours | **Benefit:** Models can spot redundancy and gaps

### Medium-term (Next 2 weeks)

9. **Archive `.agents` folder**
10. **Consolidate _legacy folders**
11. **Create verification checks** (script to validate frontmatter, check for orphaned files)
12. **Add to project automation** (pre-commit hook to validate structure)

**Effort:** ~2 hours | **Benefit:** Reduced clutter; trustworthy metadata

---

## Expected Improvement

| Task | Before | After | Gain |
|---|---|---|---|
| Model onboarding time | 30+ min (reading README, inferring structure) | 5 min (_INDEX + NOTATION + GATES) | 6x faster |
| Finding "where is X?" | 2–3 minutes (grep + inference) | 30 sec (consult index) | 4x faster |
| Dependency tracking | Implicit (models must infer) | Explicit (DEPENDENCY_MANIFEST) | Eliminates circular reasoning |
| Specification changes | Risk of violating stage gate | Clear gate + checklist | Risk ↓ 90% |
| Code-theory linkage | Unclear | codes/README.md | Simultaneous reasoning across layers |

---

## Notes for Larger Models

- These changes are **retroactive documentation**, not restructuring. No code moves until archiving step.
- Authority files (06_paper_facing/) remain locked. Index layer just makes them findable.
- This is especially valuable for **Opus / Sonnet** because they can hold the full dependency graph in mind and spot redundancy across sections.
- **Haiku models** still benefit (faster navigation) but cannot fully exploit the simultaneity.

---

**Status:** Ready for implementation  
**Owner:** Diego  
**Next checkpoint:** After implementing Priority 1 & 2, test with Opus on a real task (e.g., "Review chapter 2 introduction draft")
