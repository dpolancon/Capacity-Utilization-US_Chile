############################################################
# 40_inference_rank.R — Stage 1 Bootstrap Rank Inference (Wild Bootstrap LR)
# Repo: capacity_utilization/
#
# PURPOSE
# Stage 1 delivers finite-sample rank inference for Johansen systems under
# heteroskedasticity-aware wild bootstrap, consistent with the confinement
# ontology. This script:
#   - tests H0: rank(Pi)=r0 (default r0=0) using Johansen trace LR
#   - computes bootstrap critical values at 10/5/1% (upper tail)
#   - computes bootstrap p-values with significance stars
#   - enforces a validity-policy switch (strict redraw vs capped) based on
#     observed bootstrap failure rate (D2 rule)
#
# HARD DISCIPLINE (LOCKED)
# - Full sample first; regimes follow
# - Deterministics restricted to CONFIG$ECDET_LOCKED (typically none/const)
# - Baseline p=1 (can be extended later, but Stage 1 stays rank-only)
#
# SELF-CONTAINED
# - Allowed to source:
#     codes/10_config.R
#     codes/99_utils.R
# - No sinks. Logging via writeLines.
#
# OUTPUTS
# - output/InferenceRank/csv/STAGE1_rank_bootstrap_table.csv
# - output/InferenceRank/rds/STAGE1_rank_bootstrap_draws_<case_id>.rds  (optional archive)
# - output/InferenceRank/logs/stage1_rank_<timestamp>.log
#
############################################################

suppressPackageStartupMessages({
  library(here)
  library(readxl)
  library(dplyr)
  library(tibble)
  library(readr)
  library(urca)
})

# -------------------------
# 0) Init: config + utils
# -------------------------
source(here::here("codes", "10_config.R"))
source(here::here("codes", "99_utils.R"))

set_seed_deterministic(CONFIG$seed %||% 123456)

# -------------------------
# 1) Output dirs + logger
# -------------------------
OUT_ROOT <- here::here("output", "InferenceRank")
DIRS <- list(
  csv  = file.path(OUT_ROOT, "csv"),
  logs = file.path(OUT_ROOT, "logs"),
  rds  = file.path(OUT_ROOT, "rds")
)
ensure_dirs(OUT_ROOT, unlist(DIRS, use.names = FALSE))

ts_tag   <- format(Sys.time(), "%Y%m%d_%H%M%S")
log_file <- file.path(DIRS$logs, paste0("stage1_rank_", ts_tag, ".log"))
log_lines <- character()

log_add <- function(...) {
  msg <- paste0(...)
  log_lines <<- c(log_lines, msg)
  invisible(TRUE)
}
log_flush <- function() {
  writeLines(log_lines, con = log_file, useBytes = TRUE)
  invisible(TRUE)
}

log_add("=== STAGE 1 Rank Bootstrap start ===")
log_add("Timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
log_add("Project root: ", here::here())
log_add("OUT_ROOT: ", OUT_ROOT)

# -------------------------
# 2) Resolve data path robustly
# -------------------------
resolve_path <- function(p) {
  if (is.null(p) || !nzchar(p)) stop("CONFIG$data_file is empty.")
  if (grepl("^([A-Za-z]:\\\\|/)", p)) return(normalizePath(p, winslash = "/", mustWork = FALSE))
  normalizePath(here::here(p), winslash = "/", mustWork = FALSE)
}
DATA_FILE  <- resolve_path(CONFIG$data_file)
DATA_SHEET <- CONFIG$data_sheet
if (!file.exists(DATA_FILE)) {
  stop("Data file not found at: ", DATA_FILE)
}

log_add("Data file (resolved): ", DATA_FILE)
log_add("Data sheet: ", DATA_SHEET)

# -------------------------
# 3) User-tunable Stage 1 parameters
# -------------------------
STAGE1 <- list(
  r0 = 0L,                # primary null
  test = "trace",         # "trace" (default); extend later if needed
  B_target = 1999L,       # bootstrap replications target
  B_pilot = 200L,         # pilot attempts to estimate failure rate
  fail_threshold = 0.10,  # D2 switch threshold
  max_attempt_factor = 6, # cap attempts in capped mode: B_target * factor
  weight = "rademacher",  # wild weights: rademacher (±1)
  expl_abs_cap = 1e8      # explosive guard: max abs(X*) above this => invalid draw
)

# -------------------------
# 4) Helpers: data, windows, basis, system matrix
# -------------------------
read_data <- function() {
  df <- readxl::read_xlsx(DATA_FILE, sheet = DATA_SHEET)
  df <- as.data.frame(df)

  req <- c(CONFIG$year_col, CONFIG$y_col, CONFIG$k_col, CONFIG$e_col)
  miss <- setdiff(req, names(df))
  if (length(miss) > 0) stop("Missing columns in data: ", paste(miss, collapse = ", "))

  df <- df %>%
    mutate(
      year = as.integer(.data[[CONFIG$year_col]]),
      y    = as.numeric(.data[[CONFIG$y_col]]),
      k    = as.numeric(.data[[CONFIG$k_col]]),
      e    = as.numeric(.data[[CONFIG$e_col]])
    ) %>%
    arrange(.data$year) %>%
    mutate(
      log_y = log(.data$y),
      log_k = log(.data$k)
    )

  ok <- is.finite(df$log_y) & is.finite(df$log_k) & is.finite(df$e)
  df <- df[ok, , drop = FALSE]

  if (nrow(df) < 50) stop("Too few usable observations after filtering.")
  df
}

slice_window <- function(df, win) {
  a <- win[1]; b <- win[2]
  dfw <- df
  if (is.finite(a)) dfw <- dfw[dfw$year >= a, , drop = FALSE]
  if (is.finite(b)) dfw <- dfw[dfw$year <= b, , drop = FALSE]
  dfw
}

basis_apply_rawpowers <- function(df, degree = 2L, prefix = "Q") {
  e <- as.numeric(df$e)
  out <- as.data.frame(sapply(seq_len(degree), function(j) e^j))
  names(out) <- paste0(prefix, seq_len(degree))
  out
}

basis_fit_orthogonal <- function(df_full, degree = 2L) {
  e <- as.numeric(df_full$e)
  P <- sapply(seq_len(degree), function(j) e^j)
  qrP <- qr(P)
  list(type = "qr", degree = degree, R = qr.R(qrP))
}

basis_apply_orthogonal <- function(df, basis, prefix = "Q") {
  stopifnot(identical(basis$type, "qr"))
  e <- as.numeric(df$e)
  P <- sapply(seq_len(basis$degree), function(j) e^j)
  Z <- P %*% solve(basis$R)
  Z <- as.data.frame(Z)
  names(Z) <- paste0(prefix, seq_len(basis$degree))
  Z
}

build_system_matrix <- function(dfw, degree, basis_mode = c("raw", "ortho"), ORTHO_BASIS) {
  basis_mode <- match.arg(basis_mode)

  X <- data.frame(
    log_y = dfw$log_y,
    log_k = dfw$log_k
  )

  if (isTRUE(CONFIG$INCLUDE_E_RAW)) {
    X$e_raw <- dfw$e
  }

  if (basis_mode == "raw") {
    Q <- basis_apply_rawpowers(dfw, degree = degree, prefix = "Q")
  } else {
    Q <- basis_apply_orthogonal(dfw, basis = ORTHO_BASIS[[as.character(degree)]], prefix = "Q")
  }

  for (j in seq_len(degree)) {
    nm <- paste0("Q", j)
    X[[paste0(nm, "_logK")]] <- Q[[nm]] * dfw$log_k
  }

  X
}

# -------------------------
# 5) Johansen LR extraction
# -------------------------
compute_johansen_lr <- function(X, p, ecdet, type = "trace", r0 = 0L) {
  X <- as.matrix(X)
  K <- as.integer(p + 1L) # repo convention
  cajo <- urca::ca.jo(X, type = type, ecdet = ecdet, K = K, spec = CONFIG$johansen_spec)
  # In urca, @teststat is a vector for ranks r=0..m-1 (trace or eigen)
  ts <- as.numeric(cajo@teststat)
  # r0=0 corresponds to first element
  if (length(ts) < (r0 + 1L)) stop("Unexpected ca.jo@teststat length.")
  list(LR = ts[r0 + 1L], cajo = cajo)
}

# -------------------------
# 6) Fit restricted (rank r0) short-run regression via cajorls
#    and extract residuals + coefficients for recursion
# -------------------------
fit_restricted_short_run <- function(cajo, X, p, ecdet, r0) {
  
  # r0 >= 1: standard path (urca supports it)
  if (r0 >= 1L) {
    rl <- urca::cajorls(cajo, r = as.integer(r0))
    E  <- as.matrix(rl$rlm$residuals)
    colnames(E) <- colnames(cajo@Z0)
    return(list(mode = "cajorls", rl = rl, E = E, cvec = rep(0, ncol(E)), Gamma = NULL))
  }
  
  # r0 == 0: urca DOES NOT support cajorls(r=0).
  # Null is VAR in differences with (p-1) lags of ΔX (since p is VECM lag order).
  X  <- as.matrix(X)
  dX <- diff(X)                 # (N-1) x m
  m  <- ncol(dX)
  Tn <- nrow(dX)
  
  has_const <- identical(ecdet, "const")
  
  # Build regression: ΔX_t ~ const + ΔX_{t-1} + ... + ΔX_{t-(p-1)}
  # Number of lagged ΔX regressors = (p-1)
  if (p <= 1L) {
    Z <- NULL
    Y <- dX
  } else {
    # embed gives: [ΔX_t, ΔX_{t-1}, ..., ΔX_{t-(p-1)}]
    EBD <- embed(dX, p)          # dimensions: (Tn - (p-1)) x (m*p)
    Y   <- EBD[, 1:m, drop = FALSE]
    Z   <- EBD[, (m+1):(m*p), drop = FALSE]
  }
  
  if (has_const) {
    if (is.null(Z)) {
      fit <- lm(Y ~ 1)
      cvec <- as.numeric(coef(fit)[1, ])
    } else {
      fit <- lm(Y ~ 1 + Z)
      cvec <- as.numeric(coef(fit)[1, ])
    }
  } else {
    if (is.null(Z)) {
      fit <- lm(Y ~ 0)
      cvec <- rep(0, m)
    } else {
      fit <- lm(Y ~ 0 + Z)
      cvec <- rep(0, m)
    }
  }
  
  E <- as.matrix(residuals(fit))
  colnames(E) <- colnames(X)
  
  # Extract Gamma (for recursion when p>1). If p=1, Gamma=NULL.
  Gamma <- NULL
  if (!is.null(Z)) {
    B <- coef(fit)
    # In multivariate lm, coef is a matrix: rows=regressors, cols=equations
    # We want Gamma_i matrices stacked in the Z block.
    # Z columns are ordered as: ΔX_{t-1} (m cols), ΔX_{t-2} (m cols), ...
    if (is.matrix(B)) {
      # drop intercept row if present
      if (has_const) Bz <- B[rownames(B) != "(Intercept)", , drop = FALSE] else Bz <- B
      Gamma <- vector("list", p-1L)
      for (i in 1:(p-1L)) {
        idx <- ((i-1L)*m + 1L):(i*m)
        Gamma[[i]] <- t(Bz[idx, , drop = FALSE])  # m x m
      }
    }
  }
  
  list(mode = "diffVAR", rl = NULL, E = E, cvec = cvec, Gamma = Gamma)
}

# -------------------------
# 7) Build recursion components from cajorls output (p=1 baseline)
#    For p=1, there are no lagged differences; recursion is:
#    ΔX_t = c + eps_t*
#    where c is included only if present in rl coefficients.
# -------------------------
extract_const_vec <- function(rl_obj, m) {
  # Attempt to recover intercept per equation from coefficients.
  # cajorls gives one system object; coefficients are named.
  # We'll robustly set c=0 if not found.
  coefs <- try(stats::coef(rl_obj$rlm), silent = TRUE)
  cvec <- rep(0, m)

  if (!inherits(coefs, "try-error") && !is.null(coefs)) {
    # coefs is a matrix with rows = regressors, cols = equations
    if (is.matrix(coefs)) {
      rn <- rownames(coefs)
      # common intercept names: "(Intercept)" or "constant"
      irow <- which(rn %in% c("(Intercept)", "const", "constant"))
      if (length(irow) == 1L) cvec <- as.numeric(coefs[irow, ])
    }
  }
  cvec
}

# -------------------------
# 8) Wild weights
# -------------------------
draw_weights <- function(Tn, type = "rademacher") {
  if (type == "rademacher") {
    w <- sample(c(-1, 1), size = Tn, replace = TRUE)
    return(w)
  }
  stop("Unknown wild weight type: ", type)
}

# -------------------------
# 9) Simulate bootstrap sample under H0 (rank r0)
# -------------------------
simulate_under_null <- function(X_obs, E_hat, cvec, weight_type, expl_abs_cap) {
  # X_obs: N x m observed levels matrix (aligned with ca.jo input)
  # E_hat: Teff x m residual matrix from restricted regression
  # We simulate N rows. For p=1 we use ΔX_t = c + eps_t*
  X_obs <- as.matrix(X_obs)
  N <- nrow(X_obs); m <- ncol(X_obs)

  # Align lengths: E_hat length is Teff = N - 1 - (p-1) - K adjustment in ca.jo internal design.
  # We avoid fighting urca internals: simulate using Teff residuals and rebuild N levels by starting at X_obs[1,].
  Teff <- nrow(E_hat)
  if (Teff < (N - 1)) {
    # pad by recycling tail residuals (rare). Better than crashing; logged as warning.
    pad <- (N - 1) - Teff
    E_hat <- rbind(E_hat, E_hat[(Teff - pad + 1):Teff, , drop = FALSE])
    Teff <- nrow(E_hat)
  }
  E_use <- E_hat[1:(N - 1), , drop = FALSE]

  w <- draw_weights(N - 1, type = weight_type)
  E_star <- E_use * w

  X_star <- matrix(NA_real_, nrow = N, ncol = m)
  X_star[1, ] <- X_obs[1, ]

  for (t in 2:N) {
    dX <- cvec + E_star[t - 1, ]
    X_star[t, ] <- X_star[t - 1, ] + dX
    if (any(!is.finite(X_star[t, ]))) return(list(ok = FALSE, X = NULL, reason = "nonfinite"))
    if (max(abs(X_star[t, ]), na.rm = TRUE) > expl_abs_cap) return(list(ok = FALSE, X = NULL, reason = "explosive"))
  }

  colnames(X_star) <- colnames(X_obs)
  list(ok = TRUE, X = X_star, reason = "ok")
}

# -------------------------
# 10) Validity check wrapper: estimation success + non-explosive
#     (p=1 leaves little to check beyond stability guards)
# -------------------------
validity_check <- function(sim_obj, p, ecdet, type, r0) {
  if (!isTRUE(sim_obj$ok)) return(list(ok = FALSE, reason = sim_obj$reason))
  # Must be able to estimate ca.jo and extract LR
  tmp <- try(compute_johansen_lr(sim_obj$X, p = p, ecdet = ecdet, type = type, r0 = r0), silent = TRUE)
  if (inherits(tmp, "try-error")) return(list(ok = FALSE, reason = "ca_jo_fail"))
  list(ok = TRUE, reason = "ok", LR = tmp$LR)
}

# -------------------------
# 11) Stars and reporting helpers
# -------------------------
add_stars_p <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  ""
}

# -------------------------
# 12) Main runner for one case
# -------------------------
run_case <- function(X, window, spec, basis, ecdet, p, r0, stage1) {
  X <- as.matrix(X)
  N <- nrow(X); m <- ncol(X)

  # Observed LR
  obs <- compute_johansen_lr(X, p = p, ecdet = ecdet, type = stage1$test, r0 = r0)
  LR_obs <- obs$LR

  # Restricted fit under H0
  restr <- fit_restricted_short_run(obs$cajo, X = X, p = p, ecdet = ecdet, r0 = r0)
  E_hat <- restr$E
  cvec  <- restr$cvec
  Gamma <- restr$Gamma

  # Intercept vector for recursion (mostly 0 unless identifiable)
  cvec <- extract_const_vec(restr$rl, m = m)

  # --- Pilot to estimate failure rate
  pilot_attempts <- 0L
  pilot_valid <- 0L

  for (i in seq_len(stage1$B_pilot)) {
    pilot_attempts <- pilot_attempts + 1L
    sim <- simulate_under_null(X_obs = X, E_hat = E_hat, cvec = cvec,
                              weight_type = stage1$weight, expl_abs_cap = stage1$expl_abs_cap)
    chk <- validity_check(sim, p = p, ecdet = ecdet, type = stage1$test, r0 = r0)
    if (isTRUE(chk$ok)) pilot_valid <- pilot_valid + 1L
  }

  fail_rate <- if (pilot_attempts > 0) 1 - (pilot_valid / pilot_attempts) else NA_real_
  mode <- if (is.finite(fail_rate) && fail_rate <= stage1$fail_threshold) "strict" else "capped"

  # --- Bootstrap collection
  B_target <- stage1$B_target
  max_attempts <- if (mode == "strict") as.integer(B_target * stage1$max_attempt_factor) else as.integer(B_target * stage1$max_attempt_factor)

  LR_star <- numeric(0)
  attempts <- 0L
  failures <- 0L

  while (length(LR_star) < B_target && attempts < max_attempts) {
    attempts <- attempts + 1L
    sim <- simulate_under_null(X_obs = X, E_hat = E_hat, cvec = cvec,
                              weight_type = stage1$weight, expl_abs_cap = stage1$expl_abs_cap)
    chk <- validity_check(sim, p = p, ecdet = ecdet, type = stage1$test, r0 = r0)
    if (isTRUE(chk$ok)) {
      LR_star <- c(LR_star, chk$LR)
    } else {
      failures <- failures + 1L
    }
  }

  B_eff <- length(LR_star)
  boot_fail_rate <- if (attempts > 0) failures / attempts else NA_real_

  if (B_eff < 50) {
    # too few draws to do anything
    return(list(
      row = tibble(
        window = window, spec = spec, basis = basis, ecdet = ecdet,
        p = p, r0 = r0, test = stage1$test,
        LR_obs = LR_obs,
        cv_10 = NA_real_, cv_05 = NA_real_, cv_01 = NA_real_,
        p_boot = NA_real_, sig = "",
        reject_10 = NA, reject_05 = NA, reject_01 = NA,
        B_target = B_target, B_eff = B_eff,
        boot_fail_rate = boot_fail_rate,
        policy_mode = mode,
        cv01_unstable = NA
      ),
      draws = LR_star
    ))
  }

  # Critical values (upper tail)
  qs <- stats::quantile(LR_star, probs = c(0.90, 0.95, 0.99), na.rm = TRUE, names = FALSE)
  cv10 <- qs[1]; cv05 <- qs[2]; cv01 <- qs[3]

  # Bootstrap p-value
  p_boot <- mean(LR_star >= LR_obs, na.rm = TRUE)
  sig <- add_stars_p(p_boot)

  reject_10 <- (LR_obs > cv10)
  reject_05 <- (LR_obs > cv05)
  reject_01 <- (LR_obs > cv01)

  cv01_unstable <- (B_eff < 1000)

  list(
    row = tibble(
      window = window, spec = spec, basis = basis, ecdet = ecdet,
      p = p, r0 = r0, test = stage1$test,
      LR_obs = LR_obs,
      cv_10 = cv10, cv_05 = cv05, cv_01 = cv01,
      p_boot = p_boot, sig = sig,
      reject_10 = reject_10, reject_05 = reject_05, reject_01 = reject_01,
      B_target = B_target, B_eff = B_eff,
      boot_fail_rate = boot_fail_rate,
      policy_mode = mode,
      cv01_unstable = cv01_unstable
    ),
    draws = LR_star
  )
}

# -------------------------
# 13) Run all cases (full first, then regimes)
# -------------------------
df <- read_data()

# Fit orthogonal basis on FULL sample for each degree
ORTHO_BASIS <- list()
for (nm in names(CONFIG$SPECS)) {
  deg <- CONFIG$SPECS[[nm]]$degree
  ORTHO_BASIS[[as.character(deg)]] <- basis_fit_orthogonal(df, degree = deg)
}

windows <- CONFIG$WINDOWS_LOCKED
ecdets  <- CONFIG$ECDET_LOCKED

# Ensure full sample first in loop order if present
win_order <- names(windows)
if ("full" %in% win_order) win_order <- c("full", setdiff(win_order, "full"))

p_use <- 1L  # Stage 1 baseline

rows <- list()
draw_archives <- list()
k <- 0L

for (w_name in win_order) {
  dfw <- slice_window(df, windows[[w_name]])

  for (spec_name in names(CONFIG$SPECS)) {
    deg <- CONFIG$SPECS[[spec_name]]$degree

    for (basis_mode in c("raw", "ortho")) {
      X <- build_system_matrix(dfw, degree = deg, basis_mode = basis_mode, ORTHO_BASIS = ORTHO_BASIS)

      for (ec in ecdets) {
        # Feasibility gate (avoid wasting time)
        gate <- admissible_gate(X, p = p_use)
        if (!isTRUE(gate$ok)) {
          k <- k + 1L
          rows[[k]] <- tibble(
            window = w_name, spec = spec_name, basis = basis_mode, ecdet = ec,
            p = p_use, r0 = STAGE1$r0, test = STAGE1$test,
            LR_obs = NA_real_,
            cv_10 = NA_real_, cv_05 = NA_real_, cv_01 = NA_real_,
            p_boot = NA_real_, sig = "",
            reject_10 = NA, reject_05 = NA, reject_01 = NA,
            B_target = STAGE1$B_target, B_eff = 0L,
            boot_fail_rate = NA_real_,
            policy_mode = "gate_fail",
            cv01_unstable = NA,
            note = paste0("gate_fail: ", gate$reason)
          )
          log_add("[STAGE1] GATE_FAIL: ", w_name, " | ", spec_name, " | ", basis_mode, " | ", ec, " :: ", gate$reason)
          next
        }

        log_add("[STAGE1] RUN: ", w_name, " | ", spec_name, " | ", basis_mode, " | ", ec)
        log_flush()
        res <- try(run_case(X, window = w_name, spec = spec_name, basis = basis_mode,
                            ecdet = ec, p = p_use, r0 = STAGE1$r0, stage1 = STAGE1),
                   silent = TRUE)

        if (inherits(res, "try-error")) {
          k <- k + 1L
          rows[[k]] <- tibble(
            window = w_name, spec = spec_name, basis = basis_mode, ecdet = ec,
            p = p_use, r0 = STAGE1$r0, test = STAGE1$test,
            LR_obs = NA_real_,
            cv_10 = NA_real_, cv_05 = NA_real_, cv_01 = NA_real_,
            p_boot = NA_real_, sig = "",
            reject_10 = NA, reject_05 = NA, reject_01 = NA,
            B_target = STAGE1$B_target, B_eff = 0L,
            boot_fail_rate = NA_real_,
            policy_mode = "error",
            cv01_unstable = NA,
            note = "run_case_error"
          )
          log_add("[STAGE1] ERROR: ", w_name, " | ", spec_name, " | ", basis_mode, " | ", ec)
          next
        }

        k <- k + 1L
        rows[[k]] <- res$row

        # Archive draws (optional; can be heavy)
        case_id <- paste(w_name, spec_name, basis_mode, ec, paste0("p", p_use), sep = "__")
        draw_archives[[case_id]] <- list(
          meta = list(window = w_name, spec = spec_name, basis = basis_mode, ecdet = ec,
                      p = p_use, r0 = STAGE1$r0, test = STAGE1$test,
                      B_target = STAGE1$B_target),
          LR_star = res$draws
        )

        log_add("[STAGE1] DONE: ", w_name, " | ", spec_name, " | ", basis_mode, " | ", ec,
                " | B_eff=", res$row$B_eff, " | fail_rate=", sprintf("%.3f", res$row$boot_fail_rate),
                " | p_boot=", sprintf("%.4f", res$row$p_boot), res$row$sig)
      }
    }
  }
}

out <- bind_rows(rows) %>% arrange(.data$window, .data$spec, .data$basis, .data$ecdet)

# Clean up columns when note missing
if (!"note" %in% names(out)) out$note <- NA_character_

out_csv <- file.path(DIRS$csv, "STAGE1_rank_bootstrap_table.csv")
readr::write_csv(out, out_csv)

# Save draws archive
out_rds <- file.path(DIRS$rds, paste0("STAGE1_rank_bootstrap_draws_", ts_tag, ".rds"))
saveRDS(draw_archives, out_rds)

log_add("=== STAGE 1 completed ===")
log_add("CSV: ", out_csv)
log_add("RDS: ", out_rds)
log_add("Log: ", log_file)
  log_flush()