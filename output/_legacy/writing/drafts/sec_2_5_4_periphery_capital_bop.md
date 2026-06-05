# §2.5.4 — Stage A.2: Periphery Capital Composition and BoP Constraint
**Source authority:** `Ch2_Outline_DEFINITIVE.md` §2.5.4; `ch2_section_prompts.md`
**Date drafted:** 2026-04-02
**Word count:** ~710
**Self-check:** PASS
**Transition check:** Opens from §2.5.3's parallel construction; closes by handing off to §2.5.5 (recovering $\hat{\theta}_t^{CL}$ and $\hat{\mu}_t^{CL}$).

---

The cost-minimization problem developed in Stage A.1 treats the capital stock as homogeneous. For the US corporate sector, this is a defensible abstraction: the domestic capital goods sector produces both structures and equipment, and mechanization does not require systematic recourse to foreign exchange. In peripheral capitalism, the abstraction breaks down. The Chilean capital stock is composed of nonresidential infrastructure ($K^{NR}$) and machinery and equipment ($K^{ME}$), and the two components occupy structurally different positions in the accumulation process. Infrastructure is produced domestically; machinery must be imported. The capital goods sector is structurally incomplete — the periphery cannot produce $K^{ME}$ at scale — so every increment of mechanization through equipment investment requires foreign exchange. The balance-of-payments constraint enters the cost-minimization problem not as an external shock but as a structural cost of accumulation that the center does not face.

The capital stock decomposes as

$$K_t^{CL} = K_t^{NR} + K_t^{ME}, \tag{2.14}$$

with the machinery share $s_t^{ME} \equiv K_t^{ME} / K_t^{CL}$ varying over time as the composition of accumulation shifts between infrastructure and equipment. Total mechanization growth decomposes accordingly:

$$q = (1 - s_t^{ME})\,q^{NR} + s_t^{ME}\,q^{ME}. \tag{2.15}$$

The two capital types carry differential productivity effects. Define the composition-weighted MPF slope as

$$\bar{\alpha}_1^{CL} \equiv \alpha_1^{NR}(1 - s_t^{ME}) + \alpha_1^{ME}\, s_t^{ME}, \tag{2.16}$$

so that the peripheral MPF retains the same quadratic functional form as the center:

$$a = \bar{\alpha}_1^{CL}\, q + \alpha_2\, q^2. \tag{2.17}$$

If capital-embodied technical change in machinery exceeds that in infrastructure — $\alpha_1^{ME} > \alpha_1^{NR}$ — then a higher equipment share raises the productivity potential of mechanization, but at the cost of greater import dependence and deeper exposure to external constraint. This is the Kaldor-ECLA fault line: does the external balance-of-payments ceiling, which limits the rate of equipment mechanization $q^{ME}$, or the internal consumption drain, which limits the profit share $\pi$ available for reinvestment, bind first? The question is an estimable structural one, not a theoretical imposition. Data from the K-Stock-Harmonization pipeline — the canonical Pérez (1900--1994) baseline extended by BCCh to 2024 — provides $K^{ME}$ and $K^{NR}$ directly, so the capital type decomposition does not require imputation.

The balance-of-payments constraint enters the cost function as an additional external cost per unit of mechanization. The peripheral cost-minimization problem is

$$\min_q\; c = a - q\pi + \lambda \cdot s^{ME} \cdot \xi^{ME}_K \cdot q \tag{2.18}$$

subject to $a = \bar{\alpha}_1^{CL}\, q + \alpha_2\, q^2$, where $\xi^{ME}_K \approx 0.92$--$0.94$ is the import content of machinery investment (the Kaldor 1959 prior drawn from Cuadro 8), $s^{ME}$ is the observable equipment share, and $\lambda$ is the shadow cost of foreign exchange — the intensity of the external constraint on accumulation. The term $\lambda s^{ME} \xi^{ME}_K q$ represents the total external cost of mechanizing at rate $q$: the price the periphery pays for accumulation that the center does not face.

Substituting the constraint and differentiating yields the first-order condition

$$\bar{\alpha}_1^{CL} + 2\alpha_2 q - \pi + \lambda s^{ME}\xi^{ME}_K = 0, \tag{2.19}$$

from which the peripheral optimal mechanization rate follows:

$$q^{CL*} = \frac{\pi - \lambda s^{ME}\xi^{ME}_K - \bar{\alpha}_1^{CL}}{2\alpha_2}. \tag{2.20}$$

The structure of the solution makes the center-periphery mechanization gap transparent. Table 2.1 collects the comparison.

| | Center (Stage A.1) | Periphery (Stage A.2) |
|---|---|---|
| Capital structure | Homogeneous $K$ | $K^{NR} + K^{ME}$ ($\xi^{ME}_K \approx 0.92$--$0.94$) |
| Cost function | $c = a - q\pi$ | $c = a - q\pi + \lambda s^{ME}\xi^{ME}_K q$ |
| FOC | $q^* = (\pi - \alpha_1)/(2\alpha_2)$ | $q^{CL*} = (\pi - \lambda s^{ME}\xi^{ME}_K - \bar{\alpha}_1^{CL})/(2\alpha_2)$ |
| BoP penalty | None | $\lambda s^{ME}\xi^{ME}_K > 0$ |

**Table 2.1.** Center-periphery cost-minimization comparison.

The balance-of-payments penalty $\lambda s^{ME}\xi^{ME}_K$ acts as an effective reduction in the profit share available to induce mechanization. For a given $\pi$, the periphery mechanizes at a lower rate than the center by exactly $\lambda s^{ME}\xi^{ME}_K / (2|\alpha_2|)$. The gap is derived from the cost-minimization problem, not imposed as a calibration target or a stylized fact about peripheral underdevelopment. It is a structural consequence of the incompleteness of the domestic capital goods sector: the shadow cost of foreign exchange mediates the translation of distributional surplus into productive capacity. The next subsection recovers the peripheral transformation elasticity $\hat{\theta}_t^{CL}$ and utilization series $\hat{\mu}_t^{CL}$ from this modified cost structure.
