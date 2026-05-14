###############################################################################
# US_S30_transformation_relation_fmols_imols_dols.R
# Chapter 2 - US transformation-relation estimator and stability grid
#
# Role in locked architecture:
#   S30 = coefficient recovery and parameter-stability discipline.
#
# Guardrails:
#   - Does not reconstruct Yp.
#   - Does not reconstruct mu.
#   - Does not derive capacity utilization.
#   - Does not run profitability analysis.
#   - Does not estimate threshold/FGLS.
#   - Does not run Gregory-Hansen, Bai-Perron, or Kejriwal-Perron.
###############################################################################

# ---- 0. Paths and settings ---------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")

in_panel_path <- file.path(REPO, "data/processed/US/us_s20_admissibility_panel.csv")
in_window_register_path <- file.path(
  REPO,
  "output/US/S20_composition_admissibility/us_s20_candidate_window_register.csv"
)

out_dir <- file.path(REPO, "output/US/S30_transformation_relation")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

grid_path <- file.path(out_dir, "us_s30_estimator_grid.csv")
stability_path <- file.path(out_dir, "us_s30_window_stability_summary.csv")
rolling_path <- file.path(out_dir, "us_s30_rolling_coefficients.csv")
report_path <- file.path(out_dir, "US_S30_transformation_relation_report.md")
spec_register_path <- file.path(out_dir, "us_s30_specification_register.csv")
window_register_used_path <- file.path(out_dir, "us_s30_candidate_window_register_used.csv")
manifest_path <- file.path(out_dir, "us_s30_run_manifest.csv")

CR_KERNEL <- "ba"
FM_BANDWIDTH <- "and"
IM_BANDWIDTH <- "and"
IM_SELECTOR <- 1L
DOLS_BANDWIDTH <- 3L
DOLS_P <- 2L
ROLLING_WINDOW_DEFAULT <- 30L
ROLLING_WINDOW_FALLBACK <- 25L

RUN_TIMESTAMP <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")

s30_warnings <- character(0)

add_warning <- function(msg) {
  s30_warnings <<- unique(c(s30_warnings, msg))
  warning(msg, call. = FALSE)
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

safe_numeric <- function(x) suppressWarnings(as.numeric(x))

safe_unique_value <- function(x, default = NA_character_) {
  if (is.null(x)) return(default)
  x_chr <- as.character(x)
  vals <- unique(x_chr[!is.na(x_chr) & nzchar(x_chr)])
  if (length(vals) == 0L) return(default)
  vals[1L]
}

safe_unique_logical <- function(x) {
  if (is.null(x)) return(NA)
  if (is.logical(x)) {
    vals <- unique(x[!is.na(x)])
    if (length(vals) == 0L) return(NA)
    return(vals[1L])
  }
  vals <- tolower(as.character(x[!is.na(x)]))
  vals <- vals[nzchar(vals)]
  if (length(vals) == 0L) return(NA)
  if (vals[1L] %in% c("true", "t", "1", "yes")) return(TRUE)
  if (vals[1L] %in% c("false", "f", "0", "no")) return(FALSE)
  NA
}

bool_to_text <- function(x) {
  if (length(x) == 0L || is.na(x)) return("NA")
  if (isTRUE(x)) "TRUE" else "FALSE"
}

collapse_or_na <- function(x) {
  x <- x[!is.na(x) & nzchar(as.character(x))]
  if (length(x) == 0L) return(NA_character_)
  paste(unique(x), collapse = "; ")
}

safe_min <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  min(x)
}

safe_max <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  max(x)
}

safe_mean <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  mean(x)
}

sign_clean <- function(x, tol = 1e-8) {
  if (!is.finite(x) || abs(x) <= tol) return(0L)
  if (x > 0) 1L else -1L
}

first_existing_col <- function(df, candidates) {
  hit <- intersect(candidates, names(df))
  if (length(hit) == 0L) return(NA_character_)
  hit[1L]
}

split_terms <- function(x) {
  if (is.na(x) || !nzchar(x)) return(character(0))
  strsplit(x, "\\|", fixed = FALSE)[[1L]]
}

sanitize_id <- function(x) {
  x <- tolower(gsub("[^A-Za-z0-9]+", "_", x))
  x <- gsub("^_+|_+$", "", x)
  if (!nzchar(x)) "unnamed_window" else x
}

md_table <- function(df, n = Inf) {
  if (is.null(df) || nrow(df) == 0L) return("_No rows._")
  df <- head(df, n)
  df[] <- lapply(df, function(x) {
    if (is.numeric(x)) {
      ifelse(is.na(x), "", formatC(x, digits = 4, format = "fg"))
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

condition_number_scaled <- function(X) {
  X <- as.matrix(X)
  ok <- apply(X, 1L, function(z) all(is.finite(z)))
  X <- X[ok, , drop = FALSE]
  if (nrow(X) <= ncol(X) || ncol(X) == 0L) return(NA_real_)
  Xs <- scale(X)
  Xs[, apply(Xs, 2L, function(z) all(!is.finite(z)))] <- 0
  Xs[!is.finite(Xs)] <- 0
  qr_rank <- qr(Xs)$rank
  if (qr_rank < ncol(Xs)) return(Inf)
  sv <- svd(Xs, nu = 0, nv = 0)$d
  min_sv <- min(sv)
  if (!is.finite(min_sv) || min_sv <= .Machine$double.eps) return(Inf)
  max(sv) / min_sv
}

max_abs_pairwise_cor <- function(X) {
  X <- as.matrix(X)
  ok <- apply(X, 1L, function(z) all(is.finite(z)))
  X <- X[ok, , drop = FALSE]
  if (ncol(X) < 2L || nrow(X) < 3L) return(NA_real_)
  keep <- apply(X, 2L, function(z) stats::sd(z) > 0)
  X <- X[, keep, drop = FALSE]
  if (ncol(X) < 2L) return(NA_real_)
  cc <- suppressWarnings(stats::cor(X))
  vals <- abs(cc[upper.tri(cc)])
  vals <- vals[is.finite(vals)]
  if (length(vals) == 0L) return(NA_real_)
  max(vals)
}

make_failure_rows <- function(run_id, window_row, estimator, spec_row,
                              coeff_names, n_raw, n_effective,
                              status, estimator_status, composition_meta,
                              notes) {
  data.frame(
    run_id = run_id,
    window_id = window_row$window_id,
    window_role = window_row$role,
    year_start = window_row$year_start,
    year_end = window_row$year_end,
    estimator = estimator,
    spec_id = spec_row$spec_id,
    coefficient = coeff_names,
    estimate = NA_real_,
    std_error = NA_real_,
    t_stat = NA_real_,
    p_value = NA_real_,
    n_raw = n_raw,
    n_effective = n_effective,
    regressor_count = length(split_terms(spec_row$regressors)),
    status = status,
    estimator_status = estimator_status,
    composition_status = composition_meta$status,
    composition_basis = composition_meta$basis,
    composition_tier = composition_meta$tier,
    direct_sector_asset_split = composition_meta$direct_split,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

extract_cointreg_rows <- function(fit, term_names, run_id, window_row, estimator,
                                  spec_row, n_raw, n_effective,
                                  composition_meta, notes) {
  theta <- as.numeric(fit$theta)
  se <- as.numeric(fit$sd.theta)
  tt <- as.numeric(fit$t.theta)
  pp <- as.numeric(fit$p.theta)

  if (length(theta) != length(term_names)) {
    stop(
      "cointReg coefficient length mismatch: expected ",
      length(term_names), " terms but got ", length(theta), "."
    )
  }
  if (length(se) != length(term_names)) se <- rep(NA_real_, length(term_names))
  if (length(tt) != length(term_names)) tt <- rep(NA_real_, length(term_names))
  if (length(pp) != length(term_names)) pp <- rep(NA_real_, length(term_names))

  data.frame(
    run_id = run_id,
    window_id = window_row$window_id,
    window_role = window_row$role,
    year_start = window_row$year_start,
    year_end = window_row$year_end,
    estimator = estimator,
    spec_id = spec_row$spec_id,
    coefficient = term_names,
    estimate = theta,
    std_error = se,
    t_stat = tt,
    p_value = pp,
    n_raw = n_raw,
    n_effective = n_effective,
    regressor_count = length(split_terms(spec_row$regressors)),
    status = "estimated",
    estimator_status = "ok",
    composition_status = composition_meta$status,
    composition_basis = composition_meta$basis,
    composition_tier = composition_meta$tier,
    direct_sector_asset_split = composition_meta$direct_split,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

# ---- 2. Load inputs ----------------------------------------------------------
if (!file.exists(in_panel_path)) {
  stop(
    "Missing S20 admissibility panel: ", in_panel_path, "\n",
    "Run codes/US_S20_composition_stability_admissibility.R first.",
    call. = FALSE
  )
}

panel <- read.csv(in_panel_path, stringsAsFactors = FALSE)
require_cols(panel, c("year", "y_t", "k_t", "omega_t"), "US S20 panel")
panel <- panel[order(panel$year), ]

numeric_cols <- intersect(
  c(
    "year", "y_t", "k_t", "omega_t", "omega_k_t",
    "s_t_proxy", "phi_t_proxy", "s_t_proxy_cc", "phi_t_proxy_cc",
    "pK_relative_ME_NRC"
  ),
  names(panel)
)
for (nm in numeric_cols) panel[[nm]] <- safe_numeric(panel[[nm]])
panel$year <- as.integer(panel$year)

optional_composition_cols <- c(
  "s_t_proxy", "phi_t_proxy", "s_t_proxy_cc", "phi_t_proxy_cc",
  "pK_relative_ME_NRC", "composition_status", "composition_basis",
  "composition_tier", "direct_sector_asset_split"
)

for (nm in setdiff(optional_composition_cols, names(panel))) {
  add_warning(paste0("Optional S30 composition column missing from S20 panel: ", nm))
  if (nm %in% c("composition_status", "composition_basis", "composition_tier")) {
    panel[[nm]] <- NA_character_
  } else if (nm == "direct_sector_asset_split") {
    panel[[nm]] <- NA
  } else {
    panel[[nm]] <- NA_real_
  }
}

composition_status_panel <- safe_unique_value(panel$composition_status, "unavailable")
composition_basis_panel <- safe_unique_value(panel$composition_basis, NA_character_)
composition_tier_panel <- safe_unique_value(panel$composition_tier, NA_character_)
direct_sector_asset_split_panel <- safe_unique_logical(panel$direct_sector_asset_split)

if (!"omega_k_t" %in% names(panel) || all(!is.finite(panel$omega_k_t))) {
  panel$omega_k_t <- panel$omega_t * panel$k_t
} else {
  idx <- !is.finite(panel$omega_k_t) & is.finite(panel$omega_t) & is.finite(panel$k_t)
  panel$omega_k_t[idx] <- panel$omega_t[idx] * panel$k_t[idx]
}

default_proxy_cols <- c("s_t_proxy", "phi_t_proxy")
default_proxy_present <- all(default_proxy_cols %in% names(panel))
default_proxy_finite <- default_proxy_present &&
  all(is.finite(panel$s_t_proxy[is.finite(panel$year) & is.finite(panel$y_t) &
                                  is.finite(panel$k_t) & is.finite(panel$omega_t)])) &&
  all(is.finite(panel$phi_t_proxy[is.finite(panel$year) & is.finite(panel$y_t) &
                                    is.finite(panel$k_t) & is.finite(panel$omega_t)]))

composition_proxy_available_global <- identical(composition_status_panel, "proxy_available") &&
  default_proxy_present && default_proxy_finite

if (!composition_proxy_available_global) {
  add_warning(
    "Composition proxy is unavailable or incomplete for S30; composition specifications will be skipped."
  )
}

# ---- 3. Package availability -------------------------------------------------
cointreg_available <- requireNamespace("cointReg", quietly = TRUE)

estimator_availability <- data.frame(
  estimator = c("FM_OLS", "IM_OLS", "DOLS"),
  role = c("main_estimator", "robustness_estimator", "fragility_stress_diagnostic"),
  package = "cointReg",
  function_name = c("cointRegFM", "cointRegIM", "cointRegD"),
  available = c(cointreg_available, cointreg_available, cointreg_available),
  stringsAsFactors = FALSE
)

if (cointreg_available) {
  suppressPackageStartupMessages(library(cointReg))
} else {
  add_warning("Package cointReg is unavailable; FM-OLS, IM-OLS, and DOLS grid cells will be marked not_available.")
}

# ---- 4. Window register ------------------------------------------------------
mandatory_windows <- data.frame(
  window_id = c(
    "full_long_sample",
    "pre_1974",
    "post_1973",
    "fordist_core",
    "bridge_1940_1978",
    "pre_1974_alt_1940_1973",
    "pre_1974_alt_1947_1974",
    "post_1974_tight",
    "post_1974_support"
  ),
  year_start = c(1929L, 1929L, 1974L, 1945L, 1940L, 1940L, 1947L, 1974L, 1974L),
  year_end = c(2024L, 1973L, 2024L, 1973L, 1978L, 1973L, 1974L, 1983L, 1987L),
  role = c(
    "full_reference", "pre_reference", "post_reference", "benchmark",
    "bridge", "support", "support", "support_short", "support"
  ),
  source = "S30_mandatory",
  stringsAsFactors = FALSE
)

map_s20_window_id <- function(label, start, end) {
  if (start == 1929L && end == 2024L) return("full_long_sample")
  if (start == 1929L && end == 1973L) return("pre_1974")
  if (start == 1974L && end == 2024L) return("post_1973")
  if (start == 1945L && end == 1973L) return("fordist_core")
  if (start == 1940L && end == 1978L) return("bridge_1940_1978")
  if (start == 1974L && end == 1983L) return("post_1974_tight")
  if (start == 1974L && end == 1987L) return("post_1974_support")
  sanitize_id(label)
}

s20_windows <- data.frame(
  window_id = character(0),
  year_start = integer(0),
  year_end = integer(0),
  role = character(0),
  source = character(0),
  stringsAsFactors = FALSE
)

if (file.exists(in_window_register_path)) {
  wr <- read.csv(in_window_register_path, stringsAsFactors = FALSE)
  start_col <- first_existing_col(wr, c("start", "year_start", "available_start"))
  end_col <- first_existing_col(wr, c("end", "year_end", "available_end"))
  label_col <- first_existing_col(wr, c("window_label", "window_id", "label"))
  role_col <- first_existing_col(wr, c("role", "window_role"))

  if (!is.na(start_col) && !is.na(end_col) && !is.na(label_col)) {
    for (i in seq_len(nrow(wr))) {
      ys <- as.integer(wr[[start_col]][i])
      ye <- as.integer(wr[[end_col]][i])
      label <- as.character(wr[[label_col]][i])
      role <- if (!is.na(role_col)) as.character(wr[[role_col]][i]) else "S20_registered"
      s20_windows <- rbind(
        s20_windows,
        data.frame(
          window_id = map_s20_window_id(label, ys, ye),
          year_start = ys,
          year_end = ye,
          role = role,
          source = "S20_register",
          stringsAsFactors = FALSE
        )
      )
    }
  } else {
    add_warning("S20 window register exists but lacks usable start/end/label columns; using S30 mandatory windows.")
  }
} else {
  add_warning("S20 candidate window register not found; using S30 mandatory windows.")
}

windows <- mandatory_windows
if (nrow(s20_windows) > 0L) {
  for (i in seq_len(nrow(s20_windows))) {
    hit <- which(windows$window_id == s20_windows$window_id[i])
    if (length(hit) == 0L) {
      windows <- rbind(windows, s20_windows[i, ])
    } else {
      windows$source[hit[1L]] <- paste(unique(c(windows$source[hit[1L]], s20_windows$source[i])), collapse = "+")
      if (windows$role[hit[1L]] %in% c("", NA)) windows$role[hit[1L]] <- s20_windows$role[i]
    }
  }
}

panel_min_year <- min(panel$year, na.rm = TRUE)
panel_max_year <- max(panel$year, na.rm = TRUE)
windows$available_start <- pmax(windows$year_start, panel_min_year)
windows$available_end <- pmin(windows$year_end, panel_max_year)
windows$available <- windows$available_start <= windows$available_end
windows <- windows[order(windows$year_start, windows$year_end, windows$window_id), ]
rownames(windows) <- NULL

write.csv(windows, window_register_used_path, row.names = FALSE)

# ---- 5. Specification register ---------------------------------------------
spec_register <- data.frame(
  spec_id = c(
    "SPEC_B0_CAPITAL_ONLY",
    "SPEC_B1_WAGE_BASELINE",
    "SPEC_C1_COMPOSITION_STOCK",
    "SPEC_C2_FULL_COMPOSITION",
    "SPEC_D1_CURRENT_COST_DIAGNOSTIC",
    "SPEC_D2_PRICE_WEDGE_DIAGNOSTIC"
  ),
  formula_label = c(
    "y_t ~ k_t",
    "y_t ~ k_t + omega_k_t",
    "y_t ~ k_t + omega_k_t + s_proxy_k_t",
    "y_t ~ k_t + omega_k_t + s_proxy_k_t + omega_s_proxy_k_t",
    "y_t ~ k_t + omega_k_t + s_proxy_cc_k_t",
    "y_t ~ k_t + omega_k_t + s_proxy_k_t + pKrel_k_t"
  ),
  regressors = c(
    "k_t",
    "k_t|omega_k_t",
    "k_t|omega_k_t|s_proxy_k_t",
    "k_t|omega_k_t|s_proxy_k_t|omega_s_proxy_k_t",
    "k_t|omega_k_t|s_proxy_cc_k_t",
    "k_t|omega_k_t|s_proxy_k_t|pKrel_k_t"
  ),
  composition_required = c(FALSE, FALSE, TRUE, TRUE, TRUE, TRUE),
  proxy_type_required = c("none", "none", "default_real", "default_real", "current_cost", "price_wedge"),
  promotion_eligible = c(FALSE, TRUE, TRUE, TRUE, FALSE, FALSE),
  diagnostic_only = c(FALSE, FALSE, FALSE, FALSE, TRUE, TRUE),
  role = c(
    "baseline_reference",
    "core_candidate",
    "core_candidate",
    "core_candidate",
    "diagnostic_only",
    "diagnostic_only"
  ),
  notes = c(
    "Baseline reference only.",
    "Core wage-share interaction baseline.",
    "Core Tier-B stock-composition proxy specification.",
    "Core Tier-B stock-composition proxy with wage-composition interaction.",
    "Current-cost diagnostic only.",
    "Relative-price wedge diagnostic only."
  ),
  stringsAsFactors = FALSE
)

write.csv(spec_register, spec_register_path, row.names = FALSE)

# ---- 6. Window data construction -------------------------------------------
center_window_var <- function(x) {
  m <- safe_mean(x)
  if (!is.finite(m)) return(rep(NA_real_, length(x)))
  x - m
}

prepare_window_data <- function(df) {
  d <- df
  if (!"omega_k_t" %in% names(d)) d$omega_k_t <- NA_real_
  idx <- !is.finite(d$omega_k_t) & is.finite(d$omega_t) & is.finite(d$k_t)
  d$omega_k_t[idx] <- d$omega_t[idx] * d$k_t[idx]

  for (nm in c("s_t_proxy", "phi_t_proxy", "s_t_proxy_cc", "phi_t_proxy_cc", "pK_relative_ME_NRC")) {
    if (!nm %in% names(d)) d[[nm]] <- NA_real_
    d[[nm]] <- safe_numeric(d[[nm]])
  }

  d$s_t_proxy_c <- center_window_var(d$s_t_proxy)
  d$s_t_proxy_cc_c <- center_window_var(d$s_t_proxy_cc)
  d$pK_relative_ME_NRC_c <- center_window_var(d$pK_relative_ME_NRC)

  d$s_proxy_k_t <- d$s_t_proxy_c * d$k_t
  d$omega_s_proxy_k_t <- d$omega_t * d$s_t_proxy_c * d$k_t
  d$s_proxy_cc_k_t <- d$s_t_proxy_cc_c * d$k_t
  d$omega_s_proxy_cc_k_t <- d$omega_t * d$s_t_proxy_cc_c * d$k_t
  d$pKrel_k_t <- d$pK_relative_ME_NRC_c * d$k_t
  d
}

complete_estimation_data <- function(df, regressors) {
  vars <- c("y_t", regressors)
  ok <- stats::complete.cases(df[, vars, drop = FALSE])
  df[ok, , drop = FALSE]
}

complete_dols_data <- function(df, regressors, p = DOLS_P) {
  vars <- c("y_t", regressors)
  base_ok <- stats::complete.cases(df[, vars, drop = FALSE])
  d <- df
  n <- nrow(d)
  if (n == 0L || !any(base_ok)) return(d[FALSE, , drop = FALSE])

  dyn <- data.frame(base_ok = base_ok)
  for (reg in regressors) {
    dx <- c(NA_real_, diff(d[[reg]]))
    for (h in (-p):p) {
      suffix <- if (h < 0) paste0("lead", abs(h)) else if (h > 0) paste0("lag", h) else "cur"
      if (h <= 0L) {
        dyn[[paste0("d_", reg, "_", suffix)]] <- c(rep(NA_real_, abs(h)), dx[seq_len(n - abs(h))])
      } else {
        dyn[[paste0("d_", reg, "_", suffix)]] <- c(dx[(h + 1L):n], rep(NA_real_, h))
      }
    }
  }
  ok <- stats::complete.cases(dyn)
  d[ok, , drop = FALSE]
}

min_required_n <- function(estimator, regressor_count) {
  if (estimator == "DOLS") {
    return(max(12L, 1L + regressor_count + (2L * DOLS_P + 1L) * regressor_count + 3L))
  }
  max(10L, regressor_count + 5L)
}

window_composition_meta <- function(df) {
  sample_ok <- is.finite(df$year) & is.finite(df$y_t) & is.finite(df$k_t) & is.finite(df$omega_t)
  proxy_ok <- composition_proxy_available_global &&
    any(sample_ok) &&
    all(is.finite(df$s_t_proxy[sample_ok])) &&
    all(is.finite(df$phi_t_proxy[sample_ok]))

  if (proxy_ok) {
    list(
      status = "proxy_available",
      basis = "ME_NRC_component_proxy",
      tier = "Tier B",
      direct_split = FALSE
    )
  } else {
    list(
      status = "unavailable",
      basis = NA_character_,
      tier = NA_character_,
      direct_split = NA
    )
  }
}

spec_has_required_proxy <- function(df, spec_row, composition_meta) {
  if (!isTRUE(spec_row$composition_required)) {
    return(list(ok = TRUE, status = "ok", notes = "No composition proxy required."))
  }

  if (!identical(composition_meta$status, "proxy_available")) {
    return(list(
      ok = FALSE,
      status = "skipped_no_composition_proxy",
      notes = "Skipped because composition_status is not proxy_available for this window."
    ))
  }

  if (spec_row$proxy_type_required %in% c("default_real", "price_wedge")) {
    if (!all(is.finite(df$s_t_proxy)) || !all(is.finite(df$phi_t_proxy))) {
      return(list(
        ok = FALSE,
        status = "skipped_no_composition_proxy",
        notes = "Skipped because default real composition proxy variables are incomplete."
      ))
    }
  }

  if (identical(spec_row$proxy_type_required, "current_cost") && !all(is.finite(df$s_t_proxy_cc))) {
    return(list(
      ok = FALSE,
      status = "skipped_missing_optional_variable",
      notes = "Skipped because current-cost composition proxy is incomplete."
    ))
  }

  if (identical(spec_row$proxy_type_required, "price_wedge") && !all(is.finite(df$pK_relative_ME_NRC))) {
    return(list(
      ok = FALSE,
      status = "skipped_missing_optional_variable",
      notes = "Skipped because pK_relative_ME_NRC is incomplete."
    ))
  }

  list(ok = TRUE, status = "ok", notes = "Composition proxy requirements satisfied.")
}

# ---- 7. Estimation wrappers --------------------------------------------------
estimate_grid_cell <- function(df_window, window_row, spec_row, estimator) {
  regressors <- split_terms(spec_row$regressors)
  coeff_names <- c("const", regressors)
  n_raw <- nrow(df_window)
  run_id <- paste(window_row$window_id, spec_row$spec_id, estimator, sep = "__")
  composition_meta <- window_composition_meta(df_window)

  if (!isTRUE(window_row$available) || n_raw == 0L) {
    return(make_failure_rows(
      run_id, window_row, estimator, spec_row, coeff_names, n_raw, 0L,
      "rejected_sample_size", "rejected_sample_size", composition_meta,
      "Window unavailable after clipping to panel span."
    ))
  }

  missing_regressors <- setdiff(regressors, names(df_window))
  if (length(missing_regressors) > 0L) {
    return(make_failure_rows(
      run_id, window_row, estimator, spec_row, coeff_names, n_raw, 0L,
      "skipped_missing_optional_variable", "skipped", composition_meta,
      paste("Missing regressors:", paste(missing_regressors, collapse = ", "))
    ))
  }

  if (!isTRUE(estimator_availability$available[estimator_availability$estimator == estimator][1L])) {
    return(make_failure_rows(
      run_id, window_row, estimator, spec_row, coeff_names, n_raw, n_raw,
      "not_available", "not_available", composition_meta,
      paste0(estimator, " unavailable because cointReg is not installed.")
    ))
  }

  proxy_check <- spec_has_required_proxy(df_window, spec_row, composition_meta)
  if (!isTRUE(proxy_check$ok)) {
    return(make_failure_rows(
      run_id, window_row, estimator, spec_row, coeff_names, n_raw, 0L,
      proxy_check$status, "skipped", composition_meta, proxy_check$notes
    ))
  }

  df_est <- if (estimator == "DOLS") {
    complete_dols_data(df_window, regressors, p = DOLS_P)
  } else {
    complete_estimation_data(df_window, regressors)
  }
  n_effective <- nrow(df_est)
  min_n <- min_required_n(estimator, length(regressors))

  if (n_effective < min_n) {
    return(make_failure_rows(
      run_id, window_row, estimator, spec_row, coeff_names, n_raw, n_effective,
      "rejected_sample_size", "rejected_sample_size", composition_meta,
      paste0(
        "Effective sample size ", n_effective,
        " is below the S30 minimum ", min_n,
        ifelse(estimator == "DOLS", " after DOLS lead/lag construction.", ".")
      )
    ))
  }

  x_mat <- as.matrix(df_est[, regressors, drop = FALSE])
  y_vec <- df_est$y_t
  deter_mat <- matrix(1, nrow = length(y_vec), ncol = 1, dimnames = list(NULL, "const"))
  term_names <- c(colnames(deter_mat), colnames(x_mat))

  fit <- tryCatch(
    {
      if (estimator == "FM_OLS") {
        cointReg::cointRegFM(
          x = x_mat, y = y_vec, deter = deter_mat,
          kernel = CR_KERNEL, bandwidth = FM_BANDWIDTH, check = TRUE
        )
      } else if (estimator == "IM_OLS") {
        cointReg::cointRegIM(
          x = x_mat, y = y_vec, deter = deter_mat,
          selector = IM_SELECTOR, t.test = TRUE,
          kernel = CR_KERNEL, bandwidth = IM_BANDWIDTH, check = TRUE
        )
      } else if (estimator == "DOLS") {
        cointReg::cointRegD(
          x = x_mat, y = y_vec, deter = deter_mat,
          kernel = CR_KERNEL, bandwidth = DOLS_BANDWIDTH,
          n.lead = DOLS_P, n.lag = DOLS_P, check = TRUE
        )
      } else {
        stop("Unknown estimator: ", estimator)
      }
    },
    error = function(e) e
  )

  if (inherits(fit, "error")) {
    return(make_failure_rows(
      run_id, window_row, estimator, spec_row, coeff_names, n_raw, n_effective,
      "failed", "failed", composition_meta,
      paste("Estimator failed:", conditionMessage(fit))
    ))
  }

  notes <- switch(
    estimator,
    FM_OLS = paste0("cointReg::cointRegFM; kernel=", CR_KERNEL, "; bandwidth=", FM_BANDWIDTH, "; constant in deter."),
    IM_OLS = paste0("cointReg::cointRegIM; selector=", IM_SELECTOR, "; kernel=", CR_KERNEL, "; bandwidth=", IM_BANDWIDTH, "; constant in deter."),
    DOLS = paste0("cointReg::cointRegD; n.lead=", DOLS_P, "; n.lag=", DOLS_P, "; kernel=", CR_KERNEL, "; bandwidth=", DOLS_BANDWIDTH, "; n_effective after DOLS lead/lag construction."),
    "Estimator settings unavailable."
  )

  extract_cointreg_rows(
    fit = fit,
    term_names = term_names,
    run_id = run_id,
    window_row = window_row,
    estimator = estimator,
    spec_row = spec_row,
    n_raw = n_raw,
    n_effective = n_effective,
    composition_meta = composition_meta,
    notes = notes
  )
}

# ---- 8. Run estimator grid ---------------------------------------------------
estimators <- c("FM_OLS", "IM_OLS", "DOLS")
grid_parts <- list()
part_i <- 0L

for (wi in seq_len(nrow(windows))) {
  w <- windows[wi, ]
  df_w <- panel[panel$year >= w$available_start & panel$year <= w$available_end, , drop = FALSE]
  df_w <- prepare_window_data(df_w)

  for (si in seq_len(nrow(spec_register))) {
    sp <- spec_register[si, ]
    for (est in estimators) {
      part_i <- part_i + 1L
      grid_parts[[part_i]] <- estimate_grid_cell(df_w, w, sp, est)
    }
  }
}

estimator_grid <- do.call(rbind, grid_parts)
rownames(estimator_grid) <- NULL
write.csv(estimator_grid, grid_path, row.names = FALSE)

# ---- 9. Rolling diagnostics --------------------------------------------------
rolling_estimator_label <- if (cointreg_available) "FM_OLS" else "OLS_proxy_diagnostic"
rolling_source_label <- if (cointreg_available) "FM_OLS_cointegrating_diagnostic" else "OLS_proxy_diagnostic"

valid_panel_rows <- stats::complete.cases(panel[, c("year", "y_t", "k_t", "omega_t"), drop = FALSE])
rolling_window_length <- if (sum(valid_panel_rows) >= ROLLING_WINDOW_DEFAULT) {
  ROLLING_WINDOW_DEFAULT
} else if (sum(valid_panel_rows) >= ROLLING_WINDOW_FALLBACK) {
  ROLLING_WINDOW_FALLBACK
} else {
  NA_integer_
}

estimate_rolling_cell <- function(df_roll, spec_row, roll_start, roll_end) {
  regressors <- split_terms(spec_row$regressors)
  coeff_names <- c("const", regressors)
  composition_meta <- window_composition_meta(df_roll)

  if (is.na(rolling_window_length)) {
    return(data.frame(
      rolling_window_start = roll_start,
      rolling_window_end = roll_end,
      estimator = rolling_estimator_label,
      diagnostic_type = rolling_source_label,
      spec_id = spec_row$spec_id,
      coefficient = coeff_names,
      estimate = NA_real_,
      n_effective = 0L,
      status = "rejected_sample_size",
      notes = "No feasible rolling window length.",
      stringsAsFactors = FALSE
    ))
  }

  proxy_check <- spec_has_required_proxy(df_roll, spec_row, composition_meta)
  if (!isTRUE(proxy_check$ok)) {
    return(data.frame(
      rolling_window_start = roll_start,
      rolling_window_end = roll_end,
      estimator = rolling_estimator_label,
      diagnostic_type = rolling_source_label,
      spec_id = spec_row$spec_id,
      coefficient = coeff_names,
      estimate = NA_real_,
      n_effective = 0L,
      status = proxy_check$status,
      notes = proxy_check$notes,
      stringsAsFactors = FALSE
    ))
  }

  df_est <- complete_estimation_data(df_roll, regressors)
  n_eff <- nrow(df_est)
  if (n_eff < min_required_n("FM_OLS", length(regressors))) {
    return(data.frame(
      rolling_window_start = roll_start,
      rolling_window_end = roll_end,
      estimator = rolling_estimator_label,
      diagnostic_type = rolling_source_label,
      spec_id = spec_row$spec_id,
      coefficient = coeff_names,
      estimate = NA_real_,
      n_effective = n_eff,
      status = "rejected_sample_size",
      notes = "Rolling window has too few complete observations.",
      stringsAsFactors = FALSE
    ))
  }

  x_mat <- as.matrix(df_est[, regressors, drop = FALSE])
  y_vec <- df_est$y_t
  deter_mat <- matrix(1, nrow = length(y_vec), ncol = 1, dimnames = list(NULL, "const"))
  term_names <- c("const", regressors)

  if (cointreg_available) {
    fit <- tryCatch(
      cointReg::cointRegFM(
        x = x_mat, y = y_vec, deter = deter_mat,
        kernel = CR_KERNEL, bandwidth = FM_BANDWIDTH, check = TRUE
      ),
      error = function(e) e
    )
    if (inherits(fit, "error")) {
      return(data.frame(
        rolling_window_start = roll_start,
        rolling_window_end = roll_end,
        estimator = rolling_estimator_label,
        diagnostic_type = rolling_source_label,
        spec_id = spec_row$spec_id,
        coefficient = coeff_names,
        estimate = NA_real_,
        n_effective = n_eff,
        status = "failed",
        notes = paste("Rolling FM-OLS failed:", conditionMessage(fit)),
        stringsAsFactors = FALSE
      ))
    }
    est <- as.numeric(fit$theta)
  } else {
    d_lm <- data.frame(y_t = y_vec, x_mat, check.names = FALSE)
    form <- stats::as.formula(paste("y_t ~", paste(regressors, collapse = " + ")))
    fit <- tryCatch(stats::lm(form, data = d_lm), error = function(e) e)
    if (inherits(fit, "error")) {
      return(data.frame(
        rolling_window_start = roll_start,
        rolling_window_end = roll_end,
        estimator = rolling_estimator_label,
        diagnostic_type = rolling_source_label,
        spec_id = spec_row$spec_id,
        coefficient = coeff_names,
        estimate = NA_real_,
        n_effective = n_eff,
        status = "failed",
        notes = paste("Rolling OLS proxy failed:", conditionMessage(fit)),
        stringsAsFactors = FALSE
      ))
    }
    est <- as.numeric(stats::coef(fit))
  }

  if (length(est) != length(term_names)) est <- rep(NA_real_, length(term_names))

  data.frame(
    rolling_window_start = roll_start,
    rolling_window_end = roll_end,
    estimator = rolling_estimator_label,
    diagnostic_type = rolling_source_label,
    spec_id = spec_row$spec_id,
    coefficient = term_names,
    estimate = est,
    n_effective = n_eff,
    status = "estimated",
    notes = if (cointreg_available) {
      "Rolling FM-OLS diagnostic; not a formal regime identifier."
    } else {
      "Rolling OLS proxy diagnostic; not a formal cointegrating estimate and not a regime identifier."
    },
    stringsAsFactors = FALSE
  )
}

rolling_parts <- list()
roll_i <- 0L
core_spec_ids <- c("SPEC_B1_WAGE_BASELINE", "SPEC_C1_COMPOSITION_STOCK", "SPEC_C2_FULL_COMPOSITION")
core_specs <- spec_register[spec_register$spec_id %in% core_spec_ids, , drop = FALSE]

if (!is.na(rolling_window_length)) {
  years <- sort(unique(panel$year[valid_panel_rows]))
  roll_starts <- seq(min(years), max(years) - rolling_window_length + 1L)
  for (rs in roll_starts) {
    re <- rs + rolling_window_length - 1L
    df_roll <- panel[panel$year >= rs & panel$year <= re, , drop = FALSE]
    if (nrow(df_roll) != rolling_window_length) next
    df_roll <- prepare_window_data(df_roll)
    for (si in seq_len(nrow(core_specs))) {
      roll_i <- roll_i + 1L
      rolling_parts[[roll_i]] <- estimate_rolling_cell(df_roll, core_specs[si, ], rs, re)
    }
  }
}

if (length(rolling_parts) == 0L) {
  rolling_coefficients <- data.frame(
    rolling_window_start = integer(0),
    rolling_window_end = integer(0),
    estimator = character(0),
    diagnostic_type = character(0),
    spec_id = character(0),
    coefficient = character(0),
    estimate = numeric(0),
    n_effective = integer(0),
    status = character(0),
    notes = character(0),
    stringsAsFactors = FALSE
  )
} else {
  rolling_coefficients <- do.call(rbind, rolling_parts)
  rownames(rolling_coefficients) <- NULL
}

write.csv(rolling_coefficients, rolling_path, row.names = FALSE)

# ---- 10. Stability and promotion classification -----------------------------
get_estimate <- function(grid, window_id, spec_id, estimator, coefficient) {
  hit <- grid[
    grid$window_id == window_id &
      grid$spec_id == spec_id &
      grid$estimator == estimator &
      grid$coefficient == coefficient &
      grid$status == "estimated" &
      grid$estimator_status == "ok",
    ,
    drop = FALSE
  ]
  if (nrow(hit) == 0L) return(NA_real_)
  hit$estimate[1L]
}

key_coefficients <- function(spec_id) {
  switch(
    spec_id,
    SPEC_B0_CAPITAL_ONLY = "k_t",
    SPEC_B1_WAGE_BASELINE = "omega_k_t",
    SPEC_C1_COMPOSITION_STOCK = c("omega_k_t", "s_proxy_k_t"),
    SPEC_C2_FULL_COMPOSITION = c("omega_k_t", "s_proxy_k_t", "omega_s_proxy_k_t"),
    SPEC_D1_CURRENT_COST_DIAGNOSTIC = "s_proxy_cc_k_t",
    SPEC_D2_PRICE_WEDGE_DIAGNOSTIC = c("s_proxy_k_t", "pKrel_k_t"),
    character(0)
  )
}

estimator_ok <- function(grid, window_id, spec_id, estimator) {
  any(
    grid$window_id == window_id &
      grid$spec_id == spec_id &
      grid$estimator == estimator &
      grid$status == "estimated" &
      grid$estimator_status == "ok"
  )
}

sign_reversal_between <- function(grid, window_id, spec_id, est_a, est_b, coeffs) {
  if (length(coeffs) == 0L) return(FALSE)
  reversals <- vapply(coeffs, function(cf) {
    a <- get_estimate(grid, window_id, spec_id, est_a, cf)
    b <- get_estimate(grid, window_id, spec_id, est_b, cf)
    sa <- sign_clean(a)
    sb <- sign_clean(b)
    sa != 0L && sb != 0L && sa != sb
  }, logical(1))
  any(reversals)
}

overlap_or_adjacent <- function(a_start, a_end, b_start, b_end) {
  overlaps <- a_start <= b_end && b_start <= a_end
  adjacent <- abs(a_start - b_end) <= 1L || abs(b_start - a_end) <= 1L
  overlaps || adjacent
}

neighborhood_reversal_count <- function(grid, window_row, spec_id, coeffs) {
  if (length(coeffs) == 0L) return(0L)
  own <- vapply(coeffs, function(cf) sign_clean(get_estimate(grid, window_row$window_id, spec_id, "FM_OLS", cf)), integer(1))
  if (all(own == 0L)) return(0L)

  neighbors <- windows[
    windows$window_id != window_row$window_id &
      mapply(
        overlap_or_adjacent,
        window_row$year_start, window_row$year_end,
        windows$year_start, windows$year_end
      ),
    ,
    drop = FALSE
  ]

  count <- 0L
  if (nrow(neighbors) == 0L) return(count)
  for (i in seq_len(nrow(neighbors))) {
    for (cf in coeffs) {
      s0 <- sign_clean(get_estimate(grid, window_row$window_id, spec_id, "FM_OLS", cf))
      s1 <- sign_clean(get_estimate(grid, neighbors$window_id[i], spec_id, "FM_OLS", cf))
      if (s0 != 0L && s1 != 0L && s0 != s1) count <- count + 1L
    }
  }
  count
}

rolling_proxy_reversal_count <- function(spec_id, coeffs) {
  if (nrow(rolling_coefficients) == 0L || length(coeffs) == 0L) return(NA_integer_)
  sub <- rolling_coefficients[
    rolling_coefficients$spec_id == spec_id &
      rolling_coefficients$status == "estimated" &
      rolling_coefficients$coefficient %in% coeffs,
    ,
    drop = FALSE
  ]
  if (nrow(sub) == 0L) return(NA_integer_)
  count <- 0L
  for (cf in coeffs) {
    s <- vapply(sub$estimate[sub$coefficient == cf], sign_clean, integer(1))
    s <- unique(s[s != 0L])
    if (length(s) > 1L) count <- count + 1L
  }
  count
}

stability_rows <- list()
stab_i <- 0L

for (wi in seq_len(nrow(windows))) {
  w <- windows[wi, ]
  df_w <- panel[panel$year >= w$available_start & panel$year <= w$available_end, , drop = FALSE]
  df_w <- prepare_window_data(df_w)

  for (si in seq_len(nrow(spec_register))) {
    sp <- spec_register[si, ]
    regs <- split_terms(sp$regressors)
    key <- key_coefficients(sp$spec_id)
    df_cc <- complete_estimation_data(df_w, regs)
    cond <- if (nrow(df_cc) > length(regs)) condition_number_scaled(df_cc[, regs, drop = FALSE]) else NA_real_
    maxcorr <- if (nrow(df_cc) > length(regs)) max_abs_pairwise_cor(df_cc[, regs, drop = FALSE]) else NA_real_
    severe_collinearity <- (is.finite(cond) && cond > 100) || (is.finite(maxcorr) && maxcorr > 0.995)

    fm_ok <- estimator_ok(estimator_grid, w$window_id, sp$spec_id, "FM_OLS")
    im_ok <- estimator_ok(estimator_grid, w$window_id, sp$spec_id, "IM_OLS")
    dols_ok <- estimator_ok(estimator_grid, w$window_id, sp$spec_id, "DOLS")

    im_overturn <- if (fm_ok && im_ok) {
      sign_reversal_between(estimator_grid, w$window_id, sp$spec_id, "FM_OLS", "IM_OLS", key)
    } else {
      NA
    }
    dols_catastrophic <- if (fm_ok && dols_ok) {
      sign_reversal_between(estimator_grid, w$window_id, sp$spec_id, "FM_OLS", "DOLS", key)
    } else {
      FALSE
    }
    neigh_rev <- if (fm_ok) neighborhood_reversal_count(estimator_grid, w, sp$spec_id, key) else NA_integer_
    roll_rev <- rolling_proxy_reversal_count(sp$spec_id, key)

    statuses <- unique(estimator_grid$status[
      estimator_grid$window_id == w$window_id &
        estimator_grid$spec_id == sp$spec_id
    ])
    status_notes <- collapse_or_na(statuses)

    classification <- "REJECTED"
    if (isTRUE(sp$diagnostic_only)) {
      classification <- if (fm_ok || im_ok || dols_ok) "DIAGNOSTIC_ONLY" else "REJECTED"
    } else if (sp$spec_id == "SPEC_B0_CAPITAL_ONLY") {
      classification <- if (fm_ok) "SUPPORTING" else "REJECTED"
    } else if (!fm_ok) {
      classification <- "REJECTED"
    } else if (isTRUE(severe_collinearity) || isTRUE(im_overturn) ||
               isTRUE(dols_catastrophic) || (is.finite(neigh_rev) && neigh_rev > 0L)) {
      classification <- "FRAGILE"
    } else if (w$role %in% c("support", "support_short", "bridge", "predecessor")) {
      classification <- "SUPPORTING"
    } else {
      classification <- "CORE_CANDIDATE"
    }

    promotion_status <- switch(
      classification,
      CORE_CANDIDATE = "eligible_for_human_review",
      SUPPORTING = "supporting_benchmark_contrast",
      FRAGILE = "not_promoted_fragility_flag",
      DIAGNOSTIC_ONLY = "not_promoted_diagnostic_only",
      REJECTED = "not_promoted_rejected",
      "not_promoted"
    )

    stab_i <- stab_i + 1L
    stability_rows[[stab_i]] <- data.frame(
      window_id = w$window_id,
      window_role = w$role,
      year_start = w$year_start,
      year_end = w$year_end,
      available_start = w$available_start,
      available_end = w$available_end,
      spec_id = sp$spec_id,
      promotion_eligible = sp$promotion_eligible,
      classification = classification,
      promotion_status = promotion_status,
      fm_ols_ok = fm_ok,
      im_ols_ok = im_ok,
      dols_ok = dols_ok,
      im_ols_overturns_fm_sign_pattern = im_overturn,
      dols_catastrophic_contradiction = dols_catastrophic,
      neighborhood_reversal_count = neigh_rev,
      condition_number_scaled = cond,
      max_abs_pairwise_corr = maxcorr,
      severe_collinearity_flag = severe_collinearity,
      stability_test_type = "proxy_stability_diagnostic",
      exact_hansen_type_test = "not_implemented_in_this_S30",
      rolling_proxy_reversal_count = roll_rev,
      rolling_window_length = rolling_window_length,
      statuses_observed = status_notes,
      notes = paste(
        "Historical windows are benchmark contrasts, not search devices.",
        "Rolling diagnostics are not regime identifiers."
      ),
      stringsAsFactors = FALSE
    )
  }
}

stability_summary <- do.call(rbind, stability_rows)
rownames(stability_summary) <- NULL
write.csv(stability_summary, stability_path, row.names = FALSE)

# ---- 11. Manifest and report -------------------------------------------------
manifest <- data.frame(
  item = c(
    "script",
    "run_timestamp",
    "input_panel",
    "input_window_register",
    "output_dir",
    "cointReg_available",
    "fm_ols_bandwidth",
    "im_ols_bandwidth",
    "dols_leads_lags",
    "dols_bandwidth",
    "rolling_window_length",
    "exact_hansen_type_test",
    "stability_test_type",
    "warnings"
  ),
  value = c(
    "codes/US_S30_transformation_relation_fmols_imols_dols.R",
    RUN_TIMESTAMP,
    in_panel_path,
    ifelse(file.exists(in_window_register_path), in_window_register_path, "not_found"),
    out_dir,
    as.character(cointreg_available),
    FM_BANDWIDTH,
    IM_BANDWIDTH,
    as.character(DOLS_P),
    as.character(DOLS_BANDWIDTH),
    as.character(rolling_window_length),
    "not_implemented_in_this_S30",
    "proxy_stability_diagnostic",
    ifelse(length(s30_warnings) == 0L, "none", paste(s30_warnings, collapse = " | "))
  ),
  stringsAsFactors = FALSE
)
write.csv(manifest, manifest_path, row.names = FALSE)

estimated_grid <- estimator_grid[estimator_grid$status == "estimated" & estimator_grid$estimator_status == "ok", ]
successful_estimators <- sort(unique(estimated_grid$estimator))
unavailable_estimators <- sort(unique(estimator_grid$estimator[estimator_grid$estimator_status == "not_available"]))
if (length(unavailable_estimators) == 0L) unavailable_estimators <- "none"

classification_counts <- as.data.frame(table(stability_summary$classification), stringsAsFactors = FALSE)
names(classification_counts) <- c("classification", "n")
for (cls in c("CORE_CANDIDATE", "SUPPORTING", "FRAGILE", "DIAGNOSTIC_ONLY", "REJECTED")) {
  if (!cls %in% classification_counts$classification) {
    classification_counts <- rbind(
      classification_counts,
      data.frame(classification = cls, n = 0L, stringsAsFactors = FALSE)
    )
  }
}
classification_counts <- classification_counts[
  match(c("CORE_CANDIDATE", "SUPPORTING", "FRAGILE", "DIAGNOSTIC_ONLY", "REJECTED"),
        classification_counts$classification),
]

estimator_summary <- aggregate(
  run_id ~ estimator + estimator_status + status,
  data = estimator_grid,
  FUN = function(x) length(unique(x))
)
names(estimator_summary)[names(estimator_summary) == "run_id"] <- "grid_cells"

coverage_rows <- data.frame(
  variable = c(
    "y_t", "k_t", "omega_t", "omega_k_t", "s_t_proxy", "phi_t_proxy",
    "s_t_proxy_cc", "phi_t_proxy_cc", "pK_relative_ME_NRC"
  ),
  present = c(
    "y_t" %in% names(panel), "k_t" %in% names(panel), "omega_t" %in% names(panel),
    "omega_k_t" %in% names(panel), "s_t_proxy" %in% names(panel),
    "phi_t_proxy" %in% names(panel), "s_t_proxy_cc" %in% names(panel),
    "phi_t_proxy_cc" %in% names(panel), "pK_relative_ME_NRC" %in% names(panel)
  ),
  finite_observations = c(
    sum(is.finite(panel$y_t)),
    sum(is.finite(panel$k_t)),
    sum(is.finite(panel$omega_t)),
    sum(is.finite(panel$omega_k_t)),
    sum(is.finite(panel$s_t_proxy)),
    sum(is.finite(panel$phi_t_proxy)),
    sum(is.finite(panel$s_t_proxy_cc)),
    sum(is.finite(panel$phi_t_proxy_cc)),
    sum(is.finite(panel$pK_relative_ME_NRC))
  ),
  stringsAsFactors = FALSE
)

promotion_table <- stability_summary[
  stability_summary$classification %in% c("CORE_CANDIDATE", "SUPPORTING", "FRAGILE") &
    stability_summary$promotion_eligible,
  c(
    "window_id", "spec_id", "classification", "promotion_status",
    "fm_ols_ok", "im_ols_ok", "dols_ok",
    "severe_collinearity_flag", "neighborhood_reversal_count",
    "rolling_proxy_reversal_count"
  ),
  drop = FALSE
]

rolling_summary <- if (nrow(rolling_coefficients) == 0L) {
  data.frame(metric = "rolling_rows", value = "0", stringsAsFactors = FALSE)
} else {
  data.frame(
    metric = c(
      "rolling_window_length",
      "diagnostic_type",
      "estimated_rows",
      "failed_or_rejected_rows"
    ),
    value = c(
      as.character(rolling_window_length),
      rolling_source_label,
      as.character(sum(rolling_coefficients$status == "estimated")),
      as.character(sum(rolling_coefficients$status != "estimated"))
    ),
    stringsAsFactors = FALSE
  )
}

report <- c(
  "# US S30 transformation-relation report",
  "",
  "## 1. Purpose of S30",
  "",
  "S30 estimates and audits the long-run US transformation relation through a pre-declared estimator x window x specification grid.",
  "The purpose is coefficient recovery plus parameter-stability discipline. Historical windows are pre-declared benchmark contrasts, not search devices.",
  "",
  "## 2. Input panel and variable coverage",
  "",
  paste0("- Input panel: `", in_panel_path, "`"),
  paste0("- Panel span: ", min(panel$year, na.rm = TRUE), "-", max(panel$year, na.rm = TRUE)),
  paste0("- Observations: ", nrow(panel)),
  "",
  md_table(coverage_rows),
  "",
  "## 3. Composition status",
  "",
  paste0("- composition_status: ", ifelse(is.na(composition_status_panel), "NA", composition_status_panel)),
  paste0("- composition_basis: ", ifelse(is.na(composition_basis_panel), "NA", composition_basis_panel)),
  paste0("- composition_tier: ", ifelse(is.na(composition_tier_panel), "NA", composition_tier_panel)),
  paste0("- direct_sector_asset_split: ", bool_to_text(direct_sector_asset_split_panel)),
  "- The US composition variable is a Tier-B ME-NRC component proxy.",
  "- It is not a direct NFCorp-by-asset-type split.",
  "",
  "## 4. Window register used",
  "",
  paste0("- Register written: `", window_register_used_path, "`"),
  paste0("- Windows used: ", nrow(windows)),
  "",
  md_table(windows[, c("window_id", "year_start", "year_end", "role", "source"), drop = FALSE]),
  "",
  "## 5. Estimator availability",
  "",
  md_table(estimator_availability),
  "",
  paste0("- Estimators successfully run: ", paste(successful_estimators, collapse = ", ")),
  paste0("- Estimators unavailable: ", paste(unavailable_estimators, collapse = ", ")),
  "",
  "## 6. Specification register",
  "",
  paste0("- Register written: `", spec_register_path, "`"),
  "",
  md_table(spec_register[, c("spec_id", "formula_label", "role", "promotion_eligible", "diagnostic_only"), drop = FALSE]),
  "",
  "## 7. Main estimator grid summary",
  "",
  paste0("- Estimator grid: `", grid_path, "`"),
  paste0("- Estimated windows: ", length(unique(estimated_grid$window_id))),
  paste0("- Estimated specifications: ", length(unique(estimated_grid$spec_id))),
  "",
  md_table(estimator_summary),
  "",
  "## 8. Stability and proxy-stability summary",
  "",
  paste0("- Stability summary: `", stability_path, "`"),
  "- Exact Hansen-type parameter-instability testing was not implemented in this S30 script.",
  "- The stability check is labeled proxy_stability_diagnostic and uses estimator triangulation, neighborhood checks, collinearity diagnostics, and rolling coefficient paths.",
  "- Rolling/recursive diagnostics do not identify regimes.",
  "",
  md_table(classification_counts),
  "",
  "## 9. Rolling/recursive diagnostic summary",
  "",
  paste0("- Rolling coefficients: `", rolling_path, "`"),
  "- Rolling estimates are diagnostics, not regime identifiers.",
  "- Recursive estimates are not implemented in this first S30 script.",
  "",
  md_table(rolling_summary),
  "",
  "## 10. Promotion table",
  "",
  "Promotion is review eligibility only. No result is promoted solely because a coefficient has a preferred sign or significance.",
  "",
  md_table(promotion_table, n = 40),
  "",
  "## 11. Guardrails and non-claims",
  "",
  "- S30 does not reconstruct μ.",
  "- S30 does not estimate θ^M directly.",
  "- S30 does not reconstruct Yp.",
  "- S30 does not compute capacity utilization.",
  "- S30 does not run profitability analysis.",
  "- S30 does not estimate threshold/FGLS.",
  "- S30 does not run Gregory-Hansen, Bai-Perron, or Kejriwal-Perron.",
  "- The Tier-B ME-NRC proxy is not a direct NFCorp-by-asset-type split.",
  "- Historical windows are pre-declared benchmark contrasts.",
  "",
  "## 12. Next step",
  "",
  "S40 is allowed only after a S30 core candidate is reviewed.",
  "",
  "## Warnings",
  "",
  if (length(s30_warnings) == 0L) "- none" else paste0("- ", s30_warnings)
)

writeLines(report, report_path, useBytes = TRUE)

cat("US S30 transformation-relation outputs written:\n")
cat("  ", grid_path, "\n", sep = "")
cat("  ", stability_path, "\n", sep = "")
cat("  ", rolling_path, "\n", sep = "")
cat("  ", report_path, "\n", sep = "")
