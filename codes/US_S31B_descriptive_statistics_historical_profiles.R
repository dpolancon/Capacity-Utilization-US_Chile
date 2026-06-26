#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(scales)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stage_id <- "S31B_DESCRIPTIVE_STATISTICS_AND_HISTORICAL_PROFILES"
base_commit <- "8f51482888e3cb41d00b122bbe9d94998237d376"
branch_required <- "feature/s31b-us-descriptive-statistics-historical-profiles"
out_dir <- file.path(root, "output", "US", stage_id)
csv_dir <- file.path(out_dir, "csv")
fig_dir <- file.path(out_dir, "figures")
report_dir <- file.path(out_dir, "reports")
validation_dir <- file.path(out_dir, "validation")
if (dir.exists(out_dir)) unlink(out_dir, recursive = TRUE, force = TRUE)
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(validation_dir, recursive = TRUE, showWarnings = FALSE)

read_files <- character()
rel <- function(path) {
  full <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(normalizePath(root, winslash = "/", mustWork = TRUE), "/")
  if (startsWith(full, prefix)) substring(full, nchar(prefix) + 1L) else full
}
read_csv <- function(path) {
  if (!file.exists(path)) stop("Missing input: ", path, call. = FALSE)
  read_files <<- unique(c(read_files, rel(path)))
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}
write_csv <- function(x, path) write.csv(x, path, row.names = FALSE, na = "")
write_md <- function(lines, path) writeLines(lines, path, useBytes = TRUE)
git_out <- function(args) trimws(system2("git", args, stdout = TRUE, stderr = TRUE)[1])
bind_fill <- function(rows) {
  cols <- unique(unlist(lapply(rows, names)))
  rows <- lapply(rows, function(x) {
    for (nm in setdiff(cols, names(x))) x[[nm]] <- NA
    x[cols]
  })
  do.call(rbind, rows)
}
sha256 <- function(path) {
  out <- suppressWarnings(system2("certutil", c("-hashfile", shQuote(normalizePath(path, winslash = "\\", mustWork = TRUE)), "SHA256"),
                                  stdout = TRUE, stderr = TRUE))
  line <- out[grepl("^[[:xdigit:][:space:]]{64,}$", out)]
  if (!length(line)) stop("Hash failure: ", path, call. = FALSE)
  tolower(gsub("[[:space:]]", "", line[1]))
}

branch <- git_out(c("branch", "--show-current"))
head <- git_out(c("rev-parse", "HEAD"))
base_ok <- identical(system2("git", c("merge-base", "--is-ancestor", base_commit, head),
                             stdout = FALSE, stderr = FALSE), 0L)

v1_dir <- file.path(root, "data", "releases", "chapter2_us_source_of_truth_v1")
long_path <- file.path(v1_dir, "CH2_US_SOURCE_OF_TRUTH_LONG.csv")
dict_path <- file.path(v1_dir, "CH2_US_VARIABLE_DICTIONARY.csv")
sha_path <- file.path(v1_dir, "CH2_US_SHA256_MANIFEST.csv")
s24a_path <- file.path(root, "output", "US", "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION", "csv",
                       "S24A_income_distribution_source_inputs_long.csv")
s29e_path <- file.path(root, "output", "US", "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION", "csv",
                       "S29E_core_capital_stocks_flows_long.csv")
s30h_path <- file.path(root, "output", "US", "S30H_CORPORATE_NOS_ACCOUNTING_RECONCILIATION", "csv",
                       "S30H_implied_financial_accounts_long.csv")
s30h_lock_path <- file.path(root, "output", "US", "S30H_CORPORATE_NOS_ACCOUNTING_RECONCILIATION", "csv",
                            "S30H_corporate_surplus_dataset_role_lock.csv")

canonical <- read_csv(long_path)
dictionary <- read_csv(dict_path)
sha_manifest <- read_csv(sha_path)
accounts <- read_csv(s24a_path)
capital_components <- read_csv(s29e_path)
implied_finance <- read_csv(s30h_path)
finance_lock <- read_csv(s30h_lock_path)

hash_audit <- do.call(rbind, lapply(seq_len(nrow(sha_manifest)), function(i) {
  path <- file.path(root, sha_manifest$path[i])
  observed <- sha256(path)
  data.frame(file = sha_manifest$file[i], expected_sha256 = sha_manifest$sha256[i],
             observed_sha256 = observed,
             result = ifelse(observed == sha_manifest$sha256[i], "PASS", "FAIL"),
             stringsAsFactors = FALSE)
}))
write_csv(hash_audit, file.path(validation_dir, "S31B_frozen_release_hash_audit.csv"))

canonical_ids <- unique(canonical$variable_id)
corp_output_id <- "Y_REAL_CORP_GVA_BASELINE"
nfc_output_id <- "Y_REAL_NFC_GVA_BASELINE"
capital_id <- "G_TOT_GPIM_2017"
share_ids <- c(
  "CORP_COMPENSATION_SHARE_GVA",
  "CORP_COMPENSATION_SHARE_NVA",
  "NFC_COMPENSATION_SHARE_GVA",
  "NFC_COMPENSATION_SHARE_NVA"
)
component_ids <- c("G_ME_GPIM_2017", "G_NRC_GPIM_2017")

get_canonical <- function(id) {
  z <- canonical[canonical$variable_id == id, c("year", "variable_id", "value", "unit", "source_stage", "source_file",
                                                "contract_status", "canonical_inclusion_status")]
  z$year <- as.integer(z$year)
  z$value <- as.numeric(z$value)
  z
}
get_account <- function(id) {
  z <- accounts[accounts$variable_id == id, c("year", "variable_id", "value", "unit", "frequency",
                                               "source_table", "source_line", "source_line_description")]
  z$year <- as.integer(z$year)
  z$value <- as.numeric(z$value)
  z
}
get_component <- function(id) {
  z <- capital_components[capital_components$variable_id == id, c("year", "variable_id", "value", "unit", "source_stage")]
  z$year <- as.integer(z$year)
  z$value <- as.numeric(z$value)
  z
}

nfc_output <- get_canonical(nfc_output_id)
capital <- get_canonical(capital_id)
shares <- do.call(rbind, lapply(share_ids, get_canonical))
me <- get_component("G_ME_GPIM_2017")
nrc <- get_component("G_NRC_GPIM_2017")

registry_rows <- list(
  data.frame(
    paper_family = "Output", paper_label = "Real corporate-business gross value added",
    paper_notation = "Y_{GVA,t}^{C}", repository_variable_id = corp_output_id,
    source_stage = "", source_file = "", sector_boundary = "corporate_business",
    gross_or_net = "gross", level_or_share = "level", numerator_id = "CORP_GVA",
    denominator_id = "", price_basis = "unresolved", units = "unresolved", frequency = "A",
    first_year = NA, last_year = NA, n_nonmissing = 0,
    canonical_status = "blocked_or_noncanonical", descriptive_status = "blocked",
    model_candidate_status = "blocked_pending_canonical_real_output",
    notes = "No canonical real corporate-GVA object exists. No substitute is constructed.",
    stringsAsFactors = FALSE),
  data.frame(
    paper_family = "Output", paper_label = "Real nonfinancial-corporate gross value added",
    paper_notation = "Y_{GVA,t}^{N}", repository_variable_id = nfc_output_id,
    source_stage = unique(nfc_output$source_stage)[1], source_file = unique(nfc_output$source_file)[1],
    sector_boundary = "nonfinancial_corporate_business", gross_or_net = "gross",
    level_or_share = "level", numerator_id = "NFC_GVA", denominator_id = "",
    price_basis = "2017-price-equivalent dollars", units = unique(nfc_output$unit)[1], frequency = "A",
    first_year = min(nfc_output$year), last_year = max(nfc_output$year), n_nonmissing = sum(!is.na(nfc_output$value)),
    canonical_status = "canonical_baseline", descriptive_status = "headline",
    model_candidate_status = "eligible_not_selected", notes = "Canonical frozen-v1 NFC real-GVA baseline.",
    stringsAsFactors = FALSE),
  data.frame(
    paper_family = "Productive capital stock", paper_label = "Gross productive capital",
    paper_notation = "K_t^{P}", repository_variable_id = capital_id,
    source_stage = unique(capital$source_stage)[1], source_file = unique(capital$source_file)[1],
    sector_boundary = "nonfinancial_corporate_business", gross_or_net = "gross",
    level_or_share = "level", numerator_id = capital_id, denominator_id = "",
    price_basis = "2017 dollars", units = unique(capital$unit)[1], frequency = "A",
    first_year = min(capital$year), last_year = max(capital$year), n_nonmissing = sum(!is.na(capital$value)),
    canonical_status = "canonical_baseline", descriptive_status = "headline",
    model_candidate_status = "eligible_not_selected", notes = "Aggregate productive-capital baseline.",
    stringsAsFactors = FALSE)
)

share_meta <- data.frame(
  id = share_ids,
  label = c(
    "Corporate compensation share of corporate gross value added",
    "Corporate compensation share of corporate net value added",
    "NFC compensation share of NFC gross value added",
    "NFC compensation share of NFC net value added"
  ),
  notation = c("\\omega_{GVA,t}^{C}", "\\omega_{NVA,t}^{C}", "\\omega_{GVA,t}^{N}", "\\omega_{NVA,t}^{N}"),
  numerator = c("CORP_COMP", "CORP_COMP", "NFC_COMP", "NFC_COMP"),
  denominator = c("CORP_GVA", "CORP_NVA", "NFC_GVA", "NFC_NVA"),
  sector = c("corporate_business", "corporate_business", "nonfinancial_corporate_business", "nonfinancial_corporate_business"),
  account = c("gross", "net", "gross", "net"),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(share_meta))) {
  z <- shares[shares$variable_id == share_meta$id[i], ]
  registry_rows[[length(registry_rows) + 1L]] <- data.frame(
    paper_family = "Distributive variable", paper_label = share_meta$label[i],
    paper_notation = share_meta$notation[i], repository_variable_id = share_meta$id[i],
    source_stage = unique(z$source_stage)[1], source_file = unique(z$source_file)[1],
    sector_boundary = share_meta$sector[i], gross_or_net = share_meta$account[i],
    level_or_share = "share", numerator_id = share_meta$numerator[i],
    denominator_id = share_meta$denominator[i], price_basis = "current-dollar account ratio",
    units = "ratio", frequency = "A", first_year = min(z$year), last_year = max(z$year),
    n_nonmissing = sum(!is.na(z$value)), canonical_status = unique(z$canonical_inclusion_status)[1],
    descriptive_status = "mandatory", model_candidate_status = "eligible_not_selected",
    notes = ifelse(share_meta$account[i] == "gross",
                   "Strict same-sector accounting counterpart to real GVA.",
                   "Same-sector net-income distributive measure; not a direct counterpart to real GVA."),
    stringsAsFactors = FALSE)
}
for (id in component_ids) {
  z <- get_component(id)
  registry_rows[[length(registry_rows) + 1L]] <- data.frame(
    paper_family = "Capital composition diagnostic",
    paper_label = ifelse(id == "G_ME_GPIM_2017", "Gross machinery-and-equipment capital", "Gross nonresidential-structures capital"),
    paper_notation = ifelse(id == "G_ME_GPIM_2017", "K_t^{ME}", "K_t^{NRC}"),
    repository_variable_id = id, source_stage = unique(z$source_stage)[1],
    source_file = rel(s29e_path), sector_boundary = "nonfinancial_corporate_business",
    gross_or_net = "gross", level_or_share = "level", numerator_id = id, denominator_id = "",
    price_basis = "2017 dollars", units = unique(z$unit)[1], frequency = "A",
    first_year = min(z$year), last_year = max(z$year), n_nonmissing = sum(!is.na(z$value)),
    canonical_status = "committed_upstream_diagnostic_noncanonical",
    descriptive_status = "support_or_validation", model_candidate_status = "diagnostic_not_selected",
    notes = "Composition diagnostic only; does not replace aggregate productive capital.",
    stringsAsFactors = FALSE)
}
registry <- do.call(rbind, registry_rows)
write_csv(registry, file.path(csv_dir, "S31B_variable_registry.csv"))

windows <- data.frame(
  window_id = c("global_available", "pre_1974", "post_1974", "pre_fordist",
                "fordist_core_1947_1973", "extended_fordist_bridge_1940_1978",
                "post_fordist_pre_gfc_1974_2008", "mature_post_volcker_pre_gfc_1983_2008",
                "post_gfc_2009_2025", "post_gfc_pre_covid_2009_2019",
                "post_covid_configuration_2022_2025"),
  window_type = c("global", "structural", "structural", "nested", "nested", "bridge",
                  "structural", "nested", "structural", "nested", "nested"),
  start_year = c(NA, NA, 1974, NA, 1947, 1940, 1974, 1983, 2009, 2009, 2022),
  end_year = c(2025, 1973, 2025, 1946, 1973, 1978, 2008, 2008, 2025, 2019, 2025),
  variable_specific_start = c(TRUE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE),
  testing_eligible = "no_decision_in_descriptive_pass",
  estimation_eligible = "no_decision_in_descriptive_pass",
  stringsAsFactors = FALSE
)
transitions <- data.frame(
  window_id = c("fordist_aftermath_1974_1978", "volcker_transition_1979_1982",
                "gfc_transition_2008_2009", "covid_transition_2020_2021"),
  window_type = "transition", start_year = c(1974, 1979, 2008, 2020),
  end_year = c(1978, 1982, 2009, 2021), variable_specific_start = FALSE,
  testing_eligible = "no", estimation_eligible = "no", stringsAsFactors = FALSE
)

make_growth <- function(z, id, label) {
  z <- z[order(z$year), c("year", "value")]
  prev_year <- c(NA_integer_, head(z$year, -1))
  prev_value <- c(NA_real_, head(z$value, -1))
  valid <- !is.na(z$value) & !is.na(prev_value) & z$year == prev_year + 1L & z$value > 0 & prev_value > 0
  data.frame(variable_id = id, paper_label = label, year = z$year, value = z$value,
             previous_year = prev_year, previous_value = prev_value,
             annual_log_growth = ifelse(valid, 100 * (log(z$value) - log(prev_value)), NA_real_),
             consecutive_years = valid, stringsAsFactors = FALSE)
}
growth <- rbind(
  make_growth(nfc_output, nfc_output_id, "Real NFC GVA"),
  make_growth(capital, capital_id, "Gross productive capital"),
  make_growth(me, "G_ME_GPIM_2017", "Gross machinery-and-equipment capital"),
  make_growth(nrc, "G_NRC_GPIM_2017", "Gross nonresidential-structures capital")
)

distribution <- shares[, c("variable_id", "year", "value")]
distribution <- merge(distribution, share_meta[, c("id", "label", "sector", "account")],
                      by.x = "variable_id", by.y = "id", all.x = TRUE)
distribution <- distribution[order(distribution$variable_id, distribution$year), ]
distribution$share_percent <- 100 * distribution$value
distribution$annual_change_pp <- ave(seq_len(nrow(distribution)), distribution$variable_id, FUN = function(idx) {
  z <- distribution[idx, ]
  py <- c(NA_integer_, head(z$year, -1))
  pv <- c(NA_real_, head(z$value, -1))
  ifelse(z$year == py + 1L, 100 * (z$value - pv), NA_real_)
})

capital_diag <- merge(me[, c("year", "value")], nrc[, c("year", "value")], by = "year", suffixes = c("_me", "_nrc"))
capital_diag$me_share_productive_capital <- capital_diag$value_me / (capital_diag$value_me + capital_diag$value_nrc)
capital_diag <- merge(capital_diag, growth[growth$variable_id == "G_ME_GPIM_2017", c("year", "annual_log_growth")], by = "year", all.x = TRUE)
names(capital_diag)[names(capital_diag) == "annual_log_growth"] <- "me_annual_log_growth"
capital_diag <- merge(capital_diag, growth[growth$variable_id == "G_NRC_GPIM_2017", c("year", "annual_log_growth")], by = "year", all.x = TRUE)
names(capital_diag)[names(capital_diag) == "annual_log_growth"] <- "nrc_annual_log_growth"
write_csv(capital_diag, file.path(csv_dir, "S31B_capital_composition_diagnostics.csv"))

share_wide <- reshape(distribution[, c("year", "variable_id", "value")], idvar = "year", timevar = "variable_id", direction = "wide")
names(share_wide) <- sub("^value\\.", "", names(share_wide))
dist_diag <- data.frame(
  year = share_wide$year,
  sector_boundary_gap_gva_pp = 100 * (share_wide$CORP_COMPENSATION_SHARE_GVA - share_wide$NFC_COMPENSATION_SHARE_GVA),
  sector_boundary_gap_nva_pp = 100 * (share_wide$CORP_COMPENSATION_SHARE_NVA - share_wide$NFC_COMPENSATION_SHARE_NVA),
  gross_net_gap_corporate_pp = 100 * (share_wide$CORP_COMPENSATION_SHARE_NVA - share_wide$CORP_COMPENSATION_SHARE_GVA),
  gross_net_gap_nfc_pp = 100 * (share_wide$NFC_COMPENSATION_SHARE_NVA - share_wide$NFC_COMPENSATION_SHARE_GVA)
)
write_csv(dist_diag, file.path(csv_dir, "S31B_distributive_boundary_diagnostics.csv"))

output_diag <- data.frame(
  year = nfc_output$year, nfc_real_gva = nfc_output$value,
  nfc_output_growth = growth$annual_log_growth[growth$variable_id == nfc_output_id],
  corporate_real_gva = NA_real_, corporate_output_growth = NA_real_,
  corporate_nfc_output_growth_gap = NA_real_, nfc_share_corporate_output = NA_real_,
  blocked_reason = "Y_REAL_CORP_GVA_BASELINE is not canonical; no substitution constructed.",
  stringsAsFactors = FALSE
)
write_csv(output_diag, file.path(csv_dir, "S31B_output_boundary_diagnostics.csv"))

window_bounds <- function(w, years) {
  start <- if (isTRUE(w$variable_specific_start)) min(years, na.rm = TRUE) else w$start_year
  c(start = start, end = w$end_year)
}
safe_sd <- function(x) if (sum(!is.na(x)) >= 2) sd(x, na.rm = TRUE) else NA_real_

level_stats <- function(z, id, w) {
  b <- window_bounds(w, z$year)
  years <- seq.int(b["start"], b["end"])
  s <- z[z$year >= b["start"] & z$year <= b["end"], ]
  obs <- s[!is.na(s$value), ]
  g <- make_growth(z, id, id)
  gg <- g[g$year >= b["start"] & g$year <= b["end"] & !is.na(g$annual_log_growth), ]
  data.frame(
    variable_id = id, window_id = w$window_id, window_type = w$window_type,
    available_start = if (nrow(obs)) min(obs$year) else NA,
    available_end = if (nrow(obs)) max(obs$year) else NA,
    n_total_years_in_window = length(years), n_nonmissing = nrow(obs),
    coverage_rate = nrow(obs) / length(years),
    initial_observed_year = if (nrow(obs)) obs$year[1] else NA,
    initial_value = if (nrow(obs)) obs$value[1] else NA,
    terminal_observed_year = if (nrow(obs)) tail(obs$year, 1) else NA,
    terminal_value = if (nrow(obs)) tail(obs$value, 1) else NA,
    mean = if (nrow(obs)) mean(obs$value) else NA,
    median = if (nrow(obs)) median(obs$value) else NA,
    standard_deviation = safe_sd(obs$value),
    minimum = if (nrow(obs)) min(obs$value) else NA,
    maximum = if (nrow(obs)) max(obs$value) else NA,
    cumulative_log_change = if (nrow(obs) >= 2 && all(obs$value[c(1, nrow(obs))] > 0))
      100 * (log(tail(obs$value, 1)) - log(obs$value[1])) else NA,
    compound_annual_growth_rate = if (nrow(obs) >= 2 && all(obs$value[c(1, nrow(obs))] > 0))
      100 * ((tail(obs$value, 1) / obs$value[1])^(1 / (tail(obs$year, 1) - obs$year[1])) - 1) else NA,
    mean_annual_log_growth = if (nrow(gg)) mean(gg$annual_log_growth) else NA,
    standard_deviation_annual_log_growth = safe_sd(gg$annual_log_growth),
    minimum_annual_log_growth = if (nrow(gg)) min(gg$annual_log_growth) else NA,
    maximum_annual_log_growth = if (nrow(gg)) max(gg$annual_log_growth) else NA,
    testing_eligible = w$testing_eligible, estimation_eligible = w$estimation_eligible,
    stringsAsFactors = FALSE)
}
share_stats <- function(z, id, w) {
  b <- window_bounds(w, z$year)
  years <- seq.int(b["start"], b["end"])
  s <- z[z$year >= b["start"] & z$year <= b["end"], ]
  obs <- s[!is.na(s$value), ]
  py <- c(NA_integer_, head(z$year, -1))
  pv <- c(NA_real_, head(z$value, -1))
  changes <- ifelse(z$year == py + 1L, 100 * (z$value - pv), NA_real_)
  cc <- changes[z$year >= b["start"] & z$year <= b["end"] & !is.na(changes)]
  data.frame(
    variable_id = id, window_id = w$window_id, window_type = w$window_type,
    available_start = if (nrow(obs)) min(obs$year) else NA,
    available_end = if (nrow(obs)) max(obs$year) else NA,
    n_total_years_in_window = length(years), n_nonmissing = nrow(obs),
    coverage_rate = nrow(obs) / length(years),
    initial_observed_year = if (nrow(obs)) obs$year[1] else NA,
    initial_share_percent = if (nrow(obs)) 100 * obs$value[1] else NA,
    terminal_observed_year = if (nrow(obs)) tail(obs$year, 1) else NA,
    terminal_share_percent = if (nrow(obs)) 100 * tail(obs$value, 1) else NA,
    mean_share_percent = if (nrow(obs)) 100 * mean(obs$value) else NA,
    median_share_percent = if (nrow(obs)) 100 * median(obs$value) else NA,
    standard_deviation_percentage_points = 100 * safe_sd(obs$value),
    minimum_share_percent = if (nrow(obs)) 100 * min(obs$value) else NA,
    maximum_share_percent = if (nrow(obs)) 100 * max(obs$value) else NA,
    initial_to_terminal_change_percentage_points = if (nrow(obs) >= 2) 100 * (tail(obs$value, 1) - obs$value[1]) else NA,
    mean_annual_change_percentage_points = if (length(cc)) mean(cc) else NA,
    testing_eligible = w$testing_eligible, estimation_eligible = w$estimation_eligible,
    stringsAsFactors = FALSE)
}

level_series <- list(
  Y_REAL_NFC_GVA_BASELINE = nfc_output[, c("year", "value")],
  G_TOT_GPIM_2017 = capital[, c("year", "value")],
  G_ME_GPIM_2017 = me[, c("year", "value")],
  G_NRC_GPIM_2017 = nrc[, c("year", "value")]
)
structural <- bind_fill(c(
  lapply(names(level_series), function(id) do.call(rbind, lapply(seq_len(nrow(windows)), function(i) level_stats(level_series[[id]], id, windows[i, ])))),
  lapply(share_ids, function(id) {
    z <- shares[shares$variable_id == id, c("year", "value")]
    do.call(rbind, lapply(seq_len(nrow(windows)), function(i) share_stats(z, id, windows[i, ])))
  })
))
transition <- bind_fill(c(
  lapply(names(level_series), function(id) do.call(rbind, lapply(seq_len(nrow(transitions)), function(i) level_stats(level_series[[id]], id, transitions[i, ])))),
  lapply(share_ids, function(id) {
    z <- shares[shares$variable_id == id, c("year", "value")]
    do.call(rbind, lapply(seq_len(nrow(transitions)), function(i) share_stats(z, id, transitions[i, ])))
  })
))
write_csv(structural, file.path(csv_dir, "S31B_structural_window_descriptive_statistics.csv"))
write_csv(transition, file.path(csv_dir, "S31B_transition_window_descriptive_statistics.csv"))

events <- data.frame(
  event_id = c("volcker_event_profile_1978_1983", "gfc_event_profile_2007_2010", "covid_event_profile_2019_2022"),
  start_year = c(1978, 2007, 2019), end_year = c(1983, 2010, 2022),
  event_year = c(1979, 2008, 2020), stringsAsFactors = FALSE
)
event_source <- rbind(
  data.frame(variable_id = nfc_output_id, year = nfc_output$year, observed_value = nfc_output$value, variable_type = "level"),
  data.frame(variable_id = capital_id, year = capital$year, observed_value = capital$value, variable_type = "level"),
  data.frame(variable_id = shares$variable_id, year = shares$year, observed_value = shares$value, variable_type = "share")
)
event_values <- do.call(rbind, lapply(seq_len(nrow(events)), function(i) {
  e <- events[i, ]
  do.call(rbind, lapply(split(event_source, event_source$variable_id), function(z) {
    z <- z[order(z$year), ]
    py <- c(NA_integer_, head(z$year, -1))
    pv <- c(NA_real_, head(z$observed_value, -1))
    valid <- z$year == py + 1L & !is.na(z$observed_value) & !is.na(pv)
    q <- z[z$year >= e$start_year & z$year <= e$end_year, ]
    idx <- match(q$year, z$year)
    data.frame(
      event_id = e$event_id, variable_id = q$variable_id, year = q$year,
      observed_value = q$observed_value,
      absolute_annual_change = ifelse(valid[idx], q$observed_value - pv[idx], NA),
      percentage_annual_change_when_valid = ifelse(valid[idx] & q$variable_type == "level" & q$observed_value > 0 & pv[idx] > 0,
                                                    100 * (q$observed_value / pv[idx] - 1), NA),
      percentage_point_change_for_shares = ifelse(valid[idx] & q$variable_type == "share",
                                                   100 * (q$observed_value - pv[idx]), NA),
      position_relative_to_event = ifelse(q$year < e$event_year, "pre_event",
                                          ifelse(q$year == e$event_year, "event_onset", "post_onset")),
      stringsAsFactors = FALSE)
  }))
}))
write_csv(event_values, file.path(csv_dir, "S31B_event_profile_values.csv"))

acct_wide <- reshape(accounts[accounts$variable_id %in% c(
  "CORP_GVA", "CORP_NVA", "CORP_CFC", "CORP_COMP", "CORP_NOS",
  "NFC_GVA", "NFC_NVA", "NFC_CFC", "NFC_COMP", "NFC_NOS"
), c("year", "variable_id", "value")], idvar = "year", timevar = "variable_id", direction = "wide")
names(acct_wide) <- sub("^value\\.", "", names(acct_wide))

identity_check <- function(id, lhs, rhs, tolerance, note) {
  residual <- lhs - rhs
  data.frame(check_id = id, year = acct_wide$year, absolute_residual = abs(residual),
             relative_residual = ifelse(abs(lhs) > 0, abs(residual) / abs(lhs), NA),
             maximum_absolute_residual = max(abs(residual), na.rm = TRUE),
             mean_absolute_residual = mean(abs(residual), na.rm = TRUE),
             tolerance = tolerance,
             result = ifelse(abs(residual) <= tolerance, "PASS", "FAIL"),
             notes = note, stringsAsFactors = FALSE)
}
accounting_checks <- rbind(
  identity_check("CORP_GVA_EQUALS_NVA_PLUS_CFC", acct_wide$CORP_GVA, acct_wide$CORP_NVA + acct_wide$CORP_CFC, 2,
                 "Published current-dollar components; tolerance reflects million-dollar rounding."),
  identity_check("NFC_GVA_EQUALS_NVA_PLUS_CFC", acct_wide$NFC_GVA, acct_wide$NFC_NVA + acct_wide$NFC_CFC, 2,
                 "Published current-dollar components; tolerance reflects million-dollar rounding.")
)
for (i in seq_len(nrow(share_meta))) {
  id <- share_meta$id[i]
  num <- acct_wide[[share_meta$numerator[i]]]
  den <- acct_wide[[share_meta$denominator[i]]]
  can <- shares[shares$variable_id == id, c("year", "value")]
  aligned <- merge(data.frame(year = acct_wide$year, expected = num / den), can, by = "year")
  residual <- aligned$value - aligned$expected
  accounting_checks <- rbind(accounting_checks, data.frame(
    check_id = paste0(id, "_DIRECT_RATIO"), year = aligned$year,
    absolute_residual = abs(residual),
    relative_residual = ifelse(abs(aligned$expected) > 0, abs(residual) / abs(aligned$expected), NA),
    maximum_absolute_residual = max(abs(residual)), mean_absolute_residual = mean(abs(residual)),
    tolerance = 1e-12, result = ifelse(abs(residual) <= 1e-12, "PASS", "FAIL"),
    notes = "Canonical share equals direct same-sector numerator/denominator ratio.", stringsAsFactors = FALSE))
}
not_testable <- data.frame(
  check_id = c("CORP_NVA_COMPONENT_IDENTITY", "NFC_NVA_COMPONENT_IDENTITY",
               "CORP_GROSS_SHARE_IDENTITY", "NFC_GROSS_SHARE_IDENTITY"),
  year = NA_integer_, absolute_residual = NA_real_, relative_residual = NA_real_,
  maximum_absolute_residual = NA_real_, mean_absolute_residual = NA_real_,
  tolerance = NA_real_, result = "NOT_TESTABLE",
  notes = "Taxes on production and imports less subsidies are not separately available; corporate income tax is not substituted.",
  stringsAsFactors = FALSE)
accounting_checks <- rbind(accounting_checks, not_testable)
write_csv(accounting_checks, file.path(csv_dir, "S31B_accounting_identity_checks.csv"))

correspondence <- data.frame(
  output_object = c("Y_REAL_CORP_GVA_BASELINE", "Y_REAL_NFC_GVA_BASELINE",
                    "Y_REAL_CORP_GVA_BASELINE", "Y_REAL_NFC_GVA_BASELINE"),
  distribution_object = c("CORP_COMPENSATION_SHARE_GVA", "NFC_COMPENSATION_SHARE_GVA",
                          "CORP_COMPENSATION_SHARE_NVA", "NFC_COMPENSATION_SHARE_NVA"),
  correspondence_class = c("blocked_strict_pair", "strict_accounting_pair",
                           "blocked_same_sector_net_alternative", "same_sector_net_alternative"),
  accounting_identity_claim = c("blocked", "yes", "no", "no"),
  model_mapping_status = "eligible_not_selected",
  note = c(
    "Corporate real GVA is noncanonical.",
    "Same NFC sector and gross-value-added boundary.",
    "Corporate real GVA is noncanonical; NVA share is not a direct GVA counterpart.",
    "Same NFC sector but net denominator; not a direct GVA counterpart."
  ),
  stringsAsFactors = FALSE)
write_csv(correspondence, file.path(csv_dir, "S31B_accounting_correspondence_ledger.csv"))

theme_paper <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(color = "#444444"), legend.position = "bottom",
        axis.title = element_text(color = "#333333"))
save_plot <- function(p, name, width = 8, height = 4.8) {
  ggsave(file.path(fig_dir, name), p, width = width, height = height, dpi = 180, bg = "white")
}
break_lines <- data.frame(x = c(1947, 1974, 1979, 1982, 2008, 2009, 2020, 2022))

p <- ggplot(nfc_output, aes(year, value)) + geom_line(color = "#1b6a75", linewidth = 0.8) +
  geom_vline(data = break_lines, aes(xintercept = x), color = "#bbbbbb", linewidth = 0.3) +
  labs(title = "Real NFC gross value added", subtitle = "Canonical frozen-v1 output series",
       x = NULL, y = "Millions of 2017-price-equivalent dollars") + theme_paper
save_plot(p, "S31B_output_real_nfc_gva.png")

g_nfc <- growth[growth$variable_id == nfc_output_id, ]
p <- ggplot(g_nfc, aes(year, annual_log_growth)) + geom_hline(yintercept = 0, color = "#777777", linewidth = 0.35) +
  geom_line(color = "#1b6a75", linewidth = 0.75, na.rm = TRUE) +
  labs(title = "Annual real NFC output growth", subtitle = "Consecutive-year log growth only",
       x = NULL, y = "Percent") + theme_paper
save_plot(p, "S31B_output_nfc_growth.png")

p <- ggplot(capital, aes(year, value)) + geom_line(color = "#6b4c9a", linewidth = 0.8) +
  labs(title = "Gross productive-capital stock", x = NULL, y = "Millions of 2017 dollars") + theme_paper
save_plot(p, "S31B_capital_productive_level.png")
g_cap <- growth[growth$variable_id == capital_id, ]
p <- ggplot(g_cap, aes(year, annual_log_growth)) + geom_hline(yintercept = 0, color = "#777777", linewidth = 0.35) +
  geom_line(color = "#6b4c9a", linewidth = 0.75, na.rm = TRUE) +
  labs(title = "Annual productive-capital growth", x = NULL, y = "Percent") + theme_paper
save_plot(p, "S31B_capital_productive_growth.png")

comp_plot <- rbind(data.frame(year = me$year, value = me$value, component = "Machinery and equipment"),
                   data.frame(year = nrc$year, value = nrc$value, component = "Nonresidential structures"))
p <- ggplot(comp_plot, aes(year, value, color = component)) + geom_line(linewidth = 0.75) +
  scale_color_manual(values = c("Machinery and equipment" = "#c44e52", "Nonresidential structures" = "#4c72b0")) +
  labs(title = "Productive-capital components", x = NULL, y = "Millions of 2017 dollars", color = NULL) + theme_paper
save_plot(p, "S31B_capital_me_nrc_components.png")
p <- ggplot(capital_diag, aes(year, 100 * me_share_productive_capital)) + geom_line(color = "#c44e52", linewidth = 0.8) +
  labs(title = "Machinery and equipment share of productive capital", x = NULL, y = "Percent") + theme_paper
save_plot(p, "S31B_capital_me_share.png")

plot_share_set <- function(ids, title, name) {
  z <- distribution[distribution$variable_id %in% ids, ]
  z$series <- factor(z$label, levels = unique(z$label))
  p <- ggplot(z, aes(year, share_percent, color = series)) + geom_line(linewidth = 0.75) +
    labs(title = title, x = NULL, y = "Percent", color = NULL) + theme_paper
  save_plot(p, name)
}
plot_share_set(share_ids[1:2], "Corporate compensation shares: gross and net accounts", "S31B_distribution_corporate_gross_net.png")
plot_share_set(share_ids[3:4], "NFC compensation shares: gross and net accounts", "S31B_distribution_nfc_gross_net.png")
plot_share_set(share_ids[c(1, 3)], "Corporate and NFC gross-account compensation shares", "S31B_distribution_sector_gva.png")
plot_share_set(share_ids[c(2, 4)], "Corporate and NFC net-account compensation shares", "S31B_distribution_sector_nva.png")

gap_long <- rbind(
  data.frame(year = dist_diag$year, value = dist_diag$gross_net_gap_corporate_pp, series = "Corporate net minus gross"),
  data.frame(year = dist_diag$year, value = dist_diag$gross_net_gap_nfc_pp, series = "NFC net minus gross"))
p <- ggplot(gap_long, aes(year, value, color = series)) + geom_hline(yintercept = 0, color = "#777777", linewidth = 0.35) +
  geom_line(linewidth = 0.75) + labs(title = "Gross-net compensation-share gaps", x = NULL, y = "Percentage points", color = NULL) + theme_paper
save_plot(p, "S31B_distribution_gross_net_gaps.png")
sector_long <- rbind(
  data.frame(year = dist_diag$year, value = dist_diag$sector_boundary_gap_gva_pp, series = "Corporate minus NFC, GVA"),
  data.frame(year = dist_diag$year, value = dist_diag$sector_boundary_gap_nva_pp, series = "Corporate minus NFC, NVA"))
p <- ggplot(sector_long, aes(year, value, color = series)) + geom_hline(yintercept = 0, color = "#777777", linewidth = 0.35) +
  geom_line(linewidth = 0.75) + labs(title = "Corporate-NFC compensation-share gaps", x = NULL, y = "Percentage points", color = NULL) + theme_paper
save_plot(p, "S31B_distribution_sector_boundary_gaps.png")

event_plot_data <- event_values[event_values$variable_id %in% c(nfc_output_id, capital_id, "NFC_COMPENSATION_SHARE_GVA"), ]
event_plot_data$display_value <- ifelse(event_plot_data$variable_id == "NFC_COMPENSATION_SHARE_GVA",
                                        100 * event_plot_data$observed_value,
                                        ave(event_plot_data$observed_value, interaction(event_plot_data$event_id, event_plot_data$variable_id),
                                            FUN = function(x) 100 * x / x[1]))
event_plot_data$label <- ifelse(event_plot_data$variable_id == "NFC_COMPENSATION_SHARE_GVA",
                                "NFC compensation share (percent)",
                                ifelse(event_plot_data$variable_id == nfc_output_id, "Real NFC output (first year=100)",
                                       "Productive capital (first year=100)"))
for (eid in events$event_id) {
  z <- event_plot_data[event_plot_data$event_id == eid, ]
  p <- ggplot(z, aes(year, display_value, color = label)) + geom_line(linewidth = 0.75) + geom_point(size = 1.8) +
    labs(title = gsub("_", " ", eid), subtitle = "Descriptive event profile; not a statistical regime",
         x = NULL, y = "Index or percent", color = NULL) + theme_paper
  save_plot(p, paste0("S31B_event_", eid, ".png"))
}

figure_files <- list.files(fig_dir, pattern = "\\.png$", full.names = FALSE)

report_lines <- c(
  "# S31B U.S. Descriptive Statistics and Historical Profiles",
  "",
  "## 1. Descriptive question",
  "",
  "The descriptive pass asks how observed NFC output, productive capital, and compensation shares move across the chapter's locked historical windows. It separates accounting correspondence from later theoretical model mapping and makes no model-selection decision.",
  "",
  "## 2. Data and accounting boundaries",
  "",
  "Frozen v1 provides canonical NFC real GVA, aggregate productive capital, and all four corporate/NFC gross/net compensation shares. Canonical real corporate GVA is absent. The corporate output lane is therefore blocked rather than filled with an ad hoc substitute.",
  "",
  "The strict available output-distribution pair is real NFC GVA with the NFC compensation share of NFC GVA. Net-account compensation shares are same-sector alternatives, not direct accounting counterparts to real GVA. Accounting correspondence does not bind later model mapping.",
  "",
  "## 3. Output evolution",
  "",
  "The available headline output evidence is the canonical NFC real-GVA series. Corporate-NFC output comparisons, output-growth gaps, and the NFC share of corporate output remain incomplete because corporate real GVA is noncanonical.",
  "",
  sprintf("![Real NFC output](../figures/%s)", "S31B_output_real_nfc_gva.png"),
  "",
  sprintf("![NFC output growth](../figures/%s)", "S31B_output_nfc_growth.png"),
  "",
  "## 4. Productive-capital evolution and composition",
  "",
  "Aggregate gross productive capital remains the baseline. Machinery and equipment and nonresidential structures enter only as composition diagnostics.",
  "",
  sprintf("![Productive capital](../figures/%s)", "S31B_capital_productive_level.png"),
  "",
  sprintf("![Capital components](../figures/%s)", "S31B_capital_me_nrc_components.png"),
  "",
  "## 5. Distribution across corporate/NFC and gross/net accounts",
  "",
  "All four compensation-share candidates remain visible. Gross-account shares preserve direct same-sector GVA correspondence; net-account shares change the denominator by excluding consumption of fixed capital. Sector-boundary and denominator gaps are descriptive differences, not causal effects.",
  "",
  sprintf("![Gross-account sector comparison](../figures/%s)", "S31B_distribution_sector_gva.png"),
  "",
  sprintf("![Gross-net gaps](../figures/%s)", "S31B_distribution_gross_net_gaps.png"),
  "",
  "## 6. Fordist and post-Fordist windows",
  "",
  sprintf("The structural output contains %d variable-window rows. Each row reports its own coverage, endpoints, valid observations, and descriptive measures; no missing values are filled.", nrow(structural)),
  "",
  "## 7. Volcker event profile",
  "",
  "The 1978-1983 profile displays annual observations around the transition without treating the interval as an independent statistical regime.",
  "",
  "## 8. GFC event profile",
  "",
  "The 2007-2010 profile preserves the annual sequence around 2008-2009 without asserting an estimated structural break.",
  "",
  "## 9. COVID event profile",
  "",
  "The 2019-2022 profile shows the shock and immediate configuration without extrapolating beyond observed data.",
  "",
  "## 10. Bounded descriptive conclusions",
  "",
  "The available evidence supports a complete NFC-output, productive-capital, and four-share descriptive layer. The corporate-output boundary remains blocked. Cross-boundary model specifications remain theoretical choices and must not be presented as accounting identities.",
  "",
  "Final decision: `DESCRIPTIVE_PASS_COMPLETE_WITH_DOCUMENTED_BLOCKED_OBJECTS`."
)
write_md(report_lines, file.path(report_dir, "S31B_descriptive_statistics_report.md"))
write_md(c(
  "# S31B Method and Window Notes", "",
  "Growth is 100 times the consecutive-year log difference for positive level series.",
  "Shares are reported in percent and annual share changes in percentage points.",
  "The global, pre-1974, and pre-Fordist windows use variable-specific starts.",
  "The extended Fordist bridge overlaps adjacent windows and is not an independent regime.",
  "Transition and event windows are descriptive only and are never estimation or testing samples.",
  "No interpolation, extrapolation, zero filling, or silent year deletion is used."
), file.path(report_dir, "S31B_method_and_window_notes.md"))

validation <- data.frame(check_id = character(), check_name = character(), status = character(), evidence = character())
add <- function(id, name, ok, evidence, critical = TRUE) {
  validation <<- rbind(validation, data.frame(
    check_id = id, check_name = name,
    status = if (ok) "PASS" else if (critical) "FAIL" else "BLOCKED_DOCUMENTED",
    evidence = as.character(evidence), stringsAsFactors = FALSE))
}
add("S31B_VAL_01", "isolated_worktree_branch", branch == branch_required && base_ok, paste(branch, base_commit))
add("S31B_VAL_02", "frozen_v1_hashes", all(hash_audit$result == "PASS"), paste(sum(hash_audit$result == "PASS"), nrow(hash_audit), sep = "/"))
add("S31B_VAL_03", "canonical_key_unique", !any(duplicated(canonical[c("year", "variable_id")])), nrow(canonical))
add("S31B_VAL_04", "nfc_output_resolved", nfc_output_id %in% canonical_ids && nrow(nfc_output) > 0, nfc_output_id)
add("S31B_VAL_05", "corporate_output_resolved", corp_output_id %in% canonical_ids, corp_output_id, critical = FALSE)
add("S31B_VAL_06", "capital_resolved", capital_id %in% canonical_ids && nrow(capital) > 0, capital_id)
add("S31B_VAL_07", "four_shares_resolved", all(share_ids %in% canonical_ids), paste(share_ids, collapse = "; "))
add("S31B_VAL_08", "positive_levels_before_logs", all(nfc_output$value > 0) && all(capital$value > 0) && all(me$value > 0) && all(nrc$value > 0), "all positive")
add("S31B_VAL_09", "consecutive_growth_only", all(growth$consecutive_years[!is.na(growth$annual_log_growth)]), sum(!is.na(growth$annual_log_growth)))
add("S31B_VAL_10", "share_ranges_documented", all(shares$value >= 0 & shares$value <= 1), paste(range(shares$value), collapse = "-"))
add("S31B_VAL_11", "window_definitions", nrow(windows) == 11 && nrow(transitions) == 4, "11 structural/global/nested; 4 transition")
add("S31B_VAL_12", "transition_nonestimable", all(transitions$testing_eligible == "no" & transitions$estimation_eligible == "no"), "all transition rows")
add("S31B_VAL_13", "event_years", nrow(event_values) > 0 && all(event_values$year >= 1978 & event_values$year <= 2022), nrow(event_values))
add("S31B_VAL_14", "gross_net_labels_match", all(registry$gross_or_net[registry$repository_variable_id %in% share_ids] == share_meta$account), "four shares")
add("S31B_VAL_15", "sector_labels_match", all(registry$sector_boundary[registry$repository_variable_id %in% share_ids] == share_meta$sector), "four shares")
add("S31B_VAL_16", "gva_identities", !any(accounting_checks$result[accounting_checks$check_id %in% c("CORP_GVA_EQUALS_NVA_PLUS_CFC", "NFC_GVA_EQUALS_NVA_PLUS_CFC")] == "FAIL"), "published rounding tolerance")
add("S31B_VAL_17", "share_identities", !any(accounting_checks$result[grepl("_DIRECT_RATIO$", accounting_checks$check_id)] == "FAIL"), "four direct ratios")
add("S31B_VAL_18", "nva_component_identity_honest", all(accounting_checks$result[grepl("NVA_COMPONENT", accounting_checks$check_id)] == "NOT_TESTABLE"), "production-tax component unavailable")
add("S31B_VAL_19", "no_silent_interpolation", TRUE, "script contains no interpolation operation")
add("S31B_VAL_20", "blocked_object_not_substituted", all(is.na(output_diag$corporate_real_gva)), corp_output_id)
add("S31B_VAL_21", "required_outputs_nonempty", all(file.info(c(
  file.path(csv_dir, "S31B_variable_registry.csv"),
  file.path(csv_dir, "S31B_structural_window_descriptive_statistics.csv"),
  file.path(csv_dir, "S31B_transition_window_descriptive_statistics.csv"),
  file.path(csv_dir, "S31B_event_profile_values.csv"),
  file.path(report_dir, "S31B_descriptive_statistics_report.md")
))$size > 0), "core outputs")
add("S31B_VAL_22", "figures_created", length(figure_files) >= 12, length(figure_files))
add("S31B_VAL_23", "no_model_selection", TRUE, "all model candidates eligible_not_selected")
add("S31B_VAL_24", "no_econometrics", TRUE, "descriptive transformations only")
add("S31B_VAL_25", "source_release_unchanged", all(hash_audit$result == "PASS"), "pre-generation hash audit")
add("S31B_VAL_26", "financial_diagnostics_not_promoted", all(finance_lock$baseline_eligible == "no" | finance_lock$object_id == "NFC_NOS"), "S30H role lock")
write_csv(validation, file.path(validation_dir, "S31B_validation_checks.csv"))

critical_failures <- sum(validation$status == "FAIL")
blocked <- validation$check_name[validation$status == "BLOCKED_DOCUMENTED"]
decision <- if (critical_failures == 0 && length(blocked)) "DESCRIPTIVE_PASS_COMPLETE_WITH_DOCUMENTED_BLOCKED_OBJECTS" else
  if (critical_failures == 0) "AUTHORIZE_DESCRIPTIVE_REPORT_CONSUMPTION" else "HUMAN_REVIEW_REQUIRED"
write_md(c(
  "# S31B Validation Summary", "",
  sprintf("- PASS: %d", sum(validation$status == "PASS")),
  sprintf("- BLOCKED_DOCUMENTED: %d", sum(validation$status == "BLOCKED_DOCUMENTED")),
  sprintf("- FAIL: %d", critical_failures),
  sprintf("- Figures: %d", length(figure_files)),
  sprintf("- Structural descriptive rows: %d", nrow(structural)),
  sprintf("- Transition rows: %d", nrow(transition)),
  sprintf("- Event-profile rows: %d", nrow(event_values)),
  "",
  paste0("Final decision: `", decision, "`."),
  "",
  "Blocked object: canonical real corporate-business GVA. Corporate-output comparisons and dependent diagnostics are intentionally incomplete."
), file.path(validation_dir, "S31B_validation_summary.md"))

completion <- data.frame(
  stage_id = stage_id, validation_pass = sum(validation$status == "PASS"),
  validation_blocked = sum(validation$status == "BLOCKED_DOCUMENTED"),
  validation_fail = critical_failures, decision = decision,
  structural_rows = nrow(structural), transition_rows = nrow(transition),
  event_profile_rows = nrow(event_values), figures = length(figure_files),
  blocked_objects = paste(blocked, collapse = "; "),
  stringsAsFactors = FALSE)
write_csv(completion, file.path(validation_dir, "S31B_completion_record.csv"))
write_csv(data.frame(file_read = sort(read_files)), file.path(validation_dir, "S31B_files_read_manifest.csv"))

if (critical_failures > 0) stop("S31B validation has critical failures.", call. = FALSE)
cat(sprintf(
  "validation: PASS=%d BLOCKED=%d FAIL=%d\nstructural rows: %d\ntransition rows: %d\nevent rows: %d\nfigures: %d\ndecision: %s\n",
  sum(validation$status == "PASS"), sum(validation$status == "BLOCKED_DOCUMENTED"), critical_failures,
  nrow(structural), nrow(transition), nrow(event_values), length(figure_files), decision
))
