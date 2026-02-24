############################################################
# 39_stage0_diagnostics_tsdyn.R — Stage 0 diagnostics (tsDyn)
#
# PURPOSE
#
# This script performs the pre–bootstrap diagnostic gate for the
# tsDyn migration branch.  It replicates the behaviour of the
# legacy Stage 0 script but uses the tsDyn VECM implementation
# where possible.  The goal is to assess the residual
# environment (serial correlation, heteroskedasticity, tails) and
# record the structural/admissibility status of each case.  No
# rank inference is performed here.
#
# OUTPUT
#
# Writes a CSV table of diagnostics to
#   output/InferenceRank_tsDyn/csv/STAGE0_diagnostics_table.csv
# and a human–readable log to
#   output/InferenceRank_tsDyn/logs/stage0_<timestamp>.log
#
############################################################

suppressPackageStartupMessages({
  library(here)
  library(readxl)
  library(dplyr)
  library(tibble)
  # tsDyn and urca are optional; we check for them at runtime
})

# Load config and utils
source(here::here("codes", "10_config_tsdyn.R"))
source(here::here("codes", "99_tsdyn_utils.R"))

set_seed_deterministic(CONFIG$seed %||% 123456L)

# ------------------------------------------------------------
# Logging setup
# ------------------------------------------------------------
OUT_ROOT <- here::here(CONFIG$OUT_RANK)
DIRS <- list(
  csv  = file.path(OUT_ROOT, "csv"),
  logs = file.path(OUT_ROOT, "logs")
)
ensure_dirs(OUT_ROOT, unlist(DIRS, use.names = FALSE))

ts_tag   <- format(Sys.time(), "%Y%m%d_%H%M%S")
log_file <- file.path(DIRS$logs, paste0("stage0_", ts_tag, ".log"))
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
on.exit(log_flush(), add = TRUE)

log_add("=== STAGE 0 diagnostics (tsDyn) start ===")
log_add("Timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
log_add("Project root: ", here::here())
log_add("OUT_ROOT: ", OUT_ROOT)

# ------------------------------------------------------------
# Helpers: read data, slice window, portmanteau and ARCH tests
# ------------------------------------------------------------
resolve_path <- function(p) {
  if (is.null(p) || !nzchar(p)) stop("CONFIG$data_file is empty.")
  if (grepl("^([A-Za-z]:\\\\|/)", p)) return(normalizePath(p, winslash = "/", mustWork = FALSE))
  normalizePath(here::here(p), winslash = "/", mustWork = FALSE)
}

DATA_FILE  <- resolve_path(CONFIG$data_file)
DATA_SHEET <- CONFIG$data_sheet
log_add("Data file (resolved): ", DATA_FILE)
log_add("Data sheet: ", DATA_SHEET)

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

# Portmanteau test for serial correlation at lag K0
portmanteau_Q <- function(E, K0 = 8L) {
  E <- as.matrix(E)
  Tn <- nrow(E); m <- ncol(E)
  C0 <- crossprod(E) / Tn
  C0i <- try(solve(C0), silent = TRUE)
  if (inherits(C0i, "try-error")) return(list(stat = NA_real_, p = NA_real_, K0 = K0, df = NA_integer_))
  Q <- 0
  for (k in seq_len(K0)) {
    Ek <- E[(k + 1):Tn, , drop = FALSE]
    E0 <- E[1:(Tn - k), , drop = FALSE]
    Ck <- crossprod(Ek, E0) / Tn
    Q <- Q + sum(diag(t(Ck) %*% C0i %*% Ck %*% C0i)) * (Tn^2 / (Tn - k))
  }
  df <- (m^2) * K0
  p  <- 1 - stats::pchisq(Q, df = df)
  list(stat = Q, p = p, K0 = K0, df = df)
}

# ARCH LM test for conditional heteroskedasticity on a univariate series
arch_lm <- function(eps, q = 4L) {
  eps <- as.numeric(eps)
  n <- length(eps)
  if (n <= q) return(list(stat = NA_real_, p = NA_real_, df = q))
  u2 <- eps^2 - mean(eps^2)
  X <- embed(u2, q + 1)
  y <- X[, 1]
  Xreg <- X[, -1, drop = FALSE]
  fit <- try(lm(y ~ Xreg), silent = TRUE)
  if (inherits(fit, "try-error")) return(list(stat = NA_real_, p = NA_real_, df = q))
  R2 <- summary(fit)$r.squared
  LM <- R2 * length(y)
  pval <- 1 - pchisq(LM, df = q)
  list(stat = LM, p = pval, df = q)
}

# Skewness and kurtosis helper
skewness_vec <- function(x) {
  x <- as.numeric(x)
  m <- mean(x)
  s <- sd(x)
  if (s == 0) return(0)
  mean(((x - m) / s)^3)
}
kurtosis_vec <- function(x) {
  x <- as.numeric(x)
  m <- mean(x)
  s <- sd(x)
  if (s == 0) return(0)
  mean(((x - m) / s)^4)
}

# Read data and compute full orthogonal basis
df_full <- read_data()

# Precompute orthonormal basis on full sample for each degree
A_full <- list()
for (nm in names(CONFIG$SPECS)) {
  deg <- as.integer(CONFIG$SPECS[[nm]]$degree)
  # Fit basis only if orthogonalisation is requested later
  A_full[[as.character(deg)]] <- fit_ortho_A(df_full, e_col = CONFIG$e_col, degree = deg)
}

# Get deterministic pairs
det_table <- det_pairs(CONFIG)

# Result accumulator
rows <- list()

# Iterate windows first (full, fordism, post_fordism)
for (win_name in names(CONFIG$WINDOWS_LOCKED)) {
  win <- CONFIG$WINDOWS_LOCKED[[win_name]]
  dfw <- slice_window(df_full, win)
  if (nrow(dfw) < 10) {
    log_add("Window ", win_name, ": too few observations. Skipping.")
    next
  }
  for (spec_name in names(CONFIG$SPECS)) {
    spec <- CONFIG$SPECS[[spec_name]]
    degree <- as.integer(spec$degree)
    for (ortho_flag in CONFIG$ORTHO_TOGGLE) {
      basis_mode <- if (isTRUE(ortho_flag)) "ortho" else "raw"
      for (i in seq_len(nrow(det_table))) {
        det_row <- det_table[i, ]
        # Build state matrix
        X <- tryCatch({
          build_state_vector(
            dfw,
            spec,
            basis_mode = basis_mode,
            include_e_raw = CONFIG$INCLUDE_E_RAW,
            A_full = A_full
          )
        }, error = function(e) {
          NULL
        })
        gate1_ok <- !is.null(X) && all(is.finite(as.matrix(X)))
        gate2 <- list(ok = FALSE, reason = "gate1_fail")
        if (gate1_ok) {
          gate2 <- admissible_gate(as.matrix(X), p = CONFIG$p_vecm_default)
        }
        # Default metrics
        serial_ok <- NA
        arch_any  <- NA
        arch_share <- NA
        skew_mean <- NA
        kurt_mean <- NA
        p_Q4 <- NA
        p_Q8 <- NA
        if (gate1_ok && gate2$ok) {
          # Fit r=1 VECM for residuals
          det_flags <- list(
            include    = det_row$include,
            LRinclude  = det_row$LRinclude,
            sr_intercept = det_row$sr_intercept,
            sr_trend     = det_row$sr_trend
          )
          resid_mat <- NULL
          # Try tsDyn first if available
          if (.pkg("tsDyn")) {
            lag_info <- map_lags(CONFIG$p_vecm_default)
            vecm_try <- safe_try(
              tsDyn::VECM(
                data = X,
                lag = lag_info$lag_tsdyn,
                r = 1L,
                include = det_row$include,
                LRinclude = det_row$LRinclude,
                estim = "ML"
              )
            )
            if (vecm_try$ok) {
              # Extract residuals; tsDyn VECM has a $residuals component
              resid_mat <- tryCatch(as.matrix(vecm_try$value$residuals), error = function(e) NULL)
            }
          }
          # If tsDyn unavailable or failed, fallback to urca for residuals
          if (is.null(resid_mat) && .pkg("urca")) {
            lag_info <- map_lags(CONFIG$p_vecm_default)
            jo <- try(urca::ca.jo(X, type = "trace", ecdet = det_row$LRinclude, K = lag_info$K_urca), silent = TRUE)
            if (!inherits(jo, "try-error")) {
              caj <- try(urca::cajorls(jo, r = 1L), silent = TRUE)
              if (!inherits(caj, "try-error")) {
                resid_mat <- try(as.matrix(caj$rlm$residuals), silent = TRUE)
              }
            }
          }
          if (!is.null(resid_mat) && nrow(resid_mat) > 10) {
            # Serial correlation: portmanteau Q at 4 and 8
            p_Q4 <- portmanteau_Q(resid_mat, K0 = 4L)$p
            p_Q8 <- portmanteau_Q(resid_mat, K0 = 8L)$p
            serial_ok <- isTRUE(p_Q4 > 0.05) && isTRUE(p_Q8 > 0.05)
            # ARCH LM per equation
            arch_pvals <- sapply(seq_len(ncol(resid_mat)), function(j) arch_lm(resid_mat[, j], q = 4L)$p)
            arch_any  <- any(arch_pvals < 0.05, na.rm = TRUE)
            arch_share <- mean(arch_pvals < 0.05, na.rm = TRUE)
            # Tails: average skewness and kurtosis across equations
            skews  <- sapply(seq_len(ncol(resid_mat)), function(j) skewness_vec(resid_mat[, j]))
            kurts  <- sapply(seq_len(ncol(resid_mat)), function(j) kurtosis_vec(resid_mat[, j]))
            skew_mean <- mean(skews, na.rm = TRUE)
            kurt_mean <- mean(kurts, na.rm = TRUE)
          }
        }
        # Collect row
        rows[[length(rows) + 1L]] <- tibble(
          window  = win_name,
          spec    = spec_name,
          basis   = basis_mode,
          DSR     = det_row$DSR,
          DLR     = det_row$DLR,
          det_tag = det_row$det_tag,
          include = det_row$include,
          LRinclude = det_row$LRinclude,
          p_vecm = CONFIG$p_vecm_default,
          gate1_ok = gate1_ok,
          gate2_ok = gate2$ok,
          gate2_reason = ifelse(gate2$ok, "", gate2$reason),
          serial_ok = serial_ok,
          p_Q4 = p_Q4,
          p_Q8 = p_Q8,
          arch_any = arch_any,
          arch_share = arch_share,
          skew_mean = skew_mean,
          kurt_mean = kurt_mean
        )
      }
    }
  }
}

# Bind results and write CSV
diag_tbl <- dplyr::bind_rows(rows)
out_csv <- file.path(DIRS$csv, "STAGE0_diagnostics_table.csv")
readr::write_csv(diag_tbl, out_csv)
log_add("Diagnostics table written to: ", out_csv)
log_add("Total rows: ", nrow(diag_tbl))

log_add("=== STAGE 0 diagnostics (tsDyn) end ===")