#!/usr/bin/env Rscript

# S34 builds a pre-regression variable-menu inspection layer. It estimates no
# long-run model, runs no FM-OLS/DOLS/IM-OLS pass, and modifies no locked input.

suppressPackageStartupMessages({
  library(ggplot2)
  library(tseries)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir <- file.path(repo_root, "output", "S34_pre_regression")
plot_dir <- file.path(out_dir, "plots")
plot_dirs <- file.path(
  plot_dir,
  c(
    "variable_levels", "variable_differences", "candidate_level_relations",
    "scatter_levels", "scatter_differences"
  )
)

input_paths <- c(
  s31i_panel = file.path(
    repo_root, "data", "processed", "us_s31i",
    "us_s31i_candidate_audit_panel.csv"
  ),
  s31i_registry = file.path(
    repo_root, "data", "processed", "us_s31i",
    "us_s31i_variable_registry.csv"
  ),
  s31i_i2 = file.path(
    repo_root, "data", "processed", "us_s31i",
    "us_s31i_i2_risk_ledger.csv"
  ),
  s32c_panel = file.path(
    repo_root, "data", "processed", "us_s32c",
    "us_s32c_candidate_panel.csv"
  ),
  s32c_checks = file.path(
    repo_root, "data", "processed", "us_s32c",
    "us_s32c_validation_checks.csv"
  ),
  s30e_dictionary = file.path(
    repo_root, "output", "US",
    "S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY",
    "csv", "S30E_variable_dictionary.csv"
  ),
  s30e_admissibility = file.path(
    repo_root, "output", "US",
    "S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY",
    "csv", "S30E_admissibility_ledger.csv"
  ),
  s33_note = file.path(
    repo_root, "docs", "ch2", "S33_theta_recovery_specification_ledger.md"
  )
)

output_paths <- c(
  integration_ledger = file.path(
    out_dir, "us_s34_variable_menu_integration_ledger.csv"
  ),
  interaction_ledger = file.path(
    out_dir, "us_s34_interaction_i2_risk_ledger.csv"
  ),
  relation_ledger = file.path(
    out_dir, "us_s34_candidate_level_relation_ledger.csv"
  ),
  collinearity_ledger = file.path(
    out_dir, "us_s34_collinearity_design_ledger.csv"
  ),
  memo = file.path(out_dir, "us_s34_pre_regression_admissibility_memo.md"),
  validation = file.path(out_dir, "us_s34_validation_checks.csv"),
  input_selection = file.path(out_dir, "us_s34_input_selection_note.csv")
)

abort <- function(message) stop(message, call. = FALSE)
require_condition <- function(condition, message) {
  if (!isTRUE(condition)) abort(message)
}
read_csv <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}
write_csv <- function(data, path) {
  write.csv(data, path, row.names = FALSE, na = "")
}
as_num <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x[!is.finite(x)] <- NA_real_
  x
}
safe_name <- function(x) gsub("[^A-Za-z0-9_]+", "_", x)
collapse_unique <- function(x, sep = "; ") {
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (length(x)) paste(x, collapse = sep) else ""
}
fmt_num <- function(x, digits = 4L) {
  ifelse(is.na(x), "", formatC(x, digits = digits, format = "fg"))
}
escape_md <- function(x) gsub("|", "\\|", as.character(x), fixed = TRUE)
md_table <- function(data, columns = names(data), max_rows = Inf) {
  show <- data[, columns, drop = FALSE]
  if (is.finite(max_rows) && nrow(show) > max_rows) {
    show <- show[seq_len(max_rows), , drop = FALSE]
  }
  if (!nrow(show)) return("_No rows._")
  show[] <- lapply(show, function(x) {
    if (is.numeric(x)) fmt_num(x) else {
      x <- as.character(x)
      x[is.na(x)] <- ""
      x
    }
  })
  c(
    paste0("|", paste(columns, collapse = "|"), "|"),
    paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|"),
    apply(show, 1L, function(row) {
      paste0("|", paste(vapply(row, escape_md, character(1L)), collapse = "|"), "|")
    })
  )
}
validation_row <- function(id, status, details) {
  data.frame(check_id = id, status = status, details = details,
             stringsAsFactors = FALSE)
}

missing_inputs <- input_paths[!file.exists(input_paths)]
require_condition(
  !length(missing_inputs),
  paste("Missing S34 inputs:", paste(missing_inputs, collapse = "\n"))
)

for (path in c(out_dir, plot_dirs)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

input_hashes_before <- tools::md5sum(input_paths)

s31i <- read_csv(input_paths[["s31i_panel"]])
registry <- read_csv(input_paths[["s31i_registry"]])
s31i_i2 <- read_csv(input_paths[["s31i_i2"]])
s32c <- read_csv(input_paths[["s32c_panel"]])
s32c_checks <- read_csv(input_paths[["s32c_checks"]])
s30e_dictionary <- read_csv(input_paths[["s30e_dictionary"]])
s30e_admissibility <- read_csv(input_paths[["s30e_admissibility"]])

require_condition(!any(s32c_checks$status == "FAIL"), "S32C validation has FAIL rows.")
require_condition(!anyDuplicated(s31i$year), "S31I panel years duplicate.")
require_condition(!anyDuplicated(s32c$year), "S32C panel years duplicate.")

panel <- s31i[order(s31i$year), ]
s32c_only <- setdiff(names(s32c), names(panel))
for (name in s32c_only) {
  panel[[name]] <- s32c[[name]][match(panel$year, s32c$year)]
}

add_registry_row <- function(variable, family, role, preferred_status, source,
                             formula, construction_status,
                             deterministic_family, notes = "") {
  data.frame(
    variable = variable, family = family, role = role,
    preferred_status = preferred_status, source = source, formula = formula,
    construction_status = construction_status,
    deterministic_family = deterministic_family, notes = notes,
    stringsAsFactors = FALSE
  )
}

extra_registry <- list()
for (name in s32c_only) {
  extra_registry[[length(extra_registry) + 1L]] <- add_registry_row(
    name, "corporate_boundary_diagnostics", "corporate_boundary_candidate",
    "diagnostic_or_robustness", paste0("S32C:", name), "upstream S32C object",
    "validated_upstream_s32c", ifelse(grepl("^q_|^y_|real|GVA", name), "trend", "bounded"),
    "Added to S34 as secondary context; S31I remains the primary broad panel."
  )
}

lag_by_year <- function(x, year, lag_count = 1L) x[match(year - lag_count, year)]
safe_diff <- function(x, year) {
  x <- as_num(x)
  out <- rep(NA_real_, length(x))
  ok <- diff(year) == 1L & !is.na(x[-1L]) & !is.na(x[-length(x)])
  out[which(ok) + 1L] <- diff(x)[ok]
  out
}
weighted_path <- function(state, change, year) {
  increment <- lag_by_year(as_num(state), year, 1L) * as_num(change)
  out <- rep(NA_real_, length(increment))
  ok <- which(is.finite(increment))
  if (!length(ok)) return(out)
  blocks <- split(ok, cumsum(c(TRUE, diff(ok) != 1L)))
  block <- blocks[[which.max(vapply(blocks, length, integer(1L)))]]
  out[block] <- cumsum(increment[block])
  out
}

panel$Q_omega <- panel$q_omega_h1_Kcap
panel$q_proxy_mechanization_growth <- panel$g_ME_minus_NRC
panel$Q_q <- weighted_path(
  panel$q_proxy_mechanization_growth, panel$g_Kcap, panel$year
)
panel$Q_MEshare <- weighted_path(panel$ME_share, panel$g_Kcap, panel$year)
if (!"ME_investment_share" %in% names(panel)) {
  panel$Q_Ishare <- NA_real_
}

extra_registry[[length(extra_registry) + 1L]] <- add_registry_row(
  "Q_omega", "accumulated_path_candidates", "distribution_weighted_accumulation_path",
  "second_order_candidate", "S31I:q_omega_h1_Kcap",
  "alias: cumsum(lag(omega_NFC,1) * Delta log K_cap)",
  "S34_alias_existing_q_path", "trend",
  "Reduced-form distribution-weighted accumulated path."
)
extra_registry[[length(extra_registry) + 1L]] <- add_registry_row(
  "q_proxy_mechanization_growth", "technique_choice_proxies", "mechanization_q_proxy",
  "diagnostic_candidate", "S31I:g_ME_minus_NRC",
  "g_K_ME - g_K_NRC", "S34_alias_existing_mechanization_change", "bounded",
  "Observed technique proxy for S34 screening; not a final q-star measure."
)
extra_registry[[length(extra_registry) + 1L]] <- add_registry_row(
  "Q_q", "accumulated_path_candidates", "observed_q_weighted_accumulation_path",
  "main_extension_candidate", "S34",
  "cumsum(lag(q_proxy_mechanization_growth,1) * Delta log K_cap)",
  "constructed_for_S34_admissibility_screen", "trend",
  "Empirical proxy for observed-technique weighted accumulation."
)
extra_registry[[length(extra_registry) + 1L]] <- add_registry_row(
  "Q_MEshare", "accumulated_path_candidates", "composition_weighted_accumulation_path",
  "second_order_candidate", "S34",
  "cumsum(lag(ME_share,1) * Delta log K_cap)",
  "constructed_for_S34_admissibility_screen", "trend",
  "Composition-conditioned accumulated capacity path."
)
extra_registry[[length(extra_registry) + 1L]] <- add_registry_row(
  "Q_Ishare", "accumulated_path_candidates", "flow_composition_weighted_accumulation_path",
  "not_constructed", "S34",
  "requires ME investment share", "not_constructed_missing_authorized_panel_object",
  "trend", "ME investment share is not present in the selected S31I/S32C panel."
)

registry <- rbind(registry, do.call(rbind, extra_registry))
registry <- registry[!duplicated(registry$variable), ]
registry <- registry[registry$variable %in% names(panel), ]

candidate_variables <- unique(c(
  registry$variable,
  "y_t", "k_Kcap", "k_ME", "k_NRC", "K_cap", "K_ME", "K_NRC",
  "ME_NRC_gap", "ME_share", "NRC_share", "omega_NFC", "omega_CORP",
  "pi_res_NFC", "pi_res_CORP", "q_proxy_mechanization_growth",
  "q_omega_h1_Kcap", "Q_omega", "Q_q", "Q_MEshare", "Q_Ishare",
  "q_omega_h1_ME", "q_omega_h1_NRC", "q_omega_h1_ME_minus_NRC",
  "y_CORP", "q_omegaCORP_h1_Kcap"
))
candidate_variables <- candidate_variables[candidate_variables %in% names(panel)]

longest_block <- function(x, year) {
  ok <- which(is.finite(as_num(x)) & is.finite(year))
  if (!length(ok)) return(data.frame(year = integer(), value = numeric()))
  blocks <- split(ok, cumsum(c(TRUE, diff(ok) != 1L)))
  idx <- blocks[[which.max(vapply(blocks, length, integer(1L)))]]
  data.frame(year = year[idx], value = as_num(x)[idx])
}

safe_p <- function(expr) {
  out <- tryCatch(
    suppressWarnings(expr),
    error = function(e) e
  )
  if (inherits(out, "error")) return(NA_real_)
  p <- suppressWarnings(as.numeric(out$p.value))
  if (length(p) == 1L && is.finite(p)) p else NA_real_
}

run_tests <- function(x, year) {
  block <- longest_block(x, year)
  if (nrow(block) < 12L || stats::sd(block$value, na.rm = TRUE) == 0) {
    return(c(
      n_obs = nrow(block), sample_start = NA_real_, sample_end = NA_real_,
      adf_level_p = NA_real_, adf_diff_p = NA_real_,
      kpss_level_p = NA_real_, kpss_diff_p = NA_real_,
      pp_level_p = NA_real_, pp_diff_p = NA_real_,
      adf_second_diff_p = NA_real_, kpss_second_diff_p = NA_real_
    ))
  }
  level <- block$value
  diff1 <- diff(level)
  diff2 <- diff(level, differences = 2L)
  c(
    n_obs = nrow(block),
    sample_start = min(block$year), sample_end = max(block$year),
    adf_level_p = safe_p(tseries::adf.test(level, alternative = "stationary")),
    adf_diff_p = if (length(diff1) >= 12L) safe_p(tseries::adf.test(diff1, alternative = "stationary")) else NA_real_,
    kpss_level_p = safe_p(tseries::kpss.test(level, null = "Level")),
    kpss_diff_p = if (length(diff1) >= 12L) safe_p(tseries::kpss.test(diff1, null = "Level")) else NA_real_,
    pp_level_p = safe_p(tseries::pp.test(level, alternative = "stationary")),
    pp_diff_p = if (length(diff1) >= 12L) safe_p(tseries::pp.test(diff1, alternative = "stationary")) else NA_real_,
    adf_second_diff_p = if (length(diff2) >= 12L) safe_p(tseries::adf.test(diff2, alternative = "stationary")) else NA_real_,
    kpss_second_diff_p = if (length(diff2) >= 12L) safe_p(tseries::kpss.test(diff2, null = "Level")) else NA_real_
  )
}

is_bounded_var <- function(name, meta) {
  if (grepl("^Q_|^q_", name)) return(FALSE)
  grepl("(^omega_)|(^pi_res_)|share|_to_|burden|ratio",
        name, ignore.case = TRUE)
}

classify_variable <- function(name, meta, tests) {
  if (is.na(tests[["n_obs"]]) || tests[["n_obs"]] < 12L) return("DIAGNOSTIC_ONLY")
  ur_l <- tests[["adf_level_p"]] < 0.05 ||
    tests[["pp_level_p"]] < 0.05
  kpss_l <- tests[["kpss_level_p"]] > 0.05
  ur_d <- tests[["adf_diff_p"]] < 0.05 ||
    tests[["pp_diff_p"]] < 0.05
  kpss_d <- tests[["kpss_diff_p"]] > 0.05
  ur_dd <- tests[["adf_second_diff_p"]] < 0.05
  kpss_dd <- tests[["kpss_second_diff_p"]] > 0.05
  bounded <- is_bounded_var(name, meta)
  if (bounded && !(isTRUE(ur_l) && isTRUE(kpss_l))) return("BOUNDED_PERSISTENT")
  if (isTRUE(ur_l) && isTRUE(kpss_l)) return("I0")
  if (isTRUE(ur_d) && isTRUE(kpss_d)) return("I1")
  if (isTRUE(ur_dd) && isTRUE(kpss_dd)) return("I2_RISK")
  if (grepl("growth|Delta_|increment|q_proxy", name)) return("DIAGNOSTIC_ONLY")
  "AMBIGUOUS"
}

economic_role <- function(name, meta) {
  if (nzchar(meta$role)) return(meta$role)
  if (grepl("^y", name)) return("effective_output_proxy")
  if (grepl("^k_|^K_", name)) return("capacity_capital")
  if (grepl("omega|share|pi_res", name)) return("distribution_or_composition_state")
  if (grepl("^Q_|^q_", name)) return("accumulated_or_technique_path")
  "candidate_variable"
}

expected_order <- function(name, meta) {
  if (is_bounded_var(name, meta)) return("bounded_persistent_or_I0")
  if (grepl("growth|Delta_|increment|q_proxy", name)) return("I0_or_diagnostic")
  if (identical(meta$deterministic_family, "trend")) return("I1")
  "undetermined"
}

ledger_rows <- list()
for (name in candidate_variables) {
  meta <- registry[match(name, registry$variable), , drop = FALSE]
  if (!nrow(meta) || is.na(meta$variable[1L])) {
    meta <- add_registry_row(name, "", "", "", "unknown", "", "", "", "")
  }
  tests <- run_tests(panel[[name]], panel$year)
  prior <- s31i_i2[s31i_i2$variable == name, , drop = FALSE]
  cls <- classify_variable(name, meta[1, ], tests)
  bounded_note <- if (is_bounded_var(name, meta[1, ])) {
    "Bounded ratio/share: persistent evidence is not mechanically promoted to pure I(1)."
  } else {
    ""
  }
  prior_note <- if (nrow(prior)) {
    paste0("S31I=", prior$i_order_recommendation[1L], "; ",
           prior$s32_recommendation[1L])
  } else {
    ""
  }
  ledger_rows[[length(ledger_rows) + 1L]] <- data.frame(
    variable_name = name,
    source_file = meta$source[1L],
    construction_status = meta$construction_status[1L],
    economic_role = economic_role(name, meta[1, ]),
    theoretical_role = meta$preferred_status[1L],
    expected_order = expected_order(name, meta[1, ]),
    adf_level_p = tests[["adf_level_p"]],
    adf_diff_p = tests[["adf_diff_p"]],
    kpss_level_p = tests[["kpss_level_p"]],
    kpss_diff_p = tests[["kpss_diff_p"]],
    pp_level_p_if_available = tests[["pp_level_p"]],
    pp_diff_p_if_available = tests[["pp_diff_p"]],
    classification = cls,
    notes = collapse_unique(c(bounded_note, prior_note, meta$notes[1L])),
    sample_start = tests[["sample_start"]],
    sample_end = tests[["sample_end"]],
    n_obs = tests[["n_obs"]],
    stringsAsFactors = FALSE
  )
}
integration_ledger <- do.call(rbind, ledger_rows)
write_csv(integration_ledger, output_paths[["integration_ledger"]])

classification_of <- function(name) {
  hit <- integration_ledger[integration_ledger$variable_name == name, "classification"]
  if (length(hit)) hit[1L] else "NOT_CONSTRUCTED"
}
state_i0 <- function(name) classification_of(name) == "I0"
i1_like <- function(name) classification_of(name) %in% c("I1", "BOUNDED_PERSISTENT")

interaction_rows <- list()
add_interaction <- function(object_id, object_type, variables_used,
                            construction_status, classification, notes) {
  interaction_rows[[length(interaction_rows) + 1L]] <<- data.frame(
    object_id = object_id, object_type = object_type,
    variables_used = paste(variables_used, collapse = " + "),
    construction_status = construction_status, classification = classification,
    notes = notes, stringsAsFactors = FALSE
  )
}
raw_rule <- function(vars, state_var = NULL) {
  if (!is.null(state_var) && state_i0(state_var)) return("AUTHORIZE_ONLY_IF_STATE_I0")
  if (any(vapply(vars, i1_like, logical(1L)))) return("BLOCK_STANDARD_I2_RISK")
  "CPR_EXPERIMENT_ONLY"
}
add_interaction(
  "k_cap_times_wage_share", "raw_level_interaction",
  c("k_Kcap", "omega_NFC"), "assessed_not_constructed_for_standard_grid",
  raw_rule(c("k_Kcap", "omega_NFC"), "omega_NFC"),
  "Raw k*omega is theoretically second-order and blocked unless the state is I0."
)
add_interaction(
  "k_cap_times_q", "raw_level_interaction",
  c("k_Kcap", "q_omega_h1_Kcap"), "assessed_not_constructed_for_standard_grid",
  raw_rule(c("k_Kcap", "q_omega_h1_Kcap"), "q_omega_h1_Kcap"),
  "Raw k*q confounds accumulated technique path logic and carries I(2) risk."
)
add_interaction(
  "q_squared", "power", c("q_omega_h1_Kcap"),
  "assessed_not_constructed_for_standard_grid",
  if (state_i0("q_omega_h1_Kcap")) "AUTHORIZE_ONLY_IF_STATE_I0" else "BLOCK_STANDARD_I2_RISK",
  "Polynomial q is routed away from the standard grid unless q is stationary."
)
add_interaction(
  "wage_share_squared", "power", c("omega_NFC"),
  "assessed_not_constructed_for_standard_grid",
  if (state_i0("omega_NFC")) "AUTHORIZE_ONLY_IF_STATE_I0" else "CPR_EXPERIMENT_ONLY",
  "Bounded persistent wage share is not a clean standard polynomial object."
)
add_interaction(
  "q_times_wage_share", "raw_level_interaction",
  c("q_omega_h1_Kcap", "omega_NFC"),
  "assessed_not_constructed_for_standard_grid",
  raw_rule(c("q_omega_h1_Kcap", "omega_NFC"), "omega_NFC"),
  "Raw q*omega is overloaded relative to the accumulated-path hierarchy."
)
for (q_name in c("Q_omega", "Q_q", "Q_MEshare", "Q_Ishare")) {
  cls <- classification_of(q_name)
  status <- if (all(is.na(panel[[q_name]]))) {
    "not_constructed_missing_authorized_input"
  } else {
    "constructed_or_existing_path_tested"
  }
  decision <- if (status == "not_constructed_missing_authorized_input") {
    "NOT_CONSTRUCTED"
  } else if (cls == "I1") {
    "AUTHORIZE_STANDARD_IF_I1"
  } else if (cls == "I0") {
    "DIAGNOSTIC_ONLY"
  } else if (cls == "I2_RISK") {
    "BLOCK_STANDARD_I2_RISK"
  } else {
    "DIAGNOSTIC_ONLY"
  }
  add_interaction(
    q_name, "accumulated_weighted_path", q_name, status, decision,
    paste0("Integration classification in S34 ledger: ", cls,
           ". Accumulated paths are tested separately from raw products.")
  )
}
interaction_ledger <- do.call(rbind, interaction_rows)
write_csv(interaction_ledger, output_paths[["interaction_ledger"]])

plot_variable <- function(name, subdir, transform = c("level", "diff")) {
  transform <- match.arg(transform)
  data <- data.frame(year = panel$year, value = as_num(panel[[name]]))
  if (transform == "diff") {
    data$value <- safe_diff(data$value, data$year)
  }
  data <- data[is.finite(data$value), ]
  if (nrow(data) < 2L) return(FALSE)
  ylab <- if (transform == "level") name else paste0("Delta ", name)
  p <- ggplot(data, aes(year, value)) +
    geom_line(linewidth = 0.4, color = "#1f4e79") +
    geom_vline(xintercept = c(1973, 1974), linetype = "dashed",
               linewidth = 0.3, color = "#8b1a1a") +
    labs(title = ylab, x = NULL, y = NULL) +
    theme_minimal(base_size = 10)
  ggsave(
    filename = file.path(subdir, paste0(safe_name(name), ".png")),
    plot = p, width = 7.5, height = 4.2, dpi = 140
  )
  TRUE
}

plot_count <- 0L
for (name in candidate_variables) {
  plot_count <- plot_count + plot_variable(
    name, file.path(plot_dir, "variable_levels"), "level"
  )
  plot_count <- plot_count + plot_variable(
    name, file.path(plot_dir, "variable_differences"), "diff"
  )
}

relation_specs <- data.frame(
  relation_id = c(
    "REL_y_kcap", "REL_y_kME", "REL_y_kNRC", "REL_q_omega",
    "REL_y_Qomega", "REL_y_Qq", "REL_y_MEshare", "REL_y_QMEshare",
    "REL_ycorp_Qcorp"
  ),
  lhs = c("y_t", "y_t", "y_t", "q_proxy_mechanization_growth",
          "y_t", "y_t", "y_t", "y_t", "y_CORP"),
  rhs = c("k_Kcap", "k_ME", "k_NRC", "omega_NFC",
          "Q_omega", "Q_q", "ME_share", "Q_MEshare",
          "q_omegaCORP_h1_Kcap"),
  theoretical_status = c(
    "THEORY_CORE", "HETEROGENEOUS_CAPITAL", "HETEROGENEOUS_CAPITAL",
    "TECHNIQUE_CHOICE", "THEORY_SECOND_ORDER", "THEORY_CORE",
    "HETEROGENEOUS_CAPITAL", "HETEROGENEOUS_CAPITAL",
    "DIAGNOSTIC"
  ),
  stringsAsFactors = FALSE
)

relation_rows <- list()
plot_relation <- function(spec) {
  if (!all(c(spec$lhs, spec$rhs) %in% names(panel))) return(FALSE)
  data <- data.frame(
    year = panel$year,
    lhs = as_num(panel[[spec$lhs]]),
    rhs = as_num(panel[[spec$rhs]])
  )
  data <- data[stats::complete.cases(data), ]
  if (nrow(data) < 8L) return(FALSE)
  z <- data.frame(
    year = rep(data$year, 2L),
    variable = rep(c(spec$lhs, spec$rhs), each = nrow(data)),
    value = c(as.numeric(scale(data$lhs)), as.numeric(scale(data$rhs)))
  )
  p_level <- ggplot(z, aes(year, value, color = variable)) +
    geom_line(linewidth = 0.45) +
    geom_vline(xintercept = c(1973, 1974), linetype = "dashed",
               linewidth = 0.3, color = "#8b1a1a") +
    labs(title = spec$relation_id, x = NULL, y = "standardized level") +
    theme_minimal(base_size = 10) +
    theme(legend.position = "bottom")
  ggsave(
    file.path(plot_dir, "candidate_level_relations",
              paste0(safe_name(spec$relation_id), ".png")),
    p_level, width = 7.5, height = 4.2, dpi = 140
  )
  p_scatter <- ggplot(data, aes(rhs, lhs)) +
    geom_point(size = 1.6, color = "#1f4e79") +
    geom_smooth(method = "lm", se = FALSE, linewidth = 0.4, color = "#8b1a1a") +
    labs(title = spec$relation_id, x = spec$rhs, y = spec$lhs) +
    theme_minimal(base_size = 10)
  ggsave(
    file.path(plot_dir, "scatter_levels",
              paste0(safe_name(spec$relation_id), ".png")),
    p_scatter, width = 5.2, height = 4.4, dpi = 140
  )
  ddata <- data.frame(
    lhs = safe_diff(data$lhs, data$year),
    rhs = safe_diff(data$rhs, data$year)
  )
  ddata <- ddata[stats::complete.cases(ddata), ]
  if (nrow(ddata) >= 8L) {
    p_d <- ggplot(ddata, aes(rhs, lhs)) +
      geom_point(size = 1.6, color = "#1f4e79") +
      geom_smooth(method = "lm", se = FALSE, linewidth = 0.4, color = "#8b1a1a") +
      labs(title = paste0(spec$relation_id, " differences"),
           x = paste0("Delta ", spec$rhs), y = paste0("Delta ", spec$lhs)) +
      theme_minimal(base_size = 10)
    ggsave(
      file.path(plot_dir, "scatter_differences",
                paste0(safe_name(spec$relation_id), ".png")),
      p_d, width = 5.2, height = 4.4, dpi = 140
    )
  }
  TRUE
}

relation_plot_count <- 0L
for (i in seq_len(nrow(relation_specs))) {
  spec <- relation_specs[i, ]
  ok <- all(c(spec$lhs, spec$rhs) %in% names(panel))
  data <- if (ok) {
    data.frame(lhs = as_num(panel[[spec$lhs]]), rhs = as_num(panel[[spec$rhs]]))
  } else {
    data.frame(lhs = numeric(), rhs = numeric())
  }
  data <- data[stats::complete.cases(data), , drop = FALSE]
  corr <- if (nrow(data) >= 8L) stats::cor(data$lhs, data$rhs) else NA_real_
  visual_status <- if (is.na(corr)) {
    "not_available"
  } else if (abs(corr) >= 0.75) {
    "visually_plausible"
  } else if (abs(corr) >= 0.35) {
    "mixed_visual_support"
  } else {
    "weak_visual_support"
  }
  lhs_cls <- classification_of(spec$lhs)
  rhs_cls <- classification_of(spec$rhs)
  compatibility <- if (lhs_cls == "I1" && rhs_cls == "I1") {
    "compatible_I1_pair"
  } else if (rhs_cls == "BOUNDED_PERSISTENT") {
    "bounded_state_not_standard_I1"
  } else if ("I2_RISK" %in% c(lhs_cls, rhs_cls)) {
    "blocked_i2_risk"
  } else {
    "mixed_or_diagnostic"
  }
  standard <- compatibility == "compatible_I1_pair" &&
    visual_status %in% c("visually_plausible", "mixed_visual_support")
  blocked <- if (standard) "" else paste(
    c(
      if (compatibility != "compatible_I1_pair") compatibility else NULL,
      if (visual_status == "weak_visual_support") "weak_visual_support" else NULL
    ),
    collapse = "; "
  )
  relation_rows[[length(relation_rows) + 1L]] <- data.frame(
    relation_id = spec$relation_id, lhs = spec$lhs, rhs_set = spec$rhs,
    theoretical_status = spec$theoretical_status,
    visual_status = visual_status,
    integration_compatibility = compatibility,
    standard_cointegration_candidate = standard,
    blocked_reason = blocked,
    notes = paste0("level_correlation=", fmt_num(corr, 3L),
                   "; lhs=", lhs_cls, "; rhs=", rhs_cls),
    stringsAsFactors = FALSE
  )
  relation_plot_count <- relation_plot_count + plot_relation(spec)
}
relation_ledger <- do.call(rbind, relation_rows)
write_csv(relation_ledger, output_paths[["relation_ledger"]])

design_specs <- list(
  "DES_kcap_Qomega" = c("k_Kcap", "Q_omega"),
  "DES_kcap_Qq" = c("k_Kcap", "Q_q"),
  "DES_kcap_MEshare" = c("k_Kcap", "ME_share"),
  "DES_kME_kNRC" = c("k_ME", "k_NRC"),
  "DES_kcap_Qq_Qomega" = c("k_Kcap", "Q_q", "Q_omega"),
  "DES_kcap_Qq_MEshare" = c("k_Kcap", "Q_q", "ME_share")
)
design_rows <- list()
for (id in names(design_specs)) {
  vars <- design_specs[[id]]
  if (!all(vars %in% names(panel))) {
    design_rows[[length(design_rows) + 1L]] <- data.frame(
      design_id = id, regressors = paste(vars, collapse = " + "),
      n_obs = 0L, condition_number = NA_real_,
      pairwise_correlation_max = NA_real_, rank_status = "missing_variable",
      notes = paste("Missing:", paste(setdiff(vars, names(panel)), collapse = ", ")),
      stringsAsFactors = FALSE
    )
    next
  }
  data <- panel[, vars, drop = FALSE]
  data[] <- lapply(data, as_num)
  data <- data[stats::complete.cases(data), , drop = FALSE]
  if (nrow(data) < length(vars) + 5L) {
    rank_status <- "insufficient_complete_cases"
    cond <- NA_real_
    max_corr <- NA_real_
  } else {
    x <- scale(as.matrix(data))
    cond <- tryCatch(kappa(x, exact = TRUE), error = function(e) NA_real_)
    qr_rank <- qr(x)$rank
    rank_status <- if (qr_rank == ncol(x)) "full_rank" else "rank_deficient"
    corr <- suppressWarnings(stats::cor(x))
    max_corr <- if (ncol(x) > 1L) {
      max(abs(corr[upper.tri(corr)]), na.rm = TRUE)
    } else {
      NA_real_
    }
  }
  note <- if (is.finite(cond) && cond > 30) {
    "High condition number; fragile design warning."
  } else if (is.finite(max_corr) && max_corr > 0.95) {
    "Very high pairwise correlation; fragile design warning."
  } else {
    "Diagnostic only; not a model-selection result."
  }
  design_rows[[length(design_rows) + 1L]] <- data.frame(
    design_id = id, regressors = paste(vars, collapse = " + "),
    n_obs = nrow(data), condition_number = cond,
    pairwise_correlation_max = max_corr, rank_status = rank_status,
    notes = note, stringsAsFactors = FALSE
  )
}
collinearity_ledger <- do.call(rbind, design_rows)
write_csv(collinearity_ledger, output_paths[["collinearity_ledger"]])

input_selection <- data.frame(
  candidate_panel = c(
    "data/processed/us_s31i/us_s31i_candidate_audit_panel.csv",
    "data/processed/us_s32c/us_s32c_candidate_panel.csv",
    "data/releases/chapter2_us_source_of_truth_v1_1_candidate/CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_WIDE.csv"
  ),
  status = c("PRIMARY_USED", "SECONDARY_DIAGNOSTIC_MERGED", "DISCOVERED_NOT_PRIMARY"),
  reason = c(
    "Broadest current non-estimator Chapter 2 candidate menu: y_t, K_cap, ME/NRC, distribution, q paths, frontier conditioners.",
    "Newer but narrower corporate-boundary robustness candidate panel; S32C-only columns are added without overwriting S31I.",
    "Release candidate source-of-truth panel; does not carry the full S31I q/composition menu needed for S34."
  ),
  stringsAsFactors = FALSE
)
write_csv(input_selection, output_paths[["input_selection"]])

vars_admissible <- integration_ledger$variable_name[
  integration_ledger$classification == "I1"
]
vars_bounded <- integration_ledger$variable_name[
  integration_ledger$classification == "BOUNDED_PERSISTENT"
]
vars_i2 <- integration_ledger$variable_name[
  integration_ledger$classification == "I2_RISK"
]
blocked_interactions <- interaction_ledger[
  interaction_ledger$classification == "BLOCK_STANDARD_I2_RISK", ,
  drop = FALSE
]
plausible_paths <- interaction_ledger[
  interaction_ledger$object_type == "accumulated_weighted_path" &
    interaction_ledger$classification == "AUTHORIZE_STANDARD_IF_I1", ,
  drop = FALSE
]
plausible_relations <- relation_ledger[
  relation_ledger$visual_status %in% c("visually_plausible", "mixed_visual_support"),
  ,
  drop = FALSE
]
unsupported_relations <- relation_ledger[
  relation_ledger$visual_status == "weak_visual_support", ,
  drop = FALSE
]
fragile_designs <- collinearity_ledger[
  grepl("fragile|rank_deficient", collinearity_ledger$notes, ignore.case = TRUE) |
    collinearity_ledger$rank_status != "full_rank",
  ,
  drop = FALSE
]

final_decision <- if (nrow(blocked_interactions) > 0L || length(vars_i2) > 0L) {
  "BLOCK_ESTIMATOR_REFREEZE_PENDING_I2_RISK_REVIEW"
} else if (
  any(integration_ledger$classification %in% c("AMBIGUOUS", "BOUNDED_PERSISTENT")) ||
    nrow(fragile_designs) > 0L
) {
  "HOLD_FOR_VARIABLE_REVIEW"
} else {
  "AUTHORIZE_S35_ESTIMATOR_REFREEZE_PREP"
}

memo_lines <- c(
  "# S34 Pre-regression variable-menu admissibility memo",
  "",
  "## 1. Data panel used",
  "",
  paste(
    "S34 uses `data/processed/us_s31i/us_s31i_candidate_audit_panel.csv`",
    "as the primary panel because it is the latest broad non-estimator",
    "candidate menu containing output, capacity capital, ME/NRC components,",
    "distribution states, q paths, mechanization candidates, and frontier",
    "conditioners. `data/processed/us_s32c/us_s32c_candidate_panel.csv` is",
    "newer but narrower and tied to a corporate-boundary robustness pass;",
    "S34 imports only S32C-only columns as secondary diagnostic variables.",
    "The v1.1 release candidate is discovered but not used as primary",
    "because it does not contain the full S31I q/composition menu."
  ),
  "",
  "## 2. Variables inspected",
  "",
  paste0("- Inspected variables: ", paste(candidate_variables, collapse = ", ")),
  "",
  "## 3. Standard cointegration-screen candidates",
  "",
  if (length(vars_admissible)) paste0("- `", vars_admissible, "`") else "- None.",
  "",
  "## 4. Bounded-persistent variables",
  "",
  if (length(vars_bounded)) paste0("- `", vars_bounded, "`") else "- None.",
  "",
  paste(
    "Bounded shares and ratios are not mechanically promoted to pure I(1)",
    "objects. Their persistence is recorded as an admissibility problem",
    "rather than as a standard long-run level license."
  ),
  "",
  "## 5. Blocked standard interactions",
  "",
  md_table(blocked_interactions, c("object_id", "variables_used", "classification", "notes")),
  "",
  "## 6. Plausible accumulated paths",
  "",
  md_table(plausible_paths, c("object_id", "classification", "notes")),
  "",
  "## 7. Visually plausible level relations",
  "",
  md_table(plausible_relations, c("relation_id", "lhs", "rhs_set", "visual_status", "integration_compatibility")),
  "",
  "## 8. Theoretical relations not visually supported",
  "",
  md_table(unsupported_relations, c("relation_id", "lhs", "rhs_set", "theoretical_status", "visual_status", "notes")),
  "",
  "## 9. Collinearity warnings",
  "",
  md_table(fragile_designs, c("design_id", "regressors", "condition_number", "pairwise_correlation_max", "rank_status", "notes")),
  "",
  "## 10. Recommended next repo layer",
  "",
  paste(
    "The next layer should be an S35 variable-review and estimator-refreeze",
    "prep gate that reviews S34 classifications, resolves I(2)-risk and",
    "bounded-persistent candidates, then freezes a smaller estimator menu.",
    "It should not start from the raw interaction grid."
  ),
  "",
  "## Explicit refreeze answer",
  "",
  paste(
    "Should the next move be an estimator refreeze? No. The next move is to",
    "use S34 as a pre-regression admissibility gate. Estimator refreeze",
    "should only occur after the integration-order, interaction-risk,",
    "visual-plausibility, and design-collinearity ledgers are reviewed."
  ),
  "",
  "## Final decision",
  "",
  paste0("`", final_decision, "`")
)
writeLines(memo_lines, output_paths[["memo"]], useBytes = TRUE)

input_hashes_after <- tools::md5sum(input_paths)
plots_by_dir <- vapply(plot_dirs, function(path) {
  length(list.files(path, pattern = "\\.png$", recursive = FALSE))
}, integer(1L))
checks <- rbind(
  validation_row(
    "S34_OUTPUTS_CREATED",
    if (all(file.exists(output_paths[c(
      "integration_ledger", "interaction_ledger", "relation_ledger",
      "collinearity_ledger", "memo", "input_selection"
    )]))) "PASS" else "FAIL",
    paste(names(output_paths), file.exists(output_paths), collapse = "; ")
  ),
  validation_row(
    "S34_LEDGER_NONEMPTY",
    if (nrow(integration_ledger) > 0L) "PASS" else "FAIL",
    paste(nrow(integration_ledger), "variable rows")
  ),
  validation_row(
    "S34_PLOTS_CREATED",
    if (sum(plots_by_dir) > 0L && all(plots_by_dir > 0L)) "PASS" else "FAIL",
    paste(names(plots_by_dir), plots_by_dir, collapse = "; ")
  ),
  validation_row(
    "S34_MEMO_CREATED",
    if (file.exists(output_paths[["memo"]])) "PASS" else "FAIL",
    output_paths[["memo"]]
  ),
  validation_row(
    "S34_INTERACTION_RISK_LEDGER_CREATED",
    if (file.exists(output_paths[["interaction_ledger"]]) &&
        nrow(interaction_ledger) > 0L) "PASS" else "FAIL",
    paste(nrow(interaction_ledger), "interaction/path rows")
  ),
  validation_row(
    "S34_CANDIDATE_RELATION_LEDGER_CREATED",
    if (file.exists(output_paths[["relation_ledger"]]) &&
        nrow(relation_ledger) > 0L) "PASS" else "FAIL",
    paste(nrow(relation_ledger), "relation rows")
  ),
  validation_row(
    "S34_NO_LOCKED_INPUTS_MODIFIED",
    if (identical(input_hashes_before, input_hashes_after)) "PASS" else "FAIL",
    paste(length(input_paths), "locked/discovered input hashes compared")
  ),
  validation_row(
    "S34_FINAL_DECISION",
    "INFO",
    final_decision
  )
)
write_csv(checks, output_paths[["validation"]])

checks$details[checks$check_id == "S34_OUTPUTS_CREATED"] <- paste(
  names(output_paths), file.exists(output_paths), collapse = "; "
)
write_csv(checks, output_paths[["validation"]])

if (any(checks$status == "FAIL")) {
  abort(paste(
    "S34 validation failed:",
    paste(checks$check_id[checks$status == "FAIL"], collapse = "; ")
  ))
}

message("S34 pre-regression variable-menu report completed.")
message("Variables inspected: ", nrow(integration_ledger))
message("Interaction/path rows: ", nrow(interaction_ledger))
message("Relation rows: ", nrow(relation_ledger))
message("Plots created: ", sum(plots_by_dir))
message("Final decision: ", final_decision)
