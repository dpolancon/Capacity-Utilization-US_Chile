# ============================================================
# 52_VECM_S1_shaikh_window.R  (CONSOLIDATED)
# Self-Discovery Process — VECM Stage (S1: lnY, lnK)
# Window: shaikh_window (from CONFIG)
#
# Purpose (LOCKED):
#   - Rank-1 confinement discovery for X_t = (lnY, lnK)'
#   - Short-run lag asymmetry q=(qY,qK) applies ONLY to Γ (memory allocation)
#   - Stability geometry via companion roots (indices)
#   - Lean deliverables (<=6 figs + <=2 tables per branch)
#
# Notes:
#   - No dummies in this stage.
#   - Sources renamed:
#       codes/10_config.R
#       codes/99_utils.R
# ============================================================

rm(list = ls())

required_pkgs <- c("here","readxl","dplyr","tidyr","ggplot2","tsDyn")
for (p in required_pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop(sprintf("Package '%s' is required but not installed.", p), call. = FALSE)
  }
}

library(here)
library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)
library(tsDyn)

# ---------------------------
# Source config + utils (RENAMED)
# ---------------------------
source(here::here("codes","10_config.R"))
source(here::here("codes","99_utils.R"))
source(here::here("codes","critical_replication","24_complexity_penalties.R"))

set.seed(CONFIG$seed %||% 123)

# ============================================================
# Stage locks
# ============================================================
WINDOW_TAG <- "shaikh_window"
STATE_TAG  <- "S1_lnY_lnK"

# Reference theta from ARDL replication report (Stage 0)
THETA_ARDL_REF <- 0.7085689

P_MIN <- as.integer(max(1L, CONFIG$P_MIN %||% 1L))
P_MAX <- as.integer(max(P_MIN, CONFIG$P_MAX_EXPLORATORY %||% 8L))

# Deterministics panel for this stage (explicit stage override)
SR_SET <- c("none","const")
LR_SET <- c("none","const","trend","both")

TOL_UNIT <- 1e-3
DELTA_IC_BAND <- 2
ETA_GRID <- c(1, 1.5, 2, 3, 4, 6, 8)

# ============================================================
# Output paths
# ============================================================
out_root <- here::here(CONFIG$OUT_CR$exercise_c %||% "output/CriticalReplication/Exercise_c_VECM_S1_r1")

make_branch_dirs <- function(det_tag) {
  base <- file.path(out_root, det_tag)
  sub <- c("csv","figs","tex","logs","cache","ect")
  for (s in sub) dir.create(file.path(base, s), recursive = TRUE, showWarnings = FALSE)
  base
}

log_run <- function(log_dir, msg) {
  idx_path <- file.path(log_dir, "RUN_INDEX.csv")
  idx <- if (file.exists(idx_path)) {
    tryCatch(read.csv(idx_path, stringsAsFactors = FALSE), error = function(e) NULL)
  } else NULL
  
  run_id <- if (is.null(idx) || nrow(idx) == 0) 1L else max(idx$run_id, na.rm = TRUE) + 1L
  row <- data.frame(
    run_id = run_id,
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    message = msg,
    stringsAsFactors = FALSE
  )
  if (is.null(idx)) write.csv(row, idx_path, row.names = FALSE) else write.csv(rbind(idx, row), idx_path, row.names = FALSE)
  writeLines(paste0("[", row$timestamp, "] ", msg), con = file.path(log_dir, sprintf("RUN_%03d.txt", run_id)))
  run_id
}

# ============================================================
# Data ingestion (Shaikh)
# ============================================================
load_shaikh_window <- function() {
  df_raw <- readxl::read_excel(here::here(CONFIG$data_shaikh), sheet = CONFIG$data_shaikh_sheet)
  stopifnot(all(c(CONFIG$year_col, CONFIG$y_nom, CONFIG$k_nom, CONFIG$p_index) %in% names(df_raw)))
  
  df <- df_raw |>
    transmute(
      year  = as.integer(.data[[CONFIG$year_col]]),
      Y_nom = as.numeric(.data[[CONFIG$y_nom]]),
      K_nom = as.numeric(.data[[CONFIG$k_nom]]),
      p     = as.numeric(.data[[CONFIG$p_index]])
    ) |>
    filter(is.finite(year), is.finite(Y_nom), is.finite(K_nom), is.finite(p), p > 0) |>
    mutate(
      p_scale = p / 100,
      Y_real  = Y_nom / p_scale,
      K_real  = K_nom / p_scale,
      lnY     = log(Y_real),
      lnK     = log(K_real)
    ) |>
    arrange(year)
  
  w <- CONFIG$WINDOWS_LOCKED[[WINDOW_TAG]]
  if (is.null(w) || length(w) != 2) stop("WINDOW_TAG not found in CONFIG$WINDOWS_LOCKED", call. = FALSE)
  
  df <- df |>
    filter(year >= w[1], year <= w[2]) |>
    arrange(year)
  
  X <- as.matrix(df[, c("lnY","lnK")])
  colnames(X) <- c("lnY","lnK")
  
  list(df = df, X = X, T_window = nrow(X), m = ncol(X), window = w, window_start = as.integer(w[1]), window_end = as.integer(w[2]))
}

# ============================================================
# Parameter counts (q-aware) — no PIC
# ============================================================
k_pi <- function(r, m, lr) {
  r <- as.integer(r); m <- as.integer(m)
  d_lr <- det_count(resolve_LRinclude(lr))
  r * (2L*m - r) + r * d_lr
}

k_gamma <- function(p, qY, qK, m) {
  p <- as.integer(p); m <- as.integer(m)
  qY <- as.integer(max(0, min(p, qY)))
  qK <- as.integer(max(0, min(p, qK)))
  m * (qY + qK)
}

k_det_sr <- function(m, sr) {
  m <- as.integer(m)
  d <- det_count(resolve_include(sr))
  m * d
}

k_sigma <- function(m) {
  m <- as.integer(m)
  as.integer(m * (m + 1L) / 2L)
}

ic_panel <- function(ll, k, T_eff_common) {
  core <- -2 * ll
  AIC  <- core + 2 * k
  BIC  <- core + log(T_eff_common) * k
  HQ   <- core + 2 * log(log(T_eff_common)) * k
  denom <- T_eff_common - k - 1
  AICc <- if (is.finite(denom) && denom > 0) AIC + (2*k*(k+1))/denom else NA_real_
  tibble(AIC = AIC, BIC = BIC, HQ = HQ, AICc = AICc)
}

ic_eta <- function(ll, T_eff_common, k_gamma, k_pi, k_det, k_sigma, eta) {
  core <- -2 * ll
  pen  <- log(T_eff_common) * (k_gamma + eta * k_pi + k_det + k_sigma)
  core + pen
}

# ============================================================
# VECM ML fit (β anchor)
# ============================================================
fit_vecm_ml <- function(X, p, sr, lr) {
  tryCatch(
    tsDyn::VECM(
      data = X,
      lag = as.integer(p),
      r = 1,
      include = resolve_include(sr),
      LRinclude = resolve_LRinclude(lr),
      estim = "ML"
    ),
    error = function(e) e
  )
}

extract_beta_matrix <- function(fit) {
  b <- tryCatch({
    if (!is.null(fit$model.specific) && !is.null(fit$model.specific$beta)) fit$model.specific$beta else NULL
  }, error = function(e) NULL)
  
  if (is.null(b)) b <- tryCatch(tsDyn::coefB(fit), error = function(e) NULL)
  if (is.null(b)) b <- tryCatch({ if (!is.null(fit$beta)) fit$beta else NULL }, error = function(e) NULL)
  
  if (is.matrix(b) && nrow(b) == 1L && ncol(b) > 1L) b <- t(b)
  b
}

normalize_beta_on_lnY <- function(beta_mat, m = 2L) {
  if (is.null(beta_mat)) return(NULL)
  if (is.vector(beta_mat)) beta_mat <- matrix(beta_mat, ncol = 1)
  if (!is.matrix(beta_mat)) return(NULL)
  
  b <- beta_mat[,1]
  if (length(b) < m) return(NULL)
  if (!is.finite(b[1]) || b[1] == 0) return(NULL)
  b / b[1]
}

make_lr_det_mat <- function(T, lr) {
  lr <- resolve_LRinclude(lr)
  if (lr == "none") return(NULL)
  trend <- seq_len(T)
  const <- rep(1, T)
  if (lr == "const") return(cbind(const = const))
  if (lr == "trend") return(cbind(trend = trend))
  if (lr == "both")  return(cbind(const = const, trend = trend))
  NULL
}

compute_ect_series <- function(X, beta_norm, lr, T) {
  if (is.null(beta_norm)) return(NULL)
  m <- ncol(X)
  Z <- X
  lr_mat <- make_lr_det_mat(T, lr)
  if (!is.null(lr_mat)) Z <- cbind(Z, lr_mat)
  if (ncol(Z) != length(beta_norm)) return(as.numeric(X %*% beta_norm[1:m]))
  as.numeric(Z %*% beta_norm)
}

# ============================================================
# Restricted OLS on ΔX with ECT_{t-1} + restricted Δ-lags (q)
# ============================================================
build_restricted_design <- function(X, ect, p, qY, qK, sr) {
  X <- as.matrix(X)
  T <- nrow(X); m <- ncol(X)
  stopifnot(m == 2)
  
  dX <- apply(X, 2, diff)
  
  t_idx <- (p + 2):T
  Te <- length(t_idx)
  if (Te < 5) stop("Too few effective obs for p=", p)
  
  Ydep <- dX[t_idx - 1, , drop = FALSE]
  
  Z_list <- list(ECT = ect[t_idx - 1])
  
  qY <- max(0L, min(as.integer(p), as.integer(qY)))
  qK <- max(0L, min(as.integer(p), as.integer(qK)))
  
  for (i in 1:p) {
    lag_row <- (t_idx - 1) - i
    if (i <= qY) Z_list[[paste0("dlnY_L", i)]] <- dX[lag_row, 1]
    if (i <= qK) Z_list[[paste0("dlnK_L", i)]] <- dX[lag_row, 2]
  }
  
  inc <- resolve_include(sr)
  if (inc %in% c("const","both")) Z_list[["const"]] <- rep(1, Te)
  if (inc %in% c("trend","both")) Z_list[["trend"]] <- seq_along(t_idx)
  
  Z <- do.call(cbind, Z_list)
  list(Z = as.matrix(Z), Y = as.matrix(Ydep), t_idx = t_idx)
}

ols_multivar <- function(Z, Y) {
  B <- solve(crossprod(Z), crossprod(Z, Y))
  U <- Y - Z %*% B
  list(B = B, U = U)
}

gaussian_loglik <- function(U) {
  U <- as.matrix(U)
  Te <- nrow(U); m <- ncol(U)
  Sigma <- crossprod(U) / Te
  detS <- as.numeric(det(Sigma))
  if (!is.finite(detS) || detS <= 0) return(NA_real_)
  - (Te*m/2) * (1 + log(2*pi)) - (Te/2) * log(detS)
}

extract_gamma_list <- function(B, p, qY, qK) {
  m <- ncol(B)
  stopifnot(m == 2)
  
  G <- vector("list", p)
  for (i in 1:p) {
    Gi <- matrix(0, nrow = m, ncol = m)
    rnY <- paste0("dlnY_L", i)
    rnK <- paste0("dlnK_L", i)
    if (i <= qY && rnY %in% rownames(B)) Gi[,1] <- B[rnY, ]
    if (i <= qK && rnK %in% rownames(B)) Gi[,2] <- B[rnK, ]
    G[[i]] <- Gi
  }
  G
}

companion_roots <- function(Pi, Gamma_list, tol_unit = 1e-3) {
  m <- nrow(Pi)
  p <- length(Gamma_list)
  k <- p + 1L
  
  I <- diag(m)
  G <- Gamma_list
  
  A <- vector("list", k)
  A[[1]] <- I + Pi + if (p >= 1) G[[1]] else 0
  
  if (k >= 2) {
    for (i in 2:k) {
      Gi   <- if (i <= p) G[[i]] else matrix(0, m, m)
      Gim1 <- if (i-1 <= p) G[[i-1]] else matrix(0, m, m)
      A[[i]] <- Gi - Gim1
    }
  }
  
  C <- matrix(0, nrow = m*k, ncol = m*k)
  C[1:m, 1:(m*k)] <- do.call(cbind, A)
  if (k > 1) C[(m+1):(m*k), 1:(m*(k-1))] <- diag(m*(k-1))
  
  eig <- eigen(C, only.values = TRUE)$values
  mod <- Mod(eig)
  
  unit_ct <- sum(abs(mod - 1) <= tol_unit)
  unstable_ct <- sum(mod > 1 + tol_unit)
  
  nonunit <- mod[abs(mod - 1) > tol_unit]
  max_nonunit <- if (length(nonunit) > 0) max(nonunit) else NA_real_
  margin <- if (is.finite(max_nonunit)) 1 - max_nonunit else NA_real_
  
  list(
    eig = eig,
    mod = mod,
    unit_root_count = unit_ct,
    unstable_count = unstable_ct,
    max_mod_nonunit = max_nonunit,
    stability_margin = margin
  )
}

gamma_summaries <- function(Gamma_list) {
  frob <- function(M) sqrt(sum(M^2))
  norms <- sapply(Gamma_list, frob)
  
  colnorm <- function(M, j) sqrt(sum(M[,j]^2))
  normsY <- sapply(Gamma_list, colnorm, j = 1)
  normsK <- sapply(Gamma_list, colnorm, j = 2)
  
  total <- sum(norms, na.rm = TRUE)
  shareY <- if (total > 0) sum(normsY, na.rm = TRUE)/total else NA_real_
  shareK <- if (total > 0) sum(normsK, na.rm = TRUE)/total else NA_real_
  
  list(SR_norm_total = total, share_Y = shareY, share_K = shareK)
}

# ============================================================
# Plot helpers (lean)
# ============================================================
save_fig <- function(p, path, w = 10, h = 6, dpi = 200) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  ggsave(filename = path, plot = p, width = w, height = h, dpi = dpi)
}

band_cut <- function(x) {
  cut(x, breaks = c(-Inf, 0, 2, 6, Inf), labels = c("min","0-2","2-6",">6"))
}

plot_pca_embedding <- function(df, feat_cols, color_col, title) {
  mat <- df[, feat_cols, drop = FALSE]
  mat <- as.data.frame(lapply(mat, function(z) as.numeric(z)))
  ok <- complete.cases(mat)
  mat <- mat[ok, , drop = FALSE]
  if (nrow(mat) < 5) return(NULL)
  pc <- prcomp(scale(mat), center = TRUE, scale. = TRUE)
  coords <- as.data.frame(pc$x[,1:2, drop = FALSE])
  coords[[color_col]] <- df[[color_col]][ok]
  ggplot(coords, aes(x = PC1, y = PC2, color = .data[[color_col]])) +
    geom_point(alpha = 0.85) +
    theme_minimal(base_size = 13) +
    labs(title = title, color = color_col)
}

plot_mds_embedding <- function(df, feat_cols, color_col, title) {
  mat <- df[, feat_cols, drop = FALSE]
  mat <- as.data.frame(lapply(mat, function(z) as.numeric(z)))
  ok <- complete.cases(mat)
  mat <- mat[ok, , drop = FALSE]
  if (nrow(mat) < 5) return(NULL)
  d <- dist(scale(mat), method = "euclidean")
  mds <- cmdscale(d, k = 2)
  coords <- data.frame(D1 = mds[,1], D2 = mds[,2])
  coords[[color_col]] <- df[[color_col]][ok]
  ggplot(coords, aes(x = D1, y = D2, color = .data[[color_col]])) +
    geom_point(alpha = 0.85) +
    theme_minimal(base_size = 13) +
    labs(title = title, color = color_col)
}

plot_roots_overlay <- function(eigs_long, title) {
  unit_circle <- data.frame(
    t = seq(0, 2*pi, length.out = 400),
    x = cos(seq(0, 2*pi, length.out = 400)),
    y = sin(seq(0, 2*pi, length.out = 400))
  )
  ggplot(eigs_long, aes(x = Re, y = Im, color = cell_id)) +
    geom_path(data = unit_circle, aes(x = x, y = y), inherit.aes = FALSE, linetype = 2, alpha = 0.6) +
    geom_point(alpha = 0.75) +
    coord_equal() +
    theme_minimal(base_size = 13) +
    labs(title = title, x = "Re(λ)", y = "Im(λ)", color = "cell")
}

# ============================================================
# Main branch runner
# ============================================================
q_profiles_for_p <- function(p) {
  p <- as.integer(p)
  tibble(
    q_tag = c("sym","Y_only","K_only","Y_short","K_short"),
    qY = c(p, p, 0, min(1L,p), p),
    qK = c(p, 0, p, p, min(1L,p))
  )
}

cell_id <- function(p, q_tag, sr, lr) {
  sprintf("p%02d_%s_%s_%s", as.integer(p), q_tag, sr, lr)
}

run_branch <- function(df, X, T_window, m, sr, lr) {
  
  include <- resolve_include(sr)
  LRinclude <- resolve_LRinclude(lr)
  
  # tsDyn constraint: if LRinclude has const, SR include cannot be const
  if (include == "const" && LRinclude %in% c("const", "both")) {
    det_tag_skip <- det_tag_from(include, LRinclude)
    base_dir_skip <- make_branch_dirs(det_tag_skip)
    log_dir_skip  <- file.path(base_dir_skip, "logs")
    
    log_run(
      log_dir_skip,
      sprintf("SKIPPED: tsDyn constraint. LRinclude in {const,both} forbids SR include=const. Requested SR=%s LR=%s.", include, LRinclude)
    )
    message("Skipping branch ", det_tag_skip, " (invalid SR/LR combo in tsDyn).")
    return(invisible(NULL))
  }
  
  det_tag <- det_tag_from(include, LRinclude)
  
  base_dir <- make_branch_dirs(det_tag)
  csv_dir  <- file.path(base_dir, "csv")
  fig_dir  <- file.path(base_dir, "figs")
  tex_dir  <- file.path(base_dir, "tex")
  log_dir  <- file.path(base_dir, "logs")
  ect_dir  <- file.path(base_dir, "ect")
  
  run_id <- log_run(log_dir, sprintf("Stage S1 run: SR=%s LR=%s (P=%d..%d)", include, LRinclude, P_MIN, P_MAX))
  
  T_eff_common <- as.integer(T_window - (P_MAX + 1L))
  if (!is.finite(T_eff_common) || T_eff_common < 20) {
    T_eff_common <- as.integer(max(20L, T_window - (P_MIN + 1L)))
  }
  
  # ---- Step 1: ML VECM fits per p (β anchor)
  beta_by_p <- list()
  ll_ml_by_p <- rep(NA_real_, length(P_MIN:P_MAX))
  names(ll_ml_by_p) <- as.character(P_MIN:P_MAX)
  gate_fail <- list()
  
  for (p in P_MIN:P_MAX) {
    fit <- fit_vecm_ml(X, p, include, LRinclude)
    if (inherits(fit, "error")) {
      gate_fail[[length(gate_fail)+1]] <- data.frame(
        run_id = run_id, det_tag = det_tag, p = p,
        stage = "VECM_ML", fail_code = "VECM_FAIL",
        fail_msg = truncate_msg(conditionMessage(fit), 240),
        stringsAsFactors = FALSE
      )
      next
    }
    ll_ml_by_p[as.character(p)] <- tsdyn_loglik(fit)
    
    bmat <- extract_beta_matrix(fit)
    bnorm <- normalize_beta_on_lnY(bmat, m = m)
    if (is.null(bnorm)) {
      gate_fail[[length(gate_fail)+1]] <- data.frame(
        run_id = run_id, det_tag = det_tag, p = p,
        stage = "BETA_EXTRACT", fail_code = "BETA_FAIL",
        fail_msg = "Could not extract/normalize beta",
        stringsAsFactors = FALSE
      )
      next
    }
    beta_by_p[[as.character(p)]] <- bnorm
  }
  
  if (length(gate_fail) > 0) {
    gf <- do.call(rbind, gate_fail)
    write.csv(gf, file.path(log_dir, sprintf("GATE_FAIL_%03d.csv", run_id)), row.names = FALSE)
  }
  
  # ---- Step 2: Build p×q lattice via restricted OLS
  rows <- list()
  eig_rows <- list()
  
  for (p in P_MIN:P_MAX) {
    bnorm <- beta_by_p[[as.character(p)]]
    
    qset <- q_profiles_for_p(p)
    
    if (is.null(bnorm)) {
      for (j in seq_len(nrow(qset))) {
        cid <- cell_id(p, qset$q_tag[j], include, LRinclude)
        rows[[length(rows)+1]] <- tibble(
          run_id = run_id, det_tag = det_tag,
          include = include, LRinclude = LRinclude,
          p = p, r = 1,
          q_tag = qset$q_tag[j], qY = qset$qY[j], qK = qset$qK[j],
          cell_id = cid,
          status = "runtime_fail",
          fail_code = "BETA_MISSING",
          fail_msg = "β anchor missing (VECM ML failed or β extraction failed)"
        )
      }
      next
    }
    
    ect <- compute_ect_series(X, bnorm, LRinclude, T_window)
    
    for (j in seq_len(nrow(qset))) {
      q_tag <- qset$q_tag[j]
      qY <- qset$qY[j]
      qK <- qset$qK[j]
      cid <- cell_id(p, q_tag, include, LRinclude)
      
      fit_ols <- tryCatch({
        des <- build_restricted_design(X, ect, p, qY, qK, include)
        ols <- ols_multivar(des$Z, des$Y)
        ll  <- gaussian_loglik(ols$U)
        
        G <- extract_gamma_list(ols$B, p, qY, qK)
        
        alpha <- as.numeric(ols$B["ECT", ])
        beta_vars <- bnorm[1:2]
        Pi <- matrix(alpha, ncol = 1) %*% t(matrix(beta_vars, ncol = 1))
        
        roots <- companion_roots(Pi, G, tol_unit = TOL_UNIT)
        gsum <- gamma_summaries(G)
        
        Sigma_hat <- crossprod(ols$U) / nrow(ols$U)

        list(ok = TRUE, ll = ll, Te = nrow(ols$U),
             alpha = alpha, beta = bnorm, Pi = Pi, Sigma_hat = Sigma_hat,
             roots = roots, gsum = gsum)
      }, error = function(e) list(ok = FALSE, msg = conditionMessage(e)))
      
      if (!isTRUE(fit_ols$ok) || !is.finite(fit_ols$ll)) {
        rows[[length(rows)+1]] <- tibble(
          run_id = run_id, det_tag = det_tag,
          include = include, LRinclude = LRinclude,
          p = p, r = 1, q_tag = q_tag, qY = qY, qK = qK,
          cell_id = cid,
          status = "runtime_fail",
          fail_code = "OLS_FAIL",
          fail_msg = truncate_msg(fit_ols$msg %||% "ols failed", 240)
        )
        next
      }
      
      kG <- k_gamma(p, qY, qK, m)
      kPi <- k_pi(1, m, LRinclude)
      kDet <- k_det_sr(m, include)
      kSig <- k_sigma(m)
      kTot <- kG + kPi + kDet + kSig
      
      ic <- ic_panel(fit_ols$ll, kTot, T_eff_common)
      
      theta_hat <- -fit_ols$beta[2]
      aY <- fit_ols$alpha[1]
      aK <- fit_ols$alpha[2]
      
      unit_mismatch <- fit_ols$roots$unit_root_count - (m - 1L)
      
      comp_row <- compute_complexity_record(
        model_class = "VECM_S1_restricted_OLS",
        logLik = fit_ols$ll,
        k_total = kTot,
        vcov_mat = fit_ols$Sigma_hat,
        T_eff = fit_ols$Te
      )

      rows[[length(rows)+1]] <- tibble(
        run_id = run_id, det_tag = det_tag,
        include = include, LRinclude = LRinclude,
        p = p, r = 1, q_tag = q_tag, qY = qY, qK = qK,
        cell_id = cid,
        status = "computed",
        fit_term_source = "restricted_OLS_gaussian_not_VECM_ML",
        covariance_source = "residual_covariance_crossprodU_over_Teff",
        logLik = fit_ols$ll,
        T_eff = fit_ols$Te,
        T_eff_common = T_eff_common,
        k_gamma = kG, k_pi = kPi, k_det = kDet, k_sigma = kSig, k_total = kTot,
        ICOMP_pen = comp_row$ICOMP_pen,
        RICOMP_pen = comp_row$RICOMP_pen,
        ICOMP_flag = comp_row$ICOMP_flag,
        RICOMP_flag = comp_row$RICOMP_flag,
        ICOMP_stabilized = comp_row$ICOMP_stabilized,
        RICOMP_stabilized = comp_row$RICOMP_stabilized,
        AIC = ic$AIC, BIC = ic$BIC, HQ = ic$HQ, AICc = ic$AICc,
        theta_hat = theta_hat,
        alpha_y = aY, alpha_k = aK,
        Pi_11 = fit_ols$Pi[1,1], Pi_12 = fit_ols$Pi[1,2],
        Pi_21 = fit_ols$Pi[2,1], Pi_22 = fit_ols$Pi[2,2],
        SR_norm_total = fit_ols$gsum$SR_norm_total,
        share_Y = fit_ols$gsum$share_Y,
        share_K = fit_ols$gsum$share_K,
        stability_margin = fit_ols$roots$stability_margin,
        unit_root_count = fit_ols$roots$unit_root_count,
        unstable_count = fit_ols$roots$unstable_count,
        unit_root_mismatch = unit_mismatch,
        fail_code = NA_character_, fail_msg = NA_character_
      )
      
      eig <- fit_ols$roots$eig
      eig_rows[[length(eig_rows)+1]] <- tibble(
        run_id = run_id, det_tag = det_tag, cell_id = cid,
        p = p, q_tag = q_tag,
        eig_id = seq_along(eig),
        Re = Re(eig), Im = Im(eig), Mod = Mod(eig)
      )
    }
  }
  
  cells <- bind_rows(rows) |>
    mutate(
      window_tag = WINDOW_TAG,
      window_start = dat$window_start,
      window_end = dat$window_end
    )
  safe_write_csv(cells, file.path(csv_dir, "APPX_lattice_cells.csv"))
  
  n_comp <- sum(cells$status == "computed", na.rm = TRUE)
  if (!is.finite(n_comp) || n_comp == 0L) {
    safe_write_csv(tibble(), file.path(csv_dir, "APPX_ic_eta_long.csv"))
    safe_write_csv(tibble(), file.path(csv_dir, "TAB_top_cells_N10.csv"))
    
    feas_share <- mean(cells$status == "computed", na.rm = TRUE)
    branch_summary <- tibble(
      run_id = run_id, det_tag = det_tag, include = include, LRinclude = LRinclude,
      window_tag = WINDOW_TAG, window_start = dat$window_start, window_end = dat$window_end,
      P_MIN = P_MIN, P_MAX = P_MAX, T_window = T_window, T_eff_common = T_eff_common,
      feasibility_share = feas_share,
      best_cell_id = NA_character_, best_BIC = NA_real_,
      theta_best = NA_real_, theta_bandwidth_dBIC2 = NA_real_,
      alpha_y_med_dBIC2 = NA_real_, alpha_k_med_dBIC2 = NA_real_,
      stability_margin_best = NA_real_
    )
    safe_write_csv(branch_summary, file.path(csv_dir, "TAB_branch_summary.csv"))
    
    message("Branch ", det_tag, ": no computed cells. See logs; skipping figures.")
    return(invisible(list(det_tag = det_tag, out = base_dir, run_id = run_id)))
  }
  
  eig_long <- if (length(eig_rows) > 0) bind_rows(eig_rows) else tibble()
  if (nrow(eig_long) > 0) {
    eig_long <- eig_long |> mutate(
      window_tag = WINDOW_TAG,
      window_start = dat$window_start,
      window_end = dat$window_end
    )
  }
  if (nrow(eig_long) > 0) safe_write_csv(eig_long, file.path(csv_dir, "APPX_eigs_long.csv"))
  
  # ---- Deltas under stability mask
  cells2 <- cells
  mask_stable <- with(cells2, status == "computed" & unit_root_mismatch == 0 & unstable_count == 0)
  
  if (any(mask_stable, na.rm = TRUE)) {
    minB <- min(cells2$BIC[mask_stable], na.rm = TRUE)
    minA <- min(cells2$AIC[mask_stable], na.rm = TRUE)
    minH <- min(cells2$HQ[mask_stable], na.rm = TRUE)
  } else {
    minB <- min(cells2$BIC[cells2$status == "computed"], na.rm = TRUE)
    minA <- min(cells2$AIC[cells2$status == "computed"], na.rm = TRUE)
    minH <- min(cells2$HQ[cells2$status == "computed"], na.rm = TRUE)
  }
  
  cells2 <- cells2 |>
    mutate(dBIC = BIC - minB, dAIC = AIC - minA, dHQ = HQ - minH)
  
  safe_write_csv(cells2, file.path(csv_dir, "APPX_lattice_cells_with_deltas.csv"))
  
  # ---- IC_eta table
  eta_long <- cells2 |>
    filter(status == "computed") |>
    tidyr::expand_grid(eta = ETA_GRID) |>
    mutate(IC_eta = ic_eta(logLik, T_eff_common, k_gamma, k_pi, k_det, k_sigma, eta))
  
  safe_write_csv(eta_long, file.path(csv_dir, "APPX_ic_eta_long.csv"))
  
  # ---- Top cells + branch summary
  topN <- cells2 |>
    filter(status == "computed") |>
    arrange(BIC) |>
    slice(1:10)
  safe_write_csv(topN, file.path(csv_dir, "TAB_top_cells_N10.csv"))
  
  best_stable <- cells2 |>
    filter(status == "computed", unit_root_mismatch == 0, unstable_count == 0) |>
    arrange(BIC) |>
    slice(1)
  if (nrow(best_stable) == 0) best_stable <- topN |> slice(1)
  
  amb <- cells2 |>
    filter(status == "computed", dBIC <= DELTA_IC_BAND)
  
  theta_bw <- if (nrow(amb) > 0) diff(range(amb$theta_hat, na.rm = TRUE)) else NA_real_
  alpha_y_med <- if (nrow(amb) > 0) median(amb$alpha_y, na.rm = TRUE) else NA_real_
  alpha_k_med <- if (nrow(amb) > 0) median(amb$alpha_k, na.rm = TRUE) else NA_real_
  
  feas_share <- mean(cells2$status == "computed", na.rm = TRUE)
  
  branch_summary <- tibble(
    run_id = run_id, det_tag = det_tag, include = include, LRinclude = LRinclude,
    window_tag = WINDOW_TAG, window_start = dat$window_start, window_end = dat$window_end,
    P_MIN = P_MIN, P_MAX = P_MAX, T_window = T_window, T_eff_common = T_eff_common,
    feasibility_share = feas_share,
    best_cell_id = best_stable$cell_id[1],
    best_BIC = best_stable$BIC[1],
    theta_best = best_stable$theta_hat[1],
    theta_bandwidth_dBIC2 = theta_bw,
    alpha_y_med_dBIC2 = alpha_y_med,
    alpha_k_med_dBIC2 = alpha_k_med,
    stability_margin_best = best_stable$stability_margin[1]
  )
  safe_write_csv(branch_summary, file.path(csv_dir, "TAB_branch_summary.csv"))
  
  # ---- Figures (lean)
  plot_df <- cells2 |>
    filter(status == "computed") |>
    mutate(
      stable_ok = (unit_root_mismatch == 0 & unstable_count == 0),
      dBIC_band = band_cut(dBIC)
    )
  
  g1 <- ggplot(plot_df, aes(x = factor(p), y = q_tag, fill = dBIC)) +
    geom_tile() +
    theme_minimal(base_size = 13) +
    labs(title = paste0("ΔBIC surface (r=1) | ", det_tag), x = "p", y = "q profile", fill = "ΔBIC")
  save_fig(g1, file.path(fig_dir, "FIG_dBIC_surface.png"))
  
  g2 <- ggplot(plot_df, aes(x = k_total, y = -2*logLik, color = stability_margin)) +
    geom_point(alpha = 0.85) +
    theme_minimal(base_size = 13) +
    labs(title = paste0("Likelihood–complexity frontier | ", det_tag), x = "k_total", y = "-2 logLik", color = "stability_margin")
  save_fig(g2, file.path(fig_dir, "FIG_ll_frontier.png"))
  
  g3 <- ggplot(plot_df, aes(x = factor(p), y = q_tag, fill = theta_hat)) +
    geom_tile() +
    theme_minimal(base_size = 13) +
    labs(title = paste0("θ̂ surface (β normalized on lnY) | ", det_tag), x = "p", y = "q profile", fill = "θ̂")
  save_fig(g3, file.path(fig_dir, "FIG_theta_surface.png"))
  
  g4 <- ggplot(plot_df, aes(x = factor(p), y = q_tag, fill = stability_margin)) +
    geom_tile() +
    theme_minimal(base_size = 13) +
    labs(title = paste0("Stability margin surface | ", det_tag), x = "p", y = "q profile", fill = "margin")
  save_fig(g4, file.path(fig_dir, "FIG_stability_margin_surface.png"))
  
  feat_cols <- c("dBIC","theta_hat","alpha_y","alpha_k","share_Y","stability_margin")
  p_pca <- plot_pca_embedding(plot_df, feat_cols, "dBIC_band", paste0("PCA embedding | ", det_tag))
  if (!is.null(p_pca)) {
    save_fig(p_pca, file.path(fig_dir, "FIG_embedding_pca.png"))
  } else {
    p_mds <- plot_mds_embedding(plot_df, feat_cols, "dBIC_band", paste0("MDS embedding | ", det_tag))
    if (!is.null(p_mds)) save_fig(p_mds, file.path(fig_dir, "FIG_embedding_mds.png"))
  }
  
  # ---- ECT overlay (representatives)
  rep_best <- plot_df |> filter(stable_ok) |> arrange(BIC) |> slice(1)
  rep_stab <- plot_df |> filter(stable_ok) |> arrange(desc(stability_margin)) |> slice(1)
  rep_theta <- plot_df |> filter(stable_ok) |> mutate(dtheta = abs(theta_hat - THETA_ARDL_REF)) |> arrange(dtheta) |> slice(1)
  reps <- bind_rows(rep_best, rep_stab, rep_theta) |> distinct(p, .keep_all = TRUE) |> slice(1:min(4, n()))
  
  ect_bank <- list()
  for (i in seq_len(nrow(reps))) {
    p0 <- reps$p[i]
    b0 <- beta_by_p[[as.character(p0)]]
    ect0 <- compute_ect_series(X, b0, LRinclude, T_window)
    ect_df <- tibble(
      year = df$year, ECT = ect0, series = paste0("p=", p0),
      window_tag = WINDOW_TAG, window_start = dat$window_start, window_end = dat$window_end
    )
    ect_bank[[i]] <- ect_df
    safe_write_csv(ect_df, file.path(ect_dir, paste0("ECT_p", sprintf("%02d", p0), ".csv")))
  }
  
  ect_plot_df <- bind_rows(ect_bank)
  g6 <- ggplot(ect_plot_df, aes(x = year, y = ECT, color = series)) +
    geom_line(alpha = 0.85) +
    theme_minimal(base_size = 13) +
    labs(title = paste0("ECT overlay (representatives) | ", det_tag), x = NULL, y = "ECT")
  save_fig(g6, file.path(fig_dir, "FIG_ect_overlay_representatives.png"), w = 11, h = 6)
  
  # ---- Gated roots diagnostic
  if (nrow(eig_long) > 0) {
    top_band <- plot_df |>
      filter(dBIC <= DELTA_IC_BAND) |>
      select(cell_id, unit_root_mismatch, unstable_count)
    
    need_diag <- any(top_band$unit_root_mismatch != 0, na.rm = TRUE) || any(top_band$unstable_count > 0, na.rm = TRUE)
    if (isTRUE(need_diag)) {
      diag_cells <- top_band |>
        mutate(score = abs(unit_root_mismatch) + unstable_count) |>
        arrange(desc(score)) |>
        slice(1:min(6, n())) |>
        pull(cell_id)
      
      eig_sub <- eig_long |> filter(cell_id %in% diag_cells)
      gR <- plot_roots_overlay(eig_sub, title = paste0("Roots overlay (diagnostic) | ", det_tag))
      save_fig(gR, file.path(fig_dir, "FIG_roots_overlay_topcells.png"))
    }
  }
  
  writeLines(c(
    "% Auto-generated stubs (Stage S1)",
    paste0("% det_tag: ", det_tag),
    paste0("% Outputs in: ", base_dir),
    ""
  ), con = file.path(tex_dir, "README_TEX_STUBS.tex"))
  
  invisible(list(det_tag = det_tag, out = base_dir, run_id = run_id))
}

# ============================================================
# RUN ALL BRANCHES
# ============================================================
dat <- load_shaikh_window()
df <- dat$df
X  <- dat$X
T_window <- dat$T_window
m <- dat$m

message("Loaded shaikh window: ", dat$window[1], "-", dat$window[2], " | T=", T_window)
message("Output root: ", out_root)

for (sr in SR_SET) {
  for (lr in LR_SET) {
    message("--- Running branch: SR=", sr, " LR=", lr)
    run_branch(df, X, T_window, m, sr, lr)
  }
}

message("Stage S1 completed across all SR/LR branches.")

manifest_dir <- here::here(CONFIG$OUT_CR$manifest %||% "output/CriticalReplication/Manifest")
dir.create(manifest_dir, recursive = TRUE, showWarnings = FALSE)
manifest_path <- file.path(manifest_dir, "RUN_MANIFEST_stage4.md")
cat(
  paste0(
    "# Run Manifest (Stage 4)\n",
    "- window_tag: ", WINDOW_TAG, "\n",
    "- window_start: ", dat$window_start, "\n",
    "- window_end: ", dat$window_end, "\n\n",
    "## Script: codes/22_VECM_S1.R\n",
    "- exercise_output: output/CriticalReplication/Exercise_c_VECM_S1_r1/\n",
    "- window_tag: ", WINDOW_TAG, "\n",
    "- window_start: ", dat$window_start, "\n",
    "- window_end: ", dat$window_end, "\n",
    "- p_range: ", P_MIN, "..", P_MAX, "\n",
    "- Timestamp: ", Sys.time(), "\n\n"
  ),
  file = manifest_path,
  append = TRUE
)
