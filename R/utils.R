# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
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
  list(
    min_year = 1997,
    max_year = 2024,
    description = "Kentucky enrollment data from KDE (1997-2024)"
  )
}
