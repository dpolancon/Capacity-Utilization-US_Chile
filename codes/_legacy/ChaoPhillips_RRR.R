############################################################
## ChaoPhillip_VisST.R  (self-contained)
##
## Does:
##  A) builds windows + demeaned interactions (full/ford/post)
##  B) ingests Johansen-grid outputs (pic_table, grid_rank_decisions)
##  C) builds Storytelling tables S1..S4 and exports to:
##     output/ChaoGrid_VisST/{csv,tex,fig}
##     output/ChaoGrid_tidytable/{csv,tex}
##
## Assumptions:
##  - You already ran the Johansen-grid + PIC engine at least once
##    OR you have pic_table + grid_rank_decisions in memory.
##  - Disk fallback expects CSVs in a legacy folder (set LEGACY_GRID_CSV below).
##
## Locked notation:
##  - p = VAR lag length (grid dimension)
##  - VECM uses (p-1) lagged differences (for r>=1)
##  - ecdet ∈ {"none","const"}  (const = restricted constant in EC term)
############################################################

#### 0) Packages (hard deps only) ####
pkgs <- c("here","readxl","dplyr","knitr","kableExtra")
invisible(lapply(pkgs, require, character.only = TRUE))

#### 1) Minimal helpers (self-contained) ####
ensure_dirs <- function(...) {
  paths <- c(...)
  for (p in paths) if (!dir.exists(p)) dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

set_seed_deterministic <- function(seed = 12345) {
  set.seed(seed)
  suppressWarnings(RNGkind(kind = "Mersenne-Twister", normal.kind = "Inversion"))
}

write_tex_table <- function(df, out_path, caption = NULL, label = NULL, digits = 3) {
  tex <- knitr::kable(
    df, format = "latex", booktabs = TRUE, longtable = TRUE,
    caption = caption, label = label, digits = digits
  ) |>
    kableExtra::kable_styling(latex_options = c("hold_position","repeat_header"), font_size = 9)
  writeLines(tex, con = out_path)
}

export_pair <- function(df, csv_path, tex_path, caption = NULL, label = NULL, digits = 3) {
  utils::write.csv(df, csv_path, row.names = FALSE)
  write_tex_table(df, tex_path, caption = caption, label = label, digits = digits)
}

read_if_exists <- function(path) {
  if (file.exists(path)) utils::read.csv(path, stringsAsFactors = FALSE) else NULL
}

WINDOW_ORDER <- c("full","ford","post")
ECDET_ORDER  <- c("none","const")

#### 2) Paths + output trees ####
set_seed_deterministic()

data_path   <- here::here("data/processed/ddbb_cu_US_kgr.xlsx")
output_path <- here::here("output")

OUT_VISST_ROOT <- file.path(output_path, "ChaoGrid_VisST")
OUT_TIDY_ROOT  <- file.path(output_path, "ChaoGrid_tidytable")

DIRS <- list(
  vis_csv = file.path(OUT_VISST_ROOT, "csv"),
  vis_tex = file.path(OUT_VISST_ROOT, "tex"),
  vis_fig = file.path(OUT_VISST_ROOT, "fig"),
  tid_csv = file.path(OUT_TIDY_ROOT,  "csv"),
  tid_tex = file.path(OUT_TIDY_ROOT,  "tex")
)
ensure_dirs(DIRS$vis_csv, DIRS$vis_tex, DIRS$vis_fig, DIRS$tid_csv, DIRS$tid_tex)

#### 3) Data ingest + base variables (levels) ####
ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

df <- ddbb_us |>
  dplyr::transmute(
    year      = .data$year,
    K_stock   = .data$KGCRcorp,   # avoid collision with lag-length notation
    Y         = .data$Yrgdp,
    e         = .data$e,
    yk_input  = .data$yk,
    yk_calc   = .data$Yrgdp / .data$KGCRcorp,
    log_y     = log(.data$Yrgdp),
    log_k     = log(.data$KGCRcorp),
    log_yk    = log(.data$yk_calc)
  ) |>
  dplyr::arrange(.data$year)

add_e_bar_and_interactions <- function(dfw) {
  dfw <- dfw |> dplyr::arrange(.data$year)
  mu_e <- mean(dfw$e, na.rm = TRUE)
  
  dfw |>
    dplyr::mutate(
      # demeaned exploitation and powers
      e_bar   = e - mu_e,
      e_bar2  = e_bar^2,
      e_bar3  = e_bar^3,
      
      # raw powers
      e2      = e^2,
      e3      = e^3,
      
      # raw interactions
      logK_e   = log_k * e,
      logK_e2  = log_k * e2,
      logK_e3  = log_k * e3,
      
      # demeaned interactions
      logK_ebar  = log_k * e_bar,
      logK_ebar2 = log_k * e_bar2,
      logK_ebar3 = log_k * e_bar3,
      
      # diffs (within window: self-contained)
      d_log_y  = log_y - dplyr::lag(log_y),
      d_log_k  = log_k - dplyr::lag(log_k),
      d_e      = e     - dplyr::lag(e),
      
      d_e_bar       = e_bar       - dplyr::lag(e_bar),
      d_logK_e      = logK_e      - dplyr::lag(logK_e),
      d_logK_e2     = logK_e2     - dplyr::lag(logK_e2),
      d_logK_e3     = logK_e3     - dplyr::lag(logK_e3),
      d_logK_ebar   = logK_ebar   - dplyr::lag(logK_ebar),
      d_logK_ebar2  = logK_ebar2  - dplyr::lag(logK_ebar2),
      d_logK_ebar3  = logK_ebar3  - dplyr::lag(logK_ebar3)
    )
}

df_full <- df |>
  dplyr::filter(!is.na(log_y), !is.na(log_k), !is.na(e)) |>
  add_e_bar_and_interactions()

df_ford <- df |>
  dplyr::filter(year <= 1973) |>
  dplyr::filter(!is.na(log_y), !is.na(log_k), !is.na(e)) |>
  add_e_bar_and_interactions()

df_post <- df |>
  dplyr::filter(year >= 1974) |>
  dplyr::filter(!is.na(log_y), !is.na(log_k), !is.na(e)) |>
  add_e_bar_and_interactions()

windows <- list(full = df_full, ford = df_ford, post = df_post)


#### 4) Ingest grid outputs (memory first, disk search second) ####

message("here() root: ", here::here())
message("output_path: ", output_path)

pic_table_in <- if (exists("pic_table", inherits = TRUE)) get("pic_table", inherits = TRUE) else NULL
rank_dec_in  <- if (exists("grid_rank_decisions", inherits = TRUE)) get("grid_rank_decisions", inherits = TRUE) else NULL

# If missing in memory, search disk under output/ recursively
if (is.null(pic_table_in) || is.null(rank_dec_in)) {
  
  # candidate filenames (your earlier code might have used different names)
  pic_candidates  <- c("pic_table.csv", "PIC_table.csv", "grid_pic_table.csv", "pic.csv")
  rank_candidates <- c("grid_rank_decisions.csv", "rank_decisions.csv", "grid_rank.csv")
  
  # search root: output_path (project-relative via here::here("output"))
  search_root <- output_path
  
  find_first <- function(root, candidates) {
    hits <- unlist(lapply(candidates, function(fn) {
      list.files(root, pattern = paste0("^", gsub("\\.", "\\\\.", fn), "$"),
                 recursive = TRUE, full.names = TRUE)
    }), use.names = FALSE)
    if (length(hits) == 0) return(NULL)
    hits[1]
  }
  
  pic_path  <- if (is.null(pic_table_in)) find_first(search_root, pic_candidates) else NULL
  rank_path <- if (is.null(rank_dec_in))  find_first(search_root, rank_candidates) else NULL
  
  if (!is.null(pic_path)) {
    message("Found PIC table at: ", pic_path)
    pic_table_in <- utils::read.csv(pic_path, stringsAsFactors = FALSE)
  }
  
  if (!is.null(rank_path)) {
    message("Found rank decisions at: ", rank_path)
    rank_dec_in <- utils::read.csv(rank_path, stringsAsFactors = FALSE)
  }
  
  # If still missing, print a helpful diagnostic inventory and stop
  if (is.null(pic_table_in) || is.null(rank_dec_in)) {
    message("\nDiagnostic: listing *csv files under output/* (top 80):")
    csvs <- list.files(search_root, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
    csvs <- csvs[order(csvs)]
    print(utils::head(csvs, 80))
    
    stop("\nStill missing required inputs.\n",
         "Need: pic_table (e.g., pic_table.csv / grid_pic_table.csv) and grid_rank_decisions.csv.\n",
         "Either:\n",
         "  (i) run the Johansen-grid + PIC engine in this same project root, OR\n",
         " (ii) copy the exported CSVs into output/ so this script can find them.\n")
  }
}

# Promote to local names used downstream
pic_table <- as.data.frame(pic_table_in)
grid_rank_decisions <- as.data.frame(rank_dec_in)

#### 5.1) Harmonize required columns in pic_table ####
# We need at minimum: window, ecdet, p, r, logdet, PIC, BIC, and ideally T and m.

# p already harmonized from K -> p earlier

# Try common aliases for m and T if missing
if (!("m" %in% names(pic_table))) {
  cand_m <- intersect(names(pic_table), c("M", "m_sys", "m_dim", "sys_m", "system_size", "n_vars", "mvar"))
  if (length(cand_m) >= 1) {
    message("Harmonizing: renaming ", cand_m[1], " -> m")
    pic_table$m <- pic_table[[cand_m[1]]]
  } else {
    message("NOTE: pic_table has no 'm' column. Setting m = NA (won't break exports).")
    pic_table$m <- NA_integer_
  }
}

if (!("T" %in% names(pic_table))) {
  cand_T <- intersect(names(pic_table), c("TT", "T_eff", "Teff", "nT", "n_obs", "Tsample"))
  if (length(cand_T) >= 1) {
    message("Harmonizing: renaming ", cand_T[1], " -> T")
    pic_table$T <- pic_table[[cand_T[1]]]
  } else {
    message("NOTE: pic_table has no 'T' column. Setting T = NA (S1 will be less informative).")
    pic_table$T <- NA_integer_
  }
}

# Coerce types safely
pic_table$m <- suppressWarnings(as.integer(pic_table$m))
pic_table$T <- suppressWarnings(as.integer(pic_table$T))



#### 5) Normalize columns: K -> p, and ecdet label harmonization ####
# (a) K -> p
if (!("p" %in% names(pic_table))) {
  if ("K" %in% names(pic_table)) pic_table$p <- pic_table$K else stop("pic_table needs 'p' or legacy 'K'.")
}
if (!("p" %in% names(grid_rank_decisions))) {
  if ("K" %in% names(grid_rank_decisions)) grid_rank_decisions$p <- grid_rank_decisions$K else stop("grid_rank_decisions needs 'p' or legacy 'K'.")
}

# (b) ecdet: map "cons" -> "const" if it appears
map_ecdet <- function(x) {
  x <- as.character(x)
  x[x == "cons"] <- "const"
  x
}
pic_table$ecdet <- map_ecdet(pic_table$ecdet)
grid_rank_decisions$ecdet <- map_ecdet(grid_rank_decisions$ecdet)

# types
pic_table$window <- as.character(pic_table$window)
pic_table$ecdet  <- as.character(pic_table$ecdet)
pic_table$p      <- as.integer(pic_table$p)
pic_table$r      <- as.integer(pic_table$r)

grid_rank_decisions$window <- as.character(grid_rank_decisions$window)
grid_rank_decisions$ecdet  <- as.character(grid_rank_decisions$ecdet)
grid_rank_decisions$p      <- as.integer(grid_rank_decisions$p)

#### 6) Manifest exports ####
manifest <- data.frame(
  object = c("windows(full/ford/post)","pic_table","grid_rank_decisions"),
  rows   = c(length(windows), nrow(pic_table), nrow(grid_rank_decisions)),
  stringsAsFactors = FALSE
)

export_pair(
  manifest,
  file.path(DIRS$tid_csv, "_manifest_inputs.csv"),
  file.path(DIRS$tid_tex, "_manifest_inputs.tex"),
  caption = "Input manifest (VisST build)",
  label   = "tab:manifest_inputs",
  digits  = 0
)

#### 7) S1: Grid overview ####
S1_grid_overview <- (pic_table |>
                       dplyr::group_by(window) |>
                       dplyr::summarise(
                         T = suppressWarnings(max(T, na.rm = TRUE)),
                         m = suppressWarnings(max(m, na.rm = TRUE)),
                         ecdet_levels = paste(sort(unique(ecdet)), collapse = ","),
                         p_levels     = paste(sort(unique(p)), collapse = ","),
                         grid_points  = dplyr::n_distinct(paste(ecdet, p)),
                         .groups = "drop"
                       )) |>
  as.data.frame()

S1_grid_overview <- S1_grid_overview[order(match(S1_grid_overview$window, WINDOW_ORDER)), , drop = FALSE]

export_pair(
  S1_grid_overview,
  file.path(DIRS$tid_csv, "S1_grid_overview.csv"),
  file.path(DIRS$tid_tex, "S1_grid_overview.tex"),
  caption = "S1: Grid overview (dimensions, effective T, system size m)",
  label   = "tab:S1_grid_overview",
  digits  = 0
)

#### 8) S2: Rank tables + disagreement ####
rank_cols <- intersect(
  names(grid_rank_decisions),
  c("window","ecdet","p","r_trace_10","r_trace_05","r_trace_01","r_eigen_10","r_eigen_05","r_eigen_01")
)
S2_rank_all <- grid_rank_decisions[, rank_cols, drop = FALSE]

S2_rank_all <- S2_rank_all[order(match(S2_rank_all$window, WINDOW_ORDER),
                                 match(S2_rank_all$ecdet, ECDET_ORDER),
                                 S2_rank_all$p), , drop = FALSE]

make_disagreement <- function(df) {
  out <- df
  if (all(c("r_trace_05","r_eigen_05") %in% names(out))) out$disagree_05 <- (out$r_trace_05 != out$r_eigen_05)
  if (all(c("r_trace_10","r_eigen_10") %in% names(out))) out$disagree_10 <- (out$r_trace_10 != out$r_eigen_10)
  if (all(c("r_trace_01","r_eigen_01") %in% names(out))) out$disagree_01 <- (out$r_trace_01 != out$r_eigen_01)
  
  if (all(c("r_trace_10","r_trace_05","r_trace_01") %in% names(out))) {
    out$trace_range <- pmax(out$r_trace_10, out$r_trace_05, out$r_trace_01, na.rm = TRUE) -
      pmin(out$r_trace_10, out$r_trace_05, out$r_trace_01, na.rm = TRUE)
  }
  if (all(c("r_eigen_10","r_eigen_05","r_eigen_01") %in% names(out))) {
    out$eigen_range <- pmax(out$r_eigen_10, out$r_eigen_05, out$r_eigen_01, na.rm = TRUE) -
      pmin(out$r_eigen_10, out$r_eigen_05, out$r_eigen_01, na.rm = TRUE)
  }
  out
}
S2_rank_disagreement <- make_disagreement(S2_rank_all)

for (w in WINDOW_ORDER) {
  tmp <- S2_rank_all[S2_rank_all$window == w, , drop = FALSE]
  export_pair(
    tmp,
    file.path(DIRS$tid_csv, sprintf("S2_rank_tests_%s.csv", w)),
    file.path(DIRS$tid_tex, sprintf("S2_rank_tests_%s.tex", w)),
    caption = sprintf("S2: Rank tests (window: %s)", w),
    label   = sprintf("tab:S2_rank_tests_%s", w),
    digits  = 0
  )
}

export_pair(
  S2_rank_disagreement,
  file.path(DIRS$tid_csv, "S2_rank_disagreement.csv"),
  file.path(DIRS$tid_tex, "S2_rank_disagreement.tex"),
  caption = "S2: Rank disagreement/instability summary",
  label   = "tab:S2_rank_disagreement",
  digits  = 0
)

#### 9) S3: Top-5 by PIC and by BIC + pooled ####
need_cols_core <- c("window","ecdet","p","r","logdet","PIC","BIC")
need_cols_meta <- c("T","m")
missing_core <- setdiff(need_cols_core, names(pic_table))
if (length(missing_core) > 0) stop(paste("pic_table missing required columns:", paste(missing_core, collapse = ", ")))

# ensure metadata cols exist
for (cc in need_cols_meta) if (!(cc %in% names(pic_table))) pic_table[[cc]] <- NA_integer_

need_cols <- c(need_cols_core, need_cols_meta)


missing_cols <- setdiff(need_cols, names(pic_table))
if (length(missing_cols) > 0) stop(paste("pic_table missing required columns:", paste(missing_cols, collapse = ", ")))

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
                  criterion = criterion) |>
    dplyr::ungroup()
  as.data.frame(out)
}

S3_pic_top5 <- rank_topN(pic_table, "PIC", 5)
S3_bic_top5 <- rank_topN(pic_table, "BIC", 5)

for (w in WINDOW_ORDER) {
  export_pair(
    S3_pic_top5[S3_pic_top5$window == w, , drop = FALSE],
    file.path(DIRS$tid_csv, sprintf("S3_pic_top5_%s.csv", w)),
    file.path(DIRS$tid_tex, sprintf("S3_pic_top5_%s.tex", w)),
    caption = sprintf("S3: PIC Top-5 (window: %s)", w),
    label   = sprintf("tab:S3_pic_top5_%s", w),
    digits  = 3
  )
  export_pair(
    S3_bic_top5[S3_bic_top5$window == w, , drop = FALSE],
    file.path(DIRS$tid_csv, sprintf("S3_bic_top5_%s.csv", w)),
    file.path(DIRS$tid_tex, sprintf("S3_bic_top5_%s.tex", w)),
    caption = sprintf("S3: BIC Top-5 (window: %s)", w),
    label   = sprintf("tab:S3_bic_top5_%s", w),
    digits  = 3
  )
}

S3_top5_pooled <- rbind(
  S3_pic_top5[, c(need_cols,"criterion","within_window_rank"), drop = FALSE],
  S3_bic_top5[, c(need_cols,"criterion","within_window_rank"), drop = FALSE]
)
S3_top5_pooled <- S3_top5_pooled[order(match(S3_top5_pooled$window, WINDOW_ORDER),
                                       match(S3_top5_pooled$criterion, c("PIC","BIC")),
                                       S3_top5_pooled$within_window_rank), , drop = FALSE]

export_pair(
  S3_top5_pooled,
  file.path(DIRS$tid_csv, "S3_top5_pooled.csv"),
  file.path(DIRS$tid_tex, "S3_top5_pooled.tex"),
  caption = "S3: Top-5 candidates per window (PIC and BIC)",
  label   = "tab:S3_top5_pooled",
  digits  = 3
)

names(pic_table)
names(grid_rank_decisions)

#### 10) S4: Tie-break (PIC + Johansen screen) + final recommendation ####
pick_johansen_col <- function(use_test = c("trace","eigen"), alpha = 0.05) {
  use_test <- match.arg(use_test)
  if (isTRUE(all.equal(alpha, 0.10))) return(if (use_test=="trace") "r_trace_10" else "r_eigen_10")
  if (isTRUE(all.equal(alpha, 0.05))) return(if (use_test=="trace") "r_trace_05" else "r_eigen_05")
  if (isTRUE(all.equal(alpha, 0.01))) return(if (use_test=="trace") "r_trace_01" else "r_eigen_01")
  stop("alpha must be one of 0.10, 0.05, 0.01")
}

tie_break_rank_within_cell <- function(pic_table,
                                       grid_rank_decisions,
                                       use_test = c("trace","eigen"),
                                       alpha = 0.05,
                                       pic_tol = 0.05) {
  use_test <- match.arg(use_test)
  jcol <- pick_johansen_col(use_test, alpha)
  if (!jcol %in% names(grid_rank_decisions)) stop(paste("Missing Johansen decision column:", jcol))
  
  best2 <- pic_table |>
    dplyr::group_by(window, ecdet, p) |>
    dplyr::arrange(PIC, BIC, r, .by_group = TRUE) |>
    dplyr::slice_head(n = 2) |>
    dplyr::mutate(rank_in_pic = dplyr::row_number()) |>
    dplyr::ungroup()
  
  base <- best2 |>
    dplyr::filter(rank_in_pic == 1) |>
    dplyr::transmute(window, ecdet, p, T, m,
                     r_base = r, PIC_base = PIC, BIC_base = BIC, logdet_base = logdet)
  
  alt <- best2 |>
    dplyr::filter(rank_in_pic == 2) |>
    dplyr::transmute(window, ecdet, p,
                     r_alt = r, PIC_alt = PIC, BIC_alt = BIC, logdet_alt = logdet)
  
  out <- base |>
    dplyr::left_join(alt, by = c("window","ecdet","p")) |>
    dplyr::left_join(grid_rank_decisions, by = c("window","ecdet","p")) |>
    dplyr::mutate(
      pic_gap = PIC_alt - PIC_base,
      alt_exists = !is.na(r_alt),
      alt_pic_close = alt_exists & (pic_gap <= pic_tol),
      
      johansen_suggested = .data[[jcol]],
      reject_H0_r_le_base = !is.na(johansen_suggested) & (johansen_suggested > r_base),
      
      r_selected = dplyr::case_when(
        !alt_exists ~ r_base,
        !alt_pic_close ~ r_base,
        alt_pic_close & reject_H0_r_le_base ~ r_alt,
        TRUE ~ r_base
      ),
      
      reason_A = dplyr::case_when(
        !alt_exists ~ "Only one candidate in cell (no runner-up)",
        alt_exists & !alt_pic_close ~ sprintf("Runner-up not close (ΔPIC=%.3f > tol=%.3f)", pic_gap, pic_tol),
        alt_pic_close & reject_H0_r_le_base ~ "Runner-up close and Johansen suggests higher rank than base: select alt rank",
        alt_pic_close & !reject_H0_r_le_base ~ "Runner-up close but Johansen does not reject rank<=base: keep base rank",
        TRUE ~ "Fallback: keep base rank"
      )
    ) |>
    dplyr::as_tibble()
  
  out <- out[order(match(out$window, WINDOW_ORDER),
                   match(out$ecdet, ECDET_ORDER),
                   out$p), , drop = FALSE]
  as.data.frame(out)
}

select_final_per_window <- function(cell_selection, pic_tol_window = 0.05) {
  cs <- cell_selection |>
    dplyr::mutate(
      PIC_selected = ifelse(!is.na(r_alt) & (r_selected == r_alt), PIC_alt, PIC_base),
      BIC_selected = ifelse(!is.na(r_alt) & (r_selected == r_alt), BIC_alt, BIC_base),
      logdet_selected = ifelse(!is.na(r_alt) & (r_selected == r_alt), logdet_alt, logdet_base)
    ) |>
    dplyr::as_tibble()
  
  finals <- list()
  ledgers <- list()
  
  for (w in WINDOW_ORDER) {
    sub <- cs |> dplyr::filter(window == w)
    if (nrow(sub) == 0) next
    
    minPIC <- min(sub$PIC_selected, na.rm = TRUE)
    shortlist <- sub |> dplyr::filter(PIC_selected <= (minPIC + pic_tol_window))
    
    chosen <- shortlist[order(shortlist$BIC_selected,
                              shortlist$p,
                              match(shortlist$ecdet, ECDET_ORDER)), , drop = FALSE][1, , drop = FALSE]
    
    reason_B <- if (nrow(shortlist) == 1) {
      sprintf("Unique min PIC within window (tol=%.3f)", pic_tol_window)
    } else {
      sprintf("Shortlist within ΔPIC<=%.3f; chose lowest BIC then smallest p", pic_tol_window)
    }
    
    m_val <- if ("m" %in% names(chosen)) chosen$m else NA_integer_
    T_val <- if ("T" %in% names(chosen)) chosen$T else NA_integer_
    
    finals[[w]] <- data.frame(
      window = chosen$window,
      ecdet  = chosen$ecdet,
      p      = chosen$p,
      r      = chosen$r_selected,
      T      = T_val,
      m      = m_val,
      logdet = chosen$logdet_selected,
      PIC    = chosen$PIC_selected,
      BIC    = chosen$BIC_selected,
      reason = paste(chosen$reason_A, reason_B, sep = " | "),
      stringsAsFactors = FALSE
    )
    
    
    led <- shortlist |>
      dplyr::mutate(
        chosen = (window == chosen$window & ecdet == chosen$ecdet & p == chosen$p),
        window_minPIC = minPIC,
        tol_window = pic_tol_window
      ) |>
      dplyr::transmute(
        window, ecdet, p,
        r_base, r_alt, r_selected,
        PIC_base, PIC_alt, PIC_selected,
        BIC_base, BIC_alt, BIC_selected,
        pic_gap, johansen_suggested,
        reason_A,
        window_minPIC, tol_window,
        chosen
      )
    ledgers[[w]] <- as.data.frame(led)
  }
  
  final_tbl  <- do.call(rbind, finals)
  ledger_tbl <- do.call(rbind, ledgers)
  
  final_tbl  <- final_tbl[order(match(final_tbl$window, WINDOW_ORDER)), , drop = FALSE]
  ledger_tbl <- ledger_tbl[order(match(ledger_tbl$window, WINDOW_ORDER),
                                 match(ledger_tbl$ecdet, ECDET_ORDER),
                                 ledger_tbl$p), , drop = FALSE]
  
  list(final = final_tbl, ledger = ledger_tbl)
}

S4_cell_selection <- tie_break_rank_within_cell(
  pic_table = pic_table,
  grid_rank_decisions = grid_rank_decisions,
  use_test = "trace",
  alpha = 0.05,
  pic_tol = 0.05
)

S4 <- select_final_per_window(S4_cell_selection, pic_tol_window = 0.05)
S4_final  <- S4$final
S4_ledger <- S4$ledger

# Exports: S4 to VisST + mirror to tidytable
export_pair(
  S4_final,
  file.path(DIRS$vis_csv, "S4_final_recommendations.csv"),
  file.path(DIRS$vis_tex, "S4_final_recommendations.tex"),
  caption = "S4: Final recommended specification per window",
  label   = "tab:S4_final_recommendations",
  digits  = 3
)
export_pair(
  S4_ledger,
  file.path(DIRS$vis_csv, "S4_decision_ledger.csv"),
  file.path(DIRS$vis_tex, "S4_decision_ledger.tex"),
  caption = "S4: Decision ledger (PIC shortlist + Johansen screen)",
  label   = "tab:S4_decision_ledger",
  digits  = 3
)

export_pair(
  S4_final,
  file.path(DIRS$tid_csv, "S4_final_recommendations.csv"),
  file.path(DIRS$tid_tex, "S4_final_recommendations.tex"),
  caption = "S4: Final recommended specification per window",
  label   = "tab:S4_final_recommendations",
  digits  = 3
)
export_pair(
  S4_ledger,
  file.path(DIRS$tid_csv, "S4_decision_ledger.csv"),
  file.path(DIRS$tid_tex, "S4_decision_ledger.tex"),
  caption = "S4: Decision ledger (PIC shortlist + Johansen screen)",
  label   = "tab:S4_decision_ledger",
  digits  = 3
)

#### 11) Console summary ####
cat("\n========================================\n")
cat("ChaoPhillip_VisST: FINAL RECOMMENDATIONS (S4)\n")
cat("========================================\n")
print(S4_final)

cat("\nNotes:\n")
cat("- p = VAR lag length; VECM uses (p-1) lagged differences when r>=1.\n")
cat("- ecdet: none = no constant in EC term; const = restricted constant in EC term.\n")
cat("========================================\n")
