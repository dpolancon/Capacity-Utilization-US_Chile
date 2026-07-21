# CLAUDE.md — Capacity-Utilization-US_Chile
## Standing instructions for all Claude Code and agent sessions in this repo

Read this file before any task. These rules are binding across all sessions.

---

## Repo identity

Chapter 2 dissertation pipeline: "Demand-Led Profitability and Structural Crisis of Capitalism
in Chile and the United States during the Fordist Era."

Authority files:
- `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md` — locked outline and content decisions
- `chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md` — constitutional paper-facing claim
- `chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md` — locked paper-facing section map
- `chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md` — implementation and stage governance

---

## Directory map

```
chapter2_paper/01_Versions/        ← Paper source versions and chapter Markdown builds
chapter2_vault/06_paper_facing/    ← Locked outline, constitution, map, and references
chapter2_vault/07_WrittingSkills_and_Rules/ ← Writing and exposition rules
chapter2_vault/80_Prompts/         ← Active execution prompts and plans
codes/                             ← Flat, country/stage-prefixed implementation scripts
data/raw|interim|processed|final/  ← Data pipeline layers
data/releases/                     ← Frozen data releases
output/US|CL/                      ← Country- and stage-bounded results
```

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

**Voice:** All prose must conform to WLM v4.0. Evidence and verdict in the same
paragraph. No hedging. No neutral summaries. For advisor-facing exposition, also use
`chapter2_vault/07_WrittingSkills_and_Rules/C02_Advisor_Michael_Facing_Exposition_Prompt.md`.

---

## Stage gate

No nonlinear, interacted, or generated specification may advance to estimator selection
before passing `chapter2_vault/03_econometrics/Interaction_Term_Integration_Order_Gate.md`.
Stage transitions must also respect the active contracts indexed by
`chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md`.

---

*CLAUDE.md v2 — 2026-07-21*
*Authority: Ch2_Outline_DEFINITIVE.md | Voice: WLM v4.0*
