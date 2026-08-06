---
type: paper_facing
status: draft
depends_on:
  - chapter2_vault/03_econometrics/E18_Parameter_Stability_Audit_Protocol_Lock.md
stage_scope: paper-facing
country: US_CL
last_updated: 2026-08-05
updated_by: CH2_PAPER_FACING_SOURCE_SCOPING
layer: appendix
role: stability-audit
stage: post-estimation-diagnostics
tags:
  - chapter2/appendix
  - chapter2/stability
  - chapter2/cointegration
scope: chapter2
priority: core
---

# Appendix E: Parameter Stability

A cointegration test that fails should be diagnosed, not merely reported. This appendix sets out how instability is tested for in this chapter and what constraints govern reading a failure as evidence of regime change rather than as evidence of no long-run relation.

## E.1 What the Shin statistic already tells us

Shin's $C$ statistic is Hansen's $L_c$ restricted to intercept-only parameter variation, with $L_c^{\text{intercept}} = T \cdot C_{\text{Shin}}$. This identity holds to machine precision across the Specification A models.

The consequence is interpretive and it matters. A Shin rejection is already evidence of parameter instability; it is not evidence of "no cointegration" in some undifferentiated sense. A report that observes a Shin rejection and stops there has not said what it appears to have said. It must either decompose the rejection with the full Hansen $L_c$, per parameter and jointly, or state plainly that the decomposition was not performed.

One numerical caveat travels with this identity wherever both statistics appear: $L_c$ and $C_{\text{Shin}}$ will not agree numerically, because they use different long-run variance estimators — a score-process Bartlett estimator against the conditional $\omega_{u \cdot v}$ from the cointegrating regression. On this data they differ by roughly an order of magnitude. The discrepancy is expected and is not a sign that either is wrong.

## E.2 Bootstrapped nulls, and why the direction of the null matters

Test statistics introduced into this chapter take their inference from a bootstrapped null distribution rather than from hardcoded critical values, unless a properly indexed published table has been digitized in full.

The construction of that null is where the single most dangerous error in this protocol lives. Tests whose null is cointegration with stable parameters — Hansen $L_c$, MeanF, SupF, and the CUSUM family — require resampling stationary residuals under a moving-block scheme. Tests whose null is no cointegration — Gregory-Hansen — require cumulating resampled differences into a random walk. Transposing the two data-generating processes silently inverts every $p$-value while producing output that looks entirely plausible. Block length follows the fitted long-run-variance bandwidth; i.i.d. resampling is not admissible, since it destroys exactly the serial dependence the block scheme exists to preserve.

## E.3 Which specification the stability tests run on

Endogenously selected step dummies are excluded from the stability tests. The CUSUM family and Gregory-Hansen run on the core specification — intercept plus stochastic regressors — because a dummy selected from the same data whose stability is being tested contaminates the test. Hansen $L_c$ is reported both on the full fitted design and restricted to core parameters, and any table reporting it states which.

The distinction between level shifts and vector shifts governs what may be claimed. Step dummies absorb level shifts only. They cannot absorb a shift in the cointegrating vector itself. A specification that answers detected breaks with step dummies has therefore not addressed slope instability, and is not described as break-robust anywhere in this chapter on that basis.

## E.4 When a failure may be read as regime change

Reading a cointegration failure as evidence of structural regime-switching is permitted only when four conditions hold jointly.

Admissibility must not be the explanation: the integration-order gate passes for every regressor as actually constructed, lag structure included. Instability must be affirmatively demonstrated with bootstrapped $p$-values, not inferred from the failure itself. Break dates must be corroborated across the Hansen SupF argmax, the CUSUM supF argmax, Bai-Perron, and Gregory-Hansen — where these converge the reading is strengthened, and where they diverge the divergence is reported as divergence rather than resolved to whichever date suits the argument. And the constructive question must be answered: does a long-run relation appear once the cointegrating vector is allowed to break, by regime-split re-estimation or by Gregory-Hansen? If it does not, the honest verdict is that no stable long-run relation has been identified, and the text says so.

Describing a cointegration failure as evidence of regime change on the strength of demonstrated instability alone, without the other three conditions, is not available.

## E.5 Small samples

Where a sub-sample falls to 30 observations or fewer, bootstrap $p$-values are reported alongside asymptotics. Below roughly 25 observations the estimate is flagged as underpowered and carries an explicit reliability caveat rather than a bare verdict. Step dummies that are constant within a sub-sample are dropped, and where this happens the text notes that the sub-sample specification therefore differs from the full-sample one.

\PLACEHOLDER{Stability results are not yet reported here. Required: Hansen $L_c$ (full design and core-restricted), MeanF, SupF, CUSUM, and Gregory-Hansen for each preferred specification, each with bootstrapped $p$-values under the correctly oriented null; the break-date corroboration table across the four detection methods; and the consolidated verdict summary. Source material is in the archived \texttt{reports/US\_Section31\_Stability\_Audit/99\_archive/}.}

\PLACEHOLDER{One known defect to resolve before those results are reported: the residual ADF implementation used in the Chilean structural-break chain is not lag-augmented, and an unaugmented Dickey-Fuller regression on serially correlated residuals under-rejects severely. On the Specification A models the difference is decisive --- 2 of 18 rejections at the 5\% level with zero lagged differences against 16 of 18 under an information-criterion-selected lag order. Any prior reading of cointegration failure as regime-switching that rests on the unaugmented statistic must be revisited before it is repeated here.}
