---
type: note
status: active
layer: method
design_role: estimator_warning_rule
scope: chapter2_core_support
related_to:
  - A00_Aggregate_Transformation_Benchmark
  - R03_super_consistency_mechanics_hinge
  - R04_FMOLS_structural_preservation
  - R06_IMOLS_integration_ladder_reconstruction
  - N02_SuperConsistency
  - M10_Empirical_Identification_Framework
  - L00_Econometrics_References
priority: high
---

# Long-Run Variance Estimation and Regime Misalignment

## Core claim

FM-OLS preserves the theoretical regressor matrix, but its correction depends on long-run variance estimation. That creates a regime-misalignment risk.

The estimator does not add DOLS-style lead-lag clutter to the regression. Instead, it corrects endogeneity and serial correlation through estimates of the long-run covariance structure. This is structurally cleaner for productive-capacity reconstruction, but it is not historically neutral.

If the covariance structure changes across regimes, a global long-run variance correction can smooth across the very boundaries the research design needs to keep visible.

---

## 1. What long-run variance estimation does

FM-OLS requires estimates of the long-run covariance matrix of the innovation process.

This matrix summarizes persistence, serial correlation, and endogeneity-relevant covariance at frequency zero.

In practice, it is estimated using a kernel and bandwidth rule.

The generic object is:

$$
\hat{\Omega}
=
\sum_{j=-M}^{M}
K\left(\frac{j}{M}\right)\hat{\Gamma}(j),
$$

where:

- $\hat{\Gamma}(j)$ is the sample autocovariance at lag $j$,
- $K(\cdot)$ is the kernel weight,
- $M$ is the bandwidth.

---

## 2. Kernel choice

The kernel determines how lagged autocovariances are weighted.

Common choices include:

- Bartlett kernel: linear decay in lag weights;
- Quadratic Spectral kernel: smooth decay and strong asymptotic efficiency properties.

These choices are not part of the theory of productive capacity. They belong to the estimator’s covariance-correction layer.

---

## 3. Bandwidth choice

The bandwidth determines the memory span of the correction.

A small bandwidth uses a short memory window.  
A large bandwidth uses a longer memory window.

This matters because macroeconomic time series often exhibit persistence. Larger bandwidths can help capture long-memory covariance structure, but they also increase the risk of averaging across structurally different periods.

The bandwidth therefore introduces a temporal smoothing device into the estimator.

---

## 4. The regime-misalignment problem

If the data-generating process is globally stable, kernel-based LRV estimation can support valid coefficient recovery.

But if the sample contains structural breaks or historically distinct regimes, the same procedure becomes vulnerable.

Near a regime boundary, the kernel window can incorporate observations from both sides of the break. The resulting covariance correction is then an average of two different regimes.

This creates the smearing effect:

$$
\text{regime A covariance}
+
\text{regime B covariance}
\rightarrow
\text{hybrid correction}.
$$

That hybrid correction may be statistically convenient, but it is historically misaligned.

---

## 5. Implication for FM-OLS

FM-OLS remains the preferred main estimator for the long-run reconstruction layer because it preserves the A00 structural regressor matrix and works in log-level space.

However, its LRV correction is global unless the design explicitly modifies it.

Here "global" does not mean constant $\theta$. It means global estimation of the corrected A00 accumulated-index mapping:

$$
y_t^p
=
\alpha
+
\theta_0 k_t
+
\theta_\omega q_t^{\omega,h}
+
u_t,
$$

with:

$$
\theta_t
=
\theta_0
+
\theta_\omega m_{t-1}^{(h)}.
$$

So FM-OLS can support:

$$
\text{A00 accumulated-index relation}
\rightarrow
\hat{\theta}
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t,
$$

but it cannot, by itself, identify regime-dependent parameters or threshold dynamics.

---

## 6. Rule for Chapter 2

Use FM-OLS for the main long-run reconstruction layer.

Use the LRV/kernel warning to prevent overclaiming.

The correct claim is:

FM-OLS is structurally cleaner than DOLS for recovering the A00 aggregate interaction relation, but its covariance correction is still global. Therefore, FM-OLS can support the global A00 reconstruction, but it cannot by itself identify regime-dependent transformation elasticities without an additional regime-aware design.

---

## 7. Relation to other estimators

DOLS risks parametric clutter because it adds leads and lags to the regression.

FM-OLS avoids this clutter but introduces covariance-smoothing risk.

IM-OLS avoids both DOLS lead-lag clutter and FM-OLS kernel/bandwidth tuning in estimation, but it creates an integration-ladder trace-back problem.

Thus, each estimator has its own structural cost:

- DOLS: regressor-matrix pollution;
- FM-OLS: covariance-window smearing;
- IM-OLS: integrated-space trace-back.

---

## 8. Locked sentence for reuse

**FM-OLS preserves the A00 structural regressor matrix, but its long-run variance correction can smooth across historical regime boundaries. It is therefore preferred for global estimation of the A00 time-varying interaction mapping, not for identifying regime-dependent transformation elasticities by itself.**

---

## References

Andrews, D. W. K. (1991). Heteroskedasticity and autocorrelation consistent covariance matrix estimation. *Econometrica, 59*(3), 817–858.

Kiefer, N. M., & Vogelsang, T. J. (2005). A new asymptotic theory for heteroskedasticity-autocorrelation robust tests. *Econometric Theory, 21*(6), 1130–1164.

Phillips, P. C. B. (1995). Fully modified least squares and vector autoregression. *Econometrica, 63*(5), 1023–1078.

Phillips, P. C. B., & Hansen, B. E. (1990). Statistical inference in instrumental variables regression with I(1) processes. *Review of Economic Studies, 57*(1), 99–125.
