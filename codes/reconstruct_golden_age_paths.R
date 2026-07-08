#!/usr/bin/env Rscript

# Chapter 2 - Golden Age Capacity Path Reconstruction & Comparison
# Reconstructs potential capacity output (yp) and latent utilization (mu)
# for Specification B (composition-mediated) and Specification A (Shaikh-style)
# and compares their paths.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
panel_path <- file.path(repo_root, "output", "S34R_B_cpr_realigned_design_gate", "csv", "S34R_B_repaired_augmented_panel.csv")

if (!file.exists(panel_path)) {
  stop("S34R-B panel not found. Please run the S34R-B gate script first.", call. = FALSE)
}

panel <- read.csv(panel_path, stringsAsFactors = FALSE, check.names = FALSE)
panel <- panel[order(panel$year), ]

# Filter to Golden Age (1945-1973)
ga_data <- subset(panel, year >= 1945 & year <= 1973)

# Model 1: Specification B (Composition-Mediated with K_NRC and tau)
# FM-OLS coefficients for Golden Age (1945-1973):
alpha_B <- 14.86173
beta_k_B <- 0.23784
beta_tau_B <- 0.31207
beta_w_B <- -5.16053
beta_inter_B <- -1.02937

ga_data$yp_spec_B <- alpha_B + 
  beta_k_B * ga_data$k_NRC_centered + 
  beta_tau_B * ga_data$tau_centered + 
  beta_w_B * ga_data$omega_NFC_centered + 
  beta_inter_B * ga_data$inter_tau_omega_orth

# Model 2: Specification A (Shaikh's style with K_Kcap = ME + NRC)
# FM-OLS coefficients for Golden Age (1945-1973):
alpha_A <- 14.37609
beta_k_A <- 0.87234
beta_w_A <- 5.03512
beta_inter_A <- 3.84668

ga_data$yp_spec_A <- alpha_A + 
  beta_k_A * ga_data$k_Kcap_centered + 
  beta_w_A * ga_data$omega_NFC_centered + 
  beta_inter_A * ga_data$inter_kKcap_omega_orth

# Compute latent capacity utilization: ln_mu = y - yp
ga_data$ln_mu_spec_B <- ga_data$y_t - ga_data$yp_spec_B
ga_data$ln_mu_spec_A <- ga_data$y_t - ga_data$yp_spec_A

# Normalize such that mu_1973 = 1.0 (ln_mu_1973 = 0.0)
ln_mu_1973_B <- ga_data$ln_mu_spec_B[ga_data$year == 1973]
ln_mu_1973_A <- ga_data$ln_mu_spec_A[ga_data$year == 1973]

ga_data$ln_mu_spec_B_norm <- ga_data$ln_mu_spec_B - ln_mu_1973_B
ga_data$ln_mu_spec_A_norm <- ga_data$ln_mu_spec_A - ln_mu_1973_A

ga_data$mu_spec_B <- exp(ga_data$ln_mu_spec_B_norm)
ga_data$mu_spec_A <- exp(ga_data$ln_mu_spec_A_norm)

# Save output
out_dir <- file.path(repo_root, "output", "US", "reconstruction_comparison")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(out_dir, "us_golden_age_reconstructed_paths.csv")
write.csv(ga_data[, c("year", "y_t", "yp_spec_B", "yp_spec_A", "ln_mu_spec_B_norm", "ln_mu_spec_A_norm", "mu_spec_B", "mu_spec_A")], 
          out_file, row.names = FALSE)

# Compute comparison metrics
correlation <- cor(ga_data$mu_spec_B, ga_data$mu_spec_A)
sd_B <- sd(ga_data$mu_spec_B)
sd_A <- sd(ga_data$mu_spec_A)
mean_B <- mean(ga_data$mu_spec_B)
mean_A <- mean(ga_data$mu_spec_A)

cat("Reconstruction Comparison (1945-1973):\n")
cat("Correlation between Spec B and Spec A utilization: ", correlation, "\n")
cat("Mean of Spec B utilization: ", mean_B, "\n")
cat("Mean of Spec A utilization: ", mean_A, "\n")
cat("Standard Deviation of Spec B utilization: ", sd_B, "\n")
cat("Standard Deviation of Spec A utilization: ", sd_A, "\n")

# Print values for key years
cat("\nKey Years Comparison:\n")
key_years <- c(1945, 1950, 1960, 1970, 1973)
key_data <- subset(ga_data, year %in% key_years)[, c("year", "mu_spec_B", "mu_spec_A")]
print(key_data)
