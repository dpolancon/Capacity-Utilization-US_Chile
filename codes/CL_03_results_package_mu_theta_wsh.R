# ============================================================
# CHILE RESULTS PRESENTATION PACKAGE
# Uses Stage 1 + Stage 2 outputs
# Splice sample: ISI1931_1973 (active 1932-1973) + POST1974 (1974-2010)
# Capacity utilization path rescued under unbalanced-growth closure
# Pinch year: 1980 => u = 1
# ============================================================

suppressPackageStartupMessages({
  library(here)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(grid)
  library(tibble)
})

# -------------------------
# Paths
# -------------------------

path_stage1_master <- here::here("output", "chile_2Smu_S1", "txt", "stage1__master_results.rds")
path_stage2_root   <- here::here("output", "chile_2Smu_S2_tdols")

path_stage2_panel <- file.path(path_stage2_root, "csv", "stage2__working_panel.csv")
path_theta_isi    <- file.path(path_stage2_root, "csv", "threshold_theta__isi1931_1973.csv")
path_theta_post   <- file.path(path_stage2_root, "csv", "threshold_theta__post1974.csv")

out_root <- path_stage2_root
out_csv  <- file.path(out_root, "csv")
out_tex  <- file.path(out_root, "tex")
out_figs <- file.path(out_root, "figs")
out_txt  <- file.path(out_root, "txt")

dir.create(out_csv,  recursive = TRUE, showWarnings = FALSE)
dir.create(out_tex,  recursive = TRUE, showWarnings = FALSE)
dir.create(out_figs, recursive = TRUE, showWarnings = FALSE)
dir.create(out_txt,  recursive = TRUE, showWarnings = FALSE)

# -------------------------
# IO helpers
# -------------------------

write_txt <- function(lines, path) {
  writeLines(as.character(lines), con = path, useBytes = TRUE)
}

escape_tex <- function(x) {
  x <- as.character(x)
  x <- gsub("\\", "\\\\textbackslash{}", x, fixed = TRUE)
  x <- gsub("([_%#$&{}])", "\\\\1", x, perl = TRUE)
  x
}

df_to_tex <- function(df, file) {
  if (ncol(df) == 0) {
    writeLines("\\begin{tabular}{l}\nempty\\\\\n\\end{tabular}", con = file)
    return(invisible(NULL))
  }
  
  df2 <- df
  for (j in seq_along(df2)) {
    if (is.numeric(df2[[j]])) {
      df2[[j]] <- ifelse(is.na(df2[[j]]), "", format(round(df2[[j]], 6), trim = TRUE, scientific = FALSE))
    } else {
      df2[[j]] <- ifelse(is.na(df2[[j]]), "", as.character(df2[[j]]))
    }
  }
  
  cols <- ncol(df2)
  align <- paste(rep("l", cols), collapse = "")
  header <- paste(escape_tex(names(df2)), collapse = " & ")
  body <- apply(df2, 1, function(row) paste(escape_tex(row), collapse = " & "))
  
  lines <- c(
    paste0("\\begin{tabular}{", align, "}"),
    "\\hline",
    paste0(header, " \\\\"),
    "\\hline",
    paste0(body, " \\\\"),
    "\\hline",
    "\\end{tabular}"
  )
  
  writeLines(lines, con = file, useBytes = TRUE)
  invisible(NULL)
}

export_table <- function(df, stem) {
  write_csv(df, file.path(out_csv, paste0(stem, ".csv")))
  df_to_tex(df, file.path(out_tex, paste0(stem, ".tex")))
}

save_dual <- function(plot_obj, stem, width = 8.8, height = 5.2) {
  ggsave(
    filename = file.path(out_figs, paste0(stem, ".png")),
    plot = plot_obj, width = width, height = height, dpi = 320
  )
  ggsave(
    filename = file.path(out_figs, paste0(stem, ".pdf")),
    plot = plot_obj, width = width, height = height
  )
}

# -------------------------
# Safety checks
# -------------------------

need_files <- c(
  path_stage1_master,
  path_stage2_panel,
  path_theta_isi,
  path_theta_post
)

missing_files <- need_files[!file.exists(need_files)]
if (length(missing_files) > 0) {
  stop("Missing required files:\n", paste(missing_files, collapse = "\n"), call. = FALSE)
}

# -------------------------
# Load Stage 1 + Stage 2 objects
# -------------------------

stage1_master <- readRDS(path_stage1_master)
panel_stage2  <- read_csv(path_stage2_panel, show_col_types = FALSE)
theta_isi     <- read_csv(path_theta_isi, show_col_types = FALSE)
theta_post    <- read_csv(path_theta_post, show_col_types = FALSE)

# -------------------------
# Pull Stage 1 ECT by explicit sample/spec/lag/rank
# -------------------------

extract_stage1_ect <- function(stage1_master, sample, spec = "S1_B", lag = 1, rank = 1) {
  out <- stage1_master$ect_series %>%
    dplyr::filter(sample == !!sample, spec == !!spec, lag == !!lag, rank == !!rank) %>%
    dplyr::arrange(year) %>%
    dplyr::select(year, ECT)
  
  if (nrow(out) == 0) {
    stop("No Stage 1 ECT found for sample=", sample, ", spec=", spec, ", lag=", lag, ", rank=", rank, call. = FALSE)
  }
  
  out
}

ect_isi  <- extract_stage1_ect(stage1_master, "ISI1931_1973")
ect_post <- extract_stage1_ect(stage1_master, "POST1974")

# -------------------------
# Build splice panel
# true sample = partition output of ISI1931_1973 + POST1974
# active span = 1932-2010
# -------------------------

core <- panel_stage2 %>%
  dplyr::select(year, y, k_nr, wsh) %>%
  dplyr::filter(year >= 1932, year <= 2010)

isi_part <- theta_isi %>%
  dplyr::select(year, regime_code, theta_r1, theta_r2, theta_active) %>%
  dplyr::left_join(ect_isi, by = "year") %>%
  dplyr::mutate(true_sample = "ISI1931_1973")

post_part <- theta_post %>%
  dplyr::select(year, regime_code, theta_r1, theta_r2, theta_active) %>%
  dplyr::left_join(ect_post, by = "year") %>%
  dplyr::mutate(true_sample = "POST1974")

ts_splice <- dplyr::bind_rows(isi_part, post_part) %>%
  dplyr::filter(year >= 1932, year <= 2010) %>%
  dplyr::arrange(year) %>%
  dplyr::left_join(core, by = "year") %>%
  dplyr::mutate(
    regime_code = factor(regime_code, levels = c("low_ect_side", "high_ect_side")),
    dlog_k_nr = c(NA_real_, diff(k_nr))
  )

if (!1980 %in% ts_splice$year) {
  stop("Pinch year 1980 is not in the spliced sample.", call. = FALSE)
}
if (any(!is.finite(ts_splice$y))) {
  stop("Spliced panel has missing y values.", call. = FALSE)
}
if (any(!is.finite(ts_splice$k_nr))) {
  stop("Spliced panel has missing k_nr values.", call. = FALSE)
}
if (any(!is.finite(ts_splice$theta_active))) {
  stop("Spliced panel has missing theta_active values.", call. = FALSE)
}

# -------------------------
# Rescue productive-capacity path under unbalanced-growth closure
# Assumption:
#   Δ log Y^p_t = theta_t * Δ log K_t
# Pinch year:
#   u_1980 = 1  => log Y^p_1980 = log Y_1980
# Forward recursion:
#   logYp_t = logYp_{t-1} + theta_t * ΔlogK_t
# Backward recursion:
#   logYp_t = logYp_{t+1} - theta_{t+1} * ΔlogK_{t+1}
# -------------------------

rescue_u_path <- function(df, pinch_year = 1980) {
  df <- df %>% dplyr::arrange(year)
  idx0 <- which(df$year == pinch_year)
  
  if (length(idx0) != 1L) {
    stop("Pinch year not found uniquely.", call. = FALSE)
  }
  
  logYp <- rep(NA_real_, nrow(df))
  logYp[idx0] <- df$y[idx0]
  
  if (idx0 < nrow(df)) {
    for (i in (idx0 + 1):nrow(df)) {
      if (!is.finite(df$dlog_k_nr[i]) || !is.finite(df$theta_active[i])) {
        stop("Missing dlog_k_nr or theta_active in forward recursion at year ", df$year[i], call. = FALSE)
      }
      logYp[i] <- logYp[i - 1] + df$theta_active[i] * df$dlog_k_nr[i]
    }
  }
  
  if (idx0 > 1) {
    for (i in seq(idx0 - 1, 1)) {
      j <- i + 1
      if (!is.finite(df$dlog_k_nr[j]) || !is.finite(df$theta_active[j])) {
        stop("Missing dlog_k_nr or theta_active in backward recursion at year ", df$year[j], call. = FALSE)
      }
      logYp[i] <- logYp[j] - df$theta_active[j] * df$dlog_k_nr[j]
    }
  }
  
  df %>%
    dplyr::mutate(
      log_y_p = logYp,
      y_p = exp(log_y_p),
      u = exp(y - log_y_p)
    )
}

ts_splice <- rescue_u_path(ts_splice, pinch_year = 1980)

# -------------------------
# Save core time-series dataset
# -------------------------

ts_export <- ts_splice %>%
  dplyr::select(
    year,
    true_sample,
    regime_code,
    wsh,
    ECT,
    theta_r1,
    theta_r2,
    theta_active,
    y,
    k_nr,
    dlog_k_nr,
    log_y_p,
    y_p,
    u
  )

write_csv(ts_export, file.path(out_csv, "results_ts_splice_1932_2010.csv"))

# -------------------------
# Episode summary table
# -------------------------

episode_tbl <- ts_splice %>%
  dplyr::arrange(year) %>%
  dplyr::mutate(
    episode = cumsum(dplyr::coalesce(regime_code != dplyr::lag(regime_code), TRUE))
  ) %>%
  dplyr::group_by(true_sample, episode, regime_code) %>%
  dplyr::summarise(
    start_year = min(year),
    end_year = max(year),
    n_years = dplyr::n(),
    ect_mean = mean(ECT, na.rm = TRUE),
    theta_mean = mean(theta_active, na.rm = TRUE),
    u_mean = mean(u, na.rm = TRUE),
    wsh_mean = mean(wsh, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  dplyr::arrange(start_year)

export_table(episode_tbl, "results_regime_episodes_1932_2010")

# -------------------------
# Plot helpers
# -------------------------

rescale_to_primary <- function(x, from_min, from_max, to_min, to_max) {
  if (!is.finite(from_min) || !is.finite(from_max) || from_max <= from_min) {
    stop("Invalid scaling range.", call. = FALSE)
  }
  to_min + (x - from_min) * (to_max - to_min) / (from_max - from_min)
}

inverse_rescale <- function(y, from_min, from_max, to_min, to_max) {
  from_min + (y - to_min) * (from_max - from_min) / (to_max - to_min)
}

build_regime_bands <- function(df) {
  df %>%
    dplyr::arrange(year) %>%
    dplyr::mutate(
      ep = cumsum(dplyr::coalesce(regime_code != dplyr::lag(regime_code), TRUE))
    ) %>%
    dplyr::group_by(ep, regime_code) %>%
    dplyr::summarise(
      xmin = min(year) - 0.5,
      xmax = max(year) + 0.5,
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      fill = ifelse(regime_code == "low_ect_side", "#E5E5E5", "#F7F7F7")
    )
}

base_theme <- function(x_angle = 90) {
  theme_minimal(base_size = 11) +
    theme(
      legend.position = c(0.03, 0.97),
      legend.direction = "vertical",
      legend.justification = c(0, 1),
      legend.background = element_rect(fill = "white", color = "black", linewidth = 0.3),
      legend.box.background = element_rect(fill = "white", color = "black", linewidth = 0.3),
      legend.key = element_blank(),
      legend.key.width = unit(1.2, "cm"),
      legend.key.height = unit(0.55, "cm"),
      legend.text = element_text(size = 10, color = "black"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line = element_blank(),
      axis.ticks = element_blank(),
      axis.text.x = element_text(size = 9, angle = x_angle, vjust = 0.5, hjust = 1, color = "black"),
      axis.text.y.left = element_text(size = 10, color = "black"),
      axis.text.y.right = element_text(size = 10, color = "black"),
      axis.title.y.left = element_text(size = 10, color = "black"),
      axis.title.y.right = element_text(size = 10, color = "black"),
      axis.title.x = element_blank(),
      plot.title = element_blank(),
      plot.subtitle = element_blank(),
      panel.border = element_blank(),
      plot.background = element_blank(),
      panel.background = element_blank(),
      plot.margin = margin(5.5, 8, 15, 5.5)
    )
}

make_dual_plot <- function(df, primary_var, secondary_var,
                           primary_label, secondary_label,
                           primary_legend, secondary_legend,
                           stem, yline_at_1_primary = FALSE,
                           vline_1973 = TRUE,
                           mark_every_year = FALSE,
                           width = 8.8, height = 5.2) {
  df <- df %>% dplyr::arrange(year)
  bands <- build_regime_bands(df)
  
  pmin <- min(df[[primary_var]], na.rm = TRUE)
  pmax <- max(df[[primary_var]], na.rm = TRUE)
  prng <- pmax - pmin
  ppad <- max(prng * 0.20, 0.0015)
  y_lower <- pmin - ppad
  y_upper <- pmax + ppad
  
  smin <- min(df[[secondary_var]], na.rm = TRUE)
  smax <- max(df[[secondary_var]], na.rm = TRUE)
  if (!is.finite(smin) || !is.finite(smax) || smax <= smin) {
    stop("Secondary series has invalid range for plotting.", call. = FALSE)
  }
  
  df$secondary_scaled <- rescale_to_primary(df[[secondary_var]], smin, smax, y_lower, y_upper)
  
  x_breaks <- if (mark_every_year) seq(min(df$year), max(df$year), by = 1) else pretty(df$year, n = 10)
  
  g <- ggplot(df, aes(x = year)) +
    geom_rect(
      data = bands,
      aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
      inherit.aes = FALSE,
      fill = bands$fill,
      alpha = 0.20
    ) +
    geom_line(aes(y = .data[[primary_var]], color = primary_legend, linetype = primary_legend), linewidth = 1.0) +
    geom_line(aes(y = secondary_scaled, color = secondary_legend, linetype = secondary_legend), linewidth = 0.9)
  
  if (vline_1973) {
    g <- g + geom_vline(xintercept = 1973, linewidth = 0.4, linetype = "dashed")
  }
  if (yline_at_1_primary) {
    g <- g + geom_hline(yintercept = 1, linewidth = 0.4, linetype = "dashed")
  }
  if (mark_every_year) {
    g <- g + geom_point(aes(y = .data[[primary_var]]), size = 0.9) +
      geom_point(aes(y = secondary_scaled), size = 0.8, shape = 1)
  }
  
  color_vals <- c("black", "#D55E00")
  names(color_vals) <- c(primary_legend, secondary_legend)
  
  linetype_vals <- c("solid", "dashed")
  names(linetype_vals) <- c(primary_legend, secondary_legend)
  
  g <- g +
    scale_color_manual(values = color_vals, name = NULL) +
    scale_linetype_manual(values = linetype_vals, name = NULL) +
    scale_x_continuous(
      breaks = x_breaks,
      labels = x_breaks,
      expand = expansion(mult = c(0.01, 0.03))
    ) +
    scale_y_continuous(
      limits = c(y_lower, y_upper),
      expand = expansion(mult = c(0, 0)),
      name = primary_label,
      sec.axis = sec_axis(
        trans = ~ inverse_rescale(., smin, smax, y_lower, y_upper),
        name = secondary_label
      )
    ) +
    labs(y = primary_label) +
    base_theme(x_angle = ifelse(mark_every_year, 90, 0)) +
    guides(color = guide_legend(override.aes = list(linewidth = c(1.0, 0.9))), linetype = "none") +
    coord_cartesian(clip = "off")
  
  save_dual(g, stem = stem, width = width, height = height)
  invisible(g)
}

# -------------------------
# Window registry
# -------------------------

window_registry <- list(
  full_sample = list(
    data = ts_splice %>% dplyr::filter(year >= 1932, year <= 2010),
    tag = "full_1932_2010",
    mark_every_year = FALSE,
    width = 9.2,
    height = 5.4
  ),
  zoom_isi_crisis_aftermath = list(
    data = ts_splice %>% dplyr::filter(year >= 1932, year <= 1978),
    tag = "zoom_1932_1978",
    mark_every_year = TRUE,
    width = 10.8,
    height = 5.8
  )
)

# -------------------------
# Plot registry
# -------------------------

plot_registry <- list(
  list(
    primary_var = "u",
    secondary_var = "theta_active",
    primary_label = "u",
    secondary_label = "theta",
    primary_legend = "u",
    secondary_legend = "theta",
    stem_prefix = "dual_u_theta",
    yline_at_1_primary = TRUE
  ),
  list(
    primary_var = "theta_active",
    secondary_var = "wsh",
    primary_label = "theta",
    secondary_label = "wage share",
    primary_legend = "theta",
    secondary_legend = "wage share",
    stem_prefix = "dual_theta_wsh",
    yline_at_1_primary = TRUE
  ),
  list(
    primary_var = "theta_active",
    secondary_var = "ECT",
    primary_label = "theta",
    secondary_label = "ECT",
    primary_legend = "theta",
    secondary_legend = "ECT",
    stem_prefix = "dual_theta_ect",
    yline_at_1_primary = TRUE
  )
)

# -------------------------
# Build all requested figures
# -------------------------

generated_figs <- list()

for (wname in names(window_registry)) {
  w <- window_registry[[wname]]
  
  for (p in plot_registry) {
    stem <- paste0(p$stem_prefix, "_", w$tag)
    
    make_dual_plot(
      df = w$data,
      primary_var = p$primary_var,
      secondary_var = p$secondary_var,
      primary_label = p$primary_label,
      secondary_label = p$secondary_label,
      primary_legend = p$primary_legend,
      secondary_legend = p$secondary_legend,
      stem = stem,
      yline_at_1_primary = p$yline_at_1_primary,
      vline_1973 = TRUE,
      mark_every_year = w$mark_every_year,
      width = w$width,
      height = w$height
    )
    
    generated_figs[[length(generated_figs) + 1]] <- tibble::tibble(
      window = wname,
      stem = stem
    )
  }
}

generated_figs_tbl <- dplyr::bind_rows(generated_figs)
readr::write_csv(generated_figs_tbl, file.path(out_csv, "results_generated_figs_manifest.csv"))

# -------------------------
# Session summary
# -------------------------

summary_lines <- c(
  "Chile results presentation package completed.",
  "",
  "Splice used:",
  " - ISI1931_1973 active span 1932-1973",
  " - POST1974 span 1974-2010",
  " - Pinch year 1980 => u = 1",
  "",
  "Windows:",
  " - full sample: 1932-2010",
  " - zoom: 1932-1978",
  "",
  "Core exports:",
  " - csv/results_ts_splice_1932_2010.csv",
  " - csv/results_regime_episodes_1932_2010.csv",
  " - tex/results_regime_episodes_1932_2010.tex",
  " - csv/results_generated_figs_manifest.csv",
  "",
  "Figure stems generated:"
)

if (length(generated_figs) > 0) {
  summary_lines <- c(
    summary_lines,
    paste0(" - ", generated_figs_tbl$stem, ".(png/pdf)")
  )
}

write_txt(summary_lines, file.path(out_txt, "results_presentation_package_summary.txt"))
cat(paste(summary_lines, collapse = "\n"), "\n")




# ============================================================
# APPENDIX PACKAGE — BASELINE DOLS SPLIT SAMPLES
# No threshold regime switching
# Splice sample: ISI1931_1973 + POST1974
# Pinch year: 1980 => u = 1
# ============================================================

# -------------------------
# Required additional files
# -------------------------

path_theta_isi_baseline  <- file.path(path_stage2_root, "csv", "baseline_theta__isi1931_1973.csv")
path_theta_post_baseline <- file.path(path_stage2_root, "csv", "baseline_theta__post1974.csv")

need_files_baseline <- c(path_theta_isi_baseline, path_theta_post_baseline)
missing_baseline <- need_files_baseline[!file.exists(need_files_baseline)]
if (length(missing_baseline) > 0) {
  stop("Missing baseline theta files:\n", paste(missing_baseline, collapse = "\n"), call. = FALSE)
}

theta_isi_baseline  <- read_csv(path_theta_isi_baseline,  show_col_types = FALSE)
theta_post_baseline <- read_csv(path_theta_post_baseline, show_col_types = FALSE)

# -------------------------
# Build baseline splice panel
# -------------------------

isi_part_baseline <- theta_isi_baseline %>%
  dplyr::rename(theta_active = theta_hat) %>%
  dplyr::left_join(ect_isi, by = "year") %>%
  dplyr::mutate(
    true_sample = "ISI1931_1973",
    regime_code = "baseline_split"
  )

post_part_baseline <- theta_post_baseline %>%
  dplyr::rename(theta_active = theta_hat) %>%
  dplyr::left_join(ect_post, by = "year") %>%
  dplyr::mutate(
    true_sample = "POST1974",
    regime_code = "baseline_split"
  )

ts_baseline_splice <- dplyr::bind_rows(isi_part_baseline, post_part_baseline) %>%
  dplyr::filter(year >= 1932, year <= 2010) %>%
  dplyr::arrange(year) %>%
  dplyr::left_join(core, by = "year") %>%
  dplyr::mutate(
    regime_code = factor(regime_code, levels = "baseline_split"),
    dlog_k_nr = c(NA_real_, diff(k_nr))
  )

if (!1980 %in% ts_baseline_splice$year) {
  stop("Pinch year 1980 is not in the baseline spliced sample.", call. = FALSE)
}
if (any(!is.finite(ts_baseline_splice$theta_active))) {
  stop("Baseline spliced panel has missing theta_active values.", call. = FALSE)
}

# -------------------------
# Rescue capacity utilization path
# -------------------------

ts_baseline_splice <- rescue_u_path(ts_baseline_splice, pinch_year = 1980)

# -------------------------
# Export core baseline dataset
# -------------------------

ts_baseline_export <- ts_baseline_splice %>%
  dplyr::select(
    year,
    true_sample,
    regime_code,
    wsh,
    ECT,
    theta_active,
    y,
    k_nr,
    dlog_k_nr,
    log_y_p,
    y_p,
    u
  )

write_csv(ts_baseline_export, file.path(out_csv, "results_ts_baseline_splice_1932_2010.csv"))

# -------------------------
# Simple window summary table
# -------------------------

baseline_summary_tbl <- ts_baseline_splice %>%
  dplyr::group_by(true_sample) %>%
  dplyr::summarise(
    start_year = min(year),
    end_year   = max(year),
    n_years    = dplyr::n(),
    ect_mean   = mean(ECT, na.rm = TRUE),
    theta_mean = mean(theta_active, na.rm = TRUE),
    theta_sd   = sd(theta_active, na.rm = TRUE),
    u_mean     = mean(u, na.rm = TRUE),
    u_sd       = sd(u, na.rm = TRUE),
    wsh_mean   = mean(wsh, na.rm = TRUE),
    .groups = "drop"
  )

export_table(baseline_summary_tbl, "results_baseline_split_summary_1932_2010")

# -------------------------
# Plot helper without regime shading
# -------------------------

make_dual_plot_baseline <- function(df, primary_var, secondary_var,
                                    primary_label, secondary_label,
                                    primary_legend, secondary_legend,
                                    stem, yline_at_1_primary = FALSE,
                                    vline_1973 = TRUE,
                                    mark_every_year = FALSE,
                                    width = 8.8, height = 5.2) {
  df <- df %>% dplyr::arrange(year)
  
  pmin <- min(df[[primary_var]], na.rm = TRUE)
  pmax <- max(df[[primary_var]], na.rm = TRUE)
  prng <- pmax - pmin
  ppad <- max(prng * 0.20, 0.0015)
  y_lower <- pmin - ppad
  y_upper <- pmax + ppad
  
  smin <- min(df[[secondary_var]], na.rm = TRUE)
  smax <- max(df[[secondary_var]], na.rm = TRUE)
  if (!is.finite(smin) || !is.finite(smax) || smax <= smin) {
    stop("Secondary series has invalid range for baseline plotting.", call. = FALSE)
  }
  
  df$secondary_scaled <- rescale_to_primary(df[[secondary_var]], smin, smax, y_lower, y_upper)
  x_breaks <- if (mark_every_year) seq(min(df$year), max(df$year), by = 1) else pretty(df$year, n = 10)
  
  g <- ggplot(df, aes(x = year)) +
    geom_line(aes(y = .data[[primary_var]], color = primary_legend, linetype = primary_legend), linewidth = 1.0) +
    geom_line(aes(y = secondary_scaled, color = secondary_legend, linetype = secondary_legend), linewidth = 0.9)
  
  if (vline_1973) {
    g <- g + geom_vline(xintercept = 1973, linewidth = 0.4, linetype = "dashed")
  }
  if (yline_at_1_primary) {
    g <- g + geom_hline(yintercept = 1, linewidth = 0.4, linetype = "dashed")
  }
  if (mark_every_year) {
    g <- g + geom_point(aes(y = .data[[primary_var]]), size = 0.9) +
      geom_point(aes(y = secondary_scaled), size = 0.8, shape = 1)
  }
  
  color_vals <- c("black", "#D55E00")
  names(color_vals) <- c(primary_legend, secondary_legend)
  
  linetype_vals <- c("solid", "dashed")
  names(linetype_vals) <- c(primary_legend, secondary_legend)
  
  g <- g +
    scale_color_manual(values = color_vals, name = NULL) +
    scale_linetype_manual(values = linetype_vals, name = NULL) +
    scale_x_continuous(
      breaks = x_breaks,
      labels = x_breaks,
      expand = expansion(mult = c(0.01, 0.03))
    ) +
    scale_y_continuous(
      limits = c(y_lower, y_upper),
      expand = expansion(mult = c(0, 0)),
      name = primary_label,
      sec.axis = sec_axis(
        trans = ~ inverse_rescale(., smin, smax, y_lower, y_upper),
        name = secondary_label
      )
    ) +
    labs(y = primary_label) +
    base_theme(x_angle = ifelse(mark_every_year, 90, 0)) +
    guides(color = guide_legend(override.aes = list(linewidth = c(1.0, 0.9))), linetype = "none") +
    coord_cartesian(clip = "off")
  
  save_dual(g, stem = stem, width = width, height = height)
  invisible(g)
}

# -------------------------
# Window registry — baseline package
# -------------------------

window_registry_baseline <- list(
  full_sample = list(
    data = ts_baseline_splice %>% dplyr::filter(year >= 1932, year <= 2010),
    tag = "baseline_full_1932_2010",
    mark_every_year = FALSE,
    width = 9.2,
    height = 5.4
  ),
  zoom_isi_crisis_aftermath = list(
    data = ts_baseline_splice %>% dplyr::filter(year >= 1932, year <= 1978),
    tag = "baseline_zoom_1932_1978",
    mark_every_year = TRUE,
    width = 10.8,
    height = 5.8
  )
)

# -------------------------
# Plot registry — baseline package
# -------------------------

plot_registry_baseline <- list(
  list(
    primary_var = "u",
    secondary_var = "theta_active",
    primary_label = "u",
    secondary_label = "theta",
    primary_legend = "u",
    secondary_legend = "theta",
    stem_prefix = "dual_u_theta",
    yline_at_1_primary = TRUE
  ),
  list(
    primary_var = "theta_active",
    secondary_var = "wsh",
    primary_label = "theta",
    secondary_label = "wage share",
    primary_legend = "theta",
    secondary_legend = "wage share",
    stem_prefix = "dual_theta_wsh",
    yline_at_1_primary = TRUE
  ),
  list(
    primary_var = "theta_active",
    secondary_var = "ECT",
    primary_label = "theta",
    secondary_label = "ECT",
    primary_legend = "theta",
    secondary_legend = "ECT",
    stem_prefix = "dual_theta_ect",
    yline_at_1_primary = TRUE
  )
)

# -------------------------
# Build baseline figures
# -------------------------

generated_figs_baseline <- list()

for (wname in names(window_registry_baseline)) {
  w <- window_registry_baseline[[wname]]
  
  for (p in plot_registry_baseline) {
    stem <- paste0(p$stem_prefix, "_", w$tag)
    
    make_dual_plot_baseline(
      df = w$data,
      primary_var = p$primary_var,
      secondary_var = p$secondary_var,
      primary_label = p$primary_label,
      secondary_label = p$secondary_label,
      primary_legend = p$primary_legend,
      secondary_legend = p$secondary_legend,
      stem = stem,
      yline_at_1_primary = p$yline_at_1_primary,
      vline_1973 = TRUE,
      mark_every_year = w$mark_every_year,
      width = w$width,
      height = w$height
    )
    
    generated_figs_baseline[[length(generated_figs_baseline) + 1]] <- tibble::tibble(
      window = wname,
      stem = stem
    )
  }
}

generated_figs_baseline_tbl <- dplyr::bind_rows(generated_figs_baseline)
write_csv(generated_figs_baseline_tbl, file.path(out_csv, "results_generated_figs_manifest_baseline.csv"))

# -------------------------
# Append summary lines
# -------------------------

summary_lines_baseline <- c(
  "",
  "Baseline split-sample package completed.",
  "No threshold regime switching.",
  "",
  "Core exports:",
  " - csv/results_ts_baseline_splice_1932_2010.csv",
  " - csv/results_baseline_split_summary_1932_2010.csv",
  " - tex/results_baseline_split_summary_1932_2010.tex",
  " - csv/results_generated_figs_manifest_baseline.csv",
  "",
  "Baseline figure stems generated:"
)

if (nrow(generated_figs_baseline_tbl) > 0) {
  summary_lines_baseline <- c(
    summary_lines_baseline,
    paste0(" - ", generated_figs_baseline_tbl$stem, ".(png/pdf)")
  )
}

write_txt(
  c(summary_lines, summary_lines_baseline),
  file.path(out_txt, "results_presentation_package_summary.txt")
)

cat(paste(summary_lines_baseline, collapse = "\n"), "\n")
