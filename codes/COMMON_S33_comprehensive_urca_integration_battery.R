#!/usr/bin/env Rscript

# COMMON_S33_comprehensive_urca_integration_battery.R
# Evaluates unit root and stationarity tests on LEVELS and FIRST DIFFERENCES (I(1) verification)
# for composing capital assets (k_ME and k_NRC/k_NR) across exact window boundaries.

suppressPackageStartupMessages({
  if (requireNamespace("urca", quietly = TRUE)) library(urca)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
cl_file   <- file.path(repo_root, "data", "processed", "cl_s20", "chile_orthogonalized_panel.csv")
us_file   <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
out_dir   <- file.path(repo_root, "output")

if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

unit_root_results  <- list()
cointegration_results <- list()

extract_urca_stats <- function(ur_obj, test_name, control_type) {
  if (is.null(ur_obj)) return(NULL)
  stat_val <- tryCatch(as.numeric(ur_obj@teststat[1]), error = function(e) NA)
  cval_5   <- tryCatch(as.numeric(ur_obj@cval[1, "5pct"]), error = function(e) NA)
  
  if (is.na(cval_5)) {
    cval_5 <- tryCatch(as.numeric(ur_obj@cval[1, "5pct"]), error = function(e) NA)
    if (is.na(cval_5)) cval_5 <- tryCatch(as.numeric(ur_obj@cval[1]), error = function(e) NA)
  }
  
  dec <- "Uncertain"
  if (!is.na(stat_val) && !is.na(cval_5)) {
    if (grepl("KPSS", test_name)) {
      dec <- if (stat_val > cval_5) "Reject H0 (Non-Stationary)" else "Fail to Reject (Stationary)"
    } else {
      dec <- if (stat_val < cval_5) "Reject H0 (Stationary)" else "Fail to Reject (Unit Root)"
    }
  }
  return(data.frame(Test = test_name, Control = control_type, Stat = round(stat_val, 3), CV_5pct = round(cval_5, 3), Decision = dec, stringsAsFactors = FALSE))
}

run_window_urca_battery <- function(df, start_yr, end_yr, country, window_label) {
  nr_col <- if ("k_NRC" %in% colnames(df)) "k_NRC" else "k_NR"
  sub_df <- df[df$year >= start_yr & df$year <= end_yr, ]
  sub_df <- sub_df[!is.na(sub_df$k_ME) & !is.na(sub_df[[nr_col]]), ]
  n <- nrow(sub_df)
  if (n < 10) return(NULL)

  # Composing assets only
  vars <- c("k_ME", nr_col)
  
  for (v in vars) {
    # Evaluate both LEVEL and FIRST-DIFFERENCE
    level_vec <- sub_df[[v]]
    diff_vec  <- diff(level_vec)
    
    series_list <- list(Level = level_vec, First_Diff = diff_vec)
    
    for (ld_name in names(series_list)) {
      vec <- series_list[[ld_name]]
      
      # 1. ADF
      for (ctrl in c("none", "drift", "trend")) {
        ur_obj <- tryCatch(urca::ur.df(vec, type = ctrl, selectlags = "AIC"), error = function(e) NULL)
        res <- extract_urca_stats(ur_obj, "ADF (ur.df)", ctrl)
        if (!is.null(res)) {
          unit_root_results[[length(unit_root_results) + 1]] <<- data.frame(
            Country = country, Window = window_label, Variable = v, Level_Diff = ld_name, res, stringsAsFactors = FALSE
          )
        }
      }
      
      # 2. KPSS
      for (ctrl in c("mu", "tau")) {
        ur_obj <- tryCatch(urca::ur.kpss(vec, type = ctrl), error = function(e) NULL)
        res <- extract_urca_stats(ur_obj, "KPSS (ur.kpss)", ctrl)
        if (!is.null(res)) {
          unit_root_results[[length(unit_root_results) + 1]] <<- data.frame(
            Country = country, Window = window_label, Variable = v, Level_Diff = ld_name, res, stringsAsFactors = FALSE
          )
        }
      }
      
      # 3. Zivot-Andrews (Level only)
      if (ld_name == "Level") {
        for (ctrl in c("intercept", "trend", "both")) {
          ur_obj <- tryCatch(urca::ur.za(vec, model = ctrl), error = function(e) NULL)
          if (!is.null(ur_obj)) {
            stat_val <- tryCatch(as.numeric(ur_obj@teststat), error = function(e) NA)
            cval_5   <- tryCatch(as.numeric(ur_obj@cval["5%"]), error = function(e) NA)
            b_idx    <- tryCatch(ur_obj@bpoint, error = function(e) NA)
            b_yr     <- if (!is.na(b_idx) && b_idx <= nrow(sub_df)) sub_df$year[b_idx] else NA
            if (!is.na(stat_val) && !is.na(cval_5)) {
              dec <- if (isTRUE(stat_val < cval_5)) "Reject H0 (Break Stationary)" else "Fail to Reject (Unit Root with Break)"
              unit_root_results[[length(unit_root_results) + 1]] <<- data.frame(
                Country = country, Window = window_label, Variable = v, Level_Diff = "Level",
                Test = paste0("Zivot-Andrews Break=", b_yr), Control = ctrl, Stat = round(stat_val, 3), CV_5pct = round(cval_5, 3), Decision = dec, stringsAsFactors = FALSE
              )
            }
          }
        }
      }
    }
  }
}

# 1. US Extended Windows (Exact Boundaries)
if (file.exists(us_file)) {
  us_df <- read.csv(us_file)
  us_windows <- list(
    list(1925, 1946, "Interwar & WWII Era (1925-1946)"),
    list(1947, 1973, "Fordist Expansion (1947-1973)"),
    list(1974, 2008, "Neoliberal Restructuring (1974-2008)"),
    list(2009, 2021, "Post-GFC Stagnation (2009-2021)"),
    list(1925, 2021, "Full Long-Fordism Century (1925-2021)")
  )
  for (w in us_windows) {
    run_window_urca_battery(us_df, w[[1]], w[[2]], "US", w[[3]])
  }
}

# 2. Chile Windows (Exact Boundaries)
if (file.exists(cl_file)) {
  cl_df <- read.csv(cl_file)
  cl_windows <- list(
    list(1920, 1938, "Nitrate Crisis & Early State (1920-1938)"),
    list(1939, 1973, "Classic ISI Era (1939-1973)"),
    list(1974, 1989, "Dictatorship Shock (1974-1989)"),
    list(1990, 2024, "Democratic Neoliberal (1990-2024)"),
    list(1920, 2024, "Full Chile Century (1920-2024)")
  )
  for (w in cl_windows) {
    run_window_urca_battery(cl_df, w[[1]], w[[2]], "Chile", w[[3]])
  }
}

ur_df_final <- do.call(rbind, unit_root_results)
write.csv(ur_df_final, file.path(out_dir, "comprehensive_urca_unit_root_matrix.csv"), row.names = FALSE)

cat("Comprehensive urca battery with levels and I(1) first-differences executed successfully.\n")
