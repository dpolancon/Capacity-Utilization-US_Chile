# Shared envelope tools for Critical Replication planes.

extract_envelope <- function(df, x_col = "k_total", y_col = "logLik") {
  stopifnot(is.data.frame(df), is.character(x_col), is.character(y_col))
  stopifnot(length(x_col) == 1L, length(y_col) == 1L)
  stopifnot(x_col %in% names(df), y_col %in% names(df))

  df_env <- df |>
    dplyr::filter(is.finite(.data[[x_col]]), is.finite(.data[[y_col]])) |>
    dplyr::arrange(.data[[x_col]], dplyr::desc(.data[[y_col]])) |>
    dplyr::group_by(.data[[x_col]]) |>
    dplyr::slice(1L) |>
    dplyr::ungroup() |>
    dplyr::arrange(.data[[x_col]])

  if (nrow(df_env) == 0L) {
    return(df_env)
  }

  keep <- df_env[[y_col]] >= cummax(df_env[[y_col]])
  df_env[keep, , drop = FALSE] |>
    dplyr::arrange(.data[[x_col]])
}

canonicalize_envelope_schema <- function(df) {
  alias_map <- c(
    k = "k_total",
    ICOMP = "ICOMP_pen",
    RICOMP = "RICOMP_pen"
  )

  dup_idx <- anyDuplicated(names(df))
  if (dup_idx > 0L) {
    stop(sprintf("Envelope export aborted: duplicate column names detected (first duplicate: '%s').", names(df)[dup_idx]), call. = FALSE)
  }

  alias_pairs <- names(alias_map)[names(alias_map) %in% names(df) & alias_map %in% names(df)]
  if (length(alias_pairs) > 0L) {
    pair_msg <- paste(sprintf("%s/%s", alias_pairs, alias_map[alias_pairs]), collapse = ", ")
    stop(sprintf("Envelope export aborted: alias+canonical pairs coexist: %s.", pair_msg), call. = FALSE)
  }

  drop_cols <- unique(c(
    names(alias_map)[names(alias_map) %in% names(df)],
    names(df)[grepl("\\.[0-9]+$", names(df))]
  ))

  out <- if (length(drop_cols) > 0L) {
    df[, setdiff(names(df), drop_cols), drop = FALSE]
  } else {
    df
  }

  if (anyDuplicated(names(out)) > 0L) {
    stop("Envelope export aborted: duplicate names remain after schema canonicalization.", call. = FALSE)
  }

  out
}

write_envelope_plane <- function(df,
                                 x_col,
                                 y_col = "logLik",
                                 csv_path,
                                 fig_path,
                                 title = NULL,
                                 point_alpha = 0.4) {
  env <- extract_envelope(df, x_col = x_col, y_col = y_col)
  env <- canonicalize_envelope_schema(env)
  utils::write.csv(env, csv_path, row.names = FALSE)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[[x_col]], y = .data[[y_col]])) +
    ggplot2::geom_point(alpha = point_alpha) +
    ggplot2::geom_line(data = env, color = "red") +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = if (is.null(title)) paste0(y_col, " vs ", x_col) else title,
      x = x_col,
      y = y_col
    )

  ggplot2::ggsave(fig_path, p, width = 6, height = 4)
  invisible(env)
}
