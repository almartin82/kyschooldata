# ==============================================================================
# Assessment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw KDE assessment data into a
# clean, standardized format.
#
# ==============================================================================

#' Process raw KDE assessment data
#'
#' Transforms raw assessment data into a standardized schema.
#'
#' @param raw_data List containing data frames from get_raw_assessment
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_assessment <- function(raw_data, end_year) {

  era <- raw_data$era

  if (era %in% c("assessment_current", "assessment_historical")) {
    result <- process_assessment_df(raw_data$assessment, end_year)
  } else {
    stop(paste("Unknown data era:", era))
  }

  # Ensure consistent column order
  result <- standardize_assessment_columns(result)

  result
}


#' Process a single SRC assessment data frame
#'
#' @param df Raw data frame from SRC assessment data
#' @param end_year School year end
#' @return Processed data frame in wide format
#' @keywords internal
process_assessment_df <- function(df, end_year) {

  # Helper function to find column (case-insensitive)
  find_col <- function(pattern, df) {
    cols <- names(df)
    matches <- cols[tolower(cols) == tolower(pattern) |
                     grepl(pattern, cols, ignore.case = TRUE)]
    if (length(matches) > 0) {
      return(matches[1])
    }
    return(NULL)
  }

  # Map common column name variations to standard names
  district_col <- find_col("district", df)
  school_col <- find_col("school", df)

  # Try to find district/school ID columns vs name columns
  district_id_col <- find_col("district number|district_number|district id|district_id", df)
  school_id_col <- find_col("school number|school_number|school id|school_id", df)

  # Use ID columns if available, otherwise fall back to name columns
  if (is.null(district_id_col)) {
    district_id_col <- district_col
  }
  if (is.null(school_id_col)) {
    school_id_col <- school_col
  }

  # Find subject and grade columns
  subject_col <- find_col("subject|test", df)
  grade_col <- find_col("grade", df)

  # Find student group/demographic column
  subgroup_col <- find_col("group|demographic|subgroup", df)

  # Find score columns
  n_tested_col <- find_col("tested|number tested|n_tested", df)
  n_proficient_col <- find_col("proficient|n_proficient|number proficient", df)
  pct_proficient_col <- find_col("pct proficient|percent proficient|proficiency rate", df)

  # Build base data frame with required columns
  result <- data.frame(
    end_year = end_year,
    district_id = df[[district_id_col]],
    school_id = df[[school_id_col]]
  )

  # Add name columns if available
  if (!is.null(district_col) && district_col != district_id_col) {
    result$district_name <- df[[district_col]]
  } else {
    result$district_name <- df[[district_id_col]]
  }

  if (!is.null(school_col) && school_col != school_id_col) {
    result$school_name <- df[[school_col]]
  } else {
    result$school_name <- df[[school_id_col]]
  }

  # Add assessment columns
  if (!is.null(subject_col)) {
    result$subject <- df[[subject_col]]
  } else {
    result$subject <- "All Subjects"
  }

  if (!is.null(grade_col)) {
    result$grade_level <- df[[grade_col]]
  } else {
    result$grade_level <- "ALL"
  }

  if (!is.null(subgroup_col)) {
    result$subgroup <- df[[subgroup_col]]
  } else {
    result$subgroup <- "All Students"
  }

  # Add score columns
  if (!is.null(n_tested_col)) {
    result$n_tested <- as.numeric(df[[n_tested_col]])
  } else {
    result$n_tested <- NA_real_
  }

  if (!is.null(n_proficient_col)) {
    result$n_proficient <- as.numeric(df[[n_proficient_col]])
  } else {
    result$n_proficient <- NA_real_
  }

  if (!is.null(pct_proficient_col)) {
    # Remove % sign if present and convert to numeric
    pct_vals <- df[[pct_proficient_col]]
    pct_vals <- gsub("%", "", as.character(pct_vals))
    result$pct_proficient <- as.numeric(pct_vals) / 100
  } else {
    # Calculate from n_proficient and n_tested if available
    if (!is.null(n_proficient_col) && !is.null(n_tested_col)) {
      result$pct_proficient <- result$n_proficient / result$n_tested
    } else {
      result$pct_proficient <- NA_real_
    }
  }

  # Create is_state and is_district flags
  result$is_state <- result$district_id == "STATE" |
                     is.na(result$district_id) |
                     result$district_id == ""
  result$is_district <- !result$is_state

  # Clean up - remove rows with missing essential data
  result <- result[!is.na(result$district_id) | result$is_state, ]

  # Create state aggregate
  state_agg <- create_assessment_state_aggregate(result, end_year)

  # Combine state and district/school data
  dplyr::bind_rows(state_agg, result)
}


#' Create state-level aggregate for assessment data
#'
#' @param df Processed assessment data frame
#' @param end_year School year end
#' @return Data frame with state aggregates
#' @keywords internal
create_assessment_state_aggregate <- function(df, end_year) {

  # Filter out existing state rows if any
  df_filtered <- df[!df$is_state, ]

  # Group by subject, grade, subgroup and calculate aggregates
  state_agg <- df_filtered |>
    dplyr::group_by(subject, grade_level, subgroup) |>
    dplyr::summarise(
      end_year = end_year,
      district_id = "STATE",
      school_id = "STATE",
      district_name = "Kentucky",
      school_name = "Kentucky",
      n_tested = sum(n_tested, na.rm = TRUE),
      n_proficient = sum(n_proficient, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      pct_proficient = n_proficient / n_tested,
      is_state = TRUE,
      is_district = FALSE
    )

  # Reorder columns to match main data frame
  state_agg <- state_agg[, names(df)]

  state_agg
}


#' Standardize assessment data column names and order
#'
#' @param df Data frame to standardize
#' @return Data frame with standardized columns
#' @keywords internal
standardize_assessment_columns <- function(df) {

  # Define required columns and their order
  required_cols <- c(
    "end_year",
    "district_id",
    "school_id",
    "district_name",
    "school_name",
    "subject",
    "grade_level",
    "subgroup",
    "n_tested",
    "n_proficient",
    "pct_proficient",
    "is_state",
    "is_district"
  )

  # Ensure all required columns exist
  for (col in required_cols) {
    if (!(col %in% names(df))) {
      df[[col]] <- NA
    }
  }

  # Reorder columns
  df[, required_cols]
}
