############################################################
## ChaoGrid_Report.R  (tables + optional figures, self-contained)
##
## Reads:
##   output/ChaoGrid/csv/grid_pic_table.csv
##   output/ChaoGrid/csv/grid_rank_decisions.csv
##
## Writes:
##   output/ChaoGrid/csv : S1..S4 csvs
##   output/ChaoGrid/tex : S1..S4 texs
##   output/ChaoGrid/figs: optional figures (heatmap, etc.)
##   output/ChaoGrid/logs: report_log.txt (console capture)
############################################################

## ---- packages ----
pkgs <- c("here","dplyr","knitr","kableExtra","ggplot2","conflicted")
invisible(lapply(pkgs, require, character.only = TRUE))

#--- Source and run helpers functions ------#
codes_path <- here("codes")
helpers_path <- here(codes_path,"0_functions.R")
source(helpers_path)


## ---- paths ----
log_file <- file.path(DIRS$logs, "report_log.txt")
sink(log_file, split = TRUE)

WINDOW_ORDER <- c("full","ford","post")
ECDET_ORDER  <- c("none","const","trend")

## ---- ingest ----
pic_path  <- file.path(DIRS$csv, "grid_pic_table.csv")
rank_path <- file.path(DIRS$csv, "grid_rank_decisions.csv")

if (!file.exists(pic_path)) stop("Missing grid_pic_table.csv. Run ChaoGrid_Engine.R first.")
if (!file.exists(rank_path)) stop("Missing grid_rank_decisions.csv. Run ChaoGrid_Engine.R first.")

pic_table <- utils::read.csv(pic_path, stringsAsFactors = FALSE)
rank_dec  <- utils::read.csv(rank_path, stringsAsFactors = FALSE)

# coerce + order
pic_table$window <- as.character(pic_table$window)
pic_table$ecdet  <- as.character(pic_table$ecdet)
pic_table$p      <- as.integer(pic_table$p)
pic_table$r      <- as.integer(pic_table$r)

rank_dec$window <- as.character(rank_dec$window)
rank_dec$ecdet  <- as.character(rank_dec$ecdet)
rank_dec$p      <- as.integer(rank_dec$p)

pic_table <- pic_table[order(match(pic_table$window, WINDOW_ORDER),
                             match(pic_table$ecdet, ECDET_ORDER),
                             pic_table$p, pic_table$r), , drop = FALSE]

rank_dec <- rank_dec[order(match(rank_dec$window, WINDOW_ORDER),
                           match(rank_dec$ecdet, ECDET_ORDER),
                           rank_dec$p), , drop = FALSE]

cat("=== ChaoGrid Report start ===\n")
cat("PIC rows:", nrow(pic_table), "\n")
cat("Rank rows:", nrow(rank_dec), "\n\n")

## ---- S1: grid overview ----
S1_grid_overview <- pic_table |>
  dplyr::group_by(window) |>
  dplyr::summarise(
    T_eff = suppressWarnings(max(T, na.rm = TRUE)),
    m     = suppressWarnings(max(m, na.rm = TRUE)),
    ecdet_levels = paste(label_ecdet(sort(unique(ecdet))), collapse = ", "),
    p_levels     = paste(sort(unique(p)), collapse = ","),
    grid_points  = dplyr::n_distinct(paste(ecdet, p)),
    .groups = "drop"
  ) |>
  dplyr::as_tibble()

S1_grid_overview <- S1_grid_overview[order(match(S1_grid_overview$window, WINDOW_ORDER)), , drop = FALSE]

export_pair(
  as.data.frame(S1_grid_overview),
  file.path(DIRS$csv, "S1_grid_overview.csv"),
  file.path(DIRS$tex, "S1_grid_overview.tex"),
  caption = "S1: Grid overview (dimensions, effective T, system size m)",
  label   = "tab:S1_grid_overview",
  digits  = 0
)

## ---- S2: rank tests + disagreement ----
S2_rank_all <- rank_dec[, intersect(names(rank_dec),
                                    c("window","ecdet","p","r_trace_10","r_trace_05","r_trace_01","r_eigen_10","r_eigen_05","r_eigen_01")
), drop = FALSE]

S2_rank_all$ecdet_label <- label_ecdet(S2_rank_all$ecdet)

S2_rank_disagreement <- S2_rank_all
if (all(c("r_trace_05","r_eigen_05") %in% names(S2_rank_disagreement)))
  S2_rank_disagreement$disagree_05 <- (S2_rank_disagreement$r_trace_05 != S2_rank_disagreement$r_eigen_05)
if (all(c("r_trace_10","r_eigen_10") %in% names(S2_rank_disagreement)))
  S2_rank_disagreement$disagree_10 <- (S2_rank_disagreement$r_trace_10 != S2_rank_disagreement$r_eigen_10)
if (all(c("r_trace_01","r_eigen_01") %in% names(S2_rank_disagreement)))
  S2_rank_disagreement$disagree_01 <- (S2_rank_disagreement$r_trace_01 != S2_rank_disagreement$r_eigen_01)

export_pair(
  S2_rank_all,
  file.path(DIRS$csv, "S2_rank_all.csv"),
  file.path(DIRS$tex, "S2_rank_all.tex"),
  caption = "S2: Rank tests (trace and eigen, suggested ranks)",
  label   = "tab:S2_rank_all",
  digits  = 0
)

export_pair(
  S2_rank_disagreement,
  file.path(DIRS$csv, "S2_rank_disagreement.csv"),
  file.path(DIRS$tex, "S2_rank_disagreement.tex"),
  caption = "S2: Rank disagreement diagnostics",
  label   = "tab:S2_rank_disagreement",
  digits  = 0
)

## ---- S3: top-5 by PIC and top-5 by BIC ----
rank_topN <- function(pt, criterion = c("PIC","BIC"), N = 5) {
  criterion <- match.arg(criterion)
  key <- if (criterion == "PIC") pt$PIC else pt$BIC
  
  ord <- order(match(pt$window, WINDOW_ORDER),
               key, pt$PIC, pt$BIC,
               pt$p, match(pt$ecdet, ECDET_ORDER), pt$r,
               na.last = TRUE)
  
  out <- pt[ord, , drop = FALSE] |>
    dplyr::group_by(window) |>
    dplyr::slice_head(n = N) |>
    dplyr::mutate(within_window_rank = dplyr::row_number(),
                  criterion = criterion,
                  ecdet_label = label_ecdet(ecdet)) |>
    dplyr::ungroup()
  
  as.data.frame(out)
}

S3_pic_top5 <- rank_topN(pic_table, "PIC", 5)
S3_bic_top5 <- rank_topN(pic_table, "BIC", 5)

export_pair(
  S3_pic_top5,
  file.path(DIRS$csv, "S3_pic_top5.csv"),
  file.path(DIRS$tex, "S3_pic_top5.tex"),
  caption = "S3: Top-5 candidates per window by PIC",
  label   = "tab:S3_pic_top5",
  digits  = 3
)

export_pair(
  S3_bic_top5,
  file.path(DIRS$csv, "S3_bic_top5.csv"),
  file.path(DIRS$tex, "S3_bic_top5.tex"),
  caption = "S3: Top-5 candidates per window by BIC",
  label   = "tab:S3_bic_top5",
  digits  = 3
)

## ---- S4: simple final recommendation (PIC min per window, tie-break by BIC then smallest p) ----
S4_final <- pic_table |>
  dplyr::group_by(window) |>
  dplyr::arrange(PIC, BIC, p, ecdet, r, .by_group = TRUE) |>
  dplyr::slice_head(n = 1) |>
  dplyr::mutate(
    ecdet_label = label_ecdet(ecdet),
    reason = "Selected: min PIC within window; tie-break BIC then smallest p"
  ) |>
  dplyr::ungroup() |>
  dplyr::as_tibble()

S4_final <- S4_final[order(match(S4_final$window, WINDOW_ORDER)), , drop = FALSE]

export_pair(
  as.data.frame(S4_final),
  file.path(DIRS$csv, "S4_final_recommendations.csv"),
  file.path(DIRS$tex, "S4_final_recommendations.tex"),
  caption = "S4: Final recommended specification per window (PIC-first)",
  label   = "tab:S4_final_recommendations",
  digits  = 3
)

## ---- optional figure: heatmap (PIC surface per window) ----
# This actually adds information: you see the PIC landscape (p vs r) and how ecdet shifts it.
make_heatmap <- function(pt, window_name) {
  sub <- pt[pt$window == window_name, , drop = FALSE]
  if (nrow(sub) == 0) return(NULL)
  sub$ecdet_label <- factor(label_ecdet(sub$ecdet),
                            levels = c("No Constant","Constant","Trend"))
  
  ggplot2::ggplot(sub, ggplot2::aes(x = factor(p), y = factor(r), fill = PIC)) +
    ggplot2::geom_tile() +
    ggplot2::facet_wrap(~ ecdet_label, nrow = 1) +
    ggplot2::labs(
      title = paste0("PIC heatmap: window = ", window_name),
      x = "p (VAR lag length)",
      y = "r (cointegration rank)"
    )
}

for (w in WINDOW_ORDER) {
  p_hm <- make_heatmap(pic_table, w)
  if (!is.null(p_hm)) {
    fig_path <- file.path(DIRS$figs, paste0("F1_PIC_heatmap_", w, ".pdf"))
    ggplot2::ggsave(fig_path, plot = p_hm, width = 10, height = 4)
  }
}

## ---- console summary ----
cat("\n========================================\n")
cat("ChaoGrid_Report: FINAL RECOMMENDATIONS (S4)\n")
cat("========================================\n")
print(as.data.frame(S4_final[, c("window","ecdet","ecdet_label","p","r","T","m","logdet","PIC","BIC","reason")]))

cat("\n=== ChaoGrid Report completed ===\n")
cat("Exports written to:", ROOT_OUT, "\n")

sink()

## ---- S5: Visual diagnostics (ChaoGrid) ----
# Requires: output/ChaoGrid produced by ChaoGrid_Engine.R
# Produces: output/ChaoGrid/figs/*.pdf

### --- deps ---
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Need ggplot2 installed.")
library(ggplot2)
library(dplyr)


## --- canonical labels (locked) ---
WINDOW_ORDER <- c("full","ford","post")
ECDET_ORDER  <- c("none","const","trend")
ECDET_LABELS <- c(
  none  = "No Constant",
  const = "Constant",
  trend = "Trend"
)

## --- load grid outputs (prefer RDS) ---
grid_rds <- file.path(DIRS$rds, "grid_full.rds")
if (file.exists(grid_rds)) {
  G <- readRDS(grid_rds)
  grid_pic_table      <- G$pic_table
  grid_rank_decisions <- G$rank_decisions
} else {
  pic_csv  <- file.path(DIRS$csv, "grid_pic_table.csv")
  rank_csv <- file.path(DIRS$csv, "grid_rank_decisions.csv")
  if (!file.exists(pic_csv) || !file.exists(rank_csv)) {
    stop("Cannot find grid outputs. Expected either rds/grid_full.rds or csv/grid_pic_table.csv + csv/grid_rank_decisions.csv")
  }
  grid_pic_table      <- read.csv(pic_csv,  stringsAsFactors = FALSE)
  grid_rank_decisions <- read.csv(rank_csv, stringsAsFactors = FALSE)
}

## --- normalize ordering/types ---
grid_pic_table <- grid_pic_table |>
  mutate(
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER),
    p = as.integer(p),
    r = as.integer(r)
  ) |>
  arrange(window, ecdet, p, r)

grid_rank_decisions <- grid_rank_decisions |>
  mutate(
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER),
    p = as.integer(p)
  ) |>
  arrange(window, ecdet, p)

## --- helpers ---
save_fig <- function(plot_obj, stem, width = 11, height = 6.5) {
  out <- file.path(DIRS$figs, paste0(stem, ".pdf"))
  ggsave(filename = out, plot = plot_obj, width = width, height = height, device = cairo_pdf)
  invisible(out)
}

min_cell_points <- function(dfw) {
  # Mark the best (p,r) per (ecdet) within a given window
  dfw |>
    group_by(ecdet) |>
    slice_min(order_by = PIC, n = 1, with_ties = TRUE) |>
    ungroup() |>
    select(ecdet, p, r, PIC)
}


### ---- S5.1 Heatmap: PIC landscape (p × r), facet ecdet, per window ----

for (w in WINDOW_ORDER) {
  dfw <- grid_pic_table |> filter(as.character(window) == w)
  
  winners <- min_cell_points(dfw)
  
  p1 <- ggplot(dfw, aes(x = p, y = r, fill = PIC)) +
    geom_tile() +
    geom_point(data = winners, aes(x = p, y = r), inherit.aes = FALSE, size = 2) +
    facet_wrap(~ ecdet, labeller = as_labeller(ECDET_LABELS)) +
    scale_x_continuous(breaks = sort(unique(dfw$p))) +
    scale_y_continuous(breaks = sort(unique(dfw$r))) +
    labs(
      title = paste0("S5.1 PIC landscape (window: ", w, ")"),
      x = "VAR lag length p",
      y = "Cointegration rank r",
      fill = "PIC"
    ) +
    theme_minimal(base_size = 12)
  
  save_fig(p1, paste0("S5_1_heatmap_PIC_", w), width = 11, height = 6.5)
}



### ---- S5.2 Heatmap: ΔPIC from best-in-ecdet (makes ties obvious) ----

for (w in WINDOW_ORDER) {
  dfw <- grid_pic_table |> filter(as.character(window) == w) |>
    group_by(ecdet) |>
    mutate(PIC_min = min(PIC, na.rm = TRUE),
           dPIC = PIC - PIC_min) |>
    ungroup()
  
  p2 <- ggplot(dfw, aes(x = p, y = r, fill = dPIC)) +
    geom_tile() +
    facet_wrap(~ ecdet, labeller = as_labeller(ECDET_LABELS)) +
    scale_x_continuous(breaks = sort(unique(dfw$p))) +
    scale_y_continuous(breaks = sort(unique(dfw$r))) +
    labs(
      title = paste0("S5.2 ΔPIC from best (window: ", w, ")"),
      x = "VAR lag length p",
      y = "Cointegration rank r",
      fill = "ΔPIC"
    ) +
    theme_minimal(base_size = 12)
  
  save_fig(p2, paste0("S5_2_heatmap_dPIC_", w), width = 11, height = 6.5)
}

### ---- S5.3 Line plot: best PIC by p (shows lag-length sensitivity) ----

for (w in WINDOW_ORDER) {
  best_by_p <- grid_pic_table |> filter(as.character(window) == w) |>
    group_by(ecdet, p) |>
    summarise(PIC_best = min(PIC, na.rm = TRUE), .groups = "drop")
  
  p3 <- ggplot(best_by_p, aes(x = p, y = PIC_best, group = ecdet)) +
    geom_line() +
    geom_point(size = 2) +
    facet_wrap(~ ecdet, labeller = as_labeller(ECDET_LABELS), scales = "free_y") +
    scale_x_continuous(breaks = sort(unique(best_by_p$p))) +
    labs(
      title = paste0("S5.3 Best PIC by lag length p (window: ", w, ")"),
      x = "VAR lag length p",
      y = "min_r PIC"
    ) +
    theme_minimal(base_size = 12)
  
  save_fig(p3, paste0("S5_3_line_bestPIC_by_p_", w), width = 11, height = 6.0)
}

### ---- S5.4 “Rank instability” map: trace vs eigen disagreement at 5% ----

if (all(c("r_trace_05","r_eigen_05") %in% names(grid_rank_decisions))) {
  for (w in WINDOW_ORDER) {
    rnk <- grid_rank_decisions |> filter(as.character(window) == w) |>
      mutate(disagree_05 = (r_trace_05 != r_eigen_05))
    
    p4 <- ggplot(rnk, aes(x = p, y = ecdet, fill = disagree_05)) +
      geom_tile(color = "white") +
      facet_wrap(~ window) +
      scale_x_continuous(breaks = sort(unique(rnk$p))) +
      labs(
        title = paste0("S5.4 Trace vs Eigen disagreement at 5% (window: ", w, ")"),
        x = "VAR lag length p",
        y = "Deterministics (EC term)",
        fill = "Disagree?"
      ) +
      theme_minimal(base_size = 12)
    
    save_fig(p4, paste0("S5_4_rank_disagreement_05_", w), width = 11, height = 4.5)
  }
}

cat("\nS5 completed. Figures written to: ", DIRS$figs, "\n", sep = "")

