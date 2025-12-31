# ==============================================================================
# Utility Functions
# ==============================================================================

#' Pipe operator
#'
#' See \code{dplyr::\link[dplyr:reexports]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL


#' Convert to numeric, handling suppression markers
#'
#' KDE uses various markers for suppressed data (*, <, -, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "---", "n<10")] <- NA_character_

  # Also handle patterns like "< 10" or "<10"
 x[grepl("^<\\s*\\d+$", x)] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Standardize district ID to 3 digits
#'
#' Kentucky district IDs are 3 digits (001-999).
#'
#' @param x District ID vector
#' @return Character vector with zero-padded 3-digit IDs
#' @keywords internal
standardize_district_id <- function(x) {
  x <- trimws(as.character(x))
  # Remove any leading zeros and re-pad
  x <- as.integer(x)
  sprintf("%03d", x)
}


#' Standardize school ID to 6 digits
#'
#' Kentucky school IDs are typically 3-digit district + 3-digit school.
#'
#' @param x School ID vector
#' @return Character vector with zero-padded 6-digit IDs
#' @keywords internal
standardize_school_id <- function(x) {
  x <- trimws(as.character(x))
  # Handle various formats
  x <- gsub("[^0-9]", "", x)  # Remove non-numeric
  # Pad to 6 digits if needed
  ifelse(nchar(x) <= 6, sprintf("%06d", as.integer(x)), x)
}


#' Get school year end from SAAR year format
#'
#' SAAR uses format like "1999" to mean 1998-99 school year (end_year = 1999).
#'
#' @param saar_year SAAR year value
#' @return School year end (integer)
#' @keywords internal
saar_year_to_end_year <- function(saar_year) {
  as.integer(saar_year)
}


#' Get available years for enrollment data
#'
#' Returns the range of years for which enrollment data is available.
#'
#' @return Character vector describing available year ranges
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  message("Kentucky enrollment data availability:")
  message("")
  message("Era 1: SAAR Data (1997-2019)")
  message("  - Source: SAAR Ethnic Membership Reports")
  message("  - Aggregation: District-level only")
  message("  - Demographics: Race/ethnicity")
  message("  - File: 1996-2019 SAAR Summary ReportsADA.xlsx")
  message("")
  message("Era 2: SRC Historical Datasets (2012-2019)")
  message("  - Source: School Report Card Historical Datasets")
  message("  - Aggregation: School and District level")
  message("  - Demographics: Race/ethnicity, gender, special populations")
  message("")
  message("Era 3: SRC Current Format (2020-2024)")
  message("  - Source: Open House SRC Datasets")
  message("  - Aggregation: School and District level")
  message("  - Demographics: Race/ethnicity, gender, special populations, grade levels")
  message("  - 2020-2023: primary_enrollment_YYYY.csv, secondary_enrollment_YYYY.csv")
  message("  - 2024: KYRC24_OVW_Student_Enrollment.csv")
  message("")
  message("Note: 2025 data not yet available from KDE as of Dec 2025.")
  message("Note: Pre-1997 data not available from KDE.")
  message("")
  message("Use fetch_enr(year) where year is 1997-2024")

  invisible(list(
    saar = 1997:2019,
    src_historical = 2012:2019,
    src_current = 2020:2024
  ))
}
