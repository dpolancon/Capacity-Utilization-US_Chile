---
type: note
status: locked
layer: method
design_role: structural_object_definition
scope: chapter2_core_support
related_to:
  - A00_Aggregate_Transformation_Benchmark
  - M10_Empirical_Identification_Framework
  - N02_SuperConsistency
  - R01_residual_vs_structural_identification
  - L00_Econometrics_References
priority: high
---

# Capacity Utilization as a Structural Object

## Core claim

Capacity utilization is not directly observed and not identified by a residual.

It is a derived level ratio:

$$
\mu_t = \frac{Y_t}{Y_t^p},
$$

where observed output $Y_t$ is known, but productive capacity $Y_t^p$ is unobserved and must be structurally reconstructed.

---

## 1. Object definition

The empirical object is not the residual from an output-capital relation.

The empirical object is the ratio between observed output and reconstructed productive capacity.

Therefore, the object requires two steps:

1. identify the productive-capacity path;
2. derive utilization from that path.

The residual may describe the gap after reconstruction, but it cannot identify the denominator.

---

## 2. Productive capacity comes first

The admissible identification target is productive capacity, either as:

1. the growth law of $Y_t^p$; or
2. the log-level long-run path of $Y_t^p$.

Only after this object is recovered can utilization be computed.

Thus:

$$
\text{structural relation}
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

Not:

$$
\text{residual}
\rightarrow
\hat{\mu}_t.
$$

---

## 3. Transformation elasticity

In Chapter 2, the hinge object is the transformation elasticity $\theta_t$.

It expresses how capital accumulation is converted into productive capacity.

The A00 baseline econometric object is the aggregate interaction relation:

$$
y_t = c + \beta_1 k_t + \beta_2(\omega_t k_t) + \xi_t,
$$

which implies:

$$
\theta_t = \beta_1 + \beta_2\omega_t.
$$

In A00, the interaction term $\omega_t k_t$ is the baseline econometric device through which the aggregate transformation elasticity becomes time-varying while capital remains undifferentiated.

The reconstruction sequence is therefore:

$$
\text{A00 aggregate interaction relation}
\rightarrow
\hat{\theta}_t
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

This is not yet utilization. It is the transformation rule used to reconstruct productive capacity.

---

## 4. Dimensional admissibility

The log-level relation must be dimensionally disciplined.

Following Basu’s dimensional-analysis critique, variables entering logarithms should be interpreted as dimensionless ratios, indexes, or rebased magnitudes, not raw dimensioned quantities.

This matters because the transformation relation is not merely a convenient statistical equation. It is the empirical form through which productive capacity is reconstructed.

Therefore, log output and log capital must be treated as admissible dimensionless objects before they can support reconstruction.

---

## 5. Residualization versus residual ontology

Residualization can be an admissible econometric operation.

For example, Basu’s Yule-Frisch-Waugh-Lovell discussion clarifies that residualized regressions can recover the same coefficient vector as a full model under precise conditions.

But this does not imply that residuals identify economic objects.

Residualization is a conditioning or computational device. Residual ontology is the mistake of treating the residual itself as the object.

For capacity utilization, the rule is strict:

> residuals may help compute, condition, or diagnose; they do not identify $Y_t^p$ or $\mu_t$.

---

## 6. Level anchoring

Because $Y_t^p$ is unobserved, the reconstructed path requires level anchoring.

A long-run coefficient can discipline the growth or slope of productive capacity, but it does not automatically determine the absolute level of capacity.

Therefore, the reconstructed path must be normalized through an explicit benchmark rule, such as a pinch year or another theoretically justified level anchor.

Without level anchoring, utilization remains underidentified.

---

## 7. Operational sequence

The admissible empirical sequence is:

1. define the theoretical transformation relation;
2. estimate the long-run coefficient vector;
3. recover $\hat{\theta}_t$;
4. reconstruct $\hat{Y}_t^p$;
5. impose level anchoring;
6. derive:

$$
\hat{\mu}_t = \frac{Y_t}{\hat{Y}_t^p}.
$$

This sequence prevents the residual from being mistaken for utilization.

---

## 8. Methodological lock

Capacity utilization is a reconstructed structural object.

Its empirical identification requires:

- a theoretically specified productive-capacity relation;
- dimensionally admissible log variables;
- econometrically defensible coefficient recovery;
- explicit level anchoring;
- and rejection of residual identification.

---

## 9. Locked sentence for reuse

**Capacity utilization is not the residual from an output-capital relation. It is a level ratio between observed output and structurally reconstructed productive capacity; therefore, identification must first recover and anchor $Y_t^p$ before $\mu_t$ can be derived.**

---

## References

Basu, D. (2022). *Dimensional analysis and logarithmic transformations in applied econometrics* (Working Paper No. 2022-22). University of Massachusetts Amherst, Department of Economics. https://doi.org/10.7275/6dk1-fw16

Basu, D. (2023). *The Yule-Frisch-Waugh-Lovell theorem for linear instrumental variables estimation*. arXiv. https://arxiv.org/abs/2307.12731

Shaikh, A. (1974). *Laws of production and laws of algebra: The humbug production function*. Bard Digital Commons.
