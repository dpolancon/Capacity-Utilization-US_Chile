# Agent C — Section 4.4 and Selected Section 4.5 Invariant Audit

- **Date:** 2026-09-30
- **Scope:** Section 4.4 + Selected Section 4.5
- **Baseline File:** `_editing_ai_detrace/submission_parallel/4_4_4_5/01_BASELINE_SECTION4.tex`
- **Candidate File:** `_editing_ai_detrace/submission_parallel/4_4_4_5/02_CANDIDATE_4_4_4_5.tex`
- **Active Manuscript:** `section4.tex`
- **Audit Status:** PASSED (Zero Violations)

---

## 1. Scope Boundary Audit

### 1.1 Authorized Target Verification
The prompt authorized modifications strictly to the following 18 paragraph units:
- **Section 4.4.1 (10 units):** `CH2-S04.04.01-P001`, `CH2-S04.04.01-P002`, `CH2-S04.04.01-P003`, `CH2-S04.04.01-P004`, `CH2-S04.04.01-P005`, `CH2-S04.04.01-P007`, `CH2-S04.04.01-P008`, `CH2-S04.04.01-P009`, `CH2-S04.04.01-P010`, `CH2-S04.04.01-P011`
- **Section 4.4.2 (2 units):** `CH2-S04.04.02-P001`, `CH2-S04.04.02-P005`
- **Section 4.5.1 (4 units):** `CH2-S04.05.01-P001`, `CH2-S04.05.01-P005`, `CH2-S04.05.01-P007`, `CH2-S04.05.01-P008`
- **Section 4.5.2 (2 units):** `CH2-S04.05.02-P004`, `CH2-S04.05.02-P007`

**Verification Results:**
- Line-by-line diff analysis confirms changes occurred at **exactly 18 paragraph IDs**.
- Diff blocks outside these 18 IDs: **0**.
- Unauthorized paragraph modifications: **0**.

### 1.2 Non-Target and KEEP Parity Check
All other sections and non-authorized paragraphs in Section 4 are byte-for-byte identical between baseline and candidate:
- **Section 4.1 (Methodological Foundations):** 100% IDENTICAL
- **Section 4.2 (Descriptive Stylized Facts):** 100% IDENTICAL
- **Section 4.3 (Econometric Methodology & CMPR IM-OLS):** 100% IDENTICAL
- **Section 4.4.1 KEEP benchmark:** `CH2-S04.04.01-P006` 100% IDENTICAL
- **Section 4.4.2 KEEP benchmarks/prose:** `CH2-S04.04.02-P002`, `P003`, `P004` 100% IDENTICAL
- **Section 4.5.1 KEEP units:** `CH2-S04.05.01-P002`, `P003`, `P004`, `P006`, `P009` 100% IDENTICAL
- **Section 4.5.2 KEEP units:** `CH2-S04.05.02-P001`, `P002`, `P003`, `P005` 100% IDENTICAL
- **Section 4.6 (Chile Peripheral Empirical Evidence):** 100% IDENTICAL
- **All Tables, Table Notes, Figures, Captions, and References:** 100% IDENTICAL

### 1.3 Absolute Protected Hold: `CH2-S04.05.02-P006`
- **Baseline location:** Lines 1385–1387
- **Candidate location:** Lines 1383–1385
- **Verification status:** **PASSED — BYTE-FOR-BYTE IDENTICAL**.
- No words, punctuation, spaces, or clauses were altered. No inferences regarding the meaning-sensitive ambiguity were made.

---

## 2. Substantive Invariant Verification

### 2.1 Econometric Estimates & Test Statistics
Every single estimate, standard error, test statistic, p-value, sample size, and critical threshold was verified by programmatic frequency comparison:

| Parameter / Statistic / Term | Baseline Count | Candidate Count | Status | Notes |
|---|---:|---:|:---:|---|
| Base capital elasticity $\hat{\theta}_0 = 0.58$ | 13 | 13 | PASSED | Preserved across all specifications and references |
| Interaction elasticity $\hat{\theta}_1 = -0.30$ | 14 | 14 | PASSED | Preserved in Spec A Set 2, Clean Corporate Col 4 |
| Insignificant interaction $\hat{\theta}_1 = -0.04$ | 1 | 1 | PASSED | Without break controls in Col 3 |
| $t$-statistic $t = -0.50$ | 1 | 1 | PASSED | Col 3 without breaks |
| $t$-statistic $t = -5.00$ | 3 | 3 | PASSED | Col 4 Clean Corporate, Col 8 Shaikh-Tonak |
| ADF statistic $t_{\text{ADF}} = -4.07$ | 3 | 3 | PASSED | Spec A Col 4 cointegration rejection |
| Structures base $\hat{\theta}_{\text{NRC}} = 0.60$ | 5 | 5 | PASSED | Spec B Col 4 structures base |
| Standalone gap $\hat{\theta}_\kappa = 0.39$ | 2 | 2 | PASSED | Spec B Col 4 standalone yield |
| Standalone SE $SE = 0.29$ | 3 | 3 | PASSED | Spec B Col 4 standard error |
| Intensive interaction $\hat{\theta}_{\omega\kappa} = -7.93$ | 4 | 4 | PASSED | Spec B Col 4 preferred interaction |
| Standard error $SE = 2.96$ | 1 | 1 | PASSED | Spec B Col 4 interaction SE |
| Shaikh-Tonak interaction $\hat{\theta}_{\omega\kappa} = -17.05$ | 2 | 2 | PASSED | Spec B Col 7 interaction |
| Standard error $SE = 2.34$ | 1 | 1 | PASSED | Spec B Col 7 interaction SE |
| Structures base $\hat{\theta}_{\text{NRC}} = 0.54$ | 1 | 1 | PASSED | Spec B Col 7 structures base |
| Standalone gap $\hat{\theta}_\kappa = 0.33$ | 1 | 1 | PASSED | Spec B Col 7 standalone yield |
| Clean Corporate Tier 2 interaction $-14.97$ | 1 | 1 | PASSED | Spec B Col 5–6 interaction |
| Standard error $SE = 2.01$ | 1 | 1 | PASSED | Spec B Col 5–6 interaction SE |
| Price interaction $\hat{\theta}_{\kappa p} = -0.79$ | 1 | 1 | PASSED | Spec B Col 7–8 price interaction |
| Price interaction SE $SE = 0.32$ | 2 | 2 | PASSED | Spec B price interaction SE |
| Spec B range minimum $0.32$ | 2 | 2 | PASSED | Spec B trajectory minimum |
| Spec B ADF statistics ($-4.58, -4.60, -4.71, -4.57$) | 6 | 6 | PASSED | All break-adjusted ADF statistics intact |
| Spec B no-break ADF bound $t_{\text{ADF}} \le -4.33$ | 1 | 1 | PASSED | 10% critical rejection bound intact |
| Vogelsang-Wagner statistic bound $15.37$ | 2 | 2 | PASSED | Type-2 Wald bound intact |
| Break-controlled Vogelsang-Wagner $6.37$ | 1 | 1 | PASSED | Reduced Type-2 Wald statistic intact |
| Unattenuated interaction $\hat{\theta}_{\omega\kappa} = -11.08$ | 1 | 1 | PASSED | Col 3 without breaks intact |
| Shin LM bounds ($C_{\text{Shin}} \le 0.04, 0.03$) | 6 | 6 | PASSED | Cointegration non-rejection bounds intact |
| Type-2 Wald threshold $52.6$ | 1 | 1 | PASSED | 90th percentile fixed-$b$ threshold intact |
| No-dummy ADF statistic $t_{\text{ADF}} = -1.84$ | 1 | 1 | PASSED | Spurious regression failure statistic intact |
| Worked example parameters ($0.40, 0.72, 0.20, 0.70$) | 13 | 13 | PASSED | All illustrative worked-example values intact |

### 2.2 Historical Dates & Regimes
| Year / Date Range | Baseline Count | Candidate Count | Status | Notes |
|---|---:|---:|:---:|---|
| $1944$ | 5 | 5 | PASSED | Wartime expansion break date |
| $1977$ | 1 | 1 | PASSED | Institutional break date |
| $2001$ | 4 | 4 | PASSED | Neoliberal break date |
| $1973$ | 17 | 17 | PASSED | Benchmark pinch year / Fordist exhaustion |
| $1931$ | 17 | 17 | PASSED | Estimation sample anchor |
| $2024$ | 35 | 35 | PASSED | Sample end date |
| $1950\text{s}$ | 3 | 3 | PASSED | Golden Age illustrative anchor |
| $1968\text{--}1973$ | 4 | 4 | PASSED | Profit squeeze periodization |

### 2.3 Literature Citations & Reference Keys
| Citation Key | Baseline Count | Candidate Count | Status | Notes |
|---|---:|---:|:---:|---|
| `\citep{VogelsangWagner2024}` | 4 | 4 | PASSED | Fixed-$b$ CMPR IM-OLS methodology |
| `\citep{ShaikhTonak1994}` | 4 | 4 | PASSED | Marxian NVA national accounting |
| `\citeyearpar{Shin1994}` | 2 | 2 | PASSED | Shin LM cointegration test |
| `\citep{Basu2022}` | 1 | 1 | PASSED | Marx-biased technical change |
| `\citep{Kalecki1943}` | 1 | 1 | PASSED | Political aspects of full employment |

### 2.4 Mathematical Formulations & Displayed Equations
- **Equation \eqref{eq:431:specA_model}:** $y_t = \alpha + \theta_0\, k_{\text{cap},t} + \theta_1\, \xi^{\omega}_t + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$ — **UNTOUCHED**
- **Equation \eqref{eq:42:theta_state}:** $\theta_t(\omega_{t-1}, \iota_{t-1}) = 0.58 - 0.30 \cdot \omega_{t-1}(1 - \iota_{t-1})$ — **UNTOUCHED**
- **Equation \eqref{eq:42:yp_recursion}:** Recursive level reconstruction anchored at 1973 — **UNTOUCHED**
- **Equation \eqref{eq:432:specB_model}:** $y_t = \alpha + \theta_{\text{NRC}}\, k^{\text{NRC}}_t + \theta_\kappa\, \kappa_t + \theta_{\omega\kappa}\, \xi^{\omega\kappa}_t + \theta_{\kappa p}\, \xi^{p\kappa}_t + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$ — **UNTOUCHED**
- **All footnote content:** Footnote on regressor scaling and parameter interpretation between Spec A and Spec B is **100% VERBATIM PRESERVED**.

### 2.5 Causal Interpretation & Voice Register
- **Classical vs. Post-Fordist Closure:** Unbalanced growth closure ($\theta^* \neq 1$) and systemic disequilibrium preserved.
- **Okishio defensive mechanization mechanism:** Maintained as cost containment under profit squeeze, inducing intensive-margin substitution without proportional output expansion.
- **Center–periphery framing:** Unaltered throughout.
- **Uncertainty strength:** Confidence levels, $p$-value qualifications, and insignificance findings preserved without artificial upgrading or downgrading.

---

## 3. Active Manuscript State Verification

- **Target File:** `C:\ReposGitHub\Capacity-Utilization-US_Chile\chapter2_paper\Chapter2_3.0\section4.tex`
- **Active SHA-256 Hash:** `2e97b366a5d6dacdfef8a7ae0bbb8d5b42668c1218be928fded1dc1f28c80353`
- **Baseline SHA-256 Hash:** `2e97b366a5d6dacdfef8a7ae0bbb8d5b42668c1218be928fded1dc1f28c80353`
- **Comparison:** **BYTE-IDENTICAL**.
- **Active Manuscript Modification:** **NONE**. Zero edits, zero compilation runs, zero staging, zero commits, zero pushes.

---

## 4. Final Audit Verdict

```
============================================================
INVARIANT AUDIT VERDICT: PASSED
- Authorized IDs only modified: 18 / 18
- All KEEP and non-listed units identical: YES
- Protected hold CH2-S04.05.02-P006 untouched: YES
- Numbers, dates, estimates, SEs, p-values preserved: 100%
- Formulas, mathematical models, equations preserved: 100%
- Citations and bibliography keys preserved: 100%
- Active section4.tex hash unchanged: YES
============================================================
```
