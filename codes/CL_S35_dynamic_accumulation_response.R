#!/usr/bin/env Rscript

# S35: regime-specific accumulation responses, conditional on stationarity.

source("C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_SBVECM_common.R")
suppressPackageStartupMessages({
  library(lmtest)
  library(sandwich)
})

panel <- read.csv(sbvecm_dir(
  "data", "processed", "CL", "SBVECM", "cl_capital_1920_2024.csv"
), check.names = FALSE, stringsAsFactors = FALSE)
s25_dir <- sbvecm_dir("output", "CL", "SBVECM",
                      "S25_STATIONARY_ACCUMULATION_BREAKS")
out_dir <- sbvecm_dir("output", "CL", "SBVECM",
                      "S35_DYNAMIC_ACCUMULATION_RESPONSE")
fig_dir <- file.path(out_dir, "figures")
sbvecm_ensure_dir(out_dir)
sbvecm_ensure_dir(fig_dir)

break_ledger <- read.csv(file.path(s25_dir, "short_run_break_ledger.csv"),
                         stringsAsFactors = FALSE)
stationarity <- read.csv(
  file.path(s25_dir, "short_run_stationarity_ledger.csv"),
  stringsAsFactors = FALSE
)
break_intervals <- read.csv(
  file.path(s25_dir, "accumulation_break_intervals.csv"),
  stringsAsFactors = FALSE
)

p <- as.integer(unique(break_ledger$selected_lag)[1])
break_text <- as.character(unique(break_ledger$selected_break_years)[1])
break_years <- if (is.na(break_text) || !nzchar(break_text)) integer() else
  as.integer(strsplit(break_text, ";", fixed = TRUE)[[1]])
stationarity_gate <- nrow(stationarity) == 2L &&
  all(stationarity$integration_order == "I(0)")

growth <- data.frame(
  year = panel$year[-1L],
  d_k_NR = diff(panel$k_NR),
  d_k_ME = diff(panel$k_ME),
  stringsAsFactors = FALSE
)
lag_vector <- function(x, lag) c(rep(NA_real_, lag), head(x, -lag))
if (p > 0L) {
  for (lag in 1:p) {
    growth[[paste0("L", lag, "_d_k_NR")]] <- lag_vector(growth$d_k_NR, lag)
    growth[[paste0("L", lag, "_d_k_ME")]] <- lag_vector(growth$d_k_ME, lag)
  }
}
growth <- growth[complete.cases(growth), , drop = FALSE]

main_break <- if (length(break_years)) break_years[1] else NA_integer_
growth$period <- if (is.finite(main_break)) {
  ifelse(growth$year > main_break, "After break", "Before break")
} else {
  rep("Before break", nrow(growth))
}
growth$period <- factor(growth$period, levels = c("Before break", "After break"))

empty_response <- function() {
  starts <- c(min(growth$year),
              if (is.finite(main_break)) main_break + 1L else NA_integer_)
  ends <- c(if (is.finite(main_break)) main_break else max(growth$year),
            max(growth$year))
  keep <- is.finite(starts) & starts <= ends
  data.frame(
    period = paste(starts[keep], ends[keep], sep = "-"),
    N = vapply(seq_along(starts[keep]), function(i)
      sum(growth$year >= starts[keep][i] & growth$year <= ends[keep][i]),
      integer(1)),
    eta_impact = NA_real_,
    eta_impact_ci_low = NA_real_,
    eta_impact_ci_high = NA_real_,
    eta_3year = NA_real_,
    eta_3year_ci_low = NA_real_,
    eta_3year_ci_high = NA_real_,
    adjacent_impact_p = NA_real_,
    adjacent_3year_p = NA_real_,
    inference = "not estimated",
    empirical_verdict =
      "conditional accumulation elasticity not identified: growth-rate stationarity is inconclusive",
    stringsAsFactors = FALSE
  )
}

wald_test <- function(coef, vcov, R, r = rep(0, nrow(R))) {
  difference <- as.numeric(R %*% coef - r)
  middle <- R %*% vcov %*% t(R)
  statistic <- as.numeric(t(difference) %*% solve(middle, difference))
  p <- stats::pchisq(statistic, df = nrow(R), lower.tail = FALSE)
  c(statistic = statistic, df = nrow(R), p_value = p)
}

response_ledger <- empty_response()
adjacent_ledger <- data.frame(
  hypothesis = c("equal impact responses", "equal three-year responses"),
  statistic = NA_real_, df = NA_integer_, p_value = NA_real_,
  status = "not tested: stationarity prerequisite fails",
  stringsAsFactors = FALSE
)
system_ledger <- data.frame(
  diagnostic = c(
    "machinery growth excluded from structures equation",
    "structures growth excluded from machinery equation",
    "structures-equation serial correlation",
    "machinery-equation serial correlation",
    "pre-break companion root",
    "post-break companion root"
  ),
  statistic = NA_real_,
  p_value = NA_real_,
  pass = NA,
  status = "not estimated: stationarity prerequisite fails",
  stringsAsFactors = FALSE
)
fit <- NULL
vc <- NULL

if (stationarity_gate && is.finite(main_break) && p == 1L) {
  post <- as.integer(growth$year > main_break)
  growth$const_pre <- 1 - post
  growth$const_post <- post
  growth$dME_pre <- growth$d_k_ME * (1 - post)
  growth$dME_post <- growth$d_k_ME * post
  growth$L1_dME_pre <- growth$L1_d_k_ME * (1 - post)
  growth$L1_dME_post <- growth$L1_d_k_ME * post
  fit <- lm(
    d_k_NR ~ 0 + const_pre + const_post + L1_d_k_NR +
      dME_pre + dME_post + L1_dME_pre + L1_dME_post,
    data = growth
  )
  vc <- sandwich::NeweyWest(fit, lag = 4L, prewhite = FALSE, adjust = TRUE)
  b <- coef(fit)

  eta_gradient <- function(period) {
    b0_name <- if (period == "pre") "dME_pre" else "dME_post"
    b1_name <- if (period == "pre") "L1_dME_pre" else "L1_dME_post"
    a <- b["L1_d_k_NR"]
    b0 <- b[b0_name]
    b1 <- b[b1_name]
    S <- 1 + a + a^2
    value <- b0 + (a * b0 + b1) * S
    gradient <- setNames(rep(0, length(b)), names(b))
    gradient[b0_name] <- 1 + a * S
    gradient[b1_name] <- S
    gradient["L1_d_k_NR"] <- b0 * S + (a * b0 + b1) * (1 + 2 * a)
    list(value = unname(value), gradient = gradient)
  }

  response_rows <- lapply(c("pre", "post"), function(period) {
    b0_name <- if (period == "pre") "dME_pre" else "dME_post"
    years <- if (period == "pre")
      growth$year[growth$year <= main_break] else
        growth$year[growth$year > main_break]
    impact <- b[b0_name]
    impact_se <- sqrt(vc[b0_name, b0_name])
    eta3 <- eta_gradient(period)
    eta3_se <- sqrt(as.numeric(t(eta3$gradient) %*% vc %*% eta3$gradient))
    data.frame(
      period = paste(min(years), max(years), sep = "-"),
      N = length(years),
      eta_impact = unname(impact),
      eta_impact_ci_low = unname(impact - 1.96 * impact_se),
      eta_impact_ci_high = unname(impact + 1.96 * impact_se),
      eta_3year = eta3$value,
      eta_3year_ci_low = eta3$value - 1.96 * eta3_se,
      eta_3year_ci_high = eta3$value + 1.96 * eta3_se,
      adjacent_impact_p = NA_real_,
      adjacent_3year_p = NA_real_,
      inference = "Newey-West analytic covariance; delta method",
      empirical_verdict = "admissible conditional accumulation response",
      stringsAsFactors = FALSE
    )
  })
  response_ledger <- do.call(rbind, response_rows)

  R_impact <- matrix(0, 1, length(b), dimnames = list(NULL, names(b)))
  R_impact[1, "dME_pre"] <- 1
  R_impact[1, "dME_post"] <- -1
  impact_test <- wald_test(b, vc, R_impact)
  eta_pre <- eta_gradient("pre")
  eta_post <- eta_gradient("post")
  R_eta <- matrix(eta_pre$gradient - eta_post$gradient, nrow = 1)
  colnames(R_eta) <- names(b)
  eta_test <- wald_test(b, vc, R_eta)
  response_ledger$adjacent_impact_p <- impact_test["p_value"]
  response_ledger$adjacent_3year_p <- eta_test["p_value"]
  adjacent_ledger <- data.frame(
    hypothesis = c("equal impact responses", "equal three-year responses"),
    statistic = c(impact_test["statistic"], eta_test["statistic"]),
    df = c(impact_test["df"], eta_test["df"]),
    p_value = c(impact_test["p_value"], eta_test["p_value"]),
    status = "analytic Wald test",
    stringsAsFactors = FALSE
  )

  # System check: a regime-interacted VAR(1) in first differences.
  for (variable in c("L1_d_k_NR", "L1_d_k_ME")) {
    growth[[paste0(variable, "_pre")]] <- growth[[variable]] * (1 - post)
    growth[[paste0(variable, "_post")]] <- growth[[variable]] * post
  }
  system_formula <- ~ 0 + const_pre + const_post +
    L1_d_k_NR_pre + L1_d_k_NR_post +
    L1_d_k_ME_pre + L1_d_k_ME_post
  nr_eq <- lm(update(system_formula, d_k_NR ~ .), data = growth)
  me_eq <- lm(update(system_formula, d_k_ME ~ .), data = growth)
  nr_vc <- sandwich::NeweyWest(nr_eq, lag = 4L, prewhite = FALSE,
                               adjust = TRUE)
  me_vc <- sandwich::NeweyWest(me_eq, lag = 4L, prewhite = FALSE,
                               adjust = TRUE)
  R_me_to_nr <- matrix(0, 2, length(coef(nr_eq)),
                       dimnames = list(NULL, names(coef(nr_eq))))
  R_me_to_nr[1, "L1_d_k_ME_pre"] <- 1
  R_me_to_nr[2, "L1_d_k_ME_post"] <- 1
  R_nr_to_me <- matrix(0, 2, length(coef(me_eq)),
                       dimnames = list(NULL, names(coef(me_eq))))
  R_nr_to_me[1, "L1_d_k_NR_pre"] <- 1
  R_nr_to_me[2, "L1_d_k_NR_post"] <- 1
  granger_forward <- wald_test(coef(nr_eq), nr_vc, R_me_to_nr)
  granger_reverse <- wald_test(coef(me_eq), me_vc, R_nr_to_me)
  bg_nr <- lmtest::bgtest(nr_eq, order = 4)$p.value
  bg_me <- lmtest::bgtest(me_eq, order = 4)$p.value
  A_pre <- rbind(
    c(coef(nr_eq)["L1_d_k_NR_pre"], coef(nr_eq)["L1_d_k_ME_pre"]),
    c(coef(me_eq)["L1_d_k_NR_pre"], coef(me_eq)["L1_d_k_ME_pre"])
  )
  A_post <- rbind(
    c(coef(nr_eq)["L1_d_k_NR_post"], coef(nr_eq)["L1_d_k_ME_post"]),
    c(coef(me_eq)["L1_d_k_NR_post"], coef(me_eq)["L1_d_k_ME_post"])
  )
  root_pre <- max(Mod(eigen(A_pre, only.values = TRUE)$values))
  root_post <- max(Mod(eigen(A_post, only.values = TRUE)$values))
  system_ledger <- data.frame(
    diagnostic = c(
      "machinery growth excluded from structures equation",
      "structures growth excluded from machinery equation",
      "structures-equation serial correlation",
      "machinery-equation serial correlation",
      "pre-break companion root",
      "post-break companion root"
    ),
    statistic = c(
      granger_forward["statistic"], granger_reverse["statistic"],
      NA_real_, NA_real_, root_pre, root_post
    ),
    p_value = c(
      granger_forward["p_value"], granger_reverse["p_value"],
      bg_nr, bg_me, NA_real_, NA_real_
    ),
    pass = c(
      NA, NA, bg_nr >= 0.05, bg_me >= 0.05,
      root_pre < 1, root_post < 1
    ),
    status = "system diagnostic; exclusion tests are not causal identification",
    stringsAsFactors = FALSE
  )
}

write.csv(response_ledger,
          file.path(out_dir, "short_run_elasticity_ledger.csv"),
          row.names = FALSE)
write.csv(adjacent_ledger,
          file.path(out_dir, "short_run_adjacent_tests.csv"),
          row.names = FALSE)
write.csv(system_ledger,
          file.path(out_dir, "short_run_system_ledger.csv"),
          row.names = FALSE)

bootstrap <- data.frame(
  inferential_object = c(
    "impact response",
    "three-year cumulative response",
    "system feedback"
  ),
  bootstrap_required = FALSE,
  replications = 0L,
  reason = if (stationarity_gate) c(
    "full-sample interacted regression has analytic HAC covariance",
    "delta-method covariance is available",
    "full-sample analytic Wald and residual tests are available"
  ) else rep(
    "parameter is not identified, so resampling cannot create admissibility",
    3
  ),
  stringsAsFactors = FALSE
)
write.csv(bootstrap,
          file.path(out_dir, "short_run_bootstrap_necessity_ledger.csv"),
          row.names = FALSE)

# Paper-facing visual evidence. No fitted response line is drawn when the
# stationarity prerequisite fails.
draw_figure <- function(device) {
  if (device == "png") {
    png(file.path(fig_dir, "fig8_accumulation_evidence.png"),
        width = 2600, height = 1250, res = 300)
  } else {
    pdf(file.path(fig_dir, "fig8_accumulation_evidence.pdf"),
        width = 8.7, height = 4.2)
  }
  old_par <- par(no.readonly = TRUE)
  on.exit({
    par(old_par)
    dev.off()
  }, add = TRUE)
  par(mfrow = c(1, 2), mar = c(4.2, 4.3, 2.7, 1.0),
      family = "serif")
  yrange <- range(c(growth$d_k_NR, growth$d_k_ME))
  plot(growth$year, growth$d_k_ME, type = "l", col = "#b2182b",
       lwd = 1.25, xlab = "Year", ylab = "Annual log change",
       ylim = yrange, main = "Observed capital accumulation")
  lines(growth$year, growth$d_k_NR, col = "#2166ac", lwd = 1.25)
  if (is.finite(main_break)) abline(v = main_break, lty = 2, col = "grey35")
  abline(h = 0, col = "grey75")
  legend("topleft", c("Machinery", "Structures", "Dynamic break"),
         col = c("#b2182b", "#2166ac", "grey35"),
         lty = c(1, 1, 2), lwd = c(1.25, 1.25, 1), bty = "n", cex = 0.75)
  cols <- ifelse(growth$period == "Before break", "#4d4d4d", "#d95f02")
  plot(growth$d_k_ME, growth$d_k_NR, pch = 16, cex = 0.65, col = cols,
       xlab = expression(Delta * k[t]^ME),
       ylab = expression(Delta * k[t]^NR),
       main = if (stationarity_gate)
         "Conditional accumulation response" else
           "Observed association; elasticity not identified")
  legend("topleft", levels(growth$period),
         col = c("#4d4d4d", "#d95f02"), pch = 16, bty = "n", cex = 0.75)
}
draw_figure("png")
draw_figure("pdf")

checks <- data.frame(
  check = c(
    "stationarity gate read before estimation",
    "no response reported after failed gate",
    "response distinction from beta_ME",
    "bootstrap necessity",
    "figure contains observed data",
    "system estimate respects stationarity gate"
  ),
  pass = c(
    is.logical(stationarity_gate) && length(stationarity_gate) == 1L,
    stationarity_gate || all(!is.finite(response_ledger$eta_impact)),
    !any(grepl("beta_ME", names(response_ledger), fixed = TRUE)),
    all(!bootstrap$bootstrap_required),
    file.exists(file.path(fig_dir, "fig8_accumulation_evidence.png")),
    stationarity_gate || all(grepl("^not estimated", system_ledger$status))
  ),
  detail = c(
    paste0("stationarity gate=", stationarity_gate),
    paste(unique(response_ledger$empirical_verdict), collapse = ";"),
    "eta notation only",
    "zero replications",
    paste(min(growth$year), max(growth$year), sep = "-"),
    unique(system_ledger$status)[1]
  ),
  stringsAsFactors = FALSE
)
write.csv(checks,
          file.path(out_dir, "short_run_dynamic_integrity_checks.csv"),
          row.names = FALSE)
if (!all(checks$pass)) {
  stop("S35 dynamic-response integrity check failed: ",
       paste(checks$check[!checks$pass], collapse = "; "))
}

message("S35 complete: stationarity gate=", stationarity_gate,
        "; eta estimates reported=", any(is.finite(response_ledger$eta_impact)),
        ".")
