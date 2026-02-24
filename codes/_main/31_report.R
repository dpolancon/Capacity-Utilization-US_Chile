  ############################################################
  ## 31_report.R — ChaoGrid 3D Surface Viewer (VIEWER ONLY)
  ## Project: capacity_utilization / ChaoGrid
  ## Contract:
  ##  - Use ONLY CSV artifacts produced by codes/20_engine.R
  ##  - No estimation. No modification of PIC values.
  ##  - Precompute master_grid slices once; Plotly toggles only visibility.
  ##  - Controls toggle visibility only (no UI recompute).
  ############################################################
  
  suppressPackageStartupMessages({
    pkgs <- c(
      "here","dplyr","tidyr","readr","stringr","purrr",
      "plotly","htmlwidgets","akima"
    )
    invisible(lapply(pkgs, require, character.only = TRUE))
  })
  
  source(here::here("codes", "10_config.R"))
  source(here::here("codes", "99_utils.R"))
  
  # ----------------------------
  # Guards
  # ----------------------------
  stopifnot(!is.null(CONFIG$OUT_ROOT))
  stopifnot(!is.null(CONFIG$DELTA_PIC_TOL))  # contract requirement
  
  ROOT_OUT <- here::here(CONFIG$OUT_ROOT)
  
  DIRS <- list(
    csv  = file.path(ROOT_OUT, "csv"),
    html = file.path(ROOT_OUT, "html"),
    logs = file.path(ROOT_OUT, "logs")
  )
  ensure_dirs(DIRS$csv, DIRS$html, DIRS$logs)
  
  cat("=== 31_report.R start (viewer-only) ===\n")
  cat("Output root:", ROOT_OUT, "\n\n")
  
  # ----------------------------
  # Expected inputs (subset allowed)
  # ----------------------------
  expected_files <- c(
    file.path(DIRS$csv, "grid_pic_table_Q2_raw_unrestricted.csv"),
    file.path(DIRS$csv, "grid_pic_table_Q2_ortho_unrestricted.csv"),
    file.path(DIRS$csv, "grid_pic_table_Q3_raw_unrestricted.csv"),
    file.path(DIRS$csv, "grid_pic_table_Q3_ortho_unrestricted.csv")
  )
  
  present_files <- expected_files[file.exists(expected_files)]
  missing_files <- expected_files[!file.exists(expected_files)]
  
  cat("Inputs check:\n")
  cat("  Present:", length(present_files), "\n")
  if (length(present_files) > 0) cat(paste0("   - ", present_files, collapse = "\n"), "\n")
  cat("  Missing:", length(missing_files), "\n")
  if (length(missing_files) > 0) cat(paste0("   - ", missing_files, collapse = "\n"), "\n")
  cat("\n")
  
  if (length(present_files) == 0) {
    stop("No engine CSVs found. Expected at least one grid_pic_table_*.csv file in output/ChaoGrid/csv.")
  }
  
  # ============================================================
  # Helpers
  # ============================================================
  
  `%||%` <- function(a, b) if (!is.null(a) && length(a) >= 1) a else b
  
  infer_spec_basis <- function(path) {
    # Infer from filename only if missing in data; do NOT invent otherwise.
    fn <- basename(path)
    spec <- NA_character_
    basis <- NA_character_
    if (stringr::str_detect(fn, "Q2")) spec <- "Q2"
    if (stringr::str_detect(fn, "Q3")) spec <- "Q3"
    if (stringr::str_detect(fn, "_raw_"))   basis <- "raw"
    if (stringr::str_detect(fn, "_ortho_")) basis <- "ortho"
    list(spec = spec, basis = basis)
  }
  
  coerce_bool <- function(x) {
    if (is.logical(x)) return(x)
    if (is.numeric(x)) return(x == 1)
    if (is.character(x)) {
      xl <- tolower(trimws(x))
      return(xl %in% c("1","true","t","yes","y"))
    }
    rep(FALSE, length(x))
  }
  
  read_one_grid <- function(path) {
    inf <- infer_spec_basis(path)
    df <- suppressMessages(readr::read_csv(path, show_col_types = FALSE, progress = FALSE))
    
    # Minimal coercions (in-memory only)
    if ("p" %in% names(df)) df$p <- as.integer(df$p)
    if ("r" %in% names(df)) df$r <- as.integer(df$r)
    
    # status handling
    if (!("status" %in% names(df))) {
      df$status <- "computed"
    } else {
      df$status <- as.character(df$status)
    }
    
    # PIC_obs mapping
    if ("PIC_obs" %in% names(df)) {
      df$PIC_obs <- suppressWarnings(as.numeric(df$PIC_obs))
    } else if ("PIC" %in% names(df)) {
      df$PIC_obs <- suppressWarnings(as.numeric(df$PIC))
    } else {
      df$PIC_obs <- NA_real_
    }
    
    # spec / basis fields: use file inference only if missing in the CSV
    if (!("spec" %in% names(df))) df$spec <- inf$spec
    if (!("basis" %in% names(df))) df$basis <- inf$basis
    
    df$spec  <- as.character(df$spec)
    df$basis <- as.character(df$basis)
    
    # comparable_p handling (optional)
    if ("comparable_p" %in% names(df)) {
      df$comparable_p <- coerce_bool(df$comparable_p)
    } else {
      df$comparable_p <- NA
    }
    
    # expected categoricals
    if ("window" %in% names(df)) df$window <- as.character(df$window)
    if ("ecdet" %in% names(df))  df$ecdet  <- as.character(df$ecdet)
    
    missing_core <- setdiff(
      c("spec","basis","window","ecdet","p","r","status","PIC_obs"),
      names(df)
    )
    if (length(missing_core) > 0) {
      stop("File ", basename(path), " missing required columns: ", paste(missing_core, collapse = ", "))
    }
    
    df
  }
  
  build_interp_surface <- function(pts, x_col = "p", y_col = "r", z_col = "delta") {
    # AKIMA ONLY; no extrapolation; NA preserved
    if (nrow(pts) < 3) return(NULL)
    
    x <- pts[[x_col]]
    y <- pts[[y_col]]
    z <- pts[[z_col]]
    
    ok <- is.finite(x) & is.finite(y) & is.finite(z)
    pts2 <- pts[ok, , drop = FALSE]
    if (nrow(pts2) < 3) return(NULL)
    
    if (length(unique(pts2[[x_col]])) < 2 || length(unique(pts2[[y_col]])) < 2) return(NULL)
    
    out <- tryCatch(
      akima::interp(
        x = pts2[[x_col]],
        y = pts2[[y_col]],
        z = pts2[[z_col]],
        extrap = FALSE,
        duplicate = "mean"
      ),
      error = function(e) NULL
    )
    
    if (is.null(out) || is.null(out$z)) return(NULL)
    list(x = out$x, y = out$y, z = out$z)
  }
  
  build_slice_object <- function(df, spec, basis, ecdet, window, gridtype, surface_type = "main") {
    stopifnot(surface_type %in% c("main","diff_basis","diff_spec","gate_mask"))
    
    d0 <- df %>%
      dplyr::filter(.data$spec == spec, .data$basis == basis, .data$ecdet == ecdet, .data$window == window)
    
    if (gridtype == "unrestricted") {
      d1 <- d0 %>% dplyr::filter(.data$status == "computed")
    } else if (gridtype == "restricted") {
      d1 <- d0 %>% dplyr::filter(.data$status == "computed" & .data$comparable_p == TRUE)
    } else {
      stop("Unknown gridtype: ", gridtype)
    }
    
    pts <- d1 %>%
      dplyr::mutate(Z = -as.numeric(.data$PIC_obs)) %>%
      dplyr::filter(is.finite(.data$Z), is.finite(.data$p), is.finite(.data$r))
    
    if (nrow(pts) == 0) return(NULL)
    
    zmax <- max(pts$Z, na.rm = TRUE)
    pts <- pts %>% dplyr::mutate(delta = zmax - .data$Z)
    
    delta_min <- suppressWarnings(min(pts$delta, na.rm = TRUE))
    delta_max <- suppressWarnings(max(pts$delta, na.rm = TRUE))
    
    surf <- build_interp_surface(pts, z_col = "delta")
    if (is.null(surf)) return(NULL)
    
    key <- paste(spec, basis, ecdet, window, gridtype, surface_type, sep = "|")
    
    list(
      key = key,
      meta = list(
        spec = spec,
        basis = basis,
        ecdet = ecdet,
        window = window,
        gridtype = gridtype,
        surface_type = surface_type
      ),
      zmax = zmax,
      n_points = nrow(pts),
      delta_min = delta_min,
      delta_max = delta_max,
      surf = surf,
      pts = pts %>% dplyr::select(p, r, delta)
    )
  }
  
  build_diff_object <- function(slice_A, slice_B, surface_type) {
    stopifnot(surface_type %in% c("diff_basis","diff_spec"))
    if (is.null(slice_A) || is.null(slice_B)) return(NULL)
    
    dd <- dplyr::inner_join(
      slice_A$pts %>% dplyr::rename(delta_A = delta),
      slice_B$pts %>% dplyr::rename(delta_B = delta),
      by = c("p","r")
    )
    if (nrow(dd) < 3) return(NULL)
    
    dd <- dd %>% dplyr::mutate(diff = .data$delta_A - .data$delta_B)
    
    surf <- build_interp_surface(dd, z_col = "diff")
    if (is.null(surf)) return(NULL)
    
    metaA <- slice_A$meta
    key <- paste(metaA$spec, metaA$basis, metaA$ecdet, metaA$window, metaA$gridtype, surface_type, sep = "|")
    
    list(
      key = key,
      meta = list(
        spec = metaA$spec,
        basis = metaA$basis,
        ecdet = metaA$ecdet,
        window = metaA$window,
        gridtype = metaA$gridtype,
        surface_type = surface_type
      ),
      zmax = NA_real_,
      n_points = nrow(dd),
      diff_min = suppressWarnings(min(dd$diff, na.rm = TRUE)),
      diff_max = suppressWarnings(max(dd$diff, na.rm = TRUE)),
      surf = surf
    )
  }
  
  build_master_grid <- function(df_all) {
    has_comp <- "comparable_p" %in% names(df_all) && any(!is.na(df_all$comparable_p))
    has_any_restricted <- has_comp && any(df_all$status == "computed" & df_all$comparable_p == TRUE, na.rm = TRUE)
    
    if (!has_any_restricted) {
      cat("WARNING: comparable_p unavailable or never TRUE. Restricted gridtype will be disabled.\n\n")
    }
    
    gridtypes <- c("unrestricted")
    if (has_any_restricted) gridtypes <- c(gridtypes, "restricted")
    
    specs  <- sort(unique(df_all$spec))
    bases  <- sort(unique(df_all$basis))
    ecdets <- sort(unique(df_all$ecdet))
    wins   <- sort(unique(df_all$window))
    
    qa_counts <- df_all %>%
      dplyr::mutate(
        computed = (.data$status == "computed") & is.finite(.data$PIC_obs),
        restricted = computed & (.data$comparable_p == TRUE)
      ) %>%
      dplyr::group_by(.data$spec, .data$basis, .data$ecdet, .data$window) %>%
      dplyr::summarise(
        n_computed = sum(.data$computed, na.rm = TRUE),
        n_restricted = sum(.data$restricted, na.rm = TRUE),
        .groups = "drop"
      )
    
    cat("Availability table (counts by spec,basis,ecdet,window):\n")
    print(qa_counts)
    cat("\n")
    
    master <- list()
    main_slices <- list()
    
    for (sp in specs) for (ba in bases) for (ec in ecdets) for (w in wins) for (gt in gridtypes) {
      obj <- build_slice_object(df_all, sp, ba, ec, w, gt, surface_type = "main")
      if (!is.null(obj)) {
        main_slices[[obj$key]] <- obj
        master[[obj$key]] <- obj
        
        if (!is.na(obj$delta_max) && obj$delta_max == 0) {
          cat("WARNING: flat Δ surface (Δ_max==0) for slice: ", obj$key, "\n", sep = "")
        }
        
        cat("Slice built: ", obj$key, "\n", sep = "")
        cat("  n_points: ", obj$n_points, "\n", sep = "")
        cat("  Δ_min / Δ_max: ", signif(obj$delta_min, 6), " / ", signif(obj$delta_max, 6), "\n", sep = "")
        cat("  Z_max(S): ", signif(obj$zmax, 6), "\n\n", sep = "")
      }
    }
    
    # diff_basis: Δ(ortho) − Δ(raw)
    for (sp in specs) for (ec in ecdets) for (w in wins) for (gt in gridtypes) {
      key_ortho <- paste(sp, "ortho", ec, w, gt, "main", sep = "|")
      key_raw   <- paste(sp, "raw",   ec, w, gt, "main", sep = "|")
      
      if (key_ortho %in% names(main_slices) && key_raw %in% names(main_slices)) {
        diff_obj <- build_diff_object(main_slices[[key_ortho]], main_slices[[key_raw]], surface_type = "diff_basis")
        if (!is.null(diff_obj)) master[[diff_obj$key]] <- diff_obj
      }
    }
    
    # diff_spec: Δ(Q3) − Δ(Q2)
    for (ba in bases) for (ec in ecdets) for (w in wins) for (gt in gridtypes) {
      key_Q3 <- paste("Q3", ba, ec, w, gt, "main", sep = "|")
      key_Q2 <- paste("Q2", ba, ec, w, gt, "main", sep = "|")
      
      if (key_Q3 %in% names(main_slices) && key_Q2 %in% names(main_slices)) {
        diff_obj <- build_diff_object(main_slices[[key_Q3]], main_slices[[key_Q2]], surface_type = "diff_spec")
        if (!is.null(diff_obj)) master[[diff_obj$key]] <- diff_obj
      }
    }
    
    stopifnot(length(master) > 0)
    
    list(
      master_grid = master,
      has_restricted = has_any_restricted,
      qa_counts = qa_counts
    )
  }
  
  build_plotly_from_master_grid <- function(master_grid, default_key = NULL) {
    
    # Ensure master_grid is named by its keys
    if (is.null(names(master_grid)) || any(names(master_grid) == "")) {
      nm <- vapply(master_grid, function(o) o$key %||% NA_character_, character(1))
      stopifnot(all(!is.na(nm)))
      names(master_grid) <- nm
    }
    
    keys <- names(master_grid)
    stopifnot(length(keys) > 0)
    
    preferred <- "Q2|raw|const|fordism|unrestricted|main"
    if (is.null(default_key)) {
      if (preferred %in% keys) {
        default_key <- preferred
      } else {
        main_keys <- keys[grepl("\\|main$", keys)]
        default_key <- if (length(main_keys) > 0) main_keys[[1]] else keys[[1]]
      }
    }
    if (!(default_key %in% keys)) default_key <- keys[[1]]
    cat("DEFAULT KEY USED:", default_key, "\n")
    
    # Stable ordering: main first, then diffs
    surface_type <- vapply(strsplit(keys, "\\|"), function(v) v[[6]] %||% "?", character(1))
    ord <- order(
      ifelse(surface_type == "main", 1L,
             ifelse(surface_type == "diff_basis", 2L,
                    ifelse(surface_type == "diff_spec", 3L, 9L))),
      keys
    )
    keys_sorted <- keys[ord]
    stopifnot(length(keys_sorted) > 0)
    
    title_for_key <- function(k) {
      obj <- master_grid[[k]]
      m <- obj$meta
      if (m$surface_type == "main") {
        sprintf(
          "ΔPIC-to-best | %s | basis=%s | ecdet=%s | window=%s | %s | Z_max(S)=%.6g",
          m$spec, m$basis, m$ecdet, m$window, m$gridtype, obj$zmax
        )
      } else if (m$surface_type == "diff_basis") {
        sprintf(
          "Δ-diff (basis): Δ(ortho) − Δ(raw) | %s | ecdet=%s | window=%s | %s | diff_range=[%.6g, %.6g]",
          m$spec, m$ecdet, m$window, m$gridtype,
          obj$diff_min %||% NA_real_, obj$diff_max %||% NA_real_
        )
      } else if (m$surface_type == "diff_spec") {
        sprintf(
          "Δ-diff (spec): Δ(Q3) − Δ(Q2) | basis=%s | ecdet=%s | window=%s | %s | diff_range=[%.6g, %.6g]",
          m$basis, m$ecdet, m$window, m$gridtype,
          obj$diff_min %||% NA_real_, obj$diff_max %||% NA_real_
        )
      } else {
        sprintf("Surface | %s", k)
      }
    }
    
    p <- plotly::plot_ly()
    
    # Add traces, but HARD-SKIP any surface whose z is basically non-finite
    for (k in keys_sorted) {
      obj <- master_grid[[k]]
      if (is.null(obj$surf) || is.null(obj$surf$z)) {
        cat("SKIP (no surf):", k, "\n")
        next
      }
      
      zmat <- obj$surf$z
      n_finite <- sum(is.finite(zmat))
      
      # Conservative: require enough finite z to avoid Plotly axis scaling explosions
      if (n_finite < 10) {
        cat("SKIP (too few finite z):", k, "finite=", n_finite, "\n")
        next
      }
      
      # Extra strict for diff surfaces (often the ones that go sparse)
      if (!is.null(obj$meta$surface_type) && obj$meta$surface_type != "main" && n_finite < 50) {
        cat("SKIP (diff too sparse):", k, "finite=", n_finite, "\n")
        next
      }
      
      meta <- obj$meta
      trace_meta <- list(
        spec = meta$spec,
        basis = meta$basis,
        ecdet = meta$ecdet,
        window = meta$window,
        gridtype = meta$gridtype,
        surface_type = meta$surface_type,
        zmax = obj$zmax
      )
      
      p <- plotly::add_surface(
        p,
        x = obj$surf$x,
        y = obj$surf$y,
        z = obj$surf$z,
        name = k,
        visible  = identical(k, default_key),
        # CRITICAL: do NOT spawn 96 colorbars
        showscale = identical(k, default_key),
        meta = trace_meta
      )
    }
    
    # Materialize traces once (important for p$x$data)
    pb <- plotly::plotly_build(p)
    cat("DEBUG after plotly_build n_traces:", length(pb$x$data), "\n")
    stopifnot(length(pb$x$data) > 0)
    p <- pb
    
    # IMPORTANT: after skipping traces, dropdown must align to ACTUAL trace order
    trace_names <- vapply(p$x$data, function(d) d$name %||% NA_character_, character(1))
    stopifnot(all(!is.na(trace_names)))
    if (!(default_key %in% trace_names)) default_key <- trace_names[[1]]
    
    buttons <- lapply(seq_along(trace_names), function(i) {
      k <- trace_names[[i]]
      vis <- trace_names == k
      list(
        method = "update",
        args = list(
          list(
            visible = vis,
            # also toggle the colorbar so only one shows
            showscale = vis
          ),
          list(title = list(text = title_for_key(k)))
        ),
        label = k
      )
    })
    # ------------------------------------------------------------
    # PATCH: Menu 2 (Compare) — anchored to default_key
    # Place this AFTER you define `trace_names` and `title_for_key()`
    # and BEFORE you call plotly::layout(...).
    # ------------------------------------------------------------
    
    parse_key <- function(k) {
      parts <- strsplit(k, "\\|", fixed = FALSE)[[1]]
      stopifnot(length(parts) >= 6)
      list(
        spec = parts[[1]],
        basis = parts[[2]],
        ecdet = parts[[3]],
        window = parts[[4]],
        gridtype = parts[[5]],
        surface_type = parts[[6]]
      )
    }
    
    make_key <- function(spec, basis, ecdet, window, gridtype, surface_type) {
      paste(spec, basis, ecdet, window, gridtype, surface_type, sep = "|")
    }
    
    swap_spec <- function(x)  if (x == "Q2") "Q3" else if (x == "Q3") "Q2" else x
    swap_basis <- function(x) if (x == "raw") "ortho" else if (x == "ortho") "raw" else x
    swap_grid <- function(x)  if (x == "unrestricted") "restricted" else if (x == "restricted") "unrestricted" else x
    
    # Base (the anchor for compare buttons)
    base_key <- default_key
    base <- parse_key(base_key)
    
    # Candidate compare keys
    k_spec  <- make_key(swap_spec(base$spec), base$basis, base$ecdet, base$window, base$gridtype, base$surface_type)
    k_basis <- make_key(base$spec, swap_basis(base$basis), base$ecdet, base$window, base$gridtype, base$surface_type)
    k_grid  <- make_key(base$spec, base$basis, base$ecdet, base$window, swap_grid(base$gridtype), base$surface_type)
    k_sb    <- make_key(swap_spec(base$spec), swap_basis(base$basis), base$ecdet, base$window, base$gridtype, base$surface_type)
    
    # Only keep keys that actually exist as traces
    exists_trace <- function(k) k %in% trace_names
    pick_pair <- function(k2) {
      if (exists_trace(k2)) c(base_key, k2) else c(base_key)
    }
    
    vis_for <- function(keys_on) trace_names %in% keys_on
    
    # Menu 2 buttons (compare)
    menu2_buttons <- list(
      list(
        method = "update",
        args = list(
          list(visible = vis_for(c(base_key))),
          list(title = list(text = paste0("[BASE] ", title_for_key(base_key))))
        ),
        label = "Compare: base only"
      ),
      list(
        method = "update",
        args = list(
          list(visible = vis_for(pick_pair(k_spec))),
          list(title = list(text = paste0("[COMPARE spec] ", base_key, " + ", k_spec)))
        ),
        label = "Compare: Q2 ↔ Q3 (same basis/window/ecdet/grid)"
      ),
      list(
        method = "update",
        args = list(
          list(visible = vis_for(pick_pair(k_basis))),
          list(title = list(text = paste0("[COMPARE basis] ", base_key, " + ", k_basis)))
        ),
        label = "Compare: raw ↔ ortho (same spec/window/ecdet/grid)"
      ),
      list(
        method = "update",
        args = list(
          list(visible = vis_for(pick_pair(k_grid))),
          list(title = list(text = paste0("[COMPARE grid] ", base_key, " + ", k_grid)))
        ),
        label = "Compare: unrestricted ↔ restricted"
      ),
      list(
        method = "update",
        args = list(
          list(visible = vis_for(pick_pair(k_sb))),
          list(title = list(text = paste0("[COMPARE spec+basis] ", base_key, " + ", k_sb)))
        ),
        label = "Compare: (Q2↔Q3) + (raw↔ortho)"
      )
    )
    
    # Build menu objects (Menu 1 already exists in your code as `buttons`)
    menu_single <- list(
      type = "dropdown",
      direction = "down",
      x = 0.01, y = 0.99,
      xanchor = "left", yanchor = "top",
      showactive = TRUE,
      buttons = buttons
    )
    
    menu_compare <- list(
      type = "dropdown",
      direction = "down",
      x = 0.01, y = 0.92,   # slightly below Menu 1
      xanchor = "left", yanchor = "top",
      showactive = TRUE,
      buttons = menu2_buttons
    )
    
    
    p <- plotly::layout(
      p,
      title = list(text = title_for_key(default_key)),
      scene = list(
        xaxis = list(title = "p"),
        yaxis = list(title = "r"),
        zaxis = list(title = "ΔPIC-to-best (slice-normalized)")
      ),
      updatemenus = list(
        menu_single,
        menu_compare
      ),
      margin = list(l = 0, r = 0, b = 0, t = 120)
    )
    
    # QA: exactly one visible trace, and it has the only colorbar
    vis_count <- sum(vapply(p$x$data, function(d) isTRUE(d$visible), logical(1)))
    sc_count  <- sum(vapply(p$x$data, function(d) isTRUE(d$showscale), logical(1)))
    cat("n_traces:", length(p$x$data), "\n")
    cat("visible counts:", vis_count, "\n")
    cat("showscale counts:", sc_count, "\n")
    stopifnot(vis_count == 1)
    stopifnot(sc_count == 1)
    
    # Do NOT force axis ranges here (this is where Plotly likes to crash)
    # Let Plotly autoscale based on the visible trace.
    
    list(p = p, default_key = default_key, trace_names = trace_names)
  }
  
  export_html <- function(p, out_file) {
    cat("Export target:", out_file, "\n")
    
    ok_sc <- TRUE
    err_sc <- NULL
    
    tryCatch(
      { htmlwidgets::saveWidget(p, out_file, selfcontained = TRUE) },
      error = function(e) { ok_sc <<- FALSE; err_sc <<- e$message }
    )
    
    if (ok_sc) {
      cat("Export success: selfcontained=TRUE\n")
      return(invisible(TRUE))
    }
    
    cat("\nLOUD WARNING: selfcontained=TRUE failed.\n")
    cat("Reason:\n  ", err_sc, "\n", sep = "")
    cat("Falling back to selfcontained=FALSE. Keep the HTML file together with its *_files folder.\n\n")
    
    htmlwidgets::saveWidget(p, out_file, selfcontained = FALSE)
    cat("Export success: selfcontained=FALSE\n")
    invisible(FALSE)
  }
  
  # ============================================================
  # Main flow
  # ============================================================
  
  dfs <- lapply(present_files, read_one_grid)
  df_all <- dplyr::bind_rows(dfs)
  
  # canonical domains (no invention)
  df_all$window <- tolower(df_all$window)
  df_all$ecdet  <- tolower(df_all$ecdet)
  df_all$basis  <- tolower(df_all$basis)
  df_all$spec   <- toupper(df_all$spec)
  
  built <- build_master_grid(df_all)
  master_grid <- built$master_grid
  stopifnot(length(master_grid) > 0)
  
  default_pref <- "Q2|raw|const|fordism|unrestricted|main"
  default_key <- if (default_pref %in% names(master_grid)) default_pref else NULL
  
  pl <- build_plotly_from_master_grid(master_grid, default_key = default_key)
  p <- pl$p
  
  # Export (viewer-only)
  out_file <- file.path(DIRS$html, "PIC_surface_layer_controls.html")
  export_html(p, out_file)
  
  cat("\n=== 31_report.R complete ===\n")
  cat("HTML:", out_file, "\n")
