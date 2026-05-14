# QWEN.md — Capacity-Utilization-US_Chile

## Project Overview

This repository contains the dissertation pipeline for **Chapter 2**: *"Demand-Led Profitability and Structural Crisis of Capitalism in Chile and the United States during the Fordist Era."* It is an empirical macroeconomics project combining Marxist crisis theory with econometric identification of capacity utilization (μ_t) and behavioral investment functions.

The project has two intertwined tracks:

1. **Writing track** — producing Chapter 2 prose via LLM-assisted drafting sessions, governed by a locked outline and voice calibration guide.
2. **Empirical track** — a multi-stage estimation pipeline (Stages A, B, C) comparing center (US) and periphery (Chile) capitalist economies during 1945–1978.

### Core Framework

The chapter rests on an accounting identity: `g_K = χ · π · μ · b`, where:
- `μ_t` = capacity utilization (Y/Y^p) — latent variable recovered via reduced-rank cointegration
- `χ_t` = recapitalization rate (I/Π)
- `π` = profit share (distribution channel)
- `b` = capital productivity (technology channel)

Stage A identifies μ_t structurally. Stage B decomposes profitability via Weisskopf (r = μ·b·π). Stage C estimates behavioral investment functions (ARDL) conditional on Stage A outputs.

### Key Theoretical Document

`RRR_Accumulation_Framework.md` formalizes the integrated framework: reduced-rank identification of latent utilization nested with a behavioral accumulation law for investment.

---

## Directory Structure

```
chapter2/                     # Writing infrastructure
├── Ch2_Outline_DEFINITIVE.md # LOCKED outline — all content decisions derive from here
├── ch2_voice_guide.md        # WLM v4.0 voice calibration (paste FIRST in every session)
├── ch2_section_prompts.md    # Section firing prompts + LaTeX template
├── ch2_modular_index.md      # Section status tracker
├── fire_ch2_drafts.py        # Concurrent API firing script (optional)
├── s2_2_final_draft.md       # Completed draft of §2.2
└── s2_2_voice_constraints.md # Voice constraints for §2.2

codes/                        # Empirical pipeline
├── stage_a/                  # MPF estimation and μ identification
│   ├── us/                   # Stage A.1: US estimation (R)
│   └── chile/                # Stage A.2: Chile estimation (Python + R)
├── stage_b/                  # Weisskopf profitability decomposition (R)
│   ├── us/
│   └── chile/
├── stage_c/                  # ARDL investment function estimation (R)
│   └── us/
├── utils/                    # Shared utilities
└── legacy/                   # Deprecated scripts

data/
├── raw/                      # Source data
│   ├── us/                   # US-BEA-Income-FixedAssets-Dataset outputs
│   └── chile/                # K-Stock-Harmonization + CEPAL income data
├── processed/                # Constructed estimation panels
├── interim/                  # Intermediate constructed objects
└── final/                    # Final analysis-ready datasets

output/                       # Estimation results
├── stage_a|b|c/              # Stage-specific outputs (csv, figs, logs)
├── diagnostics/              # Model diagnostics
├── panel/                    # Panel construction outputs
├── tables/                   # Result tables
└── writing/                  # Writing-support outputs

AR_Corridor/                  # Accumulation Regime corridor analysis
├── 00_governing_notes/
├── 01_accounting_objects/
├── 02_country_tracks/
├── 03_dysfunctionality/
├── 04_estimation_outputs/
└── 05_paper_facing_assets/

docs/ch2/                     # Documentation
└── repo_structure_Ch2_v2.md  # Full directory specification

agents/                       # Agent configuration
```

---

## Notation (LOCKED — Never Violate)

| Symbol | Meaning | Prohibition |
|---|---|---|
| `μ_t` | capacity utilization = Y/Y^p | Never use "u" |
| `χ_t` | recapitalization rate = I/Π | Never use `β_t` |
| `q` | mechanization growth rate | Never use `m` (m = import share) |
| `θ_t = θ₁ + θ₂π_t` | distribution-conditioned transformation elasticity | — |
| `K^NR` | nonresidential structures | — |
| `K^ME` | machinery and equipment | — |
| Uppercase | levels | — |
| lowercase | log-levels | — |
| dot notation | growth rates | — |
| MPF | mechanization possibility frontier | Not "IPF" |
| "Harrodian benchmark" | — | Not "natural rate of growth" |
| `β_j` | cointegrating vectors / Layer-2 coefficients only | — |

---

## Data Sources

| Variable | Source |
|---|---|
| US capital stocks (K^NR, K^ME) | `C:\ReposGitHub\US-BEA-Income-FixedAssets-Dataset` |
| Chile capital stocks (K^NR, K^ME) | `C:\ReposGitHub\K-Stock-Harmonization` |
| Chile profit share | `data/raw/Chile/distr_19202024/distr_19202024.xlsx` |
| Chile real GDP | `data/raw/Chile/PerezEyzaguirre_DemandaAgregada/PerezEyzaguirre_DemandaAgregada.xlsx` |
| Price base (Chile K-Stock) | 2003 CLP — matches GDP file, no rebasing needed |

---

## Building and Running

### Empirical Pipeline

**Prerequisites:** R (with cointReg, urca, vars, dynlm, etc.), Python 3 (pandas, numpy, statsmodels)

**Chile pipeline:**
```bash
# Step 1: Data assembly
python codes/stage_a/chile/10_data_assembly.py
python codes/stage_a/chile/11_construct_panel.py

# Step 2: Stage gate — integration tests MUST pass before VECM
Rscript codes/stage_a/chile/20_integration_tests.R

# Step 3: VECM estimation (only after stage gate passes)
Rscript codes/stage_a/chile/02_stage1_vecm.R
```

**US pipeline:** R scripts in `codes/stage_a/us/` run sequentially (numbered order).

**Stage gate requirement:** `codes/stage_a/chile/20_integration_tests.R` must pass before any VECM estimation. All state variables `(y^CL, k^NR, k^ME, π, πk)` must be I(1).

### Writing Sprint

1. Open a claude.ai session **in this project**
2. Paste full contents of `chapter2/ch2_voice_guide.md` FIRST
3. Paste the relevant section prompt from `chapter2/ch2_section_prompts.md`
4. Save output as `chapter2/agents/drafts/ch2_sec<XX>_draft_v1.md`

---

## Development Conventions

### Writing Constraints

- **Citation discipline:** Never import citations to justify claims the chapter's own framework already establishes. Ask: "is this citation doing argumentative work from within this chapter's framework, or outsourcing authority?" If the latter, cut it.
- `Hamilton (2018)` belongs in Ch1 only. Ch2's rejection of HP filtering is structural (θ=1 by construction), not methodological.
- **Voice:** All prose must conform to WLM v4.0. Evidence and verdict in the same paragraph. No hedging. No neutral summaries.
- See `chapter2/ch2_voice_guide.md` for structural rules (5 hard rules) and sentence-level techniques (T1–T5).

### Code Conventions

- R scripts are numbered for execution order (e.g., `10_`, `11_`, `20_`, `02_`)
- Python scripts handle data assembly/construction; R handles estimation
- `.Rprofile` suppresses interactive prompts during scripted runs
- R packages configured via `.Rprofile` (CRAN mirror: cloud.r-project.org)

### Prohibitions

- Never violate the locked notation
- Never run VECM before stage gate passes
- Never cite Hamilton (2018) in Ch2

---

## R Project

This is an R Studio project (`Capacity-Utilization-US_Chile.Rproj`). VS Code R-debugger configurations are in `.vscode/launch.json`.

---

## Related Repositories

- `US-BEA-Income-FixedAssets-Dataset` — US capital stock data pipeline
- `K-Stock-Harmonization` — Chile capital stock harmonization pipeline

---

*QWEN.md v1 — 2026-04-14*
*Authority files: Ch2_Outline_DEFINITIVE.md | Voice: WLM v4.0 | Framework: RRR_Accumulation_Framework.md*
