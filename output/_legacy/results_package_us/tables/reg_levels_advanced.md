# Advanced Regression Analysis: US Fordist Era (1940–1978)

## Specification

- **Dependent variable:** $\ln Y_t$ — log real income (level)

- **Regressors:**

  - $r_t$ — profit rate (level)

  - $RR_t$ — reversal risk

  - $GD_t$ — gross dysfunction

- **Sample:** 39 observations (1940–1978)


---


# Block V.A — ARDL Bounds Testing for Cointegration

## A1. ARDL Model — BIC Lag Selection

### Short-Run Estimates

```

Call:
dynlm::dynlm(formula = full_formula, data = data, start = start, 
    end = end)

Residuals:
       Min         1Q     Median         3Q        Max 
-0.0098737 -0.0029931 -0.0002633  0.0021399  0.0100932 

Coefficients:
              Estimate Std. Error t value Pr(>|t|)    
(Intercept) -0.3926273  0.1185751  -3.311  0.00243 ** 
L(log_Y, 1)  1.0021422  0.0049791 201.271  < 2e-16 ***
r_t          0.0037008  0.0050639   0.731  0.47056    
L(r_t, 1)    0.0008747  0.0044329   0.197  0.84491    
RR_t        -0.4743532  0.0477386  -9.936 5.31e-11 ***
L(RR_t, 1)   0.0788489  0.0425020   1.855  0.07342 .  
GD_t         0.2415516  0.1289856   1.873  0.07088 .  
L(GD_t, 1)   0.7428104  0.1113029   6.674 2.16e-07 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 0.00515 on 30 degrees of freedom
Multiple R-squared:  0.9999,	Adjusted R-squared:  0.9999 
F-statistic: 3.839e+04 on 7 and 30 DF,  p-value: < 2.2e-16

```

### Long-Run Multipliers

```
         Term    Estimate  Std. Error    t value  Pr(>|t|)
1 (Intercept)  183.278930  376.356972  0.4869816 0.6298106
2         r_t   -2.135836    3.914525 -0.5456183 0.5893627
3        RR_t  184.621922  415.928983  0.4438785 0.6603157
4        GD_t -459.501446 1028.626567 -0.4467136 0.6582901
```

### Bounds F-Test

```

	Bounds F-test (Wald) for no cointegration

data:  d(log_Y) ~ L(log_Y, 1) + L(r_t, 1) + L(RR_t, 1) + L(GD_t, 1) +     d(r_t) + d(RR_t) + d(GD_t)
F = 17.567, p-value = 1e-06
alternative hypothesis: Possible cointegration
null values:
   k    T 
   3 1000 

```

**F = 17.5675** | I(0) 5% CV = 2.86 | I(1) 5% CV = 4.01

## A2. ARDL Model — AIC Lag Selection

### Short-Run Estimates

```

Call:
dynlm::dynlm(formula = full_formula, data = data, start = start, 
    end = end)

Residuals:
       Min         1Q     Median         3Q        Max 
-0.0098737 -0.0029931 -0.0002633  0.0021399  0.0100932 

Coefficients:
              Estimate Std. Error t value Pr(>|t|)    
(Intercept) -0.3926273  0.1185751  -3.311  0.00243 ** 
L(log_Y, 1)  1.0021422  0.0049791 201.271  < 2e-16 ***
r_t          0.0037008  0.0050639   0.731  0.47056    
L(r_t, 1)    0.0008747  0.0044329   0.197  0.84491    
RR_t        -0.4743532  0.0477386  -9.936 5.31e-11 ***
L(RR_t, 1)   0.0788489  0.0425020   1.855  0.07342 .  
GD_t         0.2415516  0.1289856   1.873  0.07088 .  
L(GD_t, 1)   0.7428104  0.1113029   6.674 2.16e-07 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 0.00515 on 30 degrees of freedom
Multiple R-squared:  0.9999,	Adjusted R-squared:  0.9999 
F-statistic: 3.839e+04 on 7 and 30 DF,  p-value: < 2.2e-16

```

### Long-Run Multipliers

```
         Term    Estimate  Std. Error    t value  Pr(>|t|)
1 (Intercept)  183.278930  376.356972  0.4869816 0.6298106
2         r_t   -2.135836    3.914525 -0.5456183 0.5893627
3        RR_t  184.621922  415.928983  0.4438785 0.6603157
4        GD_t -459.501446 1028.626567 -0.4467136 0.6582901
```

### Bounds F-Test

```

	Bounds F-test (Wald) for no cointegration

data:  d(log_Y) ~ L(log_Y, 1) + L(r_t, 1) + L(RR_t, 1) + L(GD_t, 1) +     d(r_t) + d(RR_t) + d(GD_t)
F = 17.567, p-value = 1e-06
alternative hypothesis: Possible cointegration
null values:
   k    T 
   3 1000 

```

**F = 17.5675** | I(0) 5% CV = 2.86 | I(1) 5% CV = 4.01

## A3. Bounds F-Test Summary

| Specification | F-statistic | I(0) 5% CV | I(1) 5% CV | Verdict |
|--------------|------------|-----------|-----------|---------|
| BIC | 17.5675 | 2.86 | 4.01 | Cointegration |
| AIC | 17.5675 | 2.86 | 4.01 | Cointegration |


## A4. Case Selection (Pesaran et al., 2001)

The dependent variable $\ln Y_t$ is a level with a deterministic trend, corresponding to **Case IV** (unrestricted intercept + unrestricted trend). The ARDL package default is Case III (unrestricted intercept, no trend), so the critical values reported are slightly conservative.


---

# Block V.B — VECM: Cointegration Rank and Long-Run Structure

## B1. VAR Lag-Length Selection

- BIC-optimal VAR lag: **2** (4-variable system)

## B2. Johansen Cointegration Rank Tests

### Trace Test

| r ≤ | Test Stat | 5% CV | Decision |
|-----|----------|-------|----------|
| r = 0 | 8.5750 | 53.3400 | Fail to reject (r = 0) |
| r ≤ 1 | 32.6352 | 34.9100 | Fail to reject (r = 1) |
| r ≤ 2 | 76.5394 | 19.9600 | Reject (r > 2) |
| r ≤ 3 | 160.8350 | 9.2400 | Reject (r > 3) |


### Max-Eigenvalue Test

| r ≤ | Test Stat | 5% CV | Decision |
|-----|----------|-------|----------|
| r = 0 | 8.5750 | 27.0700 | Fail to reject (r = 0) |
| r ≤ 1 | 24.0602 | 21.0700 | Reject (r > 1) |
| r ≤ 2 | 43.9042 | 14.0700 | Reject (r > 2) |
| r ≤ 3 | 84.2956 | 3.7600 | Reject (r > 3) |


## B3. Rank Assessment

- Trace test: **r = 0**, Max-eigen test: **r = 0**

Both tests agree.

No cointegration detected; VAR in differences would be appropriate.

## B4. VECM Estimation (r = 1)

### Normalized cointegrating relationship

$\ln Y_t$ + (0.2176)·$r_t$ + (15.3328)·$RR_t$ + (-34.5271)·$GD_t$ = $ECT_t$


---

# Block V.C — Dynamic OLS (DOLS)

DOLS estimated via `cointReg` (Saikkonen, 1991; Stock & Watson, 1993)

## DOLS Estimates (p = 1 lead/lag, n = 39)

### DOLS Coefficients (Long-Run)

| Variable | Estimate | Std. Error | t-value | p-value |
|----------|----------|------------|---------|--------|
| r | -0.249732 | 0.242917 | -1.0281 | 0.3108 |
| RR | -15.327144 | 0.554966 | -27.6182 | 0.0000 |
| GD | 38.388532 | 5.064315 | 7.5802 | 0.0000 |


### Interpretation

- The profit rate coefficient is **-0.249732** (t = -1.0281, p = 0.3108).

- DOLS corrects for endogeneity and serial correlation via leads and lags.


---

# Block V.D — Cross-Model Comparison: Long-Run Coefficients

| Model | r | RR | GD | Method |
|-------|-------|----|----|--------|
| VECM (r=1) | 1.0000 | 0.2176 | 15.3328 | -34.5271 | Normalized β |
| DOLS (p=1) | -0.2497 | -15.3271 | 38.3885 | Dynamic OLS |


---

*Report generated:  2026-04-14 17:16:19 *

## References

- Pesaran, M.H., Shin, Y. & Smith, R.J. (2001). *JAE*, 16(3), 289–326.
- Natsiopoulos, K. & Tzeremes, N.G. (2022). *JAE*, 37(5), 1079–1090.
- Saikkonen, P. (1991). *Econometric Theory*, 7, 1–21.
- Stock, J.H. & Watson, M.W. (1993). *Econometrica*, 61(4), 783–820.
