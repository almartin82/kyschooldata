# Download a CSV from KDE OpenHouse via POST

KDE OpenHouse pages use anti-forgery tokens. This function:

1.  GETs the page to retrieve cookies and the
    \_\_RequestVerificationToken

2.  POSTs back with ExportType=CSV to trigger the CSV download

## Usage

``` r
download_openhouse_csv(page_name)
```

## Arguments

- page_name:

  The page to download from ("Superintendents" or "Principals")

## Value

A tibble with the CSV data
