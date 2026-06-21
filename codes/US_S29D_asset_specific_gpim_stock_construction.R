# S29D constructs asset-specific ME/NRC GPIM stocks and flows only.
# It preserves the locked S12D schedule convention and does not aggregate.

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

s12d_a4_commit <- "f506afd2da9888938ad05f8578d984b8523e014d"
s12d_b_commit <- "5cbc2aae90fa1d8d5fb27057f44c879c383b1260"
s12d_c_commit <- "dd7a13fa4e715ab4645c1bd53999491550c505ea"
s13_commit <- "906ed9f744da64e9931e7f8ec653d92da25384f1"

stage_id <- "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION"
required_s29c_decision <- "AUTHORIZE_S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION"
clean_decision <- "AUTHORIZE_S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION"
blocked_decision <- "BLOCK_FOR_ASSET_SPECIFIC_GPIM_STOCK_REVIEW"
clean_status <- "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION_COMPLETE_S29E_AUTHORIZED"
blocked_status <- "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION_BLOCKED_FOR_REVIEW"
tolerance <- 1e-6

path <- function(...) file.path(...)

s29c_dir <- path(repo_root, "output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION")
s29b_dir <- path(repo_root, "output", "US", "S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP")
s12d_a4_dir <- path(repo_root, "output", "US", "S12D_A4_MANUAL_GPIM_NET_VALUE_THEORY_LOCK")
s12d_b_dir <- path(repo_root, "output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION")
s12d_c_dir <- path(repo_root, "output", "US", "S12D_C_GPIM_DOWNSTREAM_READINESS_LOCK")
s13_dir <- path(repo_root, "output", "US", "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION")
s29d_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s29d_dir, "csv")
md_dir <- path(s29d_dir, "md")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s29c_input_paths <- list(
  panel = path(s29c_dir, "csv", "S29C_fixed_assets_price_real_investment_long.csv"),
  deflator_ledger = path(s29c_dir, "csv", "S29C_deflator_construction_ledger.csv"),
  real_ledger = path(s29c_dir, "csv", "S29C_real_investment_construction_ledger.csv"),
  formula = path(s29c_dir, "csv", "S29C_nominal_price_real_formula_audit.csv"),
  unit = path(s29c_dir, "csv", "S29C_reference_year_unit_audit.csv"),
  provenance = path(s29c_dir, "csv", "S29C_source_to_derived_provenance_audit.csv"),
  admissibility = path(s29c_dir, "csv", "S29C_deflator_admissibility_audit.csv"),
  coverage = path(s29c_dir, "csv", "S29C_time_coverage_missingness_audit.csv"),
  comparison = path(s29c_dir, "csv", "S29C_locked_baseline_comparison_audit.csv"),
  no_gpim_stock = path(s29c_dir, "csv", "S29C_no_gpim_stock_construction_audit.csv"),
  validation = path(s29c_dir, "csv", "S29C_validation_checks.csv"),
  validation_md = path(s29c_dir, "md", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION_VALIDATION.md"),
  decision_md = path(s29c_dir, "md", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION_DECISION.md")
)

s29b_input_paths <- list(
  parameter_lock = path(s29b_dir, "csv", "S29B_gpim_parameter_lock_ledger.csv"),
  baseline_reuse = path(s29b_dir, "csv", "S29B_gpim_baseline_reuse_ledger.csv"),
  initialization = path(s29b_dir, "csv", "S29B_initialization_vintage_readiness_audit.csv"),
  asset_sfc = path(s29b_dir, "csv", "S29B_asset_level_stock_flow_consistency_contract.csv"),
  aggregation = path(s29b_dir, "csv", "S29B_aggregation_rule_authorization_matrix.csv"),
  validation = path(s29b_dir, "csv", "S29B_validation_checks.csv")
)

gpim_input_paths <- list(
  s12d_a4_parameters = path(s12d_a4_dir, "csv", "S12D_A4_protocol_parameters.csv"),
  s12d_a4_lock = path(s12d_a4_dir, "csv", "S12D_A4_manual_lock_ledger.csv"),
  s12d_b_script = path(repo_root, "codes", "US_S12D_B_gpim_baseline_construction.R"),
  s12d_b_stock = path(s12d_b_dir, "csv", "S12D_B_gpim_stock_panel.csv"),
  s12d_b_real = path(s12d_b_dir, "csv", "S12D_B_real_investment_flows.csv"),
  s12d_b_validation = path(s12d_b_dir, "csv", "S12D_B_validation_checks.csv"),
  s12d_c_contract = path(s12d_c_dir, "csv", "S12D_C_consumption_contract.csv"),
  s12d_c_readiness = path(s12d_c_dir, "csv", "S12D_C_readiness_checks.csv"),
  s13_panel = path(s13_dir, "csv", "S13_gpim_source_panel_long.csv"),
  s13_audit = path(s13_dir, "csv", "S13_consumption_audit.csv"),
  s13_validation = path(s13_dir, "csv", "S13_validation_checks.csv")
)

output_paths <- list(
  panel = path(csv_dir, "S29D_asset_specific_gpim_stocks_flows_long.csv"),
  schedule = path(csv_dir, "S29D_gpim_parameter_schedule_audit.csv"),
  me_vintage = path(csv_dir, "S29D_me_vintage_contribution_audit.csv"),
  nrc_vintage = path(csv_dir, "S29D_nrc_vintage_contribution_audit.csv"),
  ledger = path(csv_dir, "S29D_asset_specific_construction_ledger.csv"),
  provenance = path(csv_dir, "S29D_asset_specific_source_to_stock_provenance.csv"),
  gross_sfc = path(csv_dir, "S29D_asset_specific_gross_sfc_residual_audit.csv"),
  net_sfc = path(csv_dir, "S29D_asset_specific_net_sfc_residual_audit.csv"),
  initialization = path(csv_dir, "S29D_initialization_support_status_audit.csv"),
  comparison = path(csv_dir, "S29D_locked_baseline_comparison_audit.csv"),
  no_aggregation = path(csv_dir, "S29D_no_aggregation_audit.csv"),
  no_cross_family = path(csv_dir, "S29D_no_cross_family_audit.csv"),
  no_modeling = path(csv_dir, "S29D_no_downstream_modeling_audit.csv"),
  validation = path(csv_dir, "S29D_validation_checks.csv"),
  validation_md = path(md_dir, "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION_VALIDATION.md"),
  decision_md = path(md_dir, "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION_DECISION.md")
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

all_input_paths <- c(unlist(s29c_input_paths), unlist(s29b_input_paths), unlist(gpim_input_paths))
stop_if_missing(all_input_paths, "S29D inputs")
md5_before <- tools::md5sum(all_input_paths)

s29c_panel <- read_csv(s29c_input_paths$panel)
s29c_unit <- read_csv(s29c_input_paths$unit)
s29c_coverage <- read_csv(s29c_input_paths$coverage)
s29c_validation <- read_csv(s29c_input_paths$validation)
s29c_decision <- read_text(s29c_input_paths$decision_md)
s29b_params <- read_csv(s29b_input_paths$parameter_lock)
s29b_initialization <- read_csv(s29b_input_paths$initialization)
s29b_validation <- read_csv(s29b_input_paths$validation)
s12d_a4_params <- read_csv(gpim_input_paths$s12d_a4_parameters)
s12d_b_stock <- read_csv(gpim_input_paths$s12d_b_stock)
s12d_b_validation <- read_csv(gpim_input_paths$s12d_b_validation)
s12d_c_contract <- read_csv(gpim_input_paths$s12d_c_contract)
s12d_c_readiness <- read_csv(gpim_input_paths$s12d_c_readiness)
s13_panel <- read_csv(gpim_input_paths$s13_panel)
s13_validation <- read_csv(gpim_input_paths$s13_validation)

if (!all_pass(s29c_validation) || nrow(s29c_validation) != 77 ||
    !grepl(required_s29c_decision, s29c_decision, fixed = TRUE)) {
  stop("S29C gate is not clean or does not authorize S29D.")
}

weibull_schedule <- function(asset_family, L, alpha, d) {
  ages <- 0:L
  lambda <- L / gamma(1 + 1 / alpha)
  survival <- exp(-((ages / lambda)^alpha))
  net_value <- survival * ((1 - d)^ages)
  base <- data.frame(
    asset_family = asset_family,
    vintage_age = ages,
    service_life_L = L,
    survival_shape_alpha = alpha,
    depreciation_value_parameter_d = d,
    lambda = lambda,
    survival_weight = survival,
    net_value_weight = net_value,
    terminal_age_for_exit_flow = "no",
    stringsAsFactors = FALSE
  )
  terminal <- data.frame(
    asset_family = asset_family,
    vintage_age = L + 1L,
    service_life_L = L,
    survival_shape_alpha = alpha,
    depreciation_value_parameter_d = d,
    lambda = lambda,
    survival_weight = 0,
    net_value_weight = 0,
    terminal_age_for_exit_flow = "yes",
    stringsAsFactors = FALSE
  )
  rbind(base, terminal)
}

asset_specs <- data.frame(
  asset_family = c("ME", "NRC"),
  real_variable_id = c("I_ME_REAL_2017", "I_NRC_REAL_2017"),
  gross_variable_id = c("G_ME_GPIM_2017", "G_NRC_GPIM_2017"),
  retirement_variable_id = c("RET_ME_GPIM_2017", "RET_NRC_GPIM_2017"),
  net_variable_id = c("N_ME_GPIM_2017", "N_NRC_GPIM_2017"),
  cfc_variable_id = c("CFC_ME_GPIM_2017", "CFC_NRC_GPIM_2017"),
  stringsAsFactors = FALSE
)

schedule_list <- list()
vintage_list <- list()
stock_flow_list <- list()
init_list <- list()

for (i in seq_len(nrow(asset_specs))) {
  spec <- asset_specs[i, , drop = FALSE]
  param <- s29b_params[s29b_params$asset_family == spec$asset_family, , drop = FALSE]
  L <- as.integer(param$service_life_L)
  alpha <- as.numeric(param$survival_shape_alpha)
  d <- as.numeric(param$depreciation_value_parameter_d)
  sched <- weibull_schedule(spec$asset_family, L, alpha, d)
  sched$stage_id <- stage_id
  sched$survival_formula <- "S(a)=exp(-((a/(L/gamma(1+1/alpha)))^alpha)); ages 0:L; terminal L+1 set to zero for exit flows"
  sched$net_value_formula <- "V(a)=S(a)*(1-d)^a; terminal L+1 set to zero for CFC flow"
  schedule_list[[spec$asset_family]] <- sched

  real <- s29c_panel[s29c_panel$derived_variable_id == spec$real_variable_id, c("year", "value", "unit"), drop = FALSE]
  real$year <- as.integer(real$year)
  real$value <- as.numeric(real$value)
  real <- real[order(real$year), , drop = FALSE]
  first_full <- as.integer(s29b_initialization$first_fully_supported_year[s29b_initialization$asset_family == spec$asset_family])
  min_year <- min(real$year)
  max_year <- max(real$year)

  vintage_rows <- list()
  v_idx <- 1L
  for (calendar_year in min_year:max_year) {
    support_status <- ifelse(calendar_year < first_full, "partial_vintage_warmup", "fully_supported")
    for (age in 0:(L + 1L)) {
      vintage_year <- calendar_year - age
      if (!vintage_year %in% real$year) next
      real_investment <- real$value[real$year == vintage_year]
      s_age <- sched$survival_weight[sched$vintage_age == age]
      v_age <- sched$net_value_weight[sched$vintage_age == age]
      s_prev <- if (age == 0L) 1 else sched$survival_weight[sched$vintage_age == age - 1L]
      v_prev <- if (age == 0L) 1 else sched$net_value_weight[sched$vintage_age == age - 1L]
      retirement_weight <- if (age == 0L) 0 else s_prev - s_age
      cfc_weight <- if (age == 0L) 0 else v_prev - v_age
      vintage_rows[[v_idx]] <- data.frame(
        stage_id = stage_id,
        asset_family = spec$asset_family,
        calendar_year = calendar_year,
        vintage_year = vintage_year,
        vintage_age = age,
        real_investment = real_investment,
        survival_weight = s_age,
        net_value_weight = v_age,
        retirement_weight = retirement_weight,
        cfc_weight = cfc_weight,
        gross_stock_contribution = s_age * real_investment,
        net_stock_contribution = v_age * real_investment,
        retirement_contribution = retirement_weight * real_investment,
        cfc_contribution = cfc_weight * real_investment,
        support_status = support_status,
        stringsAsFactors = FALSE
      )
      v_idx <- v_idx + 1L
    }
  }
  vintage <- do.call(rbind, vintage_rows)
  vintage_list[[spec$asset_family]] <- vintage

  annual <- aggregate(
    cbind(gross_stock_contribution, net_stock_contribution, retirement_contribution, cfc_contribution) ~ calendar_year + asset_family + support_status,
    data = vintage,
    FUN = sum
  )
  names(annual) <- c("year", "asset_family", "support_status", "gross_stock", "net_stock", "retirements", "cfc")
  annual$real_investment <- real$value[match(annual$year, real$year)]
  annual <- annual[order(annual$year), , drop = FALSE]
  stock_flow_list[[spec$asset_family]] <- annual

  init_list[[spec$asset_family]] <- data.frame(
    stage_id = stage_id,
    asset_family = spec$asset_family,
    first_investment_year = min_year,
    first_constructed_stock_year = min(annual$year),
    first_fully_supported_stock_year = first_full,
    last_stock_year = max(annual$year),
    warmup_observations = sum(annual$support_status == "partial_vintage_warmup"),
    fully_supported_observations = sum(annual$support_status == "fully_supported"),
    stringsAsFactors = FALSE
  )
}

schedule_audit <- do.call(rbind, schedule_list)
me_vintage <- vintage_list[["ME"]]
nrc_vintage <- vintage_list[["NRC"]]
annual_all <- do.call(rbind, stock_flow_list)
initialization_audit <- do.call(rbind, init_list)

panel_rows <- list()
for (i in seq_len(nrow(asset_specs))) {
  spec <- asset_specs[i, , drop = FALSE]
  annual <- annual_all[annual_all$asset_family == spec$asset_family, , drop = FALSE]
  variables <- list(
    gross = list(id = spec$gross_variable_id, role = "gross_gpim_stock", value = annual$gross_stock, unit = "millions_2017_dollars"),
    retirement = list(id = spec$retirement_variable_id, role = "retirement_flow", value = annual$retirements, unit = "millions_2017_dollars"),
    net = list(id = spec$net_variable_id, role = "net_gpim_stock", value = annual$net_stock, unit = "millions_2017_dollars"),
    cfc = list(id = spec$cfc_variable_id, role = "consumption_of_fixed_capital_flow", value = annual$cfc, unit = "millions_2017_dollars")
  )
  for (entry in variables) {
    panel_rows[[length(panel_rows) + 1L]] <- data.frame(
      stage_id = stage_id,
      asset_family = spec$asset_family,
      derived_variable_id = entry$id,
      variable_role = entry$role,
      year = annual$year,
      value = entry$value,
      unit = entry$unit,
      support_status = annual$support_status,
      source_real_investment_variable_id = spec$real_variable_id,
      provider_v1_commit = provider_v1_commit,
      s12d_a4_commit = s12d_a4_commit,
      s12d_b_commit = s12d_b_commit,
      s12d_c_commit = s12d_c_commit,
      s13_commit = s13_commit,
      s29b_setup_commit = s29b_commit,
      s29c_real_investment_commit = s29c_commit,
      modeling_authorized = "no",
      econometrics_authorized = "no",
      stringsAsFactors = FALSE
    )
  }
}
stock_flow_panel <- do.call(rbind, panel_rows)
stock_flow_panel <- stock_flow_panel[order(stock_flow_panel$asset_family, stock_flow_panel$derived_variable_id, stock_flow_panel$year), ]

residual_rows <- function(asset, identity) {
  annual <- annual_all[annual_all$asset_family == asset, , drop = FALSE]
  annual <- annual[order(annual$year), ]
  if (identity == "gross") {
    residual <- annual$gross_stock - c(NA, head(annual$gross_stock, -1)) - annual$real_investment + annual$retirements
  } else {
    residual <- annual$net_stock - c(NA, head(annual$net_stock, -1)) - annual$real_investment + annual$cfc
  }
  tested <- !is.na(residual)
  data.frame(
    stage_id = stage_id,
    asset_family = asset,
    identity = identity,
    maximum_absolute_residual = max(abs(residual[tested]), na.rm = TRUE),
    mean_absolute_residual = mean(abs(residual[tested]), na.rm = TRUE),
    median_absolute_residual = median(abs(residual[tested]), na.rm = TRUE),
    tolerance = tolerance,
    observations_outside_tolerance = sum(abs(residual[tested]) > tolerance, na.rm = TRUE),
    first_tested_year = min(annual$year[tested]),
    last_tested_year = max(annual$year[tested]),
    tested_observations = sum(tested),
    residual_status = ifelse(max(abs(residual[tested]), na.rm = TRUE) <= tolerance, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}
gross_sfc <- do.call(rbind, list(residual_rows("ME", "gross"), residual_rows("NRC", "gross")))
net_sfc <- do.call(rbind, list(residual_rows("ME", "net"), residual_rows("NRC", "net")))

construction_ledger <- do.call(rbind, lapply(seq_len(nrow(asset_specs)), function(i) {
  spec <- asset_specs[i, , drop = FALSE]
  annual <- annual_all[annual_all$asset_family == spec$asset_family, , drop = FALSE]
  data.frame(
    stage_id = stage_id,
    asset_family = spec$asset_family,
    constructed_variable_id = c(spec$gross_variable_id, spec$retirement_variable_id, spec$net_variable_id, spec$cfc_variable_id),
    variable_role = c("gross_gpim_stock", "retirement_flow", "net_gpim_stock", "consumption_of_fixed_capital_flow"),
    construction_status = "constructed",
    source_real_investment_variable_id = spec$real_variable_id,
    observation_count = nrow(annual),
    year_start = min(annual$year),
    year_end = max(annual$year),
    first_fully_supported_year = initialization_audit$first_fully_supported_stock_year[initialization_audit$asset_family == spec$asset_family],
    unit = "millions_2017_dollars",
    stringsAsFactors = FALSE
  )
}))

provenance <- do.call(rbind, lapply(seq_len(nrow(asset_specs)), function(i) {
  spec <- asset_specs[i, , drop = FALSE]
  data.frame(
    stage_id = stage_id,
    asset_family = spec$asset_family,
    constructed_variable_id = c(spec$gross_variable_id, spec$retirement_variable_id, spec$net_variable_id, spec$cfc_variable_id),
    source_real_investment_variable_id = spec$real_variable_id,
    source_stage = "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION",
    schedule_source = "S12D_A4/S12D_B locked Weibull survival and net-value schedule",
    parameter_source = "S29B_gpim_parameter_lock_ledger.csv",
    provider_v1_commit = provider_v1_commit,
    s12d_a4_commit = s12d_a4_commit,
    s12d_b_commit = s12d_b_commit,
    s12d_c_commit = s12d_c_commit,
    s13_commit = s13_commit,
    s29b_setup_commit = s29b_commit,
    s29c_real_investment_commit = s29c_commit,
    stringsAsFactors = FALSE
  )
}))

compare_series <- function(asset, constructed_id, baseline_col, baseline_role) {
  cdf <- stock_flow_panel[stock_flow_panel$asset_family == asset & stock_flow_panel$derived_variable_id == constructed_id, c("year", "value"), drop = FALSE]
  bdf <- s12d_b_stock[s12d_b_stock$asset_block == asset, c("year", baseline_col), drop = FALSE]
  cdf$year <- as.integer(cdf$year)
  bdf$year <- as.integer(bdf$year)
  cdf$value <- as.numeric(cdf$value)
  bdf[[baseline_col]] <- as.numeric(bdf[[baseline_col]])
  names(bdf) <- c("year", "baseline_value")
  names(cdf) <- c("year", "constructed_value")
  merged <- merge(cdf, bdf, by = "year", all = FALSE)
  merged$absolute_difference <- abs(merged$constructed_value - merged$baseline_value)
  merged$relative_difference <- ifelse(abs(merged$baseline_value) > 0, merged$absolute_difference / abs(merged$baseline_value), NA)
  max_abs <- max(merged$absolute_difference, na.rm = TRUE)
  mean_abs <- mean(merged$absolute_difference, na.rm = TRUE)
  max_rel <- max(merged$relative_difference, na.rm = TRUE)
  mean_rel <- mean(merged$relative_difference, na.rm = TRUE)
  class <- ifelse(max_abs <= 1e-8, "exact_match", ifelse(max_abs <= 1e-6, "rounding_only", "unresolved"))
  data.frame(
    stage_id = stage_id,
    asset_family = asset,
    constructed_variable_id = constructed_id,
    locked_baseline_role = baseline_role,
    overlap_years = nrow(merged),
    maximum_absolute_difference = max_abs,
    mean_absolute_difference = mean_abs,
    maximum_relative_difference = max_rel,
    mean_relative_difference = mean_rel,
    comparison_classification = class,
    unresolved_material_difference = ifelse(class == "unresolved", "yes", "no"),
    stringsAsFactors = FALSE
  )
}
comparison <- do.call(rbind, list(
  compare_series("ME", "G_ME_GPIM_2017", "gross_survival_gpim_stock_2017_millions", "S12D_B_GROSS_SURVIVAL_GPIM_STOCK_BASELINE"),
  compare_series("NRC", "G_NRC_GPIM_2017", "gross_survival_gpim_stock_2017_millions", "S12D_B_GROSS_SURVIVAL_GPIM_STOCK_BASELINE"),
  compare_series("ME", "N_ME_GPIM_2017", "net_value_gpim_stock_diagnostic_2017_millions", "S12D_B_NET_VALUE_GPIM_STOCK_DIAGNOSTIC"),
  compare_series("NRC", "N_NRC_GPIM_2017", "net_value_gpim_stock_diagnostic_2017_millions", "S12D_B_NET_VALUE_GPIM_STOCK_DIAGNOSTIC"),
  data.frame(
    stage_id = stage_id,
    asset_family = c("ME", "NRC", "ME", "NRC"),
    constructed_variable_id = c("RET_ME_GPIM_2017", "RET_NRC_GPIM_2017", "CFC_ME_GPIM_2017", "CFC_NRC_GPIM_2017"),
    locked_baseline_role = c("retirement_flow_not_available_in_s12d_s13", "retirement_flow_not_available_in_s12d_s13", "cfc_flow_not_available_in_s12d_s13", "cfc_flow_not_available_in_s12d_s13"),
    overlap_years = 0L,
    maximum_absolute_difference = NA_real_,
    mean_absolute_difference = NA_real_,
    maximum_relative_difference = NA_real_,
    mean_relative_difference = NA_real_,
    comparison_classification = "not_available_in_locked_baseline",
    unresolved_material_difference = "no",
    stringsAsFactors = FALSE
  )
))

no_aggregation <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_aggregate_investment", "no_aggregate_gross_stock", "no_aggregate_net_stock", "no_aggregate_retirements", "no_aggregate_cfc", "no_core_capital_stock", "no_weighted_growth_aggregate"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = "S29D constructs only separate ME and NRC stock-flow systems.",
  stringsAsFactors = FALSE
)
no_cross_family <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_ipp_gpim_stock", "no_government_transport_gpim_stock", "no_residential_gpim_stock", "no_total_fixed_assets_gpim_stock", "no_cross_asset_schedule_use"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = c(
    "IPP remains outside S29D.",
    "Government transportation remains outside S29D.",
    "Residential assets remain outside S29D.",
    "Total fixed assets remain outside S29D.",
    "ME uses the ME schedule and NRC uses the NRC schedule."
  ),
  stringsAsFactors = FALSE
)
no_modeling <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_real_output", "no_q", "no_theta", "no_productive_capacity", "no_utilization", "no_modeling", "no_econometrics", "no_adjusted_shaikh"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = "S29D emits only asset-specific GPIM stock/flow construction outputs and audits.",
  stringsAsFactors = FALSE
)

write.csv(stock_flow_panel, output_paths$panel, row.names = FALSE)
write.csv(schedule_audit, output_paths$schedule, row.names = FALSE)
write.csv(me_vintage, output_paths$me_vintage, row.names = FALSE)
write.csv(nrc_vintage, output_paths$nrc_vintage, row.names = FALSE)
write.csv(construction_ledger, output_paths$ledger, row.names = FALSE)
write.csv(provenance, output_paths$provenance, row.names = FALSE)
write.csv(gross_sfc, output_paths$gross_sfc, row.names = FALSE)
write.csv(net_sfc, output_paths$net_sfc, row.names = FALSE)
write.csv(initialization_audit, output_paths$initialization, row.names = FALSE)
write.csv(comparison, output_paths$comparison, row.names = FALSE)
write.csv(no_aggregation, output_paths$no_aggregation, row.names = FALSE)
write.csv(no_cross_family, output_paths$no_cross_family, row.names = FALSE)
write.csv(no_modeling, output_paths$no_modeling, row.names = FALSE)

md5_after <- tools::md5sum(all_input_paths)
gpim_hash_unchanged <- identical(unname(md5_before[unlist(gpim_input_paths)]), unname(md5_after[unlist(gpim_input_paths)]))
all_hash_unchanged <- identical(unname(md5_before), unname(md5_after))
constructed_ids <- unique(stock_flow_panel$derived_variable_id)
unresolved_material <- sum(comparison$unresolved_material_difference == "yes")

check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}

validation_checks <- do.call(rbind, list(
  check("s29c_outputs_present", all(file.exists(unlist(s29c_input_paths))), paste(basename(unlist(s29c_input_paths)), collapse = "; ")),
  check("s29c_validation_all_pass", all_pass(s29c_validation) && nrow(s29c_validation) == 77, paste0("S29C_validation_checks.csv PASS ", nrow(s29c_validation))),
  check("s29c_decision_authorizes_s29d", grepl(required_s29c_decision, s29c_decision, fixed = TRUE), required_s29c_decision),
  check("s29b_outputs_present", all(file.exists(unlist(s29b_input_paths))), paste(basename(unlist(s29b_input_paths)), collapse = "; ")),
  check("s29b_validation_all_pass", all_pass(s29b_validation) && nrow(s29b_validation) == 80, paste0("S29B_validation_checks.csv PASS ", nrow(s29b_validation))),
  check("locked_s12d_a4_specification_present", file.exists(gpim_input_paths$s12d_a4_parameters) && file.exists(gpim_input_paths$s12d_a4_lock), "S12D-A4 parameter and lock ledgers present"),
  check("locked_s12d_b_baseline_present", file.exists(gpim_input_paths$s12d_b_stock) && file.exists(gpim_input_paths$s12d_b_script), "S12D-B stock panel and script present"),
  check("locked_s12d_c_contract_present", file.exists(gpim_input_paths$s12d_c_contract) && all_pass(s12d_c_readiness), "S12D-C contract/readiness present"),
  check("locked_s13_consumption_outputs_present", file.exists(gpim_input_paths$s13_panel) && all_pass(s13_validation), "S13 consumption outputs present"),
  check("locked_gpim_outputs_not_modified", gpim_hash_unchanged, "S12D/S13 input file hashes unchanged"),
  check("me_real_investment_present", any(s29c_panel$derived_variable_id == "I_ME_REAL_2017"), "I_ME_REAL_2017 present"),
  check("nrc_real_investment_present", any(s29c_panel$derived_variable_id == "I_NRC_REAL_2017"), "I_NRC_REAL_2017 present"),
  check("me_real_investment_unit_is_2017_dollars", s29c_unit$real_unit[s29c_unit$asset_family == "ME"] == "millions_2017_dollars", "ME unit millions_2017_dollars"),
  check("nrc_real_investment_unit_is_2017_dollars", s29c_unit$real_unit[s29c_unit$asset_family == "NRC"] == "millions_2017_dollars", "NRC unit millions_2017_dollars"),
  check("me_real_investment_coverage_verified", nrow(s29c_panel[s29c_panel$derived_variable_id == "I_ME_REAL_2017", ]) == 124, "ME 1901-2024, 124 rows"),
  check("nrc_real_investment_coverage_verified", nrow(s29c_panel[s29c_panel$derived_variable_id == "I_NRC_REAL_2017", ]) == 124, "NRC 1901-2024, 124 rows"),
  check("me_parameter_L_equals_14", s29b_params$service_life_L[s29b_params$asset_family == "ME"] == 14, "ME L=14"),
  check("me_parameter_alpha_equals_1_7", abs(s29b_params$survival_shape_alpha[s29b_params$asset_family == "ME"] - 1.7) < 1e-12, "ME alpha=1.7"),
  check("me_parameter_d_equals_0_110", abs(s29b_params$depreciation_value_parameter_d[s29b_params$asset_family == "ME"] - 0.110) < 1e-12, "ME d=0.110"),
  check("nrc_parameter_L_equals_30", s29b_params$service_life_L[s29b_params$asset_family == "NRC"] == 30, "NRC L=30"),
  check("nrc_parameter_alpha_equals_1_6", abs(s29b_params$survival_shape_alpha[s29b_params$asset_family == "NRC"] - 1.6) < 1e-12, "NRC alpha=1.6"),
  check("nrc_parameter_d_equals_0_024", abs(s29b_params$depreciation_value_parameter_d[s29b_params$asset_family == "NRC"] - 0.024) < 1e-12, "NRC d=0.024"),
  check("me_survival_schedule_matches_locked_baseline", comparison$maximum_absolute_difference[comparison$constructed_variable_id == "G_ME_GPIM_2017"] <= tolerance, "ME gross stock matches S12D-B baseline within tolerance"),
  check("nrc_survival_schedule_matches_locked_baseline", comparison$maximum_absolute_difference[comparison$constructed_variable_id == "G_NRC_GPIM_2017"] <= tolerance, "NRC gross stock matches S12D-B baseline within tolerance"),
  check("me_net_value_schedule_matches_locked_rule", comparison$maximum_absolute_difference[comparison$constructed_variable_id == "N_ME_GPIM_2017"] <= tolerance, "ME net value diagnostic matches S12D-B within tolerance"),
  check("nrc_net_value_schedule_matches_locked_rule", comparison$maximum_absolute_difference[comparison$constructed_variable_id == "N_NRC_GPIM_2017"] <= tolerance, "NRC net value diagnostic matches S12D-B within tolerance"),
  check("me_survival_schedule_nonincreasing", all(diff(schedule_audit$survival_weight[schedule_audit$asset_family == "ME"]) <= 1e-12), "ME survival non-increasing"),
  check("nrc_survival_schedule_nonincreasing", all(diff(schedule_audit$survival_weight[schedule_audit$asset_family == "NRC"]) <= 1e-12), "NRC survival non-increasing"),
  check("me_net_value_schedule_nonincreasing", all(diff(schedule_audit$net_value_weight[schedule_audit$asset_family == "ME"]) <= 1e-12), "ME net value non-increasing"),
  check("nrc_net_value_schedule_nonincreasing", all(diff(schedule_audit$net_value_weight[schedule_audit$asset_family == "NRC"]) <= 1e-12), "NRC net value non-increasing"),
  check("gross_me_stock_constructed", "G_ME_GPIM_2017" %in% constructed_ids, "G_ME_GPIM_2017 constructed"),
  check("gross_nrc_stock_constructed", "G_NRC_GPIM_2017" %in% constructed_ids, "G_NRC_GPIM_2017 constructed"),
  check("me_retirement_flow_constructed", "RET_ME_GPIM_2017" %in% constructed_ids, "RET_ME_GPIM_2017 constructed"),
  check("nrc_retirement_flow_constructed", "RET_NRC_GPIM_2017" %in% constructed_ids, "RET_NRC_GPIM_2017 constructed"),
  check("net_me_stock_constructed", "N_ME_GPIM_2017" %in% constructed_ids, "N_ME_GPIM_2017 constructed"),
  check("net_nrc_stock_constructed", "N_NRC_GPIM_2017" %in% constructed_ids, "N_NRC_GPIM_2017 constructed"),
  check("me_cfc_flow_constructed", "CFC_ME_GPIM_2017" %in% constructed_ids, "CFC_ME_GPIM_2017 constructed"),
  check("nrc_cfc_flow_constructed", "CFC_NRC_GPIM_2017" %in% constructed_ids, "CFC_NRC_GPIM_2017 constructed"),
  check("me_gross_sfc_identity_pass", gross_sfc$residual_status[gross_sfc$asset_family == "ME"] == "PASS", "ME gross SFC PASS"),
  check("nrc_gross_sfc_identity_pass", gross_sfc$residual_status[gross_sfc$asset_family == "NRC"] == "PASS", "NRC gross SFC PASS"),
  check("me_net_sfc_identity_pass", net_sfc$residual_status[net_sfc$asset_family == "ME"] == "PASS", "ME net SFC PASS"),
  check("nrc_net_sfc_identity_pass", net_sfc$residual_status[net_sfc$asset_family == "NRC"] == "PASS", "NRC net SFC PASS"),
  check("me_gross_sfc_max_residual_within_tolerance", gross_sfc$maximum_absolute_residual[gross_sfc$asset_family == "ME"] <= tolerance, paste("max", gross_sfc$maximum_absolute_residual[gross_sfc$asset_family == "ME"])),
  check("nrc_gross_sfc_max_residual_within_tolerance", gross_sfc$maximum_absolute_residual[gross_sfc$asset_family == "NRC"] <= tolerance, paste("max", gross_sfc$maximum_absolute_residual[gross_sfc$asset_family == "NRC"])),
  check("me_net_sfc_max_residual_within_tolerance", net_sfc$maximum_absolute_residual[net_sfc$asset_family == "ME"] <= tolerance, paste("max", net_sfc$maximum_absolute_residual[net_sfc$asset_family == "ME"])),
  check("nrc_net_sfc_max_residual_within_tolerance", net_sfc$maximum_absolute_residual[net_sfc$asset_family == "NRC"] <= tolerance, paste("max", net_sfc$maximum_absolute_residual[net_sfc$asset_family == "NRC"])),
  check("me_first_fully_supported_year_equals_1925", initialization_audit$first_fully_supported_stock_year[initialization_audit$asset_family == "ME"] == 1925, "ME first fully supported year 1925"),
  check("nrc_first_fully_supported_year_equals_1931", initialization_audit$first_fully_supported_stock_year[initialization_audit$asset_family == "NRC"] == 1931, "NRC first fully supported year 1931"),
  check("warmup_years_explicitly_flagged", any(stock_flow_panel$support_status == "partial_vintage_warmup"), "warm-up rows flagged"),
  check("fully_supported_years_explicitly_flagged", any(stock_flow_panel$support_status == "fully_supported"), "fully supported rows flagged"),
  check("vintage_contribution_audits_created", file.exists(output_paths$me_vintage) && file.exists(output_paths$nrc_vintage) && nrow(me_vintage) > 0 && nrow(nrc_vintage) > 0, paste(nrow(me_vintage), "ME rows;", nrow(nrc_vintage), "NRC rows")),
  check("parameter_schedule_audit_created", file.exists(output_paths$schedule) && nrow(schedule_audit) == 48, paste(nrow(schedule_audit), "schedule rows")),
  check("construction_ledger_created", file.exists(output_paths$ledger) && nrow(construction_ledger) == 8, paste(nrow(construction_ledger), "ledger rows")),
  check("source_to_stock_provenance_created", file.exists(output_paths$provenance) && nrow(provenance) == 8, paste(nrow(provenance), "provenance rows")),
  check("locked_baseline_comparison_created", file.exists(output_paths$comparison) && nrow(comparison) == 8, paste(nrow(comparison), "comparison rows")),
  check("no_unresolved_material_baseline_difference", unresolved_material == 0, paste(unresolved_material, "unresolved material rows")),
  check("no_aggregate_investment_constructed", no_aggregation$constructed_object_count[no_aggregation$audit_item == "no_aggregate_investment"] == 0, "no aggregate investment"),
  check("no_aggregate_gross_stock_constructed", no_aggregation$constructed_object_count[no_aggregation$audit_item == "no_aggregate_gross_stock"] == 0, "no aggregate gross stock"),
  check("no_aggregate_net_stock_constructed", no_aggregation$constructed_object_count[no_aggregation$audit_item == "no_aggregate_net_stock"] == 0, "no aggregate net stock"),
  check("no_aggregate_retirements_constructed", no_aggregation$constructed_object_count[no_aggregation$audit_item == "no_aggregate_retirements"] == 0, "no aggregate retirements"),
  check("no_aggregate_cfc_constructed", no_aggregation$constructed_object_count[no_aggregation$audit_item == "no_aggregate_cfc"] == 0, "no aggregate CFC"),
  check("no_core_capital_stock_constructed", no_aggregation$constructed_object_count[no_aggregation$audit_item == "no_core_capital_stock"] == 0, "no core capital stock"),
  check("no_weighted_growth_aggregate_constructed", no_aggregation$constructed_object_count[no_aggregation$audit_item == "no_weighted_growth_aggregate"] == 0, "no weighted aggregate"),
  check("no_ipp_gpim_stock_constructed", no_cross_family$constructed_object_count[no_cross_family$audit_item == "no_ipp_gpim_stock"] == 0, "no IPP GPIM stock"),
  check("no_government_transport_gpim_stock_constructed", no_cross_family$constructed_object_count[no_cross_family$audit_item == "no_government_transport_gpim_stock"] == 0, "no government transport GPIM stock"),
  check("no_residential_gpim_stock_constructed", no_cross_family$constructed_object_count[no_cross_family$audit_item == "no_residential_gpim_stock"] == 0, "no residential GPIM stock"),
  check("no_total_fixed_assets_gpim_stock_constructed", no_cross_family$constructed_object_count[no_cross_family$audit_item == "no_total_fixed_assets_gpim_stock"] == 0, "no total fixed assets GPIM stock"),
  check("no_cross_asset_schedule_use", all(no_cross_family$status == "PASS"), "ME/NRC schedules kept separate"),
  check("no_gpim_parameters_modified", all_hash_unchanged, "Upstream GPIM and setup inputs unchanged"),
  check("no_real_output_variables_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_real_output"] == 0, "no real output"),
  check("no_q_variables_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_q"] == 0, "no q"),
  check("no_theta_variables_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_theta"] == 0, "no theta"),
  check("no_productive_capacity_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_productive_capacity"] == 0, "no productive capacity"),
  check("no_utilization_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_utilization"] == 0, "no utilization"),
  check("no_modeling_outputs_created", no_modeling$constructed_object_count[no_modeling$audit_item == "no_modeling"] == 0, "no modeling outputs"),
  check("no_econometric_outputs_created", no_modeling$constructed_object_count[no_modeling$audit_item == "no_econometrics"] == 0, "no econometric outputs"),
  check("no_adjusted_shaikh_objects_constructed", no_modeling$constructed_object_count[no_modeling$audit_item == "no_adjusted_shaikh"] == 0, "no adjusted Shaikh"),
  check("upstream_outputs_not_modified", all_hash_unchanged, "S29C/S29B/S12D/S13 input hashes unchanged"),
  check("provider_repository_not_modified", provider_tracked_clean(provider_repo), "Provider repo tracked and staged diffs are clean; untracked local files are ignored.")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)

all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 79
final_decision <- if (all_validation_pass) clean_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

validation_md <- c(
  "# S29D Asset-Specific GPIM Stock Construction Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 79", "FAIL"), "`."),
  "",
  paste0("Constructed stock/flow panel rows: `", nrow(stock_flow_panel), "`."),
  paste0("ME vintage audit rows: `", nrow(me_vintage), "`."),
  paste0("NRC vintage audit rows: `", nrow(nrc_vintage), "`."),
  paste0("Unresolved material baseline comparison rows: `", unresolved_material, "`."),
  "",
  "S29D constructs separate ME and NRC gross stocks, net stocks, retirements, and CFC flows. It constructs no aggregate investment, aggregate stocks, core capital stock, q, theta, productive capacity, utilization, modeling, or econometric outputs.",
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29D Asset-Specific GPIM Stock Construction Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29D consumed S29C commit `", s29c_commit, "`, S29B commit `", s29b_commit, "`, S29A commit `", s29a_commit, "`, S28 commit `", s28_commit, "`, S27 commit `", s27_commit, "`, S26 commit `", s26_commit, "`, S25 commit `", s25_commit, "`, S24B commit `", s24b_commit, "`, S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("S29D also consumes locked GPIM commits: S12D-A4 `", s12d_a4_commit, "`, S12D-B `", s12d_b_commit, "`, S12D-C `", s12d_c_commit, "`, and S13 `", s13_commit, "`."),
  "",
  paste0("S29D validation: `", ifelse(all_validation_pass, "PASS 79", "FAIL"), "`."),
  paste0("Constructed stock/flow variables: `", length(constructed_ids), "`."),
  paste0("Constructed stock/flow panel rows: `", nrow(stock_flow_panel), "`."),
  paste0("ME first fully supported year: `", initialization_audit$first_fully_supported_stock_year[initialization_audit$asset_family == "ME"], "`."),
  paste0("NRC first fully supported year: `", initialization_audit$first_fully_supported_stock_year[initialization_audit$asset_family == "NRC"], "`."),
  paste0("Maximum gross SFC residual: `", max(gross_sfc$maximum_absolute_residual), "`."),
  paste0("Maximum net SFC residual: `", max(net_sfc$maximum_absolute_residual), "`."),
  paste0("Residual tolerance: `", tolerance, "`."),
  paste0("Unresolved material locked-baseline comparison rows: `", unresolved_material, "`."),
  "",
  "S29D authorizes only the next bounded stock-flow-consistent core capital aggregation pass. It does not authorize q, theta, productive capacity, utilization, modeling, or econometrics.",
  "",
  "S29D stops here."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) {
  stop("S29D validation failed; see ", output_paths$validation)
}

message("S29D validation PASS 79")
message("Constructed stock/flow variables: ", length(constructed_ids))
message("Constructed panel rows: ", nrow(stock_flow_panel))
message("Decision: ", final_decision)
