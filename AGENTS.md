# AGENTS.md — Capacity-Utilization-US_Chile
## Standing instructions for all Codex and agent sessions in this repo

Read this file before any task. These rules are binding across all sessions.

---

## Repo identity

Chapter 2 dissertation pipeline: "Demand-Led Profitability and Structural Crisis of Capitalism
in Chile and the United States during the Fordist Era."

Authority files:
- `artifacts/chapter2/Ch2_Outline_DEFINITIVE.md` — locked outline, all content decisions
- `artifacts/chapter2/ch2_voice_guide.md` — writing voice calibration (WLM v4.0)
- `artifacts/chapter2/ch2_section_prompts.md` — section firing prompts
- `agents/zavaleta_comparative_relational_protocol.md` — agent protocol for comparative-relational method
- `artifacts/repo_map_current_2026-04-16.md` — current repo map and directory snapshot
- `artifacts/repo_structure_Ch2_v2.md` — legacy target-state structure spec

---

## Directory map

```
artifacts/chapter2/       ← Chapter 2 authority docs, prompts, and voice guide
artifacts/AR_Corridor/    ← corridor research assets and paper-facing packages
codes/                    ← executable analysis scripts; current layout is legacy-heavy
codes/legacy/             ← staged estimation tree currently holding Stage A/B/C scripts
codes/_legacyV2/          ← additional archived code branch
data/raw/Chile/           ← Chile source holdings (GDP, distribution, capital-stock inputs)
data/raw/US/              ← US source holdings (including `bea/` and `fred/`)
data/processed/           ← constructed panels split by `Chile/` and `US/`
data/interim/             ← intermediate build products, including structural identification
docs/data_sources_WS_corridor_v1/ ← active WS corridor corpus workspace
docs/empirical_strategy/  ← compact empirical notes and notebook-style markdowns
docs/_legacy/             ← older documentation tree and archived notes
output/stage_a|b|c/       ← current staged estimation outputs
output/*package*/         ← older packaged result folders that still coexist with staged outputs
```

---

## Comparative-Relational Method Rule

When tasks touch comparative-historical interpretation, corridor materials, archive work, or cross-case writing, agents must use the Zavaleta comparative-relational protocol in `agents/zavaleta_comparative_relational_protocol.md`.

Operational rules:

- treat cases as historically specific configurations of power, not national containers
- make comparison relational: state what each case reveals in the other
- build external determination into the case from the start
- translate traveling concepts before applying them to a new archive or domain
- distinguish state power from state apparatus before making state-centered claims
- infer strategy from structure rather than issuing moral verdicts on actors
- keep layered temporality explicit and separate retrospective clarity from actor knowledge

Anti-drift rules:

- do not write side-by-side country profiles and call them comparison
- do not add the international as a final contextual appendix
- do not use Zavaleta vocabulary decoratively without evidentiary or analytical work
- do not collapse corridor objects into macroeconomic panels by default

---

## Notation (locked — never violate)

- `μ_t` = capacity utilization = Y/Y^p — never "u"
- `χ_t` = recapitalization rate = I/Π — never `β_t`
- `q` = mechanization growth rate — never `m` (m = import share/propensity)
- `θ_t = θ₁ + θ₂π_t` = distribution-conditioned transformation elasticity
- `K^NR` = nonresidential structures; `K^ME` = machinery and equipment
- Uppercase = levels; lowercase = log-levels; dot notation for growth rates
- MPF (not IPF); "Harrodian benchmark" (not "natural rate of growth")
- `β_j` reserved for cointegrating vectors and Layer-2 coefficients only

---

## Data sources

| Variable | Source repo / path |
|---|---|
| US capital stocks (K^NR, K^ME) | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` |
| Chile capital stocks (K^NR, K^ME) | `C:\ReposGitHub\K-Stock-Harmonization` |
| Chile profit share | `data/raw/Chile/distr_19202024/distr_19202024.xlsx` |
| Chile real GDP | `data/raw/Chile/PerezEyzaguirre_DemandaAgregada/PerezEyzaguirre_DemandaAgregada.xlsx` |
| Price base (Chile K-Stock) | 2003 CLP — matches GDP file exactly, no rebasing needed |

---

## Standing prohibitions (writing tasks)

**Citation discipline:** Do not import citations to justify a claim that the chapter's own
theoretical or accounting framework already establishes. Ask: "is this citation doing
argumentative work from within this chapter's framework, or outsourcing authority to an
external source?" If the latter, cut it.

- `Hamilton (2018)` belongs in Ch1 (methodological critique). It does not appear in Ch2.
  The grounds for rejecting HP filtering in Ch2 are structural: the filter imposes θ=1
  by construction, conflating μ and b. This argument derives from the chapter's own
  accounting framework and requires no external authority.

**Voice:** All prose must conform to WLM v4.0 (see `artifacts/chapter2/ch2_voice_guide.md`).
Evidence and verdict in the same paragraph. No hedging. No neutral summaries.

---

## Stage gate

`codes/legacy/stage_a/chile/20_integration_tests.R` must pass before VECM estimation runs.
All state variables `(y^CL, k^NR, k^ME, π, πk)` must be I(1).

---

*AGENTS.md v2 — 2026-04-17*
*Authority: `artifacts/chapter2/Ch2_Outline_DEFINITIVE.md` | Repo map: `artifacts/repo_map_current_2026-04-16.md` | Voice: WLM v4.0*
