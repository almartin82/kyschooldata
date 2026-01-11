# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading assessment data from the
# Kentucky Department of Education (KDE) website.
#
# ==============================================================================

#' Fetch Kentucky assessment data
#'
#' Downloads and processes assessment data from the Kentucky Department of
#' Education via the School Report Card (SRC) datasets.
#'
#' @param end_year A school year. Year is the end of the academic year - eg 2023-24
#'   school year is year '2024'. Valid values are 2012-2025 (excluding 2020
#'   which was waived due to COVID-19):
#'   - 2012-2020: SRC Historical datasets
#'   - 2021-2025: SRC Current format datasets
#'   Note: 2025 data may not be available yet depending on release date.
#' @param tidy If TRUE (default), returns data in long (tidy) format with
#'   consistent column structure. If FALSE, returns wide format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from KDE.
#' @return Data frame with assessment data. Includes columns for
#'   district_id, school_id, names, subject, grade_level, subgroup, and
#'   assessment scores (n_tested, n_proficient, pct_proficient).
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 assessment data (2023-24 school year)
#' aca_2024 <- fetch_aca(2024)
#'
#' # Get wide format
#' aca_wide <- fetch_aca(2024, tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' aca_fresh <- fetch_aca(2024, use_cache = FALSE)
#'
#' # Filter to specific district and subject
#' jefferson_county <- aca_2024 |>
#'   dplyr::filter(district_id == "275", subject == "Reading")  # Jefferson County
#'
#' # Get 3rd grade math proficiency
#' grade3_math <- aca_2024 |>
#'   dplyr::filter(grade_level == "03", subject == "Mathematics", subgroup == "All Students")
#' }
fetch_aca <- function(end_year, tidy = TRUE, use_cache = TRUE) {

  # Validate year
  if (end_year < 2012 || end_year > 2025) {
    stop("end_year must be between 2012 and 2025. Assessment data available from 2011-2012 school year.")
  }

  # Check for COVID waiver year
  if (end_year == 2020) {
    stop("Assessments waived for 2019-2020 school year due to COVID-19 pandemic.")
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "aca_tidy" else "aca_wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached assessment data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data from KDE
  raw <- get_raw_assessment(end_year)

  # Process to standard schema
  processed <- process_assessment(raw, end_year)

  # Optionally tidy
  if (tidy) {
    processed <- tidy_assessment(processed) |>
      id_assessment_aggs()
  }

  # Cache the result
  if (use_cache) {
    write_cache(processed, end_year, cache_type)
  }

  processed
}


#' Fetch assessment data for multiple years
#'
#' Downloads and combines assessment data for multiple school years.
#'
#' @param end_years Vector of school year ends (e.g., c(2022, 2023, 2024))
#' @param tidy If TRUE (default), returns data in long (tidy) format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with assessment data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 3 years of data
#' aca_multi <- fetch_aca_multi(2022:2024)
#'
#' # Track assessment trends
#' aca_multi |>
#'   dplyr::filter(is_state, subject == "Reading", grade_level == "03",
#'                 subgroup == "All Students") |>
#'   dplyr::select(end_year, pct_proficient)
#'
#' # Compare district performance over time
#' aca_multi |>
#'   dplyr::filter(district_id == "275", subject == "Mathematics") |>
#'   dplyr::group_by(end_year, grade_level) |>
#'   dplyr::summarize(pct_proficient = mean(pct_proficient, na.rm = TRUE))
#' }
fetch_aca_multi <- function(end_years, tidy = TRUE, use_cache = TRUE) {

  # Validate years
  invalid_years <- end_years[end_years < 2012 | end_years > 2025]
  if (length(invalid_years) > 0) {
    stop(paste("Invalid years:", paste(invalid_years, collapse = ", "),
               "\nend_year must be between 2012 and 2025"))
  }

  # Check for COVID waiver year
  if (2020 %in% end_years) {
    warning("Removing 2020 from requested years (assessments waived due to COVID-19)")
    end_years <- end_years[end_years != 2020]
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching assessment data for", yr, "..."))
      tryCatch({
        fetch_aca(yr, tidy = tidy, use_cache = use_cache)
      }, error = function(e) {
        warning(paste("Failed to fetch", yr, ":", e$message))
        NULL
      })
    }
  )

  # Remove NULL results (failed years)
  results <- results[!sapply(results, is.null)]

  if (length(results) == 0) {
    stop("No assessment data could be fetched for any of the requested years.")
  }

  # Combine
  dplyr::bind_rows(results)
}
