# U.S. Output, Productive Capital, and Distribution:
## Descriptive Statistics across Historical Windows

**Chapter 2 Narrow Regression-Facing Descriptive Report**  
**Date:** 24 June 2026  
**Country:** United States  
**Chapter:** Dissertation Chapter 2  
**Stage:** S31B  
**Scope:** Descriptive statistics only  
**Dataset boundary:** Frozen source-of-truth v1, read only

## 1. Purpose and descriptive question

This report documents the historical behavior of real NFC output, aggregate productive capital, capital composition, and four admissible wage-share measures before regression specification. It asks how these observed series differ across the locked structural, nested, transition, and event-profile windows. It performs neither model selection nor econometric estimation.

The paper-facing variable set is

$$
\left\{Y_t^{NFC},K_t^{P},\kappa_t^{ME/NRC},\omega_t^{C,GVA},
\omega_t^{C,NVA},\omega_t^{NFC,GVA},\omega_t^{NFC,NVA}\right\}.
$$

## 2. Variable menu and notation

**Table 1. Narrow variable menu and notation**

| Economic family | Paper-facing label | Notation | Repository ID | Accounting boundary | Role in later regressions |
| --- | --- | --- | --- | --- | --- |
| Output | Real gross value added of nonfinancial corporate business | $Y_t^{NFC}$ | Y_REAL_NFC_GVA_BASELINE | NFC; gross value added | Output candidate |
| Productive capital | Aggregate gross productive-capital stock | $K_t^{P}$ | G_TOT_GPIM_2017 | NFC productive-capital aggregate | Capital-scale candidate |
| Capital composition | Machinery-to-nonresidential-structures capital-composition ratio | $\kappa_t^{ME/NRC}$ | KAPPA_ME_NRC | NFC capital-component ratio | Composition candidate |
| Distribution | Corporate compensation share of GVA | $\omega_t^{C,GVA}$ | CORP_COMPENSATION_SHARE_GVA | Corporate; gross value added | Distributive candidate; eligible, not selected |
| Distribution | Corporate compensation share of NVA | $\omega_t^{C,NVA}$ | CORP_COMPENSATION_SHARE_NVA | Corporate; net value added | Distributive candidate; eligible, not selected |
| Distribution | NFC compensation share of GVA | $\omega_t^{NFC,GVA}$ | NFC_COMPENSATION_SHARE_GVA | NFC; gross value added | Distributive candidate; eligible, not selected |
| Distribution | NFC compensation share of NVA | $\omega_t^{NFC,NVA}$ | NFC_COMPENSATION_SHARE_NVA | NFC; net value added | Distributive candidate; eligible, not selected |

The two provenance inputs for $\kappa_t^{ME/NRC}$ are `G_ME_GPIM_2017` and `G_NRC_GPIM_2017`. They are construction inputs, not separate report variables.

## 3. Accounting boundaries and model openness

The strict available accounting correspondence is $Y_t^{NFC}\leftrightarrow\omega_t^{NFC,GVA}$ because both objects use the NFC sector boundary and gross value added. The NFC NVA share is a same-sector net-account alternative. The two corporate shares use the broader corporate boundary.

Accounting correspondence does not bind the later model mapping. Cross-boundary model specifications are theoretical choices, not accounting identities. All four wage shares remain eligible and unselected at S31B.

**Table 6. Accounting correspondence and regression-candidate status**

| variable_id | sector_boundary | gross_or_net_denominator | strict_output_correspondence | later_regression_eligibility | selection_status |
| --- | --- | --- | --- | --- | --- |
| Y_REAL_NFC_GVA_BASELINE | NFC | Gross value added | Output object | eligible | documented; not selected at S31B |
| G_TOT_GPIM_2017 | NFC productive capital | Not applicable | No | eligible | documented; not selected at S31B |
| KAPPA_ME_NRC | NFC component ratio | Not applicable | No | eligible | documented; not selected at S31B |
| CORP_COMPENSATION_SHARE_GVA | Corporate | GVA | No | eligible | documented; not selected at S31B |
| CORP_COMPENSATION_SHARE_NVA | Corporate | NVA | No | eligible | documented; not selected at S31B |
| NFC_COMPENSATION_SHARE_GVA | NFC | GVA | Yes: Y_REAL_NFC_GVA_BASELINE | eligible | documented; not selected at S31B |
| NFC_COMPENSATION_SHARE_NVA | NFC | NVA | No: same-sector net alternative | eligible | documented; not selected at S31B |

## 4. Historical-window architecture

Structural and nested windows support historical comparison. Bridge windows connect adjacent configurations. Transition and event-profile windows are descriptive only: they are neither testing nor estimation samples. Event profiles are displayed year by year and are not treated as independent statistical regimes.

**Table 7. Historical-window registry**

| window_id | window_type | start_year | end_year | descriptive_eligible | testing_eligible | estimation_eligible |
| --- | --- | --- | --- | --- | --- | --- |
| global_available | global | -- | -- | yes | not_decided | not_decided |
| pre_1974 | structural | -- | 1973 | yes | not_decided | not_decided |
| post_1974 | structural | 1974 | 2025 | yes | not_decided | not_decided |
| pre_fordist | nested | -- | 1946 | yes | not_decided | not_decided |
| fordist_core_1947_1973 | nested | 1947 | 1973 | yes | not_decided | not_decided |
| extended_fordist_bridge_1940_1978 | bridge | 1940 | 1978 | yes | not_decided | not_decided |
| post_fordist_pre_gfc_1974_2008 | structural | 1974 | 2008 | yes | not_decided | not_decided |
| mature_post_volcker_pre_gfc_1983_2008 | nested | 1983 | 2008 | yes | not_decided | not_decided |
| post_gfc_2009_2025 | structural | 2009 | 2025 | yes | not_decided | not_decided |
| post_gfc_pre_covid_2009_2019 | nested | 2009 | 2019 | yes | not_decided | not_decided |
| post_covid_configuration_2022_2025 | nested | 2022 | 2025 | yes | not_decided | not_decided |
| fordist_aftermath_1974_1978 | transition | 1974 | 1978 | yes | no | no |
| volcker_transition_1979_1982 | transition | 1979 | 1982 | yes | no | no |
| gfc_transition_2008_2009 | transition | 2008 | 2009 | yes | no | no |
| covid_transition_2020_2021 | transition | 2020 | 2021 | yes | no | no |
| volcker_event_profile_1978_1983 | event profile | 1978 | 1983 | yes | no | no |
| gfc_event_profile_2007_2010 | event profile | 2007 | 2010 | yes | no | no |
| covid_event_profile_2019_2022 | event profile | 2019 | 2022 | yes | no | no |

## 5. NFC real output

<!-- CLAIM:C01 CLAIM:C02 CLAIM:C03 -->
During the Fordist core, $Y_t^{NFC}$ rose from 703,904 to 2,529,343 million 2017-price-equivalent dollars, while mean annual proportional growth was 5.19%.

<!-- CLAIM:C04 CLAIM:C05 -->
Mean annual output growth was 3.52% in the post-Fordist pre-GFC window and 2.31% after the GFC. The comparison records a lower post-GFC growth profile without assigning causality or estimating a break.

<!-- CLAIM:C06 -->
The event profile records annual proportional output change of -4.10% in 2020. This observation is a realized annual movement, not an estimated shock coefficient.

![Figure 1. Real NFC output level](figures/figure_01_nfc_output_level.png)

*Figure 1 note.* Historical markers are reference dates, not estimated breakpoints. Values are descriptive and do not identify a statistical regime.

![Figure 2. Annual NFC output growth](figures/figure_02_nfc_output_growth.png)

*Figure 2 note.* Historical markers are reference dates, not estimated breakpoints. Values are descriptive and do not identify a statistical regime.

## 6. Productive-capital scale

<!-- CLAIM:C07 CLAIM:C08 -->
Mean annual growth of $K_t^P$ was -1.80% during the Fordist core and -0.78% in the post-Fordist pre-GFC window.

<!-- CLAIM:C09 CLAIM:C10 -->
The post-GFC mean annual capital-growth rate was -1.67%, while the 2020 event-profile observation was -1.99%. The aggregate remains a constructed GPIM measure over heterogeneous assets.

![Figure 3. Aggregate productive-capital level](figures/figure_03_productive_capital_level.png)

*Figure 3 note.* Historical markers are reference dates, not estimated breakpoints. Values are descriptive and do not identify a statistical regime.

![Figure 4. Annual aggregate-capital growth](figures/figure_04_productive_capital_growth.png)

*Figure 4 note.* Historical markers are reference dates, not estimated breakpoints. Values are descriptive and do not identify a statistical regime.

## 7. Productive-capital composition

$$
\kappa_t^{ME/NRC}=\frac{K_t^{ME}}{K_t^{NRC}}
=\frac{\texttt{G\_ME\_GPIM\_2017}_t}{\texttt{G\_NRC\_GPIM\_2017}_t}.
$$

The component stocks are heterogeneous. The ratio is therefore used as a directional composition indicator, not as a machinery share, a structures share, or evidence that $K_t^P$ is a simple physical sum.

<!-- CLAIM:C11 CLAIM:C12 -->
Across the Fordist core, $\kappa_t^{ME/NRC}$ moved from 0.165 to 0.338, indicating a movement toward relatively greater machinery-and-equipment intensity over that interval.

<!-- CLAIM:C13 CLAIM:C14 -->
Its initial-to-terminal absolute change was 0.198 in the post-Fordist pre-GFC window and 0.230 after the GFC. These ratio movements are not component shares of total productive capital.

![Figure 5. Machinery-to-structures composition ratio](figures/figure_05_kappa_me_nrc.png)

*Figure 5 note.* Historical markers are reference dates, not estimated breakpoints. Values are descriptive and do not identify a statistical regime.

## 8. Wage-share alternatives

The four compensation shares separate two choices: corporate versus NFC sector boundary, and gross versus net value-added denominator. Levels are reported in percent and annual changes in percentage points. No share is ranked as econometrically superior.

<!-- CLAIM:C15 CLAIM:C16 -->
During the Fordist core, the corporate GVA compensation share changed by -0.28 pp, while the NFC GVA compensation share changed by -0.05 pp.

<!-- CLAIM:C17 CLAIM:C18 -->
After the GFC, the corporate NVA compensation share changed by -4.98 pp from the first to the last available observation, compared with -3.72 pp for the NFC NVA share.

![Figure 6. Corporate GVA and NVA wage shares](figures/figure_06_corporate_gva_nva_wage_shares.png)

*Figure 6 note.* Historical markers are reference dates, not estimated breakpoints. Values are descriptive and do not identify a statistical regime.

![Figure 7. NFC GVA and NVA wage shares](figures/figure_07_nfc_gva_nva_wage_shares.png)

*Figure 7 note.* Historical markers are reference dates, not estimated breakpoints. Values are descriptive and do not identify a statistical regime.

![Figure 8. Corporate versus NFC GVA wage shares](figures/figure_08_corporate_nfc_gva_wage_shares.png)

*Figure 8 note.* Historical markers are reference dates, not estimated breakpoints. Values are descriptive and do not identify a statistical regime.

![Figure 9. Corporate versus NFC NVA wage shares](figures/figure_09_corporate_nfc_nva_wage_shares.png)

*Figure 9 note.* Historical markers are reference dates, not estimated breakpoints. Values are descriptive and do not identify a statistical regime.

## 9. Event profiles

### 9.1 Volcker, 1978-1983

<!-- CLAIM:C19 CLAIM:C20 -->
In 1982, annual NFC output growth was -0.91% and the annual absolute change in $\kappa_t^{ME/NRC}$ was -0.003. The complete panel below retains every annual observation for all seven variables.

![Figure 10. Volcker event profile, 1978-1983](figures/figure_10_volcker_event_profile_1978_1983.png)

*Figure 10 note.* The dashed line marks 1979 as a historical reference onset; panels retain observed scales.

### 9.2 GFC, 2007-2010

<!-- CLAIM:C21 CLAIM:C22 -->
In 2009, annual NFC output growth was -7.08% and the NFC GVA compensation share changed by -0.25 pp. These are concurrent descriptive movements.

![Figure 11. GFC event profile, 2007-2010](figures/figure_11_gfc_event_profile_2007_2010.png)

*Figure 11 note.* The dashed line marks 2008 as a historical reference onset; panels retain observed scales.

### 9.3 COVID, 2019-2022

<!-- CLAIM:C23 CLAIM:C24 -->
Annual NFC output growth was 9.68% in 2021, while the NFC GVA compensation share changed by 1.74 pp in 2020. The short profile does not establish a separate regime.

![Figure 12. COVID event profile, 2019-2022](figures/figure_12_covid_event_profile_2019_2022.png)

*Figure 12 note.* The dashed line marks 2020 as a historical reference onset; panels retain observed scales.

**Table 5. Event-profile annual observations**

| Event | Year | Y_NFC | K_P | kappa_ME_NRC | omega_C_GVA | omega_C_NVA | omega_NFC_GVA | omega_NFC_NVA |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| volcker_event_profile_1978_1983 | 1978 | 3,038,745 | 33,045,743 | 0.361 | 62.88 | 70.91 | 63.62 | 71.89 |
| volcker_event_profile_1978_1983 | 1979 | 3,118,975 | 32,992,479 | 0.368 | 64.21 | 72.73 | 64.98 | 73.75 |
| volcker_event_profile_1978_1983 | 1980 | 3,140,096 | 32,879,118 | 0.368 | 64.73 | 73.95 | 65.46 | 74.92 |
| volcker_event_profile_1978_1983 | 1981 | 3,283,888 | 32,798,011 | 0.366 | 63.07 | 72.21 | 63.71 | 73.07 |
| volcker_event_profile_1978_1983 | 1982 | 3,253,862 | 32,579,850 | 0.363 | 63.17 | 73.03 | 63.79 | 73.91 |
| volcker_event_profile_1978_1983 | 1983 | 3,415,215 | 32,196,062 | 0.362 | 62.28 | 71.72 | 62.95 | 72.63 |
| gfc_event_profile_2007_2010 | 2007 | 8,463,493 | 25,468,261 | 0.528 | 59.69 | 69.81 | 59.35 | 69.36 |
| gfc_event_profile_2007_2010 | 2008 | 8,373,691 | 25,313,160 | 0.540 | 60.93 | 72.10 | 59.56 | 70.18 |
| gfc_event_profile_2007_2010 | 2009 | 7,780,498 | 24,796,842 | 0.544 | 58.94 | 70.30 | 59.31 | 70.73 |
| gfc_event_profile_2007_2010 | 2010 | 8,118,731 | 24,236,708 | 0.555 | 57.07 | 67.48 | 57.18 | 67.60 |
| covid_event_profile_2019_2022 | 2019 | 10,406,488 | 21,152,933 | 0.715 | 57.64 | 68.08 | 58.74 | 69.45 |
| covid_event_profile_2019_2022 | 2020 | 9,979,518 | 20,731,782 | 0.725 | 59.26 | 70.78 | 60.48 | 72.40 |
| covid_event_profile_2019_2022 | 2021 | 10,945,065 | 20,233,341 | 0.739 | 57.05 | 67.10 | 57.97 | 68.23 |
| covid_event_profile_2019_2022 | 2022 | 11,350,816 | 19,808,110 | 0.750 | 55.50 | 65.24 | 56.48 | 66.41 |

## 10. Regression-facing implications

The later candidate menu remains exactly the seven-variable set stated in Section 1. The descriptive evidence documents scale, growth, composition, sector boundary, and denominator differences before specification selection. It does not authorize a regression equation, select a distributive measure, or map an accounting correspondence mechanically into a model.

**Table 2. Full-sample descriptive summary**

| Variable | Coverage | N | Initial | Terminal | Mean | SD | Initial-terminal change | Mean annual change |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Y_NFC | 1929-2025 | 97 | 379,518 | 12,229,586 | 4,089,211 | 3,544,035 | 3,122.40% | 3.83% |
| K_P | 1901-2024 | 124 | 1,723,395 | 19,322,143 | 39,121,139 | 20,561,787 | 1,021.17% | 2.61% |
| kappa_ME_NRC | 1901-2024 | 124 | 0.310 | 0.774 | 0.364 | 0.143 | 0.464 | 0.004 |
| omega_C_GVA | 1929-2025 | 97 | 62.48 | 55.31 | 61.93 | 2.79 | -7.17 pp | -0.07 pp |
| omega_C_NVA | 1929-2025 | 97 | 69.07 | 65.32 | 70.21 | 2.96 | -3.74 pp | -0.04 pp |
| omega_NFC_GVA | 1929-2025 | 97 | 63.25 | 56.65 | 62.22 | 2.63 | -6.60 pp | -0.07 pp |
| omega_NFC_NVA | 1929-2025 | 97 | 70.18 | 67.01 | 70.61 | 2.87 | -3.16 pp | -0.03 pp |

*Table 2 note.* Output and capital levels are millions of constant-price dollars; their changes are percentages. Wage-share levels are percentages and their changes are percentage points. Kappa is an observed ratio and its changes are ratio points.

**Table 3. Structural-window comparison**

| Variable | Window | N | Initial | Terminal | Mean | Change | Mean annual change | Volatility |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Y_NFC | fordist_core_1947_1973 | 27 | 703,904 | 2,529,343 | 1,440,431 | 259.33% | 5.19% | 4.06% |
| K_P | fordist_core_1947_1973 | 27 | 53,963,272 | 33,362,367 | 39,405,636 | -38.18% | -1.80% | 1.97% |
| kappa_ME_NRC | fordist_core_1947_1973 | 27 | 0.165 | 0.338 | 0.265 | 0.173 | 0.007 | 0.005 |
| omega_C_GVA | fordist_core_1947_1973 | 27 | 64.42 | 64.14 | 63.02 | -0.28 pp | -0.07 pp | 0.99 pp |
| omega_C_NVA | fordist_core_1947_1973 | 27 | 69.78 | 71.26 | 69.30 | 1.48 pp | -0.01 pp | 1.23 pp |
| omega_NFC_GVA | fordist_core_1947_1973 | 27 | 64.45 | 64.40 | 63.19 | -0.05 pp | -0.07 pp | 1.06 pp |
| omega_NFC_NVA | fordist_core_1947_1973 | 27 | 69.87 | 71.69 | 69.63 | 1.82 pp | -0.01 pp | 1.33 pp |
| Y_NFC | post_fordist_pre_gfc_1974_2008 | 35 | 2,491,175 | 8,373,691 | 5,182,438 | 236.13% | 3.52% | 2.99% |
| K_P | post_fordist_pre_gfc_1974_2008 | 35 | 33,562,536 | 25,313,160 | 29,589,639 | -24.58% | -0.78% | 0.53% |
| kappa_ME_NRC | post_fordist_pre_gfc_1974_2008 | 35 | 0.342 | 0.540 | 0.391 | 0.198 | 0.006 | 0.007 |
| omega_C_GVA | post_fordist_pre_gfc_1974_2008 | 35 | 64.90 | 60.93 | 62.82 | -3.97 pp | -0.09 pp | 0.95 pp |
| omega_C_NVA | post_fordist_pre_gfc_1974_2008 | 35 | 72.75 | 72.10 | 72.25 | -0.65 pp | 0.02 pp | 1.25 pp |
| omega_NFC_GVA | post_fordist_pre_gfc_1974_2008 | 35 | 65.41 | 59.56 | 63.16 | -5.85 pp | -0.14 pp | 0.94 pp |
| omega_NFC_NVA | post_fordist_pre_gfc_1974_2008 | 35 | 73.50 | 70.18 | 72.60 | -3.33 pp | -0.04 pp | 1.20 pp |
| Y_NFC | mature_post_volcker_pre_gfc_1983_2008 | 26 | 3,415,215 | 8,373,691 | 5,964,983 | 145.19% | 3.74% | 2.66% |
| K_P | mature_post_volcker_pre_gfc_1983_2008 | 26 | 32,196,062 | 25,313,160 | 28,379,246 | -21.38% | -0.97% | 0.44% |
| kappa_ME_NRC | mature_post_volcker_pre_gfc_1983_2008 | 26 | 0.362 | 0.540 | 0.403 | 0.178 | 0.007 | 0.008 |
| omega_C_GVA | mature_post_volcker_pre_gfc_1983_2008 | 26 | 62.28 | 60.93 | 62.59 | -1.35 pp | -0.09 pp | 0.93 pp |
| omega_C_NVA | mature_post_volcker_pre_gfc_1983_2008 | 26 | 71.72 | 72.10 | 72.31 | 0.38 pp | -0.04 pp | 1.27 pp |
| omega_NFC_GVA | mature_post_volcker_pre_gfc_1983_2008 | 26 | 62.95 | 59.56 | 62.86 | -3.39 pp | -0.16 pp | 0.88 pp |
| omega_NFC_NVA | mature_post_volcker_pre_gfc_1983_2008 | 26 | 72.63 | 70.18 | 72.51 | -2.45 pp | -0.14 pp | 1.16 pp |
| Y_NFC | post_gfc_2009_2025 | 17 | 7,780,498 | 12,229,586 | 9,888,212 | 57.18% | 2.31% | 3.54% |
| K_P | post_gfc_2009_2025 | 16 | 24,796,842 | 19,322,143 | 21,843,476 | -22.08% | -1.67% | 0.46% |
| kappa_ME_NRC | post_gfc_2009_2025 | 16 | 0.544 | 0.774 | 0.662 | 0.230 | 0.015 | 0.005 |
| omega_C_GVA | post_gfc_2009_2025 | 17 | 58.94 | 55.31 | 56.92 | -3.63 pp | -0.33 pp | 1.04 pp |
| omega_C_NVA | post_gfc_2009_2025 | 17 | 70.30 | 65.32 | 67.24 | -4.98 pp | -0.40 pp | 1.50 pp |
| omega_NFC_GVA | post_gfc_2009_2025 | 17 | 59.31 | 56.65 | 57.69 | -2.67 pp | -0.17 pp | 1.04 pp |
| omega_NFC_NVA | post_gfc_2009_2025 | 17 | 70.73 | 67.01 | 68.20 | -3.72 pp | -0.19 pp | 1.61 pp |
| Y_NFC | post_gfc_pre_covid_2009_2019 | 11 | 7,780,498 | 10,406,488 | 9,107,280 | 33.75% | 2.04% | 3.18% |
| K_P | post_gfc_pre_covid_2009_2019 | 11 | 24,796,842 | 21,152,933 | 22,715,988 | -14.70% | -1.62% | 0.44% |
| kappa_ME_NRC | post_gfc_pre_covid_2009_2019 | 11 | 0.544 | 0.715 | 0.623 | 0.171 | 0.016 | 0.005 |
| omega_C_GVA | post_gfc_pre_covid_2009_2019 | 11 | 58.94 | 57.64 | 57.21 | -1.30 pp | -0.30 pp | 0.90 pp |
| omega_C_NVA | post_gfc_pre_covid_2009_2019 | 11 | 70.30 | 68.08 | 67.59 | -2.22 pp | -0.37 pp | 1.13 pp |
| omega_NFC_GVA | post_gfc_pre_covid_2009_2019 | 11 | 59.31 | 58.74 | 57.78 | -0.57 pp | -0.07 pp | 0.77 pp |
| omega_NFC_NVA | post_gfc_pre_covid_2009_2019 | 11 | 70.73 | 69.45 | 68.31 | -1.28 pp | -0.07 pp | 1.11 pp |
| Y_NFC | post_covid_configuration_2022_2025 | 4 | 11,350,816 | 12,229,586 | 11,748,735 | 7.74% | 2.82% | 0.82% |
| K_P | post_covid_configuration_2022_2025 | 3 | 19,808,110 | 19,322,143 | 19,551,539 | -2.45% | -1.52% | 0.54% |
| kappa_ME_NRC | post_covid_configuration_2022_2025 | 3 | 0.750 | 0.774 | 0.761 | 0.024 | 0.012 | 0.004 |
| omega_C_GVA | post_covid_configuration_2022_2025 | 4 | 55.50 | 55.31 | 55.51 | -0.19 pp | -0.44 pp | 0.77 pp |
| omega_C_NVA | post_covid_configuration_2022_2025 | 4 | 65.24 | 65.32 | 65.44 | 0.08 pp | -0.44 pp | 0.98 pp |
| omega_NFC_GVA | post_covid_configuration_2022_2025 | 4 | 56.48 | 56.65 | 56.66 | 0.17 pp | -0.33 pp | 0.81 pp |
| omega_NFC_NVA | post_covid_configuration_2022_2025 | 4 | 66.41 | 67.01 | 66.84 | 0.61 pp | -0.30 pp | 1.05 pp |

*Table 3 note.* The paper-facing table prioritizes six windows. The complete eleven-window machine-readable table is `tables/supplement_complete_11_window_statistics.csv`.

**Table 4. Transition-window statistics**

| Variable | Window | N | Initial | Terminal | Change | Mean annual change | Testing | Estimation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Y_NFC | fordist_aftermath_1974_1978 | 5 | 2,491,175 | 3,038,745 | 21.98% | 3.83% | no | no |
| K_P | fordist_aftermath_1974_1978 | 5 | 33,562,536 | 33,045,743 | -1.54% | -0.19% | no | no |
| kappa_ME_NRC | fordist_aftermath_1974_1978 | 5 | 0.342 | 0.361 | 0.019 | 0.005 | no | no |
| omega_C_GVA | fordist_aftermath_1974_1978 | 5 | 64.90 | 62.88 | -2.02 pp | -0.25 pp | no | no |
| omega_C_NVA | fordist_aftermath_1974_1978 | 5 | 72.75 | 70.91 | -1.84 pp | -0.07 pp | no | no |
| omega_NFC_GVA | fordist_aftermath_1974_1978 | 5 | 65.41 | 63.62 | -1.80 pp | -0.16 pp | no | no |
| omega_NFC_NVA | fordist_aftermath_1974_1978 | 5 | 73.50 | 71.89 | -1.61 pp | 0.04 pp | no | no |
| Y_NFC | volcker_transition_1979_1982 | 4 | 3,118,975 | 3,253,862 | 4.32% | 1.75% | no | no |
| K_P | volcker_transition_1979_1982 | 4 | 32,992,479 | 32,579,850 | -1.25% | -0.35% | no | no |
| kappa_ME_NRC | volcker_transition_1979_1982 | 4 | 0.368 | 0.363 | -0.005 | 0.001 | no | no |
| omega_C_GVA | volcker_transition_1979_1982 | 4 | 64.21 | 63.17 | -1.04 pp | 0.07 pp | no | no |
| omega_C_NVA | volcker_transition_1979_1982 | 4 | 72.73 | 73.03 | 0.30 pp | 0.53 pp | no | no |
| omega_NFC_GVA | volcker_transition_1979_1982 | 4 | 64.98 | 63.79 | -1.19 pp | 0.04 pp | no | no |
| omega_NFC_NVA | volcker_transition_1979_1982 | 4 | 73.75 | 73.91 | 0.16 pp | 0.50 pp | no | no |
| Y_NFC | gfc_transition_2008_2009 | 2 | 8,373,691 | 7,780,498 | -7.08% | -4.07% | no | no |
| K_P | gfc_transition_2008_2009 | 2 | 25,313,160 | 24,796,842 | -2.04% | -1.32% | no | no |
| kappa_ME_NRC | gfc_transition_2008_2009 | 2 | 0.540 | 0.544 | 0.004 | 0.008 | no | no |
| omega_C_GVA | gfc_transition_2008_2009 | 2 | 60.93 | 58.94 | -1.99 pp | -0.38 pp | no | no |
| omega_C_NVA | gfc_transition_2008_2009 | 2 | 72.10 | 70.30 | -1.80 pp | 0.24 pp | no | no |
| omega_NFC_GVA | gfc_transition_2008_2009 | 2 | 59.56 | 59.31 | -0.25 pp | -0.02 pp | no | no |
| omega_NFC_NVA | gfc_transition_2008_2009 | 2 | 70.18 | 70.73 | 0.55 pp | 0.69 pp | no | no |
| Y_NFC | covid_transition_2020_2021 | 2 | 9,979,518 | 10,945,065 | 9.68% | 2.79% | no | no |
| K_P | covid_transition_2020_2021 | 2 | 20,731,782 | 20,233,341 | -2.40% | -2.20% | no | no |
| kappa_ME_NRC | covid_transition_2020_2021 | 2 | 0.725 | 0.739 | 0.014 | 0.012 | no | no |
| omega_C_GVA | covid_transition_2020_2021 | 2 | 59.26 | 57.05 | -2.21 pp | -0.29 pp | no | no |
| omega_C_NVA | covid_transition_2020_2021 | 2 | 70.78 | 67.10 | -3.68 pp | -0.49 pp | no | no |
| omega_NFC_GVA | covid_transition_2020_2021 | 2 | 60.48 | 57.97 | -2.51 pp | -0.39 pp | no | no |
| omega_NFC_NVA | covid_transition_2020_2021 | 2 | 72.40 | 68.23 | -4.17 pp | -0.61 pp | no | no |

*Table 4 note.* Every transition row is descriptive eligible, testing ineligible, and estimation ineligible.

## 11. Limitations

Canonical real corporate GVA remains blocked, so corporate-NFC real-output comparisons are unavailable. `G_ME_GPIM_2017` and `G_NRC_GPIM_2017` are used only to construct $\kappa_t^{ME/NRC}$. The ratio indicates relative composition; it is not a physically additive share of total capital. Short transition windows are descriptive only, and the post-COVID configuration contains limited observations.

## 12. Bounded conclusions

The report establishes three bounded results. First, real NFC output and productive capital display different average growth profiles across the locked historical windows. Second, the machinery-to-structures ratio changes materially over time without requiring a physical-additivity claim. Third, sector boundary and gross-versus-net denominator choices produce distinct wage-share paths, leaving all four distributive candidates open for later specification work.

These findings are descriptive. They do not establish causality, statistical significance, estimated structural breaks, cointegration, model superiority, or parameter instability.

## Appendix A. Transformation rules

$$g_{X,t}=100\left(\frac{X_t}{X_{t-1}}-1\right),\qquad X\in\{Y^{NFC},K^P\}.$$

$$\Delta\kappa_t^{ME/NRC}=\kappa_t^{ME/NRC}-\kappa_{t-1}^{ME/NRC}.$$

$$\Delta_{pp}\omega_t^{s,a}=100\left(\omega_t^{s,a}-\omega_{t-1}^{s,a}\right).$$

No logarithmic transformation is reported.

## Appendix B. Reproducibility

The report is generated by `codes/US_S31B_build_narrow_descriptive_report.R` from read-only validated S31B and authorized upstream inputs. Report tables, figures, prose values, parity checks, and compilation logs are stored beside the report.
