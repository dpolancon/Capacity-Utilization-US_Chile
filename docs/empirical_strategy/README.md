# docs/empirical_strategy/README.md
## Chilean Stage 2 Empirical Strategy — Design Documentation

**Dissertation:** Chapter 2 — Capacity Utilization in the Center and the Periphery  
**Country:** Chile (peripheral case)  
**Strategy locked:** 2026-04-07  
**Authority:** `log_empirical_strategy_override_chile_2026-04-06.md`  
**Last commit adding these notebooks:** [insert hash after commit]

---

## What this folder documents

This folder contains the sequential narrative documentation of the redesigned
two-stage empirical strategy for identifying the Chilean productive frontier and
constructing the capacity utilization series $\hat{\mu}_t^{CL}$.

The notebooks are **not executable scripts**. They document the identification
logic, architectural decisions, and expected results that underpin the code in
`codes/stage_b/chile/`. Read them before running the estimation scripts. They
are the paper trail for the committee.

---

## The central identification object

$$\hat{\theta}^{CL}(\omega_t, \phi_t) = \hat{\theta}_0 + \hat{\psi}\,\phi_t + \hat{\theta}_2\,\omega_t\phi_t$$

This is the distribution-and-composition-conditioned transformation elasticity of
the peripheral productive frontier — equation (27) of §3.5 in the analytical
framework. Every notebook in this folder exists to document how this object is
identified from the data, and how it feeds into $\hat{\mu}_t^{CL}$.

---

## Notebook sequence

| File | Purpose |
|------|---------|
| `nb_01_redesign_motivation.md` | Why the strategy was redesigned: two architectural constraints and their solutions |
| `nb_02_unit_root_battery.md` | Variable construction for the reparameterized state vector; full unit root decision table |
| `nb_03_stage1_recap_ECTm.md` | Stage 1 results recap; why $\widehat{ECT}_{m,t-1}$ is a valid external classifier |
| `nb_04_cls_threshold_estimation.md` | CLS estimator logic; how $\hat{\gamma}$ is identified; shadow price test |
| `nb_05_parameter_recovery_theta.md` | Exact algebra: $(A, B, C) \to (\hat{\theta}_0, \hat{\psi}, \hat{\theta}_2)$; Kaldor hypothesis check |
| `nb_06_mu_construction_results.md` | $\hat{\mu}_t^{CL}$ closure; pin year 1980; chapter/appendix mapping; cross-country comparison |

Read in order. Each notebook states its prerequisite.

---

## The two redesign decisions

### Decision 1: CLS estimator instead of `TVECM()`

`TVECM()` in tsDyn hardcodes its own internal ECT as the threshold variable —
external classifiers are not supported. `TVAR()` accepts external `thVar` but
disables bootstrap inference for that case.

**Resolution:** Manual CLS (Conditional Least Squares) grid search. For fixed
$\hat{\beta}$ (Johansen MLE, super-consistent) and fixed $\gamma$, the two-regime
VECM is linear OLS. Grid search over $\gamma \in \text{quantiles}(\widehat{ECT}_{m,t-1})$
finds the SSR-minimizing threshold. Bootstrap inference under the null (linear VECM)
is valid. This follows Hansen-Seo (2002) CLS logic with external classifier per
Gonzalo-Pitarakis (2006) and Krishnakumar-Neto (2009).

**Code:** `codes/stage_b/chile/03_stage2_cls_tvecm.R`  
**Prompt:** `agents/claudecode_prompt_03_stage2_cls_v2.md`

### Decision 2: Reparameterized state vector to eliminate structural collinearity

The original state vector $(y, k^{NR}, k^{ME}, \omega k^{ME})$ has severe collinearity
between $k^{NR}$ and $k^{ME}$ ($r \approx 0.97$ in the ISI period). This prevents
separate identification of $\theta_0$ and $\psi$, which are required to compute
$\hat{\theta}^{CL}(\omega_t, \phi_t)$.

**Reparameterization:**

$$k_t^{CL} = \ln(K_t^{NR} + K_t^{ME}) \qquad c_t = k_t^{ME} - k_t^{NR}$$

**New state vector:** $(y_t, k_t^{CL}, c_t, \omega_t c_t)$

**Parameter recovery (exact algebra):**

| Estimated | Structural |
|-----------|-----------|
| $A = (\theta_0+\psi)/2$ | $\theta_0 = A - B$ |
| $B = (\psi-\theta_0)/2$ | $\psi = A + B$ |
| $C = \theta_2/2$ | $\theta_2 = 2C$ |

The post-estimation formula $\hat{\theta}^{CL}(\omega_t,\phi_t) = \hat{\theta}_0 + \hat{\psi}\phi_t + \hat{\theta}_2\omega_t\phi_t$ is unchanged.

---

## Identification chain

```
Stage 1 VECM on (m, k_ME, nrs, ω)
    → ECT_m,t  [proxy for shadow price λ]
    → R_t = 1[ECT_m,t-1 > γ̂]  [regime classifier]
          ↓
Stage 2 CLS on (y, k_CL, c_t, ω c_t)
    → CV1 coefficients (A, B, C)
    → θ_0 = A−B,  ψ = A+B,  θ_2 = 2C
    → θ̂^CL(ω_t, φ_t) = θ̂_0 + ψ̂φ_t + θ̂_2 ω_t φ_t
    → g_{Y^p,CL} = θ̂^CL(ω_t, φ_t) · g_{K^CL}
    → ĝ_μ = g_Y − g_{Y^p,CL}
    → μ̂^CL(1980) = 1.0  [Ffrench-Davis pre-crisis peak, assumed]
    → μ̂^CL_t  [full series 1920–2024]
```

---

## Corresponding execution files

| Notebook | Execution counterpart |
|----------|-----------------------|
| NB-01, NB-02 | `codes/stage_b/chile/03_stage2_cls_tvecm.R` (Steps 0–1) |
| NB-03 | `codes/stage_b/chile/02b_stage1_deliver.R` (Stage 1, completed) |
| NB-04 | `codes/stage_b/chile/03_stage2_cls_tvecm.R` (Steps 3–7) |
| NB-05 | `codes/stage_b/chile/03_stage2_cls_tvecm.R` (Steps 2–3) |
| NB-06 | `codes/stage_b/chile/03_stage2_cls_tvecm.R` (Steps 9–10) |

Output CSVs land in `output/stage_b/Chile/csv/`. Key files:

| CSV | Content |
|-----|---------|
| `stage2_ur_crosswalk.csv` | Integration order verdicts for all variables |
| `stage2_structural_params.csv` | $(A, B, C)$ and recovered $(\theta_0, \psi, \theta_2)$ |
| `stage2_theta_CL_series.csv` | $\hat{\theta}^{CL}(\omega_t,\phi_t)$ time series |
| `stage2_regime_classification.csv` | Year, $ECT_m$, $R_t$, regime label |
| `stage2_alpha_loadings.csv` | $\hat{\alpha}^{(1)}$, $\hat{\alpha}^{(2)}$, SEs, shadow price test |
| `stage2_panel_with_mu_v2.csv` | Full panel with $\hat{\mu}_t^{CL}$ |
| `stage2_ssr_grid.csv` | CLS grid search SSR surface |
| `stage2_LR_bootstrap.csv` | Bootstrap null distribution for linearity test |

---

## Stage 1 outputs (prerequisite — already completed)

Stage 1 is complete. Its deliverable — `data/processed/chile/ECT_m_stage1.csv` —
is a prerequisite input for Stage 2. Do not re-run Stage 1 without explicit
instruction. Key Stage 1 results are documented in NB-03 and in the locked
strategy log.

---

## What is NOT in this folder

- The theoretical derivation of §3.5 (see `Ch2_Outline_DEFINITIVE.md` and the
  analytical framework sections of `ch2_draft_v1.tex`)
- The US empirical strategy (see `us_structural_identification_v2.md`)
- Stage 1 VECM documentation (see `stage1_vecm_report.md` and the session logs
  from 2026-04-06/07)
- The ARDL behavioral investment function for Chile (Stage B — deferred)

---

*Strategy locked: 2026-04-07. Supersedes: `empirical_strategy_peripheral_Ch2_v3.md`,
`chile_structural_identification_v2.md`. Contact: Diego (dpolancon).*
