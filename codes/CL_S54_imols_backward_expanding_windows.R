# CL_S54_imols_backward_expanding_windows.R
# Executes a backward-expanding window T-CMPR IM-OLS estimation.
# Anchors the end period at 1973 (end of ISI) and expands the start year
# backwards from 1954 down to 1932 to trace the parameter stability of the developmentalist regime.

library(cointReg)
library(dplyr)
library(readr)
library(matrixStats)
library(tidyr)

# Setup
repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
cpr_imols_path <- file.path(repo_root, ".agents/skills/cpr-im-ols/scripts/cpr_imols_estimator.R")
if (file.exists(cpr_imols_path)) {
  source(cpr_imols_path)
} else {
  cointRegIM_CMPR <- function(x, y, deter, x_base=NULL) {
    cointRegIM(x = x, y = y, deter = deter)
  }
}

panel_path <- "data/staged/ch2_panel_chile_with_prices.csv"
df_raw <- read_csv(panel_path, show_col_types = FALSE)

# Clean and transform
df <- df_raw %>%
  mutate(
    y_t          = log(GDP_real),
    k_NR         = log(K_NR),
    k_ME         = log(K_ME),
    kappa_t      = k_ME - k_NR,
    omega_net_lag = lag(omega_net),
    thresh_wbop_tau = wbop_tau,
    thresh_solvr_m0 = SolvR_M0
  ) %>%
  filter(!is.na(y_t), !is.na(k_NR), !is.na(kappa_t), !is.na(omega_net_lag), !is.na(thresh_solvr_m0)) %>%
  arrange(year)

# Threshold helper
run_threshold_model <- function(df_est, thresh_col) {
  y <- as.matrix(df_est$y_t)
  x_base <- as.matrix(df_est %>% select(k_NR, kappa_t))
  deter <- matrix(1, nrow = nrow(df_est), ncol = 1)
  colnames(deter) <- c("intercept")
  
  thresh_vals <- df_est[[thresh_col]]
  gamma_grid <- quantile(thresh_vals, probs = seq(0.15, 0.85, by = 0.05), na.rm = TRUE)
  
  best_ssr <- Inf
  best_gamma <- NA
  best_fit <- NULL
  
  for (g in gamma_grid) {
    D_ext <- ifelse(thresh_vals <= g, 1, 0)
    x_temp <- df_est %>%
      mutate(
        omega_kappa = omega_net_lag * kappa_t,
        kappa_D = kappa_t * D_ext,
        omega_kappa_D = omega_kappa * D_ext
      ) %>%
      select(k_NR, kappa_t, omega_kappa, kappa_D, omega_kappa_D) %>%
      as.matrix()
    
    fit_temp <- tryCatch({ cointRegIM_CMPR(x = x_temp, y = y, deter = deter, x_base = x_base) }, error = function(e) NULL)
    if (!is.null(fit_temp)) {
      ssr <- sum(fit_temp$residuals^2)
      if (ssr < best_ssr) {
        best_ssr <- ssr
        best_gamma <- g
        best_fit <- fit_temp
      }
    }
  }
  
  if (!is.null(best_fit)) {
    est <- as.numeric(best_fit$theta)
    sds <- as.numeric(best_fit$sd.theta)
    tstat <- if(!is.null(best_fit$t.theta)) as.numeric(best_fit$t.theta) else (est / sds)
    vars <- rownames(best_fit$theta)
    if (is.null(vars)) vars <- colnames(best_fit$x)
    if (is.null(vars)) vars <- paste0("V", 1:length(est))
    
    data.frame(
      Variable     = vars,
      Estimate     = est,
      T_Stat       = tstat,
      Gamma_Val    = best_gamma,
      stringsAsFactors = FALSE
    )
  } else {
    NULL
  }
}

# Run Backward Expanding Window
end_year <- 1973
start_years <- seq(1954, 1932, by = -1)
results_list <- list()

cat("Starting backward expanding window analysis anchored at 1973...\n")
for (s_year in start_years) {
  df_sample <- df %>% filter(year >= s_year & year <= end_year)
  cat(sprintf("Running window: %d - %d (N = %d)\n", s_year, end_year, nrow(df_sample)))
  
  res <- run_threshold_model(df_sample, "thresh_solvr_m0")
  if (!is.null(res)) {
    res$Start_Year <- s_year
    res$End_Year <- end_year
    res$Window_Size <- nrow(df_sample)
    results_list[[as.character(s_year)]] <- res
  }
}

all_results <- bind_rows(results_list)

# Reshape to wide format for easier analysis of parameter traces
# We want to pivot the variable estimates and t-stats so each row is a window (Start_Year)
trace_wide <- all_results %>%
  select(Start_Year, End_Year, Window_Size, Gamma_Val, Variable, Estimate, T_Stat) %>%
  pivot_wider(
    names_from = Variable, 
    values_from = c(Estimate, T_Stat),
    names_glue = "{Variable}_{.value}"
  ) %>%
  arrange(Start_Year)

out_dir <- "output"
dir.create(out_dir, showWarnings = FALSE)
out_csv <- file.path(out_dir, "chile_imols_backward_trace_1973.csv")
write_csv(trace_wide, out_csv)

cat("Successfully completed backward expanding trace. Results saved to:", out_csv, "\n")
