library(httr)
BEA_KEY <- Sys.getenv("BEA_API_KEY")
resp <- GET("https://apps.bea.gov/api/data",
  query = list(UserID = BEA_KEY, method = "GetData", datasetname = "NIPA",
    TableName = "T10106", Frequency = "A", Year = "ALL", ResultFormat = "JSON"),
  timeout(120))
payload <- content(resp, as = "parsed", simplifyVector = FALSE)
records <- payload$BEAAPI$Results$Data
cat(sprintf("Total records: %d\n", length(records)))
years_raw <- vapply(records, function(x) x$TimePeriod, character(1))
years_num <- suppressWarnings(as.integer(years_raw))
cat(sprintf("Parsed as integer: %d / %d\n", sum(!is.na(years_num)), length(years_num)))
cat(sprintf("Unique years: %d\n", length(unique(years_num[!is.na(years_num)]))))
cat(sprintf("Year range: %d - %d\n", min(years_num, na.rm=TRUE), max(years_num, na.rm=TRUE)))
## Check which line descriptions have valid years
df <- data.frame(year = years_num, desc = vapply(records, function(x) x$LineDescription, character(1)),
                 stringsAsFactors = FALSE)
valid <- df[!is.na(df$year), ]
cat(sprintf("Valid rows: %d\n", nrow(valid)))
cat(sprintf("Unique descs with valid years: %d\n", length(unique(valid$desc))))
print(unique(valid$desc))
