---
type: audit
status: active
depends_on:
  - chapter2_vault/03_econometrics/E18_Parameter_Stability_Audit_Protocol_Lock.md
  - chapter2_vault/03_econometrics/E17_Cointegration_Significance_Stars_Lock.md
  - chapter2_vault/08_audits/2026-08-03_section31_cointegration_stars_audit.md
stage_scope: all_stages
country: US
last_updated: 2026-08-03
updated_by: SECTION31_STABILITY_AUDIT
layer: audit
role: cointegration_failure_diagnostic_memo
stage: post-estimation-diagnostics
tags:
  - chapter2/econometrics
  - chapter2/cointegration
  - chapter2/imols
  - chapter2/structural-breaks
  - chapter2/audit
subtype: audit_memo
blocks: []
scope: chapter2
priority: reference
---

# Audit: Why Section 3.1 Found No Cointegration — Diagnostic Battery

**Question asked**: the Section 3.1 IM-OLS report reported overwhelming evidence *against*
cointegration (residual ADF failing to reject in 16/18 models, Shin LM rejecting cointegration in
18/18, VW Type 2 rejecting in 16/18). Why?

**Headline answer**: **primarily because the residual ADF test was mis-implemented.** It ran an
*unaugmented* Dickey-Fuller on strongly autocorrelated residuals while comparing the result to
critical values tabulated for the *augmented* test. Correcting the augmentation reverses the finding
from **2/18 to 18/18 models rejecting "no cointegration"** (16/18 at the stricter 5% level).

A genuine secondary finding survives the correction: the underlying relationship **is** structurally
unstable, breaking around **1974** (and secondarily the mid-1940s). That instability is real, but it
is absorbed by the Bai-Perron step dummies already in the specification — it was never the reason the
cointegration tests failed.

This is the second defect of the same family found in this report in one session. The first
(`2026-08-03_section31_cointegration_stars_audit.md`) was a correctly-computed statistic compared to
wrong critical values. This one is a statistic that does not match the methodology it is named after.

---

## 1. What was ruled out first

**I(2) / specification inadmissibility — excluded.** `codes/US_S33_integration_order_appendix_battery.R`
had already tested the interaction terms directly (double and triple, both capital variants, all 8
ω variants); every one returned **I(1)**. This audit additionally closed two gaps S33 left open, by
testing the series *exactly as S50 constructs them*:

- the **lagged** interaction terms (S33 tested contemporaneous ones) → **I(1)**, verdict carries over;
- `omega_ST_Tier2_GVA_adj` **standalone**, never previously tested despite being the
  constitution-mandated wage share → **I(1)**.

One term (M2.9's triple interaction) returned "ambiguous" under the ADF+KPSS combination and is
flagged for follow-up. The Integration Order Gate otherwise passes, so regressor admissibility is not
the explanation.

---

## 2. The defect

`codes/US_S50_section31_imols_estimation.R` computed the Engle-Granger residual test as

```r
eg_lm <- lm(diff(u) ~ u[-T_obs] - 1)   # zero lagged differences
t_adf <- summary(eg_lm)$coefficients[1, 3]
```

— a plain Dickey-Fuller with **no lag augmentation**, compared against `cv_adf()`'s MacKinnon (2010)
critical values, which are tabulated for the **augmented** test.

The IM-OLS residuals are strongly serially correlated: first-order autocorrelation **0.81–0.96**,
Yule-Walker AIC selecting **AR(2)–AR(4)**. Lag augmentation exists precisely to whiten such errors;
without it the DF test is severely biased toward non-rejection.

### Sensitivity to lag order (all 18 models, 5% level)

| Lag order | Rejections of $H_0$: no cointegration |
|---|---|
| $p=0$ — **as shipped in v2** | **2 / 18** |
| $p=1$ | 14 / 18 |
| $p=2$ | 9 / 18 |
| $p=3$ | 9 / 18 |
| $p=4$ | 5 / 18 |
| **AIC-selected** | **16 / 18** |
| **BIC-selected** | **16 / 18** |

AIC and BIC select the same lag order in **17 of 18** models; even minimal $p=1$ augmentation already
flips the verdict. The decline at $p \ge 4$ is the expected power loss from over-augmentation at
$T=94$. The reversal is therefore **not** a lag-selection artifact.

At the 10% level used for the report's lowest significance tier, the AIC-selected test rejects in
**18/18**.

### Before / after, per model

| Model | v2 (DF, $p=0$) | Corrected (AIC) | Lag | Model | v2 (DF, $p=0$) | Corrected (AIC) | Lag |
|---|---|---|---|---|---|---|---|
| M1.1 | −2.26 | **−4.67** | 1 | M2.4 | −1.88 | **−4.00** | 3 |
| M1.2 | −1.73 | **−4.35** | 1 | M2.5 | −2.08 | **−4.03** | 1 |
| M1.3 | −2.56 | **−4.90** | 1 | M2.6 | −1.63 | **−4.34** | 3 |
| M1.4 | −2.13 | **−4.50** | 1 | M2.7 | −2.00 | **−3.79** | 1 |
| M1.5 | −4.68 | −4.47 | 1 | M2.8 | −1.71 | **−4.09** | 3 |
| M1.6 | −4.51 | −4.60 | 1 | M2.9 | −2.16 | **−3.89** | 1 |
| M2.1 | −2.05 | **−4.46** | 1 | M2.10 | −2.97 | **−5.44** | 1 |
| M2.2 | −1.67 | **−4.26** | 3 | M2.11 | −2.21 | **−3.95** | 1 |
| M2.3 | −1.96 | **−4.15** | 1 | M2.12 | −2.95 | **−5.66** | 3 |

Only M1.5 and M1.6 — the two models that already rejected — move slightly the "wrong" way, which is
the expected small cost of augmentation where it was not needed.

### Caveat that limits the strength of the reversal

The residuals come from a regression that also contains **endogenously-selected** Bai-Perron step
dummies. Standard Engle-Granger critical values do not account for estimated break dates and are
therefore somewhat **liberal** here. The Gregory-Hansen test, which treats the break as endogenous by
construction, is the appropriate break-robust cross-check and is reported alongside in the companion
report. The honest statement is: cointegration is supported under the corrected test, with the
break-dummy caveat noted.

---

## 3. The genuine secondary finding: instability around 1974

Correcting the ADF does not make the instability go away — it relocates its role in the argument.

- **CUSUM family, run on the core specification with step dummies deliberately excluded** (they were
  selected from a break audit on these very residuals, so including them would absorb the instability
  the test exists to detect): `supF` rejects stability in **18/18** models (p < 0.001); OLS-CUSUM
  p = 0.002–0.046. Break dates are **1974**, **1948** and **1945**.
- **Gregory-Hansen regime-shift scan**: break estimates cluster at **1976–1977 (15 of 18 models)**,
  with 17 of 18 falling in 1972–1977 and a single outlier at 1959 (M2.9). The GH *statistic* itself,
  however, rejects its own null of no cointegration in only **1/18** models at 5% (M2.4, p = 0.034)
  and 3/18 at 10% (adding M2.2 p = 0.066 and M2.8 p = 0.096).
- **Hansen (1992) $L_c$ on the model *as estimated*** (i.e. *with* the step dummies): does **not**
  reject parameter stability. Self-normalization verified (independent i.i.d. and AR-sieve nulls
  agree to within 1%).

These three are consistent, not contradictory: the relationship is genuinely unstable, and the step
dummies already in the specification absorb that instability. What they could never do is fix a
mis-specified unit-root test.

**Per-parameter $L_c$ decomposition** (descriptive; see §4 for why not inferential) locates the
instability in the **step-dummy coefficients** (Lc ≈ 5–38) rather than the structural parameters
(intercept ≈ 4.4, $\hat\theta_0$ ≈ 4.6, $\hat\theta_1$ ≈ 2.7). The capital elasticity itself is
comparatively stable; what moves is the level.

**Shin LM reconciliation**: Shin's $C$ is Hansen's $L_c$ restricted to intercept-only variation — an
identity verified exactly (max relative error $3\times10^{-16}$) across all 18 models. So the 18/18
Shin rejection was always a statement about *intercept* instability, not about cointegration failure
in general. Its apparent conflict with the non-rejecting $L_c$ is a long-run-variance normalization
difference: Shin uses `cointReg`'s conditional $\omega_{u\cdot v}$, Hansen the score-process Bartlett
LRV; these differ by roughly an order of magnitude on this data.

---

## 4. What this audit does NOT claim

Recorded explicitly, per the AI-research-failure-mode checklist (modes 2 "hallucinated results",
4 "bug-as-insight", 5 "methodology fabrication"):

1. **The hand-rolled Hansen bootstrap subset statistic is not used for inference.** `Lc_core` inverts
   the submatrix $V_{\text{core,core}}$, ignoring covariance with the nuisance step-dummy scores. It
   failed the self-normalization check (i.i.d. vs AR-sieve null medians 31.1 vs 23.3 on M1.1, against
   390.3 vs 384.6 for the well-behaved `Lc_all`). It is reported as a descriptive magnitude only.
   Inferential instability verdicts come from `strucchange`'s published asymptotics.
2. **A cointegration failure was *not* reinterpreted as a substantive regime-switching finding.** The
   first bootstrap run returned Hansen p ≈ 0.96 — "parameters are stable." That contradicted every
   other diagnostic and was treated as an implementation problem to investigate, not as a result.
   Investigating it is what surfaced the ADF defect.
3. **A defect in this audit's own code was found and fixed mid-run.** The Gregory-Hansen inner ADF
   (`.adf_t`) initially replicated the very unaugmented-DF bug being audited, inherited from copying
   the repo's `sbvecm_adf_stat` convention. The first production run was discarded and rerun after
   the fix.
4. **The 1974 / 1977 / 1945 break dates are reported as they came out**, including the disagreement
   between CUSUM (1974) and Gregory-Hansen (1977) and the Bai-Perron dates already in the report
   (1944, 1965–68, 1981–82, 1996–99, 2010). No date was selected to fit a narrative.

---

## 5. Artifacts

| Artifact | Path |
|---|---|
| Shared stability-test module | `codes/COMMON_cointegration_stability_tests.R` |
| Stability audit script | `codes/US_S51_section31_stability_audit.R` |
| ADF lag-sensitivity table | `output/US/S51_SECTION31_STABILITY/csv/s51_adf_lag_sensitivity.csv` |
| Hansen triad + per-parameter Lc | `.../csv/s51_hansen_instability.csv`, `.../csv/s51_hansen_per_parameter_lc.csv` |
| CUSUM tests | `.../csv/s51_cusum_tests.csv` |
| Gregory-Hansen | `.../csv/s51_gregory_hansen.csv` |
| Regime-split re-estimation | `.../csv/s51_regime_split_reestimation.csv` |
| Integration-order gap closure | `.../csv/s51_integration_order_gap_closure.csv` |
| Verdict ledger | `.../csv/s51_verdict_ledger.csv` |
| Validation records | `.../csv/s51_validation_shin_lc_identity.csv`, `.../csv/s51_validation_bootstrap_sanity.csv` |
| Governing lock | `chapter2_vault/03_econometrics/E18_Parameter_Stability_Audit_Protocol_Lock.md` |

---

## 6. Follow-ups

1. **The same unaugmented-DF defect exists elsewhere**: `sbvecm_adf_stat()` / `gh_design()` in
   `codes/CL_S20_structural_break_dual_route_audit.R` and its consumers across the Chile
   S20/S30/S90/S95/S99 chain. Those results should be re-derived with `adf_t_augmented()`.
2. **Revisit downstream narrative.** Any Chapter 2 text that reads the Section 3.1 cointegration
   failure as substantive evidence (e.g. of structural regime-switching or of the price channel being
   unidentified) rests on the superseded result and must be rewritten.
3. **Resolve M2.9's ambiguous integration-order verdict** for its triple interaction term.
4. **Fix or drop `Lc_core`** — implement the partitioned-inverse (Schur complement) subset statistic
   properly, or remove it in favour of `Lc_all` plus the descriptive per-parameter decomposition.
5. **Shin critical values remain unverified** (carried over from the previous audit).
