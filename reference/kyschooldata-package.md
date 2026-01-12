# kyschooldata: Fetch and Process Kentucky School Data

Downloads and processes school data from the Kentucky Department of
Education (KDE). Provides functions for fetching enrollment data from
the School Report Card (SRC) datasets and SAAR (Superintendent's Annual
Attendance Report) data, transforming it into tidy format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/kyschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/kyschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/kyschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/kyschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/kyschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

- [`get_available_years`](https://almartin82.github.io/kyschooldata/reference/get_available_years.md):

  Show available enrollment data years

## Cache functions

- [`cache_status`](https://almartin82.github.io/kyschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/kyschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Kentucky uses a hierarchical ID system:

- District IDs: 3 digits (e.g., 275 = Jefferson County)

- School IDs: 6 digits (3-digit district + 3-digit school)

## Data Sources

Data is sourced from the Kentucky Department of Education:

- SRC: <https://openhouse.education.ky.gov/Home/SRCData>

- Open House:
  <https://www.education.ky.gov/Open-House/data/Pages/default.aspx>

- SAAR:
  <https://www.education.ky.gov/districts/enrol/pages/historical-saar-data.aspx>

## Data Eras

- Era 1 (1997-2011): SAAR Ethnic Membership Reports - district-level
  only

- Era 2 (2012-2019): SRC Historical Datasets - school and district level

- Era 3 (2020-2025): SRC Current Format - school and district level with
  grade data

## See also

Useful links:

- <https://almartin82.github.io/kyschooldata>

- <https://github.com/almartin82/kyschooldata>

- Report bugs at <https://github.com/almartin82/kyschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
