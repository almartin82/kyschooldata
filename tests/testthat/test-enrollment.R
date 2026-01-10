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
  expect_true("min_year" %in% names(result))
  expect_true("max_year" %in% names(result))
  expect_true(result$min_year >= 1990 & result$min_year <= 2030)
  expect_true(result$max_year >= 1990 & result$max_year <= 2030)
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
  # SRC Current format (2024+) - uses combined Student_Enrollment file
  urls_2024 <- get_enrollment_urls(2024)
  expect_true(any(grepl("KYRC24", urls_2024)))
  expect_true(any(grepl("Student_Enrollment", urls_2024)))

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

# Tidyness correctness tests (added 2026-01-05)
test_that("tidy format has all expected subgroups", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Check all expected subgroups are present
  expected_subgroups <- c("total_enrollment", "white", "black", "hispanic", "asian",
                         "native_american", "pacific_islander", "multiracial",
                         "male", "female", "special_ed", "lep", "econ_disadv")
  actual_subgroups <- unique(result$subgroup)

  expect_true(all(expected_subgroups %in% actual_subgroups),
              info = sprintf("Missing subgroups: %s",
                            setdiff(expected_subgroups, actual_subgroups)))
})

test_that("tidy format has all expected grade levels", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Check all expected grade levels are present
  expected_grades <- c("TOTAL", "PK", "K", "01", "02", "03", "04", "05", "06",
                      "07", "08", "09", "10", "11", "12")
  actual_grades <- unique(result$grade_level)

  expect_true(all(expected_grades %in% actual_grades),
              info = sprintf("Missing grade levels: %s",
                            setdiff(expected_grades, actual_grades)))
})

test_that("district_id and district_name are populated for non-State rows", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Check district rows have IDs and names
  district_rows <- result[result$type == "District", ]
  expect_true(sum(is.na(district_rows$district_id)) == 0,
              info = "District rows should not have NA district_id")
  expect_true(sum(is.na(district_rows$district_name)) == 0,
              info = "District rows should not have NA district_name")

  # Check school rows have district IDs and names
  school_rows <- result[result$type == "School", ]
  expect_true(sum(is.na(school_rows$district_id)) == 0,
              info = "School rows should not have NA district_id")
  expect_true(sum(is.na(school_rows$district_name)) == 0,
              info = "School rows should not have NA district_name")
})

test_that("no Inf or NaN values in tidy output", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Check for Inf/NaN in n_students
  expect_false(any(is.infinite(result$n_students)),
               info = "n_students should not contain Inf values")
  expect_false(any(is.nan(result$n_students)),
               info = "n_students should not contain NaN values")

  # Check for Inf/NaN in pct
  expect_false(any(is.infinite(result$pct)),
               info = "pct should not contain Inf values")
  expect_false(any(is.nan(result$pct)),
               info = "pct should not contain NaN values")
})

test_that("state total enrollment is reasonable", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Get state total
  state_total <- result[result$type == "State" &
                        result$subgroup == "total_enrollment" &
                        result$grade_level == "TOTAL", "n_students"]

  # State total should be positive and reasonable (500k-2M for Kentucky)
  expect_true(length(state_total) == 1, info = "Should have exactly 1 state total row")
  expect_true(state_total > 500000, info = "State total should be > 500k")
  expect_true(state_total < 2000000, info = "State total should be < 2M")
})

test_that("percentages are calculated correctly", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # Check that pct = n_students / total for a specific district
  adair_total <- result[result$district_id == "001" &
                        result$type == "District" &
                        result$subgroup == "total_enrollment" &
                        result$grade_level == "TOTAL", "n_students"]

  adair_white <- result[result$district_id == "001" &
                        result$type == "District" &
                        result$subgroup == "white" &
                        result$grade_level == "TOTAL", ]

  expect_true(nrow(adair_white) == 1, info = "Should have exactly 1 white subgroup row for Adair")
  expect_equal(adair_white$pct, adair_white$n_students / adair_total,
               tolerance = 0.0001,
               info = "pct should equal n_students / total")
})

test_that("both 2023 and 2024 data work correctly", {
  skip_on_cran()
  skip_if_offline()

  # Test 2023 (primary/secondary format)
  result_2023 <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  expect_true("district_id" %in% names(result_2023))
  expect_true(length(unique(result_2023$subgroup)) >= 13)

  # Test 2024 (combined KYRC format)
  result_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true("district_id" %in% names(result_2024))
  expect_true(length(unique(result_2024$subgroup)) >= 13)
})
