# Get available years for enrollment data

Returns the range of years for which enrollment data is available.

## Usage

``` r
get_available_years()
```

## Value

Character vector describing available year ranges

## Examples

``` r
get_available_years()
#> $min_year
#> [1] 1997
#> 
#> $max_year
#> [1] 2024
#> 
#> $description
#> [1] "Kentucky enrollment data from KDE (1997-2024)"
#> 
```
