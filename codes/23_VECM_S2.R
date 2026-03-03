# ============================================================
# 23_VECM_S2.R
# Self-Discovery Process — VECM Stage (S2: lnY, lnK, e)
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

source(here::here("codes","10_config.R"))
source(here::here("codes","99_utils.R"))
source(here::here("codes","24_complexity_penalties.R"))
source(here::here("codes","25_envelope_tools.R"))

set.seed(CONFIG$seed %||% 123)

WINDOW_TAG <- "shaikh_window"
STATE_TAG  <- "S2_lnY_lnK_e"

P_MIN <- as.integer(max(1L, CONFIG$P_MIN %||% 1L))
P_MAX <- as.integer(max(P_MIN, CONFIG$P_MAX_EXPLORATORY %||% 7L))
SR_SET <- c("none", "const")
LR_SET <- c("none", "const", "trend", "both")
R_SET  <- 0:2
TOL_UNIT <- 1e-3
ETA_GRID <- c(1, 1.5, 2, 3, 4, 6, 8)

out_root <- here::here(CONFIG$OUT_CR$exercise_d %||% "output/CriticalReplication/Exercise_d_VECM_S2_m3_rank")

make_branch_dirs <- function(det_tag) {
  base <- file.path(out_root, det_tag)
  sub <- c("csv","figs","tex","logs","cache","ect")
  for (s in sub) dir.create(file.path(base, s), recursive = TRUE, showWarnings = FALSE)
  base
}

log_run <- function(log_dir, msg) {
  idx_path <- file.path(log_dir, "RUN_INDEX.csv")
  idx <- if (file.exists(idx_path)) tryCatch(read.csv(idx_path, stringsAsFactors = FALSE), error = function(e) NULL) else NULL
  run_id <- if (is.null(idx) || nrow(idx) == 0) 1L else max(idx$run_id, na.rm = TRUE) + 1L
  row <- data.frame(run_id = run_id, timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), message = msg, stringsAsFactors = FALSE)
  if (is.null(idx)) write.csv(row, idx_path, row.names = FALSE) else write.csv(rbind(idx, row), idx_path, row.names = FALSE)
  writeLines(paste0("[", row$timestamp, "] ", msg), con = file.path(log_dir, sprintf("RUN_%03d.txt", run_id)))
  run_id
}

load_shaikh_window_s2 <- function() {
  df_raw <- readxl::read_excel(here::here(CONFIG$data_shaikh), sheet = CONFIG$data_shaikh_sheet)
  needed <- c(CONFIG$year_col, CONFIG$y_nom, CONFIG$k_nom, CONFIG$p_index, CONFIG$e_rate)
  stopifnot(all(needed %in% names(df_raw)))

  df <- df_raw |>
    transmute(
      year  = as.integer(.data[[CONFIG$year_col]]),
      Y_nom = as.numeric(.data[[CONFIG$y_nom]]),
      K_nom = as.numeric(.data[[CONFIG$k_nom]]),
      p     = as.numeric(.data[[CONFIG$p_index]]),
      e     = as.numeric(.data[[CONFIG$e_rate]])
    ) |>
    filter(is.finite(year), is.finite(Y_nom), is.finite(K_nom), is.finite(p), p > 0, is.finite(e)) |>
    mutate(
      p_scale = p / 100,
      Y_real  = Y_nom / p_scale,
      K_real  = K_nom / p_scale,
      lnY     = log(Y_real),
      lnK     = log(K_real)
    ) |>
    filter(is.finite(lnY), is.finite(lnK), is.finite(e)) |>
    arrange(year)

  w <- CONFIG$WINDOWS_LOCKED[[WINDOW_TAG]]
  if (is.null(w) || length(w) != 2) stop("WINDOW_TAG not found in CONFIG$WINDOWS_LOCKED", call. = FALSE)

  df <- df |> filter(year >= w[1], year <= w[2]) |> arrange(year)
  X <- as.matrix(df[, c("lnY", "lnK", "e")])
  colnames(X) <- c("lnY", "lnK", "e")

  list(df = df, X = X, T_window = nrow(X), m = ncol(X), window = w, window_start = as.integer(w[1]), window_end = as.integer(w[2]))
}

k_pi <- function(r, m, lr) {
  r <- as.integer(r); m <- as.integer(m)
  d_lr <- det_count(resolve_LRinclude(lr))
  r * (2L * m - r) + r * d_lr
}

k_gamma <- function(q_vec, m) {
  m <- as.integer(m)
  q_vec <- as.integer(q_vec)
  m * sum(q_vec)
}

k_det_sr <- function(m, sr) {
  m * det_count(resolve_include(sr))
}

k_sigma <- function(m) as.integer(m * (m + 1L) / 2L)

ic_panel <- function(ll, k, T_eff_common) {
  core <- -2 * ll
  AIC  <- core + 2 * k
  BIC  <- core + log(T_eff_common) * k
  HQ   <- core + 2 * log(log(T_eff_common)) * k
  denom <- T_eff_common - k - 1
  AICc <- if (is.finite(denom) && denom > 0) AIC + (2 * k * (k + 1)) / denom else NA_real_
  tibble(AIC = AIC, BIC = BIC, HQ = HQ, AICc = AICc)
}

ic_eta <- function(ll, T_eff_common, k_gamma, k_pi, k_det, k_sigma, eta) {
  -2 * ll + log(T_eff_common) * (k_gamma + eta * k_pi + k_det + k_sigma)
}

q_profiles_for_p <- function(p) {
  p <- as.integer(p)
  tibble(
    q_tag = c("sym", "Y_only", "K_only", "E_only", "Y_short", "K_short", "E_short"),
    qY = c(p, p, 0, 0, min(1L, p), p, p),
    qK = c(p, 0, p, 0, p, min(1L, p), p),
    qE = c(p, 0, 0, p, p, p, min(1L, p))
  )
}

cell_id <- function(p, q_tag, r, sr, lr) sprintf("p%02d_%s_r%d_%s_%s", as.integer(p), q_tag, as.integer(r), sr, lr)

extract_beta_alpha <- function(fit, r, m) {
  beta <- tryCatch(tsDyn::coefB(fit), error = function(e) NULL)
  alpha <- tryCatch(tsDyn::coefA(fit), error = function(e) NULL)
  if (is.null(beta) || is.null(alpha)) return(NULL)
  beta <- as.matrix(beta); alpha <- as.matrix(alpha)
  if (nrow(beta) != m && ncol(beta) == m) beta <- t(beta)
  if (nrow(alpha) != m && ncol(alpha) == m) alpha <- t(alpha)
  if (nrow(beta) < m || nrow(alpha) < m) return(NULL)
  beta <- beta[1:m, seq_len(min(r, ncol(beta))), drop = FALSE]
  alpha <- alpha[1:m, seq_len(min(r, ncol(alpha))), drop = FALSE]
  if (ncol(beta) != r || ncol(alpha) != r) return(NULL)
  list(beta = beta, alpha = alpha)
}

build_restricted_design <- function(X, beta, p, q_vec, sr) {
  X <- as.matrix(X)
  T <- nrow(X); m <- ncol(X)
  dX <- apply(X, 2, diff)
  t_idx <- (p + 2):T
  Te <- length(t_idx)
  if (Te < 8) stop("Too few effective obs")

  Ydep <- dX[t_idx - 1, , drop = FALSE]
  ect <- X %*% beta
  Z_list <- list()
  for (j in seq_len(ncol(beta))) Z_list[[paste0("ECT", j)]] <- ect[t_idx - 1, j]

  q_vec <- pmax(0L, pmin(as.integer(p), as.integer(q_vec)))
  var_names <- colnames(X)
  for (i in seq_len(p)) {
    lag_row <- (t_idx - 1) - i
    for (v in seq_len(m)) {
      if (i <= q_vec[v]) {
        Z_list[[paste0("d", var_names[v], "_L", i)]] <- dX[lag_row, v]
      }
    }
  }

  inc <- resolve_include(sr)
  if (inc %in% c("const", "both")) Z_list[["const"]] <- rep(1, Te)
  if (inc %in% c("trend", "both")) Z_list[["trend"]] <- seq_along(t_idx)

  Z <- do.call(cbind, Z_list)
  list(Z = as.matrix(Z), Y = as.matrix(Ydep), Te = Te)
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
  - (Te * m / 2) * (1 + log(2 * pi)) - (Te / 2) * log(detS)
}

extract_gamma_list <- function(B, p, q_vec, var_names) {
  m <- length(var_names)
  G <- vector("list", p)
  q_vec <- as.integer(q_vec)
  for (i in seq_len(p)) {
    Gi <- matrix(0, nrow = m, ncol = m)
    for (v in seq_len(m)) {
      rn <- paste0("d", var_names[v], "_L", i)
      if (i <= q_vec[v] && rn %in% rownames(B)) Gi[, v] <- B[rn, ]
    }
    G[[i]] <- Gi
  }
  G
}

companion_roots <- function(Pi, Gamma_list, tol_unit = 1e-3) {
  m <- nrow(Pi); p <- length(Gamma_list); k <- p + 1L
  I <- diag(m)
  A <- vector("list", k)
  A[[1]] <- I + Pi + if (p >= 1) Gamma_list[[1]] else 0
  if (k >= 2) {
    for (i in 2:k) {
      Gi <- if (i <= p) Gamma_list[[i]] else matrix(0, m, m)
      Gim1 <- if (i - 1 <= p) Gamma_list[[i - 1]] else matrix(0, m, m)
      A[[i]] <- Gi - Gim1
    }
  }
  C <- matrix(0, nrow = m * k, ncol = m * k)
  C[1:m, 1:(m * k)] <- do.call(cbind, A)
  if (k > 1) C[(m + 1):(m * k), 1:(m * (k - 1))] <- diag(m * (k - 1))

  eig <- eigen(C, only.values = TRUE)$values
  mod <- Mod(eig)
  list(
    eig = eig,
    unit_root_count = sum(abs(mod - 1) <= tol_unit),
    unstable_count = sum(mod > 1 + tol_unit),
    stability_margin = {
      nonunit <- mod[abs(mod - 1) > tol_unit]
      if (length(nonunit) == 0) NA_real_ else 1 - max(nonunit)
    }
  )
}

fit_ranked_cell <- function(X, p, r, sr, lr, q_vec) {
  m <- ncol(X)
  include <- resolve_include(sr)
  LRinclude <- resolve_LRinclude(lr)

  if (r == 0L) {
    null_fit <- fit_sigma0_var_diff(X_level = X, p_vecm = p, include = include)
    if (!isTRUE(null_fit$ok)) {
      return(c(list(status = "runtime_fail"), null_fit[c("fail_code", "fail_msg")]))
    }
    kG <- k_gamma(q_vec = q_vec, m = m)
    kPi <- 0L
    kDet <- k_det_sr(m = m, sr = sr)
    kSig <- k_sigma(m)
    kTot <- kG + kPi + kDet + kSig
    return(list(
      status = "computed", fail_code = NA_character_, fail_msg = NA_character_,
      logLik = as.numeric(null_fit$ll), Sigma = as.matrix(null_fit$Sigma0), T_eff = as.integer(null_fit$T_eff),
      alpha = matrix(0, nrow = m, ncol = 0), beta = matrix(0, nrow = m, ncol = 0), Pi = matrix(0, nrow = m, ncol = m),
      roots = list(eig = complex(0), unit_root_count = NA_integer_, unstable_count = NA_integer_, stability_margin = NA_real_),
      k_gamma = kG, k_pi = kPi, k_det = kDet, k_sigma = kSig, k_total = kTot,
      model_class = "VAR_diff_r0"
    ))
  }

  fit_ml <- tryCatch(
    tsDyn::VECM(data = X, lag = as.integer(p), r = as.integer(r), include = include, LRinclude = LRinclude, estim = "ML"),
    error = function(e) e
  )
  if (inherits(fit_ml, "error")) {
    return(list(status = "runtime_fail", fail_code = "VECM_FAIL", fail_msg = truncate_msg(conditionMessage(fit_ml), 240)))
  }

  ll_ml <- tsdyn_loglik(fit_ml)
  if (!is.finite(ll_ml)) {
    return(list(status = "runtime_fail", fail_code = "LOGLIK_NA", fail_msg = "Non-finite VECM logLik"))
  }

  ab <- extract_beta_alpha(fit_ml, r = r, m = m)
  if (is.null(ab)) {
    return(list(status = "runtime_fail", fail_code = "ALPHA_BETA_FAIL", fail_msg = "Could not extract alpha/beta"))
  }

  design <- tryCatch(build_restricted_design(X, beta = ab$beta, p = p, q_vec = q_vec, sr = sr), error = function(e) e)
  if (inherits(design, "error")) {
    return(list(status = "runtime_fail", fail_code = "DESIGN_FAIL", fail_msg = truncate_msg(conditionMessage(design), 240)))
  }

  fit_ols <- tryCatch(ols_multivar(design$Z, design$Y), error = function(e) e)
  if (inherits(fit_ols, "error")) {
    return(list(status = "runtime_fail", fail_code = "OLS_FAIL", fail_msg = truncate_msg(conditionMessage(fit_ols), 240)))
  }

  ll <- gaussian_loglik(fit_ols$U)
  Sigma <- crossprod(fit_ols$U) / nrow(fit_ols$U)
  if (!is.finite(ll) || any(!is.finite(Sigma))) {
    return(list(status = "runtime_fail", fail_code = "SIGMA_FAIL", fail_msg = "Invalid OLS likelihood/covariance"))
  }

  Pi <- ab$alpha %*% t(ab$beta)
  Gamma_list <- extract_gamma_list(B = fit_ols$B, p = p, q_vec = q_vec, var_names = colnames(X))
  roots <- companion_roots(Pi = Pi, Gamma_list = Gamma_list, tol_unit = TOL_UNIT)

  kG <- k_gamma(q_vec = q_vec, m = m)
  kPi <- k_pi(r = r, m = m, lr = lr)
  kDet <- k_det_sr(m = m, sr = sr)
  kSig <- k_sigma(m)
  kTot <- kG + kPi + kDet + kSig

  list(
    status = "computed", fail_code = NA_character_, fail_msg = NA_character_,
    logLik = ll, Sigma = Sigma, T_eff = as.integer(nrow(fit_ols$U)),
    alpha = ab$alpha, beta = ab$beta, Pi = Pi, roots = roots,
    k_gamma = kG, k_pi = kPi, k_det = kDet, k_sigma = kSig, k_total = kTot,
    model_class = "VECM_ranked_qrestricted"
  )
}

emit_mandatory_planes_s2 <- function(geom_df, csv_dir, fig_dir, tag = "S2") {
  dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

  planes <- list(c("k_total", "logLik"), c("ICOMP_pen", "logLik"), c("RICOMP_pen", "logLik"))
  for (xy in planes) {
    x <- xy[1]; y <- xy[2]
    write_envelope_plane(
      geom_df, x_col = x, y_col = y,
      csv_path = file.path(csv_dir, sprintf("ENVELOPE_%s_vs_%s.csv", y, x)),
      fig_path = file.path(fig_dir, sprintf("FIG_envelope_%s_vs_%s.png", y, x)),
      title = paste0("Envelope: ", y, " vs ", x, " | ", tag)
    )
  }
}

run_branch <- function(dat, sr, lr) {
  include <- resolve_include(sr)
  LRinclude <- resolve_LRinclude(lr)

  if (include == "const" && LRinclude %in% c("const", "both")) {
    det_tag_skip <- det_tag_from(include, LRinclude)
    base_dir_skip <- make_branch_dirs(det_tag_skip)
    log_run(file.path(base_dir_skip, "logs"), sprintf("SKIPPED: invalid tsDyn deterministic combo SR=%s LR=%s", include, LRinclude))
    return(invisible(NULL))
  }

  det_tag <- det_tag_from(include, LRinclude)
  base_dir <- make_branch_dirs(det_tag)
  csv_dir <- file.path(base_dir, "csv")
  fig_dir <- file.path(base_dir, "figs")
  log_dir <- file.path(base_dir, "logs")
  run_id <- log_run(log_dir, sprintf("Stage S2 run: SR=%s LR=%s P=%d..%d", include, LRinclude, P_MIN, P_MAX))

  X <- dat$X; m <- ncol(X); T_window <- nrow(X)
  T_eff_common <- as.integer(max(20L, T_window - (P_MAX + 1L)))

  rows <- list(); eig_rows <- list(); alpha_beta_rows <- list()

  for (p in P_MIN:P_MAX) {
    qprof <- q_profiles_for_p(p)
    for (iq in seq_len(nrow(qprof))) {
      qY <- as.integer(max(0L, min(p, qprof$qY[iq])))
      qK <- as.integer(max(0L, min(p, qprof$qK[iq])))
      qE <- as.integer(max(0L, min(p, qprof$qE[iq])))
      q_vec <- c(qY, qK, qE)
      q_tag <- qprof$q_tag[iq]

      for (r in R_SET) {
        cid <- cell_id(p, q_tag, r, include, LRinclude)
        fit <- fit_ranked_cell(X = X, p = p, r = r, sr = include, lr = LRinclude, q_vec = q_vec)

        if (!identical(fit$status, "computed")) {
          rows[[length(rows) + 1]] <- tibble(
            run_id = run_id, det_tag = det_tag, cell_id = cid, status = fit$status,
            include = include, LRinclude = LRinclude,
            p = p, r = r, q_tag = q_tag, qY = qY, qK = qK, qE = qE,
            model_class = NA_character_, logLik = NA_real_, T_eff = NA_real_, T_eff_common = T_eff_common,
            k_gamma = NA_real_, k_pi = NA_real_, k_det = NA_real_, k_sigma = NA_real_, k_total = NA_real_,
            ICOMP_pen = NA_real_, RICOMP_pen = NA_real_,
            ICOMP_flag = NA_character_, RICOMP_flag = NA_character_,
            ICOMP_stabilized = NA, RICOMP_stabilized = NA,
            AIC = NA_real_, BIC = NA_real_, HQ = NA_real_, AICc = NA_real_,
            stability_margin = NA_real_, unit_root_count = NA_real_, unstable_count = NA_real_,
            expected_unit_roots = m - r, unit_root_mismatch = NA_real_,
            fail_code = fit$fail_code %||% "UNKNOWN", fail_msg = fit$fail_msg %||% ""
          )
          next
        }

        comp_row <- compute_complexity_record(model_class = fit$model_class, logLik = fit$logLik, k_total = fit$k_total, vcov_mat = fit$Sigma, T_eff = fit$T_eff)
        ic <- ic_panel(fit$logLik, fit$k_total, T_eff_common)

        unit_mismatch <- if (is.finite(fit$roots$unit_root_count)) abs(fit$roots$unit_root_count - (m - r)) else NA_real_

        rows[[length(rows) + 1]] <- tibble(
          run_id = run_id, det_tag = det_tag, cell_id = cid, status = "computed",
          include = include, LRinclude = LRinclude,
          p = p, r = r, q_tag = q_tag, qY = qY, qK = qK, qE = qE,
          model_class = fit$model_class,
          logLik = fit$logLik, T_eff = fit$T_eff, T_eff_common = T_eff_common,
          k_gamma = fit$k_gamma, k_pi = fit$k_pi, k_det = fit$k_det, k_sigma = fit$k_sigma, k_total = fit$k_total,
          ICOMP_pen = comp_row$ICOMP_pen, RICOMP_pen = comp_row$RICOMP_pen,
          ICOMP_flag = comp_row$ICOMP_flag, RICOMP_flag = comp_row$RICOMP_flag,
          ICOMP_stabilized = comp_row$ICOMP_stabilized, RICOMP_stabilized = comp_row$RICOMP_stabilized,
          AIC = ic$AIC, BIC = ic$BIC, HQ = ic$HQ, AICc = ic$AICc,
          stability_margin = fit$roots$stability_margin,
          unit_root_count = fit$roots$unit_root_count,
          unstable_count = fit$roots$unstable_count,
          expected_unit_roots = m - r,
          unit_root_mismatch = unit_mismatch,
          fail_code = NA_character_, fail_msg = NA_character_
        )

        if (r > 0 && ncol(fit$alpha) > 0) {
          for (j in seq_len(ncol(fit$alpha))) {
            alpha_beta_rows[[length(alpha_beta_rows) + 1]] <- tibble(
              run_id = run_id, det_tag = det_tag, cell_id = cid, p = p, r = r, q_tag = q_tag,
              relation = j,
              alpha_lnY = fit$alpha[1, j], alpha_lnK = fit$alpha[2, j], alpha_e = fit$alpha[3, j],
              beta_lnY = fit$beta[1, j], beta_lnK = fit$beta[2, j], beta_e = fit$beta[3, j]
            )
          }
        }

        if (r > 0 && length(fit$roots$eig) > 0) {
          eig_rows[[length(eig_rows) + 1]] <- tibble(
            run_id = run_id, det_tag = det_tag, cell_id = cid, p = p, r = r, q_tag = q_tag,
            eig_id = seq_along(fit$roots$eig),
            Re = Re(fit$roots$eig), Im = Im(fit$roots$eig), Mod = Mod(fit$roots$eig)
          )
        }
      }
    }
  }

  cells <- bind_rows(rows) |> mutate(window_tag = WINDOW_TAG, window_start = dat$window_start, window_end = dat$window_end)
  safe_write_csv(cells, file.path(csv_dir, "APPX_lattice_cells.csv"))

  cells2 <- cells |> filter(status == "computed")
  if (nrow(cells2) > 0) {
    cells2 <- cells2 |> mutate(
      dBIC = BIC - min(BIC, na.rm = TRUE),
      dAIC = AIC - min(AIC, na.rm = TRUE),
      dHQ = HQ - min(HQ, na.rm = TRUE)
    )
  }
  safe_write_csv(cells2, file.path(csv_dir, "APPX_lattice_cells_with_deltas.csv"))

  eta_long <- if (nrow(cells2) > 0) {
    cells2 |>
      tidyr::expand_grid(eta = ETA_GRID) |>
      mutate(IC_eta = ic_eta(logLik, T_eff_common, k_gamma, k_pi, k_det, k_sigma, eta))
  } else tibble()
  safe_write_csv(eta_long, file.path(csv_dir, "APPX_ic_eta_long.csv"))

  if (length(eig_rows) > 0) safe_write_csv(bind_rows(eig_rows), file.path(csv_dir, "APPX_eigs_long.csv"))
  if (length(alpha_beta_rows) > 0) safe_write_csv(bind_rows(alpha_beta_rows), file.path(csv_dir, "TAB_alpha_beta_by_rank.csv"))

  ledger <- if (nrow(cells2) > 0) {
    bind_rows(
      cells2 |> arrange(BIC) |> slice(1) |> mutate(criterion = "BIC"),
      cells2 |> arrange(AIC) |> slice(1) |> mutate(criterion = "AIC"),
      cells2 |> arrange(HQ) |> slice(1) |> mutate(criterion = "HQ"),
      cells2 |> arrange(ICOMP_pen) |> slice(1) |> mutate(criterion = "ICOMP"),
      cells2 |> arrange(RICOMP_pen) |> slice(1) |> mutate(criterion = "RICOMP")
    ) |> select(criterion, run_id, det_tag, include, LRinclude, cell_id, p, q_tag, qY, qK, qE, r, logLik, AIC, BIC, HQ, ICOMP_pen, RICOMP_pen)
  } else tibble()
  safe_write_csv(ledger, file.path(csv_dir, "TAB_top_spec_selection_ledger.csv"))

  if (nrow(cells2) > 0) {
    summary_by_rank <- cells2 |> group_by(r) |> summarise(best_BIC = min(BIC, na.rm = TRUE), best_AIC = min(AIC, na.rm = TRUE), n_cells = n(), .groups = "drop")
    safe_write_csv(summary_by_rank, file.path(csv_dir, "TAB_summary_by_rank.csv"))
    summary_by_pqr <- cells2 |> group_by(p, q_tag, r) |> summarise(best_BIC = min(BIC, na.rm = TRUE), best_AIC = min(AIC, na.rm = TRUE), .groups = "drop")
    safe_write_csv(summary_by_pqr, file.path(csv_dir, "TAB_summary_by_p_q_r.csv"))

    emit_mandatory_planes_s2(cells2, csv_dir = csv_dir, fig_dir = fig_dir, tag = paste0("S2_", det_tag, "_allr"))
    for (rr in sort(unique(cells2$r))) {
      df_r <- cells2 |> filter(r == rr)
      emit_mandatory_planes_s2(df_r, csv_dir = file.path(csv_dir, paste0("rank_r", rr)), fig_dir = file.path(fig_dir, paste0("rank_r", rr)), tag = paste0("S2_", det_tag, "_r", rr))
    }
  }

  invisible(list(run_id = run_id, det_tag = det_tag, n_cells = nrow(cells), n_computed = nrow(cells2)))
}

dat <- load_shaikh_window_s2()
for (sr in SR_SET) {
  for (lr in LR_SET) {
    run_branch(dat, sr = sr, lr = lr)
  }
}

message("S2 run completed: ", out_root)
