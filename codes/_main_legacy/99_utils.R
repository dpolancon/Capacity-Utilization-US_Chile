############################################################
## 99_utils.R — Capacity Utilization / ChaoGrid Utilities
## SINK DISCIPLINE v2 (RStudio-safe)
##
## Core rule:
## - Enforce OUTPUT sink hygiene (these are under your control).
## - Do NOT fail on MESSAGE sinks (RStudio can keep “phantom” ones).
############################################################

# ============================================================
# S0. Package guards
# ============================================================
.pkg <- function(x) {
  if (!requireNamespace(x, quietly = TRUE)) {
    stop("Missing package '", x, "'. Install it before running.", call. = FALSE)
  }
  invisible(TRUE)
}

# ============================================================
# S1. Small helpers / hygiene
# ============================================================
`%||%` <- function(a, b) if (is.null(a)) b else a

ensure_dirs <- function(...) {
  paths <- unique(c(...))
  paths <- paths[!is.na(paths) & nzchar(paths)]
  invisible(lapply(paths, function(p) {
    if (!dir.exists(p)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
  }))
}

any_non_na <- function(x) {
  if (length(x) == 0) return(FALSE)
  any(!is.na(x))
}

set_seed_deterministic <- function(seed = 123456) {
  suppressWarnings(RNGkind(kind = "Mersenne-Twister", normal.kind = "Inversion"))
  set.seed(seed)
  invisible(TRUE)
}

# ============================================================
# SINK / LOG DISCIPLINE (LOCKED, RStudio-safe)
# ============================================================

sink_state <- function() {
  list(
    out = sink.number(type = "output"),
    msg = sink.number(type = "message"),
    rstudio = nzchar(Sys.getenv("RSTUDIO"))
  )
}

# Close OUTPUT sinks down to a target level (default: 0)
close_output_sinks_to <- function(target = 0L) {
  target <- as.integer(target)
  while (sink.number(type = "output") > target) {
    sink(NULL, type = "output")
  }
  invisible(TRUE)
}

# Try to close MESSAGE sinks down to a target level.
# In RStudio these can be sticky; never treat this as fatal.
close_message_sinks_to <- function(target = 0L) {
  target <- as.integer(target)
  while (sink.number(type = "message") > target) {
    ok <- try(sink(NULL, type = "message"), silent = TRUE)
    if (inherits(ok, "try-error")) break
    if (sink.number(type = "message") > target) break
  }
  invisible(TRUE)
}

reset_r_io <- function() {
  # Guarantee output is clean. Message sinks may be “sticky” in RStudio.
  close_output_sinks_to(0L)
  invisible(TRUE)
}

stop_if_output_sinks_open <- function(policy = c("stop","soft_close")) {
  policy <- match.arg(policy)
  n_out <- sink.number(type = "output")
  
  if (n_out == 0) return(invisible(TRUE))
  
  if (policy == "soft_close") {
    close_output_sinks_to(0L)
    return(invisible(TRUE))
  }
  
  stop(
    paste0(
      "\nSINK POLICY = stop\n",
      "Detected open OUTPUT sinks BEFORE engine start.\n",
      "sink.number(output) = ", n_out, "\n\n",
      "Fix: restart session OR manually close:\n",
      "  while(sink.number(type='output')>0) sink(NULL, type='output')\n"
    ),
    call. = FALSE
  )
}

open_log <- function(run_tag, config, dir_logs) {
  stopifnot(is.character(run_tag), length(run_tag) == 1)
  
  policy <- (config$SINK_POLICY %||% "stop")
  
  # Record baselines so we can return to them.
  base_out <- sink.number(type = "output")
  base_msg <- sink.number(type = "message")
  
  # Enforce only OUTPUT cleanliness (RStudio-safe).
  stop_if_output_sinks_open(policy = policy)
  
  if (!dir.exists(dir_logs)) dir.create(dir_logs, recursive = TRUE, showWarnings = FALSE)
  log_file <- file.path(dir_logs, paste0("engine_", run_tag, ".log"))
  
  # Sink OUTPUT only.
  sink(log_file, append = FALSE, split = TRUE, type = "output")
  
  close_log <- function() {
    # Return output sinks to baseline.
    close_output_sinks_to(base_out)
    
    # Don’t try to “fix” message sinks; just note if they changed.
    msg_now <- sink.number(type = "message")
    if (!identical(msg_now, base_msg)) {
      message(
        "NOTE: message sink count changed during run (baseline=", base_msg,
        ", now=", msg_now, "). RStudio may manage message sinks internally."
      )
    }
    invisible(TRUE)
  }
  
  attr(close_log, "log_file") <- log_file
  attr(close_log, "baseline_out") <- base_out
  attr(close_log, "baseline_msg") <- base_msg
  close_log
}

heartbeat <- function(i, n, run_tag, every = 25L) {
  every <- as.integer(every)
  if (!is.finite(every) || every < 1L) every <- 25L
  if (i %% every == 0L || i == 1L || i == n) {
    cat(sprintf("[HB] %s | %s | cell %d/%d\n",
                format(Sys.time(), "%H:%M:%S"), run_tag, i, n))
    flush.console()
  }
}

# ============================================================
# S2. Reporting utilities (tables / plots)
# ============================================================

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

# ============================================================
# S3. Admissibility / conditioning gates
# ============================================================

admissible_gate <- function(dfw, p, hard_kappa = 1e8, slack = 5) {
  T_eff <- nrow(dfw)
  m     <- ncol(dfw)
  
  if ((T_eff - (p + 1)) < slack * m) {
    return(list(ok = FALSE,
                reason = "T too small given (p,m)",
                diagnostics = list(T_eff = T_eff, m = m, p = p)))
  }
  
  S <- try(stats::cov(dfw), silent = TRUE)
  if (inherits(S, "try-error") || any(!is.finite(S))) {
    return(list(ok = FALSE,
                reason = "cov(dfw) failed / non-finite",
                diagnostics = list(T_eff = T_eff, m = m, p = p)))
  }
  
  kap <- try(kappa(S), silent = TRUE)
  if (!inherits(kap, "try-error") && is.finite(kap) && kap > hard_kappa) {
    return(list(ok = FALSE,
                reason = "ill-conditioned covariance (kappa too large)",
                diagnostics = list(kappa = kap, T_eff = T_eff, m = m, p = p)))
  }
  
  list(ok = TRUE, reason = "ok", diagnostics = list(kappa = kap, T_eff = T_eff, m = m, p = p))
}

# ============================================================
# S4. Orthogonalization layer (NO standardization)
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

# ============================================================
# S5. Johansen helpers: logLik + IC (used by Engine)
# ============================================================

loglik_from_cajorls <- function(jo_trace, r, m_expected = NULL) {
  .pkg("urca")
  fit <- tryCatch(urca::cajorls(jo_trace, r = r), error = function(e) e)
  if (inherits(fit, "error")) return(NA_real_)
  
  E <- tryCatch(as.matrix(fit$rlm$residuals), error = function(e) NULL)
  if (is.null(E) || nrow(E) < 5) return(NA_real_)
  
  m <- ncol(E)
  if (!is.null(m_expected) && m != m_expected) return(NA_real_)
  
  Teff <- nrow(E)
  S <- crossprod(E) / Teff
  
  ld <- tryCatch(as.numeric(determinant(S, logarithm = TRUE)$modulus), error = function(e) NA_real_)
  if (!is.finite(ld)) return(NA_real_)
  
  -0.5 * Teff * (m * log(2 * pi) + ld + m)
}

count_params_vecm <- function(m, p, r, ecdet) {
  k_alpha <- m * r
  k_beta  <- m * r
  k_gamma <- m * m * max(p - 1, 0)
  k_det   <- if (ecdet == "const") r else 0
  list(
    k_alpha = k_alpha, k_beta = k_beta, k_gamma = k_gamma, k_det = k_det,
    k_total = k_alpha + k_beta + k_gamma + k_det
  )
}

calc_ic <- function(loglik, T, k_total) {
  bic <- -2 * loglik + k_total * log(T)
  pic <- -2 * loglik + k_total * log(T) * log(log(T))
  list(PIC = pic, BIC = bic)
}