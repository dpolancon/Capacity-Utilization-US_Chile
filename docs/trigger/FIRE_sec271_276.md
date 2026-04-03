# READY-TO-FIRE PROMPT: §2.7.1-§2.7.6 — Stage C: Investment Function (Full Section)
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

You are a heterodox macroeconomics dissertation writing assistant. Draft the full §2.7
(Stage C: Investment Function Estimation, all six subsections §2.7.1–§2.7.6) of the chapter.



CRITICAL ARCHITECTURAL RULE: The FM spec is the PRIMARY model — motivated by Layer 1
(three distinct channels, entered separately by default) and Layer 2 (behavioral coefficient
interpretation). KR and BM are tested compressions, NOT sequential steps. The chapter does
NOT build from simple to complex — it starts from the full disaggregation and tests whether
compressions are warranted.

§2.7.1 ARDL ARCHITECTURE:
Method: ARDL bounds testing (Pesaran, Shin and Smith 2001). Cointegration structurally
guaranteed by the accounting identity g_K = χπμb. Lag selection AIC/BIC, max lag 4.
CUSUM/CUSUM-sq for parameter stability. All specs estimated for both κ_t and a_t = χ_t.

§2.7.2 PRIMARY MODEL — FM SPEC (Full Weisskopf Disaggregation):
  y_t = ψ₀ + ψ₁b̂_t + ψ₂π_t + ψ₃μ̂_t + η_t

Stage A outputs b̂_t and μ̂_t enter directly. Why Stage A is load-bearing: HP-filtering
imposes θ=1, collapsing μ and b into a single channel — the Okishio Wald test requires
the channel separation that Stage A provides.

Layer-2 coefficient interpretation table:
| Coeff. | Accounting benchmark (β_j=1) | Behavioral reading (η_j = ψ_j - 1) |
|---|---|---|
| ψ₁ | Cambridge closure on b | χ elasticity w.r.t. capital productivity |
| ψ₂ | Cambridge closure on π | χ elasticity w.r.t. profit share |
| ψ₃ | Cambridge closure on μ | χ elasticity w.r.t. CU |

Okishio Wald test (primary hypothesis):
  H₀: ψ₁ = ψ₃  (⟺ β₂ = β₃ in Layer-2 notation)
Rejection: CU has independent recapitalization effect; the crisis trigger fires.
Two readings: macro (Okishio) and firm-level (Vidal §2.2.4 — ψ₃ is regime-specific;
CUSUM instability confirms).

§2.7.3 SHAIKH NET-PROFITABILITY TEST:
Augment FM: add i_t (interest rate) as separate regressor.
  H₀: ψ₂^π = -ψ₄^i (net profitability restriction)
Decision rule: if not rejected, determines whether compression tests use gross or net r.

§2.7.4 COMPRESSION TEST 1 — BHADURI-MARGLIN:
  y_t = γ₀ + γ₁ρ_t + γ₂π_t + η_t  where ρ = μb
Wald restriction within FM: H₀: ψ₁ = ψ₃ (same as Okishio null — the BM compression
is warranted iff the Okishio null is not rejected). Identifies profit-led vs. wage-led.
Also estimated directly for comparison.

§2.7.5 COMPRESSION TEST 2 — KEYNES-ROBINSON:
  y_t = α₀ + α₁r_t + ε_t
Joint Wald within FM: H₀: ψ₁ = ψ₂ = ψ₃. KR is the limiting compression benchmark.
Also estimated directly.

§2.7.6 WALD TEST SEQUENCE TABLE:
| Test | Null | Determines |
|---|---|---|
| 1. Shaikh (within FM) | ψ₂^π = -ψ₄^i | Gross or net r in compressions |
| 2. Okishio (within FM) | ψ₁ = ψ₃ | CU crisis trigger; BM compression warranted? |
| 3. BM restriction | Technology-demand compressible into ρ | BM vs. FM |
| 4. KR restriction | All channels compressible into r | KR vs. FM |

Key: Tests 2 and 3 are the SAME null. Rejecting Okishio rejects BM simultaneously.

TARGET: ~1200 words for all six subsections. Include all equations as displayed. Include
the three tables (§2.7.2 interpretation, §2.7.6 sequence). Write §2.7.1–§2.7.6 as
flowing prose sections with the subsection headers marked clearly.
