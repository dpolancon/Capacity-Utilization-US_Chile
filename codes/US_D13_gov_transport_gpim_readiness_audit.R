#!/usr/bin/env Rscript

# US_D13_gov_transport_gpim_readiness_audit.R
#
# Readiness audit gating the D14 government-transportation GPIM gross-stock
# build (S41 diagnostic branch). Verifies:
#
#   1. FAAt705 gross-investment coverage for the two GOV_TRANS lines
#      (HIGHWAYS_STREETS, TRANSPORTATION_STRUCTURES).
#   2. Implicit-deflator feasibility: FAAt701 current-cost net stock and
#      FAAt702 quantity index both present for the same lines.
#   3. Promotion of the D01 metadata-only Weibull parameters
#      (L = 60, alpha = 1.3) into an authorized parameter table for D14.
#      Doctrinal basis: Appendix-Retirement-Distribution.md (Fraumeni life,
#      Nomura shape; Japanese road T-bar ruled not applicable to US).
#   4. Warm-up ratio ledger per D09-S thresholds
#      (warmup/L >= 1.25 LOW, >= 0.75 MEDIUM, else HIGH).
#
# Read-only with respect to all upstream artifacts. Outputs land in the
# isolated S41 diagnostic directory. Nothing here modifies D06/D07/D10
# frozen outputs or the D06 exclusion ledger; per that ledger, government
# transportation remains excluded from baseline K_capacity — this branch is
# DIAGNOSTIC_ONLY.
#
# Gate: all structural checks must PASS for D14 to run. A HIGH warm-up
# verdict does not halt the pipeline but mandates the D14 initialization
# sensitivity and report disclosure (V02_GPIM_Constitution.md Sec. 12).

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
menu_csv  <- file.path(repo_root, "data", "external", "us_bea_provider",
                       "us_bea_variable_menu_long.csv")
d01_sched <- file.path(repo_root, "output", "US",
                       "D01_GPIM_GROSS_SURVIVAL_REMEDIATION",
                       "D01_survival_schedule_table.csv")
audit_dir <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "audit")
dir.create(audit_dir, recursive = TRUE, showWarnings = FALSE)

diagnostic_stamp <- "DIAGNOSTIC_ONLY;NOT_D06_BASELINE;S41_BRANCH"

cat("========================================================================\n")
cat("D13: Government transportation GPIM readiness audit (S41 branch)\n")
cat("========================================================================\n")

## ==========================================================
## STEP 1: Load BEA menu and locate the GOV_TRANS series
## ==========================================================

menu <- read.csv(menu_csv, stringsAsFactors = FALSE)

gt_lines <- c("HIGHWAYS_STREETS", "TRANSPORTATION_STRUCTURES")
gt_types <- c(
  gross_investment = "gross_investment_current_cost",
  net_stock_cc     = "net_stock_current_cost",
  quantity_index   = "net_stock_quantity_index"
)

required_ids <- as.vector(outer(
  paste0("GOV_TRANS__", gt_lines, "__"), gt_types, paste0))

coverage_rows <- list()
checks <- list()
add_check <- function(check_id, passed, detail) {
  checks[[length(checks) + 1]] <<- data.frame(
    check_id = check_id,
    status = ifelse(passed, "PASS", "FAIL"),
    detail = detail,
    stamp = diagnostic_stamp
  )
}

for (line in gt_lines) {
  for (tname in names(gt_types)) {
    vid <- paste0("GOV_TRANS__", line, "__", gt_types[[tname]])
    sub <- menu[menu$variable_id == vid, ]
    present <- nrow(sub) > 0
    yr_min <- if (present) min(sub$year) else NA_integer_
    yr_max <- if (present) max(sub$year) else NA_integer_
    n_obs  <- nrow(sub)
    gap_free <- present && identical(sort(sub$year), seq(yr_min, yr_max))
    bea_table <- if (present) unique(sub$bea_table) else NA_character_

    coverage_rows[[vid]] <- data.frame(
      variable_id = vid, line = line, series_type = tname,
      bea_table = paste(bea_table, collapse = ";"),
      year_min = yr_min, year_max = yr_max, n_obs = n_obs,
      gap_free = gap_free, stamp = diagnostic_stamp
    )

    add_check(
      paste0("SERIES_PRESENT__", vid), present,
      sprintf("%d rows in menu", n_obs))
    if (present) {
      add_check(
        paste0("SERIES_GAP_FREE__", vid), gap_free,
        sprintf("coverage %d-%d", yr_min, yr_max))
    }
  }
}

coverage <- do.call(rbind, coverage_rows)
rownames(coverage) <- NULL

## Expected BEA table assignments
inv_tables <- coverage$bea_table[coverage$series_type == "gross_investment"]
add_check("INVESTMENT_FROM_FAAt705", all(inv_tables == "FAAt705"),
          paste(unique(inv_tables), collapse = ";"))
ns_tables <- coverage$bea_table[coverage$series_type == "net_stock_cc"]
add_check("NET_STOCK_FROM_FAAt701", all(ns_tables == "FAAt701"),
          paste(unique(ns_tables), collapse = ";"))
qi_tables <- coverage$bea_table[coverage$series_type == "quantity_index"]
add_check("QUANTITY_INDEX_FROM_FAAt702", all(qi_tables == "FAAt702"),
          paste(unique(qi_tables), collapse = ";"))

## ==========================================================
## STEP 2: Implicit-deflator feasibility
## ==========================================================

# p_GT (per line) = current-cost net stock / rebased quantity index.
# Feasible on the intersection of FAAt701 and FAAt702 coverage. Investment
# years before that window require backward extrapolation in D14 (disclosed).

defl_rows <- list()
for (line in gt_lines) {
  cc <- coverage[coverage$line == line & coverage$series_type == "net_stock_cc", ]
  qi <- coverage[coverage$line == line & coverage$series_type == "quantity_index", ]
  gi <- coverage[coverage$line == line & coverage$series_type == "gross_investment", ]
  defl_start <- max(cc$year_min, qi$year_min)
  defl_end   <- min(cc$year_max, qi$year_max)
  backcast_years <- max(0, defl_start - gi$year_min)
  defl_rows[[line]] <- data.frame(
    line = line, deflator_start = defl_start, deflator_end = defl_end,
    investment_start = gi$year_min,
    backcast_years_required = backcast_years,
    backcast_method_d14 = "log_linear_backward_extrapolation_1925_1950_mean_growth",
    backcast_sensitivity_d14 = "flat_hold_at_first_observed_price",
    stamp = diagnostic_stamp
  )
  add_check(
    paste0("DEFLATOR_FEASIBLE__", line),
    is.finite(defl_start) && is.finite(defl_end) && defl_end > defl_start,
    sprintf("implicit p_GT available %d-%d; %d backcast years for investment",
            defl_start, defl_end, backcast_years))
}
deflator_feasibility <- do.call(rbind, defl_rows)
rownames(deflator_feasibility) <- NULL

## ==========================================================
## STEP 3: Promote D01 metadata Weibull parameters
## ==========================================================

sched <- read.csv(d01_sched, stringsAsFactors = FALSE)
gov <- sched[sched$asset_family == "GOV_TRANSPORT_METADATA_ONLY", ]

param_ok <- nrow(gov) > 0 &&
  all(gov$mean_life_years == 60) &&
  all(gov$weibull_alpha == 1.3) &&
  all(gov$metadata_only == TRUE | gov$metadata_only == "TRUE")

L_gov      <- 60
alpha_gov  <- 1.3
lambda_gov <- L_gov / gamma(1 + 1 / alpha_gov)

lambda_match <- param_ok &&
  abs(unique(gov$weibull_lambda)[1] - lambda_gov) < 1e-9

add_check("D01_METADATA_ROW_PRESENT", nrow(gov) > 0,
          sprintf("%d schedule rows found", nrow(gov)))
add_check("D01_PARAMETERS_MATCH_LOCK", param_ok,
          "L=60, alpha=1.3, metadata_only=TRUE")
add_check("LAMBDA_RECOMPUTATION_MATCH", lambda_match,
          sprintf("lambda = L/Gamma(1+1/alpha) = %.10f", lambda_gov))

parameters <- data.frame(
  asset_family = "GOV_TRANSPORT",
  promoted_from = "D01_survival_schedule_table.csv:GOV_TRANSPORT_METADATA_ONLY",
  mean_life_years = L_gov,
  weibull_alpha = alpha_gov,
  weibull_lambda = lambda_gov,
  life_source = "Fraumeni (highways & streets T=60)",
  shape_source = "Nomura (2005) alpha ~= 1.3",
  triangulation_note = paste(
    "Appendix-Retirement-Distribution.md: Nomura Japanese road T-bar=19.8y",
    "ruled NOT applicable to US (AASHTO 20-50y pavements, FHWA 75y+ bridges);",
    "retain Fraumeni L=60 with Nomura shape alpha~=1.3."),
  authorized_use = "D14_gov_transport_gpim_gross_stock_build_diagnostic_only",
  prohibited_use = "baseline_capacity_component_per_D06_exclusion_ledger",
  stamp = diagnostic_stamp
)

## ==========================================================
## STEP 4: Warm-up ratio ledger (D09-S thresholds)
## ==========================================================

warmup_verdict <- function(ratio) {
  if (ratio >= 1.25) "LOW" else if (ratio >= 0.75) "MEDIUM" else "HIGH"
}

inv_start <- min(coverage$year_min[coverage$series_type == "gross_investment"])
analysis_starts <- c(estimation_window_start = 1929L,
                     d06_analysis_convention = 1947L)

warmup_rows <- lapply(names(analysis_starts), function(nm) {
  ys <- analysis_starts[[nm]]
  warmup <- ys - inv_start
  ratio <- warmup / L_gov
  data.frame(
    analysis_start_label = nm, analysis_start_year = ys,
    investment_start_year = inv_start, warmup_years = warmup,
    mean_life_years = L_gov, warmup_ratio = round(ratio, 4),
    risk_verdict = warmup_verdict(ratio),
    constitution_requirement = ifelse(
      warmup_verdict(ratio) == "LOW", "none",
      "initialization_sensitivity_mandatory_V02_sec12"),
    stamp = diagnostic_stamp
  )
})
warmup_ledger <- do.call(rbind, warmup_rows)

# Warm-up is a disclosure, not a structural gate.
add_check("WARMUP_LEDGER_COMPUTED", TRUE,
          paste(sprintf("%s: ratio=%.2f (%s)",
                        warmup_ledger$analysis_start_label,
                        warmup_ledger$warmup_ratio,
                        warmup_ledger$risk_verdict), collapse = "; "))

## ==========================================================
## STEP 5: Write outputs and gate verdict
## ==========================================================

checks_df <- do.call(rbind, checks)

write.csv(coverage,
  file.path(audit_dir, "D13_gov_transport_gpim_readiness_coverage.csv"),
  row.names = FALSE)
write.csv(deflator_feasibility,
  file.path(audit_dir, "D13_gov_transport_deflator_feasibility.csv"),
  row.names = FALSE)
write.csv(parameters,
  file.path(audit_dir, "D13_gov_transport_gpim_readiness_parameters.csv"),
  row.names = FALSE)
write.csv(warmup_ledger,
  file.path(audit_dir, "D13_gov_transport_warmup_ledger.csv"),
  row.names = FALSE)
write.csv(checks_df,
  file.path(audit_dir, "D13_gov_transport_gpim_readiness_checks.csv"),
  row.names = FALSE)

n_fail <- sum(checks_df$status == "FAIL")
cat(sprintf("\nChecks: %d total, %d FAIL\n", nrow(checks_df), n_fail))
print(checks_df[, c("check_id", "status", "detail")], row.names = FALSE)
cat("\nWarm-up ledger:\n")
print(warmup_ledger[, c("analysis_start_label", "warmup_years",
                        "warmup_ratio", "risk_verdict")], row.names = FALSE)

if (n_fail == 0) {
  cat("\nGATE: AUTHORIZE_D14_GOV_TRANSPORT_GPIM_GROSS_STOCK_BUILD\n")
} else {
  cat("\nGATE: BLOCKED — structural checks failed; D14 must not run.\n")
  quit(status = 1)
}
