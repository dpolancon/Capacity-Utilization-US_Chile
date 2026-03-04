# ============================================================
# UPDATED 28_results_pack_generator.R
# - Uses CONFIG paths
# - Uses 99_utils safe_read_csv (base R) and det_pairs if needed later
# - Uses export_table_bundle(CONFIG, ...)
# ============================================================


# ---------------------------
# Source config + utils (RENAMED)
# ---------------------------
source(here::here("codes","10_config.R"))
source(here::here("codes","99_utils.R"))


suppressPackageStartupMessages({
  library("readr")
  library("dplyr")
  library("stringr")
  library("purrr")
  library("readr")
})


if (!exists("CONFIG")) stop("CONFIG not found. Did you source codes/10_config.R ?", call. = FALSE)

OUT_ROOT <- CONFIG$OUT_CR_ROOT
RUN_ID <- Sys.getenv("CR_RUN_ID", unset = paste0("stage4_", format(Sys.time(), "%Y%m%d_%H%M%S")))
RUN_ROOT <- Sys.getenv("CR_RUN_ROOT", unset = file.path(OUT_ROOT, paste0("run_", RUN_ID)))

PACK_ROOT   <- file.path(RUN_ROOT, "ResultsPack")
PACK_TABLES <- file.path(PACK_ROOT, "tables")
PACK_FIGS   <- file.path(PACK_ROOT, "figs")
PACK_DATA   <- file.path(PACK_ROOT, "data")
dir.create(PACK_TABLES, recursive = TRUE, showWarnings = FALSE)
dir.create(PACK_FIGS, recursive = TRUE, showWarnings = FALSE)
dir.create(PACK_DATA, recursive = TRUE, showWarnings = FALSE)

# ---- Paths (CONFIG aware) ----
S1_series_path <- file.path(CONFIG$OUT_CR$exercise_a, "csv",
                            "SHAIKH_ARDL_replication_series_shaikh_window.csv")
S1_four_series_path <- file.path(CONFIG$OUT_CR$exercise_a, "csv",
                                 "SHAIKH_ARDL_replication_four_series_shaikh_window.csv")
S1_spec_report_path <- file.path(CONFIG$OUT_CR$exercise_a, "csv",
                                 "SHAIKH_ARDL_replication_spec_report_shaikh_window.csv")

XW_faithful_path <- file.path(CONFIG$OUT_CR$crosswalk, "faithful_ardl_2_4.csv")
XW_core_path     <- file.path(CONFIG$OUT_CR$crosswalk, "crosswalk_representatives.csv")

S2_geom_path  <- file.path(CONFIG$OUT_CR$exercise_b, "csv", "GEOMETRY_CARDS_ARDL.csv")
S2_env_k_path <- file.path(CONFIG$OUT_CR$exercise_b, "csv", "ENVELOPE_ARDL_logLik_vs_k_total.csv")
S2_env_i_path <- file.path(CONFIG$OUT_CR$exercise_b, "csv", "ENVELOPE_ARDL_logLik_vs_ICOMP_pen.csv")
S2_env_r_path <- file.path(CONFIG$OUT_CR$exercise_b, "csv", "ENVELOPE_ARDL_logLik_vs_RICOMP_pen.csv")

S3_root <- CONFIG$OUT_CR$exercise_c
S4_root <- CONFIG$OUT_CR$exercise_d

# ---- Local helper: harmonize names minimally (do not fight your pipeline) ----
harmonize_names <- function(df) {
  if (is.null(df)) return(NULL)

  alias_map <- c(
    theta = "theta_hat",
    lambda = "alpha_hat",
    lambda_hat = "alpha_hat",
    ICOMP = "ICOMP_pen",
    RICOMP = "RICOMP_pen",
    k = "k_total"
  )

  nm <- names(df)
  idx_theta_dot <- which(nm == "theta.hat")
  if (length(idx_theta_dot) > 0L && !"theta_hat" %in% nm) nm[idx_theta_dot] <- "theta_hat"
  idx_lambda_dot <- which(nm == "lambda.hat")
  if (length(idx_lambda_dot) > 0L && !"alpha_hat" %in% nm) nm[idx_lambda_dot] <- "alpha_hat"

  for (alias in names(alias_map)) {
    canonical <- alias_map[[alias]]
    alias_idx <- which(nm == alias)
    if (length(alias_idx) == 0L) next

    if (canonical %in% nm) {
      nm[alias_idx] <- paste0(alias, "__alias_drop")
    } else {
      nm[alias_idx] <- canonical
    }
  }

  names(df) <- nm
  alias_drop <- grepl("__alias_drop$", names(df))
  if (any(alias_drop)) {
    df <- df[, !alias_drop, drop = FALSE]
  }

  names(df) <- make.unique(names(df), sep = "__dup")
  df
}

assert_unique_names <- function(df, context) {
  if (is.null(df)) return(invisible(NULL))
  dup_idx <- anyDuplicated(names(df))
  if (dup_idx > 0L) {
    msg <- sprintf("TAB_S2 duplicate columns in '%s' (first duplicate: '%s').", context, names(df)[dup_idx])
    warning(msg, call. = FALSE)
    stop(msg, call. = FALSE)
  }
  invisible(NULL)
}


with_source <- function(df, source_file) {
  if (is.null(df)) return(NULL)
  df %>% mutate(source_file = source_file, .before = 1)
}

clean_for_paper <- function(df, allowed_cols = NULL) {
  if (is.null(df)) return(NULL)
  drop_pat <- grepl("(\\.1$|_geom$)", names(df))
  path_like <- grepl("(^source_file$|_path$|_file$)", names(df))
  df <- df[, !(drop_pat | path_like), drop = FALSE]
  if (!is.null(allowed_cols)) {
    keep <- intersect(allowed_cols, names(df))
    df <- df[, keep, drop = FALSE]
  }
  df
}

pick_winners <- function(df,
                         delta_col_candidates = c("dICOMP","dRICOMP","dBIC","dAIC","dIC_eta"),
                         max_rows = 5,
                         band = 2) {
  if (is.null(df)) return(NULL)
  dcol <- delta_col_candidates[delta_col_candidates %in% names(df)][1]
  if (is.na(dcol)) {
    ic_cols <- c("RICOMP_pen","ICOMP_pen","BIC","AIC","IC_eta","k_total")
    ic_col <- ic_cols[ic_cols %in% names(df)][1]
    if (is.na(ic_col)) return(df %>% slice_head(n = min(nrow(df), max_rows)))
    return(df %>% arrange(.data[[ic_col]]) %>% slice_head(n = min(nrow(df), max_rows)))
  }
  df %>%
    mutate(.delta = .data[[dcol]]) %>%
    arrange(.delta) %>%
    filter(.delta <= band) %>%
    slice_head(n = min(nrow(.), max_rows)) %>%
    select(-.delta)
}

# ============================================================
# TAB_S1 — faithful replication key stats
# ============================================================
s1_spec_report <- harmonize_names(with_source(
  if (file.exists(S1_spec_report_path)) safe_read_csv(S1_spec_report_path) else NULL,
  S1_spec_report_path
))

s1_faithful <- harmonize_names(with_source(
  if (file.exists(XW_faithful_path)) safe_read_csv(XW_faithful_path) else NULL,
  XW_faithful_path
))

s1_series <- if (file.exists(S1_series_path)) safe_read_csv(S1_series_path) else NULL
s1_four_series <- if (file.exists(S1_four_series_path)) safe_read_csv(S1_four_series_path) else NULL

TAB_S1 <- NULL
if (!is.null(s1_spec_report) && nrow(s1_spec_report) > 0) {
  TAB_S1 <- s1_spec_report %>%
    mutate(run_id = RUN_ID, stage_tag = "S1_ARDL_faithful", .before = 1)
} else if (!is.null(s1_faithful)) {
  warning("S1 spec report CSV missing; falling back to faithful crosswalk file.", call. = FALSE)
  TAB_S1 <- s1_faithful %>%
    mutate(run_id = RUN_ID, stage_tag = "S1_ARDL_faithful", window_tag = "shaikh_window") %>%
    select(run_id, stage_tag, window_tag, everything())
} else if (!is.null(s1_series)) {
  warning("S1 spec report + crosswalk missing; using minimal series fallback (limited inference fields).", call. = FALSE)
  nm <- names(s1_series)
  uhat_col <- nm[str_detect(nm, "u_hat|u\\.hat|u_est|u_pred")][1]
  ush_col  <- nm[str_detect(nm, "^u_shaikh$|u_shaikh")][1]
  corr_val <- NA_real_
  if (!is.na(uhat_col) && !is.na(ush_col)) {
    corr_val <- suppressWarnings(cor(s1_series[[uhat_col]], s1_series[[ush_col]], use = "complete.obs"))
  }
  TAB_S1 <- tibble::tibble(
    run_id = RUN_ID,
    stage_tag = "S1_ARDL_faithful",
    window_tag = "shaikh_window",
    spec_id = "ARDL_2_4_faithful",
    theta_hat = NA_real_,
    theta_pvalue = NA_real_,
    alpha_hat = NA_real_,
    boundsF_stat = NA_real_,
    boundsF_pvalue = NA_real_,
    boundsT_stat = NA_real_,
    boundsT_pvalue = NA_real_,
    u_hat_corr_u_shaikh = corr_val,
    source_file = S1_series_path
  )
}
if (is.null(TAB_S1)) stop("TAB_S1 failed: spec-report, faithful crosswalk, and series files are all missing.", call. = FALSE)

TAB_S1 <- clean_for_paper(TAB_S1)

TAB_S1 <- clean_for_paper(TAB_S1)

export_table_bundle(
  CONFIG, TAB_S1,
  name = "TAB_S1_replication_key_stats",
  tables_dir = PACK_TABLES,
  caption = "Faithful replication anchor statistics.",
  stage_tag = "S1_ARDL_faithful",
  run_id = RUN_ID,
  footnote = "Outputs from Exercise A (ARDL faithful replication)."
)

if (!is.null(s1_four_series) && nrow(s1_four_series) > 0) {
  data_copy_path <- file.path(PACK_DATA, "DATA_S1_ARDL_four_series.csv")
  readr::write_csv(s1_four_series, data_copy_path)
  tryCatch({
    append_results_pack_export_log(CONFIG, RUN_ID, "S1_ARDL_faithful", "data_csv", data_copy_path,
                                   caption = "S1 ARDL four-series reproducible dataset")
  }, error = function(e) {
    warning("S1 four-series manifest logging failed: ", conditionMessage(e), call. = FALSE)
  })
}

# ============================================================
# TAB_S2 — frontier summary by IC (envelope representatives)
# ============================================================
s2_geom  <- harmonize_names(with_source(if (file.exists(S2_geom_path))  safe_read_csv(S2_geom_path)  else NULL, S2_geom_path))
s2_env_k <- harmonize_names(with_source(if (file.exists(S2_env_k_path)) safe_read_csv(S2_env_k_path) else NULL, S2_env_k_path))
s2_env_i <- harmonize_names(with_source(if (file.exists(S2_env_i_path)) safe_read_csv(S2_env_i_path) else NULL, S2_env_i_path))
s2_env_r <- harmonize_names(with_source(if (file.exists(S2_env_r_path)) safe_read_csv(S2_env_r_path) else NULL, S2_env_r_path))

bind_env <- function(df, ic_family) {
  if (is.null(df)) return(NULL)
  src <- NA_character_
  if ("source_file" %in% names(df) && nrow(df) > 0L) {
    src <- unique(as.character(df$source_file))[1]
  }
  ctx <- if (is.na(src) || identical(src, "")) paste0("ic_family=", ic_family) else src
  assert_unique_names(df, paste0("bind_env pre-mutate @ ", ctx))
  df %>%
    mutate(run_id = RUN_ID,
           stage_tag = "S2_ARDL_grid",
           ic_family = ic_family,
           on_frontier = 1L)
}

S2_env_all <- dplyr::bind_rows(
  bind_env(s2_env_k, "k_total"),
  bind_env(s2_env_i, "ICOMP"),
  bind_env(s2_env_r, "RICOMP")
)
assert_unique_names(S2_env_all, "S2_env_all (pre-mutate)")
if (is.null(S2_env_all) || nrow(S2_env_all) == 0) stop("TAB_S2 failed: missing ARDL envelope files.", call. = FALSE)

TAB_S2 <- S2_env_all
if (!is.null(s2_geom)) {
  join_keys <- intersect(names(S2_env_all), names(s2_geom))
  join_keys <- join_keys[join_keys %in% c("spec_id","p","q")]
  if (length(join_keys) > 0) {
    TAB_S2 <- S2_env_all %>%
      left_join(s2_geom, by = join_keys, suffix = c("", "_geom"))
  }
}

TAB_S2 <- clean_for_paper(TAB_S2, allowed_cols = c(
  "run_id","stage_tag","ic_family","window_tag","spec_id","p","q",
  "theta_hat","lambda_hat","AIC","BIC","ICOMP_pen","RICOMP_pen",
  "ICOMP_IC","RICOMP_IC","k_total","sK_ardl"
))

export_table_bundle(
  CONFIG, TAB_S2,
  name = "TAB_S2_frontier_summary_by_IC",
  tables_dir = PACK_TABLES,
  caption = "ARDL grid frontier representatives under alternative information criteria.",
  stage_tag = "S2_ARDL_grid",
  run_id = RUN_ID,
  footnote = "Only envelope representatives are reported. Full lattice results remain in the ARDL grid outputs."
)

# ============================================================
# TAB_S3 — confinement winners by branch (bivariate VECM r=1)
# ============================================================
S3_branches <- list.dirs(S3_root, recursive = FALSE, full.names = TRUE)
S3_branches <- S3_branches[str_detect(basename(S3_branches), "^SR_.*__LR_")]

read_s3_branch <- function(branch_dir) {
  det_tag <- basename(branch_dir)
  top_path   <- file.path(branch_dir, "csv", "TAB_top_cells_N10.csv")
  sum_path   <- file.path(branch_dir, "csv", "TAB_branch_summary.csv")
  cells_path <- file.path(branch_dir, "csv", "APPX_lattice_cells_with_deltas.csv")
  
  top_df   <- harmonize_names(with_source(if (file.exists(top_path))   safe_read_csv(top_path)   else NULL, top_path))
  sum_df   <- harmonize_names(with_source(if (file.exists(sum_path))   safe_read_csv(sum_path)   else NULL, sum_path))
  cells_df <- harmonize_names(with_source(if (file.exists(cells_path)) safe_read_csv(cells_path) else NULL, cells_path))
  
  base <- if (!is.null(top_df)) top_df else cells_df
  if (is.null(base)) return(NULL)
  
  picked <- pick_winners(base, max_rows = 5, band = 2) %>%
    mutate(run_id = RUN_ID,
           stage_tag = "S3_VECM_S1_r1",
           det_tag = det_tag,
           rank = 1L,
           .before = 1)
  
  if (!is.null(sum_df)) {
    sum_df <- sum_df %>% mutate(det_tag = det_tag)
    picked <- picked %>% left_join(sum_df, by = "det_tag", suffix = c("", "_branch"))
  }
  picked
}

TAB_S3 <- purrr::map_dfr(S3_branches, read_s3_branch)
if (nrow(TAB_S3) == 0) stop("TAB_S3 failed: no readable Stage 3 branches found.", call. = FALSE)

TAB_S3 <- clean_for_paper(TAB_S3, allowed_cols = c(
  "run_id","stage_tag","det_tag","rank","p","q_tag","logLik","BIC",
  "ICOMP_pen","RICOMP_pen","theta_hat","alpha_y","alpha_k","stability_margin","dBIC"
))

export_table_bundle(
  CONFIG, TAB_S3,
  name = "TAB_S3_confinement_winners_by_branch",
  tables_dir = PACK_TABLES,
  caption = "Bivariate VECM confinement representatives by deterministic branch.",
  stage_tag = "S3_VECM_S1_r1",
  run_id = RUN_ID,
  footnote = "Winners and near-ties selected within $\\Delta IC \\le 2$.",
  escape = FALSE
)

# ============================================================
# TAB_S4 — rank summary by branch (trivariate VECM rank sweep)
# ============================================================
S4_branches <- list.dirs(S4_root, recursive = FALSE, full.names = TRUE)
S4_branches <- S4_branches[str_detect(basename(S4_branches), "^SR_.*__LR_")]

read_s4_branch <- function(branch_dir) {
  det_tag <- basename(branch_dir)
  byrank_path <- file.path(branch_dir, "csv", "TAB_summary_by_rank.csv")
  bypqr_path  <- file.path(branch_dir, "csv", "TAB_summary_by_p_q_r.csv")
  ab_path     <- file.path(branch_dir, "csv", "TAB_alpha_beta_by_rank.csv")
  ledger_path <- file.path(branch_dir, "csv", "TAB_top_spec_selection_ledger.csv")

  df_rank <- harmonize_names(with_source(if (file.exists(byrank_path)) safe_read_csv(byrank_path) else NULL, byrank_path))
  df_pqr  <- harmonize_names(with_source(if (file.exists(bypqr_path))  safe_read_csv(bypqr_path)  else NULL, bypqr_path))
  df_ab   <- harmonize_names(with_source(if (file.exists(ab_path))     safe_read_csv(ab_path)     else NULL, ab_path))
  df_led  <- harmonize_names(with_source(if (file.exists(ledger_path)) safe_read_csv(ledger_path) else NULL, ledger_path))

  add_rank <- function(df) {
    if (is.null(df)) return(NULL)
    has_r <- "r" %in% names(df)
    has_rank <- "rank" %in% names(df)
    if (has_r && has_rank) {
      df %>% mutate(rank = dplyr::coalesce(as.integer(.data$r), as.integer(.data$rank)))
    } else if (has_r) {
      df %>% mutate(rank = as.integer(.data$r))
    } else if (has_rank) {
      df %>% mutate(rank = as.integer(.data$rank))
    } else {
      df
    }
  }

  df_rank <- add_rank(df_rank)
  df_pqr <- add_rank(df_pqr)
  df_ab <- add_rank(df_ab)
  df_led <- add_rank(df_led)

  if (!is.null(df_led) && nrow(df_led) > 0) {
    out <- df_led %>%
      mutate(run_id = RUN_ID,
             stage_tag = "S2_VECM_lnY_lnK_e",
             det_tag = det_tag,
             .before = 1)
  } else if (!is.null(df_rank) && nrow(df_rank) > 0) {
    out <- df_rank %>%
      mutate(run_id = RUN_ID,
             stage_tag = "S2_VECM_lnY_lnK_e",
             det_tag = det_tag,
             criterion = "BIC_rank_summary",
             .before = 1)
  } else if (!is.null(df_pqr) && nrow(df_pqr) > 0) {
    out <- df_pqr %>%
      mutate(run_id = RUN_ID,
             stage_tag = "S2_VECM_lnY_lnK_e",
             det_tag = det_tag,
             criterion = "BIC_by_p_q_r",
             .before = 1)
  } else {
    return(NULL)
  }

  if (!is.null(df_rank) && "rank" %in% names(out) && "rank" %in% names(df_rank)) {
    rank_ref <- df_rank %>% select(rank, best_BIC, best_AIC, n_cells)
    out <- out %>% left_join(rank_ref, by = "rank", suffix = c("", "_rank"))
  }

  if (!is.null(df_ab) && nrow(df_ab) > 0 && "rank" %in% names(out) && "rank" %in% names(df_ab)) {
    ab_ref <- df_ab %>%
      group_by(rank) %>%
      summarise(alpha_lnY = dplyr::first(alpha_lnY), alpha_lnK = dplyr::first(alpha_lnK), alpha_e = dplyr::first(alpha_e),
                beta_lnY = dplyr::first(beta_lnY), beta_lnK = dplyr::first(beta_lnK), beta_e = dplyr::first(beta_e), .groups = "drop")
    out <- out %>% left_join(ab_ref, by = "rank", suffix = c("", "_ab"))
  }

  out
}

TAB_S4 <- purrr::map_dfr(S4_branches, read_s4_branch)
if (nrow(TAB_S4) == 0) stop("TAB_S2_VECM_lnY_lnK_e failed: no readable trivariate VECM branches found.", call. = FALSE)

TAB_S4 <- clean_for_paper(TAB_S4, allowed_cols = c(
  "run_id","stage_tag","det_tag","criterion","rank","cell_id","p","q_tag",
  "best_BIC","best_AIC","n_cells","alpha_lnY","alpha_lnK","alpha_e","beta_lnY","beta_lnK","beta_e"
))

export_table_bundle(
  CONFIG, TAB_S4,
  name = "TAB_S2_VECM_lnYlnK_e_cointegration",
  tables_dir = PACK_TABLES,
  caption = "Trivariate VECM ($ln Y$, $ln K$, $e$): cointegration-relevant representatives by deterministic branch and rank.",
  stage_tag = "S2_VECM_lnY_lnK_e",
  run_id = RUN_ID,
  footnote = "Compact table: criterion-level representatives with alpha/beta cointegration terms where available.",
  escape = FALSE
)

# ============================================================
# TAB_XW — crosswalk core (already computed in Exercise 26)
# ============================================================
xw_core <- harmonize_names(with_source(if (file.exists(XW_core_path)) safe_read_csv(XW_core_path) else NULL, XW_core_path))
if (is.null(xw_core)) stop("TAB_crosswalk_core failed: missing crosswalk_representatives.csv", call. = FALSE)

TAB_XW <- xw_core %>% mutate(run_id = RUN_ID, stage_tag = "CROSSWALK_CORE", .before = 1)

export_table_bundle(
  CONFIG, TAB_XW,
  name = "TAB_crosswalk_core",
  tables_dir = PACK_TABLES,
  caption = "Crosswalk of representative specifications across ARDL and VECM systems.",
  stage_tag = "CROSSWALK_CORE",
  run_id = RUN_ID,
  footnote = "This table forms the identification bridge between single-equation and system representations."
)

# ============================================================
# FIGURE INDEX + COPY canonical figs into ResultsPack/figs/
# (kept minimal; extend list as you add canonical figure IDs)
# ============================================================
fig_candidates <- tibble::tribble(
  ~fig_id, ~rel_path, ~caption,
  "FIG_S1_ARDL_u_compare_base2011",
  file.path("Exercise_a_ARDL_faithful","figs","FIG_S1_ARDL_u_compare_base2011_shaikh_window.png"),
  "Faithful ARDL replication (2011 base): Shaikh reference vs with/without LR dummies.",

  "FIG_S1_ARDL_u_compare_base1947",
  file.path("Exercise_a_ARDL_faithful","figs","FIG_S1_ARDL_u_compare_base1947_shaikh_window.png"),
  "Faithful ARDL replication (1947 base): Shaikh reference vs with/without LR dummies.",

  "FIG_S2_ARDL_frontier_RICOMP",
  file.path("Exercise_b_ARDL_grid","figs","FIG_Frontier_ARDL_logLik_vs_RICOMP_pen.png"),
  "ARDL grid: fit–complexity frontier under RICOMP; representatives define the robustness set.",

  "FIG_S3_stability_margin_surface",
  file.path("Exercise_c_VECM_S1_r1","SR_const__LR_none","figs","FIG_stability_margin_surface.png"),
  "Bivariate VECM ($ln Y$, $ln K$), $r=1$: stability margin surface over admissible lattice.",

  "FIG_S4_rank_r1_envelope_RICOMP",
  file.path("Exercise_d_VECM_S2_m3_rank","SR_const__LR_none","figs","rank_r1","FIG_envelope_logLik_vs_RICOMP_pen.png"),
  "Trivariate VECM ($ln Y, $ln K, $e$), $r=1$: fit–complexity envelope under RICOMP.",

  "FIG_S4_rank_r2_envelope_RICOMP",
  file.path("Exercise_d_VECM_S2_m3_rank","SR_const__LR_none","figs","rank_r2","FIG_envelope_logLik_vs_RICOMP_pen.png"),
  "Trivariate VECM ($ln Y$, $ln K$, $e$), $r=2$: fit–complexity envelope under RICOMP."
)

fig_candidates <- fig_candidates %>%
  mutate(abs_path = file.path(OUT_ROOT, rel_path),
         exists = file.exists(abs_path)) %>%
  filter(exists)

copy_fig <- function(abs_path) {
  dest <- file.path(PACK_FIGS, basename(abs_path))
  if (!file.exists(dest)) {
    file.copy(abs_path, dest, overwrite = FALSE)
  }
  append_results_pack_export_log(CONFIG, RUN_ID, "RESULTSPACK", "fig_copy", dest, caption = basename(dest))
  basename(dest)
}

if (nrow(fig_candidates) > 0) {
  fig_candidates <- fig_candidates %>% mutate(pack_file = purrr::map_chr(abs_path, copy_fig))
}

idx_lines <- c(
  "# ResultsPack Index",
  "",
  paste0("- Run ID: `", RUN_ID, "`"),
  paste0("- Generated: `", format(Sys.time(), tz = "America/Santiago"), "`"),
  "",
  "## Binding tables",
  "",
  "- `TAB_S1_replication_key_stats.{csv,tex}` (Stage 1 anchor)",
  "- `TAB_S2_frontier_summary_by_IC.{csv,tex}` (Stage 2 ARDL frontier representatives)",
  "- `TAB_S3_confinement_winners_by_branch.{csv,tex}` (Stage 3 bivariate confinement representatives)",
  "- `TAB_S2_VECM_lnYlnK_e_cointegration.{csv,tex}` (Trivariate VECM cointegration representatives)",
  "- `TAB_crosswalk_core.{csv,tex}` (Core crosswalk representatives across stages)",
  "",
  "## Data artifacts",
  "",
  "- `data/DATA_S1_ARDL_four_series.csv` (Faithful ARDL four-series reproducible dataset)",
  "",
  "## Figure index (canonical captions)",
  ""
)

if (nrow(fig_candidates) == 0) {
  idx_lines <- c(idx_lines, "_No figures found at expected paths._")
} else {
  for (i in seq_len(nrow(fig_candidates))) {
    idx_lines <- c(
      idx_lines,
      paste0("**", fig_candidates$fig_id[i], "**  "),
      paste0("- File: `", file.path("figs", fig_candidates$pack_file[i]), "`  "),
      paste0("- Caption: ", fig_candidates$caption[i]),
      ""
    )
  }
}

index_path <- file.path(PACK_ROOT, "INDEX_RESULTS_PACK.md")
writeLines(idx_lines, index_path)
append_results_pack_export_log(CONFIG, RUN_ID, "RESULTSPACK", "index_md", index_path, caption = "ResultsPack index")

message("ResultsPack generated at: ", PACK_ROOT)

# ============================================================
# KEY ASSESSMENT (encoded as comments because /code_mode)
# ============================================================
# ✅ Leverage found:
# - CONFIG$OUT_CR_* gives canonical output roots: use them everywhere (done).
# - 99_utils has safe_read_csv + truncate_msg + now_stamp + logging: reuse (done).
# - You had export_table_bundle duplicated 3x in utils: delete all of them and keep ONLY the one above.
# - You already have ICOMP/RICOMP surfaces in Stage 3 (envelope files exist), so IC-based grids are fully feasible.
# - Deterministic discipline is enforced by preflight_vecm_spec(); generator doesn't touch that.
#
# 🚫 Do not “leverage”:
# - Any lag remapping helpers: keep legacy functions informational only (you already warned that).