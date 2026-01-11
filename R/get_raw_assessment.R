# ==============================================================================
# Raw Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw assessment data from KDE.
# Data comes from Kentucky School Report Card (SRC) datasets.
#
# Assessment Data Availability:
# - 2011-2012 to present: K-PREP assessment results
# - Subjects: Reading, Mathematics, Science, Social Studies, Writing
# - Levels: K-8 by grade, High School by end-of-course exams
#
# Data Sources:
# - Historical SRC Datasets - Accountability:
#   https://www.education.ky.gov/Open-House/data/Pages/Historical_SRC_Datasets_Accountability.aspx
# - Assessment and Accountability Data:
#   https://education.ky.gov/Open-House/data/Pages/Assessment_Accountability_Datasets_2024-2025.aspx
#
# IMPORTANT: All URLs MUST include "www." prefix - KDE returns 403 without it.
# IMPORTANT: All requests MUST include a browser-like User-Agent header.
#
# Note: 2019-2020 assessments waived due to COVID-19
# Note: SAT/ACT data excluded per task requirements
#
# ==============================================================================

# User-Agent string for KDE downloads (required to avoid 403 errors)
KDE_USER_AGENT <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

#' Download raw assessment data from KDE
#'
#' Downloads assessment data from Kentucky Department of Education.
#' Uses SRC datasets for all available years (2011-2012 to present).
#'
#' @param end_year School year end (2012-2025)
#' @return List with assessment data frames
#' @keywords internal
get_raw_assessment <- function(end_year) {

  # Validate year
  if (end_year < 2012 || end_year > 2025) {
    stop("end_year must be between 2012 and 2025. Assessment data available from 2011-2012 school year.")
  }

  # 2019-2020 assessments waived due to COVID-19
  if (end_year == 2020) {
    stop("Assessments waived for 2019-2020 school year due to COVID-19 pandemic.")
  }

  message(paste("Downloading KDE assessment data for", end_year, "..."))

  # Use appropriate download function based on year
  if (end_year >= 2020) {
    # SRC Current Format (2020+, excluding 2020 which was waived)
    result <- download_assessment_current(end_year)
  } else {
    # SRC Historical Datasets (2012-2019)
    result <- download_assessment_historical(end_year)
  }

  result
}


#' Download Current Format Assessment Data (2021+)
#'
#' Downloads assessment CSV files from Open House for recent years.
#' Uses KYRC naming convention for 2024+.
#'
#' @param end_year School year end (2021-2025)
#' @return List with assessment data frames
#' @keywords internal
download_assessment_current <- function(end_year) {

  message("  Downloading assessment data (current format)...")

  base_url <- "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/"

  # Build list of URLs to try based on year
  if (end_year >= 2024) {
    # 2024+ uses KYRC naming convention
    year_suffix <- substr(as.character(end_year), 3, 4)
    possible_urls <- c(
      paste0(base_url, "KYRC", year_suffix, "_OVW_Assessment_Performance.csv"),
      paste0(base_url, "Accountable_Assessment_Performance_", end_year, ".csv"),
      paste0(base_url, "assessment_performance_", end_year, ".csv")
    )
  } else {
    # 2021-2023 use different naming patterns
    possible_urls <- c(
      paste0(base_url, "Accountable_Assessment_Performance_", end_year, ".csv"),
      paste0(base_url, "assessment_performance_", end_year, ".csv"),
      paste0(base_url, "Assessment_Performance_", end_year, ".csv")
    )
  }

  # Try each URL
  for (url in possible_urls) {
    message("    Trying: ", basename(url))
    assessment_df <- tryCatch({
      download_kde_assessment_csv(url, end_year, "assessment")
    }, error = function(e) {
      NULL
    })

    if (!is.null(assessment_df)) {
      return(list(
        assessment = assessment_df,
        end_year = end_year,
        era = "assessment_current"
      ))
    }
  }

  # If no data found, throw error with helpful message
  stop(paste("No assessment data found for year", end_year,
             "\nTried URLs:", paste(possible_urls, collapse = "\n"),
             "\n\nNote: Assessment data may not be available yet for this year.",
             "\nCheck: https://www.education.ky.gov/Open-House/data/Pages/Assessment_Accountability_Datasets_2024-2025.aspx"))
}


#' Download Historical Assessment Data (2012-2019)
#'
#' Downloads assessment data from SRC Historical Datasets.
#'
#' @param end_year School year end (2012-2019)
#' @return List with assessment data frames
#' @keywords internal
download_assessment_historical <- function(end_year) {

  message("  Downloading historical assessment data...")

  base_url <- "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/"

  # Historical data may use different naming conventions
  # Try multiple URL patterns
  possible_urls <- c(
    paste0(base_url, "KPREP_Assessment_", end_year, ".csv"),
    paste0(base_url, "assessment_", end_year, ".csv"),
    paste0(base_url, "Assessment_", end_year, ".csv"),
    paste0(base_url, "Accountable_Assessment_", end_year, ".csv")
  )

  for (url in possible_urls) {
    message("    Trying: ", basename(url))
    assessment_df <- tryCatch({
      download_kde_assessment_csv(url, end_year, "assessment")
    }, error = function(e) {
      NULL
    })

    if (!is.null(assessment_df)) {
      return(list(
        assessment = assessment_df,
        end_year = end_year,
        era = "assessment_historical"
      ))
    }
  }

  # If no data found, provide helpful error
  stop(paste("No assessment data found for year", end_year,
             "\nTried URLs:", paste(possible_urls, collapse = "\n"),
             "\n\nCheck data availability at:",
             "https://www.education.ky.gov/Open-House/data/Pages/Historical_SRC_Datasets_Accountability.aspx"))
}


#' Download a CSV assessment file from KDE
#'
#' @param url URL to download
#' @param end_year School year for error messages
#' @param file_type File type for error messages
#' @return Data frame
#' @keywords internal
download_kde_assessment_csv <- function(url, end_year, file_type) {

  tname <- tempfile(
    pattern = paste0("kde_assessment_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = ".csv"
  )

  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(180),
      httr::user_agent(KDE_USER_AGENT),
      httr::config(ssl_verifypeer = FALSE)  # KDE site has cert issues
    )

    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }

    # Check for error page (HTML instead of CSV)
    first_lines <- readLines(tname, n = 3, warn = FALSE)
    if (any(grepl("^<|<!DOCTYPE|<html", first_lines, ignore.case = TRUE))) {
      stop("Received HTML error page instead of CSV")
    }

    # Check file size
    if (file.info(tname)$size < 100) {
      stop("Downloaded file too small")
    }

  }, error = function(e) {
    stop(paste("Failed to download", file_type, "for year", end_year,
               "\nError:", e$message,
               "\nURL:", url))
  })

  # Read CSV
  df <- readr::read_csv(
    tname,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  unlink(tname)

  # Add end_year column
  df$end_year <- end_year

  df
}


#' Get the URL for KDE assessment data
#'
#' Returns the URL(s) where assessment data can be found for a given year.
#'
#' @param end_year School year end
#' @return Character vector of URLs
#' @export
#' @examples
#' get_assessment_urls(2024)
#' get_assessment_urls(2015)
get_assessment_urls <- function(end_year) {

  base_url <- "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/"

  if (end_year >= 2024) {
    # 2024+ uses KYRC naming
    year_suffix <- substr(as.character(end_year), 3, 4)
    paste0(base_url, "KYRC", year_suffix, "_OVW_Assessment_Performance.csv")
  } else if (end_year >= 2021) {
    # 2021-2023 use Accountable_Assessment naming
    c(
      paste0(base_url, "Accountable_Assessment_Performance_", end_year, ".csv"),
      paste0(base_url, "assessment_performance_", end_year, ".csv")
    )
  } else if (end_year >= 2012) {
    # 2012-2019 historical
    c(
      paste0(base_url, "KPREP_Assessment_", end_year, ".csv"),
      paste0(base_url, "assessment_", end_year, ".csv"),
      paste0(base_url, "Assessment_", end_year, ".csv")
    )
  } else {
    stop("Assessment data not available before 2012")
  }
}
