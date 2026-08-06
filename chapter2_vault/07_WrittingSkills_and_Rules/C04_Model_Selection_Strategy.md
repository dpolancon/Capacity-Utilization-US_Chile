---
type: system_guidance
status: active
country: US_CL
stage: all
last_updated: 2026-07-29
layer: implementation
scope: dissertation_ch2
priority: core
depends_on: [AGENTS.md, CLAUDE.md, HANDOFF_S40_TO_S99_FOR_CLAUDE_CODE.md]
---

# Model Selection Strategy for Chapter 2 Workflow

**When to use Haiku vs. Sonnet vs. Opus for your econometrics + academic writing pipeline.**

---

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

---

### 2. THEORETICAL INTERPRETATION & MECHANISM SYNTHESIS

**Use:** **Opus** (primary) → **Sonnet** for drafting

**Why Opus:**
- Your theory draws on 3+ heterodox traditions (Kaldor, Okishio, regulation theory, Shaikh)
- Mechanism logic requires holding ~5 conceptual layers simultaneously
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
- Opus: 2–3 turns per major interpretive question
- Then Sonnet: 1 turn to draft the paragraph

---

### 3. ACADEMIC WRITING & REPORT ASSEMBLY (S99 progress report)

**Use:** **Opus** (first full draft) → **Sonnet** (revision)

**Why Opus for first draft:**
- Needs to hold entire report structure (intro, methodology, results, limitations, next steps)
- Must coordinate 4 prior stages' outputs + skills (umass-applied-econometrics, academic-paper, heterodox-economics-review)
- Your voice has constraints (WLM v4.0, no hedging, evidence+verdict in same paragraph)
- Needs to flag where uncertainty genuinely exists vs. where you're just being cautious

**Why Sonnet for revision:**
- Tightening prose, checking citations, formatting tables
- "Does this paragraph match the UMass style guide?"
- Fixing small inconsistencies across sections

**Token budget:**
- Opus: 1 full draft turn (load all skills, all ledgers, produce ~8k words)
- Sonnet: 2 revision passes (one for macro-level consistency, one for polish)

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
- Deciding between 2 competing governance structures

---

### 5. CODE DEBUGGING & ERROR RECOVERY

**Use:** **Sonnet** (first try) → **Opus** if the error crosses multiple files or conceptual layers

**Why Sonnet usually works:**
- "Error X at line Y in function Z" = localized
- Sonnet can read your code + error + fix it in one turn
- R package errors, missing imports, syntax = Sonnet's bread and butter

**When Opus is needed:**
- Error is a symptom of a conceptual mismatch
- Bug is in the *interaction* between your code and a prior stage's output
- You need to trace back through 3+ functions to find the real issue

---

## Workflow patterns: which model, when

### Pattern 1: "Build a new stage script"
1. **Claude Code (Sonnet)** writes the first draft using your local R environment
2. **You test locally in RStudio**; if error, return to Claude Code with error + context
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
2. **Cowork (Opus):** If audit finds inconsistencies or planning is complex

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

## Recommended token allocation for Chapter 2 completion

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

| Task | Haiku | Fable | Sonnet | Opus |
|---|---|---|---|---|
| R script debugging | ❌ Limited | ⚠️ Risky | ✅ Excellent | ✅ Excellent |
| Statistical interpretation | ❌ No | ⚠️ Basic | ✅ Good | ✅ Excellent |
| Econometric design | ❌ No | ❌ No | ⚠️ Okay | ✅ Best |
| Theoretical synthesis | ❌ No | ❌ No | ⚠️ Okay | ✅ Best |
| Academic writing | ❌ No | ⚠️ Revision only | ✅ Good | ✅ Best |
| Prose tightening/polish | ⚠️ Limited | ✅ Good | ✅ Good | ✅ Good |
| Table reformatting | ⚠️ Risky | ✅ Good | ✅ Good | ✅ Good |
| File organization/metadata | ⚠️ Basic | ✅ Good | ✅ Good | ✅ Good |
| Holding 200k context | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| Holding full project graph | ❌ No | ❌ No | ⚠️ Difficult | ✅ Yes |
| Cost efficiency (tokens/useful output) | ✅ Best | ✅ Excellent | ✅ Good | ⚠️ For complex work |

---

## Fable strategy (new, cost-effective option)

**Fable pricing:** ~1/3 cost of Sonnet per token. Your $100 budget = ~3x token volume of same Sonnet budget.

**Best uses for Fable:**
- S99 revision pass 1: Prose tightening, consistency checking (not architectural decisions)
- S99 revision pass 2: Final polish, table formatting
- Quick metadata tasks: Create indices, organize files, format CSVs
- Low-risk edits: Reformat figures, adjust captions, fix cross-references

**When NOT to use Fable:**
- S50 design or implementation (too complex for Fable reasoning)
- S40 result interpretation (needs econometric depth)
- Debugging cryptic R errors (Fable may miss subtle issues)
- S99 first draft (need Opus to hold the full architecture)

**Fable + Sonnet hybrid workflow:**

| Stage | Step 1 | Step 2 | Cost |
|---|---|---|---|
| S50 | Opus: design brief | Sonnet: code + debug | High |
| S99 first draft | Opus: full draft + skills | (skip) | High |
| S99 revision | Sonnet: macro consistency | **Fable: final polish** | Medium |
| Metadata | (skip) | **Fable: indices/organization** | Low |

**Revised token budget with Fable:**

| Stage | Model | Turns | Est. Tokens | Cost |
|---|---|---|---|---|
| S50 design | Opus | 1 | 40k | $1.20 |
| S50 coding | Sonnet | 2 | 30k | $0.90 |
| S50 audit | Sonnet | 1 | 15k | $0.45 |
| S99 first draft | Opus | 1 | 60k | $1.80 |
| S99 revision 1 | Sonnet | 1 | 15k | $0.45 |
| S99 revision 2 | **Fable** | 1 | 20k | $0.20 |
| Metadata/index | **Fable** | 2 | 30k | $0.30 |
| **Total** | | **9** | **210k tokens** | **~$5.30** |

**Net:** $100 budget is more than enough. Use Fable aggressively for revision + metadata work.

---

## Key decisions

**Recommended approach:** 
1. Opus for architecture (S50 design, S99 first draft)
2. Sonnet for coding + macro-level revision
3. **Fable for final polish + metadata** (this is where your $100 shines)

**Practical workflow:**
- Start with Sonnet for S50 (get it working)
- Use Opus once (S50 design brief if stuck, OR S99 full draft)
- Use Fable for final S99 polish (prose tightening, table formatting)
- Use Fable for any metadata work (indices, file organization)

**Monitor:** You'll likely use <$10 on core pipeline with this strategy, leaving $90 for experimentation or additional polish passes.

See also: [[../00_constitutive_core/01_Governing_Memo]], [[C03-REPO_STRUCTURE]], [[AGENTS]]
