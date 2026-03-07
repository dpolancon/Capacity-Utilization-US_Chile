# Replication Visualization Architecture --- S0, S1, S2

This document describes the **visualization system for the entire
critical replication pipeline**, covering:

-   **S0 --- Faithful replication**
-   **S1 --- ARDL specification grid**
-   **S2 --- System re‑estimation via VECM**

The visualization architecture follows a **progressive identification
logic**:

Raw replication → specification robustness → structural system
identification.

All figures follow a **common geometric language** based on
**fit--complexity space**.

------------------------------------------------------------------------

# Global Replication Pipeline

    Raw Data
       ↓
    S0 — Faithful Replication
       ↓
    S1 — ARDL Specification Grid
       ↓
    S2 — System Re‑estimation (VECM)
       ↓
    Structural Interpretation

Each stage produces **its own visualization layer**, but all are
designed to remain **comparable**.

------------------------------------------------------------------------

# S0 --- Faithful Replication Visualization

Purpose:

Verify that the pipeline reproduces the **capacity utilization series
reported by Shaikh**.

## Figure S0.1 --- Replicated Utilization Series

Plot type:

Time series

Axes:

X axis → time\
Y axis → utilization

Layers:

-   Shaikh reported utilization
-   Replicated utilization

Purpose:

Confirm that the replication reproduces the **published empirical
object**.

------------------------------------------------------------------------

# S1 --- ARDL Specification Grid Visualization

S1 explores the **ARDL specification lattice**.

Models are compared using **fit--complexity geometry**.

## Figure S1.1 --- Global Likelihood Frontier

Scatter plot.

Axes:

X axis → model complexity (k_total)\
Y axis → −2 logLik

Layers:

-   admissible models
-   efficient frontier
-   specification labels (p,q,c,s)

Purpose:

Identify **efficient ARDL specifications**.

------------------------------------------------------------------------

## Figure S1.2 --- Information Criteria Tangencies

Overlay IC decision rules on the frontier.

Criteria shown:

-   AIC
-   BIC
-   HQ
-   ICOMP
-   RICOMP

Purpose:

Show that **different information criteria correspond to different
tangencies** on the frontier.

This demonstrates that **model identification depends on the penalty
rule**.

------------------------------------------------------------------------

## Figure S1.3 --- Informational Domain

Highlight the **Ω20 region**.

Definition:

Top 20% likelihood region of admissible models.

Visualization options:

-   faceting (top vs remainder)
-   shaded frontier region

Purpose:

Identify regions where **additional complexity yields meaningful
information gains**.

------------------------------------------------------------------------

# S2 --- VECM System Visualization

S2 extends the analysis to **system estimation**.

The same geometric logic is preserved to maintain **comparability with
S1**.

## Figure S2.1 --- Global Likelihood Frontier

Scatter plot.

Axes:

X axis → system complexity (k_total)\
Y axis → −2 logLik

Layers:

-   admissible VECM models
-   frontier line
-   specification labels

Purpose:

Identify **efficient system specifications**.

------------------------------------------------------------------------

## Figure S2.2 --- Information Criteria Frontiers

Overlay IC selection paths.

Criteria:

-   AIC
-   BIC
-   HQ
-   ICOMP
-   RICOMP

Purpose:

Determine whether **system identification is robust across penalty
rules**.

------------------------------------------------------------------------

## Figure S2.3 --- Informational Domain

Highlight the **Ω20 region** within the system specification lattice.

Purpose:

Identify **high‑information regions** where additional parameters
produce significant likelihood improvements.

------------------------------------------------------------------------

# Unified Visualization Grammar

Across S1 and S2, all figures follow the same geometry.

Axes:

X → complexity (number of parameters)\
Y → −2 log likelihood

This allows **direct comparison between ARDL and VECM specification
spaces**.

------------------------------------------------------------------------

# Visualization Tools

All figures implemented using **ggplot2**.

Recommended implementation references:

Scatter + labeling\
https://r-graph-gallery.com/web-scatterplot-corruption-and-human-development.html

Faceting\
https://r-graph-gallery.com/web-time-series-and-facetting.html

Area shading\
https://r-graph-gallery.com/area-chart.html

------------------------------------------------------------------------

# Replication Visualization Summary

    S0
    ↓
    Time‑series replication figure

    S1
    ↓
    Specification lattice visualization
    ↓
    Frontier geometry
    ↓
    Information‑criteria tangencies

    S2
    ↓
    System specification lattice
    ↓
    Frontier geometry
    ↓
    Structural interpretation

The visualization system therefore provides a **consistent empirical
language** linking:

replication → specification robustness → structural system
identification.
