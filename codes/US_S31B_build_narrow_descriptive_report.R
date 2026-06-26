#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(scales)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
report_rel <- file.path("reports", "report_dstat_2026-06-24")
report_dir <- file.path(root, report_rel)
fig_dir <- file.path(report_dir, "figures")
table_dir <- file.path(report_dir, "tables")
validation_dir <- file.path(report_dir, "validation")
broad_dir <- file.path(root, "output", "US", "S31B_DESCRIPTIVE_STATISTICS_AND_HISTORICAL_PROFILES")

if (dir.exists(report_dir)) unlink(report_dir, recursive = TRUE, force = TRUE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(validation_dir, recursive = TRUE, showWarnings = FALSE)

read_csv <- function(path) {
  if (!file.exists(path)) stop("Missing input: ", path, call. = FALSE)
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}
write_csv <- function(x, path) write.csv(x, path, row.names = FALSE, na = "")
write_text <- function(x, path) writeLines(enc2utf8(x), path, useBytes = TRUE)
fmt_num <- function(x, digits = 2) {
  ifelse(is.na(x), "--", formatC(x, format = "f", digits = digits, big.mark = ","))
}
fmt_int <- function(x) ifelse(is.na(x), "--", formatC(x, format = "f", digits = 0, big.mark = ","))
fmt_pct <- function(x, digits = 2) paste0(fmt_num(x, digits), "%")
fmt_pp <- function(x, digits = 2) paste0(fmt_num(x, digits), " pp")
fmt_ratio <- function(x) fmt_num(x, 3)
slug_label <- function(x) {
  out <- gsub("_", " ", x, fixed = TRUE)
  tools::toTitleCase(out)
}
md_escape <- function(x) gsub("|", "\\|", as.character(x), fixed = TRUE)
tex_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "\\&", x, fixed = TRUE)
  x <- gsub("%", "\\%", x, fixed = TRUE)
  x <- gsub("#", "\\#", x, fixed = TRUE)
  x <- gsub("_", "\\_\\allowbreak{}", x, fixed = TRUE)
  x
}
md_table <- function(x) {
  x[] <- lapply(x, function(v) md_escape(ifelse(is.na(v), "--", v)))
  c(
    paste0("| ", paste(names(x), collapse = " | "), " |"),
    paste0("| ", paste(rep("---", ncol(x)), collapse = " | "), " |"),
    apply(x, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  )
}
tex_table <- function(x, caption, label, widths = NULL, landscape = FALSE, font = "\\scriptsize",
                      table_number = NULL) {
  if (is.null(widths)) widths <- rep("l", ncol(x))
  align <- paste(widths, collapse = "")
  for (nm in names(x)) {
    if (identical(nm, "Notation")) {
      x[[nm]] <- ifelse(is.na(x[[nm]]), "--", x[[nm]])
    } else {
      x[[nm]] <- tex_escape(ifelse(is.na(x[[nm]]), "--", x[[nm]]))
    }
  }
  rows <- apply(x, 1, function(r) paste0(paste(r, collapse = " & "), " \\\\"))
  c(
    if (!is.null(table_number)) sprintf("\\setcounter{table}{%d}", table_number - 1L) else character(),
    if (landscape) "\\begin{landscape}" else character(),
    "\\begin{center}",
    font,
    sprintf("\\begin{longtable}{%s}", align),
    sprintf("\\caption{%s}\\label{%s}\\\\", caption, label),
    "\\toprule",
    paste0(paste(tex_escape(names(x)), collapse = " & "), " \\\\"),
    "\\midrule",
    "\\endfirsthead",
    "\\toprule",
    paste0(paste(tex_escape(names(x)), collapse = " & "), " \\\\"),
    "\\midrule",
    "\\endhead",
    rows,
    "\\bottomrule",
    "\\end{longtable}",
    "\\normalsize",
    "\\end{center}",
    if (landscape) "\\end{landscape}" else character()
  )
}
hash_file <- function(path) {
  unname(tools::md5sum(path))
}
hash_tree <- function(path) {
  files <- sort(list.files(path, recursive = TRUE, full.names = TRUE))
  data.frame(path = substring(normalizePath(files, winslash = "/", mustWork = TRUE),
                              nchar(root) + 2L),
             md5 = unname(tools::md5sum(files)), stringsAsFactors = FALSE)
}

if (!dir.exists(broad_dir)) stop("Completed S31B output directory is missing.", call. = FALSE)
broad_hash_before <- hash_tree(broad_dir)

canonical_path <- file.path(root, "data", "releases", "chapter2_us_source_of_truth_v1",
                            "CH2_US_SOURCE_OF_TRUTH_LONG.csv")
components_path <- file.path(root, "output", "US",
                             "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION", "csv",
                             "S29E_core_capital_stocks_flows_long.csv")
registry_path <- file.path(broad_dir, "csv", "S31B_variable_registry.csv")
structural_source_path <- file.path(broad_dir, "csv", "S31B_structural_window_descriptive_statistics.csv")
transition_source_path <- file.path(broad_dir, "csv", "S31B_transition_window_descriptive_statistics.csv")
event_source_path <- file.path(broad_dir, "csv", "S31B_event_profile_values.csv")
accounting_path <- file.path(broad_dir, "csv", "S31B_accounting_correspondence_ledger.csv")
validation_source_path <- file.path(broad_dir, "validation", "S31B_validation_checks.csv")

canonical <- read_csv(canonical_path)
components <- read_csv(components_path)
broad_registry <- read_csv(registry_path)
broad_structural <- read_csv(structural_source_path)
broad_transition <- read_csv(transition_source_path)
broad_events <- read_csv(event_source_path)
broad_accounting <- read_csv(accounting_path)
broad_validation <- read_csv(validation_source_path)

report_ids <- c(
  "Y_REAL_NFC_GVA_BASELINE",
  "G_TOT_GPIM_2017",
  "KAPPA_ME_NRC",
  "CORP_COMPENSATION_SHARE_GVA",
  "CORP_COMPENSATION_SHARE_NVA",
  "NFC_COMPENSATION_SHARE_GVA",
  "NFC_COMPENSATION_SHARE_NVA"
)
share_ids <- report_ids[4:7]
level_ids <- report_ids[1:2]
component_ids <- c("G_ME_GPIM_2017", "G_NRC_GPIM_2017")

meta <- data.frame(
  variable_id = report_ids,
  family = c("Output", "Productive capital", "Capital composition",
             rep("Distribution", 4)),
  label = c(
    "Real gross value added of nonfinancial corporate business",
    "Aggregate gross productive-capital stock",
    "Machinery-to-nonresidential-structures capital-composition ratio",
    "Corporate compensation share of GVA",
    "Corporate compensation share of NVA",
    "NFC compensation share of GVA",
    "NFC compensation share of NVA"
  ),
  notation_md = c(
    "$Y_t^{NFC}$", "$K_t^{P}$", "$\\kappa_t^{ME/NRC}$",
    "$\\omega_t^{C,GVA}$", "$\\omega_t^{C,NVA}$",
    "$\\omega_t^{NFC,GVA}$", "$\\omega_t^{NFC,NVA}$"
  ),
  notation_tex = c(
    "$Y_t^{NFC}$", "$K_t^{P}$", "$\\kappa_t^{ME/NRC}$",
    "$\\omega_t^{C,GVA}$", "$\\omega_t^{C,NVA}$",
    "$\\omega_t^{NFC,GVA}$", "$\\omega_t^{NFC,NVA}$"
  ),
  boundary = c(
    "NFC; gross value added",
    "NFC productive-capital aggregate",
    "NFC capital-component ratio",
    "Corporate; gross value added",
    "Corporate; net value added",
    "NFC; gross value added",
    "NFC; net value added"
  ),
  later_role = c(
    "Output candidate", "Capital-scale candidate", "Composition candidate",
    rep("Distributive candidate; eligible, not selected", 4)
  ),
  stringsAsFactors = FALSE
)

exact_series <- function(id) {
  z <- canonical[canonical$variable_id == id, c("year", "value")]
  z$year <- as.integer(z$year)
  z$value <- as.numeric(z$value)
  z <- z[order(z$year), ]
  if (!nrow(z)) stop("Canonical series missing: ", id, call. = FALSE)
  z
}
component_series <- function(id) {
  z <- components[components$variable_id == id, c("year", "value")]
  z$year <- as.integer(z$year)
  z$value <- as.numeric(z$value)
  z <- z[order(z$year), ]
  if (!nrow(z)) stop("Component series missing: ", id, call. = FALSE)
  z
}

series_list <- list()
for (id in c(level_ids, share_ids)) {
  z <- exact_series(id)
  z$variable_id <- id
  series_list[[id]] <- z[, c("variable_id", "year", "value")]
}
me <- component_series(component_ids[1])
nrc <- component_series(component_ids[2])
kappa <- merge(me, nrc, by = "year", suffixes = c("_me", "_nrc"))
kappa$value <- kappa$value_me / kappa$value_nrc
kappa$variable_id <- "KAPPA_ME_NRC"
series_list[["KAPPA_ME_NRC"]] <- kappa[, c("variable_id", "year", "value")]
series <- do.call(rbind, series_list)
series <- merge(series, meta[, c("variable_id", "family", "label")], by = "variable_id", all.x = TRUE)
series <- series[order(match(series$variable_id, report_ids), series$year), ]

derive_changes <- function(z) {
  z <- z[order(z$year), ]
  z$previous_year <- c(NA_integer_, head(z$year, -1L))
  z$previous_value <- c(NA_real_, head(z$value, -1L))
  valid <- z$year == z$previous_year + 1L & !is.na(z$value) & !is.na(z$previous_value)
  z$annual_change <- NA_real_
  if (z$variable_id[1] %in% level_ids) {
    z$annual_change[valid] <- 100 * (z$value[valid] / z$previous_value[valid] - 1)
    z$change_unit <- "percent"
  } else if (z$variable_id[1] == "KAPPA_ME_NRC") {
    z$annual_change[valid] <- z$value[valid] - z$previous_value[valid]
    z$change_unit <- "ratio points"
  } else {
    z$annual_change[valid] <- 100 * (z$value[valid] - z$previous_value[valid])
    z$change_unit <- "percentage points"
  }
  z
}
series <- do.call(rbind, lapply(split(series, series$variable_id), derive_changes))
series <- series[order(match(series$variable_id, report_ids), series$year), ]

windows <- data.frame(
  window_id = c(
    "global_available", "pre_1974", "post_1974", "pre_fordist",
    "fordist_core_1947_1973", "extended_fordist_bridge_1940_1978",
    "post_fordist_pre_gfc_1974_2008", "mature_post_volcker_pre_gfc_1983_2008",
    "post_gfc_2009_2025", "post_gfc_pre_covid_2009_2019",
    "post_covid_configuration_2022_2025"
  ),
  window_type = c("global", "structural", "structural", "nested", "nested", "bridge",
                  "structural", "nested", "structural", "nested", "nested"),
  start_year = c(NA, NA, 1974, NA, 1947, 1940, 1974, 1983, 2009, 2009, 2022),
  end_year = c(NA, 1973, 2025, 1946, 1973, 1978, 2008, 2008, 2025, 2019, 2025),
  descriptive_eligible = "yes",
  testing_eligible = "not_decided",
  estimation_eligible = "not_decided",
  stringsAsFactors = FALSE
)
transitions <- data.frame(
  window_id = c("fordist_aftermath_1974_1978", "volcker_transition_1979_1982",
                "gfc_transition_2008_2009", "covid_transition_2020_2021"),
  window_type = "transition",
  start_year = c(1974, 1979, 2008, 2020),
  end_year = c(1978, 1982, 2009, 2021),
  descriptive_eligible = "yes",
  testing_eligible = "no",
  estimation_eligible = "no",
  stringsAsFactors = FALSE
)
events <- data.frame(
  event_id = c("volcker_event_profile_1978_1983", "gfc_event_profile_2007_2010",
               "covid_event_profile_2019_2022"),
  start_year = c(1978, 2007, 2019),
  end_year = c(1983, 2010, 2022),
  onset_year = c(1979, 2008, 2020),
  stringsAsFactors = FALSE
)

window_stats <- function(z, map_row) {
  start <- map_row$start_year
  end <- map_row$end_year
  if (is.na(start)) start <- min(z$year, na.rm = TRUE)
  if (is.na(end)) end <- max(z$year, na.rm = TRUE)
  q <- z[z$year >= start & z$year <= end, ]
  q <- q[!is.na(q$value), ]
  expected <- max(0, end - start + 1)
  first <- if (nrow(q)) q[1, ] else NULL
  last <- if (nrow(q)) q[nrow(q), ] else NULL
  changes <- q$annual_change[!is.na(q$annual_change) & q$year >= start & q$year <= end]
  id <- z$variable_id[1]
  scale <- if (id %in% share_ids) 100 else 1
  cumulative <- if (!nrow(q)) NA_real_ else if (id %in% level_ids) {
    100 * (last$value / first$value - 1)
  } else if (id == "KAPPA_ME_NRC") {
    last$value - first$value
  } else {
    100 * (last$value - first$value)
  }
  data.frame(
    variable_id = id, window_id = map_row$window_id,
    window_type = map_row$window_type, start_year = start, end_year = end,
    n_expected = expected, n_observed = nrow(q),
    coverage_percent = if (expected) 100 * nrow(q) / expected else NA_real_,
    initial_year = if (nrow(q)) first$year else NA_integer_,
    initial_value = if (nrow(q)) scale * first$value else NA_real_,
    terminal_year = if (nrow(q)) last$year else NA_integer_,
    terminal_value = if (nrow(q)) scale * last$value else NA_real_,
    mean = if (nrow(q)) mean(scale * q$value) else NA_real_,
    median = if (nrow(q)) median(scale * q$value) else NA_real_,
    standard_deviation = if (nrow(q) > 1) sd(scale * q$value) else NA_real_,
    minimum = if (nrow(q)) min(scale * q$value) else NA_real_,
    maximum = if (nrow(q)) max(scale * q$value) else NA_real_,
    initial_to_terminal_change = cumulative,
    mean_annual_change = if (length(changes)) mean(changes) else NA_real_,
    annual_change_volatility = if (length(changes) > 1) sd(changes) else NA_real_,
    descriptive_eligible = map_row$descriptive_eligible,
    testing_eligible = map_row$testing_eligible,
    estimation_eligible = map_row$estimation_eligible,
    stringsAsFactors = FALSE
  )
}

make_stats <- function(map) {
  do.call(rbind, lapply(report_ids, function(id) {
    z <- series[series$variable_id == id, ]
    do.call(rbind, lapply(seq_len(nrow(map)), function(i) window_stats(z, map[i, ])))
  }))
}
structural_stats <- make_stats(windows)
transition_stats <- make_stats(transitions)

event_values <- do.call(rbind, lapply(seq_len(nrow(events)), function(i) {
  e <- events[i, ]
  q <- series[series$year >= e$start_year & series$year <= e$end_year, ]
  q$event_id <- e$event_id
  q$event_onset_year <- e$onset_year
  q$position <- ifelse(q$year < e$onset_year, "pre_event",
                       ifelse(q$year == e$onset_year, "event_onset", "post_onset"))
  q$display_value <- ifelse(q$variable_id %in% share_ids, 100 * q$value, q$value)
  q[, c("event_id", "event_onset_year", "position", "variable_id", "year",
        "display_value", "annual_change", "change_unit")]
}))

table1 <- meta[, c("family", "label", "notation_md", "variable_id", "boundary", "later_role")]
names(table1) <- c("Economic family", "Paper-facing label", "Notation", "Repository ID",
                   "Accounting boundary", "Role in later regressions")
write_csv(table1, file.path(table_dir, "table_01_narrow_variable_menu.csv"))

full_sample <- structural_stats[structural_stats$window_id == "global_available", ]
full_sample <- merge(meta[, c("variable_id", "label")], full_sample, by = "variable_id")
full_sample <- full_sample[match(report_ids, full_sample$variable_id), ]
table2 <- full_sample[, c("variable_id", "label", "initial_year", "terminal_year", "n_observed",
                          "coverage_percent", "initial_value", "terminal_value", "mean",
                          "standard_deviation", "minimum", "maximum",
                          "initial_to_terminal_change", "mean_annual_change",
                          "annual_change_volatility")]
write_csv(table2, file.path(table_dir, "table_02_full_sample_descriptive_summary.csv"))

priority_windows <- c(
  "fordist_core_1947_1973", "post_fordist_pre_gfc_1974_2008",
  "mature_post_volcker_pre_gfc_1983_2008", "post_gfc_2009_2025",
  "post_gfc_pre_covid_2009_2019", "post_covid_configuration_2022_2025"
)
table3 <- structural_stats[structural_stats$window_id %in% priority_windows, ]
table3 <- merge(meta[, c("variable_id", "label")], table3, by = "variable_id")
table3 <- table3[order(match(table3$window_id, priority_windows),
                       match(table3$variable_id, report_ids)), ]
table3 <- table3[, c("variable_id", "label", "window_id", "initial_year", "terminal_year",
                     "n_observed", "coverage_percent", "initial_value", "terminal_value",
                     "mean", "initial_to_terminal_change", "mean_annual_change",
                     "annual_change_volatility")]
write_csv(table3, file.path(table_dir, "table_03_structural_window_comparison.csv"))
write_csv(structural_stats, file.path(table_dir, "supplement_complete_11_window_statistics.csv"))

table4 <- merge(meta[, c("variable_id", "label")], transition_stats, by = "variable_id")
table4 <- table4[order(match(table4$window_id, transitions$window_id),
                       match(table4$variable_id, report_ids)), ]
table4 <- table4[, c("variable_id", "label", "window_id", "initial_year", "terminal_year",
                     "n_observed", "initial_value", "terminal_value",
                     "initial_to_terminal_change", "mean_annual_change",
                     "testing_eligible", "estimation_eligible")]
write_csv(table4, file.path(table_dir, "table_04_transition_window_statistics.csv"))

event_wide <- reshape(event_values[, c("event_id", "year", "variable_id", "display_value")],
                      idvar = c("event_id", "year"), timevar = "variable_id", direction = "wide")
names(event_wide) <- sub("^display_value\\.", "", names(event_wide))
event_wide <- event_wide[order(match(event_wide$event_id, events$event_id), event_wide$year), ]
write_csv(event_wide, file.path(table_dir, "table_05_event_profile_annual_observations.csv"))
write_csv(event_values, file.path(table_dir, "supplement_event_profile_changes.csv"))

table6 <- data.frame(
  variable_id = report_ids,
  sector_boundary = c("NFC", "NFC productive capital", "NFC component ratio",
                      "Corporate", "Corporate", "NFC", "NFC"),
  gross_or_net_denominator = c("Gross value added", "Not applicable", "Not applicable",
                               "GVA", "NVA", "GVA", "NVA"),
  strict_output_correspondence = c("Output object", "No", "No", "No", "No",
                                   "Yes: Y_REAL_NFC_GVA_BASELINE", "No: same-sector net alternative"),
  later_regression_eligibility = c("eligible", "eligible", "eligible", rep("eligible", 4)),
  selection_status = c(rep("documented; not selected at S31B", 7)),
  stringsAsFactors = FALSE
)
write_csv(table6, file.path(table_dir, "table_06_accounting_correspondence_and_candidate_status.csv"))

table7 <- rbind(
  windows[, c("window_id", "window_type", "start_year", "end_year",
              "descriptive_eligible", "testing_eligible", "estimation_eligible")],
  transitions[, c("window_id", "window_type", "start_year", "end_year",
                  "descriptive_eligible", "testing_eligible", "estimation_eligible")],
  data.frame(window_id = events$event_id, window_type = "event profile",
             start_year = events$start_year, end_year = events$end_year,
             descriptive_eligible = "yes", testing_eligible = "no",
             estimation_eligible = "no", stringsAsFactors = FALSE)
)
write_csv(table7, file.path(table_dir, "table_07_historical_window_registry.csv"))

display_value <- function(id, x) {
  if (id %in% level_ids) fmt_int(x) else if (id == "KAPPA_ME_NRC") fmt_ratio(x) else fmt_num(x, 2)
}
display_change <- function(id, x) {
  if (id %in% level_ids) fmt_pct(x) else if (id == "KAPPA_ME_NRC") fmt_ratio(x) else fmt_pp(x)
}

table2_display <- data.frame(
  Variable = table2$variable_id,
  Coverage = paste0(table2$initial_year, "-", table2$terminal_year),
  N = table2$n_observed,
  Initial = mapply(display_value, table2$variable_id, table2$initial_value),
  Terminal = mapply(display_value, table2$variable_id, table2$terminal_value),
  Mean = mapply(display_value, table2$variable_id, table2$mean),
  SD = mapply(display_value, table2$variable_id, table2$standard_deviation),
  `Initial-terminal change` = mapply(display_change, table2$variable_id,
                                      table2$initial_to_terminal_change),
  `Mean annual change` = mapply(display_change, table2$variable_id, table2$mean_annual_change),
  check.names = FALSE
)
table3_display <- data.frame(
  Variable = table3$variable_id,
  Window = table3$window_id,
  N = table3$n_observed,
  Initial = mapply(display_value, table3$variable_id, table3$initial_value),
  Terminal = mapply(display_value, table3$variable_id, table3$terminal_value),
  Mean = mapply(display_value, table3$variable_id, table3$mean),
  Change = mapply(display_change, table3$variable_id, table3$initial_to_terminal_change),
  `Mean annual change` = mapply(display_change, table3$variable_id, table3$mean_annual_change),
  Volatility = mapply(display_change, table3$variable_id, table3$annual_change_volatility),
  check.names = FALSE
)
table4_display <- data.frame(
  Variable = table4$variable_id,
  Window = table4$window_id,
  N = table4$n_observed,
  Initial = mapply(display_value, table4$variable_id, table4$initial_value),
  Terminal = mapply(display_value, table4$variable_id, table4$terminal_value),
  Change = mapply(display_change, table4$variable_id, table4$initial_to_terminal_change),
  `Mean annual change` = mapply(display_change, table4$variable_id, table4$mean_annual_change),
  Testing = table4$testing_eligible,
  Estimation = table4$estimation_eligible,
  check.names = FALSE
)
event_display <- event_wide
for (id in report_ids) {
  event_display[[id]] <- mapply(function(v) display_value(id, v), event_display[[id]])
}
short_ids <- setNames(c("Y_NFC", "K_P", "kappa_ME_NRC", "omega_C_GVA", "omega_C_NVA",
                        "omega_NFC_GVA", "omega_NFC_NVA"), report_ids)
table2_display$Variable <- unname(short_ids[table2_display$Variable])
table3_display$Variable <- unname(short_ids[table3_display$Variable])
table4_display$Variable <- unname(short_ids[table4_display$Variable])
names(event_display) <- c("Event", "Year", unname(short_ids[report_ids]))

theme_report <- theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 9, color = "#444444"),
    legend.position = "bottom",
    axis.title = element_text(size = 9),
    plot.caption = element_text(size = 8, color = "#555555", hjust = 0)
  )
markers <- data.frame(year = c(1947, 1974, 1979, 1982, 2008, 2009, 2020, 2022))
marker_layer <- geom_vline(data = markers, aes(xintercept = year),
                           linewidth = 0.25, linetype = "dotted", color = "#777777")
save_plot <- function(p, filename, width = 8.2, height = 4.6) {
  ggsave(file.path(fig_dir, filename), p, width = width, height = height,
         dpi = 220, bg = "white")
}
series_one <- function(id) series[series$variable_id == id, ]

z <- series_one(level_ids[1])
save_plot(ggplot(z, aes(year, value / 1e6)) + marker_layer +
            geom_line(linewidth = 0.7, color = "#1b6ca8") +
            labs(title = "Real NFC output", subtitle = "Observed level of Y_t^{NFC}",
                 x = NULL, y = "Trillions of 2017-price-equivalent dollars",
                 caption = "Historical markers are reference dates, not estimated breakpoints.") +
            theme_report, "figure_01_nfc_output_level.png")
save_plot(ggplot(z[!is.na(z$annual_change), ], aes(year, annual_change)) + marker_layer +
            geom_hline(yintercept = 0, linewidth = 0.3, color = "#555555") +
            geom_col(fill = "#4f86c6", width = 0.8) +
            labs(title = "Annual proportional growth of real NFC output",
                 subtitle = "100 x (Y_t^{NFC}/Y_{t-1}^{NFC} - 1)",
                 x = NULL, y = "Percent",
                 caption = "Historical markers are reference dates, not estimated breakpoints.") +
            theme_report, "figure_02_nfc_output_growth.png")

z <- series_one(level_ids[2])
save_plot(ggplot(z, aes(year, value / 1e6)) + marker_layer +
            geom_line(linewidth = 0.7, color = "#2f7d32") +
            labs(title = "Aggregate productive-capital stock",
                 subtitle = "Constructed GPIM aggregate K_t^P over heterogeneous assets",
                 x = NULL, y = "Trillions of 2017 dollars",
                 caption = "The aggregate is not asserted to be a physical sum of homogeneous components.") +
            theme_report, "figure_03_productive_capital_level.png")
save_plot(ggplot(z[!is.na(z$annual_change), ], aes(year, annual_change)) + marker_layer +
            geom_hline(yintercept = 0, linewidth = 0.3, color = "#555555") +
            geom_col(fill = "#5a9b5c", width = 0.8) +
            labs(title = "Annual proportional growth of aggregate productive capital",
                 subtitle = "100 x (K_t^P/K_{t-1}^P - 1)",
                 x = NULL, y = "Percent",
                 caption = "Historical markers are reference dates, not estimated breakpoints.") +
            theme_report, "figure_04_productive_capital_growth.png")

z <- series_one("KAPPA_ME_NRC")
save_plot(ggplot(z, aes(year, value)) + marker_layer +
            geom_line(linewidth = 0.75, color = "#9a5b13") +
            labs(title = "Machinery-to-structures capital-composition ratio",
                 subtitle = "kappa_t^{ME/NRC} = K_t^{ME}/K_t^{NRC}",
                 x = NULL, y = "Observed ratio",
                 caption = "A directional composition indicator; not a share of total productive capital.") +
            theme_report, "figure_05_kappa_me_nrc.png")

shares_plot_data <- series[series$variable_id %in% share_ids, ]
shares_plot_data$share_percent <- 100 * shares_plot_data$value
share_colors <- c(
  "CORP_COMPENSATION_SHARE_GVA" = "#1b6ca8",
  "CORP_COMPENSATION_SHARE_NVA" = "#d1495b",
  "NFC_COMPENSATION_SHARE_GVA" = "#2f7d32",
  "NFC_COMPENSATION_SHARE_NVA" = "#8f5aa8"
)
plot_shares <- function(ids, title, filename) {
  q <- shares_plot_data[shares_plot_data$variable_id %in% ids, ]
  p <- ggplot(q, aes(year, share_percent, color = variable_id)) + marker_layer +
    geom_line(linewidth = 0.7) +
    scale_color_manual(values = share_colors, labels = setNames(meta$label, meta$variable_id)) +
    labs(title = title, x = NULL, y = "Percent", color = NULL,
         caption = "Historical markers are reference dates, not estimated breakpoints.") +
    theme_report
  save_plot(p, filename)
}
plot_shares(share_ids[1:2], "Corporate GVA and NVA compensation shares",
            "figure_06_corporate_gva_nva_wage_shares.png")
plot_shares(share_ids[3:4], "NFC GVA and NVA compensation shares",
            "figure_07_nfc_gva_nva_wage_shares.png")
plot_shares(share_ids[c(1, 3)], "Corporate versus NFC GVA compensation shares",
            "figure_08_corporate_nfc_gva_wage_shares.png")
plot_shares(share_ids[c(2, 4)], "Corporate versus NFC NVA compensation shares",
            "figure_09_corporate_nfc_nva_wage_shares.png")

event_plot_labels <- setNames(c("Y NFC", "K P", "kappa ME/NRC",
                                "omega C,GVA", "omega C,NVA",
                                "omega NFC,GVA", "omega NFC,NVA"), report_ids)
for (i in seq_len(nrow(events))) {
  e <- events[i, ]
  q <- event_values[event_values$event_id == e$event_id, ]
  q$panel <- event_plot_labels[q$variable_id]
  q$plot_value <- q$display_value
  p <- ggplot(q, aes(year, plot_value, group = variable_id)) +
    geom_vline(xintercept = e$onset_year, linewidth = 0.35, linetype = "dashed", color = "#555555") +
    geom_line(linewidth = 0.65, color = "#1b6ca8") +
    geom_point(size = 1.4, color = "#1b6ca8") +
    facet_wrap(~panel, scales = "free_y", ncol = 2) +
    scale_x_continuous(breaks = e$start_year:e$end_year) +
    labs(title = slug_label(e$event_id),
         subtitle = "Year-by-year descriptive profile; dashed line marks the reference onset",
         x = NULL, y = "Observed value",
         caption = "Each panel retains its observed scale. The event window is not an independent statistical regime.") +
    theme_report + theme(axis.text.x = element_text(angle = 45, hjust = 1))
  save_plot(p, sprintf("figure_%02d_%s.png", 9 + i, e$event_id), width = 8.2, height = 8.0)
}

get_stat <- function(id, window, field, source = structural_stats) {
  z <- source[source$variable_id == id & source$window_id == window, field]
  if (length(z) != 1L) stop("Statistic lookup failed: ", id, " / ", window, " / ", field, call. = FALSE)
  as.numeric(z)
}
get_event <- function(id, event, year, field) {
  z <- event_values[event_values$variable_id == id & event_values$event_id == event &
                      event_values$year == year, field]
  if (length(z) != 1L) stop("Event lookup failed: ", id, " / ", event, " / ", year, call. = FALSE)
  as.numeric(z)
}

claims <- list()
add_claim <- function(id, section, variable, window, statistic, raw, formatted,
                      md_ref, tex_ref) {
  claims[[length(claims) + 1L]] <<- data.frame(
    claim_id = id, section = section, variable_id = variable, window_id = window,
    statistic = statistic, raw_value = raw, formatted_value = formatted,
    Markdown_claim_reference = md_ref, LaTeX_claim_reference = tex_ref,
    stringsAsFactors = FALSE
  )
  formatted
}

out_f_init <- add_claim("C01", "NFC real output", level_ids[1], priority_windows[1],
                        "initial_value", get_stat(level_ids[1], priority_windows[1], "initial_value"),
                        fmt_int(get_stat(level_ids[1], priority_windows[1], "initial_value")),
                        "sec-output-p1", "sec:output-p1")
out_f_term <- add_claim("C02", "NFC real output", level_ids[1], priority_windows[1],
                        "terminal_value", get_stat(level_ids[1], priority_windows[1], "terminal_value"),
                        fmt_int(get_stat(level_ids[1], priority_windows[1], "terminal_value")),
                        "sec-output-p1", "sec:output-p1")
out_f_growth <- add_claim("C03", "NFC real output", level_ids[1], priority_windows[1],
                          "mean_annual_change", get_stat(level_ids[1], priority_windows[1], "mean_annual_change"),
                          fmt_pct(get_stat(level_ids[1], priority_windows[1], "mean_annual_change")),
                          "sec-output-p1", "sec:output-p1")
out_pf_growth <- add_claim("C04", "NFC real output", level_ids[1], priority_windows[2],
                           "mean_annual_change", get_stat(level_ids[1], priority_windows[2], "mean_annual_change"),
                           fmt_pct(get_stat(level_ids[1], priority_windows[2], "mean_annual_change")),
                           "sec-output-p2", "sec:output-p2")
out_gfc_growth <- add_claim("C05", "NFC real output", level_ids[1], priority_windows[4],
                            "mean_annual_change", get_stat(level_ids[1], priority_windows[4], "mean_annual_change"),
                            fmt_pct(get_stat(level_ids[1], priority_windows[4], "mean_annual_change")),
                            "sec-output-p2", "sec:output-p2")
out_covid <- add_claim("C06", "NFC real output", level_ids[1], events$event_id[3],
                       "annual_change_2020", get_event(level_ids[1], events$event_id[3], 2020, "annual_change"),
                       fmt_pct(get_event(level_ids[1], events$event_id[3], 2020, "annual_change")),
                       "sec-output-p3", "sec:output-p3")

cap_f_growth <- add_claim("C07", "Productive-capital scale", level_ids[2], priority_windows[1],
                          "mean_annual_change", get_stat(level_ids[2], priority_windows[1], "mean_annual_change"),
                          fmt_pct(get_stat(level_ids[2], priority_windows[1], "mean_annual_change")),
                          "sec-capital-p1", "sec:capital-p1")
cap_pf_growth <- add_claim("C08", "Productive-capital scale", level_ids[2], priority_windows[2],
                           "mean_annual_change", get_stat(level_ids[2], priority_windows[2], "mean_annual_change"),
                           fmt_pct(get_stat(level_ids[2], priority_windows[2], "mean_annual_change")),
                           "sec-capital-p1", "sec:capital-p1")
cap_gfc_growth <- add_claim("C09", "Productive-capital scale", level_ids[2], priority_windows[4],
                            "mean_annual_change", get_stat(level_ids[2], priority_windows[4], "mean_annual_change"),
                            fmt_pct(get_stat(level_ids[2], priority_windows[4], "mean_annual_change")),
                            "sec-capital-p2", "sec:capital-p2")
cap_covid <- add_claim("C10", "Productive-capital scale", level_ids[2], events$event_id[3],
                       "annual_change_2020", get_event(level_ids[2], events$event_id[3], 2020, "annual_change"),
                       fmt_pct(get_event(level_ids[2], events$event_id[3], 2020, "annual_change")),
                       "sec-capital-p2", "sec:capital-p2")

kap_f_init <- add_claim("C11", "Capital composition", "KAPPA_ME_NRC", priority_windows[1],
                        "initial_value", get_stat("KAPPA_ME_NRC", priority_windows[1], "initial_value"),
                        fmt_ratio(get_stat("KAPPA_ME_NRC", priority_windows[1], "initial_value")),
                        "sec-kappa-p1", "sec:kappa-p1")
kap_f_term <- add_claim("C12", "Capital composition", "KAPPA_ME_NRC", priority_windows[1],
                        "terminal_value", get_stat("KAPPA_ME_NRC", priority_windows[1], "terminal_value"),
                        fmt_ratio(get_stat("KAPPA_ME_NRC", priority_windows[1], "terminal_value")),
                        "sec-kappa-p1", "sec:kappa-p1")
kap_pf_change <- add_claim("C13", "Capital composition", "KAPPA_ME_NRC", priority_windows[2],
                           "initial_to_terminal_change",
                           get_stat("KAPPA_ME_NRC", priority_windows[2], "initial_to_terminal_change"),
                           fmt_ratio(get_stat("KAPPA_ME_NRC", priority_windows[2], "initial_to_terminal_change")),
                           "sec-kappa-p2", "sec:kappa-p2")
kap_gfc_change <- add_claim("C14", "Capital composition", "KAPPA_ME_NRC", priority_windows[4],
                            "initial_to_terminal_change",
                            get_stat("KAPPA_ME_NRC", priority_windows[4], "initial_to_terminal_change"),
                            fmt_ratio(get_stat("KAPPA_ME_NRC", priority_windows[4], "initial_to_terminal_change")),
                            "sec-kappa-p2", "sec:kappa-p2")

share_c_f <- add_claim("C15", "Wage-share alternatives", share_ids[1], priority_windows[1],
                       "initial_to_terminal_change",
                       get_stat(share_ids[1], priority_windows[1], "initial_to_terminal_change"),
                       fmt_pp(get_stat(share_ids[1], priority_windows[1], "initial_to_terminal_change")),
                       "sec-shares-p1", "sec:shares-p1")
share_n_f <- add_claim("C16", "Wage-share alternatives", share_ids[3], priority_windows[1],
                       "initial_to_terminal_change",
                       get_stat(share_ids[3], priority_windows[1], "initial_to_terminal_change"),
                       fmt_pp(get_stat(share_ids[3], priority_windows[1], "initial_to_terminal_change")),
                       "sec-shares-p1", "sec:shares-p1")
share_c_gfc <- add_claim("C17", "Wage-share alternatives", share_ids[2], priority_windows[4],
                         "initial_to_terminal_change",
                         get_stat(share_ids[2], priority_windows[4], "initial_to_terminal_change"),
                         fmt_pp(get_stat(share_ids[2], priority_windows[4], "initial_to_terminal_change")),
                         "sec-shares-p2", "sec:shares-p2")
share_n_gfc <- add_claim("C18", "Wage-share alternatives", share_ids[4], priority_windows[4],
                         "initial_to_terminal_change",
                         get_stat(share_ids[4], priority_windows[4], "initial_to_terminal_change"),
                         fmt_pp(get_stat(share_ids[4], priority_windows[4], "initial_to_terminal_change")),
                         "sec-shares-p2", "sec:shares-p2")

volcker_out <- add_claim("C19", "Event profiles", level_ids[1], events$event_id[1],
                         "annual_change_1982", get_event(level_ids[1], events$event_id[1], 1982, "annual_change"),
                         fmt_pct(get_event(level_ids[1], events$event_id[1], 1982, "annual_change")),
                         "sec-events-volcker", "sec:events-volcker")
volcker_kap <- add_claim("C20", "Event profiles", "KAPPA_ME_NRC", events$event_id[1],
                         "annual_change_1982", get_event("KAPPA_ME_NRC", events$event_id[1], 1982, "annual_change"),
                         fmt_ratio(get_event("KAPPA_ME_NRC", events$event_id[1], 1982, "annual_change")),
                         "sec-events-volcker", "sec:events-volcker")
gfc_out <- add_claim("C21", "Event profiles", level_ids[1], events$event_id[2],
                     "annual_change_2009", get_event(level_ids[1], events$event_id[2], 2009, "annual_change"),
                     fmt_pct(get_event(level_ids[1], events$event_id[2], 2009, "annual_change")),
                     "sec-events-gfc", "sec:events-gfc")
gfc_share <- add_claim("C22", "Event profiles", share_ids[3], events$event_id[2],
                       "annual_change_2009", get_event(share_ids[3], events$event_id[2], 2009, "annual_change"),
                       fmt_pp(get_event(share_ids[3], events$event_id[2], 2009, "annual_change")),
                       "sec-events-gfc", "sec:events-gfc")
covid_out <- add_claim("C23", "Event profiles", level_ids[1], events$event_id[3],
                       "annual_change_2021", get_event(level_ids[1], events$event_id[3], 2021, "annual_change"),
                       fmt_pct(get_event(level_ids[1], events$event_id[3], 2021, "annual_change")),
                       "sec-events-covid", "sec:events-covid")
covid_share <- add_claim("C24", "Event profiles", share_ids[3], events$event_id[3],
                         "annual_change_2020", get_event(share_ids[3], events$event_id[3], 2020, "annual_change"),
                         fmt_pp(get_event(share_ids[3], events$event_id[3], 2020, "annual_change")),
                         "sec-events-covid", "sec:events-covid")
prose_values <- do.call(rbind, claims)
write_csv(prose_values, file.path(validation_dir, "report_prose_values.csv"))

figure_files <- sort(list.files(fig_dir, pattern = "\\.png$", full.names = FALSE))
figure_titles <- c(
  "Real NFC output level", "Annual NFC output growth",
  "Aggregate productive-capital level", "Annual aggregate-capital growth",
  "Machinery-to-structures composition ratio",
  "Corporate GVA and NVA wage shares", "NFC GVA and NVA wage shares",
  "Corporate versus NFC GVA wage shares", "Corporate versus NFC NVA wage shares",
  "Volcker event profile, 1978-1983", "GFC event profile, 2007-2010",
  "COVID event profile, 2019-2022"
)

md_fig <- function(i, note) c(
  sprintf("![Figure %d. %s](figures/%s)", i, figure_titles[i], figure_files[i]),
  "",
  sprintf("*Figure %d note.* %s", i, note),
  ""
)
common_marker_note <- paste(
  "Historical markers are reference dates, not estimated breakpoints.",
  "Values are descriptive and do not identify a statistical regime."
)

md <- c(
  "# U.S. Output, Productive Capital, and Distribution:",
  "## Descriptive Statistics across Historical Windows",
  "",
  "**Chapter 2 Narrow Regression-Facing Descriptive Report**  ",
  "**Date:** 24 June 2026  ",
  "**Country:** United States  ",
  "**Chapter:** Dissertation Chapter 2  ",
  "**Stage:** S31B  ",
  "**Scope:** Descriptive statistics only  ",
  "**Dataset boundary:** Frozen source-of-truth v1, read only",
  "",
  "## 1. Purpose and descriptive question",
  "",
  paste(
    "This report documents the historical behavior of real NFC output, aggregate productive capital,",
    "capital composition, and four admissible wage-share measures before regression specification.",
    "It asks how these observed series differ across the locked structural, nested, transition, and",
    "event-profile windows. It performs neither model selection nor econometric estimation."
  ),
  "",
  "The paper-facing variable set is",
  "",
  "$$",
  "\\left\\{Y_t^{NFC},K_t^{P},\\kappa_t^{ME/NRC},\\omega_t^{C,GVA},",
  "\\omega_t^{C,NVA},\\omega_t^{NFC,GVA},\\omega_t^{NFC,NVA}\\right\\}.",
  "$$",
  "",
  "## 2. Variable menu and notation",
  "",
  "**Table 1. Narrow variable menu and notation**",
  "",
  md_table(table1),
  "",
  paste(
    "The two provenance inputs for $\\kappa_t^{ME/NRC}$ are `G_ME_GPIM_2017` and",
    "`G_NRC_GPIM_2017`. They are construction inputs, not separate report variables."
  ),
  "",
  "## 3. Accounting boundaries and model openness",
  "",
  paste(
    "The strict available accounting correspondence is",
    "$Y_t^{NFC}\\leftrightarrow\\omega_t^{NFC,GVA}$ because both objects use the NFC sector",
    "boundary and gross value added. The NFC NVA share is a same-sector net-account alternative.",
    "The two corporate shares use the broader corporate boundary."
  ),
  "",
  paste(
    "Accounting correspondence does not bind the later model mapping. Cross-boundary model",
    "specifications are theoretical choices, not accounting identities. All four wage shares remain",
    "eligible and unselected at S31B."
  ),
  "",
  "**Table 6. Accounting correspondence and regression-candidate status**",
  "",
  md_table(table6),
  "",
  "## 4. Historical-window architecture",
  "",
  paste(
    "Structural and nested windows support historical comparison. Bridge windows connect adjacent",
    "configurations. Transition and event-profile windows are descriptive only: they are neither",
    "testing nor estimation samples. Event profiles are displayed year by year and are not treated",
    "as independent statistical regimes."
  ),
  "",
  "**Table 7. Historical-window registry**",
  "",
  md_table(table7),
  "",
  "## 5. NFC real output",
  "",
  "<!-- CLAIM:C01 CLAIM:C02 CLAIM:C03 -->",
  sprintf(
    "During the Fordist core, $Y_t^{NFC}$ rose from %s to %s million 2017-price-equivalent dollars, while mean annual proportional growth was %s.",
    out_f_init, out_f_term, out_f_growth
  ),
  "",
  "<!-- CLAIM:C04 CLAIM:C05 -->",
  sprintf(
    "Mean annual output growth was %s in the post-Fordist pre-GFC window and %s after the GFC. The comparison records a lower post-GFC growth profile without assigning causality or estimating a break.",
    out_pf_growth, out_gfc_growth
  ),
  "",
  "<!-- CLAIM:C06 -->",
  sprintf(
    "The event profile records annual proportional output change of %s in 2020. This observation is a realized annual movement, not an estimated shock coefficient.",
    out_covid
  ),
  "",
  md_fig(1, common_marker_note),
  md_fig(2, common_marker_note),
  "## 6. Productive-capital scale",
  "",
  "<!-- CLAIM:C07 CLAIM:C08 -->",
  sprintf(
    "Mean annual growth of $K_t^P$ was %s during the Fordist core and %s in the post-Fordist pre-GFC window.",
    cap_f_growth, cap_pf_growth
  ),
  "",
  "<!-- CLAIM:C09 CLAIM:C10 -->",
  sprintf(
    "The post-GFC mean annual capital-growth rate was %s, while the 2020 event-profile observation was %s. The aggregate remains a constructed GPIM measure over heterogeneous assets.",
    cap_gfc_growth, cap_covid
  ),
  "",
  md_fig(3, common_marker_note),
  md_fig(4, common_marker_note),
  "## 7. Productive-capital composition",
  "",
  "$$",
  "\\kappa_t^{ME/NRC}=\\frac{K_t^{ME}}{K_t^{NRC}}",
  "=\\frac{\\texttt{G\\_ME\\_GPIM\\_2017}_t}{\\texttt{G\\_NRC\\_GPIM\\_2017}_t}.",
  "$$",
  "",
  paste(
    "The component stocks are heterogeneous. The ratio is therefore used as a directional",
    "composition indicator, not as a machinery share, a structures share, or evidence that",
    "$K_t^P$ is a simple physical sum."
  ),
  "",
  "<!-- CLAIM:C11 CLAIM:C12 -->",
  sprintf(
    "Across the Fordist core, $\\kappa_t^{ME/NRC}$ moved from %s to %s, indicating a movement toward relatively greater machinery-and-equipment intensity over that interval.",
    kap_f_init, kap_f_term
  ),
  "",
  "<!-- CLAIM:C13 CLAIM:C14 -->",
  sprintf(
    "Its initial-to-terminal absolute change was %s in the post-Fordist pre-GFC window and %s after the GFC. These ratio movements are not component shares of total productive capital.",
    kap_pf_change, kap_gfc_change
  ),
  "",
  md_fig(5, common_marker_note),
  "## 8. Wage-share alternatives",
  "",
  paste(
    "The four compensation shares separate two choices: corporate versus NFC sector boundary,",
    "and gross versus net value-added denominator. Levels are reported in percent and annual changes",
    "in percentage points. No share is ranked as econometrically superior."
  ),
  "",
  "<!-- CLAIM:C15 CLAIM:C16 -->",
  sprintf(
    "During the Fordist core, the corporate GVA compensation share changed by %s, while the NFC GVA compensation share changed by %s.",
    share_c_f, share_n_f
  ),
  "",
  "<!-- CLAIM:C17 CLAIM:C18 -->",
  sprintf(
    "After the GFC, the corporate NVA compensation share changed by %s from the first to the last available observation, compared with %s for the NFC NVA share.",
    share_c_gfc, share_n_gfc
  ),
  "",
  md_fig(6, common_marker_note),
  md_fig(7, common_marker_note),
  md_fig(8, common_marker_note),
  md_fig(9, common_marker_note),
  "## 9. Event profiles",
  "",
  "### 9.1 Volcker, 1978-1983",
  "",
  "<!-- CLAIM:C19 CLAIM:C20 -->",
  sprintf(
    "In 1982, annual NFC output growth was %s and the annual absolute change in $\\kappa_t^{ME/NRC}$ was %s. The complete panel below retains every annual observation for all seven variables.",
    volcker_out, volcker_kap
  ),
  "",
  md_fig(10, "The dashed line marks 1979 as a historical reference onset; panels retain observed scales."),
  "### 9.2 GFC, 2007-2010",
  "",
  "<!-- CLAIM:C21 CLAIM:C22 -->",
  sprintf(
    "In 2009, annual NFC output growth was %s and the NFC GVA compensation share changed by %s. These are concurrent descriptive movements.",
    gfc_out, gfc_share
  ),
  "",
  md_fig(11, "The dashed line marks 2008 as a historical reference onset; panels retain observed scales."),
  "### 9.3 COVID, 2019-2022",
  "",
  "<!-- CLAIM:C23 CLAIM:C24 -->",
  sprintf(
    "Annual NFC output growth was %s in 2021, while the NFC GVA compensation share changed by %s in 2020. The short profile does not establish a separate regime.",
    covid_out, covid_share
  ),
  "",
  md_fig(12, "The dashed line marks 2020 as a historical reference onset; panels retain observed scales."),
  "**Table 5. Event-profile annual observations**",
  "",
  md_table(event_display),
  "",
  "## 10. Regression-facing implications",
  "",
  paste(
    "The later candidate menu remains exactly the seven-variable set stated in Section 1.",
    "The descriptive evidence documents scale, growth, composition, sector boundary, and denominator",
    "differences before specification selection. It does not authorize a regression equation, select",
    "a distributive measure, or map an accounting correspondence mechanically into a model."
  ),
  "",
  "**Table 2. Full-sample descriptive summary**",
  "",
  md_table(table2_display),
  "",
  paste(
    "*Table 2 note.* Output and capital levels are millions of constant-price dollars; their changes",
    "are percentages. Wage-share levels are percentages and their changes are percentage points.",
    "Kappa is an observed ratio and its changes are ratio points."
  ),
  "",
  "**Table 3. Structural-window comparison**",
  "",
  md_table(table3_display),
  "",
  paste(
    "*Table 3 note.* The paper-facing table prioritizes six windows. The complete eleven-window",
    "machine-readable table is `tables/supplement_complete_11_window_statistics.csv`."
  ),
  "",
  "**Table 4. Transition-window statistics**",
  "",
  md_table(table4_display),
  "",
  "*Table 4 note.* Every transition row is descriptive eligible, testing ineligible, and estimation ineligible.",
  "",
  "## 11. Limitations",
  "",
  paste(
    "Canonical real corporate GVA remains blocked, so corporate-NFC real-output comparisons are",
    "unavailable. `G_ME_GPIM_2017` and `G_NRC_GPIM_2017` are used only to construct",
    "$\\kappa_t^{ME/NRC}$. The ratio indicates relative composition; it is not a physically additive",
    "share of total capital. Short transition windows are descriptive only, and the post-COVID",
    "configuration contains limited observations."
  ),
  "",
  "## 12. Bounded conclusions",
  "",
  paste(
    "The report establishes three bounded results. First, real NFC output and productive capital",
    "display different average growth profiles across the locked historical windows. Second, the",
    "machinery-to-structures ratio changes materially over time without requiring a physical-additivity",
    "claim. Third, sector boundary and gross-versus-net denominator choices produce distinct wage-share",
    "paths, leaving all four distributive candidates open for later specification work."
  ),
  "",
  paste(
    "These findings are descriptive. They do not establish causality, statistical significance,",
    "estimated structural breaks, cointegration, model superiority, or parameter instability."
  ),
  "",
  "## Appendix A. Transformation rules",
  "",
  "$$g_{X,t}=100\\left(\\frac{X_t}{X_{t-1}}-1\\right),\\qquad X\\in\\{Y^{NFC},K^P\\}.$$",
  "",
  "$$\\Delta\\kappa_t^{ME/NRC}=\\kappa_t^{ME/NRC}-\\kappa_{t-1}^{ME/NRC}.$$",
  "",
  "$$\\Delta_{pp}\\omega_t^{s,a}=100\\left(\\omega_t^{s,a}-\\omega_{t-1}^{s,a}\\right).$$",
  "",
  "No logarithmic transformation is reported.",
  "",
  "## Appendix B. Reproducibility",
  "",
  "The report is generated by `codes/US_S31B_build_narrow_descriptive_report.R` from read-only validated S31B and authorized upstream inputs. Report tables, figures, prose values, parity checks, and compilation logs are stored beside the report."
)
md_path <- file.path(report_dir, "report_dstat_2026-06-24.md")
write_text(md, md_path)

tex_fig <- function(i, note) c(
  "\\begin{figure}[H]",
  "\\centering",
  sprintf("\\includegraphics[width=0.94\\textwidth]{%s}", figure_files[i]),
  sprintf("\\caption{%s}", tex_escape(figure_titles[i])),
  sprintf("\\label{fig:%02d}", i),
  sprintf("\\par\\smallskip\\footnotesize\\textit{Note:} %s", tex_escape(note)),
  "\\end{figure}"
)

table1_tex <- table1
names(table1_tex) <- c("Family", "Label", "Notation", "Repository ID", "Boundary", "Later role")
table6_tex <- table6
names(table6_tex) <- c("Variable", "Boundary", "Denominator", "Strict correspondence", "Eligibility", "Status")
table7_tex <- table7
names(table7_tex) <- c("Window", "Type", "Start", "End", "Descriptive", "Testing", "Estimation")
names(table2_display) <- c("Variable", "Coverage", "N", "Initial", "Terminal", "Mean", "SD",
                           "Initial-terminal change", "Mean annual change")
names(table3_display) <- c("Variable", "Window", "N", "Initial", "Terminal", "Mean", "Change",
                           "Mean annual change", "Volatility")
names(table4_display) <- c("Variable", "Window", "N", "Initial", "Terminal", "Change",
                           "Mean annual change", "Testing", "Estimation")

tex <- c(
  "\\documentclass[11pt]{article}",
  "\\usepackage[T1]{fontenc}",
  "\\usepackage[utf8]{inputenc}",
  "\\usepackage[margin=0.85in]{geometry}",
  "\\usepackage{booktabs,longtable,array,graphicx,float,caption,amsmath,amssymb,siunitx,microtype,setspace,enumitem,hyperref,xcolor,pdflscape}",
  "\\graphicspath{{figures/}}",
  "\\hypersetup{colorlinks=true,linkcolor=blue!45!black,urlcolor=blue!45!black}",
  "\\setstretch{1.08}",
  "\\setlength{\\emergencystretch}{3em}",
  "\\setlength{\\LTpre}{4pt}",
  "\\setlength{\\LTpost}{8pt}",
  "\\newcommand{\\code}[1]{\\texttt{\\detokenize{#1}}}",
  "\\title{U.S. Output, Productive Capital, and Distribution:\\\\Descriptive Statistics across Historical Windows\\\\[0.5em]\\large Chapter 2 Narrow Regression-Facing Descriptive Report}",
  "\\author{}",
  "\\date{24 June 2026}",
  "\\begin{document}",
  "\\maketitle",
  "\\begin{center}\\small United States $\\mid$ Dissertation Chapter 2 $\\mid$ Stage S31B\\\\Descriptive statistics only $\\mid$ Frozen source-of-truth v1, read only\\end{center}",
  "\\tableofcontents",
  "\\clearpage",
  "\\section{Purpose and descriptive question}",
  paste(
    "This report documents the historical behavior of real NFC output, aggregate productive capital,",
    "capital composition, and four admissible wage-share measures before regression specification.",
    "It asks how these observed series differ across the locked structural, nested, transition, and",
    "event-profile windows. It performs neither model selection nor econometric estimation."
  ),
  "\\[\\left\\{Y_t^{NFC},K_t^{P},\\kappa_t^{ME/NRC},\\omega_t^{C,GVA},\\omega_t^{C,NVA},\\omega_t^{NFC,GVA},\\omega_t^{NFC,NVA}\\right\\}.\\]",
  "\\section{Variable menu and notation}",
  tex_table(table1_tex, "Narrow variable menu and notation", "tab:variables",
            c("p{0.08\\linewidth}", "p{0.20\\linewidth}", "p{0.09\\linewidth}",
              "p{0.17\\linewidth}", "p{0.14\\linewidth}", "p{0.16\\linewidth}"),
            landscape = TRUE, font = "\\tiny", table_number = 1),
  paste(
    "The two provenance inputs for $\\kappa_t^{ME/NRC}$ are",
    "\\code{G_ME_GPIM_2017} and \\code{G_NRC_GPIM_2017}.",
    "They are construction inputs, not separate report variables."
  ),
  "\\section{Accounting boundaries and model openness}",
  paste(
    "The strict available accounting correspondence is",
    "$Y_t^{NFC}\\leftrightarrow\\omega_t^{NFC,GVA}$ because both objects use the NFC sector",
    "boundary and gross value added. The NFC NVA share is a same-sector net-account alternative.",
    "The two corporate shares use the broader corporate boundary."
  ),
  paste(
    "Accounting correspondence does not bind the later model mapping. Cross-boundary model",
    "specifications are theoretical choices, not accounting identities. All four wage shares remain",
    "eligible and unselected at S31B."
  ),
  tex_table(table6_tex, "Accounting correspondence and regression-candidate status",
            "tab:accounting", c("p{0.17\\linewidth}", "p{0.10\\linewidth}", "p{0.11\\linewidth}",
                                "p{0.17\\linewidth}", "p{0.09\\linewidth}", "p{0.16\\linewidth}"),
            landscape = TRUE, font = "\\tiny", table_number = 6),
  "\\section{Historical-window architecture}",
  paste(
    "Structural and nested windows support historical comparison. Bridge windows connect adjacent",
    "configurations. Transition and event-profile windows are descriptive only: they are neither",
    "testing nor estimation samples. Event profiles are displayed year by year and are not treated",
    "as independent statistical regimes."
  ),
  tex_table(table7_tex, "Historical-window registry", "tab:windows",
            c("p{0.23\\linewidth}", "p{0.10\\linewidth}", "r", "r", "p{0.09\\linewidth}",
              "p{0.09\\linewidth}", "p{0.09\\linewidth}"), font = "\\tiny", table_number = 7),
  "\\section{NFC real output}\\label{sec:output}",
  "% CLAIM:C01 CLAIM:C02 CLAIM:C03 sec:output-p1",
  sprintf(
    "During the Fordist core, $Y_t^{NFC}$ rose from %s to %s million 2017-price-equivalent dollars, while mean annual proportional growth was %s.",
    tex_escape(out_f_init), tex_escape(out_f_term), tex_escape(out_f_growth)
  ),
  "% CLAIM:C04 CLAIM:C05 sec:output-p2",
  sprintf(
    "Mean annual output growth was %s in the post-Fordist pre-GFC window and %s after the GFC. The comparison records a lower post-GFC growth profile without assigning causality or estimating a break.",
    tex_escape(out_pf_growth), tex_escape(out_gfc_growth)
  ),
  "% CLAIM:C06 sec:output-p3",
  sprintf(
    "The event profile records annual proportional output change of %s in 2020. This observation is a realized annual movement, not an estimated shock coefficient.",
    tex_escape(out_covid)
  ),
  tex_fig(1, common_marker_note),
  tex_fig(2, common_marker_note),
  "\\section{Productive-capital scale}\\label{sec:capital}",
  "% CLAIM:C07 CLAIM:C08 sec:capital-p1",
  sprintf(
    "Mean annual growth of $K_t^P$ was %s during the Fordist core and %s in the post-Fordist pre-GFC window.",
    tex_escape(cap_f_growth), tex_escape(cap_pf_growth)
  ),
  "% CLAIM:C09 CLAIM:C10 sec:capital-p2",
  sprintf(
    "The post-GFC mean annual capital-growth rate was %s, while the 2020 event-profile observation was %s. The aggregate remains a constructed GPIM measure over heterogeneous assets.",
    tex_escape(cap_gfc_growth), tex_escape(cap_covid)
  ),
  tex_fig(3, common_marker_note),
  tex_fig(4, common_marker_note),
  "\\section{Productive-capital composition}\\label{sec:kappa}",
  "\\begin{equation}\\kappa_t^{ME/NRC}=\\frac{K_t^{ME}}{K_t^{NRC}}=\\frac{\\code{G_ME_GPIM_2017}_t}{\\code{G_NRC_GPIM_2017}_t}.\\label{eq:kappa}\\end{equation}",
  paste(
    "The component stocks are heterogeneous. The ratio is therefore used as a directional",
    "composition indicator, not as a machinery share, a structures share, or evidence that",
    "$K_t^P$ is a simple physical sum."
  ),
  "% CLAIM:C11 CLAIM:C12 sec:kappa-p1",
  sprintf(
    "Across the Fordist core, $\\kappa_t^{ME/NRC}$ moved from %s to %s, indicating a movement toward relatively greater machinery-and-equipment intensity over that interval.",
    tex_escape(kap_f_init), tex_escape(kap_f_term)
  ),
  "% CLAIM:C13 CLAIM:C14 sec:kappa-p2",
  sprintf(
    "Its initial-to-terminal absolute change was %s in the post-Fordist pre-GFC window and %s after the GFC. These ratio movements are not component shares of total productive capital.",
    tex_escape(kap_pf_change), tex_escape(kap_gfc_change)
  ),
  tex_fig(5, common_marker_note),
  "\\section{Wage-share alternatives}\\label{sec:shares}",
  paste(
    "The four compensation shares separate two choices: corporate versus NFC sector boundary,",
    "and gross versus net value-added denominator. Levels are reported in percent and annual changes",
    "in percentage points. No share is ranked as econometrically superior."
  ),
  "% CLAIM:C15 CLAIM:C16 sec:shares-p1",
  sprintf(
    "During the Fordist core, the corporate GVA compensation share changed by %s, while the NFC GVA compensation share changed by %s.",
    tex_escape(share_c_f), tex_escape(share_n_f)
  ),
  "% CLAIM:C17 CLAIM:C18 sec:shares-p2",
  sprintf(
    "After the GFC, the corporate NVA compensation share changed by %s from the first to the last available observation, compared with %s for the NFC NVA share.",
    tex_escape(share_c_gfc), tex_escape(share_n_gfc)
  ),
  tex_fig(6, common_marker_note),
  tex_fig(7, common_marker_note),
  tex_fig(8, common_marker_note),
  tex_fig(9, common_marker_note),
  "\\section{Event profiles}\\label{sec:events}",
  "\\subsection{Volcker, 1978--1983}",
  "% CLAIM:C19 CLAIM:C20 sec:events-volcker",
  sprintf(
    "In 1982, annual NFC output growth was %s and the annual absolute change in $\\kappa_t^{ME/NRC}$ was %s. The complete panel below retains every annual observation for all seven variables.",
    tex_escape(volcker_out), tex_escape(volcker_kap)
  ),
  tex_fig(10, "The dashed line marks 1979 as a historical reference onset; panels retain observed scales."),
  "\\subsection{GFC, 2007--2010}",
  "% CLAIM:C21 CLAIM:C22 sec:events-gfc",
  sprintf(
    "In 2009, annual NFC output growth was %s and the NFC GVA compensation share changed by %s. These are concurrent descriptive movements.",
    tex_escape(gfc_out), tex_escape(gfc_share)
  ),
  tex_fig(11, "The dashed line marks 2008 as a historical reference onset; panels retain observed scales."),
  "\\subsection{COVID, 2019--2022}",
  "% CLAIM:C23 CLAIM:C24 sec:events-covid",
  sprintf(
    "Annual NFC output growth was %s in 2021, while the NFC GVA compensation share changed by %s in 2020. The short profile does not establish a separate regime.",
    tex_escape(covid_out), tex_escape(covid_share)
  ),
  tex_fig(12, "The dashed line marks 2020 as a historical reference onset; panels retain observed scales."),
  tex_table(event_display, "Event-profile annual observations", "tab:events",
            c("p{0.16\\linewidth}", "r", rep("r", 7)), landscape = TRUE, font = "\\tiny",
            table_number = 5),
  "\\section{Regression-facing implications}",
  paste(
    "The later candidate menu remains exactly the seven-variable set stated in Section 1.",
    "The descriptive evidence documents scale, growth, composition, sector boundary, and denominator",
    "differences before specification selection. It does not authorize a regression equation, select",
    "a distributive measure, or map an accounting correspondence mechanically into a model."
  ),
  "\\noindent\\footnotesize Tables 2--4 report output and capital levels in millions of constant-price dollars and their changes in percentages. Wage-share levels are percentages and their changes are percentage points. Kappa is an observed ratio and its changes are ratio points. All transition rows are descriptive eligible, testing ineligible, and estimation ineligible.\\normalsize",
  tex_table(table2_display, "Full-sample descriptive summary", "tab:fullsample",
            c("p{0.14\\linewidth}", "p{0.09\\linewidth}", "r", rep("r", 6)),
            landscape = TRUE, font = "\\tiny", table_number = 2),
  tex_table(table3_display, "Structural-window comparison", "tab:structural",
            c("p{0.12\\linewidth}", "p{0.19\\linewidth}", "r", rep("r", 6)),
            landscape = TRUE, font = "\\tiny", table_number = 3),
  tex_table(table4_display, "Transition-window statistics", "tab:transitions",
            c("p{0.12\\linewidth}", "p{0.19\\linewidth}", "r", rep("r", 4), "l", "l"),
            landscape = TRUE, font = "\\tiny", table_number = 4),
  "\\section{Limitations}",
  paste(
    "Canonical real corporate GVA remains blocked, so corporate--NFC real-output comparisons are",
    "unavailable. \\code{G_ME_GPIM_2017} and \\code{G_NRC_GPIM_2017} are used only to construct",
    "$\\kappa_t^{ME/NRC}$. The ratio indicates relative composition; it is not a physically additive",
    "share of total capital. Short transition windows are descriptive only, and the post-COVID",
    "configuration contains limited observations."
  ),
  "\\section{Bounded conclusions}",
  paste(
    "The report establishes three bounded results. First, real NFC output and productive capital",
    "display different average growth profiles across the locked historical windows. Second, the",
    "machinery-to-structures ratio changes materially over time without requiring a physical-additivity",
    "claim. Third, sector boundary and gross-versus-net denominator choices produce distinct wage-share",
    "paths, leaving all four distributive candidates open for later specification work."
  ),
  paste(
    "These findings are descriptive. They do not establish causality, statistical significance,",
    "estimated structural breaks, cointegration, model superiority, or parameter instability."
  ),
  "\\appendix",
  "\\section{Transformation rules}",
  "\\begin{equation}g_{X,t}=100\\left(\\frac{X_t}{X_{t-1}}-1\\right),\\qquad X\\in\\{Y^{NFC},K^P\\}.\\end{equation}",
  "\\begin{equation}\\Delta\\kappa_t^{ME/NRC}=\\kappa_t^{ME/NRC}-\\kappa_{t-1}^{ME/NRC}.\\end{equation}",
  "\\begin{equation}\\Delta_{pp}\\omega_t^{s,a}=100\\left(\\omega_t^{s,a}-\\omega_{t-1}^{s,a}\\right).\\end{equation}",
  "No logarithmic transformation is reported.",
  "\\section{Reproducibility}",
  "The report is generated by \\code{codes/US_S31B_build_narrow_descriptive_report.R} from read-only validated S31B and authorized upstream inputs. Report tables, figures, prose values, parity checks, and compilation logs are stored beside the report.",
  "\\end{document}"
)
tex_path <- file.path(report_dir, "report_dstat_2026-06-24.tex")
write_text(tex, tex_path)

md_text <- paste(md, collapse = "\n")
tex_text <- paste(tex, collapse = "\n")
parity <- data.frame(
  check_id = character(), check_name = character(), status = character(), evidence = character(),
  stringsAsFactors = FALSE
)
add_parity <- function(id, name, ok, evidence) {
  parity <<- rbind(parity, data.frame(check_id = id, check_name = name,
                                      status = ifelse(ok, "PASS", "FAIL"),
                                      evidence = evidence, stringsAsFactors = FALSE))
}
for (id in report_ids) {
  add_parity(paste0("PAR_VAR_", match(id, report_ids)), paste0("variable_", id),
             grepl(id, md_text, fixed = TRUE) &&
               grepl(tex_escape(id), tex_text, fixed = TRUE), id)
}
for (id in prose_values$claim_id) {
  add_parity(paste0("PAR_CLAIM_", id), paste0("claim_", id),
             grepl(paste0("CLAIM:", id), md_text, fixed = TRUE) &&
               grepl(paste0("CLAIM:", id), tex_text, fixed = TRUE),
             prose_values$formatted_value[prose_values$claim_id == id])
}
section_names <- c("Purpose and descriptive question", "Variable menu and notation",
                   "Accounting boundaries and model openness", "Historical-window architecture",
                   "NFC real output", "Productive-capital scale", "Productive-capital composition",
                   "Wage-share alternatives", "Event profiles", "Regression-facing implications",
                   "Limitations", "Bounded conclusions")
for (s in section_names) {
  add_parity(paste0("PAR_SEC_", which(section_names == s)), paste0("section_", s),
             grepl(s, md_text, fixed = TRUE) && grepl(s, tex_text, fixed = TRUE), s)
}
for (i in seq_along(figure_titles)) {
  add_parity(paste0("PAR_FIG_", i), paste0("figure_", i),
             grepl(figure_titles[i], md_text, fixed = TRUE) &&
               grepl(figure_titles[i], tex_text, fixed = TRUE), figure_titles[i])
}
table_titles <- c("Narrow variable menu and notation", "Full-sample descriptive summary",
                  "Structural-window comparison", "Transition-window statistics",
                  "Event-profile annual observations",
                  "Accounting correspondence and regression-candidate status",
                  "Historical-window registry")
for (i in seq_along(table_titles)) {
  add_parity(paste0("PAR_TAB_", i), paste0("table_", i),
             grepl(table_titles[i], md_text, fixed = TRUE) &&
               grepl(table_titles[i], tex_text, fixed = TRUE), table_titles[i])
}
add_parity("PAR_BLOCKED", "blocked_corporate_output",
           grepl("Canonical real corporate GVA remains blocked", md_text, fixed = TRUE) &&
             grepl("Canonical real corporate GVA remains blocked", tex_text, fixed = TRUE),
           "Y_REAL_CORP_GVA_BASELINE")
write_csv(parity, file.path(validation_dir, "report_md_tex_parity_checks.csv"))
parity_fail <- sum(parity$status == "FAIL")
write_text(c(
  "# Markdown-LaTeX parity summary",
  "",
  sprintf("- Checks: %d", nrow(parity)),
  sprintf("- PASS: %d", sum(parity$status == "PASS")),
  sprintf("- FAIL: %d", parity_fail),
  sprintf("- Result: %s", ifelse(parity_fail == 0, "PASS", "FAIL"))
), file.path(validation_dir, "report_md_tex_parity_summary.md"))

readme <- c(
  "# S31B narrow descriptive report",
  "",
  "## Purpose",
  "",
  "Regression-facing descriptive documentation for seven U.S. Chapter 2 variables across the locked S31B historical windows.",
  "",
  "## Analytical scope",
  "",
  "Descriptive statistics only. The report does not select a model, estimate parameters, or modify the frozen dataset.",
  "",
  "## Sources consumed",
  "",
  "- Frozen source-of-truth v1 long file (read only).",
  "- Completed S31B registry, structural, transition, event, accounting, provenance, and validation outputs.",
  "- Authorized S29E `G_ME_GPIM_2017` and `G_NRC_GPIM_2017` inputs for kappa construction only.",
  "",
  "## Build",
  "",
  "- Script: `codes/US_S31B_build_narrow_descriptive_report.R`",
  "- Order: extract and validate data; write tables and figures; write Markdown; write LaTeX mirror; run parity checks; compile PDF.",
  "- Command from the worktree root: `Rscript codes/US_S31B_build_narrow_descriptive_report.R`",
  "- LaTeX command from this folder: `latexmk -pdf -interaction=nonstopmode -halt-on-error report_dstat_2026-06-24.tex`",
  "",
  "## Blocked object",
  "",
  "Canonical real corporate GVA (`Y_REAL_CORP_GVA_BASELINE`) remains blocked and is not replaced.",
  "",
  "## Construction date",
  "",
  "24 June 2026"
)
write_text(readme, file.path(report_dir, "README.md"))

oldwd <- getwd()
setwd(report_dir)
compile_output <- tryCatch(
  system2("latexmk", c("-pdf", "-interaction=nonstopmode", "-halt-on-error",
                       "report_dstat_2026-06-24.tex"), stdout = TRUE, stderr = TRUE),
  error = function(e) structure(conditionMessage(e), status = 1L)
)
compile_status <- attr(compile_output, "status")
if (is.null(compile_status)) compile_status <- 0L
setwd(oldwd)
write_text(c(
  "Command: latexmk -pdf -interaction=nonstopmode -halt-on-error report_dstat_2026-06-24.tex",
  sprintf("Exit status: %d", compile_status),
  "",
  compile_output
), file.path(validation_dir, "latex_compilation_log.txt"))

pdf_path <- file.path(report_dir, "report_dstat_2026-06-24.pdf")
log_text <- paste(compile_output, collapse = "\n")
broad_hash_after <- hash_tree(broad_dir)
upstream_unchanged <- identical(broad_hash_before, broad_hash_after)
tracked_diff <- trimws(paste(system2("git", c("diff", "--name-only"), stdout = TRUE, stderr = TRUE),
                             collapse = "\n"))

validation <- data.frame(
  check_id = character(), check_name = character(), status = character(), evidence = character(),
  stringsAsFactors = FALSE
)
add_check <- function(id, name, ok, evidence) {
  validation <<- rbind(validation, data.frame(
    check_id = id, check_name = name, status = ifelse(ok, "PASS", "FAIL"),
    evidence = as.character(evidence), stringsAsFactors = FALSE
  ))
}
add_check("RPT_01", "exactly_seven_report_variables",
          identical(meta$variable_id, report_ids), paste(meta$variable_id, collapse = "; "))
add_check("RPT_02", "no_extra_paper_facing_variables", nrow(meta) == 7, nrow(meta))
add_check("RPT_03", "components_only_kappa_provenance",
          !any(component_ids %in% meta$variable_id), paste(component_ids, collapse = "; "))
aligned <- merge(me, nrc, by = "year", suffixes = c("_me", "_nrc"))
calc <- aligned$value_me / aligned$value_nrc
observed <- series_list[["KAPPA_ME_NRC"]]$value
add_check("RPT_04", "kappa_exact_ratio", length(calc) == length(observed) &&
            max(abs(calc - observed), na.rm = TRUE) < 1e-12, max(abs(calc - observed), na.rm = TRUE))
add_check("RPT_05", "no_logarithmic_report_columns",
          !any(grepl("log", names(structural_stats), ignore.case = TRUE)), paste(names(structural_stats), collapse = "; "))
add_check("RPT_06", "no_component_share_constructed",
          !any(grepl("share.*capital|capital.*share", names(series), ignore.case = TRUE)), paste(names(series), collapse = "; "))
add_check("RPT_07", "no_physical_additivity_assertion",
          !grepl("K_TOT = K_ME + K_NRC", md_text, fixed = TRUE) &&
            !grepl("K_TOT = K_ME + K_NRC", tex_text, fixed = TRUE), "no asserted identity")
add_check("RPT_08", "all_four_wage_shares_present",
          all(share_ids %in% unique(series$variable_id)), paste(share_ids, collapse = "; "))
share_change_test <- series[series$variable_id %in% share_ids & !is.na(series$annual_change), ]
add_check("RPT_09", "share_changes_percentage_points",
          all(share_change_test$change_unit == "percentage points"), unique(share_change_test$change_unit))
level_change_test <- series[series$variable_id %in% level_ids & !is.na(series$annual_change), ]
level_recalc <- 100 * (level_change_test$value / level_change_test$previous_value - 1)
add_check("RPT_10", "level_growth_proportional_change",
          max(abs(level_change_test$annual_change - level_recalc), na.rm = TRUE) < 1e-12,
          max(abs(level_change_test$annual_change - level_recalc), na.rm = TRUE))
add_check("RPT_11", "locked_structural_windows",
          identical(unique(structural_stats$window_id), windows$window_id),
          paste(unique(structural_stats$window_id), collapse = "; "))
add_check("RPT_12", "transition_windows_nonestimable",
          all(transition_stats$testing_eligible == "no" & transition_stats$estimation_eligible == "no"),
          paste(unique(transition_stats$window_id), collapse = "; "))
event_year_check <- all(vapply(seq_len(nrow(events)), function(i) {
  identical(sort(unique(event_values$year[event_values$event_id == events$event_id[i]])),
            events$start_year[i]:events$end_year[i])
}, logical(1)))
add_check("RPT_13", "event_profile_years_correct", event_year_check,
          paste(events$event_id, collapse = "; "))
add_check("RPT_14", "all_prose_claims_ledgered", nrow(prose_values) == 24,
          paste(prose_values$claim_id, collapse = "; "))
add_check("RPT_15", "markdown_latex_numeric_parity", parity_fail == 0,
          sprintf("%d parity failures", parity_fail))
add_check("RPT_16", "markdown_latex_section_parity",
          all(parity$status[grepl("^PAR_SEC_", parity$check_id)] == "PASS"),
          paste(section_names, collapse = "; "))
add_check("RPT_17", "all_report_figures_exist",
          length(figure_files) == 12 && all(file.exists(file.path(fig_dir, figure_files))),
          paste(figure_files, collapse = "; "))
required_tables <- sprintf("table_%02d", 1:7)
table_files <- sort(list.files(table_dir, pattern = "^table_.*\\.csv$", full.names = FALSE))
add_check("RPT_18", "all_report_tables_exist", length(table_files) == 7,
          paste(table_files, collapse = "; "))
add_check("RPT_19", "latex_compiles_successfully", compile_status == 0,
          sprintf("latexmk exit status %d", compile_status))
add_check("RPT_20", "pdf_exists_nonempty", file.exists(pdf_path) && file.info(pdf_path)$size > 0,
          ifelse(file.exists(pdf_path), file.info(pdf_path)$size, 0))
add_check("RPT_21", "no_undefined_latex_references",
          !grepl("undefined references|undefined citation|Citation.*undefined", log_text, ignore.case = TRUE),
          "latexmk output scanned")
add_check("RPT_22", "no_missing_figures",
          !grepl("File .* not found|Package pdftex.def Error", log_text, ignore.case = TRUE),
          "latexmk output scanned")
add_check("RPT_23", "upstream_s31b_outputs_unchanged", upstream_unchanged,
          sprintf("%d broad-pass files hashed", nrow(broad_hash_before)))
add_check("RPT_24", "no_tracked_files_modified", identical(tracked_diff, ""),
          ifelse(identical(tracked_diff, ""), "git diff empty", tracked_diff))
add_check("RPT_25", "blocked_corporate_output_documented",
          grepl("Canonical real corporate GVA remains blocked", md_text, fixed = TRUE) &&
            grepl("Canonical real corporate GVA remains blocked", tex_text, fixed = TRUE),
          "Y_REAL_CORP_GVA_BASELINE")
add_check("RPT_26", "broad_s31b_validation_consumed",
          all(c("PASS", "BLOCKED_DOCUMENTED") %in% unique(broad_validation$status)),
          paste(table(broad_validation$status), collapse = "; "))
add_check("RPT_27", "no_overfull_latex_boxes",
          !grepl("Overfull \\\\hbox|Overfull \\\\vbox", log_text),
          "latexmk output scanned")
write_csv(validation, file.path(validation_dir, "report_validation_checks.csv"))

fail_count <- sum(validation$status == "FAIL")
pass_count <- sum(validation$status == "PASS")
decision <- if (fail_count == 0) "AUTHORIZE_NARROW_DESCRIPTIVE_REPORT" else if (compile_status != 0) {
  "REPORT_SOURCES_COMPLETE_PDF_COMPILATION_BLOCKED"
} else if (parity_fail > 0) {
  "REPORT_PARITY_REQUIRES_CORRECTION"
} else {
  "REPORT_VALIDATION_REQUIRES_CORRECTION"
}
write_text(c(
  "# Narrow report validation summary",
  "",
  sprintf("- PASS: %d", pass_count),
  sprintf("- FAIL: %d", fail_count),
  sprintf("- Tables: %d", length(table_files)),
  sprintf("- Figures: %d", length(figure_files)),
  sprintf("- Quantitative prose claims: %d", nrow(prose_values)),
  sprintf("- Markdown-LaTeX parity: %s", ifelse(parity_fail == 0, "PASS", "FAIL")),
  sprintf("- LaTeX compilation: %s", ifelse(compile_status == 0, "PASS", "FAIL")),
  sprintf("- Decision: `%s`", decision)
), file.path(validation_dir, "report_validation_summary.md"))

oldwd <- getwd()
setwd(report_dir)
system2("latexmk", c("-c", "report_dstat_2026-06-24.tex"),
        stdout = FALSE, stderr = FALSE, wait = TRUE)
setwd(oldwd)

cat(sprintf(
  paste0("tables: %d\nfigures: %d\nquantitative prose claims: %d\n",
         "parity: %s\nlatex: %s\nvalidation: PASS=%d FAIL=%d\ndecision: %s\n"),
  length(table_files), length(figure_files), nrow(prose_values),
  ifelse(parity_fail == 0, "PASS", "FAIL"),
  ifelse(compile_status == 0, "PASS", "FAIL"),
  pass_count, fail_count, decision
))
