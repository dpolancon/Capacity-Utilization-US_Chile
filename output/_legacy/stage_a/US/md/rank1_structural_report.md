# Rank-1 Structural Identification — US NF Corporate Sector

**Script:** `codes/stage_a/us/42_rank1_check.R`  
**State vector:** X = (y, k, omega, omega*k)' + ecdet="const"  
**Data:** 1929-2024 (96 obs) | K=2 | spec="longrun"  
**Date:** 2026-04-06

---

## 1. Motivation

The full system identifies r=3 cointegrating vectors (Section 3 of the main
report). The structural content of the MPF resides in CV1 — the first
eigenvector. This section estimates the system at r=1 to verify that the
MPF identification does not depend on the additional rank, and recovers
capacity utilization from the single cointegrating relation.

---

## 2. Eigenvector (y-normalized)

| Variable | Coefficient | Structural role |
|----------|------------|-----------------|
| y | 1.0000 | normalization |
| k | -8.9238 | -alpha1 (base elasticity) |
| omega | -222.1611 | -gamma (direct distributional level shift) |
| omega_k | +12.8509 | -alpha2 (distribution-capital interaction) |
| const | +138.2544 | -c1 |

**Identical to the first eigenvector under r=3.** The Johansen procedure
returns the same beta_1 regardless of the rank specification — eigenvectors
are ordered by eigenvalue.

---

## 3. Structural content: the MPF

    y = 8.924*k + 222.161*omega - 12.851*(omega*k) - 138.254

Distribution-conditioned transformation elasticity:

    theta(omega) = 8.924 - 12.851*omega

| Object | Value |
|--------|-------|
| alpha1 (base elasticity) | 8.9238 |
| alpha2 (distribution slope) | -12.8509 |
| gamma (direct omega) | 222.1611 |
| c1 (constant) | -138.2544 |
| theta at mean omega (0.623) | 0.921 |
| theta range [omega_min, omega_max] | [0.214, 1.666] |
| omega_H (theta=1, knife-edge) | 0.617 — **inside sample** |
| omega* (theta=0, crisis boundary) | 0.694 — outside sample |

---

## 4. Eigenvalue and trace test

| | Value |
|---|---|
| lambda_1 | 0.5901 |
| Trace stat (r<=0) | 159.26 |
| 5% critical value | 53.12 |
| Decision | **Reject r=0** at any conventional level |

The first eigenvalue alone carries overwhelming evidence of cointegration.

---

## 5. Alpha loading (r=1)

| Variable | alpha | SE | t-stat |
|----------|------:|---:|-------:|
| d(y) | +0.011 | 0.015 | 0.74 |
| d(k) | +0.024 | 0.008 | 2.89** |
| d(omega) | +0.009 | 0.003 | 3.11** |
| d(omega_k) | +0.131 | 0.046 | 2.86** |

Under r=1, output does not error-correct to the MPF (t=0.74). Capital and
distribution adjust: k responds positively (accumulation absorbs excess
capacity), omega responds positively (wage share adjusts to disequilibrium).

---

## 6. ECT stationarity

| | Value |
|---|---|
| ADF | -5.988 |
| p-value | <0.01 |
| Verdict | **I(0)** — strongly stationary |

---

## 7. Capacity utilization

### 7.1 Structural closure (mu)

Frontier pinned at mu(1948) = 0.80 (Federal Reserve benchmark). Growth
closure: g(Y*) = theta(omega_t) * g(K_t), accumulated forward and backward.

| Period | n | theta mean | mu mean |
|--------|---|-----------|---------|
| Pre-Fordist (1929-1944) | 16 | 0.831 | 0.780 |
| Fordist (1945-1973) | 29 | 0.787 | 0.734 |
| Post-Fordist (1974-2024) | 51 | 1.021 | 0.681 |

Key observations:

- **1943-44**: mu crosses 1.0 (wartime full capacity) — only years at the frontier
- **Depression (1932-33)**: mu ~ 0.58-0.60 — severe underutilization
- **Fordist plateau**: mu stabilizes at 0.73-0.76
- **Post-2004 decline**: mu falls from 0.74 to 0.53 (2022) as the super-Harrodian
  regime (theta > 1) makes the frontier grow faster than actual output
- **2024**: mu = 0.55 — economy at 55% of structural potential

### 7.2 ECT-based mu (mu_ect)

    mu_ect = exp(ECT1 - mean(ECT1))

Centered on 1 by construction. This measure captures the full cointegrating
residual (including the direct omega and constant terms).

| Period | mu_ect mean |
|--------|------------|
| Pre-Fordist | 1.75 |
| Fordist | 1.12 |
| Post-Fordist | 0.94 |

The ECT-based measure shows a secular decline: the economy moves from
above-average frontier deviation (Pre-Fordist) to below-average (Post-Fordist).

---

## 8. Rank invariance — r=1 vs r=3

| Parameter | r=1 | r=3 |
|-----------|-----|-----|
| k (alpha1) | -8.9238 | -8.9238 |
| omega (gamma) | -222.1611 | -222.1611 |
| omega_k (alpha2) | +12.8509 | +12.8509 |
| const (c1) | +138.2544 | +138.2544 |
| theta(omega_bar) | 0.9206 | 0.9206 |

**Perfect agreement.** The MPF is identified by the dominant eigenvector
and does not require the additional cointegrating relations. The rank=3
system adds error correction channels (ECT2 disciplines distribution,
ECT3 is output-specific) but does not alter the structural content of
the frontier.

---

## 9. Robustness: restriction tests (from script 41)

The restriction omega=0, omega_k=1/2 is accepted across all three CVs
(LR=0.000, p=1.000). Under this restriction, alpha1=1 is rejected
for CV2 and CV3 (LR=17.06, p=0.0007), confirming alpha1 > 1.

However, this restriction compresses theta into [1.48, 1.54] — a narrow
super-Harrodian band that eliminates regime switching. The unrestricted
CV1 (alpha1=8.924, alpha2=-12.851) produces the wide theta range [0.21, 1.67]
that the theory requires.

---

## 10. Summary

| Object | Status |
|--------|--------|
| Specification | Absolute log-levels, uncentered interaction, r=1 |
| First eigenvalue | lambda_1=0.590, trace=159.26 >> cv=53.12 |
| ECT1 | I(0), ADF=-5.99 |
| theta(omega) | 8.924 - 12.851*omega — identical at r=1 and r=3 |
| Regime partition | 29% super-Harrodian, 71% sub-Harrodian |
| omega_H | 0.617 (in sample) |
| mu(1948) | 0.80 (pinned) |
| mu trajectory | 1.05 (1929) -> 0.73 (Fordist) -> 0.55 (2024) |
| Alpha | k and omega adjust; y does not error-correct at r=1 |
| Rank invariance | beta_1 identical at r=1 and r=3 |

---

*Script: `42_rank1_check.R` | Data: `rank1_theta_mu_us.csv`*  
*Plots: `r1_mu_capacity_utilization`, `r1_mu_ect`, `r1_theta_timeseries`*  
*All in `codes/stage_a/us/` and `output/stage_a/us/`*
