# 03_US_theta_figures.R
# Produces two figures from US_theta_DOLS_results.rds:
#   Figure 1: US_theta_t_by_sample.png — θ̂_t over time by sample
#   Figure 2: US_mu_hat_by_sample.png  — μ̂_t over time by sample

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
results_dir <- file.path(REPO, "AR_Corridor/04_estimation_outputs/stable_results")
out_dir     <- file.path(REPO, "AR_Corridor/04_estimation_outputs/stable_results")

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("[figures] ggplot2 not available. Install with: install.packages('ggplot2')")
}
suppressPackageStartupMessages(library(ggplot2))

# Load results
rds_path <- file.path(results_dir, "US_theta_DOLS_results.rds")
if (!file.exists(rds_path)) {
  stop(sprintf("[figures] RDS not found: %s\n  Run 01_US_theta_DOLS.R first.", rds_path))
}

rd <- readRDS(rds_path)
series   <- rd$series
bm_year  <- rd$benchmark_year

cat(sprintf("[figures] Loaded: %s\n", rds_path))

# ============================================================
# Prepare combined data frame
# ============================================================

sample_labels <- c(
  full     = "Full sample",
  pre1974  = "Pre-1974 (≤1973)",
  post1973 = "Post-1973 (≥1974)"
)

sample_colors <- c(
  "Full sample"         = "#1f77b4",
  "Pre-1974 (≤1973)"    = "#2ca02c",
  "Post-1973 (≥1974)"   = "#d62728"
)

df_theta <- data.frame()
df_mu    <- data.frame()

for (nm in names(series)) {
  s <- series[[nm]]
  label <- sample_labels[[nm]]

  df_theta <- rbind(df_theta, data.frame(year = s$year, value = s$theta_t, sample = label))
  df_mu    <- rbind(df_mu,    data.frame(year = s$year, value = s$mu_hat,  sample = label))
}

# ============================================================
# FIGURE 1: θ̂_t by sample
# ============================================================

p_theta <- ggplot(df_theta, aes(x = year, y = value, color = sample)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray40", linewidth = 0.6) +
  geom_vline(xintercept = 1973.5, linetype = "dotted", color = "gray50", linewidth = 0.5) +
  annotate("text", x = 1974, y = max(df_theta$value, na.rm = TRUE) * 0.95,
           label = "1973/74 break", hjust = 0, size = 3, color = "gray40") +
  annotate("text", x = min(df_theta$year) + 2, y = 1.02,
           label = "θ = 1 (Harrodian)", hjust = 0, size = 3, color = "gray40") +
  scale_color_manual(values = sample_colors, name = "Sample") +
  labs(
    x = "Year",
    y = expression(hat(theta)[t]),
    title = "US Transformation Elasticity θ̂_t by Sample",
    subtitle = sprintf("DOLS, benchmark year = %d", bm_year)
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "bottom"
  )

ggsave(file.path(out_dir, "US_theta_t_by_sample.png"), p_theta,
       width = 10, height = 6, dpi = 150)
cat("[figures] Written: US_theta_t_by_sample.png\n")

# ============================================================
# FIGURE 2: μ̂_t by sample
# ============================================================

p_mu <- ggplot(df_mu, aes(x = year, y = value, color = sample)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray40", linewidth = 0.6) +
  geom_vline(xintercept = 1973.5, linetype = "dotted", color = "gray50", linewidth = 0.5) +
  annotate("text", x = 1974, y = max(df_mu$value, na.rm = TRUE) * 0.95,
           label = "1973/74 break", hjust = 0, size = 3, color = "gray40") +
  annotate("text", x = min(df_mu$year) + 2, y = 1.02,
           label = "μ = 1 (benchmark)", hjust = 0, size = 3, color = "gray40") +
  scale_color_manual(values = sample_colors, name = "Sample") +
  labs(
    x = "Year",
    y = expression(hat(mu)[t]),
    title = "US Capacity Utilization Index μ̂_t by Sample",
    subtitle = sprintf("DOLS residual, benchmark year = %d (μ = 1 by construction)", bm_year)
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "bottom"
  )

ggsave(file.path(out_dir, "US_mu_hat_by_sample.png"), p_mu,
       width = 10, height = 6, dpi = 150)
cat("[figures] Written: US_mu_hat_by_sample.png\n")

cat("\n=== Figures complete ===\n")
