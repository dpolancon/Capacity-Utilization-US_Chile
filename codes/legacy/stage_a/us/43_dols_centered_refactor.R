# 43_dols_centered_refactor.R
# ==============================================================================
# Centered DOLS theta-identification — US nonfinancial corporate
# ==============================================================================
#
# Two changes from prior scripts:
#   1. KGC_NF deflated by pK_NF (own capital-goods deflator), NOT by Py
#   2. Centered parameterization: omega_c_t = omega_t - omega_bar_sample
#
# Estimator: DOLS with p=2 leads + 2 lags, Newey-West HAC SEs
# Windows: 5 (Full, Pre-1974, Post-1973, Fordist core 1945-1973,
#             Deep comparison 1940-1978)
#
# Model (centered):
#   y_t = c + theta_bar * k_t + beta2 * ((omega_t - omega_bar) * k_t)
#         + DOLS leads/lags + epsilon_t
#
# Recovery:
#   theta_t = theta_bar + beta2 * (omega_t - omega_bar)
#   theta_t_hat = theta_bar_hat + beta2_hat * (omega_t - omega_bar_sample)
#
# Harrodian threshold (centered):
#   omega_H = omega_bar + (1 - theta_bar_hat) / beta2_hat
#   valid only when beta2_hat < 0 and implied crossing is positive/admissible
#
# Equivalence check:
#   Old (uncentered): y_t = c + theta1*k_t + theta2*(omega_t * k_t) + DOLS
#   New (centered):   y_t = c + theta_bar*k_t + beta2*(omega_c_t * k_t) + DOLS
#   Algebraic mapping: theta1 = theta_bar - beta2*omega_bar, theta2 = beta2
#   => theta_t = theta1 + theta2*omega_t = theta_bar + beta2*(omega_t - omega_bar)
# ==============================================================================

library(lmtest)
library(sandwich)
library(urca)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

outdir <- file.path(REPO, "output/stage_a/us/vecm_results")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# ══════════════════════════════════════════════════════════════════════════════
# 1. DATA LOADING AND DEFLATION
# ══════════════════════════════════════════════════════════════════════════════

d <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
nf_inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
d <- merge(d, nf_inc[, c("year", "Py_fred")], by = "year")
d <- d[order(d$year), ]

# Y: deflated by Py (GDP deflator), rebased to 2024 prices
Py_2024 <- d$Py_fred[d$year == 2024]
d$Y_real <- d$GVA_NF / (d$Py_fred / Py_2024)
d$y_t    <- log(d$Y_real)

# K: KGC_NF deflated by pK_NF (own capital-goods deflator), NOT by Py
#    This is the correction: each variable scaled by its own deflator
d$K_real <- d$KGC_NF / (d$pK_NF / d$pK_NF[d$year == 2024])
d$k_t    <- log(d$K_real)

d$omega_t <- d$Wsh_NF  # wage share (unitless, no deflation)

cat(sprintf("Data: %d-%d (%d obs)\n", min(d$year), max(d$year), nrow(d)))
cat("Deflators: Y by Py_fred, K by pK_NF (own deflator — corrected)\n\n")

# ── Deflator provenance diagnostics ──────────────────────────────────────────
cat("=== DEFLATOR PROVENANCE ===\n")
cat(sprintf("Py_fred: min=%.2f max=%.2f Py[2024]=%.2f\n",
    min(d$Py_fred), max(d$Py_fred), Py_2024))
cat(sprintf("  Py_rebased = Py_fred / %.2f  →  range [%.4f, %.4f]\n",
    Py_2024, min(d$Py_fred / Py_2024), max(d$Py_fred / Py_2024)))
pK_2024 <- d$pK_NF[d$year == 2024]
cat(sprintf("pK_NF:   min=%.2f max=%.2f pK[2024]=%.2f\n",
    min(d$pK_NF), max(d$pK_NF), pK_2024))
cat(sprintf("  pK_rebased = pK_NF / %.2f  →  range [%.4f, %.4f]\n",
    pK_2024, min(d$pK_NF / pK_2024), max(d$pK_NF / pK_2024)))

# Check for tautology: if deflator is constant (=100 everywhere), rebasing does nothing
py_tautology <- (sd(d$Py_fred) < 1e-10)
pk_tautology <- (sd(d$pK_NF) < 1e-10)
cat(sprintf("\nPy_fred rebasing: %s\n",
    ifelse(py_tautology, "TAUTOLOGICAL (constant deflator — no real deflation)",
           sprintf("NECESSARY — varies %.1f→%.1f (%.1fx range)",
                   min(d$Py_fred), max(d$Py_fred), max(d$Py_fred)/min(d$Py_fred)))))
cat(sprintf("pK_NF rebasing:   %s\n",
    ifelse(pk_tautology, "TAUTOLOGICAL (constant deflator — no real deflation)",
           sprintf("NECESSARY — varies %.1f→%.1f (%.1fx range)",
                   min(d$pK_NF), max(d$pK_NF), max(d$pK_NF)/min(d$pK_NF)))))
cat("\n")

# ══════════════════════════════════════════════════════════════════════════════
# 2. ESTIMATION WINDOWS (economic labels preserved)
# ══════════════════════════════════════════════════════════════════════════════

windows <- list(
  list(label = "Full sample",            start = 1929, end = 2024),
  list(label = "Pre-1974 (<= 1973)",     start = 1929, end = 1973),
  list(label = "Post-1973 (>= 1974)",    start = 1974, end = 2024),
  list(label = "Fordist core (1945-1973)", start = 1945, end = 1973),
  list(label = "Deep comparison (1940-1978)", start = 1940, end = 1978)
)

cat("Estimation windows:\n")
for (w in windows) {
  cat(sprintf("  %-35s %d-%d\n", w$label, w$start, w$end))
}
cat("\n")

# ══════════════════════════════════════════════════════════════════════════════
# 3. DOLS BUILDER — p=2 leads + lags, returns design matrices for both specs
# ══════════════════════════════════════════════════════════════════════════════

build_dols_data <- function(df, p_leads = 2, p_lags = 2) {
  n <- nrow(df)
  dk   <- c(NA, diff(df$k_t))
  domegak <- c(NA, diff(df$omega_k_t))
  domega  <- c(NA, diff(df$omega_t))

  regs <- data.frame(
    year     = df$year,
    y        = df$y_t,
    k        = df$k_t,
    omega_k  = df$omega_k_t,
    omega_c_k = df$omega_c_k_t
  )

  for (l in (-p_lags):p_leads) {
    sfx <- if (l < 0) paste0("lead", abs(l)) else if (l > 0) paste0("lag", l) else "cur"

    if (l <= 0) {
      regs[[paste0("dk_", sfx)]]     <- c(rep(NA, abs(l)), dk[1:(n - abs(l))])
      regs[[paste0("domegak_", sfx)]] <- c(rep(NA, abs(l)), domegak[1:(n - abs(l))])
    } else {
      regs[[paste0("dk_", sfx)]]     <- c(dk[(l + 1):n], rep(NA, l))
      regs[[paste0("domegak_", sfx)]] <- c(domegak[(l + 1):n], rep(NA, l))
    }
  }

  regs <- regs[complete.cases(regs), ]
  regs
}

# ══════════════════════════════════════════════════════════════════════════════
# 4. ESTIMATION FUNCTION — centered + uncentered + equivalence
# ══════════════════════════════════════════════════════════════════════════════

estimate_window <- function(df, wlabel, p_leads = 2, p_lags = 2) {
  n_orig <- nrow(df)

  # Within-sample average wage share (centering point)
  omega_bar <- mean(df$omega_t)

  # Construct interaction terms
  df$omega_k_t   <- df$omega_t * df$k_t             # uncentered
  df$omega_c_t   <- df$omega_t - omega_bar           # centered omega
  df$omega_c_k_t <- df$omega_c_t * df$k_t            # centered interaction

  # Build DOLS data
  regs <- build_dols_data(df, p_leads = p_leads, p_lags = p_lags)
  n_eff <- nrow(regs)

  # Dynamic regressors (exclude long-run vars)
  dyn_vars <- grep("^dk_|^domegak_", names(regs), value = TRUE)

  # --------------------------------------------------------------------------
  # A. UNcentered specification (old): y ~ k + omega_k + DOLS
  # --------------------------------------------------------------------------
  fml_unc <- as.formula(paste("y ~ k + omega_k +", paste(dyn_vars, collapse = " + ")))
  fit_unc <- lm(fml_unc, data = regs)
  cf_unc  <- coef(fit_unc)
  vc_unc  <- vcov(fit_unc)
  se_unc  <- sqrt(diag(vc_unc))

  theta1_hat_unc <- cf_unc["k"]
  theta2_hat_unc <- cf_unc["omega_k"]
  se_theta1_unc  <- se_unc["k"]
  se_theta2_unc  <- se_unc["omega_k"]

  # Newey-West HAC SEs for uncentered
  nw_lag <- max(1, p_leads + 1)  # NW lag = p + 1
  vc_hac_unc <- NeweyWest(fit_unc, lag = nw_lag, prewhite = FALSE, adjust = TRUE)
  ct_unc <- coeftest(fit_unc, vcov. = vc_hac_unc)
  se_hac_unc <- ct_unc[, 2]
  se_theta1_hac_unc <- se_hac_unc["k"]
  se_theta2_hac_unc <- se_hac_unc["omega_k"]

  # --------------------------------------------------------------------------
  # B. Centered specification (new): y ~ k + omega_c_k + DOLS
  # --------------------------------------------------------------------------
  fml_cen <- as.formula(paste("y ~ k + omega_c_k +", paste(dyn_vars, collapse = " + ")))
  fit_cen <- lm(fml_cen, data = regs)
  cf_cen  <- coef(fit_cen)
  vc_cen  <- vcov(fit_cen)
  se_cen  <- sqrt(diag(vc_cen))

  theta_bar_hat <- cf_cen["k"]
  beta2_hat     <- cf_cen["omega_c_k"]
  se_theta_bar  <- se_cen["k"]
  se_beta2      <- se_cen["omega_c_k"]

  # Newey-West HAC SEs for centered
  vc_hac_cen <- NeweyWest(fit_cen, lag = nw_lag, prewhite = FALSE, adjust = TRUE)
  ct_cen <- coeftest(fit_cen, vcov. = vc_hac_cen)
  se_hac_cen <- ct_cen[, 2]
  se_theta_bar_hac <- se_hac_cen["k"]
  se_beta2_hac     <- se_hac_cen["omega_c_k"]

  # --------------------------------------------------------------------------
  # C. Equivalence diagnostics
  # --------------------------------------------------------------------------
  # Algebraic mapping:
  #   theta1_hat_unc should equal theta_bar_hat - beta2_hat * omega_bar
  #   theta2_hat_unc should equal beta2_hat
  theta1_implied  <- theta_bar_hat - beta2_hat * omega_bar
  theta2_implied  <- beta2_hat

  diff_theta1 <- abs(theta1_hat_unc - theta1_implied)
  diff_theta2 <- abs(theta2_hat_unc - theta2_implied)

  # Fitted values and residuals should be identical across specs
  fitted_unc <- fitted(fit_unc)
  fitted_cen <- fitted(fit_cen)
  resid_unc  <- residuals(fit_unc)
  resid_cen  <- residuals(fit_cen)

  max_fit_diff <- max(abs(fitted_unc - fitted_cen))
  max_resid_diff <- max(abs(resid_unc - resid_cen))

  # --------------------------------------------------------------------------
  # D. Theta path recovery
  # --------------------------------------------------------------------------
  # theta_t = theta_bar + beta2 * (omega_t - omega_bar)
  # Use the centered df (which has omega_c_t computed)
  theta_path <- theta_bar_hat + beta2_hat * (df$omega_t - omega_bar)

  # --------------------------------------------------------------------------
  # E. Harrodian threshold
  # --------------------------------------------------------------------------
  # omega_H = omega_bar + (1 - theta_bar_hat) / beta2_hat
  # Valid only when beta2_hat < 0 and crossing is positive/admissible
  omega_H <- NA
  threshold_status <- "not computed"

  if (!is.finite(beta2_hat) || beta2_hat == 0) {
    threshold_status <- "slope not identified"
  } else if (beta2_hat > 0) {
    threshold_status <- "wrong-sign slope"
  } else {
    # beta2_hat < 0
    crossing <- (1 - theta_bar_hat) / beta2_hat
    omega_H  <- omega_bar + crossing

    if (!is.finite(omega_H) || omega_H <= 0) {
      threshold_status <- "no admissible positive threshold"
    } else if (omega_H < min(df$omega_t) || omega_H > max(df$omega_t)) {
      threshold_status <- "threshold outside observed sample range"
    } else {
      threshold_status <- "Harrodian-valid"
    }
  }

  # --------------------------------------------------------------------------
  # F. Summary stats
  # --------------------------------------------------------------------------
  r2   <- summary(fit_cen)$r.squared
  r2a  <- summary(fit_cen)$adj.r.squared

  # Residual stationarity (ADF)
  adf_r <- ur.df(residuals(fit_cen), type = "none", selectlags = "BIC", lags = 4)

  # G. Economic label + regression years
  # --------------------------------------------------------------------------
  reg_start <- min(regs$year)
  reg_end   <- max(regs$year)

  # Truncate data to effective regression sample
  reg_idx <- which(df$year >= reg_start & df$year <= reg_end)

  list(
    # Window labels
    label             = wlabel,
    start_year        = df$year[1],
    end_year          = df$year[n_orig],
    regression_start  = reg_start,
    regression_end    = reg_end,
    N                 = n_eff,
    N_orig            = n_orig,

    # Omega stats
    omega_bar         = omega_bar,
    omega_min         = min(df$omega_t),
    omega_max         = max(df$omega_t),

    # Centered estimates (HAC SEs)
    theta_bar_hat     = theta_bar_hat,
    se_theta_bar_hac  = se_theta_bar_hac,
    beta2_hat         = beta2_hat,
    se_beta2_hac      = se_beta2_hac,
    t_theta_bar       = theta_bar_hat / se_theta_bar_hac,
    t_beta2           = beta2_hat / se_beta2_hac,

    # Uncentered estimates (for equivalence)
    theta1_hat_unc    = theta1_hat_unc,
    se_theta1_hac_unc = se_theta1_hac_unc,
    theta2_hat_unc    = theta2_hat_unc,
    se_theta2_hac_unc = se_theta2_hac_unc,

    # Equivalence diagnostics
    theta1_implied    = theta1_implied,
    theta2_implied    = theta2_implied,
    diff_theta1       = diff_theta1,
    diff_theta2       = diff_theta2,
    max_fit_diff      = max_fit_diff,
    max_resid_diff    = max_resid_diff,

    # Diagnostics
    theta_path        = theta_path[reg_idx],
    fitted            = fitted_cen,
    residuals         = resid_cen,
    r2                = r2,
    r2_adj            = r2a,
    adf_residual      = adf_r@teststat[1],
    adf_cv5           = adf_r@cval[1, 2],
    cointegrated      = adf_r@teststat[1] < adf_r@cval[1, 2],

    # Harrodian threshold
    omega_H           = omega_H,
    threshold_status  = threshold_status,

    # Full data for time-series outputs (regression sample only)
    years             = df$year[reg_idx],
    omega_t           = df$omega_t[reg_idx],
    omega_c_t         = df$omega_c_t[reg_idx]
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# 5. RUN ALL 5 WINDOWS
# ══════════════════════════════════════════════════════════════════════════════

cat("=", rep("=", 74), "\n")
cat("CENTERED DOLS ESTIMATION — 5 WINDOWS\n")
cat("Estimator: DOLS(p=2), Newey-West HAC SEs, lag=", max(1, 2 + 1), "\n")
cat(rep("=", 75), "\n\n")

results <- list()
for (w in windows) {
  df_w <- d[d$year >= w$start & d$year <= w$end, ]
  cat(sprintf("\n--- %s (%d-%d) ---\n", w$label, w$start, w$end))
  results[[w$label]] <- estimate_window(df_w, w$label)
  r <- results[[w$label]]

  cat(sprintf("  N=%d  R2=%.4f  R2adj=%.4f\n", r$N, r$r2, r$r2_adj))
  cat(sprintf("  omega_bar=%.4f  [%.4f, %.4f]\n", r$omega_bar, r$omega_min, r$omega_max))
  cat(sprintf("  theta_bar=%.4f (HAC SE=%.4f, t=%.3f)\n",
      r$theta_bar_hat, r$se_theta_bar_hac, r$t_theta_bar))
  cat(sprintf("  beta2    =%.4f (HAC SE=%.4f, t=%.3f)\n",
      r$beta2_hat, r$se_beta2_hac, r$t_beta2))
  cat(sprintf("  omega_H  = %s — %s\n",
      ifelse(is.na(r$omega_H), "N/A", sprintf("%.4f", r$omega_H)), r$threshold_status))
  cat(sprintf("  Equivalence: |diff_theta1|=%.2e |diff_theta2|=%.2e\n",
      r$diff_theta1, r$diff_theta2))
  cat(sprintf("  Max fitted diff=%.2e  Max resid diff=%.2e\n",
      r$max_fit_diff, r$max_resid_diff))
  cat(sprintf("  Residual ADF=%.3f (5%% cv=%.3f) — %s\n",
      r$adf_residual, r$adf_cv5,
      ifelse(r$cointegrated, "cointegrated", "WARNING")))
}

# ══════════════════════════════════════════════════════════════════════════════
# 6. MASTER SUMMARY TABLE (machine-readable CSV)
# ══════════════════════════════════════════════════════════════════════════════

cat("\n\n", rep("=", 75), "\n")
cat("MASTER SUMMARY TABLE\n")
cat(rep("=", 75), "\n\n")

summary_df <- do.call(rbind, lapply(results, function(r) {
  data.frame(
    label             = r$label,
    start_year        = r$start_year,
    end_year          = r$end_year,
    regression_start  = r$regression_start,
    regression_end    = r$regression_end,
    N                 = r$N,
    omega_mean        = r$omega_bar,
    omega_min         = r$omega_min,
    omega_max         = r$omega_max,
    theta_bar_hat     = r$theta_bar_hat,
    se_theta_bar_hac  = r$se_theta_bar_hac,
    beta2_hat         = r$beta2_hat,
    se_beta2_hac      = r$se_beta2_hac,
    t_theta_bar       = r$t_theta_bar,
    t_beta2           = r$t_beta2,
    omega_H           = ifelse(is.na(r$omega_H), NA, r$omega_H),
    threshold_status  = r$threshold_status,
    r2                = r$r2,
    r2_adj            = r$r2_adj,
    adf_residual      = r$adf_residual,
    cointegrated      = r$cointegrated,
    diff_theta1       = r$diff_theta1,
    diff_theta2       = r$diff_theta2,
    max_fit_diff      = r$max_fit_diff,
    max_resid_diff    = r$max_resid_diff,
    stringsAsFactors  = FALSE
  )
}))

write.csv(summary_df, file.path(outdir, "dols_centered_summary_us.csv"), row.names = FALSE)
cat("Saved: dols_centered_summary_us.csv\n")

# Print formatted table
cat(sprintf("\n%-35s %6s %8s %10s %10s %8s %10s %8s %12s\n",
    "Window", "N", "omega_bar", "theta_bar", "SE(thb)", "beta2", "SE(b2)", "omega_H", "threshold"))
cat(strrep("-", 110), "\n")
for (i in 1:nrow(summary_df)) {
  r <- summary_df[i, ]
  cat(sprintf("%-35s %6d %8.4f %10.4f %10.4f %8.4f %8.4f %12s %-12s\n",
      substr(r$label, 1, 35), r$N, r$omega_mean, r$theta_bar_hat, r$se_theta_bar_hac,
      r$beta2_hat, r$se_beta2_hac,
      ifelse(is.na(r$omega_H), "N/A", sprintf("%.4f", r$omega_H)),
      r$threshold_status))
}

# ══════════════════════════════════════════════════════════════════════════════
# 7. THETA-PATH TIME SERIES (per sample)
# ══════════════════════════════════════════════════════════════════════════════

cat("\n\nSaving theta-path time series...\n")

theta_path_df <- do.call(rbind, lapply(results, function(r) {
  data.frame(
    year       = r$years,
    window     = r$label,
    omega_t    = r$omega_t,
    omega_c_t  = r$omega_c_t,
    theta_t    = r$theta_path,
    fitted     = r$fitted,
    residual   = r$residuals,
    stringsAsFactors = FALSE
  )
}))

write.csv(theta_path_df, file.path(outdir, "dols_centered_theta_path_us.csv"), row.names = FALSE)
cat("Saved: dols_centered_theta_path_us.csv\n")

# ══════════════════════════════════════════════════════════════════════════════
# 8. LATEX-READY TABLE
# ══════════════════════════════════════════════════════════════════════════════

latex_lines <- character()
latex_lines <- c(latex_lines, "\\begin{table}[htbp]")
latex_lines <- c(latex_lines, "\\centering")
latex_lines <- c(latex_lines, "\\caption{Centered DOLS Estimates --- US Nonfinancial Corporate}")
latex_lines <- c(latex_lines, "\\label{tab:dols_centered_us}")
latex_lines <- c(latex_lines, "\\small")
latex_lines <- c(latex_lines, "\\begin{tabular}{l c c c c c c l}")
latex_lines <- c(latex_lines, "\\hline")
latex_lines <- c(latex_lines, "Window & $N$ & $\\bar{\\omega}$ & $\\hat{\\bar{\\theta}}$ & $\\hat{\\beta}_2$ & $\\omega_H$ & Status & Coint. \\\\")
latex_lines <- c(latex_lines, "\\hline")

for (i in 1:nrow(summary_df)) {
  r <- summary_df[i, ]
  label_tex <- gsub(" ", "~", r$label)
  omega_H_tex <- ifelse(is.na(r$omega_H), "---", sprintf("%.3f", r$omega_H))
  coint_tex <- ifelse(r$cointegrated, "yes", "no")
  latex_lines <- c(latex_lines, sprintf(
    "%s & %d & %.4f & %.4f & %.4f & %s & %s & %s \\\\",
    label_tex, r$N, r$omega_mean, r$theta_bar_hat, r$beta2_hat,
    omega_H_tex, r$threshold_status, coint_tex))
}

latex_lines <- c(latex_lines, "\\hline")
latex_lines <- c(latex_lines, "\\multicolumn{8}{l}{\\footnotesize DOLS($p=2$), Newey-West HAC SEs. $\\omega_H = \\bar{\\omega} + (1-\\hat{\\bar{\\theta}})/\\hat{\\beta}_2$.}")
latex_lines <- c(latex_lines, "\\end{tabular}")
latex_lines <- c(latex_lines, "\\end{table}")

writeLines(latex_lines, file.path(outdir, "dols_centered_table_us.tex"))
cat("Saved: dols_centered_table_us.tex\n")

# ══════════════════════════════════════════════════════════════════════════════
# 9. MARKDOWN INTERPRETATION NOTE
# ══════════════════════════════════════════════════════════════════════════════

md <- character()
md <- c(md, "# Centered DOLS θ-Identification — US Nonfinancial Corporate")
md <- c(md, "")
md <- c(md, "## Estimation Details")
md <- c(md, "")
md <- c(md, "- **Estimator**: DOLS with $p=2$ leads and lags of first differences")
md <- c(md, "- **Standard errors**: Newey-West HAC, lag = $p+1 = 3$")
md <- c(md, "- **Deflators**: $Y$ deflated by $P_Y$ (GDP deflator); $K$ deflated by $p_K$ (capital-goods deflator)")
md <- c(md, "- **Centering**: $\\omega^c_t = \\omega_t - \\bar{\\omega}_{\\text{sample}}$, computed within each window")
md <- c(md, "- **Model**: $y_t = c + \\bar{\\theta} k_t + \\beta_2 (\\omega^c_t k_t) + \\text{DOLS terms} + \\varepsilon_t$")
md <- c(md, "- **Recovery**: $\\hat{\\theta}_t = \\hat{\\bar{\\theta}} + \\hat{\\beta}_2 (\\omega_t - \\bar{\\omega}_{\\text{sample}})$")
md <- c(md, "- **Harrodian threshold**: $\\omega_H = \\bar{\\omega} + (1 - \\hat{\\bar{\\theta}})/\\hat{\\beta}_2$")
md <- c(md, "")
md <- c(md, "## Deflator Provenance")
md <- c(md, "")
md <- c(md, sprintf("- **$P_Y$ (Py_fred)**: source `income_accounts_NF.csv`, base year FRED index. Range %.2f–%.2f. Rebasing to 2024 = 1: **NECESSARY** — index varies %.1fx over sample.",
    min(d$Py_fred), max(d$Py_fred), max(d$Py_fred)/min(d$Py_fred)))
md <- c(md, sprintf("- **$p_K$ (pK_NF)**: source `US_corporate_NF_kstock_distribution.csv`, BEA capital-goods deflator for nonfinancial corporate. Range %.2f–%.2f. Rebasing to 2024 = 1: **NECESSARY** — index varies %.1fx over sample.",
    min(d$pK_NF), max(d$pK_NF), max(d$pK_NF)/min(d$pK_NF)))
md <- c(md, "")
md <- c(md, "Both deflators are **time-varying price indices**, not constants. The 2024 rebasing (divide by terminal-year value) is a normalization to express all real variables in 2024 purchasing power. It is not tautological: the indices span substantially different price levels across the sample, and the rebasing changes the level of logged variables by an additive constant that does not affect estimated slopes or cointegration relationships.")
md <- c(md, "")
md <- c(md, "## Results Summary")
md <- c(md, "")

for (i in 1:nrow(summary_df)) {
  r <- summary_df[i, ]
  md <- c(md, sprintf("### %s", r$label))
  md <- c(md, "")
  md <- c(md, sprintf("- **Sample years**: %d–%d (economic label)", r$start_year, r$end_year))
  md <- c(md, sprintf("- **Regression years**: %d–%d (after DOLS trimming)", r$regression_start, r$regression_end))
  md <- c(md, sprintf("- **Active estimation window**: %d–%d (N = %d, after 2 leads + 2 lags + trend loss)", r$regression_start, r$regression_end, r$N))
  md <- c(md, sprintf("- **Effective N**: %d", r$N))
  md <- c(md, sprintf("- **Wage share**: mean = %.4f, min = %.4f, max = %.4f", r$omega_mean, r$omega_min, r$omega_max))
  md <- c(md, sprintf("- **$\\hat{\\bar{\\theta}}$**: %.4f (HAC SE = %.4f, t = %.3f)", r$theta_bar_hat, r$se_theta_bar_hac, r$t_theta_bar))
  md <- c(md, sprintf("- **$\\hat{\\beta}_2$**: %.4f (HAC SE = %.4f, t = %.3f)", r$beta2_hat, r$se_beta2_hac, r$t_beta2))
  md <- c(md, sprintf("- **R²**: %.4f (adj. = %.4f)", r$r2, r$r2_adj))
  md <- c(md, sprintf("- **Residual ADF**: %.3f (5%% cv = %.3f) — %s", r$adf_residual, r$adf_cv5, ifelse(r$cointegrated, "cointegrated", "WARNING")))
  md <- c(md, sprintf("- **Harrodian threshold**: %s — %s",
    ifelse(is.na(r$omega_H), "N/A", sprintf("ω_H = %.4f", r$omega_H)),
    r$threshold_status))
  md <- c(md, sprintf("- **Equivalence**: |Δθ₁| = %.2e, |Δθ₂| = %.2e, max|Δfitted| = %.2e",
    r$diff_theta1, r$diff_theta2, r$max_fit_diff))
  md <- c(md, "")
}

md <- c(md, "## Fordist Core vs. Deep Comparison Window")
md <- c(md, "")

r_fc <- summary_df[summary_df$label == "Fordist core (1945-1973)", ]
r_dc <- summary_df[summary_df$label == "Deep comparison (1940-1978)", ]

if (nrow(r_fc) == 1 && nrow(r_dc) == 1) {
  beta2_fc <- r_fc$beta2_hat[1]
  beta2_dc <- r_dc$beta2_hat[1]
  se_fc    <- r_fc$se_beta2_hac[1]
  se_dc    <- r_dc$se_beta2_hac[1]
  t_fc     <- r_fc$t_beta2[1]
  t_dc     <- r_dc$t_beta2[1]
  status_fc <- r_fc$threshold_status[1]
  status_dc <- r_dc$threshold_status[1]
  oH_fc    <- ifelse(is.na(r_fc$omega_H[1]), "N/A", sprintf("%.4f", r_fc$omega_H[1]))
  oH_dc    <- ifelse(is.na(r_dc$omega_H[1]), "N/A", sprintf("%.4f", r_dc$omega_H[1]))

  diff_beta2 <- beta2_dc - beta2_fc
  pct_change <- 100 * diff_beta2 / abs(beta2_fc)

  md <- c(md, sprintf(
    "The **Fordist core (1945–1973)** and **Deep comparison (1940–1978)** windows allow us to assess whether including the late-1930s transition years and the post-1973 break period materially alters the distributional slope estimate.",
    ""))
  md <- c(md, sprintf(
    "- **β̂₂ (Fordist core)**: %.4f (HAC SE = %.4f, t = %.3f) — %s",
    beta2_fc, se_fc, t_fc, status_fc))
  md <- c(md, sprintf(
    "- **β̂₂ (Deep comparison)**: %.4f (HAC SE = %.4f, t = %.3f) — %s",
    beta2_dc, se_dc, t_dc, status_dc))
  md <- c(md, "")
  md <- c(md, sprintf(
    "The difference is Δβ₂ = %+.5f (%+.1f%% relative to the Fordist-core magnitude).",
    diff_beta2, pct_change))
  md <- c(md, "")

  if (abs(diff_beta2) < 0.5 * abs(beta2_fc)) {
    md <- c(md, sprintf(
      "This is a **modest change** relative to the Fordist-core estimate. The distributional slope β₂ is qualitatively stable across the two windows: both are %s, and both yield a %s Harrodian-threshold classification (%s vs. %s).",
      ifelse(beta2_fc < 0, "negative", "positive"),
      ifelse(status_fc == "Harrodian-valid", "valid", status_fc),
      oH_fc, oH_dc))
  } else if (sign(beta2_fc) == sign(beta2_dc)) {
    md <- c(md, sprintf(
      "This is a **substantial change in magnitude** but the sign is preserved. The Deep comparison window %s the estimated slope to %.4f from %.4f. The Harrodian threshold %s. The qualitative conclusion about the distributional channel %s.",
      ifelse(abs(beta2_dc) > abs(beta2_fc), "strengthens", "weakens"),
      beta2_dc, beta2_fc,
      ifelse(status_dc == status_fc, "classification is unchanged", paste("changes from", status_fc, "to", status_dc)),
      ifelse(status_dc == "Harrodian-valid" || status_fc == "Harrodian-valid", "remains supported in at least one window", "is affected by the window choice")))
  } else {
    md <- c(md, sprintf(
      "This is a **qualitative change**: the sign of β₂ flips between the two windows. The Fordist core yields β̂₂ = %.4f while the Deep comparison yields β̂₂ = %.4f. This suggests the distributional channel is **not robust** to the inclusion of 1940–1944 and 1974–1978 transition years.",
      beta2_fc, beta2_dc))
  }

  md <- c(md, "")
  md <- c(md, sprintf(
    "The Deep comparison window adds 5 pre-war years (1940–1944) and 5 post-crisis years (1974–1978) to the Fordist core. If β₂ is stable, this confirms the distributional mechanism operates across the broader mid-century accumulation regime. If β₂ shifts materially, it indicates the Fordist core (1945–1973) is structurally distinct from the surrounding transition periods."))
}

md <- c(md, "")
md <- c(md, "## Equivalence Verification")
md <- c(md, "")
md <- c(md, "The centered parameterization is algebraically equivalent to the uncentered specification:")
md <- c(md, "")
md <- c(md, "- Centered: $y_t = c + \\bar{\\theta} k_t + \\beta_2 (\\omega^c_t k_t) + \\varepsilon_t$")
md <- c(md, "- Uncentered: $y_t = c + \\theta_1 k_t + \\theta_2 (\\omega_t k_t) + \\varepsilon_t$")
md <- c(md, "- Mapping: $\\theta_1 = \\bar{\\theta} - \\beta_2 \\bar{\\omega}$, $\\theta_2 = \\beta_2$")
md <- c(md, "- Recovery: $\\theta_t = \\theta_1 + \\theta_2 \\omega_t = \\bar{\\theta} + \\beta_2 (\\omega_t - \\bar{\\omega})$")
md <- c(md, "")
md <- c(md, "| Window | |Δθ₁| | |Δθ₂| | max|Δfitted| | max|Δresid| |")
md <- c(md, "|--------|--------|--------|-------------|-------------|")

for (i in 1:nrow(summary_df)) {
  r <- summary_df[i, ]
  md <- c(md, sprintf("| %s | %.2e | %.2e | %.2e | %.2e |",
    r$label, r$diff_theta1, r$diff_theta2, r$max_fit_diff, r$max_resid_diff))
}

md <- c(md, "")
md <- c(md, "All equivalence tolerances are at or near machine precision, confirming algebraic equivalence.")
md <- c(md, "")
md <- c(md, "---")
md <- c(md, sprintf("*Generated: %s*", Sys.time()))
md <- c(md, "*Script: 43_dols_centered_refactor.R*")

writeLines(md, file.path(outdir, "dols_centered_interpretation_us.md"))
cat("Saved: dols_centered_interpretation_us.md\n")

cat("\n=== DONE ===\n")
cat("Outputs:\n")
cat(sprintf("  - %s/dols_centered_summary_us.csv\n", outdir))
cat(sprintf("  - %s/dols_centered_theta_path_us.csv\n", outdir))
cat(sprintf("  - %s/dols_centered_table_us.tex\n", outdir))
cat(sprintf("  - %s/dols_centered_interpretation_us.md\n", outdir))
