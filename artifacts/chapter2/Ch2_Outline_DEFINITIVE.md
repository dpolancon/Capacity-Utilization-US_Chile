# Chapter 2 — Definitive Outline
## Demand-Led Profitability and Structural Crisis of Capitalism
## in Chile and the United States during the Fordist Era

> **Status:** Definitive. Section numbers frozen.
> **Date:** 2026-04-02
> **Canonical base:** `Prospectus_CH2.pdf` (§3.1–§3.6), prospectus LaTeX text.
> **Modification:** Investment function identification grounded in the accounting foundation
> of capital accumulation (`capital_accumulation_accounting_behavioral_id.md`). Four
> prospectus specs nested via progressive disaggregation of $r = \mu b \pi$.
> **Period:** 1945–1978 (Fordist era). Rolling-window robustness uses wider dataset.
> **Bibliography:** `ch2_references.bib` (44 entries, locked).

---

## Chapter Architecture

```
         ANALYTICAL FRAMEWORK
         ┌─────────────────────────────────────────────────────┐
         │ Accounting Foundation                               │
         │   g_K = χ · π · μ · b   (accumulation identity)    │
         │   r   = μ · b · π       (Weisskopf sub-identity)   │
         │                                                     │
         │   Investment specs nest r's components with         │
         │   increasing disaggregation:                        │
         │   KR (r compressed) → BM (ρ=μb, π) → FM (b, π, μ) │
         └─────────────────────────────────────────────────────┘

         EMPIRICAL STAGES
         ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
         │   STAGE A    │───▶│   STAGE B    │    │   STAGE C    │
         │ RRR/CVAR     │    │ Weisskopf    │    │ ARDL nested  │
         │ Identifies   │───▶│ Profitability│    │ investment   │
         │ μ̂, B̂, θ̂     │    │ r = μ̂ b̂ π  │    │ KR→BM→FM    │
         │(contribution)│    │(descriptive) │    │(behavioral)  │
         └──────────────┘    └──────────────┘    └──────────────┘
                │                                       ▲
                └───────────────────────────────────────┘
                  μ̂ and B̂ enter Stage C as regressors
```

**Reading the architecture:**
- The accounting foundation (§2.3) is the conceptual scaffolding for both Stage B and
  Stage C. It is not an empirical exercise — it establishes why the Weisskopf decomposition
  and the ARDL investment function specs are structurally related.
- Stage A (§2.5) is the chapter's empirical contribution: it estimates the MPF
  $a = \alpha_1 q + \alpha_2 q^2$, derives $\hat{\theta}_t = (\hat{\alpha}_1 + \pi_t)/2$
  from the Cajas-Guijarro (2024) FOC, and recovers $\hat{\mu}_t$ and $\hat{b}_t$.
  Nothing downstream can run without it.
- Stage B (§2.6) applies the Weisskopf decomposition using Stage A outputs — this is what
  makes the profitability analysis new relative to Weisskopf (1979) and subsequent literature.
- Stage C (§2.7) uses the FM spec as the primary investment function, grounded in the
  two-layer identification: Layer 1 (three channels, entered separately by default) and
  Layer 2 (behavioral coefficient interpretation relative to the Cambridge benchmark).
  KR and BM are tested as compressions within the FM framework. Stage A outputs enter
  FM directly as regressors — the channel separation that Stage A produces is precisely
  what the Okishio test requires.

---

## §2.1 Introduction

**Prospectus base:** §3.1 (Research Question) + §3.2 (Hypothesis).

**Research question:** Is the path of capacity utilization a "crisis trigger"? What is the
mechanism from capacity utilization to an economic crisis? Was CU a crisis trigger in the
demise of the Fordist Accumulation Regime in the United States and the Inward-Looking
Accumulation Regime in Chile?

**Hypothesis:** The decentralized autonomous decision-making of individual capitalists produces
a secular trend toward cumulative disequilibrium — the mismatch between effective demand and
potential output is systematically unstable. CU rates reverse toward normal capacity after
periods of over-accumulation or under-consumption, but they overshoot, producing stagnation
episodes of increasing severity. Aggregate demand can offset multiple stagnation tendencies
via spatio-temporal fixes (Harvey 2003), deferring crisis to future horizons — but incubating
the conditions for a more violent reversal that contracts accumulation demand and triggers
structural crisis (Okishio 1961; Vidal 2019).

The capitalist periphery's CU path is structurally different: financial subordination to the
global hegemon and the external constraint shape the path of CU with a different
upward-downward profile than in the center (Prebisch 1981).

**Chapter map:** The chapter proceeds in three stages. First, it estimates the mechanization
possibility frontier (MPF) and derives structurally identified $\hat{\mu}_t$, $\hat{b}_t$,
$\hat{\theta}_t$ from the Cajas-Guijarro (2024) cost-minimization FOC — the chapter's
empirical contribution. Second, it uses those estimates to run a Weisskopf (1979) profitability
decomposition, revisiting its results with behaviorally grounded CU. Third, it estimates a
behavioral investment function grounded in the accounting foundation of capital accumulation,
with the four prospectus specs (KR, KRS, BM, FM) nested as progressive disaggregations of
$r = \mu b \pi$ — testing Shaikh (2016)'s net profitability hypothesis and Okishio (1961)'s
crisis-trigger hypothesis.

---

## §2.2 Literature Review: Marxist Crisis Theory and the Role of Capacity Utilization

**Prospectus base:** §3.3.

### §2.2.1 Crisis as the Limit of Capitalist Accumulation

**Shaikh (1978):** capitalism is inherently crisis-prone; demand stimulus transforms crisis by
displacing it temporally, not resolving it. The limit of capitalist accumulation is capitalism
itself.

**Itoh (1978):** distinguishes *excess of capital* (overaccumulation beyond profitable use) and
*excess commodity crisis* (underconsumption/realization failure). Both arise from competitive
processes intrinsic to the capitalist mode of production. Neither precludes the other.

### §2.2.2 Disproportionality, Class Struggle, and Spatial Fixes

**Arrighi (1978):** crisis as falling profitability through disproportionality — two forms:
(i) downward wage pressure → demand deficiency → realization crisis; (ii) upward wage pressure
→ profit squeeze → accumulation bottleneck. Concentration and centralization of capital
(Marx, KPVI) accelerate during crisis: stronger collective capitalist power, but also more
concentrated working-class leverage. The state absorbs excess capital through unproductive
expenditures (military, social reproduction) without resolving the underlying contradiction.

**Harvey (2018):** spatio-temporal fixes — crisis displaced across space and deferred across
time through investment in built environments and geographical restructuring. Three cuts of
crisis: (i) overaccumulation/underconsumption as cyclical phases; (ii) credit system bridging
temporal gaps in the circuit; (iii) geographical reallocation displacing crisis to other
spaces and future horizons (Harvey 2001; Luxemburg 2015; Poulantzas 2000; Trotsky 2017).

### §2.2.3 Okishio's Crisis Trigger: Cumulative Causation through Capacity Utilization

**Okishio (1961):** decentralized capitalist decision-making produces systemic disequilibrium
of aggregate demand in the long run. The *crisis trigger* concept: CU is intrinsically
unstable — always reversing toward normal capacity, but overshooting. Two distinct expressions:

- **Overaccumulation** (*excess of capital*): CU driven above normal → inventories accumulate
  → devaluation → profit collapse → violent downward reversal driven by herd behavior.
- **Underconsumption** (*excess of commodities*): wage suppression → demand deficiency →
  realization crisis; smoother and more secular in character.

### §2.2.4 The Firm and Market Anarchy: Multi-Scalar Contradictions Rule Out a Unified Desired CU

Okishio (1961) grounds aggregate CU instability in the herd behavior of individual capitalists
facing market conditions — a macro claim asserted without a firm-level foundation. The
post-Keynesian utilization controversy asks a prior question: do firms hold a stable *desired*
capacity utilization rate that anchors investment plans? The standard Kaleckian answer is
affirmative. This paper argues for a firm-level reason to doubt it that is prior to and
independent of between-firm competition.

The firm is not a unified decision-body. Contradictory imperatives operate at different
organizational scales simultaneously: securing labor discipline and extracting sufficient
output in the short run versus developing and mobilizing workers' cognitive capacities for
coordination, flexibility, and learning over the longer run. These imperatives are
irreconcilable within a single planning horizon. Pressure from shareholders, creditors,
supply-chain bargaining, and operational management pull the utilization decision in
incompatible directions. There is therefore no coherent desired CU rate to anchor investment
plans — not because of competitive pressure *between* firms, but because of multi-scalar
contradictions *within* the firm (Vidal 2014, 2019).

The market is anarchic because social production is not consciously coordinated. The firm
does not overcome that anarchy; it internalizes it through constrained planning shaped by
uncertainty and contradictory interests across organizational scales. This gives Okishio's
cumulative disequilibrium a two-level foundation: no stable within-firm target from which
to aggregate, *and* no coordination mechanism between firms. The crisis trigger operates
at both levels simultaneously.

The Fordist accumulation regime $\Lambda$ temporarily stabilized the within-firm contradiction.
High effective demand, a regulated wage relation, and stable financial conditions
institutionally aligned the competing imperatives sufficiently to produce a *de facto*
normal CU — not because the firm became internally unified, but because the external
institutional settlement suppressed the contradiction long enough for planning horizons
to extend. The demise of the Fordist settlement re-releases it. What the Weisskopf
decomposition records as a falling $\hat{\mu}_t$ in the late 1960s is, at the firm level,
the loss of that institutional anchor and the re-emergence of multi-scalar contradiction.

**Sources:** Okishio (1961); Vidal (2014, 2019); Kalecki (1971); Bhaduri and Marglin (1990).

### §2.2.5 Synthesis: A Multi-Level Theory of the Crisis Trigger

The four strands produce a coherent ladder:

| Level | Mechanism | Reference |
|---|---|---|
| Mode of production | Crisis is endemic; demand stimulus displaces, not resolves | Shaikh (1978); Itoh (1978) |
| Meso/spatial | Spatio-temporal fixes displace crisis across space and time | Arrighi (1978); Harvey (2001, 2018) |
| Aggregate/macro | CU path is the crisis trigger; cumulative disequilibrium | Okishio (1961) |
| Firm/organizational | Multi-scalar contradictions rule out a stable desired CU | Vidal (2014, 2019) |

The Fordist accumulation regime $\Lambda$ is the institutional settlement that operates
across all four levels simultaneously — holding the class struggle within distributable
bounds, stabilizing the spatial fix, suppressing within-firm contradiction, and keeping
CU near enough to normal capacity that stagnation tendencies offset rather than reinforce.
The chapter tests empirically what happens when that settlement breaks.

**Sources:** Shaikh (1978, 2016); Itoh (1978); Arrighi (1978); Marx (KPVI, KPVII); Harvey
(2001, 2003, 2018); Okishio (1961); Vidal (2014, 2019); Luxemburg (2015); Poulantzas (2000);
Trotsky (2017); Duménil and Lévy (2010); Basu (2019).

---

## §2.3 Analytical Framework

This section establishes the conceptual scaffolding that organizes all three empirical
stages. The two-layer accounting-behavioral identification is load-bearing: Layer 1
(accounting identity) establishes three distinct channels of accumulation and motivates
the FM spec as the primary estimating equation; Layer 2 (behavioral identification)
provides the coefficient interpretation and connects to the Cambridge benchmark. Together
they determine the structure of Stage C — not as background decoration, but as the
logic that fixes which model is primary and which are tested compressions.

### §2.3.1 Stagnation and Crisis: A Typology

**Prospectus base:** §3.4.1.

Distinguishing stagnation from crisis allows identification of multiple offsetting tendencies.

**Definitions (Vidal 2014, 2019):**
- **Stagnation tendency:** downward pressure on profitability
- **Partial crisis:** interruption of the economy-wide circuit of capital, resolvable by
  partial institutional reconfiguration
- **Structural crisis:** deep and prolonged interruption requiring drastic restructuring of
  the accumulation regime $\Lambda$

**Typology (Basu 2019, redefined in Vidal's terms):**

|  | *Excess of Surplus Value* | *Deficit of Surplus Value* |
|---|---|---|
| **Demand side** | Under-consumption / realization crisis | Profit squeeze (rising labor strength) |
| **Financial side** | Financial fragility | Falling (normal) rate of profit |

This grid is the interpretive template for Stage B and Stage C results.

### §2.3.2 Layer 1 — The Accounting Foundation

**Prospectus base:** §3.4.2 (Weisskopf decomposition). Extended by
`capital_accumulation_accounting_behavioral_id.md`.

**The Weisskopf decomposition** — profit rate over non-residential capital stocks:

$$r \equiv \frac{\Pi}{K} = \frac{Y}{Y^p}\cdot\frac{Y^p}{K}\cdot\frac{\Pi}{Y} = \mu\cdot b\cdot\pi$$

| Factor | Symbol | Definition | Channel |
|---|---|---|---|
| Capacity utilization | $\mu = Y/Y^p$ | Demand realization; Keynes's effective demand; Marx's realization within the capital circuit (Foley 1982) | Demand |
| Capital productivity | $b = Y^p/K$ | Technological conditions "cleaned" from demand effects; underlies the degree of mechanization | Technology |
| Profit share | $\pi = \Pi/Y$ | Distributive conflict between workers and capitalists | Distribution |

Demand-led content: effective profitability is $r = \mu \times r^n$, where $r^n \equiv b\pi$
is normal-capacity profitability. Capitalists signal from $r$, not $r^n$ (Blecker and
Setterfield 2019; Foley 1982).

**The gross accumulation identity** — nests the Weisskopf decomposition:

$$g_K \equiv \frac{I}{K} = \frac{I}{\Pi}\cdot\frac{\Pi}{Y}\cdot\frac{Y}{Y^p}\cdot\frac{Y^p}{K}
= \chi\cdot\pi\cdot\mu\cdot b$$

**Notation:** $\chi \equiv I/\Pi$ is the recapitalization rate throughout.

Since $r = \pi\mu b$, the identity collapses to the Cambridge equation:
$$k = \chi r - \delta$$

**What Layer 1 implies for Stage C:** The accumulation identity identifies three distinct
channels — demand ($\mu$), technology ($b$), distribution ($\pi$). Layer 1 says these
should be entered separately in the investment function *by default*: compressing them
into $r$ suppresses regime-relevant information. The full disaggregation (FM spec) is
therefore the primary estimating equation. KR and BM are compressions whose empirical
warrant must be tested, not assumed.

**Two dependent variables (prospectus §3.4.3, preserved throughout):**

| Variable | Definition | Interpretation |
|---|---|---|
| $\kappa_t = I/K$ | Rate of capital accumulation | Capital deepening; Robinson convention |
| $a_t = I/\Pi \equiv \chi_t$ | Rate of capitalization | Surplus reinvestment speed; Foley (1982) |

Short run: $a_t$ adjusts faster than $\kappa_t$ — reinvesting a profit share is operationally
faster than expanding the capital stock. Theoretical primacy: $a_t = \chi_t$ is the
recapitalization rate whose behavioral response Stage C estimates.

### §2.3.3 Layer 2 — The Behavioral Identification

Layer 2 derives the primary estimating equation from the accumulation identity and provides
a structural interpretation of its coefficients. Take logs (exact — no approximation):

$$\ln g_K = \ln\chi + \ln\pi + \ln\mu + \ln b$$

Under Cambridge closure ($\chi = \bar{\chi}$), $\ln\chi$ absorbs into the constant and the
identity imposes **unit elasticity** on every channel. Allow $\chi$ to respond log-linearly
to conditions: $\ln\chi = \eta_0 + \eta_1\ln\pi + \eta_2\ln\mu + \eta_3\ln b$. Substituting
and defining $\beta_j \equiv 1 + \eta_j$:

$$\boxed{\ln g_K = c + \beta_1\ln\pi + \beta_2\ln\mu + \beta_3\ln b + \varepsilon}$$

**Dual interpretation of FM coefficients:**

| Coeff. | Accounting benchmark ($\beta_j = 1$) | Behavioral content ($\eta_j = \beta_j - 1$) |
|---|---|---|
| $\beta_1$ | Cambridge closure on distribution | $\chi$ elasticity w.r.t. $\pi$: recapitalization response to profit share |
| $\beta_2$ | Cambridge closure on demand | $\chi$ elasticity w.r.t. $\mu$: recapitalization response to CU |
| $\beta_3$ | Cambridge closure on technology | $\chi$ elasticity w.r.t. $b$: recapitalization response to capital productivity |

$\beta_j = 1$: $\chi$ does not respond on that channel — accumulation is mechanically
determined by accounting. $\beta_j \neq 1$: behavioral departure; over-response ($\beta_j > 1$)
or under-response ($\beta_j < 1$) relative to the Cambridge benchmark.

**Scope of the claim (modest):** The log-linear Layer-2 equation is the interpretation
framework for the FM coefficients and establishes Cambridge closure ($\beta_j = 1$) as the
accounting benchmark. KR and BM are *economically motivated compressions* of the three
channels — tested as restrictions within the FM framework via Wald tests, not claimed as
algebraic restrictions on the log-linear equation (which would require functional-form
compatibility that the levels specs do not satisfy).

**The Okishio crisis-trigger restriction** in Layer-2 terms: $H_0: \beta_2 = \beta_3$ —
CU and capital productivity enter $\chi$'s response identically. Rejection: CU has an
independent behavioral effect on recapitalization beyond its accounting role through $r$.
This is the crisis-trigger test, and it requires Stage A's clean channel separation to be
identified.

---

## §2.4 Data

Both datasets are the author's own constructions, maintained in reproducible GitHub
repositories. Secondary sources enter as inputs to those pipelines, not as direct
chapter inputs.

**Primary estimation period:** 1945–1978 (Stages B and C). Stage A uses the full
available sample from each repository.

### §2.4.1 United States — `dpolancon/US-BEA-Income-FixedAssets-Dataset`

BEA and FRED data fetched via API. R pipeline. Contains income (NIPA) and fixed asset
tables for the United States.

| Variable | Symbol | BEA/FRED table | Notes |
|---|---|---|---|
| Real GDP | $Y_t$ | NIPA Table 1.1.6 | |
| National income components | $\Pi_t$, $W_t$ | NIPA Table 1.12 | Profit share $\pi_t = \Pi_t/Y_t$ derived |
| Net nonresidential capital stock — total | $K_t$ | BEA Fixed Assets Table 2.1 | |
| Net capital stock — structures | $K_t^{NR}$ | BEA Fixed Assets Table 2.1 | Nonresidential structures; Stage A comparator |
| Net capital stock — equipment | $K_t^{ME}$ | BEA Fixed Assets Table 2.1 | Stage A comparator |
| Gross private nonresidential investment | $I_t$ | NIPA Table 1.1.5 | |
| Employment | $L_t$ | BLS Current Employment Statistics (FRED) | For $a_t = y_t - l_t$, $q_t = k_t - l_t$ |
| Interest rate | $i_t$ | Moody's Baa corporate / Fed Funds Rate (FRED) | Stage C (Shaikh spec) only |

**Sample available:** ~1929–2024 (full BEA/FRED coverage). Primary estimation: 1945–1978.

### §2.4.2 Chile — `dpolancon/K-Stock-Harmonization`

Stock-flow consistent capital-stock harmonization. Python pipeline. Three production
surfaces:

| Surface | Coverage | Base price | Control concept | Status |
|---|---|---|---|---|
| Hofman accounting reference | 1900–1994 | 1980 CLP | Hofman only | Frozen; audit reference |
| **Canonical Pérez baseline** | **1900–1994** | **2003 CLP** | **Pérez machinery + construction; inventories excluded** | **Primary** |
| BCCh extension bundle | 1900–2024 | 2003 CLP | Canonical 1900–1994 preserved; BCCh net stocks forward | Extended |

**Capital type decomposition — available and load-bearing for Stage A.2:**

The canonical surface's control concept maps directly onto the Stage A.2 structural split:
- $K_t^{ME,CL}$ = machinery component (Pérez FBKF machinery; BCCh forward from 1995)
- $K_t^{NR,CL}$ = construction component (Pérez FBKF construction; BCCh forward from 1995)

This resolves the Stage A.2 capital-type stage-gate: **Approach 3 (direct disaggregation)
is available.** No proxy or indirect inference required for $\bar{\alpha}_1^{CL}$.

The companion $P_K$ series (investment price deflator) is available for real stock
consistency: `FBKF_nom / FBKF_real` for BCCh 1960–2024; chained ClioLab ratio for 1940–1959.

**Additional variables for Chile (supplementary):**

| Variable | Symbol | Source | Notes |
|---|---|---|---|
| Real GDP | $Y_t^{CL}$ | CEPAL; Central Bank of Chile | |
| Gross investment flows | $I_t^{CL}$ | CEPAL national accounts | Stock-flow consistent with K-Stock repo |
| Gross operating surplus | $\Pi_t^{CL}$ | CEPAL national accounts | |
| Wage share / profit share | $\pi_t^{CL}$ | Alarco Tosoni (2014); Astorga (2023) | Spliced series |
| Employment | $L_t^{CL}$ | CEPAL; Díaz et al. (2016) | Spliced; for $a_t^{CL}$, $q_t^{CL}$ |
| Terms of trade | $\text{ToT}_t$ | CEPAL | Stage A.2 BoP proxy if Approach 1 needed |

**Sample available:** Capital stock: 1900–2024 (BCCh bundle). GDP/income: ~1940–2024.
Primary estimation: 1945–1978.

### §2.4.3 Sample and Periodization Notes

| Stage | Sample used |
|---|---|
| Stage A.1 — MPF estimation (US) | Full BEA/FRED sample (~1929–2024) |
| Stage A.2 — MPF estimation (Chile) | Full K-Stock-Harmonization sample (~1900–2024; effective ~1940–2024) |
| Stage B — Weisskopf profitability analysis | 1945–1978 (primary); rolling windows for robustness |
| Stage C — ARDL investment function | 1945–1978 (primary); rolling windows for robustness |

Sub-period turning points identified endogenously from wage-share dynamics (Shaikh 2016,
invariance principle). No mechanically imposed periodization.

**Chile 1973–1975:** Coup and economic collapse produce extreme values in $q_t^{CL}$,
$a_t^{CL}$. MPF estimated excluding 1973–1975; sensitivity reported with and without.

---

## §2.5 Stage A: MPF Cost-Minimization and Structural Identification of Capacity Utilization

**Source:** Cajas-Guijarro (2024); `reproduction_function.md`; `capital_accumulation_dynamics_v5.md` §§1–8.

### §2.5.1 The Structural Problem with Standard CU Estimates

HP-filter and peak-output methods impose $\theta(\Lambda) = 1$ by construction — balanced
growth is assumed, productive capacity grows at the same rate as the capital stock. This
suppresses regime-dependent content: it conflates the demand channel ($\mu$) with the
technology channel ($b$) in the Weisskopf decomposition, and prevents identification of
over- vs. under-mechanization regimes ($\theta \neq 1$). Hamilton (2018) provides additional
grounds: HP-filtered series generate spurious low-frequency cycles and are sensitive to
endpoint behavior.

**The stationarity imposition problem:** A single-equation approach — estimating
$\hat{\alpha}_1$ from the condition that $y_t - (\alpha_1 + \pi_t)k_t/2$ is $I(0)$ —
imposes stationarity on CU by construction. If capacity utilization is genuinely $I(1)$,
this produces a spurious cointegrating vector and a contaminated $\hat{\mu}_t$ series.
The identification should be empirical, not imposed.

**The fix — over-identified system with the distributionally-dependent elasticity in the state vector:**

The distribution-conditioned transformation elasticity $\hat{\theta}_t = \theta_1 + \theta_2\pi_t$
requires $\pi_t k_t$ to remain in the state vector as a primitive. Without it, $\hat{\theta}$
collapses to a fixed parameter and the identification of a distributionally-dependent
productive capacity is lost. The $\pi_t k_t$ interaction is not a linearization convenience
— it is what confines distributional variation through the structural channels of the system.

**Augmented state vector:** $(y_t,\; k_t,\; \pi_t,\; (\pi k)_t)$ — four variables,
all potentially $I(1)$.

**CV1 — General distribution-conditioned confinement:**
$$y_t - \theta_1 k_t - \theta_2(\pi_t k_t) = \hat{\mu}_t
\quad \Leftrightarrow \quad [1,\; -\theta_1,\; 0,\; -\theta_2]\cdot\mathbf{X}_t = \hat{\mu}_t$$

The residual $\hat{\mu}_t$ is the capacity utilization series. $\hat{\theta}_t = \theta_1 + \theta_2\pi_t$
is distribution-dependent at every date.

**CV2 — Phillips curve (from Ch1):**
$$\pi_t = \varrho(y_t - \theta_1 k_t - \theta_2\pi_t k_t)
\quad \Leftrightarrow \quad [-\varrho,\; \varrho\theta_1,\; 1,\; \varrho\theta_2]\cdot\mathbf{X}_t = 0$$

Distributional variation is confined through this structural channel: the same $\theta_1$,
$\theta_2$ that define CU in CV1 govern the equilibrium distribution-CU link in CV2.
Cross-equation restriction: $\pi_t$ cannot vary freely — it is anchored by the structural
relationship between distribution and utilization.

**CV3 — Cambridge-Goodwin profitability:**
$$[-2,\; (2+\theta_1),\; -1,\; \theta_2]\cdot\mathbf{X}_t = -\delta$$

A third structural channel confining distributional variation. The same $\theta_1$, $\theta_2$
appear — over-identification from a shared distributional object across three equations.

**What the over-identification provides:**

Parameters $\{\theta_1, \theta_2, \varrho, \delta\}$ are shared across three equations.
This allows:
- Efficient estimation of $\theta_1$, $\theta_2$ from three cross-equation restrictions
- Multiple testable hypotheses: $H_0: \theta_2 = 1/2$ (Cajas-Guijarro quadratic MPF),
  CV2 slope $\varrho$, CV3 depreciation $\delta$ — all within the same system
- Rank determination without imposing stationarity on $\hat{\mu}_t$
- Structural confinement of distributional variation through CV2 and CV3

**Rank determination on $(y, k, \pi, \pi k)$:**

Johansen trace and max-eigenvalue tests on the 4-variable system:

| Rank $r$ | Common trends | Implication |
|---|---|---|
| $r = 1$ | 3 common trends | Single cointegrating relation; CU may be $I(1)$ |
| $r = 2$ | 2 common trends | Two structural relations hold in the long run |
| $r = 3$ | 1 common trend | All three structural relations; consistent with CV1–CV3 |
| $r = 4$ | 0 common trends | All variables $I(0)$ |

Rank is empirical, not imposed.

**The long-run projection of $\hat{\pi}_t^{LR}$ (for §2.5.3):**

Within the 4-variable VECM, the long-run projection of $\pi_t$ onto the cointegrating
manifold is the fitted value from the system — the component of $\pi_t$ consistent with
the long-run equilibrium across CV1, CV2, CV3. This projection is endogenous to the
system, not extracted by a separate lower-dimensional decomposition. The interaction
$(\pi k)_t$ in the state vector is what makes this projection distribution-consistent.

**Gonzalo-Granger decomposition — scope note:**

The GG decomposition of the 4-variable system can provide a diagnostic decomposition of
permanent vs. transitory components for $\hat{\mu}_t$, and may be used as a robustness
check. It is not the primary identification mechanism. GG on a lower-dimensional system
$(y, k, \pi)$ without $\pi k$ is not used — abstracting from the interaction term loses
the distributional dependence of $\hat{\theta}_t$.

**Two estimation routes:**

**Route 1 — Direct MPF (employment required, US primary):**
Estimate $a_t = \alpha_1 q_t + \alpha_2 q_t^2$. Identifies $\alpha_1$, $\alpha_2$, $q^*_t$.
Test $\theta_2 = 1/2$ against the 4-variable system.

**Route 2 — 4-variable restricted VECM (no employment, Chile primary):**
Estimate CV1–CV3 simultaneously on $(y, k, \pi, \pi k)$ with $\theta_1$, $\theta_2$,
$\varrho$, $\delta$ constrained equal across equations. Recovers $\hat{\theta}_t$,
$\hat{\mu}_t$, $\hat{b}_t$ without employment. Rank tested, not imposed.

| Country | Primary route | Rationale |
|---|---|---|
| US (Stage A.1) | Route 1 + 4-var validation | BLS employment; full MPF; $\theta_2 = 1/2$ tested within system |
| Chile (Stage A.2) | Route 2 (4-var restricted VECM) | No employment splicing; distributional dependence preserved; over-identification |

### §2.5.2 Stage A.1 — Center: MPF Cost-Minimization Problem

**Notation update (locks here):** $q \equiv \dot{M}/M$ where $M = K/L$ is the mechanization
ratio — $q$ is the rate of growth of mechanization throughout this chapter and downstream.
$M$ is reserved for imports (levels); $m$ is reserved for import share/propensity (BoP
channel). This supersedes the prior standing convention ($m$ for mechanization growth) and
must be propagated through `reproduction_function.md`, `capital_accumulation_dynamics_v5.md`,
and `natural_rate_under_mechanization.md` in a consolidation pass.

**The mechanization possibility frontier (MPF):**

$$a = \alpha_1 q + \alpha_2 q^2$$

where $a$ is the rate of growth of labour productivity and $q$ is the rate of growth of
mechanization $K/L$. The quadratic form captures standard diminishing returns on the MPF
($\alpha_2 < 0$). The FMT restriction: the MPF passes through the origin — no mechanization,
no productivity gain — consistent with $F(0|\Lambda) = 0$ from `reproduction_function.md`.

**The cost-minimization problem (Cajas-Guijarro 2024):**

$$\min_{q}\; c = a - q\pi$$

subject to $a = \alpha_1 q + \alpha_2 q^2$

where $\pi$ is the profit share representing the distributional cost of mechanization per
unit of mechanization. Substituting the constraint:

$$c = \alpha_1 q + \alpha_2 q^2 - q\pi = q(\alpha_1 - \pi) + \alpha_2 q^2$$

**First-order condition:**

$$\frac{\partial c}{\partial q} = \alpha_1 - \pi + 2\alpha_2 q = 0 \implies
\boxed{q^* = \frac{\pi - \alpha_1}{2\alpha_2}}$$

The optimal mechanization rate is increasing in the profit share ($\partial q^*/\partial\pi > 0$
since $\alpha_2 < 0$): higher profit share induces more mechanization. The SOC for a
well-behaved optimum: $\partial^2 c/\partial q^2 = 2\alpha_2 < 0$ — requires $\alpha_2 < 0$
(diminishing returns), consistent with the standard MPF assumption.

### §2.5.3 First-Stage $\hat{\theta}$ Identification via Long-Run Projection

**The identification problem:**

The cost-minimizing FOC $q^* = (\pi - \alpha_1)/(2\alpha_2)$ and the resulting
$\hat{\theta}_t = \alpha_1 + \alpha_2 q^* = (\alpha_1 + \pi)/2$ both use $\pi$ as the
relevant profit share. But which $\pi$? The technique choice is a *long-run* decision —
capitalists respond to the structural (equilibrium) distribution when choosing
mechanization, not to transitory business cycle fluctuations. Using raw $\pi_t$ to
construct $\hat{\theta}_t$ would allow short-run distributional noise to contaminate
the identification of productive capacity $Y_t^p = B_0 K_t^{\hat{\theta}}$, displacing
variation that belongs in $\hat{\mu}_t$ into $\hat{\theta}_t$.

**The cost-minimizing consistent identification requires:**

$$\hat{\theta}_t^{(1)} = \theta_1 + \theta_2\,\hat{\pi}_t^{LR}$$

where $\hat{\pi}_t^{LR}$ is the **projection of $\pi_t$ onto the long-run manifold** —
the component of the profit share consistent with the equilibrium distribution-CU
relationship, purged of short-run error correction deviations.

**Deriving $\hat{\pi}_t^{LR}$ from the cointegrating system:**

From CV1 and CV2 jointly on the long-run manifold, eliminate $\hat{\mu}_t^{LR}$:

CV1 (long-run): $\hat{\mu}_t^{LR} = y_t^{LR} - (\beta_1 + \beta_2\pi_t^{LR})k_t^{LR}$

CV2 (long-run): $\pi_t^{LR} = \varrho\hat{\mu}_t^{LR}$

Substituting CV1 into CV2 and solving:

$$\boxed{\hat{\pi}_t^{LR} = \frac{\varrho(y_t^{LR} - \beta_1 k_t^{LR})}{1 + \varrho\beta_2 k_t^{LR}}}$$

where $(y_t^{LR}, k_t^{LR})$ are the **Gonzalo-Granger permanent components** of the
state vector from the estimated VECM — the common trend projections that represent the
long-run information in $(y, k)$.

**The two-step identification procedure:**

*Step 1:* Estimate the restricted VECM on $(y, k, \pi, \pi k)$ — the 4-variable system
with CV1–CV3 constrained to share $\theta_1$, $\theta_2$. From the VECM fitted values,
extract the long-run projection of $\pi_t$:

$$\hat{\pi}_t^{LR} = \frac{\varrho(y_t^{LR} - \theta_1 k_t^{LR})}{1 + \varrho\theta_2 k_t^{LR}}$$

derived by eliminating $\hat{\mu}_t^{LR}$ across CV1 and CV2 on the long-run manifold,
where $(y_t^{LR}, k_t^{LR})$ are the VECM's long-run fitted components. This projection
is endogenous to the 4-variable system — the interaction $(\pi k)_t$ in the state vector
is what makes it distribution-consistent.

*Step 2:* Construct $\hat{\theta}_t^{(1)}$ from the projected profit share:
$$\hat{\theta}_t^{(1)} = \theta_1 + \theta_2\,\hat{\pi}_t^{LR}$$

Impose over the **full sample** to identify:
$$\hat{\mu}_t = y_t - \hat{\theta}_t^{(1)} k_t$$

**Scope note — Gonzalo-Granger:** The GG decomposition of the 4-variable system can
serve as a robustness diagnostic, decomposing $\hat{\mu}_t$ into permanent and transitory
components. GG on a lower-dimensional system $(y, k, \pi)$ without $(\pi k)$ is not used
as a primary step — abstracting from the interaction loses the distributional dependence
of $\hat{\theta}_t$.

**Capital productivity at normal capacity:**

$$\hat{b}_t = (\hat{\theta}_t^{(1)} - 1)k_t \qquad \Rightarrow \qquad
\hat{B}_t = \exp(\hat{\theta}_t^{(1)} k_t)/K_t$$

Both $\hat{\mu}_t$ and $\hat{b}_t$ feed Stage B and Stage C using the same
$\hat{\theta}_t^{(1)}$. The projection constraint propagates through the full empirical
pipeline.

### §2.5.4 Stage A.2 — Periphery: Capital Composition and BoP-Constrained Cost-Minimization

**The structural distinction from Stage A.1:** In the center, the capital stock is treated
as homogeneous for the MPF. In peripheral capitalism, the composition of capital between
Non-Residential Infrastructure ($K^{NR}$) and Machinery and Equipment ($K^{ME}$) is
critical because ME is structurally dependent on imports. The capital goods sector is
incomplete — the periphery cannot produce ME domestically at scale — so mechanization
through ME requires foreign exchange. The BoP constraint enters the cost-minimization
problem through the import content of ME investment.

**Capital decomposition:**

$$K^{CL} = K^{NR} + K^{ME}$$

$$s_t^{ME} \equiv \frac{K_t^{ME}}{K_t^{CL}} \quad \text{(ME share in total capital stock, time-varying)}$$

Total mechanization growth: $q = k^{CL} - l^{CL}$, decomposable as:

$$q = (1 - s^{ME})\,q^{NR} + s^{ME}\,q^{ME}$$

**The peripheral MPF:**

Allow differential productivity effects by capital type. Define the composition-weighted
MPF slope:

$$\bar{\alpha}_1^{CL} \equiv \alpha_1^{NR}(1 - s_t^{ME}) + \alpha_1^{ME} s_t^{ME}$$

The peripheral MPF is:

$$a = \bar{\alpha}_1^{CL}\, q + \alpha_2\, q^2$$

Same functional form as Stage A.1 but with a composition-dependent slope. If
$\alpha_1^{ME} > \alpha_1^{NR}$ (capital-embodied technical change in machinery exceeds
infrastructure), higher $s^{ME}$ raises productivity potential — but at the cost of
more ME imports and greater BoP exposure. This is the **Kaldor-ECLA fault line**: does
the external BoP ceiling (limiting $q^{ME}$) or the internal consumption drain (limiting
$\pi$) bind first?

**The peripheral cost-minimization problem:**

The BoP constraint enters the cost function as an additional external cost per unit of
mechanization:

$$\min_q\; c = a - q\pi + \lambda\cdot s^{ME}\cdot\xi^{ME}_K\cdot q$$

subject to $a = \bar{\alpha}_1^{CL}\, q + \alpha_2\, q^2$

where:
- $\xi^{ME}_K \approx 0.92$–$0.94$ = import content of ME investment (Kaldor 1959 prior;
  `empirical_strategy_peripheral_Ch2_v3.md`)
- $s^{ME}$ = ME share in capital stock (observable from Hofman 2000 if disaggregated)
- $\lambda$ = shadow cost of foreign exchange — the intensity of the BoP constraint
- $\lambda s^{ME}\xi^{ME}_K q$ = total external cost of mechanizing at rate $q$:
  the BoP price the periphery pays for accumulation that the center does not face

Substituting the constraint and taking the FOC:

$$\frac{\partial c}{\partial q} = \bar{\alpha}_1^{CL} + 2\alpha_2 q - \pi + \lambda s^{ME}\xi^{ME}_K = 0$$

$$\boxed{q^{CL*} = \frac{\pi - \lambda s^{ME}\xi^{ME}_K - \bar{\alpha}_1^{CL}}{2\alpha_2}}$$

**Center-periphery mechanization gap:**

| | Center (Stage A.1) | Periphery (Stage A.2) |
|---|---|---|
| Capital structure | Homogeneous $K$ | $K^{NR} + K^{ME}$ ($\xi^{ME}_K \approx 0.92$–$0.94$) |
| Cost function | $c = a - q\pi$ | $c = a - q\pi + \lambda s^{ME}\xi^{ME}_K q$ |
| FOC | $q^* = (\pi - \alpha_1)/(2\alpha_2)$ | $q^{CL*} = (\pi - \lambda s^{ME}\xi^{ME}_K - \bar{\alpha}_1^{CL})/(2\alpha_2)$ |
| BoP penalty | None | $\lambda s^{ME}\xi^{ME}_K > 0$ |

The BoP cost term acts as an effective *reduction* in the profit share available to induce
mechanization. For a given $\pi$, the periphery mechanizes at a lower rate than the center
by exactly $\lambda s^{ME}\xi^{ME}_K / (2|\alpha_2|)$. This is the structural source of the
center-periphery mechanization gap — derived from the cost-minimization problem, not imposed.

### §2.5.5 Stage A.2 — Recovering $\hat{\theta}_t^{CL}$ and $\hat{\mu}_t^{CL}$ (Periphery)

**The same two-step procedure as §2.5.3, extended for the peripheral cost-minimization.**

**Peripheral long-run projected profit share:**

From the peripheral FOC, the BoP penalty reduces the effective equilibrium profit share:

$$\hat{\pi}_t^{CL,LR} = \hat{\pi}_t^{LR} - \lambda s_t^{ME}\xi^{ME}_K$$

where $\hat{\pi}_t^{LR}$ is the Gonzalo-Granger permanent component of $\pi_t^{CL}$ from
the estimated VECM on $(y^{CL}, k^{CL}, \pi^{CL}, (\pi k)^{CL})$, and the BoP penalty
$\lambda s_t^{ME}\xi^{ME}_K$ is estimated from the capital composition augmentation of CV1
using K-Stock-Harmonization data (§2.5.4).

**Peripheral transformation elasticity (first stage):**

$$\hat{\theta}_t^{CL,(1)} = \bar{\alpha}_1^{CL} + \beta_2^{CL}\hat{\pi}_t^{CL,LR}
= \frac{\bar{\alpha}_1^{CL} + \hat{\pi}_t^{LR} - \lambda s_t^{ME}\xi^{ME}_K}{2}$$

under the Cajas-Guijarro restriction $\beta_2 = 1/2$.

**The center-periphery gap in $\hat{\theta}$:**

$$\hat{\theta}_t^{US,(1)} - \hat{\theta}_t^{CL,(1)} = \frac{(\alpha_1^{US} - \bar{\alpha}_1^{CL}) + \lambda s_t^{ME}\xi^{ME}_K}{2}$$

Two components: (i) MPF slope gap (structural technology difference); (ii) BoP penalty
(external constraint reducing the effective equilibrium distribution available for
mechanization).

**CU recovery imposed over full sample:**

$$\hat{\mu}_t^{CL} = \exp\!\left(y_t^{CL} - \hat{\theta}_t^{CL,(1)} k_t^{CL}\right)$$

Transitory distributional fluctuations ($\pi_t^{CL} - \hat{\pi}_t^{CL,LR}$) enter
$\hat{\mu}_t^{CL}$ — where they belong as demand-side variation — rather than
contaminating $\hat{\theta}_t^{CL,(1)}$.

**The $\lambda$ identification:**

The BoP shadow cost $\lambda$ is identified from the augmentation of CV1 with
$s_t^{ME} k_t^{CL}$ from K-Stock-Harmonization (Approach 3 available — capital type
data confirmed). $\hat{\lambda}$ is the coefficient on $s_t^{ME} k_t^{CL}$ in the
augmented cointegrating vector, with $\xi^{ME}_K \approx 0.92$–$0.94$ imposed as the
Kaldor prior.

### §2.5.6 Sample Scope

Stage A is estimated over the **full available sample** for each country — not restricted
to the 1945–1978 Fordist window. This serves two purposes: (i) the MPF parameters
$\alpha_1$, $\alpha_2$ are more precisely estimated over a longer horizon; (ii) the
$\hat{\mu}_t$ series produced will support robustness checks in Stages B and C that
extend beyond the primary Fordist window.

The Fordist restriction (1945–1978) applies only to Stage B (profitability decomposition)
and Stage C (ARDL investment function). Stage A CU estimates are available over the full
sample for both countries and can be used in downstream work.

| Stage | Sample used |
|---|---|
| Stage A — MPF estimation and CU recovery | Full available sample (country-specific) |
| Stage B — Weisskopf profitability analysis | 1945–1978 (primary); rolling windows for robustness |
| Stage C — ARDL investment function | 1945–1978 (primary); rolling windows for robustness |

### §2.5.7 Estimation Procedure: United States (Stage A.1 — Route 1 + System Validation)

**Primary: Route 1 — Direct MPF estimation.** Employment from BLS/FRED.

Data: $a_t = y_t - l_t$ (labour productivity growth); $q_t = k_t - l_t$ (mechanization
growth). Available ~1929–2024.

**Step 1 — MPF estimation:**

$$a_t = \alpha_1 q_t + \alpha_2 q_t^2 + \varepsilon_t$$

No constant (FMT restriction). OLS. Structural break tests (Chow / CUSUM). Test
$H_0: \alpha_2 = 0$; SOC test $\hat{\alpha}_2 < 0$.

**Step 2 — Recover $q^*_t$, $\hat{\theta}_t^{US}$, $\hat{\mu}_t^{US}$:**

$$q^*_t = \frac{\pi_t - \hat{\alpha}_1}{2\hat{\alpha}_2} \qquad
\hat{\theta}_t^{US} = \frac{\hat{\alpha}_1 + \pi_t}{2} \qquad
\hat{\mu}_t^{US} = \exp\!\left(y_t - \hat{\theta}_t^{US} k_t\right)$$

**Step 3 — System validation (Route 2):** Estimate the restricted VECM on
$(y_t^{US}, k_t^{US}, \pi_t^{US}, (\pi k)_t^{US})$ with $\beta_1$, $\beta_2$ constrained
across CV1–CV3. Rank test (Johansen). Check consistency of $\hat{\beta}_1$, $\hat{\beta}_2$
from the system vs. Route 1 ($\hat{\alpha}_1$, implied $\beta_2 = 1/2$). Test
$H_0: \beta_2 = 1/2$ within CV1 — structural validation of the quadratic MPF.

### §2.5.8 Estimation Procedure: Chile (Stage A.2 — Route 2 Primary)

**Route 2 — Three-equation restricted VECM on $(y^{CL}, k^{CL}, \pi^{CL})$.
No employment required.**

**Step 1 — Rank determination on $(y^{CL}, k^{CL}, \pi^{CL}, (\pi k)^{CL})$:**

Johansen trace and max-eigenvalue tests on the 4-variable system. CU not assumed
stationary — rank is empirical. The $(\pi k)^{CL}$ term must remain as a primitive
state variable to preserve the distributional dependence of $\hat{\theta}_t^{CL}$.

**Step 2 — Restricted VECM with $\theta_1$, $\theta_2$, $\varrho$, $\delta$ constrained across CV1–CV3:**

- **CV1:** $[1,\; -\theta_1,\; 0,\; -\theta_2] \cdot \mathbf{X}_t^{CL} = \hat{\mu}^{CL}$
- **CV2:** $[-\varrho,\; \varrho\theta_1,\; 1,\; \varrho\theta_2] \cdot \mathbf{X}_t^{CL} = 0$
- **CV3:** $[-2,\; (2+\theta_1),\; -1,\; \theta_2] \cdot \mathbf{X}_t^{CL} = -\delta$

Distributional variation is confined through CV2 (Phillips curve) and CV3
(Cambridge-Goodwin) — the same structural channels that constrain how $\pi_t^{CL}$
can vary in the long run. Over-identifying restrictions testable.
$\hat{\theta}_t^{CL} = \theta_1 + \theta_2\pi_t^{CL}$ — distribution-dependent.

**Step 3 — Capital composition augmentation (Stage A.2):**

Augment CV1 with $s_t^{ME} k_t^{CL}$ from K-Stock-Harmonization to recover the peripheral
$\hat{\theta}_t^{CL}$ with BoP penalty (§2.5.4–§2.5.5). Separately identifies
$\bar{\alpha}_1^{CL}$ and $\hat{\lambda}\xi^{ME}_K$.

**Step 4 — Recover $\hat{\theta}_t^{CL}$, $\hat{\mu}_t^{CL}$, $\hat{b}_t^{CL}$:**

$$\hat{\theta}_t^{CL} = \frac{\bar{\alpha}_1^{CL} + \pi_t^{CL} - \hat{\lambda}\xi^{ME}_K s_t^{ME}}{2}
\qquad \hat{\mu}_t^{CL} = \exp(y_t^{CL} - \hat{\theta}_t^{CL} k_t^{CL})$$

**Step 5 — Diagnostics:**
- Over-identification test: consistency of $\hat{\theta}^*$ across CV1, CV2, CV3
- Economic plausibility: $\hat{\mu}_t^{CL}$ falls 1974–1975 and 1982–1983; rises 1960–1971
- $\hat{\theta}_t^{US}$ vs. $\hat{\theta}_t^{CL}$: decompose gap into MPF-slope and BoP-penalty
- 1973–1975 structural break on the VECM

**Route 1 robustness (if employment confirmed):** Run direct MPF estimation to recover
$\hat{\alpha}_2^{CL}$ and $q^{CL*}_t$; cross-check $\hat{\theta}^*$ against system.

**Stage A outputs — both countries:**

| Output | US (Stage A.1, Route 1) | Chile (Stage A.2, Route 2) | Used in |
|---|---|---|---|
| $\hat{\theta}_t$ | $(\hat{\alpha}_1 + \pi_t)/2$ | $(\bar{\alpha}_1^{CL} + \pi_t - \hat{\lambda}\xi^{ME}_K s_t^{ME})/2$ | Structural comparison |
| $\hat{\mu}_t$ | $\exp(y_t - \hat{\theta}_t k_t)$ | $\exp(y_t^{CL} - \hat{\theta}_t^{CL} k_t^{CL})$ | Stage B, Stage C |
| $\hat{b}_t$ | $(\hat{\theta}_t - 1)k_t$ | $(\hat{\theta}_t^{CL}-1)k_t^{CL}$ | Stage B, Stage C |
| $q^*_t$ | $(\pi_t - \hat{\alpha}_1)/(2\hat{\alpha}_2)$ | Route 1 robustness only | Interpretation |

---

## §2.6 Stage B: Profitability Analysis

**Prospectus base:** §3.4.2.

**The contribution:** Uses Stage A $\hat{\mu}_t$ and $\hat{B}_t$ rather than HP-filter or
peak-output estimates. The Weisskopf decomposition therefore does not suppress the
regime-dependent content of the accumulation regime. This is what makes the profitability
analysis new relative to Weisskopf (1979), Basu and Manolakos (2012), and Basu and
Vasudevan (2013).

### §2.6.1 Methodology

Profit rate with Stage A estimates:
$$r = \hat{\mu} \cdot \hat{b} \cdot \pi$$

Growth rate contributions by sub-period:
$$\frac{\dot{r}}{r} = \frac{\dot{\hat{\mu}}}{\hat{\mu}} + \frac{\dot{\hat{b}}}{\hat{b}}
+ \frac{\dot{\pi}}{\pi}$$

Accumulate contributions. Sub-period turning points identified endogenously from wage-share
dynamics — consistent with the invariance principle of the new interpretation (Shaikh 2016):
the correspondence of labour values and prices holds at the aggregate when class struggle is
exogenous to the system. No mechanically imposed periodization.

Where data availability permits: real and price components of each channel.

### §2.6.2 United States: Sub-Period Decomposition (1945–1978)

Cumulative contribution chart. Sub-period narrative: Fordist expansion → late Fordist squeeze
→ structural crisis onset. Global conjuncture context (Vietnam War military-Keynesianism;
oil shocks). Relational discussion with the Chile case.

### §2.6.3 Chile: Sub-Period Decomposition (1945–1978)

Same methodology. Key structural contrast: the ISI model's $\hat{b}_t^{CL}$ is externally
conditioned by capital goods import dependency in a way the US is not. $\hat{\mu}_t^{CL}$
shows a structurally different upward-downward profile — BoP constraint enters the demand
channel. Turning points linked to political conjunctures (Unidad Popular; coup).

**Sources:** Weisskopf (1979); Basu and Manolakos (2012); Basu and Vasudevan (2013);
Foley (1982); Blecker and Setterfield (2019).

---

## §2.7 Stage C: Investment Function Estimation

**Spine:** Two-layer accounting-behavioral identification (§2.3.2–§2.3.3).
The empirical strategy follows directly from the two layers: Layer 1 says enter the three
channels of $r = \mu b \pi$ separately by default; Layer 2 provides the behavioral
interpretation of the resulting coefficients. The FM spec is therefore the primary
estimating equation. KR and BM are economically motivated compressions whose empirical
warrant is tested via Wald restrictions within the FM framework — not sequential steps
in an ascending-complexity ladder.

### §2.7.1 ARDL Estimation Architecture

**Method:** ARDL bounds testing (Pesaran, Shin and Smith 2001).

Cointegration in the FM spec is structurally guaranteed: the accounting identity
$g_K = \chi\pi\mu b$ must hold in the long run. If components wander, $g_K$ wanders
with them — the bounds test confirms this empirically; the identity explains why.

All models estimated for both $\kappa_t$ and $a_t = \chi_t$ as dependent variable.
Lag selection: AIC/BIC, maximum lag = 4. Parameter stability: CUSUM, CUSUM-sq.

The prospectus hypothesis — $a_t$ is more sensitive to profitability in the short run
than $\kappa_t$ — is tested from the short-run adjustment coefficients of the FM spec.

### §2.7.2 Primary Model: Full Weisskopf Disaggregation (FM Spec)

Motivated by Layer 1: three distinct channels exist and should be entered separately.
Motivated by Layer 2: the coefficients have a behavioral interpretation as recapitalization
elasticities relative to the Cambridge accounting benchmark.

$$y_t = \psi_0 + \psi_1 \hat{b}_t + \psi_2\pi_t + \psi_3\hat{\mu}_t + \eta_t$$

$\hat{b}_t$ and $\hat{\mu}_t$ are Stage A outputs — the clean channel separation that
Stage A produces is precisely what makes this specification identified. Using HP-filter
$\mu$ would conflate the demand and technology channels, invalidating the Okishio test.

**Layer-2 coefficient interpretation:**

| Coeff. | Accounting benchmark | Behavioral reading |
|---|---|---|
| $\psi_1$ | $\beta_3 = 1$: $\chi$ inert to capital productivity | $\eta_3 = \psi_1 - 1$: recapitalization response to structural conditions |
| $\psi_2$ | $\beta_1 = 1$: $\chi$ inert to distribution | $\eta_1 = \psi_2 - 1$: recapitalization response to profit share |
| $\psi_3$ | $\beta_2 = 1$: $\chi$ inert to demand/CU | $\eta_2 = \psi_3 - 1$: recapitalization response to utilization |

**Okishio crisis-trigger test (primary hypothesis):**

$$H_0: \psi_1 = \psi_3 \quad (\Leftrightarrow\; \beta_2 = \beta_3 \text{ in Layer-2 notation})$$

Under $H_0$: CU and capital productivity enter $\chi$'s response identically — no
independent crisis-trigger effect. Rejection: the path of $\hat{\mu}_t$ has an independent
recapitalization effect that cannot be reduced to the profit rate.

**Two readings of rejection (§2.2.4):**
- *Macro (Okishio):* CU is an independent signal at the aggregate — cumulative disequilibrium fires the trigger
- *Firm level:* $\psi_3$ is regime-specific — contingent on the Fordist institutional anchor that
  temporarily suppressed within-firm multi-scalar contradiction. CUSUM instability of $\psi_3$
  across sub-periods confirms this reading

### §2.7.3 The Shaikh Net-Profitability Test

Applied to the FM spec first, then carried through to compressions. Adds the interest rate
as a separate regressor to the FM baseline:

$$y_t = \psi_0 + \psi_1\hat{b}_t + \psi_2\pi_t + \psi_3\hat{\mu}_t + \psi_4 i_t + \eta_t$$

**Wald test:** $H_0: \psi_2^{\pi} = -\psi_4^i$ in a condensed profit-share-plus-rate form.

**Decision rule:** If not rejected, the profit share and interest rate can be netted. This
determines whether the compression tests (§2.7.4–§2.7.5) run on gross or net profitability.

The compressed Keynes-Robinson-Shaikh form — if the Wald is not rejected — is:
$$y_t = \beta_0 + \beta_1(r_t - i_t) + \varepsilon_t$$

### §2.7.4 Compression Test 1: Bhaduri-Marglin

Tests whether the technology and demand channels of FM can be compressed. BM enters
$\rho = \mu b$ (output-capital ratio at effective demand) and $\pi$ separately:

$$y_t = \gamma_0 + \gamma_1\rho_t + \gamma_2\pi_t + \eta_t$$

**Wald restriction tested within FM:** $H_0: \psi_1 = \psi_3$ (technology and demand respond
to $\chi$ identically — compressible into $\rho$). This is the *same null* as the Okishio
test: if the Okishio null is not rejected, the BM compression is warranted on the
demand-technology dimension.

**Behavioral content of BM (Layer 2):** Entering $\rho = \mu b$ suppresses $\beta_3$ (the
technology channel is set to Cambridge closure) while letting $\beta_2$ (demand/distribution
separation) be free. BM tests profit-led vs. wage-led investment regime at the cost of
losing the CU-productivity distinction.

**Estimated directly** for comparison with FM, not only as a within-FM restriction.

### §2.7.5 Compression Test 2: Keynes-Robinson

Tests whether all three channels can be compressed into $r$. KR enters only the profit rate:

$$y_t = \alpha_0 + \alpha_1 r_t + \varepsilon_t$$

**Wald restriction tested within FM:** Joint $H_0: \psi_1 = \psi_2 = \psi_3$ (all three
channels respond identically — compressible into $r$). Also tests $\alpha_0$ stability
across sub-periods as a proxy for Keynes's animal spirits.

**Estimated directly** as the limiting compression benchmark.

### §2.7.6 Wald Test Sequence

The sequence runs from the primary model outward to compressions — not from simple
to complex, but from the accounting-grounded baseline to tested restrictions:

| Test | Null | What it determines |
|---|---|---|
| 1. Shaikh (within FM) | Net profitability restriction | Whether gross or net $r$ used in compressions |
| 2. Okishio (within FM) | $\psi_1 = \psi_3$ | Is CU a crisis trigger? Is BM compression warranted? |
| 3. BM restriction | Technology-demand compressible into $\rho$ | BM vs. FM |
| 4. KR restriction | All channels compressible into $r$ | KR vs. FM |

**Reading the sequence:** Tests 2 and 3 are linked — the Okishio null and the BM
compression restriction are the same hypothesis. Rejecting the Okishio null rejects
both BM and KR compression. The FM spec stands as the supported model.

---

## §2.8 Results

### §2.8.1 United States (1945–1978)

**Stage A:**
- $\hat{\alpha}_1$, $\hat{\alpha}_2$ from MPF estimation; SOC test ($\hat{\alpha}_2 < 0$)
- $q^*_t = (\pi_t - \hat{\alpha}_1)/(2\hat{\alpha}_2)$: optimal mechanization path
- $\hat{\theta}_t^{US} = (\hat{\alpha}_1 + \pi_t)/2$: distribution-conditioned transformation
  elasticity with structural break dates
- $\hat{\mu}_t^{US}$ and $\hat{b}_t^{US}$; stationarity test; comparison against HP-filter
  benchmark to demonstrate the measurement stakes

**Stage B:**
- Cumulative contribution chart by sub-period ($\dot{\hat{\mu}}/\hat{\mu}$, $\dot{\hat{b}}/\hat{b}$,
  $\dot{\pi}/\pi$)
- Dominant stagnation tendency per sub-period; mapping onto the typology of §2.3.1
- Historical narrative: which stagnation tendencies offset, which reinforce toward structural crisis

**Stage C:**
- **Primary model (FM):** long-run coefficients $\psi_1$, $\psi_2$, $\psi_3$ with Layer-2
  interpretation ($\eta_j = \psi_j - 1$); bounds test; ECM speed of adjustment; short-run
  dynamics — for both $\kappa_t$ and $a_t$
- Okishio Wald ($\psi_1 = \psi_3$): crisis-trigger verdict; CUSUM stability of $\psi_3$
  across sub-periods
- Shaikh Wald (within FM): gross vs. net profitability determination
- Compression tests: BM restriction ($\rho = \mu b$) and KR restriction (all into $r$)
  — are the compressions warranted given the FM results?
- Comparison of $a_t$ vs. $\kappa_t$ short-run sensitivity

### §2.8.2 Chile (1945–1978)

**Stage A:**
- $\hat{\beta}_1^{CL}$, $\hat{\beta}_2^{CL}$; $\hat{\theta}_t^{CL}$ vs. $\hat{\theta}_t^{US}$
  — first empirical measure of the center-periphery mechanization gap
- $\hat{\mu}_t^{CL}$ and $\hat{b}_t^{CL}$

**Stage B:**
- Same decomposition. Key: BoP-conditioned $\hat{\mu}_t^{CL}$ produces a structurally
  different contribution profile from $\hat{\mu}_t^{US}$
- ISI crisis as a distinct stagnation typology; relational reading with the US through
  the global conjuncture of the late 1960s and early 1970s

**Stage C:**
- Same FM-first structure. Key comparison: $\psi_3^{CL}$ vs. $\psi_3^{US}$
- If $\psi_3^{CL}$ differs significantly: CU enters the peripheral investment decision
  differently — external constraint mediates the recapitalization response to demand conditions

---

## §2.9 Conclusions and Contributions

**Prospectus base:** §3.6.

**Three contributions:**

**1. Novel CU estimates via MPF cost-minimization (Stage A).**
The Cajas-Guijarro (2024) cost-minimization problem — minimize $c = a - m\pi$ subject to
$a = \alpha_1 q + \alpha_2 q^2$ — yields the FOC $q^* = (\pi - \alpha_1)/(2\alpha_2)$
and the analytical result $\hat{\theta}_t = (\hat{\alpha}_1 + \pi_t)/2$. This derives the
distribution-conditioned transformation elasticity from a behavioral optimization over
mechanization rather than recovering it as a reduced-form regression residual. CU is then
recovered as $\hat{\mu}_t = \exp(y_t - \hat{\theta}_t k_t)$. First application of this
method to the Fordist crisis period in a comparative US-Chile framework.

**2. Revisiting Weisskopf (1979) with structurally grounded CU (Stage B).**
Using Stage A estimates rather than HP-filter or peak methods, the profitability decomposition
$r = \hat{\mu}\hat{b}\pi$ provides new insights on the role of aggregate demand in the
Fordist crisis — cleanly separating the demand channel from the technology channel in a way
prior work could not.

**3. Accounting-grounded investment function with Shaikh, Okishio, and firm-level
micro-foundation (Stage C + §2.2.4).**
The gross accumulation identity $g_K = \chi\pi\mu b$ provides a structural foundation for
the ARDL investment function specifications. The four prospectus specs (KR, KRS, BM, FM)
are nested as progressive disaggregations of $r = \mu b \pi$ into its Weisskopf components.
The chapter provides a firm-level micro-foundation for Okishio's crisis-trigger claim:
multi-scalar contradictions within the firm rule out a stable desired CU rate prior to and
independently of between-firm competition, so that aggregate CU instability is doubly
grounded. The Okishio Wald test ($\psi_1 = \psi_3$) within the FM spec tests whether CU
operates as an independent recapitalization signal at the aggregate level; CUSUM instability
of $\psi_3$ across sub-periods tests whether that signal is regime-contingent, consistent
with the firm-level argument. To the best of the author's knowledge this is the first
contribution to ground Okishio's (1961) crisis-trigger notion in a firm-level theory of
CU indeterminacy while simultaneously testing it in a comparative US-Chile ARDL framework
using structurally identified CU regressors.

**Historical reading (Duménil and Lévy 2003; Krätke 2018):** all results discussed in
comparative, historical, and relational perspective — contributions to Marxist political
economy, development studies, and the reemergence of dependency theory (Kvangraven 2021).

---

## Backgrounded Files (Not Discarded — Pull on Explicit Request)

| File | Content | Pull condition |
|---|---|---|
| `empirical_strategy_peripheral_Ch2_v3.md` | Full Chilean CVAR 5-variable state vector (r=3) | If Stage A Chile MPF estimation requires auxiliary structural identification |
| `empirical_strategy_reduced_rank.md` | Reduced rank regression spec | If ARDL bounds test fails for Stage A |
| `vecm_4var.md` | 4-variable VECM | Ch3 scope |
| `two_country_reduced_rank.md` | Two-country reduced rank | Ch3 scope |
| `demand_led_formalization.md` | $\phi$-spec investment share | Robustness check only; import checkpoint active |

---

## Open Items (Stage-Gated Before Estimation)

| Decision | Blocks | Current status |
|---|---|---|
| MPF SOC test: confirm $\hat{\alpha}_2 < 0$ for US (Route 1) | §2.5.7 | Stage-gate for US $q^*_t$; not load-bearing for Stage B/C |
| Cointegrating rank test on $(y, k, \pi, \pi k)$ — 4-variable system | §2.5.7–§2.5.8 | Determines CU integration order; rank not imposed; $\pi k$ must stay in state |
| Test $H_0: \theta_2 = 1/2$ within CV1 (Cajas-Guijarro quadratic MPF restriction) | §2.5.7, §2.5.8 | Over-identification test; resolved at estimation |
| Over-identification: consistency of $\theta_1$, $\theta_2$, $\varrho$, $\delta$ across CV1–CV3 | §2.5.8 | Cross-validates structural system; multiple testable hypotheses |
| Chile employment (CEPAL + Díaz et al.): Route 1 robustness only | §2.5.8 | Not load-bearing; robustness check |
| Whether Shaikh Wald (within FM) determines gross vs. net $r$ for compression tests | §2.7.3 | Sequential; resolved at estimation |
| Preferred dependent variable for headline results ($\kappa_t$ vs. $a_t$) | §2.8 | Open until estimation; both reported |
| **Capital type stage-gate:** ✓ Closed — K-Stock-Harmonization provides $K^{ME}$ and $K^{NR}$ directly | — | ✓ Closed |
| **Notation propagation:** $q$ for mechanization growth must replace $m$ in theory files | All theory files | Standing — consolidation pass required |

**Bib addendum:** Cajas-Guijarro (2024, SCED) must be added to `ch2_references.bib`.
Full citation requires verification (title, volume, pages). Placeholder entry:

```bibtex
@article{CajasGuijarro2024,
  author  = {Cajas-Guijarro, John},
  title   = {[VERIFY FULL TITLE]},
  journal = {Structural Change and Economic Dynamics},
  year    = {2024},
  note    = {Citation key used in text: CajasGuijarro2024. Full citation pending verification.}
}
```

---

*Ch2 Definitive Outline — 2026-04-02. Nine sections (§2.1–§2.9). Local projections moved to Ch3.*
*Next action: freeze in Ops Center; create section-level writing tasks.*
