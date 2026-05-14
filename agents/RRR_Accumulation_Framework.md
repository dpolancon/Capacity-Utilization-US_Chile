# Integrated Framework: Behavioral Accumulation Law Nested in a Reduced-Rank Identification Strategy for Capacity Utilization

## 0. Purpose

This notebook formalizes a single conceptual framework with two nested layers:

1. a **structural identification layer** that recovers latent capacity utilization through reduced-rank / cointegration logic; and  
2. a **behavioral accumulation layer** that explains realized investment as a recapitalization response to profitability once utilization and productive capacity have been structurally recovered.

The methodological order is strict:

\[
\text{RRR/CVAR identifies } \mu_t
\quad \Longrightarrow \quad
\text{ARDL models } \iota_t \equiv I_t/K_t.
\]

Thus, the investment function is **nested within** the broader identification strategy. It does not identify utilization; it uses the recovered utilization object.

---

## 1. Structural primitives

Let

\[
y_t \equiv \ln Y_t, \qquad k_t \equiv \ln K_t.
\]

Output is decomposed into productive capacity and utilization:

\[
Y_t = \mu_t Y_t^p,
\qquad
y_t = y_t^p + \ln \mu_t.
\]

Capital productivity at normal capacity is

\[
B_t \equiv \frac{Y_t^p}{K_t},
\qquad
\ln B_t = y_t^p - k_t.
\]

The long-run transformation of capital stock into productive capacity is governed by the unbalanced-growth closure:

\[
y_t^p = \theta_t k_t,
\]

or, in regime language,

\[
y_t^p = \theta(\Lambda) k_t.
\]

### Proposition 1. Confinement identity

Given the decomposition above,

\[
\ln \mu_t = y_t - \theta_t k_t.
\]

This is the core identification object: utilization is recovered as the deviation of realized output from the productive-capacity manifold.

---

## 2. Distribution-conditioned long-run slope

A distributive micro-foundation can be introduced through the profit share. Let exploitation map into the profit share as

\[
\pi(e_t) = \frac{e_t}{1+e_t}.
\]

Then the long-run capacity relation can be written empirically as

\[
y_t = c + \beta_1 k_t + \beta_2(\pi_t k_t) + \xi_t,
\qquad
\xi_t \equiv \ln \mu_t.
\]

Hence the endogenous long-run transformation elasticity is

\[
\theta_t = \beta_1 + \beta_2 \pi_t.
\]

### Proposition 2. Rank-1 identification equation

If the residual from

\[
y_t - c - \beta_1 k_t - \beta_2(\pi_t k_t)
\]

is stationary, then

\[
\widehat{\ln \mu_t} = y_t - \hat c - \hat\beta_1 k_t - \hat\beta_2(\pi_t k_t)
\]

is the recovered latent utilization object.

This is the dissertation's primary identification problem.

---

## 3. Why reduced rank comes first

The reduced-rank / cointegration strategy answers the structural question:

> What is capacity utilization, given a long-run reproduction structure under unbalanced growth?

At rank 1, the maintained interpretation is

\[
\beta' Z_t = \ln \mu_t \sim I(0).
\]

So utilization is **rescued by confinement**: it is not directly observed, but recovered as the bounded deviation from the long-run manifold.

An ARDL investment equation cannot perform that identification. It can only describe how observed accumulation responds to utilization once utilization has already been recovered or proxied.

---

## 4. Higher-rank motivation: reserve-army, conflict, and learning

The rank-1 benchmark is analytically useful but restrictive, because it risks forcing too much cyclical and distributive content into a single stationary utilization residual.

The reserve-army dimension is therefore necessary, not as a crude substitute for utilization, but as the mechanism that:

1. separates **long-run distribution** embedded in \(\theta\) from **short-run distributive conflict**;
2. governs the admissible cyclical motion of utilization; and
3. introduces the demand-led learning channel.

A stylized short-run propagation block is:

\[
a_t = a(q_t^*) + \lambda \hat v_t,
\]

\[
\hat \mu_t = \kappa \hat v_t,
\]

\[
\hat \omega_t = \gamma_0 + \gamma_1 v_t.
\]

Interpretation:

- the long run is governed by \(\theta(\pi,\Lambda)\);
- the short run is governed by reserve-army conflict and learning;
- utilization is the bridge between those two layers.

The exact higher-rank \(\beta\)-space remains open until the full dynamic closure is completed, but the conceptual role of the reserve army is fixed.

---

## 5. Derived structural objects after utilization identification

Once \(\widehat{\mu_t}\) is recovered, the other structural magnitudes become observable by construction.

### Definition 1. Recovered productive capacity

\[
\hat y_t^p = y_t - \widehat{\ln \mu_t}.
\]

### Definition 2. Recovered capital productivity at normal capacity

\[
\widehat{\ln B_t} = \hat y_t^p - k_t,
\qquad
\hat B_t = \exp(\hat y_t^p - k_t).
\]

This is essential because the behavioral accumulation law requires \(B_t\), and \(B_t\) is only cleanly available once the utilization-identification problem has been solved.

---

## 6. Accounting law of capital accumulation

Define the gross accumulation rate as

\[
\iota_t \equiv \frac{I_t}{K_t}.
\]

The accounting decomposition of accumulation is

\[
\iota_t = \phi_t \mu_t B_t,
\qquad
\phi_t \equiv \frac{I_t}{Y_t}.
\]

Since

\[
\phi_t \mu_t = \frac{I_t}{Y_t} \frac{Y_t}{Y_t^p} = \frac{I_t}{Y_t^p} \equiv \phi_t^p,
\]

we obtain the equivalent form

\[
\iota_t = \phi_t^p B_t,
\qquad
\phi_t^p \equiv \frac{I_t}{Y_t^p}.
\]

A second recapitalization ratio is

\[
\beta_t \equiv \frac{I_t}{\Pi_t},
\]

so that, since

\[
\pi_t \equiv \frac{\Pi_t}{Y_t},
\qquad
r_t \equiv \frac{\Pi_t}{K_t} = \pi_t \mu_t B_t,
\]

we also have

\[
\phi_t = \beta_t \pi_t,
\]

and therefore

\[
\boxed{
\iota_t = \beta_t \pi_t \mu_t B_t = \beta_t r_t.
}
\]

### Interpretation

There are two recapitalization lenses:

- \(\beta_t = I_t/\Pi_t\): funding out of profits;
- \(\phi_t^p = I_t/Y_t^p\): claim of investment on productive-capacity output.

They are not rivals. They are linked accounting representations of the same accumulation law.

---

## 7. Behavioral accumulation law

The accounting identity above does not impose that recapitalization is constant. That is the behavioral margin.

Take logs:

\[
\ln \iota_t = \ln \beta_t + \ln \pi_t + \ln \mu_t + \ln B_t.
\]

If recapitalization were constant, \(\ln \beta_t\) would be absorbed into the intercept and each long-run elasticity would be unity.

Instead, let recapitalization respond behaviorally to the same channels:

\[
\ln \beta_t = \eta_0 + \eta_1 \ln \pi_t + \eta_2 \ln \mu_t + \eta_3 \ln B_t.
\]

Substituting gives the long-run behavioral accumulation law:

\[
\boxed{
\ln \iota_t = c + b_1 \ln \pi_t + b_2 \ln \mu_t + b_3 \ln B_t + \varepsilon_t
}
\]

with

\[
b_j = 1 + \eta_j.
\]

### Proposition 3. Dual interpretation of the coefficients

Each coefficient has both an accounting and a behavioral meaning:

| Coefficient | Accounting reading | Behavioral reading |
|---|---|---|
| \(b_1\) | Profit-share elasticity of accumulation | \(\eta_1 = b_1-1\): recapitalization response to distribution |
| \(b_2\) | Utilization elasticity of accumulation | \(\eta_2 = b_2-1\): recapitalization response to demand |
| \(b_3\) | Capital-productivity elasticity of accumulation | \(\eta_3 = b_3-1\): recapitalization response to structural conditions |

The deviation from unity is the behavioral content.

---

## 8. Why ARDL belongs here

The behavioral law

\[
\ln \iota_t = c + b_1 \ln \pi_t + b_2 \ln \mu_t + b_3 \ln B_t + \varepsilon_t
\]

is the natural place for ARDL estimation.

This belongs to the **investment-function track**, not to the primary identification of utilization.

Hence the sequential empirical logic is:

### Stage A. Structural identification

Estimate the reduced-rank / cointegration relation and recover

\[
\widehat{\mu_t}, \qquad \widehat{B_t}.
\]

### Stage B. Behavioral estimation

Estimate the accumulation law conditionally:

\[
\ln \iota_t = c + b_1 \ln \pi_t + b_2 \ln \widehat{\mu_t} + b_3 \ln \widehat{B_t} + \varepsilon_t
\]

using ARDL or a closely related single-equation long-run framework.

So the ARDL is a **conditional behavioral module nested inside** the structural-identification architecture.

---

## 9. Nested restriction menu

The behavioral coefficients generate a hierarchy of accumulation closures.

### Restriction 1. Cambridge closure

\[
b_1 = b_2 = b_3 = 1.
\]

Recapitalization is constant and accumulation follows the accounting decomposition mechanically.

### Restriction 2. Bhaduri-Marglin-type intermediate closure

\[
b_1, b_2 \text{ free},
\qquad
b_3 = 1.
\]

Recapitalization responds to distribution and demand, but not to capital productivity.

### Restriction 3. Full structural model

\[
b_1, b_2, b_3 \text{ all free}.
\]

Recapitalization responds to all three channels: distribution, utilization, and capital productivity.

The ARDL block therefore tests which behavioral closure is supported **conditional on the structurally identified utilization object**.

---

## 10. Unbalanced growth and capital productivity dynamics

The growth of productive capacity obeys

\[
y_t^p = \theta(\Lambda) k_t.
\]

Hence capital-productivity growth is

\[
b_t \equiv y_t^p - k_t = (\theta(\Lambda)-1)k_t.
\]

So \(\theta\neq 1\) implies that capital productivity is not constant. Under unbalanced growth, \(B_t\) carries the cumulated structural effect of the regime.

This matters behaviorally because the coefficient \(b_3\) tells us whether capitalists are:

- blind to the structural transformation of capital productivity (\(b_3=1\));
- amplifying that tendency (\(b_3>1\)); or
- partially offsetting it (\(b_3<1\)).

Thus, the behavioral accumulation law gives the Harrodian/unbalanced-growth term an empirical foothold.

---

## 11. Finance gap and long-run openness

Once full-capacity utilization is lifted, the finance gap need not vanish even in the long run.

Define

\[
F_t \equiv I_t - S_t.
\]

Do **not** impose

\[
I_t = S_t
\]

as a maintained long-run identification assumption.

Instead, treat it as a nested special case.

In this framework, long-run openness on the financing side is absorbed by the recapitalization process \(\beta_t\). A persistent finance gap simply means recapitalization is not reducible to a fixed saving propensity.

So the framework remains:

- disciplined on the utilization-identification side;
- open on the financing side.

---

## 12. Full integrated architecture

The complete conceptual system can be summarized as follows.

### A. Structural reproduction block

\[
y_t = y_t^p + \ln \mu_t,
\qquad
y_t^p = \theta_t k_t,
\qquad
\theta_t = \beta_1 + \beta_2 \pi_t.
\]

### B. Latent-utilization identification block

\[
\ln \mu_t = y_t - c - \beta_1 k_t - \beta_2(\pi_t k_t),
\]

estimated by reduced-rank / cointegration methods.

### C. Derived structural block

\[
\hat y_t^p = y_t - \widehat{\ln \mu_t},
\qquad
\widehat{\ln B_t} = \hat y_t^p - k_t.
\]

### D. Behavioral accumulation block

\[
\iota_t = \beta_t \pi_t \mu_t B_t,
\]

or, in estimable form,

\[
\ln \iota_t = c + b_1 \ln \pi_t + b_2 \ln \mu_t + b_3 \ln B_t + \varepsilon_t.
\]

### E. Short-run social-dynamic block

\[
a_t = a(q_t^*) + \lambda \hat v_t,
\qquad
\hat \mu_t = \kappa \hat v_t,
\qquad
\hat \omega_t = \gamma_0 + \gamma_1 v_t.
\]

This last block governs conflict, learning, and cyclical adjustment. It does not substitute for the long-run identification relation.

---

## 13. Empirical roadmap

### Step 1. Estimate the long-run confinement relation

Estimate the rank-1 baseline:

\[
y_t = c + \beta_1 k_t + \beta_2(\pi_t k_t) + \xi_t,
\qquad
\xi_t \sim I(0).
\]

Recover:

\[
\widehat{\ln \mu_t}.
\]

### Step 2. Construct productive capacity and capital productivity

\[
\hat y_t^p = y_t - \widehat{\ln \mu_t},
\qquad
\widehat{\ln B_t} = \hat y_t^p - k_t.
\]

### Step 3. Estimate the behavioral accumulation law

Using observed accumulation and recovered structural objects, estimate:

\[
\ln \iota_t = c + b_1 \ln \pi_t + b_2 \ln \widehat{\mu_t} + b_3 \ln \widehat{B_t} + \varepsilon_t.
\]

### Step 4. Test nested closures

Test:

- Cambridge: \(b_1=b_2=b_3=1\)
- Bhaduri-Marglin-type: \(b_3=1\)
- Full model: all \(b_j\) free

### Step 5. Extend to higher-rank dynamics

Once the baseline utilization object is recovered and the behavioral law is estimated, move to higher-dimensional systems that incorporate reserve-army, conflict, and learning more explicitly.

---

## 14. One-line formulation

> Capacity utilization is identified as a latent confinement object of the long-run reproduction structure, while the investment function is estimated separately as a behavioral recapitalization law conditional on the recovered utilization and productivity objects.

That is the unified framework.

