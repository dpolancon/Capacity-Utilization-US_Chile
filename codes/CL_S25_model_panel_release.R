#!/usr/bin/env Rscript

# CL_BOP_BINDING S25: freeze the sole model/report data release.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(digest)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
s10_file <- file.path(root, "data", "processed", "CL_BOP_BINDING",
                      "S10_SOURCE_PANEL", "chile_bop_source_panel_wide.csv")
s20_file <- file.path(root, "data", "processed", "CL_BOP_BINDING",
                      "S20_RER_SPLICE", "rer_spliced_2003base.csv")
s20_validation <- file.path(root, "data", "processed", "CL_BOP_BINDING",
                            "S20_RER_SPLICE", "rer_splice_validation.csv")
processed_dir <- file.path(root, "data", "processed", "CL_BOP_BINDING",
                           "S25_MODEL_PANEL")
release_dir <- file.path(root, "data", "releases",
                         "chile_bop_binding_v1")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(release_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(s10_file), file.exists(s20_file),
          all(read.csv(s20_validation)$passed))

s10 <- read.csv(s10_file, check.names = FALSE)
rer <- read.csv(s20_file, check.names = FALSE)
panel <- s10 |>
  select(-any_of(c(
    "RER_bcch_1986_annual_preliminary", "RER_bcch_months"
  ))) |>
  left_join(
    rer |>
      select(year, RER_cliolab_2003, RER_bcch_1986,
             RER_bcch_2003, RER_spliced_2003base,
             RER_source, log_RER, dlog_RER),
    by = c("year", "RER_cliolab_2003")
  ) |>
  mutate(
    period = ifelse(year <= 1973, "1920-1973", "1974-2024"),
    post_1974 = as.integer(year >= 1974)
  ) |>
  arrange(year)

model_required <- c(
  "log_imports", "log_K_ME_gross",
  "log_non_reinvested_surplus", "wage_share", "log_RER"
)
stopifnot(
  identical(panel$year, 1920:2024),
  all(complete.cases(panel[, model_required])),
  all(panel$RER_spliced_2003base > 0),
  all(panel$non_reinvested_surplus_2003_CLP > 0)
)

pre <- panel |> filter(year >= 1920, year <= 1973)
post <- panel |> filter(year >= 1974, year <= 2024)
stopifnot(nrow(pre) == 54L, nrow(post) == 51L)
write.csv(pre, file.path(processed_dir, "model_panel_pre1973.csv"),
          row.names = FALSE, na = "")
write.csv(post, file.path(processed_dir, "model_panel_post1974.csv"),
          row.names = FALSE, na = "")

dictionary <- tibble::tribble(
  ~variable, ~label, ~unit, ~base, ~transformation, ~model_role, ~source,
  "year", "Calendar year", "year", "not applicable", "none", "index", "all sources",
  "imports_CIF_real_2003_CLP", "Real CIF imports", "million CLP", "2003 prices", "level", "source field", "Perez-Eyzaguirre",
  "log_imports", "Log real CIF imports", "log million CLP", "2003 prices", "natural log", "VECM state", "constructed",
  "K_ME_gross_2003_CLP", "Gross machinery and equipment capital", "million CLP", "2003 prices", "level", "source field", "K-Stock-Harmonization",
  "log_K_ME_gross", "Log gross machinery and equipment capital", "log million CLP", "2003 prices", "natural log", "VECM state", "constructed",
  "non_reinvested_surplus_2003_CLP", "Non-reinvested surplus", "million CLP", "2003 prices", "profit share times GDP minus total investment", "source-derived identity", "constructed",
  "log_non_reinvested_surplus", "Log non-reinvested surplus", "log million CLP", "2003 prices", "natural log", "VECM state", "constructed",
  "wage_share", "Wage share", "ratio", "base-year-free", "none", "state or stationary control after gate", "distr_19202024",
  "profit_share", "Profit share", "ratio", "base-year-free", "none", "NRS construction", "distr_19202024",
  "RER_spliced_2003base", "Spliced real exchange-rate index", "index", "ClioLab 2003 scale", "ClioLab through 2010; rebased BCCh from 2011", "threshold and control", "ClioLab and BCCh",
  "log_RER", "Log spliced real exchange rate", "log index", "ClioLab 2003 scale", "natural log", "state or stationary control after gate", "constructed",
  "dlog_RER", "Annual real depreciation", "log change", "base-year-free", "first difference of log RER", "threshold robustness", "constructed",
  "import_propensity", "Import propensity", "ratio", "base-year-free", "real imports divided by real GDP", "descriptive only", "constructed",
  "current_account_gdp", "Current-account balance", "share of GDP", "base-year-free", "none", "BOP triangulation", "WBOP",
  "manufactures_imports_gdp", "Manufactured imports", "share of GDP", "base-year-free", "none", "BOP triangulation", "WBOP",
  "financing_compression_5pp", "Financing-compression event", "binary", "base-year-free", "current-account improvement of at least 5 percentage points", "BOP triangulation", "constructed from WBOP"
)
write.csv(dictionary,
          file.path(processed_dir, "model_panel_variable_dictionary.csv"),
          row.names = FALSE, na = "")

wide_release <- file.path(release_dir,
  "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv")
long_release <- file.path(release_dir,
  "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_LONG.csv")
dict_release <- file.path(release_dir,
  "CHILE_BOP_BINDING_VARIABLE_DICTIONARY.csv")
prov_release <- file.path(release_dir,
  "CHILE_BOP_BINDING_PROVENANCE_LEDGER.csv")
write.csv(panel, wide_release, row.names = FALSE, na = "")
panel |>
  mutate(across(-year, as.character)) |>
  pivot_longer(-year, names_to = "variable", values_to = "value") |>
  write.csv(long_release, row.names = FALSE, na = "")
write.csv(dictionary, dict_release, row.names = FALSE, na = "")

upstream_files <- c(
  s10_file, s20_file, s20_validation,
  file.path(root, "data", "raw", "Chile", "BCCh_TCR",
            "bcch_tcr_query_manifest.csv"),
  file.path(root, "output", "CL", "BOP_BINDING",
            "S10_SOURCE_AUDIT", "source_file_provenance_sha256.csv")
)
provenance <- tibble(
  upstream_object = normalizePath(upstream_files, winslash = "/", mustWork = TRUE),
  sha256 = vapply(upstream_files, digest, character(1),
                  algo = "sha256", file = TRUE),
  consumed_by = "CL_S25_model_panel_release.R",
  release_version = "chile_bop_binding_v1"
)
write.csv(provenance, prov_release, row.names = FALSE)

validation_lines <- c(
  "# Chile BOP Binding v1 — Validation Summary",
  "",
  "Release status: **PASS**",
  "",
  "- Annual coverage is complete from 1920 through 2024 (105 observations).",
  "- The split panels contain 1920–1973 (54 observations) and 1974–2024 (51 observations).",
  "- GDP, imports, investment, NRS, and gross machinery capital are expressed in 2003 CLP.",
  "- The ClioLab RER uses the 2003 scale; BCCh observations are rebased to that scale.",
  "- All required model variables are finite and NRS is positive throughout.",
  "- Shares and ratios are explicitly marked base-year-free.",
  "- Downstream estimation must read this release, not live source files."
)
validation_md <- file.path(release_dir,
  "CHILE_BOP_BINDING_VALIDATION_SUMMARY.md")
writeLines(validation_lines, validation_md, useBytes = TRUE)

readme <- c(
  "# Chile BOP Binding Data Release v1",
  "",
  "This is the frozen modelling and report input for the CL_BOP_BINDING branch.",
  "It joins audited Chile macroeconomic, distributional, gross-capital, RER, and WBOP series.",
  "",
  "The wide file is the sole input to S30–S99. The long file is supplied for audit and visualization.",
  "No credentials are included. See the provenance and SHA-256 manifests for reproducibility."
)
writeLines(readme, file.path(release_dir, "README.md"), useBytes = TRUE)

release_files_pre_manifest <- c(
  file.path(release_dir, "README.md"),
  wide_release, long_release, dict_release, prov_release, validation_md
)
manifest <- tibble(
  file = basename(release_files_pre_manifest),
  role = c("release documentation", "sole wide model input",
           "long audit input", "variable dictionary",
           "upstream provenance", "validation summary"),
  bytes = file.info(release_files_pre_manifest)$size,
  rows = c(
    NA_integer_, nrow(panel), nrow(panel) * (ncol(panel) - 1L),
    nrow(dictionary), nrow(provenance), NA_integer_
  )
)
manifest_file <- file.path(release_dir,
  "CHILE_BOP_BINDING_RELEASE_MANIFEST.csv")
write.csv(manifest, manifest_file, row.names = FALSE, na = "")

sha_files <- c(release_files_pre_manifest, manifest_file)
sha_manifest <- tibble(
  file = basename(sha_files),
  sha256 = vapply(sha_files, digest, character(1),
                  algo = "sha256", file = TRUE)
)
write.csv(sha_manifest,
          file.path(release_dir,
                    "CHILE_BOP_BINDING_SHA256_MANIFEST.csv"),
          row.names = FALSE)

message("CL_BOP_BINDING S25 complete: frozen release v1 written.")
