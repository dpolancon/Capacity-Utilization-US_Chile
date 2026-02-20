############################################################
## 30_report.R — ChaoGrid Report (NO sinks, robust)
############################################################

suppressPackageStartupMessages({
  pkgs <- c("here","dplyr","tidyr","readr","ggplot2")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

source(here::here("codes", "10_config.R"))
source(here::here("codes", "99_utils.R"))

ROOT_OUT <- here::here(CONFIG$OUT_ROOT)
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  figs = file.path(ROOT_OUT, "figs"),
  logs = file.path(ROOT_OUT, "logs")
)
ensure_dirs(DIRS$csv, DIRS$figs, DIRS$logs)

cat("=== Report start ===\n")
cat("Output root :", ROOT_OUT, "\n\n")

expected_files <- c(
  "grid_pic_table_Q2_raw_unrestricted.csv",
  "grid_pic_table_Q2_ortho_unrestricted.csv",
  "grid_pic_table_Q3_raw_unrestricted.csv",
  "grid_pic_table_Q3_ortho_unrestricted.csv"
)
paths <- file.path(DIRS$csv, expected_files)
missing <- paths[!file.exists(paths)]
if (length(missing) > 0) stop("Missing expected engine outputs:\n", paste(missing, collapse = "\n"), call. = FALSE)

read_one <- function(path) {
  df <- readr::read_csv(path, show_col_types = FALSE)
  df$source_file <- basename(path)
  df
}

master <- dplyr::bind_rows(lapply(paths, read_one)) |>
  dplyr::mutate(
    spec  = as.character(.data$spec),
    basis = as.character(.data$basis),
    window= as.character(.data$window),
    ecdet = as.character(.data$ecdet),
    status= as.character(.data$status)
  )

cat("Rows in master:", nrow(master), "\n")
print(table(master$status, useNA = "ifany"))
cat("\n")

DELTA_TOL <- CONFIG$DELTA_PIC_TOL

# Safety: remove any pre-existing columns that can poison joins/assignments
master <- master |>
  dplyr::select(-dplyr::any_of(c("dPIC","PIC_min","in_ambiguity","PIC_min.x","PIC_min.y")))

mins <- master |>
  dplyr::filter(status == "computed", comparable_p, is.finite(PIC_obs)) |>
  dplyr::group_by(spec, basis, window, ecdet) |>
  dplyr::summarise(PIC_min = min(PIC_obs), .groups = "drop")



master2 <- master |>
  dplyr::left_join(mins, by = c("spec","basis","window","ecdet"))

master2$dPIC <- ifelse(
  master2$status == "computed" &
    master2$comparable_p &
    is.finite(master2$PIC_obs) &
    is.finite(master2$PIC_min),
  master2$PIC_obs - master2$PIC_min,
  NA_real_
)


cat("DEBUG: DELTA_TOL = "); print(DELTA_TOL)
cat("DEBUG: length(DELTA_TOL) = ", length(DELTA_TOL), "\n")
cat("DEBUG: has dPIC col = ", ("dPIC" %in% names(master2)), "\n")
cat("DEBUG: class(dPIC) = "); print(class(master2$dPIC))
cat("DEBUG: length(dPIC) = ", length(master2$dPIC), "\n")
stopifnot(!is.null(DELTA_TOL), length(DELTA_TOL) == 1)

master2$in_ambiguity <- is.finite(master2$dPIC) &
  (master2$dPIC <= DELTA_TOL)



winners <- master2 |>
  dplyr::filter(status == "computed", comparable_p, is.finite(PIC_obs)) |>
  dplyr::group_by(spec, basis, window, ecdet) |>
  dplyr::slice_min(order_by = PIC_obs, n = 1, with_ties = FALSE) |>
  dplyr::ungroup()

ambiguity <- master2 |>
  dplyr::filter(in_ambiguity)

out_master <- file.path(DIRS$csv, "report_master_table.csv")
out_winners <- file.path(DIRS$csv, "report_winners.csv")
out_amb <- file.path(DIRS$csv, "report_ambiguity_set.csv")

readr::write_csv(master2, out_master)
readr::write_csv(winners, out_winners)
readr::write_csv(ambiguity, out_amb)

cat("Wrote:", out_master, "\n")
cat("Wrote:", out_winners, "\n")
cat("Wrote:", out_amb, "\n\n")

plot_df <- master2 |>
  dplyr::filter(status == "computed", comparable_p, is.finite(PIC_obs))

if (nrow(plot_df) > 0) {
  p1 <- ggplot2::ggplot(plot_df, ggplot2::aes(x = p, y = r, fill = PIC_obs)) +
    ggplot2::geom_tile() +
    ggplot2::facet_grid(window ~ spec + basis + ecdet, scales = "free") +
    ggplot2::labs(
      title = "PIC landscape (computed & comparable cells only)",
      x = "lag length p",
      y = "rank r"
    )
  fig_path <- file.path(DIRS$figs, "PIC_landscape_all.png")
  ggplot2::ggsave(filename = fig_path, plot = p1, width = 14, height = 8, dpi = 300)
  cat("Saved figure:", fig_path, "\n")
}

cat("=== Report completed OK ===\n")
