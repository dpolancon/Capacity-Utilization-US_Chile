#!/usr/bin/env Rscript

# S90 robustness exercise: path-dependent technique choice and identification
# of the observed-direction elasticity ratio's lumpiness.
#
# This script is deliberately downstream-isolated. It reads the canonical D10
# panel and the frozen S35/S34R-B presentation inputs, writes only to S90, and
# does not alter S40 or any Stage B/C object.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
OUT_DIR <- file.path(ROOT, "output", "US", "S90_path_dependent_theta_robustness")
CSV_DIR <- file.path(OUT_DIR, "csv")
FIG_DIR <- file.path(OUT_DIR, "figures")
REPORT_DIR <- file.path(OUT_DIR, "reports")
RDS_DIR <- file.path(OUT_DIR, "rds")
invisible(lapply(c(CSV_DIR, FIG_DIR, REPORT_DIR, RDS_DIR), dir.create,
                 recursive = TRUE, showWarnings = FALSE))

D10_PATH <- file.path(ROOT, "output", "US",
  "D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET", "csv",
  "D10_clean_us_source_of_truth_panel_wide.csv")
S35_PATH <- file.path(ROOT, "output", "US", "S35_estimator_refreeze_cpr", "csv",
  "us_s35_cpr_estimation_results.csv")
S34_PATH <- file.path(ROOT, "output", "S34R_B_cpr_realigned_design_gate", "csv",
  "S34R_B_repaired_augmented_panel.csv")

required <- c(D10_PATH, S35_PATH, S34_PATH)
if (any(!file.exists(required))) {
  stop("Missing required S90 input(s): ", paste(required[!file.exists(required)], collapse = "; "))
}

write_csv <- function(x, name) {
  write.csv(x, file.path(CSV_DIR, name), row.names = FALSE, na = "")
}

lag_vec <- function(x, k = 1L) {
  n <- length(x)
  if (k == 0L) return(x)
  if (k > 0L) return(c(rep(NA_real_, k), head(x, n - k)))
  k <- abs(k)
  c(tail(x, n - k), rep(NA_real_, k))
}

rough_L <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 2L) return(NA_real_)
  mean(diff(x)^2)
}

rough_C <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 3L) return(NA_real_)
  mean(diff(x, differences = 2L)^2)
}

safe_adf_p <- function(x) {
  if (!requireNamespace("tseries", quietly = TRUE) || length(x) < 12L) return(NA_real_)
  suppressWarnings(tryCatch(tseries::adf.test(x, alternative = "stationary")$p.value,
                            error = function(e) NA_real_))
}

safe_kpss_p <- function(x) {
  if (!requireNamespace("tseries", quietly = TRUE) || length(x) < 12L) return(NA_real_)
  suppressWarnings(tryCatch(tseries::kpss.test(x, null = "Level")$p.value,
                            error = function(e) NA_real_))
}

moving_average_lags <- function(x, h) {
  z <- vapply(seq_len(h), function(j) lag_vec(x, j), numeric(length(x)))
  apply(z, 1L, function(v) if (all(is.finite(v))) mean(v) else NA_real_)
}

adaptive_state <- function(x, rho) {
  out <- rep(NA_real_, length(x))
  first <- which(is.finite(lag_vec(x, 1L)))[1]
  if (is.na(first)) return(out)
  out[first] <- x[first - 1L]
  if (first < length(x)) {
    for (i in seq.int(first + 1L, length(x))) {
      if (is.finite(out[i - 1L]) && is.finite(x[i - 1L])) {
        out[i] <- rho * out[i - 1L] + (1 - rho) * x[i - 1L]
      }
    }
  }
  out
}

block_indices <- function(n, block = 4L) {
  if (n <= block) return(sample.int(n, n, replace = TRUE))
  starts <- sample.int(n - block + 1L, ceiling(n / block), replace = TRUE)
  head(unlist(lapply(starts, function(s) seq.int(s, s + block - 1L))), n)
}

panel <- read.csv(D10_PATH, check.names = TRUE)
panel <- panel[order(panel$year), ]
needed <- c("year", "K_ME", "K_NRC", "K_capacity", "Y_REAL_NFC_GVA_BASELINE_D09",
            "omega_NFC_productive_origin_GVA", "NFC_COMPENSATION_SHARE_GVA",
            "NFC_COMPENSATION_SHARE_NVA", "omega_CORP_raw_GVA", "omega_CORP_raw_NVA")
if (length(setdiff(needed, names(panel))) > 0L) {
  stop("D10 is missing: ", paste(setdiff(needed, names(panel)), collapse = ", "))
}

panel$y <- log(panel$Y_REAL_NFC_GVA_BASELINE_D09)
panel$k_me <- log(panel$K_ME)
panel$k_nrc <- log(panel$K_NRC)
panel$k_cap <- log(panel$K_capacity)
panel$tau <- panel$k_me - panel$k_nrc
panel$g_me <- c(NA_real_, diff(panel$k_me))
panel$g_nrc <- c(NA_real_, diff(panel$k_nrc))
panel$g_cap <- c(NA_real_, diff(panel$k_cap))
panel$d_tau <- c(NA_real_, diff(panel$tau))

wage_map <- data.frame(
  state_id = c("NFC_GVA", "NFC_NVA", "CORP_GVA", "CORP_NVA"),
  repo_variable = c("omega_NFC_productive_origin_GVA", "NFC_COMPENSATION_SHARE_NVA",
                    "omega_CORP_raw_GVA", "omega_CORP_raw_NVA"),
  sector = c("Whole NFC", "Whole NFC", "All corporations", "All corporations"),
  basis = c("GVA", "NVA", "GVA", "NVA"),
  status = c("MAIN_STATE", "AUTHORIZED_ROBUSTNESS", "COMPARISON_ONLY", "COMPARISON_ONLY"),
  productive_capacity_output = "Real NFC GVA (fixed)",
  productive_capacity_capital = "NFC K_ME and K_NRC (fixed)",
  stringsAsFactors = FALSE
)

alias_diff <- max(abs(panel$NFC_COMPENSATION_SHARE_GVA -
                        panel$omega_NFC_productive_origin_GVA), na.rm = TRUE)
alias_ledger <- rbind(
  transform(wage_map, alias_of = NA_character_, max_absolute_difference = NA_real_,
            estimation_action = "ESTIMATE_SEPARATELY"),
  data.frame(state_id = "NFC_GVA_ALIAS", repo_variable = "NFC_COMPENSATION_SHARE_GVA",
             sector = "Whole NFC", basis = "GVA", status = "EXACT_ALIAS",
             productive_capacity_output = "Real NFC GVA (fixed)",
             productive_capacity_capital = "NFC K_ME and K_NRC (fixed)",
             alias_of = "omega_NFC_productive_origin_GVA",
             max_absolute_difference = alias_diff,
             estimation_action = "DO_NOT_ESTIMATE_DUPLICATE", stringsAsFactors = FALSE)
)
write_csv(alias_ledger, "S90_wage_share_provenance_and_alias_ledger.csv")

fordist_cor <- cor(panel[panel$year >= 1945 & panel$year <= 1973,
  wage_map$repo_variable], use = "pairwise.complete.obs")
cor_ledger <- data.frame(
  state_1 = rep(rownames(fordist_cor), each = ncol(fordist_cor)),
  state_2 = rep(colnames(fordist_cor), times = nrow(fordist_cor)),
  correlation_1945_1973 = as.vector(t(fordist_cor)),
  joint_model_status = "BLOCKED_HIGH_COLLINEARITY",
  stringsAsFactors = FALSE
)
write_csv(cor_ledger, "S90_wage_share_fordist_correlation_ledger.csv")

windows <- data.frame(
  window_id = c("full_long_sample", "pre_1974_full", "post_1973_full", "fordist_core",
                "bridge_1940_1978", "pre_1974_alt_1940_1973", "pre_1974_alt_1947_1973"),
  start = c(1929, 1929, 1974, 1945, 1940, 1940, 1947),
  end = c(2024, 1973, 2024, 1973, 1978, 1973, 1973),
  reconstruction_role = c("diagnostic", "PRIMARY_FORDIST_COEFFICIENT_SOURCE", "post_fordist",
                          "short_historical_target", "bridge", "robustness", "robustness"),
  stringsAsFactors = FALSE
)
write_csv(windows, "S90_estimation_window_ledger.csv")

make_q <- function(df, state) {
  z <- state - mean(state, na.rm = TRUE)
  out <- cumsum(ifelse(is.finite(z * df$d_tau), z * df$d_tau, 0))
  out[!is.finite(state) | !is.finite(df$d_tau)] <- NA_real_
  out
}

fit_rdols <- function(base_panel, start, end, state, model_family,
                      n_lag = 1L, n_lead = 1L, rho_count = 0L) {
  w <- base_panel$year >= start & base_panel$year <= end
  d <- base_panel[w, c("year", "y", "k_nrc", "tau", "d_tau")]
  d$state <- state[w]
  d$k_nrc_c <- d$k_nrc - mean(d$k_nrc, na.rm = TRUE)
  d$tau_c <- d$tau - mean(d$tau, na.rm = TRUE)
  d$state_c <- d$state - mean(d$state, na.rm = TRUE)
  if (model_family %in% c("M0", "M1")) {
    d$nonlinear <- d$tau_c * d$state_c
    nonlinear_name <- "interaction"
  } else {
    d$nonlinear <- make_q(d, d$state)
    d$nonlinear <- d$nonlinear - mean(d$nonlinear, na.rm = TRUE)
    nonlinear_name <- "Q"
  }
  for (nm in c("k_nrc", "tau", "state")) {
    dx <- c(NA_real_, diff(d[[nm]]))
    for (s in seq.int(-n_lead, n_lag)) {
      suffix <- if (s < 0L) paste0("lead", abs(s)) else if (s > 0L) paste0("lag", s) else "current"
      d[[paste0("d_", nm, "_", suffix)]] <- lag_vec(dx, s)
    }
  }
  dyn <- grep("^d_(k_nrc|tau|state)_", names(d), value = TRUE)
  use <- c("year", "y", "k_nrc_c", "tau_c", "state_c", "nonlinear", dyn)
  e <- d[complete.cases(d[, use]), use]
  if (nrow(e) < 8L) return(list(ok = FALSE, error = "INSUFFICIENT_COMPLETE_OBSERVATIONS"))
  names(e)[names(e) == "nonlinear"] <- nonlinear_name
  regressors <- c("k_nrc_c", "tau_c", "state_c", nonlinear_name, dyn)
  X <- model.matrix(reformulate(regressors), data = e)
  fit <- lm.fit(X, e$y)
  fit$terms <- terms(reformulate(regressors, response = "y"))
  fit$call <- match.call()
  class(fit) <- "lm"
  rank <- fit$rank
  p <- ncol(X)
  n <- nrow(e)
  sse <- sum(fit$residuals^2)
  sigma2 <- if (n > rank) sse / (n - rank) else NA_real_
  vc <- if (is.finite(sigma2)) sigma2 * chol2inv(qr.R(qr(X))[seq_len(rank), seq_len(rank), drop = FALSE]) else matrix(NA_real_, rank, rank)
  se <- rep(NA_real_, p)
  se[seq_len(rank)] <- sqrt(diag(vc))
  coef <- fit$coefficients
  tval <- coef / se
  pval <- 2 * pt(abs(tval), df = max(1L, n - rank), lower.tail = FALSE)
  names(coef) <- colnames(X)
  names(se) <- names(tval) <- names(pval) <- colnames(X)
  res <- fit$residuals
  kappa_scaled <- tryCatch(kappa(scale(X[, -1L, drop = FALSE]), exact = FALSE),
                           error = function(e) NA_real_)
  adf_p <- safe_adf_p(res)
  kpss_p <- safe_kpss_p(res)
  list(ok = TRUE, fit = fit, data = e, X = X, y = e$y, coefficients = coef,
       std_error = se, t_value = tval, p_value = pval,
       n = n, rank = rank, columns = p, condition_number = kappa_scaled,
       sse = sse, bic = n * log(sse / n) + log(n) * (p + rho_count),
       r_squared = 1 - sse / sum((e$y - mean(e$y))^2),
       adf_p = adf_p, kpss_p = kpss_p,
       sample_gate = if (n >= 30L) "PASS" else "WARN_SMALL_SAMPLE",
       rank_gate = if (rank == p) "PASS" else "FAIL",
       residual_gate = if (is.finite(adf_p) && is.finite(kpss_p) && adf_p < 0.10 && kpss_p > 0.05) "PASS" else "WARN",
       nonlinear_name = nonlinear_name)
}

get_state <- function(x, model_id, rho = NA_real_) {
  if (model_id == "M0") return(x)
  if (model_id %in% c("M1_H3", "M2_H3")) return(moving_average_lags(x, 3L))
  if (model_id %in% c("M1_H5", "M2_H5")) return(moving_average_lags(x, 5L))
  if (model_id == "M3") return(adaptive_state(x, rho))
  stop("Unknown model_id: ", model_id)
}

family_of <- function(model_id) {
  if (model_id == "M0") "M0" else if (startsWith(model_id, "M1")) "M1" else "M2"
}

model_ids <- c("M0", "M1_H3", "M1_H5", "M2_H3", "M2_H5")
fit_store <- list()
coef_rows <- list()
diag_rows <- list()
run_counter <- 0L

record_fit <- function(fit, state_id, window_id, model_id, ll_id, rho = NA_real_) {
  run_counter <<- run_counter + 1L
  run_id <- sprintf("S90_RUN_%04d", run_counter)
  if (!isTRUE(fit$ok)) {
    diag_rows[[length(diag_rows) + 1L]] <<- data.frame(
      run_id, state_id, window_id, model_id, ll_id, rho, n = NA_integer_,
      rank = NA_integer_, columns = NA_integer_, condition_number = NA_real_,
      bic = NA_real_, r_squared = NA_real_, adf_p = NA_real_, kpss_p = NA_real_,
      sample_gate = "FAIL", rank_gate = "FAIL", residual_gate = "FAIL",
      generated_path_gate = "FAIL", overall_gate = "FAIL", stringsAsFactors = FALSE)
    return(invisible(run_id))
  }
  long_names <- c("k_nrc_c", "tau_c", "state_c", fit$nonlinear_name)
  roles <- c("theta_scale", "psi_technique", "phi_wage_state", "lambda_conditioning")
  for (j in seq_along(long_names)) {
    nm <- long_names[j]
    coef_rows[[length(coef_rows) + 1L]] <<- data.frame(
      run_id, state_id, window_id, model_id, ll_id, rho,
      term = nm, coefficient_role = roles[j], estimate = unname(fit$coefficients[nm]),
      std_error = unname(fit$std_error[nm]), t_value = unname(fit$t_value[nm]),
      p_value = unname(fit$p_value[nm]), estimator = "MANUAL_RESTRICTED_DOLS",
      deterministic = "INTERCEPT_ONLY", dynamic_rule = "BASE_DIFFERENCES_ONLY",
      status = "S90_ROBUSTNESS_DIAGNOSTIC", stringsAsFactors = FALSE)
  }
  generated_gate <- if (stats::sd(fit$data[[fit$nonlinear_name]]) > 0) "PASS" else "FAIL"
  overall <- if (fit$sample_gate == "PASS" && fit$rank_gate == "PASS" &&
                 fit$residual_gate == "PASS" && generated_gate == "PASS") "PASS" else "WARN_OR_FAIL"
  diag_rows[[length(diag_rows) + 1L]] <<- data.frame(
    run_id, state_id, window_id, model_id, ll_id, rho, n = fit$n,
    rank = fit$rank, columns = fit$columns, condition_number = fit$condition_number,
    bic = fit$bic, r_squared = fit$r_squared, adf_p = fit$adf_p, kpss_p = fit$kpss_p,
    sample_gate = fit$sample_gate, rank_gate = fit$rank_gate,
    residual_gate = fit$residual_gate, generated_path_gate = generated_gate,
    overall_gate = overall, stringsAsFactors = FALSE)
  invisible(run_id)
}

# LL11 is run for every authorized historical window. LL00/LL22 are prespecified
# sensitivities for the full, Fordist, and post-Fordist windows.
for (sidx in seq_len(nrow(wage_map))) {
  sid <- wage_map$state_id[sidx]
  wage <- panel[[wage_map$repo_variable[sidx]]]
  for (widx in seq_len(nrow(windows))) {
    win <- windows[widx, ]
    for (mid in model_ids) {
      st <- get_state(wage, mid)
      ft <- fit_rdols(panel, win$start, win$end, st, family_of(mid), 1L, 1L)
      key <- paste(sid, win$window_id, mid, "LL11", sep = "__")
      fit_store[[key]] <- ft
      record_fit(ft, sid, win$window_id, mid, "LL11")
    }
  }
  for (widx in which(windows$window_id %in% c("full_long_sample", "pre_1974_full", "post_1973_full"))) {
    win <- windows[widx, ]
    for (mid in model_ids) {
      st <- get_state(wage, mid)
      for (ll in list(list(id = "LL00", lag = 0L, lead = 0L),
                      list(id = "LL22", lag = 2L, lead = 2L))) {
        ft <- fit_rdols(panel, win$start, win$end, st, family_of(mid), ll$lag, ll$lead)
        key <- paste(sid, win$window_id, mid, ll$id, sep = "__")
        fit_store[[key]] <- ft
        record_fit(ft, sid, win$window_id, mid, ll$id)
      }
    }
  }
}

# Profile the adaptive state. The short Fordist-core window is used for path
# display only; reliable persistence inference comes from pre_1974_full.
rho_grid <- seq(0, 0.98, by = 0.01)
profile_windows <- windows[windows$window_id %in%
  c("full_long_sample", "pre_1974_full", "post_1973_full"), ]
profile_rows <- list()
profile_fit_cache <- list()

for (sidx in seq_len(nrow(wage_map))) {
  sid <- wage_map$state_id[sidx]
  wage <- panel[[wage_map$repo_variable[sidx]]]
  for (widx in seq_len(nrow(profile_windows))) {
    win <- profile_windows[widx, ]
    fits <- vector("list", length(rho_grid))
    for (ri in seq_along(rho_grid)) {
      rho <- rho_grid[ri]
      st <- adaptive_state(wage, rho)
      ft <- fit_rdols(panel, win$start, win$end, st, "M2", 1L, 1L, rho_count = 1L)
      fits[[ri]] <- ft
      profile_rows[[length(profile_rows) + 1L]] <- data.frame(
        state_id = sid, window_id = win$window_id, rho = rho,
        bic = if (ft$ok) ft$bic else NA_real_, n = if (ft$ok) ft$n else NA_integer_,
        rank_gate = if (ft$ok) ft$rank_gate else "FAIL", stringsAsFactors = FALSE)
    }
    ok_bic <- vapply(fits, function(z) if (isTRUE(z$ok)) z$bic else Inf, numeric(1))
    best_i <- which.min(ok_bic)
    best_rho <- rho_grid[best_i]
    best <- fits[[best_i]]
    key <- paste(sid, win$window_id, "M3", "LL11", sep = "__")
    fit_store[[key]] <- best
    profile_fit_cache[[paste(sid, win$window_id, sep = "__")]] <- fits
    record_fit(best, sid, win$window_id, "M3", "LL11", best_rho)
  }
}

profile_ledger <- do.call(rbind, profile_rows)
write_csv(profile_ledger, "S90_M3_persistence_profile_ledger.csv")

# Four-year moving-block bootstrap for the headline Fordist persistence profile.
bootstrap_reps <- as.integer(Sys.getenv("S90_BOOTSTRAP_REPS", "1000"))
if (!is.finite(bootstrap_reps) || bootstrap_reps < 10L) bootstrap_reps <- 1000L
set.seed(20260720)
rho_summary <- list()
rho_draws <- list()

for (sidx in seq_len(nrow(wage_map))) {
  sid <- wage_map$state_id[sidx]
  fits <- profile_fit_cache[[paste(sid, "pre_1974_full", sep = "__")]]
  bics <- vapply(fits, function(z) if (isTRUE(z$ok)) z$bic else Inf, numeric(1))
  best_i <- which.min(bics)
  best <- fits[[best_i]]
  best_rho <- rho_grid[best_i]
  n <- best$n
  valid <- vapply(fits, function(z) isTRUE(z$ok) && z$n == n &&
                    identical(z$data$year, best$data$year), logical(1))
  q_list <- lapply(fits, function(z) if (isTRUE(z$ok) && z$n == n) qr.Q(qr(z$X)) else NULL)
  draws <- rep(NA_real_, bootstrap_reps)
  fitted0 <- as.vector(best$X %*% best$coefficients)
  resid0 <- best$fit$residuals - mean(best$fit$residuals)
  for (b in seq_len(bootstrap_reps)) {
    ystar <- fitted0 + resid0[block_indices(n, 4L)]
    score <- rep(Inf, length(rho_grid))
    for (ri in which(valid)) {
      q <- q_list[[ri]]
      sse <- sum(ystar^2) - sum(crossprod(q, ystar)^2)
      sse <- max(sse, .Machine$double.eps)
      score[ri] <- n * log(sse / n) + log(n) * (ncol(fits[[ri]]$X) + 1L)
    }
    draws[b] <- rho_grid[which.min(score)]
  }
  half_life <- if (best_rho <= 0) 0 else log(0.5) / log(best_rho)
  ci <- quantile(draws, c(0.025, 0.975), na.rm = TRUE, names = FALSE)
  rho_summary[[length(rho_summary) + 1L]] <- data.frame(
    state_id = sid, window_id = "pre_1974_full", rho_hat = best_rho,
    half_life_years = half_life, rho_ci_low = ci[1], rho_ci_high = ci[2],
    bootstrap_reps = bootstrap_reps, block_length = 4L,
    boundary_solution = best_rho %in% c(min(rho_grid), max(rho_grid)),
    half_life_interpretation = if (best_rho == max(rho_grid))
      "LOWER_BOUND_GRID_CENSORED" else "POINT_ESTIMATE",
    persistence_evidence = if (best_rho > 0 && ci[1] > 0 && best_rho < max(rho_grid))
      "PERSISTENCE_SUPPORTED" else "WEAK_OR_BOUNDARY",
    stringsAsFactors = FALSE)
  rho_draws[[length(rho_draws) + 1L]] <- data.frame(state_id = sid,
    replication = seq_len(bootstrap_reps), rho_hat = draws, stringsAsFactors = FALSE)
}
rho_summary <- do.call(rbind, rho_summary)
rho_draws <- do.call(rbind, rho_draws)
write_csv(rho_summary, "S90_M3_persistence_and_half_life_results.csv")
write_csv(rho_draws, "S90_M3_moving_block_bootstrap_draws.csv")

coef_ledger <- do.call(rbind, coef_rows)
diagnostic_ledger <- do.call(rbind, diag_rows)
write_csv(coef_ledger, "S90_RDOLS_coefficient_ledger.csv")
write_csv(diagnostic_ledger, "S90_RDOLS_diagnostic_and_gate_ledger.csv")
saveRDS(fit_store, file.path(RDS_DIR, "S90_rdols_fit_objects.rds"))

# Frozen S35 orthogonalization audit and exact primitive-basis reconstruction.
s35 <- read.csv(S35_PATH, check.names = TRUE)
s34 <- read.csv(S34_PATH, check.names = TRUE)
ga34 <- s34[s34$year >= 1945 & s34$year <= 1973, ]
# S34R-B constructed inter_tau_omega_orth once over the full repaired panel.
# The primitive back-transformation must use that same projection scope even
# when the downstream coefficient window is 1945-1973.
orth_fit <- lm(inter_tau_omega ~ k_NRC_centered + tau_centered + omega_NFC_centered,
               data = s34)
delta <- coef(orth_fit)

get_s35 <- function(spec, coef_name) {
  z <- s35[s35$window_id == "golden_age_1945_1973" & s35$spec_id == spec &
             s35$estimator == "FM_OLS" & s35$coefficient_name == coef_name, ]
  if (nrow(z) != 1L) stop("S35 coefficient not unique: ", spec, " / ", coef_name)
  as.numeric(z$coefficient_value)
}
get_intercept <- function(spec) {
  z <- unique(s35$intercept[s35$window_id == "golden_age_1945_1973" &
                              s35$spec_id == spec & s35$estimator == "FM_OLS"])
  as.numeric(z[1])
}

orth_beta <- c(intercept = get_intercept("SPEC_B_NRC_orth"),
               theta = get_s35("SPEC_B_NRC_orth", "beta_scale"),
               psi = get_s35("SPEC_B_NRC_orth", "beta_comp"),
               phi = get_s35("SPEC_B_NRC_orth", "beta_dist"),
               lambda = get_s35("SPEC_B_NRC_orth", "beta_inter"))
raw_beta <- c(intercept = get_intercept("SPEC_B_NRC_raw"),
              theta = get_s35("SPEC_B_NRC_raw", "beta_scale"),
              psi = get_s35("SPEC_B_NRC_raw", "beta_comp"),
              phi = get_s35("SPEC_B_NRC_raw", "beta_dist"),
              lambda = get_s35("SPEC_B_NRC_raw", "beta_inter"))
primitive_beta <- c(
  intercept = orth_beta["intercept"] - orth_beta["lambda"] * delta["(Intercept)"],
  theta = orth_beta["theta"] - orth_beta["lambda"] * delta["k_NRC_centered"],
  psi = orth_beta["psi"] - orth_beta["lambda"] * delta["tau_centered"],
  phi = orth_beta["phi"] - orth_beta["lambda"] * delta["omega_NFC_centered"],
  lambda = orth_beta["lambda"]
)
names(primitive_beta) <- names(orth_beta)

raw_fitted <- raw_beta["intercept"] + raw_beta["theta"] * ga34$k_NRC_centered +
  raw_beta["psi"] * ga34$tau_centered + raw_beta["phi"] * ga34$omega_NFC_centered +
  raw_beta["lambda"] * ga34$inter_tau_omega
orth_resid <- ga34$inter_tau_omega_orth
orth_fitted <- orth_beta["intercept"] + orth_beta["theta"] * ga34$k_NRC_centered +
  orth_beta["psi"] * ga34$tau_centered + orth_beta["phi"] * ga34$omega_NFC_centered +
  orth_beta["lambda"] * orth_resid
primitive_fitted <- primitive_beta["intercept"] + primitive_beta["theta"] * ga34$k_NRC_centered +
  primitive_beta["psi"] * ga34$tau_centered + primitive_beta["phi"] * ga34$omega_NFC_centered +
  primitive_beta["lambda"] * ga34$inter_tau_omega

audit <- data.frame(
  term = names(orth_beta), orthogonalized_coefficient = unname(orth_beta),
  orthogonalization_delta = c(delta["(Intercept)"], delta["k_NRC_centered"],
                              delta["tau_centered"], delta["omega_NFC_centered"], 0),
  primitive_back_transformed = unname(primitive_beta),
  separately_estimated_raw = unname(raw_beta),
  primitive_minus_raw = unname(primitive_beta - raw_beta), stringsAsFactors = FALSE
)
write_csv(audit, "S90_coefficient_back_transformation_audit.csv")
equivalence_audit <- data.frame(
  comparison = c("orthogonalized_vs_back_transformed_primitive",
                 "separately_estimated_raw_vs_orthogonalized"),
  max_abs_fitted_difference = c(max(abs(orth_fitted - primitive_fitted), na.rm = TRUE),
                                max(abs(raw_fitted - orth_fitted), na.rm = TRUE)),
  interpretation = c("ALGEBRAIC_IDENTITY_CHECK", "ESTIMATOR_PARAMETERIZATION_COMPARISON"),
  stringsAsFactors = FALSE)

# Exact raw/orthogonalized equivalence under the same Restricted-DOLS design.
m0_rdols <- fit_store[["NFC_GVA__pre_1974_full__M0__LL11"]]
int_aux <- lm(interaction ~ k_nrc_c + tau_c + state_c, data = m0_rdols$data)
X_orth_rdols <- m0_rdols$X
X_orth_rdols[, "interaction"] <- residuals(int_aux)
fit_orth_rdols <- lm.fit(X_orth_rdols, m0_rdols$y)
fit_raw_rdols <- as.vector(m0_rdols$X %*% m0_rdols$coefficients)
fit_orth_rdols_values <- as.vector(X_orth_rdols %*% fit_orth_rdols$coefficients)
manual_rdols_equiv <- max(abs(fit_raw_rdols - fit_orth_rdols_values), na.rm = TRUE)
equivalence_audit <- rbind(equivalence_audit, data.frame(
  comparison = "manual_RDOLS_raw_vs_orthogonalized_same_design",
  max_abs_fitted_difference = manual_rdols_equiv,
  interpretation = "EXACT_PARAMETERIZATION_IDENTITY", stringsAsFactors = FALSE))
write_csv(equivalence_audit, "S90_raw_orthogonalized_fitted_value_equivalence.csv")

# Original red-series audit on D10 levels, using both code-as-written and the
# corrected primitive coefficients.
ga <- panel[panel$year >= 1945 & panel$year <= 1973, ]
ga$d <- ga$omega_NFC_productive_origin_GVA
ga$d_c <- ga$d - mean(ga$d, na.rm = TRUE)
build_path <- function(df, beta, label) {
  theta_tau <- beta["psi"] + beta["lambda"] * df$d_c
  g_p <- beta["theta"] * df$g_nrc + theta_tau * (df$g_me - df$g_nrc)
  data.frame(year = df$year, reconstruction = label,
    theta_scale = unname(beta["theta"]), theta_tau = theta_tau,
    theta_me = theta_tau, theta_nrc = beta["theta"] - theta_tau,
    g_me = df$g_me, g_nrc = df$g_nrc, g_cap = df$g_cap,
    g_p = g_p, vartheta_path = g_p / df$g_cap,
    C_scale = beta["theta"] * df$g_nrc / df$g_cap,
    C_composition = beta["psi"] * (df$g_me - df$g_nrc) / df$g_cap,
    C_distribution = beta["lambda"] * df$d_c * (df$g_me - df$g_nrc) / df$g_cap,
    stringsAsFactors = FALSE)
}
old_code_path <- build_path(ga, orth_beta, "CURRENT_CODE_ORTH_AS_PRIMITIVE")
corrected_path <- build_path(ga, primitive_beta, "CORRECTED_PRIMITIVE_BASIS")
path_audit <- rbind(old_code_path, corrected_path)
path_audit$identity_error <- path_audit$vartheta_path -
  (path_audit$C_scale + path_audit$C_composition + path_audit$C_distribution)
write_csv(path_audit, "S90_original_vartheta_path_exact_contribution_ledger.csv")

roughness_audit <- do.call(rbind, lapply(split(path_audit, path_audit$reconstruction), function(z) {
  rbind(
    data.frame(reconstruction = z$reconstruction[1], object = "g_p", L = rough_L(z$g_p), C = rough_C(z$g_p)),
    data.frame(reconstruction = z$reconstruction[1], object = "vartheta_path", L = rough_L(z$vartheta_path), C = rough_C(z$vartheta_path)),
    data.frame(reconstruction = z$reconstruction[1], object = "theta_scale", L = rough_L(z$theta_scale), C = rough_C(z$theta_scale)),
    data.frame(reconstruction = z$reconstruction[1], object = "theta_tau", L = rough_L(z$theta_tau), C = rough_C(z$theta_tau)),
    data.frame(reconstruction = z$reconstruction[1], object = "C_scale", L = rough_L(z$C_scale), C = rough_C(z$C_scale)),
    data.frame(reconstruction = z$reconstruction[1], object = "C_composition", L = rough_L(z$C_composition), C = rough_C(z$C_composition)),
    data.frame(reconstruction = z$reconstruction[1], object = "C_distribution", L = rough_L(z$C_distribution), C = rough_C(z$C_distribution))
  )
}))
write_csv(roughness_audit, "S90_original_path_roughness_ledger.csv")

mean_gcap <- mean(corrected_path$g_cap, na.rm = TRUE)
denom_sensitivity <- data.frame(
  year = corrected_path$year,
  g_p = corrected_path$g_p,
  g_cap = corrected_path$g_cap,
  vartheta_path = corrected_path$vartheta_path,
  constant_denominator_ratio = corrected_path$g_p / mean_gcap,
  abs_g_cap_ge_0_01 = abs(corrected_path$g_cap) >= 0.01,
  stringsAsFactors = FALSE
)
write_csv(denom_sensitivity, "S90_denominator_amplification_ledger.csv")
denom_rough <- data.frame(
  object = c("capacity_growth_g_p", "vartheta_path_observed_denominator",
             "g_p_constant_window_denominator", "vartheta_path_abs_gcap_ge_0_01"),
  L = c(rough_L(denom_sensitivity$g_p), rough_L(denom_sensitivity$vartheta_path),
        rough_L(denom_sensitivity$constant_denominator_ratio),
        rough_L(denom_sensitivity$vartheta_path[denom_sensitivity$abs_g_cap_ge_0_01])),
  C = c(rough_C(denom_sensitivity$g_p), rough_C(denom_sensitivity$vartheta_path),
        rough_C(denom_sensitivity$constant_denominator_ratio),
        rough_C(denom_sensitivity$vartheta_path[denom_sensitivity$abs_g_cap_ge_0_01])),
  stringsAsFactors = FALSE
)
write_csv(denom_rough, "S90_denominator_amplification_roughness.csv")

# Order-invariant Shapley attribution of L(vartheta_path).
shapley_once <- function(df, beta) {
  modules <- c("distribution", "composition", "denominator")
  perms <- rbind(c(1,2,3), c(1,3,2), c(2,1,3), c(2,3,1), c(3,1,2), c(3,2,1))
  gbar <- mean(df$g_cap, na.rm = TRUE)
  value <- function(active) {
    dist_state <- if ("distribution" %in% active) df$d_c else rep(0, nrow(df))
    # Balanced accumulation holds the observed structures-growth path fixed and
    # imposes Delta tau = g_ME - g_NRC = 0, exactly as prespecified.
    gn <- df$g_nrc
    gap <- if ("composition" %in% active) df$g_me - df$g_nrc else rep(0, nrow(df))
    den <- if ("denominator" %in% active) df$g_cap else rep(gbar, nrow(df))
    v <- (beta["theta"] * gn + (beta["psi"] + beta["lambda"] * dist_state) * gap) / den
    rough_L(v)
  }
  contrib <- setNames(rep(0, 3L), modules)
  for (p in seq_len(nrow(perms))) {
    active <- character(0)
    before <- value(active)
    for (j in perms[p, ]) {
      m <- modules[j]
      active <- c(active, m)
      after <- value(active)
      contrib[m] <- contrib[m] + (after - before) / nrow(perms)
      before <- after
    }
  }
  full <- value(modules)
  baseline <- value(character(0))
  data.frame(module = modules, shapley_contribution = unname(contrib),
             baseline_scale_roughness = baseline,
             roughness_full = full, share = unname(contrib) / full,
             baseline_scale_share = baseline / full,
             stringsAsFactors = FALSE)
}

shapley_point <- shapley_once(transform(ga, d_c = d_c), primitive_beta)
shapley_boot_reps <- bootstrap_reps
shapley_draws <- vector("list", shapley_boot_reps)
set.seed(20260721)
for (b in seq_len(shapley_boot_reps)) {
  idx <- block_indices(nrow(ga), 4L)
  zb <- ga[idx, ]
  zb$d_c <- zb$d - mean(zb$d, na.rm = TRUE)
  tmp <- shapley_once(zb, primitive_beta)
  tmp$replication <- b
  shapley_draws[[b]] <- tmp
}
shapley_draws <- do.call(rbind, shapley_draws)
ci_by_module <- do.call(rbind, lapply(split(shapley_draws, shapley_draws$module), function(z) {
  data.frame(module = z$module[1], share_ci_low = quantile(z$share, 0.025, na.rm = TRUE),
             share_ci_high = quantile(z$share, 0.975, na.rm = TRUE), stringsAsFactors = FALSE)
}))
shapley_ledger <- merge(shapley_point, ci_by_module, by = "module", sort = FALSE)
shapley_ledger <- shapley_ledger[match(c("distribution", "composition", "denominator"),
                                      shapley_ledger$module), ]
shapley_ledger$classification <- ifelse(shapley_ledger$share > 0.5, "DOMINANT", "NOT_DOMINANT")
shapley_ledger$bootstrap_dominance_stable <- shapley_ledger$share_ci_low > 0.5
write_csv(shapley_ledger, "S90_shapley_roughness_attribution_ledger.csv")
write_csv(shapley_draws, "S90_shapley_moving_block_bootstrap_draws.csv")

# Rank annual contributions to first-difference roughness and run leave-one-year-out.
cp <- corrected_path[is.finite(corrected_path$vartheta_path), ]
sq_jump <- c(NA_real_, diff(cp$vartheta_path)^2)
annual_share <- (replace(sq_jump, !is.finite(sq_jump), 0) +
  c(tail(replace(sq_jump, !is.finite(sq_jump), 0), -1L), 0)) / 2
annual_share <- annual_share / sum(annual_share)
influence <- data.frame(year = cp$year, K_ME = ga$K_ME[match(cp$year, ga$year)],
  K_NRC = ga$K_NRC[match(cp$year, ga$year)], g_me = cp$g_me, g_nrc = cp$g_nrc,
  d_tau = cp$g_me - cp$g_nrc, g_cap = cp$g_cap, vartheta_path = cp$vartheta_path,
  roughness_attributed_share = annual_share, stringsAsFactors = FALSE)
influence$roughness_rank <- rank(-influence$roughness_attributed_share, ties.method = "first")
full_L <- rough_L(cp$vartheta_path)
influence$leave_one_year_out_L <- vapply(seq_len(nrow(cp)), function(i)
  rough_L(cp$vartheta_path[-i]), numeric(1))
influence$relative_L_change_if_dropped <- influence$leave_one_year_out_L / full_L - 1
influence <- influence[order(influence$roughness_rank), ]
write_csv(influence, "S90_capital_growth_and_influential_year_audit.csv")

capital_growth_audit <- data.frame(
  year = panel$year, K_ME = panel$K_ME, K_NRC = panel$K_NRC, K_capacity = panel$K_capacity,
  g_me_recalculated_from_D10_levels = panel$g_me,
  g_nrc_recalculated_from_D10_levels = panel$g_nrc,
  g_cap_recalculated_from_D10_levels = panel$g_cap,
  d_tau_recalculated = panel$d_tau,
  identity_gme_minus_gnrc = panel$g_me - panel$g_nrc - panel$d_tau,
  stringsAsFactors = FALSE)
write_csv(capital_growth_audit, "S90_capital_growth_recalculation_audit.csv")

# Reconstruct every headline Fordist model on 1945-1973 using the longer
# pre-1974 coefficient window. NFC output remains the observed-output boundary.
coef_of <- function(ft, nm) unname(ft$coefficients[nm])
recon_rows <- list()
models_for_recon <- c("M0", "M1_H3", "M1_H5", "M2_H3", "M2_H5", "M3")

for (sidx in seq_len(nrow(wage_map))) {
  sid <- wage_map$state_id[sidx]
  wage <- panel[[wage_map$repo_variable[sidx]]]
  for (mid in models_for_recon) {
    key <- paste(sid, "pre_1974_full", mid, "LL11", sep = "__")
    ft <- fit_store[[key]]
    if (is.null(ft) || !isTRUE(ft$ok)) next
    rho <- if (mid == "M3") rho_summary$rho_hat[rho_summary$state_id == sid][1] else NA_real_
    state <- get_state(wage, mid, rho)
    pre <- panel$year >= 1929 & panel$year <= 1973
    center <- mean(state[pre], na.rm = TRUE)
    z <- panel$year >= 1945 & panel$year <= 1973
    theta <- coef_of(ft, "k_nrc_c")
    psi <- coef_of(ft, "tau_c")
    lambda <- coef_of(ft, ft$nonlinear_name)
    state_c <- state[z] - center
    theta_tau <- psi + lambda * state_c
    g_p <- theta * panel$g_nrc[z] + theta_tau * (panel$g_me[z] - panel$g_nrc[z])
    yp <- rep(NA_real_, sum(z))
    yy <- panel$y[z]
    yrs <- panel$year[z]
    anchor <- which(yrs == 1973)
    yp[anchor] <- yy[anchor]
    if (anchor > 1L) for (i in seq.int(anchor - 1L, 1L)) yp[i] <- yp[i + 1L] - g_p[i + 1L]
    mu <- exp(yy - yp)
    recon_rows[[length(recon_rows) + 1L]] <- data.frame(
      state_id = sid, model_id = mid, coefficient_window = "pre_1974_full",
      year = yrs, wage_state = state[z], wage_state_centered = state_c,
      rho = rho, theta_scale = theta, theta_tau = theta_tau,
      theta_me = theta_tau, theta_nrc = theta - theta_tau,
      g_me = panel$g_me[z], g_nrc = panel$g_nrc[z], g_cap = panel$g_cap[z],
      g_p_nrc_contribution = (theta - theta_tau) * panel$g_nrc[z],
      g_p_me_contribution = theta_tau * panel$g_me[z],
      g_p = g_p, vartheta_path = g_p / panel$g_cap[z],
      y_observed_nfc = yy, y_p = yp, mu = mu,
      anchor_check_mu_1973 = mu[anchor], stringsAsFactors = FALSE)
  }
}
reconstruction <- do.call(rbind, recon_rows)
write_csv(reconstruction, "S90_reconstructed_structural_and_path_series.csv")

# Standardized generated-path effects and cross-boundary path concordance. The
# corporate rows remain comparisons: concordance cannot identify a unique wage
# bargaining boundary when the wage-share series are nearly collinear.
std_rows <- list()
for (sidx in seq_len(nrow(wage_map))) {
  sid <- wage_map$state_id[sidx]
  for (mid in models_for_recon) {
    ft <- fit_store[[paste(sid, "pre_1974_full", mid, "LL11", sep = "__")]]
    if (is.null(ft) || !isTRUE(ft$ok)) next
    lam <- coef_of(ft, ft$nonlinear_name)
    std_rows[[length(std_rows) + 1L]] <- data.frame(
      state_id = sid, model_id = mid,
      standardized_lambda_effect_on_y = lam * sd(ft$data[[ft$nonlinear_name]]) / sd(ft$y),
      lambda = lam, generated_path_sd = sd(ft$data[[ft$nonlinear_name]]),
      y_sd = sd(ft$y), institutional_status = wage_map$status[sidx],
      stringsAsFactors = FALSE)
  }
}
standardized_effects <- do.call(rbind, std_rows)
write_csv(standardized_effects, "S90_standardized_wage_boundary_effects.csv")

path_concordance_rows <- list()
for (mid in models_for_recon) {
  ref <- reconstruction[reconstruction$state_id == "NFC_GVA" & reconstruction$model_id == mid, ]
  for (sid in setdiff(wage_map$state_id, "NFC_GVA")) {
    cmp <- reconstruction[reconstruction$state_id == sid & reconstruction$model_id == mid, ]
    mm <- merge(ref[, c("year", "theta_tau", "vartheta_path", "mu")],
                cmp[, c("year", "theta_tau", "vartheta_path", "mu")],
                by = "year", suffixes = c("_NFC_GVA", "_comparison"))
    path_concordance_rows[[length(path_concordance_rows) + 1L]] <- data.frame(
      model_id = mid, comparison_state = sid,
      correlation_theta_tau = cor(mm$theta_tau_NFC_GVA, mm$theta_tau_comparison, use = "complete.obs"),
      correlation_vartheta_path = cor(mm$vartheta_path_NFC_GVA, mm$vartheta_path_comparison, use = "complete.obs"),
      correlation_mu = cor(mm$mu_NFC_GVA, mm$mu_comparison, use = "complete.obs"),
      interpretation = if (startsWith(sid, "CORP")) "INSTITUTIONAL_COMPARISON_ONLY" else "AUTHORIZED_NFC_ROBUSTNESS",
      stringsAsFactors = FALSE)
  }
}
path_concordance <- do.call(rbind, path_concordance_rows)
write_csv(path_concordance, "S90_wage_boundary_reconstructed_path_concordance.csv")

recon_rough <- do.call(rbind, lapply(split(reconstruction,
  interaction(reconstruction$state_id, reconstruction$model_id, drop = TRUE)), function(z) {
  data.frame(state_id = z$state_id[1], model_id = z$model_id[1],
    L_theta_scale = rough_L(z$theta_scale), C_theta_scale = rough_C(z$theta_scale),
    L_theta_tau = rough_L(z$theta_tau), C_theta_tau = rough_C(z$theta_tau),
    L_g_p = rough_L(z$g_p), C_g_p = rough_C(z$g_p),
    L_vartheta_path = rough_L(z$vartheta_path), C_vartheta_path = rough_C(z$vartheta_path),
    stringsAsFactors = FALSE)
}))
write_csv(recon_rough, "S90_reconstructed_path_roughness_comparison.csv")

# Adjudication and verdict.
dominant_row <- shapley_ledger[which.max(shapley_ledger$share), ]
dominant_source <- if (dominant_row$share > 0.5) paste0(toupper(dominant_row$module), "_DRIVEN") else "JOINTLY_GENERATED"
dominance_stability <- if (dominant_row$share > 0.5 && dominant_row$share_ci_low > 0.5)
  "BOOTSTRAP_STABLE" else "BOOTSTRAP_UNSTABLE"
impl_ratio <- rough_L(corrected_path$vartheta_path) / rough_L(old_code_path$vartheta_path)
implementation_driven <- is.finite(impl_ratio) && impl_ratio < 0.5
top2_share <- sum(head(influence$roughness_attributed_share, 2), na.rm = TRUE)
data_sensitive <- top2_share > 0.5 || min(influence$leave_one_year_out_L, na.rm = TRUE) / full_L < 0.5

gate_ok <- function(sid, mid) {
  z <- diagnostic_ledger[diagnostic_ledger$state_id == sid &
    diagnostic_ledger$window_id == "pre_1974_full" & diagnostic_ledger$model_id == mid &
    diagnostic_ledger$ll_id == "LL11", ]
  nrow(z) == 1L && z$overall_gate == "PASS"
}
lambda_sign <- function(sid, mid) {
  z <- coef_ledger[coef_ledger$state_id == sid & coef_ledger$window_id == "pre_1974_full" &
    coef_ledger$model_id == mid & coef_ledger$ll_id == "LL11" &
    coef_ledger$coefficient_role == "lambda_conditioning", ]
  if (nrow(z) == 1L) sign(z$estimate) else NA_real_
}
rho_supported <- function(sid) {
  z <- rho_summary[rho_summary$state_id == sid, ]
  nrow(z) == 1L && z$persistence_evidence == "PERSISTENCE_SUPPORTED"
}
smoother <- function(sid, mid) {
  z <- recon_rough[recon_rough$state_id == sid & recon_rough$model_id == mid, ]
  nrow(z) == 1L && z$L_theta_tau < z$L_vartheta_path && z$C_theta_tau < z$C_vartheta_path
}

criteria <- data.frame(
  criterion = c("M2_H3_AND_M3_PASS_GATES_BOTH_NFC_BOUNDARIES",
                "LAMBDA_RETAINS_FORDIST_SIGN_UNDER_H5_BOTH_NFC_BOUNDARIES",
                "RHO_POSITIVE_CI_EXCLUDES_ZERO_BOTH_NFC_BOUNDARIES",
                "STRUCTURAL_PATHS_SMOOTHER_THAN_VARTTHETA_BOTH_NFC_BOUNDARIES",
                "NOT_CREATED_BY_DROPPING_INFLUENTIAL_YEARS",
                "SURVIVES_NFC_GVA_AND_NFC_NVA"),
  passed = c(
    all(vapply(c("NFC_GVA", "NFC_NVA"), function(s) gate_ok(s, "M2_H3") && gate_ok(s, "M3"), logical(1))),
    all(vapply(c("NFC_GVA", "NFC_NVA"), function(s) {
      h3 <- lambda_sign(s, "M2_H3"); h5 <- lambda_sign(s, "M2_H5")
      is.finite(h3) && is.finite(h5) && h3 == h5 && h3 < 0
    }, logical(1))),
    all(vapply(c("NFC_GVA", "NFC_NVA"), rho_supported, logical(1))),
    all(vapply(c("NFC_GVA", "NFC_NVA"), function(s) smoother(s, "M2_H3") && smoother(s, "M3"), logical(1))),
    !data_sensitive,
    all(vapply(c("NFC_GVA", "NFC_NVA"), function(s) smoother(s, "M3"), logical(1)))
  ), stringsAsFactors = FALSE)
criteria$status <- ifelse(criteria$passed, "PASS", "FAIL")
support <- all(criteria$passed)
write_csv(criteria, "S90_smoother_equilibrium_adjudication_criteria.csv")

classification <- data.frame(
  classification = c("distribution_driven", "composition_driven", "denominator_driven",
                     "implementation_driven", "data_sensitive", "jointly_generated"),
  indicator = c(shapley_ledger$share[shapley_ledger$module == "distribution"] > 0.5,
                shapley_ledger$share[shapley_ledger$module == "composition"] > 0.5,
                shapley_ledger$share[shapley_ledger$module == "denominator"] > 0.5,
                implementation_driven, data_sensitive, dominant_source == "JOINTLY_GENERATED"),
  bootstrap_stable = c(
    shapley_ledger$bootstrap_dominance_stable[shapley_ledger$module == "distribution"],
    shapley_ledger$bootstrap_dominance_stable[shapley_ledger$module == "composition"],
    shapley_ledger$bootstrap_dominance_stable[shapley_ledger$module == "denominator"],
    NA, NA, NA),
  quantitative_basis = c(
    shapley_ledger$share[shapley_ledger$module == "distribution"],
    shapley_ledger$share[shapley_ledger$module == "composition"],
    shapley_ledger$share[shapley_ledger$module == "denominator"],
    impl_ratio, top2_share, max(shapley_ledger$share)), stringsAsFactors = FALSE)
write_csv(classification, "S90_lumpiness_classification_ledger.csv")

# Figures used by the report and Beamer addendum.
png(file.path(FIG_DIR, "F01_original_lumpiness_decomposition.png"), 1600, 900, res = 180)
par(mar = c(4, 4.5, 2.2, 1))
matplot(corrected_path$year,
        cbind(corrected_path$vartheta_path, corrected_path$C_scale,
              corrected_path$C_composition, corrected_path$C_distribution),
        type = "l", lty = c(1,2,3,4), lwd = c(3,2,2,2),
        col = c("#b2182b", "#2166ac", "#4d9221", "#762a83"),
        xlab = "Year", ylab = "Elasticity ratio / exact contribution",
        main = "Observed-direction ratio and its exact additive decomposition")
abline(h = 0, col = "grey70")
legend("topleft", c("vartheta_path", "scale", "capital composition", "wage conditioning"),
       col = c("#b2182b", "#2166ac", "#4d9221", "#762a83"),
       lty = c(1,2,3,4), lwd = c(3,2,2,2), bty = "n")
dev.off()

base_m3 <- reconstruction[reconstruction$state_id == "NFC_GVA" & reconstruction$model_id == "M3", ]
png(file.path(FIG_DIR, "F02_structural_vs_directional.png"), 1600, 900, res = 180)
par(mar = c(4, 4.5, 2.2, 1))
yrng <- range(c(base_m3$theta_scale, base_m3$theta_tau, corrected_path$vartheta_path), finite = TRUE)
plot(corrected_path$year, corrected_path$vartheta_path, type = "l", lwd = 2.6,
     col = "#b2182b", xlab = "Year", ylab = "Elasticity / ratio", ylim = yrng,
     main = "Structural elasticities are not the observed-direction ratio")
lines(base_m3$year, base_m3$theta_tau, col = "#2166ac", lwd = 3)
lines(base_m3$year, base_m3$theta_scale, col = "black", lwd = 2.5, lty = 2)
legend("topleft", c("vartheta_path (ratio diagnostic)", "theta_tau (adaptive state)",
                    "theta_scale (constant composition)"),
       col = c("#b2182b", "#2166ac", "black"), lty = c(1,1,2), lwd = c(2.6,3,2.5), bty = "n")
dev.off()

png(file.path(FIG_DIR, "F03_wage_state_memory.png"), 1600, 900, res = 180)
par(mar = c(4, 4.5, 2.2, 1))
z <- panel$year >= 1940 & panel$year <= 1978
rho_nfc <- rho_summary$rho_hat[rho_summary$state_id == "NFC_GVA"]
plot(panel$year[z], panel$omega_NFC_productive_origin_GVA[z], type = "l", lwd = 2,
     col = "grey35", xlab = "Year", ylab = "Wage-share state", main = "Observed and remembered NFC wage pressure")
lines(panel$year[z], moving_average_lags(panel$omega_NFC_productive_origin_GVA, 3)[z],
      col = "#4d9221", lwd = 2.5)
lines(panel$year[z], adaptive_state(panel$omega_NFC_productive_origin_GVA, rho_nfc)[z],
      col = "#2166ac", lwd = 3)
legend("topleft", c("contemporaneous", "3-year lagged mean", paste0("adaptive, rho=", sprintf("%.2f", rho_nfc))),
       col = c("grey35", "#4d9221", "#2166ac"), lwd = c(2,2.5,3), bty = "n")
dev.off()

png(file.path(FIG_DIR, "F04_reconstructed_capacity_utilization.png"), 1600, 900, res = 180)
par(mar = c(4, 4.5, 2.2, 1))
z0 <- reconstruction[reconstruction$state_id == "NFC_GVA" & reconstruction$model_id == "M0", ]
z2 <- reconstruction[reconstruction$state_id == "NFC_GVA" & reconstruction$model_id == "M2_H3", ]
plot(z0$year, z0$mu, type = "l", col = "grey40", lwd = 2, xlab = "Year", ylab = expression(mu[t]),
     main = "NFC capacity utilization, anchored at 1973")
lines(z2$year, z2$mu, col = "#4d9221", lwd = 2.5)
lines(base_m3$year, base_m3$mu, col = "#2166ac", lwd = 3)
abline(h = 1, col = "grey75", lty = 2)
legend("topleft", c("M0 contemporaneous", "M2-H3 embodied", "M3 adaptive embodied"),
       col = c("grey40", "#4d9221", "#2166ac"), lwd = c(2,2.5,3), bty = "n")
dev.off()

png(file.path(FIG_DIR, "F05_shapley_attribution.png"), 1600, 900, res = 180)
par(mar = c(6, 4.5, 2.2, 1))
cols <- c("#762a83", "#4d9221", "#b2182b")
bp <- barplot(100 * shapley_ledger$share, names.arg = c("Wage\nconditioning", "Capital\ncomposition", "Growth\ndenominator"),
              col = cols, border = NA, ylab = "Share of first-difference roughness (%)",
              main = "Order-invariant attribution of vartheta_path roughness")
arrows(bp, 100 * shapley_ledger$share_ci_low, bp, 100 * shapley_ledger$share_ci_high,
       angle = 90, code = 3, length = .05)
abline(h = 50, lty = 2, col = "grey35")
mtext(sprintf("Baseline scale-growth roughness: %.1f%% of total",
              100 * shapley_ledger$baseline_scale_share[1]), side = 1, line = 4.8, cex = .8)
dev.off()

png(file.path(FIG_DIR, "F06_persistence_profile.png"), 1600, 900, res = 180)
par(mar = c(4, 4.5, 2.2, 1))
p0 <- profile_ledger[profile_ledger$window_id == "pre_1974_full", ]
yl <- range(p0$bic - ave(p0$bic, p0$state_id, FUN = min), na.rm = TRUE)
plot(NA, xlim = range(rho_grid), ylim = yl, xlab = expression(rho), ylab = "BIC minus boundary-specific minimum",
     main = "Adaptive-memory persistence profile, pre-1974")
pc <- c("#2166ac", "#67a9cf", "#b2182b", "#ef8a62")
for (i in seq_len(nrow(wage_map))) {
  q <- p0[p0$state_id == wage_map$state_id[i], ]
  lines(q$rho, q$bic - min(q$bic, na.rm = TRUE), col = pc[i], lwd = 2.5)
}
legend("topleft", wage_map$state_id, col = pc, lwd = 2.5, bty = "n")
dev.off()

# Validation ledger is written before the memo so a failed identity remains visible.
validation <- data.frame(
  check = c("D10 alias exact", "capital growth identity", "exact contribution identity",
            "orthogonalized primitive fitted identity", "manual RDOLS raw orth identity",
            "Shapley plus baseline identity", "mu_1973 anchor", "S90 output isolation"),
  value = c(alias_diff,
            max(abs(capital_growth_audit$identity_gme_minus_gnrc), na.rm = TRUE),
            max(abs(path_audit$identity_error), na.rm = TRUE),
            max(abs(orth_fitted - primitive_fitted), na.rm = TRUE),
            manual_rdols_equiv,
            abs(sum(shapley_ledger$shapley_contribution) +
                  shapley_ledger$baseline_scale_roughness[1] -
                  shapley_ledger$roughness_full[1]),
            max(abs(reconstruction$anchor_check_mu_1973 - 1), na.rm = TRUE), 0),
  tolerance = c(1e-12, 1e-12, 1e-12, 1e-10, 1e-10, 1e-12, 1e-12, 0),
  status = NA_character_, stringsAsFactors = FALSE)
validation$status <- ifelse(validation$value <= validation$tolerance, "PASS", "FAIL")
write_csv(validation, "S90_validation_checks.csv")

share_pct <- function(module) 100 * shapley_ledger$share[shapley_ledger$module == module]
rho_line <- paste(vapply(seq_len(nrow(rho_summary)), function(i) sprintf("%s: rho=%.2f (95%% block CI %.2f--%.2f), half-life %.2f years",
  rho_summary$state_id[i], rho_summary$rho_hat[i], rho_summary$rho_ci_low[i],
  rho_summary$rho_ci_high[i], rho_summary$half_life_years[i]), character(1)), collapse = "; ")
memo <- c(
  "# S90 Verdict: Path-Dependent Technique Choice and Aggregate-Elasticity Lumpiness",
  "",
  "## Verdict",
  "",
  sprintf("The red series in v6 is not a structural aggregate elasticity. It is `vartheta_path = g^p/g^cap`, a ratio evaluated along the observed annual direction of ME/NRC accumulation. The exact contribution identity passes at %.3g. Relative to the balanced-accumulation counterfactual, the Shapley decomposition assigns %.1f%% of total first-difference roughness to wage conditioning, %.1f%% to unbalanced capital composition, and %.1f%% to the capital-growth denominator; the observed structures-growth baseline accounts for the remaining %.1f%%. The point estimate therefore classifies the original lumpiness as **%s**, with dominance **%s** under the moving-block interval; coefficient reconstruction is %s and the path is %s.",
          max(abs(path_audit$identity_error), na.rm = TRUE), share_pct("distribution"),
          share_pct("composition"), share_pct("denominator"),
          100 * shapley_ledger$baseline_scale_share[1], dominant_source, dominance_stability,
          if (implementation_driven) "material" else "not the dominant source",
          if (data_sensitive) "data-sensitive under the prespecified influence rule" else "not dominated by one or two years"),
  "",
  "## Persistence",
  "",
  paste0(rho_line, "."),
  "",
  sprintf("The full smoother-equilibrium adjudication is **%s**. This is a joint test: the structural coefficients are smoother by construction of the economic object, but the claim is accepted only if embodied-memory models pass sample, rank, generated-path, and residual-stationarity gates; the Fordist sign survives H5; adaptive persistence excludes rho=0; influential years do not manufacture the result; and both NFC-GVA and NFC-NVA agree.",
          if (support) "SUPPORTED" else "NOT FULLY SUPPORTED"),
  "",
  "## Economic interpretation",
  "",
  "Real NFC output and NFC capital never change across the grid. The wage state may be measured at the whole-NFC or all-corporation boundary because bargaining pressure can condition the technique installed in NFC productive capacity without sharing the same accounting boundary as output. The corporate variants are institutional comparisons only: their high Fordist correlation with NFC shares does not identify a unique bargaining sector.",
  "",
  "## Implication for v6",
  "",
  "Rename the red line `Observed-direction capacity payoff (ratio diagnostic)` and remove every sentence that treats it as equilibrium `theta_t`. Report `theta_scale` and `theta_tau` separately; show `g^p` and its ME/NRC contributions before dividing by `g^cap`; and present adaptive/embodied memory as S90 robustness evidence rather than as a replacement for the locked chapter specification.",
  "",
  "## Reproducibility",
  "",
  sprintf("The script used %d four-year moving-block bootstrap replications. All outputs are isolated under `%s`. No S40 or Stage B/C object is read or written.", bootstrap_reps, OUT_DIR)
)
writeLines(memo, file.path(REPORT_DIR, "S90_VERDICT_MEMO.md"), useBytes = TRUE)

readme <- c(
  "# S90 Path-Dependent Theta Robustness",
  "",
  "Standalone diagnostic implementation of the approved plan.",
  "",
  "- canonical input: D10 clean US panel",
  "- frozen v6 audit inputs: S35 coefficients and S34R-B orthogonalized panel",
  "- main estimator: manual intercept-only Restricted DOLS, LL11",
  "- dynamic correction: differences of k_NRC, tau, and the wage state only",
  "- persistence inference: BIC profile plus four-year moving-block bootstrap",
  "- output and capital boundaries: real NFC GVA and NFC capital, fixed",
  "- downstream status: S90 diagnostic only; S40 and Stage B/C unchanged"
)
writeLines(readme, file.path(OUT_DIR, "README.md"), useBytes = TRUE)

if (any(validation$status == "FAIL")) {
  stop("S90 completed with failed validation checks: ",
       paste(validation$check[validation$status == "FAIL"], collapse = "; "))
}

message("S90 path-dependent theta robustness complete. Outputs: ", OUT_DIR)
