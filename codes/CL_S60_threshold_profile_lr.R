#!/usr/bin/env Rscript

# CL_S60_threshold_profile_lr.R
# Computes and plots the Hansen (2000) Profile Likelihood Ratio LR_1(gamma)
# for the preferred Chilean Threshold Model (omega_gross_lag) across candidate thresholds gamma of Z_t.

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(cointReg)
  library(dplyr)
  library(readr)
  library(ggplot2)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(repo_root)

cpr_imols_path <- file.path(repo_root, ".agents/skills/cpr-im-ols/scripts/cpr_imols_estimator.R")
source(cpr_imols_path)

panel_path <- file.path(repo_root, "data/staged/ch2_panel_chile_with_prices.csv")
df_full <- read_csv(panel_path, show_col_types = FALSE)

# 1. Filter estimation sample (1942-2010)
df <- df_full %>%
  filter(year >= 1942, year <= 2010) %>%
  mutate(
    y_t             = log(GDP_real),
    k_NR            = log(K_NR),
    k_ME            = log(K_ME),
    kappa_t         = k_ME - k_NR,
    omega_gross_lag = lag(omega_gross),
    p_kappa         = p_kappa_rer
  ) %>%
  filter(!is.na(y_t), !is.na(k_NR), !is.na(kappa_t), !is.na(omega_gross_lag), 
         !is.na(p_kappa), !is.na(SolvR_M0), !is.na(imbalance_level)) %>%
  arrange(year)

# Standardize threshold variables and form Z_t (p = 0.2)
df$S_tilde <- scale(df$SolvR_M0)[, 1]
df$M_tilde <- scale(df$imbalance_level)[, 1]
p_weight <- 0.2
df$Z_t <- p_weight * df$M_tilde + (1 - p_weight) * df$S_tilde

# FWL Orthogonalization for relative prices
fwl_fit <- lm(p_kappa ~ k_NR + kappa_t, data = df)
df$p_tilde <- residuals(fwl_fit)

# 2. Grid Search for Profile Likelihood Ratio
# 15% to 85% quantile evaluation domain
gamma_grid <- sort(unique(df$Z_t[df$Z_t >= quantile(df$Z_t, 0.15) & df$Z_t <= quantile(df$Z_t, 0.85)]))

ssr_vals <- numeric(length(gamma_grid))
n_obs <- nrow(df)

y_mat      <- as.matrix(df$y_t)
x_base_sub <- as.matrix(df %>% select(k_NR, kappa_t))
deter_sub  <- matrix(1, nrow = n_obs, ncol = 1)
colnames(deter_sub) <- "intercept"

for (i in seq_along(gamma_grid)) {
  g <- gamma_grid[i]
  D_g <- ifelse(df$Z_t <= g, 1, 0)
  
  df_temp <- df %>%
    mutate(
      dist_k  = omega_gross_lag * kappa_t,
      k_D     = kappa_t * D_g,
      dk_D    = dist_k * D_g
    )
  
  x_temp <- df_temp %>% select(k_NR, kappa_t, dist_k, k_D, dk_D, p_tilde) %>% as.matrix()
  
  # Fit CMPR IM-OLS
  fit_g <- cointRegIM_CMPR(x = x_temp, y = y_mat, deter = deter_sub, x_base = x_base_sub, selector = c(1,2))
  res_g <- fit_g$residuals
  ssr_vals[i] <- sum(res_g^2)
}

min_idx <- which.min(ssr_vals)
opt_gamma <- gamma_grid[min_idx]
min_ssr <- ssr_vals[min_idx]
sigma2_hat <- min_ssr / n_obs

# Profile LR sequence: LR_1(gamma) = (SSR(gamma) - SSR(gamma_hat)) / sigma2_hat
profile_lr <- (ssr_vals - min_ssr) / sigma2_hat

df_lr <- data.frame(
  gamma = gamma_grid,
  ssr = ssr_vals,
  profile_lr = profile_lr
)

# 95% Critical value
cv95 <- -2 * log(1 - sqrt(0.95)) # 7.352

# Confidence Interval
ci_vals <- df_lr$gamma[df_lr$profile_lr <= cv95]
ci_lower <- min(ci_vals)
ci_upper <- max(ci_vals)

cat(sprintf("Optimal threshold: gamma = %.3f, SSR = %.4f\n", opt_gamma, min_ssr))
cat(sprintf("95%% Confidence Interval: [%.3f, %.3f]\n", ci_lower, ci_upper))

# 3. Publication Plot
theme_pe <- function() {
  theme_classic(base_size = 11) %+replace%
    theme(
      plot.title       = element_blank(),
      plot.subtitle    = element_blank(),
      panel.grid.major = element_line(color = "gray90", linewidth = 0.4),
      panel.grid.minor = element_blank(),
      axis.title.x     = element_text(face = "bold", color = "black", margin = margin(t = 8), size = 11),
      axis.title.y     = element_text(face = "bold", color = "black", margin = margin(r = 8), size = 11, angle = 90),
      axis.text        = element_text(color = "black", size = 10),
      axis.line        = element_line(color = "#2C3E50", linewidth = 0.6),
      axis.ticks       = element_line(color = "#2C3E50", linewidth = 0.6),
      plot.margin      = margin(t = 10, r = 15, b = 10, l = 10)
    )
}

p_lr <- ggplot(df_lr, aes(x = gamma, y = profile_lr)) +
  # 95% CI Shaded Region
  annotate("rect", xmin = ci_lower, xmax = ci_upper, ymin = 0, ymax = cv95, fill = "#CBD5E1", alpha = 0.5) +
  # Profile LR Curve
  geom_line(color = "#1A365D", linewidth = 1.1) +
  # 95% Critical Value Line
  geom_hline(yintercept = cv95, linetype = "dashed", color = "#DC2626", linewidth = 0.8) +
  annotate("text", x = min(gamma_grid) + 0.05, y = cv95 + 0.75, 
           label = sprintf("95%% Critical Value (c = %.2f)", cv95), 
           color = "#DC2626", fontface = "bold", size = 3.8, hjust = 0) +
  # Identified Minimum Line
  geom_vline(xintercept = opt_gamma, linetype = "dotted", color = "black", linewidth = 0.8) +
  annotate("text", x = opt_gamma + 0.04, y = 2.0, 
           label = paste0("Threshold~hat(gamma)==", sprintf("%.3f", opt_gamma)), 
           parse = TRUE, color = "black", fontface = "bold", size = 4.0, hjust = 0) +
  scale_x_continuous(
    name = "Threshold",
    breaks = seq(-1.5, 1.5, by = 0.25)
  ) +
  scale_y_continuous(
    name = expression(paste("Profile Likelihood Ratio ", LR[1](gamma))),
    limits = c(0, max(profile_lr, na.rm = TRUE) * 1.05)
  ) +
  theme_pe()

# 4. Save Artifacts
fig_dir   <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "figures")
out_dir   <- file.path(repo_root, "output", "CL", "BOP_BINDING")
fig_vault <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "figures")

for (d in c(fig_dir, out_dir, fig_vault)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  # Standardized new taxonomy
  ggsave(file.path(d, "fig_cl_results_threshold_profile_lr.pdf"), plot = p_lr, width = 8.8, height = 5.0, device = cairo_pdf)
  ggsave(file.path(d, "fig_cl_results_threshold_profile_lr.png"), plot = p_lr, width = 8.8, height = 5.0, dpi = 300)
  # Also maintain legacy name for compatibility
  ggsave(file.path(d, "CL_fig_profile_lr.pdf"), plot = p_lr, width = 8.8, height = 5.0, device = cairo_pdf)
  ggsave(file.path(d, "CL_fig_profile_lr.png"), plot = p_lr, width = 8.8, height = 5.0, dpi = 300)
}

cat("Successfully generated fig_cl_results_threshold_profile_lr.pdf and CL_fig_profile_lr.pdf across all target directories!\n")
