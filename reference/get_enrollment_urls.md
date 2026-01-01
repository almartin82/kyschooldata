# Get the URL for KDE enrollment data

Returns the URL(s) where enrollment data can be found for a given year.

## Usage

``` r
get_enrollment_urls(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Character vector of URLs

## Examples

``` r
get_enrollment_urls(2024)  # KYRC24 format
#> [1] "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/KYRC24_OVW_Student_Enrollment.csv"  
#> [2] "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/KYRC24_OVW_Primary_Enrollment.csv"  
#> [3] "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/KYRC24_OVW_Secondary_Enrollment.csv"
get_enrollment_urls(2023)  # primary/secondary format
#> [1] "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/primary_enrollment_2023.csv"  
#> [2] "https://www.education.ky.gov/Open-House/data/HistoricalDatasets/secondary_enrollment_2023.csv"
get_enrollment_urls(2005)  # SAAR format
#> [1] "https://education.ky.gov/districts/enrol/Documents/1996-2019%20SAAR%20Summary%20ReportsADA.xlsx"
```
