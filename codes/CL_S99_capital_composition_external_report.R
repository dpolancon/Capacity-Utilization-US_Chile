#!/usr/bin/env Rscript

# Chile Stage S99 — report integrity, compilation, and build manifest.

suppressPackageStartupMessages({
  library(digest)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
report_dir <- file.path(root, "reports", "Chile_Capital_Composition_Integrated_Report")
tex <- file.path(report_dir, "chile_capital_composition_integrated_report.tex")
pdf <- file.path(report_dir, "chile_capital_composition_integrated_report.pdf")
out <- file.path(root, "output", "CL", "S99_REPORT_ASSEMBLY")
dir.create(out, recursive = TRUE, showWarnings = FALSE)

required <- c(
  file.path(root, "data", "raw", "Chile", "WBOP",
            "NievasPiketty2025WBOPFinalSeries.xlsx"),
  file.path(root, "data", "processed", "CL", "S10_SOURCE_PANEL",
            "chile_wbop_capital_annual_1920_2024.csv"),
  file.path(root, "output", "CL", "S10_SOURCE_PANEL",
            "source_provenance_sha256.csv"),
  file.path(root, "output", "CL", "S10_SOURCE_PANEL",
            "wbop_accounting_identity_audit.csv"),
  file.path(root, "output", "CL", "S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY",
            "capital_window_integration_test_ledger.csv"),
  file.path(root, "output", "CL", "S30_CHOICE_TECHNIQUE_BOP",
            "capital_model_ledger.csv"),
  file.path(root, "output", "CL", "S90_WBOP_EVENT_ROBUSTNESS",
            "complete_specification_space_map.csv"),
  tex
)
stopifnot(all(file.exists(required)))

lines <- readLines(tex, warn = FALSE, encoding = "UTF-8")
text <- paste(lines, collapse = "\n")
table_lines <- grep("\\\\begin\\{table\\}", lines, value = TRUE)
figure_lines <- grep("\\\\begin\\{figure\\}", lines, value = TRUE)
section_count <- length(grep("^\\\\section\\*?\\{", lines))
barrier_count <- length(grep("^\\\\FloatBarrier", lines))
panel <- read.csv(file.path(root, "data", "processed", "CL", "S10_SOURCE_PANEL",
                            "chile_wbop_capital_annual_1920_2024.csv"))
models <- read.csv(file.path(root, "output", "CL",
                             "S30_CHOICE_TECHNIQUE_BOP",
                             "capital_model_ledger.csv"))
short_boot <- read.csv(file.path(root, "output", "CL",
                                 "S90_WBOP_EVENT_ROBUSTNESS",
                                 "short_sample_bootstrap_requirement_ledger.csv"))

checks <- data.frame(
  check = c(
    "No legacy tau notation",
    "No legacy gamma cointegrating notation",
    "No NRC capital notation",
    "No Markdown bold in LaTeX",
    "All tables use H or h! floats",
    "Exactly three central tables",
    "Exactly six principal figures",
    "FloatBarrier precedes every section",
    "A4 U.S.-template geometry and no table of contents",
    "Figure and table captions configured above",
    "No BCCh source in replacement report",
    "No artificial phi, F_avail, or mu estimate",
    "Canonical capital panel has 105 complete observations",
    "No model estimated after a failed integration gate",
    "Central model ledger contains the complete report interface",
    "Short blocked samples retain the 999-replication requirement",
    "All required ledgers present"
  ),
  passed = c(
    !grepl("\\\\tau", text),
    !grepl("\\\\gamma", text),
    !grepl("NRC", text),
    !grepl("\\*\\*", text),
    length(table_lines) > 0 &&
      all(grepl("\\\\begin\\{table\\}\\[(H|h!)\\]", table_lines)),
    length(table_lines) == 3L,
    length(figure_lines) == 6L,
    barrier_count >= section_count,
    grepl("\\\\documentclass\\[11pt,a4paper\\]", text) &&
      grepl("\\\\usepackage\\[margin=0\\.8in\\]\\{geometry\\}", text) &&
      !grepl("\\\\tableofcontents", text),
    grepl("\\\\captionsetup\\[figure\\]\\{position=top", text) &&
      grepl("\\\\captionsetup\\[table\\]\\{position=top", text),
    !grepl("BCCh|Banco Central de Chile", text, ignore.case = TRUE),
    !grepl("\\\\hat\\{\\\\phi|\\\\hat\\{F|\\\\hat\\{\\\\mu", text),
    nrow(panel) == 105L &&
      sum(is.finite(panel$k_me)) == 105L &&
      sum(is.finite(panel$k_nr)) == 105L,
    all(models$integration_gate == "failed") &&
      all(models$disposition == "blocked"),
    all(c(
      "specification_id", "sample", "n", "rank_5pct", "beta_me",
      "alpha_nr", "alpha_me", "bootstrap_required",
      "bootstrap_executed", "bootstrap_p_value", "serial_p_value",
      "normality_p_value", "maximum_companion_root", "stable",
      "disposition"
    ) %in% names(models)) &&
      all(models$n == models$end_year - models$start_year + 1L),
    all(short_boot$required_replications == 999L) &&
      all(!short_boot$model_eligible),
    all(file.exists(required))
  ),
  stringsAsFactors = FALSE
)
write.csv(checks, file.path(out, "report_integrity_checks.csv"), row.names = FALSE)
if (!all(checks$passed)) {
  print(checks)
  stop("Report integrity checkpoint failed.")
}

old <- setwd(report_dir)
on.exit(setwd(old), add = TRUE)
args <- c("-interaction=nonstopmode", "-halt-on-error",
          "chile_capital_composition_integrated_report.tex")
log1 <- system2("pdflatex", args = args, stdout = TRUE, stderr = TRUE)
status1 <- attr(log1, "status")
if (is.null(status1)) status1 <- 0L
writeLines(log1, file.path(out, "pdflatex_pass1.log"), useBytes = TRUE)
if (status1 != 0L) stop("First LaTeX pass failed.")
log2 <- system2("pdflatex", args = args, stdout = TRUE, stderr = TRUE)
status2 <- attr(log2, "status")
if (is.null(status2)) status2 <- 0L
writeLines(log2, file.path(out, "pdflatex_pass2.log"), useBytes = TRUE)
if (status2 != 0L || !file.exists(pdf)) stop("Final LaTeX pass failed.")

pdf_info <- system2("pdfinfo", args = shQuote(pdf), stdout = TRUE, stderr = TRUE)
page_line <- grep("^Pages:", pdf_info, value = TRUE)
size_line <- grep("^Page size:", pdf_info, value = TRUE)
page_count <- if (length(page_line) == 1L) {
  as.integer(trimws(sub("^Pages:", "", page_line)))
} else {
  NA_integer_
}
is_a4 <- length(size_line) == 1L &&
  grepl("A4|595\\.27[0-9].*841\\.89", size_line, ignore.case = TRUE)
layout_checks <- data.frame(
  check = c("Compiled report is 8--10 pages", "Compiled report is A4"),
  value = c(as.character(page_count), if (is_a4) size_line else "not A4"),
  passed = c(is.finite(page_count) && page_count >= 8L && page_count <= 10L,
             is_a4),
  stringsAsFactors = FALSE
)
write.csv(layout_checks, file.path(out, "compiled_pdf_layout_checks.csv"),
          row.names = FALSE)
if (!all(layout_checks$passed)) {
  print(layout_checks)
  stop("Compiled PDF layout checkpoint failed.")
}

manifest <- data.frame(
  artifact = normalizePath(c(tex, pdf), winslash = "/", mustWork = TRUE),
  bytes = file.info(c(tex, pdf))$size,
  sha256 = vapply(c(tex, pdf), digest, character(1),
                  algo = "sha256", file = TRUE),
  built_utc = format(Sys.time(), tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ"),
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(out, "report_build_manifest.csv"), row.names = FALSE)

message("CL S99 complete: replacement report compiled and manifested.")
