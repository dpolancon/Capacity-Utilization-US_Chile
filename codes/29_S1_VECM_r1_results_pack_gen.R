# ============================================================
# 29_results_package_VECM_S1_lnY_lnK.R
#
# Results package for:
#   Exercise C — VECM S1 (lnY, lnK), r = 1
#
# Uses:
#   - CONFIG from 10_config.R
#   - utilities from 99_utils.R (safe_read_csv, safe_write_csv,
#     export_table_bundle, det helpers, etc.)
#
# Output:
#   output/CriticalReplication/ResultsPackages/VECM_S1_lnY_lnK/
#     tables/ (CSV + TEX via export_table_bundle)
#     figs/
#     logs/
# ============================================================

rm(list = ls())

suppressPackageStartupMessages({
  library(tidyverse)
  library(readr)
  library(glue)
})

# ------------------------------------------------------------
# Load CONFIG + UTILS (repo-native)
# ------------------------------------------------------------
source("10_config.R")  # defines CONFIG
source("99_utils.R")   # defines safe_read_csv, export_table_bundle, etc.

stopifnot(exists("CONFIG"))
stopifnot(is.list(CONFIG))
stopifnot(!is.null(CONFIG$OUT_CR))
stopifnot(!is.null(CONFIG$OUT_CR$exercise_c))

BASE_DIR <- CONFIG$OUT_CR$exercise_c

# ------------------------------------------------------------
# Results package output dirs
# ------------------------------------------------------------
OUT_PKG <- file.path(CONFIG$OUT_CR_ROOT, "ResultsPackages", "VECM_S1_lnY_lnK")
DIR_TABLES <- file.path(OUT_PKG, "tables")
DIR_FIGS   <- file.path(OUT_PKG, "figs")
DIR_LOGS   <- file.path(OUT_PKG, "logs")

dir.create(DIR_TABLES, recursive = TRUE, showWarnings = FALSE)
dir.create(DIR_FIGS,   recursive = TRUE, showWarnings = FALSE)
dir.create(DIR_LOGS,   recursive = TRUE, showWarnings = FALSE)

log_path <- file.path(DIR_LOGS, "RUN_results_package_VECM_S1_lnY_lnK.txt")
sink(log_path, split = TRUE)

cat("============================================================\n")
cat("RESULTS PACKAGE — VECM S1 (lnY, lnK), r=1\n")
cat("Base dir: ", BASE_DIR, "\n")
cat("Out dir:  ", OUT_PKG,  "\n")
cat("Timestamp:", now_stamp(), "\n")  # from utils
cat("============================================================\n\n")

# ------------------------------------------------------------
# Helper: list deterministic branches under Exercise C
# ------------------------------------------------------------
list_branches <- function(base_dir) {
  d <- list.dirs(base_dir, full.names = FALSE, recursive = FALSE)
  # keep only folders that look like deterministic tags
  d <- d[grepl("^SR_", d)]
  sort(d)
}

branches <- list_branches(BASE_DIR)

if (length(branches) == 0) {
  stop("No Stage-3 branches found under Exercise C directory: ", BASE_DIR, call. = FALSE)
}

cat("Branches found:\n")
print(branches)
cat("\n")

# ------------------------------------------------------------
# Helper: safe ingest one branch
# ------------------------------------------------------------
read_branch <- function(branch_tag) {
  
  bdir <- file.path(BASE_DIR, branch_tag)
  csv_dir <- file.path(bdir, "csv")
  
  f_lattice <- file.path(csv_dir, "APPX_lattice_cells_with_deltas.csv")
  f_top     <- file.path(csv_dir, "TAB_top_cells_N10.csv")
  f_sum     <- file.path(csv_dir, "TAB_branch_summary.csv")
  f_eigs    <- file.path(csv_dir, "APPX_eigs_long.csv")
  f_iceta   <- file.path(csv_dir, "APPX_ic_eta_long.csv")
  
  out <- list(branch = branch_tag)
  
  out$lattice <- if (file.exists(f_lattice)) safe_read_csv(f_lattice) else NULL
  out$top     <- if (file.exists(f_top))     safe_read_csv(f_top)     else NULL
  out$summary <- if (file.exists(f_sum))     safe_read_csv(f_sum)     else NULL
  out$eigs    <- if (file.exists(f_eigs))    safe_read_csv(f_eigs)    else NULL
  out$iceta   <- if (file.exists(f_iceta))   safe_read_csv(f_iceta)   else NULL
  
  out
}

dl <- lapply(branches, read_branch)

# ------------------------------------------------------------
# Build MANIFEST-like table for this package (inputs consumed)
# ------------------------------------------------------------
inputs_manifest <- tibble(
  branch = branches,
  lattice = map_lgl(dl, ~ !is.null(.x$lattice)),
  top10   = map_lgl(dl, ~ !is.null(.x$top)),
  summary = map_lgl(dl, ~ !is.null(.x$summary)),
  eigs    = map_lgl(dl, ~ !is.null(.x$eigs)),
  ic_eta  = map_lgl(dl, ~ !is.null(.x$iceta))
)

cat("Input availability by branch:\n")
print(inputs_manifest)
cat("\n")

export_table_bundle(
  tbl = inputs_manifest,
  name = "MANIFEST_S3_inputs_by_branch",
  tables_dir = DIR_TABLES,
  caption = "Stage 3 (Exercise C) input availability by deterministic branch."
)

# ------------------------------------------------------------
# Assemble SPEC UNIVERSE across branches
# ------------------------------------------------------------
lattice_all <- dl |>
  purrr::keep(~ !is.null(.x$lattice)) |>
  purrr::imap_dfr(function(x, i) {
    x$lattice |> mutate(branch = x$branch)
  })

if (nrow(lattice_all) == 0) {
  stop("No lattice cells loaded. Missing APPX_lattice_cells_with_deltas.csv across branches.", call. = FALSE)
}

# Harmonize key column names (non-destructive; prefer existing)
# This avoids hard failure if the pipeline used slightly different labels.
rename_if_exists <- function(df, old, new) {
  if (old %in% names(df) && !(new %in% names(df))) df <- dplyr::rename(df, !!new := !!sym(old))
  df
}

lattice_all <- lattice_all |>
  rename_if_exists("logLik", "LogLik") |>
  rename_if_exists("k_total", "Parameters") |>
  rename_if_exists("ICOMP_pen", "ICOMP_penalty") |>
  rename_if_exists("RICOMP_pen", "RICOMP_penalty") |>
  rename_if_exists("sK_ardl", "sK_ARDL")

# Create a canonical spec_id if absent
if (!("spec_id" %in% names(lattice_all))) {
  lattice_all <- lattice_all |>
    mutate(spec_id = paste0("p", sprintf("%02d", p), "_", q_profile))
}

# Keep a tidy core column set (only if present)
core_cols <- c(
  "branch","spec_id","p","q_profile",
  "LogLik","BIC",
  "ICOMP_penalty","RICOMP_penalty",
  "theta","stability_margin","max_root",
  "Parameters"
)
core_cols_present <- core_cols[core_cols %in% names(lattice_all)]

spec_universe <- lattice_all |>
  select(all_of(core_cols_present))

export_table_bundle(
  tbl = spec_universe,
  name = "DATA_S3_specification_universe",
  tables_dir = DIR_TABLES,
  caption = "Stage 3 specification universe (Exercise C): pooled lattice cells across deterministic branches."
)

# ------------------------------------------------------------
# Winners-by-branch table
# Priority: use TAB_top_cells_N10 first row if available,
# else fall back to min BIC / min RICOMP / min ICOMP if present.
# ------------------------------------------------------------
get_winner <- function(branch_tag) {
  
  x <- dl[[which(branches == branch_tag)]]
  
  if (!is.null(x$top) && nrow(x$top) > 0) {
    w <- x$top |> slice(1) |> mutate(branch = branch_tag, winner_source = "TAB_top_cells_N10")
    return(w)
  }
  
  # fallback from lattice (best available criterion)
  lat <- x$lattice
  if (is.null(lat) || nrow(lat) == 0) return(NULL)
  
  lat <- lat |> mutate(branch = branch_tag)
  
  if ("RICOMP_pen" %in% names(lat)) {
    w <- lat |> arrange(RICOMP_pen) |> slice(1) |> mutate(winner_source = "min_RICOMP_pen")
    return(w)
  }
  if ("ICOMP_pen" %in% names(lat)) {
    w <- lat |> arrange(ICOMP_pen) |> slice(1) |> mutate(winner_source = "min_ICOMP_pen")
    return(w)
  }
  if ("BIC" %in% names(lat)) {
    w <- lat |> arrange(BIC) |> slice(1) |> mutate(winner_source = "min_BIC")
    return(w)
  }
  
  lat |> slice(1) |> mutate(winner_source = "first_row_fallback")
}

winners_raw <- purrr::map(branches, get_winner) |> purrr::compact()
winners <- bind_rows(winners_raw)

# Standardize into compact winners table
wcols_pref <- c(
  "branch","winner_source","p","q_profile",
  "logLik","LogLik","BIC",
  "ICOMP_pen","ICOMP_penalty",
  "RICOMP_pen","RICOMP_penalty",
  "k_total","Parameters",
  "theta","stability_margin","max_root","spec_id"
)
wcols <- wcols_pref[wcols_pref %in% names(winners)]

TAB_winners <- winners |> select(all_of(wcols))

export_table_bundle(
  tbl = TAB_winners,
  name = "TAB_S3_confinement_winners_by_branch",
  tables_dir = DIR_TABLES,
  caption = "Stage 3 confinement winners by deterministic branch (Exercise C, VECM S1 r=1)."
)

# ------------------------------------------------------------
# Theta + stability summaries by branch (if available)
# ------------------------------------------------------------
summarise_by_branch <- function(df, var) {
  if (!(var %in% names(df))) return(NULL)
  df |> group_by(branch) |> summarise(
    n = n(),
    mean = mean(.data[[var]], na.rm = TRUE),
    sd   = sd(.data[[var]],   na.rm = TRUE),
    min  = min(.data[[var]],  na.rm = TRUE),
    max  = max(.data[[var]],  na.rm = TRUE),
    .groups = "drop"
  ) |> mutate(metric = var)
}

theta_sum <- summarise_by_branch(spec_universe, "theta")
stab_sum  <- summarise_by_branch(spec_universe, "stability_margin")

TAB_metrics <- bind_rows(theta_sum, stab_sum)

if (nrow(TAB_metrics) > 0) {
  export_table_bundle(
    tbl = TAB_metrics,
    name = "TAB_S3_metric_summary_by_branch",
    tables_dir = DIR_TABLES,
    caption = "Stage 3 metric summaries by branch (theta and stability margin where available)."
  )
} else {
  cat("No theta/stability_margin columns found for summary table.\n\n")
}

# ------------------------------------------------------------
# Minimal frontier plots (pooled), respecting your “clean viz” style
# ------------------------------------------------------------
library(ggplot2)

plot_if_cols <- function(df, x, y, fname, xlab, ylab, title) {
  if (!(x %in% names(df)) || !(y %in% names(df))) return(FALSE)
  
  g <- ggplot(df, aes(x = .data[[x]], y = .data[[y]])) +
    geom_point(aes(shape = branch), alpha = 0.65) +
    theme_minimal() +
    labs(x = xlab, y = ylab, title = title)
  
  ggsave(file.path(DIR_FIGS, fname), g, width = 10, height = 6, dpi = 160)
  TRUE
}

# logLik might be LogLik or logLik
y_ll <- if ("LogLik" %in% names(spec_universe)) "LogLik" else if ("logLik" %in% names(spec_universe)) "logLik" else NULL
x_k  <- if ("Parameters" %in% names(spec_universe)) "Parameters" else if ("k_total" %in% names(spec_universe)) "k_total" else NULL

if (!is.null(y_ll) && !is.null(x_k)) {
  ok <- plot_if_cols(
    spec_universe,
    x = x_k, y = y_ll,
    fname = "FIG_S3_frontier_logLik_vs_k_total.png",
    xlab = "Parameters",
    ylab = "LogLik",
    title = "Stage 3 frontier: fit vs complexity (pooled across branches)"
  )
  if (!ok) cat("Could not plot FIG_S3_frontier_logLik_vs_k_total (missing columns).\n")
} else {
  cat("Could not plot fit vs complexity: missing LogLik/logLik or Parameters/k_total.\n")
}

# ICOMP/RICOMP plots if present
plot_if_cols(
  spec_universe,
  x = "ICOMP_penalty", y = y_ll %||% "LogLik",
  fname = "FIG_S3_frontier_logLik_vs_ICOMP_penalty.png",
  xlab = "ICOMP penalty",
  ylab = "LogLik",
  title = "Stage 3 frontier: LogLik vs ICOMP penalty"
)

plot_if_cols(
  spec_universe,
  x = "RICOMP_penalty", y = y_ll %||% "LogLik",
  fname = "FIG_S3_frontier_logLik_vs_RICOMP_penalty.png",
  xlab = "Robust ICOMP penalty",
  ylab = "LogLik",
  title = "Stage 3 frontier: LogLik vs Robust ICOMP penalty"
)

# ------------------------------------------------------------
# MAP.md (what to read first)
# ------------------------------------------------------------
map_md <- file.path(OUT_PKG, "MAP_S3.md")

map_lines <- c(
  "# Stage 3 Results Package — VECM S1 (lnY, lnK), r=1",
  "",
  glue("- Base source: `{BASE_DIR}`"),
  glue("- Package output: `{OUT_PKG}`"),
  "",
  "## What to read first (advisor ordering)",
  "1) `tables/TAB_S3_confinement_winners_by_branch.(csv|tex)`",
  "2) `tables/TAB_S3_metric_summary_by_branch.(csv|tex)`",
  "3) `figs/FIG_S3_frontier_logLik_vs_k_total.png`",
  "4) Branch-level surfaces already in Exercise C folders (theta / stability / dBIC)",
  "",
  "## Outputs created by this package",
  "- `tables/DATA_S3_specification_universe.(csv|tex)`",
  "- `tables/TAB_S3_confinement_winners_by_branch.(csv|tex)`",
  "- `tables/TAB_S3_metric_summary_by_branch.(csv|tex)` (if metrics exist)",
  "- `figs/FIG_S3_frontier_logLik_vs_k_total.png` (if columns exist)",
  "- `figs/FIG_S3_frontier_logLik_vs_ICOMP_penalty.png` (optional)",
  "- `figs/FIG_S3_frontier_logLik_vs_RICOMP_penalty.png` (optional)",
  "",
  "## Notes",
  "- This script does not re-estimate any model. It packages computed outputs only.",
  "- Column harmonization is conservative (no overwrites; creates canonical aliases where missing)."
)

writeLines(map_lines, con = map_md)

cat("\nWrote MAP:", map_md, "\n")

cat("\nDONE.\n")

sink()