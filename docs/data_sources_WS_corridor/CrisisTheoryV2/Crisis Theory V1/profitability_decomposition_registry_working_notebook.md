# Profitability Decomposition Registry — Working Notebook

## 0. Purpose

This notebook is the beginning of a reusable registry for the profitability architecture currently being built. It consolidates the canonical decomposition, binding definitions, optional analytical toggles, and selected imports from Weisskopf (1979), all translated into the current notation system.

The aim is not to freeze every possible extension, but to establish a stable core and a modular expansion logic.

---

## 1. Canonical profit-rate decomposition

The working canonical decomposition is:

\[
r_t = (1-\omega_t)\, u_t\, p_t\, \kappa_t^G\, \nu_t
\]

where:

- \(\omega_t\): wage share, treated as the primitive distributive variable
- \(u_t\): capacity utilization
- \(p_t = P_{Y,t}/P_{K,t}\): output-price to capital-goods-price ratio
- \(\kappa_t^G = Y_t^p/K_t^{gr}\): technical productive-capacity term on gross capital stock
- \(\nu_t = V_t^G/V_t^N = (P_{K,t}K_t^{gr})/(P_{K,t}K_t^N)\): gross-to-net book-value wedge

Equivalent profit share definition:

\[
\pi_t = 1-\omega_t
\]

so that the decomposition may also be written as

\[
r_t = \pi_t\, u_t\, p_t\, \kappa_t^G\, \nu_t.
\]

---

## 2. Binding component definitions

### 2.1 Distribution

Wage share is the primitive distributive variable:

\[
\omega_t = \frac{W_t}{P_{Y,t}Y_t}.
\]

Profit share is residual:

\[
\pi_t = 1-\omega_t.
\]

This is a binding convention.

### 2.2 Realization

Capacity utilization is defined as:

\[
u_t = \frac{Y_t}{Y_t^p}.
\]

This is the baseline realization term.

### 2.3 Relative-price translation

The price-translation term is:

\[
p_t = \frac{P_{Y,t}}{P_{K,t}}.
\]

This identifies how productive capacity in real terms is translated into profitability in value terms.

### 2.4 Technical productive-capacity term

The technical-capacity core is:

\[
\kappa_t^G = \frac{Y_t^p}{K_t^{gr}}.
\]

It can also be written as:

\[
\kappa_t^G = \frac{a_t^p}{q_t^p},
\]

where

\[
a_t^p = \frac{Y_t^p}{L_t^p},
\qquad
q_t^p = \frac{K_t^{gr}}{L_t^p}.
\]

Thus the technical-capacity term rises with productivity at capacity and falls with mechanization at capacity.

### 2.5 Gross-to-net book-value wedge

Define

\[
\nu_t = \frac{V_t^G}{V_t^N}
      = \frac{P_{K,t}K_t^{gr}}{P_{K,t}K_t^N}.
\]

Interpretation: this is the wedge between the current replacement-cost valuation of capital in operation and its current net book valuation. When \(\nu_t > 1\), the measured net profit rate is higher because the same profit flow is divided by a smaller written-down capital base.

Under coherent stock accounting, \(\nu_t < 1\) is treated as an inadmissible or diagnostic case.

---

## 3. Binding refinements imported from Weisskopf (1979)

### 3.1 Technical squeeze criterion — binding

The technical-capacity block is not interpreted through mechanization alone. The relevant criterion is whether mechanization outruns productive-capacity productivity.

Since

\[
\kappa_t^G = \frac{a_t^p}{q_t^p},
\]

the adverse technical movement is identified by:

\[
\Delta \ln q_t^p > \Delta \ln a_t^p
\quad \Longleftrightarrow \quad
\Delta \ln \kappa_t^G < 0.
\]

This rule is binding. A rise in capital intensity by itself is not sufficient to diagnose a technical squeeze.

### 3.2 Presentation implication

Whenever the technical block is discussed empirically, the analysis should distinguish between:

- growth in productivity at capacity, \(\Delta \ln a_t^p\)
- growth in mechanization at capacity, \(\Delta \ln q_t^p\)

and report the technical effect through the sign and movement of \(\kappa_t^G\), not through mechanization alone.

---

## 4. Optional analytical toggles

These are available when analytically useful, but are not mandatory in every use of the framework.

### 4.1 Capacity-utilization corridor toggle

Baseline:

\[
u_t = \frac{Y_t}{Y_t^p}.
\]

Optional decomposition:

\[
u_t = u_t^{dom} + u_t^{ext}
\]

with

\[
u_t^{dom} = \frac{D_t^{dom}}{Y_t^p},
\qquad
u_t^{ext} = \frac{TB_t^{(Y)}}{Y_t^p}.
\]

Trade balance in domestic-output units:

\[
TB_t^{(Y)}
=
\frac{P_{X,t}}{P_{Y,t}}X_t^q
-
\frac{P_{M,t}}{P_{Y,t}}M_t^q.
\]

Factoring out \(P_M/P_Y\):

\[
TB_t^{(Y)}
=
\frac{P_{M,t}}{P_{Y,t}}
\left[
\frac{P_{X,t}}{P_{M,t}}X_t^q - M_t^q
\right].
\]

Define terms of trade:

\[
\tau_t = \frac{P_{X,t}}{P_{M,t}}.
\]

Then

\[
u_t^{ext}
=
\frac{P_{M,t}}{P_{Y,t}}
\cdot
\frac{\tau_t X_t^q - M_t^q}{Y_t^p}.
\]

This toggle identifies the route through which terms of trade enter utilization while keeping price and volume effects distinct.

### 4.2 Wage-share granular toggle

Baseline:

\[
\omega_t
\]

Optional decomposition:

\[
\omega_t
=
\frac{w_t^c}{a_t}\cdot\frac{P_{C,t}}{P_{Y,t}}
\]

where

\[
w_t^c = \frac{w_t^N}{P_{C,t}},
\qquad
a_t = \frac{Y_t}{L_t},
\qquad
\lambda_t = \frac{P_{C,t}}{P_{Y,t}}.
\]

Interpretation:

- \(w_t^c/a_t\): real wage relative to productivity
- \(\lambda_t = P_C/P_Y\): consumption-output price wedge

This toggle is used only when the inflation channel embedded in distribution needs to be identified explicitly.

A useful derivative result is:

\[
\frac{\partial \ln r_t}{\partial \ln \lambda_t}
=
-\frac{\omega_t}{1-\omega_t}
=
-\frac{1}{e_t},
\]

where

\[
e_t = \frac{1-\omega_t}{\omega_t}
\]

is the exploitation rate.

### 4.3 Common external-price diagnostic toggle

The current baseline keeps the two main price wedges separate:

\[
\lambda_t = \frac{P_C}{P_Y},
\qquad
p_t = \frac{P_Y}{P_K}.
\]

An optional deeper diagnostic is to re-express these against a common external-price basis when the purpose is to test whether a shared external-price shock is moving both distribution and capital valuation at once.

This is a reporting or diagnostic toggle, not a canonical decomposition rule.

### 4.4 Utilization-correction toggle inside wage share

An optional short-run refinement, inspired by Weisskopf, is to distinguish observed wage-share movement from quasi-fixed labour or overhead-labour effects by introducing:

\[
\omega_t = \omega_t^*/\eta_{\omega,t}.
\]

This is only relevant when short-run utilization changes are believed to contaminate the interpretation of distributive shifts.

It is not a baseline rule at this stage.

---

## 5. Derived ladders from deep structure to observed profitability

### 5.1 Capacity-value ladder

Real technical core:

\[
\kappa_t^G = \frac{Y_t^p}{K_t^{gr}}.
\]

Value translation on gross stock:

\[
p_t \kappa_t^G
=
\frac{P_{Y,t}Y_t^p}{P_{K,t}K_t^{gr}}.
\]

Value translation on net stock:

\[
p_t \kappa_t^G \nu_t
=
\frac{P_{Y,t}Y_t^p}{P_{K,t}K_t^N}.
\]

Actual realization on net stock:

\[
u_t p_t \kappa_t^G \nu_t
=
\frac{P_{Y,t}Y_t}{P_{K,t}K_t^N}.
\]

Distributive closure:

\[
(1-\omega_t)u_t p_t \kappa_t^G \nu_t = r_t.
\]

### 5.2 Growth-accounting form

\[
\Delta \ln r_t
=
\Delta \ln (1-\omega_t)
+
\Delta \ln u_t
+
\Delta \ln p_t
+
\Delta \ln \kappa_t^G
+
\Delta \ln \nu_t.
\]

This is the minimal contribution-accounting form for the current architecture.

---

## 6. Interpretation registry by block

### 6.1 Distributive block

\[
1-\omega_t
\]

captures the residual profit share.

A rise in wage share compresses profitability through the distributive channel.

### 6.2 Realization block

\[
u_t
\]

captures the alignment of actual demand with productive capacity.

When the corridor toggle is activated, realization is split into domestic and external channels.

### 6.3 Capacity-valuation block

\[
p_t \kappa_t^G \nu_t
\]

maps productive capacity into current-price profitability conditions.

This block contains three analytically distinct mechanisms:

- relative output/capital-goods prices
- technical productive capacity per gross capital stock
- gross-to-net book-value wedge

---

## 7. Imported Weisskopf lessons now translated into current notation

### 7.1 Most valuable imported lesson

Do not treat an observed movement in a coarse profitability component as evidence of a unique mechanism.

Instead:

- identify the ambiguity
- construct the minimum correction required
- reintroduce the corrected term into a more elaborate decomposition

This is the methodological lesson behind the current use of toggles.

### 7.2 Direct imports already absorbed

Absorbed into the current framework:

- mechanization is not by itself evidence of a technical squeeze
- price effects inside wage share should be separable from real wage/productivity effects
- utilization can, in principle, contaminate observed distributive movement
- a contribution-accounting layer can be built on top of the canonical structural identity

### 7.3 Import still provisional

Still provisional, not yet locked:

- full utilization-correction method for wage share using overhead labour data
- unified contribution-accounting grouping into distributive / realization / technical-valuation families for reporting tables
- common external-price normalization for shared price-shock diagnostics

---

## 8. Suggested results-pack reporting structure

A practical reporting structure consistent with this notebook would be:

1. Canonical decomposition table:
   - \(1-\omega_t\)
   - \(u_t\)
   - \(p_t\)
   - \(\kappa_t^G\)
   - \(\nu_t\)

2. Technical-capacity decomposition table:
   - \(a_t^p\)
   - \(q_t^p\)
   - \(\kappa_t^G\)
   - technical squeeze indicator: sign of \(\Delta \ln \kappa_t^G\)

3. Optional wage-share granular table:
   - \(\omega_t\)
   - \(w_t^c/a_t\)
   - \(P_C/P_Y\)

4. Optional utilization corridor table:
   - \(u_t\)
   - \(u_t^{dom}\)
   - \(u_t^{ext}\)
   - \(P_M/P_Y\)
   - \(\tau_t = P_X/P_M\)

5. Growth-contribution table:
   - \(\Delta \ln (1-\omega_t)\)
   - \(\Delta \ln u_t\)
   - \(\Delta \ln p_t\)
   - \(\Delta \ln \kappa_t^G\)
   - \(\Delta \ln \nu_t\)

---

## 9. Immediate next candidates for development

The most natural next extensions of this registry are:

1. define the empirical construction of \(Y_t^p\) and \(K_t^{gr}\)
2. decide whether \(p_t\) should ever be internally decomposed
3. decide whether \(\nu_t\) will remain purely accounting or be given historical interpretation by asset age / depreciation regime
4. build a clean reporting layer grouping the five factors into higher-order families for tables and figures

---

## 10. Minimal working summary

The current architecture is:

\[
r_t = (1-\omega_t)\,u_t\,p_t\,\kappa_t^G\,\nu_t
\]

with one binding refinement:

\[
\kappa_t^G=\frac{a_t^p}{q_t^p},
\qquad
\Delta \ln \kappa_t^G < 0
\Longleftrightarrow
\Delta \ln q_t^p > \Delta \ln a_t^p.
\]

The framework remains modular through optional toggles for:

- domestic vs external utilization corridors
- granular decomposition of wage share
- utilization correction in short-run distributive analysis
- shared external-price diagnostics

This notebook should be treated as the initial registry for future extensions.
