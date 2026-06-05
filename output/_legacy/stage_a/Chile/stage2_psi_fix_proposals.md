# Stage 2: Proposals to Fix the psi Identification Problem

**Date:** 2026-04-08
**Status:** Diagnostic — four proposals for resolving the collinearity-driven
misidentification of theta_0 and psi in the Chilean productive frontier.

---

## The Problem

The ISI-subsample Johansen (1940–1972, K=2, forced r=1) estimates the
productive frontier cointegrating vector:

$$y_t = 1.3369 \cdot k_t^{NR} + (-0.1759) \cdot k_t^{ME} + (-0.0260) \cdot \omega_t k_t^{ME} - 4.4412$$

| Parameter | Estimate | Expected sign | Status |
|-----------|----------|---------------|--------|
| theta_0 (k_NR) | +1.337 | > 0 | Satisfies |
| psi (k_ME) | **-0.176** | > 0 | **WRONG SIGN** |
| theta_2 (omega_kME) | -0.026 | < 0 | Satisfies |

The **cointegrating relation** is well-identified: ECT_theta is stationary
on the full sample (ADF tau = -4.22). The problem is the **decomposition**
of that relation into theta_0 and psi, driven by near-perfect collinearity:

$$\text{cor}(k_t^{NR}, k_t^{ME}) = 0.9881 \quad \text{(ISI subsample)}$$

The Johansen procedure cannot distinguish the marginal contribution of
infrastructure from that of machinery when the two stocks move in lockstep.
It allocates the entire joint capital effect to whichever variable has
marginally more explanatory power in the VAR dynamics — here k_NR — leaving
k_ME with a residual that happens to be negative.

### Consequences for theta_CL and mu_CL

The time-varying frontier elasticity is:

$$\hat{\theta}^{CL}_t = \hat{\theta}_0(1 - s_t^{ME}) + (\hat{\psi} + \hat{\theta}_2 \omega_t) \cdot s_t^{ME}$$

where $s_t^{ME} = K_t^{ME} / (K_t^{NR} + K_t^{ME})$ is the bounded
machinery share.

Within the ISI window, $s^{ME}$ ranges 0.25–0.35. The collinearity error
is contained: theta_CL stays in [0.83, 0.95] and mu_CL oscillates properly.

In the neoliberal era, $s^{ME}$ rises to 0.75. The negative psi receives
an increasingly large weight, dragging theta_CL down to 0.19 by 2024.
This makes g_Yp systematically too small, so mu_CL drifts monotonically
upward to 1.33 by 2024 — implying Chile permanently operates 33% above
productive capacity, which is economically implausible.

| Period | s_ME mean | theta_CL mean | mu_CL mean | g_mu mean | Regime 2 share |
|--------|-----------|---------------|------------|-----------|----------------|
| ISI (1940–72) | 0.302 | 0.876 | 0.866 | +0.005 | — |
| Chicago (1975–81) | 0.334 | 0.828 | 0.899 | +0.019 | 0/7 |
| Debt crisis (1982–85) | 0.340 | 0.818 | 0.858 | -0.040 | 4/4 |
| Recovery (1986–96) | 0.345 | 0.817 | 1.052 | +0.028 | 1/11 |
| Late neolib (1997–2024) | 0.618 | **0.355** | **1.188** | +0.004 | 27/28 |

The problem becomes acute after 1997 when s_ME accelerates past 0.45.

---

## Proposal A: Direct g_Yp from Beta (Skip theta_CL Entirely)

### Concept

Instead of collapsing the frontier through the s_ME-weighted theta_CL
formula, compute productive capacity growth directly from the estimated beta
applied to the actual capital stock growth rates:

$$g_{Y^p,t} = \hat{\theta}_0 \cdot \Delta k_t^{NR} + \hat{\psi} \cdot \Delta k_t^{ME} + \hat{\theta}_2 \cdot \Delta(\omega_t k_t^{ME})$$

This uses the same beta but avoids the s_ME approximation. The key insight
is that the **collinearity stabilizes the linear combination in first
differences**: since Δk_NR and Δk_ME co-move (the same correlation that
caused the identification problem), the frontier growth rate
$g_{Y^p} = 1.337 \cdot \Delta k^{NR} + (-0.176) \cdot \Delta k^{ME}$
may produce sensible values even when the individual coefficients are
unreliable, because the positive theta_0 on the dominant Δk_NR movement
compensates for the negative psi on the co-moving Δk_ME.

### Why it might work

The collinearity error is a *levels* problem. When k_NR and k_ME share a
common stochastic trend, the levels estimator cannot decompose the long-run
effect. But in first differences, the **growth rate decomposition** is less
sensitive to the coefficient allocation because Δk_NR ≈ Δk_ME in most years.

Consider: if Δk_NR ≈ Δk_ME ≈ g, then:

$$g_{Y^p} \approx (\theta_0 + \psi) \cdot g$$

The sum theta_0 + psi = 1.337 + (-0.176) = **1.161** is well-identified
(it's the total capital elasticity). This will produce a sensible g_Yp as
long as the two capital stocks grow at similar rates. The method fails only
when Δk_NR and Δk_ME diverge substantially — but that divergence is itself
limited by the physical composition of investment.

### What it changes

- **theta_CL is no longer computed** as a time-varying series
- The mu_CL construction becomes: g_mu = g_Y - theta_0 * Δk_NR - psi * Δk_ME - theta_2 * Δ(omega_kME)
- This removes the s_ME extrapolation channel that amplifies the error
- The structural interpretation of theta_CL(omega, phi) as a composition-conditioned elasticity is **lost** — the narrative must work with g_Yp directly

### Implementation

```r
df <- df %>% mutate(
  g_kNR    = c(NA, diff(k_NR)),
  g_kME    = c(NA, diff(k_ME)),
  g_omgkME = c(NA, diff(omega_kME)),
  g_Yp_A   = theta_0_ISI * g_kNR + psi_ISI * g_kME + theta_2_ISI * g_omgkME,
  g_mu_A   = g_Y - g_Yp_A
)
```

### Strengths

- Immediate fix, no re-estimation
- Uses the well-identified cointegrating vector directly
- Collinearity error is self-correcting when Δk_NR ≈ Δk_ME
- Preserves the CLS/shadow price results (those don't depend on theta_CL)

### Limitations

- Loses the compositional narrative (theta_CL as a function of phi and omega)
- The error does **not** cancel in years when Δk_NR and Δk_ME diverge significantly (e.g., the post-1997 machinery surge)
- Still relies on the same contaminated beta — the error is dampened, not eliminated
- Cannot say "when machinery share crosses X%, the frontier elasticity falls below 1" — only "in year t, frontier grew at Y%"

### Risk assessment

**Low risk.** Even if g_Yp_A still drifts, the drift will be smaller than
the s_ME-weighted version because the difference channel is more stable.
If it works, this is the right answer for the chapter: compute mu from
g_Yp directly, report theta_CL as an illustrative decomposition only for
the ISI window.

---

## Proposal B: Homogeneous Capital Restriction

### Concept

Test whether theta_0 and psi are statistically distinguishable. If not,
impose theta_0 = psi = theta (homogeneous capital), collapsing the frontier
to a single aggregate capital elasticity:

$$y_t = \theta \cdot k_t^{CL} + \theta_2 \cdot \omega_t k_t^{ME} + \kappa_1$$

where $k_t^{CL} = \ln(K_t^{NR} + K_t^{ME})$ is total non-residential
capital.

### Formal test

Use `blrtest()` from urca to test the restriction on the cointegrating
vector:

$$H_0: \beta_{k_{NR}} = \beta_{k_{ME}}$$

This is a linear restriction on beta that can be tested as a likelihood
ratio with one degree of freedom. Under H0, the restricted beta has
`beta_kNR = beta_kME = -theta` (with appropriate sign convention).

### Implementation

```r
# Restriction matrix H: beta = H * phi (where phi is the restricted vector)
# Original beta = (1, beta_kNR, beta_kME, beta_omgkME, beta_const)'
# Restriction: beta_kNR = beta_kME
# H maps: (1, theta, theta, beta_omgkME, beta_const)' = H %*% (1, theta, beta_omgkME, beta_const)'

H <- matrix(c(1, 0, 0, 0,
              0, 1, 0, 0,
              0, 1, 0, 0,
              0, 0, 1, 0,
              0, 0, 0, 1), nrow=5, ncol=4, byrow=TRUE)

bl_test <- blrtest(jo_isi, H = H, r = 1)
cat(sprintf("LR stat: %.4f, p-value: %.4f\n", bl_test@teststat, bl_test@pval))
```

If p > 0.05, the restriction is not rejected, and we adopt the homogeneous
capital model. The restricted theta is approximately the weighted average
of theta_0 and psi evaluated at s_ME = 0.30 (ISI mean):

$$\theta \approx 1.337 \times 0.70 + (-0.176) \times 0.30 \approx 0.883$$

### What it changes

- theta_CL becomes: theta_CL = theta + theta_2 * omega * s_ME
- With theta ≈ 0.88 and theta_2 = -0.03, theta_CL ≈ 0.87 across all periods
  (very small variation from the omega * s_ME interaction)
- mu_CL will oscillate around 1.0 with minimal drift because the dominant
  component is the stable theta applied to g_K_CL
- The structural narrative changes: there is no separate infrastructure vs
  machinery channel — only a single capital productivity that is marginally
  modulated by distribution

### Strengths

- Econometrically honest: acknowledges the data cannot distinguish theta_0
  from psi and imposes the minimal restriction
- Produces a stable mu_CL series across the full sample
- The theta ≈ 0.88 is economically plausible (sub-Harrodian, consistent
  with the surplus-absorption-dependent frontier of §3.5)
- The blrtest() provides a formal statistical justification

### Limitations

- Loses the Kaldor hypothesis entirely: cannot say "machinery has higher
  productivity than infrastructure"
- The composition channel (s_ME) enters only through the small theta_2
  interaction — the main source of time variation in the frontier is gone
- If the true DGP has psi ≠ theta_0, the restriction imposes a bias;
  but this bias is smaller than the collinearity-driven bias in the
  unrestricted estimates
- Requires the ISI Johansen object to run blrtest(), which means the
  test must be implemented in the estimation script

### Risk assessment

**Low risk.** If the restriction is not rejected (highly likely given
cor = 0.99), this provides a clean, defensible theta with correct
statistical properties. The narrative cost is that the composition-dependent
frontier becomes flat — but this may be the honest result for Chile.

---

## Proposal C: Two-Point Identification from the Aggregate

### Concept

The well-identified object is the **aggregate frontier elasticity** at a
given composition point:

$$\theta^{agg}(s) = \theta_0(1-s) + \psi \cdot s + \theta_2 \omega s$$

At the ISI mean (s = 0.30, omega = 0.57), Johansen gives:

$$\theta^{agg}(0.30) = 1.337 \times 0.70 + (-0.176) \times 0.30 + (-0.026) \times 0.57 \times 0.30 = 0.878$$

This is one equation in two unknowns (theta_0, psi). We need a **second
identifying equation** from outside the cointegrating system.

### Source 1: Stage 1 Kaldor prior (zeta_1 = 0.93)

The Stage 1 import propensity VECM estimated zeta_1 = 0.93 for the ISI
era — the long-run elasticity of imports with respect to machinery capital.
Tavares (1972) argues this captures the structural import dependence of
machinery accumulation: each 1% of machinery investment requires 0.93%
additional imports.

**Identifying assumption:** The import elasticity of machinery reflects
the marginal productivity differential. If machinery is more productive
(Kaldor hypothesis), it draws more imports per unit of accumulation. Under
the additional assumption that the import elasticity is proportional to the
capital productivity ratio:

$$\frac{\psi}{\theta_0} \approx \zeta_1 \quad \Rightarrow \quad \psi \approx 0.93 \cdot \theta_0$$

Combined with the aggregate equation:

$$\theta_0(1 - s) + 0.93 \theta_0 \cdot s + \theta_2 \omega s = 0.878$$

$$\theta_0 [1 - s + 0.93 s] + \theta_2 \omega s = 0.878$$

$$\theta_0 [1 - 0.07 \times 0.30] + (-0.026)(0.57)(0.30) = 0.878$$

$$\theta_0 \times 0.979 - 0.0044 = 0.878$$

$$\theta_0 = 0.901 \quad \Rightarrow \quad \psi = 0.838$$

### Source 2: Neoliberal-era aggregate as second equation

Alternatively, if we trust the cointegrating relation to hold in the
neoliberal era (ECT is stationary), we can evaluate the aggregate at the
neoliberal mean (s = 0.54, omega = 0.41):

$$\theta^{agg}(0.54) = \theta_0 \times 0.46 + \psi \times 0.54 + (-0.026) \times 0.41 \times 0.54$$

The problem is that we don't know theta^agg(0.54) independently — it's what
we're trying to identify. We would need a separate estimate of frontier
growth in the neoliberal era (e.g., from an HP filter or production function
estimate) to pin it.

### Implementation (Kaldor prior)

```r
# Two-point identification: zeta_1 = psi / theta_0
zeta_1 <- 0.93   # from Stage 1 ISI
s_bar  <- mean(df$s_ME[df$year %in% 1940:1972])
omega_bar <- mean(df$omega[df$year %in% 1940:1972])
theta_agg_ISI <- 0.878  # from Johansen aggregate at ISI mean

# Solve: theta_0 * [1 - s_bar + zeta_1 * s_bar] + theta_2 * omega_bar * s_bar = theta_agg
theta_0_C <- (theta_agg_ISI - theta_2_ISI * omega_bar * s_bar) /
             (1 - s_bar + zeta_1 * s_bar)
psi_C     <- zeta_1 * theta_0_C

cat(sprintf("theta_0 = %.4f, psi = %.4f\n", theta_0_C, psi_C))
# Expected: theta_0 ≈ 0.90, psi ≈ 0.84
```

### Strengths

- Recovers a positive psi with economic content
- Uses information already available in the pipeline (Stage 1 zeta_1)
- The Kaldor prior is independently estimated, not circular
- Produces theta_CL that varies meaningfully with s_ME (ISI ≈ 0.88,
  neoliberal ≈ 0.85 — a small decline driven by the theta_2 interaction,
  not a collapse to zero)

### Limitations

- The identifying assumption (psi/theta_0 ≈ zeta_1) is **strong and
  theoretically debatable**: the import elasticity of machinery reflects
  the external sector's response, not necessarily the domestic marginal
  product ratio. The proportionality claim requires a specific Tavares
  channel transmission mechanism
- If the assumption is wrong, both theta_0 and psi are biased in a
  correlated direction — no internal consistency check
- The recovered parameters are no longer Johansen estimates but a
  **hybrid** of Johansen (aggregate) and structural prior (Kaldor ratio)
- Sensitivity to zeta_1 is high: if zeta_1 is 0.70 instead of 0.93,
  the recovered theta_0 and psi change substantially

### Risk assessment

**Medium risk.** Produces economically interpretable parameters but depends
critically on the Kaldor prior being correct. Should be reported with a
sensitivity table showing how theta_0 and psi change across a range of
zeta_1 values (0.5 to 1.2).

---

## Proposal D: DOLS on the Orthogonalized System

### Concept

Dynamic OLS (Stock & Watson 1993) estimates the cointegrating vector by
augmenting the OLS regression with leads and lags of the first differences
of all regressors. This absorbs the endogeneity and serial correlation
that contaminate static OLS and can handle near-multicollinearity better
than Johansen because it estimates the cointegrating vector directly rather
than through an eigenvalue decomposition.

The key innovation: instead of using the collinear (k_NR, k_ME), use the
**orthogonalized** regressors (k_CL, c_t) where:

$$k_t^{CL} = \ln(K_t^{NR} + K_t^{ME}) \quad \text{(aggregate scale)}$$

$$c_t = k_t^{ME} - k_t^{NR} = \ln(K_t^{ME}/K_t^{NR}) \quad \text{(log composition ratio)}$$

These are orthogonal by construction: k_CL captures the common stochastic
trend; c_t captures relative composition. The DOLS regression is:

$$y_t = A \cdot k_t^{CL} + B \cdot c_t + C \cdot \omega_t c_t + \kappa +
\sum_{j=-q}^{q} \gamma_j' \Delta X_{t-j} + u_t$$

where $\Delta X$ includes $\Delta k^{CL}$, $\Delta c_t$, and
$\Delta(\omega c_t)$, and $q$ is the lead/lag truncation parameter.

### Why DOLS handles the I(2) concern

In Step 1, the enhanced unit root battery found c_t classified as I(2).
This killed the Johansen approach on the reparameterized system. However,
DOLS has important advantages here:

1. **DOLS is robust to near-unit-root regressors.** Stock & Watson (1993)
   show that the DOLS estimator is asymptotically median-unbiased even
   when regressors have near-unit roots. A borderline I(1)/I(2) series
   does not invalidate the estimator — it only affects convergence rates.

2. **The leads and lags absorb the persistence.** If c_t is "almost I(2)"
   (high persistence in first differences but not a true unit root), the
   lead/lag augmentation captures this dynamics without requiring the
   series to be exactly I(1).

3. **The I(2) classification may itself be suspect.** With N=105 and a
   structural break at 1973, the ADF on first differences has very low
   power. The Zivot-Andrews test on Δc_t gave tau = -3.81 (vs -5.08 CV)
   — not far from rejection. DOLS sidesteps the classification problem
   entirely.

### Parameter recovery

The DOLS coefficients (A, B, C) map to structural parameters exactly as
in the reparameterized Johansen:

$$\theta_0 = A - B, \quad \psi = A + B, \quad \theta_2 = 2C$$

The critical difference: because k_CL and c_t are (nearly) orthogonal,
the DOLS decomposition of A and B is **not contaminated by collinearity**.
The coefficient B directly estimates the differential productivity of
machinery versus infrastructure, independent of the aggregate scale A.

### Implementation

```r
library(dynlm)  # or manual DOLS via lm()

# Setup
df_dols <- df %>%
  mutate(
    k_CL    = log(exp(k_NR) + exp(k_ME)),
    c_t     = k_ME - k_NR,
    omega_c = omega * c_t
  )

# DOLS: y on levels + q leads/lags of first differences
q <- 2  # lead/lag truncation (try q = 1, 2, 3)

# Build lead/lag matrix of Δk_CL, Δc_t, Δ(omega_c)
dols_data <- df_dols %>%
  arrange(year) %>%
  mutate(
    dk_CL    = c(NA, diff(k_CL)),
    dc_t     = c(NA, diff(c_t)),
    domega_c = c(NA, diff(omega_c))
  )

# Add leads and lags
for (j in (-q):q) {
  suffix <- ifelse(j < 0, paste0("_Lm", abs(j)),
            ifelse(j > 0, paste0("_Lp", j), "_L0"))
  dols_data[[paste0("dk_CL", suffix)]]    <- dplyr::lead(dols_data$dk_CL, -j)
  dols_data[[paste0("dc_t", suffix)]]     <- dplyr::lead(dols_data$dc_t, -j)
  dols_data[[paste0("domega_c", suffix)]] <- dplyr::lead(dols_data$domega_c, -j)
}

# DOLS regression
dols_vars <- grep("^d(k_CL|c_t|omega_c)_L", names(dols_data), value = TRUE)
fml <- as.formula(paste("y ~ k_CL + c_t + omega_c +",
                        paste(dols_vars, collapse = " + ")))
dols_fit <- lm(fml, data = dols_data)

# Extract long-run coefficients
A_dols <- coef(dols_fit)["k_CL"]
B_dols <- coef(dols_fit)["c_t"]
C_dols <- coef(dols_fit)["omega_c"]

theta_0_D <- A_dols - B_dols
psi_D     <- A_dols + B_dols
theta_2_D <- 2 * C_dols

# HAC standard errors (Newey-West)
library(sandwich)
vcov_hac <- vcovHAC(dols_fit)
```

### What to expect

If the orthogonalization works, B should be **positive** (psi > theta_0,
Kaldor hypothesis), and the DOLS standard errors on B should be much
tighter than the Johansen decomposition because k_CL and c_t are nearly
uncorrelated (though the earlier diagnostic showed cor(k_CL, c_t) = 0.79
on the full sample — lower than 0.95 but not orthogonal).

The remaining correlation (0.79) means DOLS won't fully solve the problem,
but the improvement from 0.99 (k_NR, k_ME) to 0.79 (k_CL, c_t) is
substantial — the variance inflation factor drops from ~50 to ~3.

### Strengths

- **Proper econometric solution** to the collinearity problem: directly
  addresses the identification failure rather than working around it
- Robust to borderline I(1)/I(2) classification of c_t
- Produces HAC-robust standard errors (unlike Johansen, which gives only
  asymptotic chi-squared tests on restricted beta)
- Can be estimated on ISI subsample, extended window, or full sample
- If B is significant and positive, the Kaldor hypothesis is directly tested
- The A coefficient (aggregate elasticity) should match the Johansen
  aggregate (~0.88), providing an internal consistency check

### Limitations

- cor(k_CL, c_t) = 0.79 is still non-negligible — the orthogonalization
  reduces but does not eliminate collinearity
- DOLS requires choosing q (lead/lag truncation). With N=33 (ISI), q=2
  consumes 4 observations per augmented variable (12 total), leaving only
  ~21 effective degrees of freedom. q=1 is more conservative but may
  under-correct for dynamics
- If c_t is genuinely I(2), the DOLS estimator is consistent but converges
  at a slower rate (T^{1/2} rather than T) — the confidence intervals will
  be wider
- DOLS produces a **static** cointegrating vector. The CLS threshold
  stage (Steps 4–8) requires an ECT, which can be constructed from the
  DOLS residuals but lacks the Johansen asymptotic theory for rank testing.
  This means the Johansen rank test and CLS bootstrap remain linked to the
  ISI Johansen, with DOLS providing only the parameter decomposition

### Risk assessment

**Medium-high risk (of inconclusive results).** If the remaining correlation
(0.79) is still too high, B may be imprecisely estimated and the
confidence interval will span zero — which is the same problem as Johansen,
just with honest standard errors. The advantage is that DOLS will tell us
this honestly rather than producing a point estimate with a wrong sign.

If B is significant and positive, this is the definitive solution. If B is
insignificant, it confirms that the data cannot distinguish theta_0 from
psi, and Proposal B (homogeneous capital) is the honest conclusion.

---

## Summary Comparison

| | A: Direct g_Yp | B: Homogeneous | C: Kaldor Prior | D: DOLS |
|---|---|---|---|---|
| **Re-estimation** | None | blrtest only | None | Full DOLS regression |
| **Fixes psi** | No (dampens error) | Drops psi entirely | Yes (externally) | Yes (if data allow) |
| **theta_CL narrative** | Lost | Flat (~0.88) | Preserved | Preserved |
| **mu_CL drift** | Likely reduced | Eliminated | Eliminated | Eliminated (if B identified) |
| **Risk** | Low | Low | Medium | Medium-high |
| **Kaldor hypothesis** | Cannot test | Rejected by design | Imposed | Directly testable |
| **Data requirement** | ISI beta only | ISI Johansen + blrtest | ISI beta + Stage 1 zeta_1 | Panel + DOLS estimation |
| **New estimation** | No | Minimal | No | Yes |

### Recommended sequence

1. **A first** — 5-minute implementation, may resolve the mu drift entirely.
   If g_Yp_A produces cyclical mu without drift, the chapter can report mu
   from direct frontier growth and theta_CL as an illustrative decomposition
   for the ISI window only.

2. **D if A shows residual drift** — DOLS is the econometrically proper
   solution. Run on the ISI subsample (N=33, q=1) and on the extended
   window (1935–1978, N=44, q=1). If B > 0 and significant, adopt the DOLS
   parameters for the full theta_CL narrative.

3. **B as the honest fallback** — if DOLS produces an insignificant B,
   accept that the data cannot distinguish machinery from infrastructure
   productivity and impose homogeneous capital. This is a valid structural
   finding: Chilean ISI-era capital was sufficiently homogeneous in its
   productive impact that separate identification is not achievable.

4. **C for sensitivity only** — the Kaldor prior identification should be
   reported in the appendix as a "what if" exercise, not as the primary
   result. The assumption psi/theta_0 = zeta_1 is too strong to bear the
   weight of the chapter's identification strategy, but it usefully brackets
   the plausible range of psi.

---

*Generated: 2026-04-08. Authority: Ch2_Outline_DEFINITIVE.md.*
