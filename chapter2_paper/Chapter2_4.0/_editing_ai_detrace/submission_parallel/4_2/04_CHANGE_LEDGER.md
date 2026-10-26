# Section 4.2 Paragraph Change Ledger

This ledger documents all candidate revisions generated for **Section 4.2** of Chapter 2 (`section4.tex`), comparing the frozen baseline `01_BASELINE_SECTION4.tex` (SHA-256 `2E97B366A5D6DACDFEF8A7AE0BBB8D5B42668C1218BE928FDED1DC1F28C80353`) and the candidate file `02_CANDIDATE_4_2.tex`.

**Verification Status:**
- Baseline SHA-256 verified identical to active `section4.tex`.
- Candidate generated strictly under candidate mode; active `section4.tex` remains byte-for-byte identical to baseline.
- Clean unified patch generated in `03_PATCH_4_2.diff`.
- All non-target paragraphs, headings, figures, tables, and lines certified byte-for-byte identical.

**Scope:** Eleven authorized Phase 1 prose units in Section 4.2 only:
- `CH2-S04.02-P001` (REWRITE)
- `CH2-S04.02.01-P001` (COMPRESS)
- `CH2-S04.02.01-P002` (LIGHT)
- `CH2-S04.02.01-P003` (LIGHT)
- `CH2-S04.02.01-P004` (LIGHT)
- `CH2-S04.02.01-P005` (LIGHT)
- `CH2-S04.02.02-P001` (COMPRESS)
- `CH2-S04.02.02-P002` (LIGHT)
- `CH2-S04.02.02-P003` (LIGHT)
- `CH2-S04.02.02-P004` (LIGHT)
- `CH2-S04.02.02-P006` (LIGHT)

**Locked Units (Protected):**
- `CH2-S04.02.01-P006` (KEEP — byte-for-byte identical)
- `CH2-S04.02.01-P007` (KEEP — byte-for-byte identical)
- `CH2-S04.02.02-P005` (KEEP — byte-for-byte identical)

**Word Count Summary (Target Paragraphs):**
- **Cleaned prose words:** 1,305 → 1,227 (-78 words; -6.0%)
- **Raw whitespace tokens:** 1,203 → 1,119 (-84 tokens; -7.0%)

---

## Summary Table

| Paragraph ID | Status | Orig Words (Raw) | Cand Words (Raw) | Δ Words | Δ % | Citations | Numbers | Math | Refs | Operation Performed |
|---|---|---:|---:|---:|---:|:---:|:---:|:---:|:---:|---|
| **CH2-S04.02-P001** | REWRITE | 199 (199) | 174 (174) | -25 | -12.6% | PASS (1/1) | PASS (5/5) | PASS (0/0) | PASS (0/0) | Repaired broken enumeration (two "Third"s resolved into First--Fourth); rebuilt sentence boundaries around measurement, co-movement, ratio drift, capital composition, and state-dependent institutional shifts. Preserved "suggesting" and "unclear". |
| **CH2-S04.02.01-P001** | COMPRESS | 143 (139) | 113 (109) | -30 | -21.0% | PASS (0/0) | PASS (3/3) | PASS (0/0) | PASS (1/1) | Removed empirical grounding scaffolding, duplicated announcements, and "foundational structural characteristics" rhetoric. Preserved NFC scope, capital/output growth divergence, wage share dynamics, aggregate moments vs historical shifts distinction, and table reference. |
| **CH2-S04.02.01-P002** | LIGHT | 80 (64) | 76 (60) | -4 | -5.0% | PASS (0/0) | PASS (1/1) | PASS (2/2) | PASS (1/1) | Varied Figure-first opening by integrating figure pointer into the substantive pattern statement. Retained log series definitions, common upward trend, post-1980s overaccumulation gap, and first-difference information-loss claim. |
| **CH2-S04.02.01-P003** | LIGHT | 125 (116) | 122 (112) | -3 | -2.4% | PASS (0/0) | PASS (7/7) | PASS (3/3) | PASS (1/1) | Varied opener; repaired syntax ("does not renders" → "does not render", coordinated subject-verb agreement). Preserved mobilization peak (1944), Cold War fall, Fordist hump (1966), LOESS downward drift, tentative suggestion of $\theta < 1$, and knife-edge claim. |
| **CH2-S04.02.01-P004** | LIGHT | 134 (117) | 134 (116) | 0 | 0.0% | PASS (0/0) | PASS (5/5) | PASS (5/5) | PASS (2/2) | Varied Figure opener while preserving exact linear sequence of references. Preserved mean/SD, Great Depression/WWII levels, Fordist march, late 1990s IT boom peak, post-2000 IPP shift, and heterogeneous-capital model motivation. |
| **CH2-S04.02.01-P005** | LIGHT | 119 (107) | 126 (113) | +7 | +5.9% | PASS (0/0) | PASS (9/9) | PASS (0/0) | PASS (2/2) | Varied exhibit opener; corrected typos (`accumultion` → `accumulation`, `capiatl` → `capital`) and repeated `reflected` construction. Preserved growth rates, SDs, dated spikes (1946, 1974), post-1950 recession asymmetry, and physical capital durability. |
| **CH2-S04.02.02-P001** | COMPRESS | 106 (102) | 86 (82) | -20 | -18.9% | PASS (0/0) | PASS (3/3) | PASS (0/0) | PASS (1/1) | Condensed duplicated roadmap; corrected diagnosed spelling errors (`analyitical` → `analytical`, `emirical` → `empirical`). Preserved Chile 1940--2010 sample, variable coverage, aggregate moments vs regime shifts distinction, analytical framework link (Section 3.3), and threshold motivation. |
| **CH2-S04.02.02-P002** | LIGHT | 67 (58) | 69 (59) | +2 | +3.0% | PASS (0/0) | PASS (5/5) | PASS (2/2) | PASS (1/1) | Placed series and price basis first; repaired incomplete date phrase ("1990 the post-dictatorship period" → "the 1990 post-dictatorship period"). Preserved GDP/core-stock definitions, 2003 CLP price basis, 1940--2010 sample, shared trend, and both institutional dates. |
| **CH2-S04.02.02-P003** | LIGHT | 75 (65) | 70 (59) | -5 | -6.7% | PASS (0/0) | PASS (6/6) | PASS (1/1) | PASS (1/1) | Excised diagnosed arrangement commentary ("providing the symmetric parallel to the U.S. series"); varied opener. Preserved U.S. secular decline vs Chilean regime shifts contrast, state-led ISI phase (1940--1955), 1972--1975 breakdown, 1982 debt crisis, and 1990s commodity boom. |
| **CH2-S04.02.02-P004** | LIGHT | 102 (86) | 102 (85) | 0 | 0.0% | PASS (0/0) | PASS (6/6) | PASS (3/3) | PASS (2/2) | Varied Figure opener while preserving exact linear sequence of references; retained model link to $\kappa_t$-dependent $\theta$. Preserved mean/SD, ISI trajectory, 1981 debt-boom hump, late 1980s trough, mining-led accumulation, and heterogeneous-capital motivation. |
| **CH2-S04.02.02-P006** | LIGHT | 155 (150) | 155 (150) | 0 | 0.0% | PASS (1/1) | PASS (5/5) | PASS (0/0) | PASS (1/1) | Repaired final clause subject-verb agreement only ("counteract" → "counteracts" to agree with "the external constraint"). Preserved all four component trajectories (solvency, terms of trade, real exports, machinery investment), import imbalance WBOP source, and threshold grid-search mechanism. |

---

## Detailed Paragraph Audits

### CH2-S04.02-P001 (Lines 688--693)
- **Baseline text:**
  ```latex
  This subsection presents stylized facts and descriptive statistics of my data set for the United States (1931--2024) and Chile
  (1940--2010). First, the data presented for output correspond always to Non Financial Corporate Sector, while the measurement of capital stock correspond to gross measures following my own implementation of \citet{Shaikh2016} \textit{Generalized Perpetual Inventory Method} (GPIM) as presented above.  Second, output and capital stocks drift together over the long run in both economies, motivating a cointegrating approach. Third, the level of the output--capital ratio drifts through time in both countries of interest: in the United States presents a declining trend in the long-run, suggesting that their long-run relation might be governed by a transformation elasticity below unity; while in the case in Chile the relation is unclear, while its composition when distinguishing between non-residential construction and machinery and equipments accounts discretely shifts across historical regimes, this motivates a formulation of heterogeneous capital. Third, in the US capital accumulates faster than output on average. Fourth, the state variables that condition
  the transformation---the distributive state in both economies and the
  external bottleneck components in the periphery---shift discretely across
  institutional regimes, motivating a state-dependent and threshold
  co-integration empirical strategies presented in the next Section~4.3. 
  ```
- **Candidate text:**
  ```latex
  This subsection presents stylized facts and descriptive statistics of my data set for the United States (1931--2024) and Chile (1940--2010). First, output data correspond to the Non Financial Corporate Sector, while capital stock measurement corresponds to gross measures following my implementation of \citet{Shaikh2016} \textit{Generalized Perpetual Inventory Method} (GPIM) presented above. Second, output and capital stocks drift together over the long run in both economies, motivating a cointegrating approach. Third, the output--capital ratio drifts through time in both countries: in the United States, capital accumulates faster than output on average and the ratio presents a declining long-run trend, suggesting that their long-run relation might be governed by a transformation elasticity below unity; in Chile, the relation is unclear, while capital composition between non-residential construction and machinery and equipment shifts discretely across historical regimes, motivating a formulation of heterogeneous capital. Fourth, the state variables that condition the transformation---the distributive state in both economies and the external bottleneck components in the periphery---shift discretely across institutional regimes, motivating the state-dependent and threshold cointegration empirical strategies presented in Section~4.3.
  ```
- **Cleaned words:** 199 → 174 (-25 words; -12.6%)
- **Raw words:** 199 → 174 (-25 words; -12.6%)
- **Citations preserved:** `\citet{Shaikh2016}` (PASS).
- **Numbers preserved:** `1931`, `2024`, `1940`, `2010`, `4.3` (PASS).
- **Math preserved:** None in baseline; none in candidate (PASS).
- **Refs preserved:** None in baseline; none in candidate (PASS).
- **Causal direction & uncertainty preserved:** PASS. Tentative formulation ("suggesting that their long-run relation might be governed by a transformation elasticity below unity") and empirical uncertainty for Chile ("the relation is unclear") are preserved verbatim.
- **Operation:** REWRITE. Repaired broken enumeration (where "Third" was duplicated) into a logical sequence (First, Second, Third, Fourth); consolidated the U.S. faster accumulation claim into the third item alongside the ratio trend; disentangled Chile's uncertain ratio from its capital composition shifts.

---

### CH2-S04.02.01-P001 (Line 697)
- **Baseline text:**
  ```latex
  To ground the subsequent econometric analysis in empirical reality, this subsection documents the key stylized facts of the U.S. non-financial corporate economy over the 94-year sample period from 1931 to 2024. Table~\ref{tab:us_stylized_facts_summary} provides the summary statistics for the core macroeconomic and distributive variables, capturing the long-run means and volatilities of real output, capital accumulation, functional income distribution, and the evolving composition of the capital stock. While these aggregate moments establish the foundational structural characteristics of the economy—such as the persistent divergence between capital and output growth and the shifting dynamics of the wage share—the temporal evolution and historical regime shifts underlying these averages require a detailed chronological examination. The following figures therefore trace the secular trends, cyclical fluctuations, and structural breaks across these dimensions, providing the empirical motivation for the theoretical and econometric specifications developed in the subsequent sections.
  ```
- **Candidate text:**
  ```latex
  Table~\ref{tab:us_stylized_facts_summary} provides summary statistics for the core macroeconomic and distributive variables of the U.S. non-financial corporate economy over the 94-year sample period from 1931 to 2024, capturing the long-run means and volatilities of real output, capital accumulation, functional income distribution, and the evolving composition of the capital stock. While these aggregate moments record the persistent divergence between capital and output growth and the shifting dynamics of the wage share, the historical regime shifts underlying these averages require chronological examination. The series that follow trace the secular trends, cyclical fluctuations, and structural breaks across these dimensions, providing the empirical motivation for the theoretical and econometric specifications developed in subsequent sections.
  ```
- **Cleaned words:** 143 → 113 (-30 words; -21.0%)
- **Raw words:** 139 → 109 (-30 words; -21.6%)
- **Citations preserved:** None in baseline; none in candidate (PASS).
- **Numbers preserved:** `94`, `1931`, `2024` (PASS).
- **Math preserved:** None in baseline; none in candidate (PASS).
- **Refs preserved:** `\ref{tab:us_stylized_facts_summary}` (PASS).
- **Causal direction & uncertainty preserved:** PASS. Motivation for theoretical and econometric specifications from secular trends, cyclical fluctuations, and structural breaks is fully preserved.
- **Operation:** COMPRESS. Excised generic rhetorical grounding ("To ground the subsequent econometric analysis in empirical reality..."), repeated announcements, and "foundational structural characteristics" padding. Substantive distinction between aggregate summary moments and historical regime shifts retained.

---

### CH2-S04.02.01-P002 (Line 701)
- **Baseline text:**
  ```latex
  Figure~\ref{fig:us_stylized_1_y_kcap} plots log real non-financial corporate output ($y_t$) and the log of aggregate gross capital stock $k_t^{cap} = \ln(K_t^{\text{ME}} + K_t^{\text{NRC}})$. Over the 94-year sample, the two levels drift together along a common upward trend. From the early 1980s onward, the capital stock runs systematically above output, generating a persistent overaccumulation gap. Estimating in first differences would discard exactly this shared long-run cointegrating trajectory.
  ```
- **Candidate text:**
  ```latex
  Log real non-financial corporate output ($y_t$) and the log of aggregate gross capital stock $k_t^{cap} = \ln(K_t^{\text{ME}} + K_t^{\text{NRC}})$ drift together along a common upward trend over the 94-year sample (Figure~\ref{fig:us_stylized_1_y_kcap}). From the early 1980s onward, the capital stock runs systematically above output, generating a persistent overaccumulation gap. Estimating in first differences would discard exactly this shared long-run cointegrating trajectory.
  ```
- **Cleaned words:** 80 → 76 (-4 words; -5.0%)
- **Raw words:** 64 → 60 (-4 words; -6.3%)
- **Citations preserved:** None in baseline; none in candidate (PASS).
- **Numbers preserved:** `94`, `1980` (PASS).
- **Math preserved:** `$y_t$`, `$k_t^{cap} = \ln(K_t^{\text{ME}} + K_t^{\text{NRC}})$` (PASS).
- **Refs preserved:** `\ref{fig:us_stylized_1_y_kcap}` (PASS).
- **Causal direction & uncertainty preserved:** PASS. Cointegrating drift and first-difference information-loss argument preserved intact.
- **Operation:** LIGHT. Varied Figure-led opening by integrating exhibit reference into empirical trajectory description.

---

### CH2-S04.02.01-P003 (Line 703)
- **Baseline text:**
  ```latex
  Figure~\ref{fig:us_stylized_2_yk_ratio} plots the corresponding log output--capital ratio ($y_t - k_t^{cap}$). The ratio spikes to its historical maximum under wartime mobilization (1944), falls through the early Cold War, recovers part of the decline in a Fordist hump around 1966, and declines secularly thereafter. The LOESS trend traces a downward drift from 1950 onward, steepening after 1970 and again after 2000. A ratio that falls for decades while capital accumulates provides an empirical suggestion of an over-accumulation tendency $\theta < 1$: capacity formation persistently lags capital accumulation. The balanced-growth knife-edge $\theta = 1$ does not renders as a long-run tendency, once the measurement of capital stock and the dual valuation distinction and the purpose of measurement is considered. 
  ```
- **Candidate text:**
  ```latex
  The corresponding log output--capital ratio ($y_t - k_t^{cap}$, Figure~\ref{fig:us_stylized_2_yk_ratio}) spikes to its historical maximum under wartime mobilization (1944), falls through the early Cold War, recovers part of the decline in a Fordist hump around 1966, and declines secularly thereafter. The LOESS trend traces a downward drift from 1950 onward, steepening after 1970 and again after 2000. A ratio that falls for decades while capital accumulates provides an empirical suggestion of an over-accumulation tendency $\theta < 1$: capacity formation persistently lags capital accumulation. The balanced-growth knife-edge $\theta = 1$ does not render as a long-run tendency, once the measurement of capital stock, the dual valuation distinction, and the purpose of measurement are considered.
  ```
- **Cleaned words:** 125 → 122 (-3 words; -2.4%)
- **Raw words:** 116 → 112 (-4 words; -3.4%)
- **Citations preserved:** None in baseline; none in candidate (PASS).
- **Numbers preserved:** `1944`, `1966`, `1950`, `1970`, `2000`, `1`, `1` (PASS).
- **Math preserved:** `$y_t - k_t^{cap}$`, `$\theta < 1$`, `$\theta = 1$` (PASS).
- **Refs preserved:** `\ref{fig:us_stylized_2_yk_ratio}` (PASS).
- **Causal direction & uncertainty preserved:** PASS. Tentative empirical inference of overaccumulation ("provides an empirical suggestion of an over-accumulation tendency $\theta < 1$") and valuation/knife-edge argument preserved.
- **Operation:** LIGHT. Varied figure opening; repaired grammar ("does not renders" → "does not render"; resolved coordination and agreement in the final clause).

---

### CH2-S04.02.01-P004 (Line 705)
- **Baseline text:**
  ```latex
  Figure~\ref{fig:us_stylized_2b_kappa} plots the mechanization gap $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$ (mean $-0.637$, SD $0.278$, Table~\ref{tab:us_stylized_facts_summary}). The gap remains depressed throughout the Great Depression and World War II ($\approx -1.15$), embarks on a sustained upward march across the Golden Age of Atlantic Fordism as machinery and equipment outpaced industrial structures, and peaks in the late 1990s ($\approx -0.313$) during the information-technology equipment boom. From 2000 onward, $\kappa_t$ declines as investment shifted toward structures and commercial real estate while Intellectual Property Products absorbed intangible accumulation, leaving direct physical machinery accumulation subdued. The capital composition ratio is therefore a regime-shifting series rather than a smooth trend, motivating the heterogeneous-capital specification in which the transformation elasticity $\theta$ depends dynamically on $\kappa_t$.
  ```
- **Candidate text:**
  ```latex
  The mechanization gap $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$, plotted in Figure~\ref{fig:us_stylized_2b_kappa} (mean $-0.637$, SD $0.278$, Table~\ref{tab:us_stylized_facts_summary}), remains depressed throughout the Great Depression and World War II ($\approx -1.15$), embarks on a sustained upward march across the Golden Age of Atlantic Fordism as machinery and equipment outpaced industrial structures, and peaks in the late 1990s ($\approx -0.313$) during the information-technology equipment boom. From 2000 onward, $\kappa_t$ declines as investment shifted toward structures and commercial real estate while Intellectual Property Products absorbed intangible accumulation, leaving direct physical machinery accumulation subdued. The capital composition ratio is therefore a regime-shifting series rather than a smooth trend, motivating the heterogeneous-capital specification in which the transformation elasticity $\theta$ depends dynamically on $\kappa_t$.
  ```
- **Cleaned words:** 134 → 134 (0 words; 0.0%)
- **Raw words:** 117 → 116 (-1 word; -0.9%)
- **Citations preserved:** None in baseline; none in candidate (PASS).
- **Numbers preserved:** `-0.637`, `0.278`, `-1.15`, `1990`, `-0.313`, `2000` (PASS).
- **Math preserved:** `$\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$`, `$\approx -1.15$`, `$\approx -0.313$`, `$\kappa_t$`, `$\theta$` (PASS).
- **Refs preserved:** `\ref{fig:us_stylized_2b_kappa}`, `\ref{tab:us_stylized_facts_summary}` in exact original sequence (PASS).
- **Causal direction & uncertainty preserved:** PASS. Chronology, mechanism, and heterogeneous-capital model motivation strictly preserved.
- **Operation:** LIGHT. Varied Figure lead while maintaining the exact linear reference order.

---

### CH2-S04.02.01-P005 (Line 707)
- **Baseline text:**
  ```latex
  Figure~\ref{fig:us_stylized_3_growth_rates} contrasts annual growth rates. Over the full sample, aggregate gross capital accumulation grows faster than output on average (5.9\% against 3.9\% per year, Table~\ref{tab:us_stylized_facts_summary}), a long-run relation consistent with overaccumulation under an unbalanced growth closure. The two series have comparable standard deviations (0.051 against 0.045) because the pre-1950 window contains large swings in both, including capital-growth spikes around 1946 and 1974. The asymmetry that matters for estimation appears after 1950: output growth repeatedly turns negative in recessions while capital accumultion remains positive, reflecting the durability of physical capiatl in operation reflected by gross measurements. From the mid-1960s, the capital-growth series sits mostly above the output-growth line.
  ```
- **Candidate text:**
  ```latex
  Annual growth rates of output and capital are contrasted in Figure~\ref{fig:us_stylized_3_growth_rates}. Over the full sample, aggregate gross capital accumulation grows faster than output on average (5.9\% against 3.9\% per year, Table~\ref{tab:us_stylized_facts_summary}), a long-run relation consistent with overaccumulation under an unbalanced growth closure. The two series have comparable standard deviations (0.051 against 0.045) because the pre-1950 window contains large swings in both, including capital-growth spikes around 1946 and 1974. The asymmetry that matters for estimation appears after 1950: output growth repeatedly turns negative in recessions while capital accumulation remains positive, reflecting the durability of physical capital in operation captured by gross measurements. From the mid-1960s, the capital-growth series sits mostly above the output-growth line.
  ```
- **Cleaned words:** 119 → 126 (+7 words; +5.9%)
- **Raw words:** 107 → 113 (+6 words; +5.6%)
- **Citations preserved:** None in baseline; none in candidate (PASS).
- **Numbers preserved:** `5.9%`, `3.9%`, `0.051`, `0.045`, `1950`, `1946`, `1974`, `1950`, `1960` (PASS).
- **Math preserved:** None in baseline; none in candidate (PASS).
- **Refs preserved:** `\ref{fig:us_stylized_3_growth_rates}`, `\ref{tab:us_stylized_facts_summary}` in exact original sequence (PASS).
- **Causal direction & uncertainty preserved:** PASS. All growth rates, standard deviations, post-1950 recession asymmetry, and physical capital durability preserved.
- **Operation:** LIGHT. Varied exhibit opener; corrected typos (`accumultion` → `accumulation`, `capiatl` → `capital`); eliminated duplicate verb construction ("reflecting ... reflected by" → "reflecting ... captured by").

---

### CH2-S04.02.02-P001 (Line 773)
- **Baseline text:**
  ```latex
  This section documents the stylized facts of the Chilean economy over the 1940--2010 sample. Table~\ref{tab:cl_stylized_facts_summary} presents summary statistics for the core macroeconomic, distributive, and external variables, capturing the long-run means and volatilities of real output, capital accumulation, income distribution, and the balance of payments. Because these aggregate moments obscure the pronounced historical regime shifts characteristic of the periphery, the following figures trace the temporal evolution of these series to highlight the structural breaks, distributive fractures, and variables related to the external constraints of peripheral capitalism that motivate the heterogeneous-capital analyitical framework previously presented in Section~3.3 and the threshold emirical strategy developed below.
  ```
- **Candidate text:**
  ```latex
  Table~\ref{tab:cl_stylized_facts_summary} presents summary statistics for the core macroeconomic, distributive, and external variables of the Chilean economy over the 1940--2010 sample, capturing the long-run means and volatilities of real output, capital accumulation, income distribution, and the balance of payments. Because these aggregate moments obscure the pronounced historical regime shifts characteristic of the periphery, the series that follow trace the structural breaks, distributive fractures, and external constraint variables that motivate the heterogeneous-capital analytical framework presented in Section~3.3 and the threshold empirical strategy developed below.
  ```
- **Cleaned words:** 106 → 86 (-20 words; -18.9%)
- **Raw words:** 102 → 82 (-20 words; -19.6%)
- **Citations preserved:** None in baseline; none in candidate (PASS).
- **Numbers preserved:** `1940`, `2010`, `3.3` (PASS).
- **Math preserved:** None in baseline; none in candidate (PASS).
- **Refs preserved:** `\ref{tab:cl_stylized_facts_summary}` (PASS).
- **Causal direction & uncertainty preserved:** PASS. Historical regime shifts, peripheral structural breaks, analytical framework link (Section 3.3), and threshold empirical strategy strictly preserved.
- **Operation:** COMPRESS. Excised duplicated section roadmap; repaired diagnosed spelling typos (`analyitical` → `analytical`, `emirical` → `empirical`).

---

### CH2-S04.02.02-P002 (Line 777)
- **Baseline text:**
  ```latex
  Figure~\ref{fig:cl_stylized_1a_y_kcap} plots log real GDP ($y_t$) and the aggregate gross core capital stock ($k_t^{cap} = \ln[K_t^{\text{ME}} + K_t^{\text{NRC}}]$) on the same 2003 CLP price basis for Chile (1940--2010). Over seven decades, output and capital drift together along a shared upward trajectory, motivating the cointegrating specification. Dotted vertical lines mark the 1973 military coup and 1990 the post-dictatorship period.
  ```
- **Candidate text:**
  ```latex
  Log real GDP ($y_t$) and aggregate gross core capital stock ($k_t^{cap} = \ln[K_t^{\text{ME}} + K_t^{\text{NRC}}]$) for Chile (1940--2010) are plotted on the same 2003 CLP price basis in Figure~\ref{fig:cl_stylized_1a_y_kcap}. Over seven decades, output and capital drift together along a shared upward trajectory, motivating the cointegrating specification. Dotted vertical lines mark the 1973 military coup and the 1990 post-dictatorship period.
  ```
- **Cleaned words:** 67 → 69 (+2 words; +3.0%)
- **Raw words:** 58 → 59 (+1 word; +1.7%)
- **Citations preserved:** None in baseline; none in candidate (PASS).
- **Numbers preserved:** `2003`, `1940`, `2010`, `1973`, `1990` (PASS).
- **Math preserved:** `$y_t$`, `$k_t^{cap} = \ln[K_t^{\text{ME}} + K_t^{\text{NRC}}]$` (PASS).
- **Refs preserved:** `\ref{fig:cl_stylized_1a_y_kcap}` (PASS).
- **Causal direction & uncertainty preserved:** PASS. Cointegrating motivation, sample duration, and political markers preserved.
- **Operation:** LIGHT. Varied exhibit lead to emphasize the series and price basis; repaired date phrase syntax ("1990 the post-dictatorship period" → "the 1990 post-dictatorship period").

---

### CH2-S04.02.02-P003 (Line 779)
- **Baseline text:**
  ```latex
  Figure~\ref{fig:cl_stylized_1b_yk_ratio} plots the corresponding log output--capital ratio ($y_t - k_t^{cap}$) for Chile, providing the symmetric parallel to the U.S. series. Unlike the continuous secular decline in the center, the peripheral output--capital ratio exhibits pronounced regime shifts: rising during the initial state-led ISI phase (1940--1955), collapsing during the 1972--1975 breakdown and the 1982 debt crisis, and settling into an unconstrained expansion during the 1990s commodity boom.
  ```
- **Candidate text:**
  ```latex
  The corresponding log output--capital ratio ($y_t - k_t^{cap}$) for Chile is plotted in Figure~\ref{fig:cl_stylized_1b_yk_ratio}. Unlike the continuous secular decline in the center, the peripheral output--capital ratio exhibits pronounced regime shifts: rising during the initial state-led ISI phase (1940--1955), collapsing during the 1972--1975 breakdown and the 1982 debt crisis, and settling into an unconstrained expansion during the 1990s commodity boom.
  ```
- **Cleaned words:** 75 → 70 (-5 words; -6.7%)
- **Raw words:** 65 → 59 (-6 words; -9.2%)
- **Citations preserved:** None in baseline; none in candidate (PASS).
- **Numbers preserved:** `1940`, `1955`, `1972`, `1975`, `1982`, `1990` (PASS).
- **Math preserved:** `$y_t - k_t^{cap}$` (PASS).
- **Refs preserved:** `\ref{fig:cl_stylized_1b_yk_ratio}` (PASS).
- **Causal direction & uncertainty preserved:** PASS. Center secular decline vs peripheral regime shifts contrast and all historical periodizations preserved.
- **Operation:** LIGHT. Excised diagnosed arrangement commentary ("providing the symmetric parallel to the U.S. series"); varied opener.

---

### CH2-S04.02.02-P004 (Lines 781--790)
- **Baseline text:**
  ```latex
  Figure~\ref{fig:cl_stylized_2_kappa_mechanization} plots the mechanization
  gap $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$ (mean $-1.106$, SD
  $0.211$, Table~\ref{tab:cl_stylized_facts_summary}). The gap widens from the
  late 1940s through state-led ISI to 1972, stagnates under the early
  neoliberal regime with a debt-boom hump at 1981 and a post-crisis trough in
  the late 1980s, and rises sharply after redemocratization, when
  export-oriented mining pulled machinery accumulation ahead of structures.
  The gap is therefore a regime-shifting series rather than a smooth trend,
  which is what motivates the heterogeneous-capital specification in which
  $\theta$ depends on $\kappa_t$.
  ```
- **Candidate text:**
  ```latex
  The mechanization gap $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$, plotted in Figure~\ref{fig:cl_stylized_2_kappa_mechanization} (mean $-1.106$, SD $0.211$, Table~\ref{tab:cl_stylized_facts_summary}), widens from the late 1940s through state-led ISI to 1972, stagnates under the early neoliberal regime with a debt-boom hump at 1981 and a post-crisis trough in the late 1980s, and rises sharply after redemocratization, when export-oriented mining pulled machinery accumulation ahead of structures. The gap is therefore a regime-shifting series rather than a smooth trend, which is what motivates the heterogeneous-capital specification in which $\theta$ depends on $\kappa_t$.
  ```
- **Cleaned words:** 102 → 102 (0 words; 0.0%)
- **Raw words:** 86 → 85 (-1 word; -1.2%)
- **Citations preserved:** None in baseline; none in candidate (PASS).
- **Numbers preserved:** `-1.106`, `0.211`, `1940`, `1972`, `1981`, `1980` (PASS).
- **Math preserved:** `$\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$`, `$\theta$`, `$\kappa_t$` (PASS).
- **Refs preserved:** `\ref{fig:cl_stylized_2_kappa_mechanization}`, `\ref{tab:cl_stylized_facts_summary}` in exact original sequence (PASS).
- **Causal direction & uncertainty preserved:** PASS. Historical trajectory and closing heterogeneous-capital model link strictly preserved.
- **Operation:** LIGHT. Varied opener only while maintaining linear sequence of references; explicitly retained the model link.

---

### CH2-S04.02.02-P006 (Lines 800--812)
- **Baseline text:**
  ```latex
  Figure~\ref{fig:cl_stylized_4_minipages} disaggregates the external
  bottleneck into its components. The solvency ratio (Panel a), central bank
  reserves relative to base money, is flat and low until 1975, jumps after the
  debt crisis as the Bank accumulated reserves, and declines again after the
  mid-2000s. The terms of trade (Panel b) deteriorate through the 1970s and
  1980s and recover only with the commodity super-cycle. Real exports
  (Panel c) grow smoothly, so the binding episodes are driven by reserve
  solvency and import demand rather than by export failure; the import
  imbalance series follows the World Historical Balance of Payments database
  of \citet{NievasPiketty2025}. Machinery investment (Panel d) grows in bursts
  separated by the crisis dates, consistent with mechanization that is
  interrupted rather than smoothly accumulated. Section~4.5 assembles these
  components into the composite index through a grid search, and estimates the threshold at which the external constraint becomes binding and counteract the mechanization bias productivity gain. 
  ```
- **Candidate text:**
  ```latex
  Figure~\ref{fig:cl_stylized_4_minipages} disaggregates the external
  bottleneck into its components. The solvency ratio (Panel a), central bank
  reserves relative to base money, is flat and low until 1975, jumps after the
  debt crisis as the Bank accumulated reserves, and declines again after the
  mid-2000s. The terms of trade (Panel b) deteriorate through the 1970s and
  1980s and recover only with the commodity super-cycle. Real exports
  (Panel c) grow smoothly, so the binding episodes are driven by reserve
  solvency and import demand rather than by export failure; the import
  imbalance series follows the World Historical Balance of Payments database
  of \citet{NievasPiketty2025}. Machinery investment (Panel d) grows in bursts
  separated by the crisis dates, consistent with mechanization that is
  interrupted rather than smoothly accumulated. Section~4.5 assembles these
  components into the composite index through a grid search, and estimates the threshold at which the external constraint becomes binding and counteracts the mechanization bias productivity gain.
  ```
- **Cleaned words:** 155 → 155 (0 words; 0.0%)
- **Raw words:** 150 → 150 (0 words; 0.0%)
- **Citations preserved:** `\citet{NievasPiketty2025}` (PASS).
- **Numbers preserved:** `1975`, `2000`, `1970`, `1980`, `4.5` (PASS).
- **Math preserved:** None in baseline; none in candidate (PASS).
- **Refs preserved:** `\ref{fig:cl_stylized_4_minipages}` (PASS).
- **Causal direction & uncertainty preserved:** PASS. All four component mechanisms, Nievas-Piketty data attribution, reserve-solvency driver, and grid-search threshold assembly strictly preserved.
- **Operation:** LIGHT. Repaired final clause subject-verb agreement only ("counteract" → "counteracts" to agree with "the external constraint").

---

## Byte-for-Byte Preservation of Non-Target Units

- Lines 1--684 of `section4.tex` (prior to Section 4.2): Verified byte-for-byte identical.
- Lines 814--1744 of `section4.tex` (following Section 4.2): Verified byte-for-byte identical.
- All embedded figure floats and table inputs within Section 4.2: Verified byte-for-byte identical:
  - `\input{tables/tab_us_stylized_facts_summary.tex}` (line 699)
  - `\input{tables/tab_cl_stylized_facts_summary.tex}` (line 775)
  - Figures `fig:us_stylized_1_y_kcap`, `fig:us_stylized_2_yk_ratio`, `fig:us_stylized_2b_kappa`, `fig:us_stylized_3_growth_rates`, `fig:us_stylized_4a_distributive_state`, `fig:us_stylized_4b_distributive_state`
  - Figures `fig:cl_stylized_1a_y_kcap`, `fig:cl_stylized_1b_yk_ratio`, `fig:cl_stylized_2_kappa_mechanization`, `fig:cl_stylized_3_wage_share`, `fig:cl_stylized_4_minipages`
- Protected KEEP paragraphs:
  - `CH2-S04.02.01-P006` (line 709): Verified byte-for-byte identical.
  - `CH2-S04.02.01-P007` (line 711): Verified byte-for-byte identical.
  - `CH2-S04.02.02-P005` (lines 792--798): Verified byte-for-byte identical.
