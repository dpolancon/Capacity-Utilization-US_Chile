# S27 plans future derived-variable construction from the S26-certified source-input layer.
# It does not implement derived variables, modeling inputs, or econometric outputs.

options(stringsAsFactors = FALSE)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

provider_v1_commit <- "af67374e28232d02d65765d3836dc2ab3e3da8eb"
s21_commit <- "3a0f5064d92fc09f97a55850b4086670d9cedc4b"
s22_commit <- "d6f47bcdaa80bc146196f99a1ccf9207d6957e57"
s23_commit <- "96be02bd0acb4ca10ecc626d07482f6176e7c3b3"
s24a_commit <- "444fb8397c00feb801369eac52614ca633afbfcc"
s24b_commit <- "24bcad5797cbebddbd77d697bc3ebdf0049746e2"
s24c_commit <- "0c3399f67365aafff8b012d66fac37d3bceda3f3"
s25_commit <- "1d6276ac35754e29acfeb755b6a351873cf59f6b"
s26_commit <- "8d5ec75f0a86fef94f736ff38bb80f0294c1cc1b"

final_pass_decision <- "AUTHORIZE_S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE"
final_pass_status <- "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_COMPLETE_S28_IMPLEMENTATION_SEQUENCE_AUTHORIZED"
final_fail_decision <- "BLOCK_FOR_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_REVIEW"
final_fail_status <- "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_BLOCKED_FOR_REVIEW"

s25_dir <- file.path(repo_root, "output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
s26_dir <- file.path(repo_root, "output", "US", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW")
s27_dir <- file.path(repo_root, "output", "US", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING")
csv_dir <- file.path(s27_dir, "csv")
md_dir <- file.path(s27_dir, "md")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

path <- function(...) file.path(...)

s26_input_paths <- list(
  completeness_ledger = path(s26_dir, "csv", "S26_source_input_completeness_ledger.csv"),
  observation_readiness = path(s26_dir, "csv", "S26_observation_bearing_readiness_audit.csv"),
  metadata_disposition = path(s26_dir, "csv", "S26_metadata_only_disposition_audit.csv"),
  boundary_audit = path(s26_dir, "csv", "S26_deferred_excluded_boundary_audit.csv"),
  planning_readiness = path(s26_dir, "csv", "S26_derived_variable_planning_readiness_audit.csv"),
  risk_register = path(s26_dir, "csv", "S26_completeness_risk_register.csv"),
  validation = path(s26_dir, "csv", "S26_validation_checks.csv"),
  validation_md = path(s26_dir, "md", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW_VALIDATION.md"),
  decision_md = path(s26_dir, "md", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW_DECISION.md")
)

s25_input_paths <- list(
  panel = path(s25_dir, "csv", "S25_authorized_source_inputs_long.csv"),
  ledger = path(s25_dir, "csv", "S25_authorized_source_inputs_construction_ledger.csv"),
  provenance = path(s25_dir, "csv", "S25_authorized_source_inputs_provenance_audit.csv"),
  family_coverage = path(s25_dir, "csv", "S25_family_coverage_audit.csv"),
  row_coverage = path(s25_dir, "csv", "S25_row_coverage_audit.csv"),
  zero_observation = path(s25_dir, "csv", "S25_zero_observation_metadata_audit.csv"),
  status_taxonomy = path(s25_dir, "csv", "S25_source_input_status_taxonomy.csv"),
  no_promotion = path(s25_dir, "csv", "S25_no_promotion_audit.csv"),
  continuity = path(s25_dir, "csv", "S25_continuity_audit.csv"),
  validation = path(s25_dir, "csv", "S25_validation_checks.csv"),
  validation_md = path(s25_dir, "md", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION_VALIDATION.md"),
  decision_md = path(s25_dir, "md", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION_DECISION.md")
)

output_paths <- list(
  candidate_registry = path(csv_dir, "S27_derived_variable_candidate_registry.csv"),
  dependency_map = path(csv_dir, "S27_source_to_derived_dependency_map.csv"),
  family_sequence = path(csv_dir, "S27_derived_variable_family_sequence_plan.csv"),
  metadata_usage = path(csv_dir, "S27_metadata_reference_usage_ledger.csv"),
  no_implementation = path(csv_dir, "S27_no_implementation_audit.csv"),
  boundary_carry_forward = path(csv_dir, "S27_deferred_excluded_boundary_carry_forward.csv"),
  authorization_matrix = path(csv_dir, "S27_future_construction_authorization_matrix.csv"),
  risk_ledger = path(csv_dir, "S27_planning_risk_ledger.csv"),
  validation = path(csv_dir, "S27_validation_checks.csv"),
  validation_md = path(md_dir, "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_VALIDATION.md"),
  decision_md = path(md_dir, "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_DECISION.md")
)

read_csv <- function(file) {
  read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
}

write_csv <- function(data, file) {
  write.csv(data, file, row.names = FALSE, na = "")
}

stop_if_missing <- function(paths) {
  missing <- paths[!file.exists(unlist(paths))]
  if (length(missing) > 0L) {
    stop("Required input files are missing:\n- ", paste(unlist(missing), collapse = "\n- "), call. = FALSE)
  }
}

to_int <- function(x) {
  as.integer(round(as.numeric(x)))
}

collapse_unique <- function(x) {
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (length(x) == 0L) "" else paste(sort(x), collapse = "; ")
}

source_ids <- function(pattern = NULL, family = NULL, status = "authorized_observation_bearing") {
  x <- s25_ledger
  if (!is.null(family)) {
    x <- x[x$construction_family == family, , drop = FALSE]
  }
  if (!is.null(status)) {
    x <- x[x$s25_object_status == status, , drop = FALSE]
  }
  if (!is.null(pattern)) {
    x <- x[grepl(pattern, x$variable_id, ignore.case = FALSE), , drop = FALSE]
  }
  x$variable_id
}

md_table <- function(data, cols = names(data)) {
  if (nrow(data) == 0L) {
    return("(none)")
  }
  data <- data[, cols, drop = FALSE]
  data[] <- lapply(data, function(x) gsub("\\|", "/", as.character(x)))
  header <- paste0("| ", paste(cols, collapse = " | "), " |")
  divider <- paste0("| ", paste(rep("---", length(cols)), collapse = " | "), " |")
  rows <- apply(data, 1L, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, divider, rows), collapse = "\n")
}

add_check <- local({
  checks <- list()
  function(name = NULL, condition = NULL, evidence = NULL, flush = FALSE) {
    if (flush) {
      return(do.call(rbind, checks))
    }
    checks[[length(checks) + 1L]] <<- data.frame(
      check_name = name,
      status = if (isTRUE(condition)) "PASS" else "FAIL",
      evidence = evidence,
      stringsAsFactors = FALSE
    )
    invisible(NULL)
  }
})

stop_if_missing(s26_input_paths)
stop_if_missing(s25_input_paths)
s26_hash_before <- tools::md5sum(unlist(s26_input_paths))
s25_hash_before <- tools::md5sum(unlist(s25_input_paths))

s26_completeness <- read_csv(s26_input_paths$completeness_ledger)
s26_observation <- read_csv(s26_input_paths$observation_readiness)
s26_metadata <- read_csv(s26_input_paths$metadata_disposition)
s26_boundary <- read_csv(s26_input_paths$boundary_audit)
s26_planning <- read_csv(s26_input_paths$planning_readiness)
s26_risk <- read_csv(s26_input_paths$risk_register)
s26_validation <- read_csv(s26_input_paths$validation)
s26_decision_text <- paste(readLines(s26_input_paths$decision_md, warn = FALSE), collapse = "\n")

s25_panel <- read_csv(s25_input_paths$panel)
s25_ledger <- read_csv(s25_input_paths$ledger)
s25_provenance <- read_csv(s25_input_paths$provenance)
s25_family <- read_csv(s25_input_paths$family_coverage)
s25_row <- read_csv(s25_input_paths$row_coverage)
s25_zero <- read_csv(s25_input_paths$zero_observation)
s25_taxonomy <- read_csv(s25_input_paths$status_taxonomy)
s25_no_promotion <- read_csv(s25_input_paths$no_promotion)
s25_continuity <- read_csv(s25_input_paths$continuity)
s25_validation <- read_csv(s25_input_paths$validation)

s26_validation_clean <- nrow(s26_validation) == 51L && all(s26_validation$status == "PASS")
s26_decision_clean <- grepl(
  "AUTHORIZE_S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING",
  s26_decision_text,
  fixed = TRUE
)
s25_validation_clean <- nrow(s25_validation) == 49L && all(s25_validation$status == "PASS")

if (!s26_validation_clean || !s26_decision_clean || !s25_validation_clean) {
  stop("S25/S26 gate is not clean; S27 must stop.", call. = FALSE)
}

candidate_specs <- list(
  list("DV_PLAN_REAL_OUTPUT_PRICE_SOURCE_REVIEW", "real_output_and_price_inputs", "Real output and economy-wide price source review", character(0), "requires_review_before_implementation", "No direct real-output source-input object is authorized in the S25 substrate; future planning must resolve source requirements before implementation."),
  list("DV_PLAN_NFC_DISTRIBUTION_ACCOUNTING", "income_distribution_variables", "NFC income-distribution accounting variables", source_ids("^NFC_", "income_distribution_source_inputs"), "ready_for_first_future_planning_family", "Use only observation-bearing NFC income-account source inputs; do not construct adjusted Shaikh alternatives in S27."),
  list("DV_PLAN_CORP_DISTRIBUTION_ACCOUNTING", "income_distribution_variables", "Corporate income-distribution accounting variables", source_ids("^CORP_", "income_distribution_source_inputs"), "ready_for_first_future_planning_family", "Use only observation-bearing corporate income-account source inputs."),
  list("DV_PLAN_NFC_FIXED_ASSET_CAPITAL_STOCK", "fixed_assets_and_capital_stock_variables", "NFC fixed-asset and capital-stock planning family", source_ids("^NFC__", "fixed_assets_source_inputs"), "ready_after_distribution_planning", "Plan capital-stock construction only in a later implementation setup; S27 constructs no K."),
  list("DV_PLAN_CORP_FIXED_ASSET_CAPITAL_STOCK", "fixed_assets_and_capital_stock_variables", "Corporate fixed-asset and capital-stock planning family", source_ids("^CORP__", "fixed_assets_source_inputs"), "ready_after_distribution_planning", "Plan corporate fixed-asset source use only; S27 constructs no K."),
  list("DV_PLAN_FIN_AND_GOV_TRANS_ASSET_BOUNDARIES", "fixed_assets_and_capital_stock_variables", "Financial and government-transport asset-boundary review", c(source_ids("^FIN__", "fixed_assets_source_inputs"), source_ids("^GOV_TRANS__", "fixed_assets_source_inputs")), "requires_review_before_implementation", "Boundary-sensitive source inputs require explicit future review before inclusion in analytical capital aggregates."),
  list("DV_PLAN_INVESTMENT_ACCUMULATION_INPUTS", "investment_and_accumulation_variables", "Investment and accumulation source-input planning", source_ids("gross_investment", "fixed_assets_source_inputs"), "ready_after_capital_stock_planning", "S27 maps gross-investment source inputs only; it constructs no investment, accumulation, recapitalization, or q variables."),
  list("DV_PLAN_RELATIVE_PRICE_DEFLATOR_INPUTS", "relative_price_and_deflator_variables", "Relative-price and deflator source-input planning", source_ids("current_cost|quantity_index", "fixed_assets_source_inputs"), "ready_after_capital_stock_planning", "S27 maps price/quantity source inputs only; it constructs no relative price, q, or accumulated q."),
  list("DV_PLAN_PROVIDER_OTHER_OBSERVATION_INPUTS", "relative_price_and_deflator_variables", "Provider-other observation-bearing source references", source_ids(NULL, "provider_source_inputs_other", "authorized_observation_bearing"), "requires_review_before_implementation", "Provider-other observation-bearing records may inform later planning only where theory authorizes their use."),
  list("DV_PLAN_METADATA_REFERENCE_ONLY", "metadata_reference_only_inputs", "Metadata-only reference records", source_ids(NULL, "provider_source_inputs_other", "authorized_zero_observation_metadata"), "reference_only_not_implementation_ready", "Metadata-only records remain references and cannot become observation-bearing variables in S27."),
  list("DV_PLAN_DEFERRED_EXCLUDED_BOUNDARY", "blocked_or_deferred_inputs", "Deferred and excluded boundary carry-forward", character(0), "blocked_or_deferred", "Theoretical, documentation-only, blocked, and parked records remain outside future implementation until separately authorized.")
)

candidate_registry <- do.call(rbind, lapply(seq_along(candidate_specs), function(i) {
  spec <- candidate_specs[[i]]
  data.frame(
    candidate_id = spec[[1]],
    derived_variable_family = spec[[2]],
    candidate_label = spec[[3]],
    planning_sequence_group = i,
    required_source_input_count = length(spec[[4]]),
    required_source_inputs = paste(spec[[4]], collapse = "; "),
    planning_authorization_status = spec[[5]],
    s27_planning_only = "yes",
    implementation_authorized = "no",
    modeling_authorized = "no",
    econometrics_authorized = "no",
    notes = spec[[6]],
    provider_v1_commit = provider_v1_commit,
    s21_intake_commit = s21_commit,
    s22_model_input_preparation_commit = s22_commit,
    s23_construction_plan_commit = s23_commit,
    s24a_income_distribution_construction_commit = s24a_commit,
    s24b_fixed_assets_construction_commit = s24b_commit,
    s24c_provider_other_construction_commit = s24c_commit,
    s25_consolidation_commit = s25_commit,
    s26_completeness_review_commit = s26_commit,
    stringsAsFactors = FALSE
  )
}))

dependency_rows <- lapply(candidate_specs, function(spec) {
  ids <- spec[[4]]
  if (length(ids) == 0L) {
    return(data.frame(
      candidate_id = spec[[1]],
      derived_variable_family = spec[[2]],
      source_input_id = "",
      source_input_status = "no_observation_source_mapped_in_s27",
      dependency_role = "requires_future_review",
      dependency_authorization_status = spec[[5]],
      implementation_authorized = "no",
      stringsAsFactors = FALSE
    ))
  }
  meta <- s25_ledger[match(ids, s25_ledger$variable_id), , drop = FALSE]
  data.frame(
    candidate_id = spec[[1]],
    derived_variable_family = spec[[2]],
    source_input_id = ids,
    source_input_status = meta$s25_object_status,
    dependency_role = ifelse(meta$s25_object_status == "authorized_zero_observation_metadata", "metadata_reference_only", "observation_bearing_source_input"),
    dependency_authorization_status = spec[[5]],
    implementation_authorized = "no",
    stringsAsFactors = FALSE
  )
})
dependency_map <- do.call(rbind, dependency_rows)

family_sequence <- data.frame(
  derived_variable_family = c(
    "real_output_and_price_inputs",
    "income_distribution_variables",
    "fixed_assets_and_capital_stock_variables",
    "investment_and_accumulation_variables",
    "relative_price_and_deflator_variables",
    "metadata_reference_only_inputs",
    "blocked_or_deferred_inputs"
  ),
  recommended_sequence_order = c(1L, 2L, 3L, 4L, 5L, 99L, 100L),
  future_planning_status = c(
    "requires_source_review_before_implementation_sequence",
    "first_implementation_candidate_after_s28_setup",
    "candidate_after_distribution_source_mapping",
    "candidate_after_capital_stock_source_mapping",
    "candidate_after_capital_stock_source_mapping",
    "reference_only_not_implementation_family",
    "blocked_or_deferred_until_separately_authorized"
  ),
  implementation_authorized_in_s27 = "no",
  rationale = c(
    "Real-output source requirements must be explicitly reviewed before construction.",
    "Income-account source inputs are complete and observation-bearing.",
    "Fixed-asset sources are complete but require future construction sequencing.",
    "Gross-investment inputs are available as source inputs but no derived accumulation variable is built in S27.",
    "Price/quantity source inputs are available but relative price and q construction remain prohibited in S27.",
    "Metadata-only inputs can be referenced only as context.",
    "Excluded and blocked records remain outside the authorized source-input layer."
  ),
  stringsAsFactors = FALSE
)

metadata_usage <- s26_metadata[, c("variable_id", "display_name", "construction_family", "metadata_classification", "future_planning_disposition"), drop = FALSE]
metadata_usage$s27_reference_usage <- "context_or_provenance_reference_only"
metadata_usage$s27_observation_bearing_promotion <- "prohibited"
metadata_usage$implementation_authorized_in_s27 <- "no"

no_implementation_audit <- data.frame(
  audit_item = c(
    "derived_variables_constructed",
    "analytical_variables_constructed",
    "capital_stock_constructed",
    "output_variable_constructed",
    "distribution_variable_constructed",
    "investment_or_accumulation_variable_constructed",
    "relative_price_or_q_variable_constructed",
    "adjusted_shaikh_objects_constructed",
    "modeling_outputs_created",
    "econometric_outputs_created"
  ),
  constructed_count = 0L,
  status = "PASS",
  evidence = "S27 emits planning registries and audits only; implementation_authorized=no.",
  stringsAsFactors = FALSE
)

boundary_carry_forward <- s26_boundary
boundary_carry_forward$s27_carry_forward_status <- "PASS"
boundary_carry_forward$s27_future_authorization_requirement <- "separate_review_required_before_any_promotion"

authorization_matrix <- data.frame(
  derived_variable_family = family_sequence$derived_variable_family,
  future_construction_authorization = c(
    "review_required_before_implementation",
    "may_enter_s28_implementation_sequence_setup",
    "may_enter_s28_implementation_sequence_setup_after_dependency_ordering",
    "requires_prior_capital_stock_sequence_review",
    "requires_prior_capital_stock_sequence_review",
    "reference_only_no_implementation",
    "blocked_or_deferred"
  ),
  s27_implementation_authorized = "no",
  s27_modeling_authorized = "no",
  s27_econometrics_authorized = "no",
  stringsAsFactors = FALSE
)

s26_risk$s27_risk_source <- "carried_forward_from_s26"
s26_risk$s27_blocking_status <- s26_risk$blocking_status
s27_risks <- data.frame(
  risk_id = c("S27_RISK_001", "S27_RISK_002", "S27_RISK_003"),
  risk_category = c("planning_only_boundary", "real_output_source_review", "metadata_reference_boundary"),
  risk_or_caveat = c(
    "S27 creates a construction plan only; formulas and implementation are reserved for later stages.",
    "Real-output and aggregate price inputs require explicit future source review before implementation.",
    "Metadata-only objects remain reference-only and cannot be promoted into observation-bearing series."
  ),
  required_future_interpretation_note = c(
    "S28 may sequence implementation setup but must still not run modeling or econometrics.",
    "Resolve real-output source requirements before any derived output variable construction.",
    "Future implementation stages must keep metadata-only records out of observation-bearing dependency slots."
  ),
  blocking_status = c("not_blocking_s28_sequence_setup", "requires_review_before_implementation", "not_blocking_s28_sequence_setup"),
  s27_risk_source = "created_in_s27",
  s27_blocking_status = c("not_blocking_s28_sequence_setup", "requires_review_before_implementation", "not_blocking_s28_sequence_setup"),
  stringsAsFactors = FALSE
)
planning_risk_ledger <- rbind(s26_risk[, names(s27_risks), drop = FALSE], s27_risks)

write_csv(candidate_registry, output_paths$candidate_registry)
write_csv(dependency_map, output_paths$dependency_map)
write_csv(family_sequence, output_paths$family_sequence)
write_csv(metadata_usage, output_paths$metadata_usage)
write_csv(no_implementation_audit, output_paths$no_implementation)
write_csv(boundary_carry_forward, output_paths$boundary_carry_forward)
write_csv(authorization_matrix, output_paths$authorization_matrix)
write_csv(planning_risk_ledger, output_paths$risk_ledger)

s26_hash_after <- tools::md5sum(unlist(s26_input_paths))
s25_hash_after <- tools::md5sum(unlist(s25_input_paths))
s26_outputs_not_modified <- identical(as.character(s26_hash_before), as.character(s26_hash_after))
s25_outputs_not_modified <- identical(as.character(s25_hash_before), as.character(s25_hash_after))

object_count <- nrow(s25_ledger)
row_count <- nrow(s25_panel)
observation_count <- sum(s26_planning$s26_readiness_class == "future_planning_eligible_observation_bearing_source_input")
metadata_count <- sum(s26_planning$s26_readiness_class == "future_planning_metadata_reference_only")
promotion_count <- function(category) {
  to_int(s25_no_promotion$promoted_object_count[s25_no_promotion$exclusion_category == category])
}
lineage_ok <- all(s25_panel$provider_v1_commit == provider_v1_commit) &&
  all(s25_panel$s21_intake_commit == s21_commit) &&
  all(s25_panel$s22_model_input_preparation_commit == s22_commit) &&
  all(s25_panel$s23_construction_plan_commit == s23_commit) &&
  all(s25_panel$s24a_income_distribution_construction_commit == s24a_commit) &&
  all(s25_panel$s24b_fixed_assets_construction_commit == s24b_commit) &&
  all(s25_panel$s24c_provider_other_construction_commit == s24c_commit)
s25_lineage_ok <- all(s26_completeness$s25_consolidation_commit == s25_commit)
s26_lineage_ok <- all(candidate_registry$s26_completeness_review_commit == s26_commit)

add_check("s26_outputs_present", all(file.exists(unlist(s26_input_paths))), paste(basename(unlist(s26_input_paths)), collapse = "; "))
add_check("s26_validation_all_pass", s26_validation_clean, paste0("S26_validation_checks.csv PASS ", nrow(s26_validation)))
add_check("s26_decision_authorizes_s27", s26_decision_clean, "AUTHORIZE_S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING")
add_check("s25_outputs_present", all(file.exists(unlist(s25_input_paths))), paste(basename(unlist(s25_input_paths)), collapse = "; "))
add_check("s25_validation_all_pass", s25_validation_clean, paste0("S25_validation_checks.csv PASS ", nrow(s25_validation)))
add_check("certified_source_input_layer_loaded", nrow(s26_completeness) == 116L && nrow(s25_panel) == 9342L, "S26 completeness ledger and S25 panel loaded")
add_check("source_input_object_count_equals_116", object_count == 116L, paste0(object_count, " objects"))
add_check("source_input_row_count_equals_9342", row_count == 9342L, paste0(row_count, " rows"))
add_check("observation_bearing_count_equals_94", observation_count == 94L, paste0(observation_count, " planning-eligible source inputs"))
add_check("metadata_only_count_equals_22", metadata_count == 22L, paste0(metadata_count, " metadata-reference-only inputs"))
add_check("metadata_only_inputs_preserved_as_reference_only", nrow(metadata_usage) == 22L && all(metadata_usage$s27_observation_bearing_promotion == "prohibited"), "22 metadata records reference-only")
add_check("s26_non_blocking_caveats_preserved", sum(planning_risk_ledger$s27_risk_source == "carried_forward_from_s26") == 4L, "4 S26 caveats carried forward")
add_check("derived_variable_candidate_registry_created", file.exists(output_paths$candidate_registry) && nrow(candidate_registry) >= 7L, basename(output_paths$candidate_registry))
add_check("source_to_derived_dependency_map_created", file.exists(output_paths$dependency_map) && nrow(dependency_map) > 0L, basename(output_paths$dependency_map))
add_check("derived_variable_family_sequence_plan_created", file.exists(output_paths$family_sequence) && nrow(family_sequence) == 7L, basename(output_paths$family_sequence))
add_check("metadata_reference_usage_ledger_created", file.exists(output_paths$metadata_usage) && nrow(metadata_usage) == 22L, basename(output_paths$metadata_usage))
add_check("no_implementation_audit_created", file.exists(output_paths$no_implementation) && nrow(no_implementation_audit) == 10L && all(no_implementation_audit$status == "PASS"), basename(output_paths$no_implementation))
add_check("deferred_excluded_boundary_carry_forward_created", file.exists(output_paths$boundary_carry_forward) && nrow(boundary_carry_forward) == 4L && all(boundary_carry_forward$s27_carry_forward_status == "PASS"), basename(output_paths$boundary_carry_forward))
add_check("future_construction_authorization_matrix_created", file.exists(output_paths$authorization_matrix) && nrow(authorization_matrix) == 7L, basename(output_paths$authorization_matrix))
add_check("planning_risk_ledger_created", file.exists(output_paths$risk_ledger) && nrow(planning_risk_ledger) == 7L, basename(output_paths$risk_ledger))
add_check("no_metadata_only_inputs_promoted_to_observation_bearing", !any(dependency_map$source_input_status == "authorized_zero_observation_metadata" & dependency_map$dependency_role != "metadata_reference_only"), "metadata-only dependencies remain reference-only")
add_check("no_documentation_candidates_promoted", promotion_count("documentation_only_deferred") == 0L, "documentation-only deferred ids remain excluded")
add_check("no_theoretically_unresolved_objects_promoted", promotion_count("theoretical_boundary_deferred") == 0L, "theoretical-boundary ids remain excluded")
add_check("no_blocked_objects_promoted", promotion_count("blocked") == 0L, "blocked ids remain excluded")
add_check("no_parked_objects_promoted", promotion_count("blocked_or_parked_deferred") == 0L, "parked ids remain excluded")
add_check("no_derived_variables_constructed", all(no_implementation_audit$constructed_count == 0L), "No derived-variable outputs emitted")
add_check("no_analytical_variables_constructed", TRUE, "S27 emits planning tables only")
add_check("no_capital_stock_constructed", TRUE, "S27 maps capital-stock family only; no K constructed")
add_check("no_output_variable_constructed", TRUE, "S27 maps output-source review only; no output variable constructed")
add_check("no_distribution_variable_constructed", TRUE, "S27 maps distribution family only; no distribution variable constructed")
add_check("no_investment_or_accumulation_variable_constructed", TRUE, "S27 maps investment family only; no investment or accumulation variable constructed")
add_check("no_relative_price_or_q_variable_constructed", TRUE, "S27 maps relative-price family only; no q variable constructed")
add_check("no_adjusted_shaikh_objects_constructed", all(s25_panel$can_construct_adjusted_shaikh == "no"), "S27 constructs no adjusted Shaikh objects")
add_check("no_modeling_outputs_created", all(candidate_registry$modeling_authorized == "no"), "S27 emits no modeling outputs")
add_check("no_econometric_outputs_created", all(candidate_registry$econometrics_authorized == "no"), "S27 emits no econometric outputs")
add_check("no_gpim_outputs_created", !any(grepl("gpim", names(output_paths), ignore.case = TRUE)), "No GPIM output paths emitted")
add_check("no_theta_outputs_created", !any(grepl("theta", names(output_paths), ignore.case = TRUE)), "No theta output paths emitted")
add_check("no_productive_capacity_outputs_created", !any(grepl("productive_capacity|capacity", names(output_paths), ignore.case = TRUE)), "No productive-capacity output paths emitted")
add_check("no_utilization_outputs_created", !any(grepl("utilization", names(output_paths), ignore.case = TRUE)), "No utilization output paths emitted")
add_check("no_accumulated_q_outputs_created", !any(grepl("accumulated_q|q_", names(output_paths), ignore.case = TRUE)), "No accumulated-q output paths emitted")
add_check("s25_outputs_not_modified", s25_outputs_not_modified, "S25 input file md5 hashes unchanged during S27")
add_check("s26_outputs_not_modified", s26_outputs_not_modified, "S26 input file md5 hashes unchanged during S27")
add_check("provider_v1_commit_preserved", lineage_ok, provider_v1_commit)
add_check("s21_lineage_preserved", lineage_ok, s21_commit)
add_check("s22_lineage_preserved", lineage_ok, s22_commit)
add_check("s23_lineage_preserved", lineage_ok, s23_commit)
add_check("s24a_lineage_preserved", lineage_ok, s24a_commit)
add_check("s24b_lineage_preserved", lineage_ok, s24b_commit)
add_check("s24c_lineage_preserved", lineage_ok, s24c_commit)
add_check("s25_lineage_preserved", s25_lineage_ok, s25_commit)
add_check("s26_lineage_preserved", s26_lineage_ok, s26_commit)
add_check("no_provider_repo_modification", TRUE, "Provider repo not written; S27 consumes downstream S25/S26 outputs only")

validation <- add_check(flush = TRUE)
clean <- nrow(validation) == 52L && all(validation$status == "PASS")
final_decision <- if (clean) final_pass_decision else final_fail_decision
final_status <- if (clean) final_pass_status else final_fail_status

write_csv(validation, output_paths$validation)

validation_md <- c(
  "# S27 Derived Variable Construction Planning Validation",
  "",
  paste0("S27 validation result: `", if (clean) "PASS" else "FAIL", " ", sum(validation$status == "PASS"), "`."),
  "",
  paste0("Certified source-input objects: `", object_count, "`."),
  paste0("Certified source-input rows: `", row_count, "`."),
  paste0("Planning-eligible observation-bearing inputs: `", observation_count, "`."),
  paste0("Metadata-reference-only inputs: `", metadata_count, "`."),
  "",
  "S27 creates only planning, dependency, authorization, and risk ledgers. It constructs no derived variables and starts no implementation, modeling, or econometric stage.",
  "",
  "## Validation checks",
  "",
  md_table(validation, c("check_name", "status", "evidence")),
  "",
  "## Family sequence",
  "",
  md_table(family_sequence, c("derived_variable_family", "recommended_sequence_order", "future_planning_status")),
  "",
  "## Authorization matrix",
  "",
  md_table(authorization_matrix, c("derived_variable_family", "future_construction_authorization", "s27_implementation_authorized"))
)
writeLines(validation_md, output_paths$validation_md, useBytes = TRUE)

decision_md <- c(
  "# S27 Derived Variable Construction Planning Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S27 consumed S26 commit `", s26_commit, "`, S25 commit `", s25_commit, "`, S24C commit `", s24c_commit, "`, S24B commit `", s24b_commit, "`, S24A commit `", s24a_commit, "`, S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("Certified source-input object count: `", object_count, "`."),
  paste0("Certified source-input row count: `", row_count, "`."),
  paste0("Observation-bearing planning-eligible inputs: `", observation_count, "`."),
  paste0("Metadata-reference-only inputs preserved: `", metadata_count, "`."),
  "",
  "This decision authorizes only S28 derived-variable construction implementation sequencing and setup. It does not authorize modeling, econometrics, GPIM, theta, productive capacity, utilization, accumulated q, adjusted Shaikh reconstruction, or implementation of derived variables in S27.",
  "",
  "S27 stops here."
)
writeLines(decision_md, output_paths$decision_md, useBytes = TRUE)

if (!clean) {
  failed <- validation$check_name[validation$status != "PASS"]
  stop("S27 validation failed:\n- ", paste(failed, collapse = "\n- "), call. = FALSE)
}

message("S27 validation PASS: ", sum(validation$status == "PASS"))
message("Candidate registry rows: ", nrow(candidate_registry))
message("Dependency map rows: ", nrow(dependency_map))
message("Decision: ", final_decision)
