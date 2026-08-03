library(httr)
BEA_KEY <- Sys.getenv("BEA_API_KEY")
resp <- GET("https://apps.bea.gov/api/data",
  query = list(UserID = BEA_KEY, method = "GetData", datasetname = "NIPA",
    TableName = "T10110", Frequency = "A", Year = "ALL", ResultFormat = "JSON"),
  timeout(120))
payload <- content(resp, as = "parsed", simplifyVector = FALSE)
records <- payload$BEAAPI$Results$Data
print(head(records, 3))
print(class(records[[1]]$TimePeriod))
print(records[[1]]$TimePeriod)
