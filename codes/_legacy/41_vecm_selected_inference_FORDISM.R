############################################################
# 41_vecm_selected_inference.R
#
# Selected VECM parameter inference (conditional on chosen model)
# tsDyn-based implementation — NO urca
#
# OUTPUT (per window × basis):
#   variable | param | estimate | boot_mean | boot_sd | ci_low | ci_high
#
# LOCKS:
#   - DLR = "const" (restricted constant in cointegration space)
#   - DSR = "none"  (no SR constant)
#   - rank r fixed (default r=1)
#   - beta normalization: logY = 1
#   - basis toggle: raw vs ortho (orthogonalization of polynomial block only)
#   - no "_" in LaTeX labels (sanitize at export layer)
#
# Bootstrap:
#   - "iid"  residual resampling
#   - "wild" Rademacher wild bootstrap
#
# CHANGELOG (2026-02-25)
# [1] FIXED beta extraction for tsDyn VECM objects:
#     beta lives in fit$model.specific$beta (not fit$beta or S4 slots).
# [2] FIXED beta normalization under LRinclude="const":
#     tsDyn returns beta with an extra row for restricted constant (length m+1).
#     We now split: beta_x over X variables + beta_const, normalize on beta_x["logY"]=1.
# [3] ECT uses ONLY beta_x (variable part), not the constant row.
# [4] Added window-bound sanitization for -Inf/Inf ranges (safe filtering + logging).
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

latex_safe <- function(x) {
  x <- as.character(x)
  x <- gsub("_", "", x, fixed = TRUE)  # lock: never export underscores
  x
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
.pkg_local("knitr")
.pkg_local("kableExtra")

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(knitr))
suppressPackageStartupMessages(library(kableExtra))

set.seed(CONFIG$seed)

# ============================================================
# USER CONTROLS (meeting-ready defaults)
# ============================================================

# Which spec? "Q2" or "Q3"
SPEC_TAG <- "Q2"

# windows to run (set explicitly if you want only one)
WINDOWS_SELECTED <- "fordism"

# basis toggle
BASIS_SET <- c("raw", "ortho")

# fixed deterministics policy
DLR <- "const"
DSR <- "none"

# fixed rank for inference
R_FIX <- 1L

# bootstrap
BOOTSTRAP_TYPE <- "wild"   # "iid" or "wild"
B              <- 199L
FAIL_THRESHOLD <- CONFIG$fail_threshold %||% 0.10

# lag policy (window-specific)
P_VECM_DEFAULT <- as.integer(CONFIG$p_vecm_default)
P_VECM_BY_WINDOW <- list(
  full         = P_VECM_DEFAULT,
  fordism      = 1L,
  post_fordism = 2L
)

get_p_vecm_for_window <- function(window_name) {
  if (!is.null(P_VECM_BY_WINDOW[[window_name]])) return(as.integer(P_VECM_BY_WINDOW[[window_name]]))
  as.integer(P_VECM_DEFAULT)
}

# output root
OUT_ROOT <- if (.is_abs_path(CONFIG$OUT_INFERENCE %||% CONFIG$OUT_RANK)) {
  CONFIG$OUT_INFERENCE %||% CONFIG$OUT_RANK
} else {
  file.path(ROOT, CONFIG$OUT_INFERENCE %||% "output/InferenceSelectedVECM_tsDyn")
}

LOG_PATH <- file.path(OUT_ROOT, "log", "41_vecm_selected_inference_log.txt")
dir.create(dirname(LOG_PATH), recursive = TRUE, showWarnings = FALSE)

log_line(LOG_PATH, "=== 41_vecm_selected_inference started ===")
log_line(LOG_PATH, paste("SPEC_TAG=", SPEC_TAG,
                         "| DLR=", DLR, "DSR=", DSR,
                         "| r=", R_FIX,
                         "| BOOT=", BOOTSTRAP_TYPE,
                         "| B=", B))

# ============================================================
# DATA LOAD
# ============================================================

DATA_PATH <- if (.is_abs_path(CONFIG$data_file)) CONFIG$data_file else file.path(ROOT, CONFIG$data_file)

df_raw <- readxl::read_excel(DATA_PATH, sheet = CONFIG$data_sheet)

# base columns
df_raw <- df_raw %>%
  dplyr::rename(
    year = !!CONFIG$year_col,
    Y    = !!CONFIG$y_col,
    K    = !!CONFIG$k_col,
    e    = !!CONFIG$e_col
  ) %>%
  dplyr::mutate(
    logY = log(Y),
    logK = log(K),
    e_logK  = e * logK,
    e2_logK = (e^2) * logK,
    e3_logK = (e^3) * logK
  )

# ============================================================
# ORTHOGONALIZATION HELPERS (store linear map A: raw -> ortho)
# ============================================================

ortho_block_with_A <- function(M_raw) {
  qr_obj <- qr(M_raw)
  R <- qr.R(qr_obj)
  if (any(!is.finite(R)) || det(R) == 0) stop("Orthogonalization failed: singular R", call. = FALSE)
  A <- solve(R)            # raw -> Q
  M_ortho <- M_raw %*% A   # linear rotation (invertible)
  list(M = M_ortho, A = A)
}

# ============================================================
# STATE BUILDERS
# ============================================================

build_state_q2 <- function(df, ortho = FALSE) {
  # X = (logY, logK, e_logK, e2_logK)
  M_raw <- as.matrix(df[, c("e_logK", "e2_logK")])
  if (ortho) {
    tmp <- ortho_block_with_A(M_raw)
    M_blk <- tmp$M
    A <- tmp$A
    colnames(M_blk) <- c("q1logK", "q2logK")
  } else {
    M_blk <- M_raw
    A <- diag(ncol(M_raw))
    colnames(M_blk) <- c("elogK", "e2logK")
  }
  X <- cbind(logY = df$logY, logK = df$logK, M_blk)
  storage.mode(X) <- "double"
  attr(X, "A_raw_to_ortho") <- A
  X
}

build_state_q3 <- function(df, ortho = FALSE) {
  # X = (logY, logK, e_logK, e2_logK, e3_logK)
  M_raw <- as.matrix(df[, c("e_logK", "e2_logK", "e3_logK")])
  if (ortho) {
    tmp <- ortho_block_with_A(M_raw)
    M_blk <- tmp$M
    A <- tmp$A
    colnames(M_blk) <- c("q1logK", "q2logK", "q3logK")
  } else {
    M_blk <- M_raw
    A <- diag(ncol(M_raw))
    colnames(M_blk) <- c("elogK", "e2logK", "e3logK")
  }
  X <- cbind(logY = df$logY, logK = df$logK, M_blk)
  storage.mode(X) <- "double"
  attr(X, "A_raw_to_ortho") <- A
  X
}

build_state <- function(df, spec_tag, ortho) {
  if (identical(spec_tag, "Q2")) return(build_state_q2(df, ortho = ortho))
  if (identical(spec_tag, "Q3")) return(build_state_q3(df, ortho = ortho))
  stop("Unknown SPEC_TAG: ", spec_tag, call. = FALSE)
}

# ============================================================
# VECM COMPONENT EXTRACTION (tsDyn object shape)
# ============================================================

extract_beta <- function(fit, varnames) {
  # tsDyn VECM stores beta here (and coint mirrors it)
  b <- tryCatch(fit$model.specific$beta, error = function(e) NULL)
  if (is.null(b)) b <- tryCatch(fit$model.specific$coint, error = function(e) NULL)
  if (is.null(b)) return(NULL)
  
  b <- as.matrix(b)
  if (ncol(b) >= 1) b <- b[, 1, drop = FALSE]
  
  rn <- rownames(b)
  if (is.null(rn) || any(rn == "")) {
    if (nrow(b) == length(varnames) + 1L) {
      rownames(b) <- c("const", varnames)
    } else if (nrow(b) == length(varnames)) {
      rownames(b) <- varnames
    }
  }
  b
}

extract_resid <- function(fit) {
  tryCatch(as.matrix(residuals(fit)), error = function(e) NULL)
}

extract_coef_mat <- function(fit) {
  cl <- tryCatch(coef(fit), error = function(e) NULL)
  if (is.null(cl)) return(NULL)
  if (is.matrix(cl)) return(cl)
  if (is.list(cl)) {
    alln <- unique(unlist(lapply(cl, names)))
    mat <- matrix(NA_real_, nrow = length(cl), ncol = length(alln))
    rownames(mat) <- names(cl) %||% paste0("eq", seq_along(cl))
    colnames(mat) <- alln
    for (i in seq_along(cl)) {
      v <- cl[[i]]
      mat[i, match(names(v), alln)] <- as.numeric(v)
    }
    return(mat)
  }
  NULL
}

extract_Gamma_from_coefmat <- function(coef_mat, varnames, p_lag) {
  if (is.null(coef_mat)) return(NULL)
  m <- length(varnames)
  G <- array(0, dim = c(m, m, p_lag),
             dimnames = list(eq = varnames, x = varnames, lag = paste0("L", seq_len(p_lag))))
  pick <- function(nms, vname, j) {
    v <- gsub("([\\^\\$\\.|\\(|\\)|\\[\\]|\\+\\*\\?\\\\])", "\\\\\\1", vname)
    pat1 <- paste0("^(d|D)?", v, ".*(\\.|_|:)?l", j, "($|[^0-9])")
    which(grepl(pat1, nms, ignore.case = TRUE))
  }
  nms <- colnames(coef_mat)
  for (i in seq_len(m)) {
    for (j in seq_len(p_lag)) {
      for (k in seq_len(m)) {
        idx <- pick(nms, varnames[k], j)
        if (length(idx) >= 1) {
          val <- coef_mat[i, idx[1]]
          if (is.finite(val)) G[i, k, j] <- val
        }
      }
    }
  }
  G
}

extract_alpha <- function(fit, coef_mat, varnames) {
  a <- tryCatch(fit$model.specific$alpha, error = function(e) NULL)
  if (!is.null(a)) {
    a <- as.matrix(a)
    if (ncol(a) >= 1) a <- a[, 1, drop = FALSE]
    rownames(a) <- rownames(a) %||% varnames
    return(a)
  }
  # fallback: from coef matrix ECT column
  if (is.null(coef_mat)) return(NULL)
  ect_idx <- which(grepl("ECT|ec", colnames(coef_mat), ignore.case = TRUE))
  if (length(ect_idx) == 0) return(NULL)
  a <- coef_mat[, ect_idx[1], drop = FALSE]
  rownames(a) <- rownames(coef_mat) %||% varnames
  colnames(a) <- "ECT"
  a
}

# Normalize beta so that logY = 1, under LRinclude="const" where beta has extra const row.
normalize_beta_logY1 <- function(beta_mat, varnames) {
  if (is.null(beta_mat)) return(NULL)
  
  b <- as.numeric(beta_mat[, 1])
  names(b) <- rownames(beta_mat)
  
  b_const <- NA_real_
  if (length(b) == length(varnames) + 1L) {
    b_const <- b[1]
    b_x <- b[-1]
    names(b_x) <- varnames
  } else {
    b_x <- b
    if (!all(varnames %in% names(b_x))) names(b_x) <- varnames
  }
  
  if (!("logY" %in% names(b_x))) return(NULL)
  if (!is.finite(b_x["logY"]) || abs(b_x["logY"]) < 1e-10) return(NULL)
  
  scale <- b_x["logY"]
  b_x <- b_x / scale
  b_x["logY"] <- 1
  
  # scale the constant the same way (so cointegration relation is coherent)
  if (is.finite(b_const)) b_const <- b_const / scale
  
  list(beta_x = b_x, beta_const = b_const)
}

# Map beta block back to raw polynomial block if basis=ortho.
# If X = [logY, logK, M_raw %*% A], then beta_raw_block = A' beta_ortho_block.
beta_map_ortho_to_raw <- function(beta_x_named, A_raw_to_ortho, varnames_X) {
  if (is.null(beta_x_named)) return(NULL)
  k <- ncol(A_raw_to_ortho)
  block_names <- varnames_X[3:(2 + k)]
  if (!all(block_names %in% names(beta_x_named))) return(beta_x_named)
  b_blk <- beta_x_named[block_names]
  b_raw_blk <- as.numeric(t(A_raw_to_ortho) %*% matrix(b_blk, ncol = 1))
  raw_labels <- c("elogK", "e2logK", "e3logK")[seq_len(k)]
  out <- beta_x_named
  out[block_names] <- b_raw_blk
  names(out)[match(block_names, names(out))] <- raw_labels
  out
}

# ============================================================
# BOOTSTRAP INFERENCE CORE (full VECM)
# ============================================================

fit_vecm_once <- function(X, p_vecm, r, DLR, DSR) {
  tryCatch(
    tsDyn::VECM(
      X,
      lag       = p_vecm,
      r         = r,
      include   = DSR,
      LRinclude = DLR,
      estim     = "ML"
    ),
    error = function(e) NULL
  )
}

simulate_vecm_path <- function(X0, dX_init, alpha, beta_x, Gamma_arr, U_star) {
  # ΔX_t = alpha * (beta_x' X_{t-1} + const_in_coint) + Σ Γ_j ΔX_{t-j} + ε_t
  # NOTE: const handled outside (we incorporate it into ect in calling code if needed).
  T_eff <- nrow(U_star)
  m <- ncol(U_star)
  p <- dim(Gamma_arr)[3]
  X_star  <- matrix(0, T_eff, m)
  dX_star <- matrix(0, T_eff, m)
  colnames(X_star)  <- colnames(U_star)
  colnames(dX_star) <- colnames(U_star)
  
  X_star[1, ] <- X0
  if (!is.null(dX_init) && nrow(dX_init) >= 1) {
    L <- min(nrow(dX_init), T_eff)
    dX_star[seq_len(L), ] <- dX_init[seq_len(L), , drop = FALSE]
    for (t in 2:L) X_star[t, ] <- X_star[t - 1, ] + dX_star[t, ]
  }
  
  for (t in 2:T_eff) {
    ect <- as.numeric(crossprod(beta_x, X_star[t - 1, ]))
    acc <- as.numeric(alpha) * ect
    for (j in seq_len(p)) {
      tj <- t - j
      if (tj >= 1) acc <- acc + as.numeric(Gamma_arr[, , j] %*% dX_star[tj, ])
    }
    dX_star[t, ] <- acc + U_star[t, ]
    X_star[t, ]  <- X_star[t - 1L, ] + dX_star[t, ]
  }
  X_star
}

build_param_vector <- function(varnames, beta_report, beta_const, alpha_mat, coef_mat) {
  out <- numeric(0)
  
  # beta (reporting scale)
  if (!is.null(beta_report)) {
    for (nm in names(beta_report)) out[paste0("beta|", nm)] <- beta_report[[nm]]
  }
  if (is.finite(beta_const)) out["beta|const"] <- beta_const
  
  # alpha loadings
  if (!is.null(alpha_mat)) {
    a <- as.numeric(alpha_mat[, 1])
    names(a) <- rownames(alpha_mat) %||% varnames
    for (nm in names(a)) out[paste0("d", nm, "|alphaECT")] <- a[[nm]]
  }
  
  # short-run coefficients (skip ECT column if present)
  if (!is.null(coef_mat)) {
    eqn <- rownames(coef_mat) %||% varnames
    for (i in seq_len(nrow(coef_mat))) {
      for (j in seq_len(ncol(coef_mat))) {
        cn <- colnames(coef_mat)[j]
        if (is.na(coef_mat[i, j]) || !is.finite(coef_mat[i, j])) next
        if (grepl("ECT|ec", cn, ignore.case = TRUE)) next
        out[paste0("d", eqn[i], "|", cn)] <- coef_mat[i, j]
      }
    }
  }
  out
}

summarize_boot <- function(theta_hat, theta_star_mat, conf = 0.95) {
  if (nrow(theta_star_mat) == 0) return(NULL)
  alpha <- (1 - conf) / 2
  qs <- apply(theta_star_mat, 2, quantile, probs = c(alpha, 1 - alpha), na.rm = TRUE)
  data.frame(
    key       = colnames(theta_star_mat),
    estimate  = as.numeric(theta_hat[colnames(theta_star_mat)]),
    boot_mean = colMeans(theta_star_mat, na.rm = TRUE),
    boot_sd   = apply(theta_star_mat, 2, sd, na.rm = TRUE),
    ci_low    = as.numeric(qs[1, ]),
    ci_high   = as.numeric(qs[2, ]),
    stringsAsFactors = FALSE
  )
}

sanitize_window_bounds <- function(win_range, years_vec) {
  lo <- win_range[1]; hi <- win_range[2]
  if (!is.finite(lo)) lo <- min(years_vec, na.rm = TRUE)
  if (!is.finite(hi)) hi <- max(years_vec, na.rm = TRUE)
  c(lo, hi)
}

# ============================================================
# MAIN: per window × basis
# ============================================================

all_tables <- list()

for (window_name in WINDOWS_SELECTED) {
  
  win_range_raw <- CONFIG$WINDOWS_LOCKED[[window_name]]
  if (is.null(win_range_raw)) stop("Unknown window: ", window_name, call. = FALSE)
  win_range <- sanitize_window_bounds(win_range_raw, df_raw$year)
  
  df_win <- df_raw %>%
    filter(year >= win_range[1], year <= win_range[2])
  
  p_vecm <- get_p_vecm_for_window(window_name)
  log_line(LOG_PATH, paste("Window:", window_name, "P_VECM=", p_vecm, "range:", paste(win_range, collapse = "-")))
  
  for (basis in BASIS_SET) {
    
    ortho_flag <- identical(basis, "ortho")
    X <- build_state(df_win, SPEC_TAG, ortho = ortho_flag)
    A_raw_to_ortho <- attr(X, "A_raw_to_ortho") %||% diag(ncol(X) - 2)
    varnames <- colnames(X)
    
    # fit observed model
    fit <- fit_vecm_once(X, p_vecm = p_vecm, r = R_FIX, DLR = DLR, DSR = DSR)
    if (is.null(fit)) {
      log_line(LOG_PATH, paste("FAIL fit:", window_name, basis))
      next
    }
    
    coef_mat <- extract_coef_mat(fit)
    U_hat <- extract_resid(fit)
    beta_mat <- extract_beta(fit, varnames)
    alpha_mat <- extract_alpha(fit, coef_mat, varnames)
    
    if (is.null(U_hat) || nrow(U_hat) < 5) {
      log_line(LOG_PATH, paste("FAIL resid:", window_name, basis))
      next
    }
    
    T_eff <- nrow(U_hat)
    
    Gamma_arr <- extract_Gamma_from_coefmat(coef_mat, varnames, p_lag = p_vecm)
    if (is.null(Gamma_arr)) {
      log_line(LOG_PATH, paste("FAIL Gamma extract:", window_name, basis))
      next
    }
    
    beta_obj <- normalize_beta_logY1(beta_mat, varnames)
    if (is.null(beta_obj)) {
      log_line(LOG_PATH, paste("FAIL beta normalization:", window_name, basis))
      next
    }
    
    beta_x <- beta_obj$beta_x
    beta_const <- beta_obj$beta_const
    
    # beta to report (raw coordinates when ortho)
    beta_report <- beta_x
    if (ortho_flag) beta_report <- beta_map_ortho_to_raw(beta_x, A_raw_to_ortho, varnames_X = varnames)
    
    # observed parameter vector
    theta_hat <- build_param_vector(
      varnames = varnames,
      beta_report = beta_report,
      beta_const = beta_const,
      alpha_mat = alpha_mat,
      coef_mat = coef_mat
    )
    
    # ECT observed (computed in estimation basis; const excluded by default)
    ect_obs <- as.numeric(X %*% beta_x[varnames])
    ect_df <- data.frame(year = df_win$year[seq_along(ect_obs)], ECT = ect_obs)
    
    # ------------------------------------------------------------
    # Bootstrap loop
    # ------------------------------------------------------------
    fail_count <- 0L
    keep <- list()
    keep_i <- 1L
    
    dX_obs <- apply(X, 2, diff)
    dX_init <- matrix(0, T_eff, ncol(X))
    colnames(dX_init) <- varnames
    if (!is.null(dX_obs) && nrow(dX_obs) >= 1) {
      dX_init[2:T_eff, ] <- dX_obs[1:(T_eff - 1), , drop = FALSE]
    }
    X0 <- X[1, ]
    
    for (b in seq_len(B)) {
      
      if (BOOTSTRAP_TYPE == "iid") {
        idx <- sample(seq_len(T_eff), size = T_eff, replace = TRUE)
        U_star <- U_hat[idx, , drop = FALSE]
      } else {
        w <- sample(c(-1, 1), size = T_eff, replace = TRUE)
        U_star <- U_hat * w
      }
      colnames(U_star) <- varnames
      
      X_star <- tryCatch(
        simulate_vecm_path(
          X0 = X0,
          dX_init = dX_init,
          alpha = alpha_mat[, 1, drop = FALSE],
          beta_x = matrix(beta_x[varnames], ncol = 1),
          Gamma_arr = Gamma_arr,
          U_star = U_star
        ),
        error = function(e) NULL
      )
      
      if (is.null(X_star) || any(!is.finite(X_star))) {
        fail_count <- fail_count + 1L
        if (fail_count / b > FAIL_THRESHOLD) break
        next
      }
      
      fit_b <- fit_vecm_once(X_star, p_vecm = p_vecm, r = R_FIX, DLR = DLR, DSR = DSR)
      if (is.null(fit_b)) {
        fail_count <- fail_count + 1L
        if (fail_count / b > FAIL_THRESHOLD) break
        next
      }
      
      coef_b <- extract_coef_mat(fit_b)
      beta_b_mat <- extract_beta(fit_b, varnames)
      alpha_b <- extract_alpha(fit_b, coef_b, varnames)
      if (is.null(beta_b_mat) || is.null(alpha_b) || is.null(coef_b)) {
        fail_count <- fail_count + 1L
        if (fail_count / b > FAIL_THRESHOLD) break
        next
      }
      
      beta_b_obj <- normalize_beta_logY1(beta_b_mat, varnames)
      if (is.null(beta_b_obj)) {
        fail_count <- fail_count + 1L
        if (fail_count / b > FAIL_THRESHOLD) break
        next
      }
      
      beta_b_x <- beta_b_obj$beta_x
      beta_b_const <- beta_b_obj$beta_const
      
      beta_b_report <- beta_b_x
      if (ortho_flag) beta_b_report <- beta_map_ortho_to_raw(beta_b_x, A_raw_to_ortho, varnames_X = varnames)
      
      theta_b <- build_param_vector(
        varnames = varnames,
        beta_report = beta_b_report,
        beta_const = beta_b_const,
        alpha_mat = alpha_b,
        coef_mat = coef_b
      )
      
      keep[[keep_i]] <- theta_b
      keep_i <- keep_i + 1L
      
      if (b %% (CONFIG$HEARTBEAT_EVERY %||% 50L) == 0) {
        log_line(LOG_PATH, paste("Boot:", window_name, basis, "b=", b,
                                 "fail_share=", round(fail_count / b, 3)))
      }
    }
    
    if (length(keep) == 0) {
      log_line(LOG_PATH, paste("ALL_FAIL:", window_name, basis))
      next
    }
    
    common_names <- Reduce(intersect, lapply(keep, names))
    if (length(common_names) == 0) {
      log_line(LOG_PATH, paste("NO_COMMON_PARAMS:", window_name, basis))
      next
    }
    
    theta_star <- do.call(rbind, lapply(keep, function(v) v[common_names]))
    colnames(theta_star) <- common_names
    
    theta_hat_use <- theta_hat
    if (!all(common_names %in% names(theta_hat_use))) {
      miss <- setdiff(common_names, names(theta_hat_use))
      theta_hat_use[miss] <- NA_real_
    }
    
    summ <- summarize_boot(theta_hat_use, theta_star, conf = 0.95)
    summ$window <- window_name
    summ$basis <- basis
    summ$P_VECM <- p_vecm
    summ$DLR <- DLR
    summ$B_eff <- nrow(theta_star)
    summ$fail_share <- fail_count / B
    
    key_split <- strsplit(summ$key, "\\|", fixed = FALSE)
    summ$variable <- vapply(key_split, `[[`, character(1), 1)
    summ$param    <- vapply(key_split, `[[`, character(1), 2)
    summ$key <- NULL
    
    summ$variable <- latex_safe(summ$variable)
    summ$param    <- latex_safe(summ$param)
    
    out_tbl <- summ %>%
      select(window, basis, variable, param, estimate, boot_mean, boot_sd, ci_low, ci_high,
             P_VECM, DLR, B_eff, fail_share) %>%
      arrange(variable, param)
    
    # ------------------------------------------------------------
    # EXPORT (per window × basis)
    # ------------------------------------------------------------
    out_dir_csv <- file.path(OUT_ROOT, "csv")
    out_dir_tex <- file.path(OUT_ROOT, "tex")
    out_dir_rds <- file.path(OUT_ROOT, "rds")
    out_dir_ect <- file.path(OUT_ROOT, "ect")
    dir.create(out_dir_csv, recursive = TRUE, showWarnings = FALSE)
    dir.create(out_dir_tex, recursive = TRUE, showWarnings = FALSE)
    dir.create(out_dir_rds, recursive = TRUE, showWarnings = FALSE)
    dir.create(out_dir_ect, recursive = TRUE, showWarnings = FALSE)
    
    stem <- paste0("41params_", window_name, "_", basis, "_", SPEC_TAG)
    
    safe_write_csv(out_tbl, file.path(out_dir_csv, paste0(stem, ".csv")))
    safe_write_csv(ect_df, file.path(out_dir_ect, paste0("41ECT_", window_name, "_", basis, "_", SPEC_TAG, ".csv")))
    
    saveRDS(
      list(
        meta = list(
          window = window_name,
          basis = basis,
          SPEC_TAG = SPEC_TAG,
          P_VECM = p_vecm,
          r = R_FIX,
          DLR = DLR,
          DSR = DSR,
          BOOTSTRAP_TYPE = BOOTSTRAP_TYPE,
          B = B,
          B_eff = nrow(theta_star),
          fail_share = fail_count / B,
          seed = CONFIG$seed
        ),
        table = out_tbl,
        ect_obs = ect_df,
        theta_hat = theta_hat_use[common_names],
        theta_star = theta_star,
        A_raw_to_ortho = A_raw_to_ortho,
        beta_x_obs = beta_x,
        beta_const_obs = beta_const
      ),
      file.path(out_dir_rds, paste0(stem, ".rds")),
      compress = "xz"
    )
    
    tex_tbl <- out_tbl %>%
      select(variable, param, estimate, boot_mean, boot_sd, ci_low, ci_high)
    
    tex_out <- tex_tbl %>%
      mutate(across(where(is.numeric), ~ round(.x, 4))) %>%
      kable(
        format = "latex",
        booktabs = TRUE,
        escape = FALSE,
        caption = paste0("Selected VECM Bootstrap Inference (", latex_safe(window_name),
                         ", ", latex_safe(basis),
                         ", ", latex_safe(SPEC_TAG),
                         ", p=", p_vecm, ", r=", R_FIX, ")"),
        align = c("l","l","r","r","r","r","r")
      ) %>%
      kable_styling(latex_options = c("hold_position"), font_size = 9)
    
    writeLines(tex_out, file.path(out_dir_tex, paste0(stem, ".tex")))
    
    log_line(LOG_PATH, paste("EXPORT OK:", window_name, basis,
                             "B_eff=", nrow(theta_star),
                             "fail_share=", round(fail_count / B, 3)))
    
    all_tables[[paste(window_name, basis, sep = "__")]] <- out_tbl
  }
}

if (length(all_tables) > 0) {
  combined <- do.call(rbind, all_tables)
  safe_write_csv(combined, file.path(OUT_ROOT, "csv", paste0("41params_ALL_", SPEC_TAG, ".csv")))
}

log_line(LOG_PATH, "=== 41_vecm_selected_inference completed ===")
cat("\n41_vecm_selected_inference completed successfully\n")


e_raw   <- read.csv(file.path(OUT_ROOT, "ect", paste0("41ECT_fordism_raw_",   spec_tag, ".csv")))
e_ortho <- read.csv(file.path(OUT_ROOT, "ect", paste0("41ECT_fordism_ortho_", spec_tag, ".csv")))

e_raw$
plot(e_raw$year, e_raw$ECT, type="l")
