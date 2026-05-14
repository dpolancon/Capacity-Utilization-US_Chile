###############################################################################
# STAGE 2: ARDL models with bounds testing
# ============================================================================
# Runs in its own R session to avoid MASS/dplyr conflicts

proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir   <- file.path(proj_root, "output/results_package_us")
tab_dir   <- file.path(out_dir, "tables")

# Load pre-built data
d_ts <- readRDS(file.path(out_dir, "d_ts_regression.rds"))
n_obs <- nrow(d_ts)

# Load ARDL only
library(ARDL)

# ── Markdown report ─────────────────────────────────────────────────────────
md_file <- file.path(tab_dir, "regression_advanced.md")

sink(md_file)

cat("# Advanced Regression Analysis: US Fordist Era (1940–1978)\n\n")
cat("## Sample and Variables\n\n")
cat(sprintf("- **Sample period:** %d–%d (%d annual observations)\n\n",
            min(d_ts$year), max(d_ts$year), n_obs))
cat("- **Dependent variable:** $g^Y_t$ — real income growth\n\n")
cat("- **Regressors:**\n\n")
cat("  - $\\ln r_t$ — log profit rate (realized profitability)\n\n")
cat("  - $RR_t$ — reversal risk (compensatory fragility)\n\n")
cat("  - $GD_t$ — gross dysfunction (capacity burden)\n\n")
cat("\n---\n\n")

# ============================================================================
# BLOCK V.A — ARDL MODELS
# ============================================================================

cat("\n# Block V.A — ARDL Bounds Testing for Cointegration\n\n")

# ── A1. Auto-ARDL with BIC ─────────────────────────────────────────────────
cat("## A1. ARDL Model — BIC Lag Selection\n\n")

ardl_bic <- tryCatch(
  auto_ardl(gY_t ~ ln_r_t + RR_t + GD_t, data = d_ts, max_order = 3, ic = "bic"),
  error = function(e) NULL
)

if (!is.null(ardl_bic) && !is.null(ardl_bic$model)) {
  cat("### Selected Lag Structure (BIC)\n\n")
  cat(sprintf("- **ARDL order:** (%s)\n\n",
              paste(ardl_bic$order, collapse = ", ")))
  cat(sprintf("- **BIC value:** %.4f\n\n", ardl_bic$ic_val))

  cat("### Short-Run Estimates\n\n")
  cat("```\n")
  print(summary(ardl_bic$model))
  cat("```\n\n")

  cat("### Long-Run Multipliers (BIC)\n\n")
  lr_bic <- multipliers(ardl_bic$model)
  cat("```\n")
  print(lr_bic)
  cat("```\n\n")

  cat("### Bounds F-Test (BIC)\n\n")
  fbic <- bounds_f_test(ardl_bic$model, case = 3)
  cat("```\n")
  print(fbic)
  cat("```\n\n")

  F_stat <- fbic$statistic
  k_exog <- 3
  cat("### Interpretation (BIC)\n\n")
  cat(sprintf("- F-statistic = %.4f, k = %d, n = %d\n\n", F_stat, k_exog, n_obs))
  cat("Critical bounds (Pesaran et al. 2001, Table CI(iii)(c)):\n\n")
  cat("| Significance | I(0) lower | I(1) upper |\n")
  cat("|-------------|-----------|------------|\n")
  cat("| 10%         | 2.45      | 3.52       |\n")
  cat("| 5%          | 2.86      | 4.01       |\n")
  cat("| 1%          | 3.75      | 5.06       |\n\n")

  if (F_stat > 4.01) {
    cat("**Verdict:** F exceeds I(1) upper bound at 5%. **Cointegration confirmed.**\n\n")
  } else if (F_stat < 2.86) {
    cat("**Verdict:** F below I(0) lower bound at 5%. **No cointegration.**\n\n")
  } else {
    cat("**Verdict:** F in inconclusive zone. Cointegration indeterminate.\n\n")
  }
} else {
  cat("**auto_ardl (BIC) failed to identify a valid model.** ")
  cat("This may reflect insufficient degrees of freedom or numerical instability ")
  cat("in the lag-selection criterion with only ", n_obs, " observations.\n\n",
      sep = "")
  ardl_bic <- NULL
}

# ── A2. Auto-ARDL with AIC ─────────────────────────────────────────────────
cat("\n## A2. ARDL Model — AIC Lag Selection\n\n")

ardl_aic <- tryCatch(
  auto_ardl(gY_t ~ ln_r_t + RR_t + GD_t, data = d_ts, max_order = 3, ic = "aic"),
  error = function(e) NULL
)

if (!is.null(ardl_aic) && !is.null(ardl_aic$model)) {
  cat("### Selected Lag Structure (AIC)\n\n")
  cat(sprintf("- **ARDL order:** (%s)\n\n",
              paste(ardl_aic$order, collapse = ", ")))
  cat(sprintf("- **AIC value:** %.4f\n\n", ardl_aic$ic_val))

  cat("### Short-Run Estimates\n\n")
  cat("```\n")
  print(summary(ardl_aic$model))
  cat("```\n\n")

  cat("### Long-Run Multipliers (AIC)\n\n")
  lr_aic <- multipliers(ardl_aic$model)
  cat("```\n")
  print(lr_aic)
  cat("```\n\n")

  cat("### Bounds F-Test (AIC)\n\n")
  faic <- bounds_f_test(ardl_aic$model, case = 3)
  cat("```\n")
  print(faic)
  cat("```\n\n")

  F_stat_aic <- faic$statistic
  cat("### Interpretation (AIC)\n\n")
  cat(sprintf("- F-statistic = %.4f\n\n", F_stat_aic))

  if (F_stat_aic > 4.01) {
    cat("**Verdict:** F exceeds I(1) upper bound at 5%. **Cointegration confirmed.**\n\n")
  } else if (F_stat_aic < 2.86) {
    cat("**Verdict:** F below I(0) lower bound at 5%. **No cointegration.**\n\n")
  } else {
    cat("**Verdict:** F in inconclusive zone. Cointegration indeterminate.\n\n")
  }
} else {
  cat("**auto_ardl (AIC) failed to identify a valid model.**\n\n")
  ardl_aic <- NULL
}

# ── Fallback: manual ARDL(1,1,1,1) if auto_ardl failed ──────────────────────
if (is.null(ardl_bic) || is.null(ardl_aic)) {
  cat("\n## A3. Fallback — Manual ARDL(1,1,1,1) Estimation\n\n")
  cat("Since `auto_ardl` did not return a valid model, we estimate a parsimonious ")
  cat("ARDL(1,1,1,1) directly and compute long-run multipliers and bounds test manually.\n\n")

  ardl_manual <- ardl(gY_t ~ ln_r_t + RR_t + GD_t,
                      order = c(1, 1, 1, 1), data = d_ts)

  cat("### Short-Run Estimates\n\n")
  cat("```\n")
  print(summary(ardl_manual))
  cat("```\n\n")

  cat("### Long-Run Multipliers\n\n")
  lr_manual <- multipliers(ardl_manual)
  cat("```\n")
  print(lr_manual)
  cat("```\n\n")

  cat("### Bounds F-Test\n\n")
  f_manual <- bounds_f_test(ardl_manual, case = 3)
  cat("```\n")
  print(f_manual)
  cat("```\n\n")

  F_stat_man <- f_manual$statistic
  cat("### Interpretation\n\n")
  cat(sprintf("- F-statistic = %.4f\n\n", F_stat_man))
  if (F_stat_man > 4.01) {
    cat("**Cointegration confirmed.**\n\n")
  } else if (F_stat_man < 2.86) {
    cat("**No cointegration.**\n\n")
  } else {
    cat("**Inconclusive zone.**\n\n")
  }

  # Use manual results as the reference
  ardl_bic <- ardl_manual
  lr_bic <- lr_manual
  ardl_aic <- ardl_manual
  lr_aic <- lr_manual
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
cat("The `ardl` function includes an unrestricted intercept by default, ")
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
if (!is.null(ardl_bic) && !is.null(ardl_aic)) {
  cat(sprintf("- BIC selected order (%s); AIC selected order (%s).\n\n",
              paste(ardl_bic$order, collapse=", "),
              paste(ardl_aic$order, collapse=", ")))
}
cat("BIC penalizes model complexity more heavily, typically selecting shorter lag structures. ")
cat("AIC tends to overfit in small samples but may capture more dynamics. ")
cat("If both specifications yield the same cointegration verdict, the result is robust ")
cat("to lag-length uncertainty. If they diverge, the BIC result is preferred ")
cat("for inference in small samples (Natsiopoulos & Tzeremes, 2022).\n\n")

sink()

# Save ARDL results for the consolidation stage
saveRDS(list(
  ardl_bic = if (exists("ardl_bic") && !is.null(ardl_bic)) ardl_bic else NULL,
  ardl_aic = if (exists("ardl_aic") && !is.null(ardl_aic)) ardl_aic else NULL,
  ardl_manual = if (exists("ardl_manual") && !is.null(ardl_manual)) ardl_manual else NULL,
  lr_bic = if (exists("lr_bic")) lr_bic else NULL,
  lr_aic = if (exists("lr_aic")) lr_aic else NULL,
  lr_manual = if (exists("lr_manual")) lr_manual else NULL,
  f_bic = if (exists("fbic")) fbic else NULL,
  f_aic = if (exists("faic")) faic else NULL,
  f_manual = if (exists("f_manual")) f_manual else NULL
), file = file.path(out_dir, "ardl_results.rds"))

cat("\n=== STAGE 2 COMPLETE: ARDL analysis done ===\n")
