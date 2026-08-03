#!/usr/bin/env Rscript

# COMMON_cointegration_stability_tests.R
# ---------------------------------------------------------------------------
# Parameter-stability and regime-shift cointegration diagnostics for IM-OLS
# cointegrating regressions.
#
# Implements:
#   1. Hansen (1992) parameter instability triad: Lc, MeanF, SupF
#      ("Tests for Parameter Instability in Regressions with I(1) Processes",
#       Journal of Business & Economic Statistics 10(3), 321-335)
#      H0: cointegration with STABLE parameters.  H1: parameter instability.
#   2. Gregory & Hansen (1996) cointegration allowing an endogenous regime shift
#      ("Residual-based tests for cointegration in models with regime shifts",
#       Journal of Econometrics 70(1), 99-126)
#      H0: NO cointegration.  H1: cointegration with a break.
#   3. Bootstrap null-distribution machinery for both.
#
# ---------------------------------------------------------------------------
# DESIGN NOTE: why bootstrap rather than tabulated critical values
# ---------------------------------------------------------------------------
# The 2026-08-03 audit of the Section 3.1 report
# (chapter2_vault/08_audits/2026-08-03_section31_cointegration_stars_audit.md)
# found its headline defect was a correctly-computed statistic compared against
# hardcoded critical values that were not indexed to bandwidth or regressor
# count. The Gregory-Hansen implementation this module supersedes
# (CL_S20_structural_break_dual_route_audit.R) carries the same exposure
# (hardcoded -4.61/-4.99/-4.95). Rather than digitize two more critical-value
# tables and repeat the risk, every statistic here gets a bootstrapped null.
# This is also what the umass-applied-econometrics Rule I mandates.
#
# A useful consequence: bootstrap p-values are INVARIANT to any strictly
# monotone rescaling of the statistic, because the same transformation is
# applied to the observed value and to every replicate. So a normalization
# constant differing from Hansen's published one cannot corrupt inference --
# only a wrong functional FORM could. The form is validated separately; see
# `hansen_stability()`'s validation note.
#
# ---------------------------------------------------------------------------
# CRITICAL: the two test families have OPPOSITE nulls
# ---------------------------------------------------------------------------
# Their bootstrap DGPs are therefore different and MUST NOT be interchanged.
# Transposing them silently inverts every p-value.
#
#   Hansen / CUSUM   H0: cointegration + stable params
#                    -> resample STATIONARY residuals (moving block)
#                    -> `boot_null_stationary()`
#
#   Gregory-Hansen   H0: NO cointegration
#                    -> residuals follow a UNIT ROOT; cumulate resampled
#                       differences into a random walk
#                    -> `boot_null_unitroot()`
#
# `bootstrap_sanity_check()` at the bottom of this file exercises both against
# synthetic data with known answers; run it whenever this module is modified.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  if (!requireNamespace("cointReg", quietly = TRUE)) {
    stop("COMMON_cointegration_stability_tests.R requires the 'cointReg' package")
  }
})

# ---------------------------------------------------------------------------
# Robust matrix inverse: mirrors the repo convention of falling back rather
# than erroring on a near-singular design (step-dummy scores are zero before
# their break year, which can make the score covariance ill-conditioned).
# ---------------------------------------------------------------------------
.stab_solve <- function(M) {
  out <- tryCatch(solve(M), error = function(e) NULL)
  if (!is.null(out)) return(out)
  # Moore-Penrose fallback via SVD (avoids a hard MASS dependency)
  s <- svd(M)
  tol <- max(dim(M)) * .Machine$double.eps * max(s$d)
  pos <- s$d > tol
  if (!any(pos)) return(NULL)
  s$v[, pos, drop = FALSE] %*% ((1 / s$d[pos]) * t(s$u[, pos, drop = FALSE]))
}

# ---------------------------------------------------------------------------
# Multivariate Bartlett-kernel long-run covariance of the score process.
#   V = Gamma_0 + sum_{j=1..M} (1 - j/(M+1)) (Gamma_j + Gamma_j')
# `bandwidth` is M. Defaults to the Newey-West plug-in scale already selected
# by cointRegIM for the model, keeping the LRV consistent with the fixed-b
# framework used for the estimator's own inference.
# ---------------------------------------------------------------------------
.lrv_bartlett <- function(F_mat, bandwidth) {
  F_mat <- as.matrix(F_mat)
  T_obs <- nrow(F_mat)
  M <- max(0L, min(as.integer(floor(bandwidth)), T_obs - 1L))
  V <- crossprod(F_mat) / T_obs
  if (M >= 1L) {
    for (j in seq_len(M)) {
      w <- 1 - j / (M + 1)
      G <- crossprod(F_mat[(j + 1):T_obs, , drop = FALSE],
                     F_mat[1:(T_obs - j), , drop = FALSE]) / T_obs
      V <- V + w * (G + t(G))
    }
  }
  V
}

# ---------------------------------------------------------------------------
# hansen_stability(): Hansen (1992) Lc, MeanF, SupF
# ---------------------------------------------------------------------------
# X_full   : full regressor matrix INCLUDING deterministic terms (intercept,
#            step dummies) -- i.e. cbind(deter, X_mat), same column order as
#            the fitted coefficient vector.
# u        : cointegrating-regression residuals (IM-OLS u.plus).
# bandwidth: LRV bandwidth M (defaults to the model's fitted NW bandwidth).
# trim     : symmetric trimming fraction for the SupF/MeanF scan (Hansen uses
#            0.15, matching the repo's Bai-Perron convention).
# core_idx : column indices to include in the "core" joint statistic. Use this
#            to exclude step dummies so the joint test speaks to the
#            structural parameters (intercept, theta_0, theta_1, beta_cm)
#            rather than being dominated by dummy-score degeneracy.
#
# Returns Lc per parameter, joint Lc (all and core), MeanF, SupF and the
# argmax break index.
#
# VALIDATION (must hold; checked in US_S51 before any result is reported):
#   With X_full restricted to the intercept column, f_t = u_t, S_t = cumsum(u),
#   V = omega^2, hence
#         Lc_intercept  ==  T * C_Shin
#   where C_Shin = sum(S_t^2) / (T^2 * omega^2) is the Shin (1994) statistic
#   already computed in US_S50. Verified exactly (to machine precision) across
#   ALL 18 Section 3.1 models. This pins the functional form: Shin's C *is*
#   Hansen's Lc restricted to intercept-only parameter variation, which is also
#   why the report's 18/18 Shin rejection was already an (undecomposed)
#   instability signal.
#
#   LRV CAVEAT: that identity holds when both use the same long-run variance.
#   The Lc values this function REPORTS will not equal T*C_Shin numerically,
#   because `hansen_stability()` estimates the LRV from the score process with
#   a Bartlett kernel (Hansen's own formulation), whereas Shin uses cointReg's
#   CONDITIONAL long-run variance omega_{u.v} = omega_uu - omega_uv Omega_vv^-1
#   omega_vu. Both are defensible for their respective statistics; they differ
#   by roughly an order of magnitude on this data. Bootstrap inference is
#   unaffected, because the same LRV estimator is applied to the observed
#   statistic and to every replicate.
# ---------------------------------------------------------------------------
hansen_stability <- function(X_full, u, bandwidth, trim = 0.15, core_idx = NULL) {
  X_full <- as.matrix(X_full)
  u <- as.numeric(u)
  T_obs <- length(u)
  p <- ncol(X_full)
  nms <- colnames(X_full)
  if (is.null(nms)) nms <- paste0("p", seq_len(p))

  # Score contributions f_it = x_it * u_t ; cumulated S_t
  F_mat <- X_full * u
  S <- apply(F_mat, 2, cumsum)          # T x p
  S <- matrix(S, nrow = T_obs, ncol = p, dimnames = list(NULL, nms))

  V <- .lrv_bartlett(F_mat, bandwidth)
  dimnames(V) <- list(nms, nms)

  # --- per-parameter Lc (marginal): uses only the i-th score and V_ii ---
  Lc_by_param <- setNames(rep(NA_real_, p), nms)
  for (i in seq_len(p)) {
    if (is.finite(V[i, i]) && V[i, i] > 0) {
      Lc_by_param[i] <- sum(S[, i]^2) / (T_obs * V[i, i])
    }
  }

  # --- joint Lc over a set of columns ---
  joint_lc <- function(idx) {
    if (length(idx) == 0) return(NA_real_)
    Vi <- .stab_solve(V[idx, idx, drop = FALSE])
    if (is.null(Vi)) return(NA_real_)
    Ss <- S[, idx, drop = FALSE]
    sum(rowSums((Ss %*% Vi) * Ss)) / T_obs
  }
  Lc_all  <- joint_lc(seq_len(p))
  if (is.null(core_idx)) core_idx <- seq_len(p)
  # NOTE (2026-08-03): Lc_core inverts the SUBMATRIX V[core, core], which
  # ignores the covariance between core scores and the nuisance (step-dummy)
  # scores. Empirically this statistic is NOT self-normalizing -- iid and
  # AR-sieve nulls give materially different distributions (median 31.1 vs
  # 23.3 on M1.1), whereas Lc_all agrees closely across both (390.3 vs 384.6).
  # Lc_core is therefore retained for DESCRIPTIVE comparison only; use Lc_all
  # for inference. See E18_Parameter_Stability_Audit_Protocol_Lock.md.
  Lc_core <- joint_lc(core_idx)

  # --- SupF / MeanF over the tied-down (Brownian bridge) score process ---
  # B_t = S_t - (t/T) S_T ; F(t) = B_t' V^-1 B_t / [T * (t/T)(1 - t/T)]
  # Bootstrap inference makes the leading constant irrelevant (see header).
  idx <- core_idx
  Vi <- .stab_solve(V[idx, idx, drop = FALSE])
  SupF <- MeanF <- NA_real_; SupF_index <- NA_integer_
  if (!is.null(Vi)) {
    Ss <- S[, idx, drop = FALSE]
    S_T <- Ss[T_obs, ]
    tt <- seq_len(T_obs) / T_obs
    B <- Ss - outer(tt, S_T)
    quad <- rowSums((B %*% Vi) * B)
    denom <- T_obs * tt * (1 - tt)
    Fseq <- ifelse(denom > 0, quad / denom, NA_real_)
    lo <- max(1L, floor(trim * T_obs)); hi <- min(T_obs, ceiling((1 - trim) * T_obs))
    win <- lo:hi
    Fw <- Fseq[win]
    if (any(is.finite(Fw))) {
      SupF <- max(Fw, na.rm = TRUE)
      MeanF <- mean(Fw, na.rm = TRUE)
      SupF_index <- win[which.max(replace(Fw, !is.finite(Fw), -Inf))]
    }
  }

  list(
    Lc_by_param = Lc_by_param,
    Lc_all = Lc_all,
    Lc_core = Lc_core,
    MeanF = MeanF,
    SupF = SupF,
    SupF_index = SupF_index,
    V = V,
    T_obs = T_obs
  )
}

# ---------------------------------------------------------------------------
# Bootstrap resamplers
# ---------------------------------------------------------------------------
# Moving-block resample, preserving serial dependence within blocks. Block
# length defaults to the LRV bandwidth -- the data-driven scale at which serial
# dependence has already been estimated for this model. An iid resample would
# destroy exactly the dependence the Hansen/CUSUM statistics are normalized
# against, biasing the null.
moving_block_resample <- function(u, block_len) {
  T_obs <- length(u)
  L <- max(2L, min(as.integer(round(block_len)), floor(T_obs / 2)))
  n_blocks <- ceiling(T_obs / L)
  starts <- sample.int(T_obs - L + 1L, n_blocks, replace = TRUE)
  out <- unlist(lapply(starts, function(s) u[s:(s + L - 1L)]), use.names = FALSE)
  out[seq_len(T_obs)]
}

# H0: cointegration + stable parameters. Stationary residual resample.
boot_null_stationary <- function(fitted_vals, u, block_len) {
  fitted_vals + moving_block_resample(u, block_len)
}

# H0: NO cointegration. Residual carries a unit root: cumulate resampled
# first differences into a random walk. NOTE the deliberate asymmetry with
# boot_null_stationary() -- see the header warning.
boot_null_unitroot <- function(fitted_vals, u, block_len) {
  du <- diff(u)
  du_star <- moving_block_resample(du, block_len)
  u_star <- c(0, cumsum(du_star))
  fitted_vals + u_star[seq_along(fitted_vals)]
}

# ---------------------------------------------------------------------------
# Gregory & Hansen (1996) regime-shift cointegration
# ---------------------------------------------------------------------------
# Generalizes gh_design() from CL_S20_structural_break_dual_route_audit.R to a
# multi-regressor design. Kept OLS-residual based, faithful to GH (1996).
#   "level"  (C)   : intercept shift
#   "trend"  (C/T) : intercept shift + trend
#   "regime" (C/S) : intercept AND slope shift -- the specification that lets
#                    the COINTEGRATING VECTOR itself break. This is the one
#                    that matters for the Section 3.1 question.
# Statistic: min over the trimmed break scan of the ADF t-stat on the residual.
# ---------------------------------------------------------------------------
gh_design_matrix <- function(X, year, break_year, model) {
  X <- as.matrix(X)
  D <- as.integer(year >= break_year)
  if (model == "level")  return(cbind(X, D = D))
  if (model == "trend")  return(cbind(X, D = D, trend = as.numeric(year - min(year))))
  if (model == "regime") return(cbind(X, D = D, X * D))
  stop("gh_design_matrix: model must be one of 'level', 'trend', 'regime'")
}

# ---------------------------------------------------------------------------
# adf_t_augmented(): Engle-Granger residual ADF with AIC lag-order selection.
#
# The lag augmentation is NOT optional. The "A" in ADF exists to whiten
# serially correlated errors; running a plain Dickey-Fuller (p = 0) on
# autocorrelated residuals is severely biased toward NON-rejection. The
# Section 3.1 IM-OLS residuals carry AR(2)-AR(4) structure with first-order
# autocorrelation 0.81-0.96, and running them through an unaugmented DF is
# exactly what produced the report's spurious "no cointegration" verdict
# (2/18 rejections unaugmented vs 16/18 with AIC or BIC lag selection).
#
# The repo's pre-existing sbvecm_adf_stat / gh_design route in
# CL_S20_structural_break_dual_route_audit.R shares this defect; do not copy
# that convention forward.
#
# `ic`: "aic" or "bic". Both were checked on the Section 3.1 residuals and
# select the same lag order in 17 of 18 models.
# ---------------------------------------------------------------------------
adf_t_augmented <- function(u, max_lag = 8L, ic = c("aic", "bic")) {
  ic <- match.arg(ic)
  T_obs <- length(u)
  if (T_obs < 15) return(NA_real_)
  du <- diff(u); ul <- u[-T_obs]
  best_t <- NA_real_; best_ic <- Inf; best_p <- NA_integer_
  for (p in 0:max_lag) {
    n <- length(du) - p
    if (n < 12) next
    Y <- du[(p + 1):length(du)]
    Z <- matrix(ul[(p + 1):length(ul)], ncol = 1)
    if (p > 0) for (j in 1:p) Z <- cbind(Z, du[(p + 1 - j):(length(du) - j)])
    fit <- tryCatch(lm.fit(Z, Y), error = function(e) NULL)
    if (is.null(fit)) next
    r <- fit$residuals; k <- ncol(Z); dfree <- n - k
    if (dfree <= 0) next
    rss <- sum(r^2)
    if (!is.finite(rss) || rss <= 0) next
    pen <- if (ic == "aic") 2 * k else log(n) * k
    val <- n * log(rss / n) + pen
    XtXi <- tryCatch(solve(crossprod(Z)), error = function(e) NULL)
    if (is.null(XtXi)) next
    se <- sqrt((rss / dfree) * XtXi[1, 1])
    tstat <- fit$coefficients[1] / se
    if (is.finite(val) && is.finite(tstat) && val < best_ic) {
      best_ic <- val; best_t <- as.numeric(tstat); best_p <- p
    }
  }
  attr(best_t, "lag") <- best_p
  best_t
}

# Retained under the old name for call-site compatibility; now augmented.
.adf_t <- function(u, max_lag = 8L) as.numeric(adf_t_augmented(u, max_lag = max_lag))

gh_test <- function(y, X, year, model = "regime", trim = 0.15, max_lag = 4L) {
  T_obs <- length(y)
  lo <- max(2L, floor(trim * T_obs)); hi <- min(T_obs - 1L, ceiling((1 - trim) * T_obs))
  stats <- rep(NA_real_, T_obs)
  for (i in lo:hi) {
    Z <- gh_design_matrix(X, year, year[i], model)
    Z <- cbind(const = 1, Z)
    fit <- tryCatch(lm.fit(Z, y), error = function(e) NULL)
    if (is.null(fit)) next
    stats[i] <- .adf_t(fit$residuals, max_lag = max_lag)
  }
  if (!any(is.finite(stats))) {
    return(list(stat = NA_real_, break_index = NA_integer_, break_year = NA, model = model))
  }
  bi <- which.min(replace(stats, !is.finite(stats), Inf))
  list(stat = stats[bi], break_index = bi, break_year = year[bi], model = model,
       scan = stats)
}

# ---------------------------------------------------------------------------
# bootstrap_sanity_check(): guards against transposed nulls
# ---------------------------------------------------------------------------
# Exercises both DGPs on synthetic data with KNOWN answers:
#   - a genuinely cointegrated series: Hansen should NOT reject; GH SHOULD reject
#     (GH's H0 is no-cointegration, so rejection is the correct answer here)
#   - a spurious (independent random walks) pair: Hansen SHOULD reject; GH should NOT
# If these come out backwards, the DGPs have been swapped.
# ---------------------------------------------------------------------------
bootstrap_sanity_check <- function(n_boot = 199, seed = 20260803, verbose = TRUE) {
  set.seed(seed)
  T_obs <- 120; year <- 1900 + seq_len(T_obs)
  x <- cumsum(rnorm(T_obs))

  mk <- function(y) {
    X <- matrix(x, ncol = 1, dimnames = list(NULL, "x"))
    Z <- cbind(const = 1, X)
    f <- lm.fit(Z, y); u <- f$residuals; fitted_vals <- y - u
    list(X = X, Z = Z, y = y, u = u, fitted = fitted_vals)
  }

  # 1. genuinely cointegrated: u stationary
  coint <- mk(2 + 0.7 * x + rnorm(T_obs, sd = 0.4))
  # 2. spurious: y an independent random walk
  spur  <- mk(cumsum(rnorm(T_obs)))

  run_hansen_p <- function(d) {
    obs <- hansen_stability(d$Z, d$u, bandwidth = 4)$Lc_core
    null <- replicate(n_boot, {
      ys <- boot_null_stationary(d$fitted, d$u, 4)
      f <- lm.fit(d$Z, ys)
      hansen_stability(d$Z, f$residuals, bandwidth = 4)$Lc_core
    })
    mean(c(null, obs) >= obs)
  }
  run_gh_p <- function(d) {
    obs <- gh_test(d$y, d$X, year, model = "regime")$stat
    null <- replicate(n_boot, {
      ys <- boot_null_unitroot(d$fitted, d$u, 4)
      gh_test(ys, d$X, year, model = "regime")$stat
    })
    mean(c(null, obs) <= obs)   # left tail: more negative = more evidence
  }

  res <- data.frame(
    case = c("cointegrated", "spurious"),
    hansen_p = c(run_hansen_p(coint), run_hansen_p(spur)),
    gh_p = c(run_gh_p(coint), run_gh_p(spur)),
    stringsAsFactors = FALSE
  )
  res$hansen_expected <- c("high (do not reject stability)", "low (reject stability)")
  res$gh_expected     <- c("low (reject no-coint)", "high (do not reject no-coint)")
  res$hansen_ok <- c(res$hansen_p[1] > 0.10, res$hansen_p[2] < 0.10)
  res$gh_ok     <- c(res$gh_p[1] < 0.10,     res$gh_p[2] > 0.10)
  if (verbose) { cat("\n--- bootstrap sanity check (nulls not transposed?) ---\n"); print(res) }
  res
}
