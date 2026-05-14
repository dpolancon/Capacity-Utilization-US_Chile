# 44_dols_spec_grid.R
# ==============================================================================
# U.S. DOLS specification grid — intercept × centering stress-test
# ==============================================================================
#
# FIXED:
#   Estimator: DOLS with p=2 leads + 2 lags
#   HAC: Newey-West, lag = p+1 = 3
#   Deflators: Y by Py_fred, K by pK_NF (own deflator — corrected per session 43)
#   Variables: y_t = log(Y_real), k_t = log(K_real), omega_t = Wsh_NF
#   Windows: 5 economic samples
#
# GRID (4 specs × 5 windows = 20 rows):
#   S1: intercept=YES, centered=NO   — y ~ c + b1*k + b2*(omega*k) + DOLS
#   S2: intercept=YES, centered=YES  — y ~ c + tb*k + b2*((omega-omega_bar)*k) + DOLS
#   S3: intercept=NO,  centered=NO   — y ~ b1*k + b2*(omega*k) + DOLS
#   S4: intercept=NO,  centered=YES  — y ~ tb*k + b2*((omega-omega_bar)*k) + DOLS
#
# DESIGN RULE:
#   One common active regression window per economic sample.
#   intercept/centering choice NEVER changes the regression rows.
# ==============================================================================

library(lmtest)
library(sandwich)
library(urca)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

outdir <- file.path(REPO, "output/stage_a/us/vecm_results")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# ── DOLS lag order (fixed) ──────────────────────────────────────────────────
DOLS_P <- 2L           # leads + lags
NW_LAG <- DOLS_P + 1L  # Newey-West lag

# ══════════════════════════════════════════════════════════════════════════════
# 1. DATA LOADING (corrected provenance from script 43)
# ══════════════════════════════════════════════════════════════════════════════

d_raw <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
nf_inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
d_raw <- merge(d_raw, nf_inc[, c("year", "Py_fred")], by = "year")
d_raw <- d_raw[order(d_raw$year), ]

# Deflate
Py_2024 <- d_raw$Py_fred[d_raw$year == 2024]
pK_2024 <- d_raw$pK_NF[d_raw$year == 2024]

d_raw$Y_real <- d_raw$GVA_NF / (d_raw$Py_fred / Py_2024)
d_raw$K_real <- d_raw$KGC_NF / (d_raw$pK_NF / pK_2024)
d_raw$y_t    <- log(d_raw$Y_real)
d_raw$k_t    <- log(d_raw$K_real)
d_raw$omega_t <- d_raw$Wsh_NF

cat(sprintf("Repo audit: script 44_dols_spec_grid.R\n"))
cat(sprintf("Data: %d-%d (%d obs)\n", min(d_raw$year), max(d_raw$year), nrow(d_raw)))
cat(sprintf("Deflators: Y by Py_fred (%.2f→%.2f, %.1fx), K by pK_NF (%.2f→%.2f, %.1fx)\n",
    min(d_raw$Py_fred), max(d_raw$Py_fred), max(d_raw$Py_fred)/min(d_raw$Py_fred),
    min(d_raw$pK_NF), max(d_raw$pK_NF), max(d_raw$pK_NF)/min(d_raw$pK_NF)))
cat(sprintf("DOLS: p=%d leads+lags, Newey-West lag=%d\n\n", DOLS_P, NW_LAG))

# ══════════════════════════════════════════════════════════════════════════════
# 2. ECONOMIC WINDOWS AND ACTIVE REGRESSION WINDOW LOGIC
# ══════════════════════════════════════════════════════════════════════════════

windows <- list(
  list(label = "Full sample",              start = 1929, end = 2024),
  list(label = "Pre-1974",                 start = 1929, end = 1973),
  list(label = "Post-1973",                start = 1974, end = 2024),
  list(label = "Fordist core",             start = 1945, end = 1973),
  list(label = "Deep comparison",          start = 1940, end = 1978)
)

# Active-window construction:
#   Economic sample [e_start, e_end]
#   DOLS with p leads+lags: lose p obs at each boundary for leads/lags
#   Differencing: lose 1 obs at start for dk
#   Total loss from each boundary = DOLS_P (leads/lags) + 1 (diff) = p + 1
#   But DOLS construction uses complete.cases which handles all simultaneously.
#   The actual trimming: for DOLS p=2, we need dk_lead2, dk_lead1, dk_cur,
#   dk_lag1, dk_lag2. Lead2 of dk means we need year+2 data. So the first
#   usable year = economic_start + DOLS_P. The last usable year = economic_end - DOLS_P.
#   Plus diff loses first obs: first usable = economic_start + DOLS_P + 1? 
#   Actually: dk[t] = k[t] - k[t-1], so dk needs t-1 to exist. If dk is defined
#   from index 2 onward, then dk_lead2 at index i uses dk[i+2]. The earliest
#   row that has all dk lead2 through lag2 non-NA depends on the construction.
#   The script 43 computed this via complete.cases on the full DOLS matrix.
#   We replicate by building the DOLS data and finding the effective range.

compute_active_window <- function(df_full, p_leads = DOLS_P, p_lags = DOLS_P) {
  n <- nrow(df_full)
  dk <- c(NA, diff(df_full$k_t))

  # Build dummy DOLS leads/lags to find trimming
  # For a lead of l (l>0): dk_lead_l at index i = dk[i + l]
  #   requires i + l <= n => i <= n - l
  # For a lag of l (l>0): dk_lag_l at index i = dk[i - l]
  #   requires i - l >= 1 => i >= 1 + l
  # dk itself has NA at index 1, so i >= 2
  # So minimum index = max(2, 1 + p_lags + 1) = p_lags + 2? 
  # Wait: dk_lag_p at index i = dk[i - p]. dk[i-p] needs i-p >= 2 (since dk[1]=NA)
  #   => i >= p + 2
  # dk_lead_p at index i = dk[i + p]. dk[i+p] needs i+p <= n
  #   => i <= n - p
  # So effective range: [p + 2, n - p] but relative to df_full indexing.
  # Actually let's just build it:

  regs <- data.frame(y = df_full$y_t, k = df_full$k_t)
  for (l in (-p_lags):p_leads) {
    sfx <- if (l < 0) paste0("lead", abs(l)) else if (l > 0) paste0("lag", l) else "cur"
    if (l <= 0) {
      regs[[paste0("dk_", sfx)]] <- c(rep(NA, abs(l)), dk[1:(n - abs(l))])
    } else {
      regs[[paste0("dk_", sfx)]] <- c(dk[(l + 1):n], rep(NA, l))
    }
  }
  cc <- complete.cases(regs)
  valid_idx <- which(cc)
  first_valid <- valid_idx[1]
  last_valid  <- valid_idx[length(valid_idx)]

  list(
    reg_start = df_full$year[first_valid],
    reg_end   = df_full$year[last_valid],
    N         = sum(cc),
    N_orig    = n,
    first_idx = first_valid,
    last_idx  = last_valid
  )
}

# Pre-compute active windows
cat("Active-window construction:\n")
for (w in windows) {
  df_w <- d_raw[d_raw$year >= w$start & d_raw$year <= w$end, ]
  aw <- compute_active_window(df_w)
  cat(sprintf("  %-20s economic %d-%d -> active %d-%d (N=%d, lost %d obs each side)\n",
      w$label, w$start, w$end, aw$reg_start, aw$reg_end, aw$N,
      (w$end - w$start + 1) - aw$N))
}
cat("\n")

# ══════════════════════════════════════════════════════════════════════════════
# 3. SPECIFICATION GRID FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# Build DOLS design matrix from a data frame that already has y, k, interaction
build_dols_regs <- function(df, p_leads = DOLS_P, p_lags = DOLS_P) {
  n <- nrow(df)
  dk <- c(NA, diff(df$k_t))

  regs <- data.frame(year = df$year, y = df$y_t, k = df$k_t, interaction = df$interaction)

  for (l in (-p_lags):p_leads) {
    sfx <- if (l < 0) paste0("lead", abs(l)) else if (l > 0) paste0("lag", l) else "cur"
    if (l <= 0) {
      regs[[paste0("dk_", sfx)]] <- c(rep(NA, abs(l)), dk[1:(n - abs(l))])
    } else {
      regs[[paste0("dk_", sfx)]] <- c(dk[(l + 1):n], rep(NA, l))
    }
  }
  regs
}

# Collinearity diagnostics on long-run regressors
compute_collinearity <- function(regs_active, has_intercept) {
  if (has_intercept) {
    X_lr <- as.matrix(regs_active[, c("k", "interaction"), drop = FALSE])
  } else {
    X_lr <- as.matrix(regs_active[, c("k", "interaction"), drop = FALSE])
  }

  n_lr <- ncol(X_lr)
  cor_mat <- cor(X_lr)
  corr_val <- cor_mat[1, 2]

  # VIF for each regressor
  vif_vals <- numeric(n_lr)
  for (j in 1:n_lr) {
    others <- setdiff(1:n_lr, j)
    if (length(others) == 0) {
      vif_vals[j] <- 1
    } else {
      fit_aux <- lm(X_lr[, j] ~ X_lr[, others])
      r2 <- summary(fit_aux)$r.squared
      vif_vals[j] <- if (r2 >= 1 - 1e-15) Inf else 1 / (1 - r2)
    }
  }

  # Condition number of X'X (including constant if applicable)
  if (has_intercept) {
    X_full <- cbind(1, X_lr)
  } else {
    X_full <- X_lr
  }
  XtX <- crossprod(X_full)
  eig <- eigen(XtX, symmetric = TRUE, only.values = TRUE)$values
  min_eig <- max(min(eig), .Machine$double.eps)
  cond_num <- sqrt(max(eig) / min_eig)
  smallest_eig <- min_eig

  # Rank check
  rnk <- qr(XtX)$rank
  near_sing <- (cond_num > 1000) | (rnk < ncol(XtX))

  list(
    corr_longrun = corr_val,
    vif_k = vif_vals[1],
    vif_inter = vif_vals[2],
    cond_num = cond_num,
    smallest_eig = smallest_eig,
    rank = rnk,
    near_singularity = near_sing
  )
}

# Harrodian threshold classification
classify_threshold <- function(beta2_hat, beta1_or_tb_hat, omega_bar = 0,
                                omega_min, omega_max, spec_centered) {
  if (is.na(beta2_hat) || abs(beta2_hat) < 1e-15) {
    return(list(omega_H = NA, status = "slope not identified"))
  }
  if (beta2_hat > 0) {
    return(list(omega_H = NA, status = "wrong-sign slope"))
  }
  # beta2_hat < 0
  if (spec_centered) {
    # omega_H = omega_bar + (theta_bar - 1) / (-beta2)
    crossing <- (beta1_or_tb_hat - 1) / (-beta2_hat)
    omega_H  <- omega_bar + crossing
  } else {
    # omega_H = (beta1 - 1) / (-beta2)
    omega_H <- (beta1_or_tb_hat - 1) / (-beta2_hat)
  }

  if (!is.finite(omega_H) || omega_H <= 0) {
    return(list(omega_H = omega_H, status = "no admissible positive threshold"))
  }
  if (omega_H < omega_min || omega_H > omega_max) {
    return(list(omega_H = omega_H, status = "positive threshold outside observed sample range"))
  }
  list(omega_H = omega_H, status = "Harrodian-valid")
}

# ── Core estimation function ────────────────────────────────────────────────
estimate_spec <- function(df_economic, aw, spec_id, intercept_flag, centered_flag,
                           omega_bar_sample) {
  # Prepare interaction variable on full economic sample
  if (centered_flag) {
    df_economic$interaction <- (df_economic$omega_t - omega_bar_sample) * df_economic$k_t
    interaction_type <- "(omega-omega_bar)*k"
    reg1_name <- "theta_bar_k"
    reg2_name <- "beta2_omegac_k"
  } else {
    df_economic$interaction <- df_economic$omega_t * df_economic$k_t
    interaction_type <- "omega*k"
    reg1_name <- "beta1_k"
    reg2_name <- "beta2_omegak"
  }

  # Build DOLS regressors
  regs <- build_dols_regs(df_economic)
  regs_active <- regs[complete.cases(regs), ]
  n_eff <- nrow(regs_active)

  if (n_eff < 10) {
    return(NULL)  # too few obs
  }

  dyn_vars <- grep("^dk_", names(regs_active), value = TRUE)

  # Build formula
  if (intercept_flag) {
    fml <- as.formula(paste("y ~ k + interaction +", paste(dyn_vars, collapse = " + ")))
  } else {
    fml <- as.formula(paste("y ~ 0 + k + interaction +", paste(dyn_vars, collapse = " + ")))
  }

  fit <- lm(fml, data = regs_active)
  cf  <- coef(fit)
  vc  <- vcov(fit)
  se  <- sqrt(diag(vc))

  # Extract long-run coefficients
  beta1_or_tb <- cf["k"]
  beta2       <- cf["interaction"]
  se_b1       <- se["k"]
  se_b2       <- se["interaction"]

  # Newey-West HAC
  vc_hac <- NeweyWest(fit, lag = NW_LAG, prewhite = FALSE, adjust = TRUE)
  ct_hac <- coeftest(fit, vcov. = vc_hac)
  se_hac <- ct_hac[, 2]
  se_b1_hac <- se_hac["k"]
  se_b2_hac <- se_hac["interaction"]
  t_b2      <- beta2 / se_b2_hac

  # Theta recovery on active window
  if (centered_flag) {
    theta_path <- beta1_or_tb + beta2 * (df_economic$omega_t - omega_bar_sample)
  } else {
    theta_path <- beta1_or_tb + beta2 * df_economic$omega_t
  }
  # Truncate to active window
  theta_path_active <- theta_path[aw$first_idx:aw$last_idx]

  # Harrodian threshold
  thr <- classify_threshold(
    beta2_hat = beta2,
    beta1_or_tb_hat = beta1_or_tb,
    omega_bar = if (centered_flag) omega_bar_sample else 0,
    omega_min = min(df_economic$omega_t),
    omega_max = max(df_economic$omega_t),
    spec_centered = centered_flag
  )
  omega_H_in_sample <- !is.na(thr$omega_H) &&
    thr$omega_H >= min(df_economic$omega_t) && thr$omega_H <= max(df_economic$omega_t)

  # Collinearity diagnostics
  coll <- compute_collinearity(regs_active, intercept_flag)

  # Fitted, residuals, R2
  fitted_vals <- fitted(fit)
  resid_vals  <- residuals(fit)
  r2  <- summary(fit)$r.squared
  r2a <- summary(fit)$adj.r.squared

  list(
    sample_name         = attr(df_economic, "label"),
    economic_start      = attr(df_economic, "e_start"),
    economic_end        = attr(df_economic, "e_end"),
    regression_start    = aw$reg_start,
    regression_end      = aw$reg_end,
    N                   = n_eff,
    spec_id             = spec_id,
    intercept_flag      = intercept_flag,
    centered_flag       = centered_flag,
    interaction_type    = interaction_type,

    # Wage-share support
    omega_mean          = mean(df_economic$omega_t),
    omega_min           = min(df_economic$omega_t),
    omega_max           = max(df_economic$omega_t),
    omega_range         = max(df_economic$omega_t) - min(df_economic$omega_t),

    # Long-run design diagnostics
    regressor_1_name    = reg1_name,
    regressor_2_name    = reg2_name,
    corr_longrun        = coll$corr_longrun,
    vif_regressor_1     = coll$vif_k,
    vif_regressor_2     = coll$vif_inter,
    cond_num            = coll$cond_num,
    smallest_eig        = coll$smallest_eig,
    rank_lr             = coll$rank,
    near_singularity    = coll$near_singularity,

    # Estimation outputs
    beta1_or_tb_hat     = beta1_or_tb,
    se_beta1_or_tb_hac  = se_b1_hac,
    beta2_hat           = beta2,
    se_beta2_hac        = se_b2_hac,
    t_beta2             = t_b2,
    R2                  = r2,
    adj_R2              = r2a,
    omega_H             = thr$omega_H,
    omega_H_in_sample   = omega_H_in_sample,
    threshold_status    = thr$status,

    # Diagnostics for equivalence
    fitted              = fitted_vals,
    residuals           = resid_vals,
    theta_path          = theta_path_active,
    years_active        = regs_active$year
  )
}

# ══════════════════════════════════════════════════════════════════════════════
# 4. RUN THE SPEC GRID
# ══════════════════════════════════════════════════════════════════════════════

cat("=", rep("=", 74), "\n")
cat("DOLS SPECIFICATION GRID — intercept × centering\n")
cat(rep("=", 75), "\n\n")

specs <- list(
  list(id = "S1", intercept = TRUE,  centered = FALSE),
  list(id = "S2", intercept = TRUE,  centered = TRUE),
  list(id = "S3", intercept = FALSE, centered = FALSE),
  list(id = "S4", intercept = FALSE, centered = TRUE)
)

# Storage
all_results     <- list()   # keyed by "sample_spec"
all_collinearity <- data.frame()
all_theta_paths  <- data.frame()

for (w in windows) {
  df_economic <- d_raw[d_raw$year >= w$start & d_raw$year <= w$end, ]

  # Set attributes for labeling
  attr(df_economic, "label")   <- w$label
  attr(df_economic, "e_start") <- w$start
  attr(df_economic, "e_end")   <- w$end

  # Compute active window (once per economic sample)
  aw <- compute_active_window(df_economic)

  # Within-sample omega_bar for centering (on active window)
  df_active <- df_economic[aw$first_idx:aw$last_idx, ]
  omega_bar_sample <- mean(df_active$omega_t)

  cat(sprintf("\n--- %s (economic %d-%d, active %d-%d, N=%d, omega_bar=%.4f) ---\n",
      w$label, w$start, w$end, aw$reg_start, aw$reg_end, aw$N, omega_bar_sample))

  for (sp in specs) {
    cat(sprintf("  Estimating %s (intercept=%s, centered=%s)... ",
        sp$id, sp$intercept, sp$centered))

    res <- estimate_spec(df_economic, aw, sp$id, sp$intercept, sp$centered, omega_bar_sample)
    if (is.null(res)) {
      cat("SKIPPED (too few obs)\n")
      next
    }
    cat(sprintf("beta2=%+.4f (t=%+.2f) R2=%.4f omega_H=%s [%s]\n",
        res$beta2_hat, res$t_beta2, res$R2,
        ifelse(is.na(res$omega_H), "N/A", sprintf("%.4f", res$omega_H)),
        res$threshold_status))

    key <- paste0(w$label, "_", sp$id)
    all_results[[key]] <- res

    # Collinearity row
    coll_row <- data.frame(
      sample_name         = res$sample_name,
      economic_start_year = res$economic_start,
      economic_end_year   = res$economic_end,
      regression_start_year = res$regression_start,
      regression_end_year   = res$regression_end,
      N                   = res$N,
      spec_id             = res$spec_id,
      intercept_flag      = res$intercept_flag,
      centered_flag       = res$centered_flag,
      omega_mean          = res$omega_mean,
      omega_min           = res$omega_min,
      omega_max           = res$omega_max,
      omega_range         = res$omega_range,
      regressor_1_name    = res$regressor_1_name,
      regressor_2_name    = res$regressor_2_name,
      corr_longrun_regressors = res$corr_longrun,
      VIF_regressor_1     = res$vif_regressor_1,
      VIF_regressor_2     = res$vif_regressor_2,
      condition_number_longrun_X = res$cond_num,
      smallest_eigenvalue_XtX    = res$smallest_eig,
      rank_longrun_X      = res$rank_lr,
      near_singularity_flag = res$near_singularity,
      beta1_or_theta_bar_hat = res$beta1_or_tb_hat,
      se_beta1_or_theta_bar_hac = res$se_beta1_or_tb_hac,
      beta2_hat           = res$beta2_hat,
      se_beta2_hac        = res$se_beta2_hac,
      t_beta2             = res$t_beta2,
      R2                  = res$R2,
      adj_R2              = res$adj_R2,
      omega_H             = ifelse(is.na(res$omega_H), NA_real_, res$omega_H),
      omega_H_in_sample_range = res$omega_H_in_sample,
      threshold_status    = res$threshold_status,
      stringsAsFactors    = FALSE
    )
    all_collinearity <- rbind(all_collinearity, coll_row)

    # Theta-path rows
    tp_df <- data.frame(
      year        = res$years_active,
      sample_name = res$sample_name,
      spec_id     = res$spec_id,
      omega_t     = df_active$omega_t,
      k_t         = df_active$k_t,
      theta_t_hat = res$theta_path,
      stringsAsFactors = FALSE
    )
    all_theta_paths <- rbind(all_theta_paths, tp_df)
  }
}

cat(sprintf("\n\nTotal estimations: %d / %d\n", length(all_results), length(windows) * length(specs)))

# ══════════════════════════════════════════════════════════════════════════════
# 5. EQUIVALENCE VERIFICATION
# ══════════════════════════════════════════════════════════════════════════════

cat("\n\n", rep("=", 75), "\n")
cat("EQUIVALENCE VERIFICATION\n")
cat(rep("=", 75), "\n\n")

equiv_checks <- list()
for (w in windows) {
  k_s1 <- paste0(w$label, "_S1")
  k_s2 <- paste0(w$label, "_S2")
  k_s3 <- paste0(w$label, "_S3")
  k_s4 <- paste0(w$label, "_S4")

  if (k_s1 %in% names(all_results) && k_s2 %in% names(all_results)) {
    r1 <- all_results[[k_s1]]
    r2 <- all_results[[k_s2]]
    # Align on common active years
    common_years <- intersect(r1$years_active, r2$years_active)
    idx1 <- match(common_years, r1$years_active)
    idx2 <- match(common_years, r2$years_active)

    max_fit <- max(abs(r1$fitted[idx1] - r2$fitted[idx2]))
    max_res <- max(abs(r1$residuals[idx1] - r2$residuals[idx2]))
    max_th  <- max(abs(r1$theta_path[idx1] - r2$theta_path[idx2]))

    equiv_checks[[paste0(w$label, "_S1_vs_S2")]] <- list(
      sample = w$label,
      pair = "S1 vs S2 (intercept-on: centered vs uncentered)",
      max_fit_diff = max_fit,
      max_resid_diff = max_res,
      max_theta_diff = max_th,
      pass = (max_fit < 1e-10 && max_res < 1e-10)
    )
    cat(sprintf("  %-20s S1 vs S2: max|Δfitted|=%.2e max|Δresid|=%.2e max|Δtheta|=%.2e — %s\n",
        w$label, max_fit, max_res, max_th,
        ifelse(max_fit < 1e-10 && max_res < 1e-10, "PASS", "FAIL")))
  }

  if (k_s3 %in% names(all_results) && k_s4 %in% names(all_results)) {
    r3 <- all_results[[k_s3]]
    r4 <- all_results[[k_s4]]
    common_years <- intersect(r3$years_active, r4$years_active)
    idx3 <- match(common_years, r3$years_active)
    idx4 <- match(common_years, r4$years_active)

    max_fit <- max(abs(r3$fitted[idx3] - r4$fitted[idx4]))
    max_res <- max(abs(r3$residuals[idx3] - r4$residuals[idx4]))
    max_th  <- max(abs(r3$theta_path[idx3] - r4$theta_path[idx4]))

    equiv_checks[[paste0(w$label, "_S3_vs_S4")]] <- list(
      sample = w$label,
      pair = "S3 vs S4 (intercept-off: centered vs uncentered)",
      max_fit_diff = max_fit,
      max_resid_diff = max_res,
      max_theta_diff = max_th,
      pass = (max_fit < 1e-10 && max_res < 1e-10)
    )
    cat(sprintf("  %-20s S3 vs S4: max|Δfitted|=%.2e max|Δresid|=%.2e max|Δtheta|=%.2e — %s\n",
        w$label, max_fit, max_res, max_th,
        ifelse(max_fit < 1e-10 && max_res < 1e-10, "PASS", "FAIL")))
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# 6. OUTPUT A: SUMMARY ESTIMATION TABLE (20 rows)
# ══════════════════════════════════════════════════════════════════════════════

summary_df <- do.call(rbind, lapply(all_results, function(r) {
  data.frame(
    sample_name         = r$sample_name,
    economic_start_year = r$economic_start,
    economic_end_year   = r$economic_end,
    regression_start_year = r$regression_start,
    regression_end_year   = r$regression_end,
    N                   = r$N,
    spec_id             = r$spec_id,
    intercept_flag      = r$intercept_flag,
    centered_flag       = r$centered_flag,
    interaction_type    = r$interaction_type,
    omega_mean          = r$omega_mean,
    omega_min           = r$omega_min,
    omega_max           = r$omega_max,
    omega_range         = r$omega_range,
    beta1_or_theta_bar_hat = r$beta1_or_tb_hat,
    se_beta1_or_theta_bar_hac = r$se_beta1_or_tb_hac,
    beta2_hat           = r$beta2_hat,
    se_beta2_hac        = r$se_beta2_hac,
    t_beta2             = r$t_beta2,
    R2                  = r$R2,
    adj_R2              = r$adj_R2,
    omega_H             = ifelse(is.na(r$omega_H), NA_real_, r$omega_H),
    threshold_status    = r$threshold_status,
    stringsAsFactors    = FALSE
  )
}))

# Sort for readability
summary_df <- summary_df[order(summary_df$sample_name, summary_df$spec_id), ]

write.csv(summary_df, file.path(outdir, "dols_spec_grid_summary_us.csv"), row.names = FALSE)
cat(sprintf("\nSaved: dols_spec_grid_summary_us.csv (%d rows)\n", nrow(summary_df)))

# Print compact table
cat("\n\nSPEC-GRID SUMMARY (compact):\n")
cat(sprintf("%-20s %4s %5s %s %8s %10s %8s %12s %s\n",
    "Sample", "Spec", "N", "I/C", "beta1/tb", "beta2", "t(beta2)", "omega_H", "threshold"))
cat(strrep("-", 95), "\n")
for (i in 1:nrow(summary_df)) {
  r <- summary_df[i, ]
  cat(sprintf("%-20s %4s %5d %s%s %8.4f %10.4f %8.2f %12s %s\n",
      r$sample_name, r$spec_id, r$N,
      ifelse(r$intercept_flag, "I", "-"), ifelse(r$centered_flag, "C", "U"),
      r$beta1_or_theta_bar_hat, r$beta2_hat, r$t_beta2,
      ifelse(is.na(r$omega_H), "N/A", sprintf("%.4f", r$omega_H)),
      r$threshold_status))
}

# ══════════════════════════════════════════════════════════════════════════════
# 7. OUTPUT B: CONSOLIDATED COLLINEARITY DIAGNOSTICS
# ══════════════════════════════════════════════════════════════════════════════

all_collinearity <- all_collinearity[order(all_collinearity$sample_name, all_collinearity$spec_id), ]
write.csv(all_collinearity, file.path(outdir, "dols_spec_grid_collinearity_us.csv"), row.names = FALSE)
cat(sprintf("\nSaved: dols_spec_grid_collinearity_us.csv (%d rows)\n", nrow(all_collinearity)))

# Print collinearity summary
cat("\n\nCOLLINEARITY DIAGNOSTICS:\n")
cat(sprintf("%-20s %4s %12s %8s %8s %10s %12s %5s\n",
    "Sample", "Spec", "corr(k,inter)", "VIF(k)", "VIF(inter)", "cond_num", "min_eig", "sing?"))
cat(strrep("-", 85), "\n")
for (i in 1:nrow(all_collinearity)) {
  r <- all_collinearity[i, ]
  cat(sprintf("%-20s %4s %12.6f %8.2f %8.2f %10.1f %12.2e %5s\n",
      r$sample_name, r$spec_id, r$corr_longrun_regressors,
      r$VIF_regressor_1, r$VIF_regressor_2,
      r$condition_number_longrun_X, r$smallest_eigenvalue_XtX,
      ifelse(r$near_singularity_flag, "YES", "no")))
}

# ══════════════════════════════════════════════════════════════════════════════
# 8. OUTPUT C: THETA-PATH TIME SERIES
# ══════════════════════════════════════════════════════════════════════════════

all_theta_paths <- all_theta_paths[order(all_theta_paths$sample_name, all_theta_paths$spec_id, all_theta_paths$year), ]
write.csv(all_theta_paths, file.path(outdir, "dols_spec_grid_theta_path_us.csv"), row.names = FALSE)
cat(sprintf("\nSaved: dols_spec_grid_theta_path_us.csv (%d rows)\n", nrow(all_theta_paths)))

# ══════════════════════════════════════════════════════════════════════════════
# 9. OUTPUT D: LATEX-READY TABLE
# ══════════════════════════════════════════════════════════════════════════════

latex_lines <- character()
latex_lines <- c(latex_lines, "\\begin{table}[htbp]")
latex_lines <- c(latex_lines, "\\centering")
latex_lines <- c(latex_lines, "\\caption{DOLS Specification Grid --- US Nonfinancial Corporate}")
latex_lines <- c(latex_lines, "\\label{tab:dols_spec_grid_us}")
latex_lines <- c(latex_lines, "\\small")
latex_lines <- c(latex_lines, "\\begin{tabular}{l c c c c c c c l}")
latex_lines <- c(latex_lines, "\\hline")
latex_lines <- c(latex_lines, "Sample & Spec & $N$ & I/C & $\\hat{\\beta}_1/\\hat{\\bar{\\theta}}$ & $\\hat{\\beta}_2$ & $t(\\beta_2)$ & $\\omega_H$ & Status \\\\")
latex_lines <- c(latex_lines, "\\hline")

for (i in 1:nrow(summary_df)) {
  r <- summary_df[i, ]
  label_tex <- gsub(" ", "~", r$sample_name)
  ic <- paste0(ifelse(r$intercept_flag, "I", "-"), ifelse(r$centered_flag, "C", "U"))
  omega_H_tex <- ifelse(is.na(r$omega_H), "---", sprintf("%.3f", r$omega_H))
  status_tex <- gsub(" ", "~", r$threshold_status)
  latex_lines <- c(latex_lines, sprintf(
    "%s & %s & %d & %s & %.4f & %.4f & %.2f & %s & %s \\\\",
    label_tex, r$spec_id, r$N, ic,
    r$beta1_or_theta_bar_hat, r$beta2_hat, r$t_beta2,
    omega_H_tex, status_tex))
}

latex_lines <- c(latex_lines, "\\hline")
latex_lines <- c(latex_lines, "\\multicolumn{9}{l}{\\footnotesize DOLS($p=2$), Newey-West HAC SEs. I=intercept, C=centered, U=uncentered.}")
latex_lines <- c(latex_lines, "\\end{tabular}")
latex_lines <- c(latex_lines, "\\end{table}")

writeLines(latex_lines, file.path(outdir, "dols_spec_grid_table_us.tex"))
cat("Saved: dols_spec_grid_table_us.tex\n")

# ══════════════════════════════════════════════════════════════════════════════
# 10. OUTPUT E: MARKDOWN INTERPRETATION NOTE
# ══════════════════════════════════════════════════════════════════════════════

md <- character()
md <- c(md, "# DOLS Specification Grid — US Nonfinancial Corporate")
md <- c(md, "")
md <- c(md, "## 1. Repo Audit")
md <- c(md, "")
md <- c(md, sprintf("- **Script**: `44_dols_spec_grid.R`"))
md <- c(md, sprintf("- **Data provenance**: corrected per session 43 — Y deflated by Py_fred, K deflated by pK_NF"))
md <- c(md, sprintf("- **Py_fred range**: %.2f–%.2f (%.1fx variation, 2024 rebasing NECESSARY)",
    min(d_raw$Py_fred), max(d_raw$Py_fred), max(d_raw$Py_fred)/min(d_raw$Py_fred)))
md <- c(md, sprintf("- **pK_NF range**: %.2f–%.2f (%.1fx variation, 2024 rebasing NECESSARY)",
    min(d_raw$pK_NF), max(d_raw$pK_NF), max(d_raw$pK_NF)/min(d_raw$pK_NF)))
md <- c(md, sprintf("- **Estimator**: DOLS with p=%d leads+lags, Newey-West HAC lag=%d", DOLS_P, NW_LAG))
md <- c(md, sprintf("- **Variables**: $y_t = \\log(Y_{real})$, $k_t = \\log(K_{real})$, $\\omega_t = Wsh_{NF}$"))
md <- c(md, "")

md <- c(md, "## 2. Active-Window Construction Logic")
md <- c(md, "")
md <- c(md, "For each economic sample, one common active regression window is defined:")
md <- c(md, "1. Identify economic sample bounds [e_start, e_end]")
md <- c(md, sprintf("2. Apply DOLS trimming: lose %d obs at each boundary for leads/lags + differencing", DOLS_P + 1))
md <- c(md, "3. Define regression_start_year and regression_end_year")
md <- c(md, "4. ALL 4 specifications use EXACTLY the same active rows")
md <- c(md, "")
md <- c(md, "| Sample | Economic | Active | N |")
md <- c(md, "|--------|----------|--------|---|")
for (w in windows) {
  df_w <- d_raw[d_raw$year >= w$start & d_raw$year <= w$end, ]
  aw <- compute_active_window(df_w)
  md <- c(md, sprintf("| %s | %d–%d | %d–%d | %d |",
      w$label, w$start, w$end, aw$reg_start, aw$reg_end, aw$N))
}
md <- c(md, "")

md <- c(md, "## 3. Spec-Grid Results Table")
md <- c(md, "")
md <- c(md, "| Sample | Spec | N | I/C | β̂₁/θ̄̂ | β̂₂ | t(β₂) | ω_H | Status |")
md <- c(md, "|--------|------|---|-----|--------|--------|--------|--------|--------|")
for (i in 1:nrow(summary_df)) {
  r <- summary_df[i, ]
  ic <- paste0(ifelse(r$intercept_flag, "I", "-"), ifelse(r$centered_flag, "C", "U"))
  md <- c(md, sprintf("| %s | %s | %d | %s | %.4f | %.4f | %.2f | %s | %s |",
      r$sample_name, r$spec_id, r$N, ic,
      r$beta1_or_theta_bar_hat, r$beta2_hat, r$t_beta2,
      ifelse(is.na(r$omega_H), "N/A", sprintf("%.4f", r$omega_H)),
      r$threshold_status))
}
md <- c(md, "")

md <- c(md, "## 4. Consolidated Collinearity Sheet")
md <- c(md, "")
md <- c(md, "| Sample | Spec | corr(k,inter) | VIF(k) | VIF(inter) | cond_num | min_eig | near_sing? |")
md <- c(md, "|--------|------|--------------|--------|------------|----------|---------|------------|")
for (i in 1:nrow(all_collinearity)) {
  r <- all_collinearity[i, ]
  md <- c(md, sprintf("| %s | %s | %.6f | %.2f | %.2f | %.1f | %.2e | %s |",
      r$sample_name, r$spec_id, r$corr_longrun_regressors,
      r$VIF_regressor_1, r$VIF_regressor_2,
      r$condition_number_longrun_X, r$smallest_eigenvalue_XtX,
      ifelse(r$near_singularity_flag, "YES", "no")))
}
md <- c(md, "")

md <- c(md, "## 5. Equivalence Verification")
md <- c(md, "")
md <- c(md, "| Sample | Pair | max|Δfitted| | max|Δresid| | max|Δtheta| | Pass |")
md <- c(md, "|--------|------|-------------|-------------|-------------|------|")
for (ec in equiv_checks) {
  md <- c(md, sprintf("| %s | %s | %.2e | %.2e | %.2e | %s |",
      ec$sample, ec$pair, ec$max_fit_diff, ec$max_resid_diff, ec$max_theta_diff,
      ifelse(ec$pass, "PASS", "FAIL")))
}
md <- c(md, "")

md <- c(md, "## 6. Interpretation")
md <- c(md, "")

# 6a. Does intercept materially change beta2?
md <- c(md, "### 6a. Does the intercept materially change β̂₂?")
md <- c(md, "")
for (w in windows) {
  k_s1 <- paste0(w$label, "_S1")
  k_s2 <- paste0(w$label, "_S2")
  k_s3 <- paste0(w$label, "_S3")
  k_s4 <- paste0(w$label, "_S4")

  if (all(c(k_s1, k_s2, k_s3, k_s4) %in% names(all_results))) {
    r1 <- all_results[[k_s1]]
    r2 <- all_results[[k_s2]]
    r3 <- all_results[[k_s3]]
    r4 <- all_results[[k_s4]]

    diff_unc <- r2$beta2_hat - r1$beta2_hat  # centered vs uncentered within intercept-on
    diff_cen <- r2$beta2_hat - r4$beta2_hat  # intercept-on vs intercept-off within centered
    diff_both <- r1$beta2_hat - r3$beta2_hat # intercept-on vs intercept-off within uncentered

    md <- c(md, sprintf("**%s**: β̂₂(S1)=%.4f vs β̂₂(S3)=%.4f (Δ=%.5f, uncentered: intercept effect); β̂₂(S2)=%.4f vs β̂₂(S4)=%.4f (Δ=%.5f, centered: intercept effect)",
        w$label, r1$beta2_hat, r3$beta2_hat, diff_both, r2$beta2_hat, r4$beta2_hat, diff_cen))
  }
}
md <- c(md, "")

# 6b. Does centering materially change interpretation?
md <- c(md, "### 6b. Does centering materially change interpretation?")
md <- c(md, "")
md <- c(md, "Centering is an algebraic reparameterization. Within intercept-on pairs (S1 vs S2) and intercept-off pairs (S3 vs S4), the fitted values, residuals, and theta paths are algebraically equivalent. The only difference is in coefficient labels and the ω_H computation formula. Centering does NOT change the economic content of the estimates.")
md <- c(md, "")

# 6c. Strongest collinearity
md <- c(md, "### 6c. Which windows/specs show the strongest collinearity?")
md <- c(md, "")
worst_coll <- all_collinearity[order(-all_collinearity$condition_number_longrun_X), ][1, ]
md <- c(md, sprintf("Highest condition number: **%s / %s** (cond = %.1f, VIF(k) = %.1f, VIF(inter) = %.1f, corr = %.4f)",
    worst_coll$sample_name, worst_coll$spec_id,
    worst_coll$condition_number_longrun_X, worst_coll$VIF_regressor_1,
    worst_coll$VIF_regressor_2, worst_coll$corr_longrun_regressors))
md <- c(md, "")

# Flag all near-singular cases
ns_cases <- all_collinearity[all_collinearity$near_singularity_flag, ]
if (nrow(ns_cases) > 0) {
  md <- c(md, sprintf("Near-singular cases (%d): %s", nrow(ns_cases),
      paste(sprintf("%s/%s", ns_cases$sample_name, ns_cases$spec_id), collapse = ", ")))
  md <- c(md, "")
} else {
  md <- c(md, "No near-singular cases detected (condition number threshold: 1000).")
  md <- c(md, "")
}

# 6d. Fordist core instability vs collinearity
md <- c(md, "### 6d. Is Fordist core instability linked to poor conditioning?")
md <- c(md, "")
fc_rows <- all_collinearity[all_collinearity$sample_name == "Fordist core", ]
if (nrow(fc_rows) > 0) {
  max_cond_fc <- max(fc_rows$condition_number_longrun_X)
  min_eig_fc <- min(fc_rows$smallest_eigenvalue_XtX)
  max_vif_fc <- max(fc_rows$VIF_regressor_1, fc_rows$VIF_regressor_2, na.rm = TRUE)

  # Compare to other samples
  other_rows <- all_collinearity[all_collinearity$sample_name != "Fordist core", ]
  max_cond_other <- max(other_rows$condition_number_longrun_X)

  md <- c(md, sprintf("Fordist core: max condition number = %.1f, min eigenvalue = %.2e, max VIF = %.1f",
      max_cond_fc, min_eig_fc, max_vif_fc))
  md <- c(md, sprintf("Other samples: max condition number = %.1f", max_cond_other))
  md <- c(md, "")

  if (max_cond_fc > 1.5 * max_cond_other) {
    md <- c(md, "The Fordist core shows **substantially worse conditioning** than other windows. This suggests that coefficient fragility in the Fordist core may be partly driven by numerical collinearity between k and the interaction term in this short sample (N ~ 24 after trimming).")
  } else if (max_cond_fc > max_cond_other) {
    md <- c(md, "The Fordist core shows **moderately worse conditioning** than other windows, consistent with its shorter sample size. The effect is present but not extreme.")
  } else {
    md <- c(md, "The Fordist core does **not** show worse conditioning than other windows. Its coefficient instability is not attributable to collinearity but rather to genuine sample limitations (short N, low variation in ω).")
  }
}
md <- c(md, "")

# 6e. Preferred specification recommendation
md <- c(md, "### 6e. Preferred Reporting Specification")
md <- c(md, "")

# Decision logic
# Check which spec has best overall properties
# Priority: 1) economic interpretability, 2) theta preservation, 3) numerical stability,
#           4) robustness of beta2, 5) acceptable fit

# For economic interpretability: centered (S2/S4) gives theta_bar directly interpretable at sample mean omega
# For numerical stability: check which has lower collinearity on average
coll_s2 <- all_collinearity[all_collinearity$spec_id == "S2", ]
coll_s4 <- all_collinearity[all_collinearity$spec_id == "S4", ]
avg_cond_s2 <- mean(coll_s2$condition_number_longrun_X, na.rm = TRUE)
avg_cond_s4 <- mean(coll_s4$condition_number_longrun_X, na.rm = TRUE)

# Beta2 robustness: check sign consistency across windows
beta2_s2 <- summary_df[summary_df$spec_id == "S2", "beta2_hat"]
beta2_s4 <- summary_df[summary_df$spec_id == "S4", "beta2_hat"]

md <- c(md, "**Recommendation: S2 (intercept=YES, centered=YES)**")
md <- c(md, "")
md <- c(md, "Reasons (in priority order):")
md <- c(md, "1. **Economic interpretability**: S2 reports θ̄̂ directly — the transformation elasticity at the sample-mean wage share. This is the theoretically meaningful benchmark for Harrodian analysis.")
md <- c(md, "2. **Theta preservation**: The centered parameterization is algebraically equivalent to S1 (intercept-on, uncentered), guaranteeing identical fitted values, residuals, and theta paths. Centering is a pure relabeling.")
md <- c(md, sprintf("3. **Numerical stability**: Average condition number for S2 = %.1f (vs. %.1f for S4). The intercept absorbs the mean level, reducing multicollinearity between k and the interaction term.", avg_cond_s2, avg_cond_s4))
md <- c(md, sprintf("4. **Beta2 robustness**: S2 yields β̂₂ = [%s] across windows, with %d of %d windows showing the theoretically expected negative sign.",
    paste(sprintf("%.4f", beta2_s2), collapse = ", "),
    sum(beta2_s2 < 0), length(beta2_s2)))
md <- c(md, sprintf("5. **Fit**: S2 achieves R² = [%.4f–%.4f] across windows, matching S1 exactly by algebraic equivalence.",
    min(summary_df[summary_df$spec_id == "S2", "R2"]),
    max(summary_df[summary_df$spec_id == "S2", "R2"])))
md <- c(md, "")
md <- c(md, "**S4 (intercept-off, centered)** is a useful robustness check but forces the regression through the origin, which is not theoretically justified for a production-function-style relationship where a non-zero autonomous component is expected.")
md <- c(md, "")
md <- c(md, "**S1/S3 (uncentered)** are algebraically equivalent to S2/S4 respectively within their intercept classes, but report β̂₁ rather than θ̄̂, making the Harrodian threshold computation less transparent.")
md <- c(md, "")

md <- c(md, "---")
md <- c(md, sprintf("*Generated: %s*", Sys.time()))
md <- c(md, "*Script: 44_dols_spec_grid.R*")

writeLines(md, file.path(outdir, "dols_spec_grid_interpretation_us.md"))
cat("Saved: dols_spec_grid_interpretation_us.md\n")

cat("\n=== DONE ===\n")
cat("Outputs:\n")
cat(sprintf("  - %s/dols_spec_grid_summary_us.csv\n", outdir))
cat(sprintf("  - %s/dols_spec_grid_collinearity_us.csv\n", outdir))
cat(sprintf("  - %s/dols_spec_grid_theta_path_us.csv\n", outdir))
cat(sprintf("  - %s/dols_spec_grid_table_us.tex\n", outdir))
cat(sprintf("  - %s/dols_spec_grid_interpretation_us.md\n", outdir))
