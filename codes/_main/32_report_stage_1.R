# ============================================================
# 32_report_stage1.R — ChaoGrid Stage 1 Console Audit (PIC/BIC)
#
# Consolidates the console diagnostics used to close Stage 1:
#  - status counts by window×ecdet (computed/gate_fail/runtime_fail/missing)
#  - PIC minima (unrestricted computed-only) + ambiguity set (ΔPIC)
#  - comparable-domain p-range (p_min, p_max among computed comparable cells)
#  - BIC minima (unrestricted computed-only) + ambiguity set (ΔBIC)
#
# Outputs:
#  - prints key tables to console
#  - writes CSVs into <OUT_ROOT>/csv (defaults to output/ChaoGrid/csv)
#
# Usage (from repo root):
#   source("codes/32_report_stage1.R")
# or run it directly:
#   Rscript codes/32_report_stage1.R
#
# Notes:
# - This script is intentionally standalone: it does not depend on CONFIG/engine code.
# - It assumes the engine has already produced:
#     output/ChaoGrid/csv/APPX_grid_pic_table_*_unrestricted.csv
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# ----------------------------
# Parameters (edit if needed)
# ----------------------------
OUT_ROOT   <- Sys.getenv("CHAOGRID_OUT_ROOT", unset = file.path("output","ChaoGrid"))
CSV_DIR    <- file.path(OUT_ROOT, "csv")
FILE_REGEX <- "APPX_grid_pic_table_.*_unrestricted\\.csv$"

DELTA_PIC  <- suppressWarnings(as.numeric(Sys.getenv("DELTA_PIC_TOL", unset = "2")))
if (!is.finite(DELTA_PIC)) DELTA_PIC <- 2

DELTA_BIC  <- suppressWarnings(as.numeric(Sys.getenv("DELTA_BIC_TOL", unset = "2")))
if (!is.finite(DELTA_BIC)) DELTA_BIC <- 2

# ----------------------------
# Helpers
# ----------------------------
stop_if_missing <- function(cond, msg) if (cond) stop(msg, call. = FALSE)

write_csv_safe <- function(df, name) {
  dir.create(CSV_DIR, recursive = TRUE, showWarnings = FALSE)
  out <- file.path(CSV_DIR, name)
  readr::write_csv(df, out)
  message("Wrote: ", out)
  invisible(out)
}

read_grid <- function(path) {
  df <- readr::read_csv(path, show_col_types = FALSE)
  df$file <- basename(path)
  df
}

# ----------------------------
# Load grids
# ----------------------------
stop_if_missing(!dir.exists(CSV_DIR), paste0("CSV_DIR not found: ", CSV_DIR))

files <- list.files(CSV_DIR, pattern = FILE_REGEX, full.names = TRUE)
stop_if_missing(length(files) == 0, paste0("No grid files found in ", CSV_DIR, " matching: ", FILE_REGEX))

message("=== Stage 1 Audit ===")
message("OUT_ROOT: ", OUT_ROOT)
message("CSV_DIR : ", CSV_DIR)
message("Files   : ", length(files))
message("ΔPIC    : ", DELTA_PIC)
message("ΔBIC    : ", DELTA_BIC)

master <- bind_rows(lapply(files, read_grid))

# Basic column sanity (fail fast with helpful message)
req_cols <- c("window","ecdet","status","p","r","PIC_obs","BIC_obs")
missing_cols <- setdiff(req_cols, names(master))
stop_if_missing(length(missing_cols) > 0,
                paste0("Missing required columns in grid CSVs: ", paste(missing_cols, collapse = ", ")))

# ----------------------------
# A) Status counts (health of lattice)
# ----------------------------
status_counts <- master %>%
  group_by(file, window, ecdet, status) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(file, window, ecdet, status)

cat("\n--- STATUS COUNTS (long) ---\n")
print(status_counts, n = 1000)

status_wide <- status_counts %>%
  tidyr::pivot_wider(names_from = status, values_from = n, values_fill = 0) %>%
  mutate(total = rowSums(across(where(is.numeric))))

cat("\n--- STATUS COUNTS (wide) ---\n")
print(status_wide, n = 1000)

write_csv_safe(status_counts, "STAGE1_status_counts_long.csv")
write_csv_safe(status_wide,  "STAGE1_status_counts_wide.csv")

# ----------------------------
# B) Comparable-domain p-range (is p=1 forced?)
# ----------------------------
# Only meaningful if the column exists; otherwise skip gracefully.
if ("comparable_p" %in% names(master)) {

  p_domain <- master %>%
    filter(comparable_p, status == "computed") %>%
    group_by(file, window, ecdet) %>%
    summarise(p_min = min(p), p_max = max(p), .groups = "drop") %>%
    arrange(file, window, ecdet)

  cat("\n--- COMPARABLE DOMAIN p-range (computed comparable cells) ---\n")
  print(p_domain, n = 1000)

  write_csv_safe(p_domain, "STAGE1_comparable_p_domain.csv")

} else {
  message("Note: comparable_p column not found. Skipping p-domain check.")
}

# ----------------------------
# C) PIC minima (unrestricted, computed-only)
# ----------------------------
pic_minima <- master %>%
  filter(status == "computed", is.finite(PIC_obs)) %>%
  group_by(file, window, ecdet) %>%
  slice_min(PIC_obs, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(file, window, ecdet, p, r, PIC_obs) %>%
  arrange(file, window, ecdet)

cat("\n--- PIC minima (unrestricted, computed-only) ---\n")
print(pic_minima, n = 1000)

write_csv_safe(pic_minima, "STAGE1_PIC_minima_unrestricted.csv")

# ----------------------------
# D) PIC ambiguity set (ΔPIC)
# ----------------------------
pic_amb <- master %>%
  filter(status == "computed", is.finite(PIC_obs)) %>%
  group_by(file, window, ecdet) %>%
  mutate(PIC_min = min(PIC_obs), dPIC = PIC_obs - PIC_min) %>%
  ungroup() %>%
  filter(dPIC <= DELTA_PIC) %>%
  select(file, window, ecdet, p, r, dPIC) %>%
  arrange(file, window, ecdet, p, r)

cat("\n--- PIC ambiguity set (ΔPIC <= ", DELTA_PIC, ") ---\n", sep = "")
print(pic_amb, n = 1000)

write_csv_safe(pic_amb, "STAGE1_PIC_ambiguity_set.csv")

# ----------------------------
# E) BIC minima (unrestricted, computed-only)
# ----------------------------
bic_minima <- master %>%
  filter(status == "computed", is.finite(BIC_obs)) %>%
  group_by(file, window, ecdet) %>%
  slice_min(BIC_obs, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(file, window, ecdet, p, r, BIC_obs) %>%
  arrange(file, window, ecdet)

cat("\n--- BIC minima (unrestricted, computed-only) ---\n")
print(bic_minima, n = 1000)

write_csv_safe(bic_minima, "STAGE1_BIC_minima_unrestricted.csv")

# ----------------------------
# F) BIC ambiguity set (ΔBIC)
# ----------------------------
bic_amb <- master %>%
  filter(status == "computed", is.finite(BIC_obs)) %>%
  group_by(file, window, ecdet) %>%
  mutate(BIC_min = min(BIC_obs), dBIC = BIC_obs - BIC_min) %>%
  ungroup() %>%
  filter(dBIC <= DELTA_BIC) %>%
  select(file, window, ecdet, p, r, dBIC) %>%
  arrange(file, window, ecdet, p, r)

cat("\n--- BIC ambiguity set (ΔBIC <= ", DELTA_BIC, ") ---\n", sep = "")
print(bic_amb, n = 1000)

write_csv_safe(bic_amb, "STAGE1_BIC_ambiguity_set.csv")

cat("\n=== Stage 1 Audit COMPLETE ===\n")
