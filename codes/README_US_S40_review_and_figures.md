# US S40 Review and Figures Contract

## Purpose

This file defines the contract for:

`codes/US_S40_review_and_figures.R`

This stage reviews and visualizes the already-constructed S40 restricted B1 outputs.

It does not reconstruct new objects.

It does not modify the S40 reconstruction logic.

It does not move to S50.

---

## Binding inputs

Read only:

`output/US/S40_theta_tot_mu_reconstruction/`

Required files:

- `us_s40_theta_tot_path.csv`
- `us_s40_productive_capacity_path.csv`
- `us_s40_mu_path.csv`
- `us_s40_anchor_register.csv`
- `us_s40_fragility_register.csv`
- `us_s40_reconstruction_manifest.csv`

The script must stop if these files are missing.

---

## Required checks

The review must verify:

- `fragility_flag = TRUE`
- `s40_admissibility_status = admissible_restricted_b1_under_fragility`
- `dols_reconstruction_basis = FALSE`
- `dols_veto = FALSE`
- `mu_formula = Y_real / Yp`
- anchor window is `fordist_core`
- anchor years are 1945–1973
- anchor mean μ equals 1, up to rounding tolerance
- all μ values are finite
- all Yp values are finite and positive
- no Chile outputs are touched
- no profitability variables are computed

---

## Required outputs

Write only to:

`output/US/S40_review_and_figures/`

Required files:

- `us_s40_review_checks.csv`
- `us_s40_mu_summary.csv`
- `us_s40_theta_summary.csv`
- `us_s40_anchor_window_summary.csv`
- `US_S40_review_and_figures_report.md`

Required figures:

- `fig_us_s40_mu_path.png`
- `fig_us_s40_mu_path.pdf`
- `fig_us_s40_y_ycapacity_path.png`
- `fig_us_s40_y_ycapacity_path.pdf`
- `fig_us_s40_theta_tot_path.png`
- `fig_us_s40_theta_tot_path.pdf`

---

## Figure rules

Figures must be diagnostic and advisor-facing.

They must not claim clean benchmark status.

Every figure title or caption should indicate:

`restricted B1 under fragility`

The μ figure must show the anchor window visually or describe it in the figure note.

The Y/Yp figure must compare observed output and reconstructed productive capacity.

The θ figure must show reconstructed `theta_tot`, not `theta_M`.

---

## Interpretation rules

Allowed language:

- restricted B1 reconstruction
- fragility-aware S40 path
- FM-OLS-centered reconstruction
- DOLS carried as stress metadata
- utilization derived after productive capacity reconstruction and anchoring

Forbidden language:

- clean benchmark
- final utilization estimate
- DOLS reconstruction
- direct estimate of θ_M
- profitability result
- regime proof
- residual utilization

---

## Hard prohibitions

The script must not:

- estimate any new model
- alter S40 outputs
- change the anchor
- compute profitability
- touch Chile outputs
- create comparative outputs
- promote non-B1 specifications
- use DOLS as reconstruction basis
- infer θ_M as directly estimated

---

## Ready to code only if

- active branch is `feature/us-s40-restricted-b1`
- S40 reconstruction commit exists
- working tree is clean
- output is restricted to:

`codes/US_S40_review_and_figures.R`

and:

`output/US/S40_review_and_figures/`