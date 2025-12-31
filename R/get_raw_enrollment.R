# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from KDE.
# Data comes from three sources based on year:
#
# Era 1: SAAR Data (1997-2019)
#   - Superintendent's Annual Attendance Report
#   - Excel files with ethnic membership data by district
#   - URL: education.ky.gov/districts/enrol/Documents/
#
# Era 2: SRC Historical Datasets (2012-2019)
#   - School Report Card Historical Datasets
#   - CSV files with school-level enrollment
#   - URL: education.ky.gov/Open-House/data/HistoricalDatasets/
#
# Era 3: SRC Current Format (2020-2025)
#   - Open House SRC Datasets
#   - CSV files with primary/secondary enrollment
#   - URL: education.ky.gov/Open-House/data/HistoricalDatasets/
#
# ==============================================================================

#' Download raw enrollment data from KDE
#'
#' Downloads enrollment data from Kentucky Department of Education.
#' Uses SRC datasets for 2012+ and SAAR for 1997-2011.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with enrollment data frames
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  if (end_year < 1997 || end_year > 2025) {
    stop("end_year must be between 1997 and 2025. Use get_available_years() to see data availability.")
  }

  message(paste("Downloading KDE enrollment data for", end_year, "..."))

  # Use appropriate download function based on year
  if (end_year >= 2020) {
    # SRC Current Format (2020+)
    result <- download_src_current(end_year)
  } else if (end_year >= 2012) {
    # SRC Historical Datasets (2012-2019)
    result <- download_src_historical(end_year)
  } else {
    # SAAR Data (1997-2011)
    result <- download_saar_data(end_year)
  }

  result
}


#' Download SRC Current Format data (2020+)
#'
#' Downloads primary and secondary enrollment CSV files from Open House.
#'
#' @param end_year School year end (2020-2025)
#' @return List with primary and secondary data frames
#' @keywords internal
download_src_current <- function(end_year) {

  message("  Downloading SRC enrollment data (current format)...")

  base_url <- "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/"

  # For 2024+, KDE uses a different naming pattern: KYRC24_OVW_...
  if (end_year >= 2024) {
    year_suffix <- substr(as.character(end_year), 3, 4)
    primary_url <- paste0(base_url, "KYRC", year_suffix, "_OVW_Primary_Enrollment.csv")
    secondary_url <- paste0(base_url, "KYRC", year_suffix, "_OVW_Secondary_Enrollment.csv")
  } else {
    # 2020-2023 use simpler naming
    primary_url <- paste0(base_url, "primary_enrollment_", end_year, ".csv")
    secondary_url <- paste0(base_url, "secondary_enrollment_", end_year, ".csv")
  }

  # Download primary enrollment
  message("    Downloading primary enrollment...")
  primary_df <- download_kde_csv(primary_url, end_year, "primary")

  # Download secondary enrollment
  message("    Downloading secondary enrollment...")
  secondary_df <- download_kde_csv(secondary_url, end_year, "secondary")

  list(
    primary = primary_df,
    secondary = secondary_df,
    end_year = end_year,
    era = "src_current"
  )
}


#' Download SRC Historical data (2012-2019)
#'
#' Downloads enrollment data from SRC Historical Datasets.
#'
#' @param end_year School year end (2012-2019)
#' @return List with enrollment data frames
#' @keywords internal
download_src_historical <- function(end_year) {

  message("  Downloading SRC historical enrollment data...")

  base_url <- "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/"

  # Historical data uses different naming conventions
  # Try multiple URL patterns
  urls_to_try <- c(
    paste0(base_url, "primary_enrollment_", end_year, ".csv"),
    paste0(base_url, "secondary_enrollment_", end_year, ".csv"),
    paste0(base_url, "enrollment_", end_year, ".csv"),
    paste0(base_url, "Enrollment_", end_year, ".csv")
  )

  # Try primary enrollment first
  primary_url <- paste0(base_url, "primary_enrollment_", end_year, ".csv")
  secondary_url <- paste0(base_url, "secondary_enrollment_", end_year, ".csv")

  primary_df <- tryCatch({
    message("    Trying primary enrollment...")
    download_kde_csv(primary_url, end_year, "primary")
  }, error = function(e) {
    message("    Primary enrollment not found, trying combined file...")
    NULL
  })

  secondary_df <- tryCatch({
    message("    Trying secondary enrollment...")
    download_kde_csv(secondary_url, end_year, "secondary")
  }, error = function(e) {
    message("    Secondary enrollment not found...")
    NULL
  })

  # If no primary/secondary files, try combined enrollment file
  if (is.null(primary_df) && is.null(secondary_df)) {
    combined_url <- paste0(base_url, "enrollment_", end_year, ".csv")
    combined_df <- tryCatch({
      download_kde_csv(combined_url, end_year, "combined")
    }, error = function(e) {
      # Fall back to SAAR data if SRC files not available
      message("    SRC files not available, falling back to SAAR data...")
      return(NULL)
    })

    if (!is.null(combined_df)) {
      return(list(
        combined = combined_df,
        end_year = end_year,
        era = "src_historical"
      ))
    }

    # Use SAAR as fallback
    return(download_saar_data(end_year))
  }

  list(
    primary = primary_df,
    secondary = secondary_df,
    end_year = end_year,
    era = "src_historical"
  )
}


#' Download SAAR enrollment data (1997-2019)
#'
#' Downloads SAAR Ethnic Membership Report data from KDE.
#' This is district-level only.
#'
#' @param end_year School year end (1997-2019)
#' @return List with district enrollment data frame
#' @keywords internal
download_saar_data <- function(end_year) {

  message("  Downloading SAAR enrollment data...")

  if (end_year > 2019) {
    stop("SAAR data is only available through 2019. Use SRC data for later years.")
  }

  # The 1996-2019 SAAR Summary Reports Excel file
  saar_url <- "https://education.ky.gov/districts/enrol/Documents/1996-2019%20SAAR%20Summary%20ReportsADA.xlsx"

  # Create temp file
  tname <- tempfile(
    pattern = "kde_saar_",
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  # Download the file
  tryCatch({
    response <- httr::GET(
      saar_url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(300),
      httr::config(ssl_verifypeer = FALSE)  # KDE site has cert issues
    )

    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }

    # Check file size
    if (file.info(tname)$size < 1000) {
      stop("Downloaded file too small, likely an error page")
    }

  }, error = function(e) {
    stop(paste("Failed to download SAAR data:",
               "\nError:", e$message,
               "\nURL:", saar_url))
  })

  # Read the Excel file - data is in a sheet per year
  # Sheet names are like "1999", "2000", etc.
  sheet_name <- as.character(end_year)

  # Get available sheets
  sheets <- readxl::excel_sheets(tname)

  if (!(sheet_name %in% sheets)) {
    # Try with different formatting
    possible_sheets <- sheets[grepl(as.character(end_year), sheets)]
    if (length(possible_sheets) > 0) {
      sheet_name <- possible_sheets[1]
    } else {
      stop(paste("Year", end_year, "not found in SAAR data. Available years:",
                 paste(sheets, collapse = ", ")))
    }
  }

  message(paste("    Reading sheet:", sheet_name))

  # Read the specific year's sheet
  df <- readxl::read_excel(
    tname,
    sheet = sheet_name,
    col_types = "text"  # Read all as text to handle suppressions
  )

  unlink(tname)

  list(
    district = df,
    end_year = end_year,
    era = "saar"
  )
}


#' Download individual year SAAR report
#'
#' Downloads a single-year SAAR report for more recent years.
#'
#' @param end_year School year end
#' @return Data frame with SAAR data
#' @keywords internal
download_saar_single_year <- function(end_year) {

  # Individual year reports (2016-2019)
  base_url <- "https://education.ky.gov/districts/enrol/Documents/"
  saar_url <- paste0(base_url, end_year, " SAAR Summary Report.xlsx")

  tname <- tempfile(
    pattern = paste0("kde_saar_", end_year, "_"),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  tryCatch({
    response <- httr::GET(
      saar_url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(120),
      httr::config(ssl_verifypeer = FALSE)
    )

    if (httr::http_error(response)) {
      stop(paste("HTTP error:", httr::status_code(response)))
    }

  }, error = function(e) {
    stop(paste("Failed to download", end_year, "SAAR data"))
  })

  df <- readxl::read_excel(tname, col_types = "text")
  unlink(tname)

  df
}


#' Download a CSV file from KDE
#'
#' @param url URL to download
#' @param end_year School year for error messages
#' @param file_type File type for error messages
#' @return Data frame
#' @keywords internal
download_kde_csv <- function(url, end_year, file_type) {

  tname <- tempfile(
    pattern = paste0("kde_", file_type, "_"),
    tmpdir = tempdir(),
    fileext = ".csv"
  )

  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(180),
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
    stop(paste("Failed to download", file_type, "enrollment for year", end_year,
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


#' Get the URL for KDE enrollment data
#'
#' Returns the URL(s) where enrollment data can be found for a given year.
#'
#' @param end_year School year end
#' @return Character vector of URLs
#' @keywords internal
get_enrollment_urls <- function(end_year) {

  base_url <- "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/"

  if (end_year >= 2024) {
    year_suffix <- substr(as.character(end_year), 3, 4)
    c(
      paste0(base_url, "KYRC", year_suffix, "_OVW_Primary_Enrollment.csv"),
      paste0(base_url, "KYRC", year_suffix, "_OVW_Secondary_Enrollment.csv")
    )
  } else if (end_year >= 2020) {
    c(
      paste0(base_url, "primary_enrollment_", end_year, ".csv"),
      paste0(base_url, "secondary_enrollment_", end_year, ".csv")
    )
  } else if (end_year >= 2012) {
    c(
      paste0(base_url, "primary_enrollment_", end_year, ".csv"),
      paste0(base_url, "secondary_enrollment_", end_year, ".csv")
    )
  } else {
    "https://education.ky.gov/districts/enrol/Documents/1996-2019%20SAAR%20Summary%20ReportsADA.xlsx"
  }
}
