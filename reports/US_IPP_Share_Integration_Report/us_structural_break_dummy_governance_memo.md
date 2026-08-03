# Decision Memo: Structural Break Governance for Cointegration Models ($\omega_i \times \iota_t$ vs. $\omega_i \times \iota_t \times \kappa_t$)

**Chapter 2 Research Group**  
*Department of Economics, UMass Amherst*  
*August 2026*

---

## Executive Summary (BLUF)

This memo establishes the binding governance rules for selecting step dummies ($D_t$) and impulse dummies ($I_t$) in single-equation (IM-OLS/FM-OLS) and system (VECM) cointegration models for U.S. corporate accumulation. Based on our Zivot-Andrews (`ur.za`) endogenous break battery across 1925–2024 and repository governance rules:

1. **Double Interaction Models ($\omega_i \times \iota_t$):**
   - **Primary Step Dummy ($D_t$):** $D_{1984} = \mathbb{I}(t \ge 1984)$ enters the long-run cointegration relationship $\boldsymbol{\beta}' \mathbf{X}_t + \gamma D_{1984}$. It captures the Reagan-Volcker institutional break identified empirically in 1984 ($t_{\text{ZA}} \in [-4.54, -4.92]$).
   - **Impulse Dummies ($I_t$):** Enter short-run error correction equations ($\Delta \mathbf{X}_t$) only: $I_{1942\text{--}1945}$ (WWII mobilization), $I_{1974}$ (1973–74 OPEC I oil price shock), and $I_{2008}$ (GFC liquidity collapse).

2. **Section 3.2 Triple Interaction Models ($\omega_i \times \iota_t \times \kappa_t$):**
   - **Primary Step Dummies ($D_t$):** 
     - $D_{1974} = \mathbb{I}(t \ge 1974)$: Captures the extensive-margin infrastructure envelope break ($\kappa_t$ saturation at the end of Fordism, $t_{\text{ZA}} = -3.632$).
     - $D_{1985} = \mathbb{I}(t \ge 1985)$: Captures the intensive mechanization-dividend shift (triple interaction break mode at 1985, $t_{\text{ZA}} \in [-4.58, -4.66]$).
     - **Cointegrating Vector Matrix Form:** $\boldsymbol{\beta}' \mathbf{X}_t + \gamma_1 D_{1974} + \gamma_2 D_{1985}$.
   - **Impulse Dummies ($I_t$):** Enter short-run dynamics ($\Delta \mathbf{X}_t$) only: $I_{1933}$ (New Deal trough), $I_{1942\text{--}1945}$ (WWII), $I_{1974}$ (OPEC I), $I_{1982}$ (Volcker trough), and $I_{2008}$ (GFC).

---

## 1. Governance Rules: Step Dummies vs. Impulse Dummies

### Rule 1.1: Functional Differentiation
- **Step Dummies ($D_t = \mathbb{I}(t \ge T_B)$):** Represent permanent structural shifts in deterministic trends or long-run levels. Under repository symbology rules, step dummy coefficients are denoted strictly by $\gamma$ in single-equation models ($\boldsymbol{\gamma}' \mathbf{D}_t$) and $\boldsymbol{\Gamma}$ in multi-equation VECMs. Symbol $\delta$ is strictly reserved for net capital economic depreciation rates.
- **Impulse Dummies ($I_t = \mathbb{I}(t = T_B)$):** Represent transient, single-period exogenous shocks. Impulse dummies are prohibited from entering the long-run cointegrating space ($\boldsymbol{\beta}' \mathbf{X}_t$) to prevent distorting cointegration rank tests and super-consistent parameter estimates. They enter only the short-run VAR/VECM error-correction matrix $\mathbf{\Psi} \mathbf{I}_t$.

### Rule 1.2: Johansen Rank Integrity
Step dummy placement inside the cointegrating vector must follow Johansen Case 4 (restricted constant and unconstrained step dummy) or Case 5 (unconstrained trend and step dummy) to ensure that critical values match Johansen-Juselium asymptotic distributions.

---

## 2. Model 1: Double Interaction Cointegration ($\omega_i \times \iota_t$)

### 2.1 Empirical Break Evidence
Our unit root battery identified distinct break points:
- **Corporate IPP Share ($\iota_t$):** Endogenous break at **1976** ($t_{\text{ZA}} = -4.529$).
- **Double Interactions ($\omega_i \times \iota_t$):** Endogenous breaks strictly localized at **1984** across all eight wage share measures ($t_{\text{ZA}} \in [-4.54, -4.92]$).

### 2.2 Structural Break Assignment Table

| Dummy Type | Variable / Vector | Break Year ($T_B$) | Mathematical Definition | Econometric Role | Economic Rationale |
| :--- | :--- | :---: | :--- | :--- | :--- |
| **Step ($D_t$)** | Cointegrating Vector | **1984** | $D_{1984} = \mathbb{I}(t \ge 1984)$ | Long-run Level Shift ($\gamma D_{1984}$) | Reagan-Volcker neoliberal restructuring; labor share defeat and IP protection consolidation. |
| **Step ($D_t$)** | Standalone IPP Shift | **1976** | $D_{1976} = \mathbb{I}(t \ge 1976)$ | Robustness Intercept Shift | Post-stagflation pivot from tangible manufacturing to IP asset accumulation. |
| **Impulse ($I_t$)** | Short-run VECM | **1942–1945** | $I_{\text{WWII}} = \mathbb{I}(1942 \le t \le 1945)$ | Short-run Shock Control | World War II war production reallocation shock. |
| **Impulse ($I_t$)** | Short-run VECM | **1974** | $I_{1974} = \mathbb{I}(t = 1974)$ | Short-run Shock Control | OPEC I oil price spike shock. |
| **Impulse ($I_t$)** | Short-run VECM | **2008** | $I_{2008} = \mathbb{I}(t = 2008)$ | Short-run Shock Control | Global Financial Crisis liquidity freeze. |

---

## 3. Model 2: Section 3.2 Triple Interaction Cointegration ($\omega_i \times \iota_t \times \kappa_t$)

### 3.1 Empirical Break Evidence
Adding the capital composition ratio $\kappa_t = \log(K^{\text{ME}}_t) - \log(K^{\text{NRC}}_t)$ introduces the physical infrastructure footprint into the state-dependent viability framework of Section 3.2:
- **Capital Composition Ratio ($\kappa_t$):** Endogenous break at **1974** ($t_{\text{ZA}} = -3.632$).
- **Triple Interactions ($\omega_i \times \iota_t \times \kappa_t$):** Endogenous breaks tightly clustered between **1983** and **1986**, with the primary mode at **1985** ($t_{\text{ZA}} \in [-4.58, -4.66]$).

### 3.2 Structural Break Assignment Table

| Dummy Type | Variable / Vector | Break Year ($T_B$) | Mathematical Definition | Econometric Role | Economic Rationale |
| :--- | :--- | :---: | :--- | :--- | :--- |
| **Step ($D_t$)** | Cointegrating Vector | **1974** | $D_{1974} = \mathbb{I}(t \ge 1974)$ | Extensive Envelope Shift ($\gamma_1 D_{1974}$) | End of Fordism; saturation and deceleration of non-residential structures footprint ($K^{\text{NRC}}$). |
| **Step ($D_t$)** | Cointegrating Vector | **1985** | $D_{1985} = \mathbb{I}(t \ge 1985)$ | Intensive Viability Dividend ($\gamma_2 D_{1985}$) | Realignment of physical equipment, IPP investment, and wage shares post-1981 Tax Act and Plaza Accord. |
| **Impulse ($I_t$)** | Short-run VECM | **1933** | $I_{1933} = \mathbb{I}(t = 1933)$ | Short-run Shock Control | Great Depression structural trough. |
| **Impulse ($I_t$)** | Short-run VECM | **1942–1945** | $I_{\text{WWII}} = \mathbb{I}(1942 \le t \le 1945)$ | Short-run Shock Control | WWII industrial mobilization. |
| **Impulse ($I_t$)** | Short-run VECM | **1974** | $I_{1974} = \mathbb{I}(t = 1974)$ | Short-run Shock Control | OPEC I supply shock spike. |
| **Impulse ($I_t$)** | Short-run VECM | **1982** | $I_{1982} = \mathbb{I}(t = 1982)$ | Short-run Shock Control | Volcker disinflation trough. |
| **Impulse ($I_t$)** | Short-run VECM | **2008** | $I_{2008} = \mathbb{I}(t = 2008)$ | Short-run Shock Control | GFC financial panic. |

---

## 4. Synthesis and Econometric Implementation Protocol

### 4.1 Single-Equation Cointegration Form (IM-OLS / FM-OLS)
For Section 3.2 state-dependent viability estimations, the long-run equation is specified as:

$$Y^p_t = \alpha + \beta_K k_t^{\text{cap}} + \theta_{\omega} \omega_{t-1} + \theta_{\omega \iota} (\omega_{t-1} \cdot \iota_{t-1}) + \theta_{\omega \iota \kappa} (\omega_{t-1} \cdot \iota_{t-1} \cdot \kappa_{t-1}) + \gamma_1 D_{1974,t} + \gamma_2 D_{1985,t} + u_t$$

Where:
- $\gamma_1 D_{1974,t}$ captures the extensive infrastructure step shift.
- $\gamma_2 D_{1985,t}$ captures the intensive mechanization-dividend step shift.
- $u_t \sim I(0)$ is the stationary residual.

### 4.2 Multi-Equation VECM Form
In matrix notation, the system error-correction representation is:

$$\Delta \mathbf{X}_t = \boldsymbol{\alpha} \left( \boldsymbol{\beta}' \mathbf{X}_{t-1} + \boldsymbol{\Gamma}_1 D_{1974,t-1} + \boldsymbol{\Gamma}_2 D_{1985,t-1} + \mathbf{c}_0 \right) + \sum_{i=1}^{p-1} \mathbf{\Phi}_i \Delta \mathbf{X}_{t-i} + \mathbf{\Psi} \mathbf{I}_t + \boldsymbol{\varepsilon}_t$$

Where $\mathbf{I}_t = [I_{1933}, I_{\text{WWII}}, I_{1974}, I_{1982}, I_{2008}]'$ is the vector of impulse controls entering short-run dynamics only.
