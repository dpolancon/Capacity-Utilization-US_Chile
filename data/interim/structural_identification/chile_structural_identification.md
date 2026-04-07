# Chile Structural Identification Notebook
## CVAR Structural Identification — Stage A (Peripheral Extension)

**Status:** WORKING DRAFT — CV1, CV2 locked; CV3, CV4 locked pending final review  
**Date:** 2026-04-03  
**Estimator:** Johansen RRR, restricted via `blrtest()` in R `urca`  
**Implementation:** Full structural identification via `blrtest()` — all CVs restricted jointly  

---

## 1. State Vector

$$X_t^{CL} = (y_t,\; k_t^{NR},\; k_t^{ME},\; \pi_t,\; \pi_t k_t^{ME},\; m_t,\; nrs_t)'$$

| Slot | Variable | Definition | Source |
|---|---|---|---|
| 1 | $y_t$ | $\log(\text{GDP}_{real}^{CL})$ | BCCh |
| 2 | $k_t^{NR}$ | $\log(K_t^{NR,CL})$ — total non-residential capital | K-Stock-Harmonization repo (Pérez-Eyzaguirre spliced with BCCh) |
| 3 | $k_t^{ME}$ | $\log(K_t^{ME,CL})$ — machinery & equipment | K-Stock-Harmonization repo (Pérez-Eyzaguirre spliced with BCCh) |
| 4 | $\pi_t^{CL}$ | Profit share (GOS/GVA) | BCCh / Astorga (2023) |
| 5 | $\pi_t^{CL} k_t^{ME}$ | Distribution-machinery interaction (constructed) | — |
| 6 | $m_t$ | Import propensity $M_t/Y_t$ | BCCh Aggregate Demand accounts |
| 7 | $nrs_t$ | $\ln(NRS_t) = \ln(\Pi_t - I_t)$ — non-reinvested surplus | Pérez-Eyzaguirre spliced with BCCh Aggregate Demand accounts and deflators |

**Notation lock:** $\pi_t^{CL}$ = profit share throughout. $s_t$ banned.  
**$NRS_t$ definition:** $\Pi_t - I_t$ where $I_t$ is **total investment** (not machinery-only). Constructed from Pérez-Eyzaguirre capital accounts spliced with BCCh Aggregate Demand accounts and deflators. Pérez-Eyzaguirre is the update of the Clio-Lab Historical Accounts underlying the K-Stock-Harmonization repo.

**Capital stock concept — critical distinction (locked):**

The RRR/CVAR structural identification requires **gross capital stocks** for $k_t^{NR}$ and $k_t^{ME}$. The productive capacity manifold CV1 identifies $\hat\theta$ and $\hat\mu_t$ from the physical transformation of the gross capital stock into output — depreciation does not reduce productive capacity instantaneously, and the gross stock is the correct measure of the installed productive base. Using net capital stocks in CV1 would conflate the depreciation regime with the capacity transformation elasticity $\theta$, biasing $\hat\theta$ and contaminating $\hat\mu_t$.

Net capital stocks enter **only** through the profit rate identity in the internal consistency check — $r_t = \Pi_t / K_t^{net}$ — which uses current-cost net stocks to value the capital advanced. The composition ratio $comp_t = K_t^{gross} / K_t^{net,cc}$ bridges the two concepts for Stage B.

Source: K-Stock-Harmonization repo canonical Perez baseline and BCCh extension bundle provide gross stocks. Cross-check against BCCh net stocks for the profit rate identity.  
**Rank prior:** $r = 4$  
**Johansen case:** `ecdet="const"` — Case 3, restricted constant, no deterministic trend  
**Sample:** Cross-referenced with the data estimation pipeline — see note below.

---

> **Data Estimation Pipeline — Sample Rule (cross-reference)**
>
> Two distinct sample regimes apply to different stages of the estimation, determined by data availability in real terms vs. deflated nominal terms:
>
> **Stage A — Capacity utilization identification (RRR/CVAR):**
> Uses **maximum available data capacity in real terms**. Capital stock series from K-Stock-Harmonization extend back to 1900 (Pérez-Eyzaguirre / BCCh extension bundle). Real GDP from BCCh / Clio-Lab historical series. The state vector variables $(y_t, k_t^{NR}, k_t^{ME}, \pi_t, \pi_t k_t^{ME}, m_t, nrs_t)$ are used over the longest consistently available real-terms sample — potentially 1940–2024 or 1900–2024 depending on splicing availability. The Johansen rank test and CV1–CV4 structural identification run on this extended sample. Observation count for the complexity section should be updated once the final spliced series is confirmed — it exceeds 60 and may reach 80–120 annual observations depending on variable coverage.
>
> **Stage B — Profitability analysis (ARDL behavioral law):**
> Constrained to periods with **reliable price deflators**. The profit rate identity $r_t = \pi_t \cdot \hat\mu_t \cdot \hat\theta_t \cdot comp_t$ requires consistent deflators to bridge gross capital stocks (constant prices) and net current-cost stocks. BCCh deflator coverage is reliable from approximately 1960 onward; the $P_k$ companion series in K-Stock-Harmonization covers 1940–2024 via BCCh (1960–2024) and ClioLab chained ratios (1940–1959). Stage B should be restricted to the period where deflator reliability is confirmed in the pipeline audit — cross-reference `bcch_bridge_diagnostics.csv` and `pk_splice_diagnostics.csv` in the K-Stock-Harmonization `outputs/HARMONIZED_BCCH_2003CLP_v1/` directory.
>
> **The rule:** capacity utilization identification maximizes data; profitability analysis constrains to deflator-reliable periods. These are not the same sample and should not be treated as such.

---



## 2. Micro-Foundation: Two-Margin Classical Argument

**Margin I — Intensive (within-plant):** $K^{INF}$ fixed; firm substitutes $L$ for $K^{ME}$ in response to distribution pressure. Direct, continuous, high-frequency. $\partial K^{ME}/\partial\pi > 0$.

**Margin II — Extensive (new plant):** Both $K^{ME}_{new}$ and $K^{INF}_{new}$ chosen jointly at classical cost-minimizing optimum. Lumpy, episodic — driven by demand, not conjunctural distribution. $\partial K^{INF}/\partial\pi \approx 0$ at business-cycle frequency.

**Implication:** At annual data frequency, Margin I dominates. Distribution operates through machinery; infrastructure is distribution-insensitive.

**Future research flag — Regime-switching Leontief and the two-type decomposition as a general identification strategy:**

The regime-switching Leontief — where the binding constraint switches between machinery-constrained and infrastructure-constrained regimes — is deferred to future research. The natural extension is a Hansen-Seo threshold VECM with $\phi_t^{ME} = K_t^{ME}/K_t^{NR}$ as the threshold variable. When $\phi_t^{ME}$ crosses a structural threshold from below, the economy transitions from a machinery-constrained to an infrastructure-constrained regime and the capacity manifold changes form accordingly.

This has implications beyond Chile. The two-type capital decomposition — separating $K^{ME}$ and $K^{INF}$ in the productive capacity function — is a general identification strategy for studying choice of technique that is currently suppressed in standard single-capital CVAR specifications, including the US. The US baseline uses aggregate $k_t^{gross}$, which collapses machinery and infrastructure into a single series and implicitly assumes $\theta_0 = \theta_1 - \theta_0$ — equal capacity contributions per unit. Applying the ME/INF decomposition to the US would test whether the American capital accumulation regime exhibits its own choice-of-technique dynamics: whether the composition of the capital stock between machinery-intensive and infrastructure-intensive investment conditions productive capacity and the transformation elasticity $\theta$ in ways the aggregate specification cannot identify.

This is a direct extension of the Ch2 identification strategy to the center-side of the center-periphery comparison — and a methodological contribution to the structural CVAR literature on capital accumulation independent of the peripheral economy context.

---

## 3. The Four Cointegrating Vectors

### CV1 — Two-Type MPF: Mechanization Possibility Frontier (LOCKED)

Productive capacity function with infrastructure and machinery as structurally distinct inputs:

$$y_t^p = \theta_0 k_t^{INF} + \theta_1 k_t^{ME} + \theta_2(\pi_t \cdot k_t^{ME})$$

Substituting $k_t^{INF} = k_t^{NR} - k_t^{ME}$:

$$y_t^p = \theta_0 k_t^{NR} + (\theta_1 - \theta_0) k_t^{ME} + \theta_2(\pi_t \cdot k_t^{ME})$$

$$\boxed{\beta_1^{CL} = (1,\; -\theta_0,\; -(\theta_1-\theta_0),\; 0,\; -\theta_2,\; 0,\; 0)}$$

**Parameters:**

| Parameter | Content | Sign prior |
|---|---|---|
| $\theta_0$ | Infrastructure capacity elasticity | $> 0$ |
| $\theta_1 - \theta_0$ | Machinery productivity premium | $> 0$ |
| $\theta_2$ | Distribution-mechanization slope | $> 0$ |

**Identifying restrictions:**
- Zero on $\pi_t$ directly — distribution operates only through machinery
- No intercept — FMT: no exploitation → no mechanization → no capacity growth
- Zero on $m_t$, $nrs_t$

**ECT₁ = $\hat\mu_t^{CL}$:** system-wide confinement of realized output within the distribution-conditioned productive capacity manifold. This is not a residual in the statistical sense — it is the structurally identified object of the system: the degree to which effective demand is confined by the structural mediation of the capacity transformation elasticity $\theta(\pi)$, which is itself endogenous to distribution through the $\pi_t k_t^{ME}$ channel.

**Output:** $\hat\theta_0$, $\hat\theta_1 - \hat\theta_0$, $\hat\theta_2$, $\hat\mu_t^{CL}$

**Distinction from US CV1:** Interaction is $\pi_t k_t^{ME}$ (machinery only), not $\pi_t k_t^{gross}$ (aggregate NR). Infrastructure enters separately with base elasticity $\theta_0$.

---

### CV2 — Neo-Goodwin Phillips Curve (LOCKED)

$$\pi_t = \varrho_1 - \varrho_2\hat\mu_t^{CL}$$

$$\boxed{\beta_2^{CL} = (\varrho_2,\; -\varrho_2\theta_0,\; -\varrho_2(\theta_1-\theta_0),\; 1,\; 0,\; 0,\; 0)}$$

**Cross-equation restriction:** CV2 contains the same $\theta_0$, $\theta_1-\theta_0$ as CV1. This is the source of over-identification — the shared $\theta$ parameters across CV1 and CV2 are estimated jointly under the full structural restriction, not sequentially imposed.

**Zero on $\pi_t k_t^{ME}$:** interaction does not enter the distributional attractor.  
**Zero on $m_t$, $nrs_t$:** external constraint enters short-run block only.

**ECT₂:** deviation of profit share from its utilization-consistent long-run locus.

**Labor force growth $n_t$ — treatment:** $n_t = \dot N/N$ is strictly exogenous to the goods market ($\partial n_t/\partial\hat\mu_t = 0$). Does NOT enter the cointegrating vector. Enters $\Phi D_t$ as $I(0)$ control. Two short-run channels:
1. Forward attenuation: high $n_t$ replenishes reserve army, attenuates $\varrho_2$ — identified in $\Delta\pi_t$ equation
2. Backward demand depression: high $n_t$ → depressed wages → weak consumption → $\hat\mu_t$ structurally suppressed — identified in $\Delta y_t$ equation

**Historical reading:**

| Period | Mechanism | CV2 operative? |
|---|---|---|
| Long sixties | Lewis depletion — reserve army tightens | Partially — $n_t$ attenuates $\varrho_2$ |
| Pinochet | Institutional labor repression | Cycle suppressed — short-run dynamics dominate |
| Post-transition | Milder cycle — Concertación | Yes — $\varrho_2$ reasserts as $n_t$ falls |

---

### CV3 — Import Propensity Attractor: Tavares + Palma-Marcel (LOCKED)

Long-run structural determinants of the import propensity — two competing claims on the same forex pool:

$$m_t = \zeta_0 + \zeta_1 \ln k_t^{ME} + \zeta_2 \ln nrs_t$$

$$\boxed{\beta_3^{CL} = (0,\; 0,\; \zeta_1,\; 0,\; 0,\; -1,\; \zeta_2)}$$

**Parameters:**

| Parameter | Sign | Channel |
|---|---|---|
| $\zeta_1 > 0$ | Tavares | Machinery accumulation requires forex. Prior: $\zeta_1 \approx \xi_K^{ME} \approx 0.92$–$0.94$ (Kaldor 1959, Cuadro 8). Testable LR restriction. |
| $\zeta_2 > 0$ | Palma-Marcel | Rising NRS drains forex pool via luxury consumption imports |

**Identifying restrictions:**
- Zero on $y_t$: output enters only through $k^{ME}$ via accumulation path
- Zero on $k_t^{NR}$: infrastructure irrelevant to machinery import propensity
- Zero on $\pi_t$ and $\pi_t k_t^{ME}$: distribution enters through $nrs_t$, not standalone

**ECT₃:**

$$ECT_3 = m_t - \zeta_0 - \zeta_1 \ln k_t^{ME} - \zeta_2 \ln nrs_t$$

- $ECT_3 > 0$: forex pool overdrawn — pre-crisis signal (1980–1981)
- $ECT_3 < 0$: forced import compression — post-sudden-stop (1982–1983)

Asymmetric loading on $\Delta y_t$: large $|\alpha_{y,3}|$ for positive deviations (sudden stop fires fast), small for negative (slow recovery).

**Kaldor-ECLA fault line — estimable:**

$$\text{Tavares share} = \frac{\hat\zeta_1 \bar k^{ME}}{\hat\zeta_1 \bar k^{ME} + \hat\zeta_2 \overline{\ln nrs}}$$

---

### CV4 — Profitability-Goods Market Disequilibrium (LOCKED)

Open-economy Cambridge-Kaldor I=S condition. Profitability must cover both reproduction cost and external demand leakage. Carries the discipline on the Phillips curve from the profitability side.

$$ECT_4 = y_t - \gamma_1[\theta_0 k_t^{NR} + (\theta_1-\theta_0)k_t^{ME}] + \gamma_2\pi_t + \lambda b_t^{CL} - \gamma_3 m_t - \gamma_0$$

Expanding $\lambda b_t^{CL}$ using the CV1 two-type capacity manifold:

$$b_t^{CL} = (\theta_0-1)k_t^{NR} + (\theta_1-\theta_0)k_t^{ME} + \theta_2(\pi_t k_t^{ME})$$

$$\lambda b_t^{CL} = \underbrace{\lambda(\theta_0-1)}_{\text{fixed}} k_t^{NR} + \underbrace{\lambda(\theta_1-\theta_0)}_{\text{fixed}} k_t^{ME} + \underbrace{\lambda\theta_2}_{\text{fixed}} (\pi_t k_t^{ME})$$

All coefficients are fixed scalars — the time variation in $b_t^{CL}$ is carried by the state vector variables themselves. $\lambda$ is a single free scalar. The nonlinearity problem is fully resolved.

Collecting by slot, define $\psi \equiv \gamma_1 - \lambda$:

$$\boxed{\beta_4^{CL} = (1,\; -\psi\theta_0 - \lambda,\; -\psi(\theta_1-\theta_0),\; \gamma_2,\; -\psi\theta_2,\; -\gamma_3,\; 0)}$$

**$\theta$ parameters — estimated jointly with CV1 under full structural restriction.** The capital productivity term $\gamma_1[\theta_0 k_t^{NR} + (\theta_1-\theta_0)k_t^{ME}] = \gamma_1 y_t^p$ is the productive capacity manifold from CV1 scaled by $\gamma_1$. The cross-equation restriction sharing $\theta_0$, $\theta_1-\theta_0$, and $\theta_2$ across CV1 and CV4 is an overidentifying restriction tested jointly by the LR test of the full system.

**Free parameters: 5** — $\gamma_0,\; \psi \equiv \gamma_1 - \lambda,\; \lambda,\; \gamma_2,\; \gamma_3$

**Sign check:**

| Term | Combined coefficient | Reason |
|---|---|---|
| $y_t$ | $+1$ | Output — demand pressure |
| $k_t^{NR}$ | $-\psi\theta_0 - \lambda$ | Capacity manifold ($\psi$) + capital productivity dynamics ($\lambda$) |
| $k_t^{ME}$ | $-\psi(\theta_1-\theta_0)$ | Net capacity-productivity channel on machinery |
| $\pi_t$ | $+\gamma_2$ | Cambridge-Kaldor saving channel |
| $\pi_t k_t^{ME}$ | $-\psi\theta_2$ | Distribution-technique — capacity-side, negative consistent with CV1 |
| $m_t$ | $-\gamma_3$ | Import leakage compresses multiplier |
| $nrs_t$ | $0$ | Enters through CV3 only |

**$\lambda$ — Fully identified, no approximation:**

$b_t^{CL} = (\theta_0-1)k_t^{NR} + (\theta_1-\theta_0)k_t^{ME} + \theta_2(\pi_t k_t^{ME})$ is non-observed and time-varying. But it is a linear combination of state vector variables with coefficients pinned by the CV1 regime parameters. Multiplying by $\lambda$ distributes into three fixed coefficients — the time variation is carried by $k_t^{NR}$, $k_t^{ME}$, and $\pi_t k_t^{ME}$ themselves. No approximation required. $\lambda$ is a single free scalar estimated from the full structural restriction. The previous structural limitation declaration is superseded.

**Economic interpretation of $\lambda$:** $\lambda$ is the goods market sensitivity to capital productivity dynamics — the structural elasticity of I-S disequilibrium with respect to the pace of capital productivity change $b_t^{CL}$. When $\hat\theta^{CL} < 1$ (over-mechanization), $b_t^{CL} < 0$ and $\lambda b_t^{CL} < 0$ — falling capital productivity structurally pulls the goods market toward realization failure. $\lambda$ governs how strongly that tendency feeds into the I-S disequilibrium.

**$\psi = \gamma_1 - \lambda$:** the net goods market discipline from capital — residual capacity manifold effect after subtracting the capital productivity dynamics channel.

**Post-estimation diagnostic:** The ratio $\hat\lambda/\hat\theta_2$ recovers the implied average $\bar b_t^{CL}$. Under $\hat\theta^{CL} < 1$ this should be negative. Compare against directly computed $\overline{(\hat\theta-1)k_t}$.

**ECT₄:**
- $ECT_4 > 0$: output above productive capacity net of leakage — current account deteriorating
- $ECT_4 < 0$: realization failure — peripheral underconsumption trap

**Sudden stop fires when $ECT_3 > 0$ and $ECT_4 > 0$ simultaneously.**

**Comparison: Closed vs Open Economy:**

| | US CV3 (closed) | Chilean CV4 (open) |
|---|---|---|
| I=S condition | $I = s_\pi \pi Y$ | $I = s_\pi \pi Y + X - mY$ |
| Capital | $\gamma_1 b_t$ | $\gamma_1 y_t^p$ (two-type, imposed) |
| Profit share | $\gamma_2\pi_t$ | $\gamma_2\pi_t$ |
| Leakage | Absent | $-\gamma_3 m_t$ |
| Distribution-technique | Absent | $-\lambda(\pi_t k_t^{ME})$ |
| ECT buffer | Inventories | External position |

---

## 4. The Full Beta Matrix

On $(y,\; k^{NR},\; k^{ME},\; \pi,\; \pi k^{ME},\; m,\; nrs)'$, columns = cointegrating vectors CV1–CV4:

$$\beta^{CL} = \begin{pmatrix} 1 & \varrho_2 & 0 & 1 \\ -\theta_0 & -\varrho_2\theta_0 & 0 & -\psi\theta_0 - \lambda \\ -(\theta_1-\theta_0) & -\varrho_2(\theta_1-\theta_0) & \zeta_1 & -\psi(\theta_1-\theta_0) \\ 0 & 1 & 0 & \gamma_2 \\ -\theta_2 & 0 & 0 & -\psi\theta_2 \\ 0 & 0 & -1 & -\gamma_3 \\ 0 & 0 & \zeta_2 & 0 \end{pmatrix}$$

|  | CV1 | CV2 | CV3 | CV4 |
|---|---|---|---|---|
| $y$ | $1$ | $\varrho_2$ | $0$ | $1$ |
| $k^{NR}$ | $-\theta_0$ | $-\varrho_2\theta_0$ | $0$ | $-\psi\theta_0 - \lambda$ |
| $k^{ME}$ | $-(\theta_1-\theta_0)$ | $-\varrho_2(\theta_1-\theta_0)$ | $\zeta_1$ | $-\psi(\theta_1-\theta_0)$ |
| $\pi$ | $0$ | $1$ | $0$ | $\gamma_2$ |
| $\pi k^{ME}$ | $-\theta_2$ | $0$ | $0$ | $-\psi\theta_2$ |
| $m$ | $0$ | $0$ | $-1$ | $-\gamma_3$ |
| $nrs$ | $0$ | $0$ | $\zeta_2$ | $0$ |

---

## 4a. The Full Alpha Matrix

Rows = variables, columns = ECTs. Maintained zeros in brackets $[0]$. Testable marked $[0^*]$.

$$\alpha^{CL} = \begin{pmatrix} \alpha_{y,1} & \alpha_{y,2} & \alpha_{y,3} & \alpha_{y,4} \\ [0] & [0] & [0] & \alpha_{k^{NR},4} \\ \alpha_{k^{ME},1} & \alpha_{k^{ME},2} & \alpha_{k^{ME},3} & \alpha_{k^{ME},4} \\ \alpha_{\pi,1} & \alpha_{\pi,2} & [0] & \alpha_{\pi,4} \\ [0] & [0] & [0] & [0] \\ \alpha_{m,1} & [0] & \alpha_{m,3} & \alpha_{m,4} \\ [0^*] & \alpha_{nrs,2} & [0] & \alpha_{nrs,4} \end{pmatrix}$$

| Variable | ECT1 ($\hat\mu$) | ECT2 (Phillips) | ECT3 (Import) | ECT4 (Goods mkt) |
|---|---|---|---|---|
| $y_t$ | free | free | free | free |
| $k_t^{NR}$ | $[0]$ | $[0]$ | $[0]$ | free |
| $k_t^{ME}$ | free | free | free | free |
| $\pi_t$ | free | free | $[0]$ | free |
| $\pi_t k_t^{ME}$ | $[0]$ | $[0]$ | $[0]$ | $[0]$ |
| $m_t$ | free | $[0]$ | free | free |
| $nrs_t$ | $[0^*]$ | free | $[0]$ | free |

**Maintained zeros: 11** — from 28 to 17 free $\alpha$ elements.  
**Testable: 1** — $\alpha_{nrs,1}$ (procyclical conspicuous consumption hypothesis).

---

## 4a-ii. The Full Gamma Matrix

The short-run propagation matrix $\Gamma_i$ is $n \times n = 7 \times 7$. Each element $(\Gamma_i)_{jk}$ is the coefficient on $\Delta X_{k,t-i}$ in the equation for $\Delta X_{j,t}$.

**Restriction principle:** single state variables propagate freely in the short run. The interaction term $\pi_t k_t^{ME}$ is excluded in both directions — row 5 (the interaction equation has no short-run dynamics beyond its components) and column 5 (lagged interaction carries no independent predictive content).

$$\Gamma_i^{CL} = \begin{pmatrix} \gamma^i_{y,y} & \gamma^i_{y,kNR} & \gamma^i_{y,kME} & \gamma^i_{y,\pi} & 0 & \gamma^i_{y,m} & \gamma^i_{y,nrs} \\ \gamma^i_{kNR,y} & \gamma^i_{kNR,kNR} & \gamma^i_{kNR,kME} & \gamma^i_{kNR,\pi} & 0 & \gamma^i_{kNR,m} & \gamma^i_{kNR,nrs} \\ \gamma^i_{kME,y} & \gamma^i_{kME,kNR} & \gamma^i_{kME,kME} & \gamma^i_{kME,\pi} & 0 & \gamma^i_{kME,m} & \gamma^i_{kME,nrs} \\ \gamma^i_{\pi,y} & \gamma^i_{\pi,kNR} & \gamma^i_{\pi,kME} & \gamma^i_{\pi,\pi} & 0 & \gamma^i_{\pi,m} & \gamma^i_{\pi,nrs} \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 \\ \gamma^i_{m,y} & \gamma^i_{m,kNR} & \gamma^i_{m,kME} & \gamma^i_{m,\pi} & 0 & \gamma^i_{m,m} & \gamma^i_{m,nrs} \\ \gamma^i_{nrs,y} & \gamma^i_{nrs,kNR} & \gamma^i_{nrs,kME} & \gamma^i_{nrs,\pi} & 0 & \gamma^i_{nrs,m} & \gamma^i_{nrs,nrs} \end{pmatrix}$$

| Equation $\backslash$ Regressor | $\Delta y$ | $\Delta k^{NR}$ | $\Delta k^{ME}$ | $\Delta\pi$ | $\Delta(\pi k^{ME})$ | $\Delta m$ | $\Delta nrs$ |
|---|---|---|---|---|---|---|---|
| $\Delta y_t$ | free | free | free | free | $[0]$ | free | free |
| $\Delta k_t^{NR}$ | free | free | free | free | $[0]$ | free | free |
| $\Delta k_t^{ME}$ | free | free | free | free | $[0]$ | free | free |
| $\Delta\pi_t$ | free | free | free | free | $[0]$ | free | free |
| $\Delta(\pi k^{ME})_t$ | $[0]$ | $[0]$ | $[0]$ | $[0]$ | $[0]$ | $[0]$ | $[0]$ |
| $\Delta m_t$ | free | free | free | free | $[0]$ | free | free |
| $\Delta nrs_t$ | free | free | free | free | $[0]$ | free | free |

**Free elements:** $6 \times 6 = 36$ per $\Gamma_i$. **Restrictions:** $7 + 7 - 1 = 13$ zeros per lag. Scales linearly: $K-1$ lags → $13(K-1)$ total $\Gamma$ restrictions.

**Economic content of key off-diagonal blocks in the free $6\times6$:**

| Entry | Content |
|---|---|
| $\gamma^i_{kME,\pi}$ | Distribution drives machinery investment short-run — intensive margin mechanization echo |
| $\gamma^i_{kNR,y}$ | Output drives infrastructure investment — extensive margin accelerator |
| $\gamma^i_{m,kME}$ | Machinery accumulation drives import propensity short-run — Tavares channel dynamics |
| $\gamma^i_{m,nrs}$ | NRS dynamics drive import propensity — Palma-Marcel consumption drain echo |
| $\gamma^i_{\pi,y}$ | Output drives distribution — utilization-Phillips short-run transmission |
| $\gamma^i_{nrs,\pi}$ | Distribution drives NRS — surplus available for luxury consumption |
| $\gamma^i_{y,m}$ | Import propensity drives output — leakage compresses multiplier short-run |

**Note on $n_t$ in $\Phi D_t$:** labor force growth $n_t$ enters the deterministic block, not $\Gamma_i$. It affects the short-run adjustment speeds as a strictly exogenous $I(0)$ variable — it shifts the intercept of each equation in the short-run block without being part of the endogenous propagation dynamics.

---



```r
# ============================================================
# CHILE CVAR — Structural Identification
# State vector: X = (y, k_NR, k_ME, pi, pi_kME, m, nrs)
# Dimension: n=7 variables, r=4 cointegrating vectors
# ============================================================

library(urca)

# ------------------------------------------------------------
# Step 1: Construct state vector
# ------------------------------------------------------------
X <- cbind(y, k_NR, k_ME, pi, pi_kME, m, nrs)
# All variables in logs; m = M_t/Y_t (import propensity ratio)
# nrs = log(Pi_t - I_t) (non-reinvested surplus)

# ------------------------------------------------------------
# Step 2: Lag selection and rank test
# Use Saikkonen-Lütkepohl with small-sample correction
# ------------------------------------------------------------
K <- VARselect(X, lag.max = 3, type = "const")$selection["AIC(n)"]
jo <- ca.jo(X, type = "trace", ecdet = "const", K = K, spec = "longrun")
summary(jo)
# Prior: r=4. Test r=0,1,2,3,4 sequentially.
# If only r<=3 supported: revisit CV3/CV4 specification.

# ------------------------------------------------------------
# Step 3: H matrices for blrtest() — one per CV
#
# H encodes: beta_j = H_j * phi_j
# Rows = state vector slots (y, k_NR, k_ME, pi, pi_kME, m, nrs)
# Cols = free parameters for that CV
# ------------------------------------------------------------

# CV1: beta_1 = (1, -theta0, -(theta1-theta0), 0, -theta2, 0, 0)
# Free params: theta0, delta (= theta1-theta0), theta2  [3 free]
H_CV1 <- matrix(c(
  # theta0  delta   theta2
     0,      0,      0,     # y:      normalized to 1
     1,      0,      0,     # k_NR:   -theta0
     0,      1,      0,     # k_ME:   -(theta1-theta0)
     0,      0,      0,     # pi:     restricted to 0
     0,      0,      1,     # pi_kME: -theta2
     0,      0,      0,     # m:      restricted to 0
     0,      0,      0      # nrs:    restricted to 0
), nrow = 7, ncol = 3, byrow = TRUE)

# CV2: beta_2 = (rho2, -rho2*theta0, -rho2*delta, 1, 0, 0, 0)
# Cross-eq: theta0, delta shared from CV1
# Free params: rho1, rho2  [2 free after cross-eq]
# theta0_hat and delta_hat extracted from CV1 first
H_CV2 <- matrix(c(
  # rho2           rho1
     0,             0,      # y:      = rho2 (imposed via cross-eq)
    -theta0_hat,    0,      # k_NR:   = -rho2*theta0
    -delta_hat,     0,      # k_ME:   = -rho2*delta
     0,             0,      # pi:     normalized to 1
     0,             0,      # pi_kME: restricted to 0
     0,             0,      # m:      restricted to 0
     0,            -1       # nrs:    restricted to 0 / const = -rho1
), nrow = 7, ncol = 2, byrow = TRUE)
# Note: theta0_hat, delta_hat are extracted from CV1 estimates
# in a first-pass estimation before constructing H_CV2

# CV3: beta_3 = (0, 0, zeta1, 0, 0, -1, zeta2)
# Free params: zeta1, zeta2  [2 free]
H_CV3 <- matrix(c(
  # zeta1   zeta2
     0,      0,     # y:      restricted to 0
     0,      0,     # k_NR:   restricted to 0
     1,      0,     # k_ME:   zeta1 (free)
     0,      0,     # pi:     restricted to 0
     0,      0,     # pi_kME: restricted to 0
     0,      0,     # m:      normalized to -1
     0,      1      # nrs:    zeta2 (free)
), nrow = 7, ncol = 2, byrow = TRUE)

# CV4: beta_4 = (1, -psi*theta0-lambda, -psi*delta, gamma2, -psi*theta2, -gamma3, 0)
# Cross-eq: theta0, delta, theta2 shared from CV1
# Free params: psi, lambda, gamma2, gamma3 (+gamma0 constant)  [5 free]
H_CV4 <- matrix(c(
  # psi              lambda    gamma2    gamma3    gamma0
     0,               0,        0,        0,        0,      # y: normalized to 1
    -theta0_hat,     -1,        0,        0,        0,      # k_NR: -psi*theta0 - lambda
    -delta_hat,       0,        0,        0,        0,      # k_ME: -psi*delta
     0,               0,        1,        0,        0,      # pi: gamma2
    -theta2_hat,      0,        0,        0,        0,      # pi_kME: -psi*theta2
     0,               0,        0,       -1,        0,      # m: -gamma3
     0,               0,        0,        0,        0       # nrs: restricted to 0
), nrow = 7, ncol = 5, byrow = TRUE)
# Note: theta0_hat, delta_hat, theta2_hat from CV1 estimates

# ------------------------------------------------------------
# Step 4: Joint structural identification
# ------------------------------------------------------------
H_list <- list(H_CV1, H_CV2, H_CV3, H_CV4)
vecm_restricted <- blrtest(jo, H = H_list, r = 4)
summary(vecm_restricted)
# LR statistic ~ chi-sq(df) where df = overidentifying restrictions (11)

# ------------------------------------------------------------
# Step 5: Alpha restrictions
# Indicator matrix: 1 = free, 0 = maintained zero, NA = testable
# ------------------------------------------------------------

# Alpha indicator matrix (7 variables x 4 ECTs)
alpha_indicators <- matrix(c(
# ECT1  ECT2  ECT3  ECT4
    1,    1,    1,    1,   # y
    0,    0,    0,    1,   # k_NR     [maintained zeros on ECT1-3]
    1,    1,    1,    1,   # k_ME
    1,    1,    0,    1,   # pi       [maintained zero on ECT3]
    0,    0,    0,    0,   # pi_kME   [full row: maintained zeros]
    1,    0,    1,    1,   # m        [maintained zero on ECT2]
   NA,    1,    0,    1    # nrs      [testable on ECT1; maintained zero on ECT3]
), nrow = 7, ncol = 4, byrow = TRUE,
dimnames = list(
  c("y", "k_NR", "k_ME", "pi", "pi_kME", "m", "nrs"),
  c("ECT1", "ECT2", "ECT3", "ECT4")
))

# Implement alpha restrictions via restricted VECM
# cajorls() with restriction matrices or manual GLS with constraint
# For sequential LR testing of alpha[nrs, ECT1]:
#   H0: alpha_nrs1 = 0 (maintained zero)
#   H1: alpha_nrs1 != 0 (procyclical conspicuous consumption)
# Critical value from chi-sq distribution at each elimination step
# NOT pre-specified at asymptotic normal threshold

# ------------------------------------------------------------
# Step 6: Extract structural objects
# ------------------------------------------------------------
beta_hat    <- vecm_restricted@V         # 7 x 4 beta matrix
theta0_hat  <- -beta_hat[2, 1]
delta_hat   <- -beta_hat[3, 1]           # = theta1 - theta0
theta2_hat  <- -beta_hat[5, 1]
mu_hat_CL   <- X %*% beta_hat[, 1]      # CV1: confinement of demand
rho2_hat    <-  beta_hat[1, 2]
rho1_hat    <- -beta_hat[7, 2]           # from nrs slot in CV2
zeta1_hat   <-  beta_hat[3, 3]
zeta2_hat   <-  beta_hat[7, 3]
psi_hat     <- -beta_hat[3, 4] / delta_hat   # recover psi from k_ME slot
lambda_hat  <- -beta_hat[2, 4] - psi_hat * theta0_hat  # recover lambda
gamma2_hat  <-  beta_hat[4, 4]
gamma3_hat  <- -beta_hat[6, 4]
```



## 5. First-Difference Lag Restriction Matrix ($\Gamma_i$)

The short-run propagation matrix $\Gamma_i$ governs how lagged first differences $\Delta X_{t-i}$ enter each equation. The restriction principle mirrors the $\alpha$ matrix: single state variables are included; the interaction term $\pi_t k_t^{ME}$ is excluded from the short-run dynamics in both directions.

### Restriction Principle

**Row restriction — interaction equation has no short-run dynamics:**

The equation for $\Delta(\pi_t k_t^{ME})$ is not explained by any lagged $\Delta X_{t-i}$. Its short-run fluctuations are entirely determined by the dynamics of its components $\Delta\pi_t$ and $\Delta k_t^{ME}$, which already have their own equations. Row 5 of $\Gamma_i$ = 0.

**Column restriction — lagged interaction does not enter any equation:**

$\Delta(\pi_{t-i} k_{t-i}^{ME})$ carries no information beyond what $\Delta\pi_{t-i}$ and $\Delta k_{t-i}^{ME}$ already contain. Column 5 of $\Gamma_i$ = 0.

Together: 7 (row) + 7 (column) - 1 (corner double-counted) = **13 restrictions per $\Gamma_i$ matrix.**

### Restricted $\Gamma_i$ Structure

$$\Gamma_i^{CL} = \begin{pmatrix} * & * & * & * & 0 & * & * \\ * & * & * & * & 0 & * & * \\ * & * & * & * & 0 & * & * \\ * & * & * & * & 0 & * & * \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 \\ * & * & * & * & 0 & * & * \\ * & * & * & * & 0 & * & * \end{pmatrix}$$

Rows/columns: $(y,\; k^{NR},\; k^{ME},\; \pi,\; \pi k^{ME},\; m,\; nrs)$. Free elements: $6\times6 = 36$ per $\Gamma_i$.

### R Implementation

```r
# Gamma restriction indicator: 1=free, 0=restricted
# Row 5 (pi_kME equation) and column 5 (lagged pi_kME) all zero
Gamma_indicator_CL <- matrix(c(
# y_lag  kNR_lag  kME_lag  pi_lag  pikME_lag  m_lag  nrs_lag
    1,      1,       1,       1,       0,        1,      1,   # Dy
    1,      1,       1,       1,       0,        1,      1,   # Dk_NR
    1,      1,       1,       1,       0,        1,      1,   # Dk_ME
    1,      1,       1,       1,       0,        1,      1,   # Dpi
    0,      0,       0,       0,       0,        0,      0,   # Dpi_kME [full row zero]
    1,      1,       1,       1,       0,        1,      1,   # Dm
    1,      1,       1,       1,       0,        1,      1    # Dnrs
), nrow=7, ncol=7, byrow=TRUE,
dimnames=list(
  c("Dy","Dk_NR","Dk_ME","Dpi","Dpi_kME","Dm","Dnrs"),
  c("Dy_lag","Dk_NR_lag","Dk_ME_lag","Dpi_lag","Dpi_kME_lag","Dm_lag","Dnrs_lag")
))
# Each additional lag imposes 13 additional restrictions (same structure)
```

---

## 6. System Complexity — Structural vs. Unrestricted Parameter Count

This section compares the total parameter space under structural restriction against the unrestricted VECM, quantifying the degree of overidentification and the degrees of freedom for the joint LR test.

### Counting Convention

- **Unrestricted total:** all elements in each matrix block free, before any restriction. $\beta$ includes $n_{eff} \times r$ elements where $n_{eff}=8$ (7 variables + restricted constant in $\beta$).
- **Structural free:** parameters estimated freely under the structural model.
- **Normalizations:** $r=4$ (one per CV) — not overidentifying.
- **Overidentification df:** restrictions beyond normalization — degrees of freedom for the joint LR test.

### Chile Parameter Count ($n=7$, $r=4$, $n_{eff}=8$, $L$ lags)

| Block | Unrestricted elements | Structural free | Overidentifying restrictions |
|---|---|---|---|
| $\beta$ | $8\times4=32$ | 13 ($\theta_0,\delta,\theta_2,\varrho_1,\varrho_2,\zeta_0,\zeta_1,\zeta_2,\gamma_0,\psi,\lambda,\gamma_2,\gamma_3$) | $32-13-4_{norm}=15$ |
| $\alpha$ | $7\times4=28$ | 17 (maintained zeros imposed) | 11 |
| $\Gamma_i$ (per lag) | $7\times7=49$ | 36 (interaction row+col=0) | 13 |
| **Total ($L=1$)** | **109** | **66** | **39** |
| **Total ($L=2$)** | **158** | **102** | **52** |

**Joint LR test df:** 39 at $L=1$; increases by 13 per additional lag.

### Overidentification by Source (Chile)

| Source | Block | Restrictions | Economic content |
|---|---|---|---|
| $\theta_0$, $\delta$, $\theta_2$ shared across CV1, CV2, CV4 | $\beta$ | 5 cross-eq | MPF elasticities govern capacity manifold, Phillips curve, and goods market jointly |
| Zero restrictions in $\beta$ | $\beta$ | 10 | Slots excluded on theoretical grounds (e.g., $\pi$ in CV1, $m$ in CV1/CV2, etc.) |
| $\pi_t k_t^{ME}$ row in $\alpha$ | $\alpha$ | 4 | Interaction has no independent short-run adjustment |
| Other maintained zeros in $\alpha$ | $\alpha$ | 7 | Infrastructure slow-moving, import propensity causal chain, NRS direction |
| $\pi_t k_t^{ME}$ row+col in $\Gamma_i$ | $\Gamma_i$ | 13 per lag | Interaction has no independent short-run propagation |

### Comparison with Unrestricted System

$$\underbrace{109}_{\text{unrestricted}} \xrightarrow{\text{39 restrictions}} \underbrace{66}_{\text{structural}} + \underbrace{4}_{\text{normalizations}} + \underbrace{39}_{\text{over-ID test}}$$

**Sample:** Determined by the limiting series in the Stage A estimation pipeline — cross-reference the data estimation pipeline rule above. The binding constraint is the variable with shortest consistent real-terms coverage across the full state vector. The observation count is confirmed from the pipeline audit on the limiting series; it exceeds the earlier 60-observation placeholder and spans the maximum available real-terms data.

| System | Parameters | Observations | Obs/param ratio |
|---|---|---|---|
| Unrestricted ($L=1$) | 109 | $T$ (pipeline TBC) | $T/109$ |
| Structural ($L=1$) | 66 | $T$ | $T/66$ |
| Structural ($L=1$, after sequential $\alpha$ elimination) | ~53 | $T$ | $T/53$ |

**The unrestricted VECM is not estimable regardless of $T$.** With 109 parameters and a 7-variable system, the unrestricted model is severely under-identified for any annual Chilean sample of reasonable length. The structural restrictions are not a choice — they are a requirement. The 39 overidentifying restrictions do double duty: they make estimation feasible AND provide a structural test of the theoretical framework.

### Center-Periphery Complexity Comparison

| | US | Chile |
|---|---|---|
| State vector dimension | 4 | 7 |
| Cointegrating rank | 3 | 4 |
| Unrestricted params ($L=1$) | 43 | 109 |
| Structural params ($L=1$) | 26 | 66 |
| Overidentifying restrictions | 14 | 39 |
| Joint LR test df | $\chi^2(14)$ | $\chi^2(39)$ |
| Stage A sample | 1929–present (~94 obs) | Pipeline TBC (max real-terms) |
| Stage B sample | Fordist window 1945–1978 | Deflator-reliable ~1960 onward |
| Obs/structural param (Stage A) | ~3.6 | $T/66$ (TBC) |

The US is well-identified under the structural restriction at Stage A. Chile's obs/param ratio depends on the confirmed pipeline sample — the sequential $\alpha$ elimination protocol remains the mechanism by which the system becomes estimable regardless of the final $T$.

---

> **Note — Notation:** $\zeta$ is used for CV3 free parameters throughout to avoid collision with the loading matrix $\alpha$ in the standard VECM representation $\Delta X_t = \alpha\beta' X_{t-1} + \ldots$



## 5a. Note on the Goods Market Equilibrium Abstraction

It is acknowledged that in a monetary economy the goods market equilibrium condition as a strict equality — investment equals saving net of external leakage — does not hold in general. In a monetary production economy, investment is financed by credit creation prior to saving, and the equality $I = S + (X - M)$ is an ex-post accounting identity, not an ex-ante behavioral condition.

The CV4 equilibrium is retained not because the economy is assumed to satisfy it continuously, but because its closure is theoretically indispensable. Without the equilibrium abstraction, the structural role of leakages — consumption propensities, saving rates, import propensities — and the goods market imbalances they generate cannot be formally identified. It is precisely the systematic deviation from this equilibrium that reveals the structural content of the peripheral constraint: the inability to close the goods market internally because the import leakage and the consumption drain absorb the surplus that would otherwise finance reproduction. The cointegrating combination $ECT_4$ is not interpreted as a temporary disequilibrium that corrects — it is interpreted as a persistent structural gap whose dynamics are the object of identification. We could not understand the relation between distribution, leakage, and accumulation without the abstraction of equilibrium existence, even as we assert that the equilibrium itself is never realized.

---

## 6. Short-Run Block — Deterministic Components ($\Phi D_t$)

**Only $n_t$ enters $\Phi D_t$.**

The structural break dummies (1973, 1982, 1990) are excluded. The confinement of the model — the cointegrating structure, the rank, and the loading matrix — should tell the history of regime changes endogenously. Imposing break dummies a priori consumes degrees of freedom unnecessarily and preempts what the cointegration structure can identify on its own. The 1974 Phillips curve regime change is handled in the extension block (§10a) via the Johansen-Mosconi-Nielsen test — not as a maintained restriction in $\Phi D_t$.

**$n_t$ pre-test — stage gate before estimation:**

$n_t = \dot{N}/N$ must be confirmed $I(0)$ before entering $\Phi D_t$. Population growth rates are theoretically bounded and should be stationary, but demographic transition series can exhibit persistent trending behavior in finite samples.

| Pre-test outcome | Action |
|---|---|
| ADF and KPSS both confirm $I(0)$ | $n_t$ enters $\Phi D_t$ in both $\Delta y_t$ and $\Delta\pi_t$ equations |
| ADF fails to reject $I(1)$ | Use $\Delta n_t$ if interpretation survives differencing; otherwise exclude entirely |
| $n_t$ excluded | Let model confinement identify labor market effects through CV2 Goodwin mechanism alone |

---

## 7. Estimation Strategy — Two-Stage Protocol for Overparametrized Baseline

The Chilean 7-variable system is at the boundary of estimability. The correct approach is a two-stage protocol: first determine the cointegrating rank with a regularized but minimally restricted baseline; then impose the full structural identification conditional on the confirmed rank.

---

### Stage 1 — Rank Determination (Regularized Baseline)

**Objective:** Determine $r$ and recover the unrestricted $\hat\beta$ as starting values for structural identification. Stage 1 imposes only canonical and economically uncontroversial restrictions — no structural restrictions, no cross-equation constraints on $\theta$ or $\varrho$.

**Canonical restrictions (depart with these — no information loss):**

**Restriction 1 — Interaction in $\Gamma_i$:** Row 5 and column 5 of every $\Gamma_i$ = 0. 13 restrictions per lag. Justified by construction — $\Delta(\pi_t k_t^{ME})$ is not an independent short-run dynamic.

**Restriction 2 — Interaction in $\alpha$:** Row 5 of $\alpha$ = 0 (all 4 elements). Same justification — the interaction is a long-run structural object, not a short-run adjustment variable.

These two canonical restrictions remove $13 + 4 = 17$ free parameters at $L=1$, reducing Stage 1 from 109 to 92 free parameters.

**Additional regularization — apply in sequence before rank test:**

**A — BIC lag selection (first):**

With $n=7$ and $T \approx 80$–100, AIC systematically overfits the lag order. Each additional lag adds 36 free $\Gamma$ parameters — approximately half the sample size. Use BIC. It will typically select $L=1$; if $L=2$ is selected, residual autocorrelation tests must confirm the need.

```r
lag_sel <- VARselect(X, lag.max = 3, type = "const")
K_BIC <- lag_sel$selection["SC(n)"]  # BIC = SC in VARselect; K = lag order in levels VAR
# K=2 means L=1 (one first-difference lag) — the reference specification
# K=3 means L=2 (two first-difference lags) — robustness only
# K=1 means L=0 — eliminates short-run block, NEVER use
# Default to K_BIC; extend only if Portmanteau test rejects at K_BIC
```

**B — Conditional VECM on weakly exogenous candidates (second):**

From the maintained $\alpha$ restrictions, $k_t^{NR}$ only responds to ECT4, making it structurally close to weak exogeneity. Similarly $nrs_t$ only responds to ECT2 and ECT4. Test weak exogeneity formally:

```r
# LR test: H0: alpha[k_NR, ECT1] = alpha[k_NR, ECT2] = alpha[k_NR, ECT3] = 0
# chi-sq(3) — fail to reject: condition on k_NR (remove from endogenous system)
# Same test for nrs: H0: alpha[nrs, ECT1] = alpha[nrs, ECT3] = 0 (chi-sq(2))
```

If both $k_t^{NR}$ and $nrs_t$ are confirmed weakly exogenous at Stage 1, condition on them — reducing the endogenous system from 7 to 5 variables. The Johansen rank test on the 5-variable conditional system has dramatically higher power. This is the Pesaran-Shin (1994) conditional VECM approach.

**C — Block restriction on $\Gamma_i$ (third):**

The state vector partitions into a **real block** $(y, k^{NR}, k^{ME})$ and an **external block** $(m, nrs)$. Short-run changes in real capital plausibly do not instantaneously affect the import propensity or NRS within the same annual period, and vice versa. The transmission runs through error-correction channels, not through same-year $\Gamma_i$ propagation. Set the off-diagonal cross-blocks (real $\to$ external and external $\to$ real) in $\Gamma_i$ to zero — 8 additional restrictions per lag:

```r
# Additional Gamma zeros (beyond interaction row/col):
# k_NR and k_ME columns in m and nrs equation rows
# m and nrs columns in k_NR and k_ME equation rows
# Keep: y connects both blocks; pi connects both blocks
```

**D — One first-difference lag baseline ($L=1$, i.e. $K=2$ in `ca.jo()`) as reference:**

> **Notation:** Throughout this document, $L$ denotes the number of first-difference lag matrices in the VECM short-run block — equivalently, $K-1$ where $K$ is the lag order of the levels VAR passed to `ca.jo(K=...)`. $L=1$ means **one $\Gamma_i$ matrix** exists in the system — the short-run memory block is present and operative. $L=0$ would eliminate the short-run block entirely, which is never proposed and would be econometrically unjustifiable. The parameter counts in the complexity section (109, 66, 39, etc.) are all at $L=1$ — one first-difference lag.

Declare $L=1$ ($K=2$) the reference specification. $L=2$ ($K=3$) is a robustness check only, triggered by residual autocorrelation in the $L=1$ residuals — not by prior preference. Each additional lag adds 36 free $\Gamma$ parameters at Stage 1 (after canonical restrictions), making $L=2$ estimable only if the Stage 1 conditional system has sufficient degrees of freedom.

### Stage 1 — Parameter Count After Regularization

| Step | Restrictions imposed | Free params |
|---|---|---|
| Unrestricted baseline ($L=1$) | — | 109 |
| + Canonical: interaction $\Gamma$ = 0 | 13 | 96 |
| + Canonical: interaction $\alpha$ = 0 | 4 | 92 |
| + Block diagonal $\Gamma$ (real/external) | 8 | 84 |
| + Condition on $k^{NR}$ (if WE confirmed) | removes 1 equation ($4+7=11$ params) | 73 |
| + Condition on $nrs$ (if WE confirmed) | removes 1 equation ($4+7=11$ params) | 62 |

With $T \approx 80$–100 and ~62–84 free parameters depending on conditioning: ratio $\approx 1.0$–1.6. Small-sample corrections to the trace statistic (Reinsel-Ahn or Johansen-Juselius) are required throughout.

---

### Stage 2 — Structural Identification (Conditional on $\hat{r}$)

Given rank $\hat{r}$ from Stage 1:

1. Impose full structural $\beta$ restriction (CV1–CV4) via `blrtest()`
2. Impose maintained $\alpha$ zeros (11 restrictions)
3. Joint LR test — $\chi^2(39)$ at $L=1$
4. Sequential $\alpha$ elimination on free loadings
5. Extension block: JMN level shift and Hansen-Johansen slope constancy on CV2

**If $\hat{r} < 4$ at Stage 1:** Structural identification must be revised. Priority order: CV1 (capacity manifold) → CV2 (Phillips) → CV3 (import propensity) → CV4 (goods market). CV3 and CV4 may be deferred to future research if rank only supports $r \leq 2$.

---



Before Chilean estimation, US system is estimated and two objects extracted. Fixed for all subsequent steps — not re-estimated in Chilean stage.

$$\boxed{\hat\theta^{US}, \qquad \hat u_t^{US} = y_t^{US} - \hat\theta^{US} k_t^{US}}$$

- $\hat\theta^{US}$: enters §2.10 structural comparison as center-side coordinate of core-periphery mechanization gap. Does NOT enter Chilean Stage A.
- $\hat u_t^{US}$: does NOT enter Stage A. Appears in Stage B as robustness control (B3). Primary downstream role: Ch3 Vietnam War event study via copper price channel.

**Why $\hat u_t^{US}$ excluded from Stage A:** including it would absorb the hegemonic transmission channel into the structural identification, contaminating $\hat\theta^{CL}$ and foreclosing Ch3's causal identification.

---

## 8. Outputs to Extract After Estimation

| Object | Formula | Used in |
|---|---|---|
| $\hat\theta_0, \hat\theta_1-\hat\theta_0, \hat\theta_2$ | CV1 coefficients | Stage B, CV2/CV4 imposition |
| $\hat\mu_t^{CL} = \beta_1'X_t$ | Structurally identified confinement of demand — system-wide | Stage B, §2.10 comparison |
| $\hat\varrho_1, \hat\varrho_2$ | CV2 coefficients | Distributional cycle diagnostics |
| $\hat\alpha_1, \hat\alpha_2$ | CV3 coefficients | Kaldor-ECLA fault line |
| $\hat\gamma_1, \hat\gamma_2, \hat\gamma_3, \hat\lambda$ | CV4 coefficients | Goods market, Tavares amplitude |
| $\hat\lambda/\hat\theta_2$ | Implicit $\bar{b}$ diagnostic | Structural limitation check |
| Asymmetric $\alpha_{y,3}$ | Loading on $ECT_3$ in $\Delta y_t$ | Sudden stop identification |

---

## 9. Short-Run Restrictions — Loading Matrix $\alpha$

The $\alpha$ matrix is $7 \times 4 = 28$ elements. Theoretically motivated zeros reduce estimation burden without sacrificing identification. The strategy: impose maintained restrictions that are theoretically overdetermined, leave ambiguous cases as testable restrictions, and refine recursively against statistical significance post-estimation.

### 9.1 The $\alpha$/$\beta$ Partition as Variance Allocation

Every restriction imposed on $\alpha$ or $\beta$ is simultaneously three things:

**A theoretical claim** — about where the economic mechanism operates temporally. Placing $\pi_t k_t^{ME}$ entirely in $\beta$ with $\alpha_{\pi k^{ME},\cdot} = 0$ asserts that the distribution-technique interaction has no independent short-run adjustment dynamics. Its variance is generated by the regime-level relationship between distribution and mechanization, not by cycle-frequency error-correction.

**A variance allocation decision** — you are choosing where to study the variance of each variable. Short-run fluctuations in $\pi_t k_t^{ME}$ are entirely explained by the dynamics of its components $\pi_t$ and $k_t^{ME}$, which already have their own adjustment equations. There is no residual variance to study in the $\alpha$ block for the interaction term.

**A degrees-of-freedom decision** — theoretically motivated restrictions are not a cost, they are a gain. Each zero in $\alpha$ is a testable overidentifying restriction that simultaneously reduces estimation burden and sharpens identification of the free parameters. The discipline of theory is what allows a 7-variable system to be identified on a finite annual sample — regardless of whether that sample is 60, 85, or 120 observations.

### 9.2 Proposed $\alpha$ Restrictions — Variable by Variable

**$y_t$:** Responds to all four ECTs. No zeros proposed — output is the primary adjusting variable for all structural disequilibria.

**$k_t^{NR}$:** Infrastructure is slow-moving, determined at the extensive margin. Only ECT4 (goods market disequilibrium) should drive infrastructure investment. Does not respond to utilization gaps (Margin I doesn't build plants), distributional ECT (distribution doesn't drive infrastructure directly), or import propensity ECT (infrastructure is domestically producible).
Proposed: $\alpha_{k^{NR},1} = \alpha_{k^{NR},2} = \alpha_{k^{NR},3} = 0$ — **maintained**

**$k_t^{ME}$:** The intensive margin variable — responds to all structural forces. No zeros proposed.

**$\pi_t$:** Responds to utilization (Goodwin), own Phillips locus, and goods market profitability. Does NOT respond to the import propensity attractor directly — that link runs through NRS as the intermediate variable, not through the profit share responding to ECT3 directly.
Proposed: $\alpha_{\pi,3} = 0$ — **maintained**

**$\pi_t k_t^{ME}$:** Constructed interaction with no independent behavioral content as an adjusting variable. Its adjustment is entirely determined by the dynamics of $\pi_t$ and $k_t^{ME}$, which already have their own equations. Including a full row of free $\alpha$ loadings estimates redundant parameters.
Proposed: entire row = 0 — **maintained** — this is the single largest degree-of-freedom gain (4 parameters freed). Methodologically: the distribution-technique interaction fully loads to the long-run $\beta$ structure. This is theoretically strong but plausible, and methodologically solid.

**$m_t$:** Responds to utilization (high $\hat\mu_t$ pulls in imports), its own structural attractor (ECT3), and goods market conditions (ECT4). Does NOT respond to the distributional ECT directly — the link from distribution to imports runs through NRS. Setting $\alpha_{m,2} = 0$ is not an approximation: distribution affects imports through NRS as the intermediate variable, and NRS has its own adjustment equation.
Proposed: $\alpha_{m,2} = 0$ — **maintained**

**$nrs_t$:** Responds to distributional disequilibrium (ECT2) and goods market profitability (ECT4). Does NOT respond to import propensity ECT3 — NRS is a determinant of import propensity in CV3, not a responder to it. The direction runs the other way.

$\alpha_{nrs,1}$: whether NRS responds to the utilization gap is **testable**. The null ($\alpha_{nrs,1} = 0$) says NRS is disciplined by distribution and profitability only. The alternative ($\alpha_{nrs,1} \neq 0$) is the **procyclical conspicuous consumption hypothesis**: ruling class accelerates luxury consumption directly during utilization booms, pulling the trigger on the forex drain precisely when the economy is most vulnerable to sudden stop. This amplifies the BoP constraint procyclically — a second dimension of class struggle in the periphery beyond the wage-profit split.

Proposed: $\alpha_{nrs,3} = 0$ — **maintained**; $\alpha_{nrs,1}$ — **testable**

### 9.3 Summary Table

| Variable | ECT1 | ECT2 | ECT3 | ECT4 | Zeros freed |
|---|---|---|---|---|---|
| $y_t$ | free | free | free | free | 0 |
| $k_t^{NR}$ | **0** | **0** | **0** | free | 3 |
| $k_t^{ME}$ | free | free | free | free | 0 |
| $\pi_t$ | free | free | **0** | free | 1 |
| $\pi_t k_t^{ME}$ | **0** | **0** | **0** | **0** | 4 |
| $m_t$ | free | **0** | free | free | 1 |
| $nrs_t$ | testable | free | **0** | free | 2 |
| **Total** | | | | | **11 maintained** |

**From 28 to 17 free $\alpha$ elements** — 39% reduction in loading parameters before touching the data.

### 9.4 Flags for Write-Up

**§2.9 / Robustness:** The procyclical conspicuous consumption hypothesis ($\alpha_{nrs,1} \neq 0$) as a testable implication of the overidentification structure. Future research: time-varying $\alpha_{nrs,1}$ across regimes — does the procyclical channel strengthen under liberalization (post-1975) when imported luxury goods become more accessible?

**§2.6 / Empirical strategy:** The $\alpha$/$\beta$ partition as a theoretically-grounded variance allocation strategy. The $\pi_t k_t^{ME}$ restriction as the motivating example of how granular structural interpretation generates degrees of freedom. The procyclical NRS test as the empirical payoff — where the overidentification structure is rich enough to test behavioral hypotheses about class struggle that go beyond the standard Goodwin framework.

---

## 10. Recursive Refinement Protocol for Free $\alpha$ Parameters

**Step 1 — Impose maintained restrictions:** set the 11 theoretically overdetermined zeros. Estimate the restricted VECM with 17 free $\alpha$ parameters.

**Step 2 — Extract test statistics:** obtain $t$-statistics and LR test statistics for all free loadings. Identify candidates for additional zero restrictions based on statistical insignificance.

**Step 3 — Sequential LR elimination:** for each candidate loading, test $\alpha_{ij} = 0$ via LR against the restricted model. Critical values are determined empirically from the test statistic distributions at each step — **not pre-specified at 1.96 or any other asymptotic normal threshold.** In a restricted VECM, test statistics for loading parameters do not follow standard normal distributions; the distribution depends on the cointegrating rank, the number of restrictions already imposed, and the normalization used. The elimination sequence proceeds from least to most economically motivated — retaining parameters where the cost of elimination is theoretically high regardless of statistical significance.

**Step 4 — Re-test the full system:** after each elimination round, re-run the joint LR test of the full restriction set. Each new zero imposed adds to the overidentification count and to the degrees of freedom available for inference on the remaining free parameters.

**Statistical insignificance in $\alpha$ is economically informative:** if $\hat\alpha_{m,1}$ is insignificant — import propensity doesn't respond to the utilization gap after conditioning on ECT3 and ECT4 — that's a structural finding: the direct utilization-import channel is weak relative to the structural attractor and goods market channels. The recursive elimination identifies which error-correction channels are economically operative, not just statistically detectable.

---

## 10a. Extension Block — Phillips Curve Regime Change Test (1974 onward)

> **Status: Extension — not maintained. To be tested after baseline identification.**

### Motivation

1974 marks the first full year of the Pinochet regime (coup: September 1973). The distributional implications are structural and institutional: labor repression, dissolution of collective bargaining, real wage compression, and wholesale transformation of the labor market. These events plausibly shift both the long-run distributional attractor ($\varrho_1$ — the structural power differential) and the Goodwin sensitivity ($\varrho_2$ — whether rising utilization still depletes the reserve army and pushes wages up under repression). The baseline CV2 imposes a single $\varrho_1$ and $\varrho_2$ across the full sample. This extension tests whether that restriction holds.

Note: the 1973 structural break dummy is already in $\Phi D_t$ as a short-run deterministic. This extension tests whether the break also affects the **cointegrating structure** of CV2 — the long-run distributional locus — not just the short-run dynamics.

---

### Test 1 — Level Shift in the Phillips Curve Intercept

**Question:** Does the long-run distributional attractor $\varrho_1$ shift permanently after 1974?

**Modified CV2:**

$$\pi_t = (\varrho_1 + \varrho_1^* D_t^{74}) - \varrho_2\hat\mu_t$$

where $D_t^{74} = \mathbb{1}[t \geq 1974]$.

**Structural content of $\varrho_1^*$:**

- $\varrho_1^* > 0$: the structural profit share floor rises after 1974 — labor repression raises capital's structural power permanently, independent of the utilization cycle. Workers lose the baseline distributive position they held during the Frei and Allende periods
- $\varrho_1^* < 0$: the structural profit share floor falls — paradoxically, if repression also suppresses investment (via political uncertainty, capital flight), the profit share anchor may fall despite labor being weaker

**The Chilean prior is strongly $\varrho_1^* > 0$:** Pinochet's labor reforms are structurally distribution-shifting, and the empirical record shows a dramatic upward shift in the profit share post-1973. The LR test formalizes this as a testable restriction rather than an assumed condition.

**Implementation:** $D_t^{74}$ enters as a restricted dummy in $\beta_2$ — it shifts the long-run equilibrium level of CV2, not just the short-run dynamics. **Johansen-Mosconi-Nielsen (1994)** broken intercept procedure, with modified critical values for the broken-mean case.

Extended $\beta_2$ on the augmented vector $(y,\; k^{NR},\; k^{ME},\; \pi,\; \pi k^{ME},\; m,\; nrs,\; \mathbf{1},\; D_t^{74})'$:

$$\beta_2^{extended} = (\varrho_2,\; -\varrho_2\theta_0,\; -\varrho_2(\theta_1-\theta_0),\; 1,\; 0,\; 0,\; 0,\; -\varrho_1,\; -\varrho_1^*)$$

**LR test:** $H_0: \varrho_1^* = 0$ vs $H_1: \varrho_1^* \neq 0$. One additional free parameter; df = 1.

---

### Test 2 — Slope Change in the Goodwin Sensitivity

**Question:** Does $\varrho_2$ — the utilization-distribution sensitivity — shift after 1974?

**Modified CV2:**

$$\pi_t = \varrho_1 - (\varrho_2 + \varrho_2^* D_t^{74})\hat\mu_t$$

**Structural content of $\varrho_2^*$:**

- $\varrho_2^* < 0$: the Goodwin slope weakens after 1974 — labor repression severs the utilization-distribution nexus. Rising utilization no longer depletes the reserve army and pushes wages up because the reserve army is structurally replenished by repression. The demand-distribution link is institutionally overridden
- $\varrho_2^* > 0$: the Goodwin slope strengthens — even under repression, high utilization generates distributional pressure (perhaps through informal channels or regime-internal conflicts over the surplus)

**The Chilean prior strongly favors $\varrho_2^* < 0$:** the Goodwin mechanism requires some degree of labor market tightening under demand expansion. Under institutional labor repression, that tightening is suppressed. The distributive cycle becomes milder post-transition (as observed in the data), suggesting $|\varrho_2 + \varrho_2^*| < |\varrho_2|$ in the post-1974 period.

**Implementation:** $D_t^{74} \times \hat\mu_t$ is $I(0)$ (product of dummy and stationary CV1 object) — it cannot enter the $I(1)$ cointegrating vector. Identified via **Hansen-Johansen (1999) parameter constancy test** on $\varrho_2$ across the sample, using 1974 as candidate break. Alternative: split-sample estimation pre/post 1974 and compare $\hat\varrho_2^{pre}$ vs $\hat\varrho_2^{post}$.

---

### Combined Test — Full Phillips Curve Regime Change

Both shifts simultaneously: $\varrho_1$ level shift (LR test) + $\varrho_2$ slope change (Hansen-Johansen constancy). The joint test provides the complete structural stability assessment of the distributional attractor across the Pinochet break.

**Comparison with the US (1974):** Both countries experience the 1974 break but through different mechanisms. In the US it is a demand-side shock (stagflation, end of Bretton Woods). In Chile it is a supply-side institutional shock (labor repression). The sign patterns of $\varrho_1^*$ and $\varrho_2^*$ should differ accordingly — this is a structural finding about the nature of the center-periphery distributional break.

| Sign pattern | US reading | Chile reading |
|---|---|---|
| $\varrho_1^* > 0$, $\varrho_2^* < 0$ | Stagflation raises profit floor; demand-distribution link weakens | Repression raises profit floor; Goodwin mechanism institutionally severed |
| $\varrho_1^* > 0$, $\varrho_2^* > 0$ | Profit floor rises; distribution more demand-sensitive | Profit floor rises; Goodwin persists despite repression |
| $\varrho_1^* < 0$, $\varrho_2^* < 0$ | Profit floor falls; demand-distribution link weakens | Capital flight compresses profits; Goodwin suppressed |

### R Implementation Sketch

```r
# Extension: regime change test on CV2 (1974 breakpoint)
# Applies to both US and Chile CVAR scripts

# Step 1 — Construct break dummy
D74 <- as.integer(time(X) >= 1974)
X_ext <- cbind(X, D74)   # augmented state vector

# Step 2 — Level shift: restricted dummy in beta_2 (JMN procedure)
# Augment state vector with D74
# Restrict D74 to enter only beta_2 column with coefficient -varrho1_star
# Use Johansen-Mosconi-Nielsen (1994) critical values (broken mean case)
jo_ext <- ca.jo(X_ext, type="trace", ecdet="const", K=K, spec="longrun")

# Construct H_CV2_extended with additional row for D74 slot
# H_CV2_ext is (n+1) x 2 with D74 slot = (0, -1) for rho1_star
H_CV2_ext <- rbind(H_CV2, c(0, -1))  # append D74 row
# LR test: varrho1_star = 0
# chi-sq(1) with JMN-corrected critical values

# Step 3 — Slope change: Hansen-Johansen constancy test
# Test H0: rho2 constant across [1929, 2022] (US) or [T_start, 2019] (Chile)
# Candidate break: 1974
# Use parameter constancy test from Hansen (1992) or rolling Johansen
# Report sup-LR statistic and compare against Hansen-Johansen (1999) Table 1

# Manual split-sample comparison:
rho2_pre  <- estimate_CV2(X[time(X) <  1974, ])  # pre-1974 rho2
rho2_post <- estimate_CV2(X[time(X) >= 1974, ])  # post-1974 rho2
# Compare: rho2_post - rho2_pre = varrho2_star (approximate)
```

---



1. Condition number check on 7-variable system before Johansen
3. $\pi_t^{CL}$ series splice: BCCh → Astorga (2023)
4. $nrs_t$ construction: confirm $\Pi_t$ and $I_t$ at consistent frequency and coverage

---

*Draft 2026-04-03. CV1 and CV2 locked. CV3 and CV4 locked pending Diego final approval. Supersedes empirical_strategy_peripheral_Ch2_v3.md on state vector and CV structure.*
