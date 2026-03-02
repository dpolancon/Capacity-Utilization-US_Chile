# ============================================================
# 34_report_stage_2.R — ChaoGrid Stage 2 Report (Feasibility + Comparability)
#
# PURPOSE
#   Reproduce Stage 2 results:
#   - Feasible p_max by window × ecdet for each run_tag
#   - COMMON_P_MAX per run_tag and binding rows (who binds)
#   - Comparable-domain accounting: computed vs computed_comparable
#
# INPUTS (engine artifacts)
#   output/<OUT_ROOT>/csv/APPX_S1_feasible_pmax_by_window_ecdet_*.csv
#   output/<OUT_ROOT>/csv/APPX_grid_pic_table_*_unrestricted.csv
#
# OUTPUTS (written to output/<OUT_ROOT>/csv/)
#   APPX_report_stage2_feasible_pmax_long.csv
#   APPX_report_stage2_common_pmax.csv
#   APPX_report_stage2_common_pmax_binders.csv
#   APPX_report_stage2_comparable_accounting.csv
#
# Notes:
# - This script is artifact-driven. It does not infer missing pieces.
# - “Comparable-domain trimming” is measured as computed_comparable / computed.
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","dplyr","readr","stringr","tidyr","purrr")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

# --- Project wiring (reuse your repo config if available) ----
# If you run this outside the repo structure, comment i_am()/source() lines
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

LBL_APPX <- CONFIG$OUT_LABELS$appx %||% "APPX"

cat("=== Stage 2 report start ===\n")
cat("Output root :", ROOT_OUT, "\n\n")

# ============================================================
# S2A. Feasible pmax by window×ecdet (Stage 2 inputs)
# ============================================================
feas_files <- list.files(
  DIRS$csv,
  pattern = paste0("^", LBL_APPX, "_S1_feasible_pmax_by_window_ecdet_.*\\.csv$"),
  full.names = TRUE
)
if (length(feas_files) == 0) {
  stop("No feasible pmax tables found: APPX_S1_feasible_pmax_by_window_ecdet_*.csv", call. = FALSE)
}

feas <- bind_rows(lapply(feas_files, function(f) {
  df <- readr::read_csv(f, show_col_types = FALSE)
  df$file <- basename(f)
  df$run_tag <- stringr::str_replace(df$file, paste0("^", LBL_APPX, "_S1_feasible_pmax_by_window_ecdet_"), "") |>
    stringr::str_replace("\\.csv$", "")
  df
})) %>%
  dplyr::arrange(run_tag, window, ecdet)

# sanity: require p_max_feasible
if (!("p_max_feasible" %in% names(feas))) {
  stop("Expected column 'p_max_feasible' not found in feasible-pmax tables.", call. = FALSE)
}

# write long feasibility table
out_feas <- file.path(DIRS$csv, paste0(LBL_APPX, "_report_stage2_feasible_pmax_long.csv"))
readr::write_csv(feas, out_feas)

# ============================================================
# S2B. COMMON_P_MAX and binding rows per run_tag
# ============================================================
common <- feas %>%
  dplyr::group_by(run_tag) %>%
  dplyr::summarise(
    COMMON_P_MAX = min(p_max_feasible, na.rm = TRUE),
    .groups = "drop"
  )

binders <- feas %>%
  dplyr::inner_join(common, by = "run_tag") %>%
  dplyr::mutate(is_binding = (p_max_feasible == COMMON_P_MAX)) %>%
  dplyr::filter(is_binding) %>%
  dplyr::select(run_tag, window, ecdet, T, m, p_max_feasible, COMMON_P_MAX, file) %>%
  dplyr::arrange(run_tag, window, ecdet)

out_common  <- file.path(DIRS$csv, paste0(LBL_APPX, "_report_stage2_common_pmax.csv"))
out_binders <- file.path(DIRS$csv, paste0(LBL_APPX, "_report_stage2_common_pmax_binders.csv"))
readr::write_csv(common, out_common)
readr::write_csv(binders, out_binders)

cat("S2B: COMMON_P_MAX per run_tag:\n")
print(common)
cat("\nS2B: Binding rows (who sets COMMON_P_MAX):\n")
print(binders, n = 200)

# ============================================================
# S2C. Comparable-domain accounting on unrestricted grids
# ============================================================
grid_files <- list.files(
  DIRS$csv,
  pattern = paste0("^", LBL_APPX, "_grid_pic_table_.*_unrestricted\\.csv$"),
  full.names = TRUE
)
if (length(grid_files) == 0) {
  stop("No grid tables found: APPX_grid_pic_table_*_unrestricted.csv", call. = FALSE)
}

gr <- bind_rows(lapply(grid_files, function(f) {
  df <- readr::read_csv(f, show_col_types = FALSE)
  df$file <- basename(f)
  df$run_tag <- stringr::str_replace(df$file, paste0("^", LBL_APPX, "_grid_pic_table_"), "") |>
    stringr::str_replace("_unrestricted\\.csv$", "")
  df
}))

# Require key fields
need_cols <- c("status","comparable_p","window","ecdet")
missing_cols <- setdiff(need_cols, names(gr))
if (length(missing_cols) > 0) {
  stop("Grid table missing required columns: ", paste(missing_cols, collapse=", "), call. = FALSE)
}

stage2c <- gr %>%
  dplyr::group_by(run_tag, window, ecdet) %>%
  dplyr::summarise(
    total = dplyr::n(),
    computed = sum(status == "computed"),
    gate_fail = sum(status == "gate_fail"),
    runtime_fail = sum(status == "runtime_fail"),
    missing = sum(status == "missing"),
    computed_comparable = sum(status == "computed" & comparable_p),
    computed_share = computed / total,
    computed_comparable_share = computed_comparable / total,
    comparable_among_computed = dplyr::if_else(computed > 0, computed_comparable / computed, NA_real_),
    .groups = "drop"
  ) %>%
  dplyr::arrange(run_tag, window, ecdet)

out_stage2c <- file.path(DIRS$csv, paste0(LBL_APPX, "_report_stage2_comparable_accounting.csv"))
readr::write_csv(stage2c, out_stage2c)

cat("\nS2C: Comparable-domain accounting (computed vs computed_comparable):\n")
print(stage2c, n = 200)

# ============================================================
# S2 closure checks (strict, but not fragile)
# ============================================================
# Check whether comparable domain trims computed cells
trim_check <- stage2c %>%
  dplyr::mutate(trims_any = (computed_comparable < computed)) %>%
  dplyr::group_by(run_tag) %>%
  dplyr::summarise(any_trim = any(trims_any), .groups = "drop")

cat("\nS2 closure check: does comparable_p trim computed cells?\n")
print(trim_check)

cat("\n=== Stage 2 report done ===\n")
cat("Wrote:\n")
cat(" -", out_feas, "\n")
cat(" -", out_common, "\n")
cat(" -", out_binders, "\n")
cat(" -", out_stage2c, "\n")
