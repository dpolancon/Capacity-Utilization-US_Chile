#!/usr/bin/env Rscript

# ============================================================
# 26_crosswalk_tables.R
# Build canonical crosswalks from geometry/envelope outputs.
# Writes to: output/CriticalReplication/Crosswalk/
# ============================================================

options(stringsAsFactors = FALSE)

suppressPackageStartupMessages({
  library(here)
})

source(here::here("codes", "99_utils.R"))


source(here::here("codes", "10_config.R"))

out_root <- here::here(CONFIG$OUT_CR_ROOT %||% "output/CriticalReplication")
crosswalk_dir <- here::here(CONFIG$OUT_CR$crosswalk %||% file.path("output", "CriticalReplication", "Crosswalk"))
dir.create(crosswalk_dir, recursive = TRUE, showWarnings = FALSE)

message("[crosswalk] Output directory: ", normalizePath(crosswalk_dir, winslash = "/", mustWork = FALSE))

csv_files <- list.files(out_root, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
if (length(csv_files) > 0L) {
  csv_files <- csv_files[!grepl("/Crosswalk/", gsub("\\\\", "/", csv_files), ignore.case = TRUE)]
}

read_csv_safe <- function(path) {
  out <- tryCatch(utils::read.csv(path, check.names = FALSE), error = function(e) NULL)
  if (is.null(out)) return(NULL)
  out$.source_file <- path
  out
}

norm_names <- function(nm) {
  gsub("[^a-z0-9]+", "", tolower(nm))
}

pick_col <- function(df, candidates) {
  if (is.null(df) || nrow(df) == 0L) return(rep(NA_real_, 0L))
  nm <- names(df)
  key <- norm_names(nm)
  cand_key <- norm_names(candidates)
  idx <- match(cand_key, key)
  idx <- idx[!is.na(idx)]
  if (length(idx) == 0L) return(rep(NA, nrow(df)))
  df[[idx[1L]]]
}

as_num <- function(x) suppressWarnings(as.numeric(x))
as_chr <- function(x) {
  y <- as.character(x)
  y[is.na(y)] <- ""
  y
}

first_non_missing <- function(...) {
  xs <- list(...)
  if (length(xs) == 0L) return(NULL)
  out <- xs[[1L]]
  if (is.null(out)) return(NULL)
  for (i in seq_along(xs)[-1L]) {
    xi <- xs[[i]]
    if (is.null(xi)) next
    needs <- is.na(out) | out == ""
    out[needs] <- xi[needs]
  }
  out
}

build_canonical <- function(df) {
  if (is.null(df) || nrow(df) == 0L) return(df)

  model_class <- first_non_missing(
    as_chr(pick_col(df, c("model_class", "exercise", "exercise_id", "class"))),
    ifelse(grepl("ardl", tolower(df$.source_file)), "ARDL", NA),
    ifelse(grepl("vecm", tolower(df$.source_file)), "VECM", NA)
  )

  slope_hat <- as_num(first_non_missing(
    pick_col(df, c("slope_hat", "theta_hat", "theta", "slope"))
  ))

  data.frame(
    representative_group = NA_character_,
    representative_label = NA_character_,
    exercise_id = as_chr(first_non_missing(pick_col(df, c("exercise_id", "exercise")), model_class)),
    model_class = model_class,
    window_tag = as_chr(pick_col(df, c("window_tag", "window"))),
    det_tag = as_chr(pick_col(df, c("det_tag", "deterministic_tag", "det"))),
    m = as_num(pick_col(df, c("m"))),
    p = as_num(pick_col(df, c("p"))),
    q = as_num(pick_col(df, c("q"))),
    q_tag = as_chr(pick_col(df, c("q_tag", "q_profile"))),
    r = as_num(pick_col(df, c("r", "rank"))),
    cell_id = as_chr(pick_col(df, c("cell_id", "id"))),
    slope_hat = slope_hat,
    lambda = as_num(pick_col(df, c("lambda"))),
    alpha_y = as_num(pick_col(df, c("alpha_y"))),
    alpha_k = as_num(pick_col(df, c("alpha_k"))),
    alpha_e = as_num(pick_col(df, c("alpha_e"))),
    sK_ardl = as_num(pick_col(df, c("sK_ardl", "s_k_ardl", "s_K", "sK", "memory_share"))),
    share_K = as_num(pick_col(df, c("share_K", "share_k"))),
    logLik = as_num(pick_col(df, c("logLik", "ll"))),
    k_total = as_num(pick_col(df, c("k_total", "k"))),
    ICOMP_pen = as_num(pick_col(df, c("ICOMP_pen", "icomp_pen"))),
    RICOMP_pen = as_num(pick_col(df, c("RICOMP_pen", "ricomp_pen"))),
    stability_margin = as_num(pick_col(df, c("stability_margin", "margin"))),
    SI_Y = as_num(pick_col(df, c("SI_Y", "si_y"))),
    boundary_p = as_chr(pick_col(df, c("boundary_p"))),
    boundary_q = as_chr(pick_col(df, c("boundary_q"))),
    boundary_r = as_chr(pick_col(df, c("boundary_r"))),
    boundary_tags = as_chr(pick_col(df, c("boundary_tags", "boundary_tag"))),
    source_file = as_chr(df$.source_file),
    stringsAsFactors = FALSE
  )
}

extract_frontier <- function(df, x_col) {
  if (is.null(df) || nrow(df) == 0L || !(x_col %in% names(df))) return(df[0, , drop = FALSE])
  x <- df[[x_col]]
  y <- df$logLik
  ok <- is.finite(x) & is.finite(y)
  tmp <- df[ok, , drop = FALSE]
  if (nrow(tmp) == 0L) return(df[0, , drop = FALSE])

  ord <- order(tmp[[x_col]], -tmp$logLik)
  tmp <- tmp[ord, , drop = FALSE]

  by_x <- split(tmp, tmp[[x_col]])
  best_per_x <- do.call(rbind, lapply(by_x, function(d) d[which.max(d$logLik), , drop = FALSE]))
  best_per_x <- best_per_x[order(best_per_x[[x_col]]), , drop = FALSE]

  running_max <- -Inf
  keep <- logical(nrow(best_per_x))
  for (i in seq_len(nrow(best_per_x))) {
    if (best_per_x$logLik[i] > running_max) {
      keep[i] <- TRUE
      running_max <- best_per_x$logLik[i]
    }
  }
  best_per_x[keep, , drop = FALSE]
}

mark_group <- function(df, group_name, label_prefix) {
  if (nrow(df) == 0L) return(df)
  df$representative_group <- group_name
  df$representative_label <- sprintf("%s_%02d", label_prefix, seq_len(nrow(df)))
  df
}

all_raw <- lapply(csv_files, read_csv_safe)
all_raw <- all_raw[!vapply(all_raw, is.null, logical(1))]

canonical <- if (length(all_raw) > 0L) {
  do.call(rbind, lapply(all_raw, build_canonical))
} else {
  data.frame()
}

if (nrow(canonical) > 0L) {
  canonical$model_class <- toupper(as_chr(canonical$model_class))

  # infer missing q from q_tag when possible (e.g., q2_4)
  miss_q <- !is.finite(canonical$q) & nzchar(canonical$q_tag)
  if (any(miss_q)) {
    q_guess <- suppressWarnings(as.numeric(sub(".*_", "", canonical$q_tag[miss_q])))
    canonical$q[miss_q] <- q_guess
  }

  # infer boundary tags if absent
  canonical$boundary_p[canonical$boundary_p == ""] <- ifelse(
    is.finite(canonical$p) & canonical$p == max(canonical$p, na.rm = TRUE), "max", ""
  )
  canonical$boundary_r[canonical$boundary_r == ""] <- ifelse(
    is.finite(canonical$r) & canonical$r == max(canonical$r, na.rm = TRUE), "max", ""
  )
}

is_ardl <- nrow(canonical) > 0L & grepl("ARDL", canonical$model_class)
is_vecm <- nrow(canonical) > 0L & grepl("VECM", canonical$model_class)

faithful_ardl <- canonical[0, , drop = FALSE]
if (nrow(canonical) > 0L) {
  cand <- canonical[is_ardl & canonical$p == 2 & canonical$q == 4, , drop = FALSE]
  if (nrow(cand) > 0L) {
    cand <- cand[order(-cand$logLik), , drop = FALSE]
    faithful_ardl <- cand[1, , drop = FALSE]
  }
}
faithful_ardl <- mark_group(faithful_ardl, "faithful_ardl_2_4", "faithful")

ardl_frontier <- canonical[0, , drop = FALSE]
if (nrow(canonical) > 0L) {
  ardl <- canonical[is_ardl, , drop = FALSE]
  f1 <- extract_frontier(ardl, "k_total")
  f2 <- extract_frontier(ardl, "ICOMP_pen")
  f3 <- extract_frontier(ardl, "RICOMP_pen")
  ardl_frontier <- unique(rbind(f1, f2, f3))
}
ardl_frontier <- mark_group(ardl_frontier, "ardl_frontier_representatives", "ardl_frontier")

vecm_r1_frontier <- canonical[0, , drop = FALSE]
if (nrow(canonical) > 0L) {
  v1 <- canonical[is_vecm & canonical$r == 1, , drop = FALSE]
  f1 <- extract_frontier(v1, "k_total")
  f2 <- extract_frontier(v1, "ICOMP_pen")
  f3 <- extract_frontier(v1, "RICOMP_pen")
  vecm_r1_frontier <- unique(rbind(f1, f2, f3))
}
vecm_r1_frontier <- mark_group(vecm_r1_frontier, "vecm_r1_frontier_representatives", "vecm_r1_frontier")

vecm_r2m3_frontier <- canonical[0, , drop = FALSE]
if (nrow(canonical) > 0L) {
  v2 <- canonical[is_vecm & canonical$r == 2 & canonical$m == 3, , drop = FALSE]
  f1 <- extract_frontier(v2, "k_total")
  f2 <- extract_frontier(v2, "ICOMP_pen")
  f3 <- extract_frontier(v2, "RICOMP_pen")
  vecm_r2m3_frontier <- unique(rbind(f1, f2, f3))
}
vecm_r2m3_frontier <- mark_group(vecm_r2m3_frontier, "vecm_r2_m3_frontier_representatives", "vecm_r2_m3_frontier")

crosswalk <- unique(rbind(
  faithful_ardl,
  ardl_frontier,
  vecm_r1_frontier,
  vecm_r2m3_frontier
))

if (nrow(crosswalk) == 0L) {
  message("[crosswalk] No eligible geometry/envelope rows found. Writing empty template.")
}

# canonical column order for Stage 4 reporting
crosswalk <- crosswalk[, c(
  "representative_group", "representative_label",
  "exercise_id", "model_class", "window_tag", "det_tag",
  "m", "p", "q", "q_tag", "r", "cell_id",
  "slope_hat", "lambda", "alpha_y", "alpha_k", "alpha_e",
  "sK_ardl", "share_K",
  "logLik", "k_total", "ICOMP_pen", "RICOMP_pen",
  "stability_margin", "SI_Y",
  "boundary_p", "boundary_q", "boundary_r", "boundary_tags",
  "source_file"
), drop = FALSE]

utils::write.csv(crosswalk,
                 file = file.path(crosswalk_dir, "crosswalk_representatives.csv"),
                 row.names = FALSE)

# helpful split exports for downstream reporting
split_groups <- split(crosswalk, crosswalk$representative_group)
for (nm in names(split_groups)) {
  safe_nm <- gsub("[^A-Za-z0-9_]+", "_", nm)
  utils::write.csv(split_groups[[nm]],
                   file = file.path(crosswalk_dir, paste0(safe_nm, ".csv")),
                   row.names = FALSE)
}

message("[crosswalk] Wrote: ", file.path(crosswalk_dir, "crosswalk_representatives.csv"))
message("[crosswalk] Rows: ", nrow(crosswalk))
