# Notebook 2: Variable Construction and Unit Root Battery
## Chilean Stage 2 — Reparameterized State Vector

**Prerequisite:** NB-01 (redesign motivation)
**Output files:** `stage2_ur_crosswalk.csv`, `stage2_variable_construction.csv`

---

## 2.1 New variable construction

From the panel `chile_tvecm_panel.csv`, the reparameterized variables are:

| Variable | Formula | Units | Role in VECM |
|----------|---------|-------|--------------|
| $k_t^{CL}$ | $\ln(K_t^{NR} + K_t^{ME})$ | log 2003 CLP | Common capital trend |
| $c_t$ | $k_t^{ME} - k_t^{NR}$ | dimensionless log-ratio | Composition state variable |
| $\omega_t c_t$ | $\omega_t \times c_t$ | dimensionless | Distribution-composition interaction |
| $\phi_t$ | $K_t^{ME} / (K_t^{NR}+K_t^{ME})$ | ratio ∈ (0,1) | Post-estimation only (not in VECM) |

The distinction between $c_t$ and $\phi_t$ is important:
- $c_t = \ln(\phi_t/(1-\phi_t))$ is the log-odds of the composition share — the VECM variable
- $\phi_t$ is the level composition share — used only in the post-estimation formula for $\hat{\theta}^{CL}$

Both are already in the panel. The VECM uses $c_t$; the post-estimation formula uses $\phi_t$.

---

## 2.2 Collinearity verification

Expected result from the data:

```
cor(k_NR, k_ME)  ≈ 0.97   [OLD state vector — severe collinearity]
cor(k_CL, c_t)   ≈ 0.2–0.4  [NEW state vector — substantially reduced]
```

If $\text{cor}(k_t^{CL}, c_t) > 0.80$, flag and investigate. This would indicate
that the composition ratio is trending at the same rate as the aggregate capital
stock — possible if $\phi_t$ is a near-linear function of time rather than responding
to regime-specific mechanization incentives.

---

## 2.3 Full unit root battery — decision table

The battery runs four tests per variable: ADF (drift), PP (Z-tau), KPSS (mu),
and ADF on first differences. For all variables expected to be I(1), we also
run Zivot-Andrews to identify structural break dates that may be inflating the
unit root test statistics.

**Critical variable: $c_t$**

The integration order of $c_t$ determines the system architecture:

| $c_t$ verdict | System | Action |
|---|---|---|
| I(0) | **Bivariate**: $(y_t, k_t^{CL})$ as I(1) state; $c_t$, $\omega_t c_t$ as I(0) regressors in DOLS | Use Engle-Granger 2OLS with $c_t$, $\omega c_t$ as short-run controls |
| I(1) | **4-variable**: $(y_t, k_t^{CL}, c_t, \omega_t c_t)$ all I(1) | Standard Johansen on full vector |
| Borderline | 4-variable (conservative) | Report Zivot-Andrews break; ZA-adjusted verdict preferred |

**Prior expectation:** $c_t = k_t^{ME} - k_t^{NR}$ is likely I(1) over 1920–2024,
because ISI-era machinery accumulation (1940–1972) shifted composition upward
persistently, and post-1973 liberalization changed the trajectory again without
returning to the pre-ISI level. The composition ratio has not mean-reverted over
the century. Zivot-Andrews should find a break around 1940 (onset of ISI) or
1956 (peak ISI intensity), consistent with the unit root pre-tests from Prompt 1
on $\phi_t$.

---

## 2.4 Expected results crosswalk

| Variable | ADF | PP | KPSS | ADF(Δ) | ZA break | Expected verdict |
|----------|-----|-----|------|---------|----------|-----------------|
| $y_t$ | fail | fail | rej | rej | ~1970 | I(1) ✓ |
| $k_t^{CL}$ | fail | fail | rej | rej | ~1965 | I(1) ✓ |
| $c_t$ | fail | fail | rej | rej | ~1956 | I(1) ✓ |
| $\omega_t c_t$ | fail | fail | rej | rej | ~1958 | I(1) maintained |
| $\omega_t$ | borderline | borderline | fail | — | ~1958 | I(1) maintained (bounded ratio) |
| $\phi_t$ | borderline | borderline | rej | rej | ~1956 | I(1) maintained (post-estimation only) |

"fail" = fail to reject unit root null; "rej" = reject.
KPSS "rej" = reject stationarity → consistent with I(1).

---

## 2.5 Zivot-Andrews interpretation for $c_t$

If Zivot-Andrews finds a break in $c_t$ around 1940–1960, the correct interpretation
is not that $c_t$ is trend-stationary around a broken trend — it is that the drift
rate of $c_t$ changed at the break. This is consistent with I(1) with a structural
shift in the drift. The appropriate response is to include a dummy for the break
year in the short-run dynamics (unrestricted dummy in the VECM), not to treat $c_t$
as I(0).

---

## 2.6 Gating rule before proceeding to Step 2

**Gate passed if:**
- $y$, $k^{CL}$ confirmed I(1) by ADF + KPSS cross-validation
- $c_t$ confirmed I(1) or borderline (conservative 4-variable system)
- No variable classified I(2) (ADF on Δ series should all reject)

**Gate blocked if:**
- $c_t$ is I(0): switch to bivariate system + DOLS (see contingency in NB-04)
- $k^{CL}$ is I(2): investigate PIM smoothing artifact, try log-differenced k^CL

---

*NB-02 | 2026-04-07 | Next: NB-03 (Stage 1 recap and ECT_m)*
