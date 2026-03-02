############################################################
# 39_stage0_diagnostics.R — Stage 0 Pre-Bootstrap Diagnostics
# Repo: capacity_utilization/
#
# PURPOSE
# Stage 0 is a diagnostic gate before bootstrap rank inference.
# - HARD GATE: residual serial correlation (repair ladder for p)
# - SOFT ROUTING: heteroskedasticity + tails justify wild bootstrap
# - NO rank conclusions.
#
# Self-contained:
#   sources codes/10_config.R and codes/99_utils.R
# Logging: writeLines (NO sinks)
#
# OUTPUTS
# - output/Inference/csv/STAGE0_diagnostics_table.csv
# - output/Inference/logs/stage0_<timestamp>.log
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
OUT_ROOT <- here::here("output", "Inference")
DIRS <- list(
  csv  = file.path(OUT_ROOT, "csv"),
  figs = file.path(OUT_ROOT, "figs"),
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

log_add("=== STAGE 0 diagnostics start ===")
log_add("Timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
log_add("Project root (here): ", here::here())
log_add("OUT_ROOT: ", OUT_ROOT)

# -------------------------
# 2) Resolve data path robustly
# -------------------------
resolve_path <- function(p) {
  if (is.null(p) || !nzchar(p)) stop("CONFIG$data_file is empty.")
  # if already absolute, keep; else resolve relative to project root
  if (grepl("^([A-Za-z]:\\\\|/)", p)) return(normalizePath(p, winslash = "/", mustWork = FALSE))
  normalizePath(here::here(p), winslash = "/", mustWork = FALSE)
}

DATA_FILE  <- resolve_path(CONFIG$data_file)
DATA_SHEET <- CONFIG$data_sheet

log_add("Data file (resolved): ", DATA_FILE)
log_add("Data sheet: ", DATA_SHEET)

#check_file(DATA_FILE)  # uses your utils; throws if missing

# -------------------------
# 3) Helpers: read, windows, basis, system matrix
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

# raw powers basis Qj = e^j
basis_apply_rawpowers <- function(df, degree = 2L, prefix = "Q") {
  e <- as.numeric(df$e)
  out <- as.data.frame(sapply(seq_len(degree), function(j) e^j))
  names(out) <- paste0(prefix, seq_len(degree))
  out
}

# fit QR basis on FULL sample (orthogonalize raw powers)
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
# 4) Diagnostics functions
# -------------------------
portmanteau_Q <- function(E, K0 = 8L) {
  E <- as.matrix(E)
  Tn <- nrow(E); m <- ncol(E)
  C0 <- crossprod(E) / Tn
  C0i <- try(solve(C0), silent = TRUE)
  if (inherits(C0i, "try-error")) return(list(stat = NA_real_, p = NA_real_, K0 = K0, df = NA_integer_))
  
  Q <- 0
  for (k in seq_len(K0)) {
    Ek <- E[(k+1):Tn, , drop = FALSE]
    E0 <- E[1:(Tn-k), , drop = FALSE]
    Ck <- crossprod(Ek, E0) / Tn
    Q <- Q + sum(diag(t(Ck) %*% C0i %*% Ck %*% C0i)) * (Tn^2 / (Tn - k))
  }
  df <- (m^2) * K0
  p  <- 1 - stats::pchisq(Q, df = df)
  list(stat = Q, p = p, K0 = K0, df = df)
}

arch_lm <- function(eps, q = 4L) {
  eps <- as.numeric(eps)
  Tn <- length(eps)
  if (Tn <= (q + 10)) return(list(stat = NA_real_, p = NA_real_, q = q))
  y <- eps^2
  Y <- y[(q+1):Tn]
  X <- sapply(seq_len(q), function(k) y[(q+1-k):(Tn-k)])
  X <- cbind(1, X)
  fit <- stats::lm(Y ~ X - 1)
  R2  <- summary(fit)$r.squared
  stat <- length(Y) * R2
  p <- 1 - stats::pchisq(stat, df = q)
  list(stat = stat, p = p, q = q)
}

skewness <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 10) return(NA_real_)
  m <- mean(x); s <- sd(x)
  if (!is.finite(s) || s == 0) return(NA_real_)
  mean(((x - m)/s)^3)
}

kurtosis <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 10) return(NA_real_)
  m <- mean(x); s <- sd(x)
  if (!is.finite(s) || s == 0) return(NA_real_)
  mean(((x - m)/s)^4)
}

fit_residuals_johansen <- function(X, p, ecdet) {
  X <- as.matrix(X)
  K <- as.integer(p + 1L)  # repo convention
  cajo <- urca::ca.jo(X, type = "trace", ecdet = ecdet, K = K, spec = CONFIG$johansen_spec)
  rl <- urca::cajorls(cajo, r = 1L)  # maintained rank for residual diagnostics only
  E <- rl$rlm$residuals
  colnames(E) <- colnames(X)
  E
}

# -------------------------
# 5) Main loop
# -------------------------
df <- read_data()

# fit orthogonal basis on FULL sample for each degree
ORTHO_BASIS <- list()
for (nm in names(CONFIG$SPECS)) {
  deg <- CONFIG$SPECS[[nm]]$degree
  ORTHO_BASIS[[as.character(deg)]] <- basis_fit_orthogonal(df, degree = deg)
}

windows <- CONFIG$WINDOWS_LOCKED
ecdets  <- CONFIG$ECDET_LOCKED

# Repair ladder for Stage 0 gate
p_ladder <- c(1L, 2L)

results <- list()
idx <- 0L

for (w_name in names(windows)) {
  dfw <- slice_window(df, windows[[w_name]])
  
  for (spec_name in names(CONFIG$SPECS)) {
    deg <- CONFIG$SPECS[[spec_name]]$degree
    
    for (basis_mode in c("raw", "ortho")) {
      X <- build_system_matrix(dfw, degree = deg, basis_mode = basis_mode, ORTHO_BASIS = ORTHO_BASIS)
      Tn <- nrow(X); m <- ncol(X)
      
      for (ec in ecdets) {
        
        chosen_p <- NA_integer_
        sc_pass  <- FALSE
        sc_note  <- ""
        sc_q4 <- sc_p4 <- sc_q8 <- sc_p8 <- NA_real_
        E_final <- NULL
        
        for (p_try in p_ladder) {
          gate <- admissible_gate(X, p = p_try)
          if (!isTRUE(gate$ok)) {
            sc_note <- paste0("feasibility_fail@p=", p_try, ": ", gate$reason)
            next
          }
          
          E <- try(fit_residuals_johansen(X, p = p_try, ecdet = ec), silent = TRUE)
          if (inherits(E, "try-error")) {
            sc_note <- paste0("johansen_fail@p=", p_try)
            next
          }
          
          q4 <- portmanteau_Q(E, K0 = 4L)
          q8 <- portmanteau_Q(E, K0 = 8L)
          sc_q4 <- q4$stat; sc_p4 <- q4$p
          sc_q8 <- q8$stat; sc_p8 <- q8$p
          
          if (is.finite(sc_p4) && is.finite(sc_p8) && sc_p4 > 0.05 && sc_p8 > 0.05) {
            chosen_p <- p_try
            sc_pass  <- TRUE
            E_final  <- E
            sc_note  <- "pass"
            break
          }
          
          if (p_try == max(p_ladder)) {
            chosen_p <- p_try
            sc_pass  <- FALSE
            E_final  <- E
            sc_note  <- "borderline_or_fail"
          }
        }
        
        if (is.null(E_final)) {
          idx <- idx + 1L
          results[[idx]] <- tibble(
            window = w_name, spec = spec_name, basis = basis_mode, ecdet = ec,
            T = Tn, m = m, p = NA_integer_,
            serial_pass = FALSE,
            port_Q4 = sc_q4, port_p4 = sc_p4,
            port_Q8 = sc_q8, port_p8 = sc_p8,
            arch_any = NA, arch_share = NA_real_,
            skew_avg = NA_real_, kurt_avg = NA_real_,
            outlier_flag = NA,
            note = paste0("no_residuals: ", sc_note)
          )
          log_add("[STAGE0] FAIL: ", w_name, " | ", spec_name, " | ", basis_mode, " | ", ec, " | ", sc_note)
          next
        }
        
        arch_p <- rep(NA_real_, ncol(E_final))
        sk <- rep(NA_real_, ncol(E_final))
        ku <- rep(NA_real_, ncol(E_final))
        
        for (j in seq_len(ncol(E_final))) {
          aj <- arch_lm(E_final[, j], q = 4L)
          arch_p[j] <- aj$p
          sk[j] <- skewness(E_final[, j])
          ku[j] <- kurtosis(E_final[, j])
        }
        
        arch_any   <- any(is.finite(arch_p) & arch_p < 0.05)
        arch_share <- mean(is.finite(arch_p) & arch_p < 0.05)
        
        # outlier dominance (very conservative)
        outlier_flag <- NA
        C0 <- try(stats::cov(E_final), silent = TRUE)
        if (!inherits(C0, "try-error")) {
          C0i <- try(solve(C0), silent = TRUE)
          if (!inherits(C0i, "try-error")) {
            s <- rowSums((E_final %*% C0i) * E_final)
            thr <- stats::quantile(s, 0.99, na.rm = TRUE)
            outlier_flag <- any(s > thr * 3, na.rm = TRUE)
          }
        }
        
        idx <- idx + 1L
        results[[idx]] <- tibble(
          window = w_name, spec = spec_name, basis = basis_mode, ecdet = ec,
          T = Tn, m = m, p = chosen_p,
          serial_pass = sc_pass,
          port_Q4 = sc_q4, port_p4 = sc_p4,
          port_Q8 = sc_q8, port_p8 = sc_p8,
          arch_any = arch_any,
          arch_share = arch_share,
          skew_avg = mean(sk, na.rm = TRUE),
          kurt_avg = mean(ku, na.rm = TRUE),
          outlier_flag = outlier_flag,
          note = sc_note
        )
        
        log_add("[STAGE0] ",
                w_name, " | ", spec_name, " | ", basis_mode, " | ", ec,
                " | p=", chosen_p,
                " | serial_pass=", sc_pass,
                " | arch_any=", arch_any)
      }
    }
  }
}

out <- bind_rows(results) %>% arrange(.data$window, .data$spec, .data$basis, .data$ecdet)
out_file <- file.path(DIRS$csv, "STAGE0_diagnostics_table.csv")
readr::write_csv(out, out_file)

log_add("=== STAGE 0 completed ===")
log_add("CSV: ", out_file)
log_add("Log: ", log_file)