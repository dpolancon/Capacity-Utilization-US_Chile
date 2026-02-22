# ============================================================
# 10_config.R — ChaoGrid Confinement / Lattice config
# Repo: capacity_utilization/
# ============================================================

CONFIG <- list(
  
  # --- Data
  data_file  = "data/processed/ddbb_cu_US_kgr.xlsx",
  data_sheet = "us_data",
  
  # --- Variables (column names inside the sheet)
  year_col = "year",
  y_col    = "Yrgdp",
  k_col    = "KGCRcorp",
  e_col    = "e",
  
  # --- Windows (keep consistent with the chapter narrative)
  WINDOWS_LOCKED = list(
    full         = c(-Inf, Inf),
    fordism      = c(-Inf, 1973),
    post_fordism = c(1974,  Inf)
  ),
  
  # --- Johansen deterministics
  ECDET_LOCKED = c("none", "const"),
  
  # --- Lattice ranges
  P_MIN = 1L,
  P_MAX_EXPLORATORY = 7L,
  
  # --- Model specs
  # Interpretation used here:
  # Q2 = polynomial degree 2 block
  # Q3 = polynomial degree 3 block
  SPECS = list(
    Q2 = list(degree = 2L),
    Q3 = list(degree = 3L)
  ),
  
  # --- Toggle: orthogonalized polynomial basis vs raw standardized powers
  ORTHO_TOGGLE = c(FALSE, TRUE),
  
  # --- Include a non-orthogonalized linear term for e (raw or standardized)
  # Motivation: keep the first-order distribution/employment term explicit,
  # while still allowing orthogonalization of higher-order polynomial block.
  INCLUDE_E_RAW = TRUE,
  # Options:
  #   "raw" -> include e as observed
  #   "z"   -> include standardized z = (e-mean_full)/sd_full (LOCK: raw e only)
  E_RAW_MODE = "raw",
  
  # --- Outputs (under output/ChaoGrid/)
  OUT_ROOT = "output/ChaoGrid",
  
  # --- Engine behavior
  seed = 123456,
  johansen_spec = "transitory",
  
  
  # --- Logging / sinks (LOCKED)
  # Policy when sinks are already open at engine start:
  #   "stop"       -> fail fast with diagnostics (preferred)
  #   "soft_close" -> closes ONLY sink stacks (opt-in)
  SINK_POLICY = "soft_close",
  
  # --- Output labels (LOCKED naming convention)
  OUT_LABELS = list(appx = "APPX", essay = "ESSAY"),
  
  # --- Console heartbeat even when sink is active (split=TRUE)
  VERBOSE_CONSOLE = TRUE,
  HEARTBEAT_EVERY = 25L,
  
  DELTA_PIC_TOL = 2  # ejemplo: tolerancia ΔPIC para “ambiguity set”
)
