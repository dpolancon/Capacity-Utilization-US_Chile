# ============================================================
# ChaoGrid_Engine_Q2_vSurfaceEverywhere.R
#
# Object:
#   Build the FULL intended lattice over (p,r) for each window × ecdet.
#   Never drop cells. The lattice is the object.
#
# Layers recorded:
#   - gate_ok       : theoretical feasibility gate (admissibility layer)
#   - runtime_ok    : estimation succeeded (PIC_obs exists only if TRUE)
#   - PIC_obs/BIC_obs: observed IC when runtime succeeds
#   - comparable_p  : metadata for common p-range comparability
#
# Canonical output used by Report:
#   output/ChaoGrid/csv/grid_pic_table_Q2_unrestricted.csv
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","readxl","dplyr","tidyr","urca","readr")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

# ----------------------------
# S0 Paths
# ----------------------------
ROOT_OUT <- here::here("output/ChaoGrid")
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  meta = file.path(ROOT_OUT, "meta"),
  logs = file.path(ROOT_OUT, "logs")
)
dir.create(DIRS$csv,  recursive = TRUE, showWarnings = FALSE)
dir.create(DIRS$meta, recursive = TRUE, showWarnings = FALSE)
dir.create(DIRS$logs, recursive = TRUE, showWarnings = FALSE)

log_file <- file.path(DIRS$logs, "engine_log_Q2_vSurfaceEverywhere.txt")
sink(log_file, split = TRUE)
on.exit(sink(), add = TRUE)

cat("=== Engine start: Q2 vSurfaceEverywhere ===\n")
cat("Project root:", here::here(), "\n")
cat("Output root :", ROOT_OUT, "\n\n")

set.seed(123)

# ----------------------------
# S1 Windows + deterministics
# ----------------------------
WINDOWS_LOCKED <- list(
  full        = c(-Inf, Inf),
  fordism     = c(-Inf, 1973),
  post_fordism= c(1974, Inf)
)
ECDET_LOCKED <- c("none","const")

filter_window_years <- function(df, key, year_col = "year") {
  rng <- WINDOWS_LOCKED[[key]]
  df |>
    dplyr::filter(.data[[year_col]] >= rng[1], .data[[year_col]] <= rng[2])
}

# ----------------------------
# S2 Load data
# ----------------------------
data_path <- here::here("data/processed/ddbb_cu_US_kgr.xlsx")
ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

df0 <- dplyr::transmute(
  ddbb_us,
  year  = .data$year,
  log_y = log(.data$Yrgdp),
  log_k = log(.data$KGCRcorp),
  e     = .data$e
) |>
  dplyr::arrange(.data$year) |>
  dplyr::filter(!is.na(.data$year), !is.na(.data$log_y), !is.na(.data$log_k), !is.na(.data$e))

windows <- list(
  full        = filter_window_years(df0, "full"),
  fordism     = filter_window_years(df0, "fordism"),
  post_fordism= filter_window_years(df0, "post_fordism")
)

cat("Windows built:\n")
cat("N(full)=", nrow(windows$full),
    " N(fordism)=", nrow(windows$fordism),
    " N(post_fordism)=", nrow(windows$post_fordism), "\n\n")

# ----------------------------
# S3 Q2 basis (global scaling on FULL)
# ----------------------------
build_q2_basis <- function(df_full, e_col = "e") {
  e <- df_full[[e_col]]
  mu <- mean(e, na.rm = TRUE)
  sdv <- stats::sd(e, na.rm = TRUE)
  if (!is.finite(sdv) || sdv <= 0) stop("e sd is non-positive.", call.=FALSE)
  list(e_col=e_col, mean_full=mu, sd_full=sdv)
}

apply_q2_basis <- function(df, basis) {
  e_std <- (df[[basis$e_col]] - basis$mean_full) / basis$sd_full
  df |>
    dplyr::mutate(
      e_std  = e_std,
      e2_std = e_std^2,
      elogk  = e_std * .data$log_k,
      e2logk = e2_std * .data$log_k
    )
}

basis <- build_q2_basis(windows$full, e_col = "e")
writeLines(
  c("Q2 basis meta",
    paste0("e_col=", basis$e_col),
    paste0("mean_full=", signif(basis$mean_full, 8)),
    paste0("sd_full=", signif(basis$sd_full, 8))),
  con = file.path(DIRS$meta, "S0_basis_Q2_meta.txt")
)

windows_basis <- lapply(windows, apply_q2_basis, basis = basis)

# ----------------------------
# S4 System matrix Y (m=4)
# ----------------------------
build_system_Q2 <- function(df) {
  Y <- as.matrix(df[, c("log_y","log_k","elogk","e2logk")])
  colnames(Y) <- c("log_y","log_k","e_logk","e2_logk")
  list(Y = Y, var_names = colnames(Y))
}

sys_list <- lapply(windows_basis, build_system_Q2)
m_vec <- vapply(sys_list, function(s) ncol(s$Y), integer(1))
if (length(unique(m_vec)) != 1) stop("System dimension differs across windows.", call.=FALSE)
m_sys <- unique(m_vec)
cat("System dimension m =", m_sys, "\n\n")

# ----------------------------
# S5 Gate: feasibility for ca.jo
# ----------------------------
feasible_for_ca_jo <- function(T, m, p, ecdet) {
  T_eff  <- T - p
  min_eff <- max(20, 5*m + 5*p + ifelse(ecdet=="const", 5, 0))
  list(ok = is.finite(T_eff) && T_eff > min_eff, T_eff = T_eff, min_eff = min_eff)
}

# ----------------------------
# S6 Johansen runner
# ----------------------------
run_ca_jo_pair <- function(Y, ecdet, K, spec = "transitory") {
  jo_tr <- urca::ca.jo(Y, type = "trace", ecdet = ecdet, K = K, spec = spec)
  jo_ei <- urca::ca.jo(Y, type = "eigen", ecdet = ecdet, K = K, spec = spec)
  list(trace = jo_tr, eigen = jo_ei)
}

# ----------------------------
# S7 LogLik from cajorls residuals
# ----------------------------
loglik_from_cajorls <- function(jo_obj_trace, r, T_eff) {
  cr <- tryCatch(urca::cajorls(jo_obj_trace, r = r), error = function(e) NULL)
  if (is.null(cr)) return(NA_real_)
  res <- cr$rlm$residuals
  if (is.null(res)) return(NA_real_)
  res <- as.matrix(res)
  m <- ncol(res)
  if (nrow(res) < 5 || m < 1) return(NA_real_)
  
  Sigma <- stats::cov(res)
  detS <- tryCatch(det(Sigma), error = function(e) NA_real_)
  if (!is.finite(detS) || detS <= 0) return(NA_real_)
  
  ll <- - (T_eff/2) * (m*log(2*pi) + log(detS) + m)
  ll
}

# ----------------------------
# S8 Params + IC
# ----------------------------
count_params_vecm <- function(m, p, r, ecdet) {
  k_sr <- m*m*max(0, p-1)
  k_ab <- 2*m*r
  k_det <- if (ecdet == "const") m else 0
  k_total <- k_sr + k_ab + k_det
  list(k_total = k_total)
}

calc_ic <- function(ll, T, k) {
  BIC <- -2*ll + k*log(T)
  PIC <- -2*ll + k*log(T)*log(log(T))
  list(PIC = PIC, BIC = BIC)
}

# ----------------------------
# S9 Lattice + compute layer
# ----------------------------
P_MIN <- 1L
P_MAX_EXPLORATORY <- 7L

build_lattice <- function(sys_list, p_min, p_max, ecdet_set) {
  out <- list()
  for (w in names(sys_list)) {
    Y <- sys_list[[w]]$Y
    T_w <- nrow(Y); m_w <- ncol(Y)
    out[[length(out)+1]] <- tidyr::expand_grid(
      window = w,
      ecdet  = ecdet_set,
      p      = p_min:p_max,
      r      = 0:(m_w-1)
    ) |>
      dplyr::mutate(T = T_w, m = m_w, K = p + 1L)
  }
  dplyr::bind_rows(out) |>
    dplyr::mutate(window = as.character(window),
                  ecdet  = as.character(ecdet),
                  p = as.integer(p),
                  r = as.integer(r),
                  T = as.integer(T),
                  m = as.integer(m),
                  K = as.integer(K))
}

lattice <- build_lattice(sys_list, P_MIN, P_MAX_EXPLORATORY, ECDET_LOCKED)

# comparability metadata (common pmax)
feas_rows <- list()
for (w in names(sys_list)) {
  T_w <- nrow(sys_list[[w]]$Y)
  for (ec in ECDET_LOCKED) {
    feas <- integer(0)
    for (p in P_MIN:P_MAX_EXPLORATORY) {
      g <- feasible_for_ca_jo(T = T_w, m = m_sys, p = p, ecdet = ec)
      if (isTRUE(g$ok)) feas <- c(feas, p)
    }
    feas_rows[[length(feas_rows)+1]] <- data.frame(
      window = as.character(w), ecdet = as.character(ec),
      T = T_w, m = m_sys,
      p_max_feasible = if (length(feas)==0) NA_integer_ else max(feas)
    )
  }
}
feasible_df <- dplyr::bind_rows(feas_rows)
readr::write_csv(feasible_df, file.path(DIRS$csv, "S1_feasible_pmax_by_window_ecdet_Q2.csv"))

COMMON_P_MAX <- min(feasible_df$p_max_feasible, na.rm = TRUE)
writeLines(
  c("COMMON_P_MAX selection (Q2)",
    paste0("COMMON_P_MAX = ", COMMON_P_MAX),
    "Computed as min p_max_feasible across windows × ecdet.",
    "Note: comparability is metadata; unrestricted lattice still spans P_MAX_EXPLORATORY."),
  con = file.path(DIRS$meta, "S1_COMMON_P_MAX_note.txt")
)
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
  
  jo_pair <- tryCatch(
    run_ca_jo_pair(sys_list[[w]]$Y, ecdet = ec, K = K, spec = "transitory"),
    error = function(e) e
  )
  if (inherits(jo_pair, "error")) {
    cs$runtime_reason <- paste0("runtime_fail: ", conditionMessage(jo_pair))
    cell_rows[[i]] <- cs
    next
  }
  
  jo_tr <- jo_pair$trace
  
  ll_by_r <- rep(NA_real_, m_w)
  for (rr in 0:(m_w-1)) {
    ll_by_r[rr+1] <- loglik_from_cajorls(jo_tr, r = rr, T_eff = gate$T_eff)
  }
  
  if (all(!is.finite(ll_by_r))) {
    cs$runtime_reason <- "runtime_fail: cajorls logLik all non-finite"
    cell_rows[[i]] <- cs
    next
  }
  
  cs$runtime_ok <- TRUE
  cell_rows[[i]] <- cs
  
  rr_tbl <- data.frame(
    window = w, ecdet = ec, p = p, r = 0:(m_w-1),
    logLik = ll_by_r,
    stringsAsFactors = FALSE
  ) |>
    dplyr::mutate(
      k_total = vapply(r, function(rk) count_params_vecm(m=m_w, p=p, r=rk, ecdet=ec)$k_total, numeric(1)),
      PIC = mapply(function(ll, kk) if (is.finite(ll)) calc_ic(ll, T_w, kk)$PIC else NA_real_, logLik, k_total),
      BIC = mapply(function(ll, kk) if (is.finite(ll)) calc_ic(ll, T_w, kk)$BIC else NA_real_, logLik, k_total)
    )
  
  rank_rows[[length(rank_rows)+1]] <- rr_tbl
}

cell_tbl <- dplyr::bind_rows(cell_rows)
rr_tbl   <- if (length(rank_rows)>0) dplyr::bind_rows(rank_rows) else data.frame()

gridU <- lattice |>
  dplyr::left_join(cell_tbl, by = c("window","ecdet","p","T","m","K")) |>
  dplyr::left_join(rr_tbl,   by = c("window","ecdet","p","r")) |>
  dplyr::mutate(
    comparable_p = (p <= COMMON_P_MAX),
    status = dplyr::case_when(
      !gate_ok ~ "gate_fail",
      gate_ok & !runtime_ok ~ "runtime_fail",
      gate_ok & runtime_ok & is.finite(PIC) ~ "computed",
      TRUE ~ "missing"
    ),
    PIC_obs = ifelse(status=="computed", PIC, NA_real_),
    BIC_obs = ifelse(status=="computed", BIC, NA_real_)
  ) |>
  dplyr::mutate(window = as.character(window),
                ecdet  = as.character(ecdet))

readr::write_csv(gridU, file.path(DIRS$csv, "grid_pic_table_Q2_unrestricted.csv"))
cat("Wrote:", file.path(DIRS$csv, "grid_pic_table_Q2_unrestricted.csv"), "\n")

gridR <- gridU |>
  dplyr::filter(comparable_p, status=="computed", is.finite(PIC_obs)) |>
  dplyr::mutate(grid = "comparable")
readr::write_csv(gridR, file.path(DIRS$csv, "grid_pic_table_Q2_restricted.csv"))

cat("\n=== Engine completed OK ===\n")
