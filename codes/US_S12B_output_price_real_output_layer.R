#!/usr/bin/env Rscript

# S12B constructs only the locked output-price and NFC real-output layer from
# validated S12A observations. It performs no discovery, live fetch, GPIM,
# distribution adjustment, capacity construction, or econometric estimation.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S12B from the downstream repository root.", call. = FALSE)
}

abort <- function(message) stop(message, call. = FALSE)
require_condition <- function(condition, message) {
  if (!isTRUE(condition)) abort(message)
}
read_csv <- function(path) {
  read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

input_paths <- c(
  source_observations = file.path(
    repo_root, "output", "US", "S12A_OBSERVATION_PAYLOAD_IMPORT",
    "csv", "S12A_source_observations_long.csv"
  ),
  price_observations = file.path(
    repo_root, "output", "US", "S12A_OBSERVATION_PAYLOAD_IMPORT",
    "csv", "S12A_price_proxy_observations_long.csv"
  ),
  series_availability = file.path(
    repo_root, "output", "US", "S12A_OBSERVATION_PAYLOAD_IMPORT",
    "csv", "S12A_required_series_availability.csv"
  ),
  s12a_validation = file.path(
    repo_root, "output", "US", "S12A_OBSERVATION_PAYLOAD_IMPORT",
    "csv", "S12A_observation_import_validation.csv"
  ),
  price_registry = file.path(
    repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_READINESS",
    "csv", "S12_price_object_construction_registry.csv"
  ),
  construction_plan = file.path(
    repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_CONSTRUCTION",
    "csv", "S12_construction_plan_ledger.csv"
  )
)
missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  abort(
    paste0(
      "Missing S12B inputs:\n- ",
      paste(unname(missing_inputs), collapse = "\n- ")
    )
  )
}

source_observations <- read_csv(input_paths[["source_observations"]])
price_observations <- read_csv(input_paths[["price_observations"]])
series_availability <- read_csv(input_paths[["series_availability"]])
s12a_validation <- read_csv(input_paths[["s12a_validation"]])
price_registry <- read_csv(input_paths[["price_registry"]])
construction_plan <- read_csv(input_paths[["construction_plan"]])

require_condition(
  nrow(s12a_validation) > 0L &&
    all(s12a_validation$result == "PASS"),
  "S12A validation is not fully PASS."
)
require_condition(
  nrow(series_availability) > 0L &&
    all(tolower(series_availability$ready_for_construction) == "true"),
  "One or more S12A required observation inputs are not ready."
)

expected_price_names <- c(
  "P_Y_NFC_GVA_IMPLICIT_SOURCE",
  "P_Y_NFC_GVA_T115_VALIDATION",
  "P_Y_PROXY_GDP_IMPLICIT",
  "P_Y_PROXY_NONFARM_BUSINESS_OUTPUT",
  "P_Y_PROXY_BUSINESS_OUTPUT",
  "P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS",
  "P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE",
  "P_Y_PROXY_GDPBYIND_VA_MANUFACTURING"
)
expected_real_names <- c(
  "Y_REAL_NFC_GVA_BASELINE",
  "Y_REAL_NFC_GVA_PROXY_GDP_IMPLICIT",
  "Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT",
  "Y_REAL_NFC_GVA_PROXY_BUSINESS_OUTPUT",
  "Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT_BLS",
  "Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_FINANCE_INSURANCE",
  "Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_MANUFACTURING"
)

require_condition(
  setequal(price_registry$variable_name, expected_price_names),
  "The S12 price registry does not match the locked eight-object hierarchy."
)
require_condition(
  setequal(unique(price_observations$price_variable_name),
           expected_price_names),
  "S12A price observations do not cover all eight locked objects."
)
plan_price_rows <- construction_plan[
  construction_plan$target_variable %in% expected_price_names, , drop = FALSE
]
plan_real_rows <- construction_plan[
  construction_plan$target_variable %in% expected_real_names, , drop = FALSE
]
require_condition(
  setequal(plan_price_rows$target_variable, expected_price_names) &&
    all(plan_price_rows$allowed_status %in% c(
      "construction_ready", "validation_ready", "robustness_ready"
    )),
  "The S12 plan does not authorize the locked price-object layer."
)
require_condition(
  setequal(plan_real_rows$target_variable, expected_real_names) &&
    all(plan_real_rows$allowed_status %in% c(
      "construction_planned", "robustness_planned"
    )),
  "The S12 plan does not authorize the locked NFC real-output layer."
)

output_root <- file.path(
  repo_root, "output", "US", "S12B_OUTPUT_PRICE_REAL_OUTPUT"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

price_long_path <- file.path(csv_dir, "S12B_output_price_objects_long.csv")
real_long_path <- file.path(csv_dir, "S12B_real_output_objects_long.csv")
price_validation_path <- file.path(
  csv_dir, "S12B_output_price_validation.csv"
)
construction_validation_path <- file.path(
  csv_dir, "S12B_construction_validation.csv"
)
report_path <- file.path(md_dir, "S12B_OUTPUT_PRICE_REAL_OUTPUT.md")

numeric_value <- function(x) suppressWarnings(as.numeric(x))

# Rebuild the baseline source object from the two source rows rather than
# carrying forward the already-derived S12A price observation.
nominal_source <- source_observations[
  source_observations$source_variable_id == "NFC_GVA",
  ,
  drop = FALSE
]
real_source <- source_observations[
  source_observations$source_variable_id == "NFC_GVA_REAL_T11400_L41",
  ,
  drop = FALSE
]
require_condition(
  nrow(nominal_source) > 0L && nrow(real_source) > 0L,
  "T11400 NFC nominal or real source observations are missing."
)

nominal_source$value <- numeric_value(nominal_source$value)
nominal_source$unit_mult <- as.integer(nominal_source$unit_mult)
real_source$value <- numeric_value(real_source$value)
real_source$unit_mult <- as.integer(real_source$unit_mult)

nominal_units <- data.frame(
  year = as.integer(nominal_source$year),
  nominal_gva_value = nominal_source$value *
    10^(nominal_source$unit_mult - 6L),
  stringsAsFactors = FALSE
)
real_units <- data.frame(
  year = as.integer(real_source$year),
  direct_real_gva_value = real_source$value *
    10^(real_source$unit_mult - 6L),
  stringsAsFactors = FALSE
)
baseline_components <- merge(
  nominal_units, real_units, by = "year", all = FALSE
)
baseline_components$price_native <- 100 *
  baseline_components$nominal_gva_value /
  baseline_components$direct_real_gva_value

price_observations$value <- numeric_value(price_observations$value)
price_observations$year <- as.integer(price_observations$year)

annualize_price <- function(variable_name) {
  rows <- price_observations[
    price_observations$price_variable_name == variable_name,
    ,
    drop = FALSE
  ]
  require_condition(
    nrow(rows) > 0L,
    paste0("No S12A price observations for ", variable_name, ".")
  )
  if (variable_name == "P_Y_NFC_GVA_IMPLICIT_SOURCE") {
    annual <- data.frame(
      year = baseline_components$year,
      value_native = baseline_components$price_native,
      source_title = paste(
        "NFC implicit GVA deflator from T11400 current-dollar",
        "and chained-dollar GVA"
      ),
      native_unit = "Index ratio x100",
      annualization_note = "Reconstructed from T11400 lines 17 and 41.",
      stringsAsFactors = FALSE
    )
  } else {
    if (rows$frequency[1L] == "Quarterly") {
      annual_values <- aggregate(
        value ~ year,
        rows,
        FUN = function(x) {
          if (sum(is.finite(x)) == 4L) mean(x, na.rm = TRUE) else NA_real_
        }
      )
      annual_values <- annual_values[
        is.finite(annual_values$value), , drop = FALSE
      ]
    } else {
      annual_values <- aggregate(
        value ~ year,
        rows,
        FUN = function(x) mean(x, na.rm = TRUE)
      )
    }
    annual <- data.frame(
      year = annual_values$year,
      value_native = annual_values$value,
      source_title = rows$source_description[1L],
      native_unit = rows$unit[1L],
      annualization_note = if (rows$frequency[1L] == "Quarterly") {
        paste(
          "Source-native quarterly index annualized by calendar-year",
          "arithmetic mean; incomplete calendar years are excluded."
        )
      } else {
        "Source-native annual observation retained."
      },
      stringsAsFactors = FALSE
    )
  }
  base_value <- annual$value_native[annual$year == 2017L]
  require_condition(
    length(base_value) == 1L && is.finite(base_value) && base_value > 0,
    paste0(variable_name, " lacks a valid 2017 normalization value.")
  )
  annual$value_index_2017 <- 100 * annual$value_native / base_value
  annual
}

price_parts <- vector("list", length(expected_price_names))
for (i in seq_along(expected_price_names)) {
  variable_name <- expected_price_names[i]
  annual <- annualize_price(variable_name)
  registry <- price_registry[
    price_registry$variable_name == variable_name, , drop = FALSE
  ]
  require_condition(nrow(registry) == 1L, "Duplicate/missing registry row.")
  price_parts[[i]] <- data.frame(
    variable_name = variable_name,
    object_family = registry$object_family,
    source_role = registry$source_role,
    baseline_or_robustness = registry$baseline_or_robustness,
    year = annual$year,
    value_native = annual$value_native,
    value_index_2017 = annual$value_index_2017,
    native_unit = annual$native_unit,
    normalized_unit = "Index 2017=100",
    source_system = registry$source_system,
    source_table_or_series = registry$source_table_or_series,
    source_line_or_series_id = registry$source_line_or_series_id,
    source_title = annual$source_title,
    source_boundary = registry$source_boundary,
    allowed_use = registry$allowed_use,
    not_allowed_use = registry$not_allowed_use,
    construction_formula_or_rule = registry$construction_formula_or_rule,
    limitations = registry$limitations,
    status = registry$status,
    notes = paste(registry$notes, annual$annualization_note, sep = " | "),
    stringsAsFactors = FALSE
  )
}
price_long <- do.call(rbind, price_parts)
price_long <- price_long[
  order(match(price_long$variable_name, expected_price_names),
        price_long$year),
  ,
  drop = FALSE
]
rownames(price_long) <- NULL

require_condition(
  all(is.finite(price_long$value_native)) &&
    all(is.finite(price_long$value_index_2017)),
  "Output-price layer contains nonfinite values."
)
require_condition(
  all(abs(
    price_long$value_index_2017[price_long$year == 2017L] - 100
  ) < 1e-10),
  "One or more price objects failed 2017 normalization."
)
write.csv(price_long, price_long_path, row.names = FALSE, na = "")

proxy_price_names <- expected_price_names[
  grepl("^P_Y_PROXY_", expected_price_names)
]
proxy_real_names <- sub(
  "^P_Y_PROXY_", "Y_REAL_NFC_GVA_PROXY_", proxy_price_names
)
real_map <- data.frame(
  variable_name = c("Y_REAL_NFC_GVA_BASELINE", proxy_real_names),
  price_object_used = c(
    "P_Y_NFC_GVA_IMPLICIT_SOURCE", proxy_price_names
  ),
  baseline_or_robustness = c("baseline", rep("robustness", 6L)),
  stringsAsFactors = FALSE
)
require_condition(
  setequal(real_map$variable_name, expected_real_names),
  "The NFC real-output naming map is incomplete."
)

real_parts <- vector("list", nrow(real_map))
for (i in seq_len(nrow(real_map))) {
  mapping <- real_map[i, ]
  prices <- price_long[
    price_long$variable_name == mapping$price_object_used,
    c("year", "value_index_2017"),
    drop = FALSE
  ]
  names(prices)[2L] <- "price_index_value"
  constructed <- merge(nominal_units, prices, by = "year", all = FALSE)
  constructed$real_output_value <- constructed$nominal_gva_value /
    (constructed$price_index_value / 100)
  is_baseline <- mapping$baseline_or_robustness == "baseline"
  real_parts[[i]] <- data.frame(
    variable_name = mapping$variable_name,
    object_family = if (is_baseline) "real_output" else "real_output_proxy",
    baseline_or_robustness = mapping$baseline_or_robustness,
    price_object_used = mapping$price_object_used,
    year = constructed$year,
    nominal_gva_value = constructed$nominal_gva_value,
    price_index_value = constructed$price_index_value,
    real_output_value = constructed$real_output_value,
    real_output_unit = "Millions of 2017-price-equivalent dollars",
    source_boundary = "NFC nominal GVA",
    target_boundary = "NFC",
    construction_formula = paste0(
      "NFC current-dollar GVA / (", mapping$price_object_used,
      " normalized to 2017=100 / 100)"
    ),
    allowed_use = if (is_baseline) {
      "baseline NFC real GVA"
    } else {
      "NFC real-output robustness variant only"
    },
    not_allowed_use = if (is_baseline) {
      "do not relabel as CORP or FC real GVA"
    } else {
      "do not relabel as same-boundary CORP/FC real GVA"
    },
    limitations = if (is_baseline) {
      "same-boundary NFC object; benchmarked to the BEA 2017 chained-dollar reference"
    } else {
      price_registry$limitations[
        match(mapping$price_object_used, price_registry$variable_name)
      ]
    },
    status = if (is_baseline) {
      "construction_complete"
    } else {
      "robustness_complete"
    },
    notes = if (is_baseline) {
      "Validated against direct T11400 line 41."
    } else {
      paste(
        "Transparent proxy-deflated NFC GVA; proxy boundary is preserved.",
        "Quarterly proxy indexes, where applicable, use annual arithmetic means."
      )
    },
    stringsAsFactors = FALSE
  )
}
real_long <- do.call(rbind, real_parts)
real_long <- real_long[
  order(match(real_long$variable_name, expected_real_names), real_long$year),
  ,
  drop = FALSE
]
rownames(real_long) <- NULL
require_condition(
  all(is.finite(real_long$real_output_value)) &&
    all(real_long$real_output_value > 0),
  "Real-output layer contains invalid values."
)
write.csv(real_long, real_long_path, row.names = FALSE, na = "")

t115 <- price_long[
  price_long$variable_name == "P_Y_NFC_GVA_T115_VALIDATION",
  c("year", "value_native"),
  drop = FALSE
]
names(t115)[2L] <- "validation_value"
derived <- price_long[
  price_long$variable_name == "P_Y_NFC_GVA_IMPLICIT_SOURCE",
  c("year", "value_native"),
  drop = FALSE
]
names(derived)[2L] <- "constructed_value"
price_validation <- merge(derived, t115, by = "year", all = FALSE)
price_validation$check_id <- "nfc_implicit_vs_t115"
price_validation$reference_object <- "P_Y_NFC_GVA_T115_VALIDATION"
price_validation$absolute_difference <- abs(
  price_validation$constructed_value - price_validation$validation_value
)
price_validation$tolerance <- 0.1
price_validation$result <- ifelse(
  price_validation$absolute_difference <= price_validation$tolerance,
  "PASS", "FAIL"
)
price_validation$notes <- paste(
  "T1.15 line 1 is validation-only and does not replace the",
  "T1.14 source-level derivation."
)
price_validation <- price_validation[
  c(
    "check_id", "year", "constructed_value", "reference_object",
    "validation_value", "absolute_difference", "tolerance", "result",
    "notes"
  )
]
write.csv(
  price_validation, price_validation_path, row.names = FALSE, na = ""
)

baseline_real <- real_long[
  real_long$variable_name == "Y_REAL_NFC_GVA_BASELINE",
  c("year", "real_output_value"),
  drop = FALSE
]
real_validation <- merge(
  baseline_real, real_units, by = "year", all = FALSE
)
real_validation$absolute_difference <- abs(
  real_validation$real_output_value -
    real_validation$direct_real_gva_value
)
real_tolerance <- 0.1

validation <- data.frame(
  check_id = character(),
  validation_rule = character(),
  expected = character(),
  observed = character(),
  result = character(),
  notes = character(),
  stringsAsFactors = FALSE
)
add_check <- function(id, rule, expected, observed, pass, notes = "") {
  validation <<- rbind(
    validation,
    data.frame(
      check_id = id,
      validation_rule = rule,
      expected = as.character(expected),
      observed = as.character(observed),
      result = if (isTRUE(pass)) "PASS" else "FAIL",
      notes = notes,
      stringsAsFactors = FALSE
    )
  )
}

max_price_diff <- max(price_validation$absolute_difference)
max_real_diff <- max(real_validation$absolute_difference)
add_check(
  "baseline_price_components",
  "P_Y_NFC_GVA_IMPLICIT_SOURCE constructed from T11400 lines 17 and 41",
  "97 matched annual observations",
  paste0(nrow(baseline_components), " matched annual observations"),
  nrow(baseline_components) == 97L
)
add_check(
  "baseline_price_t115",
  "P_Y_NFC_GVA_IMPLICIT_SOURCE matches T11500 line 1 within published rounding",
  "maximum absolute difference <= 0.1",
  format(max_price_diff, digits = 8),
  all(price_validation$result == "PASS")
)
add_check(
  "baseline_real_t114",
  "Y_REAL_NFC_GVA_BASELINE matches T11400 line 41 within published rounding",
  "maximum absolute difference <= 0.1 million",
  format(max_real_diff, digits = 8),
  max_real_diff <= real_tolerance
)
add_check(
  "proxy_price_names",
  "All six proxy price objects retain P_Y_PROXY_* names",
  6L,
  sum(grepl("^P_Y_PROXY_", unique(price_long$variable_name))),
  setequal(
    unique(price_long$variable_name[
      price_long$baseline_or_robustness == "robustness"
    ]),
    proxy_price_names
  )
)
add_check(
  "proxy_real_names",
  "All proxy-real-output variants retain Y_REAL_NFC_GVA_PROXY_* names",
  6L,
  sum(grepl("^Y_REAL_NFC_GVA_PROXY_", unique(real_long$variable_name))),
  setequal(
    unique(real_long$variable_name[
      real_long$baseline_or_robustness == "robustness"
    ]),
    proxy_real_names
  )
)
add_check(
  "no_corp_real",
  "No CORP real GVA object constructed",
  "none",
  paste(unique(real_long$variable_name[
    grepl("CORP", real_long$variable_name)
  ]), collapse = "; "),
  !any(grepl("CORP", real_long$variable_name))
)
add_check(
  "no_fc_real",
  "No FC real GVA object constructed",
  "none",
  paste(unique(real_long$variable_name[
    grepl("(^|_)FC(_|$)", real_long$variable_name)
  ]), collapse = "; "),
  !any(grepl("(^|_)FC(_|$)", real_long$variable_name))
)
add_check(
  "no_corp_price",
  "No CORP price object constructed",
  "none",
  paste(unique(price_long$variable_name[
    grepl("CORP", price_long$variable_name)
  ]), collapse = "; "),
  !any(grepl("CORP", price_long$variable_name))
)
add_check(
  "no_fc_price",
  "No FC price object constructed",
  "none",
  paste(unique(price_long$variable_name[
    grepl("(^|_)FC(_|$)", price_long$variable_name)
  ]), collapse = "; "),
  !any(grepl("(^|_)FC(_|$)", price_long$variable_name))
)
add_check(
  "no_chained_residual",
  "No chained-dollar residual subtraction performed",
  "direct T11400 line 41 only",
  "direct T11400 line 41 used",
  TRUE
)
add_check(
  "no_proxy_relabel",
  "No proxy relabeled as CORP/FC GVA deflator",
  "transparent P_Y_PROXY_* names",
  paste(proxy_price_names, collapse = "; "),
  all(grepl("^P_Y_PROXY_", proxy_price_names))
)
add_check(
  "no_faat402_baseline",
  "No FAAt402 baseline use",
  "no FAAt402 input",
  "source tables: T11400, T11500, FRED/BLS, GDPByIndustry",
  !any(grepl("FAAt402", price_long$source_table_or_series))
)
add_check(
  "no_implied_investment",
  "No implied investment baseline use",
  "none",
  "no investment object used",
  !any(grepl("investment", real_long$construction_formula,
             ignore.case = TRUE))
)
add_check(
  "no_gpim",
  "No GPIM stocks constructed",
  "none",
  "output-price and NFC real-output objects only",
  !any(grepl("GPIM", c(price_long$variable_name, real_long$variable_name)))
)
add_check(
  "no_adjusted_distribution",
  "No adjusted distribution variables constructed",
  "none",
  "output-price and NFC real-output objects only",
  !any(grepl("omega|profit|wage|distribution|shaikh",
             c(price_long$variable_name, real_long$variable_name),
             ignore.case = TRUE))
)
add_check(
  "no_econometric_execution",
  "No S20/S21/S22/econometric code run",
  "none",
  "S12B script only",
  TRUE
)
add_check(
  "price_names_exact",
  "Only the eight locked output-price objects exist",
  paste(expected_price_names, collapse = "; "),
  paste(unique(price_long$variable_name), collapse = "; "),
  setequal(unique(price_long$variable_name), expected_price_names)
)
add_check(
  "real_names_exact",
  "Only the seven locked NFC real-output objects exist",
  paste(expected_real_names, collapse = "; "),
  paste(unique(real_long$variable_name), collapse = "; "),
  setequal(unique(real_long$variable_name), expected_real_names)
)
add_check(
  "normalization_2017",
  "Every price object is normalized to 2017=100",
  "all 2017 values equal 100",
  paste(
    format(
      price_long$value_index_2017[price_long$year == 2017L],
      digits = 8
    ),
    collapse = "; "
  ),
  all(abs(
    price_long$value_index_2017[price_long$year == 2017L] - 100
  ) < 1e-10)
)

write.csv(
  validation, construction_validation_path, row.names = FALSE, na = ""
)
require_condition(
  all(price_validation$result == "PASS") &&
    all(validation$result == "PASS"),
  paste0(
    "S12B validation failed:\n- ",
    paste(validation$validation_rule[validation$result == "FAIL"],
          collapse = "\n- ")
  )
)

escape_md <- function(x) {
  x <- gsub("\r|\n", " ", as.character(x))
  gsub("|", "\\|", x, fixed = TRUE)
}
markdown_table <- function(data, columns) {
  header <- paste0("| ", paste(columns, collapse = " | "), " |")
  divider <- paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|")
  body <- apply(data[, columns, drop = FALSE], 1L, function(row) {
    paste0(
      "| ", paste(vapply(row, escape_md, character(1L)),
                   collapse = " | "), " |"
    )
  })
  c(header, divider, body)
}

price_summary <- do.call(
  rbind,
  lapply(expected_price_names, function(id) {
    rows <- price_long[price_long$variable_name == id, , drop = FALSE]
    data.frame(
      variable_name = id,
      role = rows$baseline_or_robustness[1L],
      start_year = min(rows$year),
      end_year = max(rows$year),
      observations = nrow(rows),
      stringsAsFactors = FALSE
    )
  })
)
real_summary <- do.call(
  rbind,
  lapply(expected_real_names, function(id) {
    rows <- real_long[real_long$variable_name == id, , drop = FALSE]
    data.frame(
      variable_name = id,
      price_object_used = rows$price_object_used[1L],
      role = rows$baseline_or_robustness[1L],
      start_year = min(rows$year),
      end_year = max(rows$year),
      observations = nrow(rows),
      stringsAsFactors = FALSE
    )
  })
)

report_lines <- c(
  "# S12B Output Price and Real Output Construction",
  "",
  "## Purpose",
  "",
  paste(
    "S12B constructs the locked annual output-price layer and seven NFC",
    "real-output objects from validated S12A payloads. It creates no capital,",
    "distribution, capacity, utilization, or econometric object."
  ),
  "",
  "## Inherited locks",
  "",
  "- `P_Y_NFC_GVA_IMPLICIT_SOURCE` is the only same-boundary baseline price.",
  "- T1.15 line 1 remains validation-only.",
  "- Six `P_Y_PROXY_*` objects remain robustness-only.",
  "- CORP/FC real-price residuals and proxy relabeling remain prohibited.",
  "- FAAt402, implied investment, GPIM, and adjusted distribution are outside S12B.",
  "",
  "## Inputs",
  "",
  paste0("- S12A source observation rows: ", nrow(source_observations)),
  paste0("- S12A price observation rows: ", nrow(price_observations)),
  paste0("- S12A availability rows ready: ", nrow(series_availability)),
  paste0("- S12A validation checks passed: ", nrow(s12a_validation)),
  "- No live API fetch or source discovery was performed.",
  "",
  "## Output price objects constructed",
  "",
  markdown_table(
    price_summary,
    c("variable_name", "role", "start_year", "end_year", "observations")
  ),
  "",
  paste(
    "All objects preserve native annual values and include a common",
    "`2017=100` normalization. Quarterly BLS indexes are annualized by",
    "calendar-year arithmetic mean before normalization; incomplete years",
    "are excluded."
  ),
  "",
  "## Baseline NFC real output",
  "",
  paste(
    "`Y_REAL_NFC_GVA_BASELINE` uses current-dollar NFC GVA divided by the",
    "reconstructed T1.14 NFC implicit deflator. It matches direct T1.14",
    "line 41 with a maximum absolute difference of",
    paste0(format(max_real_diff, digits = 8), " million.")
  ),
  "",
  "## Robustness real-output variants",
  "",
  markdown_table(
    real_summary,
    c("variable_name", "price_object_used", "role", "start_year",
      "end_year", "observations")
  ),
  "",
  "## Validation results",
  "",
  paste(
    "The NFC implicit deflator matches T1.15 line 1 over",
    nrow(price_validation),
    "years with a maximum absolute difference of",
    paste0(format(max_price_diff, digits = 8), " index points.")
  ),
  markdown_table(
    validation,
    c("validation_rule", "expected", "observed", "result")
  ),
  "",
  "## Prohibited objects preserved",
  "",
  "- No CORP or FC real GVA object was constructed.",
  "- No CORP or FC price object was constructed.",
  "- No chained-dollar residual subtraction was performed.",
  "- No proxy was relabeled as a same-boundary corporate deflator.",
  "- No FAAt402, implied-investment, GPIM, or adjusted-distribution object was used.",
  "- No S20/S21/S22 or econometric code was run.",
  "",
  "## Next construction step",
  "",
  paste(
    "After S12B validates the output-price and NFC real-output layer, the",
    "next step is S12C: capital input preparation for direct nominal ME/NRC",
    "investment, CFC, current-cost validation stocks, and GPIM protocol",
    "definition. S12C must still not run S20/S21/S22 or construct",
    "econometric datasets."
  )
)
writeLines(report_lines, report_path, useBytes = TRUE)

message("S12B output-price and NFC real-output layer passed.")
message("Output-price rows: ", nrow(price_long))
message("Real-output rows: ", nrow(real_long))
message("Price validation years: ", nrow(price_validation))
message("Maximum price validation difference: ", max_price_diff)
message("Maximum baseline real-output difference: ", max_real_diff)
message("Proxy variants: ", paste(proxy_real_names, collapse = ", "))
message("GPIM stocks constructed: no")
message("Adjusted distribution variables constructed: no")
message("S20/S21/S22 run: no")
