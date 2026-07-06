---
type: "note"
status: "active"
estimator_status: restricted-dols-required-for-nonlinear-baseline
layer: "method"
design_role: "parameter_stability_window_rule"
scope: "chapter2_core_support"
related_to:
  - "M10_Empirical_Identification_Framework"
  - "N02_SuperConsistency"
  - "R03_super_consistency_mechanics_hinge"
  - "R04_FMOLS_structural_preservation"
  - "R05_LRV_kernel_bandwidth_regime_misalignment"
  - "R06_IMOLS_integration_ladder_reconstruction"
  - "R08_threshold_break_diagnostics_to_FGLS"
  - "L00_Econometrics_References"
priority: "high"
estimators:
  - "FM-OLS"
  - "IM-OLS"
  - "DOLS"
empirical_inputs:
  - "y_t"
  - "k_t"
  - "omega_t"
  - "omega_k_t"
  - "s_t_proxy"
  - "phi_t_proxy"
  - "s_t_proxy_cc"
  - "phi_t_proxy_cc"
  - "pK_relative_ME_NRC"
method_classification_core:
  - "Hansen-type parameter instability tests for I(1) regressions"
method_classification_supporting:
  - "Gregory-Hansen one-break cointegration tests"
  - "Andrews unknown-break logic"
method_classification_diagnostic:
  - "rolling-window estimates"
  - "recursive estimates"
  - "Johansen recursive constancy diagnostics"
method_classification_too_heavy_for_main_paper:
  - "Bai-Perron multiple-break methods"
  - "Kejriwal-Perron multiple breaks in cointegrated regressions"
method_classification_not_appropriate:
  - "ordinary OLS break tests as primary evidence for I(1) cointegrating regressions"
created: "2026-05-13"
updated: "2026-05-14"
role: superseded-for-baseline
stage: pre-estimation-design
aliases:
  - Structural break protocol
tags:
  - chapter2/econometrics
  - chapter2/superseded
  - chapter2/fmols
  - chapter2/imols
  - chapter2/qomega-parked
updated_by: D12V2_OBSIDIAN_ECONOMETRICS_VAULT_ORGANIZATION
---

# Parameter Stability and Window Discipline in S30

> [!warning] q_omega parked
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path. See [[D12V_Restricted_DOLS_Active_Estimator_Lock]].


> [!gate] D12V2 gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.


> [!warning] D12V2 status
> This note is not baseline authorization.
> FM-OLS and IM-OLS are blocked for nonlinear/interacted/generated Chapter 2 baseline specifications.
> Use [[D12V_Restricted_DOLS_Active_Estimator_Lock]], [[FMOLS_IMOLS_Failure_For_Interaction_Objects]], and [[Estimator_Status_Ledger_D12V]] before citing this note for estimation design.


> [!warning] D12V status update — FM-OLS
> Standard FM-OLS is superseded as the active baseline estimator for nonlinear/interacted/generated Chapter 2 specifications.
> It remains available only as historical reference, diagnostic comparator, or possible estimator for strictly linear cointegration objects if the model object is explicitly classified as standard linear cointegration.
> Do not use this note as baseline authorization without passing through [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Interaction_Term_Integration_Order_Gate]].

> [!warning] D12V status update — IM-OLS
> Standard IM-OLS is not baseline-authorized for nonlinear/interacted/generated Chapter 2 specifications.
> A restricted IM-OLS analogue is blocked as a substitute for Restricted DOLS because cumulative sums of base variables do not resolve interaction-term endogeneity in the required way.
> Use [[FMOLS_IMOLS_Failure_For_Interaction_Objects]] and [[Estimator_Status_Ledger_D12V]] before citing this note for estimation design.

> [!important] D12V status update — DOLS
> The active Chapter 2 baseline-design candidate is Restricted DOLS, not generic DOLS.
> Restricted DOLS keeps nonlinear/interacted terms in the long-run level equation but restricts the dynamic correction set to admissible base-variable differences.
> Unrestricted DOLS is blocked for interaction objects unless a separate protocol authorizes leads/lags of interaction-term differences.
> See [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]].

> [!gate] D12V interaction-term gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.
> Restricted DOLS is preferred only after base-variable integration status, interaction-term status, and sample-window adequacy are classified.

> [!warning] q_omega remains parked
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path. See [[D12V_Restricted_DOLS_Active_Estimator_Lock]].

> [!important] Current identification lock
> Break diagnostics apply after the primitive centered-interaction first layer is specified. Accumulated-index and old `omega_k_t` labels below are historical implementation references.

## Core claim

S30 should treat parameter stability as a guardrail on the long-run transformation relation, not as an invitation to search for the window with the most attractive coefficient.

The admissible protocol is:

$$
\text{pre-declared historical windows}
\rightarrow
\text{same cointegrating specification across windows}
\rightarrow
\text{estimator triangulation}
\rightarrow
\text{formal or proxy stability check}
\rightarrow
\text{diagnostic rolling/recursive inspection}.
$$

The window is never promoted because it produces the desired sign, magnitude, or significance. It is promoted only if it survives the hierarchical estimator check, neighborhood check, collinearity check, and stability-evidence check.

---

## 1. Problem definition

The S30 object is a single-equation long-run transformation relation between output, capital, distribution, and capital composition. The baseline empirical variables are:

$$
\{y_t, k_t, \omega_t, \omega^K_t, s_t^{proxy}, \phi_t^{proxy}, s_{t,cc}^{proxy}, \phi_{t,cc}^{proxy}, pK^{ME/NRC}_t\}.
$$

The composition variables are Tier-B ME--NRC component proxies for an NFCorp-centered transformation relation. They are not direct NFCorp-by-asset-type capital-stock splits. That matters because instability in their coefficients may reflect three different objects:

1. instability in the long-run transformation relation;
2. fragility from proxy construction and composition measurement;
3. local collinearity or window sensitivity in a small annual macro sample.

S30 therefore needs a protocol that distinguishes parameter instability from proxy fragility. It also needs to avoid two symmetric errors: choosing windows arbitrarily from coefficient appeal, and overreacting by turning the chapter into a specialized structural-break econometrics paper.

---

## 2. Literature map and method classification

| Method family | S30 classification | Function in S30 | Boundary rule |
|---|---:|---|---|
| FM-OLS | CORE estimator | Main estimator for the long-run transformation relation because it preserves the theoretical regressor matrix while correcting endogeneity and serial correlation. | It estimates the long-run coefficient vector; it does not identify regimes by itself. |
| IM-OLS | CORE robustness estimator | Robustness check against DOLS-style lead-lag augmentation and FM-OLS kernel/bandwidth dependence. | It is not a separate stability-testing literature; stability belongs to the cointegrating model, not to the IM-OLS label. |
| DOLS | DIAGNOSTIC / stress estimator | Fragility check using dynamic augmentation. | DOLS leads/lags reduce effective sample size and may be unstable in short annual windows. |
| Hansen-type instability tests | CORE stability check | Formal benchmark for parameter instability in regressions with $I(1)$ processes. | Preferred stability evidence when implementable. |
| Gregory--Hansen tests | SUPPORTING | Tests whether cointegration is recovered once one unknown regime shift is allowed. | Use only when the question becomes one-break cointegration, not as the default stability protocol. |
| Andrews unknown-break tests | SUPPORTING | Provides the general unknown-break logic behind sup-type tests. | Background logic, not a license to apply stationary OLS break tests as main evidence. |
| Rolling and recursive estimates | DIAGNOSTIC | Graphical and local-sensitivity evidence. | They are thermometers, not birth certificates for regimes. |
| Johansen recursive diagnostics | DIAGNOSTIC / secondary comparison | System-level comparison if the single-equation reading needs cross-checking. | Do not let CVAR diagnostics displace the S30 single-equation design. |
| Bai--Perron | TOO HEAVY FOR MAIN PAPER | Multiple-break dating in linear models. | Appendix only unless multiple-break dating becomes the substantive question. |
| Kejriwal--Perron | TOO HEAVY FOR MAIN PAPER | Multiple structural changes in cointegrated regressions. | Methodologically appropriate but excessive for the main chapter unless multiple breaks become central. |
| Ordinary OLS break tests | NOT APPROPRIATE | At most a secondary descriptive sensitivity check. | Do not use as primary evidence for instability in $I(1)$ cointegrating regressions. |

---

## 3. Role of Hansen-type parameter-instability tests

Hansen-type tests are the natural benchmark because they address parameter instability in regressions involving $I(1)$ processes. That is the correct problem class for S30.

The target is not whether a stationary OLS regression has a break. The target is whether the cointegrating vector that supports the long-run transformation relation can be treated as reasonably stable over the relevant sample or window.

The preferred rule is:

> Apply a Hansen-type parameter-instability test, or the closest implementable equivalent, to the main FM-OLS specification and report the result as the formal stability screen.

If the exact Hansen procedure is not available in the implementation stack, the replacement must be labeled carefully. Empirical fluctuation or recursive-constancy tests can be used as operational proxies, but the note and paper should not present them as exact equivalents to Hansen's original statistics.

This distinction protects the chapter from a common mistake: using whatever software can run as if it were the test required by the design. Useful, yes. Equivalent, no. Econometrics is not a costume party. ⚙️

---

## 4. Role of Gregory--Hansen tests

Gregory--Hansen tests belong to a more specific question:

> Does the relation become cointegrated once the model allows one unknown regime shift?

That is not the same as the general S30 question of whether the estimated long-run coefficient vector is stable across historically meaningful windows.

Use Gregory--Hansen only under clear triggers:

1. full-sample cointegration evidence is weak or contradictory;
2. visual and historical diagnostics point toward one plausible unknown regime shift;
3. the chapter needs to test whether the relation is better described as one-break cointegration rather than stable full-sample cointegration.

Gregory--Hansen should not replace the historical-window protocol. It is a conditional module for one-break cointegration, not a general method for selecting the best historical period.

---

## 5. Role of Bai--Perron and Kejriwal--Perron

Bai--Perron and Kejriwal--Perron are powerful but heavy.

Bai--Perron is the benchmark for estimating and testing multiple structural changes in linear models. Kejriwal--Perron adapts the multiple-break problem to cointegrated regressions. The second is closer to S30's model class; the first is useful as general break-econometrics background.

For Chapter 2, their role should be limited:

- use them only as optional appendix material;
- activate them only if evidence strongly suggests multiple breaks;
- do not let them become the main selection device for S30 windows;
- do not allow break-date estimation to replace historically motivated periodization.

The reason is practical and substantive. In annual macroeconomic data, each additional break partitions an already small sample. Multiple-break estimation can become more about segment scarcity than about the transformation relation. Unless multiple-break dating is central to the argument, this is too much machine for the job.

---

## 6. Rolling and recursive estimates

Rolling-window and recursive estimates are diagnostic evidence.

They are useful for:

1. identifying local sensitivity;
2. checking whether coefficient paths drift around historical boundaries;
3. detecting windows where composition proxies become unstable;
4. showing whether FM-OLS, IM-OLS, and DOLS tell similar local stories;
5. flagging collinearity episodes before coefficient interpretation.

They are not formal regime identifiers.

The admissible language is:

> Rolling and recursive estimates are interpreted as diagnostic evidence on local coefficient sensitivity. They do not mechanically identify regimes, and they are not used to select windows ex post.

The inadmissible language is:

> The rolling coefficient changes here, therefore the regime begins here.

That sentence should not survive an audit.

---

## 7. Historical windows and estimated breakpoints

Historical windows and statistical breakpoints are different objects.

Historical windows are substantive contrasts. They are pre-declared from political-economic periodization, institutional change, and the history of accumulation. They enter S30 as benchmark comparisons.

Estimated breakpoints are model-conditional dates produced by a test. They are useful evidence, but they are not sovereign historical periodization.

The rule is:

> Historical windows define the benchmark contrasts. Statistical breakpoints test whether the data provide independent support for instability near, inside, or outside those contrasts.

If a statistically estimated breakpoint aligns with a historical boundary, the result strengthens the interpretation. If it does not align, the divergence should be reported rather than erased. The chapter should not force the statistical breakpoint to become the historical narrative, and it should not force historical periodization to impersonate statistical proof.

---

## 8. Sample-size constraints

Annual macroeconomic cointegration models are sample-hungry. S30 must report effective sample size, not only calendar span.

For each specification and window, record:

1. calendar years;
2. raw number of observations;
3. effective number of observations after missing values;
4. effective number of observations after DOLS leads/lags;
5. number of long-run regressors and interaction terms;
6. number of nuisance terms;
7. whether composition proxies are highly collinear in that window;
8. whether FM-OLS kernel/bandwidth choices materially affect results.

Small-window results should be treated as exploratory unless they retain enough observations to estimate the long-run relation without turning each coefficient into a heroic autobiography.

Operational rule:

> No window is admissible merely because it is historically interesting. It must also be econometrically estimable after accounting for regressors, interactions, missing values, and DOLS dynamic augmentation.

---

## 9. Recommended S30 protocol

The main S30 protocol should be austere and sequential.

1. Declare the baseline transformation relation before window comparison.
2. Declare the historical windows before inspecting coefficient appeal.
3. Estimate the same specification in the full sample and in each historical window.
4. Use FM-OLS as the main estimator.
5. Use IM-OLS as the robustness estimator.
6. Use DOLS as the fragility and stress diagnostic.
7. Record effective sample size and regressor count for every window-estimator pair.
8. Apply Hansen-type stability tests, or the closest implementable equivalent, to the main FM-OLS specification as preferred formal stability evidence.
9. Use rolling and recursive estimates as diagnostic plots only.
10. Run Gregory--Hansen only if the question becomes one unknown regime shift in the cointegrating relation.
11. Reserve Bai--Perron/Kejriwal--Perron for optional appendix material if multiple breaks become substantively unavoidable.
12. Promote a specification or window only if it survives the hierarchical estimator check, neighborhood check, collinearity check, and stability-evidence check.

---

## 10. Promotion rule

A window or specification can be promoted only if the relevant checks are passed. These checks are not symmetric.

### Estimator hierarchy and veto discipline

The estimator hierarchy is asymmetric.

FM-OLS is the main estimator for the long-run transformation relation because it preserves the theoretical regressor matrix.

IM-OLS is the robustness estimator. It may overturn the interpretation if it substantively contradicts FM-OLS.

DOLS is the fragility and stress diagnostic. It may not independently veto admissibility.

Operational rule:

- FM-OLS carries the primary interpretation.
- IM-OLS checks whether the long-run coefficient pattern survives an estimator that avoids both DOLS-style lead-lag augmentation and FM-OLS kernel/bandwidth tuning.
- DOLS records fragility from dynamic augmentation, effective-sample loss, and lead-lag sensitivity.
- DOLS contradiction should be reported as fragility evidence, not as automatic evidence that the long-run transformation relation itself fails.

This rule is especially important for generated-index specifications such as:

$$
y_t^p
=
\alpha
+
\theta_0 k_t
+
\theta_\omega q_t^{\omega,h}
+
u_t.
$$

In such cases, DOLS lead-lag expansion may generate auxiliary differenced terms without structural interpretation for productive-capacity reconstruction. Those terms can stress the coefficient recovery problem, but they do not become part of the transformation relation.

Therefore, DOLS may generate:

- fragility flags;
- sample-size warnings;
- lead-lag contamination warnings;
- interaction-augmentation warnings;
- specification notes.

DOLS may not generate:

- a hard veto over FM-OLS when IM-OLS does not overturn the FM-OLS interpretation;
- an alternative reconstruction equation;
- a regime boundary;
- a substitute specification.

### Neighborhood check

Results should not collapse under small changes around the historical window boundary.

### Collinearity check

The composition proxies must not be so collinear that the coefficient is essentially a rotation of the regressor matrix.

### Stability-evidence check

Formal or proxy stability evidence must not contradict the claimed interpretation.

Hansen-type evidence is the preferred formal stability diagnostic when implementable. If exact Hansen-type testing is unavailable, the replacement must be labeled as an operational proxy.

Stability evidence should be classified as evidence about the admissibility of the cointegrating relation, not as a direct estimator of productive capacity.

### Promotion interpretation

If one check fails, the result may still be reported. It should not be promoted as the benchmark S30 finding.

If DOLS alone contradicts FM-OLS while IM-OLS remains non-contradictory, the admissible interpretation is:

> the candidate remains possible only under a fragility flag.

It is not:

> the candidate is rejected because DOLS vetoed it.

---

## 11. What not to do

Do not select the window because the coefficient becomes attractive.

Do not treat rolling-window estimates as proof of regimes.

Do not use ordinary OLS break tests as primary evidence for an $I(1)$ cointegrating regression.

Do not collapse historical periodization and statistically estimated breakpoints.

Do not treat Gregory--Hansen as a general substitute for parameter-stability testing.

Do not put Bai--Perron/Kejriwal--Perron in the main paper unless multiple-break dating becomes central to the argument.

Do not interpret instability in Tier-B ME--NRC proxies as immediate evidence that the theoretical transformation relation itself broke. Proxy fragility must be separated from structural instability.

Do not allow DOLS to operate as a co-equal veto over FM-OLS and IM-OLS. DOLS is a fragility diagnostic because its lead-lag augmentation alters the regressor matrix and may introduce nuisance dynamics that do not belong to the productive-capacity reconstruction path.

---

## 12. Locked sentence for reuse

**S30 treats historical windows as pre-declared benchmark contrasts and parameter-stability evidence as a disciplinary screen. FM-OLS carries the main reconstruction interpretation, IM-OLS checks robustness, and DOLS records fragility from dynamic augmentation rather than vetoing admissibility by itself. Rolling and recursive estimates diagnose sensitivity; they do not identify regimes. Gregory--Hansen is reserved for the one-break cointegration question, while Bai--Perron/Kejriwal--Perron remain appendix-level tools unless multiple-break dating becomes central to the chapter.**

---

## References

Andrews, D. W. K. (1993). Tests for parameter instability and structural change with unknown change point. *Econometrica, 61*(4), 821--856.

Bai, J., & Perron, P. (1998). Estimating and testing linear models with multiple structural changes. *Econometrica, 66*(1), 47--78.

Bai, J., & Perron, P. (2003). Computation and analysis of multiple structural change models. *Journal of Applied Econometrics, 18*(1), 1--22.

Engle, R. F., & Granger, C. W. J. (1987). Co-integration and error correction: Representation, estimation, and testing. *Econometrica, 55*(2), 251--276.

Gregory, A. W., & Hansen, B. E. (1996a). Residual-based tests for cointegration in models with regime shifts. *Journal of Econometrics, 70*(1), 99--126.

Gregory, A. W., & Hansen, B. E. (1996b). Tests for cointegration in models with regime and trend shifts. *Oxford Bulletin of Economics and Statistics, 58*(3), 555--560.

Gregory, A. W., Nason, J. M., & Watt, D. G. (1996). Testing for structural breaks in cointegrated relationships. *Journal of Econometrics, 71*(1--2), 321--341.

Hansen, B. E. (1992). Tests for parameter instability in regressions with I(1) processes. *Journal of Business & Economic Statistics, 10*(3), 321--335.

Hansen, H., & Johansen, S. (1999). Some tests for parameter constancy in cointegrated VAR-models. *The Econometrics Journal, 2*(2), 306--333.

Johansen, S. (1991). Estimation and hypothesis testing of cointegration vectors in Gaussian vector autoregressive models. *Econometrica, 59*(6), 1551--1580.

Kejriwal, M., & Perron, P. (2010). Testing for multiple structural changes in cointegrated regression models. *Journal of Business & Economic Statistics, 28*(4), 503--522.

Phillips, P. C. B. (1995). Fully modified least squares and vector autoregression. *Econometrica, 63*(5), 1023--1078.

Phillips, P. C. B., & Hansen, B. E. (1990). Statistical inference in instrumental variables regression with I(1) processes. *The Review of Economic Studies, 57*(1), 99--125.

Saikkonen, P. (1991). Asymptotically efficient estimation of cointegration regressions. *Econometric Theory, 7*(1), 1--21.

Stock, J. H., & Watson, M. W. (1993). A simple estimator of cointegrating vectors in higher order integrated systems. *Econometrica, 61*(4), 783--820.

Vogelsang, T. J., & Wagner, M. (2014). Integrated modified OLS estimation and fixed-b inference for cointegrating regressions. *Journal of Econometrics, 178*(2), 741--760.
