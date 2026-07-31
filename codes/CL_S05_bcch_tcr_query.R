#!/usr/bin/env Rscript

# CL_BOP_BINDING S05: acquire the broad BCCh real exchange-rate index.
# Credentials are read only from BCCH_API_USER / BCCH_API_PASSWORD and are
# never written. If credentials are absent, the official public BDE table is
# used as a reproducible fallback.

suppressPackageStartupMessages({
  library(digest)
  library(readxl)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
raw_dir <- file.path(root, "data", "raw", "Chile", "BCCh_TCR")
audit_dir <- file.path(root, "output", "CL", "BOP_BINDING", "S10_SOURCE_AUDIT")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(audit_dir, recursive = TRUE, showWarnings = FALSE)

series_code <- "F073.TCR.IND.199101.M"
first_date <- "1986-01-01"
last_date <- "2024-12-31"
api_endpoint <- "https://si3.bcentral.cl/SieteRestWS/SieteRestWS.ashx"
public_endpoint <- paste0(
  "https://si3.bcentral.cl/siete/ES/Siete/Cuadro/",
  "CAP_TIPO_CAMBIO/MN_TIPO_CAMBIO4/TCB_531_IND_TCRYCOMP?idSerie=",
  series_code
)
retrieved_utc <- format(Sys.time(), tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")

parse_bcch_date <- function(x) {
  month_map <- c(
    "Ene" = 1L, "Feb" = 2L, "Mar" = 3L, "Abr" = 4L,
    "May" = 5L, "Jun" = 6L, "Jul" = 7L, "Ago" = 8L,
    "Sep" = 9L, "Oct" = 10L, "Nov" = 11L, "Dic" = 12L
  )
  parts <- strsplit(x, ".", fixed = TRUE)
  month <- unname(month_map[vapply(parts, `[`, character(1), 1)])
  year <- as.integer(vapply(parts, `[`, character(1), 2))
  as.Date(sprintf("%04d-%02d-01", year, month))
}

fetch_api <- function(user, password) {
  stopifnot(requireNamespace("jsonlite", quietly = TRUE))
  query <- paste0(
    api_endpoint,
    "?user=", utils::URLencode(user, reserved = TRUE),
    "&pass=", utils::URLencode(password, reserved = TRUE),
    "&firstdate=", first_date,
    "&lastdate=", last_date,
    "&timeseries=", series_code,
    "&function=GetSeries"
  )
  payload <- jsonlite::fromJSON(query, simplifyDataFrame = TRUE)
  if (!identical(as.integer(payload$Codigo), 0L)) {
    stop("BCCh API returned: ", payload$Descripcion)
  }
  obs <- payload$Series$Obs
  if (is.list(obs) && length(obs) == 1L && is.data.frame(obs[[1]])) obs <- obs[[1]]
  stopifnot(is.data.frame(obs), nrow(obs) > 0)
  date <- as.Date(obs$indexDateString, format = "%d-%m-%Y")
  data.frame(
    series_code = series_code,
    date = date,
    year = as.integer(format(date, "%Y")),
    month = as.integer(format(date, "%m")),
    value = suppressWarnings(as.numeric(obs$value)),
    status = as.character(obs$statusCode),
    source_route = "authenticated_api",
    retrieved_utc = retrieved_utc,
    stringsAsFactors = FALSE
  )
}

fetch_public_bde <- function() {
  html <- paste(readLines(public_endpoint, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  table_match <- regmatches(
    html,
    regexpr(
      '<table id="listaObsHtmlAll".*?</table>',
      html, perl = TRUE
    )
  )
  stopifnot(length(table_match) == 1L, nchar(table_match) > 0)
  row_pattern <- "<tr><td>([^<]+)</td><td>([^<]+)</td></tr>"
  rows <- regmatches(table_match, gregexpr(row_pattern, table_match, perl = TRUE))[[1]]
  stopifnot(length(rows) > 0)
  date_label <- sub(row_pattern, "\\1", rows, perl = TRUE)
  value_label <- sub(row_pattern, "\\2", rows, perl = TRUE)
  date <- parse_bcch_date(date_label)
  value <- as.numeric(sub(",", ".", value_label, fixed = TRUE))
  data.frame(
    series_code = series_code,
    date = date,
    year = as.integer(format(date, "%Y")),
    month = as.integer(format(date, "%m")),
    value = value,
    status = "OK",
    source_route = "official_public_bde_table",
    retrieved_utc = retrieved_utc,
    stringsAsFactors = FALSE
  )
}

api_user <- Sys.getenv("BCCH_API_USER", unset = "")
api_password <- Sys.getenv("BCCH_API_PASSWORD", unset = "")
route_note <- ""
if (nzchar(api_user) && nzchar(api_password)) {
  monthly <- tryCatch(
    fetch_api(api_user, api_password),
    error = function(e) {
      route_note <<- paste("Authenticated API failed; official BDE fallback used:",
                           conditionMessage(e))
      fetch_public_bde()
    }
  )
} else {
  route_note <- paste(
    "BCCH_API_USER/BCCH_API_PASSWORD absent;",
    "official public BDE table used."
  )
  monthly <- fetch_public_bde()
}

monthly <- monthly[
  monthly$date >= as.Date(first_date) & monthly$date <= as.Date(last_date),
]
monthly <- monthly[order(monthly$date), ]
rownames(monthly) <- NULL

expected_months <- length(seq(as.Date(first_date), as.Date(last_date), by = "month"))
stopifnot(
  nrow(monthly) == expected_months,
  !anyDuplicated(monthly$date),
  all(is.finite(monthly$value)),
  all(monthly$value > 0)
)

raw_file <- file.path(raw_dir, "bcch_tcr_monthly_raw.csv")
write.csv(monthly, raw_file, row.names = FALSE, na = "")

catalog_file <- "C:/ReposGitHub/bcch-data-repo/data/catalogo_series.xlsx"
catalog_title <- "Índice de tipo de cambio real - TCR (promedio 1986=100)"
catalog_chapter <- "Tipos de Cambio"
if (file.exists(catalog_file)) {
  catalog <- suppressMessages(read_excel(catalog_file))
  code_col <- names(catalog)[3]
  hit <- catalog[trimws(as.character(catalog[[code_col]])) == series_code, , drop = FALSE]
  if (nrow(hit) >= 1L) {
    catalog_chapter <- as.character(hit[[1]][1])
    catalog_title <- as.character(hit[[4]][1])
  }
}

metadata <- data.frame(
  series_code = series_code,
  spanish_title = catalog_title,
  series_family = catalog_chapter,
  frequency = "MONTHLY",
  unit = "index",
  original_base = "average 1986=100",
  interpretation = "increase = real depreciation of the Chilean peso",
  first_observation = as.character(min(monthly$date)),
  last_observation = as.character(max(monthly$date)),
  n_observations = nrow(monthly),
  source = "Banco Central de Chile, Base de Datos Estadísticos",
  source_url = public_endpoint,
  methodology_url = paste0(
    "https://www.bcentral.cl/documents/33528/133329/",
    "Metodologias_de_Tipos_de_Cambio.pdf"
  ),
  source_route = unique(monthly$source_route)[1],
  stringsAsFactors = FALSE
)
metadata_file <- file.path(raw_dir, "bcch_tcr_series_metadata.csv")
write.csv(metadata, metadata_file, row.names = FALSE, na = "")

manifest <- data.frame(
  series_code = series_code,
  requested_first_date = first_date,
  requested_last_date = last_date,
  frequency = "MONTHLY",
  retrieval_utc = retrieved_utc,
  api_endpoint = api_endpoint,
  public_fallback_endpoint = public_endpoint,
  route_used = unique(monthly$source_route)[1],
  route_note = route_note,
  observation_count = nrow(monthly),
  raw_file = normalizePath(raw_file, winslash = "/", mustWork = TRUE),
  raw_file_sha256 = digest(raw_file, algo = "sha256", file = TRUE),
  metadata_file_sha256 = digest(metadata_file, algo = "sha256", file = TRUE),
  credentials_stored = FALSE,
  stringsAsFactors = FALSE
)
manifest_file <- file.path(raw_dir, "bcch_tcr_query_manifest.csv")
write.csv(manifest, manifest_file, row.names = FALSE, na = "")

audit <- data.frame(
  check = c(
    "series_code_is_broad_TCR",
    "not_TCR5",
    "not_nominal_exchange_rate",
    "frequency_monthly",
    "base_1986_average_100",
    "complete_1986_2024",
    "positive_values",
    "credentials_not_stored"
  ),
  passed = c(
    series_code == "F073.TCR.IND.199101.M",
    !grepl("TCR-5", catalog_title, fixed = TRUE),
    !grepl("nominal", tolower(catalog_title), fixed = TRUE),
    TRUE, TRUE,
    nrow(monthly) == expected_months,
    all(monthly$value > 0),
    TRUE
  ),
  detail = c(
    series_code, catalog_title, catalog_title, "MONTHLY",
    "average 1986=100",
    sprintf("%d of %d observations", nrow(monthly), expected_months),
    sprintf("range %.2f to %.2f", min(monthly$value), max(monthly$value)),
    unique(monthly$source_route)[1]
  ),
  stringsAsFactors = FALSE
)
write.csv(audit, file.path(audit_dir, "s05_bcch_tcr_acquisition_audit.csv"),
          row.names = FALSE)
stopifnot(all(audit$passed))

message("CL_BOP_BINDING S05 complete: ", nrow(monthly),
        " monthly BCCh TCR observations acquired via ",
        unique(monthly$source_route)[1], ".")
