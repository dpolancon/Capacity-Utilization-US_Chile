#!/usr/bin/env Rscript

# CL_S10_stage_chile_raw_series.R
# Stages Chilean capital, distribution, GDP, and FX external wedge candidate series.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
raw_file  <- file.path(repo_root, "data", "raw", "Chile", "ch2_raw_panel_chile.csv")
out_dir   <- file.path(repo_root, "data", "processed", "cl_s10")

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

df <- read.csv(raw_file, stringsAsFactors = FALSE)

# Filter for years with valid capital and GDP data (1920 onwards)
df_clean <- df[df$year >= 1920 & !is.na(df$GDP_real) & !is.na(df$K_ME) & !is.na(df$K_NR), ]

# Compute analytical transformations
df_clean$K_cap <- df_clean$K_ME + df_clean$K_NR

df_clean$k_cap <- log(df_clean$K_cap)
df_clean$k_ME  <- log(df_clean$K_ME)
df_clean$k_NR  <- log(df_clean$K_NR)
df_clean$y     <- log(df_clean$GDP_real)
df_clean$tau   <- df_clean$k_ME - df_clean$k_NR

# FX external wedge candidates
# z1: Log Terms of Trade proxy / Trade Balance Ratio (X_FOB / M_CIF)
df_clean$z1_tot <- log(df_clean$X_FOB / df_clean$M_CIF)

# z2: Log Real Export Capacity (X_FOB / Real GDP share)
df_clean$z2_xcap <- log(df_clean$X_FOB / df_clean$GDP_real)

out_file <- file.path(out_dir, "chile_staged_variable_panel.csv")
write.csv(df_clean, out_file, row.names = FALSE)
cat("Staged Chilean series saved to:", out_file, "\n")
