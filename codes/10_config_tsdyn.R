############################################################
# 10_config_tsdyn.R — tsDyn migration configuration
#
# This configuration file defines all constants and toggles used
# by the tsDyn‐based engine, diagnostics and rank inference
# scripts.  It mirrors the legacy 10_config.R but introduces
# explicit deterministic subspaces (DSR/DLR) and an LR engine
# toggle for flexibility.  Modify this file to adjust
# windows, variable names, or bootstrap parameters.  Do not
# overwrite legacy outputs; new outputs are written under
# output/TsDynEngine and output/InferenceRank_tsDyn.
############################################################

CONFIG <- list(
  ## Data location
  data_file  = "data/processed/ddbb_cu_US_kgr.xlsx",
  data_sheet = "us_data",

  ## Column names in the Excel sheet
  year_col = "year",
  y_col    = "Yrgdp",
  k_col    = "KGCRcorp",
  e_col    = "e",

  ## Sample windows (full sample must be first)
  WINDOWS_LOCKED = list(
    full         = c(-Inf, Inf),
    fordism      = c(-Inf, 1973),
    post_fordism = c(1974,  Inf)
  ),

  ## Deterministic subspaces
  # DSR controls short–run deterministics (Δ equations)
  # DLR controls long–run deterministics (cointegration space)
  # Allowed values: "none", "const" (trends can be added via ALLOW_TRENDS)
  DSR_SET = c("none", "const"),
  DLR_SET = c("none", "const"),

  # Explicit whitelist of allowed (DSR,DLR) pairs.  Modify this
  # list to add or remove specific deterministic structures.  Each
  # element must be a character vector of length 2.
  DET_PAIRS = list(
    c("none",  "none"),
    c("none",  "const"),
    c("const", "none")
  ),

  ## Trend deterministics toggle
  # Set to TRUE if trend terms should be available.  If enabled
  # you must also add the corresponding pairs to DET_PAIRS.
  ALLOW_TRENDS = FALSE,

  ## Lag settings
  # Minimum and maximum VECM lag order considered by the engine
  P_MIN = 1L,
  P_MAX_EXPLORATORY = 7L,
  # Default lag for Stage 0 and Stage 1 (VECM lag order)
  p_vecm_default = 1L,

  ## Model specifications
  # The structural manifold is defined via polynomial blocks Q2 and Q3.
  SPECS = list(
    Q1 = list(degree = 1L),  # NEW: linear e block
    Q2 = list(degree = 2L),
    Q3 = list(degree = 3L)
  ),

  ## Orthogonalization toggle (apply QR orthonormalization to the
  ## polynomial block).  Raw powers and orthogonalized bases are
  ## evaluated in parallel.  TRUE adds the ortho basis to the lattice.
  ORTHO_TOGGLE = c(FALSE, TRUE),

  ## Include exploitation rate as a raw linear term.  Only "raw"
  ## mode is currently supported (no z–scoring).  Changing this
  ## requires adjustments in build_state_vector().
  INCLUDE_E_RAW = TRUE,
  E_RAW_MODE    = "raw",

  ## Output roots for the tsDyn branch
  OUT_TSDYN = "output/TsDynEngine",
  OUT_RANK  = "output/InferenceRank_tsDyn",

  ## Random seed for reproducibility
  seed = 123456L,

  ## Sink / logging behaviour
  # Options: "stop" (fail if sinks are open) or "soft_close"
  SINK_POLICY = "soft_close",
  VERBOSE_CONSOLE = TRUE,
  HEARTBEAT_EVERY = 25L,

  ## Bootstrap parameters (Stage 1)
  B_target    = 1999L,
  B_pilot     = 200L,
  fail_threshold = 0.10,
  max_attempt_factor = 6L,
  weight      = "rademacher",
  expl_abs_cap = 1e8,

  ## LR engine toggle
  # "tsdyn" uses tsDyn::rank.test(); "urca" uses urca::ca.jo.
  LR_ENGINE = "tsdyn"
)
