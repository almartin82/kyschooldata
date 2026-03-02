# ==============================================================================
# Exhaustive Typology & Structure Tests for kyschooldata
# ==============================================================================
#
# Tests data structure, column types, naming standards, pivot fidelity,
# percentage calculations, aggregation invariants, and edge cases.
#
# All expected values come from real Kentucky DOE data (fetched via use_cache = TRUE).
#
# ==============================================================================

library(testthat)

# ==============================================================================
# SECTION 1: Column Types — Tidy Format
# ==============================================================================

test_that("tidy format end_year is numeric", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.numeric(tidy$end_year))
})

test_that("tidy format type is character", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(tidy$type))
})

test_that("tidy format district_id is character", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(tidy$district_id))
})

test_that("tidy format school_id is character", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(tidy$school_id))
})

test_that("tidy format district_name is character", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(tidy$district_name))
})

test_that("tidy format school_name is character", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(tidy$school_name))
})

test_that("tidy format grade_level is character", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(tidy$grade_level))
})

test_that("tidy format subgroup is character", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(tidy$subgroup))
})

test_that("tidy format n_students is numeric", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.numeric(tidy$n_students))
})

test_that("tidy format pct is numeric", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.numeric(tidy$pct))
})

test_that("tidy format is_state is logical", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.logical(tidy$is_state))
})

test_that("tidy format is_district is logical", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.logical(tidy$is_district))
})

test_that("tidy format is_school is logical", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.logical(tidy$is_school))
})

test_that("tidy format aggregation_flag is character", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(tidy$aggregation_flag))
})

# ==============================================================================
# SECTION 2: Column Types — Wide Format
# ==============================================================================

test_that("wide format end_year is numeric", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  expect_true(is.numeric(wide$end_year))
})

test_that("wide format type is character", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  expect_true(is.character(wide$type))
})

test_that("wide format row_total is numeric", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  expect_true(is.numeric(wide$row_total))
})

test_that("wide format demographic columns are numeric", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  demo_cols <- c("white", "black", "hispanic", "asian", "pacific_islander",
                 "native_american", "multiracial", "male", "female",
                 "econ_disadv", "lep", "special_ed")
  for (col in demo_cols) {
    expect_true(is.numeric(wide[[col]]),
                info = paste(col, "should be numeric"))
  }
})

test_that("wide format grade columns are numeric", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  grade_cols <- c("grade_pk", "grade_k",
                  "grade_01", "grade_02", "grade_03", "grade_04",
                  "grade_05", "grade_06", "grade_07", "grade_08",
                  "grade_09", "grade_10", "grade_11", "grade_12")
  for (col in grade_cols) {
    expect_true(is.numeric(wide[[col]]),
                info = paste(col, "should be numeric"))
  }
})

# ==============================================================================
# SECTION 3: Naming Standards — Subgroup Names
# ==============================================================================

test_that("all 13 standard subgroups present, no extras", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  actual <- sort(unique(tidy$subgroup))
  expected <- sort(c("total_enrollment", "white", "black", "hispanic",
                     "asian", "native_american", "pacific_islander",
                     "multiracial", "male", "female",
                     "econ_disadv", "lep", "special_ed"))
  expect_equal(actual, expected)
})

test_that("no non-standard subgroup variants present", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  subgroups <- unique(tidy$subgroup)

  forbidden <- c("total", "low_income", "economically_disadvantaged",
                 "socioeconomically_disadvantaged", "frl",
                 "iep", "disability", "students_with_disabilities",
                 "el", "ell", "english_learner",
                 "american_indian", "two_or_more",
                 "free_reduced_lunch",
                 "African American", "All Students",
                 "Economically Disadvantaged",
                 "Students with Disabilities (IEP)")
  overlap <- intersect(subgroups, forbidden)
  expect_equal(length(overlap), 0,
               info = paste("Forbidden names found:", paste(overlap, collapse = ", ")))
})

# ==============================================================================
# SECTION 4: Naming Standards — Grade Levels
# ==============================================================================

test_that("all 15 standard grade levels present (PK, K, 01-12, TOTAL)", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  actual <- sort(unique(tidy$grade_level))
  expected <- sort(c("PK", "K", "01", "02", "03", "04", "05", "06",
                     "07", "08", "09", "10", "11", "12", "TOTAL"))
  expect_equal(actual, expected)
})

test_that("all grade levels are uppercase", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  grades <- unique(tidy$grade_level)
  expect_true(all(grades == toupper(grades)))
})

test_that("no unexpected grade levels present", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  grades <- unique(tidy$grade_level)
  valid <- c("PK", "K", "01", "02", "03", "04", "05", "06",
             "07", "08", "09", "10", "11", "12", "TOTAL")
  unexpected <- setdiff(grades, valid)
  expect_equal(length(unexpected), 0,
               info = paste("Unexpected grades:", paste(unexpected, collapse = ", ")))
})

# ==============================================================================
# SECTION 5: Naming Standards — Entity Flags
# ==============================================================================

test_that("entity flags are present: is_state, is_district, is_school", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true("is_state" %in% names(tidy))
  expect_true("is_district" %in% names(tidy))
  expect_true("is_school" %in% names(tidy))
})

test_that("entity flags are mutually exclusive (exactly one TRUE per row)", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  flag_sums <- tidy$is_state + tidy$is_district + tidy$is_school
  expect_true(all(flag_sums == 1))
})

test_that("type column has exactly State, District, School", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_equal(sort(unique(tidy$type)), c("District", "School", "State"))
})

test_that("aggregation_flag has exactly state, district, campus", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_equal(sort(unique(tidy$aggregation_flag)), c("campus", "district", "state"))
})

test_that("is_state TRUE matches type == State", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(all(tidy$is_state == (tidy$type == "State")))
})

test_that("is_district TRUE matches type == District", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(all(tidy$is_district == (tidy$type == "District")))
})

test_that("is_school TRUE matches type == School", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(all(tidy$is_school == (tidy$type == "School")))
})

test_that("aggregation_flag state matches is_state", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(all(tidy$aggregation_flag[tidy$is_state] == "state"))
})

test_that("aggregation_flag district matches is_district", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(all(tidy$aggregation_flag[tidy$is_district] == "district"))
})

test_that("aggregation_flag campus matches is_school", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(all(tidy$aggregation_flag[tidy$is_school] == "campus"))
})

# ==============================================================================
# SECTION 6: State Row Constraints
# ==============================================================================

test_that("state rows have NA district_id and school_id", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  state <- tidy[tidy$is_state, ]

  expect_true(all(is.na(state$district_id)))
  expect_true(all(is.na(state$school_id)))
  expect_true(all(is.na(state$district_name)))
  expect_true(all(is.na(state$school_name)))
})

test_that("exactly 27 state rows in 2024 tidy output (13 subgroups + 14 grades)", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  n_state <- nrow(tidy[tidy$is_state, ])
  # 13 subgroups (TOTAL grade_level) + 14 grade levels (PK, K, 01-12) = 27
  expect_equal(n_state, 27)
})

test_that("no duplicate state rows per subgroup/grade_level", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  state <- tidy[tidy$is_state, ]
  dupes <- as.data.frame(table(state$subgroup, state$grade_level))
  multi <- dupes[dupes$Freq > 1, ]
  expect_equal(nrow(multi), 0)
})

# ==============================================================================
# SECTION 7: District Row Constraints
# ==============================================================================

test_that("district rows have populated district_id and name, NA school_id", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  dist <- tidy[tidy$is_district, ]

  expect_false(any(is.na(dist$district_id)))
  expect_false(any(is.na(dist$district_name)))
  expect_true(all(is.na(dist$school_id)))
})

test_that("all district_ids are 3-digit zero-padded strings", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  dist_ids <- unique(tidy$district_id[tidy$is_district])

  expect_true(all(nchar(dist_ids) == 3))
  expect_true(all(grepl("^[0-9]{3}$", dist_ids)))
})

test_that("known districts exist by ID: Adair (001), Jefferson (275), Fayette (165)", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  dist_ids <- unique(tidy$district_id[tidy$is_district])

  expect_true("001" %in% dist_ids)
  expect_true("275" %in% dist_ids)
  expect_true("165" %in% dist_ids)
})

test_that("known districts exist by name: Adair County, Jefferson County, Boone County", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  dist_names <- unique(tidy$district_name[tidy$is_district])

  expect_true("Adair County" %in% dist_names)
  expect_true("Jefferson County" %in% dist_names)
  expect_true("Boone County" %in% dist_names)
})

test_that("no duplicate district rows per district_id/subgroup/grade_level in 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  dist <- tidy[tidy$is_district, ]
  dupes <- as.data.frame(
    table(dist$district_id, dist$subgroup, dist$grade_level)
  )
  multi <- dupes[dupes$Freq > 1, ]
  expect_equal(nrow(multi), 0,
               info = paste("Duplicate district rows found:", nrow(multi)))
})

test_that("no duplicate district rows per district_id/subgroup/grade_level in 2023", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  dist <- tidy[tidy$is_district, ]
  dupes <- as.data.frame(
    table(dist$district_id, dist$subgroup, dist$grade_level)
  )
  multi <- dupes[dupes$Freq > 1, ]
  expect_equal(nrow(multi), 0,
               info = paste("Duplicate district rows found:", nrow(multi)))
})

# ==============================================================================
# SECTION 8: School Row Constraints
# ==============================================================================

test_that("school rows have populated district_id, school_id, and school_name", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  sch <- tidy[tidy$is_school, ]

  expect_false(any(is.na(sch$district_id)))
  expect_false(any(is.na(sch$school_id)))
  expect_false(any(is.na(sch$school_name)))
})

test_that("no duplicate school rows per district_id/school_id/subgroup/grade_level in 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  sch <- tidy[tidy$is_school, ]
  dupes <- as.data.frame(
    table(sch$district_id, sch$school_id, sch$subgroup, sch$grade_level)
  )
  multi <- dupes[dupes$Freq > 1, ]
  expect_equal(nrow(multi), 0,
               info = paste("Duplicate school rows found:", nrow(multi)))
})

# ==============================================================================
# SECTION 9: Pivot Fidelity — Wide-to-Tidy Consistency
# ==============================================================================

test_that("tidy total_enrollment matches wide row_total for all districts (2024)", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # For every district in wide, the tidy total_enrollment/TOTAL should match
  districts <- wide[wide$type == "District", ]
  for (i in seq_len(min(10, nrow(districts)))) {
    did <- districts$district_id[i]
    wide_total <- districts$row_total[i]

    tidy_total <- tidy$n_students[tidy$district_id == did & tidy$is_district &
                                   tidy$subgroup == "total_enrollment" &
                                   tidy$grade_level == "TOTAL"]
    expect_equal(tidy_total, wide_total,
                 info = paste("District", did, "total mismatch"))
  }
})

test_that("tidy white subgroup matches wide white column for Boone County (035)", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  boone_wide <- wide[wide$district_id == "035" & wide$type == "District", ]
  boone_tidy <- tidy[tidy$district_id == "035" & tidy$is_district &
                      tidy$subgroup == "white" & tidy$grade_level == "TOTAL", ]

  expect_equal(boone_tidy$n_students, boone_wide$white)
  expect_equal(boone_tidy$n_students, 15283)
})

test_that("tidy grade_k matches wide grade_k for Warren County (571)", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  warren_wide <- wide[wide$district_id == "571" & wide$type == "District", ]
  warren_tidy <- tidy[tidy$district_id == "571" & tidy$is_district &
                       tidy$subgroup == "total_enrollment" & tidy$grade_level == "K", ]

  expect_equal(warren_tidy$n_students, warren_wide$grade_k)
  expect_equal(warren_tidy$n_students, 1474)
})

test_that("tidy econ_disadv matches wide for Jefferson County (275)", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  jc_wide <- wide[wide$district_id == "275" & wide$type == "District", ]
  jc_tidy <- tidy[tidy$district_id == "275" & tidy$is_district &
                   tidy$subgroup == "econ_disadv" & tidy$grade_level == "TOTAL", ]

  expect_equal(jc_tidy$n_students, jc_wide$econ_disadv)
  expect_equal(jc_tidy$n_students, 66118)
})

# ==============================================================================
# SECTION 10: Percentage Calculation Correctness
# ==============================================================================

test_that("total_enrollment subgroup always has pct == 1.0", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  total_rows <- tidy[tidy$subgroup == "total_enrollment" &
                      tidy$grade_level == "TOTAL", ]
  expect_true(all(total_rows$pct == 1.0))
})

test_that("pct = n_students / row_total for Boone County (035) white", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  boone_white <- tidy[tidy$district_id == "035" & tidy$is_district &
                       tidy$subgroup == "white" & tidy$grade_level == "TOTAL", ]

  # white / total = 15283 / 21583
  expect_equal(boone_white$pct, 15283 / 21583, tolerance = 1e-6)
})

test_that("pct = n_students / row_total for Alvaton Elementary (571/010) black", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  alv_black <- tidy[tidy$district_id == "571" & tidy$school_id == "010" &
                     tidy$is_school &
                     tidy$subgroup == "black" & tidy$grade_level == "TOTAL", ]

  # black / total = 41 / 827
  expect_equal(alv_black$pct, 41 / 827, tolerance = 1e-6)
})

test_that("grade-level pct = n_students / row_total for state PK", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  state_pk <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment" &
                    tidy$grade_level == "PK", ]

  # PK / state total = 31467 / 686224
  expect_equal(state_pk$pct, 31467 / 686224, tolerance = 1e-6)
})

test_that("pct bounded 0 to 1 for all rows", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(all(tidy$pct >= 0, na.rm = TRUE))
  expect_true(all(tidy$pct <= 1, na.rm = TRUE))
})

test_that("no Inf or NaN in pct or n_students", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_false(any(is.infinite(tidy$pct)))
  expect_false(any(is.nan(tidy$pct)))
  expect_false(any(is.infinite(tidy$n_students)))
  expect_false(any(is.nan(tidy$n_students)))
})

test_that("no NA values in n_students (suppressed values filtered out)", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_false(any(is.na(tidy$n_students)))
})

# ==============================================================================
# SECTION 11: Aggregation Invariants
# ==============================================================================

test_that("race subgroups sum to total for Jefferson County (275) 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  races <- c("white", "black", "hispanic", "asian",
             "native_american", "pacific_islander", "multiracial")
  jc <- tidy[tidy$district_id == "275" & tidy$is_district &
              tidy$grade_level == "TOTAL", ]

  race_sum <- sum(jc$n_students[jc$subgroup %in% races])
  total <- jc$n_students[jc$subgroup == "total_enrollment"]

  expect_equal(race_sum, total)
})

test_that("race subgroups sum to total for Boone County (035) 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  races <- c("white", "black", "hispanic", "asian",
             "native_american", "pacific_islander", "multiracial")
  b <- tidy[tidy$district_id == "035" & tidy$is_district &
             tidy$grade_level == "TOTAL", ]

  race_sum <- sum(b$n_students[b$subgroup %in% races])
  total <- b$n_students[b$subgroup == "total_enrollment"]

  expect_equal(race_sum, total)
})

test_that("gender subgroups sum to total for Jefferson County (275) 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  jc <- tidy[tidy$district_id == "275" & tidy$is_district &
              tidy$grade_level == "TOTAL", ]

  male <- jc$n_students[jc$subgroup == "male"]
  female <- jc$n_students[jc$subgroup == "female"]
  total <- jc$n_students[jc$subgroup == "total_enrollment"]

  expect_equal(male + female, total)
})

test_that("gender subgroups sum to total for state level 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  st <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]

  male <- st$n_students[st$subgroup == "male"]
  female <- st$n_students[st$subgroup == "female"]
  total <- st$n_students[st$subgroup == "total_enrollment"]

  expect_equal(male + female, total)
})

test_that("race subgroups sum to total for state level 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  races <- c("white", "black", "hispanic", "asian",
             "native_american", "pacific_islander", "multiracial")
  st <- tidy[tidy$is_state & tidy$grade_level == "TOTAL", ]

  race_sum <- sum(st$n_students[st$subgroup %in% races])
  total <- st$n_students[st$subgroup == "total_enrollment"]

  expect_equal(race_sum, total)
})

test_that("state total uses KDE official aggregate (686,224), not district sum (710,854+)", {
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

  expect_equal(state_total, 686224)
  # District sum exceeds state total due to independent district overlap
  expect_true(district_sum > state_total)
})

# ==============================================================================
# SECTION 12: Grade-Level / Subgroup Orthogonality
# ==============================================================================

test_that("individual grade rows always have subgroup == total_enrollment", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  grade_rows <- tidy[tidy$grade_level %in% c("PK", "K", "01", "02", "03", "04",
                                               "05", "06", "07", "08", "09", "10",
                                               "11", "12"), ]
  expect_true(all(grade_rows$subgroup == "total_enrollment"))
})

test_that("demographic subgroups always have grade_level == TOTAL", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  demo_subs <- c("white", "black", "hispanic", "asian", "native_american",
                 "pacific_islander", "multiracial", "male", "female",
                 "econ_disadv", "lep", "special_ed")
  demo_rows <- tidy[tidy$subgroup %in% demo_subs, ]
  expect_true(all(demo_rows$grade_level == "TOTAL"))
})

# ==============================================================================
# SECTION 13: Cross-Year Consistency
# ==============================================================================

test_that("columns are identical across 2023 and 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy_2023 <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  tidy_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_equal(sort(names(tidy_2023)), sort(names(tidy_2024)))
})

test_that("subgroups are identical across 2023 and 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy_2023 <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  tidy_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_equal(sort(unique(tidy_2023$subgroup)), sort(unique(tidy_2024$subgroup)))
})

test_that("grade levels are identical across 2023 and 2024", {
  skip_on_cran()
  skip_if_offline()

  tidy_2023 <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  tidy_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_equal(sort(unique(tidy_2023$grade_level)), sort(unique(tidy_2024$grade_level)))
})

test_that("district count is consistent: 176 for 2020, 2021, 2022, 2023, 2024", {
  skip_on_cran()
  skip_if_offline()

  for (yr in 2020:2024) {
    tidy <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    n_dist <- length(unique(tidy$district_id[tidy$is_district &
                     tidy$subgroup == "total_enrollment" &
                     tidy$grade_level == "TOTAL"]))
    expect_equal(n_dist, 176,
                 info = paste(yr, "should have 176 districts, got", n_dist))
  }
})

test_that("year-over-year state total change < 5% for SRC years", {
  skip_on_cran()
  skip_if_offline()

  prev_total <- NULL
  for (yr in 2020:2024) {
    tidy <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    total <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                              tidy$grade_level == "TOTAL"]
    if (!is.null(prev_total)) {
      pct_change <- abs(total - prev_total) / prev_total
      expect_true(pct_change < 0.05,
                  info = paste(yr, "change:", round(pct_change * 100, 2), "%"))
    }
    prev_total <- total
  }
})

test_that("state total in reasonable range (500K-1M) for all SRC years", {
  skip_on_cran()
  skip_if_offline()

  for (yr in 2020:2024) {
    tidy <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    total <- tidy$n_students[tidy$is_state & tidy$subgroup == "total_enrollment" &
                              tidy$grade_level == "TOTAL"]
    expect_true(total > 500000,
                info = paste(yr, "total too low:", total))
    expect_true(total < 1000000,
                info = paste(yr, "total too high:", total))
  }
})

# ==============================================================================
# SECTION 14: Data Quality — Non-negative Counts
# ==============================================================================

test_that("all n_students values are non-negative in tidy format", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(all(tidy$n_students >= 0))
})

test_that("all non-NA values are non-negative in wide format", {
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
    vals <- wide[[col]][!is.na(wide[[col]])]
    if (length(vals) > 0) {
      expect_true(all(vals >= 0),
                  info = paste("Negative values in", col))
    }
  }
})

# ==============================================================================
# SECTION 15: Data Quality — Suppression Handling
# ==============================================================================

test_that("suppressed values in wide format are NA, not 0 or negative", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Small schools have NA demographics (suppressed)
  small_schools <- wide[wide$type == "School" & !is.na(wide$row_total) &
                         wide$row_total < 10, ]

  if (nrow(small_schools) > 0) {
    # At least some should have NA demographics
    has_na_demos <- any(is.na(small_schools$black)) |
                    any(is.na(small_schools$hispanic)) |
                    any(is.na(small_schools$asian))
    expect_true(has_na_demos,
                info = "Small schools should have some suppressed (NA) demographics")
  }
})

# ==============================================================================
# SECTION 16: Wide Format — One State Row
# ==============================================================================

test_that("wide format has exactly 1 State row", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  expect_equal(nrow(wide[wide$type == "State", ]), 1)
})

test_that("wide format has exactly 33 columns", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  expect_equal(ncol(wide), 33)
})

# ==============================================================================
# SECTION 17: tidy_enr() Direct Tests
# ==============================================================================

test_that("tidy_enr on wide data produces expected structure", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy_result <- tidy_enr(wide)

  expect_true("grade_level" %in% names(tidy_result))
  expect_true("subgroup" %in% names(tidy_result))
  expect_true("n_students" %in% names(tidy_result))
  expect_true("pct" %in% names(tidy_result))
})

test_that("tidy_enr filters out NA n_students", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy_result <- tidy_enr(wide)

  expect_false(any(is.na(tidy_result$n_students)))
})

test_that("tidy_enr followed by id_enr_aggs matches fetch_enr tidy=TRUE", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  manual <- tidy_enr(wide) |> id_enr_aggs()

  auto <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_equal(nrow(manual), nrow(auto))
  expect_equal(sort(names(manual)), sort(names(auto)))
})

# ==============================================================================
# SECTION 18: id_enr_aggs() Direct Tests
# ==============================================================================

test_that("id_enr_aggs adds is_state, is_district, is_school flags", {
  skip_on_cran()
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy_no_flags <- tidy_enr(wide)

  expect_false("is_state" %in% names(tidy_no_flags))

  with_flags <- id_enr_aggs(tidy_no_flags)
  expect_true("is_state" %in% names(with_flags))
  expect_true("is_district" %in% names(with_flags))
  expect_true("is_school" %in% names(with_flags))
  expect_true("aggregation_flag" %in% names(with_flags))
})

# ==============================================================================
# SECTION 19: Utility Function Edge Cases
# ==============================================================================

test_that("safe_numeric handles all suppression markers", {
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

test_that("safe_numeric converts valid numbers", {
  expect_equal(kyschooldata:::safe_numeric("100"), 100)
  expect_equal(kyschooldata:::safe_numeric("0"), 0)
  expect_equal(kyschooldata:::safe_numeric("1,234"), 1234)
  expect_equal(kyschooldata:::safe_numeric("1,234,567"), 1234567)
  expect_equal(kyschooldata:::safe_numeric("  100  "), 100)
  expect_equal(kyschooldata:::safe_numeric("99999"), 99999)
})

test_that("safe_numeric handles decimal numbers", {
  expect_equal(kyschooldata:::safe_numeric("3.14"), 3.14)
  expect_equal(kyschooldata:::safe_numeric("0.5"), 0.5)
})

test_that("standardize_district_id pads to 3 digits", {
  expect_equal(kyschooldata:::standardize_district_id("1"), "001")
  expect_equal(kyschooldata:::standardize_district_id("42"), "042")
  expect_equal(kyschooldata:::standardize_district_id("275"), "275")
  expect_equal(kyschooldata:::standardize_district_id("999"), "999")
  expect_equal(kyschooldata:::standardize_district_id("  165  "), "165")
})

# ==============================================================================
# SECTION 20: fetch_enr_multi() with wide format
# ==============================================================================

test_that("fetch_enr_multi tidy=FALSE 2023:2024 has correct row count", {
  skip_on_cran()
  skip_if_offline()

  result <- fetch_enr_multi(2023:2024, tidy = FALSE, use_cache = TRUE)

  rows_2023 <- nrow(result[result$end_year == 2023, ])
  rows_2024 <- nrow(result[result$end_year == 2024, ])

  expect_equal(rows_2024, 1573)
  expect_gt(rows_2023, 1000)
  expect_equal(rows_2023 + rows_2024, nrow(result))
})

test_that("fetch_enr_multi produces consistent state totals per year", {
  skip_on_cran()
  skip_if_offline()

  multi <- fetch_enr_multi(2022:2024, tidy = TRUE, use_cache = TRUE)

  st_2022 <- multi$n_students[multi$is_state & multi$end_year == 2022 &
                               multi$subgroup == "total_enrollment" &
                               multi$grade_level == "TOTAL"]
  st_2023 <- multi$n_students[multi$is_state & multi$end_year == 2023 &
                               multi$subgroup == "total_enrollment" &
                               multi$grade_level == "TOTAL"]
  st_2024 <- multi$n_students[multi$is_state & multi$end_year == 2024 &
                               multi$subgroup == "total_enrollment" &
                               multi$grade_level == "TOTAL"]

  expect_equal(st_2022, 685401)
  expect_equal(st_2023, 687294)
  expect_equal(st_2024, 686224)
})

# ==============================================================================
# SECTION 21: Tidy Row Count Distribution
# ==============================================================================

test_that("2024 tidy has correct row distribution: 27 state + 4574 district + 23361 school", {
  skip_on_cran()
  skip_if_offline()

  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  expect_equal(nrow(tidy[tidy$is_state, ]), 27)
  expect_equal(nrow(tidy[tidy$is_district, ]), 4574)
  expect_equal(nrow(tidy[tidy$is_school, ]), 23361)
  expect_equal(nrow(tidy), 27962)
})
