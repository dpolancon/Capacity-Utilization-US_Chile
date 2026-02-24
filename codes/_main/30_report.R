# ============================================================
# 30_report.R — ChaoGrid Report (CONSOLIDATED + AUDIT LAYER)
#
# Reads engine artifacts (csv/meta) and produces:
# - ESSAY outputs:
#   csv/ESSAY_Table_joint_pr_selection.csv
#   figs/ESSAY_PIC_landscape_baseline_<run_tag>.png
#
# - APPX outputs (core):
#   csv/APPX_report_master_table.csv
#   csv/APPX_report_winners.csv
#   csv/APPX_report_ambiguity_set.csv
#   figs/APPX_PIC_landscape_all.png
#
# - APPX outputs (AUDIT layer):
#   csv/APPX_report_status_counts.csv
#   csv/APPX_report_winners_BIC.csv
#   csv/APPX_report_winners_unrestricted_PIC.csv
#   csv/APPX_report_winners_unrestricted_BIC.csv
#   csv/APPX_report_feasible_pmax_by_window_ecdet.csv   (optional)
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","dplyr","tidyr","readr","ggplot2","stringr","purrr")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

here::i_am("codes/10_config.R")
source(here::here("codes", "10_config.R"))
source(here::here("codes", "99_utils.R"))

ROOT_OUT <- here::here(CONFIG$OUT_ROOT)
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  figs = file.path(ROOT_OUT, "figs"),
  logs = file.path(ROOT_OUT, "logs"),
  meta = file.path(ROOT_OUT, "meta")
)
ensure_dirs(DIRS$csv, DIRS$figs, DIRS$logs, DIRS$meta)

LBL_ESSAY <- CONFIG$OUT_LABELS$essay %||% "ESSAY"
LBL_APPX  <- CONFIG$OUT_LABELS$appx  %||% "APPX"
DELTA_TOL <- CONFIG$DELTA_PIC_TOL

cat("=== Report start ===\n")
cat("Output root :", ROOT_OUT, "\n\n")

# ------------------------------------------------------------
# S0. Load engine grid artifacts
# ------------------------------------------------------------

grid_files <- list.files(
  DIRS$csv,
  pattern = paste0("^", LBL_APPX, "_grid_pic_table_.*_unrestricted\\.csv$"),
  full.names = TRUE
)
if (length(grid_files) == 0) {
  stop("No engine grids found (APPX_grid_pic_table_*_unrestricted.csv).", call.=FALSE)
}

read_one <- function(path) {
  df <- readr::read_csv(path, show_col_types = FALSE)
  df$source_file <- basename(path)
  df
}

master <- dplyr::bind_rows(lapply(grid_files, read_one)) |>
  dplyr::mutate(
    spec   = as.character(.data$spec),
    basis  = as.character(.data$basis),
    window = as.character(.data$window),
    ecdet  = as.character(.data$ecdet),
    status = as.character(.data$status),
    run_tag = paste0(.data$spec, "_", .data$basis)
  )

# ------------------------------------------------------------
# S1. Load meta artifacts (basis + system vars)
# ------------------------------------------------------------

parse_kv_file <- function(f) {
  lines <- readLines(f, warn = FALSE)
  lines <- lines[nchar(trimws(lines)) > 0]  # drop blank lines
  kv <- strsplit(lines, "=", fixed = TRUE)
  
  keys <- vapply(kv, function(x) trimws(x[1]), character(1))
  vals <- vapply(kv, function(x) trimws(paste(x[-1], collapse = "=")), character(1))
  
  out <- as.list(vals); names(out) <- keys
  out$file <- basename(f)
  out
}
basis_files <- list.files(
  DIRS$meta,
  pattern = paste0("^", LBL_APPX, "_S0_basis_.*\\.txt$"),
  full.names = TRUE
)

# helper: ensure columns exist (pads with NA if missing)
ensure_cols <- function(df, cols) {
  for (cc in cols) if (!cc %in% names(df)) df[[cc]] <- NA_character_
  df
}

basis_tbl <- if (length(basis_files) > 0) {
  
  raw_basis <- purrr::map_dfr(basis_files, parse_kv_file)
  raw_basis <- ensure_cols(raw_basis, c("include_e_raw","e_raw_mode","spec_type","degree"))
  
  raw_basis |>
    dplyr::mutate(
      run_tag = stringr::str_replace(.data$file, paste0("^", LBL_APPX, "_S0_basis_"), "") |>
        stringr::str_replace("\\.txt$", ""),
      
      include_e_raw = tolower(dplyr::coalesce(.data$include_e_raw, "false")) %in% c("true","t","1","yes"),
      e_raw_mode    = dplyr::coalesce(.data$e_raw_mode, NA_character_),
      spec_type     = dplyr::coalesce(.data$spec_type, NA_character_),
      degree_meta   = suppressWarnings(as.integer(dplyr::coalesce(.data$degree, NA_character_)))
    ) |>
    # KEEP ONLY SAFE COLUMNS (prevents spec/basis collisions)
    dplyr::select(run_tag, include_e_raw, e_raw_mode, spec_type, degree_meta)
  
} else {
  dplyr::tibble(
    run_tag = character(),
    include_e_raw = logical(),
    e_raw_mode = character(),
    spec_type = character(),
    degree_meta = integer()
  )
}
sys_files <- list.files(DIRS$meta, pattern = paste0("^", LBL_APPX, "_S0_systemvars_.*\\.txt$"), full.names = TRUE)
sys_tbl <- if (length(sys_files) > 0) {
  purrr::map_dfr(sys_files, parse_kv_file) |>
    dplyr::mutate(
      run_tag = stringr::str_replace(.data$file, paste0("^", LBL_APPX, "_S0_systemvars_"), "") |>
        stringr::str_replace("\\.txt$", ""),
      vars = .data$vars %||% NA_character_
    ) |>
    dplyr::select(run_tag, vars)
} else dplyr::tibble(run_tag = character(), vars = character())

# ---- Tripwire: prevent meta collisions ----
bad_cols <- intersect(names(master), setdiff(names(basis_tbl), "run_tag"))
if (length(bad_cols) > 0) {
  stop("Meta join would collide with grid columns: ",
       paste(bad_cols, collapse=", "),
       call.=FALSE)
}

master <- master |>
  dplyr::left_join(basis_tbl, by = "run_tag") |>
  dplyr::left_join(sys_tbl, by = "run_tag") |>
  dplyr::mutate(
    e_linear      = isTRUE(.data$include_e_raw),
    e_linear_mode = ifelse(isTRUE(.data$include_e_raw), "raw", "none")
  ) |>
  dplyr::select(-dplyr::any_of(c("dPIC","PIC_min","in_ambiguity","PIC_min.x","PIC_min.y")))

# ------------------------------------------------------------
# S2. PIC minima (computed + comparable domain)
# ------------------------------------------------------------

mins_pic <- master |>
  dplyr::filter(status == "computed", comparable_p, is.finite(PIC_obs)) |>
  dplyr::group_by(spec, basis, window, ecdet, run_tag) |>
  dplyr::summarise(PIC_min = min(PIC_obs), .groups = "drop")

master2 <- master |>
  dplyr::left_join(mins_pic, by = c("spec","basis","window","ecdet","run_tag"))

master2$dPIC <- ifelse(
  master2$status == "computed" & master2$comparable_p & is.finite(master2$PIC_obs) & is.finite(master2$PIC_min),
  master2$PIC_obs - master2$PIC_min,
  NA_real_
)
master2$in_ambiguity <- is.finite(master2$dPIC) & (master2$dPIC <= DELTA_TOL)

winners_pic <- master2 |>
  dplyr::filter(status == "computed", comparable_p, is.finite(PIC_obs)) |>
  dplyr::group_by(spec, basis, window, ecdet, run_tag) |>
  dplyr::slice_min(order_by = PIC_obs, n = 1, with_ties = FALSE) |>
  dplyr::ungroup()

ambiguity <- master2 |> dplyr::filter(in_ambiguity)
ambiguity_sizes <- ambiguity |> dplyr::count(spec, basis, window, ecdet, run_tag, name = "ambiguity_n")

# ------------------------------------------------------------
# S3. ESSAY outputs
# ------------------------------------------------------------

winners_essay <- winners_pic |>
  dplyr::left_join(ambiguity_sizes, by = c("spec","basis","window","ecdet","run_tag")) |>
  dplyr::mutate(ambiguity_n = .data$ambiguity_n %||% 0L) |>
  dplyr::select(window, ecdet, spec, basis, e_linear, e_linear_mode, p, r, PIC_obs, PIC_min, dPIC, ambiguity_n, vars) |>
  dplyr::arrange(window, ecdet, spec, basis)

out_essay_table <- file.path(DIRS$csv, paste0(LBL_ESSAY, "_Table_joint_pr_selection.csv"))
readr::write_csv(winners_essay, out_essay_table)

baseline_run <- if ("Q2_ortho" %in% winners_pic$run_tag) "Q2_ortho" else (winners_pic$run_tag[1] %||% NA_character_)
plot_baseline <- master2 |> dplyr::filter(status == "computed", comparable_p, is.finite(PIC_obs), run_tag == baseline_run)

if (!is.na(baseline_run) && nrow(plot_baseline) > 0) {
  p_base <- ggplot2::ggplot(plot_baseline, ggplot2::aes(x = p, y = r, fill = PIC_obs)) +
    ggplot2::geom_tile() +
    ggplot2::facet_grid(window ~ ecdet) +
    ggplot2::labs(
      title = paste0("PIC landscape (baseline: ", baseline_run, ")"),
      x = "lag length p",
      y = "rank r"
    )
  out_essay_fig <- file.path(DIRS$figs, paste0(LBL_ESSAY, "_PIC_landscape_baseline_", baseline_run, ".png"))
  ggplot2::ggsave(out_essay_fig, p_base, width = 8, height = 6, dpi = 300)
}

# ------------------------------------------------------------
# S4. APPX core bundle
# ------------------------------------------------------------

readr::write_csv(master2,   file.path(DIRS$csv, paste0(LBL_APPX, "_report_master_table.csv")))
readr::write_csv(winners_pic, file.path(DIRS$csv, paste0(LBL_APPX, "_report_winners.csv")))
readr::write_csv(ambiguity, file.path(DIRS$csv, paste0(LBL_APPX, "_report_ambiguity_set.csv")))

plot_df <- master2 |> dplyr::filter(status == "computed", comparable_p, is.finite(PIC_obs))
if (nrow(plot_df) > 0) {
  p_all <- ggplot2::ggplot(plot_df, ggplot2::aes(x = p, y = r, fill = PIC_obs)) +
    ggplot2::geom_tile() +
    ggplot2::facet_grid(window ~ spec + basis + ecdet, scales = "free") +
    ggplot2::labs(
      title = "PIC landscape (all specs; computed & comparable only)",
      x = "lag length p",
      y = "rank r"
    )
  out_appx_fig <- file.path(DIRS$figs, paste0(LBL_APPX, "_PIC_landscape_all.png"))
  ggplot2::ggsave(out_appx_fig, p_all, width = 14, height = 8, dpi = 300)
}

# ------------------------------------------------------------
# S5. AUDIT layer (minimal but decisive)
# ------------------------------------------------------------

# (A) Status counts per run_tag × window × ecdet
status_counts <- master2 |>
  dplyr::mutate(
    computed_comparable = (.data$status == "computed") & isTRUE(.data$comparable_p)
  ) |>
  dplyr::group_by(run_tag, window, ecdet, spec, basis) |>
  dplyr::summarise(
    total_cells = dplyr::n(),
    computed = sum(.data$status == "computed"),
    gate_fail = sum(.data$status == "gate_fail"),
    runtime_fail = sum(.data$status == "runtime_fail"),
    missing = sum(.data$status == "missing"),
    computed_comparable = sum(.data$computed_comparable),
    .groups = "drop"
  )

readr::write_csv(
  status_counts,
  file.path(DIRS$csv, paste0(LBL_APPX, "_report_status_counts.csv"))
)

# (B) BIC winners on comparable domain
mins_bic <- master2 |>
  dplyr::filter(status == "computed", comparable_p, is.finite(BIC_obs)) |>
  dplyr::group_by(spec, basis, window, ecdet, run_tag) |>
  dplyr::summarise(BIC_min = min(BIC_obs), .groups = "drop")

winners_bic <- master2 |>
  dplyr::filter(status == "computed", comparable_p, is.finite(BIC_obs)) |>
  dplyr::group_by(spec, basis, window, ecdet, run_tag) |>
  dplyr::slice_min(order_by = BIC_obs, n = 1, with_ties = FALSE) |>
  dplyr::ungroup() |>
  dplyr::left_join(mins_bic, by = c("spec","basis","window","ecdet","run_tag"))

readr::write_csv(
  winners_bic,
  file.path(DIRS$csv, paste0(LBL_APPX, "_report_winners_BIC.csv"))
)

# (C) Unrestricted winners (computed-only), PIC and BIC
winners_unrestricted_pic <- master2 |>
  dplyr::filter(status == "computed", is.finite(PIC_obs)) |>
  dplyr::group_by(spec, basis, window, ecdet, run_tag) |>
  dplyr::slice_min(order_by = PIC_obs, n = 1, with_ties = FALSE) |>
  dplyr::ungroup()

winners_unrestricted_bic <- master2 |>
  dplyr::filter(status == "computed", is.finite(BIC_obs)) |>
  dplyr::group_by(spec, basis, window, ecdet, run_tag) |>
  dplyr::slice_min(order_by = BIC_obs, n = 1, with_ties = FALSE) |>
  dplyr::ungroup()

readr::write_csv(
  winners_unrestricted_pic,
  file.path(DIRS$csv, paste0(LBL_APPX, "_report_winners_unrestricted_PIC.csv"))
)
readr::write_csv(
  winners_unrestricted_bic,
  file.path(DIRS$csv, paste0(LBL_APPX, "_report_winners_unrestricted_BIC.csv"))
)

# (D) Optional: Feasible pmax tables (document what binds COMMON_P_MAX)
feas_files <- list.files(
  DIRS$csv,
  pattern = paste0("^", LBL_APPX, "_S1_feasible_pmax_by_window_ecdet_.*\\.csv$"),
  full.names = TRUE
)

feas_tbl <- if (length(feas_files) > 0) {
  dplyr::bind_rows(lapply(feas_files, function(f) {
    x <- readr::read_csv(f, show_col_types = FALSE)
    x$run_tag <- stringr::str_replace(
      basename(f),
      paste0("^", LBL_APPX, "_S1_feasible_pmax_by_window_ecdet_"),
      ""
    ) |>
      stringr::str_replace("\\.csv$", "")
    x
  }))
} else dplyr::tibble()

if (nrow(feas_tbl) > 0) {
  readr::write_csv(
    feas_tbl,
    file.path(DIRS$csv, paste0(LBL_APPX, "_report_feasible_pmax_by_window_ecdet.csv"))
  )
}

cat("=== Report completed OK ===\n")
cat("ESSAY:", out_essay_table, "\n")
