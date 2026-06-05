# §2.5.2 — Stage A.1: MPF Cost-Minimization Problem (Center)
**Source authority:** `Ch2_Outline_DEFINITIVE.md` §2.5.2; Cajas-Guijarro (2024)
**Date drafted:** 2026-04-02
**Word count:** ~500
**Self-check:** PASS
**Transition check:** Opens from §2.5.1's two estimation routes; closes by handing off to §2.5.3 (first-stage $\hat{\theta}$ identification via long-run projection).

---

**Notation lock (effective here and downstream):** $q \equiv \dot{K}/K - \dot{L}/L$ is the growth rate of the mechanization ratio $K/L$ throughout this chapter and all subsequent references. $M$ is reserved for imports in levels; $m$ for the import share or propensity in the balance-of-payments channel.

## The mechanization possibility frontier

The MPF is the quadratic production-side constraint that governs the trade-off between mechanization and labour productivity growth:

$$a_t = \alpha_1 q_t + \alpha_2 q_t^2, \tag{2.14}$$

where $a_t$ is the growth rate of labour productivity and $q_t$ is the growth rate of mechanization. The quadratic term captures diminishing returns on the frontier ($\alpha_2 < 0$): successive increases in mechanization yield progressively smaller productivity gains. The frontier-through-the-origin (FMT) restriction — no constant term — encodes the condition $F(0 \mid \Lambda) = 0$ from the reproduction function of §2.3: zero mechanization growth produces zero productivity growth, regardless of the institutional regime.

## The cost-minimization problem

Following Cajas-Guijarro (2024), the capitalist firm selects the mechanization rate that minimizes the unit cost of production, where the profit share $\pi_t$ represents the distributional cost per unit of mechanization:

$$\min_{q}\; c = a - q\pi \qquad \text{subject to} \quad a = \alpha_1 q + \alpha_2 q^2. \tag{2.15}$$

Substituting the constraint into the objective yields $c = q(\alpha_1 - \pi) + \alpha_2 q^2$. The first-order condition is

$$\frac{\partial c}{\partial q} = \alpha_1 - \pi + 2\alpha_2 q = 0 \quad \implies \quad q^* = \frac{\pi - \alpha_1}{2\alpha_2}. \tag{2.16}$$

The second-order condition $\partial^2 c / \partial q^2 = 2\alpha_2 < 0$ requires $\alpha_2 < 0$, consistent with diminishing returns. The optimal mechanization rate is increasing in the profit share ($\partial q^* / \partial \pi = 1/(2\alpha_2) < 0$ divided by a negative denominator yields a positive response): higher exploitation induces more mechanization, a structural regularity that the Cambridge-Goodwin tradition treats as the distribution-accumulation nexus at the technique-choice margin.

## The distribution-conditioned transformation elasticity

The capacity transformation elasticity at the optimum is the average-to-marginal productivity ratio on the MPF:

$$\theta^* = \frac{a^*}{q^*} = \alpha_1 + \alpha_2 q^*. \tag{2.17}$$

Substituting the optimal mechanization rate from (2.16):

$$\hat{\theta}_t = \frac{\alpha_1 + \pi_t}{2} = \underbrace{\frac{\alpha_1}{2}}_{\theta_1} + \underbrace{\frac{1}{2}}_{\theta_2}\,\pi_t. \tag{2.18}$$

This is the key result. The transformation elasticity is the average of the MPF slope $\alpha_1$ and the profit share $\pi_t$ — distribution-dependent, time-varying, and derived from cost-minimizing behaviour rather than assigned as a regime label. Under the quadratic MPF, $\theta_2 = 1/2$ is a structural prediction, not a free parameter. This restriction connects the direct MPF estimation to the four-variable system of §2.5.1: $\theta_2 = 1/2$ is exactly the testable hypothesis $H_0$ embedded in CV1, and the direct Route 1 estimate provides the structural foundation against which the system-based Route 2 can be validated. The next section takes up the identification problem that arises when $\pi_t$ in equation (2.18) contains transitory variation that does not belong in the technology channel.
