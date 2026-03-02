# SHAIKH ARDL OUTPUT ANALYSIS — CONSOLIDATED REPORT (Updated)

---

## 1. Model Structure

- **Selected lag order (p, q):** ARDL(2,4)  
  - lnY lags: 1–2  
  - lnK lags: 0–4  

- **Deterministic case:** `uc` (intercept, no trend)

- **Dummy treatment:**
  - Estimation: d1956, d1974, d1980 included unlagged via `|`
  - Variant A: dummy coefficients scaled by \( 1 - \sum \gamma_i \) and embedded into long-run \( \ln Y^p \)
  - Variant B: dummy block excluded from long-run \( \ln Y^p \)

- **Sample window:** 1947–2011  
  Effective estimation: 1951–2011

---

## 2. Cointegration Assessment

- **Bounds F-test:**  
  F = 6.7943  
  Above I(1) upper bound (both asymptotic and exact)  
  → Reject null of no cointegration.

- **Bounds t-test:**  
  t = −2.5522  
  Not beyond I(1) critical value  
  → Do not reject null.

- **Consistency:** Mixed.

- **Strength of evidence:** Moderate.

However, estimating the RECM strengthens inference:

- **λ (RECM Case 2):**
  - Estimate: −0.159747
  - SE: 0.038723
  - t = −4.125
  - p = 0.000134

The ECT is strongly significant and correctly signed. Empirically, this strengthens the case that the system behaves as cointegrated despite the ambiguous bounds t result.

---

## 3. Long-Run Elasticity

- **θ (LR multiplier on lnK):**  
  0.7085689  
  SE = 0.04319  
  t = 16.41  

- **Relative to 1:**  
  Clearly below 1.

Under ARDL(2,4), long-run output responds sub-proportionally to capital.

---

## 4. Adjustment Dynamics

Using RECM Case 2 (intercept inside long-run relation):

- λ = −0.159747  
- Highly significant  
- Implied half-life ≈ 3.98 years  

About 16% of disequilibrium is corrected per year.  
The point estimate is identical across UECM and RECM parameterizations; inference becomes sharper in the restricted form.

---

## 5. Utilization Behavior

- Spikes appear only in the “no LR dummies in Y^p” variant.
- Spikes align exactly with dummy years (1956, 1974, 1980).
- Including LR dummy multipliers reallocates structural level shifts into potential output.
- Excluding them forces those shifts into the utilization residual.

Empirical conclusion: deterministic treatment materially affects utilization volatility at break dates.

---

## 6. Comparative Reflection

- Δθ across constructions: none (same ARDL)
- Δbounds decision: none
- Δλ: none in point estimate; precision improves in RECM
- Utilization smoothness: materially different

---

## 7. Technical Conclusion (Strictly Empirical)

- θ is sharply estimated and stable within ARDL(2,4).
- θ ≈ 0.709 ≠ 1.
- Cointegration evidence is moderate from bounds tests but strong from RECM λ.
- Adjustment speed is economically meaningful (half-life ≈ 4 years).
- Deterministic embedding into long-run potential output is empirically decisive for utilization smoothness.

---

# Deeper Assessment — Reduced Rank Geometry Perspective

## A. Implicit Reduced-Rank Structure

With two I(1) variables:

\[
X_t = (\ln Y_t, \ln K_t)'
\]

Cointegration implies rank r = 1.

The ARDL long-run equation corresponds to a single cointegrating vector:

\[
\beta'X_t = \ln Y_t - a - \theta \ln K_t - \sum c_h D_h
\]

The RECM `ect` term is precisely this \( \beta'X_t \) object.

Thus, the ARDL replication implicitly assumes confinement dimension = 1: drift is restricted to a one-dimensional manifold in (lnY, lnK) space.

---

## B. What the Single-Equation Approach Does Not Identify

ARDL identifies:

- θ (slope of β)
- λ in the ΔlnY equation

It does not identify:

- Adjustment in ΔlnK
- Whether lnK is weakly exogenous
- Whether rank = 1 is statistically preferred in a system test

A Johansen system would:

1. Test r ∈ {0,1}
2. Recover β directly
3. Recover α vector (full adjustment matrix)

---

## C. Dummy Treatment in Rank Geometry

If deterministic level shifts are not included inside β-space (long-run relation), then:

- The residual (utilization) absorbs structural breaks
- The cointegrating manifold is misspecified

Including scaled dummy multipliers shifts the β hyperplane at break dates.  
θ remains unchanged; the intercept position of the manifold changes.

---

## D. Canonical Base for Further System Work

Next empirical step:

1. Estimate Johansen VECM on (lnY, lnK)
2. Include constant + pulse dummies as deterministics
3. Test rank
4. Normalize β on lnY
5. Compare:
   - θ_Johansen vs θ_ARDL ≈ 0.709
   - α_Y vs λ_RECM ≈ −0.16

This determines whether the ARDL replication is a consistent single-equation representation of a rank-1 system or an artefact of lag selection and deterministic placement.

---

# Bottom Line

Empirically:

- The ARDL replication is coherent.
- The long-run slope is strongly identified.
- Adjustment is statistically strong.
- Deterministic embedding is crucial.
- Cointegration is moderately supported via bounds, strongly via RECM λ.

Geometrically:

- The exercise already operates in a rank-1 confinement framework.
- The ARDL is a reduced-rank system written in single-equation form.

