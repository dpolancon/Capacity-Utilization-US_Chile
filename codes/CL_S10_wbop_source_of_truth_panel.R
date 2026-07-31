#!/usr/bin/env Rscript

# Chile Stage S10 — canonical historical WBOP external-sector panel.
# This script never constructs phi, F_avail, or capacity utilization.

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(digest)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
raw_chile <- file.path(root, "data", "raw", "Chile")
wbop_file <- file.path(raw_chile, "WBOP", "NievasPiketty2025WBOPFinalSeries.xlsx")
processed_dir <- file.path(root, "data", "processed", "CL", "S10_SOURCE_PANEL")
output_dir <- file.path(root, "output", "CL", "S10_SOURCE_PANEL")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

stopifnot(file.exists(wbop_file))

wbop_map <- tibble::tribble(
  ~sheet, ~variable, ~label,
  "B1a", "goods_balance_gdp", "Goods balance (% GDP)",
  "B1b", "goods_exports_gdp", "Goods exports (% GDP)",
  "B1c", "goods_imports_gdp", "Goods imports (% GDP)",
  "B2a", "primary_goods_balance_gdp", "Primary-goods balance (% GDP)",
  "B2b", "primary_goods_exports_gdp", "Primary-goods exports (% GDP)",
  "B2c", "primary_goods_imports_gdp", "Primary-goods imports (% GDP)",
  "B3a", "manufactures_balance_gdp", "Manufactured-goods balance (% GDP)",
  "B3b", "manufactures_exports_gdp", "Manufactured-goods exports (% GDP)",
  "B3c", "manufactures_imports_gdp", "Manufactured-goods imports (% GDP)",
  "C1d", "goods_services_balance_gdp", "Goods and services balance (% GDP)",
  "D1a", "net_foreign_income_gdp", "Net foreign income (% GDP)",
  "D1b", "foreign_income_inflows_gdp", "Foreign income inflows (% GDP)",
  "D1c", "foreign_income_outflows_gdp", "Foreign income outflows (% GDP)",
  "E1a", "net_transfers_gdp", "Net transfers (% GDP)",
  "F1", "current_account_gdp", "Current account (% GDP)",
  "G1a", "net_foreign_wealth_gdp", "Net foreign wealth (% GDP)",
  "G1b", "gross_foreign_assets_gdp", "Gross foreign assets (% GDP)",
  "G1c", "gross_foreign_liabilities_gdp", "Gross foreign liabilities (% GDP)"
)

read_wbop_chile <- function(sheet, variable) {
  x <- suppressMessages(read_excel(wbop_file, sheet = sheet, skip = 4,
                                   col_names = FALSE))
  stopifnot(ncol(x) >= 29)
  tibble(
    year = suppressWarnings(as.integer(x[[1]])),
    value = suppressWarnings(as.numeric(x[[29]]))
  ) |>
    filter(year >= 1920, year <= 2024) |>
    rename(!!variable := value)
}

wbop_series <- lapply(seq_len(nrow(wbop_map)), function(i) {
  read_wbop_chile(wbop_map$sheet[i], wbop_map$variable[i])
})
wbop <- Reduce(function(x, y) full_join(x, y, by = "year"), wbop_series) |>
  arrange(year)

capital <- read.csv(file.path(raw_chile, "ch2_raw_panel_chile.csv"),
                    check.names = FALSE) |>
  transmute(
    year = as.integer(year),
    K_ME = as.numeric(K_ME),
    K_NR = as.numeric(K_NR),
    k_me = ifelse(K_ME > 0, log(K_ME), NA_real_),
    k_nr = ifelse(K_NR > 0, log(K_NR), NA_real_),
    kappa = k_me - k_nr,
    GDP_real = as.numeric(GDP_real),
    gdp_growth = 100 * (log(GDP_real) - lag(log(GDP_real))),
    machinery_investment = as.numeric(FBKF_ME),
    structures_investment = as.numeric(FBKF_NR),
    profit_share = as.numeric(pi),
    wage_share = as.numeric(omega)
  ) |>
  filter(year >= 1920, year <= 2024)

annual <- full_join(capital, wbop, by = "year") |>
  arrange(year) |>
  mutate(
    external_financing_proxy_gdp = -current_account_gdp,
    annual_financing_stop_5pp =
      as.integer(external_financing_proxy_gdp - lag(external_financing_proxy_gdp) <= -0.05),
    d_k_me = k_me - lag(k_me),
    d_k_nr = k_nr - lag(k_nr),
    d_kappa = kappa - lag(kappa)
  )

write.csv(annual, file.path(processed_dir, "chile_wbop_capital_annual_1920_2024.csv"),
          row.names = FALSE, na = "")
write.csv(wbop_map, file.path(output_dir, "wbop_variable_dictionary.csv"),
          row.names = FALSE, na = "")

source_files <- wbop_file
provenance <- tibble(
  file = normalizePath(source_files, winslash = "/", mustWork = TRUE),
  bytes = file.info(source_files)$size,
  sha256 = vapply(source_files, digest, character(1), algo = "sha256", file = TRUE),
  retrieved_utc = format(file.info(source_files)$mtime, tz = "UTC",
                         format = "%Y-%m-%dT%H:%M:%SZ"),
  source_url = "https://wbop.world/Data/NievasPiketty2025WBOPFinalSeries.xlsx",
  validation_url = "https://wbop.world/",
  release_scope = "Annual WBOP series; Chile column CL; 1920-2024 extraction"
)
write.csv(provenance, file.path(output_dir, "source_provenance_sha256.csv"),
          row.names = FALSE)

coverage <- bind_rows(lapply(setdiff(names(annual), "year"), function(v) {
  ok <- is.finite(annual[[v]])
  tibble(panel = "annual", variable = v,
         first = ifelse(any(ok), as.character(min(annual$year[ok])), NA_character_),
         last = ifelse(any(ok), as.character(max(annual$year[ok])), NA_character_),
         n = sum(ok))
}))
write.csv(coverage, file.path(output_dir, "source_coverage_audit.csv"),
          row.names = FALSE, na = "")

accounting_audit <- tibble(
  identity = c(
    "goods balance = goods exports - goods imports",
    "manufactures balance = manufactures exports - manufactures imports",
    "current account = goods and services + net foreign income + net transfers",
    "net foreign wealth = gross foreign assets - gross foreign liabilities"
  ),
  maximum_absolute_residual = c(
    max(abs(annual$goods_balance_gdp -
              (annual$goods_exports_gdp - annual$goods_imports_gdp)), na.rm = TRUE),
    max(abs(annual$manufactures_balance_gdp -
              (annual$manufactures_exports_gdp -
                 annual$manufactures_imports_gdp)), na.rm = TRUE),
    max(abs(annual$current_account_gdp -
              (annual$goods_services_balance_gdp +
                 annual$net_foreign_income_gdp +
                 annual$net_transfers_gdp)), na.rm = TRUE),
    max(abs(annual$net_foreign_wealth_gdp -
              (annual$gross_foreign_assets_gdp -
                 annual$gross_foreign_liabilities_gdp)), na.rm = TRUE)
  )
) |>
  mutate(passed = maximum_absolute_residual < 1e-10,
         tolerance = 1e-10,
         note = "Identity check only; this is not a coefficient-comparability gate")
write.csv(accounting_audit, file.path(output_dir, "wbop_accounting_identity_audit.csv"),
          row.names = FALSE)
stopifnot(all(accounting_audit$passed))

message("CL S10 complete: canonical annual WBOP panel written.")
