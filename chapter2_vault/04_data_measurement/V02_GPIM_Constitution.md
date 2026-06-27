# Chapter 2 — GPIM Measurement Constitution and Capital-Stock Governance

## Authority and purpose

This note is the governing methodological artifact for constructing the capital-stock variables used in the Chapter 2 data and measurement architecture.

It governs:

- the definition of the capital-stock objects;
- the Machinery and Equipment and Nonresidential Structures boundaries;
- the treatment of survival, retirement, efficiency decay, and depreciation;
- the relationship between nominal investment, real investment, and current-cost stocks;
- initialization and pre-sample investment history;
- aggregation;
- validation;
- the distinction between the paper-facing baseline and robustness specifications;
- eligibility for later econometric use.

This note governs the paper-facing version of the data and measurement section of the dissertation. Implementation code, validation outputs, and regression inputs must conform to it.

This note does not yet constitute an implementation report. The implementation sequence, coding prompts, file outputs, and commit plan will be developed separately after this methodological constitution is locked.

---

# 1. Supersession statement

This note supersedes any prior Chapter 2 specification that:

- treats mean service life as a maximum or terminal asset age;
- forces Weibull survival to zero at the mean service life;
- applies a retirement hazard evaluated at an estimated mean age as though it were the exact cohort retirement rate;
- conflates survival, productive-efficiency decay, and economic depreciation;
- presents the Chapter 2 GPIM as a literal replication of Shaikh’s empirical capital-stock series;
- adds chain-type real Machinery and Equipment and Nonresidential Structures levels without an explicit aggregation rule;
- uses the terms “Market Equipment” or “Non-Residential Construction” for the project’s capital objects.

Where an earlier note, appendix, code comment, output label, or methodological statement conflicts with this note, this note governs.

Superseded materials may be retained for historical traceability, but they are not authoritative for current construction or paper-facing interpretation.

---

# 2. Relationship to the Chapter 2 identification architecture

Productive capacity is latent.

Observed output is effective-demand-realized output rather than a direct observation of productive capacity:

$$
y_t = y_t^p + \log \mu_t
$$

where:

- $y_t$ is observed output;
- $y_t^p$ is latent productive capacity;
- $\mu_t$ is capacity utilization.

The capital-stock variables governed by this note are inputs into the estimation of the long-run elasticity structure. They are not themselves direct measures of productive capacity or capacity utilization.

The identification sequence remains:

$$
\text{long-run coefficient vector}
\rightarrow
\widehat{\theta}_t
\rightarrow
\widehat{y}_t^p
\rightarrow
\widehat{\mu}_t
$$

Accordingly:

$$
K_t \neq y_t^p
$$

and:

$$
K_t \neq \mu_t
$$

The purpose of the GPIM is to construct a defensible measure of the installed productive-capital base that enters the long-run productive-capacity relationship.

---

# 3. Relationship to Shaikh

The Chapter 2 method is an improved asset-level cohort-survival GPIM developed within the accounting and valuation framework clarified by Shaikh.

It is not a literal reproduction of Shaikh’s empirical capital-stock series.

Shaikh governs or informs:

- the distinction between nominal investment and real investment;
- the relationship between real stocks and current-cost stocks;
- the role of investment and capital-stock price indices;
- chain-aggregate valuation;
- current-cost GPIM recursion;
- historical sensitivity and initialization;
- numerical comparison against the corrected Appendix 6.8 materials.

The Chapter 2 methodology independently specifies:

- the asset boundary;
- the use of exact cohort accounting;
- Weibull survival functions;
- the separation between mean service life and terminal age;
- tail-tolerance truncation;
- the Machinery and Equipment and Nonresidential Structures mapping;
- the optional productive-efficiency extension;
- the validation and governance framework.

The method should therefore be described as:

> A Chapter 2 asset-level cohort-survival GPIM, constructed in dialogue with Shaikh’s accounting and valuation framework and validated against Shaikh-related benchmarks, but calibrated and implemented for the specific asset boundary and identification requirements of this dissertation.

---

# 4. Capital boundary

## 4.1 Included baseline assets

The Chapter 2 productive-capital baseline includes:

- Machinery and Equipment, abbreviated ME;
- Nonresidential Structures, abbreviated NRC.

The conceptual capital boundary is:

$$
K_t = K_{ME,t} + K_{NRC,t}
$$

This expression defines the scope of the capital object. It does not authorize the mechanical addition of chain-type real levels.

## 4.2 Excluded baseline assets

The following do not enter the baseline productive-capital stock:

- intellectual property products;
- residential fixed assets;
- government fixed assets;
- inventories;
- land.

Intellectual property products and government transportation infrastructure remain available in the broader source-of-truth dataset as conditioning or explanatory variables.

Their analytical role is:

$$
\theta_t
=
\theta
\left(
\omega_t
\mid
IPP_t,\,
GovTransport_t
\right)
$$

They are not direct components of the baseline accumulation stock.

## 4.3 Required asset crosswalk

Every detailed source asset must be assigned one of the following statuses:

- ME;
- NRC;
- excluded;
- ambiguous.

The governing mapping sequence is:

$$
\text{provider source variable}
\rightarrow
\text{detailed asset concept}
\rightarrow
\text{ME, NRC, excluded, or ambiguous}
\rightarrow
\text{constructed stock}
$$

No aggregate ME or NRC series is regression-eligible until the detailed crosswalk has been verified against:

- provider metadata;
- source codes;
- construction code;
- output labels;
- provenance ledgers;
- paper-facing definitions.

---

# 5. Capital-stock concepts

The methodology distinguishes three capital-stock concepts.

## 5.1 Gross real surviving stock

The gross real surviving stock measures the real quantity of installed assets that remain in operation.

For asset $i$:

$$
K_{i,t}^{G,R}
=
\sum_{a \geq 0}
I_{i,t-a}^{R}
S_i(a)
$$

where:

- $I_{i,t-a}^{R}$ is real gross investment in asset $i$ from vintage $t-a$;
- $S_i(a)$ is the probability that an asset of type $i$ survives to age $a$.

This object adjusts for retirement but not for productive-efficiency decline among survivors.

It therefore imposes:

$$
E_i(a)=1
$$

The repaired paper-facing baseline is the gross real surviving stock.

## 5.2 Productive stock

The productive stock adjusts surviving assets for productive-efficiency decay conditional on survival:

$$
K_{i,t}^{P}
=
\sum_{a \geq 0}
I_{i,t-a}^{R}
S_i(a)
E_i(a)
$$

Here, $E_i(a)$ is the productive efficiency of a surviving asset of type $i$ and age $a$ relative to a new asset of the same type.

The productive stock is an optional robustness extension.

It is not currently authorized as the unique paper-facing baseline.

## 5.3 Net or wealth stock

The net or wealth stock is a valuation object governed by the decline in the market or replacement value of assets as they age.

It depends on an age-price profile rather than directly on the age-efficiency profile.

Therefore:

$$
K_{i,t}^{N}
\neq
K_{i,t}^{P}
$$

in general.

Productive stock must not be mechanically transformed into wealth stock without an explicit asset-pricing or age-price model.

---

# 6. Retirement, decay, and depreciation

The following concepts must remain separate.

## 6.1 Retirement

Retirement removes an asset from operation.

It is governed by:

$$
S_i(a)
$$

## 6.2 Conditional productive-efficiency decay

Productive-efficiency decay reduces the service flow supplied by an asset that remains in operation.

It is governed by:

$$
E_i(a)
$$

## 6.3 Economic depreciation

Economic depreciation measures the decline in asset value.

It is governed by an age-price profile and expectations about:

- future services;
- remaining service life;
- obsolescence;
- maintenance costs;
- discounting;
- resale value.

The governing distinction is:

$$
\text{retirement}
\neq
\text{productive-efficiency decay}
\neq
\text{economic depreciation}
$$

Nomura’s Weibull survival parameters concern retirement and survival. They do not directly identify $E_i(a)$.

Economic depreciation rates must not be automatically interpreted as physical or productive-efficiency decay rates.

---

# 7. Exact cohort-survival accounting

The primary physical-stock engine must use exact cohort accounting.

For asset $i$, year $t$, and age $a$:

$$
K_{i,t}^{G,R}
=
\sum_{a=0}^{A_i^\varepsilon}
I_{i,t-a}^{R}
S_i(a)
$$

The exact real retirement flow is:

$$
R_{i,t}^{R}
=
\sum_{a=1}^{A_i^\varepsilon}
I_{i,t-a}^{R}
\left[
S_i(a-1)-S_i(a)
\right]
$$

The retirement mass associated with age $a$ is:

$$
r_i(a)
=
S_i(a-1)-S_i(a)
$$

Subject to the declared timing convention, the stock-flow identity is:

$$
K_{i,t}^{G,R}
=
K_{i,t-1}^{G,R}
+
I_{i,t}^{R}
-
R_{i,t}^{R}
$$

The implementation must explicitly document whether investment is assumed to enter:

- at the beginning of the year;
- at the middle of the year;
- at the end of the year.

The same timing convention must govern:

- stock accumulation;
- retirement;
- price conversion;
- validation.

## 7.1 Rejection of the mean-age hazard approximation as the primary engine

The hazard rate evaluated at the average age of the stock is not generally equal to the cohort-weighted average hazard:

$$
h_i(\bar a_{i,t})
\neq
\sum_a
w_{i,t}(a)
h_i(a)
$$

An aggregate mean-age hazard may be retained only as a diagnostic approximation.

It is not authorized as the primary retirement mechanism.

---

# 8. Weibull survival specification

The baseline candidate survival function is:

$$
S_i(a)
=
\exp
\left[
-
\left(
\frac{a}{\lambda_i}
\right)^{\alpha_i}
\right]
$$

The corresponding continuous-age hazard is:

$$
h_i(a)
=
\frac{\alpha_i}{\lambda_i}
\left(
\frac{a}{\lambda_i}
\right)^{\alpha_i-1}
$$

The mean service life is:

$$
\bar L_i
=
\lambda_i
\Gamma
\left(
1+\frac{1}{\alpha_i}
\right)
$$

Therefore, when the mean service life and shape parameter are given:

$$
\lambda_i
=
\frac{\bar L_i}
{\Gamma\left(1+1/\alpha_i\right)}
$$

## 8.1 Mean service life is not terminal age

The mean service life is an expectation over the survival distribution.

It is not the maximum possible age of the asset.

The following rule is prohibited:

$$
S_i(a)=0
\qquad
\text{for all }a>\bar L_i
$$

The prior implementation eliminated substantial surviving cohort mass at the mean service life and therefore created an artificial retirement cliff.

## 8.2 Tail-tolerance truncation

The computational maximum age must be selected using a survival tolerance:

$$
A_i^\varepsilon
=
\min
\left\{
a:
S_i(a)\leq\varepsilon
\right\}
$$

Candidate tolerances include:

$$
\varepsilon
\in
\left\{
10^{-4},
10^{-6},
10^{-8}
\right\}
$$

The selected stock series must be numerically insensitive to a tighter tolerance.

Finite truncation is computational only. It must not redefine the economic service life.

---

# 9. Survival calibration

Survival calibration must remain asset-specific whenever the evidence permits.

A hybrid survival specification may combine:

- a cross-country or Nomura-derived Weibull shape prior;
- a U.S.-specific mean service life;
- an implied U.S. scale parameter.

The implied scale is:

$$
\lambda_i^{US}
=
\frac{
\bar L_i^{US}
}{
\Gamma\left(
1+1/\alpha_i^{prior}
\right)
}
$$

This procedure:

- transfers or borrows the shape parameter;
- calibrates the scale parameter to a U.S. mean service life;
- does not estimate a U.S. shape parameter;
- concerns survival rather than productive efficiency.

Such a specification must be classified as hybrid survival robustness until its empirical admissibility is independently established.

---

# 10. Nominal investment, real investment, and prices

Nominal investment must be converted into real investment using an admissible asset-specific investment price index:

$$
I_{i,t}^{R}
=
\frac{
I_{i,t}^{N}
}{
P_{i,t}^{I}
}
$$

Nominal investment alone cannot identify real investment or the capital-stock price.

The methodology must distinguish:

- the investment price index, $P_{i,t}^{I}$;
- the capital-stock price index, $P_{i,t}^{K}$.

For an individual homogeneous asset, the two may coincide under restrictive conditions.

For a changing-composition or chain aggregate:

$$
P_t^{I}
\neq
P_t^{K}
$$

in general.

## 10.1 Current-cost recursion

A Shaikh-compatible current-cost recursion is:

$$
K_t^{C}
=
I_t^{N}
+
(1-\rho_t)
\frac{
P_t^{K}
}{
P_{t-1}^{K}
}
K_{t-1}^{C}
$$

Here, $\rho_t$ is the retirement ratio under the declared timing convention.

The related real-stock expression is:

$$
K_t^{R}
=
\frac{
P_t^{I}
}{
P_t^{K}
}
I_t^{R}
+
(1-\rho_t)
K_{t-1}^{R}
$$

Since:

$$
I_t^{N}
=
P_t^{I} I_t^{R}
$$

the investment term may also be expressed as:

$$
\frac{
I_t^{N}
}{
P_t^{K}
}
$$

The completed ME and NRC aggregate must not impose:

$$
P_t^{I}=P_t^{K}
$$

without explicit justification.

---

# 11. Dual implementation architecture

The improved method has two linked implementation lanes.

## 11.1 Lane A — Exact cohort-survival construction

Lane A constructs asset-specific physical stocks from:

- real investment;
- survival functions;
- exact cohort retirements;
- explicit inherited vintages;
- long pre-sample histories.

Its primary output is:

$$
K_{i,t}^{G,R}
$$

Its optional robustness output is:

$$
K_{i,t}^{P}
$$

## 11.2 Lane B — Shaikh-compatible valuation and aggregate reconciliation

Lane B governs:

- current-cost valuation;
- capital-stock prices;
- aggregate price consistency;
- chain aggregation;
- reconciliation between physical stocks and current-cost stocks.

The exact cohort retirement flow from Lane A may be used to derive an aggregate retirement ratio:

$$
\rho_{i,t}
=
\frac{
R_{i,t}^{R}
}{
K_{i,t-1}^{G,R}
}
$$

This calculation remains subject to the declared timing convention.

Lane B must not replace the cohort engine with a hazard evaluated at mean age.

The two lanes must reconcile within declared numerical tolerances.

---

# 12. Initialization and pre-sample investment history

Cold-start initialization is not authorized as the preferred baseline.

The method must distinguish:

- investment-history start;
- stock-construction start;
- reporting start;
- regression-sample start.

The preferred construction uses the longest defensible investment history available.

The reporting period must begin only after the influence of initialization has declined to an acceptable tolerance.

At minimum, the implementation must compare:

1. full available investment history;
2. a later cold start;
3. a benchmark initialized stock;
4. alternative inherited age distributions.

For two alternative initializations, labelled $A$ and $B$, convergence may be evaluated using:

$$
D_{i,t}^{A,B}
=
\left|
\frac{
K_{i,t}^{A}-K_{i,t}^{B}
}{
K_{i,t}^{A}
}
\right|
$$

The reporting start should satisfy a declared condition such as:

$$
D_{i,t}^{A,B}<\tau
$$

for all material initialization comparisons and for a sustained number of years.

The tolerance $\tau$ must be specified in the implementation contract rather than selected after observing the preferred results.

---

# 13. Aggregation

ME and NRC must remain separate through construction and initial validation.

Detailed asset stocks should be constructed before aggregation whenever the source data permit.

The sequence is:

$$
\text{source verification}
\rightarrow
\text{real investment by asset}
\rightarrow
\text{cohort stock by asset}
\rightarrow
\text{ME and NRC aggregation}
$$

## 13.1 Prohibition on mechanical addition of chain-type real levels

The total capital stock must not be constructed by mechanically adding chain-type real ME and NRC levels unless the price system explicitly makes them additive.

The preferred aggregate procedure is:

1. construct detailed asset-level or family-level stocks;
2. value them consistently in current prices;
3. aggregate current-cost values;
4. derive the real aggregate using an explicit price or quantity index.

Conceptually:

$$
K_t^{C}
=
K_{ME,t}^{C}
+
K_{NRC,t}^{C}
$$

followed by:

$$
K_t^{R}
=
\frac{
K_t^{C}
}{
P_t^{K}
}
$$

The construction of $P_t^{K}$ must be documented.

Alternative index-number procedures may be used where warranted, including:

- Fisher quantity indexes;
- Törnqvist quantity indexes;
- fixed-base additive quantities;
- user-cost-weighted capital-services indexes.

These are distinct objects and must not be treated as interchangeable.

## 13.2 Detailed asset mapping requirements

For every detailed asset, the aggregation ledger must report:

- source identifier;
- source label;
- ME or NRC mapping;
- included or excluded status;
- price index;
- service life;
- survival parameters;
- efficiency-profile status;
- aggregation weight;
- coverage share;
- provenance.

A simple average of asset parameters is not authorized unless explicitly supported by the source methodology.

---

# 14. Quality adjustment and within-vintage efficiency

Quality-adjusted investment prices capture differences in the productive characteristics of new assets across vintages.

The age-efficiency profile captures changes in the productive performance of a surviving asset within a vintage as it ages.

Therefore:

$$
\text{embodied quality change across vintages}
\neq
\text{within-vintage efficiency decay}
$$

The methodology must prevent the age-efficiency profile from reproducing quality changes already incorporated in:

$$
P_{i,t}^{I}
$$

This safeguard is especially important for:

- computers;
- communications equipment;
- electronic equipment;
- other assets subject to rapid embodied technical change.

---

# 15. Productive-efficiency robustness extension

The repaired paper-facing baseline imposes:

$$
E_i(a)=1
$$

The optional productive-stock extension introduces alternative age-efficiency profiles.

It is governed as structured robustness rather than as a uniquely identified baseline.

## 15.1 Geometric efficiency toggle

The geometric profile is:

$$
E_i^{G}(a)
=
e^{-\eta_i a}
$$

Define the retained efficiency of a surviving asset at its mean service life as:

$$
m_i
=
E_i(\bar L_i)
$$

Then:

$$
\eta_i
=
-\frac{
\ln(m_i)
}{
\bar L_i
}
$$

and:

$$
E_i^{G}(a)
=
m_i^{a/\bar L_i}
$$

## 15.2 Linear-to-floor efficiency toggle

The linear-to-floor profile is:

$$
E_i^{L}(a)
=
\max
\left\{
E_{i,\min},
1-
(1-m_i)
\frac{
a
}{
\bar L_i
}
\right\}
$$

The profile must not force efficiency to zero at the mean service life.

The efficiency floor must be declared before examining the resulting stock and subjected to sensitivity analysis.

## 15.3 Illustrative retention grid

The following values are robustness assumptions rather than empirical estimates.

### Machinery and Equipment

| Calibration | Efficiency retained at mean service life |
|---|---:|
| Slow decay | $0.90$ |
| Moderate decay | $0.75$ |
| Fast decay | $0.60$ |

### Nonresidential Structures

| Calibration | Efficiency retained at mean service life |
|---|---:|
| Slow decay | $0.95$ |
| Moderate decay | $0.90$ |
| Fast decay | $0.80$ |

For each calibration, both geometric and linear-to-floor profiles should be evaluated.

The joint productive cohort weight is:

$$
W_i(a)
=
S_i(a)E_i(a)
$$

The implementation must inspect $W_i(a)$ to ensure that the combination of survival and efficiency assumptions does not remove productive capacity implausibly early.

## 15.4 Detailed-asset differentiation

Where data permit, the preferred object is:

$$
E_j(a)
$$

for detailed asset $j$, followed by aggregation into ME and NRC.

Possible analytical tiers include:

- rapid-decay equipment;
- medium-decay equipment;
- slow-decay equipment;
- long-lived structures;
- shorter-lived building systems.

Tier assignment requires an explicit and documented crosswalk.

---

# 16. Baseline and robustness hierarchy

## 16.1 Stage A — Repaired gross-surviving baseline

Stage A constructs:

$$
K_{i,t}^{G,R}
=
\sum_a
I_{i,t-a}^{R}
S_i(a)
$$

Stage A requires:

- exact cohort accounting;
- corrected Weibull scale calculations;
- no mean-life cutoff;
- tail-tolerance truncation;
- audited real investment;
- explicit asset mapping;
- warmup and initialization analysis;
- an explicit aggregation procedure;
- deterministic validation.

Stage A is the paper-facing capital-stock baseline unless later governance explicitly authorizes a replacement.

## 16.2 Stage B — Productive-stock robustness

Stage B constructs:

$$
K_{i,t}^{P}
=
\sum_a
I_{i,t-a}^{R}
S_i(a)
E_i(a)
$$

Stage B includes:

- geometric profiles;
- linear-to-floor profiles;
- slow, moderate, and fast retention assumptions;
- separate ME and NRC profiles;
- detailed asset profiles where support exists.

Stage B outputs must be labelled as robustness or sensitivity series.

## 16.3 Stage C — Regression eligibility

Stage C determines whether a constructed series may enter the econometric architecture.

Regression eligibility requires that the series pass:

- object-definition checks;
- asset-boundary checks;
- unit and price checks;
- survival checks;
- initialization checks;
- aggregation checks;
- provenance checks;
- reproducibility checks.

A Stage B productive-stock series may enter regressions as a robustness variable.

It may not replace the Stage A baseline unless its calibration and aggregation receive a separate methodological authorization.

---

# 17. Validation contract

## 17.1 Survival validation

For every asset:

$$
S_i(0)=1
$$

The following must also hold:

$$
0\leq S_i(a)\leq1
$$

$$
S_i(a+1)\leq S_i(a)
$$

and:

$$
r_i(a)
=
S_i(a-1)-S_i(a)
\geq0
$$

The retirement mass must satisfy:

$$
\sum_{a=1}^{A_i^\varepsilon}
r_i(a)
+
S_i(A_i^\varepsilon)
\approx
1
$$

No material survival mass may be discarded at the computational boundary.

## 17.2 Efficiency validation

For every productive-efficiency profile:

$$
E_i(0)=1
$$

$$
0<E_i(a)\leq1
$$

and:

$$
E_i(a+1)\leq E_i(a)
$$

The declared retention target must be reproduced:

$$
E_i(\bar L_i)=m_i
$$

## 17.3 Cohort-accounting validation

The implementation must verify:

$$
K_{i,t}^{G,R}
=
K_{i,t-1}^{G,R}
+
I_{i,t}^{R}
-
R_{i,t}^{R}
$$

within numerical tolerance.

It must also verify:

$$
K_{i,t}^{P}
\leq
K_{i,t}^{G,R}
$$

No cohort may be:

- counted twice;
- retired twice;
- omitted before reaching the tail tolerance;
- assigned to both ME and NRC.

## 17.4 Price validation

The implementation must confirm:

- all investment price indexes are positive;
- price bases are documented;
- nominal and real units reconcile;
- current-cost and real-stock identities reconcile;
- no price series is inferred circularly from the stock it is used to construct;
- investment prices and stock prices are not silently treated as identical at the aggregate level.

## 17.5 Initialization validation

The implementation must report:

- alternative start dates;
- alternative inherited-vintage assumptions;
- convergence diagnostics;
- the selected reporting start;
- the effect of initialization on levels and growth rates.

## 17.6 Aggregation validation

The implementation must verify:

- complete detailed-asset mapping;
- reported ME and NRC coverage shares;
- exclusion of IPP, residential, government, inventory, and land assets;
- consistency between code, metadata, and documentation;
- deterministic reconstruction of aggregates;
- correct treatment of chain-index nonadditivity.

---

# 18. Paper-facing commitments

The dissertation may state that:

1. The capital stock is constructed from real gross investment using an asset-specific cohort-survival perpetual inventory method.

2. Retirement is represented by a smooth survival distribution rather than by a fixed terminal service life.

3. Mean service life calibrates the survival distribution but is not interpreted as maximum asset age.

4. Machinery and Equipment and Nonresidential Structures are constructed separately before aggregation.

5. The baseline stock measures installed assets remaining in operation.

6. Alternative productive-efficiency profiles are evaluated as robustness specifications.

7. Intellectual property products and government transportation capital are excluded from the baseline capacity-building stock but retained as conditioning variables.

8. Initialization, pre-sample history, price treatment, and aggregation are explicitly audited.

The dissertation must not claim that:

- the baseline stock is a direct observation of productive capacity;
- the baseline stock measures utilization;
- the method is a literal reproduction of Shaikh’s capital series;
- Nomura identifies the Chapter 2 efficiency profile;
- the productive-efficiency robustness grid is empirically estimated;
- chain-type real component levels are necessarily additive;
- economic depreciation is identical to productive-efficiency decay.

---

# 19. Source hierarchy

The methodological source hierarchy is:

1. Shaikh Appendix 6.5 for the formal accounting and valuation framework;
2. corrected Appendix 6.8 materials for numerical validation;
3. Shaikh Appendix 6.7 for empirical choices and historical treatment;
4. Nomura for survival, discard, and the distinction between retirement and decay;
5. Paitaridis and Tsoulfidis for operational cohort-PIM comparison, warmup history, and survival-distribution sensitivity;
6. Basu for historical-cost, current-cost, and real-stock distinctions;
7. official BEA, BLS, OECD, and national-accounts documentation for asset definitions, prices, service lives, and aggregation;
8. engineering or operational evidence for optional efficiency-profile bounds.

No secondary source may override an available primary or official source without explicit justification.

---

# 20. Change control

Any future methodological change must state:

- the object being changed;
- the reason for the change;
- the source of the new information;
- whether the change affects Stage A, Stage B, or Stage C;
- whether historical outputs must be regenerated;
- whether regression eligibility must be reassessed;
- whether the paper-facing measurement section must be revised.

Changes to the following must be recorded in a parameter and decision ledger:

- asset boundaries;
- survival parameters;
- investment deflators;
- initialization;
- aggregation;
- efficiency profiles.

No silent parameter substitution is permitted.

---

# 21. Current governance decisions

| Methodological object | Decision |
|---|---|
| Shaikh accounting and valuation framework | Retain |
| Chapter 2 asset-level cohort GPIM | Authorize |
| Hard cutoff at mean service life | Reject |
| Mean-age hazard as primary retirement engine | Reject |
| Weibull survival with tail tolerance | Authorize |
| Exact cohort retirement accounting | Authorize |
| Gross real surviving stock | Authorize as Stage A baseline |
| Productive-efficiency profiles | Authorize as Stage B robustness |
| Geometric efficiency toggle | Authorize as Stage B robustness |
| Linear-to-floor efficiency toggle | Authorize as Stage B robustness |
| Productive stock as unique baseline | Not authorized |
| Separate ME and NRC construction | Required |
| Detailed asset crosswalk | Required |
| Nominal-first or explicit index aggregation | Required |
| Mechanical addition of chain real levels | Not authorized |
| Long pre-sample investment history | Required |
| Initialization sensitivity | Required |
| Stage C regression eligibility | Blocked pending reimplementation and validation |

---

# 22. Immediate consequence for the repository

The existing capital-stock outputs produced by the superseded implementation must be treated as diagnostic or historical artifacts.

They must not be used as the authoritative Chapter 2 capital-stock baseline.

The next repository phase must:

1. translate this note into a code-ready implementation contract;
2. audit the existing source inputs and asset crosswalk;
3. reconstruct Stage A;
4. validate Stage A against accounting identities and external benchmarks;
5. construct Stage B robustness variants;
6. compare the repaired outputs with the superseded series;
7. issue a formal Stage C regression-eligibility decision.

Until those steps are complete, the current capital-stock series is not authorized as the paper-facing baseline.