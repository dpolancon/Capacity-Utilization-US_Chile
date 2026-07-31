#!/usr/bin/env Rscript

# S40: compact route-specific I(2) fallback.
# It activates only when a route-specific order ledger retains genuine I(2)-risk.

source("C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_SBVECM_common.R")
suppressPackageStartupMessages(library(urca))

panel <- read.csv(sbvecm_dir("data", "processed", "CL", "SBVECM",
                            "cl_capital_1920_2024.csv"))
s20_dir <- sbvecm_dir("output", "CL", "SBVECM", "S20_DUAL_ROUTE_BREAK_AUDIT")
out_dir <- sbvecm_dir("output", "CL", "SBVECM", "S40_I2_FALLBACK")
sbvecm_ensure_dir(out_dir)

orders <- read.csv(file.path(s20_dir, "route_specific_integration_orders.csv"),
                   stringsAsFactors = FALSE)
break_sets <- read.csv(file.path(s20_dir, "route_break_sets.csv"),
                       stringsAsFactors = FALSE)
X <- as.matrix(panel[c("k_NR", "k_ME")])

parse_breaks <- function(route) {
  x <- break_sets$break_years[break_sets$break_route == route]
  if (!length(x) || x == "NONE") return(integer())
  as.integer(strsplit(x, ";", fixed = TRUE)[[1]])
}

rows <- list()
for (route in c("LOESS", "PARAMETRIC")) {
  z <- orders[orders$break_route == route &
                orders$variable %in% c("k_NR", "k_ME"), ]
  trigger <- nrow(z) == 2L && all(z$integration_order == "I(2)-risk")
  if (!trigger) {
    rows[[length(rows) + 1L]] <- data.frame(
      break_route = route,
      trigger = FALSE,
      retained_break = NA_integer_,
      differenced_system_rank = NA_integer_,
      trace_r0 = NA_real_,
      trace_cv5 = NA_real_,
      delta_beta_ME = NA_real_,
      unit_vector_test = "not executed",
      disposition = "not_triggered_route_order_is_not_I2_risk",
      stringsAsFactors = FALSE
    )
    next
  }
  route_breaks <- parse_breaks(route)
  one_break <- if (length(route_breaks)) route_breaks[1] else integer()
  pulse <- NULL
  if (length(one_break)) {
    step <- sbvecm_step_matrix(panel$year, one_break, paste0(route, "_D"))
    pulse <- apply(step, 2, diff)
    if (is.null(dim(pulse))) pulse <- matrix(pulse, ncol = 1L)
  }
  dX <- diff(X)
  jo <- ca.jo(dX, type = "trace", ecdet = "const", K = 2,
              spec = "transitory", dumvar = pulse)
  rank <- if (jo@teststat[2] > jo@cval[2, "5pct"] &&
              jo@teststat[1] <= jo@cval[1, "5pct"]) 1L else
    if (jo@teststat[1] > jo@cval[1, "5pct"]) 2L else 0L
  beta <- -jo@V[2, 1] / jo@V[1, 1]
  rows[[length(rows) + 1L]] <- data.frame(
    break_route = route,
    trigger = TRUE,
    retained_break = if (length(one_break)) one_break else NA_integer_,
    differenced_system_rank = rank,
    trace_r0 = jo@teststat[2],
    trace_cv5 = jo@cval[2, "5pct"],
    delta_beta_ME = beta,
    unit_vector_test = if (rank == 1L)
      "requires dedicated I(2) restricted-rank implementation" else "not identified",
    disposition = "diagnostic_only_no_I2_relabeling",
    stringsAsFactors = FALSE
  )
}

ledger <- do.call(rbind, rows)
write.csv(ledger, file.path(out_dir, "i2_fallback_ledger.csv"), row.names = FALSE)
message("S40 complete: I(2) fallback trigger status recorded for both routes.")
