# Tests for cache functions

test_that("get_cache_dir creates directory if needed", {
  cache_dir <- get_cache_dir()

  # Should exist after calling
  expect_true(dir.exists(cache_dir))

  # Should contain kyschooldata in path
  expect_true(grepl("kyschooldata", cache_dir))
})

test_that("cache_exists returns FALSE for non-existent files", {
  # Year 9999 should never exist
  expect_false(cache_exists(9999, "tidy"))
  expect_false(cache_exists(9999, "wide"))
})

test_that("cache round-trip works correctly", {
  # Create test data
  test_df <- data.frame(
    end_year = 9999,
    district_id = "001",
    school_id = NA_character_,
    n_students = 100,
    stringsAsFactors = FALSE
  )

  # Write to cache
  write_cache(test_df, 9999, "test")

  # Should now exist
  expect_true(cache_exists(9999, "test"))

  # Read back
  result <- read_cache(9999, "test")
  expect_equal(result$n_students, 100)
  expect_equal(result$district_id, "001")

  # Clean up
  clear_cache(9999, "test")
  expect_false(cache_exists(9999, "test"))
})

test_that("clear_cache removes files correctly", {
  # Create test files
  test_df <- data.frame(x = 1)
  write_cache(test_df, 9998, "tidy")
  write_cache(test_df, 9998, "wide")
  write_cache(test_df, 9997, "tidy")

  # Clear specific file
  clear_cache(9998, "tidy")
  expect_false(cache_exists(9998, "tidy"))
  expect_true(cache_exists(9998, "wide"))

  # Clear by year
  write_cache(test_df, 9998, "tidy")
  clear_cache(9998)
  expect_false(cache_exists(9998, "tidy"))
  expect_false(cache_exists(9998, "wide"))

  # Clean up remaining
  clear_cache(9997)
})

test_that("cache_status returns data frame", {
  # Create a test file
  test_df <- data.frame(x = 1)
  write_cache(test_df, 9996, "test")

  # Get status (captures message)
  result <- cache_status()

  # Should be a data frame (even if empty after cleanup)
  expect_true(is.data.frame(result) || length(result) == 0)

  # Clean up
  clear_cache(9996)
})
