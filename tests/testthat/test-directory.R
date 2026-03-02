# ==============================================================================
# LIVE Pipeline Tests for Kentucky School Directory
# ==============================================================================
#
# These tests verify the directory data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# Test Categories:
# 1. URL Availability - KDE OpenHouse is reachable
# 2. Raw Data Download - CSV export works for both pages
# 3. Column Structure - Expected columns exist
# 4. Tidy Schema - Standard columns present after processing
# 5. Data Quality - Non-empty, reasonable counts
# 6. Cache Round-Trip - Cache write/read preserves data
# 7. Raw vs Tidy Fidelity - Tidy matches raw
#
# ==============================================================================

library(testthat)

# Skip if no network connectivity
skip_if_no_network <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("KDE OpenHouse Directory page is accessible", {
  skip_on_cran()
  skip_if_no_network()

  response <- httr::GET(
    "https://openhouse.education.ky.gov/Directory",
    httr::config(ssl_verifypeer = FALSE),
    httr::timeout(30)
  )
  expect_equal(httr::status_code(response), 200)
})

test_that("KDE OpenHouse Superintendents page is accessible", {
  skip_on_cran()
  skip_if_no_network()

  response <- httr::GET(
    "https://openhouse.education.ky.gov/Superintendents",
    httr::config(ssl_verifypeer = FALSE),
    httr::timeout(30)
  )
  expect_equal(httr::status_code(response), 200)
})

test_that("KDE OpenHouse Principals page is accessible", {
  skip_on_cran()
  skip_if_no_network()

  response <- httr::GET(
    "https://openhouse.education.ky.gov/Principals",
    httr::config(ssl_verifypeer = FALSE),
    httr::timeout(30)
  )
  expect_equal(httr::status_code(response), 200)
})


# ==============================================================================
# STEP 2: Raw Data Download Tests
# ==============================================================================

test_that("get_raw_directory() returns both superintendent and principal data", {
  skip_on_cran()
  skip_if_no_network()

  raw <- get_raw_directory()

  expect_type(raw, "list")
  expect_true("superintendents" %in% names(raw))
  expect_true("principals" %in% names(raw))
  expect_s3_class(raw$superintendents, "tbl_df")
  expect_s3_class(raw$principals, "tbl_df")
})

test_that("raw superintendent data has expected columns", {
  skip_on_cran()
  skip_if_no_network()

  raw <- get_raw_directory()
  supt <- raw$superintendents

  expected_cols <- c(
    "District Code", "District Name",
    "Superintendent First Name", "Superintendent Last Name",
    "Address Line 1", "City", "State", "Zipcode", "Phone"
  )

  for (col in expected_cols) {
    expect_true(col %in% names(supt),
                info = paste("Missing column:", col))
  }
})

test_that("raw principal data has expected columns", {
  skip_on_cran()
  skip_if_no_network()

  raw <- get_raw_directory()
  principals <- raw$principals

  expected_cols <- c(
    "District Code", "District Name", "School Code", "School Name",
    "Principal First Name", "Principal Last Name",
    "Address Line 1", "City", "State", "Zipcode", "Phone",
    "Classification", "Description", "LOWGRADE", "HIGHGRADE"
  )

  for (col in expected_cols) {
    expect_true(col %in% names(principals),
                info = paste("Missing column:", col))
  }
})


# ==============================================================================
# STEP 3: Tidy Schema Tests
# ==============================================================================

test_that("fetch_directory(tidy = TRUE) returns standard schema", {
  skip_on_cran()
  skip_if_no_network()

  dir_data <- fetch_directory(use_cache = FALSE)

  expected_cols <- c(
    "state_district_id", "state_school_id",
    "district_name", "school_name", "entity_type",
    "address", "city", "state", "zip",
    "phone", "fax",
    "principal_name", "superintendent_name",
    "grades_served", "facility_type", "facility_description"
  )

  for (col in expected_cols) {
    expect_true(col %in% names(dir_data),
                info = paste("Missing column:", col))
  }
})

test_that("entity_type has only 'district' and 'school' values", {
  skip_on_cran()
  skip_if_no_network()

  dir_data <- fetch_directory(use_cache = FALSE)

  expect_true(all(dir_data$entity_type %in% c("district", "school")))
})

test_that("state column is always 'KY'", {
  skip_on_cran()
  skip_if_no_network()

  dir_data <- fetch_directory(use_cache = FALSE)

  expect_true(all(dir_data$state == "KY"))
})


# ==============================================================================
# STEP 4: Data Quality Tests
# ==============================================================================

test_that("directory data has multiple districts", {
  skip_on_cran()
  skip_if_no_network()

  dir_data <- fetch_directory(use_cache = FALSE)

  districts <- dir_data[dir_data$entity_type == "district", ]

  # Kentucky has ~170+ school districts
  expect_gt(nrow(districts), 150)
})

test_that("directory data has many schools", {
  skip_on_cran()
  skip_if_no_network()

  dir_data <- fetch_directory(use_cache = FALSE)

  schools <- dir_data[dir_data$entity_type == "school", ]

  # Kentucky has 1400+ schools
  expect_gt(nrow(schools), 1000)
})

test_that("most schools have principal names", {
  skip_on_cran()
  skip_if_no_network()

  dir_data <- fetch_directory(use_cache = FALSE)

  schools <- dir_data[dir_data$entity_type == "school", ]
  has_principal <- !is.na(schools$principal_name) & schools$principal_name != ""
  pct_with_principal <- mean(has_principal)

  expect_gt(pct_with_principal, 0.9)
})

test_that("most districts have superintendent names", {
  skip_on_cran()
  skip_if_no_network()

  dir_data <- fetch_directory(use_cache = FALSE)

  districts <- dir_data[dir_data$entity_type == "district", ]
  has_supt <- !is.na(districts$superintendent_name) & districts$superintendent_name != ""
  pct_with_supt <- mean(has_supt)

  expect_gt(pct_with_supt, 0.9)
})

test_that("district IDs are 3-digit zero-padded", {
  skip_on_cran()
  skip_if_no_network()

  dir_data <- fetch_directory(use_cache = FALSE)

  expect_true(all(grepl("^\\d{3}$", dir_data$state_district_id)),
              info = "All district IDs should be 3-digit zero-padded")
})

test_that("school IDs are 3-digit zero-padded", {
  skip_on_cran()
  skip_if_no_network()

  dir_data <- fetch_directory(use_cache = FALSE)

  schools <- dir_data[dir_data$entity_type == "school", ]

  expect_true(all(grepl("^\\d{3}$", schools$state_school_id)),
              info = "All school IDs should be 3-digit zero-padded")
})


# ==============================================================================
# STEP 5: Cache Round-Trip Tests
# ==============================================================================

test_that("cache write and read preserves directory data", {
  skip_on_cran()
  skip_if_no_network()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Write to cache
  write_cache_directory(dir_data, "directory_tidy_test")

  # Read from cache
  cached <- read_cache_directory("directory_tidy_test")

  expect_equal(nrow(dir_data), nrow(cached))
  expect_equal(ncol(dir_data), ncol(cached))
  expect_equal(names(dir_data), names(cached))
  expect_identical(dir_data, cached)

  # Clean up test cache
  cache_path <- build_cache_path_directory("directory_tidy_test")
  if (file.exists(cache_path)) unlink(cache_path)
})


# ==============================================================================
# STEP 6: Raw vs Tidy Fidelity Tests
# ==============================================================================

test_that("tidy data preserves raw district count", {
  skip_on_cran()
  skip_if_no_network()

  raw <- get_raw_directory()
  tidy <- fetch_directory(use_cache = FALSE)

  raw_district_count <- nrow(raw$superintendents)
  tidy_district_count <- sum(tidy$entity_type == "district")

  expect_equal(raw_district_count, tidy_district_count,
               info = "Tidy district count should match raw superintendent count")
})

test_that("tidy data preserves raw school count", {
  skip_on_cran()
  skip_if_no_network()

  raw <- get_raw_directory()
  tidy <- fetch_directory(use_cache = FALSE)

  raw_school_count <- nrow(raw$principals)
  tidy_school_count <- sum(tidy$entity_type == "school")

  expect_equal(raw_school_count, tidy_school_count,
               info = "Tidy school count should match raw principal count")
})

test_that("tidy district names match raw district names", {
  skip_on_cran()
  skip_if_no_network()

  raw <- get_raw_directory()
  tidy <- fetch_directory(use_cache = FALSE)

  raw_names <- sort(trimws(raw$superintendents[["District Name"]]))
  tidy_names <- sort(tidy$district_name[tidy$entity_type == "district"])

  expect_equal(raw_names, tidy_names,
               info = "District names should match between raw and tidy")
})
