# Post-1973 Identification Assessment — Distributional Channel

**Date:** 2026-04-07
**Problem:** theta2 (wage share effect on capacity transformation) vanishes
after 1973 across all DOLS specifications and lag structures. The distributional
conditioning of the production frontier is empirically identifiable only in
the 1940-1973 Fordist window.

---

## What we established

The DOLS rolling window analysis dates the distributional channel precisely:

- **Active:** 1940-1973 windows (peak t=-4.00 in 1940-1969)
- **Absent:** Every window starting after 1955

The channel doesn't weaken gradually — it disappears. This is not a power
problem (post-1974 has 51 obs, pre-1973 has 45). It's a structural change in
how distribution relates to the production frontier.

---

## Why the direct channel vanishes

In the Fordist period, higher wage share → mechanization pressure → capital
deepening with diminishing returns → theta falls. This requires:

1. **Wage pressure translates into investment decisions** — firms respond to
   labor costs by substituting capital for labor
2. **Investment is primarily in productive physical capital** — machinery and
   structures that transform the Y/K relationship
3. **The K stock measured captures the relevant capital** — the capital that
   enters the production function

After 1973, all three links weaken:

- **Financialization**: investment increasingly goes to financial assets,
  share buybacks, and IP rather than physical productive capital. Wage
  pressure doesn't trigger mechanization — it triggers offshoring, financial
  restructuring, or labor market deregulation.
- **Globalization**: the production frontier becomes multinational. Domestic
  K doesn't capture the full capital base that determines domestic Y.
- **Sectoral shift**: services replace manufacturing. The physical K-Y
  relationship characteristic of industrial production (where theta has
  structural meaning) matters less for an economy dominated by services.

---

## Available data for alternative identification

### In the repo now

| Variable | Source file | Coverage | Potential use |
|----------|-----------|----------|---------------|
| ME_K_gross_real | kstock_private_gpim_real.csv | 1925-2024 | Machinery vs structures decomposition |
| NRC_K_gross_real | same | 1925-2024 | Nonresidential structures |
| ME_IG_real | master_dataset.csv | 1925-2024 | Machinery investment flow |
| NRC_IG_real | same | 1925-2024 | Structures investment flow |
| ME_p_K, NRC_p_K | price_deflators.csv | 1925-2024 | Asset-specific deflators |
| urate | US_labor_market_1929_2024.csv | 1929-2024 | Unemployment rate |
| IGC_NF | NF dataset | 1929-2024 | NF investment flow (current cost) |
| pK_NF | NF dataset | 1929-2024 | NF capital deflator |
| KNC_NF, KNR_NF | NF dataset | 1929-2024 | Net capital (current cost, real) |

### Key decompositions available

**Capital composition:** ME (machinery/equipment) vs NRC (nonresidential
structures). The mechanization story operates through ME — firms respond to
wage pressure by investing in labor-replacing machinery. NRC (buildings,
infrastructure) is less responsive to wage dynamics. If the Fordist channel
operates through ME specifically, decomposing K into ME and NRC might
recover it post-1973.

**Investment flow vs stock:** The stock K_gross accumulates slowly. The
investment flow IG responds faster to distributional pressure. A mediation
model: w → IG_composition → K_composition → Y might capture what the
direct w*k interaction misses.

---

## Three proposed strategies

### Strategy 1: Capital Composition Decomposition

**Idea:** Replace aggregate k_t with (k_ME_t, k_NRC_t). The MPF becomes:

y_t = alpha_ME * k_ME_t + alpha_NRC * k_NRC_t + alpha_2 * w_t * k_ME_t + c1

Distribution conditions theta ONLY through machinery, not structures:

theta_ME(w) = alpha_ME + alpha_2 * w (distribution-conditioned)
theta_NRC = alpha_NRC (fixed, not distribution-conditioned)

**Why this might work post-1973:** Even if aggregate K's relationship to Y
is not distribution-conditioned, the machinery component might be. The
post-1973 shift toward services and IP investment dilutes the aggregate
K signal, but the ME component retains the physical mechanization content.

**State vector:** (y_t, k_ME_t, k_NRC_t, w_t * k_ME_t) + w exogenous
5 endogenous variables — needs careful rank assessment.

**Estimator:** DOLS on split samples, same framework as current.

**Data:** ME_K_gross_real and NRC_K_gross_real from kstock_private_gpim_real.csv.

### Strategy 2: Time-Varying Parameter (TVP) Model

**Idea:** Let theta2 drift as a random walk or Markov-switching process:

y_t = theta1 * k_t + theta2_t * w_k_t + c1 + epsilon_t
theta2_t = theta2_{t-1} + eta_t

**Estimator:** State-space model via Kalman filter (R packages: `dlm`,
`KFAS`, or `tvReg`). This doesn't require distribution to have a stable
long-run effect — it tracks the evolving relationship year by year.

**What it tests:** Is theta2_t negative in the Fordist period and zero/positive
after? The TVP trace would confirm the rolling DOLS finding with proper
uncertainty bands.

**Advantage:** No sample splitting needed. The full 1929-2024 sample is used
efficiently. The break at 1973 emerges endogenously from the Kalman smoother.

**Disadvantage:** No cointegration framework — the model treats the
relationship as a time-varying regression, not a long-run equilibrium.
Interpretation shifts from "distributional conditioning of the production
frontier" to "time-varying elasticity."

### Strategy 3: Mediation via Investment Composition

**Idea:** Distribution doesn't affect the production frontier directly
post-1973, but it affects the composition of investment, which in turn
affects the frontier. The causal chain:

```
w_t → (IG_ME / IG_NRC)_t → (K_ME / K_NRC)_{t+s} → theta_{t+s}
```

The wage share drives the mix of investment (more machinery when wages are
high), which gradually shifts the capital stock composition, which then
affects the output-capital relationship. This is a LAGGED, INDIRECT channel
that the contemporaneous w*k interaction cannot capture.

**Estimator:** Two-stage approach:
1. ARDL or local projection: regress investment composition
   (IG_ME/IG_total) on lagged w_t and controls
2. DOLS: include the investment composition ratio as an additional
   regressor or instrument

**What it tests:** Whether distribution operates on the production frontier
through the investment channel rather than the contemporaneous technique
channel. If investment composition mediates, the post-1973 finding is not
that distribution stopped mattering — it's that the transmission mechanism
shifted from contemporaneous to lagged.

**Variables needed:**
- IG_ME_real / IG_NRC_real (investment flows by type) — in master_dataset.csv
- ME_K_gross_real / NRC_K_gross_real (stocks by type) — available
- w_t — already constructed

---

## Recommended sequence

**Priority 1: Strategy 1 (Capital Composition)** — closest to the current
framework, uses existing data, stays within DOLS/cointegration. If ME-specific
theta2 survives post-1973, the finding is sharp: distribution conditions
mechanization, not aggregate capital deepening. This is the most publishable
result.

**Priority 2: Strategy 2 (TVP)** — complements Strategy 1 by providing
a continuous trace of theta2_t with uncertainty bands. Confirms the rolling
window finding with proper statistical framework. Can be run on the aggregate
specification without decomposing K.

**Priority 3: Strategy 3 (Mediation)** — most ambitious, tests a different
theoretical mechanism. Worth pursuing if Strategies 1-2 confirm that the
direct channel vanishes but want to argue distribution still matters through
a different pathway.

---

## Quick feasibility check

Before implementing, verify:

1. **ME vs NRC coverage:** Do ME_K_gross_real and NRC_K_gross_real sum to
   NR_K_gross_real? If not, there's an IP (intellectual property) residual
   that might be absorbing post-1973 investment.

2. **ME share trend:** What fraction of total K is ME vs NRC over time?
   If ME share has been falling (shift toward IP/services), the aggregate
   K signal is increasingly about NRC/IP rather than machinery — explaining
   why the wage-mechanization channel disappears from the aggregate.

3. **TVP packages:** `tvReg` provides time-varying coefficient OLS with
   bandwidth selection. `KFAS` provides full state-space Kalman filtering.
   Both are on CRAN.

---

*Assessment only — no estimation run. Awaiting instruction on which
strategy to pursue.*
