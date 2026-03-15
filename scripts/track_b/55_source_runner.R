############################################################
# 55_source_runner.R — Sequential runner for the 50-series
#                       Corporate Sector Extension pipeline
#
# Executes scripts 50–54 in dependency order.
# Produces: data/processed/corporate_sector_dataset.csv
#
# Usage:
#   Rscript codes/55_source_runner.R
#
# Each script is run in a clean environment via source().
# If any script fails, the runner stops and reports the error.
############################################################

cat("============================================================\n")
cat("  50-SERIES PIPELINE RUNNER\n")
cat("  Corporate Sector Extension\n")
cat(sprintf("  Started: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat("============================================================\n\n")

## Pipeline scripts in dependency order
scripts_50 <- c(
  "codes/50_fetch_bea_corporate.R",        # Fetch BEA FA by legal form + NIPA + FRED Py
  "codes/51_build_corp_output.R",          # Build GVAcorp, VAcorp, NOScorp, ECcorp
  "codes/52_build_corp_kstock.R",          # Build KGCcorp, KNCcorp (GPIM + 3 adjustments)
  "codes/53_build_corp_exploitation.R",    # Build exploit_rate, profit_share, rcorp
  "codes/54_assemble_corp_dataset.R"       # Merge + validate → corporate_sector_dataset.csv
)

t_start <- Sys.time()
results <- list()

for (i in seq_along(scripts_50)) {
  script <- scripts_50[i]
  label  <- basename(script)

  cat(sprintf("\n[%d/%d] %s\n", i, length(scripts_50), label))
  cat(paste(rep("-", 60), collapse = ""), "\n")

  if (!file.exists(script)) {
    cat(sprintf("  SKIP: file not found — %s\n", script))
    results[[label]] <- list(status = "SKIP", time = 0, error = "file not found")
    next
  }

  t0 <- Sys.time()

  status <- tryCatch({
    source(script, local = new.env(parent = globalenv()))
    "OK"
  }, error = function(e) {
    cat(sprintf("\n  *** ERROR in %s ***\n  %s\n", label, conditionMessage(e)))
    paste0("FAIL: ", conditionMessage(e))
  })

  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  results[[label]] <- list(status = status, time = elapsed, error = NA)

  cat(sprintf("  [%s] %.1f sec\n", status, elapsed))

  ## Stop on failure
  if (!startsWith(status, "OK")) {
    cat(sprintf("\n*** PIPELINE HALTED at %s ***\n", label))
    break
  }
}

## ----------------------------------------------------------
## Post-run: verify final deliverable
## ----------------------------------------------------------

final_csv <- "data/processed/corporate_sector_dataset.csv"
csv_exists <- file.exists(final_csv)

if (csv_exists) {
  df <- readr::read_csv(final_csv, show_col_types = FALSE)
  cat(sprintf("\n  Final dataset: %s\n", final_csv))
  cat(sprintf("  Rows: %d | Columns: %d | Years: %d-%d\n",
              nrow(df), ncol(df), min(df$year), max(df$year)))

  required <- c("year", "GVAcorp", "KGCcorp", "Py", "exploit_rate", "uK")
  missing  <- setdiff(required, names(df))
  if (length(missing) > 0) {
    cat(sprintf("  WARNING: Missing columns: %s\n", paste(missing, collapse = ", ")))
  } else {
    cat("  All required columns present.\n")
  }
}

## ----------------------------------------------------------
## Summary
## ----------------------------------------------------------

elapsed_total <- as.numeric(difftime(Sys.time(), t_start, units = "secs"))

cat("\n\n============================================================\n")
cat("  50-SERIES PIPELINE SUMMARY\n")
cat("============================================================\n")
cat(sprintf("%-40s  %6s  %8s\n", "Script", "Status", "Time (s)"))
cat(paste(rep("-", 60), collapse = ""), "\n")

for (label in names(results)) {
  r <- results[[label]]
  st <- if (startsWith(r$status, "OK")) "OK" else
        if (r$status == "SKIP") "SKIP" else "FAIL"
  cat(sprintf("%-40s  %6s  %8.1f\n", label, st, r$time))
}

cat(paste(rep("-", 60), collapse = ""), "\n")
cat(sprintf("Total elapsed: %.1f sec\n", elapsed_total))
cat(sprintf("Finished: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))

n_ok   <- sum(sapply(results, function(r) startsWith(r$status, "OK")))
n_fail <- sum(sapply(results, function(r) startsWith(r$status, "FAIL")))
n_skip <- sum(sapply(results, function(r) r$status == "SKIP"))

cat(sprintf("\nResult: %d OK, %d FAIL, %d SKIP out of %d scripts\n",
            n_ok, n_fail, n_skip, length(scripts_50)))

if (n_fail > 0) {
  cat("\n*** PIPELINE FAILED — see errors above ***\n")
  quit(status = 1)
} else if (csv_exists) {
  cat("\n*** PIPELINE COMPLETE ***\n")
  cat(sprintf("  Deliverable: %s\n", final_csv))
  cat("  Ready for: Rscript codes/20_S0_shaikh_faithful.R\n")
} else {
  cat("\n*** WARNING: Pipeline finished but final CSV not found ***\n")
  quit(status = 1)
}
