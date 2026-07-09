---
type: artifacts_inventory_review
status: active
layer: project_auditing
scope: all_dissertation_artifacts
last_updated: 2026-07-09
---

# In-Depth Artifact Assessment Report

> **Project Reference:** Chapter 2 Dissertation Pipeline
> **Evaluation Date:** 2026-07-07
> **Main Repo Status:** Active Stage S30 (U.S. Track) / Staged for Rebuild (Chile Track)
> **Goal:** Identify, classify, and audit all active, superseded, reference, and diagnostic artifacts in the workspace.

---

## 1. Executive Summary & Repo Evolution

An audit of the repository contents reveals a clear evolution in the project's architecture between **April 2026** and **July 2026**:

1.  **The Structural Mismatch:** The older plan `repo_structure_Ch2_v2.md` (April 2, 2026) outlines a nested directory structure under `codes/` (such as `codes/stage_a/us/` and `codes/stage_a/chile/`). However, the newer active architecture `C03-REPO_STRUCTURE.md` (updated June 8, 2026) overrides this and mandates a **flat code layout** under `codes/` (where scripts are named `US_S10_...` or `CL_S10_...` and no country subdirectories exist inside `codes/`). The actual codebase files reflect this flat, staged layout.
2.  **Methodological Evolution:** In June 2026, the aggregate distribution-conditioned interaction model ($y_t = c + \beta_1 k_t + \beta_2 \omega_t k_t + \xi_t$) became the locked theoretical benchmark, superseding older constant-elasticity or unconditioned estimation tracks.
3.  **Active Stage Status:**
    *   **United States Track:** Currently in **Stage S30/S32** (Transformation Relation & Model Choice). Cointegration datasets are frozen (`US_S30F_dataset_release_freeze.R`), and diagnostics are being run. S40 reconstruction contracts are written, but promotion is blocked under the June 8 override pending human verification of the interaction coefficient vectors.
    *   **Chile Track:** The old Chile scripts (`CL_01_...`, `CL_05_...`) are formally classified as **recyclable staged materials**. They violate stage gates by jumping straight from data to utilization/profitability. They must be systematically rebuilt into flat Stage S10-S99 scripts under `codes/`.

---

## 2. Artifact Assessment Matrix

Below is the complete inventory of key artifacts in the project, evaluated against the current July 2026 workflow.

| Artifact | File Path | Date / Vintage | Classification | Role in Current Workflow & Usage Guidelines |
| :--- | :--- | :--- | :--- | :--- |
| **Locked Outline** | [Ch2_Outline_DEFINITIVE.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/artifacts/Ch2_Outline_DEFINITIVE.md) | ~April 2026 | **Active Authority** | Ground truth for all content decisions, text sections, and subsections (§2.1–§2.9). Writing must never deviate from this structure. |
| **Voice Guide** | [ch2_voice_guide.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/artifacts/ch2_voice_guide.md) | ~April 2026 | **Active Authority** | Enforces the strict WLM v4.0 writing voice. Must be referenced and injected before drafting any prose. Prohibits hedging and demands evidence/verdict parity. |
| **Repo Structure (Active)** | [C03-REPO_STRUCTURE.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md) | **June 8, 2026** (Updated) | **Active Governance** | Governs the flat `codes/` layout and defines boundaries between stages (S10-S99). Prevents downstream stages from re-estimating upstream objects. Supersedes older folder plans. |
| **Repo Structure (Legacy)** | [repo_structure_Ch2_v2.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/artifacts/repo_structure_Ch2_v2.md) | April 2, 2026 | **Superseded Plan** | Do **NOT** use for code file placement. It is a historical reference only. All new scripts must follow the flat structure in `C03-REPO_STRUCTURE.md`. |
| **US Code Recycling** | [C01-US_00_MEMO_RECYCLING.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/C01-US_00_MEMO_RECYCLING.md) | June 8, 2026 (Updated) | **Active Reference** | Maps legacy US script functions to the new staged scripts. Ensures standardized variables like `omega_k_t` ($\omega_t k_t$) are exported. |
| **Chile Code Recycling** | [C02-CL_00_MEMO_RECYCLING.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/C02-CL_00_MEMO_RECYCLING.md) | June 2, 2026 (Updated) | **Active Reference** | Maps the Chile "recyclable batch" scripts to their target flat R scripts (`CL_S10_...` to `CL_S99_...`). Establishes the hierarchy of FM-OLS (main), IM-OLS (check), and DOLS (stress). |
| **US S30 Gate** | [C04-US_S30_STABILITY_PROTOCOL.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/C04-US_S30_STABILITY_PROTOCOL.md) | June 8, 2026 (Updated) | **Active Gate** | Adjudicates whether US Stage S30 estimations are stable enough to open S40. Defines the baseline testing equation and standardizes cointegration tests. |
| **Level Anchor Rules** | [D03_capacity_utilization_level_anchor_pinch_year_protocol.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/04_data_measurement/D03_capacity_utilization_level_anchor_pinch_year_protocol.md) | June 2026 | **Active Authority** | Governs the normalization of capacity utilization. Baseline normalizations must be point-years: $\mu_{US, 1973} = 1$ and $\mu_{CL, 1980} = 1$. Prohibits rolling averages or statistical means as baselines. |
| **Figure Styling** | [C05-FIGURE_PROTOCOL.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/C05-FIGURE_PROTOCOL.md) | June 2026 | **Active Reference** | Establishes the exact visual style for all plots. Restricts recession shading to visual context (never a regime/anchor classifier). Mandates explicit anchor markers. |
| **US S40 Contract** | [US S40 Restricted B1 Reconstruction Contract.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/US%20S40%20Restricted%20B1%20Reconstruction%20Contract.md) | June 8, 2026 (Updated) | **Active Contract** | Defines the mathematical reconstruction of $\theta_{tot}$, $Y^p$, and $\mu_t$ for the U.S. Prohibits treating residuals as utilization. |
| **US S40 Review** | [US S40 Review and Figures Contract.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/US%20S40%20Review%20and%20Figures%20Contract.md) | June 2026 | **Active Contract** | Governs S40 checks and validation figures. Prevents the review layer from modifying upstream objects. |
| **Alignment Report** | [A00_CODE_IMPLEMENTATION_ALIGNMENT_REPORT.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/A00_CODE_IMPLEMENTATION_ALIGNMENT_REPORT.md) | June 8, 2026 | **Superseded Audit** | A historical snapshot auditing note alignments. The recommendations are superseded by the new distribution-conditioned theta identification. Useful only to see past note updates. |
| **Codex Constraints** | [CONSTRAINTS.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/CONSTRAINTS.md) | ~May 2026 | **Active Governance** | Prohibits editing archive files, renaming core concepts, and collapsing diagnostic/identification/presentation layers. |
| **Modular Index** | [ch2_modular_index.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/artifacts/ch2_modular_index.md) | April 2, 2026 | **Active Tracker** | Tracks writing progress and modular section dependencies. |
| **Section Prompts** | [ch2_section_prompts.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/artifacts/ch2_section_prompts.md) | April 2, 2026 | **Active Reference** | The raw prompts used to feed the writing sprint. |

---

## 3. Methodological Risk Register & Guardrails

To protect the integrity of the dissertation's empirical findings, agents and developers must defend the following **methodological guardrails**:

1.  **The Level Normalization Guardrail:**
    *   *Risk:* A script silently calculates capacity utilization relative to a rolling or historical average (e.g., $\bar{\mu}_{1945-1973}=1$).
    *   *Guardrail:* S40 and S50 scripts must enforce point-year normalizations ($\mu_{US, 1973}=1$, $\mu_{CL, 1980}=1$). Any average-based normalization is classified as "diagnostic robustness check only" and must be explicitly labeled.
2.  **The Estimator Hierarchy Guardrail:**
    *   *Risk:* Cointegration parameters are reconstructed using DOLS or another dynamic estimator as the primary baseline.
    *   *Guardrail:* FM-OLS is the primary estimation engine. IM-OLS serves as the confirmation check. DOLS must only be used as a stress-test diagnostic.
3.  **The Residual utilization Guardrail:**
    *   *Risk:* Treating regression residuals ($\varepsilon_t$) as the capacity utilization series.
    *   *Guardrail:* Cointegration coefficients must be recovered, then used to reconstruct productive capacity ($Y^p$), and utilization ($\mu$) is derived as observed output divided by reconstructed capacity. Residuals are not utilization.
4.  **The Stage-Boundary Guardrail:**
    *   *Risk:* A downstream script (e.g., S50 or S99) re-runs an OLS regression or adjusts an anchor year.
    *   *Guardrail:* If an upstream data or parameter object is incorrect, you must patch the upstream script (S10-S40) and regenerate the files. Downstream scripts are strictly read-only.
5.  **The Variable Identity Guardrail:**
    *   *Risk:* Conflating aggregate capital stock $K_t$ with component capital stocks ($K^{ME}$, $K^{NR}$) during transformation estimations.
    *   *Guardrail:* Baseline models are estimated on aggregate $K_{cap}$ ($K^{ME} + K^{NR}$). Asset composition variables ($s_t$, $\varphi_t$) are A03-level decomposition proxies and are analyzed downstream in Stage S50/S60.

---

## 4. Lazy-Proof Workflow Reference Handoff

Before initiating any task, check this index to see which artifact governs your next steps:

*   **If you are writing or editing dissertation prose:**
    1.  Load the WLM v4.0 voice constraints in [ch2_voice_guide.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/artifacts/ch2_voice_guide.md).
    2.  Check the outline in [Ch2_Outline_DEFINITIVE.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/artifacts/Ch2_Outline_DEFINITIVE.md).
    3.  See section prompts in [ch2_section_prompts.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/artifacts/ch2_section_prompts.md).
*   **If you are editing, checking, or validating US Cointegration models (S30):**
    1.  Check the stability constraints in [C04-US_S30_STABILITY_PROTOCOL.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/C04-US_S30_STABILITY_PROTOCOL.md).
*   **If you are writing or reviewing US Capacity Reconstruction scripts (S40):**
    1.  Verify the level anchors in [D03_capacity_utilization_level_anchor_pinch_year_protocol.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/04_data_measurement/D03_capacity_utilization_level_anchor_pinch_year_protocol.md).
    2.  Check the rules in [US S40 Restricted B1 Reconstruction Contract.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/US%20S40%20Restricted%20B1%20Reconstruction%20Contract.md).
*   **If you are planning the rebuild of the Chile Track (S10-S99):**
    1.  Check the recycling instructions in [C02-CL_00_MEMO_RECYCLING.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/C02-CL_00_MEMO_RECYCLING.md).
    2.  Adhere to the stage constraints in [C03-REPO_STRUCTURE.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md).
*   **If you are preparing figures or plotting series (S99):**
    1.  Check plot conventions (recession shading, markers) in [C05-FIGURE_PROTOCOL.md](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/05_codes_implementation/C05-FIGURE_PROTOCOL.md).
