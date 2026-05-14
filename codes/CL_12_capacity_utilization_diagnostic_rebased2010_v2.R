# ============================================================
# CHILE — Capacity-utilization diagnostic package
# Domestic vs external corridor + external decomposition
# in output space and accumulation units
# ------------------------------------------------------------
# Built to mirror the architecture of:
#   - CL_10_class_struggle_diagnostic.R
#   - CL_11_dys_diagnostic_package.R
#
# Main outputs:
#   1) annual utilization panel
#   2) Stage 1 decomposition: domestic vs external corridor
#   3) Stage 2 decomposition: output-space external corridor
#   4) Stage 3 decomposition: accumulation-unit external corridor
#   5) utilization swings from smoothed mu levels
#   6) collapsed-period summaries (1940–1978 shell)
#
# Important note:
# This script is designed to be data-grabbing + architecture-ready.
# It attempts to auto-resolve source columns from the Chile profitability
# RDS layer. If the repo uses different names for trade variables,
# update MANUAL_MAP below.
#
# FRAMEWORK RULE:
# All price indices and real-term objects are operationally rebased to 2010
# before any Stage 1/2/3 decomposition is computed. Source provenance base
# years are ignored at the diagnostic stage.
# ============================================================

suppressPackageStartupMessages({
  library(here)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(purrr)
  library(stringr)
  library(ggplot2)
  library(zoo)
})

has_readxl <- requireNamespace("readxl", quietly = TRUE)

# ============================================================
# 0. PATHS, CONTROLS, AND MANUAL COLUMN MAP
# ============================================================

# ---- Existing structural outputs already validated ----
path_stage1_master <- here::here("output", "chile_2Smu_S1", "txt", "stage1__master_results.rds")
path_stage2_root   <- here::here("output", "chile_2Smu_S2_tdols")
path_theta_isi     <- file.path(path_stage2_root, "csv", "threshold_theta__isi1931_1973.csv")
path_theta_post    <- file.path(path_stage2_root, "csv", "threshold_theta__post1974.csv")
path_stage2_panel  <- file.path(path_stage2_root, "csv", "stage2__working_panel.csv")

# ---- Profitability source ----
path_profit_rds <- here::here("output", "profitability_chile", "rds", "d_merged_profitability_chile.rds")
path_profit_bundle_rds <- here::here("output", "profitability_chile", "rds", "analytical_bundle_chile.rds")

# ---- Optional external-trade raw sources ----
path_trade_csv  <- here::here("data", "raw", "Chile", "harmonized_series_2003CLP_1900_2024.csv")
path_trade_xlsx <- here::here("data", "raw", "Chile", "PerezEyzaguirre_DemandaAgregada.xlsx")

# ---- Output root ----
out_root <- here::here("output", "chile_capacity_utilization_diagnostic")
out_csv  <- file.path(out_root, "csv")
out_figs <- file.path(out_root, "figs")
out_txt  <- file.path(out_root, "txt")

for (p in c(out_csv, out_figs, out_txt)) dir.create(p, recursive = TRUE, showWarnings = FALSE)

# ---- Governing structural sample lock ----
GOV_SAMPLE_PRE1974 <- "ISI1931_1973"
GAMMA_ISI <- -6.231728207560405
PINCH_YEAR <- 1980

analysis_year_min <- 1940L
analysis_year_max <- 1978L

# Turning-point controls (mirrors class-struggle workflow)
k_smooth <- 3L
min_years_between_tp <- 2L
min_log_move <- 0.02

# Figure settings
fig_width <- 10.5
fig_height <- 5.8
fig_dpi <- 320

# ---- Manual column map ----
# Set any of these to exact column names in your repo if auto-detection misses.
MANUAL_MAP <- list(
  pY = NULL,
  pK = NULL,
  pX = NULL,
  pM = NULL,
  X_q = NULL,
  M_q = NULL,
  X_nom = NULL,
  M_nom = NULL,
  trade_year = NULL,
  trade_sheet = NULL
)

# ============================================================
# 1. HELPERS
# ============================================================

write_txt <- function(lines, path) {
  writeLines(as.character(lines), con = path, useBytes = TRUE)
}

assert_file <- function(path) {
  if (!file.exists(path)) stop("Missing required file: ", path, call. = FALSE)
}

safe_mean <- function(x) {
  if (all(is.na(x))) return(NA_real_)
  mean(x, na.rm = TRUE)
}

safe_sum <- function(x) {
  if (all(is.na(x))) return(NA_real_)
  sum(x, na.rm = TRUE)
}

mode_chr <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_character_)
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

longest_run_true <- function(x) {
  if (length(x) == 0 || all(is.na(x))) return(NA_integer_)
  r <- rle(replace(x, is.na(x), FALSE))
  if (!any(r$values)) return(0L)
  max(r$lengths[r$values])
}

safe_div <- function(num, den) {
  ifelse(is.na(den) | den == 0, NA_real_, num / den)
}

midpoint <- function(x) {
  (x + dplyr::lag(x)) / 2
}

get_base_value <- function(x, year, base_year = 2010) {
  idx <- which(year == base_year)
  if (length(idx) == 0) {
    stop("Base year ", base_year, " not found in series.", call. = FALSE)
  }
  out <- x[idx[1]]
  if (is.na(out) || out == 0) {
    stop("Base year value missing or zero for base year ", base_year, ".", call. = FALSE)
  }
  out
}

rebase_index_to_year <- function(index_x, year, base_year = 2010) {
  base_val <- get_base_value(index_x, year, base_year)
  (index_x / base_val) * 100
}

rebase_real_with_index <- function(real_x, index_x, year, base_year = 2010) {
  base_val <- get_base_value(index_x, year, base_year)
  real_x * (base_val / 100)
}

deflate_nominal_to_real_2010 <- function(nominal_x, index_x, year, base_year = 2010) {
  index_2010 <- rebase_index_to_year(index_x, year, base_year)
  nominal_x / (index_2010 / 100)
}


suggest_cols <- function(df, patterns) {
  nm <- names(df)
  keep <- nm[str_detect(tolower(nm), patterns)]
  unique(keep)
}

resolve_year_col <- function(df, manual_name = NULL) {
  if (!is.null(manual_name) && manual_name %in% names(df)) return(manual_name)
  cand <- c("year", "Year", "anio", "ano", "año")
  hit <- cand[cand %in% names(df)]
  if (length(hit) > 0) return(hit[[1]])
  low_nm <- tolower(names(df))
  low_cand <- tolower(cand)
  idx <- match(low_cand, low_nm)
  idx <- idx[!is.na(idx)]
  if (length(idx) > 0) return(names(df)[idx[[1]]])
  NA_character_
}

load_external_trade_source <- function(path_trade_csv, path_trade_xlsx, manual_sheet = NULL) {
  out <- list(df = NULL, source = NULL)

  if (file.exists(path_trade_csv)) {
    df_csv <- tryCatch(readr::read_csv(path_trade_csv, show_col_types = FALSE), error = function(e) NULL)
    if (!is.null(df_csv)) {
      out$df <- df_csv
      out$source <- basename(path_trade_csv)
      return(out)
    }
  }

  if (file.exists(path_trade_xlsx) && has_readxl) {
    sheets <- tryCatch(readxl::excel_sheets(path_trade_xlsx), error = function(e) character())
    if (!is.null(manual_sheet) && manual_sheet %in% sheets) sheets <- c(manual_sheet, setdiff(sheets, manual_sheet))
    for (sh in sheets) {
      df_x <- tryCatch(readxl::read_excel(path_trade_xlsx, sheet = sh), error = function(e) NULL)
      if (is.null(df_x)) next
      ycol <- resolve_year_col(df_x, MANUAL_MAP$trade_year)
      if (is.na(ycol)) next
      nm <- names(df_x)
      low <- tolower(nm)
      has_x <- any(str_detect(low, "(^|_)(xq|x_q|xvol|export|expo|exp)(_|$)|exportac"))
      has_m <- any(str_detect(low, "(^|_)(mq|m_q|mvol|import|imp)(_|$)|importac"))
      if (has_x && has_m) {
        out$df <- as_tibble(df_x)
        out$source <- paste0(basename(path_trade_xlsx), "::", sh)
        return(out)
      }
    }
  }

  out
}

load_profitability_panel <- function(path_profit_rds, path_profit_bundle_rds) {
  if (file.exists(path_profit_rds)) {
    return(readRDS(path_profit_rds))
  }
  if (file.exists(path_profit_bundle_rds)) {
    b <- readRDS(path_profit_bundle_rds)
    if (!("d" %in% names(b))) {
      stop("Profitability bundle found, but object `d` is missing.", call. = FALSE)
    }
    return(b$d)
  }
  stop(
    paste0(
      "Missing profitability source objects. Expected one of:\n",
      path_profit_rds, "\n",
      path_profit_bundle_rds
    ),
    call. = FALSE
  )
}

resolve_col <- function(df, manual_name, candidates, label) {
  if (!is.null(manual_name)) {
    if (!(manual_name %in% names(df))) {
      stop("Manual mapping for `", label, "` points to missing column: ", manual_name, call. = FALSE)
    }
    return(manual_name)
  }

  nm <- names(df)
  # exact match first
  hit <- candidates[candidates %in% nm]
  if (length(hit) > 0) return(hit[[1]])

  # case-insensitive fallback
  low_nm <- tolower(nm)
  low_cand <- tolower(candidates)
  idx <- match(low_cand, low_nm)
  idx <- idx[!is.na(idx)]
  if (length(idx) > 0) return(nm[idx[[1]]])

  stop(
    paste0(
      "Could not resolve column for `", label, "`.\n",
      "Tried candidates: ", paste(candidates, collapse = ", ")
    ),
    call. = FALSE
  )
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
  bind_rows(keep) %>% arrange(idx)
}

find_tp_from_levels <- function(df, level_col) {
  year <- df$year
  level <- df[[level_col]]

  out <- vector("list", 0)
  if (length(level) < 3) {
    return(tibble(method = character(), idx = integer(), year = integer(), value = numeric(), type = character()))
  }

  for (i in 2:(length(level) - 1)) {
    if (is.na(level[i - 1]) || is.na(level[i]) || is.na(level[i + 1])) next

    if (level[i - 1] < level[i] && level[i] > level[i + 1]) {
      out[[length(out) + 1]] <- tibble(method = "smoothed_level_extrema", idx = i, year = year[i], value = level[i], type = "peak")
    } else if (level[i - 1] > level[i] && level[i] < level[i + 1]) {
      out[[length(out) + 1]] <- tibble(method = "smoothed_level_extrema", idx = i, year = year[i], value = level[i], type = "trough")
    }
  }

  if (length(out) == 0) {
    return(tibble(method = character(), idx = integer(), year = integer(), value = numeric(), type = character()))
  }

  bind_rows(out) %>% distinct(idx, .keep_all = TRUE) %>% arrange(idx)
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

  tibble(
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

  start_row <- tibble(method = "boundary", idx = 1L, year = df$year[1], value = df[[level_col]][1], type = first_type)
  end_row   <- tibble(method = "boundary", idx = nrow(df), year = df$year[nrow(df)], value = df[[level_col]][nrow(df)], type = last_type)

  bind_rows(start_row, tp, end_row) %>% arrange(idx) %>% compress_turning_points()
}

build_utilization_swings <- function(tp_bounds, yearly_df) {
  if (nrow(tp_bounds) < 2) return(tibble())

  out <- vector("list", nrow(tp_bounds) - 1)
  for (i in seq_len(nrow(tp_bounds) - 1)) {
    y0 <- tp_bounds$year[i]
    y1 <- tp_bounds$year[i + 1]
    idx0 <- tp_bounds$idx[i]
    idx1 <- tp_bounds$idx[i + 1]

    x <- yearly_df %>% filter(year > y0, year <= y1)

    cum_dmu     <- safe_sum(x$d_mu_total)
    cum_dom     <- safe_sum(x$d_mu_dom)
    cum_ext     <- safe_sum(x$d_mu_ext)
    cum_s2_a    <- safe_sum(x$C_stage2_a)
    cum_s2_b    <- safe_sum(x$C_stage2_b)
    cum_s3_p    <- safe_sum(x$C_stage3_p)
    cum_s3_ecg  <- safe_sum(x$C_stage3_ecg)
    cum_qzX     <- safe_sum(x$C_qzX)
    cum_pzM     <- safe_sum(x$C_pzM)

    total_abs_stage1 <- abs(cum_dom) + abs(cum_ext)
    total_abs_stage3 <- abs(cum_qzX) + abs(cum_pzM)

    out[[i]] <- tibble(
      swing_id = i,
      start_year = y0,
      end_year = y1,
      start_type = tp_bounds$type[i],
      end_type = tp_bounds$type[i + 1],
      swing_direction = paste0(tp_bounds$type[i], "_to_", tp_bounds$type[i + 1]),
      duration_years = y1 - y0,
      start_mu = yearly_df$mu[idx0],
      end_mu   = yearly_df$mu[idx1],
      amplitude_log = log(yearly_df$mu[idx1]) - log(yearly_df$mu[idx0]),
      cum_d_mu_total = cum_dmu,
      cum_d_mu_dom = cum_dom,
      cum_d_mu_ext = cum_ext,
      cum_stage2_price_mapping = cum_s2_a,
      cum_stage2_external_command = cum_s2_b,
      cum_stage3_p_conversion = cum_s3_p,
      cum_stage3_ecg = cum_s3_ecg,
      cum_qzX = cum_qzX,
      cum_pzM = cum_pzM,
      stage1_dom_share_abs = safe_div(abs(cum_dom), total_abs_stage1),
      stage1_ext_share_abs = safe_div(abs(cum_ext), total_abs_stage1),
      stage3_qzX_share_abs = safe_div(abs(cum_qzX), total_abs_stage3),
      stage3_pzM_share_abs = safe_div(abs(cum_pzM), total_abs_stage3),
      dominant_stage1_source = case_when(
        abs(cum_dom) > abs(cum_ext) ~ "domestic_corridor",
        abs(cum_ext) > abs(cum_dom) ~ "external_corridor",
        TRUE ~ "balanced_or_flat"
      ),
      dominant_stage3_source = case_when(
        abs(cum_qzX) > abs(cum_pzM) ~ "export_command_accum_units",
        abs(cum_pzM) > abs(cum_qzX) ~ "import_burden_accum_units",
        TRUE ~ "balanced_or_flat"
      )
    )
  }

  bind_rows(out)
}

save_dual <- function(plot_obj, stem, width = fig_width, height = fig_height) {
  ggsave(file.path(out_figs, paste0(stem, ".png")), plot_obj, width = width, height = height, dpi = fig_dpi)
  ggsave(file.path(out_figs, paste0(stem, ".pdf")), plot_obj, width = width, height = height)
}

base_theme <- function() {
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      plot.title = element_blank()
    )
}

# ============================================================
# 2. LOCKED COLLAPSED PERIODS
# ============================================================

collapsed_periods <- tribble(
  ~period,       ~start_year, ~end_year,
  "1940_1946",  1940L,       1946L,
  "1946_1949",  1946L,       1949L,
  "1949_1955",  1949L,       1955L,
  "1955_1961",  1955L,       1961L,
  "1961_1969",  1961L,       1969L,
  "1969_1972",  1969L,       1972L,
  "1972_1974",  1972L,       1974L,
  "1974_1976",  1974L,       1976L,
  "1976_1978",  1976L,       1978L
)

assign_collapsed_period <- function(year_vec) {
  out <- rep(NA_character_, length(year_vec))
  for (i in seq_len(nrow(collapsed_periods))) {
    idx <- year_vec >= collapsed_periods$start_year[i] & year_vec <= collapsed_periods$end_year[i]
    out[idx] <- collapsed_periods$period[i]
  }
  out
}

# ============================================================
# 3. STRUCTURAL PANEL: CONSISTENT THETA + MU (u) + ECT
# ============================================================

assert_file(path_stage1_master)
assert_file(path_theta_isi)
assert_file(path_theta_post)
assert_file(path_stage2_panel)

stage1_master <- readRDS(path_stage1_master)
theta_isi  <- read_csv(path_theta_isi, show_col_types = FALSE)
theta_post <- read_csv(path_theta_post, show_col_types = FALSE)
panel_s2   <- read_csv(path_stage2_panel, show_col_types = FALSE)
profit_df  <- load_profitability_panel(path_profit_rds, path_profit_bundle_rds)

extract_stage1_ect <- function(stage1_master, sample, spec = "S1_B", lag = 1, rank = 1) {
  out <- stage1_master$ect_series %>%
    filter(sample == !!sample, spec == !!spec, lag == !!lag, rank == !!rank) %>%
    arrange(year) %>%
    select(year, ECT)
  if (nrow(out) == 0) {
    stop("No Stage 1 ECT found for sample=", sample, ", spec=", spec, ", lag=", lag, ", rank=", rank, call. = FALSE)
  }
  out
}

ect_isi  <- extract_stage1_ect(stage1_master, "ISI1931_1973")
ect_post <- extract_stage1_ect(stage1_master, "POST1974")

core_struct <- panel_s2 %>%
  select(year, y, k_nr, wsh) %>%
  filter(year >= 1932, year <= 2010)

struct_isi <- theta_isi %>%
  select(year, regime_code, theta_r1, theta_r2, theta_active) %>%
  left_join(ect_isi, by = "year") %>%
  mutate(true_sample = "ISI1931_1973")

struct_post <- theta_post %>%
  select(year, regime_code, theta_r1, theta_r2, theta_active) %>%
  left_join(ect_post, by = "year") %>%
  mutate(true_sample = "POST1974")

struct_splice <- bind_rows(struct_isi, struct_post) %>%
  filter(year >= 1932, year <= 2010) %>%
  arrange(year) %>%
  left_join(core_struct, by = "year") %>%
  mutate(dlog_k_nr = c(NA_real_, diff(k_nr)))

rescue_u_path <- function(df, pinch_year = 1980) {
  df <- arrange(df, year)
  idx0 <- which(df$year == pinch_year)
  if (length(idx0) != 1L) stop("Pinch year not found uniquely.", call. = FALSE)
  logYp <- rep(NA_real_, nrow(df))
  logYp[idx0] <- df$y[idx0]

  if (idx0 < nrow(df)) {
    for (i in (idx0 + 1):nrow(df)) {
      logYp[i] <- logYp[i - 1] + df$theta_active[i] * df$dlog_k_nr[i]
    }
  }
  if (idx0 > 1) {
    for (i in seq(idx0 - 1, 1)) {
      j <- i + 1
      logYp[i] <- logYp[j] - df$theta_active[j] * df$dlog_k_nr[j]
    }
  }

  df %>% mutate(log_y_p = logYp, y_p = exp(log_y_p), mu = exp(y - log_y_p), Y = exp(y))
}

struct_splice <- rescue_u_path(struct_splice, pinch_year = PINCH_YEAR) %>%
  mutate(
    ext_bind_flag_isi = if_else(year <= 1973 & ECT <= GAMMA_ISI, 1L,
                                if_else(year <= 1973 & ECT > GAMMA_ISI, 0L, NA_integer_)),
    ext_bind_state_isi = case_when(
      year > 1973 ~ NA_character_,
      ECT <= GAMMA_ISI ~ "bind",
      ECT > GAMMA_ISI  ~ "relaxed"
    ),
    ext_bind_distance_isi = case_when(
      year > 1973 ~ NA_real_,
      TRUE ~ (GAMMA_ISI - ECT) / abs(GAMMA_ISI)
    )
  )

# ============================================================
# 4. RESOLVE TRADE / PRICE INPUTS FOR UTILIZATION DECOMPOSITION
# ============================================================

price_candidates <- list(
  pY = c("pY", "Py", "pY_idx", "p_y"),
  pK = c("pK", "Pk", "pK_idx", "p_k"),
  pX = c("pX", "Px", "p_x"),
  pM = c("pM", "Pm", "p_m")
)

quantity_candidates <- list(
  X_q = c("X_q", "x_q", "XQ", "xq", "X_real", "x_real", "exports_real", "exports_volume", "x_vol", "Xvol", "exportaciones_real", "exportaciones_volumen", "exp_real", "expo_real", "export_q"),
  M_q = c("M_q", "m_q", "MQ", "mq", "M_real", "m_real", "imports_real", "imports_volume", "m_vol", "Mvol", "importaciones_real", "importaciones_volumen", "imp_real", "import_q"),
  X_nom = c("X", "x", "X_nom", "exports_nominal", "exports_current", "exports_value", "exportaciones", "exportaciones_nominales", "exp_nom", "exports"),
  M_nom = c("M", "m", "M_nom", "imports_nominal", "imports_current", "imports_value", "importaciones", "importaciones_nominales", "imp_nom", "imports")
)

col_pY <- resolve_col(profit_df, MANUAL_MAP$pY, price_candidates$pY, "pY")
col_pK <- resolve_col(profit_df, MANUAL_MAP$pK, price_candidates$pK, "pK")
col_pX <- resolve_col(profit_df, MANUAL_MAP$pX, price_candidates$pX, "pX")
col_pM <- resolve_col(profit_df, MANUAL_MAP$pM, price_candidates$pM, "pM")

# Try direct quantity columns first; if missing, fall back to nominal / price deflation.
resolve_optional <- function(df, manual_name, candidates) {
  nm <- names(df)
  if (!is.null(manual_name)) return(if (manual_name %in% nm) manual_name else NA_character_)
  hit <- candidates[candidates %in% nm]
  if (length(hit) > 0) return(hit[[1]])
  low_nm <- tolower(nm)
  low_cand <- tolower(candidates)
  idx <- match(low_cand, low_nm)
  idx <- idx[!is.na(idx)]
  if (length(idx) > 0) return(nm[idx[[1]]])
  NA_character_
}

trade_df <- profit_df
trade_source_label <- "profitability_rds"
trade_year_col <- resolve_year_col(trade_df, MANUAL_MAP$trade_year)
if (is.na(trade_year_col)) trade_year_col <- "year"

col_X_q  <- resolve_optional(trade_df, MANUAL_MAP$X_q, quantity_candidates$X_q)
col_M_q  <- resolve_optional(trade_df, MANUAL_MAP$M_q, quantity_candidates$M_q)
col_X_nom <- resolve_optional(trade_df, MANUAL_MAP$X_nom, quantity_candidates$X_nom)
col_M_nom <- resolve_optional(trade_df, MANUAL_MAP$M_nom, quantity_candidates$M_nom)

if ((is.na(col_X_q) && is.na(col_X_nom)) || (is.na(col_M_q) && is.na(col_M_nom))) {
  ext_try <- load_external_trade_source(path_trade_csv, path_trade_xlsx, MANUAL_MAP$trade_sheet)
  if (!is.null(ext_try$df)) {
    trade_df <- ext_try$df
    trade_source_label <- ext_try$source
    trade_year_col <- resolve_year_col(trade_df, MANUAL_MAP$trade_year)
    col_X_q  <- resolve_optional(trade_df, MANUAL_MAP$X_q, quantity_candidates$X_q)
    col_M_q  <- resolve_optional(trade_df, MANUAL_MAP$M_q, quantity_candidates$M_q)
    col_X_nom <- resolve_optional(trade_df, MANUAL_MAP$X_nom, quantity_candidates$X_nom)
    col_M_nom <- resolve_optional(trade_df, MANUAL_MAP$M_nom, quantity_candidates$M_nom)
  }
}

if (is.na(col_X_q) && is.na(col_X_nom)) {
  x_suggest <- suggest_cols(trade_df, "export|expo|exp|x_q|xq|xvol|exportac")
  stop(
    paste0(
      "Could not resolve exports quantity/value input. Set MANUAL_MAP$X_q or MANUAL_MAP$X_nom.
",
      "Trade source checked: ", trade_source_label, "
",
      "Possible export-like columns: ", paste(x_suggest, collapse = ", ")
    ),
    call. = FALSE
  )
}
if (is.na(col_M_q) && is.na(col_M_nom)) {
  m_suggest <- suggest_cols(trade_df, "import|imp|m_q|mq|mvol|importac")
  stop(
    paste0(
      "Could not resolve imports quantity/value input. Set MANUAL_MAP$M_q or MANUAL_MAP$M_nom.
",
      "Trade source checked: ", trade_source_label, "
",
      "Possible import-like columns: ", paste(m_suggest, collapse = ", ")
    ),
    call. = FALSE
  )
}

util_base <- profit_df %>%
  transmute(
    year,
    pY_raw = .data[[col_pY]],
    pK_raw = .data[[col_pK]],
    pX_raw = .data[[col_pX]],
    pM_raw = .data[[col_pM]],
    X_q_direct_raw = if (!is.na(col_X_q)) .data[[col_X_q]] else NA_real_,
    M_q_direct_raw = if (!is.na(col_M_q)) .data[[col_M_q]] else NA_real_,
    X_nom = if (!is.na(col_X_nom)) .data[[col_X_nom]] else NA_real_,
    M_nom = if (!is.na(col_M_nom)) .data[[col_M_nom]] else NA_real_
  ) %>%
  left_join(
    struct_splice %>%
      select(year, Y, y_p, mu, theta_active, ECT, ext_bind_flag_isi, ext_bind_state_isi, ext_bind_distance_isi, true_sample),
    by = "year"
  ) %>%
  filter(year >= analysis_year_min, year <= analysis_year_max) %>%
  arrange(year) %>%
  mutate(
    pY = rebase_index_to_year(pY_raw, year, 2010),
    pK = rebase_index_to_year(pK_raw, year, 2010),
    pX = rebase_index_to_year(pX_raw, year, 2010),
    pM = rebase_index_to_year(pM_raw, year, 2010),
    Y = rebase_real_with_index(Y, pY_raw, year, 2010),
    y_p = rebase_real_with_index(y_p, pY_raw, year, 2010),
    X_q = if_else(
      is.finite(X_q_direct_raw),
      rebase_real_with_index(X_q_direct_raw, pX_raw, year, 2010),
      deflate_nominal_to_real_2010(X_nom, pX_raw, year, 2010)
    ),
    M_q = if_else(
      is.finite(M_q_direct_raw),
      rebase_real_with_index(M_q_direct_raw, pM_raw, year, 2010),
      deflate_nominal_to_real_2010(M_nom, pM_raw, year, 2010)
    )
  )

required_stage_cols <- c("year", "pY", "pK", "pX", "pM", "X_q", "M_q", "Y", "y_p", "mu")
missing_stage_cols <- setdiff(required_stage_cols, names(util_base))
if (length(missing_stage_cols) > 0) {
  stop("Missing required utilization-stage columns: ", paste(missing_stage_cols, collapse = ", "), call. = FALSE)
}

# ============================================================
# 5. STAGE 1 — DOMESTIC VS EXTERNAL CORRIDOR
# ============================================================

annual_util_panel <- util_base %>%
  mutate(
    tau = pX / pM,
    TB_Y = (pX / pY) * X_q - (pM / pY) * M_q,
    mu_ext = TB_Y / y_p,
    mu_dom = mu - mu_ext,
    D_dom = mu_dom * y_p,
    p = pK / pY,
    p_zeta = pM / pK,
    q_zeta = pX / pK,
    ECG = q_zeta * X_q - p_zeta * M_q,
    mu_ext_check = p * ECG / y_p,
    mu_ext_gap = mu_ext - mu_ext_check,
    period = assign_collapsed_period(year)
  ) %>%
  mutate(
    d_mu_total = mu - lag(mu),
    d_mu_dom   = mu_dom - lag(mu_dom),
    d_mu_ext   = mu_ext - lag(mu_ext),
    mu_mid     = midpoint(mu),
    c_dom_mu   = d_mu_dom / mu_mid,
    c_ext_mu   = d_mu_ext / mu_mid,
    s_dom_mu   = safe_div(d_mu_dom, d_mu_total),
    s_ext_mu   = safe_div(d_mu_ext, d_mu_total)
  )

# ============================================================
# 6. STAGE 2 — OUTPUT-SPACE EXTERNAL CORRIDOR
# ============================================================

annual_util_panel <- annual_util_panel %>%
  mutate(
    stage2_a = pX / pY,
    stage2_b = (X_q - M_q / tau) / y_p,
    mu_ext_stage2 = stage2_a * stage2_b,
    stage2_gap = mu_ext - mu_ext_stage2,
    stage2_a_mid = midpoint(stage2_a),
    stage2_b_mid = midpoint(stage2_b),
    C_stage2_a = stage2_b_mid * (stage2_a - lag(stage2_a)),
    C_stage2_b = stage2_a_mid * (stage2_b - lag(stage2_b)),
    s_stage2_a_ext = safe_div(C_stage2_a, d_mu_ext),
    s_stage2_b_ext = safe_div(C_stage2_b, d_mu_ext),
    s_stage2_a_mu  = safe_div(C_stage2_a, d_mu_total),
    s_stage2_b_mu  = safe_div(C_stage2_b, d_mu_total)
  )

# ============================================================
# 7. STAGE 3 — ACCUMULATION-UNIT EXTERNAL CORRIDOR
# ============================================================

annual_util_panel <- annual_util_panel %>%
  mutate(
    stage3_alpha = p,
    stage3_beta  = ECG / y_p,
    mu_ext_stage3 = stage3_alpha * stage3_beta,
    stage3_gap = mu_ext - mu_ext_stage3,
    stage3_alpha_mid = midpoint(stage3_alpha),
    stage3_beta_mid  = midpoint(stage3_beta),
    C_stage3_p   = stage3_beta_mid * (stage3_alpha - lag(stage3_alpha)),
    C_stage3_ecg = stage3_alpha_mid * (stage3_beta - lag(stage3_beta)),
    s_stage3_p_ext   = safe_div(C_stage3_p, d_mu_ext),
    s_stage3_ecg_ext = safe_div(C_stage3_ecg, d_mu_ext),
    s_stage3_p_mu    = safe_div(C_stage3_p, d_mu_total),
    s_stage3_ecg_mu  = safe_div(C_stage3_ecg, d_mu_total)
  ) %>%
  mutate(
    qzX = q_zeta * X_q,
    pzM = p_zeta * M_q,
    d_ECG = ECG - lag(ECG),
    d_qzX = qzX - lag(qzX),
    d_pzM = pzM - lag(pzM),
    C_qzX = d_qzX,
    C_pzM = -d_pzM,
    s_qzX_ECG = safe_div(C_qzX, d_ECG),
    s_pzM_ECG = safe_div(C_pzM, d_ECG),
    s_qzX_ext = safe_div(stage3_alpha * C_qzX / midpoint(y_p), d_mu_ext),
    s_pzM_ext = safe_div(stage3_alpha * C_pzM / midpoint(y_p), d_mu_ext),
    s_qzX_mu  = safe_div(stage3_alpha * C_qzX / midpoint(y_p), d_mu_total),
    s_pzM_mu  = safe_div(stage3_alpha * C_pzM / midpoint(y_p), d_mu_total),
    q_zeta_mid = midpoint(q_zeta),
    X_q_mid    = midpoint(X_q),
    p_zeta_mid = midpoint(p_zeta),
    M_q_mid    = midpoint(M_q),
    C_qz_price = X_q_mid * (q_zeta - lag(q_zeta)),
    C_X_vol    = q_zeta_mid * (X_q - lag(X_q)),
    C_pz_price = -M_q_mid * (p_zeta - lag(p_zeta)),
    C_M_vol    = -p_zeta_mid * (M_q - lag(M_q)),
    s_qz_price_ECG = safe_div(C_qz_price, d_ECG),
    s_X_vol_ECG    = safe_div(C_X_vol, d_ECG),
    s_pz_price_ECG = safe_div(C_pz_price, d_ECG),
    s_M_vol_ECG    = safe_div(C_M_vol, d_ECG)
  )

# ============================================================
# 8. UTILIZATION STATES
# ============================================================

annual_util_panel <- annual_util_panel %>%
  mutate(
    mu_smooth = zoo::rollmean(mu, k = k_smooth, fill = NA, align = "center"),
    ln_mu = log(mu),
    ln_mu_smooth = log(mu_smooth),
    dln_mu = ln_mu - lag(ln_mu),
    dln_mu_3y = (dln_mu + lag(dln_mu, 1) + lag(dln_mu, 2)) / 3,
    mu_corridor_state = case_when(
      d_mu_total > 0 & d_mu_dom > 0 & d_mu_ext > 0 ~ "joint_support",
      d_mu_total > 0 & d_mu_dom > 0 & d_mu_ext < 0 ~ "domestic_offsetting_external_drag",
      d_mu_total > 0 & d_mu_dom < 0 & d_mu_ext > 0 ~ "external_offsetting_domestic_drag",
      d_mu_total < 0 & d_mu_dom < 0 & d_mu_ext < 0 ~ "joint_contraction",
      d_mu_total < 0 & d_mu_dom > 0 & d_mu_ext < 0 ~ "external_deterioration_dominant",
      d_mu_total < 0 & d_mu_dom < 0 & d_mu_ext > 0 ~ "domestic_deterioration_dominant",
      TRUE ~ "mixed_or_flat"
    ),
    mu_activation_state = case_when(
      is.na(theta_active) | is.na(dln_mu_3y) ~ NA_character_,
      theta_active > 1.05 & dln_mu_3y < 0 & ext_bind_flag_isi == 1 ~ "capacity_bias_activated_under_external_bind",
      theta_active > 1.05 & dln_mu_3y < 0 & ext_bind_flag_isi == 0 ~ "capacity_bias_activated_domestically_offset",
      theta_active > 1.05 & dln_mu_3y >= 0 ~ "capacity_bias_not_activated",
      theta_active < 0.95 & dln_mu_3y > 0 ~ "accumulation_pressure_activated",
      theta_active < 0.95 & dln_mu_3y <= 0 ~ "demand_pressure_bias_not_activated",
      TRUE ~ "balanced_corridor"
    )
  )

# ============================================================
# 9. UTILIZATION SWINGS FROM SMOOTHED MU LEVELS
# ============================================================

signal_tbl <- annual_util_panel %>% select(year, mu, mu_smooth, ln_mu, ln_mu_smooth)

tp_candidates_used <- find_tp_from_levels(signal_tbl, "mu_smooth") %>%
  compress_turning_points()

tp_final_pruned <- if (nrow(tp_candidates_used) > 0) {
  prune_turning_points_joint(
    tp = tp_candidates_used,
    df = signal_tbl,
    log_level_col = "ln_mu_smooth",
    min_years = min_years_between_tp,
    min_log_move = min_log_move
  ) %>% compress_turning_points()
} else {
  tp_candidates_used
}

tp_used <- if (nrow(tp_final_pruned) == 0) make_boundary_only_tp(signal_tbl, "mu") else tp_final_pruned
used_boundary_only <- nrow(tp_final_pruned) == 0

tp_bounds <- if (used_boundary_only) tp_used else add_boundaries_keep_rhs(tp_used, signal_tbl, "mu")

utilization_swings <- build_utilization_swings(tp_bounds, annual_util_panel)

# ============================================================
# 10. COLLAPSED-PERIOD SUMMARIES
# ============================================================

period_summary_panel <- annual_util_panel %>%
  filter(!is.na(period)) %>%
  group_by(period) %>%
  summarise(
    start_year = min(year),
    end_year   = max(year),
    mean_mu = safe_mean(mu),
    mean_mu_dom = safe_mean(mu_dom),
    mean_mu_ext = safe_mean(mu_ext),
    cum_d_mu_total = safe_sum(d_mu_total),
    cum_d_mu_dom = safe_sum(d_mu_dom),
    cum_d_mu_ext = safe_sum(d_mu_ext),
    mean_tau = safe_mean(tau),
    mean_p = safe_mean(p),
    mean_p_zeta = safe_mean(p_zeta),
    mean_q_zeta = safe_mean(q_zeta),
    mean_ECG = safe_mean(ECG),
    share_ext_bind_years_isi = safe_mean(ext_bind_flag_isi == 1),
    longest_ext_bind_run_isi = longest_run_true(ext_bind_flag_isi == 1),
    mu_corridor_profile = mode_chr(mu_corridor_state),
    mu_activation_profile = mode_chr(mu_activation_state),
    dominant_stage1_source = case_when(
      abs(cum_d_mu_dom) > abs(cum_d_mu_ext) ~ "domestic_corridor",
      abs(cum_d_mu_ext) > abs(cum_d_mu_dom) ~ "external_corridor",
      TRUE ~ "balanced_or_flat"
    ),
    dominant_stage2_source = case_when(
      abs(safe_sum(C_stage2_a)) > abs(safe_sum(C_stage2_b)) ~ "price_mapping_PX_over_PY",
      abs(safe_sum(C_stage2_b)) > abs(safe_sum(C_stage2_a)) ~ "external_command_X_minus_M_over_tau",
      TRUE ~ "balanced_or_flat"
    ),
    dominant_stage3_source = case_when(
      abs(safe_sum(C_qzX)) > abs(safe_sum(C_pzM)) ~ "export_command_accum_units",
      abs(safe_sum(C_pzM)) > abs(safe_sum(C_qzX)) ~ "import_burden_accum_units",
      TRUE ~ "balanced_or_flat"
    ),
    .groups = "drop"
  ) %>%
  left_join(collapsed_periods, by = c("period", "start_year", "end_year"))

# ============================================================
# 11. LONG TRACE TABLES
# ============================================================

stage1_trace_panel <- annual_util_panel %>%
  transmute(
    year, period, mu, mu_dom, mu_ext,
    d_mu_total, d_mu_dom, d_mu_ext,
    c_dom_mu, c_ext_mu, s_dom_mu, s_ext_mu,
    mu_corridor_state, mu_activation_state,
    theta_active, ext_bind_flag_isi, ext_bind_state_isi
  )

stage2_trace_panel <- annual_util_panel %>%
  transmute(
    year, period,
    mu_ext,
    stage2_a, stage2_b, mu_ext_stage2, stage2_gap,
    C_stage2_a, C_stage2_b,
    s_stage2_a_ext, s_stage2_b_ext,
    s_stage2_a_mu, s_stage2_b_mu,
    tau
  )

stage3_trace_panel <- annual_util_panel %>%
  transmute(
    year, period,
    mu_ext,
    p, p_zeta, q_zeta, ECG, mu_ext_stage3, stage3_gap,
    C_stage3_p, C_stage3_ecg,
    s_stage3_p_ext, s_stage3_ecg_ext,
    s_stage3_p_mu, s_stage3_ecg_mu,
    qzX, pzM, d_ECG,
    C_qzX, C_pzM,
    s_qzX_ECG, s_pzM_ECG,
    s_qzX_ext, s_pzM_ext,
    s_qzX_mu, s_pzM_mu,
    C_qz_price, C_X_vol, C_pz_price, C_M_vol,
    s_qz_price_ECG, s_X_vol_ECG, s_pz_price_ECG, s_M_vol_ECG
  )

crosswalk_year_util_period <- annual_util_panel %>%
  transmute(
    year,
    period,
    mu,
    mu_dom,
    mu_ext,
    mu_corridor_state,
    mu_activation_state,
    ext_bind_state_isi
  )

# ============================================================
# 12. EXPORTS
# ============================================================

write_csv(annual_util_panel, file.path(out_csv, "annual_utilization_panel.csv"))
write_csv(stage1_trace_panel, file.path(out_csv, "stage1_domestic_external_trace_panel.csv"))
write_csv(stage2_trace_panel, file.path(out_csv, "stage2_external_output_space_trace_panel.csv"))
write_csv(stage3_trace_panel, file.path(out_csv, "stage3_external_accumulation_units_trace_panel.csv"))
write_csv(utilization_swings, file.path(out_csv, "utilization_swings.csv"))
write_csv(period_summary_panel, file.path(out_csv, "period_utilization_summary_panel.csv"))
write_csv(crosswalk_year_util_period, file.path(out_csv, "crosswalk_year_util_period.csv"))
write_csv(tp_bounds, file.path(out_csv, "utilization_turning_points_bounds.csv"))

# ============================================================
# 13. FIGURES
# ============================================================

fig_mu_corridors <- annual_util_panel %>%
  ggplot(aes(x = year)) +
  geom_line(aes(y = mu, color = "mu"), linewidth = 0.9) +
  geom_line(aes(y = mu_dom, color = "mu_dom"), linewidth = 0.9, linetype = "dashed") +
  geom_line(aes(y = mu_ext, color = "mu_ext"), linewidth = 0.9, linetype = "dotdash") +
  geom_vline(xintercept = c(1946, 1949, 1955, 1961, 1969, 1972, 1974, 1976, 1978), linetype = "dotted", linewidth = 0.3) +
  scale_color_manual(values = c(mu = "black", mu_dom = "#0072B2", mu_ext = "#D55E00"), name = NULL) +
  labs(x = NULL, y = "Utilization corridor") +
  base_theme()

save_dual(fig_mu_corridors, "fig_mu_dom_ext_1940_1978")

fig_stage2 <- annual_util_panel %>%
  ggplot(aes(x = year)) +
  geom_line(aes(y = C_stage2_a, color = "P_X / P_Y mapping"), linewidth = 0.9) +
  geom_line(aes(y = C_stage2_b, color = "X - M / tau command"), linewidth = 0.9, linetype = "dashed") +
  scale_color_manual(values = c("P_X / P_Y mapping" = "black", "X - M / tau command" = "#009E73"), name = NULL) +
  labs(x = NULL, y = "Contribution to d mu_ext") +
  base_theme()

save_dual(fig_stage2, "fig_stage2_external_output_space_1940_1978")

fig_stage3 <- annual_util_panel %>%
  ggplot(aes(x = year)) +
  geom_line(aes(y = C_qzX, color = "Export command in accumulation units"), linewidth = 0.9) +
  geom_line(aes(y = C_pzM, color = "Import burden in accumulation units"), linewidth = 0.9, linetype = "dashed") +
  scale_color_manual(values = c(
    "Export command in accumulation units" = "black",
    "Import burden in accumulation units" = "#CC79A7"
  ), name = NULL) +
  labs(x = NULL, y = "Contribution to d ECG") +
  base_theme()

save_dual(fig_stage3, "fig_stage3_external_accum_units_1940_1978")

# ============================================================
# 14. SESSION SUMMARY
# ============================================================

summary_lines <- c(
  "Chile capacity-utilization diagnostic package completed.",
  "",
  "Structural lock:",
  paste0(" - Governing pre-1974 structural sample = ", GOV_SAMPLE_PRE1974),
  paste0(" - ISI threshold gamma = ", GAMMA_ISI),
  paste0(" - Pinch year for rescued utilization path = ", PINCH_YEAR),
  "",
  "Resolved source columns and 2010 enforcement:",
  paste0(" - pY raw = ", col_pY, " -> rebased to 2010"),
  paste0(" - pK raw = ", col_pK, " -> rebased to 2010"),
  paste0(" - pX raw = ", col_pX, " -> rebased to 2010"),
  paste0(" - pM raw = ", col_pM, " -> rebased to 2010"),
  paste0(" - X_q direct raw = ", ifelse(is.na(col_X_q), "<not used>", paste0(col_X_q, " -> converted to 2010 basis"))),
  paste0(" - M_q direct raw = ", ifelse(is.na(col_M_q), "<not used>", paste0(col_M_q, " -> converted to 2010 basis"))),
  paste0(" - X_nom raw = ", ifelse(is.na(col_X_nom), "<not used>", paste0(col_X_nom, " -> deflated with 2010-rebased pX"))),
  paste0(" - M_nom raw = ", ifelse(is.na(col_M_nom), "<not used>", paste0(col_M_nom, " -> deflated with 2010-rebased pM"))),
  " - Y and y_p converted to 2010 basis using pY provenance before decomposition.",
  "",
  "Core exports:",
  " - csv/annual_utilization_panel.csv",
  " - csv/stage1_domestic_external_trace_panel.csv",
  " - csv/stage2_external_output_space_trace_panel.csv",
  " - csv/stage3_external_accumulation_units_trace_panel.csv",
  " - csv/utilization_swings.csv",
  " - csv/period_utilization_summary_panel.csv",
  " - csv/crosswalk_year_util_period.csv",
  " - csv/utilization_turning_points_bounds.csv",
  "",
  "Figures:",
  " - figs/fig_mu_dom_ext_1940_1978.(png/pdf)",
  " - figs/fig_stage2_external_output_space_1940_1978.(png/pdf)",
  " - figs/fig_stage3_external_accum_units_1940_1978.(png/pdf)",
  "",
  "Protocol notes:",
  " - Stage 1: d mu = d mu_dom + d mu_ext.",
  " - Stage 2: mu_ext = (P_X / P_Y) * (X - M / tau) / Y^p.",
  " - Stage 3: mu_ext = p * (q_zeta X - p_zeta M) / Y^p.",
  " - p_zeta = P_M / P_K is the import burden in accumulation units.",
  " - q_zeta = P_X / P_K is the export command in accumulation units."
)

write_txt(summary_lines, file.path(out_txt, "capacity_utilization_diagnostic_summary.txt"))
cat(paste(summary_lines, collapse = "\n"), "\n")
