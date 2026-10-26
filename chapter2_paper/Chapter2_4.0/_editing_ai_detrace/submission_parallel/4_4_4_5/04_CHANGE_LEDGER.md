# Agent C — Section 4.4 and Selected Section 4.5 Change Ledger

- **Date:** 2026-09-30
- **Working Directory:** `chapter2_paper/Chapter2_3.0`
- **Branch:** `main`
- **Workstream:** Agent C — Section 4.4 + Selected Section 4.5 (Candidate Generation)
- **Status:** Candidate Generated / Baseline Frozen / Active Manuscript Unchanged

---

## 1. Overview and Executive Summary

This ledger records the precise, paragraph-by-paragraph interventions applied to Section 4.4 (US Baseline Empirical Results) and selected paragraphs of Section 4.5 (US Heterogeneous Capital Specification). 

All interventions strictly conform to the Phase 1 diagnostic ledger (`_editing_ai_detrace/phase1_ledger/`):
- **Authorized target paragraphs modified:** Exactly 18 units across subsections 4.4.1, 4.4.2, 4.5.1, and 4.5.2.
- **Absolute protected hold respected:** `CH2-S04.05.02-P006` is 100% UNCHANGED and byte-for-byte identical.
- **Non-listed paragraphs, sections, tables, figures, captions, and appendices:** 100% UNCHANGED.
- **Substantive lock enforced:** Zero alterations to coefficients, standard errors, $t$-statistics, $p$-values, critical thresholds, sample sizes, null hypotheses, equations, mathematical derivations, dates, citations, institutional periodizations, or causal arguments.

### Aggregate Metrics

| Metric | Baseline (`01_BASELINE_SECTION4.tex`) | Candidate (`02_CANDIDATE_4_4_4_5.tex`) | Net Delta |
|---|---:|---:|---:|
| **File Line Count** | 1,744 | 1,734 | -10 lines |
| **Total Word Count** | 18,053 | 17,869 | -184 words |
| **Target Units Word Count** | 2,206 | 2,022 | -184 words |
| **SHA-256 Hash** | `2e97b366a5d6dacdfef8a7ae0bbb8d5b42668c1218be928fded1dc1f28c80353` | `cbb34211c0fb99c264a408f5b29a2e023adcd71e4560b1866e116ac0f80015a8` | (Candidate Generated) |
| **Active `section4.tex` SHA-256** | `2e97b366a5d6dacdfef8a7ae0bbb8d5b42668c1218be928fded1dc1f28c80353` | (Identical to Baseline) | 0 (Unchanged) |

---

## 2. Summary Table of Interventions

| Item | Paragraph ID | Operation | Risk | Priority | Base Words | Cand Words | Delta | Primary Phase 1 Focus |
|---:|---|---|---|---|---:|---:|---:|---|
| 1 | `CH2-S04.04.01-P001` | COMPRESS | HIGH | P1 | 49 | 44 | -5 | Condense repeated measurement-noise explanation. |
| 2 | `CH2-S04.04.01-P002` | COMPRESS | HIGH | P1 | 215 | 204 | -11 | Remove META wrapper ("Note that"); condense NVA/CFC explanation. |
| 3 | `CH2-S04.04.01-P003` | COMPRESS | HIGH | P1 | 213 | 197 | -16 | Tighten grammar; remove redundant final measurement recap. |
| 4 | `CH2-S04.04.01-P004` | COMPRESS | HIGH | P1 | 147 | 126 | -21 | State cointegration triad verdict once; cut "mutual confirmation" / victory language. |
| 5 | `CH2-S04.04.01-P005` | LIGHT | HIGH | P2 | 137 | 136 | -1 | Trim redundant introductory frame before Set 1 results. |
| 6 | `CH2-S04.04.01-P007` | COMPRESS | HIGH | P1 | 117 | 110 | -7 | Remove "empirical confirmation" wrapper; tighten wage-pressure mechanism. |
| 7 | `CH2-S04.04.01-P008` | COMPRESS | HIGH | P1 | 127 | 102 | -25 | Condense duplicated robustness statements; remove "confirms ... structural feature". |
| 8 | `CH2-S04.04.01-P009` | DELETE-SCAFFOLD | LOW | P1 | 17 | 7 | -10 | Delete content-free introductory sentence ("To make the empirical stakes transparent..."). |
| 9 | `CH2-S04.04.01-P010` | LIGHT | HIGH | P3 | 115 | 113 | -2 | Reduce overlapping amplifiers ("chronic, permanent downward collapse" $\to$ "permanent collapse"). |
| 10 | `CH2-S04.04.01-P011` | COMPRESS | HIGH | P1 | 79 | 76 | -3 | Fold standalone "This confirms that" victory sentence into the result. |
| 11 | `CH2-S04.04.02-P001` | LIGHT | HIGH | P2 | 254 | 248 | -6 | Repair broken syntax ("i.e. which", "shared of investment", "FBR" typo, "allows to identify"). |
| 12 | `CH2-S04.04.02-P005` | LIGHT | HIGH | P2 | 86 | 87 | +1 | Fix collisions ("present empirical evidence supports that", spacing $\theta^* \neq 1$, "avoid ... to remain", bracket typo). |
| 13 | `CH2-S04.05.01-P001` | LIGHT | HIGH | P3 | 8 | 7 | -1 | Join split word ("stochast\nic" $\to$ "stochastic"). |
| 14 | `CH2-S04.05.01-P005` | COMPRESS | HIGH | P1 | 101 | 82 | -19 | Remove "direct evidence" wrapper; merge duplicated sentences on intensive margin. |
| 15 | `CH2-S04.05.01-P007` | COMPRESS | HIGH | P1 | 131 | 121 | -10 | State cointegration verdict once; cut duplicated opening announcement. |
| 16 | `CH2-S04.05.01-P008` | COMPRESS | HIGH | P1 | 104 | 86 | -18 | Condense repeated survival language across break controls. |
| 17 | `CH2-S04.05.02-P004` | COMPRESS | HIGH | P1 | 23 | 18 | -5 | Remove final repetitive model-vindication clause ("and confirms the Okishio mechanism empirically"). |
| 18 | `CH2-S04.05.02-P007` | REWRITE | HIGH | P1 | 283 | 258 | -25 | Rebuild sentence boundaries around worked example; eliminate run-on crisis conclusion. |
| — | **Total** | | | | **2,206** | **2,022** | **-184** | |

---

## 3. Detailed Paragraph Ledger

### 1. `CH2-S04.04.01-P001`
- **Locator:** Baseline line 1151 / Candidate line 1151
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `REP`
- **Diagnosis:** The measurement-error argument at the end repeats S03.01.02-P006 after a complete specification, set definition, and inference description.
- **Specific Action:** Condense the final two sentences into a single coherent sentence connecting classical measurement noise to the structural transformation elasticity bound without reversing or adjudicating the attenuation inference.
- **Baseline:**
  > Because capital stocks are constructed via Perpetual Inventory (GPIM) methods, any classical right-hand-side measurement noise in $k_{\text{cap},t}$ introduces standard attenuation bias that pulls $\hat{\theta}_0$ downward toward zero. Measurement error cannot explain why $\theta < 1$; rather, it reinforces that the true structural transformation elasticity is bounded strictly below unity.
- **Candidate:**
  > Because capital stocks are constructed via Perpetual Inventory (GPIM) methods, classical right-hand-side measurement noise in $k_{\text{cap},t}$ introduces standard attenuation bias that pulls $\hat{\theta}_0$ downward toward zero, reinforcing that the structural transformation elasticity is bounded strictly below unity rather than an artifact of measurement error.
- **Invariants Preserved:** Equation \eqref{eq:431:specA_model}, $y_t$, $k_{\text{cap},t}$, $\xi^\omega_t$, $\mathbf{D}_t$, $\theta_1$, Set 1/Set 2 definitions, $T=94, 77$, CMPR IM-OLS, \citep{VogelsangWagner2024}, GPIM, and the downward attenuation claim.

---

### 2. `CH2-S04.04.01-P002`
- **Locator:** Baseline line 1154 / Candidate line 1154
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `REP`, `META`
- **Diagnosis:** The NVA/CFC and supervisory-adjustment rationale repeats Section 4.1.3; "Note that" adds a meta-discourse reader instruction wrapper.
- **Specific Action:** Condense duplicated descriptive sentences; remove "Note that"; preserve all accounting identities, Marxian value definitions, and specification distinctions.
- **Baseline:**
  > \paragraph{Theoretical argument for the NVA basis of distributive conflict measure.}
  > Class struggle over distribution is conducted strictly over newly created value ($\text{Net Value Added} = v + s$), excluding pre-existing constant capital transfers ($\text{Consumption of Fixed Capital} = \text{CFC}$). Under classical-Marxian national accounting \citep{ShaikhTonak1994}, $\text{Gross Value Added} = \text{CFC} + v + s$. Because physical depreciation ($\text{CFC}$) represents constant capital transferred to output by concrete labor, it lies outside zero-sum distributive conflict. During periods of intensive mechanization, the ratio $\text{CFC}/\text{GVA}$ rises mechanically, causing GVA-basis wage shares to appear to fall even when the rate of surplus-value extraction ($s/v$) is invariant. The NVA basis ($\omega_{\text{NVA}} = v / (v + s)$) purges this physical depreciation distortion, isolating the true balance of class power. Standard NIPA compensation includes managerial and executive salaries, which function as distributions of surplus value rather than variable labor costs. The Shaikh-Tonak Tier 2 ($\omega_{\text{ST,Tier2}} = v_{\text{prod}} / \text{NFC\_NVA}$) and Clean Corporate Tier 1 and Tier 2 measures strip supervisory overhead ($s_{\text{sup}}$) and purge financial sector double-counting ($\text{FIN\_NOS}^{\text{implied}} + \text{NFC\_NET\_INT}$), recovering the true variable capital ($v$) that drives corporate cost-minimization decisions. Note that unadjusted Shaikh-Tonak Tier 1 NVA ($\text{NFC\_COMP} / \text{NFC\_NVA}$) is mathematically identical to the NFC Baseline NVA share, rendering Clean Corporate and Tier 2 supervisory adjustments the primary non-redundant distributive specifications.
- **Candidate:**
  > \paragraph{Theoretical argument for the NVA basis of distributive conflict measure.}
  > Class struggle over distribution is conducted strictly over newly created value ($\text{Net Value Added} = v + s$), excluding pre-existing constant capital transfers ($\text{Consumption of Fixed Capital} = \text{CFC}$). Under classical-Marxian national accounting \citep{ShaikhTonak1994}, $\text{Gross Value Added} = \text{CFC} + v + s$. Because physical depreciation ($\text{CFC}$) represents constant capital transferred to output by concrete labor, it lies outside zero-sum distributive conflict; rising $\text{CFC}/\text{GVA}$ during intensive mechanization mechanically depresses GVA wage shares even when the rate of surplus-value extraction ($s/v$) is invariant. The NVA basis ($\omega_{\text{NVA}} = v / (v + s)$) purges this physical depreciation distortion, isolating the balance of class power. Standard NIPA compensation includes managerial and executive salaries, which function as distributions of surplus value rather than variable labor costs. The Shaikh-Tonak Tier 2 ($\omega_{\text{ST,Tier2}} = v_{\text{prod}} / \text{NFC\_NVA}$) and Clean Corporate Tier 1 and Tier 2 measures strip supervisory overhead ($s_{\text{sup}}$) and purge financial sector double-counting ($\text{FIN\_NOS}^{\text{implied}} + \text{NFC\_NET\_INT}$), recovering the variable capital ($v$) that drives corporate cost-minimization decisions. Because unadjusted Shaikh-Tonak Tier 1 NVA ($\text{NFC\_COMP} / \text{NFC\_NVA}$) is mathematically identical to the NFC Baseline NVA share, Clean Corporate and Tier 2 supervisory adjustments constitute the primary non-redundant distributive specifications.
- **Invariants Preserved:** All accounting formulas ($v+s$, $\text{CFC}+v+s$, $\omega_{\text{NVA}} = v/(v+s)$), \citep{ShaikhTonak1994}, all variable strings ($\omega_{\text{ST,Tier2}}$, $\text{FIN\_NOS}^{\text{implied}} + \text{NFC\_NET\_INT}$, $\text{NFC\_COMP} / \text{NFC\_NVA}$).

---

### 3. `CH2-S04.04.01-P003`
- **Locator:** Baseline line 1157 / Candidate line 1157
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `REP`, `CERT`
- **Diagnosis:** The final sentence re-certifies the effective-wage measure after its formula, mechanism, and two historical examples have already explained it; missing article in "Under induced mechanization mechanism".
- **Specific Action:** Fix syntax ("Under the induced mechanization mechanism"); condense the final recap sentence into the explanation of Set 1 failure.
- **Baseline:**
  > \paragraph{Institutional and physical mechanism of scaling by $(1-\iota_{t-1})$.}
  > The scaling factor $(1-\iota_{t-1}) = K_{\text{cap},t-1} / (K_{\text{cap},t-1} + K_{\text{IPP},t-1})$ isolates the physical productive asset share (machinery, equipment, and structures) from total fixed capital. Under induced mechanization mechanism, when labor commands a larger share of newly created value ($\omega_{t-1} \uparrow$), profit margins shrink, forcing firms to accelerate defensive mechanization by substituting capital equipment for living labor on the shop floor. However, capital expenditure allocated to Intellectual Property Products ($K_{\text{IPP}}$)---software licenses, corporate patents, brand architecture, and legal protections---operates as market-enclosure assets rather than physical output-yielding machinery. If corporate investment shifts toward intangibles ($\iota \uparrow$), those funds do not engage in shop-floor labor substitution. In the Fordist era ($1931$--$1973$), IPP capital was negligible ($\iota \approx 0.02$--$0.05 \implies 1-\iota \approx 0.95$), allowing raw wage pressure to map directly into physical machinery expansion. In the digital Post-Fordist era ($1980$--$2024$), IPP capital surged ($\iota > 0.28 \implies 1-\iota < 0.72$), diverting substantial surplus into software and legal enclosures. Unadjusted wage interactions ($\omega_{t-1} \times k_{\text{cap}}$ in Set 1) fail across the full sample because they assume every dollar of capital stock has an identical physical capacity yield across both historical regimes. Scaling by $(1-\iota_{t-1})$ purges this Post-Fordist structural shift, measuring the exact effective wage pressure that drives physical shop-floor labor substitution.
- **Candidate:**
  > \paragraph{Institutional and physical mechanism of scaling by $(1-\iota_{t-1})$.}
  > The scaling factor $(1-\iota_{t-1}) = K_{\text{cap},t-1} / (K_{\text{cap},t-1} + K_{\text{IPP},t-1})$ isolates the physical productive asset share (machinery, equipment, and structures) from total fixed capital. Under the induced mechanization mechanism, when labor commands a larger share of newly created value ($\omega_{t-1} \uparrow$), squeezed profit margins compel firms toward defensive mechanization, substituting capital equipment for living labor on the shop floor. However, capital expenditure allocated to Intellectual Property Products ($K_{\text{IPP}}$)---software licenses, corporate patents, brand architecture, and legal protections---operates as market enclosure rather than physical output-yielding machinery. If investment shifts toward intangibles ($\iota \uparrow$), those funds bypass shop-floor labor substitution. In the Fordist era ($1931$--$1973$), IPP capital was negligible ($\iota \approx 0.02$--$0.05 \implies 1-\iota \approx 0.95$), allowing raw wage pressure to translate directly into physical machinery expansion. In the digital Post-Fordist era ($1980$--$2024$), IPP capital surged ($\iota > 0.28 \implies 1-\iota < 0.72$), diverting substantial surplus into software and legal enclosures. Unadjusted wage interactions ($\omega_{t-1} \times k_{\text{cap}}$ in Set 1) fail across the full sample because they assume an identical physical capacity yield across regimes; scaling by $(1-\iota_{t-1})$ purges this intangible diversion, capturing the effective wage pressure that drives shop-floor labor substitution.
- **Invariants Preserved:** Scaling factor formula, IPP definition, dates ($1931$--$1973$, $1980$--$2024$), shares ($\iota \approx 0.02$--$0.05 \implies 1-\iota \approx 0.95$, $\iota > 0.28 \implies 1-\iota < 0.72$), Set 1 failure rationale.

---

### 4. `CH2-S04.04.01-P004`
- **Locator:** Baseline line 1160 / Candidate line 1160
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `CERT`, `REP`, `TMPL`
- **Diagnosis:** "Mutual confirmation", "confirming", and "unanimous confirmation ... establishes" surround one set of test results with repeated verdicts.
- **Specific Action:** State the empirical cointegration verdict once at the end; remove redundant certification language while preserving all three tests, nulls, and statistics.
- **Baseline:**
  > \paragraph{Cointegration verdict across the test triad.}
  > The empirical validity of Specification A relies on mutual confirmation across the cointegration test triad: the Engle-Granger residual ADF test ($t_{\text{ADF}}$), the Shin \citeyearpar{Shin1994} LM test ($C_{\text{Shin}}$), and the Vogelsang-Wagner Type 2 Wald statistic ($S_{\text{Type 2}}$). Across all 48 specifications, the Shin LM test ($C_{\text{Shin}} \le 0.04$, $p > 0.10$) and the Vogelsang-Wagner Type 2 Wald statistic ($S_{\text{Type 2}} \le 13.18$, well below the 90th percentile fixed-$b$ critical value threshold of $52.6$) fail to reject the null hypothesis of cointegration ($H_0: \text{Cointegration}$), confirming that residual variance remains stationary and bounded. Simultaneously, when Bai-Perron step shifts are included, the Engle-Granger residual ADF test rejects the null hypothesis of no cointegration ($t_{\text{ADF}} = -4.07$, $p < 0.05$ in Column 4). This unanimous confirmation across all three tests establishes that aggregate real output and private core capital form a genuine, non-spurious long-run cointegrating relationship.
- **Candidate:**
  > \paragraph{Cointegration verdict across the test triad.}
  > Cointegration in Specification A is evaluated across three complementary tests: the Engle-Granger residual ADF test ($t_{\text{ADF}}$), the Shin \citeyearpar{Shin1994} LM test ($C_{\text{Shin}}$), and the Vogelsang-Wagner Type 2 Wald statistic ($S_{\text{Type 2}}$). Across all 48 specifications, the Shin LM test ($C_{\text{Shin}} \le 0.04$, $p > 0.10$) and the Vogelsang-Wagner Type 2 Wald statistic ($S_{\text{Type 2}} \le 13.18$, well below the 90th percentile fixed-$b$ critical value threshold of $52.6$) fail to reject the null hypothesis of cointegration ($H_0: \text{Cointegration}$). When Bai-Perron step shifts are included, the Engle-Granger residual ADF test rejects the null hypothesis of no cointegration ($t_{\text{ADF}} = -4.07$, $p < 0.05$ in Column 4), establishing that aggregate real output and private core capital form a genuine, non-spurious long-run cointegrating relationship.
- **Invariants Preserved:** All 3 tests, \citeyearpar{Shin1994}, all 48 specifications, $C_{\text{Shin}} \le 0.04$, $p > 0.10$, $S_{\text{Type 2}} \le 13.18$, threshold 52.6, $H_0: \text{Cointegration}$, $t_{\text{ADF}} = -4.07$, $p < 0.05$ in Column 4, non-spurious cointegration verdict.

---

### 5. `CH2-S04.04.01-P005`
- **Locator:** Baseline line 1163 / Candidate line 1163
- **Operation:** LIGHT (High Risk, Priority P2)
- **Phase 1 Codes:** `SCF`, `FIG`
- **Diagnosis:** "Tables ... present" followed by "Two key patterns emerge" delays the estimates with two introductory frames.
- **Specific Action:** Trim one introductory frame by combining presentation and emergence into a single opener; preserve all appendix references and patterns.
- **Baseline:**
  > \paragraph{Set 1 results: failure of standard unadjusted wage interactions.}
  > Tables~\ref{tab:specA_set1_gva_app} and \ref{tab:specA_set1_nva_app} in Appendix~\ref{app:specA_full_results} present the Set 1 estimation results. Two key patterns emerge. First, the baseline capital transformation elasticity $\hat{\theta}_0$ is positive, highly stable, and statistically significant across all specifications ($0.55$--$0.61$, $p < 0.01$), establishing that private core capital ($K_{\text{cap}} = K_{\text{ME}} + K_{\text{NRC}}$) yields a long-run output elasticity of approximately $0.58$. Second, the unadjusted standard wage interaction $\hat{\theta}_1$ fails to achieve statistical significance in every Set 1 model, with point estimates ranging from $-0.02$ ($t = -0.16$) in NFC Baseline GVA/NVA to $-0.20$ ($t = -1.95$) in Clean Corporate Tier 2 NVA. Unconditioned wage shares fail to capture the induced accumulation channel because raw wage measures conflate unproductive managerial overhead with productive variable labor and ignore the structural allocation of investment toward intellectual property products.
- **Candidate:**
  > \paragraph{Set 1 results: failure of standard unadjusted wage interactions.}
  > The Set 1 estimation results in Tables~\ref{tab:specA_set1_gva_app} and \ref{tab:specA_set1_nva_app} (Appendix~\ref{app:specA_full_results}) reveal two key patterns. First, the baseline capital transformation elasticity $\hat{\theta}_0$ is positive, highly stable, and statistically significant across all specifications ($0.55$--$0.61$, $p < 0.01$), establishing that private core capital ($K_{\text{cap}} = K_{\text{ME}} + K_{\text{NRC}}$) yields a long-run output elasticity of approximately $0.58$. Second, the unadjusted standard wage interaction $\hat{\theta}_1$ fails to achieve statistical significance in every Set 1 model, with point estimates ranging from $-0.02$ ($t = -0.16$) in NFC Baseline GVA/NVA to $-0.20$ ($t = -1.95$) in Clean Corporate Tier 2 NVA. Unconditioned wage shares fail to capture the induced accumulation channel because raw wage measures conflate unproductive managerial overhead with productive variable labor and ignore the structural allocation of investment toward intellectual property products.
- **Invariants Preserved:** Appendix cross-references, $\hat{\theta}_0 = 0.55$--$0.61$, $p < 0.01$, $\hat{\theta}_0 \approx 0.58$, $\hat{\theta}_1 = -0.02$ ($t = -0.16$) to $-0.20$ ($t = -1.95$), managerial/IPP rationale.

---

### 6. `CH2-S04.04.01-P007`
- **Locator:** Baseline line 1168 / Candidate line 1168
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `CERT`, `REP`, `TMPL`
- **Diagnosis:** The interpretation restates the wage-pressure mechanism with the formulaic certification wrapper "provides empirical confirmation of".
- **Specific Action:** Replace "provides empirical confirmation of" with "reflects"; streamline the mechanism sentences while preserving the full economic interpretation.
- **Baseline:**
  > The negative sign of $\hat{\theta}_1$ provides empirical confirmation of the induced mechanization mechanism under Okishio's market anarchy. When productive labor commands a larger share of newly created value ($\omega_{t-1} \uparrow$), firms face squeezed profit margins and respond by accelerating defensive mechanization---substituting capital equipment for living labor to lower unit labor costs. However, because this defensive substitution is driven by cost containment rather than autonomous technological expansion, it increases the technical composition of capital without generating a proportional expansion in productive output capacity. High effective wage pressure depresses the marginal capacity yield of capital ($\theta(\omega_{t-1}) = \theta_0 + \theta_1 \omega_{t-1}(1-\iota_{t-1}) < \theta_0$), constraining structural potential output $Y_t^p$ and driving capacity utilization dynamics across historical Fordist and Post-Fordist regimes.
- **Candidate:**
  > The negative sign of $\hat{\theta}_1$ reflects the induced mechanization mechanism under Okishio's market anarchy. When productive labor commands a larger share of newly created value ($\omega_{t-1} \uparrow$), squeezed profit margins compel firms toward defensive mechanization, substituting capital equipment for living labor to contain unit labor costs. Because this substitution is driven by cost containment rather than autonomous technological expansion, it raises the technical composition of capital without generating a proportional expansion in productive capacity. High effective wage pressure therefore depresses the marginal capacity yield of capital ($\theta(\omega_{t-1}) = \theta_0 + \theta_1 \omega_{t-1}(1-\iota_{t-1}) < \theta_0$), constraining structural potential output $Y_t^p$ and driving capacity utilization dynamics across historical Fordist and Post-Fordist regimes.
- **Invariants Preserved:** $\hat{\theta}_1 < 0$, Okishio mechanism, defensive mechanization, cost containment vs autonomous expansion, $\theta(\omega_{t-1}) = \theta_0 + \theta_1 \omega_{t-1}(1-\iota_{t-1}) < \theta_0$, $Y_t^p$, Fordist and Post-Fordist regimes.

---

### 7. `CH2-S04.04.01-P008`
- **Locator:** Baseline line 1171 / Candidate line 1171
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `CERT`, `REP`, `INT`, `TMPL`
- **Diagnosis:** The ending returns to "confirms ... fundamental structural feature" after the opening already stated robustness; result and verdict are repeated around the estimates.
- **Specific Action:** Condense opening sentences; remove "This confirms that" and the redundant wrapper; keep all before/after estimates intact.
- **Baseline:**
  > \paragraph{Robustness across structural break specifications.}
  > Controlling for Bai-Perron structural break step shifts ($\mathbf{D}_t$) leaves the core interaction elasticities intact while enhancing cointegration test performance. Step shift dummies absorb historical level shifts---such as the 1944 wartime expansion, the 1967 profit squeeze, and the 1982 neoliberal transition---without altering the sign or statistical significance of the effective wage interaction $\hat{\theta}_1$. In the Clean Corporate Tier 1 model, controlling for step shifts increases the magnitude of $\hat{\theta}_1$ from $-0.04$ ($t = -0.50$, insignificant) to $-0.30$ ($t = -5.00$, $p < 0.05$), while achieving strong residual cointegration ($t_{\text{ADF}} = -4.07, p < 0.05$). This confirms that the conditioning effect of distributive pressure on capital transformation is a fundamental structural feature of U.S. capital accumulation rather than an artifact of unmodeled regime shifts.
- **Candidate:**
  > \paragraph{Robustness across structural break specifications.}
  > Controlling for Bai-Perron structural break step shifts ($\mathbf{D}_t$) absorbs historical level shifts---such as the 1944 wartime expansion, the 1967 profit squeeze, and the 1982 neoliberal transition---while enhancing cointegration test performance. In the Clean Corporate Tier 1 model, controlling for step shifts increases the magnitude of $\hat{\theta}_1$ from $-0.04$ ($t = -0.50$, insignificant) to $-0.30$ ($t = -5.00$, $p < 0.05$), while achieving strong residual cointegration ($t_{\text{ADF}} = -4.07, p < 0.05$). The conditioning effect of distributive pressure on capital transformation is thus a structural feature of U.S. capital accumulation rather than an artifact of unmodeled regime shifts.
- **Invariants Preserved:** Break step shifts $\mathbf{D}_t$, 1944, 1967, 1982 dates, Clean Corporate Tier 1 model, $\hat{\theta}_1 = -0.04$ ($t = -0.50$) to $-0.30$ ($t = -5.00$, $p < 0.05$), $t_{\text{ADF}} = -4.07, p < 0.05$, structural feature conclusion.

---

### 8. `CH2-S04.04.01-P009`
- **Locator:** Baseline line 1174 / Candidate line 1174
- **Operation:** DELETE-SCAFFOLD (Low Risk, Priority P1)
- **Phase 1 Codes:** `SCF`, `META`
- **Diagnosis:** The standalone instruction announces two pedagogical counterfactuals that the following labeled items already identify; it adds no empirical or theoretical claim.
- **Specific Action:** Delete the single content-free sentence `To make the empirical stakes transparent, consider two pedagogical counterfactuals:`.
- **Baseline:**
  > \paragraph{Pedagogical counterfactuals: restriction and no-dummy breakdowns.}
  > To make the empirical stakes transparent, consider two pedagogical counterfactuals:
  > \begin{enumerate}
- **Candidate:**
  > \paragraph{Pedagogical counterfactuals: restriction and no-dummy breakdowns.}
  > \begin{enumerate}
- **Invariants Preserved:** Both counterfactual items (P010 and P011) and list structure preserved in full.

---

### 9. `CH2-S04.04.01-P010`
- **Locator:** Baseline line 1176 / Candidate line 1175
- **Operation:** LIGHT (High Risk, Priority P3)
- **Phase 1 Codes:** `INT`
- **Diagnosis:** "Chronic, permanent downward collapse" piles three overlapping descriptive amplifiers onto an already quantified decline.
- **Specific Action:** Reduce the piled amplifiers to "permanent collapse", preserving the substantive contrast and permanence claim.
- **Baseline:**
  > \item \textbf{The Restriction Counterfactual ($\theta = 1$):} Mainstream production-function approaches and statistical filters impose balanced growth ($\theta = 1$) a priori, assuming capacity expands one-for-one with capital accumulation. Under this restriction, the rapid post-war accumulation of private capital forces the estimated potential capacity path $Y^p_t = \hat{B} K_t$ upward at an unsustainable rate. Consequently, the derived capacity utilization series $\mu_t = Y_t / Y^p_t$ suffers a chronic, permanent downward collapse, falling to economically implausible levels below $60\%$ by the 2010s. Estimating $\theta$ unconstrained recovers $\hat{\theta} \approx 0.58$, confirming that physical capacity expands at roughly half the pace of capital accumulation and generating a stationary, cyclical utilization trajectory ($80\%$--$95\%$) that oscillates around historical business cycle benchmarks.
- **Candidate:**
  > \item \textbf{The Restriction Counterfactual ($\theta = 1$):} Mainstream production-function approaches and statistical filters impose balanced growth ($\theta = 1$) a priori, assuming capacity expands one-for-one with capital accumulation. Under this restriction, the rapid post-war accumulation of private capital forces the estimated potential capacity path $Y^p_t = \hat{B} K_t$ upward at an unsustainable rate. Consequently, the derived capacity utilization series $\mu_t = Y_t / Y^p_t$ suffers a permanent collapse, falling to economically implausible levels below $60\%$ by the 2010s. Estimating $\theta$ unconstrained recovers $\hat{\theta} \approx 0.58$, confirming that physical capacity expands at roughly half the pace of capital accumulation and generating a stationary, cyclical utilization trajectory ($80\%$--$95\%$) that oscillates around historical business cycle benchmarks.
- **Invariants Preserved:** $\theta = 1$, $Y^p_t = \hat{B} K_t$, $\mu_t = Y_t / Y^p_t$, below $60\%$, 2010s, $\hat{\theta} \approx 0.58$, $80\%$--$95\%$ band.

---

### 10. `CH2-S04.04.01-P011`
- **Locator:** Baseline line 1177 / Candidate line 1176
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `CERT`, `REP`
- **Diagnosis:** The final "This confirms" sentence re-announces the institutional interpretation established by the no-dummy/with-dummy comparison.
- **Specific Action:** Fold the institutional verdict directly into the active restoration sentence; remove the standalone victory sentence.
- **Baseline:**
  > \item \textbf{The No-Dummy Counterfactual (Spurious Regression):} Estimating the cointegrating equation without institutional step-shift controls yields non-stationary residuals ($t_{\text{ADF}} = -1.84$, failing cointegration). Omitting the institutional breaks conflates long-run parameter stability with historical regime shifts. Incorporating endogenously dated step dummies for the 1944 wartime expansion, the 1973/1974 Fordist exhaustion, and the 1982/1984 Volcker-Reagan neoliberal transition restores residual stationarity ($t_{\text{ADF}} = -4.07^{**}, p < 0.05$). This confirms that historical class conflict and institutional periodization are active regulators of long-run econometric cointegration.
- **Candidate:**
  > \item \textbf{The No-Dummy Counterfactual (Spurious Regression):} Estimating the cointegrating equation without institutional step-shift controls yields non-stationary residuals ($t_{\text{ADF}} = -1.84$, failing cointegration). Omitting the institutional breaks conflates long-run parameter stability with historical regime shifts. Incorporating endogenously dated step dummies for the 1944 wartime expansion, the 1973/1974 Fordist exhaustion, and the 1982/1984 Volcker-Reagan neoliberal transition restores residual stationarity ($t_{\text{ADF}} = -4.07^{**}, p < 0.05$), demonstrating that historical class conflict and institutional periodization actively regulate long-run econometric cointegration.
- **Invariants Preserved:** $t_{\text{ADF}} = -1.84$, 1944, 1973/1974, 1982/1984, $t_{\text{ADF}} = -4.07^{**}, p < 0.05$, class conflict and institutional periodization claim.

---

### 11. `CH2-S04.04.02-P001`
- **Locator:** Baseline lines 1186–1211 / Candidate lines 1185–1210
- **Operation:** LIGHT (High Risk, Priority P2)
- **Phase 1 Codes:** `SYN`, `TYPO`
- **Diagnosis:** Repeated "i.e." clauses, "shared of investment", "FBR" typo, and "allows to identify" obscure variable definitions and anchoring steps.
- **Specific Action:** Repair local grammar, preposition usage, and syntax; replace "FBR" with "FRB"; preserve all variable definitions, equations, and pinch-year anchoring.
- **Baseline:**
  > The model presented in \cref{tab:specA_set2_nva_main} column (4) yields a base capital
  > elasticity of $\hat{\theta}_0 = 0.58$ ($SE = 0.02$, $p < 0.01$)
  > and an effective wage interaction coefficient of
  > $\hat{\theta}_1 = -0.30$ ($SE = 0.06$, $p < 0.05$). The
  > state-dependent transformation elasticity then evolves over the long-run as: 
  > \begin{equation}
  > 	\theta_t(\omega_{t-1}, \iota_{t-1})
  > 	= 0.58 - 0.30 \cdot \omega_{t-1}(1 - \iota_{t-1}),
  > 	\label{eq:42:theta_state}
  > \end{equation}
  > where $\omega_{t-1}$ is the lagged "Clean Corporate Tier 1 wage
  > share", i.e. which is calculated on a net value added basis and scaled by $1-\iota_{t-1}$ which correspond to the shared of investment in tangible assets, i.e.  where $\iota$ refers to the
  > share of intellectual property products (IPP) over the total magnitude of gross capital formation. The latent capacity ceiling $Y_t^p$ follows the
  > differential law of motion $g_{Y^p,t} = \theta_t \cdot
  > g_{K_{cap},t}$, with $g_{K_{cap},t} = \Delta \ln(K_{ME,t} +
  > K_{NRC,t})$ as the unbalanced growth closure, where the only source of accumulation demand that build productive capacities is the accumulation rate of physical capital in operation measured constant 2017 dollars. The level of productive capacities is reconstructed recursively,
  > \begin{equation}
  > 	\ln Y_t^p = \ln Y_{t-1}^p
  > 	+ \left[ 0.58 - 0.30 \cdot \omega_{t-1}(1 - \iota_{t-1}) \right]
  > 	\left[ \ln K_{cap,t} - \ln K_{cap,t-1} \right],
  > 	\label{eq:42:yp_recursion}
  > \end{equation}
  > using 1973 as a pinch year given its recorded as the maximum value of the FBR series on capacity utilization ($\mu_{1973} = 100\%$). Dividing
  > realized real GDP by the estimated trajectory of productive capacities, allows to identify the rate of 
  > capacity utilization, $\mu_t \equiv Y_{GDP,t}/Y_t^p \times 100$.
  > \Cref{fig:us_capacity_dynamics_panel} plots the both recovered variables.
- **Candidate:**
  > The model presented in \cref{tab:specA_set2_nva_main} column (4) yields a base capital
  > elasticity of $\hat{\theta}_0 = 0.58$ ($SE = 0.02$, $p < 0.01$)
  > and an effective wage interaction coefficient of
  > $\hat{\theta}_1 = -0.30$ ($SE = 0.06$, $p < 0.05$). The
  > state-dependent transformation elasticity then evolves over the long run as: 
  > \begin{equation}
  > 	\theta_t(\omega_{t-1}, \iota_{t-1})
  > 	= 0.58 - 0.30 \cdot \omega_{t-1}(1 - \iota_{t-1}),
  > 	\label{eq:42:theta_state}
  > \end{equation}
  > where $\omega_{t-1}$ is the lagged Clean Corporate Tier 1 wage share calculated on a net value added basis, scaled by $1-\iota_{t-1}$, which corresponds to the share of investment in tangible assets, where $\iota$ refers to the share of intellectual property products (IPP) over the total magnitude of gross capital formation. The latent capacity ceiling $Y_t^p$ follows the differential law of motion $g_{Y^p,t} = \theta_t \cdot g_{K_{cap},t}$, with $g_{K_{cap},t} = \Delta \ln(K_{ME,t} + K_{NRC,t})$ as the unbalanced growth closure, where the only source of accumulation demand that builds productive capacity is the accumulation rate of physical capital in operation measured in constant 2017 dollars. The level of productive capacity is reconstructed recursively,
  > \begin{equation}
  > 	\ln Y_t^p = \ln Y_{t-1}^p
  > 	+ \left[ 0.58 - 0.30 \cdot \omega_{t-1}(1 - \iota_{t-1}) \right]
  > 	\left[ \ln K_{cap,t} - \ln K_{cap,t-1} \right],
  > 	\label{eq:42:yp_recursion}
  > \end{equation}
  > using 1973 as a pinch year, given that it records the maximum value of the FRB series on capacity utilization ($\mu_{1973} = 100\%$). Dividing realized real GDP by the estimated trajectory of productive capacity yields the rate of capacity utilization, $\mu_t \equiv Y_{GDP,t}/Y_t^p \times 100$. \Cref{fig:us_capacity_dynamics_panel} plots both recovered variables.
- **Invariants Preserved:** Column (4), $\hat{\theta}_0 = 0.58$ ($SE=0.02, p<0.01$), $\hat{\theta}_1 = -0.30$ ($SE=0.06, p<0.05$), Equations \eqref{eq:42:theta_state} and \eqref{eq:42:yp_recursion}, all definitions, 1973 pinch year, $\mu_{1973} = 100\%$, formula for $\mu_t$, figure reference.

---

### 12. `CH2-S04.04.02-P005`
- **Locator:** Baseline lines 1293–1295 / Candidate lines 1292–1294
- **Operation:** LIGHT (High Risk, Priority P2)
- **Phase 1 Codes:** `SYN`, `TYPO`
- **Diagnosis:** "Present empirical evidence supports that", missing space and delimiter in "$\theta^* \neq 1 $from where", "avoid ... to remain", and malformed bracket `($\mu_t<1)` are local editing collisions.
- **Specific Action:** Repair syntax, math delimiters, and bracket typos without changing the interpretation.
- **Baseline:**
  > The reconstruction present empirical evidence supports that the long-run horizon does not yield a classical closure ($\mu^* = 100\%$), 
  > but an unbalanced growth one $\theta^* \neq 1 $from where systemic disequilibrium arises through different patterns across distinct historical regimes.  
  > While the Fordist accumulation regime through its commitment to full employment implemented policies oriented to sustain aggregate demand and avoid productive capacities to remain idle, during post-Fordism the expansion of productive capacity ($\theta_t \uparrow$) has decoupled from realization ($\mu_t<1)$, causing persistent idle capacities as an institutional feature.
- **Candidate:**
  > The reconstruction presents empirical evidence that the long-run horizon does not yield a classical closure ($\mu^* = 100\%$), 
  > but an unbalanced growth one ($\theta^* \neq 1$), from which systemic disequilibrium arises through different patterns across distinct historical regimes.  
  > While the Fordist accumulation regime through its commitment to full employment implemented policies oriented to sustain aggregate demand and prevent productive capacity from remaining idle, during post-Fordism the expansion of productive capacity ($\theta_t \uparrow$) has decoupled from realization ($\mu_t < 1$), causing persistent idle capacity as an institutional feature.
- **Invariants Preserved:** Classical closure $\mu^* = 100\%$, unbalanced growth $\theta^* \neq 1$, Fordist full employment policy, post-Fordist $\theta_t \uparrow$ decoupling from $\mu_t < 1$, institutional feature claim.

---

### 13. `CH2-S04.05.01-P001`
- **Locator:** Baseline lines 1310–1311 / Candidate line 1309
- **Operation:** LIGHT (High Risk, Priority P3)
- **Phase 1 Codes:** `TYPO`
- **Diagnosis:** "Stochast ic" is an accidental split word across line break.
- **Specific Action:** Join "stochast\nic" to "stochastic".
- **Baseline:**
  > five independent $I(1)$ stochast
  > ic trends, two simultaneous
- **Candidate:**
  > five independent $I(1)$ stochastic trends, two simultaneous
- **Invariants Preserved:** Entire paragraph, Equation \eqref{eq:432:specB_model}, all variable definitions, $T=94, 77$.

---

### 14. `CH2-S04.05.01-P005`
- **Locator:** Baseline line 1322 / Candidate line 1320
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `CERT`, `REP`, `TMPL`
- **Diagnosis:** "Direct evidence" introduces a mechanism already explained in P002; the two final main-text sentences repeat the non-proportional capacity response.
- **Specific Action:** Condense duplicated mechanism wording; replace "provides direct evidence of" with "reflects"; preserve full scaling footnote.
- **Baseline:**
  > The negative sign of $\hat{\theta}_{\omega\kappa}$ provides direct evidence of defensive mechanization operating at the \emph{intensive margin} of capital composition. Specification~A established that effective wage pressure depresses the aggregate capacity yield of total capital ($\hat{\theta}_1 = -0.30$). Specification~B isolates the channel: wage pressure forces firms to widen the mechanization gap---substituting equipment for structures on the shop floor---but the capacity yield of that compositional shift is negative. The firm accumulates more machinery per dollar of structures, yet productive capacity does not expand proportionally, because the substitution is driven by cost containment rather than by genuine technical complementarity between new equipment and existing plant.\footnote{The apparent difference in magnitude between Specification~A ($\hat{\theta}_1 \approx -0.30$) and Specification~B ($\hat{\theta}_{\omega\kappa} \approx -7.93$ to $-17.05$) reflects regressor scaling, not economic inconsistency. In Specification~A, $\theta_1$ multiplies $\omega_{t-1}(1-\iota_{t-1}) \times k_{\text{cap},t}$, where aggregate capital $k_{\text{cap},t} \approx 16$--$17$ in log-levels. In Specification~B, $\theta_{\omega\kappa}$ multiplies $\omega_{t-1}(1-\iota_{t-1}) \times \kappa_t$, where the mechanization gap $\kappa_t = k^{\text{ME}}_t - k^{\text{NRC}}_t \approx 0.3$--$0.8$. The total marginal effect (coefficient $\times$ regressor scale) is comparable across both specifications.}
- **Candidate:**
  > The negative sign of $\hat{\theta}_{\omega\kappa}$ reflects defensive mechanization operating at the \emph{intensive margin} of capital composition. While Specification~A showed that effective wage pressure depresses the aggregate capacity yield of total capital ($\hat{\theta}_1 = -0.30$), Specification~B isolates the compositional channel: wage pressure forces firms to widen the mechanization gap---accumulating more machinery per dollar of structures on the shop floor---yet productive capacity does not expand proportionally because the substitution is driven by cost containment rather than technical complementarity between new equipment and existing plant.\footnote{The apparent difference in magnitude between Specification~A ($\hat{\theta}_1 \approx -0.30$) and Specification~B ($\hat{\theta}_{\omega\kappa} \approx -7.93$ to $-17.05$) reflects regressor scaling, not economic inconsistency. In Specification~A, $\theta_1$ multiplies $\omega_{t-1}(1-\iota_{t-1}) \times k_{\text{cap},t}$, where aggregate capital $k_{\text{cap},t} \approx 16$--$17$ in log-levels. In Specification~B, $\theta_{\omega\kappa}$ multiplies $\omega_{t-1}(1-\iota_{t-1}) \times \kappa_t$, where the mechanization gap $\kappa_t = k^{\text{ME}}_t - k^{\text{NRC}}_t \approx 0.3$--$0.8$. The total marginal effect (coefficient $\times$ regressor scale) is comparable across both specifications.}
- **Invariants Preserved:** $\hat{\theta}_{\omega\kappa} < 0$, intensive margin, Specification A comparison ($\hat{\theta}_1 = -0.30$), shop floor mechanization gap, non-proportional expansion, cost containment vs technical complementarity, footnote text verbatim.

---

### 15. `CH2-S04.05.01-P007`
- **Locator:** Baseline line 1328 / Candidate line 1326
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `CERT`, `REP`
- **Diagnosis:** The opening and closing announce the same cointegration verdict around a detailed test battery.
- **Specific Action:** State the cointegration verdict once at the end; remove the redundant opening sentence; preserve all tests, nulls, and statistics.
- **Baseline:**
  > \paragraph{Cointegration inference.}
  > The effective wage models show strong evidence of cointegration. The Shin LM test never rejects the null of cointegration ($C_{\text{Shin}} \le 0.03$, $p > 0.10$), and the Vogelsang-Wagner Type~2 Wald statistic remains well below critical thresholds ($S_{\text{Type~2}} \le 15.37$). The Engle-Granger residual ADF test rejects the null of no cointegration at the 5\% level in every break-adjusted model: $t_{\text{ADF}} = -4.58$ (Column~2), $-4.60$ (Column~4), $-4.71$ (Column~7), and $-4.57$ (Column~8). Without step shifts, the ADF test rejects at the 10\% level across all $T = 94$ models ($t_{\text{ADF}} \le -4.33$) and at the 5\% level for the $T = 76$ Shaikh-Tonak Tier~2 model ($t_{\text{ADF}} = -4.71$, Column~7). The full cointegration triad---Shin, Vogelsang-Wagner, and ADF---confirms that the disaggregated capital composition, real output, and effective wage pressure form a stable long-run relationship.
- **Candidate:**
  > \paragraph{Cointegration inference.}
  > Across the cointegration triad, the Shin LM test never rejects the null of cointegration ($C_{\text{Shin}} \le 0.03$, $p > 0.10$), and the Vogelsang-Wagner Type~2 Wald statistic remains well below critical thresholds ($S_{\text{Type~2}} \le 15.37$). The Engle-Granger residual ADF test rejects the null of no cointegration at the 5\% level in every break-adjusted model: $t_{\text{ADF}} = -4.58$ (Column~2), $-4.60$ (Column~4), $-4.71$ (Column~7), and $-4.57$ (Column~8). Without step shifts, the ADF test rejects at the 10\% level across all $T = 94$ models ($t_{\text{ADF}} \le -4.33$) and at the 5\% level for the $T = 76$ Shaikh-Tonak Tier~2 model ($t_{\text{ADF}} = -4.71$, Column~7). These results establish that disaggregated capital composition, real output, and effective wage pressure form a stable long-run relationship.
- **Invariants Preserved:** All 3 tests, null of cointegration, $C_{\text{Shin}} \le 0.03$, $p > 0.10$, $S_{\text{Type~2}} \le 15.37$, null of no cointegration, $t_{\text{ADF}} = -4.58, -4.60, -4.71, -4.57$, $t_{\text{ADF}} \le -4.33$, $T=94, 76$, stable long-run relationship verdict.

---

### 16. `CH2-S04.05.01-P008`
- **Locator:** Baseline line 1331 / Candidate line 1329
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `CERT`, `REP`
- **Diagnosis:** The opening, penultimate interpretation, and final confirmation repeatedly state that the interaction survives break controls.
- **Specific Action:** Condense duplicated survival statements into a single assertion of variance absorption while retaining significance; remove redundant final victory wrapper.
- **Baseline:**
  > \paragraph{Robustness.}
  > Including Bai-Perron step shifts absorbs historical level discontinuities, but leaves the sign and significance of the wage--mechanization interaction unchanged. In the Clean Corporate Tier~1 NVA model, controlling for breaks at 1944, 1977, and 2001 sharpens the ADF rejection from $-4.34$ ($p < 0.10$) to $-4.60$ ($p < 0.05$) while reducing the Vogelsang-Wagner statistic from $15.37$ to $6.37$. The wage interaction $\hat{\theta}_{\omega\kappa}$ moves from $-11.08$ (Column~3) to $-7.93$ (Column~4). This modest attenuation indicates that the step dummies absorb part of the interaction's raw variance. The interaction remains negative and significant at the 5\% level, confirming that the compositional conditioning channel survives institutional break controls.
- **Candidate:**
  > \paragraph{Robustness.}
  > Including Bai-Perron step shifts absorbs historical level discontinuities while preserving the wage--mechanization interaction. In the Clean Corporate Tier~1 NVA model, controlling for breaks at 1944, 1977, and 2001 sharpens the ADF rejection from $-4.34$ ($p < 0.10$) to $-4.60$ ($p < 0.05$) while reducing the Vogelsang-Wagner statistic from $15.37$ to $6.37$. The wage interaction $\hat{\theta}_{\omega\kappa}$ moves from $-11.08$ (Column~3) to $-7.93$ (Column~4), with the modest attenuation indicating that the step dummies absorb part of the interaction's raw variance while retaining significance at the 5\% level.
- **Invariants Preserved:** Break dates 1944, 1977, 2001, ADF $-4.34$ ($p < 0.10$) to $-4.60$ ($p < 0.05$), Vogelsang-Wagner $15.37$ to $6.37$, $\hat{\theta}_{\omega\kappa} = -11.08$ (Column 3) to $-7.93$ (Column 4), variance absorption rationale.

---

### 17. `CH2-S04.05.02-P004`
- **Locator:** Baseline line 1370 / Candidate line 1368
- **Operation:** COMPRESS (High Risk, Priority P1)
- **Phase 1 Codes:** `CERT`, `REP`
- **Diagnosis:** The ending again certifies the Okishio mechanism after P002/P005 of 4.5.1 and the preceding trajectory paragraph have established the interpretation.
- **Specific Action:** Remove only the final repeated model-vindication clause ("and confirms the Okishio mechanism empirically"); preserve the substantive contrast.
- **Baseline:**
  > Specification~A collapses this compositional mechanism into a scalar interaction ($\hat{\theta}_1 = -0.30$); Specification~B opens the intensive margin and confirms the Okishio mechanism empirically.
- **Candidate:**
  > Specification~A collapses this compositional mechanism into a scalar interaction ($\hat{\theta}_1 = -0.30$); Specification~B isolates the intensive margin directly.
- **Invariants Preserved:** Entire paragraph preceding the final clause, Fordist threshold ($C_{\text{index},t} > 0.65$), $MP_{\kappa,t}^{\text{str}} < 0$, Neoliberal threshold ($C_{\text{index},t} < 0.50$), positive territory, structural base, $\hat{\theta}_1 = -0.30$, intensive margin contrast.

---

### 18. `CH2-S04.05.02-P007`
- **Locator:** Baseline line 1388 / Candidate line 1386
- **Operation:** REWRITE (High Risk, Priority P1)
- **Phase 1 Codes:** `REP`, `SYN`, `MET`, `INT`
- **Diagnosis:** The worked example reaches a clear arithmetic result, then adds a drained-power punchline and a long, grammatically broken crisis explanation that repeats the mechanism.
- **Specific Action:** Rebuild sentence boundaries around the existing worked example; eliminate broken run-on grammar ("due firms over-shooting", "resulting into ... due the decreasing returns"); preserve every number, date, citation, and economic relation.
- **Baseline:**
  > Consider a given period during the Golden Age of American Capitalism (e.g., the 1950s) where the structural yield of nonresidential structures is $\theta_{\text{NRC}}^{\text{str}} = 0.60$ and the equipment share is $s_{\text{ME}} = 0.30$. Under a stable distributive environment, if the marginal capacity yield of mechanization is $MP_{\kappa} = 0.40$, the transformation elasticity yields an order of magnitude around $0.72$ ($\theta^{\text{SpecB}} = 0.60 + 0.30 \times 0.40$). However, as the post-war era progressed, machinery became structurally cheaper, as can be appreciated on the downswing tendency of $p_t^{\kappa}$ in Figure \ref{fig:us_specB_driving_forces}, pushing the physical equipment share up toward $0.50$. Likewise, the Profit Squeeze (1968--1973) produced a sharp spike in effective distributive pressure ($C_t$). Because the interaction term $\theta_{\omega\kappa}$ is negative, this heightened wage pressure pushing firms into a defensive tactical choice of technique, increasing their efforts for capital-using labor-saving mechanization, i.e. Marx-biased technical change \citep{Basu2022}. Consequently, the marginal capacity yield of this machinery dropped (say, to $MP_{\kappa} = 0.20$). In the post-Fordist era the aggregate elasticity then stands at $0.70$ ($\theta^{\text{SpecB}} = 0.60 + 0.50 \times 0.20$). The arithmetic is the point: a 20-percentage-point rise in the physical share of machinery leaves the aggregate elasticity essentially where it started, because the yield per unit of that machinery fell by half. Cheapening delivered the equipment; defensive investment under falling profitability drained its capacity-generating power. This mechanism explicitly limits accumulation through stagnation tendencies towards over-accumulation due firms over-shooting their investments biased towards mechanization not to expand capacity, but to replace increasingly expensive labor, resulting into an over-accumulation regime crisis due the decreasing returns to mechanization and increasingly harder to transform capital accumulation to productive capacities within the political economy of full employment with intense labor militancy \citep{Kalecki1943}.
- **Candidate:**
  > Consider a period during the Golden Age of American Capitalism (e.g., the 1950s) where the structural yield of nonresidential structures is $\theta_{\text{NRC}}^{\text{str}} = 0.60$ and the equipment share is $s_{\text{ME}} = 0.30$. Under a stable distributive environment, if the marginal capacity yield of mechanization is $MP_{\kappa} = 0.40$, the transformation elasticity is approximately $0.72$ ($\theta^{\text{SpecB}} = 0.60 + 0.30 \times 0.40$). As the post-war era progressed, machinery became structurally cheaper, reflected in the downward trend of $p_t^{\kappa}$ in Figure \ref{fig:us_specB_driving_forces}, pushing the physical equipment share up toward $0.50$. Simultaneously, the Profit Squeeze (1968--1973) generated a sharp spike in effective distributive pressure ($C_t$). Because the interaction term $\theta_{\omega\kappa}$ is negative, this heightened wage pressure pushed firms into a defensive choice of technique, accelerating capital-using labor-saving mechanization, or Marx-biased technical change \citep{Basu2022}. Consequently, the marginal capacity yield of machinery dropped (say, to $MP_{\kappa} = 0.20$), leaving the aggregate elasticity in the post-Fordist era at $0.70$ ($\theta^{\text{SpecB}} = 0.60 + 0.50 \times 0.20$). The arithmetic is the point: a 20-percentage-point rise in the physical share of machinery leaves the aggregate elasticity essentially where it started, because the yield per unit of that machinery fell by half. Cheapening delivered the equipment; defensive investment under falling profitability drained its capacity-generating power. This mechanism generates stagnation tendencies through overaccumulation. When firms invest in mechanization not to expand capacity but to replace increasingly expensive labor, diminishing returns to mechanization make it harder to transform capital accumulation into productive capacity, precipitating an overaccumulation crisis rooted in the political economy of full employment and labor militancy \citep{Kalecki1943}.
- **Invariants Preserved:** All numbers ($\theta_{\text{NRC}}^{\text{str}} = 0.60$, $s_{\text{ME}} = 0.30$, $MP_\kappa = 0.40$, $0.72$, $0.50$, $MP_\kappa = 0.20$, $0.70$, 20-percentage-point rise, fell by half), dates (1950s, 1968--1973), citations (\citep{Basu2022}, \citep{Kalecki1943}), variables ($p_t^\kappa$, $C_t$, $\theta_{\omega\kappa}$), Marx-biased technical change, overaccumulation crisis, and political economy of full employment with intense labor militancy.

---

## 4. Protected Hold Confirmation: `CH2-S04.05.02-P006`

In strict compliance with prompt Section 4 ("ABSOLUTE PROTECTED HOLD"), `CH2-S04.05.02-P006` was left completely untouched. 

Verification check from `01_BASELINE_SECTION4.tex` line 1386 to `02_CANDIDATE_4_4_4_5.tex` line 1384:
```latex
\paragraph{Driving Forces} The inclusion of heterogeneous capital reveals a structural paradox in the post-war US economy: while the relative cheapening of machinery drove a massive shift in the physical composition of capital, the capacity-generating power of this mechanization was severely degraded by the distributive conflicts of the late 1960s and early 1970s. Figure \ref{fig:us_specB_dual_theta_mu} plots the implicit capacity utilization rate ($\mu_t$) alongside the asset-weighted aggregate transformation elasticity ($\theta_t^{\text{SpecB}}$). Unlike the static baseline elasticity of Specification A, the transformation elasticity here is not solely driven by the evolving mix of machinery and structures, and the macroeconomic environment mediating their installation. As the physical accumulation of machinery and equipment accelerated relative to nonresidential structures, the aggregate transformation elasticity collapsed, severing the Harrodian link between accumulation and potential output. This structural degradation is not an artifact of index-number aggregation but the direct result of shifting marginal capacity yields. To unpack the mechanics of this collapse, Figure \ref{fig:us_specB_driving_forces} illustrates the two primary institutional driving forces behind this choice of technique: the secular decline in relative asset prices ($p_t^{\kappa} = P_t^{\text{ME}}/P_t^{\text{NRC}}$) and the episodic spikes in effective distributive pressure ($C_t = \omega_{t-1}(1-\iota_{t-1})$).
```
**Verdict:** Byte-identical match. Zero edits, zero inferences, zero harmonization.
