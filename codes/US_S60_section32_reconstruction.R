#!/usr/bin/env Rscript

# US_S60_section32_reconstruction.R
# ---------------------------------------------------------------------------
# Section 3.2 Capacity Reconstruction & Visualizations Engine (Specification B)
#
# Model: 
#   - M2.19a (Private Core Capital + Shaikh-Tonak Tier 1 NVA Wage Share + No Break)
#   - M2.24b (Private Core Capital + Shaikh-Tonak Tier 2 NVA Wage Share + Breaks)
#
# Methodology:
#   - Real GPIM Gross Capital Stock Weights (s_ME_real = K_ME / (K_ME + K_NRC))
#   - Smooth Non-Parametric Derivative (d_kappa / d_kNRC) from LOESS fit (span = 0.30)
#   - Retained Differential Formulation (no division by g_cap_t):
#       theta^{SpecB}_t = (theta_NRC_str + MP_kappa * (dkappa/dkNRC)) / (1 + s_ME_real * (dkappa/dkNRC))
#   - Figure formatting: No titles/subtitles in ggplot (handled in LaTeX)
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(cointReg)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
rds_path  <- file.path(repo_root, "output", "US", "S61_SECTION32_IMOLS", "rds", "s61_fitted_models.rds")
f_in      <- file.path(repo_root, "output", "gpim_specB_components_long.csv")

out_dir   <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY")
csv_dir   <- file.path(out_dir, "csv")
rds_dir   <- file.path(out_dir, "rds")
fig_dir   <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "drafts", "ch2_sec4_3_heterogeneous_capital_US")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S60: Section 3.2 Capacity Recovery Engine (LOESS Slope & Real GPIM Weights)\n")
cat("========================================================================\n")

if (!file.exists(rds_path)) {
  stop("Fitted models RDS not found at: ", rds_path)
}
fs <- readRDS(rds_path)

reconstruct_specB_loess <- function(model_id, is_primary = FALSE, span_val = 0.30) {
  m <- fs[[model_id]]
  df <- read.csv(f_in)
  
  # Real GPIM Gross Capital Stock Shares
  val_ME_real  <- df$K_ME
  val_NRC_real <- df$K_NRC
  df$s_ME_real  <- val_ME_real / (val_ME_real + val_NRC_real)
  df$s_NRC_real <- val_NRC_real / (val_ME_real + val_NRC_real)
  
  df$iota_t <- df$IPP_share_capital_plus_IPP
  df$iota_lag1 <- dplyr::lag(df$iota_t, 1L)
  
  # Align to model sample years
  df_clean <- df[df$year %in% m$years, ]
  df_clean <- df_clean[order(df_clean$year), ]
  
  # Non-parametric LOESS fit of mechanization gap (kappa) against extensive scale (k_NRC)
  df_clean$kappa_raw <- df_clean$k_ME - df_clean$k_NRC
  fit_loess <- loess(kappa_raw ~ k_NRC, data = df_clean, span = span_val)
  df_clean$kappa_loess <- predict(fit_loess)
  
  # Compute smooth trajectory derivative d_kappa / d_kNRC
  d_kappa <- c(df_clean$kappa_loess[2] - df_clean$kappa_loess[1], diff(df_clean$kappa_loess))
  d_kNRC  <- c(df_clean$k_NRC[2] - df_clean$k_NRC[1], diff(df_clean$k_NRC))
  df_clean$dkappa_dkNRC <- d_kappa / d_kNRC
  
  # Center variables matching estimation
  kn <- df_clean$k_NRC - df_clean$k_NRC[1]
  kp <- df_clean$tau_real - df_clean$tau_real[1]
  pk <- df_clean$p_rel - df_clean$p_rel[1]
  
  w_var <- if (grepl("Tier 1", m$Wage_Label)) "omega_ST_Tier1_NVA_lag1" else "omega_ST_Tier2_NVA_lag1"
  w <- df_clean[[w_var]]
  w_c <- w - w[1]
  
  iota <- df_clean$iota_lag1
  C_idx <- w * (1 - iota)
  C_idx_c <- C_idx - C_idx[1]
  
  inter_raw_1 <- kp * C_idx_c
  inter_raw_2 <- kp * pk
  
  # Re-run auxiliary OLS regressions to unpack structural parameters
  deter_f <- m$deter
  aux_df <- as.data.frame(cbind(k_NRC = kn, kappa = kp, deter_f))
  
  fit_aux_w <- lm(inter_raw_1 ~ . - 1, data = aux_df)
  fit_aux_p <- lm(inter_raw_2 ~ . - 1, data = aux_df)
  
  a_w_NRC <- coef(fit_aux_w)["k_NRC"]
  a_w_kp  <- coef(fit_aux_w)["kappa"]
  a_p_NRC <- coef(fit_aux_p)["k_NRC"]
  a_p_kp  <- coef(fit_aux_p)["kappa"]
  
  theta <- m$fit$theta
  d_k <- ncol(m$deter)
  
  theta_NRC_hat <- theta[d_k + 1]
  theta_kp_hat  <- theta[d_k + 2]
  theta_iw_hat  <- theta[d_k + 3]
  theta_ip_hat  <- theta[d_k + 4]
  
  theta_NRC_str <- theta_NRC_hat - theta_iw_hat * a_w_NRC - theta_ip_hat * a_p_NRC
  theta_kp_str  <- theta_kp_hat  - theta_iw_hat * a_w_kp  - theta_ip_hat * a_p_kp
  
  # Marginal payoff to mechanization gap
  mp_kappa <- theta_kp_str + theta_iw_hat * C_idx_c + theta_ip_hat * pk
  
  # Retained continuous differential elasticity formula
  theta_SpecB_loess <- (theta_NRC_str + mp_kappa * df_clean$dkappa_dkNRC) / (1 + df_clean$s_ME_real * df_clean$dkappa_dkNRC)
  
  # Potential output reconstruction (orthogonalized fitted space)
  o1 <- m$X_mat[, "inter_w"]
  o2 <- m$X_mat[, "inter_p"]
  
  idx_1973 <- which(df_clean$year == 1973)
  y_1973 <- df_clean$y_t[idx_1973]
  
  y_p <- y_1973 + 
         theta_NRC_hat * (kn - kn[idx_1973]) + 
         theta_kp_hat  * (kp - kp[idx_1973]) + 
         theta_iw_hat  * (o1 - o1[idx_1973]) + 
         theta_ip_hat  * (o2 - o2[idx_1973])
  
  mu <- exp(df_clean$y_t - y_p)
  
  anchor_err <- abs(mu[idx_1973] - 1.00)
  cat(sprintf("Model %s: mu_1973 = %.15f (Abs Error: %.2e) -> %s\n", 
              model_id, mu[idx_1973], anchor_err, if (anchor_err < 1e-12) "PASS" else "FAIL"))
  
  data.frame(
    year = df_clean$year,
    y_obs = df_clean$y_t,
    y_p = y_p,
    mu = mu,
    theta_SpecB = theta_SpecB_loess,
    dkappa_dkNRC = df_clean$dkappa_dkNRC,
    s_ME_real = df_clean$s_ME_real,
    model_id = model_id,
    is_primary = is_primary
  )
}

res_19a <- reconstruct_specB_loess("M2.19a", is_primary = TRUE)
res_24b <- reconstruct_specB_loess("M2.24b", is_primary = FALSE)

combined_df <- merge(
  res_19a[, c("year", "y_obs", "y_p", "mu", "theta_SpecB", "dkappa_dkNRC", "s_ME_real")],
  res_24b[, c("year", "y_p", "mu", "theta_SpecB")],
  by = "year",
  suffixes = c("_m19a", "_m24b")
)

csv_path <- file.path(csv_dir, "s60_section32_series.csv")
write.csv(combined_df, csv_path, row.names = FALSE)
cat("Saved series ledger to:", csv_path, "\n")

# ----------------------------------------------------------------------
# FIGURE 1: Reconstructed Capacity Utilization (mu_t)
# (No ggplot titles/subtitles; clean time series labels only)
# ----------------------------------------------------------------------
p_fig1 <- ggplot(combined_df, aes(x = year)) +
  geom_line(aes(y = mu_m19a * 100, color = "Preferred Specification (M2.19a, No Break)"), linewidth = 1.1) +
  geom_line(aes(y = mu_m24b * 100, color = "Robustness Check (M2.24b, With Breaks)"), linewidth = 0.9, linetype = "dashed") +
  geom_hline(yintercept = 100, linetype = "dashed", color = "#8B0000", linewidth = 0.8) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  annotate("text", x = 1974.5, y = 112, label = "1973 Peak Anchor (mu = 100%)", 
           color = "#006400", size = 3.3, hjust = 0, fontface = "bold") +
  scale_x_continuous(limits = c(1930, 2024), breaks = seq(1930, 2020, 10)) +
  scale_y_continuous(limits = c(25, 125), breaks = seq(30, 120, 15)) +
  scale_color_manual(values = c(
    "Preferred Specification (M2.19a, No Break)" = "#1B365D",
    "Robustness Check (M2.24b, With Breaks)" = "#5C768D"
  )) +
  labs(
    x = "Year",
    y = "Capacity Utilization (mu_t, %)",
    color = "Specification"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E5E5E5")
  )

ggsave(file.path(fig_dir, "fig_specB_reconstructed_capacity_utilization.png"), p_fig1, width = 9, height = 5.2, dpi = 300)
ggsave(file.path(fig_dir, "fig_specB_reconstructed_capacity_utilization.pdf"), p_fig1, width = 9, height = 5.2)
cat("Saved Figure 1 (Utilization)\n")


# ----------------------------------------------------------------------
# FIGURE 2: Transformation Elasticity (theta_t) with theta=1.0 Knife-Edge
# (No ggplot titles/subtitles; clean legend labels)
# ----------------------------------------------------------------------
p_fig2 <- ggplot(combined_df, aes(x = year)) +
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "#8B0000", linewidth = 0.9) +
  geom_line(aes(y = theta_SpecB_m19a, color = "Preferred Specification (M2.19a, No Break)"), linewidth = 1.1) +
  geom_line(aes(y = theta_SpecB_m24b, color = "Robustness Check (M2.24b, With Breaks)"), linewidth = 0.9, linetype = "dashed") +
  annotate("text", x = 1931, y = 1.05, label = "Overcapacity Threshold (theta = 1.00)", 
           color = "#8B0000", fontface = "bold", size = 3.3, hjust = 0) +
  scale_x_continuous(limits = c(1930, 2024), breaks = seq(1930, 2020, 10)) +
  scale_y_continuous(limits = c(-0.20, 1.20), breaks = seq(-0.20, 1.20, 0.20)) +
  scale_color_manual(values = c(
    "Preferred Specification (M2.19a, No Break)" = "#1B365D",
    "Robustness Check (M2.24b, With Breaks)" = "#5C768D"
  )) +
  labs(
    x = "Year",
    y = "Transformation Elasticity (theta_t)",
    color = "Specification"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E5E5E5")
  )

ggsave(file.path(fig_dir, "fig_specB_aggregate_elasticity_knife_edge.png"), p_fig2, width = 9, height = 5.2, dpi = 300)
ggsave(file.path(fig_dir, "fig_specB_aggregate_elasticity_knife_edge.pdf"), p_fig2, width = 9, height = 5.2)
cat("Saved Figure 2 (Elasticity Knife-Edge)\n")


# ----------------------------------------------------------------------
# FIGURE 3: Transformation Elasticity (theta_t) without Y-Axis Constraints
# (No ggplot titles/subtitles; auto-scaled Y axis)
# ----------------------------------------------------------------------
p_fig3 <- ggplot(combined_df, aes(x = year)) +
  geom_line(aes(y = theta_SpecB_m19a, color = "Preferred Specification (M2.19a, No Break)"), linewidth = 1.1) +
  geom_line(aes(y = theta_SpecB_m24b, color = "Robustness Check (M2.24b, With Breaks)"), linewidth = 0.9, linetype = "dashed") +
  geom_hline(yintercept = 1.00, linetype = "dotted", color = "#8B0000", linewidth = 0.6) +
  scale_x_continuous(limits = c(1930, 2024), breaks = seq(1930, 2020, 10)) +
  scale_color_manual(values = c(
    "Preferred Specification (M2.19a, No Break)" = "#1B365D",
    "Robustness Check (M2.24b, With Breaks)" = "#5C768D"
  )) +
  labs(
    x = "Year",
    y = "Transformation Elasticity (theta_t)",
    color = "Specification"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E5E5E5")
  )

ggsave(file.path(fig_dir, "fig_specB_aggregate_elasticity_zoomed.png"), p_fig3, width = 9, height = 5.2, dpi = 300)
ggsave(file.path(fig_dir, "fig_specB_aggregate_elasticity_zoomed.pdf"), p_fig3, width = 9, height = 5.2)
cat("Saved Figure 3 (Elasticity Unconstrained)\n")

cat("S60 Specification B Reconstruction Engine Complete!\n")
