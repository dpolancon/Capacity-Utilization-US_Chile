library(httr)
library(dplyr)
BEA_KEY <- Sys.getenv("BEA_API_KEY")
resp <- GET("https://apps.bea.gov/api/data",
  query = list(UserID = BEA_KEY, method = "GetData", datasetname = "NIPA",
    TableName = "T10106", Frequency = "A", Year = "ALL", ResultFormat = "JSON"),
  timeout(120))
payload <- content(resp, as = "parsed", simplifyVector = FALSE)
records <- payload$BEAAPI$Results$Data
years_raw <- vapply(records, function(x) x$TimePeriod, character(1))
years_num <- suppressWarnings(as.integer(years_raw))
descs <- vapply(records, function(x) x$LineDescription, character(1))
vals <- suppressWarnings(as.numeric(vapply(records, function(x) x$DataValue, character(1))))
df <- data.frame(year = years_num, line_description = descs, value = vals, stringsAsFactors = FALSE)
df <- df |> filter(!is.na(year) & !is.na(value))
cat(sprintf("After filter: %d rows, %d unique descs\n", nrow(df), length(unique(df$line_description))))
## Try extracting line 1
row1 <- df |> filter(line_description == "Gross domestic product")
cat(sprintf("GDP rows: %d, years %d-%d\n", nrow(row1), min(row1$year), max(row1$year)))
cat(sprintf("Last GDP value: %.1f\n", tail(row1$value, 1)))
