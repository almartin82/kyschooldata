# Get raw school directory data from KDE

Downloads the raw superintendent and principal CSV files from KDE's
OpenHouse Directory system. The download uses an anti-forgery token and
POST request, matching the browser export flow.

## Usage

``` r
get_raw_directory()
```

## Value

A list with two data frames: `superintendents` and `principals`
