# Reduced-Rank Confinement Report (Revised)
## Shaikh ARDL Replication Reinterpreted Through Confinement Geometry and System Identification

### Purpose and stance
This report reconstructs a sequence of empirical exercises as an identification workflow. The object is **reduced-rank confinement** (restricted drift) rather than a production function or a mechanical output-gap decomposition. “Utilization” is treated first as a **pressure coordinate** (distance from a long-run mapping). Level interpretation requires explicit anchoring.

The report proceeds in two linked layers:

1. **Conditional anchor (ARDL)**: a single-equation representation that estimates a candidate long-run mapping and a conditional correction coefficient in the output growth equation.
2. **System discipline (VECM S1)**: a joint estimation that (i) recovers the full adjustment geometry, (ii) evaluates robustness under alternative deterministic embeddings and short-run memory allocations, and (iii) maps feasible manifold rotations beyond “winners-only.”

---

## 1. Object of analysis: confinement rather than potential output

Start from the accounting identity:
\[
\ln Y_t = \ln Y^p_t + \ln u_t.
\]

Capacity is not imposed as an ex ante trend. The empirical question is whether accumulation and effective output exhibit **bounded co-movement** once institutional level shifts are accounted for. In reduced-rank terms: whether stochastic drift in \((\ln Y_t,\ln K_t)\) is confined to a lower-dimensional manifold.

---

## 2. ARDL(2,4) anchor as a conditional rank‑1 representation

### 2.1 State vector and long-run mapping
Let
\[
X_t=(\ln Y_t,\ln K_t)'.
\]

In a two-variable integrated setting, the rank‑1 confinement hypothesis corresponds to a **single** long-run restriction. The **normalized** long-run mapping is written as:
\[
\ln Y_t = a + \theta\,\ln K_t + \sum_h c_h D_{h,t} + \varepsilon_t,
\]
where \(D_{h,t}\) are deterministic break dummies used to capture level re-anchoring.

Define the deterministic-augmented error-correction term as:
\[
ECT_t \equiv \ln Y_t - a - \theta\,\ln K_t - \sum_h c_h D_{h,t}.
\]

Under the “utilization as residual” interpretation, \(ECT_t\) is the empirical **pressure coordinate**. Mapping it into a utilization *index* requires a normalization convention (see Section 6).

### 2.2 Estimated ARDL anchors
The ARDL(2,4) replication provides a conditional estimate of the manifold tilt and conditional correction in the output equation:

- Long-run slope (conditional tilt):  
  \[
  \theta_{ARDL}=0.7085689\quad (SE=0.04319,\ t=16.41).
  \]

- Conditional correction in \(\Delta\ln Y\):  
  \[
  \lambda=-0.159747\quad (t=-4.125),
  \]
  implying a half-life of roughly 3.98 years under a simple geometric decay heuristic.

These objects are **conditional**: they are properties of a single-equation representation in which dynamics are summarized through the output equation and \(K\) enters as a conditioning regressor.

---

## 3. Deterministics and breaks: translation is guaranteed, rotation is empirical

### 3.1 Dummy years and two treatments
Dummy years: 1956, 1974, 1980.

Two treatments are examined:

- **Variant A (embedded in LR):** dummies enter the long-run level.  
- **Variant B (excluded from LR):** dummies are excluded from the long-run level and thus appear in the residual/pressure coordinate.

Within the fixed ARDL anchor, the practical implication is:

- Dummy placement strongly affects the volatility and episodic spikes of the residual (pressure/utilization coordinate).
- The estimated \(\theta\) may appear stable across the two dummy treatments **within that fixed conditional specification**.

### 3.2 The key discipline
It is always true that deterministic handling **translates** the long-run relation (changes the intercept path). It is **not** a general result that deterministics “do not alter tilt.” Whether deterministics also **rotate** the inferred manifold (change \(\theta\)) is an empirical question that must be checked in a system setting where drift and persistence can be reassigned across model components (see Section 5).

---

## 4. What the single-equation ARDL can and cannot identify

ARDL identifies (conditionally):
- \(\theta\) (a candidate long-run slope under conditioning),
- \(\lambda\) (conditional correction in \(\Delta\ln Y\)).

ARDL does **not** identify (by construction):
- adjustment in \(\Delta\ln K\) (the system correction channel for capital),
- weak exogeneity of \(\ln K\),
- whether the rank‑1 restriction is stable under alternative system specifications,
- the full reduced-rank geometry \((\alpha,\beta)\) of a joint system.

This gap is not a technical nuisance; it is the difference between a **conditional** confinement story and a **system** confinement story.

---

## 5. Stage S1 system identification: joint adjustment, full-lattice saturation, and clustered robustness

Stage S1 treats the ARDL anchor as a **candidate** mapping and asks whether confinement survives system discipline.

### 5.1 Joint adjustment geometry (α vs λ)
In a system representation, deviations from confinement are corrected through an **adjustment vector**:
\[
\Delta X_t = \alpha\,ECT_{t-1} + \sum_{i=1}^{p-1}\Gamma_i\,\Delta X_{t-i} + (\text{deterministics}) + \varepsilon_t.
\]

The key difference from ARDL is that correction pressure is not confined to the output equation. System estimation can reveal:
- whether \(\Delta\ln Y\) and \(\Delta\ln K\) both respond to \(ECT_{t-1}\),
- whether the conditional \(\lambda\) is a faithful summary of system correction,
- whether conditioning on \(K\) is innocuous or hides capital adjustment.

### 5.2 Short-run memory allocation as an identification object
S1 evaluates structured short-run specifications over a lattice:
- **p**: short-run memory depth,
- **q-profiles**: asymmetric allocations of short-run lags across \(\Delta\ln Y\) and \(\Delta\ln K\).

The system result is not only a “best model,” but a **pattern**: where the estimation repeatedly chooses to spend degrees of freedom to preserve bounded drift. This yields a stable statement about short-run propagation (accumulation-loaded memory allocation) that is not available in a single-equation summary.

### 5.3 Saturation beyond winners: feasible manifold rotations
A winners-only summary can conceal specification risk. S1 is saturated by documenting that the evaluated lattice contains **alternative manifold rotations** that become feasible when:
- p increases (more short-run memory),
- deterministics become more permissive (more freedom to absorb drift),
- the system reallocates persistence between \(\Gamma\) dynamics and long-run structure.

Some candidate tilts appear extreme (high-tilt and low-tilt alternatives) among well-ranked specifications. The identification task is to treat these as feasible rotations and then discipline them through:

1) **Admissibility gating** (stochastic structure must be coherent; visually attractive stability measures are not sufficient), and  
2) **Likelihood–complexity geometry** (rotations “bought” by parameterization are not interpreted as stable long-run structure).

### 5.4 Cluster logic (deterministic families)
Deterministic treatments define clusters (spec families). The comparative object is not “which is true,” but:

- which cluster is **fit-dominant** and exhibits a stable manifold neighborhood under local perturbations, and
- which cluster is **stability-buffered** and shows how stability margins can be purchased through deterministic handling and parameterization,
- which clusters function as **stress tests** by expanding the feasible rotation space.

This cluster reading converts “robustness checks” into a relational identification map.

---

## 6. Utilization as geometry: what ECT can and cannot be

In a rank‑1 confinement setting, the error-correction term is a distance-from-manifold coordinate:
\[
ECT_t = \ln Y_t - a - \theta\ln K_t - \sum_h c_h D_{h,t}.
\]

Two disciplines follow:

1) **Shape is the primary robustness target.** The time profile of \(ECT_t\) can be meaningfully compared within a stable specification neighborhood.

2) **Level is not automatically identified.** Cross-spec differences in the level or scale of \(ECT_t\) often reflect anchoring and normalization conventions (deterministics and β-scaling). Therefore, utilization should not be asserted as a level series from the raw residual without an explicit anchoring convention for “normal capacity.”

For cross-spec comparability, report:
- relative ECT (demeaned / rebased), and/or
- standardized ECT (z-scores) when comparing shapes across families.

---

## 7. Confinement summary and workflow closure

### 7.1 What is established at this stage
- A conditional ARDL anchor provides a candidate tilt \(\theta\) and conditional correction \(\lambda\) in \(\Delta\ln Y\).
- System identification clarifies whether confinement is a joint object (shared adjustment), whether short-run propagation is accumulation-loaded, and how sensitive the inferred manifold is to drift-handling and memory allocation.

### 7.2 What remains open (and why the next step must be system expansion)
Even with a disciplined bivariate system, the confinement residual remains a composite pressure coordinate. If the manifold rotates under plausible specification perturbations, the next identification step is not “more tuning” of the bivariate shell, but expansion of the state space to include the missing mediation channels that can shift the mapping from accumulation to effective output.

---

## Appendix: Minimal notation recap
- \(X_t=(\ln Y_t,\ln K_t)'\): bivariate system state.
- \(\theta\): manifold tilt (long-run mapping slope under chosen normalization).
- \(D_{h,t}\): break dummies for level re-anchoring.
- \(ECT_t\): deterministic-augmented distance-from-manifold coordinate.
- \(\lambda\): conditional correction coefficient in the ARDL \(\Delta\ln Y\) equation.
- \(\alpha\): system adjustment vector in the VECM.
- \(\Gamma_i\): short-run dynamics matrices.
