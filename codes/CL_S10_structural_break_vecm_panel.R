#!/usr/bin/env Rscript

# S10: canonical capital-only source panel for the Chile structural-break VECM report.

source("C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_SBVECM_common.R")

raw_file <- sbvecm_dir("data", "raw", "Chile", "ch2_raw_panel_chile.csv")
data_out <- sbvecm_dir("data", "processed", "CL", "SBVECM")
out_dir <- sbvecm_dir("output", "CL", "SBVECM", "S10_SOURCE_PANEL")
sbvecm_ensure_dir(data_out)
sbvecm_ensure_dir(out_dir)

raw <- read.csv(raw_file, stringsAsFactors = FALSE, check.names = FALSE)
required <- c("year", "K_ME", "K_NR")
if (!all(required %in% names(raw))) {
  stop("Canonical Chile raw panel is missing required columns: ",
       paste(setdiff(required, names(raw)), collapse = ", "))
}

panel <- raw[
  raw$year >= 1920 & raw$year <= 2024 &
    is.finite(raw$K_ME) & is.finite(raw$K_NR),
  required
]
panel <- panel[order(panel$year), ]
if (nrow(panel) != 105L || !identical(as.integer(panel$year), 1920:2024)) {
  stop("Capital panel failed the locked 105-observation 1920-2024 coverage gate.")
}
if (any(panel$K_ME <= 0) || any(panel$K_NR <= 0)) {
  stop("Capital stocks must be strictly positive before log transformation.")
}

panel$k_ME <- log(panel$K_ME)
panel$k_NR <- log(panel$K_NR)
panel$kappa <- panel$k_ME - panel$k_NR
panel$d_k_ME <- c(NA_real_, diff(panel$k_ME))
panel$d_k_NR <- c(NA_real_, diff(panel$k_NR))
panel$d_kappa <- c(NA_real_, diff(panel$kappa))
panel$source_sha256 <- sbvecm_sha256(raw_file)
panel$source_file <- "data/raw/Chile/ch2_raw_panel_chile.csv"

identity_error <- max(abs(panel$kappa - (panel$k_ME - panel$k_NR)))
capital_rank <- qr(as.matrix(panel[c("k_NR", "k_ME", "kappa")]))$rank
if (identity_error > 1e-12 || capital_rank != 2L) {
  stop("Capital identity or exact-singularity gate failed.")
}

write.csv(panel, file.path(data_out, "cl_capital_1920_2024.csv"), row.names = FALSE)
saveRDS(panel, file.path(data_out, "cl_capital_1920_2024.rds"))

provenance <- data.frame(
  source_file = normalizePath(raw_file, winslash = "/", mustWork = TRUE),
  sha256 = sbvecm_sha256(raw_file),
  retrieval_scope = "repository canonical raw panel",
  observations = nrow(panel),
  first_year = min(panel$year),
  last_year = max(panel$year),
  price_basis = "2003 CLP, inherited from K-Stock-Harmonization",
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
write.csv(provenance, file.path(out_dir, "capital_source_provenance.csv"),
          row.names = FALSE)

checks <- data.frame(
  check = c(
    "canonical_observation_count",
    "year_sequence_complete",
    "positive_capital_levels",
    "kappa_identity",
    "trivariate_rank_is_two",
    "wbop_columns_absent",
    "bcch_columns_absent"
  ),
  value = c(
    nrow(panel),
    identical(as.integer(panel$year), 1920:2024),
    all(panel$K_ME > 0 & panel$K_NR > 0),
    identity_error,
    capital_rank,
    !any(grepl("wbop|current.account|foreign", names(panel), ignore.case = TRUE)),
    !any(grepl("bcch", names(panel), ignore.case = TRUE))
  ),
  pass = c(
    nrow(panel) == 105L,
    identical(as.integer(panel$year), 1920:2024),
    all(panel$K_ME > 0 & panel$K_NR > 0),
    identity_error <= 1e-12,
    capital_rank == 2L,
    TRUE,
    TRUE
  ),
  stringsAsFactors = FALSE
)
write.csv(checks, file.path(out_dir, "capital_panel_validation.csv"), row.names = FALSE)
if (!all(checks$pass)) stop("One or more S10 capital-panel validation checks failed.")

message("S10 complete: canonical 105-observation Chile capital panel created.")
