---
type: workflow_optimization
date: 2026-07-29
context: Dissertation econometrics + academic writing pipeline
---

# Model Selection Strategy for Chapter 2 Workflow

## Your task profile

- **Econometric pipeline:** Multi-stage R scripts (integration tests → VECM → threshold VECM → episode classification)
- **Theoretical work:** Heterodox macro, political economy interpretation, mechanism synthesis
- **Academic writing:** Progress reports, methodology exposition, limitation framing
- **Infrastructure:** Repo structure, data governance, reproducibility audits
- **Integration:** Holding full project graph in mind (theory ↔ code ↔ data ↔ output)

---

## Model selection by task type

### 1. ECONOMETRIC SCRIPTING (S30, S32, S40, S50 implementation)

**Use:** **Sonnet** (primary) → fallback to **Opus** if blocked

**Why Sonnet:**
- 200k context = can hold entire script + one output ledger + error message
- Strong on R syntax, package semantics, debugging statistical code
- Good at "fix this error" or "implement this spec" without over-explaining
- Faster iteration (cheaper tokens) for trial-and-error script development

**When to use Opus instead:**
- Script has contradictory objectives or complex conditional logic (e.g., S50's 4-way triangulation)
- You're stuck on "how should this stage conceptually work?" (architectural decisions)
- The script must coordinate 3+ prior stage outputs (dependencies)
- Error message is cryptic and requires reasoning across multiple files

**Token budget:**
- Sonnet: 1–3 turns per script (build → test locally → iterate)
- Opus: 1 turn for architectural clarification, then back to Sonnet for coding

**Prompt template:**
```
I'm implementing [stage name] of the Chile BOP-binding pipeline.
Input: [data source/prior ledger]
Output: [expected CSV/figure]
Spec: [from handoff brief]
Current blocker: [error or design question]
Write [R/Python/LaTeX].
```

---

### 2. THEORETICAL INTERPRETATION & MECHANISM SYNTHESIS

**Use:** **Opus** (primary) → **Sonnet** for drafting

**Why Opus:**
- Your theory draws on 3+ heterodox traditions (Kaldor, Okishio, regulation theory, Shaikh)
- Mechanism logic requires holding ~5 conceptual layers in mind simultaneously
  - Firm-level accumulation → sectoral composition → macro disequilibrium → periphery constraint
- Interpreting econometric results through political economy lens (not just "coefficient is significant")
- Needs to spot when results are contradictory or when interpretation is circular

**Example:** S40 result is p=0.374 (threshold effect rejected). Opus should ask:
- Does this invalidate the binding hypothesis, or just the *threshold mechanism*?
- Does the linear ECT still signal import compression in regime-specific terms?
- How does this square with the historical crisis episodes in S50?

**When to use Sonnet:**
- You have the interpretation figured out; need prose draft of specific section
- Mechanical synthesis (e.g., "summarize S30–S40 results into methodology")

**Token budget:**
- Opus: 2–3 turns per major interpretive question (e.g., "what do asymmetric adjustment speeds mean for Kaldor?")
- Then Sonnet: 1 turn to draft the paragraph

**Prompt template:**
```
I'm interpreting [econometric result] through [theoretical frame].
Finding: [result + p-value or CI]
Theory predicts: [what Kaldor/Okishio would expect]
Puzzle: [what doesn't fit]
Help me think through whether [alternative interpretation] holds.
```

---

### 3. ACADEMIC WRITING & REPORT ASSEMBLY (S99 progress report)

**Use:** **Opus** (first full draft) → **Sonnet** (revision) → **Humanized-writing** + **prose-register-critic** skills

**Why Opus for first draft:**
- Needs to hold entire report structure (intro, methodology, results, limitations, next steps)
- Must coordinate 4 prior stages' outputs + skills (umass-applied-econometrics, academic-paper, heterodox-economics-review)
- Needs to read 3 interdependent skill instructions + integrate them
- Your voice has constraints (WLM v4.0, no hedging, evidence+verdict in same paragraph)
- Needs to flag where uncertainty genuinely exists vs. where you're just being cautious

**Why Sonnet for revision:**
- Tightening prose, checking citations, formatting tables
- "Does this paragraph match the UMass style guide?"
- Fixing small inconsistencies across sections

**Token budget:**
- Opus: 1 full draft turn (load all skills, all ledgers, produce ~8k words)
- Sonnet: 2 revision passes (one for macro-level consistency, one for polish)

**Prompt template for Opus:**
```
Write the S99 progress report for the Chile BOP-binding paper using these inputs:

Authority:
- Structure: chapter2_vault/06_paper_facing/00N_Map.md
- Notation: 00S_Notation_Lock.md
- Governance: AGENTS.md

Skills to invoke:
- umass-applied-econometrics (visual-first exposition, forensic provenance)
- academic-paper (BLUF intro, evidence map, limitations)
- heterodox-economics-review (Kaldor mechanism interpretation)

Inputs:
- S30 integration-order verdict (all variables assessed, I(1)/I(2)/mixed verdicts recorded)
- S32 break-aware machinery (breaks @ 1936/1991, exploratory status)
- S40 ECT-TVECM (threshold effects NOT significant: Hansen-Seo p=0.374/0.0721/0.852)
- S50 BOP-binding chronology (episode panel with 4-way classification)

Constraints:
- No hedging; evidence and verdict in same paragraph
- Machinery's I(2) status is exploratory—report alongside ARDL fallback, don't hide
- Threshold effect is not formally supported—say so clearly
- Next decision is explicit: if p<0.05 on Hansen-Seo, threshold is policy object; if p≥0.05, linear VECM is correct

Sections:
1. Introduction (BLUF): research question + status
2. Methodology: integration-order battery + break-aware route + ECT-TVECM
3. Empirical results: elasticities + regime speeds + bootstrap evidence
4. What remains unresolved: machinery I(2), threshold effect p-values, RER-only comparison
5. Next decision: conditional on Hansen-Seo verdict

Output: Markdown source + embedded figures + ledger references.
```

---

### 4. INFRASTRUCTURE & REPO OPTIMIZATION

**Use:** **Sonnet** (primary) → **Opus** only for architectural decisions

**Why Sonnet:**
- Namespace conflicts, directory naming, file organization = straightforward logic
- YAML frontmatter standardization, indexing = pattern matching
- Creating audit scripts, migration tools = tactical coding

**When to use Opus:**
- "Should the v1_1 release inherit v1, or rebuild from source?"
- "Does archiving .agents/ create a reproducibility risk?"
- Deciding between 2 competing governance structures (decision tree)

**Token budget:**
- Sonnet: 2–3 quick turns per task (index.md, deprecation notices, cleanup scripts)
- Opus: 1 turn for each major design decision

**Prompt template:**
```
I'm optimizing the repo structure for larger Claude models.
Current state: [problem]
Goal: [indexing/governance/cleanup]
Constraints: [reproducibility, team handoff, locked authority files]
Propose a solution with concrete file paths and before/after tree.
```

---

### 5. CODE DEBUGGING & ERROR RECOVERY

**Use:** **Sonnet** (first try) → **Opus** if the error crosses multiple files or conceptual layers

**Why Sonnet usually works:**
- "Error X at line Y in function Z" = localized
- Sonnet can read your code + error + fix it in one turn
- R package errors, missing imports, syntax = Sonnet's bread and butter

**When Opus is needed:**
- Error is a symptom of a conceptual mismatch (e.g., "stage output doesn't match expected schema")
- Bug is in the *interaction* between your code and a prior stage's output
- You need to trace back through 3+ functions to find the real issue

**Token budget:**
- Sonnet: 1 turn per error
- Opus: 1 turn if Sonnet's fix doesn't work (escalation)

---

## Workflow patterns: which model, when

### Pattern 1: "Build a new stage script"
1. **Claude Code (local R environment)** writes the first draft using Sonnet
2. **You test locally**; if error, return to Claude Code with error + context
3. If stuck → **Cowork (Sonnet):** Quick fix-and-test loop
4. If conceptually broken → **Cowork (Opus):** Rearchitect the stage

### Pattern 2: "Interpret a result"
1. **Cowork (Opus):** Read ledger → Ask "what does this mean?" → Get full interpretive brief
2. **Cowork (Sonnet):** Draft the interpretation into prose
3. **Claude Code (Sonnet):** Polish and cite

### Pattern 3: "Write the final report"
1. **Cowork (Opus):** Full first draft, invoking skills, coordinating 4 prior stages
2. **Cowork (Sonnet):** Revision pass (prose tightening, table checking)
3. **You (or Claude Code):** LaTeX compilation + final PDF

### Pattern 4: "Audit or plan work"
1. **Cowork (Sonnet):** Quick audit (file lists, checksums, schema validation)
2. **Cowork (Opus):** If audit finds inconsistencies or planning is complex (dependencies across stages)

---

## Token efficiency rules

**Goal: Finish dissertation without exhausting token budget.**

### Rule 1: Sonnet for code, Opus for thinking
- Sonnet can write good code faster (cheaper tokens)
- Opus thinks better about what code to write
- **Workflow:** Opus designs, Sonnet codes

### Rule 2: Local execution first, Cowork for coordination
- Run R scripts locally in RStudio (you control when)
- Use **Cowork Sonnet** for quick error fixes
- Use **Cowork Opus** only for decisions that cross multiple stages

### Rule 3: Frozen releases are your token budget friend
- Once S40 ledgers are locked, S50 **consumes only those CSVs**—no re-querying or re-estimation
- This means S50 is smaller, faster, cheaper than if you kept re-running upstream stages
- **Implication:** Invest Opus tokens early (S30–S40) to get the causal logic right, then Sonnet can efficiently build S50–S99 on frozen inputs

### Rule 4: Skills compress your work
- Loading `umass-applied-econometrics` in one Opus turn saves you 3–4 manual turns of style-checking
- Loading `academic-paper` structure saves you outlining time
- **Result:** One expensive Opus turn with skills loaded beats three cheap Sonnet turns without them

### Rule 5: Delegate local execution
- **Cowork (Sonnet/Opus)** = Planning, design, interpretation, debugging
- **Claude Code (Sonnet, on your local machine)** = Actual R execution, package management, file I/O
- **You (RStudio)** = Monitor, spot-check results, make judgment calls
- This keeps you under token budget because local code execution doesn't consume Claude tokens

---

## Recommended token allocation for Chapters 2 completion

| Stage | Model | Turns | Est. Tokens | Purpose |
|---|---|---|---|---|
| S50 design | Opus | 1 | 40k | Architectural brief: how to triangulate ECT + WBOP + history |
| S50 coding | Claude Code (Sonnet) | 2 | 30k | Write script, debug |
| S50 audit | Cowork (Sonnet) | 1 | 15k | Verify outputs |
| S99 first draft | Cowork (Opus) | 1 | 60k | Full report with skills |
| S99 revision | Cowork (Sonnet) | 2 | 30k | Polish + consistency |
| **Total** | | **7** | **~175k** | **Full pipeline completion** |

**For comparison:** Codex alone ran ~120k tokens before exhaustion. This revised plan is actually *cheaper* because Opus is used strategically (architecture + first draft) rather than for everything.

---

## Model-specific capabilities summary

| Task | Haiku | Sonnet | Opus |
|---|---|---|---|
| R script debugging | ❌ Limited | ✅ Excellent | ✅ Excellent |
| Statistical interpretation | ⚠️ Surface-level | ✅ Good | ✅ Excellent |
| Econometric design | ❌ Not recommended | ⚠️ Okay | ✅ Best |
| Theoretical synthesis | ❌ Not recommended | ⚠️ Okay | ✅ Best |
| Academic writing | ⚠️ Draft only | ✅ Good | ✅ Best |
| Holding 200k context | ❌ No | ✅ Yes | ✅ Yes |
| Holding full project graph | ❌ No | ⚠️ Difficult | ✅ Yes |
| Cost efficiency (tokens/useful output) | ✅ Best | ✅ Good | ⚠️ Expensive but justified for complex work |

---

## Your call

**Start with this strategy:** Sonnet for S50 scripting + debugging, Opus for S99 first draft with skills loaded. If S50 gets stuck on architecture, escalate to Opus for one clarifying turn, then back to Sonnet for execution.

**Monitor:** Track tokens on each turn in Cowork (visible in task output). If you exceed ~175k before reaching final report PDF, we can compress S99 by:
- Giving you a detailed outline instead of full first draft (Sonnet reads outline, writes)
- Splitting S99 into methodology + results (Opus draft method, Sonnet drafts results)

**Questions before you start S50?**
