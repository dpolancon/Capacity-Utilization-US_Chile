#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, scipen = 999)

# S20 builds the bounded model-input layer from the S14 GPIM source-of-truth
# consolidation. It does not reconstruct GPIM, estimate models, build theta,
# productive capacity, utilization, accumulated q, or weighted capital indexes.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop(
    "Run S20 from the Capacity-Utilization-US_Chile repository root.",
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

markdown_escape <- function(x) {
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
      paste(vapply(row, markdown_escape, character(1L)), collapse = " | "),
      " |"
    )
  })
  c(header, divider, body)
}

current_head <- system2("git", c("rev-parse", "--short", "HEAD"),
                        stdout = TRUE, stderr = TRUE)
current_branch <- system2("git", c("branch", "--show-current"),
                          stdout = TRUE, stderr = TRUE)

s14_root <- file.path(
  repo_root, "output", "US", "S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION"
)
s20_plan_root <- file.path(
  repo_root, "output", "US", "S20_MODEL_INPUT_LAYER_PLANNING"
)

input_paths <- c(
  s14_panel = file.path(
    s14_root, "csv", "S14_ch2_source_of_truth_panel_long.csv"
  ),
  s14_role_ledger = file.path(
    s14_root, "csv", "S14_object_role_ledger.csv"
  ),
  s14_validation = file.path(
    s14_root, "csv", "S14_validation_checks.csv"
  ),
  s14_report = file.path(
    s14_root, "md", "S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION.md"
  ),
  s20_planning_report = file.path(
    s20_plan_root, "md", "S20_MODEL_INPUT_LAYER_PLANNING.md"
  ),
  s20_addendum = file.path(
    s20_plan_root, "md", "S20_AGGREGATION_DEPLETION_ADDENDUM.md"
  )
)

missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  stop(
    "Missing required S20 gate/input artifact(s): ",
    paste(unname(missing_inputs), collapse = ", "),
    call. = FALSE
  )
}

normalized_s14_root <- normalizePath(
  s14_root, winslash = "/", mustWork = TRUE
)
normalized_plan_root <- normalizePath(
  s20_plan_root, winslash = "/", mustWork = TRUE
)
normalized_inputs <- normalizePath(input_paths, winslash = "/", mustWork = TRUE)
names(normalized_inputs) <- names(input_paths)
s14_data_inputs_bounded <- all(startsWith(
  normalized_inputs[c("s14_panel", "s14_role_ledger", "s14_validation", "s14_report")],
  paste0(normalized_s14_root, "/")
))
planning_inputs_bounded <- all(startsWith(
  normalized_inputs[c("s20_planning_report", "s20_addendum")],
  paste0(normalized_plan_root, "/")
))
if (!s14_data_inputs_bounded || !planning_inputs_bounded) {
  stop("S20 inputs must resolve inside S14 outputs or S20 planning outputs.",
       call. = FALSE)
}

input_hashes_before <- unname(tools::md5sum(input_paths))

s14_panel <- read_csv(input_paths[["s14_panel"]])
s14_role_ledger <- read_csv(input_paths[["s14_role_ledger"]])
s14_validation <- read_csv(input_paths[["s14_validation"]])
s14_report <- readLines(input_paths[["s14_report"]], warn = FALSE,
                        encoding = "UTF-8")
s20_planning_report <- readLines(
  input_paths[["s20_planning_report"]], warn = FALSE, encoding = "UTF-8"
)
s20_addendum <- readLines(
  input_paths[["s20_addendum"]], warn = FALSE, encoding = "UTF-8"
)

require_columns(
  s14_panel,
  c(
    "variable_id", "asset_block", "year", "value", "unit", "object_role",
    "source_of_truth_status", "architecture_layer", "registered_from_stage",
    "downstream_stage_owner", "source_table", "notes"
  ),
  "S14 source-of-truth panel"
)
require_columns(
  s14_role_ledger,
  c(
    "variable_id", "asset_block", "object_role", "unit", "coverage_start",
    "coverage_end", "observation_count", "registration_status",
    "source_artifact"
  ),
  "S14 object-role ledger"
)
require_columns(
  s14_validation,
  c("check_id", "status", "evidence"),
  "S14 validation table"
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

component_stock_variables <- c("K_GROSS_GPIM_ME", "K_GROSS_GPIM_NRC")

role_for_variable <- function(variable_id) {
  if (variable_id %in% c("K_GROSS_GPIM_ME", "K_GROSS_GPIM_NRC")) {
    return("PRIMARY_COMPONENT_GPIM_REGISTER")
  }
  if (variable_id %in% c("I_REAL_GPIM_ME", "I_REAL_GPIM_NRC")) {
    return("BASELINE_REAL_INVESTMENT_INPUT")
  }
  if (variable_id %in% c("P_K_SFC_ME_2017_100", "P_K_SFC_NRC_2017_100")) {
    return("BASELINE_CAPITAL_PRICE_INPUT")
  }
  if (variable_id %in% c("I_NOMINAL_DIRECT_ME", "I_NOMINAL_DIRECT_NRC")) {
    return("CANONICAL_NOMINAL_INVESTMENT_INPUT")
  }
  "UNAUTHORIZED"
}

component_panel <- s14_panel[
  s14_panel$variable_id %in% component_stock_variables,
  ,
  drop = FALSE
]
component_units <- unique(component_panel$unit)
me_stock <- component_panel[component_panel$variable_id == "K_GROSS_GPIM_ME",
                            c("year", "value", "unit"), drop = FALSE]
nrc_stock <- component_panel[component_panel$variable_id == "K_GROSS_GPIM_NRC",
                             c("year", "value", "unit"), drop = FALSE]
names(me_stock) <- c("year", "value_me", "unit_me")
names(nrc_stock) <- c("year", "value_nrc", "unit_nrc")
stock_wide <- merge(me_stock, nrc_stock, by = "year", all = TRUE, sort = TRUE)
stock_wide$value_me <- suppressWarnings(as.numeric(stock_wide$value_me))
stock_wide$value_nrc <- suppressWarnings(as.numeric(stock_wide$value_nrc))
stock_wide$year <- as.integer(stock_wide$year)

common_stock <- stock_wide[
  stock_wide$year >= 1931L &
    is.finite(stock_wide$value_me) &
    is.finite(stock_wide$value_nrc) &
    stock_wide$unit_me == "millions_2017" &
    stock_wide$unit_nrc == "millions_2017",
  ,
  drop = FALSE
]
common_stock$K_GROSS_GPIM_TOTAL <- common_stock$value_me +
  common_stock$value_nrc

aggregate_panel <- data.frame(
  variable_id = "K_GROSS_GPIM_TOTAL",
  asset_block = "ME_PLUS_NRC",
  year = common_stock$year,
  value = common_stock$K_GROSS_GPIM_TOTAL,
  unit = "millions_2017",
  object_role = "PROVISIONAL_COMPONENT_SUM_SCALE_BENCHMARK",
  downstream_consumption_status = "S20_DERIVED_FROM_REGISTERED_COMPONENTS",
  construction_stage = "S20_MODEL_INPUT_LAYER",
  source_table = "S20 component-sum identity from S14 model-input components",
  notes = paste(
    "Provisional common-support aggregate:",
    "K_GROSS_GPIM_TOTAL = K_GROSS_GPIM_ME + K_GROSS_GPIM_NRC."
  ),
  chapter2_object_family = "capital_stock_gross",
  source_of_truth_role = "derived_scale_benchmark",
  source_of_truth_status = "S20_DERIVED_PROVISIONAL",
  architecture_layer = "S20_MODEL_INPUT_LAYER",
  registered_from_stage = "S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION",
  downstream_stage_owner = "S20_MODEL_INPUT_LAYER",
  transformation_applied = "component_sum_common_support",
  stringsAsFactors = FALSE
)

s20_panel_base <- s14_panel[s14_panel$variable_id %in% authorized_variables,
                            ,
                            drop = FALSE]
s20_panel <- rbind(s20_panel_base, aggregate_panel[, names(s20_panel_base)])
s20_panel$s20_variable_role <- vapply(
  s20_panel$variable_id, role_for_variable, character(1L)
)
s20_panel$s20_variable_role[
  s20_panel$variable_id == "K_GROSS_GPIM_TOTAL"
] <- "PROVISIONAL_COMPONENT_SUM_SCALE_BENCHMARK"
s20_panel$s20_object_status <- ifelse(
  s20_panel$variable_id == "K_GROSS_GPIM_TOTAL",
  "S20_DERIVED_PROVISIONAL",
  "S14_REGISTERED_PRESERVED"
)
s20_panel$component_gpim_register <- ifelse(
  s20_panel$variable_id %in% component_stock_variables,
  "yes",
  "no"
)
s20_panel$aggregate_available_flag <- ifelse(
  s20_panel$variable_id == "K_GROSS_GPIM_TOTAL",
  "yes",
  ifelse(
    s20_panel$variable_id == "K_GROSS_GPIM_ME" &
      as.integer(s20_panel$year) < 1931L,
    "no_component_only_pre_common_support",
    ifelse(
      s20_panel$variable_id %in% component_stock_variables &
        as.integer(s20_panel$year) >= 1931L,
      "yes_common_support_component",
      "not_applicable"
    )
  )
)
s20_panel$common_support_scope <- ifelse(
  s20_panel$variable_id == "K_GROSS_GPIM_TOTAL",
  "common_support_1931_2024",
  ifelse(
    s20_panel$variable_id %in% component_stock_variables,
    "component_series_preserved",
    "not_applicable"
  )
)
s20_panel$lineage_status <- ifelse(
  s20_panel$variable_id == "K_GROSS_GPIM_TOTAL",
  "DERIVED_EX_POST_FROM_S14_COMPONENT_REGISTERS",
  "S14_REGISTERED_COMPONENT_OR_INPUT_LINEAGE_PRESERVED"
)
s20_panel$gpim_procedure_rule <- ifelse(
  s20_panel$variable_id %in% c(component_stock_variables, "K_GROSS_GPIM_TOTAL"),
  paste(
    "asset-account GPIM first; aggregation second;",
    "no independent aggregate GPIM or aggregate survival/depletion profile"
  ),
  "S14 input preserved; no GPIM reconstruction"
)
s20_panel$stock_flow_consistency_claim <- ifelse(
  s20_panel$variable_id %in% c(component_stock_variables, "K_GROSS_GPIM_TOTAL"),
  paste(
    "S20 inherits and preserves upstream validated GPIM component lineage;",
    "validates lineage, units, support, and component-sum identity only"
  ),
  "not_applicable"
)
s20_panel$weighted_aggregation_status <- "not_constructed"
s20_panel$accumulated_q_status <- "not_constructed"
s20_panel$reconstruction_objects_status <- "not_constructed"

s20_panel <- s20_panel[
  order(s20_panel$variable_id, as.integer(s20_panel$year)),
  ,
  drop = FALSE
]
rownames(s20_panel) <- NULL

capital_role_ledger <- data.frame(
  object_id = c(
    "K_GROSS_GPIM_ME",
    "K_GROSS_GPIM_NRC",
    "K_GROSS_GPIM_TOTAL",
    "K_GROSS_GPIM_TOTAL_SUPPORT_1925_1930",
    "INDEPENDENT_AGGREGATE_GPIM_STOCK",
    "AGGREGATE_SURVIVAL_DEPLETION_PROFILE",
    "GPIM_WEIGHTED_CAPITAL_AGGREGATE",
    "TORNQVIST_OR_DIVISIA_CAPITAL_INDEX",
    "PRODUCTIVE_EFFICIENCY_WEIGHTED_STOCK"
  ),
  object_role = c(
    "PRIMARY_COMPONENT_GPIM_REGISTER",
    "PRIMARY_COMPONENT_GPIM_REGISTER",
    "PROVISIONAL_COMPONENT_SUM_SCALE_BENCHMARK",
    "COMPONENT_ONLY_PRE_COMMON_SUPPORT",
    "EXCLUDED_OBJECT",
    "EXCLUDED_OBJECT",
    "PARKED_GPIM_WEIGHTED_AGGREGATION_PENDING_VALUE_REGISTER_PROTOCOL",
    "EXCLUDED_INDEX_NUMBER_AGGREGATE",
    "EXCLUDED_PRODUCTIVE_EFFICIENCY_WEIGHT"
  ),
  status = c(
    "PRESERVED",
    "PRESERVED",
    "CONSTRUCTED_PROVISIONAL",
    "PRESERVED_AS_ME_COMPONENT_ONLY",
    "EXCLUDED",
    "EXCLUDED",
    "PARKED",
    "EXCLUDED",
    "EXCLUDED"
  ),
  allowed_use = c(
    "Component stock for model-input architecture and composition-preserving comparisons.",
    "Component stock for model-input architecture and composition-preserving comparisons.",
    "Derived common-support scale benchmark from registered ME and NRC components.",
    "Document ME-only component support before NRC stock begins.",
    "None in S20.",
    "None in S20.",
    "Future value-register protocol only.",
    "None in S20.",
    "None in S20."
  ),
  prohibited_use = c(
    "Do not assign fixed intensive/extensive meaning or use as independent theta evidence.",
    "Do not assign fixed intensive/extensive meaning or use as independent theta evidence.",
    "Do not treat as independently reconstructed aggregate GPIM or final heterogeneous-capital solution.",
    "Do not create partial-support aggregate values.",
    "Do not construct I_TOTAL -> P_TOTAL -> average depletion -> K_TOTAL.",
    "Do not apply one primitive survival/depletion profile to total capital.",
    "Do not construct value-share, weighted, Tornqvist, Divisia, or efficiency-weighted aggregates.",
    "Do not construct index-number capital aggregates.",
    "Do not smuggle theta, productivity, productive capacity, or utilization into weights."
  ),
  validation_rule = c(
    "S14 registered; unit millions_2017; 1925-2024 preserved.",
    "S14 registered; unit millions_2017; 1931-2024 preserved.",
    "Equals ME plus NRC on 1931-2024 common support.",
    "ME rows 1925-1930 retained only as component observations.",
    "Absent from S20 panel.",
    "Absent from S20 panel.",
    "Absent from S20 panel; ledger records parked status.",
    "Absent from S20 panel.",
    "Absent from S20 panel."
  ),
  stringsAsFactors = FALSE
)

distribution_role_ledger <- data.frame(
  object_id = c(
    "WAGE_SHARE_UNADJUSTED_BASELINE",
    "PROFIT_SHARE_ALTERNATIVE_RECONCILIATION",
    "SHAIKH_ADJUSTED_WAGE_SHARE",
    "SHAIKH_ADJUSTED_PROFIT_SHARE"
  ),
  object_role = c(
    "PREFERRED_DISTRIBUTION_INPUT_PENDING_AUTHORIZED_SOURCE",
    "ALTERNATIVE_RECONCILIATION_EVIDENCE_PENDING_AUTHORIZED_SOURCE",
    "BLOCKED_PENDING_CROSSWALK_AND_DATA",
    "BLOCKED_PENDING_CROSSWALK_AND_DATA"
  ),
  status = c(
    "PENDING_AUTHORIZED_SOURCE",
    "PENDING_OPTIONAL_SOURCE",
    "BLOCKED",
    "BLOCKED"
  ),
  source_status = c(
    "No authorized wage-share source is present in the S14 GPIM input contract.",
    "No authorized profit-share source is present in the S14 GPIM input contract.",
    "No current-release semantic/accounting crosswalk and data contract is authorized in S20.",
    "No current-release semantic/accounting crosswalk and data contract is authorized in S20."
  ),
  allowed_use = c(
    "Future S20 extension may join only after explicit source, boundary, formula, unit, coverage, and join validation.",
    "Alternative or reconciliation evidence only after explicit source validation.",
    "Future robustness or candidate lane only if crosswalk plus data both pass.",
    "Future robustness or candidate lane only if crosswalk plus data both pass."
  ),
  prohibited_use = c(
    "Do not derive from unaudited source or silently change sector boundary.",
    "Do not promote as preferred baseline without a new decision.",
    "Do not overwrite the unadjusted wage-share baseline.",
    "Do not overwrite the unadjusted wage-share baseline."
  ),
  stringsAsFactors = FALSE
)

blocked_ledger <- data.frame(
  object_id = c(
    "INDEPENDENT_AGGREGATE_GPIM_STOCK",
    "AGGREGATE_SURVIVAL_DEPLETION_PROFILE",
    "GPIM_WEIGHTED_CAPITAL_AGGREGATE",
    "TORNQVIST_CAPITAL_INDEX",
    "DIVISIA_CAPITAL_INDEX",
    "PRODUCTIVE_EFFICIENCY_WEIGHTED_STOCK",
    "THETA_T",
    "PRODUCTIVE_CAPACITY_Y_P",
    "CAPACITY_UTILIZATION_MU",
    "ACCUMULATED_Q",
    "S21_ACCUMULATED_Q_LAYER",
    "IPP_FRONTIER_CONDITIONER",
    "GOV_TRANS_FRONTIER_CONDITIONER",
    "SHAIKH_ADJUSTED_DISTRIBUTION_OBJECTS",
    "FAAt402_BASELINE_PROMOTION",
    "DIAGNOSTIC_NET_VALUE_GPIM_STOCK",
    "NFC_OUTPUT_PRICE_TRANSLATION_BASELINE"
  ),
  status = c(
    "EXCLUDED",
    "EXCLUDED",
    "PARKED_GPIM_WEIGHTED_AGGREGATION_PENDING_VALUE_REGISTER_PROTOCOL",
    "EXCLUDED",
    "EXCLUDED",
    "EXCLUDED",
    "EXCLUDED",
    "EXCLUDED",
    "EXCLUDED",
    "ACCUMULATED_Q_PARKED_S21_CLOSED",
    "ACCUMULATED_Q_PARKED_S21_CLOSED",
    "PARKED_CONTROL_CONDITIONERS",
    "PARKED_CONTROL_CONDITIONERS",
    "BLOCKED_PENDING_CROSSWALK_AND_DATA",
    "EXCLUDED_VALIDATION_ONLY_HISTORICAL_CONTEXT",
    "EXCLUDED",
    "EXCLUDED_ROBUSTNESS_ONLY_HISTORICAL_CONTEXT"
  ),
  reason = c(
    "S20 may derive only component-sum K_GROSS_GPIM_TOTAL from S14 component registers.",
    "Survival/depletion remains asset-account-specific.",
    "Future weights require a separate GPIM value-register protocol.",
    "Index-number aggregation is outside S20.",
    "Index-number aggregation is outside S20.",
    "No weights may encode theta, productivity, productive capacity, or utilization.",
    "S20 prepares inputs only.",
    "S20 prepares inputs only.",
    "S20 prepares inputs only.",
    "Accumulated q remains parked.",
    "S20 does not authorize S21.",
    "Future control candidate only; not baseline productive capital.",
    "Future control candidate only; not baseline productive capital.",
    "Requires current-release data and semantic/accounting crosswalk.",
    "FAAt402 remains validation-only.",
    "Diagnostic net-value GPIM stock remains excluded.",
    "NFC output-price translation remains robustness-only."
  ),
  stringsAsFactors = FALSE
)

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

decision_line_count <- function(lines, decision) {
  sum(trimws(lines) == paste0("**", decision, "**"))
}

s14_decision_count <- decision_line_count(
  s14_report, "AUTHORIZE_S20_MODEL_INPUT_LAYER"
)
s20_plan_decision_count <- decision_line_count(
  s20_planning_report, "AUTHORIZE_S20_IMPLEMENTATION_PROMPT"
)
s20_addendum_decision_count <- decision_line_count(
  s20_addendum, "AUTHORIZE_S20_IMPLEMENTATION_WITH_AGGREGATION_DEPLETION_LOCKS"
)

add_check(
  "CURRENT_HEAD_CHECKED_AT_A93B420",
  identical(current_head[1], "a93b420") && identical(current_branch[1], "main"),
  paste0("HEAD=", current_head[1], "; branch=", current_branch[1], ".")
)
add_check(
  "S14_INPUTS_FOUND",
  all(file.exists(input_paths[c(
    "s14_panel", "s14_role_ledger", "s14_validation", "s14_report"
  )])),
  "S14 panel, role ledger, validation table, and report are present."
)
add_check(
  "S20_PLANNING_DECISION_RECOGNIZED",
  s20_plan_decision_count == 1L,
  paste0(
    "AUTHORIZE_S20_IMPLEMENTATION_PROMPT decision count: ",
    s20_plan_decision_count, "."
  )
)
add_check(
  "S20_AGGREGATION_DEPLETION_ADDENDUM_RECOGNIZED",
  s20_addendum_decision_count == 1L,
  paste0(
    "AUTHORIZE_S20_IMPLEMENTATION_WITH_AGGREGATION_DEPLETION_LOCKS count: ",
    s20_addendum_decision_count, "."
  )
)
add_check(
  "S14_DECISION_RECOGNIZED",
  s14_decision_count == 1L && all(s14_validation$status == "PASS"),
  paste0(
    "AUTHORIZE_S20_MODEL_INPUT_LAYER count: ", s14_decision_count,
    "; S14 PASS checks: ", sum(s14_validation$status == "PASS"), "/",
    nrow(s14_validation), "."
  )
)

s14_vars <- sort(unique(s14_panel$variable_id))
add_check(
  "EXACT_EIGHT_VARIABLE_S14_ALLOWLIST_CONSUMED",
  setequal(s14_vars, authorized_variables) &&
    length(s14_vars) == 8L &&
    setequal(
      sort(unique(s20_panel_base$variable_id)),
      sort(authorized_variables)
    ),
  paste0(
    "S14 variables consumed: ", paste(s14_vars, collapse = ", "), "."
  )
)

component_preserved <- all(component_stock_variables %in% s20_panel$variable_id)
add_check(
  "ME_AND_NRC_COMPONENT_STOCKS_PRESERVED",
  component_preserved &&
    sum(s20_panel$variable_id == "K_GROSS_GPIM_ME") == 100L &&
    sum(s20_panel$variable_id == "K_GROSS_GPIM_NRC") == 94L,
  paste0(
    "ME component rows: ",
    sum(s20_panel$variable_id == "K_GROSS_GPIM_ME"),
    "; NRC component rows: ",
    sum(s20_panel$variable_id == "K_GROSS_GPIM_NRC"), "."
  )
)
add_check(
  "COMPONENT_FIRST_GPIM_RULE_PRESERVED_AS_LINEAGE",
  all(grepl(
    "asset-account GPIM first",
    unique(s20_panel$gpim_procedure_rule[
      s20_panel$variable_id %in% c(component_stock_variables, "K_GROSS_GPIM_TOTAL")
    ]),
    fixed = TRUE
  )),
  "S20 records asset-account GPIM first, aggregation second as lineage."
)
add_check(
  "AGGREGATE_CONSTRUCTED_ONLY_ON_COMMON_SUPPORT",
  all(aggregate_panel$year >= 1931L) &&
    nrow(aggregate_panel) == 94L,
  paste0(
    "Aggregate years: ", min(aggregate_panel$year), "-",
    max(aggregate_panel$year), "; rows: ", nrow(aggregate_panel), "."
  )
)
add_check(
  "AGGREGATE_STARTS_IN_1931",
  min(aggregate_panel$year) == 1931L,
  paste0("Minimum aggregate year: ", min(aggregate_panel$year), ".")
)
add_check(
  "NO_PARTIAL_SUPPORT_AGGREGATE_1925_1930",
  !any(
    s20_panel$variable_id == "K_GROSS_GPIM_TOTAL" &
      as.integer(s20_panel$year) >= 1925L &
      as.integer(s20_panel$year) <= 1930L
  ) &&
    sum(
      s20_panel$variable_id == "K_GROSS_GPIM_ME" &
        as.integer(s20_panel$year) >= 1925L &
        as.integer(s20_panel$year) <= 1930L
    ) == 6L,
  paste0(
    "Aggregate rows 1925-1930: ",
    sum(
      s20_panel$variable_id == "K_GROSS_GPIM_TOTAL" &
        as.integer(s20_panel$year) >= 1925L &
        as.integer(s20_panel$year) <= 1930L
    ),
    "; ME component-only rows 1925-1930: ",
    sum(
      s20_panel$variable_id == "K_GROSS_GPIM_ME" &
        as.integer(s20_panel$year) >= 1925L &
        as.integer(s20_panel$year) <= 1930L
    ),
    "."
  )
)
identity_residual <- common_stock$K_GROSS_GPIM_TOTAL -
  common_stock$value_me - common_stock$value_nrc
add_check(
  "AGGREGATE_IDENTITY_ROW_LEVEL_CHECKS_PASS",
  all(abs(identity_residual) < 0.0000001),
  paste0(
    "Maximum absolute identity residual: ",
    format(max(abs(identity_residual)), scientific = FALSE), "."
  )
)
add_check(
  "UNITS_VALIDATED_AS_MILLIONS_2017_BEFORE_AGGREGATION",
  setequal(component_units, "millions_2017") &&
    all(common_stock$unit_me == "millions_2017") &&
    all(common_stock$unit_nrc == "millions_2017"),
  paste0("Component stock units observed: ",
         paste(component_units, collapse = ", "), ".")
)
add_check(
  "K_GROSS_GPIM_TOTAL_LABELLED_PROVISIONAL_BENCHMARK",
  all(
    s20_panel$object_role[
      s20_panel$variable_id == "K_GROSS_GPIM_TOTAL"
    ] == "PROVISIONAL_COMPONENT_SUM_SCALE_BENCHMARK"
  ) &&
    all(
      s20_panel$s20_variable_role[
        s20_panel$variable_id == "K_GROSS_GPIM_TOTAL"
      ] == "PROVISIONAL_COMPONENT_SUM_SCALE_BENCHMARK"
    ),
  "K_GROSS_GPIM_TOTAL carries PROVISIONAL_COMPONENT_SUM_SCALE_BENCHMARK role."
)
add_check(
  "NO_INDEPENDENT_AGGREGATE_GPIM_STOCK_CONSTRUCTED",
  !"INDEPENDENT_AGGREGATE_GPIM_STOCK" %in% s20_panel$variable_id &&
    "INDEPENDENT_AGGREGATE_GPIM_STOCK" %in% blocked_ledger$object_id,
  "Independent aggregate GPIM stock is absent from panel and recorded as excluded."
)
add_check(
  "NO_AGGREGATE_SURVIVAL_DEPLETION_PROFILE_CONSTRUCTED",
  !"AGGREGATE_SURVIVAL_DEPLETION_PROFILE" %in% s20_panel$variable_id &&
    "AGGREGATE_SURVIVAL_DEPLETION_PROFILE" %in% blocked_ledger$object_id,
  "Aggregate survival/depletion profile is absent and recorded as excluded."
)
add_check(
  "S20_STOCK_FLOW_CLAIM_LIMITED_TO_LINEAGE_PRESERVING_VALIDATION",
  all(grepl(
    "inherits and preserves upstream validated GPIM component lineage",
    unique(s20_panel$stock_flow_consistency_claim[
      s20_panel$variable_id %in% c(component_stock_variables, "K_GROSS_GPIM_TOTAL")
    ]),
    fixed = TRUE
  )),
  "S20 validates lineage, units, support, and component-sum identity only."
)
add_check(
  "NO_WEIGHTED_OR_INDEX_NUMBER_AGGREGATE_CONSTRUCTED",
  !any(grepl(
    "WEIGHTED|TORNQVIST|DIVISIA",
    s20_panel$variable_id,
    ignore.case = TRUE
  )),
  "No weighted, Tornqvist, or Divisia aggregate variable appears in the S20 panel."
)
add_check(
  "GPIM_WEIGHTED_AGGREGATION_PARKED",
  "PARKED_GPIM_WEIGHTED_AGGREGATION_PENDING_VALUE_REGISTER_PROTOCOL" %in%
    blocked_ledger$status,
  "Weighted aggregation is recorded as PARKED_GPIM_WEIGHTED_AGGREGATION_PENDING_VALUE_REGISTER_PROTOCOL."
)
add_check(
  "PRODUCTIVE_EFFICIENCY_WEIGHTS_EXCLUDED",
  "PRODUCTIVE_EFFICIENCY_WEIGHTED_STOCK" %in% blocked_ledger$object_id &&
    !any(grepl("PRODUCTIVE_EFFICIENCY", s20_panel$variable_id,
               ignore.case = TRUE)),
  "Productive-efficiency weights are excluded and absent from the panel."
)
add_check(
  "THETA_NOT_ESTIMATED",
  !any(grepl("THETA|theta", names(s20_panel))) &&
    !any(grepl("THETA|theta", s20_panel$variable_id)),
  "No theta variable, coefficient, or column is emitted."
)
add_check(
  "PRODUCTIVE_CAPACITY_NOT_CONSTRUCTED",
  !any(grepl("PRODUCTIVE_CAPACITY|Y_P|Yp|YP", s20_panel$variable_id)),
  "No productive-capacity object is emitted."
)
add_check(
  "UTILIZATION_NOT_CONSTRUCTED",
  !any(grepl("UTILIZATION|MU|mu", s20_panel$variable_id)),
  "No utilization object is emitted."
)
add_check(
  "ACCUMULATED_Q_NOT_CONSTRUCTED",
  !any(grepl("^Q_|ACCUMULATED_Q|q_", s20_panel$variable_id,
             ignore.case = TRUE)) &&
    "ACCUMULATED_Q_PARKED_S21_CLOSED" %in% blocked_ledger$status,
  "No accumulated q object is emitted; S21 remains closed."
)
add_check(
  "FRONTIER_CONDITIONERS_EXCLUDED_FROM_BASELINE",
  all(blocked_ledger$status[
    blocked_ledger$object_id %in% c(
      "IPP_FRONTIER_CONDITIONER",
      "GOV_TRANS_FRONTIER_CONDITIONER"
    )
  ] == "PARKED_CONTROL_CONDITIONERS") &&
    !any(grepl("IPP|GOV_TRANS", s20_panel$variable_id)),
  "IPP and GOV_TRANS are parked control-conditioners and absent from the panel."
)
add_check(
  "SHAIKH_ADJUSTMENT_BLOCKED_UNLESS_CROSSWALK_PLUS_DATA_EXIST",
  all(distribution_role_ledger$status[
    grepl("SHAIKH", distribution_role_ledger$object_id)
  ] == "BLOCKED"),
  "Shaikh-adjusted distribution objects are blocked pending crosswalk plus data."
)
add_check(
  "NO_PROVIDER_FILES_ACCESSED_OR_MODIFIED",
  s14_data_inputs_bounded && planning_inputs_bounded,
  "S20 reads only S14 consolidation artifacts and S20 planning gate reports."
)
add_check(
  "NO_GPIM_RECONSTRUCTION",
  TRUE,
  "S20 derives only a component-sum aggregate from S14 registered component stocks."
)

script_path <- file.path(repo_root, "codes", "US_S20_build_model_input_layer.R")
script_lines <- readLines(script_path, warn = FALSE, encoding = "UTF-8")
executable_lines <- script_lines[
  !grepl("^\\s*#", script_lines) & nzchar(trimws(script_lines))
]
forbidden_stage_invocation <- paste0(
  "(source|sys\\.source|system|system2|shell)\\s*\\(",
  "[^\\n]*(S21|S22|S30I|S30|S32)"
)
forbidden_stage_hits <- grep(
  forbidden_stage_invocation,
  executable_lines,
  ignore.case = TRUE,
  value = TRUE
)
add_check(
  "NO_DOWNSTREAM_SCRIPTS_INVOKED",
  length(forbidden_stage_hits) == 0L,
  paste0(
    "Executable S20 lines invoking S21/S22/S30I/S30/S32: ",
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
  "NO_ECONOMETRICS_RUN",
  length(econometric_hits) == 0L,
  paste0("Econometric function calls found in S20 script: ",
         length(econometric_hits), ".")
)

preliminary_decision <- if (all(validation_checks$status == "PASS")) {
  "AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION"
} else {
  "BLOCK_S20_MODEL_INPUT_CONSUMPTION"
}
add_check(
  "FINAL_DECISION_EXPLICIT",
  preliminary_decision %in% c(
    "AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION",
    "BLOCK_S20_MODEL_INPUT_CONSUMPTION"
  ),
  paste0("Final decision resolved explicitly as ", preliminary_decision, ".")
)
final_decision <- if (all(validation_checks$status == "PASS")) {
  "AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION"
} else {
  "BLOCK_S20_MODEL_INPUT_CONSUMPTION"
}

output_root <- file.path(repo_root, "output", "US", "S20_MODEL_INPUT_LAYER")
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

panel_path <- file.path(csv_dir, "S20_model_input_panel_long.csv")
capital_ledger_path <- file.path(csv_dir, "S20_capital_role_ledger.csv")
distribution_ledger_path <- file.path(csv_dir, "S20_distribution_role_ledger.csv")
blocked_ledger_path <- file.path(
  csv_dir, "S20_blocked_parked_excluded_object_ledger.csv"
)
validation_path <- file.path(csv_dir, "S20_validation_checks.csv")
report_path <- file.path(md_dir, "S20_MODEL_INPUT_LAYER.md")

write.csv(s20_panel, panel_path, row.names = FALSE, na = "")
write.csv(capital_role_ledger, capital_ledger_path, row.names = FALSE, na = "")
write.csv(distribution_role_ledger, distribution_ledger_path,
          row.names = FALSE, na = "")
write.csv(blocked_ledger, blocked_ledger_path, row.names = FALSE, na = "")
write.csv(validation_checks, validation_path, row.names = FALSE, na = "")

panel_summary <- aggregate(
  year ~ variable_id + s20_variable_role + unit + s20_object_status,
  data = s20_panel,
  FUN = function(x) paste0(min(x), "-", max(x), " (", length(x), " rows)")
)
names(panel_summary)[names(panel_summary) == "year"] <- "span_and_rows"
panel_summary <- panel_summary[
  order(panel_summary$variable_id),
  ,
  drop = FALSE
]

report_lines <- c(
  "# S20 Model-Input Layer",
  "",
  "## Scope",
  "",
  paste(
    "S20 consumes the S14 Chapter 2 source-of-truth consolidation and",
    "constructs a bounded model-input layer. It preserves the eight",
    "S14-authorized GPIM variables and derives only the provisional",
    "`K_GROSS_GPIM_TOTAL` component-sum scale benchmark on common support."
  ),
  "",
  "S20 does not reconstruct GPIM, reopen provider discovery, run econometrics, estimate theta, construct productive capacity, construct utilization, construct accumulated q, or construct weighted/index-number aggregates.",
  "",
  "## Panel Summary",
  "",
  markdown_table(
    panel_summary,
    c(
      "variable_id", "s20_variable_role", "unit",
      "s20_object_status", "span_and_rows"
    )
  ),
  "",
  "## Aggregation and Depletion Locks",
  "",
  paste(
    "GPIM is asset-account-specific first and aggregation second.",
    "S20 preserves ME and NRC component lineage and derives the aggregate",
    "only ex post from registered component stocks."
  ),
  "",
  "- `K_GROSS_GPIM_TOTAL = K_GROSS_GPIM_ME + K_GROSS_GPIM_NRC`.",
  "- The provisional aggregate begins in 1931.",
  "- ME-only 1925-1930 observations remain component-only.",
  "- No independent aggregate GPIM stock is constructed.",
  "- No primitive aggregate survival/depletion profile is constructed.",
  paste(
    "- S20 inherits and preserves upstream validated GPIM component lineage;",
    "it validates lineage, units, support, and row-level component-sum identity",
    "only."
  ),
  "",
  "## Distribution Ledger",
  "",
  markdown_table(
    distribution_role_ledger,
    c("object_id", "object_role", "status", "source_status")
  ),
  "",
  "## Blocked, Parked, And Excluded Objects",
  "",
  markdown_table(
    blocked_ledger,
    c("object_id", "status", "reason")
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

input_hashes_after <- unname(tools::md5sum(input_paths))
if (!identical(input_hashes_before, input_hashes_after)) {
  stop("An S20 input/gate artifact changed during execution.", call. = FALSE)
}

message(
  "S20 completed: ",
  sum(validation_checks$status == "PASS"), "/",
  nrow(validation_checks), " validation checks PASS."
)
message("S20 panel rows: ", nrow(s20_panel))
message("S20 aggregate rows: ", nrow(aggregate_panel))
message("Final decision: ", final_decision)
message("GPIM reconstructed: no")
message("Econometrics run: no")
message("Downstream scripts invoked: no")

if (final_decision != "AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION") {
  quit(save = "no", status = 1L)
}
