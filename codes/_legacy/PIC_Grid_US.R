############################################################
## US Data Base + JOHANSEN GRID + PIC (Chao/Phillips-style)
##
## Grid:
##   window ∈ {full, ford, post}
##   ecdet  ∈ {"none","const"}
##   K      ∈ {2,3,4,5}   (Johansen K; VECM/VAR lag p = K-1)
##
## For each (window, ecdet, K):
##   (1) Johansen trace + max-eigen rank suggestions at alpha = 10/5/1%
##   (2) PIC + BIC over r = 0..(m-1)
##       - r >= 1 via vec2var(ca.jo, r)
##       - r = 0 via VAR(diff(X), p=K-1)
##
## Outputs:
##   output/JOHANSEN_GRID/csv/grid_rank_decisions.csv
##   output/JOHANSEN_GRID/csv/grid_pic_table.csv
##   output/JOHANSEN_GRID/csv/grid_pic_best.csv
##   output/JOHANSEN_GRID/rds/*.rds
##   output/JOHANSEN_GRID/logs/*.txt
############################################################

#### 0) Packages (hard deps only) ####
pkgs <- c(
  "here","readxl","dplyr","tidyr","ggplot2","zoo",
  "stats","knitr","kableExtra",
  "urca","vars","tseries","lmtest","sandwich","strucchange"
)
invisible(lapply(pkgs, require, character.only = TRUE))

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
      
      # raw interactions
      logK_e   = log_k * e,
      logK_e2  = log_k * e2,
      logK_e3  = log_k * e3,
      
      # demeaned interactions
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

#### 4) Build windows + interactions ####
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

############################################################
## 5) Output dirs
############################################################
grid_root <- file.path(output_path, "JOHANSEN_GRID")
grid_csv  <- file.path(grid_root, "csv")
grid_rds  <- file.path(grid_root, "rds")
grid_log  <- file.path(grid_root, "logs")
ensure_dirs(c(grid_root, grid_csv, grid_rds, grid_log))

############################################################
## 6) Helpers
############################################################
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

# Build a rank table from ca.jo with right-tail rejection
rank_table_from_jo <- function(jo_obj) {
  ts <- safe_slot(jo_obj, "teststat")
  cv <- safe_slot(jo_obj, "cval")
  if (is.null(ts) || is.null(cv)) stop("ca.jo missing teststat/cval slots.")
  
  ts_vec <- as.numeric(ts)
  
  # urca critical values are typically colnames: "10pct","5pct","1pct"
  need <- c("10pct","5pct","1pct")
  if (!all(need %in% colnames(cv))) {
    stop("Unexpected cval colnames: ", paste(colnames(cv), collapse = ", "))
  }
  cv_mat <- cv[, need, drop = FALSE]
  
  H0 <- rownames(ts)
  if (is.null(H0) || length(H0) == 0) H0 <- names(ts)
  if (is.null(H0) || length(H0) == 0) H0 <- rownames(cv_mat)
  if (is.null(H0) || length(H0) == 0) H0 <- paste0("H0 row ", seq_along(ts_vec))
  
  n <- min(length(ts_vec), nrow(cv_mat), length(H0))
  
  out <- data.frame(
    H0    = H0[seq_len(n)],
    stat  = ts_vec[seq_len(n)],
    cv_10 = as.numeric(cv_mat[seq_len(n), "10pct"]),
    cv_5  = as.numeric(cv_mat[seq_len(n), "5pct"]),
    cv_1  = as.numeric(cv_mat[seq_len(n), "1pct"]),
    stringsAsFactors = FALSE
  )
  
  # In urca, test rows correspond to r = 0..(m-1) in the given order
  out$r0 <- 0:(n - 1)
  
  # right-tail rejection
  out$rej_10 <- out$stat >= out$cv_10
  out$rej_5  <- out$stat >= out$cv_5
  out$rej_1  <- out$stat >= out$cv_1
  
  out
}

# Suggested rank: smallest r such that we FAIL to reject H0: r <= r
suggest_rank <- function(rt, alpha = 0.05) {
  a <- if (isTRUE(all.equal(alpha, 0.10))) 0.10 else
    if (isTRUE(all.equal(alpha, 0.05))) 0.05 else
      if (isTRUE(all.equal(alpha, 0.01))) 0.01 else NA_real_
  if (is.na(a)) stop("alpha must be one of 0.10, 0.05, 0.01")
  
  flag <- if (a == 0.10) rt$rej_10 else if (a == 0.05) rt$rej_5 else rt$rej_1
  idx <- which(!flag)
  if (length(idx) == 0) return(max(rt$r0) + 1L)
  rt$r0[min(idx)]
}

############################################################
## 7) PIC helpers
############################################################
ecdet_to_var_type <- function(ecdet) {
  if (ecdet == "none")  return("none")
  if (ecdet == "const") return("const")
  stop("Unsupported ecdet for VAR mapping: ", ecdet)
}

logdet_cov <- function(E) {
  Sigma <- stats::cov(E)
  detobj <- determinant(Sigma, logarithm = TRUE)
  as.numeric(detobj$modulus)
}

pic_penalty <- function(T, m, p, r) {
  # Chao/Phillips-style approximation (your working penalty)
  (m^2 * p + 2 * r * (m - r) + m * r) * (log(T) / T)
}

bic_penalty <- function(T, m, p, r) {
  # Simple BIC-style penalty (for comparison)
  (m^2 * p + r * (m - r) + m * r) * (log(T) / T)
}

compute_pic_over_ranks <- function(jo_obj, X_levels, K, ecdet, window_name) {
  # For r>=1: vec2var(jo_obj, r)
  # For r=0: VAR(diff(X_levels), p=K-1)
  p <- K - 1
  m <- ncol(X_levels)
  dX <- diff(X_levels)
  
  rows <- list()
  
  for (r in 0:(m - 1)) {
    
    if (r == 0) {
      v0 <- vars::VAR(dX, p = p, type = ecdet_to_var_type(ecdet))
      E  <- as.matrix(stats::residuals(v0))
    } else {
      v  <- vars::vec2var(jo_obj, r = r)
      E  <- as.matrix(stats::residuals(v))
    }
    
    T_here <- nrow(E)
    ld <- logdet_cov(E)
    
    rows[[length(rows) + 1L]] <- data.frame(
      window = window_name,
      ecdet  = ecdet,
      K      = K,
      p      = p,
      r      = r,
      T      = T_here,
      m      = m,
      logdet = ld,
      PIC    = ld + pic_penalty(T_here, m, p, r),
      BIC    = ld + bic_penalty(T_here, m, p, r),
      stringsAsFactors = FALSE
    )
  }
  
  dplyr::bind_rows(rows)
}

############################################################
## 8) Grid definition (edit here if needed)
############################################################
ECDET_GRID <- c("none", "const")
K_GRID     <- 2:5
ALPHA_GRID <- c(0.10, 0.05, 0.01)

# Disciplined I(1) block
SYS_VARS <- c("log_y", "log_k", "logK_e", "logK_e2")
SPEC     <- "transitory"

############################################################
## 9) Run Johansen grid + PIC
############################################################
grid_out <- list()
pic_out  <- list()

for (wname in names(windows)) {
  
  X <- make_X(windows[[wname]], SYS_VARS)
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
      
      sug_tr <- as.integer(sapply(ALPHA_GRID, function(a) suggest_rank(rt_tr, alpha = a)))
      sug_mx <- as.integer(sapply(ALPHA_GRID, function(a) suggest_rank(rt_mx, alpha = a)))
      
      # defensive clamp to [0, m-1]
      sug_tr <- pmin(pmax(sug_tr, 0L), m - 1L)
      sug_mx <- pmin(pmax(sug_mx, 0L), m - 1L)
      
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
      
      # PIC table over r=0..m-1 (use trace object; eigen/trace only differs in test statistic)
      pic_tab <- compute_pic_over_ranks(
        jo_obj      = jo_trace,
        X_levels    = X,
        K           = K,
        ecdet       = ecdet,
        window_name = wname
      )
      pic_out[[length(pic_out) + 1L]] <- pic_tab
      
      # Log
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
        "",
        "---- PIC table (r=0..m-1) ----",
        capture.output(print(pic_tab))
      ), rpt)
    }
  }
}

############################################################
## 10) Bind + export + sort
############################################################
grid_rank_decisions <- dplyr::bind_rows(grid_out)
grid_rank_decisions <- grid_rank_decisions[
  order(grid_rank_decisions$window, grid_rank_decisions$ecdet, grid_rank_decisions$K),
]

pic_table <- dplyr::bind_rows(pic_out)
pic_table <- pic_table[
  order(pic_table$window, pic_table$ecdet, pic_table$K, pic_table$r),
]

# Best PIC/BIC rank per (window, ecdet, K)
pic_best <- pic_table |>
  dplyr::group_by(window, ecdet, K) |>
  dplyr::summarise(
    r_PIC = r[which.min(PIC)],
    PIC_min = min(PIC),
    r_BIC = r[which.min(BIC)],
    BIC_min = min(BIC),
    .groups = "drop"
  ) |>
  dplyr::arrange(window, ecdet, K)

# Export CSVs
utils::write.csv(
  grid_rank_decisions,
  file.path(grid_csv, "grid_rank_decisions.csv"),
  row.names = FALSE
)

utils::write.csv(
  pic_table,
  file.path(grid_csv, "grid_pic_table.csv"),
  row.names = FALSE
)

utils::write.csv(
  pic_best,
  file.path(grid_csv, "grid_pic_best.csv"),
  row.names = FALSE
)


# ---- Custom window order for printing tables ----
win_levels <- c("full","ford","post")

pic_best <- pic_best |>
  dplyr::mutate(window = factor(window, levels = win_levels)) |>
  dplyr::arrange(window, ecdet, K) |>
  dplyr::mutate(window = as.character(window))

grid_rank_decisions <- grid_rank_decisions |>
  dplyr::mutate(window = factor(window, levels = win_levels)) |>
  dplyr::arrange(window, ecdet, K) |>
  dplyr::mutate(window = as.character(window))


# Print key outputs
print(grid_rank_decisions)
print(pic_best)


|