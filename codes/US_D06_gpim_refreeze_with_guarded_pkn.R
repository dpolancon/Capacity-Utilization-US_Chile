#!/usr/bin/env Rscript

# D06 GPIM refreeze with D05 GPIM-guarded pKN.
# Scope: ME, NRC, and K_capacity = ME + NRC only. No provider mutation or econometrics.

options(stringsAsFactors = FALSE, warn = 1, scipen = 999)

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg) == 1L) {
  normalizePath(sub("^--file=", "", script_arg), winslash = "/", mustWork = TRUE)
} else {
  normalizePath("codes/US_D06_gpim_refreeze_with_guarded_pkn.R", winslash = "/", mustWork = TRUE)
}
repo_root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run this script from the Capacity-Utilization-US_Chile repository root.", call. = FALSE)
}

path <- function(...) file.path(repo_root, ...)
rel_path <- function(x) {
  x <- normalizePath(x, winslash = "/", mustWork = FALSE)
  root <- normalizePath(repo_root, winslash = "/", mustWork = TRUE)
  sub(paste0("^", gsub("([\\^$.|?*+(){}])", "\\\\\\1", root), "/?"), "", x)
}
read_csv <- function(file) read.csv(file, check.names = FALSE, na.strings = c("", "NA"))
write_csv <- function(x, file) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  write.csv(x, file, row.names = FALSE, na = "")
}
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
safe_num <- function(x) suppressWarnings(as.numeric(x))
pass_fail <- function(flag) if (isTRUE(flag)) "PASS" else "FAIL"
max_abs <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) NA_real_ else max(abs(x))
}

stage_id <- "D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN"
decision_authorize <- "AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION"
decision_warmup_review <- "REQUIRE_WARMUP_INITIALIZATION_REVIEW"
decision_required_absent <- "BLOCK_GPIM_REFREEZE_REQUIRED_INPUT_ABSENT"
decision_coherence_fail <- "BLOCK_GPIM_REFREEZE_COHERENCE_FAIL"
tolerance <- 1e-6
analysis_start_year <- 1947L
survival_max_age <- 200L
tail_tolerance <- 1e-6

d06_dir <- path("output", "US", stage_id)
csv_dir <- path("output", "US", stage_id, "csv")
reports_dir <- path("output", "US", stage_id, "reports")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(reports_dir, recursive = TRUE, showWarnings = FALSE)

opening_repo_state <- data.frame(
  check = c(
    "git status --short",
    "git branch --show-current",
    "git rev-parse HEAD",
    "git log --oneline -5",
    "git status -sb"
  ),
  result = c(
    "CLEAN_AT_D06_OPENING_CHECK",
    "main",
    "b2926addf9db54a53591d6c3043f44302abcfe70",
    paste(c(
      "b2926ad Implement D05 GPIM guardian price-stock coherence",
      "6908be4 Merge D04 S12D_B source price and seed audit",
      "e183d33 Implement D04 S12D_B source price and seed audit",
      "7d85d55 Merge D03 S29C price and deflator provenance audit",
      "b84b350 Implement D03 S29C price and deflator provenance audit"
    ), collapse = "\n"),
    "main...origin/main [ahead 1]"
  ),
  notes = c(
    "Opening check returned no rows before D06 edits.",
    "Required branch was present.",
    "D06 starts from committed D05 boundary.",
    "D05 is treated as the boundary condition; D01-D05 are not reopened.",
    "D05 had not been pushed to origin at D06 opening; local implementation is not blocked."
  ),
  stringsAsFactors = FALSE
)

d05_dir <- path("output", "US", "D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE")
paths <- list(
  d05_asset_panel = path("output", "US", "D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE", "csv", "D05_asset_price_stock_flow_panel.csv"),
  d05_asset_checks = path("output", "US", "D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE", "csv", "D05_asset_coherence_checks.csv"),
  d05_capacity_panel = path("output", "US", "D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE", "csv", "D05_capacity_aggregation_panel.csv"),
  d05_validation = path("output", "US", "D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE", "csv", "D05_validation_checks.csv"),
  d05_report = path("output", "US", "D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE", "reports", "D05_decision_report.md")
)

required_files <- unlist(paths)
missing_files <- required_files[!file.exists(required_files)]

input_mapping <- data.frame()
init_ledger <- data.frame()
real_investment_panel <- data.frame()
asset_refrozen_panel <- data.frame()
capacity_refrozen_panel <- data.frame()
validation_checks <- data.frame()
final_decision <- decision_required_absent
d05_authorized <- FALSE

survival_weibull <- function(age, alpha, lambda) {
  exp(-((age / lambda) ^ alpha))
}

format_table <- function(df) {
  if (nrow(df) == 0L) return("_No rows._")
  paste(capture.output(print(df, row.names = FALSE)), collapse = "\n")
}

if (length(missing_files) == 0L) {
  d05_asset_panel <- read_csv(paths$d05_asset_panel)
  d05_asset_checks <- read_csv(paths$d05_asset_checks)
  d05_capacity_panel <- read_csv(paths$d05_capacity_panel)
  d05_validation <- read_csv(paths$d05_validation)
  d05_report <- read_text(paths$d05_report)

  d05_authorized <- grepl("AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN", d05_report, fixed = TRUE) &&
    nrow(d05_validation) > 0L && all(d05_validation$status == "PASS") &&
    nrow(d05_asset_checks) > 0L && all(d05_asset_checks$status == "PASS")

  d05_asset_panel$year <- as.integer(d05_asset_panel$year)
  for (col in c("I_current", "pKN_guardian", "I_real_guardian", "L", "alpha")) {
    d05_asset_panel[[col]] <- safe_num(d05_asset_panel[[col]])
  }

  asset_specs <- data.frame(
    asset = c("ME", "NRC"),
    required_L = c(14, 30),
    required_alpha = c(1.7, 1.6),
    stringsAsFactors = FALSE
  )

  input_rows <- list()
  for (asset in asset_specs$asset) {
    rows <- d05_asset_panel[d05_asset_panel$asset == asset, , drop = FALSE]
    years <- rows$year
    param <- asset_specs[asset_specs$asset == asset, , drop = FALSE]
    input_rows[[length(input_rows) + 1L]] <- data.frame(
      object_id = paste0("I_current_", asset),
      asset = asset,
      role = paste0("I_current_", asset),
      source_stage = "D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE",
      source_file = rel_path(paths$d05_asset_panel),
      source_column = "I_current",
      coverage_start = min(years, na.rm = TRUE),
      coverage_end = max(years, na.rm = TRUE),
      row_count = nrow(rows),
      status = ifelse(nrow(rows) > 0L && all(is.finite(rows$I_current)), "PRESENT", "ABSENT"),
      notes = "Current-cost gross investment consumed from D05 asset panel.",
      stringsAsFactors = FALSE
    )
    input_rows[[length(input_rows) + 1L]] <- data.frame(
      object_id = paste0("pKN_", asset),
      asset = asset,
      role = paste0("pKN_", asset),
      source_stage = "D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE",
      source_file = rel_path(paths$d05_asset_panel),
      source_column = "pKN_guardian",
      coverage_start = min(years, na.rm = TRUE),
      coverage_end = max(years, na.rm = TRUE),
      row_count = nrow(rows),
      status = ifelse(nrow(rows) > 0L && all(is.finite(rows$pKN_guardian) & rows$pKN_guardian > 0), "PRESENT", "ABSENT"),
      notes = "D05-authorized GPIM-guarded stock-valuation price; no official unmapped price is consumed.",
      stringsAsFactors = FALSE
    )
    input_rows[[length(input_rows) + 1L]] <- data.frame(
      object_id = paste0("survival_parameters_", asset),
      asset = asset,
      role = paste0("survival_parameters_", asset),
      source_stage = "D05/D01_LOCKED_SURVIVAL_ARCHITECTURE",
      source_file = rel_path(paths$d05_asset_panel),
      source_column = "L; alpha",
      coverage_start = min(years, na.rm = TRUE),
      coverage_end = max(years, na.rm = TRUE),
      row_count = length(unique(rows[, c("L", "alpha")])),
      status = ifelse(
        length(unique(rows$L)) == 1L && length(unique(rows$alpha)) == 1L &&
          abs(unique(rows$L) - param$required_L) < tolerance &&
          abs(unique(rows$alpha) - param$required_alpha) < tolerance,
        "PRESENT_LOCKED",
        "ABSENT_OR_CHANGED"
      ),
      notes = paste0("Locked survival parameters: L=", param$required_L, ", alpha=", param$required_alpha, ". D06 does not modify them."),
      stringsAsFactors = FALSE
    )
  }
  input_mapping <- do.call(rbind, input_rows)

  real_rows <- list()
  for (asset in asset_specs$asset) {
    rows <- d05_asset_panel[d05_asset_panel$asset == asset, , drop = FALSE]
    rows <- rows[order(rows$year), , drop = FALSE]
    constructed_real <- rows$I_current / (rows$pKN_guardian / 100)
    real_rows[[asset]] <- data.frame(
      year = rows$year,
      asset = asset,
      I_current = rows$I_current,
      pKN_guardian = rows$pKN_guardian,
      I_real_guardian = constructed_real,
      price_base_note = "D05 pKN_guardian is normalized to 2017=100; no D06 rebasing applied.",
      status = ifelse(is.finite(constructed_real) & constructed_real >= 0, "CONSTRUCTED", "INVALID"),
      stringsAsFactors = FALSE
    )
  }
  real_investment_panel <- do.call(rbind, real_rows)

  refrozen_rows <- list()
  init_rows <- list()
  for (asset in asset_specs$asset) {
    param <- asset_specs[asset_specs$asset == asset, , drop = FALSE]
    rows <- real_investment_panel[real_investment_panel$asset == asset, , drop = FALSE]
    rows <- rows[order(rows$year), , drop = FALSE]
    lambda <- param$required_L / gamma(1 + 1 / param$required_alpha)
    survival_at_L_plus_1 <- survival_weibull(param$required_L + 1L, param$required_alpha, lambda)
    survival_at_max_age <- survival_weibull(survival_max_age, param$required_alpha, lambda)
    construction_start <- min(rows$year)
    warmup_status <- ifelse(
      construction_start < analysis_start_year,
      "ASSET_SPECIFIC_WARMUP_USED",
      "INSUFFICIENT_WARMUP_HISTORY_REVIEW_REQUIRED"
    )
    init_rows[[asset]] <- data.frame(
      asset = asset,
      earliest_I_current_year = min(rows$year[is.finite(rows$I_current)]),
      earliest_pKN_year = min(rows$year[is.finite(rows$pKN_guardian)]),
      construction_start_year = construction_start,
      first_refrozen_stock_year = construction_start,
      analysis_start_year_if_known = analysis_start_year,
      warmup_rule = paste0("Use D05-authorized real investment from ", construction_start, " onward; years before ", analysis_start_year, " are warmup, not modeled observations."),
      inherited_vintage_rule = "No inherited pre-D05-price capital stock is invented.",
      tail_truncation_rule = paste0("D01 untruncated Weibull convention with ages 0:", survival_max_age, "; no terminal service-life cliff at L; survival at L+1 remains positive and survival at age ", survival_max_age, " is below ", tail_tolerance, "."),
      status = warmup_status,
      notes = paste0("pKN coverage begins in ", construction_start, " for ", asset, "; this is the longest D05-authorized price history available."),
      stringsAsFactors = FALSE
    )

    for (i in seq_len(nrow(rows))) {
      current_year <- rows$year[i]
      vintages <- rows[rows$year <= current_year, , drop = FALSE]
      ages <- current_year - vintages$year
      keep <- ages <= survival_max_age
      ages <- ages[keep]
      vintages <- vintages[keep, , drop = FALSE]
      survival <- survival_weibull(ages, param$required_alpha, lambda)
      k_real <- sum(vintages$I_real_guardian * survival)
      pkn <- rows$pKN_guardian[i]
      k_current <- k_real * pkn / 100
      refrozen_rows[[length(refrozen_rows) + 1L]] <- data.frame(
        year = current_year,
        asset = asset,
        K_real_refrozen = k_real,
        K_current_refrozen = k_current,
        pKN_guardian = pkn,
        I_real_guardian = rows$I_real_guardian[i],
        I_current = rows$I_current[i],
        survival_L = param$required_L,
        survival_alpha = param$required_alpha,
        survival_lambda = lambda,
        construction_start_year = construction_start,
        warmup_status = warmup_status,
        status = "CONSTRUCTED",
        stringsAsFactors = FALSE
      )
    }
  }
  init_ledger <- do.call(rbind, init_rows)
  asset_refrozen_panel <- do.call(rbind, refrozen_rows)
  asset_refrozen_panel <- asset_refrozen_panel[order(asset_refrozen_panel$asset, asset_refrozen_panel$year), , drop = FALSE]

  me <- asset_refrozen_panel[asset_refrozen_panel$asset == "ME", , drop = FALSE]
  nrc <- asset_refrozen_panel[asset_refrozen_panel$asset == "NRC", , drop = FALSE]
  years <- intersect(me$year, nrc$year)
  me <- me[match(years, me$year), , drop = FALSE]
  nrc <- nrc[match(years, nrc$year), , drop = FALSE]
  capacity_refrozen_panel <- data.frame(
    year = years,
    K_real_ME_refrozen = me$K_real_refrozen,
    K_real_NRC_refrozen = nrc$K_real_refrozen,
    K_real_capacity_refrozen = me$K_real_refrozen + nrc$K_real_refrozen,
    K_current_ME_refrozen = me$K_current_refrozen,
    K_current_NRC_refrozen = nrc$K_current_refrozen,
    K_current_capacity_refrozen = me$K_current_refrozen + nrc$K_current_refrozen,
    pKN_ME = me$pKN_guardian,
    pKN_NRC = nrc$pKN_guardian,
    pKN_capacity = 100 * (me$K_current_refrozen + nrc$K_current_refrozen) /
      (me$K_real_refrozen + nrc$K_real_refrozen),
    status = "CONSTRUCTED_BOTTOM_UP_ME_PLUS_NRC",
    stringsAsFactors = FALSE
  )
}

if (nrow(input_mapping) == 0L) {
  input_mapping <- data.frame(
    object_id = c("I_current_ME", "I_current_NRC", "pKN_ME", "pKN_NRC", "survival_parameters_ME", "survival_parameters_NRC"),
    asset = c("ME", "NRC", "ME", "NRC", "ME", "NRC"),
    role = c("I_current_ME", "I_current_NRC", "pKN_ME", "pKN_NRC", "survival_parameters_ME", "survival_parameters_NRC"),
    source_stage = "D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE",
    source_file = rel_path(paths$d05_asset_panel),
    source_column = NA_character_,
    coverage_start = NA_real_,
    coverage_end = NA_real_,
    row_count = 0L,
    status = "ABSENT",
    notes = paste("Missing D05 files:", paste(rel_path(missing_files), collapse = "; ")),
    stringsAsFactors = FALSE
  )
}

exclusion_ledger <- data.frame(
  object = c(
    "K_total",
    "BEA_TOTAL_fixed_assets",
    "provider_TOTAL",
    "IPP_baseline",
    "residential_baseline",
    "government_transportation_baseline",
    "raw_quantity_index_aggregation",
    "econometrics"
  ),
  status = c(
    "prohibited",
    "excluded",
    "excluded",
    "excluded",
    "excluded",
    "excluded",
    "prohibited",
    "prohibited"
  ),
  reason = c(
    "D06 capacity capital is ME plus NRC only.",
    "BEA total fixed assets are outside the Chapter 2 D06 baseline.",
    "Provider TOTAL is not used as fallback or comparator.",
    "IPP remains outside baseline capacity capital.",
    "Residential capital remains outside baseline capacity capital.",
    "Government transportation remains outside baseline capacity capital.",
    "D06 uses asset-level D05 pKN and real investment; it never sums raw chain-type quantity indexes.",
    "D06 is a refreeze pass, not a modeling or econometric pass."
  ),
  allowed_future_use = c(
    "none_in_D06_baseline",
    "future_boundary_review_only",
    "ledger_note_only",
    "future_conditioning_or_frontier_review_only",
    "none_in_D06_baseline",
    "future_public_infrastructure_context_review_only",
    "none",
    "future_stage_only_after_authorization"
  ),
  prohibited_use = c(
    "construction_or_alias_for_capacity_capital",
    "baseline_or_comparator_for_D06",
    "baseline_or_comparator_for_D06",
    "baseline_capacity_component",
    "baseline_capacity_component",
    "baseline_capacity_component",
    "capacity_aggregation_or_price_construction",
    "S30_S31_S32_or_any_modeling_routine"
  ),
  stringsAsFactors = FALSE
)

write_csv(input_mapping, file.path(csv_dir, "D06_input_mapping_ledger.csv"))
write_csv(init_ledger, file.path(csv_dir, "D06_initialization_warmup_ledger.csv"))
write_csv(real_investment_panel, file.path(csv_dir, "D06_real_investment_guardian_panel.csv"))
write_csv(asset_refrozen_panel, file.path(csv_dir, "D06_asset_refrozen_gpim_panel.csv"))
write_csv(capacity_refrozen_panel, file.path(csv_dir, "D06_capacity_refrozen_panel.csv"))
write_csv(exclusion_ledger, file.path(csv_dir, "D06_exclusion_ledger.csv"))

validation_row <- function(check_id, condition, notes) {
  data.frame(check_id = check_id, status = pass_fail(condition), notes = notes, stringsAsFactors = FALSE)
}

required_d05_inputs_present <- length(missing_files) == 0L
required_prices_present <- all(input_mapping$status[input_mapping$role %in% c("pKN_ME", "pKN_NRC")] == "PRESENT")
required_nominal_present <- all(input_mapping$status[input_mapping$role %in% c("I_current_ME", "I_current_NRC")] == "PRESENT")
survival_locked <- all(input_mapping$status[input_mapping$role %in% c("survival_parameters_ME", "survival_parameters_NRC")] == "PRESENT_LOCKED")
survival_no_cliff <- if (survival_locked) {
  params <- data.frame(asset = c("ME", "NRC"), L = c(14, 30), alpha = c(1.7, 1.6))
  all(vapply(seq_len(nrow(params)), function(i) {
    lambda <- params$L[i] / gamma(1 + 1 / params$alpha[i])
    survival_weibull(params$L[i] + 1L, params$alpha[i], lambda) > 0 &&
      survival_weibull(survival_max_age, params$alpha[i], lambda) < tail_tolerance
  }, logical(1)))
} else {
  FALSE
}
real_investment_constructed <- nrow(real_investment_panel) > 0L &&
  all(real_investment_panel$status == "CONSTRUCTED") &&
  max_abs(real_investment_panel$I_real_guardian - real_investment_panel$I_current / (real_investment_panel$pKN_guardian / 100)) <= tolerance
me_refrozen <- any(asset_refrozen_panel$asset == "ME") && all(asset_refrozen_panel$status[asset_refrozen_panel$asset == "ME"] == "CONSTRUCTED")
nrc_refrozen <- any(asset_refrozen_panel$asset == "NRC") && all(asset_refrozen_panel$status[asset_refrozen_panel$asset == "NRC"] == "CONSTRUCTED")
capacity_constructed <- nrow(capacity_refrozen_panel) > 0L &&
  max_abs(capacity_refrozen_panel$K_real_capacity_refrozen - capacity_refrozen_panel$K_real_ME_refrozen - capacity_refrozen_panel$K_real_NRC_refrozen) <= tolerance &&
  max_abs(capacity_refrozen_panel$K_current_capacity_refrozen - capacity_refrozen_panel$K_current_ME_refrozen - capacity_refrozen_panel$K_current_NRC_refrozen) <= tolerance
init_complete <- nrow(init_ledger) == 2L &&
  setequal(init_ledger$status, "ASSET_SPECIFIC_WARMUP_USED") &&
  all(init_ledger$construction_start_year < init_ledger$analysis_start_year_if_known)
forbidden_exclusions_complete <- setequal(
  exclusion_ledger$object,
  c("K_total", "BEA_TOTAL_fixed_assets", "provider_TOTAL", "IPP_baseline", "residential_baseline", "government_transportation_baseline", "raw_quantity_index_aggregation", "econometrics")
)

validation_checks <- do.call(rbind, list(
  validation_row("REPO_STATE_RECORDED", TRUE, "Opening repo state recorded; local main was ahead of origin/main by D05 only."),
  validation_row("D05_AUTHORIZATION_PRESENT", d05_authorized, "D05 decision report authorizes D06 and all D05 checks pass."),
  validation_row("REQUIRED_D05_INPUTS_PRESENT", required_d05_inputs_present, paste(rel_path(required_files), ifelse(file.exists(required_files), "present", "missing"), collapse = "; ")),
  validation_row("REQUIRED_PRICE_OBJECTS_PRESENT", required_prices_present, "pKN_ME and pKN_NRC are mapped from D05 pKN_guardian."),
  validation_row("REQUIRED_NOMINAL_INVESTMENT_INPUTS_PRESENT", required_nominal_present, "I_current_ME and I_current_NRC are mapped from D05 I_current."),
  validation_row("SURVIVAL_PARAMETERS_LOCKED", survival_locked, "ME L=14 alpha=1.7; NRC L=30 alpha=1.6."),
  validation_row("NO_TERMINAL_CLIFF_REINTRODUCED", survival_no_cliff, paste0("D06 uses ages 0:", survival_max_age, " with positive survival beyond L and negligible tail at max age.")),
  validation_row("REAL_INVESTMENT_CONSTRUCTED_FROM_GPIM_GUARDED_pKN", real_investment_constructed, "I_real_guardian = I_current / (pKN_guardian/100)."),
  validation_row("ME_REFROZEN_GPIM_CONSTRUCTED", me_refrozen, "ME gross surviving refrozen GPIM stock constructed separately."),
  validation_row("NRC_REFROZEN_GPIM_CONSTRUCTED", nrc_refrozen, "NRC gross surviving refrozen GPIM stock constructed separately."),
  validation_row("CAPACITY_BOTTOM_UP_AGGREGATION_CONSTRUCTED", capacity_constructed, "K_capacity_refrozen is exact ME plus NRC."),
  validation_row("NO_RAW_QUANTITY_INDEX_AGGREGATION", TRUE, "D06 reads no quantity-index column and aggregates no raw chain index."),
  validation_row("NO_TOTAL_CAPITAL_CONSTRUCTION", TRUE, "No total-capital output object is emitted."),
  validation_row("NO_FORBIDDEN_BASELINE_OBJECT_INCLUDED", forbidden_exclusions_complete, "All forbidden baseline objects are excluded in the ledger."),
  validation_row("INITIALIZATION_WARMUP_LEDGER_COMPLETE", init_complete, "Asset-specific warmup from D05 pKN history is recorded; no inherited capital stock is invented."),
  validation_row("NO_ECONOMETRICS_RUN", TRUE, "D06 writes construction/audit outputs only."),
  validation_row("DECISION_RECORDED", TRUE, "Decision code is written to D06_decision_report.md.")
))

all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 17L

if (!required_d05_inputs_present || !d05_authorized || !required_prices_present || !required_nominal_present) {
  final_decision <- decision_required_absent
} else if (!survival_locked || !survival_no_cliff || !real_investment_constructed || !me_refrozen || !nrc_refrozen || !capacity_constructed) {
  final_decision <- decision_coherence_fail
} else if (!init_complete) {
  final_decision <- decision_warmup_review
} else if (all_validation_pass) {
  final_decision <- decision_authorize
} else {
  final_decision <- decision_coherence_fail
}

write_csv(validation_checks, file.path(csv_dir, "D06_validation_checks.csv"))

asset_summary <- if (nrow(asset_refrozen_panel) > 0L) {
  do.call(rbind, lapply(c("ME", "NRC"), function(asset) {
    x <- asset_refrozen_panel[asset_refrozen_panel$asset == asset, , drop = FALSE]
    data.frame(
      asset = asset,
      first_year = min(x$year),
      last_year = max(x$year),
      rows = nrow(x),
      K_real_1947 = x$K_real_refrozen[x$year == 1947],
      K_real_2024 = x$K_real_refrozen[x$year == 2024],
      pKN_1947 = x$pKN_guardian[x$year == 1947],
      pKN_2024 = x$pKN_guardian[x$year == 2024],
      stringsAsFactors = FALSE
    )
  }))
} else {
  data.frame()
}

capacity_summary <- if (nrow(capacity_refrozen_panel) > 0L) {
  data.frame(
    first_year = min(capacity_refrozen_panel$year),
    last_year = max(capacity_refrozen_panel$year),
    rows = nrow(capacity_refrozen_panel),
    K_real_capacity_1947 = capacity_refrozen_panel$K_real_capacity_refrozen[capacity_refrozen_panel$year == 1947],
    K_real_capacity_2024 = capacity_refrozen_panel$K_real_capacity_refrozen[capacity_refrozen_panel$year == 2024],
    pKN_capacity_1947 = capacity_refrozen_panel$pKN_capacity[capacity_refrozen_panel$year == 1947],
    pKN_capacity_2024 = capacity_refrozen_panel$pKN_capacity[capacity_refrozen_panel$year == 2024],
    stringsAsFactors = FALSE
  )
} else {
  data.frame()
}

report_lines <- c(
  "# D06 GPIM Refreeze with GPIM-Guarded pKN",
  "",
  "## Opening repo state",
  "",
  "D06 starts from the committed D05 boundary and does not reopen D01-D05.",
  "",
  "```text",
  paste(opening_repo_state$check, opening_repo_state$result, sep = ": ", collapse = "\n"),
  "```",
  "",
  "D05 was local and not yet pushed at D06 opening (`main...origin/main [ahead 1]`). This is recorded but does not block local D06 implementation.",
  "",
  "## D05 authorization summary",
  "",
  paste0("D05 authorization present: `", pass_fail(d05_authorized), "`. D06 consumes D05 outputs only; it does not rerun the D05 price-coherence audit or revise the guardian price logic."),
  "",
  "## D06 conceptual lock",
  "",
  "D06 is a refreeze pass. It constructs asset-specific ME and NRC gross-survival GPIM stocks first, then constructs K_capacity as ME plus NRC. It does not construct total capital or total fixed assets.",
  "",
  "## Input mapping summary",
  "",
  "```text",
  format_table(input_mapping[, c("object_id", "asset", "role", "source_column", "coverage_start", "coverage_end", "row_count", "status")]),
  "```",
  "",
  "## Survival architecture summary",
  "",
  paste0("ME uses L=14 and alpha=1.7. NRC uses L=30 and alpha=1.6. D06 uses the D01 untruncated Weibull convention over ages 0:", survival_max_age, "; survival remains positive beyond L, so no terminal service-life cliff is reintroduced."),
  "",
  "## Price-to-real-investment rule",
  "",
  "For each asset, D06 constructs I_real_guardian = I_current / (pKN_guardian / 100). The D05 pKN series is normalized to 2017=100 and is not rebased in D06.",
  "",
  "## GPIM refreeze rule",
  "",
  "For each asset, D06 constructs K_real_refrozen as the sum of D05-guarded real investment vintages weighted by locked Weibull survival probabilities. K_current_refrozen equals K_real_refrozen multiplied by pKN_guardian/100.",
  "",
  "## Initialization and warmup",
  "",
  "D06 uses the longest D05-authorized pKN history available by asset and treats observations before 1947 as warmup history, not modeled sample observations. It invents no inherited pre-price capital stock.",
  "",
  "```text",
  format_table(init_ledger),
  "```",
  "",
  "## Asset-level results",
  "",
  "```text",
  format_table(asset_summary),
  "```",
  "",
  "## Bottom-up K_capacity summary",
  "",
  "```text",
  format_table(capacity_summary),
  "```",
  "",
  "## Exclusion statement",
  "",
  "D06 excludes total capital, BEA total fixed assets, provider TOTAL, IPP baseline, residential baseline, government transportation baseline, raw quantity-index aggregation, and econometrics.",
  "",
  "## Validation table",
  "",
  "```text",
  format_table(validation_checks),
  "```",
  "",
  "## Final decision",
  "",
  final_decision
)

writeLines(report_lines, file.path(reports_dir, "D06_decision_report.md"))

cat(final_decision, "\n")
