# §2.4 — Data
**Source authority:** Ch2_Outline_DEFINITIVE.md §2.4; dpolancon/US-BEA-Income-FixedAssets-Dataset; dpolancon/K-Stock-Harmonization
**Date drafted:** 2026-04-02
**Word count:** ~620
**Self-check:** PASS
**Transition check:** Exit ramp hands off to §2.5 (Stage A identification).

---

Both datasets that enter the chapter's estimation stages are the author's own constructions, maintained in reproducible GitHub repositories with complete pipeline documentation. Secondary sources — BEA tables, FRED series, CEPAL national accounts, the Pérez capital formation records — enter as inputs to those pipelines, not as direct chapter inputs. Every variable used in Stages A through C is traceable to a specific table fetch or harmonization step within the relevant repository. This section documents the variables, their provenance, and the sample structure that governs each estimation stage.

## §2.4.1 United States — `dpolancon/US-BEA-Income-FixedAssets-Dataset`

The US dataset is constructed from Bureau of Economic Analysis national income and fixed asset tables, supplemented by Bureau of Labor Statistics employment data and Federal Reserve interest rate series, all fetched via API. The R pipeline enforces stock-flow consistency through a Generalized Perpetual Inventory Method and produces a single canonical output panel. Table 2.1 reports the variables that enter the chapter's estimation stages.

**Table 2.1 — United States: Variables and Sources**

| Variable | Symbol | Source table | Notes |
|---|---|---|---|
| Real GDP | $Y_t$ | NIPA Table 1.1.6 | Chain-type quantity index, 2017 base |
| National income — profits | $\Pi_t$ | NIPA Table 1.12 | Corporate profits + net interest adjustment |
| National income — compensation | $W_t$ | NIPA Table 1.12 | Employee compensation; $\pi_t = \Pi_t / Y_t$ derived |
| Net nonresidential capital stock | $K_t$ | BEA Fixed Assets Table 2.1 | Current-cost net stock, corporate sector |
| Net capital — structures | $K_t^{NR}$ | BEA Fixed Assets Table 2.1 | Nonresidential structures; Stage A comparator |
| Net capital — equipment | $K_t^{ME}$ | BEA Fixed Assets Table 2.1 | Machinery and equipment; Stage A comparator |
| Gross private nonresidential investment | $I_t$ | NIPA Table 1.1.5 | Enters $\chi_t = I_t / \Pi_t$ |
| Employment | $L_t$ | BLS Current Employment Statistics (FRED) | For $a_t = y_t - l_t$, $q_t = k_t - l_t$ |
| Interest rate | $i_t$ | Moody's Baa corporate yield (FRED) | Stage C only (Shaikh 2016 spec) |

**Sample available:** 1929–2024 (full BEA/FRED coverage). Primary estimation window: 1945–1978. Stage A uses the full sample for MPF estimation and capacity utilization recovery.

## §2.4.2 Chile — `dpolancon/K-Stock-Harmonization`

The Chilean capital stock dataset is a stock-flow consistent harmonization of three production surfaces, constructed in a Python pipeline that enforces cross-source consistency at every splice point. The three surfaces differ in temporal coverage, price base, and control concept. Table 2.2 reports their structure.

**Table 2.2 — Chile: Capital Stock Production Surfaces**

| Surface | Coverage | Price base | Control concept | Status |
|---|---|---|---|---|
| Hofman accounting reference | 1900–1994 | 1980 CLP | Hofman (2000) totals | Frozen; audit reference only |
| **Canonical Pérez baseline** | **1900–1994** | **2003 CLP** | **Pérez machinery + construction; inventories excluded** | **Primary** |
| BCCh extension bundle | 1900–2024 | 2003 CLP | Canonical 1900–1994 preserved; BCCh net stocks forward | Extended |

The canonical surface's asset decomposition maps directly onto the Stage A.2 structural split: $K_t^{ME,CL}$ is the machinery component (Pérez FBKF machinery through 1994; BCCh forward from 1995) and $K_t^{NR,CL}$ is the construction component (Pérez FBKF construction through 1994; BCCh forward from 1995). This resolves the Stage A.2 capital-type stage-gate: direct disaggregation is available without proxy or indirect inference for $\bar{\alpha}_1^{CL}$. The companion investment price deflator $P_K$ uses the BCCh ratio deflator (nominal/real FBKF) for 1960–2024 and a ClioLab ratio-growth chain for 1940–1959, both rebased to 2003 = 100.

**Table 2.3 — Chile: Supplementary Variables**

| Variable | Symbol | Source | Notes |
|---|---|---|---|
| Real GDP | $Y_t^{CL}$ | CEPAL; Central Bank of Chile | |
| Gross investment flows | $I_t^{CL}$ | CEPAL national accounts | Stock-flow consistent with K-Stock repository |
| Gross operating surplus | $\Pi_t^{CL}$ | CEPAL national accounts | |
| Profit share | $\pi_t^{CL}$ | Alarco Tosoni (2014); Astorga (2023) | Spliced series |
| Employment | $L_t^{CL}$ | CEPAL; Díaz et al. (2016) | Spliced; for $a_t^{CL}$, $q_t^{CL}$ |
| Terms of trade | $\text{ToT}_t$ | CEPAL | Stage A.2 BoP proxy if Approach 1 needed |

**Sample available:** Capital stock: 1900–2024 (BCCh bundle). GDP and income variables: ~1940–2024. Primary estimation: 1945–1978.

## §2.4.3 Sample and Periodization

**Table 2.4 — Estimation Windows by Stage**

| Stage | Sample | Rationale |
|---|---|---|
| Stage A.1 — MPF estimation (US) | Full BEA/FRED sample (~1929–2024) | MPF requires maximum variation in $q_t$ |
| Stage A.2 — MPF estimation (Chile) | Full K-Stock sample (~1940–2024) | GDP availability binds the effective start |
| Stage B — Weisskopf profitability | 1945–1978 (primary); rolling windows | Fordist regime boundaries |
| Stage C — ARDL investment function | 1945–1978 (primary); rolling windows | Fordist regime boundaries |

Stage A uses the full available sample because the MPF's quadratic structure requires sufficient variation in the mechanization growth rate $q_t$ to identify $\alpha_1$ and $\alpha_2$ — restricting to the Fordist window alone would suppress the post-1978 regime variation that sharpens the frontier's curvature. Stages B and C restrict to 1945–1978 as the primary estimation window, corresponding to the Fordist accumulation regime in the United States and the inward-looking industrialization regime in Chile.

Sub-period turning points within the 1945–1978 window are identified endogenously from wage-share dynamics following Shaikh's (2016) invariance principle: the profit-share series itself determines phase boundaries, with no mechanically imposed periodization. For Chile, the 1973–1975 coup disruption produces extreme values in $q_t^{CL}$ and $a_t^{CL}$. The MPF is estimated excluding these three observations; sensitivity analysis with the full sample is reported alongside.
