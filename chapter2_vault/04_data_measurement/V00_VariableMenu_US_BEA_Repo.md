---

type: note  
status: draft_locked_for_review  
project: Chapter2  
repo_owner: Capacity-Utilization-US_Chile  
scope: United States source-of-truth variable menu  
stage: S10_source_of_truth_design  
updated: 2026-06-09  
tags:

- chapter2
    
- united-states
    
- source-of-truth
    
- bea
    
- fixed-assets
    
- income-accounts
    
- gpim
    
- shaikh-correction
    
- wage-share
    
- distributive-conditions
    
- exploitation-rate-alternative
    

---

# United States Variable Menu for Source-of-Truth Construction

## 1. Repository Architecture

The U.S. BEA-fetching repository is not the analytical authority. It is the provider, extractor, and staging layer for the variable menu.

The canonical source-of-truth dataset must be built inside:

`C:\ReposGitHub\Capacity-Utilization-US_Chile`

The division of labor is:

|Repository|Role|Analytical Authority|
|---|---|---|
|`US-BEA-Income-FixedAssets-Dataset`|Fetch BEA/NIPA/Fixed Assets tables; preserve raw and staged variables; expose table-line-unit-vintage provenance|No|
|`Capacity-Utilization-US_Chile`|Build S10/S20/S30/S40 analytical datasets; apply GPIM, admissible income corrections, sector/asset definitions, distributive variables, accumulated distribution-conditioned capital-growth indexes, and admissibility ledgers|Yes|

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

The preferred distributive variable is the wage share. The unadjusted wage share is the first-pass baseline while the current-release Shaikh-style adjustment protocol remains blocked.

The active A00 econometric relation is:

$$
y_t^p
=
\alpha
+
\theta_0 k_t
+
\theta_\omega q_t^{\omega,h}
+
u_t,
\qquad
q_t^{\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s.
$$

The benchmark inherited state is:

$$
m_{t-1}^{(1)}
=
\omega_{t-1},
\qquad
\theta_t
=
\theta_0
+
\theta_\omega m_{t-1}^{(h)}.
$$

The wage share is the preferred distributive state, preferably adjusted after the income-account correction layer.

The exploitation rate is retained as an alternative proxy for distributive conditions:

$$  
e_t = \frac{\pi_t}{\omega_t}  
$$

but it is not the preferred distributive variable in the baseline source-of-truth architecture.

The object is not:

$$  
g_{Y^p,t} = \theta g_{K^{cap},t} + \psi g_{IPP,t} + \gamma g_{GOV_TRANS,t}  
$$

Rather, IPP and government transportation fixed assets condition the transformation elasticity itself.

IPP and GOV_TRANS retain their frontier-conditioner roles, but neither enters A00 as an additive capital term. Any explicit conditioning specification involving them is an extension or diagnostic and cannot replace the accumulated-index benchmark.

---

## 3. Asset-Role Classification

|Asset Block|Include in Source-of-Truth Dataset?|Include in Preferred `K_cap`?|Role|
|---|--:|--:|---|
|Machinery and equipment, `ME`|Yes|Yes|Direct accumulation capital capable of building productive capacities|
|Nonresidential construction / structures, `NRC`|Yes|Yes|Direct plant/infrastructure capital capable of building productive capacities|
|Intellectual property products, `IPP`|Yes|No|Frontier conditioner; may shape the mechanization/productive frontier|
|Government fixed assets in transportation, `GOV_TRANS`|Yes|No|Public infrastructure conditioner; may shape logistics, circulation, and mechanization frontier|
|Residential capital|Yes if available|No|Exclusion audit / diagnostic|
|Financial-sector fixed assets|Yes if available|No baseline inclusion|Corporate-boundary diagnostic|
|Inventories|Optional|No baseline inclusion|Circulation / stock-flow diagnostic|

The source-of-truth dataset should not delete IPP or government transportation assets. It should preserve them with explicit analytical role tags.

---

## 4. Sector and Account Boundaries

The dataset should preserve at least four sector/account boundaries.

|Boundary|Role|
|---|---|
|`NFC` — nonfinancial corporate business|Preferred productive-sector boundary|
|`CORP` — total corporate business|Broad corporate comparison layer; useful for Shaikh-style accounting|
|`FIN` — financial corporate business|Transfer/double-counting and financial-claim correction layer|
|`GOV_TRANS` — government transportation fixed assets|Public infrastructure frontier-conditioning layer|

The preferred analytical baseline for productive capacity should remain NFC-centered where possible. Corporate-total variables should be retained as comparators and for Shaikh-style corporate profitability accounting.

---

## 5. Fixed-Assets Lane

The fixed-assets lane supplies the capital-stock and capital-price architecture.

The BEA-fetching repo should rescue all relevant fixed-asset variables by sector/account and asset type. The U.S.–Chile repo should then construct the analytical objects.

### 5.1 Required Asset Categories

|Asset Category|Required?|Role|
|---|--:|---|
|Total fixed assets, `T`|Yes|Aggregate benchmark|
|Machinery and equipment, `ME`|Yes|Core productive-capacity capital|
|Nonresidential construction / structures, `NRC`|Yes|Core productive-capacity capital|
|Intellectual property products, `IPP`|Yes|Frontier conditioner; excluded from preferred `K_cap`|
|Government transportation fixed assets, `GOV_TRANS`|Yes|Public infrastructure conditioner|
|Residential fixed assets|Diagnostic|Exclusion audit|
|Inventories|Optional|Circulation/stock-flow diagnostic|

### 5.2 Required Current-Cost Fixed-Asset Variables

For each available sector/account × asset block, rescue:

|Variable Family|Required Variables|Use|
|---|---|---|
|Current-cost gross stock|`K_G_CC_{sector,asset}`|GPIM benchmark stock; gross capital in operation|
|Current-cost net stock|`K_N_CC_{sector,asset}`|Net stock; profitability denominator and gross-to-net wedge|
|Current-cost gross investment|`I_G_CC_{sector,asset}`|GPIM flow input|
|Current-cost CFC / depreciation|`CFC_CC_{sector,asset}`|Gross-to-net bridge; depreciation/depletion rate|
|Retirements / discards, if available|`RET_CC_{sector,asset}`|Survival and retirement consistency|
|Revaluation / holding gains, if available|`REVAL_CC_{sector,asset}`|Current-cost stock-flow reconciliation|
|Official BEA quantity/price indexes|`Q_BEA_{sector,asset}`, `P_BEA_{sector,asset}`|Diagnostic comparison, not binding if GPIM is preferred|

### 5.3 GPIM Outputs to Construct Inside `Capacity-Utilization-US_Chile`

For each sector/account × asset block:

|Constructed Object|Description|
|---|---|
|`P_K_GPIM_{sector,asset}`|Stock-flow-consistent capital-goods price index|
|`K_G_real_GPIM_{sector,asset}`|Real gross capital stock|
|`K_N_real_GPIM_{sector,asset}`|Real net capital stock|
|`I_real_GPIM_{sector,asset}`|Real gross investment|
|`delta_GPIM_{sector,asset}`|Implied depreciation/depletion rate|
|`survival_revaluation_factor_{sector,asset}`|GPIM survival and revaluation term|
|`gross_to_net_wedge_{sector,asset}`|`K_G / K_N`|
|`ME_NRC_gap_{sector}`|`log(K_ME) - log(K_NRC)`|
|`ME_share_{sector}`|ME share in `K_ME + K_NRC`|
|`NRC_share_{sector}`|NRC share in `K_ME + K_NRC`|
|`IPP_frontier_conditioner_{sector}`|IPP stock/growth/share, excluded from `K_cap`|
|`GOV_TRANS_frontier_conditioner`|Government transportation infrastructure stock/growth/share|

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

The income-accounts lane supplies the output, surplus, wage-share, profit-share, and alternative exploitation-rate architecture.

The dataset should build both NFC and total corporate-sector income accounts.

The preferred distributive variable is the wage share:

$$  
\omega_t  
$$

The profit share is retained as an accounting complement and surplus-share diagnostic. The exploitation rate is retained as an alternative proxy for distributive conditions, especially where the theoretical or empirical specification benefits from a surplus-to-wage ratio rather than a wage-share level.

### 7.1 Required Income-Account Variables

|Variable Family|NFC|CORP|FIN|Use|
|---|--:|--:|--:|---|
|Gross value added|Required|Required|Optional/diagnostic|Output/income boundary|
|Net value added|Required|Required|Optional/diagnostic|Net income boundary|
|Compensation of employees|Required|Required|Optional/diagnostic|Wage-share construction|
|Taxes on production and imports less subsidies|Required if available|Required if available|Optional|Bridge to operating surplus|
|Gross operating surplus|Required|Required|Optional/diagnostic|Gross surplus numerator|
|Net operating surplus|Required|Required|Optional/diagnostic|Net surplus numerator|
|Consumption of fixed capital|Required|Required|Optional|Gross-to-net bridge|
|Corporate profits before tax|Required if available|Required|Required for FIN|Profit numerator comparator|
|Corporate profits after tax|Optional|Optional|Optional|Distribution/tax diagnostic|
|Taxes on corporate income|Optional|Required if available|Optional|Tax wedge|
|Net interest|Required|Required|Required|Shaikh-style transfer adjustment|
|Business current transfer payments|Required if available|Required if available|Required if available|Transfer correction|
|Business current transfer receipts|Required if available|Required if available|Required if available|Transfer correction|
|Dividends paid|Required if available|Required if available|Required if available|Distribution/double-counting check|
|Dividends received|Required if available|Required if available|Required if available|Intra-corporate transfer check|
|Undistributed corporate profits|Optional|Required if available|Optional|Retained surplus diagnostic|

---

## 8. Current-Release Shaikh-Style BEA Adjustment Protocol

Shaikh 2011 is the conceptual/accounting benchmark, not a line-number recipe to copy mechanically into current BEA releases.

The downstream task is to build a current-release Shaikh-style adjustment protocol. Shaikh 2011 supplies the accounting logic and object definitions; current BEA release semantics determine whether any candidate ingredient is admissible for the corresponding role.

S00 has gathered and imported the current candidate BEA lines `T711_L4`, `T711_L44`, `T711_L73`, `T711_L28`, `T711_L52`, `T711_L91`, `T711_L74`, and `T711_L53`. Their presence establishes provenance and candidate status only. Current BEA line numbers are not sufficient evidence of semantic continuity, and the full adjustment is not formula-admissible.

No Shaikh-adjusted income, profit-share, wage-share, exploitation-rate, accumulated-index, regression, capacity, or utilization variable may be constructed until the current-release Shaikh-style protocol passes.

|Shaikh-style object|Accounting role|Shaikh 2011 benchmark logic|Current BEA candidate line(s)|Current-release semantic interpretation|Admissibility decision|Proposed current-release treatment|Status|
|---|---|---|---|---|---|---|---|
|`BankMonIntPaid_t`|Financial-sector monetary/imputed-interest adjustment object|Identify the financial interest flows needed to remove the relevant accounting transfer from corporate income|`T711_L4`, `T711_L44`, `T711_L73`, `T711_L28`, `T711_L52`, `T711_L91`|Candidate lines span financial and government branches whose current meanings do not establish the complete benchmark object|Not admissible as a complete object|Build and document an object-level current-release mapping before specifying signs or aggregation|BLOCKED/PENDING|
|`CorpNFNetImpIntPaid_t`|Nonfinancial-corporate net imputed-interest adjustment object|Identify the nonfinancial-corporate imputed-interest flow required by the benchmark accounting boundary|`T711_L74`, `T711_L53`|Current descriptions do not preserve the legacy nonfinancial-corporate roles implied by line-number reuse|Not admissible|Locate semantically valid current-release NFC ingredients or document that the object cannot be recovered|BLOCKED/PENDING|
|`CorpImpIntAdj_t`|Combined corporate imputed-interest adjustment|Combine only protocol-approved financial and NFC adjustment objects under an explicit accounting identity|No direct BEA line; depends on approved upstream objects|Neither dependency is currently admissible|Not admissible|Define only after both component objects pass semantic and accounting review|BLOCKED/PENDING|
|`GVAcorp_adj_t`|Adjusted corporate gross value added|Apply the approved corporate adjustment to the correct gross value-added boundary|Depends on approved `CorpImpIntAdj_t` and a verified corporate GVA base|Adjustment dependency is blocked|Not admissible|Specify the adjustment direction and base only after protocol approval|BLOCKED/PENDING|
|`NOScorp_adj_t`|Adjusted corporate net operating surplus|Apply the approved adjustment to the correct net operating-surplus boundary|Depends on approved `CorpImpIntAdj_t` and a verified corporate NOS base|Adjustment dependency is blocked|Not admissible|Specify the adjustment direction and base only after protocol approval|BLOCKED/PENDING|
|`VAcorp_adj_t`|Adjusted corporate value-added denominator|Create the denominator required by adjusted distributive objects from protocol-approved income components|Depends on approved adjusted income objects|Required adjusted components do not exist|Not admissible|Define the gross/net boundary and denominator only after protocol approval|BLOCKED/PENDING|
|`omega_adj_CORP_t`|Adjusted corporate wage-share state|Retain wage share as the preferred distributive state on an approved adjusted denominator|Depends on approved `VAcorp_adj_t` and verified compensation treatment|Adjusted denominator is blocked|Not admissible|Retain unadjusted wage share as the first-pass baseline; build this separately only after protocol approval|BLOCKED/PENDING|
|`pi_adj_res_CORP_t`|Residual adjusted corporate profit-share complement|Derive the accounting complement to the approved adjusted wage share without collapsing it into a surplus-account measure|Depends on approved `omega_adj_CORP_t`|Adjusted wage share is blocked|Not admissible|Construct only as a named residual complement after protocol approval|BLOCKED/PENDING|
|`e_adj_CORP_t`|Adjusted exploitation-rate alternative proxy|Form a surplus-to-wage proxy from protocol-approved adjusted distribution objects|Depends on approved adjusted wage-share and profit-share objects|Adjusted distribution objects are blocked|Not admissible|Construct only as a separate alternative-proxy robustness object after protocol approval|BLOCKED/PENDING|

This table is a protocol scaffold, not a completed mapping or an approved formula. Each row requires a documented current-release semantic interpretation, an accounting-boundary decision, and an explicit admissibility verdict before implementation.

---

## 9. Distribution Variables

The preferred distributive variable is the wage share. While the current-release Shaikh-style protocol is blocked, the first-pass baseline is the unadjusted wage share:

$$  
\omega_t = \frac{COMP_t}{VA_t}  
$$

The corresponding unadjusted residual profit-share complement and exploitation-rate proxy may be retained as clearly named first-pass accounting and robustness objects. The exploitation rate remains an alternative proxy; it is not the baseline distributive primitive.

If the current-release Shaikh-style protocol later passes, adjusted-distribution variants may be constructed separately. They must not overwrite or silently replace the unadjusted baseline.

Implementation implication:

|Variable|Status|Role|
|---|---|---|
|`omega_CORP`|Preferred first-pass baseline|Unadjusted corporate wage-share state|
|`omega_NFC`|Preferred first-pass baseline if implementable|Unadjusted NFC wage-share state|
|`pi_res_CORP`|Derived first-pass object|Residual complement to the unadjusted wage share|
|`e_CORP`|Alternative proxy|Unadjusted surplus-to-wage distributive condition|
|`omega_adj_CORP`|Protocol-gated|Adjusted corporate wage share; blocked pending protocol approval|
|`pi_adj_res_CORP`|Protocol-gated|Adjusted residual profit-share complement; blocked pending protocol approval|
|`e_adj_CORP`|Protocol-gated alternative proxy|Adjusted exploitation-rate proxy; blocked pending protocol approval|

---

## 10. Accumulated Distribution-Conditioned Capital-Growth Indexes

The A00 econometric device is the accumulated distribution-conditioned capital-growth index:

$$
q_t^{\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s.
$$

It enters the aggregate-capital benchmark:

$$
y_t^p
=
\alpha
+
\theta_0 k_t
+
\theta_\omega q_t^{\omega,h}
+
u_t,
$$

with:

$$
\theta_t
=
\theta_0
+
\theta_\omega m_{t-1}^{(h)}.
$$

The inherited one-period distributive state is:

$$
m_{t-1}^{(1)}
=
\omega_{t-1}.
$$

The three-year and five-year moving averages are restricted robustness states. They do not estimate unrestricted lag weights and do not replace the inherited-state benchmark.

|Output object|Status|Memory-state interpretation|
|---|---|---|
|`q_omega_h1_Kcap`|Preferred A00 benchmark|Inherited one-period wage-share state|
|`q_omega_h3_Kcap`|Preferred A00 benchmark family; restricted robustness state|Restricted three-year moving-average wage-share state|
|`q_omega_h5_Kcap`|Preferred A00 benchmark family; restricted robustness state|Restricted five-year moving-average wage-share state|
|`q_e_h1_Kcap`|Alternative-proxy robustness|Inherited one-period exploitation-rate state|
|`q_e_h3_Kcap`|Alternative-proxy robustness|Restricted three-year moving-average exploitation-rate state|
|`q_e_h5_Kcap`|Alternative-proxy robustness|Restricted five-year moving-average exploitation-rate state|

Wage share remains the preferred distributive state. The exploitation rate remains an alternative proxy and cannot silently replace the A00 wage-share benchmark.

Level interaction variables such as omega_x_Kcap, omega_x_ME, omega_x_NRC, omega_x_ME_NRC_gap, e_x_Kcap, e_x_ME, e_x_NRC, and e_x_ME_NRC_gap are superseded or diagnostic only. They must not define the A00 benchmark, generated implementation variables, coefficient promotion, or S40 reconstruction.

A03 may extend the accumulated-index logic to separate ME and NRC channels. Those two-capital objects are extensions only; no ME/NRC accumulated index is binding in A00.

---

## 11. Frontier-Conditioning Variables

IPP and government transportation assets should enter as conditioning variables for `theta_t`, not as additive pieces of productive-capacity capital.

Conceptual wage-share conditioning expression:

$$  
\theta_t = \theta(\omega_t \mid IPP_t,\ GOV_TRANS_t)  
$$

Alternative-proxy conditioning expression:

$$  
\theta_t = \theta(e_t \mid IPP_t,\ GOV_TRANS_t)  
$$

These expressions use the unadjusted first-pass distributive states and preserve the frontier-conditioner interpretation. They are extension/diagnostic specifications and do not replace A00's accumulated aggregate-capital index. Adjusted versions remain blocked with the current-release Shaikh-style protocol.

Candidate conditioning variables:

|Variable|Description|
|---|---|
|`IPP_stock_{sector}`|IPP current-cost and GPIM real stock|
|`IPP_growth_{sector}`|IPP growth rate|
|`IPP_share_total_fixed_assets_{sector}`|IPP share of total fixed assets|
|`IPP_share_capital_plus_IPP_{sector}`|IPP share relative to `ME + NRC + IPP`|
|`GOV_TRANS_stock`|Government transportation fixed assets|
|`GOV_TRANS_growth`|Growth of government transportation assets|
|`GOV_TRANS_to_private_Kcap`|Government transport stock relative to private productive-capacity capital|
|`GOV_TRANS_to_NRC`|Government transport stock relative to private NRC|
|`GOV_TRANS_to_ME`|Government transport stock relative to private ME|
|`IPP_x_omega`|Interaction of IPP frontier condition with wage share|
|`GOV_TRANS_x_omega`|Interaction of government transportation frontier condition with wage share|
|`IPP_x_e`|Alternative interaction of IPP frontier condition with exploitation rate|
|`GOV_TRANS_x_e`|Alternative interaction of government transportation frontier condition with exploitation rate|

These variables should be tagged as `frontier_conditioner`, not as `direct_productive_capacity_capital`.

Any direct frontier-conditioning product is extension/diagnostic only. Wage-share versions preserve the preferred distributive state; exploitation-rate versions remain alternative-proxy variants.

---

## 12. Minimum Variable-Rescue Checklist

### 12.1 Fixed Assets

|Priority|Variable|
|---|---|
|Required|NFC current-cost gross fixed assets: total, ME, NRC, IPP|
|Required|NFC current-cost net fixed assets: total, ME, NRC, IPP|
|Required|NFC current-cost gross investment: total, ME, NRC, IPP|
|Required|NFC CFC: total, ME, NRC, IPP|
|Required|CORP current-cost gross fixed assets: total, ME, NRC, IPP if available|
|Required|CORP current-cost net fixed assets: total, ME, NRC, IPP if available|
|Required|CORP current-cost gross investment: total, ME, NRC, IPP if available|
|Required|CORP CFC: total, ME, NRC, IPP if available|
|Required|Government fixed assets in transportation: gross stock, net stock, investment, CFC|
|Diagnostic|Official BEA chained real stocks and price indexes|
|Diagnostic|FIN fixed assets|
|Diagnostic|Residential capital|
|Optional|Inventories|

### 12.2 Income Accounts

|Priority|Variable|
|---|---|
|Required|NFC gross and net value added|
|Required|CORP gross and net value added|
|Required|NFC compensation of employees|
|Required|CORP compensation of employees|
|Required|NFC gross/net operating surplus|
|Required|CORP gross/net operating surplus|
|Required|NFC CFC|
|Required|CORP CFC|
|Required|NFC corporate profits before tax, if available|
|Required|CORP corporate profits before tax|
|Required|Financial corporate profits before tax|
|Required|NFC net interest|
|Required|CORP net interest|
|Required|Financial corporate net interest|
|Required|NIPA Table 7.11 lines needed for imputed-interest correction|
|Required|NFC/CORP/FIN current transfer payments and receipts, if available|
|Required|NFC/CORP/FIN dividends paid and received, if available|
|Diagnostic|Corporate taxes|
|Diagnostic|After-tax profits|
|Diagnostic|Undistributed profits|

The compensation and value-added variables are mandatory because the wage share is the preferred distributive variable. Surplus and profit variables remain mandatory because they are needed for accounting reconciliation, Shaikh-style correction diagnostics, residual profit-share construction, and exploitation-rate alternatives.

---

## 13. Analytical Outputs to Construct

The final U.S. source-of-truth dataset should produce:

|Output|Description|
|---|---|
|`K_G_NFC_ME_GPIM`|NFC gross ME capital stock|
|`K_G_NFC_NRC_GPIM`|NFC gross NRC capital stock|
|`K_G_NFC_KCAP_GPIM`|NFC gross productive-capacity capital stock, `ME + NRC`|
|`K_N_NFC_ME_GPIM`|NFC net ME capital stock|
|`K_N_NFC_NRC_GPIM`|NFC net NRC capital stock|
|`K_N_NFC_KCAP_GPIM`|NFC net productive-capacity capital stock, `ME + NRC`|
|`P_K_NFC_ME_GPIM`|NFC ME capital price index|
|`P_K_NFC_NRC_GPIM`|NFC NRC capital price index|
|`IPP_NFC_GPIM`|NFC IPP frontier-conditioning stock|
|`GOV_TRANS_GPIM`|Government transportation frontier-conditioning stock|
|`omega_CORP`|Preferred unadjusted corporate wage-share first-pass baseline|
|`omega_NFC`|Preferred unadjusted NFC wage-share first-pass baseline, if implementable|
|`pi_res_CORP`|Unadjusted residual corporate profit-share complement|
|`e_CORP`|Unadjusted corporate exploitation-rate alternative proxy|
|`omega_adj_CORP`|Protocol-gated adjusted corporate wage share; BLOCKED/PENDING|
|`pi_adj_res_CORP`|Protocol-gated residual adjusted corporate profit share; BLOCKED/PENDING|
|`e_adj_CORP`|Protocol-gated adjusted corporate exploitation-rate alternative proxy; BLOCKED/PENDING|
|`q_omega_h1_Kcap`|Preferred A00 accumulated index using the inherited one-period wage-share state|
|`q_omega_h3_Kcap`|Preferred A00 benchmark-family index using the restricted three-year moving-average wage-share robustness state|
|`q_omega_h5_Kcap`|Preferred A00 benchmark-family index using the restricted five-year moving-average wage-share robustness state|
|`q_e_h1_Kcap`|Alternative-proxy robustness index using the inherited one-period exploitation-rate state|
|`q_e_h3_Kcap`|Alternative-proxy robustness index using the restricted three-year moving-average exploitation-rate state|
|`q_e_h5_Kcap`|Alternative-proxy robustness index using the restricted five-year moving-average exploitation-rate state|
|`source_provenance_ledger`|Full table-line-unit-vintage-sector-asset metadata|

The baseline distributive-output family is wage-share-centered and unadjusted in the first pass. Exploitation-rate variables remain alternative proxies. All adjusted distribution outputs remain blocked until the current-release Shaikh-style protocol passes.

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
    

The distributive side must also be auditable enough to distinguish between:

1. Wage-share levels.
    
2. Adjusted wage-share levels.
    
3. Residual profit-share complements.
    
4. NOS-based surplus-share diagnostics.
    
5. Exploitation-rate alternatives.
    
6. Logged exploitation-rate alternatives.
    
7. Preferred wage-share accumulated capital-growth indexes.
    
8. Alternative-proxy exploitation-rate accumulated capital-growth indexes.
    

This separation is necessary because replacing the wage share with the exploitation rate changes the scale and interpretation of the distributive state. It may be empirically useful, but it should remain a controlled alternative rather than a silent baseline substitution.

---

## 15. Current Lock

The U.S. source-of-truth dataset should preserve a broad BEA/NIPA/Fixed Assets variable menu, but the preferred productive-capacity capital stock remains:

$$  
K^{cap}_t = K^{ME}_t + K^{NRC}_t  
$$

IPP is excluded from `K_cap` but retained as a frontier-conditioning variable.

Government transportation fixed assets are excluded from `K_cap` but retained as public-infrastructure frontier-conditioning variables.

The preferred distributive conditioning variable is the wage share. While the current-release Shaikh-style protocol is blocked, the active first-pass state is the unadjusted wage share:

$$  
\omega_t = \frac{COMP_t}{VA_t}  
$$

The exploitation rate is retained as an alternative proxy for distributive conditions. Adjusted wage-share, profit-share, exploitation-rate, and accumulated-index variants remain blocked until the protocol passes and must be constructed separately if later admitted.

The active A00 transformation object is:

$$
y_t^p
=
\alpha
+
\theta_0 k_t
+
\theta_\omega q_t^{\omega,h}
+
u_t,
\qquad
\theta_t
=
\theta_0
+
\theta_\omega m_{t-1}^{(h)}.
$$

The inherited one-period wage-share state is the benchmark. The three-year and five-year wage-share moving averages are restricted robustness states. The corresponding exploitation-rate accumulated indexes are alternative-proxy robustness objects.

IPP and GOV_TRANS remain frontier conditioners, not additive capital terms. Any direct conditioning specification involving them is an extension or diagnostic and cannot override A00.

No Shaikh-adjusted income, distribution, accumulated-index, regression, capacity, or utilization object may enter S10/S20/S30/S40 while the current-release protocol is blocked.

This dataset architecture keeps the source of truth broad enough for audit and future specification redesign, while keeping the productive-capacity capital object theoretically disciplined.

The baseline is wage-share-centered. Exploitation-rate variables remain in the source-of-truth dataset as controlled alternatives, not as the preferred distributive primitive.
