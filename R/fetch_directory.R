# ==============================================================================
# School Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# Kentucky Department of Education (KDE) via the OpenHouse Directory system.
#
# Data source: https://openhouse.education.ky.gov/Directory
# - Superintendents CSV: POST to /Superintendents with ExportType=CSV
# - Principals CSV: POST to /Principals with ExportType=CSV
#
# The directory data includes district-level superintendent info and
# school-level principal info with contact details and grade ranges.
# Email addresses are withheld by KDE for security reasons.
#
# ==============================================================================

#' Fetch Kentucky school directory data
#'
#' Downloads and processes school and district directory data from the Kentucky
#' Department of Education via the OpenHouse Directory system. This includes
#' all public schools with principal contact info and all districts with
#' superintendent contact info.
#'
#' @param end_year Currently unused. The directory data represents current
#'   schools/districts and is updated regularly. Included for API consistency
#'   with other fetch functions.
#' @param tidy If TRUE (default), returns data in a standardized format with
#'   consistent column names. If FALSE, returns raw column names from KDE.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from KDE.
#' @return A tibble with school directory data. Columns include:
#'   \itemize{
#'     \item \code{state_district_id}: 3-digit district identifier (zero-padded)
#'     \item \code{state_school_id}: 3-digit school identifier within district
#'     \item \code{district_name}: District name
#'     \item \code{school_name}: School name (NA for district-level rows)
#'     \item \code{entity_type}: "district" or "school"
#'     \item \code{address}: Street address
#'     \item \code{city}: City
#'     \item \code{state}: State (always "KY")
#'     \item \code{zip}: ZIP code
#'     \item \code{phone}: Phone number
#'     \item \code{fax}: Fax number
#'     \item \code{principal_name}: School principal name (schools only)
#'     \item \code{superintendent_name}: District superintendent name (districts only)
#'     \item \code{grades_served}: Grade range (schools only, e.g., "9th-Ungraded")
#'     \item \code{facility_type}: School classification code (e.g., "A1")
#'     \item \code{facility_description}: School type description
#'     \item \code{district_website}: District website URL (districts only)
#'   }
#' @details
#' The directory data is downloaded from KDE's OpenHouse system, which
#' provides CSV exports of superintendent and principal contact lists.
#' The data is updated by districts through the DASCR (District and School
#' Collection Repository) system.
#'
#' Note: For security reasons, KDE does not include email addresses in
#' the downloadable contact files.
#'
#' @export
#' @examples
#' \dontrun{
#' # Get school directory data
#' dir_data <- fetch_directory()
#'
#' # Get raw format (original KDE column names)
#' dir_raw <- fetch_directory(tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' dir_fresh <- fetch_directory(use_cache = FALSE)
#'
#' # Filter to schools only
#' library(dplyr)
#' schools <- dir_data |>
#'   filter(entity_type == "school")
#'
#' # Find all schools in a district
#' jefferson_schools <- dir_data |>
#'   filter(state_district_id == "275", entity_type == "school")
#' }
fetch_directory <- function(end_year = NULL, tidy = TRUE, use_cache = TRUE) {

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "directory_tidy" else "directory_raw"

  # Check cache first
  if (use_cache && cache_exists_directory(cache_type)) {
    message("Using cached school directory data")
    return(read_cache_directory(cache_type))
  }

  # Get raw data from KDE
  raw <- get_raw_directory()

  # Process to standard schema
  if (tidy) {
    result <- process_directory(raw)
  } else {
    result <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache_directory(result, cache_type)
  }

  result
}


#' Get raw school directory data from KDE
#'
#' Downloads the raw superintendent and principal CSV files from KDE's
#' OpenHouse Directory system. The download uses an anti-forgery token
#' and POST request, matching the browser export flow.
#'
#' @return A list with two data frames: `superintendents` and `principals`
#' @keywords internal
get_raw_directory <- function() {

  message("Downloading school directory data from KDE OpenHouse...")

  # Download both datasets
  supt_df <- download_openhouse_csv("Superintendents")
  principals_df <- download_openhouse_csv("Principals")

  message(paste("Loaded", nrow(supt_df), "district records and",
                nrow(principals_df), "school records"))

  list(
    superintendents = supt_df,
    principals = principals_df
  )
}


#' Download a CSV from KDE OpenHouse via POST
#'
#' KDE OpenHouse pages use anti-forgery tokens. This function:
#' 1. GETs the page to retrieve cookies and the __RequestVerificationToken
#' 2. POSTs back with ExportType=CSV to trigger the CSV download
#'
#' @param page_name The page to download from ("Superintendents" or "Principals")
#' @return A tibble with the CSV data
#' @keywords internal
download_openhouse_csv <- function(page_name) {

  base_url <- "https://openhouse.education.ky.gov"
  page_url <- paste0(base_url, "/", page_name)

  # Step 1: GET the page to retrieve the anti-forgery token and cookies
  get_response <- httr::GET(
    page_url,
    httr::config(ssl_verifypeer = FALSE),
    httr::timeout(60)
  )

  if (httr::http_error(get_response)) {
    stop(paste("Failed to load", page_name, "page. HTTP status:",
               httr::status_code(get_response)))
  }

  # Extract anti-forgery token from HTML
  page_content <- httr::content(get_response, as = "text", encoding = "UTF-8")
  token_match <- regmatches(
    page_content,
    regexpr('name="__RequestVerificationToken"[^>]*value="([^"]*)"', page_content)
  )

  if (length(token_match) == 0) {
    stop(paste("Could not find anti-forgery token on", page_name, "page"))
  }

  # Extract just the token value
  token <- sub('.*value="([^"]*)".*', "\\1", token_match)

  # Extract cookies from GET response
  cookies <- httr::cookies(get_response)

  # Step 2: POST with ExportType=CSV to download
  tname <- tempfile(pattern = paste0("kde_", tolower(page_name)), fileext = ".csv")

  post_response <- httr::POST(
    page_url,
    httr::config(ssl_verifypeer = FALSE),
    body = list(
      ExportType = "CSV",
      `__RequestVerificationToken` = token
    ),
    encode = "form",
    httr::set_cookies(.cookies = stats::setNames(cookies$value, cookies$name)),
    httr::write_disk(tname, overwrite = TRUE),
    httr::timeout(120)
  )

  if (httr::http_error(post_response)) {
    unlink(tname)
    stop(paste("Failed to download", page_name, "CSV. HTTP status:",
               httr::status_code(post_response)))
  }

  # Verify file size (should be a real CSV, not an error page)
  file_info <- file.info(tname)
  if (file_info$size < 1000) {
    unlink(tname)
    stop(paste("Download failed for", page_name,
               "- file too small, may be error page"))
  }

  message(paste("Downloaded", page_name, "CSV:",
                round(file_info$size / 1024, 1), "KB"))

  # Read CSV - all as character to preserve leading zeros
  df <- readr::read_csv(
    tname,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )

  # Clean up temp file
  unlink(tname)

  # Remove empty trailing columns (KDE CSVs have trailing commas)
  empty_cols <- sapply(df, function(x) all(is.na(x) | x == ""))
  if (any(empty_cols)) {
    df <- df[, !empty_cols, drop = FALSE]
  }

  dplyr::as_tibble(df)
}


#' Process raw directory data to standard schema
#'
#' Takes raw superintendent and principal data from KDE and standardizes
#' into a single combined data frame with consistent column names.
#'
#' @param raw_data List with `superintendents` and `principals` data frames
#'   from get_raw_directory()
#' @return Processed tibble with standard schema
#' @keywords internal
process_directory <- function(raw_data) {

  supt <- raw_data$superintendents
  principals <- raw_data$principals

  # --- Process superintendent (district-level) rows ---
  district_rows <- dplyr::tibble(
    state_district_id = standardize_district_id(supt[["District Code"]]),
    state_school_id = NA_character_,
    district_name = trimws(supt[["District Name"]]),
    school_name = NA_character_,
    entity_type = "district",
    superintendent_name = paste(
      trimws(supt[["Superintendent First Name"]]),
      trimws(supt[["Superintendent Last Name"]])
    ),
    principal_name = NA_character_,
    address = trimws(supt[["Address Line 1"]]),
    address_line_2 = trimws(supt[["Address Line 2"]]),
    city = trimws(supt[["City"]]),
    state = trimws(supt[["State"]]),
    zip = trimws(supt[["Zipcode"]]),
    phone = trimws(supt[["Phone"]]),
    fax = trimws(supt[["Fax"]]),
    facility_type = NA_character_,
    facility_description = NA_character_,
    low_grade = NA_character_,
    high_grade = NA_character_,
    grades_served = NA_character_,
    district_website = trimws(supt[["District Website"]])
  )

  # --- Process principal (school-level) rows ---
  school_rows <- dplyr::tibble(
    state_district_id = standardize_district_id(principals[["District Code"]]),
    state_school_id = sprintf("%03d", as.integer(principals[["School Code"]])),
    district_name = trimws(principals[["District Name"]]),
    school_name = trimws(principals[["School Name"]]),
    entity_type = "school",
    superintendent_name = NA_character_,
    principal_name = paste(
      trimws(principals[["Principal First Name"]]),
      trimws(principals[["Principal Last Name"]])
    ),
    address = trimws(principals[["Address Line 1"]]),
    address_line_2 = trimws(principals[["Address Line 2"]]),
    city = trimws(principals[["City"]]),
    state = trimws(principals[["State"]]),
    zip = trimws(principals[["Zipcode"]]),
    phone = trimws(principals[["Phone"]]),
    fax = trimws(principals[["Fax"]]),
    facility_type = trimws(principals[["Classification"]]),
    facility_description = trimws(principals[["Description"]]),
    low_grade = trimws(principals[["LOWGRADE"]]),
    high_grade = trimws(principals[["HIGHGRADE"]]),
    grades_served = paste0(
      trimws(principals[["LOWGRADE"]]), "-",
      trimws(principals[["HIGHGRADE"]])
    ),
    district_website = NA_character_
  )

  # Combine district and school rows
  result <- dplyr::bind_rows(district_rows, school_rows)

  # Default state to KY when missing (some charter schools have incomplete data)
  result$state[is.na(result$state) | result$state == ""] <- "KY"

  # Clean up empty address_line_2
  result$address_line_2[result$address_line_2 == "" | is.na(result$address_line_2)] <- NA_character_

  # Clean up empty district_website
  result$district_website[result$district_website == "" | is.na(result$district_website)] <- NA_character_

  # Reorder columns
  preferred_order <- c(
    "state_district_id", "state_school_id",
    "district_name", "school_name", "entity_type",
    "address", "address_line_2", "city", "state", "zip",
    "phone", "fax",
    "principal_name", "superintendent_name",
    "grades_served", "low_grade", "high_grade",
    "facility_type", "facility_description",
    "district_website"
  )

  existing_cols <- preferred_order[preferred_order %in% names(result)]
  other_cols <- setdiff(names(result), preferred_order)
  result <- result[, c(existing_cols, other_cols)]

  result
}


# ==============================================================================
# Directory-specific cache functions
# ==============================================================================

#' Build cache file path for directory data
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return File path string
#' @keywords internal
build_cache_path_directory <- function(cache_type) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_type, ".rds"))
}


#' Check if cached directory data exists
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @param max_age Maximum age in days (default 7). Set to Inf to ignore age.
#' @return Logical indicating if valid cache exists
#' @keywords internal
cache_exists_directory <- function(cache_type, max_age = 7) {
  cache_path <- build_cache_path_directory(cache_type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read directory data from cache
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Cached data frame
#' @keywords internal
read_cache_directory <- function(cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  readRDS(cache_path)
}


#' Write directory data to cache
#'
#' @param data Data frame to cache
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Invisibly returns the cache path
#' @keywords internal
write_cache_directory <- function(data, cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  cache_dir <- dirname(cache_path)

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  saveRDS(data, cache_path)
  invisible(cache_path)
}


#' Clear school directory cache
#'
#' Removes cached school directory data files.
#'
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear cached directory data
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist")
    return(invisible(0))
  }

  files <- list.files(cache_dir, pattern = "^directory_", full.names = TRUE)

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached directory file(s)"))
  } else {
    message("No cached directory files to remove")
  }

  invisible(length(files))
}
