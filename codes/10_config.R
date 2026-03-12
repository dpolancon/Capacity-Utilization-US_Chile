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
  ## Shaikh replication data (raw)
  ## ----------------------------------------------------------
  data_shaikh       = "data/raw/Shaikh_RepData.xlsx",
  data_shaikh_sheet = "long",

  ## Variables in the Shaikh sheet
  year_col = "year",
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
  HEARTBEAT_EVERY = 25L
)
