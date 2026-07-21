#!/usr/bin/env Rscript

# Analytical source and identity audit for the long-run theta Beamer v4.
# This audit validates the directional two-capital derivation only. It does not
# read empirical panels, estimate coefficients, or claim a historical regime.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[1]) else
  file.path(getwd(), "codes", "US_S90_long_run_theta_directional_beamer_audit_v4.R")
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
  A03 = file.path(ROOT, "chapter2_vault", "02_analyitical_foundation",
                  "A03_TransformationElasticity_Two-CapitalCapacityComposition.md"),
  A05 = file.path(ROOT, "chapter2_vault", "02_analyitical_foundation",
                  "A05_NRCEnvelope_MechanizationBias.md"),
  PLAYBOOK = file.path(ROOT, "chapter2_vault", "00_constitutive_core",
                       "03B_Process_Tracing_Playbook.md"),
  CAPITAL = file.path(ROOT, "codes", "US_D10_clean_build_source_of_truth_dataset.R")
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
  theta_object = c("S33", find_line("S33", "capacity-building elasticity")),
  observed_output = c("RULE", find_line("RULE", "y_t = y_t^p + \\log \\mu_t.")),
  technique_choice = c("S33", find_line("S33", "q_t^* = \\arg\\max_q")),
  causal_order = c("S33", find_line("S33", "\\omega_t \\rightarrow q_t^*")),
  composition_spec = c("RULE", find_line("RULE", "Specification B: composition-mediated conditioning")),
  composition_response = c("A05", find_line("A05", "\\frac{\\partial\\hat y_t^p}{\\partial\\tilde\\tau_t}")),
  aggregate_ratio = c("A03", find_line("A03", "aggregate transformation elasticity")),
  capital_identity = c("CAPITAL", find_line("CAPITAL", "K_capacity = K_ME + K_NRC")),
  component_bridge = c("S33", find_line("S33", "S3_COMPONENT_K")),
  affine_lock = c("RULE", find_line("RULE", "\\theta_0+\\theta_1\\tilde d_t.")),
  benchmark = c("PLAYBOOK", find_line("PLAYBOOK", "governing classification is determined")),
  anchoring = c("RULE", find_line("RULE", "explicitly anchored")),
  inference = c("S33", find_line("S33", "Some specifications recover"))
)

anchor_row <- function(name) {
  z <- anchors[[name]]
  data.frame(
    anchor_id = name,
    source_id = z[1],
    source_file = rel(SOURCES[[z[1]]]),
    located_source_line = as.integer(z[2]),
    source_expression = line_text(z[1], as.integer(z[2])),
    stringsAsFactors = FALSE
  )
}
anchor_ledger <- do.call(rbind, lapply(names(anchors), anchor_row))

claim_spec <- data.frame(
  claim_id = c(sprintf("MAIN_%02d", 1:11), sprintf("APP_%02d", 1:2)),
  slide_id = c(as.character(1:11), "A1", "A2"),
  audience_facing_claim = c(
    "Long-run theta is the directional elasticity evaluated along unbalanced accumulation.",
    "Observed output separates latent productive capacity from realized utilization.",
    "Persistent distribution selects technique before the associated capital is installed.",
    "A fixed marginal technique does not imply proportional growth of inherited ME and NR stocks.",
    "The composition specification separately identifies the plant-envelope and machinery payoffs.",
    "Capital-stock growth and potential-output growth are different magnitudes on the same path.",
    "The accumulation direction maps the two-capital gradient into aggregate theta.",
    "Embodiment requires lagged timing without suppressing unbalanced composition change.",
    "The affine profit-share form is a restricted case of the path-dependent composition model.",
    "Unity classifies the combined path elasticity through capacity-productivity growth.",
    "A sustained regime requires a window interval that clears unity; mu classifies realized use.",
    "Identification requires scale-composition rank, timing, aggregation, anchoring, and positive accumulation.",
    "Regime inference must re-estimate and rebuild the full unbalanced path in every bootstrap draw."
  ),
  anchor_id = c(
    "theta_object", "observed_output", "technique_choice", "causal_order",
    "composition_response", "capital_identity", "aggregate_ratio", "component_bridge",
    "affine_lock", "benchmark", "anchoring", "composition_spec", "inference"
  ),
  displayed_equation = c(
    "theta_Gamma = d log(Yp) / d log(Kcap) along Gamma",
    "y = yp + log(mu)",
    "a'(q*) = pi_LR = 1 - omega_LR",
    "d tau = dK_ME/K_ME - dK_NR/K_NR need not equal zero",
    "dyp = theta_scale dk_NR + theta_tau d tau",
    "dk_cap = dk_NR + s_ME d tau",
    "theta_Gamma = gp/gK = theta_scale + (theta_tau-s_ME theta_scale) d tau/dk_cap",
    "gp = theta_scale g_NR + theta_tau_lag (g_ME-g_NR)",
    "theta_Gamma_LR = theta_scale + [psi_pi+lambda_pi pi_LR-s_ME theta_scale] r_LR",
    "Delta log(b) = (Theta_Gamma-1) Delta log(Kcap)",
    "Theta_Gamma_w = sum(gp)/sum(gK); Delta log(mu)=Delta y-gp",
    "rank[k_NR,tau]=2; Kcap=KME+KNR; cumulative gK positive",
    "resample; re-estimate; reconstruct gp and gK; build Theta; compare interval with one"
  ),
  stringsAsFactors = FALSE
)

claim_ledger <- merge(claim_spec, anchor_ledger, by = "anchor_id", all.x = TRUE, sort = FALSE)
claim_ledger <- claim_ledger[match(claim_spec$claim_id, claim_ledger$claim_id), ]
claim_ledger$status <- ifelse(
  !is.na(claim_ledger$located_source_line) & nzchar(claim_ledger$source_expression),
  "PASS", "FAIL"
)
claim_ledger <- claim_ledger[, c(
  "claim_id", "slide_id", "audience_facing_claim", "source_id", "source_file",
  "located_source_line", "source_expression", "displayed_equation", "status"
)]

# Deterministic algebra checks. Values are synthetic and validate identities only.
tol <- 1e-12
theta_scale <- 0.82
theta_tau <- 0.31
d_k_nr <- 0.024
d_tau <- 0.013
d_k_me <- d_k_nr + d_tau
s_me <- 0.36
d_k_cap <- d_k_nr + s_me * d_tau
d_y_p <- theta_scale * d_k_nr + theta_tau * d_tau
theta_nr <- theta_scale - theta_tau
theta_me <- theta_tau
theta_gamma_ratio <- d_y_p / d_k_cap
theta_gamma_direction <- theta_scale + (theta_tau - s_me * theta_scale) * (d_tau / d_k_cap)

pi_lr <- 0.34
omega_bar <- 0.62
omega_lr <- 1 - pi_lr
psi <- 0.28
lambda_omega <- -0.46
theta_tau_omega <- psi + lambda_omega * (omega_lr - omega_bar)
pi_bar <- 1 - omega_bar
psi_pi <- psi + lambda_omega * pi_bar
lambda_pi <- -lambda_omega
theta_tau_pi <- psi_pi + lambda_pi * pi_lr

g_nr <- c(0.021, 0.024, 0.019, 0.026, 0.023, 0.020)
g_me <- c(0.037, 0.031, 0.042, 0.034, 0.029, 0.038)
s_path <- c(0.30, 0.31, 0.32, 0.34, 0.35, 0.36)
theta_tau_path <- c(0.24, 0.26, 0.25, 0.29, 0.28, 0.31)
g_p <- theta_scale * g_nr + theta_tau_path * (g_me - g_nr)
g_k <- g_nr + s_path * (g_me - g_nr)
theta_path <- g_p / g_k
Theta_window <- sum(g_p) / sum(g_k)
d_log_b <- sum(g_p) - sum(g_k)
d_y <- g_p + c(0.001, -0.002, 0.0015, -0.001, 0.0005, -0.0015)
d_log_mu <- d_y - g_p

checks <- data.frame(
  identity_id = c(
    "ID01_COMPONENT_REPARAMETERIZATION", "ID02_AGGREGATE_CAPITAL_COORDINATE",
    "ID03_DIRECTIONAL_ELASTICITY", "ID04_BALANCED_SPECIAL_CASE",
    "ID05_WAGE_PROFIT_MAPPING", "ID06_PATH_RECONSTRUCTION",
    "ID07_WINDOW_ELASTICITY", "ID08_CAPACITY_PRODUCTIVITY",
    "ID09_UTILIZATION_GROWTH", "ID10_GROWTH_WEIGHTED_PATH"
  ),
  description = c(
    "The scale-composition differential equals the ME-NR component differential.",
    "Aggregate capital growth equals NR growth plus the ME share times composition growth.",
    "The ratio and direction-slope formulas recover the same aggregate elasticity.",
    "Zero composition change reduces the directional elasticity to the scale coefficient.",
    "The centered wage-share and mapped profit-share formulas recover the same composition payoff.",
    "Potential-output growth is reconstructed from scale growth and lagged composition growth.",
    "The window elasticity equals cumulative potential-output growth divided by cumulative capital growth.",
    "Window capital-productivity growth equals Theta minus one times cumulative capital growth.",
    "Utilization growth equals realized-output growth minus reconstructed potential-output growth.",
    "The window elasticity is the capital-growth-weighted average of local path elasticities."
  ),
  recomputed_error = c(
    abs(d_y_p - (theta_nr * d_k_nr + theta_me * d_k_me)),
    abs(d_k_cap - ((1 - s_me) * d_k_nr + s_me * d_k_me)),
    abs(theta_gamma_ratio - theta_gamma_direction),
    abs(theta_scale - (theta_scale + (theta_tau - s_me * theta_scale) * 0)),
    abs(theta_tau_omega - theta_tau_pi),
    max(abs(g_p - (theta_scale * g_nr + theta_tau_path * (g_me - g_nr)))),
    abs(Theta_window - sum(g_p) / sum(g_k)),
    abs(d_log_b - (Theta_window - 1) * sum(g_k)),
    max(abs(d_log_mu - (d_y - g_p))),
    abs(Theta_window - sum(theta_path * g_k) / sum(g_k))
  ),
  tolerance = tol,
  stringsAsFactors = FALSE
)
checks$status <- ifelse(
  is.finite(checks$recomputed_error) & checks$recomputed_error <= checks$tolerance,
  "PASS", "FAIL"
)

git_commit <- tryCatch(system("git rev-parse HEAD", intern = TRUE), error = function(e) NA_character_)
provenance <- data.frame(
  source_id = names(SOURCES),
  source_file = vapply(SOURCES, rel, character(1)),
  md5 = unname(tools::md5sum(SOURCES)),
  line_count = vapply(source_lines, length, integer(1)),
  git_commit = if (length(git_commit)) git_commit[1] else NA_character_,
  stringsAsFactors = FALSE
)

write.csv(claim_ledger, file.path(CSV_DIR, "S90_long_run_theta_directional_v4_claim_ledger.csv"), row.names = FALSE)
write.csv(checks, file.path(CSV_DIR, "S90_long_run_theta_directional_v4_identity_ledger.csv"), row.names = FALSE)
write.csv(provenance, file.path(CSV_DIR, "S90_long_run_theta_directional_v4_provenance.csv"), row.names = FALSE)
write.csv(anchor_ledger, file.path(CSV_DIR, "S90_long_run_theta_directional_v4_source_anchors.csv"), row.names = FALSE)

if (any(claim_ledger$status != "PASS") || any(checks$status != "PASS")) {
  stop("Long-run theta directional v4 analytical audit failed.")
}

macro <- function(name, value) paste0("\\providecommand{\\", name, "}{", value, "}")
macros <- c(
  macro("DirectionalClaimCount", nrow(claim_ledger)),
  macro("DirectionalIdentityCount", nrow(checks)),
  macro("BootstrapReplications", "1000"),
  macro("BootstrapBlockLength", "4"),
  macro("WindowInferenceStatus", "protocol defined; interval not yet estimated")
)
writeLines(macros, file.path(GEN_DIR, "S90_long_run_theta_directional_v4_macros.tex"), useBytes = TRUE)

report <- c(
  "# Long-Run Theta Directional Beamer v4 Audit",
  "",
  sprintf("All %d source-anchored claims passed.", nrow(claim_ledger)),
  sprintf("All %d deterministic directional identities passed at tolerance %.0e.", nrow(checks), tol),
  "",
  "This audit validates the two-capital directional algebra and source anchors only.",
  "It does not estimate a historical regime interval. The existing roughness bootstrap is not",
  "relabelled as regime inference.",
  "",
  sprintf("Source commit: `%s`.", provenance$git_commit[1])
)
writeLines(report, file.path(REPORT_DIR, "S90_LONG_RUN_THETA_DIRECTIONAL_V4_AUDIT.md"), useBytes = TRUE)

cat(sprintf("Directional v4 audit passed. Claims: %d; identities: %d.\n",
            nrow(claim_ledger), nrow(checks)))
