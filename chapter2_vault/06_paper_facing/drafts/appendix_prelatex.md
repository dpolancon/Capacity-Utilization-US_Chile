---
type: paper_facing
status: draft
country: US_CL
stage_scope: N/A
last_updated: '2026-07-29'
depends_on: []
blocks: []
layer: design
scope: chapter2
priority: context
---

# Appendix A: Mathematical Derivation of the Dual-Channel Choice of Technique

This appendix provides the formal derivation of the partial derivatives governing the firm's choice of intensive mechanization ($q^{ME*}$) with respect to the distributional channel ($\omega$) and the relative price channel ($\rho^{ME,NRC}$).

### A.1 The Constrained Objective Function

As established in Section 3.2.3, the firm maximizes the net productivity surplus $c(q^{ME}) = a - \text{Cost}$ subject to the Leontief proportionality constraint $q^{NRC} = \Phi(q^{ME})$. The unconstrained objective function is:
$$ c(q^{ME}) = \Big[ 1 - (1-\omega)\rho^{NRC} \Big] \Phi(q^{ME}) - \Big[ (1-\omega)\rho^{NRC} \cdot \rho \Big] q^{ME} $$
where $\rho = P^{ME}/P^{NRC}$ is the relative price of machinery to structures, and $\rho^{NRC}$ is the relative price of structures to output.

Taking the derivative with respect to $q^{ME}$ and setting it to zero yields the first-order condition:
$$ \Phi'(q^{ME*}) = \frac{(1-\omega)\rho^{NRC} \cdot \rho}{1 - (1-\omega)\rho^{NRC}} \equiv H $$
where $H$ is the effective cost hurdle of mechanization.

Given the technological frontier $\Phi(q) = \lambda_0 + \lambda_1 q + \lambda_2 q^2$, the marginal product is $\Phi'(q) = \lambda_1 + 2\lambda_2 q$. Substituting this into the FOC gives the optimal rate of mechanization:
$$ q^{ME*} = \frac{H - \lambda_1}{2\lambda_2} $$

### A.2 The Distributional Channel ($\omega$)

We use the chain rule to find $\frac{\partial q^{ME*}}{\partial \omega} = \frac{\partial q^{ME*}}{\partial H} \cdot \frac{\partial H}{\partial \omega}$.

Because of the concavity of the technological frontier (diminishing returns to mechanization), $\lambda_2 < 0$. Therefore:
$$ \frac{\partial q^{ME*}}{\partial H} = \frac{1}{2\lambda_2} < 0 $$

Next, we differentiate the hurdle $H$ with respect to the wage share $\omega$:
$$ \frac{\partial H}{\partial \omega} = \frac{ - \rho^{NRC} \rho \cdot \Big[1 - (1-\omega)\rho^{NRC}\Big] - \Big[(1-\omega)\rho^{NRC} \rho\Big] \cdot \rho^{NRC} }{ \Big[1 - (1-\omega)\rho^{NRC}\Big]^2 } $$
Simplifying the numerator:
$$ \frac{\partial H}{\partial \omega} = \frac{-\rho^{NRC} \cdot \rho}{\Big[1 - (1-\omega)\rho^{NRC}\Big]^2} < 0 $$

Applying the chain rule:
$$ \frac{\partial q^{ME*}}{\partial \omega} = \underbrace{\left( \frac{1}{2\lambda_2} \right)}_{(-)} \cdot \underbrace{\left( \frac{-\rho^{NRC} \cdot \rho}{[ \dots ]^2} \right)}_{(-)} > 0 $$

**Proof:** A rising wage share unequivocally increases optimal intensive mechanization.

### A.3 The Relative Price Channel ($\rho$)

We use the chain rule to find $\frac{\partial q^{ME*}}{\partial \rho} = \frac{\partial q^{ME*}}{\partial H} \cdot \frac{\partial H}{\partial \rho}$.

We differentiate the hurdle $H$ with respect to the relative price of machinery to structures ($\rho$):
$$ \frac{\partial H}{\partial \rho} = \frac{(1-\omega)\rho^{NRC}}{1 - (1-\omega)\rho^{NRC}} > 0 $$

Applying the chain rule:
$$ \frac{\partial q^{ME*}}{\partial \rho} = \underbrace{\left( \frac{1}{2\lambda_2} \right)}_{(-)} \cdot \underbrace{\left( \frac{(1-\omega)\rho^{NRC}}{1 - (1-\omega)\rho^{NRC}} \right)}_{(+)} < 0 $$

**Proof:** A falling relative price of machinery ($\rho \downarrow$) unequivocally increases optimal intensive mechanization, acting mathematically identically to an aggressive wage squeeze.
