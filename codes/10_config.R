############################################################
# 10_config.R — Chapter 3 Critical Replication configuration
#
# Lag convention (FROZEN):
#   In tsDyn:
#     VECM(lag = p)  =>  p lags of dX in the short run.
#   Therefore:
#     r = 0 null (no Pi term) must be estimated as
#       lineVar(..., lag = p, I = "diff")
#
#   We DO NOT use (p - 1) mapping.
#   We DO NOT reinterpret lag as VAR-levels lag.
#   We take tsDyn's lag argument literally.
############################################################

CONFIG <- list(

  ## ----------------------------------------------------------
  ## Shaikh replication data
  ## ----------------------------------------------------------
  ## Corporate sector dataset (built by 50-series pipeline)
  data_shaikh       = "data/processed/corporate_sector_dataset.csv",
  SHOCK_TYPE        = "permanent",   # "permanent" (step) or "transitory" (impulse)
  # exploitation rate construction audit trail (not loaded directly):
  # data/raw/Shaikh_exploitation_rate_faithful_v1.csv

  ## Previous (canonical CSV, whole-economy):
  ##   data_shaikh = "data/raw/Shaikh_canonical_series_v1.csv"
  ##   y_nom = "VAcorp", k_nom = "KGCcorp", p_index = "pIGcorpbea"

  ## Variables in the corporate dataset
  year_col = "year",
  y_nom    = "GVAcorp",      # Corporate GVA (imputed interest adjusted)
  k_nom    = "KGCcorp",      # Shaikh-adjusted gross K stock (GPIM)
  u_shaikh = "uK",           # Capacity utilization (NA until ARDL run)
  pi_share = "profit_share", # Corporate profit share
  p_index  = "Py",           # GDP implicit price deflator (common deflator)
  e_rate   = "exploit_rate",  # Exploitation rate: NOScorp/ECcorp

  

  
  
  ## ----------------------------------------------------------
  ## Sample windows (full sample must be first)
  ## ----------------------------------------------------------
  WINDOWS_LOCKED = list(
    shaikh_window = c(1947, 2011),   # was c(1947, 2011) — T=61 per Table 6.7.14
    full          = c(-Inf, Inf),
    fordism       = c(-Inf, 1973),
    post_fordism  = c(1974,  Inf)
  ),

  ## ----------------------------------------------------------
  ## Deterministic subspaces
  ##
  ## DSR = short-run deterministic (d equations)  -> tsDyn include
  ## DLR = long-run deterministic (cointegration) -> tsDyn LRinclude
  ##
  ## Allowed values: "none", "const"
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
  ## Critical replication canonical outputs (S0/S1/S2 structure)
  ## ----------------------------------------------------------
  OUT_CR = list(
    S0_faithful  = "output/CriticalReplication/S0_faithful",
    S1_geometry  = "output/CriticalReplication/S1_geometry",
    S2_vecm      = "output/CriticalReplication/S2_vecm",
    results_pack = "output/CriticalReplication/ResultsPack",
    manifest     = "output/CriticalReplication/Manifest"
  ),

  ## ----------------------------------------------------------
  ## Reproducibility
  ## ----------------------------------------------------------
  seed = 123456L,

  ## ----------------------------------------------------------
  ## Logging behaviour
  ## ----------------------------------------------------------
  HEARTBEAT_EVERY = 25L,

  ## ----------------------------------------------------------
  ## GDP & Capital Stock module (40-series)
  ## ----------------------------------------------------------
  gdp_kstock_config = "codes/40_gdp_kstock_config.R",
  DATA_INTERIM      = "data/interim",
  DATA_PROCESSED    = "data/processed"
)
