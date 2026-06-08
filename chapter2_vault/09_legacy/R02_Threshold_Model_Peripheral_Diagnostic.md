---
type: note
status: active
layer: analytical_foundation
design_role: identification_rule
scope: chapter2_peripheral_extension
related_to:
  - N01_Two_Corridor_Transformation_Elasticity
  - R01_Marx_Okishio_Regime_Diagnostic_Guardrail
  - N02_Peripheral_Mechanization_Constraint
created: 2026-05-05
---

# Threshold model as peripheral diagnostic

## Core rule

The threshold model is not an econometric decoration.

It operationalizes the theoretical claim that the transformation elasticity changes when the dominant corridor changes.

The object is:

$$
\theta_t
$$

the transformation elasticity of accumulation into productive capacity.

The threshold model asks:

> When does the transformation of accumulation into productive capacity switch between corridor configurations?

---

## 1. Linear baseline

The baseline empirical specification is:

$$
y_t
=
c+\beta_1 k_t+\beta_2(\omega_t k_t)+\varepsilon_t
$$

which implies:

$$
\theta(\omega_t)=\beta_1+\beta_2\omega_t
$$

Here:

$$
\beta_1
$$

is the baseline transformation elasticity.

$$
\beta_2
$$

is the distributive-conditioning coefficient.

A negative \(\beta_2\) indicates Marx-side dominance.

A positive \(\beta_2\) indicates Okishio-side dominance.

But the linear model only gives the average historical effect. It does not identify when the corridor changes.

---

## 2. Why a threshold model is needed

The theory implies that the wage-share effect is not globally stable because the wage share affects two corridors.

First, the technical-mechanization corridor:

$$
\omega_t
\rightarrow
q_t^*
\rightarrow
a_t-q_t^*
\rightarrow
\theta_t
$$

Second, the normal profit-recapitalization corridor:

$$
\omega_t
\rightarrow
r_t^N,\chi_t^N
\rightarrow
g_{K,t}^N
\rightarrow
\theta_t
$$

In the periphery, a third object modifies the mechanization path:

$$
\Lambda_t\varphi_t
$$

where:

$$
\Lambda_t
$$

is the shadow cost of foreign exchange, and:

$$
\varphi_t
$$

is the machinery share of accumulation.

The threshold model identifies when the external mechanization wedge becomes binding.

---

## 3. Center threshold interpretation

For the center, the threshold model can be used to identify Marx-side and Okishio-side distributive closures:

$$
\theta_t
=
\begin{cases}
\beta_1^M+\beta_2^M\omega_t, & s_t\leq \gamma \\
\beta_1^O+\beta_2^O\omega_t, & s_t> \gamma
\end{cases}
$$

where:

$$
s_t
$$

is a regime or closure indicator.

Possible candidates include:

- labor strength;
- wage-share stability;
- real-wage capture of labor productivity;
- Fordist/post-Fordist periodization.

The interpretation is:

$$
\beta_2^M<0
$$

indicates Marx-side dominance.

$$
\beta_2^O\geq 0
$$

indicates Okishio-side or weak-labor dominance.

This is a regime-level operationalization of Marx–Okishio closure logic.

It is not a direct test of the Marx–Okishio theorem.

---

## 4. Peripheral threshold interpretation

For the periphery, the threshold variable should capture the external mechanization constraint.

Define:

$$
\mathcal{E}_t=\Lambda_t\varphi_t
$$

where:

$$
\varphi_t=\frac{I_t^M}{I_t^A}
$$

is the machinery share of accumulation.

The threshold model is:

$$
\theta_t
=
\begin{cases}
\beta_1^L+\beta_2^L\omega_t, & \mathcal{E}_t\leq \gamma \\
\beta_1^H+\beta_2^H\omega_t, & \mathcal{E}_t> \gamma
\end{cases}
$$

Low external constraint:

$$
\mathcal{E}_t\leq \gamma
$$

means machinery imports do not strongly restrict mechanization.

High external constraint:

$$
\mathcal{E}_t>\gamma
$$

means imported machinery becomes a binding condition on capacity formation.

The expected peripheral result is not mechanically about the sign of \(\beta_2\). It is about whether the wage-share coefficient changes once the external mechanization constraint binds.

---

## 5. Estimable equation

The peripheral long-run equation can be written as:

$$
y_t
=
c+
\beta_1 k_t
+
\beta_2(\omega_t k_t)
+
\beta_3(\mathcal{E}_t k_t)
+
\varepsilon_t
$$

with:

$$
\theta(\omega_t,\mathcal{E}_t)
=
\beta_1+\beta_2\omega_t+\beta_3\mathcal{E}_t
$$

The expected interpretation is:

$$
\beta_3<0
$$

meaning that the imported-machinery constraint weakens the capacity payoff of accumulation.

The threshold version allows the coefficients to change across low-constraint and high-constraint regimes:

$$
y_t
=
c_j+
\beta_{1j} k_t
+
\beta_{2j}(\omega_t k_t)
+
\varepsilon_{tj},
\qquad
j\in\{L,H\}
$$

where regime membership is determined by:

$$
\mathcal{E}_t\leq \gamma
\quad
\text{or}
\quad
\mathcal{E}_t>\gamma
$$

---

## 6. Empirical proxies

If \(\Lambda_t\) is not directly observed, the external constraint can be proxied through:

- real exchange-rate stress;
- reserve adequacy;
- imports relative to reserves;
- capital-goods import capacity;
- terms-of-trade pressure;
- import compression episodes;
- current-account or balance-of-payments stress.

If \(I_t^M\) is available, use:

$$
\varphi_t=\frac{I_t^M}{I_t^A}
$$

If \(I_t^M\) is not available, use machinery/equipment investment or capital-goods imports as the closest empirical proxy.

---

## 7. Contribution statement

The threshold model gives the peripheral extension its empirical form.

It identifies whether the transformation of accumulation into productive capacity changes when imported machinery becomes externally constrained.

The theoretical claim is:

> In the periphery, the transformation elasticity is not only distribution-sensitive. It is externally fragile.

The empirical question is:

> Does the wage-share conditioning of productive-capacity formation change when the foreign-exchange constraint on machinery accumulation becomes binding?

---

## Guardrail

Do not write:

> The threshold model tests the Marx–Okishio theorem.

Write instead:

> The threshold model estimates regime switches in the Marx–Okishio closure logic as they appear in the transformation of accumulation into productive capacity.

For the peripheral case, write:

> The threshold model identifies when the imported-machinery constraint changes the capacity payoff of accumulation.

---

## Locked formulation

The threshold model is justified because the transformation elasticity is corridor-dependent. In the center, thresholds separate Marx-side and Okishio-side distributive closures. In the periphery, thresholds identify when the external mechanization wedge binds. The threshold model therefore turns the peripheral extension into an empirical diagnostic: it tests whether imported machinery and foreign-exchange pressure alter the long-run transformation of accumulation into productive capacity.