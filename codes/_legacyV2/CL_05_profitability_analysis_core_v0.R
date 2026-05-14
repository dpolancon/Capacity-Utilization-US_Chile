###############################################################################
# CHILE — Profitability analysis core
# Analytical engine only
#
# Purpose:
# - Ingest structurally filtered Chile objects from Stage 1 / Stage 2 results
# - Build structural profitability and diagnostic profitability
# - Build yearly decomposition and updated dysfunctionality indices
# - Identify profit swings
# - Build recapitalization and wedge layers
# - Save canonical analytical objects as .rds
###############################################################################

# ── 0. Packages ──────────────────────────────────────────────────────────────
pkgs <- c("dplyr", "readr", "readxl", "tibble", "tidyr", "janitor", "zoo")
miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss) > 0) install.packages(miss, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

# ── 1. Paths ─────────────────────────────────────────────────────────────────
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_root  <- file.path(proj_root, "output", "profitability_chile")
rds_dir   <- file.path(out_root, "rds")
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)

path_stage1_master <- file.path(proj_root, "output", "chile_2Smu_S1", "txt", "stage1__master_results.rds")
path_stage2_root   <- file.path(proj_root, "output", "chile_2Smu_S2_tdols")
path_stage2_panel  <- file.path(path_stage2_root, "csv", "stage2__working_panel.csv")
path_theta_isi     <- file.path(path_stage2_root, "csv", "threshold_theta__isi1931_1973.csv")
path_theta_post    <- file.path(path_stage2_root, "csv", "threshold_theta__post1974.csv")

path_capital_raw   <- file.path(proj_root, "data", "raw", "Chile", "harmonized_series_2003CLP_1900_2024.csv")
path_demand_raw    <- file.path(proj_root, "data", "raw", "Chile", "PerezEyzaguirre_DemandaAgregada.xlsx")
path_prices_raw    <- file.path(proj_root, "data", "raw", "Chile", "W04_Precios_ClioLabPUC.xlsx")

analysis_year_min <- 1940L
analysis_year_max <- 1978L
pinch_year <- 1980L

# ── 2. Helpers ───────────────────────────────────────────────────────────────
stop_missing <- function(path) {
  if (!file.exists(path)) stop("Required file not found: ", path, call. = FALSE)
}

read_any <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") return(readr::read_csv(path, show_col_types = FALSE))
  if (ext == "rds") return(readRDS(path))
  stop("Unsupported extension for: ", path, call. = FALSE)
}

find_first_present <- function(df, candidates, what) {
  hit <- intersect(candidates, names(df))
  if (length(hit) == 0) stop("Could not identify ", what, ". Candidates checked: ", paste(candidates, collapse = ", "), call. = FALSE)
  hit[1]
}

rename_first <- function(df, candidates, new_name, what = new_name) {
  old <- find_first_present(df, candidates, what)
  dplyr::rename(df, !!new_name := !!rlang::sym(old))
}

extract_stage1_ect <- function(stage1_master, sample, spec = "S1_B", lag = 1, rank = 1) {
  out <- stage1_master$ect_series |>
    dplyr::filter(sample == !!sample, spec == !!spec, lag == !!lag, rank == !!rank) |>
    dplyr::arrange(year) |>
    dplyr::select(year, ECT)
  if (nrow(out) == 0) {
    stop("No Stage 1 ECT found for sample=", sample, ", spec=", spec, ", lag=", lag, ", rank=", rank, call. = FALSE)
  }
  out
}

rescue_u_path <- function(df, pinch_year = 1980L) {
  df <- df |> dplyr::arrange(year)
  idx0 <- which(df$year == pinch_year)
  if (length(idx0) != 1L) stop("Pinch year not found uniquely in splice panel.", call. = FALSE)
  
  logYp <- rep(NA_real_, nrow(df))
  logYp[idx0] <- df$y[idx0]
  
  if (idx0 < nrow(df)) {
    for (i in (idx0 + 1):nrow(df)) {
      if (!is.finite(df$dlog_k_nr[i]) || !is.finite(df$theta_active[i])) {
        stop("Missing dlog_k_nr or theta_active in forward recursion at year ", df$year[i], call. = FALSE)
      }
      logYp[i] <- logYp[i - 1] + df$theta_active[i] * df$dlog_k_nr[i]
    }
  }
  
  if (idx0 > 1) {
    for (i in seq(idx0 - 1, 1)) {
      j <- i + 1
      if (!is.finite(df$dlog_k_nr[j]) || !is.finite(df$theta_active[j])) {
        stop("Missing dlog_k_nr or theta_active in backward recursion at year ", df$year[j], call. = FALSE)
      }
      logYp[i] <- logYp[j] - df$theta_active[j] * df$dlog_k_nr[j]
    }
  }
  
  df |>
    dplyr::mutate(
      log_y_p = logYp,
      y_p = exp(log_y_p),
      mu_t = exp(y - log_y_p)
    )
}

# Clean to sign(x) with tolerance
sign_eps <- function(x, eps = 1e-10) ifelse(abs(x) <= eps | is.na(x), 0, ifelse(x > 0, 1L, -1L))

# Turning points copied/adapted from U.S. core
find_turning_points_direction <- function(year, x, k = 3) {
  dx <- x - dplyr::lag(x)
  dx_ma <- zoo::rollmean(dx, k = k, fill = NA, align = "center")
  out <- vector("list", 0)
  for (i in 2:(length(dx_ma) - 1)) {
    if (is.na(dx_ma[i - 1]) || is.na(dx_ma[i])) next
    if (dx_ma[i - 1] > 0 && dx_ma[i] < 0) {
      out[[length(out) + 1]] <- tibble::tibble(idx = i, year = year[i], value = x[i], type = "peak")
    } else if (dx_ma[i - 1] < 0 && dx_ma[i] > 0) {
      out[[length(out) + 1]] <- tibble::tibble(idx = i, year = year[i], value = x[i], type = "trough")
    }
  }
  if (length(out) == 0) return(tibble::tibble(idx = integer(), year = integer(), value = numeric(), type = character()))
  dplyr::bind_rows(out) |> dplyr::arrange(idx)
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
  dplyr::bind_rows(keep) |> dplyr::arrange(idx)
}

prune_turning_points <- function(tp, x, min_move = 0.10, min_years = 3) {
  if (nrow(tp) <= 1) return(tp)
  out <- tp
  repeat {
    if (nrow(out) <= 1) break
    amp <- abs(diff(x[out$idx]))
    dur <- diff(out$year)
    weak <- which(amp < min_move | dur < min_years)
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
      move_drop_left  <- abs(x[b_idx] - x[left_idx])
      move_drop_right <- abs(x[right_idx] - x[a_idx])
      if (move_drop_left >= move_drop_right) out <- out[-k, , drop = FALSE] else out <- out[-(k + 1), , drop = FALSE]
    }
    out <- compress_turning_points(out)
  }
  out
}

prune_turning_points_windowed <- function(tp, data, xvar,
                                          break_year = 1946,
                                          min_move_early = 0.08,
                                          min_years_early = 2,
                                          min_move_late = 0.10,
                                          min_years_late = 3) {
  tp_early <- tp |> dplyr::filter(year <= break_year)
  tp_late  <- tp |> dplyr::filter(year >= break_year)
  tp_early_pruned <- if (nrow(tp_early) > 0) tp_early |> compress_turning_points() |> prune_turning_points(x = data[[xvar]], min_move = min_move_early, min_years = min_years_early) else tp_early
  tp_late_pruned  <- if (nrow(tp_late)  > 0) tp_late  |> compress_turning_points() |> prune_turning_points(x = data[[xvar]], min_move = min_move_late,  min_years = min_years_late)  else tp_late
  dplyr::bind_rows(tp_early_pruned, tp_late_pruned) |>
    dplyr::distinct(idx, .keep_all = TRUE) |>
    dplyr::arrange(idx) |>
    compress_turning_points()
}

add_boundaries <- function(tp, data, xvar) {
  if (nrow(tp) == 0) stop("No internal turning points detected.", call. = FALSE)
  first_type <- if (tp$type[1] == "peak") "trough" else "peak"
  last_type  <- if (tp$type[nrow(tp)] == "peak") "trough" else "peak"
  start_row <- tibble::tibble(idx = 1, year = data$year[1], value = data[[xvar]][1], type = first_type)
  end_row   <- tibble::tibble(idx = nrow(data), year = data$year[nrow(data)], value = data[[xvar]][nrow(data)], type = last_type)
  dplyr::bind_rows(start_row, tp, end_row) |> dplyr::arrange(idx) |> compress_turning_points()
}

drop_weak_terminal_swing <- function(tp, data, xvar, min_years = 3, min_move = 0.02) {
  if (nrow(tp) < 2) return(tp)
  dur_last <- tp$year[nrow(tp)] - tp$year[nrow(tp) - 1]
  amp_last <- abs(data[[xvar]][tp$idx[nrow(tp)]] - data[[xvar]][tp$idx[nrow(tp) - 1]])
  if (dur_last < min_years && amp_last < min_move) tp <- tp[-nrow(tp), , drop = FALSE]
  tp
}

build_swing_table <- function(tp, data) {
  if (nrow(tp) < 2) return(tibble::tibble())
  out <- vector("list", nrow(tp) - 1)
  for (i in 1:(nrow(tp) - 1)) {
    start_idx <- tp$idx[i]; end_idx <- tp$idx[i + 1]
    start_year <- tp$year[i]; end_year <- tp$year[i + 1]
    dur <- end_year - start_year
    start_r_diag <- data$r_diag_t[start_idx]
    end_r_diag   <- data$r_diag_t[end_idx]
    start_ln_struct <- data$ln_r_struct_t[start_idx]
    end_ln_struct   <- data$ln_r_struct_t[end_idx]
    amp_log_struct  <- end_ln_struct - start_ln_struct
    out[[i]] <- tibble::tibble(
      swing_id = i,
      start_year = start_year,
      end_year = end_year,
      direction = paste0(tp$type[i], "_to_", tp$type[i + 1]),
      duration_years = dur,
      start_r_diag = start_r_diag,
      end_r_diag = end_r_diag,
      amplitude_pct_diag = 100 * (end_r_diag / start_r_diag - 1),
      pace_pct_diag_per_year = ifelse(dur > 0, 100 * ((end_r_diag / start_r_diag)^(1 / dur) - 1), NA_real_),
      amplitude_log_struct = amp_log_struct,
      pace_log_struct_per_year = ifelse(dur > 0, amp_log_struct / dur, NA_real_)
    )
  }
  dplyr::bind_rows(out)
}

add_swing_decomposition <- function(swing_tbl, tp, data) {
  out <- swing_tbl
  comps <- c("dist", "util", "price", "capacity", "wedge")
  for (nm in comps) out[[paste0(nm, "_log")]] <- NA_real_
  out$total_log_check <- NA_real_
  for (nm in comps) out[[paste0(nm, "_share_pct")]] <- NA_real_
  out$share_sum_pct <- NA_real_
  for (i in seq_len(nrow(out))) {
    start_idx <- tp$idx[i]; end_idx <- tp$idx[i + 1]
    d_pi <- data$ln_pi_t[end_idx] - data$ln_pi_t[start_idx]
    d_mu <- data$ln_mu_t[end_idx] - data$ln_mu_t[start_idx]
    d_p  <- data$ln_p_t[end_idx]  - data$ln_p_t[start_idx]
    d_B  <- data$ln_B_t[end_idx]  - data$ln_B_t[start_idx]
    d_nu <- data$ln_nu_t[end_idx] - data$ln_nu_t[start_idx]
    d_r  <- out$amplitude_log_struct[i]
    vals <- c(dist = d_pi, util = d_mu, price = d_p, capacity = d_B, wedge = d_nu)
    for (nm in names(vals)) out[[paste0(nm, "_log")]][i] <- vals[[nm]]
    out$total_log_check[i] <- sum(vals)
    if (!is.na(d_r) && abs(d_r) > 1e-10) {
      for (nm in names(vals)) out[[paste0(nm, "_share_pct")]][i] <- 100 * vals[[nm]] / d_r
      out$share_sum_pct[i] <- 100 * sum(vals) / d_r
    }
  }
  out
}

build_yearly_indices <- function(data, eps = 1e-10) {
  out <- data |>
    dplyr::transmute(
      year,
      d_pi = ln_pi_t - dplyr::lag(ln_pi_t),
      d_mu = ln_mu_t - dplyr::lag(ln_mu_t),
      d_p  = ln_p_t  - dplyr::lag(ln_p_t),
      d_B  = ln_B_t  - dplyr::lag(ln_B_t),
      d_nu = ln_nu_t - dplyr::lag(ln_nu_t),
      r_diag_t,
      r_struct_t,
      mu_t,
      theta_t,
      nu_level = nu_t - 1,
      chi_t,
      g_K_t,
      accounting_wedge_t
    ) |>
    dplyr::mutate(
      G_t = abs(d_pi) + abs(d_mu) + abs(d_p) + abs(d_B) + abs(d_nu),
      N_t = d_pi + d_mu + d_p + d_B + d_nu,
      D_t = dplyr::if_else(!is.na(G_t) & G_t > eps, 1 - abs(N_t) / G_t, NA_real_)
    )
  
  comp_mat <- as.matrix(out[, c("d_pi", "d_mu", "d_p", "d_B", "d_nu")])
  O_t <- rep(NA_real_, nrow(out))
  for (i in seq_len(nrow(out))) {
    Ni <- out$N_t[i]
    if (is.na(Ni)) next
    sgn <- sign_eps(Ni, eps = eps)
    if (sgn == 0L) {
      O_t[i] <- sum(abs(comp_mat[i, ]), na.rm = TRUE)
    } else {
      signs <- sign_eps(comp_mat[i, ], eps = eps)
      O_t[i] <- sum(abs(comp_mat[i, signs == -sgn]), na.rm = TRUE)
    }
  }
  out |>
    dplyr::mutate(
      O_t = O_t,
      S_off_t = dplyr::if_else(!is.na(G_t) & G_t > eps, O_t / G_t, NA_real_),
      F_rev_t = dplyr::if_else(!is.na(O_t) & !is.na(N_t) & (O_t + abs(N_t)) > eps, O_t / (O_t + abs(N_t)), NA_real_)
    )
}

add_swing_indices <- function(swing_tbl, eps = 1e-10) {
  out <- swing_tbl
  out$G_swing <- NA_real_
  out$N_swing <- NA_real_
  out$D_swing <- NA_real_
  out$O_swing <- NA_real_
  out$S_off_swing <- NA_real_
  out$F_rev_swing <- NA_real_
  comp_cols <- c("dist_log", "util_log", "price_log", "capacity_log", "wedge_log")
  for (i in seq_len(nrow(out))) {
    comps <- as.numeric(out[i, comp_cols])
    G <- sum(abs(comps), na.rm = TRUE)
    N <- sum(comps, na.rm = TRUE)
    sgn <- sign_eps(N, eps = eps)
    if (sgn == 0L) O <- G else O <- sum(abs(comps[sign_eps(comps, eps = eps) == -sgn]), na.rm = TRUE)
    out$G_swing[i] <- G
    out$N_swing[i] <- N
    out$D_swing[i] <- ifelse(G > eps, 1 - abs(N) / G, NA_real_)
    out$O_swing[i] <- O
    out$S_off_swing[i] <- ifelse(G > eps, O / G, NA_real_)
    out$F_rev_swing[i] <- ifelse((O + abs(N)) > eps, O / (O + abs(N)), NA_real_)
  }
  out
}

assign_swing_ids_to_years <- function(year_tbl, swing_tbl) {
  year_tbl <- year_tbl |> dplyr::mutate(swing_id = NA_integer_)
  for (j in seq_len(nrow(swing_tbl))) {
    y0 <- swing_tbl$start_year[j]; y1 <- swing_tbl$end_year[j]
    idx <- if (j < nrow(swing_tbl)) which(year_tbl$year >= y0 & year_tbl$year < y1) else which(year_tbl$year >= y0 & year_tbl$year <= y1)
    year_tbl$swing_id[idx] <- swing_tbl$swing_id[j]
  }
  year_tbl
}

# ── 3. Load and splice structural objects ────────────────────────────────────
stop_missing(path_stage1_master)
stop_missing(path_stage2_panel)
stop_missing(path_theta_isi)
stop_missing(path_theta_post)
stop_missing(path_capital_raw)
stop_missing(path_prices_raw)

stage1_master <- readRDS(path_stage1_master)
panel_stage2  <- readr::read_csv(path_stage2_panel, show_col_types = FALSE)
theta_isi     <- readr::read_csv(path_theta_isi, show_col_types = FALSE)
theta_post    <- readr::read_csv(path_theta_post, show_col_types = FALSE)

# Stage 1 ECT
ect_isi  <- extract_stage1_ect(stage1_master, "ISI1931_1973")
ect_post <- extract_stage1_ect(stage1_master, "POST1974")


core <- panel_stage2 |>
  dplyr::select(year, y, k_nr, wsh) |>
  dplyr::filter(year >= 1932, year <= 2010)

isi_part <- theta_isi |>
  dplyr::select(year, regime_code, theta_r1, theta_r2, theta_active) |>
  dplyr::left_join(ect_isi, by = "year") |>
  dplyr::mutate(true_sample = "ISI1931_1973")

post_part <- theta_post |>
  dplyr::select(year, regime_code, theta_r1, theta_r2, theta_active) |>
  dplyr::left_join(ect_post, by = "year") |>
  dplyr::mutate(true_sample = "POST1974")

ts_splice <- dplyr::bind_rows(isi_part, post_part) |>
  dplyr::filter(year >= 1932, year <= 2010) |>
  dplyr::arrange(year) |>
  dplyr::left_join(core, by = "year") |>
  dplyr::mutate(
    regime_code = factor(regime_code, levels = c("low_ect_side", "high_ect_side")),
    dlog_k_nr = c(NA_real_, diff(k_nr))
  )

if (any(!is.finite(ts_splice$theta_active))) stop("Spliced panel has missing theta_active values.", call. = FALSE)
ts_splice <- rescue_u_path(ts_splice, pinch_year = pinch_year)

# ── 4. Load Chile panel / raw sources ────────────────────────────────────────
# c2_panel_chile: try stage2 panel first, then user-facing aliases if they exist
c2_panel <- panel_stage2 |> janitor::clean_names()
# Harmonize expected names where possible
if ("wsh" %in% names(c2_panel) && !("omega" %in% names(c2_panel))) c2_panel$omega <- c2_panel$wsh
if (!("pi" %in% names(c2_panel)) && "wsh" %in% names(c2_panel)) c2_panel$pi <- 1 - c2_panel$wsh
if (!("i_total" %in% names(c2_panel)) && "i_total" %in% names(c2_panel)) c2_panel$i_total <- c2_panel$i_total

# Demand raw (optional, only used if key flow columns are missing)
demand_raw <- tryCatch(readxl::read_excel(path_demand_raw) |> janitor::clean_names(), error = function(e) NULL)

# Price raw
prices_raw <- readxl::read_excel(
  path_prices_raw,
  sheet = "4.1.3",
  skip = 9
) |>
  janitor::clean_names() |>
  dplyr::rename(
    year = code,
    pY   = defpgb,
    pC   = defc,
    pG   = defg,
    pK   = deffbkb,
    pX   = defx,
    pM   = defm
  ) |>
  dplyr::select(year, pY, pC, pG, pK, pX, pM)

tti_raw <- readxl::read_excel(
  path_prices_raw,
  sheet = "4.3.2",
  skip = 9
) |>
  janitor::clean_names() |>
  dplyr::rename(
    year = code,
    pTI  = termint
  ) |>
  dplyr::select(year, pTI)

wp_raw <- readxl::read_excel(
  path_prices_raw,
  sheet = "4.4.1",
  skip = 9
) |>
  janitor::clean_names() |>
  dplyr::rename(
    year = code,
    wp   = iwr
  ) |>
  dplyr::select(year, wp)

cpi_raw <- readxl::read_excel(
  path_prices_raw,
  sheet = "4.1.1",
  skip = 9
) |>
  janitor::clean_names() |>
  dplyr::rename(
    year = code,
    pCPI = ipc
  ) |>
  dplyr::select(year, pCPI)

prices_raw <- prices_raw |>
  dplyr::left_join(tti_raw, by = "year") |>
  dplyr::left_join(wp_raw, by = "year") |>
  dplyr::left_join(cpi_raw, by = "year") |>
  dplyr::filter(year >= 1940, year <= analysis_year_max)


# ── 4B. Price table already cleaned and renamed upstream ─────────────────────
# Expected upstream objects after the corrected price-import block:
# prices_raw with columns:
# year, pY, pC, pG, pK, pX, pM, pTI, wp, pCPI
#
# Keep only what is needed here.

required_price_cols <- c("year", "pY", "pK")
miss_price_cols <- required_price_cols[!required_price_cols %in% names(prices_raw)]
if (length(miss_price_cols) > 0) {
  stop(
    "prices_raw is missing required columns: ",
    paste(miss_price_cols, collapse = ", "),
    call. = FALSE
  )
}

price_tbl <- prices_raw |>
  dplyr::select(dplyr::any_of(c("year", "pY", "pC", "pG", "pK", "pX", "pM", "pTI", "wp", "pCPI"))) |>
  dplyr::filter(year >= analysis_year_min, year <= analysis_year_max)

# Capital raw: optional aid for net/gross mapping if stage2 panel lacks one side
capital_raw <- readr::read_csv(path_capital_raw, show_col_types = FALSE) |>
  janitor::clean_names()

# ── 5. Build merged Chile profitability panel ────────────────────────────────
# Base structurally filtered panel
base <- ts_splice |>
  dplyr::select(year, true_sample, regime_code, ect = ECT, theta_t = theta_active, y, y_p, mu_t, k_nr, wsh) |>
  dplyr::rename(omega_t = wsh)

# Start with c2 panel for accounting-compatible variables
acc <- c2_panel |>
  dplyr::select(dplyr::any_of(c(
    "year",
    "pi", "omega", "exploitation_rate",
    "gdp_real",
    "k_nr", "k_me", "k_total",
    "fbkf_me", "fbkf_nr", "i_total", "m_cif",
    "k_nr_gross", "k_total_gross", "k_gross",
    "k_net", "k_nr_net", "k_total_net"
  )))

# Flexible gross/net stock mapping
if (!("k_gross" %in% names(acc))) {
  gross_hit <- intersect(c("k_total_gross", "k_nr_gross", "k_total", "k_nr"), names(acc))
  if (length(gross_hit) > 0) {
    acc <- dplyr::rename(acc, k_gross = !!rlang::sym(gross_hit[1]))
  }
}

if (!("k_net" %in% names(acc))) {
  net_hit <- intersect(c("k_total_net", "k_nr_net"), names(acc))
  if (length(net_hit) > 0) {
    acc <- dplyr::rename(acc, k_net = !!rlang::sym(net_hit[1]))
  } else if ("asset" %in% names(capital_raw) && "kn" %in% names(capital_raw)) {
    cap_net <- capital_raw |>
      dplyr::filter(.data$asset %in% c("Total", "NR", "K_Total", "K_NR")) |>
      dplyr::group_by(year) |>
      dplyr::summarise(k_net = dplyr::first(kn), .groups = "drop")
    acc <- acc |>
      dplyr::left_join(cap_net, by = "year")
  }
}

# If gross stock absent in acc, try from raw capital file using kg
if (!("k_gross" %in% names(acc)) || all(is.na(acc$k_gross))) {
  if ("asset" %in% names(capital_raw) && "kg" %in% names(capital_raw)) {
    cap_gross <- capital_raw |>
      dplyr::filter(.data$asset %in% c("Total", "NR", "K_Total", "K_NR")) |>
      dplyr::group_by(year) |>
      dplyr::summarise(k_gross = dplyr::first(kg), .groups = "drop")
    acc <- acc |>
      dplyr::left_join(cap_gross, by = "year")
  }
}

# Attach demand fallback if I_total or GDP_real missing
if (!is.null(demand_raw)) {
  if (!("i_total" %in% names(acc))) {
    demand_i <- demand_raw |>
      rename_first(c("x1", "year", "anio", "ano"), "year", "demand year")
    it_col <- intersect(c("inversion_interna_bruta", "i_total", "fbkf_total"), names(demand_i))
    if (length(it_col) > 0) {
      acc <- acc |>
        dplyr::left_join(
          demand_i |>
            dplyr::select(year, i_total = !!rlang::sym(it_col[1])),
          by = "year"
        )
    }
  }
  
  if (!("gdp_real" %in% names(acc))) {
    demand_y <- demand_raw |>
      rename_first(c("x1", "year", "anio", "ano"), "year", "demand year")
    y_col <- intersect(c("pib_real_milllones_de_pesos_de_2003", "gdp_real", "y_real"), names(demand_y))
    if (length(y_col) > 0) {
      acc <- acc |>
        dplyr::left_join(
          demand_y |>
            dplyr::select(year, gdp_real = !!rlang::sym(y_col[1])),
          by = "year"
        )
    }
  }
}

# Merge and restrict descriptive window
d <- base |>
  dplyr::left_join(acc, by = "year") |>
  dplyr::left_join(price_tbl, by = "year") |>
  dplyr::filter(year >= analysis_year_min, year <= analysis_year_max) |>
  dplyr::mutate(
    # Core distributive variable
    pi_t = dplyr::coalesce(pi, 1 - omega_t),
    
    # Real output references
    GDP_real = dplyr::coalesce(gdp_real, exp(y)),
    Y_real   = exp(y),
    Yp_hat   = y_p,
    
    # Capital stocks
    KGC = k_gross,
    KNC = k_net,
    
    # Deflator scaling: all indices are 2003 = 100
    pY_idx = pY,
    pK_idx = pK,
    pY_sc  = pY / 100,
    pK_sc  = pK / 100,
    
    # Reprice core flows consistently into contemporaneous-price terms
    GOS = pi_t * GDP_real * pY_sc,
    IGC = i_total * pK_sc
  )

required_now <- c(
  "year", "pi_t", "mu_t", "pY", "pK", "Yp_hat",
  "KGC", "KNC", "GOS", "IGC", "theta_t"
)

miss_now <- required_now[
  !required_now %in% names(d) |
    vapply(required_now, function(nm) all(is.na(d[[nm]])), logical(1))
]

if (length(miss_now) > 0) {
  stop(
    "Missing or unresolved Chile profitability inputs: ",
    paste(miss_now, collapse = ", "),
    call. = FALSE
  )
}

# Additional admissibility checks
if (any(d$pi_t <= 0, na.rm = TRUE)) stop("pi_t has non-positive values.", call. = FALSE)
if (any(d$mu_t <= 0, na.rm = TRUE)) stop("mu_t has non-positive values.", call. = FALSE)
if (any(d$pY <= 0, na.rm = TRUE)) stop("pY has non-positive values.", call. = FALSE)
if (any(d$pK <= 0, na.rm = TRUE)) stop("pK has non-positive values.", call. = FALSE)
if (any(d$KGC <= 0, na.rm = TRUE)) stop("KGC has non-positive values.", call. = FALSE)
if (any(d$KNC <= 0, na.rm = TRUE)) stop("KNC has non-positive values.", call. = FALSE)

# ── 6. Build structural profitability objects ────────────────────────────────
d <- d |>
  dplyr::arrange(year) |>
  dplyr::mutate(
    # Relative-price corridor: base year cancels in the ratio
    p_t = pY / pK,
    
    # Productive-capacity term
    B_t = Yp_hat / KGC,
    
    # Gross-to-net wedge
    nu_t = KGC / KNC,
    
    # Structural profitability
    r_struct_t    = pi_t * mu_t * p_t * B_t * nu_t,
    ln_r_struct_t = log(r_struct_t),
    
    # Diagnostic profitability
    r_diag_t    = GOS / KNC,
    ln_r_diag_t = log(r_diag_t),
    
    # Log components
    ln_pi_t = log(pi_t),
    ln_mu_t = log(mu_t),
    ln_p_t  = log(p_t),
    ln_B_t  = log(B_t),
    ln_nu_t = log(nu_t),
    
    # Capital growth
    ln_KNC_t = log(KNC),
    g_K_t    = ln_KNC_t - dplyr::lag(ln_KNC_t),
    
    # Reproductive closure: now dimensionally coherent
    chi_t = dplyr::if_else(!is.na(GOS) & abs(GOS) > 1e-8, IGC / GOS, NA_real_),
    
    # Diagnostic wedge
    accounting_wedge_t =
      dplyr::if_else(!is.na(r_diag_t) & abs(r_diag_t) > 1e-8, r_struct_t / r_diag_t, NA_real_)
  )

# Final admissibility checks after profitability construction
required_profitability <- c("r_struct_t", "r_diag_t", "p_t", "B_t", "nu_t", "chi_t")
miss_profitability <- required_profitability[
  !required_profitability %in% names(d) |
    vapply(required_profitability, function(nm) all(is.na(d[[nm]])), logical(1))
]

if (length(miss_profitability) > 0) {
  stop(
    "Profitability construction failed for: ",
    paste(miss_profitability, collapse = ", "),
    call. = FALSE
  )
}

if (any(d$r_struct_t <= 0, na.rm = TRUE)) stop("r_struct_t has non-positive values.", call. = FALSE)
if (any(d$r_diag_t <= 0, na.rm = TRUE)) stop("r_diag_t has non-positive values.", call. = FALSE)
if (any(d$nu_t < 1, na.rm = TRUE)) warning("nu_t < 1 detected; inspect gross/net stock consistency.", call. = FALSE)

# ── 7. Turning points and profit swings ──────────────────────────────────────
tp_raw <- find_turning_points_direction(d$year, d$ln_r_struct_t, k = 3)

tp_env <- prune_turning_points_windowed(
  tp = tp_raw,
  data = d,
  xvar = "ln_r_diag_t",
  break_year = 1946,
  min_move_early = 0.08,
  min_years_early = 2,
  min_move_late = 0.10,
  min_years_late = 3
)

tp_env_final <- add_boundaries(tp_env, d, "ln_r_diag_t") |>
  drop_weak_terminal_swing(data = d, xvar = "ln_r_diag_t", min_years = 3, min_move = 0.02)

swing_tbl <- build_swing_table(tp_env_final, d) |>
  add_swing_decomposition(tp_env_final, d) |>
  add_swing_indices()

# ── 8. Yearly and swing recap/wedge objects ──────────────────────────────────
year_tbl_dys <- build_yearly_indices(d) |>
  assign_swing_ids_to_years(swing_tbl)

year_tbl_recap <- d |>
  dplyr::transmute(
    year,
    r_diag_t,
    g_K_t,
    chi_t,
    accounting_wedge_t,
    nu_level = nu_t - 1
  ) |>
  assign_swing_ids_to_years(swing_tbl)

swing_tbl_recap <- year_tbl_recap |>
  dplyr::group_by(swing_id) |>
  dplyr::summarise(
    avg_r_diag = mean(r_diag_t, na.rm = TRUE),
    avg_g_K = mean(g_K_t, na.rm = TRUE),
    avg_chi = mean(chi_t, na.rm = TRUE),
    chi_start = dplyr::first(stats::na.omit(chi_t)),
    chi_end   = dplyr::last(stats::na.omit(chi_t)),
    avg_accounting_wedge = mean(accounting_wedge_t, na.rm = TRUE),
    wedge_start = dplyr::first(stats::na.omit(accounting_wedge_t)),
    wedge_end   = dplyr::last(stats::na.omit(accounting_wedge_t)),
    avg_nu_level = mean(nu_level, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    delta_chi = chi_end - chi_start,
    delta_accounting_wedge = wedge_end - wedge_start
  )

swing_tbl_full <- swing_tbl |>
  dplyr::left_join(swing_tbl_recap, by = "swing_id")

# ── 9. Compact outputs ───────────────────────────────────────────────────────
swing_tbl_compact <- swing_tbl_full |>
  dplyr::transmute(
    swing_id, start_year, end_year, direction, duration_years,
    amplitude_pct_diag = round(amplitude_pct_diag, 1),
    amplitude_log_struct = round(amplitude_log_struct, 3),
    dist_share_pct = round(dist_share_pct, 1),
    util_share_pct = round(util_share_pct, 1),
    price_share_pct = round(price_share_pct, 1),
    capacity_share_pct = round(capacity_share_pct, 1),
    wedge_share_pct = round(wedge_share_pct, 1),
    G_swing = round(G_swing, 4),
    N_swing = round(N_swing, 4),
    D_swing = round(D_swing, 4),
    S_off_swing = round(S_off_swing, 4),
    F_rev_swing = round(F_rev_swing, 4),
    avg_chi = round(avg_chi, 4),
    avg_accounting_wedge = round(avg_accounting_wedge, 4)
  )

year_tbl_compact <- year_tbl_dys |>
  dplyr::transmute(
    year, swing_id,
    d_pi, d_mu, d_p, d_B, d_nu,
    G_t, N_t, D_t, S_off_t, F_rev_t,
    mu_t, theta_t, nu_level, chi_t, g_K_t
  )

accounting_wedge_summary <- d |>
  dplyr::summarise(
    mean_accounting_wedge = mean(accounting_wedge_t, na.rm = TRUE),
    sd_accounting_wedge   = sd(accounting_wedge_t, na.rm = TRUE),
    min_accounting_wedge  = min(accounting_wedge_t, na.rm = TRUE),
    max_accounting_wedge  = max(accounting_wedge_t, na.rm = TRUE),
    mean_nu_level         = mean(nu_t - 1, na.rm = TRUE),
    mean_chi              = mean(chi_t, na.rm = TRUE)
  )

analytical_bundle_chile <- list(
  d = d,
  tp_env_final = tp_env_final,
  swing_tbl_full = swing_tbl_full,
  swing_tbl_compact = swing_tbl_compact,
  year_tbl_dys = year_tbl_dys,
  year_tbl_compact = year_tbl_compact,
  year_tbl_recap = year_tbl_recap,
  swing_tbl_recap = swing_tbl_recap,
  accounting_wedge_summary = accounting_wedge_summary
)

# ── 10. Save core objects ────────────────────────────────────────────────────
saveRDS(analytical_bundle_chile, file.path(rds_dir, "analytical_bundle_chile.rds"))
saveRDS(d, file.path(rds_dir, "d_merged_profitability_chile.rds"))
saveRDS(swing_tbl_full, file.path(rds_dir, "swing_tbl_full_chile.rds"))
saveRDS(year_tbl_dys, file.path(rds_dir, "year_tbl_dys_chile.rds"))
saveRDS(swing_tbl_recap, file.path(rds_dir, "swing_tbl_recap_chile.rds"))
saveRDS(accounting_wedge_summary, file.path(rds_dir, "accounting_wedge_summary_chile.rds"))

cat("Saved Chile profitability core objects to:\n")
cat("  ", rds_dir, "\n", sep = "")
cat("  analytical_bundle_chile.rds\n")
cat("  d_merged_profitability_chile.rds\n")
cat("  swing_tbl_full_chile.rds\n")
cat("  year_tbl_dys_chile.rds\n")
cat("  swing_tbl_recap_chile.rds\n")
cat("  accounting_wedge_summary_chile.rds\n")