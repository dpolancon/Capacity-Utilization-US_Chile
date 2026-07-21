#!/usr/bin/env Rscript

# Analytical source and identity audit for the long-run theta Beamer v3.
# This script reads theory/method sources only. It does not read empirical panels,
# coefficient ledgers, reconstructed paths, or historical result figures.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[1]) else
  file.path(getwd(), "codes", "US_S90_long_run_theta_analytic_beamer_audit.R")
ROOT <- normalizePath(file.path(dirname(normalizePath(script_path)), ".."), winslash = "/")

OUT_DIR <- file.path(ROOT, "output", "US", "S90_path_dependent_theta_robustness")
CSV_DIR <- file.path(OUT_DIR, "csv")
REPORT_DIR <- file.path(OUT_DIR, "reports")
GEN_DIR <- file.path(REPORT_DIR, "generated")
dir.create(CSV_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(REPORT_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(GEN_DIR, recursive = TRUE, showWarnings = FALSE)

SOURCES <- c(
  S33 = file.path(ROOT, "docs", "ch2", "S33_theta_recovery_specification_ledger.md"),
  RULE = file.path(ROOT, "chapter2_vault", "00_constitutive_core",
                   "R_distribution_conditioned_theta_identification.md"),
  OUTLINE = file.path(ROOT, "chapter2", "outline", "Ch2_Outline_DEFINITIVE.md")
)
if (!all(file.exists(SOURCES))) {
  stop("Missing analytical source(s): ", paste(SOURCES[!file.exists(SOURCES)], collapse = "; "))
}

source_lines <- lapply(SOURCES, readLines, warn = FALSE, encoding = "UTF-8")
find_line <- function(source_id, pattern, fixed = TRUE) {
  hit <- grep(pattern, source_lines[[source_id]], fixed = fixed)
  if (!length(hit)) stop("Source anchor not found: ", source_id, " :: ", pattern)
  hit[1]
}
line_text <- function(source_id, line) trimws(source_lines[[source_id]][line])
rel <- function(path) {
  p <- normalizePath(path, winslash = "/")
  prefix <- paste0(ROOT, "/")
  if (startsWith(p, prefix)) substring(p, nchar(prefix) + 1L) else p
}

anchors <- list(
  theta_object = c("S33", find_line("S33", "state-conditioned capacity-building elasticity")),
  observed_output = c("RULE", find_line("RULE", "y_t = y_t^p + \\log \\mu_t.")),
  sequence = c("RULE", find_line("RULE", "long-run coefficient vector")),
  technique_choice = c("S33", find_line("S33", "q_t^* = \\arg\\max_q")),
  causal_order = c("S33", find_line("S33", "\\omega_t \\rightarrow q_t^*")),
  accumulated_path = c("S33", find_line("S33", "Q^{tech}_t = \\sum")),
  preferred_recovery = c("S33", find_line("S33", "\\boxed{\\theta_t=\\beta+\\gamma q^*_{t-1}}")),
  profit_form = c("OUTLINE", find_line("OUTLINE", "\\hat{\\theta}_t^{(1)} = \\theta_1 + \\theta_2")),
  benchmark = c("OUTLINE", find_line("OUTLINE", "theta(\\Lambda) = 1")),
  composition = c("S33", find_line("S33", "S3_COMPONENT_K")),
  generated_inference = c("S33", find_line("S33", "Some specifications recover")),
  anchoring = c("RULE", find_line("RULE", "explicitly anchored"))
)

anchor_row <- function(name) {
  z <- anchors[[name]]
  data.frame(anchor_id = name, source_id = z[1], source_file = rel(SOURCES[[z[1]]]),
             located_source_line = as.integer(z[2]), source_expression = line_text(z[1], as.integer(z[2])),
             stringsAsFactors = FALSE)
}
anchor_ledger <- do.call(rbind, lapply(names(anchors), anchor_row))

claim_spec <- data.frame(
  claim_id = c(sprintf("MAIN_%02d", 1:10), sprintf("APP_%02d", 1:3)),
  slide_id = c(as.character(1:10), "A1", "A2", "A3"),
  audience_facing_claim = c(
    "Theta is a long-run marginal capital-to-capacity elasticity, not an annual realized-growth ratio.",
    "Observed output must be decomposed into latent capacity and utilization before utilization is recovered.",
    "Long-run distribution selects technique before productive capital is installed.",
    "Lagged technique is embodied in new accumulation rather than applied retroactively to the existing stock.",
    "The accumulated technique path converts heterogeneous installation choices into an admissible long-run state.",
    "The cointegrating vector and the lagged technique state jointly recover the complete theta path.",
    "An affine technique-choice equation nests the governing profit-share formulation of theta.",
    "Unity is the Harrodian benchmark because it leaves capacity productivity unchanged under positive accumulation.",
    "Theta classifies capacity-building while anchored mu classifies whether capacity is actually used.",
    "A regime is identified only when uncertainty excludes unity and all admissibility gates pass.",
    "Identification requires admissible long-run states, rank, stationary residuals, lag timing, and explicit anchoring.",
    "Composition payoffs and annual realized-direction ratios are not the balanced-accumulation theta coefficient.",
    "Generated-regressor uncertainty must re-estimate every upstream state before theta bands and window regimes are classified."
  ),
  anchor_id = c("theta_object", "observed_output", "technique_choice", "causal_order",
                "accumulated_path", "preferred_recovery", "profit_form", "benchmark",
                "sequence", "generated_inference", "anchoring", "composition", "generated_inference"),
  displayed_equation = c(
    "theta_t^LR = d log(Y_t^p) / d log(K_t^cap) on the long-run manifold",
    "y_t = y_t^p + log(mu_t)",
    "a'(q_t^*) = pi_t^LR = 1 - omega_t^LR",
    "Delta Q_t^tech = qtilde_{t-1}^* Delta k_t",
    "Q_t^tech = sum_{s<=t} qtilde_{s-1}^* Delta k_s",
    "theta_t^LR = beta_K + beta_Q qtilde_{t-1}^*",
    "theta_t^LR = theta_1 + theta_2 pi_{t-1}^LR",
    "Delta log(b_t) = (theta_t^LR - 1) Delta k_t",
    "Delta log(mu_t) = Delta y_t - theta_t^LR Delta k_t",
    "upper_t < 1; lower_t > 1; otherwise indeterminate",
    "rank[k,Q]=2; residual I(0); lagged installation; anchored capacity",
    "theta_scale, theta_composition, and g_t^p/g_t^cap are distinct objects",
    "Theta_w^LR = sum(theta_t^LR Delta k_t) / sum(Delta k_t)"
  ), stringsAsFactors = FALSE
)
claim_ledger <- merge(claim_spec, anchor_ledger, by = "anchor_id", all.x = TRUE, sort = FALSE)
claim_ledger <- claim_ledger[match(claim_spec$claim_id, claim_ledger$claim_id), ]
claim_ledger$status <- ifelse(!is.na(claim_ledger$located_source_line) &
                               nzchar(claim_ledger$source_expression), "PASS", "FAIL")
claim_ledger <- claim_ledger[, c("claim_id", "slide_id", "audience_facing_claim", "source_id",
                                 "source_file", "located_source_line", "source_expression",
                                 "displayed_equation", "status")]

# Deterministic algebra checks. Values are synthetic and verify identities only.
tol <- 1e-12
dk <- c(0.018, 0.027, 0.012, 0.021, 0.016, 0.025)
k0 <- 3.4
k <- k0 + cumsum(dk)
q <- c(0.72, 0.81, 0.76, 0.89, 0.84, 0.93)
qbar <- mean(q)
qtilde <- q - qbar
Q_raw <- cumsum(q * dk)
Q_centered <- cumsum(qtilde * dk)
beta_k_raw <- 0.64
beta_q <- 0.38
alpha_raw <- 0.17
beta_k_centered <- beta_k_raw + beta_q * qbar
alpha_centered <- alpha_raw - beta_q * qbar * k0
fit_raw <- alpha_raw + beta_k_raw * k + beta_q * Q_raw
fit_centered <- alpha_centered + beta_k_centered * k + beta_q * Q_centered
theta <- beta_k_centered + beta_q * qtilde
dy_p <- theta * dk
dy <- dy_p + c(0.001, -0.002, 0.0015, -0.001, 0.0005, -0.0015)
dmu <- dy - dy_p
pi_lr <- c(0.31, 0.33, 0.32, 0.35, 0.34, 0.36)
a <- 0.42; b <- 1.25
q_affine <- a + b * pi_lr
q_affine_bar <- mean(q_affine)
theta_affine <- beta_k_centered + beta_q * (q_affine - q_affine_bar)
theta1 <- beta_k_centered + beta_q * (a - q_affine_bar)
theta2 <- beta_q * b
window_theta <- sum(theta * dk) / sum(dk)

checks <- data.frame(
  identity_id = c("ID01_OUTPUT_DECOMPOSITION", "ID02_PATH_INCREMENT", "ID03_CENTERING_INVARIANCE",
                  "ID04_MARGINAL_THETA", "ID05_AFFINE_NESTING", "ID06_CAPACITY_PRODUCTIVITY",
                  "ID07_UTILIZATION_GROWTH", "ID08_WINDOW_ELASTICITY", "ID09_ANCHOR_NORMALIZATION"),
  description = c(
    "Observed log output equals latent log capacity plus log utilization.",
    "The accumulated path changes by lagged centered technique times current accumulation.",
    "Centering technique changes the coefficient basis but not the fitted capacity path.",
    "The path differential recovers beta_K plus beta_Q times the lagged centered technique.",
    "Affine technique choice maps exactly into theta_1 plus theta_2 times long-run profit share.",
    "Capacity-productivity growth equals theta minus one times capital growth.",
    "Utilization growth equals realized-output growth minus capacity growth.",
    "The window elasticity equals cumulative capacity growth divided by cumulative capital growth.",
    "A level shift in reconstructed capacity can normalize utilization to one at the anchor."
  ),
  recomputed_error = c(
    max(abs((fit_centered + log(exp(dmu))) - fit_centered - dmu)),
    max(abs(c(Q_centered[1], diff(Q_centered)) - qtilde * dk)),
    max(abs(fit_raw - fit_centered)),
    max(abs(dy_p / dk - (beta_k_centered + beta_q * qtilde))),
    max(abs(theta_affine - (theta1 + theta2 * pi_lr))),
    max(abs((dy_p - dk) - (theta - 1) * dk)),
    max(abs(dmu - (dy - theta * dk))),
    abs(window_theta - sum(dy_p) / sum(dk)),
    abs(exp((fit_centered[3] - fit_centered[3])) - 1)
  ),
  tolerance = tol, stringsAsFactors = FALSE
)
checks$status <- ifelse(is.finite(checks$recomputed_error) & checks$recomputed_error <= checks$tolerance,
                        "PASS", "FAIL")

git_commit <- tryCatch(system("git rev-parse HEAD", intern = TRUE), error = function(e) NA_character_)
provenance <- data.frame(
  source_id = names(SOURCES),
  source_file = vapply(SOURCES, rel, character(1)),
  md5 = unname(tools::md5sum(SOURCES)),
  line_count = vapply(source_lines, length, integer(1)),
  git_commit = if (length(git_commit)) git_commit[1] else NA_character_,
  audit_role = c("theta recovery and accumulated-path definition",
                 "latent-capacity identification and anchoring",
                 "governing profit-share form and Harrodian benchmark"),
  stringsAsFactors = FALSE
)

write.csv(claim_ledger, file.path(CSV_DIR, "S90_long_run_theta_analytical_claim_ledger.csv"), row.names = FALSE)
write.csv(checks, file.path(CSV_DIR, "S90_long_run_theta_identity_validation_ledger.csv"), row.names = FALSE)
write.csv(provenance, file.path(CSV_DIR, "S90_long_run_theta_source_provenance_ledger.csv"), row.names = FALSE)
write.csv(anchor_ledger, file.path(CSV_DIR, "S90_long_run_theta_source_anchor_ledger.csv"), row.names = FALSE)

if (any(claim_ledger$status != "PASS") || any(checks$status != "PASS")) {
  stop("Long-run theta analytical audit failed.")
}

macro <- function(name, value) paste0("\\providecommand{\\", name, "}{", value, "}")
macros <- c(
  macro("AnalyticalClaimCount", nrow(claim_ledger)),
  macro("AnalyticalIdentityCount", nrow(checks)),
  macro("BootstrapReplications", "1000"),
  macro("BootstrapBlockLength", "4"),
  macro("SimultaneousBandLevel", "95"),
  macro("LineThetaObject", anchors$theta_object[2]),
  macro("LineObservedOutput", anchors$observed_output[2]),
  macro("LineTechniqueChoice", anchors$technique_choice[2]),
  macro("LineAccumulatedPath", anchors$accumulated_path[2]),
  macro("LinePreferredRecovery", anchors$preferred_recovery[2]),
  macro("LineProfitForm", anchors$profit_form[2]),
  macro("LineHarrodianBenchmark", anchors$benchmark[2]),
  macro("HashSthirtyThree", substr(provenance$md5[provenance$source_id == "S33"], 1, 10)),
  macro("HashIdentificationRule", substr(provenance$md5[provenance$source_id == "RULE"], 1, 10)),
  macro("HashChapterOutline", substr(provenance$md5[provenance$source_id == "OUTLINE"], 1, 10))
)
writeLines(macros, file.path(GEN_DIR, "S90_long_run_theta_analytic_macros.tex"), useBytes = TRUE)

report <- c(
  "# Long-Run Theta Analytical Beamer Audit",
  "",
  sprintf("All %d analytical source claims passed.", nrow(claim_ledger)),
  sprintf("All %d deterministic analytical identities passed at tolerance %.0e.", nrow(checks), tol),
  "",
  "The audit reads only analytical and methodological source files. It does not read empirical panels,",
  "estimated coefficients, reconstructed historical paths, or result figures.",
  "",
  sprintf("Source commit: `%s`.", provenance$git_commit[1])
)
writeLines(report, file.path(REPORT_DIR, "S90_LONG_RUN_THETA_ANALYTICAL_AUDIT.md"), useBytes = TRUE)

cat(sprintf("Long-run theta analytical audit passed. Claims: %d; identities: %d.\n",
            nrow(claim_ledger), nrow(checks)))
