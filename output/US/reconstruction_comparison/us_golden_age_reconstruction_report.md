# Capacity Path Reconstruction & Comparison (Golden Age Case Study: 1945–1973)

This report compares the reconstructed potential output ($\hat{y}^p_t$) and latent capacity utilization ($\mu_t$) paths derived from two distinct econometric models estimated via FM-OLS over the post-war Golden Age:
1. **Specification B (Composition-Mediated):** Separates structures scale ($K^{NRC}$) and composition ($\tau = K^{ME}/K^{NRC}$) with distribution conditioning. Normalized to $\mu_{1973} = 1.0$. **Theoretical Correction (A03 Growth Law):** Productive capacity output $y^p_t$ is reconstructed by integrating the growth rate identity of capital stocks using time-varying elasticities:
   $$ \Delta y^p_t = \theta^{NRC}_t \Delta k^{NRC}_t + \theta^{ME}_t \Delta k^{ME}_t $$
   where $\theta^{ME}_t = \psi + \lambda \tilde{\omega}_t$ and $\theta^{NRC}_t = \theta - \theta^{ME}_t$. This series is anchored at $y^p_{1973} = y_{1973}$.
2. **True Shaikh-Style Model:** Regresses output directly on total private capital stock ($K_{Kcap} = K^{ME} + K^{NRC}$) only, with **no** distributive or interaction terms. Normalized around the average residual (mean-normalized in logs such that the geometric mean is 1.0).

---

## 1. Estimated Equations (FM-OLS)

### Specification B (Composition-Mediated):
$$ \Delta y_{t, B}^p = (0.2378 - \theta^{ME}_t) \Delta k^{NRC}_t + \theta^{ME}_t \Delta k^{ME}_t $$
where the time-varying machinery composition elasticity is:
$$ \theta^{ME}_t = 0.3121 - 1.0294 (\tilde{\tau}_t \cdot \tilde{\omega}_t)_{orth} $$
*(Note: $\tilde{\tau}_t \cdot \tilde{\omega}_t$ is the interaction term. The direct wage-share realization control is excluded from the capacity growth identity).*

### True Shaikh-Style Model:
$$ y_{t, A}^p = 14.4669 + 0.9099 \tilde{k}^{Kcap}_t $$

---

## 2. Path Comparison Metrics

The reconstructed series are saved to:
[us_golden_age_reconstructed_paths.csv](us_golden_age_reconstructed_paths.csv)

| Metric | Specification B (Composition-Mediated) | True Shaikh-Style Model |
| :--- | :---: | :---: |
| **Correlation ($\rho_{A,B}$)** | \multicolumn{2}{c|}{**-0.2459** (Moderate negative correlation)} |
| **Mean Utilization ($\mu$)** | **1.1374** | **1.0040** |
| **Standard Deviation ($\sigma_{\mu}$)** | **0.0707** ($7.07\%$) | **0.0908** ($9.08\%$) |
| **Minimum Utilization** | **1.0000** (1973) | **0.8736** (1960) |
| **Maximum Utilization** | **1.2330** (1947) | **1.1774** (1973) |

---

## 3. Key Years Comparison

| Year | Specification B ($\mu_t$) | True Shaikh-Style ($\mu_t$) | Divergence ($\mu_B - \mu_A$) |
| :---: | :---: | :---: | :---: |
| **1945** (Demobilization) | 1.2124 | 1.1716 | +0.0408 |
| **1950** (Korean War start) | 1.1982 | 1.0558 | +0.1424 |
| **1960** (Eisenhower recession) | 1.1295 | 0.8736 | **+0.2559** |
| **1970** (Vietnam War peak) | 1.0050 | 1.0553 | -0.0503 |
| **1973** (Baseline Year) | 1.0000 | 1.1774 | -0.1774 |

---

## 4. Visualization

![Capacity Utilization Comparison (1945-1973)](us_golden_age_reconstruction_plot.png)

---

## 5. Theoretical & Empirical Interpretation

### The Growth-Law Integration:
Instead of reconstructing potential capacity $y^p_t$ directly from a log-level fitted regression equation, Specification B uses the **A03 capacity growth-rate identity**:
$$ g_{Y^p} = \theta^{NRC} (1-s) g_{K^{NRC}} + \theta^{ME}(\omega, s) s g_{K^{ME}} $$
This method allows the time-varying elasticities $\theta_t^{NRC}$ and $\theta_t^{ME}$ to dynamically weight the accumulation rates of structures and machinery.
* **The Volatility Realignment:** Standard deviation is a robust **7.07%**, showing significant, realistic cyclical fluctuations.
* **Negative Correlation ($\rho = -0.2459$):** Because the composition channel ($\theta^{ME}_t$) behaves as a cushion, capacity output grows at a different rate than the rigid aggregate capital stock. For instance, in 1960 (Eisenhower recession), Shaikh-style utilization drops to **87.4%** because it does not recognize that capacity expansion was dampened by technique shifts. Specification B shows a utilization of **112.9%**, reflecting that capacity was tight relative to actual output.
* **Pinch Year vs. Average Residual:** Specification B is anchored strictly at the 1973 peak ($\mu_{1973} = 1.0$), forcing all prior years to have higher utilization. Shaikh's residualization centers the series around its log mean, which hides the historical asymmetry of the Golden Age peak.
