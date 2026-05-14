# =========================
# Chile Stage 1 -- consolidated single-file bundle
# External disequilibrium VECM exploration only
# Includes strict ISI window: 1931-1973
# (designed so the active lagged estimation window begins in 1932)
# =========================

required_packages <- c(
  "here", "readr", "dplyr", "tidyr", "ggplot2", "urca", "tsDyn",
  "lmtest", "tseries", "broom"
)

stage1_check_packages <- function(pkgs = required_packages) {
  miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(miss) > 0) {
    stop("Missing packages: ", paste(miss, collapse = ", "), call. = FALSE)
  }
}

# -------------------------
# Paths
# -------------------------

stage1_data_path <- function() {
  rds_path <- here::here("output", "source_of_truth_chile", "rds", "source_of_truth_chile.rds")
  csv_path <- here::here("output", "source_of_truth_chile", "csv", "source_of_truth_chile.csv")
  if (file.exists(rds_path)) return(rds_path)
  csv_path
}

stage1_paths <- function() {
  root <- here::here("output", "chile_2Smu_S1")
  paths <- list(
    root = root,
    tex  = file.path(root, "tex"),
    figs = file.path(root, "figs"),
    csv  = file.path(root, "csv"),
    txt  = file.path(root, "txt")
  )
  invisible(lapply(paths, dir.create, recursive = TRUE, showWarnings = FALSE))
  paths
}

# -------------------------
# Small IO helpers
# -------------------------

stage1_write_txt <- function(lines, path) {
  writeLines(as.character(lines), con = path, useBytes = TRUE)
}

stage1_write_manifest <- function(paths, meta) {
  lines <- c(
    "Stage 1 manifest",
    paste0("data_path: ", meta$data_path),
    paste0("samples: ", paste(meta$samples, collapse = ", ")),
    paste0("specs: ", paste(meta$specs, collapse = ", ")),
    paste0("vecm_lags: ", paste(meta$vecm_lags, collapse = ", ")),
    paste0("vecm_ranks: ", paste(meta$vecm_ranks, collapse = ", "))
  )
  stage1_write_txt(lines, file.path(paths$txt, "stage1__manifest.txt"))
}

stage1_write_review_note <- function(paths) {
  lines <- c(
    "Stage 1 review note",
    "This session is confined to Stage 1 only.",
    "Review rank behavior, variable inclusion, and the ECT.",
    "ECT is an external disequilibrium object, not utilization.",
    "Compare FULL, PRE1974, ISI1931_1973, and POST1974.",
    "ISI1931_1973 includes 1931 strategically so the active lagged estimation window begins in 1932.",
    "Focus on ECT amplitude, variance, and speed of adjustment."
  )
  stage1_write_txt(lines, file.path(paths$txt, "stage1__review_notes.txt"))
}

# -------------------------
# Simple LaTeX export
# -------------------------

stage1_escape_tex <- function(x) {
  x <- as.character(x)
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([_%#$&{}])", "\\\\\\1", x, perl = TRUE)
  x
}

stage1_df_to_tex <- function(df, file) {
  if (ncol(df) == 0) {
    writeLines("\\begin{tabular}{l}\nempty\\\\\n\\end{tabular}", con = file)
    return(invisible(NULL))
  }
  
  df2 <- df
  for (j in seq_along(df2)) {
    if (is.numeric(df2[[j]])) {
      df2[[j]] <- ifelse(is.na(df2[[j]]), "", format(round(df2[[j]], 6), trim = TRUE, scientific = FALSE))
    } else {
      df2[[j]] <- ifelse(is.na(df2[[j]]), "", as.character(df2[[j]]))
    }
  }
  
  cols <- ncol(df2)
  align <- paste(rep("l", cols), collapse = "")
  header <- paste(stage1_escape_tex(names(df2)), collapse = " & ")
  body <- apply(df2, 1, function(row) paste(stage1_escape_tex(row), collapse = " & "))
  
  lines <- c(
    paste0("\\begin{tabular}{", align, "}"),
    "\\hline",
    paste0(header, " \\\\"),
    "\\hline",
    paste0(body, " \\\\"),
    "\\hline",
    "\\end{tabular}"
  )
  
  writeLines(lines, con = file, useBytes = TRUE)
  invisible(NULL)
}

stage1_export_table <- function(df, stem, paths) {
  readr::write_csv(df, file.path(paths$csv, paste0(stem, ".csv")))
  stage1_df_to_tex(df, file.path(paths$tex, paste0(stem, ".tex")))
}

stage1_export_plot <- function(p, stem, paths, width = 8, height = 5) {
  ggplot2::ggsave(
    filename = file.path(paths$figs, paste0(stem, ".png")),
    plot = p, width = width, height = height, dpi = 300
  )
  ggplot2::ggsave(
    filename = file.path(paths$figs, paste0(stem, ".pdf")),
    plot = p, width = width, height = height
  )
}

# -------------------------
# Data
# -------------------------

stage1_read_panel <- function(path = stage1_data_path()) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") return(readRDS(path))
  readr::read_csv(path, show_col_types = FALSE)
}

stage1_prepare_data <- function(df) {
  get_col <- function(data, candidates, default = NA_real_) {
    hit <- intersect(candidates, names(data))
    if (length(hit) == 0) return(rep(default, nrow(data)))
    x <- data[[hit[1]]]
    if (length(x) == 0) return(rep(default, nrow(data)))
    x
  }

  K_ME_stage1     <- get_col(df, c("Kg_ME", "K_ME"))
  M_CIF_stage1    <- get_col(df, c("M_CIF", "M_CIF_canonical"))
  GDP_real_stage1 <- get_col(df, c("GDP_real", "GDP_real_canonical"))
  I_total_stage1  <- get_col(df, c("I_total", "I_total_canonical"))
  pi_stage1       <- get_col(df, c("pi", "pi_canonical"))
  omega_stage1    <- get_col(df, c("omega", "omega_canonical"))

  out <- df |>
    dplyr::arrange(year) |>
    dplyr::mutate(
      K_ME_stage1 = K_ME_stage1,
      M_CIF_stage1 = M_CIF_stage1,
      GDP_real_stage1 = GDP_real_stage1,
      I_total_stage1 = I_total_stage1,
      pi_stage1 = pi_stage1,
      omega_stage1 = omega_stage1,
      log_M = dplyr::if_else(M_CIF_stage1 > 0, log(M_CIF_stage1), NA_real_),
      log_KME = dplyr::if_else(K_ME_stage1 > 0, log(K_ME_stage1), NA_real_),
      NRS_proxy = (pi_stage1 * GDP_real_stage1) - I_total_stage1,
      log_NRS_proxy = dplyr::if_else(NRS_proxy > 0, log(NRS_proxy), NA_real_),
      omega = omega_stage1
    )

  required_stage1 <- c("K_ME_stage1", "M_CIF_stage1", "GDP_real_stage1", "I_total_stage1", "pi_stage1", "omega_stage1")
  missing_stage1 <- required_stage1[vapply(required_stage1, function(v) all(is.na(out[[v]])), logical(1))]
  if (length(missing_stage1) > 0) {
    stop("Stage 1 missing canonical inputs: ", paste(missing_stage1, collapse = ", "), call. = FALSE)
  }

  out
}

# -------------------------
# Spec + sample registry
# -------------------------

stage1_spec_registry <- function() {
  list(
    S1_A = list(lhs = "log_M", rhs = c("log_KME")),
    S1_B = list(lhs = "log_M", rhs = c("log_KME", "log_NRS_proxy")),
    S1_C = list(lhs = "log_M", rhs = c("log_KME", "omega")),
    S1_D = list(lhs = "log_M", rhs = c("log_KME", "log_NRS_proxy", "omega"))
  )
}

stage1_sample_registry <- function() {
  list(
    FULL = function(df) df,
    PRE1974 = function(df) dplyr::filter(df, year <= 1973),
    ISI1931_1973 = function(df) dplyr::filter(df, year >= 1931, year <= 1973),
    POST1974 = function(df) dplyr::filter(df, year >= 1974)
  )
}

stage1_complete_cases_for_spec <- function(df, spec) {
  vars <- c("year", spec$lhs, spec$rhs)
  df[stats::complete.cases(df[, vars, drop = FALSE]), vars, drop = FALSE]
}

# -------------------------
# Unit-root battery
# -------------------------

stage1_safe_stat <- function(obj, slot_name = "teststat") {
  out <- tryCatch(slot(obj, slot_name), error = function(e) NA)
  if (length(out) == 0) out <- NA
  out
}

stage1_safe_cval <- function(obj) {
  tryCatch(slot(obj, "cval"), error = function(e) NA)
}

stage1_run_adf <- function(x, type = "drift", lags = 2) {
  fit <- urca::ur.df(x, type = type, lags = lags, selectlags = "Fixed")
  list(
    test = "ADF",
    det = as.character(type),
    lags = as.character(lags),
    stat = paste(stage1_safe_stat(fit), collapse = "; "),
    cval = paste(capture.output(print(stage1_safe_cval(fit))), collapse = " ")
  )
}

stage1_run_pp <- function(x, model = "constant", lags = "short") {
  fit <- urca::ur.pp(x, type = "Z-tau", model = model, lags = lags)
  list(
    test = "PP",
    det = as.character(model),
    lags = as.character(lags),
    stat = paste(stage1_safe_stat(fit), collapse = "; "),
    cval = paste(capture.output(print(stage1_safe_cval(fit))), collapse = " ")
  )
}

stage1_run_kpss <- function(x, type = "mu", lags = "short") {
  fit <- urca::ur.kpss(x, type = type, lags = lags)
  list(
    test = "KPSS",
    det = as.character(type),
    lags = as.character(lags),
    stat = paste(stage1_safe_stat(fit), collapse = "; "),
    cval = paste(capture.output(print(stage1_safe_cval(fit))), collapse = " ")
  )
}

stage1_unitroot_battery <- function(df, vars, sample_name) {
  out <- list()
  
  for (v in vars) {
    x <- df[[v]]
    x <- x[is.finite(x)]
    
    if (length(x) < 20) next
    
    out[[paste(v, "ADF_level", sep = "__")]] <-
      dplyr::tibble(variable = v, sample = sample_name, difference = "level", !!!stage1_run_adf(x, type = "drift", lags = 2))
    
    out[[paste(v, "PP_level", sep = "__")]] <-
      dplyr::tibble(variable = v, sample = sample_name, difference = "level", !!!stage1_run_pp(x, model = "constant", lags = "short"))
    
    out[[paste(v, "KPSS_level", sep = "__")]] <-
      dplyr::tibble(variable = v, sample = sample_name, difference = "level", !!!stage1_run_kpss(x, type = "mu", lags = "short"))
    
    dx <- diff(x)
    if (length(dx) >= 20) {
      out[[paste(v, "ADF_diff", sep = "__")]] <-
        dplyr::tibble(variable = v, sample = sample_name, difference = "diff", !!!stage1_run_adf(dx, type = "drift", lags = 2))
      
      out[[paste(v, "PP_diff", sep = "__")]] <-
        dplyr::tibble(variable = v, sample = sample_name, difference = "diff", !!!stage1_run_pp(dx, model = "constant", lags = "short"))
      
      out[[paste(v, "KPSS_diff", sep = "__")]] <-
        dplyr::tibble(variable = v, sample = sample_name, difference = "diff", !!!stage1_run_kpss(dx, type = "mu", lags = "short"))
    }
  }
  
  if (length(out) == 0) {
    return(dplyr::tibble(
      variable = character(),
      sample = character(),
      difference = character(),
      test = character(),
      det = character(),
      lags = character(),
      stat = character(),
      cval = character()
    ))
  }
  
  dplyr::bind_rows(out)
}

# -------------------------
# Static diagnostics
# -------------------------

stage1_vif_table <- function(df, rhs, sample_name, spec_name) {
  if (length(rhs) <= 1) {
    return(dplyr::tibble(sample = sample_name, spec = spec_name, variable = rhs, vif = NA_real_))
  }
  
  out <- lapply(rhs, function(v) {
    others <- setdiff(rhs, v)
    form <- stats::as.formula(paste(v, "~", paste(others, collapse = " + ")))
    fit <- stats::lm(form, data = df)
    r2 <- summary(fit)$r.squared
    vif <- 1 / (1 - r2)
    dplyr::tibble(sample = sample_name, spec = spec_name, variable = v, vif = vif)
  })
  
  dplyr::bind_rows(out)
}

stage1_white_test <- function(fit, sample_name, spec_name) {
  bt <- tryCatch(lmtest::bptest(fit, ~ stats::fitted(fit) + I(stats::fitted(fit)^2)), error = function(e) NULL)
  if (is.null(bt)) {
    return(dplyr::tibble(sample = sample_name, spec = spec_name, statistic = NA_real_, p_value = NA_real_))
  }
  dplyr::tibble(sample = sample_name, spec = spec_name, statistic = unname(bt$statistic), p_value = bt$p.value)
}

stage1_lm_test <- function(fit, sample_name, spec_name, order = 1) {
  lt <- tryCatch(lmtest::bgtest(fit, order = order), error = function(e) NULL)
  if (is.null(lt)) {
    return(dplyr::tibble(sample = sample_name, spec = spec_name, order = order, statistic = NA_real_, p_value = NA_real_))
  }
  dplyr::tibble(sample = sample_name, spec = spec_name, order = order, statistic = unname(lt$statistic), p_value = lt$p.value)
}

stage1_jb_test <- function(fit, sample_name, spec_name) {
  jt <- tryCatch(tseries::jarque.bera.test(stats::residuals(fit)), error = function(e) NULL)
  if (is.null(jt)) {
    return(dplyr::tibble(sample = sample_name, spec = spec_name, statistic = NA_real_, p_value = NA_real_))
  }
  dplyr::tibble(sample = sample_name, spec = spec_name, statistic = unname(jt$statistic), p_value = jt$p.value)
}

stage1_static_diagnostics <- function(df_spec, spec, sample_name, spec_name) {
  form <- stats::as.formula(paste(spec$lhs, "~", paste(spec$rhs, collapse = " + ")))
  fit <- stats::lm(form, data = df_spec)
  
  list(
    vif = stage1_vif_table(df_spec, spec$rhs, sample_name, spec_name),
    white = stage1_white_test(fit, sample_name, spec_name),
    lm = stage1_lm_test(fit, sample_name, spec_name, order = 1),
    jb = stage1_jb_test(fit, sample_name, spec_name)
  )
}

# -------------------------
# Johansen rank
# -------------------------

stage1_johansen_rank <- function(df_spec, vars, sample_name, spec_name, ecdet = "const", K = 2, type = "trace") {
  mat <- as.matrix(df_spec[, vars, drop = FALSE])
  fit <- urca::ca.jo(mat, type = type, ecdet = ecdet, K = K, spec = "transitory")
  
  stats_vec <- fit@teststat
  cvals <- fit@cval
  
  out <- dplyr::tibble(
    sample = sample_name,
    spec = spec_name,
    test = type,
    ecdet = ecdet,
    K = K,
    rank_index = seq_along(stats_vec),
    statistic = as.numeric(stats_vec),
    cv_10pct = as.numeric(cvals[, 1]),
    cv_5pct  = as.numeric(cvals[, 2]),
    cv_1pct  = as.numeric(cvals[, 3])
  )
  
  list(model = fit, table = out)
}

# -------------------------
# VECM
# -------------------------

stage1_fit_vecm <- function(df_spec, vars, lag = 1, r = 1, include = "const", estim = "ML") {
  mat <- as.matrix(df_spec[, vars, drop = FALSE])
  tsDyn::VECM(data = mat, lag = lag, r = r, include = include, estim = estim)
}

stage1_extract_vecm_objects <- function(fit, df_spec, vars, sample_name, spec_name, lag, r) {
  beta <- tsDyn::coefB(fit)
  alpha <- tsDyn::coefA(fit)
  
  beta_df <- as.data.frame(beta)
  beta_df$variable <- rownames(beta)
  beta_df$sample <- sample_name
  beta_df$spec <- spec_name
  beta_df$lag <- lag
  beta_df$rank <- r
  rownames(beta_df) <- NULL
  
  alpha_df <- as.data.frame(alpha)
  alpha_df$equation <- rownames(alpha)
  alpha_df$sample <- sample_name
  alpha_df$spec <- spec_name
  alpha_df$lag <- lag
  alpha_df$rank <- r
  rownames(alpha_df) <- NULL
  
  b <- as.numeric(beta[, 1])
  X <- as.matrix(df_spec[, vars, drop = FALSE])
  ect <- as.numeric(X %*% b)
  
  ect_df <- dplyr::tibble(
    year = df_spec$year,
    ECT = ect,
    sample = sample_name,
    spec = spec_name,
    lag = lag,
    rank = r
  )
  
  alpha_first <- NA_real_
  if (nrow(alpha) >= 1 && ncol(alpha) >= 1) alpha_first <- alpha[1, 1]
  
  ect_summary <- dplyr::tibble(
    sample = sample_name,
    spec = spec_name,
    lag = lag,
    rank = r,
    ect_min = min(ect, na.rm = TRUE),
    ect_max = max(ect, na.rm = TRUE),
    ect_range = max(ect, na.rm = TRUE) - min(ect, na.rm = TRUE),
    ect_mean = mean(ect, na.rm = TRUE),
    ect_sd = stats::sd(ect, na.rm = TRUE),
    ect_var = stats::var(ect, na.rm = TRUE),
    alpha_first_eq = alpha_first
  )
  
  list(
    alpha = alpha_df,
    beta = beta_df,
    ect = ect_df,
    ect_summary = ect_summary
  )
}

# -------------------------
# Plots
# -------------------------

stage1_plot_ect <- function(df) {
  ggplot2::ggplot(df, ggplot2::aes(x = year, y = ECT)) +
    ggplot2::geom_line() +
    ggplot2::labs(x = "year", y = "ECT") +
    ggplot2::theme_minimal()
}

stage1_plot_ect_compare <- function(df) {
  ggplot2::ggplot(df, ggplot2::aes(x = year, y = ECT, group = interaction(sample, spec))) +
    ggplot2::geom_line() +
    ggplot2::facet_grid(sample ~ spec, scales = "free_y") +
    ggplot2::labs(x = "year", y = "ECT") +
    ggplot2::theme_minimal()
}

# -------------------------
# Main runner
# -------------------------

stage1_run <- function(
    data_path = stage1_data_path(),
    vecm_lags = 1:2,
    vecm_ranks = c(1),
    johansen_K = c(2, 3),
    export_rds = FALSE
) {
  stage1_check_packages()
  paths <- stage1_paths()
  
  df_raw <- stage1_read_panel(data_path)
  df <- stage1_prepare_data(df_raw)
  
  specs <- stage1_spec_registry()
  samples <- stage1_sample_registry()
  
  stage1_write_manifest(paths, list(
    data_path = data_path,
    samples = names(samples),
    specs = names(specs),
    vecm_lags = vecm_lags,
    vecm_ranks = vecm_ranks
  ))
  
  all_unitroot <- list()
  all_vif <- list()
  all_white <- list()
  all_lm <- list()
  all_jb <- list()
  all_rank <- list()
  all_alpha <- list()
  all_beta <- list()
  all_ect <- list()
  all_ect_summary <- list()
  
  for (sample_name in names(samples)) {
    df_s <- samples[[sample_name]](df)
    
    battery_vars <- c("log_M", "log_KME", "log_NRS_proxy", "omega")
    all_unitroot[[sample_name]] <- stage1_unitroot_battery(df_s, battery_vars, sample_name)
    
    for (spec_name in names(specs)) {
      spec <- specs[[spec_name]]
      df_spec <- stage1_complete_cases_for_spec(df_s, spec)
      
      if (nrow(df_spec) < 25) next
      
      sdiag <- stage1_static_diagnostics(df_spec, spec, sample_name, spec_name)
      all_vif[[paste(sample_name, spec_name, sep = "__")]] <- sdiag$vif
      all_white[[paste(sample_name, spec_name, sep = "__")]] <- sdiag$white
      all_lm[[paste(sample_name, spec_name, sep = "__")]] <- sdiag$lm
      all_jb[[paste(sample_name, spec_name, sep = "__")]] <- sdiag$jb
      
      vars <- c(spec$lhs, spec$rhs)
      
      for (K in johansen_K) {
        for (tt in c("trace", "eigen")) {
          rtest <- tryCatch(
            stage1_johansen_rank(df_spec, vars, sample_name, spec_name, ecdet = "const", K = K, type = tt),
            error = function(e) NULL
          )
          if (!is.null(rtest)) {
            all_rank[[paste(sample_name, spec_name, K, tt, sep = "__")]] <- rtest$table
          }
        }
      }
      
      for (lag in vecm_lags) {
        for (r in vecm_ranks) {
          if (r >= length(vars)) next
          
          fit <- tryCatch(
            stage1_fit_vecm(df_spec, vars, lag = lag, r = r, include = "const", estim = "ML"),
            error = function(e) NULL
          )
          if (is.null(fit)) next
          
          ext <- stage1_extract_vecm_objects(fit, df_spec, vars, sample_name, spec_name, lag, r)
          
          all_alpha[[paste(sample_name, spec_name, lag, r, sep = "__")]] <- ext$alpha
          all_beta[[paste(sample_name, spec_name, lag, r, sep = "__")]] <- ext$beta
          all_ect[[paste(sample_name, spec_name, lag, r, sep = "__")]] <- ext$ect
          all_ect_summary[[paste(sample_name, spec_name, lag, r, sep = "__")]] <- ext$ect_summary
          
          if (isTRUE(export_rds)) {
            saveRDS(
              fit,
              file = file.path(paths$txt, paste0("stage1__vecm__", sample_name, "__", spec_name, "__lag", lag, "__r", r, ".rds"))
            )
          }
        }
      }
    }
  }
  
  unitroot_tbl <- dplyr::bind_rows(all_unitroot)
  vif_tbl <- dplyr::bind_rows(all_vif)
  white_tbl <- dplyr::bind_rows(all_white)
  lm_tbl <- dplyr::bind_rows(all_lm)
  jb_tbl <- dplyr::bind_rows(all_jb)
  rank_tbl <- dplyr::bind_rows(all_rank)
  alpha_tbl <- dplyr::bind_rows(all_alpha)
  beta_tbl <- dplyr::bind_rows(all_beta)
  ect_tbl <- dplyr::bind_rows(all_ect)
  ect_sum_tbl <- dplyr::bind_rows(all_ect_summary)
  
  out <- list(
    unitroot = unitroot_tbl,
    vif = vif_tbl,
    white = white_tbl,
    lm = lm_tbl,
    jb = jb_tbl,
    rank = rank_tbl,
    alpha = alpha_tbl,
    beta = beta_tbl,
    ect = ect_tbl,
    ect_summary = ect_sum_tbl,
    paths = paths,
    meta = list(
      data_path = data_path,
      samples = names(samples),
      specs = names(specs),
      vecm_lags = vecm_lags,
      vecm_ranks = vecm_ranks,
      johansen_K = johansen_K,
      created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
    )
  )
  saveRDS(out, file = file.path(paths$txt, "stage1__run_output.rds"))
  
  stage1_export_table(unitroot_tbl, "stage1__unitroot_battery", paths)
  stage1_export_table(vif_tbl, "stage1__vif", paths)
  stage1_export_table(white_tbl, "stage1__white", paths)
  stage1_export_table(lm_tbl, "stage1__lm", paths)
  stage1_export_table(jb_tbl, "stage1__jb", paths)
  stage1_export_table(rank_tbl, "stage1__rank", paths)
  stage1_export_table(alpha_tbl, "stage1__alpha", paths)
  stage1_export_table(beta_tbl, "stage1__beta", paths)
  stage1_export_table(ect_sum_tbl, "stage1__ect_summary", paths)
  
  readr::write_csv(ect_tbl, file.path(paths$csv, "stage1__ect_series.csv"))
  
  if (nrow(ect_tbl) > 0) {
    keys <- unique(ect_tbl[, c("sample", "spec")])
    
    for (i in seq_len(nrow(keys))) {
      sample_i <- keys$sample[i]
      spec_i <- keys$spec[i]
      
      sub <- ect_tbl |>
        dplyr::filter(sample == sample_i, spec == spec_i)
      
      if (nrow(sub) == 0) next
      
      sub <- sub |>
        dplyr::arrange(lag, rank, year)
      
      chosen_lag <- min(sub$lag, na.rm = TRUE)
      chosen_rank <- min(sub$rank, na.rm = TRUE)
      
      sub_plot <- sub |>
        dplyr::filter(lag == chosen_lag, rank == chosen_rank)
      
      if (nrow(sub_plot) == 0) next
      
      p <- stage1_plot_ect(sub_plot)
      stem <- paste0("stage1__ect__", sample_i, "__", spec_i, "__lag", chosen_lag, "__r", chosen_rank)
      stage1_export_plot(p, stem, paths)
    }
    
    ect_compare <- dplyr::bind_rows(lapply(split(ect_tbl, list(ect_tbl$sample, ect_tbl$spec), drop = TRUE), function(sub) {
      sub <- sub |>
        dplyr::arrange(lag, rank, year)
      
      chosen_lag <- min(sub$lag, na.rm = TRUE)
      chosen_rank <- min(sub$rank, na.rm = TRUE)
      
      sub |>
        dplyr::filter(lag == chosen_lag, rank == chosen_rank)
    }))
    
    if (nrow(ect_compare) > 0) {
      pcmp <- stage1_plot_ect_compare(ect_compare)
      stage1_export_plot(pcmp, "stage1__ect_compare", paths, width = 10, height = 8)
    }
  }
  
  stage1_write_review_note(paths)
  
  summary_lines <- c(
    "Stage 1 run completed.",
    paste0("Unit-root rows: ", nrow(unitroot_tbl)),
    paste0("Rank rows: ", nrow(rank_tbl)),
    paste0("ECT rows: ", nrow(ect_tbl)),
    "Review exports in output/chile_2Smu_S1/ and stop before any Stage 2 work."
  )
  
  stage1_write_txt(summary_lines, file.path(paths$txt, "stage1__session_summary.txt"))
  cat(paste(summary_lines, collapse = "\n"), "\n")
  
  invisible(list(
    unitroot = unitroot_tbl,
    vif = vif_tbl,
    white = white_tbl,
    lm = lm_tbl,
    jb = jb_tbl,
    rank = rank_tbl,
    alpha = alpha_tbl,
    beta = beta_tbl,
    ect = ect_tbl,
    ect_summary = ect_sum_tbl,
    paths = paths
  ))
}

# ============================================================
# Stage 1 execution
# ============================================================

res_stage1 <- stage1_run(
  vecm_lags = 1:2,
  vecm_ranks = 1,
  johansen_K = c(2, 3),
  export_rds = TRUE
)

# ============================================================
# Stage 1 master RDS builder
# ============================================================

root_dir <- here::here("output", "chile_2Smu_S1", "csv")
txt_dir  <- here::here("output", "chile_2Smu_S1", "txt")

dir.create(txt_dir, recursive = TRUE, showWarnings = FALSE)

files <- list(
  alpha = file.path(root_dir, "stage1__alpha.csv"),
  beta = file.path(root_dir, "stage1__beta.csv"),
  ect_series = file.path(root_dir, "stage1__ect_series.csv"),
  ect_summary = file.path(root_dir, "stage1__ect_summary.csv"),
  jb = file.path(root_dir, "stage1__jb.csv"),
  lm = file.path(root_dir, "stage1__lm.csv"),
  rank = file.path(root_dir, "stage1__rank.csv"),
  unitroot_battery = file.path(root_dir, "stage1__unitroot_battery.csv"),
  vif = file.path(root_dir, "stage1__vif.csv"),
  white = file.path(root_dir, "stage1__white.csv")
)

missing <- files[!file.exists(unlist(files))]
if (length(missing) > 0) {
  stop("Missing CSV files: ", paste(names(missing), collapse = ", "))
}

read_one <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

stage1_master <- lapply(files, read_one)

run_output_path <- file.path(txt_dir, "stage1__run_output.rds")
stage1_run_output <- if (file.exists(run_output_path)) readRDS(run_output_path) else NULL

stage1_master$meta <- list(
  project = "Chile Stage 1 external disequilibrium VECM",
  session_scope = "Stage 1 only",
  output_root = "outputs/chile_2Smu_S1/",
  windows = c("FULL", "PRE1974", "ISI1931_1973", "POST1974"),
  specs = c("S1_A", "S1_B", "S1_C", "S1_D"),
  preferred_working_object = list(sample = "PRE1974", spec = "S1_B", lag = 1, rank = 1),
  notes = c(
    "ECT is an external disequilibrium object, not utilization.",
    "S1_B is lhs=log_M, rhs=c(log_KME, log_NRS_proxy).",
    "ISI1931_1973 is included so the active estimation window under lag structure effectively runs from 1932 to 1973.",
    "This master RDS consolidates Stage 1 tabular outputs and optional run-level objects."
  ),
  source_files = files,
  run_output_path = run_output_path,
  created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)

stage1_master$run_output <- stage1_run_output

# ============================================================
# Preferred Stage 1 packaging and comparison packs
# ============================================================

preferred_spec   <- "S1_B"
preferred_lag    <- 1
preferred_rank   <- 1
preferred_sample <- "PRE1974"

stage1_master$s1b_beta <- subset(stage1_master$beta, spec == "S1_B")
stage1_master$s1b_alpha <- subset(stage1_master$alpha, spec == "S1_B")
stage1_master$s1b_ect_summary <- subset(stage1_master$ect_summary, spec == "S1_B")
stage1_master$s1b_ect_series <- subset(stage1_master$ect_series, spec == "S1_B")

preferred_beta <- subset(
  stage1_master$beta,
  sample == preferred_sample & spec == preferred_spec & lag == preferred_lag & rank == preferred_rank
)

preferred_alpha <- subset(
  stage1_master$alpha,
  sample == preferred_sample & spec == preferred_spec & lag == preferred_lag & rank == preferred_rank
)

preferred_ect_summary <- subset(
  stage1_master$ect_summary,
  sample == preferred_sample & spec == preferred_spec & lag == preferred_lag & rank == preferred_rank
)

preferred_ect_series <- subset(
  stage1_master$ect_series,
  sample == preferred_sample & spec == preferred_spec & lag == preferred_lag & rank == preferred_rank
)

compare_beta <- subset(
  stage1_master$beta,
  spec == preferred_spec & lag == preferred_lag & rank == preferred_rank
)
compare_alpha <- subset(
  stage1_master$alpha,
  spec == preferred_spec & lag == preferred_lag & rank == preferred_rank
)
compare_ect_summary <- subset(
  stage1_master$ect_summary,
  spec == preferred_spec & lag == preferred_lag & rank == preferred_rank
)
compare_ect_series <- subset(
  stage1_master$ect_series,
  spec == preferred_spec & lag == preferred_lag & rank == preferred_rank
)

write.csv(compare_beta,
          file.path(root_dir, "stage1__s1b_compare_beta.csv"),
          row.names = FALSE)
write.csv(compare_alpha,
          file.path(root_dir, "stage1__s1b_compare_alpha.csv"),
          row.names = FALSE)
write.csv(compare_ect_summary,
          file.path(root_dir, "stage1__s1b_compare_ect_summary.csv"),
          row.names = FALSE)
write.csv(compare_ect_series,
          file.path(root_dir, "stage1__s1b_compare_ect_series.csv"),
          row.names = FALSE)

preferred_pack <- list(
  meta = list(
    preferred_spec = preferred_spec,
    preferred_sample = preferred_sample,
    preferred_lag = preferred_lag,
    preferred_rank = preferred_rank,
    interpretation = c(
      "ECT is actual log imports minus fitted structural import requirements.",
      "ECT < 0 indicates import compression relative to structural requirements.",
      "Preferred anchor window is PRE1974."
    ),
    created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  beta = preferred_beta,
  alpha = preferred_alpha,
  ect_summary = preferred_ect_summary,
  ect_series = preferred_ect_series
)

saveRDS(preferred_pack, file.path(txt_dir, "stage1__s1b_l1r1_results.rds"))
writeLines(
  c(
    "Preferred Stage 1 spec package",
    paste0("spec: ", preferred_spec),
    paste0("sample anchor: ", preferred_sample),
    paste0("lag: ", preferred_lag),
    paste0("rank: ", preferred_rank)
  ),
  con = file.path(txt_dir, "stage1__s1b_l1r1_manifest.txt")
)

isi_pack <- list(
  meta = list(
    sample = "ISI1931_1973",
    spec = "S1_B",
    lag = 1,
    rank = 1,
    interpretation = c(
      "ECT is actual log imports minus fitted structural import requirements.",
      "ECT < 0 indicates import compression relative to structural requirements.",
      "1931 is included strategically so the effective lagged window begins in 1932."
    ),
    created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  beta = subset(stage1_master$beta, sample == "ISI1931_1973" & spec == "S1_B" & lag == 1 & rank == 1),
  alpha = subset(stage1_master$alpha, sample == "ISI1931_1973" & spec == "S1_B" & lag == 1 & rank == 1),
  ect_summary = subset(stage1_master$ect_summary, sample == "ISI1931_1973" & spec == "S1_B" & lag == 1 & rank == 1),
  ect_series = subset(stage1_master$ect_series, sample == "ISI1931_1973" & spec == "S1_B" & lag == 1 & rank == 1)
)

saveRDS(isi_pack, file.path(txt_dir, "stage1__isi1931_1973_s1b_l1r1_results.rds"))

stage1_master$preferred <- preferred_pack
stage1_master$isi1931_1973 <- isi_pack
saveRDS(stage1_master, file = file.path(txt_dir, "stage1__master_results.rds"))

# ============================================================
# Screen checks and ex-ante / post-estimation cross-checks
# ============================================================

stage1_compare_preferred_on_screen <- function(stage1_master,
                                               spec_target = "S1_B",
                                               lag_target = 1,
                                               rank_target = 1) {
  
  beta_cmp <- stage1_master$beta |>
    dplyr::filter(spec == spec_target, lag == lag_target, rank == rank_target)
  
  alpha_cmp <- stage1_master$alpha |>
    dplyr::filter(spec == spec_target, lag == lag_target, rank == rank_target)
  
  ect_cmp <- stage1_master$ect_summary |>
    dplyr::filter(spec == spec_target, lag == lag_target, rank == rank_target)
  
  alpha_import <- alpha_cmp |>
    dplyr::filter(grepl("log_M", equation, fixed = TRUE)) |>
    dplyr::select(sample, spec, lag, rank, ECT) |>
    dplyr::rename(alpha_log_M = ECT)
  
  beta_wide <- beta_cmp |>
    dplyr::select(sample, spec, lag, rank, variable, r1) |>
    tidyr::pivot_wider(
      id_cols = c(sample, spec, lag, rank),
      names_from = variable,
      values_from = r1
    )
  
  cmp <- beta_wide |>
    dplyr::left_join(alpha_import, by = c("sample", "spec", "lag", "rank")) |>
    dplyr::left_join(
      ect_cmp |>
        dplyr::select(sample, spec, lag, rank, ect_mean, ect_sd, ect_range),
      by = c("sample", "spec", "lag", "rank")
    ) |>
    dplyr::arrange(factor(sample, levels = c("FULL", "PRE1974", "ISI1931_1973", "POST1974")))
  
  cat("\n========================================\n")
  cat("Preferred Stage 1 comparison\n")
  cat("Spec:", spec_target, "| Lag:", lag_target, "| Rank:", rank_target, "\n")
  cat("========================================\n\n")
  print(cmp, row.names = FALSE)
  
  cat("\nInterpretation check:\n")
  cat("- alpha_log_M should be negative.\n")
  cat("- Larger |alpha_log_M| means faster import correction.\n")
  cat("- ect_sd / ect_range show how volatile the disequilibrium object is.\n\n")
  
  invisible(cmp)
}

preferred_cmp <- stage1_compare_preferred_on_screen(
  stage1_master,
  spec_target = "S1_B",
  lag_target = 1,
  rank_target = 1
)

stage1_unitroot_guardrail_screen <- function(stage1_master,
                                             sample_target = "PRE1974",
                                             vars = c("log_M", "log_KME", "log_NRS_proxy")) {
  
  tb <- stage1_master$unitroot_battery |>
    dplyr::filter(sample == sample_target, variable %in% vars) |>
    dplyr::select(variable, difference, test, det, lags, stat)
  
  cat("\n========================================\n")
  cat("Unit-root guardrail screen\n")
  cat("Sample:", sample_target, "\n")
  cat("========================================\n\n")
  print(tb, row.names = FALSE)
  
  cat("\nReading rule:\n")
  cat("- Levels: expect mixed / weak rejection of unit root.\n")
  cat("- First differences: expect stronger rejection of unit root.\n")
  cat("- KPSS should broadly move the other way.\n")
  cat("- Use this as a guardrail, not as a hard veto.\n\n")
  
  invisible(tb)
}

stage1_unitroot_guardrail_screen(stage1_master, "FULL")
stage1_unitroot_guardrail_screen(stage1_master, "PRE1974")
stage1_unitroot_guardrail_screen(stage1_master, "ISI1931_1973")
stage1_unitroot_guardrail_screen(stage1_master, "POST1974")

stage1_vecm_screen_compare <- function(fit, sample_name) {
  beta <- tsDyn::coefB(fit)
  alpha <- tsDyn::coefA(fit)
  sm <- summary(fit)
  
  out <- data.frame(
    sample = sample_name,
    log_M_beta = beta["log_M", 1],
    log_KME_beta = beta["log_KME", 1],
    log_NRS_beta = beta["log_NRS_proxy", 1],
    alpha_log_M = alpha["Equation log_M", "ECT"],
    alpha_log_KME = alpha["Equation log_KME", "ECT"],
    alpha_log_NRS = alpha["Equation log_NRS_proxy", "ECT"]
  )
  
  cat("\n========================================\n")
  cat("POST-ESTIMATION VECM summary\n")
  cat("Sample:", sample_name, "\n")
  cat("========================================\n\n")
  print(out, row.names = FALSE)
  cat("\n")
  print(sm)
  
  invisible(out)
}

paths <- stage1_paths()
fit_full <- readRDS(file.path(paths$txt, "stage1__vecm__FULL__S1_B__lag1__r1.rds"))
fit_pre  <- readRDS(file.path(paths$txt, "stage1__vecm__PRE1974__S1_B__lag1__r1.rds"))
fit_isi  <- readRDS(file.path(paths$txt, "stage1__vecm__ISI1931_1973__S1_B__lag1__r1.rds"))
fit_post <- readRDS(file.path(paths$txt, "stage1__vecm__POST1974__S1_B__lag1__r1.rds"))

summary(fit_pre)
tsDyn::coefB(fit_pre)
tsDyn::coefA(fit_pre)

summary(fit_isi)
tsDyn::coefB(fit_isi)
tsDyn::coefA(fit_isi)

postest_full <- stage1_vecm_screen_compare(fit_full, "FULL")
postest_pre  <- stage1_vecm_screen_compare(fit_pre, "PRE1974")
postest_isi  <- stage1_vecm_screen_compare(fit_isi, "ISI1931_1973")
postest_post <- stage1_vecm_screen_compare(fit_post, "POST1974")

stage1_summary <- dplyr::bind_rows(
  postest_full,
  postest_pre,
  postest_isi,
  postest_post
)

write.csv(
  stage1_summary,
  file.path(stage1_paths()$csv, "stage1__preferred_vecm_summary.csv"),
  row.names = FALSE
)
