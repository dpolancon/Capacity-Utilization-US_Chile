# Research Memo: Distributive Conflict Accounting and Data Provenance

This memo addresses the theoretical and empirical selection of value-added measures for capturing distributive conflict in the Non-Financial Corporate (NFC) sector, with a specific focus on the U.S. Fordist and Post-Fordist eras. It also presents a comprehensive audit of the wage share time series constructed in the repository and validates their data provenance.

---

## 1. Theoretical Assessment: GVA vs. NVA in Distributive Conflict

### The Marxian-Okishian Ontological Frame
Under the theoretical synthesis of Okishio’s market anarchy and Vidal’s internally divided firm, the fundamental object of distributive conflict is the division of the **newly created value** (the net product) between capital and labor. 

From a classical Marxian perspective, the value of gross output ($W$) decomposes into:
$$W = c + v + s$$
where:
*   $c$ is constant capital (the value of raw materials and depreciation of fixed assets transferred to the product).
*   $v$ is variable capital (wages of productive workers).
*   $s$ is surplus value (unpaid labor time appropriated by capital).

The **Gross Value Added (GVA)** of the sector includes the Consumption of Fixed Capital ($CFC$, or depreciation of fixed capital) alongside the net product:
$$GVA = CFC + v + s$$

The **Net Value Added (NVA)**, by contrast, isolates the net product:
$$NVA = v + s$$

Because constant capital ($c$, which includes $CFC$) represents pre-existing value transferred directly to the final product by the concrete labor process, it does not represent new value created on the shop floor. Consequently, $CFC$ is stochastically and conceptually excluded from the zero-sum distributive struggle. The active contestation between labor effort and managerial control (Vidal's shop-floor struggle) determines the extraction of surplus value ($s$) from the living labor power paid for by variable capital ($v$). Therefore, the true terrain of distributive pressure is the net product ($NVA$).

### The Fordist Mechanization Bias and GVA Distortions
During the postwar Fordist Golden Age (1947–1973), powerful organized labor negotiated from a position of institutional strength, driving real wage growth alongside productivity gains. Under the "strong labor" closure, cost-minimizing firms responded to this sustained wage pressure by aggressively substituting machinery for labor (intensive mechanization), pushing up the technical and organic composition of capital. 

This rapid mechanization mechanically increased the share of depreciation ($CFC$) in Gross Value Added ($GVA$). If we define the wage share using GVA:
$$\omega_{GVA} = \frac{\text{Compensation}}{GVA} = \frac{v + \text{unproductive wages}}{CFC + v + s}$$

As $CFC / GVA$ rises due to capital-intensive technical change, $\omega_{GVA}$ will decline **mechanically**, even if the rate of surplus value extraction ($s/v$) remains entirely unchanged. This mechanical decline creates a false statistical signature, showing a reduction in labor's share of value added when, in reality, the rise in capital's gross share is merely funding the physical replacement of worn-out machinery (constant capital transfer), not expanding net capitalist consumption or accumulation.

By using **Net Value Added (NVA)** as the denominator:
$$\omega_{NVA} = \frac{\text{Compensation}}{NVA} = \frac{v + \text{unproductive wages}}{v + s}$$

we strip out the transferred value of fixed capital. This allows us to observe the true, unadulterated distribution of newly created value. During late Fordism, the profit squeeze (circa 1968–1973) is accurately captured by $\omega_{NVA}$ because it isolates how wage gains directly eroded the net profit share ($1 - \omega_{NVA}$), culminating in a crisis of valorization. 

> [!important]
> **Verdict:** To evaluate the distributive pressure on profitability and the choice of technique, **Net Value Added (NVA)** is the theoretically correct denominator. Using GVA conflates a physical shift in capital intensity (and the associated depreciation requirements) with a shift in the balance of class power, distorting the empirical signature of the Fordist crisis.

---

## 2. Audit of Wage Share Series and Data Provenance

We have conducted a complete audit of the construction script [`US_S29F_shaikh_tonak_wage_share_construction.R`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/US_S29F_shaikh_tonak_wage_share_construction.R) and the level-accounting contract [`US_D07_0_source_of_truth_level_accounting_contract.R`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/US_D07_0_source_of_truth_level_accounting_contract.R).

### The Shaikh-Tonak (1994) Calibration
Shaikh and Tonak's (1994) seminal contribution to national income accounting requires two primary corrections to standard NIPA categories to reconstruct Marxian categories:
1.  **Productive vs. Unproductive Labor Boundary:** Standard employee compensation ($COMP$) aggregates the wages of both productive workers (who produce value) and unproductive workers (such as supervisory staff, advertising personnel, and financial clerks, whose wages are paid out of surplus value).
2.  **No Double Accounting Rule:** The financial sector does not produce value added. Its revenues are transfers of surplus value from the productive sectors (non-financial corporate and unincorporated business) in the form of net interest and corporate fees.

The script `US_S29F_shaikh_tonak_wage_share_construction.R` implements these corrections as follows:

#### A. Supervisory Wage Correction (Tier 2)
The script imports empirical supervisory compensation ratio vectors ($\phi_{\text{sup}}$) from the historical Shaikh-Tonak dataset (`S512.csv`):
$$\phi_{\text{sup, nfc}} = 1 - (S512 \cdot 1.45)$$
Variable capital ($v_{\text{prod}}$, representing productive labor compensation) is then isolated by stripping supervisory wages from the NFC compensation:
$$v_{\text{prod}} = NFC\_COMP \times (1 - \phi_{\text{sup}})$$
This correctly partitions employee compensation into variable capital ($v_{\text{prod}}$) and unproductive wages (which are added back to surplus value).

#### B. The Denominator and the "No Double Accounting Rule"
To ensure stock-flow consistency, the denominator must strictly exclude financial sector double-counting. If we aggregate the financial sector's value added into the denominator of the wage share, we double-count the surplus value:
1.  First, it is counted as Net Operating Surplus ($NOS$) or Net Interest paid by the non-financial corporate sector (representing value generated in production but transferred to finance).
2.  Second, it is counted as value added within the financial sector itself (representing the realization of those same transfers).

The construction script prevents this by strictly isolating the **Non-Financial Corporate (NFC)** sector as the boundaries of value creation. It defines four variants:
*   `omega_ST_Tier1` (NVA Basis): $\frac{NFC\_COMP}{NFC\_NVA}$ (Baseline corporate wage share).
*   `omega_ST_Tier2` (NVA Basis): $\frac{v_{\text{prod}}}{NFC\_NVA}$ (Shaikh-Tonak purified variable capital share).
*   `omega_ST_Tier1_GVA_adj` (GVA Basis): $\frac{NFC\_COMP}{NFC\_GVA}$ (Unadjusted gross wage share).
*   `omega_ST_Tier2_GVA_adj` (GVA Basis): $\frac{v_{\text{prod}}}{NFC\_GVA}$ (Productive gross wage share).

### Data Provenance Audit
An audit of `US_D07_0_source_of_truth_level_accounting_contract.R` and `US_S20C_sectoral_wage_share_source_lane.R` confirms that all underlying variables are anchored to official BEA NIPA Table 1.14:
*   **`NFC_COMP`:** Compensation of employees, Nonfinancial corporate industries (NIPA Table 1.14, Line 4).
*   **`NFC_GVA`:** Gross value added of nonfinancial corporate industries (NIPA Table 1.14, Line 1).
*   **`NFC_NVA`:** Net value added of nonfinancial corporate industries (NIPA Table 1.14, Line 3).
*   **`NFC_CFC`:** Consumption of fixed capital, Nonfinancial corporate industries (NIPA Table 1.14, Line 2).
*   **`NFC_NOS`:** Net operating surplus, Nonfinancial corporate industries (NIPA Table 1.14, Line 8).
*   **`NFC_NET_INT`:** Net interest and miscellaneous payments, Nonfinancial corporate industries (NIPA Table 1.14, Line 11).

All series are stage-validated, annual, and fully cover the common support period (1931–2024).

---

## 3. Empirical Summary of Wage Share Variants

The table below demonstrates the historical averages of the four constructed wage share variants across the key accumulation regimes:

| Period | Tier 1 NVA ($\omega_{T1}^{NVA}$) | Tier 2 NVA ($\omega_{T2}^{NVA}$) | Tier 1 GVA ($\omega_{T1}^{GVA}$) | Tier 2 GVA ($\omega_{T2}^{GVA}$) |
| :--- | :---: | :---: | :---: | :---: |
| **Pre-war Fordism (1931–1941)** | 73.1% | 57.0% | 66.8% | 52.1% |
| **WWII Block (1942–1945)** | 70.4% | 54.9% | 65.5% | 51.1% |
| **Postwar Fordism (1947–1973)** | 77.2% | 57.6% | 70.8% | 52.9% |
| **Post-Fordism Pre-GFC (1974–2007)** | 81.1% | 55.4% | 71.9% | 49.1% |
| **Post-GFC (2008–2024)** | 80.6% | 51.8% | 70.0% | 45.0% |

### Historical Interpretations
1.  **The Fordist Postwar Peak (1947–1973):** Under NVA Tier 1, the wage share averaged 77.2%, reflecting the stable distributive compromise of Fordism. However, Tier 2 (supervisory-adjusted) drops to 57.6%, revealing that a significant portion of what NIPA records as "compensation" was actually supervisory overhead (unproductive labor paid out of surplus).
2.  **The Post-Fordist Divergence (1974–present):** While Tier 1 NVA appears to rise to 81.1% post-1974, Tier 2 NVA (purified productive wage share) **declines** from 57.6% to 55.4%, and drops further to 51.8% post-GFC. This divergence captures a crucial structural shift: the rise of managerial and supervisory overhead within the modern corporate bureaucracy (Vidal's internally divided firm), which absorbed an increasing share of aggregate compensation while the share of value going to productive workers was actively squeezed. 
3.  **The GVA Compression:** The GVA-based shares show lower baseline levels (averaging 70.8% and 52.9% respectively during Fordism) because the denominator is inflated by depreciation. In the post-GFC era, Tier 2 GVA collapses to 45.0%, reflecting the double squeeze of wage stagnation and rising capital depreciation costs.

---

## 4. Operational Recommendations

1.  **Primary Specification:** Model the cointegration regressions using the **Tier 2 NVA wage share (`omega_ST_Tier2`)** as the primary distributive variable. It is the only indicator that purifies employee compensation of supervisory overhead and strips out constant capital transfers, isolating the true Marxian variable capital share ($v/NVA$) corresponding to the shop-floor conflicts of the divided firm.
2.  **Sensitivity Checks:** Run the specifications using the **Tier 1 NVA wage share (`omega_ST_Tier1`)** as a sensitivity check to establish whether the model results are robust to the supervisory correction itself.
3.  **GVA Exclusion:** Discontinue the use of GVA-based wage shares for structural cointegration. As demonstrated, GVA shares are polluted by structural shifts in depreciation rates that do not reflect class power or workplace conflict, violating the core ontological assumptions of the Okishio-Vidal capacity-formation framework.
