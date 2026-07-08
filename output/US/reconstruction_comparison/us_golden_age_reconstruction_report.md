# Capacity Path Reconstruction & Comparison (Golden Age Case Study: 1945–1973)

This report compares the reconstructed potential output ($\hat{y}^p_t$) and latent capacity utilization ($\mu_t$) paths derived from two distinct econometric models estimated via FM-OLS over the post-war Golden Age:
1. **Specification B (Composition-Mediated):** Separates structures scale ($K^{NRC}$) and composition ($\tau = K^{ME}/K^{NRC}$) with distribution conditioning. Normalized to $\mu_{1973} = 1.0$. **Theoretical Correction:** The direct wage-share realization term ($\phi_B \tilde{\omega}_t$) is treated as a demand-side nuisance control and is **excluded** from the potential capacity output $y^p_t$, allowing the utilization residual to absorb cyclical demand-side variations.
2. **True Shaikh-Style Model:** Regresses output directly on total private capital stock ($K_{Kcap} = K^{ME} + K^{NRC}$) only, with **no** distributive or interaction terms. Normalized around the average residual (mean-normalized in logs such that the geometric mean is 1.0).

---

## 1. Estimated Equations (FM-OLS)

### Specification B (Composition-Mediated):
$$y_{t, B}^p = 14.8617 + 0.2378 \tilde{k}^{NRC}_t + 0.3121 \tilde{\tau}_t - 1.0294 (\tilde{\tau}_t \cdot \tilde{\omega}_t)_{orth}$$
*(Note the exclusion of the realization term $-5.1605 \tilde{\omega}_t$.)*

### True Shaikh-Style Model:
$$y_{t, A}^p = 14.4669 + 0.9099 \tilde{k}^{Kcap}_t$$

---

## 2. Path Comparison Metrics

The reconstructed series are saved to:
[us_golden_age_reconstructed_paths.csv](us_golden_age_reconstructed_paths.csv)

| Metric | Specification B (Composition-Mediated) | True Shaikh-Style Model |
| :--- | :---: | :---: |
| **Correlation ($\rho_{A,B}$)** | \multicolumn{2}{c|}{**0.0286** (Virtually orthogonal paths)} |
| **Mean Utilization ($\mu$)** | **1.0536** | **1.0040** |
| **Standard Deviation ($\sigma_{\mu}$)** | **0.0700** ($7.00\%$) | **0.0908** ($9.08\%$) |
| **Minimum Utilization** | **0.9392** (1971) | **0.8736** (1960) |
| **Maximum Utilization** | **1.1806** (1950) | **1.1774** (1973) |

---

## 3. Key Years Comparison

| Year | Specification B ($\mu_t$) | True Shaikh-Style ($\mu_t$) | Divergence ($\mu_B - \mu_A$) |
| :---: | :---: | :---: | :---: |
| **1945** (Demobilization) | 1.0724 | 1.1716 | -0.0992 |
| **1950** (Korean War start) | 1.1806 | 1.0558 | +0.1248 |
| **1960** (Eisenhower recession) | 1.0114 | 0.8736 | **+0.1378** |
| **1970** (Vietnam War peak) | 0.9616 | 1.0553 | -0.0937 |
| **1973** (Baseline Year) | 1.0000 | 1.1774 | -0.1774 |

---

## 4. Visualization

![Capacity Utilization Comparison (1945-1973)](us_golden_age_reconstruction_plot.png)

---

## 5. Theoretical & Empirical Interpretation

### The Volatility Correction:
By excluding the direct wage share realization term $\phi_B \tilde{\omega}_t$ from potential capacity output, the standard deviation of Specification B's utilization increases from **2.77%** to **7.00%**, introducing significant, realistic cyclical fluctuations.
* **Why this is correct:** The coefficient on the wage share in the NFC sector is negative ($\phi_B = -5.1605$), reflecting a profit-led demand realization regime (higher wage shares squeeze NFC demand/utilization).
* **Ontological Separation:** Productive capacity $Y^p$ represents the physical envelope of capital. Utilization $\mu = Y/Y^p$ absorbs the realization shock. Including the realization control in $Y^p$ incorrectly treats demand contractions as collapses in physical productive capacity.

### Orthogonality of the Paths ($\rho = 0.0286$):
The utilization paths of Specification B and the Shaikh-style model are virtually uncorrelated. 
* **Shaikh-Style:** Driven entirely by the output-to-capital ratio residual, making utilization a simple reflection of cyclical output fluctuations relative to a rigid aggregate capital corridor.
* **Composition-Mediated:** Captures the structural interaction between mechanization (the intensive margin) and distribution, adjusted for demand-side wage shocks. This highlights that incorporating the choice of technique changes not just the variance, but the entire historical path of capacity utilization.
