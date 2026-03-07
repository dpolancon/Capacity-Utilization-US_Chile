# S2 --- VECM Empirical Strategy

Study **S2** extends the critical replication from the single‑equation
ARDL framework (S1) to a **system representation** using a
**reduced‑rank VECM**.

The goal is to test whether Shaikh's utilization residual can be
interpreted as a **structural confinement relation** when identification
is performed at the **system level**.

Engine: **tsDyn VECM (R)**.

------------------------------------------------------------------------

## System representation

ΔX_t = αβ'X\_{t−1} + Σ Γ_i ΔX\_{t−i} + deterministic + ε_t

where

Π = αβ'

rank(Π) = r

------------------------------------------------------------------------

## State vector

Two system sizes:

m = 2\
X_t = (lnY_t , lnK_t)

m = 3\
X_t = (lnY_t , lnK_t , ln e_t)

where e is the rate of exploitation.

------------------------------------------------------------------------

## Empirical grid

Spec = {m, r, p, q, d, h}

This defines the full S2 lattice.

------------------------------------------------------------------------

## Lag depth

p ∈ {1,2,3,4}

------------------------------------------------------------------------

## Short‑run memory architecture

q is descriptive.

Allowed tags:

q‑sym\
q‑kXX‑yYY

Example:

q‑k40‑y60

------------------------------------------------------------------------

## Deterministic branches

d ∈ {d0,d1,d2,d3}

d0 = none\
d1 = LR mean\
d2 = SR mean\
d3 = LR + SR mean

------------------------------------------------------------------------

## Historical toggles

h ∈ {h0,h1,h2}

h0 = none

h1 = full institutional shock (1973)

h2 = full + partial shocks (1956, 1980)

------------------------------------------------------------------------

## Admissibility

A model is admissible if

• estimation converges\
• rank satisfied\
• stability satisfied

Stability:

exactly m − r unit roots\
no explosive eigenvalues

------------------------------------------------------------------------

## Selection geometry

X axis = complexity (k_total)

Y axis = −2 logLik

IC = −2 logLik + λ k_total
