#!/usr/bin/env Rscript

# US_S41_kgt_inclusion_baseline_vs_extended_imols.R
#
# S41: Does including government transportation capital in the productive
# capital aggregate change the Fordist-era transformation-elasticity slope?
#
# Compares three capital definitions under the CMlevel-form specification
# (locked S09B demand control, standalone wage share dropped per session
# design — it enters only through the k*omega interaction):
#
#   y_t = alpha + theta0*k_t + theta1*(k_t * omega_{t-1}^c)
#         + beta_cm*(c-m)_{t-1}^c + gamma'D_t + eps_t
#
# Grid: 3 capital defs x 3 windows x 2 dummy sets = 18 cells.
#   Capital:  A = k_cap (baseline, BEA net ME+NRC)
#             B = k_cap_GT (extended, + GPIM gross gov transport, D14)
#             C = k_cap_GTnet (extended, + BEA net gov transport; robustness)
#   Windows:  Full 1929-2024, Fordism 1929-1973, Post-Fordism 1974-2024
#   Dummies:  ND = intercept only
#             WD = D1933, D1947, D1974, D2008 steps + WWII block 1942-1945
#                  (degenerate columns auto-dropped per window)
#
# A0 wiring check: replicates S19's CMlevel spec exactly (including
# standalone omega, no WWII block) and asserts coefficient match against
# the frozen s19_final_demand_controls_specA_results.csv within 1e-6
# before any extended-capital cell is interpreted.
#
# Estimator: IM-OLS (cointReg::cointRegIM) per the E10V lock. The kernel
# "ba" / bandwidth "nw" arguments are the repo inference-layer convention
# only (t-stats, Shin LM, VW statistics); IM-OLS coefficients are
# kernel-invariant. Wrapper with residual ADF, Shin LM, VW Type 2, and
# condition number copied from US_S19_final_demand_controls_imols_specA.R.
#
# Governance: DIAGNOSTIC branch (S41). Gov transport remains excluded from
# baseline K_capacity per the D06 exclusion ledger; nothing frozen is
# modified.

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(cointReg)
  library(dplyr)
  library(ggplot2)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
ext_csv <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data",
                     "s41_extended_capital_panel.csv")
cm_csv  <- file.path(repo_root, "output", "US",
  "S15C_FRED_DEMAND_CONTROL_COINTEGRATION", "csv",
  "fred_ad_components_panel.csv")
s19_csv <- file.path(repo_root, "output", "US",
  "S19_FINAL_DEMAND_CONTROLS_SPECA", "csv",
  "s19_final_demand_controls_specA_results.csv")
d14_checks_csv <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION",
                            "data", "D14_validation_checks.csv")
out_dir <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION")
csv_dir <- file.path(out_dir, "csv")
fig_dir <- file.path(out_dir, "figs")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

diagnostic_stamp <- "DIAGNOSTIC_ONLY;NOT_D06_BASELINE;S41_BRANCH"

cat("========================================================================\n")
cat("S41: KGT inclusion — baseline vs extended capital, IM-OLS CMlevel form\n")
cat("========================================================================\n")

## Gate on D14
d14 <- read.csv(d14_checks_csv, stringsAsFactors = FALSE)
if (any(d14$status != "PASS")) stop("D14 gate not clean; S41 blocked.")
cat(sprintf("D14 gate: %d/%d checks PASS — authorized.\n", nrow(d14), nrow(d14)))

## ==========================================================
## STEP 1: Load extended panel and merge C/M demand control (as in S19)
## ==========================================================

df <- read.csv(ext_csv, stringsAsFactors = FALSE)
df <- df[!is.na(df$y_t) & !is.na(df$k_cap) &
         !is.na(df$omega_NFC_GVA) & !is.na(df$omega_NFC_GVA_lag1), ]
df <- df[order(df$year), ]

cm_panel <- read.csv(cm_csv, stringsAsFactors = FALSE)
cm_panel <- cm_panel[, c("year", "C_real", "M_real")]
cm_panel$cm_t <- log(cm_panel$C_real) - log(cm_panel$M_real)
cm_panel <- cm_panel %>% arrange(year) %>%
  mutate(cm_lag1 = dplyr::lag(cm_t, 1L))
df <- merge(df, cm_panel[, c("year", "cm_t", "cm_lag1")], by = "year",
            all.x = TRUE)

## Dummies (S19 convention + WWII block)
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
## STEP 2: IM-OLS wrapper (copied from US_S19, E10V lock)
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
## STEP 3: A0 wiring check — replicate S19 CMlevel exactly
## ==========================================================

cat("\n--- A0 wiring check: replicate S19 CMlevel against frozen CSV ---\n")

s19 <- read.csv(s19_csv, stringsAsFactors = FALSE)
wiring_tol <- 1e-6
wiring_rows <- list()

for (win_name in names(windows_list)) {
  win <- windows_list[[win_name]]
  sub <- df[df$year >= win$range[1] & df$year <= win$range[2], , drop = FALSE]

  k_c  <- anchor(sub$k_cap)
  w_c  <- anchor(sub$omega_NFC_GVA)
  wl_c <- anchor(sub$omega_NFC_GVA_lag1)
  kw_c <- k_c * wl_c
  cm_c <- anchor(sub$cm_lag1)

  x <- cbind(k_cap = k_c, omega = w_c, k_x_omega_lag = kw_c)
  valid <- complete.cases(x) & !is.na(cm_c)
  base_det <- as.matrix(cbind(Intercept = 1,
                              sub[, c("D1933", "D1947", "D1974", "D2008")]))
  keep <- apply(base_det, 2, function(z) length(unique(z)) > 1)
  base_det <- base_det[, keep, drop = FALSE]

  x_s <- x[valid, , drop = FALSE]
  det_s <- cbind(base_det[valid, , drop = FALSE],
                 cm_lag1 = cm_c[valid])
  fit <- cointRegIM_with_tests(x_s, sub$y_t[valid], det_s)

  ref <- s19[s19$window_id == win_name & s19$spec == "CMlevel", ]
  stopifnot(nrow(ref) == 1)
  got <- c(theta0_k   = unname(get_pars(fit, "k_cap")["coef"]),
           beta_omega = unname(get_pars(fit, "omega")["coef"]),
           theta1_kw  = unname(get_pars(fit, "k_x_omega_lag")["coef"]),
           beta_cm    = unname(get_pars(fit, "cm_lag1")["coef"]))
  want <- c(ref$theta0_k, ref$beta_omega, ref$theta1_kw, ref$beta_cm)
  diffs <- abs(got - want)
  ok <- all(diffs < wiring_tol)
  wiring_rows[[win_name]] <- data.frame(
    window_id = win_name, parameter = names(got),
    s41_replication = unname(got), s19_frozen = want,
    abs_diff = unname(diffs), status = ifelse(diffs < wiring_tol, "PASS", "FAIL"))
  cat(sprintf("  %-34s max|diff| = %.2e  %s\n", win_name, max(diffs),
              ifelse(ok, "PASS", "FAIL")))
}
wiring_df <- do.call(rbind, wiring_rows)
rownames(wiring_df) <- NULL
write.csv(wiring_df, file.path(csv_dir, "s41_a0_wiring_check.csv"),
          row.names = FALSE)
if (any(wiring_df$status != "PASS")) {
  stop("A0 wiring check FAILED — estimator plumbing differs from S19; halting.")
}
cat("A0 wiring check PASSED — plumbing identical to frozen S19.\n")

## ==========================================================
## STEP 4: 18-cell estimation grid
## ==========================================================

cat("\n--- S41 grid: 3 capital x 3 windows x 2 dummy sets ---\n")

results_list <- list()

for (cap_id in names(capital_defs)) {
  cap_var <- capital_defs[[cap_id]]
  for (win_name in names(windows_list)) {
    win <- windows_list[[win_name]]
    sub <- df[df$year >= win$range[1] & df$year <= win$range[2], , drop = FALSE]

    k_c  <- anchor(sub[[cap_var]])
    wl_c <- anchor(sub$omega_NFC_GVA_lag1)
    kw_c <- k_c * wl_c
    cm_c <- anchor(sub$cm_lag1)

    x <- cbind(k = k_c, k_x_omega_lag = kw_c)
    colnames(x) <- c(cap_var, "k_x_omega_lag")
    valid <- complete.cases(x) & !is.na(cm_c)
    if (sum(valid) < 12) next

    for (dum_id in c("ND", "WD")) {
      if (dum_id == "ND") {
        det <- cbind(Intercept = rep(1, nrow(sub)))
      } else {
        det <- as.matrix(cbind(Intercept = 1,
          sub[, c("D1933", "D1947", "D1974", "D2008", "D_WWII")]))
      }

      x_s <- x[valid, , drop = FALSE]
      det_v <- det[valid, , drop = FALSE]
      # Drop columns degenerate on the EFFECTIVE sample (after the cm
      # availability filter), not the nominal window — e.g. in Fordism the
      # effective sample is 1949-1973, where all step dummies are constant.
      keep <- apply(det_v, 2, function(z) length(unique(z)) > 1)
      keep["Intercept"] <- TRUE
      det_v <- det_v[, keep, drop = FALSE]
      det_s <- cbind(det_v, cm_lag1 = cm_c[valid])
      y_s <- sub$y_t[valid]

      fit <- tryCatch(cointRegIM_with_tests(x_s, y_s, det_s),
        error = function(e) {
          message("  FAIL ", cap_id, "/", win_name, "/", dum_id, ": ", e$message)
          NULL })
      if (is.null(fit)) next

      ct <- fit$diagnostics
      p_k  <- get_pars(fit, cap_var)
      p_kw <- get_pars(fit, "k_x_omega_lag")
      p_cm <- get_pars(fit, "cm_lag1")
      dum_names <- setdiff(colnames(det_s), c("Intercept", "cm_lag1"))
      gam <- sapply(dum_names, function(nm) get_pars(fit, nm)["coef"])
      gam_t <- sapply(dum_names, function(nm) get_pars(fit, nm)["t"])

      cell_id <- paste(cap_id, sub("_.*", "", gsub("Long_|_Era|_Century", "",
                       win_name)), dum_id, sep = "-")
      cell_id <- paste(cap_id,
                       c(Full_Century_1929_2024 = "Full",
                         Long_Fordist_Era_1929_1973 = "Ford",
                         Long_Post_Fordist_Era_1974_2024 = "Post")[win_name],
                       dum_id, sep = "-")

      results_list[[cell_id]] <- data.frame(
        cell_id = cell_id, capital = cap_id, capital_var = cap_var,
        capital_label = capital_labels[[cap_id]],
        window = win$label, window_id = win_name, dummies = dum_id,
        n_obs = ct$T_obs,
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
      cat(sprintf("  %-12s T=%3d  th0=%8.3f  th1=%9.3f (t=%6.2f)  cm=%7.3f  CN=%8.1f  %s/%s\n",
                  cell_id, ct$T_obs, p_k[["coef"]], p_kw[["coef"]], p_kw[["t"]],
                  p_cm[["coef"]], safe_scalar(ct$cond_number, 0),
                  ct$adf_verdict, ct$shin_verdict))
    }
  }
}

long_df <- do.call(rbind, results_list)
rownames(long_df) <- NULL
write.csv(long_df, file.path(csv_dir, "s41_coefficient_table_long.csv"),
          row.names = FALSE)

## ==========================================================
## STEP 5: Landscape wide table (parameters = rows, cells = columns)
## ==========================================================

fmt <- function(v, d = 3) ifelse(is.na(v), "—", sprintf(paste0("%.", d, "f"), v))

param_rows <- list(
  c("theta0_k",   "coef"), c("t_k",         "t"),
  c("theta1_kw",  "coef"), c("t_theta1_kw", "t"),
  c("beta_cm",    "coef"), c("t_cm",        "t")
)
row_labels <- c("theta0 (k)", "  t-stat", "theta1 (k*omega_lag)", "  t-stat",
                "beta (c-m)_{t-1}", "  t-stat")

wide <- data.frame(parameter = c(row_labels,
  "T", "R2_level", "sigma_u", "CN", "CN>30", "ADF verdict", "Shin verdict",
  "VW stars", "Dummies"))
cell_order <- long_df$cell_id
for (cid in cell_order) {
  r <- long_df[long_df$cell_id == cid, ]
  col <- c(
    fmt(r$theta0_k), fmt(r$t_k, 2),
    fmt(r$theta1_kw), fmt(r$t_theta1_kw, 2),
    fmt(r$beta_cm), fmt(r$t_cm, 2),
    as.character(r$n_obs), fmt(r$r2_level, 4), fmt(r$sigma_u, 4),
    fmt(r$cond_number, 1), ifelse(r$cn_gt30_flag, "FLAG", "ok"),
    r$adf_verdict, r$shin_verdict,
    ifelse(r$vw_stars == "", "n.s.", r$vw_stars), r$dummies)
  wide[[cid]] <- col
}
write.csv(wide, file.path(csv_dir, "s41_coefficient_table_wide.csv"),
          row.names = FALSE)

## Estimation ledger (headline no-fabrication trace)
ledger <- long_df[, c("cell_id", "capital_label", "window", "dummies",
                      "n_obs", "theta0_k", "theta1_kw", "t_theta1_kw",
                      "beta_cm", "cond_number", "adf_verdict", "shin_verdict",
                      "stamp")]
write.csv(ledger, file.path(csv_dir, "s41_estimation_ledger.csv"),
          row.names = FALSE)

## ==========================================================
## STEP 6: Figures
## ==========================================================

plot_df <- long_df
plot_df$window <- factor(plot_df$window,
  levels = c("Full Sample", "Fordism", "Post-Fordism"))

g1 <- ggplot(plot_df, aes(x = window, y = theta1_kw,
                          fill = capital_label, alpha = dummies)) +
  geom_col(position = position_dodge(width = 0.85), width = 0.8) +
  scale_alpha_manual(values = c(ND = 0.55, WD = 1)) +
  labs(title = "theta1 (k x omega interaction) — baseline vs extended capital",
       subtitle = "S41 diagnostic branch; IM-OLS CMlevel form; ND = no dummies, WD = step + WWII block",
       x = NULL, y = "theta1", fill = "Capital definition",
       alpha = "Dummy set") +
  theme_minimal(base_size = 11)
ggsave(file.path(fig_dir, "s41_theta1_comparison_baseline_vs_extended.png"),
       g1, width = 10, height = 6, dpi = 150)
ggsave(file.path(fig_dir, "s41_theta1_comparison_baseline_vs_extended.pdf"),
       g1, width = 10, height = 6)

share_df <- df[!is.na(df$GT_share), c("year", "GT_share")]
g2 <- ggplot(share_df, aes(x = year, y = GT_share)) +
  geom_line(linewidth = 0.8) +
  annotate("rect", xmin = 1929, xmax = 1973, ymin = -Inf, ymax = Inf,
           alpha = 0.08, fill = "blue") +
  labs(title = "Government transportation share of extended capital (K_GT / K_cap_GT)",
       subtitle = "GPIM gross, benchmark-seeded; shaded = Fordist window",
       x = NULL, y = "share") +
  theme_minimal(base_size = 11)
ggsave(file.path(fig_dir, "s41_gt_share_path.png"), g2,
       width = 10, height = 5, dpi = 150)
ggsave(file.path(fig_dir, "s41_gt_share_path.pdf"), g2,
       width = 10, height = 5)

cat(sprintf("\nSaved: %d cells (long, wide, ledger) + wiring check + 2 figures\n",
            nrow(long_df)))
cat("Key comparison (Fordism, WD):\n")
key <- long_df[long_df$window == "Fordism" & long_df$dummies == "WD",
               c("cell_id", "theta1_kw", "t_theta1_kw", "cond_number")]
print(key, row.names = FALSE)
