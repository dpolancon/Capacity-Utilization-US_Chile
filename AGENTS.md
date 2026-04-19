# AGENTS.md — Capacity-Utilization-US_Chile
## Standing instructions for all Codex and agent sessions in this repo

Read this file before any task. These rules are binding across all sessions.

---

## Repo identity

Chapter 2 dissertation pipeline: "Demand-Led Profitability and Structural Crisis of Capitalism
in Chile and the United States during the Fordist Era."

Authority files:
- `chapter2/outline/Ch2_Outline_DEFINITIVE.md` — locked outline, all content decisions
- `chapter2/agents/ch2_voice_guide.md` — writing voice calibration (WLM v4.0)
- `chapter2/agents/ch2_section_prompts.md` — section firing prompts
- `docs/ch2/repo_structure_Ch2_v2.md` — full directory specification

---

## Directory map

```
chapter2/agents/drafts/   ← Opus session outputs (prose drafts)
chapter2/draft/           ← Assembled LaTeX chapter
chapter2/outline/         ← Locked outline
codes/stage_a/us/         ← Stage A.1 US estimation (R)
codes/stage_a/chile/      ← Stage A.2 Chile estimation (Python + R)
codes/stage_b/            ← Weisskopf profitability decomposition (R)
codes/stage_c/            ← Investment function estimation (R)
data/raw/us/              ← US-BEA-Income-FixedAssets-Dataset outputs
data/raw/chile/           ← K-Stock-Harmonization + CEPAL income data
data/processed/           ← Constructed estimation panels
output/stage_a|b|c/       ← Estimation results (csv, figs, logs)
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

**Voice:** All prose must conform to WLM v4.0 (see `chapter2/agents/ch2_voice_guide.md`).
Evidence and verdict in the same paragraph. No hedging. No neutral summaries.

---

## Stage gate

`codes/stage_a/chile/20_integration_tests.R` must pass before VECM estimation runs.
All state variables `(y^CL, k^NR, k^ME, π, πk)` must be I(1).

---

*AGENTS.md v1 — 2026-04-02*
*Authority: Ch2_Outline_DEFINITIVE.md | Voice: WLM v4.0*
