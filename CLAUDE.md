# CLAUDE.md — Capacity-Utilization-US_Chile
## Chapter 2: Reduced-Rank VECM | Track B Pipeline

**Dissertation**: *A Historical Trace of Capacity Utilization Measurements*
**Author**: Diego Polanco | UMass Amherst | Supervisor: Michael Ash
**Last updated**: 2026-03-15

---

## 1. What this repo is

This is the Chapter 2 empirical pipeline. The object of estimation is a
**five-dimensional (or six-dimensional) reduced-rank VECM with cointegration
rank r=3**, estimating nonlinear productivity-exploitation interactions in the
US corporate sector. This is NOT a replication of Shaikh — that lives in
Critical-Replication-Shaikh.

The theoretical specification is fully locked in
02_theoretical_estimation_blueprint.md (V2). All coding decisions trace back
to that document. Do not deviate without explicit instruction from Diego.

---

## 2. State vector and model identity

Base specification (m=5):
```
X_t = [y_t, k_t, k_t*e_t, k_t*e_t^2, e_t]
```

Extended specification (m=6, toggle-controlled):
```
X_t = [y_t, k_t, k_t*e_t, k_t*e_t^2, e_t, ln(p_Y/p_K)]
```

Variable definitions:
- y_t = ln(Y_t / p_Y): log corporate output deflated by output price
- k_t = ln(K_t / p_K): log corporate capital stock deflated by investment price
- e_t = (1 - omega_t)/omega_t: exploitation rate IN LEVELS (never log)
- ln(p_Y/p_K): log relative price of output to capital — enters X_t only if I(1)
- Interaction block (k_t*e_t, k_t*e_t^2) is structural — never remove it
- Structural break at 1973: Fordist (1947-1973) vs post-Fordist (1974-2007)

DEFLATOR RULE: Y and K use SEPARATE deflators (p_Y for output, p_K for
capital). This differs from Track A. The relative price p_Y/p_K is a
substantive variable, not a nuisance.

TOGGLE in 10_config_trackb.R:
  INCLUDE_REL_PRICE <- TRUE   # m=6, extended spec
  INCLUDE_REL_PRICE <- FALSE  # m=5, base spec
Both specs must be run and compared. Rank r=3 is pre-specified for base spec;
re-test rank under extended spec if INCLUDE_REL_PRICE = TRUE.

---

## 3. Repo structure
```
Capacity-Utilization-US_Chile/
├── scripts/
│   ├── track_b/          <- ACTIVE: M0-M13 pipeline
│   │   ├── 50_fetch_bea_corporate.R
│   │   ├── 51_build_corp_output.R
│   │   ├── 52_build_corp_kstock.R
│   │   ├── 53_build_corp_exploitation.R
│   │   ├── 54_assemble_corp_dataset.R
│   │   ├── 55_source_runner.R
│   │   ├── 97_kstock_helpers.R
│   │   ├── 99_figure_protocol.R
│   │   └── 99_utils.R
│   └── _archive_trackA/  <- READ-ONLY reference
├── data/
│   ├── raw/
│   ├── interim/
│   └── processed/
├── output/figures/
├── results/
└── docs/
```

---

## 4. Module pipeline (M0-M13)

| Module | File | Key decision |
|--------|------|-------------|
| M0 | M0_data_construction.R | Build X_t base + extended; construct k_t*e_t, k_t*e_t^2; build ln(p_Y/p_K) |
| M1 | M1_integration_tests.R | ADF/KPSS/Zivot-Andrews on ALL X_t components including products AND ln(p_Y/p_K); I(1) verdict on relative price gates INCLUDE_REL_PRICE |
| M2 | M2_concentration_step.R | R_0t, R_1t, S_00, S_01, S_11 |
| M3 | M3_eigenvalue_problem.R | Generalized eigenvalue decomp; no economic interpretation of unrestricted beta |
| M4 | M4_rank_ladder.R | Trace + max-eigenvalue; confinement contribution ratios rho_i; CVs from M13 |
| M5 | M5_unrestricted_vecm.R | Unrestricted (alpha, beta, Gamma) |
| M6 | M6_smooth_reproduction.R | Quadratic inversion for e_t^S; discriminant check Delta_t > 0 |
| M7 | M7_restricted_beta.R | 14 restrictions (5 over-identifying); switching algorithm |
| M8 | M8_restricted_alpha.R | Sparsity pattern a_1; weak exogeneity test |
| M9 | M9_hierarchical_beta2.R | Sequential + full-info beta2; generated regressor; CR check |
| M10 | M10_deterministic.R | Restricted constant; crisis dummy entry rule |
| M11 | M11_overid_diagnostics.R | Sequential LR tests; profile likelihood; binding set B |
| M12 | M12_robustness.R | Perturbation around Spec*; discriminant monitoring |
| M13 | M13_unified_bootstrap.R | Parametric bootstrap B=999/4999 |

Dependency graph:
M0 -> M1 -> M2 -> M3 -> M4
                  |
                  M5 -> M6 -> M9
                  |           |
                  M7 <--------+
                  |
                  M8 -> M10 -> M11 -> M12 -> M13

M13 feeds back: CVs -> M4; kappa* -> M11; GR validation -> M9; LR size -> M11

---

## 5. Hard constraints — never violate

- GATE: do NOT begin M0 until Track A S9 confirms e_corp loads on independent cointegrating vector
- e_t enters in levels, not logs — logistic properties are level properties
- Interaction block (k_t*e_t, k_t*e_t^2) is structural — never remove
- Rank r=3 is pre-specified for base spec; re-test only if relative price is I(1) and enters X_t
- I(1) test on ln(p_Y/p_K) in M1 is mandatory before setting INCLUDE_REL_PRICE
- CR threshold = 0.15 for generated regressor; if CR > 0.15 trigger M13 before proceeding
- Bootstrap B=999 screening / B=4999 publication — always set and report seed
- Critical values from M13 bootstrap ONLY — never use MHM (1999) tabulated values
- Structural break at 1973 is pre-specified — not a free estimation parameter
- All figures: save_png_pdf_dual() from 99_figure_protocol.R — no ad-hoc ggsave
- All deliverable documents: .md files only — never Word/docx

---

## 6. What NOT to do

- Do not apply common deflator to Y and K — they use separate deflators here
- Do not run Track A scripts (S0/S1/S2/ARDL) — those live in Critical-Replication-Shaikh
- Do not modify scripts/_archive_trackA/ — read-only
- Do not push directly to main — feature branches: track-b-M{n}-{label}
- Do not assign economic interpretation to unrestricted beta — output to M7 only (D2)
- Do not use MHM critical values — bootstrap only
