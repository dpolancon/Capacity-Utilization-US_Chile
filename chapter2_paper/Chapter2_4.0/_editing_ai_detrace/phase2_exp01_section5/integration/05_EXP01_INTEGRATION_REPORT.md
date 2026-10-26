# Chapter 2 — Phase 2 / EXP_01 Integration Report

**Date:** 2026-09-30  
**Repository Working Directory:** `C:\ReposGitHub\Capacity-Utilization-US_Chile\chapter2_paper\Chapter2_3.0`  
**Git Branch:** `main`  
**Task:** Phase 2 / EXP_01 Section 5 Integration  
**Status:** **INTEGRATED & VERIFIED**  

---

## 1. Cryptographic Hashes and Repository State

- **Pre-Integration Baseline Hash (`section5.tex`):**  
  `F01541AC68F9816E61D93B7CA6E530603569C961D8588C345147506420F67443` *(Matches verified baseline `01_BASELINE_SECTION5.tex`)*
- **Post-Integration Active Hash (`section5.tex`):**  
  `22CC24891C934D2B27503E3E06F7F683C6910535AB338904A3BB6163FFA01387`
- **Candidate Reference Hash (`02_CANDIDATE_SECTION5.tex`):**  
  `E0E1DBAA808BDA9CD30B41A07EB8F9C6D3FE76A7B3698F333B5D224ABAF8CE5A`
- **Git State:** No `git add`, `git commit`, `git push`, or workspace manipulation performed. Prohibited path `../Chapter2_3.0 - copia/` remained untouched.

---

## 2. Authorized Manuscript Changes Applied

Modifications were restricted strictly and solely to the seven authorized Phase 1 prose units and the single preceding heading:

1. **CH2-S05-P001 (Line 4):** Accepted candidate prose verbatim without further editing.
2. **CH2-S05-P002 (Line 6):** Accepted candidate prose verbatim without further editing.
3. **CH2-S05-P004 (Line 21):** Accepted candidate prose with 3 approved human amendments:
   - Replaced `"This higher amplitude directly tracks"` with `"This higher amplitude tracks"`.
   - Replaced `"severe macro-historical trough"` with `"macroeconomic trough"`.
   - Replaced `"radically divergent regime shifts"` with `"divergent regime shifts"`.
4. **CH2-S05-P006 (Line 26):** Accepted candidate prose with approved human revisions:
   - Replaced unexamined/residual formulation with: `"The Federal Reserve Board utilization series does not identify the physical conversion of accumulation into capacity. Here, $\mu_t$ is instead recovered as an endogenous residual of $\theta_t$."`
   - Replaced candidate closing with: `"Persistent idle capacity therefore accompanies the post-Fordist shift toward financialization and the growing weight of intangible-asset accumulation \citep{Rikap2021, Rotta2018}."`
5. **CH2-S05-P008 (Line 31):** Accepted candidate prose verbatim without further editing.
6. **CH2-S05-P010 (Line 35):** Accepted candidate prose verbatim without further editing.
7. **Heading Immediately Preceding P012 (Line 37):** Re-titled from:  
   `\paragraph{Synthesis: Scar Tissue of the Global Divide.}`  
   to:  
   `\paragraph{Synthesis: Dead Labour Across the Global Divide.}`
8. **CH2-S05-P012 (Line 40):** Integrated approved classical formulation:  
   `"The dead labour embedded in under-utilized productive capacities is crystallized past labour denied the living labour necessary for its valorization. In the center, this idleness accompanies the dismantling of a domestic social settlement in the name of profitability and financialized rent extraction; in the periphery, it reflects an asymmetrical global order that conditions growth on structural subordination. In both cases, accumulated capital remains physically present while the conditions for its reproduction are impaired."`

---

## 3. Post-Integration Scope and Invariant Verification

- **Scope Confinement:** Line-by-line verification confirms that differences between `01_BASELINE_SECTION5.tex` and active `section5.tex` occur **strictly and solely on lines 4, 6, 21, 26, 31, 35, 37, and 40**.
- **Byte-for-Byte Identity of Protected Material:**
  - `CH2-S05-P003` (Line 9): 100% byte-for-byte identical.
  - `CH2-S05-P005` (Line 24): 100% byte-for-byte identical.
  - `CH2-S05-P007` (Line 29): 100% byte-for-byte identical.
  - `CH2-S05-P009` (Line 33): 100% byte-for-byte identical.
  - `CH2-S05-P011` (Line 38): 100% byte-for-byte identical.
  - Float `Figure~\ref{fig:sec5_combined_mu}` and tabular note (Lines 11–19): 100% byte-for-byte identical.
  - Section title, section label, and paragraph headers for P003, P005, P007 (Lines 1–2, 8, 23, 28): 100% byte-for-byte identical.
- **Invariants Verdict:** **FULL PASS**. All citation keys (5 in P006, 1 in P008), numeric literals, historical dates, inline math formulas, and causal directions are completely preserved.

---

## 4. Word-Count Analysis

Word counts across the seven target prose units:

- **Baseline Cleaned Prose Words:** 1118
- **Integrated Cleaned Prose Words:** 947
- **Net Word-Count Change:** **-171 words (-15.3%)**
- *(Raw whitespace tokens: 1145 → 974; -171 tokens; -14.9%)*

---

## 5. Active Manuscript Compilation

Compilation of the full chapter manuscript (`main.tex`) with the integrated `section5.tex` succeeded completely:

- **Command:** `pdflatex -interaction=nonstopmode -halt-on-error -file-line-error main.tex`
- **Return Code:** `0`
- **Output Document:** `main.pdf` (103 pages, 2,006,119 bytes)
- **LaTeX Errors:** `0`
- **Undefined References / Citations:** `0`
- **Section 5 Warnings:** `0` (Zero overfull/underfull boxes)
- **Layout:** Section 5 renders cleanly across pages 74–77 (flowing into Section 6 on page 78).

---

## 6. Directory of Integration Artifacts

The final integration artifacts are recorded under:  
`_editing_ai_detrace/phase2_exp01_section5/integration/`

1. [`01_EXP01_INTEGRATED.diff`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_paper/Chapter2_3.0/_editing_ai_detrace/phase2_exp01_section5/integration/01_EXP01_INTEGRATED.diff): Unified diff from verified baseline `01_BASELINE_SECTION5.tex` to active `section5.tex`.
2. [`02_INTEGRATION_CHANGE_LEDGER.md`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_paper/Chapter2_3.0/_editing_ai_detrace/phase2_exp01_section5/integration/02_INTEGRATION_CHANGE_LEDGER.md): Paragraph-by-paragraph before/after ledger with human amendments.
3. [`03_INTEGRATION_INVARIANT_AUDIT.md`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_paper/Chapter2_3.0/_editing_ai_detrace/phase2_exp01_section5/integration/03_INTEGRATION_INVARIANT_AUDIT.md): Detailed verification of citation multisets, numbers, math, and causal directions.
4. [`04_COMPILE_REPORT.md`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_paper/Chapter2_3.0/_editing_ai_detrace/phase2_exp01_section5/integration/04_COMPILE_REPORT.md): Full LaTeX compilation report and log excerpts.
5. [`05_EXP01_INTEGRATION_REPORT.md`](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_paper/Chapter2_3.0/_editing_ai_detrace/phase2_exp01_section5/integration/05_EXP01_INTEGRATION_REPORT.md): Executive overview and integration sign-off.

---

## 7. Stop Condition Confirmation

SECTION 5 EXP_01 INTEGRATED  
NO COMMIT  
NO PUSH  
STOPPED  
