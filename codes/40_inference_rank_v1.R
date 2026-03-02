############################################################
# 40_inference_rank.R
#
# Rank bootstrap inference (r = 0 vs r >= 1)
# tsDyn-based implementation — CLEAN & FROZEN
#
# FROZEN RULE:
#   If VECM(lag = p),
#   then r = 0 null uses:
#       lineVar(..., lag = p, I = "diff")
#
# No lag remapping.
# No helpers wrapping estimation.
#
# Option A:
#   - Windows: full, fordism, post_fordism
#   - Spec: Q2 only
#   - Basis: raw, ortho
#   - DSR fixed = "none"
#   - DLR toggle = c("none","const")
#
# Bootstrap:
#   - "iid"  = residual resampling
#   - "wild" = Rademacher wild bootstrap
############################################################

rm(list = ls()); gc()

# ------------------------------------------------------------
# Local utilities (base R only)
# ------------------------------------------------------------
`%||%` <- function(x, y) if (is.null(x)) y else x

.is_abs_path <- function(p) {
  p <- as.character(p %||% "")
  grepl("^[A-Za-z]:[\\\\/]", p) || grepl("^[\\\\/]", p) || grepl("^\\\\\\\\", p)
}

.find_project_root <- function(start = getwd(),
                               sentinel = file.path("codes","10_config_tsdyn.R"),
                               max_up = 12L) {
  cur <- normalizePath(start, winslash = "/", mustWork = FALSE)
  for (i in 0:max_up) {
    if (file.exists(file.path(cur, sentinel))) return(cur)
    parent <- normalizePath(file.path(cur, ".."), winslash = "/", mustWork = FALSE)
    if (identical(parent, cur)) break
    cur <- parent
  }
  stop("Could not locate project root (missing sentinel: ", sentinel, ") from: ", start, call. = FALSE)
}

.pkg_local <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf("Package '%s' is required but not installed.", pkg), call. = FALSE)
  }
  invisible(TRUE)
}

# ------------------------------------------------------------
# Resolve project root + source config/utils
# ------------------------------------------------------------
ROOT <- .find_project_root()

source(file.path(ROOT, "codes", "10_config_tsdyn.R"))
source(file.path(ROOT, "codes", "99_tsdyn_utils.R"))

.pkg_local("tsDyn")
.pkg_local("readxl")
.pkg_local("dplyr")

set.seed(CONFIG$seed)

# ============================================================
# USER CONTROLS
# ============================================================

BOOTSTRAP_TYPE <- "iid"   # "iid" or "wild"
B              <- 4999L
INFER_DLR_SET  <- c("none","const")

P_VECM  <- as.integer(CONFIG$p_vecm_default)
DSR_FIX <- "none"

FAIL_THRESHOLD <- CONFIG$fail_threshold %||% 0.10

OUT_ROOT <- if (.is_abs_path(CONFIG$OUT_RANK)) {
  CONFIG$OUT_RANK
} else {
  file.path(ROOT, CONFIG$OUT_RANK %||% "output/InferenceRank_tsDyn")
}

LOG_PATH <- file.path(OUT_ROOT, "log", "40_inference_rank_log.txt")
OUT_CSV  <- file.path(OUT_ROOT, "csv", "INFER_rank_bootstrap.csv")
OUT_RDS  <- file.path(OUT_ROOT, "rds", "INFER_rank_bootstrap_objects.rds")

dir.create(dirname(LOG_PATH), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(OUT_CSV),  recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(OUT_RDS),  recursive = TRUE, showWarnings = FALSE)

log_line(LOG_PATH, "=== 40_inference_rank started ===")

# ============================================================
# DATA LOAD
# ============================================================

DATA_PATH <- if (.is_abs_path(CONFIG$data_file)) CONFIG$data_file else file.path(ROOT, CONFIG$data_file)

df_raw <- readxl::read_excel(DATA_PATH, sheet = CONFIG$data_sheet)

df_raw <- df_raw %>%
  dplyr::rename(
    year = !!CONFIG$year_col,
    Y    = !!CONFIG$y_col,
    K    = !!CONFIG$k_col,
    e    = !!CONFIG$e_col
  ) %>%
  dplyr::mutate(
    logY    = log(Y),
    logK    = log(K),
    e_logK  = e * logK,
    e2_logK = (e^2) * logK
  )

# ============================================================
# STATE BUILDER (Q2 only)
# ============================================================

build_state_q2 <- function(df, ortho = FALSE) {
  M_poly <- as.matrix(df[, c("e_logK","e2_logK")])
  if (ortho) M_poly <- qr_ortho_basis(M_poly)
  X <- cbind(
    logY = df$logY,
    logK = df$logK,
    M_poly
  )
  storage.mode(X) <- "double"
  colnames(X)[3:4] <- if (ortho) colnames(M_poly) else c("e_logK","e2_logK")
  X
}

# ============================================================
# Gamma extraction (robust to tsDyn coef shapes/names)
# ============================================================

extract_Gamma_array <- function(fit_r0, varnames, p_lag) {
  cl <- tryCatch(coef(fit_r0), error = function(e) NULL)
  if (is.null(cl) || length(cl) == 0) return(NULL)
  
  # tsDyn::lineVar coef() may return a matrix (eq × regressors) instead of a list
  if (is.matrix(cl)) {
    cl_mat <- cl
    cl <- lapply(seq_len(nrow(cl_mat)), function(i) {
      v <- as.numeric(cl_mat[i, ])
      names(v) <- colnames(cl_mat)
      v
    })
  }
  
  if (!is.list(cl) || length(cl) == 0) return(NULL)
  
  m <- length(varnames)
  G <- array(0, dim = c(m, m, p_lag),
             dimnames = list(eq = varnames, x = varnames, lag = paste0("L", seq_len(p_lag))))
  
  # try to match a regressor name for v at lag j in a named coefficient vector
  pick_coef <- function(vals, nms, vname, j) {
    if (is.null(nms) || length(nms) == 0) return(NA_real_)
    
    # allow optional leading d/D (because I="diff" may name regressors with d prefix)
    # accept separators ".", "_", ":" and allow "l1" or "L1"
    v <- gsub("([\\^\\$\\.|\\(|\\)|\\[\\]|\\+\\*\\?\\\\])", "\\\\\\1", vname)
    pat_strict <- paste0("^(d|D)?", v, "(\\.|_|:)?l", j, "$")
    pat_loose  <- paste0("^(d|D)?", v, ".*(\\.|_|:)?l", j, "($|[^0-9])")
    
    idx <- which(grepl(pat_strict, nms, ignore.case = TRUE))
    if (length(idx) == 0) idx <- which(grepl(pat_loose, nms, ignore.case = TRUE))
    if (length(idx) == 0) return(NA_real_)
    vals[idx[1]]
  }
  
  for (i in seq_len(m)) {
    ci <- cl[[i]]
    
    if (is.matrix(ci)) {
      vals <- as.numeric(ci)
      nms  <- rownames(ci)
    } else {
      vals <- as.numeric(ci)
      nms  <- names(ci)
    }
    
    filled_any <- FALSE
    
    if (!is.null(nms)) {
      for (j in seq_len(p_lag)) {
        for (k in seq_len(m)) {
          v <- pick_coef(vals, nms, varnames[k], j)
          if (is.finite(v)) {
            G[i, k, j] <- v
            filled_any <- TRUE
          }
        }
      }
    }
    
    # fallback: assume stacked by lag with only endogenous regressors
    if (!filled_any) {
      need <- m * p_lag
      if (length(vals) < need) return(NULL)
      for (j in seq_len(p_lag)) {
        idx <- ((j - 1L) * m + 1L):(j * m)
        G[i, , j] <- vals[idx]
      }
    }
  }
  
  G
}

# ============================================================
# BOOTSTRAP CORE
# ============================================================

bootstrap_rank_test <- function(X, DLR, B, bootstrap_type) {
  
  m <- ncol(X)
  varnames <- colnames(X)
  
  # ------------------------------------------------------------
  # r = 0 model: VAR in differences, lag = P_VECM
  # ------------------------------------------------------------
  fit_r0 <- tryCatch(
    tsDyn::lineVar(
      data    = X,
      lag     = P_VECM,
      include = DSR_FIX,
      model   = "VAR",
      I       = "diff"
    ),
    error = function(e) NULL
  )
  
  if (is.null(fit_r0)) return(list(ok = FALSE, reason = "R0_FAIL"))
  
  ll_r0 <- tryCatch(as.numeric(logLik(fit_r0)), error = function(e) NA_real_)
  if (!is.finite(ll_r0)) return(list(ok = FALSE, reason = "R0_LL_FAIL"))
  
  U_hat <- tryCatch(as.matrix(residuals(fit_r0)), error = function(e) NULL)
  if (is.null(U_hat)) return(list(ok = FALSE, reason = "R0_RESID_FAIL"))
  
  T_eff <- nrow(U_hat)
  
  Gamma_arr <- extract_Gamma_array(fit_r0, varnames = varnames, p_lag = P_VECM)
  if (is.null(Gamma_arr)) return(list(ok = FALSE, reason = "R0_GAMMA_EXTRACT_FAIL"))
  
  # ------------------------------------------------------------
  # r = 1 model: VECM
  # ------------------------------------------------------------
  fit_r1 <- tryCatch(
    tsDyn::VECM(
      X,
      lag       = P_VECM,
      r         = 1,
      include   = DSR_FIX,
      LRinclude = DLR,
      estim     = "ML"
    ),
    error = function(e) NULL
  )
  
  if (is.null(fit_r1)) return(list(ok = FALSE, reason = "R1_FAIL"))
  
  ll_r1 <- tryCatch(as.numeric(logLik(fit_r1)), error = function(e) NA_real_)
  if (!is.finite(ll_r1)) return(list(ok = FALSE, reason = "R1_LL_FAIL"))
  
  LR_obs <- -2 * (ll_r0 - ll_r1)
  
  # ------------------------------------------------------------
  # Bootstrap loop
  # ------------------------------------------------------------
  LR_boot <- numeric(B)
  fail_count <- 0L
  
  for (b in seq_len(B)) {
    
    # Resample residuals
    if (bootstrap_type == "iid") {
      idx <- sample(seq_len(T_eff), size = T_eff, replace = TRUE)
      U_star <- U_hat[idx, , drop = FALSE]
    } else {
      w <- sample(c(-1, 1), size = T_eff, replace = TRUE)
      U_star <- U_hat * w
    }
    
    # Simulate under r = 0:
    # ΔX_t = Σ_{j=1..p} Γ_j ΔX_{t-j} + ε_t
    dX_star <- matrix(0, T_eff, m)
    X_star  <- matrix(0, T_eff, m)
    colnames(dX_star) <- varnames
    colnames(X_star)  <- varnames
    
    X_star[1, ] <- X[1, ]
    
    for (t in 2:T_eff) {
      acc <- rep(0, m)
      for (j in seq_len(P_VECM)) {
        tj <- t - j
        if (tj >= 1) {
          acc <- acc + as.numeric(Gamma_arr[, , j] %*% dX_star[tj, ])
        }
      }
      dX_star[t, ] <- acc + U_star[t, ]
      X_star[t, ]  <- X_star[t - 1L, ] + dX_star[t, ]
    }
    
    # Re-estimate r=0
    r0_star <- tryCatch(
      tsDyn::lineVar(
        data    = X_star,
        lag     = P_VECM,
        include = DSR_FIX,
        model   = "VAR",
        I       = "diff"
      ),
      error = function(e) NULL
    )
    
    # Re-estimate r=1
    r1_star <- tryCatch(
      tsDyn::VECM(
        X_star,
        lag       = P_VECM,
        r         = 1,
        include   = DSR_FIX,
        LRinclude = DLR,
        estim     = "ML"
      ),
      error = function(e) NULL
    )
    
    if (is.null(r0_star) || is.null(r1_star)) {
      fail_count <- fail_count + 1L
      LR_boot[b] <- NA_real_
      if (fail_count / b > FAIL_THRESHOLD) break
      next
    }
    
    ll0_star <- tryCatch(as.numeric(logLik(r0_star)), error = function(e) NA_real_)
    ll1_star <- tryCatch(as.numeric(logLik(r1_star)), error = function(e) NA_real_)
    
    if (!is.finite(ll0_star) || !is.finite(ll1_star)) {
      fail_count <- fail_count + 1L
      LR_boot[b] <- NA_real_
      if (fail_count / b > FAIL_THRESHOLD) break
      next
    }
    
    LR_boot[b] <- -2 * (ll0_star - ll1_star)
    
    if (b %% (CONFIG$HEARTBEAT_EVERY %||% 25L) == 0) {
      log_line(LOG_PATH, paste("Bootstrap:", b, "fail_share=", round(fail_count / b, 3)))
    }
  }
  
  LR_boot <- LR_boot[is.finite(LR_boot)]
  B_eff <- length(LR_boot)
  
  if (B_eff == 0) return(list(ok = FALSE, reason = "ALL_FAIL"))
  
  p_val <- mean(LR_boot >= LR_obs)
  
  list(
    ok         = TRUE,
    LR_obs     = LR_obs,
    p_val      = p_val,
    B_eff      = B_eff,
    fail_share = fail_count / B
  )
}

# ============================================================
# MAIN LOOP
# ============================================================

results_list <- list()
row_id <- 1L

for (window_name in names(CONFIG$WINDOWS_LOCKED)) {
  
  win_range <- CONFIG$WINDOWS_LOCKED[[window_name]]
  
  df_win <- df_raw %>%
    dplyr::filter(year >= win_range[1], year <= win_range[2])
  
  for (basis in c("raw", "ortho")) {
    
    X <- build_state_q2(df_win, ortho = (basis == "ortho"))
    
    for (DLR in INFER_DLR_SET) {
      
      log_line(LOG_PATH, paste("Running:", window_name, basis, "DLR=", DLR))
      
      out <- bootstrap_rank_test(
        X = X,
        DLR = DLR,
        B = B,
        bootstrap_type = BOOTSTRAP_TYPE
      )
      
      if (!out$ok) {
        results_list[[row_id]] <- data.frame(
          window = window_name,
          basis  = basis,
          DLR    = DLR,
          LR_obs = NA_real_,
          p_val  = NA_real_,
          B_eff  = 0L,
          fail_share = 1,
          status = out$reason,
          stringsAsFactors = FALSE
        )
      } else {
        results_list[[row_id]] <- data.frame(
          window = window_name,
          basis  = basis,
          DLR    = DLR,
          LR_obs = out$LR_obs,
          p_val  = out$p_val,
          B_eff  = out$B_eff,
          fail_share = out$fail_share,
          status = "ok",
          stringsAsFactors = FALSE
        )
      }
      
      row_id <- row_id + 1L
    }
  }
}

results_df <- do.call(rbind, results_list)

safe_write_csv(results_df, OUT_CSV)

# Save objects (df + run metadata) into the required RDS artifact
saveRDS(
  list(
    results = results_df,
    meta = list(
      seed = CONFIG$seed,
      BOOTSTRAP_TYPE = BOOTSTRAP_TYPE,
      B = B,
      P_VECM = P_VECM,
      DSR_FIX = DSR_FIX,
      INFER_DLR_SET = INFER_DLR_SET,
      windows = CONFIG$WINDOWS_LOCKED,
      OUT_ROOT = OUT_ROOT
    )
  ),
  OUT_RDS
)

log_line(LOG_PATH, "=== 40_inference_rank completed ===")

cat("\n40_inference_rank completed successfully\n")
print(results_df)


#Storing results 
dir.create(here::here("output","rank_tests"), recursive = TRUE, showWarnings = FALSE)

rank_cache <- list(
  meta = list(
    BOOTSTRAP_TYPE   = BOOTSTRAP_TYPE,
    P_VECM           = P_VECM,
    INFER_DLR_SET    = INFER_DLR_SET,
    FAIL_THRESHOLD   = FAIL_THRESHOLD,
    CONFIG           = CONFIG,
    DATA_PATH        = DATA_PATH,
    window_name      = window_name,
    win_range        = win_range,
    timestamp        = Sys.time()
  ),
  results_df      = results_df,
  results_list    = results_list,      # likely contains bootstrap draws
  admissible_gate = admissible_gate,
  as_fail_record  = as_fail_record
)

saveRDS(
  rank_cache,
  here::here("output","rank_tests","rank_cache_iid_poly2_4999.rds"),
  compress = "xz"
)