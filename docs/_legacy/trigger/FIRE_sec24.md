# READY-TO-FIRE PROMPT: §2.4 — Data
# Ch2 — Demand-Led Profitability and Structural Crisis
# Paste this ENTIRE file as a single message in a new claude.ai session (in this project)

## VOICE CONSTRAINTS (WLM v4.0)

# Ch2 Voice Guide — WLM v4 Calibration
## Paste this block BEFORE any section prompt in a claude.ai session

> **Authority:** Voice Exemplars v4 (2026-03-29) + Ch1/Ch2 approved prose (WLM v4.0)
> **Scope:** All Ch2 prose. Governs lit review, analytical framework, identification sections, conclusions.
> **Not negotiable:** These are structural constraints, not stylistic preferences.

---

## STRUCTURAL RULES (hard constraints)

**Rule 1 — Evidence and verdict in the same paragraph.**
Never decouple. If a paragraph establishes a fact, it must also close the argumentative consequence of that fact. A paragraph that ends with evidence instead of a verdict has failed.

**Rule 2 — Every citation does argumentative work.**
References are not background. They are premises. Never open a sentence with "As X argues" neutrally — integrate the citation into the claim it supports.

**Rule 3 — Institutional anchors are arguments, not context.**
When an institution, regulation, or historical settlement appears, it should constrain or explain something in the current argument, not merely locate it in time.

**Rule 4 — "Therefore" is a verdict connective, not a transition.**
Use it only when the preceding sentence earns the conclusion. If "therefore" can be deleted without losing logic, replace it or cut the sentence.

**Rule 5 — Two-movement paragraphs for evaluative content.**
Genuine achievement / systematic problem. Critique / concession. Contribution / limit. The second movement is not optional — it is what makes the paragraph earn its place.

---

## SENTENCE-LEVEL TECHNIQUES (from Voice Exemplars v4)

**T1 — Object-constitution move:** Redefine the object before analysing it.
> *"This section reconstructs... not as a narrow sequence of statistical refinements, but as a history of statecraft."*

**T2 — "Therefore precise" verdict:** The argument arrives as a verdict, not a summary.
> *"The category error is therefore precise: the Federal Reserve Board series was built to produce a stable, institutionally credible signal... making stationarity a design objective, not a discovered property."*

**T3 — "What matters is not X but Y":** Clear the field before the claim.
> *"What distinguishes Shaikh from every other participant in this debate — including Nikiforos — is that he does not stop at critiquing the measurement instrument. He reconstructs the data itself."*

**T4 — Exit ramp sentence:** Last sentence of a paragraph completes the argument and opens the next object.
> *"The limit of Shaikh's identification strategy is equally specific... It requires a conceptual framework that defines the theoretical object the elasticity proxies for. The next section provides both."*

**T5 — Two-movements in one paragraph:**
> *"Two distinct impulses characterize the literature. The first is genuine empirical achievement... The second is the systematic macro-deferral that undoes the first... The two coexist as a structural contradiction that the field's disciplinary constitution has not resolved."*

---

## APPROVED EXEMPLARS — Ch1 prose in the capacity utilization register

These show the voice working on exactly this subject matter. Match this register.

**Exemplar A (object-constitution + institutional anchor):**
> "Both traditions adjudicate this question using the Federal Reserve Board's capacity utilization series — an instrument whose stochastic properties are artifacts of construction rather than properties of the underlying economic process. The FRB series was built to produce a stable, institutionally credible signal for monetary policy governance within a historically specific Fordist settlement that made slack legible, actionable, and contestable. Its stationarity is a design feature, not a discovered property of the data."

**Exemplar B (evidence → verdict in one paragraph):**
> "Admissibility fails on Shaikh's own terms. The F(10,50)=6257 he reports is the OLS goodness-of-fit statistic, not the PSS 2-restriction bounds test... Under proper bound testing, evidence of co-integration survives only under Case 1... Cases 2 and 3 fail entirely. This evidence is favorable to an unbalanced growth closure, with a long-run tendency towards over-accumulation of productive capacities."

**Exemplar C (two movements, no hedging):**
> "What distinguishes the two sides of this exchange is not only their theoretical commitments but their relationship to the measurement instrument itself. Nikiforos's intervention is the most self-reflexive move within the tradition: he subjects both the theory and the data infrastructure to scrutiny... The Sraffian-convergence response, by contrast, defends the instrument it relies on without interrogating its construction — and when it does engage the measurement question... the engagement rests on a misreading of the very source it cites."

---

## PROHIBITIONS

- ❌ No passive for the chapter's own moves: "This section argues" not "It is argued"
- ❌ No hedging on theoretical claims: "Layer 1 establishes" not "Layer 1 may be taken to suggest"
- ❌ No orphaned conclusions: every verdict must follow from the evidence preceding it
- ❌ No neutral summaries of other scholars' positions — every summary must do argumentative work
- ❌ No "this is important because" — show why it is important through the argument itself
- ❌ No outsourced authority: do not import citations to justify a claim that the chapter's own accounting or theoretical framework already establishes. Ask: "is this citation doing argumentative work from within this chapter's framework, or borrowing credibility from an external authority?" If the latter, cut it. Ch2 has sufficient theoretical apparatus to reject HP filtering, motivate the 4-variable system, and derive the peripheral cost-minimization without deferring to mainstream econometrics papers. Hamilton (2018) belongs in Ch1, not Ch2.

---

## Ch2-specific register notes

**For theory sections (§2.3, §2.5):** Equations are not interruptions. Introduce each equation as the formal statement of a claim already established in prose. After the equation, immediately state what it implies — not what it means symbolically.

**For literature review sections (§2.2):** Each subsection has a verdict. The last paragraph of a subsection closes with a statement about what the literature cannot do, which sets up what Chapter 2 does.

**For identification sections (§2.5.1–§2.5.5):** The structural novelty is not just the method — it's why the standard approach fails. Lead with the failure, then derive the solution.

---

*WLM v4.0 calibration | Ch2 voice guide | 2026-04-02*
*Authority: Voice Exemplars v4 (Notion) + Ch1 approved prose (Chapter1_CriticalReplication.tex)*


---

## SHARED CONTEXT



---

## SECTION-SPECIFIC INSTRUCTIONS

You are a heterodox macroeconomics dissertation writing assistant. Draft §2.4 (Data, all
three subsections: §2.4.1 United States, §2.4.2 Chile, §2.4.3 Sample and Periodization)
of the chapter.



SECTION SPEC:
This section is primarily descriptive and table-driven. Keep prose tight.

§2.4.1 UNITED STATES — dpolancon/US-BEA-Income-FixedAssets-Dataset:
State upfront: both datasets are the author's own constructions, maintained in reproducible
GitHub repositories. Secondary sources enter as inputs to those pipelines, not as direct
chapter inputs.

Produce a variable table:
| Variable | Symbol | Source | Notes |
| Real GDP | Y_t | NIPA Table 1.1.6 | |
| National income components | Π_t, W_t | NIPA Table 1.12 | π_t derived |
| Net nonresidential capital stock | K_t | BEA Fixed Assets Table 2.1 | |
| Net capital — structures | K_t^NR | BEA Fixed Assets Table 2.1 | Stage A comparator |
| Net capital — equipment | K_t^ME | BEA Fixed Assets Table 2.1 | Stage A comparator |
| Gross nonresidential investment | I_t | NIPA Table 1.1.5 | |
| Employment | L_t | BLS CES (FRED) | For a_t = y_t - l_t, q_t = k_t - l_t |
| Interest rate | i_t | Moody's Baa / Fed Funds (FRED) | Stage C (Shaikh spec) only |
Sample: ~1929–2024 available; primary estimation 1945–1978.

§2.4.2 CHILE — dpolancon/K-Stock-Harmonization:
Three production surfaces (table): Hofman accounting reference (1900-1994, 1980 CLP, frozen);
Canonical Pérez baseline (1900-1994, 2003 CLP, Pérez machinery + construction, inventories
excluded — PRIMARY); BCCh extension bundle (1900-2024, 2003 CLP, canonical 1900-1994
preserved — EXTENDED).

Capital type decomposition — load-bearing for Stage A.2:
K^ME_t = machinery component; K^NR_t = construction component.
This resolves the Stage A.2 capital-type stage-gate: direct disaggregation available.

Additional supplementary variables table (GDP, investment, profit share, employment,
terms of trade) with sources (CEPAL, Alarco Tosoni 2014, Astorga 2023, Díaz et al. 2016).

Sample: capital stock 1900-2024; GDP/income ~1940-2024; primary estimation 1945-1978.

§2.4.3 SAMPLE AND PERIODIZATION:
Stage A uses full available sample for MPF estimation and CU recovery.
Stages B and C use 1945-1978 as primary window. Include sample table.
Sub-period turning points identified endogenously from wage-share dynamics (Shaikh 2016
invariance principle — no mechanically imposed periodization).
Chile 1973-1975: coup disruption; MPF estimated excluding 1973-1975; sensitivity reported.

TARGET: ~600 words plus three tables. Informational and precise.
