# Chile Stage A — Results Package Manifest

**Generated:** 2026-04-08
**Script:** `codes/stage_a/chile/30_results_package.py`
**Data source:** `output/stage_b/Chile/csv/` (all estimation CSVs) + `data/processed/Chile/ECT_m_stage1.csv`

---

## Figures

All figures are title-free; captions and notes are applied directly in LaTeX.

| File | Format | Section | Description |
|------|--------|---------|-------------|
| `figs/fig1_ECTm_threshold.pdf` | PDF (vector) | §2.8.2 | ECT_m time series with threshold shading. Regime 2 (BoP binding) years shaded red; dashed line = estimated threshold gamma_hat = −0.139. |
| `figs/fig1_ECTm_threshold.png` | PNG 300 dpi | §2.8.2 | Raster copy of above for slides / preview. |
| `figs/fig2_theta_CL.pdf` | PDF (vector) | §2.8.2 | theta^CL distribution-composition transformation elasticity, 1920–2024. Period-colored. Harrodian knife-edge (theta=1) and US Fordist reference (theta_bar=0.787) marked. |
| `figs/fig2_theta_CL.png` | PNG 300 dpi | §2.8.2 | Raster copy. |
| `figs/fig3_regime_classification.pdf` | PDF (vector) | §2.8.2 | Regime classification overlay on ECT_m. Red filled = Regime 2 (binding); blue hollow = Regime 1 (slack). Key period annotations. |
| `figs/fig3_regime_classification.png` | PNG 300 dpi | §2.8.2 | Raster copy. |
| `figs/fig4_mu_CL.pdf` | PDF (vector) | §2.8.2 | mu^CL capacity utilization, 1920–2024. Period-colored. Pin year (1980 = 1.0) marked. Identification window boundary at 1978. |
| `figs/fig4_mu_CL.png` | PNG 300 dpi | §2.8.2 | Raster copy. |
| `figs/figA1_ssr_surface.pdf` | PDF (vector) | Appendix | CLS grid search SSR surface. Vertical dashed line = SSR-minimizing gamma_hat. |
| `figs/figA1_ssr_surface.png` | PNG 300 dpi | Appendix | Raster copy. |
| `figs/figA2_bootstrap_LR.pdf` | PDF (vector) | Appendix | Bootstrap LR null distribution (999 replications). Observed LR statistic and p-value annotated. |
| `figs/figA2_bootstrap_LR.png` | PNG 300 dpi | Appendix | Raster copy. |

**Recommended usage:** Use PDF versions in LaTeX (`\includegraphics`). Use PNG for presentations, README previews, or non-LaTeX contexts.

---

## Chapter Body Tables

| File | Section | Description |
|------|---------|-------------|
| `tables/tab1_standardized_impacts.csv` | §2.8.2 | Standardized impacts across three structural channels (zeta_1: machinery accumulation, zeta_2: non-reinvested surplus, zeta_3: wage share) for pre-1973 and post-1973 sub-samples. Columns: channel, coefficient, regressor SD, standardized impact per regime. |
| `tables/tab2_theta_mu_period_averages.csv` | §2.8.2 | Period averages of theta^CL and mu^CL across Pre-ISI, ISI, Crisis, and Neoliberal eras. |
| `tables/tab3_shadow_price_test.csv` | §2.8.2 | Shadow price (Tavares channel) test: alpha loadings on output equation across regimes. Reports whether Regime 2 alpha attenuates relative to Regime 1 (shadow_price_confirmed) and slowdown factor. |

---

## Appendix Tables

| File | Description |
|------|-------------|
| `tables/tabA1_stage1_johansen_trace.csv` | Johansen trace test statistics for both sub-samples (pre-1973, post-1973). Includes critical values at 10%, 5%, 1% and rejection decisions. |
| `tables/tabA2_stage1_alpha_weakexog.csv` | Stage 1 alpha (speed-of-adjustment) loadings merged with weak exogeneity LR test results per variable per regime. |
| `tables/tabA3_stage2_alpha_loadings.csv` | Stage 2 full alpha matrix: loadings for all equations across both regimes with standard errors, t-statistics, and regime differentials. |
| `tables/tabA4_structural_params.csv` | Structural parameters: theta_0 (infrastructure elasticity), psi (machinery elasticity), theta_2 (distribution-composition interaction), kappa_1 (intercept). All ISI-identified. |
| `tables/tabA5_pin_sensitivity.csv` | Pin-year sensitivity analysis: ISI, Crisis, and Neoliberal period mean mu^CL under alternative pin-year/pin-value configurations (1978/0.95, 1979/1.0, 1980/1.0, 1981/1.0). |

---

## Notes

- **No titles on figures.** All captions and notes should be added in LaTeX `\caption{}` blocks.
- **Period color scheme:** Pre-ISI = `#6baed6`, ISI = `#2171b5`, Crisis = `#cb181d`, Neoliberal = `#fc8d59`.
- **Threshold locked:** gamma_hat = −0.1394 (from CLS grid search).
- **Pin year:** mu(1980) = 1.0 (Ffrench-Davis 2002).
- **Notation compliance:** mu_t for capacity utilization (never "u"), theta for transformation elasticity.
