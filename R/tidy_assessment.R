# ==============================================================================
# Assessment Data Tidying Functions
# ==============================================================================
#
# This file contains functions for converting wide-format assessment data
# into tidy long format.
#
# ==============================================================================

#' Tidy assessment data
#'
#' Converts wide-format assessment data into tidy long format with
# consistent schema across years.
#'
#' @param df Processed assessment data frame in wide format
#' @return Data frame in tidy long format
#' @keywords internal
tidy_assessment <- function(df) {

  # Assessment data is already in a relatively tidy format
  # Each row represents one (entity, subject, grade, subgroup) combination

  # Clean up and standardize the format
  result <- df |>
    # Ensure consistent data types
    dplyr::mutate(
      end_year = as.integer(end_year),
      district_id = as.character(district_id),
      school_id = as.character(school_id),
      subject = as.character(subject),
      grade_level = as.character(grade_level),
      subgroup = as.character(subgroup),
      n_tested = as.numeric(n_tested),
      n_proficient = as.numeric(n_proficient),
      pct_proficient = as.numeric(pct_proficient)
    ) |>
    # Remove rows with invalid percentages (outside 0-1 range)
    dplyr::filter(
      is.na(pct_proficient) |
      (pct_proficient >= 0 & pct_proficient <= 1)
    ) |>
    # Replace Inf with NA
    dplyr::mutate(
      pct_proficient = dplyr::na_if(pct_proficient, Inf),
      pct_proficient = dplyr::na_if(pct_proficient, -Inf)
    ) |>
    # Ensure non-negative counts
    dplyr::mutate(
      n_tested = dplyr::na_if(n_tested, -Inf),
      n_tested = ifelse(!is.na(n_tested) & n_tested < 0, NA, n_tested),
      n_proficient = dplyr::na_if(n_proficient, -Inf),
      n_proficient = ifelse(!is.na(n_proficient) & n_proficient < 0, NA, n_proficient)
    ) |>
    # Remove rows where n_proficient > n_tested (data quality issue)
    dplyr::filter(
      is.na(n_tested) |
      is.na(n_proficient) |
      (n_proficient <= n_tested)
    ) |>
    # Sort
    dplyr::arrange(end_year, district_id, school_id, subject, grade_level, subgroup)

  result
}


#' Create district and school aggregates for tidy assessment data
#'
#' Aggregates school-level data to district level.
#'
#' @param df Tidy assessment data frame
#' @return Data frame with added district aggregates
#' @keywords internal
id_assessment_aggs <- function(df) {

  # District aggregates are typically already in the data
  # This function ensures they exist and are consistent

  # Filter out existing district/state rows
  school_data <- df[!df$is_state & !is.na(df$school_id) & df$school_id != "", ]

  if (nrow(school_data) == 0) {
    # No school data to aggregate, return as-is
    return(df)
  }

  # Create district aggregates from school data
  district_aggs <- school_data |>
    dplyr::group_by(end_year, district_id, district_name, subject, grade_level, subgroup) |>
    dplyr::summarise(
      school_id = district_id,
      school_name = district_name,
      n_tested = sum(n_tested, na.rm = TRUE),
      n_proficient = sum(n_proficient, na.rm = TRUE),
      pct_proficient = n_proficient / n_tested,
      is_state = FALSE,
      is_district = TRUE,
      .groups = "drop"
    )

  # Remove rows where aggregate would be invalid
  district_aggs <- district_aggs[!is.infinite(district_aggs$pct_proficient), ]

  # Combine with original data
  # Keep original district/state rows and add computed ones
  original_districts <- df[df$is_district | df$is_state, ]

  # Remove duplicate district rows that might exist
  combined <- dplyr::bind_rows(original_districts, district_aggs) |>
    dplyr::distinct()

  combined
}


#' Tidy assessment data (user-facing wrapper)
#'
#' Converts wide-format assessment data into tidy long format.
#' This is the user-facing wrapper for tidyaasessment().
#'
#' @param df Processed assessment data frame in wide format
#' @return Data frame in tidy long format
#' @export
#' @examples
#' \dontrun{
#' # Fetch wide format assessment data
#' aca_wide <- fetch_aca(2024, tidy = FALSE)
#'
#' # Convert to tidy format
#' aca_tidy <- tidy_aca(aca_wide)
#' }
tidy_aca <- function(df) {
  tidy_assessment(df) |> id_assessment_aggs()
}
