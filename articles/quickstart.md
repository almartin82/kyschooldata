# Getting Started with kyschooldata

## Overview

The `kyschooldata` package provides tools for fetching and analyzing
Kentucky school enrollment data from the Kentucky Department of
Education (KDE). This vignette covers:

1.  Installation and setup
2.  Basic data fetching
3.  Understanding the data schema
4.  Working with district IDs
5.  Filtering and analysis
6.  Multi-year analysis

## Installation

Install from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("almartin82/kyschooldata")
```

Load the package along with helpful companions:

``` r
library(kyschooldata)
library(dplyr)
library(ggplot2)
```

## Data Availability

Kentucky has extensive historical data spanning nearly three decades:

``` r
# Check available years
years <- get_available_years()
cat(sprintf("Data available from %d to %d\n", years$min_year, years$max_year))
```

    ## Data available from 1997 to 2024

| Years     | Source             | Aggregation Levels      | Demographics                      |
|-----------|--------------------|-------------------------|-----------------------------------|
| 2020-2024 | SRC Current Format | State, District, School | Race, Gender, Special Populations |
| 2012-2019 | SRC Historical     | State, District, School | Race, Gender, Special Populations |
| 1997-2011 | SAAR Data          | State, District         | Race                              |

## Basic Data Fetching

### Fetch a Single Year

The main function is
[`fetch_enr()`](https://almartin82.github.io/kyschooldata/reference/fetch_enr.md),
which downloads and processes enrollment data:

``` r
# Fetch 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# View the first few rows
head(enr_2024)
```

    ##   end_year     type district_id school_id district_name school_name grade_level
    ## 1     2024    State        <NA>      <NA>          <NA>        <NA>          PK
    ## 2     2024 District        <NA>      <NA>          <NA>        <NA>          PK
    ## 3     2024 District        <NA>      <NA>          <NA>        <NA>          PK
    ## 4     2024 District        <NA>      <NA>          <NA>        <NA>          PK
    ## 5     2024 District        <NA>      <NA>          <NA>        <NA>          PK
    ## 6     2024 District        <NA>      <NA>          <NA>        <NA>          PK
    ##           subgroup n_students pct is_state is_district is_school
    ## 1 total_enrollment     407122  NA     TRUE       FALSE     FALSE
    ## 2 total_enrollment      31467  NA    FALSE        TRUE     FALSE
    ## 3 total_enrollment      13950  NA    FALSE        TRUE     FALSE
    ## 4 total_enrollment      17517  NA    FALSE        TRUE     FALSE
    ## 5 total_enrollment       3477  NA    FALSE        TRUE     FALSE
    ## 6 total_enrollment         34  NA    FALSE        TRUE     FALSE

### Understanding the Year Parameter

The `end_year` parameter represents the end of the academic year:

- `2024` = 2023-24 school year
- `2023` = 2022-23 school year
- etc.

## Understanding the Data Schema

### Tidy Format (Default)

By default,
[`fetch_enr()`](https://almartin82.github.io/kyschooldata/reference/fetch_enr.md)
returns data in **tidy (long) format**. Each row represents a single
observation for one entity, grade level, and subgroup combination.

``` r
# Key columns in tidy format
enr_2024 %>%
  select(end_year, district_id, school_id, district_name,
         type, grade_level, subgroup, n_students, pct) %>%
  head(10)
```

    ##    end_year district_id school_id district_name     type grade_level
    ## 1      2024        <NA>      <NA>          <NA>    State          PK
    ## 2      2024        <NA>      <NA>          <NA> District          PK
    ## 3      2024        <NA>      <NA>          <NA> District          PK
    ## 4      2024        <NA>      <NA>          <NA> District          PK
    ## 5      2024        <NA>      <NA>          <NA> District          PK
    ## 6      2024        <NA>      <NA>          <NA> District          PK
    ## 7      2024        <NA>      <NA>          <NA> District          PK
    ## 8      2024        <NA>      <NA>          <NA> District          PK
    ## 9      2024        <NA>      <NA>          <NA> District          PK
    ## 10     2024        <NA>      <NA>          <NA> District          PK
    ##            subgroup n_students pct
    ## 1  total_enrollment     407122  NA
    ## 2  total_enrollment      31467  NA
    ## 3  total_enrollment      13950  NA
    ## 4  total_enrollment      17517  NA
    ## 5  total_enrollment       3477  NA
    ## 6  total_enrollment         34  NA
    ## 7  total_enrollment        591  NA
    ## 8  total_enrollment       3089  NA
    ## 9  total_enrollment         40  NA
    ## 10 total_enrollment       2056  NA

| Column          | Description                                 |
|-----------------|---------------------------------------------|
| `end_year`      | School year end (e.g., 2024 for 2023-24)    |
| `district_id`   | 3-digit district code                       |
| `school_id`     | 6-digit school code (NA for district-level) |
| `district_name` | Name of the district                        |
| `school_name`   | Name of the school (NA for district-level)  |
| `type`          | “State”, “District”, or “School”            |
| `grade_level`   | Grade level (“TOTAL”, “PK”, “K”, “01”-“12”) |
| `subgroup`      | Demographic or population subgroup          |
| `n_students`    | Student count                               |
| `pct`           | Percentage of total enrollment              |

### Subgroups

The `subgroup` column identifies demographic categories:

- `total_enrollment`: Total student count
- **Race/Ethnicity**: `white`, `black`, `hispanic`, `asian`,
  `native_american`, `pacific_islander`, `multiracial`
- **Special Populations**: `econ_disadv`, `lep`, `special_ed`

``` r
# See all subgroups
enr_2024 %>%
  distinct(subgroup) %>%
  pull(subgroup)
```

    ## [1] "total_enrollment"

## Working with District IDs

Kentucky uses a hierarchical ID system:

- **District ID:** 3 digits (e.g., 275 for Jefferson County)
- **School ID:** 6 digits (district + 3-digit school code)

### Major Districts

| District ID | District Name                 |
|-------------|-------------------------------|
| 275         | Jefferson County (Louisville) |
| 180         | Fayette County (Lexington)    |
| 045         | Boone County                  |
| 360         | Kenton County                 |
| 110         | Daviess County                |

### Finding Districts

``` r
# Search for a district by name
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  filter(grepl("Jefferson", district_name, ignore.case = TRUE)) %>%
  select(district_id, district_name, n_students)
```

    ## [1] district_id   district_name n_students   
    ## <0 rows> (or 0-length row.names)

## Filtering Data

### Aggregation Level Flags

The data includes boolean flags to identify aggregation levels:

``` r
# State totals
state <- enr_2024 %>% filter(is_state)

# All districts (excluding state totals)
districts <- enr_2024 %>% filter(is_district)

# All schools
schools <- enr_2024 %>% filter(is_school)
```

### Common Filters

``` r
# State total enrollment
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

    ## [1] end_year   n_students
    ## <0 rows> (or 0-length row.names)

``` r
# Top 10 districts by enrollment
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students) %>%
  head(10)
```

    ## [1] district_name n_students   
    ## <0 rows> (or 0-length row.names)

``` r
# Demographics for state
enr_2024 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
```

    ## [1] subgroup   n_students pct       
    ## <0 rows> (or 0-length row.names)

## Multi-Year Analysis

### Fetch Multiple Years

``` r
# Fetch a range of years
enr_recent <- fetch_enr_multi(2020:2024)

# View statewide trend
enr_recent %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

    ## [1] end_year   n_students
    ## <0 rows> (or 0-length row.names)

### Historical Analysis

``` r
# Fetch early years (SAAR data - district level only)
enr_early <- fetch_enr_multi(2000:2005)

enr_early %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

    ## [1] end_year   n_students
    ## <0 rows> (or 0-length row.names)

## Visualization Example

``` r
# State enrollment trend
state_trend <- enr_recent %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(state_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.2, color = "#2C3E50") +
  geom_point(size = 3, color = "#2C3E50") +
  scale_y_continuous(labels = scales::comma, limits = c(0, NA)) +
  labs(
    title = "Kentucky Statewide Enrollment",
    x = "School Year",
    y = "Total Students"
  ) +
  theme_minimal(base_size = 12)
```

![](quickstart_files/figure-html/visualization-1.png)

## Next Steps

- Explore the [Enrollment Trends
  vignette](https://almartin82.github.io/kyschooldata/articles/enrollment-trends.md)
  for in-depth analysis with visualizations
- See the [function
  reference](https://almartin82.github.io/kyschooldata/reference/index.md)
  for detailed documentation
- Check
  [`?fetch_enr`](https://almartin82.github.io/kyschooldata/reference/fetch_enr.md)
  for parameter details
