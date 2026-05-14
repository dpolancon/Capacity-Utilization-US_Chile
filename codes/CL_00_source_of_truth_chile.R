# ============================================================
# CHILE — Source of Truth Builder
# Shared primitives only
# ------------------------------------------------------------
# Purpose:
#   Build a canonical upstream dataset for the chapter using
#   raw / locked preprocessing sources, while leaving all
#   theory-laden transformations to downstream scripts.
#
# Included blocks:
#   1) identifiers + provenance metadata
#   2) deflators / price primitives
#   3) external trade primitives
#   4) aggregate demand primitives
#   5) capital-stock primitives
#   6) wage-share / distribution primitives
#
# Explicitly excluded here:
#   - theta, mu, ECT, regime variables
#   - class-struggle decomposition components
#   - profitability rates and motion indices
#   - wedges, corridors, ratios, and logs
# ============================================================

suppressPackageStartupMessages({
  library(here)
  library(readr)
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(janitor)
  library(tibble)
  library(stringr)
  library(purrr)
})

# ============================================================
# 0. PATHS AND CONTROLS
# ============================================================

analysis_year_min <- 1940L
analysis_year_max <- 2024L

# If TRUE, keep source-label columns only in debug export, not in clean panel.
keep_source_cols_in_clean <- FALSE

out_root <- here::here("output", "source_of_truth_chile")
out_csv  <- file.path(out_root, "csv")
out_rds  <- file.path(out_root, "rds")
out_txt  <- file.path(out_root, "txt")
for (p in c(out_root, out_csv, out_rds, out_txt)) dir.create(p, recursive = TRUE, showWarnings = FALSE)

resolve_existing_path <- function(candidates) {
  hit <- candidates[file.exists(candidates)]
  if (length(hit) == 0) return(NA_character_)
  hit[[1]]
}

path_raw_panel <- resolve_existing_path(c(
  here::here("data", "raw", "Chile", "ch2_raw_panel_chile.csv"),
  here::here("data", "raw", "chile", "ch2_raw_panel_chile.csv")
))

path_processed_panel <- resolve_existing_path(c(
  here::here("data", "processed", "Chile", "ch2_panel_chile.csv"),
  here::here("data", "processed", "chile", "ch2_panel_chile.csv")
))

path_k_harmonized <- resolve_existing_path(c(
  here::here("data", "raw", "Chile", "harmonized_series_2003CLP_1900_2024.csv"),
  here::here("data", "raw", "chile", "harmonized_series_2003CLP_1900_2024.csv")
))

path_pk_harmonized <- resolve_existing_path(c(
  here::here("data", "raw", "Chile", "harmonized_pk_2003base_1940_2024.csv"),
  here::here("data", "raw", "chile", "harmonized_pk_2003base_1940_2024.csv")
))

path_prices_raw <- resolve_existing_path(c(
  here::here("data", "raw", "Chile", "W04_Precios_ClioLabPUC.xlsx"),
  here::here("data", "raw", "chile", "W04_Precios_ClioLabPUC.xlsx")
))

path_demand_raw <- resolve_existing_path(c(
  here::here("data", "raw", "Chile", "PerezEyzaguirre_DemandaAgregada.xlsx"),
  here::here("data", "raw", "chile", "PerezEyzaguirre_DemandaAgregada.xlsx")
))

path_distr_raw <- resolve_existing_path(c(
  here::here("data", "raw", "Chile", "distr_19202024.xlsx"),
  here::here("data", "raw", "chile", "distr_19202024.xlsx")
))

required_min <- c(path_k_harmonized, path_prices_raw)
if (any(is.na(required_min))) {
  stop(
    "Missing minimum required upstream sources. Need at least: harmonized capital stocks and price workbook.",
    call. = FALSE
  )
}

# ============================================================
# 1. HELPERS
# ============================================================

read_csv_clean <- function(path) {
  if (is.na(path)) return(NULL)
  readr::read_csv(path, show_col_types = FALSE) |> janitor::clean_names()
}

read_excel_clean <- function(path, sheet = NULL, skip = 0) {
  if (is.na(path)) return(NULL)
  if (is.null(sheet)) {
    readxl::read_excel(path, skip = skip) |> janitor::clean_names()
  } else {
    readxl::read_excel(path, sheet = sheet, skip = skip) |> janitor::clean_names()
  }
}

pick_first_present <- function(df, candidates) {
  if (is.null(df)) return(NA_character_)
  hit <- intersect(candidates, names(df))
  if (length(hit) == 0) return(NA_character_)
  hit[[1]]
}

maybe_vec <- function(df, candidates, n, default = NA_real_) {
  col <- pick_first_present(df, candidates)
  if (is.na(col)) return(rep(default, n))
  v <- df[[col]]
  if (length(v) == 0) return(rep(default, n))
  v
}

extract_optional <- function(df, year_candidates, value_candidates, out_name) {
  if (is.null(df)) return(tibble(year = integer(), !!out_name := numeric()))
  ycol <- pick_first_present(df, year_candidates)
  vcol <- pick_first_present(df, value_candidates)
  if (is.na(ycol) || is.na(vcol)) {
    return(tibble(year = integer(), !!out_name := numeric()))
  }
  df |>
    transmute(year = .data[[ycol]], !!out_name := .data[[vcol]])
}

coalesce_named <- function(...) {
  xs <- list(...)
  nm <- names(xs)
  if (is.null(nm)) nm <- rep("unnamed", length(xs))

  lens <- vapply(xs, length, integer(1))
  n <- if (any(lens > 0)) lens[which(lens > 0)[1]] else 0L

  out_val <- rep(NA_real_, n)
  out_src <- rep(NA_character_, n)

  for (i in seq_along(xs)) {
    x <- xs[[i]]

    if (length(x) == 0) x <- rep(NA_real_, n)
    if (length(x) == 1 && n > 1) x <- rep(x, n)

    if (length(x) != n) {
      stop(
        "coalesce_named received inconsistent lengths: ",
        paste(vapply(xs, length, integer(1)), collapse = ", "),
        call. = FALSE
      )
    }

    take <- is.na(out_val) & !is.na(x)
    out_val[take] <- x[take]
    out_src[take] <- nm[[i]]
  }

  tibble(value = out_val, source = out_src)
}

safe_left_join <- function(x, y, by = "year") {
  if (nrow(y) == 0) return(x)
  dplyr::left_join(x, y, by = by)
}

add_from_sources <- function(df, out_var, source_map) {
  n <- nrow(df)

  vals <- purrr::imap(source_map, function(col_name, src_name) {
    if (!col_name %in% names(df)) {
      return(rep(NA_real_, n))
    }

    x <- df[[col_name]]

    if (length(x) == 0) return(rep(NA_real_, n))
    if (length(x) == 1 && n > 1) return(rep(x, n))

    if (length(x) != n) {
      stop(
        "Column `", col_name, "` has length ", length(x),
        " but expected ", n, " rows.",
        call. = FALSE
      )
    }

    as.numeric(x)
  })

  tmp <- do.call(coalesce_named, vals)
  df[[out_var]] <- tmp$value
  df[[paste0("src_", out_var)]] <- tmp$source
  df
}

write_txt <- function(lines, path) writeLines(as.character(lines), con = path, useBytes = TRUE)

# ============================================================
# 2. LOAD UPSTREAM SOURCES
# ============================================================

raw_panel  <- read_csv_clean(path_raw_panel)
proc_panel <- read_csv_clean(path_processed_panel)
kraw       <- read_csv_clean(path_k_harmonized)
pkraw      <- read_csv_clean(path_pk_harmonized)
draw       <- read_excel_clean(path_distr_raw)
pe         <- read_excel_clean(path_demand_raw)

# Price workbook sheets used elsewhere in chapter codes
prices_413 <- read_excel_clean(path_prices_raw, sheet = "4.1.3", skip = 9)
prices_432 <- read_excel_clean(path_prices_raw, sheet = "4.3.2", skip = 9)
prices_441 <- read_excel_clean(path_prices_raw, sheet = "4.4.1", skip = 9)
prices_411 <- read_excel_clean(path_prices_raw, sheet = "4.1.1", skip = 9)

# ============================================================
# 3. BUILD PRIMITIVE BLOCKS
# ============================================================

# ---- 3A. Prices / deflators ----
price_block_w04 <- prices_413 |>
  transmute(
    year = code,
    pY = defpgb,
    pC = defc,
    pG = defg,
    pK_w04 = deffbkb,
    pX = defx,
    pM = defm
  ) |>
  safe_left_join(prices_432 |> transmute(year = code, pTI = termint), by = "year") |>
  safe_left_join(prices_441 |> transmute(year = code, wp = iwr), by = "year") |>
  safe_left_join(prices_411 |> transmute(year = code, pCPI = ipc), by = "year")

price_block_pk <- if (!is.null(pkraw)) {
  pkraw |>
    transmute(year = year, pK_harmonized = pk_2003base, pK_harmonized_source = source, pK_harmonized_quality = quality_flag)
} else {
  tibble(year = integer(), pK_harmonized = numeric(), pK_harmonized_source = character(), pK_harmonized_quality = character())
}

price_block <- price_block_w04 |>
  safe_left_join(price_block_pk, by = "year")

# ---- 3B. Capital stocks (ME + NR only; shared primitives) ----
cap_me_nr <- kraw |>
  filter(asset %in% c("ME", "NR")) |>
  select(year, asset, any_of(c("i", "kg", "kn"))) |>
  pivot_wider(names_from = asset, values_from = c(i, kg, kn), names_sep = "_") |>
  transmute(
    year,
    I_ME = i_ME,
    I_NR = i_NR,
    Kg_ME = kg_ME,
    Kg_NR = kg_NR,
    Kn_ME = kn_ME,
    Kn_NR = kn_NR,
    Kg_total = kg_ME + kg_NR,
    Kn_total = kn_ME + kn_NR
  )

# ---- 3C. Demand primitives ----
# Demand workbook (direct raw provenance where possible)
pe_year <- pick_first_present(pe, c("x1", "year", "anio", "ano"))
pe_block <- if (!is.na(pe_year)) {
  n_pe <- nrow(pe)
  tibble(year = pe[[pe_year]]) |>
    bind_cols(tibble(
      GDP_real = maybe_vec(pe, c("pib_real_milllones_de_pesos_de_2003", "gdp_real", "y_real"), n_pe),
      C_real   = maybe_vec(pe, c("consumo_total", "consumo_total_millones_de_pesos_de_2003", "c_real", "consumo"), n_pe),
      G_real   = maybe_vec(pe, c("gasto_de_gobierno", "gobierno", "g_real", "gasto_publico"), n_pe),
      FBKF_ME  = maybe_vec(pe, c("fbkf_en_maquinaria", "i_me", "fbkf_me"), n_pe),
      FBKF_NR  = maybe_vec(pe, c("fbkf_en_construccion", "i_cons", "fbkf_nr", "fbkf_construccion"), n_pe),
      I_total  = maybe_vec(pe, c("inversion_interna_bruta", "i_total", "fbkf_total"), n_pe),
      X_FOB    = maybe_vec(pe, c("exportaciones_fob_millones_de_pesos_de_2003", "x_fob", "exportaciones_fob"), n_pe),
      M_CIF    = maybe_vec(pe, c("importaciones_cif_millones_de_pesos_de_2003", "m_cif", "importaciones_cif"), n_pe)
    ))
} else {
  tibble(year = integer(), GDP_real = numeric(), C_real = numeric(), G_real = numeric(), FBKF_ME = numeric(), FBKF_NR = numeric(), I_total = numeric(), X_FOB = numeric(), M_CIF = numeric())
}

# Raw panel fallback (if present)
raw_block <- if (!is.null(raw_panel)) {
  n_raw <- nrow(raw_panel)
  tibble(year = raw_panel$year) |>
    bind_cols(tibble(
      GDP_real_raw = maybe_vec(raw_panel, c("gdp_real", "y_real"), n_raw),
      X_FOB_raw    = maybe_vec(raw_panel, c("x_fob", "exportaciones_fob", "exportaciones_fob_millones_de_pesos_de_2003"), n_raw),
      M_CIF_raw    = maybe_vec(raw_panel, c("m_cif", "importaciones_cif", "importaciones_cif_millones_de_pesos_de_2003"), n_raw),
      I_total_raw  = maybe_vec(raw_panel, c("i_total", "inversion_interna_bruta"), n_raw),
      C_real_raw   = maybe_vec(raw_panel, c("c_real", "consumo_total", "consumo"), n_raw),
      G_real_raw   = maybe_vec(raw_panel, c("g_real", "gasto_de_gobierno", "gobierno"), n_raw)
    ))
} else {
  tibble(year = integer(), GDP_real_raw = numeric(), X_FOB_raw = numeric(), M_CIF_raw = numeric(), I_total_raw = numeric(), C_real_raw = numeric(), G_real_raw = numeric())
}

# Processed panel fallback (if present)
proc_block <- if (!is.null(proc_panel)) {
  n_proc <- nrow(proc_panel)
  tibble(year = proc_panel$year) |>
    bind_cols(tibble(
      GDP_real_proc = maybe_vec(proc_panel, c("gdp_real"), n_proc),
      FBKF_ME_proc  = maybe_vec(proc_panel, c("fbkf_me", "i_me"), n_proc),
      FBKF_NR_proc  = maybe_vec(proc_panel, c("fbkf_nr", "i_nr", "i_cons"), n_proc),
      I_total_proc  = maybe_vec(proc_panel, c("i_total"), n_proc),
      M_CIF_proc    = maybe_vec(proc_panel, c("m_cif"), n_proc)
    ))
} else {
  tibble(year = integer(), GDP_real_proc = numeric(), FBKF_ME_proc = numeric(), FBKF_NR_proc = numeric(), I_total_proc = numeric(), M_CIF_proc = numeric())
}

# ---- 3D. Distribution primitives ----
draw_year <- pick_first_present(draw, c("periodo", "year", "anio", "ano"))
draw_block <- if (!is.na(draw_year)) {
  n_draw <- nrow(draw)
  tibble(
    year = draw[[draw_year]],
    omega = maybe_vec(draw, c("wage_share", "omega"), n_draw),
    pi = maybe_vec(draw, c("profit_share", "pi"), n_draw),
    exploitation_rate = maybe_vec(draw, c("exploitation_rate", "e"), n_draw)
  )
} else {
  tibble(year = integer(), omega = numeric(), pi = numeric(), exploitation_rate = numeric())
}

proc_distr <- if (!is.null(proc_panel)) {
  n_proc <- nrow(proc_panel)
  tibble(
    year = proc_panel$year,
    omega_proc = maybe_vec(proc_panel, c("omega"), n_proc),
    pi_proc = maybe_vec(proc_panel, c("pi"), n_proc),
    exploitation_rate_proc = maybe_vec(proc_panel, c("exploitation_rate"), n_proc)
  )
} else {
  tibble(year = integer(), omega_proc = numeric(), pi_proc = numeric(), exploitation_rate_proc = numeric())
}

# ============================================================
# 4. MERGE TO CANONICAL PANEL
# ============================================================

year_grid <- tibble(year = seq.int(analysis_year_min, analysis_year_max, by = 1L))

panel0 <- year_grid |>
  safe_left_join(price_block, by = "year") |>
  safe_left_join(cap_me_nr, by = "year") |>
  safe_left_join(pe_block, by = "year") |>
  safe_left_join(raw_block, by = "year") |>
  safe_left_join(proc_block, by = "year") |>
  safe_left_join(draw_block, by = "year") |>
  safe_left_join(proc_distr, by = "year")

# Canonical pK: dedicated harmonized pK preferred; W04 fallback
panel1 <- panel0 |>
  add_from_sources("pK", c(harmonized_pk = "pK_harmonized", w04_prices = "pK_w04")) |>
  add_from_sources("GDP_real_canonical", c(demand_workbook = "GDP_real", raw_panel = "GDP_real_raw", processed_panel = "GDP_real_proc")) |>
  add_from_sources("C_real_canonical", c(demand_workbook = "C_real", raw_panel = "C_real_raw")) |>
  add_from_sources("G_real_canonical", c(demand_workbook = "G_real", raw_panel = "G_real_raw")) |>
  add_from_sources("FBKF_ME_canonical", c(demand_workbook = "FBKF_ME", processed_panel = "FBKF_ME_proc")) |>
  add_from_sources("FBKF_NR_canonical", c(demand_workbook = "FBKF_NR", processed_panel = "FBKF_NR_proc")) |>
  add_from_sources("I_total_canonical", c(demand_workbook = "I_total", raw_panel = "I_total_raw", processed_panel = "I_total_proc")) |>
  add_from_sources("X_FOB_canonical", c(demand_workbook = "X_FOB", raw_panel = "X_FOB_raw")) |>
  add_from_sources("M_CIF_canonical", c(demand_workbook = "M_CIF", raw_panel = "M_CIF_raw", processed_panel = "M_CIF_proc")) |>
  add_from_sources("omega_canonical", c(distribution_workbook = "omega", processed_panel = "omega_proc")) |>
  add_from_sources("pi_canonical", c(distribution_workbook = "pi", processed_panel = "pi_proc")) |>
  add_from_sources("exploitation_rate_canonical", c(distribution_workbook = "exploitation_rate", processed_panel = "exploitation_rate_proc"))

source_truth_chile <- panel1 |>
  transmute(
    year,

    # provenance metadata
    analysis_window_flag = year >= analysis_year_min & year <= analysis_year_max,
    price_base_year_used = NA_integer_,
    price_base_rule = NA_character_,

    # deflators / price primitives
    pY,
    pC,
    pG,
    pK,
    pX,
    pM,
    pTI,
    wp,
    pCPI,

    # external trade primitives
    X_FOB = X_FOB_canonical,
    M_CIF = M_CIF_canonical,

    # aggregate demand primitives
    GDP_real = GDP_real_canonical,
    C_real   = C_real_canonical,
    G_real   = G_real_canonical,
    FBKF_ME  = FBKF_ME_canonical,
    FBKF_NR  = FBKF_NR_canonical,
    I_total  = I_total_canonical,
    I_ME,
    I_NR,

    # capital-stock primitives
    Kg_ME,
    Kg_NR,
    Kg_total,
    Kn_ME,
    Kn_NR,
    Kn_total,

    # wage-share / distribution primitives
    omega = omega_canonical,
    pi    = pi_canonical,
    exploitation_rate = exploitation_rate_canonical,

    # rowwise source labels (kept or dropped later)
    src_pK,
    src_GDP_real_canonical,
    src_C_real_canonical,
    src_G_real_canonical,
    src_FBKF_ME_canonical,
    src_FBKF_NR_canonical,
    src_I_total_canonical,
    src_X_FOB_canonical,
    src_M_CIF_canonical,
    src_omega_canonical,
    src_pi_canonical,
    src_exploitation_rate_canonical
  )

if (!keep_source_cols_in_clean) {
  source_truth_chile_clean <- source_truth_chile |>
    select(-starts_with("src_"))
} else {
  source_truth_chile_clean <- source_truth_chile
}

# ============================================================
# 5. MENU + PROVENANCE OUTPUTS
# ============================================================

variable_menu <- tribble(
  ~block, ~variable,
  "identifiers", "year",
  "identifiers", "analysis_window_flag",
  "identifiers", "price_base_year_used",
  "identifiers", "price_base_rule",
  "deflators", "pY",
  "deflators", "pC",
  "deflators", "pG",
  "deflators", "pK",
  "deflators", "pX",
  "deflators", "pM",
  "deflators", "pTI",
  "deflators", "wp",
  "deflators", "pCPI",
  "external_trade", "X_FOB",
  "external_trade", "M_CIF",
  "aggregate_demand", "GDP_real",
  "aggregate_demand", "C_real",
  "aggregate_demand", "G_real",
  "aggregate_demand", "FBKF_ME",
  "aggregate_demand", "FBKF_NR",
  "aggregate_demand", "I_total",
  "aggregate_demand", "I_ME",
  "aggregate_demand", "I_NR",
  "capital_stocks", "Kg_ME",
  "capital_stocks", "Kg_NR",
  "capital_stocks", "Kg_total",
  "capital_stocks", "Kn_ME",
  "capital_stocks", "Kn_NR",
  "capital_stocks", "Kn_total",
  "distribution", "omega",
  "distribution", "pi",
  "distribution", "exploitation_rate"
)

variable_provenance <- tribble(
  ~variable, ~primary_source, ~notes,
  "pY", "W04_Precios_ClioLabPUC.xlsx::4.1.3::defpgb", "output deflator primitive",
  "pC", "W04_Precios_ClioLabPUC.xlsx::4.1.3::defc", "consumption deflator primitive",
  "pG", "W04_Precios_ClioLabPUC.xlsx::4.1.3::defg", "government deflator primitive",
  "pK", "harmonized_pk_2003base_1940_2024.csv preferred; W04 fallback", "single Chilean capital-goods deflator taken as canonical pK",
  "pX", "W04_Precios_ClioLabPUC.xlsx::4.1.3::defx", "export deflator primitive",
  "pM", "W04_Precios_ClioLabPUC.xlsx::4.1.3::defm", "import deflator primitive",
  "pTI", "W04_Precios_ClioLabPUC.xlsx::4.3.2::termint", "price primitive kept raw",
  "wp", "W04_Precios_ClioLabPUC.xlsx::4.4.1::iwr", "wage-price primitive kept raw",
  "pCPI", "W04_Precios_ClioLabPUC.xlsx::4.1.1::ipc", "consumer price index primitive",
  "GDP_real", "PerezEyzaguirre_DemandaAgregada.xlsx preferred; raw/processed panel fallback", "canonical real GDP primitive",
  "C_real", "PerezEyzaguirre_DemandaAgregada.xlsx if available", "aggregate demand primitive",
  "G_real", "PerezEyzaguirre_DemandaAgregada.xlsx if available", "aggregate demand primitive",
  "FBKF_ME", "PerezEyzaguirre_DemandaAgregada.xlsx preferred; processed panel fallback", "machinery investment primitive",
  "FBKF_NR", "PerezEyzaguirre_DemandaAgregada.xlsx preferred; processed panel fallback", "construction/non-residential investment primitive in current chapter usage",
  "I_total", "PerezEyzaguirre_DemandaAgregada.xlsx preferred; panel fallback", "aggregate investment primitive",
  "X_FOB", "Demand workbook if available; raw panel fallback", "export flow primitive",
  "M_CIF", "PerezEyzaguirre_DemandaAgregada.xlsx preferred; panel fallback", "import flow primitive",
  "I_ME", "harmonized_series_2003CLP_1900_2024.csv::ME::I", "asset-level investment primitive",
  "I_NR", "harmonized_series_2003CLP_1900_2024.csv::NR::I", "asset-level investment primitive",
  "Kg_ME", "harmonized_series_2003CLP_1900_2024.csv::ME::Kg", "gross real capital primitive",
  "Kg_NR", "harmonized_series_2003CLP_1900_2024.csv::NR::Kg", "gross real capital primitive",
  "Kg_total", "sum of Kg_ME + Kg_NR", "locked aggregation rule from panel design",
  "Kn_ME", "harmonized_series_2003CLP_1900_2024.csv::ME::Kn", "net real capital primitive",
  "Kn_NR", "harmonized_series_2003CLP_1900_2024.csv::NR::Kn", "net real capital primitive",
  "Kn_total", "sum of Kn_ME + Kn_NR", "locked aggregation rule from panel design",
  "omega", "distr_19202024.xlsx preferred; processed panel fallback", "wage-share primitive",
  "pi", "distr_19202024.xlsx preferred; processed panel fallback", "profit-share primitive",
  "exploitation_rate", "distr_19202024.xlsx preferred; processed panel fallback", "distribution primitive"
)

fill_audit <- map_dfr(
  grep("^src_", names(source_truth_chile), value = TRUE),
  function(src_col) {
    var <- str_remove(src_col, "^src_")
    source_truth_chile |>
      count(source = .data[[src_col]], name = "n_years") |>
      mutate(variable = var, .before = 1)
  }
)

manifest_lines <- c(
  "Chile source of truth builder",
  paste0("analysis_year_min: ", analysis_year_min),
  paste0("analysis_year_max: ", analysis_year_max),
  "",
  "Resolved paths:",
  paste0("- raw_panel: ", path_raw_panel),
  paste0("- processed_panel: ", path_processed_panel),
  paste0("- harmonized_k: ", path_k_harmonized),
  paste0("- harmonized_pk: ", path_pk_harmonized),
  paste0("- prices_raw: ", path_prices_raw),
  paste0("- demand_raw: ", path_demand_raw),
  paste0("- distr_raw: ", path_distr_raw),
  "",
  "Design note:",
  "This panel stores shared primitives only. Structural-regime variables, class-struggle decomposition, profitability objects, wedges, ratios, logs, and motion indices are built downstream in their own scripts."
)

# ============================================================
# 6. EXPORTS
# ============================================================

write_csv(source_truth_chile_clean, file.path(out_csv, "source_of_truth_chile.csv"))
saveRDS(source_truth_chile_clean, file.path(out_rds, "source_of_truth_chile.rds"))
saveRDS(source_truth_chile, file.path(out_rds, "source_of_truth_chile_with_sources.rds"))
write_csv(variable_menu, file.path(out_csv, "source_of_truth_variable_menu.csv"))
write_csv(variable_provenance, file.path(out_csv, "source_of_truth_variable_provenance.csv"))
write_csv(fill_audit, file.path(out_csv, "source_of_truth_fill_audit.csv"))
write_txt(manifest_lines, file.path(out_txt, "source_of_truth_manifest.txt"))

cat("Saved source-of-truth outputs to:\n")
cat("  ", out_root, "\n", sep = "")
cat("Main exports:\n")
cat("  csv/source_of_truth_chile.csv\n")
cat("  rds/source_of_truth_chile.rds\n")
cat("  rds/source_of_truth_chile_with_sources.rds\n")
cat("  csv/source_of_truth_variable_menu.csv\n")
cat("  csv/source_of_truth_variable_provenance.csv\n")
cat("  csv/source_of_truth_fill_audit.csv\n")
cat("  txt/source_of_truth_manifest.txt\n")
