#!/usr/bin/env Rscript

# Chapter 2 - Golden Age Capacity Path Reconstruction & Comparison
# Reconstructs potential capacity output (yp) and latent capacity utilization (mu)
# for Specification B (composition-mediated using A03 growth-law integration),
# Specification A (Shaikh-style), and HP Filter decomposition using total output (real GDP).
# Plots time paths of utilization, elasticities (theta_total, theta_ME, theta_NRC), and wage share.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
panel_path <- file.path(repo_root, "output", "S34R_B_cpr_realigned_design_gate", "csv", "S34R_B_repaired_augmented_panel.csv")

if (!file.exists(panel_path)) {
  stop("S34R-B panel not found. Please run the S34R-B gate script first.", call. = FALSE)
}

panel <- read.csv(panel_path, stringsAsFactors = FALSE, check.names = FALSE)
panel <- panel[order(panel$year), ]

# Load nominal GDP and deflator from FRED to construct true Real GDP (total output of the whole economy)
gdpa_path <- file.path(repo_root, "data", "raw", "US", "fred", "GDPA.csv")
defl_path <- file.path(repo_root, "data", "raw", "US", "fred", "A191RD3A086NBEA.csv")

if (!file.exists(gdpa_path) || !file.exists(defl_path)) {
  stop("Raw FRED GDP or deflator files not found.", call. = FALSE)
}

gdpa <- read.csv(gdpa_path, stringsAsFactors = FALSE)
defl <- read.csv(defl_path, stringsAsFactors = FALSE)

# Merge by year
gdp_merged <- merge(gdpa[, c("year", "value")], defl[, c("year", "value")], by = "year", suffixes = c("_nominal", "_deflator"))

# Real GDP in millions of 2017 chained dollars
# Nominal GDP (value_nominal) is in billions. Deflator is index 2017=100.
# Real GDP = Nominal GDP / (Deflator / 100) * 1000
gdp_merged$real_gdp_val <- (gdp_merged$value_nominal / (gdp_merged$value_deflator / 100)) * 1000
gdp_merged$y_total <- log(gdp_merged$real_gdp_val)

# Merge total output into panel
panel <- merge(panel, gdp_merged[, c("year", "y_total")], by = "year", all.x = TRUE)

# Calculate capital stock growth rates on the full panel
panel$g_NRC <- c(NA, diff(panel$k_NRC))
panel$g_ME <- c(NA, diff(panel$k_ME))

# Model 1: Specification B (Composition-Mediated with K_NRC and tau)
# FM-OLS coefficients for Golden Age (1945-1973):
beta_k_B <- 0.23784
beta_tau_B <- 0.31207
beta_inter_B <- -1.02937

# Calculate time-varying elasticities for Specification B
panel$theta_ME_t <- beta_tau_B + beta_inter_B * panel$omega_NFC_centered
panel$theta_NRC_t <- beta_k_B - panel$theta_ME_t

# Reconstruct potential output growth rate using the A03 composition identity
panel$g_Yp_B <- panel$theta_NRC_t * panel$g_NRC + panel$theta_ME_t * panel$g_ME

# Integrate potential output growth rates anchored at 1973 (mu_1973 = 1.0) using total output
idx_1973 <- which(panel$year == 1973)
panel$yp_spec_B <- NA
panel$yp_spec_B[idx_1973] <- panel$y_total[idx_1973]

# Integrate forward from 1973
for (i in (idx_1973 + 1):nrow(panel)) {
  if (!is.na(panel$g_Yp_B[i])) {
    panel$yp_spec_B[i] <- panel$yp_spec_B[i-1] + panel$g_Yp_B[i]
  }
}

# Integrate backward from 1973
for (i in (idx_1973 - 1):1) {
  if (!is.na(panel$g_Yp_B[i+1])) {
    panel$yp_spec_B[i] <- panel$yp_spec_B[i+1] - panel$g_Yp_B[i+1]
  }
}

# Subset the panel to the Golden Age window (1945-1973) for comparison
ga_data <- subset(panel, year >= 1945 & year <= 1973)

# Model 2: True Shaikh-Style (y_t regressed on k_Kcap_centered ONLY, no distribution terms)
# estimated dynamically over the Golden Age window on NFC data
library(cointReg)
y <- ga_data$y_t
x <- as.matrix(ga_data$k_Kcap_centered)
deter <- rep(1, length(y))
fit_shaikh <- cointReg::cointRegFM(x = x, y = y, deter = deter, bandwidth = "nw")

alpha_A <- fit_shaikh$theta[1]
beta_k_A <- fit_shaikh$theta[2]

ga_data$yp_spec_A <- alpha_A + beta_k_A * ga_data$k_Kcap_centered

# Model 3: HP Filter (applied directly to total output y_total, lambda = 100)
hp_filter <- function(y, lambda = 100) {
  n <- length(y)
  I <- diag(n)
  D <- matrix(0, nrow = n - 2, ncol = n)
  for (i in 1:(n - 2)) {
    D[i, i] <- 1
    D[i, i + 1] <- -2
    D[i, i + 2] <- 1
  }
  trend <- solve(I + lambda * t(D) %*% D, y)
  cycle <- y - trend
  return(list(trend = as.vector(trend), cycle = as.vector(cycle)))
}

hp_res <- hp_filter(ga_data$y_total, lambda = 100)
ga_data$yp_spec_HP <- hp_res$trend
ga_data$ln_mu_spec_HP <- hp_res$cycle
ga_data$mu_spec_HP <- exp(ga_data$ln_mu_spec_HP)

# Compute latent capacity utilization: ln_mu = y_total - yp
ga_data$ln_mu_spec_B <- ga_data$y_total - ga_data$yp_spec_B
ga_data$ln_mu_spec_A <- ga_data$y_total - ga_data$yp_spec_A

# Normalization:
# Specification B: Already anchored at 1973 relative to total output
ga_data$ln_mu_spec_B_norm <- ga_data$ln_mu_spec_B
ga_data$mu_spec_B <- exp(ga_data$ln_mu_spec_B_norm)

# Specification A (Shaikh-style): Normalized residual (mean-normalized to 1.0)
ga_data$ln_mu_spec_A_norm <- ga_data$ln_mu_spec_A - mean(ga_data$ln_mu_spec_A)
ga_data$mu_spec_A <- exp(ga_data$ln_mu_spec_A_norm)

# Calculate aggregate transformation elasticity theta_total = g_Yp_B / g_Kcap (growth-weighted average)
ga_data$theta_total_t <- ga_data$g_Yp_B / ga_data$g_Kcap

# Save output
out_dir <- file.path(repo_root, "output", "US", "reconstruction_comparison")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(out_dir, "us_golden_age_reconstructed_paths.csv")
write.csv(ga_data[, c("year", "y_total", "y_t", "yp_spec_B", "yp_spec_A", "yp_spec_HP", 
                      "ln_mu_spec_B_norm", "ln_mu_spec_A_norm", "ln_mu_spec_HP", 
                      "mu_spec_B", "mu_spec_A", "mu_spec_HP",
                      "theta_total_t", "theta_ME_t", "theta_NRC_t", "omega_NFC")], 
          out_file, row.names = FALSE)

# Generate Plot 1: Capacity Utilization Comparison
plot_file1 <- file.path(out_dir, "us_golden_age_reconstruction_plot.png")
png(plot_file1, width = 800, height = 500)
plot(ga_data$year, ga_data$mu_spec_B, type = "l", col = "blue", lwd = 2.5, 
     ylim = c(0.7, 1.3), xlab = "Year", ylab = "Capacity Utilization", 
     main = "Capacity Utilization Comparison (1945-1973) - Total Output Basis")
lines(ga_data$year, ga_data$mu_spec_A, col = "red", lwd = 2.5)
lines(ga_data$year, ga_data$mu_spec_HP, col = "darkgreen", lwd = 2.5, lty = 2)
abline(h = 1.0, col = "gray", lty = 2)
legend("bottomleft", legend = c("Specification B (Composition-Mediated growth, Pinched 1973)", 
                               "Specification A (Shaikh-style, Mean-Normalized)",
                               "HP Filter (Output Trend, lambda = 100)"), 
       col = c("blue", "red", "darkgreen"), lwd = 2.5, lty = c(1, 1, 2))
dev.off()

# Generate Plot 2: Elasticities and Wage Share
plot_file2 <- file.path(out_dir, "us_golden_age_elasticity_plot.png")
png(plot_file2, width = 800, height = 500)
# Set up a two-panel plot
par(mar = c(4, 4, 3, 4))
plot(ga_data$year, ga_data$theta_total_t, type = "l", col = "red", lwd = 2.5, 
     ylim = c(-0.3, 2.5), xlab = "Year", ylab = "Transformation Elasticity", 
     main = "Transformation Elasticities & NFC Wage Share (1945-1973)")
lines(ga_data$year, ga_data$theta_ME_t, col = "blue", lwd = 2, lty = 2)
lines(ga_data$year, ga_data$theta_NRC_t, col = "orange", lwd = 2, lty = 3)
abline(h = 0, col = "black", lty = 2, lwd = 1)
par(new = TRUE)
plot(ga_data$year, ga_data$omega_NFC, type = "l", col = "darkgray", lwd = 1.5, 
     axes = FALSE, xlab = "", ylab = "")
axis(side = 4, col = "darkgray", col.axis = "darkgray")
mtext("NFC Wage Share", side = 4, line = 2.5, col = "darkgray")
legend("topright", legend = c("theta_total (Aggregate, Red)", "theta_ME (Machinery, Blue)", "theta_NRC (Structures, Orange)", "omega_NFC (Wage Share, Grey Axis)"), 
       col = c("red", "blue", "orange", "darkgray"), lwd = c(2.5, 2, 2, 1.5), lty = c(1, 2, 3, 1))
dev.off()

# Compute comparison metrics
correlation_B_A <- cor(ga_data$mu_spec_B, ga_data$mu_spec_A)
correlation_B_HP <- cor(ga_data$mu_spec_B, ga_data$mu_spec_HP)
correlation_A_HP <- cor(ga_data$mu_spec_A, ga_data$mu_spec_HP)
sd_B <- sd(ga_data$mu_spec_B)
sd_A <- sd(ga_data$mu_spec_A)
sd_HP <- sd(ga_data$mu_spec_HP)
mean_B <- mean(ga_data$mu_spec_B)
mean_A <- mean(ga_data$mu_spec_A)
mean_HP <- mean(ga_data$mu_spec_HP)

cat("Reconstruction Comparison (1945-1973):\n")
cat("Correlation Spec B / Spec A: ", correlation_B_A, "\n")
cat("Correlation Spec B / HP: ", correlation_B_HP, "\n")
cat("Correlation Spec A / HP: ", correlation_A_HP, "\n")
cat("Mean of Spec B utilization: ", mean_B, "\n")
cat("Mean of Spec A (Shaikh) utilization: ", mean_A, "\n")
cat("Mean of HP utilization: ", mean_HP, "\n")
cat("Standard Deviation of Spec B utilization: ", sd_B, "\n")
cat("Standard Deviation of Spec A (Shaikh) utilization: ", sd_A, "\n")
cat("Standard Deviation of HP utilization: ", sd_HP, "\n")

# Print values for key years
cat("\nKey Years Comparison:\n")
key_years <- c(1945, 1950, 1960, 1970, 1973)
key_data <- subset(ga_data, year %in% key_years)[, c("year", "mu_spec_B", "mu_spec_A", "mu_spec_HP", "theta_total_t")]
print(key_data)
