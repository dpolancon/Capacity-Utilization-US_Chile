###############################################################################
# US — Advanced Regression Analysis (1940–1978)
# Block V: ARDL (AIC/BIC) + Bounds Test · VECM (rank selection) · DOLS
###############################################################################

# ── 0. Working paths & packages ─────────────────────────────────────────────
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
data_dir  <- file.path(proj_root, "data/processed/US")
out_dir   <- file.path(proj_root, "output/results_package_us")
tab_dir   <- file.path(out_dir, "tables")
fig_dir   <- file.path(out_dir, "figures")

pkgs <- c("dplyr", "tidyr", "readr", "zoo", "lmtest", "sandwich",
          "ARDL", "tsDyn", "urca", "vars", "ggplot2")
for (p in pkgs) if (!requireNamespace(p, quietly = TRUE))
  install.packages(p, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

# Ensure dplyr verbs win over MASS
select <- dplyr::select
filter <- dplyr::filter
mutate <- dplyr::mutate
arrange <- dplyr::arrange

# ── 1. Rebuild the analysis dataset (same as results_package.R) ─────────────
mu_theta_file <- list.files(
  data_dir, pattern = "us_mu_theta_path_spec.*\\.csv$", full.names = TRUE
)
d_mt <- read_csv(mu_theta_file, show_col_types = FALSE) |>
  select(year, omega_t, theta_t_hat, gK, gYp, Y_real, Yp_hat, mu_t) |>
  filter(year >= 1940, year <= 1978) |> arrange(year)

d_bc <- read_csv(file.path(data_dir, "us_nf_corporate_stageBC.csv"),
                 show_col_types = FALSE) |>
  select(year, KGR, KNR, KGC, KNC, pY = Py, pK, IGC) |>
  filter(year >= 1940, year <= 1978) |> arrange(year)

d <- d_mt |> full_join(d_bc, by = "year") |> arrange(year) |>
  mutate(
    p_t       = pY / pK,
    B_nG_t    = Yp_hat / KGC,
    nu_t      = KGC / KNC,
    r_t       = (1 - omega_t) * mu_t * p_t * B_nG_t * nu_t,
    ln_r_t    = log(r_t),
    GD_t      = 1 - mu_t,
    SO_t      = mu_t * (1 - omega_t),
    ND_t      = GD_t - SO_t,
    OD_t      = ifelse(SO_t > 0, SO_t / (1 - GD_t), NA),
    RR_t      = ifelse(SO_t > 0, ND_t / SO_t, NA),
    ST_t      = GD_t * (1 - mu_t),
    gY_t      = c(NA, diff(log(Y_real)))
  )

# For time-series models: drop first row with NA gY_t, convert to ts/zoo
d_ts <- d |> filter(!is.na(gY_t)) |> arrange(year)
n_obs <- nrow(d_ts)
cat("Time-series sample:", n_obs, "observations (",
    min(d_ts$year), "–", max(d_ts$year), ")\n")

# Create ts objects
yr_start <- min(d_ts$year)
ts_gY   <- ts(d_ts$gY_t,   start = yr_start, freq = 1)
ts_ln_r <- ts(d_ts$ln_r_t, start = yr_start, freq = 1)
ts_RR   <- ts(d_ts$RR_t,   start = yr_start, freq = 1)
ts_GD   <- ts(d_ts$GD_t,   start = yr_start, freq = 1)

# ── Markdown report header ──────────────────────────────────────────────────
md_file <- file.path(tab_dir, "regression_advanced.md")
sink(md_file)

cat("# Advanced Regression Analysis: US Fordist Era (1940–1978)\n\n")
cat("## Sample and Variables\n\n")
cat(sprintf("- **Sample period:** %d–%d (%d annual observations)\n\n",
            min(d_ts$year), max(d_ts$year), n_obs))
cat("- **Dependent variable:** $g^Y_t$ — real income growth\n\n")
cat("- **Regressors:**\n\n")
cat(sprintf("  - $\\ln r_t$ — log profit rate (realized profitability)\n\n"))
cat(sprintf("  - $RR_t$ — reversal risk (compensatory fragility)\n\n"))
cat(sprintf("  - $GD_t$ — gross dysfunction (capacity burden)\n\n"))
cat("\n---\n\n")

# ============================================================================
# BLOCK V.A — ARDL MODELS
# ============================================================================

cat("\n# Block V.A — ARDL Bounds Testing for Cointegration\n\n")

# ── A1. Auto-ARDL with BIC ─────────────────────────────────────────────────
cat("## A1. ARDL Model — BIC Lag Selection\n\n")

ardl_bic <- auto_ardl(
  gY_t ~ ln_r_t + RR_t + GD_t,
  data = d_ts,
  max_order = 3,
  ic = "bic"
)

cat("### Selected Lag Structure (BIC)\n\n")
cat(sprintf("- **ARDL order:** %s\n\n",
            paste(ardl_bic$order, collapse = ", ")))
cat(sprintf("- **BIC value:** %.4f\n\n", ardl_bic$ic_val))

cat("### Short-Run Estimates\n\n")
sr_bic <- summary(ardl_bic$model)
print(sr_bic)
cat("\n\n")

# ── Long-run multipliers (BIC) ─────────────────────────────────────────────
cat("### Long-Run Multipliers (BIC)\n\n")
lr_bic <- multipliers(ardl_bic$model)
print(lr_bic)
cat("\n\n")

# ── Bounds F-test (BIC) ────────────────────────────────────────────────────
cat("### Bounds F-Test for Cointegration (BIC)\n\n")
fbic <- bounds_f_test(ardl_bic$model)
print(fbic)
cat("\n\n")

# Interpret the F-stat against Pesaran et al. (2001) critical bounds
cat("### Interpretation (BIC)\n\n")
F_stat <- fbic$statistic
k_exog <- 3  # ln_r, RR, GD
cat(sprintf("- F-statistic = %.4f\n", F_stat))
cat(sprintf("- Number of regressors (k) = %d\n\n", k_exog))
cat("- Reference: Pesaran, Shin & Smith (2001), Table CI(iii)(c) — unrestricted intercept, unrestricted trend\n\n")
cat("- Critical bounds (I(0) / I(1)) for k=3, n=40 (approx.):\n\n")
cat("  | Significance | I(0) lower | I(1) upper |\nn")
cat("  |-------------|-----------|------------|\n")
cat("  | 10%         | 2.45      | 3.52       |\n")
cat("  | 5%          | 2.86      | 4.01       |\n")
cat("  | 1%          | 3.75      | 5.06       |\n\n")

if (F_stat > 4.01) {
  cat("- **Verdict:** F-statistic exceeds the I(1) upper bound at 5%. ")
  cat("Reject H₀: no levels relationship. **Evidence of cointegration.**\n\n")
} else if (F_stat < 2.86) {
  cat("- **Verdict:** F-statistic below the I(0) lower bound at 5%. ")
  cat("Fail to reject H₀. **No evidence of cointegration.**\n\n")
} else {
  cat("- **Verdict:** F-statistic lies in the inconclusive zone. ")
  cat("Cannot determine cointegration without knowing integration order of regressors.\n\n")
}

# ── A2. Auto-ARDL with AIC ─────────────────────────────────────────────────
cat("\n## A2. ARDL Model — AIC Lag Selection\n\n")

ardl_aic <- auto_ardl(
  gY_t ~ ln_r_t + RR_t + GD_t,
  data = d_ts,
  max_order = 3,
  ic = "aic"
)

cat("### Selected Lag Structure (AIC)\n\n")
cat(sprintf("- **ARDL order:** %s\n\n",
            paste(ardl_aic$order, collapse = ", ")))
cat(sprintf("- **AIC value:** %.4f\n\n", ardl_aic$ic_val))

cat("### Short-Run Estimates\n\n")
sr_aic <- summary(ardl_aic$model)
print(sr_aic)
cat("\n\n")

cat("### Long-Run Multipliers (AIC)\n\n")
lr_aic <- multipliers(ardl_aic$model)
print(lr_aic)
cat("\n\n")

cat("### Bounds F-Test for Cointegration (AIC)\n\n")
faic <- bounds_f_test(ardl_aic$model)
print(faic)
cat("\n\n")

# Interpret the F-stat (AIC)
cat("### Interpretation (AIC)\n\n")
F_stat_aic <- faic$statistic
cat(sprintf("- F-statistic = %.4f\n\n", F_stat_aic))

if (F_stat_aic > 4.01) {
  cat("- **Verdict:** F-statistic exceeds the I(1) upper bound at 5%. ")
  cat("Reject H₀: no levels relationship. **Evidence of cointegration.**\n\n")
} else if (F_stat_aic < 2.86) {
  cat("- **Verdict:** F-statistic below the I(0) lower bound at 5%. ")
  cat("Fail to reject H₀. **No evidence of cointegration.**\n\n")
} else {
  cat("- **Verdict:** F-statistic lies in the inconclusive zone.\n\n")
}

# ── A3. Pesaran (2001) Case Selection Discussion ───────────────────────────
cat("\n## A3. Case Selection Discussion (Pesaran et al., 2001)\n\n")
cat("The bounds testing framework requires correct identification of the deterministic ")
cat("specification. Pesaran et al. (2001) distinguish five cases:\n\n")
cat("| Case | Intercept | Trend | Economic Interpretation |\n")
cat("|------|-----------|-------|------------------------|\n")
cat("| I    | None      | None  | Zero mean, no trend    |\n")
cat("| II   | Restricted| None  | Non-zero mean, no trend|\n")
cat("| III  | Unrestricted | None | Non-zero mean, no trend |\n")
cat("| IV   | Unrestricted | Unrestricted | Linear trend  |\n")
cat("| V    | Restricted   | Restricted   | Quadratic trend |\n\n")

cat("### Case assessment for this specification\n\n")
cat("The dependent variable $g^Y_t$ is a **growth rate** (first difference of log income). ")
cat("Growth rates typically have a non-zero mean but no deterministic trend. ")
cat("This corresponds to **Case III** (unrestricted intercept, no trend).\n\n")
cat("The regressors ($\\ln r_t$, $RR_t$, $GD_t$) are either log-levels or constructed indices ")
cat("that fluctuate around a mean. None exhibits a deterministic time trend by construction.\n\n")
cat("The `auto_ardl` function in the ARDL package includes an unrestricted intercept by default, ")
cat("which aligns with **Case III**. The critical values reported above correspond to ")
cat("Table CI(iii)(c) of Pesaran et al. (2001).\n\n")

cat("### Integration order caveat\n\n")
cat("The bounds test is valid regardless of whether regressors are I(0) or I(1), ")
cat("but **not** I(2). The following pre-estimation checks apply:\n\n")
cat("- If all regressors are I(0): compare F-statistic to I(0) lower bound.\n")
cat("- If all regressors are I(1): compare F-statistic to I(1) upper bound.\n")
cat("- If regressors are mixed I(0)/I(1): the F-statistic must be compared to ")
cat("both bounds; values in between are inconclusive.\n")
cat("- If any regressor is I(2): the bounds test is **invalid**.\n\n")

cat("### Comparison of AIC vs. BIC selection\n\n")
cat(sprintf("- BIC selected order (%s); AIC selected order (%s).\n\n",
            paste(ardl_bic$order, collapse=", "),
            paste(ardl_aic$order, collapse=", ")))
cat("BIC penalizes model complexity more heavily, typically selecting shorter lag structures. ")
cat("AIC tends to overfit in small samples but may capture more dynamics. ")
cat("If both specifications yield the same cointegration verdict, the result is robust ")
cat("to lag-length uncertainty. If they diverge, the BIC result is preferred ")
cat("for inference in small samples (Natsiopoulos & Tzeremes, 2022).\n\n")

sink()

# ============================================================================
# BLOCK V.B — VECM MODEL
# ============================================================================

sink(md_file, append = TRUE)

cat("\n---\n\n")
cat("# Block V.B — VECM: Cointegration Rank and Long-Run Structure\n\n")

# Prepare levels data for VECM
# Variables in levels: ln_r, RR, GD (and implicitly gY comes from ln(Y))
# For VECM we need the system in levels
d_levels <- d |>
  filter(year >= 1941, year <= 1978) |>
  select(year, ln_r_t, RR_t, GD_t) |>
  arrange(year) |>
  mutate(
    # Cumulate gY to get ln(Y) index for the system
    ln_Y = cumsum(c(log(d$Y_real[1]), d$gY_t[2:nrow(d)]))
  ) |>
  select(year, ln_r_t, RR_t, GD_t)

# Convert to matrix/ts
Y_vecm <- as.matrix(d_levels[, c("ln_r_t", "RR_t", "GD_t")])
colnames(Y_vecm) <- c("ln_r", "RR", "GD")

# ── B1. Lag-length selection for underlying VAR ────────────────────────────
cat("## B1. VAR Lag-Length Selection\n\n")

# Try VAR(1) to VAR(3) on levels
max_lag_vecm <- 3
var_lags <- list()
for (p in 1:max_lag_vecm) {
  var_lags[[p]] <- VAR(Y_vecm, p = p, type = "const")
}

# Information criteria
for (p in 1:max_lag_vecm) {
  cat(sprintf("- VAR(%d): AIC = %.4f, BIC = %.4f\n",
              p, AIC(var_lags[[p]]), BIC(var_lags[[p]])))
}
cat("\n")

# ── B2. Johansen rank tests ────────────────────────────────────────────────
cat("## B2. Johansen Cointegration Rank Tests\n\n")

# Use urca::ca.jo for trace and eigen tests
p_vecm <- 2  # VAR lag order for VECM (VECM p-1)
cj <- ca.jo(Y_vecm, type = "trace", ecdet = "const",
            K = p_vecm, spec = "longrun", season = NULL)

cat("### Trace Test\n\n")
cat("``` \n")
print(cj)
cat("```\n\n")

# Max-eigenvalue test
cj_max <- ca.jo(Y_vecm, type = "eigen", ecdet = "const",
                K = p_vecm, spec = "longrun", season = NULL)

cat("### Max-Eigenvalue Test\n\n")
cat("``` \n")
print(cj_max)
cat("```\n\n")

# ── B3. Rank discussion ────────────────────────────────────────────────────
cat("## B3. Cointegration Rank Assessment\n\n")

trace_stats <- cj@teststat
trace_cv10  <- cj@criticalval[, "10pct"]
trace_cv5   <- cj@criticalval[, "5pct"]
trace_cv1   <- cj@criticalval[, "1pct"]
r_names     <- cj@cvalnames

cat("### Trace Test Summary\n\n")
cat("| r ≤ | Test Stat | 10% CV | 5% CV | 1% CV | Decision (5%) |\n")
cat("|-----|----------|--------|-------|-------|---------------|\n")
for (i in 1:length(trace_stats)) {
  decision <- ifelse(trace_stats[i] > trace_cv5[i],
                     sprintf("Reject (r > %d)", i-1),
                     sprintf("Fail to reject (r = %d)", i-1))
  cat(sprintf("| %s | %.4f | %.4f | %.4f | %.4f | %s |\n",
              r_names[i], trace_stats[i], trace_cv10[i], trace_cv5[i],
              trace_cv1[i], decision))
}
cat("\n\n")

# Determine rank
rank_trace <- sum(trace_stats > trace_cv5)
cat(sprintf("- **Trace test indicates rank r = %d** (5% level).\n\n", rank_trace))

# Also report eigen test
eigen_stats <- cj_max@teststat
eigen_cv5   <- cj_max@criticalval[, "5pct"]
rank_eigen <- sum(eigen_stats > eigen_cv5)
cat(sprintf("- **Max-eigen test indicates rank r = %d** (5% level).\n\n", rank_eigen))

if (rank_trace == rank_eigen) {
  cat(sprintf("- **Both tests agree on rank = %d.**\n\n", rank_trace))
} else {
  cat("- **Tests disagree.** Trace test is generally more reliable in small samples.\n\n")
}

cat("### Feasibility of higher-rank models\n\n")
if (rank_trace >= 1) {
  cat("A rank-1 VECM is identified. ")
  if (rank_trace >= 2) {
    cat("The trace test also supports **rank = 2**, suggesting two cointegrating relationships ")
    cat("among the three variables. This would imply a richer long-run structure ")
    cat("but is harder to interpret economically with only ", n_obs, " observations.\n\n")
  } else {
    cat("The trace test does **not** support rank > 1. ")
    cat("A single cointegrating vector is the only statistically defensible specification.\n\n")
  }
} else {
  cat("Neither test supports cointegration. A VAR in differences would be more appropriate.\n\n")
}

# ── B4. Estimate VECM with rank = 1 ────────────────────────────────────────
r_est <- max(1, rank_trace)
if (r_est > 2) r_est <- 2  # cap at 2 for 3-variable system

cat(sprintf("## B4. VECM Estimation (r = %d)\n\n", r_est))

vecm_fit <- VECM(Y_vecm, lag = p_vecm - 1, r = r_est,
                 include = "const", estim = "ML")

cat("### Loading Coefficients (α)\n\n")
cat("``` \n")
print(coef(vecm_fit))
cat("```\n\n")

cat("### Cointegrating Vector(s) (β)\n\n")
# Extract from coefPI
beta_mat <- coefPI(vecm_fit)
cat("``` \n")
print(beta_mat)
cat("```\n\n")

cat("### Normalized cointegrating relationship\n\n")
# Normalize on first variable (ln_r)
if (r_est >= 1) {
  beta_norm <- beta_mat[, 1] / beta_mat[1, 1]
  cat(sprintf("$\\ln r_t$ + (%.4f)·$RR_t$ + (%.4f)·$GD_t$ = $ECT_t$\n\n",
              beta_norm[2], beta_norm[3]))
  cat("This is the estimated long-run equilibrium relationship.\n\n")
}

sink()

# ============================================================================
# BLOCK V.C — DOLS (Dynamic OLS)
# ============================================================================

sink(md_file, append = TRUE)

cat("\n---\n\n")
cat("# Block V.C — Dynamic OLS (DOLS)\n\n")
cat("## Methodology\n\n")
cat("Dynamic OLS (Saikkonen, 1991; Stock & Watson, 1993) augments the static ")
cat("cointegrating regression with leads and lags of the first differences of ")
cat("regressors to eliminate endogeneity bias and serial correlation.\n\n")
cat("$$g^Y_t = \\alpha + \\beta_1 \\ln r_t + \\beta_2 RR_t + \\beta_3 GD_t ")
cat("+ \\sum_{j=-p}^{p} \\gamma_j \\Delta X_{t-j} + \\varepsilon_t$$\n\n")
cat("where $X_t = (\\ln r_t, RR_t, GD_t)'$ and $p$ is the lead/lag order.\n\n")

# ── C1. Prepare DOLS data ──────────────────────────────────────────────────
p_dols <- 1  # leads and lags order

# First differences of all regressors
d_dols <- d_ts |>
  mutate(
    d_ln_r = c(NA, diff(ln_r_t)),
    d_RR   = c(NA, diff(RR_t)),
    d_GD   = c(NA, diff(GD_t))
  ) |>
  filter(!is.na(d_ln_r))

# Add leads and lags
for (j in 1:p_dols) {
  d_dols[[paste0("d_ln_r_L", j)]] <- c(rep(NA, j), head(d_dols$d_ln_r, -j))
  d_dols[[paste0("d_ln_r_F", j)]] <- c(tail(d_dols$d_ln_r, -j), rep(NA, j))
  d_dols[[paste0("d_RR_L", j)]]   <- c(rep(NA, j), head(d_dols$d_RR, -j))
  d_dols[[paste0("d_RR_F", j)]]   <- c(tail(d_dols$d_RR, -j), rep(NA, j))
  d_dols[[paste0("d_GD_L", j)]]   <- c(rep(NA, j), head(d_dols$d_GD, -j))
  d_dols[[paste0("d_GD_F", j)]]   <- c(tail(d_dols$d_GD, -j), rep(NA, j))
}

# Drop rows with any NA from leads/lags
d_dols <- d_dols |> filter(if_all(starts_with("d_"), ~ !is.na(.x)))
n_dols <- nrow(d_dols)
cat(sprintf("DOLS sample: %d observations (after leads/lags trimming).\n\n", n_dols))

# ── C2. Estimate DOLS ──────────────────────────────────────────────────────
# Build formula
lead_lag_vars <- c()
for (j in 1:p_dols) {
  lead_lag_vars <- c(lead_lag_vars,
                     paste0("d_ln_r_L", j), paste0("d_ln_r_F", j),
                     paste0("d_RR_L", j),   paste0("d_RR_F", j),
                     paste0("d_GD_L", j),   paste0("d_GD_F", j))
}
fml_dols <- as.formula(
  paste0("gY_t ~ ln_r_t + RR_t + GD_t + ", paste(lead_lag_vars, collapse = " + "))
)

dols_fit <- lm(fml_dols, data = d_dols)
dols_sum <- summary(dols_fit)

cat("## DOLS Estimates (p = ", p_dols, " lead/lag)\n\n", sep = "")

cat("### Long-Run Coefficients\n\n")
cat("| Variable | Estimate | Std. Error | t-value | p-value |\n")
cat("|----------|----------|------------|---------|--------|\n")

# Extract coefficients for the long-run terms (not lead/lag controls)
lr_coefs <- dols_sum$coefficients[c("(Intercept)", "ln_r_t", "RR_t", "GD_t"), ]
for (v in rownames(lr_coefs)) {
  cat(sprintf("| %s | %.6f | %.6f | %.4f | %.4f |\n",
              v, lr_coefs[v, "Estimate"], lr_coefs[v, "Std. Error"],
              lr_coefs[v, "t value"], lr_coefs[v, "Pr(>|t|)"]))
}
cat("\n\n")

cat("### Model Fit\n\n")
cat(sprintf("- **R²:** %.4f\n\n", dols_sum$r.squared))
cat(sprintf("- **Adjusted R²:** %.4f\n\n", dols_sum$adj.r.squared))
cat(sprintf("- **Residual SD:** %.6f\n\n", dols_sum$sigma))

# HAC inference for DOLS
cat("### HAC-Robust Inference (Newey-West, lag = 2)\n\n")
dols_vcov <- NeweyWest(dols_fit, lag = 2, prewhite = FALSE)
dols_coefs_test <- coeftest(dols_fit, vcov = dols_vcov)

cat("| Variable | Estimate | HAC SE | t-value | p-value |\n")
cat("|----------|----------|--------|---------|--------|\n")
lr_idx <- c(1, 2, 3, 4)  # intercept, ln_r, RR, GD
for (i in lr_idx) {
  vname <- rownames(dols_coefs_test)[i]
  cat(sprintf("| %s | %.6f | %.6f | %.4f | %.4f |\n",
              vname, dols_coefs_test[i, 1], dols_coefs_test[i, 2],
              dols_coefs_test[i, 3], dols_coefs_test[i, 4]))
}
cat("\n\n")

cat("### Interpretation\n\n")
beta_lr <- lr_coefs["ln_r_t", "Estimate"]
cat(sprintf("- The long-run elasticity of income growth with respect to profitability ")
cat("is %.4f.\n\n", beta_lr))
cat("- DOLS corrects for endogeneity of the profit rate and serial correlation ")
cat("by including leads and lags of differenced regressors.\n\n")
cat("- If the DOLS coefficient differs materially from the ARDL long-run multiplier, ")
cat("this suggests either endogeneity bias in static OLS or sensitivity to ")
cat("the dynamic augmentation scheme.\n\n")

# ── C3. Cross-model comparison table ───────────────────────────────────────
cat("\n---\n\n")
cat("# Block V.D — Cross-Model Comparison: Long-Run Coefficients\n\n")

cat("| Model | ln(r) | RR | GD | Method |\n")
cat("|-------|-------|----|----|--------|\n")

# ARDL BIC long-run
if (!is.null(lr_bic$longrun)) {
  lr_bic_vals <- lr_bic$longrun
  cat(sprintf("| ARDL (BIC) | %.4f | %.4f | %.4f | Long-run multiplier |\n",
              lr_bic_vals["ln_r_t"], lr_bic_vals["RR_t"], lr_bic_vals["GD_t"]))
}

# ARDL AIC long-run
if (!is.null(lr_aic$longrun)) {
  lr_aic_vals <- lr_aic$longrun
  cat(sprintf("| ARDL (AIC) | %.4f | %.4f | %.4f | Long-run multiplier |\n",
              lr_aic_vals["ln_r_t"], lr_aic_vals["RR_t"], lr_aic_vals["GD_t"]))
}

# VECM
if (exists("beta_norm") && r_est >= 1) {
  cat(sprintf("| VECM (r=%d) | 1.0000 | %.4f | %.4f | Normalized β vector |\n",
              r_est, beta_norm[2], beta_norm[3]))
}

# DOLS
cat(sprintf("| DOLS (p=%d) | %.4f | %.4f | %.4f | Dynamic OLS |\n",
            p_dols,
            lr_coefs["ln_r_t", "Estimate"],
            lr_coefs["RR_t", "Estimate"],
            lr_coefs["GD_t", "Estimate"]))

cat("\n\n")
cat("---\n\n")
cat("*Report generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "*\n\n")
cat("## References\n\n")
cat("- Pesaran, M.H., Shin, Y. & Smith, R.J. (2001). Bounds testing approaches to ")
cat("the analysis of levels relationships. *Journal of Applied Econometrics*, 16(3), 289–326.\n\n")
cat("- Natsiopoulos, K. & Tzeremes, N.G. (2022). ARDL bounds test for cointegration: ")
cat("Replicating the Pesaran et al. (2001) results. *Journal of Applied Econometrics*, 37(5), 1079–1090.\n\n")
cat("- Saikkonen, P. (1991). Asymptotically efficient estimation of cointegrating regression models. ")
cat("*Econometric Theory*, 7, 1–21.\n\n")
cat("- Stock, J.H. & Watson, M.W. (1993). A simple estimator of cointegrating vectors in higher order integrated systems. ")
cat("*Econometrica*, 61(4), 783–820.\n\n")

sink()

cat("\n=== ADVANCED REGRESSION REPORT COMPLETE ===\n")
cat("Markdown report saved to:", md_file, "\n")
