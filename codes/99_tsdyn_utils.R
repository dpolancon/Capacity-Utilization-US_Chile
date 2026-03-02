############################################################
# 99_tsdyn_utils.R — Utilities for tsDyn migration branch
#
# This file collects helper functions used by the tsDyn‐based
# diagnostics and inference scripts.  Functions are kept
# self‐contained and depend only on base R and the packages
# specified in DESCRIPTION.  They cover lag mapping, deterministic
# specification handling, orthogonal polynomial basis construction,
# state matrix construction, admissibility checks, logging, and
#
# NOTE (2026-02-23): consolidated helper layer appended at end:
#   - tsDyn ML logLik extraction
#   - explicit Σ̂ and log|Σ̂|
#   - r=0 comparator via lineVar(VAR, I="diff") + Σ̂(0)
#   - frozen k_SR / k_LR helpers and PIC components
#
############################################################

# --------------------------
# ORIGINAL CONTENT (unchanged)
# --------------------------

`%||%` <- function(x, y) if (is.null(x)) y else x

.pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf("Package '%s' is required but not installed.", pkg), call. = FALSE)
  }
  invisible(TRUE)
}

# ------------------------------------------------------------------
# Deterministic spec helpers
# ------------------------------------------------------------------
# tsDyn arguments:
#   include   ∈ {"const","trend","none","both"}    (short-run)
#   LRinclude ∈ {"none","const","trend","both"}    (long-run)
#
# Your project tags:
#   det_tag ∈ {"none","const","trend","both"} but split across DSR/DLR
#
# These helpers keep mappings explicit and consistent.



# ============================================================
# PATCH: vectorize resolve_include / resolve_LRinclude
# File: codes/99_tsdyn_utils.R
# ACTION: REPLACE existing resolve_include() and resolve_LRinclude()
# ============================================================

resolve_include <- function(DSR) {
  DSR <- as.character(DSR %||% "none")
  DSR <- tolower(trimws(DSR))
  allowed <- c("none","const","trend","both")
  DSR[is.na(DSR) | DSR == "" | !(DSR %in% allowed)] <- "none"
  DSR
}

resolve_LRinclude <- function(DLR) {
  DLR <- as.character(DLR %||% "none")
  DLR <- tolower(trimws(DLR))
  allowed <- c("none","const","trend","both")
  DLR[is.na(DLR) | DLR == "" | !(DLR %in% allowed)] <- "none"
  DLR
}


det_tag_from <- function(include, LRinclude) {
  paste0("SR_", include, "__LR_", LRinclude)
}

# ------------------------------------------------------------------
# Lag mapping (legacy utilities used in migration)
# ------------------------------------------------------------------
# IMPORTANT:
# tsDyn defines VECM lag in terms of ΔX lags, not VAR levels lags.
# Documentation reminder: "a VAR with 2 lags corresponds here to a VECM with 1 lag".
# Keep your grid definition explicit in engine; these are helpers only.

vecm_lag_to_var_levels_lag <- function(lag_vecm) {
  as.integer(lag_vecm) + 1L
}

var_levels_lag_to_vecm_lag <- function(lag_var_levels) {
  as.integer(lag_var_levels) - 1L
}

# ------------------------------------------------------------------
# Orthogonal polynomial basis helpers (QR rotation)
# ------------------------------------------------------------------
# Used to rotate polynomial blocks e, e^2, e logK, e^2 logK into an orthogonal basis
# while preserving invertibility (rank invariance).

qr_ortho_basis <- function(M) {
  M <- as.matrix(M)
  if (ncol(M) == 0L) return(M)
  q <- qr.Q(qr(M))
  colnames(q) <- paste0("Q", seq_len(ncol(q)))
  q
}

# ------------------------------------------------------------------
# State construction helpers
# ------------------------------------------------------------------
make_state_matrix <- function(df, vars) {
  out <- df[, vars, drop = FALSE]
  out <- as.matrix(out)
  storage.mode(out) <- "double"
  out
}

# ------------------------------------------------------------------
# Admissibility / gate checks (lightweight)
# ------------------------------------------------------------------
# Keep these conservative; do not treat runtime as a pass/fail gate.

gate_check_min_T <- function(T, m, p_max) {
  T <- as.integer(T); m <- as.integer(m); p_max <- as.integer(p_max)
  if (!is.finite(T) || !is.finite(m) || !is.finite(p_max)) return(FALSE)
  # minimal heuristic: need enough obs for parameters in Δ VAR
  T > (m * m * max(p_max - 1L, 0L) + m)
}

# ------------------------------------------------------------------
# Logging helpers (debugging only)
# ------------------------------------------------------------------
now_stamp <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

log_line <- function(path, msg) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  cat(sprintf("[%s] %s\n", now_stamp(), msg), file = path, append = TRUE)
}

# ------------------------------------------------------------------
# Safe I/O helpers
# ------------------------------------------------------------------
safe_write_csv <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(df, path, row.names = FALSE)
}

safe_read_csv <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE)
}

# ============================================================
# CONSOLIDATED HELPERS (APPENDED) — TS-DYN GRID FREEZE LAYER
# ============================================================

# ------------------------------------------------------------
# Likelihood + Sigma extraction (tsDyn: VAR via lineVar, VECM via VECM/lineVar)
# ------------------------------------------------------------

# Safe numeric extraction of logLik from tsDyn objects.
# tsDyn defines logLik for VAR (nlVar) and VECM; for ML VECM it matches Johansen-style LL
# with the eigenvalue correction term (see tsDyn manual logLik.nlVar).
tsdyn_loglik <- function(fit, r_override = NULL) {
  .pkg("tsDyn")
  ll <- tryCatch(
    {
      if (!is.null(r_override)) {
        as.numeric(tsDyn::logLik(fit, r = as.integer(r_override)))
      } else {
        as.numeric(stats::logLik(fit))
      }
    },
    error = function(e) NA_real_
  )
  ll
}

# Residual covariance estimator used for likelihood components (explicit, not “df corrected”).
# NOTE: this is NOT claiming what tsDyn uses internally; it just makes Σ̂ definition explicit.
sigma_hat_ml <- function(resid_mat, T_eff = NULL) {
  U <- as.matrix(resid_mat)
  if (is.null(T_eff)) T_eff <- nrow(U)
  if (!is.finite(T_eff) || T_eff <= 0) stop("sigma_hat_ml: invalid T_eff", call. = FALSE)
  crossprod(U) / T_eff
}

# ------------------------------------------------------------
# r=0 fallback (Phillips-style Σ̂(0) comparator path)
# ------------------------------------------------------------

# Fit a VAR on first differences with tsDyn::lineVar (so the under-the-hood class and logLik
# method stay in the tsDyn ecosystem, as you requested).
#
# Intended as the r=0 comparator object when ML-VECM cannot compute r=0.
# Output: list(ok, fit, ll, Sigma0, T_eff, m, meta)
fit_sigma0_var_diff <- function(X_level, p_vecm, include = c("none","const","trend","both")) {
  .pkg("tsDyn")
  include <- match.arg(include)
  
  X_level <- as.matrix(X_level)
  if (nrow(X_level) < 5) return(list(ok = FALSE, fail_code = "T_TOO_SMALL", fail_msg = "Too few rows"))
  
  # Map p_vecm to VAR lag in differences.
  # Convention: VECM(p) has (p-1) lags in ΔX. For r=0 comparator we use the same ΔX lag depth.
  p_diff <- as.integer(p_vecm)
  if (!is.finite(p_diff) || p_diff < 1L) p_diff <- 1L
  
  fit <- tryCatch(
    {
      tsDyn::lineVar(
        data    = X_level,
        lag     = p_diff,
        include = include,
        model   = "VAR",
        I       = "diff"
      )
    },
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(list(ok = FALSE, fail_code = "R0_VAR_DIFF_FAIL", fail_msg = conditionMessage(fit)))
  }
  
  ll <- tsdyn_loglik(fit)
  U  <- tryCatch(stats::residuals(fit), error = function(e) NULL)
  if (is.null(U)) {
    return(list(ok = FALSE, fail_code = "R0_RESID_FAIL", fail_msg = "Could not extract residuals"))
  }
  
  U <- as.matrix(U)
  T_eff <- nrow(U)
  m <- ncol(U)
  Sigma0 <- tryCatch(sigma_hat_ml(U, T_eff = T_eff), error = function(e) NULL)
  if (is.null(Sigma0) || any(!is.finite(Sigma0))) {
    return(list(ok = FALSE, fail_code = "R0_SIGMA_FAIL", fail_msg = "Non-finite Sigma0"))
  }
  
  list(
    ok = TRUE,
    fit = fit,
    ll = ll,
    Sigma0 = Sigma0,
    T_eff = T_eff,
    m = m,
    meta = list(model = "VAR", I = "diff", p_diff = p_diff, include = include)
  )
}

# ------------------------------------------------------------
# Deterministic counts (for k_SR and k_LR accounting)
# ------------------------------------------------------------

# Convert deterministic tags to counts:
# det_tag ∈ {"none","const","trend","both"}
det_count <- function(det_tag = c("none","const","trend","both")) {
  det_tag <- match.arg(det_tag)
  switch(det_tag,
         none  = 0L,
         const = 1L,
         trend = 1L,
         both  = 2L)
}

# Frozen short-run penalty:
# k_SR = (p-1)m^2 + m d
k_sr <- function(p_vecm, m, DSR = c("none","const","trend","both")) {
  DSR <- match.arg(DSR)
  p_vecm <- as.integer(p_vecm)
  m <- as.integer(m)
  d <- det_count(DSR)
  (p_vecm - 1L) * (m^2) + m * d
}

# Long-run parameter count placeholder (transparent, editable later):
# Baseline reduced-rank count: r(2m - r) plus LR deterministics loading per relation.
k_lr <- function(r, m, DLR = c("none","const","trend","both")) {
  DLR <- match.arg(DLR)
  r <- as.integer(r); m <- as.integer(m)
  d_lr <- det_count(DLR)
  # α (m×r) + β (m×r) minus r^2 normalization ⇒ r(2m - r)
  r * (2L * m - r) + r * d_lr
}

k_total_rr <- function(p_vecm, r, m, DSR, DLR) {
  k_sr(p_vecm, m, DSR) + k_lr(r, m, DLR)
}

# ------------------------------------------------------------
# PIC components (engine plugs in exact Phillips–Chao formula)
# ------------------------------------------------------------

# Return IC components (do not hard-code a single scalar),
# so the engine can implement the exact frozen criterion upstream.
pic_components <- function(ll, T_eff, k_total, Cn = NA_real_, lr_dim = NA_real_) {
  core <- -2 * ll
  lag_pen <- k_total * log(T_eff)
  
  # Long-run penalty component (Phillips/Chao scaling differs by paper/version).
  lr_pen <- if (is.finite(Cn) && is.finite(lr_dim)) Cn * lr_dim else NA_real_
  
  list(
    core = core,
    lag_pen = lag_pen,
    lr_pen = lr_pen,
    PIC = core + lag_pen + ifelse(is.finite(lr_pen), lr_pen, 0)
  )
}

# ------------------------------------------------------------
# Diagnostics: structured failure capture
# ------------------------------------------------------------

truncate_msg <- function(x, n = 240L) {
  x <- as.character(x %||% "")
  if (nchar(x) <= n) x else paste0(substr(x, 1L, n), "…")
}

as_fail_record <- function(status = c("runtime_fail","infeasible","gate_fail"),
                           fail_code = "UNKNOWN",
                           fail_msg = "",
                           extra = list()) {
  status <- match.arg(status)
  c(
    list(
      status = status,
      fail_code = as.character(fail_code),
      fail_msg = truncate_msg(fail_msg, 240L)
    ),
    extra
  )
}


# ============================================================
# PATCH: det_pairs(CONFIG) — support list-of-pairs DET_PAIRS
# File: codes/99_tsdyn_utils.R
# ACTION: REPLACE existing det_pairs() with this version
# ============================================================

det_pairs <- function(CONFIG) {
  
  # helper: normalize column names for matching
  .norm_names <- function(nm) tolower(gsub("[^a-z0-9]+", "", nm))
  
  # helper: find first matching column among candidates
  .find_col <- function(df, candidates) {
    nm_raw <- names(df)
    nm_norm <- .norm_names(nm_raw)
    cand_norm <- .norm_names(candidates)
    idx <- match(cand_norm, nm_norm)
    idx <- idx[!is.na(idx)]
    if (length(idx) == 0) return(NULL)
    nm_raw[idx[1]]
  }
  
  # helper: coerce to valid tsDyn deterministic tags
  .coerce_det <- function(x) {
    x <- as.character(x %||% "none")
    x <- tolower(trimws(x))
    x[x %in% c("", "na", "null")] <- "none"
    x[x %in% c("c", "constant", "intercept")] <- "const"
    x[x %in% c("t", "time", "lineartrend")] <- "trend"
    x[x %in% c("ct", "tc", "consttrend", "trendconst")] <- "both"
    x[!(x %in% c("none","const","trend","both"))] <- "none"
    x
  }
  
  # ---- 1) explicit table/list provided by config
  if (!is.null(CONFIG$DET_PAIRS)) {
    
    # Case 1a: DET_PAIRS is a list of length-2 vectors (your config)
    if (is.list(CONFIG$DET_PAIRS) && length(CONFIG$DET_PAIRS) > 0) {
      ok_pair <- vapply(CONFIG$DET_PAIRS, function(z) is.character(z) && length(z) == 2, logical(1))
      if (all(ok_pair)) {
        mat <- do.call(rbind, CONFIG$DET_PAIRS)
        df <- data.frame(
          DSR = .coerce_det(mat[,1]),
          DLR = .coerce_det(mat[,2]),
          stringsAsFactors = FALSE
        )
        df$include   <- resolve_include(df$DSR)
        df$LRinclude <- resolve_LRinclude(df$DLR)
        df$det_tag   <- det_tag_from(df$include, df$LRinclude)
        rownames(df) <- NULL
        return(df[, c("DSR","DLR","det_tag","include","LRinclude"), drop = FALSE])
      }
      # If it's a list but not pairs, fall through to data.frame parsing
    }
    
    # Case 1b: DET_PAIRS is already a data.frame/tibble
    df <- as.data.frame(CONFIG$DET_PAIRS)
    
    # try to locate SR/LR deterministic columns under many names
    col_DSR <- .find_col(df, c("DSR","SR","include","sr","dsr","dsr_tag","sr_tag","det_sr"))
    col_DLR <- .find_col(df, c("DLR","LR","LRinclude","lrinclude","lr","dlr","dlr_tag","lr_tag","det_lr"))
    
    # If only one column exists, apply symmetrically (legacy convenience)
    if (is.null(col_DSR) && !is.null(col_DLR)) col_DSR <- col_DLR
    if (is.null(col_DLR) && !is.null(col_DSR)) col_DLR <- col_DSR
    
    if (is.null(col_DSR) || is.null(col_DLR)) {
      stop(
        sprintf(
          "CONFIG$DET_PAIRS exists but deterministic columns not recognized. Names found: %s",
          paste(names(df), collapse = ", ")
        ),
        call. = FALSE
      )
    }
    
    df$DSR <- .coerce_det(df[[col_DSR]])
    df$DLR <- .coerce_det(df[[col_DLR]])
    
    df$include   <- resolve_include(df$DSR)
    df$LRinclude <- resolve_LRinclude(df$DLR)
    
    col_det_tag <- .find_col(df, c("det_tag","dettag","tag","det"))
    if (!is.null(col_det_tag)) {
      df$det_tag <- as.character(df[[col_det_tag]])
    } else {
      df$det_tag <- det_tag_from(df$include, df$LRinclude)
    }
    
    keep <- c("DSR","DLR","det_tag","include","LRinclude")
    out <- df[, keep, drop = FALSE]
    rownames(out) <- NULL
    return(out)
  }
  
  # ---- 2) build from DSR_SET / DLR_SET
  DSR_SET <- CONFIG$DSR_SET %||% NULL
  DLR_SET <- CONFIG$DLR_SET %||% NULL
  
  if (!is.null(DSR_SET) && !is.null(DLR_SET)) {
    out <- expand.grid(DSR = as.character(DSR_SET), DLR = as.character(DLR_SET), stringsAsFactors = FALSE)
    out$DSR <- .coerce_det(out$DSR)
    out$DLR <- .coerce_det(out$DLR)
    out$include   <- resolve_include(out$DSR)
    out$LRinclude <- resolve_LRinclude(out$DLR)
    out$det_tag   <- det_tag_from(out$include, out$LRinclude)
    return(out)
  }
  
  # ---- 3) legacy DET_SET applied symmetrically
  DET_SET <- CONFIG$DET_SET %||% NULL
  if (!is.null(DET_SET)) {
    DET_SET <- as.character(DET_SET)
    out <- expand.grid(DSR = DET_SET, DLR = DET_SET, stringsAsFactors = FALSE)
    out$DSR <- .coerce_det(out$DSR)
    out$DLR <- .coerce_det(out$DLR)
    out$include   <- resolve_include(out$DSR)
    out$LRinclude <- resolve_LRinclude(out$DLR)
    out$det_tag   <- det_tag_from(out$include, out$LRinclude)
    return(out)
  }
  
  # ---- 4) conservative fallback
  out <- expand.grid(DSR = c("none","const"), DLR = c("none","const"), stringsAsFactors = FALSE)
  out$include   <- resolve_include(out$DSR)
  out$LRinclude <- resolve_LRinclude(out$DLR)
  out$det_tag   <- det_tag_from(out$include, out$LRinclude)
  out
}

# ============================================================
# PATCH: admissible_gate — make kappa diagnostic, not a hard gate
# File: codes/99_tsdyn_utils.R
# ACTION: REPLACE existing admissible_gate() with this version
# ============================================================

admissible_gate <- function(dfw, p, slack = 5, hard_kappa = 1e12, enforce_kappa = FALSE) {
  
  dfw <- as.matrix(dfw)
  p   <- as.integer(p)
  
  T_eff <- nrow(dfw)
  m     <- ncol(dfw)
  
  # 1) Hard gates: non-finite data
  if (any(!is.finite(dfw))) {
    return(list(
      ok = FALSE,
      msg = "non-finite entries in dfw",
      reason = "non_finite",
      diagnostics = list(T_eff = T_eff, m = m, p = p)
    ))
  }
  
  # 2) Hard gates: too small effective sample given (p,m)
  if ((T_eff - (p + 1L)) < slack * m) {
    return(list(
      ok = FALSE,
      msg = "T too small given (p,m)",
      reason = "T_too_small",
      diagnostics = list(T_eff = T_eff, m = m, p = p, slack = slack)
    ))
  }
  
  # 3) Covariance diagnostics (NOT a hard gate unless enforce_kappa=TRUE)
  S <- try(stats::cov(dfw), silent = TRUE)
  if (inherits(S, "try-error") || any(!is.finite(S))) {
    # This one *is* meaningful: if cov can't be formed, estimation will almost surely fail.
    return(list(
      ok = FALSE,
      msg = "cov(dfw) failed / non-finite",
      reason = "cov_fail",
      diagnostics = list(T_eff = T_eff, m = m, p = p)
    ))
  }
  
  kap_raw <- try(kappa(S), silent = TRUE)
  kap_raw <- if (inherits(kap_raw, "try-error")) NA_real_ else as.numeric(kap_raw)
  
  # scaled covariance (less silly for trending/scale issues)
  kap_scaled <- try(kappa(stats::cov(scale(dfw))), silent = TRUE)
  kap_scaled <- if (inherits(kap_scaled, "try-error")) NA_real_ else as.numeric(kap_scaled)
  
  reason <- "ok"
  msg    <- "ok"
  ok     <- TRUE
  
  # Only gate if you explicitly demand it
  kap_to_use <- kap_scaled
  if (is.finite(kap_to_use) && kap_to_use > hard_kappa) {
    reason <- "kappa_high"
    msg    <- sprintf("kappa(scale(cov)) too large: %.3e (diagnostic)", kap_to_use)
    ok     <- !isTRUE(enforce_kappa)
  }
  
  list(
    ok = ok,
    msg = msg,
    reason = reason,
    diagnostics = list(
      T_eff = T_eff, m = m, p = p,
      kappa_raw = kap_raw,
      kappa_scaled = kap_scaled,
      hard_kappa = hard_kappa,
      enforce_kappa = enforce_kappa
    )
  )
}


############################################################
# 99_tsdyn_utils.R — Utilities for tsDyn migration branch
#
# This file collects helper functions used by the tsDyn‐based
# diagnostics and inference scripts.  Functions are kept
# self‐contained and depend only on base R and the packages
# specified in DESCRIPTION.  They cover lag mapping, deterministic
# specification handling, orthogonal polynomial basis construction,
# state matrix construction, admissibility checks, logging, and
#
# NOTE (2026-02-23): consolidated helper layer appended at end:
#   - tsDyn ML logLik extraction
#   - explicit Σ̂ and log|Σ̂|
#   - r=0 comparator via lineVar(VAR, I="diff") + Σ̂(0)
#   - frozen k_SR / k_LR helpers and PIC components
#
############################################################

# --------------------------
# ORIGINAL CONTENT (unchanged)
# --------------------------

`%||%` <- function(x, y) if (is.null(x)) y else x

.pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf("Package '%s' is required but not installed.", pkg), call. = FALSE)
  }
  invisible(TRUE)
}

# ------------------------------------------------------------------
# Deterministic spec helpers
# ------------------------------------------------------------------
# tsDyn arguments:
#   include   ∈ {"const","trend","none","both"}    (short-run)
#   LRinclude ∈ {"none","const","trend","both"}    (long-run)
#
# Your project tags:
#   det_tag ∈ {"none","const","trend","both"} but split across DSR/DLR
#
# These helpers keep mappings explicit and consistent.



# ============================================================
# PATCH: vectorize resolve_include / resolve_LRinclude
# File: codes/99_tsdyn_utils.R
# ACTION: REPLACE existing resolve_include() and resolve_LRinclude()
# ============================================================

resolve_include <- function(DSR) {
  DSR <- as.character(DSR %||% "none")
  DSR <- tolower(trimws(DSR))
  allowed <- c("none","const","trend","both")
  DSR[is.na(DSR) | DSR == "" | !(DSR %in% allowed)] <- "none"
  DSR
}

resolve_LRinclude <- function(DLR) {
  DLR <- as.character(DLR %||% "none")
  DLR <- tolower(trimws(DLR))
  allowed <- c("none","const","trend","both")
  DLR[is.na(DLR) | DLR == "" | !(DLR %in% allowed)] <- "none"
  DLR
}


det_tag_from <- function(include, LRinclude) {
  paste0("SR_", include, "__LR_", LRinclude)
}

# ------------------------------------------------------------------
# Lag mapping (legacy utilities used in migration)
# ------------------------------------------------------------------
# IMPORTANT:
# tsDyn defines VECM lag in terms of ΔX lags, not VAR levels lags.
# Documentation reminder: "a VAR with 2 lags corresponds here to a VECM with 1 lag".
# Keep your grid definition explicit in engine; these are helpers only.

vecm_lag_to_var_levels_lag <- function(lag_vecm) {
  as.integer(lag_vecm) + 1L
}

var_levels_lag_to_vecm_lag <- function(lag_var_levels) {
  as.integer(lag_var_levels) - 1L
}

# ------------------------------------------------------------------
# Orthogonal polynomial basis helpers (QR rotation)
# ------------------------------------------------------------------
# Used to rotate polynomial blocks e, e^2, e logK, e^2 logK into an orthogonal basis
# while preserving invertibility (rank invariance).

qr_ortho_basis <- function(M) {
  M <- as.matrix(M)
  if (ncol(M) == 0L) return(M)
  q <- qr.Q(qr(M))
  colnames(q) <- paste0("Q", seq_len(ncol(q)))
  q
}

# ------------------------------------------------------------------
# State construction helpers
# ------------------------------------------------------------------
make_state_matrix <- function(df, vars) {
  out <- df[, vars, drop = FALSE]
  out <- as.matrix(out)
  storage.mode(out) <- "double"
  out
}

# ------------------------------------------------------------------
# Admissibility / gate checks (lightweight)
# ------------------------------------------------------------------
# Keep these conservative; do not treat runtime as a pass/fail gate.

gate_check_min_T <- function(T, m, p_max) {
  T <- as.integer(T); m <- as.integer(m); p_max <- as.integer(p_max)
  if (!is.finite(T) || !is.finite(m) || !is.finite(p_max)) return(FALSE)
  # minimal heuristic: need enough obs for parameters in Δ VAR
  T > (m * m * max(p_max - 1L, 0L) + m)
}

# ------------------------------------------------------------------
# Logging helpers (debugging only)
# ------------------------------------------------------------------
now_stamp <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

log_line <- function(path, msg) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  cat(sprintf("[%s] %s\n", now_stamp(), msg), file = path, append = TRUE)
}

# ------------------------------------------------------------------
# Safe I/O helpers
# ------------------------------------------------------------------
safe_write_csv <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(df, path, row.names = FALSE)
}

safe_read_csv <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE)
}

# ============================================================
# CONSOLIDATED HELPERS (APPENDED) — TS-DYN GRID FREEZE LAYER
# ============================================================

# ------------------------------------------------------------
# Likelihood + Sigma extraction (tsDyn: VAR via lineVar, VECM via VECM/lineVar)
# ------------------------------------------------------------

# Safe numeric extraction of logLik from tsDyn objects.
# tsDyn defines logLik for VAR (nlVar) and VECM; for ML VECM it matches Johansen-style LL
# with the eigenvalue correction term (see tsDyn manual logLik.nlVar).
tsdyn_loglik <- function(fit, r_override = NULL) {
  .pkg("tsDyn")
  ll <- tryCatch(
    {
      if (!is.null(r_override)) {
        as.numeric(tsDyn::logLik(fit, r = as.integer(r_override)))
      } else {
        as.numeric(stats::logLik(fit))
      }
    },
    error = function(e) NA_real_
  )
  ll
}

# Residual covariance estimator used for likelihood components (explicit, not “df corrected”).
# NOTE: this is NOT claiming what tsDyn uses internally; it just makes Σ̂ definition explicit.
sigma_hat_ml <- function(resid_mat, T_eff = NULL) {
  U <- as.matrix(resid_mat)
  if (is.null(T_eff)) T_eff <- nrow(U)
  if (!is.finite(T_eff) || T_eff <= 0) stop("sigma_hat_ml: invalid T_eff", call. = FALSE)
  crossprod(U) / T_eff
}

# ------------------------------------------------------------
# r=0 fallback (Phillips-style Σ̂(0) comparator path)
# ------------------------------------------------------------

# Fit a VAR on first differences with tsDyn::lineVar (so the under-the-hood class and logLik
# method stay in the tsDyn ecosystem, as you requested).
#
# Intended as the r=0 comparator object when ML-VECM cannot compute r=0.
# Output: list(ok, fit, ll, Sigma0, T_eff, m, meta)
fit_sigma0_var_diff <- function(X_level, p_vecm, include = c("none","const","trend","both")) {
  .pkg("tsDyn")
  include <- match.arg(include)
  
  X_level <- as.matrix(X_level)
  if (nrow(X_level) < 5) return(list(ok = FALSE, fail_code = "T_TOO_SMALL", fail_msg = "Too few rows"))
  
  # Map p_vecm to VAR lag in differences.
  # Convention: VECM(p) has (p-1) lags in ΔX. For r=0 comparator we use the same ΔX lag depth.
  p_diff <- as.integer(p_vecm)
  if (!is.finite(p_diff) || p_diff < 1L) p_diff <- 1L
  
  fit <- tryCatch(
    {
      tsDyn::lineVar(
        data    = X_level,
        lag     = p_diff,
        include = include,
        model   = "VAR",
        I       = "diff"
      )
    },
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(list(ok = FALSE, fail_code = "R0_VAR_DIFF_FAIL", fail_msg = conditionMessage(fit)))
  }
  
  ll <- tsdyn_loglik(fit)
  U  <- tryCatch(stats::residuals(fit), error = function(e) NULL)
  if (is.null(U)) {
    return(list(ok = FALSE, fail_code = "R0_RESID_FAIL", fail_msg = "Could not extract residuals"))
  }
  
  U <- as.matrix(U)
  T_eff <- nrow(U)
  m <- ncol(U)
  Sigma0 <- tryCatch(sigma_hat_ml(U, T_eff = T_eff), error = function(e) NULL)
  if (is.null(Sigma0) || any(!is.finite(Sigma0))) {
    return(list(ok = FALSE, fail_code = "R0_SIGMA_FAIL", fail_msg = "Non-finite Sigma0"))
  }
  
  list(
    ok = TRUE,
    fit = fit,
    ll = ll,
    Sigma0 = Sigma0,
    T_eff = T_eff,
    m = m,
    meta = list(model = "VAR", I = "diff", p_diff = p_diff, include = include)
  )
}

# ------------------------------------------------------------
# Deterministic counts (for k_SR and k_LR accounting)
# ------------------------------------------------------------

# Convert deterministic tags to counts:
# det_tag ∈ {"none","const","trend","both"}
det_count <- function(det_tag = c("none","const","trend","both")) {
  det_tag <- match.arg(det_tag)
  switch(det_tag,
         none  = 0L,
         const = 1L,
         trend = 1L,
         both  = 2L)
}

# Frozen short-run penalty:
# k_SR = (p-1)m^2 + m d
k_sr <- function(p_vecm, m, DSR = c("none","const","trend","both")) {
  DSR <- match.arg(DSR)
  p_vecm <- as.integer(p_vecm)
  m <- as.integer(m)
  d <- det_count(DSR)
  (p_vecm - 1L) * (m^2) + m * d
}

# Long-run parameter count placeholder (transparent, editable later):
# Baseline reduced-rank count: r(2m - r) plus LR deterministics loading per relation.
k_lr <- function(r, m, DLR = c("none","const","trend","both")) {
  DLR <- match.arg(DLR)
  r <- as.integer(r); m <- as.integer(m)
  d_lr <- det_count(DLR)
  # α (m×r) + β (m×r) minus r^2 normalization ⇒ r(2m - r)
  r * (2L * m - r) + r * d_lr
}

k_total_rr <- function(p_vecm, r, m, DSR, DLR) {
  k_sr(p_vecm, m, DSR) + k_lr(r, m, DLR)
}

# ------------------------------------------------------------
# PIC components (engine plugs in exact Phillips–Chao formula)
# ------------------------------------------------------------

# Return IC components (do not hard-code a single scalar),
# so the engine can implement the exact frozen criterion upstream.
pic_components <- function(ll, T_eff, k_total, Cn = NA_real_, lr_dim = NA_real_) {
  core <- -2 * ll
  lag_pen <- k_total * log(T_eff)
  
  # Long-run penalty component (Phillips/Chao scaling differs by paper/version).
  lr_pen <- if (is.finite(Cn) && is.finite(lr_dim)) Cn * lr_dim else NA_real_
  
  list(
    core = core,
    lag_pen = lag_pen,
    lr_pen = lr_pen,
    PIC = core + lag_pen + ifelse(is.finite(lr_pen), lr_pen, 0)
  )
}

# ------------------------------------------------------------
# Diagnostics: structured failure capture
# ------------------------------------------------------------

truncate_msg <- function(x, n = 240L) {
  x <- as.character(x %||% "")
  if (nchar(x) <= n) x else paste0(substr(x, 1L, n), "…")
}

as_fail_record <- function(status = c("runtime_fail","infeasible","gate_fail"),
                           fail_code = "UNKNOWN",
                           fail_msg = "",
                           extra = list()) {
  status <- match.arg(status)
  c(
    list(
      status = status,
      fail_code = as.character(fail_code),
      fail_msg = truncate_msg(fail_msg, 240L)
    ),
    extra
  )
}


# ============================================================
# PATCH: det_pairs(CONFIG) — support list-of-pairs DET_PAIRS
# File: codes/99_tsdyn_utils.R
# ACTION: REPLACE existing det_pairs() with this version
# ============================================================

det_pairs <- function(CONFIG) {
  
  # helper: normalize column names for matching
  .norm_names <- function(nm) tolower(gsub("[^a-z0-9]+", "", nm))
  
  # helper: find first matching column among candidates
  .find_col <- function(df, candidates) {
    nm_raw <- names(df)
    nm_norm <- .norm_names(nm_raw)
    cand_norm <- .norm_names(candidates)
    idx <- match(cand_norm, nm_norm)
    idx <- idx[!is.na(idx)]
    if (length(idx) == 0) return(NULL)
    nm_raw[idx[1]]
  }
  
  # helper: coerce to valid tsDyn deterministic tags
  .coerce_det <- function(x) {
    x <- as.character(x %||% "none")
    x <- tolower(trimws(x))
    x[x %in% c("", "na", "null")] <- "none"
    x[x %in% c("c", "constant", "intercept")] <- "const"
    x[x %in% c("t", "time", "lineartrend")] <- "trend"
    x[x %in% c("ct", "tc", "consttrend", "trendconst")] <- "both"
    x[!(x %in% c("none","const","trend","both"))] <- "none"
    x
  }
  
  # ---- 1) explicit table/list provided by config
  if (!is.null(CONFIG$DET_PAIRS)) {
    
    # Case 1a: DET_PAIRS is a list of length-2 vectors (your config)
    if (is.list(CONFIG$DET_PAIRS) && length(CONFIG$DET_PAIRS) > 0) {
      ok_pair <- vapply(CONFIG$DET_PAIRS, function(z) is.character(z) && length(z) == 2, logical(1))
      if (all(ok_pair)) {
        mat <- do.call(rbind, CONFIG$DET_PAIRS)
        df <- data.frame(
          DSR = .coerce_det(mat[,1]),
          DLR = .coerce_det(mat[,2]),
          stringsAsFactors = FALSE
        )
        df$include   <- resolve_include(df$DSR)
        df$LRinclude <- resolve_LRinclude(df$DLR)
        df$det_tag   <- det_tag_from(df$include, df$LRinclude)
        rownames(df) <- NULL
        return(df[, c("DSR","DLR","det_tag","include","LRinclude"), drop = FALSE])
      }
      # If it's a list but not pairs, fall through to data.frame parsing
    }
    
    # Case 1b: DET_PAIRS is already a data.frame/tibble
    df <- as.data.frame(CONFIG$DET_PAIRS)
    
    # try to locate SR/LR deterministic columns under many names
    col_DSR <- .find_col(df, c("DSR","SR","include","sr","dsr","dsr_tag","sr_tag","det_sr"))
    col_DLR <- .find_col(df, c("DLR","LR","LRinclude","lrinclude","lr","dlr","dlr_tag","lr_tag","det_lr"))
    
    # If only one column exists, apply symmetrically (legacy convenience)
    if (is.null(col_DSR) && !is.null(col_DLR)) col_DSR <- col_DLR
    if (is.null(col_DLR) && !is.null(col_DSR)) col_DLR <- col_DSR
    
    if (is.null(col_DSR) || is.null(col_DLR)) {
      stop(
        sprintf(
          "CONFIG$DET_PAIRS exists but deterministic columns not recognized. Names found: %s",
          paste(names(df), collapse = ", ")
        ),
        call. = FALSE
      )
    }
    
    df$DSR <- .coerce_det(df[[col_DSR]])
    df$DLR <- .coerce_det(df[[col_DLR]])
    
    df$include   <- resolve_include(df$DSR)
    df$LRinclude <- resolve_LRinclude(df$DLR)
    
    col_det_tag <- .find_col(df, c("det_tag","dettag","tag","det"))
    if (!is.null(col_det_tag)) {
      df$det_tag <- as.character(df[[col_det_tag]])
    } else {
      df$det_tag <- det_tag_from(df$include, df$LRinclude)
    }
    
    keep <- c("DSR","DLR","det_tag","include","LRinclude")
    out <- df[, keep, drop = FALSE]
    rownames(out) <- NULL
    return(out)
  }
  
  # ---- 2) build from DSR_SET / DLR_SET
  DSR_SET <- CONFIG$DSR_SET %||% NULL
  DLR_SET <- CONFIG$DLR_SET %||% NULL
  
  if (!is.null(DSR_SET) && !is.null(DLR_SET)) {
    out <- expand.grid(DSR = as.character(DSR_SET), DLR = as.character(DLR_SET), stringsAsFactors = FALSE)
    out$DSR <- .coerce_det(out$DSR)
    out$DLR <- .coerce_det(out$DLR)
    out$include   <- resolve_include(out$DSR)
    out$LRinclude <- resolve_LRinclude(out$DLR)
    out$det_tag   <- det_tag_from(out$include, out$LRinclude)
    return(out)
  }
  
  # ---- 3) legacy DET_SET applied symmetrically
  DET_SET <- CONFIG$DET_SET %||% NULL
  if (!is.null(DET_SET)) {
    DET_SET <- as.character(DET_SET)
    out <- expand.grid(DSR = DET_SET, DLR = DET_SET, stringsAsFactors = FALSE)
    out$DSR <- .coerce_det(out$DSR)
    out$DLR <- .coerce_det(out$DLR)
    out$include   <- resolve_include(out$DSR)
    out$LRinclude <- resolve_LRinclude(out$DLR)
    out$det_tag   <- det_tag_from(out$include, out$LRinclude)
    return(out)
  }
  
  # ---- 4) conservative fallback
  out <- expand.grid(DSR = c("none","const"), DLR = c("none","const"), stringsAsFactors = FALSE)
  out$include   <- resolve_include(out$DSR)
  out$LRinclude <- resolve_LRinclude(out$DLR)
  out$det_tag   <- det_tag_from(out$include, out$LRinclude)
  out
}

# ============================================================
# PATCH: admissible_gate — make kappa diagnostic, not a hard gate
# File: codes/99_tsdyn_utils.R
# ACTION: REPLACE existing admissible_gate() with this version
# ============================================================

admissible_gate <- function(dfw, p, slack = 5, hard_kappa = 1e12, enforce_kappa = FALSE) {
  
  dfw <- as.matrix(dfw)
  p   <- as.integer(p)
  
  T_eff <- nrow(dfw)
  m     <- ncol(dfw)
  
  # 1) Hard gates: non-finite data
  if (any(!is.finite(dfw))) {
    return(list(
      ok = FALSE,
      msg = "non-finite entries in dfw",
      reason = "non_finite",
      diagnostics = list(T_eff = T_eff, m = m, p = p)
    ))
  }
  
  # 2) Hard gates: too small effective sample given (p,m)
  if ((T_eff - (p + 1L)) < slack * m) {
    return(list(
      ok = FALSE,
      msg = "T too small given (p,m)",
      reason = "T_too_small",
      diagnostics = list(T_eff = T_eff, m = m, p = p, slack = slack)
    ))
  }
  
  # 3) Covariance diagnostics (NOT a hard gate unless enforce_kappa=TRUE)
  S <- try(stats::cov(dfw), silent = TRUE)
  if (inherits(S, "try-error") || any(!is.finite(S))) {
    # This one *is* meaningful: if cov can't be formed, estimation will almost surely fail.
    return(list(
      ok = FALSE,
      msg = "cov(dfw) failed / non-finite",
      reason = "cov_fail",
      diagnostics = list(T_eff = T_eff, m = m, p = p)
    ))
  }
  
  kap_raw <- try(kappa(S), silent = TRUE)
  kap_raw <- if (inherits(kap_raw, "try-error")) NA_real_ else as.numeric(kap_raw)
  
  # scaled covariance (less silly for trending/scale issues)
  kap_scaled <- try(kappa(stats::cov(scale(dfw))), silent = TRUE)
  kap_scaled <- if (inherits(kap_scaled, "try-error")) NA_real_ else as.numeric(kap_scaled)
  
  reason <- "ok"
  msg    <- "ok"
  ok     <- TRUE
  
  # Only gate if you explicitly demand it
  kap_to_use <- kap_scaled
  if (is.finite(kap_to_use) && kap_to_use > hard_kappa) {
    reason <- "kappa_high"
    msg    <- sprintf("kappa(scale(cov)) too large: %.3e (diagnostic)", kap_to_use)
    ok     <- !isTRUE(enforce_kappa)
  }
  
  list(
    ok = ok,
    msg = msg,
    reason = reason,
    diagnostics = list(
      T_eff = T_eff, m = m, p = p,
      kappa_raw = kap_raw,
      kappa_scaled = kap_scaled,
      hard_kappa = hard_kappa,
      enforce_kappa = enforce_kappa
    )
  )
}

# ============================================================
#  Orthogonalization layer (NO standardization)
# ============================================================

basis_build_rawpowers_qr <- function(df, e_col = "e", degree = 2) {
  if (!(e_col %in% names(df))) stop("basis_build_rawpowers_qr: missing column ", e_col, call. = FALSE)
  
  e <- as.numeric(df[[e_col]])
  ok <- is.finite(e)
  e_ok <- e[ok]
  
  if (length(e_ok) < max(10, 5 * degree)) {
    stop("basis_build_rawpowers_qr: too few finite e values", call. = FALSE)
  }
  
  X <- sapply(seq_len(degree), function(j) e_ok^j)
  X <- as.matrix(X)
  colnames(X) <- paste0("P", seq_len(degree))
  
  qrX <- qr(X)
  R <- qr.R(qrX)
  
  if (any(!is.finite(R))) stop("basis_build_rawpowers_qr: non-finite R", call. = FALSE)
  if (any(abs(diag(R)) < 1e-12)) stop("basis_build_rawpowers_qr: R nearly singular", call. = FALSE)
  
  A <- solve(R) # so that Q = X %*% A (up to QR convention)
  
  list(
    type = "rawpowers_qr",
    e_col = e_col,
    degree = degree,
    A = A,
    R = R,
    colnames_raw = colnames(X),
    n_full = nrow(X)
  )
}

basis_apply_rawpowers_qr <- function(df, basis, prefix = "Q") {
  if (!(basis$e_col %in% names(df))) stop("basis_apply_rawpowers_qr: missing e column ", basis$e_col, call. = FALSE)
  e <- as.numeric(df[[basis$e_col]])
  
  X <- sapply(seq_len(basis$degree), function(j) e^j)
  X <- as.matrix(X)
  
  Q <- X %*% basis$A
  colnames(Q) <- paste0(prefix, seq_len(basis$degree))
  
  out <- df
  for (j in seq_len(basis$degree)) out[[colnames(Q)[j]]] <- Q[, j]
  out
}

basis_apply_rawpowers <- function(df, e_col = "e", degree = 2, prefix = "Q") {
  if (!(e_col %in% names(df))) stop("basis_apply_rawpowers: missing e column ", e_col, call. = FALSE)
  e <- as.numeric(df[[e_col]])
  out <- df
  for (j in seq_len(degree)) out[[paste0(prefix, j)]] <- e^j
  out
}

tsdyn_loglik_safe <- function(fit, T_eff, m) {
  # 1) Try logLik method
  ll <- tryCatch(as.numeric(stats::logLik(fit)), error = function(e) NA_real_)
  if (is.finite(ll)) return(ll)
  
  # 2) Fallback from residual covariance
  U <- tryCatch(stats::residuals(fit), error = function(e) NULL)
  if (is.null(U)) return(NA_real_)
  U <- as.matrix(U)
  if (nrow(U) <= 0 || ncol(U) != m) return(NA_real_)
  
  # use actual residual length, not the guessed bookkeeping T_eff
  T_eff_use <- nrow(U)
  if (!is.finite(T_eff_use) || T_eff_use <= 0) return(NA_real_)
  
  S <- crossprod(U) / as.numeric(T_eff_use)
  
  dS <- tryCatch(as.numeric(det(S)), error = function(e) NA_real_)
  if (!is.finite(dS) || dS <= 0) return(NA_real_)
  
  -0.5 * as.numeric(T_eff_use) * (m * log(2*pi) + log(dS) + m)
}

tsdyn_loglik_safe2 <- function(fit, m) {
  ll <- tryCatch(as.numeric(stats::logLik(fit)), error=function(e) NA_real_)
  if (is.finite(ll)) return(list(ll=ll, reason="ok:stats_logLik"))
  
  U <- tryCatch(residuals(fit), error=function(e) NULL)
  if (is.null(U)) return(list(ll=NA_real_, reason="fail:no_residuals"))
  U <- as.matrix(U)
  if (ncol(U) != m) return(list(ll=NA_real_, reason="fail:resid_dim"))
  T_eff_use <- nrow(U)
  if (T_eff_use <= 0) return(list(ll=NA_real_, reason="fail:T_eff<=0"))
  
  S <- crossprod(U) / as.numeric(T_eff_use)
  
  dS <- tryCatch(as.numeric(det(S)), error=function(e) NA_real_)
  if (!is.finite(dS)) return(list(ll=NA_real_, reason="fail:det_na"))
  if (dS <= 0) return(list(ll=NA_real_, reason="fail:Sigma_not_PD"))
  
  ll2 <- -0.5 * T_eff_use * (m*log(2*pi) + log(dS) + m)
  if (!is.finite(ll2)) return(list(ll=NA_real_, reason="fail:ll_nonfinite"))
  list(ll=ll2, reason="ok:resid_Sigma")
}