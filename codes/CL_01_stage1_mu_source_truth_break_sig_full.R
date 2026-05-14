# ============================================================
# CHILE STAGE 2 — INTEGRATED BASELINE + THRESHOLD DOLS SCRIPT
# Mechanization-grounded frontier specification
# Patched to include ISI1931_1973 alongside PRE1974
# ============================================================

# -------------------------
# Packages
# -------------------------
required_pkgs <- c(
  "here", "readr", "readxl", "dplyr", "tidyr", "janitor",
  "cointReg", "ggplot2"
)

miss <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss) > 0) {
  install.packages(miss)
}

library(here)
library(readr)
library(readxl)
library(dplyr)
library(tidyr)
library(janitor)
library(cointReg)
library(ggplot2)

# ============================================================
# 0. PATHS
# ============================================================

path_k <- "C:/ReposGitHub/Capacity-Utilization-US_Chile/data/raw/Chile/harmonized_series_2003CLP_1900_2024.csv"
path_d <- "C:/ReposGitHub/Capacity-Utilization-US_Chile/data/raw/Chile/distr_19202024.xlsx"
path_pe <- "C:/ReposGitHub/Capacity-Utilization-US_Chile/data/raw/Chile/PerezEyzaguirre_DemandaAgregada.xlsx"
path_stage1_master <- here::here("output", "chile_2Smu_S1", "txt", "stage1__master_results.rds")

out_root <- here::here("output", "chile_2Smu_S2_tdols")
out_csv  <- file.path(out_root, "csv")
out_txt  <- file.path(out_root, "txt")
dir.create(out_csv, recursive = TRUE, showWarnings = FALSE)
dir.create(out_txt, recursive = TRUE, showWarnings = FALSE)

# ============================================================
# 1. HELPERS
# ============================================================

write_txt <- function(lines, path) {
  writeLines(as.character(lines), con = path, useBytes = TRUE)
}

split_sample <- function(df, sample = c("full", "pre1974", "isi1931_1973", "post1974")) {
  sample <- match.arg(sample)
  if (sample == "full") return(df)
  if (sample == "pre1974") return(dplyr::filter(df, year <= 1973))
  if (sample == "isi1931_1973") return(dplyr::filter(df, year >= 1931, year <= 1973))
  if (sample == "post1974") return(dplyr::filter(df, year >= 1974))
}

load_stage1_master <- function(path = path_stage1_master) {
  if (!file.exists(path)) {
    stop("Stage 1 master RDS not found: ", path, call. = FALSE)
  }
  readRDS(path)
}

extract_stage1_ect_by_sample <- function(stage1_master,
                                         sample,
                                         spec = "S1_B",
                                         lag = 1,
                                         rank = 1) {
  ect_tbl <- stage1_master$ect_series
  
  out <- ect_tbl %>%
    dplyr::filter(
      sample == !!sample,
      spec == !!spec,
      lag == !!lag,
      rank == !!rank
    ) %>%
    dplyr::arrange(year) %>%
    dplyr::mutate(
      ECT_m = ECT,
      ECT_m_lag1 = dplyr::lag(ECT_m, 1)
    ) %>%
    dplyr::select(year, ECT_m, ECT_m_lag1, sample, spec, lag, rank)
  
  if (nrow(out) == 0) {
    stop(
      "No Stage 1 ECT found for sample=", sample,
      ", spec=", spec, ", lag=", lag, ", rank=", rank,
      call. = FALSE
    )
  }
  
  out
}

get_cointreg_coef <- function(obj, fallback_names = NULL) {
  cf <- NULL
  
  if (!is.null(obj$theta)) {
    cf <- as.numeric(obj$theta)
  } else if (!is.null(obj$beta)) {
    cf <- as.numeric(obj$beta)
  } else {
    stop("Could not extract coefficients from cointReg object.", call. = FALSE)
  }
  
  nm <- NULL
  
  if (!is.null(obj$stage2_xvars)) {
    nm <- obj$stage2_xvars
  } else if (!is.null(obj$sd.theta) && !is.null(names(obj$sd.theta))) {
    nm <- names(obj$sd.theta)
  } else if (!is.null(obj$theta) && !is.null(names(obj$theta))) {
    nm <- names(obj$theta)
  } else if (!is.null(fallback_names) && length(fallback_names) == length(cf)) {
    nm <- fallback_names
  }
  
  if (is.null(nm)) {
    stop("Could not recover coefficient names.", call. = FALSE)
  }
  
  names(cf) <- nm
  cf
}

get_ssr_cointReg <- function(obj) {
  if (is.null(obj$residuals)) {
    stop("cointReg object has no residuals.", call. = FALSE)
  }
  
  u <- obj$residuals
  
  if (!is.numeric(u)) {
    stop("Residuals are not numeric.", call. = FALSE)
  }
  
  sum(u^2, na.rm = TRUE)
}

# -------------------------
# Threshold audit helpers
# -------------------------

inspect_threshold_years <- function(theta_df, tdols_obj, sample_name) {
  theta_df %>%
    dplyr::mutate(
      sample = sample_name,
      gamma_hat = tdols_obj$gamma_hat,
      ect_side = dplyr::if_else(ECT_m_lag1 <= gamma_hat, "below_gamma", "above_gamma")
    ) %>%
    dplyr::select(
      sample, year, ECT_m_lag1, gamma_hat, ect_side,
      regime_code, theta_r1, theta_r2, theta_active
    ) %>%
    dplyr::arrange(year)
}

regime_episodes <- function(audit_df) {
  audit_df %>%
    dplyr::arrange(year) %>%
    dplyr::mutate(
      episode = cumsum(dplyr::coalesce(regime_code != dplyr::lag(regime_code), TRUE))
    ) %>%
    dplyr::group_by(sample, episode, regime_code) %>%
    dplyr::summarise(
      start_year = min(year),
      end_year   = max(year),
      n_years    = dplyr::n(),
      ect_mean   = mean(ECT_m_lag1, na.rm = TRUE),
      theta_mean = mean(theta_active, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(sample, start_year)
}

# ============================================================
# 2. LOAD RAW DATA AND BUILD PANEL
# ============================================================

kraw <- read_csv(path_k, show_col_types = FALSE) %>% clean_names()
draw <- read_excel(path_d) %>% clean_names()
pe   <- read_excel(path_pe) %>% clean_names()

# Gross capital stocks by asset
k_wide <- kraw %>%
  dplyr::select(year, asset, kg) %>%
  tidyr::pivot_wider(names_from = asset, values_from = kg, names_prefix = "kg_")

# Demand-side panel
pe_fixed <- pe %>%
  dplyr::transmute(
    year    = x1,
    y_real  = pib_real_milllones_de_pesos_de_2003,
    i_me    = fbkf_en_maquinaria,
    i_cons  = fbkf_en_construccion,
    i_total = inversion_interna_bruta,
    m_cif   = importaciones_cif_millones_de_pesos_de_2003
  )

# Distribution panel
draw_fixed <- draw %>%
  dplyr::transmute(
    year = periodo,
    wsh  = wage_share,
    psh  = profit_share,
    e    = exploitation_rate
  )

# Core audit panel
panel_audit <- k_wide %>%
  dplyr::transmute(
    year = year,
    K_ME_gross    = kg_ME,
    K_NRC_gross   = kg_NRC,
    K_NR_gross    = kg_NR,
    K_Total_gross = kg_Total,
    K_prod_sum_ME_NRC = K_ME_gross + K_NRC_gross,
    s_ME_in_prod  = K_ME_gross / K_prod_sum_ME_NRC,
    s_ME_in_NR    = K_ME_gross / K_NR_gross,
    s_ME_in_total = K_ME_gross / K_Total_gross,
    log_K_ME       = log(K_ME_gross),
    log_K_NRC      = log(K_NRC_gross),
    log_K_NR       = log(K_NR_gross),
    log_K_Total    = log(K_Total_gross),
    log_K_prod_sum = log(K_prod_sum_ME_NRC)
  ) %>%
  dplyr::left_join(draw_fixed, by = "year") %>%
  dplyr::left_join(pe_fixed,   by = "year") %>%
  dplyr::mutate(
    log_y = log(y_real),
    omega_sME_prod = wsh * s_ME_in_prod,
    omega_sME_NR   = wsh * s_ME_in_NR
  )

# Identity check: NR = ME + NRC
nr_identity <- panel_audit %>%
  dplyr::mutate(check_NR_vs_parts = K_NR_gross - (K_ME_gross + K_NRC_gross)) %>%
  dplyr::summarise(
    min_diff = min(check_NR_vs_parts, na.rm = TRUE),
    max_diff = max(check_NR_vs_parts, na.rm = TRUE),
    mean_diff = mean(check_NR_vs_parts, na.rm = TRUE)
  )

readr::write_csv(nr_identity, file.path(out_csv, "stage2__nr_identity_check.csv"))

# ============================================================
# 3. BUILD STAGE 2 WORKING DATA
# ============================================================

df0 <- panel_audit %>%
  dplyr::transmute(
    year = year,
    y    = log_y,
    k_nr = log_K_NR,
    k_me = log_K_ME,
    s_me = s_ME_in_NR,
    wsh  = wsh
  ) %>%
  dplyr::mutate(
    k_nr_sme  = k_nr * s_me,
    k_nr_wsme = k_nr * wsh * s_me,
    s_me_c  = s_me - mean(s_me, na.rm = TRUE),
    wsh_c   = wsh - mean(wsh, na.rm = TRUE),
    k_nr_sme_c  = k_nr * s_me_c,
    k_nr_wsme_c = k_nr * wsh_c * s_me_c,
    wsme = wsh * s_me,
    wsh_kme = wsh * k_me
  ) %>%
  dplyr::filter(
    is.finite(y),
    is.finite(k_nr),
    is.finite(k_me),
    is.finite(s_me),
    is.finite(wsh)
  )

readr::write_csv(df0, file.path(out_csv, "stage2__working_panel.csv"))

# ============================================================
# 4. BASELINE DOLS
# ============================================================

run_dols <- function(df, xvars) {
  cointRegD(
    y = df$y,
    x = as.data.frame(df[, xvars]),
    deter = matrix(1, nrow = nrow(df), ncol = 1),
    kmax = "k4",
    info.crit = "BIC"
  )
}

run_baseline_suite <- function(df, sample_name) {
  fits <- list(
    A_main     = run_dols(df, c("k_nr", "k_nr_sme", "k_nr_wsme")),
    A_centered = run_dols(df, c("k_nr", "k_nr_sme_c", "k_nr_wsme_c")),
    B_additive = run_dols(df, c("k_nr", "s_me", "wsme")),
    C_legacy   = run_dols(df, c("k_nr", "k_me", "wsh_kme"))
  )
  
  lines <- c(paste0("Baseline DOLS results — ", sample_name))
  for (nm in names(fits)) {
    lines <- c(lines, "", paste0("----- ", nm, " -----"), capture.output(print(fits[[nm]])))
  }
  
  write_txt(lines, file.path(out_txt, paste0("baseline_dols__", sample_name, ".txt")))
  fits
}

baseline_results <- list(
  full         = run_baseline_suite(split_sample(df0, "full"), "full"),
  pre1974      = run_baseline_suite(split_sample(df0, "pre1974"), "pre1974"),
  isi1931_1973 = run_baseline_suite(split_sample(df0, "isi1931_1973"), "isi1931_1973"),
  post1974     = run_baseline_suite(split_sample(df0, "post1974"), "post1974")
)

# ============================================================
# 5. RECOVER THETA FROM BASELINE MODEL A
# ============================================================

theta_from_A <- function(df, fit_obj) {
  b <- get_cointreg_coef(fit_obj)
  
  nm_k_nr      <- grep("^k_nr$", names(b), value = TRUE)
  nm_k_nr_sme  <- grep("^k_nr_sme$", names(b), value = TRUE)
  nm_k_nr_wsme <- grep("^k_nr_wsme$", names(b), value = TRUE)
  
  if (length(nm_k_nr) != 1 || length(nm_k_nr_sme) != 1 || length(nm_k_nr_wsme) != 1) {
    stop("Could not uniquely identify baseline slope names.", call. = FALSE)
  }
  
  df %>%
    dplyr::mutate(
      theta_hat =
        unname(b[nm_k_nr]) +
        unname(b[nm_k_nr_sme])  * s_me +
        unname(b[nm_k_nr_wsme]) * (wsh * s_me)
    ) %>%
    dplyr::select(year, theta_hat)
}

theta_full <- theta_from_A(split_sample(df0, "full"),         baseline_results$full$A_main)
theta_pre  <- theta_from_A(split_sample(df0, "pre1974"),      baseline_results$pre1974$A_main)
theta_isi  <- theta_from_A(split_sample(df0, "isi1931_1973"), baseline_results$isi1931_1973$A_main)
theta_post <- theta_from_A(split_sample(df0, "post1974"),     baseline_results$post1974$A_main)

readr::write_csv(theta_full, file.path(out_csv, "baseline_theta__full.csv"))
readr::write_csv(theta_pre,  file.path(out_csv, "baseline_theta__pre1974.csv"))
readr::write_csv(theta_isi,  file.path(out_csv, "baseline_theta__isi1931_1973.csv"))
readr::write_csv(theta_post, file.path(out_csv, "baseline_theta__post1974.csv"))

# ============================================================
# 6. LOAD STAGE 1 ECT OBJECTS
# ============================================================

stage1_master <- load_stage1_master()

ect_full <- extract_stage1_ect_by_sample(stage1_master, sample = "FULL")
ect_pre  <- extract_stage1_ect_by_sample(stage1_master, sample = "PRE1974")
ect_isi  <- extract_stage1_ect_by_sample(stage1_master, sample = "ISI1931_1973")
ect_post <- extract_stage1_ect_by_sample(stage1_master, sample = "POST1974")

df_full <- split_sample(df0, "full") %>%
  dplyr::left_join(ect_full %>% dplyr::select(year, ECT_m, ECT_m_lag1), by = "year") %>%
  dplyr::filter(is.finite(ECT_m_lag1))

df_pre <- split_sample(df0, "pre1974") %>%
  dplyr::left_join(ect_pre %>% dplyr::select(year, ECT_m, ECT_m_lag1), by = "year") %>%
  dplyr::filter(is.finite(ECT_m_lag1))

df_isi <- split_sample(df0, "isi1931_1973") %>%
  dplyr::left_join(ect_isi %>% dplyr::select(year, ECT_m, ECT_m_lag1), by = "year") %>%
  dplyr::filter(is.finite(ECT_m_lag1))

df_post <- split_sample(df0, "post1974") %>%
  dplyr::left_join(ect_post %>% dplyr::select(year, ECT_m, ECT_m_lag1), by = "year") %>%
  dplyr::filter(is.finite(ECT_m_lag1))

# ============================================================
# 7. THRESHOLD DOLS FOR MODEL A
# ============================================================

make_threshold_regressors_A <- function(df, gamma) {
  df %>%
    dplyr::mutate(
      R = as.integer(ECT_m_lag1 > gamma),
      c0_r1 = 1 - R,
      c0_r2 = R,
      knr_r1 = (1 - R) * k_nr,
      knr_r2 = R * k_nr,
      knr_sme_r1 = (1 - R) * k_nr_sme,
      knr_sme_r2 = R * k_nr_sme,
      knr_wsme_r1 = (1 - R) * k_nr_wsme,
      knr_wsme_r2 = R * k_nr_wsme
    )
}

fit_threshold_dols_A <- function(df, gamma, n_lag = 1, n_lead = 1, min_regime_n = 8) {
  work <- make_threshold_regressors_A(df, gamma)
  
  n_r1 <- sum(work$R == 0, na.rm = TRUE)
  n_r2 <- sum(work$R == 1, na.rm = TRUE)
  
  if (n_r1 < min_regime_n || n_r2 < min_regime_n) {
    stop(sprintf("Regime split too small: n_r1=%d, n_r2=%d", n_r1, n_r2), call. = FALSE)
  }
  
  xvars <- c(
    "c0_r1", "c0_r2",
    "knr_r1", "knr_r2",
    "knr_sme_r1", "knr_sme_r2",
    "knr_wsme_r1", "knr_wsme_r2"
  )
  
  fit <- cointRegD(
    y = work$y,
    x = as.data.frame(work[, xvars]),
    deter = NULL,
    n.lag = n_lag,
    n.lead = n_lead
  )
  
  fit$stage2_xvars <- xvars
  
  list(
    fit = fit,
    data = work,
    gamma = gamma,
    xvars = xvars,
    n_r1 = n_r1,
    n_r2 = n_r2
  )
}

grid_search_threshold_dols_A <- function(df,
                                         trim = 0.10,
                                         ngrid = 200,
                                         n_lag = 1,
                                         n_lead = 1,
                                         min_regime_n = 8) {
  gamma_grid <- unique(
    quantile(
      df$ECT_m_lag1,
      probs = seq(trim, 1 - trim, length.out = ngrid),
      na.rm = TRUE
    )
  )
  
  grid_out <- lapply(gamma_grid, function(g) {
    obj <- tryCatch(
      fit_threshold_dols_A(
        df = df,
        gamma = g,
        n_lag = n_lag,
        n_lead = n_lead,
        min_regime_n = min_regime_n
      ),
      error = function(e) e
    )
    
    if (inherits(obj, "error")) {
      return(tibble(
        gamma = g,
        ok = FALSE,
        ssr = NA_real_,
        n_r1 = NA_integer_,
        n_r2 = NA_integer_,
        msg = conditionMessage(obj)
      ))
    }
    
    tibble(
      gamma = g,
      ok = TRUE,
      ssr = get_ssr_cointReg(obj$fit),
      n_r1 = obj$n_r1,
      n_r2 = obj$n_r2,
      msg = NA_character_
    )
  }) %>%
    bind_rows()
  
  valid_grid <- grid_out %>%
    dplyr::filter(ok, is.finite(ssr))
  
  if (nrow(valid_grid) == 0) {
    stop("Threshold grid search found no valid gamma values.", call. = FALSE)
  }
  
  gamma_hat <- valid_grid$gamma[which.min(valid_grid$ssr)]
  
  final_obj <- fit_threshold_dols_A(
    df = df,
    gamma = gamma_hat,
    n_lag = n_lag,
    n_lead = n_lead,
    min_regime_n = min_regime_n
  )
  
  list(
    gamma_grid = grid_out,
    gamma_hat = gamma_hat,
    fit = final_obj$fit,
    data = final_obj$data,
    n_r1 = final_obj$n_r1,
    n_r2 = final_obj$n_r2
  )
}

# ============================================================
# 8. RUN THRESHOLD DOLS BY SAMPLE
# ============================================================

tdols_full <- grid_search_threshold_dols_A(df_full, trim = 0.10, ngrid = 200)
tdols_pre  <- grid_search_threshold_dols_A(df_pre,  trim = 0.10, ngrid = 200)
tdols_isi  <- grid_search_threshold_dols_A(df_isi,  trim = 0.10, ngrid = 200)
tdols_post <- grid_search_threshold_dols_A(df_post, trim = 0.10, ngrid = 200)

readr::write_csv(tdols_full$gamma_grid, file.path(out_csv, "threshold_dols_grid__full.csv"))
readr::write_csv(tdols_pre$gamma_grid,  file.path(out_csv, "threshold_dols_grid__pre1974.csv"))
readr::write_csv(tdols_isi$gamma_grid,  file.path(out_csv, "threshold_dols_grid__isi1931_1973.csv"))
readr::write_csv(tdols_post$gamma_grid, file.path(out_csv, "threshold_dols_grid__post1974.csv"))

write_txt(
  c(
    paste0("Threshold DOLS gamma — full: ", tdols_full$gamma_hat),
    paste0("Threshold DOLS gamma — pre1974: ", tdols_pre$gamma_hat),
    paste0("Threshold DOLS gamma — isi1931_1973: ", tdols_isi$gamma_hat),
    paste0("Threshold DOLS gamma — post1974: ", tdols_post$gamma_hat)
  ),
  file.path(out_txt, "threshold_dols__gammas.txt")
)

write_txt(c("Threshold DOLS — FULL", capture.output(print(tdols_full$fit))),
          file.path(out_txt, "threshold_dols__full.txt"))
write_txt(c("Threshold DOLS — PRE1974", capture.output(print(tdols_pre$fit))),
          file.path(out_txt, "threshold_dols__pre1974.txt"))
write_txt(c("Threshold DOLS — ISI1931_1973", capture.output(print(tdols_isi$fit))),
          file.path(out_txt, "threshold_dols__isi1931_1973.txt"))
write_txt(c("Threshold DOLS — POST1974", capture.output(print(tdols_post$fit))),
          file.path(out_txt, "threshold_dols__post1974.txt"))

# ============================================================
# 9. RECOVER REGIME-SPECIFIC THETA
# ============================================================

theta_from_threshold_A <- function(df_work, fit_obj) {
  fallback_names <- c(
    "c0_r1", "c0_r2",
    "knr_r1", "knr_r2",
    "knr_sme_r1", "knr_sme_r2",
    "knr_wsme_r1", "knr_wsme_r2"
  )
  
  b <- get_cointreg_coef(fit_obj, fallback_names = fallback_names)
  
  df_work %>%
    dplyr::mutate(
      theta_r1 =
        b["knr_r1"] +
        b["knr_sme_r1"]  * s_me +
        b["knr_wsme_r1"] * (wsh * s_me),
      theta_r2 =
        b["knr_r2"] +
        b["knr_sme_r2"]  * s_me +
        b["knr_wsme_r2"] * (wsh * s_me),
      regime_code = dplyr::if_else(R == 1L, "high_ect_side", "low_ect_side"),
      theta_active = dplyr::if_else(R == 1L, theta_r2, theta_r1)
    ) %>%
    dplyr::select(year, ECT_m_lag1, regime_code, theta_r1, theta_r2, theta_active)
}

theta_tdols_full <- theta_from_threshold_A(tdols_full$data, tdols_full$fit)
theta_tdols_pre  <- theta_from_threshold_A(tdols_pre$data,  tdols_pre$fit)
theta_tdols_isi  <- theta_from_threshold_A(tdols_isi$data,  tdols_isi$fit)
theta_tdols_post <- theta_from_threshold_A(tdols_post$data, tdols_post$fit)

readr::write_csv(theta_tdols_full, file.path(out_csv, "threshold_theta__full.csv"))
readr::write_csv(theta_tdols_pre,  file.path(out_csv, "threshold_theta__pre1974.csv"))
readr::write_csv(theta_tdols_isi,  file.path(out_csv, "threshold_theta__isi1931_1973.csv"))
readr::write_csv(theta_tdols_post, file.path(out_csv, "threshold_theta__post1974.csv"))

# ============================================================
# 10. YEAR-BY-YEAR AUDIT + EPISODES
# ============================================================

audit_full <- inspect_threshold_years(theta_tdols_full, tdols_full, "FULL")
audit_pre  <- inspect_threshold_years(theta_tdols_pre,  tdols_pre,  "PRE1974")
audit_isi  <- inspect_threshold_years(theta_tdols_isi,  tdols_isi,  "ISI1931_1973")
audit_post <- inspect_threshold_years(theta_tdols_post, tdols_post, "POST1974")

readr::write_csv(audit_full, file.path(out_csv, "threshold_audit__full.csv"))
readr::write_csv(audit_pre,  file.path(out_csv, "threshold_audit__pre1974.csv"))
readr::write_csv(audit_isi,  file.path(out_csv, "threshold_audit__isi1931_1973.csv"))
readr::write_csv(audit_post, file.path(out_csv, "threshold_audit__post1974.csv"))

episodes_all <- dplyr::bind_rows(audit_full, audit_pre, audit_isi, audit_post) %>%
  regime_episodes()

readr::write_csv(episodes_all, file.path(out_csv, "threshold_regime_episodes__all.csv"))

# ============================================================
# 11. SIMPLE SUMMARIES
# ============================================================

theta_summary <- bind_rows(
  theta_tdols_full %>% mutate(sample = "full"),
  theta_tdols_pre  %>% mutate(sample = "pre1974"),
  theta_tdols_isi  %>% mutate(sample = "isi1931_1973"),
  theta_tdols_post %>% mutate(sample = "post1974")
) %>%
  group_by(sample, regime_code) %>%
  summarise(
    n = n(),
    theta_mean = mean(theta_active, na.rm = TRUE),
    theta_sd   = sd(theta_active, na.rm = TRUE),
    theta_min  = min(theta_active, na.rm = TRUE),
    theta_max  = max(theta_active, na.rm = TRUE),
    .groups = "drop"
  )

readr::write_csv(theta_summary, file.path(out_csv, "threshold_theta__summary.csv"))

# ============================================================
# 12. CONSOLE CHECKS
# ============================================================

cat("\n==============================\n")
cat("Threshold gamma summary\n")
cat("==============================\n")
cat("FULL gamma        = ", tdols_full$gamma_hat, "\n", sep = "")
cat("PRE1974 gamma     = ", tdols_pre$gamma_hat, "\n", sep = "")
cat("ISI1931_1973 gamma= ", tdols_isi$gamma_hat, "\n", sep = "")
cat("POST1974 gamma    = ", tdols_post$gamma_hat, "\n", sep = "")

cat("\n==============================\n")
cat("Threshold regime counts\n")
cat("==============================\n")
print(table(tdols_full$data$R))
print(table(tdols_pre$data$R))
print(table(tdols_isi$data$R))
print(table(tdols_post$data$R))

# ============================================================
# 13. SESSION SUMMARY
# ============================================================

summary_lines <- c(
  "Chile Stage 2 integrated DOLS run completed.",
  "",
  "Baseline DOLS fitted for:",
  " - full",
  " - pre1974",
  " - isi1931_1973",
  " - post1974",
  "",
  "Threshold DOLS fitted for Model A in:",
  paste0(" - full gamma_hat = ", tdols_full$gamma_hat),
  paste0(" - pre1974 gamma_hat = ", tdols_pre$gamma_hat),
  paste0(" - isi1931_1973 gamma_hat = ", tdols_isi$gamma_hat),
  paste0(" - post1974 gamma_hat = ", tdols_post$gamma_hat),
  "",
  "Core exports:",
  " - baseline_dols__*.txt",
  " - baseline_theta__*.csv",
  " - threshold_dols_grid__*.csv",
  " - threshold_dols__*.txt",
  " - threshold_theta__*.csv",
  " - threshold_audit__*.csv",
  " - threshold_regime_episodes__all.csv",
  " - threshold_theta__summary.csv"
)

write_txt(summary_lines, file.path(out_txt, "stage2__session_summary.txt"))
cat(paste(summary_lines, collapse = "\n"), "\n")


# ============================================================
# 14. SIGNIFICANCE CODING + STRUCTURAL BREAK ADD-ON
# ============================================================

stage1_sig_code <- function(p) {
  dplyr::case_when(
    is.na(p)      ~ NA_integer_,
    p < 0.01      ~ 3L,
    p < 0.05      ~ 2L,
    p < 0.10      ~ 1L,
    TRUE          ~ 0L
  )
}

stage1_sig_label <- function(code) {
  dplyr::case_when(
    is.na(code) ~ NA_character_,
    code == 3L ~ "99",
    code == 2L ~ "95",
    code == 1L ~ "90",
    code == 0L ~ "0",
    TRUE ~ NA_character_
  )
}

stage1_add_sig_columns <- function(df, p_col = "p_value") {
  if (!p_col %in% names(df)) return(df)
  df %>%
    dplyr::mutate(
      sig_code = stage1_sig_code(.data[[p_col]]),
      sig_label = stage1_sig_label(sig_code)
    )
}

stage1_export_sig_companions <- function(stage1_master, paths) {
  white_sig <- stage1_add_sig_columns(stage1_master$white, "p_value")
  lm_sig    <- stage1_add_sig_columns(stage1_master$lm, "p_value")
  jb_sig    <- stage1_add_sig_columns(stage1_master$jb, "p_value")

  rank_sig <- stage1_master$rank %>%
    dplyr::mutate(
      sig_code = dplyr::case_when(
        statistic > cv_1pct ~ 3L,
        statistic > cv_5pct ~ 2L,
        statistic > cv_10pct ~ 1L,
        TRUE ~ 0L
      ),
      sig_label = stage1_sig_label(sig_code)
    )

  stage1_export_table(white_sig, "stage1__white_sig", paths)
  stage1_export_table(lm_sig, "stage1__lm_sig", paths)
  stage1_export_table(jb_sig, "stage1__jb_sig", paths)
  stage1_export_table(rank_sig, "stage1__rank_sig", paths)

  list(
    white_sig = white_sig,
    lm_sig = lm_sig,
    jb_sig = jb_sig,
    rank_sig = rank_sig
  )
}

stage1_parse_coef_entry <- function(x) {
  x <- trimws(as.character(x))
  if (is.na(x) || x == "") {
    return(tibble::tibble(estimate = NA_real_, std_error = NA_real_, z_stat = NA_real_, p_value = NA_real_, stars_printed = NA_character_))
  }

  m <- stringr::str_match(x, "^([+-]?[0-9]*\\.?[0-9]+(?:[eE][+-]?[0-9]+)?)\\(([^)]+)\\)(\\*+)?$")
  if (all(is.na(m))) {
    return(tibble::tibble(estimate = NA_real_, std_error = NA_real_, z_stat = NA_real_, p_value = NA_real_, stars_printed = NA_character_))
  }

  est <- suppressWarnings(as.numeric(m[2]))
  se  <- suppressWarnings(as.numeric(m[3]))
  z   <- if (is.finite(est) && is.finite(se) && !is.na(se) && se > 0) est / se else NA_real_
  p   <- if (is.finite(z)) 2 * stats::pnorm(-abs(z)) else NA_real_
  stars <- ifelse(is.na(m[4]), "", m[4])

  tibble::tibble(
    estimate = est,
    std_error = se,
    z_stat = z,
    p_value = p,
    stars_printed = stars
  )
}

stage1_term_clean <- function(x) {
  x <- trimws(as.character(x))
  x <- stringr::str_replace_all(x, "\\s+-1$", "_lag1")
  x <- stringr::str_replace_all(x, "\\s+", "_")
  x
}

stage1_extract_vecm_terms_from_fit <- function(fit, sample_name, spec_name, lag, rank) {
  sm_lines <- capture.output(summary(fit))

  out_rows <- list()
  current_terms <- NULL

  for (ln in sm_lines) {
    trimmed <- trimws(ln)
    if (trimmed == "") next

    is_header <- !startsWith(trimmed, "Equation") &&
      (grepl("ECT", trimmed, fixed = TRUE) || grepl("Intercept", trimmed, fixed = TRUE) || grepl("-1", trimmed, fixed = TRUE)) &&
      !grepl("Cointegrating vector", trimmed, fixed = TRUE)

    if (is_header) {
      current_terms <- unlist(strsplit(trimmed, "\\s{2,}"))
      current_terms <- current_terms[current_terms != ""]
      next
    }

    if (startsWith(trimmed, "Equation") && !is.null(current_terms)) {
      parts <- unlist(strsplit(trimmed, "\\s{2,}"))
      parts <- parts[parts != ""]
      if (length(parts) < 2) next

      equation <- sub("^Equation\\s+", "", parts[1])
      vals <- parts[-1]
      if (length(vals) < length(current_terms)) {
        vals <- c(vals, rep(NA_character_, length(current_terms) - length(vals)))
      }

      for (j in seq_along(current_terms)) {
        parsed <- stage1_parse_coef_entry(vals[j])
        out_rows[[length(out_rows) + 1L]] <- tibble::tibble(
          sample = sample_name,
          spec = spec_name,
          lag = lag,
          rank = rank,
          equation = equation,
          term_raw = current_terms[j],
          term = stage1_term_clean(current_terms[j])
        ) %>%
          dplyr::bind_cols(parsed)
      }
    }
  }

  if (length(out_rows) == 0) {
    return(tibble::tibble(
      sample = character(), spec = character(), lag = integer(), rank = integer(),
      equation = character(), term_raw = character(), term = character(),
      estimate = numeric(), std_error = numeric(), z_stat = numeric(), p_value = numeric(),
      stars_printed = character(), sig_code = integer(), sig_label = character()
    ))
  }

  dplyr::bind_rows(out_rows) %>%
    dplyr::mutate(
      sig_code = stage1_sig_code(p_value),
      sig_label = stage1_sig_label(sig_code)
    )
}

stage1_export_vecm_terms_with_sig <- function(paths) {
  fit_files <- list.files(paths$txt, pattern = "^stage1__vecm__.*__lag[0-9]+__r[0-9]+\\.rds$", full.names = TRUE)
  if (length(fit_files) == 0) {
    return(tibble::tibble())
  }

  parse_name <- function(path) {
    nm <- basename(path)
    m <- stringr::str_match(nm, "^stage1__vecm__(.+)__(S1_[A-Z])__lag([0-9]+)__r([0-9]+)\\.rds$")
    if (all(is.na(m))) return(NULL)
    list(sample = m[2], spec = m[3], lag = as.integer(m[4]), rank = as.integer(m[5]))
  }

  out <- lapply(fit_files, function(fp) {
    meta <- parse_name(fp)
    if (is.null(meta)) return(NULL)
    fit <- readRDS(fp)
    stage1_extract_vecm_terms_from_fit(fit, meta$sample, meta$spec, meta$lag, meta$rank)
  })

  out <- dplyr::bind_rows(out)
  if (nrow(out) > 0) {
    stage1_export_table(out, "stage1__vecm_terms_sig", paths)
  }
  out
}

stage1_structural_break_test_by_spec <- function(df, spec_name, spec, break_year = 1974L) {
  rhs <- spec$rhs
  lhs <- spec$lhs

  df_bp <- df %>%
    dplyr::filter(year >= 1931) %>%
    dplyr::mutate(post_break = as.integer(year >= break_year))

  vars <- c("year", lhs, rhs, "post_break")
  df_bp <- df_bp[stats::complete.cases(df_bp[, vars, drop = FALSE]), vars, drop = FALSE]

  n_isi <- sum(df_bp$post_break == 0, na.rm = TRUE)
  n_post <- sum(df_bp$post_break == 1, na.rm = TRUE)

  if (n_isi < 15 || n_post < 15) {
    stop("Insufficient observations for structural break test in spec ", spec_name, call. = FALSE)
  }

  rhs_str <- paste(rhs, collapse = " + ")
  f_null <- stats::as.formula(paste(lhs, "~", rhs_str))
  f_intercept <- stats::as.formula(paste(lhs, "~ post_break +", rhs_str))
  f_full <- stats::as.formula(paste(lhs, "~ post_break * (", rhs_str, ")"))

  fit_null <- stats::lm(f_null, data = df_bp)
  fit_intercept <- stats::lm(f_intercept, data = df_bp)
  fit_full <- stats::lm(f_full, data = df_bp)

  test_intercept <- stats::anova(fit_null, fit_intercept)
  test_any <- stats::anova(fit_null, fit_full)
  test_slopes <- stats::anova(fit_intercept, fit_full)

  get_row <- function(tab, test_type) {
    idx <- nrow(tab)
    tibble::tibble(
      spec = spec_name,
      test_type = test_type,
      break_year = break_year,
      n_total = nrow(df_bp),
      n_isi = n_isi,
      n_post = n_post,
      df_num = unname(tab$Df[idx]),
      df_den = unname(tab$Res.Df[idx]),
      f_stat = unname(tab$F[idx]),
      p_value = unname(tab$`Pr(>F)`[idx])
    ) %>%
      dplyr::mutate(
        sig_code = stage1_sig_code(p_value),
        sig_label = stage1_sig_label(sig_code)
      )
  }

  coef_tbl <- broom::tidy(fit_full) %>%
    dplyr::mutate(
      spec = spec_name,
      break_year = break_year,
      sig_code = stage1_sig_code(p.value),
      sig_label = stage1_sig_label(sig_code)
    ) %>%
    dplyr::rename(
      estimate = estimate,
      std_error = std.error,
      statistic = statistic,
      p_value = p.value,
      term = term
    ) %>%
    dplyr::select(spec, break_year, term, estimate, std_error, statistic, p_value, sig_code, sig_label)

  list(
    summary = dplyr::bind_rows(
      get_row(test_intercept, "intercept_shift"),
      get_row(test_slopes, "slope_shift"),
      get_row(test_any, "joint_break")
    ),
    coefficients = coef_tbl,
    models = list(null = fit_null, intercept = fit_intercept, full = fit_full)
  )
}

stage1_run_structural_break_addon <- function(data_path = stage1_data_path(), break_year = 1974L, spec_targets = c("S1_A", "S1_B", "S1_C", "S1_D")) {
  paths <- stage1_paths()
  df_raw <- stage1_read_panel(data_path)
  df <- stage1_prepare_data(df_raw)
  specs <- stage1_spec_registry()

  specs_use <- specs[intersect(spec_targets, names(specs))]
  if (length(specs_use) == 0) stop("No valid specs for structural break add-on.", call. = FALSE)

  out_sum <- list()
  out_coef <- list()

  for (nm in names(specs_use)) {
    res <- stage1_structural_break_test_by_spec(df, nm, specs_use[[nm]], break_year = break_year)
    out_sum[[nm]] <- res$summary
    out_coef[[nm]] <- res$coefficients
  }

  break_summary <- dplyr::bind_rows(out_sum)
  break_coefficients <- dplyr::bind_rows(out_coef)

  stage1_export_table(break_summary, "stage1__structural_break_isi_post", paths)
  stage1_export_table(break_coefficients, "stage1__structural_break_isi_post_terms", paths)

  list(summary = break_summary, coefficients = break_coefficients)
}

# -------------------------
# Export significance companions for existing diagnostic tables
# -------------------------

sig_exports <- stage1_export_sig_companions(stage1_master, stage1_paths())
vecm_terms_sig <- stage1_export_vecm_terms_with_sig(stage1_paths())

# -------------------------
# Structural break add-on: ISI vs POST only
# -------------------------

break_addon <- stage1_run_structural_break_addon(
  data_path = stage1_data_path(),
  break_year = 1974L,
  spec_targets = c("S1_A", "S1_B", "S1_C", "S1_D")
)

# Attach to master and resave
stage1_master$significance_exports <- sig_exports
stage1_master$vecm_terms_sig <- vecm_terms_sig
stage1_master$structural_break_isi_post <- break_addon
saveRDS(stage1_master, file = file.path(stage1_paths()$txt, "stage1__master_results.rds"))

writeLines(
  c(
    "Stage 1 add-on completed.",
    "Added: structural break tests for ISI vs POST with break at 1974.",
    "Added: significance-coded companion tables using 3/2/1/0 convention.",
    "Added: parsed VECM term table with estimates, standard errors, p-values, and significance codes.",
    "",
    "New exports:",
    "- csv/stage1__white_sig.csv",
    "- csv/stage1__lm_sig.csv",
    "- csv/stage1__jb_sig.csv",
    "- csv/stage1__rank_sig.csv",
    "- csv/stage1__vecm_terms_sig.csv",
    "- csv/stage1__structural_break_isi_post.csv",
    "- csv/stage1__structural_break_isi_post_terms.csv"
  ),
  con = file.path(stage1_paths()$txt, "stage1__addon_manifest.txt")
)
