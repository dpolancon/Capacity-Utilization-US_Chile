---
type: rule_note
status: binding
layer: analytical_foundation
scope: chapter2_core
topic: distribution_conditioned_transformation_elasticity
created: 2026-06-08
updated: 2026-06-11
design_role: specification_governance
---

# Distribution-Conditioned Transformation Elasticity Identification

## Binding object

Observed output is effective-demand-realized output. Productive capacity is latent:

$$
y_t = y_t^p + \log \mu_t.
$$

The empirical problem is reconstruction of $y_t^p$, not direct measurement of $\mu_t$. The first layer identifies a distribution-conditioned capital-to-capacity elasticity. It does not identify utilization, short-run demand adjustment, or a wage-led/profit-led demand regime.

The binding sequence is:

$$
\text{long-run coefficient vector}
\rightarrow
\hat{\theta}_t
\rightarrow
\hat{y}_t^p
\rightarrow
\hat{\mu}_t.
$$

After productive capacity has been reconstructed and explicitly anchored:

$$
\widehat{\log \mu_t}
=
y_t-\hat{y}_t^p.
$$

**Coefficient consistency does not imply object consistency.**

## First-layer specification

The preferred first-layer equation is the primitive interaction:

$$
y_t
=
\alpha
+
\theta_0 k_t
+
\phi \tilde d_t
+
\theta_1(k_t\tilde d_t)
+
\varepsilon_t.
$$

The identified object is:

$$
\theta_t
=
\theta_0+\theta_1\tilde d_t.
$$

The direct distribution term remains as a nuisance control. Omitting it imposes:

$$
\phi=0,
$$

and risks forcing the interaction to absorb distributional level effects. It also protects the interaction from arbitrary rebasing of capital:

$$
(k_t+c)\tilde d_t
=
k_t\tilde d_t+c\tilde d_t.
$$

The coefficient $\phi$ is not evidence of a wage-led or profit-led demand regime. The first-layer question is not:

$$
\frac{\partial y}{\partial d},
$$

but:

$$
\frac{\partial}{\partial d}
\left(
\frac{\partial y^p}{\partial k}
\right).
$$

## Distribution reference

The baseline uses a constant reference:

$$
\tilde d_t=d_t-\bar d.
$$

A rolling diagnostic may use:

$$
\tilde d_{t,w}=d_t-\bar d_w.
$$

HP-filter deviations are not the baseline. They change the object from distributional conditioning of $\theta_t$ to cyclical distribution-gap conditioning of $\theta_t$.

## Productive-capital boundary

The first-layer $k_t$ is productive-capacity capital, not all fixed capital. The productive boundary must be defined before estimation.

Financial-circulation fixed assets, intellectual-property products, government transport, and similar assets may enter later as conditioners, diagnostics, or robustness objects. They do not enter automatically as baseline productive capital.

## Open specification fork

The vault does not lock an additive-capital conclusion or a one-to-one mapping from machinery to an intensive margin and structures to an extensive margin.

The open question is:

> Does distributional pressure condition the capital-to-capacity mapping directly through productive-capital scale, or indirectly through the composition of productive capital?

### Specification A: direct scale-conditioning

$$
y_t
=
\alpha
+
\theta_0 \tilde k_t^{scale}
+
\phi \tilde d_t
+
\theta_1(\tilde k_t^{scale}\tilde d_t)
+
\varepsilon_t,
$$

with:

$$
\theta_t
=
\theta_0+\theta_1\tilde d_t.
$$

### Specification B: composition-mediated conditioning

$$
y_t
=
\alpha
+
\theta \tilde k_t^{scale}
+
\psi \tilde\tau_t
+
\phi \tilde d_t
+
\lambda(\tilde\tau_t\tilde d_t)
+
\varepsilon_t,
$$

where:

$$
\tilde\tau_t
=
\left(\ln K_t^{ME}-\ln K_t^{NR}\right)
-
\overline{\left(\ln K^{ME}-\ln K^{NR}\right)}.
$$

The composition response is:

$$
\frac{\partial \hat y_t^p}{\partial \tilde\tau_t}
=
\psi+\lambda\tilde d_t.
$$

Specification B tests whether distribution acts through technique or composition rather than directly through productive-capital scale.

## Layer boundaries

The first layer identifies the long-run capital-to-capacity elasticity. It does not identify:

- the speed of adjustment;
- an ECM coefficient;
- a short-run multiplier;
- full VECM dynamics;
- a demand regime.

Government expenditure, exports, consumption, imports, and other demand-composition variables remain theoretically relevant to realization, utilization, leakages, fixed points, and later interpretation. They are not direct first-layer productive-capacity builders.

## Estimator hierarchy

- FM-OLS is the preferred main estimator for the log-level reconstruction layer.
- IM-OLS is a robustness check.
- DOLS is a fragility diagnostic because leads and lags are costly in short samples.
- Threshold-FGLS belongs only to a separate regime layer after diagnostic justification.

The first layer assumes a stable long-run relation. A threshold or regime-switching layer can follow only after:

1. integration order;
2. deterministic components;
3. structural breaks;
4. nonlinear mean reversion;
5. threshold admissibility.

## Parked / not current baseline

The accumulated historical-memory operator:

$$
q_t^{\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s
$$

is parked, not deleted. It may be tested after the primitive interaction problem is clarified. It is not the current baseline, does not govern first-layer exports, and does not authorize reconstruction.

Non-interacted distribution-control equations, ARDL short-run adjustment, full VECM dynamics, and threshold-FGLS are not preferred first-layer identification routes.

## Governing links

- [[A00_Aggregate_Transformation_Benchmark]]
- [[A03_TransformationElasticity_Two-CapitalCapacityComposition]]
- [[A05_NRCEnvelope_MechanizationBias]]
- [[R10_Binding_Specification_Layering_Rule]]
- [[M10_Empirical_Identification_Framework]]
