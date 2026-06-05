# §2.5.1 — The Structural Problem with Standard CU Estimates
**Source authority:** `Ch2_Outline_DEFINITIVE.md` §2.5.1; `reproduction_function.md`; Cajas-Guijarro (2024)
**Date drafted:** 2026-04-02 | **Revised:** 2026-04-02 (WLM v4.0)
**Word count:** ~950
**Self-check:** PASS
**Transition check:** Opens from §2.4's rank-1 identification; closes by handing off to §2.5.2 (Stage A.1, US MPF) and §2.5.3 (long-run projection of $\pi_t$).

---

This section reconstructs capacity utilization identification not as a filtering problem — the extraction of a stationary residual from a trend — but as a structural determination problem in which the object to be recovered, $\hat{\mu}_t$, is defined by the same distributional parameters that govern the long-run channels of accumulation. Standard approaches to CU measurement suppress precisely this determination. That they do so reveals something about the field's relationship to its own measurement instrument: the concept of productive capacity has been operationalized as if it were distribution-invariant, when the accounting framework of §2.3 establishes that it cannot be.

## The structural failure of standard methods

Conventional capacity utilization measures — the Hodrick-Prescott filter, peak-to-peak interpolation, and production-function residual methods — share a common structural deficiency: they impose $\theta = 1$ by construction. Balanced growth is assumed, so that productive capacity grows at the same rate as the capital stock and the output-capital ratio is trend-stationary. This assumption conflates the demand channel ($\mu_t$) with the technology channel ($b_t$) in the Weisskopf decomposition $r_t = \mu_t \cdot b_t \cdot \pi_t$. If the transformation elasticity is in fact distribution-dependent — if $\theta_t = \theta_1 + \theta_2 \pi_t \neq 1$ — then filtering methods absorb regime-dependent capacity shifts into the utilization residual, contaminating $\hat{\mu}_t$ with structural variation that belongs in $\hat{b}_t$. The identification of over-mechanization ($\theta < 1$) or under-mechanization ($\theta > 1$) regimes is ruled out before estimation begins. The grounds for rejecting HP-based measures are not statistical but structural: the filter does not merely smooth badly — it suppresses the distribution-capacity channel that the Weisskopf decomposition requires as an input to Stage B.

A deeper problem concerns the stationarity of the utilization measure itself. A single-equation approach — estimating $\hat{\theta}$ from the condition that $y_t - (\theta_1 + \theta_2 \pi_t) k_t$ is $I(0)$ — imposes stationarity on capacity utilization by construction. If $\mu_t$ is genuinely $I(1)$, as it may be over samples that span structural breaks, this procedure generates a spurious cointegrating vector and a contaminated $\hat{\mu}_t$ series. The rank-1 identification of §2.4, taken in isolation, is not immune to this problem — it too imposes the stationarity it claims to test. Therefore the econometric framework must permit the integration order of $\hat{\mu}_t$ to be determined empirically, and this requires embedding the capacity relation within a system where rank is tested, not assumed.

## The four-variable over-identified system

The interaction term $\pi_t k_t$ is not a linearization convenience — it is the object that makes the transformation elasticity $\hat{\theta}_t = \theta_1 + \theta_2 \pi_t$ distribution-dependent at every date. Removing it from the state vector collapses $\hat{\theta}$ to the fixed parameter $\theta_1$ and eliminates the distributional rotation of the capacity manifold that §2.4 established as the chapter's identifying structure. The resolution is to embed the rank-1 identification within a system that disciplines $\theta_1$ and $\theta_2$ through multiple structural channels simultaneously, and to let the cointegration rank — and therefore the stationarity of $\hat{\mu}_t$ — be determined by the data. The state vector is

$$\mathbf{X}_t = (y_t,\; k_t,\; \pi_t,\; \pi_t k_t)'. \tag{2.10}$$

All four components are potentially $I(1)$. Three cointegrating relations, sharing the structural parameters $\{\theta_1, \theta_2, \varrho, \delta\}$, confine the long-run behavior of the system.

**CV1 — Distribution-conditioned confinement (from §2.4):**

$$y_t - \theta_1 k_t - \theta_2(\pi_t k_t) = \hat{\mu}_t \quad \Leftrightarrow \quad [1,\; -\theta_1,\; 0,\; -\theta_2] \cdot \mathbf{X}_t = \hat{\mu}_t. \tag{2.11}$$

The residual $\hat{\mu}_t$ is log capacity utilization — the deviation of realized output from the distribution-conditioned capacity manifold.

**CV2 — Distribution-utilization channel (Phillips curve, from Chapter 1):**

$$\pi_t = \varrho(y_t - \theta_1 k_t - \theta_2 \pi_t k_t) \quad \Leftrightarrow \quad [-\varrho,\; \varrho\theta_1,\; 1,\; \varrho\theta_2] \cdot \mathbf{X}_t = 0. \tag{2.12}$$

The same $\theta_1$ and $\theta_2$ that define the capacity manifold in CV1 govern the equilibrium distribution-utilization relationship in CV2. This is a cross-equation restriction: the profit share cannot vary freely in the long run but is anchored by the structural link between distribution and capacity utilization derived in Chapter 1.

**CV3 — Cambridge-Goodwin profitability:**

$$[-2,\; (2+\theta_1),\; -1,\; \theta_2] \cdot \mathbf{X}_t = -\delta. \tag{2.13}$$

A third structural channel confines distributional variation through the profitability identity. The depreciation rate $\delta$ enters as an additional shared parameter. The same $\theta_1$ and $\theta_2$ appear again — the system is over-identified because a single structural object, the distribution-conditioned transformation elasticity, generates restrictions across three independent long-run equilibrium conditions.

The over-identification is what makes the system informative. The parameter vector $\{\theta_1, \theta_2, \varrho, \delta\}$ is shared across three equations that impose more cross-equation restrictions than a single structural relation could sustain. This permits efficient estimation of $\theta_1$ and $\theta_2$ from three simultaneous channels, and it generates testable hypotheses internal to the system: $H_0\!: \theta_2 = 1/2$ (the Cajas-Guijarro quadratic MPF restriction), consistency of the Phillips-curve slope $\varrho$ with Chapter 1 estimates, and the plausibility of the implied depreciation rate $\delta$ against national accounts data. Cointegration rank is determined by Johansen trace and maximum-eigenvalue tests on the four-variable system — tested empirically, not imposed. If the data support rank $r = 3$, all three structural relations hold in the long run and the system is internally consistent; rank $r < 3$ would indicate that not all channels are cointegrating, a substantive finding that disciplines the scope of the identification.

## Two estimation routes

The four-variable system admits two routes to recovering $\hat{\theta}_t$ and $\hat{\mu}_t$, distinguished by data availability and institutional context.

Route 1, the direct MPF regression, estimates the cost-minimizing first-order condition $a_t = \alpha_1 q_t + \alpha_2 q_t^2$ using observed employment data to construct the mechanization growth rate $q_t$. This route identifies $\alpha_1$, $\alpha_2$, and the optimal mechanization trajectory $q_t^*$ directly, and tests $\theta_2 = 1/2$ against the four-variable system as a cross-validation. Route 1 is the primary identification for the United States, where BLS employment series are available at the required frequency and sectoral coverage.

Route 2, the restricted VECM, estimates CV1–CV3 simultaneously on $(y_t, k_t, \pi_t, \pi_t k_t)$ with $\theta_1$, $\theta_2$, $\varrho$, and $\delta$ constrained equal across equations. This route recovers $\hat{\theta}_t$, $\hat{\mu}_t$, and $\hat{b}_t$ without requiring employment data. It is the primary identification for Chile, where consistent employment series spanning the full estimation sample do not exist, and where the restricted VECM preserves the distributional dependence of the transformation elasticity within a single integrated system. Cointegration rank is tested, not imposed.

The two routes are not competing methods but complementary identifications disciplined by distinct data environments. For the United States, Route 1 provides a direct estimate that Route 2 validates; for Chile, Route 2 is the only feasible identification, and the cross-country comparison developed in §2.5.3 and §2.10 is meaningful precisely because the same structural parameters govern both.
