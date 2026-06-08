---
type: note
status: active
layer: empirical_design
design_role: capacity_utilization_level_anchor_protocol
scope: chapter2_core_support
related_to:
  - "A00_Aggregate_Transformation_Benchmark"
  - "M10_Empirical_Identification_Framework"
  - "N01_CapacityUtilization_StructuralObject"
  - "R01_residual_vs_structural_identification"
  - "GPIM, heterogeneous capital, stock-flow consistency, and valuation registers"
  - "Price-deflator protocol for ME–NRC  Non Financial-capital composition"
created: 2026-05-14
updated: 2026-05-14
---

# Capacity-utilization pinch-year anchoring protocol

## Core claim

The level of reconstructed capacity utilization requires an explicit anchor.

The econometric stage recovers the long-run transformation relation and reconstructs the shape of productive capacity. It does not, by itself, identify the absolute level at which utilization equals normal or full capacity.

Therefore, the reconstructed utilization path must be level-anchored through a declared pinch year or reference point.

The anchor is not an estimator choice.

It is a measurement convention that maps the reconstructed productive-capacity path into a utilization scale.

---

## 1. Object being anchored

The reconstruction sequence is:

$$
\text{A00 aggregate interaction relation}
\rightarrow
\hat{\theta}_t
\rightarrow
\hat{Y}^p_t
\rightarrow
\text{level anchoring}
\rightarrow
\hat{\mu}_t
$$

where:

$$
\hat{\mu}_t = \frac{Y_t}{\hat{Y}^p_t}
$$

S30 recovers the A00 coefficient vector and transformation relation. S40 reconstructs $\hat{Y}_t^p$, applies the level anchor, and derives $\hat{\mu}_t$.

The anchor fixes the utilization level scale. It does not estimate $\theta_t$, select an estimation window, define historical periodization, or validate regime stability.

---

## 2. Pinch-year rule

A pinch year is a historically and empirically justified year in which utilization is treated as equal to full or normal capacity:

$$
\mu_{t^*} = 1
$$

The pinch year should be externally motivated.

It should not be selected because it improves the shape, smoothness, or interpretability of the reconstructed path.

The pinch year is a scaling device, not an estimated regime boundary.

---

## 3. Country-specific anchors

### United States

Working anchor:

$$
t^*_{US} = 1973
$$

Rule:

$$
\mu_{US,1973} = 1
$$

Rationale:

1973 is treated as the U.S. full-capacity pinch year because it corresponds to the maximum capacity-utilization observation in the FBR utilization series used as external calibration evidence.

Implementation status:

- anchor type: external utilization-series pinch year;
- anchor source: FBR utilization series;
- anchor value: $\mu_{1973}=1$;
- anchor role: level normalization only;
- not an estimated break date;
- not a new S30 window;
- not evidence that utilization converges to one.

### Chile

Working anchor:

$$
t^*_{CL} = 1980
$$

Rule:

$$
\mu_{CL,1980} = 1
$$

Rationale:

1980 is treated as the Chile full-capacity pinch year following the full-capacity interpretation associated with Ffrench-Davis (2018).

Implementation status:

- anchor type: historically sourced full-capacity reference year;
- anchor source: Ffrench-Davis (2018);
- anchor value: $\mu_{1980}=1$;
- anchor role: level normalization only;
- not an estimated break date;
- not an ECT-regime classifier;
- not evidence that utilization converges to one.

---

## 4. Comparative normalization rule

The comparative design should not force the United States and Chile into the same calendar anchor year.

The common normalization is:

$$
\mu_{c,t^*_c}=1
$$

for each country $c$.

The country-specific pinch years are:

$$
t^*_{US}=1973
$$

and:

$$
t^*_{CL}=1980
$$

Thus, the comparison is made on a common utilization scale, not through a common calendar year.

This means:

- U.S. utilization is scaled relative to the U.S. full-capacity reference year;
- Chilean utilization is scaled relative to the Chilean full-capacity reference year;
- cross-country comparison concerns deviations from each country’s own full-capacity reference point.

This avoids imposing a false synchronized world-market full-capacity year.

---

## 5. Relation to historical windows

The estimation window and the utilization anchor are different objects.

For example, in the U.S. case:

- the Fordist-core window may be used as a historical estimation or benchmark window;
- 1973 is the utilization pinch year for level anchoring.

Therefore, the Fordist-core window should not be used to impose:

$$
\overline{\mu}_{1945-1973}=1
$$

unless this is explicitly declared as a separate robustness normalization.

The preferred anchor is:

$$
\mu_{1973}=1
$$

not:

$$
\overline{\mu}_{1945-1973}=1
$$

The latter is a window-average normalization and should be treated as diagnostic only.

---

## 6. Implementation rule

S40 reconstruction scripts must separate:

1. coefficient-recovery provenance;
2. reconstruction window provenance;
3. level-anchor provenance.

The anchor register must include:

- country;
- anchor year;
- anchor value;
- anchor source;
- anchor rationale;
- whether the anchor is externally declared or internally generated;
- whether the anchor is a point-year anchor or window-average anchor;
- whether the anchor is preferred or diagnostic.

For the preferred baseline:

| Country | Preferred anchor year | Anchor condition | Source status | Anchor type |
|---|---:|---:|---|---|
| United States | 1973 | $\mu_{1973}=1$ | FBR maximum utilization series | point-year external pinch |
| Chile | 1980 | $\mu_{1980}=1$ | Ffrench-Davis (2018) full-capacity reference | point-year historical pinch |

---

## 7. Guardrails

Do not write:

> the Fordist-core mean defines normal utilization.

Write:

> the Fordist-core window may define an estimation or historical benchmark, but the preferred U.S. utilization level anchor is the 1973 FBR full-capacity pinch year.

Do not write:

> utilization converges to one.

Write:

> utilization is level-normalized to one at an externally motivated full-capacity reference year.

Do not write:

> the anchor is estimated by S30.

Write:

> S30 estimates the transformation relation; S40 applies an external level anchor to derive utilization.

Do not write:

> the U.S. and Chile must use the same calendar year as full-capacity anchor.

Write:

> the comparison uses a common utilization scale, with country-specific full-capacity pinch years.

---

## 8. Required correction to current S40 implementation

The current U.S. S40 implementation that imposes:

$$
\overline{\mu}_{1945-1973}=1
$$

should be treated as provisional or diagnostic.

The preferred U.S. baseline should instead impose:

$$
\mu_{1973}=1
$$

The Fordist-core window remains relevant as a historical benchmark and coefficient-recovery context, but it should not silently define the level anchor.

---

## 9. Locked formulation

Capacity-utilization reconstruction requires a level anchor that is separate from the econometric recovery of the transformation relation.

For the United States, the preferred anchor is the 1973 FBR full-capacity pinch year:

$$
\mu_{US,1973}=1
$$

For Chile, the preferred anchor is the 1980 full-capacity reference associated with Ffrench-Davis (2018):

$$
\mu_{CL,1980}=1
$$

These are country-specific point-year anchors. They provide a common utilization scale without imposing a common calendar year. Estimation windows, historical periodization, and utilization anchors must remain distinct.
