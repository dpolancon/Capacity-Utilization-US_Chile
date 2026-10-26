# CL_S50_section33_imols_estimation.R
# Estimates the Threshold CMPR IM-OLS model matrix for Chile (Section 3.3/4.4)
# structured across the 4-Tier Specification Grid

library(cointReg)
library(dplyr)
library(readr)
library(matrixStats)
library(strucchange)

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
    y_t             = log(GDP_real),
    k_NR            = log(K_NR),
    k_ME            = log(K_ME),
    kappa_t         = k_ME - k_NR,
    omega_gross_lag = lag(omega_gross),
    omega_net_lag   = lag(omega_net),
    e_gross_lag     = lag(e_gross),
    e_net_lag       = lag(e_net),
    # Threshold variables
    thresh_wbop_tau       = wbop_tau,
    thresh_wbop_inc_out_x = wbop_inc_outflow_x,
    thresh_imb_level      = imbalance_level,
    thresh_solvr_m0       = SolvR_M0,
    thresh_solvr_m1       = SolvR_M1
  ) %>%
  filter(!is.na(y_t), !is.na(k_NR), !is.na(kappa_t)) %>%
  arrange(year)

# Extraction helper
extract_results <- function(fit, model_id, spec_name, p_proxy_name, thresh_var_name = "None", gamma_val = NA, tier="Tier 0") {
  est <- as.numeric(fit$theta)
  sds <- as.numeric(fit$sd.theta)
  tstat <- if(!is.null(fit$t.theta)) as.numeric(fit$t.theta) else (est / sds)
  vars <- rownames(fit$theta)
  if (is.null(vars)) vars <- colnames(fit$x)
  if (is.null(vars)) vars <- paste0("V", 1:length(est))
  
  data.frame(
    Tier         = tier,
    Model_ID     = model_id,
    Spec_Name    = spec_name,
    Price_Proxy  = p_proxy_name,
    Thresh_Var   = thresh_var_name,
    Gamma_Val    = gamma_val,
    Variable     = vars,
    Estimate     = est,
    Std_Error    = sds,
    T_Stat       = tstat,
    stringsAsFactors = FALSE
  )
}

# Helper for Profile LS Threshold Estimation
run_threshold_model <- function(df_data, thresh_col, model_id, spec_name, distr_var, p_name=NULL, price_role=0, tier="Tier 0") {
  df_est <- df_data %>% filter(!is.na(df_data[[thresh_col]]), !is.na(df_data[[distr_var]]))
  if(!is.null(p_name)) df_est <- df_est %>% filter(!is.na(.data[[p_name]]))
  
  if (nrow(df_est) < 20) return(NULL) # Skip if not enough data
  
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
    
    # Create the interacted terms
    df_temp <- df_est %>%
      mutate(
        distr_kappa = .data[[distr_var]] * kappa_t,
        kappa_D = kappa_t * D_ext,
        distr_kappa_D = distr_kappa * D_ext
      )
    
    if (price_role == 0) {
      x_temp <- df_temp %>% select(k_NR, kappa_t, distr_kappa, kappa_D, distr_kappa_D) %>% as.matrix()
    } else if (price_role == 1) { # Interacted
      df_temp <- df_temp %>% mutate(
        p_kappa_kappa = .data[[p_name]] * kappa_t,
        p_kappa_kappa_D = p_kappa_kappa * D_ext
      )
      x_temp <- df_temp %>% select(k_NR, kappa_t, distr_kappa, p_kappa_kappa, kappa_D, distr_kappa_D, p_kappa_kappa_D) %>% as.matrix()
    } else if (price_role == 2) { # Standalone Control
      df_temp <- df_temp %>% mutate(p_standalone = .data[[p_name]])
      x_temp <- df_temp %>% select(k_NR, kappa_t, distr_kappa, kappa_D, distr_kappa_D, p_standalone) %>% as.matrix()
    }
    
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
    extract_results(best_fit, model_id, spec_name, ifelse(is.null(p_name), "None", p_name), thresh_col, best_gamma, tier)
  } else {
    NULL
  }
}

results_list <- list()

# Helper to run models across a given sample period
run_sample_suite <- function(df_sample, sample_label) {
  cat(sprintf("\n--- Estimating for Sample: %s (%d - %d, N=%d) ---\n", 
              sample_label, min(df_sample$year), max(df_sample$year), nrow(df_sample)))
  
  distr_vars <- c("omega_gross_lag", "omega_net_lag", "e_gross_lag", "e_net_lag")
  thresholds <- c("thresh_solvr_m0", "thresh_solvr_m1")
  
  # --- TIER 0: Baseline Physical Core ---
  for (dvar in distr_vars) {
    for (tvar in thresholds) {
      m_id <- paste0("T0_", sample_label, "_", dvar, "_", tvar)
      res <- run_threshold_model(df_sample, tvar, m_id, paste("Baseline", dvar), dvar, NULL, 0, "Tier 0")
      if(!is.null(res)) results_list[[m_id]] <<- res
    }
  }
  
  # --- TIER 1: Standalone Controlled Models (Role 2) ---
  proxy_names_T1 <- c("p_kappa_rer", "p_kappa_ipmusa", "p_kappa_composite")
  for (pname in proxy_names_T1) {
    for (tvar in thresholds) {
      m_id <- paste0("T1_", sample_label, "_", pname, "_", tvar)
      res <- run_threshold_model(df_sample, tvar, m_id, paste("Control", pname), "omega_net_lag", pname, 2, "Tier 1")
      if(!is.null(res)) results_list[[m_id]] <<- res
    }
  }
  
  # --- TIER 2: Interacted Price Models (Role 1) - Sensitivity ---
  proxy_names_T2 <- c("p_kappa_rer", "p_kappa_ipmusa")
  for (pname in proxy_names_T2) {
    for (tvar in thresholds) {
      m_id <- paste0("T2_", sample_label, "_", pname, "_", tvar)
      res <- run_threshold_model(df_sample, tvar, m_id, paste("Interact", pname), "omega_net_lag", pname, 1, "Tier 2")
      if(!is.null(res)) results_list[[m_id]] <<- res
    }
  }
  
  # --- TIER 3: Deflated Price Index Controls (Category C) ---
  proxy_names_T3 <- c("p_kappa_py_pk", "p_kappa_py_tot_pk")
  for (pname in proxy_names_T3) {
    for (tvar in thresholds) {
      m_id <- paste0("T3_", sample_label, "_", pname, "_", tvar)
      res <- run_threshold_model(df_sample, tvar, m_id, paste("DeflControl", pname), "omega_net_lag", pname, 2, "Tier 3")
      if(!is.null(res)) results_list[[m_id]] <<- res
    }
  }
}

# Run for Extended Sample (1940-2024)
df_1940 <- df %>% filter(year >= 1940 & year <= 2024)
run_sample_suite(df_1940, "1940_2024")

# Run for Long-Run Sample starting from Great Depression (1932-2024)
df_1932 <- df %>% filter(year >= 1932 & year <= 2024)
run_sample_suite(df_1932, "1932_2024")

# Run for ISI Developmentalist Regime (1932-1973)
df_1932_1973 <- df %>% filter(year >= 1932 & year <= 1973)
run_sample_suite(df_1932_1973, "1932_1973")

# Run for Neoliberal Split Sample (1974-2024)
df_1974 <- df %>% filter(year >= 1974 & year <= 2024)
run_sample_suite(df_1974, "1974_2024")

# --- Combine and Export Results ---
all_results <- bind_rows(results_list)

out_dir <- "output"
dir.create(out_dir, showWarnings = FALSE)
out_csv <- file.path(out_dir, "chile_imols_peripheral_results_tiered.csv")
write_csv(all_results, out_csv)

cat("\nSuccessfully estimated Section 3.3 Chile Peripheral model matrix with new 4-Tier Grid and BoP thresholds.\n")
cat("Saved detailed parameter results to:", out_csv, "\n")
