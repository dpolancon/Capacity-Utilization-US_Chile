# When Did Chile's Balance-of-Payments Constraint Bind?

## An import-requirement account of machinery accumulation and external adjustment, 1920–2024

### Abstract

Chile's imports are observed. The level of imports the country's productive structure required is not: it has to be estimated. This report estimates that requirement as a long-run relation between real imports, the gross machinery stock, non-reinvested surplus and the real exchange rate, and asks whether the gap between actual and required imports dates the years when the balance-of-payments constraint bound. A single long-run relation is found in all three samples. It is usable in two of them. Over 1920–2024 imports close 31% of the gap each year and after 1974 they close 69%, so the gap measures something imports respond to. Before 1973 they do not respond at all, and the relation carries no import requirement in that period. Where the measure works it dates 18 binding years over the century, concentrated in the 1930s, the 1950s, and the two post-reform adjustments of 1975–77 and 1983–86. It does not date 1961, the one crisis independently documented, because in 1961 imports stood above their required level rather than below it. The measure identifies the compression that follows an external crisis, not the over-absorption that precedes one.

**Keywords:** Chile; balance of payments; imports; machinery accumulation; real exchange rate; cointegration; error correction; Kaldor; Thirlwall

### Resumen

Las importaciones chilenas se observan; el nivel de importaciones que la estructura productiva requería, no. Este informe estima ese requerimiento como una relación de largo plazo entre importaciones reales, stock bruto de maquinaria, excedente no reinvertido y tipo de cambio real, y pregunta si la brecha entre importaciones efectivas y requeridas fecha los años en que la restricción externa fue vinculante. Se encuentra una relación de largo plazo en las tres muestras, utilizable en dos. Antes de 1973 las importaciones no responden a la relación y la brecha no mide un requerimiento. Donde el indicador funciona, fecha 18 años vinculantes, concentrados en los años treinta, los cincuenta y los dos ajustes posreforma de 1975–77 y 1983–86. No fecha 1961: ese año las importaciones estuvieron por encima de su nivel requerido, no por debajo. El indicador identifica la compresión que sigue a una crisis externa, no el exceso de absorción que la precede.

## 1. The question, and what has to be estimated to answer it

Chile's industrialization ran on imported machinery. Building productive capacity meant buying capital goods abroad, and paying for them depended on export earnings and on access to external finance. When those ran short, the imports that carried the accumulation had to be cut. The question is when that happened.

Answering it requires distinguishing two things that are easy to conflate. Actual imports are recorded in the national accounts every year. The level of imports the productive structure *required* is not recorded anywhere; it is a relation that has to be estimated. Only once that required level exists can a shortfall be defined, and only a shortfall can indicate that the external constraint was doing the cutting.

The required level is estimated as a long-run relation among four variables, all in logs. Real imports and the gross machinery stock carry Kaldor's mechanism: expanding the productive apparatus draws in capital goods. Non-reinvested surplus stands for the surplus not internally recapitalized, which has to be financed or spent abroad. The real exchange rate enters as the relative price at which foreign goods are bought. Writing imports as `m`, the machinery stock as `k`, non-reinvested surplus as `s` and the real exchange rate as `r`, the relation estimated is

    m = β₁ k + β₂ s + β₃ r + constant

and the gap between actual and required imports in a given year is `m − (β₁k + β₂s + β₃r + constant)`. A negative gap means imports sat below the level the relation implies. In the surplus approach β₁ is the foreign-exchange cost of the intensive margin of accumulation: how much import capacity a larger machinery stock commits the economy to, conditional on distribution and the relative price of foreign goods.

Throughout, a rise in the real exchange rate means real depreciation. The convention is confirmed in the data: the largest annual increases fall in 1932, 1956–57, 1974–75 and 1983–85, each a documented Chilean devaluation.

## 2. Data

Every estimate uses the frozen release `chile_bop_binding_v1_1`: 105 annual observations, 1920 to 2024, with 54 years before 1974 and 51 after. No stage re-queries a source or rebuilds a variable. Real series are in 2003 Chilean pesos, matching the GDP source so no rebasing is applied. The real exchange rate splices a ClioLab index through 2010 to the Banco Central series from 2011, rebased to the 2003 scale. Over the 1986–2010 overlap the two correlate at 0.825 in levels and 0.750 in growth rates, with a median absolute level gap of 9.34% and a 2011 boundary change of 0.133 log points. The splice passes its declared audit and is not seamless; the measured gap is a limitation, not a rounding detail.

![The two real exchange-rate sources over their overlap](figures/rer_overlap.pdf)

The figure shows the two sources moving together over 1986–2010 while differing in level, which is why the splice is audited rather than assumed.

![The four series with local trend lines](figures/raw_system.pdf)

The figure shows all four series before any model is imposed: imports and the machinery stock rising together across the century, with the two post-1974 accelerations visible without estimation.

## 3. How persistent is each series?

A long-run relation between levels only makes sense if the levels themselves wander in a particular way. A series is called integrated of order one, written I(1), when its level wanders without returning to any fixed value but its year-to-year change does settle down. Cointegration analysis is built for exactly that case. So each variable is tested before any system is estimated, and the tests are run on the level, then on the change, then on the change in the change, stopping at the first order where the series settles.

Three tests are used because they ask the question from opposite directions. The augmented Dickey–Fuller and Phillips–Perron tests start from the assumption that the series wanders and look for evidence against it, so a statistic more negative than the critical value is evidence of stationarity. The KPSS test starts from the opposite assumption, that the series is stable, so a statistic *above* its critical value is evidence of wandering. Agreement across all three is what makes a verdict safe; disagreement is reported as disagreement.

**Table 1 — Test statistics against 5% critical values (drift specification)**

| Sample | Variable | Differences taken | ADF | ADF 5% | PP | KPSS | KPSS 5% | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1920–2024 | machinery stock | 0 | 0.59 | -2.88 | 3.34 | 1.960 | 0.463 | not stationary |
| 1920–2024 | machinery stock | 1 | -2.29 | -2.88 | -2.09 | 1.115 | 0.463 | not stationary |
| 1920–2024 | machinery stock | 2 | -7.57 | -2.88 | -8.95 | 0.072 | 0.463 | stationary |
| 1920–2024 | real exchange rate | 0 | -2.69 | -2.88 | -3.06 | 0.467 | 0.463 | not stationary |
| 1920–2024 | real exchange rate | 1 | -8.83 | -2.88 | -8.94 | 0.052 | 0.463 | stationary |
| 1920–2024 | real imports | 0 | 0.29 | -2.88 | 0.14 | 2.030 | 0.463 | not stationary |
| 1920–2024 | real imports | 1 | -7.81 | -2.88 | -7.53 | 0.151 | 0.463 | stationary |
| 1920–2024 | non-reinvested surplus | 0 | -0.33 | -2.88 | -0.34 | 2.179 | 0.463 | not stationary |
| 1920–2024 | non-reinvested surplus | 1 | -4.75 | -2.88 | -15.34 | 0.055 | 0.463 | stationary |
| 1920–2024 | wage share | 0 | -1.35 | -2.88 | -2.61 | 1.721 | 0.463 | not stationary |
| 1920–1973 | machinery stock | 0 | -0.86 | -2.89 | 1.22 | 1.009 | 0.463 | not stationary |
| 1920–1973 | machinery stock | 1 | -1.81 | -2.89 | -1.81 | 0.615 | 0.463 | not stationary |
| 1920–1973 | machinery stock | 2 | -5.05 | -2.89 | -6.38 | 0.138 | 0.463 | stationary |
| 1920–1973 | real exchange rate | 0 | -1.48 | -2.89 | -1.16 | 0.529 | 0.463 | not stationary |
| 1920–1973 | real exchange rate | 1 | -5.03 | -2.89 | -6.69 | 0.200 | 0.463 | stationary |
| 1920–1973 | real imports | 0 | -0.97 | -2.89 | -1.26 | 0.816 | 0.463 | not stationary |
| 1920–1973 | real imports | 1 | -5.57 | -2.89 | -4.93 | 0.087 | 0.463 | stationary |
| 1920–1973 | non-reinvested surplus | 0 | -1.05 | -2.89 | -1.45 | 1.314 | 0.463 | not stationary |
| 1920–1973 | wage share | 0 | -4.53 | -2.89 | -4.98 | 0.055 | 0.463 | stationary |
| 1974–2024 | machinery stock | 0 | -0.99 | -2.89 | 0.91 | 1.349 | 0.463 | not stationary |
| 1974–2024 | machinery stock | 1 | -1.92 | -2.93 | -1.99 | 0.417 | 0.463 | not stationary |
| 1974–2024 | machinery stock | 2 | -5.11 | -2.93 | -6.05 | 0.182 | 0.463 | stationary |
| 1974–2024 | real exchange rate | 0 | -3.24 | -2.89 | -3.29 | 0.677 | 0.463 | not stationary |
| 1974–2024 | real exchange rate | 1 | -3.70 | -2.93 | -7.85 | 0.154 | 0.463 | stationary |
| 1974–2024 | real imports | 0 | -1.08 | -2.89 | -0.58 | 1.342 | 0.463 | not stationary |
| 1974–2024 | real imports | 1 | -3.77 | -2.93 | -6.96 | 0.103 | 0.463 | stationary |
| 1974–2024 | non-reinvested surplus | 0 | -1.08 | -2.89 | -0.35 | 1.328 | 0.463 | not stationary |
| 1974–2024 | non-reinvested surplus | 1 | -4.95 | -2.93 | -7.50 | 0.093 | 0.463 | stationary |
| 1974–2024 | wage share | 0 | -1.26 | -2.89 | -1.65 | 1.062 | 0.463 | not stationary |

**Table 2 — Order of integration and what follows for each variable**

| Sample | Variable | Series | Order | Disposition |
| --- | --- | --- | --- | --- |
| 1920–2024 | machinery stock | `log_K_ME_gross` | I(2) | break aware or exploratory route required |
| 1920–2024 | real exchange rate | `log_RER` | I(1) | cointegrating state candidate |
| 1920–2024 | real imports | `log_imports` | I(1) | cointegrating state candidate |
| 1920–2024 | non-reinvested surplus | `log_non_reinvested_surplus` | I(1) | cointegrating state candidate |
| 1920–2024 | wage share | `wage_share` | unresolved by d3 | break aware or exploratory route required |
| 1920–1973 | machinery stock | `log_K_ME_gross` | I(2) | break aware or exploratory route required |
| 1920–1973 | real exchange rate | `log_RER` | I(1) | cointegrating state candidate |
| 1920–1973 | real imports | `log_imports` | I(1) | cointegrating state candidate |
| 1920–1973 | non-reinvested surplus | `log_non_reinvested_surplus` | I(0) | stationary control candidate |
| 1920–1973 | wage share | `wage_share` | I(0) | stationary control candidate |
| 1974–2024 | machinery stock | `log_K_ME_gross` | I(2) | break aware or exploratory route required |
| 1974–2024 | real exchange rate | `log_RER` | I(1) | cointegrating state candidate |
| 1974–2024 | real imports | `log_imports` | I(1) | cointegrating state candidate |
| 1974–2024 | non-reinvested surplus | `log_non_reinvested_surplus` | I(1) | cointegrating state candidate |
| 1974–2024 | wage share | `wage_share` | I(0) | stationary control candidate |

Read variable by variable. **Real imports** settle after one difference in every sample: the level wanders, the growth rate does not. That is the textbook I(1) case and imports enter the long-run relation without qualification. **The real exchange rate** behaves the same way in all three samples. **Non-reinvested surplus** is I(1) over the century and after 1974, but before 1973 it is already stationary in levels, which means that in the pre-1973 sample it contributes no long-run wandering for the others to be tied to. **The wage share** is stationary before 1974 and after 1974 and unresolved over the full span, so it never enters as a long-run variable and appears only in a robustness specification. **The machinery stock** is the problem, and it needs its own section.

One cell is genuinely inconclusive and is not smoothed over. For the change in the machinery stock over the full sample under a trend specification, KPSS returns 0.090 against a 5% value of 0.146, which does not reject stability, while ADF returns -2.76 against -3.43, which does not reject wandering. The two tests point opposite ways once a trend is allowed. The verdict rests on the drift specification, where all three tests agree, and the disagreement is recorded rather than resolved by preference.

## 4. Why a machinery stock can need two differences

The machinery stock needs two differences before it settles, in every sample. That is unusual enough to explain from the ground up, because it is the single biggest constraint on everything that follows.

### Start with what a capital stock is

A capital stock is a running total. This year's machinery is last year's machinery, minus what wore out, plus what was newly installed:

    K(t) = (1 − z)·K(t−1) + I(t)

where `I(t)` is investment in machinery during the year and `z` is the fraction of the existing stock retired. Nothing here is a modelling choice; it is how the stock is built from investment flows.

Now ask what happens if investment itself has no level it returns to. Suppose investment drifts upward for a couple of decades, then settles at a higher pace, then drifts again — never reverting to a long-run average. Adding up a series that wanders gives a total that wanders more. And because `z` is small for machinery, very little of the past is discarded each year, so almost the whole history stays in the total. The running total inherits the wandering of the flow and adds its own on top.

### What the two differences mean

Saying the machinery stock is I(2) says exactly this: not only does the *level* of the stock fail to return to any fixed value, its *growth rate* fails to as well. The rate of machinery accumulation itself moves to a new level and stays there. Only the change in the growth rate settles down.

### What the tests show

The battery in Table 1 shows the pattern directly for the full sample. In levels, ADF returns 0.59 against a 5% value of -2.88 and KPSS returns 1.960 against 0.463: the level wanders, and both tests agree. After one difference — that is, looking at the growth rate of the stock rather than its level — ADF still returns only -2.29 against -2.88 and KPSS still returns 1.115 against 0.463. The growth rate is no more settled than the level was. Only after a second difference does the picture change decisively: ADF -7.57, Phillips–Perron -8.95, KPSS 0.072 — all three tests agree on stationarity.

### What it costs

Standard cointegration analysis assumes every variable in the long-run relation needs the same single difference to settle. Putting an I(2) variable alongside I(1) variables makes the relation *unbalanced*: the two sides wander at different orders, and a coefficient estimated on them is not a long-run elasticity in the usual sense. The honest options are to use machinery growth instead of the stock, to move to methods built for I(2) systems, or to keep the levels specification and report the limitation. This report keeps the levels specification, because the machinery stock is the variable the mechanism is about, and it carries the limitation forward explicitly. A differenced-machinery specification is estimated alongside it as a check.

### What it means about Chile

The statistic is describing something concrete. Chile's machinery stock did not merely grow across the century — the pace at which it grew shifted and stayed shifted, averaging 2.1% a year before 1973 and 7.4% after. A series whose growth rate steps up to a new level and remains there is precisely what a second unit root describes. The awkward statistical property and the post-reform transformation of Chilean accumulation are the same fact, seen from two directions.

## 5. How many long-run relations are there?

With the variables classified, the next question is how many independent long-run relations tie them together. The answer is the *rank*: zero means no relation and the variables drift apart permanently; one means a single relation holds them together; more than one means several do. Rank is estimated with the Johansen trace test, which asks in sequence whether the number of relations is zero, then at most one, and so on, stopping at the first hypothesis it cannot reject.

Rather than test one preferred model, the relation is built up one variable at a time, so the evidence can be read as a sequence.

**Table 3 — The specifications, from the mechanism core outward**

| Rung | Variables | What it adds |
| --- | --- | --- |
| M1_kaldor_core | real imports, machinery stock | Kaldor core: imports and machinery accumulation |
| M2_plus_surplus | real imports, machinery stock, non-reinvested surplus | adds the surplus not internally recapitalized |
| M3_plus_rer | real imports, machinery stock, non-reinvested surplus, real exchange rate | headline: Kaldor controlled by the real exchange rate |
| M4_plus_wage_share | real imports, machinery stock, non-reinvested surplus, wage share | robustness: legacy fourth variable in place of the RER |
| M3d_machinery_differenced | real imports, machinery growth, non-reinvested surplus, real exchange rate | balanced-order diagnostic: machinery enters in first differences |

**Table 4 — Number of long-run relations found at each rung (constant, two lags)**

| Sample | Rung | Relations found | Residual-correlation p | All variables same order? |
| --- | --- | --- | --- | --- |
| 1920–2024 | M1 | 1 | 0.883 | no |
| 1920–2024 | M2 | 1 | 0.032 | no |
| 1920–2024 | M3 | 1 | 0.035 | no |
| 1920–2024 | M3d | 2 | 0.301 | yes |
| 1920–2024 | M4 | 1 | 0.076 | no |
| 1920–1973 | M1 | 0 | n/a | no |
| 1920–1973 | M2 | 0 | n/a | no |
| 1920–1973 | M3 | 1 | 0.532 | no |
| 1920–1973 | M3d | 1 | 0.831 | no |
| 1920–1973 | M4 | 1 | 0.911 | no |
| 1974–2024 | M1 | 1 | 0.723 | no |
| 1974–2024 | M2 | 1 | 0.979 | no |
| 1974–2024 | M3 | 1 | 0.927 | no |
| 1974–2024 | M3d | 1 | 0.932 | yes |
| 1974–2024 | M4 | 1 | 0.802 | no |

The sequence tells a clear story. Over the full century and after 1974, a single relation appears as soon as imports and machinery are put together, and it survives every addition. Before 1973 the two-variable and three-variable systems find nothing: no relation ties imports to machinery, or to machinery and surplus, in the pre-reform period. A relation appears only once the real exchange rate is added. That is the first sign that the pre-1973 system behaves differently, and Section 7 shows why it matters.

**Table 5 — The four-variable relation across deterministic terms and lags**

| Sample | Deterministic | Lags | Relations found | Residual-correlation p | Largest non-unit root |
| --- | --- | --- | --- | --- | --- |
| 1920–2024 | const | 2 | 1 | 0.035 | 0.716 |
| 1920–2024 | const | 3 | 1 | 0.452 | 0.866 |
| 1920–2024 | trend | 2 | 2 | 0.522 | 0.841 |
| 1920–2024 | trend | 3 | 1 | 0.368 | 0.866 |
| 1920–1973 | const | 2 | 1 | 0.532 | 0.763 |
| 1920–1973 | const | 3 | 1 | 0.951 | 0.823 |
| 1920–1973 | trend | 2 | 2 | 0.951 | 0.763 |
| 1920–1973 | trend | 3 | 1 | 0.804 | 0.823 |
| 1974–2024 | const | 2 | 1 | 0.927 | 0.682 |
| 1974–2024 | const | 3 | 1 | 0.688 | 0.798 |
| 1974–2024 | trend | 2 | 0 | n/a | n/a |
| 1974–2024 | trend | 3 | 1 | 0.741 | 0.798 |

The specification carried forward in each sample is the one that finds exactly one relation, leaves no residual correlation at 5%, and has stable dynamics. Requiring exactly one matters: when the test finds two, the single relation extracted from a two-dimensional space is one arbitrary combination of the two and cannot be read as *the* import requirement. The last column is the stability check. A system tied together by one relation among four variables must carry three permanent trends, so three roots sit on the unit circle by construction; the question is whether the remaining roots lie inside it. They do, between 0.68 and 0.84, so the dynamics are stable.

![Trace statistics across every rung and sample](figures/rank_grid.pdf)

The figure shows each trace sequence against its 5% critical value: where the solid line starts above the dashed one and then crosses below, that crossing point is the number of relations.

The promoted specification is the four-variable relation in all three samples, with a constant, at three lags over the full century and two lags in each subsample.

## 6. What the long-run relation says

**Table 6 — The estimated import requirement**

| Sample | Variable | Coefficient | Import share of the relation | Readable as an elasticity? |
| --- | --- | --- | --- | --- |
| 1920–2024 | real imports | 1.000 | 0.747 | yes |
| 1920–2024 | machinery stock | 0.578 | 0.747 | yes |
| 1920–2024 | non-reinvested surplus | 0.393 | 0.747 | yes |
| 1920–2024 | real exchange rate | 0.551 | 0.747 | yes |
| 1920–1973 | real imports | 1.000 | 0.042 | no |
| 1920–1973 | machinery stock | 11.661 | 0.042 | no |
| 1920–1973 | non-reinvested surplus | -7.055 | 0.042 | no |
| 1920–1973 | real exchange rate | 19.738 | 0.042 | no |
| 1974–2024 | real imports | 1.000 | 0.808 | yes |
| 1974–2024 | machinery stock | 0.683 | 0.808 | yes |
| 1974–2024 | non-reinvested surplus | 0.177 | 0.808 | yes |
| 1974–2024 | real exchange rate | 0.187 | 0.808 | yes |

Over the full century the required import level rises by 0.58% for every 1% increase in the machinery stock, and after 1974 by 0.68%. Read through the surplus approach, this is the foreign-exchange commitment attached to the intensive margin of accumulation: enlarging the machinery stock obliges the economy to sustain a proportionally higher level of imports, and the coefficient measures how much.

The pre-1973 column cannot be read this way, and the fourth column of Table 6 says why. Normalizing the relation on imports means dividing every coefficient by the weight imports carry in it. Before 1973 imports carry only 0.042 of that weight, so the division is by something close to zero and the resulting numbers — a machinery coefficient above eleven, a real-exchange-rate coefficient near twenty — are an artifact of the arithmetic, not elasticities. The relation found in the pre-1973 sample is not an import relation. Section 7 confirms this from an entirely separate direction.

The real exchange rate enters the long-run relation with a **positive** sign: 0.55 over the century and 0.19 after 1974. Since a rise means depreciation, this says a more depreciated currency goes with *higher* required imports, which is the opposite of a relative-price brake. The pattern is in the raw data, not an artifact of the system: over 1920–2024 the correlation between the log real exchange rate and the goods-import share of GDP is 0.54. The reading that fits Chilean structure is that capital and intermediate imports are hard to substitute domestically, so depreciation raises their peso cost without displacing them, while depreciation episodes coincide with the external pressure that accompanies accumulation drives. Section 8 shows the real exchange rate doing something quite different within the year.

**Table 7 — The machinery coefficient beside two simpler comparisons**

| Sample | Long-run coefficient | Level regression slope | Ratio of average growth rates |
| --- | --- | --- | --- |
| 1920–2024 | 0.578 | 0.979 | 0.919 |
| 1920–1973 | 11.661 | 1.109 | 1.320 |
| 1974–2024 | 0.683 | 0.851 | 0.801 |

The comparison matters because two series that both trend upward will appear related whether or not anything ties them together. If the estimated coefficient simply reproduced the ratio of average growth rates, it would be measuring shared drift. It does not: over the full century the long-run coefficient is 0.58 while the growth ratio is 0.92 and the level slope is 0.98. The system estimate is well below both, which is what conditioning on surplus and the real exchange rate does: part of what a bare comparison attributes to machinery belongs to the other two.

## 7. Which variable does the adjusting, and which does not

A long-run relation on its own says nothing about who moves when the relation is violated. That is the adjustment coefficient: for each variable, the fraction of last year's gap closed this year. A coefficient indistinguishable from zero says that variable ignores the gap entirely, which in this literature is called weak exogeneity. For the question at hand this is the decisive test, because a gap only measures an import requirement if imports are what responds to it.

**Table 8 — Adjustment to the long-run gap, by equation**

| Sample | Equation for | Coefficient | t | p | Responds to the gap? |
| --- | --- | --- | --- | --- | --- |
| 1920–2024 | machinery stock | -0.010 | -1.36 | 0.178 | does not adjust |
| 1920–2024 | real exchange rate | 0.123 | 1.98 | 0.051 | does not adjust |
| 1920–2024 | real imports | -0.315 | -4.87 | 0.000 | adjusts |
| 1920–2024 | non-reinvested surplus | -0.072 | -0.74 | 0.462 | does not adjust |
| 1920–1973 | machinery stock | 0.002 | 4.02 | 0.000 | adjusts |
| 1920–1973 | real exchange rate | 0.003 | 0.46 | 0.645 | does not adjust |
| 1920–1973 | real imports | -0.005 | -0.71 | 0.479 | does not adjust |
| 1920–1973 | non-reinvested surplus | -0.022 | -1.96 | 0.056 | does not adjust |
| 1974–2024 | machinery stock | -0.026 | -0.75 | 0.458 | does not adjust |
| 1974–2024 | real exchange rate | 0.068 | 0.48 | 0.637 | does not adjust |
| 1974–2024 | real imports | -0.685 | -3.34 | 0.002 | adjusts |
| 1974–2024 | non-reinvested surplus | -0.291 | -1.94 | 0.059 | does not adjust |

Over the full century imports carry the adjustment, closing 31% of the gap each year with a t ratio of -4.87. After 1974 the response is far faster, 69% within the year, and imports are the only variable that responds significantly: the machinery stock, surplus and the real exchange rate all ignore the gap. That is the configuration the question needs. Imports absorb the disequilibrium and the other three are free to push it around, so the gap is a genuine import requirement and the speed at which imports close it measures how hard the requirement bites.

Before 1973 the picture inverts. Imports respond by -0.005 with a t ratio of -0.71 and a p value of 0.479 — indistinguishable from no response at all. The machinery stock is what adjusts, at a t ratio of 4.02. So the relation that exists in the pre-1973 sample is one that machinery closes, not one that imports close. This is the same conclusion the normalization diagnostic reached in Section 6, arrived at independently: before 1973 there is no import requirement for imports to fall short of. Under import-substituting industrialization, imports of capital goods were administratively allocated through licensing and multiple exchange rates rather than adjusted to a price-and-quantity equilibrium, and a relation imports do not error-correct is what that institutional arrangement looks like in the time series.

![The gap series, with the pre-1973 sample marked unusable](figures/misalignment_usability.pdf)

The figure shows the gap for each sample, greyed where imports do not respond to it: the pre-1973 line is drawn but carries no requirement reading.

## 8. What moves imports within the year

**Table 9 — Short-run structure of the import equation**

| Sample | Term | Coefficient | t | p | Significant at 5%? |
| --- | --- | --- | --- | --- | --- |
| 1920–2024 | change in machinery stock, lag 1 | -1.247 | -1.13 | 0.260 | no |
| 1920–2024 | change in machinery stock, lag 2 | 2.499 | 2.41 | 0.018 | yes |
| 1920–2024 | change in real exchange rate, lag 1 | -0.198 | -1.66 | 0.100 | no |
| 1920–2024 | change in real exchange rate, lag 2 | -0.067 | -0.56 | 0.579 | no |
| 1920–2024 | change in real imports, lag 1 | 0.437 | 3.73 | 0.000 | yes |
| 1920–2024 | change in real imports, lag 2 | -0.066 | -0.63 | 0.530 | no |
| 1920–2024 | change in non-reinvested surplus, lag 1 | 0.028 | 0.40 | 0.687 | no |
| 1920–2024 | change in non-reinvested surplus, lag 2 | 0.067 | 1.05 | 0.298 | no |
| 1920–1973 | change in machinery stock, lag 1 | 0.098 | 0.11 | 0.916 | no |
| 1920–1973 | change in real exchange rate, lag 1 | 0.112 | 0.51 | 0.613 | no |
| 1920–1973 | change in real imports, lag 1 | 0.427 | 2.66 | 0.011 | yes |
| 1920–1973 | change in non-reinvested surplus, lag 1 | 0.127 | 1.42 | 0.161 | no |
| 1974–2024 | change in machinery stock, lag 1 | 3.285 | 3.70 | 0.001 | yes |
| 1974–2024 | change in real exchange rate, lag 1 | -0.320 | -1.45 | 0.155 | no |
| 1974–2024 | change in real imports, lag 1 | 0.025 | 0.17 | 0.866 | no |
| 1974–2024 | change in non-reinvested surplus, lag 1 | 0.586 | 3.19 | 0.003 | yes |

Over the full century imports have their own momentum: last year's import growth carries 0.44 into this year's, the most significant short-run term in the equation. After 1974 that momentum disappears — the own-lag coefficient falls to 0.025 and is indistinguishable from zero — and machinery growth takes over, at 3.29 with a t ratio of 3.70, alongside non-reinvested surplus at 0.59. Post-reform import growth is driven by what is being installed and what surplus is available to finance it, not by its own past.

The real exchange rate is where short and long run part company. In the long-run relation its coefficient is positive. Within the year it enters negatively in every sample — -0.198 over the century, with a p value of 0.100, and -0.320 after 1974 — so a depreciation does compress imports in the short term, though only marginally significantly. The relative price works as a brake on impact and as a co-mover over the long haul. Reporting only one of the two would misdescribe what the exchange rate does in this system.

Before 1973 nothing but the own lag matters: machinery growth, surplus and the real exchange rate are all insignificant in the import equation. The disconnection found in Section 7 shows up here too — pre-1973 imports move largely on their own history.

## 9. The gap beside the external accounts

The gap is a model quantity, so on its own it cannot establish that the external constraint was binding: a shortfall relative to an estimated requirement could reflect a mis-specified requirement. Independent evidence is needed, and it comes from the external accounts, which are observed rather than estimated: the current-account balance, the goods balance, the change in manufactured imports, and a financing-compression indicator.

A year is counted as binding only when two independent things agree — imports below the requirement the relation implies, *and* at least one external-account indicator showing stress, meaning a current-account or goods deficit of 3% of GDP or more, a fall in manufactured imports of at least 3 percentage points of GDP, or the financing indicator triggering. Years that satisfy only one of the two are recorded as satisfying only one. Nothing is ever counted as binding on the strength of the model alone.

**Table 10 — What each category means**

| Category | Meaning |
| --- | --- |
| binding confirmed | Imports sat below the level the long-run relation implies, and the external accounts showed stress in the same year. Both kinds of evidence agree. |
| imports short only | Imports sat below the implied level, but no external-account indicator crossed its threshold. The model sees a shortfall the accounts do not corroborate. |
| external stress only | The external accounts showed stress, but imports were at or above the level the relation implies. Pressure without an import shortfall. |
| not binding | Neither imports fell short of the implied level nor did the accounts show stress. |
| no estimate for year | The lag structure leaves this year without a value for the long-run relation, so no statement is made about it. |
| external stress no usable model signal | The accounts showed stress, and in this sample the model provides no usable import signal because imports do not adjust to the relation. |
| no stress no usable model signal | The accounts showed no stress, and in this sample the model provides no usable import signal. |

![The gap beside each external-account indicator](figures/shortfall_vs_accounts.pdf)

The figure puts the import shortfall and the three account-based pressure measures on one standardized scale: they rise together in the 1930s, the mid-1950s, and the mid-1970s and mid-1980s, and diverge in the early 1960s.

**Table 11 — Years by category**

| Sample | Binding | Import shortfall only | External stress only | Neither | Total |
| --- | --- | --- | --- | --- | --- |
| 1920–2024 | 18 | 18 | 37 | 32 | 105 |
| 1920–1973 | 0 | 0 | 30 | 24 | 54 |
| 1974–2024 | 7 | 1 | 18 | 25 | 51 |

Every year of the release is accounted for in each sample: 105, 54, 51 years respectively. The pre-1973 row is not a finding about Chile. It records that in that sample the model supplies no usable import signal, so the confirmation rule — which requires both kinds of evidence — can never be met. Thirty of those years show external stress in the accounts; what is missing is a requirement measure to pair it with, and the report does not convert that absence into a claim that the constraint never bound before 1973.

**Table 12 — Binding episodes**

| Sample | Years | Length | Peak year | Peak pressure |
| --- | --- | --- | --- | --- |
| 1920–2024 | 1933 | 1 | 1933 | 1.627 |
| 1920–2024 | 1937–1938 | 2 | 1938 | 0.041 |
| 1920–2024 | 1950–1951 | 2 | 1950 | 0.570 |
| 1920–2024 | 1953–1954 | 2 | 1954 | 0.963 |
| 1920–2024 | 1957–1959 | 3 | 1958 | 1.323 |
| 1920–2024 | 1963 | 1 | 1963 | 0.479 |
| 1920–2024 | 1975–1976 | 2 | 1976 | 0.436 |
| 1920–2024 | 1983–1986 | 4 | 1985 | 0.825 |
| 1920–2024 | 2024 | 1 | 2024 | 0.004 |
| 1974–2024 | 1975–1977 | 3 | 1976 | 0.970 |
| 1974–2024 | 1983–1986 | 4 | 1983 | 1.073 |

![The external pressure index, with binding years shaded](figures/pressure_index.pdf)

The figure shows the combined pressure index by sample, with binding years shaded: the tallest sustained blocks are the 1950s and the two post-reform adjustments.

The dated episodes line up with Chilean external history. 1933 sits in the Depression collapse of export earnings. The 1950–51, 1953–54 and 1957–59 runs fall inside the import-substituting decades, when capital-goods imports expanded against stagnant export receipts. 1975–77 follows the post-coup opening and the first oil shock, and 1983–86 is the debt crisis. Both post-reform episodes appear in the full-century and post-1974 datings alike, which is the strongest internal agreement in the report.

## 10. Does the gap identify when the constraint bound?

Partly, and the qualification is specific enough to be useful. The gap identifies binding years where imports demonstrably respond to it, which means the full century and the post-1974 sample and not the decades before 1973. Where it works it is corroborated: 18 of the 105 years in the full sample show a shortfall and independent external stress together, and the episodes fall where Chilean external history puts them.

The decisive test is the one independent date available. The Banco Central's centennial history records the 1961 balance-of-payments crisis and the abandonment of the fixed exchange rate. The chronology does not identify it. In 1961 the gap is 0.394 — imports stood *above* their required level, the largest positive gap in the surrounding decade — while the external accounts did show stress. The year is therefore recorded as external stress without an import shortfall.

That is a coherent economic reading rather than a failure to explain. The sequence around it is 1958 and 1959 below the requirement and confirmed binding, 1960 through 1962 above it with stress continuing, then 1963 below again. What 1961 looks like in this measure is an economy sustaining imports above what its productive structure and export earnings supported, financed by reserves and external credit until they ran out. The crisis was the exhaustion of that financing; the compression came afterwards. An import-shortfall measure registers the adjustment, not the over-absorption that made adjustment necessary.

So the measure dates *external adjustment episodes* rather than crisis onsets, and that is what it should be used for. A chronology of when imports were compressed against a machinery-implied requirement is a different object from a chronology of when reserves ran out, and 1961 is where the two come apart most visibly.

## 11. Limitations

**The machinery stock is I(2).** The promoted specification puts an I(2) variable in a levels relation with I(1) variables, so it is unbalanced and the machinery coefficient is not a long-run elasticity in the strict sense. A differenced-machinery specification is estimated as a check and finds a relation in every sample, but the levels version is what the report interprets. Resolving this properly means either a net-stock or investment-flow formulation or a method built for I(2) systems.

**Before 1973 the method does not apply.** Imports do not respond to the estimated relation and the relation does not normalize on imports. Both diagnostics point the same way, and the consequence is that the report has nothing to say about the timing of binding episodes in the import-substituting decades. That is the period the 1961 benchmark falls in.

**One external benchmark is a thin test.** The verified evidence base supplies exactly one precisely dated crisis, and no additional marker was invented to pad the comparison. The interpretation offered for the 1961 disagreement is plausible and is not established by a single case.

**The real exchange rate's long-run sign is unresolved.** A positive long-run coefficient on a depreciation measure cannot be read as a price elasticity. The short-run coefficient has the expected negative sign, which is reassuring but does not explain the long-run pattern.

**The splice is measurable.** The real exchange rate joins two sources with a median level gap of 9.34%, which enters every specification that uses it.

## Data availability and reproducibility

The frozen release is `data/releases/chile_bop_binding_v1_1/`. Every number is copied from a completed stage ledger; the builder performs no estimation. The SHA-256 hash of every consumed input is recorded in `output/CL/BOP_BINDING_V7/S99_REPORT_ASSEMBLY/`, and the staged ledgers sit in `data/` beside this file. Stage integrity ledgers for the estimation and dating stages both report every check passing, and the builder refuses to assemble if either fails. Each gap value was verified to reproduce the long-run relation for its own year, to a maximum absolute deviation of 3.5e-13.

The threshold model reported in the previous version is absent here. Its regime effect was not statistically supported, and the estimation stage refuses to run if any threshold ledger is among its inputs.

**AI-use disclosure.** Claude Code assisted with reproducible code, diagnostics, evidence organization and report assembly under human direction. All claims are auditable against the frozen release and the staged ledgers.

