# Notebook 5: Parameter Recovery and θ̂^CL(ω_t, φ_t) Identification
## From Estimated (A, B, C) to the Structural Transformation Elasticity

**Prerequisite:** NB-04 (CLS estimation complete, CV1 coefficients in hand)
**Output files:** `stage2_structural_params.csv`, `stage2_theta_CL_series.csv`

---

## 5.1 The central identification object

$$\boxed{\hat{\theta}^{CL}(\omega_t, \phi_t) = \hat{\theta}_0 + \hat{\psi}\,\phi_t + \hat{\theta}_2\,\omega_t\phi_t}$$

This is the empirical counterpart of equation (20) in §3.5:

$$\theta^{CL}(\omega, \phi, \lambda) = \bar{\psi}(\phi) + \frac{\pi^{eff}}{2}, \qquad \pi^{eff} \equiv (1-\omega) - \lambda\xi\phi$$

In the VECM identification, $\lambda$ is not estimated as a free parameter — it
enters through the regime structure. The frontier cointegrating vector identifies
$\theta^{CL}$ at the average $\lambda$ within each regime. The regime-specific
content of $\lambda$ is recovered from $\alpha^{(2)} - \alpha^{(1)}$, not from
$\hat{\theta}$ directly.

---

## 5.2 Exact parameter recovery algebra

The reparameterized CV1 (from Johansen MLE, y-normalized) is:

$$y_t = \kappa_1 + A\,k_t^{CL} + B\,c_t + C\,(\omega_t c_t) + ECT_{\theta,t}$$

Substituting $k^{NR} = (k^{CL} - c_t)/2$ and $k^{ME} = (k^{CL}+c_t)/2$
(exact in the log-approximation where $k^{CL} \approx (k^{NR}+k^{ME})$):

$$y_t = \theta_0 k^{NR} + \psi k^{ME} + \theta_2\omega_t k^{ME}$$
$$= \theta_0\!\left(\frac{k^{CL}-c_t}{2}\right) + (\psi + \theta_2\omega_t)\!\left(\frac{k^{CL}+c_t}{2}\right)$$
$$= \underbrace{\frac{\theta_0+\psi}{2}}_{A} k^{CL} + \underbrace{\frac{\psi-\theta_0}{2}}_{B} c_t + \underbrace{\frac{\theta_2}{2}}_{C}\omega_t c_t$$

**Therefore:**

$$\hat{\theta}_0 = \hat{A} - \hat{B}$$

$$\hat{\psi} = \hat{A} + \hat{B}$$

$$\hat{\theta}_2 = 2\hat{C}$$

These are exact identities. No approximation is involved.

---

## 5.3 Sign restrictions and economic content

| Parameter | Expected sign | Economic content |
|-----------|--------------|-----------------|
| $\hat{\theta}_0 = \hat{A}-\hat{B}$ | $> 0$ | Infrastructure contributes positively to productive capacity |
| $\hat{\psi} = \hat{A}+\hat{B}$ | $> 0$ | Machinery carries positive productive capacity premium |
| $\hat{\psi} - \hat{\theta}_0 = 2\hat{B}$ | $> 0$ | **Kaldor hypothesis**: machinery elasticity exceeds infrastructure elasticity ($\xi^{ME} \approx 0.92$–$0.94$) |
| $\hat{\theta}_2 = 2\hat{C}$ | $< 0$ | Higher wage share compresses the machinery-composition channel: distributional squeeze reduces the effective profit available for mechanization ($\pi^{eff} = (1-\omega)-\lambda\xi\phi$) |

**Key check:** The machinery premium $\hat{\psi} - \hat{\theta}_0 = 2\hat{B}$
must be positive for the Kaldor hypothesis to hold empirically. This is the
content of §3.5.1: $\psi^{ME} > \psi^{NR}$ implies that embodied technical
change is higher in imported machinery than in domestic infrastructure.

---

## 5.4 The post-estimation formula: connecting to φ_t

The VECM uses $c_t = \ln(K^{ME}/K^{NR})$ — the log-composition ratio.
The post-estimation formula requires $\phi_t = K^{ME}/(K^{NR}+K^{ME})$
— the levels composition share.

The bridge between $c_t$ and $\phi_t$:
$$c_t = \ln\!\left(\frac{\phi_t}{1-\phi_t}\right) \implies \phi_t = \frac{e^{c_t}}{1+e^{c_t}}$$

The post-estimation formula does not use $c_t$ — it uses $\phi_t$ directly:

$$\hat{\theta}^{CL}(\omega_t, \phi_t) = \hat{\theta}_0 + \hat{\psi}\,\phi_t + \hat{\theta}_2\,\omega_t\phi_t$$

This uses $\phi_t$ (column `phi` in the panel), which is already constructed as
$K^{ME}/(K^{NR}+K^{ME})$ in levels. Do not substitute $c_t$ into this formula.

---

## 5.5 Time-varying properties of θ̂^CL

The transformation elasticity varies through time via two channels:

1. **Composition channel**: as $\phi_t$ rises (machinery share increases), $\hat{\theta}^{CL}$
   shifts because $\hat{\psi} > 0$. Higher machinery share → higher productive capacity
   elasticity per unit of capital.

2. **Distribution-composition interaction**: as $\omega_t$ rises (wage share increases),
   $\hat{\theta}^{CL}$ falls via $\hat{\theta}_2\omega_t\phi_t < 0$. Higher wages compress
   the machinery-intensive mechanization path — the distributional content of the BoP constraint.

**Period-level narrative:**

- **ISI (1940–1972):** $\phi_t$ rising as machinery accumulation accelerates; $\omega_t$
  moderate and rising under Fordist-era wage compression. $\hat{\theta}^{CL}$ expected
  to be below 1 (sub-Harrodian: productive capacity grows slower than capital stock).

- **Crisis (1973–1982):** $\phi_t$ may stabilize or fall as mechanization is interrupted;
  $\omega_t$ collapses under wage repression. Conflicting forces on $\hat{\theta}^{CL}$.
  The BoP constraint is binding ($\lambda > 0$), which the CV1 captures in the average
  $\hat{\theta}^{CL}$ — the frontier is compressed below the counterfactual unconstrained path.

- **Neoliberal (1983–2024):** Import liberalization changes the composition trajectory;
  $\omega_t$ remains suppressed. $\hat{\theta}^{CL}$ expected to shift to super-Harrodian
  range ($> 1$) if productive capacity outpaces realized output.

---

## 5.6 Harrodian knife-edge in the peripheral system

Setting $\hat{\theta}^{CL}(\omega_t, \phi_t) = 1$ and solving for $\phi$:

$$\phi_H(\omega) = \frac{1 - \hat{\theta}_0}{\hat{\psi} + \hat{\theta}_2\omega}$$

This is the composition share at which the productive frontier grows at the same
rate as the capital stock, for a given wage share $\omega$. The knife-edge is a
surface in $(\omega, \phi)$ space — not a single point as in the US case where
$\theta$ depends only on $\omega$.

At the sample mean $\bar{\omega}$:
$$\phi_H(\bar{\omega}) = \frac{1-\hat{\theta}_0}{\hat{\psi}+\hat{\theta}_2\bar{\omega}}$$

If $\phi_H(\bar{\omega}) \in [\phi_{\min}, \phi_{\max}]$, the sub/super-Harrodian
regime switch is empirically operative in the Chilean sample — analogous to the
US knife-edge at $\omega_H = 0.617$.

---

## 5.7 Output: θ̂^CL series

```r
# From structural parameter recovery:
theta_CL_t <- theta_0_hat + psi_hat * df$phi + theta_2_hat * df$omega * df$phi

# Save
write_csv(
  tibble(year=df$year, phi=df$phi, omega=df$omega, theta_CL=theta_CL_t),
  "output/stage_a/Chile/csv/stage2_theta_CL_series.csv"
)
```

The `stage2_theta_CL_series.csv` file is the central empirical deliverable of
Stage 2. It contains the time-varying transformation elasticity that:
1. Feeds into the productive capacity growth closure
2. Determines the $\hat{\mu}^{CL}$ series via the pin-year normalization
3. Enters the cross-country comparison with the US $\hat{\theta}^{US}(\omega_t)$

---

*NB-05 | 2026-04-07 | Next: NB-06 (μ̂^CL construction and results)*
