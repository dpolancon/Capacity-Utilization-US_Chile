

# 1) Long-run relation (ARDL package object)
lr_hat <- as.numeric(ARDL::coint_eq(fit_ardl, case = CASE))  # "cointegrating equation" (long-run level)

# 2) Correct ECT per ARDL definition: ECT = lnY - long-run relation
lnY_vec <- as.numeric(df_ts[, "lnY"])
lnK_vec <- as.numeric(df_ts[, "lnK"])

ect_hat <- lnY_vec - lr_hat

# 3) Capacity utilization candidate (log form = ECT; level = exp(ECT))
u_hat <- exp(ect_hat)

# 4) Compute long-run elasticity of lnY w.r.t lnK from estimated ARDL coefficients
#    LR = (sum of lnK level coefficients) / (1 - sum of lnY lag coefficients)
coefs <- stats::coef(fit_ardl)

# Helper: safe sum over matching names
sum_match <- function(pattern) {
  idx <- grep(pattern, names(coefs), fixed = FALSE)
  if (length(idx) == 0) return(0)
  sum(coefs[idx], na.rm = TRUE)
}

# y-lag coefficients: L(lnY, 1), L(lnY, 2), ...
sum_phi <- sum_match("^L\\(lnY,")   # sums all lnY lags included

# k level coefficients: lnK, L(lnK, 1), L(lnK, 2), ...
sum_psi <- 0
if ("lnK" %in% names(coefs)) sum_psi <- sum_psi + coefs[["lnK"]]
sum_psi <- sum_psi + sum_match("^L\\(lnK,")

lr_elasticity_K <- as.numeric(sum_psi / (1 - sum_phi))

# 5) Output tidy series (aligned with df$year)
out_df <- tibble::tibble(
  year        = df$year,
  lnY         = lnY_vec,
  lnK         = lnK_vec,
  lr_hat      = lr_hat,
  ect_hat     = ect_hat,
  u_hat       = u_hat
)



readr::write_csv(out_df, series_path)

cat("\n=== Long-run multiplier (elasticity) ===\n")
cat("LR elasticity of lnY wrt lnK:", round(lr_elasticity_K, 6), "\n")
cat("ECT summary (should be ~stationary if cointegration holds):\n")
print(summary(ect_hat))
cat("u_hat summary (should hover around 1):\n")
print(summary(u_hat))


plot(ect_hat, type = "l")

# -----------------------------
# 6) Log
# -----------------------------
sink(log_path)
cat("=== Shaikh ARDL replication (ARDL package only) ===\n\n")
cat("Formula:\n  ", deparse(fml), "\n\n", sep = "")
cat("Order (p,q):\n  ", paste(ORDER, collapse = ","), "\n\n", sep = "")
cat("Case:\n  ", CASE, "\n\n", sep = "")
cat("Fixed dummies (unlagged via |):\n  ", if (length(DUMMY_VARS)==0) "(none)" else paste(DUMMY_VARS, collapse=", "), "\n\n", sep = "")

cat("--- bounds_f_test ---\n")
print(bt_f)

cat("\n--- ardl summary ---\n")
print(summary(fit_ardl))

cat("\n--- coint_eq info ---\n")
cat("class(coint_eq): ", paste(class(ect), collapse=", "), "\n", sep = "")
cat("ECT head:\n")
print(head(ect, 10))

cat("\n--- Outputs ---\n")
cat("Series:\n  ", series_path, "\n", sep = "")
cat("Log:\n  ", log_path, "\n", sep = "")
sink()

cat("Wrote series CSV:\n  ", series_path, "\n", sep = "")
cat("Wrote log:\n  ", log_path, "\n", sep = "")