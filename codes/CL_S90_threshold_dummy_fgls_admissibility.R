# ==============================================================================
# CL_S90_threshold_dummy_fgls_admissibility.R
# Feasible Generalized Least Squares (FGLS) Threshold Cointegration
# Using Nievas-Piketty (2025) WBOP Current Account Balance as % GDP
# and Centered Wage Share as the Distribution Variable of Interest
# ==============================================================================

library(tidyverse)
library(urca)
library(sandwich)
library(ggplot2)
library(scales)

# ---- 1. Setup paths and parameters
REPO     <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
DATA_IN  <- file.path(REPO, "data/final")
OUT_CSV  <- file.path(REPO, "output/stage_a/Chile/csv")
OUT_FIG  <- file.path(REPO, "output/stage_a/Chile/figs")

dir.create(OUT_CSV, recursive=TRUE, showWarnings=FALSE)
dir.create(OUT_FIG, recursive=TRUE, showWarnings=FALSE)

cat("=== Step 1: Loading Data ===\n")
# Load panel data
panel_path <- file.path(DATA_IN, "chile_tvecm_panel.csv")
if (!file.exists(panel_path)) {
  panel_path <- file.path(REPO, "data/processed/Chile/ch2_panel_chile.csv")
}
df_panel <- read_csv(panel_path, show_col_types = FALSE) %>% arrange(year)

# Load WBOP Chile Balance of Payments data
wbop_path <- file.path(REPO, "data/raw/Chile/nievas_piketty_wbop_chile_long.csv")
if (file.exists(wbop_path)) {
  cat("Loading Nievas-Piketty (2025) WBOP current account dataset...\n")
  df_wbop <- read_csv(wbop_path, show_col_types = FALSE) %>%
    filter(variable_code == "current_account_net_gdp") %>%
    select(year, current_account_gdp = value) %>%
    arrange(year)
  df <- df_panel %>% left_join(df_wbop, by = "year")
} else {
  cat("Error: nievas_piketty_wbop_chile_long.csv not found!\n")
  stop("Missing WBOP dataset.")
}

# Construct variables
df <- df %>%
  mutate(
    # Log total productive capital scale
    k_CL = log(exp(k_NR) + exp(k_ME)),
    # Capital composition ratio
    c_t = k_ME - k_NR,
    # Center wage share around estimation sample mean (1920-1973)
    omega_mean_est = mean(omega[year >= 1920 & year <= 1973], na.rm = TRUE),
    omega_t_centered = omega - omega_mean_est,
    # Interaction term: wage share x composition
    omega_c = omega_t_centered * c_t,
    # Lagged threshold variable: WBOP Current Account Balance as % GDP
    q_bop_lag1 = lag(current_account_gdp, 1)
  )

# Define estimation sample (1920-1973)
df_est <- df %>% filter(year >= 1920, year <= 1973)

# ---- 2. Haldrup Ladder: Unit Root & Structural Break Diagnostics
cat("\n=== Step 2: Haldrup Ladder Diagnostics ===\n")

# Unit root tests in levels
run_ur_battery <- function(series, name) {
  series_clean <- series[!is.na(series)]
  adf <- ur.df(series_clean, type = "drift", lags = 2)
  kpss <- ur.kpss(series_clean, type = "mu")
  cat(sprintf("%s - ADF t-stat: %.4f (5%% CV: %.4f), KPSS stat: %.4f (5%% CV: %.4f)\n",
              name, adf@teststat[1], adf@cval[1,2], kpss@teststat[1], kpss@cval[2]))
}

run_ur_battery(df_est$y, "y (log GDP)")
run_ur_battery(df_est$k_CL, "k_CL (log scale capital)")
run_ur_battery(df_est$c_t, "c_t (log capital composition)")
run_ur_battery(df_est$omega, "omega (wage share)")
run_ur_battery(df_est$current_account_gdp, "current_account_gdp (BOP CA % GDP)")

# Custom Gregory-Hansen Cointegration test
gregory_hansen_test <- function(y, X, model = "C", trim = 0.15) {
  n <- length(y)
  t_start <- floor(n * trim)
  t_end <- n - t_start
  
  min_t <- Inf
  best_break <- NA
  
  for (t_break in t_start:t_end) {
    D <- as.numeric((1:n) > t_break)
    
    if (model == "C") {
      reg_X <- cbind(1, D, X)
    } else if (model == "S") {
      D_X <- X * D
      reg_X <- cbind(1, D, X, D_X)
    } else {
      stop("Invalid model type")
    }
    
    fit <- lm.fit(reg_X, y)
    e <- fit$residuals
    
    # ADF(1) test on residuals
    dy <- diff(e)
    le <- e[1:(n-1)]
    dy_lag <- lag(dy, 1)
    
    valid <- 2:(n-1)
    fit_adf <- lm(dy[valid] ~ le[valid] + dy_lag[valid] - 1)
    t_stat <- summary(fit_adf)$coefficients["le[valid]", "t value"]
    
    if (is.finite(t_stat) && t_stat < min_t) {
      min_t <- t_stat
      best_break <- t_break
    }
  }
  
  return(list(stat = min_t, break_obs = best_break, model = model))
}

y_est <- df_est$y
X_est <- cbind(df_est$k_CL, df_est$c_t, df_est$omega_c, df_est$omega_t_centered)

gh_c <- gregory_hansen_test(y_est, X_est, model = "C")
gh_s <- gregory_hansen_test(y_est, X_est, model = "S")

cat(sprintf("\nGregory-Hansen Cointegration Break Diagnostics:\n"))
cat(sprintf("  Model C (Constant Shift) t-stat: %.4f (Break Year: %d, 5%% CV: -5.28)\n", 
            gh_c$stat, df_est$year[gh_c$break_obs]))
cat(sprintf("  Model S (Regime Shift)   t-stat: %.4f (Break Year: %d, 5%% CV: -6.00)\n", 
            gh_s$stat, df_est$year[gh_s$break_obs]))

# ---- 3. Sup-Wald Cointegration Test with Residual Bootstrap
cat("\n=== Step 3: Sup-Wald Threshold Admissibility ===\n")

# Default threshold variable: lagged current account % GDP
q_vec <- df_est$q_bop_lag1
valid_idx <- which(!is.na(q_vec))

y_trim <- y_est[valid_idx]
X_trim <- X_est[valid_idx, ]
q_trim <- q_vec[valid_idx]
n_trim <- length(y_trim)

# Linear model (H0)
linear_fit <- lm(y_trim ~ X_trim)
ssr_linear <- sum(linear_fit$residuals^2)

# Grid search setup
trim_pct <- 0.15
q_sorted <- sort(q_trim)
trim_low <- q_sorted[floor(n_trim * trim_pct)]
trim_high <- q_sorted[ceiling(n_trim * (1 - trim_pct))]
candidates <- q_trim[q_trim >= trim_low & q_trim <= trim_high]

compute_sup_wald <- function(y, X, q, candidates) {
  ssr_vals <- numeric(length(candidates))
  for (i in seq_along(candidates)) {
    gamma <- candidates[i]
    regime1 <- as.numeric(q <= gamma)
    regime2 <- as.numeric(q > gamma)
    X1 <- cbind(1, X) * regime1
    X2 <- cbind(1, X) * regime2
    fit <- lm.fit(cbind(X1, X2), y)
    ssr_vals[i] <- sum(fit$residuals^2)
  }
  best_ssr <- min(ssr_vals)
  best_gamma <- candidates[which.min(ssr_vals)]
  stat <- n_trim * (ssr_linear - best_ssr) / best_ssr
  return(list(stat = stat, ssr = best_ssr, gamma = best_gamma, ssr_vector = ssr_vals))
}

wald_orig <- compute_sup_wald(y_trim, X_trim, q_trim, candidates)

# Bootstrap p-value (B=200 for speed)
B <- 200
cat(sprintf("Running residual bootstrap (B=%d replicates)... Please wait.\n", B))
set.seed(42)
boot_stats <- numeric(B)
linear_resids <- residuals(linear_fit)
linear_fitted <- fitted(linear_fit)

for (b in 1:B) {
  res_boot <- sample(linear_resids, replace = TRUE)
  y_boot <- linear_fitted + res_boot
  boot_out <- compute_sup_wald(y_boot, X_trim, q_trim, candidates)
  boot_stats[b] <- boot_out$stat
}

p_val <- sum(boot_stats >= wald_orig$stat) / B
cat(sprintf("Sup-Wald Test Statistic: %.4f\n", wald_orig$stat))
cat(sprintf("Bootstrap p-value: %.4f\n", p_val))
if (p_val >= 0.10) {
  cat("WARNING: Threshold behavior is NOT statistically supported at the 10% level.\n")
  cat("Proceeding with FGLS estimation anyway as a diagnostic robustness check.\n")
} else {
  cat("SUCCESS: Threshold behavior is statistically supported.\n")
}

# ---- 4. Cochrane-Orcutt Feasible Generalized Least Squares (FGLS)
cat("\n=== Step 4: Cochrane-Orcutt FGLS Threshold Estimation ===\n")

# First-stage OLS threshold and residuals
gamma_ols <- wald_orig$gamma
regime1_ols <- as.numeric(q_trim <= gamma_ols)
regime2_ols <- as.numeric(q_trim > gamma_ols)
X_combined_ols <- cbind(cbind(1, X_trim) * regime1_ols, cbind(1, X_trim) * regime2_ols)
fit_ols <- lm(y_trim ~ X_combined_ols - 1)
e_ols <- residuals(fit_ols)

# AR(p) selection for residuals using BIC
ar_fit1 <- arima(e_ols, order=c(1,0,0), include.mean=FALSE)
ar_fit2 <- arima(e_ols, order=c(2,0,0), include.mean=FALSE)

bic1 <- BIC(ar_fit1)
bic2 <- BIC(ar_fit2)
p_opt <- if (bic1 <= bic2) 1 else 2
rho_hat <- if (p_opt == 1) coef(ar_fit1) else coef(ar_fit2)

cat(sprintf("Residual AR selection: AR(%d) selected (BIC_1=%.4f, BIC_2=%.4f)\n", p_opt, bic1, bic2))
cat(sprintf("Estimated AR coefficients (rho): %s\n", paste(round(rho_hat, 4), collapse = ", ")))

# Cochrane-Orcutt filtering function
co_filter <- function(vec, rho, p) {
  n <- length(vec)
  if (p == 1) {
    return(vec[2:n] - rho[1] * vec[1:(n-1)])
  } else {
    return(vec[3:n] - rho[1] * vec[2:(n-1)] - rho[2] * vec[1:(n-2)])
  }
}

# Transform variables
y_co <- co_filter(y_trim, rho_hat, p_opt)
n_co <- length(y_co)

# Perform FGLS Grid Search on transformed variables
ssr_fgls <- numeric(length(candidates))
for (i in seq_along(candidates)) {
  gamma <- candidates[i]
  r1 <- as.numeric(q_trim <= gamma)
  r2 <- as.numeric(q_trim > gamma)
  
  X1_raw <- cbind(1, X_trim) * r1
  X2_raw <- cbind(1, X_trim) * r2
  
  X1_co <- apply(X1_raw, 2, co_filter, rho = rho_hat, p = p_opt)
  X2_co <- apply(X2_raw, 2, co_filter, rho = rho_hat, p = p_opt)
  
  fit_co <- lm.fit(cbind(X1_co, X2_co), y_co)
  ssr_fgls[i] <- sum(fit_co$residuals^2)
}

gamma_fgls <- candidates[which.min(ssr_fgls)]
cat(sprintf("Final FGLS Threshold Estimate: %.4f%% GDP\n", gamma_fgls))

# Re-estimate final model under FGLS
r1_fgls <- as.numeric(q_trim <= gamma_fgls)
r2_fgls <- as.numeric(q_trim > gamma_fgls)
X1_raw <- cbind(1, X_trim) * r1_fgls
X2_raw <- cbind(1, X_trim) * r2_fgls
X1_co <- apply(X1_raw, 2, co_filter, rho = rho_hat, p = p_opt)
X2_co <- apply(X2_raw, 2, co_filter, rho = rho_hat, p = p_opt)
X_combined_co <- cbind(X1_co, X2_co)

fgls_model <- lm(y_co ~ X_combined_co - 1)
coef_fgls <- coef(fgls_model)
vcov_fgls <- sandwich::vcovHAC(fgls_model)
se_fgls <- sqrt(diag(vcov_fgls))
t_fgls <- coef_fgls / se_fgls
p_fgls <- 2 * (1 - pnorm(abs(t_fgls)))

# Check FGLS residuals serial correlation
e_fgls <- residuals(fgls_model)
lb_test <- Box.test(e_fgls, lag = 4, type = "Ljung-Box")
cat(sprintf("Ljung-Box test on FGLS residuals (lag=4) p-value: %.4f\n", lb_test$p.value))

# ---- 5. Robust Parameter Recovery and Reporting
cat("\n=== Step 5: FGLS Parameter Recovery ===\n")
labels <- c("Const", "k_CL", "c_t", "omega_c", "omega_t")

coef_r1 <- coef_fgls[1:5]
se_r1   <- se_fgls[1:5]
coef_r2 <- coef_fgls[6:10]
se_r2   <- se_fgls[6:10]

report_regime <- function(coefs, ses, regime_name) {
  cat(sprintf("\n--- Regime %s ---\n", regime_name))
  for (i in 1:5) {
    cat(sprintf("  %-8s: Est = %7.4f (SE = %6.4f, t = %6.2f)\n",
                labels[i], coefs[i], ses[i], coefs[i]/ses[i]))
  }
  
  # Structural recovery
  A <- coefs[2]
  B <- coefs[3]
  C <- coefs[4]
  
  theta1 <- A - B
  theta2 <- A + B
  theta3 <- 2 * C
  cat(sprintf("  Recovered Infrastructure Elasticity (theta1): %.4f\n", theta1))
  cat(sprintf("  Recovered Machinery Elasticity      (theta2): %.4f\n", theta2))
  cat(sprintf("  Recovered Interaction Coefficient   (theta3): %.4f\n", theta3))
}

report_regime(coef_r1, se_r1, "1 (BOP Deficit/Constrained: CA <= gamma)")
report_regime(coef_r2, se_r2, "2 (BOP Surplus/Unconstrained: CA > gamma)")

# ---- 6. Reconstructing Utilization Series (Full Sample 1920-2024)
cat("\n=== Step 6: Utilization Reconstruction (1920-2024) ===\n")

# Align threshold variable and classify regimes for full sample
df_full <- df %>% 
  filter(year >= 1920, year <= 2024) %>%
  mutate(
    regime_idx = if_else(q_bop_lag1 <= gamma_fgls, 1, 2, missing = 1)
  )

# Compute reconstructed transformation elasticity theta_t
df_full <- df_full %>%
  mutate(
    # Selected coefficients based on regime
    alpha_est = if_else(regime_idx == 1, coef_r1[1], coef_r2[1]),
    A_est     = if_else(regime_idx == 1, coef_r1[2], coef_r2[2]),
    B_est     = if_else(regime_idx == 1, coef_r1[3], coef_r2[3]),
    C_est     = if_else(regime_idx == 1, coef_r1[4], coef_r2[4]),
    phi_est   = if_else(regime_idx == 1, coef_r1[5], coef_r2[5]),
    
    # Recovered structural variables
    theta1_est = A_est - B_est,
    theta2_est = A_est + B_est,
    theta3_est = 2 * C_est,
    
    # Transformation elasticity (time-varying)
    theta_t = theta1_est * (1 - phi) + theta2_est * phi + theta3_est * omega_t_centered * phi
  )

# Reconstruct growth rate of capacity: g_Yp = theta_t * g_K
df_full <- df_full %>%
  mutate(
    g_k_CL = c(NA, diff(k_CL)),
    g_Yp = theta_t * g_k_CL
  )

# Accumulate growth to get unanchored capacity log levels
n_full <- nrow(df_full)
y_p_unanchored <- numeric(n_full)
y_p_unanchored[1] <- df_full$y[1] # Set initial capacity equal to output

for (t in 2:n_full) {
  if (is.na(df_full$g_Yp[t])) {
    y_p_unanchored[t] <- y_p_unanchored[t-1]
  } else {
    y_p_unanchored[t] <- y_p_unanchored[t-1] + df_full$g_Yp[t]
  }
}
df_full$y_p_un = y_p_unanchored

# Apply Level-Anchor Protocol (mu_1980 = 1.0)
y_1980 <- df_full$y[df_full$year == 1980]
yp_1980_un <- df_full$y_p_un[df_full$year == 1980]
anchor_adj <- y_1980 - yp_1980_un

df_full <- df_full %>%
  mutate(
    y_p_anchored = y_p_un + anchor_adj,
    log_mu = y - y_p_anchored,
    mu_CL = exp(log_mu)
  )

cat(sprintf("Anchoring check: mu_CL[1980] = %.8f (Expected: 1.00000000)\n", 
            df_full$mu_CL[df_full$year == 1980]))

# ---- 7. Generating Visualizations & Exports
cat("\n=== Step 7: Exporting Visuals and Data ===\n")

# Plot 1: Likelihood Ratio Profile for Threshold
lr_profile <- (ssr_fgls - min(ssr_fgls)) / (min(ssr_fgls) / n_co)
df_lr <- tibble(gamma = candidates, lr = lr_profile)

p1 <- ggplot(df_lr, aes(x = gamma, y = lr)) +
  geom_line(color = "#1f77b4", linewidth = 1) +
  geom_hline(yintercept = 7.35, linetype = "dashed", color = "red", linewidth = 0.8) +
  annotate("text", x = mean(candidates), y = 8.5, label = "95% Critical Value (7.35)", color = "red") +
  labs(title = "Likelihood Ratio (LR) Profile for FGLS Threshold",
       subtitle = sprintf("Estimated Threshold (gamma) = %.4f%% GDP", gamma_fgls),
       x = "Candidate Threshold (gamma, CA % GDP)", y = "LR Statistic") +
  theme_minimal()
ggsave(file.path(OUT_FIG, "CL_S90_fgls_threshold_lr_profile.pdf"), plot = p1, width = 7, height = 4.5)
ggsave(file.path(OUT_FIG, "CL_S90_fgls_threshold_lr_profile.png"), plot = p1, width = 7, height = 4.5)

# Plot 2: Threshold Variable with Shaded Regimes
df_plot2 <- df_full %>% filter(!is.na(q_bop_lag1))
p2 <- ggplot(df_plot2, aes(x = year, y = q_bop_lag1)) +
  geom_rect(aes(xmin = year - 0.5, xmax = year + 0.5, ymin = -Inf, ymax = Inf, 
                fill = if_else(regime_idx == 1, "Regime 1: Constrained", "Regime 2: Unconstrained")), 
            alpha = 0.2) +
  geom_line(color = "black", linewidth = 0.8) +
  geom_hline(yintercept = gamma_fgls, linetype = "dotted", color = "blue", linewidth = 1) +
  scale_fill_manual(values = c("Regime 1: Constrained" = "#ff7f0e", "Regime 2: Unconstrained" = "#2ca02c")) +
  labs(title = "Chile Regime Shading & BOP Current Account Time Series",
       subtitle = sprintf("Threshold variable: Lagged Current Account %% GDP | Estimated threshold = %.4f%% GDP", gamma_fgls),
       x = "Year", y = "Lagged Current Account Balance (% GDP)", fill = "Regime Class") +
  theme_minimal()
ggsave(file.path(OUT_FIG, "CL_S90_fgls_threshold_regimes_time_series.pdf"), plot = p2, width = 8, height = 4.5)
ggsave(file.path(OUT_FIG, "CL_S90_fgls_threshold_regimes_time_series.png"), plot = p2, width = 8, height = 4.5)

# Plot 3: Reconstructed Capacity Utilization
p3 <- ggplot(df_full, aes(x = year, y = mu_CL)) +
  geom_line(color = "#7f7f7f", alpha = 0.5) +
  geom_point(color = "#1f77b4", size = 1) +
  geom_hline(yintercept = 1.0, linetype = "dashed", color = "black") +
  scale_y_continuous(labels = percent) +
  labs(title = "Reconstructed Capacity Utilization: Chile (1920-2024)",
       subtitle = "FGLS Cointegration Threshold Model | WBOP Current Account | Anchored at mu_1980 = 100%",
       x = "Year", y = "Capacity Utilization (mu_CL)") +
  theme_minimal()
ggsave(file.path(OUT_FIG, "CL_S90_fgls_threshold_mu_reconstruction.pdf"), plot = p3, width = 8, height = 4.5)
ggsave(file.path(OUT_FIG, "CL_S90_fgls_threshold_mu_reconstruction.png"), plot = p3, width = 8, height = 4.5)

# Export results to CSV
write_csv(df_full, file.path(OUT_CSV, "CL_S90_fgls_threshold_results_panel.csv"))

# Export parameter summary
df_params <- tibble(
  Regime = c("Regime 1: Constrained", "Regime 2: Unconstrained"),
  Threshold = gamma_fgls,
  Const_Est = c(coef_r1[1], coef_r2[1]), Const_SE = c(se_r1[1], se_r2[1]),
  kCL_Est   = c(coef_r1[2], coef_r2[2]), kCL_SE   = c(se_r1[2], se_r2[2]),
  c_Est     = c(coef_r1[3], coef_r2[3]), c_SE     = c(se_r1[3], se_r2[3]),
  omega_c_Est = c(coef_r1[4], coef_r2[4]), omega_c_SE = c(se_r1[4], se_r2[4]),
  omega_Est   = c(coef_r1[5], coef_r2[5]), omega_SE   = c(se_r1[5], se_r2[5]),
  theta1    = c(coef_r1[2] - coef_r1[3], coef_r2[2] - coef_r2[3]),
  theta2    = c(coef_r1[2] + coef_r1[3], coef_r2[2] + coef_r2[3]),
  theta3    = c(2 * coef_r1[4], 2 * coef_r2[4])
)
write_csv(df_params, file.path(OUT_CSV, "CL_S90_fgls_threshold_parameters.csv"))

cat("\nSUCCESS: Execution completed. All files and plots exported to output/stage_a/Chile/\n")
