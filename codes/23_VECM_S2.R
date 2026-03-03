# ============================================================
# 23_VECM_S2.R
# Self-Discovery Process — VECM Stage (S2)
#
# This stage reuses the shared envelope helper so the three
# mandatory planes are produced with exactly the same rule.
# ============================================================

rm(list = ls())

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(ggplot2)
})

source(here::here("codes", "99_utils.R"))
source(here::here("codes", "25_envelope_tools.R"))

emit_mandatory_planes_s2 <- function(geom_df, csv_dir, fig_dir, tag = "S2") {
  stopifnot(is.data.frame(geom_df))
  dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

  write_envelope_plane(
    geom_df,
    x_col = "k_total",
    y_col = "logLik",
    csv_path = file.path(csv_dir, "ENVELOPE_logLik_vs_k_total.csv"),
    fig_path = file.path(fig_dir, "FIG_envelope_logLik_vs_k_total.png"),
    title = paste0("Envelope: logLik vs k_total | ", tag)
  )

  write_envelope_plane(
    geom_df,
    x_col = "ICOMP_pen",
    y_col = "logLik",
    csv_path = file.path(csv_dir, "ENVELOPE_logLik_vs_ICOMP_pen.csv"),
    fig_path = file.path(fig_dir, "FIG_envelope_logLik_vs_ICOMP_pen.png"),
    title = paste0("Envelope: logLik vs ICOMP_pen | ", tag)
  )

  write_envelope_plane(
    geom_df,
    x_col = "RICOMP_pen",
    y_col = "logLik",
    csv_path = file.path(csv_dir, "ENVELOPE_logLik_vs_RICOMP_pen.csv"),
    fig_path = file.path(fig_dir, "FIG_envelope_logLik_vs_RICOMP_pen.png"),
    title = paste0("Envelope: logLik vs RICOMP_pen | ", tag)
  )

  invisible(TRUE)
}
