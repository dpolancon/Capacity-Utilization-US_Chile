---
type: econometrics
status: active
depends_on:
  - chapter2_vault/03_econometrics/E17_Cointegration_Significance_Stars_Lock.md
  - chapter2_vault/03_econometrics/E15_Vogelsang_Wagner_IMOLS_Cointegration_Test_Lock.md
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-08-03
updated_by: SECTION31_STABILITY_AUDIT
layer: governance_constraint
role: stability_audit_protocol_lock
stage: post-estimation-diagnostics
tags:
  - chapter2/econometrics
  - chapter2/cointegration
  - chapter2/imols
  - chapter2/structural-breaks
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# E18: Parameter Stability Audit Protocol Lock

> [!IMPORTANT]
> **Constitutional Declaration**: When a cointegration test battery returns a
> *failure* verdict, that failure must be **diagnosed**, not merely reported. This lock governs the
> diagnostic protocol: which stability tests are run, how their critical values are obtained, and how
> a failure to cointegrate is permitted to be interpreted. It implements the
> `umass-applied-econometrics` skill's Rule D (specification-space mapping), Rule H (political-economy
> interpretation of parameters and of failure), and Rule I (small-sample bootstrap).
>
> Reference implementation: `codes/COMMON_cointegration_stability_tests.R` (shared, reusable) and
> `codes/US_S51_section31_stability_audit.R` (Section 3.1 application).

---

## 1. The Shin–Hansen Bridge (why the existing triad was already an instability signal)

**Shin's (1994) $C$ statistic is Hansen's (1992) $L_c$ restricted to intercept-only parameter
variation.** With the regressor set restricted to the intercept, the score is $f_t = \hat u_t$, the
cumulated score is $S_t = \sum_{i\le t}\hat u_i$, and

$$L_c^{\text{intercept}} \;=\; \frac{1}{T}\sum_t \frac{S_t^2}{\hat\omega^2} \;=\; T \cdot C_{\text{Shin}}, \qquad C_{\text{Shin}} = \frac{\sum_t S_t^2}{T^2 \hat\omega^2}$$

This identity was **verified exactly (to machine precision, max relative error $3\times10^{-16}$)
across all 18 Section 3.1 models** and is enforced as a blocking pre-condition in
`US_S51_section31_stability_audit.R` — no Hansen result may be reported unless it holds.

**Governing consequence**: a Shin LM rejection is *already* evidence of parameter instability, not of
"no cointegration" in some undifferentiated sense. Any report presenting a Shin rejection **must not**
stop there; it must either decompose the rejection with the full Hansen $L_c$ (per-parameter and
joint) or explicitly state that the decomposition was not performed.

**LRV caveat (must be stated wherever both appear)**: the reported $L_c$ and the reported $C_{\text{Shin}}$
will not agree numerically, because $L_c$ estimates the long-run variance from the *score process*
(Bartlett kernel, Hansen's own formulation) while Shin uses `cointReg`'s *conditional* long-run
variance $\omega_{u\cdot v}$. On Section 3.1 data these differ by roughly an order of magnitude. Both
are defensible for their respective statistics; the identity above pins the functional form, not the
numerical value.

---

## 2. Bootstrap-Null Discipline (binding)

**Directive**: new cointegration or stability test statistics introduced into this repository
**must** obtain their inference from a bootstrapped null distribution, not from hardcoded critical
values, unless a properly indexed published table is digitized in full (as in
`codes/COMMON_VW_fixedb_critical_values.R`).

**Rationale**: the 2026-08-03 audit
(`chapter2_vault/08_audits/2026-08-03_section31_cointegration_stars_audit.md`) found the Section 3.1
report's headline defect was a correctly-computed statistic compared against hardcoded critical
values not indexed to bandwidth or regressor count. The pre-existing Gregory-Hansen implementation in
`CL_S20_structural_break_dual_route_audit.R` carries the identical exposure (hardcoded
−4.61/−4.99/−4.95). Bootstrapping removes the failure mode at the root.

**Robustness property worth recording**: bootstrap p-values are invariant to any strictly monotone
rescaling of the statistic, since the same transformation applies to the observed value and to every
replicate. A normalization constant differing from a published one therefore *cannot* corrupt
inference — only a wrong functional *form* could. This is why §1's exact-identity validation is the
binding check, not agreement of numerical levels.

### 2.1 Opposite nulls require opposite DGPs

This is the single most dangerous implementation error in this protocol. Transposing the two DGPs
silently inverts every p-value while producing entirely plausible-looking output.

| Test family | $H_0$ | Bootstrap DGP | Function |
|---|---|---|---|
| Hansen $L_c$/MeanF/SupF, CUSUM | Cointegration **with stable parameters** | Resample *stationary* residuals (moving block) | `boot_null_stationary()` |
| Gregory-Hansen | **No** cointegration | Cumulate resampled differences into a *random walk* | `boot_null_unitroot()` |

Block length defaults to the model's fitted long-run-variance bandwidth — the data-driven scale at
which serial dependence has already been estimated. An i.i.d. resample is **prohibited**: it destroys
exactly the dependence the statistics are normalized against.

**Mandatory guard**: `bootstrap_sanity_check()` exercises both DGPs against synthetic series with
known answers (a genuinely cointegrated pair and an independent-random-walk pair) and asserts the
four expected outcomes. It runs as a blocking pre-condition in `US_S51` and must be re-run whenever
`COMMON_cointegration_stability_tests.R` is modified.

---

## 3. Endogenously-Selected Dummies Must Be Excluded From Stability Tests

`US_S50_section31_imols_estimation.R` inserts Bai-Perron step dummies selected from a first-pass
break audit **on the very residuals** the stability tests examine. Including those dummies in a
CUSUM or Gregory-Hansen design would absorb the instability the test exists to detect and bias the
verdict toward spurious stability.

**Directive**: CUSUM-family and Gregory-Hansen tests run on the **core specification** — intercept
plus stochastic regressors, step dummies excluded. Hansen $L_c$ is reported *both* on the full fitted
design (to characterize what the estimated model actually does) and restricted to core parameters
(the substantively interpretable joint statistic). Any table reporting these must state which
specification it used.

**Related distinction (binding)**: step dummies test only for **level shifts**. They cannot absorb a
shift in the cointegrating *vector*. A specification that responds to detected breaks with step
dummies alone has not addressed slope instability, and must not be described as "break-robust" on
that basis. The Gregory-Hansen `C/S` (regime-shift) specification is the test that addresses slope
breaks.

---

## 4. Interpreting Failure (Rule H discipline)

The `umass-applied-econometrics` skill licenses reading a failure to cointegrate as evidence of
**structural regime-switching rather than data deficiency** — but that reading must be *earned*, not
asserted. This lock sets the evidentiary bar.

A regime-switching interpretation is permitted only when the audit establishes:

1. **Admissibility is not the explanation** — the Integration Order Gate passes for every regressor
   *as actually constructed in the estimated model* (including lag structure), per
   [[Interaction_Term_Integration_Order_Gate]] and [[E_01_I2_Trap]].
2. **Instability is affirmatively demonstrated** — Hansen $L_c$/SupF and/or the CUSUM family reject
   stability, with bootstrapped p-values.
3. **Break dates are corroborated across independent procedures** — Hansen SupF argmax, CUSUM supF
   argmax, Bai-Perron, and Gregory-Hansen break estimates are reported *together*. Convergence
   strengthens the reading; divergence must be reported as divergence, not silently resolved to
   whichever date suits the narrative.
4. **The constructive question is answered** — regime-split re-estimation and/or Gregory-Hansen
   determine whether a long-run relation is recoverable *within* regimes. If it is not, the honest
   verdict is that no stable long-run relation has been identified, and the write-up must say so.

**Prohibited**: describing a cointegration failure as "evidence of regime change" when only (2) has
been shown. Instability establishes that the parameters move; it does not by itself establish that a
regime-specific equilibrium exists.

### 4.1 Verdict ledger

Every stability audit concludes with the consolidated verdict table mandated by the skill's
Cointegration Specification Audit Protocol §4 (columns: Candidate/Model | Theoretical Basis |
Evidence | Status | Governing Lock), with `Status` drawn from:

| Status | Meaning in this protocol |
|---|---|
| **Promoted** | Parameters stable *and* cointegration recovered under regime shift |
| **Held** | Parameters unstable, but cointegration recoverable once the cointegrating vector may break |
| **Blocked** | Parameters unstable *and* no cointegration even allowing a regime shift |
| **Rejected** | No instability detected, yet no cointegration under any regime-shift specification |

---

## 5. Small-Sample Discipline for Regime Splits

Regime-split re-estimation produces sub-samples materially shorter than the full window. Per Rule I:

- Sub-samples with $N \le 30$ require bootstrap p-values alongside any asymptotic verdict.
- Sub-samples below ~25 observations are flagged `underpowered` in the output and **must** carry an
  explicit reliability caveat in the write-up rather than a bare verdict.
- Step dummies that are constant within a sub-sample are dropped before re-estimation (they are
  collinear with the intercept); the write-up must note that the sub-sample specification therefore
  differs from the full-sample one.

---

## 6. Residual Unit-Root Tests Must Be Lag-Augmented (binding)

**Directive**: any Engle-Granger-style residual unit-root test in this repository **must** select a
lag order by an information criterion (AIC or BIC, max 8) and report the selected order alongside the
statistic. A plain Dickey-Fuller (zero lagged differences) is **prohibited** wherever the residuals
are serially correlated, which in practice means always.

**Rationale**: `US_S50_section31_imols_estimation.R` originally computed

```r
eg_lm <- lm(diff(u) ~ u[-T_obs] - 1)   # zero lagged differences
```

and compared the result to MacKinnon critical values, which are tabulated for the **augmented**
test. The Section 3.1 IM-OLS residuals carry AR(2)–AR(4) structure with first-order autocorrelation
0.81–0.96. Whitening is precisely what the "A" in ADF is for; without it the test is severely biased
toward non-rejection.

**Magnitude of the defect** (2026-08-03, all 18 Section 3.1 models):

| Lag order | Models rejecting $H_0$: no cointegration (5%) |
|---|---|
| $p=0$ (as shipped in v2) | **2 / 18** |
| $p=1$ | 14 / 18 |
| $p=2$ | 9 / 18 |
| $p=3$ | 9 / 18 |
| $p=4$ | 5 / 18 |
| **AIC-selected** | **16 / 18** |
| **BIC-selected** | **16 / 18** |

At the 10% level the AIC-selected test rejects in **18/18**. AIC and BIC select the same order in 17
of 18 models, and even minimal $p=1$ augmentation flips the verdict, so the reversal is not a
lag-selection artifact. The decay at $p\ge4$ is the expected power loss from over-augmentation at
$T=94$.

**Consequence**: the v2 report's headline "no cointegration" finding was an artifact of test
mis-specification, not a property of the data. Any prior interpretation resting on it — including
narrative readings of cointegration failure as structural regime-switching — must be revisited.

**Known remaining instances of this defect** (not corrected as of 2026-08-03, flagged for follow-up):
`sbvecm_adf_stat()` / `gh_design()` in `codes/CL_S20_structural_break_dual_route_audit.R` and its
consumers across the Chile S20/S30/S90/S95/S99 chain. Use `adf_t_augmented()` from
`codes/COMMON_cointegration_stability_tests.R` instead.

### 6.1 Caveat on critical values with endogenous dummies

The Section 3.1 residuals come from a regression that also contains Bai-Perron step dummies selected
from a first-pass break audit. Standard Engle-Granger critical values do not account for
endogenously-selected break dummies and are therefore somewhat **liberal** in this setting. The
Gregory-Hansen test (which treats the break as endogenous by construction) is the appropriate
break-robust cross-check and must be reported alongside.

---

## 7. Vault Cross-References

- Critical values and star conventions: [[E17_Cointegration_Significance_Stars_Lock]]
- VW Type 2 / cointegration triad: [[E15_Vogelsang_Wagner_IMOLS_Cointegration_Test_Lock]]
- Active estimator and LRV/bandwidth doctrine: [[E10V_IMOLS_CPR_Active_Estimator_Lock]]
- Integration order gate: [[Interaction_Term_Integration_Order_Gate]], [[E_01_I2_Trap]]
- Originating audit: `chapter2_vault/08_audits/2026-08-03_section31_cointegration_stars_audit.md`
