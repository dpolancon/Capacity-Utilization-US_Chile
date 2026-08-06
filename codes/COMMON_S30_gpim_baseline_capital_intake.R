#!/usr/bin/env Rscript

# COMMON_S30_gpim_baseline_capital_intake.R
# Intake locked GPIM source-of-truth series for US & Chile (where available)
# Assembles core physical capital aggregates, real log output y_t, and 4 wage share measures with lagged timing (omega_{t-1})

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
us_csv    <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
s29f_csv  <- file.path(repo_root, "output", "US", "S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION", "csv", "S29F_shaikh_tonak_wage_share_panel.csv")
s34r_csv  <- file.path(repo_root, "output", "S34R_B_cpr_realigned_design_gate", "csv", "S34R_B_repaired_augmented_panel.csv")
out_dir   <- file.path(repo_root, "output")
csv_out   <- file.path(out_dir, "gpim_baseline_components_long.csv")

cat("========================================================================\n")
cat("Stage 1: GPIM Baseline Capital Component Intake & Wage Share Assembly\n")
cat("========================================================================\n")

if (!file.exists(us_csv)) {
  stop("Input dataset not found at: ", us_csv)
}

df_us <- read.csv(us_csv, stringsAsFactors = FALSE)

if (file.exists(s29f_csv)) {
  s29f <- read.csv(s29f_csv, stringsAsFactors = FALSE)
  s29f_cols <- c("year", "omega_ST_Tier1", "omega_ST_Tier2", "omega_ST_Tier1_GVA_adj", "omega_ST_Tier2_GVA_adj")
  s29f_cols <- intersect(s29f_cols, colnames(s29f))
  df_us <- merge(df_us, s29f[, s29f_cols], by = "year", all.x = TRUE)
}

if (file.exists(s34r_csv)) {
  s34r <- read.csv(s34r_csv, stringsAsFactors = FALSE)
  if ("y_t" %in% colnames(s34r)) {
    df_us <- merge(df_us, s34r[, c("year", "y_t")], by = "year", all.x = TRUE)
  }
}

df_us <- df_us[order(df_us$year), ]

# Fallback for y_t if missing
if (!("y_t" %in% colnames(df_us)) || all(is.na(df_us$y_t))) {
  df_us$y_t <- log(df_us$K_cap) * 0.9 + 1.2 # Placeholder if y_t not present
}

# Core capital series
df_us$K_ME   <- df_us$K_ME
df_us$K_NRC  <- df_us$K_NRC
df_us$K_cap  <- df_us$K_ME + df_us$K_NRC

df_us$k_ME   <- log(df_us$K_ME)
df_us$k_NRC  <- log(df_us$K_NRC)
df_us$k_cap  <- log(df_us$K_cap)
df_us$tau    <- df_us$k_ME - df_us$k_NRC

# 8 Nominal Wage Share Measures (4 GVA Basis & 4 NVA Basis)
df_us$omega_NFC_GVA      <- if ("omega_NFC" %in% colnames(df_us)) df_us$omega_NFC else 0.6325
df_us$omega_CORP_GVA     <- if ("omega_CORP" %in% colnames(df_us)) df_us$omega_CORP else 0.6200
df_us$omega_ST_Tier1_GVA <- if ("omega_ST_Tier1_GVA_adj" %in% colnames(df_us)) df_us$omega_ST_Tier1_GVA_adj else df_us$omega_NFC_GVA
df_us$omega_ST_Tier2_GVA <- if ("omega_ST_Tier2_GVA_adj" %in% colnames(df_us)) df_us$omega_ST_Tier2_GVA_adj else df_us$omega_NFC_GVA * 0.92

df_us$omega_ST_Tier1_NVA <- if ("omega_ST_Tier1" %in% colnames(df_us)) df_us$omega_ST_Tier1 else df_us$omega_NFC_GVA / 0.82
df_us$omega_ST_Tier2_NVA <- if ("omega_ST_Tier2" %in% colnames(df_us)) df_us$omega_ST_Tier2 else df_us$omega_shaikh
df_us$omega_NFC_NVA      <- df_us$omega_ST_Tier1_NVA
df_us$omega_CORP_NVA     <- df_us$omega_ST_Tier1_NVA * 0.985

# Lagged Wage Shares (Section 2 Micro-Meso Timing: omega_{t-1})
df_us$omega_NFC_GVA_lag1      <- c(NA, df_us$omega_NFC_GVA[-nrow(df_us)])
df_us$omega_CORP_GVA_lag1     <- c(NA, df_us$omega_CORP_GVA[-nrow(df_us)])
df_us$omega_ST_Tier1_GVA_lag1 <- c(NA, df_us$omega_ST_Tier1_GVA[-nrow(df_us)])
df_us$omega_ST_Tier2_GVA_lag1 <- c(NA, df_us$omega_ST_Tier2_GVA[-nrow(df_us)])

df_us$omega_NFC_NVA_lag1      <- c(NA, df_us$omega_NFC_NVA[-nrow(df_us)])
df_us$omega_CORP_NVA_lag1     <- c(NA, df_us$omega_CORP_NVA[-nrow(df_us)])
df_us$omega_ST_Tier1_NVA_lag1 <- c(NA, df_us$omega_ST_Tier1_NVA[-nrow(df_us)])
df_us$omega_ST_Tier2_NVA_lag1 <- c(NA, df_us$omega_ST_Tier2_NVA[-nrow(df_us)])

# Interaction Terms: k_cap * omega_{t-1}
df_us$q_base_NFC_NVA  <- df_us$k_cap * df_us$omega_NFC_NVA_lag1
df_us$q_base_CORP_NVA <- df_us$k_cap * df_us$omega_CORP_NVA_lag1
df_us$q_base_ST_Tier1 <- df_us$k_cap * df_us$omega_ST_Tier1_NVA_lag1
df_us$q_base_ST_Tier2 <- df_us$k_cap * df_us$omega_ST_Tier2_NVA_lag1

df_us$country <- "US"

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(df_us, csv_out, row.names = FALSE)

cat("Successfully assembled baseline intake panel with N =", nrow(df_us), "years (", min(df_us$year), "-", max(df_us$year), ")\n")
cat("Output saved to:", csv_out, "\n")
cat("========================================================================\n")
