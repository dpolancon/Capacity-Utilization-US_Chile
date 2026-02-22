############################################################
## JOHANSEN ESTIMATION — BASELINE (urca), helper-consistent
## Full + Fordist + Post-Fordist
## Exports: output/JOHANSEN_CORE/{tex,csv,logs,rds,figs}
## REPORTING: one .txt per window with TRACE + MAX-EIGEN + BETA
## FIX: Johansen right-tail rejection stars (stat >= cv)
## FIX: robust append-to-txt (writeLines has no append/sep)
############################################################

#### 0) Packages (hard deps only) ####
pkgs <- c(
  "here","readxl","dplyr","tidyr","ggplot2","zoo",
  "stats","knitr","kableExtra",
  "urca","vars","tseries","lmtest","sandwich","strucchange"
)
invisible(lapply(pkgs, require, character.only = TRUE))

# Optional packages (do not fail if missing)
if (!requireNamespace("patchwork", quietly = TRUE)) {
  message("Optional pkg missing (ok): patchwork")
}

#### 1) Preamble: paths, helpers, data ####
source(paste0(here::here("codes"), "/0_functions.R"))  # your consolidated helpers

data_path   <- here::here("data/processed/ddbb_cu_US_kgr.xlsx")
output_path <- here::here("output")

set_seed_deterministic()
ensure_dirs(output_path)

ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

#### 2) Build base variables (levels + diffs) ####
df <- ddbb_us |>
  dplyr::transmute(
    year      = .data$year,
    K         = .data$KGCRcorp,
    Y         = .data$Yrgdp,
    e         = .data$e,                # exploitation = profits / wage bill
    yk_input  = .data$yk,
    yk_calc   = .data$Yrgdp / .data$KGCRcorp,
    log_y     = log(.data$Yrgdp),
    log_k     = log(.data$KGCRcorp),
    log_yk    = log(yk_calc),
    e2        = (.data$e)^2,
    # differences (base)
    d_log_y   = log_y - dplyr::lag(log_y),
    d_log_k   = log_k - dplyr::lag(log_k),
    d_e       = e     - dplyr::lag(e)
  ) |>
  dplyr::arrange(year)

#### 3) Window-specific demean + interactions (incl. cubic) + diffs ####
add_e_bar_and_interactions <- function(dfw) {
  mu_e <- mean(dfw$e, na.rm = TRUE)
  
  dfw |>
    dplyr::arrange(year) |>
    dplyr::mutate(
      # demeaned exploitation and powers
      e_bar   = e - mu_e,
      e_bar2  = e_bar^2,
      e_bar3  = e_bar^3,
      
      # raw powers
      e2      = e^2,
      e3      = e^3,
      
      # raw interactions required by strategy
      logK_e   = log_k * e,
      logK_e2  = log_k * e2,
      logK_e3  = log_k * e3,
      
      # demeaned interactions (multicollinearity-safe basis)
      logK_ebar  = log_k * e_bar,
      logK_ebar2 = log_k * e_bar2,
      logK_ebar3 = log_k * e_bar3,
      
      # differences of constructed terms
      d_e_bar       = e_bar       - dplyr::lag(e_bar),
      d_logK_e      = logK_e      - dplyr::lag(logK_e),
      d_logK_e2     = logK_e2     - dplyr::lag(logK_e2),
      d_logK_e3     = logK_e3     - dplyr::lag(logK_e3),
      d_logK_ebar   = logK_ebar   - dplyr::lag(logK_ebar),
      d_logK_ebar2  = logK_ebar2  - dplyr::lag(logK_ebar2),
      d_logK_ebar3  = logK_ebar3  - dplyr::lag(logK_ebar3)
    )
}

#### 4) (Optional) Unit-root variable lists (continuity) ####
vars_lvl <- c(
  "log_y","log_k",
  "e","e_bar",
  "logK_e","logK_e2","logK_e3",
  "logK_ebar","logK_ebar2","logK_ebar3"
)
vars_dif <- c(
  "d_log_y","d_log_k",
  "d_e","d_e_bar",
  "d_logK_e","d_logK_e2","d_logK_e3",
  "d_logK_ebar","d_logK_ebar2","d_logK_ebar3"
)

############################################################
## JOHANSEN CORE
############################################################

#### 5) Output folders + session snapshot ####
joh_root <- file.path(output_path, "JOHANSEN_CORE")
joh_tex  <- file.path(joh_root, "tex")
joh_csv  <- file.path(joh_root, "csv")
joh_log  <- file.path(joh_root, "logs")
joh_rds  <- file.path(joh_root, "rds")
joh_fig  <- file.path(joh_root, "figs")
ensure_dirs(c(joh_root, joh_tex, joh_csv, joh_log, joh_rds, joh_fig))

# snapshot environment (may warn about quarto; harmless)
write_session_info(file.path(joh_log, "session_info.txt"))

#### 5.1) Report helpers (robust append) ####
window_report_path <- function(wname) {
  file.path(joh_log, paste0("JOHANSEN_REPORT_", wname, ".txt"))
}
.report_line  <- function(ch = "=", n = 78) paste0(rep(ch, n), collapse = "")
.report_block <- function(title) c(.report_line("="), title, .report_line("="), "")
append_lines  <- function(lines, path) {
  cat(paste0(lines, collapse = "\n"), "\n", file = path, append = TRUE)
}

#### 6) Windows + interactions ####
df_full <- df |>
  dplyr::filter(!is.na(log_y) & !is.na(log_k) & !is.na(e)) |>
  add_e_bar_and_interactions()

df_ford <- df |>
  dplyr::filter(year <= 1973) |>
  dplyr::filter(!is.na(log_y) & !is.na(log_k) & !is.na(e)) |>
  add_e_bar_and_interactions()

df_post <- df |>
  dplyr::filter(year >= 1974) |>
  dplyr::filter(!is.na(log_y) & !is.na(log_k) & !is.na(e)) |>
  add_e_bar_and_interactions()

windows <- list(full = df_full, ford = df_ford, post = df_post)

#### 7) System specification (disciplined I(1) block only) ####
# DO NOT include e_bar/logK_ebar in long-run system
sys_vars_base  <- c("log_y", "log_k", "logK_e", "logK_e2")
sys_vars_cubic <- c("log_y", "log_k", "logK_e", "logK_e2", "logK_e3")

SYS_VARS <- sys_vars_base    # default
# SYS_VARS <- sys_vars_cubic  # enable only if you explicitly want cubic

ECDET  <- "const"            # "none" | "const" | "trend"
SPEC   <- "transitory"       # safe default
LAGMAX <- 6                  # annual data cap

#### 8) Helpers: safe slot, X builder, lag choice ####
safe_slot <- function(obj, slot_name) {
  if (!methods::is(obj, "ca.jo")) stop("Expected a urca 'ca.jo' object.")
  if (!slot_name %in% slotNames(obj)) return(NULL)
  slot(obj, slot_name)
}

make_X <- function(dfw, vars) {
  X <- dfw |>
    dplyr::select(dplyr::all_of(vars)) |>
    stats::na.omit() |>
    as.matrix()
  if (nrow(X) < 25) stop("Too few observations after NA omit for Johansen estimation.")
  X
}

choose_VAR_lag <- function(X, lag_max = 6, type = "const", criterion = "AIC(n)") {
  sel <- vars::VARselect(X, lag.max = lag_max, type = type)
  p <- as.integer(sel$selection[[criterion]])
  if (is.na(p) || p < 1) p <- 2L
  p
}

#### 9) Rank table builder (robust to urca vector/matrix) ####
# FIX: Johansen tests are RIGHT-TAIL rejection (reject for large stats)
build_rank_table <- function(jo_obj) {
  ts <- safe_slot(jo_obj, "teststat")
  cv <- safe_slot(jo_obj, "cval")
  if (is.null(ts) || is.null(cv)) stop("ca.jo missing teststat/cval slots.")
  
  ts_vec <- as.numeric(ts)
  
  if (is.null(dim(cv))) stop("Unexpected: cval has no dim(). Inspect slot(jo_obj,'cval').")
  need_cols <- c("1pct","5pct","10pct")
  if (!all(need_cols %in% colnames(cv))) {
    stop("cval columns not found. Available: ", paste(colnames(cv), collapse = ", "))
  }
  cv_mat <- cv[, need_cols, drop = FALSE]
  
  # Robust labels
  H0 <- rownames(ts)
  if (is.null(H0) || length(H0) == 0) H0 <- names(ts)
  if (is.null(H0) || length(H0) == 0) H0 <- rownames(cv_mat)
  if (is.null(H0) || length(H0) == 0) H0 <- paste0("r <= ", seq_len(length(ts_vec)) - 1)
  
  # Align lengths
  n <- min(length(ts_vec), nrow(cv_mat), length(H0))
  ts_vec <- ts_vec[seq_len(n)]
  cv_mat <- cv_mat[seq_len(n), , drop = FALSE]
  H0     <- H0[seq_len(n)]
  
  out <- data.frame(
    H0 = H0,
    stat = ts_vec,
    cv_1  = as.numeric(cv_mat[, "1pct"]),
    cv_5  = as.numeric(cv_mat[, "5pct"]),
    cv_10 = as.numeric(cv_mat[, "10pct"]),
    stringsAsFactors = FALSE
  )
  
  # Stars: RIGHT-TAIL rejection => reverse = FALSE
  out$stat_star <- vapply(seq_len(nrow(out)), function(i) {
    vec <- c(out$stat[i], out$cv_1[i], out$cv_5[i], out$cv_10[i])
    add_stars(vec, reverse = FALSE, digits = 2)
  }, character(1))
  
  # Reorder rows: show r=0 first, then r<=1, r<=2, ...
  out <- out[rev(seq_len(nrow(out))), ]
  
  out[, c("H0","stat_star","stat","cv_1","cv_5","cv_10")]
}

#### 10) Export rank outputs (hardened exporter) ####
export_rank_outputs <- function(rank_df, wname, test_type) {
  stopifnot(test_type %in% c("trace","eigen"))
  
  tex_path <- file.path(joh_tex, paste0("joh_rank_", test_type, "_", wname, ".tex"))
  csv_path <- file.path(joh_csv, paste0("joh_rank_", test_type, "_", wname, ".csv"))
  
  cap <- sprintf(
    "Johansen %s test (window: %s). Rejection is right-tail: reject if stat >= critical value.",
    test_type, wname
  )
  
  save_table_tex_csv(
    data = rank_df,
    tex_path = tex_path,
    csv_path = csv_path,
    caption  = cap,
    footnote = "Stars: *** 1%, ** 5%, * 10% (right-tail rejection).",
    escape   = TRUE,
    overwrite = TRUE
  )
}

#### 11) Run Johansen per window (trace + eigen) + write 1 report/window ####
run_johansen_window <- function(dfw, wname, sys_vars, ecdet, spec, lag_max) {
  X <- make_X(dfw, sys_vars)
  K <- choose_VAR_lag(X, lag_max = lag_max, type = "const", criterion = "AIC(n)")
  
  jo_trace <- urca::ca.jo(X, type = "trace", ecdet = ecdet, K = K, spec = spec)
  jo_eigen <- urca::ca.jo(X, type = "eigen", ecdet = ecdet, K = K, spec = spec)
  
  # Window report: overwrite each run (fresh), containing TRACE + MAX-EIGEN
  rpt <- window_report_path(wname)
  writeLines(character(0), con = rpt, useBytes = TRUE)
  
  append_lines(
    c(
      .report_block(sprintf("JOHANSEN REPORT — WINDOW: %s", toupper(wname))),
      sprintf("n = %d | K (VAR lag) = %d", nrow(X), K),
      sprintf("SYS_VARS: %s", paste(sys_vars, collapse = ", ")),
      sprintf("ECDET: %s | SPEC: %s | LAGMAX: %d", ecdet, spec, lag_max),
      sprintf("RUN DATE: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
      ""
    ),
    rpt
  )
  
  append_lines(c("---- ca.jo TRACE summary ----", capture.output(summary(jo_trace)), ""), rpt)
  append_lines(c("---- ca.jo MAX-EIGEN summary ----", capture.output(summary(jo_eigen)), ""), rpt)
  
  # Rank tables
  rank_trace <- build_rank_table(jo_trace)
  rank_eigen <- build_rank_table(jo_eigen)
  export_rank_outputs(rank_trace, wname, "trace")
  export_rank_outputs(rank_eigen, wname, "eigen")
  
  # Save objects
  saveRDS(jo_trace, file.path(joh_rds, paste0("jo_trace_", wname, ".rds")))
  saveRDS(jo_eigen, file.path(joh_rds, paste0("jo_eigen_", wname, ".rds")))
  
  list(window = wname, K = K, X = X, jo_trace = jo_trace, jo_eigen = jo_eigen, report = rpt)
}

res_full <- run_johansen_window(windows$full, "full", SYS_VARS, ECDET, SPEC, LAGMAX)
res_ford <- run_johansen_window(windows$ford, "ford", SYS_VARS, ECDET, SPEC, LAGMAX)
res_post <- run_johansen_window(windows$post, "post", SYS_VARS, ECDET, SPEC, LAGMAX)

#### 12) Choose ranks (edit after inspecting rank tables) + export beta + append to report ####
# Placeholder ranks (EDIT THESE)
r_full <- 2
r_ford <- 1
r_post <- 2

export_beta_and_residual_mats <- function(res, r, wname) {
  jo  <- res$jo_trace
  rpt <- window_report_path(wname)
  
  out <- tryCatch({
    fit  <- urca::cajorls(jo, r = r)
    beta <- fit$beta
    
    tex <- file.path(joh_tex, paste0("beta_", wname, "_r", r, ".tex"))
    csv <- file.path(joh_csv, paste0("beta_", wname, "_r", r, ".csv"))
    
    save_table_tex_csv(
      data = beta,
      tex_path = tex,
      csv_path = csv,
      caption  = sprintf("Cointegrating vectors (beta) from urca::cajorls; window: %s; r = %d.", wname, r),
      footnote = "Normalization follows urca::cajorls default. If r>1, interpret span(beta), not a single column.",
      escape   = TRUE,
      overwrite = TRUE
    )
    
    # Append beta to the same window report (robust append)
    append_lines(
      c(
        .report_line("-", 78),
        sprintf("COINTEGRATING VECTORS (beta) — cajorls | r = %d", r),
        .report_line("-", 78),
        capture.output(print(beta)),
        ""
      ),
      rpt
    )
    
    invisible(list(beta = beta))
  }, error = function(e) {
    append_lines(
      c(
        sprintf("[FAIL] cajorls/beta export for %s (r=%d): %s", wname, r, conditionMessage(e)),
        ""
      ),
      rpt
    )
    NULL
  })
  
  invisible(out)
}

export_beta_and_residual_mats(res_full, r_full, "full")
export_beta_and_residual_mats(res_ford, r_ford, "ford")
export_beta_and_residual_mats(res_post, r_post, "post")

#### 13) Minimal manifest log ####
writeLines(
  c(
    "JOHANSEN_CORE RUN COMPLETE",
    sprintf("SYS_VARS: %s", paste(SYS_VARS, collapse = ", ")),
    sprintf("ECDET: %s | SPEC: %s | LAGMAX: %d", ECDET, SPEC, LAGMAX),
    sprintf("Ranks chosen: full=%d, ford=%d, post=%d", r_full, r_ford, r_post),
    sprintf("Lags chosen (K): full=%d, ford=%d, post=%d", res_full$K, res_ford$K, res_post$K),
    sprintf("Window reports written to: %s", joh_log),
    "  - JOHANSEN_REPORT_full.txt",
    "  - JOHANSEN_REPORT_ford.txt",
    "  - JOHANSEN_REPORT_post.txt"
  ),
  con = file.path(joh_log, "run_manifest.txt"),
  useBytes = TRUE
)
