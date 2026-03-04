############################################################
# 99_utils.R — Utilities (post-migration consolidated)
#
# Consolidation notes:
# - De-duplicated the file (your old version had the whole thing twice).
# - Made r=0 comparator consistent with FROZEN lag logic:
#     lineVar(..., lag = p_vecm, I="diff")   (NO (p-1) mapping)
# - Kept legacy mapping helpers, but they are informational only.
############################################################

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
# tsDyn args:
#   include   ∈ {"const","trend","none","both"}   (short-run)
#   LRinclude ∈ {"none","const","trend","both"}  (long-run)

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
# Lag mapping (legacy informational helpers)
# ------------------------------------------------------------------
# IMPORTANT: Engine logic is frozen elsewhere. These are NOT to be used
# to silently remap p. Keep them only if you want a reminder function.
vecm_lag_to_var_levels_lag <- function(lag_vecm) as.integer(lag_vecm) + 1L
var_levels_lag_to_vecm_lag <- function(lag_var_levels) as.integer(lag_var_levels) - 1L

# ------------------------------------------------------------------
# Orthogonal polynomial basis helpers (QR rotation)
# ------------------------------------------------------------------
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
# Lightweight gate check (non-binding heuristic)
# ------------------------------------------------------------------
gate_check_min_T <- function(T, m, p_max) {
  T <- as.integer(T); m <- as.integer(m); p_max <- as.integer(p_max)
  if (!is.finite(T) || !is.finite(m) || !is.finite(p_max)) return(FALSE)
  T > (m * m * max(p_max - 1L, 0L) + m)
}

# ------------------------------------------------------------------
# Logging helpers
# ------------------------------------------------------------------
now_stamp <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

log_line <- function(path, msg) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  cat(sprintf("[%s] %s\n", now_stamp(), msg), file = path, append = TRUE)
}

stage4_manifest_log_path <- function(file_name = "SPEC_FEASIBILITY_LOG.csv") {
  file.path("output", "CriticalReplication", "Manifest", "logs", file_name)
}

append_stage4_spec_log <- function(script_name,
                                   spec_key,
                                   status,
                                   reason_code,
                                   message,
                                   file_name = "SPEC_FEASIBILITY_LOG.csv") {
  path <- here::here(stage4_manifest_log_path(file_name))
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  row <- data.frame(
    timestamp = now_stamp(),
    script = as.character(script_name),
    spec_key = as.character(spec_key),
    status = as.character(status),
    reason_code = as.character(reason_code),
    message = truncate_msg(message, 240L),
    stringsAsFactors = FALSE
  )
  if (file.exists(path)) {
    old <- tryCatch(utils::read.csv(path, stringsAsFactors = FALSE), error = function(e) NULL)
    out <- if (is.null(old)) row else rbind(old, row)
    utils::write.csv(out, path, row.names = FALSE)
  } else {
    utils::write.csv(row, path, row.names = FALSE)
  }
  invisible(path)
}

preflight_vecm_spec <- function(include, LRinclude, p, T_window, m, r = NULL, min_te = 8L) {
  include <- resolve_include(include)
  LRinclude <- resolve_LRinclude(LRinclude)
  p <- as.integer(p)
  T_window <- as.integer(T_window)
  m <- as.integer(m)
  min_te <- as.integer(min_te)

  if (include == "const" && LRinclude %in% c("const", "both")) {
    return(list(ok = FALSE, status = "skipped_invalid_det", reason_code = "INVALID_DET_COMBO",
                message = sprintf("Invalid deterministic combo: SR=%s, LR=%s.", include, LRinclude)))
  }
  if (!is.null(r) && (as.integer(r) < 0L || as.integer(r) > (m - 1L))) {
    return(list(ok = FALSE, status = "infeasible", reason_code = "RANK_OUT_OF_RANGE",
                message = sprintf("Rank r=%s outside [0,%s].", as.integer(r), m - 1L)))
  }

  Te <- T_window - (p + 1L)
  if (!is.finite(Te) || Te < min_te) {
    return(list(ok = FALSE, status = "infeasible", reason_code = "INSUFFICIENT_EFFECTIVE_SAMPLE",
                message = sprintf("T_eff=%s below min_te=%s for p=%s.", Te, min_te, p)))
  }

  list(ok = TRUE, status = "computable", reason_code = "OK", message = "Spec passes preflight feasibility checks.")
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
# Likelihood + Sigma extraction
# ============================================================

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

sigma_hat_ml <- function(resid_mat, T_eff = NULL) {
  U <- as.matrix(resid_mat)
  if (is.null(T_eff)) T_eff <- nrow(U)
  if (!is.finite(T_eff) || T_eff <= 0) stop("sigma_hat_ml: invalid T_eff", call. = FALSE)
  crossprod(U) / T_eff
}

# ============================================================
# r=0 comparator (FROZEN lag logic)
#   Use tsDyn::lineVar(model="VAR", I="diff", lag=p_vecm)
# ============================================================

fit_sigma0_var_diff <- function(X_level, p_vecm, include = c("none","const","trend","both")) {
  .pkg("tsDyn")
  include <- match.arg(include)
  
  X_level <- as.matrix(X_level)
  if (nrow(X_level) < 5) {
    return(list(ok = FALSE, fail_code = "T_TOO_SMALL", fail_msg = "Too few rows"))
  }
  
  p_diff <- as.integer(p_vecm)
  if (!is.finite(p_diff) || p_diff < 1L) p_diff <- 1L
  
  fit <- tryCatch(
    tsDyn::lineVar(
      data    = X_level,
      lag     = p_diff,
      include = include,
      model   = "VAR",
      I       = "diff"
    ),
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

# ============================================================
# Deterministic counts + (transparent) RR parameter counts
# ============================================================

det_count <- function(det_tag = c("none","const","trend","both")) {
  det_tag <- match.arg(det_tag)
  switch(det_tag,
         none  = 0L,
         const = 1L,
         trend = 1L,
         both  = 2L
  )
}

k_sr <- function(p_vecm, m, DSR = c("none","const","trend","both")) {
  DSR <- match.arg(DSR)
  p_vecm <- as.integer(p_vecm)
  m <- as.integer(m)
  d <- det_count(DSR)
  (p_vecm - 1L) * (m^2) + m * d
}

k_lr <- function(r, m, DLR = c("none","const","trend","both")) {
  DLR <- match.arg(DLR)
  r <- as.integer(r); m <- as.integer(m)
  d_lr <- det_count(DLR)
  r * (2L * m - r) + r * d_lr
}

k_total_rr <- function(p_vecm, r, m, DSR, DLR) {
  k_sr(p_vecm, m, DSR) + k_lr(r, m, DLR)
}

pic_components <- function(ll, T_eff, k_total, Cn = NA_real_, lr_dim = NA_real_) {
  core <- -2 * ll
  lag_pen <- k_total * log(T_eff)
  lr_pen <- if (is.finite(Cn) && is.finite(lr_dim)) Cn * lr_dim else NA_real_
  
  list(
    core = core,
    lag_pen = lag_pen,
    lr_pen = lr_pen,
    PIC = core + lag_pen + ifelse(is.finite(lr_pen), lr_pen, 0)
  )
}

# ============================================================
# Structured failure capture
# ============================================================

truncate_msg <- function(x, n = 240L) {
  x <- as.character(x %||% "")
  if (nchar(x) <= n) x else paste0(substr(x, 1L, n), "…")
}

as_fail_record <- function(status = c("runtime_fail","infeasible","gate_fail"),
                           fail_code = "UNKNOWN",
                           fail_msg = "",
                           extra = list()) {
  status <- match.arg(status)
  c(list(
    status = status,
    fail_code = as.character(fail_code),
    fail_msg = truncate_msg(fail_msg, 240L)
  ),
  extra
  )
}

# ============================================================
# Stage-4 geometry complexity row helper
# ============================================================

compute_complexity_record <- function(exercise,
                                      model_class,
                                      window,
                                      window_tag,
                                      window_start,
                                      window_end,
                                      p,
                                      r,
                                      logLik,
                                      k,
                                      ICOMP_pen,
                                      RICOMP_pen,
                                      AIC,
                                      BIC,
                                      HQ,
                                      AICc,
                                      SI_Y,
                                      s_K,
                                      notes = "",
                                      extra = list()) {
  row <- c(
    list(
      exercise = exercise,
      model_class = model_class,
      window = window,
      window_tag = window_tag,
      window_start = window_start,
      window_end = window_end,
      p = p,
      r = r,
      logLik = logLik,
      k = k,
      ICOMP_pen = ICOMP_pen,
      RICOMP_pen = RICOMP_pen,
      AIC = AIC,
      BIC = BIC,
      HQ = HQ,
      AICc = AICc,
      SI_Y = SI_Y,
      s_K = s_K,
      notes = notes
    ),
    extra
  )

  as.data.frame(row, stringsAsFactors = FALSE)
}

# ============================================================
# det_pairs(CONFIG) — supports list-of-pairs DET_PAIRS
# ============================================================

det_pairs <- function(CONFIG) {
  
  .norm_names <- function(nm) tolower(gsub("[^a-z0-9]+", "", nm))
  
  .find_col <- function(df, candidates) {
    nm_raw <- names(df)
    nm_norm <- .norm_names(nm_raw)
    cand_norm <- .norm_names(candidates)
    idx <- match(cand_norm, nm_norm)
    idx <- idx[!is.na(idx)]
    if (length(idx) == 0) return(NULL)
    nm_raw[idx[1]]
  }
  
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
  
  if (!is.null(CONFIG$DET_PAIRS)) {
    
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
    }
    
    df <- as.data.frame(CONFIG$DET_PAIRS)
    
    col_DSR <- .find_col(df, c("DSR","SR","include","sr","dsr","dsr_tag","sr_tag","det_sr"))
    col_DLR <- .find_col(df, c("DLR","LR","LRinclude","lrinclude","lr","dlr","dlr_tag","lr_tag","det_lr"))
    
    if (is.null(col_DSR) && !is.null(col_DLR)) col_DSR <- col_DLR
    if (is.null(col_DLR) && !is.null(col_DSR)) col_DLR <- col_DSR
    
    if (is.null(col_DSR) || is.null(col_DLR)) {
      stop(
        sprintf("CONFIG$DET_PAIRS exists but deterministic columns not recognized. Names found: %s",
                paste(names(df), collapse = ", ")),
        call. = FALSE
      )
    }
    
    df$DSR <- .coerce_det(df[[col_DSR]])
    df$DLR <- .coerce_det(df[[col_DLR]])
    
    df$include   <- resolve_include(df$DSR)
    df$LRinclude <- resolve_LRinclude(df$DLR)
    
    col_det_tag <- .find_col(df, c("det_tag","dettag","tag","det"))
    if (!is.null(col_det_tag)) df$det_tag <- as.character(df[[col_det_tag]])
    if (is.null(df$det_tag)) df$det_tag <- det_tag_from(df$include, df$LRinclude)
    
    keep <- c("DSR","DLR","det_tag","include","LRinclude")
    out <- df[, keep, drop = FALSE]
    rownames(out) <- NULL
    return(out)
  }
  
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
  
  out <- expand.grid(DSR = c("none","const"), DLR = c("none","const"), stringsAsFactors = FALSE)
  out$include   <- resolve_include(out$DSR)
  out$LRinclude <- resolve_LRinclude(out$DLR)
  out$det_tag   <- det_tag_from(out$include, out$LRinclude)
  out
}

# ============================================================
# admissible_gate — kappa is diagnostic unless enforce_kappa=TRUE
# ============================================================

admissible_gate <- function(dfw, p, slack = 5, hard_kappa = 1e12, enforce_kappa = FALSE) {
  
  dfw <- as.matrix(dfw)
  p   <- as.integer(p)
  
  T_eff <- nrow(dfw)
  m     <- ncol(dfw)
  
  if (any(!is.finite(dfw))) {
    return(list(
      ok = FALSE,
      msg = "non-finite entries in dfw",
      reason = "non_finite",
      diagnostics = list(T_eff = T_eff, m = m, p = p)
    ))
  }
  
  if ((T_eff - (p + 1L)) < slack * m) {
    return(list(
      ok = FALSE,
      msg = "T too small given (p,m)",
      reason = "T_too_small",
      diagnostics = list(T_eff = T_eff, m = m, p = p, slack = slack)
    ))
  }
  
  S <- try(stats::cov(dfw), silent = TRUE)
  if (inherits(S, "try-error") || any(!is.finite(S))) {
    return(list(
      ok = FALSE,
      msg = "cov(dfw) failed / non-finite",
      reason = "cov_fail",
      diagnostics = list(T_eff = T_eff, m = m, p = p)
    ))
  }
  
  kap_raw <- try(kappa(S), silent = TRUE)
  kap_raw <- if (inherits(kap_raw, "try-error")) NA_real_ else as.numeric(kap_raw)
  
  kap_scaled <- try(kappa(stats::cov(scale(dfw))), silent = TRUE)
  kap_scaled <- if (inherits(kap_scaled, "try-error")) NA_real_ else as.numeric(kap_scaled)
  
  reason <- "ok"
  msg    <- "ok"
  ok     <- TRUE
  
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
# Orthogonalization layer (NO standardization)
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
  
  A <- solve(R)  # Q = X %*% A (up to QR convention)
  
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

# ============================================================
# logLik fallbacks (kept, but prefer tsdyn_loglik())
# ============================================================

tsdyn_loglik_safe2 <- function(fit, m) {
  ll <- tryCatch(as.numeric(stats::logLik(fit)), error=function(e) NA_real_)
  if (is.finite(ll)) return(list(ll = ll, reason = "ok:stats_logLik"))
  
  U <- tryCatch(residuals(fit), error=function(e) NULL)
  if (is.null(U)) return(list(ll = NA_real_, reason = "fail:no_residuals"))
  U <- as.matrix(U)
  if (ncol(U) != m) return(list(ll = NA_real_, reason = "fail:resid_dim"))
  T_eff_use <- nrow(U)
  if (T_eff_use <= 0) return(list(ll = NA_real_, reason = "fail:T_eff<=0"))
  
  S <- crossprod(U) / as.numeric(T_eff_use)
  
  dS <- tryCatch(as.numeric(det(S)), error=function(e) NA_real_)
  if (!is.finite(dS)) return(list(ll = NA_real_, reason = "fail:det_na"))
  if (dS <= 0) return(list(ll = NA_real_, reason = "fail:Sigma_not_PD"))
  
  ll2 <- -0.5 * T_eff_use * (m * log(2*pi) + log(dS) + m)
  if (!is.finite(ll2)) return(list(ll = NA_real_, reason = "fail:ll_nonfinite"))
  list(ll = ll2, reason = "ok:resid_Sigma")
}



# ============================================================
# export table bundle  - table_as_is
# ============================================================
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
  if (!is.data.frame(data) && !is.matrix(data)) stop("data must be a data.frame or matrix.")
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

export_table_bundle <- function(tbl,
                                name,
                                tables_dir,
                                caption,
                                column_labels = NULL,
                                footnote = NULL,
                                manifest_hook = NULL) {
  
  csv_path <- file.path(tables_dir, paste0(name, ".csv"))
  tex_path <- file.path(tables_dir, paste0(name, ".tex"))
  
  readr::write_csv(tbl, csv_path)
  
  table_as_is(
    data = tbl,
    file_path = tex_path,
    column_labels = column_labels,
    caption = caption,
    format = "latex",
    footnote = footnote,
    manifest_hook = manifest_hook
  )
  
  invisible(list(csv = csv_path, tex = tex_path))
}
