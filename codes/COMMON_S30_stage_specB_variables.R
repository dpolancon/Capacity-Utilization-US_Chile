#!/usr/bin/env Rscript

# COMMON_S30_stage_specB_variables.R
# Stage 1 Variable Staging Engine for Specification B (Disaggregated Two-Capital Model)
# Constructs k_NRC, k_ME, tau_real, p_rel, and interaction terms (1925-2024).

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
s29c_csv  <- file.path(repo_root, "output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION", "csv", "S29C_fixed_assets_price_real_investment_long.csv")
gpim_csv  <- file.path(repo_root, "output", "gpim_baseline_components_long.csv")
out_csv   <- file.path(repo_root, "output", "gpim_specB_components_long.csv")

cat("========================================================================\n")
cat("Stage 1: Variable Staging Engine for Specification B\n")
cat("========================================================================\n")

if (!file.exists(s29c_csv)) stop("Missing S29C input: ", s29c_csv)
if (!file.exists(gpim_csv)) stop("Missing GPIM input: ", gpim_csv)

s29c_df <- read.csv(s29c_csv, stringsAsFactors = FALSE)
gpim_df <- read.csv(gpim_csv, stringsAsFactors = FALSE)

# Extract P_ME_2017 and P_NRC_2017 deflators
p_me_df  <- s29c_df[s29c_df$derived_variable_id == "P_ME_2017", c("year", "value")]
colnames(p_me_df) <- c("year", "P_ME")

p_nrc_df <- s29c_df[s29c_df$derived_variable_id == "P_NRC_2017", c("year", "value")]
colnames(p_nrc_df) <- c("year", "P_NRC")

prices_df <- merge(p_me_df, p_nrc_df, by = "year")

# Merge with GPIM long baseline panel
df <- merge(gpim_df, prices_df, by = "year", all.x = TRUE)
df <- df[order(df$year), ]

# Construct Specification B variables
df$ln_P_ME  <- log(df$P_ME)
df$ln_P_NRC <- log(df$P_NRC)
df$p_rel    <- df$ln_P_ME - df$ln_P_NRC
df$p_rel_lag1 <- c(NA, df$p_rel[-nrow(df)])

# Real physical volume mechanization choice
df$tau_real <- df$k_ME - df$k_NRC

# Interaction terms
df$inter_tau_omega_NFC_GVA   <- df$tau_real * df$omega_NFC_GVA_lag1
df$inter_tau_omega_CORP_GVA  <- df$tau_real * df$omega_CORP_GVA_lag1
df$inter_tau_omega_ST_Tier1  <- df$tau_real * df$omega_ST_Tier1_NVA_lag1
df$inter_tau_omega_ST_Tier2  <- df$tau_real * df$omega_ST_Tier2_NVA_lag1

df$inter_tau_prel <- df$tau_real * df$p_rel_lag1

# Save staged dataset
write.csv(df, out_csv, row.names = FALSE)

cat("Successfully generated Specification B staged dataset:\n", out_csv, "\n")
cat("Total observations:", nrow(df), "(Years", min(df$year), "-", max(df$year), ")\n")
cat("========================================================================\n\n")
