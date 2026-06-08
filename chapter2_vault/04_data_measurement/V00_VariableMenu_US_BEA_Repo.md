---
type: note
status: draft_locked_for_review
project: Chapter2
repo_owner: Capacity-Utilization-US_Chile
scope: United States source-of-truth variable menu
stage: S10_source_of_truth_design
updated: 2026-06-07
tags:
  - chapter2
  - united-states
  - source-of-truth
  - bea
  - fixed-assets
  - income-accounts
  - gpim
  - shaikh-correction
  - exploitation-rate
---

# United States Variable Menu for Source-of-Truth Construction

## 1. Repository Architecture

The U.S. BEA-fetching repository is not the analytical authority. It is the provider, extractor, and staging layer for the variable menu.

The canonical source-of-truth dataset must be built inside:

`C:\ReposGitHub\Capacity-Utilization-US_Chile`

The division of labor is:

| Repository | Role | Analytical Authority |
|---|---|---|
| `US-BEA-Income-FixedAssets-Dataset` | Fetch BEA/NIPA/Fixed Assets tables; preserve raw and staged variables; expose table-line-unit-vintage provenance | No |
| `Capacity-Utilization-US_Chile` | Build S10/S20/S30 analytical datasets; apply GPIM, Shaikh-style income corrections, sector/asset definitions, distributive variables, interaction variables, and admissibility ledgers | Yes |

The BEA-fetching repo should supply auditable ingredients. The U.S.–Chile capacity-utilization repo owns the source-of-truth construction.

---

## 2. Conceptual Object

The preferred U.S. capital object for productive-capacity accumulation is:

$$
K^{cap}_t = K^{ME}_t + K^{NRC}_t
$$

where:

- `ME` = machinery and equipment.
- `NRC` = nonresidential construction / nonresidential structures.

IPP and government transportation fixed assets are not part of the preferred productive-capacity capital stock. However, they are variables of interest in the source-of-truth dataset because they may condition the transformation frontier.

The preferred transformation relation is:

$$
g_{Y^p,t} = \theta_t g_{K^{cap},t}
$$

with:

$$
\theta_t = \theta(e_t \mid IPP_t,\ GOV\_TRANS_t)
$$

The object is not:

$$
g_{Y^p,t} = \theta g_{K^{cap},t} + \psi g_{IPP,t} + \gamma g_{GOV\_TRANS,t}
$$

Rather, IPP and government transportation fixed assets condition the transformation elasticity itself.

---

## 3. Asset-Role Classification

| Asset Block | Include in Source-of-Truth Dataset? | Include in Preferred `K_cap`? | Role |
|---|---:|---:|---|
| Machinery and equipment, `ME` | Yes | Yes | Direct accumulation capital capable of building productive capacities |
| Nonresidential construction / structures, `NRC` | Yes | Yes | Direct plant/infrastructure capital capable of building productive capacities |
| Intellectual property products, `IPP` | Yes | No | Frontier conditioner; may shape the mechanization/productive frontier |
| Government fixed assets in transportation, `GOV_TRANS` | Yes | No | Public infrastructure conditioner; may shape logistics, circulation, and mechanization frontier |
| Residential capital | Yes if available | No | Exclusion audit / diagnostic |
| Financial-sector fixed assets | Yes if available | No baseline inclusion | Corporate-boundary diagnostic |
| Inventories | Optional | No baseline inclusion | Circulation / stock-flow diagnostic |

The source-of-truth dataset should not delete IPP or government transportation assets. It should preserve them with explicit analytical role tags.

---

## 4. Sector and Account Boundaries

The dataset should preserve at least four sector/account boundaries.

| Boundary | Role |
|---|---|
| `NFC` — nonfinancial corporate business | Preferred productive-sector boundary |
| `CORP` — total corporate business | Broad corporate comparison layer; useful for Shaikh-style accounting |
| `FIN` — financial corporate business | Transfer/double-counting and financial-claim correction layer |
| `GOV_TRANS` — government transportation fixed assets | Public infrastructure frontier-conditioning layer |

The preferred analytical baseline for productive capacity should remain NFC-centered where possible. Corporate-total variables should be retained as comparators and for Shaikh-style corporate profitability accounting.

---

## 5. Fixed-Assets Lane

The fixed-assets lane supplies the capital-stock and capital-price architecture.

The BEA-fetching repo should rescue all relevant fixed-asset variables by sector/account and asset type. The U.S.–Chile repo should then construct the analytical objects.

### 5.1 Required Asset Categories

| Asset Category | Required? | Role |
|---|---:|---|
| Total fixed assets, `T` | Yes | Aggregate benchmark |
| Machinery and equipment, `ME` | Yes | Core productive-capacity capital |
| Nonresidential construction / structures, `NRC` | Yes | Core productive-capacity capital |
| Intellectual property products, `IPP` | Yes | Frontier conditioner; excluded from preferred `K_cap` |
| Government transportation fixed assets, `GOV_TRANS` | Yes | Public infrastructure conditioner |
| Residential fixed assets | Diagnostic | Exclusion audit |
| Inventories | Optional | Circulation/stock-flow diagnostic |

### 5.2 Required Current-Cost Fixed-Asset Variables

For each available sector/account × asset block, rescue:

| Variable Family | Required Variables | Use |
|---|---|---|
| Current-cost gross stock | `K_G_CC_{sector,asset}` | GPIM benchmark stock; gross capital in operation |
| Current-cost net stock | `K_N_CC_{sector,asset}` | Net stock; profitability denominator and gross-to-net wedge |
| Current-cost gross investment | `I_G_CC_{sector,asset}` | GPIM flow input |
| Current-cost CFC / depreciation | `CFC_CC_{sector,asset}` | Gross-to-net bridge; depreciation/depletion rate |
| Retirements / discards, if available | `RET_CC_{sector,asset}` | Survival and retirement consistency |
| Revaluation / holding gains, if available | `REVAL_CC_{sector,asset}` | Current-cost stock-flow reconciliation |
| Official BEA quantity/price indexes | `Q_BEA_{sector,asset}`, `P_BEA_{sector,asset}` | Diagnostic comparison, not binding if GPIM is preferred |

### 5.3 GPIM Outputs to Construct Inside `Capacity-Utilization-US_Chile`

For each sector/account × asset block:

| Constructed Object | Description |
|---|---|
| `P_K_GPIM_{sector,asset}` | Stock-flow-consistent capital-goods price index |
| `K_G_real_GPIM_{sector,asset}` | Real gross capital stock |
| `K_N_real_GPIM_{sector,asset}` | Real net capital stock |
| `I_real_GPIM_{sector,asset}` | Real gross investment |
| `delta_GPIM_{sector,asset}` | Implied depreciation/depletion rate |
| `survival_revaluation_factor_{sector,asset}` | GPIM survival and revaluation term |
| `gross_to_net_wedge_{sector,asset}` | `K_G / K_N` |
| `ME_NRC_gap_{sector}` | `log(K_ME) - log(K_NRC)` |
| `ME_share_{sector}` | ME share in `K_ME + K_NRC` |
| `NRC_share_{sector}` | NRC share in `K_ME + K_NRC` |
| `IPP_frontier_conditioner_{sector}` | IPP stock/growth/share, excluded from `K_cap` |
| `GOV_TRANS_frontier_conditioner` | Government transportation infrastructure stock/growth/share |

---

## 6. Productive-Capacity Capital Definitions

The preferred productive-capacity capital stock excludes IPP.

Baseline NFC object:

$$
K^{cap}_{NFC,t} = K^{ME}_{NFC,t} + K^{NRC}_{NFC,t}
$$

Corporate comparator:

$$
K^{cap}_{CORP,t} = K^{ME}_{CORP,t} + K^{NRC}_{CORP,t}
$$

Diagnostic toggle:

$$
K^{cap+IPP}_{sector,t} = K^{ME}_{sector,t} + K^{NRC}_{sector,t} + K^{IPP}_{sector,t}
$$

The diagnostic toggle must be clearly marked as non-preferred.

Government transportation fixed assets should not enter `K_cap`. They should enter as conditioning variables for `theta_t`.

---

## 7. Income-Accounts Lane

The income-accounts lane supplies the output, surplus, wage-share, profit-share, and exploitation-rate architecture.

The dataset should build both NFC and total corporate-sector income accounts.

### 7.1 Required Income-Account Variables

| Variable Family | NFC | CORP | FIN | Use |
|---|---:|---:|---:|---|
| Gross value added | Required | Required | Optional/diagnostic | Output/income boundary |
| Net value added | Required | Required | Optional/diagnostic | Net income boundary |
| Compensation of employees | Required | Required | Optional/diagnostic | Wage-share construction |
| Taxes on production and imports less subsidies | Required if available | Required if available | Optional | Bridge to operating surplus |
| Gross operating surplus | Required | Required | Optional/diagnostic | Gross surplus numerator |
| Net operating surplus | Required | Required | Optional/diagnostic | Net surplus numerator |
| Consumption of fixed capital | Required | Required | Optional | Gross-to-net bridge |
| Corporate profits before tax | Required if available | Required | Required for FIN | Profit numerator comparator |
| Corporate profits after tax | Optional | Optional | Optional | Distribution/tax diagnostic |
| Taxes on corporate income | Optional | Required if available | Optional | Tax wedge |
| Net interest | Required | Required | Required | Shaikh-style transfer adjustment |
| Business current transfer payments | Required if available | Required if available | Required if available | Transfer correction |
| Business current transfer receipts | Required if available | Required if available | Required if available | Transfer correction |
| Dividends paid | Required if available | Required if available | Required if available | Distribution/double-counting check |
| Dividends received | Required if available | Required if available | Required if available | Intra-corporate transfer check |
| Undistributed corporate profits | Optional | Required if available | Optional | Retained surplus diagnostic |

---

## 8. Shaikh-Style Imputed-Interest Correction

The source-of-truth dataset should include an explicit Shaikh-style correction layer for corporate income accounts.

The correction object is:

$$
CorpImpIntAdj_t \equiv -BankMonIntPaid_t - CorpNFNetImpIntPaid_t
$$

where:

$$
BankMonIntPaid_t =
(7.11:L4 + 7.11:L44 + 7.11:L73)
-
(7.11:L28 + 7.11:L52 + 7.11:L91)
$$

and:

$$
CorpNFNetImpIntPaid_t = 7.11:L74 - 7.11:L53
$$

Then construct:

$$
GVAcorp^{adj}_t = GVAcorp^{NIPA}_t + CorpImpIntAdj_t
$$

$$
NOScorp^{adj}_t = NOScorp^{NIPA}_t + CorpImpIntAdj_t
$$

$$
VAcorp^{adj}_t = VAcorp^{NIPA}_t + CorpImpIntAdj_t
$$

$$
\pi^{adj}_t = \frac{NOScorp^{adj}_t}{VAcorp^{adj}_t}
$$

This correction should be implemented as a named accounting layer, not hidden inside a generic profit-share variable.

---

## 9. Distribution Variables

The distributive variable should be constructed after profit-share adjustment.

Preferred adjusted profit share:

$$
\pi^{adj}_t = \frac{NOS^{adj}_t}{VA^{adj}_t}
$$

Preferred adjusted wage share:

$$
\omega^{adj}_t = 1 - \pi^{adj}_t
$$

Preferred exploitation rate:

$$
e_t = \frac{\pi^{adj}_t}{\omega^{adj}_t}
$$

Preferred logged exploitation rate:

$$
\ln e_t = \ln\left(\frac{\pi^{adj}_t}{\omega^{adj}_t}\right)
$$

The exploitation rate is the preferred interactive distributive variable with capital stocks.

---

## 10. Interaction Variables

The source-of-truth dataset should construct interaction variables using the adjusted distributive architecture.

Core distributive-capital interactions:

$$
e_t K^{cap}_t
$$

$$
e_t K^{ME}_t
$$

$$
e_t K^{NRC}_t
$$

$$
e_t m^{ME,NRC}_t
$$

where:

$$
m^{ME,NRC}_t = \log K^{ME}_t - \log K^{NRC}_t
$$

If log-level system estimation is used, the preferred distributive state variable is:

$$
\ln e_t
$$

If interaction regressors are used in a single-equation or FM-OLS/DOLS/IM-OLS setting, the dataset should preserve both raw and logged versions where theoretically coherent.

---

## 11. Frontier-Conditioning Variables

IPP and government transportation assets should enter as conditioning variables for `theta_t`, not as additive pieces of productive-capacity capital.

Preferred expression:

$$
\theta_t = \theta(e_t \mid IPP_t,\ GOV\_TRANS_t)
$$

Candidate conditioning variables:

| Variable | Description |
|---|---|
| `IPP_stock_{sector}` | IPP current-cost and GPIM real stock |
| `IPP_growth_{sector}` | IPP growth rate |
| `IPP_share_total_fixed_assets_{sector}` | IPP share of total fixed assets |
| `IPP_share_capital_plus_IPP_{sector}` | IPP share relative to `ME + NRC + IPP` |
| `GOV_TRANS_stock` | Government transportation fixed assets |
| `GOV_TRANS_growth` | Growth of government transportation assets |
| `GOV_TRANS_to_private_Kcap` | Government transport stock relative to private productive-capacity capital |
| `GOV_TRANS_to_NRC` | Government transport stock relative to private NRC |
| `GOV_TRANS_to_ME` | Government transport stock relative to private ME |
| `IPP_x_e` | Interaction of IPP frontier condition with exploitation |
| `GOV_TRANS_x_e` | Interaction of government transportation frontier condition with exploitation |

These variables should be tagged as `frontier_conditioner`, not as `direct_productive_capacity_capital`.

---

## 12. Minimum Variable-Rescue Checklist

### 12.1 Fixed Assets

| Priority | Variable |
|---|---|
| Required | NFC current-cost gross fixed assets: total, ME, NRC, IPP |
| Required | NFC current-cost net fixed assets: total, ME, NRC, IPP |
| Required | NFC current-cost gross investment: total, ME, NRC, IPP |
| Required | NFC CFC: total, ME, NRC, IPP |
| Required | CORP current-cost gross fixed assets: total, ME, NRC, IPP if available |
| Required | CORP current-cost net fixed assets: total, ME, NRC, IPP if available |
| Required | CORP current-cost gross investment: total, ME, NRC, IPP if available |
| Required | CORP CFC: total, ME, NRC, IPP if available |
| Required | Government fixed assets in transportation: gross stock, net stock, investment, CFC |
| Diagnostic | Official BEA chained real stocks and price indexes |
| Diagnostic | FIN fixed assets |
| Diagnostic | Residential capital |
| Optional | Inventories |

### 12.2 Income Accounts

| Priority | Variable |
|---|---|
| Required | NFC gross and net value added |
| Required | CORP gross and net value added |
| Required | NFC compensation of employees |
| Required | CORP compensation of employees |
| Required | NFC gross/net operating surplus |
| Required | CORP gross/net operating surplus |
| Required | NFC CFC |
| Required | CORP CFC |
| Required | NFC corporate profits before tax, if available |
| Required | CORP corporate profits before tax |
| Required | Financial corporate profits before tax |
| Required | NFC net interest |
| Required | CORP net interest |
| Required | Financial corporate net interest |
| Required | NIPA Table 7.11 lines needed for imputed-interest correction |
| Required | NFC/CORP/FIN current transfer payments and receipts, if available |
| Required | NFC/CORP/FIN dividends paid and received, if available |
| Diagnostic | Corporate taxes |
| Diagnostic | After-tax profits |
| Diagnostic | Undistributed profits |

---

## 13. Analytical Outputs to Construct

The final U.S. source-of-truth dataset should produce:

| Output | Description |
|---|---|
| `K_G_NFC_ME_GPIM` | NFC gross ME capital stock |
| `K_G_NFC_NRC_GPIM` | NFC gross NRC capital stock |
| `K_G_NFC_KCAP_GPIM` | NFC gross productive-capacity capital stock, `ME + NRC` |
| `K_N_NFC_ME_GPIM` | NFC net ME capital stock |
| `K_N_NFC_NRC_GPIM` | NFC net NRC capital stock |
| `K_N_NFC_KCAP_GPIM` | NFC net productive-capacity capital stock, `ME + NRC` |
| `P_K_NFC_ME_GPIM` | NFC ME capital price index |
| `P_K_NFC_NRC_GPIM` | NFC NRC capital price index |
| `IPP_NFC_GPIM` | NFC IPP frontier-conditioning stock |
| `GOV_TRANS_GPIM` | Government transportation frontier-conditioning stock |
| `pi_adj_CORP` | Adjusted corporate profit share |
| `omega_adj_CORP` | Adjusted corporate wage share |
| `e_adj_CORP` | Adjusted corporate exploitation rate |
| `ln_e_adj_CORP` | Logged adjusted exploitation rate |
| `pi_adj_NFC` | Adjusted NFC profit share if correction can be implemented |
| `omega_adj_NFC` | Adjusted NFC wage share |
| `e_adj_NFC` | Adjusted NFC exploitation rate |
| `ln_e_adj_NFC` | Logged NFC exploitation rate |
| `e_x_Kcap` | Exploitation-capital interaction |
| `e_x_ME` | Exploitation-ME interaction |
| `e_x_NRC` | Exploitation-NRC interaction |
| `e_x_ME_NRC_gap` | Exploitation-mechanization-gap interaction |
| `source_provenance_ledger` | Full table-line-unit-vintage-sector-asset metadata |

---

## 14. Implications After S30I Bottlenecks

The S30I bottleneck points directly back to the S10 data architecture.

The problem is not only estimator choice. The current capital variables, especially `k_NRC_t`, `k_ME_t`, and `m_ME_NRC_t`, show substantial integration-order risk. The next data-source pass must make the capital construction auditable enough to decide whether the problem comes from:

1. BEA official real stock / price-index behavior.
2. Current-cost stock-flow inconsistency.
3. Asset split construction.
4. GPIM implementation.
5. Gross versus net stock choice.
6. NFC versus CORP sector boundary.
7. ME–NRC gap definition.
8. IPP exclusion/inclusion choices.
9. Public transportation infrastructure as a frontier conditioner.
10. Genuine historical behavior of U.S. capital composition.

---

## 15. Current Lock

The U.S. source-of-truth dataset should preserve a broad BEA/NIPA/Fixed Assets variable menu, but the preferred productive-capacity capital stock remains:

$$
K^{cap}_t = K^{ME}_t + K^{NRC}_t
$$

IPP is excluded from `K_cap` but retained as a frontier-conditioning variable.

Government transportation fixed assets are excluded from `K_cap` but retained as public-infrastructure frontier-conditioning variables.

The preferred distributive conditioning variable is the adjusted exploitation rate:

$$
e_t = \frac{\pi^{adj}_t}{\omega^{adj}_t}
$$

The preferred transformation-elasticity object is:

$$
\theta_t = \theta(e_t \mid IPP_t,\ GOV\_TRANS_t)
$$

This dataset architecture keeps the source of truth broad enough for audit and future specification redesign, while keeping the productive-capacity capital object theoretically disciplined.