# ============================================================
# ChaoGrid_Engine_Q2_BootstrapSurface.R
# Purpose:
#   - Take grid_pic_table_Q2_unrestricted.csv
#   - For each window×ecdet, bootstrap over observed cells (PIC_obs)
#   - Fit a smooth surface per bootstrap sample
#   - Predict PIC_hat on FULL lattice
#   - Export:
#       output/ChaoGrid/tex/PIC_surface_bootstrap_pack_Q2.csv
#       (includes median + bands for each p,r)
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","readr","dplyr","tidyr","tibble")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

ROOT <- here::here("output/ChaoGrid")
DIRS_IN  <- list(csv = file.path(ROOT, "csv"))
DIRS_OUT <- list(tex = file.path(ROOT, "tex"), logs = file.path(ROOT, "logs"))
dir.create(DIRS_OUT$tex,  recursive=TRUE, showWarnings=FALSE)
dir.create(DIRS_OUT$logs, recursive=TRUE, showWarnings=FALSE)

log_file <- file.path(DIRS_OUT$logs, "engine_q2_bootstrap_surface_log.txt")
sink(log_file, split=TRUE)
on.exit(sink(), add=TRUE)

cat("=== Bootstrap Surface Engine start (Q2) ===\n")
cat("ROOT:", ROOT, "\n\n")

pathU <- file.path(DIRS_IN$csv, "grid_pic_table_Q2_unrestricted.csv")
if (!file.exists(pathU)) stop("Missing: grid_pic_table_Q2_unrestricted.csv", call.=FALSE)
gridU <- readr::read_csv(pathU, show_col_types = FALSE) |>
  dplyr::mutate(
    window = as.character(.data$window),
    ecdet  = as.character(.data$ecdet),
    p      = as.integer(.data$p),
    r      = as.integer(.data$r),
    gate_ok    = as.logical(.data$gate_ok),
    runtime_ok = as.logical(.data$runtime_ok),
    comparable_p = as.logical(.data$comparable_p)
  )

# --- Surface fitter: same rule each time (loess if enough, else quadratic, else constant)
fit_predict_surface <- function(d_full, d_obs) {
  if (nrow(d_obs) == 0) return(rep(NA_real_, nrow(d_full)))
  
  if (nrow(d_obs) >= 12) {
    fit <- tryCatch(
      stats::loess(PIC_obs ~ p + r, data = d_obs,
                   span = 0.9, degree = 2,
                   control = stats::loess.control(surface="direct")),
      error = function(e) NULL
    )
    if (!is.null(fit)) {
      pred <- tryCatch(stats::predict(fit, newdata = d_full), error = function(e) rep(NA_real_, nrow(d_full)))
      if (any(is.finite(pred))) return(as.numeric(pred))
    }
  }
  
  if (nrow(d_obs) >= 6) {
    fit2 <- tryCatch(
      stats::lm(PIC_obs ~ p + r + I(p^2) + I(r^2) + I(p*r), data = d_obs),
      error = function(e) NULL
    )
    if (!is.null(fit2)) {
      pred <- tryCatch(stats::predict(fit2, newdata = d_full), error = function(e) rep(NA_real_, nrow(d_full)))
      if (any(is.finite(pred))) return(as.numeric(pred))
    }
  }
  
  rep(stats::median(d_obs$PIC_obs, na.rm=TRUE), nrow(d_full))
}

# Bootstrap control
B <- 400L            # raise if you want smoother bands
Q_LO <- 0.10
Q_HI <- 0.90

keys <- gridU |>
  dplyr::distinct(window, ecdet) |>
  dplyr::arrange(window, ecdet)

pack_list <- vector("list", nrow(keys))

for (i in seq_len(nrow(keys))) {
  w  <- keys$window[i]
  ec <- keys$ecdet[i]
  cat("----", w, "|", ec, "----\n")
  
  d0 <- gridU |> dplyr::filter(.data$window == w, .data$ecdet == ec)
  
  full_grid <- tidyr::expand_grid(
    p = sort(unique(d0$p)),
    r = sort(unique(d0$r))
  )
  
  d_obs0 <- d0 |> dplyr::filter(is.finite(.data$PIC_obs)) |> dplyr::select(p, r, PIC_obs = PIC_obs)
  
  if (nrow(d_obs0) < 6) {
    cat("Too few observed points:", nrow(d_obs0), "=> constant fallback only.\n")
    pic_hat <- fit_predict_surface(full_grid, d_obs0)
    out <- full_grid |>
      dplyr::mutate(
        PIC_hat_median = pic_hat,
        PIC_hat_lo = pic_hat,
        PIC_hat_hi = pic_hat
      )
  } else {
    # bootstrap predictions matrix: n_full × B
    n_full <- nrow(full_grid)
    preds <- matrix(NA_real_, nrow = n_full, ncol = B)
    
    for (b in seq_len(B)) {
      idx <- sample.int(nrow(d_obs0), size = nrow(d_obs0), replace = TRUE)
      d_obs_b <- d_obs0[idx, , drop = FALSE]
      preds[, b] <- fit_predict_surface(full_grid, d_obs_b)
    }
    
    out <- full_grid |>
      dplyr::mutate(
        PIC_hat_median = apply(preds, 1, stats::median, na.rm = TRUE),
        PIC_hat_lo     = apply(preds, 1, stats::quantile, probs = Q_LO, na.rm = TRUE),
        PIC_hat_hi     = apply(preds, 1, stats::quantile, probs = Q_HI, na.rm = TRUE)
      )
  }
  
  # Join overlays back in (status/gate/runtime/comparable + observed PIC)
  out <- out |>
    dplyr::left_join(
      d0 |> dplyr::select(p, r, status, gate_ok, runtime_ok, comparable_p, PIC_obs, BIC_obs),
      by = c("p","r")
    ) |>
    dplyr::mutate(
      window = w,
      ecdet  = ec,
      status = dplyr::coalesce(as.character(.data$status), "missing"),
      gate_ok = dplyr::coalesce(.data$gate_ok, FALSE),
      runtime_ok = dplyr::coalesce(.data$runtime_ok, FALSE),
      comparable_p = dplyr::coalesce(.data$comparable_p, FALSE)
    )
  
  pack_list[[i]] <- out
}

SURF_BOOT <- dplyr::bind_rows(pack_list) |>
  dplyr::mutate(
    window = as.character(.data$window),
    ecdet  = as.character(.data$ecdet),
    p      = as.integer(.data$p),
    r      = as.integer(.data$r)
  )

out_path <- file.path(DIRS_OUT$tex, "PIC_surface_bootstrap_pack_Q2.csv")
readr::write_csv(SURF_BOOT, out_path)

cat("\nWrote:", out_path, "\n")
cat("=== Bootstrap Surface Engine completed OK ===\n")
