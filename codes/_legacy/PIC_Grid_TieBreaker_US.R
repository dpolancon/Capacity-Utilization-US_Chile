
############################################################
## EXPORTS (CSV + TEX) — TOP5 PIC + TIE-BREAK (JOHANSEN)
## Requires objects already in memory:
##   - pic_table
##   - grid_rank_decisions
## Requires dirs already defined:
##   - grid_root, grid_csv
############################################################

## 0) Ensure output subdirs for tex
grid_tex <- file.path(grid_root, "tex")
ensure_dirs(grid_tex)

WINDOW_ORDER <- c("full","ford","post")

## 1) Helper: write TeX table via kableExtra
write_tex_table <- function(df, out_path, caption = NULL, label = NULL, digits = 3) {
  # Safe: keep LaTeX-friendly formatting (escape = TRUE by default)
  # If you want raw LaTeX in cells, set escape = FALSE manually here.
  tex <- df |>
    knitr::kable(
      format   = "latex",
      booktabs = TRUE,
      longtable = TRUE,
      caption  = caption,
      label    = label,
      digits   = digits
    ) |>
    kableExtra::kable_styling(
      latex_options = c("hold_position", "repeat_header"),
      font_size = 9
    )
  writeLines(tex, con = out_path)
}

## 2) TOP 5 PIC candidates per window (combined + per-window)
top5_by_window <- pic_table |>
  dplyr::mutate(
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet, levels = c("none","const"))
  ) |>
  dplyr::arrange(window, PIC, BIC, K, ecdet, r) |>
  dplyr::group_by(window) |>
  dplyr::slice_head(n = 5) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    window = as.character(window),
    ecdet  = as.character(ecdet)
  )

# Export combined
utils::write.csv(
  top5_by_window,
  file.path(grid_csv, "pic_top5_by_window.csv"),
  row.names = FALSE
)

write_tex_table(
  top5_by_window,
  file.path(grid_tex, "pic_top5_by_window.tex"),
  caption = "PIC: Top 5 candidates by window",
  label   = "tab:pic_top5_by_window"
)

# Export per-window
for (w in WINDOW_ORDER) {
  tmp <- dplyr::filter(top5_by_window, window == w)
  
  utils::write.csv(
    tmp,
    file.path(grid_csv, sprintf("pic_top5_%s.csv", w)),
    row.names = FALSE
  )
  
  write_tex_table(
    tmp,
    file.path(grid_tex, sprintf("pic_top5_%s.tex", w)),
    caption = sprintf("PIC: Top 5 candidates (window: %s)", w),
    label   = sprintf("tab:pic_top5_%s", w)
  )
}

## 3) Tie-breaker helpers (PIC + Johansen screen)

pick_johansen_col <- function(use_test = c("trace","eigen"), alpha = 0.05) {
  use_test <- match.arg(use_test)
  if (isTRUE(all.equal(alpha, 0.10))) return(if (use_test=="trace") "r_trace_10" else "r_eigen_10")
  if (isTRUE(all.equal(alpha, 0.05))) return(if (use_test=="trace") "r_trace_05" else "r_eigen_05")
  if (isTRUE(all.equal(alpha, 0.01))) return(if (use_test=="trace") "r_trace_01" else "r_eigen_01")
  stop("alpha must be one of 0.10, 0.05, 0.01")
}

tie_break_rank <- function(pic_table,
                           grid_rank_decisions,
                           use_test = c("trace","eigen"),
                           alpha = 0.05,
                           pic_tol = 0.05,
                           prefer_lower_rank_when_tied = TRUE) {
  
  use_test <- match.arg(use_test)
  jcol <- pick_johansen_col(use_test, alpha)
  
  # Take best and runner-up by PIC within each (window, ecdet, K)
  pic_best2 <- pic_table |>
    dplyr::group_by(window, ecdet, K) |>
    dplyr::arrange(PIC, BIC, r) |>
    dplyr::slice_head(n = 2) |>
    dplyr::mutate(rank_in_pic = dplyr::row_number()) |>
    dplyr::ungroup()
  
  baseline <- dplyr::filter(pic_best2, rank_in_pic == 1) |>
    dplyr::rename(r_base = r, PIC_base = PIC, BIC_base = BIC, logdet_base = logdet)
  
  alt <- dplyr::filter(pic_best2, rank_in_pic == 2) |>
    dplyr::rename(r_alt = r, PIC_alt = PIC, BIC_alt = BIC, logdet_alt = logdet)
  
  out <- baseline |>
    dplyr::left_join(alt, by = c("window","ecdet","K","p","T","m")) |>
    dplyr::left_join(grid_rank_decisions, by = c("window","ecdet","K")) |>
    dplyr::mutate(
      pic_gap = PIC_alt - PIC_base,
      alt_pic_close = !is.na(PIC_alt) & (pic_gap <= pic_tol),
      
      johansen_suggested = .data[[jcol]],
      
      # Reject H0: rank <= r_base  iff  suggested_rank(alpha) > r_base
      reject_H0_r_le_base = !is.na(johansen_suggested) & (johansen_suggested > r_base),
      
      r_selected = dplyr::case_when(
        is.na(r_alt) ~ r_base,
        !alt_pic_close ~ r_base,
        alt_pic_close & reject_H0_r_le_base ~ r_alt,
        TRUE ~ r_base
      )
    )
  
  if (prefer_lower_rank_when_tied) {
    out <- out |>
      dplyr::mutate(
        r_selected = dplyr::case_when(
          alt_pic_close & abs(pic_gap) <= pic_tol ~ pmin(r_base, r_alt),
          TRUE ~ r_selected
        )
      )
  }
  
  out |>
    dplyr::mutate(
      window = factor(window, levels = WINDOW_ORDER),
      ecdet  = factor(ecdet, levels = c("none","const"))
    ) |>
    dplyr::arrange(window, ecdet, K) |>
    dplyr::mutate(window = as.character(window),
                  ecdet  = as.character(ecdet))
}

## 4) Run tie-breaker and export (combined + per-window)
tie_break_results <- tie_break_rank(
  pic_table = pic_table,
  grid_rank_decisions = grid_rank_decisions,
  use_test = "trace",      # change to "eigen" if you want that screen instead
  alpha    = 0.05,
  pic_tol  = 0.05,
  prefer_lower_rank_when_tied = TRUE
)

# Export combined
utils::write.csv(
  tie_break_results,
  file.path(grid_csv, "rank_tiebreak_pic_plus_johansen.csv"),
  row.names = FALSE
)

write_tex_table(
  tie_break_results,
  file.path(grid_tex, "rank_tiebreak_pic_plus_johansen.tex"),
  caption = "Rank selection: PIC baseline + Johansen screening",
  label   = "tab:rank_tiebreak_pic_plus_johansen"
)

# Export per-window
for (w in WINDOW_ORDER) {
  tmp <- dplyr::filter(tie_break_results, window == w)
  
  utils::write.csv(
    tmp,
    file.path(grid_csv, sprintf("rank_tiebreak_%s.csv", w)),
    row.names = FALSE
  )
  
  write_tex_table(
    tmp,
    file.path(grid_tex, sprintf("rank_tiebreak_%s.tex", w)),
    caption = sprintf("Rank selection (PIC + Johansen screen), window: %s", w),
    label   = sprintf("tab:rank_tiebreak_%s", w)
  )
}

## 5) Console prints (ordered)
cat("\n========================================\n")
cat("PIC — Top 5 candidates per window (combined)\n")
cat("========================================\n")
print(top5_by_window)

cat("\n========================================\n")
cat("Tie-break results (PIC + Johansen screen)\n")
cat("========================================\n")
print(tie_break_results)

