# EXP_01 Render Comparison and Isolated Compilation Report

**Date:** 2026-09-29  
**Engine:** pdfTeX 3.141592653-2.6-1.40.29 (TeX Live 2026)  
**Compilation Mode:** Non-stop mode, halt-on-error, file-line-error, isolated temporary directory  
**Active Repository Integrity:** UNTOUCHED (compiled entirely inside isolated temporary directories)

---

## 1. Executive Summary

Isolated compilation of Chapter 2 using the candidate Section 5 (`02_CANDIDATE_SECTION5.tex`) succeeded completely without errors or warnings. All cross-references, citation keys, mathematical formulas, and figure floats resolved cleanly.

| Metric | Baseline (`01_BASELINE_SECTION5.tex`) | Candidate (`02_CANDIDATE_SECTION5.tex`) | Status |
|---|---|---|:---:|
| **Compilation Return Code** | 0 | 0 | **PASS** |
| **PDF Generated** | Yes (`2,007,141` bytes) | Yes (`2,006,109` bytes) | **PASS** |
| **Total Pages** | 103 | 103 | **PASS** |
| **Section 5 Page Range** | Pages 74--78 | Pages 74--78 | **PASS** |
| **LaTeX Errors (`!`)** | 0 | 0 | **PASS** |
| **Undefined Citations** | 0 | 0 | **PASS** |
| **Undefined References** | 0 | 0 | **PASS** |
| **Section 5 Warnings** | 0 | 0 | **PASS** |
| **Net Warning Delta** | Baseline | 0 new, 0 removed | **PASS** |

---

## 2. Compilation Verification Checklist

- [x] **Successful compilation:** Both two-pass compilation cycles finished with exit code `0`.
- [x] **No broken citations/references:** Zero `Citation ... undefined` or `Reference ... undefined` messages in the compilation log.
- [x] **No malformed paragraph boundaries:** All seven modified paragraphs retain proper LaTeX paragraph break formatting (`\n\n`); no run-on text or broken paragraph environments.
- [x] **No new LaTeX errors:** Zero TeX errors encountered. Warning count in Section 5 is exactly zero.
- [x] **Section 5 renders normally:** Page boundaries, typography, math symbols (`\mu_t`, `\theta_t`, `\hat{\gamma}`), footnotes, and Figure~\ref{fig:sec5_combined_mu} render identically and cleanly.

---

## 3. Detailed Visual and Log Inspection

### Page-by-Page Layout (Section 5)
- **Page 74:** Section heading `\section{Discussion: The Political Economy of Capacity Utilization in the Center and the Periphery}`, paragraphs `CH2-S05-P001`, `CH2-S05-P002`, paragraph heading `\paragraph{The Relational Dynamics of Idle Capacity.}`, paragraph `CH2-S05-P003` (with footnote), and float `Figure~\ref{fig:sec5_combined_mu}` (`figures/fig_sec5_combined_mu.pdf`).
- **Page 75:** Paragraph `CH2-S05-P004` (relational dynamics of idle capacity) and paragraph heading `\paragraph{The Center: Realization Failure and Intellectual Monopolies.}`.
- **Page 76:** Paragraph `CH2-S05-P005` and paragraph `CH2-S05-P006` (Weisskopf decomposition, Fordist profit squeeze, intangible assets).
- **Page 77:** Paragraph heading `\paragraph{The Periphery: Dual Strangulation and Export Reprimarization.}`, paragraph `CH2-S05-P007`, and paragraph `CH2-S05-P008` (closed vs. peripheral economy, UP wage expansion, dual strangulation, 1975 drop).
- **Page 78:** Paragraph `CH2-S05-P009`, paragraph `CH2-S05-P010` (threshold caveat and future directions), paragraph heading `\paragraph{Synthesis: Scar Tissue of the Global Divide.}`, paragraph `CH2-S05-P011`, and closing synthesis paragraph `CH2-S05-P012` leading into `\FloatBarrier` and Section 6 (`Conclusion`).

### Log Excerpt for Section 5
```text
(./section5.tex
File: figures/fig_sec5_combined_mu.pdf Graphic file (type pdf)
<use figures/fig_sec5_combined_mu.pdf>
)
```
No overfull or underfull `\hbox` or `\vbox` warnings occurred within the text of Section 5 in either the baseline or candidate compilation.

---

## 4. Conclusion

The candidate Section 5 document `02_CANDIDATE_SECTION5.tex` renders with full syntactic and typographical validity. It produces no layout degradation or citation errors.
