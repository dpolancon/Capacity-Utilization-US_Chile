# Ch2 Section Prompts — Self-Contained Firing Prompts
## Demand-Led Profitability and Structural Crisis of Capitalism in Chile and the United States during the Fordist Era
### Rebuilt 2026-04-02 from Ch2_Outline_DEFINITIVE.md

Each prompt below is fully self-contained — paste one block into an Opus session within
the Ch2 Claude project. The project files are available as project knowledge.

**VOICE DISCIPLINE:** Always paste `ch2_voice_guide.md` BEFORE the section prompt.
The voice guide is a separate file in `chapter2/agents/`. It calibrates the agent to
WLM v4.0 (the same voice system used in Ch1 approved prose). Without it, outputs will
be structurally correct but generically voiced.

---

<!-- ═══════════════════════════════════════════════════════════════════
     SHARED CONTEXT BLOCK — embedded in every prompt below
     ═══════════════════════════════════════════════════════════════════

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
     ═══════════════════════════════════════════════════════════════════ -->

---

## PROMPT §2.1 — Introduction

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.1 (Introduction)
of the chapter "Demand-Led Profitability and Structural Crisis of Capitalism in Chile and the
United States during the Fordist Era."

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
Opening move: situate the problem — existing CU estimates (HP-filter, peak-output) impose
θ=1 by construction, conflating demand and technology channels in the Weisskopf decomposition.
This is what Ch1 demonstrated empirically. Ch2 asks: if CU is correctly identified, what
does it do? Following Okishio (1961): the PATH of μ_t is a crisis trigger — CU cumulative
disequilibrium mediates the link between accumulation dynamics and structural crisis.

Research question: Does capacity utilization operate as an independent crisis trigger in the
recapitalization decision, and does the mechanism differ structurally between center and periphery?

Main contributions (state these directly):
1. First-stage structural identification of μ̂_t from the 4-variable VECM (y,k,π,πk)
   with distribution-conditioned θ̂_t = θ₁ + θ₂π_t — without imposing stationarity
2. Stage A.2 peripheral extension: capital composition (K^NR + K^ME) and BoP-constrained
   cost-minimization — the mechanization gap between center and periphery derived, not imposed
3. FM-first investment function: the Okishio Wald test (ψ₁ = ψ₃) within the full
   Weisskopf disaggregation — CU as crisis trigger vs. mere component of r

Primary period: 1945–1978 (Fordist era). Data: own repositories (US-BEA-Income-FixedAssets-Dataset
and K-Stock-Harmonization).

End with a roadmap paragraph referencing §2.2 (literature), §2.3 (analytical framework),
§2.4 (data), §2.5 (Stage A), §2.6 (Stage B), §2.7 (Stage C), §2.8 (results), §2.9 (conclusions).

TARGET: ~600 words. Tight, no preamble. The first sentence should state the problem, not
provide background.
```

---

## PROMPT §2.2.1 — Crisis as the Limit of Capitalist Accumulation

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.2.1 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
Shaikh (2016) and Itoh (1980): crisis is not a contingent failure but an expression of
the internal contradictions of capitalist accumulation. The tendency of the profit rate
to fall is the medium-term manifestation of the secular tensions within the accumulation
regime (Λ). Key distinction: stagnation tendency (downward pressure on profitability,
inherent and persistent) vs. structural crisis (deep interruption requiring drastic
restructuring of Λ). The accumulation regime Λ temporarily contains these tendencies —
it is the institutional form through which capital resolves contradictions provisionally.
When the institutional settlement exhausts its containing capacity, the stagnation tendency
breaks through as structural crisis.

This subsection sets the theoretical register: crisis is endogenous, accumulation-regime-specific,
and requires a structural account of the channels through which the profit rate falls.
The next subsections identify which channels the chapter focuses on.

TARGET: ~350 words. No equations. Transition sentence pointing to §2.2.2.
```

---

## PROMPT §2.2.2 — Disproportionality, Class Struggle, and Spatial Fixes

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.2.2 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
Arrighi (1994) and Harvey (2003, 2010): capital resolves contradictions of over-accumulation
through spatial fixes — geographical expansion, financial circuits, and hegemonic power shifts.
The Fordist era (1945–1978) represents a specific spatial-institutional settlement: US hegemony,
dollar standard, ISI in the periphery. The class struggle over distribution is the internal
dimension; the spatial fix is the external valve. When the spatial fix closes — as it did for
Chile under BoP constraints and for the US under the Vietnam War fiscal expansion — the internal
distributive contradictions surface as structural crisis.

Connect to the chapter's empirical object: the center-periphery comparison (US vs. Chile)
maps onto the Arrighi/Harvey distinction between hegemonic center (accumulating through
financial expansion) and dependent periphery (accumulating under BoP constraint and forex
scarcity). The ISI model as a contested spatial fix.

TARGET: ~350 words. No equations. Transition to §2.2.3.
```

---

## PROMPT §2.2.3 — Okishio's Crisis Trigger: Cumulative Causation through CU

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.2.3 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
Okishio (1961): decentralized capitalist decisions produce secular cumulative disequilibrium
in capacity utilization. CU rates trend systematically below normal capacity during downturns
and overshoot during expansions, producing stagnation episodes of increasing severity.
The key: the crisis trigger is the PATH of μ_t, not a static level.

The Weisskopf (1979) decomposition provides the link: r_t = μ_t · b_t · π_t. Effective
profitability is demand-led — CU scales normal-capacity profitability. The CU path therefore
directly mediates the link between accumulation dynamics and the profit rate. Display the
Weisskopf decomposition as an equation:

  r_t ≡ (Y/Y^p) · (Y^p/K) · (Π/Y) = μ_t · b_t · π_t

Foreshadow the identification problem: to test the Okishio mechanism empirically, one needs
a structurally identified μ̂_t that does not conflate the demand channel with the technology
channel (b_t). HP-filtering imposes θ=1, collapsing μ and b into a single channel and making
the Okishio test impossible. This is what Stage A resolves.

Include: the decomposition ṙ/r = μ̇/μ + ḃ/b + π̇/π as the empirical Weisskopf identity.

TARGET: ~450 words. Include two displayed equations. Transition to §2.2.4.
```

---

## PROMPT §2.2.4 — Multi-Scalar Contradictions Rule Out a Stable Desired CU

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.2.4 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
Vidal (2014, 2019): multi-scalar contradictions within firm-level decision-making rule out
a coherent, stable desired CU rate at the firm level. The contradiction operates across
four levels: (1) mode of production (competition forces cost-minimization that degrades
collective conditions); (2) meso/spatial (sectoral and geographic disproportionalities);
(3) aggregate (coordination failures in investment timing); (4) firm (market share vs.
profit rate trade-off). Because the within-firm contradiction is irreducible, there is no
stable desired CU target — firms respond to CU signals contingently, based on the
institutional settlement Λ.

Implication for the chapter's Okishio Wald test: if firms held a stable desired CU, ψ₃
(the CU coefficient in the FM spec) should be well-defined and stable. Vidal's argument
rules this out at the firm level: ψ₃ is a regime-specific behavioral response, contingent
on the Fordist institutional anchor. CUSUM instability of ψ₃ across sub-periods would
confirm this reading.

Fordism as temporary institutional settlement: the regulation school (Boyer 1990; Aglietta 1979)
interprets Fordist wage norms and monopoly pricing as an institutional resolution of the
within-firm contradiction — temporary suppression of multi-scalar tensions, not their
elimination.

TARGET: ~500 words. No equations. Transition to §2.2.5.
```

---

## PROMPT §2.2.5 — Synthesis: A Multi-Level Theory of the Crisis Trigger

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.2.5 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
Synthesize the four strands into a unified interpretive template for the chapter. The
synthesis operates across four levels:
- Mode of production (Shaikh/Itoh): secular tendency; the background force
- Meso/spatial (Arrighi/Harvey): center-periphery differentiation; spatial fix
- Aggregate (Okishio/Weisskopf): CU path as crisis trigger; profit rate channel
- Firm (Vidal): multi-scalar contradiction; contingent and regime-specific response

Include the stagnation typology table (Basu 2019, redefined in Vidal's terms):

|                   | Excess of Surplus Value      | Deficit of Surplus Value    |
|---|---|---|
| Demand side       | Under-consumption/realization | Profit squeeze              |
| Financial side    | Financial fragility           | Falling normal profit rate  |

This grid is the interpretive template for Stage B and Stage C results. Each cell
corresponds to a different channel in the Weisskopf decomposition and the FM spec.

The synthesis punchline: CU is not just a cyclical variable — it is the medium through
which structural crisis registers at the aggregate level, and its measurement must
respect the structural channels through which it operates.

TARGET: ~400 words including table. Transition to §2.3.
```

---

## PROMPT §2.3.1 — Stagnation and Crisis: A Typology

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.3.1 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

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
```

---

## PROMPT §2.3.2 — Layer 1: The Accounting Foundation

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.3.2 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
This is the accounting spine. ARCHITECTURAL RULE: everything in this section is a pure
accounting identity — no behavioral equation is imposed. Flag this in the prose.

The Weisskopf decomposition:
  r ≡ Π/K = (Y/Y^p) · (Y^p/K) · (Π/Y) = μ · b · π

Table of factors:
| Factor | Symbol | Definition | Channel |
|---|---|---|---|
| Capacity utilization | μ = Y/Y^p | Demand realization | Demand |
| Capital productivity | b = Y^p/K | Technology at normal capacity | Technology |
| Profit share | π = Π/Y | Distributive conflict | Distribution |

Demand-led content: r = μ × r^n where r^n ≡ bπ is normal-capacity profitability.
Capitalists signal from r, not r^n.

The gross accumulation identity (nests Weisskopf):
  g_K ≡ I/K = (I/Π) · (Π/Y) · (Y/Y^p) · (Y^p/K) = χ · π · μ · b

Where χ ≡ I/Π is the recapitalization rate throughout (NOT β).

Cambridge equation: k = χr - δ (three distinct objects: r market outcome, χ investment
decision, δ physical decay).

Two dependent variables in Stage C:
- κ_t = I/K (capital accumulation rate, Robinson convention)
- a_t = I/Π = χ_t (rate of capitalization, Foley 1982)

Layer 1 implication for Stage C: the accounting identity identifies three distinct channels
(demand, technology, distribution) that should be entered separately by default.
Compressing them into r (Keynes-Robinson) suppresses regime-relevant information.

TARGET: ~500 words. Include all displayed equations and the factor table.
```

---

## PROMPT §2.3.3 — Layer 2: The Behavioral Identification

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.3.3 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
Derive the primary estimating equation from the accumulation identity. Take logs (exact):
  ln g_K = ln χ + ln π + ln μ + ln b

Under Cambridge closure (χ = χ̄): unit elasticity on every channel. Allow χ to respond
log-linearly: ln χ = η₀ + η₁lnπ + η₂lnμ + η₃lnb. Substituting, define β_j ≡ 1 + η_j:

  ln g_K = c + β₁lnπ + β₂lnμ + β₃lnb + ε

This is the Layer-2 behavioral identification equation.

Dual interpretation table:
| Coeff. | Accounting benchmark (β_j=1) | Behavioral content (η_j = β_j - 1) |
|---|---|---|
| β₁ | Cambridge closure on distribution | χ elasticity w.r.t. π |
| β₂ | Cambridge closure on demand | χ elasticity w.r.t. μ |
| β₃ | Cambridge closure on technology | χ elasticity w.r.t. b |

Modest claim (state explicitly): Layer 2 provides coefficient interpretation for the FM
spec and establishes Cambridge closure as the accounting benchmark. KR and BM are
economically motivated compressions of the three channels — tested as Wald restrictions
within the FM framework, not algebraic restrictions on the log-linear equation.

Okishio crisis-trigger restriction in Layer-2 terms: H₀: β₂ = β₃ — CU and capital
productivity enter χ's response identically. Rejection: CU has an independent behavioral
effect on recapitalization beyond its accounting role through r.

TARGET: ~500 words. Include all displayed equations and the dual interpretation table.
```

---

## PROMPT §2.4 — Data

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.4 (Data, all
three subsections: §2.4.1 United States, §2.4.2 Chile, §2.4.3 Sample and Periodization)
of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

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
```

---

## PROMPT §2.5.1 — Structural Problem + Two Routes + 4-Variable System

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.5.1 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

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

TARGET: ~900-1200 words. Include all four cointegrating vectors as displayed equations. This is
the chapter's core methodological contribution — write with precision and confidence.
```

---

## PROMPT §2.5.2 — Stage A.1: MPF Cost-Minimization (Center)

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.5.2 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
This section derives the center (US) cost-minimization problem following Cajas-Guijarro (2024).

First, state the notation lock for this section: q ≡ K̇/K - L̇/L = mechanization growth
rate throughout this chapter and all downstream. M = imports (levels); m = import share.
This must be flagged explicitly.

The MPF (quadratic, FMT restriction — no constant):
  a = α₁q + α₂q²
where a = labour productivity growth, q = mechanization growth, α₂ < 0 (diminishing returns).
FMT restriction: MPF passes through origin — no mechanization, no productivity gain.

The cost-minimization problem (Cajas-Guijarro 2024):
  min_q c = a - qπ  subject to  a = α₁q + α₂q²
Substituting constraint: c = q(α₁ - π) + α₂q²

FOC:
  ∂c/∂q = α₁ - π + 2α₂q = 0  →  q* = (π - α₁)/(2α₂)

SOC: ∂²c/∂q² = 2α₂ < 0 — requires α₂ < 0.

Optimal mechanization is increasing in the profit share (∂q*/∂π > 0 since α₂ < 0):
higher profit share induces more mechanization.

Capacity transformation elasticity (average-to-marginal ratio at optimum):
  θ = a*/q* = α₁ + α₂q*

Substituting q* = (π - α₁)/(2α₂):
  θ̂_t = (α₁ + π_t)/2 = θ₁ + θ₂π_t with θ₂ = 1/2 under the quadratic MPF

Key result: θ is the average of the MPF slope α₁ and the profit share π_t —
distribution-dependent, time-varying, behavioral (not a regime label).

Note the connection to the 4-variable system: this FOC implies θ₂ = 1/2, which is a
testable restriction within CV1 of the VECM. The direct MPF route provides the structural
foundation; the system validates it.

TARGET: ~500 words. Include all displayed equations. Tight and precise.
```

---

## PROMPT §2.5.3 — First-Stage θ̂ Identification via Long-Run Projection

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.5.3 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
The identification problem: the cost-minimizing FOC uses π as the relevant profit share,
but which π? Technique choice is a long-run decision — capitalists respond to the
equilibrium distribution, not to transitory business cycle fluctuations. Using raw π_t
to construct θ̂_t displaces short-run distributional noise into the technology channel,
contaminating the identification of productive capacity Y^p_t = B₀K^θ̂. This is the
identification problem §2.5.3 resolves.

The first-stage identification requires:
  θ̂_t^(1) = θ₁ + θ₂ π̂_t^LR

where π̂_t^LR is the projection of π_t onto the long-run manifold — the component
consistent with the equilibrium distribution-CU relationship, purged of error correction
deviations.

Deriving π̂_t^LR from the 4-variable VECM:
From CV1 and CV2 jointly on the long-run manifold, eliminate μ̂_t^LR:
  CV1: μ̂_t^LR = y_t^LR - (θ₁ + θ₂π_t^LR)k_t^LR
  CV2: π_t^LR = ϱμ̂_t^LR

Substituting and solving:
  π̂_t^LR = ϱ(y_t^LR - θ₁k_t^LR) / (1 + ϱθ₂k_t^LR)

where (y_t^LR, k_t^LR) are the VECM's long-run fitted components.

Two-step procedure:
Step 1: Estimate restricted VECM on (y,k,π,πk); extract long-run fitted values.
Step 2: Construct θ̂_t^(1) = θ₁ + θ₂π̂_t^LR; impose over full sample:
  μ̂_t = y_t - θ̂_t^(1) k_t

What this achieves: transitory distributional fluctuations (π_t - π̂_t^LR) feed μ̂_t —
demand-side variation where it belongs — rather than contaminating θ̂_t^(1). The Okishio
crisis trigger operates through this channel.

Capital productivity at normal capacity:
  b̂_t = (θ̂_t^(1) - 1)k_t  →  B̂_t = exp(θ̂_t^(1) k_t)/K_t

Scope note on GG: the Gonzalo-Granger decomposition of the 4-variable system can
serve as a robustness diagnostic for decomposing μ̂_t into permanent and transitory
components after the VECM is estimated. GG on a lower-dimensional (y,k,π) system
without (πk) is NOT used — abstracting from the interaction term loses the distributional
dependence of θ̂_t.

TARGET: ~600 words. Include the π̂_t^LR formula as a displayed equation and the two-step
procedure as a numbered list. State the identification argument precisely.
```

---

## PROMPT §2.5.4 — Stage A.2: Periphery Capital Composition and BoP Constraint

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.5.4 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
The structural distinction from Stage A.1: in peripheral capitalism, capital is composed
of K^NR (nonresidential infrastructure) and K^ME (machinery and equipment). ME must be
imported — the capital goods sector is structurally incomplete. Mechanization through ME
requires foreign exchange. The BoP constraint enters the cost-minimization through the
import content of ME investment.

Capital decomposition:
  K^CL = K^NR + K^ME
  s_t^ME = K_t^ME / K_t^CL (ME share, time-varying)
  q = (1 - s^ME)q^NR + s^ME q^ME

The peripheral MPF (composition-weighted slope):
  ā₁^CL ≡ α₁^NR(1 - s_t^ME) + α₁^ME s_t^ME
  a = ā₁^CL q + α₂ q²

The Kaldor-ECLA fault line (state explicitly): does the external BoP ceiling (limiting q^ME)
or the internal consumption drain (limiting π) bind first? This is an estimable structural
question, not a theoretical imposition. Data from K-Stock-Harmonization (canonical Pérez
baseline + BCCh extension) provides K^ME and K^NR directly — the capital type stage-gate
is closed.

The peripheral cost-minimization:
  min_q c = a - qπ + λ·s^ME·ξ^ME_K·q
  subject to a = ā₁^CL q + α₂ q²

where ξ^ME_K ≈ 0.92–0.94 (Kaldor 1959 prior from Cuadro 8) and λ = shadow cost of forex.

FOC:
  q^CL* = (π - λs^ME ξ^ME_K - ā₁^CL) / (2α₂)

The BoP penalty λs^ME ξ^ME_K acts as an effective reduction in the profit share available
for mechanization. For a given π, the periphery mechanizes at a lower rate than the center —
the center-periphery mechanization gap, derived from the cost-minimization, not imposed.

Center-periphery comparison table (include):
|  | Center (Stage A.1) | Periphery (Stage A.2) |
|---|---|---|
| Capital structure | Homogeneous K | K^NR + K^ME |
| Cost function | c = a - qπ | c = a - qπ + λs^ME ξ^ME_K q |
| FOC | q* = (π - α₁)/(2α₂) | q^CL* = (π - λs^ME ξ^ME_K - ā₁^CL)/(2α₂) |

TARGET: ~700 words. Include all displayed equations and the comparison table.
```

---

## PROMPT §2.5.5 — Stage A.2: Recovering θ̂^CL and μ̂^CL

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.5.5 of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

SECTION SPEC:
Same two-step procedure as §2.5.3, extended for the peripheral cost-minimization.

Peripheral long-run projected profit share:
  π̂_t^CL,LR = π̂_t^LR - λs_t^ME ξ^ME_K

where π̂_t^LR is the Gonzalo-Granger permanent component from the 4-variable VECM on
(y^CL, k^CL, π^CL, (πk)^CL).

Peripheral transformation elasticity (first stage):
  θ̂_t^CL,(1) = (ā₁^CL + π̂_t^LR - λ̂ ξ^ME_K s_t^ME) / 2
  (under the Cajas-Guijarro restriction θ₂ = 1/2)

The center-periphery θ gap:
  θ̂_t^US,(1) - θ̂_t^CL,(1) = [(α₁^US - ā₁^CL) + λs_t^ME ξ^ME_K] / 2

Two components: (i) MPF slope gap (structural technology difference); (ii) BoP penalty.
Decomposing this gap is the empirical content of the Kaldor-ECLA fault line.

CU recovery imposed over full sample:
  μ̂_t^CL = exp(y_t^CL - θ̂_t^CL,(1) k_t^CL)

Transitory distributional fluctuations (π_t^CL - π̂_t^CL,LR) enter μ̂_t^CL — demand-side
variation.

The λ identification: λ̂ is the coefficient on s_t^ME k_t^CL in the augmented CV1, with
ξ^ME_K ≈ 0.92 imposed as Kaldor prior. K-Stock-Harmonization provides s_t^ME directly.

Capital productivity: b̂_t^CL = (θ̂_t^CL,(1) - 1)k_t^CL

TARGET: ~400 words. Include all displayed equations. Tight — this is a short recovery
section that follows from §2.5.3 and §2.5.4.
```

---

## PROMPT §2.7.1-§2.7.6 — Stage C: Investment Function (Full Section)

```
You are a heterodox macroeconomics dissertation writing assistant. Draft the full §2.7
(Stage C: Investment Function Estimation, all six subsections §2.7.1–§2.7.6) of the chapter.

[EMBED SHARED CONTEXT BLOCK ABOVE]

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
```

---

## PROMPT §2.9 — Conclusions and Contributions (Skeleton)

```
You are a heterodox macroeconomics dissertation writing assistant. Draft §2.9 (Conclusions
and Contributions) of the chapter as a SKELETON — write all interpretive and framework prose
fully, but use [PLACEHOLDER: value] for any specific empirical results.

[EMBED SHARED CONTEXT BLOCK ABOVE]

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
```

---

## QUICK REFERENCE: Locked Equation Paste Block

Copy this into any prompt to reinforce equations:

```
KEY EQUATIONS (do not alter — notation is locked):
- Weisskopf: r ≡ μ · b · π = (Y/Y^p) · (Y^p/K) · (Π/Y)
- Gross accumulation identity: g_K ≡ χ · π · μ · b
- Cambridge equation: k = χr - δ
- Layer 2: ln g_K = c + β₁lnπ + β₂lnμ + β₃lnb; β_j = 1 + η_j
- MPF (quadratic, FMT): a = α₁q + α₂q²; no constant
- FOC (center): q* = (π - α₁)/(2α₂)
- Distribution-conditioned elasticity: θ̂_t = θ₁ + θ₂π_t (general); = (α₁ + π)/2 under quadratic MPF
- Long-run π projection: π̂^LR = ϱ(y^LR - θ₁k^LR)/(1 + ϱθ₂k^LR)
- CU identification: μ̂_t = exp(y_t - θ̂_t^(1) k_t)
- FM spec (primary): y_t = ψ₀ + ψ₁b̂_t + ψ₂π_t + ψ₃μ̂_t + η_t
- Okishio Wald: H₀: ψ₁ = ψ₃
- CV1: [1, -θ₁, 0, -θ₂]·(y,k,π,πk)' = μ̂
- CV2: [-ϱ, ϱθ₁, 1, ϱθ₂]·(y,k,π,πk)' = 0
- CV3: [-2, (2+θ₁), -1, θ₂]·(y,k,π,πk)' = -δ
```

---

*Section prompts v2. Rebuilt 2026-04-02 from Ch2_Outline_DEFINITIVE.md.
Previous version (v1, 2026-03-29) fully obsolete — wrong architecture, notation, and section numbering.*

---

## LATEX CONTEXT BLOCK — Paste alongside any prompt when requesting LaTeX output

When requesting LaTeX-formatted output (as opposed to prose draft), paste this block
alongside the section prompt. The agent should produce compilable LaTeX consistent
with Chapter 1.

```latex
%% ═══════════════════════════════════════════════════════════════════════
%% CHAPTER 2 — LaTeX TEMPLATE CONTEXT
%% Must be consistent with Chapter1_CriticalReplication.tex
%% ═══════════════════════════════════════════════════════════════════════

%% ── PREAMBLE (do not alter) ─────────────────────────────────────────────
\documentclass[11pt,a4paper]{article}

\usepackage[english]{babel}
\usepackage[T1]{fontenc}
\usepackage{lmodern}
\usepackage[a4paper,margin=1in]{geometry}

\usepackage{xcolor}
\usepackage{graphicx}
\usepackage{float}
\usepackage{booktabs}
\usepackage{array}
\usepackage{caption}
\usepackage{subcaption}
\usepackage{tabularx}

\usepackage{amsmath,amssymb,bm}
\usepackage{enumitem}
\usepackage{titlesec}
\usepackage[authoryear]{natbib}
\usepackage{hyperref}
\usepackage{fancyhdr}
\usepackage{pdflscape}
\usepackage{xfrac}
\usepackage{threeparttable}
\usepackage{multirow}
\usepackage{adjustbox}
\usepackage{rotating}

\usepackage{tikz}
\usetikzlibrary{arrows.meta, positioning, shapes.geometric}

\definecolor{darkblue}{rgb}{0,0,0.8}
\hypersetup{
    colorlinks=true,
    citecolor=darkblue,
    linkcolor=darkblue,
    urlcolor=darkblue
}

\setlength{\parskip}{0.55em}
\setlength{\parindent}{0pt}

%% ── SECTION STRUCTURE ───────────────────────────────────────────────────
%% Use standard \section / \subsection / \subsubsection with \label{}
%% Label convention:
%%   \label{sec:21_lit_review}
%%   \label{subsec:211_crisis_limit}
%% Cross-references: Section~\ref{...}, equation~\eqref{...},
%%                   Table~\ref{...}, Figure~\ref{...}

%% ── EQUATIONS ────────────────────────────────────────────────────────────
%% Labeled (numbered):    \begin{equation} \label{eq:...} ... \end{equation}
%% Unlabeled:             \begin{equation*} ... \end{equation*}
%% Multi-line aligned:    \begin{align} ... \end{align}
%%                        \begin{align*} ... \end{align*}
%%
%% NOTATION CRITICAL DISTINCTION (Ch1 vs Ch2):
%%   Ch1 (Shaikh replication) uses \hat{x} for growth rates — Shaikh's convention.
%%   Ch2 (own theory) uses \dot{x} for time derivatives of ratios in theory sections.
%%   \hat{x} reserved for ESTIMATED objects only (e.g., \hat{\theta}_t, \hat{\mu}_t).
%%
%% Key math macros:
%%   \hat{\theta}_t          distribution-conditioned θ (estimated)
%%   \hat{\mu}_t             identified CU series (estimated)
%%   \hat{b}_t               capital productivity at normal capacity (estimated)
%%   \hat{\pi}_t^{LR}        long-run projected profit share
%%   \dot{x}                 time derivative / growth rate (theory sections)
%%   \bm{X}_t                bold state vector (from bm package)
%%   \mathcal{A}             admissible set (script letters)

%% ── CITATIONS ────────────────────────────────────────────────────────────
%% In-text:       \citet{AuthorYear}      → Author (Year)
%% Parenthetical: \citep{AuthorYear}      → (Author, Year)
%% Appendix ref:  \citep[Appendix~6.6]{Shaikh2016}
%% Bibliography:  \bibliographystyle{plainnat} or \bibliographystyle{apalike}
%%                \bibliography{ch2_references}   (bib file: ch2_references.bib)

%% ── FIGURES ──────────────────────────────────────────────────────────────
%% Standard figure:
%%   \begin{figure}[H]
%%       \centering
%%       \caption{Caption text here}
%%       \label{fig:xxx}
%%       \includegraphics[width=\textwidth]{figures/fig_xxx.pdf}
%%       \begin{minipage}{\textwidth}
%%           \footnotesize
%%           \textit{Notes:} Note text here. Source: source text.
%%       \end{minipage}
%%   \end{figure}
%%
%% NOTE: Caption BEFORE \includegraphics (Ch1 convention).
%% Use [H] placement (from float package).
%% Figure files in figures/ directory; export PDF and PNG.

%% ── TABLES ───────────────────────────────────────────────────────────────
%% booktabs style — always use \toprule, \midrule, \bottomrule (no \hline):
%%   \begin{table}[H]
%%       \centering
%%       \caption{Caption text}
%%       \label{tab:xxx}
%%       \begin{tabular}{lcc}
%%           \toprule
%%           Header 1 & Header 2 & Header 3 \\
%%           \midrule
%%           Row 1    & val      & val      \\
%%           \bottomrule
%%       \end{tabular}
%%       \begin{minipage}{\linewidth}
%%           \footnotesize
%%           \textit{Notes:} Table notes here.
%%       \end{minipage}
%%   \end{table}
%%
%% For wide tables: wrap in \begin{adjustbox}{max width=\textwidth} ... \end{adjustbox}
%% For landscape tables: \begin{landscape} ... \end{landscape} (from pdflscape)
%% For external table files: \input{tables/xxx}
%% For complex table notes: \begin{threeparttable} ... \end{threeparttable}

%% ── FOOTNOTES ────────────────────────────────────────────────────────────
%% Standard \footnote{...}. Ch1 uses footnotes for:
%%   - Technical qualifications on notation
%%   - Sample-specific details that would interrupt prose
%%   - Cross-references to appendix material
%% Do not use footnotes for substantive theoretical content.

%% ── PROPOSITIONS / DEFINITIONS ───────────────────────────────────────────
%% Ch1 has NO amsthm theorem environments. Propositions are written as prose:
%%
%%   \textbf{Proposition 1} (Confinement Identity). \textit{Statement...}
%%   \textit{Proof.} Proof text. \hfill$\square$
%%
%% Or as a displayed block with a horizontal rule if needed.
%% Do NOT use \newtheorem / \begin{theorem} / \begin{proposition}.

%% ── ITEMIZED FIGURE NOTES ────────────────────────────────────────────────
%% When figure notes have multiple items (as in Ch1):
%%   \begin{itemize}[leftmargin=1em, itemsep=0pt, topsep=2pt]
%%       \item Note 1.
%%       \item Note 2.
%%   \end{itemize}

%% ── APPENDIX ─────────────────────────────────────────────────────────────
%% \appendix
%% \section{Appendix Title}
%% \label{app:xxx}
%% Appendix cross-reference in text: Appendix~\ref{app:xxx}

%% ═══════════════════════════════════════════════════════════════════════
%% END OF TEMPLATE CONTEXT
%% ═══════════════════════════════════════════════════════════════════════
```

---

*LaTeX context block added 2026-04-02. Extracted from Chapter1_CriticalReplication.tex.*
*Key Ch1→Ch2 convention change: \dot{x} for growth rates in theory (Ch2), not \hat{x} (Ch1/Shaikh).*
