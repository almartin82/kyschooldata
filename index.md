# kyschooldata

**[Documentation](https://almartin82.github.io/kyschooldata/)** \|
**[Getting
Started](https://almartin82.github.io/kyschooldata/articles/quickstart.html)**
\| **[Enrollment
Trends](https://almartin82.github.io/kyschooldata/articles/enrollment-trends.html)**

Fetch and analyze Kentucky school enrollment data from the Kentucky
Department of Education (KDE) in R or Python.

## Why kyschooldata?

Kentucky publishes rich enrollment data going back to 1997, but
accessing it requires navigating multiple data formats across different
eras. This package provides a single, consistent interface to 28 years
of Kentucky school data.

**kyschooldata** is part of the
[njschooldata](https://github.com/almartin82/njschooldata) family of
state education data packages, providing a simple, consistent interface
for accessing state-published school data in R and Python.

## What can you find with kyschooldata?

**28 years of enrollment data (1997-2024).** 686,000 students today. 176
school districts. Here are fifteen stories hiding in the numbers:

------------------------------------------------------------------------

### 1. Jefferson County is Kentucky’s giant

Jefferson County Public Schools (Louisville) serves 103,000 students,
about 15% of Kentucky’s entire enrollment. It’s larger than the next
five districts combined.

``` r
library(kyschooldata)
library(dplyr)

enr_2024 <- fetch_enr(2024, use_cache = TRUE)

s1 <- enr_2024 %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students) %>%
  head(10)
stopifnot(nrow(s1) > 0)
s1
#>       district_name n_students
#> 1  Jefferson County     103459
#> 2    Fayette County      44362
#> 3      Boone County      21583
#> 4     Warren County      20394
#> 5     Hardin County      16287
#> 6     Kenton County      14645
#> 7    Bullitt County      13674
#> 8     Oldham County      12546
#> 9    Daviess County      12011
#> 10   Madison County      12007
```

![Top
districts](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/jefferson-county-1.png)

Top districts

------------------------------------------------------------------------

### 2. Kentucky enrollment has held steady near 686,000

Kentucky enrolled 698,000 students in 2020 and 686,000 in 2024 – a
modest 1.7% decline over five years. Despite COVID disruptions,
enrollment has been remarkably stable.

``` r
enr <- fetch_enr_multi(2020:2024, use_cache = TRUE)

s2 <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
stopifnot(nrow(s2) > 0)
s2
#>   end_year n_students
#> 1     2020     698388
#> 2     2021     682953
#> 3     2022     685401
#> 4     2023     687294
#> 5     2024     686224
```

![Enrollment
trend](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/enrollment-decline-1.png)

Enrollment trend

------------------------------------------------------------------------

### 3. Eastern Kentucky coal counties are shrinking

Appalachian coal counties have seen significant enrollment declines.
Pike, Floyd, Letcher, and Perry counties combined had over 22,000
students in 2020, dropping to about 20,200 by 2024.

``` r
appalachian <- c("Pike County", "Floyd County", "Letcher County", "Perry County")

s3 <- tryCatch(
  fetch_enr_multi(2020:2024, use_cache = TRUE),
  error = function(e) {
    warning("Failed to fetch coal county data: ", e$message)
    NULL
  }
)
stopifnot(!is.null(s3))

s3 <- s3 %>%
  filter(grepl(paste(appalachian, collapse = "|"), district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, district_name, n_students)
stopifnot(nrow(s3) > 0)
s3
#>    end_year  district_name n_students
#> 1      2020    Pike County       8770
#> 2      2020   Floyd County       6092
#> 3      2020   Perry County       4341
#> 4      2020 Letcher County       3119
#> 5      2021    Pike County       8457
#> 6      2021   Floyd County       5947
#> 7      2021   Perry County       4140
#> 8      2021 Letcher County       3091
#> 9      2022    Pike County       8245
#> 10     2022   Floyd County       5889
#> 11     2022   Perry County       3958
#> 12     2022 Letcher County       2990
#> 13     2023    Pike County       8197
#> 14     2023   Floyd County       5877
#> 15     2023   Perry County       3868
#> 16     2023 Letcher County       2706
#> 17     2024    Pike County       8044
#> 18     2024   Floyd County       5762
#> 19     2024   Perry County       3783
#> 20     2024 Letcher County       2611
```

![Appalachia
decline](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/appalachia-decline-1.png)

Appalachia decline

------------------------------------------------------------------------

### 4. Hispanic students now 10% of enrollment

Hispanic students grew from 7.7% to over 10% of enrollment between 2020
and 2024. Lexington, Louisville, and central Kentucky drive this growth.

``` r
s4 <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") %>%
  select(end_year, n_students, pct)
stopifnot(nrow(s4) > 0)
s4
#>   end_year n_students        pct
#> 1     2020      53493 0.07659496
#> 2     2021      54658 0.08003186
#> 3     2022      58578 0.08546530
#> 4     2023      63502 0.09239423
#> 5     2024      69877 0.10182827
```

![Hispanic
growth](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/hispanic-growth-1.png)

Hispanic growth

------------------------------------------------------------------------

### 5. COVID dipped enrollment by 15,000 students

Kentucky lost over 15,000 students between 2020 and 2021. The state
recovered modestly in 2022-2023 before a slight decline in 2024.

``` r
s5 <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment",
         end_year %in% 2020:2024) %>%
  select(end_year, n_students) %>%
  mutate(change = n_students - lag(n_students))
stopifnot(nrow(s5) > 0)
s5
#>   end_year n_students change
#> 1     2020     698388     NA
#> 2     2021     682953 -15435
#> 3     2022     685401   2448
#> 4     2023     687294   1893
#> 5     2024     686224  -1070
```

![COVID
impact](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/covid-impact-1.png)

COVID impact

------------------------------------------------------------------------

### 6. Fayette County holds steady alongside Louisville

While Jefferson County has remained relatively stable around 103,000,
Fayette County (Lexington) has held at about 44,000 students. Both
districts show resilience despite statewide pressures.

``` r
s6 <- enr %>%
  filter(grepl("Fayette County|Jefferson County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, district_name, n_students) %>%
  tidyr::pivot_wider(names_from = district_name, values_from = n_students)
stopifnot(nrow(s6) > 0)
s6
#> # A tibble: 5 x 3
#>   end_year `Jefferson County` `Fayette County`
#>      <int>              <dbl>            <dbl>
#> 1     2020             103876            44472
#> 2     2021             101678            43182
#> 3     2022             102204            43849
#> 4     2023             103432            43799
#> 5     2024             103459            44362
```

![Fayette vs
Jefferson](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/fayette-jefferson-1.png)

Fayette vs Jefferson

------------------------------------------------------------------------

### 7. 62% of students are economically disadvantaged

Kentucky has one of the highest rates of economic disadvantage in the
nation. In some eastern Kentucky districts, over 90% of students
qualify.

``` r
s7a <- enr_2024 %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "econ_disadv") %>%
  select(n_students, pct)
stopifnot(nrow(s7a) > 0)
s7a
#>   n_students       pct
#> 1     426203 0.6210844

# Highest rates
s7b <- enr_2024 %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "econ_disadv") %>%
  arrange(desc(pct)) %>%
  select(district_name, n_students, pct) %>%
  head(10)
stopifnot(nrow(s7b) > 0)
s7b
#>            district_name n_students       pct
#> 1     Fulton Independent        318 0.9325513
#> 2  Covington Independent       3693 0.9089343
#> 3    Newport Independent       1595 0.9083144
#> 4     Dayton Independent        820 0.8807734
#> 5   Fairview Independent        507 0.8711340
#> 6             Lee County        831 0.8629283
#> 7          Harlan County       3156 0.8590093
#> 8        McCreary County       2491 0.8551322
#> 9            Bell County       2202 0.8334595
#> 10 Pineville Independent        532 0.8325509
```

![Economic
disadvantage](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/econ-disadvantage-1.png)

Economic disadvantage

------------------------------------------------------------------------

### 8. Kentucky is 71% white

Kentucky remains one of the less diverse states. Louisville and
Lexington have significant minority populations; most rural districts
are 90%+ white.

``` r
s8 <- enr_2024 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(pct))
stopifnot(nrow(s8) > 0)
s8
#>   subgroup n_students        pct
#> 1    white     488062 0.71122840
#> 2    black      74804 0.10900814
#> 3 hispanic      69877 0.10182827
#> 4    asian      14529 0.02117239
```

![Demographics](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/demographics-1.png)

Demographics

------------------------------------------------------------------------

### 9. Boone County is Northern Kentucky’s growth story

Boone County in the Cincinnati suburbs has about 21,500 students. It’s
now the third-largest district in Kentucky.

``` r
s9 <- enr %>%
  filter(grepl("Boone County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
stopifnot(nrow(s9) > 0)
s9
#>   end_year n_students
#> 1     2020      21935
#> 2     2021      21483
#> 3     2022      21432
#> 4     2023      21384
#> 5     2024      21583
```

![Boone
County](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/boone-county-1.png)

Boone County

------------------------------------------------------------------------

### 10. Independent districts are a Kentucky tradition

Kentucky has both county-wide districts (like Jefferson County) and
independent city districts (like Bowling Green Independent). Some
independent districts serve just a few hundred students.

``` r
s10 <- enr_2024 %>%
  filter(grepl("Independent", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(n_students) %>%
  select(district_name, n_students) %>%
  head(10)
stopifnot(nrow(s10) > 0)
s10
#>                 district_name n_students
#> 1       Southgate Independent        221
#> 2         Augusta Independent        337
#> 3          Fulton Independent        341
#> 4         Jackson Independent        384
#> 5       Anchorage Independent        413
#> 6         Jenkins Independent        533
#> 7    Science Hill Independent        538
#> 8  East Bernstadt Independent        545
#> 9          Burgin Independent        546
#> 10       Fairview Independent        582
```

![Independent
districts](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/independent-districts-1.png)

Independent districts

------------------------------------------------------------------------

### 11. Louisville is Kentucky’s diversity hub

Jefferson County has significant Black (36%), Hispanic (18%), and Asian
(5%) populations. White students make up only 35% of enrollment in
Louisville.

``` r
s11 <- enr_2024 %>%
  filter(grepl("Jefferson County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
stopifnot(nrow(s11) > 0)
s11
#>   subgroup n_students        pct
#> 1    white      35817 0.34619511
#> 2    black      37106 0.35865415
#> 3 hispanic      18993 0.18357997
#> 4    asian       5103 0.04932389
```

![Louisville
diversity](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/louisville-diversity-1.png)

Louisville diversity

------------------------------------------------------------------------

### 12. The gender gap is minimal

Kentucky schools have nearly equal male and female enrollment, with
males at 51.7% and females at 48.3%.

``` r
s12 <- enr_2024 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("male", "female")) %>%
  select(subgroup, n_students, pct)
stopifnot(nrow(s12) > 0)
s12
#>   subgroup n_students       pct
#> 1     male     354795 0.5170251
#> 2   female     331429 0.4829749
```

![Gender
balance](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/gender-balance-1.png)

Gender balance

------------------------------------------------------------------------

### 13. Oldham County is the wealthy suburb

Oldham County, between Louisville and Lexington, has about 12,500
students. It has Kentucky’s lowest economic disadvantage rate.

``` r
s13 <- enr %>%
  filter(grepl("Oldham County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
stopifnot(nrow(s13) > 0)
s13
#>   end_year n_students
#> 1     2020      13171
#> 2     2021      12910
#> 3     2022      12875
#> 4     2023      12792
#> 5     2024      12546
```

![Oldham
County](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/oldham-county-1.png)

Oldham County

------------------------------------------------------------------------

### 14. Harlan County tells the coal story

Harlan County dropped from 4,096 students in 2020 to 3,674 in 2024, a
10% decline in just five years. The county symbolizes the contraction of
coal country in eastern Kentucky.

``` r
s14 <- tryCatch(
  fetch_enr_multi(2020:2024, use_cache = TRUE),
  error = function(e) {
    warning("Failed to fetch Harlan County data: ", e$message)
    NULL
  }
)
stopifnot(!is.null(s14))

s14 <- s14 %>%
  filter(grepl("Harlan County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
stopifnot(nrow(s14) > 0)
s14
#>   end_year n_students
#> 1     2020       4096
#> 2     2021       3957
#> 3     2022       3827
#> 4     2023       3764
#> 5     2024       3674
```

![Harlan
County](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/harlan-county-1.png)

Harlan County

------------------------------------------------------------------------

### 15. The multiracial population is growing

Multiracial students now make up 5.3% of Kentucky’s enrollment, up from
4.4% in 2020.

``` r
s15 <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "multiracial") %>%
  select(end_year, n_students, pct)
stopifnot(nrow(s15) > 0)
s15
#>   end_year n_students        pct
#> 1     2020      30414 0.04354886
#> 2     2021      31949 0.04678067
#> 3     2022      33664 0.04911577
#> 4     2023      35350 0.05143359
#> 5     2024      36681 0.05345339
```

![Multiracial
growth](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/multiracial-growth-1.png)

Multiracial growth

------------------------------------------------------------------------

## Installation

### R

``` r
# install.packages("remotes")
remotes::install_github("almartin82/kyschooldata")
```

### Python

``` bash
pip install pykyschooldata
```

## Quick start

### R

``` r
library(kyschooldata)
library(dplyr)

# Check available years
years <- get_available_years()
cat(sprintf("Data available from %d to %d\n", years$min_year, years$max_year))

# Fetch one year
enr_2024 <- fetch_enr(2024)

# Fetch multiple years
enr_recent <- fetch_enr_multi(2020:2024)

# State totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students)
```

### Python

``` python
import pykyschooldata as ky

# Check available years
years = ky.get_available_years()
print(f"Data available from {years['min_year']} to {years['max_year']}")

# Fetch one year
enr_2024 = ky.fetch_enr(2024)

# Fetch multiple years
enr_recent = ky.fetch_enr_multi([2020, 2021, 2022, 2023, 2024])

# State totals
state_total = enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
]
print(state_total[['end_year', 'n_students']])

# District breakdown
districts = enr_2024[
    (enr_2024['is_district'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False)
print(districts[['district_name', 'n_students']].head(10))
```

## Data availability

| Years         | Source             | Aggregation Levels      | Demographics                      | Notes                            |
|---------------|--------------------|-------------------------|-----------------------------------|----------------------------------|
| **2020-2024** | SRC Current Format | State, District, School | Race, Gender, Special Populations | Full detail including grades     |
| **2012-2019** | SRC Historical     | State, District, School | Race, Gender, Special Populations | School Report Card datasets      |
| **1997-2011** | SAAR Data          | State, District         | Race                              | District-level only (no schools) |

### What’s available

- **Levels:** State, district (176), and school (~1,500)
- **Demographics:** White, Black, Hispanic, Asian, Native American,
  Pacific Islander, Multiracial
- **Special populations:** Economically Disadvantaged, LEP, Special
  Education
- **Grade levels:** Pre-K through Grade 12 (2020+ only)

### ID System

Kentucky uses a hierarchical ID system: - **District ID:** 3 digits
(e.g., 275 for Jefferson County) - **School ID:** 6 digits (district +
3-digit school code)

### Major Districts

| District ID | District Name                 |
|-------------|-------------------------------|
| 275         | Jefferson County (Louisville) |
| 165         | Fayette County (Lexington)    |
| 035         | Boone County                  |
| 291         | Kenton County                 |
| 145         | Daviess County                |

## Data Notes

### Data Source

All data comes directly from the Kentucky Department of Education
(KDE): - **Current Data (2020+):** [KDE Historical SRC
Datasets](https://www.education.ky.gov/Open-House/data/Pages/Historical-SRC-Datasets.aspx) -
**Historical Data (1997-2019):** [KDE Historical SAAR
Data](https://www.education.ky.gov/districts/enrol/Pages/Historical-SAAR-Data.aspx)

### Reporting Period

Kentucky enrollment data is collected on **Census Day**, which is
typically the first Monday in October. The `end_year` field represents
the end of the school year (e.g., `2024` = 2023-24 school year, with
Census Day in October 2023).

### Suppression Rules

Kentucky applies data suppression to protect student privacy: - Counts
below 10 students may be suppressed at the school level - Suppressed
values appear as `NA` in the data - State and district totals are not
typically suppressed

### Known Data Quality Issues

- **Pre-2012 data:** SAAR format provides district-level totals only; no
  school-level data available
- **Multiracial category:** Only available from 2020 onwards when
  federal reporting standards changed

### Data Refresh

KDE typically releases updated enrollment data in late fall after Census
Day counts are finalized. This package will be updated as new data
becomes available.

## Part of the State Schooldata Project

**kyschooldata** is part of a family of R and Python packages that
provide consistent access to state education data. The project started
with [njschooldata](https://github.com/almartin82/njschooldata) and has
expanded to cover all 50 states.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (<almartin@gmail.com>)

## License

MIT
