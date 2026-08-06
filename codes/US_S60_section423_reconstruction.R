#!/usr/bin/env Rscript

# US_S60_section423_reconstruction.R
# ---------------------------------------------------------------------------
# Section 4.2.3 Capacity Reconstruction & Visualizations Engine
#
# Model: M2.5a (Private Core Capital + Shaikh-Tonak Tier 2 Wage Share + 
#               Financialization Overhead Retention (1 - iota) + No Break)
# Protocol: D03 (1973 FRB Survey Peak Benchmark Pinch-Year Anchor: mu_1973 = 1.00)
# Outputs: 
#   - CSV Series: output/US/S60_CAPACITY_RECOVERY/csv/s60_section423_series.csv
#   - Figures (.png and .pdf):
#     * Fig 4: Reconstructed Capacity Utilization (mu_t)
#     * Fig 6: State-Dependent Transformation Elasticity (theta_t) & Overaccumulation
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(cointReg)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
s50_dir   <- file.path(repo_root, "output", "US", "S50_SECTION31_IMOLS")
s41_csv   <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data", "s41_extended_capital_panel.csv")
s29f_csv  <- file.path(repo_root, "output", "US", "S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION", "csv", "S29F_shaikh_tonak_wage_share_panel.csv")
fred_csv  <- file.path(repo_root, "output", "US", "S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION", "csv", "fred_annual_ad_components_panel.csv")

out_dir   <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY")
csv_dir   <- file.path(out_dir, "csv")
rds_dir   <- file.path(out_dir, "rds")
fig_dir   <- file.path(out_dir, "figures")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S60: Section 4.2.3 Capacity Recovery & Visualization Engine (Model M2.5a)\n")
cat("========================================================================\n")

# 1. Load fitted models
models_path <- file.path(s50_dir, "rds", "s50_fitted_models.rds")
if (!file.exists(models_path)) {
  stop("Fitted models file not found at: ", models_path)
}
fs <- readRDS(models_path)

if (!"M2.5a" %in% names(fs)) {
  stop("Model M2.5a not found in s50_fitted_models.rds. Available: ", paste(names(fs), collapse = ", "))
}

m_m25a <- fs[["M2.5a"]]
cat("Loaded fitted Model M2.5a successfully.\n")

# 2. Reconstruct design panel
df_cap <- read.csv(s41_csv, stringsAsFactors = FALSE)
df_st  <- read.csv(s29f_csv, stringsAsFactors = FALSE)
df_fred <- read.csv(fred_csv, stringsAsFactors = FALSE)

df <- df_cap[, c("year", "k_cap", "y_t", "omega_ST_Tier2_lag1")]
df_fred_sub <- df_fred[, c("year", "GDP_real")]

df <- merge(df, df_fred_sub, by = "year", all.x = TRUE)

df <- df[df$year >= 1929 & df$year <= 2024, ]
df <- df[order(df$year), ]

df$iota_t <- df_cap$IPP_share_capital_plus_IPP[match(df$year, df_cap$year)]
df$iota_lag1 <- dplyr::lag(df$iota_t, 1L)

req_cols <- c("year", "k_cap", "y_t", "omega_ST_Tier2_lag1", "iota_lag1", "GDP_real")
df_clean <- df[complete.cases(df[, req_cols]), ]

cat(sprintf("Effective Sample Window: %d - %d (T = %d observations)\n", 
            min(df_clean$year), max(df_clean$year), nrow(df_clean)))

# 3. Calculate Effective Wage Share & Transformation Elasticity theta_t for M2.5a
coefs <- m_m25a$fit$theta
d_k <- ncol(m_m25a$deter)
beta_k <- coefs[d_k + 1]       # Base capital elasticity
theta_1 <- coefs[d_k + 2]      # FWL interaction coefficient

w_eff <- df_clean$omega_ST_Tier2_lag1 * (1 - df_clean$iota_lag1)
w_eff0 <- w_eff[1]
w_eff_c <- w_eff - w_eff0

k_vec <- df_clean$k_cap
inter_raw <- k_vec * w_eff_c

# FWL slope a1 from regressing inter_raw on k_vec
aux_fit <- lm(inter_raw ~ k_vec)
a1 <- coef(aux_fit)[2]

# Total transformation elasticity: theta_t = (beta_k - theta_1 * a1 - theta_1 * w_eff0) + theta_1 * w_eff
theta_base <- beta_k - theta_1 * a1 - theta_1 * w_eff0
theta_t <- theta_base + theta_1 * w_eff

# 4. Apply Protocol D03 Level Anchoring at 1973 (mu_1973 = 1.00)
idx_1973 <- which(df_clean$year == 1973)
if (length(idx_1973) == 0) {
  stop("1973 pinch year not found in data!")
}

y_obs <- df_clean$y_t
y_1973 <- y_obs[idx_1973]
k_1973 <- k_vec[idx_1973]

# Protocol D03 Direct Evaluation: y^p_t = y_1973 + theta_t * (k_t - k_1973)
y_p_t <- y_1973 + theta_t * (k_vec - k_1973)
ln_mu_t <- y_obs - y_p_t
mu_t <- exp(ln_mu_t)

# Validate anchor condition: mu_1973 == 1.000000
anchor_err <- abs(mu_t[idx_1973] - 1.00)
cat(sprintf("Protocol D03 Anchor Verification: mu_1973 = %.15f (Abs Error: %.2e) -> %s\n", 
            mu_t[idx_1973], anchor_err, if (anchor_err < 1e-12) "PASS" else "FAIL"))

df_results <- data.frame(
  year                  = df_clean$year,
  y_obs                 = y_obs,
  k_cap                 = k_vec,
  omega_ST_Tier2_lag1   = df_clean$omega_ST_Tier2_lag1,
  iota_lag1             = df_clean$iota_lag1,
  w_effective           = w_eff,
  theta_t               = theta_t,
  y_p_t                 = y_p_t,
  mu_t                  = mu_t
)

# Export CSV
csv_path <- file.path(csv_dir, "s60_section423_series.csv")
write.csv(df_results, csv_path, row.names = FALSE)
cat("Saved series ledger to:", csv_path, "\n")

# Save RDS
saveRDS(df_results, file.path(rds_dir, "s60_section423_series.rds"))

# 5. Generate Visualizations (Dual PNG & PDF Exports)

# ----------------------------------------------------------------------
# FIGURE 4: Reconstructed Capacity Utilization (mu_t)
# ----------------------------------------------------------------------
p_fig4 <- ggplot(df_results, aes(x = year, y = mu_t * 100)) +
  geom_line(color = "#1B365D", linewidth = 1.1) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "#8B0000", linewidth = 0.8) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  annotate("text", x = 1974, y = 112, label = "1973 FRB Survey Peak Benchmark Anchor (mu = 100%)", 
           color = "#006400", size = 3.3, hjust = 0, fontface = "bold") +
  annotate("rect", xmin = 1929, xmax = 1973, ymin = -Inf, ymax = Inf, fill = "#1B365D", alpha = 0.04) +
  annotate("rect", xmin = 1974, xmax = 2024, ymin = -Inf, ymax = Inf, fill = "#8B0000", alpha = 0.04) +
  annotate("text", x = 1950, y = 62, label = "Fordist Accumulation Era\n(1929-1973)", 
           color = "#1B365D", fontface = "bold", size = 3.5) +
  annotate("text", x = 1998, y = 62, label = "Post-Fordist Restructuring Era\n(1974-2024)", 
           color = "#8B0000", fontface = "bold", size = 3.5) +
  scale_x_continuous(limits = c(1929, 2024), breaks = seq(1930, 2020, 10)) +
  scale_y_continuous(limits = c(25, 125), breaks = seq(30, 120, 15)) +
  labs(
    title = "Figure 4: Reconstructed U.S. Corporate Capacity Utilization (mu_t, 1929-2024)",
    subtitle = "Model M2.5a (IM-OLS) Level-Anchored at 1973 FRB Survey Peak Benchmark (mu_1973 = 100%)",
    x = "Year",
    y = "Capacity Utilization (mu_t, %)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12, color = "#111111"),
    plot.subtitle = element_text(face = "italic", size = 9.5, color = "#444444"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E5E5E5")
  )

ggsave(file.path(fig_dir, "fig4_reconstructed_capacity_utilization.png"), p_fig4, width = 9, height = 5.5, dpi = 300)
ggsave(file.path(fig_dir, "fig4_reconstructed_capacity_utilization.pdf"), p_fig4, width = 9, height = 5.5)
cat("Saved Figure 4 (.png and .pdf)\n")

# ----------------------------------------------------------------------
# FIGURE 6: Transformation Elasticity & Overaccumulation Regime (2-Panel)
# ----------------------------------------------------------------------
library(gridExtra)

# Top Panel: Global Overaccumulation Context (0.40 to 1.10)
p_fig6_top <- ggplot(df_results, aes(x = year, y = theta_t)) +
  annotate("rect", xmin = 1929, xmax = 2024, ymin = 0.40, ymax = 1.00, fill = "#1B365D", alpha = 0.08) +
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "#8B0000", linewidth = 0.9) +
  annotate("text", x = 1931, y = 1.04, label = "Overcapacity Threshold (theta = 1.00)", 
           color = "#8B0000", fontface = "bold", size = 3.3, hjust = 0) +
  annotate("text", x = 1960, y = 0.70, label = "Capital Overaccumulation Regime (theta_t < 1.00 throughout)", 
           color = "#1B365D", fontface = "bold.italic", size = 3.5) +
  geom_line(color = "#1B365D", linewidth = 1.0) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#8B0000", linewidth = 0.7) +
  scale_x_continuous(limits = c(1929, 2024), breaks = seq(1930, 2020, 10)) +
  scale_y_continuous(limits = c(0.40, 1.10), breaks = seq(0.40, 1.10, 0.20)) +
  labs(
    title = "Figure 6: State-Dependent Transformation Elasticity (theta_t, 1929-2024)",
    subtitle = "Panel A: Global Context Relative to Overcapacity Threshold (theta = 1.00)",
    x = NULL,
    y = "Transformation Elasticity (theta_t)"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    plot.title = element_text(face = "bold", size = 11, color = "#111111"),
    plot.subtitle = element_text(face = "italic", size = 9, color = "#444444"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E5E5E5")
  )

# Bottom Panel: Zoomed Historical Dynamics (0.42 to 0.51)
p_fig6_bottom <- ggplot(df_results, aes(x = year, y = theta_t)) +
  geom_line(color = "#1B365D", linewidth = 1.1) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "#8B0000", linewidth = 0.8) +
  annotate("text", x = 1974, y = 0.505, label = "1973 Institutional Shift", color = "#8B0000", fontface = "bold", size = 3.0, hjust = 0) +
  annotate("rect", xmin = 1929, xmax = 1973, ymin = -Inf, ymax = Inf, fill = "#1B365D", alpha = 0.04) +
  annotate("rect", xmin = 1974, xmax = 2024, ymin = -Inf, ymax = Inf, fill = "#8B0000", alpha = 0.04) +
  annotate("text", x = 1950, y = 0.425, label = "Fordism: High Dynamism", color = "#1B365D", fontface = "bold", size = 3.2) +
  annotate("text", x = 1998, y = 0.425, label = "Post-Fordism: Secular Decline", color = "#8B0000", fontface = "bold", size = 3.2) +
  scale_x_continuous(limits = c(1929, 2024), breaks = seq(1930, 2020, 10)) +
  scale_y_continuous(limits = c(0.42, 0.51), breaks = seq(0.42, 0.50, 0.02)) +
  labs(
    subtitle = "Panel B: Zoomed View of Historical Trajectory Across Accumulation Eras",
    x = "Year",
    y = "Transformation Elasticity (theta_t)"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    plot.subtitle = element_text(face = "italic", size = 9, color = "#444444"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E5E5E5")
  )

p_fig6_combined <- grid.arrange(p_fig6_top, p_fig6_bottom, ncol = 1, heights = c(1, 1))

ggsave(file.path(fig_dir, "fig6_transformation_elasticity_overaccumulation.png"), p_fig6_combined, width = 9, height = 7.5, dpi = 300)
ggsave(file.path(fig_dir, "fig6_transformation_elasticity_overaccumulation.pdf"), p_fig6_combined, width = 9, height = 7.5)
cat("Saved Figure 6 2-Panel Layout (.png and .pdf)\n")

cat("S60 Reconstruction Pipeline Completed Successfully!\n")
