############################################################
# 44_build_kstock_private.R — Private Capital Stock (GPIM)
#
# CORE SCRIPT. Builds private capital stocks by asset type
# using the GPIM apparatus from Shaikh (2016).
#
# For each asset (ME, NRC, RC, IP):
#   A. Extract from BEA Tables 4.1-4.7
#   B. Build gross stock (current-cost)
#   C. Compute own-price implicit deflators
#   D. Build GPIM constant-cost stocks (eq. 5)
#   E. Aggregate: NR=ME+NRC, TOTAL=ME+NRC+RC
#   F. Compute GPIM diagnostics (z_t, z*, half-life)
#
# Outputs to data/interim/kstock_components/ and data/processed/
#
# Sources: 40_gdp_kstock_config.R, 97_kstock_helpers.R
############################################################

rm(list = ls())

library(dplyr)
library(tidyr)
library(readr)

source("codes/40_gdp_kstock_config.R")
source("codes/99_utils.R")
source("codes/97_kstock_helpers.R")

ensure_dirs(GDP_CONFIG)

## ==============================================================
## §A. Load parsed BEA tables
## ==============================================================

load_parsed <- function(label) {
  path <- file.path(GDP_CONFIG$INTERIM_BEA_PARSED, sprintf("%s.csv", label))
  if (!file.exists(path)) {
    stop("Parsed BEA table not found: ", path,
         "\nRun 41_fetch_bea_fixed_assets.R first.")
  }
  readr::read_csv(path, show_col_types = FALSE)
}

tbl_net_cc    <- load_parsed("private_net_cc")     # Table 4.1
tbl_net_chain <- load_parsed("private_net_chain")   # Table 4.2
tbl_net_hist  <- load_parsed("private_net_hist")    # Table 4.3
tbl_dep_cc    <- load_parsed("private_dep_cc")      # Table 4.4
tbl_inv       <- load_parsed("private_inv")          # Table 4.7

message(sprintf("Loaded 5 BEA tables. Year range: %d-%d",
                min(tbl_net_cc$year), max(tbl_net_cc$year)))

## ==============================================================
## §B. Extract asset-level series
## ==============================================================

#' Extract a specific line from a BEA table
#'
#' @param tbl  Parsed BEA table (long format)
#' @param line Line number to extract
#' @param col_name Name for the value column
#' @return tibble(year, col_name)
extract_line <- function(tbl, line, col_name) {
  tbl |>
    filter(line_number == line) |>
    select(year, !!col_name := value) |>
    arrange(year)
}

# Line number mapping from config
lm <- GDP_CONFIG$LINE_MAP_PRIVATE

# Extract each asset from each table
# We build a list of data frames, one per asset type
assets <- list()

for (asset_code in c("ME", "NRC", "RC", "IP")) {
  # Determine line number
  line_num <- switch(asset_code,
    ME  = lm$equipment,
    NRC = lm$structures,
    RC  = lm$residential,
    IP  = lm$ip_products
  )

  message(sprintf("\nExtracting %s (line %d)...", asset_code, line_num))

  # Current-cost net stock (Table 4.1)
  K_net_cc <- extract_line(tbl_net_cc, line_num, "K_net_cc")

  # Chain-type QI net stock (Table 4.2)
  K_net_chain <- extract_line(tbl_net_chain, line_num, "K_net_chain")

  # Historical-cost net stock (Table 4.3)
  K_net_hist <- extract_line(tbl_net_hist, line_num, "K_net_hist")

  # Depreciation (Table 4.4)
  D_cc <- extract_line(tbl_dep_cc, line_num, "D_cc")

  # Investment (Table 4.7)
  IG_cc <- extract_line(tbl_inv, line_num, "IG_cc")

  # Merge all into single asset df
  asset_df <- K_net_cc |>
    left_join(K_net_chain, by = "year") |>
    left_join(K_net_hist, by = "year") |>
    left_join(D_cc, by = "year") |>
    left_join(IG_cc, by = "year") |>
    mutate(asset = asset_code) |>
    arrange(year)

  n_obs <- nrow(asset_df)
  n_na  <- sum(is.na(asset_df$K_net_cc))
  message(sprintf("  %s: %d obs, %d NAs in K_net_cc", asset_code, n_obs, n_na))

  assets[[asset_code]] <- asset_df
}


## ==============================================================
## §C. Build gross stock (current-cost)
## ==============================================================

message("\n--- Building gross stocks (current-cost) ---")

for (asset_code in names(assets)) {
  df <- assets[[asset_code]]

  # Gross = Net + cumulative depreciation (crude approximation)
  # See 97_kstock_helpers.R build_gross_from_net() for discussion
  df <- df |>
    mutate(
      K_gross_cc = K_net_cc + D_cc  # first-order approximation
    )

  assets[[asset_code]] <- df
  message(sprintf("  %s gross stock: mean ratio gross/net = %.3f",
                  asset_code,
                  mean(df$K_gross_cc / df$K_net_cc, na.rm = TRUE)))
}


## ==============================================================
## §D. Own-price implicit deflators (§7)
## ==============================================================

message("\n--- Computing own-price implicit deflators ---")

base_year <- GDP_CONFIG$GPIM$base_year

for (asset_code in names(assets)) {
  df <- assets[[asset_code]]

  # Deflator = K_cc / K_chain (proportional to price level)
  # Chain QI is an index, so we compute the ratio and rebase
  df <- df |>
    mutate(
      # Raw deflator ratio
      p_K_raw = ifelse(K_net_chain > 0, K_net_cc / K_net_chain, NA_real_)
    )

  # Rebase to base_year = 1.0
  if (base_year %in% df$year) {
    df <- df |>
      mutate(
        p_K = rebase_index(p_K_raw, year, base_year, scale = 1.0)
      )
  } else {
    warning(sprintf("Base year %d not in %s data. Using first available year.",
                    base_year, asset_code))
    df <- df |>
      mutate(p_K = p_K_raw / p_K_raw[1])
  }

  assets[[asset_code]] <- df
  message(sprintf("  %s deflator: range [%.4f, %.4f] (base %d = 1.0)",
                  asset_code,
                  min(df$p_K, na.rm = TRUE),
                  max(df$p_K, na.rm = TRUE),
                  base_year))
}


## ==============================================================
## §E. GPIM constant-cost stocks (eq. 5)
## ==============================================================

message("\n--- Building GPIM constant-cost stocks ---")

for (asset_code in names(assets)) {
  df <- assets[[asset_code]]

  # Single deflation: all series deflated by SAME own-price index
  # This preserves SFC: K^R_t = K^R_{t-1} + IG^R_t - D^R_t
  gpim <- gpim_deflate_sfc(
    K_cc  = df$K_net_cc,
    IG_cc = df$IG_cc,
    D_cc  = df$D_cc,
    p_K   = df$p_K
  )

  df <- df |>
    mutate(
      K_net_real  = gpim$K_real,
      IG_real     = gpim$IG_real,
      D_real      = gpim$D_real,
      K_gross_real = K_gross_cc / p_K
    )

  # Verify SFC identity for GPIM real stocks
  sfc <- validate_sfc_identity(
    K     = df$K_net_real[-1],
    K_lag = df$K_net_real[-nrow(df)],
    I     = df$IG_real[-1],
    D     = df$D_real[-1],
    label = paste0(asset_code, "_gpim_real")
  )

  max_resid <- max(abs(sfc$pct_residual), na.rm = TRUE)
  message(sprintf("  %s GPIM SFC check: max |residual| = %.6f (tol = %.4f) %s",
                  asset_code, max_resid, GDP_CONFIG$GPIM$sfc_tolerance,
                  ifelse(max_resid < GDP_CONFIG$GPIM$sfc_tolerance,
                         "[PASS]", "[WARN]")))

  # Also validate SFC for chain-weighted (expect failure)
  sfc_chain <- validate_sfc_identity(
    K     = df$K_net_chain[-1],
    K_lag = df$K_net_chain[-nrow(df)],
    I     = df$IG_cc[-1],   # investment in cc, not chain
    D     = df$D_cc[-1],    # depreciation in cc, not chain
    label = paste0(asset_code, "_chain_weighted")
  )
  max_resid_chain <- max(abs(sfc_chain$pct_residual), na.rm = TRUE)
  message(sprintf("  %s Chain SFC check: max |residual| = %.6f %s",
                  asset_code, max_resid_chain,
                  ifelse(max_resid_chain > GDP_CONFIG$GPIM$sfc_tolerance,
                         "[EXPECTED FAIL — confirms Shaikh]",
                         "[unexpected pass]")))

  assets[[asset_code]] <- df

  # Save SFC validation to interim
  safe_write_csv(sfc,
    file.path(GDP_CONFIG$INTERIM_VALIDATION,
              sprintf("sfc_%s_gpim.csv", asset_code)))
  safe_write_csv(sfc_chain,
    file.path(GDP_CONFIG$INTERIM_VALIDATION,
              sprintf("sfc_%s_chain.csv", asset_code)))
}


## ==============================================================
## §F. GPIM diagnostics: z_t, z*, half-life
## ==============================================================

message("\n--- Computing GPIM diagnostics ---")

diagnostics <- list()

for (asset_code in names(assets)) {
  df <- assets[[asset_code]]
  n <- nrow(df)

  # Theoretically correct depreciation rate (eq. 6)
  df_diag <- df |>
    mutate(
      K_net_real_lag = dplyr::lag(K_net_real),
      z_correct = gpim_depreciation_rate(D_cc, p_K, K_net_real_lag),
      z_whelan_liu = gpim_whelan_liu_rate(D_cc, dplyr::lag(K_net_cc))
    ) |>
    filter(!is.na(z_correct))

  # Average depreciation rate
  z_avg <- mean(df_diag$z_correct, na.rm = TRUE)

  # Capital price growth rate
  p_K_growth <- diff(log(df$p_K))
  g_pK_avg <- mean(p_K_growth, na.rm = TRUE)
  g_pK_1plus <- exp(g_pK_avg)

  # Critical rate and half-life
  z_star <- gpim_critical_rate(g_pK_1plus - 1)
  tau_half <- gpim_half_life(z_avg, g_pK_1plus - 1)

  # Convergence regime
  regime <- ifelse(z_avg > z_star, "CONVERGENT", "NON-CONVERGENT")

  diagnostics[[asset_code]] <- tibble(
    asset     = asset_code,
    z_avg     = z_avg,
    z_wl_avg  = mean(df_diag$z_whelan_liu, na.rm = TRUE),
    g_pK      = g_pK_avg,
    z_star    = z_star,
    tau_half  = tau_half,
    regime    = regime
  )

  message(sprintf("  %s: z_avg=%.4f, z*=%.4f, regime=%s, tau_half=%.1f yr",
                  asset_code, z_avg, z_star, regime, tau_half))
}

diag_df <- bind_rows(diagnostics)
safe_write_csv(diag_df,
  file.path(GDP_CONFIG$INTERIM_VALIDATION, "gpim_diagnostics.csv"))


## ==============================================================
## §G. Aggregate composites: NR, TOTAL, TOTAL_ALL
## ==============================================================

message("\n--- Building aggregates ---")

# Stack all assets
all_assets <- bind_rows(assets)

# Wide format for aggregation
wide <- all_assets |>
  select(year, asset, K_net_cc, K_gross_cc, K_net_real, K_gross_real,
         K_net_chain, K_net_hist, IG_cc, IG_real, D_cc, D_real, p_K)

# For current-cost and GPIM-real: aggregation is additive
for (comp_name in names(GDP_CONFIG$ASSET_COMPOSITES)) {
  components <- GDP_CONFIG$ASSET_COMPOSITES[[comp_name]]
  message(sprintf("  %s = %s", comp_name, paste(components, collapse = " + ")))

  comp_df <- wide |>
    filter(asset %in% components) |>
    group_by(year) |>
    summarise(
      K_net_cc    = sum(K_net_cc, na.rm = TRUE),
      K_gross_cc  = sum(K_gross_cc, na.rm = TRUE),
      K_net_real  = sum(K_net_real, na.rm = TRUE),
      K_gross_real = sum(K_gross_real, na.rm = TRUE),
      K_net_hist  = sum(K_net_hist, na.rm = TRUE),
      IG_cc       = sum(IG_cc, na.rm = TRUE),
      IG_real     = sum(IG_real, na.rm = TRUE),
      D_cc        = sum(D_cc, na.rm = TRUE),
      D_real      = sum(D_real, na.rm = TRUE),
      # Chain-weighted: NOT additive — sum anyway with warning
      K_net_chain = sum(K_net_chain, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(
      asset = comp_name,
      # Aggregate deflator: implicit from cc/real ratio
      p_K = ifelse(K_net_real > 0, K_net_cc / K_net_real, NA_real_)
    )

  # Note: K_net_chain sum is NOT correct for chain indices (non-additive)
  # This is documented and expected; BEA's published aggregate differs
  assets[[comp_name]] <- comp_df
}

# Warn about chain non-additivity
message("  NOTE: Chain-weighted aggregates (K_net_chain) are summed for ")
message("  reference only. Chain indices are NOT additive (Fisher-ideal).")
message("  Use BEA published aggregates for chain comparison, not sums.")


## ==============================================================
## §H. Write output files
## ==============================================================

message("\n--- Writing output files ---")

# Helper to pivot assets to wide format
pivot_to_wide <- function(asset_list, value_cols) {
  combined <- bind_rows(asset_list)
  result <- combined |>
    select(year, asset, all_of(value_cols))

  # Pivot wider: one column per asset-measure combination
  result |>
    pivot_wider(
      names_from  = asset,
      values_from = all_of(value_cols),
      names_glue  = "{asset}_{.value}"
    ) |>
    arrange(year)
}

# 1. Current-cost stocks
cc_wide <- pivot_to_wide(assets, c("K_net_cc", "K_gross_cc", "IG_cc", "D_cc"))
safe_write_csv(cc_wide,
  file.path(GDP_CONFIG$PROCESSED, "kstock_private_current_cost.csv"))
message(sprintf("  Written: kstock_private_current_cost.csv (%d rows)", nrow(cc_wide)))

# 2. GPIM real stocks
gpim_wide <- pivot_to_wide(assets, c("K_net_real", "K_gross_real", "IG_real", "D_real"))
safe_write_csv(gpim_wide,
  file.path(GDP_CONFIG$PROCESSED, "kstock_private_gpim_real.csv"))
message(sprintf("  Written: kstock_private_gpim_real.csv (%d rows)", nrow(gpim_wide)))

# 3. Chain-weighted (for comparison only)
chain_wide <- pivot_to_wide(assets, c("K_net_chain"))
safe_write_csv(chain_wide,
  file.path(GDP_CONFIG$PROCESSED, "kstock_private_chain_qty.csv"))
message(sprintf("  Written: kstock_private_chain_qty.csv (%d rows)", nrow(chain_wide)))

# 4. Price deflators
defl_wide <- pivot_to_wide(assets, c("p_K"))
safe_write_csv(defl_wide,
  file.path(GDP_CONFIG$PROCESSED, "price_deflators.csv"))
message(sprintf("  Written: price_deflators.csv (%d rows)", nrow(defl_wide)))

# 5. Interim component files (long format, per asset)
for (asset_code in names(assets)) {
  safe_write_csv(assets[[asset_code]],
    file.path(GDP_CONFIG$INTERIM_KSTOCK,
              sprintf("kstock_%s.csv", asset_code)))
}

message(sprintf("\n=== Private capital stock construction complete ==="))
message(sprintf("Processed data: %s", GDP_CONFIG$PROCESSED))
message(sprintf("Interim data: %s", GDP_CONFIG$INTERIM_KSTOCK))
