#!/usr/bin/env Rscript

# S99: assemble, compile, render, and validate the definitive Chile report.

source("C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_SBVECM_common.R")

report_dir <- sbvecm_dir("reports", "Chile_Structural_Break_VECM_Report")
base <- sbvecm_dir("output", "CL", "SBVECM")
s15 <- file.path(base, "S15_EVIDENCE_RECONCILIATION")
s20 <- file.path(base, "S20_DUAL_ROUTE_BREAK_AUDIT")
s20c <- file.path(base, "S20C_INDEPENDENT_LONG_RUN_ADJUDICATION")
s25 <- file.path(base, "S25_STATIONARY_ACCUMULATION_BREAKS")
s35 <- file.path(base, "S35_DYNAMIC_ACCUMULATION_RESPONSE")
s95 <- file.path(base, "S95_DEFINITIVE_INTEGRITY")
out_dir <- file.path(base, "S99_REPORT_ASSEMBLY")
render_dir <- sbvecm_dir("tmp", "pdfs",
                         "Chile_Structural_Break_VECM_Report")
sbvecm_ensure_dir(report_dir)
sbvecm_ensure_dir(out_dir)
sbvecm_ensure_dir(render_dir)

panel <- read.csv(sbvecm_dir(
  "data", "processed", "CL", "SBVECM", "cl_capital_1920_2024.csv"
), check.names = FALSE, stringsAsFactors = FALSE)
break_sets <- read.csv(file.path(s20, "route_break_sets.csv"),
                       stringsAsFactors = FALSE)
long_run <- read.csv(file.path(s20c, "long_run_identification_ledger.csv"),
                     stringsAsFactors = FALSE)
kp_compare <- read.csv(file.path(s20c, "kp_implementation_comparison.csv"),
                       stringsAsFactors = FALSE)
po <- read.csv(file.path(s20c, "phillips_ouliaris_cointegration_tests.csv"),
               stringsAsFactors = FALSE)
short_break <- read.csv(file.path(s25, "short_run_break_ledger.csv"),
                        stringsAsFactors = FALSE)
short_stationarity <- read.csv(
  file.path(s25, "short_run_stationarity_ledger.csv"),
  stringsAsFactors = FALSE
)
short_family <- read.csv(
  file.path(s25, "short_run_urca_family_verdicts.csv"),
  stringsAsFactors = FALSE
)
short_response <- read.csv(file.path(s35, "short_run_elasticity_ledger.csv"),
                           stringsAsFactors = FALSE)
summary_ledger <- read.csv(
  file.path(s95, "definitive_evidence_summary.csv"),
  stringsAsFactors = FALSE
)
integrity <- read.csv(
  file.path(s95, "definitive_report_integrity_checks.csv"),
  stringsAsFactors = FALSE
)
bootstrap <- read.csv(file.path(s95, "bootstrap_necessity_ledger.csv"),
                      stringsAsFactors = FALSE)
source_matrix <- read.csv(file.path(s95, "methodological_source_matrix.csv"),
                          stringsAsFactors = FALSE)
break_ci <- read.csv(file.path(s25, "accumulation_break_intervals.csv"),
                     stringsAsFactors = FALSE)

tex_escape <- function(x) {
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("_", "\\_", x, fixed = TRUE)
  x <- gsub("%", "\\%", x, fixed = TRUE)
  x <- gsub("&", "\\&", x, fixed = TRUE)
  x
}
paper_terms <- function(x) {
  x <- gsub("\\bheld\\b", "inconclusive", x, ignore.case = TRUE)
  x <- gsub("\\broute\\b", "identification method", x, ignore.case = TRUE)
  x <- gsub("\\bpromotion\\b", "admissibility", x, ignore.case = TRUE)
  x <- gsub("\\bpipeline\\b", "analysis", x, ignore.case = TRUE)
  x <- gsub("k_ME", "machinery stock", x, fixed = TRUE)
  x <- gsub("k_NR", "structures stock", x, fixed = TRUE)
  x <- gsub("beta_ME", "long-run coefficient", x, fixed = TRUE)
  x <- gsub("_", " ", x, fixed = TRUE)
  x
}
fmt <- function(x, digits = 3) {
  ifelse(is.finite(as.numeric(x)),
         sprintf(paste0("%.", digits, "f"), as.numeric(x)), "--")
}
yes_no <- function(x) ifelse(x %in% TRUE, "Yes", "No")
dates_for <- function(label) {
  z <- break_sets$break_years[break_sets$break_route == label]
  if (!length(z) || is.na(z) || z == "NONE") "None" else
    gsub(";", ", ", z, fixed = TRUE)
}

independent_kp <- kp_compare[kp_compare$implementation ==
  "independent mbreaks 1.0.1", , drop = FALSE]
dynamic_break <- as.character(unique(short_break$selected_break_years)[1])
dynamic_ci <- if (nrow(break_ci)) {
  paste(break_ci$interval_low[1], break_ci$interval_high[1], sep = "--")
} else {
  "not available"
}
writeLines(c(
  paste0("\\newcommand{\\CapitalSourceHash}{\\texttt{",
         substr(unique(panel$source_sha256), 1, 16), "\\ldots}}"),
  paste0("\\newcommand{\\LoessDates}{", dates_for("LOESS"), "}"),
  paste0("\\newcommand{\\ParametricCandidateDates}{",
         dates_for("PARAMETRIC"), "}"),
  paste0("\\newcommand{\\IndependentKPUdmax}{",
         fmt(independent_kp$statistic[1], 3), "}"),
  paste0("\\newcommand{\\IndependentKPCritical}{",
         fmt(independent_kp$critical_5[1], 2), "}"),
  paste0("\\newcommand{\\DynamicBreakDate}{", dynamic_break, "}"),
  paste0("\\newcommand{\\DynamicBreakCI}{", dynamic_ci, "}"),
  paste0("\\newcommand{\\DynamicUDmax}{",
         fmt(short_break$statistic[short_break$test == "UDmax"][1], 3), "}"),
  paste0("\\newcommand{\\DynamicUDmaxCV}{",
         fmt(short_break$critical_5[short_break$test == "UDmax"][1], 2), "}"),
  paste0("\\newcommand{\\DynamicLag}{",
         unique(short_break$selected_lag)[1], "}"),
  "\\newcommand{\\LongRunVerdict}{not identified}",
  "\\newcommand{\\AccumulationVerdict}{not identified}"
), file.path(report_dir, "report_values.tex"))

answer_labels <- c(
  "Long-run $\\beta_{\\mathrm{ME}}$",
  "Changes in $\\beta_{\\mathrm{ME},j}$",
  "Conditional accumulation $\\eta_j$",
  "Dynamic-relation break",
  "LOESS curvature dates"
)
answer_rows <- vapply(seq_len(nrow(summary_ledger)), function(i) {
  status <- if (summary_ledger$empirical_quantity[i] ==
                "dynamic-relation break") {
    "Diagnostic change"
  } else if (summary_ledger$empirical_quantity[i] ==
             "LOESS curvature dates") {
    "Descriptive only"
  } else if (summary_ledger$identified[i]) {
    "Identified"
  } else {
    "Not identified"
  }
  paste(
    answer_labels[i],
    status,
    tex_escape(summary_ledger$result[i]),
    tex_escape(summary_ledger$economic_interpretation[i]),
    sep = " & "
  )
}, character(1))
answer_rows <- paste0(answer_rows, " \\\\")
writeLines(c(
  "\\begin{table}[h!]",
  "\\centering\\small",
  "\\caption{Definitive empirical answer}",
  "\\label{tab:definitive-answer}",
  "\\begin{tabular}{p{2.4cm}p{2.5cm}p{2.7cm}p{4.9cm}}",
  "\\toprule",
  "\\textbf{Quantity} & \\textbf{Status} & \\textbf{Result} & \\textbf{Economic meaning}\\\\",
  "\\midrule",
  answer_rows,
  "\\bottomrule",
  "\\multicolumn{4}{p{13.1cm}}{\\footnotesize \\textbf{Note:} A dated change in an observed relation is not automatically an elasticity change. Long-run elasticity requires cointegration and rank one; the conditional accumulation elasticity additionally requires stationary growth rates.}",
  "\\end{tabular}",
  "\\end{table}"
), file.path(report_dir, "table_definitive_answer.tex"))

method_questions <- c(
  "Where do coefficients in a fitted regression change?",
  "Does one series reject a unit root after an unknown break?",
  "Does cointegration appear after one unknown regime change?",
  "Are coefficients stable in an already cointegrated regression?",
  "What is the rank with known deterministic breaks?",
  "What is the rank after one unknown system shift?",
  "Is an established cointegrating vector recursively constant?",
  "Does a residual combination reject no cointegration?",
  "Does one series reject a unit root with two admissible breaks?",
  "How are Bai--Perron statistics and intervals computed?"
)
method_claims <- c(
  "Candidate regression dates; not cointegration",
  "Integration-order evidence for one series",
  "One-break cointegration evidence",
  "Coefficient stability conditional on cointegration",
  "Conditional rank and vector restrictions",
  "Conditional rank with one unknown level shift",
  "Parameter constancy after rank is established",
  "Stable cointegration evidence",
  "Break-aware integration-order evidence",
  "Implementation, not a separate economic test"
)
method_display <- c(
  "Bai--Perron",
  "Zivot--Andrews",
  "Gregory--Hansen",
  "Kejriwal--Perron",
  "Johansen--Mosconi--Nielsen",
  "L\"utkepohl--Saikkonen--Trenkler",
  "Hansen--Johansen",
  "Phillips--Ouliaris",
  "Lee--Strazicich",
  "\\texttt{mbreaks}"
)
method_rows <- vapply(seq_len(nrow(source_matrix)), function(i) {
  paste(
    method_display[i],
    tex_escape(method_questions[i]),
    tex_escape(method_claims[i]),
    sep = " & "
  )
}, character(1))
method_rows <- paste0(method_rows, " \\\\")
writeLines(c(
  "\\begin{table}[h!]",
  "\\centering\\scriptsize",
  "\\caption{What the structural-break and cointegration procedures establish}",
  "\\label{tab:method-map}",
  "\\begin{tabular}{p{3.3cm}p{4.6cm}p{5.0cm}}",
  "\\toprule",
  "\\textbf{Procedure} & \\textbf{Economic-statistical question} & \\textbf{Permitted claim}\\\\",
  "\\midrule",
  method_rows,
  "\\bottomrule",
  "\\multicolumn{3}{p{13.1cm}}{\\footnotesize \\textbf{Note:} Each procedure concerns a different statistical object. Evidence about a single series, a fitted regression, a cointegrating residual, and system rank cannot be substituted for one another.}",
  "\\end{tabular}",
  "\\end{table}"
), file.path(report_dir, "table_method_map.tex"))

long_labels <- c(
  "Raw integration order",
  "Gregory--Hansen",
  "Phillips--Ouliaris",
  "No-break Johansen",
  "Independent Kejriwal--Perron",
  "Validated long-run breaks",
  "Stable $\\beta_{\\mathrm{ME}}$",
  "Period $\\beta_{\\mathrm{ME},j}$"
)
long_rows <- vapply(seq_len(nrow(long_run)), function(i) {
  paste(
    long_labels[i],
    tex_escape(paper_terms(long_run$statistic_or_result[i])),
    yes_no(long_run$prerequisite_pass[i]),
    tex_escape(paper_terms(long_run$permitted_claim[i])),
    sep = " & "
  )
}, character(1))
long_rows <- paste0(long_rows, " \\\\")
writeLines(c(
  "\\begin{table}[h!]",
  "\\centering\\small",
  "\\caption{Long-run identification evidence}",
  "\\label{tab:long-run}",
  "\\begin{tabular}{p{3.0cm}p{3.25cm}p{1.5cm}p{5.2cm}}",
  "\\toprule",
  "\\textbf{Evidence} & \\textbf{Result} & \\textbf{Gate} & \\textbf{Permitted conclusion}\\\\",
  "\\midrule",
  long_rows,
  "\\bottomrule",
  "\\multicolumn{4}{p{13.1cm}}{\\footnotesize \\textbf{Note:} The independent Kejriwal--Perron statistic exceeds its critical value, but the procedure assumes cointegration. Since neither Gregory--Hansen nor Phillips--Ouliaris establishes cointegration, the stability rejection cannot define coefficient periods.}",
  "\\end{tabular}",
  "\\end{table}"
), file.path(report_dir, "table_long_run.tex"))

families <- c("ADF", "PP", "KPSS", "ERS", "SP", "ZA")
stationarity_rows <- lapply(c("d_k_NR", "d_k_ME"), function(variable) {
  z <- short_family[
    short_family$variable == variable &
      short_family$transformation == "level", , drop = FALSE
  ]
  verdict <- vapply(families, function(family) {
    q <- z$family_verdict[z$family == family]
    if (length(q)) paper_terms(q[1]) else "not available"
  }, character(1))
  order <- short_stationarity$integration_order[
    short_stationarity$variable == variable
  ][1]
  label <- if (variable == "d_k_NR") "$\\Delta k^{\\mathrm{NR}}$" else
    "$\\Delta k^{\\mathrm{ME}}$"
  paste(label, paste(tex_escape(verdict), collapse = " & "),
        if (order == "I(0)") "$I(0)$" else "Inconclusive", sep = " & ")
})
stationarity_rows <- paste0(unlist(stationarity_rows), " \\\\")
writeLines(c(
  "\\begin{table}[h!]",
  "\\centering\\scriptsize",
  "\\caption{Stationarity evidence for the capital-growth rates after the 2005 mean shift}",
  "\\label{tab:growth-stationarity}",
  "\\begin{tabular}{p{1.35cm}p{1.35cm}p{1.35cm}p{1.35cm}p{1.35cm}p{1.35cm}p{1.35cm}p{1.75cm}}",
  "\\toprule",
  "\\textbf{Series} & \\textbf{ADF} & \\textbf{PP} & \\textbf{KPSS} & \\textbf{ERS} & \\textbf{SP} & \\textbf{ZA} & \\textbf{Conclusion}\\\\",
  "\\midrule",
  stationarity_rows,
  "\\bottomrule",
  "\\multicolumn{8}{p{13.1cm}}{\\footnotesize \\textbf{Note:} A family verdict summarizes its declared primary deterministic cases so that densely parameterized test families receive no extra weight. Four concordant families are required. The disagreement therefore remains substantive rather than being resolved by majority choice among individual configurations.}",
  "\\end{tabular}",
  "\\end{table}"
), file.path(report_dir, "table_growth_stationarity.tex"))

break_rows <- vapply(seq_len(nrow(short_break)), function(i) {
  paste(
    tex_escape(short_break$test[i]),
    fmt(short_break$statistic[i], 3),
    fmt(short_break$critical_5[i], 2),
    yes_no(short_break$rejects_5[i]),
    if (i == 1L) paste0(dynamic_break, " (", dynamic_ci, ")") else
      if (short_break$rejects_5[i]) "continue" else "stop",
    sep = " & "
  )
}, character(1))
break_rows <- paste0(break_rows, " \\\\")
writeLines(c(
  "\\begin{table}[h!]",
  "\\centering\\small",
  "\\caption{Break tests for the dynamic accumulation relation}",
  "\\label{tab:dynamic-break}",
  "\\begin{tabular}{p{2.3cm}p{1.7cm}p{1.7cm}p{1.4cm}p{5.5cm}}",
  "\\toprule",
  "\\textbf{Test} & \\textbf{Statistic} & \\textbf{5\\% critical} & \\textbf{Reject} & \\textbf{Sequential implication}\\\\",
  "\\midrule",
  break_rows,
  "\\bottomrule",
  "\\multicolumn{5}{p{13.1cm}}{\\footnotesize \\textbf{Note:} The dynamic equation uses one annual lag, selected by BIC on a common sample, and passes a four-lag residual serial-correlation test. These statistics locate a visible conditional change. They do not become elasticity evidence because the growth-rate stationarity condition fails.}",
  "\\end{tabular}",
  "\\end{table}"
), file.path(report_dir, "table_dynamic_break.tex"))

response_rows <- vapply(seq_len(nrow(short_response)), function(i) {
  paste(
    tex_escape(short_response$period[i]),
    short_response$N[i],
    "--", "--", "--",
    "Not identified: growth-rate stationarity is inconclusive",
    sep = " & "
  )
}, character(1))
response_rows <- paste0(response_rows, " \\\\")
writeLines(c(
  "\\begin{table}[h!]",
  "\\centering\\small",
  "\\caption{Can the conditional accumulation elasticity be reported?}",
  "\\label{tab:eta}",
  "\\begin{tabular}{p{2.0cm}p{0.8cm}p{1.5cm}p{1.8cm}p{2.0cm}p{4.7cm}}",
  "\\toprule",
  "\\textbf{Span} & \\textbf{$N$} & \\textbf{$\\eta_{j,0}$} & \\textbf{$\\eta_{j,3}$} & \\textbf{Adjacent test} & \\textbf{Empirical verdict}\\\\",
  "\\midrule",
  response_rows,
  "\\bottomrule",
  "\\multicolumn{6}{p{13.1cm}}{\\footnotesize \\textbf{Note:} $\\eta_{j,0}$ would be the impact response and $\\eta_{j,3}$ the cumulative three-year response. Both are intentionally blank because the growth rates do not pass the declared piecewise-stationarity rule. The 2005 break remains a feature of the observed dynamic relation, not an estimated elasticity change.}",
  "\\end{tabular}",
  "\\end{table}"
), file.path(report_dir, "table_eta.tex"))

manifest_files <- c(
  sbvecm_dir("codes", "CL_S10_structural_break_vecm_panel.R"),
  sbvecm_dir("codes", "CL_S15_evidence_reconciliation.R"),
  sbvecm_dir("codes", "CL_S20_structural_break_dual_route_audit.R"),
  sbvecm_dir("codes", "CL_S20B_parametric_cointegration_break_adjudication.R"),
  sbvecm_dir("codes", "CL_S20C_independent_long_run_adjudication.R"),
  sbvecm_dir("codes", "CL_S25_stationary_accumulation_breaks.R"),
  sbvecm_dir("codes", "CL_S30_structural_break_vecm_estimation.R"),
  sbvecm_dir("codes", "CL_S35_dynamic_accumulation_response.R"),
  sbvecm_dir("codes", "CL_S95_definitive_report_integrity.R"),
  sbvecm_dir("codes", "CL_S99_structural_break_vecm_report.R"),
  file.path(report_dir, "chile_structural_break_vecm_report.tex")
)
manifest <- data.frame(
  file = normalizePath(manifest_files, winslash = "/", mustWork = TRUE),
  sha256 = vapply(manifest_files, sbvecm_sha256, character(1)),
  stringsAsFactors = FALSE
)
write.csv(manifest, file.path(out_dir, "report_build_manifest.csv"),
          row.names = FALSE)

tex_file <- file.path(report_dir, "chile_structural_break_vecm_report.tex")
old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(report_dir)
for (pass in 1:2) {
  status <- system2(
    "pdflatex",
    c("-interaction=nonstopmode", "-halt-on-error", basename(tex_file)),
    stdout = file.path(out_dir, paste0("pdflatex_pass", pass, ".log")),
    stderr = file.path(out_dir, paste0("pdflatex_pass", pass, ".err"))
  )
  if (status != 0L) stop("LaTeX compilation failed on pass ", pass, ".")
}

pdf_file <- sub("\\.tex$", ".pdf", tex_file)
if (!file.exists(pdf_file)) stop("Compiled report PDF is missing.")

old_renders <- list.files(render_dir, pattern = "^page-.*\\.png$",
                          full.names = TRUE)
if (length(old_renders)) unlink(old_renders, force = TRUE)
system2("pdftoppm",
        c("-png", "-r", "140", pdf_file, file.path(render_dir, "page")),
        stdout = TRUE, stderr = TRUE)
pngs <- list.files(render_dir, pattern = "^page-.*\\.png$",
                   full.names = TRUE)
pdf_info <- system2("pdfinfo", pdf_file, stdout = TRUE, stderr = TRUE)
page_count <- as.integer(trimws(sub("^Pages:", "",
  pdf_info[grepl("^Pages:", pdf_info)])))
pdf_text <- paste(system2("pdftotext", c(pdf_file, "-"), stdout = TRUE,
                          stderr = TRUE), collapse = "\n")

prose_review <- data.frame(
  criterion = c(
    "Internal process vocabulary is absent.",
    "The main estimands are named in the opening argument.",
    "The economic interpretation precedes the technical appendix.",
    "The 2005 result is bounded as non-causal diagnostic evidence.",
    "The conclusion gives the definitive empirical answer."
  ),
  pass = c(
    !grepl("\\b(route|held|promotion|pipeline)\\b", pdf_text,
           ignore.case = TRUE, perl = TRUE),
    grepl("long-run elasticity", pdf_text, ignore.case = TRUE) &&
      grepl("accumulation", pdf_text, ignore.case = TRUE),
    grepl("intensive margin", pdf_text, ignore.case = TRUE),
    grepl("neither causal nor an estimate of technique", pdf_text,
          ignore.case = TRUE),
    grepl("identify neither a long-run elasticity nor a conditional",
          pdf_text, ignore.case = TRUE)
  ),
  stringsAsFactors = FALSE
)
write.csv(prose_review,
          file.path(out_dir, "paper_facing_prose_review.csv"),
          row.names = FALSE)

layout_checks <- data.frame(
  check = c(
    "compiled PDF exists",
    "all pages rendered",
    "page target is 10-12",
    "definitive verdict present",
    "dynamic break present",
    "no WBOP content",
    "no BCCh content",
    "locked kappa notation present",
    "legacy tau notation absent",
    "paper-facing vocabulary",
    "no numerical eta reported",
    "no numerical beta reported",
    "all empirical integrity checks pass",
    "no unnecessary bootstrap",
    "paper-facing prose review passes"
  ),
  pass = c(
    file.exists(pdf_file),
    length(pngs) == page_count,
    page_count >= 10L && page_count <= 12L,
    grepl("not identified", pdf_text, ignore.case = TRUE),
    grepl(dynamic_break, pdf_text, fixed = TRUE),
    !grepl("WBOP", pdf_text, fixed = TRUE),
    !grepl("BCCh", pdf_text, fixed = TRUE),
    grepl("κ|capital composition", pdf_text, ignore.case = TRUE),
    !grepl("tau_t|tau t", pdf_text, ignore.case = TRUE),
    !grepl("\\b(route|held|promotion|pipeline)\\b", pdf_text,
           ignore.case = TRUE, perl = TRUE),
    !any(is.finite(short_response$eta_impact)),
    !any(long_run$evidence %in%
      c("stable full-sample beta_ME", "period-specific beta_ME") &
      long_run$prerequisite_pass),
    all(integrity$pass),
    !any(bootstrap$strictly_necessary_now),
    all(prose_review$pass)
  ),
  value = c(
    file.exists(pdf_file), length(pngs), page_count,
    grepl("not identified", pdf_text, ignore.case = TRUE),
    dynamic_break,
    !grepl("WBOP", pdf_text, fixed = TRUE),
    !grepl("BCCh", pdf_text, fixed = TRUE),
    grepl("κ|capital composition", pdf_text, ignore.case = TRUE),
    !grepl("tau_t|tau t", pdf_text, ignore.case = TRUE),
    !grepl("\\b(route|held|promotion|pipeline)\\b", pdf_text,
           ignore.case = TRUE, perl = TRUE),
    !any(is.finite(short_response$eta_impact)),
    !any(long_run$evidence %in%
      c("stable full-sample beta_ME", "period-specific beta_ME") &
      long_run$prerequisite_pass),
    all(integrity$pass),
    !any(bootstrap$strictly_necessary_now),
    all(prose_review$pass)
  ),
  stringsAsFactors = FALSE
)
write.csv(layout_checks,
          file.path(out_dir, "compiled_pdf_layout_checks.csv"),
          row.names = FALSE)
if (!all(layout_checks$pass)) {
  stop("Report build checks failed: ",
       paste(layout_checks$check[!layout_checks$pass], collapse = "; "))
}

message("S99 complete: definitive report compiled; ", page_count,
        " pages rendered.")
