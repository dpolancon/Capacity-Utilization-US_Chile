# Stage 2 Note: mu^CL Truncation at 1982

## What runs on the full sample (valid 1920–2024)

The CLS threshold VECM estimation uses the **full panel** (T=103, 1922–2024):

1. **ECT_theta** is constructed over 1920–2024 using the ISI-estimated
   cointegrating vector. The ADF test confirms stationarity on the full
   sample (tau = -4.22, p < 0.01). The cointegrating *relation* holds
   globally — the frontier equation describes a long-run equilibrium
   that output, infrastructure, machinery, and the distributional
   interaction revert to across the entire century.

2. **Threshold identification** (gamma = -0.1394) is estimated by CLS
   grid search over the full sample. The bootstrap LR test **rejects
   linearity at 1%** (p = 0.005, 999 replications). This is a
   full-sample result.

3. **Regime classification** assigns every year 1922–2024 to Regime 1
   (BoP slack) or Regime 2 (BoP binding) based on ECT_m relative to
   gamma. The classification is historically coherent: Regime 2 captures
   ISI import-substitution peaks, the 1973 coup, the 1982 debt crisis,
   and the persistent post-1997 copper-dependent BoP constraint.

4. **Shadow price test** confirms |alpha_y(2)| < |alpha_y(1)| on the
   full sample: output error-correction speed is -0.091 under BoP slack
   vs -0.017 under BoP binding — a 5.5x compression. This is the
   chapter's central empirical result for Chile and does not depend on
   the theta^CL decomposition.

## What does NOT extrapolate (truncated at 1982)

The **theta^CL series and mu^CL construction** require decomposing the
cointegrating vector into structural parameters (theta_0, psi, theta_2)
and evaluating them at time-varying composition (s_ME) and distribution
(omega). This decomposition breaks down outside the ISI window because:

### The collinearity problem

cor(k_NR, k_ME) = 0.99 in the ISI subsample. Johansen identifies the
**frontier linear combination** (theta_0\*k_NR + psi\*k_ME + theta_2\*omega\*k_ME)
but cannot reliably separate theta_0 from psi. The raw estimates
(theta_0 = +1.34, psi = -0.18) are collinearity-contaminated: the
negative psi does not mean machinery reduces capacity — it means the
Johansen decomposition allocated most of the joint k_NR+k_ME effect
to the k_NR coefficient.

### Why this matters for extrapolation

Within the ISI window, s_ME ranges narrowly (0.25–0.35). The
collinearity-driven misallocation between theta_0 and psi approximately
cancels: theta_0\*(1-s_ME) + psi\*s_ME ≈ 0.87 because the weighted
sum is stable when s_ME doesn't move far.

In the neoliberal era, s_ME rises to 0.54. The negative psi now
receives a large weight, dragging theta^CL down to 0.51. This
**understates productive capacity growth** by ~40%, causing:
- g_Yp < g_Y persistently (frontier grows too slowly)
- mu^CL accumulates upward without mean-reversion
- By 2024, mu^CL ≈ 1.30 — implying Chile permanently operates 30%
  above productive capacity, which is economically implausible

### The fix: truncate at 1982

mu^CL is reported only for 1920–1982, where:
- s_ME stays within the ISI identification range
- The collinearity-driven decomposition error remains bounded
- mu^CL shows proper cyclical behavior (oscillating around the
  pin at 1980 = 1.0)

The post-1982 series is **not suppressed** — it is reported in the
appendix as a structural finding: the ISI productive frontier cannot
describe neoliberal Chile's accumulation regime. This is itself
evidence of structural break in the technology-composition relationship.

## What IS valid for the full sample

| Result | Sample | Status |
|--------|--------|--------|
| ECT_theta stationarity | 1920–2024 | ADF tau = -4.22 |
| Threshold gamma = -0.14 | 1922–2024 | CLS on T=103 |
| Linearity rejection | 1922–2024 | p = 0.005 |
| Shadow price | 1922–2024 | CONFIRMED |
| Regime classification | 1922–2024 | Valid |
| theta^CL | **1920–1982 only** | Truncated |
| mu^CL | **1920–1982 only** | Truncated |

---

*Generated: 2026-04-08. Authority: Ch2_Outline_DEFINITIVE.md.*
