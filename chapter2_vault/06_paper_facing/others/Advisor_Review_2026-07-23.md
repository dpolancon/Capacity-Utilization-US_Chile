---
type: paper_facing
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-23
date: 2026-07-23
reviewer: Michael Ash
candidate: Diego Polanco
subject: Chapter 2 Scoping Partition and Applied Econometrics Review
authority_files:
  - chapter2_vault/00_constitutive_core/01_Governing_Memo.md
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
subtype: paper_facing_map
blocks: []
layer: design
scope: chapter2
priority: context
---

# Advisor Review: Chapter 2 Scoping Partition & Applied Econometrics Audit
**Date of Review:** July 23, 2026  
**Reviewer:** Michael Ash (Chair/Advisor, UMass Amherst)  
**Candidate:** Diego Polanco  

This document serves as the official review and scoping agreement for Chapter 2. It establishes a formal partition between Chapter 2 and Chapter 3 to narrow the analytical scope, and provides an audit of the definitive outline against UMass Amherst applied econometrics guidelines and advisor directives.

---

## 1. The Chapter 2 / Chapter 3 Scoping Partition

To prevent analytical over-extension and ensure a tight, cohesive narrative, we are establishing a strict partition between the two macro-corridors defined in the process-tracing playbook:

### Chapter 2 Bounding: The Productive-Capacity Corridor ($\theta \rightarrow \mu \rightarrow r$)
Chapter 2 will focus exclusively on the theoretical reconstruction, empirical identification, and comparative regimes of the capacity ceiling and capacity utilization. 
*   **Theoretical Core:** The Okishio–Vidal synthesis explaining how decentralized market anarchy is internalized within the divided firm, determining the conversion of capital into capacity.
*   **Empirical Task:** Estimating the distribution-conditioned transformation elasticity ($\theta_t$) and recovering the latent capacity utilization series ($\mu_t$) for the US (domestic scale/composition conditioning) and Chile (externally constrained by the balance of payments and imported technology).
*   **Downstream Payne:** The empirical analysis terminates at the recovered capacity utilization series and its immediate implications for the profit rate via the Weisskopf decomposition ($r = \mu b \pi$).
*   **Excluded:** All estimation of accumulation/investment functions, recapitalization rates ($\chi_t$), and long-run growth feedback loops.

### Chapter 3 Relocation: The Recapitalization Corridor ($\chi \rightarrow k \rightarrow g$)
All dynamics of recapitalization and long-run growth feedback are pushed to Chapter 3.
*   **Empirical Core:** Estimating dynamic investment functions (ARDL/VECM) and testing the recapitalization response to demand and profitability.
*   **Methodology:** Vector Error Correction Models (VECM) and Local Projections (LP) to trace how shocks to utilization or distribution feed back into long-run capital accumulation ($g_k$) and macroeconomic growth ($g$).
*   **Chapter 3 Handoff:** Chapter 3 will take the recovered capacity utilization series ($\hat{\mu}_t$) from Chapter 2 as a given structural regressor.

---

## 2. Outline Restructuring Ledger (The Partition Applied)

To implement this partition, the following structural edits must be made to [Ch2_Outline_DEFINITIVE.md](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md):

*   **Section 2.3 (Synthesis & Corridors):** Delete Paragraph 2.3.3 (The Recapitalization Corridor). Retain Paragraph 2.3.2 (Productive-Capacity Corridor) and rewrite Paragraph 2.3.4 to frame how the micro-contradictions of the labor process scale up to determine the capacity ceiling, explicitly noting that the feedback of this ceiling onto investment is deferred to Chapter 3.
*   **Section 4 & 5 (Method & Results):** Remove all references to estimating accumulation rates ($g_k$), recapitalization parameters ($\chi_t$), or testing investment response coefficients ($\psi_j$).
*   **Section 6.1 (Tracing the Corridors):** Remove the recapitalization corridor analysis (Paragraph 6.1.2) and the comparative corridor synthesis (Paragraph 6.1.3). Refocus this section entirely on tracing how the recovered capacity-formation elasticity ($\theta_t$) and utilization ($\mu_t$) shape the limits of profitability ($r$) in the US and Chile.
*   **Section 7 (Conclusion):** Explicitly frame the deferral of the recapitalization corridor as the structural bridge to Chapter 3.

---

## 3. UMass Applied Econometrics & Style Audit

We evaluated the outline against the 10-point UMass Applied Econometrics checklist:

1.  **BLUF Check (Passed):** Paragraph 1.1 successfully plans to state the thesis and comparative results by the second paragraph of the Introduction.
2.  **Variable Audit (Warning):** Every mathematical parameter (specifically $\theta_t$, $\mu_t$, $e_t$, $\omega_t$, and $z_t$) must be defined in the text immediately upon its first appearance.
3.  **Active Voice Check (Passed):** The outline is drafted using active verbs. This tone must carry over into the drafting phase.
4.  **Visual-First Test (Critical Warning):** You must include non-parametric visualizations (e.g., local regressions, scatter plots of output on capital and wage share) in Section 5 *before* presenting the parametric FM-OLS/VECM results.
5.  **Forensic Transparency (Passed):** Subsection 4.4 properly schedules GPIM data construction, retirement rate assumptions ($\rho$), and database harmonization sensitivities.
6.  **Endogeneity & VECM Checks (Passed):** Cointegration tests and trivariate VECM checks are scheduled to control for bidirectional feedback between distribution and capacity.
7.  **Specification Map (Passed):** Paragraph 5.1.4 and 5.2.4 schedule the combinatorial specification-space maps (ARDL/FM-OLS lag and dummy profiles) to demonstrate "disciplined non-uniqueness."
8.  **Descriptive Grounding (Critical Warning - Marglin Emulation):** You must integrate raw, non-econometric growth rates of GDP, employment, and capital for the US corporate sector (1947–2011) directly within the narrative (Section 3.1 & Section 4.4) to contextualize the econometrics, emulating Stephen Marglin's approach.
9.  **Institutional Critique (Passed):** Paragraph 2.2.4 successfully deconstructs mainstream capacity indicators as contested conventions shaped by class conflict.
10. **Tone Balance (Passed):** The outline avoids academic posturing and snobbish language, focusing directly on the physical and institutional transmission mechanisms.

---

## 4. Advisor-Specific Directives & Required Updates

Ensure the following specific directives are addressed in the final outline updates and draft:

*   **Admissibility Definition:** Explicitly define "econometric admissibility" in Section 4. Frame it in terms of counterfactuals (e.g., what specifications fail cointegration and why).
*   **Residual Stationarity:** Section 5.3 must explicitly check and report residual stationarity ($I(0)$), with no attempts to smooth over nonstationary residuals.
*   **Single-Sector Bounding Limitation:** You must explicitly discuss the *single-sector macro bounding* of the overaccumulation and stagnation tendency regime classification (Table 1) as an analytical limitation of the model in Section 6.2 and 7.2.
*   **Measurement Error Bias on $\theta$:** Discuss the downward bias of $\theta_t$ caused by RHS measurement error in Perpetual Inventory capital stocks in Section 4.1 or 4.3.
*   **Stylized Baseline Parameters:** In Section 2.3 and Section 3, introduce a simplified, stylized numerical baseline (e.g., $g_k = 3\%$, $g_{yp} = 2\%$, and $\theta = 0.8$) to ground the capacity equations.
*   **The Punchline Principle:** Ensure Section 3.2 (Chile) and Section 6.2 have clear economic punchlines (e.g., *"A 1% increase in imported capital goods constraint shifts the transformation elasticity by X%..."*).
*   **Mandatory Pedagogical Counterfactuals:** The outline must schedule the two required counterfactuals:
    1.  *The Restriction Counterfactual* ($\theta = 1.0$) in Section 4.3/5.1 (demonstrating the economic absurdity of imposing balanced growth).
    2.  *The No-Dummy Counterfactual* in Section 4.3/5.2 (demonstrating that omitting structural breaks results in spurious cointegration).

---

## 5. Prioritized Revision Matrix

Update the definitive outline ([Ch2_Outline_DEFINITIVE.md](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md)) to reflect this partition and the advisor's directives:

| Section / Paragraph | Required Change | Rationale / Source Directive |
| :--- | :--- | :--- |
| **Section 2.3.1 (Synthesis)** | Integrate the stylized numerical baseline parameters ($g_k=3\%$, $g_{yp}=2\%$, $\theta=0.8$) and define the capital acceleration term ($d\hat{k}/dt$). | *Advisor Directive: Down-to-Earth Math* |
| **Section 2.3.3 (Delete)** | **DELETE** Subsection 2.3.3 (Recapitalization Corridor). | *Scoping Partition* |
| **Section 4.1.1 (Latent Capacity)**| Add discussion on the downward bias of $\theta_t$ caused by RHS measurement error in capital stocks. | *Advisor Directive: Theta Bias check* |
| **Section 4.3.3 / 4.3.4 (New)** | Insert a paragraph defining "Econometric Admissibility" and scheduling the two pedagogical counterfactuals ($\theta=1$ and No-Dummy specs). | *Advisor Directive: Pedagogical Counterfactuals & Admissibility* |
| **Section 4.4.1 (US Data)** | Add raw, non-econometric US growth rates of GDP, employment, and capital directly into the text (Marglin emulation). | *UMass PE Guidelines: Descriptive Grounding* |
| **Section 5.1.1 (US Results)** | Explicitly include a "Visual-First" step: plotting raw trends of output, capital, and wage shares before presenting FM-OLS. | *UMass PE Guidelines: Visual-First* |
| **Section 6.1 (Tracing)** | **RESTRUCTURE** Subsection 6.1 to remove recapitalization corridor analysis and focus entirely on the capacity-to-profitability transmission. | *Scoping Partition* |
| **Section 6.2.1 (Overaccumulation)** | Add an explicit paragraph discussing the *analytical limitation* of single-sector macro bounding for overaccumulation regimes. | *Advisor Directive: Model Limitations* |
| **Section 7 (Conclusion)** | Frame the deferred recapitalization corridor as the structural bridge to Chapter 3. | *Scoping Partition* |
