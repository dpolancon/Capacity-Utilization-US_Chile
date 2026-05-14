###############################################################################
# US_S40_theta_tot_mu_reconstruction.R
# Chapter 2 - US restricted B1 theta_tot and mu reconstruction
#
# Role:
#   Reconstructs theta_tot, productive capacity, and mu_t from the admissible
#   S30 restricted B1 pathway.
#
# Guardrails:
#   - Reconstruction stage only.
#   - Does not estimate a new cointegrating relation.
#   - Does not expand estimator grids.
#   - Uses FM-OLS as the reconstruction basis.
#   - Carries IM-OLS as robustness metadata.
#   - Carries DOLS as fragility/stress metadata only.
#   - Does not promote non-B1 specifications.
#   - Does not compute profitability.
#   - Does not touch Chile or comparative outputs.
###############################################################################

# ---- 0. Paths ----------------------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")
EXPECTED_BRANCH <- "feature/us-s40-restricted-b1"

s30_dir <- file.path(REPO, "output/US/S30_transformation_relation")
out_dir <- file.path(REPO, "output/US/S40_theta_tot_mu_reconstruction")

s30_required <- c(
  decision = "us_s30_formal_stability_decision.csv",
  disposition = "us_s30_formal_spec_disposition.csv",
  estimator_grid = "us_s30_estimator_grid.csv",
  specification_register = "us_s30_specification_register.csv",
  candidate_window_register_used = "us_s30_candidate_window_register_used.csv",
  run_manifest = "us_s30_run_manifest.csv"
)

s30_paths <- file.path(s30_dir, s30_required)
names(s30_paths) <- names(s30_required)

theta_path <- file.path(out_dir, "us_s40_theta_tot_path.csv")
capacity_path <- file.path(out_dir, "us_s40_productive_capacity_path.csv")
mu_path <- file.path(out_dir, "us_s40_mu_path.csv")
anchor_path <- file.path(out_dir, "us_s40_anchor_register.csv")
fragility_path <- file.path(out_dir, "us_s40_fragility_register.csv")
manifest_path <- file.path(out_dir, "us_s40_reconstruction_manifest.csv")
report_path <- file.path(out_dir, "US_S40_theta_tot_mu_reconstruction_report.md")

RUN_TIMESTAMP <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")

B1_SPEC_ID <- "SPEC_B1_WAGE_BASELINE"
MAIN_ESTIMATOR <- "FM_OLS"
ROBUSTNESS_ESTIMATOR <- "IM_OLS"
STRESS_ESTIMATOR <- "DOLS"

SECTOR_TARGET <- "NFCorp"
COMPOSITION_BASIS <- "ME_NRC_component_proxy"
COMPOSITION_TIER <- "Tier B"
DIRECT_SECTOR_ASSET_SPLIT <- FALSE
CAPACITY_REGISTER <- "gross_real_GPIM"

# ---- 1. Helpers --------------------------------------------------------------
read_csv_base <- function(path, check_names = FALSE) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = check_names)
}

write_csv_base <- function(df, path) {
  utils::write.csv(df, path, row.names = FALSE, na = "")
}

require_cols <- function(df, cols, object_name) {
  missing <- setdiff(cols, names(df))
  if (length(missing) > 0L) {
    stop(
      object_name, " is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

as_bool <- function(x) {
  if (is.logical(x)) return(x)
  y <- tolower(trimws(as.character(x)))
  out <- rep(NA, length(y))
  out[y %in% c("true", "t", "1", "yes", "y")] <- TRUE
  out[y %in% c("false", "f", "0", "no", "n")] <- FALSE
  out
}

as_num <- function(x) suppressWarnings(as.numeric(x))

is_true_scalar <- function(x) {
  y <- as_bool(x)
  length(y) == 1L && isTRUE(y[1L])
}

is_false_scalar <- function(x) {
  y <- as_bool(x)
  length(y) == 1L && identical(y[1L], FALSE)
}

collapse_or_na <- function(x) {
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  if (length(x) == 0L) return(NA_character_)
  paste(unique(x), collapse = "; ")
}

manifest_value <- function(manifest, item) {
  hit <- manifest$value[manifest$item == item]
  if (length(hit) == 0L || is.na(hit[1L]) || !nzchar(hit[1L])) return(NA_character_)
  hit[1L]
}

normalize_existing_path <- function(path) {
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

safe_mean <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  mean(x)
}

safe_min <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  min(x)
}

safe_max <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  max(x)
}

get_branch <- function(repo) {
  out <- tryCatch(
    system2("git", c("-C", repo, "branch", "--show-current"), stdout = TRUE, stderr = TRUE),
    error = function(e) NA_character_
  )
  out <- out[!is.na(out) & nzchar(out)]
  if (length(out) == 0L) return(NA_character_)
  trimws(out[1L])
}

md_table <- function(df, n = Inf) {
  if (is.null(df) || nrow(df) == 0L) return("_No rows._")
  df <- head(df, n)
  df[] <- lapply(df, function(x) {
    if (is.numeric(x)) {
      ifelse(is.na(x), "", formatC(x, digits = 6, format = "fg"))
    } else {
      y <- as.character(x)
      y[is.na(y)] <- ""
      y
    }
  })
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1L, function(z) paste0("| ", paste(z, collapse = " | "), " |"))
  c(header, sep, rows)
}

extract_estimator_coef <- function(estimator_grid, window_id, estimator, coefficient) {
  rows <- estimator_grid[
    estimator_grid$spec_id == B1_SPEC_ID &
      estimator_grid$window_id == window_id &
      estimator_grid$estimator == estimator &
      estimator_grid$coefficient == coefficient &
      estimator_grid$status == "estimated" &
      estimator_grid$estimator_status == "ok",
    ,
    drop = FALSE
  ]
  if (nrow(rows) != 1L) {
    stop(
      "Expected exactly one estimated ", estimator, " coefficient for ",
      B1_SPEC_ID, "/", window_id, "/", coefficient, "; found ", nrow(rows), ".",
      call. = FALSE
    )
  }
  value <- as_num(rows$estimate[1L])
  if (!is.finite(value)) {
    stop("Coefficient ", estimator, "/", coefficient, " is not finite.", call. = FALSE)
  }
  value
}

extract_optional_estimator_coef <- function(estimator_grid, window_id, estimator, coefficient) {
  rows <- estimator_grid[
    estimator_grid$spec_id == B1_SPEC_ID &
      estimator_grid$window_id == window_id &
      estimator_grid$estimator == estimator &
      estimator_grid$coefficient == coefficient,
    ,
    drop = FALSE
  ]
  if (nrow(rows) == 0L) return(NA_real_)
  ok_rows <- rows[rows$status == "estimated" & rows$estimator_status == "ok", , drop = FALSE]
  if (nrow(ok_rows) == 0L) return(NA_real_)
  as_num(ok_rows$estimate[1L])
}

estimator_status_text <- function(estimator_grid, window_id, estimator) {
  rows <- estimator_grid[
    estimator_grid$spec_id == B1_SPEC_ID &
      estimator_grid$window_id == window_id &
      estimator_grid$estimator == estimator,
    ,
    drop = FALSE
  ]
  if (nrow(rows) == 0L) return("not_detected")
  collapse_or_na(paste(rows$coefficient, rows$status, rows$estimator_status, sep = "="))
}

# ---- 2. Preconditions and S30 gate ------------------------------------------
active_branch <- get_branch(REPO)
if (!identical(active_branch, EXPECTED_BRANCH)) {
  stop(
    "Active branch must be ", EXPECTED_BRANCH, "; detected ",
    ifelse(is.na(active_branch), "<unknown>", active_branch), ".",
    call. = FALSE
  )
}

missing_s30 <- names(s30_paths)[!file.exists(s30_paths)]
if (length(missing_s30) > 0L) {
  stop(
    "Missing required S30 input file(s): ",
    paste(unname(s30_required[missing_s30]), collapse = ", "),
    call. = FALSE
  )
}

decision <- read_csv_base(s30_paths[["decision"]])
disposition <- read_csv_base(s30_paths[["disposition"]])
estimator_grid <- read_csv_base(s30_paths[["estimator_grid"]])
spec_register <- read_csv_base(s30_paths[["specification_register"]])
window_register <- read_csv_base(s30_paths[["candidate_window_register_used"]])
run_manifest <- read_csv_base(s30_paths[["run_manifest"]])

require_cols(
  decision,
  c(
    "candidate_spec_id", "tier1_pass", "s40_gate", "non_b1_specs_promoted",
    "no_s40_code", "no_mu_computation", "no_chile_outputs",
    "tier2_evidence_class", "dols_fragility_flag", "dols_veto",
    "tier1_surviving_dols_contradiction_windows"
  ),
  "us_s30_formal_stability_decision.csv"
)
require_cols(
  disposition,
  c(
    "spec_id", "under_formal_evaluation", "restricted_s40_candidate",
    "formal_promotion_allowed"
  ),
  "us_s30_formal_spec_disposition.csv"
)
require_cols(
  estimator_grid,
  c(
    "window_id", "window_role", "year_start", "year_end", "estimator",
    "spec_id", "coefficient", "estimate", "status", "estimator_status"
  ),
  "us_s30_estimator_grid.csv"
)
require_cols(
  spec_register,
  c("spec_id", "formula_label", "regressors", "promotion_eligible", "diagnostic_only"),
  "us_s30_specification_register.csv"
)
require_cols(
  window_register,
  c("window_id", "year_start", "year_end", "role", "available"),
  "us_s30_candidate_window_register_used.csv"
)
require_cols(run_manifest, c("item", "value"), "us_s30_run_manifest.csv")

if (nrow(decision) != 1L) {
  stop("S40 requires exactly one S30 formal stability decision row.", call. = FALSE)
}

gate_failures <- character(0)
if (!identical(decision$candidate_spec_id[1L], B1_SPEC_ID)) {
  gate_failures <- c(gate_failures, "candidate_spec_id is not SPEC_B1_WAGE_BASELINE")
}
if (!is_true_scalar(decision$tier1_pass[1L])) {
  gate_failures <- c(gate_failures, "tier1_pass is not TRUE")
}
if (!decision$s40_gate[1L] %in% c("pass_restricted", "pass_restricted_fragility_flag")) {
  gate_failures <- c(gate_failures, "s40_gate is not pass_restricted or pass_restricted_fragility_flag")
}
if (!is_false_scalar(decision$non_b1_specs_promoted[1L])) {
  gate_failures <- c(gate_failures, "non_b1_specs_promoted is not FALSE")
}
if (!is_true_scalar(decision$no_s40_code[1L])) {
  gate_failures <- c(gate_failures, "no_s40_code is not TRUE")
}
if (!is_true_scalar(decision$no_mu_computation[1L])) {
  gate_failures <- c(gate_failures, "no_mu_computation is not TRUE")
}
if (!is_true_scalar(decision$no_chile_outputs[1L])) {
  gate_failures <- c(gate_failures, "no_chile_outputs is not TRUE")
}

if (length(gate_failures) > 0L) {
  stop(
    "S40 upstream gate failed: ",
    paste(gate_failures, collapse = "; "),
    call. = FALSE
  )
}

b1_disposition <- disposition[disposition$spec_id == B1_SPEC_ID, , drop = FALSE]
if (nrow(b1_disposition) != 1L ||
    !is_true_scalar(b1_disposition$under_formal_evaluation[1L]) ||
    !is_true_scalar(b1_disposition$restricted_s40_candidate[1L]) ||
    !is_true_scalar(b1_disposition$formal_promotion_allowed[1L])) {
  stop("B1 is not the single formally admissible restricted S40 candidate.", call. = FALSE)
}

non_b1_promoted <- disposition[
  disposition$spec_id != B1_SPEC_ID &
    as_bool(disposition$formal_promotion_allowed) %in% TRUE,
  ,
  drop = FALSE
]
if (nrow(non_b1_promoted) > 0L) {
  stop(
    "Non-B1 formal promotion detected: ",
    paste(non_b1_promoted$spec_id, collapse = ", "),
    call. = FALSE
  )
}

b1_spec <- spec_register[spec_register$spec_id == B1_SPEC_ID, , drop = FALSE]
if (nrow(b1_spec) != 1L ||
    !identical(b1_spec$formula_label[1L], "y_t ~ k_t + omega_k_t")) {
  stop("B1 specification register row does not match the locked B1 formula.", call. = FALSE)
}

# ---- 3. Reconstruction basis -------------------------------------------------
benchmark_windows <- window_register[
  window_register$role == "benchmark" &
    as_bool(window_register$available) %in% TRUE,
  ,
  drop = FALSE
]
if (nrow(benchmark_windows) != 1L) {
  stop(
    "Expected exactly one predeclared S30 benchmark window; found ",
    nrow(benchmark_windows), ".",
    call. = FALSE
  )
}

basis_window_id <- benchmark_windows$window_id[1L]
basis_window_role <- benchmark_windows$role[1L]
basis_year_start <- as.integer(as_num(benchmark_windows$year_start[1L]))
basis_year_end <- as.integer(as_num(benchmark_windows$year_end[1L]))

fm_const <- extract_estimator_coef(estimator_grid, basis_window_id, MAIN_ESTIMATOR, "const")
fm_k <- extract_estimator_coef(estimator_grid, basis_window_id, MAIN_ESTIMATOR, "k_t")
fm_omega_k <- extract_estimator_coef(estimator_grid, basis_window_id, MAIN_ESTIMATOR, "omega_k_t")

im_const <- extract_optional_estimator_coef(estimator_grid, basis_window_id, ROBUSTNESS_ESTIMATOR, "const")
im_k <- extract_optional_estimator_coef(estimator_grid, basis_window_id, ROBUSTNESS_ESTIMATOR, "k_t")
im_omega_k <- extract_optional_estimator_coef(estimator_grid, basis_window_id, ROBUSTNESS_ESTIMATOR, "omega_k_t")

dols_const <- extract_optional_estimator_coef(estimator_grid, basis_window_id, STRESS_ESTIMATOR, "const")
dols_k <- extract_optional_estimator_coef(estimator_grid, basis_window_id, STRESS_ESTIMATOR, "k_t")
dols_omega_k <- extract_optional_estimator_coef(estimator_grid, basis_window_id, STRESS_ESTIMATOR, "omega_k_t")

im_status <- estimator_status_text(estimator_grid, basis_window_id, ROBUSTNESS_ESTIMATOR)
dols_status <- estimator_status_text(estimator_grid, basis_window_id, STRESS_ESTIMATOR)

# ---- 4. Detect and read S20/source-of-truth panel ----------------------------
input_panel_from_manifest <- manifest_value(run_manifest, "input_panel")
if (is.na(input_panel_from_manifest)) {
  stop("S30 run manifest does not declare input_panel.", call. = FALSE)
}

input_panel_path <- normalize_existing_path(input_panel_from_manifest)
panel <- read_csv_base(input_panel_path, check_names = TRUE)

require_cols(
  panel,
  c(
    "year", "Y_real", "y_t", "k_t", "omega_t", "omega_k_t",
    "sector_target", "composition_basis", "composition_tier",
    "direct_sector_asset_split", "capacity_register"
  ),
  "S30 input panel"
)

if (!any(panel$sector_target == SECTOR_TARGET, na.rm = TRUE)) {
  stop("Input panel does not preserve sector_target = NFCorp.", call. = FALSE)
}
if (!any(panel$composition_basis == COMPOSITION_BASIS, na.rm = TRUE)) {
  stop("Input panel does not preserve composition_basis = ME_NRC_component_proxy.", call. = FALSE)
}
if (!any(panel$composition_tier == COMPOSITION_TIER, na.rm = TRUE)) {
  stop("Input panel does not preserve composition_tier = Tier B.", call. = FALSE)
}
if (!any(as_bool(panel$direct_sector_asset_split) %in% FALSE, na.rm = TRUE)) {
  stop("Input panel does not preserve direct_sector_asset_split = FALSE.", call. = FALSE)
}
if (!any(grepl("^gross_real_GPIM", panel$capacity_register), na.rm = TRUE)) {
  stop("Input panel does not preserve a gross real GPIM capacity register.", call. = FALSE)
}

panel_recon <- data.frame(
  year = as.integer(as_num(panel$year)),
  Y_real = as_num(panel$Y_real),
  y_t = as_num(panel$y_t),
  k_t = as_num(panel$k_t),
  omega_t = as_num(panel$omega_t),
  omega_k_t = as_num(panel$omega_k_t),
  stringsAsFactors = FALSE
)

valid_rows <- is.finite(panel_recon$year) &
  is.finite(panel_recon$Y_real) &
  panel_recon$Y_real > 0 &
  is.finite(panel_recon$k_t) &
  is.finite(panel_recon$omega_t) &
  is.finite(panel_recon$omega_k_t)

if (!any(valid_rows)) {
  stop("No valid panel rows are available for S40 reconstruction.", call. = FALSE)
}

panel_recon <- panel_recon[valid_rows, , drop = FALSE]
panel_recon <- panel_recon[order(panel_recon$year), , drop = FALSE]

omega_k_identity_gap <- panel_recon$omega_k_t - (panel_recon$omega_t * panel_recon$k_t)
omega_k_identity_max_abs_gap <- max(abs(omega_k_identity_gap), na.rm = TRUE)

# ---- 5. Reconstruct theta_tot, Yp, and mu_t ---------------------------------
s40_fragility_flag <- identical(decision$s40_gate[1L], "pass_restricted_fragility_flag")

panel_recon$theta_tot <- fm_k + (fm_omega_k * panel_recon$omega_t)
panel_recon$log_Yp_unanchored <- fm_const +
  (fm_k * panel_recon$k_t) +
  (fm_omega_k * panel_recon$omega_k_t)
panel_recon$Yp_unanchored <- exp(panel_recon$log_Yp_unanchored)

anchor_rows <- panel_recon$year >= basis_year_start &
  panel_recon$year <= basis_year_end &
  is.finite(panel_recon$Y_real) &
  is.finite(panel_recon$Yp_unanchored) &
  panel_recon$Yp_unanchored > 0

if (!any(anchor_rows)) {
  stop("No valid rows are available in the S30 benchmark anchor window.", call. = FALSE)
}

anchor_scale_factor <- mean(panel_recon$Y_real[anchor_rows] / panel_recon$Yp_unanchored[anchor_rows])
if (!is.finite(anchor_scale_factor) || anchor_scale_factor <= 0) {
  stop("Computed anchor scale factor is not positive and finite.", call. = FALSE)
}

log_anchor_shift <- log(anchor_scale_factor)
panel_recon$Yp <- panel_recon$Yp_unanchored * anchor_scale_factor
panel_recon$log_Yp <- log(panel_recon$Yp)
panel_recon$mu_t <- panel_recon$Y_real / panel_recon$Yp

anchor_check_mean_mu <- mean(panel_recon$mu_t[anchor_rows])
anchor_observations <- sum(anchor_rows)

# ---- 6. Output tables --------------------------------------------------------
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

common_metadata <- data.frame(
  candidate_spec_id = B1_SPEC_ID,
  reconstruction_estimator = MAIN_ESTIMATOR,
  robustness_estimator = ROBUSTNESS_ESTIMATOR,
  stress_diagnostic_estimator = STRESS_ESTIMATOR,
  reconstruction_window_id = basis_window_id,
  reconstruction_window_role = basis_window_role,
  reconstruction_year_start = basis_year_start,
  reconstruction_year_end = basis_year_end,
  sector_target = SECTOR_TARGET,
  composition_basis = COMPOSITION_BASIS,
  composition_tier = COMPOSITION_TIER,
  direct_sector_asset_split = DIRECT_SECTOR_ASSET_SPLIT,
  capacity_register = CAPACITY_REGISTER,
  fragility_flag = s40_fragility_flag,
  stringsAsFactors = FALSE
)

theta_tot_path <- cbind(
  panel_recon[
    ,
    c("year", "omega_t", "omega_k_t", "theta_tot"),
    drop = FALSE
  ],
  data.frame(
    beta_const_fm_ols = fm_const,
    beta_k_t_fm_ols = fm_k,
    beta_omega_k_t_fm_ols = fm_omega_k,
    theta_tot_formula = "beta_k_t_fm_ols + beta_omega_k_t_fm_ols * omega_t",
    im_ols_beta_const = im_const,
    im_ols_beta_k_t = im_k,
    im_ols_beta_omega_k_t = im_omega_k,
    im_ols_metadata_status = im_status,
    dols_fragility_metadata_status = dols_status,
    stringsAsFactors = FALSE
  ),
  common_metadata[rep(1L, nrow(panel_recon)), , drop = FALSE]
)

productive_capacity_path <- cbind(
  panel_recon[
    ,
    c(
      "year", "Y_real", "y_t", "k_t", "omega_t", "omega_k_t",
      "theta_tot", "log_Yp_unanchored", "Yp_unanchored",
      "log_Yp", "Yp"
    ),
    drop = FALSE
  ],
  data.frame(
    anchor_variable = "mu_t",
    anchor_window_id = basis_window_id,
    anchor_year_start = basis_year_start,
    anchor_year_end = basis_year_end,
    anchor_value = 1,
    anchor_scale_factor = anchor_scale_factor,
    log_anchor_shift = log_anchor_shift,
    anchor_status = "newly_declared",
    stringsAsFactors = FALSE
  ),
  common_metadata[rep(1L, nrow(panel_recon)), , drop = FALSE]
)

mu_path_df <- cbind(
  panel_recon[
    ,
    c("year", "Y_real", "Yp", "mu_t"),
    drop = FALSE
  ],
  data.frame(
    mu_formula = "Y_real / Yp",
    anchor_variable = "mu_t",
    anchor_window_id = basis_window_id,
    anchor_year_start = basis_year_start,
    anchor_year_end = basis_year_end,
    anchor_value = 1,
    anchor_check_mean_mu = anchor_check_mean_mu,
    stringsAsFactors = FALSE
  ),
  common_metadata[rep(1L, nrow(panel_recon)), , drop = FALSE]
)

anchor_register <- data.frame(
  run_timestamp = RUN_TIMESTAMP,
  candidate_spec_id = B1_SPEC_ID,
  anchor_variable = "mu_t",
  anchor_year = NA_integer_,
  anchor_window = basis_window_id,
  anchor_year_start = basis_year_start,
  anchor_year_end = basis_year_end,
  anchor_value = 1,
  normalization_rule = paste(
    "Scale FM-OLS B1 unanchored productive capacity by",
    "mean(Y_real / Yp_unanchored) over the S30 benchmark window so",
    "mean(mu_t) = 1 in that window."
  ),
  rationale = paste(
    "No prior S30 anchor is clearly available. The default anchor is newly",
    "declared from the predeclared S30 benchmark window, not from a searched",
    "window or a new estimator."
  ),
  inherited_new_status = "newly_declared",
  anchor_scale_factor = anchor_scale_factor,
  log_anchor_shift = log_anchor_shift,
  anchor_observations = anchor_observations,
  anchor_check_mean_mu = anchor_check_mean_mu,
  input_panel_path = input_panel_path,
  fragility_flag = s40_fragility_flag,
  stringsAsFactors = FALSE
)

dols_veto <- as_bool(decision$dols_veto[1L])
dols_veto_disabled <- length(dols_veto) == 1L && identical(dols_veto[1L], FALSE)

fragility_register <- data.frame(
  run_timestamp = RUN_TIMESTAMP,
  candidate_spec_id = B1_SPEC_ID,
  s30_gate = decision$s40_gate[1L],
  fragility_flag = s40_fragility_flag,
  s30_tier2_evidence_class = decision$tier2_evidence_class[1L],
  dols_fragility_flag = as_bool(decision$dols_fragility_flag[1L]),
  dols_contradiction_windows = decision$tier1_surviving_dols_contradiction_windows[1L],
  dols_veto = as_bool(decision$dols_veto[1L]),
  dols_veto_disabled = dols_veto_disabled,
  dols_reconstruction_basis = FALSE,
  s40_admissibility_status = if (s40_fragility_flag) {
    "admissible_restricted_b1_under_fragility"
  } else {
    "admissible_restricted_b1"
  },
  im_ols_robustness_metadata_status = im_status,
  dols_fragility_metadata_status = dols_status,
  stringsAsFactors = FALSE
)

write_csv_base(theta_tot_path, theta_path)
write_csv_base(productive_capacity_path, capacity_path)
write_csv_base(mu_path_df, mu_path)
write_csv_base(anchor_register, anchor_path)
write_csv_base(fragility_register, fragility_path)

# ---- 7. Manifest -------------------------------------------------------------
output_files <- c(
  theta_tot_path = theta_path,
  productive_capacity_path = capacity_path,
  mu_path = mu_path,
  anchor_register = anchor_path,
  fragility_register = fragility_path,
  reconstruction_manifest = manifest_path,
  reconstruction_report = report_path
)

manifest <- rbind(
  data.frame(
    item = c(
      "script",
      "run_timestamp",
      "active_branch",
      "output_dir",
      "candidate_spec_id",
      "s30_gate",
      "fragility_flag",
      "input_panel_path",
      "input_panel_detection_method",
      "input_panel_year_min",
      "input_panel_year_max",
      "input_capacity_register_detected",
      "sector_target",
      "composition_basis",
      "composition_tier",
      "direct_sector_asset_split",
      "capacity_register",
      "reconstruction_basis_estimator",
      "robustness_metadata_estimator",
      "stress_metadata_estimator",
      "reconstruction_window_id",
      "reconstruction_year_start",
      "reconstruction_year_end",
      "fm_ols_beta_const",
      "fm_ols_beta_k_t",
      "fm_ols_beta_omega_k_t",
      "im_ols_metadata_status",
      "dols_fragility_metadata_status",
      "omega_k_identity_max_abs_gap",
      "anchor_variable",
      "anchor_window",
      "anchor_year_start",
      "anchor_year_end",
      "anchor_value",
      "anchor_inherited_new_status",
      "anchor_scale_factor",
      "anchor_check_mean_mu",
      "new_cointegrating_relation_estimated",
      "estimator_grid_expanded",
      "dols_used_as_reconstruction_basis",
      "non_b1_specifications_promoted",
      "profitability_computed",
      "chile_outputs_touched",
      "comparative_outputs_created",
      "threshold_fgls_activated",
      "theta_m_directly_estimated",
      "mu_identified_by_residual",
      "silent_anchor_choice",
      "hard_prohibitions_violated"
    ),
    value = as.character(c(
      "codes/US_S40_theta_tot_mu_reconstruction.R",
      RUN_TIMESTAMP,
      active_branch,
      out_dir,
      B1_SPEC_ID,
      decision$s40_gate[1L],
      s40_fragility_flag,
      input_panel_path,
      "S30 run manifest item input_panel",
      safe_min(panel_recon$year),
      safe_max(panel_recon$year),
      collapse_or_na(panel$capacity_register),
      SECTOR_TARGET,
      COMPOSITION_BASIS,
      COMPOSITION_TIER,
      DIRECT_SECTOR_ASSET_SPLIT,
      CAPACITY_REGISTER,
      MAIN_ESTIMATOR,
      ROBUSTNESS_ESTIMATOR,
      STRESS_ESTIMATOR,
      basis_window_id,
      basis_year_start,
      basis_year_end,
      fm_const,
      fm_k,
      fm_omega_k,
      im_status,
      dols_status,
      omega_k_identity_max_abs_gap,
      "mu_t",
      basis_window_id,
      basis_year_start,
      basis_year_end,
      1,
      "newly_declared",
      anchor_scale_factor,
      anchor_check_mean_mu,
      FALSE,
      FALSE,
      FALSE,
      FALSE,
      FALSE,
      FALSE,
      FALSE,
      FALSE,
      FALSE,
      FALSE,
      FALSE,
      FALSE
    )),
    stringsAsFactors = FALSE
  ),
  data.frame(
    item = paste0("s30_input_", names(s30_paths)),
    value = normalizePath(unname(s30_paths), winslash = "/", mustWork = TRUE),
    stringsAsFactors = FALSE
  ),
  data.frame(
    item = paste0("output_", names(output_files)),
    value = normalizePath(unname(output_files), winslash = "/", mustWork = FALSE),
    stringsAsFactors = FALSE
  )
)

write_csv_base(manifest, manifest_path)

# ---- 8. Report ---------------------------------------------------------------
gate_report <- data.frame(
  check = c(
    "candidate_spec_id",
    "tier1_pass",
    "s40_gate",
    "non_b1_specs_promoted",
    "no_s40_code",
    "no_mu_computation",
    "no_chile_outputs"
  ),
  value = c(
    decision$candidate_spec_id[1L],
    decision$tier1_pass[1L],
    decision$s40_gate[1L],
    decision$non_b1_specs_promoted[1L],
    decision$no_s40_code[1L],
    decision$no_mu_computation[1L],
    decision$no_chile_outputs[1L]
  ),
  stringsAsFactors = FALSE
)

basis_report <- data.frame(
  field = c(
    "main reconstruction estimator",
    "robustness metadata estimator",
    "fragility/stress metadata estimator",
    "basis specification",
    "basis window",
    "FM-OLS const",
    "FM-OLS k_t",
    "FM-OLS omega_k_t"
  ),
  value = c(
    MAIN_ESTIMATOR,
    ROBUSTNESS_ESTIMATOR,
    STRESS_ESTIMATOR,
    B1_SPEC_ID,
    paste0(basis_window_id, " (", basis_year_start, "-", basis_year_end, ")"),
    fm_const,
    fm_k,
    fm_omega_k
  ),
  stringsAsFactors = FALSE
)

anchor_report <- anchor_register[
  ,
  c(
    "anchor_variable", "anchor_window", "anchor_year_start", "anchor_year_end",
    "anchor_value", "inherited_new_status", "anchor_scale_factor",
    "anchor_check_mean_mu"
  ),
  drop = FALSE
]

fragility_report <- fragility_register[
  ,
  c(
    "s30_gate", "fragility_flag", "s30_tier2_evidence_class",
    "dols_fragility_flag", "dols_contradiction_windows",
    "dols_veto_disabled", "s40_admissibility_status"
  ),
  drop = FALSE
]

prohibition_report <- data.frame(
  prohibition = c(
    "new cointegrating relation estimated",
    "estimator grid expanded",
    "DOLS used as reconstruction basis",
    "non-B1 specifications promoted",
    "profitability computed",
    "Chile outputs touched",
    "comparative outputs created",
    "threshold-FGLS activated",
    "theta_t^M directly estimated",
    "mu_t identified by residual",
    "silent anchor choice"
  ),
  violated = rep(FALSE, 11L),
  stringsAsFactors = FALSE
)

report_lines <- c(
  "# US S40 Theta_tot and Mu Reconstruction Report",
  "",
  "## 1. Purpose",
  "",
  paste(
    "S40 reconstructs theta_tot, productive capacity, and mu_t from the",
    "already-adjudicated S30 restricted B1 pathway. It is a reconstruction",
    "stage, not an estimator stage."
  ),
  "",
  "S40 proceeds as a restricted B1 reconstruction under fragility, not as a clean benchmark promotion.",
  "",
  "## 2. Upstream S30 gate",
  "",
  md_table(gate_report),
  "",
  "## 3. Input panel",
  "",
  paste0("- Detected panel path: ", input_panel_path),
  paste0("- Detection method: S30 run manifest item `input_panel`."),
  "",
  "## 4. Reconstruction basis",
  "",
  paste(
    "FM-OLS is the main reconstruction basis. IM-OLS is carried as",
    "robustness metadata. DOLS is carried only as fragility/stress metadata",
    "and does not define theta_tot, Yp, mu_t, anchoring, or admissibility."
  ),
  "",
  md_table(basis_report),
  "",
  "## 5. Reconstruction sequence",
  "",
  paste(
    "The B1 reduced-form relation `y_t ~ k_t + omega_k_t` is transformed into",
    "`theta_tot = beta_k_t + beta_omega_k_t * omega_t`. Productive capacity is",
    "then reconstructed from the FM-OLS B1 fitted productive-capacity path,",
    "level anchored explicitly, and mu_t is derived as `Y_real / Yp`."
  ),
  "",
  "## 6. Anchor",
  "",
  md_table(anchor_report),
  "",
  paste0("- Normalization rule: ", anchor_register$normalization_rule[1L]),
  paste0("- Rationale: ", anchor_register$rationale[1L]),
  "",
  "## 7. Fragility",
  "",
  md_table(fragility_report),
  "",
  "## 8. Hard prohibitions",
  "",
  md_table(prohibition_report),
  "",
  "## 9. Output files",
  "",
  md_table(
    data.frame(
      output = basename(unname(output_files)),
      path = normalizePath(unname(output_files), winslash = "/", mustWork = FALSE),
      stringsAsFactors = FALSE
    )
  )
)

writeLines(report_lines, report_path, useBytes = TRUE)

message("US S40 restricted B1 reconstruction complete.")
message("Input panel: ", input_panel_path)
message("Anchor: ", basis_window_id, " ", basis_year_start, "-", basis_year_end, " mean(mu_t)=1")
message("Fragility flag: ", s40_fragility_flag)
