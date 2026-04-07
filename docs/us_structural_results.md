# US Structural Identification — Consolidated Results

**Script:** `codes/stage_a/us/21_vecm_structural_us.R`
**Authority:** `data/interim/structural_identification/us_structural_identification.md`
**Date:** 2026-04-04

---

## 1. Estimation setup

| Item | Value |
|------|-------|
| Sample | 1929-2024 (96 obs) |
| State vector | X_t = (y_t, k_t, pi_t, pi_k_t)' with ecdet="const" |
| Lag length K | 2 (AIC) |
| Cointegrating rank r | 3 (trace test) |
| Present-period anchor | 2024 (all real quantities normalized to 1) |
| Free parameters | 9: theta1, theta2, c1, rho1, rho2, psi, lambda, gamma2, gamma0 |
| Overidentifying restrictions | 3 (df for LR test) |
| Estimation method | Concentrated profile likelihood (Johansen 1995, eq. 8.11) |
| Optimizer | Multi-start Nelder-Mead (4 centers x 20 perturbations) + BFGS polish |

Note on method: `urca::blrtest()` applies one H matrix to ALL cointegrating
vectors and cannot handle per-CV distinct restrictions. The concentrated profile
likelihood is mathematically equivalent to Johansen restricted ML.

---

## 2. Stage 1 — Structural beta

### Beta matrices: unrestricted (Johansen) vs restricted (structural)

|           | CV1 unres | CV1 restr | CV2 unres | CV2 restr | CV3 unres | CV3 restr |
|-----------|-----------|-----------|-----------|-----------|-----------|-----------|
| y_t       | 1.0000    | 1.0000    | 1.0000    | 0.0555    | 1.0000    | 1.0000    |
| k_t       | -4.9047   | -5.1650   | -2.5111   | -0.2865   | -3.2413   | -5.6024   |
| pi_t      | -161.7614 | 0.0000    | 36.6313   | 1.0000    | -22.5443  | -10.3104  |
| pi_k_t    | 9.8377    | 11.1814   | -2.5435   | 0.6203    | 1.6423    | 13.4273   |
| const     | 64.8526   | 0.5256    | 27.1366   | -0.3441   | 36.4961   | -2.1989   |

The unrestricted eigenvectors are identified only up to an arbitrary rotation of
the cointegrating space. The pi_t coefficient of -161.8 in unrestricted CV1, the
constant of 64.9 — these magnitudes carry no economic meaning. Any linear
combination of the three columns spans the same cointegrating space and yields
the same likelihood. The structural restrictions select the economically
meaningful rotation: CV1 pins pi_t=0 (distribution enters only through the
interaction pi_k_t), CV2 normalizes on pi_t=1 (Phillips curve), and CV3
normalizes on y_t=1 (goods market). The cross-equation theta constraints
(shared theta1, theta2 across all three CVs) provide 3 overidentifying
restrictions that the data does not resist (LR p=0.80).

### Structural parameters

| Parameter | Value | Interpretation |
|-----------|-------|----------------|
| theta1 | 5.1650 | Baseline output-capital elasticity |
| theta2 | -11.1814 | Distribution-elasticity interaction |
| c1 | -0.5256 | CV1 confinement level |
| rho1 | 0.3441 | Structural profit share attractor |
| rho2 | 0.0555 | Goodwin slope (utilization-distribution sensitivity) |
| psi | 1.2009 | Net capacity manifold scale |
| lambda | -0.6001 | Capital productivity elasticity |
| gamma2 | -10.3104 | Saving from profits |
| gamma0 | 2.1989 | Goods market intercept |
| 1-rho1 | 0.6559 | Implied long-run wage share |

Fordist profit share (1945-1978): mean=0.2006, range=[0.1642, 0.2343].
theta_t at Fordist mean pi: **2.9218**.

### LR test: restricted vs unrestricted Johansen

| Statistic | Value |
|-----------|-------|
| LR chi-sq | 1.0205 |
| df | 3 |
| p-value | **0.7963** |
| Decision | **NOT REJECTED** — structural restrictions supported |

The restricted beta is well-supported by the data. Moving from the unrestricted
eigenvectors to the structural parameterization costs only 1.02 units of
log-likelihood across 3 overidentifying restrictions — the data does not resist
the economic structure imposed by the cross-equation theta constraints.

### Cross-equation consistency

All four cross-equation constraints hold to machine precision (deviation = 0.00e+00):

| Constraint | Implied | Actual | Deviation |
|------------|---------|--------|-----------|
| CV2 k = -rho2*theta1 | -0.2865 | -0.2865 | 0.00e+00 |
| CV2 pi_k = -rho2*theta2 | 0.6203 | 0.6203 | 0.00e+00 |
| CV3 k = -(psi*theta1+lambda) | -5.6024 | -5.6024 | 0.00e+00 |
| CV3 pi_k = -psi*theta2 | 13.4273 | 13.4273 | 0.00e+00 |

This is expected: the concentrated profile likelihood enforces these constraints
exactly by construction through `make_beta(phi)`.

### Internal consistency check 3 (psi/gamma2 vs 1/rho2)

| Ratio | Value |
|-------|-------|
| psi/gamma2 | -0.1165 |
| 1/rho2 | 18.0265 |

**These diverge substantially.** The Cambridge-Kaldor saving structure encoded
in CV3 is not internally consistent with the Phillips curve slope in CV2. This
signals that the goods market vector (CV3) may be capturing dynamics beyond the
simple I=S equilibrium condition — possibly inventory adjustment, fiscal
channels, or external sector effects not modeled in the two-class saving
structure.

---

## 3. Stage 2 — Alpha refinement

Baseline: Stage 1 restricted beta + unrestricted alpha.

### Unrestricted alpha matrix

|        | ECT1 (mu) | ECT2 (Phillips) | ECT3 (Goods mkt) |
|--------|-----------|-----------------|-------------------|
| y_t    | 0.2998    | -1.4735         | -0.1283           |
| k_t    | 0.0645    | -0.3202         | -0.0336           |
| pi_t   | 0.1505    | -0.8137         | -0.0670           |
| pi_k_t | -0.0505   | -0.0125         | -0.0023           |

### Test 2a: alpha[k, ECT2] = 0

| Statistic | Value |
|-----------|-------|
| LR chi-sq | 5.9002 |
| df | 1 |
| p-value | **0.0151** |
| alpha[k, ECT2] | -0.3202 |
| Decision | **REJECTED** at 5% |

Capital accumulation responds *directly* to the Phillips curve disequilibrium,
not solely through the Cambridge-Kaldor mediation channel. The negative sign
(alpha = -0.32) indicates that when the Phillips ECT is positive (pi_t above
its Goodwin attractor), capital growth decelerates. This is the *neo-Marxian*
direction: distributional tension (high profit share above the structural
attractor) signals an unsustainable extraction regime that dampens accumulation.

**Economic reading:** The reserve army mechanism operates through accumulation,
not just through distribution. A profit squeeze (pi below attractor) *accelerates*
capital formation — the Fordist investment-profit nexus runs in both directions.

### Test 2b: alpha[pi, ECT3] = 0

| Statistic | Value |
|-----------|-------|
| LR chi-sq | 12.1783 |
| df | 1 |
| p-value | **0.0005** |
| alpha[pi, ECT3] | -0.0670 |
| Decision | **REJECTED** at 1% |

Distribution responds *directly* to the goods market gap, not solely through
the utilization cycle. The negative sign (alpha = -0.067) means that when the
goods market ECT is positive (output above capacity-profitability equilibrium),
the profit share *falls*. This is the *wage-bargaining* channel: tight goods
markets (excess demand, low inventories) tilt bargaining power toward labor.

**Economic reading:** The goods market is not a passive equilibrating mechanism
mediated entirely through utilization. Realization conditions (ECT3) feed
directly into the distributional bargain. This validates the three-system
interpretation: capacity utilization (ECT1), class struggle (ECT2), and
effective demand (ECT3) are genuinely distinct adjustment channels.

### Implications for the alpha structure

The authority document predicted:
- alpha[k, ECT2] = 0: "Fordist prior: fail to reject — Cambridge-Kaldor mediation dominant"
- alpha[pi, ECT3] = 0: "positive value economically credible... but alpha[pi,ECT3]=0 is maintained hypothesis"

Both maintained hypotheses are rejected. This means the full 3x3 alpha (for the
y, k, pi equations) cannot be simplified — all nine loadings carry information.
The interaction row (pi_k_t) shows near-zero loadings throughout, consistent
with its role as a constructed interaction without independent behavioral content.

---

## 4. Structural series

### theta_t(pi) — realized distribution-conditioned elasticity

theta_hat = theta1 + theta2 * pi_t = 5.165 + (-11.181) * pi_t

| Period | theta_hat range | pi_t range |
|--------|----------------|------------|
| 1929 | 2.55 | 0.234 |
| Depression trough (1932) | 4.48 | 0.061 |
| Fordist mean | 2.92 | 0.201 |
| 2024 | 2.53 | 0.235 |

theta_t rises sharply when pi_t collapses (depression) — the production function
becomes more elastic to capital when labor's share rises, consistent with the
choice-of-technique interpretation: capital-deepening slows when profits are
squeezed, so the marginal contribution of capital to output rises.

### theta_t(pi^cm) — cost-minimizing elasticity

pi_cm = rho1 - rho2 * mu_hat (from CV2 Phillips attractor)
theta_cm = theta1 + theta2 * pi_cm

theta_cm strips out the transitory distributional cycle:
theta_t(pi) - theta_t(pi^cm) = theta2 * ECT2_t

The cross-system elasticity theta2 * rho2 = **-0.6203** measures the feedback
from utilization into the transformation elasticity through the distributional
channel. This is negative, meaning high utilization (which lowers pi via the
Goodwin mechanism) raises theta — demand-driven capacity expansion operates
through the choice-of-technique nexus.

### mu_hat — capacity utilization

mu_hat = y_t - theta_hat * k_t - c1

| Period | mu_hat | Interpretation |
|--------|--------|----------------|
| Fordist mean (1945-1978) | 0.457 | Moderate average confinement |
| Fordist sd | 0.234 | Substantial cyclical variation |
| Fordist range | [0.020, 1.008] | From near-zero to full utilization |
| 2024 (anchor year) | 0.526 | Present-period level |

---

## 5. Identity closure

The profit rate identity check:
r_reconstructed = pi_t * mu_hat_level * theta_hat * comp_t
r_observed = NOS_NF / NR_K_net_cc

| Sample | Max residual | Mean residual |
|--------|-------------|---------------|
| Full sample | **19.70%** | 13.49% |
| Fordist window | **13.63%** | — |

**These residuals substantially exceed the 1% tolerance specified in the
authority document.** The identity closure check is failing.

Diagnosis: the formula `mu_hat_level = GVA_NF / (theta_hat * NR_K_gross_real)`
treats theta_hat as a level ratio (Y^p / K), but it is actually an elasticity
in log-space. The MPF says `log(Y) = theta_hat * log(K) + c1` (in normalized
units), so `Y^p = K^theta_hat * exp(c1)` — not `theta_hat * K`. The correct
level conversion requires:

```
mu_hat_level = exp(mu_hat) = exp(y_t - theta_hat * k_t - c1)
Y^p / K_gross = exp((theta_hat - 1) * k_t + c1) * (Y_T / K_T)
```

This is a known formula issue in the identity closure step, not a structural
identification failure. The estimated beta, theta, and mu series are correct in
log-space; the level-space identity check needs revision.

---

## 6. Stage 3 — 1973 Phillips curve regime shift

Split-sample estimation with theta fixed at full-sample values. The MPF (CV1)
is structural and should not shift across regimes; only the distributional
attractor (CV2) is allowed to vary.

### Estimation: pi_t = rho1 - rho2 * mu_hat_t

| Parameter | Pre-1973 (n=45) | Post-1974 (n=51) | Change |
|-----------|----------------|-------------------|--------|
| rho1 (profit share attractor) | 0.2169 | 0.2446 | +0.0277 |
| rho2 (Goodwin slope) | 0.0596 | 0.1259 | +0.0663 |
| Implied wage share (1-rho1) | 0.7831 | 0.7554 | -0.0277 |
| R-squared | 0.6873 | 0.2752 | -0.4121 |
| rho1 s.e. | 0.0040 | 0.0128 | — |
| rho2 s.e. | 0.0061 | 0.0292 | — |

### Chow test

| Statistic | Value |
|-----------|-------|
| F | 2.3991 |
| df1, df2 | 2, 92 |
| p-value | **0.0965** |
| Decision | **NOT REJECTED** at 5% (marginal at 10%) |

### Interpretation

The Chow test fails to reject parameter stability at 5%, but the point estimates
tell a coherent story:

**Level shift (rho1_star = +0.028):** The structural profit share attractor
rises from 0.217 to 0.245 post-1974. Capital's structural power in the
distributional bargain increases — consistent with the end of the Fordist
accord, weakening of organized labor, and the shift toward financialized
accumulation. The implied wage share falls from 78.3% to 75.5%.

**Slope shift (rho2_star = +0.066):** The Goodwin slope *doubles* from 0.060
to 0.126. The utilization-distribution nexus becomes *more* sensitive post-1974,
not less. This is surprising if one expects stagflation to decouple the reserve
army mechanism. Instead, it suggests that the Goodwin channel *tightened*: each
unit of excess demand exerts stronger pressure on distribution in the
post-Fordist period. One interpretation: the erosion of institutional buffers
(collective bargaining, regulated pricing) that smoothed the utilization-
distribution transmission in the Fordist era leaves the naked market mechanism
more exposed.

**R-squared collapse (0.69 -> 0.28):** The Phillips curve explains 69% of
distributional variance pre-1973 but only 28% post-1974. The Goodwin law
remains the dominant channel, but additional forces (financialization, global
labor arbitrage, sectoral recomposition) inject noise into the distributional
process that the simple bivariate Phillips curve cannot capture. This is not a
failure of the Goodwin mechanism — it is evidence that the post-Fordist
distributional regime is more complex, with the reserve army operating alongside
other channels.

**Statistical caution:** The Chow test p=0.097 means the parameter shift is
not statistically distinguishable from zero at conventional levels. The point
estimates are informative for narrative interpretation, but any structural
claim about a 1973 break should be qualified. A longer post-break sample or
additional distributional controls might sharpen identification.

---

## 7. Summary assessment

### What the estimation establishes

1. The three cointegrating vectors (MPF, Phillips, Goods Market) are jointly
   supported by the data (LR p=0.80). The structural model is not rejected.

2. theta_t(pi) = 5.165 - 11.181*pi_t delivers a Fordist-mean elasticity of
   2.92 — the US production function is distribution-conditioned, with the
   elasticity falling as the profit share rises (capital deepening under high
   profits yields diminishing returns at the frontier).

3. The full 3x3 alpha structure is needed: both testable zeros in the loading
   matrix are rejected. Capital responds directly to distributional disequilibrium
   (Stage 2a) and distribution responds directly to the goods market gap
   (Stage 2b). The three ECTs are genuinely distinct adjustment channels.

4. The Phillips curve regime shift at 1973 is suggestive but not statistically
   significant at 5%. Point estimates indicate a modest rise in the profit share
   attractor and a doubling of the Goodwin slope, with a sharp decline in
   explanatory power.

### Open issues

1. **Identity closure:** The level-space identity check fails (max 19.7% vs
   1% tolerance). The formula needs correction for the log-linear normalization.
   This does not affect the structural parameters or the ECT series.

2. **Internal consistency (psi/gamma2 vs 1/rho2):** The goods market vector
   diverges from the Cambridge-Kaldor saving structure. CV3 may need
   reinterpretation or the inclusion of additional channels.

3. **Stage 3 power:** The Chow test at p=0.097 is underpowered for a sample
   split at 45/51. Rolling-window or recursive estimation could provide
   complementary evidence on parameter instability.

---

*Generated from `21_vecm_structural_us.R` output, 2026-04-04*
*Authority: Ch2_Outline_DEFINITIVE.md | us_structural_identification.md*
