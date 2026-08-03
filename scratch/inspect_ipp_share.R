repo_root <- getwd()
path <- file.path(repo_root, "data/releases/chapter2_us_source_of_truth_v1/README.md")
cat("File path:", path, "\n")
cat("File exists:", file.exists(path), "\n")

# Hash raw
out_raw <- system2("certutil", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
cat("Raw hash from certutil:\n")
print(out_raw)

# Normalization test
lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
temp_file <- tempfile()
con <- file(temp_file, "wb")
writeLines(lines, con, sep = "\n", useBytes = TRUE)
close(con)

out_norm <- system2("certutil", c("-hashfile", shQuote(temp_file), "SHA256"), stdout = TRUE)
cat("Normalized hash from certutil:\n")
print(out_norm)
unlink(temp_file)
