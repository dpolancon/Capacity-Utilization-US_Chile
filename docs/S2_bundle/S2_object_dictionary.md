# S2 --- Final Frozen Object Dictionary

Spec = {m,r,p,q,d,h}

  Tag   Meaning
  ----- -------------------------------
  m     system dimension
  r     cointegration rank
  p     lag depth
  q     short‑run memory architecture
  d     deterministic branch
  h     historical architecture

------------------------------------------------------------------------

## System dimension

m2 = (lnY, lnK)

m3 = (lnY, lnK, ln e)

------------------------------------------------------------------------

## Rank

m2 → r1

m3 → r2

------------------------------------------------------------------------

## Lag

p1--p4

------------------------------------------------------------------------

## Memory tags

q‑sym

q‑kXX‑yYY

If m=2:

sK = XX/100

If m=3:

sK = XX/100\
sY = YY/100\
se = 1 − sK − sY

------------------------------------------------------------------------

## Deterministic tags

d0\
d1\
d2\
d3

------------------------------------------------------------------------

## Historical tags

h0

h1 → 1973

h2 → 1973 + 1956 + 1980
