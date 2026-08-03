---
type: system_rules
status: active
depends_on: [chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]
stage_scope: all_stages
country: US_CL
last_updated: 2026-08-01
updated_by: TABLE_FIGURE_FORMATTING_RULE_LOCK
layer: governance_constraint
scope: all_agent_sessions
authority_files:
- chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
- chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
- chapter2_vault/06_paper_facing/00S_Chapter2_Symbology_and_Notation_Lock.md
- chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md
- chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md
---

# AGENTS.md — Capacity-Utilization-US_Chile
## Standing instructions for all Codex and agent sessions in this repo

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
output/                            ← Tables (.csv), figures (.png/.pdf), ledgers, raw inputs
reports/                           ← All LaTeX reports (.tex), PDFs (.pdf), and manuscript drafts
```

---

## Report vs Output Directory Governance (locked — never violate)

- **`reports/`**: Store all written reports, executive summaries, LaTeX source manuscripts (`.tex`), compiled report PDFs (`.pdf`), and analytical memos here.
- **`output/`**: Strictly reserved for quantitative output artifacts—tables (`.csv`), figures (`.png`, `.pdf`), estimation ledgers, and raw data inputs intended for incorporation into reports, presentations, or paper-facing developments.
- **Prohibition**: Never output LaTeX manuscript source files (`.tex`) or compiled report PDFs (`.pdf`) directly into `output/` or its subdirectories.

---

## Notation (locked — never violate)

- `μ_t` = capacity utilization = Y/Y^p — never "u"
- `χ_t` = recapitalization rate = I/Π — never `β_t`
- `q` = mechanization growth rate — never `m` (m = import share/propensity)
- `θ_j` = parameters governing the transformation closure $g_{Y^p} = \theta g_K$ and $d Y^p / d K = \theta$ aggregate across all specifications (including direct capital elasticity and interaction terms).
- `α` = constant intercept in cointegrating regressions (does not enter transformation derivative $d Y^p / d K$).
- `p_t^i` = relative price variable (where $i$ indexes the specific price ratio, e.g. $p_t^{\kappa}$ for relative capital asset prices $P^{\text{ME}}/P^{\text{NRC}}$). Excluded from Specification A; enters Specification B across multiple sub-specifications.
- `β_j` = standalone uninteracted control coefficients (e.g. $\beta_{\omega}$ for standalone wage share, $\beta_{p^{\kappa}}$ for relative price $p_t^{\kappa}$) and Layer-2 cointegrating vectors.
- `κ_t` = capital composition ratio ($k_t^{\text{ME}} - k_t^{\text{NRC}}$) — replaces $\tau_t$.
- `γ` / `Γ` = step dummy controls in single-equation ($\boldsymbol{\gamma}' \mathbf{D}_t$) and multi-equation system ($\boldsymbol{\Gamma} \mathbf{D}_t$) matrix form.
- `δ` = strictly reserved for economic depreciation rates of net capital stock in growth accounting and stock-flow modeling — never used for step dummies.
- `z` = depletion / discard rate of gross capital stock (capital in operation), distinct from net capital depreciation `δ`.
- `λ` = parameters of the mechanization function.
- `K^NR` = nonresidential structures; `K^ME` = machinery and equipment
- Uppercase = levels; lowercase = log-levels; dot notation for growth rates
- **MPF** = Mechanization Productive Frontier (never "Maximum Productive Frontier" or "IPF")
- **Harrodian knife-edge** (never "Harrodian benchmark")
- **Natural rate of growth**: Unblocked for explicit reference when defining the growth rate that fully absorbs population growth at a given productivity growth rate; non-binding for the paper.
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

## LaTeX table & figure formatting (locked)

- Bold text in `.tex` files must use `\textbf{}`. Never use Markdown `**` syntax.
- All `\begin{table}` and `\begin{figure}` environments must use `[h!]` or `[H]` float specifiers.
- Use `\FloatBarrier` (from `placeins` package) before each `\section` to prevent float drift.
- Table and figure captions must always be placed at the **top** of their respective environments.
- Every table and figure must include a detailed **note at the bottom**.
  - For tables, footnotes/notes must be placed at the bottom of the tabular using `\multicolumn{N}{p{Wcm}}{\footnotesize ...}`.
- Every single column in a table must use explicit `p{Xcm}` sizing with context-specific widths to ensure proper wrapping and layout.

## LaTeX paragraph numbering (locked)

- Section 3.1, 3.2, etc., represent subsections, and their inner headings represent subsubsections.
- Paragraphs must be numbered using **only uppercase letters** (e.g. `\paragraph{A}`, `\paragraph{B}`, ..., `\paragraph{Z}`, `\paragraph{AA}`, etc.).
- Paragraph headings must not repeat the preceding section or subsection numbers.
- The paragraph letter counter must reset to `A` at the start of every subsection (`\subsection`) and subsubsection (`\subsubsection`).

---

## Obsidian Vault & Metadata Governance (locked — never violate)

- **YAML Frontmatter Integrity:** When creating or editing files under `chapter2_vault/`, the agent must preserve the Obsidian YAML metadata structure. 
  - Standard keys (`type`, `status`, `depends_on`, `stage_scope`, `country`, `last_updated`, `layer`, `role`, `stage`, `tags`) must be maintained.
  - Whenever a vault file's content or protocol is updated, the `last_updated` date must be advanced to the current date (`YYYY-MM-DD`).
  - For tracking significant protocol or lock updates, include an `updated_by` key in the frontmatter matching the event name (e.g., `updated_by: CPR_IMOLS_ESTIMATION_PROTOCOL_LOCK`).

- **Bi-directional Vault Linking:** Vault notes must be cross-linked using standard double-bracket Obsidian syntax `[[Note_Name]]`. When updating any active lock, gate, or diagnostic report:
  - The corresponding Map of Content (e.g., `_03_Econometrics_MOC.md` for econometrics) must be updated.
  - Upstream analytical protocols (e.g., `R02_Identification_and_Estimation_Protocol.md`) or theoretical outlines must be updated with links to the new gate or specification.

- **Separation of Workspace and Artifact Writes:** 
  - When creating or modifying project files (vault files `.md` or scripts `.R` / `.py` in the repository), never provide `ArtifactMetadata` in the `write_to_file` call. `ArtifactMetadata` is strictly reserved for conversational markdown artifacts created inside the `<appDataDir>\brain\<conversation-id>` directory.

- **Robustness Pre-Testing and Diagnostics:** 
  - Robustness and diagnostic comparisons (e.g., comparing coefficients across uncentered and centered regimes) must not use strict decimal-place numerical gates (like `< 10^-10`) that halt execution on trivial floating-point drift.
  - Comparability must be defined as statistical indistinguishability (confidence-band overlap).
  - If numerical instability causes uncentered models to diverge from centered models, log the condition number and default to the initial-state centered model (Regime B) without blocking the estimation pipeline or experimental searches.

---

## Quick-Reference Decision Tree

**Use this when you're unsure where to look.**

### "What is the theoretical claim?"
→ `06_paper_facing/00E_Constitution.md` (locked, ~150 lines)

### "What's the paper structure?"
→ `06_paper_facing/00N_Map.md` (locked, ~260 lines)

### "What notation should I use?"
→ `06_paper_facing/00S_Notation_Lock.md` + `NOTATION_SHEET.md`

### "What code implements X?"
→ `codes/README.md` + `codes/[country_stage]_*.R`

### "How does data flow?"
→ `DEPENDENCY_MANIFEST.md` + `data/metadata/`

### "Can I change the specification?"
→ `05_codes_implementation/C03-REPO_STRUCTURE.md` + stage gates (above)

### "Is this file still active?"
→ Check `status:` in YAML frontmatter; if `deprecated`, see `DEPRECATION.md`

### "What's blocking me?"
→ `STAGE_GATES.md` or check `blocks:` key in dependent file's frontmatter

---

*AGENTS.md v7 — 2026-07-29*
*Authority: Ch2_Outline_DEFINITIVE.md | Voice: WLM v4.0*
*Navigation: See _INDEX.md + DEPENDENCY_MANIFEST.md in chapter2_vault/*
