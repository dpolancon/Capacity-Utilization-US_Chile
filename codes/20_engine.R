# ============================================================
# 20_engine.R — tsDyn Lattice Engine (tsdyn_migration_stage1)
#
# CONSOLIDATED (2026-02-23, rev2)
# - Uses tsDyn ML logLik for VECM (Johansen ML).
# - Implements r=0 comparator via tsDyn::lineVar(VAR, I="diff") and labels r0_path="SP_Sigma0".
# - Computes PIC_star = logdet(Sigma_hat) + (log(T_eff)/T_eff) * (df_LR + df_SR)
#     df_LR = 2mr - r^2
#     df_SR = (p-1)m^2 + m*d_det  with d_det from DSR
# - Keeps legacy PIC_obs/BIC_obs for debugging (do not use for selection once report enforces PIC_star).
# - Adds structured diagnostics (fail_code, fail_msg, runtime_sec) without using runtime as a gate.
# - Fixes tsDyn lag mapping: lag_tsdyn := p (VECM lag in tsDyn).
# - FIX: robust common_p_max computation (no -Inf/Inf).
# - FIX: export schema includes PIC_star + components (so report can ingest it).
# - BONUS: ortho A fallback via QR if fit_ortho_A returns NULL.
#
# Writes ONLY under output/TsDynEngine/ (branch-local).
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here", "readxl", "dplyr", "tidyr", "tsDyn", "readr", "tibble")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

# ------------------------------------------------------------
# Repo anchors + config + utils
# ------------------------------------------------------------
here::i_am("codes/20_engine.R")
source(here::here("codes", "10_config_tsdyn.R"))
source(here::here("codes", "99_tsdyn_utils.R"))

`%||%` <- get0("%||%", ifnotfound = function(a, b) if (is.null(a)) b else a)

# Local fallback ensure_dirs if utils didn't define it
if (!exists("ensure_dirs", mode = "function")) {
  ensure_dirs <- function(...) {
    paths <- unique(c(...))
    paths <- paths[!is.na(paths) & nzchar(paths)]
    invisible(lapply(paths, function(p) if (!dir.exists(p)) dir.create(p, recursive = TRUE, showWarnings = FALSE)))
  }
}

# ------------------------------------------------------------
# Output dirs + logging
# ------------------------------------------------------------
ROOT_OUT <- here::here(CONFIG$OUT_TSDYN %||% "output/TsDynEngine")
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  logs = file.path(ROOT_OUT, "logs"),
  meta = file.path(ROOT_OUT, "meta")
)
ensure_dirs(DIRS$csv, DIRS$logs, DIRS$meta)

timestamp_tag <- format(Sys.time(), "%Y%m%d_%H%M%S")
log_handle <- NULL
if (exists("open_log", mode = "function")) {
  log_handle <- tryCatch(
    open_log(DIRS$logs, paste0("engine_tsdyn_", timestamp_tag), config = CONFIG),
    error = function(e) {
      message("[WARN] open_log failed: ", conditionMessage(e))
      NULL
    }
  )
}
if (!is.null(log_handle) && exists("close_log", mode = "function")) {
  on.exit(close_log(log_handle), add = TRUE)
}

cat("=== 20_engine_tsdyn start ===\n")
cat("Output root:", ROOT_OUT, "\n\n")

# ------------------------------------------------------------
# Read data
# ------------------------------------------------------------
cat("Reading input data...\n")
set.seed(CONFIG$seed %||% 123456L)

data_path  <- here::here(CONFIG$data_file)
sheet_name <- CONFIG$data_sheet %||% "us_data"

df_raw <- readxl::read_excel(data_path, sheet = sheet_name)
df_raw <- as.data.frame(df_raw)

year_col <- CONFIG$year_col %||% "year"
y_col    <- CONFIG$y_col %||% "Yrgdp"
k_col    <- CONFIG$k_col %||% "KGCRcorp"
e_col    <- CONFIG$e_col %||% "e"

df_raw$year  <- as.numeric(df_raw[[year_col]])
df_raw$log_y <- log(as.numeric(df_raw[[y_col]]))
df_raw$log_k <- log(as.numeric(df_raw[[k_col]]))
df_raw$e_raw <- as.numeric(df_raw[[e_col]])

ok_core <- is.finite(df_raw$year) & is.finite(df_raw$log_y) & is.finite(df_raw$log_k) & is.finite(df_raw$e_raw)
df_raw <- df_raw[ok_core, , drop = FALSE]

cat("Rows after finite filter:", nrow(df_raw), "\n")
cat("Columns in data:", paste(names(df_raw), collapse = ", "), "\n\n")

# ------------------------------------------------------------
# Axes: specs / basis / windows
# ------------------------------------------------------------
if (is.null(CONFIG$SPECS) || !is.list(CONFIG$SPECS) || length(CONFIG$SPECS) == 0) {
  stop("CONFIG$SPECS missing or empty.")
}
SPEC_SET <- names(CONFIG$SPECS)

basis_set <- NULL
if (!is.null(CONFIG$ORTHO_TOGGLE)) {
  basis_set <- unique(ifelse(as.logical(CONFIG$ORTHO_TOGGLE), "ortho", "raw"))
}
if (is.null(basis_set)) basis_set <- c("raw")

WINDOWS_LOCK <- CONFIG$WINDOWS_LOCKED %||% stop("CONFIG$WINDOWS_LOCKED missing")
windows_order <- names(WINDOWS_LOCK)

# ------------------------------------------------------------
# Ortho A fallback (QR): if fit_ortho_A returns NULL
# ------------------------------------------------------------
fallback_ortho_A <- function(df, e_col = "e_raw", degree = 2L) {
  e_vec <- as.numeric(df[[e_col]])
  e_vec <- e_vec[is.finite(e_vec)]
  if (length(e_vec) < (degree + 2L)) return(NULL)
  
  X_raw <- sapply(seq_len(degree), function(j) e_vec^j)
  X_raw <- as.matrix(X_raw)
  if (any(!is.finite(X_raw))) return(NULL)
  
  qrx <- qr(X_raw)
  if (qrx$rank < degree) return(NULL)
  
  R <- qr.R(qrx)
  # A = R^{-1} so that X_raw %*% A = Q (orthonormal columns)
  A <- tryCatch(solve(R, diag(degree)), error = function(e) NULL)
  if (is.null(A) || any(!is.finite(A))) return(NULL)
  
  list(A = A, method = "QR_fallback")
}

# ------------------------------------------------------------
# Precompute orthogonalization matrices A on FULL sample for each spec
# ------------------------------------------------------------
cat("Precomputing orthogonalization (full sample) where needed...\n")

basis_info_list <- list()
for (spec in SPEC_SET) {
  degree <- as.integer(CONFIG$SPECS[[spec]]$degree)
  for (basis_tag in basis_set) {
    
    # Q1 must be raw-only
    if (identical(spec, "Q1") && identical(basis_tag, "ortho")) next
    
    key <- paste0(spec, "_", basis_tag)
    
    if (basis_tag == "ortho") {
      basis_full <- tryCatch(
        fit_ortho_A(df_raw, e_col = "e_raw", degree = degree),
        error = function(e) NULL
      )
      A <- if (!is.null(basis_full) && !is.null(basis_full$A)) basis_full$A else NULL
      
      if (is.null(A)) {
        # fallback QR
        fb <- fallback_ortho_A(df_raw, e_col = "e_raw", degree = degree)
        A <- if (!is.null(fb)) fb$A else NULL
        if (!is.null(A)) cat("  [INFO] Ortho A computed via QR fallback for", key, "\n")
      }
      
      basis_info_list[[key]] <- list(type = "ortho", degree = degree, A = A)
    } else {
      basis_info_list[[key]] <- list(type = "raw", degree = degree, A = NULL)
    }
  }
}

# ------------------------------------------------------------
# Main lattice
# ------------------------------------------------------------
cat("Building lattice...\n")
LBL_APPX <- (CONFIG$OUT_LABELS$appx %||% "APPX")

det_df <- det_pairs(CONFIG)
if (nrow(det_df) == 0) stop("det_pairs(CONFIG) returned no deterministic pairs.")

results_list <- list()
p_max_by_window <- list()

for (spec in SPEC_SET) {
  degree <- as.integer(CONFIG$SPECS[[spec]]$degree)
  
  for (basis_tag in basis_set) {
    if (identical(spec, "Q1") && identical(basis_tag, "ortho")) next
    
    run_tag <- paste0(spec, "_", basis_tag)
    cat("\nRun tag:", run_tag, "(degree=", degree, ")\n")
    
    basis_info <- basis_info_list[[run_tag]]
    if (is.null(basis_info)) next
    
    for (window_name in windows_order) {
      cat(" Window:", window_name, "\n")
      win_bounds <- WINDOWS_LOCK[[window_name]]
      
      df_win <- df_raw[df_raw$year >= win_bounds[1] & df_raw$year <= win_bounds[2], , drop = FALSE]
      if (nrow(df_win) < 10) {
        cat("  Too few observations in window, skipping.\n")
        next
      }
      
      # Build polynomial block Qj in df_win
      if (basis_info$type == "ortho") {
        if (is.null(basis_info$A)) {
          cat("  [WARN] Ortho basis requested but A is NULL; skipping this run_tag.\n")
          next
        }
        e_vec <- df_win$e_raw
        X_raw <- sapply(seq_len(degree), function(j) e_vec^j)
        colnames(X_raw) <- paste0("Qraw", seq_len(degree))
        Q <- as.matrix(X_raw) %*% basis_info$A
        colnames(Q) <- paste0("Q", seq_len(degree))
        df_win <- cbind(df_win, as.data.frame(Q))
      } else {
        for (j in seq_len(degree)) df_win[[paste0("Q", j)]] <- df_win$e_raw^j
      }
      
      for (i in seq_len(nrow(det_df))) {
        DSR <- det_df$DSR[i]
        DLR <- det_df$DLR[i]
        det_tag <- det_df$det_tag[i]
        include <- det_df$include[i]
        LRinclude <- det_df$LRinclude[i]
        
        cat("  Deterministic:", det_tag, "(", include, ",", LRinclude, ")\n")
        
        # Build system matrix X: log_y, log_k, e_raw, and Qj*log_k terms
        X <- data.frame(log_y = df_win$log_y, log_k = df_win$log_k)
        if (isTRUE(CONFIG$INCLUDE_E_RAW %||% TRUE)) X$e_raw <- df_win$e_raw
        
        for (jj in seq_len(degree)) {
          nm <- paste0("Q", jj)
          X[[paste0(nm, "_logK")]] <- df_win[[nm]] * df_win$log_k
        }
        
        m <- ncol(X)
        
        p_min <- as.integer(CONFIG$P_MIN %||% 1L)
        p_max <- as.integer(CONFIG$P_MAX_EXPLORATORY %||% p_min)
        
        feasible_p_this <- integer()
        
        for (p_vecm in seq(p_min, p_max)) {
          
          # Gate (sample size / conditioning). Runtime is logged but not treated as a pass/fail gate.
          gate <- tryCatch(admissible_gate(X, p_vecm), error = function(e) list(ok = FALSE, msg = conditionMessage(e)))
          if (!isTRUE(gate$ok)) {
            for (r0 in 0:(m - 1)) {
              results_list[[length(results_list) + 1]] <- data.frame(
                spec = spec, basis = basis_tag, window = window_name,
                DSR = DSR, DLR = DLR, det_tag = det_tag,
                include = include, LRinclude = LRinclude,
                p = p_vecm, r = r0,
                m = m,
                status = "gate_fail",
                r0_path = if (r0 == 0L) "SP_Sigma0" else NA_character_,
                fail_code = "gate_fail",
                fail_msg = truncate_msg(gate$msg %||% "", 180L),
                runtime_sec = NA_real_,
                T_eff = NA_integer_,
                logLik_ML = NA_real_,
                logdet_Sigma = NA_real_,
                Cn = NA_real_,
                df_LR = as.integer(2L * m * r0 - r0 * r0),
                df_SR = as.integer((p_vecm - 1L) * m * m + m * det_count(DSR)),
                d_det = det_count(DSR),
                k_total = as.integer(k_total_rr(p_vecm, r0, m, DSR, DLR)),
                PIC_star = NA_real_,
                PIC_obs = NA_real_, BIC_obs = NA_real_,
                stringsAsFactors = FALSE
              )
            }
            next
          }
          
          # tsDyn lag mapping: p := tsDyn VECM lag argument (Δ-lag order)
          lag_tsdyn <- p_vecm
          
          for (r0 in 0:(m - 1)) {
            t0 <- proc.time()[["elapsed"]]
            
            d_det <- det_count(DSR)
            dfSR  <- as.integer((p_vecm - 1L) * m * m + m * d_det)
            dfLR  <- as.integer(2L * m * r0 - r0 * r0)
            kTot  <- as.integer(k_total_rr(p_vecm, r0, m, DSR, DLR))
            
            # -----------------
            # r = 0 comparator path (FROZEN): VAR in first differences
            # -----------------
            if (r0 == 0L) {
              fit0 <- fit_sigma0_var_diff(X_level = X, p_vecm = p_vecm, include = include)
              
              if (!isTRUE(fit0$ok)) {
                results_list[[length(results_list) + 1]] <- data.frame(
                  spec = spec, basis = basis_tag, window = window_name,
                  DSR = DSR, DLR = DLR, det_tag = det_tag,
                  include = include, LRinclude = LRinclude,
                  p = p_vecm, r = r0,
                  m = m,
                  status = "runtime_fail",
                  r0_path = "SP_Sigma0",
                  fail_code = fit0$fail_code %||% "R0_FAIL",
                  fail_msg = truncate_msg(fit0$fail_msg %||% "", 180L),
                  runtime_sec = as.numeric(proc.time()[["elapsed"]] - t0),
                  T_eff = NA_integer_,
                  logLik_ML = NA_real_,
                  logdet_Sigma = NA_real_,
                  Cn = NA_real_,
                  df_LR = dfLR,
                  df_SR = dfSR,
                  d_det = d_det,
                  k_total = kTot,
                  PIC_star = NA_real_,
                  PIC_obs = NA_real_, BIC_obs = NA_real_,
                  stringsAsFactors = FALSE
                )
                next
              }
              
              ll0 <- fit0$ll
              Sigma0 <- fit0$Sigma0
              T_eff <- as.integer(fit0$T_eff)
              logdet0 <- tryCatch(as.numeric(determinant(Sigma0, logarithm = TRUE)$modulus), error = function(e) NA_real_)
              Cn <- if (is.finite(T_eff) && T_eff > 1L) log(T_eff) else NA_real_
              
              PIC_star <- if (is.finite(logdet0) && is.finite(Cn)) logdet0 + (Cn / T_eff) * (dfLR + dfSR) else NA_real_
              
              PIC_obs <- if (is.finite(ll0) && is.finite(T_eff) && T_eff > 1L) (-2 * ll0 + kTot * log(T_eff) * log(log(T_eff))) else NA_real_
              BIC_obs <- if (is.finite(ll0) && is.finite(T_eff) && T_eff > 1L) (-2 * ll0 + kTot * log(T_eff)) else NA_real_
              
              results_list[[length(results_list) + 1]] <- data.frame(
                spec = spec, basis = basis_tag, window = window_name,
                DSR = DSR, DLR = DLR, det_tag = det_tag,
                include = include, LRinclude = LRinclude,
                p = p_vecm, r = r0,
                m = m,
                status = "computed",
                r0_path = "SP_Sigma0",
                fail_code = NA_character_,
                fail_msg = NA_character_,
                runtime_sec = as.numeric(proc.time()[["elapsed"]] - t0),
                T_eff = T_eff,
                logLik_ML = ll0,
                logdet_Sigma = logdet0,
                Cn = Cn,
                df_LR = dfLR,
                df_SR = dfSR,
                d_det = d_det,
                k_total = kTot,
                PIC_star = PIC_star,
                PIC_obs = PIC_obs,
                BIC_obs = BIC_obs,
                stringsAsFactors = FALSE
              )
              
              feasible_p_this <- unique(c(feasible_p_this, p_vecm))
              next
            }
            
            # -----------------
            # r > 0: VECM Johansen ML
            # -----------------
            model <- tryCatch(
              tsDyn::VECM(X, lag = lag_tsdyn, r = r0, include = include, LRinclude = LRinclude, estim = "ML"),
              error = function(e) e
            )
            
            if (inherits(model, "error")) {
              results_list[[length(results_list) + 1]] <- data.frame(
                spec = spec, basis = basis_tag, window = window_name,
                DSR = DSR, DLR = DLR, det_tag = det_tag,
                include = include, LRinclude = LRinclude,
                p = p_vecm, r = r0,
                m = m,
                status = "runtime_fail",
                r0_path = NA_character_,
                fail_code = "VECM_ML_FAIL",
                fail_msg = truncate_msg(conditionMessage(model), 180L),
                runtime_sec = as.numeric(proc.time()[["elapsed"]] - t0),
                T_eff = NA_integer_,
                logLik_ML = NA_real_,
                logdet_Sigma = NA_real_,
                Cn = NA_real_,
                df_LR = dfLR,
                df_SR = dfSR,
                d_det = d_det,
                k_total = kTot,
                PIC_star = NA_real_,
                PIC_obs = NA_real_,
                BIC_obs = NA_real_,
                stringsAsFactors = FALSE
              )
              next
            }
            
            ll <- tsdyn_loglik(model)
            U  <- tryCatch(stats::residuals(model), error = function(e) NULL)
            if (is.null(U)) {
              results_list[[length(results_list) + 1]] <- data.frame(
                spec = spec, basis = basis_tag, window = window_name,
                DSR = DSR, DLR = DLR, det_tag = det_tag,
                include = include, LRinclude = LRinclude,
                p = p_vecm, r = r0,
                m = m,
                status = "runtime_fail",
                r0_path = NA_character_,
                fail_code = "RESID_FAIL",
                fail_msg = "Could not extract residuals",
                runtime_sec = as.numeric(proc.time()[["elapsed"]] - t0),
                T_eff = NA_integer_,
                logLik_ML = ll,
                logdet_Sigma = NA_real_,
                Cn = NA_real_,
                df_LR = dfLR,
                df_SR = dfSR,
                d_det = d_det,
                k_total = kTot,
                PIC_star = NA_real_,
                PIC_obs = NA_real_,
                BIC_obs = NA_real_,
                stringsAsFactors = FALSE
              )
              next
            }
            
            U <- as.matrix(U)
            T_eff <- nrow(U)
            Sigma <- tryCatch(sigma_hat_ml(U, T_eff = T_eff), error = function(e) NULL)
            logdet <- tryCatch(as.numeric(determinant(Sigma, logarithm = TRUE)$modulus), error = function(e) NA_real_)
            Cn <- if (is.finite(T_eff) && T_eff > 1L) log(T_eff) else NA_real_
            
            PIC_star <- if (is.finite(logdet) && is.finite(Cn)) logdet + (Cn / T_eff) * (dfLR + dfSR) else NA_real_
            
            PIC_obs <- if (is.finite(ll) && is.finite(T_eff) && T_eff > 1L) (-2 * ll + kTot * log(T_eff) * log(log(T_eff))) else NA_real_
            BIC_obs <- if (is.finite(ll) && is.finite(T_eff) && T_eff > 1L) (-2 * ll + kTot * log(T_eff)) else NA_real_
            
            if (!is.finite(PIC_star)) {
              results_list[[length(results_list) + 1]] <- data.frame(
                spec = spec, basis = basis_tag, window = window_name,
                DSR = DSR, DLR = DLR, det_tag = det_tag,
                include = include, LRinclude = LRinclude,
                p = p_vecm, r = r0,
                m = m,
                status = "runtime_fail",
                r0_path = NA_character_,
                fail_code = "PICSTAR_NA",
                fail_msg = "PIC_star not finite",
                runtime_sec = as.numeric(proc.time()[["elapsed"]] - t0),
                T_eff = as.integer(T_eff),
                logLik_ML = ll,
                logdet_Sigma = logdet,
                Cn = Cn,
                df_LR = dfLR,
                df_SR = dfSR,
                d_det = d_det,
                k_total = kTot,
                PIC_star = NA_real_,
                PIC_obs = PIC_obs,
                BIC_obs = BIC_obs,
                stringsAsFactors = FALSE
              )
              next
            }
            
            results_list[[length(results_list) + 1]] <- data.frame(
              spec = spec, basis = basis_tag, window = window_name,
              DSR = DSR, DLR = DLR, det_tag = det_tag,
              include = include, LRinclude = LRinclude,
              p = p_vecm, r = r0,
              m = m,
              status = "computed",
              r0_path = NA_character_,
              fail_code = NA_character_,
              fail_msg = NA_character_,
              runtime_sec = as.numeric(proc.time()[["elapsed"]] - t0),
              T_eff = as.integer(T_eff),
              logLik_ML = ll,
              logdet_Sigma = logdet,
              Cn = Cn,
              df_LR = dfLR,
              df_SR = dfSR,
              d_det = d_det,
              k_total = kTot,
              PIC_star = PIC_star,
              PIC_obs = PIC_obs,
              BIC_obs = BIC_obs,
              stringsAsFactors = FALSE
            )
            
            feasible_p_this <- unique(c(feasible_p_this, p_vecm))
          }
        }
        
        if (length(feasible_p_this) > 0) {
          key <- paste(window_name, det_tag, run_tag, sep = "|")
          p_max_by_window[[key]] <- max(feasible_p_this)
        }
      }
    }
  }
}

# ------------------------------------------------------------
# Post-processing: comparability p flags + write outputs
# ------------------------------------------------------------
cat("\nPost-processing lattice...\n")

grid_df <- dplyr::bind_rows(results_list)

if (nrow(grid_df) == 0) {
  cat("No results to write.\n")
  cat("=== 20_engine_tsdyn complete ===\n")
  quit(save = "no")
}

# Comparable p region:
# common_p_max = min over windows within each (spec,basis,det_tag) among computed rows
grid_df <- grid_df |>
  dplyr::mutate(case_tag = paste0(spec, "_", basis, "|", det_tag))

pmax_tbl <- grid_df |>
  dplyr::filter(status == "computed") |>
  dplyr::group_by(case_tag, window) |>
  dplyr::summarise(
    p_max_window = if (any(is.finite(p))) max(p[is.finite(p)]) else NA_real_,
    .groups = "drop"
  )

common_tbl <- pmax_tbl |>
  dplyr::group_by(case_tag) |>
  dplyr::summarise(
    common_p_max = if (all(is.na(p_max_window))) NA_real_ else min(p_max_window, na.rm = TRUE),
    .groups = "drop"
  )

grid_df <- grid_df |>
  dplyr::left_join(common_tbl, by = "case_tag") |>
  dplyr::mutate(
    comparable_p = status == "computed" & is.finite(common_p_max) & is.finite(p) & p <= common_p_max,
    computed_comparable = status == "computed" & comparable_p
  ) |>
  dplyr::select(-case_tag)

# ------------------------------------------------------------
# Export schema: keep PIC_star + diagnostics in the CSVs
# ------------------------------------------------------------
export_cols <- c(
  "spec","basis","window","DSR","DLR","det_tag","include","LRinclude",
  "p","r","m","status",
  "PIC_star","logdet_Sigma","logLik_ML","Cn","T_eff",
  "df_LR","df_SR","d_det","k_total",
  "PIC_obs","BIC_obs",
  "common_p_max","comparable_p","computed_comparable",
  "r0_path","fail_code","fail_msg","runtime_sec"
)

make_export_df <- function(df) {
  # Ensure T_eff exists
  if (!("T_eff" %in% names(df))) df$T_eff <- NA_integer_
  
  # Backward compat: if n_eff exists in some older runs, merge it in
  if ("n_eff" %in% names(df)) {
    df$T_eff <- dplyr::coalesce(df$T_eff, as.integer(df$n_eff))
  }
  
  df |> dplyr::select(dplyr::any_of(export_cols), dplyr::everything())
}

# Write one CSV per (spec,basis,det_tag)
cat("Writing grid tables...\n")
for (det_tag in unique(grid_df$det_tag)) {
  sub_det <- grid_df[grid_df$det_tag == det_tag, , drop = FALSE]
  for (spec in unique(sub_det$spec)) {
    for (basis_tag in unique(sub_det$basis)) {
      file_name <- paste0(
        LBL_APPX, "_grid_pic_table_",
        spec, "_", basis_tag, "_", det_tag, "_unrestricted.csv"
      )
      path <- file.path(DIRS$csv, file_name)
      
      out_case <- make_export_df(sub_det[sub_det$spec == spec & sub_det$basis == basis_tag, , drop = FALSE])
      readr::write_csv(out_case, path)
    }
  }
}

# Feasible p summary
if (length(p_max_by_window) > 0) {
  summary_tbl <- tibble::tibble(
    key = names(p_max_by_window),
    p_max = unlist(p_max_by_window)
  ) |>
    tidyr::separate(key, into = c("window", "det_tag", "run_tag"), sep = "\\|")
  
  summary_path <- file.path(DIRS$csv, paste0(LBL_APPX, "_S1_feasible_pmax_by_window_det.csv"))
  readr::write_csv(summary_tbl, summary_path)
}

cat("=== 20_engine_tsdyn complete ===\n")