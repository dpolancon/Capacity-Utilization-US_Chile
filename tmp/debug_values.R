library(httr)
BEA_KEY <- Sys.getenv("BEA_API_KEY")
resp <- GET("https://apps.bea.gov/api/data",
  query = list(UserID = BEA_KEY, method = "GetData", datasetname = "NIPA",
    TableName = "T10106", Frequency = "A", Year = "ALL", ResultFormat = "JSON"),
  timeout(120))
payload <- content(resp, as = "parsed", simplifyVector = FALSE)
records <- payload$BEAAPI$Results$Data
## Check first 5 records
for (i in 1:5) {
  cat(sprintf("Record %d: TimePeriod=%s, DataValue=%s, LineDesc=%s\n",
              i, records[[i]]$TimePeriod, records[[i]]$DataValue, records[[i]]$LineDescription))
}
## Check how many have numeric DataValue
vals_raw <- vapply(records, function(x) x$DataValue, character(1))
vals_num <- suppressWarnings(as.numeric(vals_raw))
cat(sprintf("\nNumeric values: %d / %d\n", sum(!is.na(vals_num)), length(vals_num)))
## Show non-numeric values
non_num <- vals_raw[is.na(vals_num)]
cat(sprintf("Non-numeric values: %s\n", paste(unique(non_num), collapse = ", ")))
