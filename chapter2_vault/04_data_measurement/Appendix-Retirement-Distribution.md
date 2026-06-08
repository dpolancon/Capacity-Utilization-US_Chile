---
source: appendix_K_ret_distribution.tex
source_type: latex
status: shell_reconstruction
latex_label: app:ret_distribution
bib: references.bib
---
---
source: appendix_K_ret_distribution.tex
source_type: latex
status: reconstructed_from_current_tex
latex_label: app:ret_distribution
bib: references.bib
---

# Appendix K — Weibull Retirement Distributions: Formalization, Sources, and Parameter Decision

label: app:ret_distribution

## Formalization of the Weibull Retirement Distribution

label: app:ret:formalization

This subsection defines the Weibull retirement distribution and its role in the GPIM gross capital stock recursion. Every object used in subsequent parameter calibration is introduced here.

### Why a Retirement Distribution Is Needed

label: app:ret:why

The GPIM construction of gross capital stock requires an assumption about the retirement rate $\rho(\tau)$ — the fraction of installed capital that physically exits production at age $\tau$. This is conceptually distinct from the depreciation rate $\delta$, which governs value attrition in the net stock. A machine that depreciates to zero accounting value may still operate at full productive capacity until it is retired. The gross stock tracks installed physical capacity; it falls only when assets are removed from service.

The retirement rate is not directly observed. BEA reports net stocks and investment flows; everything else is derived. Three families of assumptions have been used in the literature:

1. **Simultaneous exit (SE):** All assets retire exactly at age $T$. Widely recognized as the most unrealistic assumption [@Blades2001; @Nomura2005].
2. **Geometric (infinite lives):** Assets depreciate at a constant rate $\delta$ indefinitely. Adopted by BEA post-1997 [@Fraumeni1997]. Eliminates the retirement question but makes gross stock computation impossible — infinitely lived assets never exit.
3. **Bell-shaped distributions:** Retirements are distributed around the mean service life $\bar{T}$ with a dispersion governed by a shape parameter. Winfrey tabulated empirical Iowa curves; Weibull and log-normal distributions are parametric alternatives. Used by BEA pre-1997 and by Shaikh via ADJ1 [@Winfrey1967; @Shaikh2016].

This appendix adopts the Weibull distribution — a flexible two-parameter family that nests the exponential ($\alpha = 1$) and approximates the Winfrey S-3 bell-shaped curve for $\alpha \in [1.5,\, 3.5]$.

<!-- FLAG: latex_crosswalk | original=\citep{Blades2001, Nomura2005} -->
<!-- FLAG: latex_crosswalk | original=\citep{Fraumeni1997} -->
<!-- FLAG: latex_crosswalk | original=\citet{Winfrey1967} -->
<!-- FLAG: latex_crosswalk | original=\citet[Appendix~6.7]{Shaikh2016} -->

### The Weibull Distribution

label: app:ret:weibull_def

Let $\tau$ denote the age of an asset cohort. The Weibull distribution is parameterized by a shape parameter $\alpha > 0$ (governing the hazard profile) and a scale parameter $\lambda > 0$ (governing the spread).

The probability density function (mortality function) is:

$$
f(\tau) = \frac{\alpha}{\lambda}
\left(\frac{\tau}{\lambda}\right)^{\alpha - 1}
\exp\!\left[-\left(\frac{\tau}{\lambda}\right)^{\!\alpha}\right]
$$

label: eq:ret:pdf

This gives the fraction of a cohort retiring at exact age $\tau$.

The cumulative distribution function is:

$$
F(\tau) = 1 - \exp\!\left[-\left(\frac{\tau}{\lambda}\right)^{\!\alpha}\right]
$$

label: eq:ret:cdf

The survival function — the fraction of the cohort still in service at age $\tau$ — is:

$$
S(\tau) = \exp\!\left[-\left(\frac{\tau}{\lambda}\right)^{\!\alpha}\right]
$$

label: eq:ret:survival

The hazard function gives the instantaneous retirement rate at age $\tau$, conditional on survival to $\tau$:

$$
h(\tau) = \frac{f(\tau)}{S(\tau)}
= \frac{\alpha}{\lambda}
\left(\frac{\tau}{\lambda}\right)^{\alpha - 1}
$$

label: eq:ret:hazard

For $\alpha > 1$, the hazard is increasing in age: older assets face higher retirement risk. For $\alpha < 2.6$, the increase is regressive — retirement risk rises but at a decreasing rate, producing a right-skewed mortality distribution. This is the empirically relevant range for physical capital.

The mean service life is:

$$
\bar{T} = \lambda \cdot \Gamma\!\left(1 + \alpha^{-1}\right)
$$

label: eq:ret:mean_life

where $\Gamma(\cdot)$ is the gamma function. Given a target mean service life $L$ and a shape parameter $\alpha$, the scale parameter is recovered as:

$$
\lambda = \frac{L}{\Gamma(1 + \alpha^{-1})}
$$

label: eq:ret:lambda_from_L

This is the operational formula used in the pipeline: $L$ and $\alpha$ are the inputs; $\lambda$ is derived.

### Shape Parameter Interpretation

label: app:ret:shape_interp

The shape parameter $\alpha$ determines the hazard profile of the retirement distribution. The table below summarizes the mapping.

### Weibull shape parameter and hazard profile

label: tab:ret:shape_interp

| $\alpha$ range | Hazard profile | Interpretation |
| --- | --- | --- |
| $\alpha < 1$ | Decreasing | Infant mortality; implausible for physical capital |
| $\alpha = 1$ | Constant | Exponential; geometric depreciation as special case |
| $1 < \alpha < 2.6$ | Regressive increase | Risk rises at decreasing rate; right-skewed mortality |
| $\alpha \approx 2.6$--$3.7$ | Approximately symmetric | Bell-shaped; approximates Winfrey S-3 curve |
| $\alpha > 3.7$ | Negatively skewed | Retirements cluster tightly near mean life |

*Source:* Adapted from Nomura [@Nomura2005]. The density $f(\tau)$ is positively skewed for $\alpha < 2.6$ and approximately symmetric for $2.6 < \alpha < 3.7$.

<!-- FLAG: latex_crosswalk | original=\citet[Section~3.2]{Nomura2005} -->

### The GPIM Retirement Recursion

label: app:ret:gpim_recursion

In the GPIM, the gross real stock evolves as:

$$
K^{GR}_{i,t} = IG^{R}_{i,t} + (1 - \rho_{i,t}) \cdot K^{GR}_{i,t-1}
$$

label: eq:ret:gpim

where $\rho_{i,t}$ is the period-$t$ aggregate retirement rate for account $i$.
Under the Weibull specification, this is the hazard rate evaluated at the investment-weighted mean age of the stock:

$$
\rho_{i,t} \approx h(\bar{\tau}_{i,t})
= \frac{\alpha_i}{\lambda_i}
\left(\frac{\bar{\tau}_{i,t}}{\lambda_i}\right)^{\alpha_i - 1}
$$

label: eq:ret:rho_weibull

where $\bar{\tau}_{i,t}$ is the investment-weighted mean age of account $i$'s capital stock at time $t$, computed from the accumulated vintage distribution.

Under the Shaikh/BEA-1993 toggle (Option A), $\rho_{i,t}$ is replaced by the time-varying aggregate retirement rate taken directly from Shaikh [@Shaikh2016], projected forward by investment-mix weighting.

<!-- FLAG: latex_crosswalk | original=\citet[Appendix~6.8.II.3]{Shaikh2016} -->

### Log-Linear Estimation of Weibull Parameters

label: app:ret:loglinear

Following Nomura [@Nomura2005], the cumulative hazard function admits a log-linear form that facilitates estimation:

$$
\ln H(\tau) = \beta + \alpha \ln \tau
$$

label: eq:ret:loglinear

where $\beta = -\alpha \ln \lambda$ and $H(\tau) = (\tau/\lambda)^{\alpha}$. This log-linear relationship between cumulative hazard and age makes OLS on observed discard data computationally straightforward. Nomura uses this to estimate $(\alpha, \lambda)$ per asset class from the 2002 Survey of Actual Capital Stock and Discard of Private Enterprises (SASD).

<!-- FLAG: latex_crosswalk | original=\citet{Nomura2005} -->

## Sources for Parameterization

label: app:ret:sources

Three sources supply different pieces of the Weibull parameterization. This subsection extracts the relevant parameters from each, distinguishing what each source does and does not provide.

### Shaikh (2016) ADJ1: BEA 1993 Finite Service Lives

label: app:ret:src_shaikh

Shaikh reinstates the pre-1997 BEA methodology via ADJ1, taking the aggregate depreciation and retirement rates from BEA 1993 and projecting them forward beyond 1997 using the asset-mix composition of current investment. The implied mean service life is recovered by inverting the aggregate straight-line depreciation rate:

$$
T_{\text{implicit}} = \frac{1}{z_{\text{SL}}}
$$

label: eq:ret:shaikh_inversion

where $z_{\text{SL}}$ is the straight-line depreciation rate for the asset class.
From Shaikh’s Appendix Figure 6.7.5, the aggregate BEA 1993 corporate depreciation rate is approximately $z \approx 0.062$, yielding $T_{\text{implicit, aggregate}} \approx 16$ yr (investment-mix-weighted across structures and equipment). Decomposed: structures-dominant sub-portfolio $z_{\text{structures}} \approx 0.033$--$0.040$ implies $T_{\text{structures}} \approx 25$--$30$ yr; equipment-dominant sub-portfolio $z_{\text{equipment}} \approx 0.070$--$0.100$ implies $T_{\text{equipment}} \approx 10$--$14$ yr.

Shaikh supplies implicit $L$ for corporate structures and equipment but does not use the Weibull distribution; the aggregate rates embed the Winfrey S-3 shape implicitly without making $\alpha$ explicit. Government transportation service lives are not recoverable from ADJ1.

<!-- FLAG: latex_crosswalk | original=\citet[Appendix~6.7]{Shaikh2016} -->
<!-- FLAG: latex_crosswalk | original=\citet{BEA1993} -->
<!-- FLAG: latex_crosswalk | original=\citet[Appendix Figure~6.7.5]{Shaikh2016} -->

### Fraumeni (1997): BEA Post-1997 Geometric Depreciation Rates

label: app:ret:src_fraumeni

This subsection extracts mean service lives from Fraumeni’s Table 3 for the three accounts entering the GPIM.

Fraumeni documents the BEA's switch from straight-line depreciation with Winfrey retirement distributions to geometric (constant-rate) depreciation. The empirical basis is Hulten and Wykoff, who estimated age-price profiles for 32 U.S. producer durable equipment and nonresidential structure asset classes using Box-Cox models on used-asset market prices. Fraumeni's Table 3 reports the service life $T$ that BEA used in the pre-1997 methodology alongside the new geometric rate $\delta$ and declining-balance rate $R$ for every BEA asset class.

<!-- FLAG: latex_crosswalk | original=\citeauthor{Fraumeni1997}'s~(\citeyear{Fraumeni1997}) -->
<!-- FLAG: latex_crosswalk | original=\citet{Fraumeni1997} -->
<!-- FLAG: latex_crosswalk | original=\citet{HultenWykoff1981b} -->

### BEA service lives — NF corporate structures

label: tab:ret:fraumeni_structures

| Asset | $T$ (yr) | $\delta$ | $R$ |
| --- | ---: | ---: | ---: |
| Industrial buildings | 31 | 0.0314 | 0.975 |
| Office buildings | 36 | 0.0247 | 0.889 |
| Commercial warehouses | 40 | 0.0222 | 0.889 |
| Other commercial buildings | 34 | 0.0262 | 0.889 |
| All other nonfarm buildings | 38 | 0.0249 | 0.899 |
| **Investment-weighted average** | **$\approx 36$** |  |  |

*Source:* Fraumeni [@Fraumeni1997].

### BEA service lives — NF corporate equipment (selected)

label: tab:ret:fraumeni_equipment

| Asset | $T$ (yr) | $\delta$ | $R$ |
| --- | ---: | ---: | ---: |
| General industrial equipment | 16 | 0.1072 | 1.715 |
| Electrical transmission equipment | 33 | 0.0500 | 1.650 |
| Farm tractors | 14 | 0.1452 | 2.033 |
| Construction tractors | 10 | 0.1550 | 1.550 |
| Agricultural machinery | 14 | 0.1179 | 1.650 |
| Trucks / buses | 9--14 | 0.12--0.17 | 1.725 |
| **Investment-weighted average** | **$\approx 14$** |  |  |

*Source:* Fraumeni [@Fraumeni1997].

For government nonresidential structures, Fraumeni reports $T = 60$ yr for highways and streets, $T = 50$ yr for air transportation facilities, and $T = 60$ yr for conservation and development structures, yielding an investment-weighted average of approximately 58--60 yr.

Fraumeni supplies explicit $L$ per asset class for all three accounts but does not provide shape parameters — the geometric framework does not model retirement distributions.

<!-- FLAG: latex_crosswalk | original=\citet[Table~3]{Fraumeni1997} -->

### Nomura (2005): Empirically Estimated Weibull Parameters

label: app:ret:src_nomura

This subsection extracts Weibull shape parameters from directly observed discard data, the only available source for empirical $\alpha$ estimates.

Nomura fits Weibull distributions to the 2002 SASD survey conducted by Japan's Economic and Social Research Institute (ESRI), which directly observed scrapping events across 66 asset categories. Three estimation cases are reported: Case-1 (simple count weights), Case-2 (value-weighted), and Case-3 (bias-adjusted value weights correcting for single-period survey sampling bias from non-stationary investment). Case-3 is preferred.

### Nomura (2005) Weibull estimates — structures

label: tab:ret:nomura_structures

| Asset | $\alpha$ (C-1) | $\bar{T}$ (C-1) | $\alpha$ (C-3) | $\bar{T}$ (C-3) |
| --- | ---: | ---: | ---: | ---: |
| Residential buildings | 1.45 | 20.1 | 2.76 | 30.9 |
| Storehouses | 1.62 | 17.7 | 1.72 | 39.9 |
| Office buildings | 1.47 | 15.6 | 1.81 | 24.9 |
| Stores | 1.68 | 13.1 | 1.61 | 23.9 |
| Factories | 1.56 | 17.8 | 1.69 | 29.4 |
| Road and parking areas | 1.29 | 11.7 | 1.28 | 19.8 |
| Other construction | 1.64 | 10.8 | 2.50 | 15.5 |
| **Non-residential weighted avg.** |  |  | **$\approx 1.6$** | **$\approx 25$--$30$** |

*Source:* Nomura [@Nomura2005]. C-1 = Case-1 (count weights); C-3 = Case-3 (bias-adjusted value weights).

### Nomura (2005) Weibull estimates — equipment (selected)

label: tab:ret:nomura_equipment

| Asset | $\alpha$ (C-1) | $\bar{T}$ (C-1) | $\alpha$ (C-3) | $\bar{T}$ (C-3) |
| --- | ---: | ---: | ---: | ---: |
| Metal machine tools | 1.67 | 17.7 | 2.12 | 18.4 |
| Metal processing machinery | 1.29 | 14.9 | 1.61 | 19.9 |
| Construction machinery | 1.39 | 11.3 | 1.82 | 15.0 |
| Chemical machinery | 1.36 | 14.0 | 1.91 | 29.4 |
| Semiconductor equipment | 1.32 | 9.6 | 2.50 | 9.4 |
| Copy machines | 1.94 | 8.2 | 1.82 | 8.2 |
| **General machinery weighted avg.** |  |  | **$\approx 1.7$** | **$\approx 14$--$20$** |

*Source:* Nomura [@Nomura2005]. C-1 = Case-1; C-3 = Case-3. Supporting cross-country evidence: Meinen et al. [@Meinen1998] find $1 < \alpha < 2$ for most Dutch manufacturing assets.

For road and parking areas (Nomura asset 65), Case-3 yields $\alpha = 1.28$ and $\bar{T} = 19.8$ yr. The $\bar{T}$ reflects Japanese urban road replacement cycles and is not applicable to U.S. interstate highway infrastructure (AASHTO design life: 20--50 yr for pavements; FHWA bridge design life: 75+ yr). The shape parameter $\alpha = 1.28$ — nearly exponential — nonetheless characterizes the hazard profile: a broadly dispersed retirement distribution with a long right tail of very long-lived infrastructure assets.

## Three-Source Triangulation and Parameter Decision

label: app:ret:triangulation

The three sources supply complementary pieces of the Weibull parameterization. The table below maps what each source provides.

### Source coverage for Weibull parameters

label: tab:ret:source_coverage

| Source | Supplies | Does not supply |
| --- | --- | --- |
| Shaikh ADJ1 | Implicit $L$ (corporate only) | $\alpha$; gov. transport |
| Fraumeni [@Fraumeni1997] | Explicit $L$ per asset class | $\alpha$ |
| Nomura [@Nomura2005] | Empirical $(\alpha, \bar{T})$ | U.S.-specific calibration |

The triangulation procedure:

1. Use Fraumeni as the primary source for $L$ — it is directly stated, BEA-sourced, and internally consistent with the BEA 1993 methodology that Shaikh restores via ADJ1.
2. Verify Fraumeni $L$ against Shaikh's implicit rates; large divergences indicate an asset-mix composition issue.
3. Use Nomura Case-3 as the primary source for $\alpha$ — it is the only source that directly estimates Weibull shape from observed retirements.
4. Retain Fraumeni $T = 60$ yr for U.S. government transportation; Nomura's Japanese road $\bar{T}$ is not applicable.

### Cross-source comparison and parameter decision

label: tab:ret:cross_source

| Account | Fraumeni $L$ | Shaikh $L$ | Nomura $\bar{T}$ (C-3) | Nomura $\alpha$ (C-3) | Decision |
| --- | ---: | ---: | ---: | ---: | --- |
| NF corp. structures | 36 yr | $\sim$25--30 yr | $\sim$25--30 yr | $\sim$1.6 | $L = 30$, $\alpha = 1.6$ |
| NF corp. equipment | 14 yr | $\sim$10--14 yr | $\sim$14--20 yr | $\sim$1.7 | $L = 14$, $\alpha = 1.7$ |
| Gov. transportation | 60 yr | N/A | 12--20 yr$^{a}$ | $\sim$1.3 | $L = 60$, $\alpha = 1.3$ |

$a$ Japanese urban road data; not applicable to U.S. highway design lives.

### Decision Rationale by Account

label: app:ret:rationale

#### NF corporate structures — $L = 30$ yr, $\alpha = 1.6$

Fraumeni's $T = 36$ yr reflects the full BEA asset class range including long-lived industrial buildings and office towers. Shaikh's implied rate and Nomura's Case-3 estimates for non-residential buildings consistently point to 25--30 yr when investment-weighted across a corporate portfolio that includes commercial retail (shorter) and industrial (longer). The value $L = 30$ yr is conservative relative to Fraumeni but consistent with the other two sources. The $\alpha = 1.6$ implies a regressively increasing hazard: retirement risk rises throughout the asset's life but at a decreasing rate, producing a right-skewed mortality distribution. This is physically plausible for corporate real estate subject to renovation, demolition, and functional obsolescence.

#### NF corporate equipment — $L = 14$ yr, $\alpha = 1.7$

All three sources converge. Fraumeni's investment-weighted average is approximately 14 yr; Shaikh's implied rate is consistent at 10--14 yr; Nomura's general machinery Case-3 estimates center around 14--20 yr. The Fraumeni value is locked as canonical. The $\alpha = 1.7$ implies a similar hazard profile to structures — regressively increasing, right-skewed mortality — supported by Dutch evidence showing $1 < \alpha < 2$ for most manufacturing assets [@Meinen1998].

<!-- FLAG: latex_crosswalk | original=\citep{Meinen1998} -->

#### Government transportation — $L = 60$ yr, $\alpha = 1.3$

The $L = 60$ yr derives from Fraumeni: highways and streets $T = 60$ yr, air transportation $T = 50$ yr. This is consistent with AASHTO design specifications (20--50 yr for pavements; 75+ yr for bridges). The $\alpha = 1.3$ — the lowest shape parameter in the dataset, nearly exponential — indicates a broadly dispersed retirement distribution: most road infrastructure retires well before design life due to damage or capacity constraints, but a fraction remains in service well beyond it.

### Locked Parameter Table

label: app:ret:locked_params

The table below reports the final parameter values entering the GPIM pipeline.

### Locked Weibull retirement parameters

label: tab:ret:locked_params

| Account | $L$ (yr) | $\alpha$ | $\lambda = L\,/\,\Gamma(1 + \alpha^{-1})$ | Primary source |
| --- | ---: | ---: | ---: | --- |
| NF corp. structures | 30 | 1.6 | 33.0 | Fraumeni $T$, Shaikh implicit, Nomura $\alpha$ |
| NF corp. equipment | 14 | 1.7 | 15.3 | Fraumeni $T$; all three sources consistent |
| Gov. transportation | 60 | 1.3 | 68.4 | Fraumeni $T$ (U.S. design life), Nomura $\alpha$ |

*Notes:* Gamma function values: $\Gamma(1.625) \approx 0.909$; $\Gamma(1.588) \approx 0.914$; $\Gamma(1.769) \approx 0.877$.

### Toggle Architecture

label: app:ret:toggle

The pipeline configuration (`10_config.R`) exposes a toggle between the Weibull specification (Option B, canonical) and the Shaikh/BEA-1993 aggregate rates (Option A, sensitivity). Under Option A, $\rho_{i,t}$ is replaced by the aggregate BEA 1993 rates from Shaikh [@Shaikh2016], projected forward by investment-mix weighting — the ADJ1 logic implemented in the capital stock build scripts.

<!-- FLAG: latex_crosswalk | original=\citet[Appendix~6.8.II.3]{Shaikh2016} -->

## Future Extensions

label: app:ret:extensions

The parameters locked above are constants. Several extensions are flagged for future work; all are currently parked.

#### Time-varying service lives

Empirical evidence suggests equipment service lives may shorten over time (technological obsolescence) while structures lives may lengthen (improved materials). A time-varying extension would specify $\alpha(t)$ and $L(t)$ as functions of observable proxies, requiring vintage-level tracking rather than a single aggregate recursion.

#### Sub-asset Weibull heterogeneity

The current implementation uses a single $(L, \alpha)$ pair per account. Within NF corporate equipment, asset sub-types range from computers ($T \approx 5$ yr) to electrical transmission equipment ($T \approx 33$ yr). A sub-asset extension would compute $\rho_{i,t}$ as the investment-share-weighted average of sub-type Weibull hazard rates, making the retirement rate endogenously time-varying from the asset composition of investment.

#### U.S.-specific retirement data

Nomura uses Japanese discard data. No equivalent U.S. survey exists at comparable granularity. The closest sources — BLS Capital Flows tables (discontinued), Powers on cyclical manufacturing retirements, and Office of Tax Analysis studies — provide partial coverage for specific asset classes. Where available, U.S.-estimated shape parameters would replace Nomura's.

<!-- FLAG: latex_crosswalk | original=\citet{Nomura2005} -->
<!-- FLAG: latex_crosswalk | original=\citet{Powers1988} -->

#### IPP sub-component parameterization

Intellectual property products (software, R\&D, entertainment originals) are currently excluded from the productive capacity measure. When integrated, provisional parameters — drawn from Fraumeni for software lives and Nadiri and Prucha for R\&D depreciation — will require a dedicated literature review on intangible capital retirement.

<!-- FLAG: latex_crosswalk | original=\citet{Fraumeni1997} -->
<!-- FLAG: latex_crosswalk | original=\citet{NadiriPrucha1996} -->

#### Government transportation sub-type decomposition

Government transportation is treated as a single account. The BEA Table 7.1 structure-type breakdown distinguishes highways ($T = 60$ yr), air transportation ($T = 50$ yr), and transit infrastructure ($T = 50$--$60$ yr). A sub-type extension using investment shares from Table 7.5 would capture shifts in the composition of public infrastructure investment over the post-1956 Interstate Highway System buildout.