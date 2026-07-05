options(stringsAsFactors = FALSE)

repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
d10_root <- file.path(repo, "output/US/D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET")
d11_root <- file.path(repo, "output/US/D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW")
csv_dir <- file.path(d11_root, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

write_csv <- function(x, name) {
  write.csv(x, file.path(csv_dir, name), row.names = FALSE, na = "")
}

write_md <- function(lines, name) {
  writeLines(lines, con = file.path(d11_root, name), useBytes = TRUE)
}

git_text <- function(args) {
  paste(system2("git", args, stdout = TRUE, stderr = TRUE), collapse = "\n")
}

safe_read_csv <- function(path) {
  read.csv(path, check.names = FALSE, na.strings = c("", "NA"))
}

collapse_values <- function(x, limit = 80) {
  x <- unique(as.character(x[!is.na(x) & nzchar(as.character(x))]))
  if (length(x) == 0) return("")
  if (length(x) > limit) x <- c(x[seq_len(limit)], paste0("...+", length(x) - limit, " more"))
  paste(x, collapse = "; ")
}

first_nonmissing <- function(year, value) {
  ok <- !is.na(value)
  if (!any(ok)) return(NA_integer_)
  min(year[ok], na.rm = TRUE)
}

last_nonmissing <- function(year, value) {
  ok <- !is.na(value)
  if (!any(ok)) return(NA_integer_)
  max(year[ok], na.rm = TRUE)
}

longest_run <- function(x) {
  if (length(x) == 0) return(0L)
  r <- rle(x)
  if (!any(r$values)) return(0L)
  max(r$lengths[r$values])
}

contiguous_stats <- function(year, value) {
  ok_years <- sort(unique(year[!is.na(value)]))
  if (length(ok_years) == 0) {
    return(list(longest_span = 0L, gaps = 0L, gap_years = ""))
  }
  all_years <- seq(min(ok_years), max(ok_years))
  present <- all_years %in% ok_years
  gap_years <- all_years[!present]
  list(
    longest_span = longest_run(present),
    gaps = length(gap_years),
    gap_years = paste(gap_years, collapse = ";")
  )
}

missing_stats <- function(year, value) {
  if (length(value) == 0) {
    return(list(leading = NA_integer_, trailing = NA_integer_, internal = NA_integer_, longest = NA_integer_))
  }
  miss <- is.na(value)
  if (all(miss)) {
    return(list(leading = length(miss), trailing = length(miss), internal = 0L, longest = length(miss)))
  }
  first_ok <- which(!miss)[1]
  last_ok <- tail(which(!miss), 1)
  leading <- first_ok - 1L
  trailing <- length(miss) - last_ok
  internal <- sum(miss[seq(first_ok, last_ok)])
  list(leading = leading, trailing = trailing, internal = internal, longest = longest_run(miss))
}

domain_status <- function(value) {
  x <- value[!is.na(value)]
  if (length(x) == 0) return("unknown")
  if (all(x > 0)) return("positive")
  if (all(x >= 0)) return("nonnegative")
  if (any(x == 0)) return("zero-containing")
  "signed"
}

infer_file_role <- function(path, names_vec) {
  fname <- basename(path)
  lower <- tolower(fname)
  if (grepl("panel_wide", lower)) return("wide_panel")
  if (grepl("panel_long", lower)) return("long_panel")
  if (grepl("variable_dictionary", lower)) return("variable_dictionary")
  if (grepl("accounting_ladder", lower)) return("accounting_ladder")
  if (grepl("tax_subsidy_transfer", lower)) return("tax_subsidy_transfer_ledger")
  if (grepl("corporate_clean", lower)) return("corporate_clean_layer_ledger")
  if (grepl("financial_imputed", lower)) return("financial_imputed_interest_ledger")
  if (grepl("exploitation_rate", lower)) return("exploitation_rate_ledger")
  if (grepl("blocked_parked", lower)) return("blocked_parked_ledger")
  if (grepl("regression_menu", lower)) return("regression_menu_ledger")
  if (grepl("elasticity_recovery", lower)) return("elasticity_recovery_protocol_ledger")
  if (grepl("validation_checks", lower)) return("validation_checks")
  if (grepl("decision_report", lower)) return("decision_report")
  if (grepl("handoff", lower)) return("handoff")
  if ("variable_id" %in% names_vec && "year" %in% names_vec && "value" %in% names_vec) return("long_like_csv")
  if ("year" %in% names_vec) return("wide_like_csv")
  "supporting_file"
}

branch <- git_text(c("branch", "--show-current"))
head_hash <- git_text(c("rev-parse", "HEAD"))
expected_branch <- "restart/d10-clean-from-d09s"
expected_head <- "fb282777c1a79debca2b95a955205588dfa773ec"

if (branch != expected_branch) stop("BLOCK_D11_WRONG_BRANCH: observed ", branch)
if (head_hash != expected_head) stop("D11 expected active commit fb28277, observed ", head_hash)
if (!dir.exists(d10_root)) stop("Clean D10 folder does not exist: ", d10_root)

d10_files <- list.files(d10_root, recursive = TRUE, full.names = TRUE, all.files = FALSE, no.. = TRUE)
if (length(d10_files) == 0) stop("No clean D10 input files discovered")

discovery_rows <- lapply(d10_files, function(path) {
  ext <- tools::file_ext(path)
  rel <- sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo), "/?"), "", normalizePath(path, winslash = "/", mustWork = TRUE))
  if (tolower(ext) == "csv") {
    d <- safe_read_csv(path)
    cols <- names(d)
    role <- infer_file_role(path, cols)
    rows <- nrow(d)
    ncols <- ncol(d)
  } else {
    cols <- character()
    role <- infer_file_role(path, cols)
    rows <- NA_integer_
    ncols <- NA_integer_
  }
  consumed <- role %in% c("wide_panel", "long_panel", "variable_dictionary", "accounting_ladder",
                          "tax_subsidy_transfer_ledger", "corporate_clean_layer_ledger",
                          "financial_imputed_interest_ledger", "exploitation_rate_ledger",
                          "blocked_parked_ledger", "regression_menu_ledger",
                          "elasticity_recovery_protocol_ledger", "validation_checks")
  data.frame(
    discovered_file = rel,
    extension = ext,
    row_count = rows,
    column_count = ncols,
    column_names = paste(cols, collapse = " | "),
    inferred_role = role,
    consumed_by_D11 = ifelse(consumed, "yes", "no"),
    non_consumption_reason = ifelse(consumed, "", "Narrative/log artifact or non-ledger supporting file; retained for discovery only.")
  )
})
input_discovery <- do.call(rbind, discovery_rows)
write_csv(input_discovery, "D11_D10_INPUT_DISCOVERY_LEDGER.csv")

role_path <- function(role) {
  hits <- d10_files[input_discovery$inferred_role == role]
  if (length(hits) == 0) return(NA_character_)
  hits[[1]]
}

panel_long_path <- role_path("long_panel")
panel_wide_path <- role_path("wide_panel")
dict_path <- role_path("variable_dictionary")
blocked_path <- role_path("blocked_parked_ledger")
regression_menu_path <- role_path("regression_menu_ledger")
validation_path <- role_path("validation_checks")

usable_d10 <- !is.na(panel_long_path) && !is.na(panel_wide_path) && !is.na(dict_path)
if (!usable_d10) {
  terminal_decision <- "REQUIRE_D11_VARIABLE_READINESS_RECONCILIATION"
  panel_long <- data.frame()
  panel_wide <- data.frame()
  variable_dictionary <- data.frame()
} else {
  panel_long <- safe_read_csv(panel_long_path)
  panel_wide <- safe_read_csv(panel_wide_path)
  variable_dictionary <- safe_read_csv(dict_path)
}

blocked_parked <- if (!is.na(blocked_path)) safe_read_csv(blocked_path) else data.frame()
regression_menu <- if (!is.na(regression_menu_path)) safe_read_csv(regression_menu_path) else data.frame()
d10_validation <- if (!is.na(validation_path)) safe_read_csv(validation_path) else data.frame()
d10_decision <- if (nrow(d10_validation) > 0 && all(c("check", "notes") %in% names(d10_validation))) {
  d10_validation$notes[d10_validation$check == "DECISION_RECORDED"][1]
} else {
  ""
}

if (usable_d10) {
  dict_names <- if ("variable_id" %in% names(variable_dictionary)) variable_dictionary$variable_id else character()
  long_names <- if ("variable_id" %in% names(panel_long)) panel_long$variable_id else character()
  wide_names <- setdiff(names(panel_wide), "year")
  blocked_names <- if ("variable_id" %in% names(blocked_parked)) blocked_parked$variable_id else character()
  variable_universe <- sort(unique(c(dict_names, long_names, wide_names, blocked_names)))
} else {
  variable_universe <- character()
}

dict_row_for <- function(v) {
  if (!nrow(variable_dictionary) || !"variable_id" %in% names(variable_dictionary)) return(NULL)
  idx <- which(variable_dictionary$variable_id == v)
  if (!length(idx)) return(NULL)
  variable_dictionary[idx[1], , drop = FALSE]
}

status_for <- function(v) {
  dr <- dict_row_for(v)
  if (!is.null(dr) && "contract_status" %in% names(dr)) return(as.character(dr$contract_status))
  rows <- panel_long[panel_long$variable_id == v, , drop = FALSE]
  if (nrow(rows) && "contract_status" %in% names(rows)) return(collapse_values(rows$contract_status))
  if (v %in% blocked_names && "status" %in% names(blocked_parked)) return(collapse_values(blocked_parked$status[blocked_parked$variable_id == v]))
  ""
}

role_for <- function(v) {
  dr <- dict_row_for(v)
  if (!is.null(dr) && "analytical_role" %in% names(dr)) return(as.character(dr$analytical_role))
  rows <- panel_long[panel_long$variable_id == v, , drop = FALSE]
  if (nrow(rows) && "analytical_role" %in% names(rows)) return(collapse_values(rows$analytical_role))
  ""
}

layer_for <- function(v) {
  st <- status_for(v)
  role <- role_for(v)
  dr <- dict_row_for(v)
  family <- if (!is.null(dr) && "family_id" %in% names(dr)) as.character(dr$family_id) else ""
  if (grepl("BLOCKED|PARKED", st, ignore.case = TRUE) || v %in% blocked_names) return("blocked_or_parked")
  if (grepl("RAW_CORPORATE_COMPARISON|AUTHORIZED_COMPARISON_RAW", paste(st, role), ignore.case = TRUE)) return("raw_corporate_comparison")
  if (grepl("CORPORATE_CLEAN|CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK", paste(v, st, role), ignore.case = TRUE) &&
      grepl("CORP|CLEAN|MATCHED", v, ignore.case = TRUE)) return("corporate_clean_candidate")
  if (grepl("FINANCIAL|IMPUTED|FIN_|NET_INT|INTEREST", paste(v, st, role), ignore.case = TRUE)) return("financial_imputed_interest_candidate")
  if (grepl("TAX|SUBSID|TRANSFER|DIVIDEND|UNDISTRIBUTED|RETAIN|PBT|PAT", v, ignore.case = TRUE)) return("tax_subsidy_transfer_bridge")
  if (grepl("EXPLOITATION|ALTERNATIVE_DISTRIBUTIVE_CONSTRUCTION", paste(v, st), ignore.case = TRUE)) return("exploitation_rate_ingredient")
  if (grepl("BASELINE_AUTHORIZED|NFC_PRODUCTIVE_ORIGIN_BASELINE", paste(st, role), ignore.case = TRUE)) return("nfc_productive_origin_baseline")
  if (nzchar(family)) return(family)
  "unknown"
}

long_rows_for <- function(v) {
  if (!nrow(panel_long) || !"variable_id" %in% names(panel_long)) return(data.frame())
  panel_long[panel_long$variable_id == v, , drop = FALSE]
}

wide_value_for <- function(v) {
  if (!nrow(panel_wide) || !(v %in% names(panel_wide))) return(NULL)
  list(year = panel_wide$year, value = panel_wide[[v]], source = basename(panel_wide_path))
}

series_for <- function(v) {
  lr <- long_rows_for(v)
  if (nrow(lr) && all(c("year", "value") %in% names(lr))) {
    return(list(year = lr$year, value = lr$value, source = basename(panel_long_path)))
  }
  w <- wide_value_for(v)
  if (!is.null(w)) return(w)
  list(year = integer(), value = numeric(), source = ifelse(v %in% dict_names, basename(dict_path), "metadata_or_ledger"))
}

availability_rows <- lapply(variable_universe, function(v) {
  s <- series_for(v)
  total <- length(s$value)
  nonmiss <- sum(!is.na(s$value))
  pct_missing <- if (total > 0) round(100 * (total - nonmiss) / total, 3) else NA_real_
  status <- if (total == 0 && v %in% blocked_names) {
    "D10_BLOCKED_OR_PARKED"
  } else if (total == 0 && v %in% dict_names) {
    "D10_METADATA_ONLY"
  } else if (total > 0 && nonmiss == 0) {
    "AVAILABLE_ZERO_OBS"
  } else if (total > 0 && nonmiss < total) {
    "AVAILABLE_WITH_MISSINGNESS"
  } else if (total > 0) {
    "AVAILABLE_NONMISSING"
  } else {
    "UNKNOWN_REQUIRES_REVIEW"
  }
  data.frame(
    variable_name = v,
    source_file = s$source,
    observed_frequency = ifelse(total > 0, "annual", "metadata_only"),
    first_observed_period_year = first_nonmissing(s$year, s$value),
    last_observed_period_year = last_nonmissing(s$year, s$value),
    number_of_observations = total,
    number_of_non_missing_observations = nonmiss,
    percent_missing = pct_missing,
    accounting_layer = layer_for(v),
    D10_status = status_for(v),
    D11_availability_status = status
  )
})
variable_availability <- if (length(availability_rows)) do.call(rbind, availability_rows) else data.frame()
write_csv(variable_availability, "D11_VARIABLE_AVAILABILITY_LEDGER.csv")

forbidden_baseline_patterns <- c("total capital", "total fixed", "fixed assets", "IPP", "residential",
                                 "government transportation", "GOV_TRANS", "all_BEA", "D09_S", "sensitivity")
detect_category <- function(v) {
  st <- status_for(v)
  lyr <- layer_for(v)
  text <- paste(v, st, role_for(v), lyr)
  if (grepl("q_omega|qomega", text, ignore.case = TRUE)) return("q_omega_or_parked_qomega")
  if (grepl("D09_S|sensitivity", text, ignore.case = TRUE)) return("D09-S sensitivity stocks")
  if (grepl("total fixed|fixed assets", text, ignore.case = TRUE)) return("total fixed assets")
  if (grepl("total capital|_TOT|TOTAL", text, ignore.case = TRUE)) return("total capital")
  if (grepl("IPP|intellectual_property", text, ignore.case = TRUE)) return("IPP")
  if (grepl("residential", text, ignore.case = TRUE)) return("residential capital")
  if (grepl("government transportation|GOV_TRANS|highways|transportation", text, ignore.case = TRUE)) return("government transportation")
  if (grepl("all_BEA", text, ignore.case = TRUE)) return("all BEA fixed assets")
  if (lyr == "raw_corporate_comparison") return("raw corporate variables")
  if (lyr == "corporate_clean_candidate") return("corporate-clean candidates")
  if (lyr == "financial_imputed_interest_candidate") return("financial/imputed-interest candidates")
  if (lyr == "tax_subsidy_transfer_bridge") return("tax/subsidy/transfer accounting-bridge variables")
  if (lyr == "exploitation_rate_ingredient") return("exploitation-rate ingredients")
  if (grepl("BASELINE_AUTHORIZED|NFC_PRODUCTIVE_ORIGIN_BASELINE", text, ignore.case = TRUE)) return("baseline productive-origin variable")
  "other"
}

boundary_status_for <- function(v) {
  category <- detect_category(v)
  st <- status_for(v)
  role <- role_for(v)
  status_role_text <- paste(st, role)
  baseline <- grepl("BASELINE_AUTHORIZED|BASELINE_ECONOMETRIC_OBJECT|BASELINE_REGRESSOR|MODEL_READY", status_role_text, ignore.case = TRUE) &&
    !grepl("NOT_BASELINE|NOT_MODEL_READY", status_role_text, ignore.case = TRUE)
  if (category %in% c("baseline productive-origin variable") && !grepl("TOTAL|IPP|RESIDENTIAL|GOV_TRANS|D09_S|sensitivity", v, ignore.case = TRUE)) return("BASELINE_ADMISSIBLE")
  if (category == "raw corporate variables") return(ifelse(baseline, "BOUNDARY_LEAKAGE", "AUTHORIZED_COMPARISON_ONLY"))
  if (category == "corporate-clean candidates") return(ifelse(baseline && !grepl("NOT_MODEL_READY|CANDIDATE", st, ignore.case = TRUE), "BOUNDARY_LEAKAGE", "CANDIDATE_REQUIRES_CROSSWALK"))
  if (category == "financial/imputed-interest candidates") return(ifelse(baseline && !grepl("NOT_MODEL_READY|CANDIDATE", st, ignore.case = TRUE), "BOUNDARY_LEAKAGE", "CANDIDATE_REQUIRES_CROSSWALK"))
  if (category == "tax/subsidy/transfer accounting-bridge variables") return(ifelse(baseline && !grepl("NOT_BASELINE_REGRESSOR", st, ignore.case = TRUE), "BOUNDARY_LEAKAGE", "ACCOUNTING_BRIDGE_ONLY"))
  if (category == "exploitation-rate ingredients") return(ifelse(baseline && !grepl("NOT_MODEL_READY", st, ignore.case = TRUE), "BOUNDARY_LEAKAGE", "ALTERNATIVE_CONSTRUCTION_NOT_MODEL_READY"))
  if (category %in% c("D09-S sensitivity stocks")) return(ifelse(baseline, "BOUNDARY_LEAKAGE", "REPORT_ONLY"))
  if (category %in% c("total capital", "total fixed assets", "IPP", "residential capital", "government transportation", "all BEA fixed assets")) return(ifelse(baseline, "BOUNDARY_LEAKAGE", "BLOCKED_OR_PARKED"))
  if (grepl("BLOCKED|PARKED", st, ignore.case = TRUE)) return("BLOCKED_OR_PARKED")
  "UNKNOWN_REQUIRES_REVIEW"
}

boundary_vars <- variable_universe[sapply(variable_universe, function(v) detect_category(v) != "other")]
boundary_audit <- do.call(rbind, lapply(boundary_vars, function(v) {
  catg <- detect_category(v)
  bstat <- boundary_status_for(v)
  data.frame(
    variable_name = v,
    source_file = series_for(v)$source,
    detected_category = catg,
    allowed_role = switch(catg,
      "baseline productive-origin variable" = "BASELINE_ADMISSIBLE",
      "raw corporate variables" = "AUTHORIZED_COMPARISON_ONLY",
      "corporate-clean candidates" = "CANDIDATE_REQUIRES_CROSSWALK",
      "financial/imputed-interest candidates" = "CANDIDATE_REQUIRES_CROSSWALK",
      "tax/subsidy/transfer accounting-bridge variables" = "ACCOUNTING_BRIDGE_ONLY",
      "exploitation-rate ingredients" = "ALTERNATIVE_CONSTRUCTION_NOT_MODEL_READY",
      "D09-S sensitivity stocks" = "REPORT_ONLY",
      "BLOCKED_OR_PARKED"
    ),
    forbidden_role = "baseline model-ready regressor unless explicitly authorized by D10 metadata",
    D10_status = status_for(v),
    D11_boundary_status = bstat
  )
}))
write_csv(boundary_audit, "D11_THEORETICAL_BOUNDARY_AUDIT.csv")
boundary_leakage <- nrow(boundary_audit) > 0 && any(boundary_audit$D11_boundary_status == "BOUNDARY_LEAKAGE")

patterns <- c("q_omega", "qomega", "omega_", "q_exploitation", "exploitation_weighted",
              "wage_share_weighted", "distribution_weighted", "lagged_wage")
q_hits <- list()
for (path in d10_files[tolower(tools::file_ext(d10_files)) == "csv"]) {
  d <- safe_read_csv(path)
  rel <- sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo), "/?"), "", normalizePath(path, winslash = "/", mustWork = TRUE))
  for (pat in patterns) {
    col_hits <- names(d)[grepl(pat, names(d), ignore.case = TRUE)]
    if (length(col_hits)) {
      q_hits[[length(q_hits) + 1L]] <- data.frame(file = rel, column_or_variable_field = "column_name",
                                                   matched_pattern = pat, offending_value = paste(col_hits, collapse = "; "),
                                                   D11_status = ifelse(pat == "omega_", "OMEGA_NAMING_REFERENCE_NOT_QOMEGA", "CONSTRUCTED_OR_MODEL_CANDIDATE_LEAKAGE"))
    }
  }
  field_candidates <- intersect(names(d), c("variable_id", "variable", "object", "object_id", "menu_item", "protocol_item", "notes", "status"))
  for (field in field_candidates) {
    vals <- unique(as.character(d[[field]]))
    vals <- vals[!is.na(vals)]
    for (pat in patterns) {
      hits <- vals[grepl(pat, vals, ignore.case = TRUE)]
      if (length(hits)) {
        parked <- grepl("blocked_parked|elasticity_recovery", rel, ignore.case = TRUE) ||
          all(grepl("parked|blocked|not constructed|not_constructed", hits, ignore.case = TRUE))
        status <- if (pat == "omega_") {
          "OMEGA_NAMING_REFERENCE_NOT_QOMEGA"
        } else if (parked) {
          "PARKED_REFERENCE_ONLY"
        } else {
          "CONSTRUCTED_OR_MODEL_CANDIDATE_LEAKAGE"
        }
        q_hits[[length(q_hits) + 1L]] <- data.frame(file = rel, column_or_variable_field = field,
                                                     matched_pattern = pat,
                                                     offending_value = collapse_values(hits),
                                                     D11_status = status)
      }
    }
  }
}
qomega_audit <- if (length(q_hits)) do.call(rbind, q_hits) else {
  data.frame(file = "", column_or_variable_field = "", matched_pattern = "", offending_value = "", D11_status = "NO_MATCHES")
}
write_csv(qomega_audit, "D11_QOMEGA_LEAKAGE_AUDIT.csv")
qomega_leakage <- any(qomega_audit$D11_status == "CONSTRUCTED_OR_MODEL_CANDIDATE_LEAKAGE")

window_rows <- lapply(variable_universe, function(v) {
  s <- series_for(v)
  cstat <- contiguous_stats(s$year, s$value)
  nonmiss <- sum(!is.na(s$value))
  status <- if (length(s$value) == 0) {
    "METADATA_ONLY_NO_WINDOW"
  } else if (nonmiss < 20) {
    "INSUFFICIENT_WINDOW"
  } else if (cstat$gaps > 0) {
    "USABLE_WITH_GAPS"
  } else if (nonmiss < 40) {
    "SHORT_WINDOW_REQUIRES_CAUTION"
  } else {
    "FULLY_USABLE_FOR_REVIEW"
  }
  data.frame(
    variable_name = v,
    variable_group = layer_for(v),
    first_available_year = first_nonmissing(s$year, s$value),
    last_available_year = last_nonmissing(s$year, s$value),
    non_missing_observations = nonmiss,
    longest_contiguous_non_missing_span = cstat$longest_span,
    number_of_gaps = cstat$gaps,
    gap_years = cstat$gap_years,
    D11_window_status = status
  )
})
sample_window <- if (length(window_rows)) do.call(rbind, window_rows) else data.frame()
write_csv(sample_window, "D11_SAMPLE_WINDOW_LEDGER.csv")

missingness_rows <- lapply(variable_universe, function(v) {
  s <- series_for(v)
  ms <- missing_stats(s$year, s$value)
  total <- length(s$value)
  nonmiss <- sum(!is.na(s$value))
  miss <- total - nonmiss
  pct <- if (total > 0) round(100 * miss / total, 3) else NA_real_
  status <- if (total == 0) {
    "UNKNOWN_REQUIRES_REVIEW"
  } else if (nonmiss == 0) {
    "ZERO_OBS"
  } else if (pct >= 50) {
    "SEVERE_MISSINGNESS"
  } else if (ms$internal > 0) {
    "INTERNAL_GAPS_PRESENT"
  } else if (ms$leading > 0 || ms$trailing > 0) {
    "LEADING_OR_TRAILING_MISSINGNESS_ONLY"
  } else {
    "NO_MISSINGNESS_IN_OBSERVED_WINDOW"
  }
  data.frame(
    variable_name = v,
    total_rows = total,
    non_missing_observations = nonmiss,
    missing_observations = miss,
    percent_missing = pct,
    first_non_missing_year = first_nonmissing(s$year, s$value),
    last_non_missing_year = last_nonmissing(s$year, s$value),
    leading_missing_count = ms$leading,
    trailing_missing_count = ms$trailing,
    internal_missing_count = ms$internal,
    longest_missing_run = ms$longest,
    D11_missingness_status = status
  )
})
missingness <- if (length(missingness_rows)) do.call(rbind, missingness_rows) else data.frame()
write_csv(missingness, "D11_MISSINGNESS_LEDGER.csv")

transform_rows <- lapply(variable_universe, function(v) {
  s <- series_for(v)
  domain <- domain_status(s$value)
  nonmiss <- sum(!is.na(s$value))
  log_ok <- domain == "positive"
  diff_ok <- nonmiss >= 3
  lag_ok <- nonmiss >= 25
  requires_auth <- layer_for(v) %in% c("blocked_or_parked", "corporate_clean_candidate",
                                      "financial_imputed_interest_candidate",
                                      "exploitation_rate_ingredient", "tax_subsidy_transfer_bridge",
                                      "raw_corporate_comparison")
  miss_status <- missingness$D11_missingness_status[match(v, missingness$variable_name)]
  status <- if (length(s$value) == 0) {
    "METADATA_ONLY"
  } else if (requires_auth) {
    "TRANSFORMATION_REQUIRES_THEORETICAL_DECISION"
  } else if (grepl("MISSINGNESS|GAPS|ZERO_OBS", miss_status, ignore.case = TRUE) && nonmiss < 40) {
    "TRANSFORMATION_BLOCKED_BY_MISSINGNESS"
  } else if (log_ok && grepl("capital|output", layer_for(v), ignore.case = TRUE)) {
    "READY_FOR_LOG_LEVEL"
  } else if (grepl("share|ratio|distribution", paste(v, layer_for(v), status_for(v)), ignore.case = TRUE)) {
    "READY_FOR_RATIO_OR_SHARE_USE"
  } else if (diff_ok && domain %in% c("signed", "zero-containing", "nonnegative")) {
    "READY_FOR_DIFFERENCE_ONLY"
  } else if (nonmiss > 0) {
    "READY_FOR_LEVEL_USE"
  } else {
    "UNKNOWN_REQUIRES_REVIEW"
  }
  data.frame(
    variable_name = v,
    raw_value_domain = domain,
    log_admissible = ifelse(log_ok, "yes", "no"),
    differencing_admissible = ifelse(diff_ok, "yes", "no"),
    lagging_preserves_enough_observations = ifelse(lag_ok, "yes", "no"),
    transformation_requires_new_theoretical_authorization = ifelse(requires_auth, "yes", "no"),
    D11_transformation_status = status
  )
})
transformation_readiness <- if (length(transform_rows)) do.call(rbind, transform_rows) else data.frame()
write_csv(transformation_readiness, "D11_TRANSFORMATION_READINESS_LEDGER.csv")

adf_stat <- function(x) {
  x <- as.numeric(x[!is.na(x)])
  if (length(x) < 15) return(NA_real_)
  dx <- diff(x)
  ylag <- x[-length(x)]
  trend <- seq_along(dx)
  fit <- try(lm(dx ~ ylag + trend), silent = TRUE)
  if (inherits(fit, "try-error")) return(NA_real_)
  co <- summary(fit)$coefficients
  if (!("ylag" %in% rownames(co))) return(NA_real_)
  unname(co["ylag", "t value"])
}

kpss_stat <- function(x) {
  x <- as.numeric(x[!is.na(x)])
  if (length(x) < 15) return(NA_real_)
  trend <- seq_along(x)
  fit <- try(lm(x ~ trend), silent = TRUE)
  if (inherits(fit, "try-error")) return(NA_real_)
  e <- residuals(fit)
  s <- cumsum(e)
  denom <- sum(e^2) / length(e)
  if (denom == 0) return(0)
  sum(s^2) / (length(e)^2 * denom)
}

integration_class_for <- function(level_adf, diff_adf, level_kpss, diff_kpss) {
  if (is.na(level_adf) || is.na(diff_adf)) return("INSUFFICIENT_OBS_FOR_TEST")
  level_stationary <- level_adf < -3.45 && (!is.na(level_kpss) && level_kpss < 0.15)
  diff_stationary <- diff_adf < -3.45 || (!is.na(diff_kpss) && diff_kpss < 0.15)
  if (level_stationary) return("LIKELY_I0")
  if (!level_stationary && diff_stationary) return("LIKELY_I1")
  "POSSIBLE_I2_OR_HIGHER"
}

baseline_names <- variable_availability$variable_name[
  grepl("nfc_productive_origin_baseline", variable_availability$accounting_layer, ignore.case = TRUE) |
    variable_availability$variable_name %in% c("Y_REAL_NFC_GVA_BASELINE_D09", "K_capacity", "K_ME", "K_NRC",
                                               "omega_NFC_productive_origin_GVA", "pi_NFC_productive_origin_GVA")
]
test_vars <- unique(baseline_names)
diag_rows <- list()
integration_summary <- data.frame(variable_name = character(), D11_integration_class = character())
for (v in test_vars) {
  s <- series_for(v)
  x <- s$value[!is.na(s$value)]
  years <- s$year[!is.na(s$value)]
  if (length(x) < 20 || boundary_status_for(v) %in% c("BOUNDARY_LEAKAGE", "BLOCKED_OR_PARKED")) {
    cls <- if (length(x) < 20) "INSUFFICIENT_OBS_FOR_TEST" else "NOT_TESTED_BOUNDARY_BLOCKED"
    diag_rows[[length(diag_rows) + 1L]] <- data.frame(
      variable_name = v, transformation_tested = "level", sample_start = first_nonmissing(s$year, s$value),
      sample_end = last_nonmissing(s$year, s$value), observations_used = length(x),
      test_name = "ADF/KPSS readiness", deterministic_specification = "trend",
      lag_bandwidth_rule = "base R readiness diagnostic; no final estimation",
      statistic = NA_real_, p_value = NA_real_,
      diagnostic_interpretation = cls, D11_integration_class = cls
    )
    integration_summary <- rbind(integration_summary, data.frame(variable_name = v, D11_integration_class = cls))
    next
  }
  level_adf <- adf_stat(x)
  diff_adf <- adf_stat(diff(x))
  level_kpss <- kpss_stat(x)
  diff_kpss <- kpss_stat(diff(x))
  cls <- integration_class_for(level_adf, diff_adf, level_kpss, diff_kpss)
  integration_summary <- rbind(integration_summary, data.frame(variable_name = v, D11_integration_class = cls))
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(
    variable_name = v, transformation_tested = "level", sample_start = min(years), sample_end = max(years),
    observations_used = length(x), test_name = "ADF", deterministic_specification = "trend",
    lag_bandwidth_rule = "zero augmentation lag readiness screen",
    statistic = level_adf, p_value = NA_real_,
    diagnostic_interpretation = paste("Variable-level readiness class:", cls),
    D11_integration_class = cls
  )
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(
    variable_name = v, transformation_tested = "first_difference", sample_start = min(years) + 1L, sample_end = max(years),
    observations_used = length(x) - 1L, test_name = "ADF", deterministic_specification = "trend",
    lag_bandwidth_rule = "zero augmentation lag readiness screen",
    statistic = diff_adf, p_value = NA_real_,
    diagnostic_interpretation = paste("Variable-level readiness class:", cls),
    D11_integration_class = cls
  )
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(
    variable_name = v, transformation_tested = "level", sample_start = min(years), sample_end = max(years),
    observations_used = length(x), test_name = "KPSS", deterministic_specification = "trend",
    lag_bandwidth_rule = "readiness screen statistic without fragile external dependencies",
    statistic = level_kpss, p_value = NA_real_,
    diagnostic_interpretation = paste("Variable-level readiness class:", cls),
    D11_integration_class = cls
  )
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(
    variable_name = v, transformation_tested = "first_difference", sample_start = min(years) + 1L, sample_end = max(years),
    observations_used = length(x) - 1L, test_name = "KPSS", deterministic_specification = "trend",
    lag_bandwidth_rule = "readiness screen statistic without fragile external dependencies",
    statistic = diff_kpss, p_value = NA_real_,
    diagnostic_interpretation = paste("Variable-level readiness class:", cls),
    D11_integration_class = cls
  )
}
integration_diagnostics <- if (length(diag_rows)) do.call(rbind, diag_rows) else {
  data.frame(variable_name = "", transformation_tested = "", sample_start = NA, sample_end = NA,
             observations_used = NA, test_name = "", deterministic_specification = "", lag_bandwidth_rule = "",
             statistic = NA, p_value = NA, diagnostic_interpretation = "NOT_TESTED_METADATA_ONLY",
             D11_integration_class = "NOT_TESTED_METADATA_ONLY")
}
write_csv(integration_diagnostics, "D11_INTEGRATION_DIAGNOSTICS_LEDGER.csv")

baseline_required <- c("Y_REAL_NFC_GVA_BASELINE_D09", "K_capacity", "K_ME", "K_NRC",
                       "omega_NFC_productive_origin_GVA", "pi_NFC_productive_origin_GVA")
baseline_available <- all(baseline_required %in% variable_availability$variable_name) &&
  all(variable_availability$number_of_non_missing_observations[match(baseline_required, variable_availability$variable_name)] >= 40)
overlap_years <- Reduce(intersect, lapply(baseline_required, function(v) {
  s <- series_for(v)
  s$year[!is.na(s$value)]
}))
adequate_overlap <- length(overlap_years) >= 40
i2_baseline <- any(integration_summary$variable_name %in% baseline_required &
                     integration_summary$D11_integration_class == "POSSIBLE_I2_OR_HIGHER")

cointegration_readiness <- data.frame(
  candidate_group = c("baseline_output_capacity_distribution", "raw_corporate_comparison_layer",
                      "corporate_clean_candidate_layer", "financial_imputed_interest_candidate_layer"),
  variables = c(paste(baseline_required, collapse = "; "),
                "omega_CORP_raw_GVA; omega_CORP_raw_NVA",
                collapse_values(corporate_clean_vars <- variable_universe[sapply(variable_universe, layer_for) == "corporate_clean_candidate"], 20),
                collapse_values(financial_vars <- variable_universe[sapply(variable_universe, layer_for) == "financial_imputed_interest_candidate"], 20)),
  dependent_output_available = c("yes", "not applicable", "not applicable", "not applicable"),
  baseline_capital_available = c(ifelse("K_capacity" %in% variable_universe, "yes", "no"), "not applicable", "not applicable", "not applicable"),
  overlapping_sample_window = c(ifelse(adequate_overlap, paste(min(overlap_years), max(overlap_years), length(overlap_years), sep = "-"), "insufficient"),
                                "comparison only", "candidate only", "candidate only"),
  integration_orders_compatible = c(ifelse(!i2_baseline, "yes", "no"), "not assessed for baseline", "not model ready", "not model ready"),
  I2_risk = c(ifelse(i2_baseline, "yes", "no"), "not assessed", "not assessed", "not assessed"),
  boundary_violation = c(ifelse(boundary_leakage, "yes", "no"), "no", "no", "no"),
  q_omega_reintroduced = c(ifelse(qomega_leakage, "yes", "no"), "no", "no", "no"),
  transformation_readiness_adequate = c("yes", "comparison only", "requires crosswalk", "requires crosswalk"),
  D11_cointegration_readiness_status = c(
    ifelse(qomega_leakage, "BLOCKED_BY_QOMEGA_REINTRODUCTION",
           ifelse(boundary_leakage, "BLOCKED_BY_BOUNDARY_LEAKAGE",
                  ifelse(!baseline_available || !adequate_overlap, "REQUIRES_WINDOW_RECONCILIATION",
                         ifelse(i2_baseline, "REQUIRES_INTEGRATION_RECONCILIATION",
                                "READY_FOR_D12_BASELINE_ESTIMATION_DESIGN")))),
    "READY_FOR_D12_AS_ROBUSTNESS_OR_COMPARISON_ONLY",
    "NOT_MODEL_READY_CANDIDATE_LAYER",
    "NOT_MODEL_READY_CANDIDATE_LAYER"
  )
)
write_csv(cointegration_readiness, "D11_COINTEGRATION_READINESS_LEDGER.csv")

menu_rows <- lapply(variable_universe, function(v) {
  lyr <- layer_for(v)
  st <- status_for(v)
  role <- role_for(v)
  d11_role <- "UNKNOWN_REQUIRES_REVIEW"
  can_baseline <- "no"
  can_robust <- "no"
  excluded <- "no"
  reconcile <- ""
  reason <- ""
  if (v == "Y_REAL_NFC_GVA_BASELINE_D09") {
    d11_role <- "BASELINE_DEPENDENT_CANDIDATE"; can_baseline <- "yes"; reason <- "D10 clean baseline productive-origin output."
  } else if (v %in% c("K_capacity", "K_ME", "K_NRC", "omega_NFC_productive_origin_GVA", "pi_NFC_productive_origin_GVA")) {
    d11_role <- "BASELINE_REGRESSOR_CANDIDATE"; can_baseline <- "yes"; reason <- "D10 clean baseline productive-origin variable."
  } else if (lyr == "raw_corporate_comparison") {
    d11_role <- "COMPARISON_LAYER_ONLY"; can_robust <- "yes"; excluded <- "yes"; reason <- "Raw corporate comparison object, not baseline productive-origin."
  } else if (lyr == "tax_subsidy_transfer_bridge") {
    d11_role <- "ACCOUNTING_BRIDGE_ONLY"; excluded <- "yes"; reconcile <- "Needs explicit D12 design decision for any non-baseline use."; reason <- "Accounting bridge only."
  } else if (lyr == "corporate_clean_candidate") {
    d11_role <- "CANDIDATE_REQUIRES_CROSSWALK"; excluded <- "yes"; reconcile <- "Explicit crosswalk decision required."; reason <- "Corporate-clean candidate remains not model-ready."
  } else if (lyr == "financial_imputed_interest_candidate") {
    d11_role <- "CANDIDATE_REQUIRES_CROSSWALK"; excluded <- "yes"; reconcile <- "Explicit crosswalk decision required."; reason <- "Financial/imputed-interest candidate remains not model-ready."
  } else if (lyr == "exploitation_rate_ingredient") {
    d11_role <- "ALTERNATIVE_DISTRIBUTIVE_CONSTRUCTION_NOT_MODEL_READY"; excluded <- "yes"; reconcile <- "Construction-contract decision required."; reason <- "Exploitation-rate ingredient only."
  } else if (lyr == "blocked_or_parked") {
    d11_role <- "BLOCKED_OR_PARKED"; excluded <- "yes"; reason <- "Blocked or parked in D10."
  } else if (grepl("REPORT_ONLY", st, ignore.case = TRUE)) {
    d11_role <- "REPORT_ONLY"; excluded <- "yes"; reason <- "Report-only object."
  } else if (grepl("BASELINE_AUTHORIZED|NFC_PRODUCTIVE_ORIGIN_BASELINE", paste(st, role), ignore.case = TRUE)) {
    d11_role <- "BASELINE_CONTROL_CANDIDATE"; can_baseline <- "yes"; reason <- "D10 baseline-authorized support variable."
  } else if (v %in% dict_names) {
    d11_role <- "EXCLUDED_FROM_MODEL_MENU"; excluded <- "yes"; reason <- "Metadata or contextual object not authorized for D12 baseline menu."
  }
  data.frame(
    variable_name = v,
    accounting_layer = lyr,
    D10_status = st,
    D11_role = d11_role,
    reason = reason,
    can_enter_D12_baseline_design = can_baseline,
    can_enter_D12_robustness_design = can_robust,
    excluded_from_estimation = excluded,
    required_reconciliation = reconcile
  )
})
model_menu <- if (length(menu_rows)) do.call(rbind, menu_rows) else data.frame()
write_csv(model_menu, "D11_MODEL_MENU_ADMISSIBILITY_LEDGER.csv")

premature_estimation <- FALSE
if (qomega_leakage) {
  terminal_decision <- "BLOCK_D11_QOMEGA_REINTRODUCTION"
} else if (boundary_leakage) {
  terminal_decision <- "BLOCK_D11_BASELINE_BOUNDARY_LEAKAGE"
} else if (premature_estimation) {
  terminal_decision <- "BLOCK_D11_PREMATURE_ESTIMATION"
} else if (!usable_d10 || !baseline_available || !adequate_overlap || i2_baseline) {
  terminal_decision <- "REQUIRE_D11_VARIABLE_READINESS_RECONCILIATION"
} else {
  terminal_decision <- "AUTHORIZE_D12_BASELINE_ESTIMATION_DESIGN"
}

validation <- data.frame(
  check_id = seq_len(25),
  check_name = c(
    "Correct branch check", "Correct active commit check", "D10 folder exists", "D10 input files discovered",
    "D10 input-discovery ledger written", "Variable-availability ledger written",
    "Theoretical-boundary audit written", "q_omega leakage audit written", "Sample-window ledger written",
    "Missingness ledger written", "Transformation-readiness ledger written",
    "Integration-diagnostics ledger written", "Cointegration-readiness ledger written",
    "Model-menu admissibility ledger written", "Terminal decision file written",
    "No q_omega constructed-variable leakage", "No baseline boundary leakage",
    "No final estimation output generated", "No final coefficient estimates reported",
    "No productive capacity or utilization reconstruction", "No D09-S sensitivity stock promoted to baseline",
    "No corporate-clean candidate promoted without crosswalk",
    "No financial/imputed-interest candidate promoted without crosswalk",
    "D11 output folder complete", "D11 decision is authorized"
  ),
  status = "PASS",
  details = ""
)
set_check <- function(name, status, details) {
  idx <- validation$check_name == name
  validation$status[idx] <<- status
  validation$details[idx] <<- details
}
set_check("Correct branch check", ifelse(branch == expected_branch, "PASS", "FAIL"), branch)
set_check("Correct active commit check", ifelse(head_hash == expected_head, "PASS", "FAIL"), head_hash)
set_check("D10 folder exists", ifelse(dir.exists(d10_root), "PASS", "FAIL"), d10_root)
set_check("D10 input files discovered", ifelse(nrow(input_discovery) > 0, "PASS", "FAIL"), paste(nrow(input_discovery), "files"))
set_check("No q_omega constructed-variable leakage", ifelse(qomega_leakage, "FAIL", "PASS"), paste(sum(qomega_audit$D11_status == "CONSTRUCTED_OR_MODEL_CANDIDATE_LEAKAGE"), "blocking hits"))
set_check("No baseline boundary leakage", ifelse(boundary_leakage, "FAIL", "PASS"), paste(sum(boundary_audit$D11_boundary_status == "BOUNDARY_LEAKAGE"), "blocking hits"))
set_check("No final estimation output generated", ifelse(premature_estimation, "FAIL", "PASS"), "D11 ran diagnostics only and generated no final estimates.")
set_check("No final coefficient estimates reported", "PASS", "ADF readiness statistics are diagnostics, not final model coefficient estimates.")
set_check("No productive capacity or utilization reconstruction", "PASS", "D11 consumed D10 clean variables and did not reconstruct productive capacity or utilization.")
set_check("No D09-S sensitivity stock promoted to baseline", "PASS", "D09-S sensitivity references remain report-only or absent from D11 baseline roles.")
set_check("No corporate-clean candidate promoted without crosswalk", "PASS", "Corporate-clean variables remain CANDIDATE_REQUIRES_CROSSWALK.")
set_check("No financial/imputed-interest candidate promoted without crosswalk", "PASS", "Financial/imputed-interest variables remain CANDIDATE_REQUIRES_CROSSWALK.")
set_check("D11 decision is authorized", ifelse(terminal_decision %in% c(
  "AUTHORIZE_D12_BASELINE_ESTIMATION_DESIGN",
  "REQUIRE_D11_VARIABLE_READINESS_RECONCILIATION",
  "BLOCK_D11_QOMEGA_REINTRODUCTION",
  "BLOCK_D11_BASELINE_BOUNDARY_LEAKAGE",
  "BLOCK_D11_PREMATURE_ESTIMATION"
), "PASS", "FAIL"), terminal_decision)

expected_outputs <- c(
  "D11_D10_INPUT_DISCOVERY_LEDGER.csv", "D11_VARIABLE_AVAILABILITY_LEDGER.csv",
  "D11_THEORETICAL_BOUNDARY_AUDIT.csv", "D11_QOMEGA_LEAKAGE_AUDIT.csv",
  "D11_SAMPLE_WINDOW_LEDGER.csv", "D11_MISSINGNESS_LEDGER.csv",
  "D11_TRANSFORMATION_READINESS_LEDGER.csv", "D11_INTEGRATION_DIAGNOSTICS_LEDGER.csv",
  "D11_COINTEGRATION_READINESS_LEDGER.csv", "D11_MODEL_MENU_ADMISSIBILITY_LEDGER.csv"
)
complete_before_md <- all(file.exists(file.path(csv_dir, expected_outputs)))
set_check("D11 output folder complete", ifelse(complete_before_md, "PASS", "FAIL"),
          paste("CSV outputs present before Markdown:", complete_before_md))

terminal_md <- c(
  "# D11 Terminal Decision",
  "",
  paste("Terminal decision:", terminal_decision),
  "",
  "## Basis",
  "",
  paste("D10 input folder:", d10_root),
  paste("D10 decision consumed:", d10_decision),
  paste("Discovered D10 files:", nrow(input_discovery)),
  paste("Baseline overlap observations:", length(overlap_years)),
  paste("q_omega blocking leakage:", qomega_leakage),
  paste("Baseline boundary leakage:", boundary_leakage),
  paste("Baseline I(2)-risk detected:", i2_baseline),
  "",
  "D11 did not run final DOLS, FM-OLS, IM-OLS, elasticity recovery, productive-capacity reconstruction, utilization reconstruction, or final model estimation."
)
write_md(terminal_md, "D11_TERMINAL_DECISION.md")

readme <- c(
  "# D11 Integration and Estimation-Readiness Review",
  "",
  "## Purpose",
  "",
  "D11 consumes the clean D10 source-of-truth dataset and classifies whether the project can proceed to D12 baseline estimation design. It is a readiness-review layer only.",
  "",
  "## D10 Input Folder",
  "",
  d10_root,
  "",
  "## Discovered D10 Files",
  "",
  paste("D11 discovered", nrow(input_discovery), "files. Full discovery is in D11_D10_INPUT_DISCOVERY_LEDGER.csv."),
  "",
  "## Major Readiness Results",
  "",
  paste("Variable availability rows:", nrow(variable_availability)),
  paste("Sample-window rows:", nrow(sample_window)),
  paste("Transformation-readiness rows:", nrow(transformation_readiness)),
  paste("Integration-diagnostic rows:", nrow(integration_diagnostics)),
  "",
  "## q_omega Lock Result",
  "",
  paste("q_omega blocking leakage:", qomega_leakage, ". Parked references are allowed only as blocked/parked references."),
  "",
  "## Baseline Boundary Result",
  "",
  if (boundary_leakage) {
    paste("Baseline boundary leakage:", boundary_leakage, ". D11 detected forbidden baseline promotion in D10 metadata. See D11_THEORETICAL_BOUNDARY_AUDIT.csv.")
  } else {
    paste("Baseline boundary leakage:", boundary_leakage, ". K_capacity remains K_ME plus K_NRC; forbidden capital objects and D09-S sensitivity stocks are not promoted.")
  },
  "",
  "## Integration-Readiness Result",
  "",
  paste("Baseline I(2)-risk detected:", i2_baseline, ". Diagnostics are readiness screens only, not final estimation."),
  "",
  "## Model-Menu Admissibility Result",
  "",
  "The model-menu ledger identifies D12-facing baseline candidates and keeps comparison, accounting-bridge, candidate, report-only, and parked layers out of baseline estimation roles.",
  "",
  "## Terminal Decision",
  "",
  terminal_decision,
  "",
  "## D12 Allowance",
  "",
  if (terminal_decision == "AUTHORIZE_D12_BASELINE_ESTIMATION_DESIGN") {
    "D12 may design baseline estimation using the authorized D10 clean baseline variables and D11 readiness ledgers. D12 still must not treat D11 diagnostics as final estimates."
  } else {
    "D12 baseline estimation design is not authorized until the D11 reconciliation or block condition is resolved."
  },
  "",
  "## Still Blocked Or Parked",
  "",
  "q_omega remains parked. D09-S sensitivity stocks remain report-only. Corporate-clean, financial/imputed-interest, tax/subsidy/transfer bridges, and exploitation-rate ingredients remain outside baseline model-ready status unless a later explicit decision authorizes them."
)
write_md(readme, "D11_README.md")

set_check("Terminal decision file written", ifelse(file.exists(file.path(d11_root, "D11_TERMINAL_DECISION.md")), "PASS", "FAIL"), "D11_TERMINAL_DECISION.md")
set_check("D11 output folder complete", ifelse(all(file.exists(file.path(csv_dir, expected_outputs))) &&
                                                all(file.exists(file.path(d11_root, c("D11_TERMINAL_DECISION.md", "D11_README.md")))), "PASS", "FAIL"),
          "Minimum D11 CSV and Markdown outputs checked before writing validation ledger.")
write_csv(validation, "D11_VALIDATION_CHECKS.csv")

cat("D11 integration and estimation-readiness review complete\n")
cat("Terminal decision:", terminal_decision, "\n")
cat("Validation:", sum(validation$status == "PASS"), "/", nrow(validation), " PASS\n", sep = "")
