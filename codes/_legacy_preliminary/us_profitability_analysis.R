###############################################################################
# US — Profitability analysis core
# Analytical engine only
#
# Purpose:
# - Build chronology, structural decomposition, dysfunctionality
# - Build class-struggle filtered chronology
# - Build accounting recapitalization layer
# - Build structural-accounting wedge diagnostic
# - Save canonical analytical objects as .rds
###############################################################################

# ── 0. Packages ──────────────────────────────────────────────────────────────
pkgs <- c("dplyr", "readr", "tibble", "zoo", "mFilter")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}
invisible(lapply(pkgs, library, character.only = TRUE))

# ── 1. Paths ─────────────────────────────────────────────────────────────────
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
data_dir  <- file.path(proj_root, "data/processed/US")
rds_dir   <- file.path(proj_root, "output", "profitability_us", "rds")
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)

# ── 2. Load μ/θ package ──────────────────────────────────────────────────────
mu_theta_file <- list.files(
  data_dir,
  pattern = "us_mu_theta_path_spec.*\\.csv$",
  full.names = TRUE
)

d_mt <- readr::read_csv(mu_theta_file, show_col_types = FALSE) |>
  dplyr::select(year, omega_t, theta_t_hat, gK, gYp, Y_real, Yp_hat, mu_t) |>
  dplyr::arrange(year)

# ── 3. Load stageBC layer ────────────────────────────────────────────────────
d_bc <- readr::read_csv(
  file.path(data_dir, "us_nf_corporate_stageBC.csv"),
  show_col_types = FALSE
) |>
  dplyr::select(
    year,
    GVA, EC, GOS,
    KNC, KNR, KGC, KGR,
    IGC,
    Py, pK,
    GVA_real
  ) |>
  dplyr::rename(pY = Py) |>
  dplyr::arrange(year)

# ── 4. Merge ─────────────────────────────────────────────────────────────────
d <- d_mt |>
  dplyr::inner_join(d_bc, by = "year") |>
  dplyr::arrange(year) |>
  dplyr::filter(year >= 1940, year <= 1978)

# ── 5. Build objects ─────────────────────────────────────────────────────────
d <- d |>
  dplyr::mutate(
    # structural profitability layer
    p_t   = pY / pK,
    B_t   = Yp_hat / KGR,   # corrected capital basis
    nu_t  = KGC / KNC,
    pi_t  = 1 - omega_t,
    r_struct_t    = pi_t * mu_t * p_t * B_t * nu_t,
    ln_r_struct_t = log(r_struct_t),
    
    # diagnostic / accounting profitability
    r_diag_t    = GOS / KNC,
    ln_r_diag_t = log(r_diag_t),
    
    # decomposition terms
    ln_pi_t = log(pi_t),
    ln_mu_t = log(mu_t),
    ln_p_t  = log(p_t),
    ln_B_t  = log(B_t),
    ln_nu_t = log(nu_t),
    
    # chronology diagnostic
    dln_r_diag     = ln_r_diag_t - dplyr::lag(ln_r_diag_t),
    dln_r_diag_ma3 = zoo::rollmean(dln_r_diag, k = 3, fill = NA, align = "center")
  )

# ── 6. Turning-point helpers ─────────────────────────────────────────────────
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
  
  if (length(out) == 0) {
    return(tibble::tibble(idx = integer(), year = integer(), value = numeric(), type = character()))
  }
  
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

prune_turning_points_windowed <- function(tp, data, xvar,
                                          war_end = 1946,
                                          min_move_war = 0.08,
                                          min_years_war = 2,
                                          min_move_post = 0.10,
                                          min_years_post = 3) {
  tp_war  <- tp |> dplyr::filter(year <= war_end)
  tp_post <- tp |> dplyr::filter(year >= war_end)
  
  tp_war_pruned <- if (nrow(tp_war) > 0) {
    tp_war |>
      compress_turning_points() |>
      prune_turning_points(x = data[[xvar]], min_move = min_move_war, min_years = min_years_war)
  } else tp_war
  
  tp_post_pruned <- if (nrow(tp_post) > 0) {
    tp_post |>
      compress_turning_points() |>
      prune_turning_points(x = data[[xvar]], min_move = min_move_post, min_years = min_years_post)
  } else tp_post
  
  dplyr::bind_rows(tp_war_pruned, tp_post_pruned) |>
    dplyr::distinct(idx, .keep_all = TRUE) |>
    dplyr::arrange(idx) |>
    compress_turning_points()
}

drop_weak_terminal_swing <- function(tp, data, xvar, min_years = 3, min_move = 0.02) {
  if (nrow(tp) < 2) return(tp)
  
  dur_last <- tp$year[nrow(tp)] - tp$year[nrow(tp) - 1]
  amp_last <- abs(data[[xvar]][tp$idx[nrow(tp)]] - data[[xvar]][tp$idx[nrow(tp) - 1]])
  
  if (dur_last < min_years && amp_last < min_move) {
    tp <- tp[-nrow(tp), , drop = FALSE]
  }
  
  tp
}

add_boundaries <- function(tp, data, xvar) {
  if (nrow(tp) == 0) stop("No internal turning points detected.")
  
  first_type <- if (tp$type[1] == "peak") "trough" else "peak"
  last_type  <- if (tp$type[nrow(tp)] == "peak") "trough" else "peak"
  
  start_row <- tibble::tibble(
    idx = 1,
    year = data$year[1],
    value = data[[xvar]][1],
    type = first_type
  )
  
  end_row <- tibble::tibble(
    idx = nrow(data),
    year = data$year[nrow(data)],
    value = data[[xvar]][nrow(data)],
    type = last_type
  )
  
  dplyr::bind_rows(start_row, tp, end_row) |>
    dplyr::arrange(idx) |>
    compress_turning_points()
}

# ── 7. Chronologies ──────────────────────────────────────────────────────────
tp_raw <- find_turning_points_direction(d$year, d$ln_r_diag_t, k = 3)
tp_all <- compress_turning_points(tp_raw)

tp_env <- prune_turning_points_windowed(
  tp = tp_raw,
  data = d,
  xvar = "ln_r_diag_t",
  war_end = 1946,
  min_move_war = 0.08,
  min_years_war = 2,
  min_move_post = 0.10,
  min_years_post = 3
)

tp_all_final <- add_boundaries(tp_all, d, "ln_r_diag_t")

tp_env_final <- add_boundaries(tp_env, d, "ln_r_diag_t") |>
  drop_weak_terminal_swing(data = d, xvar = "ln_r_diag_t", min_years = 3, min_move = 0.02)

# ── 8. Swing table builders ──────────────────────────────────────────────────
build_swing_table_paper <- function(tp, data) {
  if (nrow(tp) < 2) return(tibble::tibble())
  
  out <- vector("list", nrow(tp) - 1)
  
  for (i in 1:(nrow(tp) - 1)) {
    start_idx  <- tp$idx[i]
    end_idx    <- tp$idx[i + 1]
    start_year <- tp$year[i]
    end_year   <- tp$year[i + 1]
    dur        <- end_year - start_year
    
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
  
  out$dist_log <- NA_real_
  out$util_log <- NA_real_
  out$price_log <- NA_real_
  out$capacity_log <- NA_real_
  out$wedge_log <- NA_real_
  out$total_log_check <- NA_real_
  
  out$dist_share_pct <- NA_real_
  out$util_share_pct <- NA_real_
  out$price_share_pct <- NA_real_
  out$capacity_share_pct <- NA_real_
  out$wedge_share_pct <- NA_real_
  out$share_sum_pct <- NA_real_
  
  for (i in seq_len(nrow(out))) {
    start_idx <- tp$idx[i]
    end_idx   <- tp$idx[i + 1]
    
    d_pi <- data$ln_pi_t[end_idx] - data$ln_pi_t[start_idx]
    d_mu <- data$ln_mu_t[end_idx] - data$ln_mu_t[start_idx]
    d_p  <- data$ln_p_t[end_idx]  - data$ln_p_t[start_idx]
    d_B  <- data$ln_B_t[end_idx]  - data$ln_B_t[start_idx]
    d_nu <- data$ln_nu_t[end_idx] - data$ln_nu_t[start_idx]
    
    d_r_struct <- out$amplitude_log_struct[i]
    
    out$dist_log[i] <- d_pi
    out$util_log[i] <- d_mu
    out$price_log[i] <- d_p
    out$capacity_log[i] <- d_B
    out$wedge_log[i] <- d_nu
    out$total_log_check[i] <- d_pi + d_mu + d_p + d_B + d_nu
    
    if (!is.na(d_r_struct) && abs(d_r_struct) > 1e-10) {
      out$dist_share_pct[i]     <- 100 * d_pi / d_r_struct
      out$util_share_pct[i]     <- 100 * d_mu / d_r_struct
      out$price_share_pct[i]    <- 100 * d_p  / d_r_struct
      out$capacity_share_pct[i] <- 100 * d_B  / d_r_struct
      out$wedge_share_pct[i]    <- 100 * d_nu / d_r_struct
      out$share_sum_pct[i]      <- 100 * (d_pi + d_mu + d_p + d_B + d_nu) / d_r_struct
    }
  }
  
  out
}

add_swing_dysfunctionality <- function(swing_tbl, eps = 1e-10) {
  out <- swing_tbl
  comp_names <- c("distribution", "utilization", "price", "capacity", "wedge")
  
  out$reinforcing_sign <- NA_integer_
  out$gross_reinforcing_pct <- NA_real_
  out$gross_offsetting_pct  <- NA_real_
  out$net_imbalance_idx <- NA_real_
  out$compensation_intensity <- NA_real_
  out$reinforcing_concentration <- NA_real_
  out$reversal_risk_raw <- NA_real_
  out$momentum_contradiction <- NA_real_
  out$n_reinforcing <- NA_integer_
  out$n_offsetting <- NA_integer_
  out$reinforcing_main_component <- NA_character_
  out$offsetting_main_component <- NA_character_
  
  for (i in seq_len(nrow(out))) {
    c_vec <- c(out$dist_log[i], out$util_log[i], out$price_log[i], out$capacity_log[i], out$wedge_log[i])
    names(c_vec) <- comp_names
    
    d_r <- out$amplitude_log_struct[i]
    if (is.na(d_r) || abs(d_r) <= eps) next
    
    sgn <- ifelse(d_r > 0, 1L, -1L)
    out$reinforcing_sign[i] <- sgn
    
    reinforce_mask <- sign(c_vec) == sgn & abs(c_vec) > eps
    offset_mask    <- sign(c_vec) == -sgn & abs(c_vec) > eps
    
    reinforce_vals <- abs(c_vec[reinforce_mask])
    offset_vals    <- abs(c_vec[offset_mask])
    total_abs      <- sum(abs(c_vec), na.rm = TRUE)
    if (total_abs <= eps) next
    
    reinforce_sum <- sum(reinforce_vals, na.rm = TRUE)
    offset_sum    <- sum(offset_vals, na.rm = TRUE)
    
    out$gross_reinforcing_pct[i] <- 100 * reinforce_sum / total_abs
    out$gross_offsetting_pct[i]  <- 100 * offset_sum / total_abs
    out$net_imbalance_idx[i]     <- (reinforce_sum - offset_sum) / total_abs
    out$compensation_intensity[i] <- offset_sum / abs(d_r)
    
    if (reinforce_sum > eps) {
      reinforce_shares <- reinforce_vals / reinforce_sum
      out$reinforcing_concentration[i] <- sum(reinforce_shares^2, na.rm = TRUE)
    }
    
    if (!is.na(out$gross_offsetting_pct[i]) && !is.na(out$reinforcing_concentration[i])) {
      out$reversal_risk_raw[i] <- out$gross_offsetting_pct[i] * out$reinforcing_concentration[i]
    }
    
    if (!is.na(out$compensation_intensity[i]) && !is.na(out$duration_years[i])) {
      out$momentum_contradiction[i] <- out$compensation_intensity[i] * out$duration_years[i]
    }
    
    out$n_reinforcing[i] <- sum(reinforce_mask, na.rm = TRUE)
    out$n_offsetting[i]  <- sum(offset_mask, na.rm = TRUE)
    
    if (length(reinforce_vals) > 0) {
      out$reinforcing_main_component[i] <- names(which.max(abs(c_vec[reinforce_mask])))
    }
    if (length(offset_vals) > 0) {
      out$offsetting_main_component[i] <- names(which.max(abs(c_vec[offset_mask])))
    }
  }
  
  out
}

# ── 9. Profit-swing outputs ──────────────────────────────────────────────────
swing_tbl_paper  <- build_swing_table_paper(tp_env_final, d)
swing_tbl_decomp <- add_swing_decomposition(swing_tbl_paper, tp_env_final, d)
swing_tbl_full   <- add_swing_dysfunctionality(swing_tbl_decomp)

# ── 10. Accounting recapitalization + wedge ──────────────────────────────────
d <- d |>
  dplyr::mutate(
    ln_KNC_t = log(KNC),
    g_K_t = ln_KNC_t - dplyr::lag(ln_KNC_t),
    
    gross_recap_ratio_t = dplyr::if_else(!is.na(GOS) & abs(GOS) > 1e-8, IGC / GOS, NA_real_),
    net_recap_ratio_t   = dplyr::if_else(!is.na(r_diag_t) & abs(r_diag_t) > 1e-8, g_K_t / r_diag_t, NA_real_),
    
    accounting_wedge_t = dplyr::if_else(!is.na(r_diag_t) & abs(r_diag_t) > 1e-8, r_struct_t / r_diag_t, NA_real_),
    accounting_wedge_log_t = dplyr::if_else(
      !is.na(r_struct_t) & !is.na(r_diag_t) & r_struct_t > 0 & r_diag_t > 0,
      log(r_struct_t) - log(r_diag_t),
      NA_real_
    )
  )

year_tbl_recap <- d |>
  dplyr::transmute(
    year,
    r_diag_t,
    g_K_t,
    gross_recap_ratio_t,
    net_recap_ratio_t,
    accounting_wedge_t,
    accounting_wedge_log_t
  ) |>
  dplyr::mutate(swing_id = NA_integer_)

for (j in seq_len(nrow(swing_tbl_full))) {
  y0 <- swing_tbl_full$start_year[j]
  y1 <- swing_tbl_full$end_year[j]
  
  if (j < nrow(swing_tbl_full)) {
    idx <- which(year_tbl_recap$year >= y0 & year_tbl_recap$year < y1)
  } else {
    idx <- which(year_tbl_recap$year >= y0 & year_tbl_recap$year <= y1)
  }
  
  year_tbl_recap$swing_id[idx] <- swing_tbl_full$swing_id[j]
}

swing_tbl_recap <- year_tbl_recap |>
  dplyr::group_by(swing_id) |>
  dplyr::summarise(
    avg_r_diag = mean(r_diag_t, na.rm = TRUE),
    avg_g_K = mean(g_K_t, na.rm = TRUE),
    
    avg_gross_recap_ratio = mean(gross_recap_ratio_t, na.rm = TRUE),
    sd_gross_recap_ratio = sd(gross_recap_ratio_t, na.rm = TRUE),
    gross_recap_start = dplyr::first(stats::na.omit(gross_recap_ratio_t)),
    gross_recap_end   = dplyr::last(stats::na.omit(gross_recap_ratio_t)),
    
    avg_net_recap_ratio = mean(net_recap_ratio_t, na.rm = TRUE),
    sd_net_recap_ratio = sd(net_recap_ratio_t, na.rm = TRUE),
    net_recap_start = dplyr::first(stats::na.omit(net_recap_ratio_t)),
    net_recap_end   = dplyr::last(stats::na.omit(net_recap_ratio_t)),
    
    avg_accounting_wedge = mean(accounting_wedge_t, na.rm = TRUE),
    sd_accounting_wedge = sd(accounting_wedge_t, na.rm = TRUE),
    wedge_start = dplyr::first(stats::na.omit(accounting_wedge_t)),
    wedge_end   = dplyr::last(stats::na.omit(accounting_wedge_t)),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    delta_gross_recap_ratio = gross_recap_end - gross_recap_start,
    delta_net_recap_ratio   = net_recap_end - net_recap_start,
    delta_accounting_wedge  = wedge_end - wedge_start
  )

swing_tbl_recap_full <- swing_tbl_full |>
  dplyr::left_join(swing_tbl_recap, by = "swing_id")

valid_swing_ids <- swing_tbl_recap_full |>
  dplyr::filter(!(duration_years < 3 & abs(amplitude_pct_diag) < 5)) |>
  dplyr::pull(swing_id)

swing_tbl_recap <- swing_tbl_recap |>
  dplyr::filter(swing_id %in% valid_swing_ids)

swing_tbl_recap_full <- swing_tbl_recap_full |>
  dplyr::filter(swing_id %in% valid_swing_ids)

swing_tbl_compact <- swing_tbl_recap_full |>
  dplyr::transmute(
    swing_id,
    start_year,
    end_year,
    direction,
    duration_years,
    amplitude_pct_diag = round(amplitude_pct_diag, 1),
    pace_pct_diag_per_year = round(pace_pct_diag_per_year, 2),
    amplitude_log_struct = round(amplitude_log_struct, 3),
    dist_share_pct = round(dist_share_pct, 1),
    util_share_pct = round(util_share_pct, 1),
    price_share_pct = round(price_share_pct, 1),
    capacity_share_pct = round(capacity_share_pct, 1),
    wedge_share_pct = round(wedge_share_pct, 1),
    share_sum_pct = round(share_sum_pct, 1),
    gross_reinforcing_pct = round(gross_reinforcing_pct, 1),
    gross_offsetting_pct = round(gross_offsetting_pct, 1),
    net_imbalance_idx = round(net_imbalance_idx, 3),
    compensation_intensity = round(compensation_intensity, 3),
    reinforcing_concentration = round(reinforcing_concentration, 3),
    reversal_risk_raw = round(reversal_risk_raw, 2),
    momentum_contradiction = round(momentum_contradiction, 2),
    avg_r_diag = round(avg_r_diag, 3),
    avg_g_K = round(avg_g_K, 3),
    avg_gross_recap_ratio = round(avg_gross_recap_ratio, 3),
    delta_gross_recap_ratio = round(delta_gross_recap_ratio, 3),
    avg_net_recap_ratio = round(avg_net_recap_ratio, 3),
    delta_net_recap_ratio = round(delta_net_recap_ratio, 3),
    reinforcing_main_component,
    offsetting_main_component
  )

accounting_wedge_summary <- d |>
  dplyr::summarise(
    mean_accounting_wedge = mean(accounting_wedge_t, na.rm = TRUE),
    sd_accounting_wedge   = sd(accounting_wedge_t, na.rm = TRUE),
    cv_accounting_wedge   = sd(accounting_wedge_t, na.rm = TRUE) / mean(accounting_wedge_t, na.rm = TRUE),
    min_accounting_wedge  = min(accounting_wedge_t, na.rm = TRUE),
    max_accounting_wedge  = max(accounting_wedge_t, na.rm = TRUE)
  )

# ── 11. Yearly dysfunctionality ──────────────────────────────────────────────
build_yearly_dysfunctionality <- function(data, swing_tbl, eps = 1e-10) {
  comp_names <- c("distribution", "utilization", "price", "capacity", "wedge")
  
  out <- data |>
    dplyr::transmute(
      year,
      r_diag_t,
      ln_r_diag_t,
      r_struct_t,
      ln_r_struct_t,
      dln_r_diag,
      dln_r_diag_ma3,
      ln_pi_t,
      ln_mu_t,
      ln_p_t,
      ln_B_t,
      ln_nu_t
    ) |>
    dplyr::mutate(
      d_dist = ln_pi_t - dplyr::lag(ln_pi_t),
      d_util = ln_mu_t - dplyr::lag(ln_mu_t),
      d_price = ln_p_t - dplyr::lag(ln_p_t),
      d_capacity = ln_B_t - dplyr::lag(ln_B_t),
      d_wedge = ln_nu_t - dplyr::lag(ln_nu_t),
      d_r_struct = ln_r_struct_t - dplyr::lag(ln_r_struct_t),
      
      swing_id = NA_integer_,
      swing_start = NA_real_,
      swing_end = NA_real_,
      swing_direction = NA_character_,
      swing_duration = NA_real_,
      
      gross_reinforcing_pct_t = NA_real_,
      gross_offsetting_pct_t = NA_real_,
      net_imbalance_idx_t = NA_real_,
      compensation_intensity_t = NA_real_,
      reinforcing_concentration_t = NA_real_,
      reversal_risk_raw_t = NA_real_,
      
      gross_reinforcing_pct_swing = NA_real_,
      gross_offsetting_pct_swing = NA_real_,
      net_imbalance_idx_swing = NA_real_,
      compensation_intensity_swing = NA_real_,
      reinforcing_concentration_swing = NA_real_,
      reversal_risk_raw_swing = NA_real_,
      momentum_contradiction_swing = NA_real_,
      
      reinforcing_main_component_swing = NA_character_,
      offsetting_main_component_swing = NA_character_
    )
  
  for (j in seq_len(nrow(swing_tbl))) {
    y0 <- swing_tbl$start_year[j]
    y1 <- swing_tbl$end_year[j]
    
    if (j < nrow(swing_tbl)) {
      idx_years <- which(out$year >= y0 & out$year < y1)
    } else {
      idx_years <- which(out$year >= y0 & out$year <= y1)
    }
    
    out$swing_id[idx_years] <- swing_tbl$swing_id[j]
    out$swing_start[idx_years] <- y0
    out$swing_end[idx_years] <- y1
    out$swing_direction[idx_years] <- swing_tbl$direction[j]
    out$swing_duration[idx_years] <- swing_tbl$duration_years[j]
    
    out$gross_reinforcing_pct_swing[idx_years] <- swing_tbl$gross_reinforcing_pct[j]
    out$gross_offsetting_pct_swing[idx_years] <- swing_tbl$gross_offsetting_pct[j]
    out$net_imbalance_idx_swing[idx_years] <- swing_tbl$net_imbalance_idx[j]
    out$compensation_intensity_swing[idx_years] <- swing_tbl$compensation_intensity[j]
    out$reinforcing_concentration_swing[idx_years] <- swing_tbl$reinforcing_concentration[j]
    out$reversal_risk_raw_swing[idx_years] <- swing_tbl$reversal_risk_raw[j]
    out$momentum_contradiction_swing[idx_years] <- swing_tbl$momentum_contradiction[j]
    out$reinforcing_main_component_swing[idx_years] <- swing_tbl$reinforcing_main_component[j]
    out$offsetting_main_component_swing[idx_years] <- swing_tbl$offsetting_main_component[j]
  }
  
  for (i in seq_len(nrow(out))) {
    c_vec <- c(out$d_dist[i], out$d_util[i], out$d_price[i], out$d_capacity[i], out$d_wedge[i])
    names(c_vec) <- comp_names
    
    d_r <- out$d_r_struct[i]
    if (is.na(d_r) || abs(d_r) <= eps) next
    
    sgn <- ifelse(d_r > 0, 1, -1)
    reinforce_mask <- sign(c_vec) == sgn & abs(c_vec) > eps
    offset_mask    <- sign(c_vec) == -sgn & abs(c_vec) > eps
    
    reinforce_vals <- abs(c_vec[reinforce_mask])
    offset_vals    <- abs(c_vec[offset_mask])
    total_abs      <- sum(abs(c_vec), na.rm = TRUE)
    if (total_abs <= eps) next
    
    reinforce_sum <- sum(reinforce_vals, na.rm = TRUE)
    offset_sum    <- sum(offset_vals, na.rm = TRUE)
    
    out$gross_reinforcing_pct_t[i] <- 100 * reinforce_sum / total_abs
    out$gross_offsetting_pct_t[i]  <- 100 * offset_sum / total_abs
    out$net_imbalance_idx_t[i]     <- (reinforce_sum - offset_sum) / total_abs
    out$compensation_intensity_t[i] <- offset_sum / abs(d_r)
    
    if (reinforce_sum > eps) {
      reinforce_shares <- reinforce_vals / reinforce_sum
      out$reinforcing_concentration_t[i] <- sum(reinforce_shares^2, na.rm = TRUE)
    }
    
    if (!is.na(out$gross_offsetting_pct_t[i]) && !is.na(out$reinforcing_concentration_t[i])) {
      out$reversal_risk_raw_t[i] <- out$gross_offsetting_pct_t[i] * out$reinforcing_concentration_t[i]
    }
  }
  
  out |>
    dplyr::mutate(
      dist_share_t = dplyr::if_else(abs(d_r_struct) > eps, 100 * d_dist / d_r_struct, NA_real_),
      util_share_t = dplyr::if_else(abs(d_r_struct) > eps, 100 * d_util / d_r_struct, NA_real_),
      price_share_t = dplyr::if_else(abs(d_r_struct) > eps, 100 * d_price / d_r_struct, NA_real_),
      capacity_share_t = dplyr::if_else(abs(d_r_struct) > eps, 100 * d_capacity / d_r_struct, NA_real_),
      wedge_share_t = dplyr::if_else(abs(d_r_struct) > eps, 100 * d_wedge / d_r_struct, NA_real_),
      share_sum_t = dist_share_t + util_share_t + price_share_t + capacity_share_t + wedge_share_t,
      stagnation_transmission_t = dplyr::if_else(
        !is.na(gross_offsetting_pct_t) & !is.na(d_r_struct),
        (gross_offsetting_pct_t / 100) * abs(d_r_struct),
        NA_real_
      )
    )
}

year_tbl_dys <- build_yearly_dysfunctionality(d, swing_tbl_full)

year_tbl_compact <- year_tbl_dys |>
  dplyr::transmute(
    year,
    swing_id,
    swing_start,
    swing_end,
    swing_direction,
    gross_reinforcing_pct_t = round(gross_reinforcing_pct_t, 1),
    gross_offsetting_pct_t = round(gross_offsetting_pct_t, 1),
    net_imbalance_idx_t = round(net_imbalance_idx_t, 3),
    compensation_intensity_t = round(compensation_intensity_t, 3),
    reinforcing_concentration_t = round(reinforcing_concentration_t, 3),
    reversal_risk_raw_t = round(reversal_risk_raw_t, 2),
    
    gross_reinforcing_pct_swing = round(gross_reinforcing_pct_swing, 1),
    gross_offsetting_pct_swing = round(gross_offsetting_pct_swing, 1),
    net_imbalance_idx_swing = round(net_imbalance_idx_swing, 3),
    compensation_intensity_swing = round(compensation_intensity_swing, 3),
    reinforcing_concentration_swing = round(reinforcing_concentration_swing, 3),
    reversal_risk_raw_swing = round(reversal_risk_raw_swing, 2),
    
    dist_share_t = round(dist_share_t, 1),
    util_share_t = round(util_share_t, 1),
    price_share_t = round(price_share_t, 1),
    capacity_share_t = round(capacity_share_t, 1),
    wedge_share_t = round(wedge_share_t, 1),
    share_sum_t = round(share_sum_t, 1)
  )

# ── 12. Class-struggle chronology ────────────────────────────────────────────
d <- d |>
  dplyr::mutate(
    ln_omega_t = log(omega_t),
    ln_omega_T_t = ln_omega_t - theta_t_hat * log(mu_t),
    omega_T_t = exp(ln_omega_T_t),
    dln_omega_T = ln_omega_T_t - dplyr::lag(ln_omega_T_t),
    dln_omega_T_ma3 = zoo::rollmean(dln_omega_T, k = 3, fill = NA, align = "center")
  )

tpw_raw <- find_turning_points_direction(d$year, d$ln_omega_T_t, k = 3)
tpw_all <- compress_turning_points(tpw_raw)

tpw_env <- prune_turning_points_windowed(
  tp = tpw_raw,
  data = d,
  xvar = "ln_omega_T_t",
  war_end = 1946,
  min_move_war = 0.08,
  min_years_war = 2,
  min_move_post = 0.10,
  min_years_post = 3
)

tpw_all_final <- add_boundaries(tpw_all, d, "ln_omega_T_t")

tpw_env_final <- add_boundaries(tpw_env, d, "ln_omega_T_t") |>
  drop_weak_terminal_swing(data = d, xvar = "ln_omega_T_t", min_years = 3, min_move = 0.02)

build_swing_table_generic <- function(tp, data, level_var, log_var) {
  if (nrow(tp) < 2) return(tibble::tibble())
  
  out <- vector("list", nrow(tp) - 1)
  
  for (i in 1:(nrow(tp) - 1)) {
    start_idx  <- tp$idx[i]
    end_idx    <- tp$idx[i + 1]
    start_year <- tp$year[i]
    end_year   <- tp$year[i + 1]
    dur        <- end_year - start_year
    
    start_level <- data[[level_var]][start_idx]
    end_level   <- data[[level_var]][end_idx]
    amp_log <- data[[log_var]][end_idx] - data[[log_var]][start_idx]
    
    out[[i]] <- tibble::tibble(
      swing_id = i,
      start_year = start_year,
      end_year = end_year,
      direction = paste0(tp$type[i], "_to_", tp$type[i + 1]),
      duration_years = dur,
      start_level = start_level,
      end_level = end_level,
      amplitude_pct = 100 * (end_level / start_level - 1),
      pace_pct_per_year = ifelse(dur > 0, 100 * ((end_level / start_level)^(1 / dur) - 1), NA_real_),
      amplitude_log = amp_log,
      pace_log_per_year = ifelse(dur > 0, amp_log / dur, NA_real_)
    )
  }
  
  dplyr::bind_rows(out)
}

swing_tbl_class <- build_swing_table_generic(
  tp = tpw_env_final,
  data = d,
  level_var = "omega_T_t",
  log_var = "ln_omega_T_t"
)

swing_tbl_class_compact <- swing_tbl_class |>
  dplyr::transmute(
    swing_id,
    start_year,
    end_year,
    direction,
    duration_years,
    amplitude_pct = round(amplitude_pct, 1),
    pace_pct_per_year = round(pace_pct_per_year, 2),
    amplitude_log = round(amplitude_log, 3)
  )

# ── 13. Overlap table ────────────────────────────────────────────────────────
build_overlap_table <- function(profit_tbl, class_tbl) {
  out <- vector("list", 0)
  
  for (i in seq_len(nrow(profit_tbl))) {
    p0 <- profit_tbl$start_year[i]
    p1 <- profit_tbl$end_year[i]
    
    for (k in seq_len(nrow(class_tbl))) {
      c0 <- class_tbl$start_year[k]
      c1 <- class_tbl$end_year[k]
      
      overlap_start <- max(p0, c0)
      overlap_end   <- min(p1, c1)
      
      if (overlap_start <= overlap_end) {
        out[[length(out) + 1]] <- tibble::tibble(
          profit_swing_id = profit_tbl$swing_id[i],
          class_swing_id  = class_tbl$swing_id[k],
          profit_interval = paste0(p0, "-", p1),
          class_interval  = paste0(c0, "-", c1),
          overlap_start   = overlap_start,
          overlap_end     = overlap_end,
          overlap_years   = overlap_end - overlap_start + 1
        )
      }
    }
  }
  
  dplyr::bind_rows(out)
}

overlap_tbl <- build_overlap_table(
  profit_tbl = swing_tbl_paper,
  class_tbl  = swing_tbl_class
)

# ── 14. Canonical analytical bundle ──────────────────────────────────────────
analytical_bundle_us <- list(
  d = d,
  tp_all_final = tp_all_final,
  tp_env_final = tp_env_final,
  swing_tbl_paper = swing_tbl_paper,
  swing_tbl_decomp = swing_tbl_decomp,
  swing_tbl_full = swing_tbl_full,
  year_tbl_recap = year_tbl_recap,
  swing_tbl_recap = swing_tbl_recap,
  swing_tbl_recap_full = swing_tbl_recap_full,
  swing_tbl_compact = swing_tbl_compact,
  accounting_wedge_summary = accounting_wedge_summary,
  year_tbl_dys = year_tbl_dys,
  year_tbl_compact = year_tbl_compact,
  tpw_all_final = tpw_all_final,
  tpw_env_final = tpw_env_final,
  swing_tbl_class = swing_tbl_class,
  swing_tbl_class_compact = swing_tbl_class_compact,
  overlap_tbl = overlap_tbl
)

# ── 15. Save canonical objects ───────────────────────────────────────────────
saveRDS(analytical_bundle_us, file.path(rds_dir, "analytical_bundle_us.rds"))
saveRDS(d, file.path(rds_dir, "d_merged_profitability_us.rds"))
saveRDS(swing_tbl_full, file.path(rds_dir, "swing_tbl_full.rds"))
saveRDS(swing_tbl_recap, file.path(rds_dir, "swing_tbl_recap.rds"))
saveRDS(swing_tbl_recap_full, file.path(rds_dir, "swing_tbl_recap_full.rds"))
saveRDS(year_tbl_dys, file.path(rds_dir, "year_tbl_dys.rds"))
saveRDS(year_tbl_recap, file.path(rds_dir, "year_tbl_recap.rds"))
saveRDS(accounting_wedge_summary, file.path(rds_dir, "accounting_wedge_summary.rds"))

cat("\nSaved analytical core to:\n")
cat("  ", rds_dir, "\n", sep = "")
cat("  analytical_bundle_us.rds\n")