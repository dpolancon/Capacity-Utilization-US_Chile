# ============================================================
# 30_report_tsdyn.R — tsDyn Report (grid + winners + feasibility)
#
# CONSOLIDATED (2026-02-23)
#   - Primary IC is chosen dynamically:
#       ic_primary = "PIC_star" if present & finite, else "PIC_obs"
#   - Backward compatible with legacy engine outputs (PIC_obs/BIC_obs).
#   - Robust ingestion + type coercion to avoid bind_rows conflicts.
#   - Rebuild comparable-domain flags using common_p_max.
#   - Winners / deltas / ambiguity sizes computed for ic_primary (+ BIC_obs if present).
#   - r=0 dominance computed using ic_primary and BIC_obs where available.
#   - Logging uses plain sink (robust).
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","readr","dplyr","tidyr","stringr","tibble")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

# ------------------------------------------------------------
# Repo anchors + config
# ------------------------------------------------------------
here::i_am("codes/30_report_tsdyn.R")
source(here::here("codes","10_config_tsdyn.R"))

utils_path <- here::here("codes","99_tsdyn_utils.R")
if (file.exists(utils_path)) source(utils_path)

`%||%` <- get0("%||%", ifnotfound = function(a,b) if (is.null(a)) b else a)

# Local fallback ensure_dirs if utils didn't define it
if (!exists("ensure_dirs", mode = "function")) {
  ensure_dirs <- function(...) {
    paths <- unique(c(...))
    paths <- paths[!is.na(paths) & nzchar(paths)]
    for (p in paths) if (!dir.exists(p)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
    invisible(TRUE)
  }
}

# ------------------------------------------------------------
# I/O roots
# ------------------------------------------------------------
IN_DIR  <- here::here(CONFIG$OUT_TSDYN %||% "output/TsDynEngine", "csv")
OUT_DIR <- here::here("output", "Reports_tsDyn")
DIRS <- list(
  csv  = file.path(OUT_DIR, "csv"),
  figs = file.path(OUT_DIR, "figs"),
  logs = file.path(OUT_DIR, "logs")
)
ensure_dirs(DIRS$csv, DIRS$figs, DIRS$logs)

# ------------------------------------------------------------
# Logging (plain sink; robust)
# ------------------------------------------------------------
timestamp_tag <- format(Sys.time(), "%Y%m%d_%H%M%S")
log_file <- file.path(DIRS$logs, paste0("report_tsdyn_", timestamp_tag, ".log"))
sink(log_file, split = TRUE)
on.exit(try(sink(), silent=TRUE), add=TRUE)

cat("=== 30_report_tsdyn start ===\n")
cat("Input dir :", IN_DIR, "\n")
cat("Output dir:", OUT_DIR, "\n\n")

# ------------------------------------------------------------
# Helper: parse spec/basis/det_tag from filename
# Expected: APPX_grid_pic_table_<spec>_<basis>_<det_tag>_unrestricted.csv
# ------------------------------------------------------------
parse_grid_filename <- function(path) {
  fn <- basename(path)
  pat <- "^APPX_grid_pic_table_([^_]+)_([^_]+)_(.+)_unrestricted\\.csv$"
  m <- stringr::str_match(fn, pat)
  if (is.na(m[1,1])) {
    return(data.frame(spec=NA_character_, basis=NA_character_, det_tag=NA_character_, file=fn,
                      stringsAsFactors=FALSE))
  }
  data.frame(spec=m[1,2], basis=m[1,3], det_tag=m[1,4], file=fn, stringsAsFactors=FALSE)
}

# ------------------------------------------------------------
# Helper: standardize types to prevent bind_rows conflicts
# ------------------------------------------------------------
standardize_grid_types <- function(df) {
  
  # Core identifiers
  if ("p" %in% names(df)) df$p <- suppressWarnings(as.integer(df$p))
  if ("r" %in% names(df)) df$r <- suppressWarnings(as.integer(df$r))
  if ("m" %in% names(df)) df$m <- suppressWarnings(as.integer(df$m))
  
  if ("window" %in% names(df)) df$window <- as.character(df$window)
  if ("spec" %in% names(df)) df$spec <- as.character(df$spec)
  if ("basis" %in% names(df)) df$basis <- as.character(df$basis)
  if ("det_tag" %in% names(df)) df$det_tag <- as.character(df$det_tag)
  if ("status" %in% names(df)) df$status <- as.character(df$status)
  
  # IC columns (legacy + frozen)
  if ("PIC_obs" %in% names(df)) df$PIC_obs <- suppressWarnings(as.numeric(df$PIC_obs))
  if ("BIC_obs" %in% names(df)) df$BIC_obs <- suppressWarnings(as.numeric(df$BIC_obs))
  if ("PIC_star" %in% names(df)) df$PIC_star <- suppressWarnings(as.numeric(df$PIC_star))
  
  # Likelihood/covariance components (new engine)
  if ("logLik_ML" %in% names(df)) df$logLik_ML <- suppressWarnings(as.numeric(df$logLik_ML))
  if ("logdet_Sigma" %in% names(df)) df$logdet_Sigma <- suppressWarnings(as.numeric(df$logdet_Sigma))
  if ("Cn" %in% names(df)) df$Cn <- suppressWarnings(as.numeric(df$Cn))
  if ("T_eff" %in% names(df)) df$T_eff <- suppressWarnings(as.integer(df$T_eff))
  if ("n_eff" %in% names(df)) df$n_eff <- suppressWarnings(as.integer(df$n_eff))  # backward compat
  if ("k_total" %in% names(df)) df$k_total <- suppressWarnings(as.integer(df$k_total))
  if ("df_LR" %in% names(df)) df$df_LR <- suppressWarnings(as.integer(df$df_LR))
  if ("df_SR" %in% names(df)) df$df_SR <- suppressWarnings(as.integer(df$df_SR))
  if ("d_det" %in% names(df)) df$d_det <- suppressWarnings(as.integer(df$d_det))
  
  # Diagnostics
  if ("runtime_sec" %in% names(df)) df$runtime_sec <- suppressWarnings(as.numeric(df$runtime_sec))
  if ("fail_code" %in% names(df)) df$fail_code <- as.character(df$fail_code)
  if ("fail_msg" %in% names(df)) df$fail_msg <- as.character(df$fail_msg)
  if ("r0_path" %in% names(df)) df$r0_path <- as.character(df$r0_path)
  
  # Comparability / geometry columns (engine versions differ)
  if ("p_max_window" %in% names(df)) df$p_max_window <- suppressWarnings(as.numeric(df$p_max_window))
  if ("p_max_feasible" %in% names(df)) df$p_max_feasible <- suppressWarnings(as.numeric(df$p_max_feasible))
  if ("common_p_max" %in% names(df)) df$common_p_max <- suppressWarnings(as.numeric(df$common_p_max))
  
  # Flags
  if ("comparable_p" %in% names(df)) df$comparable_p <- as.logical(df$comparable_p)
  if ("computed_comparable" %in% names(df)) df$computed_comparable <- as.logical(df$computed_comparable)
  
  df
}

# ------------------------------------------------------------
# Ingest grid files
# ------------------------------------------------------------
grid_files <- list.files(IN_DIR, pattern="^APPX_grid_pic_table_.*_unrestricted\\.csv$",
                         full.names = TRUE)

cat("Grid files found:", length(grid_files), "\n")
if (length(grid_files) == 0) {
  stop("No tsDyn grid files found under: ", IN_DIR,
       "\nExpected pattern: APPX_grid_pic_table_<spec>_<basis>_<det_tag>_unrestricted.csv",
       call. = FALSE)
}

meta_tbl <- dplyr::bind_rows(lapply(grid_files, parse_grid_filename))
grid_list <- vector("list", length(grid_files))

for (i in seq_along(grid_files)) {
  f <- grid_files[i]
  meta <- meta_tbl[i,]
  df <- readr::read_csv(f, show_col_types = FALSE)
  
  # provenance
  if (!("spec" %in% names(df))) df$spec <- meta$spec
  if (!("basis" %in% names(df))) df$basis <- meta$basis
  if (!("det_tag" %in% names(df))) df$det_tag <- meta$det_tag
  df$src_file <- meta$file
  
  # normalize window column name if needed
  if (!("window" %in% names(df)) && ("WINDOW" %in% names(df))) df$window <- df$WINDOW
  
  # ensure comparability flags exist (if absent, we rebuild later)
  if (!("comparable_p" %in% names(df))) df$comparable_p <- NA
  if (!("computed_comparable" %in% names(df))) df$computed_comparable <- NA
  
  df <- standardize_grid_types(df)
  grid_list[[i]] <- df
}

grid <- dplyr::bind_rows(grid_list)

cat("Rows ingested:", nrow(grid), "\n\n")
if (nrow(grid) == 0) stop("Grid ingestion produced 0 rows; check engine output.", call.=FALSE)


# --- Freeze enforcement: PIC_star must exist and be usable
cat("PIC_star present:", "PIC_star" %in% names(grid), "\n")
if ("PIC_star" %in% names(grid)) {
  cat("finite PIC_star (computed):",
      sum(is.finite(grid$PIC_star) & grid$status=="computed", na.rm=TRUE), "\n")
}

if (!("PIC_star" %in% names(grid)) ||
    !any(is.finite(grid$PIC_star) & grid$status=="computed", na.rm=TRUE)) {
  stop("Frozen criterion requires PIC_star, but it is missing or non-finite in computed cells. Re-run engine outputs.",
       call. = FALSE)
}

ic_primary <- "PIC_star"

# ------------------------------------------------------------
# Choose primary IC: prefer PIC_star if present and finite
# ------------------------------------------------------------
ic_primary <- "PIC_obs"
if ("PIC_star" %in% names(grid)) {
  any_finite_picstar <- any(is.finite(grid$PIC_star) & grid$status == "computed", na.rm = TRUE)
  if (isTRUE(any_finite_picstar)) ic_primary <- "PIC_star"
}
cat("Primary IC:", ic_primary, "\n\n")

has_bic <- ("BIC_obs" %in% names(grid)) && any(is.finite(grid$BIC_obs) & grid$status == "computed", na.rm = TRUE)
cat("BIC available:", has_bic, "\n\n")

# ------------------------------------------------------------
# Ensure FULL-first window order
# ------------------------------------------------------------
windows_lock <- CONFIG$WINDOWS_LOCKED %||% CONFIG$windows_lock
if (is.null(windows_lock)) stop("CONFIG must provide WINDOWS_LOCKED (or windows_lock).", call.=FALSE)
window_order <- names(windows_lock)
if (length(window_order) == 0) window_order <- c("full","fordism","post_fordism")

grid$window <- factor(as.character(grid$window), levels = window_order, ordered = TRUE)

# ------------------------------------------------------------
# Audit table A: status counts + shares
# ------------------------------------------------------------
status_counts <- grid |>
  dplyr::mutate(status = dplyr::coalesce(status, "missing")) |>
  dplyr::count(window, spec, basis, det_tag, status, name="n") |>
  tidyr::pivot_wider(names_from = status, values_from = n, values_fill = 0)

safe_col <- function(df, nm) if (nm %in% names(df)) df[[nm]] else rep(0, nrow(df))

num_cols <- setdiff(names(status_counts), c("window","spec","basis","det_tag"))
status_counts$total <- rowSums(status_counts[, num_cols, drop = FALSE])

status_counts$computed_share     <- safe_col(status_counts, "computed")     / status_counts$total
status_counts$gate_fail_share    <- safe_col(status_counts, "gate_fail")    / status_counts$total
status_counts$runtime_fail_share <- safe_col(status_counts, "runtime_fail") / status_counts$total

status_counts <- status_counts |>
  dplyr::arrange(window, spec, basis, det_tag)

readr::write_csv(status_counts, file.path(DIRS$csv, "APPX_report_status_counts_tsDyn.csv"))

# ------------------------------------------------------------
# Feasible pmax per window and common_p_max per (spec,basis,det_tag)
# ------------------------------------------------------------
pmax_window <- grid |>
  dplyr::filter(status == "computed") |>
  dplyr::group_by(spec, basis, det_tag, window) |>
  dplyr::summarise(p_max_feasible = max(p, na.rm=TRUE), .groups="drop")

common_pmax <- pmax_window |>
  dplyr::group_by(spec, basis, det_tag) |>
  dplyr::summarise(common_p_max = min(p_max_feasible, na.rm=TRUE), .groups="drop")

readr::write_csv(pmax_window, file.path(DIRS$csv, "APPX_report_feasible_pmax_by_window_tsDyn.csv"))
readr::write_csv(common_pmax, file.path(DIRS$csv, "APPX_report_common_pmax_tsDyn.csv"))

# ------------------------------------------------------------
# Rebuild comparability flags (authoritative)
# ------------------------------------------------------------
grid <- grid |>
  dplyr::select(-dplyr::any_of(c("common_p_max", "common_p_max.x", "common_p_max.y")))

grid <- grid |>
  dplyr::left_join(common_pmax, by = c("spec","basis","det_tag")) |>
  dplyr::mutate(
    common_p_max = suppressWarnings(as.numeric(common_p_max)),
    comparable_p = dplyr::if_else(
      status == "computed" & is.finite(common_p_max) & is.finite(p) & p <= common_p_max,
      TRUE, FALSE
    ),
    computed_comparable = comparable_p
  )

# ------------------------------------------------------------
# Helper: pick winners with tie handling (dynamic IC)
# ------------------------------------------------------------
pick_winner <- function(df, ic_col) {
  if (!(ic_col %in% names(df))) return(NULL)
  df <- df |> dplyr::filter(status=="computed", is.finite(.data[[ic_col]]))
  if (nrow(df) == 0) return(NULL)
  
  min_val <- min(df[[ic_col]], na.rm=TRUE)
  ties <- df |> dplyr::filter(.data[[ic_col]] == min_val) |> dplyr::arrange(p, r)
  w <- ties[1, , drop=FALSE]
  w$n_ties <- nrow(ties)
  w[[paste0(ic_col,"_min")]] <- min_val
  w
}

# ------------------------------------------------------------
# Winners: unrestricted (primary IC + BIC if present)
# ------------------------------------------------------------
w_unres_primary <- grid |>
  dplyr::group_by(window, spec, basis, det_tag) |>
  dplyr::group_modify(~{ out <- pick_winner(.x, ic_primary); if (is.null(out)) tibble::tibble() else out }) |>
  dplyr::ungroup() |>
  dplyr::arrange(window, spec, basis, det_tag)

readr::write_csv(
  w_unres_primary,
  file.path(DIRS$csv, paste0("APPX_winners_unrestricted_", ic_primary, "_tsDyn.csv"))
)

if (has_bic) {
  w_unres_bic <- grid |>
    dplyr::group_by(window, spec, basis, det_tag) |>
    dplyr::group_modify(~{ out <- pick_winner(.x, "BIC_obs"); if (is.null(out)) tibble::tibble() else out }) |>
    dplyr::ungroup() |>
    dplyr::arrange(window, spec, basis, det_tag)
  
  readr::write_csv(w_unres_bic, file.path(DIRS$csv, "APPX_winners_unrestricted_BIC_tsDyn.csv"))
}

# ------------------------------------------------------------
# Winners: comparable-domain (p <= common_p_max)
# ------------------------------------------------------------
grid_comp <- grid |> dplyr::filter(status == "computed", comparable_p)

w_comp_primary <- grid_comp |>
  dplyr::group_by(window, spec, basis, det_tag) |>
  dplyr::group_modify(~{ out <- pick_winner(.x, ic_primary); if (is.null(out)) tibble::tibble() else out }) |>
  dplyr::ungroup() |>
  dplyr::arrange(window, spec, basis, det_tag)

readr::write_csv(
  w_comp_primary,
  file.path(DIRS$csv, paste0("APPX_winners_comparable_", ic_primary, "_tsDyn.csv"))
)

if (has_bic) {
  w_comp_bic <- grid_comp |>
    dplyr::group_by(window, spec, basis, det_tag) |>
    dplyr::group_modify(~{ out <- pick_winner(.x, "BIC_obs"); if (is.null(out)) tibble::tibble() else out }) |>
    dplyr::ungroup() |>
    dplyr::arrange(window, spec, basis, det_tag)
  
  readr::write_csv(w_comp_bic, file.path(DIRS$csv, "APPX_winners_comparable_BIC_tsDyn.csv"))
}

# ------------------------------------------------------------
# Essay-facing joint selection + sharpness gaps (primary IC + BIC optional)
# ------------------------------------------------------------
delta_to_second <- function(df, ic_col) {
  if (!(ic_col %in% names(df))) return(NA_real_)
  df <- df |>
    dplyr::filter(status == "computed", comparable_p, is.finite(.data[[ic_col]]))
  if (nrow(df) < 2) return(NA_real_)
  v <- sort(df[[ic_col]])
  v[2] - v[1]
}

A_eps_size <- function(df, ic_col, eps = 2) {
  if (!(ic_col %in% names(df))) return(NA_integer_)
  v <- df[[ic_col]]
  if (all(!is.finite(v))) return(NA_integer_)
  v0 <- min(v, na.rm = TRUE)
  sum((v - v0) <= eps, na.rm = TRUE)
}

# ---- Layer 1: Slice-local normalization (on grid_comp)
grid_comp <- grid_comp |>
  dplyr::group_by(window, spec, basis, det_tag) |>
  dplyr::mutate(
    IC_min_slice = min(.data[[ic_primary]], na.rm = TRUE),
    deltaIC_to_min_slice = .data[[ic_primary]] - IC_min_slice
  ) |>
  dplyr::ungroup()

if (has_bic) {
  grid_comp <- grid_comp |>
    dplyr::group_by(window, spec, basis, det_tag) |>
    dplyr::mutate(
      BIC_min_slice = min(BIC_obs, na.rm = TRUE),
      deltaBIC_to_min_slice = BIC_obs - BIC_min_slice
    ) |>
    dplyr::ungroup()
}

# ---- Layer 2: Spec-local normalization (pool across basis + det_tag)
grid_comp <- grid_comp |>
  dplyr::group_by(window, spec) |>
  dplyr::mutate(
    IC_min_spec = min(.data[[ic_primary]], na.rm = TRUE),
    deltaIC_to_min_spec = .data[[ic_primary]] - IC_min_spec
  ) |>
  dplyr::ungroup()

if (has_bic) {
  grid_comp <- grid_comp |>
    dplyr::group_by(window, spec) |>
    dplyr::mutate(
      BIC_min_spec = min(BIC_obs, na.rm = TRUE),
      deltaBIC_to_min_spec = BIC_obs - BIC_min_spec
    ) |>
    dplyr::ungroup()
}

# ---- ESSAY table: winners + delta layers
essay_tbl <- grid_comp |>
  dplyr::group_by(window, spec, basis, det_tag) |>
  dplyr::group_modify(~{
    w_ic <- pick_winner(.x, ic_primary)
    if (is.null(w_ic)) return(tibble::tibble())
    
    # slice mins
    IC_min_slice <- min(.x[[ic_primary]], na.rm = TRUE)
    IC_min_spec  <- .x$IC_min_spec[which(is.finite(.x$IC_min_spec))[1]]
    
    A2_ic_slice <- A_eps_size(.x, ic_primary, eps = 2)
    
    # winner->spec delta
    ww <- .x[.x$p == w_ic$p & .x$r == w_ic$r, , drop = FALSE]
    deltaIC_winner_to_spec <- if (nrow(ww) > 0) ww$deltaIC_to_min_spec[1] else NA_real_
    
    out <- tibble::tibble(
      ic_primary = ic_primary,
      p_IC = w_ic$p,
      r_IC = w_ic$r,
      IC_min = w_ic[[ic_primary]],
      deltaIC_2nd = delta_to_second(.x, ic_primary),
      IC_min_slice = IC_min_slice,
      A2_IC_slice = A2_ic_slice,
      IC_min_spec = IC_min_spec,
      deltaIC_winner_to_spec = deltaIC_winner_to_spec
    )
    
    # optional BIC block
    if (has_bic) {
      w_bic <- pick_winner(.x, "BIC_obs")
      out$p_BIC <- if (!is.null(w_bic)) w_bic$p else NA_integer_
      out$r_BIC <- if (!is.null(w_bic)) w_bic$r else NA_integer_
      out$BIC_min <- if (!is.null(w_bic)) w_bic$BIC_obs else NA_real_
      out$deltaBIC_2nd <- delta_to_second(.x, "BIC_obs")
      out$BIC_min_slice <- min(.x$BIC_obs, na.rm = TRUE)
      out$BIC_min_spec <- .x$BIC_min_spec[which(is.finite(.x$BIC_min_spec))[1]]
      # delta winner->spec
      if (!is.null(w_bic)) {
        ww2 <- .x[.x$p == w_bic$p & .x$r == w_bic$r, , drop = FALSE]
        out$deltaBIC_winner_to_spec <- if (nrow(ww2) > 0) ww2$deltaBIC_to_min_spec[1] else NA_real_
      } else {
        out$deltaBIC_winner_to_spec <- NA_real_
      }
      out$A2_BIC_slice <- A_eps_size(.x, "BIC_obs", eps = 2)
    }
    
    out
  }) |>
  dplyr::ungroup() |>
  dplyr::left_join(common_pmax, by=c("spec","basis","det_tag")) |>
  dplyr::left_join(
    status_counts |>
      dplyr::select(window,spec,basis,det_tag,computed_share,total),
    by=c("window","spec","basis","det_tag")
  ) |>
  dplyr::arrange(window, spec, basis, det_tag)

# Spec-level A2 size (pooling across basis+det_tag)
A2_spec_tbl <- grid_comp |>
  dplyr::group_by(window, spec) |>
  dplyr::summarise(
    A2_IC_spec  = A_eps_size(dplyr::pick(dplyr::everything()), ic_primary, eps = 2),
    A2_BIC_spec = if (has_bic) A_eps_size(dplyr::pick(dplyr::everything()), "BIC_obs", eps = 2) else NA_integer_,
    .groups = "drop"
  )

essay_tbl <- essay_tbl |>
  dplyr::left_join(A2_spec_tbl, by = c("window","spec"))

readr::write_csv(essay_tbl, file.path(DIRS$csv, paste0("ESSAY_joint_selection_tsDyn_", ic_primary, ".csv")))

# ------------------------------------------------------------
# Rank dominance table: r=0 vs selected winner (primary IC + BIC optional)
# ------------------------------------------------------------
rank_dominance_tbl <- grid |>
  dplyr::filter(status == "computed") |>
  dplyr::group_by(window, spec, basis, det_tag) |>
  dplyr::group_modify(~{
    
    df <- .x
    # Winner (IC-based, comparable domain)
    df_comp <- df |> dplyr::filter(comparable_p)
    
    w_ic <- pick_winner(df_comp, ic_primary)
    if (is.null(w_ic)) return(tibble::tibble())
    
    # Best r=0 model (across all p) using primary IC
    r0_df <- df |>
      dplyr::filter(r == 0, is.finite(.data[[ic_primary]]))
    
    IC_r0_min <- if (nrow(r0_df) == 0) NA_real_ else min(r0_df[[ic_primary]], na.rm = TRUE)
    deltaIC_r0_vs_winner <- IC_r0_min - w_ic[[ic_primary]]
    
    dominance_flag <- dplyr::case_when(
      is.na(deltaIC_r0_vs_winner) ~ "r0 not computed",
      deltaIC_r0_vs_winner < 2 ~ "weak",
      deltaIC_r0_vs_winner < 10 ~ "strong",
      deltaIC_r0_vs_winner < 100 ~ "very strong",
      TRUE ~ "decisive"
    )
    
    out <- tibble::tibble(
      ic_primary = ic_primary,
      p_winner = w_ic$p,
      r_winner = w_ic$r,
      IC_winner = w_ic[[ic_primary]],
      IC_r0_min = IC_r0_min,
      deltaIC_r0_vs_winner = deltaIC_r0_vs_winner,
      dominance = dominance_flag
    )
    
    if (has_bic) {
      w_bic <- pick_winner(df_comp, "BIC_obs")
      r0_bic <- df |> dplyr::filter(r == 0, is.finite(BIC_obs))
      BIC_r0_min <- if (nrow(r0_bic) == 0) NA_real_ else min(r0_bic$BIC_obs, na.rm = TRUE)
      out$p_winner_BIC <- if (!is.null(w_bic)) w_bic$p else NA_integer_
      out$r_winner_BIC <- if (!is.null(w_bic)) w_bic$r else NA_integer_
      out$BIC_winner <- if (!is.null(w_bic)) w_bic$BIC_obs else NA_real_
      out$BIC_r0_min <- BIC_r0_min
      out$deltaBIC_r0_vs_winner <- BIC_r0_min - if (!is.null(w_bic)) w_bic$BIC_obs else NA_real_
    }
    
    out
  }) |>
  dplyr::ungroup() |>
  dplyr::arrange(window, spec, basis, det_tag)

readr::write_csv(
  rank_dominance_tbl,
  file.path(DIRS$csv, paste0("ESSAY_rank_dominance_r0_tsDyn_", ic_primary, ".csv"))
)

# ------------------------------------------------------------
# Final digest
# ------------------------------------------------------------
cat("\n=== Digest ===\n")
cat("Primary IC     :", ic_primary, "\n")
cat("Unique windows :", paste(levels(grid$window), collapse=", "), "\n")
cat("Unique specs   :", paste(unique(grid$spec), collapse=", "), "\n")
cat("Unique basis   :", paste(unique(grid$basis), collapse=", "), "\n")
cat("Unique det_tag :", paste(unique(grid$det_tag), collapse=", "), "\n")
cat("Computed cells :", sum(grid$status=="computed", na.rm=TRUE), "\n")
cat("Winners (essay) rows:", nrow(essay_tbl), "\n")
cat("\nOutputs written under:", OUT_DIR, "\n")
cat("=== 30_report_tsdyn complete ===\n")