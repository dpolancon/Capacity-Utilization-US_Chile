---
type: note
status: active
layer: superseded
design_role: theory_to_identification
scope: chapter2_core
related_to:
  - N01_CapacityUtilization_StructuralObject
  - N02_SuperConsistency
  - M10_Empirical_Identification_Framework
  - Marx_Okishio_Closure_Logic
created: 2026-05-05
---

# Two-corridor foundation for the transformation elasticity

## Core claim

The empirical coefficient on the wage-share interaction is not a generic distributive effect.

It is a reduced-form trace of two corridors:

1. the technical-mechanization corridor;
2. the normal profit-recapitalization corridor.

The empirical strategy therefore does not estimate a production function. It estimates how accumulation is historically transformed into productive capacity under regime-specific distributive conditions.

---

## 1. Notation lock

Let:

$$
A_t
$$

be labor productivity in levels.

$$
a_t = \Delta \ln A_t
$$

is labor-productivity growth.

Let:

$$
Q_t = \frac{K_t}{L_t}
$$

be the mechanization ratio.

$$
q_t = \Delta \ln Q_t
$$

is mechanization growth.

Let:

$$
B_t^N = \frac{Y_t^p}{K_t}
$$

be the normal output-capital ratio. This is not an autonomous productivity of capital. It is an artifact of labor productivity relative to mechanization.

Since:

$$
\frac{Y}{K} = \frac{Y/L}{K/L}
$$

we define:

$$
B_t^N = \frac{A_t}{Q_t^*}
$$

and therefore:

$$
b_t^N = \Delta \ln B_t^N = a_t - q_t^*
$$

Let:

$$
c_t^{w,N}
$$

be the historically given normal real wage bundle per unit of labor.

Then:

$$
\omega_t^N = \frac{c_t^{w,N}}{A_t}
$$

is the normal wage share.

The profit share is:

$$
1-\omega_t^N
$$

---

## 2. Leontief reproduction benchmark

The heterodox production foundation is fixed-coefficients:

$$
Y_t = \min\{A_tL_t,\ \mu^*B_tK_t\}
$$

But \(B_t\) is not primitive. It is derived from labor productivity and mechanization.

The productive-capacity benchmark is:

$$
Y_t^p = B_t^N K_t
$$

with:

$$
B_t^N = \frac{A_t}{Q_t^*}
$$

so:

$$
Y_t^p = \frac{A_t}{Q_t^*}K_t
$$

Capacity utilization is the realized gap from this benchmark:

$$
u_t = \frac{Y_t}{Y_t^p}
$$

or in logs:

$$
\ln u_t = y_t - y_t^p
$$

Utilization does not define productive capacity. It measures the non-fulfillment of the productive-capacity benchmark.

---

## 3. Mechanization-productivity frontier

Labor-productivity growth is governed by a mechanization-productivity frontier:

$$
a_t(q_t)=\lambda_0+\lambda_1q_t+\lambda_2q_t^2
$$

with:

$$
\lambda_2<0
$$

The coefficients have the following interpretation.

$$
\lambda_0
$$

is baseline labor-process productivity growth not explained by measured mechanization.

$$
\lambda_1
$$

is the first-order productivity effect of mechanization.

$$
\lambda_2
$$

is the curvature or contradiction coefficient. Since \(\lambda_2<0\), mechanization has diminishing productivity effects. It may eventually outrun the labor-productivity gains it induces.

---

## 4. Firm benchmark: cost-minimizing mechanization

The firm is not introduced as a full profit-maximizing subject. The benchmark is weaker and cleaner: the efficient firm minimizes the cost of mechanization per unit of labor-productivity gain.

Let the distributive cost per unit of mechanization be the historically given normal profit share:

$$
\pi_t^N = 1-\omega_t^N
$$

The firm solves:

$$
\min_{q_t\geq 0}
\left[
\pi_t^N q_t - a_t(q_t)
\right]
$$

or:

$$
\min_{q_t\geq 0}
\left[
(1-\omega_t^N)q_t
-
\lambda_0-\lambda_1q_t-\lambda_2q_t^2
\right]
$$

The first-order condition is:

$$
1-\omega_t^N-\lambda_1-2\lambda_2q_t^*=0
$$

so:

$$
\lambda_1+2\lambda_2q_t^*=1-\omega_t^N
$$

and:

$$
q_t^*(\omega_t^N)
=
\frac{\lambda_1-1+\omega_t^N}{-2\lambda_2}
$$

With the non-negativity constraint:

$$
q_t^*(\omega_t^N)
=
\max\left\{
0,\
\frac{\lambda_1-1+\omega_t^N}{-2\lambda_2}
\right\}
$$

The interior solution requires:

$$
\omega_t^N>1-\lambda_1
$$

Distribution enters by changing the cost-minimizing mechanization rate. A higher wage share lowers the profit-share cost term and raises the induced mechanization solution, but this does not guarantee a higher transformation elasticity.

---

## 5. Technical-mechanization corridor

The derived output-capital artifact is:

$$
b_t^N = a_t - q_t^*
$$

Substituting the mechanization frontier:

$$
b_t^N
=
\lambda_0+(\lambda_1-1)q_t^*+\lambda_2(q_t^*)^2
$$

This is the numerator of the transformation-elasticity mechanism.

If:

$$
a_t>q_t^*
$$

then:

$$
b_t^N>0
$$

and accumulation tends to expand productive capacity more than proportionally.

If:

$$
a_t=q_t^*
$$

then:

$$
b_t^N=0
$$

and productive capacity grows one-for-one with capital.

If:

$$
a_t<q_t^*
$$

then:

$$
b_t^N<0
$$

and mechanization outruns labor-productivity growth. Accumulation expands productive capacity less than proportionally.

This is the technical-mechanization corridor.

---

## 6. Normal profit-recapitalization corridor

Normal profitability is not realized profitability at \(\mu=1\).

It is profitability under smooth proportional reproduction.

Define:

$$
r_t^N = B_t^N(1-\omega_t^N)
$$

Since:

$$
B_t^N=\frac{A_t}{Q_t^*}
$$

and:

$$
\omega_t^N=\frac{c_t^{w,N}}{A_t}
$$

we get:

$$
r_t^N
=
\frac{A_t}{Q_t^*}
\left(
1-\frac{c_t^{w,N}}{A_t}
\right)
$$

so:

$$
r_t^N
=
\frac{A_t-c_t^{w,N}}{Q_t^*}
$$

Normal profitability is therefore the surplus labor-productivity margin divided by the mechanization requirement.

Now define the normal gross recapitalization ratio:

$$
\chi_t^N=\frac{I_t^N}{\Pi_t^N}
$$

This is not a simple saving propensity. It is the normal circuit-adjusted conversion of surplus into productive capital outlays.

The normal accumulation corridor is:

$$
g_{K,t}^N=\chi_t^N r_t^N-\delta_t
$$

or:

$$
g_{K,t}^N
=
\chi_t^N B_t^N(1-\omega_t^N)-\delta_t
$$

This is the normal profit-recapitalization corridor.

---

## 7. Transformation elasticity

The transformation elasticity is:

$$
\theta_t^N
=
1+
\frac{b_t^N}{g_{K,t}^N}
$$

Since:

$$
b_t^N=a_t-q_t^*
$$

and:

$$
g_{K,t}^N=\chi_t^N r_t^N-\delta_t
$$

we have:

$$
\theta_t^N
=
1+
\frac{a_t-q_t^*}
{
\chi_t^N r_t^N-\delta_t
}
$$

Using the mechanization frontier:

$$
\theta_t^N
=
1+
\frac{
\lambda_0+(\lambda_1-1)q_t^*
+\lambda_2(q_t^*)^2
}
{
\chi_t^N B_t^N(1-\omega_t^N)-\delta_t
}
$$

This is the two-corridor foundation.

The numerator is the technical-mechanization corridor.

The denominator is the normal profit-recapitalization corridor.

---

## 8. Empirical translation

The empirical specification can be written as:

$$
\theta(\omega)=\beta_1+\beta_2\omega
$$

This is a reduced-form representation of the two-corridor structure.

$$
\beta_1
$$

is the baseline transformation elasticity of accumulation into productive capacity.

It does not measure capital productivity.

It measures the average long-run capacity payoff of accumulation before the wage-share conditioning term is activated.

$$
\beta_2
$$

is the distributive-conditioning coefficient.

It captures how the wage share conditions the transformation of accumulation into productive capacity through both corridors:

$$
\omega
\rightarrow
q^*
\rightarrow
a-q^*
\rightarrow
\theta
$$

and:

$$
\omega
\rightarrow
r^N,\chi^N
\rightarrow
g_K^N
\rightarrow
\theta
$$

Thus, \(\beta_2\) does not have a universal sign.

Its sign is regime-specific.

---

## 9. Marx–Okishio interpretation

Basu’s Marx–Okishio framework implies that Marx and Okishio correspond to different closure conditions. If real wages remain fixed, viable technical change tends to raise the profit rate. If real wages rise enough, or if the wage share is institutionally stabilized, the falling-profit result can obtain.

In this framework, the Marx–Okishio logic is not tested directly.

It is translated into a regime-level interpretation of \(\beta_2\).

If:

$$
\beta_2<0
$$

then the wage-share channel behaves in Marx-side terms. Stronger labor capture, capital-using mechanization, or normal profit-circuit compression weakens the transformation of accumulation into productive capacity.

If:

$$
\beta_2>0
$$

then the wage-share channel behaves in Okishio-side terms. Wage pressure is associated with productivity-enhancing mechanization, accumulation-supporting technical change, or a regime where labor is too weak to convert productivity growth into a falling-profit tendency.

If:

$$
\beta_2\simeq 0
$$

then the two corridors may be offsetting each other, or the linear specification may be too compressed to detect the relevant threshold.

---

## 10. Regulationist hypotheses

The regime-level hypotheses are:

$$
H_1:\quad \beta_2^{Fordism}<0
$$

Fordism is interpreted as a strong-labor closure. Real wages tend to move with productivity, the wage share is relatively stabilized, and labor has institutional capacity to capture productivity gains. This corresponds to the Marx-side closure logic.

$$
H_2:\quad \beta_2^{PostFordism}>\beta_2^{Fordism}
$$

Post-Fordism is interpreted as a weak-labor closure. Wage-share stabilization weakens, real wages no longer reliably track labor productivity, and labor is less able to convert productivity growth into a falling-profit tendency.

The stronger hypothesis is:

$$
H_{2b}:\quad \beta_2^{PostFordism}>0
$$

This should be treated as an empirical possibility rather than the baseline requirement.

The safer baseline is that post-Fordism weakens or reverses the Fordist negative distributive-conditioning effect.

---

## 11. Contribution statement

This approach does not re-prove Marx–Okishio.

It operationalizes Marx–Okishio closure logic at the macro-regime level.

The empirical contribution is to estimate whether the wage-share coefficient in the transformation elasticity behaves as a Marx-side or Okishio-side distributive-conditioning effect.

The object is not the profit rate itself.

The object is the transformation of accumulation into productive capacity.

Thus, the empirical strategy identifies regime-level stagnation tendencies by asking whether distribution strengthens or weakens the capacity payoff of accumulation.

---

## Locked formulation

The estimated transformation elasticity is a reduced-form historical object generated by two corridors. The technical-mechanization corridor determines whether labor-productivity growth outstrips mechanization. The normal profit-recapitalization corridor determines whether normal surplus is converted into productive capital outlays under smooth proportional reproduction. The wage-share coefficient \(\beta_2\) captures the regime-specific balance between these corridors. A negative \(\beta_2\) indicates Marx-side dominance; a positive \(\beta_2\) indicates Okishio-side dominance; and a regime shift in \(\beta_2\) operationalizes the historical movement from strong-labor to weak-labor closure conditions.