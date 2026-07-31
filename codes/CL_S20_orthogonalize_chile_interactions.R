#!/usr/bin/env Rscript

# CL_S20_orthogonalize_chile_interactions.R
# Computes FWL orthogonalized interaction residuals (u_hat) for Chilean 2-way and 3-way models.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_file <- file.path(repo_root, "data", "processed", "cl_s10", "chile_staged_variable_panel.csv")
out_dir    <- file.path(repo_root, "data", "processed", "cl_s20")

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

df <- read.csv(input_file, stringsAsFactors = FALSE)

# 1. 2-way scale-distribution interaction: (k_cap * omega)
m_k_omega <- lm((k_cap * omega) ~ k_cap + omega, data = df)
df$u_hat_k_omega <- residuals(m_k_omega)

# 2. 2-way scale-FX interaction: (k_cap * z1_tot)
m_k_z1 <- lm((k_cap * z1_tot) ~ k_cap + z1_tot, data = df)
df$u_hat_k_z1 <- residuals(m_k_z1)

# 3. 2-way distribution-FX interaction: (omega * z1_tot)
m_omega_z1 <- lm((omega * z1_tot) ~ omega + z1_tot, data = df)
df$u_hat_omega_z1 <- residuals(m_omega_z1)

# 4. 3-way interaction (per A06 pending resolution): (k_cap * omega * z1_tot)
m_3way <- lm((k_cap * omega * z1_tot) ~ k_cap + omega + z1_tot + u_hat_k_omega + u_hat_k_z1 + u_hat_omega_z1, data = df)
df$u_hat_k_omega_z1_pending <- residuals(m_3way)

out_file <- file.path(out_dir, "chile_orthogonalized_panel.csv")
write.csv(df, out_file, row.names = FALSE)
cat("Orthogonalized Chilean panel saved to:", out_file, "\n")
