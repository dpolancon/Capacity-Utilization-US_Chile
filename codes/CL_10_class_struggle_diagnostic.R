###############################################################################
# CHILE — Class-struggle temporality from Astorga (2023), Weisskopf-style
#
# Workflow:
# 1) load Astorga data
# 2) janitor / keep only variables of interest
# 3) reduced-form Weisskopf decomposition
# 4) peak-to-trough analysis from smoothed wage-share LEVEL
# 5) decompose each swing
# 6) compare class-struggle swings against fixed profit-rate shell
#
# Core identity:
#   w_share_t = (w/y)_t * price_wedge_t
# so that
#   d ln(w_share) = d ln(w/y) + d ln(price_wedge)
#
# Interpretation:
# - offensive_component = d ln(w/y)
# - defensive_component = d ln(price_wedge)
###############################################################################

# ── 0. Packages ──────────────────────────────────────────────────────────────
pkgs <- c("readxl", "dplyr", "tibble", "readr", "ggplot2", "zoo")
miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss) > 0) install.packages(miss, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

# ── 1. Paths and controls ────────────────────────────────────────────────────
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

path_astorga <- file.path(
  proj_root, "data", "raw", "Chile", "Astorga2023_SupM3.xlsx"
)

out_root <- file.path(
  proj_root, "output", "chile_class_struggle_astorga_weisskopf"
)
csv_dir <- file.path(out_root, "csv")
fig_dir <- file.path(out_root, "figures")
rds_dir <- file.path(out_root, "rds")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)

analysis_year_min <- 1940L
analysis_year_max <- 1978L

# Turning-point controls
k_smooth <- 3L
local_span <- 1L
min_years_between_tp <- 2L
min_log_move <- 0.02

# Optional manual override if ever needed later
use_manual_tp <- FALSE
manual_tp <- tibble::tribble(
  ~year, ~type,
  1942L, "trough",
  1947L, "peak",
  1955L, "trough",
  1964L, "peak",
  1969L, "trough",
  1972L, "peak"
)

# Figure settings
fig_width <- 12
fig_height <- 7
fig_dpi <- 320

# Fixed shell for later comparison only
profit_shell <- tibble::tribble(
  ~period,       ~start_year, ~end_year,
  "1940_1946",   1940L, 1946L,
  "1946_1949",   1946L, 1949L,
  "1949_1955",   1949L, 1955L,
  "1955_1961",   1955L, 1961L,
  "1961_1969",   1961L, 1969L,
  "1969_1972",   1969L, 1972L,
  "1972_1974",   1972L, 1974L,
  "1974_1976",   1974L, 1976L,
  "1976_1978",   1976L, 1978L
)

# ── 2. Helpers ───────────────────────────────────────────────────────────────
zsafe <- function(x) {
  s <- stats::sd(x, na.rm = TRUE)
  m <- mean(x, na.rm = TRUE)
  if (!is.finite(s) || s <= 0) return(rep(NA_real_, length(x)))
  (x - m) / s
}

compress_turning_points <- function(tp) {
  if (nrow(tp) <= 1) return(tp)
  
  keep <- vector("list", 0)
  current <- tp[1, , drop = FALSE]
  
  for (i in 2:nrow(tp)) {
    this <- tp[i, , drop = FALSE]
    
    if (this$type == current$type) {
      if (this$type == "peak" && this$value > current$value) current <- this
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

find_tp_from_levels <- function(df, level_col) {
  year <- df$year
  level <- df[[level_col]]
  
  out <- vector("list", 0)
  
  if (length(level) < 3) {
    return(tibble::tibble(
      method = character(),
      idx = integer(),
      year = integer(),
      value = numeric(),
      type = character()
    ))
  }
  
  for (i in 2:(length(level) - 1)) {
    if (is.na(level[i - 1]) || is.na(level[i]) || is.na(level[i + 1])) next
    
    if (level[i - 1] < level[i] && level[i] > level[i + 1]) {
      out[[length(out) + 1]] <- tibble::tibble(
        method = "smoothed_level_extrema",
        idx = i,
        year = year[i],
        value = level[i],
        type = "peak"
      )
    } else if (level[i - 1] > level[i] && level[i] < level[i + 1]) {
      out[[length(out) + 1]] <- tibble::tibble(
        method = "smoothed_level_extrema",
        idx = i,
        year = year[i],
        value = level[i],
        type = "trough"
      )
    }
  }
  
  if (length(out) == 0) {
    return(tibble::tibble(
      method = character(),
      idx = integer(),
      year = integer(),
      value = numeric(),
      type = character()
    ))
  }
  
  dplyr::bind_rows(out) |>
    dplyr::distinct(idx, .keep_all = TRUE) |>
    dplyr::arrange(idx)
}

prune_turning_points_joint <- function(tp, df, log_level_col,
                                       min_years = 2L, min_log_move = 0.02) {
  if (nrow(tp) <= 1) return(tp)
  
  log_level <- df[[log_level_col]]
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

make_boundary_only_tp <- function(df, level_col) {
  level_first <- df[[level_col]][1]
  level_last  <- df[[level_col]][nrow(df)]
  
  start_type <- if (level_last >= level_first) "trough" else "peak"
  end_type   <- if (start_type == "trough") "peak" else "trough"
  
  tibble::tibble(
    method = "boundary_only",
    idx = c(1L, nrow(df)),
    year = c(df$year[1], df$year[nrow(df)]),
    value = c(level_first, level_last),
    type = c(start_type, end_type)
  )
}

add_boundaries_keep_rhs <- function(tp, df, level_col) {
  if (nrow(tp) == 0) return(make_boundary_only_tp(df, level_col))
  
  first_type <- if (tp$type[1] == "peak") "trough" else "peak"
  last_type  <- if (tp$type[nrow(tp)] == "peak") "trough" else "peak"
  
  start_row <- tibble::tibble(
    method = "boundary",
    idx = 1L,
    year = df$year[1],
    value = df[[level_col]][1],
    type = first_type
  )
  
  end_row <- tibble::tibble(
    method = "boundary",
    idx = nrow(df),
    year = df$year[nrow(df)],
    value = df[[level_col]][nrow(df)],
    type = last_type
  )
  
  dplyr::bind_rows(start_row, tp, end_row) |>
    dplyr::arrange(idx) |>
    compress_turning_points()
}

classify_mode <- function(cum_offensive, cum_defensive) {
  dplyr::case_when(
    cum_offensive > 0 & cum_defensive > 0 ~ "joint_advance",
    cum_offensive > 0 & cum_defensive < 0 ~ "offensive_advance_with_price_headwind",
    cum_offensive < 0 & cum_defensive > 0 ~ "defensive_resistance",
    cum_offensive < 0 & cum_defensive < 0 ~ "joint_retreat",
    TRUE ~ "mixed_or_flat"
  )
}

build_class_struggle_swings <- function(tp_bounds, yearly_df) {
  if (nrow(tp_bounds) < 2) return(tibble::tibble())
  
  out <- vector("list", nrow(tp_bounds) - 1)
  
  for (i in seq_len(nrow(tp_bounds) - 1)) {
    y0 <- tp_bounds$year[i]
    y1 <- tp_bounds$year[i + 1]
    idx0 <- tp_bounds$idx[i]
    idx1 <- tp_bounds$idx[i + 1]
    
    x <- yearly_df |>
      dplyr::filter(year > y0, year <= y1)
    
    cum_wshare <- sum(x$dln_w_share, na.rm = TRUE)
    cum_off <- sum(x$offensive_component, na.rm = TRUE)
    cum_def <- sum(x$defensive_component, na.rm = TRUE)
    total_abs <- abs(cum_off) + abs(cum_def)
    
    out[[i]] <- tibble::tibble(
      swing_id = i,
      start_year = y0,
      end_year = y1,
      start_type = tp_bounds$type[i],
      end_type = tp_bounds$type[i + 1],
      swing_direction = paste0(tp_bounds$type[i], "_to_", tp_bounds$type[i + 1]),
      duration_years = y1 - y0,
      start_w_share = yearly_df$w_share[idx0],
      end_w_share = yearly_df$w_share[idx1],
      amplitude_log = yearly_df$ln_w_share[idx1] - yearly_df$ln_w_share[idx0],
      cum_dln_w_share = cum_wshare,
      cum_offensive = cum_off,
      cum_defensive = cum_def,
      closure_gap = cum_wshare - cum_off - cum_def,
      offensive_share_abs = ifelse(total_abs > 0, abs(cum_off) / total_abs, NA_real_),
      defensive_share_abs = ifelse(total_abs > 0, abs(cum_def) / total_abs, NA_real_),
      dominant_mode = classify_mode(cum_off, cum_def)
    )
  }
  
  dplyr::bind_rows(out)
}

build_profit_shell_compare <- function(shell_df, yearly_df) {
  out <- vector("list", nrow(shell_df))
  
  for (i in seq_len(nrow(shell_df))) {
    p <- shell_df[i, , drop = FALSE]
    
    level_x <- yearly_df |>
      dplyr::filter(year >= p$start_year, year <= p$end_year)
    flow_x <- yearly_df |>
      dplyr::filter(year > p$start_year, year <= p$end_year)
    
    cum_wshare <- sum(flow_x$dln_w_share, na.rm = TRUE)
    cum_off <- sum(flow_x$offensive_component, na.rm = TRUE)
    cum_def <- sum(flow_x$defensive_component, na.rm = TRUE)
    total_abs <- abs(cum_off) + abs(cum_def)
    
    out[[i]] <- tibble::tibble(
      period = p$period,
      start_year = p$start_year,
      end_year = p$end_year,
      n_level_years = nrow(level_x),
      n_flow_years = nrow(flow_x),
      mean_w_share = mean(level_x$w_share, na.rm = TRUE),
      mean_w_over_y = mean(level_x$w_over_y, na.rm = TRUE),
      mean_price_wedge = mean(level_x$price_wedge, na.rm = TRUE),
      cum_dln_w_share = cum_wshare,
      cum_offensive = cum_off,
      cum_defensive = cum_def,
      closure_gap = cum_wshare - cum_off - cum_def,
      offensive_share_abs = ifelse(total_abs > 0, abs(cum_off) / total_abs, NA_real_),
      defensive_share_abs = ifelse(total_abs > 0, abs(cum_def) / total_abs, NA_real_),
      dominant_mode = classify_mode(cum_off, cum_def)
    )
  }
  
  dplyr::bind_rows(out)
}

build_overlap_table <- function(cs_swings, shell_df) {
  out <- vector("list", 0)
  
  for (i in seq_len(nrow(cs_swings))) {
    for (j in seq_len(nrow(shell_df))) {
      a0 <- cs_swings$start_year[i]
      a1 <- cs_swings$end_year[i]
      b0 <- shell_df$start_year[j]
      b1 <- shell_df$end_year[j]
      
      overlap_start <- max(a0, b0)
      overlap_end <- min(a1, b1)
      overlap_years <- overlap_end - overlap_start + 1L
      
      if (overlap_years > 0) {
        out[[length(out) + 1]] <- tibble::tibble(
          swing_id = cs_swings$swing_id[i],
          class_struggle_interval = paste0(cs_swings$start_year[i], "_", cs_swings$end_year[i]),
          class_struggle_mode = cs_swings$dominant_mode[i],
          profit_period = shell_df$period[j],
          overlap_start = overlap_start,
          overlap_end = overlap_end,
          overlap_years = overlap_years
        )
      }
    }
  }
  
  if (length(out) == 0) return(tibble::tibble())
  dplyr::bind_rows(out)
}

# ── 3. Load and janitor Astorga variables of interest ────────────────────────
raw_astorga <- readxl::read_excel(
  path = path_astorga,
  sheet = "Chile",
  range = "A1:Q99",
  col_names = FALSE
)

names(raw_astorga) <- paste0("c", seq_len(ncol(raw_astorga)))

astorga_clean <- raw_astorga |>
  dplyr::transmute(
    year_left  = suppressWarnings(as.integer(c2)),
    w          = suppressWarnings(as.numeric(c6)),
    y          = suppressWarnings(as.numeric(c7)),
    w_over_y   = suppressWarnings(as.numeric(c15)),
    w_share    = suppressWarnings(as.numeric(c16)),
    year_right = suppressWarnings(as.integer(c17))
  ) |>
  dplyr::filter(!is.na(year_left)) |>
  dplyr::rename(year = year_left) |>
  dplyr::filter(year >= analysis_year_min, year <= analysis_year_max) |>
  dplyr::arrange(year) |>
  dplyr::mutate(
    year_check = ifelse(!is.na(year_right), year_right == year, TRUE),
    w_over_y_rebuilt = w / y,
    w_over_y_gap_check = w_over_y - w_over_y_rebuilt
  )

# ── 4. Reduced-form Weisskopf decomposition ──────────────────────────────────
astorga_decomp <- astorga_clean |>
  dplyr::mutate(
    price_wedge = w_share / w_over_y,
    ln_w_share = log(w_share),
    ln_w_over_y = log(w_over_y),
    ln_price_wedge = log(price_wedge),
    dln_w_share = ln_w_share - dplyr::lag(ln_w_share),
    offensive_component = ln_w_over_y - dplyr::lag(ln_w_over_y),
    defensive_component = ln_price_wedge - dplyr::lag(ln_price_wedge),
    decomposition_gap = dln_w_share - offensive_component - defensive_component
  )

# ── 5. Peak-to-trough analysis on SMOOTHED LEVEL ─────────────────────────────
signal_tbl <- astorga_decomp |>
  dplyr::mutate(
    w_share_smooth = zoo::rollmean(w_share, k = k_smooth, fill = NA, align = "center"),
    ln_w_share_smooth = log(w_share_smooth)
  )

if (use_manual_tp) {
  tp_used <- manual_tp |>
    dplyr::left_join(
      signal_tbl |>
        dplyr::select(year, idx = dplyr::row_number(), value = w_share),
      by = "year"
    ) |>
    dplyr::mutate(method = "manual_override") |>
    dplyr::select(method, idx, year, value, type)
  candidate_method_used <- "manual_override"
  tp_candidates_used <- tp_used
  tp_final_pruned <- tp_used
  used_boundary_only <- FALSE
} else {
  tp_candidates_used <- find_tp_from_levels(signal_tbl, "w_share_smooth") |>
    compress_turning_points()
  
  candidate_method_used <- "smoothed_level_extrema"
  
  tp_final_pruned <- if (nrow(tp_candidates_used) > 0) {
    prune_turning_points_joint(
      tp = tp_candidates_used,
      df = signal_tbl,
      log_level_col = "ln_w_share_smooth",
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
    tp_used <- make_boundary_only_tp(signal_tbl, "w_share")
    used_boundary_only <- TRUE
  }
}

tp_bounds <- if (used_boundary_only) {
  tp_used
} else {
  add_boundaries_keep_rhs(tp_used, signal_tbl, "w_share")
}

class_struggle_swings <- build_class_struggle_swings(tp_bounds, astorga_decomp)

tp_status <- tibble::tibble(
  analysis_year_min = analysis_year_min,
  analysis_year_max = analysis_year_max,
  turning_point_method = candidate_method_used,
  n_candidates_used = nrow(tp_candidates_used),
  n_after_prune = nrow(tp_final_pruned),
  used_boundary_only = used_boundary_only,
  k_smooth = k_smooth,
  min_years_between_tp = min_years_between_tp,
  min_log_move = min_log_move,
  use_manual_tp = use_manual_tp
)

# ── 6. Compare against fixed profit-rate swing shell ─────────────────────────
profit_shell_compare <- build_profit_shell_compare(profit_shell, astorga_decomp)
crosswalk_overlap <- build_overlap_table(class_struggle_swings, profit_shell)

# ── 7. Figures ───────────────────────────────────────────────────────────────
fig01 <- ggplot(signal_tbl, aes(x = year)) +
  geom_line(aes(y = w_share, linetype = "Observed wage share"), linewidth = 1.0) +
  geom_line(
    aes(y = w_share_smooth, linetype = "Centered 3-year smooth"),
    linewidth = 1.0
  ) +
  geom_point(
    data = tp_used |>
      dplyr::filter(!method %in% c("boundary", "boundary_only")),
    aes(y = value, shape = type),
    size = 3
  ) +
  scale_linetype_manual(values = c(
    "Observed wage share" = "solid",
    "Centered 3-year smooth" = "dashed"
  )) +
  scale_shape_manual(values = c(peak = 24, trough = 25)) +
  labs(x = NULL, y = "wage share", linetype = NULL, shape = NULL, title = NULL) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

ggsave(
  filename = file.path(fig_dir, "fig01_wage_share_peak_trough_class_struggle.png"),
  plot = fig01, width = fig_width, height = fig_height, dpi = fig_dpi
)
ggsave(
  filename = file.path(fig_dir, "fig01_wage_share_peak_trough_class_struggle.pdf"),
  plot = fig01, width = fig_width, height = fig_height
)

fig02 <- ggplot(astorga_decomp |> dplyr::filter(!is.na(offensive_component)), aes(x = year)) +
  geom_hline(yintercept = 0, linetype = "dotted", linewidth = 0.4) +
  geom_line(aes(y = offensive_component, linetype = "Offensive component"), linewidth = 1.0) +
  geom_line(aes(y = defensive_component, linetype = "Defensive component"), linewidth = 1.0) +
  scale_linetype_manual(values = c(
    "Offensive component" = "solid",
    "Defensive component" = "dashed"
  )) +
  labs(x = NULL, y = "log-change contribution", linetype = NULL, title = NULL) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

ggsave(
  filename = file.path(fig_dir, "fig02_offensive_defensive_components_yearly.png"),
  plot = fig02, width = fig_width, height = fig_height, dpi = fig_dpi
)
ggsave(
  filename = file.path(fig_dir, "fig02_offensive_defensive_components_yearly.pdf"),
  plot = fig02, width = fig_width, height = fig_height
)

# ── 8. Save outputs ──────────────────────────────────────────────────────────
readr::write_csv(astorga_clean, file.path(csv_dir, "astorga_clean_1940_1978.csv"))
readr::write_csv(astorga_decomp, file.path(csv_dir, "astorga_decomposition_1940_1978.csv"))
readr::write_csv(tp_status, file.path(csv_dir, "class_struggle_turning_point_status.csv"))
readr::write_csv(tp_candidates_used, file.path(csv_dir, "class_struggle_tp_candidates_used.csv"))
readr::write_csv(tp_final_pruned, file.path(csv_dir, "class_struggle_tp_final_pruned.csv"))
readr::write_csv(tp_used, file.path(csv_dir, "class_struggle_tp_used.csv"))
readr::write_csv(tp_bounds, file.path(csv_dir, "class_struggle_tp_with_boundaries.csv"))
readr::write_csv(class_struggle_swings, file.path(csv_dir, "class_struggle_swings_peak_to_trough.csv"))
readr::write_csv(profit_shell_compare, file.path(csv_dir, "class_struggle_vs_profit_shell.csv"))
readr::write_csv(crosswalk_overlap, file.path(csv_dir, "class_struggle_profit_shell_overlap.csv"))

saveRDS(astorga_clean, file.path(rds_dir, "astorga_clean_1940_1978.rds"))
saveRDS(astorga_decomp, file.path(rds_dir, "astorga_decomposition_1940_1978.rds"))
saveRDS(class_struggle_swings, file.path(rds_dir, "class_struggle_swings_peak_to_trough.rds"))
saveRDS(profit_shell_compare, file.path(rds_dir, "class_struggle_vs_profit_shell.rds"))
saveRDS(crosswalk_overlap, file.path(rds_dir, "class_struggle_profit_shell_overlap.rds"))

# ── 9. Console audit ─────────────────────────────────────────────────────────
cat("\nAstorga janitor audit\n")
cat("---------------------\n")
cat("Rows 1940-1978                 :", nrow(astorga_clean), "\n")
cat("Year check all TRUE           :", all(astorga_clean$year_check, na.rm = TRUE), "\n")
cat("Max abs w_over_y rebuild gap  :", max(abs(astorga_clean$w_over_y_gap_check), na.rm = TRUE), "\n")
cat("Max abs decomposition gap     :", max(abs(astorga_decomp$decomposition_gap), na.rm = TRUE), "\n")

cat("\nTurning-point status\n")
cat("--------------------\n")
print(tp_status)

cat("\nClass-struggle swings (peak-to-trough)\n")
cat("--------------------------------------\n")
print(class_struggle_swings)

cat("\nComparison inside fixed profit-rate shell\n")
cat("-----------------------------------------\n")
print(profit_shell_compare)

cat("\nOverlap table: endogenous class-struggle swings vs fixed profit shell\n")
cat("--------------------------------------------------------------------\n")
print(crosswalk_overlap)