---
type: note
status: superseded-for-baseline
layer: method
design_role: robustness_estimator_rule
scope: chapter2_core_support
estimator_status: historical-or-diagnostic
requires_review_before_use: true
updated_by: D12V_ECONOMETRICS_VAULT_ESTIMATOR_PIVOT
related_to:
  - R03_super_consistency_mechanics_hinge
  - R04_FMOLS_structural_preservation
  - R05_LRV_kernel_bandwidth_regime_misalignment
  - N02_SuperConsistency
  - M10_Empirical_Identification_Framework
  - L00_Econometrics_References
priority: high
---

# IM-OLS and the Integration-Ladder Reconstruction Problem

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
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path.

> [!important] Current identification lock
> IM-OLS is a robustness check for the primitive centered-interaction first layer. Accumulated-index construction discussed below is parked historical-memory work, not the current baseline.

## Core claim

IM-OLS is admissible as a robustness estimator for the long-run transformation relation, but not as a direct reconstruction device for capacity utilization.

Its advantage is that it avoids DOLS-style lead-lag clutter and FM-OLS-style kernel/bandwidth tuning in the estimation step. Its cost is that estimation occurs in integrated partial-sum space, while productive capacity and utilization must be reconstructed in log-level space.

---

## 1. What IM-OLS does

IM-OLS transforms the cointegrating regression through partial sums. Instead of estimating only in the original $I(1)$ level space, it works with accumulated variables.

The logic is asymptotic dominance: the transformed signal grows faster than the transformed noise, so second-order bias terms are dominated in the limit.

This produces a super-consistent long-run coefficient without expanding the regression with DOLS leads/lags or estimating FM-OLS-style kernel corrections during the coefficient-recovery step.

---

## 2. Why IM-OLS is attractive

For Chapter 2, IM-OLS is attractive because it offers a clean robustness check.

It avoids:

- DOLS parametric augmentation,
- DOLS lead-lag selection,
- FM-OLS kernel choice,
- FM-OLS bandwidth choice.

So IM-OLS can test whether the long-run coefficient is robust to an estimator that uses neither short-run dynamic clutter nor non-parametric covariance tuning in the estimation equation.

---

## 3. The integration-ladder problem

The cost is structural.

IM-OLS estimates the long-run coefficient in integrated or partial-sum space. But the dissertation’s reconstructed object lives in log-level space:

$$
\hat{\theta}
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

Therefore, IM-OLS cannot be moved directly into utilization reconstruction without an explicit trace-back step.

The estimator may recover the long-run coefficient, but the reconstructed productive-capacity path must still be returned to the level-space object required by:

$$
\mu_t = \frac{Y_t}{Y_t^p}.
$$

---

## 4. Generated-index sequence rule

If the specification contains an accumulated distribution-conditioned index, the order of operations matters.

The inherited memory state must weight capital growth before accumulation.

The theoretical object is:

$$
z_t
=
m_{t-1}^{(h)}\Delta k_t,
$$

then the correct sequence is:

$$
z_t
=
m_{t-1}^{(h)}\Delta k_t
\rightarrow
q_t^{\omega,h}
=
\sum_{j=1}^{t} z_j.
$$

The incorrect sequence is:

$$
\left(\sum_{j=1}^{t}\omega_j\right)
\times
\left(\sum_{j=1}^{t}\Delta k_j\right).
$$

That would create a different mathematical object and break the connection with the theoretical transformation relation.

---

## 5. Trace-back protocol

If IM-OLS is used to support reconstruction, the fitted integrated object must be traced back into level space.

The protocol is:

1. estimate the long-run relation in integrated space;
2. recover the long-run coefficient vector;
3. construct the fitted integrated productive-capacity path;
4. difference the fitted integrated path to return to log-level space;
5. apply the explicit level anchor or pinch-year normalization;
6. derive utilization from observed output relative to reconstructed productive capacity.

So the usable sequence is:

$$
\text{IM-OLS coefficient recovery}
\rightarrow
\text{trace-back to } \hat{Y}_t^p
\rightarrow
\text{level anchoring}
\rightarrow
\hat{\mu}_t.
$$

---

## 6. Regime limitation

IM-OLS remains a global cointegration estimator.

If the economy crosses historically distinct regimes, the partial-sum transformation accumulates those shifts into the transformed series. A global IM-OLS regression may therefore fit a single integrated trend across a relation whose slope or intercept changes across regimes.

This makes IM-OLS useful for robustness, but not sufficient for regime-dependent identification.

The regime layer must be modeled separately.

---

## 7. Methodological lock

IM-OLS should be assigned the following role:

- not the main reconstruction estimator;
- not a direct utilization estimator;
- not a threshold-regime estimator;
- yes, a robustness check for the long-run coefficient.

Its value is highest when the question is:

> Does the long-run transformation coefficient survive an estimator that avoids both DOLS-style lead-lag clutter and FM-OLS-style kernel/bandwidth tuning?

---

## 8. Locked sentence for reuse

**IM-OLS is a strong robustness estimator for the long-run transformation coefficient, but its partial-sum architecture creates an integration-ladder problem: the estimate must be traced back into log-level productive-capacity space before utilization can be derived.**

---

## References

Vogelsang, T. J., & Wagner, M. (2014). Integrated modified OLS estimation and fixed-b inference for cointegrating regressions. *Journal of Econometrics, 178*(2), 741–760. https://doi.org/10.1016/j.jeconom.2013.10.015

Vogelsang, T. J., & Wagner, M. (2024). *Integrated modified OLS estimation and fixed-b inference for cointegrating multivariate polynomial regressions* (IHS Working Paper No. 53). Institute for Advanced Studies.
