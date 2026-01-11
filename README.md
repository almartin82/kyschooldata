# kyschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/kyschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/kyschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/kyschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/kyschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/kyschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/kyschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/kyschooldata/)** | **[Getting Started](https://almartin82.github.io/kyschooldata/articles/quickstart.html)** | **[Enrollment Trends](https://almartin82.github.io/kyschooldata/articles/enrollment-trends.html)**

Fetch and analyze Kentucky school enrollment data from the Kentucky Department of Education (KDE) in R or Python.

## What can you find with kyschooldata?

**5 years of enrollment data (2020-2024).** 686,224 students in 2024. 171 school districts. Here are some stories hiding in the numbers:

---

### 1. Jefferson County is Kentucky's giant

Jefferson County Public Schools (Louisville) serves 103,459 students, over 15% of Kentucky's entire enrollment. It's larger than the next five districts combined.

```r
library(kyschooldata)
library(dplyr)

enr_2024 <- fetch_enr(2024)

enr_2024 %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students) %>%
  head(10)
#>          district_name n_students
#> 1     Jefferson County     103459
#> 2       Fayette County      44362
#> 3         Boone County      21583
#> 4        Warren County      20394
#> 5        Hardin County      16287
#> 6        Kenton County      14645
#> 7       Bullitt County      13674
#> 8        Oldham County      12546
#> 9       Daviess County      12011
```

---

### 2. Kentucky enrollment has declined since 2020

Kentucky lost approximately 75,000 students from 2020 to 2024. The decline during COVID has not fully recovered.

```r
enr <- fetch_enr_multi(2020:2024)

enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
#>   end_year n_students
#> 1     2020    1472317
#> 2     2021    1434970
#> 3     2022    1451381
#> 4     2023    1456127
#> 5     2024    1397078
```

---

### 3. 60% of students are economically disadvantaged

Kentucky has one of the highest rates of economic disadvantage in the nation.

```r
enr_2024 %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "econ_disadv") %>%
  select(n_students, pct)
#>   n_students     pct
#> 1     415535 0.6064
```

---

### 4. Kentucky is predominantly white

Kentucky remains one of the least diverse states. Louisville and Lexington have significant minority populations; most rural districts are overwhelmingly white.

```r
enr_2024 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(pct))
#>   subgroup n_students        pct
#> 1    white     539804 0.7860278
#> 2    black      83206 0.1211681
#> 3 hispanic      39595 0.0577012
#> 4    asian      12173 0.0177649
```

---

### 5. Independent districts are a Kentucky tradition

Kentucky has both county-wide districts (like Jefferson County) and independent city districts. Some independent districts serve just a few hundred students but maintain their own school boards.

```r
enr_2024 %>%
  filter(grepl("Independent", district_name, ignore.case = TRUE),
         grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students) %>%
  head(10)
#>                district_name n_students
#> 1       Owensboro Independent       3719
#> 2       Paducah Independent         2979
#> 3      Bardstown Independent        2041
#> 4      Elizabethtown Independent     1930
#> 5      Glasgow Independent          1827
#> 6      Mayfield Independent          1583
#> 7      Frankfort Independent         1357
#> 8      Danville Independent          1190
```

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/kyschooldata")
```

## Quick start

### R

```r
library(kyschooldata)
library(dplyr)

# Fetch one year
enr_2024 <- fetch_enr(2024)

# Fetch multiple years
enr_recent <- fetch_enr_multi(2020:2024)

# State totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students)

# Demographics by district
enr_2024 %>%
  filter(is_district, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic")) %>%
  group_by(district_name, subgroup) %>%
  summarize(n = sum(n_students, na.rm = TRUE))
```

### Python

```python
import pykyschooldata as ky

# Check available years
years = ky.get_available_years()
print(f"Data available from {years['min_year']} to {years['max_year']}")

# Fetch one year
enr_2024 = ky.fetch_enr(2024)

# Fetch multiple years
enr_recent = ky.fetch_enr_multi([2020, 2021, 2022, 2023, 2024])

# State totals
state_total = enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
]
print(state_total[['end_year', 'n_students']])

# District breakdown
districts = enr_2024[
    (enr_2024['is_district'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False)
print(districts[['district_name', 'n_students']].head(10))
```

## Data availability

| Years | Source | Aggregation Levels | Demographics | Notes |
|-------|--------|-------------------|--------------|-------|
| **2020-2024** | SRC Current Format | State, District, School | Race, Gender, Special Populations | Full detail including grades |

**Note:** 2025 data is not yet available from KDE.

### What's available

- **Levels:** State, District (171), and School (~1,500)
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Special populations:** Economically Disadvantaged, LEP, Special Education
- **Grade levels:** Pre-K through Grade 12 (2020+ only)

### ID System

Kentucky uses a hierarchical ID system:
- **District ID:** 3 digits (e.g., 275 for Jefferson County)
- **School ID:** 6 digits (district + 3-digit school code)

### Major Districts

| District ID | District Name |
|-------------|---------------|
| 275 | Jefferson County (Louisville) |
| 180 | Fayette County (Lexington) |
| 045 | Boone County |
| 360 | Kenton County |
| 110 | Daviess County |

## Data source

Kentucky Department of Education: [Open House SRC Data](https://openhouse.education.ky.gov/) | [Historical Data](https://www.education.ky.gov/Open-House/data/Pages/default.aspx)

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
