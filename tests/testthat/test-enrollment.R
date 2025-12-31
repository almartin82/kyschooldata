# Tests for enrollment functions
# Note: Most tests are marked as skip_on_cran since they require network access

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)

  # Suppressed values
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric("---")))
  expect_true(is.na(safe_numeric("n<10")))

  # Whitespace handling
  expect_equal(safe_numeric("  100  "), 100)
})

test_that("standardize_district_id pads correctly", {
  expect_equal(standardize_district_id("1"), "001")
  expect_equal(standardize_district_id("12"), "012")
  expect_equal(standardize_district_id("123"), "123")
  expect_equal(standardize_district_id("  42  "), "042")
})

test_that("standardize_school_id pads correctly", {
  expect_equal(standardize_school_id("123456"), "123456")
  expect_equal(standardize_school_id("1234"), "001234")
})

test_that("fetch_enr validates year parameter", {
  expect_error(fetch_enr(1990), "end_year must be between")
  expect_error(fetch_enr(2030), "end_year must be between")
})

test_that("get_available_years returns year ranges", {
  result <- get_available_years()
  expect_type(result, "list")
  expect_true("saar" %in% names(result))
  expect_true("src_historical" %in% names(result))
  expect_true("src_current" %in% names(result))
})

test_that("get_cache_dir returns valid path", {
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(grepl("kyschooldata", cache_dir))
})

test_that("cache functions work correctly", {
  # Test cache path generation
  path <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024.rds", path))

  # Test cache_exists returns FALSE for non-existent cache
  expect_false(cache_exists(9999, "tidy"))
})

test_that("get_enrollment_urls returns correct URLs", {
  # SRC Current format (2024+)
  urls_2024 <- get_enrollment_urls(2024)
  expect_true(any(grepl("KYRC24", urls_2024)))
  expect_true(any(grepl("Primary", urls_2024)))
  expect_true(any(grepl("Secondary", urls_2024)))

  # SRC Current format (2020-2023)
  urls_2023 <- get_enrollment_urls(2023)
  expect_true(any(grepl("primary_enrollment_2023", urls_2023)))
  expect_true(any(grepl("secondary_enrollment_2023", urls_2023)))

  # SAAR data (pre-2012)
  urls_2010 <- get_enrollment_urls(2010)
  expect_true(any(grepl("SAAR", urls_2010)))
})

# Integration tests (require network access)
test_that("fetch_enr downloads and processes SRC current data", {
  skip_on_cran()
  skip_if_offline()

  # Use a recent year
  result <- fetch_enr(2023, tidy = FALSE, use_cache = FALSE)

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("district_id" %in% names(result))
  expect_true("school_id" %in% names(result))
  expect_true("row_total" %in% names(result))
  expect_true("type" %in% names(result))

  # Check we have all levels
  expect_true("State" %in% result$type)
  expect_true("District" %in% result$type || "School" %in% result$type)

  # Check ID formats - district IDs should be 3 digits
  districts <- result[result$type == "District" & !is.na(result$district_id), ]
  if (nrow(districts) > 0) {
    expect_true(all(nchar(districts$district_id) == 3))
  }
})

test_that("fetch_enr downloads SAAR data for older years", {
  skip_on_cran()
  skip_if_offline()

  # SAAR year
  result <- fetch_enr(2010, tidy = FALSE, use_cache = FALSE)

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("district_id" %in% names(result))
  expect_true("row_total" %in% names(result))
  expect_true("type" %in% names(result))

  # SAAR data is district-level only
  expect_true("State" %in% result$type)
  expect_true("District" %in% result$type)
})

test_that("tidy_enr produces correct long format", {
  skip_on_cran()
  skip_if_offline()

  # Get wide data
  wide <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)

  # Tidy it
  tidy_result <- tidy_enr(wide)

  # Check structure
  expect_true("grade_level" %in% names(tidy_result))
  expect_true("subgroup" %in% names(tidy_result))
  expect_true("n_students" %in% names(tidy_result))
  expect_true("pct" %in% names(tidy_result))

  # Check subgroups include expected values
  subgroups <- unique(tidy_result$subgroup)
  expect_true("total_enrollment" %in% subgroups)
})

test_that("id_enr_aggs adds correct flags", {
  skip_on_cran()
  skip_if_offline()

  # Get tidy data with aggregation flags
  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Check flags exist
  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_school" %in% names(result))

  # Check flags are boolean
  expect_true(is.logical(result$is_state))
  expect_true(is.logical(result$is_district))
  expect_true(is.logical(result$is_school))

  # Check mutual exclusivity (each row is only one type)
  type_sums <- result$is_state + result$is_district + result$is_school
  expect_true(all(type_sums == 1))
})

test_that("fetch_enr_multi combines multiple years", {
  skip_on_cran()
  skip_if_offline()

  # Fetch 2 years
  result <- fetch_enr_multi(c(2022, 2023), tidy = TRUE, use_cache = TRUE)

  # Check we have both years
  expect_true(2022 %in% result$end_year)
  expect_true(2023 %in% result$end_year)
})
