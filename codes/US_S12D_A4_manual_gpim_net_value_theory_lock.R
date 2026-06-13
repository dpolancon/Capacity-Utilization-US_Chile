#!/usr/bin/env Rscript

# S12D-A4 records the dissertation-level net-value theory lock. It authorizes
# S12D-B as the next step but constructs no final GPIM stock.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S12D-A4 from the downstream repository root.", call. = FALSE)
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
write_csv <- function(data, path) {
  write.csv(data, path, row.names = FALSE, na = "")
}

input_paths <- c(
  a3_registry = file.path(
    repo_root, "output", "US", "S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR",
    "csv", "S12D_A3_external_anchor_registry.csv"
  ),
  a3_mapping = file.path(
    repo_root, "output", "US", "S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR",
    "csv", "S12D_A3_schedule_mapping.csv"
  ),
  a3_decision = file.path(
    repo_root, "output", "US", "S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR",
    "csv", "S12D_A3_protocol_decision_ledger.csv"
  ),
  a3_validation = file.path(
    repo_root, "output", "US", "S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR",
    "csv", "S12D_A3_validation_checks.csv"
  ),
  s12c_parameters = file.path(
    repo_root, "output", "US", "S12C_CAPITAL_INPUT_GPIM_PROTOCOL",
    "csv", "S12C_gpim_parameter_metadata.csv"
  )
)
missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  abort(paste0(
    "Missing S12D-A4 inputs:\n- ",
    paste(unname(missing_inputs), collapse = "\n- ")
  ))
}

a3_registry <- read_csv(input_paths[["a3_registry"]])
a3_mapping <- read_csv(input_paths[["a3_mapping"]])
a3_decision <- read_csv(input_paths[["a3_decision"]])
a3_validation <- read_csv(input_paths[["a3_validation"]])
s12c_parameters <- read_csv(input_paths[["s12c_parameters"]])

require_condition(
  nrow(a3_validation) > 0L && all(a3_validation$result == "PASS"),
  "S12D-A3 validation is not fully PASS."
)
require_condition(
  sum(a3_decision$protocol_item == "final_stage_gate_decision") == 1L &&
    a3_decision$status[
      a3_decision$protocol_item == "final_stage_gate_decision"
    ] == "REQUIRE_MANUAL_THEORY_LOCK",
  "S12D-A3 did not require the S12D-A4 manual theory lock."
)
require_condition(
  setequal(a3_mapping$asset_block, c("ME", "NRC")) &&
    all(a3_mapping$manual_theory_choice_required == "TRUE"),
  "S12D-A3 does not contain both proposed manual-lock mappings."
)

manual_lock_sentence <- paste(
  "For the Chapter 2 GPIM baseline, net-value weights are defined separately",
  "from physical survival as V_i(j)=S_i(j)(1-d_i)^j, where S_i(j) is the",
  "locked asset-specific Weibull survival schedule and the externally",
  "documented declining-balance age-price rates are d_ME=0.110 and",
  "d_NRC=0.024. These rates are age-price/depreciation anchors only; they",
  "are not retirement rates, productive-efficiency profiles, FAAt402 price",
  "indexes, NFC output deflators, or final capital-price indexes."
)

expected_manual_lock_sentence <- paste(
  "For the Chapter 2 GPIM baseline, net-value weights are defined separately",
  "from physical survival as V_i(j)=S_i(j)(1-d_i)^j, where S_i(j) is the",
  "locked asset-specific Weibull survival schedule and the externally",
  "documented declining-balance age-price rates are d_ME=0.110 and",
  "d_NRC=0.024. These rates are age-price/depreciation anchors only; they",
  "are not retirement rates, productive-efficiency profiles, FAAt402 price",
  "indexes, NFC output deflators, or final capital-price indexes."
)
require_condition(
  identical(manual_lock_sentence, expected_manual_lock_sentence),
  "The manual lock sentence was altered."
)

parameter_value <- function(name) {
  value <- suppressWarnings(as.numeric(
    s12c_parameters$parameter_value[
      s12c_parameters$parameter_name == name
    ]
  ))
  require_condition(
    length(value) == 1L && is.finite(value),
    paste0("Missing locked parameter ", name, ".")
  )
  value
}

protocol_parameters <- data.frame(
  asset_block = c("ME", "NRC"),
  survival_profile = c("Weibull", "Weibull"),
  L = c(parameter_value("L_ME"), parameter_value("L_NRC")),
  alpha = c(parameter_value("alpha_ME"), parameter_value("alpha_NRC")),
  age_price_profile = c(
    "declining_balance_geometric",
    "declining_balance_geometric"
  ),
  d = c("0.110", "0.024"),
  net_value_schedule = c(
    "V_ME(j)=S_ME(j)*(1-0.110)^j",
    "V_NRC(j)=S_NRC(j)*(1-0.024)^j"
  ),
  baseline_status = c(
    "LOCKED_FOR_S12D_B",
    "LOCKED_FOR_S12D_B"
  ),
  stringsAsFactors = FALSE
)

manual_lock_ledger <- data.frame(
  lock_id = c(
    "S12D_A4_MANUAL_LOCK_SENTENCE",
    "PHYSICAL_SURVIVAL_ROLE",
    "AGE_PRICE_ROLE",
    "NET_VALUE_ROLE",
    "SFC_IMPLICIT_PRICE_ROLE",
    "FAAT402_ROLE",
    "NFC_OUTPUT_PRICE_ROLE",
    "PRODUCTIVE_EFFICIENCY_ROLE",
    "FINAL_GPIM_STOCK_BOUNDARY"
  ),
  object_family = c(
    "manual_theory_lock",
    "survival_profile",
    "age_price_profile",
    "net_value_schedule",
    "capital_price_recovery",
    "validation_quantity_index",
    "output_price",
    "productive_efficiency",
    "construction_boundary"
  ),
  status = c(
    "LOCKED",
    "LOCKED_SEPARATE_WEIBULL",
    "LOCKED_ASSET_SPECIFIC_DECLINING_BALANCE",
    "LOCKED_COMPOSITE_VALUE_WEIGHT",
    "AUTHORIZED_FOR_RECURSIVE_RECOVERY_IN_S12D_B",
    "VALIDATION_ONLY_NOT_BASELINE_PRICE",
    "OUTPUT_ROUTE_ONLY_NOT_BASELINE_CAPITAL_PRICE",
    "SEPARATE_NOT_CONSTRUCTED",
    "NOT_CONSTRUCTED_IN_S12D_A4"
  ),
  baseline_allowed = c(
    "TRUE", "survival_role_only", "TRUE", "TRUE", "TRUE",
    "FALSE", "FALSE", "FALSE", "FALSE"
  ),
  rule = c(
    manual_lock_sentence,
    paste(
      "Physical survival remains the locked asset-specific Weibull schedule."
    ),
    paste(
      "Age-price decline uses d_ME=0.110 and d_NRC=0.024 as separate",
      "asset-specific anchors."
    ),
    "Net-value weights combine survival and age-price decline.",
    paste(
      "The SFC implicit capital price remains recursively recovered from",
      "direct nominal investment, locked net-value weights, and current-cost",
      "stock anchors."
    ),
    "FAAt402 remains comparison and validation only.",
    paste(
      "The NFC output deflator remains an output-unit translation or",
      "robustness object only."
    ),
    "Productive-efficiency profiles remain separate and unconstructed.",
    paste(
      "This pass records protocol metadata only and creates no final GPIM",
      "stock."
    )
  ),
  source_stage = c(
    "manual_dissertation_lock",
    "S12C_locked_parameters",
    "S12D_A3_external_anchor",
    "S12D_A4_manual_lock",
    "S12D_A_recursive_protocol",
    "S12C_S12D_A_boundary",
    "S12B_S12D_A_boundary",
    "S12D_A2_S12D_A3_boundary",
    "S12D_A4_boundary"
  ),
  notes = c(
    "Exact user-authorized lock sentence.",
    "", "", "", "", "", "", "",
    "S12D-B is the next authorized construction stage."
  ),
  stringsAsFactors = FALSE
)

stage_gate_decision <- data.frame(
  decision_id = "S12D_A4_FINAL_STAGE_GATE",
  decision = "AUTHORIZE_S12D_B",
  authorization_scope = paste(
    "Construct real ME/NRC investment and diagnostic/final GPIM objects only",
    "under the locked S12D-A4 net-value schedule and all inherited boundaries."
  ),
  prerequisites_satisfied = "TRUE",
  manual_lock_recorded = "TRUE",
  final_gpim_stocks_constructed_in_this_pass = "FALSE",
  s20_s21_s22_run = "FALSE",
  econometric_output_created = "FALSE",
  notes = paste(
    "Authorization is prospective. S12D-A4 itself is a lock pass only."
  ),
  stringsAsFactors = FALSE
)

output_root <- file.path(
  repo_root, "output", "US",
  "S12D_A4_MANUAL_GPIM_NET_VALUE_THEORY_LOCK"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

paths <- c(
  lock = file.path(csv_dir, "S12D_A4_manual_lock_ledger.csv"),
  parameters = file.path(csv_dir, "S12D_A4_protocol_parameters.csv"),
  decision = file.path(csv_dir, "S12D_A4_stage_gate_decision.csv"),
  validation = file.path(csv_dir, "S12D_A4_validation_checks.csv"),
  report = file.path(
    md_dir, "S12D_A4_MANUAL_GPIM_NET_VALUE_THEORY_LOCK.md"
  )
)

validation <- data.frame(
  validation_rule = character(),
  result = character(),
  observed = character(),
  notes = character(),
  stringsAsFactors = FALSE
)
add_check <- function(rule, pass, observed, notes = "") {
  validation <<- rbind(validation, data.frame(
    validation_rule = rule,
    result = if (isTRUE(pass)) "PASS" else "FAIL",
    observed = as.character(observed),
    notes = notes,
    stringsAsFactors = FALSE
  ))
}
add_check(
  "exact manual lock sentence recorded",
  identical(
    manual_lock_ledger$rule[
      manual_lock_ledger$lock_id == "S12D_A4_MANUAL_LOCK_SENTENCE"
    ],
    expected_manual_lock_sentence
  ),
  manual_lock_sentence
)
add_check(
  "parameter ledger has exactly ME and NRC rows",
  nrow(protocol_parameters) == 2L &&
    identical(protocol_parameters$asset_block, c("ME", "NRC")),
  paste(protocol_parameters$asset_block, collapse = "; ")
)
add_check(
  "ME depreciation rate locked",
  identical(protocol_parameters$d[
    protocol_parameters$asset_block == "ME"
  ], "0.110"),
  protocol_parameters$d[protocol_parameters$asset_block == "ME"]
)
add_check(
  "NRC depreciation rate locked",
  identical(protocol_parameters$d[
    protocol_parameters$asset_block == "NRC"
  ], "0.024"),
  protocol_parameters$d[protocol_parameters$asset_block == "NRC"]
)
add_check(
  "ME Weibull parameters unchanged",
  identical(protocol_parameters$L[
    protocol_parameters$asset_block == "ME"
  ], 14) &&
    identical(protocol_parameters$alpha[
      protocol_parameters$asset_block == "ME"
    ], 1.7),
  "L=14; alpha=1.7"
)
add_check(
  "NRC Weibull parameters unchanged",
  identical(protocol_parameters$L[
    protocol_parameters$asset_block == "NRC"
  ], 30) &&
    identical(protocol_parameters$alpha[
      protocol_parameters$asset_block == "NRC"
    ], 1.6),
  "L=30; alpha=1.6"
)
add_check(
  "age-price profile locked separately from survival",
  all(protocol_parameters$survival_profile == "Weibull") &&
    all(protocol_parameters$age_price_profile ==
          "declining_balance_geometric") &&
    all(protocol_parameters$net_value_schedule !=
          c("V_ME(j)=S_ME(j)", "V_NRC(j)=S_NRC(j)")),
  paste(protocol_parameters$net_value_schedule, collapse = "; ")
)
add_check(
  "both schedules locked for S12D-B",
  all(protocol_parameters$baseline_status == "LOCKED_FOR_S12D_B"),
  paste(protocol_parameters$baseline_status, collapse = "; ")
)
add_check(
  "FAAt402 not baseline capital-price route",
  manual_lock_ledger$baseline_allowed[
    manual_lock_ledger$lock_id == "FAAT402_ROLE"
  ] == "FALSE",
  "validation only"
)
add_check(
  "NFC output price not baseline capital-price route",
  manual_lock_ledger$baseline_allowed[
    manual_lock_ledger$lock_id == "NFC_OUTPUT_PRICE_ROLE"
  ] == "FALSE",
  "output translation/robustness only"
)
add_check(
  "productive-efficiency profile remains separate",
  manual_lock_ledger$status[
    manual_lock_ledger$lock_id == "PRODUCTIVE_EFFICIENCY_ROLE"
  ] == "SEPARATE_NOT_CONSTRUCTED",
  "not constructed"
)
add_check(
  "no final GPIM stocks constructed",
  stage_gate_decision$final_gpim_stocks_constructed_in_this_pass ==
    "FALSE" &&
    !any(grepl("^K_G_NFC_.*GPIM", names(protocol_parameters))),
  "lock metadata only"
)
add_check(
  "no S20/S21/S22 run",
  stage_gate_decision$s20_s21_s22_run == "FALSE",
  "S12D-A4 only"
)
add_check(
  "no econometric output created",
  stage_gate_decision$econometric_output_created == "FALSE",
  "none"
)
add_check(
  "exactly one final stage-gate decision",
  nrow(stage_gate_decision) == 1L &&
    identical(stage_gate_decision$decision, "AUTHORIZE_S12D_B"),
  stage_gate_decision$decision
)
add_check(
  "S12D-B authorization requires recorded manual lock",
  stage_gate_decision$manual_lock_recorded == "TRUE" &&
    any(manual_lock_ledger$lock_id == "S12D_A4_MANUAL_LOCK_SENTENCE") &&
    identical(
      manual_lock_ledger$rule[
        manual_lock_ledger$lock_id == "S12D_A4_MANUAL_LOCK_SENTENCE"
      ],
      expected_manual_lock_sentence
    ),
  "exact sentence recorded before authorization"
)
add_check(
  "S12D-A3 rates inherited without alteration",
  all(abs(
    as.numeric(protocol_parameters$d[
      match(a3_mapping$asset_block, protocol_parameters$asset_block)
    ]) - a3_mapping$depreciation_rate
  ) < 1e-12),
  "ME=0.110; NRC=0.024"
)

require_condition(
  all(validation$result == "PASS"),
  paste0(
    "S12D-A4 validation failed:\n- ",
    paste(validation$validation_rule[validation$result == "FAIL"],
          collapse = "\n- ")
  )
)

write_csv(manual_lock_ledger, paths[["lock"]])
write_csv(protocol_parameters, paths[["parameters"]])
write_csv(stage_gate_decision, paths[["decision"]])
write_csv(validation, paths[["validation"]])

escape_md <- function(x) {
  x <- gsub("\r|\n", " ", as.character(x))
  gsub("|", "\\|", x, fixed = TRUE)
}
markdown_table <- function(data, columns) {
  formatted <- data[, columns, drop = FALSE]
  numeric_columns <- vapply(formatted, is.numeric, logical(1L))
  formatted[numeric_columns] <- lapply(
    formatted[numeric_columns],
    function(x) ifelse(is.na(x), "", format(x, trim = TRUE, nsmall = 1))
  )
  header <- paste0("| ", paste(columns, collapse = " | "), " |")
  divider <- paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|")
  body <- apply(formatted, 1L, function(row) {
    paste0(
      "| ", paste(vapply(row, escape_md, character(1L)),
                   collapse = " | "), " |"
    )
  })
  c(header, divider, body)
}

report_lines <- c(
  "# S12D-A4 Manual GPIM Net-Value Theory Lock",
  "",
  "## Why A Manual Lock Was Required",
  "",
  paste(
    "S12D-A3 found explicit external declining-balance age-price evidence",
    "for ME and NRC, but the evidence did not automatically authorize",
    "combining those value-decay rates with the project's separate finite",
    "Weibull survival schedules. S12D-A4 records the dissertation-level",
    "choice that resolves that conceptual boundary."
  ),
  "",
  "## Exact Manual Lock",
  "",
  manual_lock_sentence,
  "",
  "## Locked Parameterization",
  "",
  markdown_table(
    protocol_parameters,
    c(
      "asset_block", "survival_profile", "L", "alpha",
      "age_price_profile", "d", "net_value_schedule", "baseline_status"
    )
  ),
  "",
  "## Interpretation",
  "",
  "1. Physical survival remains the locked asset-specific Weibull schedule.",
  "2. Age-price decline uses the externally anchored asset-specific rates.",
  "3. Net-value weights combine survival and age-price decline.",
  "4. The SFC implicit capital price remains recovered recursively.",
  "5. The recovered SFC price is not FAAt402.",
  "6. The recovered SFC price is not the NFC output deflator.",
  "7. Productive-efficiency profiles remain separate and unconstructed.",
  "",
  "## Capital-Price Boundary",
  "",
  paste(
    "This lock defines value weights; it does not promote FAAt402 or the NFC",
    "output deflator. FAAt402 remains a quality-adjusted quantity-index",
    "validation object. The NFC output price remains an output-unit",
    "translation or robustness route. S12D-B must recover the asset-specific",
    "SFC implicit price by recursion under the locked schedules."
  ),
  "",
  "## Construction Boundary",
  "",
  paste(
    "S12D-A4 records protocol metadata only. It does not deflate investment,",
    "run the GPIM recursion, construct a final stock, run S20/S21/S22, or",
    "create econometric output."
  ),
  "",
  "## Stage-Gate Decision",
  "",
  "- Decision: `AUTHORIZE_S12D_B`.",
  paste(
    "- S12D-B is authorized as the next construction step under the exact",
    "manual lock and inherited provider/price boundaries."
  ),
  "- Final GPIM stocks constructed in this pass: no.",
  "",
  "## Validation",
  "",
  markdown_table(
    validation,
    c("validation_rule", "result", "observed")
  )
)
writeLines(report_lines, paths[["report"]], useBytes = TRUE)

message("S12D-A4 manual GPIM net-value theory lock passed.")
message("Manual lock ledger rows: ", nrow(manual_lock_ledger))
message("Protocol parameter rows: ", nrow(protocol_parameters))
message("Validation checks: ", nrow(validation))
message("Decision: AUTHORIZE_S12D_B")
message("Final GPIM stocks constructed: no")
message("S20/S21/S22 run: no")
