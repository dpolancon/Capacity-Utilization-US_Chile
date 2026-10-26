# Figure Coherence Report — Chapter 2

**Generated:** 2026-08-07 · **Event:** `CH2_FIGURE_COHERENCE_AUDIT`
**Scope:** the six figures the manuscript draws. Tables are covered only where a table
defect bears directly on a figure; the systematic table audit was deliberately left out of
scope, and table routing defects are recorded in
`chapter2_vault/05_codes_implementation/C06-ARTIFACT_ROUTING_REGISTRY.md` §4 instead.

> **This report does not fix anything.** It gathers evidence so that a repair protocol can be
> designed against facts rather than impressions. Every finding names what is wrong, how it was
> established, and what it would take to settle — and stops there. §12 lists the decisions a
> protocol would have to make; none of them is made here.

---

## 1. The six figures

| # | Figure | Producing script | Consumed at |
|---|---|---|---|
| 1 | `us_capital_levels_loess.png` | `codes/US_S38_generate_us_only_figures.R:60` | §4.1 `fig:us_levels_loess` |
| 2 | `us_tau_regime_bands.png` | `codes/US_S38_generate_us_only_figures.R:101` | §4.1 `fig:us_kappa_bands` |
| 3 | `fig_cl_capital_levels_loess.png` | `codes/CL_S20_external_constraint_admissibility.R:406` | §4.1 `fig:cl_levels_loess` |
| 4 | `fig_cl_kappa_regime_bands.png` | `codes/CL_S20_external_constraint_admissibility.R:422` | §4.1 `fig:cl_kappa_bands` |
| 5 | `fig6_transformation_elasticity_overaccumulation.png` | `codes/US_S60_section423_reconstruction.R:234` | §4.2 `fig:specA_elasticity` |
| 6 | `fig4_reconstructed_capacity_utilization.png` | `codes/US_S60_section423_reconstruction.R:174` | §4.2 `fig:specA_mu` |

All six route to a producing script and all six exist on disk. That is the good news, and it
is most of the good news.

---

## 2. Freshness — **severe**

Figure and script timestamps against the data each figure depends on:

| Figure | Figure written | Its input data written | Verdict |
|---|---|---|---|
| 1, 2 (US levels, US $\kappa$ bands) | **2026-07-25 17:11** | `us_staged_pending_conditioners.csv` — **2026-08-04 15:02** | **Figure predates its own input by 10 days** |
| 3, 4 (Chile levels, Chile $\kappa$ bands) | 2026-07-27 16:27 | S10 Chile capital panel | Stale relative to the August estimation tier |
| 5, 6 (elasticity, $\hat{\mu}$) | 2026-08-05 14:07 | S60 capacity CSVs — 2026-08-05 22:27 | **Figure predates the reconstruction CSVs by 8 hours** |

Every figure in the chapter was rendered before the data it visualises reached its current
state. For figures 1 and 2 this is unambiguous: the conditioner panel they plot was rebuilt on
4 August and the plots have not been regenerated since 25 July.

This is not a cosmetic problem. §4.1 presents these plots as the raw evidence the parametric
work is then fitted to. If the underlying series changed on 4 August, the visual-first argument
is being made from superseded data while the tables beside it are current.

**Established by:** filesystem mtimes, cross-checked against
`output/artifact_routing/artifact_routing_edges.csv` for the input paths each script reads.

---

## 3. Output format (C05 §9) — **4 of 6 fail**

C05 §9 requires paper-facing figures to be exported in **both** `.png` and `.pdf`.

| Figure | `.png` | `.pdf` |
|---|---|---|
| 1 `us_capital_levels_loess` | yes | **no** |
| 2 `us_tau_regime_bands` | yes | **no** |
| 3 `fig_cl_capital_levels_loess` | yes | **no** |
| 4 `fig_cl_kappa_regime_bands` | yes | **no** |
| 5 `fig6_transformation_elasticity_overaccumulation` | yes | yes |
| 6 `fig4_reconstructed_capacity_utilization` | yes | yes |

Only `US_S60_section423_reconstruction.R` emits both formats. `US_S38` and `CL_S20` emit PNG
only. The manuscript includes the PNG in all six cases, so nothing is broken today — but the
raster is the only copy for four figures, which forecloses vector rescaling at typesetting.

---

## 4. Visual consistency — **fails**

Measured from the files themselves (Pillow available; metrics are real, not inferred):

| Figure | Pixels | Aspect | DPI | `ggsave` call |
|---|---|---|---|---|
| 1 | 2850 × 1620 | 1.76 | 300 | `width = 9.5, height = 5.4, dpi = 300` |
| 2 | 2850 × 1620 | 1.76 | 300 | `width = 9.5, height = 5.4, dpi = 300` |
| 3 | 1776 × 983 | 1.81 | **240** | `width = 7.4, height = 4.1, dpi = 240` |
| 4 | 1776 × 1020 | 1.74 | **240** | `width = 7.4, height = 4.25, dpi = 240` |
| 5 | 2700 × 2250 | **1.20** | 300 | `width = 9, height = 7.5, dpi = 300` |
| 6 | 2700 × 1650 | 1.64 | 300 | `width = 9, height = 5.5, dpi = 300` |

Three problems, in descending order of visibility to a reader:

- **The Chilean figures are rendered at 240 dpi against 300 dpi for the US figures.** Since
  both are included at `width=0.85\textwidth`, the Chilean plots are physically the same width
  on the page but carry 38% fewer pixels per inch. Side by side in §4.1, the periphery is
  literally lower resolution than the centre. Given that §5's locked burden is to block a
  norm/deviation reading of the comparison, having the Chilean evidence render visibly coarser
  is the wrong kind of asymmetry to ship.
- **Four distinct canvas geometries** across six figures: 9.5×5.4, 7.4×4.1, 7.4×4.25, 9×7.5,
  9×5.5 inches. Figure 5 is nearly square (aspect 1.20) where its companions are wide.
- **Figures 3 and 4 differ from each other** (4.1 vs 4.25 inches tall) despite being a matched
  pair plotting the same object for the same country.

---

## 5. Notation lock (00S) — **1 fails**

`us_tau_regime_bands.png` carries $\tau$ in its filename. The notation lock retired $\tau_t$
and replaced it with $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$. The object plotted is
$\kappa_t$; the caption and the LaTeX label (`fig:us_kappa_bands`) are both correct. Only the
artifact filename, and the `png_fig2` variable in `US_S38_generate_us_only_figures.R`, still
say `tau`.

Note the Chilean counterpart was renamed: `fig_cl_kappa_regime_bands.png`. So the pair is
inconsistent with each other as well as with the lock — one side migrated, the other did not.

There is a second, older copy at `output/CL/figures/cl_tau_regime_bands.png` from the earlier
naming generation, which the manuscript does not use. See §7.

---

## 6. C05 protocol compliance — **fails across the board**

| C05 requirement | Status |
|---|---|
| §2 analytical status label on every figure | **Absent.** No figure declares whether it is diagnostic, paper-facing, robustness-only, or a restricted reconstruction. `US_S38` and `US_S60_section423` contain no status vocabulary at all; `CL_S20` has two incidental matches unrelated to figure status. |
| §6 recession-shading metadata (`recession_shading_source`, `_annualization`, `_role`, `_regime_classifier`) | **Absent.** Zero occurrences of `recession_shading` in any of the three producing scripts. Whether any of these figures shades recessions at all is therefore undocumented, and if one does, its annualization rule is unrecorded. |
| §7 anchor markers ($\mu_{1973} = 1$ for the US) | **Partially met.** `US_S60_section423_reconstruction.R` references 1973 in 22 places, so the anchor is present in the reconstruction logic. Whether Figure 6 marks it *visually* per §7 requires reading the plot, not the code. **Unverified.** |
| §10 caption/note language stating analytical status | **Absent** — see §7 below. |

---

## 7. LaTeX conventions (AGENTS.md, locked) — **6 of 6 fail one rule**

| Figure | Caption above graphic | `\label` present | **Bottom note** |
|---|---|---|---|
| all six | yes | yes | **no** |

The locked rule is *"Every table and figure must include a detailed note at the bottom."* Every
table fragment in the chapter complies. **No figure does.** The six figure environments carry a
caption and a label and nothing else.

This compounds §6: C05 §10 requires the note to state the figure's analytical status, and there
is no note to state it in.

---

## 8. Naming conventions — inconsistent

Three schemes across six files:

- `us_capital_levels_loess`, `us_tau_regime_bands` — country prefix, no `fig` token
- `fig_cl_capital_levels_loess`, `fig_cl_kappa_regime_bands` — `fig_` prefix, country second
- `fig4_reconstructed_capacity_utilization`, `fig6_transformation_elasticity_overaccumulation`
  — `fig<N>_` with a hardcoded number

The third is the most fragile: `fig4` and `fig6` embed a manuscript figure number in the
filename, and they are currently the *first two* figures of §4.2 and render as Figures 5 and 6
of the chapter. The numbers in the filenames refer to a document ordering that no longer
exists.

---

## 9. Near-twins and unchosen alternatives

Two figures exist in near-duplicate under the older naming generation, in a directory the
manuscript does not draw from:

| Manuscript uses | Near-twin not used |
|---|---|
| `output/CL/S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY/fig_cl_capital_levels_loess.png` | `output/CL/figures/cl_capital_levels_loess.png` |
| `output/CL/S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY/fig_cl_kappa_regime_bands.png` | `output/CL/figures/cl_tau_regime_bands.png` |

The `output/CL/figures/` pair is produced by `codes/CL_S44_generate_peripheral_figures.R` and
exists in both `.png` and `.pdf`, so it satisfies C05 §9 where the pair actually used does not.
Whether the S20 variant or the S44 variant is the right one is a substantive question about
which lane the chapter should draw its Chilean visual evidence from — not a naming detail.

---

## 10. Adjacent defects that bear on the figures

Not figure defects strictly, but they determine what figures the chapter can show.

- **Three Specification B figures exist but reach nothing.**
  `codes/US_S60_section32_reconstruction.R:196–260` writes
  `fig_specB_reconstructed_capacity_utilization`, `fig_specB_aggregate_elasticity_knife_edge`,
  and `fig_specB_aggregate_elasticity_zoomed` to the vault drafts directory, not to `output/`.
  The six files sitting in `output/US/S61_SECTION32_IMOLS/figures/` have no producer in the
  committed code.
- **The section that would cite them is not in the build.**
  `ch2_sec4_3_4.md` is absent from `compile_chapter2.py`'s `sec4_files` list, so §4.3 has no
  figures at all. Specification B — the chapter's central empirical specification — is
  currently presented without a single visual.
- **Chile has no reconstruction figure.** §4.4 carries tables only. §4.2 has two figures for
  Specification A; the peripheral case has none.

---

## 11. Two process hazards worth recording

- **The generated `.tex` files are being hand-edited.** `section3.tex` was modified
  2026-08-07 12:43 and `main.pdf` built from it at 12:46, after the last transpiler run on
  08-05. Running `python compile_chapter2.py` will silently destroy those edits, because it
  regenerates `section*.tex` wholesale from the vault markdown. Either the edits move back into
  the markdown sources, or the transpiler stops being run. Both are defensible; doing neither
  is not.
- **The Monte Carlo critical values are not reproducible.** `US_S52` and `US_S62` contain no
  `set.seed()`. The 100,000-pass simulation behind every significance star in the chapter
  cannot be reproduced to the exact value. This bears on figures indirectly: any figure
  plotting a starred quantity inherits the irreproducibility.

---

## 12. What a repair protocol would have to decide

Deliberately not decided here. Each is a genuine choice with a cost on both sides.

1. **Regeneration order.** Every figure is stale, so regeneration is unavoidable — but
   regenerating figures 1–2 requires re-running `US_S38` against the 4 August conditioner
   panel, which may change what the visual-first argument in §4.1 shows. Does the prose get
   written against the current figures, or do the figures get regenerated first and the prose
   written after?
2. **One canvas standard, or two.** A single geometry across all figures is cleaner, but
   Figure 5 is a two-panel plot that genuinely needs more vertical room. Standardise width and
   DPI only, and let height vary? Or force a common aspect and redesign Figure 5?
3. **Chilean DPI parity is not optional** given §5's anti-norm/deviation burden — but raising
   `CL_S20` to 300 dpi means re-running a script whose other outputs feed the BOP lane. Is the
   fix in `CL_S20`, or is the chapter's Chilean visual evidence re-sourced from `CL_S44`
   (which already emits PNG + PDF)?
4. **The `tau` filename.** Renaming the artifact breaks the `US_S38` script, the manuscript
   include path, and `FIGURE_PATHS.md`. Renaming is correct under the lock; the question is
   whether it happens now or at the next regeneration of that figure.
5. **Figure notes.** Six notes have to be written, each stating analytical status per C05 §10.
   Where do they live — in the vault markdown so the transpiler emits them, or hand-written
   into the `.tex`? This interacts directly with hazard 11.1.
6. **Specification B's missing figures.** Fix the script's output path, add `ch2_sec4_3_4.md`
   to the build, or both. Adding it to the build without fixing the path yields three broken
   includes.
7. **Whether Chile gets a reconstruction figure at all**, and if so from which lane.
8. **Whether `set.seed()` is added before or after the figures are regenerated** — adding it
   afterwards locks in an unreproducible baseline.

---

## Appendix: how this report was produced

- Producer edges: `output/artifact_routing/artifact_routing_edges.csv`, generated by
  `codes/COMMON_S00_artifact_routing_scan.py`.
- Freshness: filesystem mtimes of figures, producing scripts, and the input paths each script
  reads according to the edge ledger.
- Image metrics: Pillow, read directly from the PNG files.
- `ggsave` geometry: grepped from the three producing scripts.
- C05 compliance: keyword search for the metadata fields C05 §6 mandates, and for the §2 status
  vocabulary, in the producing scripts.
- LaTeX compliance: parsed `\begin{figure}` environments in `section*.tex` and `appendix*.tex`.

Nothing in this report was inferred from a figure's appearance; every claim rests on a file, a
timestamp, or a line of code. The one item marked **unverified** (§6, anchor markers) is marked
so precisely because settling it requires looking at the rendered plot.
