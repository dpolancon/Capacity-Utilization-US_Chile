# ============================
# Stage 2 — Formal Diagnostics
# Outputs: output/diagnostics/*.tex
# ============================

#### 0) Packages (viz + diagnostics + export)  ####
pkgs <- c(
  "here","readxl","dplyr","tidyr","ggplot2","zoo","patchwork","stats",
  "knitr","kableExtra","urca","lmtest","tseries"
)
invisible(lapply(pkgs, require, character.only = TRUE))

#### 1) Preamble: paths, helpers, data  ####
source(paste0(here("codes"), "/0_functions.R"))  # helpers: add_stars, UnitRootTests, processAndAddStars, table_as_is, ensure_dirs, set_seed_deterministic, write_session_info
data_path   <- here("data/ddbb_cu_US_kgr.xlsx")
output_path <- here("output")

set_seed_deterministic()  # deterministic anything that uses RNG
ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

## PATCHES: add near the top, after packages and paths ====
diag_dir    <- file.path(output_path, "diagnostics","stage2")
log_file    <- file.path(diag_dir, "stage2_debug.log")
ensure_dirs(c(diag_dir))
cat("", file = log_file)  # reset log

logf <- function(...) {
  cat(sprintf("[%s] ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")), file = log_file, append = TRUE)
  cat(paste0(paste0(..., collapse = ""), "\n"), file = log_file, append = TRUE)
}

# Always write something, even on error
export_placeholder_tex <- function(path, title, msg) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  txt <- sprintf("\\begin{table}[H]\n\\centering\n\\caption{%s}\n\\begin{tabular}{c}\n\\toprule\n\\textit{%s}\\\\\n\\bottomrule\n\\end{tabular}\n\\end{table}\n",
                 gsub("\\\\", "\\\\", title), gsub("_", "\\\\_", msg))
  writeLines(txt, path, useBytes = TRUE)
  logf("PLACEHOLDER -> ", path, " :: ", msg)
}

safe_table_as_is <- function(obj, file_path, caption) {
  tryCatch({
    table_as_is(obj, file_path = file_path, caption = caption,
                format = "latex", overwrite = TRUE, escape = TRUE)
    logf("WROTE -> ", file_path)
  }, error = function(e) {
    export_placeholder_tex(file_path, caption, paste("Export failed:", conditionMessage(e)))
  })
}




#### 2) Build variables (exact scope you requested) ####
dfv <- ddbb_us |>
  dplyr::transmute(
    year      = .data$year,
    K         = .data$KGCRcorp,
    Y         = .data$Yrgdp,
    e         = .data$e,
    yk_input  = .data$yk,              # provided ratio (for cross-check)
    yk_calc   = .data$Yrgdp / .data$KGCRcorp,
    log_y     = log(.data$Yrgdp),
    log_k     = log(.data$KGCRcorp),
    log_yk    = log(yk_calc),
    e2        = (.data$e)^2,
    e_logk     = log_k*e,
    e2_logk     = log_k*e2,
    d_yk      = yk_calc - dplyr::lag(yk_calc),
    d_log_y   = log_y - dplyr::lag(log_y),
    d_log_k   = log_k - dplyr::lag(log_k),
    d_log_yk  = log_yk - dplyr::lag(log_yk),
    d_e       = e - dplyr::lag(e),
    d_e2      = e2 - dplyr::lag(e2),
    d_e_logk  = e_logk - dplyr::lag(e_logk),
    d_e2_logk = e2_logk - dplyr::lag(e2_logk)
  )

# Optional cross-check of provided vs computed y/k
if ("yk_input" %in% names(dfv)) {
  d_mx <- suppressWarnings(max(abs(dfv$yk_input - dfv$yk_calc), na.rm = TRUE))
  if (is.finite(d_mx) && d_mx > 1e-8) message(sprintf("WARN: yk mismatch max |input - calc| = %.3e", d_mx))
}

# Basic guard
if (sum(is.finite(dfv$log_yk)) <= 20) stop("Too few usable observations for log_yk")

#### 3) Unit-root test suites (constant & trend) ####
vars_all <- c("log_y","log_k","log_yk","e","e2","e_logk","e2_logk","d_log_y","d_log_k","d_log_yk","d_e","d_e2","d_e_logk","d_e2_logk")

UR_const <- try(UnitRootTests(dplyr::select(dfv, dplyr::all_of(vars_all)),
                              model_type = "constant", adf_lag_select = "BIC"), silent = TRUE)
if (inherits(UR_const, "try-error")) {
  logf("ERROR UR_const: ", attr(UR_const, "condition")$message)
  export_placeholder_tex(file.path(diag_dir, "unitroot_const.tex"),
                         "Unit root tests (constant model)",
                         attr(UR_const, "condition")$message)
} else {
  UR_tbl_const <- try(processAndAddStars(UR_const), silent = TRUE)
  if (inherits(UR_tbl_const, "try-error")) {
    logf("ERROR process UR_const: ", attr(UR_tbl_const, "condition")$message)
    export_placeholder_tex(file.path(diag_dir, "unitroot_const.tex"),
                           "Unit root tests (constant model)",
                           attr(UR_tbl_const, "condition")$message)
  } else {
    safe_table_as_is(UR_tbl_const,
                     file.path(diag_dir, "unitroot_const.tex"),
                     "Unit root tests (constant model)")
  }
}

UR_trend <- try(UnitRootTests(dplyr::select(dfv, dplyr::all_of(vars_all)),
                              model_type = "trend", adf_lag_select = "BIC"), silent = TRUE)
if (inherits(UR_trend, "try-error")) {
  logf("ERROR UR_trend: ", attr(UR_trend, "condition")$message)
  export_placeholder_tex(file.path(diag_dir, "unitroot_trend.tex"),
                         "Unit root tests (trend model)",
                         attr(UR_trend, "condition")$message)
} else {
  UR_tbl_trend <- try(processAndAddStars(UR_trend), silent = TRUE)
  if (inherits(UR_tbl_trend, "try-error")) {
    logf("ERROR process UR_trend: ", attr(UR_tbl_trend, "condition")$message)
    export_placeholder_tex(file.path(diag_dir, "unitroot_trend.tex"),
                           "Unit root tests (trend model)",
                           attr(UR_tbl_trend, "condition")$message)
  } else {
    safe_table_as_is(UR_tbl_trend,
                     file.path(diag_dir, "unitroot_trend.tex"),
                     "Unit root tests (trend model)")
  }
}

UR_tbl_const <- processAndAddStars(UR_const)
UR_tbl_trend <- processAndAddStars(UR_trend)

table_as_is(UR_tbl_const,
            file_path = file.path(diag_dir, "unitroot_const.tex"),
            caption = "Unit root tests (constant model)",
            format = "latex", overwrite = TRUE, escape = TRUE)

table_as_is(UR_tbl_trend,
            file_path = file.path(diag_dir, "unitroot_trend.tex"),
            caption = "Unit root tests (trend model)",
            format = "latex", overwrite = TRUE, escape = TRUE)

#### 4) Baseline regressions and residual diagnostics ####

# ---- helpers ----
p_star <- function(p) {
  if (is.na(p)) return("")
  if (p < .01) return(sprintf("%.3f***", p))
  if (p < .05) return(sprintf("%.3f**", p))
  if (p < .10) return(sprintf("%.3f*", p))
  sprintf("%.3f", p)
}
.safe_lb_lag <- function(u, desired = 12L) {
  n <- sum(is.finite(u))
  max(2L, min(desired, n - 2L))
}
.safe_table_as_is <- function(obj, file_path, caption, escape = TRUE) {
  tryCatch({
    table_as_is(obj, file_path = file_path, caption = caption,
                format = "latex", overwrite = TRUE, escape = escape)
    invisible(file_path)
  }, error = function(e) {
    dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
    placeholder <- sprintf("\\begin{table}[H]\\centering\\caption{%s}\\begin{tabular}{c}\\toprule\\textit{Export failed: %s}\\\\\\bottomrule\\end{tabular}\\end{table}\n",
                           caption, gsub("_", "\\\\_", conditionMessage(e), fixed = TRUE))
    writeLines(placeholder, file_path, useBytes = TRUE)
    invisible(file_path)
  })
}

# ---- core runner for a 2-model block (linear + quadratic) ----
.run_block <- function(data, dep, lin, sq, label_prefix,
                       bg_order = 4L, lb_lag = 12L) {
  need <- c(dep, lin, sq)
  if (!all(need %in% names(data))) {
    stop("Missing required columns: ", paste(setdiff(need, names(data)), collapse = ", "))
  }
  D <- data[complete.cases(data[need]), need, drop = FALSE]
  if (nrow(D) < 25) warning("Small sample for ", label_prefix, ": n = ", nrow(D))
  
  f_lin  <- stats::as.formula(paste(dep, "~", lin))
  f_quad <- stats::as.formula(paste(dep, "~", paste(c(lin, sq), collapse = " + ")))
  
  m_lin  <- stats::lm(f_lin,  data = D)
  m_quad <- stats::lm(f_quad, data = D)
  
  u_lin  <- residuals(m_lin)
  u_quad <- residuals(m_quad)
  
  lag_lin  <- .safe_lb_lag(u_lin,  desired = lb_lag)
  lag_quad <- .safe_lb_lag(u_quad, desired = lb_lag)
  
  BG_lin   <- try(lmtest::bgtest(m_lin,  order = bg_order), silent = TRUE)
  BG_quad  <- try(lmtest::bgtest(m_quad, order = bg_order), silent = TRUE)
  
  LB2_lin  <- try(Box.test(u_lin^2,  type = "Ljung-Box", lag = lag_lin),  silent = TRUE)
  LB2_quad <- try(Box.test(u_quad^2, type = "Ljung-Box", lag = lag_quad), silent = TRUE)
  
  JB_lin   <- try(tseries::jarque.bera.test(u_lin),  silent = TRUE)
  JB_quad  <- try(tseries::jarque.bera.test(u_quad), silent = TRUE)
  
  p_BG_lin   <- if (inherits(BG_lin,  "htest")) BG_lin$p.value   else NA_real_
  p_BG_quad  <- if (inherits(BG_quad, "htest")) BG_quad$p.value  else NA_real_
  p_LB2_lin  <- if (inherits(LB2_lin, "htest")) LB2_lin$p.value  else NA_real_
  p_LB2_quad <- if (inherits(LB2_quad,"htest")) LB2_quad$p.value else NA_real_
  p_JB_lin   <- if (!inherits(JB_lin,  "try-error")) JB_lin$p.value   else NA_real_
  p_JB_quad  <- if (!inherits(JB_quad, "try-error")) JB_quad$p.value  else NA_real_
  
  infl_lin  <- try(stats::influence.measures(m_lin),  silent = TRUE)
  infl_quad <- try(stats::influence.measures(m_quad), silent = TRUE)
  lev_flag <- try({
    max(infl_lin$infmat[, "hat"], infl_quad$infmat[, "hat"], na.rm = TRUE) > 0.5
  }, silent = TRUE); if (inherits(lev_flag, "try-error")) lev_flag <- FALSE
  cd_flag <- try({
    max(cooks.distance(m_lin), cooks.distance(m_quad), na.rm = TRUE) > 1
  }, silent = TRUE); if (inherits(cd_flag, "try-error")) cd_flag <- FALSE
  
  use_HAC_block  <- any(c(p_BG_lin, p_BG_quad, p_LB2_lin, p_LB2_quad) < .10, na.rm = TRUE)
  use_gefp_block <- any(c(p_JB_lin, p_JB_quad) < .05, na.rm = TRUE)
  outlier_block  <- isTRUE(lev_flag) || isTRUE(cd_flag)
  
  tbl <- data.frame(
    Model = c(
      sprintf("%s: %s", label_prefix, "linear"),
      sprintf("%s: %s", label_prefix, "quadratic")
    ),
    Spec  = c(
      sprintf("%s ~ %s", dep, lin),
      sprintf("%s ~ %s + %s", dep, lin, sq)
    ),
    BG_p  = c(p_star(p_BG_lin),  p_star(p_BG_quad)),
    LB2_p = c(p_star(p_LB2_lin), p_star(p_LB2_quad)),
    JB_p  = c(p_star(p_JB_lin),  p_star(p_JB_quad)),
    stringsAsFactors = FALSE
  )
  
  flags <- data.frame(
    Model        = c(sprintf("%s: linear", label_prefix), sprintf("%s: quadratic", label_prefix)),
    use_HAC      = c(use_HAC_block,  use_HAC_block),
    hac_kind     = if (use_HAC_block) "Newey-West" else "",
    use_gefp     = c(use_gefp_block, use_gefp_block),
    outlier_flag = c(outlier_block,  outlier_block),
    stringsAsFactors = FALSE
  )
  
  list(table = tbl, flags = flags)
}

# ---- run both LEVELS and DIFFS ----
# Expects dfv with: log_yk, e, e2, d_log_yk, d_e, d_e2
# Expects diag_dir defined upstream

blk_levels <- .run_block(data = dfv,
                         dep = "log_yk", lin = "e", sq = "e2",
                         label_prefix = "Levels")

blk_levels_eK <- .run_block(data = dfv,
                         dep = "log_y", lin = "e_logk", sq = "e2_logk",
                         label_prefix = "Levels")

blk_diffs  <- .run_block(data = dfv,
                         dep = "d_log_yk", lin = "d_e", sq = "d_e2",
                         label_prefix = "First differences")

blk_diffs_eK <- .run_block(data = dfv,
                         dep = "d_log_y", lin = "d_e_logk", sq = "d_e2_logk",
                         label_prefix = "First differences")


# Combine into the single residual_tests_baseline table (4 rows)
residual_tbl <- rbind(blk_levels$table,blk_levels_eK$table, blk_diffs$table,blk_diffs_eK$table)

._caption1 <- "Residual diagnostics for baseline models (levels and first differences)"
._caption2 <- "Routing flags for Stage 3 admissibility (levels and first differences)"

._file1 <- file.path(diag_dir, "residual_tests_baseline.tex")
._file2 <- file.path(diag_dir, "routing_summary.tex")

.safe_table_as_is(residual_tbl, ._file1, ._caption1)

routing_tbl <- rbind(blk_levels$flags,blk_levels_eK$flags, blk_diffs$flags,blk_diffs_eK$flags)
._safe <- .safe_table_as_is(routing_tbl, ._file2, ._caption2)


#### 5) Session info snapshot (plain text) ####
write_session_info(file.path(diag_dir, "session_info.txt"))
logf("DONE Stage 2")

# Done. If anything complains, it will be your data or the universe.