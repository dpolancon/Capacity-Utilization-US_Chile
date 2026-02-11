############################################################
## ChaoGrid_Engine.R  (Q2 + Q3, robust, self-contained)
##
## GLOBAL QR basis (Gram–Schmidt via QR) built on FULL sample e
## Then reused across full/ford/post => comparable across windows
##
## Locked conventions preserved:
##   - ecdet ∈ {none, const} (trend excluded)
##   - K = p+1 in ca.jo
##   - Q2 uses up to degree 2; Q3 up to degree 3
############################################################

suppressPackageStartupMessages({
  pkgs <- c("here","readxl","dplyr","urca","vars","ggplot2","readr","knitr","kableExtra")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

# ---- helpers ----
codes_path   <- here::here("codes")
helpers_path <- file.path(codes_path, "0_functions.R")
source(helpers_path)

# ---- penalties (locked usage) ----
PIC_penalty <- function(T, k) log(T) * k / T
BIC_penalty <- function(T, k) log(T) * k

# ---- param count proxy (centralized) ----
k_params_proxy <- function(m, p, r) {
  m^2 * p + r * (2*m - r)
}

# ---- user knobs ----
P_MAX <- 7
ECDET_ORDER   <- c("none","const")   # trend excluded
BASIS_ORDER   <- c("Q2","Q3")
WINDOW_ORDER  <- c("full","ford","post")

# ---- inference knobs ----
TOP_N <- 3L
BOOT_B <- 100L
BOOT_BLOCKLEN <- NULL
DO_THETA_SECOND <- TRUE

# ---- paths + logging ----
ROOT_OUT <- here::here("output/ChaoGrid")
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  tex  = file.path(ROOT_OUT, "tex"),
  figs = file.path(ROOT_OUT, "figs"),
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

# ============================================================
# 1) Data ingest + GLOBAL QR basis builder
# ============================================================
build_window_df <- function(ddbb_us, ...) {
  df0 <- dplyr::transmute(
    ddbb_us,
    year  = .data$year,
    log_y = log(.data$Yrgdp),
    log_k = log(.data$KGCRcorp),
    e     = .data$e
  ) |>
    dplyr::arrange(.data$year) |>
    dplyr::filter(!is.na(.data$log_y), !is.na(.data$log_k), !is.na(.data$e))
  
  if (rlang::dots_n(...) > 0) {
    df0 <- dplyr::filter(df0, ...)
  }
  df0
}

data_path <- here::here("data/processed/ddbb_cu_US_kgr.xlsx")
ddbb_us   <- readxl::read_excel(data_path, sheet = "us_data")

windows_raw <- list(
  full = build_window_df(ddbb_us),
  ford = build_window_df(ddbb_us, year <= 1973),
  post = build_window_df(ddbb_us, year >= 1974)
)
stopifnot(all(WINDOW_ORDER %in% names(windows_raw)))

cat("Windows built (raw). N(full)=", nrow(windows_raw$full),
    " N(ford)=", nrow(windows_raw$ford),
    " N(post)=", nrow(windows_raw$post), "\n\n")

# ---- GLOBAL QR basis objects (built ONCE, frozen) ----
basis_qr2 <- theta_basis_qr_build(windows_raw$full$e, degree = 2, center = TRUE)
basis_qr3 <- theta_basis_qr_build(windows_raw$full$e, degree = 3, center = TRUE)

cat("GLOBAL QR basis built on FULL window e.\n")
cat("  degree2: center=", basis_qr2$center, "\n")
cat("  degree3: center=", basis_qr3$center, "\n\n")

augment_with_basis <- function(df0) {
  B3 <- theta_basis_qr_fixed(df0$e, basis_qr3)
  P1 <- B3$q[, 1]
  P2 <- B3$q[, 2]
  P3 <- B3$q[, 3]
  
  df0 |>
    dplyr::mutate(
      P1 = as.numeric(P1),
      P2 = as.numeric(P2),
      P3 = as.numeric(P3),
      logK_P1 = .data$log_k * .data$P1,
      logK_P2 = .data$log_k * .data$P2,
      logK_P3 = .data$log_k * .data$P3
    )
}

windows <- lapply(windows_raw, augment_with_basis)

# ---- system variables ----
SYS_VARS_Q2 <- c("log_y","log_k","logK_P1","logK_P2")
SYS_VARS_Q3 <- c("log_y","log_k","logK_P1","logK_P2","logK_P3")

# ============================================================
# 2) Admissible gates (grid feasibility + numerical safety)
# ============================================================
is_feasible_cell <- function(T_eff, m, p, det) {
  det_pen <- if (det == "none") 0 else 5
  need <- (m * (p + 2)) + det_pen + 10
  isTRUE(is.finite(T_eff) && T_eff > need)
}

is_valid_numeric <- function(x) {
  isTRUE(!is.null(x) && all(is.finite(x)) && !any(is.nan(x)) && !is.complex(x))
}

get_suggested_rank <- function(test_stats, crit_vals) {
  if (is.complex(test_stats) || is.complex(crit_vals)) stop("Complex rank objects (numerical failure)")
  rej <- as.numeric(test_stats) > as.numeric(crit_vals)
  if (!any(rej, na.rm = TRUE)) return(0L)
  as.integer(max(which(rej), na.rm = TRUE))
}

safe_var_diff_resids <- function(dfw_mat, p) {
  dY <- diff(dfw_mat)
  if (nrow(dY) <= (ncol(dY) * (p + 1) + 5)) stop("Too few obs for VAR(diff) at this p")
  fit <- vars::VAR(dY, p = p, type = "none")
  stats::resid(fit)
}

# ============================================================
# 3) Grid definition
# ============================================================
GRID <- expand.grid(
  basis  = BASIS_ORDER,
  window = names(windows),
  ecdet  = ECDET_ORDER,
  p      = 1:P_MAX,
  stringsAsFactors = FALSE
)

GRID <- GRID[order(
  match(GRID$basis,  BASIS_ORDER),
  match(GRID$window, WINDOW_ORDER),
  match(GRID$ecdet,  ECDET_ORDER),
  GRID$p
), , drop = FALSE]

cat("Grid size =", nrow(GRID), "cells\n\n")

# ============================================================
# 4) Engine loop
# ============================================================
pic_rows  <- list()
rank_rows <- list()

n_total <- nrow(GRID)
n_ok    <- 0L
n_skip  <- 0L
n_fail  <- 0L

for (i in seq_len(n_total)) {
  
  g <- GRID[i, , drop = FALSE]
  basis <- as.character(g$basis)
  wname <- as.character(g$window)
  det   <- as.character(g$ecdet)
  p     <- as.integer(g$p)
  
  SYS_VARS <- if (basis == "Q2") SYS_VARS_Q2 else SYS_VARS_Q3
  dfw <- windows[[wname]][, SYS_VARS, drop = FALSE] |> stats::na.omit()
  
  T_eff <- nrow(dfw)
  m     <- ncol(dfw)
  
  cat("Cell ", i, "/", n_total,
      ": basis=", basis,
      " window=", wname,
      " ecdet=", det,
      " p=", p,
      " (T=", T_eff, ", m=", m, ")\n", sep="")
  
  if (!is_feasible_cell(T_eff, m, p, det)) {
    cat("  -> SKIP infeasible (T too small for m,p,det)\n\n")
    n_skip <- n_skip + 1L
    next
  }
  
  gate <- admissible_gate(dfw, p = p, hard_kappa = 1e8, slack = 5)
  if (!isTRUE(gate$ok)) {
    cat("  -> SKIP admissible_gate: ", gate$reason, "\n\n", sep = "")
    n_skip <- n_skip + 1L
    next
  }
  
  cell_ok <- tryCatch({
    
    jo <- urca::ca.jo(
      dfw,
      type  = "trace",
      ecdet = det,
      K     = p + 1
    )
    
    if (!is_valid_numeric(jo@teststat)) stop("Invalid/NA/NaN teststat in ca.jo")
    if (!is_valid_numeric(jo@cval))     stop("Invalid/NA/NaN cval in ca.jo")
    
    tr_stat <- jo@teststat
    tr_cval <- jo@cval
    
    r_trace_10 <- get_suggested_rank(tr_stat, tr_cval[, "10pct"])
    r_trace_05 <- get_suggested_rank(tr_stat, tr_cval[, "5pct"])
    r_trace_01 <- get_suggested_rank(tr_stat, tr_cval[, "1pct"])
    
    rank_rows[[length(rank_rows) + 1]] <- data.frame(
      basis      = basis,
      window     = wname,
      ecdet      = det,
      p          = p,
      T          = T_eff,
      m          = m,
      r_trace_10 = r_trace_10,
      r_trace_05 = r_trace_05,
      r_trace_01 = r_trace_01,
      r_eigen_10 = NA_integer_,
      r_eigen_05 = NA_integer_,
      r_eigen_01 = NA_integer_,
      stringsAsFactors = FALSE
    )
    
    dfw_mat <- as.matrix(dfw)
    
    for (r in 0:(m-1)) {
      
      resids <- if (r == 0) {
        safe_var_diff_resids(dfw_mat, p = p)
      } else {
        vecm <- vars::vec2var(jo, r = r)
        stats::resid(vecm)
      }
      
      if (!is_valid_numeric(resids)) stop("Invalid/complex residuals (numerical failure)")
      
      logdet <- safe_logdet(resids)
      if (!is.finite(logdet) || is.nan(logdet)) stop("Non-finite logdet")
      
      k_par <- k_params_proxy(m = m, p = p, r = r)
      
      PIC <- logdet + PIC_penalty(T_eff, k_par)
      BIC <- logdet + BIC_penalty(T_eff, k_par)
      
      if (!is.finite(PIC) || !is.finite(BIC)) stop("Non-finite PIC/BIC")
      
      pic_rows[[length(pic_rows) + 1]] <- data.frame(
        basis  = basis,
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
    
    TRUE
    
  }, error = function(e) {
    cat("  -> FAIL: ", conditionMessage(e), "\n\n", sep = "")
    FALSE
  })
  
  if (isTRUE(cell_ok)) {
    n_ok <- n_ok + 1L
    cat("  -> OK\n\n")
  } else {
    n_fail <- n_fail + 1L
  }
}

# ============================================================
# 5) Assemble + export base artifacts
# ============================================================
grid_pic_table      <- dplyr::bind_rows(pic_rows)
grid_rank_decisions <- dplyr::bind_rows(rank_rows)

grid_pic_table <- grid_pic_table |>
  dplyr::mutate(
    basis  = factor(basis,  levels = BASIS_ORDER),
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER)
  ) |>
  dplyr::arrange(basis, window, ecdet, p, r) |>
  dplyr::mutate(
    basis  = as.character(basis),
    window = as.character(window),
    ecdet  = as.character(ecdet)
  )

grid_rank_decisions <- grid_rank_decisions |>
  dplyr::mutate(
    basis  = factor(basis,  levels = BASIS_ORDER),
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER)
  ) |>
  dplyr::arrange(basis, window, ecdet, p) |>
  dplyr::mutate(
    basis  = as.character(basis),
    window = as.character(window),
    ecdet  = as.character(ecdet)
  )

for (b in BASIS_ORDER) {
  pic_b <- dplyr::filter(grid_pic_table, basis == b)
  rnk_b <- dplyr::filter(grid_rank_decisions, basis == b)
  
  utils::write.csv(pic_b,
                   file.path(DIRS$csv, paste0("grid_pic_table_", b, ".csv")),
                   row.names = FALSE)
  
  utils::write.csv(rnk_b,
                   file.path(DIRS$csv, paste0("grid_rank_decisions_", b, ".csv")),
                   row.names = FALSE)
}

grid_full <- list(
  grid = GRID,
  basis_order  = BASIS_ORDER,
  window_order = WINDOW_ORDER,
  ecdet_order  = ECDET_ORDER,
  sys_vars_q2  = SYS_VARS_Q2,
  sys_vars_q3  = SYS_VARS_Q3,
  windows_sizes = lapply(windows, nrow),
  pic_table = grid_pic_table,
  rank_decisions = grid_rank_decisions,
  global_basis = list(
    qr2 = basis_qr2,
    qr3 = basis_qr3
  ),
  run_stats = list(
    total = n_total,
    ok    = n_ok,
    skipped_infeasible = n_skip,
    failed = n_fail
  ),
  notes = list(
    basis = "GLOBAL QR orthogonalization of raw powers e^1..e^d (centered), built on FULL window e and reused across windows",
    trend = "Excluded by design",
    boundary_rule = "Boundary-seeking PIC minima treated as overparameterization signal"
  )
)

saveRDS(grid_full, file.path(DIRS$rds, "grid_full.rds"))

cat("=== Engine completed (base grid) ===\n")
cat("Cells total:", n_total, "\n")
cat("Cells ok   :", n_ok, "\n")
cat("Cells skip :", n_skip, " (infeasible/admissible)\n")
cat("Cells fail :", n_fail, " (errors)\n")
cat("PIC rows   :", nrow(grid_pic_table), "\n")
cat("Rank rows  :", nrow(grid_rank_decisions), "\n")
cat("Exports written to:", ROOT_OUT, "\n\n")

# ============================================================
# 6) S6 theta_inference exports (final + top-N PIC per basis/window)
# ============================================================
inference_log <- file.path(DIRS$logs, "inference_log.txt")
cat("\n=== S6 theta_inference start ===\n")
cat("Inference log:", inference_log, "\n")

sink(inference_log, append = FALSE, split = TRUE)

cat("=== theta_inference log ===\n")
cat("TOP_N:", TOP_N, " BOOT_B:", BOOT_B, " DO_THETA_SECOND:", DO_THETA_SECOND, "\n\n")

select_specs <- function(pic_table, basis, window, top_n = 3) {
  pt <- pic_table |>
    dplyr::filter(.data$basis == basis, .data$window == window) |>
    dplyr::arrange(.data$PIC, .data$BIC, .data$p, .data$ecdet, .data$r)
  list(
    final = pt |> dplyr::slice_head(n = 1),
    topN  = pt |> dplyr::slice_head(n = top_n)
  )
}

# Robust extractor:
# - ensure dfw has colnames so jo@V rownames can be mapped
# - normalize on log_y coefficient
extract_theta_beta_from_dfw <- function(dfw, ecdet, p, degree) {
  dfw <- as.matrix(dfw)
  if (is.null(colnames(dfw))) stop("dfw has no colnames; cannot map beta terms")
  
  jo <- urca::ca.jo(dfw, type = "trace", ecdet = ecdet, K = p + 1)
  
  V <- jo@V
  if (is.null(dim(V))) stop("ca.jo@V not matrix; cannot extract beta")
  if (is.null(rownames(V))) stop("ca.jo@V has no rownames; cannot map variables")
  
  bvec <- V[, 1]
  names(bvec) <- rownames(V)
  
  if (!("log_y" %in% names(bvec))) {
    stop("log_y not found in beta vector names. Found: ",
         paste(names(bvec), collapse = ", "))
  }
  
  bvec <- bvec / as.numeric(bvec["log_y"])
  
  need <- c("log_k", paste0("logK_P", 1:degree))
  if (!all(need %in% names(bvec))) {
    stop("Missing theta terms in beta vector: ",
         paste(setdiff(need, names(bvec)), collapse = ", "))
  }
  
  b0 <- -as.numeric(bvec["log_k"])
  cvec <- -as.numeric(bvec[paste0("logK_P", 1:degree)])
  
  c(b0, cvec)
}

run_theta_inference_one <- function(spec_row) {
  basis  <- as.character(spec_row$basis)
  window <- as.character(spec_row$window)
  ecdet  <- as.character(spec_row$ecdet)
  p      <- as.integer(spec_row$p)
  r      <- as.integer(spec_row$r)
  
  degree <- if (basis == "Q2") 2L else 3L
  basis_obj <- if (degree == 2L) basis_qr2 else basis_qr3
  
  SYS_VARS <- if (basis == "Q2") SYS_VARS_Q2 else SYS_VARS_Q3
  dfw <- windows[[window]][, SYS_VARS, drop = FALSE] |> stats::na.omit()
  dfw_mat <- as.matrix(dfw)
  
  cat("Spec:", basis, window, ecdet, "p=", p, "r=", r, "degree=", degree, "\n")
  
  beta_hat <- extract_theta_beta_from_dfw(dfw_mat, ecdet, p, degree)
  
  # Default inference: moving-block bootstrap on beta, then evaluate theta curve
  T_eff <- nrow(dfw_mat)
  L <- if (is.null(BOOT_BLOCKLEN)) max(5L, floor(T_eff^(1/3))) else as.integer(BOOT_BLOCKLEN)
  
  # draw betas
  betas <- matrix(NA_real_, nrow = BOOT_B, ncol = length(beta_hat))
  kept <- 0L; failed <- 0L
  
  for (b in seq_len(BOOT_B)) {
    idx <- mbb_indices(T_eff, L)
    dfb <- dfw_mat[idx, , drop = FALSE]
    tryb <- try({
      betas[b, ] <- extract_theta_beta_from_dfw(dfb, ecdet, p, degree)
      kept <<- kept + 1L
    }, silent = TRUE)
    if (inherits(tryb, "try-error")) failed <- failed + 1L
  }
  
  e_grid <- seq(min(windows_raw$full$e, na.rm=TRUE),
                max(windows_raw$full$e, na.rm=TRUE), length.out = 101)
  
  est0 <- theta_eval_qr(e_grid, beta_hat, basis_obj)
  
  # percentile bands
  qlo <- function(x) stats::quantile(x, probs = 0.025, na.rm = TRUE, names = FALSE)
  qhi <- function(x) stats::quantile(x, probs = 0.975, na.rm = TRUE, names = FALSE)
  
  th_draws  <- matrix(NA_real_, nrow = length(e_grid), ncol = BOOT_B)
  thp_draws <- matrix(NA_real_, nrow = length(e_grid), ncol = BOOT_B)
  thpp_draws<- matrix(NA_real_, nrow = length(e_grid), ncol = BOOT_B)
  
  for (b in seq_len(BOOT_B)) {
    if (any(!is.finite(betas[b, ]))) next
    estb <- theta_eval_qr(e_grid, betas[b, ], basis_obj)
    th_draws[, b]  <- estb$theta
    thp_draws[, b] <- estb$theta_prime
    thpp_draws[, b]<- estb$theta_second
  }
  
  curve <- data.frame(
    e = e_grid,
    theta_hat = est0$theta,
    theta_lo  = apply(th_draws, 1, qlo),
    theta_hi  = apply(th_draws, 1, qhi),
    theta_prime_hat = est0$theta_prime,
    theta_prime_lo  = apply(thp_draws, 1, qlo),
    theta_prime_hi  = apply(thp_draws, 1, qhi),
    stringsAsFactors = FALSE
  )
  
  if (isTRUE(DO_THETA_SECOND)) {
    curve$theta_second_hat <- est0$theta_second
    curve$theta_second_lo  <- apply(thpp_draws, 1, qlo)
    curve$theta_second_hi  <- apply(thpp_draws, 1, qhi)
  }
  
  # coef table (bootstrap SD + percentile on beta)
  coef_tbl <- data.frame(
    term = c("b0", paste0("c", seq_len(degree))),
    estimate = as.numeric(beta_hat),
    se_boot  = apply(betas, 2, stats::sd, na.rm = TRUE),
    lo_boot  = apply(betas, 2, qlo),
    hi_boot  = apply(betas, 2, qhi),
    stringsAsFactors = FALSE
  )
  
  # mapping to raw polynomial a0..ad
  cvec <- as.numeric(beta_hat[-1])
  mp <- theta_coefmap_qr(beta_hat[1], cvec, basis_obj)
  a_raw <- mp$a
  
  poly_tbl <- data.frame(
    term = names(a_raw),
    estimate = as.numeric(a_raw),
    stringsAsFactors = FALSE
  )
  
  coefmap_out <- data.frame(
    group = c(rep("orthogonal_coeffs", nrow(coef_tbl)), rep("raw_poly_coeffs", nrow(poly_tbl))),
    term  = c(as.character(coef_tbl$term), as.character(poly_tbl$term)),
    estimate = c(as.numeric(coef_tbl$estimate), as.numeric(poly_tbl$estimate)),
    se = c(as.numeric(coef_tbl$se_boot), rep(NA_real_, nrow(poly_tbl))),
    lo = c(as.numeric(coef_tbl$lo_boot), rep(NA_real_, nrow(poly_tbl))),
    hi = c(as.numeric(coef_tbl$hi_boot), rep(NA_real_, nrow(poly_tbl))),
    method = "bootstrap_mbb_ca_jo_qr",
    stringsAsFactors = FALSE
  )
  
  stem <- paste0("S6_theta_", basis, "_", window, "_", ecdet, "_p", p, "_r", r)
  
  curve_path <- file.path(DIRS$csv, paste0(stem, "_curve.csv"))
  coef_path  <- file.path(DIRS$csv, paste0(stem, "_coefmap.csv"))
  tex_path   <- file.path(DIRS$tex, paste0(stem, "_coefmap.tex"))
  fig_path_noext <- file.path(DIRS$figs, paste0(stem, "_curve"))
  
  readr::write_csv(curve, curve_path)
  readr::write_csv(coefmap_out, coef_path)
  
  save_table_tex_csv(
    data = coefmap_out,
    tex_path = tex_path,
    csv_path = NULL,
    caption = paste0("S6: Theta coefficient map (", basis, ", ", window, ", ", ecdet, ", p=", p, ", r=", r, ")"),
    footnote = paste0("Method: bootstrap MBB on ca.jo beta; GLOBAL QR basis built on FULL window e; block_len=", L),
    escape = TRUE,
    overwrite = TRUE
  )
  
  # plot theta & theta'
  curve_plot <- curve
  curve_plot$series <- "theta"
  curve_plot$hat <- curve_plot$theta_hat
  curve_plot$lo  <- curve_plot$theta_lo
  curve_plot$hi  <- curve_plot$theta_hi
  
  curve_plot2 <- data.frame(
    e = curve$e,
    series = "theta_prime",
    hat = curve$theta_prime_hat,
    lo = curve$theta_prime_lo,
    hi = curve$theta_prime_hi
  )
  
  plot_df <- rbind(
    curve_plot[, c("e","series","hat","lo","hi")],
    curve_plot2
  )
  
  p1 <- ggplot2::ggplot(plot_df, ggplot2::aes(x = e, y = hat)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = lo, ymax = hi), alpha = 0.2) +
    ggplot2::geom_line() +
    ggplot2::facet_wrap(~ series, ncol = 1, scales = "free_y") +
    ggplot2::labs(
      title = paste0("S6 Theta inference (QR): ", basis, " | ", window, " | ", ecdet, " | p=", p, " r=", r),
      x = "e",
      y = "Estimate (95% band)"
    ) +
    ggplot2::theme_minimal(base_size = 12)
  
  ggplot2::ggsave(paste0(fig_path_noext, ".pdf"), plot = p1, width = 9, height = 7.2)
  
  cat("  bootstrap kept=", kept, " failed=", failed, "\n")
  cat("  wrote:", basename(curve_path), "\n")
  cat("         ", basename(coef_path), "\n")
  cat("         ", basename(tex_path), "\n")
  cat("         ", basename(paste0(fig_path_noext, ".pdf")), "\n\n")
  
  invisible(TRUE)
}

for (b in BASIS_ORDER) {
  for (w in WINDOW_ORDER) {
    sel <- select_specs(grid_pic_table, basis = b, window = w, top_n = TOP_N)
    specs <- dplyr::bind_rows(sel$final, sel$topN) |> dplyr::distinct()
    
    if (nrow(specs) == 0) next
    
    cat("== Inference batch:", b, w, "n_specs=", nrow(specs), "\n")
    for (k in seq_len(nrow(specs))) {
      sr <- specs[k, , drop = FALSE]
      ok <- try(run_theta_inference_one(sr), silent = TRUE)
      if (inherits(ok, "try-error")) {
        cat("  -> inference FAIL for ", b, " ", w, " spec k=", k, ": ", as.character(ok), "\n\n", sep="")
      }
    }
  }
}

cat("Running theta_unit_tests_qr...\n")
ut <- try(theta_unit_tests_qr(), silent = TRUE)
if (inherits(ut, "try-error")) {
  cat("theta_unit_tests_qr FAILED: ", as.character(ut), "\n")
} else {
  cat("theta_unit_tests_qr PASSED.\n")
}

cat("\n=== S6 theta_inference completed ===\n")
sink()  # inference_log
sink()  # engine_log
