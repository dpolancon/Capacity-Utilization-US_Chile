# READY-TO-FIRE PROMPT: §2.9 — Conclusions and Contributions (Skeleton)
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

You are a heterodox macroeconomics dissertation writing assistant. Draft §2.9 (Conclusions
and Contributions) of the chapter as a SKELETON — write all interpretive and framework prose
fully, but use [PLACEHOLDER: value] for any specific empirical results.



SECTION SPEC:
Three-part deliverable structure:

PART 1 — CU identification:
Structurally identified μ̂_t^US and μ̂_t^CL for both countries — available as inputs to
downstream work. The identification rests on the 4-variable VECM with distribution-conditioned
θ̂_t = θ₁ + θ₂π̂_t^LR — the first such identification in the literature that allows CU to
be I(1) without imposing stationarity by construction. Compare against HP-filter: [PLACEHOLDER:
direction and magnitude of divergence]. Stage A.2 additionally identifies the center-periphery
mechanization gap: θ̂^US - θ̂^CL = [PLACEHOLDER] decomposed into [PLACEHOLDER] MPF-slope
and [PLACEHOLDER] BoP-penalty components.

PART 2 — Profitability channels (Stage B):
Dominant stagnation tendency per sub-period, mapped onto the §2.3.1 typology. [PLACEHOLDER:
US sub-period narrative]. [PLACEHOLDER: Chile sub-period narrative]. The Weisskopf
decomposition using structural μ̂_t differs from HP-filter benchmark in [PLACEHOLDER: direction].

PART 3 — Recapitalization law and crisis trigger (Stage C):
FM spec results: ψ₁ = [PLACEHOLDER], ψ₂ = [PLACEHOLDER], ψ₃ = [PLACEHOLDER].
Okishio Wald verdict: [PLACEHOLDER: reject / fail to reject]. Center-periphery comparison:
ψ₃^US vs. ψ₃^CL — [PLACEHOLDER: direction and interpretation]. CUSUM stability of ψ₃:
[PLACEHOLDER: stable or breaks and at what date].

CONTRIBUTIONS (write fully — no placeholders):
1. First structural CU identification from over-identified 4-variable VECM without stationarity
   imposition — center (US) and periphery (Chile) compared
2. Stage A.2 peripheral extension: BoP-constrained cost-minimization with capital composition
   (K^NR + K^ME); center-periphery mechanization gap derived from the FOC, not imposed
3. FM-first investment function with Okishio Wald test — the Cajas-Guijarro structural CU
   is precisely what makes this test identified; HP-filter would prevent it
4. Kaldor-ECLA fault line as an estimable structural question: BoP ceiling vs. internal
   consumption drain decomposed from the center-periphery θ gap

FORWARD REFERENCES: Ch3 inherits μ̂_t, b̂_t, θ̂_t as given inputs — no re-estimation.
The Weisskopf decomposition and Okishio trigger become Ch3 applications.

APPROVED PUNCHLINE (use verbatim at or near the end): "Demand conditions intervene on
the political economy of the ceiling, i.e. the class struggle over distribution, utilization,
and the institutional forms that govern whether accumulation can proceed."

TARGET: ~700 words. Write the framework prose fully; [PLACEHOLDER] only where results
are pending. End with the approved punchline.
