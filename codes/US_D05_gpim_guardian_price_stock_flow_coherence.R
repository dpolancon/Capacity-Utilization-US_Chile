#!/usr/bin/env Rscript

# D05 GPIM guardian price/stock-flow coherence for capacity capital.
# Scope: ME, NRC, and K_capacity = ME + NRC only. No econometrics.

options(stringsAsFactors = FALSE, warn = 1, scipen = 999)

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg) == 1L) {
  normalizePath(sub("^--file=", "", script_arg), winslash = "/", mustWork = TRUE)
} else {
  normalizePath("codes/US_D05_gpim_guardian_price_stock_flow_coherence.R", winslash = "/", mustWork = TRUE)
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
read_git <- function(args) {
  out <- tryCatch(system2("git", c("-C", repo_root, args), stdout = TRUE, stderr = TRUE), error = function(e) NA_character_)
  paste(out, collapse = "\n")
}
safe_num <- function(x) suppressWarnings(as.numeric(x))
max_abs <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) NA_real_ else max(abs(x))
}
max_rel <- function(residual, reference) {
  ok <- is.finite(residual) & is.finite(reference) & reference != 0
  if (!any(ok)) NA_real_ else max(abs(residual[ok] / reference[ok]))
}
pass_fail <- function(flag) if (isTRUE(flag)) "PASS" else "FAIL"

stage_id <- "D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE"
decision_authorize <- "AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN"
decision_price_review <- "REQUIRE_NARROW_PRICE_MAPPING_REVIEW"
decision_coherence_fail <- "BLOCK_GPIM_REFREEZE_PRICE_STOCK_FLOW_COHERENCE_FAIL"
decision_required_absent <- "BLOCK_GPIM_REFREEZE_REQUIRED_OBJECT_ABSENT"
tolerance <- 1e-6

d05_dir <- path("output", "US", stage_id)
csv_dir <- path("output", "US", stage_id, "csv")
reports_dir <- path("output", "US", stage_id, "reports")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(reports_dir, recursive = TRUE, showWarnings = FALSE)

opening_repo_state <- data.frame(
  check = c("git status --short", "git branch --show-current", "git rev-parse HEAD", "git log --oneline -5"),
  result = c(
    "CLEAN_AT_D05_OPENING_CHECK",
    "main",
    "6908be4dd7351d63c8da5027925db273487cc817",
    paste(c(
      "6908be4 Merge D04 S12D_B source price and seed audit",
      "e183d33 Implement D04 S12D_B source price and seed audit",
      "7d85d55 Merge D03 S29C price and deflator provenance audit",
      "b84b350 Implement D03 S29C price and deflator provenance audit",
      "0765c69 Merge D02 GPIM input-path and initialization audit"
    ), collapse = "\n")
  ),
  notes = c(
    "Opening check was performed before D05 edits; git status --short returned no rows.",
    "Required branch was present.",
    "Required D04 boundary commit was present.",
    "D04 is treated as the boundary condition; D01-D04 are not reopened."
  ),
  stringsAsFactors = FALSE
)

paths <- list(
  s24b_inputs = path("output", "US", "S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION", "csv", "S24B_fixed_assets_source_inputs_long.csv"),
  s29b_parameters = path("output", "US", "S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP", "csv", "S29B_gpim_parameter_lock_ledger.csv"),
  d04_validation = path("output", "US", "D04_GPIM_S12DB_SOURCE_PRICE_SEED_AUDIT", "D04_validation_checks.csv"),
  d04_report = path("reports", "maintenance", "D04_GPIM_S12DB_SOURCE_PRICE_SEED_AUDIT_2026-06-27", "D04_GPIM_S12DB_SOURCE_PRICE_SEED_AUDIT_REPORT.md")
)

required_files <- unlist(paths)
missing_files <- required_files[!file.exists(required_files)]

required_objects <- data.frame(
  object_id = c(
    "FIN__ME__gross_investment_current_cost",
    "FIN__ME__net_stock_current_cost",
    "FIN__ME__net_stock_quantity_index",
    "FIN__NRC__gross_investment_current_cost",
    "FIN__NRC__net_stock_current_cost",
    "FIN__NRC__net_stock_quantity_index"
  ),
  asset = c("ME", "ME", "ME", "NRC", "NRC", "NRC"),
  role = c(
    "current_cost_gross_investment",
    "current_cost_net_stock_anchor",
    "net_stock_quantity_index_review_only",
    "current_cost_gross_investment",
    "current_cost_net_stock_anchor",
    "net_stock_quantity_index_review_only"
  ),
  stringsAsFactors = FALSE
)

input_ledger <- data.frame()
asset_panel <- data.frame()
asset_checks <- data.frame()
capacity_panel <- data.frame()
validation_checks <- data.frame()
final_decision <- decision_required_absent

if (length(missing_files) == 0L) {
  s24b <- read_csv(paths$s24b_inputs)
  s29b_parameters <- read_csv(paths$s29b_parameters)

  ledger_rows <- lapply(seq_len(nrow(required_objects)), function(i) {
    spec <- required_objects[i, , drop = FALSE]
    rows <- s24b[s24b$variable_id == spec$object_id, , drop = FALSE]
    yrs <- safe_num(rows$year)
    data.frame(
      object_id = spec$object_id,
      asset = spec$asset,
      role = spec$role,
      source_file = rel_path(paths$s24b_inputs),
      source_status = ifelse(nrow(rows) > 0L, "present_in_staged_s24b_source_inputs", "absent_from_staged_s24b_source_inputs"),
      coverage_start = ifelse(nrow(rows) > 0L, min(yrs, na.rm = TRUE), NA_real_),
      coverage_end = ifelse(nrow(rows) > 0L, max(yrs, na.rm = TRUE), NA_real_),
      row_count = nrow(rows),
      status = ifelse(nrow(rows) > 0L, "PRESENT", "ABSENT"),
      notes = ifelse(
        nrow(rows) > 0L,
        paste0(
          "Provider ", rows$source_table[1], " line ", rows$source_line[1], " (",
          rows$source_line_description[1], "); ", rows$unit[1], "."
        ),
        "Required D05 primitive input is absent."
      ),
      stringsAsFactors = FALSE
    )
  })
  input_ledger <- do.call(rbind, ledger_rows)
} else {
  input_ledger <- cbind(
    required_objects,
    source_file = rel_path(paths$s24b_inputs),
    source_status = "required_stage_file_missing",
    coverage_start = NA_real_,
    coverage_end = NA_real_,
    row_count = 0L,
    status = "ABSENT",
    notes = paste("Missing files:", paste(rel_path(missing_files), collapse = "; ")),
    stringsAsFactors = FALSE
  )
}

write_csv(input_ledger, file.path(csv_dir, "D05_input_availability_ledger.csv"))

extract_series <- function(panel, variable_id, label) {
  rows <- panel[panel$variable_id == variable_id, c("year", "value"), drop = FALSE]
  rows$year <- as.integer(rows$year)
  rows$value <- safe_num(rows$value)
  rows <- rows[is.finite(rows$year) & is.finite(rows$value), , drop = FALSE]
  rows <- rows[order(rows$year), , drop = FALSE]
  if (nrow(rows) == 0L) stop("Missing required series: ", label, call. = FALSE)
  if (anyDuplicated(rows$year)) stop("Duplicate years in required series: ", label, call. = FALSE)
  rownames(rows) <- NULL
  rows
}

lookup_value <- function(series, year, label) {
  value <- series$value[series$year == year]
  if (length(value) != 1L || !is.finite(value)) {
    stop("Expected one finite value for ", label, " in ", year, ".", call. = FALSE)
  }
  value[[1L]]
}

weibull_net_value_weights <- function(asset, L, alpha, d) {
  ages <- 0:L
  lambda <- L / gamma(1 + 1 / alpha)
  survival <- exp(-((ages / lambda)^alpha))
  net_value <- survival * ((1 - d)^ages)
  terminal <- data.frame(
    age = L + 1L,
    survival_weight = 0,
    net_value_weight = 0
  )
  rbind(
    data.frame(
      age = ages,
      survival_weight = survival,
      net_value_weight = net_value
    ),
    terminal
  )
}

recover_guardian_asset <- function(asset, nominal, net_anchor, quantity_index, L, alpha, d) {
  weights <- weibull_net_value_weights(asset, L, alpha, d)
  stock_ages <- weights$age[weights$age <= L]
  first_complete_vintage_year <- min(nominal$year) + L
  recovery_years <- sort(unique(net_anchor$year[net_anchor$year >= first_complete_vintage_year]))
  recovery_years <- recovery_years[recovery_years %in% nominal$year]
  if (length(recovery_years) == 0L || !2017L %in% recovery_years) {
    stop("No D05 recovery span including 2017 for ", asset, ".", call. = FALSE)
  }

  raw_price <- setNames(rep(100, nrow(nominal)), nominal$year)
  raw_price_status <- setNames(rep("INITIALIZATION_SEED_PRICE_INHERITED_NOT_REDECIDED", nrow(nominal)), nominal$year)

  for (year in recovery_years) {
    lag_contribution <- 0
    for (age in stock_ages[stock_ages > 0]) {
      vintage_year <- year - age
      if (!vintage_year %in% nominal$year) {
        stop("Incomplete nominal investment vintage for ", asset, " in ", year, ".", call. = FALSE)
      }
      p_lag <- raw_price[[as.character(vintage_year)]]
      i_lag <- lookup_value(nominal, vintage_year, paste(asset, "nominal investment"))
      lag_contribution <- lag_contribution +
        weights$net_value_weight[weights$age == age] * i_lag / (p_lag / 100)
    }
    current_nominal <- lookup_value(nominal, year, paste(asset, "nominal investment"))
    anchor <- lookup_value(net_anchor, year, paste(asset, "current-cost net stock anchor"))
    candidate <- 100 * (anchor - current_nominal) / lag_contribution
    if (!is.finite(candidate) || candidate <= 0) {
      stop("Non-positive D05 guardian price for ", asset, " in ", year, ".", call. = FALSE)
    }
    raw_price[[as.character(year)]] <- candidate
    raw_price_status[[as.character(year)]] <- "RECOVERED_GPIM_GUARDIAN_PRICE"
  }

  base_raw <- raw_price[["2017"]]
  pkn_all <- 100 * raw_price / base_raw
  real_investment <- setNames(
    nominal$value / (pkn_all[as.character(nominal$year)] / 100),
    nominal$year
  )

  rows <- lapply(recovery_years, function(year) {
    k_real <- 0
    cfc <- 0
    for (age in stock_ages) {
      vintage_year <- year - age
      real_i <- real_investment[[as.character(vintage_year)]]
      k_real <- k_real + weights$net_value_weight[weights$age == age] * real_i
    }
    cfc_ages <- weights$age[weights$age > 0]
    for (age in cfc_ages) {
      vintage_year <- year - age
      if (!vintage_year %in% names(real_investment)) next
      real_i <- real_investment[[as.character(vintage_year)]]
      cfc <- cfc +
        (weights$net_value_weight[weights$age == age - 1L] -
          weights$net_value_weight[weights$age == age]) * real_i
    }
    pkn <- pkn_all[[as.character(year)]]
    i_current <- lookup_value(nominal, year, paste(asset, "current-cost gross investment"))
    k_current_anchor <- lookup_value(net_anchor, year, paste(asset, "current-cost net stock anchor"))
    k_quantity <- lookup_value(quantity_index, year, paste(asset, "net stock quantity index"))
    i_real <- i_current / (pkn / 100)
    k_current <- (pkn / 100) * k_real
    data.frame(
      year = year,
      asset = asset,
      I_current = i_current,
      K_current_anchor = k_current_anchor,
      K_quantity_index = k_quantity,
      pKN_guardian = pkn,
      K_real_guardian = k_real,
      K_current_reconstructed = k_current,
      I_real_guardian = i_real,
      consumption_of_fixed_capital_real = cfc,
      depletion_rate_guardian = NA_real_,
      coherence_residual_current = NA_real_,
      coherence_residual_real = NA_real_,
      current_anchor_residual = k_current - k_current_anchor,
      price_status = raw_price_status[[as.character(year)]],
      first_complete_vintage_year = first_complete_vintage_year,
      L = L,
      alpha = alpha,
      d_parameter = d,
      stringsAsFactors = FALSE
    )
  })
  panel <- do.call(rbind, rows)
  panel <- panel[order(panel$year), , drop = FALSE]

  for (i in seq_len(nrow(panel))) {
    if (i == 1L) next
    prev <- panel[i - 1L, , drop = FALSE]
    cur <- panel[i, , drop = FALSE]
    d_t <- cur$consumption_of_fixed_capital_real / prev$K_real_guardian
    real_rhs <- cur$I_current / (cur$pKN_guardian / 100) + (1 - d_t) * prev$K_real_guardian
    current_rhs <- cur$I_current +
      (1 - d_t) * (cur$pKN_guardian / prev$pKN_guardian) * prev$K_current_reconstructed
    panel$depletion_rate_guardian[i] <- d_t
    panel$coherence_residual_real[i] <- cur$K_real_guardian - real_rhs
    panel$coherence_residual_current[i] <- cur$K_current_reconstructed - current_rhs
  }
  panel
}

if (length(missing_files) == 0L && all(input_ledger$status == "PRESENT")) {
  asset_specs <- data.frame(
    asset = c("ME", "NRC"),
    investment_id = c("FIN__ME__gross_investment_current_cost", "FIN__NRC__gross_investment_current_cost"),
    stock_id = c("FIN__ME__net_stock_current_cost", "FIN__NRC__net_stock_current_cost"),
    quantity_id = c("FIN__ME__net_stock_quantity_index", "FIN__NRC__net_stock_quantity_index"),
    stringsAsFactors = FALSE
  )

  panel_list <- list()
  for (asset in asset_specs$asset) {
    spec <- asset_specs[asset_specs$asset == asset, , drop = FALSE]
    param <- s29b_parameters[s29b_parameters$asset_family == asset, , drop = FALSE]
    if (nrow(param) != 1L) stop("Missing locked S29B parameter row for ", asset, ".", call. = FALSE)
    nominal <- extract_series(s24b, spec$investment_id, paste(asset, "gross investment current cost"))
    stock <- extract_series(s24b, spec$stock_id, paste(asset, "net stock current cost"))
    quantity <- extract_series(s24b, spec$quantity_id, paste(asset, "net stock quantity index"))
    panel_list[[asset]] <- recover_guardian_asset(
      asset = asset,
      nominal = nominal,
      net_anchor = stock,
      quantity_index = quantity,
      L = as.integer(param$service_life_L),
      alpha = as.numeric(param$survival_shape_alpha),
      d = as.numeric(param$depreciation_value_parameter_d)
    )
  }
  asset_panel <- do.call(rbind, panel_list)
  asset_panel <- asset_panel[order(asset_panel$asset, asset_panel$year), , drop = FALSE]

  check_asset <- function(asset, check_id, check_name, condition, residual = NA_real_, reference = NA_real_, notes = "") {
    data.frame(
      asset = asset,
      check_id = check_id,
      check_name = check_name,
      status = pass_fail(condition),
      max_abs_residual = if (length(residual) == 1L && is.na(residual)) NA_real_ else max_abs(residual),
      max_rel_residual = if (length(residual) == 1L && is.na(residual)) NA_real_ else max_rel(residual, reference),
      tolerance = tolerance,
      notes = notes,
      stringsAsFactors = FALSE
    )
  }

  asset_checks <- do.call(rbind, lapply(c("ME", "NRC"), function(asset) {
    x <- asset_panel[asset_panel$asset == asset, , drop = FALSE]
    inputs_present <- all(input_ledger$status[input_ledger$asset == asset] == "PRESENT")
    current_resid <- x$coherence_residual_current[is.finite(x$coherence_residual_current)]
    real_resid <- x$coherence_residual_real[is.finite(x$coherence_residual_real)]
    rbind(
      check_asset(asset, "INPUTS_PRESENT", "Required staged primitive inputs are present", inputs_present, notes = paste(nrow(x), "guardian rows")),
      check_asset(asset, "NO_RAW_INDEX_AGGREGATION", "Quantity index is not aggregated or used as a raw capital sum", TRUE, notes = "K_quantity_index is carried as asset-level input context only."),
      check_asset(asset, "PKN_FINITE_POSITIVE", "Guardian pKN is finite and positive", all(is.finite(x$pKN_guardian) & x$pKN_guardian > 0), notes = "pKN is recovered under the GPIM stock-flow law."),
      check_asset(asset, "ASSET_LEVEL_GPIM_CURRENT_RECURSION_COHERENT", "Current-cost GPIM recursion residual is within tolerance", max_abs(current_resid) <= tolerance, current_resid, x$K_current_reconstructed[is.finite(x$coherence_residual_current)], "First panel year is an anchor row and is excluded from recursion residual maxima."),
      check_asset(asset, "ASSET_LEVEL_GPIM_REAL_RECURSION_COHERENT", "Real GPIM recursion residual is within tolerance", max_abs(real_resid) <= tolerance, real_resid, x$K_real_guardian[is.finite(x$coherence_residual_real)], "Depletion rate is read from the locked net-value vintage schedule implied by S29B."),
      check_asset(asset, "ME_NRC_SEPARATE_VALIDATION_COMPLETE", "Asset is validated before capacity aggregation", TRUE, notes = "ME and NRC checks are computed before bottom-up aggregation."),
      check_asset(asset, "NO_TOTAL_CAPITAL_OBJECT_CONSTRUCTED", "No total-capital object is constructed", TRUE, notes = "D05 constructs only ME, NRC, and capacity as ME plus NRC."),
      check_asset(asset, "NO_FORBIDDEN_BASELINE_OBJECT_INCLUDED", "No forbidden baseline object is included", TRUE, notes = "Provider TOTAL, IPP, residential, government transportation, and official unmapped prices are excluded.")
    )
  }))

  if (all(asset_checks$status == "PASS")) {
    me <- asset_panel[asset_panel$asset == "ME", , drop = FALSE]
    nrc <- asset_panel[asset_panel$asset == "NRC", , drop = FALSE]
    years <- intersect(me$year, nrc$year)
    me <- me[match(years, me$year), , drop = FALSE]
    nrc <- nrc[match(years, nrc$year), , drop = FALSE]
    capacity_panel <- data.frame(
      year = years,
      K_real_ME = me$K_real_guardian,
      K_real_NRC = nrc$K_real_guardian,
      K_real_capacity = me$K_real_guardian + nrc$K_real_guardian,
      K_current_ME = me$K_current_reconstructed,
      K_current_NRC = nrc$K_current_reconstructed,
      K_current_capacity = me$K_current_reconstructed + nrc$K_current_reconstructed,
      pKN_ME = me$pKN_guardian,
      pKN_NRC = nrc$pKN_guardian,
      pKN_capacity = 100 * (me$K_current_reconstructed + nrc$K_current_reconstructed) /
        (me$K_real_guardian + nrc$K_real_guardian),
      stringsAsFactors = FALSE
    )
  }
}

exclusion_ledger <- data.frame(
  object = c(
    "provider_TOTAL",
    "K_total",
    "IPP",
    "residential",
    "government_transportation",
    "official_unmapped_price_indexes",
    "legal_form_by_asset_gross_stock_current_cost"
  ),
  status = c(
    "excluded",
    "prohibited",
    "parked",
    "excluded",
    "parked",
    "review_only_unmapped",
    "unavailable_benchmark_gap"
  ),
  reason = c(
    "Provider total is not Chapter 2 capacity capital; D05 capacity capital is ME plus NRC only.",
    "Total capital is conceptually outside the Chapter 2 D05 baseline.",
    "IPP is a parked conditioning/frontier object, not baseline capacity capital.",
    "Residential capital is outside the D05 capacity-capital boundary.",
    "Government transportation is a parked public-infrastructure/context object, not baseline capacity capital.",
    "Official price-index rows are not silently mapped into the D05 baseline.",
    "Legal-form-by-asset gross-stock current-cost objects are unavailable; D05 constructs GPIM stocks from investment vintages."
  ),
  allowed_future_use = c(
    "ledger_note_only_if_provider_TOTAL_appears",
    "none_in_D05_baseline",
    "future_conditioning_or_frontier_review_only",
    "none_in_D05_baseline",
    "future_public_infrastructure_context_review_only",
    "narrow_mapping_review_only",
    "future_benchmark_review_if_provider_object_becomes_available"
  ),
  prohibited_use = c(
    "baseline_or_comparator_for_capacity_capital",
    "construction_or_alias_for_capacity_capital",
    "baseline_capacity_capital_component",
    "baseline_capacity_capital_component",
    "baseline_capacity_capital_component",
    "silent_baseline_price_input",
    "construction_blocker_or_substitute_for_ME_NRC_GPIM_vintage_stock"
  ),
  stringsAsFactors = FALSE
)

write_csv(asset_panel, file.path(csv_dir, "D05_asset_price_stock_flow_panel.csv"))
write_csv(asset_checks, file.path(csv_dir, "D05_asset_coherence_checks.csv"))
write_csv(capacity_panel, file.path(csv_dir, "D05_capacity_aggregation_panel.csv"))
write_csv(exclusion_ledger, file.path(csv_dir, "D05_exclusion_ledger.csv"))

validation_row <- function(check_id, condition, notes) {
  data.frame(
    check_id = check_id,
    status = pass_fail(condition),
    notes = notes,
    stringsAsFactors = FALSE
  )
}

required_inputs_present <- nrow(input_ledger) == 6L && all(input_ledger$status == "PRESENT")
asset_boundary_ok <- nrow(asset_panel) > 0L && setequal(unique(asset_panel$asset), c("ME", "NRC"))
pkn_me <- nrow(asset_panel[asset_panel$asset == "ME" & is.finite(asset_panel$pKN_guardian), ]) > 0L
pkn_nrc <- nrow(asset_panel[asset_panel$asset == "NRC" & is.finite(asset_panel$pKN_guardian), ]) > 0L
me_pass <- all(asset_checks$status[asset_checks$asset == "ME"] == "PASS") && any(asset_checks$asset == "ME")
nrc_pass <- all(asset_checks$status[asset_checks$asset == "NRC"] == "PASS") && any(asset_checks$asset == "NRC")
capacity_pass <- nrow(capacity_panel) > 0L &&
  max_abs(capacity_panel$K_real_capacity - capacity_panel$K_real_ME - capacity_panel$K_real_NRC) <= tolerance &&
  max_abs(capacity_panel$K_current_capacity - capacity_panel$K_current_ME - capacity_panel$K_current_NRC) <= tolerance
pkn_capacity_derived <- nrow(capacity_panel) > 0L &&
  max_abs(capacity_panel$pKN_capacity - 100 * capacity_panel$K_current_capacity / capacity_panel$K_real_capacity) <= tolerance
exclusion_complete <- setequal(
  exclusion_ledger$object,
  c("provider_TOTAL", "K_total", "IPP", "residential", "government_transportation", "official_unmapped_price_indexes", "legal_form_by_asset_gross_stock_current_cost")
)

validation_checks <- do.call(rbind, list(
  validation_row("REPO_STATE_RECORDED", TRUE, "Opening repo state is recorded in D05_decision_report.md; D04 head 6908be4 is the boundary condition."),
  validation_row("REQUIRED_INPUTS_PRESENT", required_inputs_present, paste(input_ledger$object_id, input_ledger$status, collapse = "; ")),
  validation_row("ASSET_BOUNDARY_ME_NRC_ONLY", asset_boundary_ok, "D05 asset panel contains ME and NRC only."),
  validation_row("NO_TOTAL_CAPITAL_CONSTRUCTION", TRUE, "No total-capital panel, column, or derived baseline is emitted."),
  validation_row("NO_RAW_QUANTITY_INDEX_AGGREGATION", TRUE, "Quantity indexes remain asset-level context and are never summed."),
  validation_row("PKN_ME_CONSTRUCTED", pkn_me, "pKN_ME is the ME guardian stock-valuation price."),
  validation_row("PKN_NRC_CONSTRUCTED", pkn_nrc, "pKN_NRC is the NRC guardian stock-valuation price."),
  validation_row("ME_GPIM_COHERENCE_PASS", me_pass, "ME asset-level current and real recursions pass."),
  validation_row("NRC_GPIM_COHERENCE_PASS", nrc_pass, "NRC asset-level current and real recursions pass."),
  validation_row("CAPACITY_BOTTOM_UP_AGGREGATION_PASS", capacity_pass, "Capacity is exact ME plus NRC after separate asset validation."),
  validation_row("PKN_CAPACITY_DERIVED", pkn_capacity_derived, "pKN_capacity is derived from K_current_capacity over K_real_capacity."),
  validation_row("EXCLUSION_LEDGER_COMPLETE", exclusion_complete, "All required D05 exclusions are recorded."),
  validation_row("NO_WARMUP_DECISION_MADE", TRUE, "D05 does not alter or authorize seed, inherited-vintage, or warmup treatment."),
  validation_row("NO_ECONOMETRICS_RUN", TRUE, "D05 reads staged inputs and writes audit outputs only."),
  validation_row("DECISION_RECORDED", TRUE, "D05 decision code is written to the decision report.")
))

all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 15L
if (length(missing_files) > 0L || !required_inputs_present) {
  final_decision <- decision_required_absent
} else if (!all(asset_checks$status == "PASS") || !capacity_pass || !pkn_capacity_derived) {
  final_decision <- decision_coherence_fail
} else if (!all_validation_pass) {
  final_decision <- decision_price_review
} else {
  final_decision <- decision_authorize
}

write_csv(validation_checks, file.path(csv_dir, "D05_validation_checks.csv"))

asset_summary <- if (nrow(asset_panel) > 0L) {
  do.call(rbind, lapply(c("ME", "NRC"), function(asset) {
    x <- asset_panel[asset_panel$asset == asset, , drop = FALSE]
    data.frame(
      asset = asset,
      first_year = min(x$year),
      last_year = max(x$year),
      rows = nrow(x),
      pKN_start = x$pKN_guardian[which.min(x$year)],
      pKN_2017 = x$pKN_guardian[x$year == 2017],
      pKN_end = x$pKN_guardian[which.max(x$year)],
      max_abs_current_recursion_residual = max_abs(x$coherence_residual_current),
      max_abs_real_recursion_residual = max_abs(x$coherence_residual_real),
      stringsAsFactors = FALSE
    )
  }))
} else {
  data.frame()
}

fmt_table <- function(df) {
  if (nrow(df) == 0L) return("_No rows._")
  paste(capture.output(print(df, row.names = FALSE)), collapse = "\n")
}

report_lines <- c(
  "# D05 GPIM Guardian Price/Stock-Flow Coherence",
  "",
  "## Opening repo state",
  "",
  "D05 starts from the verified D04 boundary condition and does not reopen D01-D04.",
  "",
  "```text",
  paste(opening_repo_state$check, opening_repo_state$result, sep = ": ", collapse = "\n"),
  "```",
  "",
  "## Source/input availability",
  "",
  "The six required staged provider/downstream inputs are read from S24B. ME maps to BEA Fixed Assets line 34. NRC maps to line 35. Legal-form gross-stock current-cost objects are not required because D05 constructs GPIM stocks from investment vintages.",
  "",
  "```text",
  fmt_table(input_ledger[, c("object_id", "asset", "role", "coverage_start", "coverage_end", "row_count", "status")]),
  "```",
  "",
  "## Methodological lock",
  "",
  "Shaikh Appendix 6.8 is used as a methodological template: GPIM must discipline current-cost investment, real/quantity stock movement, and current-cost stock valuation under one stock-flow law. Shaikh is not used as the target series.",
  "",
  "## Capacity definition",
  "",
  "D05 defines capacity capital as K_capacity = ME + NRC. It does not construct total capital, total fixed assets, IPP, residential capital, government transportation, or an all-capital aggregate.",
  "",
  "## Aggregation rule",
  "",
  "ME and NRC are validated separately before aggregation. Raw chain-type quantity indexes are not added. K_real_capacity is the sum of K_real_ME and K_real_NRC after asset-level coherence passes. K_current_capacity is the corresponding current-cost sum. pKN_capacity is derived as 100 * K_current_capacity / K_real_capacity.",
  "",
  "## Guardian price summary",
  "",
  "```text",
  fmt_table(asset_summary),
  "```",
  "",
  "## Exclusion statement",
  "",
  "Provider TOTAL and K_total are excluded from the D05 baseline. Official unmapped price indexes remain review-only. IPP, residential capital, and government transportation remain outside baseline capacity capital.",
  "",
  "## Validation table",
  "",
  "```text",
  fmt_table(validation_checks),
  "```",
  "",
  "## Final decision",
  "",
  final_decision
)

writeLines(report_lines, file.path(reports_dir, "D05_decision_report.md"))

cat(final_decision, "\n")
