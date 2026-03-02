# ============================================================
# 20_engine.R — tsDyn Lattice Engine (IC_xi_eta_soft)
#
# Scaling update:
#   scaling = log(T_eff_common) / T_eff_common
#
# IC_xi_eta =
#   -2*logLik_ML +
#   [log(T_eff_common)/T_eff_common] *
#   ( xi*k_lag + eta*k_rank + k_det )
#
# Orthogonalization restored (QR layer).
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","readxl","dplyr","tidyr","tsDyn","readr","tibble")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

here::i_am("codes/20_engine.R")
source(here::here("codes","10_config_tsdyn.R"))
source(here::here("codes","99_tsdyn_utils.R"))

`%||%` <- get0("%||%", ifnotfound = function(a,b) if (is.null(a)) b else a)

ROOT_OUT <- here::here(CONFIG$OUT_TSDYN %||% "output/TsDynEngine")
DIRS <- list(
  csv  = file.path(ROOT_OUT,"csv"),
  logs = file.path(ROOT_OUT,"logs"),
  meta = file.path(ROOT_OUT,"meta")
)
dir.create(DIRS$csv,  recursive=TRUE, showWarnings=FALSE)
dir.create(DIRS$logs, recursive=TRUE, showWarnings=FALSE)
dir.create(DIRS$meta, recursive=TRUE, showWarnings=FALSE)

cat("=== 20_engine_tsdyn (IC_xi_eta_soft) start ===\n")

set.seed(CONFIG$seed %||% 123456L)

# ------------------------------------------------------------
# Data load
# ------------------------------------------------------------

df_raw <- readxl::read_excel(
  here::here(CONFIG$data_file),
  sheet = CONFIG$data_sheet %||% "us_data"
)

df_raw <- as.data.frame(df_raw)

df_raw$year  <- as.numeric(df_raw[[CONFIG$year_col]])
df_raw$log_y <- log(as.numeric(df_raw[[CONFIG$y_col]]))
df_raw$log_k <- log(as.numeric(df_raw[[CONFIG$k_col]]))
df_raw$e_raw <- as.numeric(df_raw[[CONFIG$e_col]])

df_raw <- df_raw[
  is.finite(df_raw$year) &
    is.finite(df_raw$log_y) &
    is.finite(df_raw$log_k) &
    is.finite(df_raw$e_raw),
]

SPEC_SET <- names(CONFIG$SPECS)
basis_set  <- unique(ifelse(as.logical(CONFIG$ORTHO_TOGGLE),"ortho","raw"))
WINDOWS    <- CONFIG$WINDOWS_LOCKED
det_df     <- det_pairs(CONFIG)

results_list <- list()
window_sizes <- list()

# ------------------------------------------------------------
# GRID LOOP
# ------------------------------------------------------------

for (spec in SPEC_SET) {
  
  degree <- as.integer(CONFIG$SPECS[[spec]]$degree)
  
  for (basis_tag in basis_set) {
    
    for (window_name in names(WINDOWS)) {
      
      bounds <- WINDOWS[[window_name]]
      df_win <- df_raw[df_raw$year>=bounds[1] & df_raw$year<=bounds[2],]
      
      if (nrow(df_win) < 10) next
      window_sizes[[window_name]] <- nrow(df_win)
      
      # ------------------------------------------------------
      # DISTRIBUTIVE BLOCK
      # ------------------------------------------------------
      
      if (degree == 1L) {
        # Q1 = raw linear e only
        df_win$Q1 <- df_win$e_raw
        
      } else {
        
        if (basis_tag == "ortho") {
          
          basis_obj <- basis_build_rawpowers_qr(
            df_win,
            e_col  = "e_raw",
            degree = degree
          )
          
          df_win <- basis_apply_rawpowers_qr(
            df_win,
            basis  = basis_obj,
            prefix = "Q"
          )
          
        } else {
          
          df_win <- basis_apply_rawpowers(
            df_win,
            e_col  = "e_raw",
            degree = degree,
            prefix = "Q"
          )
        }
      }
      
      # ------------------------------------------------------
      # Deterministics loop
      # ------------------------------------------------------
      
      for (i in seq_len(nrow(det_df))) {
        
        DSR <- det_df$DSR[i]
        DLR <- det_df$DLR[i]
        det_tag <- det_df$det_tag[i]
        include <- det_df$include[i]
        LRinclude <- det_df$LRinclude[i]
        
        # Build state vector
        X <- data.frame(
          log_y = df_win$log_y,
          log_k = df_win$log_k
        )
        
        if (isTRUE(CONFIG$INCLUDE_E_RAW))
          X$e_raw <- df_win$e_raw
        
        for (jj in seq_len(degree))
          X[[paste0("Q",jj,"_logK")]] <-
          df_win[[paste0("Q",jj)]] * df_win$log_k
        
        m <- ncol(X)
        
        # --------------------------------------------------
        # Lag & Rank loop
        # --------------------------------------------------
        
        # --------------------------------------------------
        # Lag & Rank loop
        # --------------------------------------------------
        
        for (p_vecm in seq(CONFIG$P_MIN, CONFIG$P_MAX_EXPLORATORY)) {
          
          for (r0 in 0:(m-1)) {
            
            model <- tryCatch({
              
              if (r0 == 0L) {
                
                # ------------------------------------------
                # r = 0  →  Unrestricted VAR in differences
                # ------------------------------------------
                
                tsDyn::lineVar(
                  data    = X,
                  lag     = p_vecm,
                  model   = "VAR",
                  I       = "diff",
                  include = include
                )
                
              } else {
                
                # ------------------------------------------
                # r ≥ 1  →  Johansen ML VECM
                # ------------------------------------------
                
                tsDyn::VECM(
                  X,
                  lag       = p_vecm,
                  r         = r0,
                  include   = include,
                  LRinclude = LRinclude,
                  estim     = "ML"
                )
              }
              
            }, error = function(e) NULL)
            
            if (is.null(model)) next
            
            ll <- tsdyn_loglik(model)
            
            results_list[[length(results_list)+1]] <-
              data.frame(
                spec   = spec,
                basis  = basis_tag,
                window = window_name,
                DSR    = DSR,
                DLR    = DLR,
                det_tag= det_tag,
                p      = p_vecm,
                r      = r0,
                m      = m,
                logLik_ML = ll,
                status = "computed",
                stringsAsFactors = FALSE
              )
          }
        }
      }
    }
  }
}

grid_df <- dplyr::bind_rows(results_list)

grid_df <- grid_df |>
  mutate(case_tag=paste0(spec,"_",basis,"|",det_tag))

# ------------------------------------------------------------
# COMMON T_eff
# ------------------------------------------------------------

common_tbl <- grid_df |>
  group_by(case_tag,window) |>
  summarise(p_max_window=max(p),.groups="drop") |>
  group_by(case_tag) |>
  summarise(common_p_max=min(p_max_window),.groups="drop")

grid_df <- grid_df |>
  left_join(common_tbl,by="case_tag") |>
  mutate(
    T_window = as.numeric(unlist(window_sizes[window])),
    T_eff_common = T_window - common_p_max
  )

# ------------------------------------------------------------
# IC_xi_eta_soft
# ------------------------------------------------------------

grid_df <- grid_df |>
  mutate(
    fit = -2 * logLik_ML,
    
    k_rank = 2*m*r - r^2,
    k_lag  = m^2 * (p - 1),
    k_det  = 0,
    
    xi  = ifelse(r < m, m/(m - r), NA_real_),
    eta = 1,
    
    scaling = log(T_eff_common) / T_eff_common,
    
    IC_xi_eta =
      fit +
      scaling *
      ( xi*k_lag + eta*k_rank + k_det )
  )

# ------------------------------------------------------------
# Export
# ------------------------------------------------------------

readr::write_csv(
  grid_df,
  file.path(DIRS$csv,"APPX_grid_ic_xi_eta_soft.csv")
)

cat("=== 20_engine_tsdyn (IC_xi_eta_soft) done ===\n")