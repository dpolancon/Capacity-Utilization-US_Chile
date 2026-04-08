# 23_ardl_extended_netK_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# Stage C: ARDL Extended Sample Estimations — US NF Corporate Sector
#
# 4 core estimations (2 specs x 2 samples) + WWII dummy evaluation
#   Spec 3ch: g_Kn ~ r + mu + pi
#   Spec 4ch: g_Kn ~ mu + B_real + PyPK + pi
#   Sample A: 1930-1973 (N~44, max_order=3)
#   Sample B: 1940-1973 (N~34, max_order=2)
#
# Method: Pesaran, Shin & Smith (2001)
# Bounds tests: Cases 2, 3, 5
# ═══════════════════════════════════════════════════════════════════════════════

library(readr)
library(dplyr)
library(tibble)
library(ARDL)
library(urca)
library(tseries)
library(lmtest)
library(car)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
csv_dir <- file.path(REPO, "output/stage_c/US/csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

ds <- read_csv(file.path(REPO, "data/processed/us_nf_corporate_stageC.csv"),
               show_col_types = FALSE)
ds$D_wwii <- ifelse(ds$year >= 1941 & ds$year <= 1945, 1, 0)


# ═══════════════════════════════════════════════════════════════════════════════
# WORKHORSE FUNCTION
# ═══════════════════════════════════════════════════════════════════════════════

run_ardl <- function(ds, spec_name, formula_obj, sample_start, sample_end,
                     max_ord, k, csv_dir, run_wald = FALSE) {

  tag <- sprintf("%s_%d%d_N%d", spec_name, sample_start, sample_end,
                 sample_end - sample_start + 1)
  nominal_N <- sample_end - sample_start + 1

  cat(sprintf("\n%s\n", strrep("=", 70)))
  cat(sprintf("ESTIMATION: %s | %d-%d (nominal N=%d) | max_order=%d\n",
      spec_name, sample_start, sample_end, nominal_N, max_ord))
  cat(strrep("=", 70), "\n")

  # ── Data ──────────────────────────────────────────────────────────────────
  buf <- max_ord + 1
  df <- ds %>%
    filter(year >= (sample_start - buf), year <= sample_end) %>%
    arrange(year)

  vars_needed <- all.vars(formula_obj)
  df_ts <- ts(df[, c("year", vars_needed)],
              start = min(df$year), frequency = 1)

  # ── 1. Model selection ────────────────────────────────────────────────────
  cat("\n--- Model Selection ---\n")
  auto <- auto_ardl(formula_obj, data = df_ts, max_order = max_ord,
                    selection = "AIC")
  best <- auto$best_model
  best_order <- auto$best_order
  eff_N <- nobs(best)

  cat(sprintf("Selected: ARDL(%s) | Effective N=%d | Params=%d | df=%d\n",
      paste(best_order, collapse = ","), eff_N, length(coef(best)),
      eff_N - length(coef(best))))

  # Top 5
  top5 <- tibble()
  for (i in 1:min(5, nrow(auto$top_orders))) {
    ord <- as.numeric(auto$top_orders[i, 1:(k+1)])
    m <- tryCatch(ardl(formula_obj, data = df_ts, order = ord),
                  error = function(e) NULL)
    if (!is.null(m)) {
      top5 <- bind_rows(top5, tibble(
        rank = i, order = paste(ord, collapse = ","),
        AIC = AIC(m), BIC = BIC(m),
        n_eff = nobs(m), df_resid = nobs(m) - length(coef(m))
      ))
    }
  }
  cat("\nTop 5:\n")
  print(top5)
  write_csv(top5, file.path(csv_dir, sprintf("stageC_US_netK_%s_top5_models.csv", tag)))

  # ── 2. Coefficients ──────────────────────────────────────────────────────
  cat("\n--- ARDL Coefficients ---\n")
  print(summary(best))

  best_cf <- summary(best)$coefficients
  coef_df <- tibble(term = rownames(best_cf), estimate = best_cf[,1],
                    se = best_cf[,2], t_stat = best_cf[,3], p_value = best_cf[,4])
  write_csv(coef_df, file.path(csv_dir, sprintf("stageC_US_netK_%s_ardl_coefficients.csv", tag)))

  # ── 3. Bounds tests (all 5 PSS cases) ─────────────────────────────────────
  cat("\n--- Bounds Tests (all 5 PSS 2001 cases) ---\n")

  # Trend-augmented model for Cases 4 and 5
  # The ARDL package trend() must be called in a scope where df_ts is visible.
  # We assign df_ts to the global environment temporarily.
  assign("..ardl_ts_tmp", df_ts, envir = .GlobalEnv)
  auto_trend <- tryCatch({
    f_trend <- update(formula_obj, . ~ . + trend(..ardl_ts_tmp))
    auto_ardl(f_trend, data = ..ardl_ts_tmp, max_order = max_ord, selection = "AIC")
  }, error = function(e) {
    cat(sprintf("  Trend model failed: %s\n", e$message))
    NULL
  })
  rm("..ardl_ts_tmp", envir = .GlobalEnv)

  bounds_res <- tibble()
  for (case_num in 1:5) {
    m_test <- if (case_num %in% c(4, 5) && !is.null(auto_trend)) auto_trend$best_model else best

    bf <- tryCatch(bounds_f_test(m_test, case = case_num),
                   error = function(e) list(statistic = NA, p.value = NA))
    bt <- tryCatch(bounds_t_test(m_test, case = case_num),
                   error = function(e) list(statistic = NA, p.value = NA))

    bounds_res <- bind_rows(bounds_res, tibble(
      case = case_num,
      F_stat = ifelse(is.null(bf$statistic), NA, bf$statistic),
      F_p = ifelse(is.null(bf$p.value), NA, bf$p.value),
      t_stat = ifelse(is.null(bt$statistic), NA, bt$statistic),
      t_p = ifelse(is.null(bt$p.value), NA, bt$p.value)
    ))

    f_dec <- ifelse(is.na(bf$p.value), "N/A",
             ifelse(bf$p.value < 0.01, "Reject 1%",
             ifelse(bf$p.value < 0.05, "Reject 5%",
             ifelse(bf$p.value < 0.10, "Reject 10%", "Fail"))))
    t_dec <- ifelse(is.na(bt$p.value), "N/A",
             ifelse(bt$p.value < 0.01, "Reject 1%",
             ifelse(bt$p.value < 0.05, "Reject 5%",
             ifelse(bt$p.value < 0.10, "Reject 10%", "Fail"))))

    cat(sprintf("  Case %d: F=%.3f (p=%.4f) %s | t=%.3f (p=%.4f) %s\n",
        case_num,
        ifelse(is.na(bf$statistic), NA, bf$statistic),
        ifelse(is.na(bf$p.value), NA, bf$p.value), f_dec,
        ifelse(is.na(bt$statistic), NA, bt$statistic),
        ifelse(is.na(bt$p.value), NA, bt$p.value), t_dec))
  }
  write_csv(bounds_res, file.path(csv_dir, sprintf("stageC_US_netK_%s_bounds_tests.csv", tag)))

  # ── 4. Long-run multipliers ──────────────────────────────────────────────
  cat("\n--- Long-Run Multipliers ---\n")
  lr <- multipliers(best)
  print(lr)
  write_csv(as.data.frame(lr), file.path(csv_dir,
            sprintf("stageC_US_netK_%s_longrun_multipliers.csv", tag)))

  # ── 5. ECM ──────────────────────────────────────────────────────────────
  cat("\n--- ECM (Case 3) ---\n")
  ecm <- recm(best, case = 3)
  print(summary(ecm))

  ecm_cf <- summary(ecm)$coefficients
  ecm_df <- tibble(term = rownames(ecm_cf), estimate = ecm_cf[,1],
                   se = ecm_cf[,2], t_stat = ecm_cf[,3], p_value = ecm_cf[,4])
  write_csv(ecm_df, file.path(csv_dir, sprintf("stageC_US_netK_%s_ecm_coefficients.csv", tag)))

  ect_row <- which(ecm_df$term == "ect")
  ect_coef <- ecm_df$estimate[ect_row]
  ect_t <- ecm_df$t_stat[ect_row]
  hl <- if (ect_coef < 0) log(0.5) / log(1 + ect_coef) else NA
  full_adj <- if (ect_coef < 0) log(0.05) / log(1 + ect_coef) else NA

  # Bounds t is authoritative
  bt3 <- bounds_res %>% filter(case == 3)
  cat(sprintf("\nECT: %.4f (OLS t=%.3f) | Bounds t (Case 3): %.3f (p=%.4f)\n",
      ect_coef, ect_t, bt3$t_stat, bt3$t_p))
  cat(sprintf("Half-life: %.2f years | 95%% adj: %.1f years\n", hl, full_adj))

  # ── 6. Wald test (4ch only) ────────────────────────────────────────────
  wald_result <- NULL
  if (run_wald) {
    cat("\n--- Wald Test: H0: beta_mu = beta_PyPK + beta_Br ---\n")
    ardl_names <- names(coef(best))

    mu_nms   <- grep("^(mu|L\\(mu)", ardl_names, value = TRUE)
    br_nms   <- grep("^(B_real|L\\(B_real)", ardl_names, value = TRUE)
    pypk_nms <- grep("^(PyPK|L\\(PyPK)", ardl_names, value = TRUE)

    R <- rep(0, length(coef(best)))
    names(R) <- ardl_names
    for (nm in mu_nms)   R[nm] <- R[nm] + 1
    for (nm in br_nms)   R[nm] <- R[nm] - 1
    for (nm in pypk_nms) R[nm] <- R[nm] - 1

    diff_val <- sum(R * coef(best))
    V <- vcov(best)
    se_diff <- as.numeric(sqrt(t(R) %*% V %*% R))
    wald_t <- diff_val / se_diff
    wald_p <- 2 * pt(-abs(wald_t), df = nobs(best) - length(coef(best)))

    cat(sprintf("  Diff (mu - PyPK - Br numerators): %.4f  SE: %.4f\n", diff_val, se_diff))
    cat(sprintf("  Wald t: %.4f  p: %.4f  %s\n", wald_t, wald_p,
        ifelse(wald_p < 0.05, "REJECT H0", "FAIL TO REJECT")))

    wald_result <- tibble(diff = diff_val, se = se_diff,
                          t_stat = wald_t, p_value = wald_p)
  }

  # ── 7. Diagnostics ────────────────────────────────────────────────────
  cat("\n--- Diagnostics ---\n")
  bg1 <- bgtest(best, order = 1)
  bg2 <- bgtest(best, order = 2)
  bp  <- bptest(best)
  jb  <- jarque.bera.test(residuals(best))
  rst <- resettest(best, power = 2, type = "fitted")

  diag_df <- tibble(
    test = c("BG(1)", "BG(2)", "Breusch-Pagan", "Jarque-Bera", "RESET"),
    statistic = c(bg1$statistic, bg2$statistic, bp$statistic, jb$statistic, rst$statistic),
    p_value = c(bg1$p.value, bg2$p.value, bp$p.value, jb$p.value, rst$p.value)
  )
  for (i in 1:nrow(diag_df)) {
    cat(sprintf("  %-15s stat=%.3f  p=%.4f  %s\n", diag_df$test[i],
        diag_df$statistic[i], diag_df$p_value[i],
        ifelse(diag_df$p_value[i] > 0.05, "PASS", "WARNING")))
  }
  write_csv(diag_df, file.path(csv_dir, sprintf("stageC_US_netK_%s_diagnostics.csv", tag)))

  s <- summary(best)
  cat(sprintf("\nR2=%.4f  adjR2=%.4f\n", s$r.squared, s$adj.r.squared))

  # ── Return ────────────────────────────────────────────────────────────
  list(
    tag = tag, spec = spec_name,
    sample = sprintf("%d-%d", sample_start, sample_end),
    nominal_N = nominal_N, eff_N = eff_N,
    best_order = paste(best_order, collapse = ","),
    AIC = AIC(best), BIC = BIC(best),
    R2 = s$r.squared, adjR2 = s$adj.r.squared,
    lr = lr,
    ect = ect_coef, ect_ols_t = ect_t,
    bounds_t_case3 = bt3$t_stat, bounds_t_p = bt3$t_p,
    bounds_F_case3 = (bounds_res %>% filter(case == 3))$F_stat,
    bounds_F_p = (bounds_res %>% filter(case == 3))$F_p,
    half_life = hl,
    wald = wald_result,
    diagnostics = diag_df,
    bounds_all = bounds_res
  )
}


# ═══════════════════════════════════════════════════════════════════════════════
# WWII DUMMY COMPARISON
# ═══════════════════════════════════════════════════════════════════════════════

compare_wwii <- function(ds, spec_name, formula_obj, sample_start, sample_end,
                         max_ord, k, csv_dir) {

  tag <- sprintf("%s_%d%d_N%d", spec_name, sample_start, sample_end,
                 sample_end - sample_start + 1)

  cat(sprintf("\n--- WWII Dummy Comparison: %s ---\n", tag))

  buf <- max_ord + 1
  df <- ds %>%
    filter(year >= (sample_start - buf), year <= sample_end) %>%
    arrange(year)

  vars_needed <- c(all.vars(formula_obj), "D_wwii")
  df_ts <- ts(df[, c("year", vars_needed)],
              start = min(df$year), frequency = 1)

  # Base model (already run)
  auto_base <- auto_ardl(formula_obj, data = df_ts, max_order = max_ord,
                         selection = "AIC")

  # Augmented model with D_wwii
  formula_wwii <- update(formula_obj, . ~ . + D_wwii)

  # For auto_ardl with mixed max_order: pass vector
  # k+1 base vars + D_wwii; D_wwii gets max_order=0
  max_ord_vec <- c(rep(max_ord, k + 1), 0)

  auto_wwii <- tryCatch(
    auto_ardl(formula_wwii, data = df_ts, max_order = max_ord_vec,
              selection = "AIC"),
    error = function(e) {
      cat(sprintf("  auto_ardl with D_wwii failed: %s\n", e$message))
      # Fallback: manually fit with same order + D_wwii at order 0
      base_ord <- auto_base$best_order
      ord_wwii <- c(as.numeric(base_ord), 0)
      m <- tryCatch(ardl(formula_wwii, data = df_ts, order = ord_wwii),
                    error = function(e2) NULL)
      if (!is.null(m)) list(best_model = m, best_order = ord_wwii) else NULL
    }
  )

  if (is.null(auto_wwii)) {
    cat("  WWII dummy comparison failed.\n")
    return(NULL)
  }

  base_aic <- AIC(auto_base$best_model)
  base_bic <- BIC(auto_base$best_model)
  wwii_aic <- AIC(auto_wwii$best_model)
  wwii_bic <- BIC(auto_wwii$best_model)

  comp <- tibble(
    model = c("Base", "D_wwii"),
    order = c(paste(auto_base$best_order, collapse = ","),
              paste(auto_wwii$best_order, collapse = ",")),
    AIC = c(base_aic, wwii_aic),
    BIC = c(base_bic, wwii_bic),
    delta_AIC = c(0, wwii_aic - base_aic),
    delta_BIC = c(0, wwii_bic - base_bic)
  )

  prefer <- ifelse(wwii_aic < base_aic & wwii_bic < base_bic, "D_wwii preferred",
            ifelse(wwii_aic < base_aic, "D_wwii by AIC only",
            "Base preferred"))

  cat(sprintf("  Base AIC=%.2f BIC=%.2f | WWII AIC=%.2f BIC=%.2f | %s\n",
      base_aic, base_bic, wwii_aic, wwii_bic, prefer))

  # D_wwii coefficient if available
  wwii_cf <- summary(auto_wwii$best_model)$coefficients
  dwwii_row <- grep("D_wwii", rownames(wwii_cf))
  if (length(dwwii_row) > 0) {
    comp$D_wwii_coef <- c(NA, wwii_cf[dwwii_row, "Estimate"])
    comp$D_wwii_t    <- c(NA, wwii_cf[dwwii_row, "t value"])
    comp$D_wwii_p    <- c(NA, wwii_cf[dwwii_row, "Pr(>|t|)"])
    cat(sprintf("  D_wwii coef=%.4f (t=%.2f, p=%.4f)\n",
        wwii_cf[dwwii_row, "Estimate"], wwii_cf[dwwii_row, "t value"],
        wwii_cf[dwwii_row, "Pr(>|t|)"]))
  }

  write_csv(comp, file.path(csv_dir, sprintf("stageC_US_netK_%s_wwii_comparison.csv", tag)))
  comp
}


# ═══════════════════════════════════════════════════════════════════════════════
# EXECUTE 4 CORE ESTIMATIONS
# ═══════════════════════════════════════════════════════════════════════════════

results <- list()

# 1. 3ch, 1930-1973
results[["3ch_1930"]] <- run_ardl(ds, "3ch", g_Kn ~ r + mu + pi,
  1930, 1973, max_ord = 3, k = 3, csv_dir)

# 2. 4ch, 1930-1973
results[["4ch_1930"]] <- run_ardl(ds, "4ch", g_Kn ~ mu + B_real + PyPK + pi,
  1930, 1973, max_ord = 3, k = 4, csv_dir, run_wald = TRUE)

# 3. 3ch, 1940-1973
results[["3ch_1940"]] <- run_ardl(ds, "3ch", g_Kn ~ r + mu + pi,
  1940, 1973, max_ord = 2, k = 3, csv_dir)

# 4. 4ch, 1940-1973
results[["4ch_1940"]] <- run_ardl(ds, "4ch", g_Kn ~ mu + B_real + PyPK + pi,
  1940, 1973, max_ord = 2, k = 4, csv_dir, run_wald = TRUE)

# 5. 3ch, 1947-1974 (Fordist core + 1 year post)
results[["3ch_1947"]] <- run_ardl(ds, "3ch", g_Kn ~ r + mu + pi,
  1947, 1974, max_ord = 2, k = 3, csv_dir)

# 6. 4ch, 1947-1974
results[["4ch_1947"]] <- run_ardl(ds, "4ch", g_Kn ~ mu + B_real + PyPK + pi,
  1947, 1974, max_ord = 2, k = 4, csv_dir, run_wald = TRUE)


# ═══════════════════════════════════════════════════════════════════════════════
# WWII DUMMY EVALUATION (1930-1973 samples only)
# ═══════════════════════════════════════════════════════════════════════════════

wwii_3ch <- compare_wwii(ds, "3ch", g_Kn ~ r + mu + pi,
  1930, 1973, max_ord = 3, k = 3, csv_dir)

wwii_4ch <- compare_wwii(ds, "4ch", g_Kn ~ mu + B_real + PyPK + pi,
  1930, 1973, max_ord = 3, k = 4, csv_dir)


# ═══════════════════════════════════════════════════════════════════════════════
# CONSOLIDATED SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 90), "\n")
cat("CONSOLIDATED RESULTS\n")
cat(strrep("=", 90), "\n")

summary_tbl <- tibble()
for (nm in names(results)) {
  r <- results[[nm]]
  lr_mu <- r$lr$Estimate[r$lr$Term == "mu"]
  lr_mu_p <- r$lr$`Pr(>|t|)`[r$lr$Term == "mu"]

  summary_tbl <- bind_rows(summary_tbl, tibble(
    est = nm, spec = r$spec, sample = r$sample,
    eff_N = r$eff_N, order = r$best_order,
    AIC = r$AIC, R2 = r$R2, adjR2 = r$adjR2,
    F_case3 = r$bounds_F_case3, F_p = r$bounds_F_p,
    t_case3 = r$bounds_t_case3, t_p = r$bounds_t_p,
    ECT = r$ect, half_life = r$half_life,
    LR_mu = lr_mu, LR_mu_p = lr_mu_p,
    wald_t = ifelse(!is.null(r$wald), r$wald$t_stat, NA),
    wald_p = ifelse(!is.null(r$wald), r$wald$p_value, NA)
  ))
}

print(summary_tbl)
write_csv(summary_tbl, file.path(csv_dir, "stageC_US_netK_extended_summary.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# GENERATE REPORT
# ═══════════════════════════════════════════════════════════════════════════════

rpt <- c(
"# Stage C Report — ARDL Extended Sample Estimations",
"## US Non-Financial Corporate Sector",
sprintf("**Date:** %s | **Script:** 23_ardl_extended_netK_us.R", Sys.Date()),
"",
"---",
"",
"## 1. Overview",
"",
"| Estimation | Spec | Sample | Eff N | Order | AIC | R2 | Adj R2 | F(Case3) | F p | t(Case3) | t p | ECT | Half-life | LR mu | mu p |",
"|------------|------|--------|-------|-------|-----|-----|--------|----------|-----|----------|-----|-----|-----------|-------|------|"
)

for (i in 1:nrow(summary_tbl)) {
  s <- summary_tbl[i,]
  rpt <- c(rpt, sprintf("| %s | %s | %s | %d | %s | %.1f | %.3f | %.3f | %.3f | %.4f | %.3f | %.4f | %.3f | %.1f | %.3f | %.4f |",
    s$est, s$spec, s$sample, s$eff_N, s$order, s$AIC, s$R2, s$adjR2,
    s$F_case3, s$F_p, s$t_case3, s$t_p, s$ECT, s$half_life, s$LR_mu, s$LR_mu_p))
}

rpt <- c(rpt, "", "---", "")

# Section for each estimation
for (nm in names(results)) {
  r <- results[[nm]]
  rpt <- c(rpt,
    sprintf("## %s", r$tag), "",
    sprintf("**Sample:** %s | **Effective N:** %d | **Model:** ARDL(%s)",
            r$sample, r$eff_N, r$best_order), "",

    "### Bounds Tests", "",
    "| Case | F-stat | F p-value | t-stat | t p-value |",
    "|------|--------|-----------|--------|-----------|"
  )
  for (j in 1:nrow(r$bounds_all)) {
    b <- r$bounds_all[j,]
    rpt <- c(rpt, sprintf("| %d | %.3f | %.4f | %.3f | %.4f |",
      b$case,
      ifelse(is.na(b$F_stat), NA, b$F_stat),
      ifelse(is.na(b$F_p), NA, b$F_p),
      ifelse(is.na(b$t_stat), NA, b$t_stat),
      ifelse(is.na(b$t_p), NA, b$t_p)))
  }

  rpt <- c(rpt, "", "### Long-Run Multipliers", "",
    "| Variable | Estimate | SE | t-stat | p-value |",
    "|----------|---------|-----|--------|---------|")
  for (j in 1:nrow(r$lr)) {
    rpt <- c(rpt, sprintf("| %s | %.4f | %.4f | %.3f | %.4f |",
      r$lr$Term[j], r$lr$Estimate[j], r$lr$`Std. Error`[j],
      r$lr$`t value`[j], r$lr$`Pr(>|t|)`[j]))
  }

  rpt <- c(rpt, "",
    sprintf("### ECM (Case 3)"), "",
    sprintf("- **ECT:** %.4f (OLS t=%.3f)", r$ect, r$ect_ols_t),
    sprintf("- **Bounds t (Case 3):** %.3f (p=%.4f) — %s",
      r$bounds_t_case3, r$bounds_t_p,
      ifelse(r$bounds_t_p < 0.05, "REJECTS H0 at 5%",
      ifelse(r$bounds_t_p < 0.10, "REJECTS H0 at 10%", "inconclusive"))),
    "- **Note:** Only the bounds t-test provides valid inference on the ECT in ARDL models.",
    sprintf("- **Half-life:** %.2f years | **95%% adjustment:** %.1f years",
      r$half_life, ifelse(r$ect < 0, log(0.05)/log(1+r$ect), NA))
  )

  if (!is.null(r$wald)) {
    rpt <- c(rpt, "",
      "### Wald Test: H0: beta_mu = beta_PyPK + beta_Br", "",
      sprintf("- Difference: %.4f | SE: %.4f | t: %.4f | p: %.4f",
        r$wald$diff, r$wald$se, r$wald$t_stat, r$wald$p_value),
      sprintf("- Decision: **%s**",
        ifelse(r$wald$p_value < 0.05, "REJECT H0 — channels are distinct",
               "FAIL TO REJECT H0")))
  }

  rpt <- c(rpt, "", "### Diagnostics", "",
    "| Test | Statistic | p-value | Decision |",
    "|------|----------|---------|----------|")
  for (j in 1:nrow(r$diagnostics)) {
    d <- r$diagnostics[j,]
    rpt <- c(rpt, sprintf("| %s | %.3f | %.4f | %s |",
      d$test, d$statistic, d$p_value,
      ifelse(d$p_value > 0.05, "PASS", "WARNING")))
  }

  rpt <- c(rpt, "", "---", "")
}

# WWII section
rpt <- c(rpt, "## WWII Dummy Evaluation (1930-1973 samples)", "")
if (!is.null(wwii_3ch)) {
  rpt <- c(rpt, "### 3-channel", "")
  for (j in 1:nrow(wwii_3ch)) {
    rpt <- c(rpt, sprintf("- %s: AIC=%.2f BIC=%.2f",
      wwii_3ch$model[j], wwii_3ch$AIC[j], wwii_3ch$BIC[j]))
  }
}
if (!is.null(wwii_4ch)) {
  rpt <- c(rpt, "", "### 4-channel", "")
  for (j in 1:nrow(wwii_4ch)) {
    rpt <- c(rpt, sprintf("- %s: AIC=%.2f BIC=%.2f",
      wwii_4ch$model[j], wwii_4ch$AIC[j], wwii_4ch$BIC[j]))
  }
}

# Cross-sample stability
rpt <- c(rpt, "", "---", "",
  "## Cross-Sample Stability", "",
  "### Long-run mu multiplier across samples", "",
  "| Spec | 1930-1973 | 1940-1973 | 1948-1973 (prev) |",
  "|------|-----------|-----------|------------------|")

for (sp in c("3ch", "4ch")) {
  lr_30 <- results[[paste0(sp, "_1930")]]$lr
  lr_40 <- results[[paste0(sp, "_1940")]]$lr
  mu_30 <- lr_30$Estimate[lr_30$Term == "mu"]
  mu_40 <- lr_40$Estimate[lr_40$Term == "mu"]
  prev  <- ifelse(sp == "4ch", "0.639", "0.276")
  rpt <- c(rpt, sprintf("| %s | %.3f | %.3f | %s |", sp, mu_30, mu_40, prev))
}

rpt <- c(rpt, "", "---", "",
  sprintf("*Script: codes/stage_c/us/23_ardl_extended_netK_us.R*"),
  sprintf("*Generated: %s*", Sys.Date()))

writeLines(rpt, file.path(REPO, "output/stage_c/US/stageC_US_netK_ardl_extended_report.md"))
cat("\nReport saved.\n")

cat("\n", strrep("=", 70), "\n")
cat("All extended sample estimations complete.\n")
cat(strrep("=", 70), "\n")
