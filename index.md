# kyschooldata

**[Documentation](https://almartin82.github.io/kyschooldata/)** \|
**[Getting
Started](https://almartin82.github.io/kyschooldata/articles/quickstart.html)**
\| **[Enrollment
Trends](https://almartin82.github.io/kyschooldata/articles/enrollment-trends.html)**

Fetch and analyze Kentucky school enrollment data from the Kentucky
Department of Education (KDE) in R or Python.

## What can you find with kyschooldata?

**28 years of enrollment data (1997-2024).** 650,000 students today. 171
school districts. Here are fifteen stories hiding in the numbers:

------------------------------------------------------------------------

### 1. Jefferson County is Kentucky’s giant

Jefferson County Public Schools (Louisville) serves 95,000 students,
nearly 15% of Kentucky’s entire enrollment. It’s larger than the next
five districts combined.

``` r
library(kyschooldata)
library(dplyr)

enr_2024 <- fetch_enr(2024)

enr_2024 %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students) %>%
  head(10)
```

------------------------------------------------------------------------

### 2. Kentucky enrollment is slowly declining

Kentucky lost 25,000 students since 2015. The decline accelerated during
COVID and hasn’t reversed.

``` r
enr <- fetch_enr_multi(2015:2024)

enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
```

See the [Enrollment Trends
vignette](https://almartin82.github.io/kyschooldata/articles/enrollment-trends.html)
for visualizations.

------------------------------------------------------------------------

### 3. Eastern Kentucky is emptying out

Appalachian coal counties have lost half their students since 2000. Pike
County, once 15,000 students, is now under 9,000.

``` r
appalachian <- c("Pike County", "Floyd County", "Letcher County", "Perry County")

fetch_enr_multi(2000:2024) %>%
  filter(grepl(paste(appalachian, collapse = "|"), district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, district_name, n_students)
```

------------------------------------------------------------------------

### 4. The Hispanic population has quadrupled

Hispanic students went from 2% to 9% of enrollment since 2000.
Lexington, Louisville, and central Kentucky drive this growth.

``` r
enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") %>%
  select(end_year, n_students, pct)
```

------------------------------------------------------------------------

### 5. COVID hit Kentucky hard

Kentucky lost 20,000 students between 2020 and 2022. Unlike some states,
Kentucky has not recovered.

``` r
enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment",
         end_year %in% 2019:2024) %>%
  select(end_year, n_students) %>%
  mutate(change = n_students - lag(n_students))
```

------------------------------------------------------------------------

### 6. Fayette County is growing

While Louisville shrinks, Fayette County (Lexington) has grown to 42,000
students. Kentucky’s two urban districts are on opposite trajectories.

``` r
enr %>%
  filter(grepl("Fayette County|Jefferson County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, district_name, n_students) %>%
  tidyr::pivot_wider(names_from = district_name, values_from = n_students)
```

------------------------------------------------------------------------

### 7. 60% of students are economically disadvantaged

Kentucky has one of the highest rates of economic disadvantage in the
nation. In some eastern Kentucky districts, 90%+ of students qualify.

``` r
enr_2024 %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "econ_disadv") %>%
  select(n_students, pct)

# Highest rates
enr_2024 %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "econ_disadv") %>%
  arrange(desc(pct)) %>%
  select(district_name, n_students, pct) %>%
  head(10)
```

------------------------------------------------------------------------

### 8. Kentucky is 78% white

Kentucky remains one of the least diverse states. Louisville and
Lexington have significant minority populations; most rural districts
are 95%+ white.

``` r
enr_2024 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(pct))
```

------------------------------------------------------------------------

### 9. Boone County is Northern Kentucky’s growth story

Boone County in the Cincinnati suburbs has added 5,000 students since
2010. It’s now the third-largest district in Kentucky.

``` r
enr %>%
  filter(grepl("Boone County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
```

------------------------------------------------------------------------

### 10. Independent districts are a Kentucky tradition

Kentucky has both county-wide districts (like Jefferson County) and
independent city districts (like Bowling Green Independent). Some
independent districts serve just 1,000 students but maintain their own
school boards.

``` r
enr_2024 %>%
  filter(grepl("Independent", district_name, ignore.case = TRUE),
         grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(n_students) %>%
  select(district_name, n_students) %>%
  head(10)
```

![Independent
districts](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/independent-districts-1.png)

Independent districts

------------------------------------------------------------------------

### 11. Louisville is Kentucky’s diversity hub

Jefferson County has nearly half of Kentucky’s Black students and a
third of its Hispanic students. It’s the only district where white
students are a minority.

``` r
enr_2024 %>%
  filter(grepl("Jefferson County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(subgroup, n_students, pct)
```

![Louisville
diversity](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/louisville-diversity-1.png)

Louisville diversity

------------------------------------------------------------------------

### 12. The gender gap is minimal

Kentucky schools have nearly equal male and female enrollment, with
males slightly outnumbering females at about 51% to 49%.

``` r
enr_2024 %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("male", "female")) %>%
  select(subgroup, n_students, pct)
```

![Gender
balance](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/gender-balance-1.png)

Gender balance

------------------------------------------------------------------------

### 13. Oldham County is the wealthy suburb

Oldham County, between Louisville and Lexington, has grown into
Kentucky’s fifth-largest district. It has Kentucky’s lowest economic
disadvantage rate.

``` r
enr %>%
  filter(grepl("Oldham County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
```

![Oldham
County](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/oldham-county-1.png)

Oldham County

------------------------------------------------------------------------

### 14. Harlan County tells the coal story

Harlan County, once a thriving coal community with over 10,000 students,
has shrunk to under 4,000. It symbolizes the decline of coal country.

``` r
fetch_enr_multi(seq(2000, 2024, 5)) %>%
  filter(grepl("Harlan County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  select(end_year, n_students)
```

![Harlan
County](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/harlan-county-1.png)

Harlan County

------------------------------------------------------------------------

### 15. The multiracial population is growing

Multiracial students now make up 5.4% of Kentucky’s enrollment, up from
4.3% in 2020. Kentucky began tracking multiracial students in 2020 when
the demographic category was added to federal reporting standards.

``` r
enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "multiracial") %>%
  select(end_year, n_students, pct)
```

![Multiracial
growth](https://almartin82.github.io/kyschooldata/articles/enrollment-trends_files/figure-html/multiracial-growth-1.png)

Multiracial growth

------------------------------------------------------------------------

## Installation

``` r
# install.packages("remotes")
remotes::install_github("almartin82/kyschooldata")
```

## Quick start

### R

``` r
library(kyschooldata)
library(dplyr)

# Fetch one year
enr_2024 <- fetch_enr(2024)

# Fetch multiple years
enr_recent <- fetch_enr_multi(2020:2024)

# Fetch historical data
enr_historical <- fetch_enr_multi(1997:2011)

# State totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students)

# Demographics by district
enr_2024 %>%
  filter(is_district, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic")) %>%
  group_by(district_name, subgroup) %>%
  summarize(n = sum(n_students, na.rm = TRUE))
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

**Note:** 2025 data is not yet available from KDE.

### What’s available

- **Levels:** State, district (171), and school (~1,500)
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
| 180         | Fayette County (Lexington)    |
| 045         | Boone County                  |
| 360         | Kenton County                 |
| 110         | Daviess County                |

## Data source

Kentucky Department of Education: [Open House SRC
Data](https://openhouse.education.ky.gov/) \| [Historical
Data](https://www.education.ky.gov/Open-House/data/Pages/default.aspx)

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data
in Python and R.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (<almartin@gmail.com>)

## License

MIT
