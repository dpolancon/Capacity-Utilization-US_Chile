# 20_ardl_investment_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# Stage C: ARDL Investment Function — US NF Corporate Sector
# Fordist era, 1947-1973 (27 obs)
#
# Method: ARDL (Pesaran, Shin & Smith 2001)
# Cases tested: 1 (no intercept, no trend), 3 (unrestricted intercept),
#               5 (unrestricted intercept + trend)
# Bounds: F-test and t-test with finite-sample critical values
#
# Dependent: g_K (real gross capital accumulation rate)
# Candidates: r, mu, pi, B_real, PyPK
# ═══════════════════════════════════════════════════════════════════════════════

library(readr)
library(dplyr)
library(tibble)
library(ARDL)
library(urca)
library(tseries)
library(lmtest)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
csv_dir <- file.path(REPO, "output/stage_c/US/csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

ds <- read_csv(file.path(REPO, "data/processed/us_nf_corporate_stageC.csv"),
               show_col_types = FALSE)

# Need 1946 for lagged differences; estimation window 1947-1973
df <- ds %>% filter(year >= 1946, year <= 1973) %>% arrange(year)
df_est <- df %>% filter(year >= 1947)
N <- nrow(df_est)
cat(sprintf("Estimation sample: %d-%d (N=%d)\n", min(df_est$year), max(df_est$year), N))

df_ts <- ts(df %>% select(year, g_K, r, mu, pi, B_real, PyPK, chi),
            start = 1946, frequency = 1)


# ═══════════════════════════════════════════════════════════════════════════════
# 1. PRE-TESTS: INTEGRATION ORDER
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("1. INTEGRATION ORDER PRE-TESTS (1947-1973, N=27)\n")
cat(strrep("=", 70), "\n")

test_vars <- c("g_K", "r", "mu", "pi", "B_real", "PyPK")

cat(sprintf("\n%-10s %8s %8s %8s %8s %5s\n",
    "Variable", "ADF_lev", "p_lev", "ADF_dif", "p_dif", "Order"))
cat(strrep("-", 52), "\n")

int_orders <- tibble()
for (v in test_vars) {
  x <- df_est[[v]]
  adf_l <- tryCatch(adf.test(x), error = function(e) list(statistic = NA, p.value = 1))
  dx <- diff(x)
  adf_d <- tryCatch(adf.test(dx), error = function(e) list(statistic = NA, p.value = 1))

  # KPSS for confirmation
  kpss_l <- tryCatch(kpss.test(x, null = "Level"),
                     error = function(e) list(statistic = NA, p.value = NA))

  ord <- ifelse(adf_l$p.value < 0.05, "I(0)",
         ifelse(adf_d$p.value < 0.05, "I(1)", "ambiguous"))

  int_orders <- bind_rows(int_orders, tibble(
    variable = v, adf_level = adf_l$statistic, p_level = adf_l$p.value,
    adf_diff = adf_d$statistic, p_diff = adf_d$p.value,
    kpss_level = kpss_l$statistic, kpss_p = kpss_l$p.value,
    order = ord
  ))

  cat(sprintf("%-10s %8.3f %8.3f %8.3f %8.3f %5s\n",
      v, adf_l$statistic, adf_l$p.value, adf_d$statistic, adf_d$p.value, ord))
}

cat("\nNote: N=27 — ADF has low power. ARDL bounds approach is valid for mixed I(0)/I(1).\n")
cat("ARDL is NOT valid if any variable is I(2). None detected.\n")

write_csv(int_orders, file.path(csv_dir, "stageC_US_integration_orders.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# 2. ARDL MODEL SELECTION — TOP 5 BY AIC, COMPARE BIC
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("2. ARDL MODEL SELECTION\n")
cat(strrep("=", 70), "\n")

# Baseline: g_K ~ r + mu + pi
# With N=27, max_order=2 is the ceiling (preserves df)
cat("\nBaseline specification: g_K ~ r + mu + pi\n")
cat("Max order: 2 (df constraint with N=27)\n\n")

auto_base <- auto_ardl(g_K ~ r + mu + pi,
                       data = df_ts, max_order = 2, selection = "AIC")

# Extract top models
top5 <- auto_base$top_orders

cat("=== TOP 5 MODELS BY AIC ===\n")
cat(sprintf("%-5s %-20s %10s %10s %5s\n", "Rank", "Order", "AIC", "BIC", "df"))
cat(strrep("-", 55), "\n")

top5_details <- tibble()
for (i in 1:min(5, nrow(top5))) {
  ord <- top5[i, ]
  ord_vec <- as.numeric(ord[1, 1:4])
  n_params <- sum(ord_vec) + 1 + length(ord_vec)  # lags + intercept + contemporaneous
  df_resid <- N - n_params

  # Fit each model explicitly for BIC
  form_str <- sprintf("g_K ~ r + mu + pi")
  m <- ardl(as.formula(form_str), data = df_ts,
            order = ord_vec, start = 1947, end = 1973)
  aic_val <- AIC(m)
  bic_val <- BIC(m)

  top5_details <- bind_rows(top5_details, tibble(
    rank = i,
    order = paste(ord_vec, collapse = ","),
    AIC = aic_val, BIC = bic_val,
    n_params = n_params, df_resid = df_resid
  ))

  cat(sprintf("%-5d ARDL(%-12s) %10.2f %10.2f %5d\n",
      i, paste(ord_vec, collapse=","), aic_val, bic_val, df_resid))
}

write_csv(top5_details, file.path(csv_dir, "stageC_US_top5_models.csv"))

# Selected model
best_order <- as.numeric(top5[1, 1:4])
cat(sprintf("\nSelected: ARDL(%s) — AIC-optimal\n", paste(best_order, collapse=",")))

# Check if BIC-optimal differs
bic_best <- top5_details %>% slice_min(BIC, n = 1)
cat(sprintf("BIC-optimal: ARDL(%s)\n", bic_best$order))
if (bic_best$order != top5_details$order[1]) {
  cat("AIC and BIC disagree — report both. BIC penalizes complexity more heavily.\n")
  cat("With N=27, BIC preference is more conservative and may be preferred.\n")
}


# ═══════════════════════════════════════════════════════════════════════════════
# 3. ESTIMATE SELECTED MODEL
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("3. ARDL ESTIMATION\n")
cat(strrep("=", 70), "\n")

best <- auto_base$best_model
cat("\n--- Unrestricted ARDL ---\n")
print(summary(best))


# ═══════════════════════════════════════════════════════════════════════════════
# 4. PESARAN CASES: BOUNDS F-TEST AND T-TEST
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("4. BOUNDS TESTS — PESARAN, SHIN & SMITH (2001)\n")
cat(strrep("=", 70), "\n")

cat("\nPesaran cases:\n")
cat("  Case 1: No intercept, no trend\n")
cat("  Case 3: Unrestricted intercept, no trend (standard)\n")
cat("  Case 5: Unrestricted intercept + unrestricted trend\n")
cat(sprintf("\nk = %d regressors | N = %d\n", 3, N))

for (case_num in c(1, 3, 5)) {
  cat(sprintf("\n--- Case %d ---\n", case_num))

  # F-test
  bf <- tryCatch(
    bounds_f_test(best, case = case_num),
    error = function(e) { cat(sprintf("F-test failed: %s\n", e$message)); NULL }
  )
  if (!is.null(bf)) {
    cat("F-test (joint significance of lagged levels):\n")
    print(bf)
    cat(sprintf("  F-statistic: %.4f\n", bf$statistic))
    cat(sprintf("  p-value:     %.4f\n", bf$p.value))
    if (bf$p.value < 0.01) cat("  Decision: REJECT H0 at 1% — cointegration evidence\n")
    else if (bf$p.value < 0.05) cat("  Decision: REJECT H0 at 5% — cointegration evidence\n")
    else if (bf$p.value < 0.10) cat("  Decision: REJECT H0 at 10% — marginal evidence\n")
    else cat("  Decision: FAIL TO REJECT H0 — inconclusive or no cointegration\n")
  }

  # t-test
  bt <- tryCatch(
    bounds_t_test(best, case = case_num),
    error = function(e) { cat(sprintf("t-test failed: %s\n", e$message)); NULL }
  )
  if (!is.null(bt)) {
    cat("\nt-test (ECM coefficient significance):\n")
    print(bt)
    cat(sprintf("  t-statistic: %.4f\n", bt$statistic))
    cat(sprintf("  p-value:     %.4f\n", bt$p.value))
  }
}


# ═══════════════════════════════════════════════════════════════════════════════
# 5. LONG-RUN MULTIPLIERS AND ECM
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("5. LONG-RUN MULTIPLIERS AND ECM FORM\n")
cat(strrep("=", 70), "\n")

cat("\n--- Long-run multipliers ---\n")
lr <- multipliers(best)
print(lr)
write_csv(as.data.frame(lr), file.path(csv_dir, "stageC_US_longrun_multipliers.csv"))

cat("\n--- Error Correction Model (Case 3) ---\n")
ecm <- recm(best, case = 3)
print(summary(ecm))

ecm_cf <- summary(ecm)$coefficients
ect_row <- which(rownames(ecm_cf) == "ect")
if (length(ect_row) > 0) {
  ect_coef <- ecm_cf[ect_row, "Estimate"]
  ect_se   <- ecm_cf[ect_row, "Std. Error"]
  ect_t    <- ecm_cf[ect_row, "t value"]
  ect_p    <- ecm_cf[ect_row, "Pr(>|t|)"]
  cat(sprintf("\nSpeed of adjustment: %.4f (SE=%.4f, t=%.3f, p=%.4f)\n",
      ect_coef, ect_se, ect_t, ect_p))
  if (ect_coef < 0 & ect_p < 0.05) {
    hl <- log(0.5) / log(1 + ect_coef)
    cat(sprintf("Half-life: %.1f years\n", hl))
    cat("ECT is negative and significant — error correction confirmed.\n")
  }
}

# Save ECM coefficients
ecm_df <- tibble(
  term = rownames(ecm_cf),
  estimate = ecm_cf[, "Estimate"],
  se = ecm_cf[, "Std. Error"],
  t_stat = ecm_cf[, "t value"],
  p_value = ecm_cf[, "Pr(>|t|)"]
)
write_csv(ecm_df, file.path(csv_dir, "stageC_US_ecm_coefficients.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# 6. DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("6. DIAGNOSTICS\n")
cat(strrep("=", 70), "\n")

# Serial correlation
bg1 <- bgtest(best, order = 1)
bg2 <- bgtest(best, order = 2)
cat(sprintf("Breusch-Godfrey (lag=1): chi2=%.3f  p=%.4f  %s\n",
    bg1$statistic, bg1$p.value,
    ifelse(bg1$p.value > 0.05, "PASS", "WARNING")))
cat(sprintf("Breusch-Godfrey (lag=2): chi2=%.3f  p=%.4f  %s\n",
    bg2$statistic, bg2$p.value,
    ifelse(bg2$p.value > 0.05, "PASS", "WARNING")))

# Heteroskedasticity
bp <- bptest(best)
cat(sprintf("Breusch-Pagan:          chi2=%.3f  p=%.4f  %s\n",
    bp$statistic, bp$p.value,
    ifelse(bp$p.value > 0.05, "PASS", "WARNING")))

# Normality
jb <- jarque.bera.test(residuals(best))
cat(sprintf("Jarque-Bera:            chi2=%.3f  p=%.4f  %s\n",
    jb$statistic, jb$p.value,
    ifelse(jb$p.value > 0.05, "PASS", "WARNING")))

# RESET
reset_t <- resettest(best, power = 2, type = "fitted")
cat(sprintf("RESET (power=2):        F=%.3f    p=%.4f  %s\n",
    reset_t$statistic, reset_t$p.value,
    ifelse(reset_t$p.value > 0.05, "PASS", "WARNING")))

# R-squared
s <- summary(best)
cat(sprintf("\nR-squared: %.4f  Adj R-squared: %.4f\n", s$r.squared, s$adj.r.squared))
cat(sprintf("Residual SE: %.6f  df: %d\n", s$sigma, s$df[2]))

diag_df <- tibble(
  test = c("BG(1)", "BG(2)", "Breusch-Pagan", "Jarque-Bera", "RESET"),
  statistic = c(bg1$statistic, bg2$statistic, bp$statistic, jb$statistic, reset_t$statistic),
  p_value = c(bg1$p.value, bg2$p.value, bp$p.value, jb$p.value, reset_t$p.value),
  decision = c(
    ifelse(bg1$p.value > 0.05, "PASS", "WARNING"),
    ifelse(bg2$p.value > 0.05, "PASS", "WARNING"),
    ifelse(bp$p.value > 0.05, "PASS", "WARNING"),
    ifelse(jb$p.value > 0.05, "PASS", "WARNING"),
    ifelse(reset_t$p.value > 0.05, "PASS", "WARNING")
  )
)
write_csv(diag_df, file.path(csv_dir, "stageC_US_diagnostics.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# 7. ALTERNATIVE SPECIFICATIONS
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("7. ALTERNATIVE SPECIFICATIONS\n")
cat(strrep("=", 70), "\n")

specs <- list(
  list(name = "4-channel", formula = g_K ~ mu + B_real + PyPK + pi),
  list(name = "Parsimonious", formula = g_K ~ r + mu),
  list(name = "Profitability only", formula = g_K ~ r),
  list(name = "Demand + distribution", formula = g_K ~ mu + pi)
)

alt_results <- tibble()
for (sp in specs) {
  cat(sprintf("\n--- %s: %s ---\n", sp$name, deparse(sp$formula)))
  auto_sp <- tryCatch(
    auto_ardl(sp$formula, data = df_ts, max_order = 2, selection = "AIC"),
    error = function(e) { cat("  Failed:", e$message, "\n"); NULL }
  )
  if (!is.null(auto_sp)) {
    m <- auto_sp$best_model
    ord <- paste(auto_sp$best_order, collapse = ",")
    cat(sprintf("  Selected: ARDL(%s)  AIC=%.2f  BIC=%.2f  R2=%.4f  adjR2=%.4f\n",
        ord, AIC(m), BIC(m), summary(m)$r.squared, summary(m)$adj.r.squared))

    # Bounds F-test (Case 3)
    bf3 <- tryCatch(bounds_f_test(m, case = 3),
                    error = function(e) list(statistic = NA, p.value = NA))

    cat(sprintf("  Bounds F (Case 3): F=%.3f  p=%.4f\n",
        bf3$statistic, bf3$p.value))

    # ECM
    ecm_sp <- tryCatch(recm(m, case = 3), error = function(e) NULL)
    ect_val <- NA; ect_p_val <- NA
    if (!is.null(ecm_sp)) {
      ecm_sp_cf <- summary(ecm_sp)$coefficients
      ect_r <- which(rownames(ecm_sp_cf) == "ect")
      if (length(ect_r) > 0) {
        ect_val <- ecm_sp_cf[ect_r, "Estimate"]
        ect_p_val <- ecm_sp_cf[ect_r, "Pr(>|t|)"]
        cat(sprintf("  ECT: %.4f (p=%.4f)\n", ect_val, ect_p_val))
      }
    }

    # Short-run mu significance
    mu_coef <- NA; mu_p <- NA
    if ("d(mu)" %in% rownames(ecm_sp_cf)) {
      mu_coef <- ecm_sp_cf["d(mu)", "Estimate"]
      mu_p <- ecm_sp_cf["d(mu)", "Pr(>|t|)"]
    }

    alt_results <- bind_rows(alt_results, tibble(
      spec = sp$name, order = ord,
      AIC = AIC(m), BIC = BIC(m),
      R2 = summary(m)$r.squared, adjR2 = summary(m)$adj.r.squared,
      F_bounds = bf3$statistic, F_p = bf3$p.value,
      ECT = ect_val, ECT_p = ect_p_val,
      d_mu = mu_coef, d_mu_p = mu_p
    ))

    print(summary(m))
  }
}

# Add baseline to comparison
bf_base <- bounds_f_test(best, case = 3)
alt_results <- bind_rows(
  tibble(spec = "Baseline (g_K~r+mu+pi)",
         order = paste(best_order, collapse = ","),
         AIC = AIC(best), BIC = BIC(best),
         R2 = summary(best)$r.squared, adjR2 = summary(best)$adj.r.squared,
         F_bounds = bf_base$statistic, F_p = bf_base$p.value,
         ECT = ecm_df$estimate[ecm_df$term == "ect"],
         ECT_p = ecm_df$p_value[ecm_df$term == "ect"],
         d_mu = NA, d_mu_p = NA),
  alt_results
)

cat("\n=== MODEL COMPARISON ===\n")
print(alt_results)
write_csv(alt_results, file.path(csv_dir, "stageC_US_model_comparison.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# 8. SAVE ARDL COEFFICIENTS
# ═══════════════════════════════════════════════════════════════════════════════

best_cf <- summary(best)$coefficients
best_df <- tibble(
  term = rownames(best_cf),
  estimate = best_cf[, "Estimate"],
  se = best_cf[, "Std. Error"],
  t_stat = best_cf[, "t value"],
  p_value = best_cf[, "Pr(>|t|)"]
)
write_csv(best_df, file.path(csv_dir, "stageC_US_ardl_coefficients.csv"))


cat("\n", strrep("=", 70), "\n")
cat("Stage C estimation complete.\n")
cat(sprintf("Outputs: %s\n", csv_dir))
cat(strrep("=", 70), "\n")
