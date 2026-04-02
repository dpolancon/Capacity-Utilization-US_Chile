# Ch2 Modular Components Index
## Demand-Led Profitability and Structural Crisis of Capitalism in Chile and the United States during the Fordist Era

> **Status:** OUTLINE LOCKED. Section prompts ready.
> **Date rebuilt:** 2026-04-02
> **Governing file:** `Ch2_Outline_DEFINITIVE.md` (§2.1–§2.9, 33 subsections)
> **Prompts file:** `ch2_section_prompts.md` (this session rebuild)
> **Data repos:** `dpolancon/US-BEA-Income-FixedAssets-Dataset` · `dpolancon/K-Stock-Harmonization`

---

## Assembly Logic

```
DRAFTABLE NOW (theory-complete):
  §2.1 Introduction
  §2.2.1–§2.2.5 Literature Review (5 subsections)
  §2.3.1–§2.3.3 Analytical Framework (3 subsections)
  §2.4.1–§2.4.3 Data (3 subsections)
  §2.5.1–§2.5.6 Stage A theory + identification (6 subsections)
  §2.7.1–§2.7.6 Stage C investment function (theory complete; no results)
  §2.9 Conclusions (skeleton with PLACEHOLDER slots)

BLOCKED ON EMPIRICS:
  §2.5.7 Stage A.1 estimation procedure (US results)
  §2.5.8 Stage A.2 estimation procedure (Chile results)
  §2.6.1–§2.6.3 Stage B profitability decomposition (results)
  §2.8.1–§2.8.2 Results (both countries)
```

---

## Module Registry

| Subsection | Title | Status | Blocking condition |
|---|---|---|---|
| §2.1 | Introduction | DRAFTABLE | — |
| §2.2.1 | Crisis as Limit of Capitalist Accumulation | DRAFTABLE | — |
| §2.2.2 | Disproportionality, Class Struggle, Spatial Fixes | DRAFTABLE | — |
| §2.2.3 | Okishio's Crisis Trigger | DRAFTABLE | — |
| §2.2.4 | Multi-Scalar Contradictions Rule Out Stable Desired CU | DRAFTABLE | — |
| §2.2.5 | Synthesis: Multi-Level Theory of the Crisis Trigger | DRAFTABLE | — |
| §2.3.1 | Stagnation and Crisis: A Typology | DRAFTABLE | — |
| §2.3.2 | Layer 1 — The Accounting Foundation | DRAFTABLE | — |
| §2.3.3 | Layer 2 — The Behavioral Identification | DRAFTABLE | — |
| §2.4.1 | United States data | DRAFTABLE | — |
| §2.4.2 | Chile data | DRAFTABLE | — |
| §2.4.3 | Sample and Periodization Notes | DRAFTABLE | — |
| §2.5.1 | Structural Problem + Two Routes + 4-Variable System | DRAFTABLE | — |
| §2.5.2 | Stage A.1 — Center: MPF Cost-Minimization | DRAFTABLE | — |
| §2.5.3 | First-Stage θ̂ via Long-Run Projection | DRAFTABLE | — |
| §2.5.4 | Stage A.2 — Periphery: Capital Composition + BoP | DRAFTABLE | — |
| §2.5.5 | Stage A.2 — Recovering θ̂^CL and μ̂^CL | DRAFTABLE | — |
| §2.5.6 | Sample Scope | DRAFTABLE | — |
| §2.5.7 | Estimation Procedure: United States | PLACEHOLDER | US estimation results |
| §2.5.8 | Estimation Procedure: Chile | PLACEHOLDER | Chile estimation results |
| §2.6.1 | Stage B Methodology | PLACEHOLDER | Stage A outputs |
| §2.6.2 | United States Sub-Period Decomposition | PLACEHOLDER | Stage A outputs |
| §2.6.3 | Chile Sub-Period Decomposition | PLACEHOLDER | Stage A outputs |
| §2.7.1 | ARDL Estimation Architecture | DRAFTABLE | — |
| §2.7.2 | Primary Model: Full Weisskopf Disaggregation (FM) | DRAFTABLE | — |
| §2.7.3 | Shaikh Net-Profitability Test | DRAFTABLE | — |
| §2.7.4 | Compression Test 1: Bhaduri-Marglin | DRAFTABLE | — |
| §2.7.5 | Compression Test 2: Keynes-Robinson | DRAFTABLE | — |
| §2.7.6 | Wald Test Sequence | DRAFTABLE | — |
| §2.8.1 | United States Results | PLACEHOLDER | All stages complete |
| §2.8.2 | Chile Results | PLACEHOLDER | All stages complete |
| §2.9 | Conclusions and Contributions | DRAFTABLE (skeleton) | — |

---

## Locked Equations

| Label | Equation | Section |
|---|---|---|
| Weisskopf decomposition | $r_t \equiv \mu_t \cdot b_t \cdot \pi_t$ | §2.3.2 |
| Gross accumulation identity | $g_K \equiv \chi_t \cdot \pi_t \cdot \mu_t \cdot b_t$ | §2.3.2 |
| Cambridge equation | $k = \chi r - \delta$ | §2.3.2 |
| Layer 2 behavioral | $\ln g_K = c + \beta_1\ln\pi + \beta_2\ln\mu + \beta_3\ln b$ | §2.3.3 |
| Cambridge benchmark | $\beta_j = 1$; behavioral content $\eta_j = \beta_j - 1$ | §2.3.3 |
| MPF (quadratic) | $a = \alpha_1 q + \alpha_2 q^2$ | §2.5.2 |
| Cost-minimization FOC | $q^* = (\pi - \alpha_1)/(2\alpha_2)$ | §2.5.2 |
| Distribution-conditioned θ | $\hat{\theta}_t = \theta_1 + \theta_2\pi_t$ | §2.5.1, §2.5.3 |
| Confinement identity | $\hat{\mu}_t = \exp(y_t - \hat{\theta}_t^{(1)} k_t)$ | §2.5.3 |
| Long-run π projection | $\hat{\pi}_t^{LR} = \varrho(y_t^{LR} - \theta_1 k_t^{LR})/(1 + \varrho\theta_2 k_t^{LR})$ | §2.5.3 |
| Peripheral FOC | $q^{CL*} = (\pi - \lambda s^{ME}\xi^{ME}_K - \bar{\alpha}_1^{CL})/(2\alpha_2)$ | §2.5.4 |
| Peripheral θ | $\hat{\theta}_t^{CL} = (\bar{\alpha}_1^{CL} + \hat{\pi}_t^{LR} - \lambda s_t^{ME}\xi^{ME}_K)/2$ | §2.5.5 |
| FM primary spec | $y_t = \psi_0 + \psi_1\hat{b}_t + \psi_2\pi_t + \psi_3\hat{\mu}_t + \eta_t$ | §2.7.2 |
| Okishio Wald test | $H_0: \psi_1 = \psi_3$ | §2.7.2 |
| Shaikh Wald test | $H_0: \psi_2^\pi = -\psi_4^i$ | §2.7.3 |

---

## Notation Quick-Reference (agent-enforced)

| Symbol | Meaning | Constraint |
|---|---|---|
| $\mu_t = Y_t/Y^p_t$ | Capacity utilization | Never "u" |
| $b_t = Y^p_t/K_t$ | Capital productivity at normal capacity | |
| $\pi_t = \Pi_t/Y_t$ | Profit share | |
| $\chi_t = I_t/\Pi_t$ | Recapitalization rate | NOT $\beta$ (reserved for cointegrating vectors) |
| $\kappa_t = I_t/K_t$ | Capital accumulation rate | Robinson convention |
| $a_t = \chi_t$ | Rate of capitalization (DV in Stage C) | |
| $\hat{\theta}_t = \theta_1 + \theta_2\pi_t$ | Distribution-conditioned transformation elasticity | Upstream — from cost-minimization FOC |
| $q \equiv \dot{K}/K - \dot{L}/L$ | Mechanization growth rate | NOT m; m = import share/propensity |
| $M$ | Imports (levels) | |
| $K^{NR}$, $K^{ME}$ | Nonresidential structures; machinery and equipment | From K-Stock-Harmonization |
| $e_t$ | Exploitation rate | EXCLUSIVELY exploitation; Euler = exp(·) |
| $r$ | Profit rate | $r = \mu b \pi$ |
| MPF | Mechanization Possibility Frontier | Never IPF |
| $\Lambda$ | Institutional space / accumulation regime | |

---

## Banned Terms (agent-enforced)

- ~~"IPF"~~ → MPF
- ~~"natural rate of growth"~~ → "Harrodian benchmark"
- ~~"interregnum"~~
- ~~hat notation $\hat{x}$ for growth rates in theory~~ → use $\dot{x}$
- ~~"β" for recapitalization rate~~ → $\chi$
- ~~"m" for mechanization growth~~ → $q$
- ~~"IICS imposed"~~ → "IICS is a falsifiable hypothesis, not an imposed condition"

---

## Priority Draft Queue

1. **§2.3** — Analytical Framework (all three subsections: typology + Layer 1 + Layer 2). Highest leverage — the accounting/behavioral identification is the spine of everything.
2. **§2.5.1** — Stage A identification problem + 4-variable VECM system. The chapter's core methodological contribution.
3. **§2.5.3** — First-stage θ̂ via long-run projection. Theoretically the sharpest new result.
4. **§2.5.4** — Stage A.2 peripheral capital composition + BoP cost-minimization. Distinctive center-periphery contribution.
5. **§2.7** — Stage C investment function (all 6 subsections). Theory-complete; FM-first structure is well-specified.
6. **§2.2** — Literature review (5 subsections). Synthesis of known material; write after §2.3 is solid.
7. **§2.1** — Introduction. Write last among draftable sections; requires §2.3 and §2.7 to be solid.
8. **§2.9** — Conclusions skeleton. PLACEHOLDER slots for results; framework prose fully writable.

---

## Workflow

```
ops-center session (Sonnet)
   ↓ select section from priority queue
   ↓ fire section prompt from ch2_section_prompts.md
   → open Opus session in this Claude project
   → paste prompt (self-contained; project files inherited)
   → Opus drafts section
   → bring output back to ops-center for review + tracking
   → update ops-state.yaml
```

---

*Index v2. Rebuilt 2026-04-02 from Ch2_Outline_DEFINITIVE.md. Previous version (v1, 2026-03-29) referenced Ch2_Outline_v1_DRAFT.md — fully obsolete.*
