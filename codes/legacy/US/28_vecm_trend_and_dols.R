# 28_vecm_trend_and_dols.R
# (A) VECM with restricted trend in beta (ecdet="trend", Case 4)
# (B) DOLS for long-run coefficients — split samples
# State vector: (y, k, wk) endogenous, w exogenous
# Dual deflators: Py for Y, pK for K. Log real levels.

library(urca)
library(vars)
if (!requireNamespace("numDeriv", quietly = TRUE)) install.packages("numDeriv")

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

d <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
nf_inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
d <- merge(d, nf_inc[, c("year", "Py_fred")], by = "year")
d <- d[order(d$year), ]

Py_2024 <- d$Py_fred[d$year == 2024]
d$Y_real <- d$GVA_NF / (d$Py_fred / Py_2024)
d$y_t    <- log(d$Y_real)
d$k_t    <- log(d$KGR_NF)
d$w_t    <- d$Wsh_NF
d$w_k_t  <- d$w_t * d$k_t

d_pre  <- d[d$year <= 1973, ]
d_post <- d[d$year >= 1974, ]

cat(sprintf("Full: %d-%d (%d) | Pre: %d-%d (%d) | Post: %d-%d (%d)\n",
    min(d$year), max(d$year), nrow(d),
    min(d_pre$year), max(d_pre$year), nrow(d_pre),
    min(d_post$year), max(d_post$year), nrow(d_post)))
cat("y=log(GVA/Py), k=log(KGR_NF). Dual deflators. w exogenous.\n\n")

# ══════════════════════════════════════════════════════════════════════════════
# HELPER: run VECM on sub-sample
# ══════════════════════════════════════════════════════════════════════════════
run_vecm <- function(df, label, ecdet_spec, K = 2) {
  X <- as.matrix(df[, c("y_t", "k_t", "w_k_t")])
  W <- as.matrix(df[, "w_t", drop = FALSE])
  n <- nrow(X)

  jo <- ca.jo(X, type = "trace", ecdet = ecdet_spec, K = K,
              spec = "longrun", dumvar = W)

  p <- ncol(X)
  cat(sprintf("\n--- %s (ecdet='%s', n=%d) ---\n", label, ecdet_spec, n))

  # Rank
  for (r0 in 0:(p - 1)) {
    idx <- p - r0
    cat(sprintf("  r<=%d: trace=%.2f  5%%cv=%.2f  %s\n",
        r0, jo@teststat[idx], jo@cval[idx, 2],
        ifelse(jo@teststat[idx] > jo@cval[idx, 2], "REJECT", "fail")))
  }

  # First eigenvector
  b1 <- jo@V[, 1] / jo@V[1, 1]
  n_slots <- length(b1)

  if (ecdet_spec == "const") {
    # slots: y, k, wk, const
    th1 <- -b1[2]; th2 <- -b1[3]; c1 <- -b1[4]; trend <- NA
    cat(sprintf("  CV1: theta1=%.4f, theta2=%.4f, c1=%.4f\n", th1, th2, c1))
  } else {
    # ecdet="trend": slots: y, k, wk, trend, (no separate const in beta)
    # Actually urca with ecdet="trend" adds trend to beta: slots = p+1
    th1 <- -b1[2]; th2 <- -b1[3]; trend <- -b1[4]
    c1 <- NA
    cat(sprintf("  CV1: theta1=%.4f, theta2=%.4f, trend=%.6f\n", th1, th2, trend))
  }

  w_bar <- mean(df$w_t)
  th_bar <- th1 + th2 * w_bar

  # Knife edge
  w_H <- NA
  if (th2 < 0 & th1 > 1) w_H <- (th1 - 1) / abs(th2)

  cat(sprintf("  theta_bar(w=%.4f) = %.4f\n", w_bar, th_bar))
  if (!is.na(w_H)) {
    cat(sprintf("  w_H = %.4f %s [%.4f, %.4f]\n", w_H,
        ifelse(w_H >= min(df$w_t) & w_H <= max(df$w_t), "IN RANGE", "outside"),
        min(df$w_t), max(df$w_t)))
  }

  # ECT
  if (ecdet_spec == "const") {
    mu <- df$y_t - th1 * df$k_t - th2 * df$w_k_t - c1
  } else {
    mu <- df$y_t - th1 * df$k_t - th2 * df$w_k_t - trend * seq_len(n)
  }
  adf <- ur.df(mu, type = "drift", lags = 2)
  cat(sprintf("  ECT ADF=%.3f (5%%cv=%.2f) — %s\n",
      adf@teststat[1], adf@cval[1, 2],
      ifelse(adf@teststat[1] < adf@cval[1, 2], "I(0)", "WARNING")))

  list(theta1 = th1, theta2 = th2, c1 = c1, trend = trend,
       th_bar = th_bar, w_H = w_H, w_bar = w_bar, n = n,
       adf = adf@teststat[1], ecdet = ecdet_spec)
}

# ══════════════════════════════════════════════════════════════════════════════
# PART A: VECM — const vs trend
# ══════════════════════════════════════════════════════════════════════════════
cat("=" , rep("=", 64), "\n")
cat("PART A: JOHANSEN VECM — ecdet='const' vs ecdet='trend'\n")
cat(rep("=", 65), "\n")

cat("\n=== ecdet='const' (Case 3) ===")
r_pre_c  <- run_vecm(d_pre,  "Pre-1973", "const")
r_post_c <- run_vecm(d_post, "Post-1974", "const")

cat("\n\n=== ecdet='trend' (Case 4) ===")
r_pre_t  <- run_vecm(d_pre,  "Pre-1973", "trend")
r_post_t <- run_vecm(d_post, "Post-1974", "trend")

# ══════════════════════════════════════════════════════════════════════════════
# PART B: DOLS — long-run coefficients directly
# ══════════════════════════════════════════════════════════════════════════════
cat("\n\n", rep("=", 65), "\n")
cat("PART B: DOLS — LONG-RUN COEFFICIENTS\n")
cat(rep("=", 65), "\n")
cat("\ny_t = theta1*k_t + theta2*w_k_t + c0 + c1*t + leads/lags of dk, dwk\n\n")

run_dols <- function(df, label, p_leads = 1, p_lags = 1, include_trend = TRUE) {
  n <- nrow(df)
  cat(sprintf("\n--- %s DOLS (leads=%d, lags=%d, trend=%s, n=%d) ---\n",
      label, p_leads, p_lags, include_trend, n))

  # Construct leads and lags of first differences
  dk   <- c(NA, diff(df$k_t))
  dwk  <- c(NA, diff(df$w_k_t))

  # Build regressor matrix
  regs <- data.frame(y = df$y_t, k = df$k_t, wk = df$w_k_t, t = 1:n)

  for (l in (-p_lags):p_leads) {
    suffix <- if (l < 0) paste0("m", abs(l)) else if (l > 0) paste0("p", l) else "0"
    if (l <= 0) {
      regs[[paste0("dk_", suffix)]]  <- c(rep(NA, abs(l)), dk[1:(n - abs(l))])
      regs[[paste0("dwk_", suffix)]] <- c(rep(NA, abs(l)), dwk[1:(n - abs(l))])
    } else {
      regs[[paste0("dk_", suffix)]]  <- c(dk[(l + 1):n], rep(NA, l))
      regs[[paste0("dwk_", suffix)]] <- c(dwk[(l + 1):n], rep(NA, l))
    }
  }

  regs <- regs[complete.cases(regs), ]
  n_eff <- nrow(regs)

  # Formula
  dyn_vars <- grep("^dk_|^dwk_", names(regs), value = TRUE)
  if (include_trend) {
    fml <- as.formula(paste("y ~ k + wk + t +", paste(dyn_vars, collapse = " + ")))
  } else {
    fml <- as.formula(paste("y ~ k + wk +", paste(dyn_vars, collapse = " + ")))
  }

  fit <- lm(fml, data = regs)
  cf  <- coef(fit)
  se  <- sqrt(diag(vcov(fit)))

  th1 <- cf["k"]
  th2 <- cf["wk"]
  se_th1 <- se["k"]
  se_th2 <- se["wk"]

  trend_coef <- if (include_trend) cf["t"] else NA
  trend_se   <- if (include_trend) se["t"] else NA

  w_bar <- mean(df$w_t)
  th_bar <- th1 + th2 * w_bar
  # Delta method SE for theta_bar
  vc_12 <- vcov(fit)[c("k", "wk"), c("k", "wk")]
  se_bar <- sqrt(vc_12[1,1] + w_bar^2 * vc_12[2,2] + 2 * w_bar * vc_12[1,2])

  w_H <- NA
  if (th2 < 0 & th1 > 1) w_H <- (th1 - 1) / abs(th2)

  cat(sprintf("  n_eff=%d  R2=%.4f  R2adj=%.4f\n", n_eff,
      summary(fit)$r.squared, summary(fit)$adj.r.squared))
  cat(sprintf("  theta1 = %.4f (SE=%.4f, t=%.3f)\n", th1, se_th1, th1/se_th1))
  cat(sprintf("  theta2 = %.4f (SE=%.4f, t=%.3f)\n", th2, se_th2, th2/se_th2))
  if (include_trend)
    cat(sprintf("  trend  = %.6f (SE=%.6f, t=%.3f)\n", trend_coef, trend_se, trend_coef/trend_se))
  cat(sprintf("  theta_bar(w=%.4f) = %.4f (SE=%.4f, t=%.3f)\n",
      w_bar, th_bar, se_bar, th_bar/se_bar))
  if (!is.na(w_H))
    cat(sprintf("  w_H = %.4f %s [%.4f, %.4f]\n", w_H,
        ifelse(w_H >= min(df$w_t) & w_H <= max(df$w_t), "IN RANGE", "outside"),
        min(df$w_t), max(df$w_t)))

  # Residual stationarity
  resid <- residuals(fit)
  adf <- ur.df(resid, type = "none", lags = 2)
  cat(sprintf("  Residual ADF=%.3f (5%%cv=%.2f) — %s\n",
      adf@teststat[1], -1.95,
      ifelse(adf@teststat[1] < -1.95, "cointegrated", "WARNING")))

  # Signs
  cat(sprintf("  Signs: theta1 %s 0, theta2 %s 0 — %s\n",
      ifelse(th1>0,">","<"), ifelse(th2<0,"<",">"),
      ifelse(th1>0 & th2<0, "CORRECT", "PROBLEM")))

  list(theta1 = th1, theta2 = th2, se_th1 = se_th1, se_th2 = se_th2,
       trend = trend_coef, th_bar = th_bar, se_bar = se_bar,
       w_H = w_H, w_bar = w_bar, n = n_eff,
       adf = adf@teststat[1], r2 = summary(fit)$r.squared)
}

# DOLS without trend
cat("\n--- WITHOUT TREND ---")
dols_pre_nt  <- run_dols(d_pre,  "Pre-1973",  include_trend = FALSE)
dols_post_nt <- run_dols(d_post, "Post-1974", include_trend = FALSE)

# DOLS with trend
cat("\n\n--- WITH TREND ---")
dols_pre_t  <- run_dols(d_pre,  "Pre-1973",  include_trend = TRUE)
dols_post_t <- run_dols(d_post, "Post-1974", include_trend = TRUE)

# ══════════════════════════════════════════════════════════════════════════════
# COMPARISON TABLE
# ══════════════════════════════════════════════════════════════════════════════
cat("\n\n", rep("=", 75), "\n")
cat("MASTER COMPARISON\n")
cat(rep("=", 75), "\n\n")

cat(sprintf("%-25s %10s %10s %10s %10s %8s\n",
    "Specification", "theta1", "theta2", "th_bar", "w_H", "ECT/ADF"))
cat(strrep("-", 75), "\n")

print_row <- function(label, r) {
  cat(sprintf("%-25s %10.4f %10.4f %10.4f %10s %8.3f\n",
      label, r$theta1, r$theta2, r$th_bar,
      ifelse(is.na(r$w_H), "N/A", sprintf("%.4f", r$w_H)),
      r$adf))
}

print_row("PRE VECM const", r_pre_c)
print_row("PRE VECM trend", r_pre_t)
print_row("PRE DOLS no trend", dols_pre_nt)
print_row("PRE DOLS trend", dols_pre_t)
cat(strrep("-", 75), "\n")
print_row("POST VECM const", r_post_c)
print_row("POST VECM trend", r_post_t)
print_row("POST DOLS no trend", dols_post_nt)
print_row("POST DOLS trend", dols_post_t)

cat(sprintf("\n\nSign check summary:\n"))
all_specs <- list(
  "PRE VECM const"=r_pre_c, "PRE VECM trend"=r_pre_t,
  "PRE DOLS no trend"=dols_pre_nt, "PRE DOLS trend"=dols_pre_t,
  "POST VECM const"=r_post_c, "POST VECM trend"=r_post_t,
  "POST DOLS no trend"=dols_post_nt, "POST DOLS trend"=dols_post_t)
for (nm in names(all_specs)) {
  r <- all_specs[[nm]]
  cat(sprintf("  %-25s th1=%+8.2f th2=%+8.2f signs=%s\n",
      nm, r$theta1, r$theta2,
      ifelse(r$theta1 > 0 & r$theta2 < 0, "OK", "WRONG")))
}

# ══════════════════════════════════════════════════════════════════════════════
# SAVE
# ══════════════════════════════════════════════════════════════════════════════
outdir <- file.path(REPO, "output/stage_a/us/vecm_results")

results <- data.frame(
  spec = c("PRE_VECM_const", "PRE_VECM_trend", "PRE_DOLS_notrend", "PRE_DOLS_trend",
           "POST_VECM_const", "POST_VECM_trend", "POST_DOLS_notrend", "POST_DOLS_trend"),
  theta1 = c(r_pre_c$theta1, r_pre_t$theta1, dols_pre_nt$theta1, dols_pre_t$theta1,
             r_post_c$theta1, r_post_t$theta1, dols_post_nt$theta1, dols_post_t$theta1),
  theta2 = c(r_pre_c$theta2, r_pre_t$theta2, dols_pre_nt$theta2, dols_pre_t$theta2,
             r_post_c$theta2, r_post_t$theta2, dols_post_nt$theta2, dols_post_t$theta2),
  theta_bar = c(r_pre_c$th_bar, r_pre_t$th_bar, dols_pre_nt$th_bar, dols_pre_t$th_bar,
                r_post_c$th_bar, r_post_t$th_bar, dols_post_nt$th_bar, dols_post_t$th_bar),
  w_H = c(r_pre_c$w_H, r_pre_t$w_H, dols_pre_nt$w_H, dols_pre_t$w_H,
           r_post_c$w_H, r_post_t$w_H, dols_post_nt$w_H, dols_post_t$w_H),
  adf = c(r_pre_c$adf, r_pre_t$adf, dols_pre_nt$adf, dols_pre_t$adf,
          r_post_c$adf, r_post_t$adf, dols_post_nt$adf, dols_post_t$adf),
  signs_ok = c(r_pre_c$theta1>0 & r_pre_c$theta2<0,
               r_pre_t$theta1>0 & r_pre_t$theta2<0,
               dols_pre_nt$theta1>0 & dols_pre_nt$theta2<0,
               dols_pre_t$theta1>0 & dols_pre_t$theta2<0,
               r_post_c$theta1>0 & r_post_c$theta2<0,
               r_post_t$theta1>0 & r_post_t$theta2<0,
               dols_post_nt$theta1>0 & dols_post_nt$theta2<0,
               dols_post_t$theta1>0 & dols_post_t$theta2<0)
)
write.csv(results, file.path(outdir, "trend_dols_comparison.csv"), row.names = FALSE)
cat(sprintf("\nSaved: trend_dols_comparison.csv\n"))
cat("\n=== DONE ===\n")
