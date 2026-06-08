---
type: note
status: active
layer: method
design_role: estimator_admissibility_rule
scope: chapter2_core_support
related_to:
  - R01_residual_vs_structural_identification
  - N01_CapacityUtilization_StructuralObject
  - N02_SuperConsistency
  - M10_Empirical_Identification_Framework
  - L00_Econometrics_References
priority: high
---

# DOLS, Reconstruction, and the Estimator-Layer Boundary

## Core claim

DOLS is admissible for recovering a long-run coefficient vector under cointegration, but it is not automatically admissible as a reconstruction device for productive capacity or capacity utilization.

The reason is that DOLS solves an estimator problem, not an object-reconstruction problem. Its leads and lags of first differences help purify the long-run coefficient from endogeneity and serial-correlation problems, but those auxiliary terms do not belong to the structural path of productive capacity.

## 1. What DOLS does

DOLS estimates a long-run relation by augmenting the cointegrating regression with leads and lags of first differences:

$$
y_t = \alpha + \beta x_t + \sum_{j=-q}^{p}\gamma_j \Delta x_{t-j} + \varepsilon_t.
$$

The coefficient of interest is $\beta$.

The lead-lag terms are estimator corrections. They help address feedback, endogeneity, and serial correlation in the cointegrating regression. They do not identify the economic mechanism that generates productive capacity.

## 2. The reconstruction dilemma

The Chapter 2 target is not merely $\beta$. The target is the reconstructed path:

$$
\text{long-run relation}
\rightarrow
\hat{\theta}_t
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

DOLS can support the first step. It cannot complete the rest.

Its auxiliary lead-lag terms belong to the coefficient-recovery layer, not to the productive-capacity reconstruction layer.

## 3. Rule for productive-capacity reconstruction

When reconstructing $Y_t^p$, the relevant object is the long-run transformation relation.

The DOLS augmentation terms should not enter the reconstructed productive-capacity path unless they are explicitly theorized as part of capacity formation.

Otherwise, nuisance dynamics are imported into the structural object.

## 4. Chilean specification risk

In Chile, the risk is amplified by regime change.

A fixed DOLS lead-lag window may smooth across structurally distinct accumulation regimes. If the capital-output relation changes around major institutional ruptures, the auxiliary dynamics can smear the transition rather than clarify it.

This becomes especially problematic if the resulting residual or error-correction term is later used to activate regimes. That would collapse three distinct operations:

1. long-run coefficient recovery,
2. productive-capacity reconstruction,
3. regime classification.

That collapse is not admissible.

## 5. Correct use of DOLS

DOLS may be used as a robustness estimator for the long-run relation.

It should not be treated as a complete reconstruction procedure for $\mu_t$.

Correct interpretation:

> DOLS can purify the long-run coefficient, but it cannot by itself purify the reconstructed object. Its lead-lag augmentation belongs to the estimator layer, not to the structural capacity path.

## 6. Locked sentence for reuse

**DOLS is admissible for coefficient recovery under cointegration, but not as a direct reconstruction device for capacity utilization. Its lead-lag terms correct the estimation of the long-run coefficient; they do not identify the level path of productive capacity.**

## References

Engle, R. F., & Granger, C. W. J. (1987). Co-integration and error correction: Representation, estimation, and testing. *Econometrica, 55*(2), 251–276.

Johansen, S. (1991). Estimation and hypothesis testing of cointegration vectors in Gaussian vector autoregressive models. *Econometrica, 59*(6), 1551–1580.

Phillips, P. C. B. (1995). Fully modified least squares and vector autoregression. *Econometrica, 63*(5), 1023–1078.

Stock, J. H., & Watson, M. W. (1993). A simple estimator of cointegrating vectors in higher order integrated systems. *Econometrica, 61*(4), 783–820.