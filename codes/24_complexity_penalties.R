# ============================================================
# 24_complexity_penalties.R
# Reusable complexity-penalty helpers for Critical Replication
#
# Criterion spec (world-aware audit notes)
# - C1(Sigma) = (k/2) * log(tr(Sigma)/k) - (1/2) * log|Sigma|, k = dim(Sigma)
# - ICOMP    = -2*logLik + 2*C1(Sigma)
# - RICOMP   = 2*sum_i rho(t_i) + 2*C1(Sigma_R)
#
# This module computes COMPLEXITY components only (2*C1):
# - ICOMP_pen  := 2*C1(Sigma)
# - RICOMP_pen := 2*C1(Sigma_R) proxy when robust fit term is unavailable
#
# Robust-fit term 2*sum rho(t_i) is NOT computed here. Callers must provide it
# separately for full RICOMP model selection.
# ============================================================

sanitize_vcov <- function(vcov_mat, eps = 1e-10) {
  M <- suppressWarnings(as.matrix(vcov_mat))

  if (length(M) == 0 || !is.matrix(M) || nrow(M) != ncol(M)) {
    return(list(ok = FALSE, mat = NA, flag = "invalid_vcov_shape", stabilized = FALSE))
  }

  if (any(!is.finite(M))) {
    return(list(ok = FALSE, mat = NA, flag = "non_finite_vcov", stabilized = FALSE))
  }

  M <- (M + t(M)) / 2

  ev <- tryCatch(eigen(M, symmetric = TRUE, only.values = TRUE)$values,
                 error = function(e) NA_real_)

  if (all(is.finite(ev)) && min(ev) > eps) {
    return(list(ok = TRUE, mat = M, flag = "ok", stabilized = FALSE))
  }

  ridge <- if (all(is.finite(ev))) max(eps, eps - min(ev) + eps) else eps
  M_stab <- M + diag(ridge, nrow(M))

  ev2 <- tryCatch(eigen(M_stab, symmetric = TRUE, only.values = TRUE)$values,
                  error = function(e) NA_real_)

  if (all(is.finite(ev2)) && min(ev2) > 0) {
    return(list(ok = TRUE, mat = M_stab, flag = "ridge_stabilized", stabilized = TRUE))
  }

  list(ok = FALSE, mat = M_stab, flag = "stabilization_failed", stabilized = TRUE)
}

stable_logdet <- function(M) {
  chol_try <- tryCatch(chol(M), error = function(e) NULL)
  if (!is.null(chol_try)) {
    return(2 * sum(log(diag(chol_try))))
  }

  ev <- tryCatch(eigen(M, symmetric = TRUE, only.values = TRUE)$values,
                 error = function(e) NA_real_)
  if (!all(is.finite(ev)) || any(ev <= 0)) return(NA_real_)
  sum(log(ev))
}

compute_c1_core <- function(vcov_mat, eps = 1e-10) {
  vc <- sanitize_vcov(vcov_mat, eps = eps)
  if (!isTRUE(vc$ok)) {
    return(list(C1 = NA_real_, k = NA_integer_, flag = vc$flag, stabilized = vc$stabilized))
  }

  k <- as.integer(nrow(vc$mat))
  trS <- sum(diag(vc$mat))
  logdetS <- stable_logdet(vc$mat)

  if (!is.finite(trS) || trS <= 0 || !is.finite(logdetS)) {
    return(list(C1 = NA_real_, k = k, flag = "c1_inputs_invalid", stabilized = vc$stabilized))
  }

  C1 <- (k / 2) * log(trS / k) - 0.5 * logdetS

  list(C1 = as.numeric(C1), k = k, flag = vc$flag, stabilized = vc$stabilized)
}

compute_icomp_penalty <- function(vcov_mat, eps = 1e-10) {
  c1 <- compute_c1_core(vcov_mat = vcov_mat, eps = eps)

  if (!is.finite(c1$C1)) {
    return(list(ICOMP_pen = NA_real_, ICOMP_flag = c1$flag, ICOMP_stabilized = c1$stabilized, ICOMP_k_sigma = c1$k))
  }

  list(
    ICOMP_pen = 2 * c1$C1,
    ICOMP_flag = c1$flag,
    ICOMP_stabilized = c1$stabilized,
    ICOMP_k_sigma = c1$k
  )
}

compute_ricomp_penalty <- function(vcov_mat, eps = 1e-10) {
  c1 <- compute_c1_core(vcov_mat = vcov_mat, eps = eps)

  if (!is.finite(c1$C1)) {
    return(list(RICOMP_pen = NA_real_, RICOMP_flag = c1$flag, RICOMP_stabilized = c1$stabilized, RICOMP_k_sigma = c1$k))
  }

  list(
    RICOMP_pen = 2 * c1$C1,
    RICOMP_flag = "complexity_component_only_requires_robust_fit_term",
    RICOMP_stabilized = c1$stabilized,
    RICOMP_k_sigma = c1$k
  )
}

compute_complexity_record <- function(model_class, logLik, k_total, vcov_mat, T_eff, extra = list()) {
  icomp <- compute_icomp_penalty(vcov_mat = vcov_mat)
  ricomp <- compute_ricomp_penalty(vcov_mat = vcov_mat)

  row <- list(
    model_class = as.character(model_class),
    logLik = as.numeric(logLik),
    k_total = as.numeric(k_total),
    ICOMP_pen = icomp$ICOMP_pen,
    RICOMP_pen = ricomp$RICOMP_pen,
    ICOMP_flag = icomp$ICOMP_flag,
    RICOMP_flag = ricomp$RICOMP_flag,
    ICOMP_stabilized = isTRUE(icomp$ICOMP_stabilized),
    RICOMP_stabilized = isTRUE(ricomp$RICOMP_stabilized),
    ICOMP_k_sigma = as.numeric(icomp$ICOMP_k_sigma),
    RICOMP_k_sigma = as.numeric(ricomp$RICOMP_k_sigma),
    ICOMP = if (is.finite(logLik) && is.finite(icomp$ICOMP_pen)) -2 * as.numeric(logLik) + icomp$ICOMP_pen else NA_real_,
    RICOMP = NA_real_,
    T_eff = as.numeric(T_eff)
  )

  if (length(extra) > 0) row <- c(row, extra)

  as.data.frame(row, stringsAsFactors = FALSE)
}
