# Study B — Empirical Strategy Canvas

## 1. Research Question
Evaluate whether the identification of productive capacity (Y^p) from ARDL cointegration between output (Y) and capital (K) is stable across the admissible specification lattice or depends on the information criterion used for model selection.

Core relation:

ln(Y_t) = θ ln(K_t) + ε_t

In the utilization interpretation:

ln(u_t) = ln(Y_t) − θ ln(K_t)

with closure under unbalanced growth:

g_Y^p = θ g_K

Utilization is confined but not required to converge to 1.

---

## 2. Model Space (Specification Lattice)

Candidate specifications:

F = { (p, q, c, s) }

Where:

p = ARDL lag order for Y
q = ARDL lag order for K
c = deterministic case (ARDL Cases 1–5)
s = Shaikh historically contingent dummy toggle

Notation used in outputs:

Spec = {p, q, c, s}

Example:

Spec = {2,4,3,1}

---

## 3. Admissibility Gate

Before comparing models, the feasible lattice is restricted using the bounds‑F cointegration test.

Admissible set:

A = { m ∈ F | F‑bounds rejects H0 }

Interpretation:

Rejecting the null implies long‑run confinement of utilization.

Notes:

• Only bounds‑F defines admissibility
• Cases 2 and 4 remain admissible but t‑bounds are not defined

---

## 4. Information Criteria Contest

Within admissible domain A, model selection is evaluated using five criteria:

AIC
BIC
HQ
ICOMP
RICOMP

Each criterion defines:

m* = argmin IC(m)

The Top‑5 specifications per criterion are reported in Table B1.

---

## 5. Likelihood–Complexity Geometry

Each admissible model has:

Fit:

−2 log L(m)

Complexity:

k(m)

Global efficient frontier:

F(k) = min_{m ∈ A, k(m)=k} (−2 log L(m))

This frontier identifies models delivering the best fit at each complexity level.

---

## 6. Informational Gradient (τ)

Frontier improvement between complexity levels:

τ(k) = F(k−1) − F(k)

Define informationally meaningful region:

Top‑20% τ values

Ω20 = { k : τ(k) ≥ Q0.8(τ) }

Interpretation:

Regions where additional complexity produces meaningful likelihood improvement.

---

## 7. Visualization System

Study B produces three frontier figures.

All plots implemented using ggplot2.

Helpful implementation references:

Scatter + labeling example
https://r-graph-gallery.com/web-scatterplot-corruption-and-human-development.html

Faceting example
https://r-graph-gallery.com/web-time-series-and-facetting.html

Area / shading example
https://r-graph-gallery.com/area-chart.html

---

## Figure B1 — Global Likelihood Frontier

Scatter plot:

X‑axis: complexity k
Y‑axis: −2 log L

Layers:

• admissible models
• frontier line
• labels showing (p,q,c,s)

Typical ggplot layers:

geom_point()
geom_line()
geom_text_repel()

Purpose:

Identify efficient ARDL specifications.

---

## Figure B2 — Information‑Criteria Frontiers

Overlay IC decision rules on frontier geometry.

Elements:

• admissible model scatter
• global frontier
• IC selection paths

Paths for:

AIC
BIC
HQ
ICOMP
RICOMP

Purpose:

Show different criteria selecting different tangencies on the frontier.

---

## Figure B3 — Informational Domain (τ Spectrum)

Highlight Ω20 region.

Two visualization options:

Facet frontier into panels:

Top 20% τ
Remaining

Or shade frontier segments.

Purpose:

Identify regions where additional complexity yields meaningful information gains.

---

## 8. Tables

### Table B1 — Information Criteria Contest

Rows: IC criteria
Columns: Top‑5 models

Cell content:

Spec = {p,q,c,s}
IC value
F = bounds statistic***

Stars represent bounds‑F rejection levels.

Purpose:

Show criterion‑dependent model selection.

---

### Table B2 — Efficient Frontier Econometrics

Columns: frontier models

Rows include:

ARDL case
toggle s
Bounds F
Bounds t
θ (long‑run elasticity)
α (adjustment speed)
long‑run multipliers
short‑run ΔK block
short‑run ΔY block
t‑bounds robustness indicator

Purpose:

Provide full econometric interpretation of frontier models.

---

## 9. Workflow Figure — Empirical Strategy

```
ARDL Specification Lattice
        │
        ▼
Bounds‑F Admissibility Gate
        │
        ▼
TABLE B1
Information Criteria Contest
        │
        ▼
FIGURE B1
Global Likelihood Frontier
        │
        ▼
FIGURE B2
IC Selection Frontiers
        │
        ▼
FIGURE B3
Informational τ Domain
        │
        ▼
TABLE B2
Frontier Econometric Interpretation
```

---

## 10. Conceptual Contribution

The analysis demonstrates that:

• multiple ARDL specifications satisfy cointegration
• these models lie on a likelihood–complexity frontier
• different information criteria select different frontier points
• therefore identification of productive capacity (θ) is criterion‑dependent rather than uniquely determined by the data.

