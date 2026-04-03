# READY-TO-FIRE PROMPT: §2.5.1 — Structural Problem + Two Routes + 4-Variable System
# Ch2 — Demand-Led Profitability and Structural Crisis
# Paste this ENTIRE file as a single message in a new claude.ai session (in this project)
# ═══════════════════════════════════════════════════════════════════════

## VOICE CONSTRAINTS (WLM v4.0) — apply to every paragraph

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



---

## SECTION-SPECIFIC INSTRUCTIONS

You are a heterodox macroeconomics dissertation writing assistant. Draft §2.5.1 of the chapter.



SECTION SPEC:
This is the methodological heart of Stage A. Three parts:

PART 1 — The structural problem:
HP-filter and peak-output methods impose θ(Λ)=1 by construction — balanced growth assumed,
productive capacity grows at the same rate as capital stock. This conflates the demand channel
(μ) with the technology channel (b) in the Weisskopf decomposition. Hamilton (2018) adds:
HP-filtered series generate spurious low-frequency cycles, sensitive to endpoint behavior.

The stationarity imposition problem (state explicitly): single-equation identification
imposes stationarity on μ̂_t by construction. If CU is genuinely I(1), this produces a
spurious cointegrating vector. The identification should be empirical, not imposed.

PART 2 — The 4-variable over-identified system:
State vector: (y_t, k_t, π_t, (πk)_t) — four variables, all potentially I(1). The
interaction term πk is NOT a linearization convenience — it is what makes θ̂_t = θ₁ + θ₂π_t
distribution-dependent. Removing it from the state vector collapses θ̂ to a fixed parameter.

Three cointegrating restrictions, sharing parameters θ₁, θ₂:

CV1 (confinement): y_t - θ₁k_t - θ₂(π_t k_t) = μ̂_t
  → [1, -θ₁, 0, -θ₂]·X_t = μ̂_t

CV2 (Phillips curve, from Ch1):
  π_t = ϱ(y_t - θ₁k_t - θ₂π_t k_t)
  → [-ϱ, ϱθ₁, 1, ϱθ₂]·X_t = 0

CV3 (Cambridge-Goodwin profitability):
  k_t = (y_t - k_t) + π_t + (y_t - θ₁k_t - θ₂π_t k_t) - δ
  → [-2, (2+θ₁), -1, θ₂]·X_t = -δ

Distributional variation is confined through CV2 and CV3 — π_t cannot vary freely;
it is anchored by the structural distribution-CU and profitability channels.

Over-identification: parameters {θ₁, θ₂, ϱ, δ} shared across three equations → more
cross-equation restrictions than free parameters on a single structural object (θ̂_t).
Tests: H₀: θ₂ = 1/2 (Cajas-Guijarro quadratic MPF); consistency of θ₁, θ₂, ϱ, δ
across equations; rank test without imposing stationarity.

Rank determination on (y, k, π, πk): Johansen trace and max-eigenvalue on 4-variable
system. Rank tested, not assumed.

PART 3 — Two estimation routes:
Route 1 (US primary): direct MPF regression a_t = α₁q_t + α₂q_t² using BLS employment.
Identifies α₁, α₂, q*_t. Tests θ₂ = 1/2 against 4-variable system.

Route 2 (Chile primary): restricted VECM on (y,k,π,πk) with θ₁,θ₂,ϱ,δ constrained
equal across CV1-CV3. No employment needed. Rank tested, not imposed.

TARGET: ~900 words. Include all four cointegrating vectors as displayed equations. This is
the chapter's core methodological contribution — write with precision and confidence.
