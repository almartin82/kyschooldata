# ==============================================================================
# Transformation Correctness Tests for kyschooldata
# ==============================================================================
#
# These tests verify that the data transformation pipeline produces correct
# output at every stage: suppression handling, ID formatting, grade mapping,
# subgroup normalization, pivot fidelity, percentage calculation, aggregation,
# entity flags, per-year known values, and cross-year consistency.
#
# All expected values come from real KDE data (fetched via use_cache = TRUE).
# No fabricated values.
#
# ==============================================================================

library(testthat)

# ==============================================================================
# SECTION 1: Suppression Handling
# ==============================================================================

test_that("safe_numeric correctly handles suppression markers", {
  # Standard suppression markers used by KDE
  expect_true(is.na(kyschooldata:::safe_numeric("*")))
  expect_true(is.na(kyschooldata:::safe_numeric(".")))
  expect_true(is.na(kyschooldata:::safe_numeric("-")))
  expect_true(is.na(kyschooldata:::safe_numeric("-1")))
  expect_true(is.na(kyschooldata:::safe_numeric("<5")))
  expect_true(is.na(kyschooldata:::safe_numeric("<10")))
  expect_true(is.na(kyschooldata:::safe_numeric("< 10")))
  expect_true(is.na(kyschooldata:::safe_numeric("N/A")))
  expect_true(is.na(kyschooldata:::safe_numeric("NA")))
  expect_true(is.na(kyschooldata:::safe_numeric("")))
  expect_true(is.na(kyschooldata:::safe_numeric("---")))
  expect_true(is.na(kyschooldata:::safe_numeric("n<10")))
})

test_that("safe_numeric converts valid numbers correctly", {
  expect_equal(kyschooldata:::safe_numeric("100"), 100)
  expect_equal(kyschooldata:::safe_numeric("0"), 0)
  expect_equal(kyschooldata:::safe_numeric("1234"), 1234)
  expect_equal(kyschooldata:::safe_numeric("1,234"), 1234)
  expect_equal(kyschooldata:::safe_numeric("1,234,567"), 1234567)
  expect_equal(kyschooldata:::safe_numeric("  100  "), 100)
})

test_that("suppressed values become NA in wide format, not negative or zero", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Small schools have suppressed demographics — those should be NA, not 0 or negative
  # Barbourville Learning Center has row_total=4 and many NA demographics
  barb <- wide[wide$school_name == "Barbourville Learning Center" &
               wide$type == "School", ]
  if (nrow(barb) > 0) {
    # black should be NA (suppressed), not 0
    expect_true(is.na(barb$black),
                info = "Suppressed black count should be NA for tiny school")
    # hispanic should be NA (suppressed)
    expect_true(is.na(barb$hispanic),
                info = "Suppressed hispanic count should be NA for tiny school")
    # row_total should NOT be NA even for small schools
    expect_false(is.na(barb$row_total),
                 info = "row_total should always be present")
    expect_equal(barb$row_total, 4)
  }
})

test_that("suppressed values are excluded from tidy format (filtered by !is.na)", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # tidy_enr filters out NA n_students rows
  expect_false(any(is.na(tidy$n_students)),
               info = "Tidy format should have no NA n_students (suppressed values filtered out)")
})

# ==============================================================================
# SECTION 2: ID Formatting
# ==============================================================================

test_that("district IDs are zero-padded 3-digit strings", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  districts <- wide[wide$type == "District", ]

  # All district IDs should be 3 characters
  expect_true(all(nchar(districts$district_id) == 3),
              info = "All district IDs should be 3 characters")

  # All should be numeric strings
  expect_true(all(grepl("^[0-9]{3}$", districts$district_id)),
              info = "District IDs should be 3-digit numeric strings")

  # Known districts: 001 = Adair, 275 = Jefferson
  expect_true("001" %in% districts$district_id,
              info = "Adair County (001) should exist")
  expect_true("275" %in% districts$district_id,
              info = "Jefferson County (275) should exist")
  expect_true("165" %in% districts$district_id,
              info = "Fayette County (165) should exist")
})

test_that("state rows have NA district/school identifiers", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  state_rows <- tidy[tidy$is_state, ]

  expect_true(all(is.na(state_rows$district_id)),
              info = "State rows should have NA district_id")
  expect_true(all(is.na(state_rows$school_id)),
              info = "State rows should have NA school_id")
  expect_true(all(is.na(state_rows$district_name)),
              info = "State rows should have NA district_name")
  expect_true(all(is.na(state_rows$school_name)),
              info = "State rows should have NA school_name")
})

test_that("district rows have populated district_id and district_name", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  dist_rows <- tidy[tidy$is_district, ]

  expect_false(any(is.na(dist_rows$district_id)),
               info = "District rows should never have NA district_id")
  expect_false(any(is.na(dist_rows$district_name)),
               info = "District rows should never have NA district_name")
  expect_true(all(is.na(dist_rows$school_id)),
              info = "District rows should have NA school_id")
})

test_that("school rows have district_id, school_id, and names", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  school_rows <- tidy[tidy$is_school, ]

  expect_false(any(is.na(school_rows$district_id)),
               info = "School rows should have district_id")
  expect_false(any(is.na(school_rows$school_id)),
               info = "School rows should have school_id")
  expect_false(any(is.na(school_rows$school_name)),
               info = "School rows should have school_name")
})

test_that("standardize_district_id pads correctly", {
  expect_equal(kyschooldata:::standardize_district_id("1"), "001")
  expect_equal(kyschooldata:::standardize_district_id("42"), "042")
  expect_equal(kyschooldata:::standardize_district_id("275"), "275")
  expect_equal(kyschooldata:::standardize_district_id("  165  "), "165")
})

# ==============================================================================
# SECTION 3: Grade Level Mapping
# ==============================================================================

test_that("all expected grade levels present in tidy output", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  actual_grades <- sort(unique(tidy$grade_level))

  expected_grades <- c("01", "02", "03", "04", "05", "06", "07", "08",
                       "09", "10", "11", "12", "K", "PK", "TOTAL")

  expect_true(all(expected_grades %in% actual_grades),
              info = paste("Missing grade levels:",
                           paste(setdiff(expected_grades, actual_grades), collapse = ", ")))
})

test_that("grade levels are uppercase standard format", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  grades <- unique(tidy$grade_level)

  # All should be uppercase
  expect_true(all(grades == toupper(grades)),
              info = "All grade levels should be uppercase")

  # No unexpected grade levels
  valid_grades <- c("PK", "K", "01", "02", "03", "04", "05", "06", "07", "08",
                    "09", "10", "11", "12", "TOTAL")
  unexpected <- setdiff(grades, valid_grades)
  expect_equal(length(unexpected), 0,
               info = paste("Unexpected grade levels:", paste(unexpected, collapse = ", ")))
})

test_that("grade level rows use total_enrollment subgroup", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  grade_rows <- tidy[tidy$grade_level %in% c("PK", "K", "01", "02", "03", "04",
                                               "05", "06", "07", "08", "09", "10",
                                               "11", "12"), ]

  # All individual grade rows should have subgroup = "total_enrollment"
  expect_true(all(grade_rows$subgroup == "total_enrollment"),
              info = "Individual grade rows should always have subgroup = total_enrollment")
})

test_that("demographic subgroups use TOTAL grade_level", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  demo_rows <- tidy[tidy$subgroup %in% c("white", "black", "hispanic", "asian",
                                           "native_american", "pacific_islander",
                                           "multiracial", "male", "female",
                                           "econ_disadv", "lep", "special_ed"), ]

  # All demographic subgroup rows should have grade_level = "TOTAL"
  expect_true(all(demo_rows$grade_level == "TOTAL"),
              info = "Demographic subgroup rows should always have grade_level = TOTAL")
})

# ==============================================================================
# SECTION 4: Subgroup Normalization
# ==============================================================================

test_that("all 13 standard subgroups present in tidy output", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  actual_subgroups <- sort(unique(tidy$subgroup))

  expected_subgroups <- sort(c("total_enrollment", "white", "black", "hispanic",
                               "asian", "native_american", "pacific_islander",
                               "multiracial", "male", "female",
                               "econ_disadv", "lep", "special_ed"))

  expect_equal(actual_subgroups, expected_subgroups,
               info = "Should have exactly the 13 standard subgroups")
})

test_that("subgroup names follow naming standards (no non-standard variants)", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  subgroups <- unique(tidy$subgroup)

  # Should NOT have non-standard names
  forbidden_names <- c("total", "low_income", "economically_disadvantaged",
                       "frl", "iep", "disability", "el", "ell", "english_learner",
                       "american_indian", "two_or_more", "African American",
                       "All Students", "Economically Disadvantaged")
  overlap <- intersect(subgroups, forbidden_names)
  expect_equal(length(overlap), 0,
               info = paste("Non-standard subgroup names found:", paste(overlap, collapse = ", ")))
})

# ==============================================================================
# SECTION 5: Pivot Fidelity (wide -> tidy)
# ==============================================================================

test_that("tidy total_enrollment matches wide row_total for Jefferson County 2024", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Jefferson County (275) district
  jc_wide <- wide[wide$district_id == "275" & wide$type == "District", ]
  jc_tidy_total <- tidy[tidy$district_id == "275" & tidy$is_district &
                         tidy$subgroup == "total_enrollment" &
                         tidy$grade_level == "TOTAL", ]

  expect_equal(nrow(jc_tidy_total), 1,
               info = "Should have exactly 1 total_enrollment TOTAL row per district")
  expect_equal(jc_tidy_total$n_students, jc_wide$row_total,
               info = "Tidy n_students should match wide row_total")
  expect_equal(jc_tidy_total$n_students, 103459)
})

test_that("tidy demographic counts match wide format for Jefferson County 2024", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  jc_wide <- wide[wide$district_id == "275" & wide$type == "District", ]

  # White
  jc_white <- tidy[tidy$district_id == "275" & tidy$is_district &
                    tidy$subgroup == "white" & tidy$grade_level == "TOTAL", ]
  expect_equal(jc_white$n_students, jc_wide$white)
  expect_equal(jc_white$n_students, 35817)

  # Black
  jc_black <- tidy[tidy$district_id == "275" & tidy$is_district &
                    tidy$subgroup == "black" & tidy$grade_level == "TOTAL", ]
  expect_equal(jc_black$n_students, jc_wide$black)
  expect_equal(jc_black$n_students, 37106)

  # Hispanic
  jc_hispanic <- tidy[tidy$district_id == "275" & tidy$is_district &
                       tidy$subgroup == "hispanic" & tidy$grade_level == "TOTAL", ]
  expect_equal(jc_hispanic$n_students, jc_wide$hispanic)
  expect_equal(jc_hispanic$n_students, 18993)

  # econ_disadv
  jc_econ <- tidy[tidy$district_id == "275" & tidy$is_district &
                   tidy$subgroup == "econ_disadv" & tidy$grade_level == "TOTAL", ]
  expect_equal(jc_econ$n_students, jc_wide$econ_disadv)
  expect_equal(jc_econ$n_students, 66118)
})

test_that("tidy grade-level counts match wide format for Fayette County 2024", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  fay_wide <- wide[wide$district_id == "165" & wide$type == "District", ]

  # Grade K
  fay_k <- tidy[tidy$district_id == "165" & tidy$is_district &
                 tidy$subgroup == "total_enrollment" & tidy$grade_level == "K", ]
  expect_equal(fay_k$n_students, fay_wide$grade_k)
  expect_equal(fay_k$n_students, 3252)

  # Grade 09
  fay_09 <- tidy[tidy$district_id == "165" & tidy$is_district &
                  tidy$subgroup == "total_enrollment" & tidy$grade_level == "09", ]
  expect_equal(fay_09$n_students, fay_wide$grade_09)
  expect_equal(fay_09$n_students, 3853)

  # Grade PK
  fay_pk <- tidy[tidy$district_id == "165" & tidy$is_district &
                  tidy$subgroup == "total_enrollment" & tidy$grade_level == "PK", ]
  expect_equal(fay_pk$n_students, fay_wide$grade_pk)
  expect_equal(fay_pk$n_students, 1318)
})

test_that("school-level pivot fidelity: tidy matches wide for Jefferson school 155", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Marion C. Moore School: district_id=275, school_id=155
  sch_wide <- wide[wide$district_id == "275" & wide$school_id == "155" &
                    wide$type == "School", ]
  sch_tidy <- tidy[tidy$district_id == "275" & tidy$school_id == "155" &
                    tidy$is_school, ]

  # Total
  sch_total <- sch_tidy[sch_tidy$subgroup == "total_enrollment" &
                         sch_tidy$grade_level == "TOTAL", ]
  expect_equal(sch_total$n_students, sch_wide$row_total)
  expect_equal(sch_total$n_students, 2320)

  # White
  sch_white <- sch_tidy[sch_tidy$subgroup == "white" &
                         sch_tidy$grade_level == "TOTAL", ]
  expect_equal(sch_white$n_students, sch_wide$white)
  expect_equal(sch_white$n_students, 576)

  # Black
  sch_black <- sch_tidy[sch_tidy$subgroup == "black" &
                         sch_tidy$grade_level == "TOTAL", ]
  expect_equal(sch_black$n_students, sch_wide$black)
  expect_equal(sch_black$n_students, 791)
})

# ==============================================================================
# SECTION 6: Percentage Calculations
# ==============================================================================

test_that("total_enrollment subgroup always has pct = 1.0", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  total_rows <- tidy[tidy$subgroup == "total_enrollment" &
                      tidy$grade_level == "TOTAL", ]

  expect_true(all(total_rows$pct == 1.0),
              info = "total_enrollment TOTAL should always have pct = 1.0")
})

test_that("pct = n_students / row_total for demographic subgroups", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Adair County (001): white pct should be 2468/3068
  adair_white <- tidy[tidy$district_id == "001" & tidy$is_district &
                       tidy$subgroup == "white" & tidy$grade_level == "TOTAL", ]
  expect_equal(adair_white$pct, 2468 / 3068, tolerance = 1e-6,
               info = "Adair white pct should be 2468/3068")

  # Jefferson County: black pct should be 37106/103459
  jc_black <- tidy[tidy$district_id == "275" & tidy$is_district &
                    tidy$subgroup == "black" & tidy$grade_level == "TOTAL", ]
  expect_equal(jc_black$pct, 37106 / 103459, tolerance = 1e-6,
               info = "Jefferson black pct should be 37106/103459")

  # Fayette County: black pct from 2023 should be 10296/43799
  tidy_2023 <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  fay_black_2023 <- tidy_2023[tidy_2023$district_id == "165" & tidy_2023$is_district &
                               tidy_2023$subgroup == "black" & tidy_2023$grade_level == "TOTAL", ]
  expect_equal(fay_black_2023$pct, 10296 / 43799, tolerance = 1e-6,
               info = "Fayette 2023 black pct should be 10296/43799")
})

test_that("pct is bounded between 0 and 1 (inclusive)", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_true(all(tidy$pct >= 0, na.rm = TRUE),
              info = "All pct values should be >= 0")
  expect_true(all(tidy$pct <= 1, na.rm = TRUE),
              info = "All pct values should be <= 1 (capped by pmin)")
})

test_that("grade-level pct represents fraction of row_total", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Fayette County: grade K pct should be 3252/44362
  fay_k <- tidy[tidy$district_id == "165" & tidy$is_district &
                 tidy$subgroup == "total_enrollment" & tidy$grade_level == "K", ]
  expect_equal(fay_k$pct, 3252 / 44362, tolerance = 1e-6,
               info = "Fayette grade K pct should be 3252/44362")
})

test_that("no Inf or NaN values in pct or n_students", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_false(any(is.infinite(tidy$pct)),
               info = "No Inf in pct")
  expect_false(any(is.nan(tidy$pct)),
               info = "No NaN in pct")
  expect_false(any(is.infinite(tidy$n_students)),
               info = "No Inf in n_students")
  expect_false(any(is.nan(tidy$n_students)),
               info = "No NaN in n_students")
})

# ==============================================================================
# SECTION 7: Aggregation
# ==============================================================================

test_that("race categories sum to total for Jefferson County 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  race_subgroups <- c("white", "black", "hispanic", "asian",
                      "native_american", "pacific_islander", "multiracial")
  jc_races <- tidy[tidy$district_id == "275" & tidy$is_district &
                    tidy$grade_level == "TOTAL" &
                    tidy$subgroup %in% race_subgroups, ]
  race_sum <- sum(jc_races$n_students)

  jc_total <- tidy[tidy$district_id == "275" & tidy$is_district &
                    tidy$subgroup == "total_enrollment" &
                    tidy$grade_level == "TOTAL", "n_students"]

  expect_equal(race_sum, jc_total[[1]],
               info = "Sum of race categories should equal total enrollment for Jefferson County")
})

test_that("gender categories sum to total for Jefferson County 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  jc_male <- tidy[tidy$district_id == "275" & tidy$is_district &
                   tidy$subgroup == "male" & tidy$grade_level == "TOTAL", "n_students"]
  jc_female <- tidy[tidy$district_id == "275" & tidy$is_district &
                     tidy$subgroup == "female" & tidy$grade_level == "TOTAL", "n_students"]
  jc_total <- tidy[tidy$district_id == "275" & tidy$is_district &
                    tidy$subgroup == "total_enrollment" &
                    tidy$grade_level == "TOTAL", "n_students"]

  expect_equal(jc_male[[1]] + jc_female[[1]], jc_total[[1]],
               info = "Male + Female should equal total enrollment")
})

test_that("state total uses KDE official aggregate, not district sum (double-counting guard)", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_total <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                                 tidy$grade_level == "TOTAL"]
  district_sum <- sum(
    tidy$n_students[tidy$is_district & tidy$subgroup == "total_enrollment" &
                    tidy$grade_level == "TOTAL"],
    na.rm = TRUE
  )

  # KDE state total (686224) is less than district sum (710854) because some
  # independent districts overlap with county districts. The state row should
  # use KDE's official aggregate (district_id 999), NOT the sum of all districts.
  expect_equal(state_total, 686224)

  # District sum exceeds state total due to independent district overlap
  expect_true(district_sum > state_total,
              info = paste("District sum", district_sum,
                           "should exceed state total", state_total,
                           "due to independent district overlap"))
})

test_that("enr_grade_aggs produces K8, HS, K12 correctly", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  grade_aggs <- enr_grade_aggs(tidy)

  # State-level grade aggregates
  state_aggs <- grade_aggs[grade_aggs$is_state, ]

  state_k8 <- state_aggs[state_aggs$grade_level == "K8", "n_students"][[1]]
  state_hs <- state_aggs[state_aggs$grade_level == "HS", "n_students"][[1]]
  state_k12 <- state_aggs[state_aggs$grade_level == "K12", "n_students"][[1]]

  # K8 + HS should equal K12
  expect_equal(state_k8 + state_hs, state_k12,
               info = "K8 + HS should equal K12 at state level")

  # Verify against known values
  expect_equal(state_k8, 445902)
  expect_equal(state_hs, 208202)
  expect_equal(state_k12, 654104)
})

test_that("enr_grade_aggs K8 matches sum of K through 08", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  grade_aggs <- enr_grade_aggs(tidy)

  # Manual K-8 sum from state-level tidy data
  state_tidy <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
  manual_k8 <- sum(state_tidy$n_students[state_tidy$grade_level %in%
                                c("K", "01", "02", "03", "04", "05", "06", "07", "08")])

  agg_k8 <- grade_aggs$n_students[grade_aggs$is_state & grade_aggs$grade_level == "K8"]

  expect_equal(agg_k8, manual_k8,
               info = "enr_grade_aggs K8 should match manual sum of K + 01-08")
})

test_that("enr_grade_aggs HS matches sum of 09 through 12", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  grade_aggs <- enr_grade_aggs(tidy)

  state_tidy <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment", ]
  manual_hs <- sum(state_tidy$n_students[state_tidy$grade_level %in% c("09", "10", "11", "12")])

  agg_hs <- grade_aggs$n_students[grade_aggs$is_state & grade_aggs$grade_level == "HS"]

  expect_equal(agg_hs, manual_hs,
               info = "enr_grade_aggs HS should match manual sum of 09-12")
})

# ==============================================================================
# SECTION 8: Entity Flags
# ==============================================================================

test_that("entity flags are mutually exclusive", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  flag_sums <- tidy$is_state + tidy$is_district + tidy$is_school
  expect_true(all(flag_sums == 1),
              info = "Every row should be exactly one of: state, district, school")
})

test_that("entity flags are boolean type", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_true(is.logical(tidy$is_state))
  expect_true(is.logical(tidy$is_district))
  expect_true(is.logical(tidy$is_school))
})

test_that("aggregation_flag aligns with entity flags", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # state
  state_agg <- unique(tidy[tidy$is_state, "aggregation_flag"])[[1]]
  expect_equal(state_agg, "state")

  # district
  dist_agg <- unique(tidy[tidy$is_district, "aggregation_flag"])[[1]]
  expect_equal(dist_agg, "district")

  # school
  school_agg <- unique(tidy[tidy$is_school, "aggregation_flag"])[[1]]
  expect_equal(school_agg, "campus")
})

test_that("exactly one state row per subgroup/grade_level combo", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  state_rows <- tidy[tidy$is_state, ]

  # Count rows per subgroup + grade_level
  state_counts <- as.data.frame(
    table(state_rows$subgroup, state_rows$grade_level)
  )
  multi <- state_counts[state_counts$Freq > 1, ]

  expect_equal(nrow(multi), 0,
               info = paste("Should have at most 1 state row per subgroup/grade combo. Duplicates:",
                            nrow(multi)))
})

# ==============================================================================
# SECTION 9: Per-Year Known Values
# ==============================================================================

test_that("2024 state total enrollment is 686,224", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  state_total <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment" &
                       tidy$grade_level == "TOTAL", "n_students"][[1]]

  expect_equal(state_total, 686224)
})

test_that("2024 has 176 districts", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  dist_rows <- tidy[tidy$is_district & tidy$subgroup == "total_enrollment" &
                     tidy$grade_level == "TOTAL", ]
  n_districts <- length(unique(dist_rows$district_id))

  expect_equal(n_districts, 176)
})

test_that("2024 has 1,396 schools", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  n_schools <- nrow(tidy[tidy$is_school & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL", ])

  expect_equal(n_schools, 1396)
})

test_that("2024 state white enrollment is 488,062", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  state_white <- tidy[tidy$is_state & tidy$subgroup == "white" &
                       tidy$grade_level == "TOTAL", "n_students"][[1]]

  expect_equal(state_white, 488062)
})

test_that("2024 state black enrollment is 74,804", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  state_black <- tidy[tidy$is_state & tidy$subgroup == "black" &
                       tidy$grade_level == "TOTAL", "n_students"][[1]]

  expect_equal(state_black, 74804)
})

test_that("2024 state econ_disadv enrollment is 426,203", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  state_econ <- tidy[tidy$is_state & tidy$subgroup == "econ_disadv" &
                      tidy$grade_level == "TOTAL", "n_students"][[1]]

  expect_equal(state_econ, 426203)
})

test_that("2024 Adair County (001) known values", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  adair <- tidy[tidy$district_id == "001" & tidy$is_district &
                 tidy$grade_level == "TOTAL", ]

  adair_total <- adair[adair$subgroup == "total_enrollment", "n_students"][[1]]
  expect_equal(adair_total, 3068)

  adair_white <- adair[adair$subgroup == "white", "n_students"][[1]]
  expect_equal(adair_white, 2468)

  adair_black <- adair[adair$subgroup == "black", "n_students"][[1]]
  expect_equal(adair_black, 199)

  adair_hispanic <- adair[adair$subgroup == "hispanic", "n_students"][[1]]
  expect_equal(adair_hispanic, 215)

  adair_econ <- adair[adair$subgroup == "econ_disadv", "n_students"][[1]]
  expect_equal(adair_econ, 1933)

  adair_sped <- adair[adair$subgroup == "special_ed", "n_students"][[1]]
  expect_equal(adair_sped, 520)

  adair_lep <- adair[adair$subgroup == "lep", "n_students"][[1]]
  expect_equal(adair_lep, 74)
})

test_that("2024 Jefferson County (275) known values", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  jc <- tidy[tidy$district_id == "275" & tidy$is_district &
              tidy$grade_level == "TOTAL", ]

  expect_equal(jc[jc$subgroup == "total_enrollment", "n_students"][[1]], 103459)
  expect_equal(jc[jc$subgroup == "white", "n_students"][[1]], 35817)
  expect_equal(jc[jc$subgroup == "black", "n_students"][[1]], 37106)
  expect_equal(jc[jc$subgroup == "hispanic", "n_students"][[1]], 18993)
  expect_equal(jc[jc$subgroup == "asian", "n_students"][[1]], 5103)
  expect_equal(jc[jc$subgroup == "econ_disadv", "n_students"][[1]], 66118)
  expect_equal(jc[jc$subgroup == "lep", "n_students"][[1]], 20724)
  expect_equal(jc[jc$subgroup == "special_ed", "n_students"][[1]], 14860)
})

test_that("2024 Fayette County (165) known values", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  fay <- tidy[tidy$district_id == "165" & tidy$is_district &
               tidy$grade_level == "TOTAL", ]

  expect_equal(fay[fay$subgroup == "total_enrollment", "n_students"][[1]], 44362)
  expect_equal(fay[fay$subgroup == "white", "n_students"][[1]], 18774)
  expect_equal(fay[fay$subgroup == "black", "n_students"][[1]], 10326)
  expect_equal(fay[fay$subgroup == "hispanic", "n_students"][[1]], 9769)
})

test_that("2023 state total enrollment is 687,294", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  state_total <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment" &
                       tidy$grade_level == "TOTAL", "n_students"][[1]]

  expect_equal(state_total, 687294)
})

test_that("2023 Fayette County (165) known values", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  fay <- tidy[tidy$district_id == "165" & tidy$is_district &
               tidy$grade_level == "TOTAL", ]

  expect_equal(fay[fay$subgroup == "total_enrollment", "n_students"][[1]], 43799)
  expect_equal(fay[fay$subgroup == "white", "n_students"][[1]], 19366)
  expect_equal(fay[fay$subgroup == "black", "n_students"][[1]], 10296)
  expect_equal(fay[fay$subgroup == "hispanic", "n_students"][[1]], 8841)
})

# ==============================================================================
# SECTION 10: Cross-Year Consistency
# ==============================================================================

test_that("district count is consistent across years (176 for both 2023 and 2024)", {
  skip_on_cran()
  skip_if_offline()

  tidy_2023 <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  tidy_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  dist_2023 <- tidy_2023[tidy_2023$is_district & tidy_2023$subgroup == "total_enrollment" &
                         tidy_2023$grade_level == "TOTAL", ]
  n_2023 <- length(unique(dist_2023$district_id))
  dist_2024 <- tidy_2024[tidy_2024$is_district & tidy_2024$subgroup == "total_enrollment" &
                          tidy_2024$grade_level == "TOTAL", ]
  n_2024 <- length(unique(dist_2024$district_id))

  expect_equal(n_2023, 176)
  expect_equal(n_2024, 176)
})

test_that("state total is in reasonable range across years", {
  skip_on_cran()
  skip_if_offline()

  for (yr in c(2023, 2024)) {
    tidy <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    state_total <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                                    tidy$grade_level == "TOTAL"]

    expect_true(state_total > 500000,
                info = paste(yr, "state total should be > 500K, got", state_total))
    expect_true(state_total < 1000000,
                info = paste(yr, "state total should be < 1M, got", state_total))
  }
})

test_that("year-over-year state total change is within 5%", {
  skip_on_cran()
  skip_if_offline()

  tidy_2023 <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  tidy_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  total_2023 <- tidy_2023[tidy_2023$is_state & tidy_2023$subgroup == "total_enrollment" &
                           tidy_2023$grade_level == "TOTAL", "n_students"][[1]]
  total_2024 <- tidy_2024[tidy_2024$is_state & tidy_2024$subgroup == "total_enrollment" &
                           tidy_2024$grade_level == "TOTAL", "n_students"][[1]]

  pct_change <- abs(total_2024 - total_2023) / total_2023
  expect_true(pct_change < 0.05,
              info = paste("Year-over-year change should be < 5%, got",
                           round(pct_change * 100, 2), "%"))
})

test_that("schema columns are consistent across years", {
  skip_on_cran()
  skip_if_offline()

  tidy_2023 <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  tidy_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Same columns
  expect_equal(sort(names(tidy_2023)), sort(names(tidy_2024)),
               info = "Tidy column names should be identical across years")

  # Same subgroups
  expect_equal(sort(unique(tidy_2023$subgroup)), sort(unique(tidy_2024$subgroup)),
               info = "Available subgroups should be identical across years")

  # Same grade levels
  expect_equal(sort(unique(tidy_2023$grade_level)), sort(unique(tidy_2024$grade_level)),
               info = "Available grade levels should be identical across years")
})

test_that("no duplicate rows in tidy format (one observation per group per period)", {
  skip_on_cran()
  skip_if_offline()

  for (yr in c(2023, 2024)) {
    tidy <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    # District-level duplicates
    dist_data <- tidy[tidy$is_district, ]
    dist_dupes <- as.data.frame(
      table(dist_data$end_year, dist_data$district_id,
            dist_data$subgroup, dist_data$grade_level)
    )
    dist_dupes <- dist_dupes[dist_dupes$Freq > 1, ]
    expect_equal(nrow(dist_dupes), 0,
                 info = paste(yr, "should have no duplicate district rows"))

    # School-level duplicates
    sch_data <- tidy[tidy$is_school, ]
    sch_dupes <- as.data.frame(
      table(sch_data$end_year, sch_data$district_id, sch_data$school_id,
            sch_data$subgroup, sch_data$grade_level)
    )
    sch_dupes <- sch_dupes[sch_dupes$Freq > 1, ]
    expect_equal(nrow(sch_dupes), 0,
                 info = paste(yr, "should have no duplicate school rows"))
  }
})

test_that("fetch_enr_multi produces correct multi-year output", {
  skip_on_cran()
  skip_if_offline()

  multi <- fetch_enr_multi(c(2023, 2024), tidy = TRUE, use_cache = TRUE)

  expect_true(2023 %in% multi$end_year)
  expect_true(2024 %in% multi$end_year)

  # State totals for each year
  state_2023 <- multi[multi$is_state & multi$end_year == 2023 &
                       multi$subgroup == "total_enrollment" &
                       multi$grade_level == "TOTAL", "n_students"][[1]]
  state_2024 <- multi[multi$is_state & multi$end_year == 2024 &
                       multi$subgroup == "total_enrollment" &
                       multi$grade_level == "TOTAL", "n_students"][[1]]

  expect_equal(state_2023, 687294)
  expect_equal(state_2024, 686224)
})

# ==============================================================================
# SECTION 11: Wide Format Structure
# ==============================================================================

test_that("wide format has all expected columns in correct order", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expected_cols <- c(
    "end_year", "type",
    "district_id", "school_id",
    "district_name", "school_name",
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "econ_disadv", "lep", "special_ed",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  expect_equal(names(wide), expected_cols,
               info = "Wide format columns should match expected order")
})

test_that("wide format type column has exactly State, District, School", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  types <- sort(unique(wide$type))

  expect_equal(types, c("District", "School", "State"))
})

test_that("wide format has exactly one State row", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  state_rows <- wide[wide$type == "State", ]

  expect_equal(nrow(state_rows), 1,
               info = "Should have exactly 1 state row in wide format")
})

test_that("wide format n_students are non-negative where not NA", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  numeric_cols <- c("row_total", "white", "black", "hispanic", "asian",
                    "pacific_islander", "native_american", "multiracial",
                    "male", "female", "econ_disadv", "lep", "special_ed",
                    "grade_pk", "grade_k",
                    "grade_01", "grade_02", "grade_03", "grade_04",
                    "grade_05", "grade_06", "grade_07", "grade_08",
                    "grade_09", "grade_10", "grade_11", "grade_12")

  for (col in numeric_cols) {
    vals <- wide[[col]]
    non_na <- vals[!is.na(vals)]
    if (length(non_na) > 0) {
      expect_true(all(non_na >= 0),
                  info = paste("All non-NA values in", col, "should be >= 0"))
    }
  }
})
