# Critical Replication Pipeline (Stage 4)
## Run Manifest and Repo Structure (Repo README)

This repository implements a **full-grid** critical replication pipeline (“Shaikh’s world”), with **reduced-dimensional reporting** via fit–complexity frontiers and crosswalk tables.

The goal is not “find the true model.” The goal is to **map model-selection uncertainty** across:
- **ARDL grid**: \((p,q)\)
- **VECM grid (bivariate)**: \((p, q\_profile)\) with **rank fixed at \(r=1\)**
- **VECM grid (trivariate + distribution)**: \((p, q\_profile, r)\) with **\(r\in\{0,1,2\}\)** and  
  \(X_t=(\ln Y_t,\ln K_t,\ln e_t)'\)

---

## Non-negotiable locks (binding constraints)

1) **Full grids** are computed for all exercises (no “shrunk candidate sets” in computation).  
2) **Envelope (upper frontier)** is computed and plotted for every fit–complexity plane.  
3) Primary complexity diagnostics are **ICOMP/RICOMP penalty components only**:
   - `ICOMP_pen`
   - `RICOMP_pen`
   Baseline ICs (AIC/BIC/HQ/AICc) may be recorded as comparators but are not the primary diagnostic.
4) **Post-faithful replication:** no dummy-placement stress tests. Dummies appear only “as reported” in faithful replication.  
5) Distributive variable in the m=3 extension: **e (rate of exploitation)**, default transformation **\(\ln e\)**.  
6) Terminology: use **“slope”** (avoid jargon like “tilt”).  
7) Crosswalks are fixed (see below).

---

## Crosswalks (locked)

### A) Memory allocation crosswalk
A comparable scalar “K-memory share” is defined across model classes:

- **ARDL:**  
  \[
  s_K^{ARDL} = \frac{q}{(p-1)+q}
  \]
- **VECM:** `share_K^{VECM}` from Γ-norm shares (short-run matrices)

**Primary crosswalk:**  
\(
s_K^{ARDL} \leftrightarrow share_K^{VECM}
\)

### B) Rank>1 stabilization collapse (normalization-safe)
Avoid α-only scalarization (normalization sensitive). Use:

- \(\Pi=\alpha\beta'\) (rank-invariant)
- stable eigenvalue moduli from companion roots \(|\lambda_j|<1\)

Define:
- decay weights: \(d_j=-\log(|\lambda_j|)\)
- speed summary: \(D=\mathrm{mean}(d_j)\)
- correction strength (output-relevant): \(S_Y = \|e_Y'\Pi\|_2\)  
  (or system-wide \(S=\|\Pi\|_F\))
- stabilization index: \(SI_Y = D\cdot S_Y\) (or \(SI=D\cdot S\))

Inference (optional in Stage 4 reporting): delta method with numerical gradient; note fragility when roots are near-repeated or near 1.

---

## Required deliverables (Stage 4 outputs)

### 1) Cell-level “geometry cards” (full grid export)
Every evaluated cell writes one row to a geometry-card table. NA is allowed where not defined (e.g., `lambda` in VECM).

Minimum shared columns:
- identifiers: `exercise_id`, `window_tag`, `m`, `p`, `q` (ARDL) or `q_tag/qY/qK` (VECM), `r` (if applicable), `det_tag`, `cell_id`
- fit: `logLik`, `T_eff`, `T_eff_common` (if enforced)
- count complexity: `k_total`
- entanglement complexity: `ICOMP_pen`, `RICOMP_pen`
- slope: `slope_hat` (θ for ARDL; θ_hat from β-normalization for VECM)
- adjustment: `lambda` (ARDL) or `alpha_y`, `alpha_k`, `alpha_e` (VECM)
- memory allocation: `sK_ardl` (ARDL) or `share_K` (VECM)
- stability: `stability_margin`, `unit_root_mismatch`, `unstable_count`; and `SI_Y` when \(r>1\)
- boundary tags: `boundary_p`, `boundary_q`, `boundary_r`

### 2) Mandatory frontiers (three planes, envelope binding)
For each exercise grid, produce **three** frontier plots and write the corresponding envelope tables:

Planes:
1) `logLik` vs `k_total`
2) `logLik` vs `ICOMP_pen`
3) `logLik` vs `RICOMP_pen`

Envelope definition (deterministic):
- sort x ascending
- for each x, keep the point with max logLik
- envelope points are those that set a new running maximum in logLik as x increases
- connect envelope points in increasing x order (line through envelope points)

### 3) Crosswalk tables (reduced-dimensional synthesis)
Generate a crosswalk table aligning representative specs across:
- faithful ARDL(2,4)
- ARDL frontier representatives
- VECM r=1 frontier representatives
- VECM r=2 frontier representatives (m=3)

Crosswalk columns:
- slope_hat, adjustment, memory share
- fit + complexity coordinates (logLik, k_total, ICOMP_pen, RICOMP_pen)
- rank + stability summary (r, stability_margin, SI_Y)
- boundary tags

---

## Canonical repo layout (recommended)

```
codes/
  10_config.R
  20_shaikh_ardl_replication.R
  21_CR_ARDL_grid.R
  22_VECM_S1.R
  23_VECM_S2.R
  24_complexity_penalties.R
  25_envelope_tools.R
  26_crosswalk_tables.R
  27_run_stage4_all.R
  99_utils.R

data/
  raw/
    Shaikh_RepData.xlsx
  processed/                                       # optional

output/
  CriticalReplication/
    Exercise_a_ARDL_faithful/
        csv/ figs/ logs/
    Exercise_b_ARDL_grid/
        csv/ figs/ logs/
    Exercise_c_VECM_S1_r1/
        csv/ figs/ logs/ branches/
    Exercise_d_VECM_S2_m3_rank/
        csv/ figs/ logs/
    Crosswalk/
        csv/ figs/ logs/
    Manifest/
        RUN_MANIFEST_stage4.md
        RUN_MANIFEST_stage4.csv                     # optional
```

Canonical convention: active Stage-4 scripts are named with the `2*` sequence and are resolved from `codes/` (no `codes/critical_replication/` runtime path).

**Canonical rule:** active pipeline scripts live in `codes/` root; subfolders are archival or domain-specific modules only.

---

## How to run (Stage 4)

Recommended: one runner that executes the whole pipeline end-to-end.

### Option A (preferred): run the single runner
```
Rscript codes/27_run_stage4_all.R
```

### Option B: run modules in order
1) faithful ARDL “as reported”
```
Rscript codes/20_shaikh_ardl_replication.R
```
2) ARDL full grid
```
Rscript codes/21_CR_ARDL_grid.R
```
3) bivariate VECM S1 (r=1) full grid
```
Rscript codes/22_VECM_S1.R
```
4) trivariate VECM rank grid (m=3, r∈{0,1,2})
```
Rscript codes/23_VECM_S2.R
```
5) crosswalk tables + final artifacts
```
Rscript codes/26_crosswalk_tables.R
```

---

## Run Manifest (Stage 4)

A run writes:
- `output/CriticalReplication/Manifest/RUN_MANIFEST_stage4.md`
- optionally: `RUN_MANIFEST_stage4.csv`

### Required manifest fields

**Header**
- Run ID
- Timestamp (ISO 8601)
- Timezone
- Machine/OS info
- Git commit hash (if available)
- Seed used (from config)

**Inputs**
- Dataset path + sheet name
- Variable columns used (Y_nom, K_nom, p_index, u_shaikh, e)
- Window tag and years
- Deterministic settings per exercise

**Scripts executed**
For each script:
- script name + relative path
- key grid dimensions (p range, q range / q_profiles, r range)
- outputs written (folders + key filenames)

**Output index (canonical artifacts)**
List paths relative to repo root, including:
- geometry cards CSVs per exercise
- envelope tables (three per exercise)
- frontier plots (three per exercise)
- crosswalk table(s) and main-text-ready figures

**R session snapshot**
- R version
- package versions (ARDL, tsDyn, robust covariance tools, etc.)
- sessionInfo() saved to `logs/SESSIONINFO.txt` (recommended) and referenced

**Deviations and notes**
- any data substitutions (e.g., common numeraire choices)
- scope locks enforced (e.g., no post-faithful dummy stress tests)

---

## Notes on interpretation discipline (paper-facing)
- Frontiers visualize how fit is “purchased” with complexity or parameter entanglement.
- Selection is treated as **choice under uncertainty**; report envelopes + ambiguity neighborhoods rather than a single “winner = truth.”
- In rank>1 systems, scalar stability summaries must be normalization-safe (use \(\Pi\) and roots, not α alone).
