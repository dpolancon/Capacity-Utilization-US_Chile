#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S12D-C from the Capacity-Utilization-US_Chile repository root.",
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

input_root <- file.path(
  repo_root, "output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION"
)
input_paths <- c(
  report = file.path(
    input_root, "md", "S12D_B_GPIM_BASELINE_CONSTRUCTION.md"
  ),
  validation = file.path(
    input_root, "csv", "S12D_B_validation_checks.csv"
  ),
  reconstruction = file.path(
    input_root, "csv", "S12D_B_sfc_reconstruction_checks.csv"
  ),
  roles = file.path(
    input_root, "csv", "S12D_B_object_role_ledger.csv"
  ),
  boundary = file.path(
    input_root, "csv", "S12D_B_price_boundary_comparison.csv"
  )
)

missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  stop(
    "Missing required S12D-B input(s): ",
    paste(unname(missing_inputs), collapse = ", "),
    call. = FALSE
  )
}

s12d_b_report <- paste(
  readLines(input_paths[["report"]], warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
validation <- read_csv(input_paths[["validation"]])
reconstruction <- read_csv(input_paths[["reconstruction"]])
roles <- read_csv(input_paths[["roles"]])
boundary <- read_csv(input_paths[["boundary"]])

required_columns <- list(
  validation = c("check_id", "status", "evidence"),
  reconstruction = c(
    "asset_block", "first_recovery_year", "last_recovery_year",
    "max_absolute_sfc_residual_millions"
  ),
  roles = c("asset_block", "object_role", "baseline_use")
)
tables <- list(
  validation = validation,
  reconstruction = reconstruction,
  roles = roles
)
for (table_name in names(required_columns)) {
  missing_columns <- setdiff(
    required_columns[[table_name]],
    names(tables[[table_name]])
  )
  if (length(missing_columns) > 0L) {
    stop(
      table_name, " input is missing required column(s): ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }
}

readiness_checks <- data.frame(
  check_id = character(),
  status = character(),
  evidence = character(),
  stringsAsFactors = FALSE
)
add_check <- function(check_id, passed, evidence) {
  readiness_checks <<- rbind(
    readiness_checks,
    data.frame(
      check_id = check_id,
      status = if (isTRUE(passed)) "PASS" else "FAIL",
      evidence = as.character(evidence),
      stringsAsFactors = FALSE
    )
  )
}

all_validation_pass <- nrow(validation) > 0L &&
  all(validation$status == "PASS")
add_check(
  "S12D_B_ALL_VALIDATIONS_PASS",
  all_validation_pass,
  paste0(
    sum(validation$status == "PASS"), "/",
    nrow(validation), " S12D-B validation rows are PASS."
  )
)
add_check(
  "S12D_B_VALIDATION_ROW_COUNT",
  nrow(validation) == 21L,
  paste0("Observed ", nrow(validation), " validation rows; required 21.")
)

next_stage_authorized <- grepl(
  "AUTHORIZE_S12D_C", s12d_b_report, fixed = TRUE
) && grepl(
  "S12D-C is the next consolidation and downstream handoff step",
  s12d_b_report,
  fixed = TRUE
)
add_check(
  "S12D_B_AUTHORIZES_S12D_C_NEXT",
  next_stage_authorized,
  paste0(
    "AUTHORIZE_S12D_C token and explicit next-step statement present: ",
    ifelse(next_stage_authorized, "yes.", "no.")
  )
)

asset_rows <- function(asset) {
  reconstruction[reconstruction$asset_block == asset, , drop = FALSE]
}
me_reconstruction <- asset_rows("ME")
nrc_reconstruction <- asset_rows("NRC")

add_check(
  "SFC_RECONSTRUCTION_ME_PRESENT",
  nrow(me_reconstruction) == 1L,
  paste0("Observed ", nrow(me_reconstruction), " ME reconstruction rows.")
)
add_check(
  "SFC_RECONSTRUCTION_NRC_PRESENT",
  nrow(nrc_reconstruction) == 1L,
  paste0("Observed ", nrow(nrc_reconstruction), " NRC reconstruction rows.")
)

residual_tolerance_millions <- 1e-6
residuals <- suppressWarnings(as.numeric(
  reconstruction$max_absolute_sfc_residual_millions
))
residuals_valid <- length(residuals) == nrow(reconstruction) &&
  nrow(reconstruction) > 0L &&
  all(is.finite(residuals)) &&
  all(residuals < residual_tolerance_millions)
observed_max_residual <- if (any(is.finite(residuals))) {
  max(residuals[is.finite(residuals)])
} else {
  NA_real_
}
add_check(
  "SFC_MAX_ABSOLUTE_RESIDUAL_BELOW_TOLERANCE",
  residuals_valid,
  paste0(
    "Observed maximum absolute residual = ",
    format(observed_max_residual, scientific = TRUE, digits = 8),
    " million; required < ",
    format(residual_tolerance_millions, scientific = TRUE),
    " million."
  )
)

span_matches <- function(rows, first_year, last_year) {
  nrow(rows) == 1L &&
    suppressWarnings(as.integer(rows$first_recovery_year)) == first_year &&
    suppressWarnings(as.integer(rows$last_recovery_year)) == last_year
}
add_check(
  "ME_RECOVERY_SPAN_1925_2024",
  span_matches(me_reconstruction, 1925L, 2024L),
  if (nrow(me_reconstruction) == 1L) {
    paste0(
      "Observed ME span ",
      me_reconstruction$first_recovery_year, "-",
      me_reconstruction$last_recovery_year, "."
    )
  } else {
    "A unique ME recovery row was not available."
  }
)
add_check(
  "NRC_RECOVERY_SPAN_1931_2024",
  span_matches(nrc_reconstruction, 1931L, 2024L),
  if (nrow(nrc_reconstruction) == 1L) {
    paste0(
      "Observed NRC span ",
      nrc_reconstruction$first_recovery_year, "-",
      nrc_reconstruction$last_recovery_year, "."
    )
  } else {
    "A unique NRC recovery row was not available."
  }
)

add_check(
  "OBJECT_ROLE_LEDGER_ROW_COUNT",
  nrow(roles) == 16L,
  paste0("Observed ", nrow(roles), " role-ledger rows; required 16.")
)
role_assets <- sort(unique(roles$asset_block))
add_check(
  "OBJECT_ROLE_LEDGER_ASSETS",
  identical(role_assets, c("ME", "NRC")),
  paste0("Observed asset blocks: ", paste(role_assets, collapse = ", "), ".")
)

baseline_roles <- c(
  "SFC_IMPLICIT_BASELINE_PRICE",
  "DIRECT_NOMINAL_INVESTMENT_CANONICAL",
  "REAL_INVESTMENT_BASELINE",
  "GROSS_SURVIVAL_GPIM_STOCK_BASELINE"
)
nonbaseline_roles <- c(
  "NET_VALUE_GPIM_STOCK_DIAGNOSTIC",
  "FAAt402_VALIDATION_ONLY",
  "OUTPUT_UNIT_TRANSLATION_ROBUSTNESS_ONLY",
  "PRODUCTIVE_EFFICIENCY_NOT_CONSTRUCTED"
)
expected_roles <- c(baseline_roles, nonbaseline_roles)

role_key <- paste(roles$asset_block, roles$object_role, sep = "::")
expected_role_key <- as.vector(outer(
  c("ME", "NRC"),
  expected_roles,
  paste,
  sep = "::"
))
add_check(
  "OBJECT_ROLE_LEDGER_COMPLETE_UNIQUE_GRID",
  nrow(roles) == 16L &&
    !anyDuplicated(role_key) &&
    setequal(role_key, expected_role_key),
  paste0(
    "Observed ", length(unique(role_key)),
    " unique asset-role combinations; required 16."
  )
)

baseline_use_yes <- roles$object_role %in% baseline_roles &
  roles$baseline_use == "yes"
baseline_yes_exact <- all(
  roles$baseline_use[roles$object_role %in% baseline_roles] == "yes"
) && !any(
  roles$baseline_use[!roles$object_role %in% baseline_roles] == "yes"
)
add_check(
  "BASELINE_USE_YES_EXACT_ROLE_SET",
  baseline_yes_exact && sum(baseline_use_yes) == 8L,
  paste0(
    "Observed baseline_use=yes roles: ",
    paste(sort(unique(roles$object_role[roles$baseline_use == "yes"])),
          collapse = ", "),
    "."
  )
)

nonbaseline_no_exact <- all(
  roles$baseline_use[roles$object_role %in% nonbaseline_roles] == "no"
) && !any(
  roles$baseline_use[!roles$object_role %in% nonbaseline_roles] == "no"
)
add_check(
  "BASELINE_USE_NO_EXACT_ROLE_SET",
  nonbaseline_no_exact &&
    sum(roles$object_role %in% nonbaseline_roles &
          roles$baseline_use == "no") == 8L,
  paste0(
    "Observed baseline_use=no roles: ",
    paste(sort(unique(roles$object_role[roles$baseline_use == "no"])),
          collapse = ", "),
    "."
  )
)

add_check(
  "PRICE_BOUNDARY_COMPARISON_PRESENT_NONEMPTY",
  file.exists(input_paths[["boundary"]]) && nrow(boundary) > 0L,
  paste0(
    "Price-boundary comparison exists with ", nrow(boundary), " rows."
  )
)

status_map <- c(
  SFC_IMPLICIT_BASELINE_PRICE = "BASELINE_CONSUMABLE",
  DIRECT_NOMINAL_INVESTMENT_CANONICAL = "BASELINE_CONSUMABLE",
  REAL_INVESTMENT_BASELINE = "BASELINE_CONSUMABLE",
  GROSS_SURVIVAL_GPIM_STOCK_BASELINE = "BASELINE_CONSUMABLE",
  NET_VALUE_GPIM_STOCK_DIAGNOSTIC = "DIAGNOSTIC_ONLY",
  FAAt402_VALIDATION_ONLY = "VALIDATION_ONLY",
  OUTPUT_UNIT_TRANSLATION_ROBUSTNESS_ONLY = "ROBUSTNESS_ONLY",
  PRODUCTIVE_EFFICIENCY_NOT_CONSTRUCTED = "NOT_CONSTRUCTED"
)
allowed_use_map <- c(
  SFC_IMPLICIT_BASELINE_PRICE =
    "Baseline capital-price index for downstream GPIM consumption.",
  DIRECT_NOMINAL_INVESTMENT_CANONICAL =
    "Canonical nominal investment input and provenance reference.",
  REAL_INVESTMENT_BASELINE =
    "Baseline real investment flow for downstream capital analysis.",
  GROSS_SURVIVAL_GPIM_STOCK_BASELINE =
    "Baseline GPIM capital-stock object for downstream layers.",
  NET_VALUE_GPIM_STOCK_DIAGNOSTIC =
    "SFC identity reconstruction and diagnostic checks only.",
  FAAt402_VALIDATION_ONLY =
    "Boundary validation against the official quantity index only.",
  OUTPUT_UNIT_TRANSLATION_ROBUSTNESS_ONLY =
    "NFC output-unit translation robustness exercises only.",
  PRODUCTIVE_EFFICIENCY_NOT_CONSTRUCTED =
    "No downstream use; the object does not exist."
)
prohibited_use_map <- c(
  SFC_IMPLICIT_BASELINE_PRICE =
    "Do not replace it with FAAt402 or the NFC output price.",
  DIRECT_NOMINAL_INVESTMENT_CANONICAL =
    "Do not replace it with implied investment.",
  REAL_INVESTMENT_BASELINE =
    "Do not reinterpret it as nominal investment or a diagnostic series.",
  GROSS_SURVIVAL_GPIM_STOCK_BASELINE =
    "Do not substitute the net-value diagnostic stock.",
  NET_VALUE_GPIM_STOCK_DIAGNOSTIC =
    "Do not use it as the baseline GPIM capital stock.",
  FAAt402_VALIDATION_ONLY =
    "Do not use it as the baseline capital-price object.",
  OUTPUT_UNIT_TRANSLATION_ROBUSTNESS_ONLY =
    "Do not use it as the baseline capital-price object.",
  PRODUCTIVE_EFFICIENCY_NOT_CONSTRUCTED =
    "Do not infer or consume a productive-efficiency series."
)

consumption_contract <- data.frame(
  asset_block = roles$asset_block,
  object_role = roles$object_role,
  downstream_consumption_status = unname(status_map[roles$object_role]),
  allowed_use = unname(allowed_use_map[roles$object_role]),
  prohibited_use = unname(prohibited_use_map[roles$object_role]),
  stringsAsFactors = FALSE
)

contract_valid <- nrow(consumption_contract) == 16L &&
  !anyNA(consumption_contract) &&
  all(consumption_contract$downstream_consumption_status %in% c(
    "BASELINE_CONSUMABLE",
    "DIAGNOSTIC_ONLY",
    "VALIDATION_ONLY",
    "ROBUSTNESS_ONLY",
    "NOT_CONSTRUCTED"
  ))
add_check(
  "CONSUMPTION_CONTRACT_COMPLETE",
  contract_valid,
  paste0(
    "Constructed ", nrow(consumption_contract),
    " contract rows with no unmapped roles: ",
    ifelse(anyNA(consumption_contract), "no.", "yes.")
  )
)

final_decision <- if (all(readiness_checks$status == "PASS")) {
  "AUTHORIZE_NEXT_LAYER_CONSUMPTION"
} else {
  "REQUIRE_S12D_B_PATCH"
}

output_root <- file.path(
  repo_root, "output", "US", "S12D_C_GPIM_DOWNSTREAM_READINESS_LOCK"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

readiness_path <- file.path(csv_dir, "S12D_C_readiness_checks.csv")
contract_path <- file.path(csv_dir, "S12D_C_consumption_contract.csv")
report_path <- file.path(
  md_dir, "S12D_C_GPIM_DOWNSTREAM_READINESS_LOCK.md"
)

write.csv(readiness_checks, readiness_path, row.names = FALSE, na = "")
write.csv(consumption_contract, contract_path, row.names = FALSE, na = "")

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
  "# S12D-C GPIM Downstream Readiness Lock",
  "",
  "## Audit Boundary",
  "",
  paste(
    "S12D-C audited the already-constructed S12D-B outputs and wrote the",
    "downstream consumption contract. S12D-C did not reconstruct any GPIM",
    "object."
  ),
  "",
  "- S12D-C did not run S20, S21, or S22.",
  "- S12D-C did not run econometrics.",
  "- S12D-C did not modify provider data.",
  "",
  "## Consumption Boundary",
  "",
  paste(
    "`SFC_IMPLICIT_BASELINE_PRICE` is the baseline capital-price object, and",
    "`GROSS_SURVIVAL_GPIM_STOCK_BASELINE` is the baseline GPIM capital-stock",
    "object."
  ),
  paste(
    "`NET_VALUE_GPIM_STOCK_DIAGNOSTIC` is diagnostic only. `FAAt402` is",
    "validation-only. NFC output-price translation is robustness-only.",
    "Productive-efficiency objects remain not constructed."
  ),
  "",
  "## Readiness Checks",
  "",
  markdown_table(
    readiness_checks,
    c("check_id", "status", "evidence")
  ),
  "",
  "## Downstream Consumption Contract",
  "",
  markdown_table(
    consumption_contract,
    c(
      "asset_block", "object_role", "downstream_consumption_status",
      "allowed_use", "prohibited_use"
    )
  ),
  "",
  "## Final Decision",
  "",
  paste0("**", final_decision, "**")
)
writeLines(report_lines, report_path, useBytes = TRUE)

message(
  "S12D-C completed: ",
  sum(readiness_checks$status == "PASS"), "/",
  nrow(readiness_checks), " readiness checks PASS."
)
message("Decision: ", final_decision)
message("GPIM objects reconstructed: no")
message("S20/S21/S22 run: no")
message("Econometrics run: no")
message("Provider data modified: no")

if (final_decision != "AUTHORIZE_NEXT_LAYER_CONSUMPTION") {
  quit(save = "no", status = 1L)
}
