# Notebook 1: Why the Empirical Strategy Was Redesigned
## Chilean Productive Frontier — Stage 2 Empirical Architecture

**Status:** Post-redesign documentation | **Date:** 2026-04-07
**Authority:** Ch2_Outline_DEFINITIVE.md + log_empirical_strategy_override_chile_2026-04-06.md

---

## 1.1 What the original strategy proposed

The locked architecture (2026-04-06) specified a two-stage empirical design:

- **Stage 1**: Johansen VECM on $(m_t, k_t^{ME}, nrs_t, \omega_t)$ → extract $\widehat{ECT}_{m,t}$ as proxy for shadow price $\lambda$
- **Stage 2**: Threshold VECM on $(y_t, k_t^{NR}, k_t^{ME}, \omega_t k_t^{ME})$ using $\widehat{ECT}_{m,t-1}$ as the external regime classifier

The theoretical logic was sound: ECT_m identifies the BoP disequilibrium; when it exceeds threshold $\hat{\gamma}$, the shadow price $\lambda > 0$ activates, compressing the feasible mechanization path and thereby the transformation elasticity $\theta^{CL}$.

---

## 1.2 Constraint 1: tsDyn package — external classifier not supported

The `TVECM()` function in tsDyn hardcodes its own internal ECT as the threshold
transition variable. There is no `thVar` argument in `TVECM()`. The package
author confirmed this directly:

> *"In TVECM, the threshold variable is the ECT itself, and there is no option
> to have an external transition variable."* — Stigler (tsDyn mailing list, 2011)

`TVAR()` does accept an external `thVar`, but the source code of `TVAR.boot()`
explicitly stops with:

```r
stop("Cannot (yet) bootstrap model with external thVar or commonInter")
```

meaning bootstrap inference — the only valid inferential procedure for the
threshold parameter — is disabled for the external classifier case. This rules
out TVAR as a substitute.

**Resolution:** Implement the CLS (Conditional Least Squares) estimator
manually. For fixed $\beta$ (from Johansen MLE, super-consistent) and fixed
$\gamma$, the two-regime VECM is a linear OLS problem. Grid search over
$\gamma \in \text{quantiles}(\widehat{ECT}_{m,t-1})$ finds the SSR-minimizing
threshold. Bootstrap inference proceeds by resampling from the linear VECM
under the null of linearity. This is the Hansen-Seo (2002) CLS estimator
applied with an external pre-estimated transition variable, which Gonzalo and
Pitarakis (2006) and Krishnakumar and Neto (2009) term "cointegration with
threshold effects."

---

## 1.3 Constraint 2: Structural collinearity in the original state vector

The original state vector $(y_t, k_t^{NR}, k_t^{ME}, \omega_t k_t^{ME})$ has
a collinearity problem that is structural, not incidental.

$k_t^{NR}$ and $k_t^{ME}$ share a common I(1) stochastic trend driven by
aggregate capital accumulation. Under the choice-of-technique relation in §3.5,
the two capital stocks are jointly accumulated: ISI-era investment pushes both
simultaneously. Their long-run correlation is high — in the Chilean panel,
$\text{cor}(k^{NR}, k^{ME}) \approx 0.97$ over 1940–1972.

The consequence is that the Johansen MLE on the original vector cannot reliably
identify $\theta_0$ (infrastructure elasticity) and $\psi$ (machinery elasticity)
separately, even though the linear combination $\theta_0 k^{NR} + \psi k^{ME}$
(the productive frontier) may be well-identified. The collinearity inflates the
standard errors on both coefficients and can produce sign reversals in individual
components.

This is particularly damaging because the central identification target —
$\hat{\theta}^{CL}(\omega_t, \phi_t) = \hat{\theta}_0 + \hat{\psi}\phi_t +
\hat{\theta}_2\omega_t\phi_t$ — requires separating $\theta_0$ from $\psi$
to evaluate the machinery productivity premium $\psi > \theta_0$ (the Kaldor
hypothesis). If the two cannot be identified individually, the post-estimation
formula collapses.

---

## 1.4 The redesign: sum-and-difference reparameterization

The fix is to reparameterize the state vector into orthogonal components:

$$k_t^{CL} = \ln(K_t^{NR} + K_t^{ME}) \qquad \text{(common capital trend)}$$

$$c_t = k_t^{ME} - k_t^{NR} \qquad \text{(log-composition ratio)}$$

These are orthogonal by construction. $k^{CL}$ captures aggregate capital scale;
$c_t$ captures how far the composition has shifted toward machinery relative to
infrastructure. Their correlation is substantially lower than between $k^{NR}$
and $k^{ME}$ individually.

**Redesigned state vector:**

$$X_t^{CL,\theta} = (y_t,\; k_t^{CL},\; c_t,\; \omega_t c_t)'$$

The productive frontier in this reparameterization is:

$$y_t = \kappa_1 + A\,k_t^{CL} + B\,c_t + C\,(\omega_t c_t) + ECT_{\theta,t}$$

The structural parameters recover from the estimated $(A, B, C)$ as:

$$\theta_0 = A - B \qquad \psi = A + B \qquad \theta_2 = 2C$$

This is exact algebra — no approximation. The identification target is recovered:

$$\hat{\theta}^{CL}(\omega_t, \phi_t) = \hat{\theta}_0 + \hat{\psi}\phi_t + \hat{\theta}_2\omega_t\phi_t$$

---

## 1.5 What the redesign preserves and what it changes

| Object | Before redesign | After redesign |
|--------|----------------|----------------|
| Stage 1 | Unchanged | Unchanged |
| State vector | $(y, k^{NR}, k^{ME}, \omega k^{ME})$ | $(y, k^{CL}, c_t, \omega c_t)$ |
| Collinearity | High (cor≈0.97) | Low (by construction) |
| Estimator | `TVECM()` attempted | Manual CLS grid search |
| Threshold variable | ECT_m (external, blocked) | ECT_m (external, via manual CLS) |
| Central object | $\hat{\theta}^{CL}(\omega,\phi)$ | Same — now separably identified |
| Theoretical interpretation | Unchanged | Unchanged |
| $\hat{\mu}^{CL}$ construction | Pin 1980=1.0 | Same |

The redesign is an implementation correction, not a theoretical one. The
identification strategy, the shadow price narrative, the Kaldor mechanism, the
$\alpha^{(1)}$ vs $\alpha^{(2)}$ test — all preserved.

---

## 1.6 Notebook sequence

| Notebook | Content |
|----------|---------|
| **NB-01** (this) | Motivation: two constraints and the redesign logic |
| **NB-02** | Variable construction and full unit root battery |
| **NB-03** | Stage 1 recap — ECT_m as external classifier |
| **NB-04** | CLS threshold VECM — estimation and γ̂ identification |
| **NB-05** | Parameter recovery → $\hat{\theta}^{CL}(\omega_t,\phi_t)$ |
| **NB-06** | $\hat{\mu}^{CL}$ construction, pin year, and results |

---

*NB-01 | 2026-04-07 | Prereq for all subsequent notebooks*
