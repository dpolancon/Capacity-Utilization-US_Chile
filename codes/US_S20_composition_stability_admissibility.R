###############################################################################
# US_S20_composition_stability_admissibility.R
# Chapter 2 — US composition, window, and stability admissibility layer
#
# Role in locked architecture:
#   S20 = composition, mechanization, periodization, and admissibility.
#
# This script does not perform final coefficient recovery and does not reconstruct
# productive capacity or utilization. OLS diagnostics here are admissibility scans
# only; FM-OLS/IM-OLS/DOLS estimator roles belong to S30/S90.
#
# Inputs:
#   data/final/US/us_source_of_truth_panel.csv
#
# Main outputs:
#   data/processed/US/us_s20_admissibility_panel.csv
#   output/US/S20_composition_admissibility/us_s20_window_admissibility_summary.csv
#   output/US/S20_composition_admissibility/US_S20_admissibility_summary.md
###############################################################################

# ---- 0. Paths ----------------------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")

in_panel_path <- file.path(REPO, "data/final/US/us_source_of_truth_panel.csv")
out_data_dir  <- file.path(REPO, "data/processed/US")
out_dir       <- file.path(REPO, "output/US/S20_composition_admissibility")
out_log_dir   <- file.path(REPO, "artifacts/repo_state_logs/us_s20_composition_admissibility")

for (p in c(out_data_dir, out_dir, out_log_dir)) {
  dir.create(p, recursive = TRUE, showWarnings = FALSE)
}

# ---- 1. Helpers --------------------------------------------------------------
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

first_existing_name <- function(df, candidates) {
  hit <- intersect(candidates, names(df))
  if (length(hit) == 0L) return(NA_character_)
  hit[1L]
}

safe_log <- function(x) {
  out <- rep(NA_real_, length(x))
  ok <- is.finite(x) & x > 0
  out[ok] <- log(x[ok])
  out
}

safe_diff_log <- function(x) {
  lx <- safe_log(x)
  c(NA_real_, diff(lx))
}

safe_cor <- function(x, y) {
  ok <- is.finite(x) & is.finite(y)
  if (sum(ok) < 3L) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok]))
}

safe_min <- function(x) {
  ok <- is.finite(x)
  if (!any(ok)) return(NA_real_)
  min(x[ok])
}

safe_mean <- function(x) {
  ok <- is.finite(x)
  if (!any(ok)) return(NA_real_)
  mean(x[ok])
}

safe_max <- function(x) {
  ok <- is.finite(x)
  if (!any(ok)) return(NA_real_)
  max(x[ok])
}

safe_vif_pair <- function(x1, x2) {
  ok <- is.finite(x1) & is.finite(x2)
  if (sum(ok) < 5L) return(c(VIF_x1 = NA_real_, VIF_x2 = NA_real_))
  d <- data.frame(x1 = x1[ok], x2 = x2[ok])
  r2_1 <- tryCatch(summary(lm(x1 ~ x2, data = d))$r.squared, error = function(e) NA_real_)
  r2_2 <- tryCatch(summary(lm(x2 ~ x1, data = d))$r.squared, error = function(e) NA_real_)
  c(
    VIF_x1 = ifelse(is.finite(r2_1) && r2_1 < 1, 1 / (1 - r2_1), NA_real_),
    VIF_x2 = ifelse(is.finite(r2_2) && r2_2 < 1, 1 / (1 - r2_2), NA_real_)
  )
}

safe_condition_number <- function(X) {
  X <- as.matrix(X)
  ok <- apply(X, 1L, function(z) all(is.finite(z)))
  X <- X[ok, , drop = FALSE]
  if (nrow(X) <= ncol(X)) return(NA_real_)
  XtX <- crossprod(X)
  eig <- tryCatch(eigen(XtX, symmetric = TRUE, only.values = TRUE)$values, error = function(e) NA_real_)
  if (any(!is.finite(eig))) return(NA_real_)
  min_eig <- max(min(eig), .Machine$double.eps)
  sqrt(max(eig) / min_eig)
}

ols_scan <- function(df, formula_obj) {
  fit <- tryCatch(lm(formula_obj, data = df), error = function(e) NULL)
  if (is.null(fit)) {
    return(list(ok = FALSE, n = nrow(df)))
  }
  co <- coef(summary(fit))
  out <- list(ok = TRUE, n = nobs(fit), adj_r2 = summary(fit)$adj.r.squared)
  for (term in rownames(co)) {
    clean <- gsub("[^A-Za-z0-9_]+", "_", term)
    out[[paste0("ols_", clean, "_estimate")]] <- unname(co[term, "Estimate"])
    out[[paste0("ols_", clean, "_p")]] <- unname(co[term, "Pr(>|t|)"])
  }
  out
}

# ---- 2. Load S10 panel -------------------------------------------------------
if (!file.exists(in_panel_path)) {
  stop(
    "Missing S10 panel: ", in_panel_path, "\n",
    "Run codes/US_S10_source_of_truth_panel.R first.",
    call. = FALSE
  )
}

panel <- read.csv(in_panel_path, stringsAsFactors = FALSE)
require_cols(panel, c("year", "y_t", "k_t", "omega_t", "Y_real", "K_total_real"), "US S10 panel")
panel <- panel[order(panel$year), ]

# ---- 2b. Composition proxy contract -----------------------------------------
# The ME-NRC bridge is a Tier-B NFCorp-centered component proxy. It is not a
# direct nonfinancial-corporate-by-asset-type split.
s_proxy_source <- first_existing_name(panel, c("s_t_proxy", "s_ME_over_ME_NRC_gross_real"))
phi_proxy_source <- first_existing_name(panel, c("phi_t_proxy", "phi_ME_over_ME_NRC_real"))
s_proxy_cc_source <- first_existing_name(panel, c("s_t_proxy_cc", "s_ME_over_ME_NRC_gross_cc"))
phi_proxy_cc_source <- first_existing_name(panel, c("phi_t_proxy_cc", "phi_ME_over_ME_NRC_cc"))
pK_relative_source <- first_existing_name(panel, c("pK_relative_ME_NRC"))

if (!"s_t_proxy" %in% names(panel)) {
  panel$s_t_proxy <- if (!is.na(s_proxy_source)) panel[[s_proxy_source]] else NA_real_
}
if (!"phi_t_proxy" %in% names(panel)) {
  panel$phi_t_proxy <- if (!is.na(phi_proxy_source)) panel[[phi_proxy_source]] else NA_real_
}
if (!"s_t_proxy_cc" %in% names(panel)) {
  panel$s_t_proxy_cc <- if (!is.na(s_proxy_cc_source)) panel[[s_proxy_cc_source]] else NA_real_
}
if (!"phi_t_proxy_cc" %in% names(panel)) {
  panel$phi_t_proxy_cc <- if (!is.na(phi_proxy_cc_source)) panel[[phi_proxy_cc_source]] else NA_real_
}
if (!"pK_relative_ME_NRC" %in% names(panel)) {
  panel$pK_relative_ME_NRC <- if (!is.na(pK_relative_source)) panel[[pK_relative_source]] else NA_real_
}

panel$s_t_proxy <- suppressWarnings(as.numeric(panel$s_t_proxy))
panel$phi_t_proxy <- suppressWarnings(as.numeric(panel$phi_t_proxy))
panel$s_t_proxy_cc <- suppressWarnings(as.numeric(panel$s_t_proxy_cc))
panel$phi_t_proxy_cc <- suppressWarnings(as.numeric(panel$phi_t_proxy_cc))
panel$pK_relative_ME_NRC <- suppressWarnings(as.numeric(panel$pK_relative_ME_NRC))

if (!"s_ME_over_ME_NRC_gross_real" %in% names(panel)) {
  panel$s_ME_over_ME_NRC_gross_real <- panel$s_t_proxy
}
if (!"phi_ME_over_ME_NRC_real" %in% names(panel)) {
  panel$phi_ME_over_ME_NRC_real <- panel$phi_t_proxy
}
if (!"s_ME_over_ME_NRC_gross_cc" %in% names(panel)) {
  panel$s_ME_over_ME_NRC_gross_cc <- panel$s_t_proxy_cc
}
if (!"phi_ME_over_ME_NRC_cc" %in% names(panel)) {
  panel$phi_ME_over_ME_NRC_cc <- panel$phi_t_proxy_cc
}

composition_estimation_sample <- is.finite(panel$year) &
  is.finite(panel$y_t) &
  is.finite(panel$k_t) &
  is.finite(panel$omega_t)

composition_proxy_available <- sum(composition_estimation_sample) > 0L &&
  all(is.finite(panel$s_t_proxy[composition_estimation_sample])) &&
  all(is.finite(panel$phi_t_proxy[composition_estimation_sample]))

if (composition_proxy_available) {
  composition_status_value <- "proxy_available"
  composition_basis_value <- "ME_NRC_component_proxy"
  composition_tier_value <- "Tier B"
  direct_sector_asset_split_value <- FALSE
  sector_target_value <- "NFCorp"
} else {
  composition_status_value <- "unavailable"
  composition_basis_value <- NA_character_
  composition_tier_value <- NA_character_
  direct_sector_asset_split_value <- NA
  sector_target_value <- NA_character_
}

panel$composition_status <- composition_status_value
panel$composition_basis <- composition_basis_value
panel$composition_tier <- composition_tier_value
panel$direct_sector_asset_split <- direct_sector_asset_split_value
panel$sector_target <- sector_target_value

# ---- 3. Construct S20 variables --------------------------------------------
# Core old interaction retained as a diagnostic surface.
panel$omega_k_t <- panel$omega_t * panel$k_t
panel$omega_dev <- panel$omega_t - mean(panel$omega_t, na.rm = TRUE)
panel$omega_dev_k_t <- panel$omega_dev * panel$k_t

# Composition surfaces. For current US data this may remain missing; that is a
# legitimate S20 finding, not a script failure.
if (!"s_t" %in% names(panel)) panel$s_t <- NA_real_
if (!"phi_t" %in% names(panel)) panel$phi_t <- NA_real_

s_bar <- mean(panel$s_t, na.rm = TRUE)
if (!is.finite(s_bar)) s_bar <- NA_real_
panel$s_dev <- panel$s_t - s_bar
panel$s_dev_k_t <- panel$s_dev * panel$k_t
panel$omega_s_dev_k_t <- panel$omega_t * panel$s_dev_k_t

s_proxy_bar <- mean(panel$s_t_proxy, na.rm = TRUE)
if (!is.finite(s_proxy_bar)) s_proxy_bar <- NA_real_
panel$s_proxy_dev <- panel$s_t_proxy - s_proxy_bar
panel$s_proxy_dev_k_t <- panel$s_proxy_dev * panel$k_t
panel$omega_s_proxy_dev_k_t <- panel$omega_t * panel$s_proxy_dev_k_t

phi_proxy_bar <- mean(panel$phi_t_proxy, na.rm = TRUE)
if (!is.finite(phi_proxy_bar)) phi_proxy_bar <- NA_real_
panel$phi_proxy_dev <- panel$phi_t_proxy - phi_proxy_bar

# Mechanization/productivity diagnostic variables when ingredients exist.
if (!"K_machinery_real" %in% names(panel)) panel$K_machinery_real <- NA_real_
if (!"K_other_real" %in% names(panel)) panel$K_other_real <- NA_real_

panel$gY <- c(NA_real_, diff(panel$y_t))
panel$gK <- c(NA_real_, diff(panel$k_t))
panel$gK_machinery <- safe_diff_log(panel$K_machinery_real)

# If labor is later added to S10, q_t and a_t can become active here.
if (!"L" %in% names(panel)) panel$L <- NA_real_
panel$A_t <- ifelse(is.finite(panel$L) & panel$L > 0, panel$Y_real / panel$L, NA_real_)
panel$Q_t <- ifelse(is.finite(panel$L) & panel$L > 0, panel$K_total_real / panel$L, NA_real_)
panel$a_t <- safe_diff_log(panel$A_t)
panel$q_t <- safe_diff_log(panel$Q_t)

# Center benchmark dummies. These are admissibility labels, not automatic regimes.
panel$D_post1945 <- as.integer(panel$year >= 1945L)
panel$D_post1974 <- as.integer(panel$year >= 1974L)

# ---- 4. Candidate windows ----------------------------------------------------
windows <- data.frame(
  window_label = c(
    "Full_1929_2024",
    "PreFordist_core_1929_1944",
    "Fordist_core_1945_1973",
    "Pre1974_broad_1929_1973",
    "Bridge_1940_1978",
    "Post1974_tight_1974_1983",
    "Post1974_support_1974_1987",
    "Post1974_broad_1974_2024"
  ),
  start = c(1929L, 1929L, 1945L, 1929L, 1940L, 1974L, 1974L, 1974L),
  end   = c(2024L, 1944L, 1973L, 1973L, 1978L, 1983L, 1987L, 2024L),
  role = c(
    "full_reference",
    "predecessor",
    "benchmark",
    "support",
    "bridge",
    "support_short",
    "support",
    "post_reference"
  ),
  stringsAsFactors = FALSE
)

# Trim windows to available data span.
min_year <- min(panel$year, na.rm = TRUE)
max_year <- max(panel$year, na.rm = TRUE)
windows$available_start <- pmax(windows$start, min_year)
windows$available_end   <- pmin(windows$end, max_year)
windows$available <- windows$available_start <= windows$available_end

# ---- 5. Window-level admissibility scan -------------------------------------
scan_one_window <- function(w) {
  df <- panel[panel$year >= w$available_start & panel$year <= w$available_end, ]
  if (!isTRUE(w$available) || nrow(df) == 0L) {
    return(data.frame(
      window_label = w$window_label,
      window_role = w$role,
      start = w$start,
      end = w$end,
      available_start = w$available_start,
      available_end = w$available_end,
      available = FALSE,
      N = 0L,
      stringsAsFactors = FALSE
    ))
  }

  vif_unc <- safe_vif_pair(df$k_t, df$omega_k_t)
  vif_ctr <- safe_vif_pair(df$k_t, df$omega_dev_k_t)

  X_unc <- cbind(1, df$k_t, df$omega_k_t)
  X_ctr <- cbind(1, df$k_t, df$omega_dev_k_t)

  ols_unc <- ols_scan(df, y_t ~ k_t + omega_k_t)
  ols_ctr <- ols_scan(df, y_t ~ k_t + omega_dev_k_t)

  data.frame(
    window_label = w$window_label,
    window_role = w$role,
    start = w$start,
    end = w$end,
    available_start = w$available_start,
    available_end = w$available_end,
    available = TRUE,
    N = nrow(df),
    year_min = min(df$year),
    year_max = max(df$year),
    omega_min = min(df$omega_t, na.rm = TRUE),
    omega_mean = mean(df$omega_t, na.rm = TRUE),
    omega_max = max(df$omega_t, na.rm = TRUE),
    y_sd = sd(df$y_t, na.rm = TRUE),
    k_sd = sd(df$k_t, na.rm = TRUE),
    corr_k_omega_k = safe_cor(df$k_t, df$omega_k_t),
    corr_k_omega_dev_k = safe_cor(df$k_t, df$omega_dev_k_t),
    VIF_k_uncentered = unname(vif_unc["VIF_x1"]),
    VIF_interaction_uncentered = unname(vif_unc["VIF_x2"]),
    VIF_k_centered = unname(vif_ctr["VIF_x1"]),
    VIF_interaction_centered = unname(vif_ctr["VIF_x2"]),
    condition_number_uncentered = safe_condition_number(X_unc),
    condition_number_centered = safe_condition_number(X_ctr),
    s_available = any(is.finite(df$s_t)),
    phi_available = any(is.finite(df$phi_t)),
    s_t_proxy_available = any(is.finite(df$s_t_proxy)),
    phi_t_proxy_available = any(is.finite(df$phi_t_proxy)),
    s_t_proxy_min = safe_min(df$s_t_proxy),
    s_t_proxy_mean = safe_mean(df$s_t_proxy),
    s_t_proxy_max = safe_max(df$s_t_proxy),
    phi_t_proxy_min = safe_min(df$phi_t_proxy),
    phi_t_proxy_mean = safe_mean(df$phi_t_proxy),
    phi_t_proxy_max = safe_max(df$phi_t_proxy),
    composition_status = composition_status_value,
    composition_basis = composition_basis_value,
    composition_tier = composition_tier_value,
    direct_sector_asset_split = direct_sector_asset_split_value,
    sector_target = sector_target_value,
    q_available = any(is.finite(df$q_t)),
    a_available = any(is.finite(df$a_t)),
    ols_uncentered_ok = isTRUE(ols_unc$ok),
    ols_uncentered_adj_r2 = ifelse(isTRUE(ols_unc$ok), ols_unc$adj_r2, NA_real_),
    ols_uncentered_beta_k = ifelse(!is.null(ols_unc$ols_k_t_estimate), ols_unc$ols_k_t_estimate, NA_real_),
    ols_uncentered_beta_omega_k = ifelse(!is.null(ols_unc$ols_omega_k_t_estimate), ols_unc$ols_omega_k_t_estimate, NA_real_),
    ols_centered_ok = isTRUE(ols_ctr$ok),
    ols_centered_adj_r2 = ifelse(isTRUE(ols_ctr$ok), ols_ctr$adj_r2, NA_real_),
    ols_centered_beta_k = ifelse(!is.null(ols_ctr$ols_k_t_estimate), ols_ctr$ols_k_t_estimate, NA_real_),
    ols_centered_beta_omega_dev_k = ifelse(!is.null(ols_ctr$ols_omega_dev_k_t_estimate), ols_ctr$ols_omega_dev_k_t_estimate, NA_real_),
    stringsAsFactors = FALSE
  )
}

window_rows <- lapply(seq_len(nrow(windows)), function(i) scan_one_window(windows[i, ]))
window_summary <- do.call(rbind, window_rows)
rownames(window_summary) <- NULL

# ---- 6. Output data and logs -------------------------------------------------
admiss_panel_path <- file.path(out_data_dir, "us_s20_admissibility_panel.csv")
window_summary_path <- file.path(out_dir, "us_s20_window_admissibility_summary.csv")
window_register_path <- file.path(out_dir, "us_s20_candidate_window_register.csv")

write.csv(panel, admiss_panel_path, row.names = FALSE)
write.csv(window_summary, window_summary_path, row.names = FALSE)
write.csv(windows, window_register_path, row.names = FALSE)

# ---- 7. Markdown summary -----------------------------------------------------
direct_composition_msg <- if (any(is.finite(panel$s_t))) {
  "s_t is available as a direct composition variable."
} else {
  "s_t direct asset split is not available in the current US source panel."
}

direct_phi_msg <- if (any(is.finite(panel$phi_t))) {
  "phi_t is available as a direct investment-composition variable."
} else {
  "phi_t direct investment-composition split is not available in the current US source panel."
}

proxy_msg <- if (composition_proxy_available) {
  "The ME-NRC component proxy is present and non-missing for the S20 estimation sample."
} else {
  "The ME-NRC component proxy is unavailable or incomplete for the S20 estimation sample."
}

estimation_sample_years <- panel$year[composition_estimation_sample]
estimation_sample_span <- if (length(estimation_sample_years) > 0L) {
  paste0(min(estimation_sample_years), "-", max(estimation_sample_years))
} else {
  "none"
}

summary_md <- c(
  "# US S20 composition and stability admissibility summary",
  "",
  "## Status",
  "",
  "This file records the S20 admissibility layer for the US case.",
  "",
  "It does not perform final coefficient recovery and does not reconstruct productive capacity or utilization.",
  "",
  "## Data span",
  "",
  paste0("- First year: ", min(panel$year, na.rm = TRUE)),
  paste0("- Last year: ", max(panel$year, na.rm = TRUE)),
  paste0("- Observations: ", nrow(panel)),
  "",
  "## Composition availability",
  "",
  paste0("- composition_status = ", composition_status_value),
  paste0("- composition_basis = ", ifelse(is.na(composition_basis_value), "NA", composition_basis_value)),
  paste0("- composition_tier = ", ifelse(is.na(composition_tier_value), "NA", composition_tier_value)),
  paste0("- direct_sector_asset_split = ", ifelse(is.na(direct_sector_asset_split_value), "NA", direct_sector_asset_split_value)),
  paste0("- sector_target = ", ifelse(is.na(sector_target_value), "NA", sector_target_value)),
  paste0("- Estimation sample checked: ", estimation_sample_span, " (N = ", sum(composition_estimation_sample), ")"),
  paste0("- ", proxy_msg),
  paste0("- ", direct_composition_msg),
  paste0("- ", direct_phi_msg),
  "- Default proxy mappings: s_t_proxy = s_ME_over_ME_NRC_gross_real; phi_t_proxy = phi_ME_over_ME_NRC_real.",
  "- Diagnostic proxy mappings: s_t_proxy_cc = s_ME_over_ME_NRC_gross_cc; phi_t_proxy_cc = phi_ME_over_ME_NRC_cc; pK_relative_ME_NRC = pK_relative_ME_NRC.",
  "- Interpretation: Tier-B ME-NRC component proxy for the NFCorp-centered transformation relation; not a direct nonfinancial-corporate-by-asset-type split.",
  "",
  "## Candidate windows",
  "",
  paste0("- Window register: `", window_register_path, "`"),
  paste0("- Window summary: `", window_summary_path, "`"),
  "",
  "## Guardrail",
  "",
  "OLS scans in this script are diagnostic only. They do not replace FM-OLS, IM-OLS, or DOLS in S30/S90.",
  "",
  "DOLS-era windows are treated as candidate historical/admissibility windows, not as final regimes.",
  "",
  "S30 may proceed only after this S20 layer is reviewed."
)

summary_path <- file.path(out_dir, "US_S20_admissibility_summary.md")
writeLines(summary_md, summary_path)
writeLines(capture.output(sessionInfo()), file.path(out_log_dir, "sessionInfo_US_S20.txt"))

cat("US S20 admissibility panel written:\n")
cat("  ", admiss_panel_path, "\n", sep = "")
cat("Window summary written:\n")
cat("  ", window_summary_path, "\n", sep = "")
cat("Markdown summary written:\n")
cat("  ", summary_path, "\n", sep = "")
