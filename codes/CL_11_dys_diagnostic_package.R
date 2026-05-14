# ============================================================
# CHILE DIAGNOSTIC PACKAGE BUILDER
# Profitability swings + decomposable dysfunctionality +
# structural regime overlay (theta -> mu -> chi -> ECT bind)
# ------------------------------------------------------------
# Design principles
# 1) Keep first-order profitability motion separate from the
#    second-order structural regime object.
# 2) Build dysfunctionality indices directly from the moving
#    profitability components.
# 3) Make the index reopenable: every swing can be traced back
#    to the exact components generating contradiction.
# 4) Use the ISI1931_1973 threshold object as the governing
#    structural architecture for the pre-1974 historical reading.
# ============================================================

suppressPackageStartupMessages({
  library(here)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(stringr)
  library(ggplot2)
  library(tibble)
})

# ============================================================
# 0. PATHS AND USER SWITCHES
# ============================================================

# ---- Existing structural outputs already validated ----
path_stage1_master <- here::here("output", "chile_2Smu_S1", "txt", "stage1__master_results.rds")
path_stage2_root   <- here::here("output", "chile_2Smu_S2_tdols")
path_theta_isi     <- file.path(path_stage2_root, "csv", "threshold_theta__isi1931_1973.csv")
path_theta_post    <- file.path(path_stage2_root, "csv", "threshold_theta__post1974.csv")
path_stage2_panel  <- file.path(path_stage2_root, "csv", "stage2__working_panel.csv")

# ---- REQUIRED: profitability-motion source ----
# The profitability architecture currently lives in the RDS layer, not in a CSV placeholder.
# Preferred source order mirrors the standalone Chile swings diagnostic.
path_profit_rds <- here::here("output", "profitability_chile", "rds", "d_merged_profitability_chile.rds")
path_profit_bundle_rds <- here::here("output", "profitability_chile", "rds", "analytical_bundle_chile.rds")

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

# ---- OPTIONAL: externally prepared swing table ----
# If file exists, it will be used. Otherwise the script falls back to the locked
# collapsed chronology.
path_profit_swings <- here::here("output", "profitability_chile", "csv", "profit_rate_swings.csv")

# ---- Main output root ----
out_root <- here::here("output", "chile_diagnostic_package")
out_csv  <- file.path(out_root, "csv")
out_figs <- file.path(out_root, "figs")
out_txt  <- file.path(out_root, "txt")

dir.create(out_csv, recursive = TRUE, showWarnings = FALSE)
dir.create(out_figs, recursive = TRUE, showWarnings = FALSE)
dir.create(out_txt, recursive = TRUE, showWarnings = FALSE)

# ---- Governing structural sample lock ----
GOV_SAMPLE_PRE1974 <- "ISI1931_1973"
GAMMA_ISI <- -6.231728207560405
PINCH_YEAR <- 1980

# ---- Threshold bands for structural collapse ----
THETA_TOL <- 0.05
CHI_STRONG_Q <- 0.67
CHI_WEAK_Q   <- 0.33
HIGH_DYSFUNCTION_Q <- 0.75
HIGH_FRAGILITY_Q   <- 0.75

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

rescale_to_primary <- function(x, from_min, from_max, to_min, to_max) {
  to_min + (x - from_min) * (to_max - to_min) / (from_max - from_min)
}

inverse_rescale <- function(y, from_min, from_max, to_min, to_max) {
  from_min + (y - to_min) * (from_max - from_min) / (to_max - to_min)
}

# ============================================================
# 2. LOCKED COLLAPSED PERIODS
# ============================================================

collapsed_periods <- tribble(
  ~period,       ~start_year, ~end_year, ~profit_swing_class,
  "1940_1946",  1940L,       1946L,     "restorative_expansion",
  "1946_1949",  1946L,       1949L,     "corrective_downturn",
  "1949_1955",  1949L,       1955L,     "renewed_expansion",
  "1955_1961",  1955L,       1961L,     "stagnation_tendency",
  "1961_1969",  1961L,       1969L,     "contradictory_expansion",
  "1969_1972",  1969L,       1972L,     "crisis_breakdown",
  "1972_1974",  1972L,       1974L,     "forced_offset",
  "1974_1976",  1974L,       1976L,     "structural_fragility",
  "1976_1978",  1976L,       1978L,     "partial_recovery"
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
  
  df %>% mutate(log_y_p = logYp, y_p = exp(log_y_p), u = exp(y - log_y_p))
}

struct_splice <- rescue_u_path(struct_splice, pinch_year = PINCH_YEAR) %>%
  mutate(mu = u)

# External bind orientation locked to ISI threshold object.
# Low ECT side (ECT <= gamma_isi) is treated as the bind side.
struct_splice <- struct_splice %>%
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
# 4. PROFITABILITY-MOTION INPUT: BUILD FROM PRIMITIVES
# ============================================================

required_profit_primitives <- c(
  "year",
  "r_struct_t",
  "pi_t",
  "mu_t",
  "p_t",
  "B_t",
  "nu_t",
  "IGC",
  "GOS",
  "k_nr",
  "y"
)

missing_profit_primitives <- setdiff(required_profit_primitives, names(profit_df))
if (length(missing_profit_primitives) > 0) {
  stop(
    "The profitability object is missing required primitive columns:\n",
    paste(missing_profit_primitives, collapse = ", "),
    "\n\nExpected primitives:\n",
    paste(required_profit_primitives, collapse = ", "),
    call. = FALSE
  )
}

profit_df <- profit_df %>%
  arrange(year) %>%
  transmute(
    year = year,
    
    # structural profit-rate level used for swings
    r_struct = r_struct_t,
    
    # first-order moving profitability components
    d_pi = log(pi_t) - lag(log(pi_t)),
    d_mu = log(mu_t) - lag(log(mu_t)),
    d_p  = log(p_t)  - lag(log(p_t)),
    d_B  = log(B_t)  - lag(log(B_t)),
    d_nu = log(nu_t) - lag(log(nu_t)),
    
    # recapitalization ratio: gross investment over gross operating surplus
    chi = if_else(is.finite(GOS) & GOS > 0, IGC / GOS, NA_real_),
    
    # accumulation and growth rates in log terms
    g_k = k_nr - lag(k_nr),
    g_y = y    - lag(y),
    
    # keep useful structural companions if you want them available downstream
    ect = if ("ect" %in% names(cur_data())) ect else NA_real_,
    theta_t = if ("theta_t" %in% names(cur_data())) theta_t else NA_real_,
    mu_t = mu_t
  ) %>%
  mutate(
    period = assign_collapsed_period(year),
    component_distribution = d_pi,
    component_utilization  = d_mu,
    component_prices       = d_p,
    component_capacity     = d_B,
    component_wedge        = d_nu
  )
# ============================================================
# 5. FIRST-ORDER DYSFUNCTIONALITY INDICES (DECOMPOSABLE)
# ============================================================

component_names <- c("d_pi", "d_mu", "d_p", "d_B", "d_nu")
component_labels <- c(
  d_pi = "distribution",
  d_mu = "utilization_realization",
  d_p  = "relative_prices",
  d_B  = "productive_capacity",
  d_nu = "wedge"
)

profit_diag <- profit_df %>%
  rowwise() %>%
  mutate(
    G = sum(abs(c_across(all_of(component_names))), na.rm = TRUE),
    N = sum(c_across(all_of(component_names)), na.rm = TRUE),
    D = if_else(G > 0, 1 - abs(N) / G, 0),
    net_sign = case_when(N > 0 ~ 1, N < 0 ~ -1, TRUE ~ 0),
    O = case_when(
      net_sign == 0 ~ G,
      TRUE ~ sum(abs(c_across(all_of(component_names)))[sign(c_across(all_of(component_names))) == -net_sign], na.rm = TRUE)
    ),
    R = G - O,
    S_off = if_else(G > 0, O / G, 0),
    F_rev = if_else((O + abs(N)) > 0, O / (O + abs(N)), 0)
  ) %>%
  ungroup()

# Reopen the index by component-year contributions
component_long <- profit_diag %>%
  select(year, r_struct, period, G, N, D, O, R, S_off, F_rev, net_sign, all_of(component_names)) %>%
  pivot_longer(cols = all_of(component_names), names_to = "component", values_to = "value") %>%
  mutate(
    component_family = recode(component, !!!component_labels),
    abs_value = abs(value),
    contributes_to_net_direction = case_when(
      net_sign == 0 ~ FALSE,
      sign(value) == net_sign ~ TRUE,
      TRUE ~ FALSE
    ),
    offsets_net_direction = case_when(
      net_sign == 0 & abs_value > 0 ~ TRUE,
      net_sign == 0 & abs_value == 0 ~ FALSE,
      sign(value) == -net_sign ~ TRUE,
      TRUE ~ FALSE
    ),
    reinforcing_abs = if_else(contributes_to_net_direction, abs_value, 0),
    offsetting_abs  = if_else(offsets_net_direction, abs_value, 0),
    share_of_total_motion = if_else(G > 0, abs_value / G, 0),
    share_of_offsetting_motion = if_else(O > 0, offsetting_abs / O, 0),
    share_of_reinforcing_motion = if_else(R > 0, reinforcing_abs / R, 0)
  )

# ============================================================
# 6. SWING TABLE: EXTERNAL INPUT IF AVAILABLE, OTHERWISE USE LOCKED PERIODS
# ============================================================

if (file.exists(path_profit_swings)) {
  swing_tbl <- read_csv(path_profit_swings, show_col_types = FALSE)
  needed_swing_cols <- c("swing_id", "start_year", "end_year", "swing_class")
  missing_swing_cols <- setdiff(needed_swing_cols, names(swing_tbl))
  if (length(missing_swing_cols) > 0) {
    stop("Swing table missing columns: ", paste(missing_swing_cols, collapse = ", "), call. = FALSE)
  }
} else {
  swing_tbl <- collapsed_periods %>%
    transmute(
      swing_id = row_number(),
      start_year,
      end_year,
      swing_class = profit_swing_class,
      period = period
    )
}

assign_swing_id <- function(year_vec, swing_tbl) {
  out <- rep(NA_integer_, length(year_vec))
  for (i in seq_len(nrow(swing_tbl))) {
    idx <- year_vec >= swing_tbl$start_year[i] & year_vec <= swing_tbl$end_year[i]
    out[idx] <- swing_tbl$swing_id[i]
  }
  out
}

profit_diag <- profit_diag %>%
  mutate(swing_id = assign_swing_id(year, swing_tbl))

component_long <- component_long %>%
  mutate(swing_id = assign_swing_id(year, swing_tbl))

# ============================================================
# 7. MERGE STRUCTURAL TRACK INTO THE ANNUAL DIAGNOSTIC PANEL
# ============================================================

struct_overlay <- struct_splice %>%
  transmute(
    year,
    true_sample,
    regime_code_struct = as.character(regime_code),
    theta_r1_struct = theta_r1,
    theta_r2_struct = theta_r2,
    theta_active_struct = theta_active,
    ECT,
    ext_bind_flag_isi,
    ext_bind_state_isi,
    ext_bind_distance_isi,
    mu_struct = mu,
    y_struct = y,
    k_nr_struct = k_nr,
    y_p_struct = y_p,
    u_struct = u,
    wsh_struct = wsh
  )

annual_diagnostic_panel <- profit_diag %>%
  left_join(struct_overlay, by = "year") %>%
  mutate(
    theta_r1 = .data$theta_r1_struct,
    theta_r2 = .data$theta_r2_struct,
    theta_active = .data$theta_active_struct,
    mu = .data$mu_struct,
    regime_code = .data$regime_code_struct,
    y = .data$y_struct,
    k_nr = .data$k_nr_struct,
    y_p = .data$y_p_struct,
    u = .data$u_struct,
    wsh = .data$wsh_struct,
    
    mu_activation_state = case_when(
      is.na(.data$theta_active) | is.na(.data$mu) ~ NA_character_,
      .data$theta_active > 1 + THETA_TOL & .data$mu < 1 ~ "capacity_overaccumulation_activated",
      .data$theta_active > 1 + THETA_TOL & .data$mu >= 1 ~ "capacity_bias_not_activated",
      .data$theta_active < 1 - THETA_TOL & .data$mu > 1 ~ "accumulation_pressure_activated",
      .data$theta_active < 1 - THETA_TOL & .data$mu <= 1 ~ "demand_pressure_bias_not_activated",
      TRUE ~ "balanced_corridor"
    ),
    
    theta_state = case_when(
      is.na(.data$theta_active) ~ NA_character_,
      .data$theta_active > 1 + THETA_TOL ~ "theta_gt_1",
      .data$theta_active < 1 - THETA_TOL ~ "theta_lt_1",
      TRUE ~ "theta_near_1"
    )
  ) %>%
  select(
    -regime_code_struct,
    -theta_r1_struct,
    -theta_r2_struct,
    -theta_active_struct,
    -mu_struct,
    -y_struct,
    -k_nr_struct,
    -y_p_struct,
    -u_struct,
    -wsh_struct
  )


# Chi classification uses sample distribution over the active annual panel.
chi_cut_strong <- quantile(annual_diagnostic_panel$chi, probs = CHI_STRONG_Q, na.rm = TRUE)
chi_cut_weak   <- quantile(annual_diagnostic_panel$chi, probs = CHI_WEAK_Q, na.rm = TRUE)
D_cut_high     <- quantile(annual_diagnostic_panel$D, probs = HIGH_DYSFUNCTION_Q, na.rm = TRUE)
F_cut_high     <- quantile(annual_diagnostic_panel$F_rev, probs = HIGH_FRAGILITY_Q, na.rm = TRUE)

annual_diagnostic_panel <- annual_diagnostic_panel %>%
  mutate(
    chi_state = case_when(
      is.na(chi) ~ NA_character_,
      chi >= chi_cut_strong ~ "strong",
      chi <= chi_cut_weak   ~ "weak_or_blocked",
      TRUE ~ "intermediate"
    ),
    dysfunctionality_state = case_when(
      D >= D_cut_high & F_rev >= F_cut_high ~ "grossly_dysfunctional",
      D >= D_cut_high & F_rev < F_cut_high  ~ "offsetting",
      D < D_cut_high  & F_rev >= F_cut_high ~ "reversal_prone",
      TRUE ~ "contained"
    ),
    net_motion_state = case_when(
      N > 0 ~ "profitability_rising",
      N < 0 ~ "profitability_falling",
      TRUE  ~ "full_cancellation"
    ),
    dominant_motion_component = NA_character_,
    dominant_offsetting_component = NA_character_,
    dominant_net_component = NA_character_
  )

# Fill dominant-component fields from component_long
annual_dom_motion <- component_long %>%
  group_by(year) %>%
  slice_max(order_by = abs_value, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(year, dominant_motion_component = component_family)

annual_dom_offset <- component_long %>%
  group_by(year) %>%
  slice_max(order_by = offsetting_abs, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(year, dominant_offsetting_component = if_else(offsetting_abs > 0, component_family, NA_character_))

annual_dom_net <- component_long %>%
  mutate(net_signed_push = if_else(contributes_to_net_direction, abs_value, 0)) %>%
  group_by(year) %>%
  slice_max(order_by = net_signed_push, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(year, dominant_net_component = if_else(net_signed_push > 0, component_family, NA_character_))

annual_diagnostic_panel <- annual_diagnostic_panel %>%
  select(-dominant_motion_component, -dominant_offsetting_component, -dominant_net_component) %>%
  left_join(annual_dom_motion, by = "year") %>%
  left_join(annual_dom_offset, by = "year") %>%
  left_join(annual_dom_net, by = "year")

# ============================================================
# 8. SWING-LEVEL SOURCE TRACE AND DIAGNOSTIC SUMMARY
# ============================================================

swing_component_trace <- component_long %>%
  group_by(swing_id, component_family) %>%
  summarise(
    n_years = n(),
    total_abs_motion = safe_sum(abs_value),
    total_signed_contribution = safe_sum(value),
    total_offsetting_abs = safe_sum(offsetting_abs),
    total_reinforcing_abs = safe_sum(reinforcing_abs),
    mean_share_total_motion = safe_mean(share_of_total_motion),
    mean_share_offsetting = safe_mean(share_of_offsetting_motion),
    .groups = "drop"
  ) %>%
  group_by(swing_id) %>%
  mutate(
    motion_rank = min_rank(desc(total_abs_motion)),
    offsetting_rank = min_rank(desc(total_offsetting_abs)),
    net_rank = min_rank(desc(abs(total_signed_contribution)))
  ) %>%
  ungroup()

swing_summary_panel <- annual_diagnostic_panel %>%
  group_by(swing_id) %>%
  summarise(
    start_year = min(year, na.rm = TRUE),
    end_year   = max(year, na.rm = TRUE),
    duration_years = n(),
    period_mode = mode_chr(period),
    r_start = dplyr::first(r_struct),
    r_end   = dplyr::last(r_struct),
    swing_amplitude = r_end - r_start,
    mean_G = safe_mean(G),
    mean_N = safe_mean(N),
    mean_D = safe_mean(D),
    mean_S_off = safe_mean(S_off),
    mean_F_rev = safe_mean(F_rev),
    share_profitability_falling_years = safe_mean(N < 0),
    share_high_dysfunction_years = safe_mean(D >= D_cut_high),
    share_high_fragility_years   = safe_mean(F_rev >= F_cut_high),
    mean_theta = safe_mean(theta_active),
    mean_mu = safe_mean(mu),
    mean_chi = safe_mean(chi),
    mean_ext_bind_distance_isi = safe_mean(ext_bind_distance_isi),
    share_ext_bind_years_isi = safe_mean(ext_bind_flag_isi == 1),
    longest_ext_bind_run_isi = longest_run_true(ext_bind_flag_isi == 1),
    mean_g_k = safe_mean(g_k),
    mean_g_y = safe_mean(g_y),
    terminal_theta_state = dplyr::last(na.omit(theta_state)),
    terminal_mu_state    = dplyr::last(na.omit(mu_activation_state)),
    terminal_chi_state   = dplyr::last(na.omit(chi_state)),
    terminal_ext_state   = dplyr::last(na.omit(ext_bind_state_isi)),
    dysfunctionality_profile = mode_chr(dysfunctionality_state),
    recapitalization_profile = mode_chr(chi_state),
    .groups = "drop"
  ) %>%
  left_join(swing_tbl, by = "swing_id")

# Dominant sources by swing
swing_dom_motion <- swing_component_trace %>%
  group_by(swing_id) %>%
  slice_max(order_by = total_abs_motion, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(swing_id, dominant_motion_source = component_family)

swing_dom_offset <- swing_component_trace %>%
  group_by(swing_id) %>%
  slice_max(order_by = total_offsetting_abs, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(swing_id, dominant_offsetting_source = component_family)

swing_dom_net <- swing_component_trace %>%
  group_by(swing_id) %>%
  slice_max(order_by = abs(total_signed_contribution), n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(swing_id, dominant_net_source = component_family)

swing_summary_panel <- swing_summary_panel %>%
  left_join(swing_dom_motion, by = "swing_id") %>%
  left_join(swing_dom_offset, by = "swing_id") %>%
  left_join(swing_dom_net, by = "swing_id") %>%
  mutate(
    crisis_stage = case_when(
      mean_N < 0 & mean_D >= D_cut_high & mean_F_rev >= F_cut_high &
        share_ext_bind_years_isi >= 0.5 & recapitalization_profile == "weak_or_blocked" ~ "structural_crisis_signal",
      mean_N < 0 & mean_D >= D_cut_high ~ "partial_crisis_signal",
      mean_D >= D_cut_high | mean_F_rev >= F_cut_high ~ "stagnation_tendency_signal",
      TRUE ~ "contained_or_offset"
    )
  )

# ============================================================
# 9. COLLAPSED-PERIOD FINAL CLASSIFICATION OBJECT
# ============================================================

period_summary_panel <- annual_diagnostic_panel %>%
  filter(!is.na(period)) %>%
  group_by(period) %>%
  summarise(
    start_year = min(year),
    end_year   = max(year),
    mean_N = safe_mean(N),
    mean_D = safe_mean(D),
    mean_F_rev = safe_mean(F_rev),
    mean_theta = safe_mean(theta_active),
    mean_mu = safe_mean(mu),
    mean_chi = safe_mean(chi),
    share_ext_bind_years_isi = safe_mean(ext_bind_flag_isi == 1),
    longest_ext_bind_run_isi = longest_run_true(ext_bind_flag_isi == 1),
    mean_g_k = safe_mean(g_k),
    mean_g_y = safe_mean(g_y),
    dysfunctionality_profile = mode_chr(dysfunctionality_state),
    recapitalization_profile = mode_chr(chi_state),
    theta_profile = mode_chr(theta_state),
    mu_profile = mode_chr(mu_activation_state),
    external_constraint = case_when(
      share_ext_bind_years_isi >= 0.67 ~ "external_structural_bind",
      share_ext_bind_years_isi >= 0.33 ~ "heightened_external_pressure",
      TRUE ~ "no_major_external_bind"
    ),
    .groups = "drop"
  ) %>%
  left_join(collapsed_periods, by = "period")

period_dom_sources <- component_long %>%
  filter(!is.na(period)) %>%
  group_by(period, component_family) %>%
  summarise(
    total_abs_motion = safe_sum(abs_value),
    total_offsetting_abs = safe_sum(offsetting_abs),
    total_signed_contribution = safe_sum(value),
    .groups = "drop"
  )

period_dom_motion <- period_dom_sources %>%
  group_by(period) %>%
  slice_max(order_by = total_abs_motion, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(period, dominant_motion_source = component_family)

period_dom_offset <- period_dom_sources %>%
  group_by(period) %>%
  slice_max(order_by = total_offsetting_abs, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(period, dominant_offsetting_source = component_family)

period_dom_net <- period_dom_sources %>%
  group_by(period) %>%
  slice_max(order_by = abs(total_signed_contribution), n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(period, dominant_net_source = component_family)

period_classification_panel <- period_summary_panel %>%
  left_join(period_dom_motion, by = "period") %>%
  left_join(period_dom_offset, by = "period") %>%
  left_join(period_dom_net, by = "period") %>%
  mutate(
    final_class = case_when(
      profit_swing_class == "crisis_breakdown" & external_constraint == "external_structural_bind" & recapitalization_profile == "weak_or_blocked" ~ "structural_crisis_breakdown",
      profit_swing_class %in% c("forced_offset", "structural_fragility") & dysfunctionality_profile %in% c("grossly_dysfunctional", "reversal_prone") ~ "fragile_offset_under_stress",
      profit_swing_class == "contradictory_expansion" & dysfunctionality_profile %in% c("offsetting", "grossly_dysfunctional") ~ "contradictory_expansion_under_tension",
      profit_swing_class == "stagnation_tendency" ~ "stagnation_tendency_phase",
      TRUE ~ profit_swing_class
    )
  ) %>%
  select(
    period,
    profit_swing_class,
    dysfunctionality_profile,
    recapitalization_profile,
    external_constraint,
    dominant_motion_source,
    dominant_offsetting_source,
    dominant_net_source,
    theta_profile,
    mu_profile,
    mean_g_k,
    mean_g_y,
    final_class
  )

# ============================================================
# 10. CROSSWALK FOR LATER CLASS-STRUGGLE MERGE
# ============================================================

crosswalk_year_swing_period <- annual_diagnostic_panel %>%
  transmute(
    year,
    swing_id,
    period,
    profit_rate = r_struct,
    net_motion_state,
    dysfunctionality_state,
    theta_state,
    mu_activation_state,
    chi_state,
    ext_bind_state_isi
  )

# ============================================================
# 11. EXPORTS
# ============================================================

write_csv(annual_diagnostic_panel, file.path(out_csv, "annual_diagnostic_panel.csv"))
write_csv(component_long, file.path(out_csv, "annual_component_trace_panel.csv"))
write_csv(swing_component_trace, file.path(out_csv, "swing_source_trace_panel.csv"))
write_csv(swing_summary_panel, file.path(out_csv, "swing_summary_panel.csv"))
write_csv(period_summary_panel, file.path(out_csv, "period_summary_panel.csv"))
write_csv(period_classification_panel, file.path(out_csv, "period_classification_panel.csv"))
write_csv(crosswalk_year_swing_period, file.path(out_csv, "crosswalk_year_swing_period.csv"))

# ============================================================
# 12. FIGURES
# ============================================================

base_theme <- function() {
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      plot.title = element_blank()
    )
}

save_dual <- function(plot_obj, stem, width = 8.5, height = 4.8) {
  ggsave(file.path(out_figs, paste0(stem, ".png")), plot_obj, width = width, height = height, dpi = 320)
  ggsave(file.path(out_figs, paste0(stem, ".pdf")), plot_obj, width = width, height = height)
}

fig_diag <- annual_diagnostic_panel %>%
  filter(year >= 1940, year <= 1978) %>%
  ggplot(aes(x = year)) +
  geom_line(aes(y = D, color = "Dysfunctionality (D)"), linewidth = 0.9) +
  geom_line(aes(y = F_rev, color = "Reversal fragility"), linewidth = 0.9, linetype = "dashed") +
  geom_vline(xintercept = c(1946, 1949, 1955, 1961, 1969, 1972, 1974, 1976, 1978), linetype = "dotted", linewidth = 0.3) +
  scale_color_manual(values = c("Dysfunctionality (D)" = "black", "Reversal fragility" = "#D55E00"), name = NULL) +
  labs(y = "Index value") +
  base_theme()

save_dual(fig_diag, "fig_dysfunctionality_1940_1978")

fig_struct <- annual_diagnostic_panel %>%
  filter(year >= 1940, year <= 1978) %>%
  {
    df <- .
    pmin <- min(df$theta_active, na.rm = TRUE)
    pmax <- max(df$theta_active, na.rm = TRUE)
    smin <- min(df$mu, na.rm = TRUE)
    smax <- max(df$mu, na.rm = TRUE)
    df$mu_scaled <- rescale_to_primary(df$mu, smin, smax, pmin, pmax)
    ggplot(df, aes(x = year)) +
      geom_line(aes(y = theta_active, color = "theta"), linewidth = 0.9) +
      geom_line(aes(y = mu_scaled, color = "mu"), linewidth = 0.9, linetype = "dashed") +
      geom_hline(yintercept = 1, linewidth = 0.3, linetype = "dotted") +
      scale_y_continuous(
        name = "theta",
        sec.axis = sec_axis(~ inverse_rescale(., smin, smax, pmin, pmax), name = "mu")
      ) +
      scale_color_manual(values = c(theta = "black", mu = "#0072B2"), name = NULL) +
      base_theme()
  }

save_dual(fig_struct, "fig_theta_mu_1940_1978")

fig_growth <- annual_diagnostic_panel %>%
  filter(year >= 1940, year <= 1978) %>%
  ggplot(aes(x = year)) +
  geom_line(aes(y = g_k, color = "Accumulation rate (g_k)"), linewidth = 0.9) +
  geom_line(aes(y = g_y, color = "Growth rate (g_y)"), linewidth = 0.9, linetype = "dashed") +
  scale_color_manual(values = c("Accumulation rate (g_k)" = "black", "Growth rate (g_y)" = "#009E73"), name = NULL) +
  labs(y = "Rate") +
  base_theme()

save_dual(fig_growth, "fig_growth_accumulation_1940_1978")

# ============================================================
# 13. SESSION SUMMARY
# ============================================================

summary_lines <- c(
  "Chile diagnostic package completed.",
  "",
  "Structural lock:",
  paste0(" - Governing pre-1974 structural sample = ", GOV_SAMPLE_PRE1974),
  paste0(" - ISI threshold gamma = ", GAMMA_ISI),
  paste0(" - Pinch year for rescued utilization path = ", PINCH_YEAR),
  "",
  "Required profitability primitives used to build the motion panel:",
  paste0(" - ", required_profit_primitives),
  "",
  "Core exports:",
  " - csv/annual_diagnostic_panel.csv",
  " - csv/annual_component_trace_panel.csv",
  " - csv/swing_source_trace_panel.csv",
  " - csv/swing_summary_panel.csv",
  " - csv/period_summary_panel.csv",
  " - csv/period_classification_panel.csv",
  " - csv/crosswalk_year_swing_period.csv",
  "",
  "Figures:",
  " - figs/fig_dysfunctionality_1940_1978.(png/pdf)",
  " - figs/fig_theta_mu_1940_1978.(png/pdf)",
  " - figs/fig_growth_accumulation_1940_1978.(png/pdf)",
  "",
  "Notes:",
  " - mu is the rescued capacity-utilization path under the threshold-theta splice.",
  " - ext_bind_flag_isi is oriented so ECT <= gamma_isi denotes the bind side.",
  " - Class-struggle integration is deferred to a later join through the crosswalk."
)

write_txt(summary_lines, file.path(out_txt, "diagnostic_package_summary.txt"))
cat(paste(summary_lines, collapse = "\n"), "\n")
