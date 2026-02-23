# Deduplicate district rows from primary/secondary file overlap

When KDE provides separate primary and secondary enrollment files
(2020-2023), some districts appear in both. The secondary file contains
career/technical center data. For each duplicated district, keep the row
with the larger row_total (primary enrollment), since the primary file
represents the official comprehensive enrollment count.

## Usage

``` r
dedup_district_rows(df)
```

## Arguments

- df:

  Processed data frame

## Value

Data frame with one row per district (per type)
