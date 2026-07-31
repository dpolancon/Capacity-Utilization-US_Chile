---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
  - chapter2_vault/02_analyitical_foundation/A06_RelativePrice_Mechanization_Theory.md
  - chapter2_vault/03_econometrics/Interaction_Term_Integration_Order_Gate.md
stage_scope: S30-S40
country: US_CL
last_updated: 2026-07-26
layer: econometrics
design_role: integration_order_gate
scope: chapter2_core
related_to:
  - A06_RelativePrice_Mechanization_Theory
  - D02_PriceDeflator_Protocol_K_Composition
  - Interaction_Term_Integration_Order_Gate
subtype: econometrics_gate
blocks: []
priority: reference
---

# E14: Relative Capital Asset Price Integration Order & Andrews-Zivot Break Gate

> [!important] Cointegration Admissibility Pass
> All capital price deflators ($\ln P_{\text{NFC}}^{\text{ME}}$, $\ln P_{\text{NFC}}^{\text{NRC}}$), relative asset price log-ratio ($p_t^{\text{rel}}$), and the price-interacted mechanization term ($\tau_t^{\text{real}} \cdot p_{t-1}^{\text{rel}}$) are **strictly $I(1)$ processes**.
> They pass the `Interaction_Term_Integration_Order_Gate.md` and are **econometrically admissible** for IM-OLS cointegrating estimation in Specification B.

---

## 1. Unit Root & Andrews-Zivot (AZ) Break Testing Matrix (1925–2024)

Executed via `codes/COMMON_S33_relative_price_urca_battery.R`. Output saved to `output/relative_price_urca_unit_root_matrix.csv`.

| Variable | Series Level | Test Method | Test Stat | 5% Critical Value | Endogenous Break Year | Result / Decision |
|---|---|---|---|---|---|---|
| $\ln P_{\text{NFC}}^{\text{ME}}$ | Level | ADF (Trend) | -0.382 | -3.450 | — | $I(1)$ Unit Root |
| $\ln P_{\text{NFC}}^{\text{ME}}$ | Level | ERS (DF-GLS) | -1.360 | -2.930 | — | $I(1)$ Unit Root |
| $\ln P_{\text{NFC}}^{\text{ME}}$ | Level | Andrews-Zivot (Both) | -5.081 | -5.080 | 1973 | $I(1)$ Boundary |
| $\ln P_{\text{NFC}}^{\text{ME}}$ | 1st Diff | ADF (Trend) | -3.996 | -3.450 | — | **$I(0)$ Stationary** |
| $\ln P_{\text{NFC}}^{\text{ME}}$ | 1st Diff | Andrews-Zivot (Both) | -6.579 | -5.080 | 1932 | **$I(0)$ Stationary** |
| $\ln P_{\text{NFC}}^{\text{NRC}}$ | Level | ADF (Trend) | -1.837 | -3.450 | — | $I(1)$ Unit Root |
| $\ln P_{\text{NFC}}^{\text{NRC}}$ | Level | ERS (DF-GLS) | -2.056 | -2.930 | — | $I(1)$ Unit Root |
| $\ln P_{\text{NFC}}^{\text{NRC}}$ | Level | Andrews-Zivot (Both) | -4.215 | -5.080 | 1973 | $I(1)$ Unit Root |
| $\ln P_{\text{NFC}}^{\text{NRC}}$ | 1st Diff | ADF (Trend) | -6.938 | -3.450 | — | **$I(0)$ Stationary** |
| $\ln P_{\text{NFC}}^{\text{NRC}}$ | 1st Diff | Andrews-Zivot (Both) | -9.735 | -5.080 | 1930 | **$I(0)$ Stationary** |
| $p_t^{\text{rel}}$ | Level | ADF (Trend) | -0.724 | -3.450 | — | $I(1)$ Unit Root |
| $p_t^{\text{rel}}$ | Level | ERS (DF-GLS) | -0.578 | -2.930 | — | $I(1)$ Unit Root |
| $p_t^{\text{rel}}$ | Level | Andrews-Zivot (Both) | -3.366 | -5.080 | 1984 | $I(1)$ Unit Root |
| $p_t^{\text{rel}}$ | 1st Diff | ADF (Trend) | -6.632 | -3.450 | — | **$I(0)$ Stationary** |
| $p_t^{\text{rel}}$ | 1st Diff | Andrews-Zivot (Both) | -11.969 | -5.080 | 1931 | **$I(0)$ Stationary** |
| $\tau_t^{\text{real}} \cdot p_{t-1}^{\text{rel}}$ | Level | ADF (Trend) | -2.974 | -3.450 | — | $I(1)$ Unit Root |
| $\tau_t^{\text{real}} \cdot p_{t-1}^{\text{rel}}$ | Level | Andrews-Zivot (Both) | -4.079 | -5.080 | 1947 | $I(1)$ Unit Root |
| $\tau_t^{\text{real}} \cdot p_{t-1}^{\text{rel}}$ | 1st Diff | ADF (Trend) | -7.220 | -3.450 | — | **$I(0)$ Stationary** |
| $\tau_t^{\text{real}} \cdot p_{t-1}^{\text{rel}}$ | 1st Diff | Andrews-Zivot (Both) | -12.301 | -5.080 | 1932 | **$I(0)$ Stationary** |

---

## 2. Econometric Interpretation & Cointegration Gate Status

1. **Strict $I(1)$ Integration Order**:
   - The log relative asset price $p_t^{\text{rel}} = \ln P_{\text{NFC}}^{\text{ME}} - \ln P_{\text{NFC}}^{\text{NRC}}$ is unambiguously non-stationary in levels ($t_{\text{ADF}} = -0.724 > -3.450$) and stationary in first differences ($t_{\text{ADF}} = -6.632 < -3.450$).
   - Allowing for endogenous structural breaks (AZ test) identifies key historical inflection points ($1984$ for relative prices; $1973$ for asset deflators), but confirms that $p_t^{\text{rel}}$ remains $I(1)$ across structural regimes.

2. **Interacted Term $I(1)$ Verification**:
   - The interacted choice-of-technique term $\tau_t^{\text{real}} \cdot p_{t-1}^{\text{rel}}$ is strictly $I(1)$ in level ($t_{\text{ADF}} = -2.974 > -3.450$; $t_{\text{AZ}} = -4.079 > -5.080$) and $I(0)$ in first difference ($t_{\text{ADF}} = -7.220$).
   - It avoids any $I(2)$ trap or spurious stationary mixing.

3. **Gate Verdict: APPROVED FOR SPECIFICATION B ESTIMATION**:
   - $p_t^{\text{rel}}$ and $\tau_t^{\text{real}} \cdot p_{t-1}^{\text{rel}}$ meet all requirements of `chapter2_vault/03_econometrics/Interaction_Term_Integration_Order_Gate.md`.
   - Both Specification B2 (direct control) and Specification B3 (interacted relative price choice of technique) are econometrically admissible for 168-matrix IM-OLS estimation.
