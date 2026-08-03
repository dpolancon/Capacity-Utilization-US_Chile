library(httr)
BEA_KEY <- Sys.getenv("BEA_API_KEY")
resp <- GET("https://apps.bea.gov/api/data",
  query = list(UserID = BEA_KEY, method = "GetData", datasetname = "NIPA",
    TableName = "T10106", Frequency = "A", Year = "ALL", ResultFormat = "JSON"),
  timeout(120))
payload <- content(resp, as = "parsed", simplifyVector = FALSE)
records <- payload$BEAAPI$Results$Data
## Show unique line_number + line_description combos
df <- data.frame(
  line = vapply(records, function(x) x$LineNumber, character(1)),
  desc = vapply(records, function(x) x$LineDescription, character(1)),
  metric = vapply(records, function(x) x$METRIC_NAME, character(1)),
  stringsAsFactors = FALSE
)
print(unique(df))
