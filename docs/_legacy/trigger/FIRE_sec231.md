# READY-TO-FIRE PROMPT: §2.3.1 — Stagnation and Crisis: A Typology
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

## SHARED CONTEXT (architecture, notation, data)

CHAPTER: "Demand-Led Profitability and Structural Crisis of Capitalism in Chile and the
United States during the Fordist Era"
Governing outline: Ch2_Outline_DEFINITIVE.md (§2.1–§2.9, 33 subsections)

THREE-STAGE EMPIRICAL ARCHITECTURE:
- Stage A: MPF cost-minimization + 4-variable VECM on (y,k,π,πk) with CV1–CV3
  → structurally identified μ̂_t, b̂_t, θ̂_t
  · Stage A.1 (US, center): Route 1 direct MPF + 4-var system validation
  · Stage A.2 (Chile, periphery): Route 2, 4-var restricted VECM primary; no employment needed
  · CV1 (confinement): y - θ₁k - θ₂(πk) = μ̂
  · CV2 (Phillips curve): π = ϱ(y - θ₁k - θ₂πk)
  · CV3 (Cambridge-Goodwin): [-2, (2+θ₁), -1, θ₂]·X = -δ
- Stage B: Weisskopf profitability decomposition using Stage A outputs
- Stage C: FM spec (full Weisskopf disaggregation) as primary investment function;
  KR and BM as tested compressions — NOT sequential steps

TWO-LAYER ACCOUNTING/BEHAVIORAL IDENTIFICATION:
- Layer 1 (accounting): g_K ≡ χπμb; r ≡ μbπ; Cambridge: k = χr - δ
- Layer 2 (behavioral): ln g_K = c + β₁lnπ + β₂lnμ + β₃lnb; β_j=1 = Cambridge benchmark;
  η_j = β_j - 1 = behavioral content
- FM spec is the Layer-1 default: three channels separately. KR and BM are compressions
  tested via Wald restrictions within FM.

NOTATION (locked — enforce strictly, flag violations):
- Uppercase = levels; lowercase = log-levels; dot notation (ẋ) for time derivatives of ratios
- μ_t = Y_t/Y^p_t (capacity utilization) — NEVER "u"
- b_t = Y^p_t/K_t (capital productivity at normal capacity)
- π_t = Π_t/Y_t (profit share)
- χ_t = I_t/Π_t (recapitalization rate) — NOT β; β is reserved for cointegrating vectors
- κ_t = I_t/K_t (capital accumulation rate, Robinson convention)
- a_t = χ_t (rate of capitalization — DV in Stage C alternative)
- θ_t = θ₁ + θ₂π_t (distribution-conditioned transformation elasticity)
- q ≡ K̇/K - L̇/L (mechanization growth rate) — NOT m (m = import share/propensity)
- M = imports levels; K^NR = nonresidential structures; K^ME = machinery and equipment
- e = exploitation rate EXCLUSIVELY; Euler's number = exp(·)
- MPF (not IPF); "Harrodian benchmark" (not "natural rate of growth"); never "interregnum"
- BANNED: hat notation x̂ for growth rates in theory → use ẋ

DATA SOURCES:
- US: dpolancon/US-BEA-Income-FixedAssets-Dataset (BEA + FRED API, R pipeline)
  · K^NR = nonresidential structures; K^ME = equipment (BEA Fixed Assets Table 2.1)
- Chile: dpolancon/K-Stock-Harmonization (canonical Pérez 1900-1994 + BCCh extension 1900-2024)
  · K^ME = machinery; K^NR = construction — capital type split available directly
  · Primary period: 1945-1978 (Stages B+C); Stage A full available sample

STYLE:
- Academic prose, no bullet points in body text
- Present tense for theory and mechanisms; past for empirical findings
- Heterodox framing: "regime", "tendency", "structural determination" — avoid mainstream causal language
- Include equations as displayed LaTeX where specified
- Write in paragraphs; lists only for tables or enumerated results

---

## SECTION-SPECIFIC INSTRUCTIONS

You are a heterodox macroeconomics dissertation writing assistant. Draft §2.3.1 of the chapter.



SECTION SPEC:
This is §2.3.1 within the Analytical Framework section. Keep it tight — it is the
typological setup, not the main theoretical contribution.

Vidal (2014, 2019) distinctions: stagnation tendency (downward pressure on profitability,
inherent), partial crisis (interruption resolvable by partial reconfiguration of Λ),
structural crisis (deep interruption requiring drastic restructuring of Λ). 

The Basu (2019) typology (redefined in Vidal's terms), as a displayed table:

|                   | Excess of Surplus Value      | Deficit of Surplus Value    |
|---|---|---|
| Demand side       | Under-consumption/realization | Profit squeeze              |
| Financial side    | Financial fragility           | Falling normal profit rate  |

This grid is the interpretive template for Stage B (which channel dominates per sub-period?)
and Stage C (which channel drives recapitalization?). Introduce it here; return to it in
§2.6 and §2.8. Transition to §2.3.2.

TARGET: ~300 words including table. Economical.
