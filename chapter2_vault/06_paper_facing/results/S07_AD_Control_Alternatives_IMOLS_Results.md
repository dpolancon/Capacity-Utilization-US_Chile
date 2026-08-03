---
type: econometrics-result
status: active
country: US
stage_scope: estimation-results
last_updated: '2026-07-31'
depends_on:
  - "[[S04_StructuralBreak_locked decisions]]"
  - "[[S06_AD_Controlled_SpecA_IMOLS_Results]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
  - "[[00S_Chapter2_Symbology_and_Notation_Lock]]"
  - "[[US_S17_AD_control_alternatives_imols_specA]]"
blocks: []
layer: results
role: multispec-synthesis
stage: estimation-results
subtype: cointegration-matrix
tags:
  - chapter2/results
  - chapter2/imols
  - chapter2/specification-a
  - chapter2/aggregate-demand-control
  - chapter2/demand-composition
  - chapter2/cointegration
aliases:
  - S07 AD Control Alternatives IM-OLS Results
scope: chapter2
priority: core
updated_by: AD_CONTROL_ALTERNATIVES_SPECA_RESULTS
binding_since: 2026-07-31
---

# S07: Alternative Demand Controls for Specification A — IM-OLS Results

> **Task:** Re-test Specification A with two alternatives to the rejected level-`AD_t` control (S06):
>
> 1. **Nominal non-accumulation demand share of GDP:**
>    $$s_t^{AD} = \frac{AD_t^n}{GDP_t^n} = 1 - \frac{I_t^n}{GDP_t^n}$$
>    treated as a stationary (I(0)) deterministic control.
>
> 2. **Real log consumption-minus-imports:**
>    $$\tau_t^{CM} = c_t^{real} - m_t^{real} = \ln C_t^{real} - \ln M_t^{real}$$
>    used as a distributionally induced replacement for the wage share in the interaction `k_t^{cap} \cdot \tau_{t-1}^{CM}`.

> **High-level finding:** The **C-M interaction** is a far more robust demand-composition control than either the level of `AD_t` (S06) or the nominal AD share. It delivers a **stable positive interaction coefficient** across regimes and restores cointegration hygiene in the full sample and the Golden Age. However, the sign is **positive**, not the negative profit-squeeze sign predicted by the baseline theoretical mechanism. The **AD-share control** does not stabilise the profit-squeeze interaction either.

---

## 1. Data and controls

| Control | Source | Series | Sample | Integration |
| :--- | :--- | :--- | :--- | :--- |
| AD share (`s_t^{AD}`) | FRED annual nominal | `GDPA`, `GPDIA` | 1929–2025 | I(0)-like bounded share; ADF(none) = -0.06, so treated as deterministic trend/control |
| C-M (`\tau_t^{CM}`) | FRED real quarterly-to-annual (S15C) | `PCECC96`, `IMPGSC1` | 1947–2025 | **Strongly stationary**; ADF(none) = -3.85 |

All specifications use Regime B Initial-State Centering and the locked cointegration triad (EG-ADF, Shin LM, VW Type 2) via `cointReg::cointRegIM`.

---

## 2. Nominal AD-Share Control

The target AD-share specification is:
$$y_t^{NFC} = a + \theta_0 k_t^{cap} + \theta_1 (k_t^{cap} \cdot \omega_{t-1}) + \boldsymbol{\gamma}' \mathbf{D}_t + \delta \, s_t^{AD} + u_t$$
where `s_t^{AD}` enters as a deterministic (I(0)) control.

### Table 1: AD-Share Results (`Ash1` target vs. original Spec A)

| Window | Spec | `\theta_0 (k)` | `\theta_1 (k \times \omega_{lag})` | `t(\theta_1)` | `C_{\text{Shin}}` | `CN` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| Full Sample (1931–2024) | A (ref) | 0.612 | **-48.100** | **-6.63** | 1.1083 | 111.09 |
| Full Sample | Ash1 | 0.561 | 2.467 | 0.54 | 1.3334 | 107.42 |
| Full Sample | Ash2 (AD share + full wage share) | 0.662 | **-47.379** | **-7.48** | 1.4679 | 120.76 |
| Post-Fordism (1974–2024) | A (ref) | 3.940 | 220.463 | 2.46 | 0.1553 | 76.06 |
| Post-Fordism | Ash1 | 5.439 | -32.686 | -0.48 | 0.0858 | 39.93 |
| Post-Fordism | Ash2 | 4.136 | 120.990 | 1.16 | 0.1521 | 89.99 |
| Fordism (1929–1973) | A (ref) | 0.529 | **-134.255** | **-3.83** | 1.1638 | 16.96 |
| Fordism | Ash1 | 1.053 | -7.524 | -0.36 | 1.5257 | 24.59 |
| Fordism | Ash2 | 0.883 | **-111.658** | **-3.91** | 1.8346 | 24.96 |

**Assessment:**
- The standalone AD share is **not** a substitute for the wage-share channel. When it replaces the wage share (`Ash1`), the `k \times \omega` interaction becomes insignificant across all major windows.
- Only when the full wage-share control is retained (`Ash2`) does the profit-squeeze interaction recover its original negative and significant sign — and this is simply the original Spec A result with an extra deterministic adjustment.
- The AD share therefore absorbs some low-frequency variation but does not identify a structurally stable `\theta_1`.

---

## 3. Real C-M Interaction Control

The target C-M specification is:
$$y_t^{NFC} = a + \theta_0 k_t^{cap} + \theta_1 \left(k_t^{cap} \cdot \tau_{t-1}^{CM}\right) + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$$
where `\tau_{t-1}^{CM} = c_{t-1}^{real} - m_{t-1}^{real}` is lagged and centered within each window (Regime B).

### Table 2: C-M Interaction Results

| Window | Spec | `\theta_0 (k)` | `\theta_1 (k \times CM_{lag})` | `t(\theta_1)` | `C_{\text{Shin}}` | `CN` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| Full Sample (1948–2024) | A (ref) | 0.612 | **-48.100** | **-6.63** | 1.1083 | 111.09 |
| Full Sample | CM1 target | 0.972 | **+0.065** | **2.17** | **0.0823** | 247.62 |
| Full Sample | CM2 (+CM level) | 0.621 | **+0.133** | **3.99** | **0.0301** | 681.02 |
| Full Sample | CM3 (+both CM and `\omega`) | 0.973 | +0.065 / -0.102 | 2.11 / -0.21 | 0.0899 | 306.55 |
| Fordism (1929–1973) | A (ref) | 0.529 | **-134.255** | **-3.83** | 1.1638 | 16.96 |
| Fordism | CM1 target | 1.339 | **+0.466** | **2.05** | 0.1708 | 95.57 |
| Fordism | CM3 (+both CM and `\omega`) | 0.722 | **-5.300** (CM: -0.174) | **-5.29** (-1.08) | **0.0248** | 120.54 |
| Golden Age (1948–1973) | A (ref) | 23.103 | +678.739 | 2.28 | 0.2361 | 11.72 |
| Golden Age | CM1 target | 19.920 | **+19.513** | **2.39** | **0.0406** | 56.59 |
| Post-Fordism (1974–2024) | A (ref) | 3.940 | +220.463 | 2.46 | 0.1553 | 76.06 |
| Post-Fordism | CM1 target | 10.338 | **+5.715** | **2.46** | 0.2582 | 76.88 |
| Post-Fordism | CM3 (+both CM and `\omega`) | 10.230 | -12.015 (CM: +5.441) | -0.34 (2.35) | 0.2574 | 110.75 |
| Neoliberal (1974–2008) | A (ref) | 2.362 | +284.912 | 2.10 | 0.3048 | 22.06 |
| Neoliberal | CM1 target | 9.702 | **+5.728** | **2.18** | 0.2828 | 22.71 |

**Key facts:**
- The C-M interaction is **positive and statistically significant** in the Full Sample, Golden Age, Fordism, Post-Fordism, and Neoliberal sub-samples. This is a major improvement over the `k \times \omega` interaction, which flips sign across regimes.
- Cointegration hygiene improves dramatically for the Full Sample (`C_{\text{Shin}}` falls from 1.108 to **0.082**) and the Golden Age (from 0.236 to **0.041**).
- In CM3, when both interactions are included, the wage-share interaction in Fordism reverts to the theoretically expected negative sign (`\hat{\theta}_1^{\omega} = -5.30^{***}`), while the C-M interaction is negative but insignificant there. In Post-Fordism, the wage-share interaction remains negative but insignificant, and the C-M interaction remains positive and significant. The two variables therefore capture distinct mechanisms.

---

## 4. Why C-M Works and AD Share Does Not

- **C-M is stationary.** Because `\tau_t^{CM}` is I(0), the product `k_t^{cap} \cdot \tau_{t-1}^{CM}` is I(1), just like the original `k \times \omega` term. It can enter the IM-OLS cointegrating regression without changing the integration-order structure.

- **C-M is economically interpretable as demand-composition pressure.** A high C-M spread (consumption far above imports) proxies strong domestic demand absorption relative to import leakage. Its positive interaction with capital means that, when domestic demand absorption is high, additional capital stock translates more effectively into capacity output — a demand-led utilisation channel.

- **AD share is not a distribution variable.** The share `1 - I/GDP` is a national-accounting identity residual. It is bounded, slow-moving, and not tied to class distribution in the same way as the wage share or the C-M spread. Including it does not supply the missing distributional mechanism.

- **AD level is over-collinear.** As shown in S06, using the real log level of `AD_t` alongside `k_t` creates three mutually cointegrated I(1) variables and fails identification. The AD share avoids the I(1) level problem but carries no independent explanatory content for the profit-squeeze parameter.

---

## 5. Verdict and Recommendation

| Control | Does it eliminate the original sign instability? | Does it preserve the negative profit-squeeze `\theta_1`? | Does it clear cointegration hygiene? |
| :--- | :---: | :---: | :---: |
| Real `AD_t` level | No — worsens collinearity | No | No |
| Nominal AD share of GDP | No — makes `\theta_1` insignificant | No (when replacing `\omega`) | Mostly no |
| Real C-M interaction | **Yes** — stable positive sign everywhere | **No** — sign is positive, not negative | **Yes** in Full Sample, Golden Age; mixed elsewhere |

**Recommendation:**

1. **Do not replace the wage-share profit-squeeze interaction with either AD level or AD share.** Neither restores the theoretically predicted negative `\theta_1`.

2. **The C-M interaction is a promising demand-composition control** but it identifies a different mechanism (demand-led absorption) rather than the profit squeeze. If the paper wants a demand-composition channel, `k \times (c-m)` can be added to the model — preferably alongside the wage-share interaction (CM3 style) — rather than replacing it.

3. **The original Spec A instability remains unresolved by demand controls alone.** The source of the Fordism/Post-Fordism sign flip in `\theta_1` is more likely a structural-break problem in the capital-distribution nexus than an omitted demand variable. Revisit the structural-break specification (slope breaks or regime-specific re-centring) rather than stacking demand controls.

---

## 6. Files Produced

- `codes/US_S17_AD_control_alternatives_imols_specA.R` — estimation script.
- `output/US/S17_AD_CONTROL_ALTERNATIVES_IMOLS_SPECA/csv/s17_ad_control_alternatives_specA_results.csv` — full nested results.
- `chapter2_vault/06_paper_facing/results/S07_AD_Control_Alternatives_IMOLS_Results.md` (this report).
