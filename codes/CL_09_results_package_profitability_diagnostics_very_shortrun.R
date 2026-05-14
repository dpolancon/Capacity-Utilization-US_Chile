###############################################################################
# CHILE — Profit swings diagnostic with ECT
# VERY SHORT WINDOW: 1968–1975
#
# Purpose:
# - Identify Chile profit swings in the micro-window covering
#   the critical juncture around the Unidad Popular and the onset
#   of counter-revolution
# - Use a joint diagnostic:
#   (i) smoothed log-differential profitability
#   (ii) profit rate in level
# - Include ECT as a diagnostic layer for external imbalance pressure
# - Produce transparent CSV/RDS outputs and two figures
#
# Output root:
# - output/profitability_chile_diagnostic_short_very_19681975
#
# Directory structure:
# - csv/
# - figures/
# - rds/
###############################################################################

# ── 0. Packages ──────────────────────────────────────────────────────────────
pkgs <- c("dplyr", "readr", "tibble", "zoo", "ggplot2", "janitor")
miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss) > 0) install.packages(miss, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

# ── 1. Paths and controls ────────────────────────────────────────────────────
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

path_d_rds <- file.path(
  proj_root, "output", "profitability_chile", "rds", "d_merged_profitability_chile.rds"
)

path_bundle_rds <- file.path(
  proj_root, "output", "profitability_chile", "rds", "analytical_bundle_chile.rds"
)

out_root <- file.path(
  proj_root, "output", "profitability_chile_diagnostic_short_very_19681975"
)
csv_dir  <- file.path(out_root, "csv")
fig_dir  <- file.path(out_root, "figures")
rds_dir  <- file.path(out_root, "rds")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)

analysis_year_min <- 1968L
analysis_year_max <- 1975L

# Carrier settings
level_var <- "r_diag_t"
log_var   <- "ln_r_diag_t"
ect_var   <- "ect"

# Signal settings
k_smooth     <- 3L
ect_smooth_k <- 3L
local_span   <- 1L

# Lighter pruning for micro-window
min_years_between_tp <- 1L
min_log_move         <- 0.01

# Figure settings
fig_width  <- 12
fig_height <- 7
fig_dpi    <- 320

# ── 2. Helpers ───────────────────────────────────────────────────────────────
sign_eps <- function(x, eps = 1e-10) {
  ifelse(is.na(x) | abs(x) <= eps, 0L, ifelse(x > 0, 1L, -1L))
}

zsafe <- function(x) {
  s <- stats::sd(x, na.rm = TRUE)
  m <- mean(x, na.rm = TRUE)
  if (!is.finite(s) || s <= 0) return(rep(NA_real_, length(x)))
  (x - m) / s
}

load_profitability_panel <- function(path_d_rds, path_bundle_rds) {
  if (file.exists(path_d_rds)) {
    return(readRDS(path_d_rds))
  }
  
  if (file.exists(path_bundle_rds)) {
    b <- readRDS(path_bundle_rds)
    if (!("d" %in% names(b))) {
      stop("Bundle found, but object 'd' is missing.", call. = FALSE)
    }
    return(b$d)
  }
  
  stop(
    "Could not find either d_merged_profitability_chile.rds or analytical_bundle_chile.rds.",
    call. = FALSE
  )
}

locate_local_extremum <- function(year, level, i, type, span = 1L) {
  lo <- max(1L, i - span)
  hi <- min(length(level), i + span)
  win_idx <- lo:hi
  win_val <- level[win_idx]
  
  if (all(is.na(win_val))) {
    return(tibble::tibble(
      idx = i,
      year = year[i],
      value = level[i],
      type = type
    ))
  }
  
  j <- if (type == "peak") {
    win_idx[which.max(win_val)]
  } else {
    win_idx[which.min(win_val)]
  }
  
  tibble::tibble(
    idx = j,
    year = year[j],
    value = level[j],
    type = type
  )
}

compute_signal_table <- function(df, level_var, log_var, k_smooth,
                                 ect_var = "ect", ect_smooth_k = 3L) {
  if (!(level_var %in% names(df))) {
    stop("Missing level_var in input data: ", level_var, call. = FALSE)
  }
  if (!(ect_var %in% names(df))) {
    stop("Missing ect_var in input data: ", ect_var, call. = FALSE)
  }
  
  out <- df |>
    dplyr::arrange(year) |>
    dplyr::transmute(
      year,
      r_level = .data[[level_var]],
      ln_r    = if (log_var %in% names(df)) .data[[log_var]] else log(.data[[level_var]]),
      ect     = .data[[ect_var]]
    ) |>
    dplyr::mutate(
      dlog_r = ln_r - dplyr::lag(ln_r),
      dlog_r_smoothed = zoo::rollmean(dlog_r, k = k_smooth, fill = NA, align = "center"),
      ect_smoothed    = zoo::rollmean(ect, k = ect_smooth_k, fill = NA, align = "center")
    ) |>
    dplyr::mutate(
      dlog_r_z          = zsafe(dlog_r),
      dlog_r_smoothed_z = zsafe(dlog_r_smoothed),
      ect_z             = zsafe(ect),
      ect_smoothed_z    = zsafe(ect_smoothed)
    )
  
  out
}

compress_turning_points <- function(tp) {
  if (nrow(tp) <= 1) return(tp)
  
  keep <- vector("list", 0)
  current <- tp[1, , drop = FALSE]
  
  for (i in 2:nrow(tp)) {
    this <- tp[i, , drop = FALSE]
    
    if (this$type == current$type) {
      if (this$type == "peak"   && this$value > current$value) current <- this
      if (this$type == "trough" && this$value < current$value) current <- this
    } else {
      keep[[length(keep) + 1]] <- current
      current <- this
    }
  }
  
  keep[[length(keep) + 1]] <- current
  dplyr::bind_rows(keep) |>
    dplyr::arrange(idx)
}

find_tp_from_signal <- function(signal_tbl, signal_col, span = 1L, eps = 1e-10, method_name = "signal_rule") {
  year  <- signal_tbl$year
  level <- signal_tbl$r_level
  sig   <- signal_tbl[[signal_col]]
  
  out <- vector("list", 0)
  
  if (length(sig) < 3) {
    return(tibble::tibble(
      method = character(),
      signal_col = character(),
      signal_idx = integer(),
      signal_year = integer(),
      idx = integer(),
      year = integer(),
      value = numeric(),
      type = character(),
      signal_prev = numeric(),
      signal_curr = numeric(),
      signal_strength = numeric()
    ))
  }
  
  for (i in 2:(length(sig) - 1)) {
    if (is.na(sig[i - 1]) || is.na(sig[i])) next
    
    s_prev <- sign_eps(sig[i - 1], eps = eps)
    s_curr <- sign_eps(sig[i], eps = eps)
    
    if (s_prev > 0L && s_curr < 0L) {
      ext <- locate_local_extremum(year, level, i, "peak", span = span)
      out[[length(out) + 1]] <- tibble::tibble(
        method = method_name,
        signal_col = signal_col,
        signal_idx = i,
        signal_year = year[i],
        idx = ext$idx,
        year = ext$year,
        value = ext$value,
        type = ext$type,
        signal_prev = sig[i - 1],
        signal_curr = sig[i],
        signal_strength = abs(sig[i - 1]) + abs(sig[i])
      )
    } else if (s_prev < 0L && s_curr > 0L) {
      ext <- locate_local_extremum(year, level, i, "trough", span = span)
      out[[length(out) + 1]] <- tibble::tibble(
        method = method_name,
        signal_col = signal_col,
        signal_idx = i,
        signal_year = year[i],
        idx = ext$idx,
        year = ext$year,
        value = ext$value,
        type = ext$type,
        signal_prev = sig[i - 1],
        signal_curr = sig[i],
        signal_strength = abs(sig[i - 1]) + abs(sig[i])
      )
    }
  }
  
  if (length(out) == 0) {
    return(tibble::tibble(
      method = character(),
      signal_col = character(),
      signal_idx = integer(),
      signal_year = integer(),
      idx = integer(),
      year = integer(),
      value = numeric(),
      type = character(),
      signal_prev = numeric(),
      signal_curr = numeric(),
      signal_strength = numeric()
    ))
  }
  
  dplyr::bind_rows(out) |>
    dplyr::distinct(idx, .keep_all = TRUE) |>
    dplyr::arrange(idx)
}

find_tp_from_levels <- function(signal_tbl, span = 1L) {
  year  <- signal_tbl$year
  level <- signal_tbl$r_level
  
  out <- vector("list", 0)
  
  if (length(level) < 3) {
    return(tibble::tibble(
      method = character(),
      signal_col = character(),
      signal_idx = integer(),
      signal_year = integer(),
      idx = integer(),
      year = integer(),
      value = numeric(),
      type = character(),
      signal_prev = numeric(),
      signal_curr = numeric(),
      signal_strength = numeric()
    ))
  }
  
  for (i in 2:(length(level) - 1)) {
    if (is.na(level[i - 1]) || is.na(level[i]) || is.na(level[i + 1])) next
    
    if (level[i - 1] < level[i] && level[i] > level[i + 1]) {
      ext <- locate_local_extremum(year, level, i, "peak", span = span)
      out[[length(out) + 1]] <- tibble::tibble(
        method = "level_extrema",
        signal_col = "r_level",
        signal_idx = i,
        signal_year = year[i],
        idx = ext$idx,
        year = ext$year,
        value = ext$value,
        type = ext$type,
        signal_prev = NA_real_,
        signal_curr = NA_real_,
        signal_strength = NA_real_
      )
    } else if (level[i - 1] > level[i] && level[i] < level[i + 1]) {
      ext <- locate_local_extremum(year, level, i, "trough", span = span)
      out[[length(out) + 1]] <- tibble::tibble(
        method = "level_extrema",
        signal_col = "r_level",
        signal_idx = i,
        signal_year = year[i],
        idx = ext$idx,
        year = ext$year,
        value = ext$value,
        type = ext$type,
        signal_prev = NA_real_,
        signal_curr = NA_real_,
        signal_strength = NA_real_
      )
    }
  }
  
  if (length(out) == 0) {
    return(tibble::tibble(
      method = character(),
      signal_col = character(),
      signal_idx = integer(),
      signal_year = integer(),
      idx = integer(),
      year = integer(),
      value = numeric(),
      type = character(),
      signal_prev = numeric(),
      signal_curr = numeric(),
      signal_strength = numeric()
    ))
  }
  
  dplyr::bind_rows(out) |>
    dplyr::distinct(idx, .keep_all = TRUE) |>
    dplyr::arrange(idx)
}

prune_turning_points_joint <- function(tp, signal_tbl, min_years = 1L, min_log_move = 0.01) {
  if (nrow(tp) <= 1) return(tp)
  
  level <- signal_tbl$r_level
  log_level <- log(level)
  out <- tp
  
  repeat {
    if (nrow(out) <= 1) break
    
    dur <- diff(out$year)
    amp_log <- abs(diff(log_level[out$idx]))
    weak <- which(dur < min_years | amp_log < min_log_move)
    
    if (length(weak) == 0) break
    
    k <- weak[1]
    
    if (k == 1) {
      out <- out[-2, , drop = FALSE]
    } else if (k == nrow(out) - 1) {
      out <- out[-k, , drop = FALSE]
    } else {
      left_idx  <- out$idx[k - 1]
      a_idx     <- out$idx[k]
      b_idx     <- out$idx[k + 1]
      right_idx <- out$idx[k + 2]
      
      move_drop_left  <- abs(log_level[b_idx] - log_level[left_idx])
      move_drop_right <- abs(log_level[right_idx] - log_level[a_idx])
      
      if (move_drop_left >= move_drop_right) {
        out <- out[-k, , drop = FALSE]
      } else {
        out <- out[-(k + 1), , drop = FALSE]
      }
    }
    
    out <- compress_turning_points(out)
  }
  
  out
}

make_boundary_only_tp <- function(signal_tbl) {
  level_first <- signal_tbl$r_level[1]
  level_last  <- signal_tbl$r_level[nrow(signal_tbl)]
  
  start_type <- if (level_last >= level_first) "trough" else "peak"
  end_type   <- if (start_type == "trough") "peak" else "trough"
  
  tibble::tibble(
    method = "boundary_only",
    signal_col = NA_character_,
    signal_idx = c(NA_integer_, NA_integer_),
    signal_year = c(NA_integer_, NA_integer_),
    idx = c(1L, nrow(signal_tbl)),
    year = c(signal_tbl$year[1], signal_tbl$year[nrow(signal_tbl)]),
    value = c(signal_tbl$r_level[1], signal_tbl$r_level[nrow(signal_tbl)]),
    type = c(start_type, end_type),
    signal_prev = c(NA_real_, NA_real_),
    signal_curr = c(NA_real_, NA_real_),
    signal_strength = c(NA_real_, NA_real_)
  )
}

add_boundaries_keep_rhs <- function(tp, signal_tbl) {
  if (nrow(tp) == 0) {
    return(make_boundary_only_tp(signal_tbl))
  }
  
  first_type <- if (tp$type[1] == "peak") "trough" else "peak"
  last_type  <- if (tp$type[nrow(tp)] == "peak") "trough" else "peak"
  
  start_row <- tibble::tibble(
    method = "boundary",
    signal_col = NA_character_,
    signal_idx = NA_integer_,
    signal_year = NA_integer_,
    idx = 1L,
    year = signal_tbl$year[1],
    value = signal_tbl$r_level[1],
    type = first_type,
    signal_prev = NA_real_,
    signal_curr = NA_real_,
    signal_strength = NA_real_
  )
  
  end_row <- tibble::tibble(
    method = "boundary",
    signal_col = NA_character_,
    signal_idx = NA_integer_,
    signal_year = NA_integer_,
    idx = nrow(signal_tbl),
    year = signal_tbl$year[nrow(signal_tbl)],
    value = signal_tbl$r_level[nrow(signal_tbl)],
    type = last_type,
    signal_prev = NA_real_,
    signal_curr = NA_real_,
    signal_strength = NA_real_
  )
  
  dplyr::bind_rows(start_row, tp, end_row) |>
    dplyr::arrange(idx) |>
    compress_turning_points()
}

build_swing_table <- function(tp_bounds, signal_tbl) {
  if (nrow(tp_bounds) < 2) return(tibble::tibble())
  
  out <- vector("list", nrow(tp_bounds) - 1)
  
  for (i in seq_len(nrow(tp_bounds) - 1)) {
    idx0 <- tp_bounds$idx[i]
    idx1 <- tp_bounds$idx[i + 1]
    
    y0 <- tp_bounds$year[i]
    y1 <- tp_bounds$year[i + 1]
    
    r0  <- signal_tbl$r_level[idx0]
    r1  <- signal_tbl$r_level[idx1]
    ln0 <- signal_tbl$ln_r[idx0]
    ln1 <- signal_tbl$ln_r[idx1]
    
    ect0 <- signal_tbl$ect[idx0]
    ect1 <- signal_tbl$ect[idx1]
    ect_avg <- mean(signal_tbl$ect[idx0:idx1], na.rm = TRUE)
    ect_sm_avg <- mean(signal_tbl$ect_smoothed[idx0:idx1], na.rm = TRUE)
    
    dur <- y1 - y0
    
    out[[i]] <- tibble::tibble(
      swing_id = i,
      start_year = y0,
      end_year = y1,
      start_type = tp_bounds$type[i],
      end_type   = tp_bounds$type[i + 1],
      direction  = paste0(tp_bounds$type[i], "_to_", tp_bounds$type[i + 1]),
      duration_years = dur,
      start_r = r0,
      end_r   = r1,
      amplitude_pct = 100 * (r1 / r0 - 1),
      amplitude_log = ln1 - ln0,
      pace_pct_per_year = ifelse(dur > 0, 100 * ((r1 / r0)^(1 / dur) - 1), NA_real_),
      pace_log_per_year = ifelse(dur > 0, (ln1 - ln0) / dur, NA_real_),
      ect_start = ect0,
      ect_end   = ect1,
      ect_avg   = ect_avg,
      ect_smoothed_avg = ect_sm_avg,
      boundary_only = all(tp_bounds$method == "boundary_only"),
      rhs_terminal_window = (i == (nrow(tp_bounds) - 1))
    )
  }
  
  dplyr::bind_rows(out)
}

plot_joint_diagnostic <- function(signal_tbl, tp_used, out_png, out_pdf, title_txt = NULL) {
  level <- signal_tbl$r_level
  sig   <- signal_tbl$dlog_r_smoothed
  
  level_center <- mean(level, na.rm = TRUE)
  sig_range <- range(sig, na.rm = TRUE)
  lvl_range <- range(level, na.rm = TRUE)
  
  if (!all(is.finite(sig_range)) || diff(sig_range) == 0) {
    scale_fac <- 1
  } else {
    scale_fac <- 0.85 * diff(lvl_range) / diff(sig_range)
  }
  
  signal_plot <- signal_tbl |>
    dplyr::mutate(
      dlog_plot = level_center + dlog_r_smoothed * scale_fac
    )
  
  tp_plot <- tp_used |>
    dplyr::filter(!method %in% c("boundary", "boundary_only")) |>
    dplyr::transmute(
      year,
      r_level = value,
      type
    )
  
  p <- ggplot(signal_plot, aes(x = year)) +
    geom_hline(yintercept = level_center, linetype = "dotted", linewidth = 0.4) +
    geom_line(aes(y = r_level), linewidth = 1.1) +
    geom_line(aes(y = dlog_plot), linetype = "dashed", linewidth = 0.9) +
    geom_point(
      data = dplyr::filter(tp_plot, type == "peak"),
      aes(y = r_level, shape = type),
      size = 3.2, stroke = 0.8, fill = NA
    ) +
    geom_point(
      data = dplyr::filter(tp_plot, type == "trough"),
      aes(y = r_level, shape = type),
      size = 3.2, stroke = 0.8, fill = NA
    ) +
    scale_shape_manual(values = c(peak = 24, trough = 25)) +
    scale_y_continuous(
      name = "profit rate",
      sec.axis = sec_axis(
        trans = ~ (. - level_center) / scale_fac,
        name = "smoothed Δ log profitability"
      )
    ) +
    labs(
      x = NULL,
      title = title_txt,
      shape = NULL
    ) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
  
  ggsave(out_png, p, width = fig_width, height = fig_height, dpi = fig_dpi)
  ggsave(out_pdf, p, width = fig_width, height = fig_height)
  
  invisible(p)
}

plot_ect_diagnostic <- function(signal_tbl, tp_used, out_png, out_pdf, title_txt = NULL) {
  tp_vlines <- tp_used |>
    dplyr::filter(!method %in% c("boundary", "boundary_only"))
  
  p <- ggplot(signal_tbl, aes(x = year)) +
    geom_hline(yintercept = 0, linetype = "dotted", linewidth = 0.4) +
    geom_line(aes(y = dlog_r_smoothed_z, linetype = "Smoothed Δlog profitability (z)"), linewidth = 1.0) +
    geom_line(aes(y = ect_smoothed_z, linetype = "ECT external imbalance (z)"), linewidth = 1.0) +
    geom_vline(
      data = tp_vlines,
      aes(xintercept = year),
      linewidth = 0.35,
      alpha = 0.45
    ) +
    scale_linetype_manual(values = c(
      "Smoothed Δlog profitability (z)" = "dashed",
      "ECT external imbalance (z)" = "solid"
    )) +
    labs(
      x = NULL,
      y = "standardized diagnostic scale",
      title = title_txt,
      linetype = NULL
    ) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
  
  ggsave(out_png, p, width = fig_width, height = fig_height, dpi = fig_dpi)
  ggsave(out_pdf, p, width = fig_width, height = fig_height)
  
  invisible(p)
}

# ── 3. Load data ─────────────────────────────────────────────────────────────
d <- load_profitability_panel(path_d_rds, path_bundle_rds)

required_vars <- c("year", level_var, ect_var)
miss_vars <- required_vars[!required_vars %in% names(d)]
if (length(miss_vars) > 0) {
  stop("Missing required variable(s): ", paste(miss_vars, collapse = ", "), call. = FALSE)
}

d <- d |>
  dplyr::filter(year >= analysis_year_min, year <= analysis_year_max) |>
  dplyr::arrange(year)

if (!(log_var %in% names(d))) {
  d[[log_var]] <- log(d[[level_var]])
}

if (any(!is.finite(d[[level_var]]) | d[[level_var]] <= 0, na.rm = TRUE)) {
  stop("Profit-rate level series contains non-positive or non-finite values.", call. = FALSE)
}

# ── 4. Compute signals ───────────────────────────────────────────────────────
signal_tbl <- compute_signal_table(
  df = d,
  level_var = level_var,
  log_var = log_var,
  k_smooth = k_smooth,
  ect_var = ect_var,
  ect_smooth_k = ect_smooth_k
)

# ── 5. Detection ladder ──────────────────────────────────────────────────────
tp_candidates_primary <- find_tp_from_signal(
  signal_tbl = signal_tbl,
  signal_col = "dlog_r_smoothed",
  span = local_span,
  method_name = "smoothed_dlog_rule"
) |>
  compress_turning_points()

tp_candidates_raw <- find_tp_from_signal(
  signal_tbl = signal_tbl,
  signal_col = "dlog_r",
  span = local_span,
  method_name = "raw_dlog_rule"
) |>
  compress_turning_points()

tp_candidates_level <- find_tp_from_levels(
  signal_tbl = signal_tbl,
  span = local_span
) |>
  compress_turning_points()

tp_candidates_used <- tp_candidates_primary
candidate_method_used <- "smoothed_dlog_rule"

if (nrow(tp_candidates_used) == 0 && nrow(tp_candidates_raw) > 0) {
  tp_candidates_used <- tp_candidates_raw
  candidate_method_used <- "raw_dlog_rule"
}

if (nrow(tp_candidates_used) == 0 && nrow(tp_candidates_level) > 0) {
  tp_candidates_used <- tp_candidates_level
  candidate_method_used <- "level_extrema"
}

tp_final_pruned <- if (nrow(tp_candidates_used) > 0) {
  prune_turning_points_joint(
    tp = tp_candidates_used,
    signal_tbl = signal_tbl,
    min_years = min_years_between_tp,
    min_log_move = min_log_move
  ) |>
    compress_turning_points()
} else {
  tp_candidates_used
}

tp_used <- tp_final_pruned
used_boundary_only <- FALSE

if (nrow(tp_used) == 0) {
  tp_used <- make_boundary_only_tp(signal_tbl)
  used_boundary_only <- TRUE
}

tp_bounds <- if (used_boundary_only) {
  tp_used
} else {
  add_boundaries_keep_rhs(
    tp = tp_used,
    signal_tbl = signal_tbl
  )
}

swings_tbl <- build_swing_table(
  tp_bounds = tp_bounds,
  signal_tbl = signal_tbl
)

tp_status <- tibble::tibble(
  level_var = level_var,
  log_var = log_var,
  ect_var = ect_var,
  n_candidates_primary = nrow(tp_candidates_primary),
  n_candidates_raw = nrow(tp_candidates_raw),
  n_candidates_level = nrow(tp_candidates_level),
  candidate_method_used = candidate_method_used,
  n_candidates_used = nrow(tp_candidates_used),
  n_after_prune = nrow(tp_final_pruned),
  used_boundary_only = used_boundary_only
)

config_tbl <- tibble::tibble(
  analysis_year_min = analysis_year_min,
  analysis_year_max = analysis_year_max,
  level_var = level_var,
  log_var = log_var,
  ect_var = ect_var,
  k_smooth = k_smooth,
  ect_smooth_k = ect_smooth_k,
  local_span = local_span,
  min_years_between_tp = min_years_between_tp,
  min_log_move = min_log_move
)

# ── 6. Save outputs ──────────────────────────────────────────────────────────
readr::write_csv(config_tbl, file.path(csv_dir, "diagnostic_config_chile_profit_swings_short_very_19681975.csv"))
readr::write_csv(tp_status, file.path(csv_dir, "turning_points_status_chile_profit_swings_short_very_19681975.csv"))

readr::write_csv(signal_tbl, file.path(csv_dir, "signal_table_chile_profit_swings_short_very_19681975.csv"))
readr::write_csv(tp_candidates_primary, file.path(csv_dir, "turning_points_candidates_primary_chile_profit_swings_short_very_19681975.csv"))
readr::write_csv(tp_candidates_raw, file.path(csv_dir, "turning_points_candidates_raw_chile_profit_swings_short_very_19681975.csv"))
readr::write_csv(tp_candidates_level, file.path(csv_dir, "turning_points_candidates_level_chile_profit_swings_short_very_19681975.csv"))
readr::write_csv(tp_candidates_used, file.path(csv_dir, "turning_points_candidates_used_chile_profit_swings_short_very_19681975.csv"))
readr::write_csv(tp_final_pruned, file.path(csv_dir, "turning_points_final_pruned_chile_profit_swings_short_very_19681975.csv"))
readr::write_csv(tp_used, file.path(csv_dir, "turning_points_used_chile_profit_swings_short_very_19681975.csv"))
readr::write_csv(tp_bounds, file.path(csv_dir, "turning_points_with_boundaries_chile_profit_swings_short_very_19681975.csv"))
readr::write_csv(swings_tbl, file.path(csv_dir, "profit_swings_joint_diagnostic_chile_short_very_19681975.csv"))

saveRDS(config_tbl, file.path(rds_dir, "diagnostic_config_chile_profit_swings_short_very_19681975.rds"))
saveRDS(tp_status, file.path(rds_dir, "turning_points_status_chile_profit_swings_short_very_19681975.rds"))
saveRDS(signal_tbl, file.path(rds_dir, "signal_table_chile_profit_swings_short_very_19681975.rds"))
saveRDS(tp_candidates_primary, file.path(rds_dir, "turning_points_candidates_primary_chile_profit_swings_short_very_19681975.rds"))
saveRDS(tp_candidates_raw, file.path(rds_dir, "turning_points_candidates_raw_chile_profit_swings_short_very_19681975.rds"))
saveRDS(tp_candidates_level, file.path(rds_dir, "turning_points_candidates_level_chile_profit_swings_short_very_19681975.rds"))
saveRDS(tp_candidates_used, file.path(rds_dir, "turning_points_candidates_used_chile_profit_swings_short_very_19681975.rds"))
saveRDS(tp_final_pruned, file.path(rds_dir, "turning_points_final_pruned_chile_profit_swings_short_very_19681975.rds"))
saveRDS(tp_used, file.path(rds_dir, "turning_points_used_chile_profit_swings_short_very_19681975.rds"))
saveRDS(tp_bounds, file.path(rds_dir, "turning_points_with_boundaries_chile_profit_swings_short_very_19681975.rds"))
saveRDS(swings_tbl, file.path(rds_dir, "profit_swings_joint_diagnostic_chile_short_very_19681975.rds"))

# ── 7. Figures ───────────────────────────────────────────────────────────────
plot_joint_diagnostic(
  signal_tbl = signal_tbl,
  tp_used = tp_used,
  out_png = file.path(fig_dir, "fig01_chile_profit_turning_points_joint_short_very_19681975.png"),
  out_pdf = file.path(fig_dir, "fig01_chile_profit_turning_points_joint_short_very_19681975.pdf"),
  title_txt = NULL
)

plot_ect_diagnostic(
  signal_tbl = signal_tbl,
  tp_used = tp_used,
  out_png = file.path(fig_dir, "fig02_chile_profit_vs_ect_diagnostic_short_very_19681975.png"),
  out_pdf = file.path(fig_dir, "fig02_chile_profit_vs_ect_diagnostic_short_very_19681975.pdf"),
  title_txt = NULL
)

# ── 8. Console summary ───────────────────────────────────────────────────────
cat("Saved Chile very-short-run profit swings diagnostic outputs to:\n")
cat("  ", out_root, "\n", sep = "")
cat("Files:\n")
cat("  csv/diagnostic_config_chile_profit_swings_short_very_19681975.csv\n")
cat("  csv/turning_points_status_chile_profit_swings_short_very_19681975.csv\n")
cat("  csv/signal_table_chile_profit_swings_short_very_19681975.csv\n")
cat("  csv/turning_points_candidates_primary_chile_profit_swings_short_very_19681975.csv\n")
cat("  csv/turning_points_candidates_raw_chile_profit_swings_short_very_19681975.csv\n")
cat("  csv/turning_points_candidates_level_chile_profit_swings_short_very_19681975.csv\n")
cat("  csv/turning_points_candidates_used_chile_profit_swings_short_very_19681975.csv\n")
cat("  csv/turning_points_final_pruned_chile_profit_swings_short_very_19681975.csv\n")
cat("  csv/turning_points_used_chile_profit_swings_short_very_19681975.csv\n")
cat("  csv/turning_points_with_boundaries_chile_profit_swings_short_very_19681975.csv\n")
cat("  csv/profit_swings_joint_diagnostic_chile_short_very_19681975.csv\n")
cat("  figures/fig01_chile_profit_turning_points_joint_short_very_19681975.png\n")
cat("  figures/fig01_chile_profit_turning_points_joint_short_very_19681975.pdf\n")
cat("  figures/fig02_chile_profit_vs_ect_diagnostic_short_very_19681975.png\n")
cat("  figures/fig02_chile_profit_vs_ect_diagnostic_short_very_19681975.pdf\n")
cat("  rds/*.rds\n")