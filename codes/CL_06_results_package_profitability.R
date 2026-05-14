###############################################################################
# CHILE — Profitability results package
# Reads analytical_bundle_chile.rds and exports tables / figures
# Always dual plotting (.png and .pdf)
###############################################################################

# ── 0. Packages ──────────────────────────────────────────────────────────────
pkgs <- c("dplyr", "readr", "tibble", "ggplot2", "tidyr", "knitr")
miss <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss) > 0) install.packages(miss, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

# ── 1. Paths ─────────────────────────────────────────────────────────────────
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
rds_dir   <- file.path(proj_root, "output", "profitability_chile", "rds")
res_dir   <- file.path(proj_root, "output", "profitability_chile", "results_pack")
csv_dir   <- file.path(res_dir, "csv")
tex_dir   <- file.path(res_dir, "tex")
fig_dir   <- file.path(res_dir, "figs")

for (p in c(csv_dir, tex_dir, fig_dir)) dir.create(p, recursive = TRUE, showWarnings = FALSE)

bundle_path <- file.path(rds_dir, "analytical_bundle_chile.rds")
if (!file.exists(bundle_path)) stop("Missing analytical bundle: ", bundle_path, call. = FALSE)

# ── 2. Helpers ───────────────────────────────────────────────────────────────
escape_latex <- function(x) {
  x <- as.character(x)
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([_%#$&{}])", "\\\\\\1", x, perl = TRUE)
  x
}

save_table_dual <- function(df, stem, digits = 4) {
  readr::write_csv(df, file.path(csv_dir, paste0(stem, ".csv")))
  
  out <- df
  for (j in seq_along(out)) {
    if (is.numeric(out[[j]])) {
      out[[j]] <- format(round(out[[j]], digits), trim = TRUE, scientific = FALSE)
    }
    out[[j]] <- ifelse(is.na(out[[j]]), "", as.character(out[[j]]))
  }
  
  align <- paste(rep("l", ncol(out)), collapse = "")
  header <- paste(escape_latex(names(out)), collapse = " & ")
  body <- apply(out, 1, function(row) paste(escape_latex(row), collapse = " & "))
  
  lines <- c(
    paste0("\\begin{tabular}{", align, "}"),
    "\\hline",
    paste0(header, " \\\\"),
    "\\hline",
    paste0(body, " \\\\"),
    "\\hline",
    "\\end{tabular}"
  )
  
  writeLines(lines, con = file.path(tex_dir, paste0(stem, ".tex")), useBytes = TRUE)
}

save_plot_dual <- function(plot_obj, stem, width = 8.4, height = 4.8, dpi = 320) {
  ggplot2::ggsave(file.path(fig_dir, paste0(stem, ".png")), plot_obj, width = width, height = height, dpi = dpi)
  ggplot2::ggsave(file.path(fig_dir, paste0(stem, ".pdf")), plot_obj, width = width, height = height)
}

theme_results_min <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_blank(),
      legend.title = ggplot2::element_blank(),
      axis.title.x = ggplot2::element_blank()
    )
}

zscore <- function(x) {
  s <- stats::sd(x, na.rm = TRUE)
  m <- mean(x, na.rm = TRUE)
  if (!is.finite(s) || s <= 0) return(rep(NA_real_, length(x)))
  (x - m) / s
}

# ── 3. Load bundle ───────────────────────────────────────────────────────────
b <- readRDS(bundle_path)

required_bundle_objects <- c(
  "d",
  "tp_env_final",
  "swing_tbl_full",
  "swing_tbl_compact",
  "year_tbl_dys",
  "year_tbl_compact",
  "year_tbl_recap",
  "swing_tbl_recap",
  "accounting_wedge_summary"
)

miss_bundle_objects <- required_bundle_objects[!required_bundle_objects %in% names(b)]
if (length(miss_bundle_objects) > 0) {
  stop("Bundle is missing objects: ", paste(miss_bundle_objects, collapse = ", "), call. = FALSE)
}

d  <- b$d
yd <- b$year_tbl_dys
sw <- b$swing_tbl_full
sr <- b$swing_tbl_recap
tp <- b$tp_env_final

# ── 4. Export core tables ────────────────────────────────────────────────────
save_table_dual(b$swing_tbl_compact, "tab01_profit_swings_compact_chile", digits = 4)
save_table_dual(b$year_tbl_compact,  "tab02_yearly_dysfunctionality_chile", digits = 4)
save_table_dual(sr,                  "tab03_swing_recapitalization_chile", digits = 4)
save_table_dual(b$accounting_wedge_summary, "tab04_accounting_wedge_summary_chile", digits = 4)

# ── 5. Figures built on UPDATED indices and saved objects ────────────────────

# Fig 1: profitability with turning points as actually stored in bundle
# Use ln_r_diag_t because tp_env_final in the successful run was finalized against that series.
turn_pts <- tp |>
  dplyr::filter(type %in% c("peak", "trough")) |>
  dplyr::mutate(plot_y = d$ln_r_diag_t[idx])

p1 <- ggplot(d, aes(x = year, y = ln_r_diag_t)) +
  geom_line(linewidth = 0.95) +
  geom_point(data = turn_pts, aes(y = plot_y, shape = type), size = 2.2, color = "black") +
  scale_shape_manual(values = c(peak = 24, trough = 25)) +
  labs(y = "log diagnostic profitability") +
  theme_results_min()
save_plot_dual(p1, "fig01_chile_profitability_turning_points", width = 8.8, height = 4.8)

# Fig 2: swing decomposition shares
plot_decomp <- sw |>
  dplyr::select(
    swing_id, start_year, end_year,
    dist_share_pct, util_share_pct, price_share_pct, capacity_share_pct, wedge_share_pct
  ) |>
  tidyr::pivot_longer(
    cols = c(dist_share_pct, util_share_pct, price_share_pct, capacity_share_pct, wedge_share_pct),
    names_to = "component",
    values_to = "share"
  ) |>
  dplyr::mutate(label = paste0(start_year, "-", end_year))

p2 <- ggplot(plot_decomp, aes(x = label, y = share, fill = component)) +
  geom_col(position = "stack", width = 0.75) +
  geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.3) +
  labs(y = "share of structural swing (%)") +
  theme_results_min() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")
save_plot_dual(p2, "fig02_chile_profit_swing_decomposition", width = 9.4, height = 5.0)

# Fig 3: yearly gross/net/dysfunctionality
plot_idx <- yd |>
  dplyr::select(year, G_t, N_t, D_t) |>
  tidyr::pivot_longer(cols = c(G_t, N_t, D_t), names_to = "series", values_to = "value")

p3 <- ggplot(plot_idx, aes(x = year, y = value, linetype = series)) +
  geom_line(linewidth = 0.9) +
  labs(y = "index value") +
  theme_results_min()
save_plot_dual(p3, "fig03_chile_yearly_gross_net_dysfunctionality", width = 8.8, height = 4.8)

# Fig 4: yearly offsetting share and reversal fragility
plot_frag <- yd |>
  dplyr::select(year, S_off_t, F_rev_t) |>
  tidyr::pivot_longer(cols = c(S_off_t, F_rev_t), names_to = "series", values_to = "value")

p4 <- ggplot(plot_frag, aes(x = year, y = value, linetype = series)) +
  geom_line(linewidth = 0.9) +
  labs(y = "share / fragility") +
  theme_results_min()
save_plot_dual(p4, "fig04_chile_yearly_offsetting_reversal_fragility", width = 8.8, height = 4.8)

# Fig 5: swing-level updated dysfunctionality package
plot_sw_idx <- sw |>
  dplyr::select(start_year, end_year, D_swing, S_off_swing, F_rev_swing) |>
  dplyr::mutate(label = paste0(start_year, "-", end_year)) |>
  tidyr::pivot_longer(cols = c(D_swing, S_off_swing, F_rev_swing), names_to = "series", values_to = "value")

p5 <- ggplot(plot_sw_idx, aes(x = label, y = value, group = series, linetype = series)) +
  geom_line(linewidth = 0.85) +
  geom_point(size = 1.8) +
  labs(y = "swing index value") +
  theme_results_min() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
save_plot_dual(p5, "fig05_chile_dysfunctionality_swings_updated", width = 9.0, height = 4.8)

# Fig 6: chi and accounting wedge over time (z-scored overlay)
plot_rec <- d |>
  dplyr::transmute(
    year,
    z_chi = zscore(chi_t),
    z_wedge = zscore(accounting_wedge_t)
  ) |>
  tidyr::pivot_longer(cols = c(z_chi, z_wedge), names_to = "series", values_to = "value")

p6 <- ggplot(plot_rec, aes(x = year, y = value, linetype = series)) +
  geom_line(linewidth = 0.9) +
  labs(y = "standardized series") +
  theme_results_min()
save_plot_dual(p6, "fig06_chile_chi_wedge_timeseries", width = 8.8, height = 4.8)

# Fig 7: chi vs reversal fragility by swing
plot_scatter <- sw |>
  dplyr::filter(is.finite(avg_chi), is.finite(F_rev_swing))

p7 <- ggplot(plot_scatter, aes(x = avg_chi, y = F_rev_swing)) +
  geom_point(size = 2.1) +
  geom_text(aes(label = paste0(start_year, "-", end_year)), nudge_y = 0.015, size = 3, check_overlap = TRUE) +
  labs(x = "average recapitalization ratio (chi)", y = "reversal fragility") +
  theme_results_min() +
  theme(axis.title.x = element_text())
save_plot_dual(p7, "fig07_chile_chi_vs_reversal_fragility", width = 8.2, height = 4.8)

cat("Saved Chile profitability results pack to:\n")
cat("  ", res_dir, "\n", sep = "")