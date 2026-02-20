# ============================================================
# 20_engine.R — ChaoGrid Engine (Q2 + Q3, ORTHO toggle)
#
# Contract:
# - Build FULL lattice over (p,r) for each window × ecdet
# - Never drop cells
# - Separate: gate_ok (admissibility) vs runtime_ok (estimation success)
# - Export unrestricted canonical tables per (spec × ortho)
#
# Outputs:
# output/ChaoGrid/csv/grid_pic_table_<SPEC>_<BASIS>_unrestricted.csv
# output/ChaoGrid/csv/S1_feasible_pmax_by_window_ecdet_<SPEC>_<BASIS>.csv
# output/ChaoGrid/meta/S0_basis_<SPEC>_<BASIS>.txt
# output/ChaoGrid/logs/engine_<SPEC>_<BASIS>.log
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","readxl","dplyr","tidyr","urca","readr")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

setwd("C:/ReposGitHub/capacity_utilization/")

# --- Load utils + config
here::i_am("codes/10_config.R")
source(here::here("codes", "99_utils.R"))
source(here::here("codes", "10_config.R"))

# reset_r_io()
set_seed_deterministic(CONFIG$seed)

# ----------------------------
# Paths
# ----------------------------
ROOT_OUT <- here::here(CONFIG$OUT_ROOT)
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  meta = file.path(ROOT_OUT, "meta"),
  logs = file.path(ROOT_OUT, "logs")
)
ensure_dirs(DIRS$csv, DIRS$meta, DIRS$logs)

# ----------------------------
# Window helper
# ----------------------------
filter_window_years <- function(df, key, year_col = "year") {
  rng <- CONFIG$WINDOWS_LOCKED[[key]]
  df |>
    dplyr::filter(.data[[year_col]] >= rng[1], .data[[year_col]] <= rng[2])
}

# ----------------------------
# Basis builders (toggle backbone)
# ----------------------------
build_basis <- function(df_full, e_col, degree, orthogonalize = TRUE) {
  if (orthogonalize) {
    b <- basis_build_poly(df_full, e_col = e_col, degree = degree, center_scale = TRUE)
    b$basis_name <- paste0("ortho_deg", degree)
    return(b)
  }
  
  # raw standardized powers: z, z^2, ..., z^d
  e <- df_full[[e_col]]
  mu <- mean(e, na.rm = TRUE)
  sdv <- stats::sd(e, na.rm = TRUE)
  if (!is.finite(sdv) || sdv <= 0) stop("RAW basis: sd(e) invalid", call. = FALSE)
  
  list(
    type = "raw_std_powers",
    e_col = e_col,
    degree = degree,
    mean_full = mu,
    sd_full = sdv,
    basis_name = paste0("raw_deg", degree)
  )
}

apply_basis <- function(df, basis) {
  e <- df[[basis$e_col]]
  
  if (identical(basis$type, "poly_orthonormal")) {
    # creates Q1..Qd
    out <- basis_apply_poly(df, basis, prefix = "Q")
    return(out)
  }
  
  if (identical(basis$type, "raw_std_powers")) {
    z <- (as.numeric(e) - basis$mean_full) / basis$sd_full
    for (j in seq_len(basis$degree)) df[[paste0("Q", j)]] <- z^j
    return(df)
  }
  
  stop("Unknown basis$type", call. = FALSE)
}

# ----------------------------
# Build system matrix Y for degree d
# System: [log_y, log_k, Q1*log_k, ..., Qd*log_k]
# ----------------------------
build_system_Qd_engine <- function(df, d, y_col = "log_y", k_col = "log_k") {
  build_system_Qd(df, d = d, y_col = y_col, k_col = k_col, q_prefix = "Q")
}

# ----------------------------
# Gate rule (kept simple + explicit)
# ----------------------------
feasible_for_ca_jo <- function(T, m, p, ecdet) {
  T_eff  <- T - p
  min_eff <- max(20, 5*m + 5*p + ifelse(ecdet == "const", 5, 0))
  list(ok = is.finite(T_eff) && T_eff > min_eff, T_eff = T_eff, min_eff = min_eff)
}

# ----------------------------
# Lattice builder
# ----------------------------
build_lattice <- function(sys_list, p_min, p_max, ecdet_set) {
  out <- list()
  for (w in names(sys_list)) {
    Y <- sys_list[[w]]$Y
    T_w <- nrow(Y); m_w <- ncol(Y)
    out[[length(out) + 1L]] <- tidyr::expand_grid(
      window = w,
      ecdet  = ecdet_set,
      p      = p_min:p_max,
      r      = 0:(m_w - 1L)
    ) |>
      dplyr::mutate(T = T_w, m = m_w, K = p + 1L)
  }
  dplyr::bind_rows(out) |>
    dplyr::mutate(
      window = as.character(.data$window),
      ecdet  = as.character(.data$ecdet),
      p      = as.integer(.data$p),
      r      = as.integer(.data$r),
      T      = as.integer(.data$T),
      m      = as.integer(.data$m),
      K      = as.integer(.data$K)
    )
}

# ============================================================
# S1 Load + pre-transform data
# ============================================================
data_path <- here::here(CONFIG$data_file)
ddbb_us <- readxl::read_excel(data_path, sheet = CONFIG$data_sheet)

df0 <- dplyr::transmute(
  ddbb_us,
  year  = .data[[CONFIG$year_col]],
  log_y = log(.data[[CONFIG$y_col]]),
  log_k = log(.data[[CONFIG$k_col]]),
  e     = .data[[CONFIG$e_col]]
) |>
  dplyr::arrange(.data$year) |>
  dplyr::filter(
    is.finite(.data$year),
    is.finite(.data$log_y),
    is.finite(.data$log_k),
    is.finite(.data$e)
  )

windows_raw <- list(
  full         = filter_window_years(df0, "full", year_col = "year"),
  fordism      = filter_window_years(df0, "fordism", year_col = "year"),
  post_fordism = filter_window_years(df0, "post_fordism", year_col = "year")
)

# ============================================================
# S2 Run: for each SPEC × ORTHO
# ============================================================
for (spec_name in names(CONFIG$SPECS)) {
  
  degree <- CONFIG$SPECS[[spec_name]]$degree
  
  for (ORTHO in CONFIG$ORTHO_TOGGLE) {
    
    basis_tag <- if (ORTHO) "ortho" else "raw"
    run_tag   <- paste0(spec_name, "_", basis_tag)
    
    log_file <- file.path(DIRS$logs, paste0("engine_", run_tag, ".log"))
    sink(log_file, split = TRUE)
    on.exit(sink(), add = TRUE)
    
    cat("=== Engine start:", run_tag, "===\n")
    cat("Project root:", here::here(), "\n")
    cat("Output root :", ROOT_OUT, "\n")
    cat("Degree      :", degree, "\n")
    cat("ORTHO       :", ORTHO, "\n\n")
    
    # --- Build basis on FULL window once
    basis <- build_basis(windows_raw$full, e_col = "e", degree = degree, orthogonalize = ORTHO)
    
    # --- record basis meta (minimal + stable)
    writeLines(
      c(
        paste0("basis_tag=", basis_tag),
        paste0("spec=", spec_name),
        paste0("degree=", degree),
        paste0("type=", basis$type),
        paste0("e_col=", basis$e_col),
        paste0("mean_full=", signif(basis$mean_full, 10)),
        paste0("sd_full=", signif(basis$sd_full, 10))
      ),
      con = file.path(DIRS$meta, paste0("S0_basis_", run_tag, ".txt"))
    )
    
    # --- Apply basis to each window + build Y
    windows_b <- lapply(windows_raw, apply_basis, basis = basis)
    sys_list  <- lapply(windows_b, build_system_Qd_engine, d = degree, y_col = "log_y", k_col = "log_k")
    
    # dimension check
    m_vec <- vapply(sys_list, function(s) ncol(s$Y), integer(1))
    if (length(unique(m_vec)) != 1) stop("System dimension differs across windows; check missingness.", call. = FALSE)
    m_sys <- unique(m_vec)
    cat("System dimension m =", m_sys, "\n\n")
    
    # --- Lattice
    lattice <- build_lattice(
      sys_list = sys_list,
      p_min    = CONFIG$P_MIN,
      p_max    = CONFIG$P_MAX_EXPLORATORY,
      ecdet_set= CONFIG$ECDET_LOCKED
    )
    
    # --- comparability metadata: COMMON_P_MAX (not a filter, just a flag)
    feas_rows <- list()
    for (w in names(sys_list)) {
      T_w <- nrow(sys_list[[w]]$Y)
      for (ec in CONFIG$ECDET_LOCKED) {
        feas <- integer(0)
        for (p in CONFIG$P_MIN:CONFIG$P_MAX_EXPLORATORY) {
          g <- feasible_for_ca_jo(T = T_w, m = m_sys, p = p, ecdet = ec)
          if (isTRUE(g$ok)) feas <- c(feas, p)
        }
        feas_rows[[length(feas_rows) + 1L]] <- data.frame(
          window = w, ecdet = ec, T = T_w, m = m_sys,
          p_max_feasible = if (length(feas) == 0) NA_integer_ else max(feas),
          stringsAsFactors = FALSE
        )
      }
    }
    feasible_df <- dplyr::bind_rows(feas_rows)
    readr::write_csv(feasible_df, file.path(DIRS$csv, paste0("S1_feasible_pmax_by_window_ecdet_", run_tag, ".csv")))
    
    COMMON_P_MAX <- min(feasible_df$p_max_feasible, na.rm = TRUE)
    cat("COMMON_P_MAX =", COMMON_P_MAX, "\n\n")
    
    # --- Compute per (window, ecdet, p): gate/runtime + rank IC
    keys <- lattice |>
      dplyr::distinct(window, ecdet, p, T, m, K) |>
      dplyr::arrange(window, ecdet, p)
    
    cell_rows <- vector("list", nrow(keys))
    rank_rows <- list()
    
    for (i in seq_len(nrow(keys))) {
      
      w  <- keys$window[i]
      ec <- keys$ecdet[i]
      p  <- keys$p[i]
      T_w <- keys$T[i]
      m_w <- keys$m[i]
      K   <- keys$K[i]
      
      gate <- feasible_for_ca_jo(T = T_w, m = m_w, p = p, ecdet = ec)
      
      cs <- data.frame(
        window = w, ecdet = ec, p = p, T = T_w, m = m_w, K = K,
        gate_ok = isTRUE(gate$ok),
        gate_T_eff = gate$T_eff,
        gate_min_eff = gate$min_eff,
        runtime_ok = FALSE,
        runtime_reason = NA_character_,
        stringsAsFactors = FALSE
      )
      
      if (!isTRUE(gate$ok)) {
        cs$runtime_reason <- paste0("gate_fail: T_eff=", gate$T_eff, " <= min_eff=", gate$min_eff)
        cell_rows[[i]] <- cs
        next
      }
      
      jo_tr <- tryCatch(
        urca::ca.jo(sys_list[[w]]$Y, type = "trace", ecdet = ec, K = K, spec = CONFIG$johansen_spec),
        error = function(e) e
      )
      
      if (inherits(jo_tr, "error")) {
        cs$runtime_reason <- paste0("runtime_fail: ", conditionMessage(jo_tr))
        cell_rows[[i]] <- cs
        next
      }
      
      ll_by_r <- rep(NA_real_, m_w)
      for (rr in 0:(m_w - 1L)) {
        ll_by_r[rr + 1L] <- loglik_from_cajorls(jo_tr, r = rr, m_expected = m_w)
      }
      
      if (all(!is.finite(ll_by_r))) {
        cs$runtime_reason <- "runtime_fail: cajorls logLik all non-finite"
        cell_rows[[i]] <- cs
        next
      }
      
      cs$runtime_ok <- TRUE
      cell_rows[[i]] <- cs
      
      rr_tbl <- data.frame(
        window = w, ecdet = ec, p = p, r = 0:(m_w - 1L),
        logLik = ll_by_r,
        stringsAsFactors = FALSE
      ) |>
        dplyr::mutate(
          k_total = vapply(.data$r, function(rrr) count_params_vecm(m = m_w, p = p, r = rrr, ecdet = ec)$k_total, numeric(1)),
          PIC = mapply(function(ll, kk) if (is.finite(ll)) calc_ic(ll, T_w, kk)$PIC else NA_real_, .data$logLik, .data$k_total),
          BIC = mapply(function(ll, kk) if (is.finite(ll)) calc_ic(ll, T_w, kk)$BIC else NA_real_, .data$logLik, .data$k_total)
        )
      
      rank_rows[[length(rank_rows) + 1L]] <- rr_tbl
    }
    
    cell_tbl <- dplyr::bind_rows(cell_rows)
    rr_tbl   <- if (length(rank_rows) > 0) dplyr::bind_rows(rank_rows) else dplyr::tibble()
    
    gridU <- lattice |>
      dplyr::left_join(cell_tbl, by = c("window","ecdet","p","T","m","K")) |>
      dplyr::left_join(rr_tbl,   by = c("window","ecdet","p","r")) |>
      dplyr::mutate(
        comparable_p = (.data$p <= COMMON_P_MAX),
        status = dplyr::case_when(
          !.data$gate_ok ~ "gate_fail",
          .data$gate_ok & !.data$runtime_ok ~ "runtime_fail",
          .data$gate_ok & .data$runtime_ok & is.finite(.data$PIC) ~ "computed",
          TRUE ~ "missing"
        ),
        PIC_obs = ifelse(.data$status == "computed", .data$PIC, NA_real_),
        BIC_obs = ifelse(.data$status == "computed", .data$BIC, NA_real_)
      ) |>
      dplyr::mutate(
        spec  = spec_name,
        basis = basis_tag
      )
    
    out_csv <- file.path(DIRS$csv, paste0("grid_pic_table_", run_tag, "_unrestricted.csv"))
    readr::write_csv(gridU, out_csv)
    
    
    cat("Wrote:", out_csv, "\n")
    cat("=== Engine completed OK:", run_tag, "===\n")
    sink()
  }
}
