# EXP_01 Active Manuscript Compilation Report

**Document:** `main.tex`  
**Engine:** pdfTeX 3.141592653-2.6-1.40.29 (TeX Live 2026)  
**Compilation Date:** 2026-09-30  
**Command:** `pdflatex -interaction=nonstopmode -halt-on-error -file-line-error main.tex`  
**Working Directory:** `C:\ReposGitHub\Capacity-Utilization-US_Chile\chapter2_paper\Chapter2_3.0`  

---

## 1. Executive Summary

Compilation of the active chapter manuscript with the integrated Section 5 completed successfully with return code `0`. All citations, figure cross-references, mathematical formulas, and section floats resolved cleanly.

| Diagnostic Metric | Observed Value | Verification Standard | Status |
|---|---|---|:---:|
| **Process Exit Code** | `0` | `0` | **PASS** |
| **Output Document** | `main.pdf` | Exists & valid | **PASS** |
| **PDF File Size** | `2,006,119` bytes | ~2.0 MB | **PASS** |
| **Total Page Count** | `103` pages | 103 pages | **PASS** |
| **Section 5 Span** | Pages 74--77 (leading into Section 6 on p. 78) | Matches layout | **PASS** |
| **LaTeX Errors (`!`)** | `0` | `0` | **PASS** |
| **Undefined Citations** | `0` | `0` | **PASS** |
| **Undefined References** | `0` | `0` | **PASS** |
| **Section 5 Warnings** | `0` | `0` | **PASS** |
| **Overfull/Underfull in Sec 5** | `0` | `0` | **PASS** |

---

## 2. Compilation Log Inspection for Section 5

The excerpt below shows the exact transcript recorded in `main.log` as the engine processed `section5.tex`:

```text
(./section5.tex
<figures/fig_sec5_combined_mu.pdf, id=1965, 686.565pt x 375.4025pt>
File: figures/fig_sec5_combined_mu.pdf Graphic file (type pdf)
<use figures/fig_sec5_combined_mu.pdf>
Package pdftex.def Info: figures/fig_sec5_combined_mu.pdf  used on input line 15.
(pdftex.def)             Requested size: 469.75502pt x 256.85129pt.
[74] [75 <./figures/fig_sec5_combined_mu.pdf>] [76] [77])
```

### Transcript Analysis
- **Graphics inclusion:** Figure~\ref{fig:sec5_combined_mu} (`figures/fig_sec5_combined_mu.pdf`) loaded and scaled without warnings.
- **Box layout:** Zero `Overfull \hbox`, `Underfull \hbox`, `Overfull \vbox`, or `Underfull \vbox` warnings occurred within the text of Section 5.
- **Cross-references:** All labels (`sec:5:comparative_historical_analysis`, `fig:sec5_combined_mu`) and citation keys (`Weisskopf1979`, `Stockhammer2012`, `Vidal2019`, `Rikap2021`, `Rotta2018`, `DeVylder1976`) resolved without warning.
- **Heading formatting:** `\paragraph{Synthesis: Dead Labour Across the Global Divide.}` rendered normally with standard paragraph head indentation and typeface.

---

## 3. Scope and Regression Verification

- **No New LaTeX Errors:** No syntax or structural errors were introduced by the integrated prose.
- **Layout Stability:** Total document length remains 103 pages. Section 5 begins on page 74 and flows into Section 6 on page 78.
- **Isolation of Changes:** Only `section5.tex` was modified; no other section files were altered in response to compilation output.

---

## 4. Final Verdict

**MANUSCRIPT COMPILATION: PASS.**  
Active manuscript compiles cleanly and Section 5 renders correctly.
