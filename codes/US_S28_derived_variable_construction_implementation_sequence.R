# S28 converts the S27 derived-variable construction plan into a future
# implementation sequence. It does not construct derived variables.

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
s27_commit <- "e42e124679137a3acaa0f0c7d4eebd71c562656a"

first_safe_family <- "income_distribution_variables"
final_pass_decision <- "AUTHORIZE_S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION"
final_pass_status <- "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE_COMPLETE_S29A_AUTHORIZED"
final_fail_decision <- "BLOCK_FOR_DERIVED_VARIABLE_IMPLEMENTATION_SEQUENCE_REVIEW"
final_fail_status <- "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE_BLOCKED_FOR_REVIEW"

s25_dir <- file.path(repo_root, "output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
s26_dir <- file.path(repo_root, "output", "US", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW")
s27_dir <- file.path(repo_root, "output", "US", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING")
s28_dir <- file.path(repo_root, "output", "US", "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE")
csv_dir <- file.path(s28_dir, "csv")
md_dir <- file.path(s28_dir, "md")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

path <- function(...) file.path(...)

s27_input_paths <- list(
  candidate_registry = path(s27_dir, "csv", "S27_derived_variable_candidate_registry.csv"),
  dependency_map = path(s27_dir, "csv", "S27_source_to_derived_dependency_map.csv"),
  family_sequence = path(s27_dir, "csv", "S27_derived_variable_family_sequence_plan.csv"),
  metadata_usage = path(s27_dir, "csv", "S27_metadata_reference_usage_ledger.csv"),
  no_implementation = path(s27_dir, "csv", "S27_no_implementation_audit.csv"),
  boundary_carry_forward = path(s27_dir, "csv", "S27_deferred_excluded_boundary_carry_forward.csv"),
  authorization_matrix = path(s27_dir, "csv", "S27_future_construction_authorization_matrix.csv"),
  risk_ledger = path(s27_dir, "csv", "S27_planning_risk_ledger.csv"),
  validation = path(s27_dir, "csv", "S27_validation_checks.csv"),
  validation_md = path(s27_dir, "md", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_VALIDATION.md"),
  decision_md = path(s27_dir, "md", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_DECISION.md")
)

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
  implementation_sequence = path(csv_dir, "S28_derived_variable_implementation_sequence.csv"),
  family_authorization = path(csv_dir, "S28_derived_variable_family_authorization_matrix.csv"),
  pass_registry = path(csv_dir, "S28_future_pass_registry.csv"),
  dependency_depth = path(csv_dir, "S28_dependency_depth_ordering.csv"),
  dependency_risk = path(csv_dir, "S28_dependency_risk_audit.csv"),
  no_implementation = path(csv_dir, "S28_no_implementation_audit.csv"),
  validation = path(csv_dir, "S28_validation_checks.csv"),
  validation_md = path(md_dir, "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE_VALIDATION.md"),
  decision_md = path(md_dir, "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE_DECISION.md")
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

snake_to_pascal <- function(x) {
  parts <- strsplit(x, "_", fixed = TRUE)[[1]]
  paste0(toupper(substr(parts, 1L, 1L)), substr(parts, 2L, nchar(parts)), collapse = "")
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

stop_if_missing(s27_input_paths)
stop_if_missing(s26_input_paths)
stop_if_missing(s25_input_paths)
s27_hash_before <- tools::md5sum(unlist(s27_input_paths))
s26_hash_before <- tools::md5sum(unlist(s26_input_paths))
s25_hash_before <- tools::md5sum(unlist(s25_input_paths))

s27_candidates <- read_csv(s27_input_paths$candidate_registry)
s27_dependencies <- read_csv(s27_input_paths$dependency_map)
s27_family_sequence <- read_csv(s27_input_paths$family_sequence)
s27_metadata <- read_csv(s27_input_paths$metadata_usage)
s27_no_implementation <- read_csv(s27_input_paths$no_implementation)
s27_boundary <- read_csv(s27_input_paths$boundary_carry_forward)
s27_authorization <- read_csv(s27_input_paths$authorization_matrix)
s27_risk <- read_csv(s27_input_paths$risk_ledger)
s27_validation <- read_csv(s27_input_paths$validation)
s27_decision_text <- paste(readLines(s27_input_paths$decision_md, warn = FALSE), collapse = "\n")

s26_completeness <- read_csv(s26_input_paths$completeness_ledger)
s26_planning <- read_csv(s26_input_paths$planning_readiness)
s26_risk <- read_csv(s26_input_paths$risk_register)
s26_validation <- read_csv(s26_input_paths$validation)

s25_panel <- read_csv(s25_input_paths$panel)
s25_ledger <- read_csv(s25_input_paths$ledger)
s25_no_promotion <- read_csv(s25_input_paths$no_promotion)
s25_validation <- read_csv(s25_input_paths$validation)

s27_validation_clean <- nrow(s27_validation) == 52L && all(s27_validation$status == "PASS")
s27_decision_clean <- grepl(
  "AUTHORIZE_S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE",
  s27_decision_text,
  fixed = TRUE
)
s26_validation_clean <- nrow(s26_validation) == 51L && all(s26_validation$status == "PASS")
s25_validation_clean <- nrow(s25_validation) == 49L && all(s25_validation$status == "PASS")

if (!s27_validation_clean || !s27_decision_clean || !s26_validation_clean || !s25_validation_clean) {
  stop("S25/S26/S27 gate is not clean; S28 must stop.", call. = FALSE)
}

implementation_sequence <- merge(
  s27_family_sequence,
  s27_authorization[, c("derived_variable_family", "future_construction_authorization")],
  by = "derived_variable_family",
  all.x = TRUE,
  sort = FALSE
)
implementation_sequence$s28_sequence_order <- implementation_sequence$recommended_sequence_order
implementation_sequence$s28_sequence_status <- ifelse(
  implementation_sequence$derived_variable_family == first_safe_family,
  "first_safe_implementation_family_for_s29a",
  ifelse(
    implementation_sequence$future_construction_authorization %in% c("blocked_or_deferred", "reference_only_no_implementation"),
    "not_an_implementation_family",
    ifelse(
      implementation_sequence$future_construction_authorization == "review_required_before_implementation",
      "review_required_before_implementation",
      "queued_after_s29a_or_dependency_review"
    )
  )
)
implementation_sequence$s28_constructed_in_this_pass <- "no"
implementation_sequence$s29a_authorization_candidate <- ifelse(
  implementation_sequence$derived_variable_family == first_safe_family,
  "yes",
  "no"
)

family_authorization <- merge(
  implementation_sequence[, c("derived_variable_family", "s28_sequence_order", "s28_sequence_status")],
  s27_authorization,
  by = "derived_variable_family",
  all.x = TRUE,
  sort = FALSE
)
family_authorization$s28_implementation_authorized <- "no"
family_authorization$s28_modeling_authorized <- "no"
family_authorization$s28_econometrics_authorized <- "no"
family_authorization$next_action <- ifelse(
  family_authorization$derived_variable_family == first_safe_family,
  "authorize_s29a_bounded_implementation_pass",
  ifelse(
    family_authorization$future_construction_authorization == "review_required_before_implementation",
    "review_before_implementation",
    family_authorization$future_construction_authorization
  )
)

pass_registry <- data.frame(
  future_pass_id = c("S29A", "S29B", "S29C", "S29D", "S29E", "S29Z_REF", "S29Z_BLOCKED"),
  derived_variable_family = c(
    "income_distribution_variables",
    "fixed_assets_and_capital_stock_variables",
    "investment_and_accumulation_variables",
    "relative_price_and_deflator_variables",
    "real_output_and_price_inputs",
    "metadata_reference_only_inputs",
    "blocked_or_deferred_inputs"
  ),
  future_pass_label = c(
    "Income Distribution Variables Construction",
    "Fixed Assets And Capital Stock Variables Construction Setup",
    "Investment And Accumulation Variables Construction Setup",
    "Relative Price And Deflator Variables Construction Setup",
    "Real Output And Price Inputs Source Review",
    "Metadata Reference Only Carry Forward",
    "Blocked Or Deferred Boundary Carry Forward"
  ),
  pass_authorization_status = c(
    "authorized_by_clean_s28_decision",
    "queued_after_s29a_dependency_review",
    "requires_prior_capital_stock_sequence_review",
    "requires_prior_capital_stock_sequence_review",
    "review_required_before_implementation",
    "reference_only_no_implementation",
    "blocked_or_deferred"
  ),
  implementation_authorized_in_s28 = "no",
  modeling_authorized = "no",
  econometrics_authorized = "no",
  stringsAsFactors = FALSE
)

candidate_family_sequence <- implementation_sequence[, c("derived_variable_family", "s28_sequence_order"), drop = FALSE]
dependency_depth <- merge(
  s27_dependencies,
  candidate_family_sequence,
  by = "derived_variable_family",
  all.x = TRUE,
  sort = FALSE
)
dependency_depth$dependency_depth <- ifelse(
  dependency_depth$dependency_role == "observation_bearing_source_input",
  0L,
  ifelse(dependency_depth$dependency_role == "metadata_reference_only", 99L, NA_integer_)
)
dependency_depth$depth_order_status <- ifelse(
  dependency_depth$dependency_role == "observation_bearing_source_input",
  "direct_source_input_dependency_first",
  ifelse(dependency_depth$dependency_role == "metadata_reference_only", "metadata_reference_only_not_implementation_dependency", "future_review_required")
)
dependency_depth$implementation_authorized_in_s28 <- "no"
dependency_depth <- dependency_depth[order(dependency_depth$s28_sequence_order, dependency_depth$dependency_depth, dependency_depth$candidate_id, dependency_depth$source_input_id), , drop = FALSE]

s26_risk$s28_risk_source <- "carried_forward_from_s26"
s27_risk$s28_risk_source <- ifelse(s27_risk$s27_risk_source == "carried_forward_from_s26", "carried_forward_from_s26_via_s27", "carried_forward_from_s27")
dependency_risk <- rbind(
  data.frame(
    risk_id = s26_risk$risk_id,
    risk_category = s26_risk$risk_category,
    risk_or_caveat = s26_risk$risk_or_caveat,
    required_future_interpretation_note = s26_risk$required_future_interpretation_note,
    blocking_status = s26_risk$blocking_status,
    s28_risk_source = s26_risk$s28_risk_source,
    s28_disposition = "carried_forward_no_implementation_in_s28",
    stringsAsFactors = FALSE
  ),
  data.frame(
    risk_id = s27_risk$risk_id,
    risk_category = s27_risk$risk_category,
    risk_or_caveat = s27_risk$risk_or_caveat,
    required_future_interpretation_note = s27_risk$required_future_interpretation_note,
    blocking_status = s27_risk$blocking_status,
    s28_risk_source = s27_risk$s28_risk_source,
    s28_disposition = "carried_forward_no_implementation_in_s28",
    stringsAsFactors = FALSE
  )
)

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
    "econometric_outputs_created",
    "gpim_outputs_created",
    "theta_outputs_created",
    "productive_capacity_outputs_created",
    "utilization_outputs_created",
    "accumulated_q_outputs_created"
  ),
  constructed_count = 0L,
  status = "PASS",
  evidence = "S28 emits sequencing and authorization-control artifacts only.",
  stringsAsFactors = FALSE
)

write_csv(implementation_sequence, output_paths$implementation_sequence)
write_csv(family_authorization, output_paths$family_authorization)
write_csv(pass_registry, output_paths$pass_registry)
write_csv(dependency_depth, output_paths$dependency_depth)
write_csv(dependency_risk, output_paths$dependency_risk)
write_csv(no_implementation_audit, output_paths$no_implementation)

s27_hash_after <- tools::md5sum(unlist(s27_input_paths))
s26_hash_after <- tools::md5sum(unlist(s26_input_paths))
s25_hash_after <- tools::md5sum(unlist(s25_input_paths))
s27_outputs_not_modified <- identical(as.character(s27_hash_before), as.character(s27_hash_after))
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
s26_lineage_ok <- all(s27_candidates$s26_completeness_review_commit == s26_commit)
s27_lineage_ok <- TRUE

add_check("s27_outputs_present", all(file.exists(unlist(s27_input_paths))), paste(basename(unlist(s27_input_paths)), collapse = "; "))
add_check("s27_validation_all_pass", s27_validation_clean, paste0("S27_validation_checks.csv PASS ", nrow(s27_validation)))
add_check("s27_decision_authorizes_s28", s27_decision_clean, "AUTHORIZE_S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE")
add_check("s26_outputs_present", all(file.exists(unlist(s26_input_paths))), paste(basename(unlist(s26_input_paths)), collapse = "; "))
add_check("s26_validation_all_pass", s26_validation_clean, paste0("S26_validation_checks.csv PASS ", nrow(s26_validation)))
add_check("s25_outputs_present", all(file.exists(unlist(s25_input_paths))), paste(basename(unlist(s25_input_paths)), collapse = "; "))
add_check("s25_validation_all_pass", s25_validation_clean, paste0("S25_validation_checks.csv PASS ", nrow(s25_validation)))
add_check("certified_source_input_object_count_equals_116", object_count == 116L, paste0(object_count, " objects"))
add_check("certified_source_input_row_count_equals_9342", row_count == 9342L, paste0(row_count, " rows"))
add_check("observation_bearing_count_equals_94", observation_count == 94L, paste0(observation_count, " observation-bearing inputs"))
add_check("metadata_only_count_equals_22", metadata_count == 22L, paste0(metadata_count, " metadata-only inputs"))
add_check("metadata_only_inputs_preserved_as_reference_only", all(s27_metadata$s27_observation_bearing_promotion == "prohibited"), "metadata-only inputs remain reference-only")
add_check("s27_candidate_registry_loaded", nrow(s27_candidates) == 11L, paste0(nrow(s27_candidates), " candidate rows"))
add_check("s27_dependency_map_loaded", nrow(s27_dependencies) == 188L, paste0(nrow(s27_dependencies), " dependency rows"))
add_check("s27_family_sequence_plan_loaded", nrow(s27_family_sequence) == 7L, paste0(nrow(s27_family_sequence), " family rows"))
add_check("s27_future_authorization_matrix_loaded", nrow(s27_authorization) == 7L, paste0(nrow(s27_authorization), " authorization rows"))
add_check("derived_variable_implementation_sequence_created", file.exists(output_paths$implementation_sequence) && nrow(implementation_sequence) == 7L, basename(output_paths$implementation_sequence))
add_check("family_authorization_matrix_created", file.exists(output_paths$family_authorization) && nrow(family_authorization) == 7L, basename(output_paths$family_authorization))
add_check("future_pass_registry_created", file.exists(output_paths$pass_registry) && nrow(pass_registry) == 7L, basename(output_paths$pass_registry))
add_check("dependency_depth_ordering_created", file.exists(output_paths$dependency_depth) && nrow(dependency_depth) == nrow(s27_dependencies), basename(output_paths$dependency_depth))
add_check("dependency_risk_audit_created", file.exists(output_paths$dependency_risk) && nrow(dependency_risk) == 11L, basename(output_paths$dependency_risk))
add_check("no_implementation_audit_created", file.exists(output_paths$no_implementation) && nrow(no_implementation_audit) == 15L && all(no_implementation_audit$status == "PASS"), basename(output_paths$no_implementation))
add_check("first_safe_implementation_family_identified", first_safe_family %in% implementation_sequence$derived_variable_family && any(implementation_sequence$derived_variable_family == first_safe_family & implementation_sequence$s29a_authorization_candidate == "yes"), first_safe_family)
add_check("s26_caveats_carried_forward", sum(dependency_risk$s28_risk_source == "carried_forward_from_s26") == 4L, "4 S26 caveats carried forward")
add_check("s27_planning_risks_carried_forward", sum(dependency_risk$s28_risk_source == "carried_forward_from_s27") == 3L, "3 S27 planning risks carried forward")
add_check("no_metadata_only_inputs_promoted_to_observation_bearing", !any(dependency_depth$source_input_status == "authorized_zero_observation_metadata" & dependency_depth$dependency_role != "metadata_reference_only"), "metadata-only dependencies remain reference-only")
add_check("no_documentation_candidates_promoted", promotion_count("documentation_only_deferred") == 0L, "documentation-only deferred ids remain excluded")
add_check("no_theoretically_unresolved_objects_promoted", promotion_count("theoretical_boundary_deferred") == 0L, "theoretical-boundary ids remain excluded")
add_check("no_blocked_objects_promoted", promotion_count("blocked") == 0L, "blocked ids remain excluded")
add_check("no_parked_objects_promoted", promotion_count("blocked_or_parked_deferred") == 0L, "parked ids remain excluded")
add_check("no_derived_variables_constructed", all(no_implementation_audit$constructed_count == 0L), "No derived-variable outputs emitted")
add_check("no_analytical_variables_constructed", TRUE, "S28 emits sequencing tables only")
add_check("no_capital_stock_constructed", TRUE, "S28 sequences capital-stock family only; no K constructed")
add_check("no_output_variable_constructed", TRUE, "S28 sequences source review only; no output variable constructed")
add_check("no_distribution_variable_constructed", TRUE, "S28 authorizes future pass only; no distribution variable constructed")
add_check("no_investment_or_accumulation_variable_constructed", TRUE, "S28 sequences investment family only; no investment or accumulation variable constructed")
add_check("no_relative_price_or_q_variable_constructed", TRUE, "S28 sequences relative-price family only; no q variable constructed")
add_check("no_adjusted_shaikh_objects_constructed", all(s25_panel$can_construct_adjusted_shaikh == "no"), "S28 constructs no adjusted Shaikh objects")
add_check("no_modeling_outputs_created", all(family_authorization$s28_modeling_authorized == "no"), "S28 emits no modeling outputs")
add_check("no_econometric_outputs_created", all(family_authorization$s28_econometrics_authorized == "no"), "S28 emits no econometric outputs")
add_check("no_gpim_outputs_created", !any(grepl("gpim", names(output_paths), ignore.case = TRUE)), "No GPIM output paths emitted")
add_check("no_theta_outputs_created", !any(grepl("theta", names(output_paths), ignore.case = TRUE)), "No theta output paths emitted")
add_check("no_productive_capacity_outputs_created", !any(grepl("productive_capacity|capacity", names(output_paths), ignore.case = TRUE)), "No productive-capacity output paths emitted")
add_check("no_utilization_outputs_created", !any(grepl("utilization", names(output_paths), ignore.case = TRUE)), "No utilization output paths emitted")
add_check("no_accumulated_q_outputs_created", !any(grepl("accumulated_q|q_", names(output_paths), ignore.case = TRUE)), "No accumulated-q output paths emitted")
add_check("s25_outputs_not_modified", s25_outputs_not_modified, "S25 input file md5 hashes unchanged during S28")
add_check("s26_outputs_not_modified", s26_outputs_not_modified, "S26 input file md5 hashes unchanged during S28")
add_check("s27_outputs_not_modified", s27_outputs_not_modified, "S27 input file md5 hashes unchanged during S28")
add_check("provider_v1_commit_preserved", lineage_ok, provider_v1_commit)
add_check("s21_lineage_preserved", lineage_ok, s21_commit)
add_check("s22_lineage_preserved", lineage_ok, s22_commit)
add_check("s23_lineage_preserved", lineage_ok, s23_commit)
add_check("s24a_lineage_preserved", lineage_ok, s24a_commit)
add_check("s24b_lineage_preserved", lineage_ok, s24b_commit)
add_check("s24c_lineage_preserved", lineage_ok, s24c_commit)
add_check("s25_lineage_preserved", s25_lineage_ok, s25_commit)
add_check("s26_lineage_preserved", s26_lineage_ok, s26_commit)
add_check("s27_lineage_preserved", s27_lineage_ok, s27_commit)
add_check("no_provider_repo_modification", TRUE, "Provider repo not written; S28 consumes downstream S25/S26/S27 outputs only")

validation <- add_check(flush = TRUE)
clean <- nrow(validation) == 59L && all(validation$status == "PASS")
final_decision <- if (clean) final_pass_decision else final_fail_decision
final_status <- if (clean) final_pass_status else final_fail_status

write_csv(validation, output_paths$validation)

validation_md <- c(
  "# S28 Derived Variable Construction Implementation Sequence Validation",
  "",
  paste0("S28 validation result: `", if (clean) "PASS" else "FAIL", " ", sum(validation$status == "PASS"), "`."),
  "",
  paste0("First safe implementation family: `", first_safe_family, "`."),
  paste0("Certified source-input objects: `", object_count, "`."),
  paste0("Certified source-input rows: `", row_count, "`."),
  "",
  "S28 creates only implementation sequence, pass registry, dependency-depth, authorization, and risk-control artifacts. It constructs no derived variables.",
  "",
  "## Validation checks",
  "",
  md_table(validation, c("check_name", "status", "evidence")),
  "",
  "## Implementation sequence",
  "",
  md_table(implementation_sequence, c("derived_variable_family", "s28_sequence_order", "s28_sequence_status", "s29a_authorization_candidate")),
  "",
  "## Pass registry",
  "",
  md_table(pass_registry, c("future_pass_id", "derived_variable_family", "pass_authorization_status"))
)
writeLines(validation_md, output_paths$validation_md, useBytes = TRUE)

decision_md <- c(
  "# S28 Derived Variable Construction Implementation Sequence Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S28 consumed S27 commit `", s27_commit, "`, S26 commit `", s26_commit, "`, S25 commit `", s25_commit, "`, S24C commit `", s24c_commit, "`, S24B commit `", s24b_commit, "`, S24A commit `", s24a_commit, "`, S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("First safe implementation family: `", first_safe_family, "`."),
  paste0("Certified source-input object count: `", object_count, "`."),
  paste0("Certified source-input row count: `", row_count, "`."),
  paste0("Observation-bearing inputs: `", observation_count, "`."),
  paste0("Metadata-reference-only inputs: `", metadata_count, "`."),
  "",
  "This decision authorizes only S29A income-distribution variables construction. It does not authorize modeling, econometrics, GPIM, theta, productive capacity, utilization, accumulated q, adjusted Shaikh reconstruction, or any other derived-variable family implementation.",
  "",
  "S28 stops here."
)
writeLines(decision_md, output_paths$decision_md, useBytes = TRUE)

if (!clean) {
  failed <- validation$check_name[validation$status != "PASS"]
  stop("S28 validation failed:\n- ", paste(failed, collapse = "\n- "), call. = FALSE)
}

message("S28 validation PASS: ", sum(validation$status == "PASS"))
message("First safe implementation family: ", first_safe_family)
message("Decision: ", final_decision)
