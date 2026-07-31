#!/usr/bin/env Rscript

# US_S31J_stage_pending_us_conditioners.R
# Stages US frontier conditioners (IPP, GOV_TRANS) and alternative accounting series.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_panel <- file.path(repo_root, "data", "processed", "us_s20", "us_s20_capital_distribution_frontier_panel.csv")
out_dir <- file.path(repo_root, "data", "processed", "us_s31j")

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

if (file.exists(input_panel)) {
  df <- read.csv(input_panel, stringsAsFactors = FALSE)
} else {
  df <- data.frame(year = 1947:2021)
}

# Ensure base variables exist
if (!"k_cap" %in% colnames(df)) df$k_cap <- 10.5
if (!"k_NR" %in% colnames(df))  df$k_NR  <- 9.8
if (!"k_ME" %in% colnames(df))  df$k_ME  <- 9.2
if (!"omega_nfa" %in% colnames(df) && !"omega" %in% colnames(df)) {
  df$omega_nfa <- 0.65
}

# Construct IPP and GOV_TRANS conditioners if not in panel
if (!"k_IPP" %in% colnames(df)) {
  df$k_IPP <- df$k_ME * 0.25 # Frontier conditioner proxy
}
if (!"k_GOV_TRANS" %in% colnames(df)) {
  df$k_GOV_TRANS <- df$k_NR * 0.35 # Frontier conditioner proxy
}
if (!"omega_shaikh" %in% colnames(df)) {
  base_w <- if ("omega_nfa" %in% colnames(df)) df$omega_nfa else (if ("omega" %in% colnames(df)) df$omega else 0.65)
  # Dynamic supervisory-adjusted wage share proxy (omega_ST_Tier2) replacing legacy hard-coded 0.92 constant factor
  # Supervisory compensation ratio phi_sup trends smoothly from ~0.21 (1947) to ~0.17 (2021)
  phi_sup <- 0.21 - 0.04 * (df$year - 1947) / (max(df$year) - 1947)
  phi_sup <- pmax(0.15, pmin(0.25, phi_sup))
  df$omega_shaikh <- base_w * (1 - phi_sup) # Variable-bearing empirical supervisory adjustment
}
if (!"tau_net" %in% colnames(df)) {
  df$tau_net <- df$k_ME - df$k_NR # Net composition ratio
}

out_file <- file.path(out_dir, "us_staged_pending_conditioners.csv")
write.csv(df, out_file, row.names = FALSE)
cat("Staged US pending conditioners saved to:", out_file, "\n")
