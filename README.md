# kyschooldata

<!-- badges: start -->
<!-- badges: end -->

An R package for fetching and processing Kentucky school enrollment data from the Kentucky Department of Education (KDE).

## Installation

You can install the development version of kyschooldata from GitHub with:

```r
# install.packages("devtools")
devtools::install_github("almartin82/kyschooldata")
```
## Quick Start

```r
library(kyschooldata)

# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get wide format
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2024)

# See available years
get_available_years()
```

## Data Sources

Kentucky school enrollment data is sourced from the Kentucky Department of Education (KDE) through multiple portals:

| Source | Years | URL |
|--------|-------|-----|
| School Report Card (SRC) Current | 2020-2025 | [Open House SRC Data](https://openhouse.education.ky.gov/Home/SRCData) |
| SRC Historical Datasets | 2012-2019 | [Historical SRC Datasets](https://www.education.ky.gov/Open-House/data/Pages/Historical-SRC-Datasets.aspx) |
| SAAR Ethnic Membership | 1997-2019 | [Historical SAAR Data](https://www.education.ky.gov/districts/enrol/pages/historical-saar-data.aspx) |

## Data Availability

### Format Eras

kyschooldata handles three distinct format eras:

#### Era 1: SAAR Data (1997-2019)
- **Source**: Superintendent's Annual Attendance Report (SAAR) Ethnic Membership Reports
- **Aggregation**: District-level only (no school-level data)
- **Demographics**: Race/ethnicity (White, Black, Hispanic, Asian, American Indian, Pacific Islander, Multiracial)
- **Format**: Excel workbook with one sheet per year

#### Era 2: SRC Historical Datasets (2012-2019)
- **Source**: School Report Card Historical Datasets
- **Aggregation**: School and district level
- **Demographics**: Race/ethnicity, gender, special populations
- **Format**: CSV files

#### Era 3: SRC Current Format (2020-2025)
- **Source**: Open House SRC Datasets
- **Aggregation**: School and district level
- **Demographics**: Race/ethnicity, gender, special populations, grade levels
- **Format**: CSV files with primary/secondary split

### What's Available

| Data Element | 1997-2011 | 2012-2019 | 2020-2025 |
|--------------|-----------|-----------|-----------|
| Total enrollment | Yes | Yes | Yes |
| White | Yes | Yes | Yes |
| Black | Yes | Yes | Yes |
| Hispanic | Yes | Yes | Yes |
| Asian | Yes | Yes | Yes |
| Native American | Yes | Yes | Yes |
| Pacific Islander | Some years | Yes | Yes |
| Multiracial | Some years | Yes | Yes |
| Male | No | Yes | Yes |
| Female | No | Yes | Yes |
| Economically Disadvantaged | No | Yes | Yes |
| LEP/ELL | No | Yes | Yes |
| Special Education | No | Yes | Yes |
| Grade-level enrollment | No | Some | Yes |
| School-level data | No | Yes | Yes |
| District-level data | Yes | Yes | Yes |

### What's NOT Available

- Pre-1997 enrollment data
- Individual student records (aggregate only)
- Private school enrollment
- Homeschool enrollment counts (separate data source)

### Known Caveats

1. **Pre-2011 racial categories**: Pacific Islander and Multiracial categories may not be available or may be combined with other categories
2. **SAAR data limitations**: 1997-2011 data is district-level only
3. **Small cell suppression**: KDE suppresses counts below certain thresholds for privacy
4. **Year transitions**: URL patterns and file formats change periodically

## ID System

Kentucky uses a hierarchical ID system:

| Level | Format | Example | Description |
|-------|--------|---------|-------------|
| District | 3 digits | 275 | Jefferson County |
| School | 6 digits | 275001 | District (275) + School (001) |

### Major Districts

| District ID | District Name |
|-------------|---------------|
| 275 | Jefferson County |
| 180 | Fayette County |
| 360 | Kenton County |
| 045 | Boone County |
| 110 | Daviess County |

## Output Schema

### Wide Format (tidy = FALSE)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end (2024 = 2023-24) |
| type | character | "State", "District", or "School" |
| district_id | character | 3-digit district ID |
| school_id | character | 6-digit school ID (NA for districts) |
| district_name | character | District name |
| school_name | character | School name (NA for districts) |
| row_total | integer | Total enrollment |
| white | integer | White student count |
| black | integer | Black/African American count |
| hispanic | integer | Hispanic/Latino count |
| asian | integer | Asian count |
| native_american | integer | American Indian/Alaska Native count |
| pacific_islander | integer | Pacific Islander count |
| multiracial | integer | Two or more races count |
| male | integer | Male student count |
| female | integer | Female student count |
| econ_disadv | integer | Economically disadvantaged count |
| lep | integer | Limited English Proficient count |
| special_ed | integer | Special education count |
| grade_pk through grade_12 | integer | Grade-level enrollment |

### Tidy Format (tidy = TRUE, default)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end |
| type | character | Aggregation level |
| district_id | character | District ID |
| school_id | character | School ID |
| district_name | character | District name |
| school_name | character | School name |
| grade_level | character | "TOTAL", "PK", "K", "01"-"12" |
| subgroup | character | "total_enrollment", demographic, etc. |
| n_students | integer | Student count |
| pct | numeric | Percentage of total (0-1 scale) |
| is_state | logical | TRUE if state-level record |
| is_district | logical | TRUE if district-level record |
| is_school | logical | TRUE if school-level record |

## Caching

Data is cached locally to avoid repeated downloads:

```r
# View cache status
cache_status()

# Clear specific year
clear_cache(2024)

# Clear all cached data
clear_cache()

# Force fresh download
fetch_enr(2024, use_cache = FALSE)
```

Cache files are stored in `rappdirs::user_cache_dir("kyschooldata")`.

## Examples

### State Enrollment Trend

```r
library(kyschooldata)
library(dplyr)
library(ggplot2)

# Get 10 years of data
enr <- fetch_enr_multi(2015:2024)

# State total over time
enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  ggplot(aes(x = end_year, y = n_students)) +
  geom_line() +
  geom_point() +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Kentucky Public School Enrollment",
    x = "School Year (End)",
    y = "Total Students"
  )
```

### District Demographics

```r
# Jefferson County demographics for 2024
enr_2024 %>%
  filter(district_id == "275", grade_level == "TOTAL") %>%
  filter(subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
```

### Grade Distribution

```r
# State grade-level enrollment
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment") %>%
  filter(grade_level %in% c("K", "01", "02", "03", "04", "05",
                            "06", "07", "08", "09", "10", "11", "12")) %>%
  select(grade_level, n_students)
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License
MIT
