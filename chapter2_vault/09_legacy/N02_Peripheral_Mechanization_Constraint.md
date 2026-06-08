---
type: note
status: active
layer: superseded
design_role: object_definition
scope: chapter2_peripheral_extension
related_to:
  - N01_Two_Corridor_Transformation_Elasticity
  - R01_Marx_Okishio_Regime_Diagnostic_Guardrail
created: 2026-05-05
---

# Peripheral mechanization constraint

## Core claim

The Marx–Okishio problem can be translated into a mechanization-viability problem.

The question is not only whether technical change raises or lowers profitability. The question is:

> Under what distributive and external conditions does mechanization remain a viable route for transforming accumulation into productive capacity?

In the center, mechanization is governed mainly by distribution, normal profitability, and the normal recapitalization corridor.

In the periphery, mechanization is additionally constrained by the foreign-exchange cost of imported machinery.

---

## 1. Mechanization sign

Notation lock:

$$
Q_t=\frac{K_t}{L_t}
$$

is the mechanization ratio.

$$
q_t=\Delta \ln Q_t
$$

is the mechanization sign / mechanization growth variable.

The model uses \(q_t\), not \(\hat q_t\), as the mechanization sign.

---

## 2. Accumulation demand must be disaggregated

Accumulation demand is the only component of demand that directly expands productive capacity.

But not all accumulation demand directly drives mechanization.

Disaggregate accumulation demand as:

$$
I_t^A = I_t^M + I_t^O
$$

where:

$$
I_t^M
$$

is machinery/equipment accumulation, and:

$$
I_t^O
$$

is other accumulation: structures, construction, inventories, infrastructure, and non-mechanizing fixed capital.

Define the machinery share of accumulation:

$$
\varphi_t=\frac{I_t^M}{I_t^A}
$$

Total accumulation expands the capital stock:

$$
I_t^A \rightarrow g_{K,t}
$$

but machinery accumulation drives mechanization:

$$
I_t^M \rightarrow q_t
$$

This distinction is essential. The peripheral constraint binds most directly on the mechanizing component of accumulation.

---

## 3. Mechanization-productivity frontier

Labor-productivity growth is generated along a concave mechanization-productivity frontier:

$$
a_t(q_t)=\lambda_0+\lambda_1q_t+\lambda_2q_t^2
$$

with:

$$
\lambda_1>0,\qquad \lambda_2<0
$$

where:

$$
a_t=\Delta\ln A_t
$$

is labor-productivity growth.

The coefficients are interpreted as follows:

$$
\lambda_0
$$

captures baseline labor-process productivity growth not explained by measured mechanization.

$$
\lambda_1
$$

captures the first-order productivity effect of mechanization.

$$
\lambda_2<0
$$

captures the curvature or contradiction of mechanization: mechanization raises labor productivity, but with diminishing effects.

---

## 4. Center benchmark

Let the distributive cost per unit of mechanization be the normal profit share:

$$
m_t^C=1-\omega_t^N
$$

The firm solves:

$$
\min_{q_t\geq0}
\left[
m_t^Cq_t-a_t(q_t)
\right]
$$

The first-order condition is:

$$
m_t^C-\lambda_1-2\lambda_2q_t^{C,*}=0
$$

so:

$$
q_t^{C,*}
=
\max\left\{
0,\
\frac{\lambda_1-m_t^C}{-2\lambda_2}
\right\}
$$

or:

$$
q_t^{C,*}
=
\max\left\{
0,\
\frac{\lambda_1-(1-\omega_t^N)}{-2\lambda_2}
\right\}
$$

Mechanization is admissible only if:

$$
\lambda_1>1-\omega_t^N
$$

Distribution enters by changing the cost-minimizing mechanization path.

---

## 5. Peripheral extension

In the periphery, machinery is imported.

Imported capital-goods demand is tied to the machinery component of accumulation:

$$
M_t^K=I_t^M
$$

under the simplifying assumption that machinery is fully imported.

Let:

$$
\Lambda_t
$$

be the shadow cost of foreign exchange.

Let:

$$
\varphi_t
$$

be the machinery share of accumulation.

Then the external mechanization wedge is:

$$
\Lambda_t\varphi_t
$$

The peripheral cost per unit of mechanization is:

$$
m_t^P
=
(1-\omega_t^N)+\Lambda_t\varphi_t
$$

The peripheral firm benchmark is:

$$
\min_{q_t\geq0}
\left[
m_t^Pq_t-a_t(q_t)
\right]
$$

so:

$$
q_t^{P,*}
=
\max\left\{
0,\
\frac{\lambda_1-m_t^P}{-2\lambda_2}
\right\}
$$

or:

$$
q_t^{P,*}
=
\max\left\{
0,\
\frac{
\lambda_1-(1-\omega_t^N)-\Lambda_t\varphi_t
}
{-2\lambda_2}
\right\}
$$

The external constraint lowers the admissible mechanization path.

---

## 6. Link to the two-corridor framework

The transformation elasticity is:

$$
\theta_t^N
=
1+
\frac{a_t-q_t^*}{g_{K,t}^N}
$$

The technical-mechanization corridor is:

$$
a_t-q_t^*
=
\lambda_0+(\lambda_1-1)q_t^*
+\lambda_2(q_t^*)^2
$$

The normal profit-recapitalization corridor is:

$$
g_{K,t}^N
=
\chi_t^N r_t^N-\delta_t
$$

The peripheral extension modifies the technical-mechanization corridor by replacing the center mechanization path with the peripheral mechanization path:

$$
q_t^*=q_t^{P,*}
$$

It may also modify the normal recapitalization corridor because the conversion of surplus into productive capital outlays depends on access to imported machinery:

$$
\chi_t^{N,P}<\chi_t^{N,C}
$$

when the external constraint binds.

Therefore:

$$
\theta_t^{N,P}
=
1+
\frac{
\lambda_0+(\lambda_1-1)q_t^{P,*}
+\lambda_2(q_t^{P,*})^2
}
{
\chi_t^{N,P}r_t^N-\delta_t
}
$$

---

## 7. Kaldor-Chile bridge

Kaldor’s Chile analysis supports the peripheral extension.

The Chilean problem was not simply insufficient domestic saving. Investment had a high import content because machinery and equipment depended heavily on imported capital goods. Raising the investment ratio therefore required additional import capacity.

This means that mechanization in Chile was not only a question of domestic distribution or profitability. It was also mediated by the balance-of-payments constraint.

The peripheral mechanism is:

$$
\text{accumulation demand}
\rightarrow
\text{machinery accumulation}
\rightarrow
\text{imported machinery demand}
\rightarrow
\text{foreign-exchange constraint}
\rightarrow
q_t^{P,*}
\rightarrow
\text{productive-capacity growth}
$$

---

## Locked formulation

The peripheral extension adds an external mechanization wedge to the two-corridor framework.

In the center, mechanization is conditioned by distribution and normal profitability.

In the periphery, mechanization is additionally conditioned by the foreign-exchange cost of imported machinery.

The external constraint can weaken the transformation of accumulation into productive capacity even when total accumulation continues, because the mechanizing component of accumulation depends on imported machinery.