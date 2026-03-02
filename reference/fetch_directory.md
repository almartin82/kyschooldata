# Fetch Kentucky school directory data

Downloads and processes school and district directory data from the
Kentucky Department of Education via the OpenHouse Directory system.
This includes all public schools with principal contact info and all
districts with superintendent contact info.

## Usage

``` r
fetch_directory(end_year = NULL, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  Currently unused. The directory data represents current
  schools/districts and is updated regularly. Included for API
  consistency with other fetch functions.

- tidy:

  If TRUE (default), returns data in a standardized format with
  consistent column names. If FALSE, returns raw column names from KDE.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from KDE.

## Value

A tibble with school directory data. Columns include:

- `state_district_id`: 3-digit district identifier (zero-padded)

- `state_school_id`: 3-digit school identifier within district

- `district_name`: District name

- `school_name`: School name (NA for district-level rows)

- `entity_type`: "district" or "school"

- `address`: Street address

- `city`: City

- `state`: State (always "KY")

- `zip`: ZIP code

- `phone`: Phone number

- `fax`: Fax number

- `principal_name`: School principal name (schools only)

- `superintendent_name`: District superintendent name (districts only)

- `grades_served`: Grade range (schools only, e.g., "9th-Ungraded")

- `facility_type`: School classification code (e.g., "A1")

- `facility_description`: School type description

- `district_website`: District website URL (districts only)

## Details

The directory data is downloaded from KDE's OpenHouse system, which
provides CSV exports of superintendent and principal contact lists. The
data is updated by districts through the DASCR (District and School
Collection Repository) system.

Note: For security reasons, KDE does not include email addresses in the
downloadable contact files.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school directory data
dir_data <- fetch_directory()

# Get raw format (original KDE column names)
dir_raw <- fetch_directory(tidy = FALSE)

# Force fresh download (ignore cache)
dir_fresh <- fetch_directory(use_cache = FALSE)

# Filter to schools only
library(dplyr)
schools <- dir_data |>
  filter(entity_type == "school")

# Find all schools in a district
jefferson_schools <- dir_data |>
  filter(state_district_id == "275", entity_type == "school")
} # }
```
