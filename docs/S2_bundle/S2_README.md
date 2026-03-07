# S2 --- System-Level Replication (VECM)

## Purpose

Study **S2** extends the critical replication from the **single‑equation
ARDL environment (S1)** to a **system representation** using a
**reduced‑rank Vector Error Correction Model (VECM)**.

The objective is to determine whether Shaikh's capacity‑utilization
residual can be interpreted as a **structural confinement relation**
when identification occurs at the **system level**, rather than through
conditional single‑equation estimation.

The econometric engine used is the **VECM implementation from the
`tsDyn` package (R)**.

------------------------------------------------------------------------

# Conceptual Logic

In Shaikh's framework:

u = Y / Y\^p

and productive capacity evolves according to

g(Y\^p) = θ · g(K)

which allows **unbalanced growth (θ ≠ 1)**.

Taking logs:

ln(Y) − θ ln(K) = ln(u)

Thus:

• Cointegration between **lnY** and **lnK** identifies the **capacity
transformation relation**\
• The residual represents **capacity utilization dynamics**

S2 tests whether this relation remains stable when the model is
estimated as a **system** rather than conditionally.

------------------------------------------------------------------------

# System Design

Two system dimensions are considered.

## m = 2

X_t = (lnY_t , lnK_t)

This reproduces Shaikh's core structure.

## m = 3

X_t = (lnY_t , lnK_t , ln e_t)

where **e** is the rate of exploitation.

This allows testing a second structural relation related to
**reserve‑army dynamics**.

------------------------------------------------------------------------

# Specification Grammar

Each model is defined by:

Spec = {m, r, p, q, d, h}

Where:

m = system dimension\
r = cointegration rank\
p = lag depth\
q = short‑run memory architecture\
d = deterministic structure\
h = historical shock structure

The full dictionary is documented in:

**S2_object_dictionary.md**

------------------------------------------------------------------------

# Estimation Engine

All system estimations are performed with:

tsDyn::VECM()

Maximum likelihood estimation under the reduced‑rank condition:

Π = αβ'

rank(Π) = r

------------------------------------------------------------------------

# Model Lattice Exploration

S2 evaluates a structured grid over:

• system dimension (m)\
• rank (r)\
• lag depth (p)\
• short‑run propagation architecture (q)\
• deterministic specification (d)\
• historical shock toggles (h)

The resulting model lattice is evaluated using **fit--complexity
geometry**.

------------------------------------------------------------------------

# Model Comparison Geometry

Models are evaluated on a **fit vs complexity plane**.

X‑axis:

k_total = number of estimated parameters

Y‑axis:

−2 logLik

Information criteria correspond to linear trade‑off rules:

IC = −2 logLik + λ · k_total

with

AIC → λ = 2\
BIC → λ = log(T)\
HQ → λ ≈ 2 log log(T)

ICOMP and RICOMP incorporate covariance‑based complexity penalties.

------------------------------------------------------------------------

# Visualization Strategy

Three core figures summarize the model lattice.

## Figure S2.1 --- Global Likelihood Frontier

Scatter:

x = k_total\
y = −2 logLik

Purpose:

Identify efficient specifications.

------------------------------------------------------------------------

## Figure S2.2 --- Information‑Criteria Frontiers

Overlay IC decision paths:

AIC\
BIC\
HQ\
ICOMP\
RICOMP

Purpose:

Show how different penalties select different tangencies.

------------------------------------------------------------------------

## Figure S2.3 --- Informational Domain

Highlight the **top 20% likelihood region (Ω20)**.

Purpose:

Identify regions where complexity yields meaningful information gains.

The full visualization guide is documented in:

**S2_visualization_strategy.md**

------------------------------------------------------------------------

# Pipeline Workflow

S2 estimation pipeline:

1.  Construct specification grid\
2.  Estimate VECM models (tsDyn)\
3.  Compute log‑likelihood and parameter counts\
4.  Apply admissibility filters\
5.  Compute information criteria\
6.  Build frontier geometry\
7.  Identify candidate models\
8.  Interpret cointegration space β

------------------------------------------------------------------------

# Helper Functions

Implementation helpers are documented in:

**S2_helpers.md**

These functions standardize:

• VECM estimation\
• likelihood extraction\
• parameter counting\
• stability checks

------------------------------------------------------------------------

# Documentation Map

This folder contains the documentation for S2.

/docs

S2_README.md\
S2_empirical_strategy.md\
S2_object_dictionary.md\
S2_visualization_strategy.md\
S2_helpers.md

------------------------------------------------------------------------

# Relationship with Other Studies

S0 --- Shaikh faithful replication\
S1 --- ARDL grid exploration\
S2 --- VECM system replication

S2 tests whether the **capacity‑utilization relation survives system
identification** and whether additional structural relations emerge when
exploitation dynamics are introduced.

------------------------------------------------------------------------

# Freeze Status

The S2 design is **conceptually saturated**.

Frozen elements:

• specification grammar\
• deterministic dictionary\
• institutional shock interpretation\
• admissibility rules\
• visualization framework\
• frontier‑based model comparison

Remaining items are **implementation details**, not conceptual gaps.
