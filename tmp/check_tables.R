library(httr)
BEA_KEY <- Sys.getenv("BEA_API_KEY")
for (tbl in c("T10105", "T10103")) {
  resp <- GET("https://apps.bea.gov/api/data",
    query = list(UserID = BEA_KEY, method = "GetData", datasetname = "NIPA",
      TableName = tbl, Frequency = "A", Year = "ALL", ResultFormat = "JSON"),
    timeout(120))
  payload <- content(resp, as = "parsed", simplifyVector = FALSE)
  records <- payload$BEAAPI$Results$Data
  descs <- unique(vapply(records, function(x) x$LineDescription, character(1)))
  cat(sprintf("\n=== %s (%d rows) ===\n", tbl, length(records)))
  cat(paste0(descs, collapse = "\n"))
}
