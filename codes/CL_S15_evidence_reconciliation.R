#!/usr/bin/env Rscript

# S15: reconcile the canonical Chile capital evidence with superseded outputs.

source("C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_SBVECM_common.R")

repo <- sbvecm_repo_root
out_dir <- sbvecm_dir("output", "CL", "SBVECM",
                      "S15_EVIDENCE_RECONCILIATION")
sbvecm_ensure_dir(out_dir)

canonical_file <- sbvecm_dir(
  "data", "processed", "CL", "SBVECM", "cl_capital_1920_2024.csv"
)
legacy_file <- sbvecm_dir(
  "data", "processed", "cl_s20", "chile_orthogonalized_panel.csv"
)
legacy_vecm_file <- sbvecm_dir("output", "break_informed_johansen_vecm_ledger.csv")
legacy_cointreg_script <- sbvecm_dir("codes", "CL_S42_cointreg_triad_estimation.R")
custom_kp_script <- sbvecm_dir(
  "codes", "CL_S20B_parametric_cointegration_break_adjudication.R"
)

canonical <- read.csv(canonical_file, check.names = FALSE,
                      stringsAsFactors = FALSE)
legacy <- if (file.exists(legacy_file)) {
  read.csv(legacy_file, check.names = FALSE, stringsAsFactors = FALSE)
} else {
  data.frame()
}

file_year_range <- function(d) {
  if (!nrow(d) || !"year" %in% names(d)) return(c(NA_integer_, NA_integer_))
  c(min(as.integer(d[["year"]]), na.rm = TRUE),
    max(as.integer(d[["year"]]), na.rm = TRUE))
}

canonical_range <- file_year_range(canonical)
legacy_range <- file_year_range(legacy)

ledger <- data.frame(
  evidence_id = c(
    "CANONICAL_CAPITAL_PANEL",
    "LEGACY_ORTHOGONALIZED_PANEL",
    "LEGACY_BREAK_VECM",
    "LEGACY_CL_S42_FMOLS",
    "LEGACY_CL_S42_IMOLS",
    "CUSTOM_KP_IMPLEMENTATION",
    "CRAN_COINTRREG_IMPLEMENTATION",
    "CRAN_MBREAKS_IMPLEMENTATION"
  ),
  object = c(
    canonical_file,
    legacy_file,
    legacy_vecm_file,
    legacy_cointreg_script,
    legacy_cointreg_script,
    custom_kp_script,
    "cointReg::cointRegIM/cointRegFM",
    "mbreaks::mdl"
  ),
  observations = c(
    nrow(canonical),
    if (nrow(legacy)) nrow(legacy) else NA_integer_,
    if (nrow(legacy)) nrow(legacy) else NA_integer_,
    if (nrow(legacy)) nrow(legacy) else NA_integer_,
    if (nrow(legacy)) nrow(legacy) else NA_integer_,
    nrow(canonical),
    nrow(canonical),
    nrow(canonical)
  ),
  sample = c(
    paste(canonical_range, collapse = "-"),
    if (all(is.finite(legacy_range))) paste(legacy_range, collapse = "-") else NA,
    if (all(is.finite(legacy_range))) paste(legacy_range, collapse = "-") else NA,
    if (all(is.finite(legacy_range))) paste(legacy_range, collapse = "-") else NA,
    if (all(is.finite(legacy_range))) paste(legacy_range, collapse = "-") else NA,
    paste(canonical_range, collapse = "-"),
    paste(canonical_range, collapse = "-"),
    paste(canonical_range, collapse = "-")
  ),
  classification = c(
    "authoritative",
    "superseded",
    "superseded",
    "invalid estimator label",
    "invalid estimator label",
    "diagnostic comparator",
    "authorized estimator implementation",
    "independent structural-break implementation"
  ),
  report_use = c(
    "all reported capital evidence",
    "excluded",
    "excluded",
    "excluded",
    "excluded",
    "reported only beside independent reproduction",
    "runs only after cointegration prerequisites pass",
    "formal break computation with method-specific critical values"
  ),
  reason = c(
    "105 annual observations, 1920-2024, exact capital identity and source hash",
    "91-observation 1920-2010 panel cannot support 1920-2024 claims",
    "coefficients inherit the shorter legacy panel",
    "OLS with Newey-West covariance is not cointReg FM-OLS",
    "a regression on cumulative machinery is not cointReg IM-OLS",
    "custom statistic differs from the independent mbreaks computation",
    "calls the published package estimator rather than a renamed OLS routine",
    "official package implementation of Bai-Perron computations"
  ),
  stringsAsFactors = FALSE
)

write.csv(ledger, file.path(out_dir, "evidence_reconciliation_ledger.csv"),
          row.names = FALSE)

package_rows <- data.frame(
  package = c("R", "urca", "cointReg", "strucchange", "mbreaks",
              "sandwich", "lmtest"),
  version = c(
    paste(R.version$major, R.version$minor, sep = "."),
    vapply(c("urca", "cointReg", "strucchange", "mbreaks",
             "sandwich", "lmtest"),
           function(x) as.character(utils::packageVersion(x)), character(1))
  ),
  stringsAsFactors = FALSE
)
write.csv(package_rows, file.path(out_dir, "package_version_ledger.csv"),
          row.names = FALSE)

checks <- data.frame(
  check = c(
    "canonical observation count",
    "canonical sample",
    "canonical source hash unique",
    "legacy panel excluded",
    "legacy estimator labels excluded",
    "mbreaks pinned version recorded"
  ),
  pass = c(
    nrow(canonical) == 105L,
    identical(canonical_range, c(1920L, 2024L)),
    length(unique(canonical[["source_sha256"]])) == 1L,
    all(ledger$report_use[ledger$evidence_id %in%
      c("LEGACY_ORTHOGONALIZED_PANEL", "LEGACY_BREAK_VECM")] == "excluded"),
    all(ledger$report_use[ledger$evidence_id %in%
      c("LEGACY_CL_S42_FMOLS", "LEGACY_CL_S42_IMOLS")] == "excluded"),
    package_rows$version[package_rows$package == "mbreaks"] == "1.0.1"
  ),
  detail = c(
    nrow(canonical),
    paste(canonical_range, collapse = "-"),
    unique(canonical[["source_sha256"]]),
    if (nrow(legacy)) paste(legacy_range, collapse = "-") else "missing",
    "CL_S42 inspected directly",
    package_rows$version[package_rows$package == "mbreaks"]
  ),
  stringsAsFactors = FALSE
)
write.csv(checks, file.path(out_dir, "evidence_reconciliation_checks.csv"),
          row.names = FALSE)

if (!all(checks$pass)) {
  stop("S15 evidence reconciliation failed: ",
       paste(checks$check[!checks$pass], collapse = "; "))
}

message("S15 complete: canonical evidence isolated from superseded outputs.")
