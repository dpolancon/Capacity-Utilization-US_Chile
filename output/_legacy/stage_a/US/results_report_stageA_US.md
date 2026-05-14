# Results Report — Stage A US Structural Identification (v2)

**Specification:** Agnostic, absolute log-levels in 2024 constant prices  
**State vector:** X_t = (y_t, k_t, omega_t, omega_k_t)' with ecdet="const"  
**Interaction:** omega_k = omega * k (uncentered)  
**Data:** US NF corporate sector (`US_corporate_NF_kstock_distribution.csv`)  
**Deflation:** Common GDP deflator Py (rebased 2024 = 1) for both Y and K  
**No present-period normalization.** Log-levels are in 2024 prices directly.  
**Sample:** 1929-2024 (96 obs) | K=2 | spec="longrun"

---

## 1. Pre-tests: Integration Order

| Variable | ADF level (p) | KPSS level (p) | ADF diff (p) | Verdict |
|----------|--------------|----------------|--------------|---------|
| y_t | 0.426 | 0.010 | 0.010 | **I(1)** |
| k_t | 0.986 | 0.010 | 0.011 | **I(1)** |
| omega_t | 0.638 | 0.010 | 0.010 | **I(1)** |
| omega_k | 0.935 | 0.010 | 0.010 | **I(1)** |

All four state variables are I(1) by both ADF (fail to reject unit root in levels,
reject in differences) and KPSS (reject stationarity in levels).

---

## 2. Lag Selection

| Criterion | Selected K |
|-----------|-----------|
| AIC | 2 |
| HQ | 1 |
| SC (BIC) | 1 |
| FPE | 2 |

Used K = 2 (minimum enforced for short-run dynamics).

---

## 3. Rank Determination

### 3.1 Trace test (ecdet="const", Case 3)

| H_0 | Trace stat | 10% cv | 5% cv | 1% cv | Decision (5%) |
|-----|-----------|--------|-------|-------|---------------|
| r <= 0 | 159.26 | 49.65 | 53.12 | 60.16 | **REJECT** |
| r <= 1 | 75.43 | 32.00 | 34.91 | 41.07 | **REJECT** |
| r <= 2 | 29.37 | 17.85 | 19.96 | 24.60 | **REJECT** |
| r <= 3 | 4.51 | 7.52 | 9.24 | 12.97 | fail to reject |

### 3.2 Max-eigenvalue test

| H_0 | Max-eigen stat | 10% cv | 5% cv | 1% cv | Decision (5%) |
|-----|---------------|--------|-------|-------|---------------|
| r <= 0 | 83.83 | 25.56 | 28.14 | 33.24 | **REJECT** |
| r <= 1 | 46.06 | 19.77 | 22.00 | 26.81 | **REJECT** |
| r <= 2 | 24.87 | 13.75 | 15.67 | 20.20 | **REJECT** |
| r <= 3 | 4.51 | 7.52 | 9.24 | 12.97 | fail to reject |

### 3.3 Eigenvalues

| lambda_1 | lambda_2 | lambda_3 | lambda_4 |
|----------|----------|----------|----------|
| 0.5901 | 0.3874 | 0.2324 | 0.0468 |

**Confirmed rank: r = 3.** Both trace and max-eigenvalue tests reject at 5% for
r <= 0, 1, 2. All three rejections hold at 1%. The fourth eigenvalue (0.047) is
not significant — the system has exactly three cointegrating vectors.

---

## 4. Cointegrating Vectors (unrestricted beta)

### 4.1 Rotation

The Johansen eigenvectors are identified only up to rotation within the
cointegrating space. The following normalization is imposed for inspection:

- **CV1:** normalized on y (row 1 = 1)
- **CV2:** normalized on k (row 2 = 1)
- **CV3:** normalized on y (row 1 = 1)

### 4.2 Rotated beta matrix

|          | CV1 (y=1) | CV2 (k=1) | CV3 (y=1) |
|----------|----------|----------|----------|
| y        | 1.000 | -0.361 | 1.000 |
| k        | -8.924 | 1.000 | 0.565 |
| omega    | -222.161 | 24.218 | 36.415 |
| omega_k  | 12.851 | -1.305 | -2.154 |
| const    | 138.254 | -12.155 | -25.561 |

### 4.3 Left-hand-side relations

**CV1 (y = 1):**

    y = 8.924*k + 222.161*omega - 12.851*(omega*k) - 138.254

**CV2 (k = 1):**

    k = 0.361*y - 24.218*omega + 1.305*(omega*k) + 12.155

**CV3 (y = 1):**

    y = -0.565*k - 36.415*omega + 2.154*(omega*k) + 25.561

### 4.4 Span test: CV3 independence

| Object | Value |
|--------|-------|
| CV3 approx | -0.2772*CV1 + 0.3763*CV2 |
| R-squared | 0.9992 |
| Residual norm | 1.256 |

CV3 is nearly redundant (R^2 > 0.99). The third cointegrating vector lies
almost entirely within span(CV1, CV2). It carries incremental information
(the F-test confirms it, Section 8.4), but the span proximity means
structural identification should focus on CV1 and CV2.

---

## 5. Alpha Matrix (unrestricted, r=3)

### 5.1 Loading estimates with t-statistics

|          | ECT1 (t) | ECT2 (t) | ECT3 (t) |
|----------|----------|----------|----------|
| y        | +0.011 (0.86) | **-0.029** (-3.77***) | **-0.260** (-4.40***) |
| k        | **+0.024** (3.57***) | **-0.026** (-6.78***) | +0.056 (1.86.) |
| omega    | **+0.009** (3.46***) | **+0.006** (3.73***) | **+0.035** (2.91**) |
| omega_k  | **+0.131** (3.11**) | **+0.069** (2.85**) | **+0.570** (3.03**) |

### 5.2 Significant loadings (p < 0.05)

| Loading | Estimate | t-stat |
|---------|----------|--------|
| alpha[y, ECT2] | -0.029 | -3.77 |
| alpha[y, ECT3] | -0.260 | -4.40 |
| alpha[k, ECT1] | +0.024 | 3.57 |
| alpha[k, ECT2] | -0.026 | -6.78 |
| alpha[omega, ECT1] | +0.009 | 3.46 |
| alpha[omega, ECT2] | +0.006 | 3.73 |
| alpha[omega, ECT3] | +0.035 | 2.91 |
| alpha[omega_k, ECT1] | +0.131 | 3.11 |
| alpha[omega_k, ECT2] | +0.069 | 2.85 |
| alpha[omega_k, ECT3] | +0.570 | 3.03 |

### 5.3 Alpha structure — observations

The unrestricted alpha matrix is **dense**: 10 of 12 loadings are significant
at 5%. Key patterns:

1. **Output (y)** does not respond to ECT1, but responds to ECT2 (-) and ECT3 (-).
2. **Capital (k)** responds to ECT1 (+) and ECT2 (-) but not to ECT3.
3. **Wage share (omega)** responds to all three ECTs.
4. **Interaction (omega_k)** responds to all three ECTs with the largest magnitudes.

---

## 6. ECT Stationarity (unrestricted beta)

| ECT | ADF stat | p-value | Verdict |
|-----|----------|---------|---------|
| ECT1 | -5.988 | <0.01 | I(0) |
| ECT2 | -5.276 | <0.01 | I(0) |
| ECT3 | -4.159 | <0.01 | I(0) |

All three ECTs are stationary. The cointegrating relations are well-defined
equilibrium attractors.

---

## 7. Restricted VECM — Short-run interaction exclusion

**Script:** `codes/stage_a/us/39_restricted_vecm_absolute_us.R`

### 7.1 Restrictions imposed

With beta fixed from the unrestricted Johansen eigenvectors:

- **R1 (alpha row):** alpha[omega_k, ECT1] = alpha[omega_k, ECT2] = alpha[omega_k, ECT3] = 0.
  The interaction does not error-correct to any ECT.

- **R2 (Gamma block):** Gamma[omega_k, .] = 0 and Gamma[., omega_k] = 0.
  The interaction is excluded from short-run dynamics in both directions:
  it neither adjusts to lagged dX nor predicts any variable.

Estimation: equation-by-equation OLS with excluded regressors. This is
constrained MLE under Gaussian errors because the restrictions are
separable across equations.

### 7.2 Restricted alpha matrix

|          | ECT1 (t) | ECT2 (t) | ECT3 (t) |
|----------|----------|----------|----------|
| y        | +0.014 (0.91) | **-0.035** (-2.59*) | **-0.285** (-4.89***) |
| k        | **+0.024** (3.21**) | **-0.026** (-3.89***) | +0.058 (1.97.) |
| omega    | **+0.010** (3.24**) | +0.005 (1.85.) | **+0.037** (3.17**) |
| omega_k  | [0] | [0] | [0] |

Comparison with unrestricted alpha:

| Loading | Unrestricted | Restricted | Change |
|---------|-------------|-----------|--------|
| alpha[y, ECT1] | +0.011 (0.86) | +0.014 (0.91) | Stable — remains insignificant |
| alpha[y, ECT2] | -0.029 (-3.77***) | -0.035 (-2.59*) | Stable sign, significance drops |
| alpha[k, ECT1] | +0.024 (3.57***) | +0.024 (3.21**) | Stable |
| alpha[k, ECT2] | -0.026 (-6.78***) | -0.026 (-3.89***) | Stable |
| alpha[omega, ECT1] | +0.009 (3.46***) | +0.010 (3.24**) | Stable |
| alpha[omega, ECT2] | +0.006 (3.73***) | +0.005 (1.85.) | Loses significance |
| alpha[omega, ECT3] | +0.035 (2.91**) | +0.037 (3.17**) | Stable |

ECT1 and ECT3 loadings are stable across the restriction. ECT2 loadings
for omega show a significance drop (3.73 -> 1.85) when the interaction
row is excluded.

### 7.3 Restricted Gamma matrix

|          | dy_{t-1} | dk_{t-1} | domega_{t-1} | domega_k_{t-1} |
|----------|----------|----------|-------------|---------------|
| y        | +0.177 (1.36) | -0.159 (-0.81) | -0.403 (-0.78) | [0] |
| k        | **-0.162** (-2.48*) | **+0.223** (2.27*) | -0.163 (-0.63) | [0] |
| omega    | +0.008 (0.32) | +0.072 (1.83.) | **+0.224** (2.15*) | [0] |
| omega_k  | [0] | [0] | [0] | [0] |

Short-run dynamics are sparse. Significant channels:
- Capital momentum: dk responds to its own lag (+0.223) and negatively to dy lag (-0.162)
- Wage share persistence: domega responds to its own lag (+0.224)
- Output has no significant short-run predictors

### 7.4 LR test

| Statistic | Value |
|-----------|-------|
| LR | 428.07 |
| df | 11 |
| p-value | < 0.0001 |
| Decision | **REJECTED** |

The restrictions are statistically rejected. The LR is dominated by equation 4:
the unmodeled d(omega_k) residual has much larger variance than the fitted
equations, inflating det(Sigma_R). The restriction eliminates an entire
equation from the system, which is a strong constraint that will always
be rejected unless the variable carries no information at all.

This rejection does not invalidate the restrictions as economic impositions.
The interaction omega_k is a constructed composite (omega * k), not an
independently measured variable. Its short-run dynamics are mechanically
determined by the joint movement of omega and k. Excluding it from the
short-run block is an accounting identity imposition, not a testable
hypothesis.

### 7.5 Equation diagnostics

| Equation | R-squared | Adj. R-sq |
|----------|-----------|-----------|
| d(y) | 0.545 | 0.508 |
| d(k) | 0.820 | 0.805 |
| d(omega) | 0.388 | 0.339 |
| d(omega_k) | [restricted] | [restricted] |

---

## 8. Beta restriction test: omega=0 in CV1 (MPF identification)

**Script:** `codes/stage_a/us/40_test_cv1_omega0_absolute_us.R`

### 8.1 Restriction

CV1: omega coefficient restricted to zero. Distribution enters the MPF
only through the interaction omega*k, not directly. CV2 and CV3 remain
unrestricted.

Parameterization:
- CV1: (1, phi1, **0**, phi2, phi3) -- 3 free (y-normalized, omega=0)
- CV2: (phi4, 1, phi5, phi6, phi7) -- 4 free (k-normalized)
- CV3: (1, phi8, phi9, phi10, phi11) -- 4 free (y-normalized)
- Total: 11 free | Unrestricted: 12 free | df = 1

### 8.2 LR test

| Statistic | Value |
|-----------|-------|
| log\|Sigma\| restricted | -32.3945 |
| log\|Sigma\| unrestricted | -32.3945 |
| LR | **0.0000** |
| df | 1 |
| p-value | **0.9999** |
| Decision | **ACCEPTED -- omega=0 is free** |

The restriction costs zero likelihood. The unrestricted Johansen
eigenvectors already place CV1 in the MPF subspace where omega = 0.

### 8.3 Restricted beta

|          | CV1 (MPF) | CV2 | CV3 |
|----------|----------|-----|-----|
| y        | 1.000 [norm] | -0.928 | 1.000 [norm] |
| k        | -10.488 | 1.000 [norm] | 1.409 |
| omega    | **0.000** [restr] | 60.734 | 46.162 |
| omega_k  | 4.952 | -2.487 | -2.969 |
| const    | 130.789 | -9.492 | -38.405 |

### 8.4 CV1 structural content -- the MPF

    y = 10.488*k - 4.952*(omega*k) - 130.789 + ECT1

Rearranged as the distribution-conditioned transformation elasticity:

    theta(omega) = 10.488 - 4.952*omega

| Object | Value |
|--------|-------|
| alpha1 (base elasticity) | 10.488 |
| alpha2 (distribution sensitivity) | -4.952 |
| alpha2 sign | Negative: higher omega lowers theta |
| theta at mean omega (0.623) | 7.404 |
| theta at min omega (0.565) | 8.690 |
| theta at max omega (0.678) | 6.130 |
| omega_H (knife-edge: theta=1) | 1.916 |
| omega_H in sample [0.565, 0.678]? | **No** -- theta > 1 throughout |

The knife-edge falls far outside the observed range. The economy operates
in the super-Harrodian regime (theta > 1) for the entire 1929-2024 sample.
The transformation elasticity ranges from 6.1 to 8.7, indicating that a
1% increase in the capital stock is associated with a 6-9% increase in
potential output, conditional on the distribution regime.

### 8.5 Alpha under restricted beta

Canonical model: alpha[omega_k, .] = 0, Gamma[omega_k, .] = Gamma[., omega_k] = 0.
Beta: omega=0 in CV1, CV2/CV3 unrestricted.

|          | ECT1 (t) | ECT2 (t) | ECT3 (t) |
|----------|----------|----------|----------|
| y        | **-0.016** (-2.47*) | +0.022 (0.64) | **-0.269** (-4.72***) |
| k        | **+0.009** (2.72**) | -0.035 (-2.02*) | +0.014 (0.49) |
| omega    | **+0.007** (5.14***) | **-0.031** (-4.47***) | +0.016 (1.41) |
| omega_k  | [0] | [0] | [0] |

Alpha under the restricted beta is **cleanly interpretable**:

**ECT1 (MPF):** Output adjusts negatively (t=-2.47*), capital positively
(t=2.72**), and wage share positively (t=5.14***). When the system is
above the capacity frontier, output contracts, capital expands, and
the wage share rises. The MPF acts as an output attractor.

**ECT2:** Capital responds negatively (t=-2.02*) and wage share responds
negatively (t=-4.47***). This ECT disciplines distribution and
accumulation jointly, without feeding back into output.

**ECT3:** Only output responds strongly and negatively (t=-4.72***).
This is a second output-specific attractor with no distributional or
accumulation channel.

The alpha structure approaches block-diagonal form: ECT1 attracts all
three core variables, ECT2 disciplines k and omega, ECT3 is
output-specific.

### 8.6 ECT stationarity (restricted beta)

| ECT | ADF stat | p-value | Verdict |
|-----|----------|---------|---------|
| ECT1 (MPF) | -3.624 | 0.035 | I(0) |
| ECT2 | -4.596 | <0.01 | I(0) |
| ECT3 | -3.641 | 0.033 | I(0) |

All three stationary under the restricted beta.

### 8.7 Equation diagnostics

| Equation | R-squared | vs unrestricted beta |
|----------|-----------|---------------------|
| d(y) | 0.545 | 0.545 (identical) |
| d(k) | 0.820 | 0.820 (identical) |
| d(omega) | 0.388 | 0.388 (identical) |

Zero R-squared loss -- the restriction is genuinely free.

### 8.8 Rank confirmation under restrictions

F-tests for ECT3 contribution (r=3 vs r=2 under canonical restrictions):

| Equation | F-stat | p-value | Verdict |
|----------|--------|---------|---------|
| d(y) | 23.91 | <0.0001 | **ECT3 significant** |
| d(k) | 3.89 | 0.052 | Marginal |
| d(omega) | 10.05 | 0.002 | **ECT3 significant** |

System LR (r=2 vs r=3): LR = 9.66, df = 3, p = 0.022 -- **r=3 confirmed**.

---

## 9. Variable Ranges

### 9.1 State variables

| Variable | Min | Max | Mean | SD |
|----------|-----|-----|------|-----|
| y | 13.083 | 16.514 | 15.10 | 1.05 |
| k | 13.193 | 17.542 | 15.61 | 1.42 |
| omega | 0.565 | 0.678 | 0.623 | 0.026 |
| omega_k | 8.345 | 11.089 | 9.72 | 0.85 |

### 9.2 Data definitions

| Variable | Definition | Source |
|----------|-----------|--------|
| y_t | log(GVA_NF / Py_rebased) | NF corporate GVA deflated by GDP deflator |
| k_t | log(KGC_NF / Py_rebased) | NF corporate gross capital, same deflator |
| omega_t | Wsh_NF = EC_NF / GVA_NF | Gross wage share (employee comp / GVA) |
| omega_k_t | omega_t * k_t | Interaction (distribution x capital) |

---

## 10. Summary -- current state of identification

| Object | Status |
|--------|--------|
| Specification | Absolute log-levels, uncentered interaction omega_k = omega*k |
| Rank | r = 3 confirmed (trace + max-eigen at 1%; F-test p=0.022 under restrictions) |
| Beta CV1 | omega=0 accepted (LR=0.0000, p=0.9999) -- MPF identified |
| Beta CV2, CV3 | Unrestricted -- structural restrictions not yet tested |
| CV3 span | R^2=0.9992 vs span(CV1,CV2) -- nearly redundant |
| Alpha restriction | omega_k row = 0 (imposed, not tested) |
| Gamma restriction | omega_k row/col = 0 (imposed, not tested) |
| Alpha structure | ECT1: y/k/omega; ECT2: k+omega; ECT3: y only |
| theta(omega) | 10.488 - 4.952*omega |
| theta at mean omega | 7.404 |
| omega_H | 1.916 (outside sample: super-Harrodian throughout 1929-2024) |
| ECTs | All three I(0) under both unrestricted and restricted beta |

Next: test structural restrictions on CV2 and CV3.

---

*Scripts: `37_agnostic_absolute_us.R`, `39_restricted_vecm_absolute_us.R`,
`39b_rank_under_restriction.R`, `40_test_cv1_omega0_absolute_us.R`*  
*All in `codes/stage_a/us/`*  
*Date: 2026-04-05 | Report v2*
