#!/usr/bin/env Rscript

# COMMON_S31_capital_aggregation_conceptual_audit.R
# Stage 2: Dimensionality, Additivity, and Composition Conceptual Audit
# Analyzes simple sum K_cap = K_ME + K_NRC dimensionality, base-year price weighting drift, and chained quantity non-additivity.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_csv <- file.path(repo_root, "output", "gpim_baseline_components_long.csv")
out_dir   <- file.path(repo_root, "output")
fig_dir   <- file.path(out_dir, "figures")
metrics_csv <- file.path(out_dir, "aggregation_adequacy_metrics.csv")
pdf_out   <- file.path(fig_dir, "fig_aggregation_dimensionality.pdf")
png_out   <- file.path(fig_dir, "fig_aggregation_dimensionality.png")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("Stage 2: Dimensionality & Additivity Conceptual Aggregation Audit\n")
cat("========================================================================\n")

if (!file.exists(input_csv)) {
  stop("Input file missing: ", input_csv)
}

df <- read.csv(input_csv, stringsAsFactors = FALSE)
df <- df[order(df$year), ]

# Filter finite rows for plotting
df_plot <- df[is.finite(df$k_cap) & is.finite(df$k_NRC), ]

# 1. Non-Additivity & Residual Analysis
df$K_sum <- df$K_ME + df$K_NRC
df$K_residual <- df$K_cap - df$K_sum
df$pct_residual <- (df$K_residual / df$K_cap) * 100

# 2. Composition Share s_ME and Taylor Approximation: k_cap ≈ k_NRC + s_ME * tau
df$s_ME <- df$K_ME / df$K_sum
mean_s_ME <- mean(df$s_ME, na.rm = TRUE)

df$k_cap_approx <- df$k_NRC + mean_s_ME * df$tau
df$taylor_residual <- df$k_cap - df$k_cap_approx

# 3. Compute Aggregation Metrics
cor_tau_kcap <- cor(df$tau, df$k_cap, use = "complete.obs")
cor_tau_knrc <- cor(df$tau, df$k_NRC, use = "complete.obs")
var_residual <- var(df$taylor_residual, na.rm = TRUE)
var_kcap     <- var(df$k_cap, na.rm = TRUE)

metrics <- data.frame(
  Metric = c(
    "Mean_Machinery_Share_s_ME",
    "Max_NonAdditivity_Pct_Residual",
    "Mean_NonAdditivity_Pct_Residual",
    "Cor_Tau_vs_k_cap",
    "Cor_Tau_vs_k_NRC",
    "Variance_Ratio_TaylorResidual_to_k_cap",
    "Full_Sample_N"
  ),
  Value = c(
    mean_s_ME,
    max(abs(df$pct_residual), na.rm = TRUE),
    mean(abs(df$pct_residual), na.rm = TRUE),
    cor_tau_kcap,
    cor_tau_knrc,
    var_residual / var_kcap,
    nrow(df)
  )
)

write.csv(metrics, metrics_csv, row.names = FALSE)
cat("Adequacy metrics saved to:", metrics_csv, "\n")

# 4. Generate Diagnostic Plot
pdf(pdf_out, width = 10, height = 7)
par(mfrow = c(2, 1), mar = c(4, 4, 3, 2))

y_lims <- range(c(df_plot$k_cap, df_plot$k_NRC), na.rm = TRUE)

# Plot 1: Capital Composition tau_t vs. Aggregate Scale k_cap
plot(df_plot$year, df_plot$k_cap, type = "l", col = "navy", lwd = 2,
     main = "Aggregate Capital Scale (k_cap) vs. Capital Composition Ratio (tau = k_ME - k_NRC)",
     xlab = "Year", ylab = "Log Scale (k_cap)", ylim = y_lims)
lines(df_plot$year, df_plot$k_NRC, col = "firebrick", lwd = 2, lty = 2)
legend("topleft", legend = c("Log Total Capital (k_cap)", "Log Structures Footprint (k_NRC)"),
       col = c("navy", "firebrick"), lty = c(1, 2), lwd = 2, bty = "n")

# Plot 2: Taylor Approximation Drift (Non-Additivity & Composition Distortion)
plot(df_plot$year, df_plot$taylor_residual, type = "l", col = "forestgreen", lwd = 2,
     main = "Compositional Drift & Taylor Aggregation Residual [k_cap - (k_NRC + s_ME * tau)]",
     xlab = "Year", ylab = "Log Deviation Residual")
abline(h = 0, lty = 3, col = "gray40")

dev.off()

# Save PNG copy
png(png_out, width = 1000, height = 700, res = 100)
par(mfrow = c(2, 1), mar = c(4, 4, 3, 2))
plot(df_plot$year, df_plot$k_cap, type = "l", col = "navy", lwd = 2,
     main = "Aggregate Capital Scale (k_cap) vs. Capital Composition Ratio (tau = k_ME - k_NRC)",
     xlab = "Year", ylab = "Log Scale (k_cap)", ylim = y_lims)
lines(df_plot$year, df_plot$k_NRC, col = "firebrick", lwd = 2, lty = 2)
legend("topleft", legend = c("Log Total Capital (k_cap)", "Log Structures Footprint (k_NRC)"),
       col = c("navy", "firebrick"), lty = c(1, 2), lwd = 2, bty = "n")

plot(df_plot$year, df_plot$taylor_residual, type = "l", col = "forestgreen", lwd = 2,
     main = "Compositional Drift & Taylor Aggregation Residual [k_cap - (k_NRC + s_ME * tau)]",
     xlab = "Year", ylab = "Log Deviation Residual")
abline(h = 0, lty = 3, col = "gray40")
dev.off()

cat("Diagnostic figures saved to:\n", pdf_out, "\n", png_out, "\n")
cat("========================================================================\n")
