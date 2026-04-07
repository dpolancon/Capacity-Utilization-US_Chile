# US Sequential Structural Identification — Omega Specification
## Consolidated Results and Geometric Interpretation

**Script:** `codes/stage_a/us/30_sequential_cvar_omega_us.R`  
**Data:** `US_corporate_NF_kstock_distribution.csv` (NF corporate sector, gross distribution)  
**Date:** 2026-04-05

---

## 1. Estimation setup

| Item | Value |
|------|-------|
| Sample | 1929-2024 (96 obs) |
| State vector | X_t = (y_t, k_t, omega_t, omega_k_t)' with ecdet="const" |
| Distributional variable | omega = Wsh_NF = EC_NF / GVA_NF (gross wage share) |
| Capital concept | KGC_NF (total nonfarm gross capital, Py-deflated) |
| Lag length K | 2 (AIC; BIC selects 1, overridden to K=2 minimum) |
| Cointegrating rank r | 3 (trace and max-eigenvalue, all at 5%) |
| Common deflator | Py_fred (GDP deflator, rebased 2024=1) |
| Normalization | Present-period: 2024 = 1 for all real quantities |

### Pre-tests: all four variables I(1)

| Variable | ADF levels (p) | KPSS levels (p) | ADF diff (p) | Verdict |
|----------|---------------|-----------------|--------------|---------|
| y (log GVA) | 0.426 | 0.010 | 0.010 | I(1) |
| k (log K gross) | 0.986 | 0.010 | 0.011 | I(1) |
| omega (wage share) | 0.638 | 0.010 | 0.010 | I(1) |
| omega*k (interaction) | 0.576 | 0.010 | 0.010 | I(1) |

### Rank determination

| Null | Trace stat | 5% cv | Max-eigen stat | 5% cv | Decision |
|------|-----------|-------|----------------|-------|----------|
| r <= 0 | 159.26 | 53.12 | 83.83 | 28.14 | REJECT |
| r <= 1 | 75.43 | 34.91 | 46.06 | 22.00 | REJECT |
| r <= 2 | 29.37 | 19.96 | 24.87 | 15.67 | REJECT |
| r <= 3 | 4.51 | 9.24 | 4.51 | 9.24 | Fail |

**Confirmed rank: r = 3.** All three stages structurally available.

---

## 2. Stage 1 — CV1: MPF

### Structural parameters

| Parameter | Estimate | Interpretation |
|-----------|----------|----------------|
| alpha1 | 6.3566 | Base transformation elasticity |
| alpha2 | -8.7706 | Distribution sensitivity (NEGATIVE) |
| c1 | -0.1677 | Nuisance (technology intercept) |
| theta_bar | 0.8945 | theta at mean omega = 0.6228 |
| omega_H | 0.6108 | Harrodian knife-edge wage share |

### blrtest

| Statistic | Value |
|-----------|-------|
| LR chi-sq | 2.763 |
| df | 1 |
| p-value | 0.097 |
| Decision | Not rejected at 5% (marginal at 10%) |

### ECT1 stationarity

| Test | Statistic | p-value |
|------|-----------|---------|
| ADF on mu0 | -5.400 | < 0.01 |

ECT1 is confirmed I(0). The capacity manifold is a stationary attractor.

---

## 3. Stage 2 — CV2: Reserve Army Phillips Curve

### Sequential result (alpha1, alpha2 fixed from Stage 1)

| Parameter | Estimate | Expected sign |
|-----------|----------|---------------|
| c1 (re-estimated) | -0.0376 | -- |
| kappa1 | 0.4507 | -- |
| kappa2 | -2.0668 | > 0 (VIOLATED) |

**Verdict:** kappa2 < 0 — the Goodwin reserve army mechanism is **not confirmed** in the
sequential c1-purged specification. The second cointegrating vector does not function
as a Phillips curve when conditioned on the MPF parameters.

### LR test at r=2

| Statistic | Value |
|-----------|-------|
| LR chi-sq | 11.582 |
| df | 5 |
| p-value | 0.041 |
| Decision | **REJECTED** at 5% |

The structural restrictions at r=2 are not data-consistent.

### Stage 3: unavailable

Goods market closure requires kappa2 > 0. Stage 3 not estimated.

---

## 4. Alpha matrix (unrestricted, r=3)

|        | ECT1 (mu) | ECT2 | ECT3 |
|--------|-----------|------|------|
| y      | -0.277    | -0.169 | 0.498 |
| k      | 0.053     | -0.110 | 0.097 |
| omega  | 0.050     | -0.079 | -0.039 |
| omega_k | -0.106   | 0.346 | 0.072 |

**Interaction row (omega_k) is NOT zero.** The maintained-zero assumption is violated:
alpha[omega_k, ECT2] = 0.346 is the largest loading in the ECT2 column. The interaction
variable responds strongly to the second ECT, which undermines the structural identification
premise that omega_k is a composite with no independent adjustment channel.

---

## 5. Geometry of Distribution and Theta

### 5.1 The theta(omega) mapping

The capacity transformation elasticity is:

$$\theta(\omega) = 6.357 - 8.771 \, \omega_t$$

This is a **downward-sloping** linear function: higher gross wage share *reduces* the
transformation elasticity. The sign is negative (alpha2 < 0), contrary to the prompt's
expectation of alpha2 > 0.

**Interpretation.** In the *gross* distribution framework (EC/GVA vs GOS/GVA), the
wage share and operating surplus are exhaustive shares of gross value added. A higher
omega_t means a lower *gross* operating surplus, which includes both net operating surplus
(profits) and consumption of fixed capital (depreciation). The gross surplus funds
*both replacement investment and net accumulation*. When the wage share rises, the gross
surplus available for maintaining and upgrading the capital stock is squeezed, reducing
the efficiency of the capital-output transformation. Mechanization investment — which
raises theta by upgrading the productive quality of installed capital — requires surplus.

This contrasts with the *net* distribution (pi_net = NOS/NVA) where the relationship
theta(pi) = 5.165 - 11.181 pi (from the previous identification) had a similar negative
slope but was measured against a different distributional axis.

### 5.2 The Harrodian knife-edge

The knife-edge wage share is:

$$\omega_H = \frac{1 - \alpha_1}{\alpha_2} = \frac{1 - 6.357}{-8.771} = 0.611$$

At omega = omega_H, theta = 1 exactly. The sample range of omega is [0.565, 0.678],
so omega_H falls **inside** the observed distribution — the economy crosses the
knife-edge repeatedly.

**Regime classification:**

| Regime | Condition | theta | Period character |
|--------|-----------|-------|------------------|
| Harrodian | omega < 0.611 | > 1 | Capital deepening yields increasing output-capital ratio; accelerator instability amplifies |
| Sub-unitary | omega > 0.611 | < 1 | Capital deepening yields diminishing output-capital ratio; stabilizing force |

The theta plot (Plot 1) shows the economy oscillating between regimes:
- **Great Depression (1929-33):** omega falls sharply (profit squeeze collapses wages), theta rises above 1 — Harrodian increasing returns during contraction
- **Fordist era (1945-73):** omega generally above 0.611, theta mostly sub-unitary — stable accumulation regime
- **Neoliberal era (1980-2024):** omega declining trend toward 0.56, theta rises — regime switches toward Harrodian dynamics

### 5.3 Why alpha2 < 0 is structurally coherent

The prompt expected alpha2 > 0 based on the reasoning that higher wage share should
raise theta (more labor income → more demand → higher utilization → higher effective
transformation). But this conflates the *demand-side* effect (utilization) with the
*supply-side* effect (capacity transformation). The MPF identifies theta from the
*capacity* relationship Y^p = B K^theta, not from the demand-utilization channel.

In the gross distribution:
- Higher omega → lower GOS/GVA → lower depreciation-plus-net-surplus share
- Lower surplus → lower mechanization investment rate (chi = I/Pi)
- Lower mechanization → lower capital quality upgrading → lower theta

The *demand* effect of higher omega (higher consumption → higher utilization) operates
through ECT1 (mu), not through theta itself. The separation is precisely the achievement
of the structural identification: theta is the *frontier* parameter (how much output a
unit of capital *can* produce), while mu is the *utilization* parameter (how much of that
capacity is *actually* used). Higher omega raises mu (demand channel) but lowers theta
(supply channel). The net effect on output depends on the magnitudes.

### 5.4 Why the sequential Goodwin identification failed

The kappa2 < 0 result at Stage 2 means: conditioning on the MPF (fixed alpha1, alpha2),
the second cointegrating vector does not have the Phillips curve form "higher utilization
raises wage share." Three candidate explanations:

1. **The gross wage share is not the right distributional variable for the Goodwin channel.**
   The reserve army mechanism operates through labor market bargaining power, which may
   be better captured by the *net* wage share (EC/NVA) or the exploitation rate (GOS/EC),
   not the *gross* wage share that includes depreciation in the denominator. In the gross
   framework, cyclical movements in depreciation (CCA) can mask the bargaining channel.

2. **The c1-purged cross-equation restriction is too tight.** The prompt specifies that
   c1 (nuisance) should not enter CV2. But if the constant in the MPF absorbs a
   technology-level shift that also enters the Phillips curve (e.g., the level of
   potential output affects the natural rate of unemployment), then purging c1 from CV2
   removes economically relevant information. The existing joint estimation
   (`22_vecm_structural_wsh_joint.R`) includes c1 in all three CVs.

3. **The interaction row is not a maintained zero.** The alpha matrix shows
   alpha[omega_k, ECT2] = 0.346, which is the largest loading in the ECT2 column.
   This means the interaction variable omega*k has an independent adjustment channel,
   violating the premise that it is a pure composite. If omega*k adjusts independently
   to distributional disequilibrium, the structural identification that treats it as
   mechanically linked to omega and k is compromised.

### 5.5 Recommendations

**A. For the distributional variable:** Test the specification with the *net* wage
share (EC/NVA) or alternatively the exploitation rate (e = GOS/EC). The gross wage
share bundles depreciation dynamics into the distributional variable, which may not be
appropriate for the reserve army channel. The MPF (CV1) can use the gross distribution
(since theta relates to the gross production function), but CV2 may require a net
distributional variable.

**B. For the cross-equation restriction:** Compare the c1-purged sequential approach
(this script) with the c1-included joint approach (script 22). If the joint approach
recovers kappa2 > 0, this confirms that the nuisance parameter c1 carries economically
relevant information for the distributional dynamics — it should be included in
cross-equation restrictions rather than purged.

**C. For the interaction row:** Test the maintained-zero restriction
alpha[omega_k, .] = 0 formally via an LR test. If rejected, the state vector may need
modification — either dropping the interaction term entirely (accepting a constant theta)
or replacing it with a variable that has no independent loading.

**D. For the Harrodian knife-edge:** The finding omega_H = 0.611 inside the sample
is robust to the Stage 2 failure — it depends only on Stage 1 parameters. The
mixed-regime result (theta oscillating around 1) is a first-order structural finding
regardless of whether the Goodwin mechanism can be sequentially identified. Report it.

**E. For the sequential vs joint strategy:** The sequential approach has the virtue of
transparency (each stage adds one structural equation) but the cost of rigidity (alpha1,
alpha2 are never re-estimated after Stage 1). The joint approach (`21_vecm_structural_us.R`)
estimates all 9 parameters simultaneously and achieves a lower concentrated likelihood.
The comparison is informative: if the joint approach produces qualitatively different
CV2/CV3 parameters while maintaining a comparable LR test p-value, this indicates that
the sequential conditioning is overly restrictive.

---

## 6. Comparison with previous pi-based results

| Object | pi-based (net, script 21) | omega-based (gross, script 30) |
|--------|--------------------------|-------------------------------|
| Distribution variable | ProfSh = NOS/NVA ~ 0.23 | Wsh_NF = EC/GVA ~ 0.62 |
| theta1 / alpha1 | 5.165 | 6.357 |
| theta2 / alpha2 | -11.181 | -8.771 |
| c1 | -0.526 | -0.168 |
| theta_bar | 2.92 (at mean pi=0.20) | 0.89 (at mean omega=0.62) |
| Knife-edge | pi_H = (1-5.165)/(-11.181) = 0.373 | omega_H = (1-6.357)/(-8.771) = 0.611 |
| Knife-edge in sample? | No (pi range [0.06, 0.38]) | Yes (omega range [0.56, 0.68]) |
| CV2 kappa2 sign | -- (joint: rho2=0.056 > 0) | -2.067 (sequential: WRONG) |
| LR test (r=3 joint) | 1.021 (p=0.796, not rejected) | -- (sequential failed at Stage 2) |

**Key comparison:** The pi-based system placed the knife-edge *outside* the sample
(theta always > 1), while the omega-based system places it *inside* (theta oscillates
around 1). This difference arises because the gross distribution axis (omega ~ 0.62)
has a different range and variability than the net distribution axis (pi ~ 0.23).
The structural finding is that the gross distribution generates a mixed Harrodian regime,
while the net distribution generates a uniformly Harrodian regime.

This is not a contradiction — it reflects the fact that depreciation (CCA) acts as a
wedge between gross and net surplus. The gross framework captures the *full* cost of
reproduction including capital replacement, while the net framework captures only the
residual after replacement. The gross theta is lower because capital replacement absorbs
part of the output-capital relationship that the net theta attributes to "returns."

---

*Generated from `30_sequential_cvar_omega_us.R`, 2026-04-05*
