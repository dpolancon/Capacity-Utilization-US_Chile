############################################################
# 10_config.R — project configuration (FROZEN LAG LOGIC)
#
# Lag convention (FROZEN):
#   In tsDyn:
#     VECM(lag = p)  ⇒  p lags of ΔX in the short run.
#   Therefore:
#     r = 0 null (no Π term) must be estimated as
#       lineVar(..., lag = p, I = "diff")
#
#   We DO NOT use (p - 1) mapping.
#   We DO NOT reinterpret lag as VAR-levels lag.
#   We take tsDyn's lag argument literally.
############################################################

CONFIG <- list(
  
  ## ----------------------------------------------------------
  ## Data location (project processed)
  ## ----------------------------------------------------------
  data_file  = "data/processed/ddbb_cu_US_kgr.xlsx",
  data_sheet = "us_data",
  
  ## Column names in the Excel sheet
  year_col = "year",
  y_col    = "Yrgdp",
  k_col    = "KGCRcorp",
  e_col    = "e",
  
  ## ----------------------------------------------------------
  ## Shaikh Data Replication (raw)
  ## ----------------------------------------------------------
  data_shaikh       = "data/raw/Shaikh_RepData.xlsx",
  data_shaikh_sheet = "long",
  
  ## Variables in the Shaikh sheet
  y_nom    = "GVAcorp",
  k_nom    = "KGCcorp",
  p_index  = "Py",
  u_shaikh = "u_shaikh",
  pi_share = "Profshcorp",
  e_rate   = "e",
  
  ## ----------------------------------------------------------
  ## Sample windows (full sample must be first)
  ## ----------------------------------------------------------
  WINDOWS_LOCKED = list(
    shaikh_window = c(1947, 2011),
    full          = c(-Inf, Inf),
    fordism       = c(-Inf, 1973),
    post_fordism  = c(1974,  Inf)
  ),
  
  ## ----------------------------------------------------------
  ## Deterministic subspaces
  ##
  ## DSR = short-run deterministic (Δ equations)  -> tsDyn include
  ## DLR = long-run deterministic (cointegration) -> tsDyn LRinclude
  ##
  ## Allowed values: "none", "const"
  ## (trend/both are supported in utils, but stage locks can restrict)
  ## ----------------------------------------------------------
  DSR_SET = c("none", "const"),
  DLR_SET = c("none", "const"),
  
  ## Explicit deterministic pairs (SR, LR)
  DET_PAIRS = list(
    c("none",  "none"),
    c("none",  "const"),
    c("const", "none")
  ),
  
  ## ----------------------------------------------------------
  ## Trend toggle (OFF by default)
  ## ----------------------------------------------------------
  ALLOW_TRENDS = FALSE,
  
  ## ----------------------------------------------------------
  ## Lag settings (tsDyn convention is frozen)
  ## ----------------------------------------------------------
  P_MIN = 1L,
  P_MAX_EXPLORATORY = 7L,
  
  ## Default lag for inference
  p_vecm_default = 1L,
  
  ## ----------------------------------------------------------
  ## Model specifications (structural manifold blocks)
  ## ----------------------------------------------------------
  SPECS = list(
    Q1 = list(degree = 1L),
    Q2 = list(degree = 2L),
    Q3 = list(degree = 3L)
  ),
  
  ## ----------------------------------------------------------
  ## Orthogonalization toggle
  ## ----------------------------------------------------------
  ORTHO_TOGGLE = c(FALSE, TRUE),
  
  ## ----------------------------------------------------------
  ## Exploitation term handling
  ## ----------------------------------------------------------
  INCLUDE_E_RAW = TRUE,
  E_RAW_MODE    = "raw",
  
  ## ----------------------------------------------------------
  ## Output roots
  ## ----------------------------------------------------------
  OUT_TSDYN = "output/TsDynEngine",
  OUT_RANK  = "output/InferenceRank_tsDyn",
  
  ## ----------------------------------------------------------
  ## Reproducibility
  ## ----------------------------------------------------------
  seed = 123456L,
  
  ## ----------------------------------------------------------
  ## Logging behaviour
  ## ----------------------------------------------------------
  SINK_POLICY      = "soft_close",
  VERBOSE_CONSOLE  = TRUE,
  HEARTBEAT_EVERY  = 25L,
  
  ## ----------------------------------------------------------
  ## Bootstrap parameters
  ## ----------------------------------------------------------
  B_target           = 1999L,
  B_pilot            = 200L,
  fail_threshold     = 0.10,
  max_attempt_factor = 6L,
  weight             = "rademacher",
  expl_abs_cap       = 1e8,
  
  ## ----------------------------------------------------------
  ## LR engine toggle
  ## ----------------------------------------------------------
  LR_ENGINE = "tsdyn",
  
  ## ----------------------------------------------------------
  ## Information Criteria diagnostic (placeholder)
  ## ----------------------------------------------------------
  IC_DIAGNOSTIC = list(
    eta_value = 1
  )
)