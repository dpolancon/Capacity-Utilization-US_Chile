# 21_ardl_4channel_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# Stage C: ARDL 4-Channel Investment Function — US NF Corporate Sector
# Fordist era, 1947-1973
#
# Specification: g_K ~ mu + B_real + PyPK + pi
# Method: Pesaran, Shin & Smith (2001)
# All 5 cases tested for bounds F and bounds t
# Wald test: H0: beta_mu = beta_PyPK + beta_Br
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

# 1946 for lag construction; estimation 1947-1973
df <- ds %>% filter(year >= 1946, year <= 1973) %>% arrange(year)
df_est <- df %>% filter(year >= 1947)
N <- nrow(df_est)

df_ts <- ts(df %>% select(year, g_K, mu, B_real, PyPK, pi),
            start = 1946, frequency = 1)

cat(sprintf("Estimation sample: %d-%d (N=%d)\n", min(df_est$year), max(df_est$year), N))


# ═══════════════════════════════════════════════════════════════════════════════
# 1. MODEL SELECTION — TOP 20, REPORT TOP 5
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("1. ARDL MODEL SELECTION: g_K ~ mu + B_real + PyPK + pi\n")
cat(strrep("=", 70), "\n")

auto_4ch <- auto_ardl(g_K ~ mu + B_real + PyPK + pi,
                      data = df_ts, max_order = 2, selection = "AIC")

top_orders <- auto_4ch$top_orders
best_order <- as.numeric(top_orders[1, 1:5])

cat(sprintf("\nSelected by AIC: ARDL(%s)\n", paste(best_order, collapse = ",")))

cat("\n=== TOP 5 MODELS ===\n")
cat(sprintf("%-5s %-20s %10s %10s %5s %6s\n", "Rank", "Order", "AIC", "BIC", "df", "k"))
cat(strrep("-", 60), "\n")

top5 <- tibble()
for (i in 1:min(5, nrow(top_orders))) {
  ord <- as.numeric(top_orders[i, 1:5])
  m <- ardl(g_K ~ mu + B_real + PyPK + pi, data = df_ts, order = ord)
  n_params <- length(coef(m))
  # Effective sample may shrink with higher lags
  n_eff <- nobs(m)
  df_res <- n_eff - n_params

  top5 <- bind_rows(top5, tibble(
    rank = i, order = paste(ord, collapse = ","),
    AIC = AIC(m), BIC = BIC(m), n_params = n_params,
    n_eff = n_eff, df_resid = df_res
  ))

  cat(sprintf("%-5d ARDL(%-14s) %10.2f %10.2f %5d %6d\n",
      i, paste(ord, collapse = ","), AIC(m), BIC(m), df_res, n_params))
}

# BIC-optimal check
bic_best <- top5 %>% slice_min(BIC, n = 1)
cat(sprintf("\nAIC-optimal: ARDL(%s)  AIC=%.2f\n", top5$order[1], top5$AIC[1]))
cat(sprintf("BIC-optimal: ARDL(%s)  BIC=%.2f\n", bic_best$order, bic_best$BIC))

write_csv(top5, file.path(csv_dir, "stageC_US_4ch_top5_models.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# 2. ESTIMATE SELECTED MODEL
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("2. ARDL ESTIMATION\n")
cat(strrep("=", 70), "\n")

best <- auto_4ch$best_model
cat(sprintf("\nModel: ARDL(%s)\n", paste(best_order, collapse = ",")))
cat(sprintf("Effective sample: %d obs\n", nobs(best)))
cat(sprintf("Parameters: %d | Residual df: %d\n",
    length(coef(best)), nobs(best) - length(coef(best))))

cat("\n--- Unrestricted ARDL coefficients ---\n")
print(summary(best))

# Save coefficients
best_cf <- summary(best)$coefficients
best_df <- tibble(
  term = rownames(best_cf),
  estimate = best_cf[, "Estimate"],
  se = best_cf[, "Std. Error"],
  t_stat = best_cf[, "t value"],
  p_value = best_cf[, "Pr(>|t|)"]
)
write_csv(best_df, file.path(csv_dir, "stageC_US_4ch_ardl_coefficients.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# 3. PESARAN CASES 1-5: BOUNDS F AND T TESTS
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("3. BOUNDS TESTS — ALL 5 PESARAN CASES\n")
cat(strrep("=", 70), "\n")

k <- 4  # number of regressors (mu, B_real, PyPK, pi)
cat(sprintf("\nk = %d | N = %d (effective sample of selected model)\n", k, nobs(best)))

cat("\nCase taxonomy (PSS 2001):\n")
cat("  Case 1: No intercept, no trend\n")
cat("  Case 2: Restricted intercept, no trend\n")
cat("  Case 3: Unrestricted intercept, no trend\n")
cat("  Case 4: Unrestricted intercept, restricted trend\n")
cat("  Case 5: Unrestricted intercept, unrestricted trend\n")

# Need models with and without trend for Cases 4 and 5
# Refit with trend for Case 5
auto_4ch_trend <- tryCatch(
  auto_ardl(g_K ~ mu + B_real + PyPK + pi + trend(df_ts),
            data = df_ts, max_order = 2, selection = "AIC"),
  error = function(e) NULL
)

bounds_results <- tibble()

for (case_num in 1:5) {
  cat(sprintf("\n--- Case %d ---\n", case_num))

  # Select appropriate model
  if (case_num %in% c(4, 5) && !is.null(auto_4ch_trend)) {
    m_test <- auto_4ch_trend$best_model
    cat(sprintf("  Using trend-augmented model: ARDL(%s)\n",
        paste(auto_4ch_trend$best_order, collapse = ",")))
  } else {
    m_test <- best
  }

  # F-test
  bf <- tryCatch(
    bounds_f_test(m_test, case = case_num),
    error = function(e) {
      cat(sprintf("  F-test: incompatible with Case %d (%s)\n", case_num, e$message))
      NULL
    }
  )

  # t-test
  bt <- tryCatch(
    bounds_t_test(m_test, case = case_num),
    error = function(e) {
      cat(sprintf("  t-test: incompatible with Case %d (%s)\n", case_num, e$message))
      NULL
    }
  )

  f_stat <- ifelse(!is.null(bf), bf$statistic, NA)
  f_p    <- ifelse(!is.null(bf), bf$p.value, NA)
  t_stat <- ifelse(!is.null(bt), bt$statistic, NA)
  t_p    <- ifelse(!is.null(bt), bt$p.value, NA)

  if (!is.null(bf)) {
    cat(sprintf("  F-stat = %.4f  p = %.4f", f_stat, f_p))
    if (f_p < 0.01) cat("  => REJECT H0 at 1%%\n")
    else if (f_p < 0.05) cat("  => REJECT H0 at 5%%\n")
    else if (f_p < 0.10) cat("  => REJECT H0 at 10%%\n")
    else cat("  => FAIL TO REJECT\n")
  }

  if (!is.null(bt)) {
    cat(sprintf("  t-stat = %.4f  p = %.4f", t_stat, t_p))
    if (t_p < 0.01) cat("  => REJECT H0 at 1%%\n")
    else if (t_p < 0.05) cat("  => REJECT H0 at 5%%\n")
    else if (t_p < 0.10) cat("  => REJECT H0 at 10%%\n")
    else cat("  => FAIL TO REJECT\n")
  }

  bounds_results <- bind_rows(bounds_results, tibble(
    case = case_num, F_stat = f_stat, F_p = f_p, t_stat = t_stat, t_p = t_p
  ))
}

cat("\n=== BOUNDS TESTS SUMMARY ===\n")
print(bounds_results)
write_csv(bounds_results, file.path(csv_dir, "stageC_US_4ch_bounds_tests.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# 4. LONG-RUN MULTIPLIERS
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("4. LONG-RUN MULTIPLIERS\n")
cat(strrep("=", 70), "\n")

lr <- multipliers(best)
cat("\n")
print(lr)

write_csv(as.data.frame(lr), file.path(csv_dir, "stageC_US_4ch_longrun_multipliers.csv"))

# Extract long-run coefficients for Wald test
lr_mu   <- lr$Estimate[lr$Term == "mu"]
lr_Br   <- lr$Estimate[lr$Term == "B_real"]
lr_PyPK <- lr$Estimate[lr$Term == "PyPK"]
lr_pi   <- lr$Estimate[lr$Term == "pi"]

cat(sprintf("\nLong-run multipliers:\n"))
cat(sprintf("  beta_mu   = %.6f\n", lr_mu))
cat(sprintf("  beta_Br   = %.6f\n", lr_Br))
cat(sprintf("  beta_PyPK = %.6f\n", lr_PyPK))
cat(sprintf("  beta_pi   = %.6f\n", lr_pi))
cat(sprintf("  beta_PyPK + beta_Br = %.6f\n", lr_PyPK + lr_Br))
cat(sprintf("  beta_mu - (beta_PyPK + beta_Br) = %.6f\n", lr_mu - lr_PyPK - lr_Br))


# ═══════════════════════════════════════════════════════════════════════════════
# 5. ECM FORM AND BOUNDS t-TEST INFERENCE
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("5. ERROR CORRECTION MODEL (Case 3)\n")
cat(strrep("=", 70), "\n")

ecm <- recm(best, case = 3)
cat("\n")
print(summary(ecm))

ecm_cf <- summary(ecm)$coefficients

# Save ECM
ecm_df <- tibble(
  term = rownames(ecm_cf),
  estimate = ecm_cf[, "Estimate"],
  se = ecm_cf[, "Std. Error"],
  t_stat = ecm_cf[, "t value"],
  p_value = ecm_cf[, "Pr(>|t|)"]
)
write_csv(ecm_df, file.path(csv_dir, "stageC_US_4ch_ecm_coefficients.csv"))

# ECT inference — bounds t-test is the ONLY valid inference
ect_row <- which(ecm_df$term == "ect")
ect_coef <- ecm_df$estimate[ect_row]
ect_t    <- ecm_df$t_stat[ect_row]
ect_p    <- ecm_df$p_value[ect_row]

cat(sprintf("\n=== ECT INFERENCE (bounds t-test is authoritative) ===\n"))
cat(sprintf("ECT coefficient:  %.6f\n", ect_coef))
cat(sprintf("ECT t-statistic:  %.4f\n", ect_t))
cat(sprintf("ECT p (OLS):      %.6f\n", ect_p))

# The OLS p-value on ECT is NOT valid for inference on the existence
# of a levels relationship. Only the bounds t-test is valid.
bt_case3 <- bounds_results %>% filter(case == 3)
cat(sprintf("\nBounds t-stat (Case 3): %.4f\n", bt_case3$t_stat))
cat(sprintf("Bounds t p-value:       %.4f\n", bt_case3$t_p))

if (!is.na(bt_case3$t_p)) {
  if (bt_case3$t_p < 0.05) {
    cat("DECISION: Bounds t-test REJECTS H0 at 5%% — long-run relationship confirmed.\n")
  } else if (bt_case3$t_p < 0.10) {
    cat("DECISION: Bounds t-test REJECTS H0 at 10%% — marginal evidence.\n")
  } else {
    cat("DECISION: Bounds t-test FAILS TO REJECT — inconclusive.\n")
    cat("NOTE: With N=26 and k=4, finite-sample power is limited.\n")
  }
}

# Half-life
if (ect_coef < 0) {
  hl <- log(0.5) / log(1 + ect_coef)
  cat(sprintf("\nHalf-life of adjustment: %.2f years\n", hl))
  cat(sprintf("Full adjustment (~95%%): %.1f years\n", log(0.05) / log(1 + ect_coef)))
}


# ═══════════════════════════════════════════════════════════════════════════════
# 6. WALD TEST: H0: beta_mu = beta_PyPK + beta_Br
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("6. WALD TEST — H0: beta_mu = beta_PyPK + beta_Br\n")
cat(strrep("=", 70), "\n")

# The long-run multipliers are nonlinear functions of the ARDL coefficients.
# The Wald test must be conducted on the underlying ARDL parameters.
#
# From ARDL(1,2,1,1,1) for g_K ~ mu + B_real + PyPK + pi:
# Long-run: beta_j = (sum of contemporaneous + lagged coefficients on j) / (1 - sum of lagged g_K coefficients)
#
# We test the restriction on the long-run form via the delta method.
# The multipliers() function provides SEs via delta method already.
# We construct the Wald statistic manually.

cat("\nH0: beta_mu = beta_PyPK + beta_Br\n")
cat("H1: beta_mu != beta_PyPK + beta_Br\n\n")

# Use linearHypothesis on the ECM (which contains the long-run coefficients directly)
# In the ECM form: L(mu,1), L(B_real,1), L(PyPK,1) are the lagged levels
# whose coefficients / (-ECT) give the long-run multipliers.
# But linearHypothesis works on the raw ECM coefficients.

# The ECM coefficients on lagged levels are: coef / ect_coef = -LR multiplier
# So testing equality of LR multipliers = testing equality of level coefficients

# Identify the level terms in the ECM
ecm_terms <- ecm_df$term
cat("ECM terms:\n")
print(ecm_terms)

# The level terms are those containing "L(" (lagged levels from the ARDL)
# In recm output: L(mu, 1), L(B_real, 1), L(PyPK, 1), L(pi, 1)
# But the naming may differ. Let's check.

# Alternative approach: test directly on the long-run multipliers
# via the ARDL unrestricted coefficients
cat("\nLong-run values:\n")
cat(sprintf("  beta_mu               = %.6f (SE=%.6f)\n",
    lr$Estimate[lr$Term == "mu"], lr$`Std. Error`[lr$Term == "mu"]))
cat(sprintf("  beta_B_real           = %.6f (SE=%.6f)\n",
    lr$Estimate[lr$Term == "B_real"], lr$`Std. Error`[lr$Term == "B_real"]))
cat(sprintf("  beta_PyPK             = %.6f (SE=%.6f)\n",
    lr$Estimate[lr$Term == "PyPK"], lr$`Std. Error`[lr$Term == "PyPK"]))
cat(sprintf("  beta_PyPK + beta_Br   = %.6f\n", lr_PyPK + lr_Br))
cat(sprintf("  Difference (mu - sum) = %.6f\n", lr_mu - lr_PyPK - lr_Br))

# Wald test via linearHypothesis on the underlying ARDL model
# We need to express H0 in terms of the ARDL coefficients
# LR multiplier for mu = (coef_mu + coef_L(mu,1) + coef_L(mu,2)) / (1 - coef_L(g_K,1))
# This is nonlinear in the parameters. Use the delta method via car::deltaMethod

# Extract ARDL coefficient names
ardl_coefs <- coef(best)
ardl_names <- names(ardl_coefs)
cat("\nARDL coefficient names:\n")
print(ardl_names)

# Construct the long-run expressions
# phi = 1 - sum of lagged g_K coefficients
# For ARDL(1,...): phi = 1 - coef("L(g_K, 1)")
gk_lag_names <- grep("^L\\(g_K", ardl_names, value = TRUE)
phi_expr <- paste0("1 - ", paste(sprintf("`%s`", gk_lag_names), collapse = " - "))

# LR multiplier for each variable
mu_lag_names <- c(grep("^mu$", ardl_names, value = TRUE),
                  grep("^L\\(mu", ardl_names, value = TRUE))
br_lag_names <- c(grep("^B_real$", ardl_names, value = TRUE),
                  grep("^L\\(B_real", ardl_names, value = TRUE))
pypk_lag_names <- c(grep("^PyPK$", ardl_names, value = TRUE),
                    grep("^L\\(PyPK", ardl_names, value = TRUE))

mu_num   <- paste(sprintf("`%s`", mu_lag_names), collapse = " + ")
br_num   <- paste(sprintf("`%s`", br_lag_names), collapse = " + ")
pypk_num <- paste(sprintf("`%s`", pypk_lag_names), collapse = " + ")

# H0: mu_num/phi = (br_num + pypk_num)/phi
# Equivalent to: mu_num = br_num + pypk_num (phi cancels)
# This is LINEAR in the ARDL coefficients!

h0_expr <- sprintf("(%s) - (%s) - (%s) = 0", mu_num, br_num, pypk_num)
cat(sprintf("\nWald test expression: %s\n", h0_expr))

wald <- tryCatch(
  linearHypothesis(best, h0_expr),
  error = function(e) {
    cat(sprintf("linearHypothesis failed: %s\n", e$message))
    cat("Attempting manual construction...\n")
    NULL
  }
)

if (!is.null(wald)) {
  cat("\n--- Wald Test Result ---\n")
  print(wald)
  wald_F <- wald$F[2]
  wald_p <- wald$`Pr(>F)`[2]
  cat(sprintf("\nWald F-statistic: %.4f\n", wald_F))
  cat(sprintf("p-value:          %.4f\n", wald_p))
  if (wald_p > 0.05) {
    cat("DECISION: FAIL TO REJECT H0 — beta_mu = beta_PyPK + beta_Br\n")
    cat("The demand channel (mu) has the same long-run effect as the\n")
    cat("combined technology + relative price channels.\n")
  } else {
    cat("DECISION: REJECT H0 — beta_mu != beta_PyPK + beta_Br\n")
    cat("The demand channel has a distinct long-run effect from the\n")
    cat("combined supply-side channels.\n")
  }
} else {
  # Manual Wald: numerator sum and variance
  R <- rep(0, length(ardl_coefs))
  names(R) <- ardl_names
  for (nm in mu_lag_names)   R[nm] <- R[nm] + 1
  for (nm in br_lag_names)   R[nm] <- R[nm] - 1
  for (nm in pypk_lag_names) R[nm] <- R[nm] - 1

  diff_val <- sum(R * ardl_coefs)
  V <- vcov(best)
  se_diff <- sqrt(t(R) %*% V %*% R)
  wald_t <- diff_val / se_diff
  wald_p <- 2 * pt(-abs(wald_t), df = nobs(best) - length(ardl_coefs))

  cat(sprintf("\nManual Wald test:\n"))
  cat(sprintf("  Difference: %.6f\n", diff_val))
  cat(sprintf("  SE:         %.6f\n", se_diff))
  cat(sprintf("  t-stat:     %.4f\n", wald_t))
  cat(sprintf("  p-value:    %.4f\n", wald_p))
  if (wald_p > 0.05) {
    cat("DECISION: FAIL TO REJECT H0\n")
  } else {
    cat("DECISION: REJECT H0\n")
  }
}


# ═══════════════════════════════════════════════════════════════════════════════
# 7. DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 70), "\n")
cat("7. DIAGNOSTICS\n")
cat(strrep("=", 70), "\n")

bg1 <- bgtest(best, order = 1)
bg2 <- bgtest(best, order = 2)
bp  <- bptest(best)
jb  <- jarque.bera.test(residuals(best))
rst <- resettest(best, power = 2, type = "fitted")

cat(sprintf("Breusch-Godfrey (lag=1): chi2=%.3f  p=%.4f  %s\n",
    bg1$statistic, bg1$p.value, ifelse(bg1$p.value > 0.05, "PASS", "WARNING")))
cat(sprintf("Breusch-Godfrey (lag=2): chi2=%.3f  p=%.4f  %s\n",
    bg2$statistic, bg2$p.value, ifelse(bg2$p.value > 0.05, "PASS", "WARNING")))
cat(sprintf("Breusch-Pagan:          chi2=%.3f  p=%.4f  %s\n",
    bp$statistic, bp$p.value, ifelse(bp$p.value > 0.05, "PASS", "WARNING")))
cat(sprintf("Jarque-Bera:            chi2=%.3f  p=%.4f  %s\n",
    jb$statistic, jb$p.value, ifelse(jb$p.value > 0.05, "PASS", "WARNING")))
cat(sprintf("RESET (power=2):        F=%.3f    p=%.4f  %s\n",
    rst$statistic, rst$p.value, ifelse(rst$p.value > 0.05, "PASS", "WARNING")))

s <- summary(best)
cat(sprintf("\nR-squared: %.4f  Adj R-squared: %.4f\n", s$r.squared, s$adj.r.squared))
cat(sprintf("Residual SE: %.6f  df: %d\n", s$sigma, s$df[2]))

diag_df <- tibble(
  test = c("BG(1)", "BG(2)", "Breusch-Pagan", "Jarque-Bera", "RESET"),
  statistic = c(bg1$statistic, bg2$statistic, bp$statistic, jb$statistic, rst$statistic),
  p_value = c(bg1$p.value, bg2$p.value, bp$p.value, jb$p.value, rst$p.value)
)
write_csv(diag_df, file.path(csv_dir, "stageC_US_4ch_diagnostics.csv"))


cat("\n", strrep("=", 70), "\n")
cat("Stage C — 4-channel estimation complete.\n")
cat(strrep("=", 70), "\n")
