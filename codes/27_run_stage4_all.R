# ============================================================
# 27_run_stage4_all.R
# Stage 4 orchestrator + manifest writer
# ============================================================

rm(list = ls())

# ---- helpers ---------------------------------------------------------------
iso_stamp <- function(x = Sys.time()) {
  format(x, "%Y-%m-%dT%H:%M:%S%z", tz = Sys.timezone())
}

safe_system <- function(cmd, args = character()) {
  out <- tryCatch(
    system2(cmd, args = args, stdout = TRUE, stderr = TRUE),
    error = function(e) structure(conditionMessage(e), status = 1L)
  )
  status <- attr(out, "status")
  if (is.null(status)) status <- 0L
  list(status = as.integer(status), output = as.character(out))
}

# ---- setup ----------------------------------------------------------------
source(here::here("codes", "10_config.R"))

run_start <- Sys.time()
run_id <- paste0("stage4_", format(run_start, "%Y%m%d_%H%M%S"))

tz_name <- Sys.timezone()
if (is.na(tz_name) || !nzchar(tz_name)) tz_name <- "UNKNOWN"

git_hash <- safe_system("git", c("rev-parse", "--short", "HEAD"))
git_hash_val <- if (git_hash$status == 0L) trimws(paste(git_hash$output, collapse = "\n")) else "UNAVAILABLE"

manifest_dir <- here::here("output", "CriticalReplication", "Manifest")
manifest_logs_dir <- file.path(manifest_dir, "logs")
dir.create(manifest_logs_dir, recursive = TRUE, showWarnings = FALSE)

sessioninfo_path <- file.path(manifest_logs_dir, "SESSIONINFO_stage4.txt")
writeLines(capture.output(sessionInfo()), con = sessioninfo_path)

# ---- script plan -----------------------------------------------------------
script_plan <- data.frame(
  script = c(
    "20_shaikh_ardl_replication.R",
    "21_CR_ARDL_grid.R",
    "22_VECM_S1.R",
    "23_VECM_S2.R",
    "26_crosswalk_tables.R"
  ),
  grid_dimensions = c(
    "Fixed ARDL replication (single locked specification)",
    "ARDL grid (p x q; values declared inside script)",
    "VECM S1 grid (lag/deterministic combinations; values declared inside script)",
    "VECM S2 grid (m=3, rank r in {0,1,2} + lag/deterministics as scripted)",
    "Crosswalk table builder (no independent grid)"
  ),
  stringsAsFactors = FALSE
)

script_plan$path <- file.path("codes", script_plan$script)
script_plan$exists <- vapply(
  script_plan$script,
  function(s) file.exists(here::here("codes", s)),
  logical(1)
)
script_plan$status <- "not_run"
script_plan$exit_code <- NA_integer_
script_plan$log_path <- NA_character_

# ---- execute ---------------------------------------------------------------
for (i in seq_len(nrow(script_plan))) {
  log_file <- file.path(manifest_logs_dir, sub("\\.R$", "_run.log", script_plan$script[i]))
  script_plan$log_path[i] <- file.path("output", "CriticalReplication", "Manifest", "logs", basename(log_file))

  if (!isTRUE(script_plan$exists[i])) {
    writeLines(sprintf("MISSING SCRIPT: %s", script_plan$path[i]), con = log_file)
    script_plan$status[i] <- "missing"
    script_plan$exit_code[i] <- NA_integer_
    next
  }

  run <- safe_system(
    R.home("bin/Rscript"),
    c(shQuote(here::here("codes", script_plan$script[i])))
  )

  writeLines(run$output, con = log_file)
  script_plan$exit_code[i] <- run$status
  script_plan$status[i] <- if (run$status == 0L) "ok" else "failed"
}

# ---- deviation checks ------------------------------------------------------
deviations <- character()
if (any(!script_plan$exists)) {
  deviations <- c(
    deviations,
    sprintf(
      "Lock not met: missing script(s): %s.",
      paste(script_plan$script[!script_plan$exists], collapse = ", ")
    )
  )
}
if (any(script_plan$status == "failed")) {
  deviations <- c(
    deviations,
    sprintf(
      "Lock not met: failed script(s): %s.",
      paste(script_plan$script[script_plan$status == "failed"], collapse = ", ")
    )
  )
}

if (is.null(CONFIG$WINDOWS_LOCKED$shaikh_window)) {
  deviations <- c(deviations, "Lock not met: CONFIG$WINDOWS_LOCKED$shaikh_window is missing.")
}

# ---- output artifact index -------------------------------------------------
artifact_files <- character()
if (dir.exists(here::here("output"))) {
  all_outputs <- list.files(here::here("output"), recursive = TRUE, full.names = TRUE)
  if (length(all_outputs) > 0L) {
    finfo <- file.info(all_outputs)
    artifact_files <- all_outputs[!is.na(finfo$mtime) & finfo$mtime >= run_start - 1]
    artifact_files <- normalizePath(artifact_files, winslash = "/", mustWork = FALSE)
    repo_root <- normalizePath(here::here(), winslash = "/", mustWork = TRUE)
    artifact_files <- sub(paste0("^", repo_root, "/"), "", artifact_files)
    artifact_files <- sort(unique(artifact_files))
  }
}

if (!length(artifact_files)) {
  deviations <- c(deviations, "No new/updated output artifacts were detected at runtime.")
}

# ---- write manifest markdown ----------------------------------------------
manifest_md_path <- file.path(manifest_dir, "RUN_MANIFEST_stage4.md")
manifest_csv_path <- file.path(manifest_dir, "RUN_MANIFEST_stage4.csv")

window_years <- CONFIG$WINDOWS_LOCKED$shaikh_window
window_label <- if (!is.null(window_years) && length(window_years) == 2L) {
  sprintf("%s-%s", window_years[[1]], window_years[[2]])
} else {
  "UNAVAILABLE"
}

md <- c(
  "# RUN MANIFEST — Stage 4",
  "",
  "## Run metadata",
  sprintf("- Run ID: `%s`", run_id),
  sprintf("- Timestamp: `%s`", iso_stamp(run_start)),
  sprintf("- Timezone: `%s`", tz_name),
  sprintf("- Git hash: `%s`", git_hash_val),
  sprintf("- Seed: `%s`", if (!is.null(CONFIG$seed)) as.character(CONFIG$seed) else "UNAVAILABLE"),
  sprintf("- Machine/OS: `%s`", paste(names(Sys.info()), Sys.info(), collapse = "; ")),
  "",
  "## Input data and variable mapping",
  sprintf("- Dataset path: `%s`", CONFIG$data_shaikh),
  sprintf("- Sheet: `%s`", CONFIG$data_shaikh_sheet),
  sprintf("- Year column: `%s`", CONFIG$year_col),
  sprintf("- Variables: Y_nom=`%s`, K_nom=`%s`, p_index=`%s`, u_shaikh=`%s`, e=`%s`", CONFIG$y_nom, CONFIG$k_nom, CONFIG$p_index, CONFIG$u_shaikh, CONFIG$e_rate),
  sprintf("- Window lock: `shaikh_window` (%s)", window_label),
  "",
  "## Script execution log (with grid dimensions)",
  "| Script | Path | Grid dimensions | Exists | Status | Exit code | Log |",
  "|---|---|---|---:|---|---:|---|"
)

for (i in seq_len(nrow(script_plan))) {
  md <- c(
    md,
    sprintf(
      "| `%s` | `%s` | %s | %s | %s | %s | `%s` |",
      script_plan$script[i],
      script_plan$path[i],
      script_plan$grid_dimensions[i],
      ifelse(isTRUE(script_plan$exists[i]), "yes", "no"),
      script_plan$status[i],
      ifelse(is.na(script_plan$exit_code[i]), "NA", as.character(script_plan$exit_code[i])),
      script_plan$log_path[i]
    )
  )
}

md <- c(md, "", "## Output artifact index (relative paths)")
if (length(artifact_files)) {
  md <- c(md, paste0("- `", artifact_files, "`"))
} else {
  md <- c(md, "- No artifacts indexed.")
}

md <- c(
  md,
  "",
  "## Session snapshot",
  sprintf("- `sessionInfo()` saved to `%s`", file.path("output", "CriticalReplication", "Manifest", "logs", basename(sessioninfo_path))),
  "",
  "## Deviations / notes"
)
if (length(deviations)) {
  md <- c(md, paste0("- ", deviations))
} else {
  md <- c(md, "- None.")
}

writeLines(md, con = manifest_md_path)

# optional CSV manifest
csv_manifest <- script_plan[, c("script", "path", "grid_dimensions", "exists", "status", "exit_code", "log_path")]
csv_manifest$run_id <- run_id
csv_manifest$timestamp <- iso_stamp(run_start)
csv_manifest$timezone <- tz_name
csv_manifest$git_hash <- git_hash_val
csv_manifest$seed <- if (!is.null(CONFIG$seed)) CONFIG$seed else NA_integer_
write.csv(csv_manifest, file = manifest_csv_path, row.names = FALSE)

message("Stage 4 runner complete.")
message("Manifest written: ", manifest_md_path)
message("Manifest CSV written: ", manifest_csv_path)
