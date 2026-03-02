############################################################
# 34_stage3_EngleGrangerGate.R
# Stage 3 — EG residual stationarity gate (p=1,r=1 only)
# Outputs: output/EngleGrangerGate/ (NOT output/ChaoGrid/)
#
# Self-contained, allowed to source:
#   - codes/10_config.R
#   - codes/99_utils.R
#
# NO sinks. Logging via writeLines.
############################################################

# -------------------------
# 0) Packages (bootUR is soft)
# -------------------------
suppressPackageStartupMessages({
  library(here)
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(readr)
})


#here::i_am("/codes/34_report_stage_3")

source(here::here("codes", "10_config.R"))
source(here::here("codes", "99_utils.R"))

set_seed_deterministic(CONFIG$seed %||% 123456)

# -------------------------
# 1) Output dirs
# -------------------------
OUT_ROOT <- here::here("output", "EngleGrangerGate")
DIRS <- list(
  csv  = file.path(OUT_ROOT, "csv"),
  figs = file.path(OUT_ROOT, "figs"),
  logs = file.path(OUT_ROOT, "logs"),
  meta = file.path(OUT_ROOT, "meta"),
  rds  = file.path(OUT_ROOT, "rds"),
  tex  = file.path(OUT_ROOT, "tex")
)
ensure_dirs(OUT_ROOT, unlist(DIRS, use.names = FALSE))

log_file  <- file.path(DIRS$logs, "stage3_gate_log.txt")
log_lines <- character()

log_add <- function(...) {
  msg <- paste0(...)
  log_lines <<- c(log_lines, msg)
  invisible(TRUE)
}

log_flush <- function() {
  writeLines(log_lines, con = log_file, useBytes = TRUE)
  invisible(TRUE)
}

log_add("=== Stage 3 EG Gate start ===")
log_add("Timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
log_add("Project root: ", here::here())
log_add("OUT_ROOT: ", OUT_ROOT)

# -------------------------
# 2) Soft dependency: bootUR
# -------------------------
bootUR_ok <- requireNamespace("bootUR", quietly = TRUE)
log_add("bootUR available: ", bootUR_ok)

# -------------------------
# 3) Load data (single source of truth)
# -------------------------
data_path <- here::here(CONFIG$data_file)
if (!file.exists(data_path)) stop("Missing data file: ", data_path, call. = FALSE)

df0 <- readxl::read_excel(data_path, sheet = CONFIG$data_sheet)

need_cols <- c(CONFIG$year_col, CONFIG$y_col, CONFIG$k_col, CONFIG$e_col)
miss <- setdiff(need_cols, names(df0))
if (length(miss) > 0) stop("Missing required columns in data: ", paste(miss, collapse = ", "), call. = FALSE)

df <- df0 %>%
  transmute(
    year = as.integer(.data[[CONFIG$year_col]]),
    Y    = as.numeric(.data[[CONFIG$y_col]]),
    K    = as.numeric(.data[[CONFIG$k_col]]),
    e    = as.numeric(.data[[CONFIG$e_col]])
  ) %>%
  filter(is.finite(year), is.finite(Y), is.finite(K), is.finite(e)) %>%
  arrange(year) %>%
  mutate(
    logY = log(Y),
    logK = log(K),
    t_idx = year - min(year, na.rm = TRUE)  # deterministic trend regressor (0,1,2,...)
  )

if (nrow(df) < 25) stop("Too few observations after cleaning: n=", nrow(df), call. = FALSE)

# -------------------------
# 4) Helpers: windows, basis, regressors
# -------------------------
WINDOWS <- CONFIG$WINDOWS_LOCKED
ECDET   <- CONFIG$ECDET_LOCKED

apply_window <- function(d, window_name) {
  rng <- WINDOWS[[window_name]]
  if (is.null(rng) || length(rng) != 2) stop("Bad window definition for: ", window_name, call. = FALSE)
  lo <- rng[1]; hi <- rng[2]
  d %>% filter(year >= lo, year <= hi)
}

# Build regressors for EG regression
# - Always include logK
# - Raw basis: include e^j * logK for j=1..degree
# - Ortho basis: include e*logK (if INCLUDE_E_RAW) and Q2..Qdeg * logK (exclude Q1)
make_reg_df <- function(d, degree = 2L, basis = c("raw","ortho")) {
  basis <- match.arg(basis)
  out <- d %>% select(year, t_idx, logY, logK, e)
  
  if (basis == "raw") {
    for (j in seq_len(degree)) {
      out[[paste0("x", j)]] <- (out$e^j) * out$logK
    }
    return(out)
  }
  
  # ortho
  bobj <- basis_build_rawpowers_qr(out, e_col = "e", degree = degree)
  out2 <- basis_apply_rawpowers_qr(out, bobj, prefix = "Q")
  
  if (isTRUE(CONFIG$INCLUDE_E_RAW)) {
    out2[["x1"]] <- out2$e * out2$logK
  } else {
    out2[["x1"]] <- out2$Q1 * out2$logK
  }
  
  if (degree >= 2) {
    for (j in 2:degree) {
      out2[[paste0("x", j)]] <- out2[[paste0("Q", j)]] * out2$logK
    }
  }
  
  out2
}

# EG regression with deterministic toggle
# eg_det in {"intercept","trend"}
run_eg <- function(reg_df, degree, eg_det = c("intercept","trend")) {
  eg_det <- match.arg(eg_det)
  
  rhs <- c("logK", paste0("x", seq_len(degree)))
  if (eg_det == "trend") rhs <- c(rhs, "t_idx")
  
  fml <- as.formula(paste("logY ~", paste(rhs, collapse = " + ")))
  fit <- stats::lm(fml, data = reg_df)
  
  list(
    fit = fit,
    resid = as.numeric(stats::resid(fit)),
    n = stats::nobs(fit),
    formula = deparse(fml)
  )
}

# bootUR deterministics mapping
map_adf_det <- function(eg_det) {
  if (eg_det == "trend") return("trend")
  "intercept"
}

# -------------------------
# 5) Candidate grid (p=r=1 fixed)
# -------------------------
RUN_TAGS <- tibble::tibble(
  run_tag = c("Q2_raw","Q2_ortho","Q3_raw","Q3_ortho"),
  spec    = c("Q2","Q2","Q3","Q3"),
  degree  = c(2L,2L,3L,3L),
  basis   = c("raw","ortho","raw","ortho")
)

EG_DET_TOGGLE <- c("intercept","trend")

spec_grid <- tidyr::expand_grid(
  RUN_TAGS,
  window = names(WINDOWS),
  ecdet  = ECDET,
  eg_det = EG_DET_TOGGLE
) %>%
  mutate(
    p = 1L,
    r = 1L,
    spec_id = paste(run_tag, window, ecdet, paste0("EG_", eg_det), sep = "__")
  )

log_add("Spec grid rows: ", nrow(spec_grid))

# -------------------------
# 6) Run EG + ADF + bootstrap ADF (if bootUR)
# -------------------------
gate_rows  <- vector("list", nrow(spec_grid))
resid_list <- list()

alpha <- 0.05

for (ii in seq_len(nrow(spec_grid))) {
  row <- spec_grid[ii, ]
  
  run_tag <- row$run_tag
  degree  <- row$degree
  basis   <- row$basis
  window  <- row$window
  ecdet   <- row$ecdet
  eg_det  <- row$eg_det
  
  dW <- apply_window(df, window)
  reg_df <- make_reg_df(dW, degree = degree, basis = basis)
  
  eg <- try(run_eg(reg_df, degree = degree, eg_det = eg_det), silent = TRUE)
  if (inherits(eg, "try-error")) {
    gate_rows[[ii]] <- tibble::tibble(
      spec_id = row$spec_id,
      run_tag = run_tag,
      spec = row$spec,
      degree = degree,
      window = window,
      ecdet = ecdet,
      basis = basis,
      eg_det = eg_det,
      p = 1L, r = 1L,
      n_obs = NA_integer_,
      eg_formula = NA_character_,
      adf_stat = NA_real_,
      adf_pval = NA_real_,
      adf_det = map_adf_det(eg_det),
      boot_pval = NA_real_,
      boot_B = NA_integer_,
      gate_pass = NA,
      notes = paste0("EG failed: ", as.character(eg))
    )
    next
  }
  
  uhat <- eg$resid
  resid_list[[row$spec_id]] <- uhat
  
  adf_stat <- NA_real_
  adf_pval <- NA_real_
  adf_det  <- map_adf_det(eg_det)
  
  boot_pval <- NA_real_
  boot_B    <- NA_integer_
  
  if (bootUR_ok) {
    # asymptotic adf (still useful as label)
    adf_obj <- try(bootUR::adf(uhat, deterministics = adf_det), silent = TRUE)
    if (!inherits(adf_obj, "try-error")) {
      adf_stat <- as.numeric(adf_obj$statistic)
      adf_pval <- as.numeric(adf_obj$p.value)
    }
    
    # bootstrap adf (small-sample diagnostic)
    boot_B <- 9999L
    boot_obj <- try(
      bootUR::boot_adf(
        uhat,
        B = boot_B,
        deterministics = adf_det,
        bootstrap = "AWB",
        detrend = "OLS",
        show_progress = FALSE,
        do_parallel = FALSE   # safer default; flip TRUE when stable
      ),
      silent = TRUE
    )
    if (!inherits(boot_obj, "try-error")) {
      boot_pval <- as.numeric(boot_obj$p.value)
    }
  }
  
  # Gate annotation:
  # Use bootstrap if available, else fall back to asymptotic.
  gate_pass <- NA
  if (is.finite(boot_pval)) {
    gate_pass <- (boot_pval <= alpha)
  } else if (is.finite(adf_pval)) {
    gate_pass <- (adf_pval <= alpha)
  }
  
  note_bits <- c()
  if (!bootUR_ok) note_bits <- c(note_bits, "bootUR not installed; bootstrap skipped")
  if (bootUR_ok && !is.finite(boot_pval)) note_bits <- c(note_bits, "boot_adf failed/NA; fallback may apply")
  if (length(note_bits) == 0) note_bits <- c("ok")
  
  gate_rows[[ii]] <- tibble::tibble(
    spec_id = row$spec_id,
    run_tag = run_tag,
    spec = row$spec,
    degree = degree,
    window = window,
    ecdet = ecdet,
    basis = basis,
    eg_det = eg_det,
    p = 1L, r = 1L,
    n_obs = eg$n,
    eg_formula = eg$formula,
    adf_stat = adf_stat,
    adf_pval = adf_pval,
    adf_det = adf_det,
    boot_pval = boot_pval,
    boot_B = boot_B,
    gate_pass = gate_pass,
    notes = paste(note_bits, collapse = " | ")
  )
}

gate_tbl <- bind_rows(gate_rows) %>%
  arrange(run_tag, window, ecdet, eg_det)

# -------------------------
# 7) Write outputs
# -------------------------
out_csv <- file.path(DIRS$csv, "stage3_gate_table.csv")
readr::write_csv(gate_tbl, out_csv)

out_rds <- file.path(DIRS$rds, "stage3_gate_residuals.rds")
saveRDS(resid_list, out_rds)

meta_file <- file.path(DIRS$meta, "stage3_gate_meta.txt")
meta_lines <- c(
  "=== Stage 3 Gate meta ===",
  paste0("Timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("Data file: ", CONFIG$data_file),
  paste0("Sheet: ", CONFIG$data_sheet),
  paste0("Windows: ", paste(names(WINDOWS), collapse = ", ")),
  paste0("ECDET: ", paste(ECDET, collapse = ", ")),
  paste0("EG deterministic toggle: ", paste(EG_DET_TOGGLE, collapse = ", ")),
  paste0("bootUR available: ", bootUR_ok),
  "",
  "sessionInfo():",
  capture.output(sessionInfo())
)
writeLines(meta_lines, con = meta_file, useBytes = TRUE)

log_add("Wrote CSV: ", out_csv)
log_add("Wrote RDS: ", out_rds)
log_add("Wrote META: ", meta_file)
log_add("=== Stage 3 EG Gate COMPLETE ===")
log_flush()

cat("Stage 3 EG Gate done.\n")
cat("Outputs under: ", OUT_ROOT, "\n", sep = "")

# ============================================================
# STAGE 3 — Console + Log Summary Patch (FIXED v2)
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
})

tbl <- readr::read_csv(out_csv, show_col_types = FALSE)

expected <- c("spec_id","run_tag","window","ecdet","basis","eg_det",
              "n_obs","adf_stat","adf_pval","boot_pval","gate_pass")
missing_cols <- setdiff(expected, names(tbl))

n_total <- nrow(tbl)
n_pass  <- sum(tbl$gate_pass == TRUE,  na.rm = TRUE)
n_fail  <- sum(tbl$gate_pass == FALSE, na.rm = TRUE)
n_na    <- sum(is.na(tbl$gate_pass))

boot_share_non_na <- if ("boot_pval" %in% names(tbl)) mean(is.finite(tbl$boot_pval)) else 0

by_cell <- tbl %>%
  mutate(
    gate_pass_chr = case_when(
      gate_pass == TRUE  ~ "PASS",
      gate_pass == FALSE ~ "FAIL",
      TRUE               ~ "NA"
    )
  ) %>%
  count(run_tag, window, ecdet, eg_det, gate_pass_chr, name = "n") %>%
  tidyr::pivot_wider(names_from = gate_pass_chr, values_from = n, values_fill = 0)

# Ensure all three columns exist even if absent in data
for (nm in c("PASS","FAIL","NA")) {
  if (!(nm %in% names(by_cell))) by_cell[[nm]] <- 0L
}

by_cell <- by_cell %>%
  mutate(total = PASS + FAIL + .data[["NA"]]) %>%   # <-- IMPORTANT: column "NA"
  arrange(run_tag, window, ecdet, eg_det)

adf_brief <- tbl %>%
  summarise(
    n_adf_stat = sum(is.finite(adf_stat)),
    stat_min   = suppressWarnings(min(adf_stat, na.rm = TRUE)),
    stat_med   = suppressWarnings(median(adf_stat, na.rm = TRUE)),
    stat_max   = suppressWarnings(max(adf_stat, na.rm = TRUE)),
    n_adf_pval = sum(is.finite(adf_pval)),
    pval_min   = suppressWarnings(min(adf_pval, na.rm = TRUE)),
    pval_med   = suppressWarnings(median(adf_pval, na.rm = TRUE)),
    pval_max   = suppressWarnings(max(adf_pval, na.rm = TRUE))
  )

fmt_tbl <- function(df, n = 200) {
  out <- capture.output(print(df, n = n, width = 120))
  paste(out, collapse = "\n")
}

stamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
report <- c(
  "",
  "============================================================",
  paste0("STAGE 3 EG GATE — OUTPUT SUMMARY @ ", stamp),
  "============================================================",
  paste0("CSV: ", normalizePath(out_csv, winslash = "/", mustWork = FALSE)),
  paste0("Rows: ", n_total, " | PASS: ", n_pass, " | FAIL: ", n_fail, " | NA: ", n_na),
  paste0("bootUR available: ", bootUR_ok),
  paste0("boot_pval non-missing share: ", sprintf("%.3f", boot_share_non_na)),
  if (!bootUR_ok) "NOTE: Bootstrap unit-root inference was NOT run (bootUR unavailable)."
  else "NOTE: Bootstrap unit-root inference was run where boot_pval is non-missing.",
  if (length(missing_cols) > 0) paste0("WARNING: missing expected columns: ", paste(missing_cols, collapse = ", "))
  else "Columns: OK",
  "",
  "--- Gate outcomes by run_tag × window × ecdet × EG_det ---",
  fmt_tbl(by_cell, n = 500),
  "",
  "--- ADF diagnostic (overall) ---",
  fmt_tbl(adf_brief, n = 50),
  "============================================================"
)

cat(paste0(report, collapse = "\n"), "\n")
writeLines(report, con = log_file, sep = "\n", useBytes = TRUE)