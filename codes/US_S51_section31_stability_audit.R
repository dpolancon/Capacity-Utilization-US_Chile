#!/usr/bin/env Rscript

# US_S51_section31_stability_audit.R
# ---------------------------------------------------------------------------
# Section 3.1 Cointegration Failure Diagnostics: Parameter-Stability Audit
#
# The Section 3.1 IM-OLS matrix (US_S50) reports overwhelming evidence AGAINST
# cointegration: residual ADF fails to reject "no cointegration" in 16/18
# models, Shin LM rejects cointegration in 18/18, VW Type 2 rejects in 16/18.
# This script audits WHY.
#
# The leading rival explanation is already excluded: US_S33's integration-order
# battery tested the interaction terms directly (double and triple, both
# capital variants, all 8 omega variants) and every one returned I(1). The
# Integration Order Gate passes, so the regressors are admissible.
#
# That leaves PARAMETER INSTABILITY, which is already half-visible in the
# existing output. Shin's C statistic is Hansen's (1992) Lc restricted to
# intercept-only variation (verified exactly across all 18 models, see
# COMMON_cointegration_stability_tests.R). So the 18/18 Shin rejection is
# already an instability signal -- just an undecomposed one. US_S50 responds to
# the Bai-Perron breaks by inserting STEP DUMMIES, i.e. level shifts only. If
# the SLOPE (theta_0, theta_1) also shifts, a fixed-coefficient cointegration
# test must fail even when a regime-specific long-run relation exists.
#
# Battery:
#   (a) Hansen (1992) Lc / MeanF / SupF, per-parameter and joint, bootstrapped
#   (b) CUSUM family: OLS-CUSUM + supF/aveF/expF (strucchange)
#   (c) Recursive / rolling theta_0, theta_1 paths with fixed-b bands
#   (d) Gregory-Hansen (1996) regime-shift cointegration, bootstrapped
#   (e) Regime-split IM-OLS re-estimation at each model's endogenous break
#   (f) Integration-order gap closure (lagged interactions, ST_Tier2 standalone)
#   (g) Consolidated verdict ledger
#
# Governed by the umass-applied-econometrics skill: Rule B (visual-first),
# Rule D (specification-space mapping), Rule H (PE interpretation of failure),
# Rule I (small-sample bootstrap), and the Cointegration Specification Audit
# Protocol's verdict-ledger format.
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(cointReg)
  library(strucchange)
  library(urca)
  library(dplyr)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
source(file.path(repo_root, "codes", "COMMON_VW_fixedb_critical_values.R"))
source(file.path(repo_root, "codes", "COMMON_cointegration_stability_tests.R"))

s50_dir  <- file.path(repo_root, "output", "US", "S50_SECTION31_IMOLS")
out_dir  <- file.path(repo_root, "output", "US", "S51_SECTION31_STABILITY")
csv_dir  <- file.path(out_dir, "csv")
fig_dir  <- file.path(out_dir, "fig")
rep_dir  <- file.path(repo_root, "reports", "US_Section31_Stability_Audit")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rep_dir, recursive = TRUE, showWarnings = FALSE)

# Bootstrap replication counts. Rule I prefers 1,000; the Gregory-Hansen
# bootstrap is ~66x more expensive per replicate (it rescans every candidate
# break date), so it runs at a reduced but still adequate count.
# Overridable via environment variables for smoke-testing (S51_BOOT_HANSEN,
# S51_BOOT_GH). Production runs use the defaults below.
.envint <- function(nm, default) {
  v <- Sys.getenv(nm, "")
  if (nzchar(v) && !is.na(suppressWarnings(as.integer(v)))) as.integer(v) else default
}
N_BOOT_HANSEN <- .envint("S51_BOOT_HANSEN", 1000L)
N_BOOT_GH     <- .envint("S51_BOOT_GH", 499L)
SEED          <- 20260803L
cat(sprintf("Bootstrap reps: Hansen=%d, Gregory-Hansen=%d\n", N_BOOT_HANSEN, N_BOOT_GH))

cat("========================================================================\n")
cat("S51: Section 3.1 Cointegration Failure Diagnostics (Stability Audit)\n")
cat("========================================================================\n")

fs <- readRDS(file.path(s50_dir, "rds", "s50_fitted_models.rds"))
s50 <- read.csv(file.path(s50_dir, "csv", "s50_section31_results.csv"))
cat(sprintf("Loaded %d fitted models from S50.\n\n", length(fs)))

# ---------------------------------------------------------------------------
# BLOCKING VALIDATION -- must pass before any result is reported.
# Lc restricted to intercept-only variation must equal T * Shin_stat exactly.
# See COMMON_cointegration_stability_tests.R for why this pins the functional
# form of the Hansen implementation.
# ---------------------------------------------------------------------------
cat("--- Blocking validation: Lc(intercept-only) == T * Shin_stat ---\n")
val_rows <- lapply(names(fs), function(nm) {
  m <- fs[[nm]]
  S_t <- cumsum(m$u_plus)
  lc <- sum(S_t^2) / (m$T_obs * m$omega_u_v)
  tgt <- m$T_obs * m$Shin_stat
  data.frame(Model_ID = nm, Lc_intercept = lc, T_times_Shin = tgt,
             rel_err = abs(lc - tgt) / abs(tgt),
             pass = isTRUE(all.equal(lc, tgt, tolerance = 1e-8)))
})
val_df <- do.call(rbind, val_rows)
write.csv(val_df, file.path(csv_dir, "s51_validation_shin_lc_identity.csv"), row.names = FALSE)
if (!all(val_df$pass)) {
  stop("BLOCKING: Shin-Lc identity failed for: ",
       paste(val_df$Model_ID[!val_df$pass], collapse = ", "),
       ". Hansen implementation is wrong; refusing to report results.")
}
cat(sprintf("  PASS on all %d models (max rel. error %.2e)\n\n", nrow(val_df), max(val_df$rel_err)))

cat("--- Blocking validation: bootstrap nulls not transposed ---\n")
set.seed(SEED)
san <- bootstrap_sanity_check(n_boot = 199, seed = SEED, verbose = FALSE)
write.csv(san, file.path(csv_dir, "s51_validation_bootstrap_sanity.csv"), row.names = FALSE)
print(san[, c("case", "hansen_p", "gh_p", "hansen_ok", "gh_ok")])
if (!(all(san$hansen_ok) && all(san$gh_ok))) {
  stop("BLOCKING: bootstrap sanity check failed -- the two null DGPs appear transposed.")
}
cat("  PASS\n\n")

# ---------------------------------------------------------------------------
# Helper: refit IM-OLS and return residuals for a given y (design fixed).
# u.plus is a linear operator on y (verified to machine precision) and is
# invariant to bandwidth (E10V lock), so bootstrap refits are well-posed.
# ---------------------------------------------------------------------------
imols_resid <- function(y, X_mat, deter) {
  f <- tryCatch(
    cointReg::cointRegIM(x = X_mat, y = y, deter = deter, selector = c(1, 2),
                         t.test = FALSE, kernel = "ba", bandwidth = "nw"),
    error = function(e) NULL)
  if (is.null(f)) return(NULL)
  f$u.plus
}

# Core (non-dummy) column indices within cbind(deter, X_mat): the intercept
# plus the stochastic regressors, excluding Bai-Perron step dummies.
core_indices <- function(m) {
  d_k <- ncol(m$deter)
  c(1L, (d_k + 1L):(d_k + ncol(m$X_mat)))
}

# ---------------------------------------------------------------------------
# (a0) HEADLINE DIAGNOSTIC: EG-ADF lag-augmentation sensitivity
# ---------------------------------------------------------------------------
# The v2 report ran an UNAUGMENTED Dickey-Fuller (zero lagged differences) on
# residuals carrying AR(2)-AR(4) structure. A plain DF on serially correlated
# errors is severely biased toward non-rejection. This block quantifies the
# damage: it recomputes the statistic at fixed lags p = 0..4 and at AIC- and
# BIC-selected orders, and counts rejections of "no cointegration" under each.
# This is reported FIRST because it turns out to be the dominant explanation
# for the report's cointegration failure.
# ---------------------------------------------------------------------------
cat("--- (a0) EG-ADF lag-augmentation sensitivity ---\n")
adf_fixed <- function(u, p) {
  T_obs <- length(u); du <- diff(u); ul <- u[-T_obs]
  n <- length(du) - p
  if (n < 12) return(NA_real_)
  Y <- du[(p + 1):length(du)]; Z <- matrix(ul[(p + 1):length(ul)], ncol = 1)
  if (p > 0) for (j in 1:p) Z <- cbind(Z, du[(p + 1 - j):(length(du) - j)])
  f <- tryCatch(lm.fit(Z, Y), error = function(e) NULL); if (is.null(f)) return(NA_real_)
  r <- f$residuals; k <- ncol(Z); s2 <- sum(r^2) / (n - k)
  XtXi <- tryCatch(solve(crossprod(Z)), error = function(e) NULL); if (is.null(XtXi)) return(NA_real_)
  as.numeric(f$coefficients[1] / sqrt(s2 * XtXi[1, 1]))
}
adf_rows <- lapply(names(fs), function(nm) {
  m <- fs[[nm]]; u <- m$u_plus
  mv <- ncol(m$X_mat) + 1
  cv5 <- if (mv <= 3) -3.74 else -4.10
  a <- adf_t_augmented(u, 8L, "aic"); b <- adf_t_augmented(u, 8L, "bic")
  arf <- tryCatch(ar.yw(u, aic = TRUE, order.max = 8)$order, error = function(e) NA_integer_)
  data.frame(Model_ID = nm, m_vars = mv, cv5 = cv5,
             resid_AR1 = cor(u[-1], u[-length(u)]), resid_AR_order = arf,
             adf_p0 = adf_fixed(u, 0), adf_p1 = adf_fixed(u, 1), adf_p2 = adf_fixed(u, 2),
             adf_p3 = adf_fixed(u, 3), adf_p4 = adf_fixed(u, 4),
             adf_aic = as.numeric(a), aic_lag = attr(a, "lag"),
             adf_bic = as.numeric(b), bic_lag = attr(b, "lag"))
})
adf_df <- do.call(rbind, adf_rows)
for (cc in c("p0", "p1", "p2", "p3", "p4", "aic", "bic")) {
  adf_df[[paste0("rej_", cc)]] <- adf_df[[paste0("adf_", cc)]] < adf_df$cv5
}
write.csv(adf_df, file.path(csv_dir, "s51_adf_lag_sensitivity.csv"), row.names = FALSE)
cat(sprintf("  residual AR1 range: %.2f to %.2f (AR order %d-%d) -> augmentation is required\n",
            min(adf_df$resid_AR1), max(adf_df$resid_AR1),
            min(adf_df$resid_AR_order, na.rm = TRUE), max(adf_df$resid_AR_order, na.rm = TRUE)))
cat("  rejections of H0 'no cointegration' at 5%, out of 18:\n")
cat(sprintf("    p=0 (as in v2 report): %2d\n", sum(adf_df$rej_p0)))
for (cc in c("p1", "p2", "p3", "p4")) cat(sprintf("    p=%s%23s%2d\n", substr(cc, 2, 2), "", sum(adf_df[[paste0("rej_", cc)]])))
cat(sprintf("    AIC-selected lag:      %2d\n", sum(adf_df$rej_aic)))
cat(sprintf("    BIC-selected lag:      %2d\n", sum(adf_df$rej_bic)))
cat(sprintf("  AIC and BIC agree on lag order in %d of 18 models.\n\n",
            sum(adf_df$aic_lag == adf_df$bic_lag, na.rm = TRUE)))

# ---------------------------------------------------------------------------
# (a) HANSEN (1992) Lc / MeanF / SupF with bootstrapped p-values
# ---------------------------------------------------------------------------
cat("--- (a) Hansen (1992) parameter instability triad ---\n")
set.seed(SEED)
hansen_rows <- list(); hansen_param_rows <- list()

for (nm in names(fs)) {
  m <- fs[[nm]]
  X_full <- cbind(m$deter, m$X_mat)
  T_obs <- m$T_obs
  bw <- max(1, m$b_hat * T_obs)
  ci <- core_indices(m)

  obs <- hansen_stability(X_full, m$u_plus, bandwidth = bw, core_idx = ci)
  fitted_vals <- m$y - m$u_plus

  # Two null DGPs are drawn in parallel. Agreement between them is the
  # self-normalization check: a statistic whose null distribution depends on
  # which stationary process generated the residuals is not properly
  # normalized and its p-value must not be used for inference.
  ar_fit <- tryCatch(ar.yw(m$u_plus, aic = TRUE, order.max = 8), error = function(e) NULL)
  sieve_draw <- function() {
    if (is.null(ar_fit)) return(rnorm(T_obs, sd = sd(m$u_plus)))
    as.numeric(arima.sim(n = T_obs,
                         list(ar = if (ar_fit$order > 0) ar_fit$ar else numeric(0)),
                         sd = sqrt(ar_fit$var.pred)))
  }
  cols <- c("Lc_all", "Lc_core", "MeanF", "SupF")
  boot_blk <- matrix(NA_real_, N_BOOT_HANSEN, 4, dimnames = list(NULL, cols))
  boot_sie <- matrix(NA_real_, N_BOOT_HANSEN, 4, dimnames = list(NULL, cols))
  for (b in seq_len(N_BOOT_HANSEN)) {
    for (which_dgp in c("blk", "sie")) {
      y_star <- if (which_dgp == "blk") boot_null_stationary(fitted_vals, m$u_plus, bw)
                else fitted_vals + sieve_draw()
      u_star <- imols_resid(y_star, m$X_mat, m$deter)
      if (is.null(u_star)) next
      hb <- hansen_stability(X_full, u_star, bandwidth = bw, core_idx = ci)
      v <- c(hb$Lc_all, hb$Lc_core, hb$MeanF, hb$SupF)
      if (which_dgp == "blk") boot_blk[b, ] <- v else boot_sie[b, ] <- v
    }
  }
  pv <- function(o, M, col) {
    v <- M[, col]; v <- v[is.finite(v)]
    if (!is.finite(o) || length(v) == 0) return(NA_real_)
    mean(c(v, o) >= o)
  }
  selfnorm <- function(col) {
    a <- median(boot_blk[, col], na.rm = TRUE); b2 <- median(boot_sie[, col], na.rm = TRUE)
    if (!is.finite(a) || !is.finite(b2) || max(abs(a), abs(b2)) == 0) return(NA_real_)
    abs(a - b2) / max(abs(a), abs(b2))
  }

  hansen_rows[[nm]] <- data.frame(
    Model_ID = nm, T_obs = T_obs, k_reg = m$k_reg, b_hat = m$b_hat,
    Lc_all = obs$Lc_all, Lc_all_p = pv(obs$Lc_all, boot_sie, "Lc_all"),
    Lc_all_p_block = pv(obs$Lc_all, boot_blk, "Lc_all"),
    Lc_all_selfnorm_gap = selfnorm("Lc_all"),
    Lc_core_descriptive = obs$Lc_core,
    Lc_core_selfnorm_gap = selfnorm("Lc_core"),
    MeanF = obs$MeanF, MeanF_p = pv(obs$MeanF, boot_sie, "MeanF"),
    SupF = obs$SupF, SupF_p = pv(obs$SupF, boot_sie, "SupF"),
    SupF_selfnorm_gap = selfnorm("SupF"),
    SupF_break_year = if (is.na(obs$SupF_index)) NA_integer_ else m$years[obs$SupF_index],
    n_boot_ok = sum(is.finite(boot_sie[, "Lc_all"]))
  )
  hansen_param_rows[[nm]] <- data.frame(
    Model_ID = nm, parameter = names(obs$Lc_by_param),
    Lc = as.numeric(obs$Lc_by_param),
    is_core = seq_along(obs$Lc_by_param) %in% ci
  )
  cat(sprintf("  %-6s Lc_all=%9.2f (p=%.3f, selfnorm gap %.2f)  SupF=%7.3f (p=%.3f)  break=%s\n",
              nm, obs$Lc_all, hansen_rows[[nm]]$Lc_all_p,
              hansen_rows[[nm]]$Lc_all_selfnorm_gap,
              obs$SupF, hansen_rows[[nm]]$SupF_p, hansen_rows[[nm]]$SupF_break_year))
}
hansen_df <- do.call(rbind, hansen_rows)
hansen_param_df <- do.call(rbind, hansen_param_rows)
write.csv(hansen_df, file.path(csv_dir, "s51_hansen_instability.csv"), row.names = FALSE)
write.csv(hansen_param_df, file.path(csv_dir, "s51_hansen_per_parameter_lc.csv"), row.names = FALSE)
cat("\n")

# ---------------------------------------------------------------------------
# (b) CUSUM family
# ---------------------------------------------------------------------------
# IMPORTANT DESIGN DECISION: these run on the CORE specification (intercept +
# stochastic regressors), WITHOUT the Bai-Perron step dummies. Those dummies
# were themselves selected by a break audit on these very residuals; including
# them would absorb the instability the test is trying to detect and bias the
# result toward spurious stability.
# ---------------------------------------------------------------------------
cat("--- (b) CUSUM family (core specification, step dummies excluded) ---\n")
cusum_rows <- list()
for (nm in names(fs)) {
  m <- fs[[nm]]
  dat <- as.data.frame(m$X_mat); dat$.y <- m$y
  form <- as.formula(paste(".y ~", paste(colnames(m$X_mat), collapse = " + ")))

  ocus <- tryCatch(strucchange::efp(form, data = dat, type = "OLS-CUSUM"), error = function(e) NULL)
  rcus <- tryCatch(strucchange::efp(form, data = dat, type = "Rec-CUSUM"), error = function(e) NULL)
  fst  <- tryCatch(strucchange::Fstats(form, data = dat, from = 0.15, to = 0.85), error = function(e) NULL)

  gp <- function(o) if (is.null(o)) NA_real_ else as.numeric(strucchange::sctest(o)$p.value)
  gs <- function(o, ty) if (is.null(o)) NA_real_ else as.numeric(strucchange::sctest(o, type = ty)$p.value)
  gstat <- function(o, ty) if (is.null(o)) NA_real_ else as.numeric(strucchange::sctest(o, type = ty)$statistic)

  bk <- NA_integer_
  if (!is.null(fst)) {
    bi <- which.max(fst$Fstats)
    bk <- m$years[bi + floor(0.15 * m$T_obs)]
  }
  cusum_rows[[nm]] <- data.frame(
    Model_ID = nm,
    OLS_CUSUM_stat = if (is.null(ocus)) NA_real_ else as.numeric(strucchange::sctest(ocus)$statistic),
    OLS_CUSUM_p = gp(ocus),
    Rec_CUSUM_p = gp(rcus),
    supF_stat = gstat(fst, "supF"), supF_p = gs(fst, "supF"),
    aveF_p = gs(fst, "aveF"), expF_p = gs(fst, "expF"),
    supF_break_year = bk
  )
  cat(sprintf("  %-6s OLS-CUSUM p=%.4f  supF p=%.4f  break=%s\n",
              nm, cusum_rows[[nm]]$OLS_CUSUM_p, cusum_rows[[nm]]$supF_p, bk))

  png(file.path(fig_dir, sprintf("s51_cusum_%s.png", nm)), width = 900, height = 500, res = 110)
  if (!is.null(ocus)) { plot(ocus, main = sprintf("OLS-CUSUM: %s", nm)) } else { plot.new() }
  dev.off()
}
cusum_df <- do.call(rbind, cusum_rows)
write.csv(cusum_df, file.path(csv_dir, "s51_cusum_tests.csv"), row.names = FALSE)
cat("\n")

# ---------------------------------------------------------------------------
# (c) Recursive / rolling theta paths  (Rule B: visual-first)
# ---------------------------------------------------------------------------
cat("--- (c) Recursive and rolling elasticity paths ---\n")
MIN_WIN <- 30L; ROLL_WIN <- 40L
recur_rows <- list()
for (nm in names(fs)) {
  m <- fs[[nm]]; d_k <- ncol(m$deter); T_obs <- m$T_obs
  rows <- list()
  for (t in seq(MIN_WIN, T_obs)) {
    idx <- seq_len(t)
    f <- tryCatch(cointReg::cointRegIM(x = m$X_mat[idx, , drop = FALSE], y = m$y[idx],
                                       deter = m$deter[idx, , drop = FALSE],
                                       selector = c(1, 2), t.test = TRUE,
                                       kernel = "ba", bandwidth = "nw"),
                  error = function(e) NULL)
    if (is.null(f)) next
    co <- as.vector(f$theta); sd <- as.vector(f$sd.theta)
    bh <- f$bandwidth$number / t
    cv <- tryCatch(fixedb_crit("t", k = ncol(m$X_mat), b = bh, level = 0.05), error = function(e) NA_real_)
    rows[[length(rows) + 1L]] <- data.frame(
      Model_ID = nm, kind = "recursive", end_year = m$years[t], n = t,
      theta_0 = co[d_k + 1], theta_0_sd = sd[d_k + 1],
      theta_1 = co[d_k + 2], theta_1_sd = sd[d_k + 2], crit95 = cv)
  }
  for (s in seq_len(T_obs - ROLL_WIN + 1L)) {
    idx <- s:(s + ROLL_WIN - 1L)
    f <- tryCatch(cointReg::cointRegIM(x = m$X_mat[idx, , drop = FALSE], y = m$y[idx],
                                       deter = m$deter[idx, , drop = FALSE],
                                       selector = c(1, 2), t.test = TRUE,
                                       kernel = "ba", bandwidth = "nw"),
                  error = function(e) NULL)
    if (is.null(f)) next
    co <- as.vector(f$theta); sd <- as.vector(f$sd.theta)
    bh <- f$bandwidth$number / ROLL_WIN
    cv <- tryCatch(fixedb_crit("t", k = ncol(m$X_mat), b = bh, level = 0.05), error = function(e) NA_real_)
    rows[[length(rows) + 1L]] <- data.frame(
      Model_ID = nm, kind = "rolling", end_year = m$years[idx[ROLL_WIN]], n = ROLL_WIN,
      theta_0 = co[d_k + 1], theta_0_sd = sd[d_k + 1],
      theta_1 = co[d_k + 2], theta_1_sd = sd[d_k + 2], crit95 = cv)
  }
  rr <- do.call(rbind, rows); recur_rows[[nm]] <- rr

  rec <- rr[rr$kind == "recursive", ]
  if (nrow(rec) > 1) {
    png(file.path(fig_dir, sprintf("s51_recursive_theta_%s.png", nm)), width = 900, height = 500, res = 110)
    up <- rec$theta_0 + rec$crit95 * rec$theta_0_sd
    lo <- rec$theta_0 - rec$crit95 * rec$theta_0_sd
    plot(rec$end_year, rec$theta_0, type = "l", lwd = 2, ylim = range(c(up, lo), na.rm = TRUE),
         xlab = "End year of expanding window", ylab = expression(hat(theta)[0]),
         main = sprintf("Recursive capital elasticity: %s", nm))
    lines(rec$end_year, up, lty = 2); lines(rec$end_year, lo, lty = 2)
    abline(h = 0, col = "grey60")
    dev.off()
  }
  cat(sprintf("  %-6s recursive theta_0 range [%.3f, %.3f]\n", nm,
              min(rec$theta_0, na.rm = TRUE), max(rec$theta_0, na.rm = TRUE)))
}
recur_df <- do.call(rbind, recur_rows)
write.csv(recur_df, file.path(csv_dir, "s51_recursive_rolling_theta.csv"), row.names = FALSE)
cat("\n")

# ---------------------------------------------------------------------------
# (d) Gregory-Hansen (1996) regime-shift cointegration, bootstrapped
# ---------------------------------------------------------------------------
cat("--- (d) Gregory-Hansen regime-shift cointegration ---\n")
set.seed(SEED)
gh_rows <- list()
for (nm in names(fs)) {
  m <- fs[[nm]]
  Z0 <- cbind(const = 1, m$X_mat)
  f0 <- lm.fit(Z0, m$y); u0 <- f0$residuals; fitted0 <- m$y - u0
  bw <- max(1, m$b_hat * m$T_obs)

  for (mod in c("level", "trend", "regime")) {
    obs <- gh_test(m$y, m$X_mat, m$years, model = mod)
    nullv <- rep(NA_real_, N_BOOT_GH)
    for (b in seq_len(N_BOOT_GH)) {
      y_star <- boot_null_unitroot(fitted0, u0, bw)
      nullv[b] <- gh_test(y_star, m$X_mat, m$years, model = mod)$stat
    }
    nv <- nullv[is.finite(nullv)]
    p <- if (!is.finite(obs$stat) || length(nv) == 0) NA_real_ else mean(c(nv, obs$stat) <= obs$stat)
    gh_rows[[length(gh_rows) + 1L]] <- data.frame(
      Model_ID = nm, gh_model = mod, statistic = obs$stat,
      break_year = obs$break_year, boot_p = p, n_boot_ok = length(nv))
  }
  gg <- do.call(rbind, gh_rows)
  gg <- gg[gg$Model_ID == nm, ]
  cat(sprintf("  %-6s regime: stat=%7.3f p=%.3f break=%s\n", nm,
              gg$statistic[gg$gh_model == "regime"], gg$boot_p[gg$gh_model == "regime"],
              gg$break_year[gg$gh_model == "regime"]))
}
gh_df <- do.call(rbind, gh_rows)
write.csv(gh_df, file.path(csv_dir, "s51_gregory_hansen.csv"), row.names = FALSE)
cat("\n")

# ---------------------------------------------------------------------------
# (e) Regime-split IM-OLS re-estimation at each model's endogenous break
# ---------------------------------------------------------------------------
cat("--- (e) Regime-split IM-OLS re-estimation (endogenous breaks) ---\n")
MIN_REGIME_N <- 25L
split_rows <- list()
for (nm in names(fs)) {
  m <- fs[[nm]]
  bk <- hansen_df$SupF_break_year[hansen_df$Model_ID == nm]
  if (is.na(bk)) next
  regimes <- list(pre = which(m$years < bk), post = which(m$years >= bk))
  for (rg in names(regimes)) {
    idx <- regimes[[rg]]
    n <- length(idx)
    if (n < 12) next
    # Drop step dummies that are constant within the sub-sample (they would be
    # collinear with the intercept and make the design singular).
    dsub <- m$deter[idx, , drop = FALSE]
    keep <- c(TRUE, apply(dsub[, -1, drop = FALSE], 2, function(z) length(unique(z)) > 1))
    dsub <- dsub[, keep, drop = FALSE]
    f <- tryCatch(cointReg::cointRegIM(x = m$X_mat[idx, , drop = FALSE], y = m$y[idx],
                                       deter = dsub, selector = c(1, 2), t.test = TRUE,
                                       kernel = "ba", bandwidth = "nw"),
                  error = function(e) NULL)
    if (is.null(f)) next
    u <- f$u.plus; Tn <- length(u); dk <- ncol(dsub)
    bh <- f$bandwidth$number / Tn
    # EG-ADF on the sub-sample residual
    eg <- lm(diff(u) ~ u[-Tn] - 1)
    t_adf <- summary(eg)$coefficients[1, 3]
    om2 <- f$omega.u.v
    C_shin <- if (!is.null(om2) && is.finite(om2) && om2 > 0) sum(cumsum(u)^2) / (Tn^2 * om2) else NA_real_
    co <- as.vector(f$theta); sd <- as.vector(f$sd.theta)
    split_rows[[length(split_rows) + 1L]] <- data.frame(
      Model_ID = nm, regime = rg, break_year = bk,
      start_year = min(m$years[idx]), end_year = max(m$years[idx]), n = n,
      theta_0 = co[dk + 1], theta_0_sd = sd[dk + 1],
      theta_1 = co[dk + 2], theta_1_sd = sd[dk + 2],
      b_hat = bh,
      theta_0_stars = fixedb_stars(abs(co[dk + 1] / sd[dk + 1]), "t", k = ncol(m$X_mat), b = bh),
      EG_ADF = t_adf, Shin = C_shin,
      underpowered = n < MIN_REGIME_N)
  }
}
split_df <- do.call(rbind, split_rows)
write.csv(split_df, file.path(csv_dir, "s51_regime_split_reestimation.csv"), row.names = FALSE)
cat(sprintf("  %d regime sub-models estimated; %d flagged underpowered (n < %d)\n\n",
            nrow(split_df), sum(split_df$underpowered), MIN_REGIME_N))

# ---------------------------------------------------------------------------
# (f) Integration-order gap closure
# ---------------------------------------------------------------------------
# Two gaps left open by US_S33: (1) omega_ST_Tier2_GVA_adj was never tested
# standalone, despite being the wage share the repo constitution mandates;
# (2) S33 tested CONTEMPORANEOUS interactions, while S50 builds them from
# LAGGED omega and iota. Close both on the exact series S50 uses.
# ---------------------------------------------------------------------------
cat("--- (f) Integration-order gap closure ---\n")
io_test <- function(x, label) {
  x <- as.numeric(x); x <- x[is.finite(x)]
  adf_l <- tryCatch(urca::ur.df(x, type = "drift", selectlags = "AIC"), error = function(e) NULL)
  adf_d <- tryCatch(urca::ur.df(diff(x), type = "drift", selectlags = "AIC"), error = function(e) NULL)
  kp_l  <- tryCatch(urca::ur.kpss(x, type = "mu", lags = "short"), error = function(e) NULL)
  kp_d  <- tryCatch(urca::ur.kpss(diff(x), type = "mu", lags = "short"), error = function(e) NULL)
  gv <- function(o) if (is.null(o)) NA_real_ else as.numeric(o@teststat[1])
  gc5 <- function(o, cn) if (is.null(o)) NA_real_ else as.numeric(o@cval[1, cn])
  adf_l_s <- gv(adf_l); adf_d_s <- gv(adf_d); kp_l_s <- gv(kp_l); kp_d_s <- gv(kp_d)
  adf_l_r <- is.finite(adf_l_s) && adf_l_s < gc5(adf_l, "5pct")
  adf_d_r <- is.finite(adf_d_s) && adf_d_s < gc5(adf_d, "5pct")
  kp_l_r  <- is.finite(kp_l_s)  && kp_l_s  > gc5(kp_l, "5pct")
  kp_d_r  <- is.finite(kp_d_s)  && kp_d_s  > gc5(kp_d, "5pct")
  verdict <- if (!adf_l_r && kp_l_r && adf_d_r && !kp_d_r) "I(1)" else
             if (adf_l_r && !kp_l_r) "I(0)" else
             if (!adf_d_r && kp_d_r) "I(2) risk" else "ambiguous"
  data.frame(series = label, ADF_level = adf_l_s, ADF_level_rejects = adf_l_r,
             KPSS_level = kp_l_s, KPSS_level_rejects = kp_l_r,
             ADF_diff = adf_d_s, ADF_diff_rejects = adf_d_r,
             KPSS_diff = kp_d_s, KPSS_diff_rejects = kp_d_r, verdict = verdict)
}

io_rows <- list()
m11 <- fs[["M1.1"]]
# Reconstruct the exact lagged series S50 used, from the fitted design matrices.
for (nm in c("M1.1", "M1.5", "M2.1", "M2.9")) {
  m <- fs[[nm]]
  io_rows[[length(io_rows) + 1L]] <- io_test(m$X_mat[, 1], sprintf("%s: k_cap (level regressor)", nm))
  io_rows[[length(io_rows) + 1L]] <- io_test(m$X_mat[, 2], sprintf("%s: %s (lagged interaction as estimated)", nm, colnames(m$X_mat)[2]))
  io_rows[[length(io_rows) + 1L]] <- io_test(m$y, sprintf("%s: y_t", nm))
}
# omega_ST_Tier2_GVA_adj standalone (constitution-mandated, never tested alone)
st <- read.csv(file.path(repo_root, "output", "US", "S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION",
                         "csv", "S29F_shaikh_tonak_wage_share_panel.csv"))
stv <- st$omega_ST_Tier2_GVA_adj[st$year >= 1929 & st$year <= 2024]
io_rows[[length(io_rows) + 1L]] <- io_test(stv, "omega_ST_Tier2_GVA_adj (standalone, 1929-2024)")
io_df <- do.call(rbind, io_rows)
write.csv(io_df, file.path(csv_dir, "s51_integration_order_gap_closure.csv"), row.names = FALSE)
print(io_df[, c("series", "verdict")])
cat("\n")

# ---------------------------------------------------------------------------
# (g) Consolidated verdict ledger
# ---------------------------------------------------------------------------
cat("--- (g) Consolidated verdict ledger ---\n")
ledger <- lapply(names(fs), function(nm) {
  h <- hansen_df[hansen_df$Model_ID == nm, ]
  cu <- cusum_df[cusum_df$Model_ID == nm, ]
  g <- gh_df[gh_df$Model_ID == nm & gh_df$gh_model == "regime", ]
  s0 <- s50[s50$Model_ID == nm, ]
  ad <- adf_df[adf_df$Model_ID == nm, ]

  # Cointegration verdict now rests on the CORRECTED (lag-augmented) EG-ADF.
  # The v2 report's p=0 verdict is retained alongside it to make the reversal
  # auditable rather than silent.
  coint_corrected <- isTRUE(ad$rej_aic)
  coint_v2        <- isTRUE(ad$rej_p0)
  # Instability inference uses strucchange's published asymptotics (supF /
  # OLS-CUSUM) rather than the hand-rolled Hansen bootstrap, whose subset
  # statistic failed the self-normalization check. Hansen enters descriptively.
  unstable <- isTRUE(cu$supF_p < 0.05) || isTRUE(cu$OLS_CUSUM_p < 0.05)
  gh_rej <- isTRUE(g$boot_p < 0.05)

  status <- if (coint_corrected && !unstable) "Promoted" else
            if (coint_corrected && unstable) "Held" else
            if (!coint_corrected && gh_rej) "Held" else
            if (unstable || gh_rej) "Blocked" else "Rejected"
  rationale <- if (status == "Promoted") "Cointegration holds under the corrected lag-augmented ADF; no detected parameter instability." else
               if (status == "Held") "Cointegration supported, but parameter instability is present -- the long-run relation is regime-conditional, not a fixed-coefficient equilibrium." else
               if (status == "Blocked") "No cointegration even after correcting the ADF and allowing a regime shift." else
               "Neither cointegration nor instability established; evidence inconclusive."

  data.frame(
    Model_ID = nm,
    Theoretical_Basis = sprintf("%s | %s", s0$Wage_Label, s0$Capital_Label),
    Evidence = sprintf(paste0("ADF(AIC,lag=%s)=%.2f vs cv %.2f -> %s [v2 unaugmented was %.2f -> %s]; ",
                              "supF p=%.3f; OLS-CUSUM p=%.3f; GH-regime=%.2f (p=%.3f); ",
                              "Lc_all=%.1f (descriptive); breaks: CUSUM %s / GH %s / BP %s"),
                       ad$aic_lag, ad$adf_aic, ad$cv5,
                       if (coint_corrected) "REJECTS no-coint" else "fails to reject",
                       ad$adf_p0, if (coint_v2) "REJECTS" else "fails to reject",
                       cu$supF_p, cu$OLS_CUSUM_p, g$statistic, g$boot_p, h$Lc_all,
                       cu$supF_break_year, g$break_year, s0$Break_Years),
    Status = status,
    Rationale = rationale,
    Governing_Lock = "E17 (stars/critical values); E15 (VW triad); E10V (IM-OLS CPR); E18 (stability audit protocol)",
    stringsAsFactors = FALSE)
})
ledger_df <- do.call(rbind, ledger)
write.csv(ledger_df, file.path(csv_dir, "s51_verdict_ledger.csv"), row.names = FALSE)
print(table(ledger_df$Status))

saveRDS(list(hansen = hansen_df, hansen_param = hansen_param_df, cusum = cusum_df,
             recursive = recur_df, gh = gh_df, split = split_df, io = io_df,
             ledger = ledger_df, validation = val_df, sanity = san),
        file.path(out_dir, "s51_stability_audit.rds"))

cat("\n========================================================================\n")
cat("S51 complete. Outputs in:", out_dir, "\n")
cat("========================================================================\n")
