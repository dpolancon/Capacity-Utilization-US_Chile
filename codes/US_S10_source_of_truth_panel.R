###############################################################################
# US_S10_source_of_truth_panel.R
# Chapter 2 — US source-of-truth panel builder
#
# Role in locked architecture:
#   S10 = source-of-truth data construction.
#
# This script only builds the canonical US panel. It does not estimate the
# transformation relation, reconstruct productive capacity, derive utilization,
# run diagnostics, or export paper-facing figures.
#
# Main output:
#   data/final/US/us_source_of_truth_panel.csv
# Compatibility output:
#   data/processed/US/us_source_of_truth_panel.csv
###############################################################################

# ---- 0. Paths ----------------------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")
BEA  <- Sys.getenv("BEA_REPO", unset = "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset")

raw_kstock_path <- file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv")
bea_income_path <- file.path(BEA,  "data/processed/income_accounts_NF.csv")

out_final_dir     <- file.path(REPO, "data/final/US")
out_processed_dir <- file.path(REPO, "data/processed/US")
out_log_dir       <- file.path(REPO, "artifacts/repo_state_logs/us_s10_source_of_truth")

for (p in c(out_final_dir, out_processed_dir, out_log_dir)) {
  dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

REBASE_YEAR <- as.integer(Sys.getenv("US_REBASE_YEAR", unset = "2024"))

# ---- 1. Helpers --------------------------------------------------------------
require_cols <- function(df, cols, object_name) {
  missing <- setdiff(cols, names(df))
  if (length(missing) > 0L) {
    stop(
      object_name, " is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

coalesce_first_existing <- function(df, candidates) {
  hit <- intersect(candidates, names(df))
  if (length(hit) == 0L) return(rep(NA_real_, nrow(df)))
  df[[hit[1L]]]
}

first_existing_name <- function(df, candidates) {
  hit <- intersect(candidates, names(df))
  if (length(hit) == 0L) return(NA_character_)
  hit[1L]
}

safe_log <- function(x) {
  out <- rep(NA_real_, length(x))
  ok <- is.finite(x) & x > 0
  out[ok] <- log(x[ok])
  out
}

# ---- 2. Load raw inputs ------------------------------------------------------
if (!file.exists(raw_kstock_path)) {
  stop("Missing US raw k-stock file: ", raw_kstock_path, call. = FALSE)
}
if (!file.exists(bea_income_path)) {
  stop("Missing BEA income file: ", bea_income_path, call. = FALSE)
}

d_raw  <- read.csv(raw_kstock_path, stringsAsFactors = FALSE)
nf_inc <- read.csv(bea_income_path, stringsAsFactors = FALSE)

require_cols(d_raw,  c("year", "GVA_NF", "KGC_NF", "pK_NF", "Wsh_NF"), "US raw k-stock/distribution data")
require_cols(nf_inc, c("year", "Py_fred"), "BEA income data")

# ---- 3. Merge and rebase -----------------------------------------------------
d <- merge(d_raw, nf_inc[, c("year", "Py_fred")], by = "year", all = FALSE)
d <- d[order(d$year), ]

Py_base <- d$Py_fred[d$year == REBASE_YEAR]
pK_base <- d$pK_NF[d$year == REBASE_YEAR]

if (length(Py_base) != 1L || length(pK_base) != 1L) {
  stop(
    "Could not uniquely identify rebase-year values for Py_fred and pK_NF. ",
    "Check REBASE_YEAR = ", REBASE_YEAR,
    call. = FALSE
  )
}

# ---- 4. Canonical transformations ------------------------------------------
# These names standardize repeated blocks from the DOLS-era scripts.
d$Y_real       <- d$GVA_NF / (d$Py_fred / Py_base)
d$K_total_real <- d$KGC_NF / (d$pK_NF / pK_base)

d$y_t       <- safe_log(d$Y_real)
d$k_t       <- safe_log(d$K_total_real)
d$omega_t   <- d$Wsh_NF
d$omega_k_t <- d$omega_t * d$k_t

# Retain old script-compatible names, but mark them as aliases.
d$K_real <- d$K_total_real

# ---- 5. Optional composition placeholders -----------------------------------
# The updated analytical architecture requires composition variables whenever
# machinery/non-machinery stocks are available. The old US DOLS batch does not
# establish a clean machinery split. This S10 script therefore creates explicit
# placeholders and records whether composition is available.

machinery_stock_candidates <- c(
  "K_machinery_real", "KM_real", "KME_real", "K_equipment_real",
  "KGC_M_NF", "KGC_equipment_NF", "K_machinery_NF"
)
other_stock_candidates <- c(
  "K_other_real", "KO_real", "K_structures_real", "K_infrastructure_real",
  "KGC_O_NF", "KGC_structures_NF", "K_other_NF"
)

machinery_col <- first_existing_name(d, machinery_stock_candidates)
other_col     <- first_existing_name(d, other_stock_candidates)

if (!is.na(machinery_col)) {
  d$K_machinery_real <- d[[machinery_col]]
} else {
  d$K_machinery_real <- NA_real_
}

if (!is.na(other_col)) {
  d$K_other_real <- d[[other_col]]
} else {
  d$K_other_real <- NA_real_
}

if (!all(is.na(d$K_machinery_real)) && all(is.finite(d$K_total_real))) {
  d$s_t <- d$K_machinery_real / d$K_total_real
} else {
  d$s_t <- NA_real_
}

# Machinery share of investment is not available in the DOLS-era US inputs.
# Keep placeholders so downstream S20 scripts have a stable contract.
d$I_total <- coalesce_first_existing(d, c("I_total", "IGC_NF", "IGR_NF"))
d$I_machinery <- coalesce_first_existing(d, c("I_machinery", "IM_NF", "I_equipment_NF"))

if (!all(is.na(d$I_machinery)) && !all(is.na(d$I_total))) {
  d$phi_t <- d$I_machinery / d$I_total
} else {
  d$phi_t <- NA_real_
}

# US is the center benchmark. External mechanization pressure is not central here.
d$external_pressure_t <- NA_real_
d$D_external_high <- NA_real_

# ---- 6. Profitability aliases if available ----------------------------------
# Keep pass-through variables used by downstream US profitability scripts.
alias_map <- list(
  GVA = c("GVA", "GVA_NF"),
  EC  = c("EC", "EC_NF"),
  GOS = c("GOS", "GOS_NF"),
  KNC = c("KNC", "KNC_NF"),
  KNR = c("KNR", "KNR_NF"),
  KGC = c("KGC", "KGC_NF"),
  KGR = c("KGR", "KGR_NF"),
  IGC = c("IGC", "IGC_NF"),
  pY  = c("pY", "Py", "Py_fred"),
  pK  = c("pK", "pK_NF"),
  GVA_real = c("GVA_real", "Y_real")
)

for (nm in names(alias_map)) {
  if (!nm %in% names(d)) {
    d[[nm]] <- coalesce_first_existing(d, alias_map[[nm]])
  }
}

# ---- 7. Output panel ---------------------------------------------------------
priority_cols <- c(
  "year",
  "Y_real", "K_total_real", "K_real", "y_t", "k_t",
  "omega_t", "omega_k_t",
  "K_machinery_real", "K_other_real", "s_t",
  "I_total", "I_machinery", "phi_t",
  "external_pressure_t", "D_external_high",
  "GVA", "EC", "GOS", "KNC", "KNR", "KGC", "KGR", "IGC", "pY", "pK", "GVA_real",
  "GVA_NF", "KGC_NF", "pK_NF", "Wsh_NF", "Py_fred"
)

priority_cols <- intersect(priority_cols, names(d))
other_cols <- setdiff(names(d), priority_cols)
panel <- d[, c(priority_cols, other_cols), drop = FALSE]

final_path     <- file.path(out_final_dir, "us_source_of_truth_panel.csv")
processed_path <- file.path(out_processed_dir, "us_source_of_truth_panel.csv")

write.csv(panel, final_path, row.names = FALSE)
write.csv(panel, processed_path, row.names = FALSE)

# ---- 8. Metadata -------------------------------------------------------------
meta <- c(
  "# US S10 source-of-truth panel",
  "",
  paste0("Created by: codes/US_S10_source_of_truth_panel.R"),
  paste0("Rebase year: ", REBASE_YEAR),
  paste0("Input raw k-stock/distribution file: ", raw_kstock_path),
  paste0("Input BEA income file: ", bea_income_path),
  paste0("Output final panel: ", final_path),
  paste0("Output processed compatibility panel: ", processed_path),
  "",
  "## Span",
  paste0("- First year: ", min(panel$year, na.rm = TRUE)),
  paste0("- Last year: ", max(panel$year, na.rm = TRUE)),
  paste0("- Observations: ", nrow(panel)),
  "",
  "## Composition availability",
  paste0("- Machinery stock column detected: ", ifelse(is.na(machinery_col), "none", machinery_col)),
  paste0("- Other stock column detected: ", ifelse(is.na(other_col), "none", other_col)),
  paste0("- s_t available: ", any(is.finite(panel$s_t))),
  paste0("- phi_t available: ", any(is.finite(panel$phi_t))),
  "",
  "## Contract",
  "S10 only constructs the canonical panel. It does not estimate theta, reconstruct productive capacity, derive utilization, or export paper-facing results."
)

writeLines(meta, file.path(out_log_dir, "US_S10_source_of_truth_panel_README.md"))
writeLines(capture.output(sessionInfo()), file.path(out_log_dir, "sessionInfo_US_S10.txt"))

cat("US S10 source-of-truth panel written:\n")
cat("  ", final_path, "\n", sep = "")
cat("  ", processed_path, "\n", sep = "")
cat("Metadata written:\n")
cat("  ", file.path(out_log_dir, "US_S10_source_of_truth_panel_README.md"), "\n", sep = "")
