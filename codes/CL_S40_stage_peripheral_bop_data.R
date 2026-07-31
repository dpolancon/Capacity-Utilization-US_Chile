#!/usr/bin/env Rscript

# CL_S40_stage_peripheral_bop_data.R
# Stages Chilean capital stock, distributive variables, output, and FX availability series (1920-2024).
# Implements Note A04 & Centering Protocol N11:
# Includes Uncentered, Initial-State Centered, and Sample-Mean Centered interaction terms.

suppressPackageStartupMessages({
  library(readxl)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

# File paths
raw_csv    <- file.path(repo_root, "data", "raw", "Chile", "ch2_raw_panel_chile.csv")
distr_xlsx <- file.path(repo_root, "data", "raw", "Chile", "distr_19202024.xlsx")
gdp_xlsx   <- file.path(repo_root, "data", "raw", "Chile", "PerezEyzaguirre_DemandaAgregada.xlsx")
out_dir    <- file.path(repo_root, "data", "processed", "cl_s40")

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

cat("=== Step 1: Loading raw data files ===\n")
df_raw <- read.csv(raw_csv, stringsAsFactors = FALSE)
df_sub <- df_raw[df_raw$year >= 1920 & df_raw$year <= 2024, ]

# Read wage share / profit share from distr_19202024.xlsx if available
if (file.exists(distr_xlsx)) {
  df_distr <- read_excel(distr_xlsx, sheet = "values")
  colnames(df_distr) <- tolower(colnames(df_distr))
  df_sub$omega_distr <- df_distr$wsh[match(df_sub$year, df_distr$periodo)]
  df_sub$pi_distr    <- df_distr$psh[match(df_sub$year, df_distr$periodo)]
}

if ("omega_distr" %in% colnames(df_sub) && !all(is.na(df_sub$omega_distr))) {
  df_sub$omega <- ifelse(is.na(df_sub$omega_distr), df_sub$omega, df_sub$omega_distr)
}
df_sub$pi <- 1 - df_sub$omega

cat("=== Step 2: Constructing log levels and capital composition ===\n")
df_sub$K_cap <- df_sub$K_ME + df_sub$K_NR
df_sub$k_ME  <- log(df_sub$K_ME)
df_sub$k_NR  <- log(df_sub$K_NR)
df_sub$k_cap <- log(df_sub$K_cap)

# Capital Composition ratio: kappa_t (alias tau_t)
df_sub$kappa <- df_sub$k_ME - df_sub$k_NR
df_sub$tau   <- df_sub$kappa

# Log Real GDP
df_sub$y <- log(df_sub$GDP_real)

cat("=== Step 3: Constructing FX Constraint & Realization Wedge (Note A04) ===\n")
df_sub$F_avail <- df_sub$X_FOB

# Peak-to-peak capacity output proxy mu_t
y_peak <- cummax(df_sub$GDP_real)
df_sub$mu <- df_sub$GDP_real / y_peak
df_sub$mu <- df_sub$mu / max(df_sub$mu, na.rm = TRUE)

df_sub$F_req <- df_sub$mu * df_sub$pi * df_sub$GDP_real

# Realization ratio: phi_t = min(1, F_avail / F_req)
phi_raw <- df_sub$F_avail / (0.15 * df_sub$F_req)
df_sub$phi <- pmin(1.0, phi_raw)

# Effective profit share & blocked surplus
df_sub$pi_eff     <- df_sub$pi * df_sub$phi
df_sub$pi_blocked <- df_sub$pi - df_sub$pi_eff

cat("=== Step 4: Constructing Interaction Terms & Centering Treatments (Protocol N11) ===\n")
# 1. Uncentered
df_sub$omega_phi <- df_sub$omega * df_sub$phi
df_sub$omega_tau <- df_sub$omega * df_sub$tau

# 2. Initial-State Centered (Treatment 2: x_t - x_1)
w1   <- df_sub$omega[1]
phi1 <- df_sub$phi[1]
tau1 <- df_sub$tau[1]

df_sub$omega_init_c <- df_sub$omega - w1
df_sub$phi_init_c   <- df_sub$phi - phi1
df_sub$tau_init_c   <- df_sub$tau - tau1

df_sub$omega_phi_init_c <- df_sub$omega_init_c * df_sub$phi_init_c
df_sub$omega_tau_init_c <- df_sub$omega_init_c * df_sub$tau_init_c

# 3. Sample-Mean Centered (Treatment 3: x_t - bar{x})
wm   <- mean(df_sub$omega, na.rm = TRUE)
phim <- mean(df_sub$phi, na.rm = TRUE)
taum <- mean(df_sub$tau, na.rm = TRUE)

df_sub$omega_mean_c <- df_sub$omega - wm
df_sub$phi_mean_c   <- df_sub$phi - phim
df_sub$tau_mean_c   <- df_sub$tau - taum

df_sub$omega_phi_mean_c <- df_sub$omega_mean_c * df_sub$phi_mean_c
df_sub$omega_tau_mean_c <- df_sub$omega_mean_c * df_sub$tau_mean_c

# Save staged dataset
out_file <- file.path(out_dir, "chile_peripheral_staged_panel.csv")
write.csv(df_sub, out_file, row.names = FALSE)
cat("Successfully staged Chilean panel saved to:", out_file, "\n")
cat("Years covered:", min(df_sub$year), "-", max(df_sub$year), "(N =", nrow(df_sub), ")\n")
