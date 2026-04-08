# Repo Structure v2 — Capacity-Utilization-US_Chile
## Chapter 2: Writing + Empirical Pipeline

> **Date:** 2026-04-02  
> **Supersedes:** `repo_structure_Ch2_v1.md` (2026-03-29)  
> **Key changes:** Stage C added (investment function); `chapter2/` top-level writing folder; Stage A split A.1/A.2 by country; Chile data assembly tracked.

---

## Governing principles

1. **Writing and empirics never cross.** `chapter2/` owns all prose. `codes/` owns all estimation. `data/` owns all inputs. `output/` owns all results.
2. **Archive, never delete.** Ch1 Stage 4 scripts stay in `codes/archive/ch1_stage4/`.
3. **Country split within stages.** `codes/stage_a/us/` and `codes/stage_a/chile/` — parallel tracks, parallel execution.
4. **Drafts are inputs to the chapter, not outputs.** Opus session drafts land in `chapter2/agents/drafts/` and are assembled into `chapter2/draft/ch2_draft_v1.tex`.

---

## Target directory tree

```
Capacity-Utilization-US_Chile/
│
├── README.md
├── WorkflowManifesto.md
├── .gitignore
├── .gitattributes
├── capacity_utilization.Rproj
│
├── chapter2/                            ← ALL writing artifacts
│   ├── agents/                          ← Writing infrastructure (Max tab workflow)
│   │   ├── ch2_modular_index.md         ← Section status + authority map [v2]
│   │   ├── ch2_section_prompts.md       ← Section firing prompts + LaTeX template [v2]
│   │   └── drafts/                      ← Opus session outputs land here
│   │       ├── ch2_sec21_draft_v1.md    ← §2.1 Introduction
│   │       ├── ch2_sec221_draft_v1.md   ← §2.2.1 Crisis as limit
│   │       └── ...                      ← one file per section
│   ├── draft/                           ← Assembled LaTeX chapter
│   │   ├── ch2_draft_v1.tex             ← Assembled from drafts (after review)
│   │   ├── ch2_references.bib           ← Bibliography (44 entries locked)
│   │   └── figures/                     ← Figures referenced in chapter
│   └── outline/                         ← Locked outline history
│       └── Ch2_Outline_DEFINITIVE.md    ← THE authority file (2026-04-02)
│
├── codes/
│   ├── archive/
│   │   └── ch1_stage4/                  ← Ch1 Stage 4 scripts (archived)
│   │
│   ├── utils/
│   │   └── 00_utils.R                   ← Shared helpers (log-diff, date index, plotting)
│   │
│   ├── stage_a/                         ← CU identification (MPF + VECM)
│   │   ├── us/                          ← Stage A.1: US center (Route 1)
│   │   │   ├── 10_data_prep_us.R        ← Load BEA repo outputs; construct a_t, q_t
│   │   │   ├── 20_mpf_regression.R      ← a_t = α₁q_t + α₂q_t² (Route 1 direct MPF)
│   │   │   ├── 21_theta_mu_us.R         ← θ̂_t^US, μ̂_t^US, b̂_t^US recovery
│   │   │   └── 22_vecm_validation.R     ← 4-var VECM (y,k,π,πk) validation + β₂=1/2 test
│   │   │
│   │   └── chile/                       ← Stage A.2: Chile periphery (Route 2)
│   │       ├── 10_data_assembly.py      ← Merge K-Stock canonical + CEPAL income → panel
│   │       ├── 11_construct_panel.py    ← Construct (y,k,π,πk,s_ME,kME,kNR); save .csv
│   │       ├── 20_integration_tests.R   ← ADF/KPSS on all state variables [STAGE GATE]
│   │       ├── 21_vecm_4var.R           ← Johansen rank test + restricted VECM CV1-CV3
│   │       ├── 22_theta_mu_chile.R      ← π̂^LR → θ̂_t^CL → μ̂_t^CL recovery
│   │       └── 23_bop_augmentation.R    ← s^ME k augmentation; λ̂ identification
│   │
│   ├── stage_b/                         ← Weisskopf profitability decomposition
│   │   ├── 30_weisskopf_us.R            ← ṙ/r = μ̇/μ + ḃ/b + π̇/π, US sub-periods
│   │   └── 31_weisskopf_chile.R         ← Same, Chile sub-periods
│   │
│   └── stage_c/                         ← Investment function (FM-first)
│       ├── 40_fm_ardl_us.R              ← Primary: FM spec (ψ₁b̂ + ψ₂π + ψ₃μ̂), US
│       ├── 41_fm_ardl_chile.R           ← Same, Chile
│       ├── 42_compression_tests.R       ← BM Wald (ψ₁=ψ₃) + KR Wald (joint)
│       ├── 43_shaikh_test.R             ← Net profitability Wald (ψ₂^π = -ψ₄^i)
│       └── 44_structural_comparison.R   ← ψ₃^US vs ψ₃^CL; CUSUM stability
│
├── data/
│   ├── raw/
│   │   ├── us/                          ← Outputs from US-BEA-Income-FixedAssets-Dataset
│   │   │   └── (NIPA + BEA Fixed Assets: Y, K, KNR, KME, Π, W, I, employment)
│   │   └── chile/                       ← K-Stock + CEPAL income [ASSEMBLE NOW]
│   │       ├── k_stock_canonical_2003CLP.csv    ← From K-Stock-Harmonization canonical
│   │       ├── k_stock_bcch_2003CLP.csv         ← BCCh extension bundle
│   │       ├── cepal_gdp_income.csv             ← Y^CL, Π^CL, W^CL from CEPAL
│   │       ├── cepal_employment.csv             ← L^CL (for Route 1 robustness only)
│   │       └── cepal_tot.csv                    ← Terms of trade (BoP proxy)
│   │
│   └── processed/
│       ├── us/
│       │   └── ch2_panel_us.rds         ← (y,k,π,a,q,kNR,kME) ready for Stage A.1
│       └── chile/
│           └── ch2_panel_chile.rds      ← (y,k,π,πk,s_ME,kME,kNR) ready for Stage A.2
│
└── output/
    ├── stage_a/
    │   ├── us/
    │   │   ├── csv/                     ← θ̂ series, μ̂_t^US, α̂₁, α̂₂, MPF diagnostics
    │   │   ├── figs/                    ← μ̂_t vs HP-filter; θ̂_t path
    │   │   └── logs/
    │   └── chile/
    │       ├── csv/                     ← θ̂^CL, μ̂^CL, rank test, VECM estimates
    │       ├── figs/                    ← θ̂^US vs θ̂^CL; μ̂^CL validation
    │       └── logs/
    ├── stage_b/
    │   ├── us/
    │   └── chile/
    └── stage_c/
        ├── us/
        ├── chile/
        └── comparison/                  ← ψ₃^US vs ψ₃^CL crosswalk
```

---

## Immediate setup: bash script

Run from repo root in Claude Code or terminal:

```bash
#!/bin/bash
# setup_ch2_structure.sh
# Run from repo root: bash setup_ch2_structure.sh

set -e

echo "Creating chapter2/ writing structure..."
mkdir -p chapter2/agents/drafts
mkdir -p chapter2/draft/figures
mkdir -p chapter2/outline

echo "Creating codes/ estimation structure..."
mkdir -p codes/stage_a/us
mkdir -p codes/stage_a/chile
mkdir -p codes/stage_b
mkdir -p codes/stage_c
mkdir -p codes/utils

echo "Creating data/ structure..."
mkdir -p data/raw/us
mkdir -p data/raw/chile
mkdir -p data/processed/us
mkdir -p data/processed/chile

echo "Creating output/ structure..."
mkdir -p output/stage_a/us/{csv,figs,logs}
mkdir -p output/stage_a/chile/{csv,figs,logs}
mkdir -p output/stage_b/us output/stage_a/chile
mkdir -p output/stage_c/US output/stage_c/chile output/stage_c/comparison

echo "Moving agent files to chapter2/agents/..."
# Run after copying outputs from this session:
# cp agents/ch2_modular_index.md chapter2/agents/       [v2 file]
# cp agents/ch2_section_prompts.md chapter2/agents/     [v2 file]
# cp agents/Ch2_Outline_DEFINITIVE.md chapter2/outline/ [locked outline]

echo "Creating stub scripts..."
touch codes/utils/00_utils.R
touch codes/stage_a/us/10_data_prep_us.R
touch codes/stage_a/us/20_mpf_regression.R
touch codes/stage_a/us/21_theta_mu_us.R
touch codes/stage_a/us/22_vecm_validation.R
touch codes/stage_a/chile/10_data_assembly.py
touch codes/stage_a/chile/11_construct_panel.py
touch codes/stage_a/chile/20_integration_tests.R
touch codes/stage_a/chile/21_vecm_4var.R
touch codes/stage_a/chile/22_theta_mu_chile.R
touch codes/stage_a/chile/23_bop_augmentation.R
touch codes/stage_b/30_weisskopf_us.R
touch codes/stage_b/31_weisskopf_chile.R
touch codes/stage_c/40_fm_ardl_us.R
touch codes/stage_c/41_fm_ardl_chile.R
touch codes/stage_c/42_compression_tests.R
touch codes/stage_c/43_shaikh_test.R
touch codes/stage_c/44_structural_comparison.R

echo "Done. Review structure, then: git add -A && git commit -m 'scaffold: Ch2 writing + empirical pipeline structure'"
```

---

## File flow: writing track

```
chapter2/agents/ch2_section_prompts.md   ← copy section prompt
  ↓
claude.ai (new session in this project)  ← paste prompt, Opus drafts
  ↓
chapter2/agents/drafts/ch2_sec##_v1.md  ← paste output here
  ↓
review + edit                            ← this session (Sonnet ops center)
  ↓
chapter2/draft/ch2_draft_v1.tex          ← assembled LaTeX chapter
  ↓
pdflatex (two-pass)                      ← compile
```

---

## File flow: empirical track

```
data/raw/chile/
  k_stock_canonical_2003CLP.csv          ← K-Stock-Harmonization output
  cepal_gdp_income.csv                   ← CEPAL assembly [TODAY]
  ↓
codes/stage_a/chile/10_data_assembly.py  ← merge → data/processed/chile/ch2_panel_chile.rds
  ↓
codes/stage_a/chile/20_integration_tests.R   ← [STAGE GATE]
  ↓
codes/stage_a/chile/21_vecm_4var.R           ← rank test + restricted VECM
  ↓
codes/stage_a/chile/22_theta_mu_chile.R      ← μ̂^CL, θ̂^CL, b̂^CL → output/stage_a/chile/csv/
  ↓
codes/stage_b/31_weisskopf_chile.R           ← Weisskopf decomposition
  ↓
codes/stage_c/41_fm_ardl_chile.R             ← FM ARDL + Wald tests
  ↓
output/stage_c/comparison/                   ← ψ₃^US vs ψ₃^CL crosswalk
```

---

## Script naming convention

| Script | Stage | Role |
|---|---|---|
| `10_data_prep_us.R` | Setup A.1 | US panel construction |
| `10_data_assembly.py` | Setup A.2 | Chile K-Stock + CEPAL merge |
| `11_construct_panel.py` | Setup A.2 | $(y,k,\pi,\pi k)$ construction |
| `20_integration_tests.R` | **GATE** | ADF/KPSS on all state variables |
| `20_mpf_regression.R` | A.1 | Route 1 direct MPF |
| `21_vecm_4var.R` | A.2 | 4-var restricted VECM |
| `22_theta_mu_*.R` | A.1/A.2 | $\hat{\theta}$, $\hat{\mu}$, $\hat{b}$ recovery |
| `30_weisskopf_us.R` | B | US Weisskopf decomposition |
| `31_weisskopf_chile.R` | B | Chile Weisskopf decomposition |
| `40_fm_ardl_us.R` | C | FM primary spec, US |
| `41_fm_ardl_chile.R` | C | FM primary spec, Chile |
| `42_compression_tests.R` | C | BM + KR Wald compression tests |
| `43_shaikh_test.R` | C | Net profitability Wald |
| `44_structural_comparison.R` | C | $\hat{\psi}_3^{US}$ vs $\hat{\psi}_3^{CL}$ |

---

## Stage gate: `20_integration_tests.R`

Hard gate before Stage A.2 VECM estimation. Must pass before `21_vecm_4var.R` runs.

Checks:
- ADF + KPSS on $(y^{CL}, k^{CL}, \pi^{CL}, \pi^{CL}k^{CL})$
- All four must be $I(1)$ for rank test to be well-posed
- Output: `output/stage_a/chile/csv/integration_tests.csv`

---

*Repo structure v2. 2026-04-02. Supersedes v1 (2026-03-29).*
*Chile income data assembly in progress — `data/raw/chile/` is the immediate landing zone.*
