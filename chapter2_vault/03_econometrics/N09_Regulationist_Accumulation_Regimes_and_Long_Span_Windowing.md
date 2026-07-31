---
type: econometrics
status: active
depends_on:
  - chapter2_vault/03_econometrics/N05_Capital_Integration_Order_Comprehensive_Audit.md
  - chapter2_vault/03_econometrics/N06_Kappa_Identification_and_IMOLS_Exogeneity_Paradox.md
  - chapter2_vault/03_econometrics/N07_Small_Sample_Validation_and_Resampling_Protocol.md
  - chapter2_vault/03_econometrics/N08_Internal_Decision_Report_Window_Estimations_and_Parameter_Stability.md
stage_scope: layer_2_and_3_governance
country: US_CL
last_updated: 2026-07-25
layer: econometrics
scope: institutional_periodization_and_windowing
subtype: internal_decision_report
blocks: []
priority: reference
---

# N09 — Regulationist Accumulation Regimes, Institutional Configurations, and Long-Span Window Architecture

> **Document Purpose:** Institutional and econometric periodization architecture for Layer 2 capital composition cointegration ($k_t^{\text{NRC}} = \alpha + \gamma k_t^{\text{ME}}$). Grounded in French Regulation Theory (Aglietta, Boyer, Lipietz), Social Structures of Accumulation (SSA) theory, Matt Vidal's work on US post-Fordism, and Polanco Osorio (2021) on Chilean accumulation regimes.

---

## Executive Summary & BLUF

To estimate cointegrating elasticities of technique ($\gamma$) without sacrificing sample-size power ($N \ge 25\text{--}50$), we resolve the tension between short historical sub-phases and econometric estimation by introducing **Long-Span Macro-Era Windows** equipped with internal step-break dummies ($D_t^{\text{sub}}$) and slope interaction controls:

1. **United States Long-Span Windows:**
   - **Fordist Macro-Era (1925/1939–1973, $N=35\text{--}49$):** Stretched backwards to include early Fordist assembly expansion, the New Deal, and WWII industrial mobilization, but **strictly bounded at 1973** (collapse of Bretton Woods and onset of 1973 OPEC crisis). Controlled via a step-break dummy $D_t^{\text{pre-war}} = 1$ for 1925–1946.
   - **Post-Fordist / Neoliberal Macro-Era (1974–2021, $N=48$):** Commences in 1974 following the 1973 Fordist rupture. Encompasses Late-Fordist Crisis/Transition (1974–1981, Volcker shock) and Neoliberal Decoupling (1982–2021, lean production "mediocre sufficiency," Vidal), controlled via $D_t^{\text{crisis}} = 1$ for 1974–1981.
2. **Chile Long-Span Windows:**
   - **State-Led ISI Macro-Era (1940–1973, $N=34$):** Encompasses CORFO industrial expansion (1940–1960) and structural balance-of-payments bottleneck (1961–1973, Polanco Osorio 2021).
   - **Neoliberal Export Macro-Era (1974–2024, $N=51$):** Encompasses dictatorial shock (1974–1989) and democratic primary-export model (1990–2024), controlled via a step-break dummy $D_t^{\text{shock}} = 1$ for 1974–1989.
3. **Econometric Advantage:** Long-span windows provide the necessary degrees of freedom ($N \ge 34$) for cointegration tests (Johansen, FM-OLS, IM-OLS) while slope interactions $\gamma_1 (D_t^{\text{sub}} \times k_t^{\text{ME}})$ capture exact institutional sub-phase elasticity shifts.

---

## 1. Regulationist Theoretical Framework

### 1.1 Five Core Institutional Forms (*Formes Institutionnelles*)
Regulation Theory posits that capital accumulation is stabilized by five institutional pillars:
1. **Wage-Labor Nexus (*Rapport Salarial*):** Organization of labor, collective bargaining, wage-setting mechanisms (productivity-indexed vs. suppressed).
2. **Form of Competition:** Monopolistic/markup pricing vs. competitive market-clearing.
3. **Monetary & Financial Regime:** Credit regulation, central bank autonomy, financial market depth (Bretton Woods vs. fiat financialization).
4. **State Form:** Keynesian welfare state vs. Neoliberal workfare/subsidiary state.
5. **International Insertion:** Core industrial leader vs. peripheral primary-commodity exporter.

### 1.2 Structural Crisis Typology
- **Partial Crisis:** Recurrent cyclical downturn resolvable through marginal policy adjustments within existing institutional forms.
- **Structural Crisis (*Crise Structurelle*):** Irreversible breakdown occurring when accumulation tendencies (e.g. falling profit rate, balance-of-payments bottleneck) breach institutional containment, requiring radical destruction and restructuring of the mode of regulation.

---

## 2. US Accumulation Regimes (Matt Vidal Integration)

Matt Vidal (2013, 2019, 2022) conceptualizes US post-Fordism as a regime of **"mediocre sufficiency"**: rather than achieving high-trust flexible lean efficiency, US managers enforced wage suppression, aggressive outsourcing, and financialized shareholder-value metrics.

```
       +-------------------------------------------------------------------+
       |                 US CAPITALISM INSTITUTIONAL ARC                   |
       +-------------------------------------------------------------------+
       | 1947–1968: Fordist Expansion                                     |
       |   - Monopolistic Competition, Productivity-Indexed Wages (Treaty)   |
       |   - Bretton Woods, Keynesian Welfare State                        |
       | 1969–1981: Fordist Stagnation & Structural Crisis                 |
       |   - Falling Profit Rate, Stagflation, Bretton Woods Collapse       |
       | 1982–2021: Post-Fordist / Neoliberal Regime                       |
       |   - Lean Production, Wage Suppression (Decoupling), Financialization|
       |   - ICT Machinery Decoupling (k_ME vs k_NRC)                       |
       +-------------------------------------------------------------------+
```

- **Fordist Macro-Era (1925/1939–1973, $N=35\text{--}49$):** Stretched backwards to encompass early Fordist assembly expansion, New Deal labor legislation, and WWII industrial mobilization. **Strictly bounded at 1973** (collapse of Bretton Woods gold convertibility, 1973 OPEC oil shock, and end of the Golden Age).
- **Transition & Post-Fordist Macro-Era (1974–2021, $N=48$):** Begins in 1974 following the 1973 Fordist rupture. Encompasses Late-Fordist Crisis & Transition (1974–1981; stagflation, Volcker shock) and Neoliberal Decoupling (1982–2021; wage suppression, "mediocre sufficiency" lean production, ICT machinery expansion).

---

## 3. Chilean Accumulation Regimes (Polanco Osorio 2021 Integration)

Polanco Osorio (2021) examines the institutional and profit-rate dynamics of Chilean capital accumulation, emphasizing structural dependency and foreign exchange constraints. In peripheral Chile, machinery ($K^{\text{ME}}$) represents imported capital goods, while structures ($K^{\text{NRC}}$) represent domestic construction and state infrastructure.

```
       +-------------------------------------------------------------------+
       |              CHILEAN CAPITALISM INSTITUTIONAL ARC                 |
       +-------------------------------------------------------------------+
       | 1940–1973: Post-Nitrate State-Led ISI Regime                       |
       |   - CORFO Industrialization, Protective Tariffs                   |
       |   - 1940–1960 Expansion | 1961–1973 Bottleneck & Structural Crisis  |
       | 1973–1989: Dictatorial Shock & Neoliberal Restructuring           |
       |   - De-industrialization, Wage Repression, 1982 Financial Crash   |
       | 1990–2024: Democratic Neoliberal Export Model                     |
       |   - Primary Commodities (Mining/Agro), Central Bank Autonomy      |
       |   - AFP Pension Capital Markets, Imported Machinery Dependency    |
       +-------------------------------------------------------------------+
```

- **State-Led ISI Macro-Era (1940–1973, $N=34$):** CORFO state-directed industrialization, tariff protection, state wage arbitration. Suffers structural balance-of-payments bottleneck (1961–1973) due to capital goods import dependency, culminating in the Popular Unity crisis and 1973 coup.
- **Neoliberal Export Macro-Era (1974–2024, $N=51$):** Dictatorial shock phase (1974–1989; 10% uniform tariffs, wage suppression, 1982 banking crash) followed by democratic consolidation (1990–2024; primary commodity exports, AFP pension capital markets, autonomous Central Bank).

---

## 4. Comprehensive Periodization & Windowing Architecture

| Country | Long-Span Macro-Era | Period | Sample Size ($N$) | Internal Sub-Phase Controls | Institutional & Econometric Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **United States** | **Fordist Macro-Era** | **1925/1939–1973** | **35–49** | $D_t^{\text{pre-war}} = 1$ for 1925–1946 (Great Depression & WWII) | Monopolistic wage-labor nexus; stable error correction ($\boldsymbol{\alpha}_{\text{vecm}} < 0$); $\hat{\gamma}_0 \approx 2.85$. |
| **United States** | **Post-Fordist Macro-Era** | **1974–2021** | **48** | $D_t^{\text{crisis}} = 1$ for 1974–1981 (Fordist Crisis / Volcker Shock) | Wage suppression ("mediocre sufficiency"); ICT machinery decoupling ($\hat{\gamma} \approx 3.12$). |
| **Chile** | **State ISI Macro-Era** | **1940–1973** | **34** | $D_t^{\text{crisis}} = 1$ for 1961–1973 (ISI BoP Bottleneck) | State-led industrialization; foreign exchange constraint on $k_{\text{ME}}$ imports ($\hat{\gamma}_0 \approx 3.03$). |
| **Chile** | **Neoliberal Export Era** | **1974–2024** | **51** | $D_t^{\text{shock}} = 1$ for 1974–1989 (Dictatorial Shock / 1982 Crash) | Primary export model (mining/agro); high machinery import dependency ($\hat{\gamma} \approx 2.40$). |

---

## 5. Long-Span Econometric Model Specification

To execute Layer 2 estimations over these long-span windows:

$$k_{\text{NRC},t} = \alpha_0 + \alpha_1 D_t^{\text{sub}} + \gamma_0 k_{\text{ME},t} + \gamma_1 \left( D_t^{\text{sub}} \times k_{\text{ME},t} \right) + \epsilon_t$$

- **Estimator Choice:** Primary estimations performed via **IM-OLS** (Vogelsang & Wagner) and **Johansen VECM**, with test inference validated via **Residual Wild Bootstrap** (Cavaliere et al., 2012).
- **Hypothesis Test:** $\gamma_1 = 0$ tests whether the internal institutional sub-phase induced a structural shift in the choice-of-technique elasticity without breaking the long-run cointegrating relationship.
