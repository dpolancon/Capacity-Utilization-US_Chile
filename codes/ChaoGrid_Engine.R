############################################################
## ChaoGrid_Engine.R  (consolidated, robust, self-contained)
##
## Purpose:
##   Run Johansen grid search with PIC/BIC evaluation.
##   Export machine-readable artifacts only.
##
## Outputs: output/ChaoGrid/
##   csv/  : grid_pic_table.csv, grid_rank_decisions.csv
##   rds/  : grid_full.rds
##   logs/ : engine_log.txt
##
## Locked conventions:
##   - p = VAR lag length
##   - VECM uses (p-1) lags (implemented via ca.jo K = p+1)
##   - ecdet ∈ {none, const, trend}
##   - Identification system for theta(e):
##       log_y, log_k, logK_e = log_k*e, logK_e2 = log_k*e^2
############################################################

# ---- packages ----#  
pkgs <- c("here","readxl","dplyr","urca","vars")
invisible(lapply(pkgs, require, character.only = TRUE))

#--- Source and run helpers functions ------#
codes_path <- here("codes")
helpers_path <- here(codes_path,"0_functions.R")
source(helpers_path)

# penalties centralized (locked usage)
PIC_penalty <- function(T, k) log(T) * k / T
BIC_penalty <- function(T, k) log(T) * k

# simple parameter count proxy (keep centralized so you can swap later)
# NOTE: this is a proxy; if you have a locked count elsewhere, replace here only.
k_params_proxy <- function(m, p, r) {
  # VAR(p) params approx m^2 * p, cointegration space approx r*(2m - r)
  m^2 * p + r * (2*m - r)
}

## ---- paths + logging ----
ROOT_OUT <- here::here("output/ChaoGrid")
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  tex  = file.path(ROOT_OUT, "tex"),   # keep available even if you don't use it in engine
  figs = file.path(ROOT_OUT, "figs"),  # keep available even if you don't use it in engine
  rds  = file.path(ROOT_OUT, "rds"),
  logs = file.path(ROOT_OUT, "logs")
)
ensure_dirs(DIRS$csv, DIRS$tex, DIRS$figs, DIRS$rds, DIRS$logs)

log_file <- file.path(DIRS$logs, "engine_log.txt")
sink(log_file, split = TRUE)

cat("=== ChaoGrid Engine start ===\n")
cat("Project root:", here::here(), "\n")
cat("Output root :", ROOT_OUT, "\n\n")

set_seed_deterministic()

## ---- data: build windows (self-contained) ----
data_path <- here::here("data/processed/ddbb_cu_US_kgr.xlsx")
ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

df <- dplyr::transmute(
  ddbb_us,
  year  = .data$year,
  log_y = log(.data$Yrgdp),
  log_k = log(.data$KGCRcorp),
  e     = .data$e
) |>
  dplyr::arrange(.data$year) |>
  dplyr::filter(!is.na(.data$log_y), !is.na(.data$log_k), !is.na(.data$e)) |>
  dplyr::mutate(
    e2      = .data$e^2,
    e3      = .data$e^2,
    logK_e  = .data$log_k * .data$e,
    logK_e2 = .data$log_k * .data$e2
    logK_e3 = .data$log_k * .data$e3
  )

windows <- list(
  full = df,
  ford = dplyr::filter(df, .data$year <= 1973),
  post = dplyr::filter(df, .data$year >= 1974)
)

stopifnot(is.list(windows))
stopifnot(all(c("full","ford","post") %in% names(windows)))

cat("Windows built. N(full)=", nrow(windows$full),
    " N(ford)=", nrow(windows$ford),
    " N(post)=", nrow(windows$post), "\n\n")

## ---- system variables (theta(e) identification) ----
SYS_VARS_Q2 <- c("log_y","log_k","logK_e","logK_e2")
SYS_VARS_Q3 <- c("log_y","log_k","logK_e","logK_e2","logK_e3")

m_sys_Q2 <- length(SYS_VARS_Q2)
m_sys_Q3 <- length(SYS_VARS_Q3)


## ---- grid definition ----
GRID <- expand.grid(
  basis  = c("Q2","Q3"),
  window = names(windows),
  ecdet  = c("none","const","trend"),
  p      = 1:7,
  stringsAsFactors = FALSE
)

# enforce stable ordering
WINDOW_ORDER <- c("full","ford","post")
ECDET_ORDER  <- c("none","const","trend")
GRID <- GRID[order(match(GRID$window, WINDOW_ORDER),
                   match(GRID$ecdet,  ECDET_ORDER),
                   GRID$p), , drop = FALSE]

cat("Grid size =", nrow(GRID), "cells\n\n")

## ---- engine loop ----
pic_rows  <- list()
rank_rows <- list()

for (i in seq_len(nrow(GRID))) {
  
  g <- GRID[i, , drop = FALSE]
  wname <- g$window
  det   <- g$ecdet
  p     <- as.integer(g$p)
  
  SYS_VARS <- if (g$basis == "Q2") SYS_VARS_Q2 else SYS_VARS_Q3
  
  dfw <- windows[[wname]][, SYS_VARS, drop = FALSE] |> na.omit()
  dfw <- stats::na.omit(dfw)
  
  T_eff <- nrow(dfw)
  m     <- ncol(dfw)
  
  cat("Cell ", i, "/", nrow(GRID), ": window=", wname,
      " ecdet=", det, " p=", p, " (T=", T_eff, ", m=", m, ")\n", sep="")
  
  # Johansen uses K = p+1 so that the VECM has (p-1) lagged differences.
  jo <- try(
    urca::ca.jo(
      dfw,
      type  = "trace",    # rank tests computed here; eigen also available in @rank.test
      ecdet = det,
      K     = p + 1
    ),
    silent = TRUE
  )
  
  if (inherits(jo, "try-error")) {
    cat("  -> ca.jo failed. Skipping cell.\n\n")
    next
  }
  
  # rank decisions (these are "suggested r" at alpha, computed from test stats vs critvals)
  # urca stores test statistics and critical values; we derive suggested ranks by sequential testing.
  get_suggested_rank <- function(test_stats, crit_vals) {
    # test_stats/crit_vals are vectors over r = 0...(m-1)
    # suggested rank = max r such that test rejects H0(r) : rank <= r
    # In Johansen, tests are usually stated H0: rank <= r.
    # If stat > crit => reject, so rank is at least r+1.
    rej <- as.numeric(test_stats) > as.numeric(crit_vals)
    if (!any(rej, na.rm = TRUE)) return(0L)
    as.integer(max(which(rej), na.rm = TRUE))
  }
  
  # trace and eigen test stats
  tr_stat <- jo@teststat
  tr_cval <- jo@cval
  eg_stat <- jo@lambda
  eg_cval <- jo@cval
  
  # For safety: urca uses matrices for cval; columns are "10pct","5pct","1pct"
  r_trace_10 <- get_suggested_rank(tr_stat, tr_cval[, "10pct"])
  r_trace_05 <- get_suggested_rank(tr_stat, tr_cval[, "5pct"])
  r_trace_01 <- get_suggested_rank(tr_stat, tr_cval[, "1pct"])
  
  # eigen is not directly in @cval in same shape for all versions; use @cval and @lambda teststat logic
  # Many urca versions store eigen test in jo@lambda, with same critical values matrix.
  r_eigen_10 <- get_suggested_rank(eg_stat, eg_cval[, "10pct"])
  r_eigen_05 <- get_suggested_rank(eg_stat, eg_cval[, "5pct"])
  r_eigen_01 <- get_suggested_rank(eg_stat, eg_cval[, "1pct"])
  
  rank_rows[[length(rank_rows) + 1]] <- data.frame(
    window     = wname,
    ecdet      = det,
    p          = p,
    T          = T_eff,
    m          = m,
    r_trace_10 = r_trace_10,
    r_trace_05 = r_trace_05,
    r_trace_01 = r_trace_01,
    r_eigen_10 = r_eigen_10,
    r_eigen_05 = r_eigen_05,
    r_eigen_01 = r_eigen_01,
    stringsAsFactors = FALSE
  )
  
  # PIC/BIC evaluation over r = 0...(m-1)
  for (r in 0:(m-1)) {
    
    # residuals
    if (r == 0) {
      # r=0: VAR in differences with same p (no EC term)
      varfit <- vars::VAR(diff(as.matrix(dfw)), p = p, type = "none")
      resids <- stats::resid(varfit)
    } else {
      vecm   <- vars::vec2var(jo, r = r)
      resids <- stats::resid(vecm)
    }
    
    logdet <- safe_logdet(resids)
    
    k_par <- k_params_proxy(m = m, p = p, r = r)
    
    PIC <- logdet + PIC_penalty(T_eff, k_par)
    BIC <- logdet + BIC_penalty(T_eff, k_par)
    
    pic_rows[[length(pic_rows) + 1]] <- data.frame(
      window = wname,
      ecdet  = det,
      p      = p,
      r      = r,
      T      = T_eff,
      m      = m,
      logdet = logdet,
      k_par  = k_par,
      PIC    = PIC,
      BIC    = BIC,
      stringsAsFactors = FALSE
    )
  }
  
  cat("  -> done.\n\n")
}

## ---- assemble + export ----
grid_pic_table <- dplyr::bind_rows(pic_rows)
grid_rank_decisions <- dplyr::bind_rows(rank_rows)

# stable ordering in exports
grid_pic_table <- grid_pic_table |>
  dplyr::mutate(
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER)
  ) |>
  dplyr::arrange(window, ecdet, p, r) |>
  dplyr::mutate(window = as.character(window), ecdet = as.character(ecdet))

grid_rank_decisions <- grid_rank_decisions |>
  dplyr::mutate(
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER)
  ) |>
  dplyr::arrange(window, ecdet, p) |>
  dplyr::mutate(window = as.character(window), ecdet = as.character(ecdet))


utils::write.csv(filter(grid_pic_table, basis=="Q2"), file.path(DIRS$csv,"grid_pic_table_Q2.csv"), row.names=FALSE)
utils::write.csv(filter(grid_pic_table, basis=="Q3"), file.path(DIRS$csv,"grid_pic_table_Q3.csv"), row.names=FALSE)

utils::write.csv(grid_rank_decisions,
                 file.path(DIRS$csv, "grid_rank_decisions.csv"),
                 row.names = FALSE)

grid_full <- list(grid = GRID,SYS_VARS = SYS_VARS, windows_sizes = lapply(windows, nrow), 
                  pic_table = grid_pic_table, rank_decisions = grid_rank_decisions)

saveRDS(grid_full,file.path(DIRS$rds, "grid_full.rds"))

cat("=== Engine completed ===\n")
cat("PIC table rows :", nrow(grid_pic_table), "\n")
cat("Rank table rows:", nrow(grid_rank_decisions), "\n")
cat("Exports written to:", ROOT_OUT, "\n")

sink()
