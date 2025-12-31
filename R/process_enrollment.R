# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw KDE enrollment data into a
# clean, standardized format.
#
# ==============================================================================

#' Process raw KDE enrollment data
#'
#' Transforms raw data into a standardized schema.
#'
#' @param raw_data List containing data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  era <- raw_data$era

  if (era == "src_current") {
    result <- process_src_current(raw_data, end_year)
  } else if (era == "src_historical") {
    result <- process_src_historical(raw_data, end_year)
  } else if (era == "saar") {
    result <- process_saar(raw_data, end_year)
  } else {
    stop(paste("Unknown data era:", era))
  }

  # Ensure consistent column order
  result <- standardize_columns(result)

  result
}


#' Process SRC Current Format data (2020+)
#'
#' @param raw_data List with primary and secondary data frames (or combined)
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_src_current <- function(raw_data, end_year) {

  results <- list()

  # Process combined enrollment if available (2024+ format)
  if (!is.null(raw_data$combined) && nrow(raw_data$combined) > 0) {
    combined_processed <- process_src_enrollment_df(raw_data$combined, end_year, "combined")
    results$combined <- combined_processed
  }

  # Process primary enrollment if available
  if (!is.null(raw_data$primary) && nrow(raw_data$primary) > 0) {
    primary <- process_src_enrollment_df(raw_data$primary, end_year, "primary")
    results$primary <- primary
  }

  # Process secondary enrollment if available
  if (!is.null(raw_data$secondary) && nrow(raw_data$secondary) > 0) {
    secondary <- process_src_enrollment_df(raw_data$secondary, end_year, "secondary")
    results$secondary <- secondary
  }

  # Combine
  if (length(results) == 0) {
    stop("No enrollment data found")
  }

  combined <- dplyr::bind_rows(results)

  # Create state aggregate
  state_agg <- create_state_aggregate(combined, end_year)

  # Combine all
  dplyr::bind_rows(state_agg, combined)
}


#' Process a single SRC enrollment data frame
#'
#' @param df Raw data frame from SRC
#' @param end_year School year end
#' @param level "primary" or "secondary"
#' @return Processed data frame
#' @keywords internal
process_src_enrollment_df <- function(df, end_year, level) {

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by patterns (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Determine if this is school or district level data
  school_col <- find_col(c("^SCH_CD$", "^SCHOOL_CD$", "^SCHOOL$", "SCH_CODE", "SCHOOL_CODE"))
  district_col <- find_col(c("^DIST_NUMBER$", "^DIST_CD$", "^DISTRICT$", "^DIST$", "DIST_CODE", "DISTRICT_CODE"))

  has_school <- !is.null(school_col) && any(!is.na(df[[school_col]]) & df[[school_col]] != "")

  # Initialize result
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    stringsAsFactors = FALSE
  )

  # Determine type
  if (has_school) {
    result$type <- "School"
    result$school_id <- standardize_school_id(df[[school_col]])
  } else {
    result$type <- "District"
    result$school_id <- rep(NA_character_, n_rows)
  }

  # District ID
  if (!is.null(district_col)) {
    result$district_id <- standardize_district_id(df[[district_col]])
  } else if (has_school) {
    # Extract district from school ID (first 3 digits)
    result$district_id <- substr(result$school_id, 1, 3)
  }

  # Names
  school_name_col <- find_col(c("^SCH_NAME$", "^SCHOOL_NAME$", "SCHOOL_NM"))
  if (!is.null(school_name_col)) {
    result$school_name <- trimws(df[[school_name_col]])
  } else {
    result$school_name <- rep(NA_character_, n_rows)
  }

  district_name_col <- find_col(c("^DIST_NAME$", "^DISTRICT_NAME$", "DISTRICT_NM"))
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(df[[district_name_col]])
  } else {
    result$district_name <- rep(NA_character_, n_rows)
  }

  # Total enrollment
  total_col <- find_col(c("^MEMBERSHIP$", "^TOTAL$", "^ENROLLMENT$", "TOTAL_ENROLLMENT", "TOTAL_MEMBERSHIP"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Demographics - Race/Ethnicity
  demo_map <- list(
    white = c("WHITE", "MEMBERSHIP_WHITE", "CNT_WHITE"),
    black = c("BLACK", "AFRICAN_AMERICAN", "MEMBERSHIP_BLACK", "CNT_BLACK"),
    hispanic = c("HISPANIC", "MEMBERSHIP_HISPANIC", "CNT_HISPANIC"),
    asian = c("ASIAN", "MEMBERSHIP_ASIAN", "CNT_ASIAN"),
    pacific_islander = c("PACIFIC", "NATIVE_HAWAIIAN", "MEMBERSHIP_PACIFIC", "CNT_PACIFIC"),
    native_american = c("AMERICAN_INDIAN", "NATIVE_AMERICAN", "MEMBERSHIP_AMERICAN_INDIAN", "CNT_AMERICAN_INDIAN"),
    multiracial = c("TWO_OR_MORE", "MULTIRACIAL", "MULTI", "MEMBERSHIP_TWO", "CNT_TWO")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Gender
  male_col <- find_col(c("^MALE$", "MEMBERSHIP_MALE", "CNT_MALE"))
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  }

  female_col <- find_col(c("^FEMALE$", "MEMBERSHIP_FEMALE", "CNT_FEMALE"))
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  }

  # Special populations
  special_map <- list(
    econ_disadv = c("ECON", "ECONOMICALLY", "FREE_REDUCED", "FRL"),
    lep = c("LEP", "ELL", "ENGLISH_LEARNER", "LIMITED_ENGLISH"),
    special_ed = c("SPED", "SPECIAL_ED", "IEP", "DISABILITY")
  )

  for (name in names(special_map)) {
    col <- find_col(special_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # Grade levels
  grade_map <- list(
    grade_pk = c("^PK$", "^PRE_?K", "PRESCHOOL", "GRADE_PK"),
    grade_k = c("^K$", "^KG$", "KINDERGARTEN", "GRADE_K"),
    grade_01 = c("^G01$", "^GRADE_?1$", "^G1$", "GRADE_01"),
    grade_02 = c("^G02$", "^GRADE_?2$", "^G2$", "GRADE_02"),
    grade_03 = c("^G03$", "^GRADE_?3$", "^G3$", "GRADE_03"),
    grade_04 = c("^G04$", "^GRADE_?4$", "^G4$", "GRADE_04"),
    grade_05 = c("^G05$", "^GRADE_?5$", "^G5$", "GRADE_05"),
    grade_06 = c("^G06$", "^GRADE_?6$", "^G6$", "GRADE_06"),
    grade_07 = c("^G07$", "^GRADE_?7$", "^G7$", "GRADE_07"),
    grade_08 = c("^G08$", "^GRADE_?8$", "^G8$", "GRADE_08"),
    grade_09 = c("^G09$", "^GRADE_?9$", "^G9$", "GRADE_09"),
    grade_10 = c("^G10$", "^GRADE_?10$", "GRADE_10"),
    grade_11 = c("^G11$", "^GRADE_?11$", "GRADE_11"),
    grade_12 = c("^G12$", "^GRADE_?12$", "GRADE_12")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Process SRC Historical data (2012-2019)
#'
#' @param raw_data List with enrollment data frames
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_src_historical <- function(raw_data, end_year) {

  results <- list()

  # Process primary if available
  if (!is.null(raw_data$primary) && nrow(raw_data$primary) > 0) {
    results$primary <- process_src_enrollment_df(raw_data$primary, end_year, "primary")
  }

  # Process secondary if available
  if (!is.null(raw_data$secondary) && nrow(raw_data$secondary) > 0) {
    results$secondary <- process_src_enrollment_df(raw_data$secondary, end_year, "secondary")
  }

  # Process combined if available
  if (!is.null(raw_data$combined) && nrow(raw_data$combined) > 0) {
    results$combined <- process_src_enrollment_df(raw_data$combined, end_year, "combined")
  }

  # If we fell back to SAAR, process that
  if (!is.null(raw_data$district) && raw_data$era == "saar") {
    return(process_saar(raw_data, end_year))
  }

  if (length(results) == 0) {
    stop("No enrollment data found for year ", end_year)
  }

  combined <- dplyr::bind_rows(results)

  # Create state aggregate
  state_agg <- create_state_aggregate(combined, end_year)

  dplyr::bind_rows(state_agg, combined)
}


#' Process SAAR data (1997-2019)
#'
#' @param raw_data List with district data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_saar <- function(raw_data, end_year) {

  df <- raw_data$district
  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by patterns
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Initialize result - SAAR is district-level only
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    stringsAsFactors = FALSE
  )

  # School ID is NA for district data
  result$school_id <- rep(NA_character_, n_rows)

  # District ID
  dist_col <- find_col(c("^DIST", "^DISTRICT", "^CD$", "^CODE$"))
  if (!is.null(dist_col)) {
    result$district_id <- standardize_district_id(df[[dist_col]])
  }

  # District Name
  name_col <- find_col(c("^NAME$", "DISTRICT_NAME", "DIST_NAME"))
  if (!is.null(name_col)) {
    result$district_name <- trimws(df[[name_col]])
  }

  # School name is NA for districts
  result$school_name <- rep(NA_character_, n_rows)

  # SAAR columns are typically: TOTAL, WHITE, BLACK, HISPANIC, ASIAN, AMERICAN_INDIAN, etc.
  # Also may have abbreviated names

  # Total
  total_col <- find_col(c("^TOTAL$", "^MEMBERSHIP$", "^ENROLL"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  }

  # Race/Ethnicity - SAAR uses standard names
  demo_map <- list(
    white = c("^WHITE$", "^WHT$"),
    black = c("^BLACK$", "^BLK$", "^AFRICAN"),
    hispanic = c("^HISPANIC$", "^HISP$"),
    asian = c("^ASIAN$"),
    pacific_islander = c("^PACIFIC$", "^NATIVE_HAW"),
    native_american = c("^AMERICAN_INDIAN$", "^AM_IND$", "^NATIVE_AM"),
    multiracial = c("^TWO$", "^MULTI$", "^TWO_OR_MORE$")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    }
  }

  # SAAR typically doesn't have gender, special populations, or grade levels
  # Those will be NA

  # Create state aggregate
  state_agg <- create_state_aggregate(result, end_year)

  dplyr::bind_rows(state_agg, result)
}


#' Create state-level aggregate from district/school data
#'
#' @param df Processed data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(df, end_year) {

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "econ_disadv", "lep", "special_ed",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(df)]

  # Use only district-level data for state totals (avoid double-counting schools)
  if ("type" %in% names(df) && any(df$type == "District")) {
    df_for_sum <- df[df$type == "District", ]
  } else {
    df_for_sum <- df
  }

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    school_id = NA_character_,
    district_name = NA_character_,
    school_name = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    if (col %in% names(df_for_sum)) {
      state_row[[col]] <- sum(df_for_sum[[col]], na.rm = TRUE)
    }
  }

  state_row
}


#' Standardize column order and ensure all expected columns exist
#'
#' @param df Data frame to standardize
#' @return Data frame with consistent columns
#' @keywords internal
standardize_columns <- function(df) {

  # Define expected columns in order
  expected_cols <- c(
    "end_year", "type",
    "district_id", "school_id",
    "district_name", "school_name",
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "econ_disadv", "lep", "special_ed",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Add missing columns as NA
  for (col in expected_cols) {
    if (!(col %in% names(df))) {
      if (col %in% c("end_year")) {
        df[[col]] <- NA_integer_
      } else if (col %in% c("type", "district_id", "school_id", "district_name", "school_name")) {
        df[[col]] <- NA_character_
      } else {
        df[[col]] <- NA_integer_
      }
    }
  }

  # Select and order columns
  result <- df[, expected_cols, drop = FALSE]

  result
}
