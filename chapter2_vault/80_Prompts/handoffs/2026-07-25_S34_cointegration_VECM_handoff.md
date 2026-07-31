---
type: research_note
status: active
session_date: 2026-07-25
pipeline_stage: "S34 \u2192 Paper-Facing Write-Up"
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
  - chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md
  - chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
  - reports/capital_integration_cointegration_comprehensive_report.tex
  - output/break_informed_johansen_vecm_ledger.csv
  - codes/COMMON_S34_break_informed_vecm_pipeline.R
governing_rules:
  - AGENTS.md v4 (directory governance, notation, LaTeX formatting)
  - /umass-applied-econometrics (BLUF, visual-first, endogenous distribution)
  - "/humanize-writing (active voice \u226570%, no AI transitions, hedging <5%)"
  - chapter2_vault/07_WrittingSkills_and_Rules/ (WLM v4.0)
last_updated: 2026-07-25
subtype: handoff
country: US_CL
stage_scope: N/A
blocks: []
layer: implementation
scope: chapter2
priority: context
---

# S34 Cointegration & VECM Pipeline → Chapter 2 Write-Up Handoff

## Purpose

This handoff bridges the completed S34 econometric pipeline (integration order testing, Johansen cointegration, bootstrap rank tests, VECM speed-of-adjustment, lag structure, and specification verdict) to the paper-facing write-up of Chapter 2. It maps every established empirical fact to its destination section in the locked outline, supplies the exact numerical evidence, and identifies what each finding does for the chapter's argument.

---

## I. Inventory of Established Empirical Facts

### Fact 1: Both Capital Components Are $I(1)$

| Variable | Country | ADF (Trend) | KPSS ($\eta_\tau$) | $\Delta$ ADF | $\Delta$ KPSS | Verdict |
|---|---|---|---|---|---|---|
| $k^{\text{NRC}}$ | U.S. | $-1.46$ | $0.278^*$ | $-3.82^*$ | $0.061$ | $I(1)$ |
| $k^{\text{ME}}$ | U.S. | $-0.22$ | $0.446^*$ | $-4.15^*$ | $0.048$ | $I(1)$ |
| $k^{\text{NR}}$ | Chile | $-0.32$ | $0.447^*$ | $-4.06^*$ | $0.052$ | $I(1)$ |
| $k^{\text{ME}}$ | Chile | $-1.34$ | $0.448^*$ | $-4.29^*$ | $0.041$ | $I(1)$ |

**What this does for the chapter:** Satisfies the precondition for Johansen cointegration. Establishes that capital stock levels are non-stationary stochastic processes whose growth rates are stationary—the integration order admissibility gate for the $\theta_t$ estimation stage (Section 4.1.3 of the outline).

---

### Fact 2: LOESS 2nd Derivative Inflection Dates

| Country | Inflection Dates | Political Economy Reading |
|---|---|---|
| U.S. | **1933**, **1968**, **2008** | Depression trough; late-Fordist profit squeeze (5 years before 1973); GFC |
| Chile | **1936**, **1971**, **1982** | Post-Nitrate ISI transition; Allende FX crisis; Latin American debt crisis |

**What this does for the chapter:** Provides data-first, non-parametric periodization before any parametric model is imposed. The 1968 U.S. inflection is decisive: mechanization deceleration preceded the institutional crisis. The profit squeeze drove the adjustment; the oil shock made it visible. Feeds directly into the "Visual-First" obligation of Section 5.1.1 and the Fordist crisis narrative (Section 6.3.1).

---

### Fact 3: Century-Long Cointegration Under Drift ($\hat{\gamma} \approx 1$)

| Country | Window | N | Trace | $\hat{\gamma}$ | Wild Boot $p$ | Decision |
|---|---|---|---|---|---|---|
| U.S. | Full Century (1925–2021) | 97 | 22.76 | **0.994** | **0.026** | $r=1$ |
| Chile | Full Century (1920–2024) | 91 | 31.36 | **0.955** | **0.004** | $r=1$ |

**What this does for the chapter:** $\hat{\gamma} \approx 1.0$ under LHS $k^{\text{NRC}}$ normalization means structures growth tracked machinery accumulation proportionally across the long century. This is the Fordist settlement encoded in the cointegrating vector. The $\hat{\gamma}$ coefficient carries direct political economy content: it is the structural envelope response to machinery deepening. $\hat{\gamma} \approx 1 \implies \tau_t = k^{\text{ME}} - k^{\text{NRC}}$ is stationary or borderline-stationary, which is the integration order condition that makes $\tau_t$ admissible for the $D_9$ specification.

**Outline destination:** Section 2.3.4 (Two-Capital Composition), Section 4.2.3 (Composition-Mediated Specification B), and the specification verdict (Section 4.2 and embedded empirical strategy).

---

### Fact 4: Sub-Period Cointegration Reveals Regime Heterogeneity

| Country | Window | EC Control | Trace | $\hat{\gamma}$ | Decision |
|---|---|---|---|---|---|
| U.S. | Fordist (1947–73) | const | 25.25 | **0.60** | $r=1$ |
| U.S. | Neoliberal (1974–2008) | const | 12.68 | 1.77 | $r=0$ |
| U.S. | Full Century Inst-Break | trend | 33.72 | **0.24** | $r=1$ |
| Chile | Dictatorship (1974–89) | const | 32.70 | **1.16** | $r=1$ |
| Chile | Democratic (1990–2024) | const | 20.22 | **0.69** | $r=1$ |

**What this does for the chapter:**

- **U.S. Fordist $\hat{\gamma} = 0.60$**: Machinery grew faster than structures. The intensive margin outpaced plant construction under stable wages → the choice of technique deepened mechanization within a proportional structural envelope.
- **U.S. Neoliberal $r=0$**: Financialized accumulation dissolved the Fordist proportionality. No stable long-run link between plant and technique.
- **U.S. Trend $\hat{\gamma} = 0.24$**: Post-1973, machinery expanded at 4× the rate of structures. Computerization and automation without proportional plant expansion → $\theta^N$ shifts toward the machinery payoff.
- **Chile Dictatorship $\hat{\gamma} = 1.16$**: Structures grew faster than machinery. Pinochet-era wage suppression and deindustrialization of machinery-intensive ISI sectors.
- **Chile Democratic $\hat{\gamma} = 0.69$**: Machinery outpaced structures in the export-model era.

**Outline destination:** Section 5.1.1–5.2.4 (empirical results), Section 6.3.1–6.3.3 (crisis dynamics), Section 3.1–3.2 (center-periphery asymmetry).

---

### Fact 5: Cavaliere et al. (2012) Wild Bootstrap Validates Rank Decisions

| Key Result | i.i.d. Boot $p$ | Wild Boot $p$ | Interpretation |
|---|---|---|---|
| Chile Century (const) | 1.000 | **0.004** | Standard bootstrap fails; wild bootstrap confirms robust cointegration |
| U.S. Century (const) | 1.000 | **0.026** | Same pattern: heteroskedasticity-robust confirmation |
| Chile Dictatorship (const) | 0.102 | **0.008** | Standard bootstrap misses it; wild bootstrap confirms at 1% |
| U.S. Fordist (const) | 0.596 | **0.054** | Borderline—machinery-led adjustment under stable Fordist institutions |

**What this does for the chapter:** Demonstrates that standard bootstrap procedures are inadequate for century-long macroeconomic series subject to non-stationary volatility. The Cavaliere et al. wild bootstrap (Rademacher resampling) provides the heteroskedasticity-robust inference required for structural break-scarred capital series. This is a methodological contribution: standard rank tests and i.i.d. bootstraps disagree sharply, and the wild bootstrap resolves in favor of cointegration.

**Outline destination:** Section 4.1.3 (integration order admissibility), Section 5 (empirical results tables).

---

### Fact 6: Speed-of-Adjustment Coefficients ($\alpha$) — The Dynamic Political Economy

| Country | Window | $\alpha_{\text{NRC}}$ ($t$) | $\alpha_{\text{ME}}$ ($t$) | Half-Life | Channel |
|---|---|---|---|---|---|
| U.S. | Full Century | $-0.032$ ($-3.76$) | $-0.018$ ($-2.12$) | 21.9 / 39.2 yr | Bilateral |
| U.S. | Fordist (1947–73) | $-0.151$ ($-2.09$) | **$-0.323$** ($-4.50$) | 4.6 / **2.1** yr | **Asymmetric ME** |
| U.S. | Inst-Break (trend) | $-0.155$ ($-4.95$) | $-0.166$ ($-5.65$) | 4.5 / 4.2 yr | Rapid bilateral |
| Chile | Full Century | $-0.018$ ($-2.57$) | $-0.011$ ($-0.82$) | 38.1 / $\infty$ yr | **Weak exogeneity of ME** |
| Chile | Dictatorship | $-0.051$ ($-2.84$) | $-0.112$ ($-4.58$) | 13.6 / 6.2 yr | Structural squeeze |

**What this does for the chapter:**

1. **U.S. Fordist Asymmetry**: Machinery adjusted twice as fast as structures (half-life 2.1 vs 4.6 years). Tactical equipment investment absorbed short-run disequilibrium rapidly; multi-year plant construction anchored the long run. This asymmetry is the dynamic signature of the choice of technique: the intensive margin (machinery) is the active adjustment instrument under Fordist institutional closure.

2. **Chile Weak Exogeneity**: Machinery is weakly exogenous ($t = -0.82$, insignificant). Chilean firms do not adjust imported machinery purchases to restore domestic structural balance. Machinery accumulation is driven by foreign exchange availability ($\phi_t$), not by domestic equilibrium-restoring behavior. Structures absorb the full adjustment burden. This is the econometric fingerprint of peripheral dependency: the intensive margin is externally constrained.

**Outline destination:** Section 2.3.3 (intensive margin), Section 3.2.2–3.2.3 (FX bottleneck, effective profit share squeeze), Section 5.1–5.2 (results), Section 6.1–6.2 (profitability transmission).

---

### Fact 7: Short-Run Lag Structure ($\Gamma_1$) — Investment Gestation

| Country | Equation | $\gamma_{11}$ (own NRC) | $\gamma_{12}$ (cross ME) | Key Pattern |
|---|---|---|---|---|
| U.S. | $\Delta k^{\text{NRC}}_t$ | $+0.420^*$ | $+0.153^*$ | Structure inertia + ME spillover |
| U.S. | $\Delta k^{\text{ME}}_t$ | $+0.307^*$ | $+0.478^*$ | Bilateral complementarity |
| Chile | $\Delta k^{\text{NR}}_t$ | $+0.491^*$ | $+0.195^*$ | Structure inertia + weak ME spillover |
| Chile | $\Delta k^{\text{ME}}_t$ | $-0.203$ | **$+0.989^*$** | Extreme ME autoregression; no NR feedback |

**What this does for the chapter:** 

- **U.S.**: Prior-year structure growth pushes machinery investment ($\gamma_{21} = +0.307$). Expanding physical plant opens capacity for new machinery—complementarity within the structural envelope.
- **Chile**: Machinery exhibits near-unit-root autoregressive persistence ($\gamma_{22} = 0.989$) with zero feedback from structures ($\gamma_{21} = -0.203$, insignificant). Machinery investment is driven by its own momentum and import access, not domestic plant construction. This is consistent with Fact 6: machinery is externally determined.

**Outline destination:** Section 2.3.2 (extensive margin, multi-year plant gestation), Section 3.2.1 (import-constrained machinery).

---

### Fact 8: Specification Fork Verdict — Only $\tau_t$ Survives

| Candidate | Theory Gate | Integration Gate | Status |
|---|---|---|---|
| $k^{\text{ME}}_t$, $k^{\text{NRC}}_t$ (unrestricted) | ✓ Capacity identity | ✗ $r = 0.9944$; $I(2)$ risk | **Rejected** |
| $\tau_t = k^{\text{ME}} - k^{\text{NRC}}$ | ✓ Composition state | ✓ $I(1)/I(0)$; CN = 4.81 | **Promoted ($D_9$)** |
| $q_t = K^{\text{ME}}/L$ | ✓ FOC observable | ✗ Unresolved $I(2)$ | **Blocked** |
| $Q_t^\omega$ | ✓ Induced innovation | ✗ $r = 0.99997$ with $k^{\text{cap}}$ | **Rejected** |
| $Q_t^{\text{ME share}}$ | ✓ Composition stock | ✗ $r = 0.998$ with $k^{\text{cap}}$ | **Held** |
| $Q_t^q$ | ✓ $q^*$ direct proxy | ✗ Unresolved $I(2)$ | **Blocked** |

**What this does for the chapter:** This is the decisive empirical gate for Section 4.2 (Econometric Specifications). The $\theta_t$ estimation stage can only use the composition-mediated specification:

$$y_t = \alpha + \theta \tilde{k}_t^{\text{NRC}} + \psi \tilde{\tau}_t + \phi \tilde{\omega}_t + \lambda \hat{u}_t^{(\tau, \omega)} + \varepsilon_t \qquad (D_9)$$

The rejection of raw $q_t$ is not a theoretical failure—the theory correctly describes the firm's decision mechanism. The econometric problem is that the observable $q_t$ is too persistent ($I(2)$-risky) for standard cointegration designs. The theory survives; the variable does not.

**Outline destination:** Section 4.2.2–4.2.3 (US Specifications A and B), Section 4.2.5 (interaction terms as friction proxies).

---

## II. Mapping to Paper-Facing Outline Sections

### Section 1 (Introduction) — Paragraphs 1.1–1.5

**Use from this handoff:**
- Fact 3 (century $\hat{\gamma} \approx 1$) as the BLUF: structures tracked machinery proportionally across the Fordist settlement.
- Fact 8 ($\tau_t$ as sole survivor) as the specification verdict.
- Fact 6 (Chile weak exogeneity) for the comparative divergence paragraph (1.4).

**Register rule:** BLUF by second paragraph. State the result, then motivate it. No hedging.

---

### Section 2 (Micro-Meso Hinge) — Paragraphs 2.3.1–2.3.5

**Use from this handoff:**
- Fact 1 ($I(1)$ capital components) grounds the formal benchmark in stochastic reality.
- Fact 3 ($\hat{\gamma}$ near unity) maps directly onto Paragraph 2.3.4 (Two-Capital Composition). The cointegrating coefficient is the empirical counterpart of the theoretical composition-weighted $\theta^N(\pi, s)$.
- Fact 6 ($\alpha$ asymmetry) feeds Paragraph 2.3.5: shop-floor effort calibration (Vidal) and market anarchy (Okishio) push $a_t$ away from $a^N$, and the speed-of-adjustment tells you which capital asset bears the correction burden.
- Fact 7 (lag structure) grounds Paragraph 2.3.2: the extensive margin evolves with multi-year plant commitment inertia ($\gamma_{11} \approx 0.42$–$0.49$).

---

### Section 3 (Center-Periphery Extension) — Paragraphs 3.1–3.3

**Use from this handoff:**
- Fact 6 (Chile weak exogeneity of ME, $\alpha_{\text{ME}} = -0.011$, $t = -0.82$) is the econometric fingerprint of Paragraph 3.2.2 (FX conversion ratio $\phi_t$).
- Fact 4 (Chile trend-control failure) validates Paragraph 3.2.3: episodic BOP crises prevent century-long trend-stationary equilibrium.
- Fact 7 (Chile extreme ME autoregression $\gamma_{22} = 0.989$) confirms Paragraph 3.2.1: machinery investment is import-driven, not domestically coordinated.
- Fact 4 (U.S. neoliberal $r=0$) and Fact 3 (U.S. Fordist $\hat{\gamma} = 0.60$) ground Paragraphs 3.1.1–3.1.3 (institutionalized class compromise and its dissolution).

---

### Section 4 (Empirical Strategy) — Paragraphs 4.1–4.4

**Use from this handoff:**
- Fact 1 (integration order battery) → Paragraph 4.1.3 (integration order admissibility gate).
- Fact 8 (specification fork) → Paragraphs 4.2.2–4.2.3 (US Specifications A and B). Only $\tau_t$ enters Specification B ($D_9$). Specification A uses aggregate $k_t^{\text{cap}}$ with distribution interaction.
- Fact 5 (Cavaliere wild bootstrap) → Paragraph 4.2.5 (robustness) and methodology credibility.

---

### Section 5 (Empirical Results) — Paragraphs 5.1–5.3

**Use from this handoff:**
- Fact 2 (LOESS inflections) → Paragraph 5.1.1 (Visual-First non-parametric analysis).
- Facts 3 & 4 (cointegration tables) → Paragraphs 5.1.1 and 5.2.1 (formal rank tests).
- Fact 6 ($\alpha$ coefficients) → Paragraphs 5.1.2 and 5.2.2 (error-correction dynamics alongside $\hat{\theta}_t$).
- Fact 7 (lag structure) → supporting evidence within results interpretation.
- Fact 5 (bootstrap) → Paragraphs 5.1.4 and 5.2.4 (sensitivity/robustness diagnostics).

---

### Section 6 (Discussion) — Paragraphs 6.1–6.3

**Use from this handoff:**
- Fact 6 (U.S. Fordist $\alpha_{\text{ME}} = -0.323$, half-life 2.1 yr) → Paragraph 6.1.1 (US capacity transmission). The machinery-led adjustment under Fordism is the dynamic mechanism through which distribution conditions the capacity ceiling.
- Fact 6 (Chile weak exogeneity) → Paragraph 6.1.2 (Chilean capacity transmission). The FX-bounded ceiling on profitability.
- Fact 4 (U.S. neoliberal non-cointegration, trend $\hat{\gamma} = 0.24$) → Paragraph 6.2.1 (structural overaccumulation). Machinery deepening without proportional plant expansion is the accumulation pattern that generates $\hat{\theta} < 1.0$.
- Fact 2 (1968 inflection before 1973) → Paragraph 6.3.1 (Crisis of Fordism). The profit squeeze drove mechanization deceleration before the institutional rupture.
- Fact 2 (1971 Chile inflection) → Paragraph 6.3.2 (Crisis of ISI). FX conversion ratio tightened as capital flight blocked imported machinery under Allende.

---

## III. Key Interpretive Propositions for the Write-Up

### Proposition A: The Cointegrating Coefficient as Political Economy Object

The cointegrating vector $k_t^{\text{NRC}} = \hat{\alpha} + \hat{\gamma} k_t^{\text{ME}}$ is not a statistical curiosity. $\hat{\gamma}$ is the structural envelope response to machinery deepening:

$$\hat{\gamma} = \frac{\partial k^{\text{NRC}}}{\partial k^{\text{ME}}}$$

When $\hat{\gamma} \approx 1.0$: balanced Fordist proportionality. When $\hat{\gamma} < 1.0$: machinery deepening outpaces plant expansion—the intensive margin dominates. When $\hat{\gamma} \ll 1.0$ or $r=0$: the institutional link between technique choice and structural scale has dissolved.

### Proposition B: $\tau_t$ as the Sole Econometric Carrier of Mechanization

The specification fork is resolved: only $\tau_t = \ln K^{\text{ME}} - \ln K^{\text{NRC}}$ clears both the theoretical gate (indexes composition-mediated choice of technique without requiring labor data) and the integration order gate ($I(0)$ or borderline under drift cointegration with $\hat{\gamma} \approx 1$). The surviving specification family is $D_9$.

### Proposition C: Center-Periphery Asymmetry in Error-Correction

The speed-of-adjustment vectors reveal qualitatively different accumulation regimes:
- **Core (U.S.)**: Bilateral adjustment—both assets respond to disequilibrium. Machinery adjusts faster during Fordism. The choice of technique is domestically endogenous.
- **Periphery (Chile)**: Weak exogeneity of machinery. The intensive margin is externally determined by $\phi_t$. Structures bear the full adjustment burden. The choice of technique is foreign-exchange-constrained.

### Proposition D: The 1968 Inflection as Causal Ordering Evidence

The LOESS 2nd derivative zero-crossing at 1968 (five years before the 1973 institutional break) establishes causal ordering: the distributional squeeze drove mechanization deceleration before the oil shock and institutional crisis. This is evidence for the induced innovation mechanism ($\omega \uparrow \implies \pi \downarrow \implies q^* \uparrow$ slows as distributional room narrows).

---

## IV. Files, Artifacts, and Pipeline State

### Primary Output Artifacts

| File | Location | Content |
|---|---|---|
| Results Ledger | [break_informed_johansen_vecm_ledger.csv](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/break_informed_johansen_vecm_ledger.csv) | 29-row CSV with all VECM estimates, bootstrap $p$-values, $\alpha$, $\Gamma_1$ |
| LaTeX Report | [capital_integration_cointegration_comprehensive_report.tex](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/reports/capital_integration_cointegration_comprehensive_report.tex) | 403-line, 12-section manuscript with 7 tables and 1 figure |
| Compiled PDF | [capital_integration_cointegration_comprehensive_report.pdf](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/reports/capital_integration_cointegration_comprehensive_report.pdf) | Compiled (0 errors) |
| LOESS Figure | [chile_us_capital_breaks_loess.png](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/figures/chile_us_capital_breaks_loess.png) | 4-panel LOESS trajectories with 2nd derivative overlays |
| Pipeline Script | [COMMON_S34_break_informed_vecm_pipeline.R](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/COMMON_S34_break_informed_vecm_pipeline.R) | Full VECM pipeline with $\alpha$, $\Gamma_1$ extraction |

### Vault Authority Files

| File | Role |
|---|---|
| [Ch2_Outline_DEFINITIVE.md](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md) | Locked paragraph-level micro-outline |
| [00N_Chapter2_PaperFacing_MAP.md](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md) | Section-level burden map and register lock |
| [00E_Chapter2_PaperFacing_Constitution.md](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md) | Constitutional one-sentence test |

---

## V. Open Items for Next Session

### Immediate Next Steps (Pre-$\theta_t$ Estimation)

1. **Write Sections 4.2.2–4.2.3** of the paper using the specification verdict (Fact 8). The $D_9$ specification family is locked. Write the empirical strategy section with the composition-mediated specification as the leading design.

2. **Embed VECM Evidence in Section 5**: Translate the 7 tables from the LaTeX report into the paper-facing narrative. The cointegration tables, $\alpha$ table, $\Gamma_1$ table, bootstrap table, and specification verdict table are all publication-ready.

3. **Write Section 6.3** (Crisis Dynamics): Use the 1968 inflection (Fact 2) and the neoliberal non-cointegration (Fact 4) to write the Fordist crisis narrative. Use Chile's 1971 inflection and weak exogeneity (Fact 6) for the ISI crisis narrative.

### Downstream Pipeline (Post-Handoff)

4. **$\theta_t$ Estimation Stage (S40–S50)**: Deploy $D_9$ specification with $\tilde{\tau}_t$ and $\tilde{\omega}_t$ interaction. Estimator: IM-OLS (CPR-adapted) as baseline, FM-OLS as diagnostic comparator.

5. **Capacity Reconstruction ($\hat{Y}^p_t$, $\hat{\mu}_t$)**: Once $\hat{\theta}_t$ is recovered, reconstruct the capacity series and utilization rate for both countries.

6. **Sensitivity**: Pinch-year normalization tests, $\theta = 1.0$ restriction counterfactual, no-dummy counterfactual.

### Notation Reminders (from AGENTS.md v4)

- $\mu_t$ = capacity utilization (never "u")
- $\chi_t$ = recapitalization rate (never $\beta_t$)
- $q$ = mechanization growth rate (never $m$)
- $\theta_t = \theta_1 + \theta_2\pi_t$ = distribution-conditioned transformation elasticity
- $K^{\text{NR}}$ = nonresidential structures; $K^{\text{ME}}$ = machinery and equipment
- MPF (not IPF); "Harrodian benchmark" (not "natural rate of growth")
- $\beta_j$ reserved for cointegrating vectors and Layer-2 coefficients only

---

## VI. Constitutional One-Sentence Test

Every section of the write-up must serve this sentence:

> **Chapter 2 reconstructs capacity utilization as a structurally mediated object by identifying the transformation elasticity through which distribution conditions the conversion of accumulation into productive capacity under capitalist disequilibrium, and by comparing how that same problem is differently determined in the center and the periphery.**

The S34 pipeline establishes the empirical foundation: the integration order evidence, cointegrating vectors, speed-of-adjustment dynamics, and specification verdict are the quantitative substrate that this sentence rests upon.

---

*Handoff v1.0 — 2026-07-25*
*Session: dde829f2-9b4b-42db-85bc-10040c085fcd*
*Authority: Ch2_Outline_DEFINITIVE.md | AGENTS.md v4 | WLM v4.0*
