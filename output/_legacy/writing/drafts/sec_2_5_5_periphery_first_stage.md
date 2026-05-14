# §2.5.5 — Peripheral First-Stage Recovery: $\hat{\theta}_t^{CL}$, $\hat{\mu}_t^{CL}$, and the Center-Periphery Gap
**Source authority:** `Ch2_Outline_DEFINITIVE.md` §2.5.5; `ch2_section_prompts.md`
**Date drafted:** 2026-04-02
**Word count:** ~400
**Self-check:** PASS
**Transition check:** Opens from §2.5.4's modified FOC and BoP penalty; closes by handing off to §2.6 (Stage B Weisskopf profitability decomposition).

---

The two-step identification procedure of §2.5.3 extends directly to the peripheral economy once the balance-of-payments penalty derived in §2.5.4 is absorbed into the long-run profit share projection. The restricted four-variable VECM is estimated on the Chilean state vector $(y_t^{CL},\, k_t^{CL},\, \pi_t^{CL},\, (\pi k)_t^{CL})'$, and the Gonzalo-Granger permanent component delivers the long-run fitted profit share $\hat{\pi}_t^{LR}$ by the same substitution logic as in equation (2.14). The peripheral long-run projected profit share then corrects for the external cost of mechanization:

$$\hat{\pi}_t^{CL,LR} \;=\; \hat{\pi}_t^{LR} \;-\; \lambda\, s_t^{ME}\, \xi_K^{ME}, \tag{2.21}$$

where $\lambda$ is the shadow cost of foreign exchange identified from the augmented CV1, $s_t^{ME}$ is the time-varying machinery share from the K-Stock-Harmonization pipeline, and $\xi_K^{ME} \approx 0.92$ is the import content of equipment investment imposed as a Kaldor prior. The correction subtracts the distributional surplus absorbed by the balance-of-payments constraint before it can induce mechanization --- the portion of the profit share that finances import dependence rather than productive capacity expansion.

The peripheral first-stage transformation elasticity follows under the Cajas-Guijarro restriction $\theta_2 = 1/2$:

$$\hat{\theta}_t^{CL,(1)} \;=\; \frac{\bar{\alpha}_1^{CL} \;+\; \hat{\pi}_t^{LR} \;-\; \hat{\lambda}\, \xi_K^{ME}\, s_t^{ME}}{2}. \tag{2.22}$$

The center-periphery gap in the transformation elasticity decomposes into two identifiable components:

$$\hat{\theta}_t^{US,(1)} \;-\; \hat{\theta}_t^{CL,(1)} \;=\; \frac{\bigl(\alpha_1^{US} \;-\; \bar{\alpha}_1^{CL}\bigr) \;+\; \lambda\, s_t^{ME}\, \xi_K^{ME}}{2}. \tag{2.23}$$

The first term is the MPF slope gap --- a structural technology difference reflecting the higher productivity of mechanization in the center, where the domestic capital goods sector is complete. The second term is the BoP penalty --- the external constraint that compresses the effective profit share available for technique choice in the periphery. Decomposing this gap is the empirical content of the Kaldor-ECLA fault line: the relative weight of internal technological asymmetry against external balance-of-payments dependence in explaining why peripheral capitalism operates on a lower capacity manifold.

The identification of $\hat{\lambda}$ proceeds within the cointegrating system. In the augmented CV1, $\hat{\lambda}$ is the coefficient on the interaction $s_t^{ME}\, k_t^{CL}$, with $\xi_K^{ME} \approx 0.92$ imposed rather than estimated. The K-Stock-Harmonization pipeline provides $s_t^{ME}$ directly from the Perez baseline and BCCh extension, so the capital composition variable enters the VECM as observed data, not as a generated regressor.

Capacity utilization is recovered over the full sample by imposing the first-stage elasticity:

$$\hat{\mu}_t^{CL} \;=\; \exp\!\bigl(y_t^{CL} \;-\; \hat{\theta}_t^{CL,(1)}\, k_t^{CL}\bigr). \tag{2.24}$$

Transitory distributional fluctuations $\pi_t^{CL} - \hat{\pi}_t^{CL,LR}$ --- purged from the technology channel by the long-run projection --- feed $\hat{\mu}_t^{CL}$ as demand-side variation, exactly as in the center specification. Capital productivity at normal capacity follows directly: $\hat{b}_t^{CL} = (\hat{\theta}_t^{CL,(1)} - 1)\, k_t^{CL}$. Both objects --- $\hat{\mu}_t^{CL}$ and $\hat{b}_t^{CL}$ --- enter Stage B of the Weisskopf profitability decomposition, carrying the structural imprint of the balance-of-payments constraint through the $\hat{\lambda}$ correction embedded in $\hat{\theta}_t^{CL,(1)}$.
