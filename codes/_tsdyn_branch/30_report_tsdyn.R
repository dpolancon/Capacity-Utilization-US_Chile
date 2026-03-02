# ============================================================
# 30_report_tsdyn.R — Engine-based IC_xi_eta Report (tsDyn)
#
# REBUILT TO REQUIRE ONLY ENGINE OUTPUTS:
#   Inputs (csv/):
#     - APPX_rank_profile_full.csv
#     - APPX_report_p_feasible_from_engine.csv  (preferred)
#       OR APPX_p_feasibility_summary.csv       (fallback)
#
# Outputs (csv/):
#   - APPX_grid_ic_xi_eta_soft.csv
#   - APPX_report_best_rank_by_window.csv
#   - APPX_report_rank_pressure_r1_vs_r2plus.csv
#   - APPX_report_postfordism_highrank_flag.csv
#   - APPX_report_postfordism_rank_shift_diagnostic.csv
#   - APPX_report_postfordism_confinement_candidates.csv
# ============================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tidyr)
})

here::i_am("codes/30_report_tsdyn.R")
source(here::here("codes","10_config_tsdyn.R"))

`%||%` <- get0("%||%", ifnotfound = function(a,b) if (is.null(a)) b else a)

ROOT_OUT <- here::here(CONFIG$OUT_TSDYN %||% "output/TsDynEngine")
DIRS <- list(csv = file.path(ROOT_OUT,"csv"),
             logs = file.path(ROOT_OUT,"logs"))
dir.create(DIRS$csv, recursive=TRUE, showWarnings=FALSE)
dir.create(DIRS$logs, recursive=TRUE, showWarnings=FALSE)

cat("=== 30_report_tsdyn (engine-only IC_xi_eta) start ===\n")

# ------------------------------------------------------------
# Settings (keep editable for sprint)
# ------------------------------------------------------------
# Default: eta=1, xi uses your locked functional form idea if present
ETA <- as.numeric(CONFIG$ETA %||% 1.0)

# If you already locked xi = 1 + r/(m-r), do it here; else xi=1.
XI_MODE <- CONFIG$XI_MODE %||% "rank_ratio"  # "rank_ratio" or "one"
xi_fun <- function(r, m) {
  if (XI_MODE == "rank_ratio") {
    # safe-guard: r <= m-1 always in grid
    1 + (r / pmax(1, (m - r)))
  } else {
    1.0
  }
}

slice_keys <- c("spec","basis","window","det_tag")

# ------------------------------------------------------------
# Load rank profile (engine lattice)
# ------------------------------------------------------------
rank_path <- file.path(DIRS$csv, "APPX_rank_profile_full.csv")
rank_df <- readr::read_csv(rank_path, show_col_types = FALSE)

stopifnot(all(c("spec","basis","window","det_tag","p","r","logLik","k_total","k_longrun","T_window","T_eff","m","status") %in% names(rank_df)))

# keep only computed rows with finite ll
rank_df <- rank_df %>%
  filter(status == "computed", is.finite(logLik))

# ------------------------------------------------------------
# Load feasibility summary
# ------------------------------------------------------------
feas_path1 <- file.path(DIRS$csv, "APPX_report_p_feasible_from_engine.csv")
feas_path2 <- file.path(DIRS$csv, "APPX_p_feasibility_summary.csv")

if (file.exists(feas_path1)) {
  feas_df <- readr::read_csv(feas_path1, show_col_types = FALSE)
} else if (file.exists(feas_path2)) {
  feas_df <- readr::read_csv(feas_path2, show_col_types = FALSE)
} else {
  stop("Missing feasibility CSV: expected APPX_report_p_feasible_from_engine.csv or APPX_p_feasibility_summary.csv")
}

# standardize required cols
stopifnot(all(c("spec","basis","window","det_tag") %in% names(feas_df)))
pmax_col <- if ("p_max_feasible" %in% names(feas_df)) "p_max_feasible" else
  if ("p_max_feasible_r1" %in% names(feas_df)) "p_max_feasible_r1" else NA_character_

if (is.na(pmax_col)) {
  stop("Feasibility summary missing p_max_feasible (or p_max_feasible_r1). Cannot build comparable domain.")
}

feas_df <- feas_df %>%
  mutate(p_max_feasible = as.integer(.data[[pmax_col]])) %>%
  select(spec,basis,window,det_tag,p_max_feasible)

# ------------------------------------------------------------
# Comparable domain: common_p_max per (spec,basis,det_tag)
# ------------------------------------------------------------
common_p <- feas_df %>%
  group_by(spec,basis,det_tag) %>%
  summarise(common_p_max = min(p_max_feasible, na.rm=TRUE), .groups="drop")

# attach feasible p ceilings
rank_df <- rank_df %>%
  left_join(common_p, by=c("spec","basis","det_tag")) %>%
  filter(p <= common_p_max)

# ------------------------------------------------------------
# Compute IC_xi_eta from ENGINE bookkeeping only
# We only have:
#   k_total, k_longrun
# We split:
#   k_rank = k_longrun
#   k_other = k_total - k_longrun  (lags + deterministics lumped)
#
# Fit term:
#   -2*logLik
# Penalty:
#   log(T_eff_common) * ( xi*k_other + eta*k_rank )
#
# IMPORTANT: enforce common T_eff within slice using p_max (slice-level)
# ------------------------------------------------------------
# slice-level T_eff_common = T_window - common_p_max (per window slice)
rank_df <- rank_df %>%
  left_join(
    feas_df %>% rename(p_max_feasible_window = p_max_feasible),
    by=c("spec","basis","window","det_tag")
  ) %>%
  mutate(
    T_eff_common = as.integer(T_window - p_max_feasible_window),
    k_rank  = as.numeric(k_longrun),
    k_other = as.numeric(k_total - k_longrun),
    xi_val  = xi_fun(r, m),
    IC_xi_eta = (-2.0*logLik) + log(pmax(5, T_eff_common)) * (xi_val*k_other + ETA*k_rank)
  ) %>%
  filter(is.finite(IC_xi_eta))

grid_df <- rank_df %>%
  select(spec,basis,window,det_tag,p,r,m,T_window,T_eff_common,logLik,k_total,k_longrun,k_rank,k_other,xi_val,IC_xi_eta)

write_csv(grid_df, file.path(DIRS$csv, "APPX_grid_ic_xi_eta_soft.csv"))

# ------------------------------------------------------------
# ΔIC within slice + winners
# ------------------------------------------------------------
grid_df <- grid_df %>%
  group_by(across(all_of(slice_keys))) %>%
  mutate(
    IC_min = min(IC_xi_eta),
    delta_IC = IC_xi_eta - IC_min
  ) %>%
  ungroup()

winners <- grid_df %>% filter(delta_IC == 0)

# Best rank by window (tie-break: smaller r, then smaller p)
best_by_window <- winners %>%
  group_by(across(all_of(slice_keys))) %>%
  arrange(r, p, .by_group=TRUE) %>%
  slice_head(n=1) %>%
  ungroup() %>%
  transmute(spec,basis,window,det_tag,
            r_star = r,
            IC_star = IC_xi_eta,
            p_star = p)

write_csv(best_by_window, file.path(DIRS$csv, "APPX_report_best_rank_by_window.csv"))

# ------------------------------------------------------------
# Rank pressure: r=1 vs best of r>=2 within slice
# pressure_highrank > 0  => r=1 preferred (confinement-friendly)
# pressure_highrank < 0  => higher rank preferred
# ------------------------------------------------------------
rank_pressure <- grid_df %>%
  group_by(across(all_of(slice_keys))) %>%
  summarise(
    IC_r1    = suppressWarnings(min(IC_xi_eta[r == 1], na.rm=TRUE)),
    IC_r2plus= suppressWarnings(min(IC_xi_eta[r >= 2], na.rm=TRUE)),
    .groups="drop"
  ) %>%
  mutate(
    IC_r1 = ifelse(is.infinite(IC_r1), NA_real_, IC_r1),
    IC_r2plus = ifelse(is.infinite(IC_r2plus), NA_real_, IC_r2plus),
    pressure_highrank = IC_r2plus - IC_r1
  )

write_csv(rank_pressure, file.path(DIRS$csv, "APPX_report_rank_pressure_r1_vs_r2plus.csv"))

# ------------------------------------------------------------
# Post-Fordism high-rank flag (r_star >= 2 in post_fordism)
# ------------------------------------------------------------
post_flag <- best_by_window %>%
  mutate(postfordism_highrank = (window == "post_fordism" & r_star >= 2))

write_csv(post_flag, file.path(DIRS$csv, "APPX_report_postfordism_highrank_flag.csv"))

# ------------------------------------------------------------
# Post-Fordism "higher rank dimension?" diagnostic
# Compare r_star across windows within (spec,basis,det_tag)
# ------------------------------------------------------------
rank_shift <- best_by_window %>%
  select(spec,basis,window,det_tag,r_star) %>%
  tidyr::pivot_wider(names_from = window, values_from = r_star,
                     names_prefix = "r_") %>%
  mutate(
    post_higher_than_fordism = ifelse(!is.na(r_post_fordism) & !is.na(r_fordism),
                                      r_post_fordism > r_fordism, NA),
    post_higher_than_full    = ifelse(!is.na(r_post_fordism) & !is.na(r_full),
                                      r_post_fordism > r_full, NA)
  ) %>%
  transmute(spec,basis,det_tag,
            r_fordism = r_fordism,
            r_full    = r_full,
            r_post    = r_post_fordism,
            post_higher_than_fordism,
            post_higher_than_full)

write_csv(rank_shift, file.path(DIRS$csv, "APPX_report_postfordism_rank_shift_diagnostic.csv"))

# ------------------------------------------------------------
# Confinement candidates for post-fordism:
#   - window == post_fordism
#   - r_star == 1  (target confinement)
#   - allow p_star to be >1 (your practical need)
#   - pressure_highrank > 0 (r=1 beats r>=2)
# ------------------------------------------------------------
candidates <- best_by_window %>%
  filter(window == "post_fordism") %>%
  left_join(rank_pressure, by=c("spec","basis","window","det_tag")) %>%
  left_join(common_p, by=c("spec","basis","det_tag")) %>%
  mutate(
    r1_is_winner = (r_star == 1),
    needs_higher_p = (p_star > 1),
    confinement_friendly = (r1_is_winner & !is.na(pressure_highrank) & pressure_highrank > 0)
  ) %>%
  arrange(desc(confinement_friendly), desc(needs_higher_p), desc(pressure_highrank)) %>%
  select(spec,basis,det_tag,
         r_star,p_star,IC_star,
         pressure_highrank, common_p_max,
         r1_is_winner, needs_higher_p, confinement_friendly)

write_csv(candidates, file.path(DIRS$csv, "APPX_report_postfordism_confinement_candidates.csv"))

cat("=== 30_report_tsdyn complete ===\n")
cat("Wrote: APPX_grid_ic_xi_eta_soft.csv\n")
cat("Wrote: APPX_report_best_rank_by_window.csv\n")
cat("Wrote: APPX_report_rank_pressure_r1_vs_r2plus.csv\n")
cat("Wrote: APPX_report_postfordism_highrank_flag.csv\n")
cat("Wrote: APPX_report_postfordism_rank_shift_diagnostic.csv\n")
cat("Wrote: APPX_report_postfordism_confinement_candidates.csv\n")