# Extract KDE state aggregate from processed data

KDE includes a statewide aggregate row with district_id "999" in its SRC
data files. When data is split across primary and secondary files
(2020-2023), both files may contain a district 999 row. We use the
primary file's number (the larger total) as the official state
enrollment figure.

## Usage

``` r
extract_kde_state_agg(df, end_year)
```

## Arguments

- df:

  Processed data frame that may contain district_id 999 rows

- end_year:

  School year end

## Value

Single-row data frame with state totals
