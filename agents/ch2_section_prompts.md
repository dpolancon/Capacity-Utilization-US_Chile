# Ch2 Agent Prompts — Copy-Paste Ready
## Capacity Utilization: Center & Periphery
### Usage: copy one block → paste into Claude (VS Code extension, claude.ai, or any interface)

---

<!-- ============================================================
     SHARED CONTEXT BLOCK
     Every prompt below contains this embedded.
     You do NOT need to paste this separately — it's inside each prompt.
     ============================================================ -->

---

## PROMPT §2.1 — Introduction

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.1 (Introduction) of Chapter 2: "Capacity Utilization in the Center and the Periphery: Old Debates and New Estimates."

NOTATION (locked — never violate):
- Uppercase = levels (Y, K, B, Λ); lowercase = logs (y, k)
- μ_t = capacity utilization (Y_t/Y^p_t) — never "u"
- θ(Λ) = capacity transformation elasticity — UPSTREAM regime parameter, never FOC-derived
- π_t = profit share; e_t = exploitation rate ONLY (Euler's number = exp(·))
- ι_t = I_t/K_t; β_t = I_t/Π_t = recapitalization rate; B_t = Y^p_t/K_t
- MPF not IPF; "Harrodian benchmark" not "natural rate of growth"; never "interregnum"

ARCHITECTURE:
Stage A (RRR/CVAR): recovers μ̂_t as stationary residual of y_t = c + β₁k_t + β₂(π_t k_t) + ξ_t; endogenous elasticity θ_t = β₁ + β₂π_t.
Stage B (ARDL): behavioral accumulation law ln ι_t = c + b₁ ln π_t + b₂ ln μ̂_t + b₃ ln B̂_t + ε_t, with b_j = 1 + η_j.
IICS is a falsifiable hypothesis, not an imposed condition.
Tavares channel: peripheral β_t is structurally constrained by forex availability and import content of investment — the chapter's distinctive contribution.

SECTION SPEC:
Arc: crisis theory → CU as missing structural link → two-stage empirical machine → center/periphery comparison. Ch1 showed existing CU estimates impose balanced growth by construction (θ=1), suppressing regime-dependent content. Ch2 asks: what does CU do in the economy? Following Okishio (1961): CU path is a crisis trigger. Two-stage empirical machine: (i) identify μ_t as latent confinement object via RRR/CVAR; (ii) estimate behavioral recapitalization law conditional on recovered objects. Run same machine on US and Chile. The BoP constraint enters recapitalization differentially in the periphery: you have the surplus but cannot buy the machines (Tavares 1985). Three downstream outputs: μ̂_t, B̂_t/θ̂_t, behavioral accumulation law with tested closures. End with roadmap paragraph.

TARGET: ~600 words. Academic prose, present tense for theory, heterodox framing. No bullet points. End with a standard roadmap paragraph referencing §2.2–§2.11.
```

---

## PROMPT §2.2.1 — Stagnation Typology

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.2.1 (Stagnation and Crisis: A Typology) of Chapter 2.

NOTATION (locked): μ_t = capacity utilization; θ(Λ) = upstream regime parameter; MPF not IPF; "Harrodian benchmark" not "natural rate of growth."

SECTION SPEC:
Present the Vidal (2014, 2019) / Basu (2019) typology of stagnation tendencies. Two-by-two matrix: rows = Demand side / Financial side; columns = Excess of Surplus Value / Deficit of Surplus Value. Cells: under-consumption/realization crisis; profit squeeze (rising labor strength); financial fragility; falling (normal) rate of profit. Partial crisis = interruption resolvable by partial reconfiguration of Λ. Structural crisis = deep interruption requiring drastic restructuring. This is taxonomic setup — no equations required. The typology frames what kind of crisis CU dynamics can trigger. Transition sentence at end pointing to §2.2.2.

TARGET: ~350 words. Include the 2×2 table. Academic prose, no bullet points outside the table.
```

---

## PROMPT §2.2.2 — Okishio's Crisis Trigger

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.2.2 (Okishio's Crisis Trigger and Cumulative Disequilibrium) of Chapter 2.

NOTATION (locked): μ_t = capacity utilization (Y_t/Y^p_t) — never "u"; π_t = profit share; B_t = capital productivity at normal capacity. The Weisskopf decomposition is r_t = μ_t · B_t · π_t. Lowercase y, k = logs of Y, K.

SECTION SPEC:
Okishio (1961): decentralized capitalist decisions produce secular cumulative disequilibrium in CU. The mismatch between effective demand and productive capacity is systematically unstable. CU rates trend toward reversal of normal capacity but overshoot, producing stagnation episodes of increasing severity. Key: the crisis trigger is the PATH of μ_t, not a static level. Connect to Weisskopf (1979) decomposition r_t = μ_t B_t π_t: profitability is demand-led (μ_t scales normal profitability), so the CU path directly mediates the link between accumulation dynamics and crisis. Foreshadow the identification problem: to read this decomposition empirically, one needs a structurally identified μ_t. Transition to §2.2.3.

TARGET: ~450 words. Include the Weisskopf decomposition as a displayed equation. Academic prose.
```

---

## PROMPT §2.2.3 — From Profitability to Accumulation

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.2.3 (From Profitability to Accumulation: The Missing Link) of Chapter 2.

NOTATION (locked): μ_t = capacity utilization; β_t = I_t/Π_t = recapitalization rate; ι_t = I_t/K_t = gross accumulation rate. The Foley-Michl investment function is profit-oriented and market-share-oriented — never "optimal."

SECTION SPEC:
The literature has studied the tendency of the profit rate to fall (Basu & Manolakos 2012; Basu & Vasudevan 2013) but the causal link from profitability to crisis runs through accumulation demand (Basu & Das 2017; Ibarra 2023, 2024). The rate of profit matters because it drives the rate of investment. This chapter formalizes that link through the behavioral recapitalization law (ln ι_t = c + b₁ ln π_t + b₂ ln μ̂_t + b₃ ln B̂_t). The mechanism differs structurally between center and periphery: in the periphery, forex constraints bind the recapitalization response (Tavares 1985). Closing transition: to make the crisis-trigger hypothesis testable, μ_t must be identified structurally — not imposed by a filter. Ch1 showed why; §2.3 formalizes how.

TARGET: ~300 words. Academic prose, tight. This is a bridge subsection, not a standalone contribution.
```

---

## PROMPT §2.3 — Structural Primitives

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.3 (Structural Primitives: Production, Capacity, and Unbalanced Growth) of Chapter 2.

NOTATION (locked — enforce strictly):
- Uppercase = levels; lowercase = logs. y_t ≡ ln Y_t; k_t ≡ ln K_t.
- μ_t ≡ Y_t/Y^p_t = capacity utilization
- B_t ≡ Y^p_t/K_t = capital productivity at normal capacity
- θ(Λ) = capacity transformation elasticity — UPSTREAM regime parameter, pinned by institutional space Λ. NOT derivable from FOC. NOT a behavioral choice.
- y^p_t = θ(Λ) · k_t is a growth-rate relation, not a level production function.
- Balanced growth θ=1 is the knife-edge special case. The general case is θ≠1.

ARCHITECTURAL RULE: All steps in this section are pure accounting — no behavioral equation is imposed until §2.7. Flag this explicitly in the prose.

SECTION SPEC:
Leontief production structure: Y_t = min(B_t K_t, A_t L_t), both binding at μ_t=1. Output decomposition: Y_t = μ_t Y^p_t → y_t = y^p_t + ln μ_t. Capital productivity at normal capacity: B_t = Y^p_t/K_t → ln B_t = y^p_t - k_t. Unbalanced growth closure: y^p_t = θ(Λ) k_t. Proposition 1 (Confinement Identity): ln μ_t = y_t − θ(Λ) k_t. Explain economic content: (i) pure accounting identity; (ii) θ≠1 implies persistent structural disequilibrium in capital-output ratio; (iii) the Harrodian benchmark corresponds to θ=1 — the knife-edge that existing CU measures impose by construction. Transition to §2.4: to estimate the confinement identity, we need an empirically tractable specification of θ.

TARGET: ~600 words. Include Proposition 1 as a numbered proposition with proof in 2–3 lines. Academic prose.
```

---

## PROMPT §2.4 — Distribution-Conditioned Capacity

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.4 (Distribution-Conditioned Capacity: The Interaction Term) of Chapter 2.

NOTATION (locked):
- π_t = profit share = e_t/(1+e_t) where e_t is the exploitation rate
- z_t ≡ π_t · k_t = interaction term (constructed object, not a primitive state variable)
- θ_t = β₁ + β₂ π_t = endogenous long-run transformation elasticity (empirical proxy for general θ(e|Λ))
- β₁, β₂ are structural parameters of the cointegrating relation — NOT behavioral choices. θ is UPSTREAM.
- ξ_t = ln μ_t = stationary residual if rank-1 confinement holds
- IICS is a falsifiable hypothesis: the sign and magnitude of β₂ determine whether higher exploitation raises or depresses the capacity-transformation elasticity.

SECTION SPEC:
Profit share: π_t = e_t/(1+e_t). Interaction term z_t = π_t k_t as empirical proxy for θ(e|Λ)·k_t in the cointegrating space. Long-run capacity relation: y_t = c + β₁k_t + β₂(π_t k_t) + ξ_t, ξ_t ≡ ln μ_t. Endogenous elasticity: θ_t = β₁ + β₂ π_t. Proposition 2 (Rank-1 Identification): if the residual is I(0), then the recovered μ̂_t = y_t − ĉ − β̂₁k_t − β̂₂(π_t k_t). Three points: (1) θ is upstream — β₁ and β₂ are structural parameters, not behavioral choices; (2) the interaction term z_t rotates the cointegrating space — it is a constructed object needed to represent θ(e)·k in the VECM; (3) IICS is falsifiable through the sign of β₂. Transition to §2.5.

TARGET: ~500 words. Include Proposition 2 as a numbered proposition. Academic prose.
```

---

## PROMPT §2.5.1 — US Bridge

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.5.1 (US: From Ch1's ARDL to Ch2's Cointegrating Relation) of Chapter 2.

NOTATION: X^US_t = (y_t, k_t, π_t k_t)' = state vector. θ̂^S1 = Ch1 ARDL estimate of transformation elasticity. Data: BEA/FRED (y, k); NIPA Table 1.12 (e → π). Sample: 1947–2019.

SECTION SPEC:
Ch1's bivariate ARDL on (y_t, k_t) with VAcorp/KGCcorp data recovered θ̂^S1 and diagnosed rank-1 confinement (S2). Ch2 augments with z_t = π_t k_t, allowing θ_t to vary with distribution. The state vector becomes X^US_t = (y_t, k_t, π_t k_t)'. Positioning against existing US CU literature: CBO (2004), Adams & Coe (1990), Alichi (2015), Taylor (1993) multivariate filter methods, BQ/Keating/Herwartz SVAR tradition. Those approaches impose θ=1 or stationarity by construction — Ch1 demonstrated the structural deficiency. Ch2's identification is the alternative: it permits θ≠1 and recovers the distribution-conditioned capacity slope. The interaction term z_t is what these approaches systematically omit.

TARGET: ~400 words. Academic prose. Position against existing literature without dismissing it — frame as "alternative identification" not "superior method."
```

---

## PROMPT §2.5.2 — Chile: Parallel Construction

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.5.2 (Chile: Constructing the Parallel) of Chapter 2.

NOTATION: X^CL_t = (y^CL_t, k^CL_t, π^CL_t k^CL_t)'. Data sources: PWT rnna or Hofman (2000)/Lüders et al. (2016)/Pérez-Eyzaguirre (2019) spliced capital stock; Alarco Tosoni (2014) and Astorga (2023) wage share series. Sample: 1960–2019.

SECTION SPEC:
Data construction mirrors the US. Key difference: the Chilean capital stock requires splicing across three vintages. The profit share is constructed from national accounts (compensation of employees) spliced with Alarco Tosoni (2014) and Astorga (2023). Positioning against Chilean CU literature: BCCh structural balance fiscal framework, Magud & Medina (2011), Fuentes/Gredig/Larraín (2008), Durand & Fornero (2024), Figueroa/Fornero/García (2019). Key asymmetry: Chilean CU estimates are not just academic objects — they are governance variables feeding directly into the structural fiscal balance rule. Ch2's identification is an ALTERNATIVE that permits θ≠1 and recovers the distribution-conditioned slope. The structural contour literature (Spilimbergo 1999; Monfort 2008) provides the open-small-economy context.

TARGET: ~500 words. Academic prose. Make the governance-variable point crisp — it's a genuine contribution, not just a literature review.
```

---

## PROMPT §2.5.3 — Parallel as Method

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.5.3 (The Parallel Construction as Method) of Chapter 2.

SECTION SPEC:
Short methodological bridge (0.5 page). Both countries get the same X_t = (y_t, k_t, π_t k_t)', same Johansen procedure, same rank-1 identification. The structural comparison in §2.10 is meaningful BECAUSE the measurement apparatus is identical. The key asymmetries — US budget-baseline embedding vs. Chilean structural-balance embedding — are FINDINGS of the comparison, not artefacts of measurement. Close with a transition to §2.6.

TARGET: ~200 words. Tight. One key methodological point, stated clearly.
```

---

## PROMPT §2.6.1 — Stage A: Estimation Setup

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.6.1 (Estimation) of Chapter 2, covering the Johansen CVAR setup for Stage A.

NOTATION: X_t = (y_t, k_t, z_t)' where z_t = π_t k_t. r = cointegrating rank. Expected rank: r=1.

SECTION SPEC:
Johansen (1988) procedure on X_t = (y_t, k_t, π_t k_t)'. Rank determination: trace test H₀: r≤j vs H₁: r>j for j=0,1,2; max-eigenvalue test; finite-sample critical values (Johansen-Juselius 1990). Restricted constant specification: drift absorbed into cointegrating space, not the common trends. Break detection: Gregory-Hansen (1996) endogenous break at unknown date — particularly relevant for Chile given 1973 and 1982 regime shifts. Note the GPY2025 impossibility result: Appendix A1 proves β cannot be fully nonparametric, providing formal justification for constant cointegrating vectors within institutional regimes. This is the econometric motivation for the regime-by-regime identification strategy.

TARGET: ~400 words. Academic prose. Technical but readable — explain the restricted constant specification intuitively.
```

---

## PROMPT §2.6.2 — Stage A: US Results (skeleton)

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.6.2 (Results: US Baseline) of Chapter 2 as a SKELETON — structural narrative with placeholder slots for estimated values.

NOTATION: β̂₁, β̂₂ → θ̂^US_t = β̂₁ + β̂₂ π_t. Recovered ln μ̂^US_t = y_t − ĉ − β̂₁k_t − β̂₂(π_t k_t).

SECTION SPEC:
Write the section as it will read after estimation — use [VALUE] placeholders for actual estimates. Structure: (1) rank determination results — trace and max-eigenvalue tests supporting r=1; (2) estimated cointegrating vector — report β̂₁ and β̂₂ with standard errors; (3) implied θ̂^US and its regime interpretation — does it cross unity? when?; (4) loading coefficients and speed of adjustment; (5) diagnostics — CUSUM, recursive eigenvalues. The narrative must interpret θ̂^US economically in terms of the over-/under-accumulation regime typology from §2.3.

TARGET: ~500 words skeleton with [PLACEHOLDER] slots. Write the interpretive and transition prose fully; leave estimated values as [VALUE] or [TABLE 2.1].
```

---

## PROMPT §2.6.3 — Stage A: Chile Results (skeleton)

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.6.3 (Results: Chile) of Chapter 2 as a SKELETON.

NOTATION: θ̂^CL_t = β̂^CL₁ + β̂^CL₂ π^CL_t. First structural comparison: θ̂^US vs θ̂^CL — the mechanization gap in θ-units.

SECTION SPEC:
Same structure as §2.6.2 but for Chile. Additional elements: (1) regime break treatment — Gregory-Hansen test; if break detected, report date and discuss 1973/1982 candidates; (2) first structural comparison: θ̂^US vs θ̂^CL — interpret the mechanization gap economically; (3) note the Hansen-Seo threshold VECM as the preferred regime-change treatment given the Tavares BoP constraint activates as a threshold on the import content of investment φ̃^ME_t. Write the narrative for the mechanization gap as the empirical realization of the center-periphery structural difference.

TARGET: ~500 words skeleton with [PLACEHOLDER] slots for estimated values.
```

---

## PROMPT §2.6.4 — Stage A: Derived Objects

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.6.4 (Derived Objects) of Chapter 2.

NOTATION (locked):
- ŷ^p_t = y_t − ln μ̂_t (recovered productive capacity)
- ln B̂_t = ŷ^p_t − k_t; B̂_t = exp(ŷ^p_t − k_t) (recovered capital productivity at normal capacity)
- These are Stage B INPUTS. They are NOT estimated in Stage B — they are constructed from Stage A output.

SECTION SPEC:
Two definitions (state them formally): (1) Recovered productive capacity ŷ^p_t = y_t − ln μ̂_t; (2) Recovered capital productivity at normal capacity B̂_t = exp(ŷ^p_t − k_t). Emphasize the two-stage architecture: Stage A recovers μ̂_t and B̂_t cleanly only after the identification problem is solved. An ARDL investment equation cannot perform Stage A's identification — it can only describe how accumulation responds to utilization once utilization has been structurally recovered. This paragraph is load-bearing: it justifies the sequential architecture.

TARGET: ~250 words. Include the two definitions as numbered definitions. Tight.
```

---

## PROMPT §2.7 — Accounting Law of Capital Accumulation

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.7 (The Accounting Law of Capital Accumulation) of Chapter 2.

NOTATION (locked — every symbol matters):
- ι_t ≡ I_t/K_t = gross accumulation rate
- φ_t ≡ I_t/Y_t = investment share
- φ^p_t ≡ I_t/Y^p_t = investment share at normal capacity
- β_t ≡ I_t/Π_t = recapitalization rate (BEHAVIORAL MARGIN)
- π_t = Π_t/Y_t = profit share
- r_t = Π_t/K_t = profit rate = π_t μ_t B_t
- BOXED result: ι_t = β_t · π_t · μ_t · B_t = β_t · r_t

ARCHITECTURAL RULE: This section is pure accounting — all steps are identity manipulation. No behavioral equation is imposed. The behavioral content enters only through the question of whether β_t is constant.

SECTION SPEC:
Start from ι_t = I_t/K_t. Show: ι_t = φ_t μ_t B_t. Since φ_t μ_t = I_t/Y^p_t ≡ φ^p_t, obtain ι_t = φ^p_t B_t (utilization drops out). Introduce β_t = I_t/Π_t and use r_t = π_t μ_t B_t to obtain the boxed result ι_t = β_t r_t. Two recapitalization lenses: β_t (funding out of profits) and φ^p_t (claim on productive-capacity output) — linked accounting representations. The behavioral margin is whether β_t is constant. Note Weisskopf (1979) decomposition r_t = μ_t B_t π_t as the profitability reading of the same identity. Transition: §2.8 makes β_t the object of behavioral estimation.

TARGET: ~500 words. Include the full derivation as displayed equations. Box the key result. Academic prose around the equations.
```

---

## PROMPT §2.8.1 — Stage B: Specification

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.8.1 (Specification) of Chapter 2.

NOTATION (locked):
- ln ι_t = c + b₁ ln π_t + b₂ ln μ̂_t + b₃ ln B̂_t + ε_t [BOXED — the behavioral accumulation law]
- b_j = 1 + η_j; η_j = recapitalization response (deviation from accounting unity)
- μ̂_t and B̂_t are Stage A OUTPUTS passed in as conditioning variables — Stage B does NOT re-estimate them
- The Foley-Michl investment function is profit-oriented and market-share-oriented — never "optimal"

SECTION SPEC:
If recapitalization responds behaviorally: ln β_t = η₀ + η₁ ln π_t + η₂ ln μ_t + η₃ ln B_t. Substituting into log of ι_t = β_t r_t yields the behavioral accumulation law (box it). Each coefficient has dual interpretation (Table): b₁ = profit-share elasticity / η₁ = distribution response; b₂ = utilization elasticity / η₂ = demand response; b₃ = capital-productivity elasticity / η₃ = structural response. Deviation from unity is the behavioral content. Estimation: ARDL with Pesaran-Shin-Smith (2001) bounds test. This is a CONDITIONAL behavioral module — it uses Stage A's recovered objects, it does not identify them.

TARGET: ~450 words. Include the boxed equation and the dual-interpretation table. Academic prose.
```

---

## PROMPT §2.8.2 — Stage B: Restriction Menu

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.8.2 (Nested Restriction Menu) of Chapter 2.

NOTATION: b₁, b₂, b₃ from ln ι_t = c + b₁ ln π_t + b₂ ln μ̂_t + b₃ ln B̂_t + ε_t.

SECTION SPEC:
Three nested closures tested via Wald restrictions: (1) Cambridge closure — b₁=b₂=b₃=1 (β_t constant, accumulation fully accounting-determined); (2) Bhaduri-Marglin type — b₃=1, b₁ and b₂ free (recapitalization responds to distribution and demand but is blind to capital productivity); (3) Full structural model — all b_j free (recapitalization responds to all three channels). The ARDL block tests which closure is supported CONDITIONAL on the structurally identified utilization object. The restriction tests have economic content: Cambridge means capitalists mechanically reinvest a fixed share of profits regardless of structural conditions; the full model means they respond to the structural transformation of capital productivity.

TARGET: ~300 words. Include the restriction table. Short and precise.
```

---

## PROMPT §2.8.3 — Stage B: US Results (skeleton)

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.8.3 (Results: US) of Chapter 2 as a SKELETON with [PLACEHOLDER] slots.

NOTATION: b̂₁, b̂₂, b̂₃ = ARDL estimates. η̂_j = b̂_j − 1 = behavioral content.

SECTION SPEC:
Skeleton narrative: ARDL estimation with PSS bounds test on the US behavioral accumulation law. Structure: (1) bounds test result — I(0)/I(1) bounds and long-run relationship confirmed; (2) estimated coefficients b̂₁, b̂₂, b̂₃ with [VALUE] slots; (3) Wald restriction tests — which closure is rejected/supported?; (4) economic interpretation of η̂_j = b̂_j − 1: does b̂₃ indicate amplification (b₃>1) or partial offset (b₃<1) of the capital-productivity tendency? (5) stability diagnostics. Write the interpretive prose fully; leave numerical results as [VALUE] or [TABLE 2.2].

TARGET: ~450 words skeleton.
```

---

## PROMPT §2.8.4 — Stage B: Chile Results (skeleton)

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.8.4 (Results: Chile) of Chapter 2 as a SKELETON.

NOTATION: Same as §2.8.3 but for Chile. Key comparison: b̂₃^US vs b̂₃^CL.

SECTION SPEC:
Same structure as §2.8.3. Key question: does b̂₃^CL differ from b̂₃^US? Is the capital-productivity channel structurally constrained in Chile? The narrative should build toward the Tavares mechanism: if the BoP constraint binds, η̂₃^CL = b̂₃^CL − 1 should be smaller in absolute value (or differently signed) than η̂₃^US — the recapitalization response to structural conditions is dampened by forex unavailability. Close with a transition sentence to §2.9, which provides the mechanism for this finding.

TARGET: ~450 words skeleton with [PLACEHOLDER] slots.
```

---

## PROMPT §2.9.1 — The Tavares Channel

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.9.1 (The Tavares Channel) of Chapter 2. This is the chapter's distinctive theoretical contribution — write it with appropriate care.

NOTATION: β_t = recapitalization rate. φ̃^ME_t = import content of investment (share of machinery and equipment in gross capital formation sourced from abroad). η₃ = b₃ − 1 = recapitalization response to capital productivity.

SECTION SPEC:
Three-step mechanism (do NOT present as bullet points — integrate into flowing prose):
(1) Peripheral accumulation requires imported machinery — the capital goods sector is structurally incomplete (Tavares's "hard phase" of ISI, Fajnzylber's "truncated industrialization").
(2) The recapitalization rate β_t is structurally conditioned by forex availability: profits exist (Π_t > 0) but β_t collapses when imported capital goods are unaffordable — the surplus exists but cannot be converted into re-investment.
(3) Sudden stops in β_t — debt-cycle reversals, terms-of-trade collapses, Volcker shock — express financial dependency as a constraint on the technical composition of accumulated capital.
Sources: Tavares (1985, 2000) via Vernengo (2006). Distinguish from: pure output-side BoP constraints (not what Tavares means); simple import compression (not a recapitalization constraint). The contribution is localizing the constraint in the RECAPITALIZATION FUNCTION, not in the output equation.

TARGET: ~600 words. No bullet points. Flowing theoretical prose. This section earns its keep.
```

---

## PROMPT §2.9.2 — Tavares Formalization

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.9.2 (Formalization) of Chapter 2.

NOTATION (locked):
- η₃^CL = η₃^CL(φ̃^ME_t, BoP_t) — recapitalization response to capital productivity is not free in the periphery
- φ̃^ME_t = import content of investment
- BoP_t = external constraint proxy (terms of trade, real exchange rate, or current account balance)
- Empirical prior: ξ^ME_K ≈ 0.92–0.94 from Kaldor (1959) Cuadro 8 — NOT estimated from unavailable disaggregated import data
- ε = income elasticity of exports (exogenous world demand for Chilean commodities) ≠ π = import propensity (endogenous to domestic productive structure) — do NOT conflate

SECTION SPEC:
The recapitalization response η₃ = b₃ − 1 is not a free behavioral parameter in the periphery — it is structurally constrained by the import content of investment and forex availability. Candidate specifications: (i) augment Chilean ARDL with forex availability proxy; (ii) test whether b̂₃^CL is stable across BoP regimes or breaks at sudden stops (Hansen-Seo threshold VECM preferred given BoP constraint activates as threshold on φ̃^ME_t); (iii) compare b₃^US (unconstrained) vs b₃^CL (BoP-mediated). The structural null: η₃^US > η₃^CL (peripheral recapitalization is more constrained). Note the Kaldor-vs-ECLA fault line: whether the external BoP ceiling or internal consumption drain dominates is an estimable structural question.

TARGET: ~450 words. Include equation for η₃^CL = η₃^CL(φ̃^ME_t, BoP_t). Academic prose.
```

---

## PROMPT §2.9.3 — Technical Composition Channel

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.9.3 (The Technical Composition Channel) of Chapter 2.

NOTATION: θ^CL = capacity transformation elasticity for Chile. θ < 1 = over-mechanization (capital grows faster than productive capacity). B_t = capital productivity at normal capacity.

SECTION SPEC:
When θ < 1 (over-mechanization): the economy needs MORE imported capital goods per unit of capacity created (because capital productivity is falling, more capital is needed per unit of output), but its capacity to earn forex is LOWER because the accumulated capital is less productive. The peripheral trap: over-mechanization raises the import bill for investment while degrading the export capacity that finances it. Link to Prebisch-Singer: the secular deterioration of the terms of trade is not just a price phenomenon — it is a structural constraint on the technical composition of peripheral capital accumulation. The b₃ comparison in §2.10 gives this trap empirical content: b₃^CL < b₃^US would indicate that Chilean capitalists cannot recapitalize at the rate the structural conditions demand, because the forex constraint binds.

APPROVED PUNCHLINE (use verbatim at or near the end of this section): "demand conditions intervene on the political economy of the ceiling, i.e. the class struggle over distribution, utilization, and the institutional forms that govern whether accumulation can proceed."

TARGET: ~400 words. Academic prose. Use the approved punchline.
```

---

## PROMPT §2.10 — Structural Comparison

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.10 (Structural Comparison: Center vs. Periphery) of Chapter 2 as a SKELETON — narrative framework with [PLACEHOLDER] slots for estimated values.

SECTION SPEC:
Synthesize results across both countries. The parallel construction (§2.5.3) ensures the comparison is structural, not a measurement artefact. Walk through the comparison table row by row:
- θ̂: the mechanization gap in θ-units — [VALUE]^US vs [VALUE]^CL
- Regime breaks: when does θ shift? what do the dates correspond to?
- b̂₁ (distribution): profit-share response comparison
- b̂₂ (demand): utilization response comparison
- b̂₃ (structural): THE KEY COMPARISON — capital-productivity response; is b̂₃^CL < b̂₃^US?
- b̂₃ stability: does b̂₃^CL break at BoP crises?
- μ̂_t volatility: utilization instability — is Chile more volatile?
- B̂_t trend: capital productivity trajectory — does Chile show faster deterioration under over-mechanization?

PUNCHLINE: In the US, the recapitalization function responds to all three channels relatively freely. In Chile, the b₃ channel (structural response to capital productivity) is mediated by the BoP constraint — financial dependency shows up empirically as a structurally constrained recapitalization response. The Tavares channel provides the mechanism; the comparison table provides the evidence.

TARGET: ~600 words skeleton. Include comparison table with [PLACEHOLDER] cells. Write the interpretive prose fully.
```

---

## PROMPT §2.11 — Conclusions

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.11 (Conclusions) of Chapter 2.

NOTATION: μ̂_t, B̂_t, θ̂_t = structurally identified objects produced by Stage A. b̂₁, b̂₂, b̂₃ = behavioral accumulation law estimates from Stage B.

SECTION SPEC:
Three-part structure:
(1) CU series: structurally identified μ̂_t for both countries — available as inputs to Ch3 (profitability analysis, investment function hypothesis testing per prospectus §3.4.3).
(2) Regime classification: θ̂^US vs θ̂^CL — the empirical realization of the core-periphery mechanization gap.
(3) Financial dependency formalized: the Tavares channel — inability to convert surplus into re-investment due to lack of foreign currency — is not a narrative but an estimable structural constraint on the recapitalization function. The comparison b₃^US vs b₃^CL gives it empirical content.

Forward references:
- Ch3 inherits μ̂_t, B̂_t, θ̂_t as given inputs — no re-estimation
- The Weisskopf decomposition r_t = μ_t B_t π_t and Okishio crisis trigger become Ch3 applications of the Stage A recovered objects
- The center-periphery relational analysis (Vietnam War → terms of trade → Chilean full employment) uses the structural comparison from §2.9

Write for [PLACEHOLDER] values where results are pending, but write the framework prose fully.

TARGET: ~700 words. Three clearly structured deliverables + forward references. Academic prose.
```

---

## QUICK REFERENCE: Locked Equations

Paste into any prompt if you want to reinforce specific equations:

```
KEY EQUATIONS (do not alter):
- Confinement identity: ln μ_t = y_t − θ(Λ) k_t
- Rank-1 identification: y_t = c + β₁k_t + β₂(π_t k_t) + ξ_t, ξ_t ~ I(0)
- Endogenous elasticity: θ_t = β₁ + β₂ π_t
- Accounting law: ι_t = β_t · π_t · μ_t · B_t = β_t · r_t
- Behavioral accumulation law: ln ι_t = c + b₁ ln π_t + b₂ ln μ̂_t + b₃ ln B̂_t + ε_t
- Behavioral content: b_j = 1 + η_j
- Tavares constraint: η₃^CL = η₃^CL(φ̃^ME_t, BoP_t)
```

---

*23 prompts. Each is self-contained — no shared context file needed. Copy one block, paste into Claude.*
