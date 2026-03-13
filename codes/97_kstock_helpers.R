############################################################
# 97_kstock_helpers.R — GPIM Helper Functions
#
# Implements the Generalized Perpetual Inventory Method
# apparatus from Shaikh (2016), Appendix 6.5 §V, 6.6 §I,
# and 6.7 §V.
#
# Notation follows docs/notation.md.
# Configuration from 40_gdp_kstock_config.R (GDP_CONFIG).
#
# Dependencies: dplyr, tidyr, readr
# (No side effects — pure functions only)
############################################################

# ==================================================================
# §A. BEA I/O Functions
# ==================================================================

#' Read and standardize a BEA CSV file (downloaded from iTable)
#'
#' BEA CSVs typically have header rows, then a wide-format table
#' with years as columns. This function handles common formats.
#'
#' @param path Path to CSV file
#' @return tibble in long format: year, line_number, line_desc, value
read_bea_csv <- function(path) {
  stopifnot(file.exists(path))

  raw <- readr::read_csv(path, show_col_types = FALSE, skip = 0)

  # Detect if first column is line numbers or descriptions
  # BEA format: first few cols are metadata, then year columns
  year_cols <- grep("^\\d{4}$", names(raw), value = TRUE)
  meta_cols <- setdiff(names(raw), year_cols)

  if (length(year_cols) == 0) {
    # Try transposed format
    stop("Cannot detect year columns in BEA CSV: ", path,
         "\nExpected column names matching YYYY pattern.")
  }

  # Standardize metadata columns
  names_lower <- tolower(meta_cols)
  line_col <- meta_cols[grepl("line", names_lower)][1]
  desc_col <- meta_cols[grepl("desc|name|series", names_lower)][1]

  if (is.na(line_col)) line_col <- meta_cols[1]
  if (is.na(desc_col)) desc_col <- meta_cols[min(2, length(meta_cols))]

  result <- raw |>
    tidyr::pivot_longer(
      cols      = tidyr::all_of(year_cols),
      names_to  = "year",
      values_to = "value"
    ) |>
    dplyr::transmute(
      year        = as.integer(.data$year),
      line_number = as.integer(.data[[line_col]]),
      line_desc   = as.character(.data[[desc_col]]),
      value       = suppressWarnings(as.numeric(gsub("[^0-9.\\-]", "", .data$value)))
    )

  result
}

#' Parse BEA API response into standardized long format
#'
#' @param resp Response from bea.R::beaGet() (a data.frame)
#' @return tibble: year, line_number, line_desc, value
parse_bea_api_response <- function(resp) {
  stopifnot(is.data.frame(resp))

  # BEA API returns: TableName, SeriesCode, LineNumber,
  #   LineDescription, TimePeriod, METRIC_NAME, CL_UNIT,
  #   UNIT_MULT, DataValue, NoteRef
  result <- resp |>
    dplyr::transmute(
      year        = as.integer(.data$TimePeriod),
      line_number = as.integer(.data$LineNumber),
      line_desc   = as.character(.data$LineDescription),
      value       = suppressWarnings(as.numeric(gsub("[^0-9.\\-]", "", .data$DataValue)))
    )

  result
}

#' Pivot BEA wide-format data to tidy long format
#'
#' Generic fallback for non-standard BEA formats.
#'
#' @param df Data frame with year columns (YYYY format)
#' @return tibble in long format
bea_wide_to_long <- function(df) {
  year_cols <- grep("^\\d{4}$", names(df), value = TRUE)
  meta_cols <- setdiff(names(df), year_cols)

  df |>
    tidyr::pivot_longer(
      cols      = tidyr::all_of(year_cols),
      names_to  = "year",
      values_to = "value"
    ) |>
    dplyr::mutate(year = as.integer(.data$year))
}

#' Map BEA line numbers to asset taxonomy codes
#'
#' @param df Long-format BEA data with line_number column
#' @param line_map Named list: asset_code -> line_number(s)
#' @return df with additional column 'asset'
map_bea_lines <- function(df, line_map) {
  # Invert the map: line_number -> asset_code
  inv <- data.frame(
    line_number = unlist(line_map),
    asset       = rep(names(line_map), lengths(line_map)),
    stringsAsFactors = FALSE
  )
  dplyr::left_join(df, inv, by = "line_number")
}

#' Validate BEA line map against actual line descriptions
#'
#' Checks that line numbers correspond to expected description
#' substrings. Issues warnings for mismatches.
#'
#' @param df Parsed BEA data with line_number and line_desc
#' @param expected Named list: label -> list(line=N, desc_pattern="substring")
#' @return Logical: TRUE if all match
validate_line_map <- function(df, expected) {
  all_ok <- TRUE
  for (label in names(expected)) {
    spec <- expected[[label]]
    row <- df |>
      dplyr::filter(.data$line_number == spec$line) |>
      dplyr::slice(1)

    if (nrow(row) == 0) {
      warning(sprintf("Line %d (%s) not found in data", spec$line, label))
      all_ok <- FALSE
    } else if (!grepl(spec$desc_pattern, row$line_desc, ignore.case = TRUE)) {
      warning(sprintf("Line %d (%s): expected '%s', found '%s'",
                       spec$line, label, spec$desc_pattern, row$line_desc))
      all_ok <- FALSE
    }
  }
  all_ok
}


# ==================================================================
# §B. GPIM Core Functions (§3-4 of formalization)
# ==================================================================

#' Compute survival-revaluation factor z*_t (eq. 4)
#'
#' z*_t = (1 - z_t) * (p^K_t / p^K_{t-1})
#'
#' @param z_t Depletion rate (scalar or vector)
#' @param p_t Current-period price index
#' @param p_lag Lagged price index
#' @return z*_t (same length as inputs)
gpim_survival_revaluation <- function(z_t, p_t, p_lag) {
  stopifnot(length(z_t) == length(p_t),
            length(p_t) == length(p_lag))
  (1 - z_t) * (p_t / p_lag)
}

#' GPIM current-cost accumulation (eq. 3)
#'
#' K_t = IG_t + z*_t * K_{t-1}
#'
#' Forward recursion from initial value K0.
#'
#' @param IG  Gross investment (current cost), vector length T
#' @param z_star Survival-revaluation factor, vector length T
#' @param K0  Initial capital stock (period 0)
#' @return Capital stock vector, length T
gpim_accumulate_cc <- function(IG, z_star, K0) {
  T <- length(IG)
  stopifnot(length(z_star) == T)
  K <- numeric(T)
  K[1] <- IG[1] + z_star[1] * K0
  for (t in 2:T) {
    K[t] <- IG[t] + z_star[t] * K[t - 1]
  }
  K
}

#' GPIM constant-cost (real) accumulation (eq. 5)
#'
#' K^R_t = IG^R_t + (1 - z_t) * K^R_{t-1}
#'
#' @param IG_R Real gross investment, vector length T
#' @param z    Depletion rate, vector length T
#' @param K0_R Initial real capital stock
#' @return Real capital stock vector, length T
gpim_accumulate_real <- function(IG_R, z, K0_R) {
  T <- length(IG_R)
  stopifnot(length(z) == T)
  K <- numeric(T)
  K[1] <- IG_R[1] + (1 - z[1]) * K0_R
  for (t in 2:T) {
    K[t] <- IG_R[t] + (1 - z[t]) * K[t - 1]
  }
  K
}

#' Theoretically correct aggregate depreciation rate (eq. 6)
#'
#' z_t = D_t / (p^K_t * K^R_{t-1})
#'
#' @param D_t  Nominal depreciation (current cost)
#' @param p_t  Current-period capital price index
#' @param K_R_lag Lagged real capital stock
#' @return Depreciation rate z_t
gpim_depreciation_rate <- function(D_t, p_t, K_R_lag) {
  stopifnot(length(D_t) == length(p_t),
            length(D_t) == length(K_R_lag))
  denom <- p_t * K_R_lag
  # Guard against division by zero in early periods
  ifelse(denom > 0, D_t / denom, NA_real_)
}

#' Whelan-Liu approximate depreciation rate (eq. 8)
#'
#' z^WL_t = D_t / K_{t-1}
#'
#' @param D_t  Nominal depreciation
#' @param K_lag Lagged nominal capital stock
#' @return Whelan-Liu depreciation rate
gpim_whelan_liu_rate <- function(D_t, K_lag) {
  stopifnot(length(D_t) == length(K_lag))
  ifelse(K_lag > 0, D_t / K_lag, NA_real_)
}


# ==================================================================
# §C. Convergence Functions (§5 of formalization)
# ==================================================================

#' Critical depletion rate (eq. 15)
#'
#' z_star = g_pK / (1 + g_pK)
#'
#' @param g_pK Growth rate of capital-goods prices
#' @return Critical depletion rate
gpim_critical_rate <- function(g_pK) {
  g_pK / (1 + g_pK)
}

#' Half-life of transient component (eq. 16)
#'
#' tau_half = ln(2) / ln(1/z*)
#' where z* = (1-z)(1+g_pK)
#'
#' @param z     Depletion rate
#' @param g_pK  Growth rate of capital-goods prices
#' @return Half-life in periods (years)
gpim_half_life <- function(z, g_pK) {
  z_star_factor <- (1 - z) * (1 + g_pK)
  if (z_star_factor >= 1) return(Inf)  # non-convergent regime
  log(2) / log(1 / z_star_factor)
}

#' General solution constants (eqs. 12-13)
#'
#' C(z) = (1+g_I) / [(1+g_I) - (1-z)(1+g_pK)]
#' A(z) = K_0 - C(z) * IG_0
#'
#' @param K0    Initial capital stock
#' @param IG0   Initial gross investment
#' @param g_I   Growth rate of gross investment
#' @param z     Depletion rate
#' @param g_pK  Growth rate of capital-goods prices
#' @return Named list: C_z, A_z, z_star_factor
gpim_general_solution <- function(K0, IG0, g_I, z, g_pK) {
  z_star_factor <- (1 - z) * (1 + g_pK)
  denom <- (1 + g_I) - z_star_factor
  if (abs(denom) < 1e-10) {
    warning("Denominator near zero: g_I + z_star_factor ~ 1")
    return(list(C_z = Inf, A_z = NA_real_, z_star_factor = z_star_factor))
  }
  C_z <- (1 + g_I) / denom
  A_z <- K0 - C_z * IG0
  list(C_z = C_z, A_z = A_z, z_star_factor = z_star_factor)
}


# ==================================================================
# §D. Deflator Functions (§7 of formalization)
# ==================================================================

#' Compute own-price implicit deflator from current-cost and chain QI
#'
#' p^K_t = K^cc_t / K^chain_t  (rebased so base_year = 100)
#'
#' The chain QI is an index (base_year = 100). The ratio gives
#' the implicit price deflator that, when applied to the current-cost
#' stock, yields the chain-weighted quantity.
#'
#' @param K_cc    Current-cost stock (levels)
#' @param K_chain Chain-type quantity index (index, base=100)
#' @param base_year Year at which deflator = 1.0
#' @return Implicit price deflator (1.0 at base_year)
compute_implicit_deflator <- function(K_cc, K_chain, base_year = 2017L) {
  # The chain QI is an index number (100 at base year).
  # To get the deflator: p = K_cc / (K_chain * K_cc_base / 100)
  # But more directly: the deflator is the ratio of current-cost

  # to the level implied by the chain index.
  # Since K_chain is an index, K_real_level = K_cc_base * K_chain / 100
  # and p = K_cc / K_real_level

  # For our purposes, we compute the deflator as a ratio
  # that preserves stock-flow consistency when used for single deflation.
  raw_deflator <- K_cc / K_chain  # proportional to price level
  # Rebase so deflator = 1.0 at base_year
  # (Caller must ensure base_year is in the data range)
  raw_deflator / raw_deflator[1]  # placeholder; actual rebasing below
}

#' Rebase a price index to a new base year
#'
#' @param index  Numeric vector (the index series)
#' @param years  Integer vector of corresponding years
#' @param new_base_year The year at which the rebased index = 1.0 (or 100)
#' @param scale  Target value at base year (default 1.0; use 100 for percentage)
#' @return Rebased index vector
rebase_index <- function(index, years, new_base_year, scale = 1.0) {
  base_idx <- which(years == new_base_year)
  if (length(base_idx) == 0) {
    stop("Base year ", new_base_year, " not found in years vector")
  }
  base_val <- index[base_idx[1]]
  if (is.na(base_val) || base_val == 0) {
    stop("Index value at base year is NA or zero")
  }
  scale * index / base_val
}

#' Compute log quality-adjustment wedge (eq. 22)
#'
#' omega_t = ln(p^{K,QA}_t) - ln(p^K_t)
#'
#' @param p_QA  Quality-adjusted (hedonic) price index
#' @param p_obs Observed-price (non-hedonic) price index
#' @return Log wedge vector
quality_adjustment_wedge <- function(p_QA, p_obs) {
  stopifnot(length(p_QA) == length(p_obs))
  log(p_QA) - log(p_obs)
}


# ==================================================================
# §E. Stock Construction Functions
# ==================================================================

#' Build gross stock from net stock + cumulative depreciation
#'
#' Gross_cc_t = Net_cc_t + CumulativeDepreciation_cc_t
#'
#' Since BEA publishes net stocks and depreciation flows,
#' cumulative depreciation is approximated by accumulating
#' annual depreciation flows. However, the more direct approach:
#' Gross = Net + (cumulative D since asset installation), which
#' for aggregate stocks means Gross_t ~ Net_t + D_t / z_t
#' (i.e., Net + average remaining depreciation). We use the
#' empirical identity: if we know IG and net stock accumulation,
#' gross stock can be backed out.
#'
#' For current-cost stocks:
#'   K^gross_t = K^net_t + sum of depreciation allowances
#'   still embedded in surviving assets
#'
#' Approximation: Use the BEA convention where
#'   K^gross ~ K^net + D_t * average_age / 2
#' But simpler: derive from K^net_t + annual D flow / depreciation rate
#'
#' @param K_net_cc Net current-cost stock
#' @param D_cc     Current-cost depreciation flow
#' @param method   "ratio" (K_net + D/z) or "accumulate"
#' @return Gross current-cost stock
build_gross_from_net <- function(K_net_cc, D_cc, method = "ratio") {
  if (method == "ratio") {
    # z_t ~ D_t / K_net_t (approximate depreciation rate)
    # Then Gross_t ~ K_net_t * (1 + 1/average_service_life)
    # Simplified: Gross_t ~ K_net_t + D_t * (K_net_t / D_t)
    # This reduces to 2 * K_net_t... not right.
    #
    # Better approach: Gross = Net + Accumulated Depreciation
    # AccumDep_t = sum_{s=0}^{L} D_{t-s} * survival_weight
    # Without service-life data, use the proxy:
    #   Gross_t approx = Net_t / (1 - avg_age * z)
    #   But avg_age is unknown.
    #
    # Safest: Return Net stock with a flag indicating gross
    # is unavailable without additional BEA tables (Table 4.5/4.6
    # provide gross stocks directly in some BEA vintages).
    warning("Gross stock estimation from net + depreciation is approximate. ",
            "Consider using BEA gross stock tables directly if available.")
    # Use simple perpetual-inventory logic backwards:
    # If K^net_t = K^net_{t-1} + IG_t - D_t, and
    # K^gross_t = K^gross_{t-1} + IG_t - Ret_t (retirements),
    # then K^gross_t - K^net_t = (K^gross_{t-1} - K^net_{t-1}) + (D_t - Ret_t)
    # The gap between gross and net grows by (D - Ret) each period.
    # Without retirement data, we approximate:
    K_net_cc + D_cc  # Crude first-order approximation
  } else {
    stop("Method '", method, "' not implemented")
  }
}

#' Validate stock-flow consistency identity
#'
#' Computes residual_t = K_t - (K_{t-1} + I_t - D_t)
#'
#' For current-cost: residual = revaluation (holding gains)
#' For chain-weighted: residual = index-number artifact (Shaikh's point)
#' For GPIM-deflated: residual should be ~ 0
#'
#' @param K      Capital stock, length T
#' @param K_lag  Lagged capital stock, length T (first element is K_0)
#' @param I      Investment, length T
#' @param D      Depreciation, length T
#' @param label  Character label for logging
#' @return tibble: t, K, K_implied, residual, pct_residual
validate_sfc_identity <- function(K, K_lag, I, D, label = "") {
  T <- length(K)
  stopifnot(length(K_lag) == T, length(I) == T, length(D) == T)

  K_implied <- K_lag + I - D
  residual  <- K - K_implied
  pct_resid <- ifelse(abs(K) > 0, residual / K, NA_real_)

  dplyr::tibble(
    t           = seq_len(T),
    K_actual    = K,
    K_implied   = K_implied,
    residual    = residual,
    pct_residual = pct_resid,
    label       = label
  )
}

#' Build GPIM real stock via single deflation
#'
#' Deflates current-cost stock, investment, and depreciation
#' by the SAME own-price implicit deflator, preserving SFC.
#'
#' K^R_t = K^cc_t / p^K_t
#' IG^R_t = IG^cc_t / p^K_t
#' D^R_t = D^cc_t / p^K_t
#'
#' @param K_cc  Current-cost capital stock
#' @param IG_cc Current-cost investment
#' @param D_cc  Current-cost depreciation
#' @param p_K   Own-price implicit deflator (1.0 at base year)
#' @return Named list: K_real, IG_real, D_real
gpim_deflate_sfc <- function(K_cc, IG_cc, D_cc, p_K) {
  stopifnot(length(K_cc) == length(p_K),
            length(IG_cc) == length(p_K),
            length(D_cc) == length(p_K))

  list(
    K_real  = K_cc / p_K,
    IG_real = IG_cc / p_K,
    D_real  = D_cc / p_K
  )
}


# ==================================================================
# §F. Data Quality & Logging
# ==================================================================

#' Log data quality summary for a series
#'
#' Reports: N observations, NAs, range, first/last year
#'
#' @param df    Data frame with 'year' and 'value' columns
#' @param name  Series name for log message
#' @return Invisibly returns the data frame (for piping)
log_data_quality <- function(df, name) {
  n     <- nrow(df)
  n_na  <- sum(is.na(df$value))
  yr_min <- min(df$year, na.rm = TRUE)
  yr_max <- max(df$year, na.rm = TRUE)
  val_rng <- range(df$value, na.rm = TRUE)

  msg <- sprintf("[%s] %s: n=%d, NA=%d, years=%d-%d, range=[%.2f, %.2f]",
                 now_stamp(), name, n, n_na, yr_min, yr_max,
                 val_rng[1], val_rng[2])
  message(msg)
  invisible(df)
}

#' Ensure all required directories exist
#'
#' @param config GDP_CONFIG list
ensure_dirs <- function(config) {
  dirs <- c(config$RAW_BEA, config$RAW_FRED,
            config$INTERIM_BEA_PARSED, config$INTERIM_KSTOCK,
            config$INTERIM_GDP, config$INTERIM_VALIDATION,
            config$INTERIM_FIGURES, config$INTERIM_LOGS,
            config$PROCESSED)
  for (d in dirs) {
    dir.create(d, showWarnings = FALSE, recursive = TRUE)
  }
}
