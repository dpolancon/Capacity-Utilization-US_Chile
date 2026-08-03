#!/usr/bin/env Rscript

# US_S42B_kgt_full_fordist_window_imols.R
#
# S42: re-runs the S41 baseline-vs-extended capital grid with the (c-m)
# demand control extended to 1929 (NIPA T10106, built by S42A). This
# unlocks the full Fordist window 1929-1973 (S41's Fordist cells ran on
# the 1949-1973 effective sample because the FRED control begins 1947).
# With the full window, the WD dummy set (D1933, D1947, WWII block) is
# non-degenerate in Fordism for the first time.
#
# Same 18-cell grid as S41:
#   Capital:  A = k_cap | B = k_cap_GT (GPIM gross) | C = k_cap_GTnet
#   Windows:  Full 1929-2024, Fordism 1929-1973, Post-Fordism 1974-2024
#   Dummies:  ND | WD (steps D1933/D1947/D1974/D2008 + WWII block 1942-45)
#
# Continuity block (disclosed, not asserted): the A/B/C Fordist cells are
# re-estimated on the truncated 1949-1973 sample with the NEW control and
# tabulated against the S41 ledger — separating control-source effects
# from sample-extension effects.
#
# Estimator: IM-OLS (cointReg::cointRegIM) per the E10V lock. The kernel
# "ba" / bandwidth "nw" arguments are the repo inference-layer convention
# only (t-stats, Shin LM, VW statistics); IM-OLS coefficients are
# kernel-invariant. Wrapper copied from US_S41 (originally US_S19).
#
# No gating: stationarity/base-year verdicts from S42A are carried into
# the report's limitations section, not enforced here.
#
# Governance: DIAGNOSTIC branch (S42). No frozen artifact modified.

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(cointReg)
  library(dplyr)
  library(ggplot2)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
ext_csv <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data",
                     "s41_extended_capital_panel.csv")
cm_csv  <- file.path(repo_root, "output", "US", "S42_CM_EXTENSION", "csv",
                     "s42a_extended_cm_control_panel.csv")
s41_ledger_csv <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION",
                            "csv", "s41_estimation_ledger.csv")
out_dir <- file.path(repo_root, "output", "US", "S42_CM_EXTENSION")
csv_dir <- file.path(out_dir, "csv")
fig_dir <- file.path(out_dir, "figs")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

diagnostic_stamp <- "DIAGNOSTIC_ONLY;S42_BRANCH"

cat("========================================================================\n")
cat("S42B: Full-Fordist-window IM-OLS grid with extended (c-m) control\n")
cat("========================================================================\n")

## ==========================================================
## STEP 1: Load panels
## ==========================================================

df <- read.csv(ext_csv, stringsAsFactors = FALSE)
df <- df[!is.na(df$y_t) & !is.na(df$k_cap) &
         !is.na(df$omega_NFC_GVA) & !is.na(df$omega_NFC_GVA_lag1), ]
df <- df[order(df$year), ]

cm_panel <- read.csv(cm_csv, stringsAsFactors = FALSE)
df <- merge(df, cm_panel[, c("year", "cm_t", "cm_lag1")], by = "year",
            all.x = TRUE)

cat(sprintf("Merged panel: %d obs %d-%d; cm control %d-%d\n",
            nrow(df), min(df$year), max(df$year),
            min(df$year[!is.na(df$cm_lag1)]),
            max(df$year[!is.na(df$cm_lag1)])))

df$D1933 <- ifelse(df$year >= 1933, 1, 0)
df$D1947 <- ifelse(df$year >= 1947, 1, 0)
df$D1974 <- ifelse(df$year >= 1974, 1, 0)
df$D2008 <- ifelse(df$year >= 2008, 1, 0)
df$D_WWII <- ifelse(df$year >= 1942 & df$year <= 1945, 1, 0)

windows_list <- list(
  Full_Century_1929_2024          = list(range = c(1929, 2024), label = "Full Sample"),
  Long_Fordist_Era_1929_1973      = list(range = c(1929, 1973), label = "Fordism"),
  Long_Post_Fordist_Era_1974_2024 = list(range = c(1974, 2024), label = "Post-Fordism")
)

capital_defs <- c(A = "k_cap", B = "k_cap_GT", C = "k_cap_GTnet")
capital_labels <- c(
  A = "Baseline (ME+NRC)",
  B = "Extended GPIM gross (+K_GT)",
  C = "Extended BEA net (+GOV_TRANS)")

## ==========================================================
## STEP 2: IM-OLS wrapper (copied from US_S41 / US_S19)
## ==========================================================

safe_scalar <- function(val, default = NA) {
  if (is.null(val) || length(val) == 0 || is.na(val[1])) return(default)
  val[1]
}

cv_adf <- function(m) {
  tab <- list(
    `2` = c(p01 = -3.90, p05 = -3.34, p10 = -3.04),
    `3` = c(p01 = -4.29, p05 = -3.74, p10 = -3.45),
    `4` = c(p01 = -4.64, p05 = -4.10, p10 = -3.81),
    `5` = c(p01 = -4.96, p05 = -4.42, p10 = -4.13),
    `6` = c(p01 = -5.25, p05 = -4.72, p10 = -4.43)
  )
  tab[[as.character(min(max(m, 2), 6))]]
}

cv_vw2 <- function(k) {
  tab <- list(
    `1` = c(p10 = 5.82,  p05 = 7.36,  p01 = 11.24),
    `2` = c(p10 = 8.60,  p05 = 10.33, p01 = 14.22),
    `3` = c(p10 = 11.45, p05 = 13.78, p01 = 18.90),
    `4` = c(p10 = 14.10, p05 = 16.70, p01 = 22.40),
    `5` = c(p10 = 16.60, p05 = 19.60, p01 = 26.00)
  )
  tab[[as.character(min(max(k, 1), 5))]]
}

calc_vw_type2 <- function(x, y, deter, fit) {
  tryCatch({
    y.T <- nrow(x); x.k <- ncol(x)
    d.k <- if (is.null(deter)) 0 else ncol(deter)
    Sx <- matrixStats::colCumsums(x)
    if (d.k == 0) Sd <- matrix(nrow = y.T, ncol = 0) else Sd <- matrixStats::colCumsums(deter)
    InvBase <- Sx[y.T:1, , drop = FALSE]
    InvBaseCum <- matrixStats::colCumsums(InvBase)
    RevBase <- InvBaseCum[y.T:1, , drop = FALSE]
    Zreg <- matrixStats::colCumsums(RevBase)
    if (d.k == 0) X2mat <- as.matrix(cbind(Sx, x, Zreg)) else X2mat <- as.matrix(cbind(Sd, Sx, x, Zreg))
    S <- matrixStats::colCumsums(X2mat)
    DS <- rbind(S[y.T, ], t(S[y.T, ] - t(S[1:(y.T - 1), ])))
    Ha <- cointReg:::trySolve(t(X2mat) %*% X2mat)
    H <- Ha %*% t(DS)
    V2 <- H %*% t(H)
    lambda2 <- fit$lambda2
    if (is.null(lambda2) || length(lambda2) == 0) return(list(stat = NA, stars = ""))
    idx <- (d.k + 2 * x.k + 1):(d.k + 3 * x.k)
    V2_lambda <- V2[idx, idx, drop = FALSE]
    w2 <- fit$omega.u.v
    if (is.null(w2) || is.na(w2) || w2 <= 0) return(list(stat = NA, stars = ""))
    V2_inv <- cointReg:::trySolve(V2_lambda)
    S_type2 <- as.numeric(t(lambda2) %*% V2_inv %*% lambda2 / w2)
    cv <- cv_vw2(x.k)
    stars <- if (!is.na(S_type2)) {
      if (S_type2 >= cv["p01"]) "***" else if (S_type2 >= cv["p05"]) "**" else if (S_type2 >= cv["p10"]) "*" else ""
    } else ""
    list(stat = S_type2, stars = stars)
  }, error = function(e) list(stat = NA, stars = ""))
}

cointRegIM_with_tests <- function(x, y, deter, kernel = "ba", bandwidth = "nw") {
  fit <- cointReg::cointRegIM(x = x, y = y, deter = deter,
    selector = c(1, 2), t.test = TRUE, kernel = kernel, bandwidth = bandwidth)

  u <- fit$residuals
  if (any(is.na(u))) u <- u[!is.na(u)]
  T_obs <- length(u)
  m_i1 <- 1 + ncol(x)

  t_adf <- NA; adf_verdict <- ""
  try({
    eg_lm <- stats::lm(diff(u) ~ u[-T_obs] - 1)
    t_adf <- summary(eg_lm)$coefficients[1, 3]
    cv <- cv_adf(m_i1)
    adf_verdict <- if (t_adf <= cv["p01"]) "coint_1pct" else
                   if (t_adf <= cv["p05"]) "coint_5pct" else
                   if (t_adf <= cv["p10"]) "coint_10pct" else "no_coint"
  }, silent = TRUE)

  C_shin <- NA; shin_verdict <- ""
  try({
    S_t <- cumsum(u)
    omega2 <- fit$omega.u.v
    if (is.null(omega2) || is.na(omega2) || omega2 <= 0) {
      omega2 <- cointReg::getLongRunVar(u, kernel = kernel, bandwidth = bandwidth)$long.run
    }
    C_shin <- sum(S_t^2) / (T_obs^2 * omega2)
    shin_verdict <- if (C_shin >= 0.184) "reject_1pct" else
                    if (C_shin >= 0.121) "reject_5pct" else
                    if (C_shin >= 0.095) "reject_10pct" else "coint_ok"
  }, silent = TRUE)

  vw <- tryCatch(calc_vw_type2(x, y, deter, fit), error = function(e) list(stat = NA, stars = ""))

  y_mean <- mean(y)
  ss_tot <- sum((y - y_mean)^2)
  ss_res <- sum(u^2)
  r2_level <- max(0, 1 - (ss_res / ss_tot))
  sigma_u <- sqrt(ss_res / max(1, T_obs - ncol(x)))

  Xfull <- if (is.null(deter)) as.matrix(x) else {
    det_cn <- deter[, apply(as.matrix(deter), 2, var, na.rm = TRUE) > 1e-12, drop = FALSE]
    as.matrix(cbind(det_cn, x))
  }
  cn <- tryCatch(kappa(cor(Xfull), exact = TRUE), error = function(e) NA)

  fit$diagnostics <- list(
    T_obs = T_obs, m_i1 = m_i1,
    t_adf = safe_scalar(t_adf), adf_verdict = adf_verdict,
    C_shin = safe_scalar(C_shin), shin_verdict = shin_verdict,
    S_type2 = safe_scalar(vw$stat), vw_stars = vw$stars,
    r2_level = safe_scalar(r2_level), sigma_u = safe_scalar(sigma_u),
    cond_number = safe_scalar(cn)
  )
  fit
}

get_pars <- function(fit, nm) {
  s_nm <- paste0("S.", nm)
  idx <- which(names(fit$theta) == s_nm)
  if (length(idx) == 1) c(coef = fit$theta[[idx]], t = fit$t.theta[[idx]])
  else c(coef = NA_real_, t = NA_real_)
}

anchor <- function(z) z - z[which(!is.na(z))[1]]

## ==========================================================
## STEP 3: Cell estimator (shared by grid and continuity block)
## ==========================================================

run_cell <- function(sub, cap_var, dum_id, cell_id, win_lbl, win_name, cap_id) {
  k_c  <- anchor(sub[[cap_var]])
  wl_c <- anchor(sub$omega_NFC_GVA_lag1)
  kw_c <- k_c * wl_c
  cm_c <- anchor(sub$cm_lag1)

  x <- cbind(k = k_c, k_x_omega_lag = kw_c)
  colnames(x) <- c(cap_var, "k_x_omega_lag")
  valid <- complete.cases(x) & !is.na(cm_c)
  if (sum(valid) < 12) return(NULL)

  if (dum_id == "ND") {
    det <- cbind(Intercept = rep(1, nrow(sub)))
  } else {
    det <- as.matrix(cbind(Intercept = 1,
      sub[, c("D1933", "D1947", "D1974", "D2008", "D_WWII")]))
  }

  x_s <- x[valid, , drop = FALSE]
  det_v <- det[valid, , drop = FALSE]
  # Drop columns degenerate on the EFFECTIVE sample
  keep <- apply(det_v, 2, function(z) length(unique(z)) > 1)
  keep["Intercept"] <- TRUE
  det_v <- det_v[, keep, drop = FALSE]
  det_s <- cbind(det_v, cm_lag1 = cm_c[valid])
  y_s <- sub$y_t[valid]

  fit <- tryCatch(cointRegIM_with_tests(x_s, y_s, det_s),
    error = function(e) { message("  FAIL ", cell_id, ": ", e$message); NULL })
  if (is.null(fit)) return(NULL)

  ct <- fit$diagnostics
  p_k  <- get_pars(fit, cap_var)
  p_kw <- get_pars(fit, "k_x_omega_lag")
  p_cm <- get_pars(fit, "cm_lag1")
  dum_names <- setdiff(colnames(det_s), c("Intercept", "cm_lag1"))
  gam <- sapply(dum_names, function(nm) get_pars(fit, nm)["coef"])
  gam_t <- sapply(dum_names, function(nm) get_pars(fit, nm)["t"])
  eff_years <- sub$year[valid]

  data.frame(
    cell_id = cell_id, capital = cap_id, capital_var = cap_var,
    capital_label = capital_labels[[cap_id]],
    window = win_lbl, window_id = win_name, dummies = dum_id,
    n_obs = ct$T_obs, eff_start = min(eff_years), eff_end = max(eff_years),
    theta0_k = p_k[["coef"]], t_k = p_k[["t"]],
    theta1_kw = p_kw[["coef"]], t_theta1_kw = p_kw[["t"]],
    beta_cm = p_cm[["coef"]], t_cm = p_cm[["t"]],
    gamma_json = paste(sprintf("%s=%.4f(t=%.2f)", dum_names, gam, gam_t),
                       collapse = "; "),
    r2_level = ct$r2_level, sigma_u = ct$sigma_u,
    cond_number = ct$cond_number, cn_gt30_flag = ct$cond_number > 30,
    t_adf = ct$t_adf, adf_verdict = ct$adf_verdict,
    C_shin = ct$C_shin, shin_verdict = ct$shin_verdict,
    S_type2 = ct$S_type2, vw_stars = ct$vw_stars,
    stamp = diagnostic_stamp,
    stringsAsFactors = FALSE
  )
}

## ==========================================================
## STEP 4: 18-cell grid with the extended control
## ==========================================================

cat("\n--- S42 grid: extended (c-m) control, 1929+ ---\n")

win_short <- c(Full_Century_1929_2024 = "Full",
               Long_Fordist_Era_1929_1973 = "Ford",
               Long_Post_Fordist_Era_1974_2024 = "Post")

results_list <- list()
for (cap_id in names(capital_defs)) {
  for (win_name in names(windows_list)) {
    win <- windows_list[[win_name]]
    sub <- df[df$year >= win$range[1] & df$year <= win$range[2], , drop = FALSE]
    for (dum_id in c("ND", "WD")) {
      cell_id <- paste(cap_id, win_short[[win_name]], dum_id, sep = "-")
      row <- run_cell(sub, capital_defs[[cap_id]], dum_id, cell_id,
                      win$label, win_name, cap_id)
      if (is.null(row)) next
      results_list[[cell_id]] <- row
      cat(sprintf("  %-12s T=%3d (%d-%d)  th0=%8.3f  th1=%9.3f (t=%6.2f)  cm=%7.3f  CN=%8.1f  %s/%s\n",
                  cell_id, row$n_obs, row$eff_start, row$eff_end,
                  row$theta0_k, row$theta1_kw, row$t_theta1_kw, row$beta_cm,
                  safe_scalar(row$cond_number, 0),
                  row$adf_verdict, row$shin_verdict))
    }
  }
}
long_df <- do.call(rbind, results_list)
rownames(long_df) <- NULL
write.csv(long_df, file.path(csv_dir, "s42_coefficient_table_long.csv"),
          row.names = FALSE)

## ==========================================================
## STEP 5: Continuity block — truncated 1949-1973 with new control vs S41
## ==========================================================

cat("\n--- Continuity block: 1949-1973 truncated sample, new control ---\n")

s41_ledger <- read.csv(s41_ledger_csv, stringsAsFactors = FALSE)
cont_rows <- list()
for (cap_id in names(capital_defs)) {
  sub <- df[df$year >= 1949 & df$year <= 1973, , drop = FALSE]
  cell_id <- paste0(cap_id, "-Ford-TRUNC")
  row <- run_cell(sub, capital_defs[[cap_id]], "ND", cell_id,
                  "Fordism (truncated)", "Truncated_1949_1973", cap_id)
  if (is.null(row)) next
  s41_ref <- s41_ledger[grepl(paste0("^", cap_id, "-Ford"),
                              s41_ledger$cell_id), ][1, ]
  cont_rows[[cell_id]] <- data.frame(
    capital = cap_id, capital_label = capital_labels[[cap_id]],
    theta1_s41_fred_control = s41_ref$theta1_kw,
    theta1_trunc_nipa_control = row$theta1_kw,
    control_source_effect = row$theta1_kw - s41_ref$theta1_kw,
    theta1_s42_full_window = long_df$theta1_kw[
      long_df$cell_id == paste0(cap_id, "-Ford-ND")],
    sample_extension_effect = long_df$theta1_kw[
      long_df$cell_id == paste0(cap_id, "-Ford-ND")] - row$theta1_kw,
    stamp = diagnostic_stamp
  )
  cat(sprintf("  %s: S41(FRED)=%.3f  trunc(NIPA)=%.3f  full(NIPA)=%.3f\n",
              cap_id, s41_ref$theta1_kw, row$theta1_kw,
              cont_rows[[cell_id]]$theta1_s42_full_window))
}
continuity <- do.call(rbind, cont_rows)
rownames(continuity) <- NULL
write.csv(continuity, file.path(csv_dir, "s42_continuity_decomposition.csv"),
          row.names = FALSE)

## ==========================================================
## STEP 6: Landscape wide table + ledger + figures
## ==========================================================

fmt <- function(v, d = 3) ifelse(is.na(v), "—", sprintf(paste0("%.", d, "f"), v))

wide <- data.frame(parameter = c(
  "theta0 (k)", "  t-stat", "theta1 (k*omega_lag)", "  t-stat",
  "beta (c-m)_{t-1}", "  t-stat",
  "T", "eff. sample", "R2_level", "sigma_u", "CN", "CN>30",
  "ADF verdict", "Shin verdict", "VW stars", "Dummies"))
for (cid in long_df$cell_id) {
  r <- long_df[long_df$cell_id == cid, ]
  wide[[cid]] <- c(
    fmt(r$theta0_k), fmt(r$t_k, 2),
    fmt(r$theta1_kw), fmt(r$t_theta1_kw, 2),
    fmt(r$beta_cm), fmt(r$t_cm, 2),
    as.character(r$n_obs), sprintf("%d-%d", r$eff_start, r$eff_end),
    fmt(r$r2_level, 4), fmt(r$sigma_u, 4),
    fmt(r$cond_number, 1), ifelse(r$cn_gt30_flag, "FLAG", "ok"),
    r$adf_verdict, r$shin_verdict,
    ifelse(r$vw_stars == "", "n.s.", r$vw_stars), r$dummies)
}
write.csv(wide, file.path(csv_dir, "s42_coefficient_table_wide.csv"),
          row.names = FALSE)

ledger <- long_df[, c("cell_id", "capital_label", "window", "dummies",
                      "n_obs", "eff_start", "eff_end", "theta0_k",
                      "theta1_kw", "t_theta1_kw", "beta_cm", "cond_number",
                      "adf_verdict", "shin_verdict", "stamp")]
write.csv(ledger, file.path(csv_dir, "s42_estimation_ledger.csv"),
          row.names = FALSE)

plot_df <- long_df
plot_df$window <- factor(plot_df$window,
  levels = c("Full Sample", "Fordism", "Post-Fordism"))
g1 <- ggplot(plot_df, aes(x = window, y = theta1_kw,
                          fill = capital_label, alpha = dummies)) +
  geom_col(position = position_dodge(width = 0.85), width = 0.8) +
  scale_alpha_manual(values = c(ND = 0.55, WD = 1)) +
  labs(title = "theta1 with full Fordist window (extended (c-m) control, 1929+)",
       subtitle = "S42 diagnostic branch; compare S41 (control truncated at 1947)",
       x = NULL, y = "theta1", fill = "Capital definition", alpha = "Dummy set") +
  theme_minimal(base_size = 11)
ggsave(file.path(fig_dir, "s42_theta1_full_fordist_window.png"), g1,
       width = 10, height = 6, dpi = 150)
ggsave(file.path(fig_dir, "s42_theta1_full_fordist_window.pdf"), g1,
       width = 10, height = 6)

comp_df <- rbind(
  data.frame(capital = continuity$capital, run = "S41 trunc (FRED ctrl)",
             theta1 = continuity$theta1_s41_fred_control),
  data.frame(capital = continuity$capital, run = "Trunc (NIPA ctrl)",
             theta1 = continuity$theta1_trunc_nipa_control),
  data.frame(capital = continuity$capital, run = "Full window (NIPA ctrl)",
             theta1 = continuity$theta1_s42_full_window))
comp_df$run <- factor(comp_df$run, levels = unique(comp_df$run))
g2 <- ggplot(comp_df, aes(x = capital, y = theta1, fill = run)) +
  geom_col(position = position_dodge(width = 0.85), width = 0.8) +
  labs(title = "Fordist theta1 decomposition: control source vs sample extension",
       x = "Capital definition", y = "theta1 (Fordism)", fill = NULL) +
  theme_minimal(base_size = 11)
ggsave(file.path(fig_dir, "s42_fordist_theta1_decomposition.png"), g2,
       width = 9, height = 5.5, dpi = 150)
ggsave(file.path(fig_dir, "s42_fordist_theta1_decomposition.pdf"), g2,
       width = 9, height = 5.5)

cat(sprintf("\nSaved: %d grid cells + continuity decomposition + 2 figures\n",
            nrow(long_df)))
