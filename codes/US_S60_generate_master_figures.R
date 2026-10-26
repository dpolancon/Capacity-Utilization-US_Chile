#!/usr/bin/env Rscript

# US_S60_generate_master_figures.R
# ---------------------------------------------------------------------------
# Master Visualization & Figure Generation Engine (Chapter 2: Figures 1-4)
#
# Admissible Models:
#   - Section 3.1 (Aggregate Capital): M2.8a (No Break) & M2.8b (With Breaks)
#   - Section 3.2 (Heterogeneous Capital): M2.19a (No Break) & M2.24b (With Breaks)
#
# Protocol Rules:
#   - No titles or subtitles inside ggplot2 objects (handled in LaTeX .tex captions)
#   - Dual export to high-resolution PNG (300 dpi) and vectorized PDF (.pdf)
#   - Legend positioned at bottom with clear labels
#   - Year X-axis rotated 45 degrees with 5-year tick marks (seq(1930, 2020, 5))
#   - Strict notation: \kappa_t = k_ME - k_NRC for capital composition / mechanization gap
#   - \theta = 1.00 knife-edge line included only when range provides clean visualization
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(cointReg)
  library(gridExtra)
  library(grid)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

# Load fitted model objects
s50_path <- file.path(repo_root, "output", "US", "S50_SECTION31_IMOLS", "rds", "s50_fitted_models.rds")
s61_path <- file.path(repo_root, "output", "US", "S61_SECTION32_IMOLS", "rds", "s61_fitted_models.rds")

if (!file.exists(s50_path)) stop("Missing S50 fitted models RDS at: ", s50_path)
if (!file.exists(s61_path)) stop("Missing S61 fitted models RDS at: ", s61_path)

s50_models <- readRDS(s50_path)
s61_models <- readRDS(s61_path)

# Load underlying source data
f_in <- file.path(repo_root, "output", "gpim_specB_components_long.csv")
df_all <- read.csv(f_in, stringsAsFactors = FALSE)
df_all <- df_all[df_all$year >= 1929 & df_all$year <= 2024, ]
df_all <- df_all[order(df_all$year), ]
df_all$iota_t    <- df_all$IPP_share_capital_plus_IPP
df_all$iota_lag1 <- dplyr::lag(df_all$iota_t, 1L)

# Output Directories
out_fig_dir <- file.path(repo_root, "output", "US", "figures")
csv_out_dir <- file.path(out_fig_dir, "csv")
vault_fig_dir <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "drafts", "ch2_sec4_3_heterogeneous_capital_US")

dir.create(out_fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(csv_out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(vault_fig_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S60: Chapter 2 Master Figure Redesign Engine (Figures 1 - 4)\n")
cat("========================================================================\n")

# ---------------------------------------------------------------------------
# Reconstruction Helpers
# ---------------------------------------------------------------------------

reconstruct_s31 <- function(model_id) {
  m <- s50_models[[model_id]]
  df_sub <- df_all[df_all$year %in% m$years, ]
  df_sub <- df_sub[order(df_sub$year), ]
  
  w_var <- if (grepl("M2.8", model_id)) "omega_ST_Tier2_NVA_lag1" else "omega_ST_Tier1_NVA_lag1"
  df_sub <- df_sub[!is.na(df_sub[[w_var]]) & !is.na(df_sub$iota_lag1), ]
  
  coefs <- m$fit$theta
  d_k <- ncol(m$deter)
  beta_k <- coefs[d_k + 1]
  theta_1 <- coefs[d_k + 2]
  
  w_eff <- df_sub[[w_var]] * (1 - df_sub$iota_lag1)
  w_eff0 <- w_eff[1]
  w_eff_c <- w_eff - w_eff0
  
  k_vec <- df_sub$k_cap
  inter_raw <- k_vec * w_eff_c
  
  deter_mat <- m$deter
  if (nrow(deter_mat) > nrow(df_sub)) {
    deter_mat <- deter_mat[(nrow(deter_mat) - nrow(df_sub) + 1):nrow(deter_mat), , drop = FALSE]
  }
  aux_df <- data.frame(k = k_vec)
  if (ncol(deter_mat) > 0) aux_df <- cbind(aux_df, deter_mat)
  fit_aux <- lm(inter_raw ~ . - 1, data = aux_df)
  a1 <- coef(fit_aux)["k"]
  inter_ortho <- fit_aux$residuals
  
  theta_base <- beta_k - theta_1 * a1 - theta_1 * w_eff0
  theta_t <- theta_base + theta_1 * w_eff
  
  idx_1973 <- which(df_sub$year == 1973)
  y_obs <- df_sub$y_t
  
  y_p <- y_obs[idx_1973] + beta_k * (k_vec - k_vec[idx_1973]) + theta_1 * (inter_ortho - inter_ortho[idx_1973])
  if (d_k > 1) {
    gamma_coefs <- coefs[2:d_k]
    D_mat <- deter_mat[, 2:d_k, drop = FALSE]
    D_diff <- sweep(D_mat, 2, D_mat[idx_1973, ], "-")
    y_p <- y_p + as.vector(D_diff %*% gamma_coefs)
  }
  
  mu_t <- exp(y_obs - y_p)
  
  data.frame(
    year = df_sub$year,
    y_obs = y_obs,
    k_cap = k_vec,
    w_eff = w_eff,
    theta_t = theta_t,
    y_p = y_p,
    mu_t = mu_t,
    model_id = model_id
  )
}

reconstruct_s32 <- function(model_id, span_val = 0.30) {
  m <- s61_models[[model_id]]
  df_sub <- df_all[df_all$year %in% m$years, ]
  df_sub <- df_sub[order(df_sub$year), ]
  
  w_var <- if (grepl("M2.19", model_id)) "omega_ST_Tier1_NVA_lag1" else "omega_ST_Tier2_NVA_lag1"
  df_sub <- df_sub[!is.na(df_sub[[w_var]]) & !is.na(df_sub$iota_lag1), ]
  
  val_ME_real  <- df_sub$K_ME
  val_NRC_real <- df_sub$K_NRC
  df_sub$s_ME_real  <- val_ME_real / (val_ME_real + val_NRC_real)
  df_sub$s_NRC_real <- val_NRC_real / (val_ME_real + val_NRC_real)
  
  df_sub$kappa_raw <- df_sub$k_ME - df_sub$k_NRC
  fit_loess <- loess(kappa_raw ~ k_NRC, data = df_sub, span = span_val)
  df_sub$kappa_loess <- predict(fit_loess)
  
  d_kappa <- c(df_sub$kappa_loess[2] - df_sub$kappa_loess[1], diff(df_sub$kappa_loess))
  d_kNRC  <- c(df_sub$k_NRC[2] - df_sub$k_NRC[1], diff(df_sub$k_NRC))
  df_sub$dkappa_dkNRC <- d_kappa / d_kNRC
  
  kn <- df_sub$k_NRC - df_sub$k_NRC[1]
  kp <- df_sub$tau_real - df_sub$tau_real[1]
  pk <- df_sub$p_rel - df_sub$p_rel[1]
  
  w <- df_sub[[w_var]]
  w_c <- w - w[1]
  
  iota <- df_sub$iota_lag1
  C_idx <- w * (1 - iota)
  C_idx_c <- C_idx - C_idx[1]
  
  inter_raw_1 <- kp * C_idx_c
  inter_raw_2 <- kp * pk
  
  deter_f <- m$deter
  if (nrow(deter_f) > nrow(df_sub)) {
    deter_f <- deter_f[(nrow(deter_f) - nrow(df_sub) + 1):nrow(deter_f), , drop = FALSE]
  }
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
  
  mp_kappa <- theta_kp_str + theta_iw_hat * C_idx_c + theta_ip_hat * pk
  
  theta_SpecB_loess <- (theta_NRC_str + mp_kappa * df_sub$dkappa_dkNRC) / (1 + df_sub$s_ME_real * df_sub$dkappa_dkNRC)
  
  o1 <- m$X_mat[, "inter_w"]
  o2 <- m$X_mat[, "inter_p"]
  if (length(o1) > nrow(df_sub)) {
    o1 <- o1[(length(o1) - nrow(df_sub) + 1):length(o1)]
    o2 <- o2[(length(o2) - nrow(df_sub) + 1):length(o2)]
  }
  
  idx_1973 <- which(df_sub$year == 1973)
  y_1973 <- df_sub$y_t[idx_1973]
  
  y_p <- y_1973 + 
         theta_NRC_hat * (kn - kn[idx_1973]) + 
         theta_kp_hat  * (kp - kp[idx_1973]) + 
         theta_iw_hat  * (o1 - o1[idx_1973]) + 
         theta_ip_hat  * (o2 - o2[idx_1973])
  if (d_k > 1) {
    gamma_coefs <- theta[2:d_k]
    D_mat <- deter_f[, 2:d_k, drop = FALSE]
    D_diff <- sweep(D_mat, 2, D_mat[idx_1973, ], "-")
    y_p <- y_p + as.vector(D_diff %*% gamma_coefs)
  }
  
  mu_t <- exp(df_sub$y_t - y_p)
  
  data.frame(
    year = df_sub$year,
    y_obs = df_sub$y_t,
    k_NRC = df_sub$k_NRC,
    k_ME = df_sub$k_ME,
    kappa_t = df_sub$tau_real,
    p_rel = df_sub$p_rel,
    w_eff = C_idx,
    theta_t = theta_SpecB_loess,
    y_p = y_p,
    mu_t = mu_t,
    model_id = model_id
  )
}

res_m28a  <- reconstruct_s31("M2.8a")
res_m28b  <- reconstruct_s31("M2.8b")
res_m219a <- reconstruct_s32("M2.19a")
res_m224b <- reconstruct_s32("M2.24b")

# Merge series into canonical master dataframe
df_master <- df_all[, c("year", "y_t", "k_cap", "k_NRC", "k_ME", "tau_real", "p_rel", "IPP_share_capital_plus_IPP")]
colnames(df_master)[colnames(df_master) == "tau_real"] <- "kappa_t"

df_master <- df_master %>%
  left_join(res_m28a[, c("year", "mu_t", "theta_t")], by = "year") %>%
  rename(mu_m28a = mu_t, theta_m28a = theta_t) %>%
  left_join(res_m28b[, c("year", "mu_t", "theta_t")], by = "year") %>%
  rename(mu_m28b = mu_t, theta_m28b = theta_t) %>%
  left_join(res_m219a[, c("year", "mu_t", "theta_t", "w_eff")], by = "year") %>%
  rename(mu_m219a = mu_t, theta_m219a = theta_t, w_eff_m219a = w_eff) %>%
  left_join(res_m224b[, c("year", "mu_t", "theta_t", "w_eff")], by = "year") %>%
  rename(mu_m224b = mu_t, theta_m224b = theta_t, w_eff_m224b = w_eff)

write.csv(df_master, file.path(csv_out_dir, "s60_master_figure_series.csv"), row.names = FALSE)
cat("Master series saved to:", file.path(csv_out_dir, "s60_master_figure_series.csv"), "\n")

# Shared Theme Protocol Function
apply_figure_theme <- function() {
  theme_minimal(base_size = 11) +
    theme(
      legend.position = "bottom",
      legend.title = element_blank(),
      legend.text = element_text(size = 9.5),
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, color = "#222222", size = 9),
      axis.text.y = element_text(color = "#222222", size = 9),
      axis.title.x = element_text(margin = margin(t = 8), face = "bold", size = 10),
      axis.title.y = element_text(margin = margin(r = 8), face = "bold", size = 10),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#E5E5E5", linewidth = 0.4),
      plot.margin = margin(t = 10, r = 15, b = 10, l = 15)
    )
}

save_dual_figure <- function(plot_obj, filename_base, width = 9, height = 5.2) {
  png_path1 <- file.path(out_fig_dir, paste0(filename_base, ".png"))
  pdf_path1 <- file.path(out_fig_dir, paste0(filename_base, ".pdf"))
  png_path2 <- file.path(vault_fig_dir, paste0(filename_base, ".png"))
  pdf_path2 <- file.path(vault_fig_dir, paste0(filename_base, ".pdf"))
  
  ggsave(png_path1, plot_obj, width = width, height = height, dpi = 300)
  ggsave(pdf_path1, plot_obj, width = width, height = height)
  ggsave(png_path2, plot_obj, width = width, height = height, dpi = 300)
  ggsave(pdf_path2, plot_obj, width = width, height = height)
  
  cat(sprintf("Exported Dual Figure [%s] (.png & .pdf)\n", filename_base))
}

# ---------------------------------------------------------------------------
# FIGURE 1: Reconstructed Capacity Utilization (\mu_t)
# ---------------------------------------------------------------------------
p_fig1 <- ggplot(df_master %>% filter(year >= 1948), aes(x = year)) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "#8B0000", linewidth = 0.8) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  geom_line(aes(y = mu_m28a * 100, color = "Section 3.1 Aggregate Capital (M2.8a, No Break)"), linewidth = 1.1) +
  geom_line(aes(y = mu_m28b * 100, color = "Section 3.1 Aggregate Capital (M2.8b, With Breaks)"), linewidth = 0.9, linetype = "dashed") +
  geom_line(aes(y = mu_m219a * 100, color = "Section 3.2 Heterogeneous Capital (M2.19a, No Break)"), linewidth = 1.1, linetype = "dotdash") +
  geom_line(aes(y = mu_m224b * 100, color = "Section 3.2 Heterogeneous Capital (M2.24b, With Break)"), linewidth = 0.9, linetype = "longdash") +
  annotate("text", x = 1974.5, y = 112, label = "1973 Peak Anchor (mu = 100%)", 
           color = "#006400", size = 3.3, hjust = 0, fontface = "bold") +
  scale_x_continuous(breaks = seq(1930, 2020, 5), limits = c(1947, 2024)) +
  scale_y_continuous(breaks = seq(60, 120, 10), limits = c(60, 118)) +
  scale_color_manual(values = c(
    "Section 3.1 Aggregate Capital (M2.8a, No Break)" = "#1B365D",
    "Section 3.1 Aggregate Capital (M2.8b, With Breaks)" = "#5C768D",
    "Section 3.2 Heterogeneous Capital (M2.19a, No Break)" = "#008080",
    "Section 3.2 Heterogeneous Capital (M2.24b, With Break)" = "#D95F02"
  )) +
  labs(
    x = "Year",
    y = "Capacity Utilization (mu_t, %)"
  ) +
  apply_figure_theme() +
  guides(color = guide_legend(nrow = 2, byrow = TRUE))

save_dual_figure(p_fig1, "fig1_reconstructed_capacity_utilization")

# ---------------------------------------------------------------------------
# FIGURE 2: Transformation Elasticity (\theta_t) - Standalone & Zoomed Views
# ---------------------------------------------------------------------------

# Panel A: Section 3.1 Aggregate Capital Elasticity (Zoomed Scale: [0.30, 0.60])
p_fig2_s31 <- ggplot(df_master %>% filter(year >= 1949), aes(x = year)) +
  geom_line(aes(y = theta_m28a, color = "Aggregate Capital Preferred (M2.8a, No Break)"), linewidth = 1.1) +
  geom_line(aes(y = theta_m28b, color = "Aggregate Capital Break-Adjusted (M2.8b, With Breaks)"), linewidth = 0.9, linetype = "dashed") +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#006400", linewidth = 0.7) +
  scale_x_continuous(breaks = seq(1930, 2020, 5), limits = c(1948, 2024)) +
  scale_y_continuous(breaks = seq(0.30, 0.60, 0.05), limits = c(0.30, 0.60)) +
  scale_color_manual(values = c(
    "Aggregate Capital Preferred (M2.8a, No Break)" = "#1B365D",
    "Aggregate Capital Break-Adjusted (M2.8b, With Breaks)" = "#5C768D"
  )) +
  labs(
    x = "Year",
    y = "Transformation Elasticity (theta_t)"
  ) +
  apply_figure_theme()

# Panel B: Section 3.2 Heterogeneous Capital Elasticity (Spanning [-0.80, 1.10] with Knife-Edge theta = 1.00)
p_fig2_s32 <- ggplot(df_master %>% filter(year >= 1949), aes(x = year)) +
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "#8B0000", linewidth = 0.9) +
  geom_line(aes(y = theta_m219a, color = "Heterogeneous Capital Preferred (M2.19a, No Break)"), linewidth = 1.1) +
  geom_line(aes(y = theta_m224b, color = "Heterogeneous Capital Break-Adjusted (M2.24b, With Break)"), linewidth = 0.9, linetype = "dashed") +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#006400", linewidth = 0.7) +
  annotate("text", x = 1950, y = 1.05, label = "Overaccumulation Threshold (theta = 1.00)", 
           color = "#8B0000", fontface = "bold", size = 3.2, hjust = 0) +
  scale_x_continuous(breaks = seq(1930, 2020, 5), limits = c(1948, 2024)) +
  scale_y_continuous(breaks = seq(-0.80, 1.10, 0.20), limits = c(-0.80, 1.10)) +
  scale_color_manual(values = c(
    "Heterogeneous Capital Preferred (M2.19a, No Break)" = "#008080",
    "Heterogeneous Capital Break-Adjusted (M2.24b, With Break)" = "#D95F02"
  )) +
  labs(
    x = "Year",
    y = "Transformation Elasticity (theta_t)"
  ) +
  apply_figure_theme()

save_dual_figure(p_fig2_s31, "fig2_transformation_elasticity_aggregate_s31")
save_dual_figure(p_fig2_s32, "fig2_transformation_elasticity_heterogeneous_s32")

# ---------------------------------------------------------------------------
# FIGURE 3: State-Dependent Overaccumulation & Distributive Pressures (Stacked 2-Panel)
# ---------------------------------------------------------------------------
df_fig3 <- df_master %>% filter(year >= 1949)

p_fig3_top <- ggplot(df_fig3, aes(x = year)) +
  geom_line(aes(y = theta_m28a, color = "Transformation Elasticity (theta_t, M2.8a)"), linewidth = 1.1) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  annotate("text", x = 1952, y = 0.515, label = "Fordist Acceleration", color = "#1B365D", fontface = "bold", size = 3.2) +
  annotate("text", x = 1998, y = 0.490, label = "Post-Fordist Stagnation", color = "#8B0000", fontface = "bold", size = 3.2) +
  scale_x_continuous(breaks = seq(1930, 2020, 5), limits = c(1948, 2024)) +
  scale_y_continuous(breaks = seq(0.48, 0.52, 0.01), limits = c(0.48, 0.52)) +
  scale_color_manual(values = c("Transformation Elasticity (theta_t, M2.8a)" = "#1B365D")) +
  labs(
    x = NULL,
    y = "Transformation Elasticity (theta_t)"
  ) +
  apply_figure_theme() +
  theme(axis.text.x = element_blank(), axis.title.x = element_blank())

p_fig3_bottom <- ggplot(df_fig3, aes(x = year)) +
  geom_line(aes(y = w_eff_m224b, color = "Effective Wage Pressure ((1-iota) * omega)"), linewidth = 1.1) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  scale_x_continuous(breaks = seq(1930, 2020, 5), limits = c(1948, 2024)) +
  scale_y_continuous(breaks = seq(0.35, 0.55, 0.05), limits = c(0.35, 0.55)) +
  scale_color_manual(values = c("Effective Wage Pressure ((1-iota) * omega)" = "#D95F02")) +
  labs(
    x = "Year",
    y = "Effective Wage Pressure ((1-iota) * omega_t)"
  ) +
  apply_figure_theme()

p_fig3_stacked <- grid.arrange(p_fig3_top, p_fig3_bottom, ncol = 1, heights = c(1, 1))
save_dual_figure(p_fig3_stacked, "fig3_state_dependent_wage_pressure_stacked", width = 9, height = 7.5)

# ---------------------------------------------------------------------------
# FIGURE 4: Heterogeneous Mechanization & Asset Composition (\kappa_t vs p^\kappa_t)
# ---------------------------------------------------------------------------
# Stacked 2-Panel Layout for Mechanization Gap \kappa_t and Relative Price Ratio p^\kappa_t
df_fig4 <- df_master %>% filter(year >= 1931)

p_fig4_top <- ggplot(df_fig4, aes(x = year)) +
  geom_line(aes(y = kappa_t, color = "Capital Composition / Mechanization Gap (kappa_t = k_ME - k_NRC)"), linewidth = 1.1) +
  geom_vline(xintercept = 1958, linetype = "dashed", color = "#8B0000", linewidth = 0.7) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#006400", linewidth = 0.7) +
  annotate("text", x = 1959, y = -0.40, label = "1958 Break", color = "#8B0000", size = 3.0, fontface = "bold", hjust = 0) +
  scale_x_continuous(breaks = seq(1930, 2020, 5), limits = c(1930, 2024)) +
  scale_y_continuous(breaks = seq(-1.3, -0.2, 0.2), limits = c(-1.3, -0.2)) +
  scale_color_manual(values = c("Capital Composition / Mechanization Gap (kappa_t = k_ME - k_NRC)" = "#1B365D")) +
  labs(
    x = NULL,
    y = "Capital Composition Ratio (kappa_t)"
  ) +
  apply_figure_theme() +
  theme(axis.text.x = element_blank(), axis.title.x = element_blank())

p_fig4_bottom <- ggplot(df_fig4, aes(x = year)) +
  geom_line(aes(y = p_rel, color = "Relative Capital Asset Price (p_t^kappa = P_ME / P_NRC)"), linewidth = 1.1) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#006400", linewidth = 0.7) +
  scale_x_continuous(breaks = seq(1930, 2020, 5), limits = c(1930, 2024)) +
  scale_y_continuous(breaks = seq(-0.3, 1.2, 0.3), limits = c(-0.3, 1.2)) +
  scale_color_manual(values = c("Relative Capital Asset Price (p_t^kappa = P_ME / P_NRC)" = "#008080")) +
  labs(
    x = "Year",
    y = "Relative Price Ratio (p_t^kappa)"
  ) +
  apply_figure_theme()

p_fig4_stacked <- grid.arrange(p_fig4_top, p_fig4_bottom, ncol = 1, heights = c(1, 1))
save_dual_figure(p_fig4_stacked, "fig4_heterogeneous_mechanization_and_prices_stacked", width = 9, height = 7.5)

cat("========================================================================\n")
cat("Master Figure Generation Complete! All 4 figures generated successfully.\n")
cat("========================================================================\n")
