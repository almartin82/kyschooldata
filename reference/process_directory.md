# Process raw directory data to standard schema

Takes raw superintendent and principal data from KDE and standardizes
into a single combined data frame with consistent column names.

## Usage

``` r
process_directory(raw_data)
```

## Arguments

- raw_data:

  List with `superintendents` and `principals` data frames from
  get_raw_directory()

## Value

Processed tibble with standard schema
