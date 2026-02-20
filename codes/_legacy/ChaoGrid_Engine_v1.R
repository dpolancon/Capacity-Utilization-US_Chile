# ============================================================
# ChaoGrid_Engine.R (vNext, consolidated)
# Q2-stable, bug-fixed, dual outputs (unrestricted lattice + restricted/comparable)
#
# Key fix preserved:
#   - Do NOT rely on urca jo@LL
#   - Compute rank-specific logLik via cajorls residuals (loglik_from_cajorls)
#
# Storytelling design:
#   - Export UNRESTRICTED lattice (p=1..P_MAX_EXPLORATORY, r=0..m-1) with gate/runtime status
#   - Export RESTRICTED/comparable subset (p<=COMMON_P_MAX and computed)
#   - Write legacy filenames for Report back-compat (grid_pic_table_Q2.csv etc.)
#
# IMPORTANT:
#   - Never use isTRUE() inside mutate() for column-wise logicals.
#     Use vector logic: gate_ok & runtime_ok, etc.
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","readxl","dplyr","tidyr","urca","vars")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

source(here::here("codes", "0_functions.R"))

# ============================================================
# S1 Paths + logging
# ============================================================
ROOT_OUT <- here::here("output/ChaoGrid")
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  tex  = file.path(ROOT_OUT, "tex"),
  figs = file.path(ROOT_OUT, "figs"),
  rds  = file.path(ROOT_OUT, "rds"),
  logs = file.path(ROOT_OUT, "logs"),
  meta = file.path(ROOT_OUT, "meta")
)
ensure_dirs(DIRS$csv, DIRS$tex, DIRS$figs, DIRS$rds, DIRS$logs, DIRS$meta)

log_file <- file.path(DIRS$logs, "engine_log.txt")
sink(log_file, split = TRUE)
on.exit(sink(), add = TRUE)

cat("=== ChaoGrid vNext Engine start (Q2) ===\n")
cat("Project root:", here::here(), "\n")
cat("Output root :", ROOT_OUT, "\n\n")

set_seed_deterministic()

# ============================================================
# S2 Data load (preserve source)
# ============================================================
data_path <- here::here("data/processed/ddbb_cu_US_kgr.xlsx")
ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

df0 <- dplyr::transmute(
  ddbb_us,
  year  = .data$year,
  log_y = log(.data$Yrgdp),
  log_k = log(.data$KGCRcorp),
  e     = .data$e
) |>
  dplyr::arrange(.data$year) |>
  dplyr::filter(!is.na(.data$year), !is.na(.data$log_y), !is.na(.data$log_k), !is.na(.data$e))

df_full <- filter_window_years(df0, "full", year_col = "year")
df_ford <- filter_window_years(df0, "fordism", year_col = "year")
df_post <- filter_window_years(df0, "post_fordism", year_col = "year")

windows <- list(full = df_full, fordism = df_ford, post_fordism = df_post)

cat("Windows built.\n")
cat("N(full)=", nrow(df_full), " N(fordism)=", nrow(df_ford), " N(post_fordism)=", nrow(df_post), "\n\n")

# ============================================================
# S3 Build invariant Q2 basis (global scaling on FULL)
# ============================================================
basis <- build_q2_basis(df_full, e_col = "e", degree = 2)

if (requireNamespace("jsonlite", quietly = TRUE)) {
  jsonlite::write_json(
    list(
      e_col = basis$e_col,
      mean_full = basis$mean_full,
      sd_full = basis$sd_full,
      coef_map_raw = basis$coef_map_raw
    ),
    path = file.path(DIRS$meta, "S0_basis_Q2_meta.json"),
    pretty = TRUE, auto_unbox = TRUE
  )
} else {
  utils::write.csv(
    data.frame(e_col = basis$e_col, mean_full = basis$mean_full, sd_full = basis$sd_full),
    file.path(DIRS$meta, "S0_basis_Q2_meta.csv"),
    row.names = FALSE
  )
}

windows_basis <- lapply(windows, apply_q2_basis, basis = basis)
sys_list <- lapply(windows_basis, build_system_Q2, y_col = "log_y", k_col = "log_k")

m_vec <- vapply(sys_list, function(s) ncol(s$Y), integer(1))
if (length(unique(m_vec)) != 1) stop("System dimension differs across windows; check missingness.", call. = FALSE)
m_sys <- unique(m_vec)

cat("System dimension m = ", m_sys, " (Q2)\n\n")

# ============================================================
# S4 Feasibility + COMMON_P_MAX (comparable restriction)
#   Gate = feasible_for_ca_jo(T,m,p,ecdet)
# ============================================================
P_MIN <- 1L
P_MAX_EXPLORATORY <- 7L   # storytelling range for UNRESTRICTED lattice

feasible_rows <- list()
for (w in names(sys_list)) {
  T_w <- nrow(sys_list[[w]]$Y)
  for (ec in ECDET_LOCKED) {
    feas <- integer(0)
    for (p in P_MIN:P_MAX_EXPLORATORY) {
      gate <- feasible_for_ca_jo(T = T_w, m = m_sys, p = p, ecdet = ec)
      if (isTRUE(gate$ok)) feas <- c(feas, p)
    }
    feasible_rows[[length(feasible_rows) + 1]] <- data.frame(
      window = w, ecdet = ec, T = T_w, m = m_sys,
      p_max_feasible = if (length(feas) == 0) NA_integer_ else max(feas)
    )
  }
}
feasible_df <- dplyr::bind_rows(feasible_rows)
utils::write.csv(feasible_df, file.path(DIRS$csv, "S1_feasible_pmax_by_window_ecdet_Q2.csv"), row.names = FALSE)

COMMON_P_MAX <- min(feasible_df$p_max_feasible, na.rm = TRUE)
if (!is.finite(COMMON_P_MAX) || COMMON_P_MAX < P_MIN) stop("No feasible COMMON_P_MAX found.", call. = FALSE)

writeLines(
  c(
    "ChaoGrid vNext — COMMON_P_MAX selection (Q2)",
    paste0("COMMON_P_MAX = ", COMMON_P_MAX),
    "Computed as min feasible p_max across windows × ecdet.",
    paste0("Windows: ", paste(names(WINDOWS_LOCKED), collapse = ", ")),
    paste0("ecdet: ", paste(ECDET_LOCKED, collapse = ", "))
  ),
  con = file.path(DIRS$meta, "S1_COMMON_P_MAX_note.txt")
)

cat("COMMON_P_MAX =", COMMON_P_MAX, "\n\n")

# ============================================================
# S5 Dual-output grid builder
#   - UNRESTRICTED: p=1..P_MAX_EXPLORATORY, r=0..m-1
#   - RESTRICTED:   p<=COMMON_P_MAX AND computed
# ============================================================

build_intended_lattice <- function(sys_list, p_min, p_max, ecdet_set) {
  out <- list()
  for (w in names(sys_list)) {
    Y <- sys_list[[w]]$Y
    T_w <- nrow(Y)
    m_w <- ncol(Y)
    r_range <- 0:(m_w - 1)
    for (ec in ecdet_set) {
      out[[length(out) + 1]] <- tidyr::expand_grid(
        window = w,
        ecdet  = ec,
        p      = p_min:p_max,
        r      = r_range
      ) |>
        dplyr::mutate(T = T_w, m = m_w, K = p + 1L)
    }
  }
  dplyr::bind_rows(out)
}

run_grid_Q2_unrestricted <- function(sys_list, p_min, p_max, ecdet_set, common_p_max,
                                     grid_label = "unrestricted") {
  
  lattice <- build_intended_lattice(sys_list, p_min, p_max, ecdet_set) |>
    dplyr::mutate(
      grid = grid_label,
      comparable_p = (p <= common_p_max)
    )
  
  # Compute per (w, ec, p) once
  keys <- lattice |>
    dplyr::distinct(window, ecdet, p, T, m, K, comparable_p)
  
  cell_rows <- vector("list", nrow(keys))
  rank_rows <- list()
  rank_stats_rows <- list()
  
  for (i in seq_len(nrow(keys))) {
    w  <- keys$window[i]
    ec <- keys$ecdet[i]
    p  <- keys$p[i]
    T_w <- keys$T[i]
    m_w <- keys$m[i]
    K   <- keys$K[i]
    
    gate <- feasible_for_ca_jo(T = T_w, m = m_w, p = p, ecdet = ec)
    
    cs <- data.frame(
      window = w, ecdet = ec, p = p, T = T_w, m = m_w,
      gate_ok = isTRUE(gate$ok),
      gate_T_eff = gate$T_eff,
      gate_min_eff = gate$min_eff,
      runtime_ok = FALSE,
      runtime_reason = NA_character_,
      reject_sequence_valid = NA,
      r_trace_10pct = NA_integer_, r_trace_5pct = NA_integer_, r_trace_1pct = NA_integer_,
      r_eigen_10pct = NA_integer_, r_eigen_5pct = NA_integer_, r_eigen_1pct = NA_integer_,
      stringsAsFactors = FALSE
    )
    
    if (!isTRUE(gate$ok)) {
      cs$runtime_reason <- paste0("gate_fail: T_eff=", gate$T_eff, " <= min_eff=", gate$min_eff)
      cell_rows[[i]] <- cs
      next
    }
    
    jo_pair <- tryCatch(
      run_ca_jo_pair(sys_list[[w]]$Y, ecdet = ec, K = K, spec = "transitory"),
      error = function(e) e
    )
    
    if (inherits(jo_pair, "error")) {
      cs$runtime_reason <- paste0("runtime_fail: ", conditionMessage(jo_pair))
      cell_rows[[i]] <- cs
      next
    }
    
    jo_tr <- jo_pair$trace
    jo_ei <- jo_pair$eigen
    
    rd <- extract_rank_decisions_pair(jo_tr, jo_ei, alpha_levels = ALPHA_LEVELS)
    
    # Full rank test stats table (storytelling)
    r0 <- 0:(m_w - 1)
    rank_stats_rows[[length(rank_stats_rows) + 1]] <- data.frame(
      grid = grid_label, window = w, ecdet = ec, p = p, r0 = r0,
      trace_stat = rd$trace_stats,
      eigen_stat = rd$eigen_stats,
      trace_cv_10 = rd$trace_cv[, 1],
      trace_cv_5  = rd$trace_cv[, 2],
      trace_cv_1  = rd$trace_cv[, 3],
      eigen_cv_10 = rd$eigen_cv[, 1],
      eigen_cv_5  = rd$eigen_cv[, 2],
      eigen_cv_1  = rd$eigen_cv[, 3]
    )
    
    # Rank-specific logLik via cajorls residuals
    ll_by_r <- rep(NA_real_, m_w)
    for (r in 0:(m_w - 1)) {
      ll_by_r[r + 1] <- loglik_from_cajorls(jo_tr, r = r, m_expected = m_w)
    }
    
    if (all(!is.finite(ll_by_r))) {
      cs$runtime_reason <- "runtime_fail: cajorls logLik all non-finite"
      cell_rows[[i]] <- cs
      next
    }
    
    # Mark success
    cs$runtime_ok <- TRUE
    cs$reject_sequence_valid <- rd$reject_sequence_valid
    cs$r_trace_10pct <- rd$ranks$r_trace_10pct
    cs$r_trace_5pct  <- rd$ranks$r_trace_5pct
    cs$r_trace_1pct  <- rd$ranks$r_trace_1pct
    cs$r_eigen_10pct <- rd$ranks$r_eigen_10pct
    cs$r_eigen_5pct  <- rd$ranks$r_eigen_5pct
    cs$r_eigen_1pct  <- rd$ranks$r_eigen_1pct
    cell_rows[[i]] <- cs
    
    rr <- data.frame(
      window = w, ecdet = ec, p = p, r = 0:(m_w - 1),
      logLik = ll_by_r,
      stringsAsFactors = FALSE
    ) |>
      dplyr::mutate(
        k_total = vapply(r, function(rrr)
          count_params_vecm(m = m_w, p = p, r = rrr, ecdet = ec)$k_total, numeric(1)),
        PIC = mapply(function(ll, kk) if (is.finite(ll)) calc_ic(ll, T_w, kk)$PIC else NA_real_, logLik, k_total),
        BIC = mapply(function(ll, kk) if (is.finite(ll)) calc_ic(ll, T_w, kk)$BIC else NA_real_, logLik, k_total)
      )
    
    rank_rows[[length(rank_rows) + 1]] <- rr
  }
  
  cell_tbl   <- dplyr::bind_rows(cell_rows)
  rr_tbl     <- if (length(rank_rows) > 0) dplyr::bind_rows(rank_rows) else data.frame()
  rstats_tbl <- if (length(rank_stats_rows) > 0) dplyr::bind_rows(rank_stats_rows) else data.frame()
  
  out <- lattice |>
    dplyr::left_join(cell_tbl, by = c("window","ecdet","p","T","m")) |>
    dplyr::left_join(rr_tbl,   by = c("window","ecdet","p","r")) |>
    dplyr::mutate(
      # CRITICAL FIX: vector logic, not isTRUE()
      status = dplyr::case_when(
        !gate_ok ~ "gate_fail",
        gate_ok & !runtime_ok ~ "runtime_fail",
        gate_ok & runtime_ok & is.finite(PIC) ~ "computed",
        TRUE ~ "unknown"
      )
    )
  
  list(unrestricted = out, cell_status = cell_tbl, rank_stats = rstats_tbl)
}

dual <- run_grid_Q2_unrestricted(
  sys_list = sys_list,
  p_min = P_MIN,
  p_max = P_MAX_EXPLORATORY,
  ecdet_set = ECDET_LOCKED,
  common_p_max = COMMON_P_MAX,
  grid_label = "unrestricted"
)

grid_unrestricted <- dual$unrestricted
cell_status <- dual$cell_status
rank_stats_unrestricted <- dual$rank_stats

# Restricted/comparable subset (for identification + cross-window comparability)
grid_restricted <- grid_unrestricted |>
  dplyr::filter(comparable_p, status == "computed") |>
  dplyr::mutate(grid = "comparable")

# Export dual outputs
utils::write.csv(grid_unrestricted, file.path(DIRS$csv, "grid_pic_table_Q2_unrestricted.csv"), row.names = FALSE)
utils::write.csv(grid_restricted,   file.path(DIRS$csv, "grid_pic_table_Q2_restricted.csv"), row.names = FALSE)
utils::write.csv(cell_status,       file.path(DIRS$csv, "grid_cell_status_Q2_unrestricted.csv"), row.names = FALSE)
utils::write.csv(rank_stats_unrestricted, file.path(DIRS$csv, "grid_rank_stats_Q2_unrestricted.csv"), row.names = FALSE)

cat("Exported unrestricted + restricted grids.\n\n")

# ============================================================
# S5b Legacy exports for Report back-compat
# ============================================================

# legacy skips (comparable range): one row per (window,ecdet,p) with failure
grid_skips_Q2 <- grid_unrestricted |>
  dplyr::filter(comparable_p) |>
  dplyr::distinct(window, ecdet, p, m, T, gate_ok, runtime_ok, gate_T_eff, gate_min_eff, runtime_reason, status) |>
  dplyr::filter(status %in% c("gate_fail","runtime_fail")) |>
  dplyr::mutate(
    grid = "comparable",
    reason = dplyr::if_else(is.na(runtime_reason), status, runtime_reason)
  ) |>
  dplyr::select(grid, window, ecdet, p, m, T, reason)

grid_rank_stats_Q2 <- rank_stats_unrestricted |>
  dplyr::filter(p <= COMMON_P_MAX) |>
  dplyr::mutate(grid = "comparable")

# legacy: the Report currently expects these exact filenames
utils::write.csv(grid_restricted,    file.path(DIRS$csv, "grid_pic_table_Q2.csv"), row.names = FALSE)
utils::write.csv(grid_rank_stats_Q2, file.path(DIRS$csv, "grid_rank_stats_Q2.csv"), row.names = FALSE)
utils::write.csv(grid_skips_Q2,      file.path(DIRS$csv, "grid_skips_Q2.csv"), row.names = FALSE)

cat("Legacy (Report) exports written: grid_pic_table_Q2.csv, grid_rank_stats_Q2.csv, grid_skips_Q2.csv\n\n")

# ============================================================
# S6 Decision rule (Q2) using restricted/comparable grid
#   (Back to your existing pipeline functions)
# ============================================================

dfG <- grid_restricted
if (nrow(dfG) == 0) {
  cat("ERROR: No feasible/computed cells in restricted comparable grid.\n")
  cat("Check COMMON_P_MAX, gate rules, and runtime failures in grid_cell_status_Q2_unrestricted.csv\n")
  stop("No feasible/computed cells in restricted comparable grid.", call. = FALSE)
}

# Choose winners within restricted grid
winners_ec <- list()
for (w in unique(dfG$window)) {
  for (ec in ECDET_LOCKED) {
    sub <- dfG[dfG$window == w & dfG$ecdet == ec & dfG$grid == "comparable", , drop = FALSE]
    win <- choose_winner_Q2(
      sub,
      p_max = COMMON_P_MAX,
      r_max = m_sys - 1,
      epsilon = DECISION_DEFAULTS$epsilon,
      delta   = DECISION_DEFAULTS$delta
    )
    if (!is.null(win)) winners_ec[[length(winners_ec) + 1]] <- win
  }
}
w_ec <- do.call(rbind, winners_ec)

final_specs <- list()
for (w in unique(dfG$window)) {
  wn <- w_ec[w_ec$window == w & w_ec$ecdet == "none", , drop = FALSE]
  wc <- w_ec[w_ec$window == w & w_ec$ecdet == "const", , drop = FALSE]
  wn <- if (nrow(wn) == 0) NULL else wn[1, , drop = FALSE]
  wc <- if (nrow(wc) == 0) NULL else wc[1, , drop = FALSE]
  sel <- det_preference(wn, wc, tau_det = DECISION_DEFAULTS$tau_det)
  if (!is.null(sel)) final_specs[[length(final_specs) + 1]] <- sel
}

CANON_COLS <- names(w_ec)
final_specs <- lapply(final_specs, function(x) {
  if (is.null(x)) return(NULL)
  x <- as.data.frame(x)
  miss <- setdiff(CANON_COLS, names(x))
  if (length(miss) > 0) x[miss] <- NA
  x[, CANON_COLS, drop = FALSE]
})

final_specs <- Filter(Negate(is.null), final_specs)
final_df <- do.call(rbind, final_specs)

utils::write.csv(final_df, file.path(DIRS$csv, "S4_final_recommendations_Q2.csv"), row.names = FALSE)

writeLines(
  c(
    "ChaoGrid vNext — Q2 Decision Rule",
    "",
    "Step A: per window×ecdet, find global min PIC (p*,r*).",
    "Step B: boundary discipline rejects upper-boundary minima (p==p_max or r==r_max).",
    "        choose best interior within epsilon of global min; else best interior w/ flag.",
    "Step C: tie-breakers within delta: lower p, then lower r.",
    "Step D: prefer ecdet=none unless const improves PIC by > tau.",
    "",
    paste0("epsilon=", DECISION_DEFAULTS$epsilon, ", delta=", DECISION_DEFAULTS$delta, ", tau=", DECISION_DEFAULTS$tau_det),
    paste0("COMMON_P_MAX=", COMMON_P_MAX),
    "Trend deterministics excluded (LOCKED)."
  ),
  con = file.path(DIRS$meta, "decision_log.txt")
)

# ============================================================
# S7 Rank decision export (from restricted grid)
# ============================================================
rank_decisions <- dfG |>
  dplyr::distinct(
    window, ecdet, p, m, T,
    r_trace_10pct, r_trace_5pct, r_trace_1pct,
    r_eigen_10pct, r_eigen_5pct, r_eigen_1pct,
    reject_sequence_valid
  )

# Attach selected r=... test stats (from legacy rank_stats table)
rs <- grid_rank_stats_Q2

rank_decisions <- rank_decisions |>
  dplyr::left_join(
    rs |>
      dplyr::rename(r_sel = r0) |>
      dplyr::select(window, ecdet, p, r_sel, trace_stat, trace_cv_5, eigen_stat, eigen_cv_5),
    by = c("window","ecdet","p", "r_trace_5pct" = "r_sel")
  ) |>
  dplyr::rename(
    trace_stat_r_5pct = trace_stat,
    trace_cv_r_5pct   = trace_cv_5,
    eigen_stat_r_5pct = eigen_stat,
    eigen_cv_r_5pct   = eigen_cv_5
  )

utils::write.csv(rank_decisions, file.path(DIRS$csv, "grid_rank_decisions_Q2.csv"), row.names = FALSE)

# ============================================================
# S8 Inference exports (Q2) — based on final_df choices
# ============================================================
e_grid <- as.numeric(stats::quantile(df_full$e, probs = seq(0.05, 0.95, by = 0.05), na.rm = TRUE))

infer_one <- function(window, ecdet, p, r, tag) {
  Y <- sys_list[[window]]$Y
  jo_tr <- urca::ca.jo(Y, type = "trace", ecdet = ecdet, K = p + 1, spec = "transitory")
  
  ba <- extract_beta_alpha(jo_tr, r = r, var_names = sys_list[[window]]$var_names)
  beta_n <- normalize_beta(ba$beta, on_var = "log_y", col = "first_nonzero")
  th <- theta_curve_from_beta(beta_n, basis, grid_e = e_grid)
  
  stem <- paste0("S6_theta_Q2_", window, "_", ecdet, "_p", p, "_r", r, "_", tag)
  utils::write.csv(th$curve,   file.path(DIRS$csv, paste0(stem, "_curve.csv")), row.names = FALSE)
  utils::write.csv(th$coefmap, file.path(DIRS$csv, paste0(stem, "_coefmap.csv")), row.names = FALSE)
  utils::write.csv(
    data.frame(
      window = window, ecdet = ecdet, p = p, r = r,
      normalize_on = "log_y",
      basis_mean_full = basis$mean_full,
      basis_sd_full   = basis$sd_full,
      vars = paste(sys_list[[window]]$var_names, collapse = ";")
    ),
    file.path(DIRS$csv, paste0(stem, "_meta.csv")),
    row.names = FALSE
  )
}

# Final + two PIC-best alternatives within restricted grid (if available)
for (w in names(sys_list)) {
  fin <- final_df[final_df$window == w, , drop = FALSE]
  if (nrow(fin) == 0) next
  fin <- fin[1, , drop = FALSE]
  
  sub <- dfG[dfG$window == w & dfG$grid == "comparable", , drop = FALSE]
  sub <- sub[order(sub$PIC), , drop = FALSE]
  alt <- sub[!(sub$ecdet == fin$ecdet & sub$p == fin$p & sub$r == fin$r), , drop = FALSE]
  alt <- alt[1:min(2, nrow(alt)), , drop = FALSE]
  
  infer_one(w, fin$ecdet, fin$p, fin$r, "final")
  if (nrow(alt) >= 1) infer_one(w, alt$ecdet[1], alt$p[1], alt$r[1], "alt1")
  if (nrow(alt) >= 2) infer_one(w, alt$ecdet[2], alt$p[2], alt$r[2], "alt2")
}

# ============================================================
# S9 PIC/BIC recompute audit (restricted grid)
# ============================================================
set.seed(123)
idx <- sample(seq_len(nrow(dfG)), size = min(10, nrow(dfG)))
ok_ic <- vapply(idx, function(i) recompute_ic_check(dfG[i, ]), logical(1))
if (!all(ok_ic)) stop("PIC/BIC recomputation check failed.", call. = FALSE)

# ============================================================
# S10 QA tests
# ============================================================
stopifnot(run_unit_tests())

cat("\n=== Engine completed successfully ===\n")
sink()
