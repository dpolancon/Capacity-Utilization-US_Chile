#!/usr/bin/env Rscript

# S35 reviews S34's admissibility gates and freezes no estimator. It runs
# design-matrix diagnostics only: no FM-OLS, DOLS, IM-OLS, VECM, or final model.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir <- file.path(repo_root, "output", "S35_specification_review")

input_paths <- c(
  s34_integration = file.path(
    repo_root, "output", "S34_pre_regression",
    "us_s34_variable_menu_integration_ledger.csv"
  ),
  s34_interaction = file.path(
    repo_root, "output", "S34_pre_regression",
    "us_s34_interaction_i2_risk_ledger.csv"
  ),
  s34_relation = file.path(
    repo_root, "output", "S34_pre_regression",
    "us_s34_candidate_level_relation_ledger.csv"
  ),
  s34_design = file.path(
    repo_root, "output", "S34_pre_regression",
    "us_s34_collinearity_design_ledger.csv"
  ),
  s34_memo = file.path(
    repo_root, "output", "S34_pre_regression",
    "us_s34_pre_regression_admissibility_memo.md"
  ),
  s31i_panel = file.path(
    repo_root, "data", "processed", "us_s31i",
    "us_s31i_candidate_audit_panel.csv"
  )
)

output_paths <- c(
  review = file.path(out_dir, "us_s35_specification_review_ledger.csv"),
  design = file.path(out_dir, "us_s35_design_diagnostics_ledger.csv"),
  menu = file.path(out_dir, "us_s35_estimator_menu_candidate_ledger.csv"),
  memo = file.path(out_dir, "us_s35_specification_review_memo.md"),
  validation = file.path(out_dir, "us_s35_validation_checks.csv")
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
collapse_unique <- function(x, sep = "; ") {
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (length(x)) paste(x, collapse = sep) else ""
}
fmt <- function(x, digits = 4L) {
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
    if (is.numeric(x)) fmt(x) else {
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
validation_row <- function(check_id, status, details) {
  data.frame(check_id = check_id, status = status, details = details,
             stringsAsFactors = FALSE)
}

missing_inputs <- input_paths[!file.exists(input_paths)]
require_condition(
  !length(missing_inputs),
  paste("Missing S35 inputs:", paste(missing_inputs, collapse = "\n"))
)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
input_hashes_before <- tools::md5sum(input_paths)

s34_integration <- read_csv(input_paths[["s34_integration"]])
s34_interaction <- read_csv(input_paths[["s34_interaction"]])
s34_relation <- read_csv(input_paths[["s34_relation"]])
s34_design <- read_csv(input_paths[["s34_design"]])
panel <- read_csv(input_paths[["s31i_panel"]])
panel <- panel[order(panel$year), ]

lag_by_year <- function(x, year, lag_count = 1L) x[match(year - lag_count, year)]
weighted_path <- function(state, change, year) {
  increment <- lag_by_year(as_num(state), year, 1L) * as_num(change)
  result <- rep(NA_real_, length(increment))
  usable <- which(is.finite(increment))
  if (!length(usable)) return(result)
  blocks <- split(usable, cumsum(c(TRUE, diff(usable) != 1L)))
  block <- blocks[[which.max(vapply(blocks, length, integer(1L)))]]
  result[block] <- cumsum(increment[block])
  result
}

panel$Q_omega <- panel$q_omega_h1_Kcap
panel$Q_MEshare <- weighted_path(panel$ME_share, panel$g_Kcap, panel$year)
panel$q_proxy_mechanization_growth <- panel$g_ME_minus_NRC
panel$Q_q <- weighted_path(panel$q_proxy_mechanization_growth, panel$g_Kcap, panel$year)
panel$Q_Ishare <- NA_real_

classification_of <- function(variable) {
  hit <- s34_integration[
    s34_integration$variable_name == variable, "classification"
  ]
  if (length(hit)) hit[1L] else "NOT_CONSTRUCTED"
}
interaction_status_of <- function(object_id) {
  hit <- s34_interaction[
    s34_interaction$object_id == object_id, "classification"
  ]
  if (length(hit)) hit[1L] else "NOT_ASSESSED"
}
relation_status_of <- function(relation_id) {
  hit <- s34_relation[s34_relation$relation_id == relation_id, , drop = FALSE]
  if (nrow(hit)) {
    paste(hit$visual_status[1L], hit$integration_compatibility[1L], sep = "; ")
  } else {
    "not_assessed"
  }
}

design_specs <- list(
  S35_DES_KCAP_QMESHARE = c("k_Kcap", "Q_MEshare"),
  S35_DES_KCAP_QMESHARE_OMEGA = c("k_Kcap", "Q_MEshare", "omega_NFC"),
  S35_DES_KCAP_QOMEGA = c("k_Kcap", "Q_omega"),
  S35_DES_KCAP_QOMEGA_OMEGA = c("k_Kcap", "Q_omega", "omega_NFC"),
  S35_DES_KCAP_QQ = c("k_Kcap", "Q_q"),
  S35_DES_KCAP_QMESHARE_QOMEGA = c("k_Kcap", "Q_MEshare", "Q_omega"),
  S35_DES_KCAP_QMESHARE_QOMEGA_OMEGA = c(
    "k_Kcap", "Q_MEshare", "Q_omega", "omega_NFC"
  ),
  S35_DES_KME_KNRC = c("k_ME", "k_NRC")
)

diagnose_design <- function(design_id, vars) {
  if (!all(vars %in% names(panel))) {
    return(data.frame(
      design_id = design_id,
      variables = paste(vars, collapse = " + "),
      n_obs = 0L,
      condition_number = NA_real_,
      pairwise_correlation_max = NA_real_,
      max_vif_from_correlation_inverse = NA_real_,
      rank_status = "missing_variable",
      collinearity_status = "BLOCKED_MISSING_VARIABLE",
      notes = paste("Missing:", paste(setdiff(vars, names(panel)), collapse = ", ")),
      stringsAsFactors = FALSE
    ))
  }
  data <- panel[, vars, drop = FALSE]
  data[] <- lapply(data, as_num)
  data <- data[stats::complete.cases(data), , drop = FALSE]
  if (nrow(data) < length(vars) + 5L) {
    return(data.frame(
      design_id = design_id,
      variables = paste(vars, collapse = " + "),
      n_obs = nrow(data),
      condition_number = NA_real_,
      pairwise_correlation_max = NA_real_,
      max_vif_from_correlation_inverse = NA_real_,
      rank_status = "insufficient_complete_cases",
      collinearity_status = "BLOCKED_INSUFFICIENT_SAMPLE",
      notes = "Too few complete observations for design diagnostics.",
      stringsAsFactors = FALSE
    ))
  }
  x <- scale(as.matrix(data))
  cond <- tryCatch(kappa(x, exact = TRUE), error = function(e) NA_real_)
  corr <- suppressWarnings(stats::cor(x))
  max_corr <- if (ncol(corr) > 1L) {
    max(abs(corr[upper.tri(corr)]), na.rm = TRUE)
  } else {
    NA_real_
  }
  inv_corr <- tryCatch(solve(corr), error = function(e) NULL)
  max_vif <- if (is.null(inv_corr)) NA_real_ else max(diag(inv_corr), na.rm = TRUE)
  rank_status <- if (qr(x)$rank == ncol(x)) "full_rank" else "rank_deficient"
  col_status <- if (rank_status != "full_rank") {
    "BLOCKED_RANK_DEFICIENT"
  } else if (is.finite(max_corr) && max_corr >= 0.999) {
    "FRAGILE_NEAR_PERFECT_COLLINEARITY"
  } else if (is.finite(cond) && cond >= 30) {
    "FRAGILE_HIGH_CONDITION_NUMBER"
  } else if (is.finite(max_corr) && max_corr >= 0.95) {
    "FRAGILE_HIGH_PAIRWISE_CORRELATION"
  } else {
    "PASS_DESIGN_DIAGNOSTIC"
  }
  notes <- switch(
    col_status,
    FRAGILE_NEAR_PERFECT_COLLINEARITY =
      "Near-perfect pairwise collinearity; do not use as main menu without redesign.",
    FRAGILE_HIGH_CONDITION_NUMBER =
      "Full rank but high condition number; estimator refreeze prep must review.",
    FRAGILE_HIGH_PAIRWISE_CORRELATION =
      "Full rank but pairwise correlation is too high for an unqualified main design.",
    PASS_DESIGN_DIAGNOSTIC =
      "Design diagnostic passes basic collinearity thresholds.",
    BLOCKED_RANK_DEFICIENT = "Design matrix is rank deficient.",
    "Design diagnostic failed."
  )
  data.frame(
    design_id = design_id,
    variables = paste(vars, collapse = " + "),
    n_obs = nrow(data),
    condition_number = cond,
    pairwise_correlation_max = max_corr,
    max_vif_from_correlation_inverse = max_vif,
    rank_status = rank_status,
    collinearity_status = col_status,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

design_ledger <- do.call(rbind, Map(diagnose_design, names(design_specs), design_specs))
write_csv(design_ledger, output_paths[["design"]])

design_status_of <- function(design_id) {
  hit <- design_ledger[design_ledger$design_id == design_id, , drop = FALSE]
  if (nrow(hit)) hit$collinearity_status[1L] else "NOT_DIAGNOSED"
}
design_notes_of <- function(design_id) {
  hit <- design_ledger[design_ledger$design_id == design_id, , drop = FALSE]
  if (nrow(hit)) {
    paste0(
      "condition_number=", fmt(hit$condition_number[1L], 5L),
      "; max_pairwise_corr=", fmt(hit$pairwise_correlation_max[1L], 5L),
      "; ", hit$notes[1L]
    )
  } else {
    ""
  }
}

review_rows <- list()
add_review <- function(spec_id, formula_text, specification_role,
                       theta_recovery_status, accumulation_channel,
                       ovb_control_status, integration_gate,
                       interaction_gate, design_gate, s35_status, notes) {
  review_rows[[length(review_rows) + 1L]] <<- data.frame(
    spec_id = spec_id,
    formula = formula_text,
    specification_role = specification_role,
    theta_recovery_status = theta_recovery_status,
    accumulation_channel = accumulation_channel,
    ovb_control_status = ovb_control_status,
    integration_gate = integration_gate,
    interaction_gate = interaction_gate,
    design_gate = design_gate,
    s35_status = s35_status,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

add_review(
  "S35_CORE_MECH_COMP_OVB",
  "y_t = alpha + beta k_Kcap + gamma Q_MEshare + delta omega_NFC + e_t",
  "preferred_theoretical_candidate",
  "theta_t = beta + gamma s_ME_{t-1}; omega_NFC is not theta recovery",
  "mechanization_composition_accumulation",
  "bounded_persistent_OVB_control",
  paste(
    "y_t", classification_of("y_t"),
    "k_Kcap", classification_of("k_Kcap"),
    "Q_MEshare", classification_of("Q_MEshare"),
    "omega_NFC", classification_of("omega_NFC")
  ),
  "NO_RAW_INTERACTION; omega_NFC enters only as bounded-persistent control",
  design_status_of("S35_DES_KCAP_QMESHARE_OMEGA"),
  "HOLD_FOR_DESIGN_REVIEW",
  design_notes_of("S35_DES_KCAP_QMESHARE_OMEGA")
)
add_review(
  "S35_MECH_COMP_PATH",
  "y_t = alpha + beta k_Kcap + gamma Q_MEshare + e_t",
  "theta_recovery_candidate",
  "theta_t = beta + gamma s_ME_{t-1}",
  "mechanization_composition_accumulation",
  "none",
  paste(
    "y_t", classification_of("y_t"),
    "k_Kcap", classification_of("k_Kcap"),
    "Q_MEshare", classification_of("Q_MEshare")
  ),
  interaction_status_of("Q_MEshare"),
  design_status_of("S35_DES_KCAP_QMESHARE"),
  "HOLD_FOR_DESIGN_REVIEW",
  design_notes_of("S35_DES_KCAP_QMESHARE")
)
add_review(
  "S35_DIST_ACCUM_PATH",
  "y_t = alpha + beta k_Kcap + gamma Q_omega + e_t",
  "reduced_form_distribution_robustness",
  "theta_t = beta + gamma omega_{t-1}; reduced form, not mechanization composition",
  "distribution_conditioned_accumulation",
  "none",
  paste(
    "y_t", classification_of("y_t"),
    "k_Kcap", classification_of("k_Kcap"),
    "Q_omega", classification_of("Q_omega")
  ),
  interaction_status_of("Q_omega"),
  design_status_of("S35_DES_KCAP_QOMEGA"),
  "DIAGNOSTIC_ONLY",
  paste("Q_omega is admissible by integration but too collinear for main menu.",
        design_notes_of("S35_DES_KCAP_QOMEGA"))
)
add_review(
  "S35_DIST_ACCUM_OVB",
  "y_t = alpha + beta k_Kcap + gamma Q_omega + delta omega_NFC + e_t",
  "reduced_form_distribution_robustness_with_control",
  "theta_t = beta + gamma omega_{t-1}; delta omega_NFC is OVB control",
  "distribution_conditioned_accumulation",
  "bounded_persistent_OVB_control_with_double_counting_risk",
  paste(
    "y_t", classification_of("y_t"),
    "k_Kcap", classification_of("k_Kcap"),
    "Q_omega", classification_of("Q_omega"),
    "omega_NFC", classification_of("omega_NFC")
  ),
  "NO_RAW_INTERACTION; DOUBLE_COUNTS_DISTRIBUTION_RISK",
  design_status_of("S35_DES_KCAP_QOMEGA_OMEGA"),
  "DIAGNOSTIC_ONLY",
  paste("Retain only as reduced-form robustness, not main menu.",
        design_notes_of("S35_DES_KCAP_QOMEGA_OMEGA"))
)
add_review(
  "S35_OBS_Q_PATH",
  "y_t = alpha + beta k_Kcap + gamma Q_q + e_t",
  "observed_q_recovery_candidate",
  "parked; Q_q would imply theta_t = beta + gamma q_{t-1}",
  "observed_q_weighted_accumulation",
  "none",
  paste(
    "y_t", classification_of("y_t"),
    "k_Kcap", classification_of("k_Kcap"),
    "Q_q", classification_of("Q_q")
  ),
  interaction_status_of("Q_q"),
  design_status_of("S35_DES_KCAP_QQ"),
  "BLOCK_STANDARD_GRID_PENDING_I2_REVIEW",
  "Observed q recovery remains blocked because S34 classifies Q_q as I2_RISK."
)
add_review(
  "S35_RAW_K_OMEGA",
  "y_t = alpha + beta k_Kcap + gamma (k_Kcap * omega_NFC) + e_t",
  "blocked_raw_interaction",
  "blocked; raw interaction is not preferred theta recovery",
  "none",
  "none",
  paste("k_Kcap", classification_of("k_Kcap"),
        "omega_NFC", classification_of("omega_NFC")),
  interaction_status_of("k_cap_times_wage_share"),
  "not_diagnosed_because_blocked",
  "BLOCK_STANDARD_GRID_PENDING_I2_REVIEW",
  "Raw k*omega is blocked by S34 and contradicts the accumulated-path hierarchy."
)
add_review(
  "S35_RAW_K_Q",
  "y_t = alpha + beta k_Kcap + gamma (k_Kcap * q_t) + e_t",
  "blocked_raw_interaction",
  "blocked; raw interaction is not preferred theta recovery",
  "none",
  "none",
  paste("k_Kcap", classification_of("k_Kcap"),
        "q_omega_h1_Kcap", classification_of("q_omega_h1_Kcap")),
  interaction_status_of("k_cap_times_q"),
  "not_diagnosed_because_blocked",
  "BLOCK_STANDARD_GRID_PENDING_I2_REVIEW",
  "Raw k*q is blocked by S34; route nonlinear mechanization outside standard grid."
)
add_review(
  "S35_Q_SQUARED",
  "a_t = lambda_0 + lambda_1 q_t + lambda_2 q_t^2 + e_t",
  "nonlinear_mechanization_experiment",
  "does not recover theta_t inside the standard capacity equation",
  "nonlinear_technique_choice",
  "none",
  paste("q_omega_h1_Kcap", classification_of("q_omega_h1_Kcap")),
  interaction_status_of("q_squared"),
  "not_diagnosed_because_cpr_only",
  "ROUTE_NONLINEAR_MECHANIZATION_TO_CPR",
  "Quadratic q is CPR/polynomial-only unless a stationary q object is found."
)
add_review(
  "S35_Q_OMEGA_RAW",
  "q_t = alpha + eta omega_NFC + e_t, or raw q_t * omega_NFC extension",
  "technique_choice_diagnostic",
  "upstream q-star relation, not direct theta recovery",
  "technique_choice_state",
  "none",
  relation_status_of("REL_q_omega"),
  interaction_status_of("q_times_wage_share"),
  "not_main_capacity_design",
  "DIAGNOSTIC_ONLY",
  "S34 visual support for q_proxy_mechanization_growth vs omega_NFC is weak."
)

review_ledger <- do.call(rbind, review_rows)
write_csv(review_ledger, output_paths[["review"]])

menu_rows <- list()
add_menu <- function(spec_id, menu_tier, standard_grid_status,
                     estimator_refreeze_prep_status, reason) {
  row <- review_ledger[review_ledger$spec_id == spec_id, , drop = FALSE]
  menu_rows[[length(menu_rows) + 1L]] <<- data.frame(
    spec_id = spec_id,
    formula = if (nrow(row)) row$formula[1L] else "",
    menu_tier = menu_tier,
    standard_grid_status = standard_grid_status,
    estimator_refreeze_prep_status = estimator_refreeze_prep_status,
    reason = reason,
    stringsAsFactors = FALSE
  )
}
add_menu(
  "S35_CORE_MECH_COMP_OVB", "candidate_main_after_design_review",
  "not_authorized_yet", "hold",
  "Theoretically leading, but k_Kcap and Q_MEshare remain highly collinear; omega_NFC is bounded-persistent OVB control."
)
add_menu(
  "S35_MECH_COMP_PATH", "candidate_nested_baseline_after_design_review",
  "not_authorized_yet", "hold",
  "Cleaner theta-recovery path than OVB version, but still fails basic design fragility threshold."
)
add_menu(
  "S35_DIST_ACCUM_PATH", "reduced_form_robustness_only",
  "diagnostic_or_robustness_only", "do_not_refreeze_as_main",
  "Q_omega is I(1) but nearly perfectly collinear with k_Kcap and is distribution-conditioned, not direct mechanization composition."
)
add_menu(
  "S35_DIST_ACCUM_OVB", "reduced_form_robustness_only",
  "diagnostic_only", "do_not_refreeze_as_main",
  "Adds bounded omega_NFC to a path already weighted by omega_NFC; double-counting risk plus near-singular design."
)
add_menu(
  "S35_OBS_Q_PATH", "parked_observed_q_recovery",
  "blocked_standard_grid", "do_not_refreeze",
  "Q_q remains I2_RISK; observed-q recovery is parked until a better q proxy is authorized."
)
add_menu(
  "S35_RAW_K_OMEGA", "blocked_raw_interaction",
  "blocked_standard_grid", "do_not_refreeze",
  "Raw level interaction is blocked by S34."
)
add_menu(
  "S35_RAW_K_Q", "blocked_raw_interaction",
  "blocked_standard_grid", "do_not_refreeze",
  "Raw k*q is blocked by S34."
)
add_menu(
  "S35_Q_SQUARED", "cpr_polynomial_only",
  "route_to_CPR", "do_not_refreeze",
  "Nonlinear mechanization through q^2 requires CPR/polynomial treatment."
)
add_menu(
  "S35_Q_OMEGA_RAW", "upstream_diagnostic_only",
  "diagnostic_only", "do_not_refreeze_as_capacity_spec",
  "Technique-choice screen is upstream and visually weak in S34."
)
menu_ledger <- do.call(rbind, menu_rows)
write_csv(menu_ledger, output_paths[["menu"]])

remaining_i2_dependency <- any(review_ledger$s35_status == "BLOCK_STANDARD_GRID_PENDING_I2_REVIEW")
main_design_hold <- any(review_ledger$spec_id %in% c(
  "S35_CORE_MECH_COMP_OVB", "S35_MECH_COMP_PATH"
) & review_ledger$s35_status == "HOLD_FOR_DESIGN_REVIEW")
cpr_only_needed <- all(menu_ledger$standard_grid_status %in% c(
  "route_to_CPR", "blocked_standard_grid", "diagnostic_only"
))

final_decision <- if (main_design_hold) {
  "HOLD_FOR_DESIGN_REVIEW"
} else if (remaining_i2_dependency) {
  "BLOCK_STANDARD_GRID_PENDING_I2_REVIEW"
} else if (cpr_only_needed) {
  "ROUTE_NONLINEAR_MECHANIZATION_TO_CPR"
} else {
  "AUTHORIZE_ESTIMATOR_REFREEZE_PREP"
}

answer <- function(question, verdict) {
  paste0("- **", question, "** ", verdict)
}
locked_sentence <- paste(
  "Include omega_t not to recover theta_t directly, but to prevent the",
  "mechanization-composition path Q^{MEshare}_t from absorbing omitted",
  "distributional-state effects. The recovered theta_t remains tied to",
  "accumulated composition-conditioned capacity building, while omega_t",
  "enters as a bounded-persistent OVB-control and second-order",
  "distributional state term."
)

main_designs <- design_ledger[design_ledger$design_id %in% c(
  "S35_DES_KCAP_QMESHARE", "S35_DES_KCAP_QMESHARE_OMEGA",
  "S35_DES_KCAP_QOMEGA", "S35_DES_KCAP_QOMEGA_OMEGA"
), , drop = FALSE]

memo_lines <- c(
  "# S35 Specification Review and Estimator-Refreeze Prep Gate",
  "",
  "## Purpose",
  "",
  paste(
    "S35 reviews S34 admissibility results and freezes no estimator. It",
    "distinguishes theta-recovery specifications, OVB-control terms,",
    "distribution-conditioned accumulation, mechanization-composition",
    "accumulation, blocked raw interactions, and CPR-only experiments."
  ),
  "",
  "## S34 locks consumed",
  "",
  "- `Q_omega` is I(1) and authorized standard-if-I(1), but design-fragile.",
  "- `Q_MEshare` is I(1) and authorized standard-if-I(1), but must pass S35 design review.",
  "- `Q_q` remains blocked for I(2) risk.",
  "- `omega_NFC` and `ME_share` are bounded-persistent states, not clean pure I(1) trend objects.",
  "- Raw `k_Kcap * omega_NFC`, raw `k_Kcap * q`, `q^2`, and raw `q * omega_NFC` are blocked from the standard grid.",
  "",
  "## Locked interpretation",
  "",
  locked_sentence,
  "",
  "## Required S35 answers",
  "",
  answer(
    "Is `Q_MEshare` admissible when paired with `k_Kcap`?",
    paste(
      "Integration says yes, but design says hold:",
      design_notes_of("S35_DES_KCAP_QMESHARE")
    )
  ),
  answer(
    "Is `Q_MEshare + omega_NFC` admissible as mechanization path plus OVB-control?",
    paste(
      "Only conceptually. The design remains fragile:",
      design_notes_of("S35_DES_KCAP_QMESHARE_OMEGA")
    )
  ),
  answer(
    "Is `Q_omega` too collinear with `k_Kcap` to remain in the main estimator menu?",
    paste("Yes.", design_notes_of("S35_DES_KCAP_QOMEGA"))
  ),
  answer(
    "Should `Q_omega` be retained only as reduced-form distribution-conditioned robustness path?",
    "Yes. It is distribution-conditioned accumulation, not direct mechanization composition."
  ),
  answer(
    "Should `Q_q` remain blocked?",
    "Yes. S34 classifies `Q_q` as `I2_RISK`, so it remains outside the standard grid."
  ),
  answer(
    "Is there a better observed q proxy available, or should observed-q recovery be parked?",
    "No better authorized observed q proxy is present in the S34/S31I menu; observed-q recovery is parked."
  ),
  answer(
    "Which candidate specifications are standard-grid admissible?",
    "None are authorized for immediate estimator refreeze. `Q_MEshare` specifications are theoretically preferred but held for design review."
  ),
  answer(
    "Which candidate specifications must be diagnostic-only?",
    "`Q_omega` reduced-form paths, `Q_omega + omega_NFC`, and upstream q-omega screens."
  ),
  answer(
    "Which require CPR/polynomial treatment?",
    "Raw `k*q`, raw `k*omega`, raw `q*omega`, and `q^2` remain outside the standard grid; nonlinear q work routes to CPR."
  ),
  "",
  "## Main Design Diagnostics",
  "",
  md_table(
    main_designs,
    c(
      "design_id", "variables", "n_obs", "condition_number",
      "pairwise_correlation_max", "max_vif_from_correlation_inverse",
      "collinearity_status"
    )
  ),
  "",
  "## Specification Review Ledger",
  "",
  md_table(
    review_ledger,
    c(
      "spec_id", "specification_role", "theta_recovery_status",
      "accumulation_channel", "ovb_control_status", "s35_status"
    )
  ),
  "",
  "## Estimator Menu Candidate Ledger",
  "",
  md_table(
    menu_ledger,
    c(
      "spec_id", "menu_tier", "standard_grid_status",
      "estimator_refreeze_prep_status", "reason"
    )
  ),
  "",
  "## Final Decision",
  "",
  paste0("`", final_decision, "`"),
  "",
  "Estimator refreeze should not begin from this layer. The next move is a targeted design review of the mechanization-composition path, especially whether `Q_MEshare` can be orthogonalized, periodized, indexed, or otherwise represented without collapsing into `k_Kcap`."
)
writeLines(memo_lines, output_paths[["memo"]], useBytes = TRUE)

input_hashes_after <- tools::md5sum(input_paths)
checks <- rbind(
  validation_row(
    "S35_OUTPUTS_CREATED",
    if (all(file.exists(output_paths[c("review", "design", "menu", "memo")]))) "PASS" else "FAIL",
    paste(names(output_paths), file.exists(output_paths), collapse = "; ")
  ),
  validation_row(
    "S35_SPEC_REVIEW_LEDGER_NONEMPTY",
    if (nrow(review_ledger) > 0L) "PASS" else "FAIL",
    paste(nrow(review_ledger), "specification rows")
  ),
  validation_row(
    "S35_DESIGN_DIAGNOSTICS_INCLUDE_QMESHARE",
    if (all(c(
      "S35_DES_KCAP_QMESHARE", "S35_DES_KCAP_QMESHARE_OMEGA"
    ) %in% design_ledger$design_id)) "PASS" else "FAIL",
    "Required Q_MEshare designs are diagnosed."
  ),
  validation_row(
    "S35_MENU_LEDGER_NONEMPTY",
    if (nrow(menu_ledger) > 0L) "PASS" else "FAIL",
    paste(nrow(menu_ledger), "menu rows")
  ),
  validation_row(
    "S35_NO_FINAL_ESTIMATION",
    "PASS",
    "No FM-OLS, DOLS, IM-OLS, VECM, Johansen, or final long-run estimator is called."
  ),
  validation_row(
    "S35_NO_LOCKED_INPUTS_MODIFIED",
    if (identical(input_hashes_before, input_hashes_after)) "PASS" else "FAIL",
    paste(length(input_paths), "input hashes compared")
  ),
  validation_row(
    "S35_FINAL_DECISION",
    "INFO",
    final_decision
  )
)
write_csv(checks, output_paths[["validation"]])
checks$details[checks$check_id == "S35_OUTPUTS_CREATED"] <- paste(
  names(output_paths), file.exists(output_paths), collapse = "; "
)
write_csv(checks, output_paths[["validation"]])

if (any(checks$status == "FAIL")) {
  abort(paste(
    "S35 validation failed:",
    paste(checks$check_id[checks$status == "FAIL"], collapse = "; ")
  ))
}

message("S35 specification review gate completed.")
message("Specification rows: ", nrow(review_ledger))
message("Design rows: ", nrow(design_ledger))
message("Menu rows: ", nrow(menu_ledger))
message("Final decision: ", final_decision)
