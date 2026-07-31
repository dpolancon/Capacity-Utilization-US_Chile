---
type: research_note
status: ready_to_fire
created: 2026-07-25
pipeline_stage: "S34 Report Expansion & Downstream \u03C4_t Regime Testing"
depends_on:
  - reports/capital_integration_cointegration_comprehensive_report.tex
  - output/break_informed_johansen_vecm_ledger.csv
  - chapter2_vault/80_Prompts/handoffs/2026-07-25_S34_cointegration_VECM_handoff.md
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
skills_required:
  - /umass-applied-econometrics (with cointegration_specification_audit tool)
  - /deep-research (lit-review mode + full mode)
  - /humanize-writing
governing_rules:
  - AGENTS.md v4
  - WLM v4.0
subtype: execution_prompt
country: US_CL
stage_scope: N/A
last_updated: '2026-07-29'
blocks: []
layer: implementation
scope: chapter2
priority: context
---

# Prompt Suite: Report Coherence Expansion + Downstream τ_t Regime Testing

This document contains two self-contained execution prompts. **Part A fires now** to expand and tighten the existing report. **Part B fires in a future session** to test for coefficient changes across regimes defined by τ_t breaks.

---

## PART A — Report Coherence & Expansion Prompt (Fire Now)

### Objective

Expand the existing LaTeX report at `reports/capital_integration_cointegration_comprehensive_report.tex` so that its 12 sections form a single coherent argument. The current report presents its sections (LOESS visualization, unit root battery, drift/trend VECMs, bootstrap, α loadings, Γ₁ lag structure, political economy reading, specification verdict) sequentially but without a narrative thread that binds them. This prompt creates that thread.

### Governing Skills

1. **Read `/umass-applied-econometrics` SKILL.md** at `c:\ReposGitHub\academic-research-skills\umass-applied-econometrics\SKILL.md` and apply its full 14-point diagnostic checklist (§3). Use the embedded **Cointegration Specification Audit Protocol** at `c:\ReposGitHub\academic-research-skills\umass-applied-econometrics\tools\cointegration_specification_audit.md` to validate that every step of the 7-gate audit sequence appears in the report.

2. **Read `/deep-research` SKILL.md** at `c:\ReposGitHub\academic-research-skills\deep-research\SKILL.md`. Fire in **lit-review mode** with the following research question:

   > **RQ:** What econometric methods exist for identifying and testing structural breaks in cointegrating relationships between heterogeneous capital stocks, and how do non-parametric smoothing techniques (LOESS, kernel regression) complement parametric break tests (Gregory-Hansen, Bai-Perron, Zivot-Andrews) in long-run macroeconomic time series?

   **Scope boundaries:**
   - **In scope:** Gregory-Hansen (1996) cointegration with structural breaks; Bai-Perron (1998, 2003) sequential break testing; Cavaliere et al. (2012) wild bootstrap under non-stationary volatility; LOESS 2nd derivative inflection dating vs. endogenous break detection; regime-switching VECMs (Krolzig 1997, Saikkonen & Lütkepohl 2000).
   - **Out of scope:** Bayesian structural break models, machine learning break detection, financial time series applications.

   The lit-review output feeds directly into a new section to be inserted in the report.

3. **Read `/humanize-writing` SKILL.md** at `c:\ReposGitHub\humanize-writing\SKILL.md`. Apply to all new prose.

### Execution Steps

#### Step 1: Narrative Thread Audit

Read the report in full. For each section transition (§1→§2, §2→§3, ..., §9→§10), write a one-sentence transition claim that connects the departing section's conclusion to the arriving section's burden. These transitions must satisfy:

- The LOESS section (§2) must motivate the unit root section (§3): "The inflection dates in τ_t reveal where the *acceleration* of mechanization bias reversed sign; the unit root battery now establishes whether the *levels* of the composing capital assets are stochastic processes amenable to cointegration."
- The unit root section (§3) must motivate the drift VECM section (§4): "I(1) status of both components is the precondition; Johansen under drift tests whether these I(1) processes share a long-run equilibrium whose coefficient γ̂ carries political economy content."
- The drift VECM (§4) must motivate the trend VECM (§5): "Drift controls test proportional co-movement; trend controls test whether a deterministic compositional drift operates within the equilibrium, distinguishing Fordist balance from post-Fordist decoupling."
- The bootstrap section (§6) must be positioned as *robustness validation* of rank decisions, not as a standalone section.
- The α section (§7) must answer the question opened by §4–§5: "Given that cointegration holds, *who adjusts?*"
- The Γ₁ section (§8) must answer: "Given the direction of long-run adjustment, what is the *gestation lag* of that adjustment?"
- The unified PE reading (§9) must synthesize §4–§8 into the interpretive propositions from the handoff (Propositions A–D).
- The specification verdict (§10) must close the chain: the cointegration evidence from §4–§8 *determines* which mechanization intensity proxy enters the θ_t estimation stage.

Insert these transition sentences into the report as connecting paragraphs between sections.

#### Step 2: LOESS–Structural Break Interweaving

Expand Section 2 (LOESS) using the `/deep-research` lit-review output. The current LOESS section identifies zero-crossings but does not:

a. **Explain the LOESS methodology** — Describe the local polynomial regression, bandwidth selection, and 2nd derivative estimation procedure. Cite Cleveland (1979) and Cleveland & Devlin (1988).

b. **Distinguish LOESS inflections from parametric breakpoints** — The current report states this distinction in one sentence (line 68). Expand into a full paragraph contrasting:
   - LOESS 2nd derivative zero-crossings: non-parametric, identify *curvature reversals* in the composition trajectory (where mechanization acceleration flips sign).
   - Zivot-Andrews / Gregory-Hansen breakpoints: parametric, test for *level or slope shifts* in the unit root process or cointegrating vector.
   - Bai-Perron sequential breaks: identify *structural change dates* in regression coefficients.

   Make clear that the LOESS dates are used as *diagnostic periodization markers* that inform (but do not determine) the historical windows for sub-period VECMs.

c. **Connect inflection dates to political economy periodization** — Each zero-crossing must be traced to a specific distributive or institutional rupture:
   - U.S. 1968: late-Fordist profit squeeze. Cite Weisskopf (1979), Marglin & Schor (1990).
   - Chile 1971: Allende nationalization + capital flight → φ_t compression.
   - Chile 1982: Latin American debt crisis → external constraint binds.

#### Step 3: Unified Figure Strategy

The report currently has 1 figure (LOESS trajectories). Add the following figure specifications (to be generated by R pipeline):

1. **Figure 2: τ_t Path with Regime Bands** — Plot τ_t = ln K^ME − ln K^NRC for both countries on a single panel with vertical dashed lines at LOESS zero-crossings. Shade regime bands in distinct colors. Overlay LOESS-smoothed trend.

2. **Figure 3: γ̂ Coefficient Map Across Windows** — Bar chart or dot-and-whisker plot showing γ̂ estimates across all sub-period and century-long VECMs, separated by drift vs. trend controls. Color-code by cointegration status (r=1 vs r=0).

3. **Figure 4: Speed-of-Adjustment Asymmetry** — Dual-axis or paired dot plot showing α_NRC and α_ME across cointegrated windows. Highlight the Fordist machinery asymmetry and Chile's weak exogeneity.

Insert figure specifications as `% TODO: FIGURE N` LaTeX comments in the appropriate sections. The R code to generate them is a downstream task.

#### Step 4: 14-Point Checklist Compliance

Run the `/umass-applied-econometrics` §3 diagnostic checklist against the expanded report. For each of the 14 points, mark PASS or REVISE and specify what must be changed:

1. BLUF Check — Abstract and Introduction
2. Variable Audit — All symbols defined at first use
3. Active Voice Check — No passive constructions, no AI transitions
4. Visual-First Test — LOESS before parametric
5. Forensic Transparency — Data exclusions justified
6. Endogeneity Audit — Bidirectional feedback discussed
7. Specification Map — Failed specifications reported
8. Descriptive Grounding — Raw growth rates in narrative
9. Institutional Critique — Capacity as contested convention
10. Tone Balance — Authoritative, not defensive
11. Integration Order Gate — All candidates tested
12. Coefficient PE Interpretation — Surplus approach reading
13. Bootstrap Sensitivity — Bootstrap p-values alongside asymptotic
14. Consolidated Verdict Table — Summary table present

#### Step 5: LaTeX Updates

Apply all changes to the LaTeX report at `reports/capital_integration_cointegration_comprehensive_report.tex`. Follow AGENTS.md v4 LaTeX rules:
- Bold: `\textbf{}` only
- Floats: `[h!]` or `[H]`
- `\FloatBarrier` before each `\section`
- Column widths: explicit `p{Xcm}`
- Footnotes: `\footnotesize` within `\multicolumn{N}{p{Wcm}}{...}`

### Output

- Expanded LaTeX report (saved to `reports/`)
- `/deep-research` lit-review output on structural break methods (saved as artifact)
- 14-point checklist audit results (saved as artifact)

---

---

## PART B — Downstream τ_t Regime-Specific Coefficient Testing Prompt (Fire Later)

### Objective

Test whether the cointegrating coefficient γ̂ between k^NRC and k^ME changes significantly across historical regimes defined by breaks in the τ_t = ln K^ME − ln K^NRC path. This directly tests whether the choice of technique operated under qualitatively different accumulation regimes.

### Governing Skills

1. **Read `/deep-research` SKILL.md**. Fire in **full research mode** with the following research question:

   > **RQ:** How can structural breaks in the composition path τ_t = ln K^ME − ln K^NRC be used to identify regime-specific cointegrating vectors between machinery and nonresidential structures, and what do coefficient changes across regimes reveal about the political economy of the choice of technique?

   **Sub-questions:**
   1. What formal tests exist for structural breaks in cointegrating vectors (Gregory-Hansen 1996a,b; Hansen 1992; Kejriwal-Perron 2010)?
   2. How does the Markov-Switching VECM (MS-VECM, Krolzig 1997) allow the cointegrating coefficient to vary across latent regimes?
   3. What is the relationship between non-parametric LOESS inflection dating and endogenous break detection in cointegration?
   4. How should the wild bootstrap (Cavaliere et al. 2012) be adapted for regime-specific sub-sample VECMs with N ≤ 30?

   **Scope boundaries:**
   - **In scope:** Gregory-Hansen cointegration with structural break; Bai-Perron sequential break tests applied to cointegrating residuals; Threshold VECM (Hansen & Seo 2002); LOESS-informed window selection; Cavaliere et al. wild bootstrap for finite samples; political economy of regime-dependent mechanization.
   - **Out of scope:** Bayesian change-point models, smooth transition models (STAR), panel cointegration with breaks.

   **Data context:** The researcher has annual log-levels of machinery (k^ME) and nonresidential structures (k^NRC/k^NR) for the U.S. (1925–2021, N=97) and Chile (1920–2024, N=91). LOESS 2nd derivative zero-crossings have identified inflection dates: U.S. = {1933, 1968, 2008}; Chile = {1936, 1971, 1982}. Full-century VECMs under drift yield γ̂ ≈ 1 (balanced mechanization); sub-period VECMs yield regime-heterogeneous γ̂ values (0.60 for U.S. Fordism, 1.16 for Chile Dictatorship, 0.24 for U.S. trend with institutional breaks).

2. **Read `/umass-applied-econometrics` SKILL.md** and apply Rules G (Integration Order Governance), H (Political Economy Interpretation), and I (Small-Sample Bootstrap). Use the **Cointegration Specification Audit Protocol** to validate each regime-specific VECM.

### Execution Steps

#### Step 1: Deep Research Phase

Fire `/deep-research` in full mode. The research output must cover:

a. **Gregory-Hansen (1996) test** — Test for a single unknown break date in the cointegrating relationship. The null is cointegration with constant parameters; the alternative is cointegration with a structural break (regime shift, trend break, or regime + trend shift). Apply to the full-century k^NRC = α + γ k^ME relationship for both countries. Report the endogenously determined break date and compare it to the LOESS zero-crossings.

b. **Bai-Perron sequential break test** — Apply to the cointegrating residuals û_t from the full-century drift VECM. Test for up to m=3 breaks. Compare the endogenous break dates to the LOESS zero-crossings and the institutional periodization (1973/2008 for U.S.; 1973/1982 for Chile).

c. **Regime-specific sub-sample VECMs** — For each regime window defined by the LOESS breaks:
   - U.S.: {1925–1933, 1933–1968, 1968–2008, 2008–2021}
   - Chile: {1920–1936, 1936–1971, 1971–1982, 1982–2024}
   
   Estimate separate Johansen VECMs with drift and trend controls. Extract γ̂, α, Γ₁ for each regime. Apply Cavaliere et al. (2012) wild bootstrap (500 reps, Rademacher) for sub-samples with N ≤ 30.

d. **Coefficient stability test** — Formally test whether γ̂ is statistically different across adjacent regimes. Options:
   - Wald test for equality of γ̂ across windows
   - Rolling recursive VECM with γ̂ path plotted over time
   - Hansen (1992) parameter instability test on the cointegrating vector

#### Step 2: Political Economy Interpretation of Regime-Specific γ̂

For each regime-specific γ̂, provide a political economy interpretation using the `/umass-applied-econometrics` Rule H framework:

| Regime | Expected γ̂ Range | PE Interpretation |
|---|---|---|
| U.S. Pre-Depression (1925–1933) | γ̂ ≈ ? | Roaring Twenties machinery deepening within expanding industrial plant |
| U.S. Fordist Core (1933–1968) | γ̂ < 1 | Stable wage-profit frontier → induced mechanization within proportional plant expansion |
| U.S. Late Fordism → Neoliberal (1968–2008) | γ̂ << 1 or r=0 | Decoupling: computerization/automation without proportional structure investment |
| U.S. Post-GFC (2008–2021) | γ̂ ≈ ? or r=0 | Secular stagnation: investment collapse in both assets |
| Chile ISI Build-Up (1936–1971) | γ̂ ≈ 1 | Import-substitution balanced accumulation under state direction |
| Chile Dictatorship (1971–1982) | γ̂ > 1 | Deindustrialization of machinery-intensive sectors; structures outpace ME |
| Chile Neoliberal Export (1982–2024) | γ̂ < 1 | Primary export model → machinery imports for mining; structures lag |

#### Step 3: τ_t Path Visualization & Regime Bands

Generate an R script that:

1. Computes τ_t = ln K^ME − ln K^NRC for both countries.
2. Fits LOESS with bandwidth span = 0.3 (or cross-validated optimal).
3. Computes 1st and 2nd derivatives of the LOESS fit numerically.
4. Identifies 2nd derivative zero-crossings.
5. Plots τ_t path with:
   - LOESS smoothed overlay
   - Vertical dashed lines at zero-crossings
   - Shaded regime bands with labels
   - Annotated γ̂ values for each regime (from sub-sample VECMs)
6. Saves to `output/figures/tau_path_regime_bands_US.png` and `output/figures/tau_path_regime_bands_CL.png`.

#### Step 4: Expand the Report

Insert a new section after the current §9 (Unified Political Economy Reading) titled:

> **Section 10: Regime-Specific Cointegrating Vectors and the Historical Periodization of Choice of Technique**

This section must:
- Present the Gregory-Hansen break test results
- Present the Bai-Perron sequential break results on cointegrating residuals
- Compare endogenous break dates to LOESS zero-crossings
- Report regime-specific γ̂ estimates in a new table
- Provide the political economy interpretation of coefficient changes
- Include the τ_t path figure with regime bands
- Apply the cointegration specification audit protocol to each sub-sample VECM

The existing Section 10 (Specification Fork) becomes Section 11.

#### Step 5: Update Ledger

Append regime-specific VECM results to `output/break_informed_johansen_vecm_ledger.csv` with columns for:
- `Regime_Label` (e.g., "US_Fordist_Core_1933_1968")
- `Break_Source` (e.g., "LOESS_2nd_Deriv" or "Gregory_Hansen" or "Bai_Perron")
- All existing columns (Trace, γ̂, α_NR, α_ME, Γ₁, Bootstrap p-values)

### Output

- `/deep-research` full report on regime-switching cointegration methods
- Expanded LaTeX report with new Section 10
- Updated CSV ledger with regime-specific estimates
- R script for τ_t path visualization
- Consolidated regime-specific verdict table

### Connection to Chapter 2 Outline

The regime-specific γ̂ evidence feeds directly into:
- **Section 5.1.1** (US Visual-First Grounding): τ_t regime bands as the non-parametric foundation
- **Section 5.1.2** (US Transformation Elasticity): regime-dependent γ̂ conditions the composition-mediated θ_t
- **Section 6.3.1** (Crisis of Fordism): The 1968 break and the γ̂ shift from Fordist to neoliberal
- **Section 6.3.2** (Crisis of ISI): The 1971 break and γ̂ shift under Allende/Dictatorship

---

*Prompt Suite v1.0 — 2026-07-25*
*Authority: Ch2_Outline_DEFINITIVE.md | AGENTS.md v4 | /umass-applied-econometrics | /deep-research*
