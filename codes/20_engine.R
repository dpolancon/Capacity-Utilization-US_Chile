# ============================================================
# 20_engine.R — ChaoGrid Engine (v4 CONSOLIDATED)
# Repo: capacity_utilization/
#
# Goal (locked):
# - Build FULL lattice over (p,r) for each window × ecdet
# - NEVER drop cells: separate gate_ok vs runtime_ok
# - Export unrestricted canonical grid tables for joint (p,r) selection (PIC/BIC)
#
# v4 fixes (definitive sink discipline):
# - NO file() connection objects.
# - sink() by filename only, with a dedicated open/close wrapper.
# - Always close message sinks first, then output sinks.
# - Fail-fast if sinks already open (optional auto-close via CONFIG$AUTO_CLOSE_SINKS).
#
# e handling (locked):
# - NO standardization of e (raw only).
# - ORTHO toggle = QR orthogonalization of RAW powers block X=[e^1,...,e^d]
#   applied BEFORE interacting with logK:
#     Q = X %*% A   (A stored)
#     regressors: Qj*logK
# - Transformation A is saved so coefficients can be back-transformed:
#     delta_raw = A %*% gamma_ortho
#
# Specs supported:
# - type="poly_theta":  [log_y, log_k, (optional e_raw), Q1*logK,...,Qd*logK]
# - type="linear_affine_theta": [log_y, log_k, e_raw*logK]   (theta(e)=λ0+λ1 e)
#
# Exports (prefixed):
#  csv/<APPX>_grid_pic_table_<SPEC>_<BASIS>_unrestricted.csv
#  csv/<APPX>_S1_feasible_pmax_by_window_ecdet_<SPEC>_<BASIS>.csv
#  meta/<APPX>_S0_basis_<SPEC>_<BASIS>.txt
#  meta/<APPX>_S0_systemvars_<SPEC>_<BASIS>.txt
#  meta/<APPX>_A_matrix_<SPEC>_<BASIS>.{rds,csv}   [only ortho + poly_theta]
#  logs/<APPX>_engine_<SPEC>_<BASIS>.log
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","readxl","dplyr","tidyr","urca","readr")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

# --- Load config + utils (do not put runtime logic into config)
here::i_am("codes/10_config.R")
source(here::here("codes", "99_utils.R"))
source(here::here("codes", "10_config.R"))

# ------------------------------------------------------------
# Fallback helpers (only if not defined in 99_utils.R)
# ------------------------------------------------------------
`%||%` <- get0("%||%", ifnotfound = function(a,b) if (is.null(a)) b else a)

ensure_dirs <- get0("ensure_dirs", ifnotfound = function(...) {
  paths <- unique(c(...))
  paths <- paths[!is.na(paths) & nzchar(paths)]
  invisible(lapply(paths, function(p) if (!dir.exists(p)) dir.create(p, recursive = TRUE, showWarnings = FALSE)))
})

set_seed_deterministic <- get0("set_seed_deterministic", ifnotfound = function(seed = 123456) {
  suppressWarnings(RNGkind(kind = "Mersenne-Twister", normal.kind = "Inversion"))
  set.seed(seed)
  invisible(TRUE)
})

# logLik from cajorls (fallback if absent)
loglik_from_cajorls <- get0("loglik_from_cajorls", ifnotfound = function(jo_trace, r, m_expected = NULL) {
  fit <- tryCatch(urca::cajorls(jo_trace, r = r), error = function(e) e)
  if (inherits(fit, "error")) return(NA_real_)
  E <- tryCatch(as.matrix(fit$rlm$residuals), error = function(e) NULL)
  if (is.null(E) || nrow(E) < 5) return(NA_real_)
  m <- ncol(E)
  if (!is.null(m_expected) && m != m_expected) return(NA_real_)
  Teff <- nrow(E)
  S <- crossprod(E) / Teff
  ld <- tryCatch(as.numeric(determinant(S, logarithm = TRUE)$modulus), error = function(e) NA_real_)
  if (!is.finite(ld)) return(NA_real_)
  -0.5 * Teff * (m * log(2 * pi) + ld + m)
})

count_params_vecm <- get0("count_params_vecm", ifnotfound = function(m, p, r, ecdet) {
  k_alpha <- m * r
  k_beta  <- m * r
  k_gamma <- m * m * max(p - 1, 0)
  k_det   <- if (ecdet == "const") r else 0
  list(k_total = k_alpha + k_beta + k_gamma + k_det)
})

calc_ic <- get0("calc_ic", ifnotfound = function(loglik, T, k_total) {
  bic <- -2 * loglik + k_total * log(T)
  pic <- -2 * loglik + k_total * log(T) * log(log(T))
  list(PIC = pic, BIC = bic)
})

# ------------------------------------------------------------
# Logging discipline (LOCKED): use open_log() from 99_utils.R
# ------------------------------------------------------------

# ------------------------------------------------------------
# v4 Basis: raw powers and QR orthogonalization (NO standardization)
# ------------------------------------------------------------
basis_apply_rawpowers <- function(df, e_col = "e", degree = 2, prefix = "Q") {
  e <- as.numeric(df[[e_col]])
  if (any(!is.finite(e))) stop("basis_apply_rawpowers: e has non-finite values after filtering", call. = FALSE)
  for (j in seq_len(degree)) df[[paste0(prefix, j)]] <- e^j
  df
}

basis_build_rawpowers_qr <- function(df_full, e_col = "e", degree = 2) {
  e <- df_full[[e_col]]
  e <- as.numeric(e[is.finite(e)])
  if (length(e) < max(10, 5 * degree)) stop("basis_build_rawpowers_qr: too few finite e values", call. = FALSE)
  
  X <- sapply(seq_len(degree), function(j) e^j)
  colnames(X) <- paste0("e^", seq_len(degree))
  
  qrX <- qr(X)
  Q <- qr.Q(qrX)  # orthonormal columns
  
  # A solves: X %*% A = Q
  A <- solve(crossprod(X), crossprod(X, Q))
  
  list(type = "rawpowers_qr", e_col = e_col, degree = degree, A = A)
}

basis_apply_rawpowers_qr <- function(df, basis, prefix = "Q") {
  e <- as.numeric(df[[basis$e_col]])
  if (any(!is.finite(e))) stop("basis_apply_rawpowers_qr: e has non-finite values after filtering", call. = FALSE)
  X <- sapply(seq_len(basis$degree), function(j) e^j)
  Q <- X %*% basis$A
  Q <- as.matrix(Q)
  colnames(Q) <- paste0(prefix, seq_len(basis$degree))
  cbind(df, as.data.frame(Q))
}

build_basis <- function(df_full, e_col, degree, orthogonalize = TRUE) {
  if (isTRUE(orthogonalize)) {
    b <- basis_build_rawpowers_qr(df_full, e_col = e_col, degree = degree)
    b$basis_name <- paste0("qr_rawpowers_deg", degree)
    return(b)
  }
  list(type = "raw_powers", e_col = e_col, degree = degree, basis_name = paste0("rawpowers_deg", degree))
}

apply_basis <- function(df, basis, spec_type) {
  df$e_raw <- as.numeric(df[[CONFIG$e_col]])
  
  if (identical(spec_type, "linear_affine_theta")) return(df)
  
  if (identical(basis$type, "rawpowers_qr")) return(basis_apply_rawpowers_qr(df, basis, prefix = "Q"))
  if (identical(basis$type, "raw_powers"))   return(basis_apply_rawpowers(df, e_col = basis$e_col, degree = basis$degree, prefix = "Q"))
  
  stop("apply_basis: unknown basis$type", call. = FALSE)
}

# ------------------------------------------------------------
# System builder
# ------------------------------------------------------------
build_system_engine <- function(df, spec_type, degree, y_col="log_y", k_col="log_k") {
  
  if (identical(spec_type, "linear_affine_theta")) {
    need <- c(y_col, k_col, "e_raw")
    miss <- setdiff(need, names(df))
    if (length(miss)) stop("Missing column(s): ", paste(miss, collapse=", "), call.=FALSE)
    
    X <- data.frame(
      log_y  = df[[y_col]],
      log_k  = df[[k_col]],
      e_logK = df[["e_raw"]] * df[[k_col]]
    )
    ok <- stats::complete.cases(X)
    X <- X[ok, , drop=FALSE]
    return(list(Y=as.matrix(X), var_names=colnames(X), ok_idx=which(ok)))
  }
  
  need <- c(y_col, k_col, paste0("Q", seq_len(degree)))
  miss <- setdiff(need, names(df))
  if (length(miss)) stop("Missing column(s): ", paste(miss, collapse=", "), call.=FALSE)
  
  X <- data.frame(log_y=df[[y_col]], log_k=df[[k_col]])
  if (isTRUE(CONFIG$INCLUDE_E_RAW %||% FALSE)) X$e_raw <- df[["e_raw"]]
  
  for (j in seq_len(degree)) {
    X[[paste0("Q", j, "_logK")]] <- df[[paste0("Q", j)]] * df[[k_col]]
  }
  
  ok <- stats::complete.cases(X)
  X <- X[ok, , drop=FALSE]
  list(Y=as.matrix(X), var_names=colnames(X), ok_idx=which(ok))
}

# ------------------------------------------------------------
# Gate rule + Lattice
# ------------------------------------------------------------
feasible_for_ca_jo <- function(T, m, p, ecdet) {
  T_eff <- T - p
  min_eff <- max(20, 5*m + 5*p + ifelse(ecdet=="const", 5, 0))
  list(ok = is.finite(T_eff) && T_eff > min_eff, T_eff=T_eff, min_eff=min_eff)
}

build_lattice <- function(sys_list, p_min, p_max, ecdet_set) {
  out <- list()
  for (w in names(sys_list)) {
    Y <- sys_list[[w]]$Y
    T_w <- nrow(Y); m_w <- ncol(Y)
    out[[length(out)+1L]] <- tidyr::expand_grid(
      window=w, ecdet=ecdet_set, p=p_min:p_max, r=0:(m_w-1L)
    ) |>
      dplyr::mutate(T=T_w, m=m_w, K=p+1L)
  }
  dplyr::bind_rows(out) |>
    dplyr::mutate(
      window=as.character(.data$window),
      ecdet=as.character(.data$ecdet),
      p=as.integer(.data$p),
      r=as.integer(.data$r),
      T=as.integer(.data$T),
      m=as.integer(.data$m),
      K=as.integer(.data$K)
    )
}

# ------------------------------------------------------------
# Init + data
# ------------------------------------------------------------
set_seed_deterministic(CONFIG$seed)

ROOT_OUT <- here::here(CONFIG$OUT_ROOT)
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  meta = file.path(ROOT_OUT, "meta"),
  logs = file.path(ROOT_OUT, "logs")
)
ensure_dirs(DIRS$csv, DIRS$meta, DIRS$logs)

LBL_APPX <- CONFIG$OUT_LABELS$appx %||% "APPX"
VERBOSE_CONSOLE  <- isTRUE(CONFIG$VERBOSE_CONSOLE %||% TRUE)
HEARTBEAT_EVERY  <- as.integer(CONFIG$HEARTBEAT_EVERY %||% 25L)
if (!is.finite(HEARTBEAT_EVERY) || HEARTBEAT_EVERY < 1) HEARTBEAT_EVERY <- 25L

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
  dplyr::filter(is.finite(.data$year), is.finite(.data$log_y), is.finite(.data$log_k), is.finite(.data$e))

filter_window_years <- function(df, key, year_col = "year") {
  rng <- CONFIG$WINDOWS_LOCKED[[key]]
  df |>
    dplyr::filter(.data[[year_col]] >= rng[1], .data[[year_col]] <= rng[2])
}

windows_raw <- list(
  full         = filter_window_years(df0, "full", year_col="year"),
  fordism      = filter_window_years(df0, "fordism", year_col="year"),
  post_fordism = filter_window_years(df0, "post_fordism", year_col="year")
)

# ============================================================
# RUN
# ============================================================
for (spec_name in names(CONFIG$SPECS)) {
  
  spec_type <- CONFIG$SPECS[[spec_name]]$type
  degree    <- CONFIG$SPECS[[spec_name]]$degree
  
  ORTHO_SET <- if (identical(spec_type, "linear_affine_theta")) c(FALSE) else CONFIG$ORTHO_TOGGLE
  
  for (ORTHO in ORTHO_SET) {
    
    basis_tag <- if (identical(spec_type, "linear_affine_theta")) "raw" else if (ORTHO) "ortho" else "raw"
    run_tag   <- paste0(spec_name, "_", basis_tag)
    # log file handled by open_log(run_tag, CONFIG, DIRS$logs)
    
    if (VERBOSE_CONSOLE) {
      cat("\n>>> ABOUT TO RUN:", run_tag, "@", format(Sys.time()), "\n")
      flush.console()
    }
    
    close_log <- NULL
    
    tryCatch({
      
      close_log <- open_log(run_tag = paste0(LBL_APPX, "_", run_tag), config = CONFIG, dir_logs = DIRS$logs)
      on.exit(if (is.function(close_log)) close_log(), add = TRUE)
      
      cat("=== Engine start:", run_tag, "===\n")
      cat("Spec:", spec_name, "| type:", spec_type, "| degree:", degree, "| ORTHO:", ORTHO, "\n\n")
      
      basis <- if (!identical(spec_type, "linear_affine_theta")) {
        build_basis(windows_raw$full, e_col="e", degree=degree, orthogonalize=ORTHO)
      } else {
        list(type="none", e_col="e", degree=1L, basis_name="none")
      }
      
      writeLines(
        c(
          paste0("run_tag=", run_tag),
          paste0("spec=", spec_name),
          paste0("basis=", basis_tag),
          paste0("spec_type=", spec_type),
          paste0("degree=", degree),
          paste0("basis_type=", basis$type),
          paste0("basis_name=", basis$basis_name %||% NA_character_),
          paste0("e_raw_locked=TRUE")
        ),
        con = file.path(DIRS$meta, paste0(LBL_APPX, "_S0_basis_", run_tag, ".txt"))
      )
      
      if (identical(basis$type, "rawpowers_qr")) {
        saveRDS(basis$A, file.path(DIRS$meta, paste0(LBL_APPX, "_A_matrix_", run_tag, ".rds")))
        utils::write.csv(basis$A,
                         file.path(DIRS$meta, paste0(LBL_APPX, "_A_matrix_", run_tag, ".csv")),
                         row.names = FALSE)
      }
      
      windows_b <- lapply(windows_raw, apply_basis, basis=basis, spec_type=spec_type)
      sys_list  <- lapply(windows_b, build_system_engine, spec_type=spec_type, degree=degree, y_col="log_y", k_col="log_k")
      
      ref_win <- if ("full" %in% names(sys_list)) "full" else names(sys_list)[1]
      writeLines(
        c(
          paste0("run_tag=", run_tag),
          paste0("vars=", paste(sys_list[[ref_win]]$var_names, collapse=", "))
        ),
        con = file.path(DIRS$meta, paste0(LBL_APPX, "_S0_systemvars_", run_tag, ".txt"))
      )
      
      m_vec <- vapply(sys_list, function(s) ncol(s$Y), integer(1))
      if (length(unique(m_vec)) != 1) stop("System dimension differs across windows; check missingness.", call.=FALSE)
      m_sys <- unique(m_vec)
      cat("System dimension m =", m_sys, "\n\n")
      
      lattice <- build_lattice(sys_list, CONFIG$P_MIN, CONFIG$P_MAX_EXPLORATORY, CONFIG$ECDET_LOCKED)
      
      feas_rows <- list()
      for (w in names(sys_list)) {
        T_w <- nrow(sys_list[[w]]$Y)
        for (ec in CONFIG$ECDET_LOCKED) {
          feas <- integer(0)
          for (p in CONFIG$P_MIN:CONFIG$P_MAX_EXPLORATORY) {
            g <- feasible_for_ca_jo(T=T_w, m=m_sys, p=p, ecdet=ec)
            if (isTRUE(g$ok)) feas <- c(feas, p)
          }
          feas_rows[[length(feas_rows)+1L]] <- data.frame(
            window=w, ecdet=ec, T=T_w, m=m_sys,
            p_max_feasible=if (length(feas)==0) NA_integer_ else max(feas),
            stringsAsFactors=FALSE
          )
        }
      }
      feasible_df <- dplyr::bind_rows(feas_rows)
      readr::write_csv(feasible_df, file.path(DIRS$csv, paste0(LBL_APPX, "_S1_feasible_pmax_by_window_ecdet_", run_tag, ".csv")))
      
      COMMON_P_MAX <- suppressWarnings(min(feasible_df$p_max_feasible, na.rm=TRUE))
      if (!is.finite(COMMON_P_MAX)) COMMON_P_MAX <- NA_integer_
      cat("COMMON_P_MAX =", COMMON_P_MAX, "\n\n")
      
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
        
        if (i %% HEARTBEAT_EVERY == 0) {
          cat("...progress:", run_tag, "| i=", i, "/", nrow(keys),
              "| window=", w, "ecdet=", ec, "p=", p,
              "|", format(Sys.time()), "\n")
        }
        
        gate <- feasible_for_ca_jo(T=T_w, m=m_w, p=p, ecdet=ec)
        
        cs <- data.frame(
          window=w, ecdet=ec, p=p, T=T_w, m=m_w, K=K,
          gate_ok=isTRUE(gate$ok),
          gate_T_eff=gate$T_eff,
          gate_min_eff=gate$min_eff,
          runtime_ok=FALSE,
          runtime_reason=NA_character_,
          stringsAsFactors=FALSE
        )
        
        if (!isTRUE(gate$ok)) {
          cs$runtime_reason <- paste0("gate_fail: T_eff=", gate$T_eff, " <= min_eff=", gate$min_eff)
          cell_rows[[i]] <- cs
          next
        }
        
        jo_tr <- tryCatch(
          urca::ca.jo(sys_list[[w]]$Y, type="trace", ecdet=ec, K=K, spec=CONFIG$johansen_spec),
          error=function(e) e
        )
        
        if (inherits(jo_tr, "error")) {
          cs$runtime_reason <- paste0("runtime_fail: ", conditionMessage(jo_tr))
          cell_rows[[i]] <- cs
          next
        }
        
        ll_by_r <- rep(NA_real_, m_w)
        for (rr in 0:(m_w-1L)) ll_by_r[rr+1L] <- loglik_from_cajorls(jo_tr, r=rr, m_expected=m_w)
        
        if (all(!is.finite(ll_by_r))) {
          cs$runtime_reason <- "runtime_fail: cajorls logLik all non-finite"
          cell_rows[[i]] <- cs
          next
        }
        
        cs$runtime_ok <- TRUE
        cell_rows[[i]] <- cs
        
        rr_tbl <- data.frame(window=w, ecdet=ec, p=p, r=0:(m_w-1L), logLik=ll_by_r, stringsAsFactors=FALSE) |>
          dplyr::mutate(
            k_total = vapply(.data$r, function(rrr) count_params_vecm(m=m_w, p=p, r=rrr, ecdet=ec)$k_total, numeric(1)),
            PIC = mapply(function(ll, kk) if (is.finite(ll)) calc_ic(ll, T_w, kk)$PIC else NA_real_, .data$logLik, .data$k_total),
            BIC = mapply(function(ll, kk) if (is.finite(ll)) calc_ic(ll, T_w, kk)$BIC else NA_real_, .data$logLik, .data$k_total)
          )
        
        rank_rows[[length(rank_rows)+1L]] <- rr_tbl
      }
      
      cell_tbl <- dplyr::bind_rows(cell_rows)
      rr_tbl <- if (length(rank_rows)>0) dplyr::bind_rows(rank_rows) else dplyr::tibble()
      
      gridU <- lattice |>
        dplyr::left_join(cell_tbl, by=c("window","ecdet","p","T","m","K")) |>
        dplyr::left_join(rr_tbl,   by=c("window","ecdet","p","r")) |>
        dplyr::mutate(
          comparable_p = ifelse(is.na(COMMON_P_MAX), FALSE, (.data$p <= COMMON_P_MAX)),
          status = dplyr::case_when(
            !.data$gate_ok ~ "gate_fail",
            .data$gate_ok & !.data$runtime_ok ~ "runtime_fail",
            .data$gate_ok & .data$runtime_ok & is.finite(.data$PIC) ~ "computed",
            TRUE ~ "missing"
          ),
          PIC_obs = ifelse(.data$status=="computed", .data$PIC, NA_real_),
          BIC_obs = ifelse(.data$status=="computed", .data$BIC, NA_real_)
        ) |>
        dplyr::mutate(spec=spec_name, basis=basis_tag)
      
      out_csv <- file.path(DIRS$csv, paste0(LBL_APPX, "_grid_pic_table_", run_tag, "_unrestricted.csv"))
      readr::write_csv(gridU, out_csv)
      
      cat("\nWrote:", out_csv, "\n")
      cat("=== Engine completed OK:", run_tag, "===\n")
      
    }, error=function(e) {
      
      cat("RUN FAILED:", run_tag, "\n", conditionMessage(e), "\n")
      
    }, finally={
      
      if (is.function(close_log)) close_log()
      
      if (sink.number(type="output") > 0) {
        message("WARNING: OUTPUT sinks remained open after run. out=", sink.number(type="output"))
      }
    })
  }
}
