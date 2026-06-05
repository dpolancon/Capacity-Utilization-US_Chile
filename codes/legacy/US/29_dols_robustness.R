# 29_dols_robustness.R
# 1. DOLS lag/lead sensitivity for post-1974
# 2. Recursive/rolling DOLS windows to recover distributional channel

library(urca)

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

# ══════════════════════════════════════════════════════════════════════════════
# DOLS HELPER
# ══════════════════════════════════════════════════════════════════════════════
run_dols <- function(df, p_leads, p_lags, silent = FALSE) {
  n <- nrow(df)
  dk  <- c(NA, diff(df$k_t))
  dwk <- c(NA, diff(df$w_k_t))

  regs <- data.frame(y = df$y_t, k = df$k_t, wk = df$w_k_t)
  for (l in (-p_lags):p_leads) {
    sfx <- if (l < 0) paste0("m", abs(l)) else if (l > 0) paste0("p", l) else "0"
    if (l <= 0) {
      regs[[paste0("dk_", sfx)]]  <- c(rep(NA, abs(l)), dk[1:(n - abs(l))])
      regs[[paste0("dwk_", sfx)]] <- c(rep(NA, abs(l)), dwk[1:(n - abs(l))])
    } else {
      regs[[paste0("dk_", sfx)]]  <- c(dk[(l+1):n], rep(NA, l))
      regs[[paste0("dwk_", sfx)]] <- c(dwk[(l+1):n], rep(NA, l))
    }
  }
  regs <- regs[complete.cases(regs), ]
  n_eff <- nrow(regs)
  if (n_eff < 15) return(NULL)

  dyn <- grep("^dk_|^dwk_", names(regs), value = TRUE)
  fml <- as.formula(paste("y ~ k + wk +", paste(dyn, collapse = " + ")))
  fit <- lm(fml, data = regs)
  cf  <- coef(fit); se <- sqrt(diag(vcov(fit)))

  th1 <- cf["k"]; th2 <- cf["wk"]
  se1 <- se["k"]; se2 <- se["wk"]
  w_bar <- mean(df$w_t)
  vc12 <- vcov(fit)[c("k","wk"), c("k","wk")]
  th_bar <- th1 + th2 * w_bar
  se_bar <- sqrt(vc12[1,1] + w_bar^2*vc12[2,2] + 2*w_bar*vc12[1,2])

  adf_r <- ur.df(residuals(fit), type = "none", lags = min(2, n_eff - 5))

  if (!silent) {
    cat(sprintf("  p=%d/%d n=%d | th1=%+7.3f(%5.3f) th2=%+7.4f(%5.4f) t2=%.2f | th_bar=%.3f | ADF=%.2f\n",
        p_lags, p_leads, n_eff, th1, se1, th2, se2, th2/se2, th_bar, adf_r@teststat[1]))
  }

  list(theta1=th1, theta2=th2, se1=se1, se2=se2, t2=th2/se2,
       th_bar=th_bar, se_bar=se_bar, n=n_eff,
       adf=adf_r@teststat[1], r2=summary(fit)$r.squared,
       signs_ok = th1 > 0 & th2 < 0)
}

# ══════════════════════════════════════════════════════════════════════════════
# PART 1: LAG/LEAD SENSITIVITY — POST-1974
# ══════════════════════════════════════════════════════════════════════════════
cat("=" , rep("=", 69), "\n")
cat("PART 1: DOLS LAG/LEAD SENSITIVITY — POST-1974\n")
cat(rep("=", 70), "\n\n")

d_post <- d[d$year >= 1974, ]
cat(sprintf("Post-1974: %d-%d (%d obs)\n\n", min(d_post$year), max(d_post$year), nrow(d_post)))

cat(sprintf("%-8s %8s %8s %8s %8s %8s %8s %8s\n",
    "lags/ld", "n_eff", "theta1", "theta2", "t(th2)", "th_bar", "ADF", "signs"))
cat(strrep("-", 70), "\n")

for (pl in 0:4) {
  for (ll in 0:4) {
    r <- run_dols(d_post, p_leads = pl, p_lags = ll, silent = TRUE)
    if (!is.null(r)) {
      cat(sprintf("%-8s %8d %8.3f %8.4f %8.2f %8.3f %8.2f %8s\n",
          sprintf("%d/%d", ll, pl), r$n, r$theta1, r$theta2, r$t2,
          r$th_bar, r$adf, ifelse(r$signs_ok, "OK", "no")))
    }
  }
}

# Also pre-1973 for reference
cat(sprintf("\nPre-1973 reference:\n"))
cat(sprintf("%-8s %8s %8s %8s %8s %8s %8s %8s\n",
    "lags/ld", "n_eff", "theta1", "theta2", "t(th2)", "th_bar", "ADF", "signs"))
cat(strrep("-", 70), "\n")
d_pre <- d[d$year <= 1973, ]
for (pl in 0:3) {
  for (ll in 0:3) {
    r <- run_dols(d_pre, p_leads = pl, p_lags = ll, silent = TRUE)
    if (!is.null(r)) {
      cat(sprintf("%-8s %8d %8.3f %8.4f %8.2f %8.3f %8.2f %8s\n",
          sprintf("%d/%d", ll, pl), r$n, r$theta1, r$theta2, r$t2,
          r$th_bar, r$adf, ifelse(r$signs_ok, "OK", "no")))
    }
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# PART 2: RECURSIVE/ROLLING DOLS WINDOWS
# ══════════════════════════════════════════════════════════════════════════════
cat("\n\n", rep("=", 70), "\n")
cat("PART 2: ROLLING DOLS WINDOWS — RECOVERING THE DISTRIBUTIONAL CHANNEL\n")
cat(rep("=", 70), "\n\n")

# Historically informed sub-periods:
# 1929-1945: Depression + WWII
# 1945-1973: Golden Age / Fordist
# 1973-1982: Stagflation / Volcker
# 1982-2000: Neoliberal consolidation / Great Moderation
# 2000-2024: Financialization / post-GFC

# Minimum T for DOLS: ~25 obs (with 1 lead + 1 lag, need 23 effective)
# Use fixed lag/lead = 1/1

cat("A. Historically informed windows (DOLS 1/1):\n\n")

windows_hist <- list(
  c(1929, 1945, "Depression+WWII"),
  c(1929, 1955, "Prewar+early Fordist"),
  c(1929, 1973, "Full pre-crisis"),
  c(1945, 1973, "Golden Age"),
  c(1945, 1978, "Fordist broad"),
  c(1960, 1985, "Late Fordist+transition"),
  c(1973, 2000, "Neoliberal core"),
  c(1974, 2024, "Full post-crisis"),
  c(1982, 2008, "Great Moderation"),
  c(1982, 2024, "Neo+finance"),
  c(1990, 2024, "Post cold war"),
  c(2000, 2024, "Financialization")
)

cat(sprintf("%-25s %5s %8s %8s %8s %8s %8s %5s\n",
    "Window", "n", "theta1", "theta2", "t(th2)", "th_bar", "ADF", "sign"))
cat(strrep("-", 80), "\n")

hist_results <- list()
for (w in windows_hist) {
  y1 <- as.integer(w[1]); y2 <- as.integer(w[2]); lab <- w[3]
  df <- d[d$year >= y1 & d$year <= y2, ]
  if (nrow(df) < 20) next
  r <- run_dols(df, p_leads = 1, p_lags = 1, silent = TRUE)
  if (!is.null(r)) {
    cat(sprintf("%-25s %5d %8.3f %8.4f %8.2f %8.3f %8.2f %5s\n",
        sprintf("%d-%d %s", y1, y2, lab), r$n, r$theta1, r$theta2, r$t2,
        r$th_bar, r$adf, ifelse(r$signs_ok, "OK", "no")))
    hist_results[[length(hist_results) + 1]] <- c(y1, y2, r$theta1, r$theta2,
        r$t2, r$th_bar, r$adf, r$signs_ok)
  }
}

# B. Rolling window (30 years)
cat(sprintf("\n\nB. Rolling 30-year window (DOLS 1/1):\n\n"))

cat(sprintf("%-12s %5s %8s %8s %8s %8s %8s %5s\n",
    "Window", "n", "theta1", "theta2", "t(th2)", "th_bar", "ADF", "sign"))
cat(strrep("-", 65), "\n")

roll_results <- data.frame()
for (start in 1929:1994) {
  end <- start + 29
  if (end > 2024) break
  df <- d[d$year >= start & d$year <= end, ]
  r <- run_dols(df, p_leads = 1, p_lags = 1, silent = TRUE)
  if (!is.null(r)) {
    cat(sprintf("%-12s %5d %8.3f %8.4f %8.2f %8.3f %8.2f %5s\n",
        sprintf("%d-%d", start, end), r$n, r$theta1, r$theta2, r$t2,
        r$th_bar, r$adf, ifelse(r$signs_ok, "OK", "no")))
    roll_results <- rbind(roll_results, data.frame(
      start=start, end=end, theta1=r$theta1, theta2=r$theta2,
      t_theta2=r$t2, th_bar=r$th_bar, adf=r$adf, signs_ok=r$signs_ok))
  }
}

# C. Summary: when does theta2 < 0 and significant?
cat(sprintf("\n\nC. Windows where theta2 < 0 AND |t| > 2:\n\n"))
sig_neg <- roll_results[roll_results$theta2 < 0 & abs(roll_results$t_theta2) > 2, ]
if (nrow(sig_neg) > 0) {
  cat(sprintf("%-12s %8s %8s %8s %8s\n", "Window", "theta2", "t(th2)", "th_bar", "ADF"))
  cat(strrep("-", 50), "\n")
  for (i in 1:nrow(sig_neg)) {
    cat(sprintf("%-12s %8.4f %8.2f %8.3f %8.2f\n",
        sprintf("%d-%d", sig_neg$start[i], sig_neg$end[i]),
        sig_neg$theta2[i], sig_neg$t_theta2[i], sig_neg$th_bar[i], sig_neg$adf[i]))
  }
} else {
  cat("  NONE found in 30-year rolling windows.\n")
}

# D. Expanding windows from 1974
cat(sprintf("\n\nD. Expanding window from 1974 (DOLS 1/1):\n\n"))
cat(sprintf("%-12s %5s %8s %8s %8s %8s %5s\n",
    "Window", "n", "theta1", "theta2", "t(th2)", "th_bar", "sign"))
cat(strrep("-", 55), "\n")

for (end in seq(1998, 2024, by = 2)) {
  df <- d[d$year >= 1974 & d$year <= end, ]
  r <- run_dols(df, p_leads = 1, p_lags = 1, silent = TRUE)
  if (!is.null(r)) {
    cat(sprintf("%-12s %5d %8.3f %8.4f %8.2f %8.3f %5s\n",
        sprintf("1974-%d", end), r$n, r$theta1, r$theta2, r$t2,
        r$th_bar, ifelse(r$signs_ok, "OK", "no")))
  }
}

# Save rolling results
outdir <- file.path(REPO, "output/stage_a/us/vecm_results")
write.csv(roll_results, file.path(outdir, "dols_rolling_30yr.csv"), row.names = FALSE)

cat(sprintf("\n\nSaved: dols_rolling_30yr.csv\n"))
cat("\n=== DONE ===\n")
