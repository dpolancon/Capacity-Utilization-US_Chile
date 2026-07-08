# Cointegrating Polynomial Regression (CPR): Econometric Exposition

This note provides a self-contained exposition of **Cointegrating Polynomial Regression (CPR)**, explaining why it resolves the $I(2)$ unit root trap in nonlinear models and how FM-OLS/IM-OLS estimators ensure valid inference.

---

## 1. What is Cointegrating Polynomial Regression?

Standard linear cointegration (Engle-Granger, Johansen) assumes a linear relationship between variables integrated of order one ($I(1)$). However, many economic theories—including Chapter 2's induced innovation model—mandate **nonlinear interactions** between stochastic trends.

A **Cointegrating Polynomial Regression (CPR)** is a regression model that contains powers or products of $I(1)$ regressors, yet yields a stationary ($I(0)$) error term. 

### General Formulation:
$$y_t = \alpha + \beta_1 x_t + \beta_2 x_t^2 + \gamma (x_t \cdot z_t) + u_t$$

Where:
* $y_t, x_t, z_t$ are $I(1)$ stochastic processes.
* $x_t^2$ and $x_t \cdot z_t$ are nonlinear terms.
* The model is cointegrated if and only if $u_t \sim I(0)$.

---

## 2. The $I(2)$ Trap in Naive Cointegration

In time-series econometrics, if $x_t \sim I(1)$ and $z_t \sim I(1)$, their product $w_t = x_t \cdot z_t$ is **not** $I(1)$. It is integrated of order two ($I(2)$) or contains $I(2)$ stochastic components.

### Why this breaks standard models:
1. **Asymptotic Invalidity:** If you run a standard linear Engle-Granger test on $y_t \sim (x_t, z_t, w_t)$, the critical values are incorrect. Standard unit root tests on residuals collapse because the regressors span different integration orders ($I(1)$ and $I(2)$).
2. **Deterministic Drift Inflation:** Squaring or multiplying random walks introduces deterministic trend components that grow faster than standard random walks.
3. **Multicollinearity:** The interaction term $x_t \cdot z_t$ is highly collinear with its constituent main effects $x_t$ and $z_t$, leading to massive Variance Inflation Factors (VIFs > 80.0) and parameter instability.

---

## 3. The CPR Solution

CPR theory (pioneered by Wagner 2012, Hong & Phillips 2010) establishes that **mixed-order regressors can cointegrate** if they share the same underlying stochastic trends. The $I(2)$ components in the interaction term $(x_t \cdot z_t)$ cancel out with the $I(2)$ components of the dependent variable $y_t$ to produce a stationary error term $u_t$.

### How CPR Resolves the Trap:
* **Promoted Admissibility:** Rather than blocking $I(2)$ variables, we classify them as `AUTHORIZE_POLYNOMIAL_CPR` since the nonlinear interaction is theoretically required.
* **Residual Centering (Orthogonalization):** We regress the interaction product on the constituent main effects:
  $$(x_t \cdot z_t) = \delta_0 + \delta_1 x_t + \delta_2 z_t + v_t$$
  We then use the residual $v_t$ as the **orthogonalized interaction** regressor. This reduces the VIF to exactly **1.0** without modifying the OLS residuals, the cointegration test statistics, or the estimated coefficient of interest ($\gamma$).

---

## 4. Estimation Methods: FM-OLS vs. IM-OLS

While OLS estimators in a CPR are superconsistent, they suffer from severe **second-order asymptotic bias** (endogeneity and serial correlation of the errors). To obtain valid t-statistics and p-values, we use adapted estimators:

### A. Fully Modified OLS (FM-OLS)
* **Mechanism:** Adjusts the dependent variable $y_t$ and the covariance matrix to account for endogeneity and serial correlation using a non-parametric kernel estimator (e.g., Newey-West).
* **Role:** Serves as the main level estimator for the locked specifications.

### B. Integrated Modified OLS (IM-OLS)
* **Mechanism:** Avoids the calculation of long-run covariance matrices for the squared/product regressors (which can be highly unstable in small samples). It adds lead/lag adjustments to the regression directly.
* **Role:** Primary robustness check. It is highly robust to mixed-order integrated systems.

### C. Dynamic OLS (DOLS)
* **Mechanism:** Adds leads and lags of the first-differences of the regressors to absorb short-run dynamics.
* **Role:** Fragility diagnostic (sensitive to lag/lead length in small samples).

---

## 5. Application to Chapter 2 (Specification B)

In Specification B, the plant scale ($k_{NRC}$) is the extensive margin, and composition ($\tau = k_{ME} - k_{NRC}$) is the intensive margin. Distributive wage share ($\omega$) conditions the intensive margin:

$$y_t = \alpha + \theta \tilde{k}^{scale}_t + \psi \tilde{\tau}_t + \phi \tilde{\omega}_t + \lambda (\tilde{\tau}_t \cdot \tilde{\omega}_t)_{orth} + u_t$$

Differentiating with respect to the intensive composition ($\tau$) yields the **state-dependent elasticity**:

$$\theta_t^{\tau} \equiv \frac{\partial y_t}{\partial \tilde{\tau}_t} = \psi + \lambda \tilde{\omega}_t$$

* Under the Golden Age estimation, $\psi = 0.3121$ and $\lambda = -1.0294$.
* As wage share rises ($\tilde{\omega}_t > 0$), the capacity payoff of mechanization falls due to diminishing returns along the concave technological frontier ($\lambda_2 < 0$), validating the cost-minimization FOC.
