#!/usr/bin/env Rscript

# Shared functions for the Chile structural-break VECM audit.
# This file never chooses between LOESS and parametric break routes.

suppressPackageStartupMessages({
  library(urca)
  library(strucchange)
})

sbvecm_repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
sbvecm_seed <- 20260727L

sbvecm_dir <- function(...) file.path(sbvecm_repo_root, ...)

sbvecm_ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

sbvecm_sha256 <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

sbvecm_step_matrix <- function(year, breaks, prefix = "D") {
  breaks <- sort(unique(as.integer(breaks)))
  if (!length(breaks)) return(NULL)
  ans <- sapply(breaks, function(b) as.integer(year >= b))
  if (is.null(dim(ans))) ans <- matrix(ans, ncol = 1L)
  colnames(ans) <- paste0(prefix, "_", breaks)
  ans
}

sbvecm_trend_matrix <- function(year, breaks, prefix = "T") {
  breaks <- sort(unique(as.integer(breaks)))
  if (!length(breaks)) return(NULL)
  ans <- sapply(breaks, function(b) pmax(0, year - b))
  if (is.null(dim(ans))) ans <- matrix(ans, ncol = 1L)
  colnames(ans) <- paste0(prefix, "_", breaks)
  ans
}

sbvecm_adjust_for_steps <- function(x, year, breaks) {
  dm <- sbvecm_step_matrix(year, breaks)
  if (is.null(dm)) return(as.numeric(x))
  fit <- lm(as.numeric(x) ~ year + dm)
  as.numeric(residuals(fit))
}

sbvecm_test_extract <- function(obj, family, deterministic) {
  if (is.null(obj)) {
    return(list(statistic = NA_real_, critical_5 = NA_real_,
                stationary = NA, breakpoint_index = NA_integer_))
  }
  stat <- NA_real_
  cv5 <- NA_real_
  bp <- NA_integer_
  get_cv5 <- function(x) {
    cv <- x@cval
    if (!is.null(dim(cv)) && !is.null(colnames(cv)) && "5pct" %in% colnames(cv)) {
      return(as.numeric(cv[1, "5pct"]))
    }
    if (!is.null(dim(cv)) && ncol(cv) >= 2L) return(as.numeric(cv[1, 2L]))
    if (length(cv) >= 2L) return(as.numeric(cv[2L]))
    NA_real_
  }
  if (family == "ADF") {
    stat_name <- switch(deterministic, none = "tau1", drift = "tau2", trend = "tau3")
    stat <- as.numeric(obj@teststat[1, stat_name])
    cv5 <- as.numeric(obj@cval[stat_name, "5pct"])
  } else if (family == "PP") {
    stat <- as.numeric(obj@teststat[1])
    cv5 <- get_cv5(obj)
  } else if (family == "KPSS") {
    stat <- as.numeric(obj@teststat[1])
    cv5 <- get_cv5(obj)
  } else if (family == "ERS") {
    stat <- as.numeric(obj@teststat[1])
    cv5 <- get_cv5(obj)
  } else if (family == "SP") {
    stat <- as.numeric(obj@teststat[1])
    cv5 <- as.numeric(obj@cval[1])
  } else if (family == "ZA") {
    stat <- as.numeric(obj@teststat[1])
    cv5 <- as.numeric(obj@cval[2])
    bp <- as.integer(obj@bpoint)
  }
  stationary <- if (!is.finite(stat) || !is.finite(cv5)) {
    NA
  } else if (family == "KPSS") {
    stat <= cv5
  } else {
    stat < cv5
  }
  list(statistic = stat, critical_5 = cv5, stationary = stationary,
       breakpoint_index = bp)
}

sbvecm_battery_row <- function(variable, transformation, break_route, adjustment,
                               family, deterministic, configuration, obj, year_index,
                               error = "") {
  ext <- sbvecm_test_extract(obj, family, deterministic)
  bp_year <- NA_integer_
  if (!is.na(ext$breakpoint_index) &&
      ext$breakpoint_index >= 1L &&
      ext$breakpoint_index <= length(year_index)) {
    bp_year <- as.integer(year_index[ext$breakpoint_index])
  }
  data.frame(
    variable = variable,
    transformation = transformation,
    break_route = break_route,
    adjustment = adjustment,
    family = family,
    deterministic = deterministic,
    configuration = configuration,
    statistic = ext$statistic,
    critical_5 = ext$critical_5,
    stationary_at_5pct = ext$stationary,
    breakpoint_index = ext$breakpoint_index,
    breakpoint_year = bp_year,
    error = error,
    stringsAsFactors = FALSE
  )
}

sbvecm_safe_test <- function(expr) {
  tryCatch(list(object = eval.parent(substitute(expr)), error = ""),
           error = function(e) list(object = NULL, error = conditionMessage(e)))
}

sbvecm_run_urca_battery <- function(x, years, variable, break_route = "NONE",
                                    adjustment = "raw") {
  stopifnot(length(x) == length(years))
  transformations <- list(
    level = list(x = as.numeric(x), years = years),
    first_difference = list(x = diff(as.numeric(x), differences = 1L), years = years[-1L]),
    second_difference = list(x = diff(as.numeric(x), differences = 2L), years = years[-c(1L, 2L)])
  )
  rows <- list()
  add <- function(family, deterministic, configuration, tested, year_index) {
    rows[[length(rows) + 1L]] <<- sbvecm_battery_row(
      variable, current_transform, break_route, adjustment, family,
      deterministic, configuration, tested$object, year_index, tested$error
    )
  }
  for (tr_name in names(transformations)) {
    current_transform <- tr_name
    z <- transformations[[tr_name]]$x
    zy <- transformations[[tr_name]]$years
    if (length(z) < 20L || any(!is.finite(z))) next

    for (det in c("none", "drift", "trend")) {
      for (lag in 0:4) {
        tested <- sbvecm_safe_test(urca::ur.df(z, type = det, lags = lag,
                                              selectlags = "Fixed"))
        add("ADF", det, paste0("fixed_lag_", lag), tested, zy)
      }
      for (sel in c("AIC", "BIC")) {
        tested <- sbvecm_safe_test(urca::ur.df(z, type = det, lags = 4L,
                                              selectlags = sel))
        add("ADF", det, paste0(tolower(sel), "_maxlag_4"), tested, zy)
      }
    }

    for (test_type in c("Z-alpha", "Z-tau")) {
      for (det in c("constant", "trend")) {
        for (bw in c("short", "long")) {
          tested <- sbvecm_safe_test(urca::ur.pp(z, type = test_type,
                                                model = det, lags = bw))
          add("PP", det, paste(test_type, bw, sep = "_"), tested, zy)
        }
      }
    }

    for (det in c("mu", "tau")) {
      for (bw in c("nil", "short", "long")) {
        tested <- sbvecm_safe_test(urca::ur.kpss(z, type = det, lags = bw))
        add("KPSS", det, paste0("correction_", bw), tested, zy)
      }
    }

    for (test_type in c("DF-GLS", "P-test")) {
      for (det in c("constant", "trend")) {
        tested <- sbvecm_safe_test(urca::ur.ers(
          z, type = test_type, model = det, lag.max = 4L
        ))
        add("ERS", det, paste0(test_type, "_lagmax_4"), tested, zy)
      }
    }

    for (test_type in c("tau", "rho")) {
      for (degree in 1:4) {
        tested <- sbvecm_safe_test(urca::ur.sp(
          z, type = test_type, pol.deg = degree, signif = 0.05
        ))
        add("SP", paste0("polynomial_", degree),
            paste0(test_type, "_degree_", degree), tested, zy)
      }
    }

    for (det in c("intercept", "trend", "both")) {
      for (lag in 0:4) {
        tested <- sbvecm_safe_test(urca::ur.za(z, model = det, lag = lag))
        add("ZA", det, paste0("lag_", lag), tested, zy)
      }
    }
  }
  do.call(rbind, rows)
}

sbvecm_mark_primary <- function(battery) {
  battery$primary_configuration <- FALSE
  battery$primary_configuration[
    battery$family == "ADF" & battery$configuration == "bic_maxlag_4"
  ] <- TRUE
  battery$primary_configuration[
    battery$family == "PP" & battery$configuration == "Z-tau_long"
  ] <- TRUE
  battery$primary_configuration[
    battery$family == "KPSS" & battery$configuration == "correction_long"
  ] <- TRUE
  battery$primary_configuration[
    battery$family == "ERS" & battery$configuration == "DF-GLS_lagmax_4"
  ] <- TRUE
  battery$primary_configuration[
    battery$family == "SP" & battery$configuration == "tau_degree_2"
  ] <- TRUE
  battery$primary_configuration[
    battery$family == "ZA" & battery$configuration == "lag_1"
  ] <- TRUE
  battery
}

sbvecm_family_verdicts <- function(battery) {
  p <- battery[battery$primary_configuration & !is.na(battery$stationary_at_5pct), ]
  keys <- unique(p[c("variable", "transformation", "break_route", "adjustment", "family")])
  out <- lapply(seq_len(nrow(keys)), function(i) {
    k <- keys[i, ]
    z <- p[
      p$variable == k$variable &
        p$transformation == k$transformation &
        p$break_route == k$break_route &
        p$adjustment == k$adjustment &
        p$family == k$family, ]
    yes <- sum(z$stationary_at_5pct, na.rm = TRUE)
    no <- sum(!z$stationary_at_5pct, na.rm = TRUE)
    verdict <- if (yes > no) "stationary" else if (no > yes) "unit_root" else "conflict"
    data.frame(k, n_deterministic_cases = nrow(z), stationary_cases = yes,
               unit_root_cases = no, family_verdict = verdict,
               stringsAsFactors = FALSE)
  })
  do.call(rbind, out)
}

sbvecm_order_adjudication <- function(family_verdicts) {
  keys <- unique(family_verdicts[c("variable", "break_route", "adjustment")])
  out <- lapply(seq_len(nrow(keys)), function(i) {
    k <- keys[i, ]
    z <- family_verdicts[
      family_verdicts$variable == k$variable &
        family_verdicts$break_route == k$break_route &
        family_verdicts$adjustment == k$adjustment, ]
    transform_verdict <- function(tr) {
      q <- z[z$transformation == tr, ]
      yes <- sum(q$family_verdict == "stationary")
      no <- sum(q$family_verdict == "unit_root")
      verdict <- if (yes >= 4L) "stationary" else if (no >= 4L) "unit_root" else "held"
      c(verdict = verdict, stationary = yes, unit_root = no,
        conflict = sum(q$family_verdict == "conflict"))
    }
    lv <- transform_verdict("level")
    d1 <- transform_verdict("first_difference")
    d2 <- transform_verdict("second_difference")
    order <- "held"
    if (lv["verdict"] == "stationary") order <- "I(0)"
    if (lv["verdict"] == "unit_root" && d1["verdict"] == "stationary") order <- "I(1)"
    if (lv["verdict"] == "unit_root" && d1["verdict"] == "unit_root" &&
        d2["verdict"] == "stationary") order <- "I(2)-risk"
    data.frame(
      k,
      level_verdict = lv["verdict"],
      first_difference_verdict = d1["verdict"],
      second_difference_verdict = d2["verdict"],
      level_stationary_families = as.integer(lv["stationary"]),
      first_difference_stationary_families = as.integer(d1["stationary"]),
      second_difference_stationary_families = as.integer(d2["stationary"]),
      integration_order = order,
      disposition = if (order == "I(1)") "promoted" else if (order == "held") "held" else "blocked",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

sbvecm_loess_fit <- function(year, kappa, span) {
  fit <- loess(kappa ~ year, span = span, degree = 2,
               control = loess.control(surface = "direct"))
  fitted <- as.numeric(predict(fit, newdata = data.frame(year = year)))
  d1 <- c(NA_real_, (fitted[3:length(fitted)] - fitted[1:(length(fitted) - 2L)]) / 2,
          NA_real_)
  d2 <- c(NA_real_, fitted[3:length(fitted)] - 2 * fitted[2:(length(fitted) - 1L)] +
          fitted[1:(length(fitted) - 2L)], NA_real_)
  list(fit = fit, fitted = fitted, d1 = d1, d2 = d2)
}

sbvecm_loess_crossings <- function(year, d2) {
  idx <- which(is.finite(d2[-length(d2)]) & is.finite(d2[-1L]) &
                 d2[-length(d2)] * d2[-1L] < 0)
  as.integer(year[idx + 1L])
}

sbvecm_loess_cv_span <- function(year, kappa, spans = seq(0.15, 0.75, by = 0.01)) {
  cv_parts <- lapply(spans, function(s) {
    pred <- rep(NA_real_, length(kappa))
    for (i in seq_along(kappa)) {
      fit <- tryCatch(
        loess(y ~ year, data = data.frame(y = kappa[-i], year = year[-i]),
              span = s, degree = 2,
              control = loess.control(surface = "direct")),
        error = function(e) NULL
      )
      if (!is.null(fit)) {
        pred[i] <- tryCatch(
          as.numeric(predict(fit, newdata = data.frame(year = year[i]))),
          error = function(e) NA_real_
        )
        if (!is.finite(pred[i])) {
          fit2 <- loess(y ~ year, data = data.frame(y = kappa[-i], year = year[-i]),
                        span = s, degree = 2)
          pred[i] <- as.numeric(predict(fit2, data.frame(year = year[i])))
        }
      }
    }
    sq <- (kappa - pred)^2
    c(mse = mean(sq, na.rm = TRUE),
      se = sd(sq, na.rm = TRUE) / sqrt(sum(is.finite(sq))))
  })
  cv <- do.call(rbind, cv_parts)
  data.frame(span = spans, loocv_mse = cv[, "mse"], loocv_se = cv[, "se"])
}

sbvecm_block_indices <- function(n, block_length) {
  starts <- sample.int(n, ceiling(n / block_length), replace = TRUE)
  unlist(lapply(starts, function(s) ((s - 1L + 0:(block_length - 1L)) %% n) + 1L))[
    seq_len(n)
  ]
}

sbvecm_bic_lag <- function(x, max_lag = 4L, deterministic = c("drift", "trend", "none")) {
  deterministic <- match.arg(deterministic)
  vals <- sapply(0:max_lag, function(lag) {
    fit <- tryCatch(urca::ur.df(x, type = deterministic, lags = lag,
                               selectlags = "Fixed"), error = function(e) NULL)
    if (is.null(fit)) return(Inf)
    k <- length(coef(fit@testreg))
    n <- length(residuals(fit@testreg))
    rss <- sum(residuals(fit@testreg)^2)
    n * log(rss / n) + k * log(n)
  })
  which.min(vals) - 1L
}

sbvecm_adf_stat <- function(x, deterministic = "drift", max_lag = 4L) {
  lag <- sbvecm_bic_lag(x, max_lag, deterministic)
  obj <- urca::ur.df(x, type = deterministic, lags = lag, selectlags = "Fixed")
  ext <- sbvecm_test_extract(obj, "ADF", deterministic)
  c(statistic = ext$statistic, critical_5 = ext$critical_5, lag = lag)
}

sbvecm_serial_p <- function(cajorls_fit, lag = 4L) {
  if (is.null(cajorls_fit)) return(NA_real_)
  residuals_matrix <- residuals(cajorls_fit$rlm)
  if (is.null(dim(residuals_matrix))) return(NA_real_)
  pvals <- apply(residuals_matrix, 2, function(e) {
    tryCatch(Box.test(e, lag = min(lag, floor(length(e) / 5)),
                      type = "Ljung-Box", fitdf = 0)$p.value,
             error = function(err) NA_real_)
  })
  min(pvals, na.rm = TRUE)
}

sbvecm_model_id <- function(route, form, break_set, lag, centering) {
  clean_set <- if (!length(break_set)) "NONE" else paste(sort(break_set), collapse = "_")
  paste("CL-BVECM", route, form, clean_set, paste0("K", lag), centering, sep = "-")
}
