#!/usr/bin/env Rscript

# CL_S60_capacity_utilization_recovery.R
# Reconstructs aggregate capacity utilization (mu_t) and aggregate transformation elasticity (theta_t^Agg)
# for Chile using the preferred regime-switching CMPR IM-OLS model (Column 2: omega_gross, p=0.2, gamma=0.425).
# Anchored at 1981 Ffrench-Davis pinch year (mu_1981 = 1.0).

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(cointReg)
  library(dplyr)
  library(readr)
  library(matrixStats)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(repo_root)

cpr_imols_path <- file.path(repo_root, ".agents/skills/cpr-im-ols/scripts/cpr_imols_estimator.R")
source(cpr_imols_path)

panel_path <- file.path(repo_root, "data/staged/ch2_panel_chile_with_prices.csv")
df_full <- read_csv(panel_path, show_col_types = FALSE)

# Filter estimation sample (1942-2010 per benchmark)
df <- df_full %>%
  filter(year >= 1942, year <= 2010) %>%
  mutate(
    y_t             = log(GDP_real),
    k_NR            = log(K_NR),
    k_ME            = log(K_ME),
    kappa_t         = k_ME - k_NR,
    omega_gross_lag = lag(omega_gross),
    p_kappa         = p_kappa_rer,
    s_ME            = K_ME / (K_ME + K_NR),
    K_tot           = K_ME + K_NR,
    k_tot           = log(K_tot)
  ) %>%
  filter(!is.na(y_t), !is.na(k_NR), !is.na(kappa_t), !is.na(omega_gross_lag), 
         !is.na(p_kappa), !is.na(SolvR_M0), !is.na(imbalance_level)) %>%
  arrange(year)

# 1. Standardize threshold variables and form Z_t (p = 0.2)
df$S_tilde <- scale(df$SolvR_M0)[, 1]
df$M_tilde <- scale(df$imbalance_level)[, 1]
p_weight <- 0.2
df$Z_t <- p_weight * df$M_tilde + (1 - p_weight) * df$S_tilde

# Optimal threshold gamma = 0.425
opt_gamma <- 0.425
df$D_gamma <- ifelse(df$Z_t <= opt_gamma, 1, 0)
df$regime_label <- ifelse(df$D_gamma == 1, "Binding", "Slack")

# 2. FWL Orthogonalization for relative prices
fwl_fit <- lm(p_kappa ~ k_NR + kappa_t, data = df)
df$p_tilde <- residuals(fwl_fit)

# 3. Model Estimation
df_est <- df %>%
  mutate(
    dist_k  = omega_gross_lag * kappa_t,
    k_D     = kappa_t * D_gamma,
    dk_D    = dist_k * D_gamma
  )

y_mat      <- as.matrix(df_est$y_t)
x_base_sub <- as.matrix(df_est %>% select(k_NR, kappa_t))
deter_sub  <- matrix(1, nrow = nrow(df_est), ncol = 1)
colnames(deter_sub) <- "intercept"

x_final <- df_est %>% select(k_NR, kappa_t, dist_k, k_D, dk_D, p_tilde) %>% as.matrix()

fit <- cointRegIM_CMPR(x = x_final, y = y_mat, deter = deter_sub, x_base = x_base_sub, selector = c(1,2))

theta_coefs <- fit$theta
cat("=== ESTIMATED MODEL COEFFICIENTS ===\n")
print(theta_coefs)

alpha   <- theta_coefs[1]
theta_1 <- theta_coefs[2] # k_NR
theta_2 <- theta_coefs[3] # kappa_t
theta_3 <- theta_coefs[4] # omega_gross_lag * kappa_t
theta_4 <- theta_coefs[5] # kappa_t * D_gamma
theta_5 <- theta_coefs[6] # omega_gross_lag * kappa_t * D_gamma
theta_p <- theta_coefs[7] # p_tilde

# 4. Construct Regime-Switching Transformation Elasticity Path
# theta_t^Agg = theta_1 + s_ME * [theta_2 + theta_3 * omega_lag + D_gamma * (theta_4 + theta_5 * omega_lag)]
mp_kappa_t <- theta_2 + theta_3 * df_est$omega_gross_lag + df_est$D_gamma * (theta_4 + theta_5 * df_est$omega_gross_lag)
df_est$mp_kappa_t <- mp_kappa_t
df_est$theta_t_agg <- theta_1 + df_est$s_ME * mp_kappa_t

# 5. Differential Capacity Recovery Anchored at 1981 (mu_1981 = 1.000000)
# g_K,t = k_tot,t - k_tot,t-1
# Capacity growth g_Yp,t = theta_t^Agg * g_K,t
g_K <- c(0, diff(df_est$k_tot))
df_est$g_K <- g_K
df_est$g_Yp <- df_est$theta_t_agg * g_K

# Pinch year 1981
idx_1981 <- which(df_est$year == 1981)
if (length(idx_1981) == 0) stop("1981 pinch year not found in sample.")

ln_Yp <- numeric(nrow(df_est))
ln_Yp[idx_1981] <- df_est$y_t[idx_1981] # Y^p_1981 = Y_1981

# Forward recursion (1982 to end)
for (i in (idx_1981 + 1):nrow(df_est)) {
  ln_Yp[i] <- ln_Yp[i - 1] + df_est$g_Yp[i]
}

# Backward recursion (1980 down to 1)
for (i in (idx_1981 - 1):1) {
  ln_Yp[i] <- ln_Yp[i + 1] - df_est$g_Yp[i + 1]
}

df_est$ln_Yp <- ln_Yp
df_est$Yp    <- exp(ln_Yp)
df_est$mu_t  <- exp(df_est$y_t - ln_Yp)

# Validate 1981 Anchor
err_1981 <- abs(df_est$mu_t[idx_1981] - 1.000000)
cat(sprintf("\n=== 1981 ANCHOR VALIDATION ===\n"))
cat(sprintf("mu_1981 = %.15f (absolute error = %.2e) -> %s\n", 
            df_est$mu_t[idx_1981], err_1981, 
            if (err_1981 < 1e-12) "PASS" else "FAIL"))

# 6. Save Output Ledger
out_dir <- file.path(repo_root, "output")
dir.create(out_dir, showWarnings = FALSE)
out_csv <- file.path(out_dir, "chile_capacity_utilization_series.csv")

export_df <- df_est %>%
  select(
    year, y_t, k_NR, k_ME, kappa_t, k_tot, g_K,
    omega_gross_lag, s_ME, SolvR_M0, imbalance_level,
    S_tilde, M_tilde, Z_t, D_gamma, regime_label,
    mp_kappa_t, theta_t_agg, g_Yp, ln_Yp, Yp, mu_t
  )

write_csv(export_df, out_csv)
cat(sprintf("\nSuccessfully exported capacity recovery series to: %s\n", out_csv))
