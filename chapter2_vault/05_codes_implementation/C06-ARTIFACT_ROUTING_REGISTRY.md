---
type: code_governance
status: active
depends_on:
  - chapter2_vault/05_codes_implementation/C05-FIGURE_PROTOCOL.md
  - chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md
  - data/metadata/data_provenance_manifest.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-08-07
updated_by: ARTIFACT_ROUTING_REGISTRY_ESTABLISHED
layer: registry
role: code-artifact-routing-registry
stage: paper-assembly
design_role: code_to_artifact_provenance
scope: chapter2
repo: Capacity-Utilization-US_Chile
applies_to: [US, CL, COMMON]
related_to:
  - "[[C05-FIGURE_PROTOCOL]]"
  - "[[DEPENDENCY_MANIFEST]]"
  - "[[2026-08-05_ch2_paper_assembly_lock_consistency_ledger]]"
subtype: code_implementation_memo
blocks: []
tags:
  - chapter2/codes
  - chapter2/provenance
  - chapter2/figures
  - chapter2/paper-facing
priority: core
---

# C06: Artifact Routing Registry — which code produced which figure and table

> [!IMPORTANT]
> **Constitutional Declaration.** This note records the route from analysis code to
> paper-facing artifact. Every figure and table the manuscript consumes must be traceable
> from this registry to the script that emitted it and the data that script read. An artifact
> that cannot be routed is not a result; it is a file.

---

## 1. What this note governs, and what it does not

`C03` §2 requires that no note silently import another note's authority. This one owns
**origin** and nothing else.

| Question | Governed by |
|---|---|
| Which script produced this artifact, from what inputs, consumed where? | **C06 (this note)** |
| What may a figure claim? Analytical status labels, recession shading, anchor markers, output formats, caption language, prohibited phrasings | [[C05-FIGURE_PROTOCOL]] |
| How does data travel from source to `data/processed/`? | `data/metadata/data_provenance_manifest.md` |
| What does an S-number stage *mean*? | **Nobody — see §5.** This note records observed practice, not doctrine. |
| Which numbers are binding for the manuscript? | `reports/SALVAGE_MANIFEST.md` |
| Where do artifacts live? | `AGENTS.md` — `output/` for quantitative artifacts, `reports/` for prose and LaTeX |

C05 §6 requires that "the report or manifest should state the annualization rule" for
recession shading, and §9 that "the report should list their expected local output paths."
C05 names no such document. **C06 is that document.**

---

## 2. The generated edge ledgers

`codes/COMMON_S00_artifact_routing_scan.py` scans all 301 scripts — `codes/` plus three
off-tree generators — and emits three CSVs to `output/artifact_routing/`:

| File | Contents |
|---|---|
| `artifact_routing_edges.csv` | every write, with `script_path`, `line`, `call`, `evidence`, `path_expression`, `resolved_path`, `artifact_kind`, `resolution`, `exists_on_disk` |
| `artifact_routing_reverse.csv` | artifact → producing script(s), flagged `MULTIPLE_PRODUCERS` and `WEAK_EVIDENCE_ONLY` |
| `artifact_routing_orphans.csv` | declared paths with no file on disk, and files on disk with no declared producer |

Re-run it after any change to a script's output paths. It is read-only over the repository.

### 2.1 Evidence classes, and why the distinction is load-bearing

Static analysis cannot always tell a write from a read. The ledger therefore grades its own
evidence rather than flattening everything into a single claim:

- **`write_call`** — the path is an argument to `ggsave`, `png`, `write.csv`, `saveRDS`, and
  the like. Strong: this is a write.
- **`path_expression`** — a `file.path()` composition naming an artifact extension. Medium.
- **`string_literal`** — a bare quoted path handed to a call. Weak, and the reason both
  Python table generators appear as `WEAK_EVIDENCE_ONLY`: they pass the output path to a
  user-defined writer function, which no static rule recognises as a write. Both were
  confirmed genuine by reading the source; the flag records the *evidence*, not a doubt.

Resolution is graded separately as `exact`, `partial` (directory known, filename built at
runtime), or `unresolved`. Of 2,447 edges, 1,476 resolve exactly, 65 partially, and 906 not at
all.

The worked example is `split_core_triad_tables.py`, which produces all 18 `_CORE`/`_TRIAD`
fragments the manuscript inputs. The ledger records both of its writes and marks both
**`unresolved`**:

```
L258 [unresolved]  reports / folder / f"{stem}_CORE.tex"
L261 [unresolved]  reports / folder / f"{stem}_TRIAD.tex"
```

`stem` is a loop variable over nine source fragments, so no static rule can say which of the
eighteen files either line produces. The scanner found the write and declined to name the
artifact. That is the intended behaviour: a reader who needs the mapping is sent to §3.2 of
this note, which states it, rather than being handed a fabricated filename that would look
authoritative and be wrong for eight cases out of nine.

Two guards keep inputs from being reported as outputs: any path a script reads is subtracted
from that script's outputs, and a line carrying three or more artifact literals is treated as
a vector of inputs rather than a set of writes.

---

## 3. The Chapter 2 paper-facing lineage

Curated by hand and verified against the ledger. This is the route the manuscript depends on.

### 3.1 Figures the manuscript draws

| Figure | Producing script | Reads | Consumed at |
|---|---|---|---|
| `output/figures/us_capital_levels_loess.png` | `codes/US_S38_generate_us_only_figures.R:60` | `data/processed/us_s31j/us_staged_pending_conditioners.csv` | §4.1 `fig:us_levels_loess` |
| `output/figures/us_tau_regime_bands.png` | `codes/US_S38_generate_us_only_figures.R:101` | same | §4.1 `fig:us_kappa_bands` |
| `output/CL/S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY/fig_cl_capital_levels_loess.png` | `codes/CL_S20_external_constraint_admissibility.R:406` | `chile_wbop_capital_annual_1920_2024.csv` (S10 lane) | §4.1 `fig:cl_levels_loess` |
| `output/CL/S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY/fig_cl_kappa_regime_bands.png` | `codes/CL_S20_external_constraint_admissibility.R:422` | same | §4.1 `fig:cl_kappa_bands` |
| `output/US/S60_CAPACITY_RECOVERY/figures/fig6_transformation_elasticity_overaccumulation.png` | `codes/US_S60_section423_reconstruction.R:234` | `s41_extended_capital_panel.csv`, `S29F_shaikh_tonak_wage_share_panel.csv`, `fred_annual_ad_components_panel.csv` | §4.2 `fig:specA_elasticity` |
| `output/US/S60_CAPACITY_RECOVERY/figures/fig4_reconstructed_capacity_utilization.png` | `codes/US_S60_section423_reconstruction.R:174` | same three | §4.2 `fig:specA_mu` |

All six carry `write_call` or `path_expression` evidence and resolve exactly.

### 3.2 Table fragments the manuscript inputs

| Fragment family | Producing script | Reads | Consumed at |
|---|---|---|---|
| `reports/US_Section31_IMOLS_Results/table_specA_set{1,2}_{gva,nva}.tex` | `codes/generate_s31_latex_tables.py:212–224` | `output/US/S50_SECTION31_IMOLS/csv/s50_section31_results.csv` + `section31_cmpr_custom_critical_values_N100000.csv` | §4.2 |
| `reports/US_Section32_IMOLS_Results/table_specB_set{1,2}_{gva,nva}.tex` | `output/generate_latex_tables.py:222–234` ⚠ | `output/US/S61_SECTION32_IMOLS/csv/s61_section32_results.csv` + `output/US/S62_SECTION32_MC/csv/cmpr_s32_critical_values_N100000.csv` | §4.3 |
| `reports/Chile_Section33_Peripheral_IMOLS_Results/table_chile_threshold_imols.tex` | **none — see §4.1** | — | §4.4 |
| all `*_CORE.tex` and `*_TRIAD.tex` (18) | `chapter2_paper/WP_Chapter2_1.0/split_core_triad_tables.py` | the nine fragments above | §4.2–§4.4 and Appendix D |

Upstream of the two Python generators sit the estimators themselves:
`codes/US_S50_section31_imols_estimation.R:334` writes the Specification A results CSV,
`codes/US_S61_section32_imols_specB.R:304` the Specification B CSV,
`codes/US_S52_*` and `codes/US_S62_*` the Monte Carlo critical values.

---

## 4. Known routing defects

Recorded, not repaired. Each is stated with the evidence that establishes it.

### 4.1 The Chile table has no producer

`reports/Chile_Section33_Peripheral_IMOLS_Results/table_chile_threshold_imols.tex` appears in
`artifact_routing_reverse.csv` with **zero** producing scripts. The Chilean estimator,
`codes/CL_S50_section33_imols_estimation.R:136`, writes only
`output/chile_imols_peripheral_results.csv` — to a bare relative `output/` at repo root, with
no country or stage directory. The `.tex` that carries all of §4.4 is hand-authored.

This is the most consequential defect in the registry. It is also the mechanism behind a
discrepancy already flagged in the manuscript: the hand-authored table reported a standard
error of 1.85 and three significance stars where the estimation output gives 2.10 and one.
A generated table cannot drift from its estimates. A transcribed one did.

### 4.2 The Specification B figure script writes to a path nothing reads

`codes/US_S60_section32_reconstruction.R:196–260` writes its three figures to
`chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/`. The scanner
resolves them there and nowhere else. The six `fig_specB_*` files now in
`output/US/S61_SECTION32_IMOLS/figures/` therefore have **no producer in the committed code**
— they are artifacts of a pre-commit version of the script. They appear in
`artifact_routing_orphans.csv` as `on_disk_no_producer`.

### 4.3 The aggregate-elasticity section never reaches the PDF

`chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/ch2_sec4_3_4.md`
is **absent from `compile_chapter2.py`'s `sec4_files` list**. Its derivation of
$\theta^{\text{SpecB}}_t$ and its three figure wires are transpiled into nothing. This is why
the manuscript carries six `\includegraphics` and not nine, and it compounds 4.2: even if the
figure paths were correct, the section that cites them is not in the build.

### 4.4 A generator lives outside `codes/`

`output/generate_latex_tables.py` produces four binding Specification B fragments from inside
`output/`, which `AGENTS.md` reserves for quantitative artifacts. Its sibling
`codes/generate_s31_latex_tables.py` does the same job for Specification A from the correct
location. Neither is named in `codes/README.md`.

### 4.5 A critical-value filename mismatch

`codes/generate_s31_latex_tables.py:6` reads
`output/US/S50_SECTION31_IMOLS/csv/section31_cmpr_custom_critical_values_N100000.csv`.
`codes/US_S52_section31_cmpr_montecarlo_critical_values.R:241` writes that file **without**
the `section31_` prefix. Both exist on disk. The prefixed file the table generator actually
consumes was produced out of band, so the Specification A stars do not trace to a script.

### 4.6 The pipeline emits no provenance

`US_S50`, `US_S61`, `US_S52`, `US_S62`, `US_S60_*`, `US_S38`, `CL_S50_section33`, and
`CL_S20_external_constraint_admissibility` contain no `Sys.time()`, no git hash, no
`sessionInfo()`, and write no manifest. `US_S52` and `US_S62` contain no `set.seed()`, so the
100,000-pass Monte Carlo critical values underpinning every significance star in the chapter
are not reproducible to the exact value.

The capability exists and is demonstrated elsewhere in this repository. The `US_D09` family
writes `D09_figure_manifest.csv` — figure id, file, source data, status — and
`US_D09_R_*.R:59` reads it back to verify. `CL_S25`, `CL_S99`, and `CL_S05` write SHA-256
manifests. The modern estimation lane simply does not do it.

---

## 5. Two conventions this note declines to settle

Both are pre-existing. Recording them is correct; resolving them is not this note's authority.

**The S-number taxonomy conflicts with itself.** `99_legacy/C03-REPO_STRUCTURE.md` §4 assigns
S50 to the capacity/profitability corridor and S60 to Chile's peripheral recapitalization. The
live tree uses S50 for US Section 3.1 IM-OLS and S60 for US capacity recovery. No note anywhere
defines S50, S51, S60, S61, or S62. Their meanings below are **observed from the tree**, not
locked:

| Stage | Observed content |
|---|---|
| `S50_SECTION31_IMOLS` | §4.2 Specification A IM-OLS estimation |
| `S51_SECTION31_STABILITY` | parameter-stability audit of those specifications |
| `S60_CAPACITY_RECOVERY` | $\hat{Y}^p$ and $\hat{\mu}$ reconstruction |
| `S61_SECTION32_IMOLS` | §4.3 Specification B IM-OLS estimation |
| `S62_SECTION32_MC` | Monte Carlo fixed-$b$ critical values for Specification B |

**Script name does not determine output directory.** There is no helper deriving one from the
other; every script hardcodes its own path string, under four incompatible conventions —
absolute `repo_root` (~60 files), `normalizePath(getwd())` (82 files), the `sbvecm_dir()`
helper in `CL_SBVECM_common.R:14` (4 files), and bare relative strings. `US_S42B_*` writes to
`S42_CM_EXTENSION`; `US_S38_*` writes to a flat `output/figures`; `COMMON_S33_*` writes into
`output/US/`; `CL_S50_section33` writes to bare `output/`. The registry documents the mapping
as found.

---

## 6. Cross-references

Figure conventions: [[C05-FIGURE_PROTOCOL]] ·
Data lineage: `data/metadata/data_provenance_manifest.md` ·
Binding manuscript sources: `reports/SALVAGE_MANIFEST.md` ·
Governance state: [[2026-08-05_ch2_paper_assembly_lock_consistency_ledger]] ·
Figure locations for §4.3: `chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/FIGURE_PATHS.md`
