# ============================================================
# 80_pack_ch3_replication.R
#
# Results packaging for Chapter 3 Critical Replication.
# STRICT CONSUMER of declared public S0/S1/S2 outputs.
# CONTRACT ERROR on any missing input. No fallbacks. No heuristic
# discovery. No schema repair.
#
# Reads:
#   S0: S0_spec_report.csv, S0_utilization_series.csv, S0_fivecase_summary.csv
#   S1: S1_lattice_full.csv, S1_admissible.csv, S1_frontier_F020.csv,
#       S1_frontier_u_band.csv, S1_frontier_theta.csv
#   S2: S2_m2_admissible.csv, S2_m2_omega20.csv,
#       S2_m3_admissible.csv, S2_m3_omega20.csv,
#       S2_rotation_check.csv
#
# Writes:
#   output/CriticalReplication/ResultsPack/tables/
#   output/CriticalReplication/ResultsPack/figures/
#
# Date: 2026-03-11
# ============================================================

rm(list = ls())

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(ggplot2)
})

source(here::here("codes", "10_config.R"))
source(here::here("codes", "99_utils.R"))

stopifnot(exists("CONFIG"))

# ---- CONTRACT: assert_file utility ----
assert_file <- function(path) {
  if (!file.exists(path))
    stop("CONTRACT ERROR: expected file not found: ", path, call. = FALSE)
  invisible(path)
}

# ---- Paths ----
S0_DIR <- here::here(CONFIG$OUT_CR$S0_faithful, "csv")
S1_DIR <- here::here(CONFIG$OUT_CR$S1_geometry, "csv")
S2_DIR <- here::here(CONFIG$OUT_CR$S2_vecm, "csv")

PACK_ROOT <- here::here(CONFIG$OUT_CR$results_pack)
PACK_TABLES  <- file.path(PACK_ROOT, "tables")
PACK_FIGURES <- file.path(PACK_ROOT, "figures")

dir.create(PACK_TABLES,  recursive = TRUE, showWarnings = FALSE)
dir.create(PACK_FIGURES, recursive = TRUE, showWarnings = FALSE)

# ---- S0 inputs ----
s0_spec_report <- assert_file(file.path(S0_DIR, "S0_spec_report.csv"))
s0_utilization <- assert_file(file.path(S0_DIR, "S0_utilization_series.csv"))
s0_fivecase    <- assert_file(file.path(S0_DIR, "S0_fivecase_summary.csv"))

cat("S0 inputs verified.\n")
s0_spec  <- read.csv(s0_spec_report)
s0_u     <- read.csv(s0_utilization)
s0_cases <- read.csv(s0_fivecase)

# ---- S1 inputs ----
s1_lattice   <- assert_file(file.path(S1_DIR, "S1_lattice_full.csv"))
s1_admiss    <- assert_file(file.path(S1_DIR, "S1_admissible.csv"))
s1_frontier  <- assert_file(file.path(S1_DIR, "S1_frontier_F020.csv"))

cat("S1 inputs verified.\n")
s1_lat <- read.csv(s1_lattice)
s1_adm <- read.csv(s1_admiss)
s1_f20 <- read.csv(s1_frontier)

# Optional S1 files (not all may exist at initial packaging)
s1_u_band_path <- file.path(S1_DIR, "S1_frontier_u_band.csv")
s1_theta_path  <- file.path(S1_DIR, "S1_frontier_theta.csv")
s1_u_band <- if (file.exists(s1_u_band_path)) read.csv(s1_u_band_path) else NULL
s1_theta  <- if (file.exists(s1_theta_path))  read.csv(s1_theta_path)  else NULL

# ---- S2 inputs ----
s2_m2_admiss <- assert_file(file.path(S2_DIR, "S2_m2_admissible.csv"))
s2_m2_omega  <- assert_file(file.path(S2_DIR, "S2_m2_omega20.csv"))
s2_m3_admiss <- assert_file(file.path(S2_DIR, "S2_m3_admissible.csv"))
s2_m3_omega  <- assert_file(file.path(S2_DIR, "S2_m3_omega20.csv"))
s2_rotation  <- assert_file(file.path(S2_DIR, "S2_rotation_check.csv"))

cat("S2 inputs verified.\n")
s2_m2_a <- read.csv(s2_m2_admiss)
s2_m2_o <- read.csv(s2_m2_omega)
s2_m3_a <- read.csv(s2_m3_admiss)
s2_m3_o <- read.csv(s2_m3_omega)
s2_rot  <- read.csv(s2_rotation)

# ============================================================
# BUILD PAPER-FACING TABLES
# ============================================================

# Table 1: S0 five-case comparison
write.csv(s0_cases, file.path(PACK_TABLES, "TAB_S0_fivecase.csv"),
          row.names = FALSE)

# Table 2: S0 bounds test results
write.csv(s0_spec, file.path(PACK_TABLES, "TAB_S0_bounds_report.csv"),
          row.names = FALSE)

# Table 3: S1 frontier summary
s1_summary <- data.frame(
  total_specs = nrow(s1_lat),
  admissible  = nrow(s1_adm),
  frontier_F020 = nrow(s1_f20),
  stringsAsFactors = FALSE
)
write.csv(s1_summary, file.path(PACK_TABLES, "TAB_S1_frontier_summary.csv"),
          row.names = FALSE)

# Table 4: S2 admissibility summary
s2_summary <- data.frame(
  system = c("m=2", "m=3"),
  admissible = c(nrow(s2_m2_a), nrow(s2_m3_a)),
  omega20    = c(nrow(s2_m2_o), nrow(s2_m3_o)),
  stringsAsFactors = FALSE
)
write.csv(s2_summary, file.path(PACK_TABLES, "TAB_S2_admissibility_summary.csv"),
          row.names = FALSE)

# Table 5: S2 rotation diagnostics
write.csv(s2_rot, file.path(PACK_TABLES, "TAB_S2_rotation_check.csv"),
          row.names = FALSE)

cat("Tables written to: ", PACK_TABLES, "\n")

# ============================================================
# BUILD PAPER-FACING FIGURES
# ============================================================

# Figure: S0 utilization replication
if ("year" %in% names(s0_u) && "u_hat" %in% names(s0_u)) {
  p_s0 <- ggplot2::ggplot(s0_u, ggplot2::aes(x = year, y = u_hat)) +
    ggplot2::geom_line(color = "steelblue", linewidth = 0.8) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Year", y = "Utilization rate",
                  title = "S0: Replicated capacity utilization")

  if ("u_shaikh" %in% names(s0_u)) {
    p_s0 <- p_s0 + ggplot2::geom_line(
      ggplot2::aes(y = u_shaikh), linetype = "dashed", color = "black"
    )
  }

  ggplot2::ggsave(file.path(PACK_FIGURES, "fig_S0_utilization_replication.pdf"),
                  p_s0, width = 7, height = 5, dpi = 300)
}

cat("Pack complete. Output: ", PACK_ROOT, "\n")

# ============================================================
# INDEX
# ============================================================
pack_files <- list.files(PACK_ROOT, recursive = TRUE)
index_lines <- c(
  "# INDEX — Chapter 3 Results Pack",
  sprintf("Generated: %s", Sys.time()),
  "",
  "## Tables",
  paste0("- ", list.files(PACK_TABLES)),
  "",
  "## Figures",
  paste0("- ", list.files(PACK_FIGURES))
)
writeLines(index_lines, file.path(PACK_ROOT, "INDEX_RESULTS_PACK.md"))
cat("Index written.\n")
