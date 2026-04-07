# Notebook 4: CLS Threshold VECM — Estimation and γ̂ Identification
## How the Regime Classifier Is Identified from the Data

**Prerequisite:** NB-03 (ECT_m verified stationary)
**Output files:** `stage2_ssr_grid.csv`, `stage2_regime_classification.csv`, `stage2_alpha_loadings.csv`

---

## 4.1 The identification problem and why CLS solves it

The identification problem has two parts:

1. **γ (threshold):** Where does ECT_m cross the boundary that activates $\lambda > 0$?
2. **α^(1), α^(2) (regime-specific loadings):** How does the frontier system adjust
   to disequilibrium ECT_θ in each regime?

Neither is observed directly. The CLS estimator solves both simultaneously by
exploiting a key property: for **fixed** $\beta$ (cointegrating vector) and
**fixed** $\gamma$, the two-regime VECM is a linear OLS regression.

$$\Delta X_t = \mu + \underbrace{\alpha^{(1)} ECT_{\theta,t-1}(1-R_t)}_{\text{Regime 1 loading}} + \underbrace{\alpha^{(2)} ECT_{\theta,t-1} R_t}_{\text{Regime 2 loading}} + \sum_{j=1}^L \Gamma_j \Delta X_{t-j} + \varepsilon_t$$

where $R_t = \mathbf{1}[ECT_{m,t-1} > \gamma]$ and $ECT_{\theta,t-1} = y_{t-1} - \hat{A}k^{CL}_{t-1} - \hat{B}c_{t-1} - \hat{C}\omega_{t-1}c_{t-1} - \hat{\kappa}_1$.

The only nonlinearity is in $\gamma$, which is searched over a grid.

---

## 4.2 Estimation sequence

**Step 1 — Fix β:** Estimate the linear Johansen VECM on the full sample.
Extract the y-normalized first eigenvector as $\hat{\beta}$. Construct
$\widehat{ECT}_{\theta,t}$. Verify stationarity (ADF test).

**Step 2 — Fix grid:** Set the threshold grid to the 10%–90% quantile range
of $\widehat{ECT}_{m,t-1}$, with 300 evenly spaced points. The 10% trimming
on each tail ensures each regime has at least 10 observations (N=105 × 0.10 = 10.5).

**Step 3 — Grid search:** For each $\gamma_j$ in the grid:
- Compute $R_t^{(j)} = \mathbf{1}[\widehat{ECT}_{m,t-1} > \gamma_j]$
- Construct regime-interacted regressors: $ECT_\theta \cdot (1-R_t^{(j)})$ and $ECT_\theta \cdot R_t^{(j)}$
- Run OLS on the stacked 4-equation system
- Store $\text{SSR}(\gamma_j)$

**Step 4 — Optimal threshold:** $\hat{\gamma} = \arg\min_j \text{SSR}(\gamma_j)$

**Step 5 — Re-estimate at $\hat{\gamma}$:** Final OLS produces $\hat{\alpha}^{(1)}$
and $\hat{\alpha}^{(2)}$ with standard errors.

---

## 4.3 Reading the SSR surface

The SSR surface plot (`stage2_ssr_grid.csv`) should show:

- A smooth, U-shaped or L-shaped surface with a clear minimum
- The minimum at $\hat{\gamma}$ somewhere between the pre-1973 ECT_m mean (≈0.06)
  and post-1973 mean (≈0.32) — reflecting that the threshold separates the two historical regimes
- No secondary local minima of similar depth (which would indicate identification ambiguity)

**Red flag:** If the SSR surface is flat with no clear minimum, the data do not
support threshold dynamics for the frontier system with ECT_m as the classifier.
Proceed to the linearity test and, if not rejected, report the linear VECM as
the baseline.

---

## 4.4 Regime classification — expected structure

Given the ECT_m time series structure (pre-1973 mean ≈ 0.06, post-1973 mean ≈ 0.32),
the expected regime classification is:

- **Regime 1 (BoP slack):** Predominantly pre-1973 observations (≈50–60 obs).
  ISI-era imports near structural equilibrium; $\lambda \approx 0$.
- **Regime 2 (BoP binding):** Predominantly post-1973 observations (≈40–50 obs).
  Persistent import disequilibrium; $\lambda > 0$ activates the shadow price penalty.

This regime structure is not imposed — it is recovered from the data via the
SSR-minimizing $\hat{\gamma}$. If the estimated classification is qualitatively
consistent with the historical narrative (ISI operating near equilibrium,
neoliberal period persistently above threshold), this is a validation of the
theoretical identification. If not, investigate.

---

## 4.5 The shadow price test: |α_y^(2)| < |α_y^(1)|

The output equation loading on ECT_θ in each regime:

- $\hat{\alpha}_y^{(1)}$: speed at which $y_t$ corrects to the productive frontier
  when BoP is slack ($\lambda = 0$). Theory: faster correction, more negative.
- $\hat{\alpha}_y^{(2)}$: speed of correction when BoP is binding ($\lambda > 0$).
  Theory: slower correction — the shadow price compresses the feasible mechanization
  path and thereby the rate at which actual output can converge to the frontier.

**Prediction:** $|\hat{\alpha}_y^{(2)}| < |\hat{\alpha}_y^{(1)}|$

This is the empirical signature of the BoP constraint operating through the Kaldor
mechanism as a ceiling: the same import-content structure that normally drives
structural import demand now limits how fast machinery can be added, slowing
frontier convergence.

**If not confirmed:** This is a structural finding, not an estimation failure.
Report it as: "The frontier adjustment speed is not compressed in the BoP-binding
regime." This would suggest the shadow price compresses a different variable
(check $\hat{\alpha}_{k^{CL}}^{(2)}$ vs $\hat{\alpha}_{k^{CL}}^{(1)}$ — the
compression may operate on capital accumulation rather than output directly).

---

## 4.6 Bootstrap linearity test

Null hypothesis: linear VECM ($\alpha^{(1)} = \alpha^{(2)}$).
Alternative: two-regime VECM with threshold at $\hat{\gamma}$.

**Test statistic:** $LR = T \cdot \ln(\text{SSR}_{\text{linear}} / \text{SSR}_{\text{min}})$

**Bootstrap:** Resample from linear VECM residuals (residual bootstrap, B=999).
For each bootstrap draw, re-run the full CLS grid search to construct the null
distribution of the LR statistic.

**Interpretation:**
- $p < 0.05$: Reject linearity; threshold dynamics confirmed. Report $\hat{\gamma}$,
  $\hat{\alpha}^{(1)}$, $\hat{\alpha}^{(2)}$ as primary results.
- $0.05 \leq p < 0.10$: Marginal evidence; report at 10% with caveat.
- $p \geq 0.10$: Fail to reject; report linear VECM as baseline. The $\hat{\theta}^{CL}$
  identification from Step 2 remains valid; only the regime-specific content of
  $\alpha^{(1)}$ vs $\alpha^{(2)}$ is not statistically confirmed.

---

## 4.7 Output files from this stage

| File | Content |
|------|---------|
| `stage2_ssr_grid.csv` | $\gamma$ grid and SSR values — for SSR surface plot |
| `stage2_regime_classification.csv` | Year, ECT_m, $R_t$, regime label |
| `stage2_alpha_loadings.csv` | $\hat{\alpha}^{(1)}$, $\hat{\alpha}^{(2)}$, SEs, t-stats, difference |
| `stage2_LR_bootstrap.csv` | Bootstrap null distribution of LR statistic |

---

*NB-04 | 2026-04-07 | Next: NB-05 (parameter recovery and θ̂^CL)*
