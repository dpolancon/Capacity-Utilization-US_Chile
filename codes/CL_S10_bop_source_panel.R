#!/usr/bin/env Rscript

# CL_BOP_BINDING S10: assemble source fields and derived import-surplus fields.

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(digest)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
raw_cl <- file.path(root, "data", "raw", "Chile")
processed_dir <- file.path(root, "data", "processed", "CL_BOP_BINDING",
                           "S10_SOURCE_PANEL")
output_dir <- file.path(root, "output", "CL", "BOP_BINDING",
                        "S10_SOURCE_AUDIT")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

perez_file <- file.path(raw_cl, "PerezEyzaguirre_DemandaAgregada.xlsx")
distr_file <- file.path(raw_cl, "distr_19202024.xlsx")
cliolab_file <- file.path(raw_cl, "W04_Precios_ClioLabPUC.xlsx")
wbop_file <- file.path(raw_cl, "WBOP", "NievasPiketty2025WBOPFinalSeries.xlsx")
bcch_file <- file.path(raw_cl, "BCCh_TCR", "bcch_tcr_monthly_raw.csv")
bcch_macro_file <- file.path(raw_cl, "ADnominal_deflators_19962025_BCCH.xlsx")
kstock_file <- paste0(
  "C:/ReposGitHub/K-Stock-Harmonization/outputs/",
  "HARMONIZED_BCCH_2003CLP_v1/",
  "harmonized_series_2003CLP_1900_2024.csv"
)
source_files <- c(perez_file, distr_file, cliolab_file, wbop_file,
                  bcch_file, bcch_macro_file, kstock_file)
stopifnot(all(file.exists(source_files)))

perez_raw <- suppressMessages(read_excel(perez_file, sheet = "Demanda Agregada"))
perez <- tibble(
  year = as.integer(perez_raw[[1]]),
  GDP_real_2003_CLP = as.numeric(perez_raw[[2]]),
  exports_FOB_real_2003_CLP = as.numeric(perez_raw[[3]]),
  imports_CIF_real_2003_CLP = as.numeric(perez_raw[[4]]),
  net_exports_real_2003_CLP = as.numeric(perez_raw[[5]]),
  investment_ME_real_2003_CLP = as.numeric(perez_raw[[6]]),
  investment_NR_real_2003_CLP = as.numeric(perez_raw[[7]]),
  inventory_change_real_2003_CLP = as.numeric(perez_raw[[8]]),
  investment_total_real_2003_CLP = as.numeric(perez_raw[[9]]),
  government_consumption_real_2003_CLP = as.numeric(perez_raw[[10]]),
  private_consumption_real_2003_CLP = as.numeric(perez_raw[[11]])
) |>
  filter(year >= 1920, year <= 2024)

# The historical demand workbook ends in 2010. Extend GDP, imports, exports,
# and total fixed investment with BCCh reference-2018 nominal/deflator pairs,
# preserving BCCh growth rates and anchoring each component to its 2010
# Pérez-Eyzaguirre real level.
bcch_macro_raw <- suppressMessages(
  read_excel(bcch_macro_file, sheet = "Canasta",
             col_names = FALSE, .name_repair = "minimal")
)
bcch_year_cells <- bcch_macro_raw[1, 3:ncol(bcch_macro_raw), drop = TRUE]
bcch_years <- vapply(bcch_year_cells, function(z) {
  if (inherits(z, c("Date", "POSIXct", "POSIXt"))) {
    as.integer(format(as.Date(z), "%Y"))
  } else {
    numeric_value <- as.numeric(z)
    if (is.finite(numeric_value) && numeric_value > 3000) {
      as.integer(format(as.Date(numeric_value, origin = "1899-12-30"), "%Y"))
    } else {
      as.integer(numeric_value)
    }
  }
}, integer(1))
extract_bcch_real <- function(nominal_row, deflator_row) {
  nominal <- suppressWarnings(as.numeric(
    bcch_macro_raw[nominal_row, 3:ncol(bcch_macro_raw), drop = TRUE]
  ))
  deflator <- suppressWarnings(as.numeric(
    bcch_macro_raw[deflator_row, 3:ncol(bcch_macro_raw), drop = TRUE]
  ))
  nominal / deflator * 100 * 1000
}
bcch_macro <- tibble(
  year = bcch_years,
  GDP_real_bcch_2018 = extract_bcch_real(8, 14),
  exports_real_bcch_2018 = extract_bcch_real(6, 12),
  imports_real_bcch_2018 = extract_bcch_real(7, 13),
  investment_real_bcch_2018 = extract_bcch_real(4, 11)
) |>
  filter(year >= 1996, year <= 2024)

splice_variables <- tibble::tribble(
  ~perez_variable, ~bcch_variable,
  "GDP_real_2003_CLP", "GDP_real_bcch_2018",
  "exports_FOB_real_2003_CLP", "exports_real_bcch_2018",
  "imports_CIF_real_2003_CLP", "imports_real_bcch_2018",
  "investment_total_real_2003_CLP", "investment_real_bcch_2018"
)
macro_splice_ledger <- bind_rows(lapply(seq_len(nrow(splice_variables)), function(i) {
  p_var <- splice_variables$perez_variable[i]
  b_var <- splice_variables$bcch_variable[i]
  p2010 <- perez[[p_var]][perez$year == 2010]
  b2010 <- bcch_macro[[b_var]][bcch_macro$year == 2010]
  factor <- p2010 / b2010
  bcch_macro[[paste0(p_var, "_chainlinked")]] <<-
    bcch_macro[[b_var]] * factor
  tibble(
    variable = p_var,
    perez_2010 = p2010,
    bcch_2010_reference2018 = b2010,
    chainlink_factor = factor,
    growth_2010_2011 = log(
      bcch_macro[[b_var]][bcch_macro$year == 2011] / b2010
    ),
    rule = "BCCh growth path chain-linked to Perez-Eyzaguirre 2010 level"
  )
}))

perez <- full_join(
  perez,
  bcch_macro |>
    select(year, ends_with("_chainlinked")),
  by = "year"
) |>
  arrange(year)
for (p_var in splice_variables$perez_variable) {
  extension_var <- paste0(p_var, "_chainlinked")
  perez[[p_var]] <- ifelse(
    perez$year >= 2011,
    perez[[extension_var]],
    perez[[p_var]]
  )
}
perez <- perez |>
  mutate(
    macro_source = ifelse(
      year <= 2010, "Perez-Eyzaguirre",
      "BCCh reference-2018 growth chain-linked at 2010"
    )
  ) |>
  select(-ends_with("_chainlinked")) |>
  filter(year >= 1920, year <= 2024)

distr_raw <- suppressMessages(read_excel(distr_file, sheet = "values"))
distr <- tibble(
  year = as.integer(distr_raw[[1]]),
  wage_share = as.numeric(distr_raw[[2]]),
  profit_share = as.numeric(distr_raw[[3]]),
  exploitation_rate = as.numeric(distr_raw[[4]])
) |>
  filter(year >= 1920, year <= 2024)

k_long <- read.csv(kstock_file, check.names = FALSE)
kstock <- k_long |>
  filter(asset %in% c("ME", "NRC"), year >= 1920, year <= 2024) |>
  select(year, asset, I, Kg, Kn) |>
  pivot_wider(
    names_from = asset,
    values_from = c(I, Kg, Kn),
    names_glue = "{.value}_{asset}"
  ) |>
  transmute(
    year = as.integer(year),
    K_ME_gross_2003_CLP = Kg_ME,
    K_NR_gross_2003_CLP = Kg_NRC,
    K_ME_net_2003_CLP = Kn_ME,
    K_NR_net_2003_CLP = Kn_NRC,
    investment_ME_kstock_2003_CLP = I_ME,
    investment_NR_kstock_2003_CLP = I_NRC
  )

cliolab_raw <- suppressMessages(
  read_excel(cliolab_file, sheet = "4.2.2", col_names = FALSE, skip = 11)
)
cliolab <- tibble(
  year = as.integer(cliolab_raw[[1]]),
  RER_cliolab_2003 = as.numeric(cliolab_raw[[2]])
) |>
  filter(year >= 1920, year <= 2024)

bcch_monthly <- read.csv(bcch_file, stringsAsFactors = FALSE)
bcch_annual_preliminary <- bcch_monthly |>
  group_by(year = as.integer(year)) |>
  summarise(
    RER_bcch_1986_annual_preliminary = mean(value, na.rm = TRUE),
    RER_bcch_months = sum(is.finite(value)),
    .groups = "drop"
  ) |>
  filter(year <= 2024)

wbop_map <- tibble::tribble(
  ~sheet, ~variable,
  "B1a", "goods_balance_gdp",
  "B1b", "goods_exports_gdp",
  "B1c", "goods_imports_gdp",
  "B3a", "manufactures_balance_gdp",
  "B3b", "manufactures_exports_gdp",
  "B3c", "manufactures_imports_gdp",
  "C1d", "goods_services_balance_gdp",
  "D1a", "net_foreign_income_gdp",
  "D1b", "foreign_income_inflows_gdp",
  "D1c", "foreign_income_outflows_gdp",
  "E1a", "net_transfers_gdp",
  "F1", "current_account_gdp",
  "G1a", "net_foreign_wealth_gdp",
  "G1b", "gross_foreign_assets_gdp",
  "G1c", "gross_foreign_liabilities_gdp"
)
read_wbop_chile <- function(sheet, variable) {
  x <- suppressMessages(read_excel(
    wbop_file, sheet = sheet, skip = 4, col_names = FALSE
  ))
  stopifnot(ncol(x) >= 29)
  out <- tibble(
    year = suppressWarnings(as.integer(x[[1]])),
    value = suppressWarnings(as.numeric(x[[29]]))
  ) |>
    filter(year >= 1920, year <= 2024)
  names(out)[2] <- variable
  out
}
wbop <- Reduce(
  function(x, y) full_join(x, y, by = "year"),
  lapply(seq_len(nrow(wbop_map)), function(i) {
    read_wbop_chile(wbop_map$sheet[i], wbop_map$variable[i])
  })
)

source_panel <- tibble(year = 1920:2024) |>
  left_join(perez, by = "year") |>
  left_join(distr, by = "year") |>
  left_join(kstock, by = "year") |>
  left_join(cliolab, by = "year") |>
  left_join(bcch_annual_preliminary, by = "year") |>
  left_join(wbop, by = "year") |>
  arrange(year) |>
  mutate(
    gross_operating_surplus_2003_CLP =
      profit_share * GDP_real_2003_CLP,
    non_reinvested_surplus_2003_CLP =
      gross_operating_surplus_2003_CLP - investment_total_real_2003_CLP,
    log_imports = ifelse(
      imports_CIF_real_2003_CLP > 0,
      log(imports_CIF_real_2003_CLP), NA_real_
    ),
    log_K_ME_gross = ifelse(
      K_ME_gross_2003_CLP > 0, log(K_ME_gross_2003_CLP), NA_real_
    ),
    log_K_NR_gross = ifelse(
      K_NR_gross_2003_CLP > 0, log(K_NR_gross_2003_CLP), NA_real_
    ),
    log_non_reinvested_surplus = ifelse(
      non_reinvested_surplus_2003_CLP > 0,
      log(non_reinvested_surplus_2003_CLP), NA_real_
    ),
    import_propensity = imports_CIF_real_2003_CLP / GDP_real_2003_CLP,
    external_financing_pressure_gdp = -current_account_gdp,
    financing_compression_5pp = as.integer(
      current_account_gdp - lag(current_account_gdp) >= 0.05
    )
  )

wide_file <- file.path(processed_dir, "chile_bop_source_panel_wide.csv")
long_file <- file.path(processed_dir, "chile_bop_source_panel_long.csv")
validation_file <- file.path(processed_dir, "source_panel_validation.csv")
write.csv(source_panel, wide_file, row.names = FALSE, na = "")

source_panel |>
  mutate(across(-year, as.character)) |>
  pivot_longer(-year, names_to = "variable", values_to = "value") |>
  write.csv(long_file, row.names = FALSE, na = "")

variable_meta <- tibble::tribble(
  ~variable, ~source, ~unit, ~base, ~role,
  "GDP_real_2003_CLP", "Perez-Eyzaguirre", "million CLP", "2003 prices", "raw",
  "imports_CIF_real_2003_CLP", "Perez-Eyzaguirre", "million CLP", "2003 prices", "raw",
  "investment_total_real_2003_CLP", "Perez-Eyzaguirre", "million CLP", "2003 prices", "raw",
  "profit_share", "distr_19202024", "ratio", "base-year-free", "raw",
  "wage_share", "distr_19202024", "ratio", "base-year-free", "raw",
  "K_ME_gross_2003_CLP", "K-Stock-Harmonization", "million CLP", "2003 prices", "raw",
  "K_NR_gross_2003_CLP", "K-Stock-Harmonization", "million CLP", "2003 prices", "raw",
  "RER_cliolab_2003", "ClioLab PUC 4.2.2", "index", "2003=100", "raw",
  "RER_bcch_1986_annual_preliminary", "BCCh F073.TCR.IND.199101.M", "index", "1986 average=100", "raw annualized",
  "gross_operating_surplus_2003_CLP", "constructed", "million CLP", "2003 prices", "derived",
  "non_reinvested_surplus_2003_CLP", "constructed", "million CLP", "2003 prices", "derived",
  "log_imports", "constructed", "log level", "2003 prices", "derived",
  "log_K_ME_gross", "constructed", "log level", "2003 prices", "derived",
  "log_non_reinvested_surplus", "constructed", "log level", "2003 prices", "derived",
  "import_propensity", "constructed", "ratio", "base-year-free", "derived"
)

coverage <- bind_rows(lapply(seq_len(nrow(variable_meta)), function(i) {
  v <- variable_meta$variable[i]
  ok <- is.finite(source_panel[[v]])
  tibble(
    variable = v,
    source = variable_meta$source[i],
    unit = variable_meta$unit[i],
    base = variable_meta$base[i],
    role = variable_meta$role[i],
    first_year = ifelse(any(ok), min(source_panel$year[ok]), NA_integer_),
    last_year = ifelse(any(ok), max(source_panel$year[ok]), NA_integer_),
    observations = sum(ok),
    missing = sum(!ok),
    passed = dplyr::case_when(
      v == "RER_cliolab_2003" ~ sum(ok) == 91,
      v == "RER_bcch_1986_annual_preliminary" ~ sum(ok) == 39,
      TRUE ~ all(ok)
    )
  )
}))
write.csv(coverage, validation_file, row.names = FALSE, na = "")

identity_audit <- tibble(
  check = c(
    "wage_plus_profit_share",
    "NRS_identity",
    "NRS_positive_for_logs",
    "model_core_complete_1920_2024",
    "gross_capital_not_net_capital"
  ),
  maximum_absolute_residual = c(
    max(abs(source_panel$wage_share + source_panel$profit_share - 1),
        na.rm = TRUE),
    max(abs(
      source_panel$non_reinvested_surplus_2003_CLP -
        (source_panel$profit_share * source_panel$GDP_real_2003_CLP -
           source_panel$investment_total_real_2003_CLP)
    ), na.rm = TRUE),
    min(source_panel$non_reinvested_surplus_2003_CLP, na.rm = TRUE),
    sum(!complete.cases(source_panel[, c(
      "log_imports", "log_K_ME_gross",
      "log_non_reinvested_surplus", "wage_share"
    )])),
    max(abs(source_panel$K_ME_gross_2003_CLP -
              source_panel$K_ME_net_2003_CLP), na.rm = TRUE)
  ),
  passed = c(
    max(abs(source_panel$wage_share + source_panel$profit_share - 1),
        na.rm = TRUE) < 1e-8,
    TRUE,
    min(source_panel$non_reinvested_surplus_2003_CLP, na.rm = TRUE) > 0,
    all(complete.cases(source_panel[, c(
      "log_imports", "log_K_ME_gross",
      "log_non_reinvested_surplus", "wage_share"
    )])),
    any(abs(source_panel$K_ME_gross_2003_CLP -
              source_panel$K_ME_net_2003_CLP) > 0, na.rm = TRUE)
  ),
  note = c(
    "accounting identity tolerance only",
    "constructed in the same expression audited here",
    "required for log NRS",
    "required for both split samples",
    "legacy import VECM uses gross machinery capital"
  )
)
write.csv(identity_audit,
          file.path(output_dir, "source_panel_identity_audit.csv"),
          row.names = FALSE)

provenance <- tibble(
  file = normalizePath(source_files, winslash = "/", mustWork = TRUE),
  bytes = file.info(source_files)$size,
  modified_utc = format(file.info(source_files)$mtime, tz = "UTC",
                        format = "%Y-%m-%dT%H:%M:%SZ"),
  sha256 = vapply(source_files, digest, character(1),
                  algo = "sha256", file = TRUE)
)
write.csv(provenance,
          file.path(output_dir, "source_file_provenance_sha256.csv"),
          row.names = FALSE)
write.csv(coverage,
          file.path(output_dir, "source_panel_coverage_audit.csv"),
          row.names = FALSE, na = "")
write.csv(wbop_map,
          file.path(output_dir, "wbop_variable_dictionary.csv"),
          row.names = FALSE)
write.csv(macro_splice_ledger,
          file.path(output_dir, "macro_2010_chainlink_ledger.csv"),
          row.names = FALSE)

stopifnot(all(identity_audit$passed), all(coverage$passed))
message("CL_BOP_BINDING S10 complete: canonical 1920-2024 source panel written.")
