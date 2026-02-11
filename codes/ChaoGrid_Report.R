############################################################
## ChaoGrid_Report.R  (Q2 + Q3, tables + figures, self-contained)
##
## Compatibility audit vs current Engine outputs:
## - Expects: grid_pic_table_{Q2,Q3}.csv and grid_rank_decisions_{Q2,Q3}.csv
## - Expects columns in PIC table: window, ecdet, p, r, PIC, BIC, T, m
## - Expects columns in rank table: window, ecdet, p, r_trace_10/05/01
## - Optional: S6_theta_*_curve.csv (index table only if exists)
##
## Fixes implemented here (report-side):
## 1) Boundary diagnostic (S5.6) rewritten safely:
##    - no “unique() inside mutate” fragility
##    - p_max/r_max computed by join
## 2) Grid overview (S1) grid_points counts actual (ecdet,p,r) combos.
############################################################

suppressPackageStartupMessages({
  pkgs <- c("here","dplyr","tidyr","ggplot2","knitr","kableExtra","scales","conflicted","readr")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

# ---- helpers ----
codes_path   <- here::here("codes")
helpers_path <- file.path(codes_path, "0_functions.R")
source(helpers_path)

# ---- conflicts ----
conflicted::conflicts_prefer(dplyr::filter)
conflicted::conflicts_prefer(dplyr::select)
conflicted::conflicts_prefer(dplyr::lag)

# ---- paths ----
ROOT_OUT <- here::here("output/ChaoGrid")
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  tex  = file.path(ROOT_OUT, "tex"),
  figs = file.path(ROOT_OUT, "figs"),
  rds  = file.path(ROOT_OUT, "rds"),
  logs = file.path(ROOT_OUT, "logs")
)
ensure_dirs(DIRS$csv, DIRS$tex, DIRS$figs, DIRS$rds, DIRS$logs)

log_file <- file.path(DIRS$logs, "report_log.txt")
sink(log_file, split = TRUE)

# ---- locked enums ----
WINDOW_ORDER <- c("full","ford","post")
ECDET_ORDER  <- c("none","const")
BASIS_ORDER  <- c("Q2","Q3")

ECDET_LABELS <- c(
  none  = "No Constant",
  const = "Constant"
)

# ---- io ----
pic_paths <- c(
  Q2 = file.path(DIRS$csv, "grid_pic_table_Q2.csv"),
  Q3 = file.path(DIRS$csv, "grid_pic_table_Q3.csv")
)
rnk_paths <- c(
  Q2 = file.path(DIRS$csv, "grid_rank_decisions_Q2.csv"),
  Q3 = file.path(DIRS$csv, "grid_rank_decisions_Q3.csv")
)

for (b in BASIS_ORDER) {
  if (!file.exists(pic_paths[[b]])) stop("Missing: ", pic_paths[[b]], "  (run engine first)")
  if (!file.exists(rnk_paths[[b]])) stop("Missing: ", rnk_paths[[b]], "  (run engine first)")
}

cat("=== ChaoGrid Report start ===\n")
cat("Root:", ROOT_OUT, "\n\n")

# ---- ingest all ----
read_pic <- function(path, basis) {
  read.csv(path, stringsAsFactors = FALSE) |>
    dplyr::mutate(
      basis  = basis,
      window = as.character(window),
      ecdet  = as.character(ecdet),
      p      = as.integer(p),
      r      = as.integer(r),
      PIC    = as.numeric(PIC),
      BIC    = as.numeric(BIC),
      T      = as.numeric(T),
      m      = as.numeric(m)
    )
}

read_rnk <- function(path, basis) {
  read.csv(path, stringsAsFactors = FALSE) |>
    dplyr::mutate(
      basis  = basis,
      window = as.character(window),
      ecdet  = as.character(ecdet),
      p      = as.integer(p)
    )
}

pic_all <- dplyr::bind_rows(
  read_pic(pic_paths[["Q2"]], "Q2"),
  read_pic(pic_paths[["Q3"]], "Q3")
)

rnk_all <- dplyr::bind_rows(
  read_rnk(rnk_paths[["Q2"]], "Q2"),
  read_rnk(rnk_paths[["Q3"]], "Q3")
)

pic_all <- pic_all |>
  dplyr::mutate(
    basis  = factor(basis,  levels = BASIS_ORDER),
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER)
  ) |>
  dplyr::arrange(basis, window, ecdet, p, r)

rnk_all <- rnk_all |>
  dplyr::mutate(
    basis  = factor(basis,  levels = BASIS_ORDER),
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER)
  ) |>
  dplyr::arrange(basis, window, ecdet, p)

cat("PIC rows (all):", nrow(pic_all), "\n")
cat("Rank rows(all):", nrow(rnk_all), "\n\n")

PIC_scales <- pic_all |>
  dplyr::group_by(window) |>
  dplyr::summarise(
    PIC_lo = min(PIC, na.rm = TRUE),
    PIC_hi = max(PIC, na.rm = TRUE),
    .groups = "drop"
  ) |>
  as.data.frame()

dPIC_caps <- pic_all |>
  dplyr::group_by(basis, window, ecdet) |>
  dplyr::mutate(dPIC = PIC - min(PIC, na.rm = TRUE)) |>
  dplyr::ungroup() |>
  dplyr::group_by(window) |>
  dplyr::summarise(
    dPIC_cap = stats::quantile(dPIC, probs = 0.95, na.rm = TRUE),
    .groups = "drop"
  ) |>
  as.data.frame()

export_csv_tex <- function(df, stem, caption, label, digits = 3) {
  export_pair(
    as.data.frame(df),
    file.path(DIRS$csv, paste0(stem, ".csv")),
    file.path(DIRS$tex, paste0(stem, ".tex")),
    caption = caption,
    label   = label,
    digits  = digits
  )
}

# ============================================================
# SECTION A: per-basis S1..S4 + S5.6 minima storage
# ============================================================
run_report_basis <- function(basis_name) {
  suffix <- paste0("_", basis_name)
  
  pic_table <- pic_all |>
    dplyr::filter(as.character(.data$basis) == basis_name) |>
    dplyr::mutate(
      basis  = as.character(.data$basis),
      window = as.character(.data$window),
      ecdet  = as.character(.data$ecdet)
    )
  
  rank_dec <- rnk_all |>
    dplyr::filter(as.character(.data$basis) == basis_name) |>
    dplyr::mutate(
      basis  = as.character(.data$basis),
      window = as.character(.data$window),
      ecdet  = as.character(.data$ecdet)
    )
  
  cat("\n--- Running basis:", basis_name, "---\n")
  cat("PIC rows:", nrow(pic_table), "\n")
  cat("Rank rows:", nrow(rank_dec), "\n\n")
  
  # S1: grid overview
  S1 <- pic_table |>
    dplyr::group_by(window) |>
    dplyr::summarise(
      T_eff = suppressWarnings(max(T, na.rm = TRUE)),
      m     = suppressWarnings(max(m, na.rm = TRUE)),
      ecdet_levels = paste(label_ecdet(sort(unique(ecdet))), collapse = ", "),
      p_levels     = paste(sort(unique(p)), collapse = ","),
      grid_points  = dplyr::n_distinct(paste(ecdet, p, r, sep = "|")), # fixed: count actual cells
      .groups = "drop"
    ) |>
    dplyr::arrange(match(window, WINDOW_ORDER))
  
  export_csv_tex(
    S1,
    stem = paste0("S1_grid_overview", suffix),
    caption = paste0("S1: Grid overview (", basis_name, ")"),
    label   = paste0("tab:S1_grid_overview", suffix),
    digits  = 0
  )
  
  # S2: rank tests table
  S2 <- rank_dec |>
    dplyr::select(dplyr::any_of(c("basis","window","ecdet","p",
                                  "r_trace_10","r_trace_05","r_trace_01",
                                  "r_eigen_10","r_eigen_05","r_eigen_01"))) |>
    dplyr::mutate(ecdet_label = label_ecdet(ecdet))
  
  export_csv_tex(
    S2,
    stem = paste0("S2_rank_all", suffix),
    caption = paste0("S2: Rank tests (", basis_name, ")"),
    label   = paste0("tab:S2_rank_all", suffix),
    digits  = 0
  )
  
  # S3: top-5 candidates by PIC/BIC per window
  rank_topN <- function(pt, criterion = c("PIC","BIC"), N = 5) {
    criterion <- match.arg(criterion)
    key <- if (criterion == "PIC") pt$PIC else pt$BIC
    
    ord <- order(
      match(pt$window, WINDOW_ORDER),
      key, pt$PIC, pt$BIC,
      pt$p, match(pt$ecdet, ECDET_ORDER), pt$r,
      na.last = TRUE
    )
    
    pt[ord, , drop = FALSE] |>
      dplyr::group_by(window) |>
      dplyr::slice_head(n = N) |>
      dplyr::mutate(
        within_window_rank = dplyr::row_number(),
        criterion = criterion,
        ecdet_label = label_ecdet(ecdet)
      ) |>
      dplyr::ungroup() |>
      as.data.frame()
  }
  
  S3_pic <- rank_topN(pic_table, "PIC", 5)
  S3_bic <- rank_topN(pic_table, "BIC", 5)
  
  export_csv_tex(
    S3_pic,
    stem = paste0("S3_pic_top5", suffix),
    caption = paste0("S3: Top-5 candidates per window by PIC (", basis_name, ")"),
    label   = paste0("tab:S3_pic_top5", suffix),
    digits  = 3
  )
  
  export_csv_tex(
    S3_bic,
    stem = paste0("S3_bic_top5", suffix),
    caption = paste0("S3: Top-5 candidates per window by BIC (", basis_name, ")"),
    label   = paste0("tab:S3_bic_top5", suffix),
    digits  = 3
  )
  
  # S4: final per window (PIC-first)
  S4 <- pic_table |>
    dplyr::group_by(window) |>
    dplyr::arrange(PIC, BIC, p, ecdet, r, .by_group = TRUE) |>
    dplyr::slice_head(n = 1) |>
    dplyr::mutate(
      ecdet_label = label_ecdet(ecdet),
      reason = "Selected: min PIC within window; tie-break BIC then smallest p"
    ) |>
    dplyr::ungroup()
  
  export_csv_tex(
    S4,
    stem = paste0("S4_final_recommendations", suffix),
    caption = paste0("S4: Final recommended specification (PIC-first) (", basis_name, ")"),
    label   = paste0("tab:S4_final_recommendations", suffix),
    digits  = 3
  )
  
  # store minima per (window,ecdet)
  minPIC <- pic_table |>
    dplyr::group_by(window, ecdet) |>
    dplyr::slice_min(order_by = PIC, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::select(window, ecdet, p, r, PIC) |>
    dplyr::mutate(ecdet_label = ECDET_LABELS[as.character(ecdet)])
  
  saveRDS(minPIC, file.path(DIRS$rds, paste0("minPIC_by_window_ecdet", suffix, ".rds")))
  
  # S5.6 boundary diagnostic (SAFE implementation)
  bounds <- pic_table |>
    dplyr::group_by(window, ecdet) |>
    dplyr::summarise(
      p_max = max(p, na.rm = TRUE),
      r_max = max(r, na.rm = TRUE),
      .groups = "drop"
    )
  
  S5_boundary <- pic_table |>
    dplyr::group_by(window, ecdet) |>
    dplyr::slice_min(order_by = PIC, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::left_join(bounds, by = c("window","ecdet")) |>
    dplyr::mutate(
      at_p_max = (p == p_max),
      at_r_max = (r == r_max),
      boundary_min = (at_p_max | at_r_max),
      ecdet_label = ECDET_LABELS[as.character(ecdet)],
      note = ifelse(boundary_min,
                    "Boundary-seeking PIC min (treat as overparameterization signal)",
                    "Interior PIC min (more credible identification)")
    )
  
  export_csv_tex(
    S5_boundary,
    stem = paste0("S5_6_boundary_minima", suffix),
    caption = paste0("S5.6: Boundary-seeking PIC minima diagnostic (", basis_name, ")"),
    label   = paste0("tab:S5_6_boundary_minima", suffix),
    digits  = 0
  )
  
  p6 <- ggplot2::ggplot(S5_boundary, ggplot2::aes(x = window, y = ecdet_label, fill = boundary_min)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::labs(
      title = paste0("S5.6 Boundary-seeking PIC minima (", basis_name, ")"),
      x = "Window", y = "Deterministics", fill = "Boundary?"
    ) +
    ggplot2::theme_minimal(base_size = 12)
  
  ggplot2::ggsave(
    filename = file.path(DIRS$figs, paste0("S5_6_boundary_minima", suffix, ".pdf")),
    plot = p6, width = 9, height = 3.6
  )
  
  invisible(TRUE)
}

invisible(lapply(BASIS_ORDER, run_report_basis))

# ============================================================
# SECTION B: Cross-basis storytelling figures (COMPARE)
# ============================================================

get_window_limits <- function(w, what = c("PIC","dPIC")) {
  what <- match.arg(what)
  if (what == "PIC") {
    row <- PIC_scales[PIC_scales$window == w, , drop = FALSE]
    return(c(row$PIC_lo[1], row$PIC_hi[1]))
  } else {
    row <- dPIC_caps[dPIC_caps$window == w, , drop = FALSE]
    return(c(0, row$dPIC_cap[1]))
  }
}

for (w in WINDOW_ORDER) {
  sub <- pic_all |>
    dplyr::filter(as.character(.data$window) == w) |>
    dplyr::mutate(
      basis_label = as.character(.data$basis),
      ecdet_label = ECDET_LABELS[as.character(.data$ecdet)]
    )
  
  if (nrow(sub) == 0) next
  lims <- get_window_limits(w, "PIC")
  
  p_cmp1 <- ggplot2::ggplot(sub, ggplot2::aes(x = p, y = r, fill = PIC)) +
    ggplot2::geom_tile() +
    ggplot2::facet_grid(basis_label ~ ecdet_label) +
    ggplot2::scale_x_continuous(breaks = sort(unique(sub$p))) +
    ggplot2::scale_y_continuous(breaks = sort(unique(sub$r))) +
    ggplot2::scale_fill_continuous(limits = lims, oob = scales::squish) +
    ggplot2::labs(
      title = paste0("S5.1 PIC landscape (COMPARE Q2 vs Q3; window: ", w, ")"),
      x = "VAR lag length p",
      y = "Cointegration rank r",
      fill = "PIC"
    ) +
    ggplot2::theme_minimal(base_size = 12)
  
  ggplot2::ggsave(
    filename = file.path(DIRS$figs, paste0("S5_1_heatmap_PIC_COMPARE_", w, ".pdf")),
    plot = p_cmp1, width = 12, height = 7.0
  )
}

pic_with_dPIC <- pic_all |>
  dplyr::group_by(basis, window, ecdet) |>
  dplyr::mutate(dPIC = PIC - min(PIC, na.rm = TRUE)) |>
  dplyr::ungroup()

for (w in WINDOW_ORDER) {
  sub <- pic_with_dPIC |>
    dplyr::filter(as.character(.data$window) == w) |>
    dplyr::mutate(
      basis_label = as.character(.data$basis),
      ecdet_label = ECDET_LABELS[as.character(.data$ecdet)]
    )
  
  if (nrow(sub) == 0) next
  lims <- get_window_limits(w, "dPIC")
  
  p_cmp2 <- ggplot2::ggplot(sub, ggplot2::aes(x = p, y = r, fill = dPIC)) +
    ggplot2::geom_tile() +
    ggplot2::facet_grid(basis_label ~ ecdet_label) +
    ggplot2::scale_x_continuous(breaks = sort(unique(sub$p))) +
    ggplot2::scale_y_continuous(breaks = sort(unique(sub$r))) +
    ggplot2::scale_fill_continuous(limits = lims, oob = scales::squish) +
    ggplot2::labs(
      title = paste0("S5.2 ΔPIC from best (COMPARE Q2 vs Q3; window: ", w, ")"),
      x = "VAR lag length p",
      y = "Cointegration rank r",
      fill = "ΔPIC"
    ) +
    ggplot2::theme_minimal(base_size = 12)
  
  ggplot2::ggsave(
    filename = file.path(DIRS$figs, paste0("S5_2_heatmap_dPIC_COMPARE_", w, ".pdf")),
    plot = p_cmp2, width = 12, height = 7.0
  )
}

best_by_p_all <- pic_all |>
  dplyr::group_by(basis, window, ecdet, p) |>
  dplyr::summarise(PIC_best = min(PIC, na.rm = TRUE), .groups = "drop") |>
  dplyr::mutate(
    basis_label = as.character(.data$basis),
    ecdet_label = ECDET_LABELS[as.character(.data$ecdet)]
  )

for (w in WINDOW_ORDER) {
  sub <- best_by_p_all |>
    dplyr::filter(as.character(.data$window) == w)
  if (nrow(sub) == 0) next
  
  p_cmp3 <- ggplot2::ggplot(sub, ggplot2::aes(x = p, y = PIC_best, group = interaction(basis_label, ecdet_label))) +
    ggplot2::geom_line() +
    ggplot2::geom_point(size = 2) +
    ggplot2::facet_grid(basis_label ~ ecdet_label, scales = "free_y") +
    ggplot2::scale_x_continuous(breaks = sort(unique(sub$p))) +
    ggplot2::labs(
      title = paste0("S5.3 Best PIC by p (COMPARE Q2 vs Q3; window: ", w, ")"),
      x = "VAR lag length p",
      y = "min_r PIC"
    ) +
    ggplot2::theme_minimal(base_size = 12)
  
  ggplot2::ggsave(
    filename = file.path(DIRS$figs, paste0("S5_3_line_bestPIC_by_p_COMPARE_", w, ".pdf")),
    plot = p_cmp3, width = 12, height = 6.5
  )
}

best_r_map_all <- pic_all |>
  dplyr::group_by(basis, window, ecdet, p) |>
  dplyr::slice_min(order_by = PIC, n = 1, with_ties = FALSE) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    basis_label = as.character(.data$basis),
    ecdet_label = ECDET_LABELS[as.character(.data$ecdet)]
  )

for (w in WINDOW_ORDER) {
  sub <- best_r_map_all |> dplyr::filter(as.character(.data$window) == w)
  if (nrow(sub) == 0) next
  
  p5 <- ggplot2::ggplot(sub, ggplot2::aes(x = p, y = ecdet_label, fill = r)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::facet_wrap(~ basis_label, nrow = 1) +
    ggplot2::scale_x_continuous(breaks = sort(unique(sub$p))) +
    ggplot2::labs(
      title = paste0("S5.5 Best rank r*(p) (argmin_r PIC; window: ", w, ")"),
      x = "VAR lag length p",
      y = "Deterministics",
      fill = "r*(p)"
    ) +
    ggplot2::theme_minimal(base_size = 12)
  
  ggplot2::ggsave(
    filename = file.path(DIRS$figs, paste0("S5_5_heatmap_bestR_by_p_COMPARE_", w, ".pdf")),
    plot = p5, width = 11, height = 3.8
  )
}

mQ2 <- readRDS(file.path(DIRS$rds, "minPIC_by_window_ecdet_Q2.rds"))
mQ3 <- readRDS(file.path(DIRS$rds, "minPIC_by_window_ecdet_Q3.rds"))

S5_7 <- mQ2 |>
  dplyr::rename(p_Q2 = p, r_Q2 = r, PIC_Q2 = PIC) |>
  dplyr::left_join(
    mQ3 |> dplyr::rename(p_Q3 = p, r_Q3 = r, PIC_Q3 = PIC),
    by = c("window","ecdet","ecdet_label")
  ) |>
  dplyr::mutate(
    dPIC_Q3_minus_Q2 = PIC_Q3 - PIC_Q2,
    winner = ifelse(dPIC_Q3_minus_Q2 < 0, "Q3 (lower PIC)", "Q2 (lower PIC)")
  ) |>
  dplyr::arrange(match(window, WINDOW_ORDER), match(ecdet, ECDET_ORDER))

export_csv_tex(
  S5_7,
  stem = "S5_7_Q3_vs_Q2_minPIC",
  caption = "S5.7: Q3 vs Q2 comparison using global minimum PIC (per window, ecdet)",
  label   = "tab:S5_7_Q3_vs_Q2_minPIC",
  digits  = 4
)

p7 <- ggplot2::ggplot(S5_7, ggplot2::aes(x = window, y = dPIC_Q3_minus_Q2, group = ecdet_label)) +
  ggplot2::geom_hline(yintercept = 0, linetype = 2) +
  ggplot2::geom_line() +
  ggplot2::geom_point(size = 2) +
  ggplot2::facet_wrap(~ ecdet_label, nrow = 1) +
  ggplot2::labs(
    title = "S5.7 Q3 vs Q2: Δ(min PIC) = minPIC(Q3) - minPIC(Q2)",
    x = "Window",
    y = "Δ(min PIC): negative favors Q3"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  filename = file.path(DIRS$figs, "S5_7_Q3_vs_Q2_minPIC.pdf"),
  plot = p7, width = 11, height = 4.2
)

# ============================================================
# OPTIONAL SECTION S6: index table if inference artifacts exist
# ============================================================
s6_files <- list.files(DIRS$csv, pattern = "^S6_theta_.*_curve\\.csv$", full.names = TRUE)
if (length(s6_files) > 0) {
  S6_index <- data.frame(
    file = basename(s6_files),
    basis  = sub("^S6_theta_(Q2|Q3)_.*$", "\\1", basename(s6_files)),
    window = sub("^S6_theta_(Q2|Q3)_([a-z]+)_.*$", "\\2", basename(s6_files)),
    ecdet  = sub("^S6_theta_(Q2|Q3)_[a-z]+_([a-z]+)_p.*$", "\\2", basename(s6_files)),
    p = as.integer(sub(".*_p([0-9]+)_r.*$", "\\1", basename(s6_files))),
    r = as.integer(sub(".*_r([0-9]+)_curve\\.csv$", "\\1", basename(s6_files))),
    stringsAsFactors = FALSE
  ) |>
    dplyr::arrange(match(window, WINDOW_ORDER), match(basis, BASIS_ORDER), match(ecdet, ECDET_ORDER), p, r)
  
  export_csv_tex(
    S6_index,
    stem = "S6_theta_index",
    caption = "S6: Index of theta inference artifacts generated by the engine",
    label   = "tab:S6_theta_index",
    digits  = 0
  )
  cat("\nS6 artifacts detected: wrote S6_theta_index.{csv,tex}\n")
} else {
  cat("\nNOTE: No S6 inference artifacts found in output/ChaoGrid/csv (run engine with S6 enabled).\n")
}

cat("\n=== ChaoGrid Report completed ===\n")
cat("Exports written to:", ROOT_OUT, "\n")
sink()
