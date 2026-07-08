# Capacity Path Reconstruction & Comparison (Golden Age Case Study: 1945–1973)

This report compares the reconstructed potential output ($\hat{y}^p_t$) and latent capacity utilization ($\mu_t$) paths derived from two distinct econometric models estimated via FM-OLS over the post-war Golden Age:
1. **Specification B (Composition-Mediated):** Separates structures scale ($K^{NRC}$) and composition ($\tau = K^{ME}/K^{NRC}$) with distribution conditioning.
2. **True Shaikh-Style Model:** Regresses output directly on total private capital stock ($K_{Kcap} = K^{ME} + K^{NRC}$) only, with **no** distributive or interaction terms.

Both models are normalized to $\mu_{1973} = 1.0$ (strictly point-year baseline).

---

## 1. Estimated Equations (FM-OLS)

### Specification B (Composition-Mediated):
$$y_{t, B}^p = 14.8617 + 0.2378 \tilde{k}^{NRC}_t + 0.3121 \tilde{\tau}_t - 5.1605 \tilde{\omega}_t - 1.0294 (\tilde{\tau}_t \cdot \tilde{\omega}_t)_{orth}$$

### True Shaikh-Style Model:
$$y_{t, A}^p = 14.4669 + 0.9099 \tilde{k}^{Kcap}_t$$

---

## 2. Path Comparison Metrics

The reconstructed series are saved to:
[us_golden_age_reconstructed_paths.csv](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/reconstruction_comparison/us_golden_age_reconstructed_paths.csv)

| Metric | Specification B (Composition-Mediated) | True Shaikh-Style Model |
| :--- | :---: | :---: |
| **Correlation ($\rho_{A,B}$)** | \multicolumn{2}{c|}{**0.3876** (Moderate positive correlation)} |
| **Mean Utilization ($\mu$)** | **0.9949** | **0.8527** |
| **Standard Deviation ($\sigma_{\mu}$)** | **0.0277** ($2.77\%$) | **0.0771** ($7.71\%$) |
| **Minimum Utilization** | **0.9329** (1958) | **0.7420** (1960) |
| **Maximum Utilization** | **1.0422** (1945) | **1.0000** (1973) |

---

## 3. Key Years Comparison

| Year | Specification B ($\mu_t$) | True Shaikh-Style ($\mu_t$) | Divergence ($\mu_B - \mu_A$) |
| :---: | :---: | :---: | :---: |
| **1945** (Demobilization) | 1.0422 | 0.9951 | +0.0471 |
| **1950** (Korean War start) | 0.9882 | 0.8967 | +0.0915 |
| **1960** (Eisenhower recession) | 0.9841 | 0.7420 | **+0.2421** |
| **1970** (Vietnam War peak) | 1.0110 | 0.8963 | +0.1147 |
| **1973** (Baseline Year) | 1.0000 | 1.0000 | 0.0000 |

---

## 4. Theoretical & Empirical Interpretation

### Why the True Shaikh-Style Model leads to high volatility ($\sigma = 7.71\%$):
* **Single-Capital assumption:** By using $K_{Kcap} = K^{ME} + K^{NRC}$ as a single regressor without conditioning on the choice of technique (machinery composition), the model assumes that all capital forms expand scale uniformly.
* **Dominant Scale Coefficient:** The coefficient on $k^{Kcap}$ is `0.9099` (very close to `1.0`). When capital accumulation accelerates, the potential capacity output $\hat{y}^p_t$ swings violently. Because actual output $y_t$ grows more steadily, this forces the residual $\mu_t$ to absorb massive cyclical fluctuations (swinging down to **74.2%** in 1960).

### Why Composition-Mediated (Spec B) is more stable ($\sigma = 2.77\%$):
* **Separation of Margins:** Spec B isolates structures ($K^{NRC}$) as the physical plant scale (extensive margin). The structures coefficient is much lower (`0.23784`), reflecting that physical scale does not translate 1-to-1 into output capacity.
* **Composition Cushioning:** The intensive margin ($\tau$, machinery-to-structures ratio) behaves as a shock-absorber. When capitalists mechanize in response to distribution, the capacity payoff changes dynamically.
* **Keynesian/Harrodian alignment:** The resulting utilization series has a very low standard deviation ($2.77\%$) and hovers tightly around its mean ($0.9949$). This supports the Keynesian structural view that capacity utilization stays within a narrow reproduction corridor during normal growth periods, rather than undergoing massive long-term collapses.
