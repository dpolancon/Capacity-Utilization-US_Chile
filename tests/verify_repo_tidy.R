#!/usr/bin/env Rscript

# verify_repo_tidy.R
# Automated Verification Script for Repository Tidiness Rules
# Checks:
# 1. codes/ contains no subdirectories other than legacy/ and runs/
# 2. data/metadata/data_provenance_manifest.md exists and has valid YAML header with 6 mandatory fields
# 3. All markdown files in chapter2_vault/, reports/, drafts/ contain valid YAML headers with 6 mandatory fields

suppressPackageStartupMessages({
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("R package 'yaml' is required but not installed.")
  }
  library(yaml)
})

GREEN <- "\033[32m"
RED <- "\033[31m"
BOLD <- "\033[1m"
RESET <- "\033[0m"

mandatory_fields <- c("type", "status", "depends_on", "stage_scope", "country", "last_updated")

parse_yaml_frontmatter <- function(file_path) {
  lines <- tryCatch(
    readLines(file_path, warn = FALSE, encoding = "UTF-8"),
    error = function(e) return(list(valid = FALSE, error = paste("File read error:", e$message)))
  )
  if (is.null(lines) || length(lines) < 3) {
    return(list(valid = FALSE, error = "File empty or too short for YAML header"))
  }
  
  lines[1] <- sub("^\ufeff", "", lines[1])
  
  if (trimws(lines[1]) != "---") {
    return(list(valid = FALSE, error = "First line is not '---'"))
  }
  
  closing_idx <- which(trimws(lines[2:length(lines)]) == "---")
  if (length(closing_idx) == 0) {
    return(list(valid = FALSE, error = "No closing '---' frontmatter line found"))
  }
  
  end_line <- closing_idx[1] + 1
  if (end_line <= 2) {
    yaml_lines <- ""
  } else {
    yaml_lines <- lines[2:(end_line - 1)]
  }
  yaml_str <- paste(yaml_lines, collapse = "\n")
  
  parsed <- tryCatch(
    yaml::yaml.load(yaml_str),
    error = function(e) return(list(valid = FALSE, error = paste("YAML parse error:", e$message)))
  )
  
  if (is.null(parsed) || !is.list(parsed)) {
    return(list(valid = FALSE, error = "YAML content did not parse as a key-value object"))
  }
  
  missing_keys <- setdiff(mandatory_fields, names(parsed))
  if (length(missing_keys) > 0) {
    return(list(
      valid = FALSE,
      error = paste("Missing mandatory field(s):", paste(missing_keys, collapse = ", ")),
      parsed = parsed
    ))
  }
  
  return(list(valid = TRUE, parsed = parsed))
}

run_verification <- function() {
  cat(paste0(BOLD, "====================================================\n"))
  cat(paste0("  REPOSITORY TIDINESS VERIFICATION REPORT\n"))
  cat(paste0("====================================================\n\n", RESET))
  
  all_passed <- TRUE
  
  # ----------------------------------------------------
  # Check 1: Subdirectories of codes/
  # ----------------------------------------------------
  cat(paste0(BOLD, "[Check 1] Verify codes/ contains no subdirectories other than 'legacy/' and 'runs/'\n", RESET))
  codes_dir <- "codes"
  if (!dir.exists(codes_dir)) {
    cat(paste0("  Status: ", RED, "FAIL", RESET, " - Directory 'codes/' does not exist.\n\n"))
    all_passed <- FALSE
  } else {
    subdirs <- list.dirs(codes_dir, recursive = FALSE, full.names = FALSE)
    allowed_subdirs <- c("legacy", "runs")
    disallowed_subdirs <- setdiff(subdirs, allowed_subdirs)
    
    if (length(disallowed_subdirs) > 0) {
      cat(paste0("  Status: ", RED, "FAIL", RESET, " - Found disallowed subdirectories in codes/: ",
                 paste(disallowed_subdirs, collapse = ", "), "\n\n"))
      all_passed <- FALSE
    } else {
      cat(paste0("  Status: ", GREEN, "PASS", RESET, " - Top-level subdirectories in codes/ are restricted to 'legacy/' and 'runs/'.\n"))
      cat(paste0("          Found subdirectories: ", paste(subdirs, collapse = ", "), "\n\n"))
    }
  }
  
  # ----------------------------------------------------
  # Check 2: data/metadata/data_provenance_manifest.md
  # ----------------------------------------------------
  cat(paste0(BOLD, "[Check 2] Verify data/metadata/data_provenance_manifest.md exists & has valid YAML header\n", RESET))
  manifest_path <- "data/metadata/data_provenance_manifest.md"
  if (!file.exists(manifest_path)) {
    cat(paste0("  Status: ", RED, "FAIL", RESET, " - Manifest file '", manifest_path, "' does not exist.\n\n"))
    all_passed <- FALSE
  } else {
    result <- parse_yaml_frontmatter(manifest_path)
    if (!result$valid) {
      cat(paste0("  Status: ", RED, "FAIL", RESET, " - ", result$error, "\n\n"))
      all_passed <- FALSE
    } else {
      cat(paste0("  Status: ", GREEN, "PASS", RESET, " - data_provenance_manifest.md exists and contains all 6 mandatory YAML fields:\n"))
      cat(paste0("          (", paste(mandatory_fields, collapse = ", "), ")\n\n"))
    }
  }
  
  # ----------------------------------------------------
  # Check 3: Active vault & reports/drafts markdown frontmatter
  # ----------------------------------------------------
  cat(paste0(BOLD, "[Check 3] Verify all markdown files in chapter2_vault/, reports/, drafts/ have valid 6-field YAML headers\n", RESET))
  search_dirs <- c("chapter2_vault", "reports", "drafts")
  existing_dirs <- search_dirs[dir.exists(search_dirs)]
  
  md_files <- c()
  for (d in existing_dirs) {
    files <- list.files(d, pattern = "\\.md$", recursive = TRUE, full.names = TRUE)
    md_files <- c(md_files, files)
  }
  
  if (length(md_files) == 0) {
    cat(paste0("  Status: ", RED, "FAIL", RESET, " - No markdown files found in target directories.\n\n"))
    all_passed <- FALSE
  } else {
    failed_files <- list()
    for (f in md_files) {
      res <- parse_yaml_frontmatter(f)
      if (!res$valid) {
        failed_files[[f]] <- res$error
      }
    }
    
    if (length(failed_files) > 0) {
      cat(paste0("  Status: ", RED, "FAIL", RESET, " - ", length(failed_files), " file(s) failed YAML header verification:\n"))
      for (fn in names(failed_files)) {
        cat(paste0("          - ", fn, ": ", failed_files[[fn]], "\n"))
      }
      cat("\n")
      all_passed <- FALSE
    } else {
      cat(paste0("  Status: ", GREEN, "PASS", RESET, " - Checked ", length(md_files), " markdown files across ",
                 paste(existing_dirs, collapse = ", "), ".\n"))
      cat(paste0("          All ", length(md_files), " files contain valid YAML headers with all 6 mandatory fields.\n\n"))
    }
  }
  
  # ----------------------------------------------------
  # Summary Report & Exit
  # ----------------------------------------------------
  cat(paste0(BOLD, "----------------------------------------------------\n"))
  if (all_passed) {
    cat(paste0("  OVERALL VERIFICATION STATUS: ", GREEN, "PASS (ALL CHECKS OK)", RESET, "\n"))
    cat(paste0(BOLD, "====================================================\n\n", RESET))
    quit(save = "no", status = 0)
  } else {
    cat(paste0("  OVERALL VERIFICATION STATUS: ", RED, "FAIL", RESET, "\n"))
    cat(paste0(BOLD, "====================================================\n\n", RESET))
    quit(save = "no", status = 1)
  }
}

run_verification()
