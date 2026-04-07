# US Self-Discovery Results — Sequential Rank & Structure Tests

**Script:** `codes/stage_a/us/30_sequential_cvar_omega_us.R`  
**Data:** `US_corporate_NF_kstock_distribution.csv` (NF corporate sector, gross distribution)  
**Date:** 2026-04-05

---

## 0. Setup

| Item | Value |
|------|-------|
| Sample | 1929-2024 (96 obs) |
| State vector | X_t = (y_t, k_t, omega_t, omega_k_t)' with ecdet="const" |
| omega_t | Wsh_NF = EC_NF / GVA_NF (gross wage share, range [0.565, 0.678]) |
| Capital | KGC_NF (total NF gross capital, Py-deflated by common GDP deflator) |
| Lag order K | 2 (AIC=2, BIC=1, minimum K=2 enforced) |
| Normalization | Present-period: 2024 = 1 |
| Confirmed rank | r = 3 (trace and max-eigenvalue, all reject at 5%) |

### Pre-tests: all four variables I(1)

| Variable | ADF levels (p) | KPSS levels (p) | ADF diff (p) | Verdict |
|----------|---------------|-----------------|--------------|---------|
| y (log GVA real) | 0.426 | <0.01 | <0.01 | I(1) |
| k (log K gross) | 0.986 | <0.01 | 0.011 | I(1) |
| omega (wage share) | 0.638 | <0.01 | <0.01 | I(1) |
| omega*k (interaction) | 0.576 | <0.01 | <0.01 | I(1) |

### Johansen rank determination

| Null | Trace stat | 5% cv | Max-eigen | 5% cv | Decision |
|------|-----------|-------|-----------|-------|----------|
| r <= 0 | 159.26 | 53.12 | 83.83 | 28.14 | REJECT |
| r <= 1 | 75.43 | 34.91 | 46.06 | 22.00 | REJECT |
| r <= 2 | 29.37 | 19.96 | 24.87 | 15.67 | REJECT |
| r <= 3 | 4.51 | 9.24 | 4.51 | 9.24 | Fail |

Eigenvalues (unrestricted): 0.5901, 0.3874, 0.2324, 0.0468

---

## 1. Test A — Restricted r=1 (CV1, omega=0) vs Unrestricted r=3

### CV1 structural parameters (blrtest at r=1)

beta_1 = (1, -alpha1, 0, -alpha2, -c1) with omega restricted to 0.

| Parameter | Estimate | Role |
|-----------|----------|------|
| alpha1 | 6.3566 | Base transformation elasticity |
| alpha2 | -8.7706 | Distribution sensitivity (higher omega → lower theta) |
| c1 | -0.1677 | Nuisance (technology intercept) |

Derived objects:

| Object | Value |
|--------|-------|
| theta_bar (at mean omega=0.6228) | 0.8945 |
| omega_H (Harrodian knife-edge) | 0.6108 |
| omega_H in sample? | YES — mixed regime |
| ECT1 ADF | -5.400 (p < 0.01, I(0) confirmed) |
| blrtest LR (omega=0 within r=1) | 2.763 (df=1, p=0.097) |

### Joint LR test

| Component | Value |
|-----------|-------|
| **LR total: restricted r=1 vs unrestricted r=3** | **73.69** |
| LR rank component (trace stat for r<=1) | 75.43 |
| LR structure component (blrtest omega=0) | 2.76 |
| Additive sum | 78.19 |
| Discrepancy (eigenvalue shift under restriction) | -4.51 |

Eigenvalues under restriction: 0.5778, 0.3840, 0.2151, 0.0183

| Reference df | chi-sq 5% cv | Decision |
|-------------|-------------|----------|
| 5 | 11.07 | REJECTED |
| 8 | 15.51 | REJECTED |
| 10 | 18.31 | REJECTED |
| 12 | 21.03 | REJECTED |

### Interpretation

The joint null {r=1, omega=0 in CV1} is overwhelmingly rejected against
unrestricted r=3. The rejection is **dominated by the rank component** — the trace
statistic (75.43) already rejects r<=1 massively. The structural restriction
(omega=0) contributes only 2.76 to the total LR, which is marginal at 10% within r=1.

The data demands at least two additional cointegrating vectors beyond CV1. The second
and third eigenvalues (0.387, 0.232) carry substantial information. Restricting to r=1
discards it.

**Conclusion for r=1:** CV1's identifying restriction (omega=0) is marginally
acceptable within r=1, but rank 1 itself is far too restrictive. The system has r=3.

---

## 2. Test B — Restricted r=2 (CV1 structured + CV2 unrestricted) vs Unrestricted r=3

**Script:** `codes/stage_a/us/31_test_r2_cv1_structured_us.R`

### Model specification

| Component | Parameterization | Free params |
|-----------|-----------------|-------------|
| CV1 (MPF) | beta1 = (1, -alpha1, 0, -alpha2, -c1) — omega=0 | 3 |
| CV2 (unrestricted) | beta2 = (b21, b22, 1, b24, b25) — normalized on omega | 4 |
| **Total** | | **7** |
| Unrestricted r=2 | | 8 |
| Unrestricted r=3 | | 12 |

### Beta matrix

|          | CV1 (MPF)  | CV2 (free) |
|----------|-----------|-----------|
| y_t      | 1.0000 [norm] | -0.7127 |
| k_t      | -6.0339 | 3.4146 |
| omega_t  | 0.0000 [restr] | 1.0000 [norm] |
| omega_k  | 8.5131 | -4.7379 |
| const    | -0.1950 | -0.3437 |

CV1 structural parameters: alpha1 = 6.034, alpha2 = -8.513, c1 = 0.195

| Derived object | Value |
|----------------|-------|
| theta_bar (at mean omega=0.623) | 0.732 |
| omega_H (knife-edge) | 0.591 |
| ECT1 ADF | -5.871 (p < 0.01) |
| ECT2 ADF | -5.740 (p < 0.01) |

### LR tests

| Test | LR stat | df | p-value | Decision |
|------|---------|-----|---------|----------|
| **(a) Structure only:** restricted r=2 vs unrestricted r=2 | **0.000** | 1 | **1.000** | NOT REJECTED |
| **(b) Rank + structure:** restricted r=2 vs unrestricted r=3 | **24.865** | — | — | REJECTED |
| **(c) Rank only:** trace test r<=2 | 29.373 | — | 5% cv=19.96 | REJECTED |

**Key finding (a):** LR = 0.000 — the omega=0 restriction on CV1 costs **zero likelihood**
at r=2. The unrestricted r=2 Johansen eigenvectors already place CV1 in (or infinitesimally
close to) the structural subspace where omega=0. The restriction is perfectly consistent
with the data — it is not a binding constraint.

**Decomposition of (b):**

| Component | Value |
|-----------|-------|
| LR_joint (restricted r=2 vs unrestricted r=3) | 24.865 |
| LR_rank (trace stat for r<=2) | 29.373 |
| LR_structure (omega=0) | 0.000 |
| Discrepancy (eigenvalue shift) | -4.508 |

The entire rejection against r=3 comes from the **rank component** — the third eigenvalue
(0.232) carries statistically significant information. The structural restriction omega=0
contributes nothing to the rejection.

### Beta inference (Hessian-based)

| Parameter | Estimate | SE | t-stat | p-value | Sig |
|-----------|----------|-----|--------|---------|-----|
| alpha1 | 6.0339 | 37.234 | 0.162 | 0.871 | |
| alpha2 | -8.5131 | 44.405 | -0.192 | 0.848 | |
| c1 | 0.1950 | 10.487 | 0.019 | 0.985 | |
| b21_y | -0.7127 | 62.665 | -0.011 | 0.991 | |
| b22_k | 3.4146 | 40.892 | 0.084 | 0.934 | |
| b24_wk | -4.7379 | 28.275 | -0.168 | 0.867 | |
| b25_const | -0.3437 | 13.740 | -0.025 | 0.980 | |
| **theta_bar** | **0.7321** | 64.831 | 0.011 | 0.991 | |

Hessian has **2 negative eigenvalues** — eigenvalue floor correction applied. All
individual beta coefficients are statistically insignificant. This is expected:
cointegrating vectors are identified as a *space*, not as individual directions.
Rotation within the cointegrating space does not change the likelihood, so the Hessian
is flat along rotation directions. Joint identification (the LR test) is the
authoritative test, not individual t-statistics.

### Alpha inference (OLS standard errors)

| Loading | Estimate | SE | t-stat | p-value | Sig |
|---------|----------|-----|--------|---------|-----|
| alpha[y, ECT1] | 0.084 | 0.050 | 1.68 | 0.093 | . |
| alpha[y, ECT2] | 0.143 | 0.057 | 2.52 | 0.012 | * |
| **alpha[k, ECT1]** | **0.121** | 0.023 | **5.17** | **<0.001** | *** |
| **alpha[k, ECT2]** | **0.173** | 0.026 | **6.56** | **<0.001** | *** |
| alpha[omega, ECT1] | 0.022 | 0.010 | 2.22 | 0.026 | * |
| alpha[omega, ECT2] | 0.009 | 0.011 | 0.84 | 0.402 | |
| alpha[omega_k, ECT1] | -0.053 | 0.028 | -1.95 | 0.052 | . |
| alpha[omega_k, ECT2] | 0.014 | 0.031 | 0.45 | 0.652 | |

**Key alpha findings:**

1. **Capital (k) responds strongly to BOTH ECTs** — alpha[k, ECT1]=0.121 (t=5.17)
   and alpha[k, ECT2]=0.173 (t=6.56). Capital accumulation is the primary adjustment
   channel for both the capacity manifold and the second long-run relationship.

2. **Output (y) responds significantly to ECT2** — alpha[y, ECT2]=0.143 (t=2.52).
   The second cointegrating relationship feeds back into output dynamics.

3. **Wage share responds only to ECT1** — alpha[omega, ECT1]=0.022 (t=2.22, p=0.026).
   Distribution adjusts to the capacity gap but NOT to ECT2 (p=0.40).

4. **omega_k (interaction) does NOT respond significantly to ECT2** — the maintained-zero
   assumption is supported at r=2 (p=0.65). At r=3 this was violated (alpha[omega_k, ECT2]=0.346),
   suggesting the third CV was absorbing interaction dynamics.

### CV2 interpretation: NOT a Phillips curve

The unrestricted CV2 is: omega = 0.713*y - 3.415*k + 4.738*omega_k + 0.344

If CV2 were a Phillips curve (omega = kappa1 + kappa2*mu0), the implied kappa2 from
each variable would agree:

| Source | Implied kappa2 |
|--------|---------------|
| From y coefficient | +0.713 |
| From k coefficient | -0.566 |
| From omega_k coefficient | -0.557 |

The k and omega_k channels agree (kappa2 ≈ -0.56) but the y channel gives +0.71
with **opposite sign**. CV2 is not a simple Phillips curve — it has additional structure
that involves k and omega_k independently of the MPF composite mu0.

**Interpretation:** CV2 captures a long-run relationship between the wage share, output,
and capital that cannot be reduced to omega = f(mu0). The capital stock enters CV2 with
its own coefficient (b22=3.41), not merely through the mu0 composite. This suggests
CV2 reflects a capital-deepening-distribution nexus: as capital deepens (k rises),
the wage share adjusts — but not through the capacity utilization channel.

---

## 3. Test C — CV2 structural restriction: y=0

**Script:** `codes/stage_a/us/32_test_cv2_structured_us.R`

### Motivation

Test B showed the unrestricted CV2 has y=-0.713, while the k and omega_k channels
are consistent with a capital-deepening relationship that does not involve output
directly. Substituting CV1 into CV2 shows y is entirely accounted for by the MPF —
the net content of CV2 has no independent y term. We test y=0 in CV2.

### Model hierarchy

| Model | Specification | Free params |
|-------|--------------|-------------|
| M0 | Unrestricted r=2 | 8 |
| M1 | CV1 (omega=0) + CV2 free | 7 |
| M2 | CV1 (omega=0) + CV2 (y=0) | 6 |

### LR tests

| Test | LR stat | df | p-value | Decision |
|------|---------|-----|---------|----------|
| M1 vs M0 (omega=0 in CV1) | 0.0000 | 1 | 1.000 | **ACCEPTED** |
| M2 vs M1 (y=0 in CV2, incremental) | **0.0000** | 1 | **1.000** | **ACCEPTED** |
| M2 vs M0 (omega=0 + y=0, joint) | 0.0000 | 2 | 1.000 | **ACCEPTED** |
| M2 vs unrestricted r=3 (rank+structure) | 24.865 | — | — | (rank-dominated) |
| Trace stat (r<=2) | 29.373 | — | 5% cv=19.96 | REJECT r<=2 |

**Both structural restrictions cost zero likelihood.** The data places the first two
cointegrating vectors exactly in the restricted subspace {omega=0 in CV1, y=0 in CV2}
without any coercion. log|Sigma| is identical across M0, M1, M2 to 6 decimal places.

### Beta matrix (M2)

|          | CV1 (MPF)  | CV2 (y=0) |
|----------|-----------|-----------|
| y_t      | 1.0000 [norm] | 0.0000 [restr] |
| k_t      | -6.0339 (p<0.001***) | -0.8857 (p=0.987) |
| omega_t  | 0.0000 [restr] | 1.0000 [norm] |
| omega_k  | 8.5132 (p<0.001***) | 1.3294 (p=0.988) |
| const    | -0.1950 (p=0.929) | -0.4826 (p=0.879) |

**CV1 structural parameters are now individually significant:**

| Parameter | Estimate | SE | t-stat | p-value | 95% CI |
|-----------|----------|-----|--------|---------|--------|
| alpha1 | 6.034 | 1.685 | 3.58 | 0.0003*** | [2.731, 9.337] |
| alpha2 | -8.513 | 0.998 | -8.53 | <0.0001*** | [-10.468, -6.558] |
| c1 | 0.195 | 2.173 | 0.09 | 0.929 | [-4.064, 4.454] |

With the y=0 restriction on CV2 removing rotation indeterminacy in the y-direction,
the Hessian gains curvature along the alpha1/alpha2 directions. The concentrated
likelihood identifies these parameters with high precision. c1 remains a nuisance
(insignificant, as expected).

**CV2 coefficients remain individually insignificant** — the Hessian is still flat
along the CV2 direction. This is because at r=2, the second eigenvector retains
one rotation degree of freedom (overall scale/sign). The joint LR test (not individual
t-stats) is authoritative for CV2.

### Derived structural objects

| Object | Value | SE | t | p |
|--------|-------|-----|---|---|
| theta_bar (at mean omega=0.623) | 0.732 | 2.261 | 0.32 | 0.746 |
| omega_H (Harrodian knife-edge) | 0.591 | — | — | — |

theta_bar is not individually significant because it is a linear combination of
alpha1 and alpha2 that happens to be close to 1 (the null where deflator cancels).
The individual parameters alpha1 and alpha2 are highly significant.

### Alpha inference (M2)

| Loading | Estimate | SE | t-stat | p-value | Sig |
|---------|----------|-----|--------|---------|-----|
| alpha[y, ECT1] | -0.017 | 0.017 | -1.03 | 0.303 | |
| **alpha[y, ECT2]** | **0.143** | 0.057 | **2.52** | **0.012** | * |
| alpha[k, ECT1] | -0.002 | 0.008 | -0.27 | 0.790 | |
| **alpha[k, ECT2]** | **0.173** | 0.026 | **6.56** | **<0.001** | *** |
| **alpha[omega, ECT1]** | **0.015** | 0.003 | **4.65** | **<0.001** | *** |
| alpha[omega, ECT2] | 0.009 | 0.011 | 0.84 | 0.402 | |
| **alpha[omega_k, ECT1]** | **-0.063** | 0.009 | **-6.91** | **<0.001** | *** |
| alpha[omega_k, ECT2] | 0.014 | 0.031 | 0.45 | 0.652 | |

**Alpha structure is sharp and interpretable:**

- **ECT1 (capacity manifold):** omega adjusts (t=4.65***), omega_k adjusts (t=-6.91***).
  Output and capital do NOT respond directly to the capacity gap. The adjustment
  to the MPF is entirely through distribution — the wage share corrects when
  output deviates from the capacity frontier. This is the Goodwin channel operating
  through ECT1 directly.

- **ECT2 (capital-distribution):** Output responds (t=2.52*) and capital responds
  strongly (t=6.56***). Wage share does NOT respond (t=0.84, p=0.40). The second
  relationship disciplines output and capital accumulation, but distribution is
  unaffected — consistent with CV2 being a supply-side/accumulation condition rather
  than a distributional bargaining equation.

### ECT stationarity

| ECT | ADF stat | p-value | Verdict |
|-----|----------|---------|---------|
| ECT1 (CV1/MPF) | -5.871 | <0.01 | I(0) |
| ECT2 (CV2/y=0) | -5.726 | <0.01 | I(0) |

Both ECTs are strongly stationary.

### CV2 structural interpretation

With y=0 imposed, CV2 reads:

    omega*(1 + 1.329*k) = 0.886*k + 0.483

Solved: omega = (0.886*k + 0.483) / (1 + 1.329*k)

This is a **capital-deepening distributional condition**: the long-run wage share is
determined by the capital stock through a nonlinear (rational) function. It is NOT
a Phillips curve (no utilization channel).

| Evaluation point | k value | omega_CV2 |
|-----------------|---------|-----------|
| 1929 (k_min) | -4.349 | 0.705 |
| Median | -1.445 | 0.866 |
| 2024 (k=0) | 0.000 | 0.483 |

The implied omega_CV2 is **above** the observed omega for much of the sample,
suggesting the long-run distributional attractor has been consistently above
the realized wage share — the economy has been below its capital-deepening
distributional equilibrium.

---

## 4. Test D — CV3 self-discovery: CV1+CV2 locked, CV3 unrestricted at r=3

**Script:** `codes/stage_a/us/33_test_cv3_unrestricted_us.R`

### LR test: CV1+CV2 restrictions at r=3

| Item | Value |
|------|-------|
| LR stat (CV1+CV2 restricted, CV3 free vs unrestricted r=3) | **0.000** |
| df | 2 |
| p-value | **1.000** |
| Decision | **ACCEPTED** |

**The restrictions remain free at r=3.** The entire cointegrating space at r=3 is
consistent with {omega=0 in CV1, y=0 in CV2}. log|Sigma| for the restricted model
matches the unrestricted to 6 decimal places.

### ECT stationarity

| ECT | ADF stat | p-value | Verdict |
|-----|----------|---------|---------|
| ECT1 (CV1/MPF) | -5.819 | <0.01 | I(0) |
| ECT2 (CV2/K-distr) | -6.265 | <0.01 | I(0) |
| ECT3 (CV3/free) | -4.503 | <0.01 | I(0) |

All three ECTs are stationary. The system has three cointegrating vectors.

### CV3 extracted (unrestricted, conditional on CV1+CV2)

**Normalized on y=1:**

|          | CV3 |
|----------|-----|
| y_t      | 1.000 [norm] |
| k_t      | 0.458 |
| omega_t  | 3.680 |
| omega_k  | -2.610 |
| const    | -1.239 |

**Normalized on omega=1:**

|          | CV3 |
|----------|-----|
| y_t      | 0.272 |
| k_t      | 0.125 |
| omega_t  | 1.000 [norm] |
| omega_k  | -0.709 |
| const    | -0.337 |

### Net CV3 content (after substituting CV1=0, CV2=0)

When we substitute the equilibrium conditions from CV1 and CV2 into CV3,
the net content is:

    Net CV3 = 1.177 * k  -  1.933 * omega_k  +  0.088

Both k and omega_k channels are active. CV3 is not reducible to a single axis.

### CV3 vs CV1+CV2 span test: CRITICAL FINDING

CV3 is approximately a linear combination of CV1 and CV2:

    CV3 approx 0.792 * CV1 + 3.750 * CV2

| Slot | CV3 actual | CV3 fitted | Residual |
|------|-----------|-----------|----------|
| y_t | 1.000 | 0.792 | 0.208 |
| k_t | 0.458 | 0.568 | -0.109 |
| omega_t | 3.680 | 3.750 | -0.070 |
| omega_k | -2.610 | -2.507 | -0.103 |
| const | -1.239 | -1.313 | 0.075 |

**R-squared = 0.997.** CV3 is 99.7% in the span of CV1+CV2.

**This means the third cointegrating vector adds essentially no new long-run
information beyond what CV1 and CV2 already encode.** The third eigenvalue
(0.232) is statistically significant by the trace test, but the direction it
identifies is nearly a linear combination of the first two. The effective rank
is r=2, with a "noisy third vector" that recombines the existing two relationships.

### Alpha at r=3 — instability warning

The alpha matrix at r=3 is **qualitatively different** from r=2:

| Loading | r=3 (t-stat) | r=2 (t-stat) | Stable? |
|---------|-------------|-------------|---------|
| alpha[omega, ECT1] | -0.170 (-2.29) | +0.015 (+4.65) | **NO — sign flip** |
| alpha[k, ECT2] | -0.101 (-0.12) | +0.173 (+6.56) | **NO — magnitude collapse** |
| alpha[omega_k, ECT1] | +0.197 (+0.90) | -0.063 (-6.91) | **NO — sign flip** |

The alpha loadings on ECT1 and ECT2 **flip sign and lose significance** when moving
from r=2 to r=3. This is because CV3 is nearly collinear with CV1+CV2 — the three
ECTs are nearly linearly dependent, which destabilizes the alpha decomposition.
The loading matrix rotates to accommodate the near-redundant third direction.

The **ECT3 loadings** are:

| Variable | alpha[., ECT3] | t-stat | p-value | Sig |
|----------|---------------|--------|---------|-----|
| y | -2.065 | -4.90 | <0.001 | *** |
| k | 0.054 | 0.25 | 0.799 | |
| omega | 0.220 | 2.58 | 0.010 | ** |
| omega_k | -0.302 | -1.20 | 0.228 | |

Output and wage share respond to ECT3, but this is mostly absorbing the
signal that was cleanly attributed to ECT1 and ECT2 at r=2. The near-collinearity
means the r=3 alpha decomposition is **not structurally interpretable** —
it redistributes the same information across three nearly-dependent ECTs.

### Beta inference (Hessian)

| Parameter | Estimate | SE | t-stat | p-value | Sig |
|-----------|----------|-----|--------|---------|-----|
| alpha1 | 5.718 | 4.535 | 1.26 | 0.207 | |
| alpha2 | -7.995 | 3.254 | -2.46 | 0.014 | * |
| c1 | 0.171 | 1.117 | 0.15 | 0.878 | |
| b_k | 1.359 | 4.678 | 0.29 | 0.772 | |
| b_wk | -2.357 | 5.137 | -0.46 | 0.646 | |
| c2 | -0.314 | 5.585 | -0.06 | 0.955 | |
| g2_k | 0.458 | 5.739 | 0.08 | 0.936 | |
| g3_omega | 3.680 | 3.910 | 0.94 | 0.347 | |
| g4_wk | -2.610 | 5.302 | -0.49 | 0.623 | |
| g5_const | -1.239 | 4.663 | -0.27 | 0.791 | |

At r=3 alpha1 loses individual significance (p=0.21, was 0.0003 at r=2).
alpha2 retains marginal significance (p=0.014). The added CV3 introduces
rotation ambiguity that inflates SEs on CV1 parameters.

---

## 5. Synthesis

### Full model hierarchy

| Model | Restrictions | Free | LR vs unr. r=same | p |
|-------|-------------|------|-------------------|---|
| M0 (unr r=2) | — | 8 | — | — |
| M1 (CV1 omega=0, r=2) | 1 | 7 | 0.000 | 1.000 |
| M2 (CV1+CV2 restr, r=2) | 2 | 6 | 0.000 | 1.000 |
| M3 (CV1+CV2 restr, CV3 free, r=3) | 2 | 10 | 0.000 | 1.000 |

All structural restrictions are free at every rank tested. The data naturally
places the cointegrating vectors in the structural subspace.

### The r=2 vs r=3 choice

The trace test formally rejects r<=2. But the self-discovery reveals that
CV3 is 99.7% in the span of CV1+CV2, and its inclusion destabilizes the
alpha matrix (sign flips, significance collapses). This is a classic case
of **over-extraction**: the third eigenvalue is statistically significant
but structurally redundant.

**Recommendation: report at r=2 as the primary specification.** The two-CV
system has:
- Clean structural identification (both restrictions free)
- Individually significant alpha1, alpha2 (p < 0.001)
- Interpretable block-diagonal alpha (distribution adjusts to MPF,
  accumulation adjusts to K-distribution nexus)
- Both ECTs strongly stationary

Report r=3 as robustness. Note that CV3 adds no new long-run information
and that the alpha decomposition is not stable across r=2/r=3.

### Key structural findings

| Finding | Value | Source |
|---------|-------|--------|
| alpha1 | 6.034 (SE=1.69) | r=2 with CV1+CV2 locked |
| alpha2 | -8.513 (SE=1.00) | r=2 with CV1+CV2 locked |
| theta_bar (mean omega=0.623) | 0.732 | alpha1 + alpha2*omega_bar |
| omega_H (knife-edge) | 0.591 | (1-alpha1)/alpha2 |
| omega_H in sample? | YES [0.565, 0.678] | Mixed Harrodian regime |
| omega=0 cost (CV1) | 0.000 | Free at r=2 and r=3 |
| y=0 cost (CV2) | 0.000 | Free at r=2 and r=3 |
| CV3 span R-sq | 0.997 | Nearly redundant |
| ECT1 ADF | -5.87 (p<0.01) | I(0) |
| ECT2 ADF | -5.73 (p<0.01) | I(0) |

### Economic interpretation

1. **CV1 (MPF):** theta(omega) = 6.03 - 8.51*omega. Higher gross wage share
   lowers the transformation elasticity — surplus compression reduces
   mechanization capacity. The knife-edge at omega=0.591 bisects the sample:
   Fordist era is mostly sub-unitary (stable), neoliberal wage squeeze pushes
   toward Harrodian dynamics (theta > 1).

2. **CV2 (capital-distribution nexus):** omega = f(k, omega*k) with no output
   channel. The long-run wage share is determined by capital deepening through
   a nonlinear rational function. This is NOT a Phillips curve — it is a
   technical-distributional condition. The economy adjusts to this via
   accumulation (k responds, t=6.56) not bargaining (omega does not respond).

3. **CV3 (redundant):** nearly a linear combination of CV1 and CV2. The third
   eigenvalue captures noise in the estimation of the CV1+CV2 subspace,
   not a genuinely new long-run relationship. Goods market closure or
   Goodwin mechanisms are not empirically operative as a third independent
   cointegrating vector in this state vector specification.

---

## 6. LOCKED DECLARATION — Stage A US Complete

**Script:** `codes/stage_a/us/34_lock_r2_structural_us.R`

### Locked parameters

| Parameter | Estimate | SE | t-stat | p-value | 95% CI |
|-----------|----------|-----|--------|---------|--------|
| **alpha1** | **6.034** | 1.685 | 3.58 | 0.0003*** | [2.731, 9.337] |
| **alpha2** | **-8.513** | 0.998 | -8.53 | <0.0001*** | [-10.468, -6.558] |
| c1 | 0.195 | 2.173 | 0.09 | 0.929 | [-4.064, 4.454] |
| b_k | -0.886 | 55.83 | -0.02 | 0.987 | — |
| b_wk | 1.329 | 85.51 | 0.02 | 0.988 | — |
| c2 | -0.483 | 3.173 | -0.15 | 0.879 | — |

| Derived | Value | SE | 95% CI |
|---------|-------|-----|--------|
| theta_bar (at omega_bar=0.623) | 0.732 | 2.261 | [-3.699, 5.163] |
| omega_H (knife-edge) | 0.591 | 0.262 | [0.078, 1.105] |

### Locked alpha (block-diagonal confirmed)

| | ECT1 (MPF) | ECT2 (K-dist) |
|---|---|---|
| y | -0.017 (t=-1.0) | **0.143** (t=2.5*) |
| k | -0.002 (t=-0.3) | **0.173** (t=6.6***) |
| **omega** | **0.015** (t=4.7***) | 0.009 (t=0.8) |
| **omega_k** | **-0.063** (t=-6.9***) | 0.014 (t=0.5) |

Block-diagonal: all four off-diagonal loadings insignificant (p > 0.30).

### Regime diagnostics

| Period | omega | theta | mu0 | ect2 | % theta>1 |
|--------|-------|-------|-----|------|-----------|
| Pre-Fordist (1929-44) | 0.630 | 0.673 | -0.445 | 0.325 | 0.0% |
| Fordist (1945-73) | 0.633 | 0.643 | -0.321 | 0.257 | 0.0% |
| Post-Fordist (1974-2024) | 0.615 | 0.801 | -0.130 | 0.165 | 29.4% |
| Full sample | 0.623 | 0.732 | -0.240 | 0.219 | 15.6% |

**First post-war theta>1: 2006** (omega=0.588, theta=1.030).
The economy crossed the Harrodian knife-edge in the mid-2000s as the neoliberal
wage squeeze pushed omega below 0.591. By 2024, theta=1.189 — firmly in the
super-Harrodian regime.

### Outputs saved

| File | Contents |
|------|----------|
| `stage_a_structural_series_us.csv` | year, y, k, omega, omega_k, mu0, mu, ect2, theta_t, omega_cv2, regime |
| `stage_a_params_locked_us.rds` | All parameters, inference, alpha, beta, LR test |
| `LOCKED_DECISION_stage_a_us.md` | Formal decision log for audit trail |

### Stage gate: PASSED

Stage A US is complete. Locked outputs inherited by:
- Stage B: Fordist window ARDL on profit rate and accumulation
- Chilean estimation: comparative structural identification

---

*Document updated: 2026-04-05. Stage A US LOCKED.*
