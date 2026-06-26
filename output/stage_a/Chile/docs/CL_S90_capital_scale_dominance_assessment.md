---
type: report
status: active
layer: method_interpretation
design_role: econometric_audit
scope: chapter2_chile_regimes
related_to:
  - R03_super_consistency_mechanics_hinge
  - R07_FGLS_threshold_cointegration_admissibility
  - R11_CointegrationAdmissibility_Super-Consistency
  - R12_FGLS_implementation_protocol
priority: high
---

# CL_S90: Capital Scale Dominance and Small-Sample Insignificance Audit (Chile)

## Executive Verdict

In the Cochrane-Orcutt FGLS threshold estimation for the Chilean capacity frontier (1940–1978, $N=39$), the aggregate capital scale ($k_t^{CL}$) is the only statistically significant regressor across both the BOP-constrained deficit regime ($t = 9.50$) and the unconstrained surplus regime ($t = 3.47$). The statistical insignificance of the capital composition ratio ($c_t$), the wage share level control ($\omega_t$), and their interaction ($\omega_c$) is not an indication that structural composition and distributional conflicts are absent. Instead, it is the direct consequence of **cointegration asymptotics and a small-sample degrees-of-freedom squeeze**. 

The aggregate capital scale captures the sovereign $I(1)$ stochastic trend of the system, achieving super-consistent convergence at rate $T$, which asymptotically dominates the composition and distributional controls whose convergence rates are limited to $\sqrt{T}$. When split across regimes and dynamically augmented, the standard errors of these secondary parameters explode due to a depleted degree-of-freedom pool, leaving $k_t^{CL}$ to absorb the entirety of the long-run cointegrating relationship.

---

## 1. Cointegration Asymptotics and the Super-Consistency Hinge

The fundamental source of parameter dominance in our model is the difference in asymptotic convergence rates between the regressors. 

Let the augmented capacity frontier regression be:

$$y_t = \alpha_g + A_g k_t^{CL} + B_g c_t + C_g (\omega_t c_t) + \phi_g \omega_t + \text{nuisance dynamics} + \eta_t$$

The aggregate capital scale variable, $k_t^{CL} = \ln(K^{NR}_t + K^{ME}_t)$, is a highly nonstationary $I(1)$ series characterized by a strong deterministic drift (accumulation trend). The dependent variable, $y_t$ (log real GDP), shares this drift. 

Under cointegration theory:
1. **Scale Coefficient ($A_g$):** Because $k_t^{CL}$ and $y_t$ share the primary $I(1)$ stochastic trend, the estimator $\hat{A}_g$ converges to its true value at rate $T$ (super-consistency):
   $$\hat{A}_g - A_g = O_p(T^{-1})$$
   This rapid convergence purges the estimator of small-sample bias and ensures highly concentrated probability mass, generating extremely small standard errors ($0.0889$ in Regime 1, $0.2578$ in Regime 2) and high t-statistics ($9.50$ and $3.47$).
2. **Composition and Distribution Coefficients ($B_g, C_g, \phi_g$):** Although the composition ratio $c_t = k_t^{ME} - k_t^{NR}$ and the wage share $\omega_t$ are persistent, they do not possess a strong deterministic drift; they behave asymptotically as stationary $I(0)$ or near-integrated drift-less processes. Consequently, their estimators converge at the standard rate of $\sqrt{T}$:
   $$\hat{B}_g - B_g = O_p(T^{-1/2})$$
   In a sample of $N=39$, a convergence rate of $\sqrt{T}$ is insufficient to overcome the noise of short-run adjustments, resulting in high parameter variance, large standard errors, and t-statistics below critical values.

---

## 2. Signal-to-Noise Ratio and Multi-Collinearity in Levels

The structures stock ($k_t^{NR}$) and machinery stock ($k_t^{ME}$) are highly collinear in levels ($r \approx 0.98$) due to their joint accumulation during Chile's ISI era. This collinearity is not eliminated by the aggregate scale ($k_t^{CL}$) and composition ($c_t$) reparameterization; rather, it is concentrated:

* **$k_t^{CL}$ (Aggregate Scale):** Captures the shared, high-signal stochastic trend of both capital components.
* **$c_t$ (Composition):** Captures the relative difference, which represents a low-frequency structural margin.

Because output $y_t$ is strongly cointegrated with the aggregate trend, $k_t^{CL}$ absorbs the common cointegrating vector. The composition variable $c_t$ is left to explain the remaining low-frequency variation. In a short annual macro series, this residual variation has a very low signal-to-noise ratio, making the composition coefficient $B_g$ highly fragile and statistically indistinguishable from zero.

---

## 3. Small-Sample Degrees-of-Freedom Squeeze

Estimating a multi-regime cointegrating model with dynamic endogeneity corrections requires a substantial number of observations. In our Chilean sample ($N=39$), the sample splitting and dynamic adjustments deplete the degrees of freedom:

| Model Layer | Parameter / Variable Count | Observations Consumed | Remaining Degrees of Freedom (Regime 1, $N_1=15$) | Remaining Degrees of Freedom (Regime 2, $N_2=23$) |
|---|---:|---:|---:|---:|
| **Raw Sample** | — | — | $15$ | $23$ |
| **FGLS Level Regressors** | $5$ parameters per regime | $10$ parameters total | $10$ | $18$ |
| **Cochrane-Orcutt AR(1)** | $1$ lag | $1$ observation | $9$ | $17$ |
| **Saikkonen Leads/Lags ($K=1$)** | $2$ parameters per capital stock | $4$ parameters total | **$5$** | **$13$** |

With only **5 degrees of freedom** remaining in Regime 1 to estimate 5 level parameters (Constant, Scale, Composition, Interaction, Distribution Control), the estimator's covariance matrix explodes:
$$\text{Var}(\hat{\theta}) = s^2 (Z^{*'} Z^*)^{-1}$$
Because $(Z^{*'} Z^*)^{-1}$ is poorly conditioned due to the small sample size, the standard errors of all non-scale regressors inflate dramatically. For example, the standard error of the interaction term $\omega_c$ in Regime 1 is $0.9269$ relative to a coefficient of $-0.0333$ ($t = -0.04$), and in Regime 2 it is $6.5849$ relative to a coefficient of $-0.2175$ ($t = -0.03$).

---

## 4. Cochrane-Orcutt FGLS Variance Shifting

The Cochrane-Orcutt FGLS transformation applies a quasi-differencing filter to the variables:
$$W_t^* = W_t - \hat{\rho}_1 W_{t-1}$$
With $\hat{\rho}_1 = 0.3690$, this transformation acts as a high-pass filter. It reduces the low-frequency trend component of the data and emphasizes the high-frequency (short-run) variations.

For the aggregate scale trend ($k_t^{CL}$), which has an extremely strong trend signal, this filtering does not prevent identification. However, for the composition ratio $c_t$ and the centered wage share $\omega_t$, which are already drift-less and move slowly, the quasi-differencing filter removes much of their useful variation. This shifts the variance structure of the regressors, further compounding the small-sample identification problem and causing the scale coefficient to absorb the remaining explanatory power.

---

## 5. Economic Implications for Capacity Utilization Reconstruction

The statistical dominance of $k_t^{CL}$ has clear implications for the Chilean productive capacity ($Y_t^p$) reconstruction:

1. **Scale as the Cointegrating Anchor:** The aggregate scale trend is the sovereign long-run anchor of the productive frontier. The capacity frontier is fundamentally driven by the scale of productive assets.
2. **Composition as a Parameter Drift:** Capital composition ($c_t$) and distribution ($\omega_t$) do not behave as sovereign cointegrating trends; instead, they act as conditioners of the scale elasticity. 
3. **Robustness of the Utilization Path:** Because the reconstructed utilization path ($\mu_{CL,t}$) is derived from the capacity frontier, the fact that the scale coefficient is highly significant and stable ($\hat{A}_1 = 0.8444$, $\hat{A}_2 = 0.8949$) ensures that the estimated capacity utilization series is robust and not distorted by the high variance of the secondary parameters.

Therefore, we must treat the recovered regime-specific scale elasticities as the primary empirical contribution of the threshold model, while treating the composition and distribution interaction coefficients as descriptive estimates of local parameter drift rather than statistically sovereign cointegrating vectors.
