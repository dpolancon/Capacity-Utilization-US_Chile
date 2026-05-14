# ============================================================
# STAGE 1 ECT AUDIT BLOCK — PATCHED SAFE VERSION
# paste after: stage1_master <- load_stage1_master()
# ============================================================

audit_stage1_ect <- function(stage1_master,
                             sample_target = "PRE1974",
                             spec_target = "S1_B",
                             lag_target = 1,
                             rank_target = 1,
                             tol = 1e-8) {
  
  cat("\n====================================================\n")
  cat("STAGE 1 ECT AUDIT\n")
  cat("====================================================\n")
  
  # -------------------------
  # 0. Guardrails
  # -------------------------
  if (is.null(stage1_master)) {
    stop("stage1_master is NULL.", call. = FALSE)
  }
  
  required_top <- c("preferred", "ect_series", "ect_summary", "beta")
  missing_top <- required_top[!required_top %in% names(stage1_master)]
  if (length(missing_top) > 0) {
    stop("stage1_master is missing: ", paste(missing_top, collapse = ", "), call. = FALSE)
  }
  
  if (is.null(stage1_master$preferred$meta)) {
    stop("stage1_master$preferred$meta is missing.", call. = FALSE)
  }
  
  if (is.null(stage1_master$preferred$ect_series)) {
    stop("stage1_master$preferred$ect_series is missing.", call. = FALSE)
  }
  
  # -------------------------
  # small safe print helper
  # -------------------------
  safe_print_df <- function(x, n = NULL, title = NULL) {
    if (!is.null(title)) cat(title, "\n")
    x_df <- as.data.frame(x)
    if (!is.null(n)) x_df <- utils::head(x_df, n)
    print(x_df, row.names = FALSE)
  }
  
  # -------------------------
  # 1. Check preferred object
  # -------------------------
  cat("\n[1] Preferred object stored in stage1_master$preferred$meta\n")
  print(stage1_master$preferred$meta)
  
  # -------------------------
  # 2. Check what is available in master tables
  # -------------------------
  cat("\n[2] Available ECT combinations in master results\n")
  available_ect <- stage1_master$ect_summary %>%
    dplyr::distinct(sample, spec, lag, rank) %>%
    dplyr::arrange(sample, spec, lag, rank)
  
  safe_print_df(available_ect)
  
  # -------------------------
  # 3. Pull the target ECT series from general master
  # -------------------------
  ect_general <- stage1_master$ect_series %>%
    dplyr::filter(
      sample == sample_target,
      spec   == spec_target,
      lag    == lag_target,
      rank   == rank_target
    ) %>%
    dplyr::arrange(year)
  
  cat("\n[3] Rows grabbed from stage1_master$ect_series\n")
  cat("nrow =", nrow(ect_general), "\n")
  safe_print_df(ect_general, n = 10)
  
  if (nrow(ect_general) == 0) {
    stop("No ECT rows found in stage1_master$ect_series for requested target.", call. = FALSE)
  }
  
  # -------------------------
  # 4. Pull from preferred shortcut and compare
  # -------------------------
  ect_preferred <- stage1_master$preferred$ect_series %>%
    dplyr::filter(sample == sample_target) %>%
    dplyr::arrange(year)
  
  cat("\n[4] Rows grabbed from stage1_master$preferred$ect_series\n")
  cat("nrow =", nrow(ect_preferred), "\n")
  safe_print_df(ect_preferred, n = 10)
  
  if (nrow(ect_preferred) == 0) {
    stop("No ECT rows found in stage1_master$preferred$ect_series for requested sample.", call. = FALSE)
  }
  
  compare_tbl <- ect_general %>%
    dplyr::select(year, ECT_general = ECT) %>%
    dplyr::left_join(
      ect_preferred %>% dplyr::select(year, ECT_preferred = ECT),
      by = "year"
    ) %>%
    dplyr::mutate(diff = ECT_general - ECT_preferred)
  
  cat("\n[5] Compare general pull vs preferred shortcut\n")
  print(summary(compare_tbl$diff))
  
  same_series <- all(is.finite(compare_tbl$diff)) &&
    max(abs(compare_tbl$diff), na.rm = TRUE) < tol
  
  cat("Same series? ", same_series, "\n")
  
  # -------------------------
  # 5. Recover normalized beta and rebuild implied ECT
  # -------------------------
  cat("\n[6] Rebuild normalized ECT from beta table\n")
  
  beta_tbl <- stage1_master$beta %>%
    dplyr::filter(
      sample == sample_target,
      spec   == spec_target,
      lag    == lag_target,
      rank   == rank_target
    ) %>%
    dplyr::select(variable, r1)
  
  safe_print_df(beta_tbl)
  
  needed_vars <- c("log_M", "log_KME", "log_NRS_proxy")
  if (!all(needed_vars %in% beta_tbl$variable)) {
    stop("Beta table does not contain expected S1_B variables.", call. = FALSE)
  }
  
  b_logM  <- beta_tbl$r1[beta_tbl$variable == "log_M"][1]
  b_logK  <- beta_tbl$r1[beta_tbl$variable == "log_KME"][1]
  b_logNR <- beta_tbl$r1[beta_tbl$variable == "log_NRS_proxy"][1]
  
  cat("\nRaw beta coefficients:\n")
  cat("b_logM  =", b_logM, "\n")
  cat("b_logK  =", b_logK, "\n")
  cat("b_logNR =", b_logNR, "\n")
  
  if (!is.finite(b_logM) || abs(b_logM) < tol) {
    stop("Coefficient on log_M is missing or too close to zero; cannot normalize.", call. = FALSE)
  }
  
  # normalize on log_M = +1
  z1 <- b_logK / b_logM
  z2 <- b_logNR / b_logM
  
  cat("\nNormalized relation implied by beta/log_M:\n")
  cat("ECT_norm = log_M + (", z1, ")*log_KME + (", z2, ")*log_NRS_proxy\n", sep = "")
  cat("Interpretation check: if theory says ECT = log_M - fitted_requirements,\n")
  cat("then the normalized coefficients on log_KME and log_NRS_proxy should enter with the expected sign.\n")
  
  # -------------------------
  # 6. Join original panel values and reconstruct ECT
  # -------------------------
  panel_path <- here::here("data", "processed", "Chile", "ch2_panel_chile.csv")
  
  if (!file.exists(panel_path)) {
    stop("Processed Chile panel not found at: ", panel_path, call. = FALSE)
  }
  
  raw_panel <- readr::read_csv(panel_path, show_col_types = FALSE) %>%
    dplyr::arrange(year) %>%
    dplyr::mutate(
      log_M = dplyr::if_else(M_CIF > 0, log(M_CIF), NA_real_),
      log_KME = dplyr::if_else(K_ME > 0, log(K_ME), NA_real_),
      NRS_proxy = (pi * GDP_real) - I_total,
      log_NRS_proxy = dplyr::if_else(NRS_proxy > 0, log(NRS_proxy), NA_real_)
    )
  
  if (sample_target == "PRE1974") {
    raw_panel <- raw_panel %>% dplyr::filter(year <= 1973)
  } else if (sample_target == "POST1974") {
    raw_panel <- raw_panel %>% dplyr::filter(year >= 1974)
  } else if (sample_target == "FULL") {
    raw_panel <- raw_panel
  } else {
    stop("sample_target must be one of: FULL, PRE1974, POST1974", call. = FALSE)
  }
  
  raw_panel <- raw_panel %>%
    dplyr::filter(
      is.finite(log_M),
      is.finite(log_KME),
      is.finite(log_NRS_proxy)
    )
  
  audit_df <- ect_general %>%
    dplyr::select(year, ECT_saved = ECT) %>%
    dplyr::left_join(
      raw_panel %>%
        dplyr::select(year, log_M, log_KME, log_NRS_proxy),
      by = "year"
    ) %>%
    dplyr::mutate(
      ECT_rebuilt = log_M + z1 * log_KME + z2 * log_NRS_proxy
    )
  
  corr_same <- stats::cor(audit_df$ECT_saved,  audit_df$ECT_rebuilt, use = "complete.obs")
  corr_flip <- stats::cor(audit_df$ECT_saved, -audit_df$ECT_rebuilt, use = "complete.obs")
  
  cat("\n[7] Saved vs rebuilt ECT correlation check\n")
  cat("corr(ECT_saved,  ECT_rebuilt ) =", corr_same, "\n")
  cat("corr(ECT_saved, -ECT_rebuilt ) =", corr_flip, "\n")
  
  orientation <- dplyr::case_when(
    is.finite(corr_same) && abs(corr_same) > 0.999 ~ "saved ECT matches rebuilt orientation",
    is.finite(corr_flip) && abs(corr_flip) > 0.999 ~ "saved ECT is flipped relative to rebuilt orientation",
    TRUE ~ "orientation unclear; inspect manually"
  )
  
  cat("Orientation diagnosis: ", orientation, "\n")
  
  cat("\n[8] First 15 audited rows\n")
  safe_print_df(
    audit_df %>%
      dplyr::select(year, ECT_saved, ECT_rebuilt, log_M, log_KME, log_NRS_proxy),
    n = 15
  )
  
  invisible(list(
    ect_general = ect_general,
    ect_preferred = ect_preferred,
    compare_tbl = compare_tbl,
    beta_tbl = beta_tbl,
    audit_df = audit_df,
    corr_same = corr_same,
    corr_flip = corr_flip,
    orientation = orientation
  ))
}

# -------------------------
# run the audit
# -------------------------
audit_pre  <- audit_stage1_ect(stage1_master, sample_target = "PRE1974")
audit_full <- audit_stage1_ect(stage1_master, sample_target = "FULL")
audit_post <- audit_stage1_ect(stage1_master, sample_target = "POST1974")