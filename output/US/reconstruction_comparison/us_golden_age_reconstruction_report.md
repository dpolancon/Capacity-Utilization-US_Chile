# Capacity Path Reconstruction & Comparison (Golden Age Case Study: 1945–1973)

This report compares the reconstructed potential output ($\hat{y}^p_t$) and latent capacity utilization ($\mu_t$) paths derived from three distinct methodologies estimated over the post-war Golden Age:
1. **Specification B (Composition-Mediated):** Separates structures scale ($K^{NRC}$) and composition ($\tau = K^{ME}/K^{NRC}$) with distribution conditioning. Normalized to $\mu_{1973} = 1.0$. Reconstructed by integrating the physical growth rate identity using time-varying elasticities (A03 growth law):
   $$ \Delta y^p_t = \theta^{NRC}_t \Delta k^{NRC}_t + \theta^{ME}_t \Delta k^{ME}_t $$
   where $\theta^{ME}_t = \psi + \lambda \tilde{\omega}_t$ and $\theta^{NRC}_t = \theta - \theta^{ME}_t$. This series is anchored at $y^p_{1973} = y_{1973}$.
2. **True Shaikh-Style Model:** Regresses output directly on total private capital stock ($K_{Kcap} = K^{ME} + K^{NRC}$) only, with **no** distributive or interaction terms. Normalized around the average residual (mean-normalized in logs such that the geometric mean is 1.0).
3. **HP Filter Trend-Cycle Decomposition:** A Hodrick-Prescott filter ($\lambda = 100$) applied directly to observed output $y_t$. Reconstructed potential output is the trend ($y^p_t = y^{\text{trend}}_t$), and utilization is the cycle ($\mu_t = \exp(y^{\text{cycle}}_t)$).

---

## 1. Estimated Equations & Specifications

### Specification B (Composition-Mediated):
$$ \Delta y_{t, B}^p = (0.2378 - \theta^{ME}_t) \Delta k^{NRC}_t + \theta^{ME}_t \Delta k^{ME}_t $$
where the time-varying machinery composition elasticity is:
$$ \theta^{ME}_t = 0.3121 - 1.0294 (\tilde{\tau}_t \cdot \tilde{\omega}_t)_{orth} $$

### True Shaikh-Style Model (FM-OLS):
$$ y_{t, A}^p = 14.4669 + 0.9099 \tilde{k}^{Kcap}_t $$

### HP Filter (Output Trend):
$$ y_{t, HP}^p = \text{HP-Trend}(y_t, \lambda=100) $$

---

## 2. Path Comparison Metrics

The reconstructed series are saved to:
[us_golden_age_reconstructed_paths.csv](us_golden_age_reconstructed_paths.csv)

| Metric | Specification B (Composition-Mediated) | True Shaikh-Style Model | HP Filter Decomposition |
| :--- | :---: | :---: | :---: |
| **Correlation with Spec B ($\rho$)** | **1.0000** | **-0.2459** | **0.5559** |
| **Correlation with Shaikh ($\rho$)** | **-0.2459** | **1.0000** | **0.4367** |
| **Mean Utilization ($\mu$)** | **1.1374** | **1.0040** | **1.0005** |
| **Standard Deviation ($\sigma_{\mu}$)** | **0.0707** ($7.07\%$) | **0.0908** ($9.08\%$) | **0.0326** ($3.26\%$) |
| **Minimum Utilization** | **1.0000** (1973) | **0.8736** (1960) | **0.9416** (1958) |
| **Maximum Utilization** | **1.2330** (1947) | **1.1774** (1973) | **1.0664** (1966) |

---

## 3. Key Years Comparison

| Year | Specification B ($\mu_t$) | True Shaikh-Style ($\mu_t$) | HP Filter ($\mu_t$) |
| :---: | :---: | :---: | :---: |
| **1945** (Demobilization) | 1.2124 | 1.1716 | 1.0423 |
| **1950** (Korean War start) | 1.1982 | 1.0558 | 1.0185 |
| **1960** (Eisenhower recession) | 1.1295 | 0.8736 | 0.9754 |
| **1970** (Vietnam War peak) | 1.0050 | 1.0553 | 0.9719 |
| **1973** (Baseline Year) | 1.0000 | 1.1774 | 1.0033 |

---

## 4. Visualization

![Capacity Utilization Comparison (1945-1973)](us_golden_age_reconstruction_plot.png)

---

## 5. Theoretical & Empirical Interpretation

### Methodological Insights:
* **The HP Filter Fallacy ($\sigma = 3.26\%$):** The HP filter represents a purely statistical trend-cycle decomposition of output, completely blind to the capital stock and distributive conditions. It yields a very low-volatility utilization path ($3.26\%$) because it forces the trend (capacity) to follow output closely. By doing so, it implicitly assumes that $\theta = 1$ and conflates structural capacity changes with short-run cycles (as criticized by Hamilton).
* **Correlation Alignment:** Specification B has a stronger positive correlation with the HP business cycle cycle (**0.5559**) than the Shaikh style does (**0.4367**). This indicates that composition-mediated capacity utilization aligns better with standard macroeconomic cyclical turnarounds while retaining structural grounding in the real capital stocks.
* **The Role of the Cushion:** In 1960 (Eisenhower recession), HP filter utilization falls below trend (**97.5%**) and Shaikh-style falls deeply to **87.4%**. In contrast, Specification B shows a high utilization of **112.9%**. This divergence arises because the A03 identity incorporates the intensive cushion: the slowing rate of mechanization ($\tau$) during that period led to slower capacity growth relative to actual output, keeping capacity tight and utilization high.
