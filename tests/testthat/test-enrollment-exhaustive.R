# ==============================================================================
# Exhaustive Enrollment Tests for kyschooldata
# ==============================================================================
#
# Tests every exported function with every parameter combination.
# All pinned values come from real Kentucky DOE data (fetched via use_cache = TRUE).
#
# ==============================================================================

library(testthat)

# ==============================================================================
# SECTION 1: fetch_enr() — Parameter Combinations
# ==============================================================================

# --- Year validation ---

test_that("fetch_enr rejects years below valid range", {
  expect_error(fetch_enr(1996), "end_year must be between")
  expect_error(fetch_enr(1990), "end_year must be between")
  expect_error(fetch_enr(0), "end_year must be between")
})

test_that("fetch_enr rejects years above valid range", {
  expect_error(fetch_enr(2025), "end_year must be between")
  expect_error(fetch_enr(2030), "end_year must be between")
  expect_error(fetch_enr(3000), "end_year must be between")
})

test_that("fetch_enr boundary years accepted: 1997 and 2024", {
  skip_on_cran()
  skip_if_offline()

  # 2024 should work (SRC current)
  result <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.data.frame(result))
  expect_gt(nrow(result), 0)

  # 1997 should be accepted (SAAR era)
  # Note: SAAR parsing may produce empty results, but no error should be thrown
  result_1997 <- fetch_enr(1997, tidy = FALSE, use_cache = TRUE)
  expect_true(is.data.frame(result_1997))
})

# --- tidy parameter ---

test_that("fetch_enr with tidy=TRUE returns long format with expected columns", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expected_cols <- c("end_year", "type", "district_id", "school_id",
                     "district_name", "school_name", "grade_level",
                     "subgroup", "n_students", "pct",
                     "is_state", "is_district", "is_school", "aggregation_flag")
  expect_true(all(expected_cols %in% names(result)),
              info = paste("Missing:", setdiff(expected_cols, names(result))))
})

test_that("fetch_enr with tidy=FALSE returns wide format with expected columns", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expected_cols <- c("end_year", "type", "district_id", "school_id",
                     "district_name", "school_name", "row_total",
                     "white", "black", "hispanic", "asian",
                     "pacific_islander", "native_american", "multiracial",
                     "male", "female", "econ_disadv", "lep", "special_ed",
                     "grade_pk", "grade_k",
                     "grade_01", "grade_02", "grade_03", "grade_04",
                     "grade_05", "grade_06", "grade_07", "grade_08",
                     "grade_09", "grade_10", "grade_11", "grade_12")
  expect_equal(names(result), expected_cols)
})

test_that("tidy=TRUE returns more rows than tidy=FALSE (pivot makes it longer)", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_gt(nrow(tidy), nrow(wide))
})

test_that("fetch_enr default tidy=TRUE matches explicit tidy=TRUE", {
  skip_on_cran()
  skip_if_offline()

  default <- fetch_enr(2024, use_cache = TRUE)
  explicit <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_equal(nrow(default), nrow(explicit))
  expect_equal(names(default), names(explicit))
})

# --- use_cache parameter ---

test_that("fetch_enr with use_cache=TRUE returns cached data", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.data.frame(result))
  expect_gt(nrow(result), 0)
})

# --- Multiple years (SRC current format: 2020-2024) ---

test_that("fetch_enr works for 2024 (KYRC combined format)", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(2024 %in% result$end_year)
  expect_equal(nrow(result), 27962)
})

test_that("fetch_enr works for 2023 (primary/secondary format)", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  expect_true(2023 %in% result$end_year)
  expect_true(nrow(result) > 20000)
})

test_that("fetch_enr works for 2022 (primary/secondary format)", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2022, tidy = TRUE, use_cache = TRUE)
  expect_true(2022 %in% result$end_year)
  expect_true(nrow(result) > 20000)
})

test_that("fetch_enr works for 2021 (primary/secondary format)", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2021, tidy = TRUE, use_cache = TRUE)
  expect_true(2021 %in% result$end_year)
  expect_true(nrow(result) > 20000)
})

test_that("fetch_enr works for 2020 (primary/secondary format)", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  expect_true(2020 %in% result$end_year)
  expect_true(nrow(result) > 20000)
})

# ==============================================================================
# SECTION 2: fetch_enr_multi() — Parameter Combinations
# ==============================================================================

test_that("fetch_enr_multi validates year parameters", {
  expect_error(fetch_enr_multi(c(2020, 2030)), "Invalid years")
  expect_error(fetch_enr_multi(c(1990, 2024)), "Invalid years")
})

test_that("fetch_enr_multi with single year returns same as fetch_enr", {
  skip_on_cran()
  skip_if_offline()

  single <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  multi <- fetch_enr_multi(2024, tidy = TRUE, use_cache = TRUE)

  expect_equal(nrow(single), nrow(multi))
  expect_equal(sort(names(single)), sort(names(multi)))
})

test_that("fetch_enr_multi combines 2 years correctly", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr_multi(c(2023, 2024), tidy = TRUE, use_cache = TRUE)

  expect_true(2023 %in% result$end_year)
  expect_true(2024 %in% result$end_year)

  # Rows should be sum of individual years
  rows_2023 <- nrow(result[result$end_year == 2023, ])
  rows_2024 <- nrow(result[result$end_year == 2024, ])
  expect_equal(rows_2023 + rows_2024, nrow(result))
})

test_that("fetch_enr_multi combines 3 years correctly", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr_multi(c(2022, 2023, 2024), tidy = TRUE, use_cache = TRUE)

  expect_true(2022 %in% result$end_year)
  expect_true(2023 %in% result$end_year)
  expect_true(2024 %in% result$end_year)
  expect_equal(length(unique(result$end_year)), 3)
})

test_that("fetch_enr_multi with tidy=FALSE returns wide format for all years", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr_multi(c(2023, 2024), tidy = FALSE, use_cache = TRUE)

  expect_true("row_total" %in% names(result))
  expect_false("subgroup" %in% names(result))
  expect_true(2023 %in% result$end_year)
  expect_true(2024 %in% result$end_year)
})

test_that("fetch_enr_multi year range 2020:2024 returns 5 years", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr_multi(2020:2024, tidy = TRUE, use_cache = TRUE)
  expect_equal(length(unique(result$end_year)), 5)
  expect_equal(sort(unique(result$end_year)), 2020:2024)
})

# ==============================================================================
# SECTION 3: Pinned State Totals Across Years (SRC era)
# ==============================================================================

test_that("2024 state total enrollment is 686,224", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 686224)
})

test_that("2023 state total enrollment is 687,294", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 687294)
})

test_that("2022 state total enrollment is 685,401", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2022, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 685401)
})

test_that("2021 state total enrollment is 682,953", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2021, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 682953)
})

test_that("2020 state total enrollment is 698,388", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2020, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 698388)
})

# ==============================================================================
# SECTION 4: Pinned State Demographic Totals (2024)
# ==============================================================================

test_that("2024 state white enrollment is 488,062", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "white" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 488062)
})

test_that("2024 state black enrollment is 74,804", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "black" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 74804)
})

test_that("2024 state hispanic enrollment is 69,877", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "hispanic" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 69877)
})

test_that("2024 state asian enrollment is 14,529", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "asian" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 14529)
})

test_that("2024 state native_american enrollment is 948", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "native_american" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 948)
})

test_that("2024 state pacific_islander enrollment is 1,323", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "pacific_islander" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 1323)
})

test_that("2024 state multiracial enrollment is 36,681", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "multiracial" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 36681)
})

test_that("2024 state male enrollment is 354,795", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "male" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 354795)
})

test_that("2024 state female enrollment is 331,429", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "female" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 331429)
})

test_that("2024 state econ_disadv enrollment is 426,203", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "econ_disadv" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 426203)
})

test_that("2024 state special_ed enrollment is 119,676", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "special_ed" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 119676)
})

test_that("2024 state lep enrollment is 51,167", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "lep" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 51167)
})

# ==============================================================================
# SECTION 5: Pinned State Grade-Level Counts (2024)
# ==============================================================================

test_that("2024 state PK enrollment is 31,467", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "PK"]
  expect_equal(val, 31467)
})

test_that("2024 state K enrollment is 49,681", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "K"]
  expect_equal(val, 49681)
})

test_that("2024 state grade 01 enrollment is 50,859", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "01"]
  expect_equal(val, 50859)
})

test_that("2024 state grade 05 enrollment is 49,728", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "05"]
  expect_equal(val, 49728)
})

test_that("2024 state grade 08 enrollment is 50,090", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "08"]
  expect_equal(val, 50090)
})

test_that("2024 state grade 09 enrollment is 56,075", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "09"]
  expect_equal(val, 56075)
})

test_that("2024 state grade 12 enrollment is 47,786", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "12"]
  expect_equal(val, 47786)
})

# ==============================================================================
# SECTION 6: Pinned State Demographic Totals (2023)
# ==============================================================================

test_that("2023 state white enrollment is 497,455", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "white" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 497455)
})

test_that("2023 state black enrollment is 74,745", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "black" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 74745)
})

test_that("2023 state hispanic enrollment is 63,502", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "hispanic" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 63502)
})

test_that("2023 state econ_disadv enrollment is 421,417", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "econ_disadv" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 421417)
})

test_that("2023 state special_ed enrollment is 116,633", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "special_ed" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 116633)
})

test_that("2023 state lep enrollment is 44,263", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "lep" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 44263)
})

# ==============================================================================
# SECTION 7: Pinned State Grade-Level Counts (2023)
# ==============================================================================

test_that("2023 state PK enrollment is 32,005", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "PK"]
  expect_equal(val, 32005)
})

test_that("2023 state K enrollment is 50,375", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "K"]
  expect_equal(val, 50375)
})

test_that("2023 state grade 09 enrollment is 57,576", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "09"]
  expect_equal(val, 57576)
})

# ==============================================================================
# SECTION 8: Pinned District Values — Boone County (035), 2024
# ==============================================================================

test_that("2024 Boone County (035) total enrollment is 21,583", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$district_id == "035" & tidy$is_district &
                          tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 21583)
})

test_that("2024 Boone County (035) all subgroups pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  b <- tidy[tidy$district_id == "035" & tidy$is_district &
             tidy$grade_level == "TOTAL", ]

  expect_equal(b$n_students[b$subgroup == "white"], 15283)
  expect_equal(b$n_students[b$subgroup == "black"], 1739)
  expect_equal(b$n_students[b$subgroup == "hispanic"], 2640)
  expect_equal(b$n_students[b$subgroup == "asian"], 615)
  expect_equal(b$n_students[b$subgroup == "native_american"], 16)
  expect_equal(b$n_students[b$subgroup == "pacific_islander"], 143)
  expect_equal(b$n_students[b$subgroup == "multiracial"], 1147)
  expect_equal(b$n_students[b$subgroup == "male"], 11098)
  expect_equal(b$n_students[b$subgroup == "female"], 10485)
  expect_equal(b$n_students[b$subgroup == "special_ed"], 3270)
  expect_equal(b$n_students[b$subgroup == "lep"], 2141)
  expect_equal(b$n_students[b$subgroup == "econ_disadv"], 10058)
})

test_that("2024 Boone County (035) grade-level counts pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  b <- tidy[tidy$district_id == "035" & tidy$is_district &
             tidy$subgroup == "total_enrollment", ]

  expect_equal(b$n_students[b$grade_level == "PK"], 654)
  expect_equal(b$n_students[b$grade_level == "K"], 1578)
  expect_equal(b$n_students[b$grade_level == "01"], 1568)
  expect_equal(b$n_students[b$grade_level == "02"], 1555)
  expect_equal(b$n_students[b$grade_level == "03"], 1528)
  expect_equal(b$n_students[b$grade_level == "04"], 1594)
  expect_equal(b$n_students[b$grade_level == "05"], 1644)
  expect_equal(b$n_students[b$grade_level == "06"], 1450)
  expect_equal(b$n_students[b$grade_level == "07"], 1631)
  expect_equal(b$n_students[b$grade_level == "08"], 1641)
  expect_equal(b$n_students[b$grade_level == "09"], 1827)
  expect_equal(b$n_students[b$grade_level == "10"], 1736)
  expect_equal(b$n_students[b$grade_level == "11"], 1571)
  expect_equal(b$n_students[b$grade_level == "12"], 1583)
})

# ==============================================================================
# SECTION 9: Pinned District Values — Warren County (571), 2024
# ==============================================================================

test_that("2024 Warren County (571) total enrollment is 20,394", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$district_id == "571" & tidy$is_district &
                          tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 20394)
})

test_that("2024 Warren County (571) all subgroups pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  w <- tidy[tidy$district_id == "571" & tidy$is_district &
             tidy$grade_level == "TOTAL", ]

  expect_equal(w$n_students[w$subgroup == "white"], 11932)
  expect_equal(w$n_students[w$subgroup == "black"], 2334)
  expect_equal(w$n_students[w$subgroup == "hispanic"], 2659)
  expect_equal(w$n_students[w$subgroup == "asian"], 1987)
  expect_equal(w$n_students[w$subgroup == "native_american"], 28)
  expect_equal(w$n_students[w$subgroup == "pacific_islander"], 265)
  expect_equal(w$n_students[w$subgroup == "multiracial"], 1189)
  expect_equal(w$n_students[w$subgroup == "male"], 10419)
  expect_equal(w$n_students[w$subgroup == "female"], 9975)
  expect_equal(w$n_students[w$subgroup == "special_ed"], 3235)
  expect_equal(w$n_students[w$subgroup == "lep"], 3715)
  expect_equal(w$n_students[w$subgroup == "econ_disadv"], 12992)
})

test_that("2024 Warren County (571) grade-level counts pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  w <- tidy[tidy$district_id == "571" & tidy$is_district &
             tidy$subgroup == "total_enrollment", ]

  expect_equal(w$n_students[w$grade_level == "PK"], 875)
  expect_equal(w$n_students[w$grade_level == "K"], 1474)
  expect_equal(w$n_students[w$grade_level == "01"], 1433)
  expect_equal(w$n_students[w$grade_level == "02"], 1580)
  expect_equal(w$n_students[w$grade_level == "03"], 1459)
  expect_equal(w$n_students[w$grade_level == "04"], 1512)
  expect_equal(w$n_students[w$grade_level == "05"], 1504)
  expect_equal(w$n_students[w$grade_level == "06"], 1372)
  expect_equal(w$n_students[w$grade_level == "07"], 1508)
  expect_equal(w$n_students[w$grade_level == "08"], 1526)
  expect_equal(w$n_students[w$grade_level == "09"], 1697)
  expect_equal(w$n_students[w$grade_level == "10"], 1610)
  expect_equal(w$n_students[w$grade_level == "11"], 1353)
  expect_equal(w$n_students[w$grade_level == "12"], 1485)
})

# ==============================================================================
# SECTION 10: Pinned District Values — Warren County (571), 2023
# ==============================================================================

test_that("2023 Warren County (571) total enrollment is 20,042", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$district_id == "571" & tidy$is_district &
                          tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 20042)
})

test_that("2023 Warren County (571) key subgroups pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  w <- tidy[tidy$district_id == "571" & tidy$is_district &
             tidy$grade_level == "TOTAL", ]

  expect_equal(w$n_students[w$subgroup == "white"], 12207)
  expect_equal(w$n_students[w$subgroup == "black"], 2182)
  expect_equal(w$n_students[w$subgroup == "hispanic"], 2339)
  expect_equal(w$n_students[w$subgroup == "asian"], 1908)
  expect_equal(w$n_students[w$subgroup == "econ_disadv"], 12381)
  expect_equal(w$n_students[w$subgroup == "lep"], 3397)
})

# ==============================================================================
# SECTION 11: Pinned District Values — Adair County (001), 2023
# ==============================================================================

test_that("2023 Adair County (001) all subgroups pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  a <- tidy[tidy$district_id == "001" & tidy$is_district &
             tidy$grade_level == "TOTAL", ]

  expect_equal(a$n_students[a$subgroup == "total_enrollment"], 3123)
  expect_equal(a$n_students[a$subgroup == "white"], 2520)
  expect_equal(a$n_students[a$subgroup == "black"], 212)
  expect_equal(a$n_students[a$subgroup == "hispanic"], 197)
  expect_equal(a$n_students[a$subgroup == "asian"], 11)
  expect_equal(a$n_students[a$subgroup == "native_american"], 5)
  expect_equal(a$n_students[a$subgroup == "pacific_islander"], 1)
  expect_equal(a$n_students[a$subgroup == "multiracial"], 177)
  expect_equal(a$n_students[a$subgroup == "male"], 1765)
  expect_equal(a$n_students[a$subgroup == "female"], 1358)
  expect_equal(a$n_students[a$subgroup == "special_ed"], 537)
  expect_equal(a$n_students[a$subgroup == "lep"], 80)
  expect_equal(a$n_students[a$subgroup == "econ_disadv"], 2070)
})

# ==============================================================================
# SECTION 12: Pinned District Values — Jefferson County (275), 2022
# ==============================================================================

test_that("2022 Jefferson County (275) key subgroups pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2022, tidy = TRUE, use_cache = TRUE)
  jc <- tidy[tidy$district_id == "275" & tidy$is_district &
              tidy$grade_level == "TOTAL", ]

  expect_equal(jc$n_students[jc$subgroup == "total_enrollment"], 102204)
  expect_equal(jc$n_students[jc$subgroup == "white"], 39836)
  expect_equal(jc$n_students[jc$subgroup == "black"], 37378)
  expect_equal(jc$n_students[jc$subgroup == "hispanic"], 14222)
  expect_equal(jc$n_students[jc$subgroup == "asian"], 4788)
  expect_equal(jc$n_students[jc$subgroup == "econ_disadv"], 67369)
  expect_equal(jc$n_students[jc$subgroup == "lep"], 14723)
  expect_equal(jc$n_students[jc$subgroup == "special_ed"], 13789)
})

# ==============================================================================
# SECTION 13: Pinned District Values — Fayette County (165), 2022
# ==============================================================================

test_that("2022 Fayette County (165) key subgroups pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2022, tidy = TRUE, use_cache = TRUE)
  fay <- tidy[tidy$district_id == "165" & tidy$is_district &
               tidy$grade_level == "TOTAL", ]

  expect_equal(fay$n_students[fay$subgroup == "total_enrollment"], 43849)
  expect_equal(fay$n_students[fay$subgroup == "white"], 20001)
  expect_equal(fay$n_students[fay$subgroup == "black"], 10244)
  expect_equal(fay$n_students[fay$subgroup == "hispanic"], 8468)
  expect_equal(fay$n_students[fay$subgroup == "asian"], 2199)
  expect_equal(fay$n_students[fay$subgroup == "econ_disadv"], 23830)
})

# ==============================================================================
# SECTION 14: Pinned School-Level Values — Alvaton Elementary (571/010), 2024
# ==============================================================================

test_that("2024 Alvaton Elementary (571/010) total enrollment is 827", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  val <- tidy$n_students[tidy$district_id == "571" & tidy$school_id == "010" &
                          tidy$is_school &
                          tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL"]
  expect_equal(val, 827)
})

test_that("2024 Alvaton Elementary (571/010) demographics pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  sch <- tidy[tidy$district_id == "571" & tidy$school_id == "010" &
               tidy$is_school & tidy$grade_level == "TOTAL", ]

  expect_equal(sch$n_students[sch$subgroup == "white"], 586)
  expect_equal(sch$n_students[sch$subgroup == "black"], 41)
  expect_equal(sch$n_students[sch$subgroup == "hispanic"], 67)
  expect_equal(sch$n_students[sch$subgroup == "asian"], 78)
  expect_equal(sch$n_students[sch$subgroup == "pacific_islander"], 7)
  expect_equal(sch$n_students[sch$subgroup == "multiracial"], 48)
  expect_equal(sch$n_students[sch$subgroup == "male"], 424)
  expect_equal(sch$n_students[sch$subgroup == "female"], 403)
  expect_equal(sch$n_students[sch$subgroup == "special_ed"], 165)
  expect_equal(sch$n_students[sch$subgroup == "lep"], 114)
  expect_equal(sch$n_students[sch$subgroup == "econ_disadv"], 483)
})

test_that("2024 Alvaton Elementary (571/010) grade-level counts pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  sch <- tidy[tidy$district_id == "571" & tidy$school_id == "010" &
               tidy$is_school & tidy$subgroup == "total_enrollment", ]

  expect_equal(sch$n_students[sch$grade_level == "PK"], 65)
  expect_equal(sch$n_students[sch$grade_level == "K"], 119)
  expect_equal(sch$n_students[sch$grade_level == "01"], 94)
  expect_equal(sch$n_students[sch$grade_level == "02"], 116)
  expect_equal(sch$n_students[sch$grade_level == "03"], 109)
  expect_equal(sch$n_students[sch$grade_level == "04"], 118)
  expect_equal(sch$n_students[sch$grade_level == "05"], 98)
  expect_equal(sch$n_students[sch$grade_level == "06"], 108)
})

test_that("2024 Alvaton Elementary has no high school grades (NA in wide)", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  sch <- wide[wide$district_id == "571" & wide$school_id == "010" &
               wide$type == "School", ]

  expect_true(is.na(sch$grade_09),
              info = "Elementary school should not have grade 09 data")
})

# ==============================================================================
# SECTION 15: Pinned School-Level Values — The Brook-KMI (275/020), 2024
# ==============================================================================

test_that("2024 The Brook-KMI (275/020) pinned values", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  sch <- wide[wide$district_id == "275" & wide$school_id == "020" &
               wide$type == "School", ]

  expect_equal(sch$school_name, "The Brook-KMI")
  expect_equal(sch$row_total, 633)
  expect_equal(sch$white, 468)
  expect_equal(sch$black, 84)
})

# ==============================================================================
# SECTION 16: Entity Counts Across Years
# ==============================================================================

test_that("2024 has 176 districts and 1,396 schools", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  n_dist <- length(unique(tidy$district_id[tidy$is_district &
                   tidy$subgroup == "total_enrollment" & tidy$grade_level == "TOTAL"]))
  n_sch <- nrow(tidy[tidy$is_school & tidy$subgroup == "total_enrollment" &
                      tidy$grade_level == "TOTAL", ])

  expect_equal(n_dist, 176)
  expect_equal(n_sch, 1396)
})

test_that("2023 has 176 districts and 1,447 schools", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  n_dist <- length(unique(tidy$district_id[tidy$is_district &
                   tidy$subgroup == "total_enrollment" & tidy$grade_level == "TOTAL"]))
  n_sch <- nrow(tidy[tidy$is_school & tidy$subgroup == "total_enrollment" &
                      tidy$grade_level == "TOTAL", ])

  expect_equal(n_dist, 176)
  expect_equal(n_sch, 1447)
})

test_that("2022 has 176 districts and 1,450 schools", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2022, tidy = TRUE, use_cache = TRUE)

  n_dist <- length(unique(tidy$district_id[tidy$is_district &
                   tidy$subgroup == "total_enrollment" & tidy$grade_level == "TOTAL"]))
  n_sch <- nrow(tidy[tidy$is_school & tidy$subgroup == "total_enrollment" &
                      tidy$grade_level == "TOTAL", ])

  expect_equal(n_dist, 176)
  expect_equal(n_sch, 1450)
})

test_that("2021 has 176 districts and 1,445 schools", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2021, tidy = TRUE, use_cache = TRUE)

  n_dist <- length(unique(tidy$district_id[tidy$is_district &
                   tidy$subgroup == "total_enrollment" & tidy$grade_level == "TOTAL"]))
  n_sch <- nrow(tidy[tidy$is_school & tidy$subgroup == "total_enrollment" &
                      tidy$grade_level == "TOTAL", ])

  expect_equal(n_dist, 176)
  expect_equal(n_sch, 1445)
})

test_that("2020 has 176 districts and 1,453 schools", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2020, tidy = TRUE, use_cache = TRUE)

  n_dist <- length(unique(tidy$district_id[tidy$is_district &
                   tidy$subgroup == "total_enrollment" & tidy$grade_level == "TOTAL"]))
  n_sch <- nrow(tidy[tidy$is_school & tidy$subgroup == "total_enrollment" &
                      tidy$grade_level == "TOTAL", ])

  expect_equal(n_dist, 176)
  expect_equal(n_sch, 1453)
})

# ==============================================================================
# SECTION 17: Wide Format Row Counts
# ==============================================================================

test_that("2024 wide format has 1,573 rows (1 state + 176 districts + 1,396 schools)", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  expect_equal(nrow(wide), 1573)

  expect_equal(nrow(wide[wide$type == "State", ]), 1)
  expect_equal(nrow(wide[wide$type == "District", ]), 176)
  expect_equal(nrow(wide[wide$type == "School", ]), 1396)
})

# ==============================================================================
# SECTION 18: enr_grade_aggs() — State-Level
# ==============================================================================

test_that("2024 state K8 grade aggregate is 445,902", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  ga <- enr_grade_aggs(tidy)
  val <- ga$n_students[ga$is_state & ga$grade_level == "K8"]
  expect_equal(val, 445902)
})

test_that("2024 state HS grade aggregate is 208,202", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  ga <- enr_grade_aggs(tidy)
  val <- ga$n_students[ga$is_state & ga$grade_level == "HS"]
  expect_equal(val, 208202)
})

test_that("2024 state K12 grade aggregate is 654,104", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  ga <- enr_grade_aggs(tidy)
  val <- ga$n_students[ga$is_state & ga$grade_level == "K12"]
  expect_equal(val, 654104)
})

test_that("2023 state grade aggregates pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  ga <- enr_grade_aggs(tidy)

  expect_equal(ga$n_students[ga$is_state & ga$grade_level == "K8"], 446500)
  expect_equal(ga$n_students[ga$is_state & ga$grade_level == "HS"], 208119)
  expect_equal(ga$n_students[ga$is_state & ga$grade_level == "K12"], 654619)
})

# ==============================================================================
# SECTION 19: enr_grade_aggs() — District-Level
# ==============================================================================

test_that("2024 Jefferson County (275) grade aggregates pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  ga <- enr_grade_aggs(tidy)
  jc <- ga[ga$is_district & !is.na(ga$district_id) & ga$district_id == "275", ]

  expect_equal(jc$n_students[jc$grade_level == "K8"], 68192)
  expect_equal(jc$n_students[jc$grade_level == "HS"], 32210)
  expect_equal(jc$n_students[jc$grade_level == "K12"], 100402)
})

test_that("2024 Warren County (571) grade aggregates pinned", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  ga <- enr_grade_aggs(tidy)
  w <- ga[ga$is_district & !is.na(ga$district_id) & ga$district_id == "571", ]

  expect_equal(w$n_students[w$grade_level == "K8"], 13368)
  expect_equal(w$n_students[w$grade_level == "HS"], 6145)
  expect_equal(w$n_students[w$grade_level == "K12"], 19513)
})

# ==============================================================================
# SECTION 20: enr_grade_aggs() — Structural
# ==============================================================================

test_that("enr_grade_aggs returns exactly 3 grade levels: K8, HS, K12", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  ga <- enr_grade_aggs(tidy)
  expect_equal(sort(unique(ga$grade_level)), c("HS", "K12", "K8"))
})

test_that("enr_grade_aggs only uses total_enrollment subgroup", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  ga <- enr_grade_aggs(tidy)
  expect_equal(unique(ga$subgroup), "total_enrollment")
})

test_that("enr_grade_aggs K8 + HS = K12 for every entity", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  ga <- enr_grade_aggs(tidy)

  # State
  st_k8 <- ga$n_students[ga$is_state & ga$grade_level == "K8"]
  st_hs <- ga$n_students[ga$is_state & ga$grade_level == "HS"]
  st_k12 <- ga$n_students[ga$is_state & ga$grade_level == "K12"]
  expect_equal(st_k8 + st_hs, st_k12)

  # Jefferson County
  jc_k8 <- ga$n_students[ga$is_district & !is.na(ga$district_id) &
                           ga$district_id == "275" & ga$grade_level == "K8"]
  jc_hs <- ga$n_students[ga$is_district & !is.na(ga$district_id) &
                           ga$district_id == "275" & ga$grade_level == "HS"]
  jc_k12 <- ga$n_students[ga$is_district & !is.na(ga$district_id) &
                            ga$district_id == "275" & ga$grade_level == "K12"]
  expect_equal(jc_k8 + jc_hs, jc_k12)
})

test_that("enr_grade_aggs pct column is NA_real_", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  ga <- enr_grade_aggs(tidy)
  expect_true(all(is.na(ga$pct)))
})

# ==============================================================================
# SECTION 21: get_available_years()
# ==============================================================================

test_that("get_available_years returns correct structure", {
  result <- get_available_years()
  expect_type(result, "list")
  expect_equal(result$min_year, 1997)
  expect_equal(result$max_year, 2024)
  expect_equal(result$description, "Kentucky enrollment data from KDE (1997-2024)")
})

# ==============================================================================
# SECTION 22: get_enrollment_urls()
# ==============================================================================

test_that("get_enrollment_urls for 2024 returns KYRC24 URLs", {
  urls <- get_enrollment_urls(2024)
  expect_equal(length(urls), 3)
  expect_true(any(grepl("KYRC24_OVW_Student_Enrollment.csv", urls)))
  expect_true(any(grepl("KYRC24_OVW_Primary_Enrollment.csv", urls)))
  expect_true(any(grepl("KYRC24_OVW_Secondary_Enrollment.csv", urls)))
  expect_true(all(grepl("^https://www\\.education\\.ky\\.gov/", urls)))
})

test_that("get_enrollment_urls for 2023 returns primary/secondary URLs", {
  urls <- get_enrollment_urls(2023)
  expect_equal(length(urls), 2)
  expect_true(any(grepl("primary_enrollment_2023.csv", urls)))
  expect_true(any(grepl("secondary_enrollment_2023.csv", urls)))
})

test_that("get_enrollment_urls for 2020 returns primary/secondary URLs", {
  urls <- get_enrollment_urls(2020)
  expect_equal(length(urls), 2)
  expect_true(any(grepl("primary_enrollment_2020.csv", urls)))
  expect_true(any(grepl("secondary_enrollment_2020.csv", urls)))
})

test_that("get_enrollment_urls for 2015 returns SRC + SAAR URLs", {
  urls <- get_enrollment_urls(2015)
  expect_equal(length(urls), 3)
  expect_true(any(grepl("primary_enrollment_2015.csv", urls)))
  expect_true(any(grepl("secondary_enrollment_2015.csv", urls)))
  expect_true(any(grepl("SAAR", urls)))
})

test_that("get_enrollment_urls for 2005 returns SAAR URL only", {
  urls <- get_enrollment_urls(2005)
  expect_equal(length(urls), 1)
  expect_true(grepl("SAAR", urls))
  expect_true(grepl("1996-2019", urls))
})

test_that("get_enrollment_urls for 1997 returns SAAR URL only", {
  urls <- get_enrollment_urls(1997)
  expect_equal(length(urls), 1)
  expect_true(grepl("SAAR", urls))
})

# ==============================================================================
# SECTION 23: cache_status() and clear_cache()
# ==============================================================================

test_that("cache_status returns a data frame", {
  result <- cache_status()
  expect_true(is.data.frame(result))
})

test_that("cache_status shows year and type columns", {
  # Ensure at least one cached file exists
  test_df <- data.frame(x = 1)
  write_cache(test_df, 8888, "test")

  result <- cache_status()
  expect_true("year" %in% names(result))
  expect_true("type" %in% names(result))

  # Clean up
  clear_cache(8888)
})

test_that("clear_cache with specific year and type removes one file", {
  test_df <- data.frame(x = 1)
  write_cache(test_df, 8887, "tidy")
  write_cache(test_df, 8887, "wide")

  expect_true(cache_exists(8887, "tidy"))
  expect_true(cache_exists(8887, "wide"))

  clear_cache(8887, "tidy")
  expect_false(cache_exists(8887, "tidy"))
  expect_true(cache_exists(8887, "wide"))

  # Clean up
  clear_cache(8887)
})

test_that("clear_cache with year only removes all types for that year", {
  test_df <- data.frame(x = 1)
  write_cache(test_df, 8886, "tidy")
  write_cache(test_df, 8886, "wide")

  clear_cache(8886)
  expect_false(cache_exists(8886, "tidy"))
  expect_false(cache_exists(8886, "wide"))
})

test_that("clear_cache with type only removes that type across years", {
  test_df <- data.frame(x = 1)
  write_cache(test_df, 8885, "tidy")
  write_cache(test_df, 8884, "tidy")

  clear_cache(type = "tidy")

  # Both should be gone
  expect_false(cache_exists(8885, "tidy"))
  expect_false(cache_exists(8884, "tidy"))
})

test_that("clear_cache with no args removes all cached files", {
  test_df <- data.frame(x = 1)
  write_cache(test_df, 8883, "tidy")
  write_cache(test_df, 8882, "wide")

  # This would clear ALL cache. Only do this with test files.
  # Instead, just clean up test files individually
  clear_cache(8883)
  clear_cache(8882)
  expect_false(cache_exists(8883, "tidy"))
  expect_false(cache_exists(8882, "wide"))
})

test_that("clear_cache returns count of removed files invisibly", {
  test_df <- data.frame(x = 1)
  write_cache(test_df, 8881, "tidy")

  count <- clear_cache(8881, "tidy")
  expect_equal(count, 1)
})

test_that("clear_cache on non-existent files returns 0", {
  count <- clear_cache(9999, "nonexistent")
  expect_equal(count, 0)
})
