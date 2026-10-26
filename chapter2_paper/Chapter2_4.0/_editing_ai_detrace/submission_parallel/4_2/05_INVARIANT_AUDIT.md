# Section 4.2 Invariant Audit

This is a comprehensive **source-preservation and substantive-lock audit** generated from the verified baseline `01_BASELINE_SECTION4.tex` (SHA-256 `2E97B366A5D6DACDFEF8A7AE0BBB8D5B42668C1218BE928FDED1DC1F28C80353`) and the candidate file `02_CANDIDATE_4_2.tex`.

**Audit boundary:** Verification of preservation across all eleven authorized Phase 1 prose units in Section 4.2, byte-for-byte preservation of all non-target text in `section4.tex`, and verification that the active manuscript file `section4.tex` was not modified.

---

## 1. Automated Invariants on Changed Paragraphs

| Paragraph ID | Line (Baseline) | Citation Keys | Numeric Literals | Inline Math | Cross-References | Causal Direction | Uncertainty Level | Automated Status |
|---|---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **CH2-S04.02-P001** | 688 | PASS (1/1) | PASS (5/5) | PASS (0/0) | PASS (0/0) | PASS | PASS | **PASS** |
| **CH2-S04.02.01-P001** | 697 | PASS (0/0) | PASS (3/3) | PASS (0/0) | PASS (1/1) | PASS | PASS | **PASS** |
| **CH2-S04.02.01-P002** | 701 | PASS (0/0) | PASS (1/1) | PASS (2/2) | PASS (1/1) | PASS | PASS | **PASS** |
| **CH2-S04.02.01-P003** | 703 | PASS (0/0) | PASS (7/7) | PASS (3/3) | PASS (1/1) | PASS | PASS | **PASS** |
| **CH2-S04.02.01-P004** | 705 | PASS (0/0) | PASS (5/5) | PASS (5/5) | PASS (2/2) | PASS | PASS | **PASS** |
| **CH2-S04.02.01-P005** | 707 | PASS (0/0) | PASS (9/9) | PASS (0/0) | PASS (2/2) | PASS | PASS | **PASS** |
| **CH2-S04.02.02-P001** | 773 | PASS (0/0) | PASS (3/3) | PASS (0/0) | PASS (1/1) | PASS | PASS | **PASS** |
| **CH2-S04.02.02-P002** | 777 | PASS (0/0) | PASS (5/5) | PASS (2/2) | PASS (1/1) | PASS | PASS | **PASS** |
| **CH2-S04.02.02-P003** | 779 | PASS (0/0) | PASS (6/6) | PASS (1/1) | PASS (1/1) | PASS | PASS | **PASS** |
| **CH2-S04.02.02-P004** | 781 | PASS (0/0) | PASS (6/6) | PASS (3/3) | PASS (2/2) | PASS | PASS | **PASS** |
| **CH2-S04.02.02-P006** | 800 | PASS (1/1) | PASS (5/5) | PASS (0/0) | PASS (1/1) | PASS | PASS | **PASS** |

---

## 2. Invariant Multiset Comparison Details

### Citation Keys
- `CH2-S04.02-P001`: `{'Shaikh2016': 1}` in both baseline and candidate. Exact multiset and linear position identity.
- `CH2-S04.02.02-P006`: `{'NievasPiketty2025': 1}` in both baseline and candidate. Exact multiset and linear position identity.
- All other target paragraphs contain zero citations in baseline and zero citations in candidate.

### Numeric Literals & Historical Dates
- `CH2-S04.02-P001`: `1931`, `2024`, `1940`, `2010`, `4.3` preserved.
- `CH2-S04.02.01-P001`: `94`, `1931`, `2024` preserved.
- `CH2-S04.02.01-P002`: `94`, `1980` (early 1980s) preserved.
- `CH2-S04.02.01-P003`: `1944`, `1966`, `1950`, `1970`, `2000`, `1`, `1` preserved.
- `CH2-S04.02.01-P004`: `-0.637`, `0.278`, `-1.15`, `1990` (late 1990s), `-0.313`, `2000` preserved.
- `CH2-S04.02.01-P005`: `5.9%`, `3.9%`, `0.051`, `0.045`, `1950` (pre-1950), `1946`, `1974`, `1950` (after 1950), `1960` (mid-1960s) preserved.
- `CH2-S04.02.02-P001`: `1940`, `2010`, `3.3` preserved.
- `CH2-S04.02.02-P002`: `2003`, `1940`, `2010`, `1973`, `1990` preserved.
- `CH2-S04.02.02-P003`: `1940`, `1955`, `1972`, `1975`, `1982`, `1990` (1990s) preserved.
- `CH2-S04.02.02-P004`: `-1.106`, `0.211`, `1940` (late 1940s), `1972`, `1981`, `1980` (late 1980s) preserved.
- `CH2-S04.02.02-P006`: `1975`, `1970` (1970s), `1980` (1980s), `2000` (mid-2000s), `4.5` preserved.

### Inline Math Expressions
- `CH2-S04.02.01-P002`: `$y_t$`, `$k_t^{cap} = \ln(K_t^{\text{ME}} + K_t^{\text{NRC}})$` preserved.
- `CH2-S04.02.01-P003`: `$y_t - k_t^{cap}$`, `$\theta < 1$`, `$\theta = 1$` preserved.
- `CH2-S04.02.01-P004`: `$\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$`, `$\approx -1.15$`, `$\approx -0.313$`, `$\kappa_t$`, `$\theta$` preserved.
- `CH2-S04.02.02-P002`: `$y_t$`, `$k_t^{cap} = \ln(K_t^{\text{ME}} + K_t^{\text{NRC}})$` preserved.
- `CH2-S04.02.02-P003`: `$y_t - k_t^{cap}$` preserved.
- `CH2-S04.02.02-P004`: `$\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$`, `$\theta$`, `$\kappa_t$` preserved.

### Cross-References (Figures and Tables)
- `CH2-S04.02.01-P001`: `tab:us_stylized_facts_summary` preserved.
- `CH2-S04.02.01-P002`: `fig:us_stylized_1_y_kcap` preserved.
- `CH2-S04.02.01-P003`: `fig:us_stylized_2_yk_ratio` preserved.
- `CH2-S04.02.01-P004`: `fig:us_stylized_2b_kappa`, `tab:us_stylized_facts_summary` preserved in exact linear order.
- `CH2-S04.02.01-P005`: `fig:us_stylized_3_growth_rates`, `tab:us_stylized_facts_summary` preserved in exact linear order.
- `CH2-S04.02.02-P001`: `tab:cl_stylized_facts_summary` preserved.
- `CH2-S04.02.02-P002`: `fig:cl_stylized_1a_y_kcap` preserved.
- `CH2-S04.02.02-P003`: `fig:cl_stylized_1b_yk_ratio` preserved.
- `CH2-S04.02.02-P004`: `fig:cl_stylized_2_kappa_mechanization`, `tab:cl_stylized_facts_summary` preserved in exact linear order.
- `CH2-S04.02.02-P006`: `fig:cl_stylized_4_minipages` preserved.

---

## 3. Substantive Invariant Verification

- **CH2-S04.02-P001 (Section 4.2 Overview):**
  - *Country samples:* United States (1931--2024) and Chile (1940--2010) explicitly maintained.
  - *Measurement definitions:* Non Financial Corporate Sector output; gross capital stock from GPIM (\citet{Shaikh2016}) strictly preserved.
  - *Long-run co-movement:* Drift together motivating cointegration retained.
  - *U.S. ratio and accumulation:* Declining long-run trend and faster capital accumulation than output strictly preserved.
  - *Tentative language:* "suggesting that their long-run relation might be governed by a transformation elasticity below unity" preserved verbatim.
  - *Chile relation & composition:* "in Chile, the relation is unclear" preserved verbatim; discrete regime shifts between non-residential construction and machinery and equipment motivating heterogeneous capital preserved.
  - *State dependence:* Distributive state in both economies and external bottleneck components in Chile shifting discretely across institutional regimes, motivating state-dependent and threshold cointegration empirical strategies in Section 4.3 preserved.

- **CH2-S04.02.01-P001 (U.S. Stylized Facts Introduction):**
  - *Scope:* U.S. non-financial corporate economy over the 94-year sample period from 1931 to 2024 preserved.
  - *Variables:* Real output, capital accumulation, functional income distribution, evolving composition of the capital stock preserved.
  - *Moments vs. regime shifts:* Persistent divergence between capital and output growth and shifting wage share dynamics contrasted with secular trends, cyclical fluctuations, and structural breaks that motivate the econometric specifications preserved.

- **CH2-S04.02.01-P002 (U.S. Output and Core Capital Stock):**
  - *Definitions & Trajectory:* Log levels $y_t$ and $k_t^{cap} = \ln(K_t^{\text{ME}} + K_t^{\text{NRC}})$ drifting together over the 94-year sample along a common upward trend preserved.
  - *Overaccumulation gap:* Capital stock running systematically above output from early 1980s onward preserved.
  - *First-difference argument:* Information loss from estimating in first differences preserved verbatim.

- **CH2-S04.02.01-P003 (U.S. Output-Capital Ratio):**
  - *Chronology:* Wartime mobilization peak (1944), Cold War decline, Fordist hump (1966), secular decline thereafter preserved.
  - *LOESS drift:* Downward drift from 1950 onward, steepening after 1970 and 2000 preserved.
  - *Tentative inference:* "provides an empirical suggestion of an over-accumulation tendency $\theta < 1$: capacity formation persistently lags capital accumulation" preserved verbatim.
  - *Knife-edge claim:* $\theta = 1$ not rendering as a long-run tendency once capital stock measurement and dual valuation are considered preserved.

- **CH2-S04.02.01-P004 (U.S. Mechanization Gap $\kappa_t$):**
  - *Moments & Historical trajectory:* Mean $-0.637$, SD $0.278$; Great Depression/WWII depression ($\approx -1.15$); Atlantic Fordist march; late 1990s IT peak ($\approx -0.313$); post-2000 structures and commercial real estate shift; IPP intangible absorption preserved.
  - *Model link:* Heterogeneous-capital specification where $\theta$ depends dynamically on $\kappa_t$ strictly preserved.

- **CH2-S04.02.01-P005 (U.S. Growth Rates & Durability):**
  - *Full-sample growth rates:* Capital (5.9%) vs output (3.9%) per year; standard deviations (0.051 vs 0.045); 1946 and 1974 spikes preserved.
  - *Overaccumulation closure:* Unbalanced growth closure preserved.
  - *Post-1950 asymmetry & durability:* Negative output growth in recessions vs positive capital accumulation reflecting durability of physical capital in operation captured by gross measurements preserved.

- **CH2-S04.02.02-P001 (Chile Stylized Facts Introduction):**
  - *Sample & variables:* 1940--2010 sample; real output, capital accumulation, income distribution, balance of payments preserved.
  - *Regime shifts & framework link:* Structural breaks, distributive fractures, and external constraint variables motivating Section 3.3 analytical framework and threshold empirical strategy preserved.

- **CH2-S04.02.02-P002 (Chile GDP and Core Capital Stock):**
  - *Definitions & price basis:* Real GDP ($y_t$), gross core capital stock ($k_t^{cap}$), 2003 CLP price basis preserved.
  - *Trajectory & dates:* Seven decades of co-movement; 1973 military coup; 1990 post-dictatorship period preserved.

- **CH2-S04.02.02-P003 (Chile Output-Capital Ratio):**
  - *Center vs periphery contrast:* Continuous secular decline in the center contrasted with peripheral regime shifts preserved.
  - *Historical phases:* State-led ISI (1940--1955), 1972--1975 breakdown, 1982 debt crisis, 1990s commodity boom unconstrained expansion preserved.

- **CH2-S04.02.02-P004 (Chile Mechanization Gap $\kappa_t$):**
  - *Moments & Trajectory:* Mean $-1.106$, SD $0.211$; late 1940s to 1972 ISI rise; early neoliberal stagnation with 1981 hump; late 1980s trough; post-1990 mining-led accumulation preserved.
  - *Model link:* Heterogeneous-capital specification in which $\theta$ depends on $\kappa_t$ strictly preserved.

- **CH2-S04.02.02-P006 (Chile External Bottleneck Components):**
  - *Four components:* (Panel a) Central Bank solvency ratio ($S_t$), reserves relative to base money; (Panel b) terms of trade ($\ln \text{ToT}_t$); (Panel c) real exports ($\ln X_t$); (Panel d) machinery investment ($\ln I_t^{\text{ME}}$) preserved.
  - *Causal mechanism:* Binding episodes driven by reserve solvency and import demand rather than export failure; Nievas-Piketty WBOP attribution; grid-search assembly into composite index and threshold estimation in Section 4.5 preserved.
  - *Agreed verb agreement:* "becomes binding and counteracts the mechanization bias productivity gain" preserved.

---

## 4. Whole-File and Scope Verification

- **Baseline SHA-256:** `2E97B366A5D6DACDFEF8A7AE0BBB8D5B42668C1218BE928FDED1DC1F28C80353`
- **Active `section4.tex` SHA-256:** `2E97B366A5D6DACDFEF8A7AE0BBB8D5B42668C1218BE928FDED1DC1F28C80353` (byte-for-byte identical; active manuscript was NOT modified).
- **Lines 1--684 of `section4.tex`:** Byte-for-byte identical.
- **Lines 814--1744 of `section4.tex`:** Byte-for-byte identical.
- **Protected KEEP units verified byte-for-byte identical:**
  - `CH2-S04.02.01-P006` (wage share permutations): Byte-for-byte identical.
  - `CH2-S04.02.01-P007` (effective wage pressure): Byte-for-byte identical.
  - `CH2-S04.02.02-P005` (Chile wage share trajectories): Byte-for-byte identical.
- **Scope containment:** 100% contained within authorized Section 4.2 units. Zero unauthorized edits.
