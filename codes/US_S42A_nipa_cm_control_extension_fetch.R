#!/usr/bin/env Rscript

# US_S42A_nipa_cm_control_extension_fetch.R
#
# Extends the demand-control variables back to 1929 by fetching:
# 1. NIPA T10105 (nominal GDP and components, current dollars, annual)
#    - Y_nominal (Gross domestic product, Line 1)
#    - C_nominal (Personal consumption expenditures, Line 2)
#    - M_nominal (Imports, Line 18)
#    Constructs nominal shares: C_share_nom, M_share_nom, net_C_share_nom
#
# 2. NIPA T10106 (real GDP and components, chained dollars, annual)
#    - C_real_nipa, M_real_nipa
#    Constructs log spread: cm_t = log(C_real_nipa) - log(M_real_nipa)
#
# Governance: Strictly enforces nominal expenditure shares (NIPA T1.1.5)
# vs real chained log levels (NIPA T1.1.6).

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(httr)
  library(dplyr)
  library(tseries)
})

# Load user Renviron if BEA_API_KEY is not in active env
if (!nzchar(Sys.getenv("BEA_API_KEY"))) {
  if (file.exists("C:/Users/User/.Renviron")) readRenviron("C:/Users/User/.Renviron")
}

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir <- file.path(repo_root, "output", "US", "S42_CM_EXTENSION")
csv_dir <- file.path(out_dir, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

fred_csv <- file.path(repo_root, "output", "US",
  "S15C_FRED_DEMAND_CONTROL_COINTEGRATION", "csv",
  "fred_ad_components_panel.csv")
raw_cache_t10106 <- file.path(csv_dir, "s42a_nipa_t10106_raw_cache.csv")
raw_cache_t10105 <- file.path(csv_dir, "s42a_nipa_t10105_raw_cache.csv")

diagnostic_stamp <- "DIAGNOSTIC_ONLY;S42_BRANCH"

cat("========================================================================\n")
cat("S42A: NIPA T10105 (Nominal Shares) & T10106 (Real Levels) Extension to 1929\n")
cat("========================================================================\n")

BEA_KEY <- Sys.getenv("BEA_API_KEY")

fetch_bea_table <- function(table_name, cache_file) {
  if (file.exists(cache_file)) {
    cat(sprintf("Using cached %s pull: %s\n", table_name, cache_file))
    return(read.csv(cache_file, stringsAsFactors = FALSE))
  } else {
    if (!nzchar(BEA_KEY)) stop(sprintf("BEA_API_KEY is not set and no cache exists for %s.", table_name))
    resp <- GET(
      "https://apps.bea.gov/api/data",
      query = list(UserID = BEA_KEY, method = "GetData", datasetname = "NIPA",
                   TableName = table_name, Frequency = "A", Year = "ALL",
                   ResultFormat = "JSON"),
      timeout(120)
    )
    stop_for_status(resp)
    payload <- content(resp, as = "parsed", simplifyVector = FALSE)
    records <- payload$BEAAPI$Results$Data
    if (is.null(records) || length(records) == 0L) stop(sprintf("No data for %s.", table_name))
    
    df <- do.call(rbind, lapply(records, function(x) {
      data.frame(
        year = suppressWarnings(as.integer(x$TimePeriod)),
        line_number = suppressWarnings(as.integer(x$LineNumber)),
        line_description = as.character(x$LineDescription),
        series_code = as.character(x$SeriesCode),
        value = suppressWarnings(as.numeric(gsub(",", "", x$DataValue))),
        stringsAsFactors = FALSE
      )
    }))
    df <- df[!is.na(df$year) & !is.na(df$value), ]
    write.csv(df, cache_file, row.names = FALSE)
    cat(sprintf("Fetched and cached %s: %d rows\n", table_name, nrow(df)))
    return(df)
  }
}

t10105 <- fetch_bea_table("T10105", raw_cache_t10105)
t10106 <- fetch_bea_table("T10106", raw_cache_t10106)

pick_line <- function(tab, label) {
  sub <- tab[tab$line_description == label, c("year", "value")]
  if (nrow(sub) > length(unique(sub$year))) {
    ln <- min(tab$line_number[tab$line_description == label], na.rm = TRUE)
    sub <- tab[tab$line_description == label & tab$line_number == ln, c("year", "value")]
  }
  sub[order(sub$year), ]
}

## Extract Nominal Series (T10105)
Y_nom <- pick_line(t10105, "Gross domestic product")
C_nom <- pick_line(t10105, "Personal consumption expenditures")
M_nom <- pick_line(t10105, "Imports")

names(Y_nom) <- c("year", "Y_nominal_gdp")
names(C_nom) <- c("year", "C_nominal_nipa")
names(M_nom) <- c("year", "M_nominal_nipa")

## Extract Real Series (T10106)
C_real <- pick_line(t10106, "Personal consumption expenditures")
M_real <- pick_line(t10106, "Imports")

names(C_real) <- c("year", "C_real_nipa")
names(M_real) <- c("year", "M_real_nipa")

## Merge panels
cm <- merge(Y_nom, C_nom, by = "year", all = TRUE)
cm <- merge(cm, M_nom, by = "year", all = TRUE)
cm <- merge(cm, C_real, by = "year", all = TRUE)
cm <- merge(cm, M_real, by = "year", all = TRUE)

cm <- cm[order(cm$year), ]
cm <- cm[!is.na(cm$year), ]

## Construct Nominal Shares (Strict NIPA Standard: Nominal / Nominal Total GDP)
cm$c_share_nom <- cm$C_nominal_nipa / cm$Y_nominal_gdp
cm$m_share_nom <- cm$M_nominal_nipa / cm$Y_nominal_gdp
cm$net_c_share_nom <- (cm$C_nominal_nipa - cm$M_nominal_nipa) / cm$Y_nominal_gdp

## Construct Real Log Spread
cm$cm_t <- log(cm$C_real_nipa) - log(cm$M_real_nipa)
cm$cm_lag1 <- dplyr::lag(cm$cm_t, 1L)
cm$stamp <- diagnostic_stamp

cat(sprintf("Extended cm control: %d obs, %d-%d\n", nrow(cm), min(cm$year), max(cm$year)))

## Consistency overlap vs FRED
fred <- read.csv(fred_csv, stringsAsFactors = FALSE)
fred$cm_fred <- log(fred$C_real) - log(fred$M_real)
ov <- merge(cm[, c("year", "cm_t")], fred[, c("year", "cm_fred")], by = "year")

overlap <- data.frame(
  n_overlap_years = nrow(ov),
  overlap_start = min(ov$year), overlap_end = max(ov$year),
  corr_levels = cor(ov$cm_t, ov$cm_fred),
  corr_first_diff = cor(diff(ov$cm_t), diff(ov$cm_fred)),
  mean_abs_diff_levels = mean(abs(ov$cm_t - ov$cm_fred)),
  mean_abs_diff_first_diff = mean(abs(diff(ov$cm_t) - diff(ov$cm_fred))),
  note = "Level offsets between chained indexes are absorbed by per-window anchoring.",
  stamp = diagnostic_stamp
)

## Stationarity tests
test_windows <- list(
  full_1929_2024 = c(1929, 2024),
  fordism_1929_1973 = c(1929, 1973),
  post_fordism_1974_2024 = c(1974, 2024)
)

stat_rows <- lapply(names(test_windows), function(nm) {
  rg <- test_windows[[nm]]
  z <- cm$cm_t[cm$year >= rg[1] & cm$year <= rg[2]]
  z <- z[!is.na(z)]
  adf <- tryCatch(suppressWarnings(tseries::adf.test(z)), error = function(e) NULL)
  kpss <- tryCatch(suppressWarnings(tseries::kpss.test(z, null = "Level")), error = function(e) NULL)
  adf_p <- if (is.null(adf)) NA else adf$p.value
  kpss_p <- if (is.null(kpss)) NA else kpss$p.value
  verdict <- if (!is.na(adf_p) && !is.na(kpss_p)) {
    if (adf_p <= 0.10 && kpss_p > 0.05) "I0_supported"
    else if (adf_p > 0.10 && kpss_p <= 0.05) "I1_indicated"
    else "mixed_evidence"
  } else "test_unavailable"
  data.frame(window = nm, n_obs = length(z),
             adf_stat = if (is.null(adf)) NA else unname(adf$statistic),
             adf_p = adf_p,
             kpss_stat = if (is.null(kpss)) NA else unname(kpss$statistic),
             kpss_p = kpss_p,
             verdict = verdict, stamp = diagnostic_stamp)
})
stationarity <- do.call(rbind, stat_rows)

## Save outputs
write.csv(cm, file.path(csv_dir, "s42a_extended_cm_control_panel.csv"), row.names = FALSE)
write.csv(overlap, file.path(csv_dir, "s42a_overlap_consistency_check.csv"), row.names = FALSE)
write.csv(stationarity, file.path(csv_dir, "s42a_stationarity_verdicts.csv"), row.names = FALSE)

cat("\nS42A complete. Extended nominal and real demand panel written to:",
    file.path(csv_dir, "s42a_extended_cm_control_panel.csv"), "\n")
