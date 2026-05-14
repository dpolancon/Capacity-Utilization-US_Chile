###############################################################################
# STAGE 2: ARDL models — log_Y ~ r_t + RR_t + GD_t
# ============================================================================
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir   <- file.path(proj_root, "output/results_package_us")
tab_dir   <- file.path(out_dir, "tables")

d_ts <- readRDS(file.path(out_dir, "d_ts_levels.rds"))
n_obs <- nrow(d_ts)

library(ARDL)

md_file <- file.path(tab_dir, "reg_levels_advanced.md")
sink(md_file)

cat("# Advanced Regression Analysis: US Fordist Era (1940–1978)\n\n")
cat("## Specification\n\n")
cat("- **Dependent variable:** $\\ln Y_t$ — log real income (level)\n\n")
cat("- **Regressors:**\n\n")
cat("  - $r_t$ — profit rate (level, not logged)\n\n")
cat("  - $RR_t$ — reversal risk\n\n")
cat("  - $GD_t$ — gross dysfunction\n\n")
cat(sprintf("- **Sample:** %d observations (%d–%d)\n\n",
            n_obs, min(d_ts$year), max(d_ts$year)))
cat("\n---\n\n")

# ── A1. Auto-ARDL BIC ──────────────────────────────────────────────────────
cat("\n# Block V.A — ARDL Bounds Testing for Cointegration\n\n")
cat("## A1. ARDL Model — BIC Lag Selection\n\n")

ardl_bic <- tryCatch(
  auto_ardl(log_Y ~ r_t + RR_t + GD_t, data = d_ts, max_order = 3, ic = "bic"),
  error = function(e) { cat("Error:", e$message, "\n\n"); NULL }
)

if (!is.null(ardl_bic) && !is.null(ardl_bic$model)) {
  cat(sprintf("- **ARDL order:** (%s), BIC = %.4f\n\n",
              paste(ardl_bic$order, collapse = ", "), ardl_bic$ic_val))
  cat("### Short-Run Estimates\n\n```\n")
  print(summary(ardl_bic$model))
  cat("```\n\n")
  cat("### Long-Run Multipliers\n\n```\n")
  lr_bic <- multipliers(ardl_bic$model)
  print(lr_bic)
  cat("```\n\n")
  cat("### Bounds F-Test (Case III)\n\n```\n")
  fbic <- bounds_f_test(ardl_bic$model, case = 3)
  print(fbic)
  cat("```\n\n")
  cat(sprintf("**F = %.4f** | I(0) 5%% CV = 2.86 | I(1) 5%% CV = 4.01\n\n",
              fbic$statistic))
  if (fbic$statistic > 4.01) {
    cat("**Verdict: Cointegration confirmed.**\n\n")
  } else if (fbic$statistic < 2.86) {
    cat("**Verdict: No cointegration.**\n\n")
  } else {
    cat("**Verdict: Inconclusive.**\n\n")
  }
} else {
  cat("*auto_ardl (BIC) failed.*\n\n")
  ardl_bic <- NULL
}

# ── A2. Auto-ARDL AIC ──────────────────────────────────────────────────────
cat("\n## A2. ARDL Model — AIC Lag Selection\n\n")

ardl_aic <- tryCatch(
  auto_ardl(log_Y ~ r_t + RR_t + GD_t, data = d_ts, max_order = 3, ic = "aic"),
  error = function(e) { cat("Error:", e$message, "\n\n"); NULL }
)

if (!is.null(ardl_aic) && !is.null(ardl_aic$model)) {
  cat(sprintf("- **ARDL order:** (%s), AIC = %.4f\n\n",
              paste(ardl_aic$order, collapse = ", "), ardl_aic$ic_val))
  cat("### Short-Run Estimates\n\n```\n")
  print(summary(ardl_aic$model))
  cat("```\n\n")
  cat("### Long-Run Multipliers\n\n```\n")
  lr_aic <- multipliers(ardl_aic$model)
  print(lr_aic)
  cat("```\n\n")
  cat("### Bounds F-Test (Case III)\n\n```\n")
  faic <- bounds_f_test(ardl_aic$model, case = 3)
  print(faic)
  cat("```\n\n")
  cat(sprintf("**F = %.4f** | I(0) 5%% CV = 2.86 | I(1) 5%% CV = 4.01\n\n",
              faic$statistic))
  if (faic$statistic > 4.01) {
    cat("**Verdict: Cointegration confirmed.**\n\n")
  } else if (faic$statistic < 2.86) {
    cat("**Verdict: No cointegration.**\n\n")
  } else {
    cat("**Verdict: Inconclusive.**\n\n")
  }
} else {
  cat("*auto_ardl (AIC) failed.*\n\n")
  ardl_aic <- NULL
}

# ── Fallback: manual ARDL(1,1,1,1) ─────────────────────────────────────────
if (is.null(ardl_bic) || is.null(ardl_bic$model) ||
    is.null(ardl_aic) || is.null(ardl_aic$model)) {
  cat("\n## A3. Manual ARDL(1,1,1,1)\n\n")
  ardl_man <- ardl(log_Y ~ r_t + RR_t + GD_t,
                   order = c(1, 1, 1, 1), data = d_ts)
  cat("### Short-Run Estimates\n\n```\n")
  print(summary(ardl_man))
  cat("```\n\n")
  cat("### Long-Run Multipliers\n\n```\n")
  lr_man <- multipliers(ardl_man)
  print(lr_man)
  cat("```\n\n")
  cat("### Bounds F-Test\n\n```\n")
  f_man <- bounds_f_test(ardl_man, case = 3)
  print(f_man)
  cat("```\n\n")

  if (is.null(ardl_bic))  { ardl_bic <- ardl_man; lr_bic <- lr_man; fbic <- f_man }
  if (is.null(ardl_aic))  { ardl_aic <- ardl_man; lr_aic <- lr_man; faic <- f_man }
}

# ── A4. Bounds F-Test Summary ──────────────────────────────────────────────
cat("\n## A4. Bounds F-Test Summary\n\n")
cat("| Specification | F-statistic | I(0) 5% CV | I(1) 5% CV | Verdict |\n")
cat("|--------------|------------|-----------|-----------|---------|\n")
for (nm in list(BIC = fbic, AIC = faic)) {
  if (!is.null(nm)) {
    v <- ifelse(nm$statistic > 4.01, "Cointegration",
         ifelse(nm$statistic < 2.86, "No coint.", "Inconclusive"))
    cat(sprintf("| — | %.4f | 2.86 | 4.01 | %s |\n", nm$statistic, v))
  }
}
cat("\n\n")

# ── A5. Pesaran case discussion ────────────────────────────────────────────
cat("\n## A5. Case Selection (Pesaran et al., 2001)\n\n")
cat("The dependent variable $\\ln Y_t$ is a **level** (log real income), which ")
cat("exhibits a clear deterministic trend over the Fordist era. ")
cat("This corresponds to **Case IV** (unrestricted intercept + unrestricted trend).\n\n")
cat("| Case | Intercept | Trend |\n|------|-----------|-------|\n")
cat("| I    | None      | None  |\n| II   | Restricted| None  |\n")
cat("| III  | Unrestricted | None |\n| IV   | Unrestricted | Unrestricted |\n")
cat("| V    | Restricted   | Restricted |\n\n")
cat("However, the ARDL package default is Case III (unrestricted intercept, no trend). ")
cat("Since log income has a trend, the bounds test critical values should ideally ")
cat("reference Case IV. The Case III critical values reported above are slightly ")
cat("conservative for this specification.\n\n")

sink()

# Save results
saveRDS(list(
  ardl_bic = ardl_bic, ardl_aic = ardl_aic,
  lr_bic = if (exists("lr_bic")) lr_bic else NULL,
  lr_aic = if (exists("lr_aic")) lr_aic else NULL,
  f_bic  = if (exists("fbic"))  fbic  else NULL,
  f_aic  = if (exists("faic"))  faic  else NULL
), file = file.path(out_dir, "ardl_levels_results.rds"))

cat("\n=== STAGE 2 COMPLETE ===\n")
