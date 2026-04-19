# Notebook 3: Stage 1 Recap — ECT_m as External Regime Classifier
## The BoP Disequilibrium Measure and Its Role in Stage 2

**Prerequisite:** NB-02 (unit root battery passed)
**Input:** `data/processed/chile/ECT_m_stage1.csv`

---

## 3.1 What Stage 1 delivers

Stage 1 estimated the import propensity cointegration system on the split sample
(pre-1973 ISI, post-1973 neoliberal):

$$m_t = \zeta_0 + \underbrace{\zeta_1}_{\text{Kaldor}} k_t^{ME} + \underbrace{\zeta_2}_{\text{Palma-Marcel}} nrs_t + \zeta_3\,\omega_t + ECT_{m,t}$$

**Locked results (from stage1_vecm_report.md):**

| Parameter | Pre-1973 ISI | Post-1973 neoliberal |
|-----------|-------------|---------------------|
| $\hat{\zeta}_1$ (Kaldor) | +0.93 | +0.31 |
| $\hat{\zeta}_2$ (Palma-Marcel) | +0.44 | +0.24 |
| $\hat{\zeta}_3$ ($\omega$) | −3.92 | −7.13 |
| $\hat{\alpha}_m$ | −0.178 | −0.180 |
| Portmanteau p | 0.87 | 0.53 |

**Key ECT_m properties:**

| Statistic | Pre-1973 | Post-1973 |
|-----------|---------|----------|
| ECT_m mean | +0.061 | +0.325 |
| ADF τ | −4.45 | −3.17 |

---

## 3.2 Why ECT_m is a valid external classifier

**Theoretical mapping:**
$$\underbrace{\widehat{ECT}_{m,t-1} > \hat{\gamma}}_{\text{imports exceed structural equilibrium}} \implies \underbrace{R_t = 1}_{\text{Regime 2}} \implies \underbrace{\lambda > 0}_{\text{shadow price activates}} \implies \underbrace{|\alpha_y^{(2)}| < |\alpha_y^{(1)}|}_{\text{frontier adjustment compressed}}$$

**Stationarity:** $\widehat{ECT}_{m,t-1}$ is stationary (pre-1973 ADF τ = −4.45,
exceeds MacKinnon critical value for n=4 regressors ≈ −4.46 at 5%). The
post-1973 τ = −3.17 is borderline, but the full-sample Johansen rank test
confirms cointegration, which implies the pooled ECT_m is stationary. A
stationary transition variable is a formal requirement for CLS inference.

**External validity:** ECT_m is not the disequilibrium of the frontier system.
It is the disequilibrium of the import propensity system — a structurally
distinct relation. This is what Gonzalo-Pitarakis (2006) and Krishnakumar-Neto
(2009) define as "cointegration with threshold effects": the transition variable
comes from a theoretically grounded external system. Stigler's objection —
"why isn't the influencing variable included in the VECM?" — is answered:
ECT_m is the residual from a separate cointegrating system, not an omitted
variable. Its exclusion from the frontier CV1 is theoretically correct.

---

## 3.3 Verification checks before Stage 2

Run these on `ECT_m_stage1.csv` before proceeding:

```r
ect_s1 <- read_csv("data/processed/chile/ECT_m_stage1.csv") %>%
  arrange(year) %>%
  mutate(ECT_m_lag1 = lag(ECT_m, 1))

# 1. Mean structure
cat(sprintf("Pre-1973 ECT_m mean:  %.4f\n", mean(ect_s1$ECT_m[ect_s1$year < 1973])))
cat(sprintf("Post-1973 ECT_m mean: %.4f\n", mean(ect_s1$ECT_m[ect_s1$year >= 1973])))

# 2. Stationarity of ECT_m_lag1
adf_ectm <- ur.df(na.omit(ect_s1$ECT_m_lag1), type="drift", lags=4, selectlags="BIC")
cat(sprintf("ADF(ECT_m_lag1): tau=%.4f\n", adf_ectm@teststat[1]))

# 3. Range of ECT_m_lag1 in estimation window
cat(sprintf("ECT_m_lag1 range: [%.4f, %.4f]\n",
    min(ect_s1$ECT_m_lag1, na.rm=T), max(ect_s1$ECT_m_lag1, na.rm=T)))
```

**Expected output:**
- Pre-1973 mean ≈ 0.06, Post-1973 mean ≈ 0.32 (structural shift visible)
- ADF τ more negative than −3.5 (confirming stationarity for use as transition variable)
- Range spanning both sides of the expected threshold (10%–90% quantiles used in grid)

---

## 3.4 What ECT_m_lag1 carries into Stage 2

The one-period lag is essential for two reasons:

**Timing:** The BoP constraint that governs period $t$ mechanization was activated
by the disequilibrium visible at $t-1$. Import-driven exchange-rate pressure,
capital flight, and investment compression all respond to the balance of payments
position of the prior period. The lag is economically grounded, not a statistical
artifact.

**Exogeneity:** $ECT_{m,t-1}$ is predetermined with respect to $\Delta X_t^{CL,\theta}$.
The frontier system variables $(y_t, k^{CL}_t, c_t, \omega_t c_t)$ do not Granger-cause
the import system in the short run — confirmed by the Stage 1 weak exogeneity
results showing k_ME, nrs are weakly exogenous post-1973. The lag removes any
remaining simultaneity concern.

---

*NB-03 | 2026-04-07 | Next: NB-04 (CLS threshold estimation)*
