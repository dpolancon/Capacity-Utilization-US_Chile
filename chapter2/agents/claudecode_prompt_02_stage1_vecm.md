# Claude Code Prompt 2: Stage 1 VECM Estimation
## Chilean TVECM — Import Propensity Cointegration System

---

## CONTEXT

This is Stage 1 of a two-stage Threshold VECM. Stage 1 estimates the long-run
import propensity cointegration system and extracts the error correction term
$\widehat{ECT}_{m,t}$ that serves as the threshold transition variable for Stage 2.

**This script must only be run after the unit root crosswalk (Prompt 1) has been reviewed
and integration orders confirmed for all series.** If that crosswalk flags blockers
(I(2) series, phi as I(1)), do not proceed — halt and report.

**Assume integration orders from Prompt 1 verdict:** All state vector series I(1).
If this assumption is violated by Prompt 1 results, flag and halt.

**Panel file:**
```
C:\ReposGitHub\Capacity-Utilization-US_Chile\data\final\chile_tvecm_panel.csv
```

---

## THEORETICAL SPECIFICATION

### Long-run cointegrating relation (CV1)

$$m_t = \zeta_0 + \zeta_1 k_t^{ME} + \zeta_2 nrs_t + \zeta_3 \omega_t + ECT_{m,t}$$

where:
- $\zeta_1 > 0$: machinery accumulation raises structural import demand (Tavares channel)
- $\zeta_2 \gtrless 0$: net effect of non-reinvested surplus on BoP (no sign restriction; recovers Kaldor/Palma-Marcel)
- $\zeta_3$: wage share effect on imports (no strong prior)
- $ECT_{m,t}$: identifies externally-driven systemic imbalances (forex scarcity vs. luxury consumption)

The sign and relative magnitude of $\zeta_2$ vs $\zeta_1$ answers whether accumulation-relief or consumption-drain dominates.

### State vector

$$Y_t = (m_t,\; k_t^{ME},\; nrs_t,\; \omega_t)'$$

All in log levels except $\omega_t$ (wage share ratio, untransformed).

### Deterministic specification

- Restricted constant (Case 3 in Johansen taxonomy): constant enters the cointegrating space, no linear trend in levels.
- Structural break dummies `D1973`, `D1975` enter as **unrestricted** impulse dummies in the short-run dynamics (not in the cointegrating vector). This is the standard treatment — restricted dummies alter the asymptotic distribution of the trace test.

### Expected cointegrating rank

- Prior: r = 1 (one cointegrating vector = the import propensity relation).
- The 4-variable system with r = 1 implies 3 common stochastic trends — this is appropriate given that $k_t^{ME}$, $nrs_t$, and $\omega_t$ all drive nonstationary trends in imports.

---

## STEP-BY-STEP PROCEDURE

### Step 0: Setup and data load

```r
library(urca)      # ca.jo(), blrtest(), alrtest()
library(tsDyn)     # VECM() — for comparison and ECT extraction
library(vars)      # VAR() for lag selection, VARselect()
library(tidyverse)
library(knitr)     # kable() for clean output

# Load panel and restrict to estimation sample
df_raw <- read_csv("data/final/chile_tvecm_panel.csv")
df <- df_raw %>% filter(in_sample == TRUE)

# Confirm N=39 (1940–1978)
stopifnot(nrow(df) == 39)
stopifnot(all(df$year %in% 1940:1978))

# Extract state vector as matrix (ordered: m, k_ME, nrs, omega)
Y_mat <- df %>%
  select(m, k_ME, nrs, omega) %>%
  as.matrix()

rownames(Y_mat) <- df$year

# Break dummies (unrestricted — enter as exogenous in short-run)
dummies <- df %>% select(D1973, D1975) %>% as.matrix()
```

### Step 1: Lag order selection

Select lag order for the underlying VAR in levels. With N=39, keep maximum lags low (max = 3).

```r
# VAR in levels for lag selection
var_select <- VARselect(
  y       = Y_mat,
  lag.max = 3,
  type    = "const",
  exogen  = dummies
)

cat("\n=== VAR Lag Selection ===\n")
print(var_select$selection)   # AIC, HQ, SC, FPE selections
cat("\nFull criteria table:\n")
print(round(var_select$criteria, 3))

# Decision: prefer SC/BIC with small sample (N=39)
# Store selected lag for VECM (VECM lag = VAR lag - 1)
lag_var <- var_select$selection["SC(n)"]
lag_vecm <- max(1, lag_var - 1)
cat(sprintf("\nSelected VAR lag (SC): %d → VECM lag: %d\n", lag_var, lag_vecm))
```

Report all four criteria and justify the selection. With N=39, AIC will overfit — prefer SC.

### Step 2: Johansen cointegration test

Run the Johansen trace test and maximum eigenvalue test to determine cointegrating rank.

```r
# Johansen trace test — restricted constant (ecdet = "const" = Case 3)
jo_trace <- ca.jo(
  x      = Y_mat,
  type   = "trace",
  ecdet  = "const",
  K      = lag_var,         # VAR lag in levels
  spec   = "transitory",    # standard VECM parameterization
  dumvar = dummies
)

cat("\n=== Johansen Trace Test ===\n")
summary(jo_trace)

# Maximum eigenvalue test
jo_eigen <- ca.jo(
  x      = Y_mat,
  type   = "eigen",
  ecdet  = "const",
  K      = lag_var,
  spec   = "transitory",
  dumvar = dummies
)

cat("\n=== Johansen Max-Eigenvalue Test ===\n")
summary(jo_eigen)
```

**Report format for crosswalk:**

```
| H₀: r ≤ k | Trace stat | 1% CV | 5% CV | 10% CV | Decision |
|------------|------------|-------|-------|--------|----------|
| r ≤ 0      |            |       |       |        |          |
| r ≤ 1      |            |       |       |        |          |
| r ≤ 2      |            |       |       |        |          |
| r ≤ 3      |            |       |       |        |          |
```

Same table for max-eigenvalue.

**Decision rule:** Report r at the 5% level as baseline. Note if trace and max-eigen disagree — prefer trace in small samples. If r=0 is not rejected (no cointegration), **halt and flag as a blocker for the entire strategy.**

### Step 3: Estimate unrestricted VECM (r=1 baseline)

```r
# Impose r=1 based on Johansen test; estimate unrestricted VECM
vecm_unrestr <- cajorls(jo_trace, r = 1)

cat("\n=== Unrestricted VECM (r=1) ===\n")
cat("\nCointegrating vector (beta):\n")
print(round(vecm_unrestr$beta, 4))

cat("\nLoading matrix (alpha):\n")
print(round(vecm_unrestr$rlm$coefficients[1, ], 4))  # ECT loadings

cat("\nShort-run dynamics (Gamma matrices):\n")
print(summary(vecm_unrestr$rlm))
```

### Step 4: Sign check and economic interpretation

After extracting the cointegrating vector, check signs against theory:

```r
beta_raw <- vecm_unrestr$beta  # unnormalized cointegrating vector

# Normalize on m (first variable); extract coefficients
# Johansen normalization: beta[1,1] = 1, so beta[2:5] = -[zeta_1, zeta_2, zeta_3, zeta_0]
# Adjust sign convention to match theoretical equation m = zeta_0 + zeta_1*k_ME + ...

cat("\n=== Theoretical Sign Check ===\n")
cat("Expected: zeta_1 (k_ME) > 0 — Tavares channel\n")
cat("Expected: zeta_2 (nrs) unrestricted — Kaldor/Palma-Marcel\n")
cat("Expected: zeta_3 (omega) unrestricted\n\n")

# Extract and report with correct sign orientation
zeta <- -beta_raw[-1, 1] / beta_raw[1, 1]  # divide by normalization
names(zeta) <- c("k_ME (zeta_1)", "nrs (zeta_2)", "omega (zeta_3)", "const (zeta_0)")
print(round(zeta, 4))

# Flag sign violations
if (zeta["k_ME (zeta_1)"] < 0) {
  cat("⚠ WARNING: zeta_1 < 0 — Tavares channel sign reversed. Investigate.\n")
} else {
  cat("✓ zeta_1 > 0 — Tavares channel sign confirmed.\n")
}
```

### Step 5: Identification — test loading restrictions (alpha)

The import equation should show error-correction ($\alpha_m < 0$ — imports fall when ECT is positive, i.e., when imports exceed long-run equilibrium). Test this formally.

```r
# Extract alpha (loading) vector from unrestricted VECM
# alpha is a 4-element vector: [alpha_m, alpha_kME, alpha_nrs, alpha_omega]

# Convert ca.jo object to VAR for loading inspection
vecm_vars <- vec2var(jo_trace, r = 1)

cat("\n=== Loading Matrix (alpha) Inspection ===\n")
cat("Sign convention: alpha_m < 0 means imports error-correct (expected)\n")
cat("alpha_kME ≠ 0 means capital accumulation responds to import disequilibrium\n\n")

# Extract loadings manually from cajorls
alpha <- vecm_unrestr$rlm$coefficients["ect1", ]
print(round(alpha, 4))

# Flag
if (alpha["m"] >= 0) {
  cat("⚠ WARNING: alpha_m >= 0 — m does not error-correct. System may not be identified.\n")
} else {
  cat("✓ alpha_m < 0 — imports error-correct as expected.\n")
}
```

**Optional restriction tests using `blrtest()` and `alrtest()`:**

Test whether $k_t^{ME}$ and/or $\omega_t$ are weakly exogenous (loading = 0):

```r
# Test weak exogeneity of k_ME (H0: alpha_kME = 0)
H_weak_kME <- matrix(c(1,0,0,0, 0,0,0,0, 0,1,0,0, 0,0,1,0), nrow=4)
# blrtest on alpha: use alrtest() for loading restrictions
# alrtest(jo_trace, A = H_weak_kME, r = 1) — if available
# If alrtest not available, report manually from t-statistics of cajorls output
```

Report: χ² statistic and p-value for each weak exogeneity test. Weak exogeneity of $k_t^{ME}$ and $\omega_t$ would imply that the import disequilibrium does not feed back into capital accumulation or distribution — a defensible structural assumption in the short run.

### Step 6: Extract ECT_m as the threshold transition variable

This is the primary deliverable of Stage 1.

```r
# Extract the estimated ECT from the VECM residuals
# ECT_m,t = m_t - zeta_0 - zeta_1*k_ME_t - zeta_2*nrs_t - zeta_3*omega_t

# Method 1: From ca.jo fitted values
ECT_m <- jo_trace@RK[, 1]  # cointegrating residuals (check sign convention)

# Method 2: Construct directly from estimated beta
beta_norm <- jo_trace@V[, 1] / jo_trace@V[1, 1]  # normalize on m
ECT_m_direct <- Y_mat_with_const %*% beta_norm    # Y_mat extended with column of 1s

# Cross-check: correlation between both methods should be ~1.0
cat(sprintf("\nECT extraction methods correlation: %.6f\n",
            cor(ECT_m, ECT_m_direct, use="complete.obs")))

# Store ECT in a data frame with year index
ect_df <- data.frame(
  year  = df$year,
  ECT_m = as.numeric(ECT_m_direct)
)

# Save for Stage 2
write_csv(ect_df, "data/processed/chile/ECT_m_stage1.csv")
cat("\nECT_m saved to: data/processed/chile/ECT_m_stage1.csv\n")
```

### Step 7: VECM diagnostic tests

```r
# Residual diagnostics from VAR representation
vecm_var_obj <- vec2var(jo_trace, r = 1)

cat("\n=== Residual Diagnostics ===\n")

# 1. Portmanteau test (no serial correlation in residuals)
pt <- serial.test(vecm_var_obj, lags.pt = 10, type = "PT.adjusted")
cat("\nPortmanteau (H0: no serial correlation):\n")
print(pt)

# 2. ARCH test (no conditional heteroskedasticity)
arch_t <- arch.test(vecm_var_obj, lags.multi = 5)
cat("\nARCH-LM test:\n")
print(arch_t)

# 3. Normality test (Jarque-Bera on residuals)
norm_t <- normality.test(vecm_var_obj)
cat("\nJarque-Bera normality test:\n")
print(norm_t)

# 4. CUSUM stability test on each equation
# (use strucchange package if available)
# cusum_test <- efp(resid(vecm_unrestr$rlm)[,1] ~ 1, type="OLS-CUSUM")
# plot(cusum_test)
```

Flag any violations. Serial correlation failure with N=39 often indicates under-specified lag structure — try increasing lag by 1 and re-run Step 2.

### Step 8: Crosswalk summary for chat

Compile all results into a single structured crosswalk table and print to console:

```r
cat("\n\n")
cat("================================================================\n")
cat("    STAGE 1 VECM — ESTIMATION CROSSWALK SUMMARY\n")
cat("================================================================\n\n")

cat("--- Lag Selection ---\n")
cat(sprintf("VAR lag selected (SC): %d | VECM lag: %d\n\n", lag_var, lag_vecm))

cat("--- Johansen Trace Test ---\n")
# Print formatted rank test table

cat("--- Cointegrating Vector (normalized on m) ---\n")
cat(sprintf("m_t = %.4f + %.4f*k_ME + %.4f*nrs + %.4f*omega + ECT_m\n",
    zeta["const (zeta_0)"], zeta["k_ME (zeta_1)"],
    zeta["nrs (zeta_2)"], zeta["omega (zeta_3)"]))

cat("\n--- Sign Check ---\n")
cat(sprintf("zeta_1 (k_ME):  %.4f  [Expected >0: Tavares]\n", zeta["k_ME (zeta_1)"]))
cat(sprintf("zeta_2 (nrs):   %.4f  [Expected unrestricted: Kaldor/Palma-Marcel]\n", zeta["nrs (zeta_2)"]))
cat(sprintf("zeta_3 (omega): %.4f  [Expected unrestricted]\n", zeta["omega (zeta_3)"]))

cat("\n--- Loading Matrix (alpha) ---\n")
cat(sprintf("alpha_m:     %.4f  [Expected <0: error-corrects]\n", alpha["m"]))
cat(sprintf("alpha_kME:   %.4f\n", alpha["k_ME"]))
cat(sprintf("alpha_nrs:   %.4f\n", alpha["nrs"]))
cat(sprintf("alpha_omega: %.4f\n", alpha["omega"]))

cat("\n--- Diagnostics ---\n")
cat(sprintf("Portmanteau p-value: %.4f  [>0.05 = OK]\n", pt$serial$p.value))
cat(sprintf("ARCH p-value:        %.4f  [>0.05 = OK]\n", arch_t$arch.mul$p.value))

cat("\n--- ECT_m ---\n")
cat(sprintf("Saved to: data/processed/chile/ECT_m_stage1.csv\n"))
cat(sprintf("ECT_m range [1940–1978]: [%.4f, %.4f]\n",
    min(ect_df$ECT_m), max(ect_df$ECT_m)))
cat(sprintf("ECT_m std dev: %.4f\n", sd(ect_df$ECT_m)))
cat("================================================================\n")
```

---

## CONTINGENCY PROTOCOLS

### If Johansen finds r=0 (no cointegration)
**HALT.** Do not extract ECT. The entire two-stage strategy depends on cointegration in Stage 1. Options:
1. Re-run with different lag specification
2. Re-run with different sample (1945–1975, excluding post-coup)
3. Re-run with restricted constant vs. no constant to check sensitivity
4. Flag as a blocking result and escalate to dissertation committee

### If Johansen finds r=2 or r=3
This is not a blocker but requires interpretation. With r>1, there are multiple long-run relations:
- If r=2: a second cointegrating vector exists — report its coefficients; assess whether it represents a spurious relation or a genuine additional long-run tie (e.g., a machinery-NRS composition relation)
- Use the first eigenvector (highest eigenvalue) as ECT_m for Stage 2 — this is the dominant long-run attractor
- Flag for robustness check using the second eigenvector as an alternative transition variable

### If zeta_1 (k_ME) < 0
The Tavares channel sign is reversed — machinery accumulation reduces imports. This contradicts the theoretical prior ($\xi^{ME}_K \approx 0.92$). Investigate:
1. Check units consistency (both m_t and k_ME in 2003 CLP?)
2. Check whether k_ME is driving rather than adjusting (test weak exogeneity of k_ME)
3. Report as an anomalous finding, do not suppress

### If serial correlation test fails
1. Increase VECM lag by 1 (re-run from Step 2)
2. Add additional exogenous controls (tot, pcu) to the short-run dynamics
3. If still failing at lag 3: accept with caveat — N=39 limits test power significantly

---

## OUTPUTS

1. `codes/stage_a/chile/02_stage1_vecm.R` — fully documented estimation script
2. `data/processed/chile/ECT_m_stage1.csv` — the ECT series (year + ECT_m)
3. `output/diagnostics/stage1_vecm_crosswalk.md` — formatted crosswalk for this chat
4. `output/tables/stage1_cointegrating_vector.tex` — LaTeX table of the CV1 coefficients
5. Console: print full crosswalk summary (Section of Step 8)

---

## NOTATION LOCK (from CLAUDE.md — enforce throughout)

- `m` = imports (log real); NEVER use `m` for mechanization rate in code comments
- `omega` = wage share ω; `pi_share` = profit share π (avoid variable name `pi` — reserved in R)
- `mu` = capacity utilization (Y/Y^p); never "u"
- `chi` = recapitalization rate (I/Π); never "beta"
- Capital stocks: `K_NR` = nonresidential structures; `K_ME` = machinery & equipment
- All capital stocks: GROSS unless explicitly noted
- `ECT_m` = error correction term from Stage 1; `ECT_theta` = from Stage 2

---

*Prompt version: 2026-04-06. Stage 1 VECM on (m, k_ME, nrs, omega). Sample: 1940–1978 (N=39). Packages: urca, vars, tsDyn. Repo: dpolancon/Capacity-Utilization-US_Chile.*
