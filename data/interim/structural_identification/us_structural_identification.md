# ~~US Structural Identification Notebook~~
## ~~CVAR Structural Identification — Stage A~~

**Status:** SUPERSEDED (2026-04-04). Replaced by `us_structural_identification_v2.md`.  
**Reason:** Distributional variable changed from π_t to e_t = π/(1-π). See v2 for rationale.

---

*Original content below preserved for reference only. Do not use for estimation.*

**~~Status:~~ LOCKED (2026-04-04)**  
**Estimator:** Johansen RRR, restricted via `blrtest()` in R `urca`  
**Implementation:** Full structural identification via `blrtest()` — all CVs restricted jointly  

---

## 1. State Vector

$$X_t^{US} = (y_t,\; k_t^{gross},\; \pi_t,\; \pi_t k_t^{gross},\; \mathbf{1})'$$

| Slot | Variable | Definition | Source |
|---|---|---|---|
| 1 | $y_t$ | $\log(\text{GDP}_{real})$ | `gdp_real_2017` |
| 2 | $k_t^{gross}$ | $\log(NR\_K\_gross\_real)$ | `NR_K_gross_real` |
| 3 | $\pi_t$ | Corporate profit share | `profit_share` |
| 4 | $\pi_t k_t^{gross}$ | Interaction (constructed) | — |
| 5 | $\mathbf{1}$ | Restricted constant | `ecdet="const"` |

**Capital accounting (dual concept — locked):**

The RRR/CVAR structural identification requires **gross capital stocks** for $k_t^{gross}$. The productive capacity manifold CV1 identifies $\hat\theta$ and $\hat\mu_t$ from the physical transformation of the gross capital stock into output. Depreciation does not reduce productive capacity instantaneously — the gross stock is the correct measure of the installed productive base. Using net stocks in CV1 would conflate the depreciation regime with the capacity transformation elasticity $\theta$, biasing $\hat\theta$ and contaminating $\hat\mu_t$.

- **VECM/RRR:** `NR_K_gross_real` — real gross productive capital for MPF. Required.
- **Profit rate:** `NR_K_net_cc` — net current cost, value of capital advanced. Used only in the profit rate identity $r_t = \Pi_t / K_t^{net,cc}$ and the internal consistency check.
- **Composition ratio:** $comp_t = NR\_K\_gross\_real_t / NR\_K\_net\_cc_t$ — bridges the two concepts for Stage B Weisskopf decomposition.

**Sample:** Cross-referenced with the data estimation pipeline — see note below.  
**Johansen case:** `ecdet="const"` — Case 3, restricted constant, no linear trend in levels.

---

> **Data Estimation Pipeline — Sample Rule (cross-reference)**
>
> Two distinct sample regimes apply to different stages of the US estimation, determined by data availability in real terms vs. deflated nominal terms.
>
> **Stage A — Capacity utilization identification (RRR/CVAR):**
> Uses **maximum available data capacity in real terms**. The binding constraint is the limiting series across the state vector:
> - Real GDP (`gdp_real_2017`, NIPA Table 1.1.3): available from **1929**
> - Real gross NR capital (`NR_K_gross_real`, BEA Fixed Asset Table 4.1): available from **1925**
> - Corporate profit share (`profit_share`, NIPA Table 1.12): available from **1929**
> - Interaction $\pi_t k_t^{gross}$: constructed — same coverage as limiting series
>
> Stage A limiting series: **1929 onward** (NIPA real series). The Johansen rank test and CV1–CV3 structural identification run on the maximum real-terms sample — potentially 1929–2022/2023 (~94 observations). The pre-WWII period (1929–1940) should be included subject to a structural break audit (Great Depression and WWII as regime breaks in $\Phi D_t$).
>
> **Stage B — Profitability analysis (ARDL behavioral law):**
> Constrained to periods where **price deflators for bridging gross and net capital stocks are reliable**. The profit rate identity $r_t = \pi_t \cdot \hat\mu_t \cdot \hat\theta_t \cdot comp_t$ requires:
> - Net current-cost NR capital (`NR_K_net_cc`, BEA Fixed Asset Table 4.1): available from 1925, but current-cost methodology and chain-type deflators (BEA Table 4.2 — chain-type price deflators for private nonresidential fixed assets) are most internally consistent for the **post-WWII period**.
> - The composition ratio $comp_t = NR\_K\_gross\_real / NR\_K\_net\_cc$ requires both series on a consistent deflator basis.
>
> The Fordist window (1945–1978) referenced in the decisions table is the specific behavioral estimation sub-period — not a deflator reliability constraint per se, but the period where the Cambridge-Kaldor saving structure, the Goodwin distributional dynamics, and the goods market condition are theoretically operative in their canonical form. Stage B can be extended post-1978 as a robustness check.
>
> **Cross-reference files:** BEA Fixed Asset Table 4.2 (chain-type deflators), NIPA Table 1.12 (corporate profits), `master_dataset.csv` in the Ch2 pipeline — confirm consistent deflator basis before estimating the profit rate identity.
>
> **The rule:** capacity utilization identification maximizes data in real terms (1929 onward); profitability analysis anchors to deflator-reliable post-WWII period. The extended Stage A sample is the methodological contribution — structural identification of $\hat\mu_t$ does not require deflated price data, only real quantity series.

---



## 2. The Three Cointegrating Vectors

### CV1 — MPF: Mechanization Possibility Frontier

FMT pins MPF to origin — no intercept. Distribution enters only through the interaction term.

$$y_t = \theta_1 k_t^{gross} + \theta_2(\pi_t k_t^{gross}) = (\theta_1 + \theta_2\pi_t)\, k_t^{gross}$$

Endogenous transformation elasticity: $\theta_t(\pi) = \theta_1 + \theta_2\pi_t$

$$\boxed{\beta_1^{US} = (1,\; -\theta_1,\; 0,\; -\theta_2,\; 0)}$$

**Identifying restriction:** coefficient on $\pi_t = 0$. Distribution enters the production frontier *only* through $\pi_t k_t^{gross}$. Goodwin-MPF identifying restriction.

**ECT₁ = $\hat\mu_t^{US}$:** system-wide confinement of realized output within the distribution-conditioned productive capacity manifold. This is not a residual — it is the structurally identified object of the system: the degree to which effective demand is confined by the structural mediation of the capacity transformation elasticity $\theta_t(\pi) = \theta_1 + \theta_2\pi_t$, endogenous to distribution.

**Output:** $\hat\theta_1$, $\hat\theta_2$, $\hat\mu_t^{US} = y_t - \hat\theta_t k_t^{gross}$

---

### CV2 — Phillips Curve: Class Struggle Markup

$$\bar\pi_t = \varrho_1 - \varrho_2\hat\mu_t, \qquad \varrho_2 > 0$$

$$\boxed{\beta_2^{US} = (\varrho_2,\; -\varrho_2\theta_1,\; 1,\; -\varrho_2\theta_2,\; -\varrho_1)}$$

**Cross-equation restriction:** CV2 contains the same $\theta_1$, $\theta_2$ as CV1. Source of over-identification.

**Identifying restriction:** $\varrho_2 > 0$ — as utilization rises, reserve army shrinks, profit share falls.

**ECT₂:** class struggle markup deviation from Goodwin locus.

---

### CV3 — Profitability-Goods Market Disequilibrium (MPF-Consistent)

The closed-economy Cambridge-Kaldor I=S condition corrected for MPF consistency. The capital productivity argument must use $b_t^{US}$ from the CV1 capacity manifold — not $y_t - k_t^{gross}$, which conflates the CV1 confinement object $\hat\mu_t$ with the structural capital productivity trajectory.

**Why the old formulation was inconsistent:** $y_t - k_t^{gross} = b_t^{US} + \hat\mu_t$. Using realized output-capital ratio in CV3 imports the confinement object $\hat\mu_t$ — a stationary CV1 combination — into a cointegrating relation, collapsing the structural separation between the MPF and the goods market condition.

**Correct formulation:** use $b_t^{US}$ — the MPF-consistent capital productivity:

$$b_t^{US} = (\theta_1-1)k_t^{gross} + \theta_2(\pi_t k_t^{gross})$$

Expanding $\lambda b_t^{US}$ — same resolution as Chilean CV4:

$$\lambda b_t^{US} = \underbrace{\lambda(\theta_1-1)}_{\text{fixed}} k_t^{gross} + \underbrace{\lambda\theta_2}_{\text{fixed}} (\pi_t k_t^{gross})$$

All coefficients are fixed scalars. Define $\psi \equiv \gamma_1 - \lambda$. The goods market condition:

$$ECT_3^{US} = y_t - \gamma_1 y_t^{p,US} + \gamma_2\pi_t + \lambda b_t^{US} - \gamma_0$$

Collecting by slot:

$$\boxed{\beta_3^{US} = (1,\; -(\psi\theta_1+\lambda),\; \gamma_2,\; -\psi\theta_2,\; -\gamma_0)}$$

**Free parameters: 4** — $\gamma_0,\; \psi,\; \lambda,\; \gamma_2$

**What changed from the old formulation:**
- Normalization slot shifts from $k_t^{gross}$ to $y_t$ — CV3 is an output-side condition
- Zero on $\pi_t k_t^{gross}$ is gone — the distribution-technique interaction enters CV3 through $\psi\theta_2$, as an overidentifying cross-equation restriction from CV1
- Capital productivity enters through CV1-consistent $b_t^{US}$ decomposition, not realized $y_t - k_t^{gross}$

**ECT₃:**

| ECT₃ sign | Goods market signal | Goodwin phase |
|---|---|---|
| $ECT_3 > 0$ | Output above what profitability and capacity sustain — inventories drawn down | Expansion |
| $ECT_3 < 0$ | Realization failure — paradox of thrift | Contraction |

**Economic interpretation of $\lambda$ (US):** when $\theta_1 > 1$ (US under-mechanization regime), $b_t^{US} > 0$ and $\lambda b_t^{US} > 0$ — rising capital productivity generates upward goods market pressure. $\lambda$ is the structural elasticity of I-S disequilibrium with respect to capital productivity dynamics.

**$\psi = \gamma_1 - \lambda$:** net goods market discipline from capacity — residual capacity manifold scale after subtracting capital productivity dynamics.

**Internal consistency check:** $\hat\psi/\hat\gamma_2 \approx 1/\hat\varrho_2$

---


## 3. The Full Beta Matrix

On $(y,\; k^{gross},\; \pi,\; \pi k^{gross},\; \mathbf{1})'$, columns = cointegrating vectors CV1–CV3:

$$\beta^{US} = \begin{pmatrix} 1 & \varrho_2 & 1 \\ -\theta_1 & -\varrho_2\theta_1 & -(\psi\theta_1+\lambda) \\ 0 & 1 & \gamma_2 \\ -\theta_2 & -\varrho_2\theta_2 & -\psi\theta_2 \\ 0 & -\varrho_1 & -\gamma_0 \end{pmatrix}$$

|  | CV1 | CV2 | CV3 |
|---|---|---|---|
| $y$ | $1$ | $\varrho_2$ | $1$ |
| $k^{gross}$ | $-\theta_1$ | $-\varrho_2\theta_1$ | $-(\psi\theta_1+\lambda)$ |
| $\pi$ | $0$ | $1$ | $\gamma_2$ |
| $\pi k^{gross}$ | $-\theta_2$ | $-\varrho_2\theta_2$ | $-\psi\theta_2$ |
| $\mathbf{1}$ | $0$ | $-\varrho_1$ | $-\gamma_0$ |

**Shared parameters:** $\theta_1$, $\theta_2$ appear in CV1, CV2, and CV3. Cross-equation constraint across all three CVs requires full structural identification via joint LR test. This is the overidentification gain from the MPF-consistent CV3 formulation — one additional cross-equation restriction relative to the old Cambridge-Kaldor specification.

---

## 3a. The Full Alpha Matrix

Rows = variables, columns = ECTs. Maintained zeros in brackets. Testable restrictions marked with *.

$$\alpha^{US} = \begin{pmatrix} \alpha_{y,1} & \alpha_{y,2} & \alpha_{y,3} \\ \alpha_{k,1} & [0^*] & \alpha_{k,3} \\ \alpha_{\pi,1} & \alpha_{\pi,2} & [0^*] \\ [0] & [0] & [0] \end{pmatrix}$$

| Variable | ECT1 ($\hat\mu$) | ECT2 (Phillips) | ECT3 (Goods mkt) |
|---|---|---|---|
| $y_t$ | free | free | free |
| $k_t^{gross}$ | free | $[0^*]$ testable | free |
| $\pi_t$ | free | free | $[0^*]$ testable |
| $\pi_t k_t^{gross}$ | $[0]$ | $[0]$ | $[0]$ |

**Maintained zeros: 3** (interaction row). **Testable: 2** ($\alpha_{k,2}$, $\alpha_{\pi,3}$).

**Note:** the interaction row maintained zeros remain valid despite $\pi_t k_t^{gross}$ now appearing in CV3. The loading restriction asserts that the distribution-technique interaction has no independent short-run adjustment dynamics — its adjustment is fully determined by the dynamics of $\pi_t$ and $k_t^{gross}$, which already have their own equations. This holds regardless of which CVs the interaction enters in $\beta$.

---

## 3b. The Full Gamma Matrix

The short-run propagation matrix $\Gamma_i$ is $n \times n = 4 \times 4$. Each element $(\Gamma_i)_{jk}$ is the coefficient on $\Delta X_{k,t-i}$ in the equation for $\Delta X_{j,t}$.

**Restriction principle:** single state variables propagate freely in the short run. The interaction term $\pi_t k_t^{gross}$ is excluded in both directions — row 4 (the interaction equation has no short-run dynamics beyond its components) and column 4 (lagged interaction carries no independent predictive content).

$$\Gamma_i^{US} = \begin{pmatrix} \gamma^i_{y,y} & \gamma^i_{y,k} & \gamma^i_{y,\pi} & 0 \\ \gamma^i_{k,y} & \gamma^i_{k,k} & \gamma^i_{k,\pi} & 0 \\ \gamma^i_{\pi,y} & \gamma^i_{\pi,k} & \gamma^i_{\pi,\pi} & 0 \\ 0 & 0 & 0 & 0 \end{pmatrix}$$

Rows: equations for $\Delta y_t,\; \Delta k_t^{gross},\; \Delta\pi_t,\; \Delta(\pi_t k_t^{gross})$. Columns: lagged $\Delta y_{t-i},\; \Delta k_{t-i}^{gross},\; \Delta\pi_{t-i},\; \Delta(\pi_{t-i} k_{t-i}^{gross})$.

| Equation $\backslash$ Regressor | $\Delta y_{t-i}$ | $\Delta k_{t-i}^{gross}$ | $\Delta\pi_{t-i}$ | $\Delta(\pi k^{gross})_{t-i}$ |
|---|---|---|---|---|
| $\Delta y_t$ | free | free | free | $[0]$ |
| $\Delta k_t^{gross}$ | free | free | free | $[0]$ |
| $\Delta\pi_t$ | free | free | free | $[0]$ |
| $\Delta(\pi k^{gross})_t$ | $[0]$ | $[0]$ | $[0]$ | $[0]$ |

**Free elements:** $3 \times 3 = 9$ per $\Gamma_i$. **Restrictions:** $4 + 4 - 1 = 7$ zeros per lag. Scales linearly: $K-1$ lags → $7(K-1)$ total $\Gamma$ restrictions.

**Economic content of each free block ($3\times3$ upper-left):**

| Entry | Content |
|---|---|
| $\gamma^i_{y,y}$ | Output autocorrelation — demand persistence |
| $\gamma^i_{y,k}$ | Capital stock drives output short-run — accelerator echo |
| $\gamma^i_{y,\pi}$ | Distribution drives output — demand regime signal |
| $\gamma^i_{k,y}$ | Output drives investment — Keynesian accelerator |
| $\gamma^i_{k,k}$ | Capital accumulation persistence |
| $\gamma^i_{k,\pi}$ | Distribution drives investment short-run — Bhaduri-Marglin echo |
| $\gamma^i_{\pi,y}$ | Output drives distribution — utilization cycle |
| $\gamma^i_{\pi,k}$ | Capital drives distribution — mechanization pressure |
| $\gamma^i_{\pi,\pi}$ | Distributive conflict persistence |

---



```r
# ============================================================
# US CVAR — Structural Identification
# State vector: X = (y, k_gross, pi, pi_k, const)
# Dimension: n=5 (incl. restricted constant), r=3
# ============================================================

library(urca)

# ------------------------------------------------------------
# Step 1: Load data and construct state vector
# ------------------------------------------------------------
X <- cbind(y, k_gross, pi, pi_k)  # n=4 variables + ecdet="const"

# ------------------------------------------------------------
# Step 2: Lag selection and Johansen rank test
# ------------------------------------------------------------
K <- VARselect(X, lag.max = 3, type = "const")$selection["AIC(n)"]
jo <- ca.jo(X, type = "trace", ecdet = "const", K = K, spec = "longrun")
summary(jo)  # inspect trace and max-eigenvalue statistics

# ------------------------------------------------------------
# Step 3: Full structural restriction via blrtest()
#
# H matrix encodes the restriction beta = H * phi
# Rows = state vector slots (y, k, pi, pi_k, const)
# Cols = free parameters per CV
#
# CV1 restriction: beta_1 = (1, -theta1, 0, -theta2, 0)
# Free params: theta1, theta2
# H_CV1: 5 rows x 2 free params
# ------------------------------------------------------------
H_CV1 <- matrix(c(
  #  theta1  theta2
     0,      0,      # y:     normalized to 1 (not a free param)
     1,      0,      # k:     -theta1 (free)
     0,      0,      # pi:    restricted to 0
     0,      1,      # pi_k:  -theta2 (free)
     0,      0       # const: restricted to 0
), nrow = 5, ncol = 2, byrow = TRUE)

# CV2 restriction: beta_2 = (rho2, -rho2*theta1, 1, -rho2*theta2, -rho1)
# Cross-equation: theta1 and theta2 shared with CV1
# Free params after cross-eq restriction: rho1, rho2
# H_CV2: 5 rows x 2 free params (rho1, rho2)
H_CV2 <- matrix(c(
  #  rho2             rho1
     0,               0,      # y:     = rho2 (handled via cross-eq)
    -jo@V[2,1],       0,      # k:     = -rho2*theta1 (theta1 from CV1)
     0,               0,      # pi:    normalized to 1
    -jo@V[4,1],       0,      # pi_k:  = -rho2*theta2 (theta2 from CV1)
     0,              -1       # const: = -rho1 (free)
), nrow = 5, ncol = 2, byrow = TRUE)
# Note: jo@V[2,1] and jo@V[4,1] are theta1_hat and theta2_hat from CV1

# CV3 restriction: beta_3 = (1, -(psi*theta1+lambda), gamma2, -psi*theta2, -gamma0)
# Cross-eq: theta1 and theta2 shared from CV1 — overidentifying restriction
# Free params: psi, lambda, gamma2, gamma0  [4 free]
H_CV3 <- matrix(c(
  #  psi              lambda    gamma2    gamma0
     0,               0,        0,        0,      # y:      normalized to 1
    -theta1_hat,     -1,        0,        0,      # k:      -(psi*theta1 + lambda)
     0,               0,        1,        0,      # pi:     gamma2
    -theta2_hat,      0,        0,        0,      # pi_k:   -psi*theta2 (cross-eq from CV1)
     0,               0,        0,       -1       # const:  -gamma0
), nrow = 5, ncol = 4, byrow = TRUE)
# Note: theta1_hat, theta2_hat extracted from CV1 estimates
# psi = gamma1 - lambda recovered post-estimation

# ------------------------------------------------------------
# Step 4: Joint structural identification test
# blrtest() tests H_i restriction for each CV jointly
# ------------------------------------------------------------
H_list <- list(H_CV1, H_CV2, H_CV3)
vecm_restricted <- blrtest(jo, H = H_list, r = 3)
summary(vecm_restricted)
# LR test statistic ~ chi-sq with df = overidentifying restrictions
# df = (n*r - r^2) - free_params = (5*3 - 9) - 7 = 6 - 7 ... 
# adjust df based on normalization chosen

# ------------------------------------------------------------
# Step 5: Alpha restrictions
# Set maintained zeros before estimation
# Interaction row (row 4): all zeros — maintained
# alpha[k, ECT2] and alpha[pi, ECT3]: testable via sequential LR
# ------------------------------------------------------------

# Extract unrestricted alpha from cajorls
vecm_base <- cajorls(jo, r = 3)
alpha_hat  <- vecm_base$beta  # note: cajorls returns alpha in beta slot
# or: alpha_hat <- coef(vecm_base$rlm)[1:3, ]  # depends on version

# Restriction matrix A for alpha: A'*alpha = 0 imposes row restrictions
# Row 4 (pi_k): all zeros — A_piK forces full row to zero
A_piK <- diag(4)  # 4x4 identity — impose all alpha[piK, .] = 0
# Implement via restricted VECM re-estimation with A constraints

# Sequential LR tests for testable restrictions:
# Test alpha[k, ECT2] = 0:
#   Estimate restricted model, compare LR vs unrestricted
# Test alpha[pi, ECT3] = 0:
#   Estimate restricted model, compare LR vs unrestricted
# Critical values from chi-sq(1) distribution evaluated at each step

# ------------------------------------------------------------
# Step 6: Extract structural objects
# ------------------------------------------------------------
theta1_hat  <- -vecm_restricted@V[2, 1]  # CV1 slot 2, CV1 column
theta2_hat  <- -vecm_restricted@V[4, 1]  # CV1 slot 4, CV1 column
mu_hat      <- X %*% vecm_restricted@V[, 1]  # CV1 confinement series
rho1_hat    <- -vecm_restricted@V[5, 2]
rho2_hat    <-  vecm_restricted@V[1, 2]
gamma0_hat  <- -vecm_restricted@V[5, 3]
gamma1_hat  <- -vecm_restricted@V[1, 3]
gamma2_hat  <- -vecm_restricted@V[3, 3]
```



---

## 4. Free Parameters and Identification

**Free parameters:** $\theta_1, \theta_2, \varrho_1, \varrho_2, \gamma_0, \psi, \lambda, \gamma_2$ — **8 free parameters**

**Rank prior:** $r = 2$; acceptable if $r = 3$

**Over-identification:** $\theta_1$, $\theta_2$ shared across CV1, CV2, and CV3. The CV3 cross-equation restriction is the overidentification gain from MPF-consistent formulation — one additional restriction relative to the old Cambridge-Kaldor specification.

---

## 5. Decisions Locked

| Decision | Answer |
|---|---|
| Rank | Johansen decides empirically; prior $r=2$; acceptable if $r=3$ |
| CV identification | Full structural — CV1, CV2, CV3 restricted with shared θ; estimated jointly via `blrtest()` |
| CV3 | MPF-consistent goods market condition; $\psi$, $\lambda$ free; cross-eq restriction on $\theta$ |
| Sample | Stage A (capacity identification): 1929–present — max real-terms data. Stage B (profitability): post-WWII deflator-reliable period; Fordist window (1945–1978) for behavioral estimation |
| Capital for VECM | $k = \log(NR\_K\_gross\_real)$ — gross, required for MPF identification |
| Capital for profit rate | $K^{net,cc} = NR\_K\_net\_cc$ |
| Johansen case | Case 3: `ecdet="const"` |
| CV2 unrestricted | Robustness only — deferred |

---

## 5a. Testable Short-Run Adjustment Parameters — Interpretation and Testing

### General Testing Protocol

After imposing the 3 maintained zeros in $\alpha$ (the interaction row), the 2 testable parameters are evaluated via sequential LR testing. The procedure:

**Step 1 — Estimate the restricted base model:** VECM with maintained zeros imposed, 9 free $\alpha$ parameters.

**Step 2 — Identify candidates:** Inspect the $t$-statistics and economic content of all free loadings. Candidates for further restriction are those that are statistically weak AND whose economic cost of elimination is low given theory.

**Step 3 — Sequential LR test:** For each candidate $\alpha_{ij} = 0$, form the restricted model and test via LR against the unrestricted base:

$$LR = -2(\ell_{\text{restricted}} - \ell_{\text{unrestricted}}) \sim \chi^2(q)$$

where $q$ is the number of restrictions being tested. **Critical values are determined empirically from the $\chi^2$ distribution at each step — not pre-specified at asymptotic normal thresholds.** In a restricted VECM, the distribution of loading parameter tests depends on cointegrating rank, restrictions already imposed, and the specific normalization. Sequential elimination proceeds from least to most economically motivated.

**Step 4 — Re-test the full system:** After each elimination, re-run the joint LR test of the full $\beta$ restriction set. Overidentification count grows; inference on remaining parameters sharpens.

**Principle:** Statistical insignificance in $\alpha$ is economically informative — it identifies which error-correction channels are operative, not just detectable.

---

### Testable Parameter 1 — $\alpha_{k,2}$: Capital responding to distributional disequilibrium

**What it tests:** Does the capital stock $k_t^{gross}$ error-correct toward the Goodwin-Phillips distributional locus (ECT2)?

**$H_0: \alpha_{k,2} = 0$** — Capital does not respond directly to distributional disequilibrium. Distribution disciplines capital only through output first ($\alpha_{y,2}$ free), and capital then adjusts to the resulting goods market gap through ECT3. The distribution-investment link is fully mediated — distribution raises the profit share, which raises saving, which finances capital accumulation through the Cambridge-Kaldor channel.

**$H_1: \alpha_{k,2} \neq 0$** — Capital responds directly to the class struggle markup deviation from the Goodwin locus. When profits are above the Goodwin attractor, capitalists accelerate investment directly — not waiting for the goods market channel to transmit. This would be evidence of a direct Bhaduri-Marglin type investment response: $\pi_t \uparrow \to I_t \uparrow$ as a behavioral decision independent of the utilization-mediated path.

**Economic reading of sign:**
- $\alpha_{k,2} > 0$: capital accelerates when profits are above the Goodwin locus — profit-squeeze investment response, Bhaduri-Marglin type
- $\alpha_{k,2} < 0$: capital decelerates when profits are above the Goodwin locus — distributional ceiling bites on accumulation, closer to the neo-Marxian wage-led interpretation

**Fordist period prior:** For 1945–1978, the Cambridge-Kaldor mediation story is more plausible — distribution feeds accumulation through saving, not through direct behavioral response. Prior: fail to reject $H_0$. Post-Fordist period (if estimated): the behavioral response channel may become detectable as financialization loosens the saving-investment mediation.

---

### Testable Parameter 2 — $\alpha_{\pi,3}$: Distribution responding to goods market disequilibrium

**What it tests:** Does the profit share $\pi_t$ error-correct toward the goods market equilibrium (ECT3)?

**$H_0: \alpha_{\pi,3} = 0$** — Distribution is not directly disciplined by the goods market disequilibrium. The goods market gap transmits to distribution only through output: ECT3 $\to \Delta y_t$ (via $\alpha_{y,3}$) $\to \Delta\hat\mu_t$ $\to \Delta\pi_t$ (via the Goodwin Phillips ECT2). The chain is mediated — goods market pressure disciplines distribution only after passing through the utilization cycle.

**$H_1: \alpha_{\pi,3} \neq 0$** — Distribution responds directly to the goods market disequilibrium. When investment demand exceeds saving (ECT3 $> 0$), the excess demand allows firms to mark up prices, shifting income toward profits directly — bypassing the utilization cycle. This is the markup pricing channel: goods market tightness $\to$ pricing power $\to \pi_t \uparrow$.

**Economic reading of sign:**
- $\alpha_{\pi,3} > 0$: profit share rises when investment exceeds saving — markup pricing under excess demand, consistent with Kaleckian price-setting
- $\alpha_{\pi,3} < 0$: profit share falls when investment exceeds saving — real wage gains under tight goods markets, closer to a wage-bargaining story where workers capture tight market conditions

**Historical prior:** The markup pricing channel is most plausible in oligopolistic product markets. For the Fordist US (concentrated manufacturing, administered pricing), a positive $\alpha_{\pi,3}$ is economically credible. The restriction $\alpha_{\pi,3} = 0$ is the maintained hypothesis; a positive estimate would be a meaningful structural finding about the Fordist goods market regime.

---

### Joint Interpretation: What the Testable Parameters Reveal Together

The two testable parameters together map out the structure of the distributional-accumulation transmission in the US economy:

| Outcome | Economic reading |
|---|---|
| Both zero | Full Cambridge-Kaldor mediation: distribution → saving → accumulation; goods market → output → utilization → distribution. No direct channels. |
| $\alpha_{k,2} \neq 0$ only | Direct investment response to distribution — Bhaduri-Marglin behavioral channel operative alongside the Cambridge-Kaldor saving channel |
| $\alpha_{\pi,3} \neq 0$ only | Markup pricing channel operative — goods market tightness directly conditions distribution, bypassing the utilization cycle |
| Both nonzero | Full interdependence: direct channels operative in both directions. Distribution and accumulation are jointly determined with feedback that bypasses the standard mediation chains |

The Fordist prior favors the first outcome — the Cambridge-Kaldor saving channel and the Goodwin utilization-Phillips chain as the dominant transmission mechanisms, with direct channels either absent or weak. Evidence against this is itself a structural finding about the US accumulation regime.



## 5b. First-Difference Lag Restriction Matrix ($\Gamma_i$)

The short-run propagation matrix $\Gamma_i$ governs how lagged first differences $\Delta X_{t-i}$ enter each equation. The restriction principle mirrors the $\alpha$ matrix: single state variables are included; the interaction term $\pi_t k_t^{gross}$ is excluded from the short-run dynamics in both directions.

### Restriction Principle

**Row restriction — interaction equation has no short-run dynamics:**

The equation for $\Delta(\pi_t k_t^{gross})$ is not explained by any lagged $\Delta X_{t-i}$. The short-run fluctuations of the interaction are entirely determined by the dynamics of its components $\Delta\pi_t$ and $\Delta k_t^{gross}$, which already have their own equations in the system. Row 4 of $\Gamma_i$ = 0.

**Column restriction — lagged interaction does not enter any equation:**

$\Delta(\pi_{t-i} k_{t-i}^{gross})$ carries no information beyond what $\Delta\pi_{t-i}$ and $\Delta k_{t-i}^{gross}$ already contain as separate predictors. Column 4 of $\Gamma_i$ = 0.

Together: 4 (row) + 4 (column) - 1 (corner double-counted) = **7 restrictions per $\Gamma_i$ matrix.**

### Restricted $\Gamma_i$ Structure

$$\Gamma_i^{US} = \begin{pmatrix} * & * & * & 0 \\ * & * & * & 0 \\ * & * & * & 0 \\ 0 & 0 & 0 & 0 \end{pmatrix}$$

Rows/columns: $(y,\; k^{gross},\; \pi,\; \pi k^{gross})$. Free elements: $3\times3 = 9$ per $\Gamma_i$.

### R Implementation

```r
# Gamma restriction indicator: 1=free, 0=restricted
# Row 4 (pi_k equation) and column 4 (lagged pi_k) all zero
Gamma_indicator <- matrix(c(
  1, 1, 1, 0,   # y equation: y, k, pi drive y; pi_k excluded
  1, 1, 1, 0,   # k equation: y, k, pi drive k; pi_k excluded
  1, 1, 1, 0,   # pi equation: y, k, pi drive pi; pi_k excluded
  0, 0, 0, 0    # pi_k equation: no lagged differences (full row zero)
), nrow=4, ncol=4, byrow=TRUE,
dimnames=list(
  c("Dy", "Dk", "Dpi", "Dpi_k"),
  c("Dy_lag", "Dk_lag", "Dpi_lag", "Dpi_k_lag")
))

# Restrictions scale with lag order:
# Each additional lag imposes 7 additional restrictions (same structure)
# For K=2 (one first-difference lag, L=1): 1 Gamma matrix, 7 restrictions
# For K=3 (two first-difference lags, L=2): 2 Gamma matrices, 14 restrictions
# L=0 (K=1) eliminates the short-run block entirely — never use
# For K=3: 2 Gamma matrices, 14 restrictions, etc.
```

---

## 6. System Complexity — Structural vs. Unrestricted Parameter Count

This section compares the total parameter space under structural restriction against the unrestricted VECM, to quantify the degree of overidentification and the degrees of freedom for the joint LR test.

### Counting Convention

- **Unrestricted total:** all elements in each matrix block free, before any restriction. $\beta$ includes $n_{eff} \times r$ elements where $n_{eff} = n+1$ for restricted constant.
- **Structural free:** parameters estimated freely under the structural model.
- **Restrictions:** unrestricted elements minus structural free minus normalizations ($r$).
- **Overidentification df:** the number of testable restrictions — the degrees of freedom for the joint LR test of the full structural identification.

### US Parameter Count ($n=4$, $r=3$, $n_{eff}=5$, $L$ lags)

| Block | Unrestricted elements | Structural free | Overidentifying restrictions |
|---|---|---|---|
| $\beta$ | $5\times3=15$ | 8 ($\theta_1,\theta_2,\varrho_1,\varrho_2,\psi,\lambda,\gamma_2,\gamma_0$) | $15-8-3_{norm}=4$ |
| $\alpha$ | $4\times3=12$ | 9 (maintained zeros imposed) | 3 |
| $\Gamma_i$ (per lag) | $4\times4=16$ | 9 (interaction row+col=0) | 7 |
| **Total ($L=1$)** | **43** | **26** | **14** |
| **Total ($L=2$)** | **59** | **35** | **21** |

**Joint LR test df:** 14 at $L=1$ ($K=2$); increases by 7 per additional first-difference lag.

> **Notation:** $L$ = number of first-difference lag matrices ($\Gamma_i$) in the VECM short-run block; $L = K-1$ where $K$ is the lag order in `ca.jo(K=...)`. $L=1$ means one $\Gamma_1$ matrix — the short-run memory block is present. $L=0$ would eliminate the short-run block entirely and is never proposed. Parameter counts below are at $L=1$ (one first-difference lag, $K=2$).

**Stage A sample:** ~94 observations (1929–2022) at $L=1$; ~84 if restricted to post-WWII (1939–2022). The figure below uses 94 as the Stage A upper bound — the actual count is confirmed from the pipeline audit on the limiting series.

**Unrestricted VECM** at $L=1$: 43 parameters on ~94 observations. **Ratio: 2.2 obs per parameter** — identified but not comfortably. Structural restrictions are still econometrically motivated even at this sample length.

**Structural VECM** at $L=1$: 26 parameters. **Ratio: 3.6 obs per parameter** — well-identified for the Stage A full sample. The extended pre-WWII data materially improves identification relative to the Fordist-window-only estimate.

### Overidentification by Source

| Source | Restrictions | Economic content |
|---|---|---|
| $\theta_1$, $\theta_2$ shared across CV1, CV2, CV3 | 4 (β) | MPF elasticities govern both capacity manifold and goods market condition |
| $\pi_t k_t^{gross}$ row in $\alpha$ | 3 (maintained zeros) | Interaction has no independent short-run adjustment |
| $\pi_t k_t^{gross}$ row+col in $\Gamma_i$ | 7 per lag | Interaction has no independent short-run propagation |

**The overidentification is not numerical padding — each restriction is a testable structural claim.** The joint LR test with 14 df at $L=1$ is the formal test of whether the data support the structural interpretation of the MPF, the Phillips curve, and the goods market condition simultaneously.

### Comparison with the Unrestricted System

$$\underbrace{43}_{\text{unrestricted}} \xrightarrow{\text{14 restrictions}} \underbrace{26}_{\text{structural}} + \underbrace{3}_{\text{normalizations}} + \underbrace{14}_{\text{over-ID test}}$$

The structural restrictions achieve a 40% reduction in parameters ($43 \to 26$), turning an under-identified estimation problem on a 74-observation sample into an over-identified structural system with 14 testable restrictions.



| Object | Formula | Used in |
|---|---|---|
| $\hat\theta_1, \hat\theta_2$ | CV1 coefficients | Stage B, CV2 decomposition |
| $\hat\theta_t = \hat\theta_1 + \hat\theta_2\hat\pi_t^{LR}$ | Distribution-conditioned elasticity | All downstream |
| $\hat\mu_t^{US} = y_t - \hat\theta_t k_t^{gross}$ | Structurally identified confinement of demand — system-wide | Stage B, Stage C |
| $\hat\varrho_1, \hat\varrho_2$ | CV2 coefficients | Class struggle diagnostics |
| $\hat\gamma_0, \hat\gamma_1, \hat\gamma_2$ | CV3 coefficients | Goods market diagnostics |
| $\hat{b}_t^{gross} = y_t - k_t^{gross}$ | Log capital productivity (gross) | Stage B |
| $comp_t = NR\_K\_gross\_real / NR\_K\_net\_cc$ | Composition ratio | Stage B profit rate |
| $\hat{b}_t^{nc} = \hat\theta_t \cdot comp_t$ | Output-capital ratio at current cost | Stage B Weisskopf |

---

## 7. Internal Consistency Checks (Post-Estimation)

**Check 1 — Identity closure (stage gate before Stage B):**

$$r_t^{reconstructed} = \pi_t \cdot \hat\mu_t \cdot \hat\theta_t \cdot comp_t \approx r_t^{observed} = \Pi_t / K_t^{net,cc}$$

Tolerance: residual $< 1\%$ of $r_t^{observed}$ over the full estimation sample. No sub-period window imposed.

**Check 2 — Phillips curve level term:**

$(1 - \hat\varrho_1)$ is the estimated structural power differential — the baseline profit share independent of the utilization cycle. Its sign and magnitude are estimated freely from the data across the full sample. No specific numerical range is pre-imposed; the level is a finding, not a calibration target. The relevant diagnostic is whether $\hat\varrho_1 \in (0,1)$ — i.e. whether the estimated long-run profit share anchor is economically plausible — not whether it matches any particular sub-period average.

**Check 3 — Goods market internal consistency:**

$$\hat\psi / \hat\gamma_2 \approx 1/\hat\varrho_2$$

This is a purely algebraic cross-equation consistency condition linking the capacity-productivity scale ($\psi$) and the saving channel ($\gamma_2$) in CV3 to the Phillips curve slope ($\varrho_2$) in CV2. It holds as an approximation if the Cambridge-Kaldor saving structure is internally consistent with the distributional attractor. No window-specific calibration required.

---

## 8. Short-Run Restrictions — Loading Matrix $\alpha$

The US $\alpha$ matrix is $4 \times 3 = 12$ elements (at $r=3$; $4 \times 2 = 8$ at $r=2$). The system is structurally simpler than Chile — no external constraint, no ME/INF split. Adjustment dynamics are purely domestic and closed.

### 8.1 The $\alpha$/$\beta$ Partition as Variance Allocation

Same principle as Chile: restrictions on $\alpha$ are simultaneously a theoretical claim about where the mechanism operates temporally, a variance allocation decision about where to study each variable's dynamics, and a degrees-of-freedom gain. The $\pi_t k_t^{gross}$ row is the single most important restriction — the distribution-technique interaction fully loads to the long-run $\beta$ structure with no independent short-run adjustment dynamics.

### 8.2 Proposed $\alpha$ Restrictions — Variable by Variable

**$y_t$:** Output is the primary adjusting variable for all three structural disequilibria — utilization gap (ECT1), Phillips locus (ECT2), Cambridge-Kaldor I-S gap (ECT3). No zeros proposed.

**$k_t^{gross}$:** Capital stock responds to the Cambridge-Kaldor goods market gap (ECT3) and the utilization accelerator (ECT1).

- ECT1 (utilization gap): high $\hat\mu_t$ drives investment — the accelerator mechanism. Operative at annual frequency in the US. Keep free.
- ECT2 (Phillips distributional locus): does capital respond directly to distributional disequilibrium? The argument for zero: distribution disciplines capital through output first ($\alpha_{y,2}$ free), then capital adjusts to the resulting goods market gap through ECT3. The distribution-investment link is already embedded in ECT3 via the Cambridge-Kaldor $\gamma_2\pi_t$ term.

**Proposed:** $\alpha_{k,2}$ — **testable.** Does distributional disequilibrium drive capital accumulation directly, or only through output and the goods market?

**$\pi_t$:** Profit share responds to ECT1 (utilization drives distribution — standard Goodwin) and ECT2 (own Phillips locus adjustment).

- ECT3 (Cambridge-Kaldor I-S gap): does the goods market gap discipline distribution directly? Possible channel: excess investment demand allows markup pricing, shifting income toward profits. But the standard Goodwin story runs through utilization first.

**Proposed:** $\alpha_{\pi,3}$ — **testable.** Does the I-S gap discipline distribution directly, or only through utilization?

**$\pi_t k_t^{gross}$:** Constructed interaction — no independent behavioral content as an adjusting variable. Its adjustment is entirely determined by the dynamics of $\pi_t$ and $k_t^{gross}$, which already have their own equations. The distribution-technique interaction fully loads to the long-run $\beta$ structure.

**Maintained:** entire row = 0 — **3 parameters freed.**

### 8.3 Summary Table

| Variable | ECT1 | ECT2 | ECT3 | Zeros freed |
|---|---|---|---|---|
| $y_t$ | free | free | free | 0 |
| $k_t^{gross}$ | free | **testable** | free | 0 |
| $\pi_t$ | free | free | **testable** | 0 |
| $\pi_t k_t^{gross}$ | **0** | **0** | **0** | 3 |
| **Total** | | | | **3 maintained** |

**From 12 to 9 free $\alpha$ elements** at $r=3$; from 8 to 5 at $r=2$.

### 8.4 Recursive Refinement Protocol

**Step 1:** Impose 3 maintained zeros. Estimate with 9 free $\alpha$ parameters.

**Step 2:** Extract test statistics on all free loadings.

**Step 3 — Sequential LR elimination:** test additional zero restrictions via LR. Critical values are determined empirically from the test statistic distributions at each step — **not pre-specified at any asymptotic normal threshold.** In a restricted VECM, test statistics for loading parameters do not follow standard normal distributions; the distribution depends on cointegrating rank, restrictions already imposed, and normalization. Elimination proceeds from least to most economically motivated — retaining parameters where the theoretical cost of elimination is high regardless of statistical significance.

**Step 4:** Re-run the joint LR test after each elimination round. Statistical insignificance in $\alpha$ is economically informative — it identifies which error-correction channels are operative, not just detectable.

### 8.5 Structural Contrast with Chile

The US has 3 maintained zeros from a single restriction — the interaction row. Chile has 11 maintained zeros from six distinct theoretical arguments: infrastructure slow-moving, import propensity causal chain, NRS direction, distributional intermediate variable, Lewis labor supply exogeneity, interaction row. The difference is not quantitative — it reflects the structural complexity of the peripheral case. The BoP constraint, NRS drain, and two-margin capital decomposition each generate additional theoretically motivated zeros that the closed economy simply does not need.

The two testable restrictions in the US ($\alpha_{k,2}$ and $\alpha_{\pi,3}$) are the closed-economy analogues of the Chilean procyclical NRS test — places where theory is ambiguous and the LR test arbitrates. In the US the ambiguity is about whether distributional disequilibrium disciplines capital directly or only through output. In Chile it is about whether utilization booms trigger luxury consumption directly or only through distribution.

---

## 9. Estimation Script: `20_vecm_4var_us.R`

```r
# Sequence:
# 1. Load ch2_panel_us.csv
# 2. Full sample (non-missing on y, k, pi, pi_k)
# 3. Lag selection: VARselect(), max 3 lags, type="const"
# 4. Johansen rank: ca.jo(X, type="trace", ecdet="const", K=K, spec="longrun")
#    + ca.jo(..., type="eigen") for max-eigenvalue
# 5. Unrestricted VECM: cajorls(jo, r=r_hat) — baseline
# 6. Full structural restriction: blrtest(jo, H=H_joint, r=r_hat)
#    Joint restriction imposing shared theta across CV1 and CV2
#    Extract: theta1_hat, theta2_hat, rho1_hat, rho2_hat
# 7. If r=3: add CV3 restriction, re-run blrtest on full system
#    LR test of joint restriction is the structural identification test
# 8. CV3: cajorls(jo, r=3) if rank supports it
# 9. Extract mu_hat, b_gross, comp, b_nc
# 10. Identity closure check
# 11. Save to output/stage_a/us/csv/
```

---

## 9a. Extension Block — Phillips Curve Regime Change Test (1974 onward)

> **Status: Extension — not maintained. To be tested after baseline identification.**

### Motivation

1974 marks the structural inflection in the US distributional regime: the end of the Bretton Woods system (Nixon shock 1971, full float 1973), the first OPEC oil shock, and the onset of stagflation. These events plausibly shift both the long-run distributional attractor ($\varrho_1$ — the structural power differential) and the sensitivity of distribution to utilization ($\varrho_2$ — the Goodwin slope). The baseline CV2 imposes a single $\varrho_1$ and $\varrho_2$ across the full sample. This extension tests whether that restriction is warranted.

---

### Test 1 — Level Shift in the Phillips Curve Intercept

**Question:** Does the long-run distributional attractor $\varrho_1$ shift permanently after 1974?

**Modified CV2:**

$$\pi_t = (\varrho_1 + \varrho_1^* D_t^{74}) - \varrho_2\hat\mu_t$$

where $D_t^{74} = \mathbb{1}[t \geq 1974]$.

**Structural content of $\varrho_1^*$:**

- $\varrho_1^* > 0$: the structural profit share floor rises after 1974 — capital's structural power increases in the stagflation era (consistent with profit squeeze narrative ending, real wage compression)
- $\varrho_1^* < 0$: the structural profit share floor falls — distributional conflict intensifies, workers retain structural bargaining power beyond the Fordist period

**Implementation:** $D_t^{74}$ enters as a restricted dummy in $\beta_2$ — it shifts the long-run equilibrium level of the CV2 attractor, not just the short-run dynamics. The appropriate procedure is the **Johansen-Mosconi-Nielsen (1994)** broken intercept test: estimate CV2 allowing for a structural break in the restricted constant at 1974, using the modified critical values tabulated for the broken-mean case.

The extended $\beta_2$ on the augmented vector $(y,\; k^{gross},\; \pi,\; \pi k^{gross},\; \mathbf{1},\; D_t^{74})'$:

$$\beta_2^{extended} = (\varrho_2,\; -\varrho_2\theta_1,\; 1,\; -\varrho_2\theta_2,\; -\varrho_1,\; -\varrho_1^*)$$

**LR test:** $H_0: \varrho_1^* = 0$ (no level shift) vs $H_1: \varrho_1^* \neq 0$. One additional free parameter; df = 1.

---

### Test 2 — Slope Change in the Goodwin Sensitivity

**Question:** Does $\varrho_2$ — the sensitivity of distribution to utilization — shift after 1974?

**Modified CV2:**

$$\pi_t = \varrho_1 - (\varrho_2 + \varrho_2^* D_t^{74})\hat\mu_t$$

**Structural content of $\varrho_2^*$:**

- $\varrho_2^* < 0$: the Goodwin slope weakens after 1974 — stagflation decouples the utilization-distribution nexus. Rising prices allow firms to maintain profit shares even under low utilization; the reserve army mechanism is muted
- $\varrho_2^* > 0$: the Goodwin slope strengthens — distributional conflict becomes more sensitive to demand conditions in the post-Fordist period

**Implementation note:** The interaction $D_t^{74} \times \hat\mu_t$ is $I(0)$ since $\hat\mu_t$ is $I(0)$ by CV1 construction. It cannot enter the $I(1)$ cointegrating vector in the standard Johansen framework. The slope change is therefore identified via the **Hansen-Johansen (1999) parameter constancy test** — testing whether $\varrho_2$ is stable across the full sample with 1974 as the candidate break point. This is a structural stability test on an existing $\beta$ coefficient, not a new free parameter in $\beta$.

Alternatively: split-sample estimation pre/post 1974 and compare $\hat\varrho_2^{pre}$ vs $\hat\varrho_2^{post}$ directly.

---

### Combined Test — Full Regime Change in CV2

Both shifts simultaneously: $\varrho_1$ level shift (testable via LR) + $\varrho_2$ slope change (testable via Hansen-Johansen constancy). The joint test provides the complete structural stability assessment of the Phillips curve across the Fordist/post-Fordist regime boundary.

### R Implementation Sketch

```r
# Extension: regime change test on CV2 (1974 breakpoint)
# Step 1 — Level shift: add D74 as restricted dummy in beta
D74 <- as.integer(time(X) >= 1974)  # dummy variable
X_ext <- cbind(X, D74)              # extended state vector

# Run Johansen with restricted dummy in beta (JMN procedure)
# Use critical values from Johansen-Mosconi-Nielsen (1994) Table 1
jo_ext <- ca.jo(X_ext, type="trace", ecdet="const", K=K, spec="longrun")
# Restrict D74 to enter only CV2 beta column — test varrho1_star = 0

# Step 2 — Slope change: Hansen-Johansen constancy test
# Use hansen.test() or manual fluctuation test on rho2_hat across rolling windows
# Candidate break: 1974
# H0: rho2 constant across full sample
# H1: rho2 shifts at 1974

# Interpretation table:
# varrho1_star > 0 + varrho2_star < 0: classic stagflation regime
#   — higher structural profit floor AND weaker utilization-distribution sensitivity
# varrho1_star < 0 + varrho2_star > 0: intensified conflict regime
#   — lower structural profit floor AND stronger utilization-distribution link
```

---



The current US specification uses aggregate $k_t^{gross}$ — real gross non-residential capital — which collapses machinery and equipment ($K^{ME}$) and structures/infrastructure ($K^{INF}$) into a single series. This implicitly assumes equal capacity contributions per unit of capital: $\theta_0 = \theta_1 - \theta_0$, i.e. no machinery productivity premium.

The Chilean identification relaxes this assumption by separating $k_t^{NR}$ and $k_t^{ME}$ in the state vector, recovering a two-type capacity manifold:

$$y_t^p = \theta_0 k_t^{NR} + (\theta_1 - \theta_0)k_t^{ME} + \theta_2(\pi_t k_t^{ME})$$

Applying this decomposition to the US would test whether the American capital accumulation regime exhibits its own choice-of-technique dynamics — whether the composition between machinery-intensive and infrastructure-intensive investment conditions productive capacity and the transformation elasticity $\hat\theta^{US}$ in ways the aggregate specification cannot identify.

If $\theta_1 - \theta_0 \neq 0$ in the US, the current $\hat\theta^{US}$ is a weighted average of two structurally distinct elasticities, and the utilization series $\hat\mu_t^{US}$ inherits a composition bias. The center-periphery comparison in §2.10 — $\hat\theta^{US}$ vs $\hat\theta^{CL}$ — would then be comparing objects with different internal structures.

**Natural extension:** Re-estimate the US system with the two-type state vector $(y_t, k_t^{NR}, k_t^{ME}, \pi_t, \pi_t k_t^{ME})'$ using the BEA fixed asset decomposition (equipment vs structures from NIPA Table 4.1). The LR test of the restriction $\theta_1 - \theta_0 = 0$ is the formal test of whether the choice-of-technique dynamics that motivate the Chilean two-type specification are also operative in the US center economy.

**Connection to regime-switching Leontief (Chile):** If the US exhibits a significant machinery productivity premium ($\theta_1 - \theta_0 > 0$), then $\phi_t^{ME,US} = K_t^{ME}/K_t^{NR}$ becomes a candidate threshold variable for a Hansen-Seo threshold VECM in the US — testing whether post-war deindustrialization (falling $\phi_t^{ME,US}$) has shifted the US toward an infrastructure-constrained regime analogous to the peripheral trap but operating through a different mechanism.

---

*Locked 2026-04-04. Authority: this document. Supersedes all prior session notes on US VECM identification.*
