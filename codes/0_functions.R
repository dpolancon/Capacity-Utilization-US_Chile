############################################################
## Consolidated helpers — reproducible + inference-safe
## (audited against urca refman; tidy/kable export hardened)
############################################################

# -------- Significance stars (robust, pretty) --------
add_stars <- function(vec, reverse = FALSE, digits = 2) {
  if (length(vec) < 4 || all(is.na(vec))) return("")
  v <- suppressWarnings(as.numeric(vec[1:4]))
  if (any(!is.finite(v))) return("")
  names(v) <- c("Test statistic","Critical value 1%","Critical value 5%","Critical value 10%")
  ts <- v[1]; c1 <- v[2]; c5 <- v[3]; c10 <- v[4]
  if (any(is.na(c(ts,c1,c5,c10)))) return("")
  stars <- if (reverse) {
    if (ts >= c1) "***" else if (ts >= c5) "**" else if (ts >= c10) "*" else ""
  } else {
    if (ts <= c1) "***" else if (ts <= c5) "**" else if (ts <= c10) "*" else ""
  }
  paste0(formatC(ts, format = "f", digits = digits), stars)
}

# -------- Unit root suite: ADF/PP/DF-GLS/ERS.PO/KPSS --------
UnitRootTests <- function(df_ts, model_type = c("constant","trend"),
                          adf_lag_select = c("BIC","AIC","Fixed"),
                          adf_lags = NULL,
                          ers_lag_max = 5,
                          pp_lags = c("short","long")) {
  if (!requireNamespace("urca", quietly = TRUE)) stop("Please install 'urca'")
  model_type <- match.arg(model_type)
  adf_lag_select <- match.arg(adf_lag_select)
  pp_lags <- match.arg(pp_lags)
  
  df_ts <- as.data.frame(df_ts)
  numeric_cols <- vapply(df_ts, is.numeric, TRUE)
  if (!any(numeric_cols)) stop("No numeric columns found in df_ts.")
  if (any(!numeric_cols)) warning("Ignored non-numeric columns: ", paste(names(df_ts)[!numeric_cols], collapse = ", "))
  df_ts <- df_ts[, numeric_cols, drop = FALSE]
  
  strip_na <- function(x) {
    ix <- which(is.finite(x))
    if (!length(ix)) return(numeric())
    x[min(ix):max(ix)]
  }
  
  var_names <- colnames(df_ts)
  test_names <- c("ADF","PP","DF.GL","ERS.PO","KPSS")
  empty_vec <- function() { vec <- rep(NA_real_, 4); names(vec) <- c("Test statistic","Critical value 1%","Critical value 5%","Critical value 10%"); vec }
  tests <- setNames(lapply(test_names, function(.) setNames(vector("list", length(var_names)), var_names)),
                    test_names)
  
  for (v in var_names) {
    x <- strip_na(df_ts[[v]])
    if (!length(x)) {
      tests$ADF[[v]]    <- empty_vec()
      tests$PP[[v]]     <- empty_vec()
      tests$DF.GL[[v]]  <- empty_vec()
      tests$ERS.PO[[v]] <- empty_vec()
      tests$KPSS[[v]]   <- empty_vec()
      next
    }
    
    # ADF with correct tau row (tau2 for drift, tau3 for trend)
    tests$ADF[[v]] <- tryCatch({
      adf_type <- if (model_type == "constant") "drift" else "trend"
      adf <- if (adf_lag_select %in% c("BIC","AIC")) {
        urca::ur.df(x, type = adf_type, selectlags = adf_lag_select)
      } else {
        if (is.null(adf_lags)) stop("When adf_lag_select='Fixed', provide adf_lags.")
        urca::ur.df(x, type = adf_type, lags = adf_lags)
      }
      tau_name <- if (model_type == "constant") "tau2" else "tau3"
      ts_vec <- adf@teststat
      ts <- if (is.matrix(ts_vec)) {
        rn <- rownames(ts_vec); idx <- which(rn == tau_name); if (!length(idx)) idx <- 1L
        unname(ts_vec[idx, 1])
      } else {
        tmp <- unname(ts_vec[tau_name]); if (is.na(tmp)) tmp <- unname(ts_vec[[1L]]); tmp
      }
      cv_mat <- adf@cval
      cv_r <- grep(paste0("^", tau_name), rownames(cv_mat)); if (!length(cv_r)) cv_r <- 1L
      cv <- cv_mat[cv_r, c("1pct","5pct","10pct"), drop = TRUE]
      vec <- c(ts, as.numeric(cv)); names(vec) <- names(empty_vec()); vec
    }, error = function(e){ warning(sprintf("ADF failed for %s: %s", v, conditionMessage(e))); empty_vec() })
    
    # PP (Z-tau), deterministic per model_type
    tests$PP[[v]] <- tryCatch({
      pp <- urca::ur.pp(x, type = "Z-tau", lags = pp_lags, model = model_type)
      ts <- unname(pp@teststat[1])
      cv <- pp@cval[1, c("1pct","5pct","10pct"), drop = TRUE]
      vec <- c(ts, as.numeric(cv)); names(vec) <- names(empty_vec()); vec
    }, error = function(e){ warning(sprintf("PP failed for %s: %s", v, conditionMessage(e))); empty_vec() })
    
    # DF-GLS
    tests$DF.GL[[v]] <- tryCatch({
      dfgls <- urca::ur.ers(x, type = "DF-GLS", model = model_type, lag.max = ers_lag_max)
      ts <- unname(dfgls@teststat[1])  # take first element, names differ across builds
      cv <- dfgls@cval[1, c("1pct","5pct","10pct"), drop = TRUE]
      vec <- c(ts, as.numeric(cv)); names(vec) <- names(empty_vec()); vec
    }, error = function(e){ warning(sprintf("DF-GLS failed for %s: %s", v, conditionMessage(e))); empty_vec() })
    
    # ERS Point-Optimal
    tests$ERS.PO[[v]] <- tryCatch({
      ers_po <- urca::ur.ers(x, type = "P-test", model = model_type, lag.max = ers_lag_max)
      ts <- unname(ers_po@teststat[1])  # same robustness
      cv <- ers_po@cval[1, c("1pct","5pct","10pct"), drop = TRUE]
      vec <- c(ts, as.numeric(cv)); names(vec) <- names(empty_vec()); vec
    }, error = function(e){ warning(sprintf("ERS.PO failed for %s: %s", v, conditionMessage(e))); empty_vec() })
    
    # KPSS: mu for level, tau for trend; long lag rule for robustness
    tests$KPSS[[v]] <- tryCatch({
      kpss_type <- if (model_type == "constant") "mu" else "tau"
      kpss <- urca::ur.kpss(x, type = kpss_type, lags = "long")
      ts <- unname(kpss@teststat[1])
      cv <- kpss@cval[1, c("1pct","5pct","10pct"), drop = TRUE]
      vec <- c(ts, as.numeric(cv)); names(vec) <- names(empty_vec()); vec
    }, error = function(e){ warning(sprintf("KPSS failed for %s: %s", v, conditionMessage(e))); empty_vec() })
  }
  
  for (t in test_names) tests[[t]] <- tests[[t]][var_names]
  
  structure(list(raw = tests, vars = var_names, tests = test_names,
                 model_type = model_type,
                 meta = list(adf_lag_select = adf_lag_select, ers_lag_max = ers_lag_max, pp_lags = pp_lags)),
            class = "unitroot_suite")
}

# -------- Make table of starred stats (wide) or tidy with raw + star --------
processAndAddStars <- function(test_results, tidy = FALSE, digits = 2) {
  stopifnot(is.list(test_results), !is.null(test_results$raw))
  raw <- test_results$raw; var_names <- test_results$vars; test_names <- test_results$tests
  out <- matrix(NA_character_, nrow = length(var_names), ncol = length(test_names),
                dimnames = list(var_names, test_names))
  for (t in test_names) {
    reverse <- identical(t, "KPSS")
    for (v in var_names) out[v, t] <- add_stars(raw[[t]][[v]], reverse = reverse, digits = digits)
  }
  df <- as.data.frame(out, stringsAsFactors = FALSE)
  if (!tidy) return(df)
  
  tidy_rows <- lapply(var_names, function(v) {
    do.call(rbind, lapply(test_names, function(t) {
      vec <- raw[[t]][[v]]
      if (length(vec) < 4) vec <- rep(NA_real_, 4)
      data.frame(var = v, test = t,
                 stat = vec[1], cval_1 = vec[2], cval_5 = vec[3], cval_10 = vec[4],
                 stat_star = add_stars(vec, reverse = identical(t,"KPSS"), digits = digits),
                 stringsAsFactors = FALSE)
    }))
  })
  do.call(rbind, tidy_rows)
}

# -------- Reshape helper (flat numeric vector -> matrix) --------
reshapeTestsResults <- function(results_vector, var_names,
                                test_names = c('ADF','PP','DF.GL','ERS.PO','KPSS'),
                                byrow = TRUE) {
  if (length(results_vector) != length(var_names) * length(test_names))
    stop("Length mismatch: results_vector must equal length(var_names) * length(test_names)")
  matrix(as.numeric(results_vector),
         nrow = length(var_names),
         ncol = length(test_names),
         byrow = byrow,
         dimnames = list(var_names, test_names))
}

# -------- Table export with optional kableExtra footnote/styling --------
table_as_is <- function(data, file_path,
                        column_labels = NULL,
                        caption = "Table",
                        format = c("latex", "html"),
                        overwrite = TRUE,
                        escape = TRUE,
                        return_string = FALSE,
                        footnote = NULL,
                        manifest_hook = NULL) {
  format <- match.arg(format)
  if (!is.data.frame(data) && !is.matrix(data)) stop("`data` must be a data.frame or matrix.")
  if (!is.null(column_labels)) {
    if (length(column_labels) != ncol(data)) stop("column_labels length mismatch.")
    colnames(data) <- column_labels
  }
  dir_path <- dirname(file_path)
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  if (file.exists(file_path) && !isTRUE(overwrite)) stop("File exists and overwrite = FALSE: ", file_path)
  
  if (!requireNamespace("knitr", quietly = TRUE)) stop("Package 'knitr' is required")
  tbl <- knitr::kable(data, format = format, booktabs = TRUE, caption = caption, escape = escape)
  
  if (requireNamespace("kableExtra", quietly = TRUE)) {
    if (format == "latex") {
      tbl <- kableExtra::kable_styling(tbl, latex_options = c("hold_position"))
      if (!is.null(footnote)) tbl <- kableExtra::footnote(tbl, general = footnote, threeparttable = TRUE)
    } else {
      tbl <- kableExtra::kable_styling(tbl, bootstrap_options = c("condensed","responsive"))
      if (!is.null(footnote)) tbl <- kableExtra::footnote(tbl, general = footnote)
    }
    tbl_string <- as.character(tbl)
  } else {
    # minimal fallback, append plain note if requested
    tbl_string <- paste(tbl, collapse = "\n")
    if (!is.null(footnote)) tbl_string <- paste0(tbl_string, sprintf("\n\nNote: %s\n", footnote))
  }
  
  if (isTRUE(return_string)) return(tbl_string)
  
  tryCatch({
    writeLines(tbl_string, con = file_path, useBytes = TRUE)
    if (is.function(manifest_hook)) manifest_hook(list(type = "table", file = file_path, caption = caption))
    invisible(file_path)
  }, error = function(e) stop("Failed to write table: ", conditionMessage(e)))
}

############################
# Reproducible export utils
############################

# Ensure directories exist (idempotent)
ensure_dirs <- function(paths) {
  dirs <- unique(normalizePath(paths, winslash = "/", mustWork = FALSE))
  invisible(lapply(dirs, function(p)
    if (!dir.exists(p)) dir.create(p, recursive = TRUE, showWarnings = FALSE)))
}

# Deterministic seed setup
set_seed_deterministic <- function(seed = 123456) {
  RNGkind(kind = "Mersenne-Twister", normal.kind = "Inversion")
  set.seed(seed)
}

# ggplot saver: PDF first (Cairo if available) + PNG backup
save_plot_dual <- function(gg, filepath_no_ext,
                           width = 9, height = 5.2, dpi = 300,
                           overwrite = TRUE) {
  stopifnot(requireNamespace("ggplot2", quietly = TRUE))
  dir.create(dirname(filepath_no_ext), recursive = TRUE, showWarnings = FALSE)
  pdf_path <- paste0(filepath_no_ext, ".pdf")
  png_path <- paste0(filepath_no_ext, ".png")
  if (!overwrite && (file.exists(pdf_path) || file.exists(png_path)))
    stop("File exists and overwrite = FALSE: ", filepath_no_ext)
  
  # Try Cairo PDF for better text; fallback to default device
  try({
    ggplot2::ggsave(filename = pdf_path, plot = gg,
                    width = width, height = height,
                    device = get0("cairo_pdf", envir = asNamespace("grDevices"), inherits = FALSE),
                    bg = "white")
  }, silent = TRUE)
  if (!file.exists(pdf_path)) {
    ggplot2::ggsave(filename = pdf_path, plot = gg, width = width, height = height, bg = "white")
  }
  
  ggplot2::ggsave(filename = png_path, plot = gg,
                  width = width, height = height, dpi = dpi, bg = "white")
  invisible(list(pdf = pdf_path, png = png_path))
}

# Base graphics saver (for packages that plot via base)
save_baseplot_dual <- function(plot_expr, filepath_no_ext,
                               width = 9, height = 5.2, dpi = 300,
                               overwrite = TRUE) {
  dir.create(dirname(filepath_no_ext), recursive = TRUE, showWarnings = FALSE)
  pdf_path <- paste0(filepath_no_ext, ".pdf")
  png_path <- paste0(filepath_no_ext, ".png")
  if (!overwrite && (file.exists(pdf_path) || file.exists(png_path)))
    stop("File exists and overwrite = FALSE: ", filepath_no_ext)
  
  grDevices::pdf(pdf_path, width = width, height = height)
  try({ eval.parent(substitute(plot_expr)) }, silent = TRUE)
  grDevices::dev.off()
  
  grDevices::png(png_path, width = width * 96, height = height * 96, res = dpi)
  try({ eval.parent(substitute(plot_expr)) }, silent = TRUE)
  grDevices::dev.off()
  
  invisible(list(pdf = pdf_path, png = png_path))
}

# Tidy LaTeX + optional CSV export wrapper
save_table_tex_csv <- function(data, tex_path, csv_path = NULL,
                               caption = "Table", footnote = NULL,
                               escape = TRUE, overwrite = TRUE) {
  if (!requireNamespace("knitr", quietly = TRUE)) stop("Package 'knitr' required for LaTeX export")
  dir.create(dirname(tex_path), recursive = TRUE, showWarnings = FALSE)
  if (!is.null(csv_path)) dir.create(dirname(csv_path), recursive = TRUE, showWarnings = FALSE)
  if (!overwrite && (file.exists(tex_path) || (!is.null(csv_path) && file.exists(csv_path))))
    stop("File exists and overwrite = FALSE: ", tex_path)
  
  if (exists("table_as_is", mode = "function")) {
    table_as_is(data, file_path = tex_path, caption = caption,
                format = "latex", overwrite = TRUE,
                escape = escape, footnote = footnote)
  } else {
    tbl <- knitr::kable(data, format = "latex", booktabs = TRUE, caption = caption, escape = escape)
    writeLines(paste(tbl, collapse = "\n"), con = tex_path, useBytes = TRUE)
  }
  
  if (!is.null(csv_path)) {
    if (!requireNamespace("readr", quietly = TRUE)) stop("Package 'readr' required for CSV export")
    readr::write_csv(as.data.frame(data), csv_path)
  }
  invisible(list(tex = tex_path, csv = csv_path))
}

# Session info snapshot (plain text)
write_session_info <- function(path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  txt <- tryCatch({
    if (requireNamespace("sessioninfo", quietly = TRUE)) {
      paste(capture.output(sessioninfo::session_info()), collapse = "\n")
    } else {
      paste(capture.output(utils::sessionInfo()), collapse = "\n")
    }
  }, error = function(e) paste("sessionInfo() failed:", conditionMessage(e)))
  writeLines(txt, path, useBytes = TRUE)
  invisible(path)
}

#----------------------------------#
### Helpers Chao-Phillip Grid ####
#----------------------------------#

ensure_dirs <- function(...) {
  paths <- c(...)
  for (p in paths)
    if (!dir.exists(p))
      dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

safe_logdet <- function(resids) {
  S <- stats::cov(resids, use = "pairwise.complete.obs")
  as.numeric(determinant(S, logarithm = TRUE)$modulus)
}

set_seed_deterministic <- function(seed = 12345) {
  set.seed(seed)
  suppressWarnings(
    RNGkind(kind="Mersenne-Twister", normal.kind="Inversion")
  )
}

write_tex_table <- function(df, out_path, caption = NULL, label = NULL, digits = 3) {
  tex <- knitr::kable(
    df, format = "latex", booktabs = TRUE, longtable = TRUE,
    caption = caption, label = label, digits = digits
  ) |>
    kableExtra::kable_styling(latex_options = c("hold_position","repeat_header"), font_size = 9)
  writeLines(tex, con = out_path)
}




export_pair <- function(df, csv_path, tex_path, caption = NULL, label = NULL, digits = 3) {
  utils::write.csv(df, csv_path, row.names = FALSE)
  write_tex_table(df, tex_path, caption = caption, label = label, digits = digits)
}



label_ecdet <- function(x) {
  x <- as.character(x)
  out <- x
  out[x == "none"]  <- "No Constant"
  out[x == "const"] <- "Constant"
  out[x == "trend"] <- "Trend"
  out
}
