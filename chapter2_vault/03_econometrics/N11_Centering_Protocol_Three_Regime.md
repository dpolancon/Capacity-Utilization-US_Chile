---
type: econometrics
status: active
depends_on:
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-26
updated_by: PAPER_FACING_TERMINOLOGY_LOCK
layer: governance_constraint
role: centering-protocol
stage: pre-estimation-design
tags:
  - chapter2/econometrics
  - chapter2/centering
  - chapter2/imols-cpr
  - chapter2/robustness
aliases:
  - Centering protocol
  - Centering Treatment
  - Variable Centering Protocol
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# N11 — Centering Treatment & Variable Transformation Protocol for CPR IM-OLS

> [!IMPORTANT]
> **Paper-Facing Nomenclature Lock**: To prevent confusion between historical accumulation regimes (e.g., Fordism vs. Post-Fordism) and finite-sample numerical stabilization choices, the term "Centering Regime" MUST NOT be used in paper-facing tables, manuscripts, or reports.
> 
> The structural protocol row/header MUST be labeled **"Centering Treatment"** (or **"Variable Centering"**).
> The three specification variants are designated as:
> 1. **Uncentered** (Regime A: Raw uncentered levels)
> 2. **Initial-State** (Regime B: Initial-state centered $(x_t - x_1)$)
> 3. **Sample-Mean** (Regime C: Sample-mean centered $(x_t - \bar{x})$)

---

> ## ⚠️ SCOPE LIMIT ON §1, ESTABLISHED EMPIRICALLY 2026-07-30
>
> The Core Invariance Theorem below is **algebraically correct but conditional on a premise the
> pipeline's break-interacted designs violate**. Where the premise fails, the centering regime is a
> **model choice, not a conditioning choice** — it changes the estimates, and in the Spec B models it
> changes the *sign* of the parameters carrying H1 and H2. Evidence:
> `output/US/BREAK_AWARE_IMOLS/S33F_CENTERING_DIAGNOSTIC/csv/`, produced by
> `codes/US_S33F_centering_invariance_diagnostic.R`.
>
> **The premise.** §1's argument requires the design to span *all lower-order constituents* of every
> interaction. That holds for the $\{1, \tau, \omega, \tau\omega\}$ case §1 states. It does **not** hold
> once a break dummy enters multiplicatively. Centering expands
>
> $$(\kappa - \kappa_0)(\omega - \omega_0)D_t = \kappa\omega D_t - \kappa_0(\omega D_t) - \omega_0(\kappa D_t) + \kappa_0\omega_0 D_t$$
>
> so invariance additionally requires $\omega D_t$ **and** $\kappa D_t$ in the design.
> `US_S33D` carries $\kappa D_t$ (as $\delta_1$) but **not** $\omega D_t$; `US_S33E` carries **neither**.
> Both are therefore outside the theorem's scope.
>
> **Verified on synthetic data** (true DGP, $T=94$, OLS relative spread across the three regimes):
>
> | Design | OLS spread | Verdict |
> |---|---:|---|
> | $\{1,\kappa,\omega,\kappa\omega\}$ — §1's case | $6\times10^{-16}$ | invariant ✅ |
> | $+\ D_t,\ \kappa\omega D_t$ (our design shape) | $7.8\times10^{-2}$ | **not invariant** ❌ |
> | $+\ D_t,\ \kappa D_t,\ \omega D_t,\ \kappa\omega D_t$ | $6\times10^{-16}$ | invariant ✅ |
> | span broken *and* standalone $\kappa$ dropped (B4) | $7.1\times10^{-1}$ | **worst** ❌ |
>
> So §1 is exactly right within its scope, and completing the span restores it exactly under OLS.
>
> **Two things §1 does not cause.** (i) IM-OLS is not the culprit: on well-conditioned synthetic data
> it is invariant to ~0.3%. (ii) Ill-conditioning is not the culprit either: forcing the standardized
> condition number to 181 leaves the spread at 0.26%. A linear trend in the deterministic component
> does **not** fix it (median relative spread 1.98 → 1.64 on the real data).
>
> **On the real Spec B full-sample data**, completing the span does not restore *global* invariance
> (median relative spread across all parameters stays ~1.5), but it is decisive for the two parameters
> that carry the hypotheses. Sign stability across the three centering regimes:
>
> | Specification | $\hat\theta_{\omega\kappa}$ | $\hat\theta_{\kappa p^\kappa}$ |
> |---|---|---|
> | B4, span broken (current `US_S33E`) | [−19.60, +5.05] unstable ❌ | [−0.744, +2.083] unstable ❌ |
> | B4, span completed | [−15.06, +1.90] unstable ❌ | [−0.412, +1.081] unstable ❌ |
> | §3.2 form ($\theta_\kappa$ present), span broken | [−10.77, +3.66] unstable ❌ | [−1.024, +0.049] unstable ❌ |
> | **§3.2 form, span completed** | **[−13.82, −9.61] stable ✅** | **[−0.689, −0.558] stable ✅** |
>
> The §3.2-consistent design with the interaction span completed is the **only** configuration in which
> both are sign-stable — and $\hat\theta_{\kappa p^\kappa}$ then lands **negative**, as
> `ch2_sec3_2_heterogeneous_capital_prelatex.md` line 68 predicts. Restoring $\theta_\kappa$ and
> completing the span are jointly necessary; neither alone suffices.
>
> **Consequence for reporting.** Any Spec B estimate produced under a broken interaction span carries
> a centering-dependent sign and must not be quoted as evidence for or against H1 or H2. This affects
> the break-interacted columns of `US_S33D` and `US_S33E`, including figures already in the v7 report.
>
> **The gate that follows from this (added after `US_S33G` ran).** §1 itself states that centering
> changes "the point of evaluation for the baseline linear coefficients" — so base coefficients are
> *expected* to move, and any invariance test that averages over them is testing a claim §1 never
> makes. The operative gate is therefore **interaction-class parameters only**, and
> `specB5_centering_stability.csv` carries a `parameter_class` column so the carve-out lives in the
> data rather than in prose.
>
> Under that gate, Spec B5 (`codes/US_S33G_specB5_theory_consistent_full_sample.R`) **passes 7/7**.
> Interaction-class relative spreads run 0.018 ($\theta_{NRC}$) to 0.417, with every sign stable;
> base-class parameters move freely (1.49–3.00), exactly as §1 anticipates. Note the residual
> interaction spread is real and larger than the ~0.007 seen on synthetic data with a complete span —
> B5 is sign-identified, not exactly invariant, and should be described that way.
>
> §1 below is retained unedited; it is correct within its stated scope.

## 1. Core Invariance Theorem

For any Cointegrating Polynomial Regression (CPR) model with interaction terms, the estimated interaction coefficient $\hat{d}$ is **mathematically identical** across all scalar centering choices $c$:
$$ \tilde{\tau}_t = \tau_t - c_\tau, \qquad \tilde{\omega}_t = \omega_t - c_\omega $$

Because the design space $\{1, \tau_t, \omega_{t-1}, \tau_t \omega_{t-1}\}$ spans the exact same vector column space as $\{1, \tilde{\tau}_t, \tilde{\omega}_{t-1}, \tilde{\tau}_t \tilde{\omega}_{t-1}\}$, lower-order drifts ($c_\tau \tilde{\omega}_{t-1}$ and $c_\omega \tilde{\tau}_t$) are automatically absorbed by linear regressors in multiple regression mechanics. 

Only two features change across centering treatments:
1. The **numerical conditioning** (condition number) of the design matrix in finite samples.
2. The **point of evaluation** for the baseline linear coefficients ($\hat{\psi}, \hat{f}$).

---

## 2. The Three Centering Treatments

### Treatment 1: Uncentered (Raw Levels Baseline)
*   **Transformation:** Raw variables $k_t, \tau_t, \omega_t, \tau_t \omega_{t-1}$.
*   **Base Coefficient Interpretation:** Linear parameters evaluate at $\omega_t = 0$. Since zero wage share is unfeasible, linear terms have no standalone structural interpretation.
*   **Paper-Facing Designation:** `Uncentered` or `Raw Levels`.
*   **Numerical Requirement:** Requires QR or SVD matrix decomposition.

### Treatment 2: Initial-State (Primary Structural Benchmark)
*   **Transformation:** $\tilde{\tau}_t = \tau_t - \tau_1$, $\tilde{\omega}_t = \omega_t - \omega_1$.
*   **Base Coefficient Interpretation:** Linear parameters evaluate at the **historical starting state** ($\omega_1$, e.g., dawn of Fordism).
*   **Paper-Facing Designation:** `Initial-State` or `Initial-State Centered`.
*   **Role:** Primary structural robustness benchmark:
    1. Aligns with canonical Brownian motion initialization ($B(0) = 0$).
    2. Avoids forward-looking statistical artifacts ($\bar{\omega}$ using future data).
    3. Maps directly to path-dependent historical divergence driven by class distribution.

### Treatment 3: Sample-Mean (Secondary Robustness Benchmark)
*   **Transformation:** $\tilde{\tau}_t = \tau_t - \bar{\tau}$, $\tilde{\omega}_t = \omega_t - \bar{\omega}$.
*   **Base Coefficient Interpretation:** Linear parameters evaluate at sample mean $\bar{\omega}$.
*   **Paper-Facing Designation:** `Sample-Mean` or `Sample-Mean Centered`.

---

## 3. Paper-Facing Table Presentation Contract

In all LaTeX regression tables:
- **Table Control Row Header**: Labeled **"Centering Treatment"** (or **"Variable Centering"**).
- **Cell Values**: Labeled `Uncentered`, `Initial-State`, `Sample-Mean`.
