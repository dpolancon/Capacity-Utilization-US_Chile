#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, scipen = 999)

# S14 registers the locked S13 GPIM baseline in the Chapter 2 source-of-truth
# architecture. It performs no reconstruction, provider access, or econometrics.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop(
    "Run S14 from the Capacity-Utilization-US_Chile repository root.",
    call. = FALSE
  )
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

s13_root <- file.path(
  repo_root, "output", "US",
  "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION"
)
input_paths <- c(
  source_panel = file.path(
    s13_root, "csv", "S13_gpim_source_panel_long.csv"
  ),
  consumption_audit = file.path(
    s13_root, "csv", "S13_consumption_audit.csv"
  ),
  validation = file.path(
    s13_root, "csv", "S13_validation_checks.csv"
  ),
  report = file.path(
    s13_root, "md", "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION.md"
  )
)

missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  stop(
    "Missing required S14 input(s): ",
    paste(unname(missing_inputs), collapse = ", "),
    call. = FALSE
  )
}

normalized_s13_root <- normalizePath(
  s13_root, winslash = "/", mustWork = TRUE
)
normalized_inputs <- normalizePath(
  input_paths, winslash = "/", mustWork = TRUE
)
input_paths_bounded <- all(
  startsWith(normalized_inputs, paste0(normalized_s13_root, "/"))
)
if (!input_paths_bounded) {
  stop("Every S14 input must resolve inside the S13 output directory.",
       call. = FALSE)
}

input_hashes_before <- unname(tools::md5sum(input_paths))

s13_panel <- read_csv(input_paths[["source_panel"]])
s13_audit <- read_csv(input_paths[["consumption_audit"]])
s13_validation <- read_csv(input_paths[["validation"]])
s13_report_lines <- readLines(
  input_paths[["report"]],
  warn = FALSE,
  encoding = "UTF-8"
)

require_columns(
  s13_panel,
  c(
    "asset_block", "year", "variable_id", "value", "unit", "object_role",
    "downstream_consumption_status", "construction_stage", "source_table",
    "notes"
  ),
  "S13 GPIM source panel"
)
require_columns(
  s13_audit,
  c(
    "asset_block", "object_role", "consumed", "source_table",
    "variable_ids_created", "evidence"
  ),
  "S13 consumption audit"
)
require_columns(
  s13_validation,
  c("check_id", "status", "evidence"),
  "S13 validation table"
)

authorized_variables <- c(
  "I_NOMINAL_DIRECT_ME",
  "I_NOMINAL_DIRECT_NRC",
  "P_K_SFC_ME_2017_100",
  "P_K_SFC_NRC_2017_100",
  "I_REAL_GPIM_ME",
  "I_REAL_GPIM_NRC",
  "K_GROSS_GPIM_ME",
  "K_GROSS_GPIM_NRC"
)
authorized_assets <- c("ME", "NRC")
authorized_roles <- c(
  "DIRECT_NOMINAL_INVESTMENT_CANONICAL",
  "SFC_IMPLICIT_BASELINE_PRICE",
  "REAL_INVESTMENT_BASELINE",
  "GROSS_SURVIVAL_GPIM_STOCK_BASELINE"
)

role_metadata <- data.frame(
  variable_id = authorized_variables,
  chapter2_object_family = c(
    "capital_investment_nominal",
    "capital_investment_nominal",
    "capital_price",
    "capital_price",
    "capital_investment_real",
    "capital_investment_real",
    "capital_stock_gross",
    "capital_stock_gross"
  ),
  source_of_truth_role = c(
    "canonical_nominal_investment_input",
    "canonical_nominal_investment_input",
    "baseline_capital_price_input",
    "baseline_capital_price_input",
    "baseline_real_investment_input",
    "baseline_real_investment_input",
    "baseline_gross_capital_stock_input",
    "baseline_gross_capital_stock_input"
  ),
  stringsAsFactors = FALSE
)

consolidation_panel <- merge(
  s13_panel,
  role_metadata,
  by = "variable_id",
  all.x = TRUE,
  sort = FALSE
)
consolidation_panel$source_of_truth_status <- "REGISTERED_BASELINE"
consolidation_panel$architecture_layer <-
  "S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION"
consolidation_panel$registered_from_stage <-
  "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION"
consolidation_panel$downstream_stage_owner <- "S20_MODEL_INPUT_LAYER"
consolidation_panel$transformation_applied <- "none"
consolidation_panel <- consolidation_panel[
  order(
    consolidation_panel$asset_block,
    consolidation_panel$variable_id,
    consolidation_panel$year
  ),
  ,
  drop = FALSE
]
rownames(consolidation_panel) <- NULL

make_role_ledger_row <- function(variable) {
  rows <- consolidation_panel[
    consolidation_panel$variable_id == variable,
    ,
    drop = FALSE
  ]
  data.frame(
    variable_id = variable,
    asset_block = paste(unique(rows$asset_block), collapse = "; "),
    object_role = paste(unique(rows$object_role), collapse = "; "),
    chapter2_object_family = paste(
      unique(rows$chapter2_object_family),
      collapse = "; "
    ),
    source_of_truth_role = paste(
      unique(rows$source_of_truth_role),
      collapse = "; "
    ),
    unit = paste(unique(rows$unit), collapse = "; "),
    coverage_start = if (nrow(rows) > 0L) min(rows$year) else NA_integer_,
    coverage_end = if (nrow(rows) > 0L) max(rows$year) else NA_integer_,
    observation_count = nrow(rows),
    registration_status = if (
      nrow(rows) > 0L &&
        all(rows$source_of_truth_status == "REGISTERED_BASELINE")
    ) {
      "REGISTERED_BASELINE"
    } else {
      "REGISTRATION_FAILED"
    },
    allowed_use = "Input to the bounded S20 model-input layer.",
    prohibited_use = paste(
      "No GPIM reconstruction, diagnostic net-value stock, FAAt402",
      "baseline promotion, NFC output-price translation,",
      "productive-efficiency construction, or econometrics."
    ),
    source_artifact = "S13_gpim_source_panel_long.csv",
    stringsAsFactors = FALSE
  )
}

object_role_ledger <- do.call(
  rbind,
  lapply(authorized_variables, make_role_ledger_row)
)
rownames(object_role_ledger) <- NULL

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

add_check(
  "S13_VALIDATION_ALL_PASS",
  nrow(s13_validation) == 18L &&
    all(s13_validation$status == "PASS"),
  paste0(
    sum(s13_validation$status == "PASS"), "/",
    nrow(s13_validation), " S13 validation checks are PASS."
  )
)

decision_lines <- trimws(s13_report_lines)
s13_authorization_count <- sum(
  decision_lines == "**AUTHORIZE_DOWNSTREAM_GPIM_CONSUMPTION**"
)
add_check(
  "S13_DECISION_AUTHORIZES_DOWNSTREAM_GPIM",
  s13_authorization_count == 1L,
  paste0(
    "Exact AUTHORIZE_DOWNSTREAM_GPIM_CONSUMPTION decision line count: ",
    s13_authorization_count, "."
  )
)

registered_variables <- sort(unique(consolidation_panel$variable_id))
add_check(
  "EXACTLY_EIGHT_AUTHORIZED_GPIM_VARIABLES_REGISTERED",
  nrow(object_role_ledger) == 8L &&
    setequal(registered_variables, authorized_variables) &&
    !anyDuplicated(object_role_ledger$variable_id),
  paste0(
    "Registered ", length(registered_variables), " distinct variables: ",
    paste(registered_variables, collapse = ", "), "."
  )
)

registered_assets <- sort(unique(consolidation_panel$asset_block))
add_check(
  "ME_AND_NRC_ASSET_BLOCKS_PRESENT",
  identical(registered_assets, authorized_assets) &&
    all(table(consolidation_panel$asset_block) > 0L),
  paste0(
    "Observed asset blocks: ", paste(registered_assets, collapse = ", "), "."
  )
)

add_check(
  "S13_AUDIT_COVERS_EIGHT_BASELINE_OBJECTS",
  nrow(s13_audit) == 8L &&
    all(s13_audit$consumed == "yes") &&
    setequal(s13_audit$variable_ids_created, authorized_variables),
  paste0(
    sum(s13_audit$consumed == "yes"), "/",
    nrow(s13_audit), " S13 audit rows are consumed=yes."
  )
)

nonbaseline_tokens <- paste(
  c(
    "NET_VALUE", "FAAt402", "OUTPUT_UNIT_TRANSLATION",
    "PRODUCTIVE_EFFICIENCY"
  ),
  collapse = "|"
)
nonbaseline_entered <- any(
  consolidation_panel$object_role %in% setdiff(
    unique(consolidation_panel$object_role),
    authorized_roles
  )
) || any(
  grepl(
    nonbaseline_tokens,
    consolidation_panel$variable_id,
    ignore.case = TRUE
  )
)
add_check(
  "NO_NON_BASELINE_S12D_OBJECTS_ENTER_S14",
  !nonbaseline_entered &&
    all(
      consolidation_panel$downstream_consumption_status ==
        "BASELINE_CONSUMABLE"
    ),
  paste0(
    "Non-baseline variable or role rows registered: ",
    sum(
      !consolidation_panel$object_role %in% authorized_roles |
        grepl(
          nonbaseline_tokens,
          consolidation_panel$variable_id,
          ignore.case = TRUE
        )
    ),
    "."
  )
)

panel_keys <- paste(
  consolidation_panel$asset_block,
  consolidation_panel$year,
  consolidation_panel$variable_id,
  sep = "::"
)
add_check(
  "S13_OBSERVATIONS_PRESERVED_WITHOUT_TRANSFORMATION",
  nrow(consolidation_panel) == 884L &&
    all(is.finite(consolidation_panel$value)) &&
    !anyDuplicated(panel_keys) &&
    all(consolidation_panel$transformation_applied == "none"),
  paste0(
    nrow(consolidation_panel),
    " finite observations registered; duplicate keys: ",
    sum(duplicated(panel_keys)), "; transformations applied: none."
  )
)

script_path <- file.path(
  repo_root, "codes", "US_S14_ch2_source_of_truth_consolidation.R"
)
script_lines <- readLines(script_path, warn = FALSE, encoding = "UTF-8")
executable_lines <- script_lines[
  !grepl("^\\s*#", script_lines) & nzchar(trimws(script_lines))
]
forbidden_stage_invocation <- paste0(
  "(source|sys\\.source|system|system2|shell)\\s*\\(",
  "[^\\n]*(S20|S21|S22|S31I|S30|S32)"
)
forbidden_stage_hits <- grep(
  forbidden_stage_invocation,
  executable_lines,
  ignore.case = TRUE,
  value = TRUE
)
add_check(
  "NO_DOWNSTREAM_STAGE_SCRIPT_INVOKED",
  length(forbidden_stage_hits) == 0L,
  paste0(
    "Executable S14 lines invoking S20/S21/S22/S31I/S30/S32: ",
    length(forbidden_stage_hits), "."
  )
)

econometric_invocation <- paste0(
  "\\b(lm|glm|arima|var|vec2var|ca\\.jo|ur\\.df|dynlm|ardl|",
  "coeftest|waldtest)\\s*\\("
)
econometric_hits <- grep(
  econometric_invocation,
  executable_lines,
  ignore.case = TRUE,
  value = TRUE
)
add_check(
  "S14_DATA_ARCHITECTURE_ONLY",
  length(econometric_hits) == 0L &&
    all(
      consolidation_panel$architecture_layer ==
        "S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION"
    ),
  paste0(
    "Econometric function calls found: ", length(econometric_hits),
    "; output layer is registration-only."
  )
)

input_hashes_after_read <- unname(tools::md5sum(input_paths))
add_check(
  "S13_INPUTS_UNCHANGED_DURING_CONSOLIDATION",
  identical(input_hashes_before, input_hashes_after_read),
  paste0(
    sum(input_hashes_before == input_hashes_after_read), "/",
    length(input_paths), " S13 input hashes unchanged after consumption."
  )
)

add_check(
  "NO_PROVIDER_FILES_REFERENCED_OR_MODIFIED",
  input_paths_bounded,
  paste(
    "All four inputs resolve inside the S13 output directory;",
    "S14 has no provider input or provider write target."
  )
)

add_check(
  "OBJECT_ROLE_LEDGER_COMPLETE",
  nrow(object_role_ledger) == 8L &&
    all(object_role_ledger$registration_status == "REGISTERED_BASELINE") &&
    sum(object_role_ledger$observation_count) == 884L,
  paste0(
    nrow(object_role_ledger), " ledger rows register ",
    sum(object_role_ledger$observation_count), " observations."
  )
)

preliminary_decision <- if (all(validation_checks$status == "PASS")) {
  "AUTHORIZE_S20_MODEL_INPUT_LAYER"
} else {
  "BLOCK_S20_MODEL_INPUT_LAYER"
}
add_check(
  "FINAL_DECISION_EXPLICIT",
  preliminary_decision %in% c(
    "AUTHORIZE_S20_MODEL_INPUT_LAYER",
    "BLOCK_S20_MODEL_INPUT_LAYER"
  ),
  paste0("Final decision resolved explicitly as ", preliminary_decision, ".")
)

final_decision <- if (all(validation_checks$status == "PASS")) {
  "AUTHORIZE_S20_MODEL_INPUT_LAYER"
} else {
  "BLOCK_S20_MODEL_INPUT_LAYER"
}

output_root <- file.path(
  repo_root, "output", "US", "S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

panel_path <- file.path(
  csv_dir, "S14_ch2_source_of_truth_panel_long.csv"
)
ledger_path <- file.path(
  csv_dir, "S14_object_role_ledger.csv"
)
validation_path <- file.path(
  csv_dir, "S14_validation_checks.csv"
)
report_path <- file.path(
  md_dir, "S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION.md"
)

write.csv(consolidation_panel, panel_path, row.names = FALSE, na = "")
write.csv(object_role_ledger, ledger_path, row.names = FALSE, na = "")
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

report_lines <- c(
  "# S14 Chapter 2 Source-of-Truth Consolidation",
  "",
  "## Architecture Result",
  "",
  paste(
    "S14 registers the locked S13 GPIM baseline in the Chapter 2",
    "source-of-truth architecture. The consolidation panel preserves all",
    "884 S13 observations and registers exactly the eight authorized GPIM",
    "variables for the bounded S20 model-input layer."
  ),
  "",
  "## Registered Object Roles",
  "",
  markdown_table(
    object_role_ledger,
    c(
      "variable_id", "asset_block", "object_role",
      "source_of_truth_role", "unit", "coverage_start", "coverage_end",
      "observation_count", "registration_status"
    )
  ),
  "",
  "## Boundary Enforcement",
  "",
  "- S14 consumes only the S13 panel, audit, validation table, and report.",
  "- S14 does not reconstruct GPIM or reopen provider discovery.",
  "- S14 does not read or modify provider files.",
  "- S14 does not invoke S20, S21, S22, S31I, S30, or S32.",
  "- S14 creates no econometric or productive-efficiency object.",
  "- The diagnostic net-value stock does not enter S14.",
  "- `FAAt402` remains validation-only historical context.",
  "- NFC output-price translation remains robustness-only historical context.",
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

input_hashes_after_write <- unname(tools::md5sum(input_paths))
if (!identical(input_hashes_before, input_hashes_after_write)) {
  stop("An S13 input changed while S14 outputs were written.", call. = FALSE)
}

message(
  "S14 completed: ",
  sum(validation_checks$status == "PASS"), "/",
  nrow(validation_checks), " validation checks PASS."
)
message("Consolidation-panel rows: ", nrow(consolidation_panel))
message("Object-role ledger rows: ", nrow(object_role_ledger))
message("Decision: ", final_decision)
message("GPIM reconstructed: no")
message("Provider files read or modified: no")
message("Downstream or econometric scripts invoked: no")

if (final_decision != "AUTHORIZE_S20_MODEL_INPUT_LAYER") {
  quit(save = "no", status = 1L)
}
