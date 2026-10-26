# EXP_01 Invariant Audit (Verified)

This is a comprehensive **source-preservation audit** generated from the verified baseline `01_BASELINE_SECTION5.tex` and candidate `02_CANDIDATE_SECTION5.tex`.

**Audit boundary:** Verification of preservation across all seven authorized Phase 1 prose units, byte-for-byte preservation of all non-target text, and isolated LaTeX document compilation integrity.

---

## 1. Automated Invariants on Changed Paragraphs

| Paragraph ID | Line | Citation Keys | Numeric Literals | Inline Math | Causal Direction | Uncertainty Level | Automated Status |
|---|---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **CH2-S05-P001** | 4 | PASS (0/0) | PASS (1/1) | PASS (2/2) | PASS | PASS | **PASS** |
| **CH2-S05-P002** | 6 | PASS (0/0) | PASS (1/1) | PASS (2/2) | PASS | PASS | **PASS** |
| **CH2-S05-P004** | 21 | PASS (0/0) | PASS (8/8) | PASS (5/5) | PASS | PASS | **PASS** |
| **CH2-S05-P006** | 26 | PASS (5/5) | PASS (14/14) | PASS (8/8) | PASS | PASS | **PASS** |
| **CH2-S05-P008** | 31 | PASS (1/1) | PASS (16/16) | PASS (3/3) | PASS | PASS | **PASS** |
| **CH2-S05-P010** | 35 | PASS (0/0) | PASS (2/2) | PASS (2/2) | PASS | PASS | **PASS** |
| **CH2-S05-P012** | 40 | PASS (0/0) | PASS (0/0) | PASS (0/0) | PASS | PASS | **PASS** |

### Invariant Multiset Comparison Details

- **Citation Keys:**
  - `CH2-S05-P006`: `{'Weisskopf1979': 1, 'Stockhammer2012': 1, 'Vidal2019': 1, 'Rikap2021': 1, 'Rotta2018': 1}` in both baseline and candidate. Exact multiset identity.
  - `CH2-S05-P008`: `{'DeVylder1976': 1}` in both baseline and candidate. Exact multiset identity.
  - All other target paragraphs contain zero citations in baseline and zero citations in candidate.

- **Numeric Literals & Historical Dates:**
  - `CH2-S05-P001`: `4` (Section 4 reference) preserved.
  - `CH2-S05-P002`: `1` ($\theta < 1$) preserved.
  - `CH2-S05-P004`: `100%`, `1975`, `1982`, `1979--1985`, `1982` (`82%`), `1981` (`100%`) preserved.
  - `CH2-S05-P006`: `1960s`, `76.2%`, `1975`, `74.1%`, `1982`, `0.32`, `100%`, `2000`, `103%` preserved.
  - `CH2-S05-P008`: `20-percentage-point`, `49%`, `1970`, `69.03%`, `1972`, `-1.06`, `0.425`, `94.1%`, `1969`, `98.4%`, `1971`, `1972`, `26 percentage points`, `four years`, `72%`, `1975` preserved.
  - `CH2-S05-P010`: `0.425`, `2000s` preserved.
  - `CH2-S05-P012`: No numeric literals in either file.

- **Inline Math Expressions:**
  - `CH2-S05-P001`: `$\theta_t$`, `$\mu_t$` preserved.
  - `CH2-S05-P002`: `$\theta < 1$`, `$\mu_t$` preserved.
  - `CH2-S05-P004`: `$\mu = 100\%$`, `$\mu_t$`, `$K_t$`, `$\mu_{1982} \approx 82\%$`, `$\mu_{1981} = 100\%$` preserved.
  - `CH2-S05-P006`: `$\mu_t$` (x4), `$\theta_t$` (x3), `$\mu_{2000} \approx 103\%$` preserved.
  - `CH2-S05-P008`: `$Z_t = -1.06 < \hat{\gamma} = 0.425$`, `$\mu_t$` (x2) preserved.
  - `CH2-S05-P010`: `$Z_t$`, `$\hat{\gamma} = 0.425$` preserved.
  - `CH2-S05-P012`: No inline math expressions in either file.

---

## 2. Invariant Substantive Findings

- **P001 (Overaccumulation Baseline):** The below-unity transformation elasticity premise ($\theta_t < 1$), the single-sector disproportionality definition of overaccumulation, systemic disequilibrium, chronic idle capacity, and the supply-formation versus demand-realization distinction are all strictly preserved.
- **P002 (Comparative Thesis):** The core political economy contrast—U.S. realization crisis driven by institutional exhaustion and effective demand failure versus Chilean crisis driven by external truncation of capital imports and physical strangulation—is preserved intact; only the section-level announcement sentence is removed.
- **P004 (Empirical Relational Dynamics):** All reported dates, utilization rates, fixed capital irreversibility ($K_t$), the Volcker interest-rate shock transmission mechanism, and the divergent structural resolutions (debt financialization vs. peripheral subordination) are preserved. Mechanical enumeration ("First", "Second") and rhetorical scaffolding are stripped.
- **P006 (Center Dynamics & Intellectual Monopolies):** The Weisskopf RSL/RF decomposition, the interpretation of $\mu_t$ as an endogenous residual of $\theta_t$, the collapse of $\theta_t$ to 0.32, capitalist class restoration of profitability via wage suppression/deunionization, the long-term erosion of domestic realization, the debt-led consumption offset, and the post-2000 shift to intangible assets are fully preserved without dilution.
- **P008 (Periphery Dual Strangulation):** The complete macroeconomic causal chain—wage share expansion during the *Unidad Popular*, binding threshold domain ($Z_t = -1.06 < \hat{\gamma} = 0.425$), microeconomic incentive vs. macroeconomic means, import demand crowding out capital equipment, utilization decline from 94.1% (1969) to 98.4% (1971) to 72% (1975), credit blockades, capital flight, the 1972 bosses' lockout, and the blocked surplus driving structural inflation—is preserved in every detail.
- **P010 (Methodological Caveat on Threshold Classifier):** The deterministic hard classification properties, absence of smooth probabilistic switching or within-regime identification, stop-go capturing, discrete severing of capacity transformation during external insolvency, and the future extensions (series extension, Markov-switching, panel models) are all retained. Punctuation and grammatical errors are cleaned.
- **P012 (Theoretical Synthesis):** The Marxian theoretical architecture—dead labour / past labour denied living labour necessary for valorization, inability of the accumulation regime to reproduce itself, and the center/periphery contrast (social contract dismantled for profitability vs. asymmetrical global subordination)—is fully retained.

---

## 3. Whole-File and Scope Verification

- **Total file lines:** Exactly 40 lines in baseline, exactly 40 lines in candidate.
- **Diff localization:** Exactly 7 lines differ (lines 4, 6, 21, 26, 31, 35, 40), corresponding exactly to Phase 1 IDs `CH2-S05-P001`, `CH2-S05-P002`, `CH2-S05-P004`, `CH2-S05-P006`, `CH2-S05-P008`, `CH2-S05-P010`, and `CH2-S05-P012`.
- **Untargeted paragraphs:** `CH2-S05-P003` (line 9), `CH2-S05-P005` (line 24), `CH2-S05-P007` (line 29), `CH2-S05-P009` (line 33), and `CH2-S05-P011` (line 38) are **100% byte-for-byte identical**.
- **Structural elements:** All section headings, labels, paragraph titles, figure environments, and tabular captions are **100% byte-for-byte identical**.
- **No unauthorized modifications:** Zero differences exist outside the seven authorized prose units.

---

## 4. Authorial Review Note: Heading vs. Body Metaphor

- **Subsection Heading (Line 37):**  
  `\paragraph{Synthesis: Scar Tissue of the Global Divide.}`  
  *(Locked; remains strictly unchanged).*
- **Candidate Body (Line 40, P012):**  
  The candidate body eliminates the ornamental phrase `"speaks a distinct language across the scar tissue of the global divide"` and does **not** contain the words `"scar tissue"` anywhere in its text.
- **Verdict for Author Review:** The candidate body relies strictly on classical political economy concepts (*dead labour*, *living labour*, *valorization*, *reproduction*, *social contract*, *structural subordination*). Whether to retain `"Scar Tissue of the Global Divide"` in the paragraph heading or align it with the de-metaphorized body is an authorial decision for future editing stages. Headings were locked in EXP_01 and were not modified.

---

## 5. Diff & Compilation Verification

- **Diff Verification:** The clean unified diff `03_EXP01_PATCH_CLEAN.diff` was generated directly from `01_BASELINE_SECTION5.tex` → `02_CANDIDATE_SECTION5.tex`. Execution of `git apply --check 03_EXP01_PATCH_CLEAN.diff` succeeded with return code `0` and no warnings.
- **Isolated LaTeX Compilation:** Executed via pdfTeX 3.141592653-2.6-1.40.29 (TeX Live 2026) in an isolated temporary directory.
  - Return code: `0`
  - PDF generated: `2,006,109` bytes
  - TeX errors: `0`
  - Undefined references / citations: `0`
  - Section 5 compilation warnings: `0`

---

## 6. Final Verdict

**EXP_01 INVARIANT AUDIT: FULL PASS.**  
All invariants (citations, numeric literals, math expressions, causal direction, uncertainty) are completely preserved. Scope is strictly confined to the seven authorized prose units. Compilation is clean.