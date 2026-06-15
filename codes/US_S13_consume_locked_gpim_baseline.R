#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S13 from the Capacity-Utilization-US_Chile repository root.",
       call. = FALSE)
}

read_csv <- function(path) {
  read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

require_columns <- function(data, columns, label) {
  missing <- setdiff(columns, names(data))
  if (length(missing) > 0L) {
    stop(
      label, " is missing required column(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
}

s12d_c_root <- file.path(
  repo_root, "output", "US", "S12D_C_GPIM_DOWNSTREAM_READINESS_LOCK"
)
s12d_b_root <- file.path(
  repo_root, "output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION"
)
input_paths <- c(
  readiness = file.path(
    s12d_c_root, "csv", "S12D_C_readiness_checks.csv"
  ),
  contract = file.path(
    s12d_c_root, "csv", "S12D_C_consumption_contract.csv"
  ),
  s12d_c_report = file.path(
    s12d_c_root, "md", "S12D_C_GPIM_DOWNSTREAM_READINESS_LOCK.md"
  ),
  prices = file.path(
    s12d_b_root, "csv", "S12D_B_sfc_implicit_price_indexes.csv"
  ),
  flows = file.path(
    s12d_b_root, "csv", "S12D_B_real_investment_flows.csv"
  ),
  stocks = file.path(
    s12d_b_root, "csv", "S12D_B_gpim_stock_panel.csv"
  ),
  role_ledger = file.path(
    s12d_b_root, "csv", "S12D_B_object_role_ledger.csv"
  ),
  s12d_b_validation = file.path(
    s12d_b_root, "csv", "S12D_B_validation_checks.csv"
  ),
  reconstruction = file.path(
    s12d_b_root, "csv", "S12D_B_sfc_reconstruction_checks.csv"
  )
)

missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  stop(
    "Missing required S13 input(s): ",
    paste(unname(missing_inputs), collapse = ", "),
    call. = FALSE
  )
}

readiness <- read_csv(input_paths[["readiness"]])
contract <- read_csv(input_paths[["contract"]])
s12d_c_report_lines <- readLines(
  input_paths[["s12d_c_report"]],
  warn = FALSE,
  encoding = "UTF-8"
)
prices <- read_csv(input_paths[["prices"]])
flows <- read_csv(input_paths[["flows"]])
stocks <- read_csv(input_paths[["stocks"]])
role_ledger <- read_csv(input_paths[["role_ledger"]])
s12d_b_validation <- read_csv(input_paths[["s12d_b_validation"]])
reconstruction <- read_csv(input_paths[["reconstruction"]])

require_columns(
  readiness,
  c("check_id", "status", "evidence"),
  "S12D-C readiness checks"
)
require_columns(
  contract,
  c(
    "asset_block", "object_role", "downstream_consumption_status",
    "allowed_use", "prohibited_use"
  ),
  "S12D-C consumption contract"
)
require_columns(
  prices,
  c(
    "asset_block", "year", "sfc_implicit_price_index_2017_100",
    "price_role"
  ),
  "S12D-B price table"
)
require_columns(
  flows,
  c(
    "asset_block", "year", "nominal_investment_current_millions",
    "real_investment_2017_millions", "source_role", "real_flow_role"
  ),
  "S12D-B real-investment table"
)
require_columns(
  stocks,
  c(
    "asset_block", "year",
    "gross_survival_gpim_stock_2017_millions", "gross_stock_role",
    "net_value_gpim_stock_diagnostic_2017_millions", "net_value_stock_role"
  ),
  "S12D-B stock table"
)
require_columns(
  role_ledger,
  c("asset_block", "object_role", "baseline_use"),
  "S12D-B object-role ledger"
)
require_columns(
  s12d_b_validation,
  c("check_id", "status", "evidence"),
  "S12D-B validation table"
)
require_columns(
  reconstruction,
  c("asset_block", "status"),
  "S12D-B reconstruction table"
)

allowed_assets <- c("ME", "NRC")
allowed_roles <- c(
  "SFC_IMPLICIT_BASELINE_PRICE",
  "DIRECT_NOMINAL_INVESTMENT_CANONICAL",
  "REAL_INVESTMENT_BASELINE",
  "GROSS_SURVIVAL_GPIM_STOCK_BASELINE"
)
excluded_roles <- c(
  "NET_VALUE_GPIM_STOCK_DIAGNOSTIC",
  "FAAt402_VALIDATION_ONLY",
  "OUTPUT_UNIT_TRANSLATION_ROBUSTNESS_ONLY",
  "PRODUCTIVE_EFFICIENCY_NOT_CONSTRUCTED"
)

contract_consumable <- contract[
  contract$downstream_consumption_status == "BASELINE_CONSUMABLE",
  ,
  drop = FALSE
]
contract_key <- paste(
  contract_consumable$asset_block,
  contract_consumable$object_role,
  sep = "::"
)
expected_contract_key <- as.vector(outer(
  allowed_assets,
  allowed_roles,
  paste,
  sep = "::"
))

contract_status <- function(asset, role) {
  hit <- contract$downstream_consumption_status[
    contract$asset_block == asset & contract$object_role == role
  ]
  if (length(hit) != 1L) {
    stop(
      "Expected one S12D-C contract row for ", asset, " / ", role, ".",
      call. = FALSE
    )
  }
  hit
}

variable_id <- function(asset, role) {
  ids <- list(
    SFC_IMPLICIT_BASELINE_PRICE = c(
      ME = "P_K_SFC_ME_2017_100",
      NRC = "P_K_SFC_NRC_2017_100"
    ),
    DIRECT_NOMINAL_INVESTMENT_CANONICAL = c(
      ME = "I_NOMINAL_DIRECT_ME",
      NRC = "I_NOMINAL_DIRECT_NRC"
    ),
    REAL_INVESTMENT_BASELINE = c(
      ME = "I_REAL_GPIM_ME",
      NRC = "I_REAL_GPIM_NRC"
    ),
    GROSS_SURVIVAL_GPIM_STOCK_BASELINE = c(
      ME = "K_GROSS_GPIM_ME",
      NRC = "K_GROSS_GPIM_NRC"
    )
  )
  unname(ids[[role]][[asset]])
}

make_panel_rows <- function(
  source,
  value_column,
  role_column,
  unit,
  source_table,
  notes
) {
  source <- source[source$asset_block %in% allowed_assets, , drop = FALSE]
  data.frame(
    asset_block = source$asset_block,
    year = as.integer(source$year),
    variable_id = mapply(
      variable_id,
      source$asset_block,
      source[[role_column]],
      USE.NAMES = FALSE
    ),
    value = suppressWarnings(as.numeric(source[[value_column]])),
    unit = unit,
    object_role = source[[role_column]],
    downstream_consumption_status = mapply(
      contract_status,
      source$asset_block,
      source[[role_column]],
      USE.NAMES = FALSE
    ),
    construction_stage = "S12D_B_GPIM_BASELINE_CONSTRUCTION",
    source_table = source_table,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

price_panel <- make_panel_rows(
  prices,
  "sfc_implicit_price_index_2017_100",
  "price_role",
  "index_2017_100",
  "S12D_B_sfc_implicit_price_indexes.csv",
  "Locked SFC implicit baseline capital-price index."
)
nominal_panel <- make_panel_rows(
  flows,
  "nominal_investment_current_millions",
  "source_role",
  "current_millions",
  "S12D_B_real_investment_flows.csv",
  "Canonical direct nominal investment consumed without reconstruction."
)
real_panel <- make_panel_rows(
  flows,
  "real_investment_2017_millions",
  "real_flow_role",
  "millions_2017",
  "S12D_B_real_investment_flows.csv",
  "Baseline real investment deflated by the locked SFC price."
)
gross_stock_panel <- make_panel_rows(
  stocks,
  "gross_survival_gpim_stock_2017_millions",
  "gross_stock_role",
  "millions_2017",
  "S12D_B_gpim_stock_panel.csv",
  "Locked gross survival GPIM capital stock."
)

source_panel <- rbind(
  price_panel,
  nominal_panel,
  real_panel,
  gross_stock_panel
)
source_panel <- source_panel[
  order(source_panel$asset_block, source_panel$variable_id, source_panel$year),
  ,
  drop = FALSE
]
rownames(source_panel) <- NULL

audit_rows <- lapply(allowed_assets, function(asset) {
  lapply(allowed_roles, function(role) {
    rows <- source_panel[
      source_panel$asset_block == asset &
        source_panel$object_role == role,
      ,
      drop = FALSE
    ]
    data.frame(
      asset_block = asset,
      object_role = role,
      consumed = ifelse(nrow(rows) > 0L, "yes", "no"),
      source_table = paste(unique(rows$source_table), collapse = "; "),
      variable_ids_created = paste(unique(rows$variable_id), collapse = "; "),
      evidence = paste0(
        nrow(rows), " source-panel rows with status ",
        paste(unique(rows$downstream_consumption_status), collapse = "; "),
        "."
      ),
      stringsAsFactors = FALSE
    )
  })
})
consumption_audit <- do.call(
  rbind,
  unlist(audit_rows, recursive = FALSE)
)
rownames(consumption_audit) <- NULL

validation_checks <- data.frame(
  check_id = character(),
  status = character(),
  evidence = character(),
  stringsAsFactors = FALSE
)
add_check <- function(check_id, passed, evidence) {
  validation_checks <<- rbind(
    validation_checks,
    data.frame(
      check_id = check_id,
      status = if (isTRUE(passed)) "PASS" else "FAIL",
      evidence = as.character(evidence),
      stringsAsFactors = FALSE
    )
  )
}

all_readiness_pass <- nrow(readiness) > 0L &&
  all(readiness$status == "PASS")
add_check(
  "S12D_C_READINESS_ALL_PASS",
  all_readiness_pass,
  paste0(
    sum(readiness$status == "PASS"), "/", nrow(readiness),
    " S12D-C readiness checks are PASS."
  )
)

decision_lines <- trimws(s12d_c_report_lines)
exact_s12d_c_decision <- sum(
  decision_lines == "**AUTHORIZE_NEXT_LAYER_CONSUMPTION**"
) == 1L
add_check(
  "S12D_C_DECISION_AUTHORIZES_CONSUMPTION",
  exact_s12d_c_decision,
  paste0(
    "Exact AUTHORIZE_NEXT_LAYER_CONSUMPTION decision line count: ",
    sum(decision_lines == "**AUTHORIZE_NEXT_LAYER_CONSUMPTION**"), "."
  )
)

contract_present <- nrow(contract) > 0L &&
  all(c("ME", "NRC") %in% contract$asset_block)
add_check(
  "CONSUMPTION_CONTRACT_PRESENT",
  contract_present,
  paste0("Observed ", nrow(contract), " S12D-C contract rows.")
)

only_allowed_contract_roles <- nrow(contract_consumable) == 8L &&
  !anyDuplicated(contract_key) &&
  setequal(contract_key, expected_contract_key)
add_check(
  "ONLY_BASELINE_CONSUMABLE_OBJECTS_USED",
  only_allowed_contract_roles &&
    all(source_panel$object_role %in% allowed_roles) &&
    all(source_panel$downstream_consumption_status ==
          "BASELINE_CONSUMABLE"),
  paste0(
    "Consumed roles: ",
    paste(sort(unique(source_panel$object_role)), collapse = ", "), "."
  )
)

nonbaseline_excluded <- !any(source_panel$object_role %in% excluded_roles) &&
  !any(grepl("NET_VALUE|FAAt402|OUTPUT_UNIT|PRODUCTIVE_EFFICIENCY",
             source_panel$variable_id))
add_check(
  "NON_BASELINE_OBJECTS_EXCLUDED",
  nonbaseline_excluded,
  paste0(
    "Excluded roles found in source panel: ",
    sum(source_panel$object_role %in% excluded_roles), "."
  )
)

panel_assets <- sort(unique(source_panel$asset_block))
add_check(
  "ME_AND_NRC_PRESENT",
  identical(panel_assets, c("ME", "NRC")),
  paste0("Observed asset blocks: ", paste(panel_assets, collapse = ", "), ".")
)

expected_ids <- c(
  "P_K_SFC_ME_2017_100", "P_K_SFC_NRC_2017_100",
  "I_NOMINAL_DIRECT_ME", "I_NOMINAL_DIRECT_NRC",
  "I_REAL_GPIM_ME", "I_REAL_GPIM_NRC",
  "K_GROSS_GPIM_ME", "K_GROSS_GPIM_NRC"
)
add_check(
  "SFC_PRICE_VARIABLES_CREATED",
  all(c(
    "P_K_SFC_ME_2017_100",
    "P_K_SFC_NRC_2017_100"
  ) %in% source_panel$variable_id),
  "Created P_K_SFC_ME_2017_100 and P_K_SFC_NRC_2017_100."
)
add_check(
  "DIRECT_NOMINAL_INVESTMENT_VARIABLES_CREATED",
  all(c(
    "I_NOMINAL_DIRECT_ME",
    "I_NOMINAL_DIRECT_NRC"
  ) %in% source_panel$variable_id),
  "Created both direct nominal investment variables."
)
add_check(
  "REAL_INVESTMENT_VARIABLES_CREATED",
  all(c(
    "I_REAL_GPIM_ME",
    "I_REAL_GPIM_NRC"
  ) %in% source_panel$variable_id),
  "Created I_REAL_GPIM_ME and I_REAL_GPIM_NRC."
)
add_check(
  "GROSS_GPIM_STOCK_VARIABLES_CREATED",
  all(c(
    "K_GROSS_GPIM_ME",
    "K_GROSS_GPIM_NRC"
  ) %in% source_panel$variable_id),
  "Created K_GROSS_GPIM_ME and K_GROSS_GPIM_NRC."
)
add_check(
  "SOURCE_PANEL_NONEMPTY",
  nrow(source_panel) > 0L &&
    all(is.finite(source_panel$value)) &&
    setequal(unique(source_panel$variable_id), expected_ids),
  paste0(
    "Source panel contains ", nrow(source_panel),
    " finite observations across ",
    length(unique(source_panel$variable_id)), " variables."
  )
)

panel_key <- paste(
  source_panel$asset_block,
  source_panel$year,
  source_panel$variable_id,
  sep = "::"
)
add_check(
  "SOURCE_PANEL_UNIQUE_KEYS",
  !anyDuplicated(panel_key),
  paste0(
    "Duplicate asset-year-variable keys: ",
    sum(duplicated(panel_key)), "."
  )
)

ledger_baseline_key <- paste(
  role_ledger$asset_block[role_ledger$baseline_use == "yes"],
  role_ledger$object_role[role_ledger$baseline_use == "yes"],
  sep = "::"
)
add_check(
  "S12D_B_ROLE_LEDGER_MATCHES_CONTRACT",
  setequal(ledger_baseline_key, expected_contract_key),
  paste0(
    "S12D-B ledger exposes ",
    length(unique(ledger_baseline_key)),
    " baseline asset-role combinations."
  )
)
add_check(
  "S12D_B_VALIDATION_AND_RECONSTRUCTION_PASS",
  nrow(s12d_b_validation) == 21L &&
    all(s12d_b_validation$status == "PASS") &&
    nrow(reconstruction) == 2L &&
    all(reconstruction$status == "PASS"),
  paste0(
    sum(s12d_b_validation$status == "PASS"), "/",
    nrow(s12d_b_validation), " S12D-B validations and ",
    sum(reconstruction$status == "PASS"), "/",
    nrow(reconstruction), " reconstruction checks are PASS."
  )
)
add_check(
  "NO_S20_S21_S22_RUN",
  TRUE,
  "S13 reads only the named S12D-B and S12D-C artifacts."
)
add_check(
  "NO_ECONOMETRICS_RUN",
  TRUE,
  "S13 creates no econometric object and invokes no econometric script."
)
add_check(
  "NO_PROVIDER_MODIFICATION",
  TRUE,
  "S13 reads no provider repository path and modifies no provider data."
)

preliminary_decision <- if (all(validation_checks$status == "PASS")) {
  "AUTHORIZE_DOWNSTREAM_GPIM_CONSUMPTION"
} else {
  "REQUIRE_S13_PATCH"
}
add_check(
  "FINAL_DECISION_EXPLICIT",
  preliminary_decision %in% c(
    "AUTHORIZE_DOWNSTREAM_GPIM_CONSUMPTION",
    "REQUIRE_S13_PATCH"
  ),
  paste0("Final decision resolved explicitly as ", preliminary_decision, ".")
)

final_decision <- if (all(validation_checks$status == "PASS")) {
  "AUTHORIZE_DOWNSTREAM_GPIM_CONSUMPTION"
} else {
  "REQUIRE_S13_PATCH"
}

output_root <- file.path(
  repo_root, "output", "US",
  "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

source_panel_path <- file.path(csv_dir, "S13_gpim_source_panel_long.csv")
audit_path <- file.path(csv_dir, "S13_consumption_audit.csv")
validation_path <- file.path(csv_dir, "S13_validation_checks.csv")
report_path <- file.path(
  md_dir, "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION.md"
)

write.csv(source_panel, source_panel_path, row.names = FALSE, na = "")
write.csv(consumption_audit, audit_path, row.names = FALSE, na = "")
write.csv(validation_checks, validation_path, row.names = FALSE, na = "")

escape_md <- function(x) {
  x <- gsub("\r|\n", " ", as.character(x))
  gsub("|", "\\|", x, fixed = TRUE)
}
markdown_table <- function(data, columns) {
  formatted <- data[, columns, drop = FALSE]
  header <- paste0("| ", paste(columns, collapse = " | "), " |")
  divider <- paste0(
    "|", paste(rep("---", length(columns)), collapse = "|"), "|"
  )
  body <- apply(formatted, 1L, function(row) {
    paste0(
      "| ",
      paste(vapply(row, escape_md, character(1L)), collapse = " | "),
      " |"
    )
  })
  c(header, divider, body)
}

panel_summary <- aggregate(
  year ~ asset_block + variable_id + object_role + unit,
  data = source_panel,
  FUN = function(x) paste0(min(x), "-", max(x), " (", length(x), " rows)")
)
names(panel_summary)[names(panel_summary) == "year"] <- "span_and_rows"

report_lines <- c(
  "# S13 Locked GPIM Source-of-Truth Consumption",
  "",
  "## Consumption Gate",
  "",
  paste(
    "S13 consumed the locked S12D-C contract and creates the downstream-facing",
    "GPIM source panel. The panel contains only baseline-consumable S12D-C",
    "objects."
  ),
  "",
  "## Integration Boundary",
  "",
  "- S13 did not reconstruct GPIM stocks.",
  "- S13 did not run S20, S21, or S22.",
  "- S13 did not run econometrics.",
  "- S13 did not modify provider data.",
  "- The diagnostic net-value stock remains excluded.",
  "- `FAAt402` remains validation-only.",
  "- NFC output-price translation remains robustness-only.",
  "- Productive-efficiency objects remain not constructed.",
  "",
  "## Source Panel",
  "",
  markdown_table(
    panel_summary,
    c("asset_block", "variable_id", "object_role", "unit", "span_and_rows")
  ),
  "",
  "## Consumption Audit",
  "",
  markdown_table(
    consumption_audit,
    c(
      "asset_block", "object_role", "consumed", "source_table",
      "variable_ids_created", "evidence"
    )
  ),
  "",
  "## Validation Checks",
  "",
  markdown_table(
    validation_checks,
    c("check_id", "status", "evidence")
  ),
  "",
  "## Final Decision",
  "",
  paste0("**", final_decision, "**")
)
writeLines(report_lines, report_path, useBytes = TRUE)

message(
  "S13 completed: ",
  sum(validation_checks$status == "PASS"), "/",
  nrow(validation_checks), " validation checks PASS."
)
message("Source-panel rows: ", nrow(source_panel))
message("Consumption-audit rows: ", nrow(consumption_audit))
message("Decision: ", final_decision)
message("GPIM stocks reconstructed: no")
message("S20/S21/S22 run: no")
message("Econometrics run: no")
message("Provider data modified: no")

if (final_decision != "AUTHORIZE_DOWNSTREAM_GPIM_CONSUMPTION") {
  quit(save = "no", status = 1L)
}
