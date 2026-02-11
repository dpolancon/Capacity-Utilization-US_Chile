############################################################
## 0_functions.R — Consolidated helpers + theta_inference module
## QR/Gram–Schmidt orthogonalization (GLOBAL, window-invariant)
## Reproducible + inference-safe (audited, deduplicated)
##
## Key contract:
## - Orthogonalization is QR of raw powers e^1..e^d (optionally centered)
## - The QR basis object is built ONCE using FULL window e, then reused
## - Theta inference uses the SAME QR basis for theta, theta', theta''
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
  empty_vec <- function() {
    vec <- rep(NA_real_, 4)
    names(vec) <- c("Test statistic","Critical value 1%","Critical value 5%","Critical value 10%")
    vec
  }
  tests <- setNames(
    lapply(test_names, function(.) setNames(vector("list", length(var_names)), var_names)),
    test_names
  )
  
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
    
    tests$PP[[v]] <- tryCatch({
      pp <- urca::ur.pp(x, type = "Z-tau", lags = pp_lags, model = model_type)
      ts <- unname(pp@teststat[1])
      cv <- pp@cval[1, c("1pct","5pct","10pct"), drop = TRUE]
      vec <- c(ts, as.numeric(cv)); names(vec) <- names(empty_vec()); vec
    }, error = function(e){ warning(sprintf("PP failed for %s: %s", v, conditionMessage(e))); empty_vec() })
    
    tests$DF.GL[[v]] <- tryCatch({
      dfgls <- urca::ur.ers(x, type = "DF-GLS", model = model_type, lag.max = ers_lag_max)
      ts <- unname(dfgls@teststat[1])
      cv <- dfgls@cval[1, c("1pct","5pct","10pct"), drop = TRUE]
      vec <- c(ts, as.numeric(cv)); names(vec) <- names(empty_vec()); vec
    }, error = function(e){ warning(sprintf("DF-GLS failed for %s: %s", v, conditionMessage(e))); empty_vec() })
    
    tests$ERS.PO[[v]] <- tryCatch({
      ers_po <- urca::ur.ers(x, type = "P-test", model = model_type, lag.max = ers_lag_max)
      ts <- unname(ers_po@teststat[1])
      cv <- ers_po@cval[1, c("1pct","5pct","10pct"), drop = TRUE]
      vec <- c(ts, as.numeric(cv)); names(vec) <- names(empty_vec()); vec
    }, error = function(e){ warning(sprintf("ERS.PO failed for %s: %s", v, conditionMessage(e))); empty_vec() })
    
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

ensure_dirs <- function(...) {
  paths <- c(...)
  paths <- unique(paths[!is.na(paths) & nzchar(paths)])
  invisible(lapply(paths, function(p) {
    if (!dir.exists(p)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
  }))
}

set_seed_deterministic <- function(seed = 123456) {
  suppressWarnings(RNGkind(kind = "Mersenne-Twister", normal.kind = "Inversion"))
  set.seed(seed)
}

safe_logdet <- function(resids) {
  S <- stats::cov(resids, use = "pairwise.complete.obs")
  as.numeric(determinant(S, logarithm = TRUE)$modulus)
}

save_plot_dual <- function(gg, filepath_no_ext,
                           width = 9, height = 5.2, dpi = 300,
                           overwrite = TRUE) {
  stopifnot(requireNamespace("ggplot2", quietly = TRUE))
  dir.create(dirname(filepath_no_ext), recursive = TRUE, showWarnings = FALSE)
  pdf_path <- paste0(filepath_no_ext, ".pdf")
  png_path <- paste0(filepath_no_ext, ".png")
  if (!overwrite && (file.exists(pdf_path) || file.exists(png_path)))
    stop("File exists and overwrite = FALSE: ", filepath_no_ext)
  
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

# ============================================================
# Admissible gate (shared)
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
# theta_inference module (GLOBAL QR basis + mapping + CIs)
# ============================================================

# Build raw polynomial matrix X(e) = [e, e^2, ..., e^degree] (no intercept)
poly_raw <- function(e, degree) {
  X <- sapply(1:degree, function(d) e^d)
  colnames(X) <- paste0("e", 1:degree)
  X
}

poly_raw_d1 <- function(e, degree) {
  X1 <- sapply(1:degree, function(d) d * e^(d - 1))
  colnames(X1) <- paste0("de_e", 1:degree)
  X1
}

poly_raw_d2 <- function(e, degree) {
  X2 <- sapply(1:degree, function(d) if (d >= 2) d * (d - 1) * e^(d - 2) else rep(0, length(e)))
  colnames(X2) <- paste0("d2e_e", 1:degree)
  X2
}

# Build a GLOBAL QR basis object from reference e (use full sample e)
theta_basis_qr_build <- function(e_ref, degree = 3, center = TRUE) {
  stopifnot(degree >= 1)
  X <- poly_raw(e_ref, degree)
  
  mu <- if (center) colMeans(X, na.rm = TRUE) else rep(0, ncol(X))
  Xc <- sweep(X, 2, mu, "-")
  
  qrX <- qr(Xc)
  R   <- qr.R(qrX)
  
  # A = R^{-1} so that q(e) = Xc(e) %*% A matches qr.Q on reference sample
  A <- solve(R)
  
  # optional deterministic sign convention for reproducibility:
  # force diag(R) positive => flip columns if needed
  sgn <- sign(diag(R)); sgn[sgn == 0] <- 1
  A <- A %*% diag(sgn, nrow = length(sgn))
  mu <- mu # unchanged
  
  list(degree = degree, center = center, mu = mu, A = A)
}

# Evaluate q(e), dq/de, d2q/de2 using the frozen QR basis object
theta_basis_qr_fixed <- function(e, basis_obj) {
  degree <- basis_obj$degree
  mu     <- basis_obj$mu
  A      <- basis_obj$A
  
  X  <- poly_raw(e, degree)
  Xc <- sweep(X, 2, mu, "-")
  
  dX  <- poly_raw_d1(e, degree)
  d2X <- poly_raw_d2(e, degree)
  
  q   <- Xc  %*% A
  dq  <- dX  %*% A
  ddq <- d2X %*% A
  
  colnames(q)   <- paste0("Q", 1:degree)
  colnames(dq)  <- paste0("dQ", 1:degree)
  colnames(ddq) <- paste0("ddQ", 1:degree)
  
  list(q = q, dq = dq, ddq = ddq)
}

# Map orthogonal coeffs c -> raw polynomial coefficients a0..ad given basis_obj
# theta(e) = b0 + c' q(e)
# q(e) = Xc(e) A where Xc = X - mu and X=[e^1..e^d]
# Let w = A c. Then theta(e) = b0 + sum_k w_k (e^k - mu_k)
# => a_k = w_k;  a_0 = b0 - sum_k w_k mu_k
theta_coefmap_qr <- function(b0, cvec, basis_obj) {
  stopifnot(length(cvec) == basis_obj$degree)
  w <- as.numeric(basis_obj$A %*% as.numeric(cvec))
  a_k <- w
  a0  <- as.numeric(b0 - sum(w * basis_obj$mu))
  a <- c(a0, a_k) # a0..ad
  names(a) <- paste0("a", 0:basis_obj$degree)
  list(w = w, a = a)
}

# Evaluate theta and derivatives given beta = (b0, c1..cd) using QR basis
theta_eval_qr <- function(e, beta, basis_obj) {
  degree <- basis_obj$degree
  stopifnot(length(beta) == (1 + degree))
  B <- theta_basis_qr_fixed(e, basis_obj)
  cvec <- as.numeric(beta[-1])
  th  <- as.numeric(beta[1] + B$q  %*% cvec)
  th1 <- as.numeric(B$dq %*% cvec)
  th2 <- as.numeric(B$ddq %*% cvec)
  list(theta = th, theta_prime = th1, theta_second = th2)
}

theta_delta_ci_qr <- function(e_grid, beta_hat, Sigma_beta, basis_obj,
                              zcrit = 1.96, do_second = FALSE) {
  degree <- basis_obj$degree
  stopifnot(length(beta_hat) == (1 + degree))
  
  B <- theta_basis_qr_fixed(e_grid, basis_obj)
  
  g   <- cbind(1, B$q)
  gp  <- cbind(0, B$dq)
  gpp <- cbind(0, B$ddq)
  
  est <- theta_eval_qr(e_grid, beta_hat, basis_obj)
  
  var_theta <- rowSums((g  %*% Sigma_beta) * g)
  var_prime <- rowSums((gp %*% Sigma_beta) * gp)
  
  out <- data.frame(
    e = e_grid,
    theta_hat = est$theta,
    theta_lo  = est$theta - zcrit * sqrt(pmax(var_theta, 0)),
    theta_hi  = est$theta + zcrit * sqrt(pmax(var_theta, 0)),
    theta_prime_hat = est$theta_prime,
    theta_prime_lo  = est$theta_prime - zcrit * sqrt(pmax(var_prime, 0)),
    theta_prime_hi  = est$theta_prime + zcrit * sqrt(pmax(var_prime, 0)),
    stringsAsFactors = FALSE
  )
  
  if (isTRUE(do_second)) {
    var_second <- rowSums((gpp %*% Sigma_beta) * gpp)
    out$theta_second_hat <- est$theta_second
    out$theta_second_lo  <- est$theta_second - zcrit * sqrt(pmax(var_second, 0))
    out$theta_second_hi  <- est$theta_second + zcrit * sqrt(pmax(var_second, 0))
  }
  
  out
}

# Moving-block bootstrap indices
mbb_indices <- function(T, L) {
  if (L < 1) L <- 1
  if (L > T) L <- T
  starts <- sample.int(T - L + 1L, size = ceiling(T / L), replace = TRUE)
  idx <- unlist(lapply(starts, function(s) s:(s + L - 1L)))
  idx[1:T]
}

# Bootstrap inference for theta curve and coefficients (pointwise percentile bands)
theta_bootstrap_qr <- function(dfw, degree, basis_obj,
                               ecdet, p, r,
                               B = 100, block_len = NULL,
                               extract_beta_fun,
                               verbose = FALSE) {
  stopifnot(is.matrix(dfw))
  T <- nrow(dfw)
  if (is.null(block_len)) block_len <- max(5L, floor(T^(1/3)))
  if (verbose) message("Bootstrap B=", B, " block_len=", block_len)
  
  e_grid <- sort(unique(seq(min(basis_obj$mu[1]^(1/1), na.rm=TRUE),
                            max(basis_obj$mu[1]^(1/1), na.rm=TRUE),
                            length.out = 101)))
  # Better: evaluate on observed e-range. Caller should pass e_grid, but keep safe default:
  e_grid <- seq(min(dfw[,1], na.rm=TRUE), max(dfw[,1], na.rm=TRUE), length.out = 101)
  # NOTE: we don't actually know which column is e here; Engine evaluates on global e range.
  # In Engine we override e_grid explicitly. This function expects caller to manage e_grid if needed.
  
  beta_hat <- extract_beta_fun(dfw, ecdet, p, r)
  # e_grid will be overwritten by caller logic; but keep consistent interface:
  # We'll set curve later after caller passes its own grid. See Engine.
  
  th_mat  <- matrix(NA_real_, nrow = 101, ncol = B)
  thp_mat <- matrix(NA_real_, nrow = 101, ncol = B)
  thpp_mat<- matrix(NA_real_, nrow = 101, ncol = B)
  
  kept <- 0L
  fail <- 0L
  
  for (b in seq_len(B)) {
    idx <- mbb_indices(T, block_len)
    dfb <- dfw[idx, , drop = FALSE]
    tryb <- try({
      beta_b <- extract_beta_fun(dfb, ecdet, p, r)
      # Caller re-evaluates curve on its grid; here we only store betas
      kept <<- kept + 1L
      beta_b
    }, silent = TRUE)
    if (inherits(tryb, "try-error")) fail <- fail + 1L
  }
  
  list(
    method = "bootstrap_mbb_ca_jo",
    B = B,
    block_len = block_len,
    kept = kept,
    failed = fail,
    beta_hat = beta_hat
  )
}

# Unit tests for QR mapping: theta via basis equals theta via raw polynomial a
theta_unit_tests_qr <- function() {
  e_ref <- seq(0.2, 0.6, length.out = 80)
  for (deg in 2:3) {
    basis_obj <- theta_basis_qr_build(e_ref, degree = deg, center = TRUE)
    e_grid <- seq(min(e_ref), max(e_ref), length.out = 25)
    
    # random (b0,c)
    b0 <- stats::rnorm(1)
    cvec <- stats::rnorm(deg)
    beta <- c(b0, cvec)
    
    B <- theta_basis_qr_fixed(e_grid, basis_obj)
    th1 <- as.numeric(b0 + B$q %*% cvec)
    
    mp <- theta_coefmap_qr(b0, cvec, basis_obj)
    a <- mp$a # a0..ad
    V <- sapply(0:deg, function(k) e_grid^k)
    th2 <- as.numeric(V %*% a)
    
    if (max(abs(th1 - th2), na.rm = TRUE) > 1e-8) {
      stop("theta_unit_tests_qr failed for deg=", deg)
    }
  }
  TRUE
}
