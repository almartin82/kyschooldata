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
#' @param df Raw data frame from SRC (Kentucky-specific long format)
#' @param end_year School year end
#' @param level "primary" or "secondary"
#' @return Processed data frame in wide format
#' @keywords internal
process_src_enrollment_df <- function(df, end_year, level) {

  # Kentucky data is in long format with DEMOGRAPHIC column
  # Structure: one row per (entity, demographic) combination
  #
  # Two column naming conventions:
  # 2020-2023: DEMOGRAPHIC, DISTRICT NUMBER, SCHOOL NUMBER, TOTAL STUDENT COUNT,
  #            PRESCHOOL COUNT, KINDERGARTEN COUNT, GRADE1 COUNT, etc.
  # 2024+:    Demographic, District Number, School Number, All Grades,
  #            Preschool, K, Grade 1, Grade 2, etc.

  # Helper function to find column (case-insensitive)
  find_col <- function(df, patterns) {
    cols <- names(df)
    for (pattern in patterns) {
      matched <- grep(pattern, cols, ignore.case = TRUE)
      if (length(matched) > 0) return(cols[matched[1]])
    }
    NULL
  }

  # Find columns using both naming conventions
  demographic_col <- find_col(df, c("^DEMOGRAPHIC$", "^Demographic$"))
  district_num_col <- find_col(df, c("^DISTRICT NUMBER$", "^District Number$"))
  district_name_col <- find_col(df, c("^DISTRICT NAME$", "^District Name$"))
  school_num_col <- find_col(df, c("^SCHOOL NUMBER$", "^School Number$"))
  school_name_col <- find_col(df, c("^SCHOOL NAME$", "^School Name$"))

  # Grade level column maps (handle both naming conventions)
  total_col <- find_col(df, c("^TOTAL STUDENT COUNT$", "^All Grades$"))
  grade_pk_col <- find_col(df, c("^PRESCHOOL COUNT$", "^Preschool$"))
  grade_k_col <- find_col(df, c("^KINDERGARTEN COUNT$", "^K$"))
  grade_01_col <- find_col(df, c("^GRADE1 COUNT$", "^GRADE 1$", "^Grade 1$"))
  grade_02_col <- find_col(df, c("^GRADE2 COUNT$", "^GRADE 2$", "^Grade 2$"))
  grade_03_col <- find_col(df, c("^GRADE3 COUNT$", "^GRADE 3$", "^Grade 3$"))
  grade_04_col <- find_col(df, c("^GRADE4 COUNT$", "^GRADE 4$", "^Grade 4$"))
  grade_05_col <- find_col(df, c("^GRADE5 COUNT$", "^GRADE 5$", "^Grade 5$"))
  grade_06_col <- find_col(df, c("^GRADE6 COUNT$", "^GRADE 6$", "^Grade 6$"))
  grade_07_col <- find_col(df, c("^GRADE7 COUNT$", "^GRADE 7$", "^Grade 7$"))
  grade_08_col <- find_col(df, c("^GRADE8 COUNT$", "^GRADE 8$", "^Grade 8$"))
  grade_09_col <- find_col(df, c("^GRADE9 COUNT$", "^GRADE 9$", "^Grade 9$"))
  grade_10_col <- find_col(df, c("^GRADE10 COUNT$", "^GRADE 10$", "^Grade 10$"))
  grade_11_col <- find_col(df, c("^GRADE11 COUNT$", "^GRADE 11$", "^Grade 11$"))
  grade_12_col <- find_col(df, c("^GRADE12 COUNT$", "^GRADE 12$", "^Grade 12$"))

  # Demographic name mapping (KY names -> our standard names)
  demographic_map <- c(
    "All Students" = "total_enrollment",
    "Female" = "female",
    "Male" = "male",
    "African American" = "black",
    "American Indian or Alaska Native" = "native_american",
    "Asian" = "asian",
    "Hispanic or Latino" = "hispanic",
    "Native Hawaiian or Pacific Islander" = "pacific_islander",
    "Two or More Races" = "multiracial",
    "White (non-Hispanic)" = "white",
    "Economically Disadvantaged" = "econ_disadv",
    "Students with Disabilities (IEP)" = "special_ed",
    "English Learner" = "lep"
    # Note: Other demographics (Foster Care, Gifted, Homeless, Migrant, Military) are excluded
    # as they don't fit our standard schema
  )

  # Filter to only demographics we care about
  df <- df[df[[demographic_col]] %in% names(demographic_map), ]

  # Identify district vs school rows
  # District rows have SCHOOL NAME = "---District Total---" or SCHOOL NUMBER = NA
  # For 2024+, State rows have District Number = "999" and School Name = "All Schools"
  df$is_district_row <- is.na(df[[school_num_col]]) |
    df[[school_name_col]] == "---District Total---" |
    (df[[school_name_col]] == "All Schools" & df[[district_num_col]] == "999")

  # For each entity (district or school), create a wide-format row
  entities <- unique(df[, c(district_num_col, district_name_col, school_num_col, school_name_col, "is_district_row")])

  result_list <- lapply(seq_len(nrow(entities)), function(i) {
    entity <- entities[i, ]

    # Get all demographics for this entity
    entity_data <- df[
      df[[district_num_col]] == entity[[district_num_col]] &
      df[[school_name_col]] == entity[[school_name_col]],
    ]

    # Initialize row
    row <- list(
      end_year = end_year,
      district_id = as.character(entity[[district_num_col]]),
      district_name = entity[[district_name_col]]
    )

    # Determine type and set school fields
    if (entity$is_district_row) {
      row$type <- "District"
      row$school_id <- NA_character_
      row$school_name <- NA_character_
    } else {
      row$type <- "School"
      row$school_id <- as.character(entity[[school_num_col]])
      row$school_name <- entity[[school_name_col]]
    }

    # Get "All Students" row for total and grade levels
    all_students <- entity_data[entity_data[[demographic_col]] == "All Students", ]

    if (nrow(all_students) > 0) {
      as_row <- all_students[1, ]  # Take first row
      row$row_total <- safe_numeric(as_row[[total_col]])
      row$grade_pk <- safe_numeric(as_row[[grade_pk_col]])
      row$grade_k <- safe_numeric(as_row[[grade_k_col]])
      row$grade_01 <- safe_numeric(as_row[[grade_01_col]])
      row$grade_02 <- safe_numeric(as_row[[grade_02_col]])
      row$grade_03 <- safe_numeric(as_row[[grade_03_col]])
      row$grade_04 <- safe_numeric(as_row[[grade_04_col]])
      row$grade_05 <- safe_numeric(as_row[[grade_05_col]])
      row$grade_06 <- safe_numeric(as_row[[grade_06_col]])
      row$grade_07 <- safe_numeric(as_row[[grade_07_col]])
      row$grade_08 <- safe_numeric(as_row[[grade_08_col]])
      row$grade_09 <- safe_numeric(as_row[[grade_09_col]])
      row$grade_10 <- safe_numeric(as_row[[grade_10_col]])
      row$grade_11 <- safe_numeric(as_row[[grade_11_col]])
      row$grade_12 <- safe_numeric(as_row[[grade_12_col]])
    } else {
      row$row_total <- NA_integer_
      row$grade_pk <- NA_integer_
      row$grade_k <- NA_integer_
      row$grade_01 <- NA_integer_
      row$grade_02 <- NA_integer_
      row$grade_03 <- NA_integer_
      row$grade_04 <- NA_integer_
      row$grade_05 <- NA_integer_
      row$grade_06 <- NA_integer_
      row$grade_07 <- NA_integer_
      row$grade_08 <- NA_integer_
      row$grade_09 <- NA_integer_
      row$grade_10 <- NA_integer_
      row$grade_11 <- NA_integer_
      row$grade_12 <- NA_integer_
    }

    # Add demographic columns from their respective rows
    for (j in seq_len(nrow(entity_data))) {
      demo_row <- entity_data[j, ]
      ky_name <- demo_row[[demographic_col]]
      std_name <- demographic_map[ky_name]

      # Skip total_enrollment (already handled) and grade levels (not in demographic rows)
      if (!is.na(std_name) && std_name != "total_enrollment") {
        # Demographic counts come from total column
        row[[std_name]] <- safe_numeric(demo_row[[total_col]])
      }
    }

    # Ensure all expected columns exist (fill with NA if missing)
    expected_demos <- c("white", "black", "hispanic", "asian", "native_american",
                       "pacific_islander", "multiracial", "male", "female",
                       "econ_disadv", "lep", "special_ed")
    for (col in expected_demos) {
      if (!(col %in% names(row))) {
        row[[col]] <- NA_integer_
      }
    }

    as.data.frame(row, stringsAsFactors = FALSE)
  })

  # Combine all rows
  result <- dplyr::bind_rows(result_list)

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
