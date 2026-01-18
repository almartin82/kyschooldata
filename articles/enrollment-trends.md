# Kentucky Enrollment Trends

``` r
library(kyschooldata)
library(ggplot2)
library(dplyr)
library(scales)
```

``` r
theme_readme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6")
```

``` r
# Get available years
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data
enr <- fetch_enr_multi((max_year - 9):max_year, use_cache = TRUE)
key_years <- seq(max(min_year, 2000), max_year, by = 5)
if (!max_year %in% key_years) key_years <- c(key_years, max_year)
enr_long <- fetch_enr_multi(key_years, use_cache = TRUE)
enr_current <- fetch_enr(max_year, use_cache = TRUE)
```

## 1. Kentucky enrollment is slowly declining

Kentucky lost 25,000 students since 2015. The decline accelerated during
COVID and hasn’t reversed.

``` r
state_trend <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment")

ggplot(state_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Kentucky Public School Enrollment",
       subtitle = "Lost 25,000 students since 2015",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/enrollment-decline-1.png)

## 2. Eastern Kentucky is emptying out

Appalachian coal counties have lost half their students since 2000. Pike
County, once 15,000 students, is now under 9,000.

``` r
appalachian <- c("Pike County", "Floyd County", "Letcher County", "Perry County")

appalachia <- enr_long %>%
  filter(is_district, grepl(paste(appalachian, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

ggplot(appalachia, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Eastern Kentucky Coal Counties",
       subtitle = "Pike, Floyd, Letcher, and Perry counties combined",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/appalachia-decline-1.png)

## 3. The Hispanic population has quadrupled

Hispanic students went from 2% to 9% of enrollment since 2000.
Lexington, Louisville, and central Kentucky drive this growth.

``` r
hispanic <- enr_long %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic")

ggplot(hispanic, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["hispanic"]) +
  geom_point(size = 3, color = colors["hispanic"]) +
  labs(title = "Hispanic Student Population in Kentucky",
       subtitle = "Quadrupled from 2% to 9% since 2000",
       x = "School Year", y = "Percent of Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/hispanic-growth-1.png)

## 4. Boone County is Northern Kentucky’s growth story

Boone County in the Cincinnati suburbs has added 5,000 students since
2010. It’s now the third-largest district in Kentucky.

``` r
boone <- enr %>%
  filter(is_district, grepl("Boone County", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(boone, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Boone County - Northern Kentucky Growth",
       subtitle = "Cincinnati suburbs driving Kentucky's growth",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/boone-county-1.png)

## 5. Jefferson County is Kentucky’s giant

Jefferson County Public Schools (Louisville) serves 95,000 students,
nearly 15% of Kentucky’s entire enrollment. It’s larger than the next
five districts combined.

``` r
top_districts <- enr_current %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, n_students))

ggplot(top_districts, aes(x = district_label, y = n_students)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "Kentucky's Largest School Districts",
       subtitle = "Jefferson County is nearly 15% of state enrollment",
       x = "", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/jefferson-county-1.png)

## 6. Fayette County is growing while Louisville shrinks

While Louisville shrinks, Fayette County (Lexington) has grown to 42,000
students. Kentucky’s two urban districts are on opposite trajectories.

``` r
urban <- enr %>%
  filter(grepl("Fayette County|Jefferson County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL", subgroup == "total_enrollment")

ggplot(urban, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Kentucky's Two Urban Giants",
       subtitle = "Lexington growing while Louisville shrinks",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/fayette-jefferson-1.png)

## 7. 60% of students are economically disadvantaged

Kentucky has one of the highest rates of economic disadvantage in the
nation. In some eastern Kentucky districts, 90%+ of students qualify.

``` r
econ_top <- enr_current %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "econ_disadv") %>%
  arrange(desc(pct)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, pct))

ggplot(econ_top, aes(x = district_label, y = pct * 100)) +
  geom_col(fill = colors["black"]) +
  coord_flip() +
  labs(title = "Highest Rates of Economic Disadvantage",
       subtitle = "Eastern Kentucky districts often exceed 90%",
       x = "", y = "Percent Economically Disadvantaged") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/econ-disadvantage-1.png)

## 8. COVID hit Kentucky hard

Kentucky lost 20,000 students between 2020 and 2022. Unlike some states,
Kentucky has not recovered.

``` r
covid_years <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment",
         end_year >= 2018)

ggplot(covid_years, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  geom_vline(xintercept = 2020, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID's Impact on Kentucky Enrollment",
       subtitle = "Lost 20,000 students and hasn't recovered",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/covid-impact-1.png)

## 9. Kentucky is 78% white

Kentucky remains one of the least diverse states. Louisville and
Lexington have significant minority populations; most rural districts
are 95%+ white.

``` r
demo <- enr_current %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  arrange(desc(pct)) %>%
  mutate(subgroup_label = reorder(subgroup, pct))

ggplot(demo, aes(x = subgroup_label, y = pct * 100)) +
  geom_col(aes(fill = subgroup)) +
  coord_flip() +
  scale_fill_manual(values = c("white" = colors["white"], "black" = colors["black"],
                               "hispanic" = colors["hispanic"], "asian" = colors["asian"],
                               "multiracial" = "#1ABC9C")) +
  labs(title = "Kentucky Student Demographics",
       subtitle = "State remains 78% white",
       x = "", y = "Percent of Students") +
  theme_readme() +
  theme(legend.position = "none")
```

![](enrollment-trends_files/figure-html/demographics-1.png)

## 10. Independent districts are a Kentucky tradition

Kentucky has both county-wide districts (like Jefferson County) and
independent city districts (like Bowling Green Independent). Some
independent districts serve just 1,000 students but maintain their own
school boards.

``` r
independent <- enr_current %>%
  filter(grepl("Independent", district_name, ignore.case = TRUE),
         grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(n_students) %>%
  head(15) %>%
  mutate(district_label = reorder(district_name, n_students))

ggplot(independent, aes(x = district_label, y = n_students)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "Kentucky's Smallest Independent Districts",
       subtitle = "Some serve just 1,000 students with their own school boards",
       x = "", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/independent-districts-1.png)

## 11. Louisville is Kentucky’s diversity hub

Jefferson County has nearly half of Kentucky’s Black students and a
third of its Hispanic students. It’s the only district where white
students are a minority.

``` r
# Louisville vs rest of state demographic comparison
jefferson <- enr_current %>%
  filter(grepl("Jefferson County", district_name, ignore.case = TRUE),
         is_district, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  mutate(area = "Jefferson County (Louisville)")

state <- enr_current %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  mutate(area = "Kentucky Statewide")

compare <- bind_rows(jefferson, state) %>%
  mutate(subgroup = factor(subgroup, levels = c("white", "black", "hispanic", "asian", "multiracial")))

ggplot(compare, aes(x = subgroup, y = pct * 100, fill = area)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("Jefferson County (Louisville)" = colors["black"],
                               "Kentucky Statewide" = colors["white"])) +
  labs(title = "Louisville vs Kentucky Demographics",
       subtitle = "Jefferson County is Kentucky's diversity hub",
       x = "", y = "Percent of Students", fill = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/louisville-diversity-1.png)

## 12. The gender gap is minimal

Kentucky schools have nearly equal male and female enrollment, with
males slightly outnumbering females at about 51% to 49%.

``` r
gender <- enr_current %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("male", "female")) %>%
  mutate(subgroup = factor(subgroup, levels = c("male", "female")))

ggplot(gender, aes(x = subgroup, y = n_students, fill = subgroup)) +
  geom_col() +
  geom_text(aes(label = paste0(round(pct * 100, 1), "%")), vjust = -0.5, size = 5) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.1))) +
  scale_fill_manual(values = c("male" = colors["white"], "female" = colors["hispanic"])) +
  labs(title = "Gender Balance in Kentucky Schools",
       subtitle = "Near-equal enrollment with slight male majority",
       x = "", y = "Students") +
  theme_readme() +
  theme(legend.position = "none")
```

![](enrollment-trends_files/figure-html/gender-balance-1.png)

## 13. Oldham County is the wealthy suburb

Oldham County, between Louisville and Lexington, has grown into
Kentucky’s fifth-largest district. It has Kentucky’s lowest economic
disadvantage rate.

``` r
oldham <- enr %>%
  filter(is_district, grepl("Oldham County", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(oldham, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["asian"]) +
  geom_point(size = 3, color = colors["asian"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Oldham County - The Wealthy Suburb",
       subtitle = "Growing rapidly between Louisville and Lexington",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/oldham-county-1.png)

## 14. Harlan County tells the coal story

Harlan County, once a thriving coal community with over 10,000 students,
has shrunk to under 4,000. It symbolizes the decline of coal country.

``` r
harlan <- enr_long %>%
  filter(is_district, grepl("Harlan County", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(harlan, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["black"]) +
  geom_point(size = 3, color = colors["black"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Harlan County - The Coal Story",
       subtitle = "From coal boom to population decline",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/harlan-county-1.png)

## 15. The multiracial population is growing

Multiracial students now make up 5.4% of Kentucky’s enrollment, up from
4.3% in 2020. Kentucky began tracking multiracial students in 2020 when
the demographic category was added to federal reporting standards.

``` r
multiracial <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "multiracial")

ggplot(multiracial, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = "#1ABC9C") +
  geom_point(size = 3, color = "#1ABC9C") +
  scale_y_continuous(labels = comma) +
  labs(title = "Multiracial Students in Kentucky",
       subtitle = "5.4% of enrollment, up from 4.3% in 2020",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/multiracial-growth-1.png)

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.3 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] scales_1.4.0       dplyr_1.1.4        ggplot2_4.0.1      kyschooldata_0.1.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] bit_4.6.0          gtable_0.3.6       jsonlite_2.0.0     crayon_1.5.3      
#>  [5] compiler_4.5.2     tidyselect_1.2.1   parallel_4.5.2     jquerylib_0.1.4   
#>  [9] systemfonts_1.3.1  textshaping_1.0.4  readxl_1.4.5       yaml_2.3.12       
#> [13] fastmap_1.2.0      readr_2.1.6        R6_2.6.1           labeling_0.4.3    
#> [17] generics_0.1.4     curl_7.0.0         knitr_1.51         tibble_3.3.1      
#> [21] desc_1.4.3         tzdb_0.5.0         bslib_0.9.0        pillar_1.11.1     
#> [25] RColorBrewer_1.1-3 rlang_1.1.7        cachem_1.1.0       xfun_0.55         
#> [29] fs_1.6.6           sass_0.4.10        S7_0.2.1           bit64_4.6.0-1     
#> [33] cli_3.6.5          pkgdown_2.2.0      withr_3.0.2        magrittr_2.0.4    
#> [37] digest_0.6.39      grid_4.5.2         vroom_1.6.7        hms_1.1.4         
#> [41] rappdirs_0.3.4     lifecycle_1.0.5    vctrs_0.7.0        evaluate_1.0.5    
#> [45] glue_1.8.0         cellranger_1.1.0   farver_2.1.2       codetools_0.2-20  
#> [49] ragg_1.5.0         httr_1.4.7         rmarkdown_2.30     purrr_1.2.1       
#> [53] tools_4.5.2        pkgconfig_2.0.3    htmltools_0.5.9
```
