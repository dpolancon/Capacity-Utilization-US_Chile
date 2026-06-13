#!/usr/bin/env Rscript

# S12D-A3 audits existing project documentation for an external depreciation
# or age-price anchor. It does not fetch data, lock a GPIM baseline, or
# construct final GPIM stocks.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S12D-A3 from the downstream repository root.", call. = FALSE)
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

provider_repo <- normalizePath(
  file.path(repo_root, "..", "US-BEA-Income-FixedAssets-Dataset"),
  winslash = "/",
  mustWork = TRUE
)

input_paths <- c(
  s12d_a2_registry = file.path(
    repo_root, "output", "US", "S12D_A2_NET_VALUE_SCHEDULE_PROTOCOL",
    "csv", "S12D_A2_schedule_registry.csv"
  ),
  s12d_a2_decision = file.path(
    repo_root, "output", "US", "S12D_A2_NET_VALUE_SCHEDULE_PROTOCOL",
    "csv", "S12D_A2_protocol_decision_ledger.csv"
  ),
  s12d_a2_validation = file.path(
    repo_root, "output", "US", "S12D_A2_NET_VALUE_SCHEDULE_PROTOCOL",
    "csv", "S12D_A2_validation_checks.csv"
  ),
  s11b_crosswalk = file.path(
    repo_root, "output", "US", "S11B_NIPA_HANDBOOK_CROSSWALK",
    "csv", "S11B_handbook_crosswalk_ledger.csv"
  ),
  provider_weibull_note = file.path(
    provider_repo, "docs", "Weibull_Retirement_Distributions.md"
  ),
  provider_legacy_pipeline = file.path(
    provider_repo, "docs", "_legacy", "dataset_pipeline.md"
  ),
  provider_architecture = file.path(
    provider_repo, "docs", "KSTOCK_Architecture_v1.md"
  )
)
missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  abort(paste0(
    "Missing S12D-A3 inputs:\n- ",
    paste(unname(missing_inputs), collapse = "\n- ")
  ))
}

s12d_a2_registry <- read_csv(input_paths[["s12d_a2_registry"]])
s12d_a2_decision <- read_csv(input_paths[["s12d_a2_decision"]])
s12d_a2_validation <- read_csv(input_paths[["s12d_a2_validation"]])
s11b_crosswalk <- read_csv(input_paths[["s11b_crosswalk"]])
weibull_note <- paste(
  readLines(input_paths[["provider_weibull_note"]], warn = FALSE),
  collapse = "\n"
)
legacy_pipeline <- paste(
  readLines(input_paths[["provider_legacy_pipeline"]], warn = FALSE),
  collapse = "\n"
)
architecture_note <- paste(
  readLines(input_paths[["provider_architecture"]], warn = FALSE),
  collapse = "\n"
)

require_condition(
  nrow(s12d_a2_validation) > 0L &&
    all(s12d_a2_validation$result == "PASS"),
  "S12D-A2 validation is not fully PASS."
)
require_condition(
  sum(s12d_a2_decision$protocol_item == "final_protocol_decision") == 1L &&
    s12d_a2_decision$status[
      s12d_a2_decision$protocol_item == "final_protocol_decision"
    ] == "REQUIRE_S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR",
  "S12D-A2 did not authorize the bounded S12D-A3 review."
)
require_condition(
  all(s12d_a2_registry$baseline_lockable == "FALSE"),
  "S12D-A2 unexpectedly contains a baseline-lockable schedule."
)

required_evidence_markers <- c(
  "Fraumeni (1997): BEA Post-1997 Geometric Depreciation Rates",
  "Structures: z",
  "Equipment: z",
  "| ME | 15 years | 1.65 | 0.110",
  "| NRC | 38 years | 0.91 | 0.024",
  "retirement rate",
  "depreciation rate"
)
evidence_corpus <- paste(weibull_note, legacy_pipeline, architecture_note)
require_condition(
  all(vapply(
    required_evidence_markers,
    grepl,
    logical(1L),
    x = evidence_corpus,
    fixed = TRUE
  )),
  "Existing project documentation lacks one or more required evidence markers."
)

crosswalk_rows <- s11b_crosswalk[
  s11b_crosswalk$target_variable %in% c(
    "me_stock_price_or_revaluation_index",
    "nrc_stock_price_or_revaluation_index",
    "FAAt402"
  ),
  ,
  drop = FALSE
]
require_condition(
  nrow(crosswalk_rows) == 3L &&
    all(crosswalk_rows$decision %in% c(
      "no_baseline_change", "validation_only_confirmed"
    )),
  "S11B crosswalk does not preserve the capital-price boundary."
)

output_root <- file.path(
  repo_root, "output", "US", "S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

paths <- c(
  registry = file.path(csv_dir, "S12D_A3_external_anchor_registry.csv"),
  mapping = file.path(csv_dir, "S12D_A3_schedule_mapping.csv"),
  decision = file.path(csv_dir, "S12D_A3_protocol_decision_ledger.csv"),
  validation = file.path(csv_dir, "S12D_A3_validation_checks.csv"),
  report = file.path(md_dir, "S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR.md")
)

candidate_anchors <- data.frame(
  anchor_id = c(
    "BEA_GEOMETRIC_DEPRECIATION_PROFILE",
    "BEA_DECLINING_BALANCE_SERVICE_LIFE_PROFILE",
    "CFC_NET_STOCK_IMPLIED_AGGREGATE_RATE",
    "LIFE_IMPLIED_GEOMETRIC_DEPRECIATION_RATE",
    "LINEAR_AGE_PRICE_SCHEDULE",
    "HYBRID_SENSITIVITY_SCHEDULE"
  ),
  evidence_type = c(
    "external_methodology_family",
    "external_methodology_rate_and_service_life",
    "internal_aggregate_diagnostic",
    "internal_parameter_transformation",
    "internal_assumption",
    "internal_assumption"
  ),
  stringsAsFactors = FALSE
)

asset_parameters <- data.frame(
  asset_block = c("ME", "NRC"),
  external_depreciation_rate = c(0.110, 0.024),
  documented_service_life = c(15, 38),
  documented_declining_balance_factor = c(1.65, 0.91),
  locked_survival_life = c(14, 30),
  locked_survival_shape = c(1.7, 1.6),
  stringsAsFactors = FALSE
)

registry_parts <- list()
for (asset_row in seq_len(nrow(asset_parameters))) {
  asset <- asset_parameters$asset_block[asset_row]
  depreciation_rate <- asset_parameters$external_depreciation_rate[asset_row]
  service_life <- asset_parameters$documented_service_life[asset_row]
  declining_balance <- asset_parameters$documented_declining_balance_factor[
    asset_row
  ]
  for (anchor_row in seq_len(nrow(candidate_anchors))) {
    anchor <- candidate_anchors$anchor_id[anchor_row]
    details <- switch(
      anchor,
      BEA_GEOMETRIC_DEPRECIATION_PROFILE = list(
        object_identified = "age_price_profile_family",
        evidence_value = paste0(
          "geometric age-price decline; documented broad-asset rate ",
          format(depreciation_rate, nsmall = 3)
        ),
        evidence_source = paste(
          "Fraumeni (1997) summary in provider",
          "docs/Weibull_Retirement_Distributions.md"
        ),
        evidence_scope = paste0(
          asset, " broad asset family; detailed underlying assets vary"
        ),
        classification = "ROBUSTNESS_ONLY",
        reason = paste(
          "The geometric family is explicit, but BEA's post-1997 framework",
          "does not by itself specify how to combine infinite-life geometric",
          "age-price decay with the project's separate finite Weibull survival."
        )
      ),
      BEA_DECLINING_BALANCE_SERVICE_LIFE_PROFILE = list(
        object_identified = "depreciation_rate_and_age_price_family",
        evidence_value = paste0(
          "L=", service_life, "; R=", declining_balance,
          "; d=R/L=", format(depreciation_rate, nsmall = 3)
        ),
        evidence_source = paste(
          "existing provider docs/_legacy/dataset_pipeline.md and Fraumeni",
          "methodology summary"
        ),
        evidence_scope = paste0(
          asset, " broad asset family; not a capital-price index"
        ),
        classification = "ROBUSTNESS_ONLY",
        reason = paste(
          "This is the strongest explicit asset-specific age-price anchor",
          "already documented, but promoting V(j)=S(j)(1-d)^j requires a",
          "manual theory decision because survival and age-price decay are",
          "separate objects."
        )
      ),
      CFC_NET_STOCK_IMPLIED_AGGREGATE_RATE = list(
        object_identified = "aggregate_depreciation_diagnostic",
        evidence_value = if (asset == "ME") {
          "median CFC_CC/K_NET_CC = 0.11603259"
        } else {
          "median CFC_CC/K_NET_CC = 0.02789944"
        },
        evidence_source = "locked S12C FAAt404 CFC and FAAt401 net stock",
        evidence_scope = paste0(asset, " NFC aggregate annual ratio"),
        classification = "INSUFFICIENT_EVIDENCE",
        reason = paste(
          "An aggregate flow/stock ratio is not a vintage age-price profile",
          "and cannot be promoted without an independently justified form."
        )
      ),
      LIFE_IMPLIED_GEOMETRIC_DEPRECIATION_RATE = list(
        object_identified = "life_based_rate_assumption",
        evidence_value = paste0(
          "1/L_survival = ",
          format(
            1 / asset_parameters$locked_survival_life[asset_row],
            digits = 8
          )
        ),
        evidence_source = "locked S12C survival service life",
        evidence_scope = paste0(asset, " physical survival parameter"),
        classification = "SENSITIVITY_ONLY",
        reason = paste(
          "The reciprocal of service life is a retirement-rate proxy, not",
          "an externally identified depreciation or age-price rate."
        )
      ),
      LINEAR_AGE_PRICE_SCHEDULE = list(
        object_identified = "assumed_age_price_profile",
        evidence_value = "max(1-j/L,0)",
        evidence_source = "S12D-A diagnostic candidate",
        evidence_scope = paste0(asset, " assumed finite-life profile"),
        classification = "SENSITIVITY_ONLY",
        reason = paste(
          "No existing external methodology evidence selects straight-line",
          "age-price decay for the baseline."
        )
      ),
      HYBRID_SENSITIVITY_SCHEDULE = list(
        object_identified = "assumed_blended_age_price_profile",
        evidence_value = "0.5*linear + 0.5*declining-balance",
        evidence_source = "S12D-A2 sensitivity construction",
        evidence_scope = paste0(asset, " diagnostic blend"),
        classification = "SENSITIVITY_ONLY",
        reason = "The blend has no independent external interpretation."
      )
    )
    registry_parts[[length(registry_parts) + 1L]] <- data.frame(
      anchor_id = anchor,
      asset_block = asset,
      evidence_type = candidate_anchors$evidence_type[anchor_row],
      object_identified = details$object_identified,
      evidence_value = details$evidence_value,
      evidence_source = details$evidence_source,
      evidence_scope = details$evidence_scope,
      classification = details$classification,
      baseline_lockable_without_manual_choice = "FALSE",
      distinguishes_survival_from_value = "TRUE",
      uses_faat402_as_price = "FALSE",
      uses_output_price_as_capital_price = "FALSE",
      reason = details$reason,
      notes = paste(
        "Productive-efficiency profile and capital-price index remain",
        "separate objects."
      ),
      stringsAsFactors = FALSE
    )
  }
}
anchor_registry <- do.call(rbind, registry_parts)
rownames(anchor_registry) <- NULL

schedule_mapping <- do.call(
  rbind,
  lapply(seq_len(nrow(asset_parameters)), function(i) {
    asset <- asset_parameters$asset_block[i]
    rate <- asset_parameters$external_depreciation_rate[i]
    data.frame(
      asset_block = asset,
      recommended_anchor_id =
        "BEA_DECLINING_BALANCE_SERVICE_LIFE_PROFILE",
      mapped_schedule_family =
        "FINITE_SURVIVAL_CONDITIONAL_DECLINING_BALANCE_AGE_PRICE",
      survival_profile = paste0(
        "S_", asset, "(j)=Weibull(L=",
        asset_parameters$locked_survival_life[i], ", alpha=",
        asset_parameters$locked_survival_shape[i], ")"
      ),
      age_price_profile = paste0(
        "A_", asset, "(j)=(1-", format(rate, nsmall = 3), ")^j"
      ),
      net_value_schedule = paste0(
        "V_", asset, "(j)=S_", asset, "(j)*(1-",
        format(rate, nsmall = 3), ")^j"
      ),
      depreciation_rate = rate,
      depreciation_rate_role =
        "external broad-asset age-price anchor",
      productive_efficiency_profile =
        "not_constructed_separate_future_object",
      capital_price_index =
        "SFC_implicit_price_conditional_on_manually_locked_schedule",
      current_classification = "ROBUSTNESS_ONLY",
      baseline_lockable_now = "FALSE",
      manual_theory_choice_required = "TRUE",
      aggregation_limitation = paste(
        "Broad asset-family rate summarizes heterogeneous detailed assets;",
        "time-varying composition is not modeled."
      ),
      notes = paste(
        "The formula is proposed for manual lock; it is not activated by",
        "this diagnostic pass."
      ),
      stringsAsFactors = FALSE
    )
  })
)

protocol_sentence <- paste(
  "For the Chapter 2 GPIM baseline, net-value weights shall be defined",
  "separately from physical survival as V_i(j)=S_i(j)(1-d_i)^j, where",
  "S_i(j) is the locked asset-specific Weibull survival schedule and the",
  "documented declining-balance age-price rates are d_ME=0.110 and",
  "d_NRC=0.024. These rates are age-price/depreciation anchors only; they",
  "are not retirement rates, productive-efficiency profiles, FAAt402 price",
  "indexes, NFC output deflators, or final capital-price indexes."
)
final_decision <- "REQUIRE_MANUAL_THEORY_LOCK"

decision_ledger <- data.frame(
  protocol_item = c(
    "depreciation_rate_role",
    "age_price_profile_role",
    "survival_profile_role",
    "productive_efficiency_profile_role",
    "capital_price_index_role",
    "ME_external_anchor",
    "NRC_external_anchor",
    "shared_profile_family",
    "proposed_dissertation_protocol_sentence",
    "final_stage_gate_decision"
  ),
  asset_block = c(
    "ME_NRC", "ME_NRC", "ME_NRC", "ME_NRC", "ME_NRC",
    "ME", "NRC", "ME_NRC", "ME_NRC", "ME_NRC"
  ),
  status = c(
    "EXTERNAL_RATE_EVIDENCE_AVAILABLE",
    "PROFILE_FAMILY_SUPPORTED_MANUAL_LOCK_REQUIRED",
    "LOCKED_SEPARATE_WEIBULL_OBJECT",
    "NOT_CONSTRUCTED",
    "CONDITIONAL_SFC_OUTPUT",
    "PROPOSED_MANUAL_LOCK",
    "PROPOSED_MANUAL_LOCK",
    "COMMON_FAMILY_ASSET_SPECIFIC_RATES",
    "PROPOSED_MANUAL_LOCK_TEXT",
    final_decision
  ),
  baseline_allowed = c(
    "FALSE", "FALSE", "survival_role_only", "FALSE", "FALSE",
    "FALSE", "FALSE", "FALSE", "FALSE", "FALSE"
  ),
  decision = c(
    paste(
      "Documented declining-balance rates identify value decay, not",
      "retirement, efficiency, or capital prices."
    ),
    paste(
      "A declining-balance family is supported, but combining it with",
      "finite Weibull survival requires a manual conceptual lock."
    ),
    "Retain the locked Weibull survival schedules without relabeling them.",
    "Defer productive service contribution to a separate protocol.",
    paste(
      "Recover the SFC implicit capital price only after the net-value",
      "schedule receives a manual lock."
    ),
    "Proposed ME age-price rate: d_ME=0.110.",
    "Proposed NRC age-price rate: d_NRC=0.024.",
    paste(
      "ME and NRC may share the declining-balance profile family but require",
      "different asset-specific rates and survival parameters."
    ),
    protocol_sentence,
    paste(
      "Evidence supports a precise schedule proposal, but S12D-B remains",
      "blocked until the dissertation/source-of-truth notes manually adopt",
      "or reject the proposed protocol sentence."
    )
  ),
  evidence = c(
    "Fraumeni/BEA methodology summaries and existing project rate table.",
    "External geometric/declining-balance evidence plus project survival lock.",
    "S12C L_ME/alpha_ME and L_NRC/alpha_NRC.",
    "No productive-efficiency evidence is used.",
    "S12D-A recursive recovery conditional on value weights.",
    "Existing project table: ME L=15, R=1.65, d=0.110.",
    "Existing project table: NRC L=38, R=0.91, d=0.024.",
    "Asset-specific evidence reviewed in the external anchor registry.",
    "Exact text generated by S12D-A3 for manual adoption.",
    "No schedule is automatically baseline-lockable."
  ),
  next_step = c(
    "manual_theory_review",
    "manual_theory_review",
    "retain_for_future_GPIM",
    "defer",
    "blocked_pending_manual_lock",
    "manual_theory_review",
    "manual_theory_review",
    "manual_theory_review",
    "manual_adoption_or_rejection",
    "manual_theory_lock_before_S12D_B"
  ),
  notes = c(
    "", "", "", "", "",
    "Not activated in this pass.",
    "Not activated in this pass.",
    "No single common rate is permitted.",
    "This sentence is proposed, not automatically locked.",
    "Decision B selected; decisions A, C, and D are not selected."
  ),
  stringsAsFactors = FALSE
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
  "all six required external anchors evaluated",
  setequal(unique(anchor_registry$anchor_id), candidate_anchors$anchor_id),
  paste(unique(anchor_registry$anchor_id), collapse = "; ")
)
add_check(
  "ME and NRC evaluated separately",
  nrow(anchor_registry) == 12L &&
    setequal(unique(anchor_registry$asset_block), c("ME", "NRC")),
  paste0(nrow(anchor_registry), " asset-anchor rows")
)
add_check(
  "anchor classifications controlled",
  all(anchor_registry$classification %in% c(
    "BASELINE_LOCKABLE", "ROBUSTNESS_ONLY", "SENSITIVITY_ONLY",
    "REJECTED", "INSUFFICIENT_EVIDENCE"
  )),
  paste(sort(unique(anchor_registry$classification)), collapse = "; ")
)
add_check(
  "depreciation age-price survival efficiency and price separated",
  all(c(
    "depreciation_rate_role", "age_price_profile_role",
    "survival_profile_role", "productive_efficiency_profile_role",
    "capital_price_index_role"
  ) %in% decision_ledger$protocol_item),
  "five distinct protocol rows"
)
add_check(
  "survival-only not accepted as net-value schedule",
  !any(grepl(
    "SURVIVAL_ONLY",
    schedule_mapping$recommended_anchor_id,
    fixed = TRUE
  )) &&
    !any(schedule_mapping$net_value_schedule %in% c(
      "V_ME(j)=S_ME(j)", "V_NRC(j)=S_NRC(j)"
    )),
  "survival remains a separate physical object"
)
add_check(
  "CFC net-stock rate remains aggregate diagnostic",
  all(anchor_registry$classification[
    anchor_registry$anchor_id ==
      "CFC_NET_STOCK_IMPLIED_AGGREGATE_RATE"
  ] == "INSUFFICIENT_EVIDENCE"),
  "not treated as a vintage age-price profile"
)
add_check(
  "FAAt402 not used as baseline capital-price route",
  all(anchor_registry$uses_faat402_as_price == "FALSE") &&
    !any(grepl("FAAt402.*baseline_allowed.*TRUE",
               paste(decision_ledger, collapse = " "),
               ignore.case = TRUE)),
  "validation/comparison boundary preserved"
)
add_check(
  "NFC output price not used as baseline capital-price route",
  all(anchor_registry$uses_output_price_as_capital_price == "FALSE"),
  "no output-price capital route"
)
add_check(
  "no final GPIM stocks constructed",
  !any(grepl("^K_G_NFC_.*GPIM", names(anchor_registry))) &&
    !any(grepl("FINAL_GPIM_STOCK", decision_ledger$status)),
  "protocol metadata only"
)
add_check("no S20/S21/S22 run", TRUE, "S12D-A3 script only")
add_check(
  "no econometric output created",
  TRUE,
  "documentation and protocol mapping only"
)
add_check(
  "explicit final decision produced",
  final_decision %in% c(
    "PROCEED_TO_S12D_B",
    "REQUIRE_MANUAL_THEORY_LOCK",
    "PARK_GPIM_BASELINE_USE_ROBUSTNESS_ONLY",
    "RETURN_TO_PROVIDER_ONLY_IF_PRECISE_MISSING_ANCHOR"
  ),
  final_decision
)
add_check(
  "exactly one final decision produced",
  sum(decision_ledger$protocol_item == "final_stage_gate_decision") == 1L &&
    decision_ledger$status[
      decision_ledger$protocol_item == "final_stage_gate_decision"
    ] == final_decision,
  final_decision
)
add_check(
  "S12D-B remains blocked pending manual lock",
  final_decision != "PROCEED_TO_S12D_B" &&
    all(schedule_mapping$baseline_lockable_now == "FALSE"),
  "manual theory lock required"
)
add_check(
  "protocol sentence is explicit and asset-specific",
  grepl("d_ME=0.110", protocol_sentence, fixed = TRUE) &&
    grepl("d_NRC=0.024", protocol_sentence, fixed = TRUE) &&
    grepl("V_i(j)=S_i(j)(1-d_i)^j", protocol_sentence, fixed = TRUE),
  protocol_sentence
)
add_check(
  "provider return not triggered",
  final_decision != "RETURN_TO_PROVIDER_ONLY_IF_PRECISE_MISSING_ANCHOR",
  paste(
    "Existing documentation contains the rate evidence; the unresolved",
    "step is conceptual adoption, not a new provider variable."
  )
)

require_condition(
  all(validation$result == "PASS"),
  paste0(
    "S12D-A3 validation failed:\n- ",
    paste(validation$validation_rule[validation$result == "FAIL"],
          collapse = "\n- ")
  )
)

write_csv(anchor_registry, paths[["registry"]])
write_csv(schedule_mapping, paths[["mapping"]])
write_csv(decision_ledger, paths[["decision"]])
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
    function(x) ifelse(is.na(x), "", format(round(x, 6), trim = TRUE))
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
  "# S12D-A3 External Depreciation / Age-Price Anchor",
  "",
  "## Why S12D-A3 Was Required",
  "",
  paste(
    "S12D-A2 showed that exact SFC closure cannot identify a net-value",
    "schedule: every positive candidate schedule generated a mechanically",
    "exact conditional price path. S12D-A3 therefore reviews only existing",
    "external methodology evidence for an independently defensible ME and",
    "NRC age-price anchor."
  ),
  "",
  "## Evidence Reviewed",
  "",
  paste(
    "- The existing provider methodological note",
    "`docs/Weibull_Retirement_Distributions.md`, which summarizes",
    "Fraumeni (1997), pre-1997 BEA service lives, geometric depreciation,",
    "and the distinction between depreciation and retirement."
  ),
  paste(
    "- The existing project architecture and legacy pipeline documentation,",
    "which records broad-asset declining-balance values of L=15, R=1.65,",
    "d=0.110 for ME and L=38, R=0.91, d=0.024 for NRC."
  ),
  paste(
    "- The S11B handbook crosswalk, which confirms that BEA uses age-price",
    "profiles but that FAAt402 is a quantity-index validation object, not a",
    "capital-price baseline."
  ),
  paste(
    "- Locked S12C CFC and net-stock series, used only to confirm that",
    "aggregate CFC/net-stock ratios are diagnostics rather than vintage",
    "age-price profiles."
  ),
  "",
  "## External Anchor Registry",
  "",
  markdown_table(
    anchor_registry,
    c(
      "asset_block", "anchor_id", "object_identified", "evidence_value",
      "classification"
    )
  ),
  "",
  "## Object Identification",
  "",
  paste(
    "The external evidence identifies an asset-specific depreciation rate",
    "and a declining-balance age-price family. It does not identify physical",
    "survival, productive efficiency, or a capital-price index. Survival",
    "remains the separate locked Weibull object. The SFC implicit capital",
    "price remains an output conditional on the manually selected value",
    "schedule."
  ),
  "",
  "## ME and NRC Treatment",
  "",
  paste(
    "ME and NRC can share the declining-balance profile family, but they",
    "cannot share one rate. The documented broad-asset anchors are d_ME=0.110",
    "and d_NRC=0.024, and their Weibull survival parameters also remain",
    "asset-specific. Detailed-asset heterogeneity and time-varying",
    "composition remain limitations."
  ),
  "",
  "## Schedule Mapping",
  "",
  markdown_table(
    schedule_mapping,
    c(
      "asset_block", "survival_profile", "age_price_profile",
      "net_value_schedule", "current_classification",
      "manual_theory_choice_required"
    )
  ),
  "",
  "## Stage-Gate Decision",
  "",
  paste0("- Decision: `", final_decision, "`."),
  "- S12D-B authorized: no.",
  paste(
    "The evidence is sufficiently explicit to define a precise candidate",
    "protocol, so no provider return is required. It is not sufficient to",
    "make the conceptual combination automatic: the dissertation must",
    "manually decide whether finite Weibull survival and BEA-style",
    "declining-balance age-price decay should jointly define net value."
  ),
  "",
  "## Exact Protocol Sentence Proposed For Lock",
  "",
  protocol_sentence,
  "",
  paste(
    "This sentence is proposed for manual adoption in the dissertation and",
    "source-of-truth notes. S12D-A3 does not itself activate it."
  ),
  "",
  "## Boundary Confirmation",
  "",
  "- FAAt402 baseline capital-price use: no.",
  "- NFC output-price baseline capital-price use: no.",
  "- Survival weights relabeled as net-value weights: no.",
  "- Aggregate CFC/net-stock rate treated as a vintage profile: no.",
  "- Productive-efficiency profile constructed: no.",
  "- Final GPIM stocks constructed: no.",
  "- S20/S21/S22 run: no.",
  "- Econometric output created: no.",
  "",
  "## Validation",
  "",
  markdown_table(
    validation,
    c("validation_rule", "result", "observed")
  )
)
writeLines(report_lines, paths[["report"]], useBytes = TRUE)

message("S12D-A3 external depreciation/age-price anchor passed.")
message("External anchor registry rows: ", nrow(anchor_registry))
message("Schedule mapping rows: ", nrow(schedule_mapping))
message("Validation checks: ", nrow(validation))
message("Decision: ", final_decision)
message("S12D-B authorized: no")
message("Final GPIM stocks constructed: no")
message("S20/S21/S22 run: no")
