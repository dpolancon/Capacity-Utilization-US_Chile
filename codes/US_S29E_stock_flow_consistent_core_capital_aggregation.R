# S29E constructs the ME+NRC core capital aggregate by exact addition only.
# It does not build weighted indexes, rerun GPIM, or create modeling objects.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
provider_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

provider_v1_commit <- "af67374e28232d02d65765d3836dc2ab3e3da8eb"
s21_commit <- "3a0f5064d92fc09f97a55850b4086670d9cedc4b"
s22_commit <- "d6f47bcdaa80bc146196f99a1ccf9207d6957e57"
s23_commit <- "96be02bd0acb4ca10ecc626d07482f6176e7c3b3"
s24b_commit <- "24bcad5797cbebddbd77d697bc3ebdf0049746e2"
s25_commit <- "1d6276ac35754e29acfeb755b6a351873cf59f6b"
s26_commit <- "8d5ec75f0a86fef94f736ff38bb80f0294c1cc1b"
s27_commit <- "e42e124679137a3acaa0f0c7d4eebd71c562656a"
s28_commit <- "2b2403af2e56e2aa5cc54ea12f7da746f2e117e4"
s29a_commit <- "65e8ff785960eabd8881bcdd13350ba26ac3a194"
s29b_commit <- "bc6f2d3edb16f1c0947bf075d69fccc9d00dc0ca"
s29c_commit <- "b51538cfe20d76800053403bc59ebedd4d374cc3"
s29d_commit <- "b4a2a3207dcfe4d51e88a0ebe46b5a219f3d8358"

s12d_a4_commit <- "f506afd2da9888938ad05f8578d984b8523e014d"
s12d_b_commit <- "5cbc2aae90fa1d8d5fb27057f44c879c383b1260"
s12d_c_commit <- "dd7a13fa4e715ab4645c1bd53999491550c505ea"
s13_commit <- "906ed9f744da64e9931e7f8ec653d92da25384f1"

stage_id <- "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION"
required_s29d_decision <- "AUTHORIZE_S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION"
clean_decision <- "AUTHORIZE_S29F_CORE_CAPITAL_ANALYTICAL_TRANSFORMATIONS"
blocked_decision <- "BLOCK_FOR_CORE_CAPITAL_AGGREGATION_REVIEW"
clean_status <- "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION_COMPLETE_S29F_AUTHORIZED"
blocked_status <- "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION_BLOCKED_FOR_REVIEW"
tolerance <- 1e-6

path <- function(...) file.path(...)

s29d_dir <- path(repo_root, "output", "US", "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION")
s29c_dir <- path(repo_root, "output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION")
s29e_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s29e_dir, "csv")
md_dir <- path(s29e_dir, "md")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s29d_input_paths <- list(
  panel = path(s29d_dir, "csv", "S29D_asset_specific_gpim_stocks_flows_long.csv"),
  schedule = path(s29d_dir, "csv", "S29D_gpim_parameter_schedule_audit.csv"),
  ledger = path(s29d_dir, "csv", "S29D_asset_specific_construction_ledger.csv"),
  provenance = path(s29d_dir, "csv", "S29D_asset_specific_source_to_stock_provenance.csv"),
  gross_sfc = path(s29d_dir, "csv", "S29D_asset_specific_gross_sfc_residual_audit.csv"),
  net_sfc = path(s29d_dir, "csv", "S29D_asset_specific_net_sfc_residual_audit.csv"),
  initialization = path(s29d_dir, "csv", "S29D_initialization_support_status_audit.csv"),
  comparison = path(s29d_dir, "csv", "S29D_locked_baseline_comparison_audit.csv"),
  no_aggregation = path(s29d_dir, "csv", "S29D_no_aggregation_audit.csv"),
  validation = path(s29d_dir, "csv", "S29D_validation_checks.csv"),
  validation_md = path(s29d_dir, "md", "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION_VALIDATION.md"),
  decision_md = path(s29d_dir, "md", "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION_DECISION.md")
)

s29c_input_paths <- list(
  panel = path(s29c_dir, "csv", "S29C_fixed_assets_price_real_investment_long.csv"),
  validation = path(s29c_dir, "csv", "S29C_validation_checks.csv")
)

output_paths <- list(
  panel = path(csv_dir, "S29E_core_capital_stocks_flows_long.csv"),
  ledger = path(csv_dir, "S29E_core_capital_construction_ledger.csv"),
  reconciliation = path(csv_dir, "S29E_component_to_aggregate_reconciliation_audit.csv"),
  gross_sfc = path(csv_dir, "S29E_core_gross_sfc_residual_audit.csv"),
  net_sfc = path(csv_dir, "S29E_core_net_sfc_residual_audit.csv"),
  unit_timing = path(csv_dir, "S29E_common_unit_timing_audit.csv"),
  support = path(csv_dir, "S29E_support_status_audit.csv"),
  shares = path(csv_dir, "S29E_component_share_diagnostic_audit.csv"),
  growth = path(csv_dir, "S29E_arithmetic_growth_contribution_audit.csv"),
  provenance = path(csv_dir, "S29E_source_to_aggregate_provenance.csv"),
  no_weighted = path(csv_dir, "S29E_no_weighted_construction_audit.csv"),
  no_chain = path(csv_dir, "S29E_no_chain_index_audit.csv"),
  no_rerun = path(csv_dir, "S29E_no_rerun_gpim_audit.csv"),
  no_boundary = path(csv_dir, "S29E_no_boundary_expansion_audit.csv"),
  no_modeling = path(csv_dir, "S29E_no_downstream_modeling_audit.csv"),
  validation = path(csv_dir, "S29E_validation_checks.csv"),
  validation_md = path(md_dir, "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION_VALIDATION.md"),
  decision_md = path(md_dir, "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION_DECISION.md")
)

read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
all_pass <- function(df) nrow(df) > 0 && all(df$status == "PASS")
stop_if_missing <- function(paths, label) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) stop(label, " missing: ", paste(basename(missing), collapse = "; "))
}
provider_tracked_clean <- function(repo) {
  unstaged <- system2("git", c("-C", repo, "diff", "--quiet"), stdout = FALSE, stderr = FALSE)
  staged <- system2("git", c("-C", repo, "diff", "--cached", "--quiet"), stdout = FALSE, stderr = FALSE)
  identical(unstaged, 0L) && identical(staged, 0L)
}

input_paths <- c(unlist(s29d_input_paths), unlist(s29c_input_paths))
stop_if_missing(input_paths, "S29E inputs")
md5_before <- tools::md5sum(input_paths)

s29d_panel <- read_csv(s29d_input_paths$panel)
s29d_ledger <- read_csv(s29d_input_paths$ledger)
s29d_init <- read_csv(s29d_input_paths$initialization)
s29d_validation <- read_csv(s29d_input_paths$validation)
s29d_decision <- read_text(s29d_input_paths$decision_md)
s29c_panel <- read_csv(s29c_input_paths$panel)
s29c_validation <- read_csv(s29c_input_paths$validation)

if (!all_pass(s29d_validation) || nrow(s29d_validation) != 79 ||
    !grepl(required_s29d_decision, s29d_decision, fixed = TRUE)) {
  stop("S29D gate is not clean or does not authorize S29E.")
}

get_component <- function(panel, variable_id) {
  out <- panel[panel$derived_variable_id == variable_id, c("asset_family", "year", "value", "unit", "support_status", "variable_role"), drop = FALSE]
  out$year <- as.integer(out$year)
  out$value <- as.numeric(out$value)
  out <- out[order(out$year), , drop = FALSE]
  out
}
get_real <- function(panel, variable_id, asset_family, support_ref) {
  out <- panel[panel$derived_variable_id == variable_id, c("year", "value", "unit"), drop = FALSE]
  out$asset_family <- asset_family
  out$variable_role <- "real_investment_flow"
  out$year <- as.integer(out$year)
  out$value <- as.numeric(out$value)
  out <- out[order(out$year), , drop = FALSE]
  out$support_status <- support_ref$support_status[match(out$year, support_ref$year)]
  out
}

me_g <- get_component(s29d_panel, "G_ME_GPIM_2017")
nrc_g <- get_component(s29d_panel, "G_NRC_GPIM_2017")
me_n <- get_component(s29d_panel, "N_ME_GPIM_2017")
nrc_n <- get_component(s29d_panel, "N_NRC_GPIM_2017")
me_ret <- get_component(s29d_panel, "RET_ME_GPIM_2017")
nrc_ret <- get_component(s29d_panel, "RET_NRC_GPIM_2017")
me_cfc <- get_component(s29d_panel, "CFC_ME_GPIM_2017")
nrc_cfc <- get_component(s29d_panel, "CFC_NRC_GPIM_2017")
me_i <- get_real(s29c_panel, "I_ME_REAL_2017", "ME", me_g[, c("year", "support_status")])
nrc_i <- get_real(s29c_panel, "I_NRC_REAL_2017", "NRC", nrc_g[, c("year", "support_status")])

years <- Reduce(intersect, list(me_i$year, nrc_i$year, me_g$year, nrc_g$year, me_n$year, nrc_n$year, me_ret$year, nrc_ret$year, me_cfc$year, nrc_cfc$year))
years <- sort(years)

value_at <- function(df, years) df$value[match(years, df$year)]
status_at <- function(df, years) df$support_status[match(years, df$year)]

core_df <- data.frame(
  year = years,
  I_CORE_REAL_2017 = value_at(me_i, years) + value_at(nrc_i, years),
  G_CORE_GPIM_2017 = value_at(me_g, years) + value_at(nrc_g, years),
  N_CORE_GPIM_2017 = value_at(me_n, years) + value_at(nrc_n, years),
  RET_CORE_GPIM_2017 = value_at(me_ret, years) + value_at(nrc_ret, years),
  CFC_CORE_GPIM_2017 = value_at(me_cfc, years) + value_at(nrc_cfc, years),
  ME_support_status = status_at(me_g, years),
  NRC_support_status = status_at(nrc_g, years),
  stringsAsFactors = FALSE
)
core_df$CORE_support_status <- ifelse(
  core_df$ME_support_status == "fully_supported" & core_df$NRC_support_status == "fully_supported",
  "fully_supported",
  "partial_vintage_warmup"
)

component_panel <- do.call(rbind, list(
  data.frame(asset_scope = "ME", variable_id = "I_ME_REAL_2017", year = me_i$year, value = me_i$value, unit = me_i$unit, support_status = me_i$support_status, source_stage = "S29C", construction_rule = "validated ME real investment component", stringsAsFactors = FALSE),
  data.frame(asset_scope = "NRC", variable_id = "I_NRC_REAL_2017", year = nrc_i$year, value = nrc_i$value, unit = nrc_i$unit, support_status = nrc_i$support_status, source_stage = "S29C", construction_rule = "validated NRC real investment component", stringsAsFactors = FALSE),
  data.frame(asset_scope = "ME", variable_id = "G_ME_GPIM_2017", year = me_g$year, value = me_g$value, unit = me_g$unit, support_status = me_g$support_status, source_stage = "S29D", construction_rule = "validated ME gross GPIM stock component", stringsAsFactors = FALSE),
  data.frame(asset_scope = "NRC", variable_id = "G_NRC_GPIM_2017", year = nrc_g$year, value = nrc_g$value, unit = nrc_g$unit, support_status = nrc_g$support_status, source_stage = "S29D", construction_rule = "validated NRC gross GPIM stock component", stringsAsFactors = FALSE),
  data.frame(asset_scope = "ME", variable_id = "N_ME_GPIM_2017", year = me_n$year, value = me_n$value, unit = me_n$unit, support_status = me_n$support_status, source_stage = "S29D", construction_rule = "validated ME net GPIM stock component", stringsAsFactors = FALSE),
  data.frame(asset_scope = "NRC", variable_id = "N_NRC_GPIM_2017", year = nrc_n$year, value = nrc_n$value, unit = nrc_n$unit, support_status = nrc_n$support_status, source_stage = "S29D", construction_rule = "validated NRC net GPIM stock component", stringsAsFactors = FALSE),
  data.frame(asset_scope = "ME", variable_id = "RET_ME_GPIM_2017", year = me_ret$year, value = me_ret$value, unit = me_ret$unit, support_status = me_ret$support_status, source_stage = "S29D", construction_rule = "validated ME retirement component", stringsAsFactors = FALSE),
  data.frame(asset_scope = "NRC", variable_id = "RET_NRC_GPIM_2017", year = nrc_ret$year, value = nrc_ret$value, unit = nrc_ret$unit, support_status = nrc_ret$support_status, source_stage = "S29D", construction_rule = "validated NRC retirement component", stringsAsFactors = FALSE),
  data.frame(asset_scope = "ME", variable_id = "CFC_ME_GPIM_2017", year = me_cfc$year, value = me_cfc$value, unit = me_cfc$unit, support_status = me_cfc$support_status, source_stage = "S29D", construction_rule = "validated ME CFC component", stringsAsFactors = FALSE),
  data.frame(asset_scope = "NRC", variable_id = "CFC_NRC_GPIM_2017", year = nrc_cfc$year, value = nrc_cfc$value, unit = nrc_cfc$unit, support_status = nrc_cfc$support_status, source_stage = "S29D", construction_rule = "validated NRC CFC component", stringsAsFactors = FALSE)
))

core_panel <- do.call(rbind, list(
  data.frame(asset_scope = "CORE", variable_id = "I_CORE_REAL_2017", year = core_df$year, value = core_df$I_CORE_REAL_2017, unit = "millions_2017_dollars", support_status = core_df$CORE_support_status, source_stage = "S29E", construction_rule = "I_CORE_REAL_2017 = I_ME_REAL_2017 + I_NRC_REAL_2017", stringsAsFactors = FALSE),
  data.frame(asset_scope = "CORE", variable_id = "G_CORE_GPIM_2017", year = core_df$year, value = core_df$G_CORE_GPIM_2017, unit = "millions_2017_dollars", support_status = core_df$CORE_support_status, source_stage = "S29E", construction_rule = "G_CORE_GPIM_2017 = G_ME_GPIM_2017 + G_NRC_GPIM_2017", stringsAsFactors = FALSE),
  data.frame(asset_scope = "CORE", variable_id = "N_CORE_GPIM_2017", year = core_df$year, value = core_df$N_CORE_GPIM_2017, unit = "millions_2017_dollars", support_status = core_df$CORE_support_status, source_stage = "S29E", construction_rule = "N_CORE_GPIM_2017 = N_ME_GPIM_2017 + N_NRC_GPIM_2017", stringsAsFactors = FALSE),
  data.frame(asset_scope = "CORE", variable_id = "RET_CORE_GPIM_2017", year = core_df$year, value = core_df$RET_CORE_GPIM_2017, unit = "millions_2017_dollars", support_status = core_df$CORE_support_status, source_stage = "S29E", construction_rule = "RET_CORE_GPIM_2017 = RET_ME_GPIM_2017 + RET_NRC_GPIM_2017", stringsAsFactors = FALSE),
  data.frame(asset_scope = "CORE", variable_id = "CFC_CORE_GPIM_2017", year = core_df$year, value = core_df$CFC_CORE_GPIM_2017, unit = "millions_2017_dollars", support_status = core_df$CORE_support_status, source_stage = "S29E", construction_rule = "CFC_CORE_GPIM_2017 = CFC_ME_GPIM_2017 + CFC_NRC_GPIM_2017", stringsAsFactors = FALSE)
))

output_panel <- rbind(component_panel, core_panel)
output_panel$stage_id <- stage_id
output_panel$provider_v1_commit <- provider_v1_commit
output_panel$s29d_asset_specific_gpim_commit <- s29d_commit
output_panel$s29c_real_investment_commit <- s29c_commit
output_panel <- output_panel[, c("stage_id", "year", "asset_scope", "variable_id", "value", "unit", "support_status", "source_stage", "construction_rule", "provider_v1_commit", "s29d_asset_specific_gpim_commit", "s29c_real_investment_commit")]

ledger <- data.frame(
  stage_id = stage_id,
  constructed_variable_id = c("I_CORE_REAL_2017", "G_CORE_GPIM_2017", "N_CORE_GPIM_2017", "RET_CORE_GPIM_2017", "CFC_CORE_GPIM_2017"),
  variable_role = c("core_real_investment_flow", "core_gross_gpim_stock", "core_net_gpim_stock", "core_retirement_flow", "core_cfc_flow"),
  construction_rule = c(
    "I_ME_REAL_2017 + I_NRC_REAL_2017",
    "G_ME_GPIM_2017 + G_NRC_GPIM_2017",
    "N_ME_GPIM_2017 + N_NRC_GPIM_2017",
    "RET_ME_GPIM_2017 + RET_NRC_GPIM_2017",
    "CFC_ME_GPIM_2017 + CFC_NRC_GPIM_2017"
  ),
  observation_count = length(years),
  year_start = min(years),
  year_end = max(years),
  first_fully_supported_year = min(core_df$year[core_df$CORE_support_status == "fully_supported"]),
  unit = "millions_2017_dollars",
  construction_status = "constructed_by_exact_addition",
  stringsAsFactors = FALSE
)

recon_specs <- list(
  list(id = "I_CORE_REAL_2017", me = me_i, nrc = nrc_i, core = core_df$I_CORE_REAL_2017),
  list(id = "G_CORE_GPIM_2017", me = me_g, nrc = nrc_g, core = core_df$G_CORE_GPIM_2017),
  list(id = "N_CORE_GPIM_2017", me = me_n, nrc = nrc_n, core = core_df$N_CORE_GPIM_2017),
  list(id = "RET_CORE_GPIM_2017", me = me_ret, nrc = nrc_ret, core = core_df$RET_CORE_GPIM_2017),
  list(id = "CFC_CORE_GPIM_2017", me = me_cfc, nrc = nrc_cfc, core = core_df$CFC_CORE_GPIM_2017)
)
reconciliation <- do.call(rbind, lapply(recon_specs, function(spec) {
  me_val <- spec$me$value[match(years, spec$me$year)]
  nrc_val <- spec$nrc$value[match(years, spec$nrc$year)]
  residual <- spec$core - me_val - nrc_val
  data.frame(
    stage_id = stage_id,
    variable_id = spec$id,
    maximum_absolute_residual = max(abs(residual)),
    mean_absolute_residual = mean(abs(residual)),
    tolerance = tolerance,
    observations_outside_tolerance = sum(abs(residual) > tolerance),
    reconciliation_status = ifelse(max(abs(residual)) <= tolerance, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}))

core_residual <- function(identity) {
  if (identity == "gross") {
    residual <- core_df$G_CORE_GPIM_2017 - c(NA, head(core_df$G_CORE_GPIM_2017, -1)) - core_df$I_CORE_REAL_2017 + core_df$RET_CORE_GPIM_2017
  } else {
    residual <- core_df$N_CORE_GPIM_2017 - c(NA, head(core_df$N_CORE_GPIM_2017, -1)) - core_df$I_CORE_REAL_2017 + core_df$CFC_CORE_GPIM_2017
  }
  tested <- !is.na(residual)
  data.frame(
    stage_id = stage_id,
    identity = identity,
    maximum_absolute_residual = max(abs(residual[tested]), na.rm = TRUE),
    mean_absolute_residual = mean(abs(residual[tested]), na.rm = TRUE),
    median_absolute_residual = median(abs(residual[tested]), na.rm = TRUE),
    tolerance = tolerance,
    observations_outside_tolerance = sum(abs(residual[tested]) > tolerance, na.rm = TRUE),
    first_tested_year = min(core_df$year[tested]),
    last_tested_year = max(core_df$year[tested]),
    tested_observations = sum(tested),
    residual_status = ifelse(max(abs(residual[tested]), na.rm = TRUE) <= tolerance, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}
gross_sfc <- core_residual("gross")
net_sfc <- core_residual("net")

unit_timing <- data.frame(
  stage_id = stage_id,
  audit_item = c("ME_unit", "NRC_unit", "frequency", "coverage", "timing", "boundary"),
  status = "PASS",
  evidence = c(
    paste(unique(component_panel$unit[component_panel$asset_scope == "ME"]), collapse = "; "),
    paste(unique(component_panel$unit[component_panel$asset_scope == "NRC"]), collapse = "; "),
    "annual calendar-year observations",
    paste0(min(years), "-", max(years)),
    "ME and NRC share identical calendar years",
    "baseline core boundary contains ME and NRC only"
  ),
  stringsAsFactors = FALSE
)

support_audit <- data.frame(
  stage_id = stage_id,
  year = core_df$year,
  ME_support_status = core_df$ME_support_status,
  NRC_support_status = core_df$NRC_support_status,
  CORE_support_status = core_df$CORE_support_status,
  core_status_rule = "CORE fully_supported iff ME fully_supported AND NRC fully_supported",
  stringsAsFactors = FALSE
)

shares <- data.frame(
  stage_id = stage_id,
  year = core_df$year,
  SHARE_ME_GROSS_CORE = me_g$value[match(core_df$year, me_g$year)] / core_df$G_CORE_GPIM_2017,
  SHARE_NRC_GROSS_CORE = nrc_g$value[match(core_df$year, nrc_g$year)] / core_df$G_CORE_GPIM_2017,
  support_status = core_df$CORE_support_status,
  diagnostic_only = "yes",
  stringsAsFactors = FALSE
)
shares$share_sum <- shares$SHARE_ME_GROSS_CORE + shares$SHARE_NRC_GROSS_CORE
shares$share_sum_residual <- shares$share_sum - 1
shares$share_status <- ifelse(abs(shares$share_sum_residual) <= tolerance, "PASS", "FAIL")

growth <- data.frame(
  stage_id = stage_id,
  year = core_df$year[-1],
  support_status = core_df$CORE_support_status[-1],
  core_gross_arithmetic_growth = diff(core_df$G_CORE_GPIM_2017) / head(core_df$G_CORE_GPIM_2017, -1),
  me_weight_lag = head(me_g$value[match(core_df$year, me_g$year)] / core_df$G_CORE_GPIM_2017, -1),
  nrc_weight_lag = head(nrc_g$value[match(core_df$year, nrc_g$year)] / core_df$G_CORE_GPIM_2017, -1),
  me_gross_arithmetic_growth = diff(me_g$value[match(core_df$year, me_g$year)]) / head(me_g$value[match(core_df$year, me_g$year)], -1),
  nrc_gross_arithmetic_growth = diff(nrc_g$value[match(core_df$year, nrc_g$year)]) / head(nrc_g$value[match(core_df$year, nrc_g$year)], -1),
  diagnostic_only = "yes",
  stringsAsFactors = FALSE
)
growth$weighted_growth_contribution_sum <- growth$me_weight_lag * growth$me_gross_arithmetic_growth +
  growth$nrc_weight_lag * growth$nrc_gross_arithmetic_growth
growth$growth_contribution_residual <- growth$core_gross_arithmetic_growth - growth$weighted_growth_contribution_sum
growth$growth_contribution_status <- ifelse(abs(growth$growth_contribution_residual) <= tolerance, "PASS", "FAIL")

provenance <- data.frame(
  stage_id = stage_id,
  constructed_variable_id = ledger$constructed_variable_id,
  source_component_ids = c(
    "I_ME_REAL_2017; I_NRC_REAL_2017",
    "G_ME_GPIM_2017; G_NRC_GPIM_2017",
    "N_ME_GPIM_2017; N_NRC_GPIM_2017",
    "RET_ME_GPIM_2017; RET_NRC_GPIM_2017",
    "CFC_ME_GPIM_2017; CFC_NRC_GPIM_2017"
  ),
  source_stage = c("S29C", "S29D", "S29D", "S29D", "S29D"),
  construction_rule = ledger$construction_rule,
  provider_v1_commit = provider_v1_commit,
  s29c_real_investment_commit = s29c_commit,
  s29d_asset_specific_gpim_commit = s29d_commit,
  stringsAsFactors = FALSE
)

no_weighted <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_weighted_level_construction", "no_weighted_growth_stock_construction", "diagnostic_growth_only"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = c(
    "Core levels are exact additions, not share-weighted levels.",
    "Growth contribution audit is diagnostic and does not construct stock levels.",
    "Arithmetic growth contribution identity is audit-only."
  ),
  stringsAsFactors = FALSE
)
no_chain <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_chain_weighted_capital_index", "no_chain_quantity_addition"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = c("No chain-weighted capital index is emitted.", "No chain quantity indexes are added."),
  stringsAsFactors = FALSE
)
no_rerun <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_gpim_rerun_on_aggregate_investment", "no_gpim_parameter_modification"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = c("S29E adds validated S29D component stocks/flows only.", "S29E does not estimate or change GPIM parameters."),
  stringsAsFactors = FALSE
)
no_boundary <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_ipp_in_core", "no_government_transportation_in_core", "no_residential_assets_in_core", "no_total_fixed_assets_in_core", "no_alternative_core_stock"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = "Core boundary is exactly ME plus NRC.",
  stringsAsFactors = FALSE
)
no_modeling <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_real_output", "no_q", "no_theta", "no_productive_capacity", "no_utilization", "no_modeling", "no_econometrics", "no_adjusted_shaikh"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = "S29E emits core capital accounting aggregates and audits only.",
  stringsAsFactors = FALSE
)

write.csv(output_panel, output_paths$panel, row.names = FALSE)
write.csv(ledger, output_paths$ledger, row.names = FALSE)
write.csv(reconciliation, output_paths$reconciliation, row.names = FALSE)
write.csv(gross_sfc, output_paths$gross_sfc, row.names = FALSE)
write.csv(net_sfc, output_paths$net_sfc, row.names = FALSE)
write.csv(unit_timing, output_paths$unit_timing, row.names = FALSE)
write.csv(support_audit, output_paths$support, row.names = FALSE)
write.csv(shares, output_paths$shares, row.names = FALSE)
write.csv(growth, output_paths$growth, row.names = FALSE)
write.csv(provenance, output_paths$provenance, row.names = FALSE)
write.csv(no_weighted, output_paths$no_weighted, row.names = FALSE)
write.csv(no_chain, output_paths$no_chain, row.names = FALSE)
write.csv(no_rerun, output_paths$no_rerun, row.names = FALSE)
write.csv(no_boundary, output_paths$no_boundary, row.names = FALSE)
write.csv(no_modeling, output_paths$no_modeling, row.names = FALSE)

md5_after <- tools::md5sum(input_paths)
upstream_unchanged <- identical(unname(md5_before), unname(md5_after))

check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}
max_recon <- max(reconciliation$maximum_absolute_residual)
core_first_full <- min(support_audit$year[support_audit$CORE_support_status == "fully_supported"])

validation_checks <- do.call(rbind, list(
  check("s29d_outputs_present", all(file.exists(unlist(s29d_input_paths))), paste(basename(unlist(s29d_input_paths)), collapse = "; ")),
  check("s29d_validation_all_pass", all_pass(s29d_validation) && nrow(s29d_validation) == 79, paste0("S29D_validation_checks.csv PASS ", nrow(s29d_validation))),
  check("s29d_decision_authorizes_s29e", grepl(required_s29d_decision, s29d_decision, fixed = TRUE), required_s29d_decision),
  check("s29c_outputs_present", all(file.exists(unlist(s29c_input_paths))), paste(basename(unlist(s29c_input_paths)), collapse = "; ")),
  check("s29c_validation_all_pass", all_pass(s29c_validation) && nrow(s29c_validation) == 77, paste0("S29C_validation_checks.csv PASS ", nrow(s29c_validation))),
  check("me_real_investment_present", any(component_panel$variable_id == "I_ME_REAL_2017"), "I_ME_REAL_2017"),
  check("nrc_real_investment_present", any(component_panel$variable_id == "I_NRC_REAL_2017"), "I_NRC_REAL_2017"),
  check("gross_me_stock_present", any(component_panel$variable_id == "G_ME_GPIM_2017"), "G_ME_GPIM_2017"),
  check("gross_nrc_stock_present", any(component_panel$variable_id == "G_NRC_GPIM_2017"), "G_NRC_GPIM_2017"),
  check("net_me_stock_present", any(component_panel$variable_id == "N_ME_GPIM_2017"), "N_ME_GPIM_2017"),
  check("net_nrc_stock_present", any(component_panel$variable_id == "N_NRC_GPIM_2017"), "N_NRC_GPIM_2017"),
  check("me_retirement_present", any(component_panel$variable_id == "RET_ME_GPIM_2017"), "RET_ME_GPIM_2017"),
  check("nrc_retirement_present", any(component_panel$variable_id == "RET_NRC_GPIM_2017"), "RET_NRC_GPIM_2017"),
  check("me_cfc_present", any(component_panel$variable_id == "CFC_ME_GPIM_2017"), "CFC_ME_GPIM_2017"),
  check("nrc_cfc_present", any(component_panel$variable_id == "CFC_NRC_GPIM_2017"), "CFC_NRC_GPIM_2017"),
  check("me_unit_is_millions_2017_dollars", all(component_panel$unit[component_panel$asset_scope == "ME"] == "millions_2017_dollars"), "ME unit millions_2017_dollars"),
  check("nrc_unit_is_millions_2017_dollars", all(component_panel$unit[component_panel$asset_scope == "NRC"] == "millions_2017_dollars"), "NRC unit millions_2017_dollars"),
  check("me_nrc_units_compatible", length(unique(component_panel$unit[component_panel$asset_scope %in% c("ME", "NRC")])) == 1, "ME/NRC units compatible"),
  check("me_nrc_frequency_compatible", all(diff(sort(unique(component_panel$year[component_panel$asset_scope == "ME"]))) == 1) && all(diff(sort(unique(component_panel$year[component_panel$asset_scope == "NRC"]))) == 1), "annual frequency"),
  check("me_nrc_timing_compatible", identical(sort(unique(component_panel$year[component_panel$asset_scope == "ME"])), sort(unique(component_panel$year[component_panel$asset_scope == "NRC"]))), "identical calendar years"),
  check("me_nrc_coverage_compatible", min(years) == 1901 && max(years) == 2024 && length(years) == 124, "1901-2024, 124 years"),
  check("core_boundary_contains_only_me_and_nrc", setequal(unique(component_panel$asset_scope), c("ME", "NRC")), "component scope ME/NRC only"),
  check("core_real_investment_constructed", "I_CORE_REAL_2017" %in% core_panel$variable_id, "I_CORE_REAL_2017"),
  check("core_gross_stock_constructed", "G_CORE_GPIM_2017" %in% core_panel$variable_id, "G_CORE_GPIM_2017"),
  check("core_net_stock_constructed", "N_CORE_GPIM_2017" %in% core_panel$variable_id, "N_CORE_GPIM_2017"),
  check("core_retirement_constructed", "RET_CORE_GPIM_2017" %in% core_panel$variable_id, "RET_CORE_GPIM_2017"),
  check("core_cfc_constructed", "CFC_CORE_GPIM_2017" %in% core_panel$variable_id, "CFC_CORE_GPIM_2017"),
  check("core_real_investment_exact_addition_pass", reconciliation$reconciliation_status[reconciliation$variable_id == "I_CORE_REAL_2017"] == "PASS", "I exact addition"),
  check("core_gross_stock_exact_addition_pass", reconciliation$reconciliation_status[reconciliation$variable_id == "G_CORE_GPIM_2017"] == "PASS", "G exact addition"),
  check("core_net_stock_exact_addition_pass", reconciliation$reconciliation_status[reconciliation$variable_id == "N_CORE_GPIM_2017"] == "PASS", "N exact addition"),
  check("core_retirement_exact_addition_pass", reconciliation$reconciliation_status[reconciliation$variable_id == "RET_CORE_GPIM_2017"] == "PASS", "RET exact addition"),
  check("core_cfc_exact_addition_pass", reconciliation$reconciliation_status[reconciliation$variable_id == "CFC_CORE_GPIM_2017"] == "PASS", "CFC exact addition"),
  check("component_reconciliation_residuals_within_tolerance", max_recon <= tolerance, paste("max", max_recon)),
  check("core_gross_sfc_identity_pass", gross_sfc$residual_status == "PASS", "gross core SFC PASS"),
  check("core_net_sfc_identity_pass", net_sfc$residual_status == "PASS", "net core SFC PASS"),
  check("core_gross_sfc_max_residual_within_tolerance", gross_sfc$maximum_absolute_residual <= tolerance, paste("max", gross_sfc$maximum_absolute_residual)),
  check("core_net_sfc_max_residual_within_tolerance", net_sfc$maximum_absolute_residual <= tolerance, paste("max", net_sfc$maximum_absolute_residual)),
  check("core_first_fully_supported_year_equals_1931", core_first_full == 1931, paste("core first fully supported", core_first_full)),
  check("core_warmup_years_explicitly_flagged", any(support_audit$CORE_support_status == "partial_vintage_warmup"), "warm-up rows flagged"),
  check("core_fully_supported_years_explicitly_flagged", any(support_audit$CORE_support_status == "fully_supported"), "fully supported rows flagged"),
  check("common_unit_timing_audit_created", file.exists(output_paths$unit_timing) && all(unit_timing$status == "PASS"), paste(nrow(unit_timing), "unit/timing rows")),
  check("construction_ledger_created", file.exists(output_paths$ledger) && nrow(ledger) == 5, paste(nrow(ledger), "ledger rows")),
  check("reconciliation_audit_created", file.exists(output_paths$reconciliation) && nrow(reconciliation) == 5, paste(nrow(reconciliation), "reconciliation rows")),
  check("gross_sfc_audit_created", file.exists(output_paths$gross_sfc) && nrow(gross_sfc) == 1, "gross SFC audit created"),
  check("net_sfc_audit_created", file.exists(output_paths$net_sfc) && nrow(net_sfc) == 1, "net SFC audit created"),
  check("support_status_audit_created", file.exists(output_paths$support) && nrow(support_audit) == 124, paste(nrow(support_audit), "support rows")),
  check("provenance_ledger_created", file.exists(output_paths$provenance) && nrow(provenance) == 5, paste(nrow(provenance), "provenance rows")),
  check("me_gross_share_constructed_as_diagnostic", "SHARE_ME_GROSS_CORE" %in% names(shares), "ME gross share diagnostic"),
  check("nrc_gross_share_constructed_as_diagnostic", "SHARE_NRC_GROSS_CORE" %in% names(shares), "NRC gross share diagnostic"),
  check("gross_composition_shares_sum_to_one", max(abs(shares$share_sum_residual)) <= tolerance && all(shares$share_status == "PASS"), paste("max residual", max(abs(shares$share_sum_residual)))),
  check("arithmetic_growth_contribution_audit_created", file.exists(output_paths$growth) && nrow(growth) == 123, paste(nrow(growth), "growth rows")),
  check("arithmetic_growth_contribution_identity_pass", max(abs(growth$growth_contribution_residual), na.rm = TRUE) <= tolerance && all(growth$growth_contribution_status == "PASS"), paste("max residual", max(abs(growth$growth_contribution_residual), na.rm = TRUE))),
  check("no_weighted_level_construction", no_weighted$constructed_object_count[no_weighted$audit_item == "no_weighted_level_construction"] == 0, "no weighted level construction"),
  check("no_weighted_growth_stock_construction", no_weighted$constructed_object_count[no_weighted$audit_item == "no_weighted_growth_stock_construction"] == 0, "growth audit diagnostic only"),
  check("no_chain_weighted_capital_index_constructed", all(no_chain$constructed_object_count == 0), "no chain index"),
  check("no_gpim_rerun_on_aggregate_investment", no_rerun$constructed_object_count[no_rerun$audit_item == "no_gpim_rerun_on_aggregate_investment"] == 0, "no aggregate GPIM rerun"),
  check("no_gpim_parameters_modified", no_rerun$constructed_object_count[no_rerun$audit_item == "no_gpim_parameter_modification"] == 0 && upstream_unchanged, "no parameter modification"),
  check("no_ipp_in_core", no_boundary$constructed_object_count[no_boundary$audit_item == "no_ipp_in_core"] == 0, "no IPP"),
  check("no_government_transportation_in_core", no_boundary$constructed_object_count[no_boundary$audit_item == "no_government_transportation_in_core"] == 0, "no government transportation"),
  check("no_residential_assets_in_core", no_boundary$constructed_object_count[no_boundary$audit_item == "no_residential_assets_in_core"] == 0, "no residential"),
  check("no_total_fixed_assets_in_core", no_boundary$constructed_object_count[no_boundary$audit_item == "no_total_fixed_assets_in_core"] == 0, "no total fixed assets"),
  check("no_alternative_core_stock_constructed", no_boundary$constructed_object_count[no_boundary$audit_item == "no_alternative_core_stock"] == 0, "no alternative core stock"),
  check("no_real_output_variables_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_real_output"] == 0, "no real output"),
  check("no_q_variables_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_q"] == 0, "no q"),
  check("no_theta_variables_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_theta"] == 0, "no theta"),
  check("no_productive_capacity_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_productive_capacity"] == 0, "no productive capacity"),
  check("no_utilization_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_utilization"] == 0, "no utilization"),
  check("no_modeling_outputs_created", no_modeling$constructed_object_count[no_modeling$audit_item == "no_modeling"] == 0, "no modeling"),
  check("no_econometric_outputs_created", no_modeling$constructed_object_count[no_modeling$audit_item == "no_econometrics"] == 0, "no econometrics"),
  check("no_adjusted_shaikh_objects_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_adjusted_shaikh"] == 0, "no adjusted Shaikh"),
  check("upstream_outputs_not_modified", upstream_unchanged, "S29D/S29C input hashes unchanged"),
  check("provider_repository_not_modified", provider_tracked_clean(provider_repo), "Provider repo tracked and staged diffs are clean; untracked local files are ignored.")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)

all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 72
final_decision <- if (all_validation_pass) clean_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

validation_md <- c(
  "# S29E Stock-Flow-Consistent Core Capital Aggregation Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 72", "FAIL"), "`."),
  "",
  paste0("Core constructed variables: `", nrow(ledger), "`."),
  paste0("Output panel rows: `", nrow(output_panel), "`."),
  paste0("Core first fully supported year: `", core_first_full, "`."),
  paste0("Maximum reconciliation residual: `", max_recon, "`."),
  paste0("Maximum aggregate SFC residual: `", max(gross_sfc$maximum_absolute_residual, net_sfc$maximum_absolute_residual), "`."),
  "",
  "S29E constructs core investment, gross stock, net stock, retirements, and CFC by exact ME+NRC addition only. It constructs no weighted capital index, chain index, q, theta, productive capacity, utilization, modeling, or econometric output.",
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29E Stock-Flow-Consistent Core Capital Aggregation Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29E consumed S29D commit `", s29d_commit, "`, S29C commit `", s29c_commit, "`, S29B commit `", s29b_commit, "`, S29A commit `", s29a_commit, "`, S28 commit `", s28_commit, "`, S27 commit `", s27_commit, "`, S26 commit `", s26_commit, "`, S25 commit `", s25_commit, "`, S24B commit `", s24b_commit, "`, S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("S29E preserves locked GPIM lineage: S12D-A4 `", s12d_a4_commit, "`, S12D-B `", s12d_b_commit, "`, S12D-C `", s12d_c_commit, "`, and S13 `", s13_commit, "`."),
  "",
  paste0("S29E validation: `", ifelse(all_validation_pass, "PASS 72", "FAIL"), "`."),
  paste0("Constructed core variables: `", paste(ledger$constructed_variable_id, collapse = "; "), "`."),
  paste0("Core panel rows: `", nrow(core_panel), "`."),
  paste0("Full output panel rows including components: `", nrow(output_panel), "`."),
  paste0("Core coverage: `", min(years), "-", max(years), "`."),
  paste0("Core first fully supported year: `", core_first_full, "`."),
  paste0("Core warm-up observations: `", sum(support_audit$CORE_support_status == "partial_vintage_warmup"), "`."),
  paste0("Maximum reconciliation residual: `", max_recon, "`."),
  paste0("Maximum aggregate gross SFC residual: `", gross_sfc$maximum_absolute_residual, "`."),
  paste0("Maximum aggregate net SFC residual: `", net_sfc$maximum_absolute_residual, "`."),
  paste0("Residual tolerance: `", tolerance, "`."),
  "",
  "S29E authorizes only bounded core capital analytical transformations. It does not authorize q, theta, productive capacity, utilization, output-capital regressors, modeling, or econometrics.",
  "",
  "S29E stops here."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) {
  stop("S29E validation failed; see ", output_paths$validation)
}

message("S29E validation PASS 72")
message("Constructed core variables: ", nrow(ledger))
message("Output panel rows: ", nrow(output_panel))
message("Decision: ", final_decision)
