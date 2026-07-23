# Comprehensive Analysis & Outline Replacement Strategy for `Ch2_Outline_DEFINITIVE.md`

**Agent:** Explorer 2  
**Milestone:** Milestone 1 — Chapter 2 Outline Pruning & Scoping Partition  
**Target File:** `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md`  
**Working Directory:** `c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_explorer_m1_2`  
**Date:** 2026-07-23  

---

## 1. Executive Summary & Problem Statement

This analysis provides the definitive audit and edit plan for pruning `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md`. The objective is to enforce the **Chapter 2 / Chapter 3 Scoping Partition** established in `Advisor_Review_2026-07-23.md` (Requirement R1) and align the outline strictly with the notation, voice, and methodological rules of `AGENTS.md`.

### Core Scoping Boundary (Requirement R1)
*   **Chapter 2 Scope:** Bounded exclusively to the **Productive-Capacity Corridor** ($\theta_t \rightarrow \mu_t \rightarrow r_t$). Reconstructs potential capacity $\hat{Y}_t^p$, recovers utilization $\hat{\mu}_t$, and terminates at the Weisskopf profit rate decomposition ($r_t = \mu_t b_t \pi_t$).
*   **Chapter 3 Scope:** Relocates the **Recapitalization Corridor** ($\chi_t \rightarrow k_t \rightarrow g_t$) and all dynamic investment function estimations (ARDL/VECM/Local Projections feedback of utilization onto accumulation) to Chapter 3. Chapter 3 will take $\hat{\mu}_t$ from Chapter 2 as a given structural regressor.

---

## 2. Targeted Occurrences & Line Number Audit

Below is the complete line-by-line inventory of all affected sections, subsections, and paragraphs in `Ch2_Outline_DEFINITIVE.md`.

### 2.1 Subsection 2.3.3 & Paragraph 2.3.3 (Recapitalization Corridor)
*   **Line 70:** `#### Subsection 2.3: Synthesis and the Two-Corridor Process Tracing`
*   **Lines 75–76:**
    ```markdown
    *   **Paragraph 2.3.3:** *Name: The Recapitalization Corridor*
        *   *Focus:* Define the second corridor, linking the recapitalization rate ($\chi$), capital accumulation ($k$), and macroeconomic growth ($g$).
    ```
*   **Lines 77–78:**
    ```markdown
    *   **Paragraph 2.3.4:** *Name: Bridging Micro Contradiction to Macro Disequilibrium*
        *   *Focus:* Summarize how firm-level struggles over effort and capacity scale up to determine the macroeconomic transformation of accumulation into active capacity.
    ```
*   **Audit Finding:** Paragraph 2.3.3 defines the recapitalization corridor ($\chi_t \rightarrow k_t \rightarrow g_t$) which belongs in Chapter 3. Subsection 2.3 title references "Two-Corridor". Paragraph 2.3.4 needs explicit framing that investment feedback is deferred to Chapter 3. Also, line 76 violates `AGENTS.md` notation by omitting sub-t subscripts ($\chi, k, g \rightarrow \chi_t, k_t, g_t$).

### 2.2 Investment Function References in Section 4 & Section 5
*   **Lines 112–148 (Section 4: Empirical Strategy and Identification Framework):**
    *   *Line 126 (Paragraph 4.2.2):* Uses parameter $\psi$ in $y_t = \alpha + \theta k_t + \psi \tau_t + \phi \tilde{d}_t + \lambda (\tau_t \tilde{d}_t)$. Here $\psi$ represents the composition coefficient (machinery/structures ratio $\tau_t$), not an investment response parameter $\psi_j$. However, to avoid ambiguity with investment response notation and enforce R1, Section 4 must be explicitly bounded to long-run cointegrating capacity equations, excluding any accumulation rate ($g_k$) or investment response functions.
    *   *Line 138 (Paragraph 4.3.3):* `$u_{t_0} = 1$` — **CRITICAL NOTATION VIOLATION of `AGENTS.md`**. `AGENTS.md` mandates: "`μ_t` = capacity utilization = Y/Y^p — never 'u'".
    *   *Omissions per Advisor Directives:* Missing explicit definitions of econometric admissibility, measurement error bias on $\theta_t$, raw growth rate descriptive grounding (Marglin emulation), and the two required pedagogical counterfactuals ($\theta=1.0$ and No-Dummy).
*   **Lines 150–180 (Section 5: Empirical Results - US and Chile):**
    *   *Line 154 (Paragraph 5.1.1):* Missing explicit "Visual-First" step (plotting raw trends before FM-OLS) required by UMass Applied Econometrics checklist.
    *   *Line 177–178 (Paragraph 5.3.3):* Needs explicit check for residual stationarity ($I(0)$).

### 2.3 Subsection 6.1 (Tracing the Corridors & Subsections 6.1.2 / 6.1.3)
*   **Line 184:** `#### Subsection 6.1: Tracing the Corridors`
*   **Lines 185–187 (Paragraph 6.1.1):**
    ```markdown
    *   **Paragraph 6.1.1:** *Name: US Corridor Analysis*
        *   *Focus:* Use the process-tracing playbook to evaluate the US case: how $\theta_t$ and $\mu_t$ conditioned the profit rate, and how $\chi_t$ drove accumulation.
    ```
    *Audit:* "how $\chi_t$ drove accumulation" violates the scoping partition.
*   **Lines 188–189 (Paragraph 6.1.2):**
    ```markdown
    *   **Paragraph 6.1.2:** *Name: Chile Corridor Analysis*
        *   *Focus:* Trace the Chilean case, showing how external balance constraints choked the recapitalization corridor.
    ```
    *Audit:* Focuses on choking the "recapitalization corridor" instead of the capacity-to-profitability transmission.
*   **Lines 190–191 (Paragraph 6.1.3):**
    ```markdown
    *   **Paragraph 6.1.3:** *Name: Comparative Corridor Synthesis*
        *   *Focus:* Synthesize the comparison: how the interaction between capacity and recapitalization corridors differed across center and periphery.
    ```
    *Audit:* Directly references interaction with recapitalization corridors.
*   **Refocus Strategy for Section 6.1:** Refocus Section 6.1 entirely on the **Productive-Capacity Corridor** ($\theta_t \rightarrow \mu_t \rightarrow r_t$) and the Weisskopf profit rate decomposition ($r_t = \mu_t \cdot b_t \cdot \pi_t$).

### 2.4 Section 7 (Conclusion & Chapter 3 Bridge Framing)
*   **Lines 210–223 (Section 7: Conclusion):**
*   **Lines 218–220 (Paragraph 7.2.1):**
    ```markdown
    *   **Paragraph 7.2.1:** *Name: Programmatic Horizon*
        *   *Focus:* Outline future research avenues, including the integration of full profitability decompositions and expanded process-tracing datasets.
    ```
    *Audit:* Currently a generic description. Must be updated to explicitly frame the **Recapitalization Corridor** ($\chi_t \rightarrow k_t \rightarrow g_t$) and long-run investment/growth feedback estimation as the structural bridge to Chapter 3, where $\hat{\mu}_t$ from Chapter 2 is passed forward as an exogenous structural regressor.

---

## 3. Compliance Check against `AGENTS.md` Rules

| Rule Category | Standard | Evaluation & Required Adjustment in Plan |
| :--- | :--- | :--- |
| **Capacity Utilization Notation** | `\mu_t` = Y/Y^p — **never `u`** | Fixed line 138 (`$u_{t_0} = 1$` $\rightarrow$ `$\mu_{t_0} = 1$`). |
| **Recapitalization Notation** | `\chi_t` = I/\Pi — **never `\beta_t`** | Fixed subscript notation in text (`\chi_t`). |
| **Mechanization Growth Rate** | `q` — **never `m`** | Maintained `q` for mechanization; `m` reserved for import propensity. |
| **Transformation Elasticity** | `\theta_t = \theta_1 + \theta_2 \pi_t` | Standardized parameter symbols with explicit sub-$t$ subscripts. |
| **Capital Composition** | `K^{NR}` (structures), `K^{ME}` (machinery) | Maintained BEA asset classification boundary in Section 4.4. |
| **Voice & Tone** | Active voice $\ge 70\%$, WLM v4.0 | Formulated paragraph focus statements in active, direct prose. |
| **Estimator/Parameter Scoping** | No investment functions in Ch2 | Deleted all accumulation rate ($g_k$) and recapitalization ($\chi_t$) estimations from Ch2. |

---

## 4. Precise Replacement Plan

This replacement plan details the exact contiguous chunks to be edited in `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md`.

### Chunk 1: Section 2.3 Refocus & Paragraph 2.3.3 Pruning
*   **Line Range:** 70–78
*   **Instruction:** Update Subsection 2.3 header, integrate stylized parameters into Paragraph 2.3.1, retain Paragraph 2.3.2, remove Paragraph 2.3.3, and rewrite Paragraph 2.3.4 to frame the micro-meso ceiling determination and defer investment feedback to Chapter 3.
*   **Target Content:**
```markdown
#### Subsection 2.3: Synthesis and the Two-Corridor Process Tracing
*   **Paragraph 2.3.1:** *Name: Reinterpreting the Mechanization Frontier*
    *   *Focus:* Synthesize Okishio and Vidal. Reframe the mechanization frontier from a firm-level optimization problem into a macro-structural envelope of historical class conflict.
*   **Paragraph 2.3.2:** *Name: The Productive-Capacity Corridor*
    *   *Focus:* Define the first process-tracing corridor, linking the capacity elasticity ($\theta$), realized utilization ($\mu$), and the profit rate ($r$).
*   **Paragraph 2.3.3:** *Name: The Recapitalization Corridor*
    *   *Focus:* Define the second corridor, linking the recapitalization rate ($\chi$), capital accumulation ($k$), and macroeconomic growth ($g$).
*   **Paragraph 2.3.4:** *Name: Bridging Micro Contradiction to Macro Disequilibrium*
    *   *Focus:* Summarize how firm-level struggles over effort and capacity scale up to determine the macroeconomic transformation of accumulation into active capacity.
```
*   **Replacement Content:**
```markdown
#### Subsection 2.3: Synthesis and Process Tracing: The Productive-Capacity Corridor
*   **Paragraph 2.3.1:** *Name: Reinterpreting the Mechanization Frontier*
    *   *Focus:* Synthesize Okishio and Vidal. Reframe the mechanization frontier from a firm-level optimization problem into a macro-structural envelope of historical class conflict. Introduce stylized baseline parameters ($g_k = 3\%$, $g_{yp} = 2\%$, $\theta = 0.8$) and define the capital acceleration term ($d\hat{k}/dt$) to ground the capacity equations.
*   **Paragraph 2.3.2:** *Name: The Productive-Capacity Corridor*
    *   *Focus:* Define the productive-capacity corridor, linking distributional conditioning to the transformation elasticity ($\theta_t$), realized capacity utilization ($\mu_t$), and the profit rate ($r_t$) via the Weisskopf decomposition ($r_t = \mu_t b_t \pi_t$).
*   **Paragraph 2.3.3:** *Name: Bridging Micro Contradiction to Macro Disequilibrium*
    *   *Focus:* Summarize how shop-floor struggles over effort calibration and contested capacity conventions scale up to establish the aggregate capacity ceiling ($\hat{Y}_t^p$), explicitly noting that the feedback of this capacity ceiling onto long-run capital accumulation and dynamic investment functions ($\chi_t \rightarrow k_t \rightarrow g_t$) is deferred to Chapter 3.
```

---

### Chunk 2: Section 4 Updates (Notation Fix, Admissibility, Counterfactuals & Marglin Grounding)
*   **Line Range:** 132–144
*   **Instruction:** Fix `$u_{t_0} = 1$` notation violation in Paragraph 4.3.3, insert Paragraph 4.3.4 on Econometric Admissibility & Pedagogical Counterfactuals, and add Marglin descriptive grounding to Paragraph 4.4.1.
*   **Target Content:**
```markdown
#### Subsection 4.3: Estimator Hierarchy and Normalization
*   **Paragraph 4.3.1:** *Name: FM-OLS as Preferred Estimator*
    *   *Focus:* Justify FM-OLS as the primary estimator due to its ability to correct for endogeneity and serial correlation in log-level regressions.
*   **Paragraph 4.3.2:** *Name: IM-OLS Robustness and DOLS Exclusion Rationale*
    *   *Focus:* Justify the use of IM-OLS as a check and explain why DOLS is excluded (its differencing dynamics insert non-structural terms that distort $\theta_t$).
*   **Paragraph 4.3.3:** *Name: Normalization and Level Anchoring (Pinch Year)*
    *   *Focus:* Explain the role of the pinch year ($u_{t_0} = 1$) to anchor the utilization level, and outline sensitivity tests across alternative years.

#### Subsection 4.4: Data Construction and Harmonization
*   **Paragraph 4.4.1:** *Name: US BEA Source Pathways*
    *   *Focus:* Detail the construction of US corporate sector variables from BEA NIPA and Fixed Asset Tables, emphasizing the separation of structures and machinery.
```
*   **Replacement Content:**
```markdown
#### Subsection 4.3: Estimator Hierarchy and Normalization
*   **Paragraph 4.3.1:** *Name: FM-OLS as Preferred Estimator*
    *   *Focus:* Justify FM-OLS as the primary estimator due to its ability to correct for endogeneity and serial correlation in log-level regressions.
*   **Paragraph 4.3.2:** *Name: IM-OLS Robustness and DOLS Exclusion Rationale*
    *   *Focus:* Justify the use of IM-OLS as a check and explain why DOLS is excluded (its differencing dynamics insert non-structural terms that distort $\theta_t$).
*   **Paragraph 4.3.3:** *Name: Normalization and Level Anchoring (Pinch Year)*
    *   *Focus:* Explain the role of the pinch year ($\mu_{t_0} = 1$) to anchor the utilization level, and outline sensitivity tests across alternative peak-utilization years.
*   **Paragraph 4.3.4:** *Name: Econometric Admissibility and Pedagogical Counterfactuals*
    *   *Focus:* Explicitly define econometric admissibility as the survival of cointegration under structural distribution. Schedule two mandatory counterfactuals: (1) the Restriction Counterfactual ($\theta = 1.0$) to demonstrate the economic absurdity of imposing balanced growth, and (2) the No-Dummy Counterfactual to prove that omitting structural breaks generates spurious cointegration.

#### Subsection 4.4: Data Construction and Harmonization
*   **Paragraph 4.4.1:** *Name: US BEA Source Pathways and Descriptive Grounding*
    *   *Focus:* Detail the construction of US corporate sector variables from BEA NIPA and Fixed Asset Tables, emphasizing the separation of structures ($K^{NR}$) and machinery ($K^{ME}$). Emulate Stephen Marglin by integrating raw, non-econometric growth rates of GDP, employment, and capital (1947–2011) directly into the text to ground the econometrics.
```

---

### Chunk 3: Section 5 Visual-First Step & Section 6.1 Refocusing
*   **Line Range:** 152–191
*   **Instruction:** Insert Visual-First requirement into Paragraph 5.1.1, and completely restructure Subsection 6.1 to remove recapitalization corridor analysis and focus purely on capacity-to-profitability transmission.
*   **Target Content:**
```markdown
#### Subsection 5.1: US Estimation and Capacity Reconstruction
*   **Paragraph 5.1.1:** *Name: US Cointegration Performance*
    *   *Focus:* Present the ADF, EG, and Johansen test statistics for US bivariate and trivariate specifications.
*   **Paragraph 5.1.2:** *Name: US Transformation Elasticity ($\hat{\theta}_t$)*
    *   *Focus:* Report the recovered US elasticity coefficients, demonstrating how $\theta_t$ varies with the wage share.
*   **Paragraph 5.1.3:** *Name: Reconstructed US Capacity Utilization*
    *   *Focus:* Present the final US utilization series, highlighting cyclical behaviors and post-1973 structural shifts.
*   **Paragraph 5.1.4:** *Name: US Specification-Space Map*
    *   *Focus:* Display the robust results across the combinatorial space of lag lengths and dummy configurations.

#### Subsection 5.2: Chile Estimation and the External Wedge
*   **Paragraph 5.2.1:** *Name: Chile Cointegration Performance*
    *   *Focus:* Present cointegration tests for the Chilean baseline and the extended peripheral model.
*   **Paragraph 5.2.2:** *Name: Chilean Transformation Elasticity ($\hat{\theta}_t$)*
    *   *Focus:* Report the recovered Chilean elasticity and show how it responds to both distribution and the external wedge ($z_t$).
*   **Paragraph 5.2.3:** *Name: Reconstructed Chilean Capacity Utilization*
    *   *Focus:* Present the Chilean utilization series (1900–2024), detailing its behavior during the ISI era and neoliberal transition.
*   **Paragraph 5.2.4:** *Name: Chile Sensitivity Diagnostics*
    *   *Focus:* Map the specification space for Chile, comparing different choices of the external conditioning variable $z_t$.

#### Subsection 5.3: Comparative Synthesis
*   **Paragraph 5.3.1:** *Name: Capacity Volatility Comparison*
    *   *Focus:* Analyze the different levels of volatility in the recovered capacity ceilings of the US and Chile.
*   **Paragraph 5.3.2:** *Name: Elasticity Regimes Contrast*
    *   *Focus:* Contrast the US overaccumulation regime ($\hat{\theta}_t < 1.0$) with the Chilean externally constrained regime.
*   **Paragraph 5.3.3:** *Name: Residual and Cointegration Stability*
    *   *Focus:* Demonstrate the stability of the estimated cointegrating residuals across both countries.

---

### Section 6: Discussion and Theoretical Implications

#### Subsection 6.1: Tracing the Corridors
*   **Paragraph 6.1.1:** *Name: US Corridor Analysis*
    *   *Focus:* Use the process-tracing playbook to evaluate the US case: how $\theta_t$ and $\mu_t$ conditioned the profit rate, and how $\chi_t$ drove accumulation.
*   **Paragraph 6.1.2:** *Name: Chile Corridor Analysis*
    *   *Focus:* Trace the Chilean case, showing how external balance constraints choked the recapitalization corridor.
*   **Paragraph 6.1.3:** *Name: Comparative Corridor Synthesis*
    *   *Focus:* Synthesize the comparison: how the interaction between capacity and recapitalization corridors differed across center and periphery.
```
*   **Replacement Content:**
```markdown
#### Subsection 5.1: US Estimation and Capacity Reconstruction
*   **Paragraph 5.1.1:** *Name: US Cointegration Performance and Visual-First Grounding*
    *   *Focus:* Provide a non-parametric "Visual-First" analysis plotting raw time-series trends and scatter plots of output, capital, and wage shares before presenting parametric ADF, EG, and Johansen test statistics for US specifications.
*   **Paragraph 5.1.2:** *Name: US Transformation Elasticity ($\hat{\theta}_t$)*
    *   *Focus:* Report the recovered US elasticity coefficients, demonstrating how $\theta_t$ varies with the wage share.
*   **Paragraph 5.1.3:** *Name: Reconstructed US Capacity Utilization*
    *   *Focus:* Present the final US utilization series ($\hat{\mu}_t$), highlighting cyclical behaviors and post-1973 structural shifts.
*   **Paragraph 5.1.4:** *Name: US Specification-Space Map*
    *   *Focus:* Display the robust results across the combinatorial space of lag lengths and dummy configurations.

#### Subsection 5.2: Chile Estimation and the External Wedge
*   **Paragraph 5.2.1:** *Name: Chile Cointegration Performance*
    *   *Focus:* Present non-parametric visual trends followed by formal cointegration tests for the Chilean baseline and the extended peripheral model.
*   **Paragraph 5.2.2:** *Name: Chilean Transformation Elasticity ($\hat{\theta}_t$)*
    *   *Focus:* Report the recovered Chilean elasticity and show how it responds to both distribution and the external wedge ($z_t$).
*   **Paragraph 5.2.3:** *Name: Reconstructed Chilean Capacity Utilization*
    *   *Focus:* Present the Chilean utilization series ($\hat{\mu}_t$, 1900–2024), detailing its behavior during the ISI era and neoliberal transition.
*   **Paragraph 5.2.4:** *Name: Chile Sensitivity Diagnostics*
    *   *Focus:* Map the specification space for Chile, comparing different choices of the external conditioning variable $z_t$.

#### Subsection 5.3: Comparative Synthesis
*   **Paragraph 5.3.1:** *Name: Capacity Volatility Comparison*
    *   *Focus:* Analyze the different levels of volatility in the recovered capacity ceilings of the US and Chile.
*   **Paragraph 5.3.2:** *Name: Elasticity Regimes Contrast*
    *   *Focus:* Contrast the US overaccumulation regime ($\hat{\theta}_t < 1.0$) with the Chilean externally constrained regime.
*   **Paragraph 5.3.3:** *Name: Residual and Cointegration Stability*
    *   *Focus:* Demonstrate the stability and $I(0)$ stationarity of the estimated cointegrating residuals across both countries.

---

### Section 6: Discussion and Theoretical Implications

#### Subsection 6.1: Tracing the Productive-Capacity Corridor
*   **Paragraph 6.1.1:** *Name: US Productive-Capacity Transmission*
    *   *Focus:* Use the process-tracing playbook to trace how distribution-conditioned transformation elasticity ($\hat{\theta}_t$) and recovered capacity utilization ($\hat{\mu}_t$) shape the upper ceiling of US corporate profitability via the Weisskopf decomposition ($r_t = \mu_t b_t \pi_t$).
*   **Paragraph 6.1.2:** *Name: Chilean Productive-Capacity Transmission*
    *   *Focus:* Trace how external balance-of-payments constraints ($z_t$) condition Chilean capacity formation ($\hat{\theta}_t$) and utilization ($\hat{\mu}_t$), establishing a foreign-exchange-bounded ceiling on domestic profitability.
*   **Paragraph 6.1.3:** *Name: Comparative Profitability Transmission Synthesis*
    *   *Focus:* Synthesize the comparative transmission mechanisms: contrast how internal class-distributional mediation in the core vs. external technological dependency in the periphery constrain long-run profitability dynamics, without estimating accumulation feedback loops.
```

---

### Chunk 4: Section 7 Bridge Framing & Single-Sector Bounding Limitation
*   **Line Range:** 218–222
*   **Instruction:** Update Paragraph 7.2.1 to frame the recapitalization corridor as the structural bridge to Chapter 3 and note the single-sector macro bounding limitation.
*   **Target Content:**
```markdown
#### Subsection 7.2: Programmatic Horizon
*   **Paragraph 7.2.1:** *Name: Programmatic Horizon*
    *   *Focus:* Outline future research avenues, including the integration of full profitability decompositions and expanded process-tracing datasets.
*   **Paragraph 7.2.2:** *Name: Concluding Reflections*
    *   *Focus:* Present final reflections on the status of capacity utilization in heterodox growth theory.
```
*   **Replacement Content:**
```markdown
#### Subsection 7.2: Programmatic Horizon
*   **Paragraph 7.2.1:** *Name: Structural Bridge to Chapter 3 and Model Limitations*
    *   *Focus:* Explicitly frame the deferral of the Recapitalization Corridor ($\chi_t \rightarrow k_t \rightarrow g_t$) and dynamic investment function estimations as the structural bridge to Chapter 3, where Chapter 2's recovered utilization series ($\hat{\mu}_t$) serves as an input regressor for VECM and Local Projections growth models. Note the single-sector macro bounding of the overaccumulation model as an analytical limitation of Chapter 2.
*   **Paragraph 7.2.2:** *Name: Concluding Reflections*
    *   *Focus:* Present final reflections on the status of capacity utilization in heterodox growth theory, reinforcing that capacity is a socially contested, historically specific regime.
```

---

## 5. Summary of Edits & Next Steps

1. **Paragraph 2.3.3 Pruned:** Removed the recapitalization corridor definition from Chapter 2; refocused Paragraph 2.3.4 on shop-floor micro-contradictions scaling to macro capacity ceilings.
2. **Section 4 & Section 5 Updated:** Corrected `$u_{t_0}=1$` to `$\mu_{t_0}=1$`, added econometric admissibility definition, scheduled the restriction and no-dummy pedagogical counterfactuals, added Marglin descriptive grounding and Visual-First non-parametric plotting.
3. **Section 6.1 Restructured:** Renamed to "Tracing the Productive-Capacity Corridor", deleted recapitalization corridor analysis, refocused paragraphs 6.1.1–6.1.3 on capacity-to-profitability transmission via Weisskopf decomposition.
4. **Section 7 Updated:** Updated Paragraph 7.2.1 to explicitly frame the recapitalization corridor as the bridge to Chapter 3.

The replacement chunks above provide exact, unambiguous drop-in replacements for `replace_file_content` or `multi_replace_file_content` by Implementer agents.
