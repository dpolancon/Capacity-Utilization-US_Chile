#!/usr/bin/env Rscript

# Presentation-specific source audit for the expanded S90 Beamer addendum.
# Reads the scripts and artifacts that produced the displayed results, performs
# independent reproductions, and writes only new S90 presentation assets.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
S90_DIR <- file.path(ROOT, "output", "US", "S90_path_dependent_theta_robustness")
CSV_DIR <- file.path(S90_DIR, "csv")
FIG_DIR <- file.path(S90_DIR, "figures")
REPORT_DIR <- file.path(S90_DIR, "reports")
GEN_DIR <- file.path(REPORT_DIR, "generated")
invisible(lapply(c(CSV_DIR, FIG_DIR, REPORT_DIR, GEN_DIR), dir.create,
                 recursive = TRUE, showWarnings = FALSE))

SCRIPT_S34 <- file.path(ROOT, "codes", "S34R_B_cpr_realigned_design_gate",
                        "run_s34r_b_cpr_realigned_design_gate.py")
SCRIPT_S35 <- file.path(ROOT, "codes", "US_S35_estimator_refreeze_cpr.R")
SCRIPT_RECON <- file.path(ROOT, "codes", "reconstruct_golden_age_paths.R")
SCRIPT_S90 <- file.path(ROOT, "codes", "US_S90_path_dependent_theta_robustness.R")

S34_PANEL <- file.path(ROOT, "output", "S34R_B_cpr_realigned_design_gate", "csv",
                       "S34R_B_repaired_augmented_panel.csv")
S35_RESULTS <- file.path(ROOT, "output", "US", "S35_estimator_refreeze_cpr", "csv",
                         "us_s35_cpr_estimation_results.csv")
ORIGINAL_RECON <- file.path(ROOT, "output", "US", "reconstruction_comparison",
                            "us_golden_age_reconstructed_paths.csv")
D10_PANEL <- file.path(ROOT, "output", "US",
                       "D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET",
                       "csv", "D10_clean_us_source_of_truth_panel_wide.csv")

S90_BACKTRANSFORM <- file.path(CSV_DIR, "S90_coefficient_back_transformation_audit.csv")
S90_PATH <- file.path(CSV_DIR, "S90_original_vartheta_path_exact_contribution_ledger.csv")
S90_SHAPLEY <- file.path(CSV_DIR, "S90_shapley_roughness_attribution_ledger.csv")
S90_INFLUENCE <- file.path(CSV_DIR, "S90_capital_growth_and_influential_year_audit.csv")
S90_DENOM <- file.path(CSV_DIR, "S90_denominator_amplification_roughness.csv")
S90_PROFILE <- file.path(CSV_DIR, "S90_M3_persistence_profile_ledger.csv")
S90_RHO <- file.path(CSV_DIR, "S90_M3_persistence_and_half_life_results.csv")
S90_RHO_DRAWS <- file.path(CSV_DIR, "S90_M3_moving_block_bootstrap_draws.csv")
S90_RECON <- file.path(CSV_DIR, "S90_reconstructed_structural_and_path_series.csv")
S90_RDOLS <- file.path(CSV_DIR, "S90_RDOLS_coefficient_ledger.csv")
S90_VALIDATION <- file.path(CSV_DIR, "S90_validation_checks.csv")

required <- c(SCRIPT_S34, SCRIPT_S35, SCRIPT_RECON, SCRIPT_S90, S34_PANEL,
              S35_RESULTS, ORIGINAL_RECON, D10_PANEL, S90_BACKTRANSFORM,
              S90_PATH, S90_SHAPLEY, S90_INFLUENCE, S90_DENOM, S90_PROFILE,
              S90_RHO, S90_RHO_DRAWS, S90_RECON, S90_RDOLS, S90_VALIDATION)
if (any(!file.exists(required))) {
  stop("Missing source-audit input(s): ", paste(required[!file.exists(required)], collapse = "; "))
}
if (!requireNamespace("cointReg", quietly = TRUE)) {
  stop("Package cointReg is required to reproduce the S35 FM-OLS estimates.")
}

write_csv <- function(x, path) write.csv(x, path, row.names = FALSE, na = "")
rel <- function(path) {
  p <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(ROOT, "/")
  if (startsWith(p, prefix)) substring(p, nchar(prefix) + 1L) else p
}

script_paths <- c(S34 = SCRIPT_S34, S35 = SCRIPT_S35,
                  RECONSTRUCTION = SCRIPT_RECON, S90 = SCRIPT_S90)
script_lines <- lapply(script_paths, readLines, warn = FALSE)

find_line <- function(script_id, pattern, fixed = FALSE) {
  hit <- grep(pattern, script_lines[[script_id]], fixed = fixed)
  if (length(hit) == 0L) stop("Source anchor not found in ", script_id, ": ", pattern)
  hit[1]
}

anchor_specs <- data.frame(
  anchor_id = c("S34_ORTH", "S35_SPEC", "S35_FMOLS", "RECON_BETAS",
                "RECON_GP", "RECON_RATIO", "RECON_OUTPUT_BOUNDARY",
                "S90_OUTPUT_BOUNDARY", "S90_BACKTRANSFORM", "S90_PATH",
                "S90_SHAPLEY"),
  script_id = c("S34", "S35", "S35", "RECONSTRUCTION", "RECONSTRUCTION",
                "RECONSTRUCTION", "RECONSTRUCTION", "S90", "S90", "S90", "S90"),
  pattern = c("panel[\"inter_tau_omega_orth\"] = residual_center",
              "SPEC_B_NRC_orth = list(", "cointReg::cointRegFM",
              "beta_k_B <-", "panel$g_Yp_B <-", "ga_data$theta_total_t <-",
              "panel$yp_spec_B[idx_1973] <- panel$y_total[idx_1973]",
              "panel$y <- log(panel$Y_REAL_NFC_GVA_BASELINE_D09)",
              "primitive_beta <- c(", "build_path <- function", "shapley_once <- function"),
  fixed = rep(TRUE, 11),
  stringsAsFactors = FALSE)
anchor_specs$source_line <- mapply(find_line, anchor_specs$script_id,
                                   anchor_specs$pattern, anchor_specs$fixed)
anchor_specs$expression <- mapply(function(s, n) trimws(script_lines[[s]][n]),
                                  anchor_specs$script_id, anchor_specs$source_line)
anchor_specs$script_path <- unname(vapply(anchor_specs$script_id,
  function(s) rel(script_paths[[s]]), character(1)))
write_csv(anchor_specs, file.path(CSV_DIR, "S90_beamer_source_anchor_ledger.csv"))

git_commit <- tryCatch(system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
                       error = function(e) NA_character_)
if (length(git_commit) == 0L) git_commit <- NA_character_
provenance <- data.frame(
  script_id = names(script_paths),
  script_path = vapply(script_paths, rel, character(1)),
  md5 = unname(tools::md5sum(script_paths)),
  line_count = vapply(script_lines, length, integer(1)),
  git_commit = git_commit[1],
  audit_role = c("construct centered and orthogonalized interaction",
                 "estimate Golden-Age raw and orthogonalized CPR coefficients",
                 "construct capacity growth, utilization, and the red ratio",
                 "back-transform, decompose, attribute roughness, and profile memory"),
  stringsAsFactors = FALSE)
write_csv(provenance, file.path(CSV_DIR, "S90_beamer_script_provenance_ledger.csv"))

claims <- list()
add_claim <- function(claim_id, claim, producer_script, source_line, expression,
                      input_artifact, output_artifact, recomputed, published,
                      tolerance, notes = "") {
  difference <- abs(as.numeric(recomputed) - as.numeric(published))
  claims[[length(claims) + 1L]] <<- data.frame(
    claim_id = claim_id,
    audience_facing_claim = claim,
    producer_script = rel(producer_script),
    located_source_line = source_line,
    expression = expression,
    input_artifact = rel(input_artifact),
    output_artifact = rel(output_artifact),
    recomputed_value = as.numeric(recomputed),
    published_value = as.numeric(published),
    absolute_difference = difference,
    tolerance = tolerance,
    status = if (is.finite(difference) && difference <= tolerance) "PASS" else "FAIL",
    notes = notes,
    stringsAsFactors = FALSE)
}

# ---- S34 reproduction: full-panel residual centering ----------------------
s34 <- read.csv(S34_PANEL, check.names = FALSE)
s34_fit <- lm(inter_tau_omega ~ k_NRC_centered + tau_centered + omega_NFC_centered,
              data = s34)
s34_resid_max <- max(abs(residuals(s34_fit) - s34$inter_tau_omega_orth), na.rm = TRUE)
s34_anchor <- anchor_specs[anchor_specs$anchor_id == "S34_ORTH", ]
add_claim("SRC_S34_001",
          "The interaction shown to S35 is the full-panel residual-centered interaction.",
          SCRIPT_S34, s34_anchor$source_line, s34_anchor$expression,
          S34_PANEL, S34_PANEL, s34_resid_max, 0, 1e-12,
          "Independent OLS residuals compared with inter_tau_omega_orth.")

# ---- S35 reproduction: exact Golden-Age FM-OLS calls ---------------------
s35 <- read.csv(S35_RESULTS, check.names = TRUE)
ga35 <- s34[s34$year >= 1945 & s34$year <= 1973, ]
ga35 <- ga35[complete.cases(ga35[, c("y_t", "k_Kcap", "k_NRC", "omega_NFC")]), ]

run_s35_fmols <- function(rhs) {
  fit <- cointReg::cointRegFM(x = as.matrix(ga35[, rhs, drop = FALSE]),
                             y = ga35$y_t, deter = rep(1, nrow(ga35)),
                             bandwidth = "nw")
  as.numeric(fit$theta)
}
s35_specs <- list(
  SPEC_B_NRC_raw = list(rhs = c("k_NRC_centered", "tau_centered",
                                "omega_NFC_centered", "inter_tau_omega"),
                        names = c("intercept", "beta_scale", "beta_comp", "beta_dist", "beta_inter")),
  SPEC_B_NRC_orth = list(rhs = c("k_NRC_centered", "tau_centered",
                                 "omega_NFC_centered", "inter_tau_omega_orth"),
                         names = c("intercept", "beta_scale", "beta_comp", "beta_dist", "beta_inter"))
)
s35_reproduced <- list()
s35_fmols_anchor <- anchor_specs[anchor_specs$anchor_id == "S35_FMOLS", ]
for (spec_id in names(s35_specs)) {
  spec <- s35_specs[[spec_id]]
  theta <- setNames(run_s35_fmols(spec$rhs), spec$names)
  s35_reproduced[[spec_id]] <- theta
  rows <- s35[s35$window_id == "golden_age_1945_1973" &
                s35$spec_id == spec_id & s35$estimator == "FM_OLS", ]
  published <- c(intercept = unique(rows$intercept)[1],
                 setNames(rows$coefficient_value, rows$coefficient_name))
  for (nm in names(theta)) {
    add_claim(paste0("SRC_S35_", ifelse(grepl("orth", spec_id), "ORTH_", "RAW_"), toupper(nm)),
              paste0("S35 Golden-Age FM-OLS reproduces ", spec_id, " ", nm, "."),
              SCRIPT_S35, s35_fmols_anchor$source_line, s35_fmols_anchor$expression,
              S34_PANEL, S35_RESULTS, theta[nm], published[nm], 5e-5,
              "Tolerance reflects the five-decimal published coefficient ledger." )
  }
}

# ---- Original reconstruction reproduction --------------------------------
recon_lines <- script_lines$RECONSTRUCTION
extract_assignment <- function(name) {
  hit <- grep(paste0("^\\s*", name, "\\s*<-\\s*-?[0-9.]+"), recon_lines)
  if (length(hit) != 1L) stop("Numeric assignment not unique: ", name)
  value <- as.numeric(sub(paste0("^\\s*", name, "\\s*<-\\s*"), "", trimws(recon_lines[hit])))
  list(value = value, line = hit)
}
bk <- extract_assignment("beta_k_B")
bt <- extract_assignment("beta_tau_B")
bi <- extract_assignment("beta_inter_B")
hardcoded <- c(theta = bk$value, psi = bt$value, lambda = bi$value)
orth_s35 <- s35_reproduced$SPEC_B_NRC_orth
for (nm in names(hardcoded)) {
  published_nm <- c(theta = "beta_scale", psi = "beta_comp", lambda = "beta_inter")[[nm]]
  add_claim(paste0("SRC_RECON_COEF_", toupper(nm)),
            paste0("The reconstruction script hard-codes the S35 orthogonalized ", nm, " coefficient."),
            SCRIPT_RECON, c(theta = bk$line, psi = bt$line, lambda = bi$line)[nm],
            trimws(recon_lines[c(theta = bk$line, psi = bt$line, lambda = bi$line)[nm]]),
            S35_RESULTS, ORIGINAL_RECON, hardcoded[nm], orth_s35[published_nm], 5e-5)
}

orig <- read.csv(ORIGINAL_RECON, check.names = FALSE)
ga_orig <- s34[s34$year >= 1945 & s34$year <= 1973, ]
theta_me_old <- hardcoded["psi"] + hardcoded["lambda"] * ga_orig$omega_NFC_centered
theta_nrc_old <- hardcoded["theta"] - theta_me_old
g_p_old <- theta_nrc_old * ga_orig$g_K_NRC + theta_me_old * ga_orig$g_K_ME
ratio_old <- g_p_old / ga_orig$g_Kcap
repro_old <- data.frame(year = ga_orig$year, theta_ME_t = theta_me_old,
                        theta_NRC_t = theta_nrc_old, g_p = g_p_old,
                        theta_total_t = ratio_old)
cmp_old <- merge(repro_old, orig[, c("year", "theta_ME_t", "theta_NRC_t", "theta_total_t")],
                 by = "year", suffixes = c("_recomputed", "_published"))
series_checks <- c(
  theta_ME_t = max(abs(cmp_old$theta_ME_t_recomputed - cmp_old$theta_ME_t_published), na.rm = TRUE),
  theta_NRC_t = max(abs(cmp_old$theta_NRC_t_recomputed - cmp_old$theta_NRC_t_published), na.rm = TRUE),
  theta_total_t = max(abs(cmp_old$theta_total_t_recomputed - cmp_old$theta_total_t_published), na.rm = TRUE)
)
ratio_anchor <- anchor_specs[anchor_specs$anchor_id == "RECON_RATIO", ]
for (nm in names(series_checks)) {
  add_claim(paste0("SRC_RECON_SERIES_", toupper(nm)),
            paste0("The original reconstruction series ", nm, " is reproduced from its script."),
            SCRIPT_RECON, ratio_anchor$source_line, ratio_anchor$expression,
            S34_PANEL, ORIGINAL_RECON, series_checks[nm], 0, 1e-10)
}
published_gp <- orig$theta_total_t[match(ga_orig$year, orig$year)] * ga_orig$g_Kcap
gp_diff <- max(abs(g_p_old - published_gp), na.rm = TRUE)
gp_anchor <- anchor_specs[anchor_specs$anchor_id == "RECON_GP", ]
add_claim("SRC_RECON_GP",
          "The original productive-capacity growth series is reproduced before division by capital growth.",
          SCRIPT_RECON, gp_anchor$source_line, gp_anchor$expression,
          S34_PANEL, ORIGINAL_RECON, gp_diff, 0, 1e-10)

recon_boundary_anchor <- anchor_specs[anchor_specs$anchor_id == "RECON_OUTPUT_BOUNDARY", ]
add_claim("SRC_RECON_OUTPUT_BOUNDARY",
          "The original reconstruction anchors productive capacity to total real GDP in 1973.",
          SCRIPT_RECON, recon_boundary_anchor$source_line, recon_boundary_anchor$expression,
          SCRIPT_RECON, ORIGINAL_RECON, 1, 1, 0,
          "Script-fact check; this is an accounting-boundary observation, not a model comparison.")

# ---- S90 reproduction from D10/S34/S35 inputs -----------------------------
d10 <- read.csv(D10_PANEL, check.names = TRUE)
d10 <- d10[order(d10$year), ]
d10$k_me <- log(d10$K_ME)
d10$k_nrc <- log(d10$K_NRC)
d10$k_cap <- log(d10$K_capacity)
d10$g_me <- c(NA_real_, diff(d10$k_me))
d10$g_nrc <- c(NA_real_, diff(d10$k_nrc))
d10$g_cap <- c(NA_real_, diff(d10$k_cap))
d10$d_tau <- d10$g_me - d10$g_nrc

s90_boundary_anchor <- anchor_specs[anchor_specs$anchor_id == "S90_OUTPUT_BOUNDARY", ]
add_claim("SRC_S90_OUTPUT_BOUNDARY",
          "The S90 reconstruction fixes observed output at real NFC GVA.",
          SCRIPT_S90, s90_boundary_anchor$source_line, s90_boundary_anchor$expression,
          D10_PANEL, S90_RECON, 1, 1, 0,
          "Script-fact check; the capital boundary remains NFC in both reconstructions.")

orth_beta <- c(intercept = unname(s35_reproduced$SPEC_B_NRC_orth["intercept"]),
               theta = unname(s35_reproduced$SPEC_B_NRC_orth["beta_scale"]),
               psi = unname(s35_reproduced$SPEC_B_NRC_orth["beta_comp"]),
               phi = unname(s35_reproduced$SPEC_B_NRC_orth["beta_dist"]),
               lambda = unname(s35_reproduced$SPEC_B_NRC_orth["beta_inter"]))
delta <- coef(s34_fit)
primitive <- c(intercept = orth_beta["intercept"] - orth_beta["lambda"] * delta["(Intercept)"],
               theta = orth_beta["theta"] - orth_beta["lambda"] * delta["k_NRC_centered"],
               psi = orth_beta["psi"] - orth_beta["lambda"] * delta["tau_centered"],
               phi = orth_beta["phi"] - orth_beta["lambda"] * delta["omega_NFC_centered"],
               lambda = orth_beta["lambda"])
names(primitive) <- c("intercept", "theta", "psi", "phi", "lambda")
back <- read.csv(S90_BACKTRANSFORM, check.names = TRUE)
published_primitive <- setNames(back$primitive_back_transformed, back$term)
bt_anchor <- anchor_specs[anchor_specs$anchor_id == "S90_BACKTRANSFORM", ]
for (nm in names(primitive)) {
  add_claim(paste0("SRC_S90_PRIMITIVE_", toupper(nm)),
            paste0("S90 reproduces the primitive-basis ", nm, " coefficient."),
            SCRIPT_S90, bt_anchor$source_line, bt_anchor$expression,
            c(S34_PANEL, S35_RESULTS)[1], S90_BACKTRANSFORM,
            primitive[nm], published_primitive[nm], 5e-5)
}

# S90 reads the published S35 coefficient ledger; subsequent path checks must
# therefore use the published/back-transformed values rather than the extra
# precision recovered by independently rerunning cointRegFM above.
primitive_for_s90 <- published_primitive[c("intercept", "theta", "psi", "phi", "lambda")]

orth_published <- setNames(back$orthogonalized_coefficient, back$term)
ga_basis <- s34[s34$year >= 1945 & s34$year <= 1973, ]
fit_orth_basis <- orth_published["intercept"] +
  orth_published["theta"] * ga_basis$k_NRC_centered +
  orth_published["psi"] * ga_basis$tau_centered +
  orth_published["phi"] * ga_basis$omega_NFC_centered +
  orth_published["lambda"] * ga_basis$inter_tau_omega_orth
fit_primitive_basis <- primitive_for_s90["intercept"] +
  primitive_for_s90["theta"] * ga_basis$k_NRC_centered +
  primitive_for_s90["psi"] * ga_basis$tau_centered +
  primitive_for_s90["phi"] * ga_basis$omega_NFC_centered +
  primitive_for_s90["lambda"] * ga_basis$inter_tau_omega
orth_primitive_fit_diff <- max(abs(fit_orth_basis - fit_primitive_basis), na.rm = TRUE)
add_claim("SRC_S90_ORTH_PRIMITIVE_FIT",
          "Back-transformation changes the coefficient basis but leaves fitted capacity unchanged.",
          SCRIPT_S90, bt_anchor$source_line, bt_anchor$expression,
          c(S34_PANEL, S35_RESULTS)[1], S90_BACKTRANSFORM,
          orth_primitive_fit_diff, 0, 1e-10)

ga <- d10[d10$year >= 1945 & d10$year <= 1973, ]
ga$d <- ga$omega_NFC_productive_origin_GVA
ga$d_c <- ga$d - mean(ga$d, na.rm = TRUE)
ga$theta_tau <- primitive_for_s90["psi"] + primitive_for_s90["lambda"] * ga$d_c
ga$g_p <- primitive_for_s90["theta"] * ga$g_nrc + ga$theta_tau * (ga$g_me - ga$g_nrc)
ga$vartheta_path <- ga$g_p / ga$g_cap
ga$C_scale <- primitive_for_s90["theta"] * ga$g_nrc / ga$g_cap
ga$C_composition <- primitive_for_s90["psi"] * (ga$g_me - ga$g_nrc) / ga$g_cap
ga$C_distribution <- primitive_for_s90["lambda"] * ga$d_c * (ga$g_me - ga$g_nrc) / ga$g_cap
identity_error <- max(abs(ga$vartheta_path - ga$C_scale - ga$C_composition - ga$C_distribution),
                      na.rm = TRUE)
path_anchor <- anchor_specs[anchor_specs$anchor_id == "S90_PATH", ]
add_claim("SRC_S90_PATH_IDENTITY",
          "The observed-direction ratio equals the three exact economic contributions.",
          SCRIPT_S90, path_anchor$source_line, path_anchor$expression,
          D10_PANEL, S90_PATH, identity_error, 0, 1e-12)

s90_path <- read.csv(S90_PATH, check.names = TRUE)
s90_corrected <- s90_path[s90_path$reconstruction == "CORRECTED_PRIMITIVE_BASIS", ]
path_cmp <- merge(ga[, c("year", "g_p", "vartheta_path", "C_scale", "C_composition", "C_distribution")],
                  s90_corrected[, c("year", "g_p", "vartheta_path", "C_scale", "C_composition", "C_distribution")],
                  by = "year", suffixes = c("_recomputed", "_published"))
path_series_diff <- max(vapply(c("g_p", "vartheta_path", "C_scale", "C_composition", "C_distribution"),
  function(nm) max(abs(path_cmp[[paste0(nm, "_recomputed")]] - path_cmp[[paste0(nm, "_published")]]),
                    na.rm = TRUE), numeric(1)))
add_claim("SRC_S90_PATH_SERIES",
          "The corrected S90 capacity-growth path and contribution series reproduce from D10 levels.",
          SCRIPT_S90, path_anchor$source_line, path_anchor$expression,
          D10_PANEL, S90_PATH, path_series_diff, 0, 5e-5)

rough_L <- function(x) mean(diff(x[is.finite(x)])^2)
mean_gcap <- mean(ga$g_cap, na.rm = TRUE)
constant_ratio <- ga$g_p / mean_gcap

shapley_once <- function(df, beta) {
  modules <- c("distribution", "composition", "denominator")
  perms <- rbind(c(1,2,3), c(1,3,2), c(2,1,3), c(2,3,1), c(3,1,2), c(3,2,1))
  gbar <- mean(df$g_cap, na.rm = TRUE)
  value <- function(active) {
    state <- if ("distribution" %in% active) df$d_c else rep(0, nrow(df))
    gap <- if ("composition" %in% active) df$g_me - df$g_nrc else rep(0, nrow(df))
    den <- if ("denominator" %in% active) df$g_cap else rep(gbar, nrow(df))
    rough_L((beta["theta"] * df$g_nrc + (beta["psi"] + beta["lambda"] * state) * gap) / den)
  }
  contribution <- setNames(rep(0, 3), modules)
  for (p in seq_len(nrow(perms))) {
    active <- character(0); before <- value(active)
    for (j in perms[p, ]) {
      m <- modules[j]; active <- c(active, m); after <- value(active)
      contribution[m] <- contribution[m] + (after - before) / nrow(perms)
      before <- after
    }
  }
  full <- value(modules); baseline <- value(character(0))
  data.frame(module = modules, contribution = contribution,
             share = contribution / full, baseline_share = baseline / full)
}
shapley_recomputed <- shapley_once(ga, primitive_for_s90)
shapley_published <- read.csv(S90_SHAPLEY, check.names = TRUE)
shapley_cmp <- merge(shapley_recomputed, shapley_published[, c("module", "share", "baseline_scale_share")],
                     by = "module", suffixes = c("_recomputed", "_published"))
shapley_diff <- max(abs(shapley_cmp$share_recomputed - shapley_cmp$share_published), na.rm = TRUE)
shap_anchor <- anchor_specs[anchor_specs$anchor_id == "S90_SHAPLEY", ]
add_claim("SRC_S90_SHAPLEY",
          "The roughness shares reproduce from the script's six-order Shapley calculation.",
          SCRIPT_S90, shap_anchor$source_line, shap_anchor$expression,
          D10_PANEL, S90_SHAPLEY, shapley_diff, 0, 1e-10)

profile <- read.csv(S90_PROFILE, check.names = TRUE)
rho <- read.csv(S90_RHO, check.names = TRUE)
for (sid in rho$state_id) {
  z <- profile[profile$state_id == sid & profile$window_id == "pre_1974_full", ]
  rho_min <- z$rho[which.min(z$bic)]
  rho_pub <- rho$rho_hat[rho$state_id == sid]
  add_claim(paste0("SRC_S90_RHO_", sid),
            paste0("The BIC profile minimum reproduces the reported persistence for ", sid, "."),
            SCRIPT_S90, find_line("S90", "best_i <- which.min", TRUE),
            trimws(script_lines$S90[find_line("S90", "best_i <- which.min", TRUE)]),
            S90_PROFILE, S90_RHO, rho_min, rho_pub, 1e-12)
}

draws <- read.csv(S90_RHO_DRAWS, check.names = TRUE)
draw_count <- min(table(draws$state_id))
published_draw_count <- unique(rho$bootstrap_reps)
add_claim("SRC_S90_BOOTSTRAP_COUNT",
          "Every wage boundary uses 1,000 four-year moving-block bootstrap draws.",
          SCRIPT_S90, find_line("S90", "bootstrap_reps <-", TRUE),
          trimws(script_lines$S90[find_line("S90", "bootstrap_reps <-", TRUE)]),
          S90_RHO_DRAWS, S90_RHO, draw_count, published_draw_count[1], 0)

reconstructed <- read.csv(S90_RECON, check.names = TRUE)
anchor_error <- max(abs(reconstructed$anchor_check_mu_1973 - 1), na.rm = TRUE)
add_claim("SRC_S90_MU_ANCHOR",
          "Every reconstructed NFC utilization path is anchored at mu_1973 = 1.",
          SCRIPT_S90, find_line("S90", "yp[anchor] <- yy[anchor]", TRUE),
          trimws(script_lines$S90[find_line("S90", "yp[anchor] <- yy[anchor]", TRUE)]),
          D10_PANEL, S90_RECON, anchor_error, 0, 1e-12)

validation <- read.csv(S90_VALIDATION, check.names = TRUE)
validation_failures <- sum(validation$status != "PASS")
add_claim("SRC_S90_VALIDATION",
          "All S90 numerical identities pass their declared tolerances.",
          SCRIPT_S90, find_line("S90", "validation <- data.frame", TRUE),
          trimws(script_lines$S90[find_line("S90", "validation <- data.frame", TRUE)]),
          S90_VALIDATION, S90_VALIDATION, validation_failures, 0, 0)

claim_ledger <- do.call(rbind, claims)
write_csv(claim_ledger, file.path(CSV_DIR, "S90_beamer_claim_reproduction_ledger.csv"))
if (any(claim_ledger$status != "PASS")) {
  stop("Beamer source audit failed: ",
       paste(claim_ledger$claim_id[claim_ledger$status != "PASS"], collapse = "; "))
}

# ---- Derived presentation values ------------------------------------------
shapley <- read.csv(S90_SHAPLEY, check.names = TRUE)
influence <- read.csv(S90_INFLUENCE, check.names = TRUE)
denom <- read.csv(S90_DENOM, check.names = TRUE)
rdols <- read.csv(S90_RDOLS, check.names = TRUE)
back <- read.csv(S90_BACKTRANSFORM, check.names = TRUE)

year_row <- function(y) ga[ga$year == y, ]
y45 <- year_row(1945); y46 <- year_row(1946)
get_sh <- function(module, field) shapley[shapley$module == module, field][1]
get_rho <- function(state, field) rho[rho$state_id == state, field][1]
get_lambda <- function(state, model) {
  z <- rdols[rdols$state_id == state & rdols$window_id == "pre_1974_full" &
               rdols$model_id == model & rdols$ll_id == "LL11" &
               rdols$coefficient_role == "lambda_conditioning", ]
  z$estimate[1]
}
back_value <- function(term, col) back[back$term == term, col][1]

fmt <- function(x, digits = 2) formatC(as.numeric(x), format = "f", digits = digits)
fmtg <- function(x, digits = 3) formatC(as.numeric(x), format = "fg", digits = digits)
tex_macros <- c(
  paste0("\\providecommand{\\YearEarlyOne}{", y45$year, "}"),
  paste0("\\providecommand{\\CapacityGrowthEarlyOne}{", fmt(100 * y45$g_p, 3), "}"),
  paste0("\\providecommand{\\CapitalGrowthEarlyOne}{", fmt(100 * y45$g_cap, 3), "}"),
  paste0("\\providecommand{\\RatioEarlyOne}{", fmt(y45$vartheta_path, 2), "}"),
  paste0("\\providecommand{\\YearEarlyTwo}{", y46$year, "}"),
  paste0("\\providecommand{\\CapacityGrowthEarlyTwo}{", fmt(100 * y46$g_p, 3), "}"),
  paste0("\\providecommand{\\CapitalGrowthEarlyTwo}{", fmt(100 * y46$g_cap, 3), "}"),
  paste0("\\providecommand{\\RatioEarlyTwo}{", fmt(y46$vartheta_path, 2), "}"),
  paste0("\\providecommand{\\OrthTheta}{", fmt(back_value("theta", "orthogonalized_coefficient"), 5), "}"),
  paste0("\\providecommand{\\PrimitiveTheta}{", fmt(back_value("theta", "primitive_back_transformed"), 5), "}"),
  paste0("\\providecommand{\\OrthPsi}{", fmt(back_value("psi", "orthogonalized_coefficient"), 5), "}"),
  paste0("\\providecommand{\\PrimitivePsi}{", fmt(back_value("psi", "primitive_back_transformed"), 5), "}"),
  paste0("\\providecommand{\\InteractionLambda}{", fmt(back_value("lambda", "primitive_back_transformed"), 5), "}"),
  paste0("\\providecommand{\\OrthPrimitiveFitDifference}{", format(orth_primitive_fit_diff, scientific = TRUE, digits = 2), "}"),
  paste0("\\providecommand{\\SthirtyFourResidualDifference}{", format(s34_resid_max, scientific = TRUE, digits = 2), "}"),
  paste0("\\providecommand{\\CompositionShare}{", fmt(100 * get_sh("composition", "share"), 1), "}"),
  paste0("\\providecommand{\\CompositionShareLow}{", fmt(100 * get_sh("composition", "share_ci_low"), 1), "}"),
  paste0("\\providecommand{\\CompositionShareHigh}{", fmt(100 * get_sh("composition", "share_ci_high"), 1), "}"),
  paste0("\\providecommand{\\DenominatorShare}{", fmt(100 * get_sh("denominator", "share"), 1), "}"),
  paste0("\\providecommand{\\DistributionShare}{", fmt(100 * get_sh("distribution", "share"), 1), "}"),
  paste0("\\providecommand{\\ScaleReferenceShare}{", fmt(100 * shapley$baseline_scale_share[1], 1), "}"),
  paste0("\\providecommand{\\TopTwoInfluenceShare}{", fmt(100 * sum(head(influence$roughness_attributed_share, 2)), 1), "}"),
  paste0("\\providecommand{\\FirstYearDropReduction}{", fmt(-100 * influence$relative_L_change_if_dropped[influence$year == 1945], 1), "}"),
  paste0("\\providecommand{\\CapacityGrowthRoughness}{", fmtg(denom$L[denom$object == "capacity_growth_g_p"], 4), "}"),
  paste0("\\providecommand{\\RatioRoughness}{", fmtg(denom$L[denom$object == "vartheta_path_observed_denominator"], 4), "}"),
  paste0("\\providecommand{\\ConstantDenominatorRoughness}{", fmtg(denom$L[denom$object == "g_p_constant_window_denominator"], 4), "}"),
  paste0("\\providecommand{\\RhoNfcGva}{", fmt(get_rho("NFC_GVA", "rho_hat"), 2), "}"),
  paste0("\\providecommand{\\RhoNfcGvaLow}{", fmt(get_rho("NFC_GVA", "rho_ci_low"), 2), "}"),
  paste0("\\providecommand{\\RhoNfcGvaHigh}{", fmt(get_rho("NFC_GVA", "rho_ci_high"), 2), "}"),
  paste0("\\providecommand{\\HalfLifeNfcGva}{", fmt(get_rho("NFC_GVA", "half_life_years"), 1), "}"),
  paste0("\\providecommand{\\RhoNfcNva}{", fmt(get_rho("NFC_NVA", "rho_hat"), 2), "}"),
  paste0("\\providecommand{\\RhoNfcNvaLow}{", fmt(get_rho("NFC_NVA", "rho_ci_low"), 2), "}"),
  paste0("\\providecommand{\\RhoNfcNvaHigh}{", fmt(get_rho("NFC_NVA", "rho_ci_high"), 2), "}"),
  paste0("\\providecommand{\\HalfLifeNfcNva}{", fmt(get_rho("NFC_NVA", "half_life_years"), 1), "}"),
  paste0("\\providecommand{\\MtwoLambdaGvaHthree}{", fmt(get_lambda("NFC_GVA", "M2_H3"), 2), "}"),
  paste0("\\providecommand{\\MtwoLambdaGvaHfive}{", fmt(get_lambda("NFC_GVA", "M2_H5"), 2), "}"),
  paste0("\\providecommand{\\MtwoLambdaNvaHthree}{", fmt(get_lambda("NFC_NVA", "M2_H3"), 2), "}"),
  paste0("\\providecommand{\\MtwoLambdaNvaHfive}{", fmt(get_lambda("NFC_NVA", "M2_H5"), 2), "}"),
  paste0("\\providecommand{\\MthreeLambdaGva}{", fmt(get_lambda("NFC_GVA", "M3"), 2), "}"),
  paste0("\\providecommand{\\MthreeLambdaNva}{", fmt(get_lambda("NFC_NVA", "M3"), 2), "}"),
  paste0("\\providecommand{\\BootstrapReplications}{", published_draw_count[1], "}"),
  paste0("\\providecommand{\\ValidationCheckCount}{", nrow(validation), "}"),
  paste0("\\providecommand{\\ClaimCheckCount}{", nrow(claim_ledger), "}"),
  "\\providecommand{\\AnchorYear}{1973}",
  "\\providecommand{\\CoefficientTolerance}{5\\times10^{-5}}",
  "\\providecommand{\\AlgebraTolerance}{10^{-10}}",
  paste0("\\providecommand{\\LineSthirtyFourOrth}{", s34_anchor$source_line, "}"),
  paste0("\\providecommand{\\LineSthirtyFiveFmols}{", s35_fmols_anchor$source_line, "}"),
  paste0("\\providecommand{\\LineReconstructionRatio}{", ratio_anchor$source_line, "}"),
  paste0("\\providecommand{\\LineSninetyBacktransform}{", bt_anchor$source_line, "}"),
  paste0("\\providecommand{\\HashSthirtyFour}{", substr(provenance$md5[provenance$script_id == "S34"], 1, 10), "}"),
  paste0("\\providecommand{\\HashSthirtyFive}{", substr(provenance$md5[provenance$script_id == "S35"], 1, 10), "}"),
  paste0("\\providecommand{\\HashReconstruction}{", substr(provenance$md5[provenance$script_id == "RECONSTRUCTION"], 1, 10), "}"),
  paste0("\\providecommand{\\HashSninety}{", substr(provenance$md5[provenance$script_id == "S90"], 1, 10), "}")
)
writeLines(tex_macros, file.path(GEN_DIR, "S90_beamer_numbers.tex"), useBytes = TRUE)

write_excerpt <- function(file_name, script_id, ranges) {
  lines <- script_lines[[script_id]]
  chosen <- unique(unlist(lapply(ranges, function(r) seq.int(max(1, r[1]), min(length(lines), r[2])))))
  out <- c(paste0("# source: ", rel(script_paths[[script_id]]), " lines ",
                  paste(vapply(ranges, function(r) paste(r, collapse = "-"), character(1)), collapse = ", ")),
           lines[chosen])
  writeLines(out, file.path(GEN_DIR, file_name), useBytes = TRUE)
}
write_excerpt("S90_excerpt_S34.txt", "S34", list(c(s34_anchor$source_line - 2, s34_anchor$source_line)))
write_excerpt("S90_excerpt_S35.txt", "S35", list(c(find_line("S35", "SPEC_B_NRC_orth = list(", TRUE),
                                                       find_line("S35", "SPEC_B_NRC_orth = list(", TRUE) + 5),
                                                  c(s35_fmols_anchor$source_line - 1, s35_fmols_anchor$source_line + 1)))
write_excerpt("S90_excerpt_reconstruction.txt", "RECONSTRUCTION",
              list(c(bk$line, bi$line),
                   c(find_line("RECONSTRUCTION", "panel$theta_ME_t <-", TRUE),
                     find_line("RECONSTRUCTION", "panel$g_Yp_B <-", TRUE)),
                   c(recon_boundary_anchor$source_line, recon_boundary_anchor$source_line),
                   c(ratio_anchor$source_line - 1, ratio_anchor$source_line)))
write_excerpt("S90_excerpt_S90.txt", "S90",
              list(c(s90_boundary_anchor$source_line, s90_boundary_anchor$source_line),
                   c(bt_anchor$source_line, bt_anchor$source_line + 7),
                   c(path_anchor$source_line, path_anchor$source_line + 7)))

# ---- Presentation figures --------------------------------------------------
png(file.path(FIG_DIR, "F07_two_year_ratio_arithmetic.png"), 1600, 900, res = 180)
par(mar = c(5, 5, 3, 1))
vals <- rbind(c(100 * y45$g_p, 100 * y45$g_cap), c(100 * y46$g_p, 100 * y46$g_cap))
bp <- barplot(t(vals), beside = TRUE, col = c("#2166ac", "#b2182b"), border = NA,
              names.arg = c("1945", "1946"), ylab = "Annual log growth (%)",
              main = "The ratio falls even though capacity growth accelerates",
              ylim = c(0, max(vals) * 1.25))
legend("topleft", c("capacity growth g_p", "aggregate capital growth g_cap"),
       fill = c("#2166ac", "#b2182b"), border = NA, bty = "n")
text(colMeans(bp), apply(t(vals), 2, max) * 1.10,
     labels = c(paste0("ratio = ", fmt(y45$vartheta_path, 2)),
                paste0("ratio = ", fmt(y46$vartheta_path, 2))), font = 2)
dev.off()

png(file.path(FIG_DIR, "F08_capacity_growth_and_denominator_amplification.png"),
    1700, 1000, res = 180)
par(mfrow = c(2,1), mar = c(2.5, 5, 2.2, 1), oma = c(2, 0, 0, 0))
plot(ga$year, 100 * ga$g_p, type = "l", lwd = 3, col = "#2166ac",
     xlab = "", ylab = "g_p (%)", main = "Capacity growth moves within a narrow range")
abline(h = 0, col = "grey75")
plot(ga$year, ga$vartheta_path, type = "l", lwd = 3, col = "#b2182b",
     xlab = "", ylab = "capacity payoff ratio",
     main = "Division by annual capital growth magnifies the path")
lines(ga$year, constant_ratio, lwd = 2.5, col = "#2166ac", lty = 2)
points(c(1945, 1946), ga$vartheta_path[match(c(1945,1946), ga$year)], pch = 21,
       bg = "white", col = "black", cex = 1.2)
legend("topleft", c("observed denominator", "constant within-window denominator"),
       col = c("#b2182b", "#2166ac"), lty = c(1,2), lwd = c(3,2.5), bty = "n")
mtext("Year", side = 1, outer = TRUE, line = .5)
dev.off()

png(file.path(FIG_DIR, "F09_roughness_attribution_and_influence.png"),
    1800, 850, res = 180)
par(mfrow = c(1,2), mar = c(6, 5, 3, 1))
shares <- c(get_sh("distribution", "share"), get_sh("composition", "share"),
            get_sh("denominator", "share"), shapley$baseline_scale_share[1]) * 100
lower <- c(get_sh("distribution", "share_ci_low"), get_sh("composition", "share_ci_low"),
           get_sh("denominator", "share_ci_low"), NA) * 100
upper <- c(get_sh("distribution", "share_ci_high"), get_sh("composition", "share_ci_high"),
           get_sh("denominator", "share_ci_high"), NA) * 100
bp <- barplot(shares, names.arg = c("wage", "composition", "denom.", "structures"),
              col = c("#762a83", "#4d9221", "#b2182b", "grey65"), border = NA,
              ylab = "Share of total roughness (%)", main = "Point attribution")
arrows(bp[1:3], lower[1:3], bp[1:3], upper[1:3], angle = 90, code = 3, length = .05)
abline(h = 50, col = "grey35", lty = 2)
top <- head(influence, 8)
ord <- rev(seq_len(nrow(top)))
plot(top$roughness_attributed_share[ord] * 100, ord, type = "h", lwd = 4,
     col = ifelse(top$year[ord] %in% c(1945,1946), "#b2182b", "grey45"),
     yaxt = "n", xlab = "Attributed roughness share (%)", ylab = "",
     main = "Influential years")
points(top$roughness_attributed_share[ord] * 100, ord, pch = 19,
       col = ifelse(top$year[ord] %in% c(1945,1946), "#b2182b", "grey35"))
axis(2, at = ord, labels = top$year[ord], las = 1)
dev.off()

png(file.path(FIG_DIR, "F10_nfc_persistence_profile.png"), 1600, 900, res = 180)
par(mar = c(5, 5, 3, 1))
p_nfc <- profile[profile$window_id == "pre_1974_full" &
                   profile$state_id %in% c("NFC_GVA", "NFC_NVA"), ]
ylim <- range(p_nfc$bic - ave(p_nfc$bic, p_nfc$state_id, FUN = min), na.rm = TRUE)
plot(NA, xlim = c(0, .98), ylim = ylim, xlab = expression(rho),
     ylab = "BIC minus boundary-specific minimum",
     main = "The NFC wage state adjusts slowly")
cols <- c(NFC_GVA = "#2166ac", NFC_NVA = "#b2182b")
for (sid in names(cols)) {
  z <- p_nfc[p_nfc$state_id == sid, ]
  lines(z$rho, z$bic - min(z$bic, na.rm = TRUE), col = cols[sid], lwd = 3)
  abline(v = get_rho(sid, "rho_hat"), col = cols[sid], lty = 3)
}
legend("bottomleft", c("NFC GVA wage share", "NFC NVA wage share"),
       col = cols, lwd = 3, bty = "n")
dev.off()

adapt_state <- function(x, rho_value) {
  out <- rep(NA_real_, length(x)); out[2] <- x[1]
  for (i in 3:length(x)) out[i] <- rho_value * out[i-1] + (1-rho_value) * x[i-1]
  out
}
h3 <- rowMeans(cbind(c(NA, d10$omega_NFC_productive_origin_GVA[-nrow(d10)]),
                    c(NA, NA, d10$omega_NFC_productive_origin_GVA[-c(nrow(d10)-1, nrow(d10))]),
                    c(NA, NA, NA, d10$omega_NFC_productive_origin_GVA[-c((nrow(d10)-2):nrow(d10))])),
               na.rm = FALSE)
adaptive <- adapt_state(d10$omega_NFC_productive_origin_GVA, get_rho("NFC_GVA", "rho_hat"))
z <- d10$year >= 1940 & d10$year <= 1978
png(file.path(FIG_DIR, "F11_wage_memory_states.png"), 1600, 900, res = 180)
par(mar = c(5, 5, 3, 1))
plot(d10$year[z], d10$omega_NFC_productive_origin_GVA[z], type = "l", lwd = 2,
     col = "grey35", xlab = "Year", ylab = "NFC wage-share state",
     main = "Memory changes the state applied to newly installed technique")
lines(d10$year[z], h3[z], col = "#4d9221", lwd = 2.5)
lines(d10$year[z], adaptive[z], col = "#2166ac", lwd = 3)
legend("topleft", c("current wage share", "three-year lagged mean",
                    paste0("adaptive state, rho = ", fmt(get_rho("NFC_GVA", "rho_hat"), 2))),
       col = c("grey35", "#4d9221", "#2166ac"), lwd = c(2,2.5,3), bty = "n")
dev.off()

summary_lines <- c(
  "# S90 Beamer Source Audit",
  "",
  paste0("All ", nrow(claim_ledger), " source-to-result claims passed."),
  "",
  "The audit independently reproduces the S34 interaction residualization, S35 Golden-Age FM-OLS coefficients, the original reconstruction path, and the S90 decomposition and persistence outputs.",
  "",
  paste0("Script commit: `", git_commit[1], "`."),
  "",
  "The generated TeX macros are the sole numeric interface for the expanded Beamer addendum."
)
writeLines(summary_lines, file.path(REPORT_DIR, "S90_BEAMER_SOURCE_AUDIT.md"), useBytes = TRUE)

message("S90 Beamer source audit passed. Claims: ", nrow(claim_ledger),
        ". Generated assets: ", GEN_DIR)
