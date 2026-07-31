---
type: paper_facing
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-23
date: 2026-07-23
conversation_id: 1087ad76-f9a3-4d89-9596-1b49f4925b11
project: Capacity-Utilization-US_Chile
chapter: Chapter 2
subtype: paper_facing_map
blocks: []
layer: design
scope: chapter2
priority: context
---

# Session Handoff Manifest: Chapter 2 Scoping & Outline Complete

This manifest documents the state of the Chapter 2 project at the close of the session on **July 23, 2026**. It defines the scoping partition agreed upon by the candidate and advisor, maps out the active files, and provides clear instructions for the incoming agent to resume work.

---

## 1. Current Project Status

We have completed the **Research, Outline, and Review** phases for Chapter 2. The project has transitioned from a loose set of notes into a structurally locked outline backed by a formal advisor review and scoping agreement.

### Git Commits Tracked:
*   `1e2f053` — Added the initial Chapter 2 outline and implementation plan.
*   `10674fe` — Added the official advisor review and scoping partition agreement.

---

## 2. Active File Registry (The Tuple)

The next session must load and respect the following active files in the vault as the single source of truth:

| Path in Repository | Purpose | Status |
| :--- | :--- | :--- |
| [`chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md) | Locked section-by-section and paragraph-by-paragraph outline. | **Locked (Awaiting update for partition)** |
| [`chapter2_vault/06_paper_facing/Advisor_Review_2026-07-23.md`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/Advisor_Review_2026-07-23.md) | Official advisor review establishing the scoping split and applied econometrics audit. | **Active & Locked** |
| [`chapter2_vault/80_Prompts/implementation_plan.md`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/80_Prompts/implementation_plan.md) | Strategic transition plan from Chapter 1 findings to Chapter 2 comparative framework. | **Active & Locked** |

---

## 3. The Chapter 2 / Chapter 3 Scoping Partition

To prevent analytical over-extension, we have partitioned the two corridors:
1.  **Chapter 2 Bounding:** Confined strictly to the **productive-capacity corridor ($\theta_t \rightarrow \mu_t \rightarrow r_t$)**. It will reconstruct potential capacity and recover utilization. It ends at the Weisskopf profit rate decomposition. No investment functions or accumulation feedback loops will be estimated.
2.  **Chapter 3 Relocation:** Confined to the **recapitalization corridor ($\chi_t \rightarrow k_t \rightarrow g_t$)**. All estimation of dynamic investment functions, VECM feedback, and local projections are deferred to Chapter 3, using Chapter 2's recovered utilization series as a given regressor.

---

## 4. Pending Actions & Next Steps

When a new session is initialized, the incoming agent must execute the following tasks sequentially:

### Step 1: Update the Outline for the Partition
Modify the definitive outline ([Ch2_Outline_DEFINITIVE.md](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md)) to prune the recapitalization corridor. Specifically:
*   Delete Subsection 2.3.3 (Recapitalization Corridor) and Paragraph 2.3.3.
*   Remove all references to investment function estimations ($\chi_t, \psi_j$) in Section 4 and Section 5.
*   Delete Subsection 6.1.2 (Chile Corridor Analysis) and Subsection 6.1.3 (Comparative Corridor Synthesis). Refocus Subsection 6.1 entirely on the capacity-to-profitability transmission.
*   Update Section 7 to frame the recapitalization corridor as the bridge to Chapter 3.

### Step 2: Address the Interactive Specification Decisions
Solicit the scholar's final choices on:
*   *US Specification:* Scale-conditioned vs. Composition-mediated ($\tau_t$, machinery/structures ratio).
*   *Chilean Wedge:* Terms of Trade ($ToT_t$) vs. Import Capacity as the external proxy ($z_t$).
*   *Pinch Years:* The target years to anchor the utilization level ($\mu_{t_0} = 1$).

### Step 3: Begin Drafting the Introduction (Section 1)
Draft Section 1 under strict compliance with `/umass-applied-econometrics` (BLUF by second paragraph, define all parameters immediately) and `/humanize-writing` (no transitions at paragraph openings, active voice $\ge 70\%$, no generic AI tells).

---

## 5. Resuming Instructions for the Next Agent

To resume work, load the active files using:
```markdown
1. Read the active handoff manifest: [handoff_manifest.md](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/handoff_manifest.md)
2. Read the advisor directives: [Advisor_Review_2026-07-23.md](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/Advisor_Review_2026-07-23.md)
3. Load the locked outline: [Ch2_Outline_DEFINITIVE.md](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md)
```
Then, execute Step 1 of the pending actions above.
