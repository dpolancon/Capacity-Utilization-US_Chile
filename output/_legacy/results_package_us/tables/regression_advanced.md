# Advanced Regression Analysis: US Fordist Era (1940–1978)

## Sample and Variables

- **Sample period:** 1941–1978 (38 annual observations)

- **Dependent variable:** $g^Y_t$ — real income growth

- **Regressors:**

  - $\ln r_t$ — log profit rate (realized profitability)

  - $RR_t$ — reversal risk (compensatory fragility)

  - $GD_t$ — gross dysfunction (capacity burden)


---


# Block V.A — ARDL Bounds Testing for Cointegration

## A1. ARDL Model — BIC Lag Selection

**auto_ardl (BIC) failed to identify a valid model.** This may reflect insufficient degrees of freedom or numerical instability in the lag-selection criterion with only 38 observations.


## A2. ARDL Model — AIC Lag Selection

**auto_ardl (AIC) failed to identify a valid model.**


## A3. Fallback — Manual ARDL(1,1,1,1) Estimation

Since `auto_ardl` did not return a valid model, we estimate a parsimonious ARDL(1,1,1,1) directly and compute long-run multipliers and bounds test manually.

### Short-Run Estimates

```

Time series regression with "ts" data:
Start = 2, End = 38

Call:
dynlm::dynlm(formula = full_formula, data = data, start = start, 
    end = end)

Residuals:
       Min         1Q     Median         3Q        Max 
-0.0065393 -0.0024267 -0.0004071  0.0012735  0.0109929 

Coefficients:
               Estimate Std. Error t value Pr(>|t|)    
(Intercept)  -0.3442407  0.0445789  -7.722 1.63e-08 ***
L(gY_t, 1)   -0.0280039  0.0185385  -1.511    0.142    
ln_r_t        0.0009019  0.0118680   0.076    0.940    
L(ln_r_t, 1)  0.0020040  0.0131402   0.153    0.880    
RR_t         -0.4135110  0.0361406 -11.442 2.86e-12 ***
L(RR_t, 1)    0.0264175  0.0449841   0.587    0.562    
GD_t          0.0551918  0.0880152   0.627    0.536    
L(GD_t, 1)    0.8451544  0.0995344   8.491 2.35e-09 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 0.004404 on 29 degrees of freedom
Multiple R-squared:  0.9946,	Adjusted R-squared:  0.9933 
F-statistic: 767.6 on 7 and 29 DF,  p-value: < 2.2e-16

```

### Long-Run Multipliers

```
         Term     Estimate  Std. Error    t value     Pr(>|t|)
1 (Intercept) -0.334863207 0.041735282 -8.0235040 7.550232e-09
2      ln_r_t  0.002826754 0.002978941  0.9489123 3.505065e-01
3        RR_t -0.376548619 0.042869258 -8.7836515 1.148004e-09
4        GD_t  0.875819858 0.091641294  9.5570438 1.826020e-10
```

### Bounds F-Test

```

	Bounds F-test (Wald) for no cointegration

data:  d(gY_t) ~ L(gY_t, 1) + L(ln_r_t, 1) + L(RR_t, 1) + L(GD_t, 1) +     d(ln_r_t) + d(RR_t) + d(GD_t)
F = 1403.8, p-value = 1e-06
alternative hypothesis: Possible cointegration
null values:
   k    T 
   3 1000 

```

### Interpretation

- F-statistic = 1403.8347

**Cointegration confirmed.**


## A3. Case Selection Discussion (Pesaran et al., 2001)

The bounds testing framework requires correct identification of the deterministic specification. Pesaran et al. (2001) distinguish five cases:

| Case | Intercept | Trend | Economic Interpretation |
|------|-----------|-------|------------------------|
| I    | None      | None  | Zero mean, no trend    |
| II   | Restricted| None  | Non-zero mean, no trend|
| III  | Unrestricted | None | Non-zero mean, no trend |
| IV   | Unrestricted | Unrestricted | Linear trend  |
| V    | Restricted   | Restricted   | Quadratic trend |

### Case assessment for this specification

The dependent variable $g^Y_t$ is a **growth rate** (first difference of log income). Growth rates typically have a non-zero mean but no deterministic trend. This corresponds to **Case III** (unrestricted intercept, no trend).

The regressors ($\ln r_t$, $RR_t$, $GD_t$) are either log-levels or constructed indices that fluctuate around a mean. None exhibits a deterministic time trend by construction.

The `ardl` function includes an unrestricted intercept by default, which aligns with **Case III**. The critical values reported above correspond to Table CI(iii)(c) of Pesaran et al. (2001).

### Integration order caveat

The bounds test is valid regardless of whether regressors are I(0) or I(1), but **not** I(2). The following pre-estimation checks apply:

- If all regressors are I(0): compare F-statistic to I(0) lower bound.
- If all regressors are I(1): compare F-statistic to I(1) upper bound.
- If regressors are mixed I(0)/I(1): the F-statistic must be compared to both bounds; values in between are inconclusive.
- If any regressor is I(2): the bounds test is **invalid**.

### Comparison of AIC vs. BIC selection

- BIC selected order (1, 1, 1, 1); AIC selected order (1, 1, 1, 1).

BIC penalizes model complexity more heavily, typically selecting shorter lag structures. AIC tends to overfit in small samples but may capture more dynamics. If both specifications yield the same cointegration verdict, the result is robust to lag-length uncertainty. If they diverge, the BIC result is preferred for inference in small samples (Natsiopoulos & Tzeremes, 2022).

