############################################################
## US Data Base + JOHANSEN GRID (ecdet x K) — CONSOLIDATED
## Fixes included:
##  (1) Windows/full-ford-post built inside script
##  (2) RIGHT-tail rejection (stat >= cv)
##  (3) Robust alpha handling (0.1 vs 0.10)
##  (4) POSITION-based storage (no name-index NA ranks)
##  (5) Base-R sorting (avoids window() collisions)
##  (6) ROBUST r-index mapping: locate the r=0 row then index by position
## Outputs: output/JOHANSEN_GRID/{csv,rds,logs}
############################################################

#### 0) Packages (hard deps only) ####
pkgs <- c(
  "here","readxl","dplyr","tidyr","ggplot2","zoo",
  "stats","knitr","kableExtra",
  "urca","vars","tseries","lmtest","sandwich","strucchange"
)
invisible(lapply(pkgs, require, character.only = TRUE))

# Optional packages (do not fail if missing)
if (!requireNamespace("patchwork", quietly = TRUE)) {
  message("Optional pkg missing (ok): patchwork")
}

#### 1) Preamble: paths, helpers, data ####
source(paste0(here::here("codes"), "/0_functions.R"))  # your consolidated helpers

data_path   <- here::here("data/processed/ddbb_cu_US_kgr.xlsx")
output_path <- here::here("output")

set_seed_deterministic()
ensure_dirs(output_path)

ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

#### 2) Build base variables (levels + diffs) ####
df <- ddbb_us |>
  dplyr::transmute(
    year      = .data$year,
    K         = .data$KGCRcorp,
    Y         = .data$Yrgdp,
    e         = .data$e,                # exploitation = profits / wage bill
    yk_input  = .data$yk,
    yk_calc   = .data$Yrgdp / .data$KGCRcorp,
    log_y     = log(.data$Yrgdp),
    log_k     = log(.data$KGCRcorp),
    log_yk    = log(yk_calc),
    e2        = (.data$e)^2,
    # differences (base)
    d_log_y   = log_y - dplyr::lag(log_y),
    d_log_k   = log_k - dplyr::lag(log_k),
    d_e       = e     - dplyr::lag(e)
  ) |>
  dplyr::arrange(year)

#### 3) Window-specific demean + interactions (incl. cubic) + diffs ####
add_e_bar_and_interactions <- function(dfw) {
  mu_e <- mean(dfw$e, na.rm = TRUE)
  
  dfw |>
    dplyr::arrange(year) |>
    dplyr::mutate(
      # demeaned exploitation and powers
      e_bar   = e - mu_e,
      e_bar2  = e_bar^2,
      e_bar3  = e_bar^3,
      
      # raw powers
      e2      = e^2,
      e3      = e^3,
      
      # raw interactions required by strategy
      logK_e   = log_k * e,
      logK_e2  = log_k * e2,
      logK_e3  = log_k * e3,
      
      # demeaned interactions (multicollinearity-safe basis)
      logK_ebar  = log_k * e_bar,
      logK_ebar2 = log_k * e_bar2,
      logK_ebar3 = log_k * e_bar3,
      
      # differences of constructed terms
      d_e_bar       = e_bar       - dplyr::lag(e_bar),
      d_logK_e      = logK_e      - dplyr::lag(logK_e),
      d_logK_e2     = logK_e2     - dplyr::lag(logK_e2),
      d_logK_e3     = logK_e3     - dplyr::lag(logK_e3),
      d_logK_ebar   = logK_ebar   - dplyr::lag(logK_ebar),
      d_logK_ebar2  = logK_ebar2  - dplyr::lag(logK_ebar2),
      d_logK_ebar3  = logK_ebar3  - dplyr::lag(logK_ebar3)
    )
}

#### 4) (Optional) Unit-root variable lists (continuity) ####
vars_lvl <- c(
  "log_y","log_k",
  "e","e_bar",
  "logK_e","logK_e2","logK_e3",
  "logK_ebar","logK_ebar2","logK_ebar3"
)
vars_dif <- c(
  "d_log_y","d_log_k",
  "d_e","d_e_bar",
  "d_logK_e","d_logK_e2","d_logK_e3",
  "d_logK_ebar","d_logK_ebar2","d_logK_ebar3"
)

############################################################
## JOHANSEN GRID — ecdet x K grid, rank decisions recorded
############################################################

## 0) Output dirs
grid_root <- file.path(output_path, "JOHANSEN_GRID")
grid_csv  <- file.path(grid_root, "csv")
grid_rds  <- file.path(grid_root, "rds")
grid_log  <- file.path(grid_root, "logs")
ensure_dirs(c(grid_root, grid_csv, grid_rds, grid_log))

## 1) Helpers (self-contained)
append_lines <- function(lines, path) {
  cat(paste0(lines, collapse = "\n"), "\n", file = path, append = TRUE)
}

make_X <- function(dfw, vars) {
  X <- dfw |>
    dplyr::select(dplyr::all_of(vars)) |>
    stats::na.omit() |>
    as.matrix()
  if (nrow(X) < 25) stop("Too few observations after NA omit for Johansen estimation.")
  X
}

safe_slot <- function(obj, slot_name) {
  if (!methods::is(obj, "ca.jo")) stop("Expected a urca 'ca.jo' object.")
  if (!slot_name %in% slotNames(obj)) return(NULL)
  slot(obj, slot_name)
}

# Robustly build r-index by POSITION:
# Find which row corresponds to "r=0" or "r<=0". If not found, fallback to last row as r=0
derive_r0_by_position <- function(H0) {
  H0c <- trimws(as.character(H0))
  idx0 <- which(grepl("^r\\s*=\\s*0$", H0c) | grepl("^r\\s*<=\\s*0$", H0c) | grepl("<=\\s*0$", H0c))
  if (length(idx0) == 0) idx0 <- length(H0c)  # common in urca prints: r=0 is last line
  idx0 <- idx0[1]
  # r0 is distance from the r=0 row
  r0 <- seq_along(H0c) - idx0
  r0
}


rank_table_from_jo <- function(jo_obj) {
  ts <- safe_slot(jo_obj, "teststat")
  cv <- safe_slot(jo_obj, "cval")
  if (is.null(ts) || is.null(cv)) stop("ca.jo missing teststat/cval slots.")
  
  ts_vec <- as.numeric(ts)
  
  # Handle either colname convention
  cn <- colnames(cv)
  if (all(c("10pct","5pct","1pct") %in% cn)) {
    cv_mat <- cv[, c("10pct","5pct","1pct"), drop = FALSE]
    colnames(cv_mat) <- c("10pct","5pct","1pct")
  } else if (all(c("1pct","5pct","10pct") %in% cn)) {
    cv_mat <- cv[, c("10pct","5pct","1pct"), drop = FALSE]  # reorder
    colnames(cv_mat) <- c("10pct","5pct","1pct")
  } else {
    stop("Unexpected cval colnames: ", paste(cn, collapse = ", "))
  }
  
  H0 <- rownames(ts)
  if (is.null(H0) || length(H0) == 0) H0 <- names(ts)
  if (is.null(H0) || length(H0) == 0) H0 <- rownames(cv_mat)
  if (is.null(H0) || length(H0) == 0) H0 <- paste0("r<=?", seq_along(ts_vec))
  
  n <- min(length(ts_vec), nrow(cv_mat), length(H0))
  
  out <- data.frame(
    H0    = as.character(H0[seq_len(n)]),
    stat  = ts_vec[seq_len(n)],
    cv_10 = as.numeric(cv_mat[seq_len(n), "10pct"]),
    cv_5  = as.numeric(cv_mat[seq_len(n), "5pct"]),
    cv_1  = as.numeric(cv_mat[seq_len(n), "1pct"]),
    stringsAsFactors = FALSE
  )
  
  # Parse r from H0 labels:
  # Examples: "r <= 0", "r<=1", "r = 0"
  H0c <- gsub("\\s+", "", out$H0)
  r_le <- suppressWarnings(as.integer(sub(".*<=([0-9]+).*", "\\1", H0c)))
  r_eq <- suppressWarnings(as.integer(sub(".*=([0-9]+).*",  "\\1", H0c)))
  
  out$r0 <- ifelse(grepl("<=", H0c), r_le, r_eq)
  
  # If parsing failed (rare), fall back to a safe monotone sequence
  if (anyNA(out$r0)) out$r0[is.na(out$r0)] <- seq_len(sum(is.na(out$r0))) - 1L
  
  # Right-tail rejection
  out$rej_10 <- out$stat >= out$cv_10
  out$rej_5  <- out$stat >= out$cv_5
  out$rej_1  <- out$stat >= out$cv_1
  
  # Sort by r ascending so suggest_rank() is meaningful
  out <- out[order(out$r0), ]
  rownames(out) <- NULL
  
  out
}



suggest_rank <- function(rt, alpha = 0.05) {
  a <- if (isTRUE(all.equal(alpha, 0.10))) 0.10 else
    if (isTRUE(all.equal(alpha, 0.05))) 0.05 else
      if (isTRUE(all.equal(alpha, 0.01))) 0.01 else NA_real_
  if (is.na(a)) stop("alpha must be one of 0.10, 0.05, 0.01")
  
  flag <- if (a == 0.10) rt$rej_10 else if (a == 0.05) rt$rej_5 else rt$rej_1
  
  # smallest r such that we FAIL to reject H0: r <= r
  idx <- which(!flag)
  if (length(idx) == 0) return(max(rt$r0) + 1L)  # means ">= m" effectively
  rt$r0[min(idx)]
}


## 2) Build windows + interactions
df_full <- df |>
  dplyr::filter(!is.na(log_y) & !is.na(log_k) & !is.na(e)) |>
  add_e_bar_and_interactions()

df_ford <- df |>
  dplyr::filter(year <= 1973) |>
  dplyr::filter(!is.na(log_y) & !is.na(log_k) & !is.na(e)) |>
  add_e_bar_and_interactions()

df_post <- df |>
  dplyr::filter(year >= 1974) |>
  dplyr::filter(!is.na(log_y) & !is.na(log_k) & !is.na(e)) |>
  add_e_bar_and_interactions()

windows <- list(full = df_full, ford = df_ford, post = df_post)

## 3) Grid definition
ECDET_GRID <- c("none", "const")
K_GRID     <- 2:5
ALPHA_GRID <- c(0.10, 0.05, 0.01)

# System spec (self-contained defaults)
SYS_VARS <- c("log_y", "log_k", "logK_e", "logK_e2")  # disciplined I(1) block
SPEC     <- "transitory"

## 4) Run the grid
grid_out <- list()

for (wname in names(windows)) {
  X  <- make_X(windows[[wname]], SYS_VARS)
  nT <- nrow(X)
  m  <- ncol(X)
  
  for (ecdet in ECDET_GRID) {
    for (K in K_GRID) {
      
      jo_trace <- urca::ca.jo(X, type = "trace", ecdet = ecdet, K = K, spec = SPEC)
      jo_eigen <- urca::ca.jo(X, type = "eigen", ecdet = ecdet, K = K, spec = SPEC)
      
      saveRDS(jo_trace, file.path(grid_rds, sprintf("jo_trace_%s_%s_K%d.rds", wname, ecdet, K)))
      saveRDS(jo_eigen, file.path(grid_rds, sprintf("jo_eigen_%s_%s_K%d.rds", wname, ecdet, K)))
      
      rt_tr <- rank_table_from_jo(jo_trace)
      rt_mx <- rank_table_from_jo(jo_eigen)
      
      # sanity checks: r must live in {0,...,m-1}
      stopifnot(all(rt_tr$r0 >= 0), all(rt_tr$r0 <= (m - 1)))
      stopifnot(all(rt_mx$r0 >= 0), all(rt_mx$r0 <= (m - 1)))
      
      sug_tr <- as.integer(sapply(ALPHA_GRID, function(a) suggest_rank(rt_tr, alpha = a)))
      sug_mx <- as.integer(sapply(ALPHA_GRID, function(a) suggest_rank(rt_mx, alpha = a)))
    
      
      grid_out[[length(grid_out) + 1L]] <- data.frame(
        window = wname,
        ecdet  = ecdet,
        K      = K,
        n      = nT,
        m      = m,
        r_trace_10 = sug_tr[1],
        r_trace_05 = sug_tr[2],
        r_trace_01 = sug_tr[3],
        r_eigen_10 = sug_mx[1],
        r_eigen_05 = sug_mx[2],
        r_eigen_01 = sug_mx[3],
        stringsAsFactors = FALSE
      )
      
      rpt <- file.path(grid_log, sprintf("grid_%s_%s_K%d.txt", wname, ecdet, K))
      writeLines(character(0), rpt)
      append_lines(c(
        "==============================================================",
        sprintf("JOHANSEN GRID | window=%s | ecdet=%s | K=%d", wname, ecdet, K),
        "==============================================================",
        sprintf("n=%d | m=%d | vars=%s", nT, m, paste(SYS_VARS, collapse = ", ")),
        "",
        "---- TRACE summary ----",
        capture.output(summary(jo_trace)),
        "",
        "---- MAX-EIGEN summary ----",
        capture.output(summary(jo_eigen)),
        "",
        "---- TRACE rank table (parsed) ----",
        capture.output(print(rt_tr)),
        "",
        "---- MAX-EIGEN rank table (parsed) ----",
        capture.output(print(rt_mx)),
        ""
      ), rpt)
    }
  }
}

## 5) Bind + export + Base-R sort/print
grid_rank_decisions <- dplyr::bind_rows(grid_out)

utils::write.csv(
  grid_rank_decisions,
  file.path(grid_csv, "grid_rank_decisions.csv"),
  row.names = FALSE
)

grid_rank_decisions <- grid_rank_decisions[
  order(grid_rank_decisions$window,
        grid_rank_decisions$ecdet,
        grid_rank_decisions$K),
]

print(grid_rank_decisions)
