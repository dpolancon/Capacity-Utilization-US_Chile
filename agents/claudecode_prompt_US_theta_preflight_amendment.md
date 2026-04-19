# Amendment to FINAL consolidated prompt
## Pre-flight variable audit guardrail
**Date:** 2026-04-13
**Inserts into:** `00_run_US_theta.R`, inside `load_panel()` and as a standalone Block before the main loop
**Purpose:** Detect column mismatches — particularly panels built with pi_t instead of omega_t — before any estimation runs. Never fail silently.

---

## WHERE TO INSERT

### 1. Replace `load_panel()` in `00_run_US_theta.R` with the extended version below.
### 2. Insert BLOCK PREFLIGHT after BLOCK 3 (data loading) and before BLOCK 4 (main loop).

---

## EXTENDED `load_panel()` — with variable audit

Replace the existing `load_panel()` function entirely with this version.
Changes: (a) pi_t → omega_t derivation added for both tracks, not just Corp;
(b) explicit audit log returned alongside the data frame;
(c) hard stop only when derivation is impossible.

```r
load_panel <- function(track) {

  # --- Resolve file path ---
  path <- NULL
  for (f in track$files) if (file.exists(f)) { path <- f; break }
  if (is.null(path)) stop(sprintf("[%s] No panel file found. Tried:\n  %s",
    track$label, paste(track$files, collapse="\n  ")))

  df   <- read.csv(path, stringsAsFactors=FALSE)
  cols <- names(df)

  audit <- list(
    sector     = track$label,
    file       = path,
    all_cols   = paste(cols, collapse=", "),
    year_col   = NA, y_col=NA, k_col=NA, omega_col=NA,
    omega_derived_from = NA,
    ok_rebuilt = FALSE,
    warnings   = character()
  )

  resolve <- function(aliases, df_cols) {
    m <- df_cols[tolower(df_cols) %in% tolower(aliases)]
    if (length(m) == 0) return(NA_character_)
    m[1]
  }

  # Year
  year_col <- resolve(c("year","yr","YEAR"), cols)
  if (is.na(year_col)) stop(sprintf("[%s] year column not found.", track$label))
  audit$year_col <- year_col

  # y_t
  y_col <- resolve(track$col_y, cols)
  if (is.na(y_col)) stop(sprintf(
    "[%s] y_t not found. Tried: %s\nAvailable: %s",
    track$label, paste(track$col_y, collapse=", "), paste(cols, collapse=", ")))
  audit$y_col <- y_col

  # k_t  — gross capital required; warn if net-stock alias detected
  k_col <- resolve(track$col_k, cols)
  if (is.na(k_col)) stop(sprintf(
    "[%s] k_t not found. Tried: %s\nAvailable: %s",
    track$label, paste(track$col_k, collapse=", "), paste(cols, collapse=", ")))
  audit$k_col <- k_col
  if (grepl("net|KNC|k_net|knet", k_col, ignore.case=TRUE)) {
    audit$warnings <- c(audit$warnings,
      sprintf("WARNING: k_col='%s' looks like a NET stock. Gross required for theta.", k_col))
  }

  # omega_t — primary resolution
  omega_col <- resolve(track$col_omega, cols)

  if (!is.na(omega_col)) {
    # Sanity check: omega should be in (0,1)
    vals <- suppressWarnings(as.numeric(df[[omega_col]]))
    vals <- vals[!is.na(vals)]
    if (length(vals) > 0 && (min(vals) < 0 || max(vals) > 1)) {
      audit$warnings <- c(audit$warnings,
        sprintf("WARNING: '%s' has values outside (0,1): [%.3f, %.3f]. Not a share?",
                omega_col, min(vals), max(vals)))
    }
    audit$omega_col <- omega_col
    audit$omega_derived_from <- "direct"

  } else {
    # omega not found directly — try derivation cascade

    # Case 1: pi_t (profit share) present → omega = 1 - pi_t
    # This catches panels built under the old pi_t specification
    pi_aliases <- c("pi_t","pi","profit_share","profsh","Profshcorp",
                    "Profshcorpt","profit_share_corp","profsh_corp",
                    "profit_share_nfc","profsh_nfc","pishare")
    pi_col <- resolve(pi_aliases, cols)

    if (!is.na(pi_col)) {
      df$omega_t <- 1 - suppressWarnings(as.numeric(df[[pi_col]]))
      omega_col  <- "omega_t"
      audit$omega_col <- omega_col
      audit$omega_derived_from <- paste0("1 - ", pi_col, "  [OLD pi_t SPEC DETECTED]")
      audit$warnings <- c(audit$warnings,
        sprintf("DERIVATION: omega_t = 1 - %s. Panel was built under pi_t spec.", pi_col))

    # Case 2: compensation and GVA columns present → omega = EC / GVA
    } else {
      ec_col  <- resolve(c("EC_NF","EC_nfc","compensation","EC","wages",
                           "employee_compensation"), cols)
      gva_col <- resolve(c("GVA_NF","GVA_nfc","GVA","value_added","gross_value_added"), cols)

      if (!is.na(ec_col) && !is.na(gva_col)) {
        df$omega_t <- suppressWarnings(as.numeric(df[[ec_col]])) /
                      suppressWarnings(as.numeric(df[[gva_col]]))
        omega_col  <- "omega_t"
        audit$omega_col <- omega_col
        audit$omega_derived_from <- paste0(ec_col, " / ", gva_col)
        audit$warnings <- c(audit$warnings,
          sprintf("DERIVATION: omega_t = %s / %s.", ec_col, gva_col))

      } else {
        stop(sprintf(
          "[%s] Cannot resolve omega_t. Tried direct aliases, 1-pi_t, and EC/GVA ratio.\nAvailable columns: %s",
          track$label, paste(cols, collapse=", ")))
      }
    }
  }

  # Check for stale ok_t: if ok_t is already in df, it may have been built with pi_t
  if ("ok_t" %in% cols) {
    # Recompute ok_t from resolved omega_t and k_t; compare to stored ok_t
    stored_ok   <- suppressWarnings(as.numeric(df[["ok_t"]]))
    computed_ok <- suppressWarnings(as.numeric(df[[omega_col]])) *
                   suppressWarnings(as.numeric(df[[k_col]]))
    ok_diff <- mean(abs(stored_ok - computed_ok), na.rm=TRUE)
    if (ok_diff > 1e-6) {
      audit$warnings <- c(audit$warnings,
        sprintf("WARNING: stored ok_t differs from omega_t*k_t by mean %.6f. Rebuilding ok_t.", ok_diff))
      df$ok_t       <- computed_ok
      audit$ok_rebuilt <- TRUE
    }
  }

  # Standardise column names to canonical
  out        <- data.frame(
    year    = as.integer(df[[year_col]]),
    y_t     = as.numeric(df[[y_col]]),
    k_t     = as.numeric(df[[k_col]]),
    omega_t = as.numeric(df[[omega_col]])
  )
  out        <- out[complete.cases(out), ]
  out        <- out[order(out$year), ]
  out$ok_t   <- out$omega_t * out$k_t   # always recompute from canonical omega

  audit$n_obs     <- nrow(out)
  audit$year_min  <- min(out$year)
  audit$year_max  <- max(out$year)
  audit$omega_min <- round(min(out$omega_t), 4)
  audit$omega_max <- round(max(out$omega_t), 4)

  list(data=out, audit=audit)
}
```

---

## BLOCK PREFLIGHT: Insert in `00_run_US_theta.R` after BLOCK 3, before BLOCK 4

```r
# ============================================================
# BLOCK PREFLIGHT: Variable audit — run before any estimation
# Loads all sector panels, runs audit, writes pre-flight report.
# Halts if any critical issue cannot be resolved automatically.
# ============================================================

panels     <- list()   # sector_nm -> data frame
audits     <- list()   # sector_nm -> audit list
pf_lines   <- c()      # pre-flight report lines

pf_lines <- c(pf_lines,
  "## Pre-flight variable audit",
  sprintf("Generated: %s", Sys.time()),
  sprintf("benchmark_year (FRB CAPUT peak): %d", benchmark_year),
  sprintf("CAPUT note: %s", caput_pin_note),
  "")

all_ok <- TRUE

for (sector_nm in names(sector_tracks)) {
  track  <- sector_tracks[[sector_nm]]

  result <- tryCatch(
    load_panel(track),
    error = function(e) {
      list(data=NULL, audit=list(
        sector=sector_nm, file="NOT FOUND",
        all_cols="—", year_col=NA, y_col=NA, k_col=NA,
        omega_col=NA, omega_derived_from=NA, ok_rebuilt=FALSE,
        warnings=paste("LOAD ERROR:", e$message),
        n_obs=0, year_min=NA, year_max=NA,
        omega_min=NA, omega_max=NA))
    }
  )

  audits[[sector_nm]] <- result$audit
  panels[[sector_nm]] <- result$data

  au <- result$audit

  pf_lines <- c(pf_lines,
    sprintf("### Sector: %s", sector_nm),
    "",
    sprintf("| Field | Value |"),
    sprintf("|-------|-------|"),
    sprintf("| File  | %s |", au$file),
    sprintf("| year  | %s |", au$year_col),
    sprintf("| y_t   | %s |", au$y_col),
    sprintf("| k_t   | %s |", au$k_col),
    sprintf("| omega_t | %s |", au$omega_col),
    sprintf("| omega derived from | %s |", au$omega_derived_from),
    sprintf("| ok_t rebuilt? | %s |", au$ok_rebuilt),
    sprintf("| N obs | %s |", au$n_obs),
    sprintf("| Year range | %s - %s |", au$year_min, au$year_max),
    sprintf("| omega range | [%s, %s] |", au$omega_min, au$omega_max),
    ""
  )

  if (length(au$warnings) > 0) {
    pf_lines <- c(pf_lines, "**Warnings:**", "")
    for (w in au$warnings) pf_lines <- c(pf_lines, sprintf("- %s", w))
    pf_lines <- c(pf_lines, "")
  }

  # Flag critical failures
  if (is.null(result$data)) {
    pf_lines <- c(pf_lines, sprintf("**CRITICAL: %s panel failed to load.**", sector_nm), "")
    all_ok   <- FALSE
  }

  # Flag if omega derivation used old pi_t spec
  if (!is.na(au$omega_derived_from) &&
      grepl("pi_t SPEC", au$omega_derived_from, ignore.case=TRUE)) {
    pf_lines <- c(pf_lines,
      sprintf("**FLAG: %s panel was built under pi_t spec. omega_t auto-derived as 1-pi_t.**", sector_nm),
      "Verify this is the correct transformation before trusting estimation results.", "")
  }

  cat(sprintf("[preflight] %s: %s\n", sector_nm,
              if(is.null(result$data)) "FAILED" else "OK"))
  for (w in au$warnings) cat(sprintf("  [!] %s\n", w))
}

# Sample coverage check: warn if Fordist window 1945-1978 is not fully covered
for (sector_nm in names(panels)) {
  df_check <- panels[[sector_nm]]
  if (is.null(df_check)) next
  fordist_yrs <- 1945:1978
  missing_fordist <- fordist_yrs[!fordist_yrs %in% df_check$year]
  if (length(missing_fordist) > 0) {
    msg <- sprintf("[%s] Fordist window gap: missing years %s",
                   sector_nm, paste(range(missing_fordist), collapse="-"))
    pf_lines <- c(pf_lines, paste("**WARNING:**", msg), "")
    cat(sprintf("[preflight] %s\n", msg))
  }
}

# Write pre-flight report
pf_file <- file.path(out_dir, "US_preflight_audit_130426.md")
writeLines(pf_lines, pf_file)
cat(sprintf("[preflight] Report written: %s\n", pf_file))

# Hard stop if any panel failed entirely
if (!all_ok) {
  stop(paste(
    "[preflight] One or more sector panels failed to load.",
    "Fix column mapping or file paths before re-running.",
    sprintf("See %s for details.", pf_file)
  ))
}

cat("[preflight] All panels loaded. Proceeding to estimation.\n\n")

# Pass panels into the main loop — replace load_panel() calls there
# BLOCK 4 should use panels[[sector_nm]] directly instead of calling load_panel() again
```

---

## CORRESPONDING CHANGE TO BLOCK 4 (main loop)

In the main loop in `00_run_US_theta.R`, replace:

```r
df_all <- tryCatch(load_panel(track), error=function(e) { message(e$message); NULL })
if (is.null(df_all)) next
```

with:

```r
df_all <- panels[[sector_nm]]
if (is.null(df_all)) {
  message(sprintf("[%s] Panel not available (pre-flight failed). Skipping.", sector_nm))
  next
}
```

This ensures data loading happens exactly once (in BLOCK PREFLIGHT), not twice.

---

## WHAT THE GUARDRAIL CATCHES

| Condition | Behaviour |
|-----------|-----------|
| Panel file not found at any candidate path | Hard stop with all tried paths listed |
| `omega_t` column missing, `pi_t` present | Auto-derives `omega_t = 1 − pi_t`, flags in report, continues |
| `omega_t` missing, neither `pi_t` nor EC/GVA present | Hard stop with available columns listed |
| `ok_t` stored in panel but built from old `pi_t` | Detects mean difference, rebuilds `ok_t = omega_t * k_t`, flags |
| `k_t` column looks like a net stock (`KNC`, `k_net`) | Warning in report, does not halt (user decides) |
| `omega_t` values outside (0, 1) | Warning — possible percentage rather than share |
| Fordist window 1945–1978 not fully covered | Warning in report, does not halt |
| `year` column not found | Hard stop |

---

## PRE-FLIGHT OUTPUT FILE

`outputs/DOLS_results_130426/US_preflight_audit_130426.md`

Written unconditionally before any estimation. Contains sector-by-sector column
resolution table, all warnings, omega derivation method, and CAPUT pin confirmation.
This file is the first thing to check if estimation results look wrong.

---

## WHAT DOES NOT CHANGE

Everything else in the consolidated prompt is unchanged.
The three R scripts retain the same block structure.
Only `load_panel()` is replaced and BLOCK PREFLIGHT is inserted.
