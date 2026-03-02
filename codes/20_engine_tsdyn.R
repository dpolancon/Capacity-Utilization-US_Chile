# ============================================================
# 20_engine_tsdyn.R — Layer 1 Estimation Engine (tsDyn)
#
# CLEAN ARCHITECTURE REBUILD (Layer 1 only):
#   - Estimate models on the full lattice (p,r)
#   - Store likelihood geometry + bookkeeping
#   - NO IC, NO winner selection, NO comparability filters
#
# FROZEN LAG LOGIC (from 10_config_tsdyn.R):
#   tsDyn VECM(lag = p)  => p lags of ΔX in short run
#   r = 0 must be: lineVar(..., model="VAR", I="diff")
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","readxl","dplyr","tidyr","tsDyn","readr","tibble","stringr","purrr")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

here::i_am("codes/20_engine_tsdyn.R")
source(here::here("codes","10_config_tsdyn.R"))
source(here::here("codes","99_tsdyn_utils.R"))

`%||%` <- get0("%||%", ifnotfound = function(a,b) if (is.null(a)) b else a)

# ------------------------------------------------------------
# Output roots (same convention as old engine)
# ------------------------------------------------------------
ROOT_OUT <- here::here(CONFIG$OUT_TSDYN %||% "output/TsDynEngine")
DIRS <- list(
  csv  = file.path(ROOT_OUT,"csv"),
  logs = file.path(ROOT_OUT,"logs"),
  meta = file.path(ROOT_OUT,"meta")
)
dir.create(DIRS$csv,  recursive=TRUE, showWarnings=FALSE)
dir.create(DIRS$logs, recursive=TRUE, showWarnings=FALSE)
dir.create(DIRS$meta, recursive=TRUE, showWarnings=FALSE)

OUT_CSV <- file.path(DIRS$csv,  "APPX_rank_profile_full.csv")
OUT_FEAS <- file.path(DIRS$csv, "APPX_p_feasibility_summary.csv")
OUT_FAIL <- file.path(DIRS$csv, "APPX_fail_summary.csv")

cat("=== 20_engine_tsdyn (Layer 1: likelihood objects only) start ===\n")
set.seed(CONFIG$seed %||% 123456L)

# ------------------------------------------------------------
# Parameter bookkeeping (as per your Layer 1 spec)
# ------------------------------------------------------------
k_longrun <- function(m, r) as.integer(2*m*r - r^2)              # 2mr − r^2
k_rank_increment <- function(m, r) as.integer(2*m - 2*r - 1)     # 2m − 2r − 1
k_shortrun <- function(m, p) as.integer(m*m*(p - 1L))            # m^2 (p−1)

k_det <- function(m, r, DSR, DLR) {
  # Deterministics: explicit, logged, no silent mapping.
  # Short-run deterministic enters each Δ equation: contributes m per term
  # Long-run deterministic enters cointegration space: contributes r per term
  k_sr <- ifelse(DSR == "none", 0L, as.integer(m))
  k_lr <- ifelse(DLR == "none", 0L, as.integer(r))
  as.integer(k_sr + k_lr)
}

# ------------------------------------------------------------
# Robust logLik extraction (two-step):
#  1) stats::logLik(model) when available
#  2) fallback from residual covariance (Gaussian) when possible
#
# NOTE: We keep T_eff as a bookkeeping column only.
#       We do NOT force T_eff inside the likelihood unless the method needs it.
# ------------------------------------------------------------
tsdyn_loglik_safe2_local <- function(model, m) {
  # returns list(ll=..., source=..., reason=...)
  # source ∈ {"stats_logLik","resid_Sigma", NA}
  
  # ---- v1: stats::logLik ----
  ll1 <- tryCatch({
    v <- stats::logLik(model)
    as.numeric(v)[1]
  }, error = function(e) NA_real_)
  
  if (is.finite(ll1)) {
    return(list(ll = ll1, source = "stats_logLik", reason = "computed"))
  }
  
  # ---- v2: fallback from residual covariance ----
  # Try to obtain residuals matrix (T x m)
  res <- tryCatch({
    r <- stats::residuals(model)
    if (is.null(r)) return(NULL)
    r <- as.matrix(r)
    if (ncol(r) != m) {
      # sometimes residuals come as vector per equation; try to coerce
      if (is.vector(r) && length(r) %% m == 0) r <- matrix(r, ncol = m)
    }
    r
  }, error = function(e) NULL)
  
  if (is.null(res) || !is.matrix(res) || nrow(res) < 5) {
    return(list(ll = NA_real_, source = NA_character_, reason = "fail: logLik extraction"))
  }
  
  # residual covariance
  Sigma <- tryCatch({
    stats::cov(res, use = "pairwise.complete.obs")
  }, error = function(e) NULL)
  
  if (is.null(Sigma) || any(!is.finite(Sigma))) {
    return(list(ll = NA_real_, source = NA_character_, reason = "fail: logLik extraction"))
  }
  
  detS <- tryCatch(as.numeric(det(Sigma)), error = function(e) NA_real_)
  if (!is.finite(detS) || detS <= 0) {
    return(list(ll = NA_real_, source = NA_character_, reason = "fail: logLik extraction"))
  }
  
  T_eff_here <- nrow(res)
  
  # Gaussian log-likelihood (up to constant):
  # ll = -(T/2) [ m*log(2π) + log|Σ| + m ]
  # We keep full expression for comparability across cells (constants matter in IC later anyway).
  ll2 <- -0.5 * T_eff_here * (m * log(2*pi) + log(detS) + m)
  
  if (!is.finite(ll2)) {
    return(list(ll = NA_real_, source = NA_character_, reason = "fail: logLik extraction"))
  }
  
  list(ll = ll2, source = "resid_Sigma", reason = "computed")
}

# ------------------------------------------------------------
# Data load (same as old engine)
# ------------------------------------------------------------
df_raw <- readxl::read_excel(
  here::here(CONFIG$data_file),
  sheet = CONFIG$data_sheet %||% "us_data"
)
df_raw <- as.data.frame(df_raw)

df_raw$year  <- as.numeric(df_raw[[CONFIG$year_col]])
df_raw$log_y <- log(as.numeric(df_raw[[CONFIG$y_col]]))
df_raw$log_k <- log(as.numeric(df_raw[[CONFIG$k_col]]))
df_raw$e_raw <- as.numeric(df_raw[[CONFIG$e_col]])

df_raw <- df_raw[
  is.finite(df_raw$year) &
    is.finite(df_raw$log_y) &
    is.finite(df_raw$log_k) &
    is.finite(df_raw$e_raw),
]

SPEC_SET  <- names(CONFIG$SPECS)
WINDOWS   <- CONFIG$WINDOWS_LOCKED
det_df    <- det_pairs(CONFIG)  # must provide: DSR, DLR, det_tag, include, LRinclude

# basis_set consistent with old engine intent
basis_set <- unique(ifelse(as.logical(CONFIG$ORTHO_TOGGLE), "ortho", "raw"))

# lag bounds from config
P_MIN <- as.integer(CONFIG$P_MIN %||% 1L)
P_MAX <- as.integer(CONFIG$P_MAX_EXPLORATORY %||% 7L)

results_list <- list()
heartbeat_every <- as.integer(CONFIG$HEARTBEAT_EVERY %||% 25L)
counter <- 0L

# ------------------------------------------------------------
# GRID LOOP (spec × basis × window × deterministics × p × r)
# ------------------------------------------------------------
for (spec in SPEC_SET) {
  
  degree <- as.integer(CONFIG$SPECS[[spec]]$degree)
  
  for (basis_tag in basis_set) {
    
    for (window_name in names(WINDOWS)) {
      
      bounds <- WINDOWS[[window_name]]
      df_win <- df_raw[df_raw$year >= bounds[1] & df_raw$year <= bounds[2], ]
      
      if (nrow(df_win) < 10) next
      T_window <- nrow(df_win)
      
      # ------------------------------------------------------
      # Build distributive polynomial block (exact old logic)
      # ------------------------------------------------------
      if (degree == 1L) {
        df_win$Q1 <- df_win$e_raw
      } else {
        if (basis_tag == "ortho") {
          basis_obj <- basis_build_rawpowers_qr(
            df_win,
            e_col  = "e_raw",
            degree = degree
          )
          df_win <- basis_apply_rawpowers_qr(
            df_win,
            basis  = basis_obj,
            prefix = "Q"
          )
        } else {
          df_win <- basis_apply_rawpowers(
            df_win,
            e_col  = "e_raw",
            degree = degree,
            prefix = "Q"
          )
        }
      }
      
      # ------------------------------------------------------
      # Deterministics loop
      # ------------------------------------------------------
      for (i in seq_len(nrow(det_df))) {
        
        DSR       <- det_df$DSR[i]
        DLR       <- det_df$DLR[i]
        det_tag   <- det_df$det_tag[i]
        include   <- det_df$include[i]
        LRinclude <- det_df$LRinclude[i]
        
        # --------------------------------------------------
        # Build state vector X (exact old logic)
        # --------------------------------------------------
        X <- data.frame(
          log_y = df_win$log_y,
          log_k = df_win$log_k
        )
        
        if (isTRUE(CONFIG$INCLUDE_E_RAW)) {
          X$e_raw <- df_win$e_raw
        }
        
        for (jj in seq_len(degree)) {
          X[[paste0("Q", jj, "_logK")]] <- df_win[[paste0("Q", jj)]] * df_win$log_k
        }
        
        m <- ncol(X)
        
        # --------------------------------------------------
        # Lag loop
        # --------------------------------------------------
        for (p_vecm in P_MIN:P_MAX) {
          
          # Rank loop: r ∈ [0, m-1]
          for (r0 in 0:(m - 1L)) {
            
            counter <- counter + 1L
            if (isTRUE(CONFIG$VERBOSE_CONSOLE) && (counter %% heartbeat_every == 0L)) {
              cat(sprintf("... heartbeat %d | %s %s %s %s | p=%d r=%d | T=%d m=%d\n",
                          counter, spec, basis_tag, window_name, det_tag, p_vecm, r0, T_window, m))
            }
            
            # bookkeeping computed regardless of success
            kLR  <- k_longrun(m, r0)
            kSR  <- k_shortrun(m, p_vecm)
            kDET <- k_det(m, r0, DSR, DLR)
            kTOT <- as.integer(kLR + kSR + kDET)
            
            model <- tryCatch({
              
              if (r0 == 0L) {
                
                # r = 0 null (FROZEN): unrestricted VAR in differences
                tsDyn::lineVar(
                  data    = X,
                  lag     = as.integer(p_vecm),
                  model   = "VAR",
                  I       = "diff",
                  include = include
                )
                
              } else {
                
                # r ≥ 1: ML VECM via lineVar
                tsDyn::lineVar(
                  data      = X,
                  lag       = as.integer(p_vecm),
                  r         = as.integer(r0),
                  include   = include,
                  LRinclude = LRinclude,
                  model     = "VECM",
                  estim     = "ML"
                )
              }
              
            }, error = function(e) e)
            
            # common row payload builder (keeps columns consistent)
            base_row <- list(
              spec      = spec,
              basis     = basis_tag,
              window    = window_name,
              det_tag   = det_tag,
              p         = as.integer(p_vecm),
              r         = as.integer(r0),
              k_longrun = as.integer(kLR),
              k_total   = as.integer(kTOT),
              T_window  = as.integer(T_window),
              T_eff     = as.integer(T_window - p_vecm),  # bookkeeping only
              m         = as.integer(m)
            )
            
            if (inherits(model, "error")) {
              results_list[[length(results_list) + 1L]] <- tibble::as_tibble(c(
                base_row,
                list(
                  logLik     = NA_real_,
                  ll_source  = NA_character_,
                  status     = paste0("fail: ", substr(conditionMessage(model), 1, 180))
                )
              ))
              next
            }
            
            # logLik extraction (v1 primary, v2 fallback)
            out_ll <- tsdyn_loglik_safe2_local(model, m = m)
            ll     <- out_ll$ll
            st     <- if (is.finite(ll)) "computed" else out_ll$reason
            
            results_list[[length(results_list) + 1L]] <- tibble::as_tibble(c(
              base_row,
              list(
                logLik     = ll,
                ll_source  = out_ll$source,
                status     = st
              )
            ))
          }
        }
      }
    }
  }
}

rank_profile <- dplyr::bind_rows(results_list) |>
  dplyr::arrange(spec, basis, window, det_tag, p, r)

readr::write_csv(rank_profile, OUT_CSV)

# ------------------------------------------------------------
# Minimal “move-forward” summaries for report stage:
#  (1) Fail summary by status
#  (2) p-feasibility: for each group, how far can we push p?
# ------------------------------------------------------------
fail_summary <- rank_profile |>
  dplyr::filter(status != "computed") |>
  dplyr::count(status, sort = TRUE)

readr::write_csv(fail_summary, OUT_FAIL)

p_feas <- rank_profile |>
  dplyr::mutate(computed = status == "computed") |>
  dplyr::group_by(spec, window, basis, det_tag, p) |>
  dplyr::summarise(
    m = dplyr::first(m),
    T_window = dplyr::first(T_window),
    share_computed = mean(computed),
    min_r_computed = if (any(computed)) min(r[computed]) else NA_integer_,
    max_r_computed = if (any(computed)) max(r[computed]) else NA_integer_,
    .groups="drop"
  ) |>
  dplyr::group_by(spec, window, basis, det_tag) |>
  dplyr::summarise(
    m = dplyr::first(m),
    T_window = dplyr::first(T_window),
    p_max_any = max(p[share_computed > 0], na.rm = TRUE),
    p_max_allr = suppressWarnings(max(p[share_computed == 1], na.rm = TRUE)),
    .groups="drop"
  ) |>
  dplyr::mutate(
    p_max_allr = ifelse(is.infinite(p_max_allr), NA_real_, p_max_allr)
  ) |>
  dplyr::arrange(spec, window, basis, det_tag)

readr::write_csv(p_feas, OUT_FEAS)

cat("=== 20_engine_tsdyn (Layer 1) done ===\n")
cat("Wrote: ", OUT_CSV, "\n")
cat("Wrote: ", OUT_FAIL, "\n")
cat("Wrote: ", OUT_FEAS, "\n")