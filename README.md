---
type: repository_manifest
status: active
layer: project_root
scope: dissertation_ch2
current_stage: S35 (US refreeze) / CL_S10 (Chile rebuild)
active_methodology: Interactive Cointegration (Polynomial Cointegration - CPR)
---

# Capacity-Utilization-US_Chile

Research and writing repository for Chapter 2 of the dissertation, "Demand-Led
Profitability and Structural Crisis of Capitalism in Chile and the United States during
the Fordist Era."

## Canonical layout

| Path | Role |
|---|---|
| `chapter2_paper/01_Versions/` | Versioned paper sources and future chapter-level Markdown builds |
| `chapter2_vault/06_paper_facing/` | Locked outline, paper-facing constitution, map, notes, and references |
| `chapter2_vault/07_WrittingSkills_and_Rules/` | Writing and exposition rules |
| `chapter2_vault/80_Prompts/` | Active execution prompts and implementation plans |
| `chapter2_vault/05_codes_implementation/` | Code-stage contracts and repository governance |
| `codes/` | Flat, country/stage-prefixed executable scripts |
| `data/` | Raw, interim, processed, final, and released data layers |
| `output/` | Country- and stage-specific results |

The former top-level `chapter2/` writing tree has been retired. Do not recreate it or
restore its old outline, draft, voice, or prompt paths. The vault is the authority layer;
`chapter2_paper/01_Versions/` is the paper-building layer.

## Writing workflow

1. Read `AGENTS.md` before beginning work.
2. Use `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md` for locked content decisions.
3. Use the paper-facing constitution and map in the same vault directory to determine scope.
4. Build each chapter version under `chapter2_paper/01_Versions/`, including the planned Markdown version.
5. Keep research notes, prompts, and governance material in `chapter2_vault/`; keep paper prose in `chapter2_paper/`.

## Synchronizing between computers

Commit and push completed work before changing machines. On the other computer, fetch and
fast-forward the same branch before editing. Research PDFs, figures, serialized model
objects, and report build products are version-controlled so the research record travels
with the repository. R session state, IDE state, and local Obsidian workspace state remain
machine-local and are ignored.

## Governing files

- `AGENTS.md` — binding repository-wide agent rules
- `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md` — locked outline
- `chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md` — paper-facing constitutional core
- `chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md` — paper-facing section map
- `chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md` — implementation structure and stage governance

The locked notation in `AGENTS.md` applies to all paper-facing and empirical work.
