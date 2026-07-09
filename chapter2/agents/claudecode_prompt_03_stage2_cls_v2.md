# Claude Code Prompt 03 v2: Stage 2 — CLS Threshold VECM
## Reparameterized State Vector + Full Unit Root Battery
## Central object: θ̂^CL(ω_t, φ_t) = θ̂_0 + ψ̂φ_t + θ̂_2 ω_t φ_t

---

## PRIMARY IDENTIFICATION GOAL

Every step in this script exists to arrive at one object:

$$\boxed{\hat{\theta}^{CL}(\omega_t, \phi_t) = \hat{\theta}_0 + \hat{\psi}\,\phi_t + \hat{\theta}_2\,\omega_t\phi_t}$$

This is the distribution-and-composition-conditioned transformation elasticity of the Chilean
productive frontier. It is the peripheral empirical counterpart of §3.5 in the analytical
framework: the object that translates capital accumulation into productive-capacity growth
under the BoP constraint, and whose regime-specific recovery from the CLS threshold VECM
is the chapter's main empirical contribution for Chile.

The identification chain is:

```
Stage 1 VECM → ECT_m (proxy for λ) → regime classifier R_t
    ↓
Stage 2 CLS-TVECM → CV1 coefficients (A, B, C)
    ↓
Parameter recovery: θ_0 = A−B, ψ = A+B, θ_2 = 2C
    ↓
θ̂^CL(ω_t, φ_t) = θ̂_0 + ψ̂ φ_t + θ̂_2 ω_t φ_t
    ↓
g_{Y^p,CL} = θ̂^CL(ω_t, φ_t) · g_{K^CL}
    ↓
μ̂^CL(t_0 = 1980) = 1.0  →  μ̂^CL series
```

---

## ARCHITECTURAL MOTIVATION: WHY THIS STATE VECTOR

### The collinearity problem with the original state vector

The original vector $X_t = (y_t, k_t^{NR}, k_t^{ME}, \omega_t k_t^{ME})'$ has a structural
collinearity: $k^{NR}$ and $k^{ME}$ share a common I(1) stochastic trend driven by aggregate
capital accumulation. By the choice-of-technique relation in §3.5, the two capital stocks
move together in the long run — ISI-era machinery and infrastructure are jointly accumulated.
Their correlation produces near-multicollinearity in the cointegrating vector, making separate
identification of $\theta_0$ and $\psi$ unreliable, even though the linear combination
$\theta_0 k^{NR} + \psi k^{ME}$ (the productive frontier) may be well-identified.

### The sum-and-difference reparameterization

Define:

$$k_t^{CL} = \ln(K_t^{NR} + K_t^{ME})  \quad \text{(common capital trend, I(1))}$$

$$c_t = k_t^{ME} - k_t^{NR} = \ln\!\left(\frac{K_t^{ME}}{K_t^{NR}}\right)  \quad \text{(log-composition ratio)}$$

These are orthogonal by construction: $k^{CL}$ captures aggregate scale; $c_t$ captures
relative composition — how far accumulation has shifted toward machinery versus infrastructure.

**Reparameterized state vector:**

$$X_t^{CL,\theta} = \left(y_t,\; k_t^{CL},\; c_t,\; \omega_t c_t\right)'$$

**CV1 — Capacity frontier:**

$$y_t = \kappa_1 + A\,k_t^{CL} + B\,c_t + C\,(\omega_t c_t) + ECT_{\theta,t}$$

**Exact parameter recovery** (from substituting $k^{NR} = (k^{CL}-c_t)/2$,
$k^{ME} = (k^{CL}+c_t)/2$ into the original frontier):

| Estimated | Structural | Economic content |
|-----------|-----------|-----------------|
| $A = (\theta_0+\psi)/2$ | $\theta_0 = A - B$ | Infrastructure elasticity |
| $B = (\psi-\theta_0)/2$ | $\psi = A + B$ | Machinery elasticity |
| $C = \theta_2/2$ | $\theta_2 = 2C$ | Distribution-composition interaction |

**Sign priors from §3.5:**
- $A > 0$: aggregate capital contributes positively to productive capacity
- $B > 0$: machinery has higher productivity than infrastructure ($\psi > \theta_0$) — **Kaldor hypothesis**
- $C < 0$: higher wage share compresses the composition-machinery channel ($\theta_2 < 0$)

**The post-estimation identification object:**

$$\hat{\theta}^{CL}(\omega_t, \phi_t) = \hat{\theta}_0 + \hat{\psi}\,\phi_t + \hat{\theta}_2\,\omega_t\phi_t$$

where $\phi_t = K_t^{ME}/K_t^{CL}$ (machinery share of total non-residential capital stock,
in levels — not log). This is equation (27) of §3.5, recovered from the reparameterized
VECM coefficients.

---

## PREREQUISITE INPUTS

```
data/final/chile_tvecm_panel.csv          — full panel (N=105, 1920-2024)
data/processed/chile/ECT_m_stage1.csv     — ECT_m from Stage 1 (year, ECT_m, regime)
```

Variables needed from panel (confirm column names before running):
- `y`       — log real GDP
- `k_NR`    — log gross non-residential capital stock (2003 CLP)
- `k_ME`    — log gross machinery & equipment stock (2003 CLP)
- `omega`   — wage share (ratio, not log)
- `phi`     — K_ME / K_total composition share (levels ratio)
- `D1973`, `D1975` — impulse dummies

---

## STEP 0: SETUP, DATA LOAD, AND VARIABLE CONSTRUCTION

```r
library(urca)       # ca.jo(), cajorls(), ur.df(), ur.kpss(), ur.za()
library(vars)       # VARselect()
library(tidyverse)
library(sandwich)   # HAC standard errors
library(strucchange) # for Zivot-Andrews if ur.za() unavailable

# ---- Load panel
df <- read_csv("data/final/chile_tvecm_panel.csv") %>%
  arrange(year)

# ---- Load Stage 1 ECT_m
ect_s1 <- read_csv("data/processed/chile/ECT_m_stage1.csv") %>%
  arrange(year) %>%
  mutate(ECT_m_lag1 = lag(ECT_m, 1))

df <- df %>%
  left_join(ect_s1 %>% select(year, ECT_m, ECT_m_lag1), by = "year")

# ================================================================
# REPARAMETERIZED STATE VECTOR CONSTRUCTION
# ================================================================

df <- df %>%
  mutate(
    # Aggregate capital trend: log(K_NR_levels + K_ME_levels)
    # k_NR and k_ME are log series → need to exp() first
    k_CL     = log(exp(k_NR) + exp(k_ME)),

    # Log-composition ratio: ln(K_ME / K_NR) = k_ME - k_NR
    c_t      = k_ME - k_NR,

    # Distributional-composition interaction
    omega_c  = omega * c_t
  )

cat("=== Reparameterized Variables Summary ===\n")
cat(sprintf("k_CL:    mean=%.4f, sd=%.4f, range=[%.4f, %.4f]\n",
    mean(df$k_CL, na.rm=T), sd(df$k_CL, na.rm=T),
    min(df$k_CL, na.rm=T), max(df$k_CL, na.rm=T)))
cat(sprintf("c_t:     mean=%.4f, sd=%.4f, range=[%.4f, %.4f]\n",
    mean(df$c_t, na.rm=T), sd(df$c_t, na.rm=T),
    min(df$c_t, na.rm=T), max(df$c_t, na.rm=T)))
cat(sprintf("omega_c: mean=%.4f, sd=%.4f, range=[%.4f, %.4f]\n",
    mean(df$omega_c, na.rm=T), sd(df$omega_c, na.rm=T),
    min(df$omega_c, na.rm=T), max(df$omega_c, na.rm=T)))

# Verify collinearity reduction
cat(sprintf("\nCorrelation check:\n"))
cat(sprintf("  cor(k_NR, k_ME)  = %.4f  [OLD — should be high]\n",
    cor(df$k_NR, df$k_ME, use="complete")))
cat(sprintf("  cor(k_CL, c_t)   = %.4f  [NEW — should be much lower]\n",
    cor(df$k_CL, df$c_t, use="complete")))

# ---- State vector matrix (levels, for Johansen)
Y_levels <- df %>%
  select(y, k_CL, c_t, omega_c) %>%
  as.matrix()
rownames(Y_levels) <- df$year

# ---- Dummies
D_mat <- df %>%
  select(D1973, D1975) %>%
  as.matrix()
```

---

## STEP 1: FULL UNIT ROOT BATTERY — ALL STATE VECTOR VARIABLES

Run the complete battery for $y_t$, $k_t^{CL}$, $c_t$, $\omega_t c_t$, and also
$c_t$ in first differences. The integration order of $c_t$ is the critical unknown:
if $c_t \sim I(0)$, the state vector collapses to a bivariate system $(y_t, k_t^{CL})$
with $c_t$ as a conditioning variable; if $c_t \sim I(1)$, the 4-variable system is valid.

```r
# ---- Utility function: run full battery on a single series
run_ur_battery <- function(series, series_name, max_lags=4) {
  x <- na.omit(series)
  cat(sprintf("\n--- Unit Root Battery: %s (N=%d) ---\n", series_name, length(x)))

  results <- list()

  # 1. ADF with drift
  adf_d <- ur.df(x, type="drift", selectlags="BIC", lags=max_lags)
  adf_tau <- adf_d@teststat[1]
  cat(sprintf("ADF (drift, BIC): tau = %.4f  [5%%CV: %.4f]\n",
      adf_tau, adf_d@cval[1,2]))
  results$adf_tau  <- adf_tau
  results$adf_5pct <- adf_d@cval[1,2]
  results$adf_rej  <- adf_tau < adf_d@cval[1,2]

  # 2. Phillips-Perron
  pp <- ur.pp(x, type="Z-tau", model="constant", lags="short")
  pp_stat <- pp@teststat
  cat(sprintf("PP (Z-tau):       stat = %.4f  [5%%CV: %.4f]\n",
      pp_stat, pp@cval[2]))
  results$pp_stat  <- pp_stat
  results$pp_rej   <- pp_stat < pp@cval[2]

  # 3. KPSS level stationarity
  kpss_mu <- ur.kpss(x, type="mu", lags="short")
  kpss_stat <- kpss_mu@teststat
  cat(sprintf("KPSS (mu):        stat = %.4f  [5%%CV: 0.463]\n", kpss_stat))
  results$kpss_stat <- kpss_stat
  results$kpss_rej  <- kpss_stat > 0.463  # 5% CV for mu specification

  # 4. ADF on first differences (null: I(2))
  dx <- diff(x)
  adf_d1 <- ur.df(dx, type="drift", selectlags="BIC", lags=max_lags)
  adf_d1_tau <- adf_d1@teststat[1]
  cat(sprintf("ADF on Δ:         tau = %.4f  [5%%CV: %.4f]  → confirms I(1) if rejects\n",
      adf_d1_tau, adf_d1@cval[1,2]))
  results$adf_d1_tau <- adf_d1_tau
  results$adf_d1_rej <- adf_d1_tau < adf_d1@cval[1,2]

  # 5. Zivot-Andrews structural break
  tryCatch({
    za <- ur.za(x, model="both", lag=max_lags)
    za_stat  <- za@teststat
    za_break <- za@bpoint
    cat(sprintf("Zivot-Andrews:    tau = %.4f  [5%%CV: -5.08]  break at t=%d (yr=%d)\n",
        za_stat, za_break,
        as.integer(rownames(Y_levels)[za_break + 1])))
    results$za_stat  <- za_stat
    results$za_break <- za_break
    results$za_rej   <- za_stat < -5.08
  }, error=function(e) {
    cat(sprintf("Zivot-Andrews: error — %s\n", e$message))
  })

  # ---- Verdict
  n_rej_unit <- sum(c(results$adf_rej, results$pp_rej), na.rm=TRUE)
  kpss_rej   <- results$kpss_rej
  if (n_rej_unit >= 2 & !kpss_rej) {
    verdict <- "I(0) — stationary"
  } else if (n_rej_unit == 0 & kpss_rej & results$adf_d1_rej) {
    verdict <- "I(1) — confirmed"
  } else if (n_rej_unit == 0 & kpss_rej & !results$adf_d1_rej) {
    verdict <- "I(2) — investigate"
  } else {
    verdict <- "BORDERLINE — see notes"
  }
  cat(sprintf(">>> VERDICT: %s\n", verdict))
  results$verdict <- verdict
  invisible(results)
}

# ---- Run battery on all variables
cat("\n================================================================\n")
cat("       UNIT ROOT BATTERY — STAGE 2 STATE VECTOR\n")
cat("================================================================\n")

ur_y       <- run_ur_battery(df$y,       "y (log GDP)")
ur_kCL     <- run_ur_battery(df$k_CL,    "k_CL (log total K)")
ur_ct      <- run_ur_battery(df$c_t,     "c_t (log-composition ratio)")
ur_omegac  <- run_ur_battery(df$omega_c, "omega_c (omega × c_t)")
ur_omega   <- run_ur_battery(df$omega,   "omega (wage share — conditioning)")
ur_phi     <- run_ur_battery(df$phi,     "phi (K_ME/K_total — for post-estimation)")

# ---- Integration order crosswalk
cat("\n=== Integration Order Crosswalk ===\n")
cat(sprintf("%-20s %-8s %-8s %-8s %-8s %-20s\n",
    "Variable", "ADF", "PP", "KPSS", "Δ-ADF", "Verdict"))
for (nm in list(
  list("y",       ur_y),
  list("k_CL",    ur_kCL),
  list("c_t",     ur_ct),
  list("omega_c", ur_omegac),
  list("omega",   ur_omega),
  list("phi",     ur_phi)
)) {
  r <- nm[[2]]
  cat(sprintf("%-20s %-8s %-8s %-8s %-8s %-20s\n",
      nm[[1]],
      ifelse(isTRUE(r$adf_rej),   "rej",  "fail"),
      ifelse(isTRUE(r$pp_rej),    "rej",  "fail"),
      ifelse(isTRUE(r$kpss_rej),  "rej",  "fail"),
      ifelse(isTRUE(r$adf_d1_rej),"rej",  "fail"),
      r$verdict))
}

# ================================================================
# CRITICAL DECISION GATE: Integration order of c_t
# ================================================================
cat("\n=== CRITICAL GATE: c_t integration order ===\n")
if (ur_ct$verdict == "I(0) — stationary") {
  cat("c_t is I(0): BIVARIATE SYSTEM — use (y, k_CL) only.\n")
  cat("c_t and omega_c enter as I(0) conditioning regressors.\n")
  cat("Proceed with 2-variable Johansen + DOLS for composition terms.\n")
  system_type <- "bivariate"
} else if (ur_ct$verdict == "I(1) — confirmed") {
  cat("c_t is I(1): FULL 4-VARIABLE SYSTEM — proceed as specified.\n")
  system_type <- "4variable"
} else {
  cat("c_t is BORDERLINE — proceed with 4-variable system (conservative).\n")
  cat("Report borderline result explicitly. Sensitivity with bivariate in appendix.\n")
  system_type <- "4variable"
}
```

---

## STEP 2: LAG SELECTION AND LINEAR VECM BASELINE

```r
cat("\n=== VAR Lag Selection ===\n")
var_sel <- VARselect(Y_levels, lag.max=3, type="const", exogen=D_mat)
print(var_sel$selection)
K_var  <- var_sel$selection["SC(n)"]
L_vecm <- max(1, K_var - 1)
cat(sprintf("VAR lag (SC): %d → VECM lag: %d\n", K_var, L_vecm))

# ---- Johansen rank test
jo_full <- ca.jo(
  x      = Y_levels,
  type   = "trace",
  ecdet  = "const",
  K      = K_var,
  spec   = "transitory",
  dumvar = D_mat
)

cat("\n=== Johansen Trace Test ===\n")
summary(jo_full)

# ---- Linear VECM at r=1
vecm_lin     <- cajorls(jo_full, r=1)
beta_raw     <- vecm_lin$beta   # normalized: beta[1,1] = 1
coef_raw_rlm <- coef(vecm_lin$rlm)

cat("\n=== CV1 — Raw Johansen Coefficients (y-normalized) ===\n")
# In Johansen output: y=1, then -A (k_CL), -B (c_t), -C (omega_c), -intercept
A_hat   <- -beta_raw["k_CL.l1",   1]
B_hat   <- -beta_raw["c_t.l1",    1]
C_hat   <- -beta_raw["omega_c.l1",1]
kappa_1 <- -beta_raw["constant",  1]

cat(sprintf("  A (k_CL):   %+.4f\n", A_hat))
cat(sprintf("  B (c_t):    %+.4f\n", B_hat))
cat(sprintf("  C (omega_c):%+.4f\n", C_hat))
cat(sprintf("  intercept:  %+.4f\n", kappa_1))

# ================================================================
# PARAMETER RECOVERY: θ_0, ψ, θ_2 from (A, B, C)
# ================================================================
cat("\n================================================================\n")
cat("  STRUCTURAL PARAMETER RECOVERY\n")
cat("================================================================\n")

theta_0_hat <- A_hat - B_hat        # infrastructure elasticity
psi_hat     <- A_hat + B_hat        # machinery elasticity
theta_2_hat <- 2 * C_hat            # distribution-composition interaction

cat(sprintf("theta_0 = A - B = %.4f - %.4f = %.4f  [Expected > 0]\n",
    A_hat, B_hat, theta_0_hat))
cat(sprintf("psi     = A + B = %.4f + %.4f = %.4f  [Expected > 0; Kaldor: psi > theta_0]\n",
    A_hat, B_hat, psi_hat))
cat(sprintf("theta_2 = 2C   = 2×(%.4f)  = %.4f  [Expected < 0]\n",
    C_hat, theta_2_hat))
cat(sprintf("Machinery premium (psi - theta_0): %.4f  [Expected > 0]\n",
    psi_hat - theta_0_hat))

# Sign checks
if (theta_0_hat <= 0) warning("theta_0 <= 0: infrastructure reduces capacity. Investigate.")
if (psi_hat    <= 0) warning("psi <= 0: no machinery productivity. Investigate.")
if (theta_2_hat >= 0) warning("theta_2 >= 0: wrong sign on distribution-composition term.")
if (psi_hat > theta_0_hat) {
  cat("✓ Kaldor hypothesis confirmed: machinery elasticity > infrastructure elasticity.\n")
} else {
  cat("⚠ Kaldor hypothesis NOT confirmed: psi <= theta_0.\n")
}

# ---- ECT_theta (frontier disequilibrium in reparameterized space)
ECT_theta <- Y_levels %*% beta_raw[1:4, 1] + beta_raw["constant", 1]
ECT_theta_lag1 <- c(NA, head(ECT_theta, -1))

adf_ect <- ur.df(na.omit(ECT_theta), type="drift", selectlags="BIC", lags=4)
cat(sprintf("\nADF on ECT_theta: tau=%.4f [5%%CV: %.4f]  → %s\n",
    adf_ect@teststat[1], adf_ect@cval[1,2],
    ifelse(adf_ect@teststat[1] < adf_ect@cval[1,2], "STATIONARY ✓", "NOT STATIONARY ⚠")))
```

---

## STEP 3: POST-ESTIMATION IDENTIFICATION OBJECT θ̂^CL(ω_t, φ_t)

**Compute $\hat{\theta}^{CL}$ immediately after recovering structural parameters.**
This is the central identification object. All subsequent steps serve to attach
regime-specific content to it.

```r
cat("\n================================================================\n")
cat("  CENTRAL IDENTIFICATION: θ̂^CL(ω_t, φ_t)\n")
cat("================================================================\n")

# From §3.5 equation (27):
# θ̂^CL(ω_t, φ_t) = θ̂_0 + ψ̂ φ_t + θ̂_2 ω_t φ_t
# where φ_t = K_ME / K_CL (levels ratio, not log)

theta_CL_t <- theta_0_hat + psi_hat * df$phi + theta_2_hat * df$omega * df$phi

cat("θ̂^CL(ω_t, φ_t) = θ̂_0 + ψ̂ φ_t + θ̂_2 ω_t φ_t\n")
cat(sprintf("               = %.4f + %.4f × φ_t + (%.4f) × ω_t φ_t\n",
    theta_0_hat, psi_hat, theta_2_hat))

# Summary statistics
cat(sprintf("\nθ̂^CL summary: mean=%.4f, sd=%.4f, range=[%.4f, %.4f]\n",
    mean(theta_CL_t, na.rm=T), sd(theta_CL_t, na.rm=T),
    min(theta_CL_t, na.rm=T), max(theta_CL_t, na.rm=T)))

# Period averages (key for narrative)
periods <- list(
  "Pre-ISI    (1920-1939)" = c(1920,1939),
  "ISI        (1940-1972)" = c(1940,1972),
  "Crisis     (1973-1982)" = c(1973,1982),
  "Neoliberal (1983-2024)" = c(1983,2024)
)
cat("\nPeriod averages of θ̂^CL:\n")
for (nm in names(periods)) {
  yr <- periods[[nm]]
  idx <- df$year >= yr[1] & df$year <= yr[2]
  cat(sprintf("  %-30s: %.4f\n", nm, mean(theta_CL_t[idx], na.rm=T)))
}

# Harrodian knife-edge: θ̂^CL = 1
# Solve: θ_0 + ψ φ + θ_2 ω φ = 1 → φ_H(ω) = (1 - θ_0) / (ψ + θ_2 ω)
phi_H_at_mean_omega <- (1 - theta_0_hat) / (psi_hat + theta_2_hat * mean(df$omega, na.rm=T))
cat(sprintf("\nHarrodian knife-edge: φ_H(ω̄) = %.4f\n", phi_H_at_mean_omega))
cat(sprintf("Interpretation: at mean wage share, the frontier is neutral (θ̂=1)\n"))
cat(sprintf("when machinery share = %.1f%% of total capital\n", 100*phi_H_at_mean_omega))

# Years above/below knife-edge
n_above <- sum(theta_CL_t > 1, na.rm=T)
n_below <- sum(theta_CL_t < 1, na.rm=T)
cat(sprintf("Years above Harrodian (θ>1, super-Harrodian): %d (%.1f%%)\n",
    n_above, 100*n_above/(n_above+n_below)))
cat(sprintf("Years below Harrodian (θ<1, sub-Harrodian):   %d (%.1f%%)\n",
    n_below, 100*n_below/(n_above+n_below)))
```

---

## STEP 4: REGIME DATA MATRIX CONSTRUCTION

```r
# ---- First differences for CLS
dY <- diff(Y_levels)
n  <- nrow(dY)
yrs_diff <- df$year[-1]

build_regressor_matrix <- function(dY, ECT_theta_lag1, ECT_m_lag1,
                                   D_mat, L, df_years) {
  n <- nrow(dY)
  if (L > 0) {
    lag_blocks <- lapply(1:L, function(j) dY[(L-j+1):(n-j), , drop=FALSE])
    lag_matrix <- do.call(cbind, lag_blocks)
    colnames(lag_matrix) <- paste0(
      rep(colnames(dY), L), ".L", rep(1:L, each=ncol(dY)))
  } else {
    lag_matrix <- matrix(nrow=n-L, ncol=0)
  }
  t_range <- (L+1):n
  T_est   <- length(t_range)
  ECT_th_est <- ECT_theta_lag1[(t_range+1)]
  ECT_m_est  <- ECT_m_lag1[(t_range+1)]
  D_est      <- D_mat[(t_range+1), , drop=FALSE]
  dY_est     <- dY[t_range, , drop=FALSE]
  lag_est    <- lag_matrix[t_range - L, , drop=FALSE]
  list(dY=dY_est, ECT_th=ECT_th_est, ECT_m=ECT_m_est,
       lags=lag_est, dummies=D_est, T_est=T_est)
}

reg_data <- build_regressor_matrix(dY, ECT_theta_lag1, df$ECT_m_lag1,
                                   D_mat, L_vecm, df$year)
cat(sprintf("Estimation sample: T=%d\n", reg_data$T_est))
```

---

## STEP 5: CLS GRID SEARCH — THRESHOLD γ̂ IDENTIFICATION

```r
cat("\n================================================================\n")
cat("  CLS GRID SEARCH: SSR-minimizing threshold γ̂\n")
cat("================================================================\n")

trim_pct   <- 0.10
gamma_grid <- unique(quantile(reg_data$ECT_m, probs=seq(trim_pct,1-trim_pct,length=300),
                              na.rm=TRUE))
cat(sprintf("Grid: %d candidates, range [%.4f, %.4f]\n",
    length(gamma_grid), min(gamma_grid), max(gamma_grid)))

compute_ssr <- function(gamma, reg_data) {
  R_t    <- as.integer(reg_data$ECT_m > gamma)
  ECT_r1 <- reg_data$ECT_th * (1 - R_t)
  ECT_r2 <- reg_data$ECT_th * R_t
  X_reg  <- cbind(ECT_r1=ECT_r1, ECT_r2=ECT_r2,
                  reg_data$lags, reg_data$dummies, const=1)
  valid  <- complete.cases(X_reg, reg_data$dY)
  if (sum(valid) < ncol(X_reg)+2) return(Inf)
  X_v <- X_reg[valid,,drop=FALSE]; Y_v <- reg_data$dY[valid,,drop=FALSE]
  cf  <- solve(crossprod(X_v), crossprod(X_v, Y_v))
  sum((Y_v - X_v %*% cf)^2)
}

ssr_grid      <- vapply(gamma_grid, compute_ssr, reg_data=reg_data, FUN.VALUE=numeric(1))
gamma_hat_idx <- which.min(ssr_grid)
gamma_hat     <- gamma_grid[gamma_hat_idx]
ssr_min       <- ssr_grid[gamma_hat_idx]

cat(sprintf("\nγ̂ = %.4f  (SSR = %.6f)\n", gamma_hat, ssr_min))
cat(sprintf("Interpretation: BoP constraint activates when ECT_m > %.4f\n", gamma_hat))

plot(gamma_grid, ssr_grid, type="l", lwd=2,
     xlab="Candidate threshold (γ)", ylab="SSR",
     main=sprintf("CLS Grid Search | γ̂ = %.4f", gamma_hat))
abline(v=gamma_hat, col="red", lty=2, lwd=2)
legend("topright", sprintf("γ̂ = %.3f", gamma_hat), col="red", lty=2, lwd=2)
```

---

## STEP 6: ESTIMATION AT γ̂ — REGIME-SPECIFIC LOADINGS

```r
R_t_opt  <- as.integer(reg_data$ECT_m > gamma_hat)
n_r1     <- sum(R_t_opt==0, na.rm=T)
n_r2     <- sum(R_t_opt==1, na.rm=T)

cat(sprintf("\nRegime 1 (BoP slack,   ECT_m ≤ %.4f): N=%d (%.1f%%)\n",
    gamma_hat, n_r1, 100*n_r1/(n_r1+n_r2)))
cat(sprintf("Regime 2 (BoP binding, ECT_m > %.4f): N=%d (%.1f%%)\n",
    gamma_hat, n_r2, 100*n_r2/(n_r1+n_r2)))

yrs_r2 <- yrs_diff[reg_data$ECT_m > gamma_hat & !is.na(reg_data$ECT_m)]
cat(sprintf("Regime 2 years: %s\n", paste(sort(yrs_r2), collapse=", ")))

ECT_r1_opt <- reg_data$ECT_th * (1 - R_t_opt)
ECT_r2_opt <- reg_data$ECT_th * R_t_opt

X_final    <- cbind(ECT_r1=ECT_r1_opt, ECT_r2=ECT_r2_opt,
                    reg_data$lags, reg_data$dummies, const=1)
valid_fin  <- complete.cases(X_final, reg_data$dY)
X_fin      <- X_final[valid_fin,,drop=FALSE]
Y_fin      <- reg_data$dY[valid_fin,,drop=FALSE]
T_fin      <- nrow(X_fin); k_p <- ncol(X_fin)

coef_fin   <- solve(crossprod(X_fin), crossprod(X_fin, Y_fin))
resid_fin  <- Y_fin - X_fin %*% coef_fin

se_mat <- matrix(NA, k_p, 4, dimnames=list(rownames(coef_fin), colnames(Y_fin)))
for (eq in 1:4) {
  s2 <- sum(resid_fin[,eq]^2)/(T_fin-k_p)
  se_mat[,eq] <- sqrt(diag(solve(crossprod(X_fin)))*s2)
}
t_mat <- coef_fin / se_mat

cat("\n=== Regime-Specific ECT Loadings ===\n")
cat(sprintf("%-12s %10s %10s %10s %10s\n",
    "Equation", "α^(1)", "α^(2)", "|α^(2)|<|α^(1)|", "diff"))
for (eq in colnames(Y_fin)) {
  a1 <- coef_fin["ECT_r1", eq]
  a2 <- coef_fin["ECT_r2", eq]
  cat(sprintf("%-12s %+10.4f %+10.4f %-15s %+10.4f\n",
      eq, a1, a2,
      ifelse(abs(a2) < abs(a1), "YES ✓", "NO"),
      a2-a1))
}
```

---

## STEP 7: SHADOW PRICE TEST

```r
cat("\n================================================================\n")
cat("  SHADOW PRICE TEST: |α_y^(2)| < |α_y^(1)|\n")
cat("================================================================\n")

alpha_y_r1 <- coef_fin["ECT_r1", "y"]
alpha_y_r2 <- coef_fin["ECT_r2", "y"]

cat(sprintf("α_y^(1) [Regime 1, BoP slack]:   %+.4f  (t=%.2f)\n",
    alpha_y_r1, t_mat["ECT_r1","y"]))
cat(sprintf("α_y^(2) [Regime 2, BoP binding]: %+.4f  (t=%.2f)\n",
    alpha_y_r2, t_mat["ECT_r2","y"]))
cat(sprintf("|α_y^(2)| − |α_y^(1)|:           %+.4f\n",
    abs(alpha_y_r2) - abs(alpha_y_r1)))

shadow_price_confirmed <- abs(alpha_y_r2) < abs(alpha_y_r1)
if (shadow_price_confirmed) {
  cat("\nCONFIRMED: Output adjusts more slowly to frontier when BoP is binding.\n")
  cat("Kaldor mechanism operates as ceiling — shadow price compresses frontier adjustment.\n")
  cat("This compresses θ̂^CL: the effective mechanization path is constrained by λ > 0.\n")
} else {
  cat("\nNOT CONFIRMED: |α_y^(2)| ≥ |α_y^(1)|.\n")
  cat("Report as structural finding. Investigate: regime mis-classification?\n")
  cat("The BoP constraint may compress a different variable than y in this specification.\n")
}
```

---

## STEP 8: LINEARITY TEST — BOOTSTRAP LR

```r
cat("\n=== Linearity LR Test ===\n")
X_linear  <- cbind(ECT_theta=reg_data$ECT_th, reg_data$lags, reg_data$dummies, const=1)
valid_lin <- complete.cases(X_linear, reg_data$dY)
X_lin <- X_linear[valid_lin,,drop=FALSE]; Y_lin <- reg_data$dY[valid_lin,,drop=FALSE]
coef_lin  <- solve(crossprod(X_lin), crossprod(X_lin, Y_lin))
resid_lin <- Y_lin - X_lin %*% coef_lin
ssr_lin   <- sum(resid_lin^2)
LR_stat   <- T_fin * log(ssr_lin/ssr_min)
cat(sprintf("LR statistic: %.4f\n", LR_stat))

set.seed(42); n_boot <- 999; LR_boot <- numeric(n_boot)
for (b in seq_len(n_boot)) {
  idx_b   <- sample(seq_len(T_fin), replace=TRUE)
  Y_boot  <- X_lin %*% coef_lin + resid_lin[idx_b,]
  ssr_b_l <- sum((Y_boot - X_lin %*% solve(crossprod(X_lin), crossprod(X_lin, Y_boot)))^2)
  ssr_b_m <- min(vapply(gamma_grid, function(g) {
    Rb    <- as.integer(reg_data$ECT_m[valid_lin] > g)
    ECT1  <- reg_data$ECT_th[valid_lin]*(1-Rb)
    ECT2  <- reg_data$ECT_th[valid_lin]*Rb
    Xb    <- cbind(ECT_r1=ECT1, ECT_r2=ECT2,
                   reg_data$lags[valid_lin,], reg_data$dummies[valid_lin,], const=1)
    vb    <- complete.cases(Xb, Y_boot)
    if(sum(vb)<ncol(Xb)+2) return(Inf)
    cb    <- solve(crossprod(Xb[vb,]), crossprod(Xb[vb,], Y_boot[vb,]))
    sum((Y_boot[vb,]-Xb[vb,]%*%cb)^2)
  }, FUN.VALUE=numeric(1)))
  LR_boot[b] <- T_fin * log(ssr_b_l/ssr_b_m)
  if (b %% 100==0) cat(sprintf("  Bootstrap: %d/%d\n", b, n_boot))
}

p_boot <- mean(LR_boot >= LR_stat)
cat(sprintf("Bootstrap p-value (%d reps): %.4f\n", n_boot, p_boot))
cat(sprintf("5%% CV: %.4f | 10%% CV: %.4f\n",
    quantile(LR_boot, 0.95), quantile(LR_boot, 0.90)))
cat(ifelse(p_boot < 0.05, "REJECT linearity (5%)\n",
    ifelse(p_boot < 0.10, "REJECT linearity (10%)\n",
           "FAIL TO REJECT linearity\n")))
```

---

## STEP 9: μ̂^CL CONSTRUCTION — PIN YEAR 1980

```r
cat("\n================================================================\n")
cat("  PRODUCTIVE CAPACITY AND μ̂^CL CONSTRUCTION\n")
cat("================================================================\n")

# g_{Y^p,CL} = θ̂^CL(ω_t, φ_t) · g_{K^CL}
df <- df %>%
  arrange(year) %>%
  mutate(
    g_Y    = c(NA, diff(y)),
    g_K_CL = c(NA, diff(k_CL)),
    g_Yp   = theta_CL_t * g_K_CL,
    g_mu   = g_Y - g_Yp
  )

# Pin: μ̂^CL(1980) = 1.0
# Ffrench-Davis (2002): last year before the 1981-83 debt crisis.
# Chile operated at or near full productive capacity in 1980 —
# peak of the credit-financed expansion before the sudden stop.
pin_year <- 1980; pin_mu <- 1.0
df <- df %>% mutate(mu_CL = NA_real_)
df$mu_CL[df$year==pin_year] <- pin_mu

for (yr in (pin_year+1):max(df$year)) {
  ic <- which(df$year==yr); ip <- which(df$year==yr-1)
  if (length(ic)==1 && length(ip)==1 && !is.na(df$g_mu[ic]))
    df$mu_CL[ic] <- df$mu_CL[ip] * exp(df$g_mu[ic])
}
for (yr in (pin_year-1):min(df$year)) {
  ic <- which(df$year==yr); in_ <- which(df$year==yr+1)
  if (length(ic)==1 && length(in_)==1 && !is.na(df$g_mu[in_]))
    df$mu_CL[ic] <- df$mu_CL[in_] / exp(df$g_mu[in_])
}

cat(sprintf("Verification: μ̂^CL(1980) = %.6f [target: 1.000000]\n",
    df$mu_CL[df$year==1980]))

cat("\nPeriod averages of μ̂^CL:\n")
for (nm in names(periods)) {
  yr <- periods[[nm]]
  idx <- df$year >= yr[1] & df$year <= yr[2]
  cat(sprintf("  %-30s: %.4f\n", nm, mean(df$mu_CL[idx], na.rm=T)))
}

# Sensitivity — alternative pin years
cat("\nPin-year sensitivity:\n")
for (alt in list(list(1978,0.95), list(1979,1.0), list(1980,1.0), list(1981,1.0))) {
  pyr <- alt[[1]]; pmu <- alt[[2]]
  mu_a <- rep(NA_real_, nrow(df))
  mu_a[df$year==pyr] <- pmu
  for (yr in (pyr+1):max(df$year)) {
    ic<-which(df$year==yr); ip<-which(df$year==yr-1)
    if(length(ic)==1&&length(ip)==1&&!is.na(df$g_mu[ic]))
      mu_a[ic] <- mu_a[ip] * exp(df$g_mu[ic])
  }
  for (yr in (pyr-1):min(df$year)) {
    ic<-which(df$year==yr); in_<-which(df$year==yr+1)
    if(length(ic)==1&&length(in_)==1&&!is.na(df$g_mu[in_]))
      mu_a[ic] <- mu_a[in_] / exp(df$g_mu[in_])
  }
  cat(sprintf("  pin=%d@%.2f | ISI mean: %.3f | Post-82 mean: %.3f\n",
      pyr, pmu,
      mean(mu_a[df$year %in% 1940:1972], na.rm=T),
      mean(mu_a[df$year %in% 1983:2024], na.rm=T)))
}
```

---

## STEP 10: SAVE ALL OUTPUTS

```r
out_dir <- "output/stage_a/Chile/csv/"
dir.create(out_dir, showWarnings=FALSE, recursive=TRUE)

# Panel
df_out <- df %>%
  mutate(theta_CL = theta_CL_t) %>%
  select(year, y, k_CL, c_t, omega_c, k_NR, k_ME, phi, omega,
         ECT_m, ECT_m_lag1, theta_CL, g_Y, g_K_CL, g_Yp, g_mu, mu_CL)
write_csv(df_out, file.path(out_dir, "stage2_panel_with_mu_v2.csv"))

# Unit root crosswalk
ur_crosswalk <- tribble(
  ~variable, ~adf_tau, ~adf_5pct, ~pp_rej, ~kpss_rej, ~adf_d1_rej, ~verdict,
  "y",       ur_y$adf_tau,      ur_y$adf_5pct,      ur_y$pp_rej,      ur_y$kpss_rej,      ur_y$adf_d1_rej,      ur_y$verdict,
  "k_CL",    ur_kCL$adf_tau,    ur_kCL$adf_5pct,    ur_kCL$pp_rej,    ur_kCL$kpss_rej,    ur_kCL$adf_d1_rej,    ur_kCL$verdict,
  "c_t",     ur_ct$adf_tau,     ur_ct$adf_5pct,     ur_ct$pp_rej,     ur_ct$kpss_rej,     ur_ct$adf_d1_rej,     ur_ct$verdict,
  "omega_c", ur_omegac$adf_tau, ur_omegac$adf_5pct, ur_omegac$pp_rej, ur_omegac$kpss_rej, ur_omegac$adf_d1_rej, ur_omegac$verdict,
  "omega",   ur_omega$adf_tau,  ur_omega$adf_5pct,  ur_omega$pp_rej,  ur_omega$kpss_rej,  ur_omega$adf_d1_rej,  ur_omega$verdict,
  "phi",     ur_phi$adf_tau,    ur_phi$adf_5pct,    ur_phi$pp_rej,    ur_phi$kpss_rej,    ur_phi$adf_d1_rej,    ur_phi$verdict
)
write_csv(ur_crosswalk, file.path(out_dir, "stage2_ur_crosswalk.csv"))

# Structural parameters
params_out <- tibble(
  parameter = c("A", "B", "C", "theta_0", "psi", "theta_2", "kappa_1"),
  estimate  = c(A_hat, B_hat, C_hat, theta_0_hat, psi_hat, theta_2_hat, kappa_1),
  meaning   = c("(theta_0+psi)/2", "(psi-theta_0)/2", "theta_2/2",
                "infrastructure elasticity", "machinery elasticity",
                "distribution-composition interaction", "intercept")
)
write_csv(params_out, file.path(out_dir, "stage2_structural_params.csv"))

# θ̂^CL series
write_csv(
  tibble(year=df$year, phi=df$phi, omega=df$omega, theta_CL=theta_CL_t),
  file.path(out_dir, "stage2_theta_CL_series.csv")
)

# Regime classification
write_csv(
  tibble(year=yrs_diff[valid_fin], ECT_m=reg_data$ECT_m[valid_fin],
         R_t=R_t_opt[valid_fin],
         regime=ifelse(R_t_opt[valid_fin]==0, "Regime1_slack", "Regime2_binding")),
  file.path(out_dir, "stage2_regime_classification.csv")
)

# Alpha loadings
write_csv(
  tibble(equation=colnames(Y_fin),
         alpha_r1=coef_fin["ECT_r1",], se_r1=se_mat["ECT_r1",], t_r1=t_mat["ECT_r1",],
         alpha_r2=coef_fin["ECT_r2",], se_r2=se_mat["ECT_r2",], t_r2=t_mat["ECT_r2",],
         diff=coef_fin["ECT_r2",]-coef_fin["ECT_r1",]),
  file.path(out_dir, "stage2_alpha_loadings.csv")
)

# Bootstrap + SSR grid
write_csv(tibble(gamma=gamma_grid, ssr=ssr_grid),
          file.path(out_dir, "stage2_ssr_grid.csv"))
write_csv(tibble(LR_boot=LR_boot),
          file.path(out_dir, "stage2_LR_bootstrap.csv"))

cat("\n================================================================\n")
cat("  FINAL CROSSWALK SUMMARY\n")
cat("================================================================\n")
cat(sprintf("State vector:     (y, k_CL, c_t, omega_c)  — reparameterized\n"))
cat(sprintf("Estimator:        Manual CLS (Gonzalo-Pitarakis 2006)\n"))
cat(sprintf("Transition var:   ECT_m_lag1 (proxy for λ)\n"))
cat(sprintf("\nθ̂^CL(ω,φ) = %.4f + %.4f × φ + (%.4f) × ωφ\n",
    theta_0_hat, psi_hat, theta_2_hat))
cat(sprintf("Kaldor premium (ψ−θ_0):  %.4f  %s\n",
    psi_hat-theta_0_hat, ifelse(psi_hat>theta_0_hat,"✓","⚠")))
cat(sprintf("\nγ̂:               %.4f\n", gamma_hat))
cat(sprintf("Regime 1 / 2:    %d / %d obs\n", n_r1, n_r2))
cat(sprintf("LR p-value:      %.4f\n", p_boot))
cat(sprintf("Shadow price:    |α_y^(2)| < |α_y^(1)|: %s\n",
    ifelse(shadow_price_confirmed, "CONFIRMED ✓", "NOT CONFIRMED ⚠")))
cat(sprintf("μ̂^CL(1980):      %.6f\n", df$mu_CL[df$year==1980]))
cat("================================================================\n")
```

---

## CONTINGENCY PROTOCOLS

### If c_t is I(0) — bivariate fallback
Run a 2-variable Johansen on $(y_t, k_t^{CL})$ with $c_t$ and $\omega_t c_t$ as
restricted I(0) regressors in the cointegrating relation (DOLS). The CV1 then
estimates $A$ directly as the aggregate elasticity. $B$ and $C$ are identified
from the DOLS regressors. Parameter recovery $\theta_0 = A-B$, $\psi = A+B$,
$\theta_2 = 2C$ is unchanged.

### If sign priors violated
Do not suppress. $B \leq 0$ means infrastructure is more productive than machinery
at the margin — investigate whether Chile's composition ratio moved in a theoretically
unexpected direction. $C \geq 0$ means distribution expands rather than compresses
the mechanization path — report as a structural finding.

### If linearity not rejected
Report as in previous protocol. θ̂^CL is still identified from the linear VECM;
the regime-specific interpretation of α^(1) vs α^(2) is suggestive rather than
statistically confirmed.

---

*Prompt v2: 2026-04-07. Central object: θ̂^CL(ω_t,φ_t). Reparameterized state vector.
Authority: log_empirical_strategy_override_chile_2026-04-06.md. Pin: μ(1980)=1.0.*
