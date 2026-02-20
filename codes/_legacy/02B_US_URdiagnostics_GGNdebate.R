# ============================================
# Stage 2 — Debate Build (Nikiforos-vs-Gahn aware)
# Outputs: output/diagnostics/stage2/debate_build/*.tex, *.csv
# Mirrors your Stage 2 Formal Diagnostics scaffolding.
# ============================================

#### 0) Packages ####
pkgs <- c(
  "here","readxl","dplyr","tidyr","ggplot2","zoo","patchwork","stats",
  "knitr","kableExtra","urca","lmtest","tseries","fracdiff"
)
invisible(lapply(pkgs, require, character.only = TRUE))
has_uroot <- requireNamespace("uroot", quietly = TRUE)  # optional Lee–Strazicich

#### 1) Preamble: paths, helpers, data ####
source(paste0(here("codes"), "/0_functions.R"))  # add_stars, table_as_is, ensure_dirs, set_seed_deterministic, write_session_info, etc.
data_path   <- here("data/ddbb_cu_US_kgr.xlsx")
output_path <- here("output")
set_seed_deterministic()

diag_dir     <- file.path(output_path, "diagnostics","stage2")
debate_dir   <- file.path(diag_dir, "debate_build")
ensure_dirs(c(diag_dir, debate_dir))

log_file <- file.path(debate_dir, "debate_build_debug.log")
cat("", file = log_file)
logf <- function(...) {
  cat(sprintf("[%s] ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")), file = log_file, append = TRUE)
  cat(paste0(paste0(..., collapse = ""), "\n"), file = log_file, append = TRUE)
}

export_placeholder_tex <- function(path, title, msg) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  txt <- sprintf("\\begin{table}[H]\n\\centering\n\\caption{%s}\n\\begin{tabular}{c}\n\\toprule\n\\textit{%s}\\\\\n\\bottomrule\n\\end{tabular}\n\\end{table}\n",
                 gsub("\\\\", "\\\\", title), gsub("_", "\\\\_", msg))
  writeLines(txt, path, useBytes = TRUE)
  logf("PLACEHOLDER -> ", path, " :: ", msg)
}

safe_table_as_is <- function(obj, file_path, caption) {
  tryCatch({
    table_as_is(obj, file_path = file_path, caption = caption,
                format = "latex", overwrite = TRUE, escape = TRUE)
    logf("WROTE -> ", file_path)
  }, error = function(e) {
    export_placeholder_tex(file_path, caption, paste("Export failed:", conditionMessage(e)))
  })
}

# Data
ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

#### 2) Build variables (exact scope you used) ####
dfv <- ddbb_us |>
  dplyr::transmute(
    year      = .data$year,
    K         = .data$KGCRcorp,
    Y         = .data$Yrgdp,
    e         = .data$e,
    yk_input  = .data$yk,
    yk_calc   = .data$Yrgdp / .data$KGCRcorp,
    log_y     = log(.data$Yrgdp),
    log_k     = log(.data$KGCRcorp),
    log_yk    = log(yk_calc),
    e2        = (.data$e)^2,
    d_yk      = yk_calc - dplyr::lag(yk_calc),
    d_log_y   = log_y - dplyr::lag(log_y),
    d_log_k   = log_k - dplyr::lag(log_k),
    d_log_yk  = log_yk - dplyr::lag(log_yk),
    d_e       = e - dplyr::lag(e),
    d_e2      = e2 - dplyr::lag(e2)
  )

if ("yk_input" %in% names(dfv)) {
  d_mx <- suppressWarnings(max(abs(dfv$yk_input - dfv$yk_calc), na.rm = TRUE))
  if (is.finite(d_mx) && d_mx > 1e-8) logf(sprintf("WARN: yk mismatch max |input - calc| = %.3e", d_mx))
}
if (sum(is.finite(dfv$log_yk)) <= 20) stop("Too few usable observations for log_yk")

#### 3) Debate-build tests (functions) ####
schwert_cap <- function(T) floor(12*(T/100)^(1/4))

adf_long_seq <- function(x, model = c("constant","trend"), alpha = 0.10) {
  model <- match.arg(model); x <- as.numeric(x)
  Tn <- sum(is.finite(x)); pmax <- max(0L, schwert_cap(Tn))
  keep_p <- 0L; tcrit <- qnorm(1 - alpha/2); out <- NULL
  for (p in pmax:0) {
    type <- if (model == "constant") "drift" else "trend"
    fit  <- try(urca::ur.df(x, type = type, lags = p, selectlags = "Fixed"), silent = TRUE)
    if (inherits(fit,"try-error")) next
    if (p == 0L) { keep_p <- 0L; out <- fit; break }
    summ <- try(summary(fit), silent = TRUE); if (inherits(summ,"try-error")) next
    coefs <- try(summ@testreg$coefficients, silent = TRUE)
    if (inherits(coefs,"try-error") || nrow(coefs)==0L) next
    rn <- rownames(coefs)
    id_last <- grep(paste0("(d\\(x\\)|Delta x|dx)\\.", p, "$"), rn, ignore.case = TRUE)
    if (length(id_last) == 0L) id_last <- tail(which(!grepl("\\(Intercept\\)|z\\.lag\\.1|const|trend", rn, ignore.case = TRUE)), 1)
    if (length(id_last) == 0L) next
    t_last <- suppressWarnings(as.numeric(coefs[id_last, "t value"]))
    if (is.finite(t_last) && abs(t_last) > tcrit) { keep_p <- p; out <- fit; break }
  }
  key   <- if (model == "constant") "tau2" else "tau3"
  stat  <- tryCatch(as.numeric(out@teststat[key]), error = function(e) NA_real_)
  crit5 <- tryCatch(as.numeric(out@cval["5pct"]),  error = function(e) NA_real_)
  pval  <- tryCatch(out@testreg$coefficients["z.lag.1","Pr(>|t|)"], error = function(e) NA_real_)
  list(p = keep_p, stat = stat, crit5 = crit5, pval = pval)
}

pp_long <- function(x, model = c("constant","trend")) {
  model <- match.arg(model)
  fit <- try(urca::ur.pp(as.numeric(x), type = "Z-tau",
                         model = if (model=="constant") "constant" else "trend",
                         lags = "long"), silent = TRUE)
  if (inherits(fit,"try-error")) return(NA_real_)
  as.numeric(fit@teststat)
}

dfgls_stat <- function(x, model=c("constant","trend"), lag.max=8){
  model <- match.arg(model)
  fit <- try(urca::ur.ers(as.numeric(x), type="DF-GLS",
                          model = if (model=="constant") "constant" else "trend",
                          lag.max=lag.max), silent=TRUE)
  if (inherits(fit,"try-error")) return(NA_real_)
  as.numeric(fit@teststat)
}

ers_po_stat <- function(x, model=c("constant","trend"), lag.max=8){
  model <- match.arg(model)
  fit <- try(urca::ur.ers(as.numeric(x), type="P-test",
                          model = if (model=="constant") "constant" else "trend",
                          lag.max=lag.max), silent=TRUE)
  if (inherits(fit,"try-error")) return(NA_real_)
  as.numeric(fit@teststat)
}

ng_perron_MZt <- function(x, model=c("constant","trend")){
  model <- match.arg(model)
  fit <- try(urca::ur.ngp(as.numeric(x), type = if (model=="constant") "level" else "trend"), silent=TRUE)
  if (inherits(fit,"try-error")) return(NA_real_)
  as.numeric(fit@teststat["MZt"])
}

za_stat <- function(x, model=c("intercept","trend","both")){
  model <- match.arg(model)
  fit <- try(urca::ur.za(as.numeric(x), model=model), silent=TRUE)
  if (inherits(fit,"try-error")) return(NA_real_)
  as.numeric(fit@teststat)
}

ls_stat <- function(x){
  if (!has_uroot) return(NA_real_)
  fit <- try(uroot::ls.unitroot(as.numeric(x), demeaning="both"), silent=TRUE)
  if (inherits(fit,"try-error")) return(NA_real_)
  as.numeric(fit$stat)
}

gph_d <- function(x){
  est <- try(fracdiff::fdGPH(na.omit(as.numeric(x))), silent=TRUE)
  if (inherits(est,"try-error")) return(NA_real_)
  as.numeric(est$d)
}

decide_integration <- function(stats){
  rej <- c(
    DFGLS = if (!is.na(stats$DF_GLS))   stats$DF_GLS   < -2.9 else NA,
    ERSPO = if (!is.na(stats$ERS_PO))   stats$ERS_PO   <  3.0 else NA,
    ADFL  = if (!is.na(stats$ADF_long)) stats$ADF_long < -2.9 else NA,
    PPL   = if (!is.na(stats$PP_long))  stats$PP_long  < -3.0 else NA,
    NGP   = if (!is.na(stats$NP_MZt))   stats$NP_MZt   < -2.9 else NA
  )
  n_rej <- sum(rej, na.rm=TRUE); n_valid <- sum(!is.na(rej))
  za_ok <- !is.na(stats$ZA_stat) && stats$ZA_stat < -4.8
  ls_ok <- !is.na(stats$LS_stat) && stats$LS_stat < -3.5
  d_hat <- stats$GPH_d
  
  if (n_valid>0 && n_rej/n_valid >= 0.6 && (is.na(d_hat) || d_hat <= 0.5)) {
    c("I(0)", "Unit-root null rejected by majority; no strong fractional evidence.")
  } else if (!is.na(d_hat) && d_hat > 0.5 && d_hat < 1) {
    c("Near-I(1) / fractional", sprintf("Fractional integration d≈%.2f; very persistent.", d_hat))
  } else if (!za_ok && !ls_ok) {
    c("I(1)", "Break-robust UR fail to reject; consistent with non-stationarity.")
  } else {
    c("Ambiguous", "Discordant tests; treat as near-integrated or break-stationary.")
  }
}

run_debate_tests <- function(x, name, model = c("constant","trend")) {
  model <- match.arg(model)
  adf <- adf_long_seq(x, model)
  stats <- list(
    DF_GLS   = dfgls_stat(x, model),
    ERS_PO   = ers_po_stat(x, model),
    ADF_long = adf$stat,
    PP_long  = pp_long(x, model),
    NP_MZt   = ng_perron_MZt(x, model),
    ZA_stat  = if (model=="trend") za_stat(x, "trend") else za_stat(x, "intercept"),
    LS_stat  = ls_stat(x),
    GPH_d    = gph_d(x)
  )
  dec <- decide_integration(stats)
  data.frame(
    Variable = name,
    Model    = model,
    DF_GLS   = round(stats$DF_GLS, 3),
    ERS_PO   = round(stats$ERS_PO, 3),
    ADF_long = round(stats$ADF_long, 3),
    PP_long  = round(stats$PP_long, 3),
    NP_MZt   = round(stats$NP_MZt, 3),
    ZA_stat  = round(stats$ZA_stat, 3),
    LS_stat  = round(stats$LS_stat, 3),
    GPH_d    = round(stats$GPH_d, 2),
    Call     = dec[1],
    Note     = dec[2],
    stringsAsFactors = FALSE
  )
}

run_debate_on_df <- function(dfv, export_dir = debate_dir){
  vars <- list(
    "log Y"    = dfv$log_y,
    "log K"    = dfv$log_k,
    "log(Y/K)" = dfv$log_yk,
    "e"        = dfv$e,
    "e2"       = dfv$e2
  )
  const <- do.call(rbind, lapply(names(vars), function(nm) run_debate_tests(vars[[nm]], nm, "constant")))
  trend <- do.call(rbind, lapply(names(vars), function(nm) run_debate_tests(vars[[nm]], nm, "trend")))
  
  utils::write.csv(const, file.path(export_dir, "UR_debate_panel_constant.csv"), row.names = FALSE)
  utils::write.csv(trend, file.path(export_dir, "UR_debate_panel_trend.csv"),    row.names = FALSE)
  
  # LaTeX exports (robust)
  safe_table_as_is(const, file.path(export_dir, "UR_debate_panel_constant.tex"), "Debate-build unit root panel (constant)")
  safe_table_as_is(trend, file.path(export_dir, "UR_debate_panel_trend.tex"),    "Debate-build unit root panel (trend)")
  
  list(constant = const, trend = trend)
}

summarize_calls <- function(results, export_dir = debate_dir){
  mk <- function(df, spec) transform(df[, c("Variable","Call","Note")], Spec = spec)
  allc <- rbind(mk(results$constant, "constant"), mk(results$trend, "trend"))
  utils::write.csv(allc, file.path(export_dir, "UR_debate_calls.csv"), row.names = FALSE)
  safe_table_as_is(allc[, c("Variable","Spec","Call","Note")],
                   file.path(export_dir, "UR_debate_calls.tex"),
                   "Debate-build: integration calls and notes")
  allc
}

#### 4) Run and export ####
try({
  stopifnot(all(c("log_y","log_k","log_yk","e","e2") %in% names(dfv)))
  results <- run_debate_on_df(dfv, export_dir = debate_dir)
  calls   <- summarize_calls(results, export_dir = debate_dir)
  logf("DONE Debate Build. Outputs -> ", normalizePath(debate_dir, winslash = "/"))
}, silent = FALSE)

#### 5) Session info ####
write_session_info(file.path(debate_dir, "session_info.txt"))
