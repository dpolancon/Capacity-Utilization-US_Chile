############################################################
## ChaoGrid_Ingest_Analysis.R
## Purpose:
##   Ingest ChaoGrid_Report figures + grid artifacts
##   Build an analysis-ready bundle (no re-estimation).
############################################################

pkgs <- c("here","dplyr","readr","stringr","fs")
invisible(lapply(pkgs, require, character.only = TRUE))

# --- paths (LOCKED) ---
ROOT_OUT <- here::here("output/ChaoGrid")
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  rds  = file.path(ROOT_OUT, "rds"),
  figs = file.path(ROOT_OUT, "figs"),
  logs = file.path(ROOT_OUT, "logs"),
  tex  = file.path(ROOT_OUT, "tex")
)

WINDOW_ORDER <- c("full","ford","post")
ECDET_ORDER  <- c("none","const","trend")
ECDET_LABELS <- c(none="No Constant", const="Constant", trend="Trend")

# --- load authoritative grid outputs (prefer RDS) ---
grid_rds <- file.path(DIRS$rds, "grid_full.rds")

if (file.exists(grid_rds)) {
  G <- readRDS(grid_rds)
  pic_table  <- G$pic_table
  rank_dec   <- G$rank_decisions
} else {
  pic_csv  <- file.path(DIRS$csv, "grid_pic_table.csv")
  rank_csv <- file.path(DIRS$csv, "grid_rank_decisions.csv")
  if (!file.exists(pic_csv) || !file.exists(rank_csv)) {
    stop("Missing grid outputs. Run ChaoGrid_Engine.R first.")
  }
  pic_table <- readr::read_csv(pic_csv, show_col_types = FALSE)
  rank_dec  <- readr::read_csv(rank_csv, show_col_types = FALSE)
}

# --- normalize types + ordering ---
pic_table <- pic_table |>
  dplyr::mutate(
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER),
    p = as.integer(p),
    r = as.integer(r)
  ) |>
  dplyr::arrange(window, ecdet, p, r)

rank_dec <- rank_dec |>
  dplyr::mutate(
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER),
    p = as.integer(p)
  ) |>
  dplyr::arrange(window, ecdet, p)

# --- ingest figure inventory (S5.* PDFs) ---
fig_index <- fs::dir_ls(DIRS$figs, regexp = "\\.pdf$") |>
  tibble::tibble(path = .) |>
  dplyr::mutate(
    file = basename(path),
    # crude but robust parsing based on your naming convention
    window = dplyr::case_when(
      stringr::str_detect(file, "_full") ~ "full",
      stringr::str_detect(file, "_ford") ~ "ford",
      stringr::str_detect(file, "_post") ~ "post",
      TRUE ~ NA_character_
    ),
    fig_family = dplyr::case_when(
      stringr::str_detect(file, "^S5_1_") ~ "S5.1 PIC heatmap",
      stringr::str_detect(file, "^S5_2_") ~ "S5.2 Rank stability ribbon",
      stringr::str_detect(file, "^S5_3_") ~ "S5.3 PIC vs BIC tradeoff",
      stringr::str_detect(file, "^S5_4_") ~ "S5.4 Robustness plateau",
      TRUE ~ "Other"
    )
  ) |>
  dplyr::mutate(window = factor(window, levels = WINDOW_ORDER)) |>
  dplyr::arrange(fig_family, window, file)

# --- core derived objects for interpretation (no estimation) ---

# 1) winners per (window, ecdet) by PIC + tie-break BIC + p
winners_by_ecdet <- pic_table |>
  dplyr::group_by(window, ecdet) |>
  dplyr::arrange(PIC, BIC, p, r, .by_group = TRUE) |>
  dplyr::slice_head(n = 1) |>
  dplyr::ungroup() |>
  dplyr::mutate(ecdet_label = ECDET_LABELS[as.character(ecdet)])

# 2) global winner per window (matches your S4 logic)
winner_by_window <- pic_table |>
  dplyr::group_by(window) |>
  dplyr::arrange(PIC, BIC, p, ecdet, r, .by_group = TRUE) |>
  dplyr::slice_head(n = 1) |>
  dplyr::ungroup() |>
  dplyr::mutate(ecdet_label = ECDET_LABELS[as.character(ecdet)])

# 3) plateau map: near-min within window (ΔPIC <= tol)
tol <- 0.05  # start small; can loosen to 0.10 / 0.20 later
plateau <- pic_table |>
  dplyr::group_by(window) |>
  dplyr::mutate(PIC_min = min(PIC, na.rm = TRUE),
                dPIC = PIC - PIC_min,
                on_plateau = dPIC <= tol) |>
  dplyr::ungroup()

# 4) rank disagreement diagnostics (trace vs eigen at 5%)
rank_diag <- rank_dec |>
  dplyr::mutate(
    disagree_05 = (r_trace_05 != r_eigen_05),
    disagree_10 = (r_trace_10 != r_eigen_10),
    disagree_01 = (r_trace_01 != r_eigen_01),
    ecdet_label = ECDET_LABELS[as.character(ecdet)]
  )

# --- minimal “analysis checklist” object (what each figure should support) ---
analysis_checklist <- tibble::tibble(
  figure = c("S5.1","S5.2","S5.3","S5.4"),
  claim_it_should_support = c(
    "PIC landscape has a clear basin; minima not an isolated pixel. Winner(s) marked.",
    "Suggested rank is stable across p and alpha, or instability is localized and interpretable.",
    "PIC–BIC tradeoff reveals whether selection is ‘sharp’ or a continuum of near-equivalents.",
    "There is a robustness plateau around the global min; or lack of plateau indicates fragility."
  ),
  failure_mode = c(
    "Multiple unrelated minima; winner flips wildly across ecdet.",
    "Rank suggestions jump erratically; trace vs eigen disagree systematically.",
    "Tradeoff cloud has no structure; BIC punishes everything into corner.",
    "No near-min region: single cell dominates, suggests overfit or counting issue."
  )
)

# --- bundle for downstream narrative (save once) ---
bundle <- list(
  fig_index = fig_index,
  winner_by_window = winner_by_window,
  winners_by_ecdet = winners_by_ecdet,
  plateau = plateau,
  rank_diag = rank_diag,
  checklist = analysis_checklist
)

saveRDS(bundle, file.path(DIRS$rds, "analysis_bundle.rds"))

cat("Ingestion complete.\n")
cat("Figures indexed:", nrow(fig_index), "\n")
cat("Bundle saved:", file.path(DIRS$rds, "analysis_bundle.rds"), "\n")
